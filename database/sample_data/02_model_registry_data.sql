/*
Tên file: 02_model_registry_data.sql
Mô tả: Nhập dữ liệu mẫu cho bảng MODEL_REGISTRY
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.0
*/

-- Xóa dữ liệu cũ nếu cần
-- DELETE FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY;

-- Lấy các TYPE_ID từ bảng MODEL_TYPE để tham chiếu
DECLARE @PD_TYPE_ID INT;
DECLARE @LGD_TYPE_ID INT;
DECLARE @BSCORE_TYPE_ID INT;
DECLARE @APP_SCORE_TYPE_ID INT;
DECLARE @EARLY_WARN_TYPE_ID INT;
DECLARE @SEGMENT_TYPE_ID INT;

SELECT @PD_TYPE_ID = TYPE_ID FROM MODEL_REGISTRY.dbo.MODEL_TYPE WHERE TYPE_CODE = 'PD';
SELECT @LGD_TYPE_ID = TYPE_ID FROM MODEL_REGISTRY.dbo.MODEL_TYPE WHERE TYPE_CODE = 'LGD';
SELECT @BSCORE_TYPE_ID = TYPE_ID FROM MODEL_REGISTRY.dbo.MODEL_TYPE WHERE TYPE_CODE = 'BSCORE';
SELECT @APP_SCORE_TYPE_ID = TYPE_ID FROM MODEL_REGISTRY.dbo.MODEL_TYPE WHERE TYPE_CODE = 'APP_SCORE';
SELECT @EARLY_WARN_TYPE_ID = TYPE_ID FROM MODEL_REGISTRY.dbo.MODEL_TYPE WHERE TYPE_CODE = 'EARLY_WARN';
SELECT @SEGMENT_TYPE_ID = TYPE_ID FROM MODEL_REGISTRY.dbo.MODEL_TYPE WHERE TYPE_CODE = 'SEGMENT';

-- Nhập dữ liệu vào bảng MODEL_REGISTRY
INSERT INTO MODEL_REGISTRY.dbo.MODEL_REGISTRY (
    TYPE_ID,
    MODEL_NAME,
    MODEL_DESCRIPTION,
    MODEL_VERSION,
    SOURCE_DATABASE,
    SOURCE_SCHEMA,
    SOURCE_TABLE_NAME,
    REF_SOURCE,
    EFF_DATE,
    EXP_DATE,
    IS_ACTIVE,
    PRIORITY,
    MODEL_CATEGORY,
    SEGMENT_CRITERIA
)
VALUES 
-- PD Models
(@PD_TYPE_ID, 'PD_RETAIL', N'Mô hình xác suất vỡ nợ cho khách hàng cá nhân', '1.0', 'RISK_MODELS', 'dbo', 'PD_RETAIL_RESULTS', 
 N'Risk Management/Model Development/PD Models/PD_RETAIL_v1.0_Documentation.pdf', '2024-01-01', '2026-01-01', 1, 1, 'Retail',
 N'{"customer_segment": "RETAIL", "product_type": "ALL", "vintage": "ALL"}'),

(@PD_TYPE_ID, 'PD_RETAIL_MORTGAGE', N'Mô hình xác suất vỡ nợ cho khách hàng vay thế chấp nhà', '1.2', 'RISK_MODELS', 'dbo', 'PD_MORTGAGE_RESULTS', 
 N'Risk Management/Model Development/PD Models/PD_RETAIL_MORTGAGE_v1.2_Documentation.pdf', '2024-03-01', '2026-03-01', 1, 2, 'Retail',
 N'{"customer_segment": "RETAIL", "product_type": "MORTGAGE", "vintage": "ALL"}'),

(@PD_TYPE_ID, 'PD_RETAIL_UNSECURED', N'Mô hình xác suất vỡ nợ cho khách hàng vay tín chấp', '1.1', 'RISK_MODELS', 'dbo', 'PD_UNSECURED_RESULTS', 
 N'Risk Management/Model Development/PD Models/PD_RETAIL_UNSECURED_v1.1_Documentation.pdf', '2024-02-15', '2026-02-15', 1, 2, 'Retail',
 N'{"customer_segment": "RETAIL", "product_type": "UNSECURED", "vintage": "ALL"}'),

(@PD_TYPE_ID, 'PD_SME', N'Mô hình xác suất vỡ nợ cho khách hàng doanh nghiệp vừa và nhỏ', '2.0', 'RISK_MODELS', 'dbo', 'PD_SME_RESULTS', 
 N'Risk Management/Model Development/PD Models/PD_SME_v2.0_Documentation.pdf', '2024-04-01', '2026-04-01', 1, 1, 'SME',
 N'{"customer_segment": "SME", "product_type": "ALL", "company_size": "SMALL_MEDIUM"}'),

(@PD_TYPE_ID, 'PD_CORPORATE', N'Mô hình xác suất vỡ nợ cho khách hàng doanh nghiệp lớn', '1.5', 'RISK_MODELS', 'dbo', 'PD_CORPORATE_RESULTS', 
 N'Risk Management/Model Development/PD Models/PD_CORPORATE_v1.5_Documentation.pdf', '2024-05-15', '2026-05-15', 1, 1, 'Corporate',
 N'{"customer_segment": "CORPORATE", "product_type": "ALL", "company_size": "LARGE"}'),

-- LGD Models
(@LGD_TYPE_ID, 'LGD_RETAIL', N'Mô hình tổn thất khi vỡ nợ cho khách hàng cá nhân', '1.0', 'RISK_MODELS', 'dbo', 'LGD_RETAIL_RESULTS', 
 N'Risk Management/Model Development/LGD Models/LGD_RETAIL_v1.0_Documentation.pdf', '2024-01-01', '2026-01-01', 1, 1, 'Retail',
 N'{"customer_segment": "RETAIL", "product_type": "ALL", "collateral": "ALL"}'),

(@LGD_TYPE_ID, 'LGD_SME', N'Mô hình tổn thất khi vỡ nợ cho khách hàng doanh nghiệp vừa và nhỏ', '1.0', 'RISK_MODELS', 'dbo', 'LGD_SME_RESULTS', 
 N'Risk Management/Model Development/LGD Models/LGD_SME_v1.0_Documentation.pdf', '2024-04-01', '2026-04-01', 1, 1, 'SME',
 N'{"customer_segment": "SME", "product_type": "ALL", "company_size": "SMALL_MEDIUM"}'),

-- Behavioral Scorecard Models
(@BSCORE_TYPE_ID, 'BSCORE_RETAIL', N'Thẻ điểm hành vi cho khách hàng cá nhân', '2.1', 'RISK_MODELS', 'dbo', 'BSCORE_RETAIL_RESULTS', 
 N'Risk Management/Model Development/Scorecards/BSCORE_RETAIL_v2.1_Documentation.pdf', '2024-02-01', '2026-02-01', 1, 1, 'Retail',
 N'{"customer_segment": "RETAIL", "account_age": ">= 6 months", "product_type": "ALL"}'),

(@BSCORE_TYPE_ID, 'BSCORE_RETAIL_CARDS', N'Thẻ điểm hành vi cho khách hàng thẻ tín dụng', '1.3', 'RISK_MODELS', 'dbo', 'BSCORE_CARDS_RESULTS', 
 N'Risk Management/Model Development/Scorecards/BSCORE_RETAIL_CARDS_v1.3_Documentation.pdf', '2024-03-15', '2026-03-15', 1, 2, 'Retail',
 N'{"customer_segment": "RETAIL", "account_age": ">= 6 months", "product_type": "CREDIT_CARD"}'),

-- Application Scorecard Models
(@APP_SCORE_TYPE_ID, 'ASCORE_RETAIL', N'Thẻ điểm đăng ký cho khách hàng cá nhân - không có dữ liệu tín dụng ngoài', '3.0', 'RISK_MODELS', 'dbo', 'ASCORE_RETAIL_RESULTS', 
 N'Risk Management/Model Development/Scorecards/ASCORE_RETAIL_v3.0_Documentation.pdf', '2024-01-15', '2026-01-15', 1, 1, 'Retail',
 N'{"customer_segment": "RETAIL", "account_age": "NEW", "product_type": "ALL", "has_bureau": false}'),

(@APP_SCORE_TYPE_ID, 'ASCORE_RETAIL_BUREAU', N'Thẻ điểm đăng ký cho khách hàng cá nhân - có dữ liệu tín dụng ngoài', '2.5', 'RISK_MODELS', 'dbo', 'ASCORE_RETAIL_BUREAU_RESULTS', 
 N'Risk Management/Model Development/Scorecards/ASCORE_RETAIL_BUREAU_v2.5_Documentation.pdf', '2024-02-20', '2026-02-20', 1, 1, 'Retail',
 N'{"customer_segment": "RETAIL", "account_age": "NEW", "product_type": "ALL", "has_bureau": true}'),

(@APP_SCORE_TYPE_ID, 'ASCORE_SME', N'Thẻ điểm đăng ký cho khách hàng doanh nghiệp vừa và nhỏ', '1.2', 'RISK_MODELS', 'dbo', 'ASCORE_SME_RESULTS', 
 N'Risk Management/Model Development/Scorecards/ASCORE_SME_v1.2_Documentation.pdf', '2024-04-15', '2026-04-15', 1, 1, 'SME',
 N'{"customer_segment": "SME", "account_age": "NEW", "company_size": "SMALL_MEDIUM"}'),

-- Early Warning Models
(@EARLY_WARN_TYPE_ID, 'EWS_RETAIL', N'Mô hình cảnh báo sớm cho khách hàng cá nhân', '1.0', 'RISK_MODELS', 'dbo', 'EWS_RETAIL_RESULTS', 
 N'Risk Management/Model Development/EWS Models/EWS_RETAIL_v1.0_Documentation.pdf', '2024-03-01', '2026-03-01', 1, 1, 'Retail',
 N'{"customer_segment": "RETAIL", "product_type": "ALL", "account_status": "ACTIVE"}'),

(@EARLY_WARN_TYPE_ID, 'EWS_SME', N'Mô hình cảnh báo sớm cho khách hàng doanh nghiệp vừa và nhỏ', '1.1', 'RISK_MODELS', 'dbo', 'EWS_SME_RESULTS', 
 N'Risk Management/Model Development/EWS Models/EWS_SME_v1.1_Documentation.pdf', '2024-05-01', '2026-05-01', 1, 1, 'SME',
 N'{"customer_segment": "SME", "product_type": "ALL", "account_status": "ACTIVE"}'),

-- Segmentation Models
(@SEGMENT_TYPE_ID, 'SEG_CUSTOMER_VALUE', N'Mô hình phân khúc khách hàng theo giá trị', '1.0', 'RISK_MODELS', 'dbo', 'SEGMENTATION_CUSTOMER_VALUE', 
 N'Risk Management/Model Development/Segmentation Models/SEG_CUSTOMER_VALUE_v1.0_Documentation.pdf', '2024-01-01', '2026-01-01', 1, 1, 'All',
 N'{"customer_type": "ALL"}'),

(@SEGMENT_TYPE_ID, 'SEG_BEHAVIOR_CLUSTERS', N'Mô hình phân cụm khách hàng theo hành vi', '1.2', 'RISK_MODELS', 'dbo', 'SEGMENTATION_BEHAVIOR_CLUSTERS', 
 N'Risk Management/Model Development/Segmentation Models/SEG_BEHAVIOR_CLUSTERS_v1.2_Documentation.pdf', '2024-02-01', '2026-02-01', 1, 2, 'Retail',
 N'{"customer_segment": "RETAIL", "account_age": ">= 12 months"}');
GO

PRINT 'Đã nhập dữ liệu mẫu cho bảng MODEL_REGISTRY thành công.';
GO