/*
Tên file: 09_vw_feature_lineage.sql
Mô tả: Tạo view VW_FEATURE_LINEAGE để hiển thị phả hệ (lineage) từ nguồn đến đặc trưng đến mô hình
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-15
Phiên bản: 1.0
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu view đã tồn tại thì xóa
IF EXISTS (SELECT * FROM sys.views WHERE name = 'VW_FEATURE_LINEAGE' AND schema_id = SCHEMA_ID('dbo'))
    DROP VIEW dbo.VW_FEATURE_LINEAGE;
GO

-- Tạo view VW_FEATURE_LINEAGE
CREATE VIEW dbo.VW_FEATURE_LINEAGE AS
WITH FeatureData AS (
    -- Thông tin cơ bản về các đặc trưng
    SELECT 
        cd.COLUMN_ID,
        cd.SOURCE_TABLE_ID,
        cd.COLUMN_NAME,
        cd.DATA_TYPE,
        cd.FEATURE_IMPORTANCE,
        cd.BUSINESS_DEFINITION,
        cd.TRANSFORMATION_LOGIC,
        cd.IS_FEATURE,
        st.SOURCE_DATABASE,
        st.SOURCE_SCHEMA,
        st.SOURCE_TABLE_NAME,
        st.TABLE_TYPE,
        st.DATA_OWNER,
        st.UPDATE_FREQUENCY
    FROM MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd
    JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON cd.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
    WHERE cd.IS_FEATURE = 1
),
SourceTableRefresh AS (
    -- Thông tin về cập nhật dữ liệu nguồn
    SELECT 
        srl.SOURCE_TABLE_ID,
        MAX(srl.PROCESS_DATE) AS LAST_REFRESH_DATE,
        MAX(srl.REFRESH_TYPE) AS LAST_REFRESH_TYPE
    FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG srl
    WHERE srl.REFRESH_STATUS = 'COMPLETED'
    GROUP BY srl.SOURCE_TABLE_ID
),
FeatureModelUsage AS (
    -- Ánh xạ đặc trưng vào mô hình và thông tin về tầm quan trọng
    SELECT 
        cd.COLUMN_ID,
        mr.MODEL_ID,
        mr.MODEL_NAME,
        mr.MODEL_VERSION,
        mt.TYPE_CODE AS MODEL_TYPE,
        mr.MODEL_CATEGORY,
        tm.USAGE_TYPE,
        tm.SEQUENCE_ORDER,
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
        CASE 
            WHEN mr.IS_ACTIVE = 0 THEN 'INACTIVE'
            WHEN GETDATE() BETWEEN mr.EFF_DATE AND mr.EXP_DATE THEN 'ACTIVE'
            WHEN GETDATE() < mr.EFF_DATE THEN 'PENDING'
            WHEN GETDATE() > mr.EXP_DATE THEN 'EXPIRED'
            ELSE 'UNKNOWN'
        END AS MODEL_STATUS
    FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
    JOIN MODEL_REGISTRY.dbo.MODEL_TYPE mt ON mr.TYPE_ID = mt.TYPE_ID
    JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING tm ON mr.MODEL_ID = tm.MODEL_ID
    JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON tm.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
    JOIN MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd ON st.SOURCE_TABLE_ID = cd.SOURCE_TABLE_ID
    WHERE cd.IS_FEATURE = 1
),
FeatureDerivedFrom AS (
    -- Phân tích ngược để xác định các cột nguồn cho đặc trưng
    SELECT 
        fd1.COLUMN_ID AS FEATURE_ID,
        fd2.COLUMN_ID AS SOURCE_COLUMN_ID,
        fd2.COLUMN_NAME AS SOURCE_COLUMN_NAME,
        fd2.SOURCE_DATABASE + '.' + fd2.SOURCE_SCHEMA + '.' + fd2.SOURCE_TABLE_NAME AS SOURCE_LOCATION,
        CASE
            WHEN fd1.TRANSFORMATION_LOGIC LIKE CONCAT('%', fd2.COLUMN_NAME, '%')
                 OR fd1.TRANSFORMATION_LOGIC LIKE CONCAT('%[', fd2.COLUMN_NAME, ']%')
                 OR fd1.TRANSFORMATION_LOGIC LIKE CONCAT('%"', fd2.COLUMN_NAME, '"%') THEN 'DIRECT'
            ELSE 'INDIRECT'
        END AS DERIVATION_TYPE
    FROM FeatureData fd1
    CROSS JOIN FeatureData fd2
    WHERE fd1.COLUMN_ID != fd2.COLUMN_ID
    AND (
        fd1.TRANSFORMATION_LOGIC LIKE CONCAT('%', fd2.COLUMN_NAME, '%')
        OR fd1.TRANSFORMATION_LOGIC LIKE CONCAT('%[', fd2.COLUMN_NAME, ']%')
        OR fd1.TRANSFORMATION_LOGIC LIKE CONCAT('%"', fd2.COLUMN_NAME, '"%')
    )
),
ModelOutput AS (
    -- Thông tin về đầu ra của mô hình
    SELECT 
        mr.MODEL_ID,
        mr.SOURCE_DATABASE + '.' + mr.SOURCE_SCHEMA + '.' + mr.SOURCE_TABLE_NAME AS OUTPUT_LOCATION
    FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
)
SELECT 
    fd.COLUMN_ID,
    fd.COLUMN_NAME AS FEATURE_NAME,
    fd.DATA_TYPE,
    fd.FEATURE_IMPORTANCE,
    fd.SOURCE_DATABASE + '.' + fd.SOURCE_SCHEMA + '.' + fd.SOURCE_TABLE_NAME AS FEATURE_SOURCE_LOCATION,
    fd.TABLE_TYPE AS SOURCE_TABLE_TYPE,
    fd.DATA_OWNER AS SOURCE_DATA_OWNER,
    fd.UPDATE_FREQUENCY AS SOURCE_UPDATE_FREQUENCY,
    str.LAST_REFRESH_DATE,
    str.LAST_REFRESH_TYPE,
    DATEDIFF(DAY, str.LAST_REFRESH_DATE, GETDATE()) AS DAYS_SINCE_REFRESH,
    
    -- Thông tin về chuyển đổi và nguồn gốc
    fd.TRANSFORMATION_LOGIC,
    
    -- Danh sách các cột nguồn
    (
        SELECT STRING_AGG(fdf.SOURCE_COLUMN_NAME, ', ')
        FROM FeatureDerivedFrom fdf
        WHERE fdf.FEATURE_ID = fd.COLUMN_ID
    ) AS SOURCE_COLUMNS,
    
    -- Danh sách các vị trí nguồn
    (
        SELECT STRING_AGG(fdf.SOURCE_LOCATION, ', ')
        FROM FeatureDerivedFrom fdf
        WHERE fdf.FEATURE_ID = fd.COLUMN_ID
    ) AS SOURCE_LOCATIONS,
    
    -- Số lượng mô hình sử dụng đặc trưng này
    (
        SELECT COUNT(DISTINCT MODEL_ID)
        FROM FeatureModelUsage fmu
        WHERE fmu.COLUMN_ID = fd.COLUMN_ID
    ) AS MODELS_COUNT,
    
    -- Danh sách các mô hình sử dụng đặc trưng này
    (
        SELECT STRING_AGG(CONCAT(MODEL_NAME, ' (', MODEL_VERSION, ')'), ', ')
        FROM FeatureModelUsage fmu
        WHERE fmu.COLUMN_ID = fd.COLUMN_ID
    ) AS MODELS_USING_FEATURE,
    
    -- Danh sách loại mô hình sử dụng đặc trưng này
    (
        SELECT STRING_AGG(MODEL_TYPE, ', ')
        FROM FeatureModelUsage fmu
        WHERE fmu.COLUMN_ID = fd.COLUMN_ID
    ) AS MODEL_TYPES,
    
    -- Danh sách phân khúc mô hình sử dụng đặc trưng này
    (
        SELECT STRING_AGG(MODEL_CATEGORY, ', ')
        FROM FeatureModelUsage fmu
        WHERE fmu.COLUMN_ID = fd.COLUMN_ID
    ) AS MODEL_CATEGORIES,
    
    -- Số lượng mô hình active sử dụng đặc trưng này
    (
        SELECT COUNT(DISTINCT MODEL_ID)
        FROM FeatureModelUsage fmu
        WHERE fmu.COLUMN_ID = fd.COLUMN_ID
        AND fmu.MODEL_STATUS = 'ACTIVE'
    ) AS ACTIVE_MODELS_COUNT,
    
    -- Tầm quan trọng của đặc trưng dựa trên lịch sử sử dụng
    CASE 
        WHEN (
            SELECT COUNT(DISTINCT MODEL_ID)
            FROM FeatureModelUsage fmu
            WHERE fmu.COLUMN_ID = fd.COLUMN_ID
            AND fmu.IS_EXPLICITLY_REQUIRED = 1
        ) >= 3 THEN 'HIGH'
        WHEN (
            SELECT COUNT(DISTINCT MODEL_ID)
            FROM FeatureModelUsage fmu
            WHERE fmu.COLUMN_ID = fd.COLUMN_ID
        ) >= 5 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS USAGE_IMPORTANCE,
    
    -- Danh sách đầu ra của mô hình sử dụng đặc trưng này
    (
        SELECT STRING_AGG(mo.OUTPUT_LOCATION, ', ')
        FROM FeatureModelUsage fmu
        JOIN ModelOutput mo ON fmu.MODEL_ID = mo.MODEL_ID
        WHERE fmu.COLUMN_ID = fd.COLUMN_ID
    ) AS MODEL_OUTPUTS,
    
    -- Người tạo và thời gian
    fd.BUSINESS_DEFINITION,
    CASE 
        WHEN (SELECT COUNT(*) FROM FeatureDerivedFrom fdf WHERE fdf.FEATURE_ID = fd.COLUMN_ID) > 0 THEN 'DERIVED'
        ELSE 'RAW'
    END AS FEATURE_TYPE
FROM FeatureData fd
LEFT JOIN SourceTableRefresh str ON fd.SOURCE_TABLE_ID = str.SOURCE_TABLE_ID;
GO

-- Thêm comment cho view
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'View hiển thị phả hệ (lineage) từ nguồn đến đặc trưng đến mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'VIEW',  @level1name = N'VW_FEATURE_LINEAGE';
GO

PRINT N'View VW_FEATURE_LINEAGE đã được tạo thành công';
GO