/*
Tên file: 02_vw_model_type_info.sql
Mô tả: Tạo view VW_MODEL_TYPE_INFO để hiển thị thông tin tổng hợp về mô hình và loại mô hình
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.0
*/

-- Kiểm tra nếu view đã tồn tại thì xóa
IF EXISTS (SELECT * FROM sys.views WHERE name = 'VW_MODEL_TYPE_INFO' AND schema_id = SCHEMA_ID('dbo'))
    DROP VIEW MODEL_REGISTRY.dbo.VW_MODEL_TYPE_INFO;
GO

-- Tạo view VW_MODEL_TYPE_INFO
CREATE VIEW MODEL_REGISTRY.dbo.VW_MODEL_TYPE_INFO AS
SELECT 
    mr.MODEL_ID,
    mr.MODEL_NAME,
    mr.MODEL_VERSION,
    mt.TYPE_ID,
    mt.TYPE_CODE,
    mt.TYPE_NAME,
    mr.MODEL_DESCRIPTION,
    mr.MODEL_CATEGORY,
    mr.SOURCE_DATABASE,
    mr.SOURCE_SCHEMA,
    mr.SOURCE_TABLE_NAME,
    mr.REF_SOURCE,
    mr.EFF_DATE,
    mr.EXP_DATE,
    mr.IS_ACTIVE,
    mr.PRIORITY,
    mr.SEGMENT_CRITERIA,
    CASE 
        WHEN mr.IS_ACTIVE = 0 THEN 'INACTIVE'
        WHEN GETDATE() BETWEEN mr.EFF_DATE AND mr.EXP_DATE THEN 'ACTIVE'
        WHEN GETDATE() < mr.EFF_DATE THEN 'PENDING'
        WHEN GETDATE() > mr.EXP_DATE THEN 'EXPIRED'
        ELSE 'UNKNOWN'
    END AS MODEL_STATUS,
    (
        SELECT COUNT(DISTINCT tu.SOURCE_TABLE_ID)
        FROM MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE tu
        WHERE tu.MODEL_ID = mr.MODEL_ID AND tu.IS_ACTIVE = 1
    ) AS SOURCE_TABLES_COUNT,
    (
        SELECT COUNT(*)
        FROM MODEL_REGISTRY.dbo.MODEL_PARAMETERS p
        WHERE p.MODEL_ID = mr.MODEL_ID
    ) AS PARAMETERS_COUNT,
    (
        SELECT COUNT(*)
        FROM MODEL_REGISTRY.dbo.MODEL_SEGMENT_MAPPING sm
        WHERE sm.MODEL_ID = mr.MODEL_ID AND sm.IS_ACTIVE = 1
    ) AS SEGMENTS_COUNT,
    (
        SELECT MAX(VALIDATION_DATE)
        FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS mvr
        WHERE mvr.MODEL_ID = mr.MODEL_ID
    ) AS LAST_VALIDATION_DATE,
    (
        SELECT TOP 1 mvr.AUC_ROC
        FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS mvr
        WHERE mvr.MODEL_ID = mr.MODEL_ID
        ORDER BY mvr.VALIDATION_DATE DESC
    ) AS LATEST_AUC_ROC,
    (
        SELECT TOP 1 mvr.KS_STATISTIC
        FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS mvr
        WHERE mvr.MODEL_ID = mr.MODEL_ID
        ORDER BY mvr.VALIDATION_DATE DESC
    ) AS LATEST_KS,
    (
        SELECT TOP 1 mvr.PSI
        FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS mvr
        WHERE mvr.MODEL_ID = mr.MODEL_ID
        ORDER BY mvr.VALIDATION_DATE DESC
    ) AS LATEST_PSI,
    (
        SELECT CASE
            WHEN COUNT(*) = 0 THEN NULL
            WHEN MIN(mvr.AUC_ROC) = MAX(mvr.AUC_ROC) THEN 'STABLE'
            WHEN FIRST_VALUE(mvr.AUC_ROC) OVER (ORDER BY mvr.VALIDATION_DATE DESC) >
                 FIRST_VALUE(mvr.AUC_ROC) OVER (ORDER BY mvr.VALIDATION_DATE ASC) THEN 'IMPROVING'
            WHEN FIRST_VALUE(mvr.AUC_ROC) OVER (ORDER BY mvr.VALIDATION_DATE DESC) <
                 FIRST_VALUE(mvr.AUC_ROC) OVER (ORDER BY mvr.VALIDATION_DATE ASC) THEN 'DEGRADING'
            ELSE 'FLUCTUATING'
        END
        FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS mvr
        WHERE mvr.MODEL_ID = mr.MODEL_ID
    ) AS PERFORMANCE_TREND,
    mr.CREATED_BY,
    mr.CREATED_DATE,
    mr.UPDATED_BY,
    mr.UPDATED_DATE
FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
JOIN MODEL_REGISTRY.dbo.MODEL_TYPE mt ON mr.TYPE_ID = mt.TYPE_ID;
GO

-- Thêm comment cho view
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'View hiển thị thông tin tổng hợp về mô hình và loại mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'VIEW',  @level1name = N'VW_MODEL_TYPE_INFO';
GO

PRINT 'View VW_MODEL_TYPE_INFO đã được tạo thành công';
GO