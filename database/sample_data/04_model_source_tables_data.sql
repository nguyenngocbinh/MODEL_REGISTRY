/*
Tên file: 04_model_source_tables_data.sql
Mô tả: Nhập dữ liệu mẫu cho bảng MODEL_SOURCE_TABLES
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.0
*/

-- Xóa dữ liệu cũ nếu cần
-- DELETE FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES;

-- Nhập dữ liệu vào bảng MODEL_SOURCE_TABLES
INSERT INTO MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES (
    SOURCE_DATABASE,
    SOURCE_SCHEMA,
    SOURCE_TABLE_NAME,
    TABLE_TYPE,
    TABLE_DESCRIPTION,
    DATA_OWNER,
    UPDATE_FREQUENCY,
    DATA_LATENCY,
    DATA_QUALITY_SCORE,
    KEY_COLUMNS,
    IS_ACTIVE
)
VALUES 
-- Customer Information Tables
('DATA_WAREHOUSE', 'dbo', 'DIM_CUSTOMER', 'INPUT', 
 N'Bảng thông tin khách hàng chứa dữ liệu nhân khẩu học và thông tin liên hệ', 
 N'Customer Data Management Team', 'DAILY', '1 DAY', 8, 
 '["CUSTOMER_ID"]', 1),

('DATA_WAREHOUSE', 'dbo', 'DIM_ACCOUNT', 'INPUT', 
 N'Bảng thông tin tài khoản chứa dữ liệu về các tài khoản và sản phẩm', 
 N'Account Management Team', 'DAILY', '1 DAY', 9, 
 '["ACCOUNT_ID", "CUSTOMER_ID"]', 1),

('DATA_WAREHOUSE', 'dbo', 'FACT_ACCOUNT_BALANCE', 'INPUT', 
 N'Bảng dữ liệu số dư tài khoản hàng ngày', 
 N'Finance Data Team', 'DAILY', '1 DAY', 9, 
 '["ACCOUNT_ID", "BALANCE_DATE"]', 1),

('DATA_WAREHOUSE', 'dbo', 'FACT_TRANSACTION', 'INPUT', 
 N'Bảng dữ liệu giao dịch chứa tất cả các giao dịch tài khoản', 
 N'Transaction Processing Team', 'DAILY', '1 DAY', 8, 
 '["TRANSACTION_ID", "ACCOUNT_ID", "TRANSACTION_DATE"]', 1),

-- Credit Bureau Data
('DATA_WAREHOUSE', 'dbo', 'FACT_CREDIT_BUREAU', 'INPUT', 
 N'Bảng dữ liệu tín dụng từ các cục thông tin tín dụng', 
 N'Credit Risk Analytics Team', 'MONTHLY', '5 DAYS', 7, 
 '["BUREAU_REPORT_ID", "CUSTOMER_ID", "REPORT_DATE"]', 1),

-- Financial Statement Data
('DATA_WAREHOUSE', 'dbo', 'FACT_FINANCIAL_STATEMENT', 'INPUT', 
 N'Bảng dữ liệu báo cáo tài chính của khách hàng doanh nghiệp', 
 N'Corporate Banking Team', 'QUARTERLY', '30 DAYS', 7, 
 '["STATEMENT_ID", "CUSTOMER_ID", "STATEMENT_DATE"]', 1),

-- Payment History
('DATA_WAREHOUSE', 'dbo', 'FACT_PAYMENT_HISTORY', 'INPUT', 
 N'Bảng dữ liệu lịch sử thanh toán khoản vay', 
 N'Collections Team', 'DAILY', '1 DAY', 9, 
 '["PAYMENT_ID", "ACCOUNT_ID", "PAYMENT_DATE"]', 1),

('DATA_WAREHOUSE', 'dbo', 'FACT_DELINQUENCY', 'INPUT', 
 N'Bảng dữ liệu thông tin nợ quá hạn', 
 N'Collections Team', 'DAILY', '1 DAY', 9, 
 '["ACCOUNT_ID", "DELINQUENCY_DATE"]', 1),

-- Feature Tables for Risk Models
('RISK_MODELS', 'dbo', 'PD_RETAIL_FEATURES', 'INPUT', 
 N'Bảng đặc trưng đầu vào cho mô hình PD Retail', 
 N'Risk Modeling Team', 'DAILY', '1 DAY', 9, 
 '["CUSTOMER_ID", "PROCESS_DATE"]', 1),

('RISK_MODELS', 'dbo', 'PD_SME_FEATURES', 'INPUT', 
 N'Bảng đặc trưng đầu vào cho mô hình PD SME', 
 N'Risk Modeling Team', 'DAILY', '1 DAY', 8, 
 '["CUSTOMER_ID", "PROCESS_DATE"]', 1),

('RISK_MODELS', 'dbo', 'BSCORE_RETAIL_FEATURES', 'INPUT', 
 N'Bảng đặc trưng đầu vào cho thẻ điểm hành vi khách hàng cá nhân', 
 N'Risk Modeling Team', 'DAILY', '1 DAY', 8, 
 '["CUSTOMER_ID", "ACCOUNT_ID", "PROCESS_DATE"]', 1),

('RISK_MODELS', 'dbo', 'ASCORE_RETAIL_FEATURES', 'INPUT', 
 N'Bảng đặc trưng đầu vào cho thẻ điểm đăng ký khách hàng cá nhân', 
 N'Risk Modeling Team', 'DAILY', '1 DAY', 8, 
 '["APPLICATION_ID", "CUSTOMER_ID", "PROCESS_DATE"]', 1),

('RISK_MODELS', 'dbo', 'EWS_RETAIL_FEATURES', 'INPUT', 
 N'Bảng đặc trưng đầu vào cho mô hình cảnh báo sớm khách hàng cá nhân', 
 N'Risk Monitoring Team', 'DAILY', '1 DAY', 8, 
 '["CUSTOMER_ID", "PROCESS_DATE"]', 1),

-- Model Output Tables
('RISK_MODELS', 'dbo', 'PD_RETAIL_RESULTS', 'OUTPUT', 
 N'Bảng kết quả mô hình PD Retail (xác suất vỡ nợ)', 
 N'Risk Modeling Team', 'DAILY', '1 DAY', 9, 
 '["CUSTOMER_ID", "PROCESS_DATE"]', 1),

('RISK_MODELS', 'dbo', 'PD_MORTGAGE_RESULTS', 'OUTPUT', 
 N'Bảng kết quả mô hình PD cho khách hàng vay thế chấp nhà', 
 N'Risk Modeling Team', 'DAILY', '1 DAY', 9, 
 '["CUSTOMER_ID", "PROCESS_DATE"]', 1),

('RISK_MODELS', 'dbo', 'PD_UNSECURED_RESULTS', 'OUTPUT', 
 N'Bảng kết quả mô hình PD cho khách hàng vay tín chấp', 
 N'Risk Modeling Team', 'DAILY', '1 DAY', 9, 
 '["CUSTOMER_ID", "PROCESS_DATE"]', 1),

('RISK_MODELS', 'dbo', 'PD_SME_RESULTS', 'OUTPUT', 
 N'Bảng kết quả mô hình PD SME (xác suất vỡ nợ)', 
 N'Risk Modeling Team', 'DAILY', '1 DAY', 9, 
 '["CUSTOMER_ID", "PROCESS_DATE"]', 1),

('RISK_MODELS', 'dbo', 'PD_CORPORATE_RESULTS', 'OUTPUT', 
 N'Bảng kết quả mô hình PD Corporate (xác suất vỡ nợ)', 
 N'Risk Modeling Team', 'DAILY', '1 DAY', 9, 
 '["CUSTOMER_ID", "PROCESS_DATE"]', 1),

('RISK_MODELS', 'dbo', 'LGD_RETAIL_RESULTS', 'OUTPUT', 
 N'Bảng kết quả mô hình LGD Retail (tỷ lệ tổn thất khi vỡ nợ)', 
 N'Risk Modeling Team', 'DAILY', '1 DAY', 9, 
 '["CUSTOMER_ID", "PROCESS_DATE"]', 1),

('RISK_MODELS', 'dbo', 'LGD_SME_RESULTS', 'OUTPUT', 
 N'Bảng kết quả mô hình LGD SME (tỷ lệ tổn thất khi vỡ nợ)', 
 N'Risk Modeling Team', 'DAILY', '1 DAY', 9, 
 '["CUSTOMER_ID", "PROCESS_DATE"]', 1),

('RISK_MODELS', 'dbo', 'BSCORE_RETAIL_RESULTS', 'OUTPUT', 
 N'Bảng kết quả thẻ điểm hành vi khách hàng cá nhân', 
 N'Risk Modeling Team', 'DAILY', '1 DAY', 9, 
 '["CUSTOMER_ID", "PROCESS_DATE"]', 1),

('RISK_MODELS', 'dbo', 'BSCORE_CARDS_RESULTS', 'OUTPUT', 
 N'Bảng kết quả thẻ điểm hành vi khách hàng thẻ tín dụng', 
 N'Risk Modeling Team', 'DAILY', '1 DAY', 9, 
 '["CUSTOMER_ID", "PROCESS_DATE"]', 1),

('RISK_MODELS', 'dbo', 'ASCORE_RETAIL_RESULTS', 'OUTPUT', 
 N'Bảng kết quả thẻ điểm đăng ký khách hàng cá nhân', 
 N'Risk Modeling Team', 'DAILY', '1 DAY', 9, 
 '["APPLICATION_ID", "CUSTOMER_ID", "PROCESS_DATE"]', 1),

('RISK_MODELS', 'dbo', 'ASCORE_RETAIL_BUREAU_RESULTS', 'OUTPUT', 
 N'Bảng kết quả thẻ điểm đăng ký khách hàng cá nhân có dữ liệu tín dụng ngoài', 
 N'Risk Modeling Team', 'DAILY', '1 DAY', 9, 
 '["APPLICATION_ID", "CUSTOMER_ID", "PROCESS_DATE"]', 1),

('RISK_MODELS', 'dbo', 'ASCORE_SME_RESULTS', 'OUTPUT', 
 N'Bảng kết quả thẻ điểm đăng ký khách hàng doanh nghiệp vừa và nhỏ', 
 N'Risk Modeling Team', 'DAILY', '1 DAY', 9, 
 '["APPLICATION_ID", "CUSTOMER_ID", "PROCESS_DATE"]', 1),

('RISK_MODELS', 'dbo', 'EWS_RETAIL_RESULTS', 'OUTPUT', 
 N'Bảng kết quả mô hình cảnh báo sớm khách hàng cá nhân', 
 N'Risk Monitoring Team', 'DAILY', '1 DAY', 9, 
 '["CUSTOMER_ID", "PROCESS_DATE"]', 1),

('RISK_MODELS', 'dbo', 'EWS_SME_RESULTS', 'OUTPUT', 
 N'Bảng kết quả mô hình cảnh báo sớm khách hàng doanh nghiệp vừa và nhỏ', 
 N'Risk Monitoring Team', 'DAILY', '1 DAY', 9, 
 '["CUSTOMER_ID", "PROCESS_DATE"]', 1),

('RISK_MODELS', 'dbo', 'SEGMENTATION_CUSTOMER_VALUE', 'OUTPUT', 
 N'Bảng kết quả phân khúc khách hàng theo giá trị', 
 N'Customer Analytics Team', 'MONTHLY', '1 DAY', 8, 
 '["CUSTOMER_ID", "PROCESS_DATE"]', 1),

('RISK_MODELS', 'dbo', 'SEGMENTATION_BEHAVIOR_CLUSTERS', 'OUTPUT', 
 N'Bảng kết quả phân cụm khách hàng theo hành vi', 
 N'Customer Analytics Team', 'MONTHLY', '1 DAY', 8, 
 '["CUSTOMER_ID", "PROCESS_DATE"]', 1),

-- Reference Tables
('DATA_WAREHOUSE', 'dbo', 'DIM_PRODUCT', 'REFERENCE', 
 N'Bảng thông tin sản phẩm chứa danh mục sản phẩm', 
 N'Product Management Team', 'MONTHLY', '1 DAY', 10, 
 '["PRODUCT_ID"]', 1),

('DATA_WAREHOUSE', 'dbo', 'DIM_INDUSTRY', 'REFERENCE', 
 N'Bảng thông tin ngành nghề chứa danh mục và phân loại ngành nghề kinh doanh', 
 N'Data Governance Team', 'YEARLY', '1 DAY', 10, 
 '["INDUSTRY_ID"]', 1),

('DATA_WAREHOUSE', 'dbo', 'DIM_GEOGRAPHY', 'REFERENCE', 
 N'Bảng thông tin địa lý chứa danh mục vùng miền và địa chỉ', 
 N'Data Governance Team', 'QUARTERLY', '1 DAY', 10, 
 '["GEOGRAPHY_ID"]', 1),

('RISK_MODELS', 'dbo', 'REF_RISK_GRADE', 'REFERENCE', 
 N'Bảng tham chiếu cấp độ rủi ro và định nghĩa', 
 N'Risk Policy Team', 'YEARLY', '1 DAY', 10, 
 '["RISK_GRADE_ID"]', 1),

('RISK_MODELS', 'dbo', 'REF_MODEL_PARAMETERS', 'REFERENCE', 
 N'Bảng tham chiếu tham số mô hình', 
 N'Risk Modeling Team', 'AS NEEDED', '1 DAY', 10, 
 '["PARAMETER_ID"]', 1);
GO

PRINT N'Đã nhập dữ liệu mẫu cho bảng MODEL_SOURCE_TABLES thành công.';
GO