/*
Tên file: 08_check_model_dependencies.sql
Mô tả: Tạo stored procedure CHECK_MODEL_DEPENDENCIES để kiểm tra các phụ thuộc của mô hình
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-15
Phiên bản: 1.0
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu proc đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.CHECK_MODEL_DEPENDENCIES', 'P') IS NOT NULL
    DROP PROCEDURE dbo.CHECK_MODEL_DEPENDENCIES;
GO

-- Tạo stored procedure CHECK_MODEL_DEPENDENCIES
CREATE PROCEDURE dbo.CHECK_MODEL_DEPENDENCIES
    @MODEL_ID INT = NULL,
    @MODEL_NAME NVARCHAR(100) = NULL,
    @MODEL_VERSION NVARCHAR(20) = NULL,
    @INCLUDE_REVERSE_DEPENDENCIES BIT = 0, -- Kiểm tra cả các mô hình phụ thuộc vào đầu ra của mô hình này
    @CHECK_THRESHOLD BIT = 1, -- Có đánh giá ngưỡng chất lượng dữ liệu không
    @AS_OF_DATE DATE = NULL -- Ngày tham chiếu, mặc định là ngày hiện tại
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Xử lý tham số mặc định
    IF @AS_OF_DATE IS NULL
        SET @AS_OF_DATE = GETDATE();
        
    -- Xử lý lỗi nếu không có MODEL_ID hoặc MODEL_NAME
    IF @MODEL_ID IS NULL AND @MODEL_NAME IS NULL
    BEGIN
        RAISERROR(N'Phải cung cấp MODEL_ID hoặc MODEL_NAME', 16, 1);
        RETURN;
    END
    
    -- Nếu không có MODEL_ID nhưng có MODEL_NAME, tìm MODEL_ID
    IF @MODEL_ID IS NULL AND @MODEL_NAME IS NOT NULL
    BEGIN
        SELECT @MODEL_ID = MODEL_ID 
        FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY 
        WHERE MODEL_NAME = @MODEL_NAME 
          AND (@MODEL_VERSION IS NULL OR MODEL_VERSION = @MODEL_VERSION)
          AND IS_ACTIVE = 1;
        
        IF @MODEL_ID IS NULL
        BEGIN
            DECLARE @DISPLAY_VERSION NVARCHAR(20) = ISNULL(@MODEL_VERSION, 'bất kỳ');
            RAISERROR(N'Không tìm thấy mô hình có tên "%s" và phiên bản "%s"', 16, 1, @MODEL_NAME, @DISPLAY_VERSION);
            RETURN;
        END
    END
    
    -- Lấy thông tin cơ bản về mô hình
    SELECT 
        mr.MODEL_ID,
        mr.MODEL_NAME,
        mr.MODEL_VERSION,
        mt.TYPE_CODE,
        mt.TYPE_NAME,
        mr.EFF_DATE AS MODEL_EFF_DATE,
        mr.EXP_DATE AS MODEL_EXP_DATE,
        mr.SOURCE_DATABASE + '.' + mr.SOURCE_SCHEMA + '.' + mr.SOURCE_TABLE_NAME AS OUTPUT_TABLE,
        mr.IS_ACTIVE,
        CASE 
            WHEN mr.IS_ACTIVE = 1 AND @AS_OF_DATE BETWEEN mr.EFF_DATE AND mr.EXP_DATE THEN 'ACTIVE'
            WHEN mr.IS_ACTIVE = 1 AND @AS_OF_DATE < mr.EFF_DATE THEN 'PENDING'
            WHEN mr.IS_ACTIVE = 1 AND @AS_OF_DATE > mr.EXP_DATE THEN 'EXPIRED'
            ELSE 'INACTIVE'
        END AS MODEL_STATUS
    FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
    JOIN MODEL_REGISTRY.dbo.MODEL_TYPE mt ON mr.TYPE_ID = mt.TYPE_ID
    WHERE mr.MODEL_ID = @MODEL_ID;
    
    -- Tạo bảng tạm để lưu trữ các phụ thuộc
    CREATE TABLE #Dependencies (
        SOURCE_TABLE_ID INT,
        SOURCE_DATABASE NVARCHAR(128),
        SOURCE_SCHEMA NVARCHAR(128),
        SOURCE_TABLE_NAME NVARCHAR(128),
        TABLE_FULL_NAME NVARCHAR(400),
        TABLE_TYPE NVARCHAR(50),
        USAGE_PURPOSE NVARCHAR(100),
        USAGE_TYPE NVARCHAR(50),
        IS_CRITICAL BIT,
        IS_ACTIVE BIT,
        LAST_REFRESH_DATE DATE,
        DATA_QUALITY_SCORE INT,
        IS_AVAILABLE BIT,
        HAS_QUALITY_ISSUES BIT,
        DEPENDENCY_STATUS NVARCHAR(20),
        ERROR_MESSAGE NVARCHAR(500)
    );
    
    -- Lấy danh sách các bảng phụ thuộc (bảng nguồn của mô hình)
    INSERT INTO #Dependencies (
        SOURCE_TABLE_ID,
        SOURCE_DATABASE,
        SOURCE_SCHEMA,
        SOURCE_TABLE_NAME,
        TABLE_FULL_NAME,
        TABLE_TYPE,
        USAGE_PURPOSE,
        USAGE_TYPE,
        IS_CRITICAL,
        IS_ACTIVE,
        LAST_REFRESH_DATE,
        DATA_QUALITY_SCORE,
        IS_AVAILABLE,
        HAS_QUALITY_ISSUES,
        DEPENDENCY_STATUS,
        ERROR_MESSAGE
    )
    SELECT 
        st.SOURCE_TABLE_ID,
        st.SOURCE_DATABASE,
        st.SOURCE_SCHEMA,
        st.SOURCE_TABLE_NAME,
        st.SOURCE_DATABASE + '.' + st.SOURCE_SCHEMA + '.' + st.SOURCE_TABLE_NAME AS TABLE_FULL_NAME,
        st.TABLE_TYPE,
        tu.USAGE_PURPOSE,
        tm.USAGE_TYPE,
        ISNULL(tm.IS_CRITICAL, 0) AS IS_CRITICAL,
        st.IS_ACTIVE,
        (
            SELECT MAX(PROCESS_DATE)
            FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG
            WHERE SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
            AND REFRESH_STATUS = 'COMPLETED'
            AND PROCESS_DATE <= @AS_OF_DATE
        ) AS LAST_REFRESH_DATE,
        st.DATA_QUALITY_SCORE,
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM INFORMATION_SCHEMA.TABLES 
                WHERE TABLE_CATALOG = st.SOURCE_DATABASE 
                  AND TABLE_SCHEMA = st.SOURCE_SCHEMA 
                  AND TABLE_NAME = st.SOURCE_TABLE_NAME
            ) THEN 1
            ELSE 0
        END AS IS_AVAILABLE,
        CASE 
            WHEN EXISTS (
                SELECT 1
                FROM MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG dq
                WHERE dq.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
                AND dq.REMEDIATION_STATUS IN ('OPEN', 'IN_PROGRESS')
                AND dq.PROCESS_DATE <= @AS_OF_DATE
                AND (@CHECK_THRESHOLD = 0 OR dq.SEVERITY IN ('HIGH', 'CRITICAL'))
            ) THEN 1
            ELSE 0
        END AS HAS_QUALITY_ISSUES,
        CASE 
            WHEN NOT EXISTS (
                SELECT 1 
                FROM INFORMATION_SCHEMA.TABLES 
                WHERE TABLE_CATALOG = st.SOURCE_DATABASE 
                  AND TABLE_SCHEMA = st.SOURCE_SCHEMA 
                  AND TABLE_NAME = st.SOURCE_TABLE_NAME
            ) THEN 'MISSING'
            WHEN NOT EXISTS (
                SELECT 1
                FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG
                WHERE SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
                AND REFRESH_STATUS = 'COMPLETED'
                AND PROCESS_DATE <= @AS_OF_DATE
            ) THEN 'NO_DATA'
            WHEN EXISTS (
                SELECT 1
                FROM MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG dq
                WHERE dq.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
                AND dq.REMEDIATION_STATUS IN ('OPEN', 'IN_PROGRESS')
                AND dq.PROCESS_DATE <= @AS_OF_DATE
                AND dq.SEVERITY IN ('HIGH', 'CRITICAL')
                AND @CHECK_THRESHOLD = 1
            ) THEN 'QUALITY_ISSUES'
            ELSE 'READY'
        END AS DEPENDENCY_STATUS,
        CASE 
            WHEN NOT EXISTS (
                SELECT 1 
                FROM INFORMATION_SCHEMA.TABLES 
                WHERE TABLE_CATALOG = st.SOURCE_DATABASE 
                  AND TABLE_SCHEMA = st.SOURCE_SCHEMA 
                  AND TABLE_NAME = st.SOURCE_TABLE_NAME
            ) THEN N'Bảng không tồn tại'
            WHEN NOT EXISTS (
                SELECT 1
                FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG
                WHERE SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
                AND REFRESH_STATUS = 'COMPLETED'
                AND PROCESS_DATE <= @AS_OF_DATE
            ) THEN N'Không có dữ liệu cho ngày ' + CONVERT(NVARCHAR, @AS_OF_DATE, 103)
            ELSE NULL
        END AS ERROR_MESSAGE
    FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st
    JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE tu ON st.SOURCE_TABLE_ID = tu.SOURCE_TABLE_ID
    LEFT JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING tm ON st.SOURCE_TABLE_ID = tm.SOURCE_TABLE_ID AND tm.MODEL_ID = @MODEL_ID
    WHERE tu.MODEL_ID = @MODEL_ID
    AND tu.IS_ACTIVE = 1
    AND st.TABLE_TYPE <> 'OUTPUT' -- Loại bỏ bảng đầu ra của chính mô hình này
    AND @AS_OF_DATE BETWEEN tu.EFF_DATE AND tu.EXP_DATE;
    
    -- Nếu @INCLUDE_REVERSE_DEPENDENCIES = 1, thêm các mô hình phụ thuộc vào đầu ra của mô hình này
    IF @INCLUDE_REVERSE_DEPENDENCIES = 1
    BEGIN
        -- Tạo bảng tạm cho các phụ thuộc ngược
        CREATE TABLE #ReverseDependencies (
            DEPENDENT_MODEL_ID INT,
            DEPENDENT_MODEL_NAME NVARCHAR(100),
            DEPENDENT_MODEL_VERSION NVARCHAR(20),
            DEPENDENT_MODEL_TYPE NVARCHAR(100),
            DEPENDENCY_TYPE NVARCHAR(50),
            DEPENDENCY_PURPOSE NVARCHAR(100),
            IS_CRITICAL BIT,
            IS_ACTIVE BIT,
            DEPENDENCY_STATUS NVARCHAR(20)
        );
        
        -- Lấy thông tin về bảng đầu ra của mô hình
        DECLARE @OUTPUT_DATABASE NVARCHAR(128);
        DECLARE @OUTPUT_SCHEMA NVARCHAR(128);
        DECLARE @OUTPUT_TABLE_NAME NVARCHAR(128);
        DECLARE @OUTPUT_TABLE_ID INT;
        
        SELECT 
            @OUTPUT_DATABASE = SOURCE_DATABASE,
            @OUTPUT_SCHEMA = SOURCE_SCHEMA,
            @OUTPUT_TABLE_NAME = SOURCE_TABLE_NAME
        FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY
        WHERE MODEL_ID = @MODEL_ID;
        
        -- Tìm ID của bảng đầu ra
        SELECT @OUTPUT_TABLE_ID = SOURCE_TABLE_ID
        FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES
        WHERE SOURCE_DATABASE = @OUTPUT_DATABASE
          AND SOURCE_SCHEMA = @OUTPUT_SCHEMA
          AND SOURCE_TABLE_NAME = @OUTPUT_TABLE_NAME;
        
        -- Nếu tìm thấy bảng đầu ra, kiểm tra các phụ thuộc ngược
        IF @OUTPUT_TABLE_ID IS NOT NULL
        BEGIN
            -- Lấy danh sách các mô hình sử dụng bảng đầu ra của mô hình này
            INSERT INTO #ReverseDependencies (
                DEPENDENT_MODEL_ID,
                DEPENDENT_MODEL_NAME,
                DEPENDENT_MODEL_VERSION,
                DEPENDENT_MODEL_TYPE,
                DEPENDENCY_TYPE,
                DEPENDENCY_PURPOSE,
                IS_CRITICAL,
                IS_ACTIVE,
                DEPENDENCY_STATUS
            )
            SELECT 
                mr.MODEL_ID,
                mr.MODEL_NAME,
                mr.MODEL_VERSION,
                mt.TYPE_NAME,
                tm.USAGE_TYPE,
                tu.USAGE_PURPOSE,
                ISNULL(tm.IS_CRITICAL, 0),
                mr.IS_ACTIVE,
                CASE 
                    WHEN mr.IS_ACTIVE = 0 THEN 'INACTIVE'
                    WHEN @AS_OF_DATE < mr.EFF_DATE THEN 'PENDING'
                    WHEN @AS_OF_DATE > mr.EXP_DATE THEN 'EXPIRED'
                    ELSE 'ACTIVE'
                END
            FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
            JOIN MODEL_REGISTRY.dbo.MODEL_TYPE mt ON mr.TYPE_ID = mt.TYPE_ID
            JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE tu ON mr.MODEL_ID = tu.MODEL_ID
            LEFT JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING tm ON tu.MODEL_ID = tm.MODEL_ID AND tu.SOURCE_TABLE_ID = tm.SOURCE_TABLE_ID
            WHERE tu.SOURCE_TABLE_ID = @OUTPUT_TABLE_ID
            AND mr.MODEL_ID <> @MODEL_ID -- Loại bỏ chính mô hình này
            AND tu.IS_ACTIVE = 1
            AND @AS_OF_DATE BETWEEN tu.EFF_DATE AND tu.EXP_DATE;
        END
    END
    
    -- Tính toán tổng quan về trạng thái phụ thuộc
    DECLARE @TOTAL_DEPENDENCIES INT = 0;
    DECLARE @READY_DEPENDENCIES INT = 0;
    DECLARE @CRITICAL_ISSUES INT = 0;
    DECLARE @QUALITY_ISSUES INT = 0;
    
    SELECT 
        @TOTAL_DEPENDENCIES = COUNT(*),
        @READY_DEPENDENCIES = SUM(CASE WHEN DEPENDENCY_STATUS = 'READY' THEN 1 ELSE 0 END),
        @CRITICAL_ISSUES = SUM(CASE WHEN IS_CRITICAL = 1 AND DEPENDENCY_STATUS <> 'READY' THEN 1 ELSE 0 END),
        @QUALITY_ISSUES = SUM(CASE WHEN DEPENDENCY_STATUS = 'QUALITY_ISSUES' THEN 1 ELSE 0 END)
    FROM #Dependencies;
    
    -- Trả về tổng quan về trạng thái phụ thuộc
    SELECT 
        'MODEL_DEPENDENCIES_SUMMARY' AS RESULT_TYPE,
        @TOTAL_DEPENDENCIES AS TOTAL_DEPENDENCIES,
        @READY_DEPENDENCIES AS READY_DEPENDENCIES,
        @CRITICAL_ISSUES AS CRITICAL_ISSUES,
        @QUALITY_ISSUES AS QUALITY_ISSUES,
        CASE 
            WHEN @CRITICAL_ISSUES > 0 THEN 'NOT_READY_CRITICAL_ISSUES'
            WHEN @QUALITY_ISSUES > 0 AND @CHECK_THRESHOLD = 1 THEN 'READY_WITH_QUALITY_ISSUES'
            WHEN @READY_DEPENDENCIES < @TOTAL_DEPENDENCIES THEN 'READY_WITH_WARNINGS'
            ELSE 'READY'
        END AS OVERALL_STATUS,
        CASE 
            WHEN @CRITICAL_ISSUES > 0 THEN N'Có vấn đề nghiêm trọng với ' + CAST(@CRITICAL_ISSUES AS NVARCHAR) + N' phụ thuộc quan trọng'
            WHEN @QUALITY_ISSUES > 0 AND @CHECK_THRESHOLD = 1 THEN N'Sẵn sàng nhưng có ' + CAST(@QUALITY_ISSUES AS NVARCHAR) + N' vấn đề chất lượng dữ liệu cần xử lý'
            WHEN @READY_DEPENDENCIES < @TOTAL_DEPENDENCIES THEN N'Sẵn sàng nhưng có ' + CAST(@TOTAL_DEPENDENCIES - @READY_DEPENDENCIES AS NVARCHAR) + N' phụ thuộc chưa sẵn sàng (không quan trọng)'
            ELSE N'Tất cả phụ thuộc đều sẵn sàng'
        END AS STATUS_DESCRIPTION;
    
    -- Trả về chi tiết về các phụ thuộc
    SELECT 
        'MODEL_DEPENDENCIES_DETAILS' AS RESULT_TYPE,
        SOURCE_TABLE_ID,
        TABLE_FULL_NAME,
        TABLE_TYPE,
        USAGE_PURPOSE,
        USAGE_TYPE,
        IS_CRITICAL,
        IS_ACTIVE,
        LAST_REFRESH_DATE,
        DATA_QUALITY_SCORE,
        IS_AVAILABLE,
        HAS_QUALITY_ISSUES,
        DEPENDENCY_STATUS,
        ERROR_MESSAGE
    FROM #Dependencies
    ORDER BY IS_CRITICAL DESC, DEPENDENCY_STATUS DESC, TABLE_TYPE, TABLE_FULL_NAME;
    
    -- Nếu @INCLUDE_REVERSE_DEPENDENCIES = 1, trả về chi tiết về các phụ thuộc ngược
    IF @INCLUDE_REVERSE_DEPENDENCIES = 1
    BEGIN
        SELECT 
            'REVERSE_DEPENDENCIES' AS RESULT_TYPE,
            DEPENDENT_MODEL_ID,
            DEPENDENT_MODEL_NAME,
            DEPENDENT_MODEL_VERSION,
            DEPENDENT_MODEL_TYPE,
            DEPENDENCY_TYPE,
            DEPENDENCY_PURPOSE,
            IS_CRITICAL,
            IS_ACTIVE,
            DEPENDENCY_STATUS
        FROM #ReverseDependencies
        ORDER BY IS_CRITICAL DESC, DEPENDENCY_STATUS, DEPENDENT_MODEL_NAME;
        
        -- Hiển thị cảnh báo nếu có các phụ thuộc ngược đang hoạt động
        SELECT 
            'REVERSE_DEPENDENCIES_SUMMARY' AS RESULT_TYPE,
            COUNT(*) AS TOTAL_DEPENDENTS,
            SUM(CASE WHEN DEPENDENCY_STATUS = 'ACTIVE' THEN 1 ELSE 0 END) AS ACTIVE_DEPENDENTS,
            SUM(CASE WHEN IS_CRITICAL = 1 AND DEPENDENCY_STATUS = 'ACTIVE' THEN 1 ELSE 0 END) AS CRITICAL_DEPENDENTS,
            CASE 
                WHEN SUM(CASE WHEN IS_CRITICAL = 1 AND DEPENDENCY_STATUS = 'ACTIVE' THEN 1 ELSE 0 END) > 0 
                THEN 'CRITICAL_WARNING' 
                WHEN SUM(CASE WHEN DEPENDENCY_STATUS = 'ACTIVE' THEN 1 ELSE 0 END) > 0 
                THEN 'WARNING'
                ELSE 'INFO'
            END AS WARNING_LEVEL,
            CASE 
                WHEN SUM(CASE WHEN IS_CRITICAL = 1 AND DEPENDENCY_STATUS = 'ACTIVE' THEN 1 ELSE 0 END) > 0 
                THEN N'Có ' + CAST(SUM(CASE WHEN IS_CRITICAL = 1 AND DEPENDENCY_STATUS = 'ACTIVE' THEN 1 ELSE 0 END) AS NVARCHAR) + N' mô hình quan trọng phụ thuộc vào mô hình này'
                WHEN SUM(CASE WHEN DEPENDENCY_STATUS = 'ACTIVE' THEN 1 ELSE 0 END) > 0 
                THEN N'Có ' + CAST(SUM(CASE WHEN DEPENDENCY_STATUS = 'ACTIVE' THEN 1 ELSE 0 END) AS NVARCHAR) + N' mô hình phụ thuộc vào mô hình này'
                ELSE N'Không có mô hình nào đang hoạt động phụ thuộc vào mô hình này'
            END AS WARNING_MESSAGE
        FROM #ReverseDependencies;
    END
    
    -- Dọn dẹp
    DROP TABLE #Dependencies;
    
    IF @INCLUDE_REVERSE_DEPENDENCIES = 1
        DROP TABLE #ReverseDependencies;
END;
GO

-- Thêm comment cho stored procedure
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Kiểm tra các phụ thuộc của mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'PROCEDURE',  @level1name = N'CHECK_MODEL_DEPENDENCIES';
GO

PRINT N'Stored procedure CHECK_MODEL_DEPENDENCIES đã được tạo thành công';
GO