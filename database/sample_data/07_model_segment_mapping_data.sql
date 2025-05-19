/*
Tên file: 07_model_segment_mapping_data.sql
Mô tả: Nhập dữ liệu mẫu cho bảng MODEL_SEGMENT_MAPPING
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-17
Phiên bản: 1.0
*/

-- Xóa dữ liệu cũ nếu cần
-- DELETE FROM MODEL_REGISTRY.dbo.MODEL_SEGMENT_MAPPING;

-- Lấy các MODEL_ID để tham chiếu
DECLARE @PD_RETAIL_ID INT;
DECLARE @PD_MORTGAGE_ID INT;
DECLARE @PD_UNSECURED_ID INT;
DECLARE @PD_CARDS_ID INT;
DECLARE @BSCORE_RETAIL_MORTGAGE_ID INT;
DECLARE @BSCORE_CARDS_ID INT;
DECLARE @PD_SME_ID INT;
DECLARE @ASCORE_RETAIL_ID INT;
DECLARE @ASCORE_RETAIL_BUREAU_ID INT;

SELECT @PD_RETAIL_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'PD_RETAIL';
SELECT @PD_MORTGAGE_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'PD_RETAIL_MORTGAGE';
SELECT @PD_UNSECURED_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'PD_RETAIL_UNSECURED';
SELECT @PD_CARDS_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'PD_RETAIL_CARDS';
SELECT @BSCORE_RETAIL_MORTGAGE_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'BSCORE_RETAIL_MORTGAGE';
SELECT @BSCORE_CARDS_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'BSCORE_RETAIL_CARDS';
SELECT @PD_SME_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'PD_SME';
SELECT @ASCORE_RETAIL_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'ASCORE_RETAIL';
SELECT @ASCORE_RETAIL_BUREAU_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'ASCORE_RETAIL_BUREAU';

-- Nhập dữ liệu vào bảng MODEL_SEGMENT_MAPPING
INSERT INTO MODEL_REGISTRY.dbo.MODEL_SEGMENT_MAPPING (
    MODEL_ID,
    SEGMENT_NAME,
    SEGMENT_DESCRIPTION,
    SEGMENT_CRITERIA,
    PRIORITY,
    EXPECTED_VOLUME,
    SEGMENT_PERFORMANCE,
    EFF_DATE,
    EXP_DATE,
    IS_ACTIVE
)
VALUES 
-- PD Retail segments
(@PD_RETAIL_ID, 'Mass Segment', N'Khách hàng cá nhân phân khúc đại chúng', 
 N'CUSTOMER_SEGMENT = ''RETAIL'' AND SUB_SEGMENT = ''MASS'' AND ACTIVE_FLAG = 1', 
 1, 500000, 
 N'{"GINI": 0.48, "KS": 0.42, "AUC": 0.74, "PSI": 0.12}',
 '2024-01-01', '2026-01-01', 1),

(@PD_RETAIL_ID, 'Affluent Segment', N'Khách hàng cá nhân phân khúc khá giả', 
 N'CUSTOMER_SEGMENT = ''RETAIL'' AND SUB_SEGMENT = ''AFFLUENT'' AND ACTIVE_FLAG = 1', 
 1, 150000, 
 N'{"GINI": 0.55, "KS": 0.47, "AUC": 0.78, "PSI": 0.09}',
 '2024-01-01', '2026-01-01', 1),

(@PD_RETAIL_ID, 'Premier Segment', N'Khách hàng cá nhân phân khúc cao cấp', 
 N'CUSTOMER_SEGMENT = ''RETAIL'' AND SUB_SEGMENT = ''PREMIER'' AND ACTIVE_FLAG = 1', 
 1, 50000, 
 N'{"GINI": 0.58, "KS": 0.51, "AUC": 0.79, "PSI": 0.11}',
 '2024-01-01', '2026-01-01', 1),

-- PD Mortgage segments
(@PD_MORTGAGE_ID, 'Urban Properties', N'Các khoản vay mua bất động sản tại khu vực đô thị', 
 N'PROPERTY_TYPE IN (''APARTMENT'', ''CONDO'', ''TOWNHOUSE'') AND URBAN_FLAG = 1 AND PURPOSE = ''HOME_PURCHASE''', 
 1, 80000, 
 N'{"GINI": 0.52, "KS": 0.45, "AUC": 0.76, "PSI": 0.08}',
 '2024-03-01', '2026-03-01', 1),

(@PD_MORTGAGE_ID, 'Suburban Properties', N'Các khoản vay mua bất động sản tại khu vực ngoại ô', 
 N'PROPERTY_TYPE IN (''HOUSE'', ''VILLA'') AND URBAN_FLAG = 0 AND PURPOSE = ''HOME_PURCHASE''', 
 2, 60000, 
 N'{"GINI": 0.49, "KS": 0.42, "AUC": 0.74, "PSI": 0.10}',
 '2024-03-01', '2026-03-01', 1),

(@PD_MORTGAGE_ID, 'Refinance Mortgages', N'Các khoản vay tái cấp vốn bất động sản', 
 N'PURPOSE = ''REFINANCE''', 
 3, 40000, 
 N'{"GINI": 0.47, "KS": 0.40, "AUC": 0.73, "PSI": 0.13}',
 '2024-03-01', '2026-03-01', 1),

-- PD Unsecured segments
(@PD_UNSECURED_ID, 'High Income Unsecured', N'Khách hàng vay tín chấp thu nhập cao', 
 N'CUSTOMER_SEGMENT = ''RETAIL'' AND LOAN_TYPE = ''UNSECURED'' AND INCOME_CATEGORY = ''HIGH''', 
 1, 70000, 
 N'{"GINI": 0.51, "KS": 0.44, "AUC": 0.76, "PSI": 0.11}',
 '2024-02-15', '2026-02-15', 1),

(@PD_UNSECURED_ID, 'Medium Income Unsecured', N'Khách hàng vay tín chấp thu nhập trung bình', 
 N'CUSTOMER_SEGMENT = ''RETAIL'' AND LOAN_TYPE = ''UNSECURED'' AND INCOME_CATEGORY = ''MEDIUM''', 
 2, 120000, 
 N'{"GINI": 0.48, "KS": 0.41, "AUC": 0.74, "PSI": 0.12}',
 '2024-02-15', '2026-02-15', 1),

(@PD_UNSECURED_ID, 'Low Income Unsecured', N'Khách hàng vay tín chấp thu nhập thấp', 
 N'CUSTOMER_SEGMENT = ''RETAIL'' AND LOAN_TYPE = ''UNSECURED'' AND INCOME_CATEGORY = ''LOW''', 
 3, 90000, 
 N'{"GINI": 0.45, "KS": 0.38, "AUC": 0.72, "PSI": 0.14}',
 '2024-02-15', '2026-02-15', 1),

-- Credit Card segments
(@PD_CARDS_ID, 'Platinum Cards', N'Thẻ tín dụng hạng platinum', 
 N'CARD_TYPE = ''PLATINUM'' AND ACTIVE_FLAG = 1', 
 1, 30000, 
 N'{"GINI": 0.56, "KS": 0.48, "AUC": 0.78, "PSI": 0.09}',
 '2024-02-20', '2026-02-20', 1),

(@PD_CARDS_ID, 'Gold Cards', N'Thẻ tín dụng hạng gold', 
 N'CARD_TYPE = ''GOLD'' AND ACTIVE_FLAG = 1', 
 2, 80000, 
 N'{"GINI": 0.53, "KS": 0.46, "AUC": 0.77, "PSI": 0.10}',
 '2024-02-20', '2026-02-20', 1),

(@PD_CARDS_ID, 'Standard Cards', N'Thẻ tín dụng hạng chuẩn', 
 N'CARD_TYPE = ''STANDARD'' AND ACTIVE_FLAG = 1', 
 3, 150000, 
 N'{"GINI": 0.50, "KS": 0.43, "AUC": 0.75, "PSI": 0.11}',
 '2024-02-20', '2026-02-20', 1),

-- Behavioral Scorecard segments for mortgage
(@BSCORE_RETAIL_MORTGAGE_ID, 'Low LTV Mortgage', N'Khoản vay thế chấp nhà có tỷ lệ LTV thấp', 
 N'PRODUCT_TYPE = ''MORTGAGE'' AND LTV < 0.6 AND MOB >= 12', 
 1, 40000, 
 N'{"GINI": 0.52, "KS": 0.45, "AUC": 0.76, "F1": 0.82}',
 '2024-06-30', '9999-12-31', 1),

(@BSCORE_RETAIL_MORTGAGE_ID, 'Medium LTV Mortgage', N'Khoản vay thế chấp nhà có tỷ lệ LTV trung bình', 
 N'PRODUCT_TYPE = ''MORTGAGE'' AND LTV >= 0.6 AND LTV <= 0.8 AND MOB >= 12', 
 2, 60000, 
 N'{"GINI": 0.48, "KS": 0.42, "AUC": 0.74, "F1": 0.78}',
 '2024-06-30', '9999-12-31', 1),

(@BSCORE_RETAIL_MORTGAGE_ID, 'High LTV Mortgage', N'Khoản vay thế chấp nhà có tỷ lệ LTV cao', 
 N'PRODUCT_TYPE = ''MORTGAGE'' AND LTV > 0.8 AND MOB >= 12', 
 3, 30000, 
 N'{"GINI": 0.45, "KS": 0.39, "AUC": 0.72, "F1": 0.75}',
 '2024-06-30', '9999-12-31', 1),

-- Behavioral Scorecard segments for credit cards
(@BSCORE_CARDS_ID, 'High Spenders', N'Khách hàng thẻ có mức chi tiêu cao', 
 N'PRODUCT_TYPE = ''CREDIT_CARD'' AND AVG_SPEND > 10000000 AND MOB >= 6', 
 1, 20000, 
 N'{"GINI": 0.54, "KS": 0.47, "AUC": 0.77, "F1": 0.83}',
 '2021-12-31', '9999-12-31', 1),

(@BSCORE_CARDS_ID, 'Medium Spenders', N'Khách hàng thẻ có mức chi tiêu trung bình', 
 N'PRODUCT_TYPE = ''CREDIT_CARD'' AND AVG_SPEND BETWEEN 5000000 AND 10000000 AND MOB >= 6', 
 2, 50000, 
 N'{"GINI": 0.51, "KS": 0.44, "AUC": 0.75, "F1": 0.80}',
 '2021-12-31', '9999-12-31', 1),

(@BSCORE_CARDS_ID, 'Low Spenders', N'Khách hàng thẻ có mức chi tiêu thấp', 
 N'PRODUCT_TYPE = ''CREDIT_CARD'' AND AVG_SPEND < 5000000 AND MOB >= 6', 
 3, 80000, 
 N'{"GINI": 0.47, "KS": 0.40, "AUC": 0.73, "F1": 0.76}',
 '2021-12-31', '9999-12-31', 1),

-- SME segments
(@PD_SME_ID, 'Micro Enterprises', N'Doanh nghiệp siêu nhỏ', 
 N'BUSINESS_SEGMENT = ''SME'' AND ANNUAL_REVENUE < 10000000000 AND COMPANY_SIZE = ''MICRO''', 
 1, 25000, 
 N'{"GINI": 0.60, "KS": 0.48, "AUC": 0.80, "F1": 0.85}',
 '2024-04-01', '2026-04-01', 1),

(@PD_SME_ID, 'Small Enterprises', N'Doanh nghiệp nhỏ', 
 N'BUSINESS_SEGMENT = ''SME'' AND ANNUAL_REVENUE BETWEEN 10000000000 AND 50000000000 AND COMPANY_SIZE = ''SMALL''', 
 2, 15000, 
 N'{"GINI": 0.65, "KS": 0.52, "AUC": 0.82, "F1": 0.87}',
 '2024-04-01', '2026-04-01', 1),

(@PD_SME_ID, 'Medium Enterprises', N'Doanh nghiệp vừa', 
 N'BUSINESS_SEGMENT = ''SME'' AND ANNUAL_REVENUE > 50000000000 AND COMPANY_SIZE = ''MEDIUM''', 
 3, 10000, 
 N'{"GINI": 0.68, "KS": 0.55, "AUC": 0.84, "F1": 0.89}',
 '2024-04-01', '2026-04-01', 1),

-- Application Scorecard segments
(@ASCORE_RETAIL_ID, 'New Customers', N'Khách hàng mới, không có lịch sử quan hệ với ngân hàng', 
 N'IS_NEW_CUSTOMER = 1 AND BUREAU_DATA = 0', 
 1, 100000, 
 N'{"GINI": 0.40, "KS": 0.34, "AUC": 0.70, "F1": 0.72}',
 '2024-01-15', '2026-01-15', 1),

(@ASCORE_RETAIL_ID, 'Existing Deposit Customers', N'Khách hàng hiện tại có sản phẩm tiền gửi', 
 N'IS_NEW_CUSTOMER = 0 AND HAS_DEPOSIT = 1 AND HAS_LOAN = 0 AND BUREAU_DATA = 0', 
 2, 50000, 
 N'{"GINI": 0.42, "KS": 0.36, "AUC": 0.71, "F1": 0.74}',
 '2024-01-15', '2026-01-15', 1),

-- Application Scorecard with Bureau segments
(@ASCORE_RETAIL_BUREAU_ID, 'New With Bureau', N'Khách hàng mới có dữ liệu tín dụng ngoài', 
 N'IS_NEW_CUSTOMER = 1 AND BUREAU_DATA = 1', 
 1, 80000, 
 N'{"GINI": 0.65, "KS": 0.52, "AUC": 0.82, "F1": 0.85}',
 '2024-02-20', '2026-02-20', 1),

(@ASCORE_RETAIL_BUREAU_ID, 'Existing With Bureau', N'Khách hàng hiện tại có dữ liệu tín dụng ngoài', 
 N'IS_NEW_CUSTOMER = 0 AND BUREAU_DATA = 1', 
 2, 40000, 
 N'{"GINI": 0.67, "KS": 0.54, "AUC": 0.83, "F1": 0.87}',
 '2024-02-20', '2026-02-20', 1);
GO

PRINT N'Đã nhập dữ liệu mẫu cho bảng MODEL_SEGMENT_MAPPING thành công.';
GO