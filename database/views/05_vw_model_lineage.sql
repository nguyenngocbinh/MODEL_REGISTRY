/*
Tên file: 05_vw_model_lineage.sql
Mô tả: Tạo view VW_MODEL_LINEAGE để hiển thị mối quan hệ phả hệ (lineage) giữa các mô hình
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-15
Phiên bản: 1.0
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu view đã tồn tại thì xóa
IF EXISTS (SELECT * FROM sys.views WHERE name = 'VW_MODEL_LINEAGE' AND schema_id = SCHEMA_ID('dbo'))
    DROP VIEW dbo.VW_MODEL_LINEAGE;
GO

-- Tạo view VW_MODEL_LINEAGE
CREATE VIEW dbo.VW_MODEL_LINEAGE AS
WITH ModelVersions AS (
    -- Nhóm các mô hình theo tên và sắp xếp theo phiên bản
    SELECT 
        MODEL_ID,
        MODEL_NAME,
        MODEL_VERSION,
        TYPE_ID,
        ROW_NUMBER() OVER (PARTITION BY MODEL_NAME ORDER BY CASE 
            WHEN ISNUMERIC(REPLACE(MODEL_VERSION, '.', '')) = 1 
            THEN CAST(REPLACE(MODEL_VERSION, '.', '') AS FLOAT)
            ELSE 0
        END) AS VERSION_ORDER
    FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY
),
ModelWithPreviousVersion AS (
    -- Kết nối mỗi mô hình với phiên bản trước đó (nếu có)
    SELECT 
        mv.MODEL_ID,
        mv.MODEL_NAME,
        mv.MODEL_VERSION,
        mv.TYPE_ID,
        prev.MODEL_ID AS PREVIOUS_MODEL_ID,
        prev.MODEL_VERSION AS PREVIOUS_VERSION
    FROM ModelVersions mv
    LEFT JOIN ModelVersions prev ON mv.MODEL_NAME = prev.MODEL_NAME AND prev.VERSION_ORDER = mv.VERSION_ORDER - 1
),
SourceLineage AS (
    -- Xác định các bảng nguồn chung giữa các mô hình
    SELECT DISTINCT
        tu1.MODEL_ID AS TARGET_MODEL_ID,
        tu2.MODEL_ID AS SOURCE_MODEL_ID,
        COUNT(DISTINCT tu1.SOURCE_TABLE_ID) AS SHARED_TABLES_COUNT,
        STRING_AGG(CONCAT(st.SOURCE_DATABASE, '.', st.SOURCE_SCHEMA, '.', st.SOURCE_TABLE_NAME), ', ') AS SHARED_TABLES
    FROM MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE tu1
    JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE tu2 ON tu1.SOURCE_TABLE_ID = tu2.SOURCE_TABLE_ID AND tu1.MODEL_ID != tu2.MODEL_ID
    JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON tu1.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
    WHERE tu1.IS_ACTIVE = 1 AND tu2.IS_ACTIVE = 1
    GROUP BY tu1.MODEL_ID, tu2.MODEL_ID
)
SELECT 
    mvp.MODEL_ID,
    mr1.MODEL_NAME,
    mr1.MODEL_VERSION,
    mt1.TYPE_CODE AS MODEL_TYPE,
    mr1.MODEL_CATEGORY,
    mr1.CREATED_DATE AS MODEL_CREATED_DATE,
    mvp.PREVIOUS_MODEL_ID,
    ISNULL(mr2.MODEL_NAME, '') AS PREVIOUS_MODEL_NAME,
    ISNULL(mr2.MODEL_VERSION, '') AS PREVIOUS_VERSION,
    ISNULL(mt2.TYPE_CODE, '') AS PREVIOUS_MODEL_TYPE,
    
    -- Mô hình kế thừa trực tiếp (theo tên và phiên bản)
    CASE WHEN mvp.PREVIOUS_MODEL_ID IS NOT NULL THEN 'TRUE' ELSE 'FALSE' END AS IS_DIRECT_SUCCESSOR,
    
    -- Thông tin về các mô hình có liên quan (nguồn chung)
    (
        SELECT COUNT(DISTINCT SOURCE_MODEL_ID)
        FROM SourceLineage sl
        WHERE sl.TARGET_MODEL_ID = mvp.MODEL_ID
    ) AS RELATED_MODELS_COUNT,
    
    -- Danh sách các mô hình có nguồn dữ liệu chung
    (
        SELECT STRING_AGG(CONCAT(mr.MODEL_NAME, ' (', mr.MODEL_VERSION, ')'), ', ')
        FROM SourceLineage sl
        JOIN MODEL_REGISTRY.dbo.MODEL_REGISTRY mr ON sl.SOURCE_MODEL_ID = mr.MODEL_ID
        WHERE sl.TARGET_MODEL_ID = mvp.MODEL_ID
    ) AS RELATED_MODELS,
    
    -- Thông tin sự khác biệt giữa các mô hình
    (
        SELECT CAST(COUNT(*) AS VARCHAR) + ' tham số khác biệt'
        FROM MODEL_REGISTRY.dbo.MODEL_PARAMETERS p1
        LEFT JOIN MODEL_REGISTRY.dbo.MODEL_PARAMETERS p2 ON p1.PARAMETER_NAME = p2.PARAMETER_NAME 
                                                         AND p2.MODEL_ID = mvp.PREVIOUS_MODEL_ID
        WHERE p1.MODEL_ID = mvp.MODEL_ID 
        AND (p2.PARAMETER_ID IS NULL OR p1.PARAMETER_VALUE != p2.PARAMETER_VALUE)
    ) AS PARAMETER_DIFFERENCES,

    -- Hiệu suất so với mô hình trước đó
    (
        SELECT TOP 1 CAST(
            CASE 
                WHEN vr1.GINI > ISNULL(vr2.GINI, 0) THEN 'IMPROVED (' + CAST(CAST((vr1.GINI - ISNULL(vr2.GINI, 0)) * 100 AS DECIMAL(10, 2)) AS VARCHAR) + '% GINI)'
                WHEN vr1.GINI < ISNULL(vr2.GINI, 0) THEN 'DEGRADED (' + CAST(CAST((ISNULL(vr2.GINI, 0) - vr1.GINI) * 100 AS DECIMAL(10, 2)) AS VARCHAR) + '% GINI)'
                ELSE 'UNCHANGED'
            END AS VARCHAR)
        FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS vr1
        LEFT JOIN MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS vr2 ON vr2.MODEL_ID = mvp.PREVIOUS_MODEL_ID
        WHERE vr1.MODEL_ID = mvp.MODEL_ID
        ORDER BY vr1.VALIDATION_DATE DESC, vr2.VALIDATION_DATE DESC
    ) AS PERFORMANCE_CHANGE,
    
    -- Thông tin triển khai
    mr1.EFF_DATE,
    mr1.EXP_DATE,
    CASE 
        WHEN mr1.IS_ACTIVE = 0 THEN 'INACTIVE'
        WHEN GETDATE() BETWEEN mr1.EFF_DATE AND mr1.EXP_DATE THEN 'ACTIVE'
        WHEN GETDATE() < mr1.EFF_DATE THEN 'PENDING'
        WHEN GETDATE() > mr1.EXP_DATE THEN 'EXPIRED'
        ELSE 'UNKNOWN'
    END AS MODEL_STATUS,
    
    -- Thông tin về người tạo
    mr1.CREATED_BY,
    mr1.UPDATED_BY,
    mr1.UPDATED_DATE
FROM ModelWithPreviousVersion mvp
JOIN MODEL_REGISTRY.dbo.MODEL_REGISTRY mr1 ON mvp.MODEL_ID = mr1.MODEL_ID
JOIN MODEL_REGISTRY.dbo.MODEL_TYPE mt1 ON mr1.TYPE_ID = mt1.TYPE_ID
LEFT JOIN MODEL_REGISTRY.dbo.MODEL_REGISTRY mr2 ON mvp.PREVIOUS_MODEL_ID = mr2.MODEL_ID
LEFT JOIN MODEL_REGISTRY.dbo.MODEL_TYPE mt2 ON mr2.TYPE_ID = mt2.TYPE_ID;
GO

-- Thêm comment cho view
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'View hiển thị mối quan hệ phả hệ (lineage) giữa các mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'VIEW',  @level1name = N'VW_MODEL_LINEAGE';
GO

PRINT N'View VW_MODEL_LINEAGE đã được tạo thành công';
GO