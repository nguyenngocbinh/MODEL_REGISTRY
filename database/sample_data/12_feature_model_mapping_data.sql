/*
Tên file: 12_feature_model_mapping_data.sql
Mô tả: Nhập dữ liệu mẫu cho bảng FEATURE_MODEL_MAPPING
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-18
Phiên bản: 1.0
*/

-- Xóa dữ liệu cũ nếu cần
-- DELETE FROM MODEL_REGISTRY.dbo.FEATURE_MODEL_MAPPING;

-- Lấy các FEATURE_ID để tham chiếu
DECLARE @CUST_AGE_ID INT;
DECLARE @INCOME_ID INT;
DECLARE @CUST_TENURE_ID INT;
DECLARE @UTIL_RATIO_ID INT;
DECLARE @DPD_30_L12M_ID INT;
DECLARE @MAX_DPD_L12M_ID INT;
DECLARE @BUREAU_SCORE_ID INT;
DECLARE @DTI_ID INT;
DECLARE @LTV_ID INT;
DECLARE @BAL_GROWTH_ID INT;
DECLARE @AVG_BAL_L3M_ID INT;
DECLARE @PMT_RATIO_ID INT;
DECLARE @CASH_ADV_RATIO_ID INT;
DECLARE @GENDER_ID INT;
DECLARE @OCCUP_ID INT;
DECLARE @EMP_STATUS_ID INT;
DECLARE @RES_STATUS_ID INT;
DECLARE @CUST_SEGMENT_ID INT;
DECLARE @CREDIT_LIMIT_ID INT;
DECLARE @INT_RATE_ID INT;
DECLARE @INQUIRIES_L6M_ID INT;
DECLARE @PD_ID INT;
DECLARE @RISK_GRADE_ID INT;
DECLARE @BEH_SCORE_ID INT;

SELECT @CUST_AGE_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'CUST_AGE';
SELECT @INCOME_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'INCOME';
SELECT @CUST_TENURE_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'CUST_TENURE';
SELECT @UTIL_RATIO_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'UTIL_RATIO';
SELECT @DPD_30_L12M_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'DPD_30_L12M';
SELECT @MAX_DPD_L12M_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'MAX_DPD_L12M';
SELECT @BUREAU_SCORE_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'BUREAU_SCORE';
SELECT @DTI_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'DTI';
SELECT @LTV_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'LTV';
SELECT @BAL_GROWTH_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'BAL_GROWTH';
SELECT @AVG_BAL_L3M_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'AVG_BAL_L3M';
SELECT @PMT_RATIO_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'PMT_RATIO';
SELECT @CASH_ADV_RATIO_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'CASH_ADV_RATIO';
SELECT @GENDER_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'GENDER';
SELECT @OCCUP_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'OCCUP';
SELECT @EMP_STATUS_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'EMP_STATUS';
SELECT @RES_STATUS_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'RES_STATUS';
SELECT @CUST_SEGMENT_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'CUST_SEGMENT';
SELECT @CREDIT_LIMIT_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'CREDIT_LIMIT';
SELECT @INT_RATE_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'INT_RATE';
SELECT @INQUIRIES_L6M_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'INQ_L6M';
SELECT @PD_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'PD';
SELECT @RISK_GRADE_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'RISK_GRADE';
SELECT @BEH_SCORE_ID = FEATURE_ID FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'BEH_SCORE';

-- Lấy các MODEL_ID để tham chiếu
DECLARE @PD_RETAIL_ID INT;
DECLARE @PD_MORTGAGE_ID INT;
DECLARE @PD_UNSECURED_ID INT;
DECLARE @PD_CARDS_ID INT;
DECLARE @PD_SME_ID INT;
DECLARE @PD_CORPORATE_ID INT;
DECLARE @LGD_RETAIL_ID INT;
DECLARE @BSCORE_RETAIL_MORTGAGE_ID INT;
DECLARE @BSCORE_CARDS_ID INT;
DECLARE @ASCORE_RETAIL_ID INT;
DECLARE @ASCORE_RETAIL_BUREAU_ID INT;
DECLARE @ASCORE_SME_ID INT;
DECLARE @EWS_SME_ID INT;

SELECT @PD_RETAIL_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'PD_RETAIL';
SELECT @PD_MORTGAGE_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'PD_RETAIL_MORTGAGE';
SELECT @PD_UNSECURED_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'PD_RETAIL_UNSECURED';
SELECT @PD_CARDS_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'PD_RETAIL_CARDS';
SELECT @PD_SME_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'PD_SME';
SELECT @PD_CORPORATE_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'PD_CORPORATE';
SELECT @LGD_RETAIL_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'LGD_RETAIL';
SELECT @BSCORE_RETAIL_MORTGAGE_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'BSCORE_RETAIL_MORTGAGE';
SELECT @BSCORE_CARDS_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'BSCORE_RETAIL_CARDS';
SELECT @ASCORE_RETAIL_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'ASCORE_RETAIL';
SELECT @ASCORE_RETAIL_BUREAU_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'ASCORE_RETAIL_BUREAU';
SELECT @ASCORE_SME_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'ASCORE_SME';
SELECT @EWS_SME_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'EWS_SME';

-- Nhập dữ liệu vào bảng FEATURE_MODEL_MAPPING
INSERT INTO MODEL_REGISTRY.dbo.FEATURE_MODEL_MAPPING (
    FEATURE_ID,
    MODEL_ID,
    USAGE_TYPE,
    FEATURE_IMPORTANCE,
    FEATURE_WEIGHT,
    IS_MANDATORY,
    TRANSFORMATION_APPLIED,
    FEATURE_RANK,
    PERMUTATION_IMPORTANCE,
    SHAP_VALUE,
    USAGE_DESCRIPTION
)
VALUES 
-- PD_RETAIL model features
(@CUST_AGE_ID, @PD_RETAIL_ID, 'INPUT', 0.08, -0.0124, 1, 
 'Binning into age categories: YOUNG (<25), YOUNG_ADULT (25-35), MIDDLE_AGED (35-50), SENIOR (>50)', 
 7, 0.06, 0.07, 
 'Customer age as a demographic predictor of default risk. Younger and older customers tend to have different default patterns.'),

(@INCOME_ID, @PD_RETAIL_ID, 'INPUT', 0.15, -0.5218, 1, 
 'Log transformation and standardization', 
 3, 0.12, 0.14, 
 'Monthly income is a key indicator of repayment capacity. Higher income generally correlates with lower default risk.'),

(@CUST_TENURE_ID, @PD_RETAIL_ID, 'INPUT', 0.09, -0.2043, 1, 
 'Binning into tenure categories: NEW (<12 months), ESTABLISHED (12-36 months), LOYAL (>36 months)', 
 6, 0.08, 0.09, 
 'Customer relationship length indicates stability. Longer relationships typically show lower default risk.'),

(@UTIL_RATIO_ID, @PD_RETAIL_ID, 'INPUT', 0.22, 0.7621, 1, 
 'Scaling to 0-1 range and categorical binning (LOW, MEDIUM, HIGH)', 
 2, 0.18, 0.20, 
 'Credit utilization ratio is a strong predictor of default. Higher utilization correlates with higher risk.'),

(@DPD_30_L12M_ID, @PD_RETAIL_ID, 'INPUT', 0.25, 0.9821, 1, 
 'Binning into frequency categories: NONE (0), ONCE (1), FEW (2-3), MANY (>3)', 
 1, 0.21, 0.23, 
 'Past delinquency frequency is the strongest predictor of future default. More frequent past delinquencies indicate higher risk.'),

(@MAX_DPD_L12M_ID, @PD_RETAIL_ID, 'INPUT', 0.20, 0.7456, 1, 
 'Binning into severity categories: NONE (0), MILD (1-30), MODERATE (31-60), SEVERE (61-90), CRITICAL (>90)', 
 4, 0.17, 0.19, 
 'Maximum delinquency severity indicates worst-case payment behavior. Higher past DPD correlates with default risk.'),

(@BUREAU_SCORE_ID, @PD_RETAIL_ID, 'INPUT', 0.28, -0.9235, 1, 
 'MinMax scaling to 0-1 range', 
 5, 0.24, 0.26, 
 'External credit score provides third-party assessment of creditworthiness. Lower scores indicate higher default risk.'),

(@BAL_GROWTH_ID, @PD_RETAIL_ID, 'INPUT', 0.10, 0.3125, 0, 
 'Winsorization at [-0.5, 2] and categorization', 
 10, 0.08, 0.09, 
 'Balance growth rate indicates increasing or decreasing debt burden. Rapid growth can signal financial distress.'),

(@PD_ID, @PD_RETAIL_ID, 'OUTPUT', 1.0, NULL, 1, 
 'Logistic transformation to probability [0-1]', 
 NULL, NULL, NULL, 
 'Probability of Default within 12 months - primary output of the model.'),

(@RISK_GRADE_ID, @PD_RETAIL_ID, 'DERIVED', NULL, NULL, 0, 
 'Mapping of PD ranges to letter grades', 
 NULL, NULL, NULL, 
 'Risk grade derived from PD for business reporting and decision-making.'),

-- PD_MORTGAGE model features
(@CUST_AGE_ID, @PD_MORTGAGE_ID, 'INPUT', 0.05, -0.0098, 1, 
 'Binning into age categories', 
 5, 0.04, 0.06, 
 'Age as demographic factor in mortgage default risk assessment.'),

(@INCOME_ID, @PD_MORTGAGE_ID, 'INPUT', 0.12, -0.4129, 1, 
 'Log transformation', 
 3, 0.10, 0.11, 
 'Income as indicator of mortgage repayment capacity.'),

(@LTV_ID, @PD_MORTGAGE_ID, 'INPUT', 0.25, 0.9318, 1, 
 'Binning into LTV categories', 
 1, 0.22, 0.24, 
 'Loan-to-Value ratio is the primary risk driver for mortgage loans. Higher LTV indicates higher default risk.'),

(@DTI_ID, @PD_MORTGAGE_ID, 'INPUT', 0.18, 0.6452, 1, 
 'Capping at 1.0 and binning', 
 2, 0.15, 0.17, 
 'Debt-to-Income ratio measures repayment capacity. Higher DTI indicates lower affordability and higher risk.'),

(@BUREAU_SCORE_ID, @PD_MORTGAGE_ID, 'INPUT', 0.15, -0.5127, 1, 
 'MinMax scaling to 0-1 range', 
 4, 0.13, 0.14, 
 'External credit score for overall creditworthiness assessment.'),

(@PD_ID, @PD_MORTGAGE_ID, 'OUTPUT', 1.0, NULL, 1, 
 'Logistic transformation to probability [0-1]', 
 NULL, NULL, NULL, 
 'Probability of Default within 12 months for mortgage loans.'),

-- PD_CARDS model features
(@UTIL_RATIO_ID, @PD_CARDS_ID, 'INPUT', 0.25, 0.8725, 1, 
 'Scaling and binning', 
 1, 0.22, 0.24, 
 'Credit card utilization is the strongest predictor for card default risk.'),

(@CASH_ADV_RATIO_ID, @PD_CARDS_ID, 'INPUT', 0.20, 0.7125, 1, 
 'Square root transformation and binning', 
 2, 0.18, 0.19, 
 'Cash advance usage is a strong indicator of liquidity issues and higher default risk for cards.'),

(@DPD_30_L12M_ID, @PD_CARDS_ID, 'INPUT', 0.18, 0.6824, 1, 
 'Frequency categorization', 
 3, 0.16, 0.17, 
 'Past delinquency frequency for predicting future card payment behavior.'),

(@PMT_RATIO_ID, @PD_CARDS_ID, 'INPUT', 0.15, -0.5321, 1, 
 'Binning into payment behavior categories', 
 4, 0.13, 0.14, 
 'Payment ratio indicates whether customer pays minimum, partial, or full balance. Lower ratios correlate with higher risk.'),

(@BUREAU_SCORE_ID, @PD_CARDS_ID, 'INPUT', 0.12, -0.4215, 1, 
 'Scaling and binning', 
 5, 0.10, 0.11, 
 'External credit score for general creditworthiness assessment.'),

(@PD_ID, @PD_CARDS_ID, 'OUTPUT', 1.0, NULL, 1, 
 'Logistic transformation to probability [0-1]', 
 NULL, NULL, NULL, 
 'Probability of Default within 12 months for credit card accounts.'),

-- BSCORE_CARDS model features
(@UTIL_RATIO_ID, @BSCORE_CARDS_ID, 'INPUT', 0.18, -50, 1, 
 'Scaling and binning', 
 1, 0.16, 0.17, 
 'Utilization ratio contribution to behavioral score. Higher utilization reduces score.'),

(@PMT_RATIO_ID, @BSCORE_CARDS_ID, 'INPUT', 0.22, 80, 1, 
 'Payment behavior categorization', 
 2, 0.19, 0.21, 
 'Payment history contribution to behavioral score. Higher payment ratio improves score.'),

(@CASH_ADV_RATIO_ID, @BSCORE_CARDS_ID, 'INPUT', 0.12, -30, 1, 
 'Square root transformation', 
 3, 0.10, 0.11, 
 'Cash advance usage contribution to behavioral score. Higher cash advance ratio reduces score.'),

(@BAL_GROWTH_ID, @BSCORE_CARDS_ID, 'INPUT', 0.15, -45, 1, 
 'Growth rate categorization', 
 4, 0.13, 0.14, 
 'Balance growth contribution to behavioral score. Rapid growth reduces score.'),

(@DPD_30_L12M_ID, @BSCORE_CARDS_ID, 'INPUT', 0.25, -100, 1, 
 'Delinquency frequency categorization', 
 5, 0.22, 0.24, 
 'Past delinquency contribution to behavioral score. More delinquencies significantly reduce score.'),

(@BEH_SCORE_ID, @BSCORE_CARDS_ID, 'OUTPUT', 1.0, NULL, 1, 
 'Linear combination and scaling to 300-900 range', 
 NULL, NULL, NULL, 
 'Behavioral score indicating account performance and risk level.'),

(@PD_ID, @BSCORE_CARDS_ID, 'DERIVED', NULL, NULL, 0, 
 'Score-to-probability mapping table', 
 NULL, NULL, NULL, 
 'Derived PD from behavioral score for risk assessment purposes.'),

-- ASCORE_RETAIL model features
(@INCOME_ID, @ASCORE_RETAIL_ID, 'INPUT', 0.20, 60, 1, 
 'Income categorization and scaling', 
 1, 0.18, 0.19, 
 'Income contribution to application score. Higher income improves score.'),

(@CUST_AGE_ID, @ASCORE_RETAIL_ID, 'INPUT', 0.10, 25, 1, 
 'Age categorization', 
 4, 0.08, 0.09, 
 'Age contribution to application score. Middle-aged applicants typically score higher.'),

(@RES_STATUS_ID, @ASCORE_RETAIL_ID, 'INPUT', 0.08, 20, 1, 
 'Residence stability categorization', 
 3, 0.07, 0.08, 
 'Residence stability contribution to score. Owned residence improves score.'),

(@EMP_STATUS_ID, @ASCORE_RETAIL_ID, 'INPUT', 0.12, 35, 1, 
 'Employment stability categorization', 
 2, 0.10, 0.11, 
 'Employment stability contribution to score. Stable employment improves score.'),

(@OCCUP_ID, @ASCORE_RETAIL_ID, 'INPUT', 0.05, 15, 0, 
 'Occupation categorization', 
 5, 0.04, 0.05, 
 'Occupation contribution to score. Some professions are associated with lower risk.'),

(@BEH_SCORE_ID, @ASCORE_RETAIL_ID, 'OUTPUT', 1.0, NULL, 1, 
 'Linear combination and scaling to 300-900 range', 
 NULL, NULL, NULL, 
 'Application score indicating default risk for new applicants without bureau data.'),

-- ASCORE_RETAIL_BUREAU model features
(@INCOME_ID, @ASCORE_RETAIL_BUREAU_ID, 'INPUT', 0.15, 50, 1, 
 'Income categorization and scaling', 
 3, 0.13, 0.14, 
 'Income contribution to application score with bureau data.'),

(@BUREAU_SCORE_ID, @ASCORE_RETAIL_BUREAU_ID, 'INPUT', 0.25, 90, 1, 
 'Credit score scaling', 
 1, 0.22, 0.24, 
 'Bureau score contribution. External credit score is the strongest factor when available.'),

(@INQUIRIES_L6M_ID, @ASCORE_RETAIL_BUREAU_ID, 'INPUT', 0.10, -30, 1, 
 'Inquiry frequency categorization', 
 4, 0.08, 0.09, 
 'Recent credit inquiries contribution. More inquiries reduce score as they indicate credit-seeking behavior.'),

(@RES_STATUS_ID, @ASCORE_RETAIL_BUREAU_ID, 'INPUT', 0.05, 15, 0, 
 'Residence stability categorization', 
 5, 0.04, 0.05, 
 'Residence stability contribution with reduced importance compared to non-bureau model.'),

(@EMP_STATUS_ID, @ASCORE_RETAIL_BUREAU_ID, 'INPUT', 0.08, 20, 1, 
 'Employment stability categorization', 
 2, 0.07, 0.08, 
 'Employment stability contribution with reduced importance compared to non-bureau model.'),

(@BEH_SCORE_ID, @ASCORE_RETAIL_BUREAU_ID, 'OUTPUT', 1.0, NULL, 1, 
 'Linear combination and scaling to 300-900 range', 
 NULL, NULL, NULL, 
 'Application score indicating default risk for new applicants with bureau data.');
GO

PRINT N'Đã nhập dữ liệu mẫu cho bảng FEATURE_MODEL_MAPPING thành công.';
GO