/*
Tên file: 07_fn_validate_feature.sql
Mô tả: Tạo function FN_VALIDATE_FEATURE để kiểm tra tính hợp lệ và chất lượng của đặc trưng
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-16
Ngày cập nhật: 2025-06-19
Phiên bản: 1.1

Function này cung cấp các chức năng:
1. Kiểm tra toàn diện tính hợp lệ và chất lượng của đặc trưng dựa trên nhiều tiêu chí
2. Tính điểm chất lượng tổng hợp cho đặc trưng
3. Phân loại đặc trưng theo mức độ chất lượng
4. Cung cấp chi tiết về từng kiểm tra và đề xuất cải thiện
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu function đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.FN_VALIDATE_FEATURE', 'IF') IS NOT NULL
    DROP FUNCTION dbo.FN_VALIDATE_FEATURE;
GO

-- Tạo function FN_VALIDATE_FEATURE
CREATE FUNCTION dbo.FN_VALIDATE_FEATURE (
    @FEATURE_ID INT,
    @VALIDATION_DATE DATE = NULL,
    @SEGMENT_ID INT = NULL  -- NULL cho toàn bộ dữ liệu, hoặc ID của phân khúc cụ thể
)
RETURNS TABLE
AS
RETURN (
    WITH FeatureInfo AS (
        -- Lấy thông tin về đặc trưng
        SELECT 
            fr.FEATURE_ID,
            fr.FEATURE_NAME,
            fr.FEATURE_CODE,
            fr.DATA_TYPE,
            fr.VALUE_TYPE,
            fr.VALID_MIN_VALUE,
            fr.VALID_MAX_VALUE,
            fr.VALID_VALUES,
            fr.IS_ACTIVE
        FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY fr
        WHERE fr.FEATURE_ID = @FEATURE_ID
    ),
    FeatureStatsInfo AS (
        -- Lấy thông tin thống kê mới nhất của đặc trưng
        SELECT TOP 1
            fs.STATS_ID,
            fs.CALCULATION_DATE,
            fs.MIN_VALUE,
            fs.MAX_VALUE,
            fs.MEAN,
            fs.MEDIAN,
            fs.STD_DEVIATION,
            fs.MISSING_RATIO,
            fs.UNIQUE_VALUES,
            fs.INFORMATION_VALUE,
            fs.STABILITY_INDEX,
            fs.TARGET_CORRELATION,
            fs.HAS_OUTLIERS,
            fs.HIGH_CARDINALITY,
            fs.LOW_VARIANCE,
            fs.SKEWNESS,
            fs.KURTOSIS
        FROM MODEL_REGISTRY.dbo.FEATURE_STATS fs
        WHERE fs.FEATURE_ID = @FEATURE_ID
          AND fs.IS_ACTIVE = 1
          AND (@SEGMENT_ID IS NULL OR fs.SEGMENT_ID = @SEGMENT_ID)
          AND (@VALIDATION_DATE IS NULL OR fs.CALCULATION_DATE <= @VALIDATION_DATE)
        ORDER BY fs.CALCULATION_DATE DESC
    ),
    QualityChecks AS (
        -- 1. Kiểm tra phạm vi giá trị
        SELECT 
            CASE 
                WHEN fi.DATA_TYPE = 'NUMERIC' AND fsi.MIN_VALUE IS NOT NULL AND fi.VALID_MIN_VALUE IS NOT NULL
                    AND fsi.MIN_VALUE < CAST(fi.VALID_MIN_VALUE AS FLOAT) THEN 0
                ELSE 1
            END AS RANGE_MIN_CHECK,
            
            CASE 
                WHEN fi.DATA_TYPE = 'NUMERIC' AND fsi.MAX_VALUE IS NOT NULL AND fi.VALID_MAX_VALUE IS NOT NULL
                    AND fsi.MAX_VALUE > CAST(fi.VALID_MAX_VALUE AS FLOAT) THEN 0
                ELSE 1
            END AS RANGE_MAX_CHECK,
            
            -- 2. Kiểm tra dữ liệu thiếu
            CASE 
                WHEN fsi.MISSING_RATIO IS NOT NULL AND fsi.MISSING_RATIO > 0.2 THEN 0
                ELSE 1
            END AS MISSING_DATA_CHECK,
            
            -- 3. Kiểm tra độ phân tán (variance)
            CASE 
                WHEN fi.DATA_TYPE = 'NUMERIC' AND fsi.LOW_VARIANCE = 1 THEN 0
                ELSE 1
            END AS VARIANCE_CHECK,
            
            -- 4. Kiểm tra ngoại lai (outliers)
            CASE 
                WHEN fi.DATA_TYPE = 'NUMERIC' AND fsi.HAS_OUTLIERS = 1 THEN 0
                ELSE 1
            END AS OUTLIER_CHECK,
            
            -- 5. Kiểm tra độ tương quan với mục tiêu
            CASE 
                WHEN fsi.TARGET_CORRELATION IS NOT NULL AND ABS(fsi.TARGET_CORRELATION) < 0.05 THEN 0
                ELSE 1
            END AS CORRELATION_CHECK,
            
            -- 6. Kiểm tra tính ổn định (stability)
            CASE 
                WHEN fsi.STABILITY_INDEX IS NOT NULL AND fsi.STABILITY_INDEX > 0.25 THEN 0
                ELSE 1
            END AS STABILITY_CHECK,
            
            -- 7. Kiểm tra Information Value (IV)
            CASE 
                WHEN fsi.INFORMATION_VALUE IS NOT NULL AND fsi.INFORMATION_VALUE < 0.02 THEN 0
                ELSE 1
            END AS IV_CHECK,
            
            -- 8. Kiểm tra tính đối xứng (skewness)
            CASE 
                WHEN fi.DATA_TYPE = 'NUMERIC' AND fsi.SKEWNESS IS NOT NULL AND ABS(fsi.SKEWNESS) > 3 THEN 0
                ELSE 1
            END AS SKEWNESS_CHECK,
            
            -- 9. Kiểm tra độ nhọn (kurtosis)
            CASE 
                WHEN fi.DATA_TYPE = 'NUMERIC' AND fsi.KURTOSIS IS NOT NULL AND fsi.KURTOSIS > 10 THEN 0
                ELSE 1
            END AS KURTOSIS_CHECK,
            
            -- 10. Kiểm tra cardinality cao (quá nhiều giá trị độc đáo)
            CASE 
                WHEN fi.VALUE_TYPE = 'CATEGORICAL' AND fsi.HIGH_CARDINALITY = 1 THEN 0
                ELSE 1
            END AS CARDINALITY_CHECK,
            
            -- 11. Thêm các giá trị thống kê để tham khảo
            fsi.MIN_VALUE,
            fsi.MAX_VALUE,
            fsi.MEAN,
            fsi.MEDIAN,
            fsi.STD_DEVIATION,
            fsi.MISSING_RATIO,
            fsi.UNIQUE_VALUES,
            fsi.INFORMATION_VALUE,
            fsi.STABILITY_INDEX,
            fsi.TARGET_CORRELATION,
            fsi.SKEWNESS,
            fsi.KURTOSIS,
            fsi.CALCULATION_DATE,
            CONVERT(NVARCHAR(20), fi.VALID_MIN_VALUE) AS EXPECTED_MIN_VALUE,
            CONVERT(NVARCHAR(20), fi.VALID_MAX_VALUE) AS EXPECTED_MAX_VALUE,
            fi.VALID_VALUES AS EXPECTED_VALUES
        FROM FeatureInfo fi
        LEFT JOIN FeatureStatsInfo fsi ON 1=1
    ),
    QualityResults AS (
        -- Tính toán điểm và phân loại chất lượng
        SELECT
            -- Các kết quả kiểm tra riêng lẻ
            qc.RANGE_MIN_CHECK,
            qc.RANGE_MAX_CHECK,
            qc.MISSING_DATA_CHECK,
            qc.VARIANCE_CHECK,
            qc.OUTLIER_CHECK,
            qc.CORRELATION_CHECK,
            qc.STABILITY_CHECK,
            qc.IV_CHECK,
            qc.SKEWNESS_CHECK,
            qc.KURTOSIS_CHECK,
            qc.CARDINALITY_CHECK,
            
            -- Giá trị thống kê
            qc.MIN_VALUE,
            qc.MAX_VALUE,
            qc.MEAN,
            qc.MEDIAN,
            qc.STD_DEVIATION,
            qc.MISSING_RATIO,
            qc.UNIQUE_VALUES,
            qc.INFORMATION_VALUE,
            qc.STABILITY_INDEX,
            qc.TARGET_CORRELATION,
            qc.SKEWNESS,
            qc.KURTOSIS,
            qc.CALCULATION_DATE,
            qc.EXPECTED_MIN_VALUE,
            qc.EXPECTED_MAX_VALUE,
            qc.EXPECTED_VALUES,
            
            -- Tính tổng số kiểm tra đạt
            (qc.RANGE_MIN_CHECK + qc.RANGE_MAX_CHECK + qc.MISSING_DATA_CHECK + 
             qc.VARIANCE_CHECK + qc.OUTLIER_CHECK + qc.CORRELATION_CHECK + 
             qc.STABILITY_CHECK + qc.IV_CHECK + qc.SKEWNESS_CHECK + 
             qc.KURTOSIS_CHECK + qc.CARDINALITY_CHECK) AS CHECKS_PASSED,
            
            -- Tổng số kiểm tra áp dụng được (trả về NULL = không áp dụng)
            CASE WHEN qc.RANGE_MIN_CHECK IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN qc.RANGE_MAX_CHECK IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN qc.MISSING_DATA_CHECK IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN qc.VARIANCE_CHECK IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN qc.OUTLIER_CHECK IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN qc.CORRELATION_CHECK IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN qc.STABILITY_CHECK IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN qc.IV_CHECK IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN qc.SKEWNESS_CHECK IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN qc.KURTOSIS_CHECK IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN qc.CARDINALITY_CHECK IS NOT NULL THEN 1 ELSE 0 END AS TOTAL_APPLICABLE_CHECKS
        FROM QualityChecks qc
    )
    -- Trả về kết quả với phân loại chất lượng
    SELECT 
        fi.FEATURE_ID,
        fi.FEATURE_NAME,
        fi.FEATURE_CODE,
        fi.DATA_TYPE,
        fi.VALUE_TYPE,
        fi.IS_ACTIVE,
        qr.CALCULATION_DATE AS STATS_DATE,
        
        -- Chi tiết các kiểm tra
        qr.RANGE_MIN_CHECK,
        qr.RANGE_MAX_CHECK,
        qr.MISSING_DATA_CHECK,
        qr.VARIANCE_CHECK,
        qr.OUTLIER_CHECK,
        qr.CORRELATION_CHECK,
        qr.STABILITY_CHECK,
        qr.IV_CHECK,
        qr.SKEWNESS_CHECK,
        qr.KURTOSIS_CHECK,
        qr.CARDINALITY_CHECK,
        
        -- Thông tin thống kê
        qr.MIN_VALUE,
        qr.MAX_VALUE,
        qr.MEAN,
        qr.MEDIAN,
        qr.STD_DEVIATION,
        qr.MISSING_RATIO,
        qr.UNIQUE_VALUES,
        qr.INFORMATION_VALUE,
        qr.STABILITY_INDEX,
        qr.TARGET_CORRELATION,
        qr.SKEWNESS,
        qr.KURTOSIS,
        qr.EXPECTED_MIN_VALUE,
        qr.EXPECTED_MAX_VALUE,
        qr.EXPECTED_VALUES,
        
        -- Tính điểm đánh giá
        qr.CHECKS_PASSED,
        qr.TOTAL_APPLICABLE_CHECKS,
        
        -- Tính phần trăm đạt
        CASE 
            WHEN qr.TOTAL_APPLICABLE_CHECKS = 0 THEN NULL -- Tránh chia cho 0
            ELSE CAST(qr.CHECKS_PASSED AS FLOAT) / qr.TOTAL_APPLICABLE_CHECKS * 100 
        END AS QUALITY_SCORE,
        
        -- Xếp loại chất lượng
        CASE 
            WHEN qr.TOTAL_APPLICABLE_CHECKS = 0 THEN 'UNKNOWN'
            WHEN CAST(qr.CHECKS_PASSED AS FLOAT) / qr.TOTAL_APPLICABLE_CHECKS >= 0.9 THEN 'EXCELLENT'
            WHEN CAST(qr.CHECKS_PASSED AS FLOAT) / qr.TOTAL_APPLICABLE_CHECKS >= 0.75 THEN 'GOOD'
            WHEN CAST(qr.CHECKS_PASSED AS FLOAT) / qr.TOTAL_APPLICABLE_CHECKS >= 0.6 THEN 'ACCEPTABLE'
            WHEN CAST(qr.CHECKS_PASSED AS FLOAT) / qr.TOTAL_APPLICABLE_CHECKS >= 0.4 THEN 'POOR'
            ELSE 'CRITICAL'
        END AS QUALITY_RATING,
        
        -- Tổng hợp các vấn đề
        CONCAT(
            CASE WHEN qr.RANGE_MIN_CHECK = 0 THEN 'Giá trị tối thiểu nằm ngoài phạm vi cho phép; ' ELSE '' END,
            CASE WHEN qr.RANGE_MAX_CHECK = 0 THEN 'Giá trị tối đa nằm ngoài phạm vi cho phép; ' ELSE '' END,
            CASE WHEN qr.MISSING_DATA_CHECK = 0 THEN 'Tỷ lệ dữ liệu thiếu quá cao; ' ELSE '' END,
            CASE WHEN qr.VARIANCE_CHECK = 0 THEN 'Độ phân tán của đặc trưng quá thấp; ' ELSE '' END,
            CASE WHEN qr.OUTLIER_CHECK = 0 THEN 'Có nhiều giá trị ngoại lai; ' ELSE '' END,
            CASE WHEN qr.CORRELATION_CHECK = 0 THEN 'Tương quan với biến mục tiêu quá thấp; ' ELSE '' END,
            CASE WHEN qr.STABILITY_CHECK = 0 THEN 'Đặc trưng không ổn định theo thời gian; ' ELSE '' END,
            CASE WHEN qr.IV_CHECK = 0 THEN 'Information Value quá thấp; ' ELSE '' END,
            CASE WHEN qr.SKEWNESS_CHECK = 0 THEN 'Độ lệch (skewness) quá cao; ' ELSE '' END,
            CASE WHEN qr.KURTOSIS_CHECK = 0 THEN 'Độ nhọn (kurtosis) quá cao; ' ELSE '' END,
            CASE WHEN qr.CARDINALITY_CHECK = 0 THEN 'Có quá nhiều giá trị độc đáo; ' ELSE '' END
        ) AS ISSUES_SUMMARY,
        
        -- Đề xuất cải thiện
        CASE 
            WHEN qr.TOTAL_APPLICABLE_CHECKS = 0 THEN 'Không có đủ dữ liệu thống kê để đánh giá.'
            WHEN CAST(qr.CHECKS_PASSED AS FLOAT) / qr.TOTAL_APPLICABLE_CHECKS >= 0.9 THEN 'Không có hành động cần thiết, đặc trưng có chất lượng tốt.'
            ELSE CONCAT(
                CASE WHEN qr.RANGE_MIN_CHECK = 0 THEN 'Kiểm tra lại giới hạn dưới của đặc trưng; ' ELSE '' END,
                CASE WHEN qr.RANGE_MAX_CHECK = 0 THEN 'Kiểm tra lại giới hạn trên của đặc trưng; ' ELSE '' END,
                CASE WHEN qr.MISSING_DATA_CHECK = 0 THEN 'Cần cải thiện việc thu thập dữ liệu hoặc áp dụng phương pháp điền khuyết phù hợp; ' ELSE '' END,
                CASE WHEN qr.VARIANCE_CHECK = 0 THEN 'Đặc trưng có độ phân tán thấp, cân nhắc bỏ hoặc gộp với đặc trưng khác; ' ELSE '' END,
                CASE WHEN qr.OUTLIER_CHECK = 0 THEN 'Xử lý giá trị ngoại lai bằng cắt giới hạn (capping) hoặc biến đổi; ' ELSE '' END,
                CASE WHEN qr.CORRELATION_CHECK = 0 THEN 'Đặc trưng có ít giá trị dự báo, cân nhắc loại bỏ hoặc tạo đặc trưng mới; ' ELSE '' END,
                CASE WHEN qr.STABILITY_CHECK = 0 THEN 'Đặc trưng không ổn định theo thời gian, cần thường xuyên hiệu chỉnh lại; ' ELSE '' END,
                CASE WHEN qr.IV_CHECK = 0 THEN 'Information Value thấp, cân nhắc thay thế bằng đặc trưng có khả năng dự báo tốt hơn; ' ELSE '' END,
                CASE WHEN qr.SKEWNESS_CHECK = 0 THEN 'Áp dụng biến đổi (log, sqrt) để giảm độ lệch; ' ELSE '' END,
                CASE WHEN qr.KURTOSIS_CHECK = 0 THEN 'Áp dụng biến đổi để giảm độ nhọn; ' ELSE '' END,
                CASE WHEN qr.CARDINALITY_CHECK = 0 THEN 'Gộp các giá trị thành các nhóm có ý nghĩa để giảm cardinality; ' ELSE '' END
            )
        END AS RECOMMENDATIONS
    FROM FeatureInfo fi
    CROSS JOIN QualityResults qr
);
GO

-- Thêm comment cho function
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Kiểm tra tính hợp lệ và chất lượng của đặc trưng', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'FUNCTION',  @level1name = N'FN_VALIDATE_FEATURE';
GO

PRINT N'Function FN_VALIDATE_FEATURE đã được tạo thành công';
GO

-- Tạo stored procedure để kiểm tra nhiều đặc trưng cùng lúc và lưu kết quả
IF OBJECT_ID('dbo.SP_VALIDATE_FEATURES', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SP_VALIDATE_FEATURES;
GO

CREATE PROCEDURE dbo.SP_VALIDATE_FEATURES
    @MODEL_ID INT = NULL,                -- Nếu NULL, kiểm tra tất cả đặc trưng đang active
    @FEATURE_ID INT = NULL,              -- Nếu MODEL_ID NULL, có thể chỉ định FEATURE_ID cụ thể
    @VALIDATION_DATE DATE = NULL,        -- Ngày của dữ liệu thống kê để dùng cho đánh giá
    @SEGMENT_ID INT = NULL,              -- NULL cho toàn bộ dữ liệu, hoặc ID của phân khúc
    @MIN_QUALITY_THRESHOLD FLOAT = 60.0, -- Ngưỡng chất lượng tối thiểu (%)
    @LOG_RESULTS BIT = 1                 -- Có ghi log kết quả hay không
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Tạo bảng tạm để lưu kết quả
    CREATE TABLE #ValidationResults (
        FEATURE_ID INT,
        FEATURE_NAME NVARCHAR(100),
        FEATURE_CODE NVARCHAR(50),
        DATA_TYPE NVARCHAR(50),
        VALUE_TYPE NVARCHAR(50),
        QUALITY_SCORE FLOAT,
        QUALITY_RATING NVARCHAR(20),
        ISSUES_SUMMARY NVARCHAR(MAX),
        RECOMMENDATIONS NVARCHAR(MAX),
        STATS_DATE DATE
    );
    
    -- Xác định danh sách đặc trưng cần kiểm tra
    DECLARE @FeaturesTable TABLE (FEATURE_ID INT);
    
    IF @MODEL_ID IS NOT NULL
    BEGIN
        -- Lấy các đặc trưng được sử dụng bởi mô hình
        INSERT INTO @FeaturesTable (FEATURE_ID)
        SELECT DISTINCT fmm.FEATURE_ID
        FROM dbo.FEATURE_MODEL_MAPPING fmm
        WHERE fmm.MODEL_ID = @MODEL_ID
          AND fmm.IS_ACTIVE = 1;
    END
    ELSE IF @FEATURE_ID IS NOT NULL
    BEGIN
        -- Chỉ kiểm tra một đặc trưng cụ thể
        INSERT INTO @FeaturesTable (FEATURE_ID)
        VALUES (@FEATURE_ID);
    END
    ELSE
    BEGIN
        -- Kiểm tra tất cả đặc trưng đang active
        INSERT INTO @FeaturesTable (FEATURE_ID)
        SELECT FEATURE_ID
        FROM dbo.FEATURE_REGISTRY
        WHERE IS_ACTIVE = 1;
    END
    
    -- Kiểm tra từng đặc trưng và lưu kết quả
    INSERT INTO #ValidationResults
    SELECT 
        f.FEATURE_ID,
        f.FEATURE_NAME,
        f.FEATURE_CODE,
        f.DATA_TYPE,
        f.VALUE_TYPE,
        f.QUALITY_SCORE,
        f.QUALITY_RATING,
        f.ISSUES_SUMMARY,
        f.RECOMMENDATIONS,
        f.STATS_DATE
    FROM @FeaturesTable ft
    CROSS APPLY dbo.FN_VALIDATE_FEATURE(ft.FEATURE_ID, @VALIDATION_DATE, @SEGMENT_ID) f;
    
    -- Thống kê tổng quan kết quả kiểm tra
    SELECT 
        COUNT(*) AS TOTAL_FEATURES_CHECKED,
        SUM(CASE WHEN QUALITY_RATING = 'EXCELLENT' THEN 1 ELSE 0 END) AS EXCELLENT_COUNT,
        SUM(CASE WHEN QUALITY_RATING = 'GOOD' THEN 1 ELSE 0 END) AS GOOD_COUNT,
        SUM(CASE WHEN QUALITY_RATING = 'ACCEPTABLE' THEN 1 ELSE 0 END) AS ACCEPTABLE_COUNT,
        SUM(CASE WHEN QUALITY_RATING = 'POOR' THEN 1 ELSE 0 END) AS POOR_COUNT,
        SUM(CASE WHEN QUALITY_RATING = 'CRITICAL' THEN 1 ELSE 0 END) AS CRITICAL_COUNT,
        SUM(CASE WHEN QUALITY_RATING = 'UNKNOWN' THEN 1 ELSE 0 END) AS UNKNOWN_COUNT,
        SUM(CASE WHEN QUALITY_SCORE < @MIN_QUALITY_THRESHOLD THEN 1 ELSE 0 END) AS BELOW_THRESHOLD_COUNT,
        AVG(QUALITY_SCORE) AS AVG_QUALITY_SCORE
    FROM #ValidationResults;
    
    -- Hiện thị kết quả chi tiết
    SELECT * FROM #ValidationResults
    ORDER BY 
        CASE QUALITY_RATING
            WHEN 'CRITICAL' THEN 1
            WHEN 'POOR' THEN 2
            WHEN 'ACCEPTABLE' THEN 3
            WHEN 'GOOD' THEN 4
            WHEN 'EXCELLENT' THEN 5
            ELSE 6
        END,
        QUALITY_SCORE;
    
    -- Ghi log kết quả nếu được yêu cầu
    IF @LOG_RESULTS = 1
    BEGIN
        -- Ghi log cho từng đặc trưng
        INSERT INTO dbo.FEATURE_REFRESH_LOG (
            FEATURE_ID,
            REFRESH_TYPE,
            REFRESH_STATUS,
            REFRESH_END_TIME,
            REFRESH_REASON,
            REFRESH_TRIGGERED_BY,
            SUCCESS_VALIDATION_FLAG,
            VALIDATION_DETAILS,
            ENVIRONMENT
        )
        SELECT 
            vr.FEATURE_ID,
            'VALIDATION',
            'COMPLETED',
            GETDATE(),
            'Kiểm tra chất lượng đặc trưng' + 
                CASE 
                    WHEN @MODEL_ID IS NOT NULL THEN ' cho mô hình ID=' + CAST(@MODEL_ID AS NVARCHAR(10))
                    ELSE ''
                END,
            SUSER_NAME(),
            CASE WHEN vr.QUALITY_SCORE >= @MIN_QUALITY_THRESHOLD THEN 1 ELSE 0 END,
            'Quality Score: ' + CAST(vr.QUALITY_SCORE AS NVARCHAR(10)) + 
            ', Rating: ' + vr.QUALITY_RATING + 
            ', Issues: ' + ISNULL(vr.ISSUES_SUMMARY, 'None'),
            'PROD'
        FROM #ValidationResults vr;
        
        -- Ghi log tổng hợp nếu là kiểm tra cho mô hình
        IF @MODEL_ID IS NOT NULL
        BEGIN
            -- Tính tỷ lệ đạt yêu cầu
            DECLARE @TOTAL_FEATURES INT = (SELECT COUNT(*) FROM #ValidationResults);
            DECLARE @PASSING_FEATURES INT = (SELECT COUNT(*) FROM #ValidationResults WHERE QUALITY_SCORE >= @MIN_QUALITY_THRESHOLD);
            DECLARE @PASSING_RATIO FLOAT = CASE WHEN @TOTAL_FEATURES = 0 THEN 0 ELSE CAST(@PASSING_FEATURES AS FLOAT) / @TOTAL_FEATURES END;
            
            -- Ghi log cho mô hình
            INSERT INTO dbo.MODEL_DATA_QUALITY_LOG (
                SOURCE_TABLE_ID,
                PROCESS_DATE,
                ISSUE_TYPE,
                ISSUE_DESCRIPTION,
                ISSUE_CATEGORY,
                SEVERITY,
                RECORDS_AFFECTED,
                PERCENTAGE_AFFECTED,
                IMPACT_DESCRIPTION,
                DETECTION_METHOD,
                REMEDIATION_STATUS
            )
            SELECT 
                NULL, -- SOURCE_TABLE_ID
                GETDATE(), -- PROCESS_DATE
                'FEATURE_QUALITY', -- ISSUE_TYPE
                'Kiểm tra chất lượng đặc trưng cho mô hình ID=' + CAST(@MODEL_ID AS NVARCHAR(10)), -- ISSUE_DESCRIPTION
                'DATA_QUALITY', -- ISSUE_CATEGORY
                CASE -- SEVERITY
                    WHEN @PASSING_RATIO >= 0.9 THEN 'LOW'
                    WHEN @PASSING_RATIO >= 0.75 THEN 'MEDIUM'
                    WHEN @PASSING_RATIO >= 0.5 THEN 'HIGH'
                    ELSE 'CRITICAL'
                END,
                @TOTAL_FEATURES - @PASSING_FEATURES, -- RECORDS_AFFECTED
                (1 - @PASSING_RATIO) * 100, -- PERCENTAGE_AFFECTED
                'Có ' + CAST(@TOTAL_FEATURES - @PASSING_FEATURES AS NVARCHAR(10)) + ' đặc trưng không đạt ngưỡng chất lượng tối thiểu ' +
                CAST(@MIN_QUALITY_THRESHOLD AS NVARCHAR(10)) + '%', -- IMPACT_DESCRIPTION
                'FN_VALIDATE_FEATURE', -- DETECTION_METHOD
                'OPEN'; -- REMEDIATION_STATUS
        END
    END
    
    -- Dọn dẹp
    DROP TABLE #ValidationResults;
END;
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Kiểm tra tính hợp lệ và chất lượng của nhiều đặc trưng cùng lúc', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'PROCEDURE',  @level1name = N'SP_VALIDATE_FEATURES';
GO

PRINT N'stored Procedure SP_VALIDATE_FEATURES đã được tạo thành công';
GO

-- Hướng dẫn sử dụng:
PRINT N'
-- Ví dụ cách sử dụng Function FN_VALIDATE_FEATURE:
SELECT * FROM dbo.FN_VALIDATE_FEATURE(
    1,                -- FEATURE_ID 
    NULL,             -- VALIDATION_DATE (NULL để lấy dữ liệu thống kê mới nhất)
    NULL              -- SEGMENT_ID (NULL để sử dụng dữ liệu toàn bộ)
);

-- Ví dụ cách sử dụng Stored Procedure SP_VALIDATE_FEATURES:
-- 1. Kiểm tra các đặc trưng của một mô hình cụ thể
EXEC dbo.SP_VALIDATE_FEATURES
    @MODEL_ID = 1,
    @VALIDATION_DATE = NULL,
    @SEGMENT_ID = NULL,
    @MIN_QUALITY_THRESHOLD = 60.0,
    @LOG_RESULTS = 1;

-- 2. Kiểm tra một đặc trưng cụ thể
EXEC dbo.SP_VALIDATE_FEATURES
    @MODEL_ID = NULL,
    @FEATURE_ID = 1,
    @VALIDATION_DATE = NULL,
    @SEGMENT_ID = NULL,
    @MIN_QUALITY_THRESHOLD = 60.0,
    @LOG_RESULTS = 1;
    
-- 3. Kiểm tra tất cả đặc trưng đang hoạt động
EXEC dbo.SP_VALIDATE_FEATURES
    @MODEL_ID = NULL,
    @FEATURE_ID = NULL,
    @VALIDATION_DATE = NULL,
    @SEGMENT_ID = NULL,
    @MIN_QUALITY_THRESHOLD = 60.0,
    @LOG_RESULTS = 1;
    
-- 4. Kiểm tra các đặc trưng cho một phân khúc cụ thể
EXEC dbo.SP_VALIDATE_FEATURES
    @MODEL_ID = 1,
    @FEATURE_ID = NULL,
    @VALIDATION_DATE = NULL,
    @SEGMENT_ID = 2,
    @MIN_QUALITY_THRESHOLD = 60.0,
    @LOG_RESULTS = 1;
    
-- 5. Kiểm tra các đặc trưng với dữ liệu thống kê tại một ngày nhất định
EXEC dbo.SP_VALIDATE_FEATURES
    @MODEL_ID = 1,
    @FEATURE_ID = NULL,
    @VALIDATION_DATE = ''2025-04-01'',
    @SEGMENT_ID = NULL,
    @MIN_QUALITY_THRESHOLD = 60.0,
    @LOG_RESULTS = 1;';