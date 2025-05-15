/*
Tên file: 12_get_model_features.sql
Mô tả: Tạo stored procedure GET_MODEL_FEATURES để lấy danh sách đặc trưng của mô hình
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-15
Phiên bản: 1.0
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu proc đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.GET_MODEL_FEATURES', 'P') IS NOT NULL
    DROP PROCEDURE dbo.GET_MODEL_FEATURES;
GO

-- Tạo stored procedure GET_MODEL_FEATURES
CREATE PROCEDURE dbo.GET_MODEL_FEATURES
    @MODEL_ID INT = NULL,
    @MODEL_NAME NVARCHAR(100) = NULL,
    @MODEL_VERSION NVARCHAR(20) = NULL,
    @AS_OF_DATE DATE = NULL,
    @INCLUDE_INACTIVE BIT = 0,
    @INCLUDE_QUALITY_ISSUES BIT = 1,
    @SORT_BY NVARCHAR(50) = 'IMPORTANCE' -- 'IMPORTANCE', 'NAME', 'TABLE', 'USAGE'
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
          AND (@INCLUDE_INACTIVE = 1 OR IS_ACTIVE = 1);
        
        IF @MODEL_ID IS NULL
        BEGIN
            DECLARE @DISPLAY_VERSION NVARCHAR(20);
            SET @DISPLAY_VERSION = ISNULL(@MODEL_VERSION, 'bất kỳ');

            RAISERROR(N'Không tìm thấy mô hình phù hợp với tên "%s" và phiên bản "%s"', 16, 1, @MODEL_NAME, @DISPLAY_VERSION);
            RETURN;
        END
    END
    
    -- Hiển thị thông tin cơ bản về mô hình
    SELECT 
        mr.MODEL_ID,
        mr.MODEL_NAME,
        mr.MODEL_VERSION,
        mt.TYPE_CODE,
        mt.TYPE_NAME,
        mr.MODEL_DESCRIPTION,
        mr.EFF_DATE,
        mr.EXP_DATE,
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
    
    -- Lấy danh sách tất cả các đặc trưng được sử dụng bởi mô hình
    WITH FeaturesCTE AS (
        SELECT 
            cd.COLUMN_ID,
            cd.COLUMN_NAME,
            cd.DATA_TYPE,
            cd.COLUMN_DESCRIPTION,
            cd.IS_MANDATORY,
            cd.IS_FEATURE,
            cd.FEATURE_IMPORTANCE,
            cd.BUSINESS_DEFINITION,
            cd.TRANSFORMATION_LOGIC,
            st.SOURCE_TABLE_ID,
            st.SOURCE_DATABASE,
            st.SOURCE_SCHEMA,
            st.SOURCE_TABLE_NAME,
            st.TABLE_TYPE,
            tu.USAGE_PURPOSE,
            tm.USAGE_TYPE,
            tm.IS_CRITICAL,
            tm.SEQUENCE_ORDER,
            tm.REQUIRED_COLUMNS,
            tu.PRIORITY,
            CASE 
                WHEN EXISTS (
                    SELECT 1
                    FROM MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG dq
                    WHERE dq.COLUMN_ID = cd.COLUMN_ID
                    AND dq.REMEDIATION_STATUS IN ('OPEN', 'IN_PROGRESS')
                    AND dq.PROCESS_DATE <= @AS_OF_DATE
                ) THEN 1
                ELSE 0
            END AS HAS_QUALITY_ISSUES,
            CASE 
                WHEN EXISTS (
                    SELECT 1
                    FROM MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG dq
                    WHERE dq.COLUMN_ID = cd.COLUMN_ID
                    AND dq.REMEDIATION_STATUS IN ('OPEN', 'IN_PROGRESS')
                    AND dq.SEVERITY IN ('HIGH', 'CRITICAL')
                    AND dq.PROCESS_DATE <= @AS_OF_DATE
                ) THEN 1
                ELSE 0
            END AS HAS_CRITICAL_ISSUES,
            ROW_NUMBER() OVER (
                PARTITION BY cd.COLUMN_ID 
                ORDER BY 
                    CASE 
                        WHEN @SORT_BY = 'IMPORTANCE' THEN ISNULL(cd.FEATURE_IMPORTANCE, 0) 
                        ELSE 0 
                    END DESC,
                    tm.IS_CRITICAL DESC,
                    tu.PRIORITY,
                    tm.SEQUENCE_ORDER
            ) AS RowNum
        FROM MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd
        JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON cd.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
        JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE tu ON st.SOURCE_TABLE_ID = tu.SOURCE_TABLE_ID
        JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING tm ON tu.MODEL_ID = tm.MODEL_ID AND tu.SOURCE_TABLE_ID = tm.SOURCE_TABLE_ID
        WHERE tu.MODEL_ID = @MODEL_ID
        AND (@INCLUDE_INACTIVE = 1 OR tu.IS_ACTIVE = 1)
        AND (@INCLUDE_INACTIVE = 1 OR st.IS_ACTIVE = 1)
        AND @AS_OF_DATE BETWEEN tu.EFF_DATE AND tu.EXP_DATE
        AND cd.IS_FEATURE = 1 -- Chỉ lấy các cột đã được đánh dấu là đặc trưng
        AND (
            -- Kiểm tra xem cột có nằm trong danh sách REQUIRED_COLUMNS không
            tm.REQUIRED_COLUMNS IS NULL
            OR tm.REQUIRED_COLUMNS = '[]'
            OR CHARINDEX('"' + cd.COLUMN_NAME + '"', tm.REQUIRED_COLUMNS) > 0
        )
    )
    SELECT 
        COLUMN_ID,
        COLUMN_NAME,
        DATA_TYPE,
        COLUMN_DESCRIPTION,
        IS_MANDATORY,
        FEATURE_IMPORTANCE,
        SOURCE_DATABASE + '.' + SOURCE_SCHEMA + '.' + SOURCE_TABLE_NAME AS TABLE_FULL_NAME,
        TABLE_TYPE,
        USAGE_PURPOSE,
        USAGE_TYPE,
        IS_CRITICAL,
        SEQUENCE_ORDER,
        PRIORITY,
        BUSINESS_DEFINITION,
        TRANSFORMATION_LOGIC,
        HAS_QUALITY_ISSUES,
        HAS_CRITICAL_ISSUES
    FROM FeaturesCTE
    WHERE RowNum = 1 -- Loại bỏ các bản ghi trùng lặp
    ORDER BY 
        CASE 
            WHEN @SORT_BY = 'IMPORTANCE' THEN ISNULL(FEATURE_IMPORTANCE, 0) 
            ELSE 0 
        END DESC,
        CASE 
            WHEN @SORT_BY = 'NAME' THEN COLUMN_NAME 
            ELSE '' 
        END,
        CASE 
            WHEN @SORT_BY = 'TABLE' THEN SOURCE_DATABASE + '.' + SOURCE_SCHEMA + '.' + SOURCE_TABLE_NAME 
            ELSE '' 
        END,
        CASE 
            WHEN @SORT_BY = 'USAGE' THEN USAGE_TYPE 
            ELSE '' 
        END,
        IS_CRITICAL DESC,
        PRIORITY,
        SEQUENCE_ORDER;
    
    -- Nếu @INCLUDE_QUALITY_ISSUES = 1, trả về danh sách các vấn đề chất lượng dữ liệu gần đây
    IF @INCLUDE_QUALITY_ISSUES = 1
    BEGIN
        SELECT TOP 20
            dq.LOG_ID,
            st.SOURCE_DATABASE + '.' + st.SOURCE_SCHEMA + '.' + st.SOURCE_TABLE_NAME AS TABLE_FULL_NAME,
            cd.COLUMN_NAME,
            dq.PROCESS_DATE,
            dq.ISSUE_TYPE,
            dq.SEVERITY,
            dq.ISSUE_DESCRIPTION,
            dq.REMEDIATION_STATUS,
            dq.IMPACT_DESCRIPTION,
            dq.RECORDS_AFFECTED,
            dq.PERCENTAGE_AFFECTED
        FROM MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG dq
        JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON dq.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
        JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE tu ON st.SOURCE_TABLE_ID = tu.SOURCE_TABLE_ID
        JOIN MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd ON dq.COLUMN_ID = cd.COLUMN_ID
        WHERE tu.MODEL_ID = @MODEL_ID
        AND @AS_OF_DATE BETWEEN tu.EFF_DATE AND tu.EXP_DATE
        AND dq.REMEDIATION_STATUS IN ('OPEN', 'IN_PROGRESS') -- Chỉ lấy các vấn đề chưa giải quyết
        AND dq.PROCESS_DATE <= @AS_OF_DATE
        ORDER BY dq.SEVERITY DESC, dq.PROCESS_DATE DESC;
    END
    
    -- Tính toán thống kê tổng hợp về đặc trưng
    SELECT 
        COUNT(DISTINCT cd.COLUMN_ID) AS TOTAL_FEATURES,
        SUM(CASE WHEN cd.IS_MANDATORY = 1 THEN 1 ELSE 0 END) AS MANDATORY_FEATURES,
        SUM(CASE WHEN tm.IS_CRITICAL = 1 THEN 1 ELSE 0 END) AS CRITICAL_FEATURES,
        COUNT(DISTINCT st.SOURCE_TABLE_ID) AS SOURCE_TABLES_COUNT,
        (
            SELECT COUNT(*)
            FROM MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG dq
            JOIN MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd ON dq.COLUMN_ID = cd.COLUMN_ID
            JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON cd.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
            JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE tu ON st.SOURCE_TABLE_ID = tu.SOURCE_TABLE_ID
            WHERE tu.MODEL_ID = @MODEL_ID
            AND dq.REMEDIATION_STATUS IN ('OPEN', 'IN_PROGRESS')
            AND dq.PROCESS_DATE <= @AS_OF_DATE
        ) AS QUALITY_ISSUES_COUNT,
        (
            SELECT COUNT(*)
            FROM MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG dq
            JOIN MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd ON dq.COLUMN_ID = cd.COLUMN_ID
            JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON cd.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
            JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE tu ON st.SOURCE_TABLE_ID = tu.SOURCE_TABLE_ID
            WHERE tu.MODEL_ID = @MODEL_ID
            AND dq.REMEDIATION_STATUS IN ('OPEN', 'IN_PROGRESS')
            AND dq.SEVERITY IN ('HIGH', 'CRITICAL')
            AND dq.PROCESS_DATE <= @AS_OF_DATE
        ) AS CRITICAL_ISSUES_COUNT
    FROM MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd
    JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON cd.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
    JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE tu ON st.SOURCE_TABLE_ID = tu.SOURCE_TABLE_ID
    JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING tm ON tu.MODEL_ID = tm.MODEL_ID AND tu.SOURCE_TABLE_ID = tm.SOURCE_TABLE_ID
    WHERE tu.MODEL_ID = @MODEL_ID
    AND (@INCLUDE_INACTIVE = 1 OR tu.IS_ACTIVE = 1)
    AND (@INCLUDE_INACTIVE = 1 OR st.IS_ACTIVE = 1)
    AND @AS_OF_DATE BETWEEN tu.EFF_DATE AND tu.EXP_DATE
    AND cd.IS_FEATURE = 1
    AND (
        tm.REQUIRED_COLUMNS IS NULL
        OR tm.REQUIRED_COLUMNS = '[]'
        OR CHARINDEX('"' + cd.COLUMN_NAME + '"', tm.REQUIRED_COLUMNS) > 0
    );
END;
GO

-- Thêm comment cho stored procedure
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Lấy danh sách các đặc trưng của mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'PROCEDURE',  @level1name = N'GET_MODEL_FEATURES';
GO

PRINT N'Stored procedure GET_MODEL_FEATURES đã được tạo thành công';
GO