/*
Tên file: 10_feature_transformations_data.sql
Mô tả: Nhập dữ liệu mẫu cho bảng FEATURE_TRANSFORMATIONS
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-17
Phiên bản: 1.0
*/

-- Xóa dữ liệu cũ nếu cần
-- DELETE FROM MODEL_REGISTRY.dbo.FEATURE_TRANSFORMATIONS;

-- Lấy các FEATURE_ID để tham chiếu
DECLARE @CUST_AGE_ID INT;
DECLARE @INCOME_ID INT;
DECLARE @CUST_TENURE_ID INT;
DECLARE @UTIL_RATIO_ID INT;
DECLARE @CUR_BAL_ID INT;
DECLARE @DPD_30_L12M_ID INT;
DECLARE @MAX_DPD_L12M_ID INT;
DECLARE @BUREAU_SCORE_ID INT;
DECLARE @DTI_ID INT;
DECLARE @LTV_ID INT;
DECLARE @BAL_GROWTH_ID INT;
DECLARE @AVG_BAL_L3M_ID INT;
DECLARE @CREDIT_LIMIT_ID INT;
DECLARE @INQ_L6M_ID INT;
DECLARE @CASH_ADV_RATIO_ID INT;

SELECT @CUST_AGE_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'CUST_AGE';
SELECT @INCOME_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'INCOME';
SELECT @CUST_TENURE_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'CUST_TENURE';
SELECT @UTIL_RATIO_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'UTIL_RATIO';
SELECT @CUR_BAL_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'CUR_BAL';
SELECT @DPD_30_L12M_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'DPD_30_L12M';
SELECT @MAX_DPD_L12M_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'MAX_DPD_L12M';
SELECT @BUREAU_SCORE_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'BUREAU_SCORE';
SELECT @DTI_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'DTI';
SELECT @LTV_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'LTV';
SELECT @BAL_GROWTH_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'BAL_GROWTH';
SELECT @AVG_BAL_L3M_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'AVG_BAL_L3M';
SELECT @CREDIT_LIMIT_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'CREDIT_LIMIT';
SELECT @INQ_L6M_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'INQ_L6M';
SELECT @CASH_ADV_RATIO_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'CASH_ADV_RATIO';

-- Nhập dữ liệu vào bảng FEATURE_TRANSFORMATIONS
INSERT INTO MODEL_REGISTRY.dbo.FEATURE_TRANSFORMATIONS (
    FEATURE_ID,
    TRANSFORMATION_NAME,
    TRANSFORMATION_TYPE,
    TRANSFORMATION_DESCRIPTION,
    TRANSFORMATION_SQL,
    TRANSFORMATION_PARAMS,
    PREPROCESSING_STEPS,
    POSTPROCESSING_STEPS,
    EXECUTION_ORDER,
    IS_MANDATORY,
    IS_REVERSIBLE,
    REVERSE_TRANSFORMATION_SQL
)
VALUES 
-- Transformations for Age
(@CUST_AGE_ID, 'Age Binning', 'BINNING', 
 N'Phân nhóm tuổi thành các khoảng rời rạc', 
 N'CASE 
    WHEN CUST_AGE < 25 THEN ''YOUNG'' 
    WHEN CUST_AGE < 35 THEN ''YOUNG_ADULT'' 
    WHEN CUST_AGE < 50 THEN ''MIDDLE_AGED'' 
    WHEN CUST_AGE < 65 THEN ''MATURE'' 
    ELSE ''SENIOR'' 
   END AS AGE_CATEGORY', 
 N'{"bins": [25, 35, 50, 65], "labels": ["YOUNG", "YOUNG_ADULT", "MIDDLE_AGED", "MATURE", "SENIOR"]}', 
 N'Kiểm tra và xử lý giá trị ngoại lệ: Nếu tuổi < 18 hoặc > 100, gán giá trị missing', 
 NULL, 
 1, 1, 0, NULL),

(@CUST_AGE_ID, 'Age Standardization', 'SCALING', 
 N'Chuẩn hóa tuổi thành biến có trung bình 0 và độ lệch chuẩn 1', 
 N'(CUST_AGE - @mean) / @std_dev AS AGE_STANDARDIZED', 
 N'{"mean": 42.5, "std_dev": 15.2}', 
 NULL, 
 NULL, 
 2, 0, 1, 
 N'(AGE_STANDARDIZED * @std_dev) + @mean AS CUST_AGE'),

-- Transformations for Income
(@INCOME_ID, 'Income Log Transform', 'LOG', 
 N'Biến đổi logarit tự nhiên của thu nhập để giảm độ lệch phân phối', 
 N'LOG(CASE WHEN INCOME > 0 THEN INCOME ELSE 1 END) AS LOG_INCOME', 
 NULL, 
 N'Kiểm tra và đảm bảo thu nhập > 0 trước khi áp dụng logarit', 
 NULL, 
 1, 1, 1, 
 N'EXP(LOG_INCOME) AS INCOME'),

(@INCOME_ID, 'Income Category', 'BINNING', 
 N'Phân loại thu nhập thành các nhóm thu nhập', 
 N'CASE 
    WHEN INCOME < 5000000 THEN ''LOW'' 
    WHEN INCOME < 20000000 THEN ''MEDIUM'' 
    WHEN INCOME < 50000000 THEN ''HIGH'' 
    ELSE ''VERY_HIGH'' 
   END AS INCOME_CATEGORY', 
 N'{"bins": [5000000, 20000000, 50000000], "labels": ["LOW", "MEDIUM", "HIGH", "VERY_HIGH"]}', 
 NULL, 
 NULL, 
 2, 1, 0, NULL),

(@INCOME_ID, 'Income MinMax Scaling', 'SCALING', 
 N'Chuẩn hóa thu nhập vào khoảng [0,1] sử dụng phương pháp Min-Max', 
 N'(INCOME - @min_value) / (@max_value - @min_value) AS INCOME_SCALED', 
 N'{"min_value": 0, "max_value": 100000000}', 
 NULL, 
 N'Giá trị nằm ngoài khoảng [0,1] sẽ được gán về giới hạn tương ứng', 
 3, 0, 1, 
 N'(INCOME_SCALED * (@max_value - @min_value)) + @min_value AS INCOME'),

-- Transformations for Utilization Ratio
(@UTIL_RATIO_ID, 'Utilization Ratio Binning', 'BINNING', 
 N'Phân nhóm tỷ lệ sử dụng thành các khoảng rời rạc', 
 N'CASE 
    WHEN UTIL_RATIO < 0.3 THEN ''LOW'' 
    WHEN UTIL_RATIO < 0.7 THEN ''MEDIUM'' 
    ELSE ''HIGH'' 
   END AS UTIL_CATEGORY', 
 N'{"bins": [0.3, 0.7], "labels": ["LOW", "MEDIUM", "HIGH"]}', 
 NULL, 
 NULL, 
 1, 1, 0, NULL),

(@UTIL_RATIO_ID, 'Utilization Ratio Transformation', 'POWER',
 N'Biến đổi phi tuyến tỷ lệ sử dụng để làm nổi bật sự khác biệt ở mức độ cao',
 N'POWER(UTIL_RATIO, 0.5) AS UTIL_TRANSFORMED',
 N'{"power": 0.5}',
 N'Đảm bảo UTIL_RATIO nằm trong khoảng [0,1]',
 NULL,
 2, 0, 1,
 N'POWER(UTIL_TRANSFORMED, 2) AS UTIL_RATIO'),

-- Transformations for Current Balance
(@CUR_BAL_ID, 'Balance Transformation', 'LOG', 
 N'Biến đổi logarit của số dư tuyệt đối cộng 1 để xử lý cả số âm và không', 
 N'LOG(ABS(CUR_BAL) + 1) AS LOG_BALANCE', 
 NULL, 
 NULL, 
 NULL, 
 1, 1, 0, NULL),

(@CUR_BAL_ID, 'Balance Sign Indicator', 'ENCODING', 
 N'Tạo biến chỉ báo về dấu của số dư', 
 N'CASE WHEN CUR_BAL >= 0 THEN 1 ELSE 0 END AS POSITIVE_BALANCE', 
 NULL, 
 NULL, 
 NULL, 
 2, 0, 0, NULL),

(@CUR_BAL_ID, 'Balance Categorization', 'BINNING', 
 N'Phân loại số dư thành các nhóm', 
 N'CASE 
    WHEN CUR_BAL < 0 THEN ''NEGATIVE'' 
    WHEN CUR_BAL = 0 THEN ''ZERO'' 
    WHEN CUR_BAL < 10000000 THEN ''LOW'' 
    WHEN CUR_BAL < 100000000 THEN ''MEDIUM'' 
    ELSE ''HIGH'' 
   END AS BALANCE_CATEGORY', 
 N'{"custom_bins": [0], "labels": ["NEGATIVE", "ZERO", "LOW", "MEDIUM", "HIGH"]}', 
 NULL, 
 NULL, 
 3, 0, 0, NULL),

-- Transformations for DPD 30+ Last 12M
(@DPD_30_L12M_ID, 'DPD Frequency Categorization', 'BINNING', 
 N'Phân loại tần suất DPD 30+ thành các nhóm', 
 N'CASE 
    WHEN DPD_30_L12M = 0 THEN ''NONE'' 
    WHEN DPD_30_L12M = 1 THEN ''ONCE'' 
    WHEN DPD_30_L12M <= 3 THEN ''FEW'' 
    ELSE ''MANY'' 
   END AS DPD_FREQUENCY', 
 N'{"custom_bins": [0, 1, 3], "labels": ["NONE", "ONCE", "FEW", "MANY"]}', 
 NULL, 
 NULL, 
 1, 1, 0, NULL),

(@DPD_30_L12M_ID, 'DPD Indicator', 'ENCODING', 
 N'Tạo biến chỉ báo liệu có DPD 30+ trong 12 tháng qua hay không', 
 N'CASE WHEN DPD_30_L12M > 0 THEN 1 ELSE 0 END AS HAS_DPD_30', 
 NULL, 
 NULL, 
 NULL, 
 2, 0, 0, NULL),

-- Transformations for Max DPD Last 12M
(@MAX_DPD_L12M_ID, 'Max DPD Categorization', 'BINNING', 
 N'Phân loại giá trị DPD tối đa thành các nhóm mức độ nghiêm trọng', 
 N'CASE 
    WHEN MAX_DPD_L12M = 0 THEN ''NONE'' 
    WHEN MAX_DPD_L12M <= 30 THEN ''MILD'' 
    WHEN MAX_DPD_L12M <= 60 THEN ''MODERATE'' 
    WHEN MAX_DPD_L12M <= 90 THEN ''SEVERE'' 
    ELSE ''CRITICAL'' 
   END AS MAX_DPD_CATEGORY', 
 N'{"custom_bins": [0, 30, 60, 90], "labels": ["NONE", "MILD", "MODERATE", "SEVERE", "CRITICAL"]}', 
 NULL, 
 NULL, 
 1, 1, 0, NULL),

(@MAX_DPD_L12M_ID, 'Max DPD Threshold Indicators', 'ENCODING', 
 N'Tạo các biến chỉ báo cho các ngưỡng DPD quan trọng', 
 N'CASE WHEN MAX_DPD_L12M > 30 THEN 1 ELSE 0 END AS DPD_OVER_30,
   CASE WHEN MAX_DPD_L12M > 60 THEN 1 ELSE 0 END AS DPD_OVER_60,
   CASE WHEN MAX_DPD_L12M > 90 THEN 1 ELSE 0 END AS DPD_OVER_90', 
 NULL, 
 NULL, 
 NULL, 
 2, 0, 0, NULL),

-- Transformations for Bureau Score
(@BUREAU_SCORE_ID, 'Bureau Score Scaling', 'SCALING', 
 N'Chuẩn hóa điểm tín dụng vào khoảng [0,1]', 
 N'(BUREAU_SCORE - 300) / 600 AS BUREAU_SCORE_SCALED', 
 N'{"min_value": 300, "max_value": 900}', 
 NULL, 
 NULL, 
 1, 1, 1, 
 N'(BUREAU_SCORE_SCALED * 600) + 300 AS BUREAU_SCORE'),

(@BUREAU_SCORE_ID, 'Bureau Score Categories', 'BINNING', 
 N'Phân loại điểm tín dụng thành các nhóm', 
 N'CASE 
    WHEN BUREAU_SCORE < 500 THEN ''VERY_LOW'' 
    WHEN BUREAU_SCORE < 600 THEN ''LOW'' 
    WHEN BUREAU_SCORE < 700 THEN ''MEDIUM'' 
    WHEN BUREAU_SCORE < 800 THEN ''HIGH'' 
    ELSE ''VERY_HIGH'' 
   END AS BUREAU_SCORE_CATEGORY', 
 N'{"bins": [500, 600, 700, 800], "labels": ["VERY_LOW", "LOW", "MEDIUM", "HIGH", "VERY_HIGH"]}', 
 NULL, 
 NULL, 
 2, 0, 0, NULL),

-- Transformations for Debt to Income Ratio
(@DTI_ID, 'DTI Capping', 'IMPUTATION', 
 N'Giới hạn DTI để tránh giá trị cực lớn', 
 N'CASE WHEN DTI > 1 THEN 1 ELSE DTI END AS DTI_CAPPED', 
 N'{"upper_cap": 1}', 
 NULL, 
 NULL, 
 1, 1, 0, NULL),

(@DTI_ID, 'DTI Categories', 'BINNING', 
 N'Phân loại DTI thành các nhóm mức độ', 
 N'CASE 
    WHEN DTI < 0.3 THEN ''LOW'' 
    WHEN DTI < 0.5 THEN ''MODERATE'' 
    WHEN DTI < 0.7 THEN ''HIGH'' 
    ELSE ''VERY_HIGH'' 
   END AS DTI_CATEGORY', 
 N'{"bins": [0.3, 0.5, 0.7], "labels": ["LOW", "MODERATE", "HIGH", "VERY_HIGH"]}', 
 NULL, 
 NULL, 
 2, 0, 0, NULL),

-- Transformations for LTV Ratio
(@LTV_ID, 'LTV Capping', 'IMPUTATION', 
 N'Giới hạn LTV để tránh giá trị cực lớn', 
 N'CASE WHEN LTV > 1.2 THEN 1.2 ELSE LTV END AS LTV_CAPPED', 
 N'{"upper_cap": 1.2}', 
 NULL, 
 NULL, 
 1, 1, 0, NULL),

(@LTV_ID, 'LTV Categories', 'BINNING', 
 N'Phân loại LTV thành các nhóm mức độ', 
 N'CASE 
    WHEN LTV <= 0.5 THEN ''VERY_LOW'' 
    WHEN LTV <= 0.7 THEN ''LOW'' 
    WHEN LTV <= 0.8 THEN ''MODERATE'' 
    WHEN LTV <= 0.9 THEN ''HIGH'' 
    ELSE ''VERY_HIGH'' 
   END AS LTV_CATEGORY', 
 N'{"bins": [0.5, 0.7, 0.8, 0.9], "labels": ["VERY_LOW", "LOW", "MODERATE", "HIGH", "VERY_HIGH"]}', 
 NULL, 
 NULL, 
 2, 0, 0, NULL),

-- Transformations for Balance Growth Rate
(@BAL_GROWTH_ID, 'Balance Growth Winsorization', 'IMPUTATION', 
 N'Winsorize tỷ lệ tăng trưởng dư nợ để giảm ảnh hưởng của giá trị cực lớn', 
 N'CASE 
    WHEN BAL_GROWTH < -0.5 THEN -0.5 
    WHEN BAL_GROWTH > 2 THEN 2 
    ELSE BAL_GROWTH 
   END AS BAL_GROWTH_WINSORIZED', 
 N'{"lower_cap": -0.5, "upper_cap": 2}', 
 NULL, 
 NULL, 
 1, 1, 0, NULL),

(@BAL_GROWTH_ID, 'Balance Growth Categories', 'BINNING', 
 N'Phân loại tỷ lệ tăng trưởng dư nợ thành các xu hướng', 
 N'CASE 
    WHEN BAL_GROWTH < -0.1 THEN ''DECREASING'' 
    WHEN BAL_GROWTH < 0.05 THEN ''STABLE'' 
    WHEN BAL_GROWTH < 0.2 THEN ''GROWING'' 
    ELSE ''RAPIDLY_GROWING'' 
   END AS GROWTH_CATEGORY', 
 N'{"bins": [-0.1, 0.05, 0.2], "labels": ["DECREASING", "STABLE", "GROWING", "RAPIDLY_GROWING"]}', 
 NULL, 
 NULL, 
 2, 0, 0, NULL),

-- Transformations for Average Balance L3M
(@AVG_BAL_L3M_ID, 'Average Balance Log Transform', 'LOG', 
 N'Biến đổi logarit của số dư trung bình tuyệt đối cộng 1', 
 N'LOG(ABS(AVG_BAL_L3M) + 1) AS LOG_AVG_BAL', 
 NULL, 
 NULL, 
 NULL, 
 1, 1, 0, NULL),

(@AVG_BAL_L3M_ID, 'Average Balance Normalization', 'SCALING', 
 N'Chuẩn hóa số dư trung bình sử dụng phương pháp MinMax có giới hạn', 
 N'(
   CASE 
     WHEN AVG_BAL_L3M < @min_value THEN @min_value 
     WHEN AVG_BAL_L3M > @max_value THEN @max_value 
     ELSE AVG_BAL_L3M 
   END - @min_value
  ) / (@max_value - @min_value) AS AVG_BAL_NORM', 
 N'{"min_value": -10000000, "max_value": 100000000}', 
 NULL, 
 NULL, 
 2, 0, 1, 
 N'(AVG_BAL_NORM * (@max_value - @min_value)) + @min_value AS AVG_BAL_L3M'),

-- Transformations for Credit Limit
(@CREDIT_LIMIT_ID, 'Credit Limit Log Transform', 'LOG', 
 N'Biến đổi logarit tự nhiên của hạn mức tín dụng', 
 N'LOG(CASE WHEN CREDIT_LIMIT > 0 THEN CREDIT_LIMIT ELSE 1 END) AS LOG_CREDIT_LIMIT', 
 NULL, 
 N'Kiểm tra và đảm bảo CREDIT_LIMIT > 0 trước khi áp dụng logarit', 
 NULL, 
 1, 1, 1, 
 N'EXP(LOG_CREDIT_LIMIT) AS CREDIT_LIMIT'),

(@CREDIT_LIMIT_ID, 'Credit Limit Categorization', 'BINNING', 
 N'Phân loại hạn mức tín dụng thành các cấp độ', 
 N'CASE 
    WHEN CREDIT_LIMIT < 10000000 THEN ''LOW'' 
    WHEN CREDIT_LIMIT < 50000000 THEN ''MEDIUM'' 
    WHEN CREDIT_LIMIT < 200000000 THEN ''HIGH'' 
    ELSE ''PREMIUM'' 
   END AS CREDIT_LIMIT_CATEGORY', 
 N'{"bins": [10000000, 50000000, 200000000], "labels": ["LOW", "MEDIUM", "HIGH", "PREMIUM"]}', 
 NULL, 
 NULL, 
 2, 0, 0, NULL),

-- Transformations for Inquiries Last 6M
(@INQ_L6M_ID, 'Inquiry Categorization', 'BINNING', 
 N'Phân loại số lần truy vấn thành các nhóm mức độ', 
 N'CASE 
    WHEN INQ_L6M = 0 THEN ''NONE'' 
    WHEN INQ_L6M = 1 THEN ''ONE'' 
    WHEN INQ_L6M <= 3 THEN ''FEW'' 
    WHEN INQ_L6M <= 6 THEN ''MODERATE'' 
    ELSE ''MANY'' 
   END AS INQUIRY_INTENSITY', 
 N'{"custom_bins": [0, 1, 3, 6], "labels": ["NONE", "ONE", "FEW", "MODERATE", "MANY"]}', 
 NULL, 
 NULL, 
 1, 1, 0, NULL),

(@INQ_L6M_ID, 'Recent Inquiry Indicator', 'ENCODING', 
 N'Tạo biến chỉ báo liệu có truy vấn gần đây hay không', 
 N'CASE WHEN INQ_L6M > 0 THEN 1 ELSE 0 END AS HAS_RECENT_INQUIRY', 
 NULL, 
 NULL, 
 NULL, 
 2, 0, 0, NULL),

-- Transformations for Cash Advance Ratio
(@CASH_ADV_RATIO_ID, 'Cash Advance Ratio Categorization', 'BINNING', 
 N'Phân loại tỷ lệ rút tiền mặt thành các nhóm mức độ', 
 N'CASE 
    WHEN CASH_ADV_RATIO = 0 THEN ''NONE'' 
    WHEN CASH_ADV_RATIO < 0.1 THEN ''LOW'' 
    WHEN CASH_ADV_RATIO < 0.3 THEN ''MODERATE'' 
    WHEN CASH_ADV_RATIO < 0.5 THEN ''HIGH'' 
    ELSE ''VERY_HIGH'' 
   END AS CASH_ADVANCE_USAGE', 
 N'{"bins": [0, 0.1, 0.3, 0.5], "labels": ["NONE", "LOW", "MODERATE", "HIGH", "VERY_HIGH"]}', 
 NULL, 
 NULL, 
 1, 1, 0, NULL),

(@CASH_ADV_RATIO_ID, 'Cash Advance Indicator', 'ENCODING', 
 N'Tạo biến chỉ báo liệu có sử dụng rút tiền mặt hay không', 
 N'CASE WHEN CASH_ADV_RATIO > 0 THEN 1 ELSE 0 END AS HAS_CASH_ADVANCE', 
 NULL, 
 NULL, 
 NULL, 
 2, 0, 0, NULL),

(@CASH_ADV_RATIO_ID, 'Cash Advance Risk Transformation', 'POWER', 
 N'Biến đổi phi tuyến để làm nổi bật rủi ro ở tỷ lệ sử dụng tiền mặt cao', 
 N'POWER(CASH_ADV_RATIO, 0.5) AS CASH_ADV_RISK', 
 N'{"power": 0.5}', 
 NULL, 
 N'Tỷ lệ cao hơn rất quan trọng trong việc dự báo rủi ro tín dụng', 
 3, 0, 1, 
 N'POWER(CASH_ADV_RISK, 2) AS CASH_ADV_RATIO');
GO

PRINT N'Đã nhập dữ liệu mẫu cho bảng FEATURE_TRANSFORMATIONS thành công.';
GO