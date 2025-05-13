/*
Tên file: 03_vw_model_performance.sql
Mô tả: Tạo view VW_MODEL_PERFORMANCE để hiển thị thông tin về hiệu suất của các mô hình theo thời gian
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.1 - Cập nhật theo các ngưỡng đánh giá hiệu suất mới
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu view đã tồn tại thì xóa
IF EXISTS (SELECT * FROM sys.views WHERE name = 'VW_MODEL_PERFORMANCE' AND schema_id = SCHEMA_ID('dbo'))
    DROP VIEW dbo.VW_MODEL_PERFORMANCE;
GO

-- Tạo view VW_MODEL_PERFORMANCE
CREATE VIEW dbo.VW_MODEL_PERFORMANCE AS
SELECT 
    mvr.VALIDATION_ID,
    mr.MODEL_ID,
    mr.MODEL_NAME,
    mr.MODEL_VERSION,
    mt.TYPE_CODE,
    mt.TYPE_NAME,
    mr.MODEL_CATEGORY,
    mvr.VALIDATION_DATE,
    mvr.VALIDATION_TYPE,
    mvr.VALIDATION_PERIOD,
    mvr.DATA_SAMPLE_SIZE,
    mvr.DATA_SAMPLE_DESCRIPTION,    
    mvr.KS_STATISTIC,
    mvr.GINI,
    mvr.PSI,
    mvr.ACCURACY,
    mvr.PRECISION,
    mvr.RECALL,
    mvr.F1_SCORE,
    mvr.IV,
    mvr.BRIER_SCORE,
    mvr.LOG_LOSS,
    mvr.CSI,
    
    LAG(mvr.KS_STATISTIC) OVER (PARTITION BY mr.MODEL_ID ORDER BY mvr.VALIDATION_DATE) AS PREV_KS,
    CASE 
        WHEN LAG(mvr.KS_STATISTIC) OVER (PARTITION BY mr.MODEL_ID ORDER BY mvr.VALIDATION_DATE) IS NOT NULL 
        THEN (mvr.KS_STATISTIC - LAG(mvr.KS_STATISTIC) OVER (PARTITION BY mr.MODEL_ID ORDER BY mvr.VALIDATION_DATE)) 
              / LAG(mvr.KS_STATISTIC) OVER (PARTITION BY mr.MODEL_ID ORDER BY mvr.VALIDATION_DATE) * 100
        ELSE NULL
    END AS KS_CHANGE_PCT,
    
    LAG(mvr.PSI) OVER (PARTITION BY mr.MODEL_ID ORDER BY mvr.VALIDATION_DATE) AS PREV_PSI,
    CASE 
        WHEN LAG(mvr.PSI) OVER (PARTITION BY mr.MODEL_ID ORDER BY mvr.VALIDATION_DATE) IS NOT NULL 
        THEN (mvr.PSI - LAG(mvr.PSI) OVER (PARTITION BY mr.MODEL_ID ORDER BY mvr.VALIDATION_DATE)) 
              / NULLIF(LAG(mvr.PSI) OVER (PARTITION BY mr.MODEL_ID ORDER BY mvr.VALIDATION_DATE), 0) * 100
        ELSE NULL
    END AS PSI_CHANGE_PCT,
    
    -- Đánh giá hiệu suất dựa trên các ngưỡng cập nhật    
    -- KS Rating: <0.2 (Red), 0.2-0.3 (Amber), >0.3 (Green)
    CASE 
        WHEN mvr.KS_STATISTIC < 0.2 THEN 'RED'
        WHEN mvr.KS_STATISTIC >= 0.2 AND mvr.KS_STATISTIC <= 0.3 THEN 'AMBER'
        WHEN mvr.KS_STATISTIC > 0.3 THEN 'GREEN'
        ELSE 'N/A'
    END AS KS_RATING,
    
    -- GINI Rating: <0.2 (Red), 0.2-0.4 (Amber), >0.4 (Green)
    CASE 
        WHEN mvr.GINI < 0.2 THEN 'RED'
        WHEN mvr.GINI >= 0.2 AND mvr.GINI <= 0.4 THEN 'AMBER'
        WHEN mvr.GINI > 0.4 THEN 'GREEN'
        ELSE 'N/A'
    END AS GINI_RATING,
    
    -- PSI Rating: >0.25 (Red), 0.1-0.25 (Amber), <0.1 (Green)
    CASE 
        WHEN mvr.PSI > 0.25 THEN 'RED'
        WHEN mvr.PSI >= 0.1 AND mvr.PSI <= 0.25 THEN 'AMBER'
        WHEN mvr.PSI < 0.1 THEN 'GREEN'
        ELSE 'N/A'
    END AS PSI_RATING,
    
    -- IV Rating: <0.02 (Red), 0.02-0.1 (Amber), >0.1 (Green)
    CASE 
        WHEN mvr.IV < 0.02 THEN 'RED'
        WHEN mvr.IV >= 0.02 AND mvr.IV <= 0.1 THEN 'AMBER'
        WHEN mvr.IV > 0.1 THEN 'GREEN'
        ELSE 'N/A'
    END AS IV_RATING,
    
    -- KAPPA Rating (mới thêm): <0.2 (Red), 0.2-0.6 (Amber), >0.6 (Green)
    CASE 
        WHEN mvr.F1_SCORE < 0.2 THEN 'RED'  -- Giả sử KAPPA = F1_SCORE nếu không có trường KAPPA
        WHEN mvr.F1_SCORE >= 0.2 AND mvr.F1_SCORE < 0.6 THEN 'AMBER'
        WHEN mvr.F1_SCORE >= 0.6 THEN 'GREEN'
        ELSE 'N/A'
    END AS KAPPA_RATING,
    
    -- Đánh giá tổng thể - cập nhật theo quy tắc mới (có ít nhất 1 Red = Red, nhiều hơn 2 Amber = Red, 1-2 Amber = Amber, tất cả Green = Green)
    CASE 
        WHEN
            mvr.KS_STATISTIC < 0.2 OR
            mvr.GINI < 0.2 OR
            mvr.PSI > 0.25 OR
            mvr.IV < 0.02 OR
            mvr.F1_SCORE < 0.2  -- KAPPA
        THEN 'RED'
        WHEN (
            (CASE WHEN mvr.KS_STATISTIC >= 0.2 AND mvr.KS_STATISTIC <= 0.3 THEN 1 ELSE 0 END) +
            (CASE WHEN mvr.GINI >= 0.2 AND mvr.GINI <= 0.4 THEN 1 ELSE 0 END) +
            (CASE WHEN mvr.PSI >= 0.1 AND mvr.PSI <= 0.25 THEN 1 ELSE 0 END) +
            (CASE WHEN mvr.IV >= 0.02 AND mvr.IV <= 0.1 THEN 1 ELSE 0 END) +
            (CASE WHEN mvr.F1_SCORE >= 0.2 AND mvr.F1_SCORE < 0.6 THEN 1 ELSE 0 END)  -- KAPPA
        ) > 2 THEN 'RED'
        WHEN (            
            (CASE WHEN mvr.KS_STATISTIC >= 0.2 AND mvr.KS_STATISTIC <= 0.3 THEN 1 ELSE 0 END) +
            (CASE WHEN mvr.GINI >= 0.2 AND mvr.GINI <= 0.4 THEN 1 ELSE 0 END) +
            (CASE WHEN mvr.PSI >= 0.1 AND mvr.PSI <= 0.25 THEN 1 ELSE 0 END) +
            (CASE WHEN mvr.IV >= 0.02 AND mvr.IV <= 0.1 THEN 1 ELSE 0 END) +
            (CASE WHEN mvr.F1_SCORE >= 0.2 AND mvr.F1_SCORE < 0.6 THEN 1 ELSE 0 END)  -- KAPPA
        ) >= 1 THEN 'AMBER'
        ELSE 'GREEN'
    END AS OVERALL_RATING,
    
    -- Thông tin khác
    mvr.VALIDATION_STATUS,
    mvr.VALIDATION_THRESHOLD_BREACHED,
    mvr.VALIDATION_COMMENTS,
    mvr.VALIDATED_BY,
    mvr.APPROVED_BY,
    mvr.APPROVED_DATE,
    mvr.CREATED_DATE,
    mvr.CREATED_BY,
    
    -- Thông tin về hiệu lực của mô hình
    mr.EFF_DATE AS MODEL_EFF_DATE,
    mr.EXP_DATE AS MODEL_EXP_DATE,
    mr.IS_ACTIVE AS MODEL_IS_ACTIVE,
    CASE 
        WHEN mr.IS_ACTIVE = 0 THEN 'INACTIVE'
        WHEN GETDATE() BETWEEN mr.EFF_DATE AND mr.EXP_DATE THEN 'ACTIVE'
        WHEN GETDATE() < mr.EFF_DATE THEN 'PENDING'
        WHEN GETDATE() > mr.EXP_DATE THEN 'EXPIRED'
        ELSE 'UNKNOWN'
    END AS MODEL_STATUS
FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS mvr
JOIN MODEL_REGISTRY.dbo.MODEL_REGISTRY mr ON mvr.MODEL_ID = mr.MODEL_ID
JOIN MODEL_REGISTRY.dbo.MODEL_TYPE mt ON mr.TYPE_ID = mt.TYPE_ID;
GO

-- Thêm comment cho view
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'View hiển thị thông tin về hiệu suất của các mô hình theo thời gian với các ngưỡng đánh giá cập nhật', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'VIEW',  @level1name = N'VW_MODEL_PERFORMANCE';
GO

PRINT N'View VW_MODEL_PERFORMANCE đã được cập nhật thành công với các ngưỡng đánh giá mới';
GO