/*
Tên file: 08_model_column_details_data.sql
Mô tả: Nhập dữ liệu mẫu cho bảng MODEL_COLUMN_DETAILS
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-17
Phiên bản: 1.0
*/

-- Xóa dữ liệu cũ nếu cần
-- DELETE FROM MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS;

-- Lấy các SOURCE_TABLE_ID để tham chiếu
DECLARE @DIM_CUSTOMER_ID INT;
DECLARE @DIM_ACCOUNT_ID INT;
DECLARE @FACT_ACCOUNT_BALANCE_ID INT;
DECLARE @FACT_PAYMENT_HISTORY_ID INT;
DECLARE @FACT_DELINQUENCY_ID INT;
DECLARE @FACT_CREDIT_BUREAU_ID INT;
DECLARE @PD_RETAIL_FEATURES_ID INT;
DECLARE @PD_MORTGAGE_RESULTS_ID INT;
DECLARE @BSCORE_CARDS_RESULTS_ID INT;

SELECT @DIM_CUSTOMER_ID = SOURCE_TABLE_ID FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES WHERE SOURCE_TABLE_NAME = 'DIM_CUSTOMER';
SELECT @DIM_ACCOUNT_ID = SOURCE_TABLE_ID FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES WHERE SOURCE_TABLE_NAME = 'DIM_ACCOUNT';
SELECT @FACT_ACCOUNT_BALANCE_ID = SOURCE_TABLE_ID FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES WHERE SOURCE_TABLE_NAME = 'FACT_ACCOUNT_BALANCE';
SELECT @FACT_PAYMENT_HISTORY_ID = SOURCE_TABLE_ID FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES WHERE SOURCE_TABLE_NAME = 'FACT_PAYMENT_HISTORY';
SELECT @FACT_DELINQUENCY_ID = SOURCE_TABLE_ID FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES WHERE SOURCE_TABLE_NAME = 'FACT_DELINQUENCY';
SELECT @FACT_CREDIT_BUREAU_ID = SOURCE_TABLE_ID FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES WHERE SOURCE_TABLE_NAME = 'FACT_CREDIT_BUREAU';
SELECT @PD_RETAIL_FEATURES_ID = SOURCE_TABLE_ID FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES WHERE SOURCE_TABLE_NAME = 'PD_RETAIL_FEATURES';
SELECT @PD_MORTGAGE_RESULTS_ID = SOURCE_TABLE_ID FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES WHERE SOURCE_TABLE_NAME = 'PD_MORTGAGE_RESULTS';
SELECT @BSCORE_CARDS_RESULTS_ID = SOURCE_TABLE_ID FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES WHERE SOURCE_TABLE_NAME = 'BSCORE_CARDS_RESULTS';

-- Nhập dữ liệu vào bảng MODEL_COLUMN_DETAILS
INSERT INTO MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS (
    SOURCE_TABLE_ID,
    COLUMN_NAME,
    DATA_TYPE,
    COLUMN_DESCRIPTION,
    IS_MANDATORY,
    IS_FEATURE,
    FEATURE_IMPORTANCE,
    BUSINESS_DEFINITION,
    TRANSFORMATION_LOGIC,
    EXPECTED_VALUES,
    DATA_QUALITY_CHECKS
)
VALUES 
-- DIM_CUSTOMER key columns
(@DIM_CUSTOMER_ID, 'CUSTOMER_ID', 'INT', N'Mã định danh khách hàng', 1, 0, NULL, 
 N'Mã định danh duy nhất của khách hàng trong hệ thống ngân hàng', 
 NULL, 
 N'Giá trị số nguyên dương', 
 N'NOT NULL, PRIMARY KEY CHECK'),

(@DIM_CUSTOMER_ID, 'CUSTOMER_TYPE', 'NVARCHAR(20)', N'Loại khách hàng', 1, 1, 0.05, 
 N'Phân loại khách hàng (INDIVIDUAL, BUSINESS)', 
 NULL, 
 N'INDIVIDUAL, BUSINESS', 
 N'NOT NULL, ENUM CHECK'),

(@DIM_CUSTOMER_ID, 'CUSTOMER_SEGMENT', 'NVARCHAR(50)', N'Phân khúc khách hàng', 1, 1, 0.12, 
 N'Phân khúc khách hàng theo chính sách của ngân hàng', 
 NULL, 
 N'RETAIL, SME, CORPORATE, PREMIER, AFFLUENT, MASS', 
 N'NOT NULL, ENUM CHECK'),

(@DIM_CUSTOMER_ID, 'GENDER', 'NVARCHAR(10)', N'Giới tính', 0, 1, 0.03, 
 N'Giới tính của khách hàng cá nhân', 
 NULL, 
 N'MALE, FEMALE, OTHER', 
 N'ENUM CHECK'),

(@DIM_CUSTOMER_ID, 'DATE_OF_BIRTH', 'DATE', N'Ngày sinh', 0, 1, 0.08, 
 N'Ngày sinh của khách hàng cá nhân', 
 N'DATE_DIFF(YEAR, DATE_OF_BIRTH, CURRENT_DATE) AS AGE', 
 N'Ngày hợp lệ, không trong tương lai, tuổi từ 18-100', 
 N'DATE RANGE CHECK, NOT FUTURE DATE'),

(@DIM_CUSTOMER_ID, 'INCOME', 'DECIMAL(18,2)', N'Thu nhập', 0, 1, 0.15, 
 N'Thu nhập hàng tháng của khách hàng (VND)', 
 N'LOG(INCOME) AS LOG_INCOME, CASE WHEN INCOME < 5000000 THEN ''LOW'' WHEN INCOME < 20000000 THEN ''MEDIUM'' ELSE ''HIGH'' END AS INCOME_CATEGORY', 
 N'Giá trị số dương, thông thường từ 3,000,000 đến 500,000,000', 
 N'POSITIVE CHECK, RANGE CHECK, OUTLIER DETECTION'),

(@DIM_CUSTOMER_ID, 'OCCUPATION', 'NVARCHAR(100)', N'Nghề nghiệp', 0, 1, 0.06, 
 N'Nghề nghiệp hoặc lĩnh vực làm việc của khách hàng', 
 N'CASE WHEN OCCUPATION IN (''DOCTOR'', ''LAWYER'', ''ENGINEER'') THEN ''PROFESSIONAL'' ... END AS OCCUPATION_CATEGORY', 
 N'Giá trị văn bản hợp lệ', 
 N'CATEGORY MAPPING'),

(@DIM_CUSTOMER_ID, 'EMPLOYMENT_STATUS', 'NVARCHAR(50)', N'Tình trạng việc làm', 0, 1, 0.07, 
 N'Tình trạng việc làm hiện tại của khách hàng', 
 NULL, 
 N'EMPLOYED, SELF_EMPLOYED, UNEMPLOYED, RETIRED, STUDENT', 
 N'ENUM CHECK'),

(@DIM_CUSTOMER_ID, 'RESIDENCE_STATUS', 'NVARCHAR(50)', N'Tình trạng cư trú', 0, 1, 0.04, 
 N'Tình trạng sở hữu nơi ở của khách hàng', 
 NULL, 
 N'OWNED, MORTGAGED, RENTED, LIVING_WITH_PARENTS, OTHER', 
 N'ENUM CHECK'),

(@DIM_CUSTOMER_ID, 'REGISTRATION_DATE', 'DATE', N'Ngày đăng ký', 1, 1, 0.09, 
 N'Ngày khách hàng đăng ký với ngân hàng', 
 N'DATE_DIFF(MONTH, REGISTRATION_DATE, CURRENT_DATE) AS CUSTOMER_TENURE_MONTHS', 
 N'Ngày hợp lệ, không trong tương lai', 
 N'DATE RANGE CHECK, NOT FUTURE DATE'),

-- FACT_CREDIT_BUREAU continued
(@FACT_CREDIT_BUREAU_ID, 'INQUIRIES_L6M', 'INT', N'Số lần truy vấn trong 6 tháng qua', 0, 1, 0.15, 
 N'Số lần truy vấn thông tin tín dụng trong 6 tháng qua', 
 N'CASE WHEN INQUIRIES_L6M <= 1 THEN ''LOW'' WHEN INQUIRIES_L6M <= 3 THEN ''MEDIUM'' ELSE ''HIGH'' END AS INQUIRY_INTENSITY', 
 N'Giá trị số nguyên không âm', 
 N'NON-NEGATIVE CHECK'),

(@FACT_CREDIT_BUREAU_ID, 'DELINQUENCIES_L24M', 'INT', N'Số lần quá hạn trong 24 tháng qua', 0, 1, 0.22, 
 N'Số lần quá hạn ghi nhận trong 24 tháng qua', 
 N'CASE WHEN DELINQUENCIES_L24M = 0 THEN ''NONE'' WHEN DELINQUENCIES_L24M = 1 THEN ''ONCE'' WHEN DELINQUENCIES_L24M <= 3 THEN ''FEW'' ELSE ''MANY'' END AS DELINQUENCY_HISTORY', 
 N'Giá trị số nguyên không âm', 
 N'NON-NEGATIVE CHECK'),

(@FACT_CREDIT_BUREAU_ID, 'CREDIT_HISTORY_LENGTH', 'INT', N'Độ dài lịch sử tín dụng', 0, 1, 0.13, 
 N'Độ dài lịch sử tín dụng tính theo tháng', 
 N'CASE WHEN CREDIT_HISTORY_LENGTH < 12 THEN ''NEW'' WHEN CREDIT_HISTORY_LENGTH < 36 THEN ''DEVELOPING'' WHEN CREDIT_HISTORY_LENGTH < 60 THEN ''ESTABLISHED'' ELSE ''MATURE'' END AS HISTORY_CATEGORY', 
 N'Giá trị số nguyên dương', 
 N'POSITIVE CHECK'),

(@FACT_CREDIT_BUREAU_ID, 'TOTAL_DEFAULTS', 'INT', N'Tổng số vỡ nợ', 0, 1, 0.24, 
 N'Tổng số lần vỡ nợ trong lịch sử tín dụng', 
 N'CASE WHEN TOTAL_DEFAULTS = 0 THEN ''NONE'' WHEN TOTAL_DEFAULTS = 1 THEN ''ONCE'' ELSE ''MULTIPLE'' END AS DEFAULT_HISTORY', 
 N'Giá trị số nguyên không âm', 
 N'NON-NEGATIVE CHECK'),

(@FACT_CREDIT_BUREAU_ID, 'HAS_CURRENT_DEFAULT', 'BIT', N'Có vỡ nợ hiện tại', 0, 1, 0.27, 
 N'Cờ đánh dấu khách hàng đang có khoản vỡ nợ', 
 NULL, 
 N'0 (No), 1 (Yes)', 
 N'BOOLEAN CHECK'),

-- PD_RETAIL_FEATURES key columns (model input features)
(@PD_RETAIL_FEATURES_ID, 'CUSTOMER_ID', 'INT', N'Mã định danh khách hàng', 1, 0, NULL, 
 N'Mã định danh duy nhất của khách hàng', 
 NULL, 
 N'Giá trị số nguyên dương', 
 N'NOT NULL, FOREIGN KEY CHECK'),

(@PD_RETAIL_FEATURES_ID, 'PROCESS_DATE', 'DATE', N'Ngày xử lý', 1, 0, NULL, 
 N'Ngày tính toán đặc trưng', 
 NULL, 
 N'Ngày hợp lệ, không trong tương lai', 
 N'NOT NULL, DATE RANGE CHECK, NOT FUTURE DATE'),

(@PD_RETAIL_FEATURES_ID, 'CUSTOMER_AGE', 'INT', N'Tuổi khách hàng', 0, 1, 0.05, 
 N'Tuổi của khách hàng tính tại ngày xử lý', 
 N'CASE WHEN CUSTOMER_AGE < 25 THEN ''YOUNG'' WHEN CUSTOMER_AGE < 35 THEN ''YOUNG_ADULT'' WHEN CUSTOMER_AGE < 50 THEN ''MIDDLE_AGED'' ELSE ''SENIOR'' END AS AGE_CATEGORY', 
 N'Giá trị số nguyên từ 18 đến 100', 
 N'RANGE CHECK (18-100)'),

(@PD_RETAIL_FEATURES_ID, 'CUSTOMER_TENURE', 'INT', N'Thời gian là khách hàng', 0, 1, 0.08, 
 N'Thời gian khách hàng quan hệ với ngân hàng (tháng)', 
 N'CASE WHEN CUSTOMER_TENURE < 12 THEN ''NEW'' WHEN CUSTOMER_TENURE < 36 THEN ''ESTABLISHED'' ELSE ''LOYAL'' END AS TENURE_CATEGORY', 
 N'Giá trị số nguyên không âm', 
 N'NON-NEGATIVE CHECK'),

(@PD_RETAIL_FEATURES_ID, 'INCOME_CATEGORY', 'VARCHAR(20)', N'Phân loại thu nhập', 0, 1, 0.12, 
 N'Phân loại thu nhập của khách hàng', 
 NULL, 
 N'LOW, MEDIUM, HIGH', 
 N'ENUM CHECK'),

(@PD_RETAIL_FEATURES_ID, 'AVG_BALANCE_L3M', 'DECIMAL(18,2)', N'Số dư trung bình 3 tháng', 0, 1, 0.15, 
 N'Số dư tài khoản trung bình trong 3 tháng gần nhất (VND)', 
 N'LOG(ABS(AVG_BALANCE_L3M) + 1) AS LOG_AVG_BALANCE_L3M', 
 N'Giá trị số, có thể dương hoặc âm', 
 N'RANGE CHECK'),

(@PD_RETAIL_FEATURES_ID, 'UTILIZATION_RATIO', 'DECIMAL(5,2)', N'Tỷ lệ sử dụng tín dụng', 0, 1, 0.22, 
 N'Tỷ lệ sử dụng hạn mức tín dụng (%)', 
 N'CASE WHEN UTILIZATION_RATIO < 0.3 THEN ''LOW'' WHEN UTILIZATION_RATIO < 0.7 THEN ''MEDIUM'' ELSE ''HIGH'' END AS UTILIZATION_CATEGORY', 
 N'Giá trị số từ 0% đến 100%', 
 N'RANGE CHECK (0-100)'),

(@PD_RETAIL_FEATURES_ID, 'DPD_LAST_12M', 'INT', N'Số lần DPD 30+ trong 12 tháng', 0, 1, 0.25, 
 N'Số lần quá hạn trên 30 ngày trong 12 tháng qua', 
 N'CASE WHEN DPD_LAST_12M = 0 THEN ''NONE'' WHEN DPD_LAST_12M = 1 THEN ''ONCE'' WHEN DPD_LAST_12M <= 3 THEN ''FEW'' ELSE ''MANY'' END AS DPD_FREQUENCY', 
 N'Giá trị số nguyên không âm', 
 N'NON-NEGATIVE CHECK'),

(@PD_RETAIL_FEATURES_ID, 'MAX_DPD_LAST_12M', 'INT', N'Số ngày DPD tối đa trong 12 tháng', 0, 1, 0.20, 
 N'Số ngày quá hạn tối đa trong 12 tháng qua', 
 N'CASE WHEN MAX_DPD_LAST_12M = 0 THEN ''NONE'' WHEN MAX_DPD_LAST_12M <= 30 THEN ''MILD'' WHEN MAX_DPD_LAST_12M <= 60 THEN ''MODERATE'' WHEN MAX_DPD_LAST_12M <= 90 THEN ''SEVERE'' ELSE ''CRITICAL'' END AS MAX_DPD_CATEGORY', 
 N'Giá trị số nguyên không âm', 
 N'NON-NEGATIVE CHECK'),

(@PD_RETAIL_FEATURES_ID, 'PAYMENT_RATIO', 'DECIMAL(5,2)', N'Tỷ lệ thanh toán', 0, 1, 0.18, 
 N'Tỷ lệ thanh toán trên dư nợ (%)', 
 N'CASE WHEN PAYMENT_RATIO < 0.03 THEN ''MINIMUM'' WHEN PAYMENT_RATIO < 0.1 THEN ''PARTIAL'' WHEN PAYMENT_RATIO < 0.5 THEN ''SUBSTANTIAL'' ELSE ''FULL'' END AS PAYMENT_BEHAVIOR', 
 N'Giá trị số từ 0% đến 100%', 
 N'RANGE CHECK (0-100)'),

(@PD_RETAIL_FEATURES_ID, 'BUREAU_SCORE', 'INT', N'Điểm tín dụng', 0, 1, 0.28, 
 N'Điểm tín dụng từ cục thông tin tín dụng', 
 N'CASE WHEN BUREAU_SCORE < 500 THEN ''VERY_LOW'' WHEN BUREAU_SCORE < 600 THEN ''LOW'' WHEN BUREAU_SCORE < 700 THEN ''MEDIUM'' WHEN BUREAU_SCORE < 800 THEN ''HIGH'' ELSE ''VERY_HIGH'' END AS BUREAU_SCORE_CATEGORY', 
 N'Giá trị số nguyên từ 300 đến 900', 
 N'RANGE CHECK (300-900)'),

(@PD_RETAIL_FEATURES_ID, 'DEBT_TO_INCOME', 'DECIMAL(6,2)', N'Tỷ lệ nợ trên thu nhập', 0, 1, 0.16, 
 N'Tỷ lệ tổng dư nợ trên thu nhập hàng tháng (%)', 
 N'CASE WHEN DEBT_TO_INCOME < 0.3 THEN ''LOW'' WHEN DEBT_TO_INCOME < 0.5 THEN ''MODERATE'' WHEN DEBT_TO_INCOME < 0.7 THEN ''HIGH'' ELSE ''VERY_HIGH'' END AS DTI_CATEGORY', 
 N'Giá trị số từ 0% đến 100%', 
 N'RANGE CHECK (0-100)'),

(@PD_RETAIL_FEATURES_ID, 'BALANCE_GROWTH_RATE', 'DECIMAL(6,2)', N'Tỷ lệ tăng trưởng dư nợ', 0, 1, 0.10, 
 N'Tỷ lệ tăng trưởng dư nợ trong 6 tháng qua (%)', 
 N'CASE WHEN BALANCE_GROWTH_RATE < 0 THEN ''DECREASING'' WHEN BALANCE_GROWTH_RATE < 0.05 THEN ''STABLE'' WHEN BALANCE_GROWTH_RATE < 0.2 THEN ''GROWING'' ELSE ''RAPIDLY_GROWING'' END AS GROWTH_CATEGORY', 
 N'Giá trị số, có thể dương hoặc âm', 
 N'RANGE CHECK'),

-- PD_MORTGAGE_RESULTS key columns (model output)
(@PD_MORTGAGE_RESULTS_ID, 'CUSTOMER_ID', 'INT', N'Mã định danh khách hàng', 1, 0, NULL, 
 N'Mã định danh duy nhất của khách hàng', 
 NULL, 
 N'Giá trị số nguyên dương', 
 N'NOT NULL, FOREIGN KEY CHECK'),

(@PD_MORTGAGE_RESULTS_ID, 'PROCESS_DATE', 'DATE', N'Ngày xử lý', 1, 0, NULL, 
 N'Ngày tính toán kết quả mô hình', 
 NULL, 
 N'Ngày hợp lệ, không trong tương lai', 
 N'NOT NULL, DATE RANGE CHECK, NOT FUTURE DATE'),

(@PD_MORTGAGE_RESULTS_ID, 'PD_VALUE', 'DECIMAL(9,6)', N'Giá trị xác suất vỡ nợ', 1, 0, NULL, 
 N'Xác suất vỡ nợ trong khoảng thời gian nhất định', 
 NULL, 
 N'Giá trị số từ 0 đến 1', 
 N'NOT NULL, RANGE CHECK (0-1)'),

(@PD_MORTGAGE_RESULTS_ID, 'PD_SCORE', 'INT', N'Điểm xác suất vỡ nợ', 0, 0, NULL, 
 N'Điểm số tương ứng với xác suất vỡ nợ', 
 NULL, 
 N'Giá trị số nguyên từ 300 đến 900', 
 N'RANGE CHECK (300-900)'),

(@PD_MORTGAGE_RESULTS_ID, 'RISK_GRADE', 'VARCHAR(5)', N'Cấp độ rủi ro', 0, 0, NULL, 
 N'Cấp độ rủi ro dựa trên xác suất vỡ nợ', 
 NULL, 
 N'AAA, AA, A, BBB, BB, B, CCC, CC, C', 
 N'ENUM CHECK'),

(@PD_MORTGAGE_RESULTS_ID, 'PD_CALIBRATED', 'DECIMAL(9,6)', N'Xác suất vỡ nợ đã hiệu chỉnh', 0, 0, NULL, 
 N'Xác suất vỡ nợ sau khi hiệu chỉnh', 
 NULL, 
 N'Giá trị số từ 0 đến 1', 
 N'RANGE CHECK (0-1)'),

(@PD_MORTGAGE_RESULTS_ID, 'PD_VARIANCE', 'DECIMAL(9,6)', N'Phương sai xác suất vỡ nợ', 0, 0, NULL, 
 N'Phương sai của ước lượng xác suất vỡ nợ', 
 NULL, 
 N'Giá trị số từ 0 đến 1', 
 N'RANGE CHECK (0-1)'),

(@PD_MORTGAGE_RESULTS_ID, 'MODEL_VERSION', 'VARCHAR(20)', N'Phiên bản mô hình', 1, 0, NULL, 
 N'Phiên bản mô hình được sử dụng', 
 NULL, 
 N'Chuỗi phiên bản hợp lệ (vd: 1.0, 1.2)', 
 N'NOT NULL CHECK'),

-- BSCORE_CARDS_RESULTS key columns (model output)
(@BSCORE_CARDS_RESULTS_ID, 'CUSTOMER_ID', 'INT', N'Mã định danh khách hàng', 1, 0, NULL, 
 N'Mã định danh duy nhất của khách hàng', 
 NULL, 
 N'Giá trị số nguyên dương', 
 N'NOT NULL, FOREIGN KEY CHECK'),

(@BSCORE_CARDS_RESULTS_ID, 'PROCESS_DATE', 'DATE', N'Ngày xử lý', 1, 0, NULL, 
 N'Ngày tính toán kết quả mô hình', 
 NULL, 
 N'Ngày hợp lệ, không trong tương lai', 
 N'NOT NULL, DATE RANGE CHECK, NOT FUTURE DATE'),

(@BSCORE_CARDS_RESULTS_ID, 'BEHAVIOR_SCORE', 'INT', N'Điểm hành vi', 1, 0, NULL, 
 N'Điểm đánh giá hành vi sử dụng thẻ tín dụng', 
 NULL, 
 N'Giá trị số nguyên từ 300 đến 900', 
 N'NOT NULL, RANGE CHECK (300-900)'),

(@BSCORE_CARDS_RESULTS_ID, 'RISK_CATEGORY', 'VARCHAR(20)', N'Phân loại rủi ro', 1, 0, NULL, 
 N'Phân loại mức độ rủi ro dựa trên điểm hành vi', 
 NULL, 
 N'LOW_RISK, MEDIUM_RISK, HIGH_RISK, VERY_HIGH_RISK', 
 N'NOT NULL, ENUM CHECK'),

(@BSCORE_CARDS_RESULTS_ID, 'DEFAULT_PROBABILITY', 'DECIMAL(9,6)', N'Xác suất vỡ nợ', 0, 0, NULL, 
 N'Xác suất vỡ nợ trong 12 tháng tới dựa trên điểm hành vi', 
 NULL, 
 N'Giá trị số từ 0 đến 1', 
 N'RANGE CHECK (0-1)'),

(@BSCORE_CARDS_RESULTS_ID, 'UTIL_RATIO_CONTRIB', 'INT', N'Đóng góp của tỷ lệ sử dụng', 0, 0, NULL, 
 N'Điểm đóng góp từ tỷ lệ sử dụng hạn mức', 
 NULL, 
 N'Giá trị số nguyên', 
 NULL),

(@BSCORE_CARDS_RESULTS_ID, 'PAYMENT_HISTORY_CONTRIB', 'INT', N'Đóng góp của lịch sử thanh toán', 0, 0, NULL, 
 N'Điểm đóng góp từ lịch sử thanh toán', 
 NULL, 
 N'Giá trị số nguyên', 
 NULL),

(@BSCORE_CARDS_RESULTS_ID, 'CASH_ADVANCE_CONTRIB', 'INT', N'Đóng góp của rút tiền mặt', 0, 0, NULL, 
 N'Điểm đóng góp từ hành vi rút tiền mặt', 
 NULL, 
 N'Giá trị số nguyên', 
 NULL),

(@BSCORE_CARDS_RESULTS_ID, 'BALANCE_GROWTH_CONTRIB', 'INT', N'Đóng góp của tăng trưởng dư nợ', 0, 0, NULL, 
 N'Điểm đóng góp từ tốc độ tăng trưởng dư nợ', 
 NULL, 
 N'Giá trị số nguyên', 
 NULL),

(@BSCORE_CARDS_RESULTS_ID, 'MODEL_VERSION', 'VARCHAR(20)', N'Phiên bản mô hình', 1, 0, NULL, 
 N'Phiên bản mô hình được sử dụng', 
 NULL, 
 N'Chuỗi phiên bản hợp lệ (vd: 1.0, 1.3)', 
 N'NOT NULL CHECK');
GO

PRINT N'Đã nhập dữ liệu mẫu cho bảng MODEL_COLUMN_DETAILS thành công.';
GO