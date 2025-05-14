/*
Tên file: 02_get_table_models.sql
Mô tả: Tạo stored procedure GET_TABLE_MODELS để lấy danh sách tất cả các mô hình sử dụng một bảng dữ liệu
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.0
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu proc đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.GET_TABLE_MODELS', 'P') IS NOT NULL
    DROP PROCEDURE dbo.GET_TABLE_MODELS;
GO

-- Tạo stored procedure GET_TABLE_MODELS
CREATE PROCEDURE dbo.GET_TABLE_MODELS
    @DATABASE_NAME NVARCHAR(128),
    @SCHEMA_NAME NVARCHAR(128),
    @TABLE_NAME NVARCHAR(128),
    @AS_OF_DATE DATE = NULL,
    @INCLUDE_INACTIVE BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Xử lý tham số mặc định
    IF @AS_OF_DATE IS NULL
        SET @AS_OF_DATE = GETDATE();
        
    -- Kiểm tra tham số đầu vào
    IF @DATABASE_NAME IS NULL OR @SCHEMA_NAME IS NULL OR @TABLE_NAME IS NULL
    BEGIN
        RAISERROR(N'Phải cung cấp đầy đủ thông tin bảng: DATABASE_NAME, SCHEMA_NAME, và TABLE_NAME', 16, 1);
        RETURN;
    END
    
    -- Kiểm tra bảng có tồn tại trong registry không
    DECLARE @SOURCE_TABLE_ID INT;
    
    SELECT @SOURCE_TABLE_ID = SOURCE_TABLE_ID
    FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES
    WHERE SOURCE_DATABASE = @DATABASE_NAME
      AND SOURCE_SCHEMA = @SCHEMA_NAME
      AND SOURCE_TABLE_NAME = @TABLE_NAME;
      
    IF @SOURCE_TABLE_ID IS NULL
    BEGIN
        RAISERROR(N'Bảng %s.%s.%s không tồn tại trong registry', 16, 1, @DATABASE_NAME, @SCHEMA_NAME, @TABLE_NAME);
        RETURN;
    END
    
    -- Hiển thị thông tin chi tiết về bảng
    SELECT 
        st.SOURCE_TABLE_ID,
        st.SOURCE_DATABASE,
        st.SOURCE_SCHEMA,
        st.SOURCE_TABLE_NAME,
        st.TABLE_TYPE,
        st.TABLE_DESCRIPTION,
        st.DATA_OWNER,
        st.UPDATE_FREQUENCY,
        st.DATA_LATENCY,
        st.DATA_QUALITY_SCORE,
        st.KEY_COLUMNS,
        st.IS_ACTIVE,
        (
            SELECT COUNT(DISTINCT MODEL_ID)
            FROM MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE
            WHERE SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
            AND (@INCLUDE_INACTIVE = 1 OR IS_ACTIVE = 1)
            AND @AS_OF_DATE BETWEEN EFF_DATE AND EXP_DATE
        ) AS MODELS_COUNT,
        (
            SELECT MAX(PROCESS_DATE)
            FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG
            WHERE SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
            AND REFRESH_STATUS = 'COMPLETED'
            AND PROCESS_DATE <= @AS_OF_DATE
        ) AS LAST_REFRESH_DATE,
        (
            SELECT COUNT(*)
            FROM MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG
            WHERE SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
            AND REMEDIATION_STATUS IN ('OPEN', 'IN_PROGRESS')
            AND PROCESS_DATE <= @AS_OF_DATE
        ) AS OPEN_ISSUES_COUNT
    FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st
    WHERE st.SOURCE_TABLE_ID = @SOURCE_TABLE_ID;
    
    -- Lấy danh sách các cột được theo dõi
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
        (
            SELECT COUNT(*)
            FROM MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG
            WHERE COLUMN_ID = cd.COLUMN_ID
            AND REMEDIATION_STATUS IN ('OPEN', 'IN_PROGRESS')
            AND PROCESS_DATE <= @AS_OF_DATE
        ) AS OPEN_ISSUES_COUNT
    FROM MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd
    WHERE cd.SOURCE_TABLE_ID = @SOURCE_TABLE_ID
    -- FIX: Removed "NULLS LAST" which is not supported in SQL Server and replaced with a CASE expression
    ORDER BY cd.IS_FEATURE DESC, 
             CASE WHEN cd.FEATURE_IMPORTANCE IS NULL THEN 0 ELSE 1 END DESC, 
             CASE WHEN cd.FEATURE_IMPORTANCE IS NULL THEN 0 ELSE cd.FEATURE_IMPORTANCE END DESC, 
             cd.COLUMN_NAME;
    
    -- Lấy danh sách tất cả các mô hình sử dụng bảng này
    SELECT 
        mr.MODEL_ID,
        mr.MODEL_NAME,
        mr.MODEL_VERSION,
        mt.TYPE_CODE,
        mt.TYPE_NAME,
        tu.USAGE_PURPOSE,
        tm.USAGE_TYPE,
        tm.IS_CRITICAL,
        tu.PRIORITY,
        mr.MODEL_DESCRIPTION,
        CASE 
            WHEN mr.IS_ACTIVE = 1 AND @AS_OF_DATE BETWEEN mr.EFF_DATE AND mr.EXP_DATE THEN 'ACTIVE'
            WHEN mr.IS_ACTIVE = 1 AND @AS_OF_DATE < mr.EFF_DATE THEN 'PENDING'
            WHEN mr.IS_ACTIVE = 1 AND @AS_OF_DATE > mr.EXP_DATE THEN 'EXPIRED'
            ELSE 'INACTIVE'
        END AS MODEL_STATUS,
        mr.EFF_DATE AS MODEL_EFF_DATE,
        mr.EXP_DATE AS MODEL_EXP_DATE,
        tu.EFF_DATE AS USAGE_EFF_DATE,
        tu.EXP_DATE AS USAGE_EXP_DATE,
        (
            SELECT MAX(VALIDATION_DATE)
            FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS
            WHERE MODEL_ID = mr.MODEL_ID
            AND VALIDATION_DATE <= @AS_OF_DATE
        ) AS LAST_VALIDATION_DATE,
        tm.REQUIRED_COLUMNS,
        tm.FILTERS_APPLIED,
        tm.SEQUENCE_ORDER,
        tm.DATA_TRANSFORMATION
    FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
    JOIN MODEL_REGISTRY.dbo.MODEL_TYPE mt ON mr.TYPE_ID = mt.TYPE_ID
    JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE tu ON mr.MODEL_ID = tu.MODEL_ID
    LEFT JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING tm ON tu.MODEL_ID = tm.MODEL_ID AND tu.SOURCE_TABLE_ID = tm.SOURCE_TABLE_ID
    WHERE tu.SOURCE_TABLE_ID = @SOURCE_TABLE_ID
    AND (@INCLUDE_INACTIVE = 1 OR mr.IS_ACTIVE = 1)
    AND (@INCLUDE_INACTIVE = 1 OR tu.IS_ACTIVE = 1)
    AND @AS_OF_DATE BETWEEN tu.EFF_DATE AND tu.EXP_DATE
    ORDER BY mr.IS_ACTIVE DESC, tm.IS_CRITICAL DESC, tu.PRIORITY, mt.TYPE_NAME, mr.MODEL_NAME, mr.MODEL_VERSION;
    
    -- Lấy thông tin về các vấn đề chất lượng dữ liệu gần đây
    SELECT TOP 10
        dq.LOG_ID,
        dq.PROCESS_DATE,
        ISNULL(cd.COLUMN_NAME, 'N/A') AS COLUMN_NAME,
        dq.ISSUE_TYPE,
        dq.SEVERITY,
        dq.ISSUE_DESCRIPTION,
        dq.RECORDS_AFFECTED,
        dq.PERCENTAGE_AFFECTED,
        dq.REMEDIATION_STATUS,
        dq.REMEDIATION_ACTION,
        dq.IMPACT_DESCRIPTION,
        dq.CREATED_DATE,
        dq.CREATED_BY
    FROM MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG dq
    LEFT JOIN MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd ON dq.COLUMN_ID = cd.COLUMN_ID
    WHERE dq.SOURCE_TABLE_ID = @SOURCE_TABLE_ID
    AND dq.PROCESS_DATE <= @AS_OF_DATE
    ORDER BY dq.PROCESS_DATE DESC, dq.SEVERITY DESC;
END;
GO

-- Thêm comment cho stored procedure
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Lấy danh sách tất cả các mô hình sử dụng một bảng dữ liệu', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'PROCEDURE',  @level1name = N'GET_TABLE_MODELS';
GO

PRINT N'Stored procedure GET_TABLE_MODELS đã được tạo thành công';
GO