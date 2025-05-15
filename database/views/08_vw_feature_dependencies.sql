/*
Tên file: 08_vw_feature_dependencies.sql
Mô tả: Tạo view VW_FEATURE_DEPENDENCIES để hiển thị mối quan hệ phụ thuộc giữa các đặc trưng
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-15
Phiên bản: 1.0
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu view đã tồn tại thì xóa
IF EXISTS (SELECT * FROM sys.views WHERE name = 'VW_FEATURE_DEPENDENCIES' AND schema_id = SCHEMA_ID('dbo'))
    DROP VIEW dbo.VW_FEATURE_DEPENDENCIES;
GO

-- Tạo view VW_FEATURE_DEPENDENCIES
CREATE VIEW dbo.VW_FEATURE_DEPENDENCIES AS
WITH FeatureInfo AS (
    -- Thông tin cơ bản về các đặc trưng 
    SELECT 
        cd.COLUMN_ID,
        cd.SOURCE_TABLE_ID,
        cd.COLUMN_NAME,
        st.SOURCE_DATABASE,
        st.SOURCE_SCHEMA,
        st.SOURCE_TABLE_NAME,
        cd.DATA_TYPE,
        cd.TRANSFORMATION_LOGIC,
        cd.FEATURE_IMPORTANCE
    FROM MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd
    JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON cd.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
    WHERE cd.IS_FEATURE = 1
),
FeatureModelUsage AS (
    -- Ánh xạ đặc trưng vào mô hình
    SELECT 
        cd.COLUMN_ID,
        mr.MODEL_ID,
        mr.MODEL_NAME
    FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
    JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING tm ON mr.MODEL_ID = tm.MODEL_ID
    JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON tm.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
    JOIN MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd ON st.SOURCE_TABLE_ID = cd.SOURCE_TABLE_ID
    WHERE cd.IS_FEATURE = 1
      AND tm.IS_ACTIVE = 1
      AND mr.IS_ACTIVE = 1
),
CooccurringFeatures AS (
    -- Xác định các đặc trưng xuất hiện cùng nhau trong các mô hình
    SELECT 
        f1.COLUMN_ID AS FEATURE_ID,
        f2.COLUMN_ID AS DEPENDENT_FEATURE_ID,
        COUNT(DISTINCT f1.MODEL_ID) AS SHARED_MODELS_COUNT
    FROM FeatureModelUsage f1
    JOIN FeatureModelUsage f2 ON f1.MODEL_ID = f2.MODEL_ID AND f1.COLUMN_ID != f2.COLUMN_ID
    GROUP BY f1.COLUMN_ID, f2.COLUMN_ID
),
TransformationDependencies AS (
    -- Phân tích logic biến đổi để tìm các phụ thuộc trực tiếp (dựa trên tên cột)
    SELECT 
        fi1.COLUMN_ID AS FEATURE_ID,
        fi2.COLUMN_ID AS DEPENDENT_FEATURE_ID,
        1 AS IS_DIRECT_DEPENDENCY
    FROM FeatureInfo fi1
    JOIN FeatureInfo fi2 ON fi1.COLUMN_ID != fi2.COLUMN_ID
    WHERE fi1.TRANSFORMATION_LOGIC LIKE CONCAT('%', fi2.COLUMN_NAME, '%')
    -- Bổ sung các điều kiện tương tự cho các mẫu SQL khác có thể có trong logic biến đổi
    OR fi1.TRANSFORMATION_LOGIC LIKE CONCAT('%[', fi2.COLUMN_NAME, ']%')
    OR fi1.TRANSFORMATION_LOGIC LIKE CONCAT('%"', fi2.COLUMN_NAME, '"%')
)
SELECT 
    fi1.COLUMN_ID AS FEATURE_ID,
    fi1.COLUMN_NAME AS FEATURE_NAME,
    fi1.SOURCE_DATABASE + '.' + fi1.SOURCE_SCHEMA + '.' + fi1.SOURCE_TABLE_NAME AS FEATURE_SOURCE,
    fi1.DATA_TYPE AS FEATURE_DATA_TYPE,
    fi2.COLUMN_ID AS DEPENDENT_FEATURE_ID,
    fi2.COLUMN_NAME AS DEPENDENT_FEATURE_NAME,
    fi2.SOURCE_DATABASE + '.' + fi2.SOURCE_SCHEMA + '.' + fi2.SOURCE_TABLE_NAME AS DEPENDENT_FEATURE_SOURCE,
    fi2.DATA_TYPE AS DEPENDENT_FEATURE_DATA_TYPE,
    CASE 
        WHEN td.IS_DIRECT_DEPENDENCY = 1 THEN 'DIRECT'
        ELSE 'INDIRECT'
    END AS DEPENDENCY_TYPE,
    CASE
        WHEN td.IS_DIRECT_DEPENDENCY = 1 THEN 'Derived from transformation logic'
        ELSE 'Co-occurring in models'
    END AS DEPENDENCY_DESCRIPTION,
    cf.SHARED_MODELS_COUNT,
    CASE 
        WHEN cf.SHARED_MODELS_COUNT >= 5 THEN 'STRONG'
        WHEN cf.SHARED_MODELS_COUNT >= 3 THEN 'MODERATE'
        WHEN cf.SHARED_MODELS_COUNT >= 1 THEN 'WEAK'
        ELSE 'UNKNOWN'
    END AS COOCCURRENCE_STRENGTH,
    -- Thông tin về tầm quan trọng của mối quan hệ
    CAST((fi1.FEATURE_IMPORTANCE * fi2.FEATURE_IMPORTANCE) AS DECIMAL(10,2)) AS COMBINED_IMPORTANCE,
    -- Kiểm tra cùng bảng nguồn hay khác bảng
    CASE WHEN fi1.SOURCE_TABLE_ID = fi2.SOURCE_TABLE_ID THEN 'SAME_TABLE' ELSE 'CROSS_TABLE' END AS RELATIONSHIP_SCOPE,
    -- Kiểm tra loại dữ liệu tương thích
    CASE 
        WHEN fi1.DATA_TYPE = fi2.DATA_TYPE THEN 'COMPATIBLE'
        WHEN (fi1.DATA_TYPE LIKE '%INT%' AND fi2.DATA_TYPE LIKE '%INT%') OR
             (fi1.DATA_TYPE LIKE '%NUMERIC%' AND fi2.DATA_TYPE LIKE '%NUMERIC%') OR
             (fi1.DATA_TYPE LIKE '%DECIMAL%' AND fi2.DATA_TYPE LIKE '%DECIMAL%') OR
             (fi1.DATA_TYPE LIKE '%FLOAT%' AND fi2.DATA_TYPE LIKE '%FLOAT%') THEN 'NUMERIC_COMPATIBLE'
        WHEN (fi1.DATA_TYPE LIKE '%CHAR%' AND fi2.DATA_TYPE LIKE '%CHAR%') OR
             (fi1.DATA_TYPE LIKE '%TEXT%' AND fi2.DATA_TYPE LIKE '%TEXT%') THEN 'TEXT_COMPATIBLE'
        WHEN (fi1.DATA_TYPE LIKE '%DATE%' AND fi2.DATA_TYPE LIKE '%DATE%') OR
             (fi1.DATA_TYPE LIKE '%TIME%' AND fi2.DATA_TYPE LIKE '%TIME%') THEN 'DATETIME_COMPATIBLE'
        ELSE 'INCOMPATIBLE'
    END AS DATA_TYPE_COMPATIBILITY,
    -- Trích xuất logic biến đổi nếu có sự phụ thuộc trực tiếp
    CASE 
        WHEN td.IS_DIRECT_DEPENDENCY = 1 THEN
            SUBSTRING(
                fi1.TRANSFORMATION_LOGIC,
                PATINDEX('%' + fi2.COLUMN_NAME + '%', fi1.TRANSFORMATION_LOGIC),
                100
            )
        ELSE NULL
    END AS TRANSFORMATION_EXCERPT
FROM FeatureInfo fi1
JOIN CooccurringFeatures cf ON fi1.COLUMN_ID = cf.FEATURE_ID
JOIN FeatureInfo fi2 ON cf.DEPENDENT_FEATURE_ID = fi2.COLUMN_ID
LEFT JOIN TransformationDependencies td ON fi1.COLUMN_ID = td.FEATURE_ID AND fi2.COLUMN_ID = td.DEPENDENT_FEATURE_ID
-- Lọc để chỉ hiển thị các mối quan hệ có ý nghĩa
WHERE (cf.SHARED_MODELS_COUNT >= 2 OR td.IS_DIRECT_DEPENDENCY = 1);
GO

-- Thêm comment cho view
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'View hiển thị mối quan hệ phụ thuộc giữa các đặc trưng', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'VIEW',  @level1name = N'VW_FEATURE_DEPENDENCIES';
GO

PRINT N'View VW_FEATURE_DEPENDENCIES đã được tạo thành công';
GO