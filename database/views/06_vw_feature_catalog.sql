/*
Tên file: 06_vw_feature_catalog.sql
Mô tả: Tạo view VW_FEATURE_CATALOG để hiển thị danh mục các đặc trưng (features) được sử dụng trong mô hình
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-15
Phiên bản: 1.0
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu view đã tồn tại thì xóa
IF EXISTS (SELECT * FROM sys.views WHERE name = 'VW_FEATURE_CATALOG' AND schema_id = SCHEMA_ID('dbo'))
    DROP VIEW dbo.VW_FEATURE_CATALOG;
GO

-- Tạo view VW_FEATURE_CATALOG
CREATE VIEW dbo.VW_FEATURE_CATALOG AS
WITH FeatureUsage AS (
    -- Đếm số lượng mô hình sử dụng mỗi đặc trưng
    SELECT 
        cd.COLUMN_ID,
        COUNT(DISTINCT tm.MODEL_ID) AS MODELS_COUNT,
        STRING_AGG(CONCAT(mr.MODEL_NAME, ' (', mr.MODEL_VERSION, ')'), ', ') AS MODELS_USING_FEATURE
    FROM MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd
    JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING tm ON cd.SOURCE_TABLE_ID = tm.SOURCE_TABLE_ID
    JOIN MODEL_REGISTRY.dbo.MODEL_REGISTRY mr ON tm.MODEL_ID = mr.MODEL_ID
    WHERE cd.IS_FEATURE = 1
      AND (
          -- Kiểm tra nếu cột được liệt kê trong REQUIRED_COLUMNS
          tm.REQUIRED_COLUMNS IS NOT NULL
          AND (
              tm.REQUIRED_COLUMNS LIKE CONCAT('%"', cd.COLUMN_NAME, '"%')
              OR tm.REQUIRED_COLUMNS LIKE CONCAT('%[', cd.COLUMN_NAME, ']%')
              OR tm.REQUIRED_COLUMNS LIKE CONCAT('%"', cd.COLUMN_NAME, '",%')
              OR tm.REQUIRED_COLUMNS LIKE CONCAT('%', cd.COLUMN_NAME, ',%')
          )
      )
      AND tm.IS_ACTIVE = 1
    GROUP BY cd.COLUMN_ID
),
FeaturePerformance AS (
    -- Trung bình mức độ quan trọng của đặc trưng trong các mô hình
    SELECT 
        cd.COLUMN_ID,
        AVG(cd.FEATURE_IMPORTANCE) AS AVG_IMPORTANCE,
        MAX(cd.FEATURE_IMPORTANCE) AS MAX_IMPORTANCE,
        MIN(cd.FEATURE_IMPORTANCE) AS MIN_IMPORTANCE
    FROM MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd
    WHERE cd.IS_FEATURE = 1
      AND cd.FEATURE_IMPORTANCE IS NOT NULL
    GROUP BY cd.COLUMN_ID
),
QualityIssues AS (
    -- Số lượng vấn đề chất lượng dữ liệu cho mỗi đặc trưng
    SELECT 
        cd.COLUMN_ID,
        COUNT(CASE WHEN dql.REMEDIATION_STATUS IN ('OPEN', 'IN_PROGRESS') THEN 1 END) AS ACTIVE_ISSUES,
        COUNT(CASE WHEN dql.SEVERITY = 'CRITICAL' OR dql.SEVERITY = 'HIGH' THEN 1 END) AS HIGH_SEVERITY_ISSUES,
        MAX(dql.PROCESS_DATE) AS LAST_ISSUE_DATE
    FROM MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd
    LEFT JOIN MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG dql ON cd.COLUMN_ID = dql.COLUMN_ID
    WHERE cd.IS_FEATURE = 1
    GROUP BY cd.COLUMN_ID
)
SELECT 
    cd.COLUMN_ID,
    cd.SOURCE_TABLE_ID,
    st.SOURCE_DATABASE,
    st.SOURCE_SCHEMA,
    st.SOURCE_TABLE_NAME,
    cd.COLUMN_NAME,
    cd.DATA_TYPE,
    cd.COLUMN_DESCRIPTION,
    cd.IS_MANDATORY,
    cd.IS_FEATURE,
    cd.FEATURE_IMPORTANCE,
    fp.AVG_IMPORTANCE,
    fp.MAX_IMPORTANCE,
    CASE 
        WHEN fp.AVG_IMPORTANCE >= 0.7 THEN 'HIGH'
        WHEN fp.AVG_IMPORTANCE >= 0.3 THEN 'MEDIUM'
        WHEN fp.AVG_IMPORTANCE IS NULL THEN 'UNKNOWN'
        ELSE 'LOW'
    END AS IMPORTANCE_LEVEL,
    ISNULL(fu.MODELS_COUNT, 0) AS MODELS_COUNT,
    fu.MODELS_USING_FEATURE,
    cd.BUSINESS_DEFINITION,
    cd.TRANSFORMATION_LOGIC,
    cd.EXPECTED_VALUES,
    cd.DATA_QUALITY_CHECKS,
    ISNULL(qi.ACTIVE_ISSUES, 0) AS ACTIVE_QUALITY_ISSUES,
    ISNULL(qi.HIGH_SEVERITY_ISSUES, 0) AS HIGH_SEVERITY_ISSUES,
    qi.LAST_ISSUE_DATE,
    CASE
        WHEN ISNULL(qi.HIGH_SEVERITY_ISSUES, 0) > 0 THEN 'CRITICAL'
        WHEN ISNULL(qi.ACTIVE_ISSUES, 0) > 0 THEN 'WARNING'
        ELSE 'GOOD'
    END AS QUALITY_STATUS,
    -- Tạo ranking cho các đặc trưng dựa trên sự kết hợp của tầm quan trọng và mức độ sử dụng
    CASE 
        WHEN cd.IS_FEATURE = 0 THEN 'NOT_FEATURE'
        WHEN (ISNULL(fp.AVG_IMPORTANCE, 0) >= 0.5 AND ISNULL(fu.MODELS_COUNT, 0) >= 3) OR 
             ISNULL(fp.MAX_IMPORTANCE, 0) >= 0.8 THEN 'TIER_1'
        WHEN (ISNULL(fp.AVG_IMPORTANCE, 0) >= 0.3 AND ISNULL(fu.MODELS_COUNT, 0) >= 2) OR 
             ISNULL(fp.MAX_IMPORTANCE, 0) >= 0.5 THEN 'TIER_2'
        ELSE 'TIER_3'
    END AS FEATURE_TIER,
    cd.CREATED_BY,
    cd.CREATED_DATE,
    cd.UPDATED_BY,
    cd.UPDATED_DATE
FROM MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd
JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON cd.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
LEFT JOIN FeatureUsage fu ON cd.COLUMN_ID = fu.COLUMN_ID
LEFT JOIN FeaturePerformance fp ON cd.COLUMN_ID = fp.COLUMN_ID
LEFT JOIN QualityIssues qi ON cd.COLUMN_ID = qi.COLUMN_ID
WHERE cd.IS_FEATURE = 1;
GO

-- Thêm comment cho view
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'View hiển thị danh mục các đặc trưng (features) được sử dụng trong mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'VIEW',  @level1name = N'VW_FEATURE_CATALOG';
GO

PRINT N'View VW_FEATURE_CATALOG đã được tạo thành công';
GO