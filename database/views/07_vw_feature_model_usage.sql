/*
Tên file: 07_vw_feature_model_usage.sql
Mô tả: Tạo view VW_FEATURE_MODEL_USAGE để hiển thị mối quan hệ giữa các đặc trưng và mô hình
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-15
Phiên bản: 1.0
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu view đã tồn tại thì xóa
IF EXISTS (SELECT * FROM sys.views WHERE name = 'VW_FEATURE_MODEL_USAGE' AND schema_id = SCHEMA_ID('dbo'))
    DROP VIEW dbo.VW_FEATURE_MODEL_USAGE;
GO

-- Tạo view VW_FEATURE_MODEL_USAGE
CREATE VIEW dbo.VW_FEATURE_MODEL_USAGE AS
WITH ModelFeatureMapping AS (
    -- Ánh xạ đặc trưng vào mô hình dựa trên bảng nguồn và bảng ánh xạ
    SELECT DISTINCT
        mr.MODEL_ID,
        mr.MODEL_NAME,
        mr.MODEL_VERSION,
        mt.TYPE_CODE AS MODEL_TYPE,
        mr.MODEL_CATEGORY,
        cd.COLUMN_ID,
        cd.COLUMN_NAME,
        cd.FEATURE_IMPORTANCE,
        tm.USAGE_TYPE,
        CASE 
            WHEN tm.REQUIRED_COLUMNS IS NOT NULL
            AND (
                tm.REQUIRED_COLUMNS LIKE CONCAT('%"', cd.COLUMN_NAME, '"%')
                OR tm.REQUIRED_COLUMNS LIKE CONCAT('%[', cd.COLUMN_NAME, ']%')
                OR tm.REQUIRED_COLUMNS LIKE CONCAT('%"', cd.COLUMN_NAME, '",%')
                OR tm.REQUIRED_COLUMNS LIKE CONCAT('%', cd.COLUMN_NAME, ',%')
            ) THEN 1
            ELSE 0
        END AS IS_EXPLICITLY_REQUIRED,
        tm.SEQUENCE_ORDER,
        st.SOURCE_DATABASE,
        st.SOURCE_SCHEMA,
        st.SOURCE_TABLE_NAME,
        cd.DATA_TYPE,
        cd.BUSINESS_DEFINITION,
        cd.TRANSFORMATION_LOGIC
    FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
    JOIN MODEL_REGISTRY.dbo.MODEL_TYPE mt ON mr.TYPE_ID = mt.TYPE_ID
    JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING tm ON mr.MODEL_ID = tm.MODEL_ID
    JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON tm.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
    JOIN MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd ON st.SOURCE_TABLE_ID = cd.SOURCE_TABLE_ID
    WHERE cd.IS_FEATURE = 1
      AND tm.IS_ACTIVE = 1
      AND mr.IS_ACTIVE = 1
),
FeaturePerformance AS (
    -- Xác định hiệu suất của đặc trưng trong mô hình cụ thể (nếu có thông tin)
    SELECT 
        mfm.MODEL_ID,
        mfm.COLUMN_ID,
        MAX(mvr.VALIDATION_DATE) AS LAST_VALIDATION_DATE,
        FIRST_VALUE(mvr.VALIDATION_STATUS) OVER (PARTITION BY mfm.MODEL_ID, mfm.COLUMN_ID 
                                               ORDER BY mvr.VALIDATION_DATE DESC) AS LAST_VALIDATION_STATUS
    FROM ModelFeatureMapping mfm
    CROSS APPLY (
        SELECT TOP 1 * 
        FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS mvr
        WHERE mvr.MODEL_ID = mfm.MODEL_ID
        ORDER BY mvr.VALIDATION_DATE DESC
    ) mvr
    GROUP BY mfm.MODEL_ID, mfm.COLUMN_ID, mvr.VALIDATION_DATE, mvr.VALIDATION_STATUS
),
ModelSegments AS (
    -- Xác định các phân khúc mà mô hình được áp dụng
    SELECT 
        sm.MODEL_ID,
        STRING_AGG(sm.SEGMENT_NAME, ', ') AS APPLICABLE_SEGMENTS
    FROM MODEL_REGISTRY.dbo.MODEL_SEGMENT_MAPPING sm
    WHERE sm.IS_ACTIVE = 1
    GROUP BY sm.MODEL_ID
),
FeatureQualityIssues AS (
    -- Vấn đề chất lượng dữ liệu của đặc trưng trên mô hình cụ thể
    SELECT 
        mfm.MODEL_ID,
        mfm.COLUMN_ID,
        COUNT(CASE WHEN dql.REMEDIATION_STATUS IN ('OPEN', 'IN_PROGRESS') THEN 1 END) AS ACTIVE_ISSUES,
        MAX(dql.SEVERITY) AS MAX_SEVERITY
    FROM ModelFeatureMapping mfm
    JOIN MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG dql ON mfm.COLUMN_ID = dql.COLUMN_ID
    GROUP BY mfm.MODEL_ID, mfm.COLUMN_ID
)
SELECT 
    mfm.MODEL_ID,
    mfm.MODEL_NAME,
    mfm.MODEL_VERSION,
    mfm.MODEL_TYPE,
    mfm.MODEL_CATEGORY,
    ms.APPLICABLE_SEGMENTS,
    mfm.COLUMN_ID,
    mfm.COLUMN_NAME,
    mfm.SOURCE_DATABASE + '.' + mfm.SOURCE_SCHEMA + '.' + mfm.SOURCE_TABLE_NAME AS SOURCE_LOCATION,
    mfm.DATA_TYPE,
    mfm.FEATURE_IMPORTANCE,
    CASE 
        WHEN mfm.FEATURE_IMPORTANCE >= 0.7 THEN 'HIGH'
        WHEN mfm.FEATURE_IMPORTANCE >= 0.3 THEN 'MEDIUM'
        WHEN mfm.FEATURE_IMPORTANCE IS NULL THEN 'UNKNOWN'
        ELSE 'LOW'
    END AS IMPORTANCE_LEVEL,
    mfm.USAGE_TYPE,
    mfm.IS_EXPLICITLY_REQUIRED,
    CASE 
        WHEN mfm.IS_EXPLICITLY_REQUIRED = 1 THEN 'EXPLICIT'
        ELSE 'IMPLICIT'
    END AS REQUIREMENT_TYPE,
    mfm.SEQUENCE_ORDER,
    mfm.BUSINESS_DEFINITION,
    mfm.TRANSFORMATION_LOGIC,
    fp.LAST_VALIDATION_DATE,
    fp.LAST_VALIDATION_STATUS,
    ISNULL(fqi.ACTIVE_ISSUES, 0) AS ACTIVE_QUALITY_ISSUES,
    fqi.MAX_SEVERITY,
    CASE 
        WHEN fqi.MAX_SEVERITY = 'CRITICAL' THEN 'CRITICAL'
        WHEN fqi.MAX_SEVERITY = 'HIGH' THEN 'HIGH_RISK'
        WHEN fqi.ACTIVE_ISSUES > 0 THEN 'MODERATE_RISK'
        ELSE 'GOOD'
    END AS QUALITY_STATUS,
    -- Đánh giá tổng hợp về tầm quan trọng của đặc trưng đối với mô hình cụ thể
    CASE 
        WHEN mfm.FEATURE_IMPORTANCE >= 0.7 OR mfm.IS_EXPLICITLY_REQUIRED = 1 THEN 'CRITICAL'
        WHEN mfm.FEATURE_IMPORTANCE >= 0.3 THEN 'IMPORTANT'
        ELSE 'SUPPORTIVE'
    END AS FEATURE_SIGNIFICANCE,
    -- Trạng thái hiệu lực của mô hình
    mr.EFF_DATE,
    mr.EXP_DATE,
    CASE 
        WHEN mr.IS_ACTIVE = 0 THEN 'INACTIVE'
        WHEN GETDATE() BETWEEN mr.EFF_DATE AND mr.EXP_DATE THEN 'ACTIVE'
        WHEN GETDATE() < mr.EFF_DATE THEN 'PENDING'
        WHEN GETDATE() > mr.EXP_DATE THEN 'EXPIRED'
        ELSE 'UNKNOWN'
    END AS MODEL_STATUS
FROM ModelFeatureMapping mfm
JOIN MODEL_REGISTRY.dbo.MODEL_REGISTRY mr ON mfm.MODEL_ID = mr.MODEL_ID
LEFT JOIN FeaturePerformance fp ON mfm.MODEL_ID = fp.MODEL_ID AND mfm.COLUMN_ID = fp.COLUMN_ID
LEFT JOIN ModelSegments ms ON mfm.MODEL_ID = ms.MODEL_ID
LEFT JOIN FeatureQualityIssues fqi ON mfm.MODEL_ID = fqi.MODEL_ID AND mfm.COLUMN_ID = fqi.COLUMN_ID;
GO

-- Thêm comment cho view
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'View hiển thị mối quan hệ giữa các đặc trưng và mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'VIEW',  @level1name = N'VW_FEATURE_MODEL_USAGE';
GO

PRINT N'View VW_FEATURE_MODEL_USAGE đã được tạo thành công';
GO