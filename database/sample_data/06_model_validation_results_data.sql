/*
Tên file: 06_model_validation_results_data.sql
Mô tả: Nhập dữ liệu mẫu cho bảng MODEL_VALIDATION_RESULTS
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.0
*/

-- Xóa dữ liệu cũ nếu cần
-- DELETE FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS;

-- Lấy các MODEL_ID để tham chiếu
DECLARE @PD_RETAIL_ID INT;
DECLARE @PD_MORTGAGE_ID INT;
DECLARE @PD_UNSECURED_ID INT;
DECLARE @PD_SME_ID INT;
DECLARE @ASCORE_RETAIL_ID INT;
DECLARE @ASCORE_RETAIL_BUREAU_ID INT;

SELECT @PD_RETAIL_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'PD_RETAIL';
SELECT @PD_MORTGAGE_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'PD_RETAIL_MORTGAGE';
SELECT @PD_UNSECURED_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'PD_RETAIL_UNSECURED';
SELECT @PD_SME_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'PD_SME';
SELECT @ASCORE_RETAIL_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'ASCORE_RETAIL';
SELECT @ASCORE_RETAIL_BUREAU_ID = MODEL_ID FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_NAME = 'ASCORE_RETAIL_BUREAU';

-- Nhập dữ liệu vào bảng MODEL_VALIDATION_RESULTS
INSERT INTO MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS (
    MODEL_ID,
    VALIDATION_DATE,
    VALIDATION_TYPE,
    VALIDATION_PERIOD,
    DATA_SAMPLE_SIZE,
    DATA_SAMPLE_DESCRIPTION,
    MODEL_SUBTYPE,
    KS_STATISTIC,
    GINI,
    ACCURACY,
    PRECISION,
    RECALL,
    F1_SCORE,
    IV,
    KAPPA,
    PSI,
    CSI,
    DETAILED_METRICS,
    CONFUSION_MATRIX,
    VALIDATION_COMMENTS,
    VALIDATION_STATUS,
    VALIDATED_BY
)
VALUES 

-- PD Retail validation results
(@PD_RETAIL_ID, '2024-01-01', 'DEVELOPMENT', 'JAN2023-DEC2023', 500000, 
 N'Mẫu phát triển, bao gồm tất cả khách hàng cá nhân có ít nhất 12 tháng lịch sử', 
 NULL, 0.45, 0.52, 0.82, 0.75, 0.68, 0.71, 0.35, 0.62, NULL, NULL,
 N'{"by_segment": {"Mass": {"GINI": 0.48, "KS": 0.42}, "Affluent": {"GINI": 0.55, "KS": 0.47}, "Premier": {"GINI": 0.58, "KS": 0.51}}}',
 N'{"TP": 2500, "TN": 3000, "FP": 800, "FN": 1200}',
 N'Mô hình hoạt động tốt trên tất cả các phân khúc. Khả năng phân biệt cao nhất ở nhóm khách hàng Premier.',
 'APPROVED', N'Nguyễn Văn A'),

(@PD_RETAIL_ID, '2024-04-01', 'OUT_OF_TIME', 'JAN2024-MAR2024', 120000, 
 N'Đánh giá out-of-time trên dữ liệu Q1/2024', 
 NULL, 0.43, 0.50, 0.81, 0.73, 0.67, 0.70, 0.33, 0.60, 0.08, 0.12,
 N'{"by_segment": {"Mass": {"GINI": 0.46, "KS": 0.40}, "Affluent": {"GINI": 0.53, "KS": 0.45}, "Premier": {"GINI": 0.57, "KS": 0.49}}}',
 N'{"TP": 600, "TN": 750, "FP": 220, "FN": 300}',
 N'Hiệu suất nhìn chung ổn định so với mô hình ban đầu. Chỉ số PSI = 0.08 cho thấy phân phối khá ổn định.',
 'APPROVED', N'Nguyễn Văn A'),

-- ASCORE Retail validation results
(@ASCORE_RETAIL_ID, '2024-01-15', 'DEVELOPMENT', 'JAN2023-DEC2023', 200000, 
 N'Mẫu phát triển, bao gồm tất cả hồ sơ đăng ký mới', 
 'Retail AScore (without Bureau)', 0.35, 0.42, 0.75, 0.65, 0.62, 0.63, 0.28, 0.55, NULL, NULL,
 N'{"by_segment": {"Mass": {"GINI": 0.40, "KS": 0.34}, "Affluent": {"GINI": 0.43, "KS": 0.36}}}',
 N'{"TP": 1500, "TN": 1800, "FP": 750, "FN": 950}',
 N'Khả năng phân biệt thấp hơn so với các mô hình behavior do thiếu thông tin hành vi, nhưng vẫn ở mức chấp nhận được cho mô hình application không có dữ liệu tín dụng ngoài.',
 'APPROVED', N'Lê Văn C'),

(@ASCORE_RETAIL_ID, '2024-04-15', 'OUT_OF_TIME', 'JAN2024-MAR2024', 45000, 
 N'Đánh giá out-of-time trên dữ liệu Q1/2024', 
 'Retail AScore (without Bureau)', 0.34, 0.40, 0.74, 0.64, 0.60, 0.62, 0.26, 0.54, 0.11, 0.15,
 N'{"by_segment": {"Mass": {"GINI": 0.38, "KS": 0.32}, "Affluent": {"GINI": 0.41, "KS": 0.35}}}',
 N'{"TP": 350, "TN": 420, "FP": 180, "FN": 250}',
 N'Hiệu suất giảm nhẹ so với mô hình ban đầu. Chỉ số PSI = 0.11 cho thấy có sự thay đổi nhỏ trong phân phối. Cần theo dõi thêm.',
 'APPROVED', N'Lê Văn C'),

-- ASCORE Retail Bureau validation results
(@ASCORE_RETAIL_BUREAU_ID, '2024-02-20', 'DEVELOPMENT', 'JAN2023-DEC2023', 150000, 
 N'Mẫu phát triển, bao gồm tất cả hồ sơ đăng ký mới có dữ liệu tín dụng ngoài', 
 'Retail AScore (with Bureau)', 0.55, 0.68, 0.88, 0.82, 0.75, 0.78, 0.52, 0.70, NULL, NULL,
 N'{"by_segment": {"Mass": {"GINI": 0.65, "KS": 0.52}, "Affluent": {"GINI": 0.70, "KS": 0.57}}}',
 N'{"TP": 1300, "TN": 1500, "FP": 280, "FN": 420}',
 N'Mô hình có khả năng phân biệt cao nhờ tích hợp dữ liệu tín dụng ngoài, cải thiện đáng kể so với mô hình không có dữ liệu tín dụng ngoài.',
 'APPROVED', N'Đỗ Thị D'),

(@ASCORE_RETAIL_BUREAU_ID, '2024-04-20', 'OUT_OF_TIME', 'JAN2024-MAR2024', 38000, 
 N'Đánh giá out-of-time trên dữ liệu Q1/2024', 
 'Retail AScore (with Bureau)', 0.53, 0.65, 0.86, 0.80, 0.73, 0.76, 0.50, 0.68, 0.07, 0.10,
 N'{"by_segment": {"Mass": {"GINI": 0.62, "KS": 0.50}, "Affluent": {"GINI": 0.67, "KS": 0.55}}}',
 N'{"TP": 320, "TN": 380, "FP": 75, "FN": 125}',
 N'Hiệu suất nhìn chung ổn định so với mô hình ban đầu. Chỉ số PSI = 0.07 cho thấy phân phối khá ổn định.',
 'APPROVED', N'Đỗ Thị D'),

-- PD SME validation results
(@PD_SME_ID, '2024-04-01', 'DEVELOPMENT', 'JAN2022-DEC2023', 80000, 
 N'Mẫu phát triển, bao gồm tất cả khách hàng SME có ít nhất 24 tháng lịch sử', 
 'Wholesale Scorecard', 0.52, 0.64, 0.86, 0.79, 0.73, 0.76, 0.45, 0.72, NULL, NULL,
 N'{"by_segment": {"Micro": {"GINI": 0.60, "KS": 0.48}, "Small": {"GINI": 0.65, "KS": 0.52}, "Medium": {"GINI": 0.68, "KS": 0.55}}}',
 N'{"TP": 500, "TN": 650, "FP": 130, "FN": 220}',
 N'Mô hình hoạt động tốt trên tất cả các phân khúc doanh nghiệp. Khả năng phân biệt cao nhất ở nhóm doanh nghiệp vừa.',
 'APPROVED', N'Phạm Văn E')
;
GO

PRINT N'Đã nhập dữ liệu mẫu cho bảng MODEL_VALIDATION_RESULTS thành công.';
GO