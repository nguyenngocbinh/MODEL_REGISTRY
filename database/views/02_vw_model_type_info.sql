/*
Tên file: 02_vw_model_type_info.sql
Mô tả: Tạo view VW_MODEL_TYPE_INFO để hiển thị thông tin tổng hợp về mô hình và loại mô hình
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.1 - Cập nhật để phù hợp với bảng MODEL_VALIDATION_RESULTS đã loại bỏ AUC_ROC
*/

SET NOCOUNT ON;
GO

PRINT N'Bắt đầu tạo view VW_MODEL_TYPE_INFO...';

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu view đã tồn tại thì xóa
IF EXISTS (SELECT * FROM sys.views WHERE name = 'VW_MODEL_TYPE_INFO' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    DROP VIEW dbo.VW_MODEL_TYPE_INFO;
    PRINT N'Đã xóa view VW_MODEL_TYPE_INFO hiện có.';
END
GO

-- Tạo view VW_MODEL_TYPE_INFO
CREATE VIEW dbo.VW_MODEL_TYPE_INFO AS
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
        FROM dbo.MODEL_TABLE_USAGE tu
        WHERE tu.MODEL_ID = mr.MODEL_ID AND tu.IS_ACTIVE = 1
    ) AS SOURCE_TABLES_COUNT,
    (
        SELECT COUNT(*)
        FROM dbo.MODEL_PARAMETERS p
        WHERE p.MODEL_ID = mr.MODEL_ID
    ) AS PARAMETERS_COUNT,
    (
        SELECT COUNT(*)
        FROM dbo.MODEL_SEGMENT_MAPPING sm
        WHERE sm.MODEL_ID = mr.MODEL_ID AND sm.IS_ACTIVE = 1
    ) AS SEGMENTS_COUNT,
    (
        SELECT MAX(VALIDATION_DATE)
        FROM dbo.MODEL_VALIDATION_RESULTS mvr
        WHERE mvr.MODEL_ID = mr.MODEL_ID
    ) AS LAST_VALIDATION_DATE,
    (
        SELECT TOP 1 mvr.GINI
        FROM dbo.MODEL_VALIDATION_RESULTS mvr
        WHERE mvr.MODEL_ID = mr.MODEL_ID
        ORDER BY mvr.VALIDATION_DATE DESC
    ) AS LATEST_GINI,
    (
        SELECT TOP 1 mvr.KS_STATISTIC
        FROM dbo.MODEL_VALIDATION_RESULTS mvr
        WHERE mvr.MODEL_ID = mr.MODEL_ID
        ORDER BY mvr.VALIDATION_DATE DESC
    ) AS LATEST_KS,
    (
        SELECT TOP 1 mvr.PSI
        FROM dbo.MODEL_VALIDATION_RESULTS mvr
        WHERE mvr.MODEL_ID = mr.MODEL_ID
        ORDER BY mvr.VALIDATION_DATE DESC
    ) AS LATEST_PSI,
    ISNULL(trend.PERFORMANCE_TREND, 'NO_DATA') AS PERFORMANCE_TREND,
    mr.CREATED_BY,
    mr.CREATED_DATE,
    mr.UPDATED_BY,
    mr.UPDATED_DATE
FROM dbo.MODEL_REGISTRY mr
JOIN dbo.MODEL_TYPE mt ON mr.TYPE_ID = mt.TYPE_ID
OUTER APPLY (
    SELECT TOP 1 
        CASE
            WHEN MinGini = MaxGini THEN 'STABLE'
            WHEN FirstGiniDescending > FirstGiniAscending THEN 'IMPROVING'
            WHEN FirstGiniDescending < FirstGiniAscending THEN 'DEGRADING'
            ELSE 'FLUCTUATING'
        END AS PERFORMANCE_TREND
    FROM (
        SELECT DISTINCT
            MIN(mvr.GINI) OVER () AS MinGini,
            MAX(mvr.GINI) OVER () AS MaxGini,
            FIRST_VALUE(mvr.GINI) OVER (ORDER BY mvr.VALIDATION_DATE DESC) AS FirstGiniDescending,
            FIRST_VALUE(mvr.GINI) OVER (ORDER BY mvr.VALIDATION_DATE ASC) AS FirstGiniAscending
        FROM dbo.MODEL_VALIDATION_RESULTS mvr
        WHERE mvr.MODEL_ID = mr.MODEL_ID
    ) AS stats
) AS trend;
GO


PRINT N'View VW_MODEL_TYPE_INFO đã được tạo.';

-- Thêm comment cho view bằng phương pháp an toàn
BEGIN TRY
    -- Kiểm tra xem thuộc tính đã tồn tại chưa
    IF EXISTS (
        SELECT 1 FROM sys.extended_properties 
        WHERE major_id = OBJECT_ID('dbo.VW_MODEL_TYPE_INFO') 
          AND minor_id = 0
          AND name = 'MS_Description'
    )
    BEGIN
        -- Nếu đã tồn tại, cập nhật lại
        EXEC sys.sp_updateextendedproperty 
            @name = N'MS_Description', 
            @value = N'View hiển thị thông tin tổng hợp về mô hình và loại mô hình', 
            @level0type = N'SCHEMA', @level0name = N'dbo', 
            @level1type = N'VIEW', @level1name = N'VW_MODEL_TYPE_INFO';
        PRINT N'Đã cập nhật mô tả cho view VW_MODEL_TYPE_INFO.';
    END
    ELSE
    BEGIN
        -- Nếu chưa tồn tại, thêm mới
        EXEC sys.sp_addextendedproperty 
            @name = N'MS_Description', 
            @value = N'View hiển thị thông tin tổng hợp về mô hình và loại mô hình', 
            @level0type = N'SCHEMA', @level0name = N'dbo', 
            @level1type = N'VIEW', @level1name = N'VW_MODEL_TYPE_INFO';
        PRINT N'Đã thêm mô tả cho view VW_MODEL_TYPE_INFO.';
    END
END TRY
BEGIN CATCH
    PRINT N'Cảnh báo: Không thể thêm/cập nhật extended properties cho view. Lỗi: ' + ERROR_MESSAGE();
    -- Vẫn tiếp tục thực thi - không dừng script vì lỗi này
END CATCH
GO

PRINT N'Hoàn thành tạo view VW_MODEL_TYPE_INFO.';