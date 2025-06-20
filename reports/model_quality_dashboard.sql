/*
Tên file: model_quality_dashboard.sql
Mô tả: Báo cáo tổng hợp về chất lượng mô hình và đặc trưng cho dashboard
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-06-19
Phiên bản: 1.0
*/

-- ====================================================
-- BÁO CÁO TỔNG HỢP CHẤT LƯỢNG MÔ HÌNH VÀ ĐẶC TRƯNG
-- ====================================================

-- 1. Tổng quan về tình trạng mô hình
PRINT '1. TỔNG QUAN VỀ TÌNH TRẠNG MÔ HÌNH';
PRINT '==========================================';

SELECT 
    'MODEL_STATUS_OVERVIEW' AS REPORT_SECTION,
    mt.TYPE_NAME AS MODEL_TYPE,
    COUNT(*) AS TOTAL_MODELS,
    SUM(CASE WHEN mr.IS_ACTIVE = 1 AND GETDATE() BETWEEN mr.EFF_DATE AND mr.EXP_DATE THEN 1 ELSE 0 END) AS ACTIVE_MODELS,
    SUM(CASE WHEN mr.IS_ACTIVE = 1 AND GETDATE() > mr.EXP_DATE THEN 1 ELSE 0 END) AS EXPIRED_MODELS,
    SUM(CASE WHEN mr.IS_ACTIVE = 0 THEN 1 ELSE 0 END) AS INACTIVE_MODELS,
    SUM(CASE WHEN mr.IS_ACTIVE = 1 AND GETDATE() < mr.EFF_DATE THEN 1 ELSE 0 END) AS PENDING_MODELS
FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
JOIN MODEL_REGISTRY.dbo.MODEL_TYPE mt ON mr.TYPE_ID = mt.TYPE_ID
GROUP BY mt.TYPE_NAME
ORDER BY mt.TYPE_NAME;

-- 2. Tình trạng hiệu suất mô hình gần đây
PRINT '';
PRINT '2. TÌNH TRẠNG HIỆU SUẤT MÔ HÌNH GẦN ĐÂY';
PRINT '==========================================';

WITH RecentPerformance AS (
    SELECT 
        mr.MODEL_ID,
        mr.MODEL_NAME,
        mr.MODEL_VERSION,
        mt.TYPE_NAME,
        mvr.VALIDATION_DATE,
        mvr.GINI,
        mvr.KS_STATISTIC,
        mvr.PSI,
        mvr.ACCURACY,
        ROW_NUMBER() OVER (PARTITION BY mr.MODEL_ID ORDER BY mvr.VALIDATION_DATE DESC) as rn
    FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
    JOIN MODEL_REGISTRY.dbo.MODEL_TYPE mt ON mr.TYPE_ID = mt.TYPE_ID
    JOIN MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS mvr ON mr.MODEL_ID = mvr.MODEL_ID
    WHERE mr.IS_ACTIVE = 1
    AND mvr.VALIDATION_DATE >= DATEADD(MONTH, -6, GETDATE())
)
SELECT 
    'MODEL_PERFORMANCE_RECENT' AS REPORT_SECTION,
    rp.MODEL_ID,
    rp.MODEL_NAME,
    rp.MODEL_VERSION,
    rp.TYPE_NAME,
    rp.VALIDATION_DATE,
    rp.GINI,
    rp.KS_STATISTIC,
    rp.PSI,
    rp.ACCURACY,
    CASE 
        WHEN rp.GINI >= 0.4 AND rp.PSI <= 0.25 THEN 'GOOD'
        WHEN rp.GINI >= 0.3 AND rp.PSI <= 0.35 THEN 'ACCEPTABLE'
        ELSE 'NEEDS_REVIEW'
    END AS PERFORMANCE_STATUS,
    CASE 
        WHEN rp.PSI > 0.25 THEN 'HIGH_INSTABILITY'
        WHEN rp.GINI < 0.3 THEN 'LOW_DISCRIMINATION'
        WHEN rp.KS_STATISTIC < 0.2 THEN 'POOR_SEPARATION'
        ELSE 'OK'
    END AS MAIN_CONCERN
FROM RecentPerformance rp
WHERE rp.rn = 1
ORDER BY 
    CASE 
        WHEN rp.GINI >= 0.4 AND rp.PSI <= 0.25 THEN 3
        WHEN rp.GINI >= 0.3 AND rp.PSI <= 0.35 THEN 2
        ELSE 1
    END,
    rp.PSI DESC;

-- 3. Tình trạng chất lượng dữ liệu nguồn
PRINT '';
PRINT '3. TÌNH TRẠNG CHẤT LƯỢNG DỮ LIỆU NGUỒN';
PRINT '==========================================';

SELECT 
    'DATA_QUALITY_STATUS' AS REPORT_SECTION,
    st.TABLE_TYPE,
    COUNT(DISTINCT st.SOURCE_TABLE_ID) AS TOTAL_TABLES,
    AVG(st.DATA_QUALITY_SCORE) AS AVG_QUALITY_SCORE,
    SUM(CASE WHEN st.DATA_QUALITY_SCORE >= 80 THEN 1 ELSE 0 END) AS HIGH_QUALITY_TABLES,
    SUM(CASE WHEN st.DATA_QUALITY_SCORE BETWEEN 60 AND 79 THEN 1 ELSE 0 END) AS MEDIUM_QUALITY_TABLES,
    SUM(CASE WHEN st.DATA_QUALITY_SCORE < 60 THEN 1 ELSE 0 END) AS LOW_QUALITY_TABLES,
    COUNT(DISTINCT CASE 
        WHEN EXISTS (
            SELECT 1 FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG srl 
            WHERE srl.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID 
            AND srl.REFRESH_STATUS = 'COMPLETED' 
            AND srl.PROCESS_DATE = CAST(GETDATE() AS DATE)
        ) THEN st.SOURCE_TABLE_ID 
    END) AS TABLES_REFRESHED_TODAY
FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st
WHERE st.IS_ACTIVE = 1
GROUP BY st.TABLE_TYPE
ORDER BY st.TABLE_TYPE;

-- 4. Vấn đề chất lượng dữ liệu mở
PRINT '';
PRINT '4. VẤN ĐỀ CHẤT LƯỢNG DỮ LIỆU MỞ';
PRINT '==========================================';

SELECT 
    'DATA_QUALITY_ISSUES' AS REPORT_SECTION,
    dq.SEVERITY,
    dq.ISSUE_TYPE,
    dq.ISSUE_CATEGORY,
    COUNT(*) AS ISSUE_COUNT,
    SUM(dq.RECORDS_AFFECTED) AS TOTAL_RECORDS_AFFECTED,
    AVG(dq.PERCENTAGE_AFFECTED) AS AVG_PERCENTAGE_AFFECTED,
    MIN(dq.PROCESS_DATE) AS OLDEST_ISSUE_DATE,
    MAX(dq.PROCESS_DATE) AS NEWEST_ISSUE_DATE
FROM MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG dq
WHERE dq.REMEDIATION_STATUS IN ('OPEN', 'IN_PROGRESS')
AND dq.PROCESS_DATE >= DATEADD(MONTH, -3, GETDATE())
GROUP BY dq.SEVERITY, dq.ISSUE_TYPE, dq.ISSUE_CATEGORY
ORDER BY 
    CASE dq.SEVERITY 
        WHEN 'CRITICAL' THEN 1 
        WHEN 'HIGH' THEN 2 
        WHEN 'MEDIUM' THEN 3 
        ELSE 4 
    END,
    COUNT(*) DESC;

-- 5. Thống kê đặc trưng theo chất lượng
PRINT '';
PRINT '5. THỐNG KÊ ĐẶC TRƯNG THEO CHẤT LƯỢNG';
PRINT '==========================================';

-- Tạo view tạm để đánh giá chất lượng đặc trưng
WITH FeatureQuality AS (
    SELECT 
        fr.FEATURE_ID,
        fr.FEATURE_NAME,
        fr.FEATURE_CODE,
        fr.DATA_TYPE,
        fr.BUSINESS_CATEGORY,
        fs.MISSING_RATIO,
        fs.INFORMATION_VALUE,
        fs.STABILITY_INDEX,
        fs.TARGET_CORRELATION,
        -- Tính điểm chất lượng đơn giản
        CASE 
            WHEN fs.MISSING_RATIO IS NULL THEN NULL
            WHEN fs.MISSING_RATIO <= 0.05 AND 
                 ISNULL(fs.INFORMATION_VALUE, 0) >= 0.1 AND 
                 ISNULL(fs.STABILITY_INDEX, 0) <= 0.25 AND 
                 ABS(ISNULL(fs.TARGET_CORRELATION, 0)) >= 0.1 THEN 'EXCELLENT'
            WHEN fs.MISSING_RATIO <= 0.15 AND 
                 ISNULL(fs.INFORMATION_VALUE, 0) >= 0.05 AND 
                 ISNULL(fs.STABILITY_INDEX, 0) <= 0.35 THEN 'GOOD'
            WHEN fs.MISSING_RATIO <= 0.3 AND 
                 ISNULL(fs.INFORMATION_VALUE, 0) >= 0.02 THEN 'ACCEPTABLE'
            ELSE 'POOR'
        END AS QUALITY_RATING
    FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY fr
    LEFT JOIN (
        SELECT 
            fs1.FEATURE_ID,
            fs1.MISSING_RATIO,
            fs1.INFORMATION_VALUE,
            fs1.STABILITY_INDEX,
            fs1.TARGET_CORRELATION,
            ROW_NUMBER() OVER (PARTITION BY fs1.FEATURE_ID ORDER BY fs1.CALCULATION_DATE DESC) as rn
        FROM MODEL_REGISTRY.dbo.FEATURE_STATS fs1
        WHERE fs1.IS_ACTIVE = 1
    ) fs ON fr.FEATURE_ID = fs.FEATURE_ID AND fs.rn = 1
    WHERE fr.IS_ACTIVE = 1
)
SELECT 
    'FEATURE_QUALITY_DISTRIBUTION' AS REPORT_SECTION,
    fq.BUSINESS_CATEGORY,
    fq.DATA_TYPE,
    COUNT(*) AS TOTAL_FEATURES,
    SUM(CASE WHEN fq.QUALITY_RATING = 'EXCELLENT' THEN 1 ELSE 0 END) AS EXCELLENT_COUNT,
    SUM(CASE WHEN fq.QUALITY_RATING = 'GOOD' THEN 1 ELSE 0 END) AS GOOD_COUNT,
    SUM(CASE WHEN fq.QUALITY_RATING = 'ACCEPTABLE' THEN 1 ELSE 0 END) AS ACCEPTABLE_COUNT,
    SUM(CASE WHEN fq.QUALITY_RATING = 'POOR' THEN 1 ELSE 0 END) AS POOR_COUNT,
    SUM(CASE WHEN fq.QUALITY_RATING IS NULL THEN 1 ELSE 0 END) AS NO_STATS_COUNT,
    AVG(fq.MISSING_RATIO) AS AVG_MISSING_RATIO,
    AVG(fq.INFORMATION_VALUE) AS AVG_INFORMATION_VALUE,
    AVG(fq.STABILITY_INDEX) AS AVG_STABILITY_INDEX
FROM FeatureQuality fq
GROUP BY fq.BUSINESS_CATEGORY, fq.DATA_TYPE
ORDER BY fq.BUSINESS_CATEGORY, fq.DATA_TYPE;

-- 6. Mô hình cần chú ý ưu tiên
PRINT '';
PRINT '6. MÔ HÌNH CẦN CHÚ Ý ƯU TIÊN';
PRINT '==========================================';

WITH ModelPriority AS (
    SELECT 
        mr.MODEL_ID,
        mr.MODEL_NAME,
        mr.MODEL_VERSION,
        mt.TYPE_NAME,
        mr.EXP_DATE,
        mvr.VALIDATION_DATE,
        mvr.GINI,
        mvr.PSI,
        -- Tính điểm ưu tiên
        (
            CASE WHEN mr.EXP_DATE <= DATEADD(MONTH, 3, GETDATE()) THEN 30 ELSE 0 END + -- Sắp hết hạn
            CASE WHEN mvr.PSI > 0.35 THEN 25 ELSE 0 END + -- PSI cao
            CASE WHEN mvr.GINI < 0.3 THEN 20 ELSE 0 END + -- GINI thấp
            CASE WHEN mvr.VALIDATION_DATE < DATEADD(MONTH, -6, GETDATE()) THEN 15 ELSE 0 END + -- Lâu chưa đánh giá
            CASE WHEN EXISTS (
                SELECT 1 FROM MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG dq
                JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE tu ON dq.SOURCE_TABLE_ID = tu.SOURCE_TABLE_ID
                WHERE tu.MODEL_ID = mr.MODEL_ID 
                AND dq.SEVERITY IN ('CRITICAL', 'HIGH')
                AND dq.REMEDIATION_STATUS IN ('OPEN', 'IN_PROGRESS')
            ) THEN 10 ELSE 0 END -- Có vấn đề dữ liệu
        ) AS PRIORITY_SCORE,
        STRING_AGG(
            CASE 
                WHEN mr.EXP_DATE <= DATEADD(MONTH, 3, GETDATE()) THEN 'Sắp hết hạn'
                WHEN mvr.PSI > 0.35 THEN 'PSI cao'
                WHEN mvr.GINI < 0.3 THEN 'GINI thấp'
                WHEN mvr.VALIDATION_DATE < DATEADD(MONTH, -6, GETDATE()) THEN 'Lâu chưa đánh giá'
            END, 
            '; '
        ) AS PRIORITY_REASONS
    FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
    JOIN MODEL_REGISTRY.dbo.MODEL_TYPE mt ON mr.TYPE_ID = mt.TYPE_ID
    LEFT JOIN (
        SELECT 
            mvr1.MODEL_ID,
            mvr1.VALIDATION_DATE,
            mvr1.GINI,
            mvr1.PSI,
            ROW_NUMBER() OVER (PARTITION BY mvr1.MODEL_ID ORDER BY mvr1.VALIDATION_DATE DESC) as rn
        FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS mvr1
    ) mvr ON mr.MODEL_ID = mvr.MODEL_ID AND mvr.rn = 1
    WHERE mr.IS_ACTIVE = 1
    GROUP BY 
        mr.MODEL_ID, mr.MODEL_NAME, mr.MODEL_VERSION, mt.TYPE_NAME, 
        mr.EXP_DATE, mvr.VALIDATION_DATE, mvr.GINI, mvr.PSI
)
SELECT 
    'HIGH_PRIORITY_MODELS' AS REPORT_SECTION,
    mp.MODEL_ID,
    mp.MODEL_NAME,
    mp.MODEL_VERSION,
    mp.TYPE_NAME,
    mp.PRIORITY_SCORE,
    mp.PRIORITY_REASONS,
    mp.EXP_DATE,
    mp.VALIDATION_DATE,
    mp.GINI,
    mp.PSI,
    CASE 
        WHEN mp.PRIORITY_SCORE >= 50 THEN 'URGENT'
        WHEN mp.PRIORITY_SCORE >= 30 THEN 'HIGH'
        WHEN mp.PRIORITY_SCORE >= 15 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS PRIORITY_LEVEL
FROM ModelPriority mp
WHERE mp.PRIORITY_SCORE > 0
ORDER BY mp.PRIORITY_SCORE DESC;

-- 7. Xu hướng hiệu suất mô hình theo thời gian
PRINT '';
PRINT '7. XU HƯỚNG HIỆU SUẤT MÔ HÌNH THEO THỜI GIAN';
PRINT '==========================================';

SELECT 
    'MODEL_PERFORMANCE_TREND' AS REPORT_SECTION,
    FORMAT(mvr.VALIDATION_DATE, 'yyyy-MM') AS VALIDATION_MONTH,
    mt.TYPE_NAME,
    COUNT(*) AS VALIDATIONS_COUNT,
    AVG(mvr.GINI) AS AVG_GINI,
    AVG(mvr.KS_STATISTIC) AS AVG_KS,
    AVG(mvr.PSI) AS AVG_PSI,
    AVG(mvr.ACCURACY) AS AVG_ACCURACY,
    SUM(CASE WHEN mvr.GINI >= 0.4 AND mvr.PSI <= 0.25 THEN 1 ELSE 0 END) AS GOOD_PERFORMANCE_COUNT,
    SUM(CASE WHEN mvr.PSI > 0.25 THEN 1 ELSE 0 END) AS HIGH_PSI_COUNT
FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS mvr
JOIN MODEL_REGISTRY.dbo.MODEL_REGISTRY mr ON mvr.MODEL_ID = mr.MODEL_ID
JOIN MODEL_REGISTRY.dbo.MODEL_TYPE mt ON mr.TYPE_ID = mt.TYPE_ID
WHERE mvr.VALIDATION_DATE >= DATEADD(MONTH, -12, GETDATE())
AND mr.IS_ACTIVE = 1
GROUP BY FORMAT(mvr.VALIDATION_DATE, 'yyyy-MM'), mt.TYPE_NAME
ORDER BY VALIDATION_MONTH DESC, mt.TYPE_NAME;

-- 8. Đề xuất hành động
PRINT '';
PRINT '8. ĐỀ XUẤT HÀNH ĐỘNG';
PRINT '==========================================';

SELECT 
    'ACTION_RECOMMENDATIONS' AS REPORT_SECTION,
    'MODEL_MANAGEMENT' AS CATEGORY,
    'Có ' + CAST(COUNT(*) AS NVARCHAR) + ' mô hình cần được đánh giá lại trong vòng 30 ngày tới' AS RECOMMENDATION,
    'HIGH' AS PRIORITY
FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
LEFT JOIN (
    SELECT MODEL_ID, MAX(VALIDATION_DATE) as LAST_VALIDATION
    FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS
    GROUP BY MODEL_ID
) lv ON mr.MODEL_ID = lv.MODEL_ID
WHERE mr.IS_ACTIVE = 1
AND (lv.LAST_VALIDATION IS NULL OR lv.LAST_VALIDATION < DATEADD(MONTH, -6, GETDATE()))

UNION ALL

SELECT 
    'ACTION_RECOMMENDATIONS' AS REPORT_SECTION,
    'DATA_QUALITY' AS CATEGORY,
    'Có ' + CAST(COUNT(*) AS NVARCHAR) + ' vấn đề chất lượng dữ liệu nghiêm trọng cần được xử lý' AS RECOMMENDATION,
    'CRITICAL' AS PRIORITY
FROM MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG dq
WHERE dq.SEVERITY IN ('CRITICAL', 'HIGH')
AND dq.REMEDIATION_STATUS IN ('OPEN', 'IN_PROGRESS')
AND dq.PROCESS_DATE >= DATEADD(MONTH, -1, GETDATE())

UNION ALL

SELECT 
    'ACTION_RECOMMENDATIONS' AS REPORT_SECTION,
    'FEATURE_MANAGEMENT' AS CATEGORY,
    'Có ' + CAST(COUNT(*) AS NVARCHAR) + ' đặc trưng chưa có thống kê hoặc thống kê lỗi thời' AS RECOMMENDATION,
    'MEDIUM' AS PRIORITY
FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY fr
LEFT JOIN (
    SELECT FEATURE_ID, MAX(CALCULATION_DATE) as LAST_STATS
    FROM MODEL_REGISTRY.dbo.FEATURE_STATS
    WHERE IS_ACTIVE = 1
    GROUP BY FEATURE_ID
) ls ON fr.FEATURE_ID = ls.FEATURE_ID
WHERE fr.IS_ACTIVE = 1
AND (ls.LAST_STATS IS NULL OR ls.LAST_STATS < DATEADD(MONTH, -3, GETDATE()));

PRINT '';
PRINT 'BÁO CÁO HOÀN THÀNH - ' + CONVERT(NVARCHAR, GETDATE(), 120);
PRINT '==========================================';