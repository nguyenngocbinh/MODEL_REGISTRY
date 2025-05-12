/*
Tên file: 01_get_model_tables.sql
Mô tả: Tạo stored procedure GET_MODEL_TABLES để lấy danh sách tất cả các bảng dữ liệu được sử dụng bởi một mô hình
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.0
*/

-- Kiểm tra nếu proc đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.GET_MODEL_TABLES', 'P') IS NOT NULL
    DROP PROCEDURE MODEL_REGISTRY.dbo.GET_MODEL_TABLES;
GO

-- Tạo stored procedure GET_MODEL_TABLES
CREATE PROCEDURE MODEL_REGISTRY.dbo.GET_MODEL_TABLES
    @MODEL_ID INT = NULL,
    @MODEL_NAME NVARCHAR(100) = NULL,
    @MODEL_VERSION NVARCHAR(20) = NULL,
    @AS_OF_DATE DATE = NULL,
    @INCLUDE_INACTIVE BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Xử lý tham số mặc định
    IF @AS_OF_DATE IS NULL
        SET @AS_OF_DATE = GETDATE();
        
    -- Xử lý lỗi nếu không có MODEL_ID hoặc MODEL_NAME
    IF @MODEL_ID IS NULL AND @MODEL_NAME IS NULL
    BEGIN
        RAISERROR('Phải cung cấp MODEL_ID hoặc MODEL_NAME', 16, 1);
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
            RAISERROR('Không tìm thấy mô hình phù hợp với tên "%s" và phiên bản "%s"', 16, 1, @MODEL_NAME, ISNULL(@MODEL_VERSION, 'bất kỳ'));
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
    
    -- Lấy danh sách tất cả các bảng dữ liệu được sử dụng bởi mô hình
    SELECT 
        st.SOURCE_TABLE_ID,
        st.SOURCE_DATABASE,
        st.SOURCE_SCHEMA,
        st.SOURCE_TABLE_NAME,
        st.TABLE_TYPE,
        tu.USAGE_PURPOSE,
        tm.USAGE_TYPE,
        st.TABLE_DESCRIPTION,
        st.DATA_OWNER,
        st.UPDATE_FREQUENCY,
        tm.IS_CRITICAL,
        tm.SEQUENCE_ORDER,
        tu.PRIORITY,
        CASE 
            WHEN EXISTS (
                SELECT 1
                FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG r
                WHERE r.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
                AND r.REFRESH_STATUS = 'COMPLETED'
                AND r.PROCESS_DATE = (
                    SELECT MAX(PROCESS_DATE) 
                    FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG
                    WHERE SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
                    AND PROCESS_DATE <= @AS_OF_DATE
                )
            ) THEN 'READY'
            ELSE 'NOT_READY'
        END AS DATA_STATUS,
        (
            SELECT MAX(PROCESS_DATE)
            FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG
            WHERE SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
            AND REFRESH_STATUS = 'COMPLETED'
            AND PROCESS_DATE <= @AS_OF_DATE
        ) AS LAST_REFRESH_DATE,
        tu.EFF_DATE AS USAGE_EFF_DATE,
        tu.EXP_DATE AS USAGE_EXP_DATE
    FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st
    JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE tu ON st.SOURCE_TABLE_ID = tu.SOURCE_TABLE_ID
    LEFT JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING tm ON st.SOURCE_TABLE_ID = tm.SOURCE_TABLE_ID AND tm.MODEL_ID = @MODEL_ID
    WHERE tu.MODEL_ID = @MODEL_ID
    AND (@INCLUDE_INACTIVE = 1 OR tu.IS_ACTIVE = 1)
    AND (@INCLUDE_INACTIVE = 1 OR st.IS_ACTIVE = 1)
    AND @AS_OF_DATE BETWEEN tu.EFF_DATE AND tu.EXP_DATE
    ORDER BY tm.IS_CRITICAL DESC, tu.PRIORITY, tm.SEQUENCE_ORDER, st.TABLE_TYPE;
    
    -- Lấy thông tin về các cột chính được sử dụng bởi mô hình
    SELECT 
        st.SOURCE_DATABASE + '.' + st.SOURCE_SCHEMA + '.' + st.SOURCE_TABLE_NAME AS TABLE_FULL_NAME,
        cd.COLUMN_NAME,
        cd.DATA_TYPE,
        cd.COLUMN_DESCRIPTION,
        cd.IS_MANDATORY,
        cd.IS_FEATURE,
        cd.FEATURE_IMPORTANCE,
        cd.BUSINESS_DEFINITION,
        cd.TRANSFORMATION_LOGIC
    FROM MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd
    JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON cd.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
    JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE tu ON st.SOURCE_TABLE_ID = tu.SOURCE_TABLE_ID
    WHERE tu.MODEL_ID = @MODEL_ID
    AND cd.IS_FEATURE = 1 -- Chỉ lấy các cột là đặc trưng của mô hình
    AND (@INCLUDE_INACTIVE = 1 OR tu.IS_ACTIVE = 1)
    AND @AS_OF_DATE BETWEEN tu.EFF_DATE AND tu.EXP_DATE
    ORDER BY st.SOURCE_TABLE_NAME, 
        CASE WHEN cd.FEATURE_IMPORTANCE IS NULL THEN 0 ELSE 1 END DESC, 
        cd.FEATURE_IMPORTANCE DESC, 
        cd.COLUMN_NAME;
    
    -- Lấy thông tin về các vấn đề chất lượng dữ liệu gần đây
    SELECT TOP 10
        st.SOURCE_DATABASE + '.' + st.SOURCE_SCHEMA + '.' + st.SOURCE_TABLE_NAME AS TABLE_FULL_NAME,
        ISNULL(cd.COLUMN_NAME, 'N/A') AS COLUMN_NAME,
        dq.PROCESS_DATE,
        dq.ISSUE_TYPE,
        dq.SEVERITY,
        dq.ISSUE_DESCRIPTION,
        dq.REMEDIATION_STATUS,
        dq.IMPACT_DESCRIPTION
    FROM MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG dq
    JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON dq.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
    JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE tu ON st.SOURCE_TABLE_ID = tu.SOURCE_TABLE_ID
    LEFT JOIN MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd ON dq.COLUMN_ID = cd.COLUMN_ID
    WHERE tu.MODEL_ID = @MODEL_ID
    AND @AS_OF_DATE BETWEEN tu.EFF_DATE AND tu.EXP_DATE
    AND dq.PROCESS_DATE <= @AS_OF_DATE
    AND dq.REMEDIATION_STATUS IN ('OPEN', 'IN_PROGRESS') -- Chỉ lấy các vấn đề chưa giải quyết
    ORDER BY dq.SEVERITY DESC, dq.PROCESS_DATE DESC;
END;
GO

-- Thêm comment cho stored procedure
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Lấy danh sách tất cả các bảng dữ liệu được sử dụng bởi một mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'PROCEDURE',  @level1name = N'GET_MODEL_TABLES';
GO

PRINT 'Stored procedure GET_MODEL_TABLES đã được tạo thành công';
GO