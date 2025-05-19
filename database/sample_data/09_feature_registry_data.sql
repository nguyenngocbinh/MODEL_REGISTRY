/*
Tên file: 09_feature_registry_data.sql
Mô tả: Nhập dữ liệu mẫu cho bảng FEATURE_REGISTRY
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-17
Phiên bản: 1.0
*/

-- Xóa dữ liệu cũ nếu cần
-- DELETE FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY;

-- Nhập dữ liệu vào bảng FEATURE_REGISTRY
INSERT INTO MODEL_REGISTRY.dbo.FEATURE_REGISTRY (
    FEATURE_NAME,
    FEATURE_CODE,
    FEATURE_DESCRIPTION,
    DATA_TYPE,
    VALUE_TYPE,
    SOURCE_SYSTEM,
    BUSINESS_CATEGORY,
    DOMAIN_KNOWLEDGE,
    IS_PII,
    IS_SENSITIVE,
    DEFAULT_VALUE,
    VALID_MIN_VALUE,
    VALID_MAX_VALUE,
    VALID_VALUES,
    BUSINESS_OWNER,
    UPDATE_FREQUENCY
)
VALUES 
-- Đặc trưng nhân khẩu học
('Customer Age', 'CUST_AGE', N'Tuổi của khách hàng tại thời điểm tính toán', 
 'NUMERIC', 'CONTINUOUS', 'CORE_BANKING', 'DEMOGRAPHIC', 
 N'Tuổi là một yếu tố quan trọng trong đánh giá rủi ro. Thông thường, khách hàng trung niên (35-55) có xu hướng ổn định hơn về mặt tài chính.', 
 0, 0, NULL, '18', '100', NULL, 
 N'Customer Data Management Team', 'MONTHLY'),

('Gender', 'GENDER', N'Giới tính của khách hàng', 
 'CATEGORICAL', 'NOMINAL', 'CORE_BANKING', 'DEMOGRAPHIC', 
 N'Giới tính có thể có ảnh hưởng đến các mẫu hành vi tài chính và rủi ro. Tác động thực tế phụ thuộc vào từng thị trường và phân khúc khách hàng.', 
 1, 0, 'UNKNOWN', NULL, NULL, N'["MALE", "FEMALE", "OTHER", "UNKNOWN"]', 
 N'Customer Data Management Team', 'STATIC'),

('Customer Income', 'INCOME', N'Thu nhập hàng tháng của khách hàng (VND)', 
 'NUMERIC', 'CONTINUOUS', 'CORE_BANKING', 'FINANCIAL', 
 N'Thu nhập là yếu tố chính trong đánh giá khả năng trả nợ. Quan trọng để tính tỷ lệ nợ trên thu nhập (DTI) và khả năng thanh toán.', 
 0, 1, '0', '0', '1000000000', NULL, 
 N'Risk Analytics Team', 'QUARTERLY'),

('Income Category', 'INCOME_CAT', N'Phân loại thu nhập của khách hàng', 
 'CATEGORICAL', 'ORDINAL', 'DATA_WAREHOUSE', 'FINANCIAL', 
 N'Phân loại thu nhập giúp phân đoạn khách hàng vào các nhóm có mức thu nhập tương tự để áp dụng các chiến lược phù hợp.', 
 0, 1, 'MEDIUM', NULL, NULL, N'["LOW", "MEDIUM", "HIGH", "VERY_HIGH"]', 
 N'Risk Analytics Team', 'QUARTERLY'),

('Occupation', 'OCCUP', N'Nghề nghiệp hoặc lĩnh vực làm việc của khách hàng', 
 'CATEGORICAL', 'NOMINAL', 'CORE_BANKING', 'DEMOGRAPHIC', 
 N'Nghề nghiệp ảnh hưởng đến độ ổn định thu nhập và khả năng tìm kiếm việc làm mới. Một số ngành (như y tế, giáo dục) thường có việc làm ổn định hơn.', 
 0, 0, 'UNKNOWN', NULL, NULL, N'["PROFESSIONAL", "MANAGER", "TECHNICIAN", "CLERICAL", "SERVICE", "AGRICULTURE", "PRODUCTION", "MILITARY", "UNEMPLOYED", "RETIRED", "STUDENT", "HOMEMAKER", "SELF_EMPLOYED", "OTHER", "UNKNOWN"]', 
 N'Customer Data Management Team', 'QUARTERLY'),

('Employment Status', 'EMP_STATUS', N'Tình trạng việc làm hiện tại của khách hàng', 
 'CATEGORICAL', 'NOMINAL', 'CORE_BANKING', 'DEMOGRAPHIC', 
 N'Tình trạng việc làm ảnh hưởng đến độ ổn định tài chính. Khách hàng có việc làm toàn thời gian thường được đánh giá ít rủi ro hơn.', 
 0, 0, 'UNKNOWN', NULL, NULL, N'["EMPLOYED", "SELF_EMPLOYED", "UNEMPLOYED", "RETIRED", "STUDENT", "UNKNOWN"]', 
 N'Customer Data Management Team', 'MONTHLY'),

('Residence Status', 'RES_STATUS', N'Tình trạng sở hữu nơi ở của khách hàng', 
 'CATEGORICAL', 'NOMINAL', 'CORE_BANKING', 'DEMOGRAPHIC', 
 N'Tình trạng sở hữu nhà ở là một chỉ báo về sự ổn định. Khách hàng sở hữu nhà thường được coi là ổn định hơn những người thuê nhà.', 
 0, 0, 'UNKNOWN', NULL, NULL, N'["OWNED", "MORTGAGED", "RENTED", "LIVING_WITH_PARENTS", "OTHER", "UNKNOWN"]', 
 N'Customer Data Management Team', 'QUARTERLY'),

('Customer Tenure', 'CUST_TENURE', N'Thời gian khách hàng quan hệ với ngân hàng (tháng)', 
 'NUMERIC', 'DISCRETE', 'CORE_BANKING', 'RELATIONSHIP', 
 N'Thời gian quan hệ với ngân hàng là chỉ báo về sự trung thành và ổn định. Quan hệ lâu dài thường đi kèm với nhận thức tốt hơn về rủi ro của khách hàng.', 
 0, 0, '0', '0', '600', NULL, 
 N'Customer Experience Team', 'MONTHLY'),

('Customer Segment', 'CUST_SEGMENT', N'Phân khúc khách hàng theo chính sách của ngân hàng', 
 'CATEGORICAL', 'ORDINAL', 'CORE_BANKING', 'RELATIONSHIP', 
 N'Phân khúc khách hàng dựa trên giá trị, mức độ tương tác và các thuộc tính khác để phục vụ chiến lược phân biệt.', 
 0, 0, 'MASS', NULL, NULL, N'["MASS", "AFFLUENT", "PREMIER", "PRIVATE_BANKING"]', 
 N'Customer Experience Team', 'MONTHLY'),

-- Đặc trưng tài khoản
('Account Age', 'ACC_AGE', N'Tuổi tài khoản tính theo tháng', 
 'NUMERIC', 'DISCRETE', 'CORE_BANKING', 'ACCOUNT', 
 N'Tuổi tài khoản chỉ ra thời gian hoạt động của sản phẩm. Các tài khoản mới thường có rủi ro cao hơn (hiệu ứng "seasoning").', 
 0, 0, '0', '0', '600', NULL, 
 N'Account Management Team', 'MONTHLY'),

('Product Type', 'PROD_TYPE', N'Loại sản phẩm tài chính của tài khoản', 
 'CATEGORICAL', 'NOMINAL', 'CORE_BANKING', 'ACCOUNT', 
 N'Loại sản phẩm có các đặc điểm rủi ro khác nhau. Thẻ tín dụng thường có rủi ro cao hơn các khoản vay thế chấp.', 
 0, 0, NULL, NULL, NULL, N'["MORTGAGE", "CREDIT_CARD", "PERSONAL_LOAN", "AUTO_LOAN", "SECURED_LOAN", "UNSECURED_LOAN", "SAVINGS", "CHECKING", "TERM_DEPOSIT"]', 
 N'Product Management Team', 'STATIC'),

('Credit Limit', 'CREDIT_LIMIT', N'Hạn mức tín dụng được cấp (VND)', 
 'NUMERIC', 'CONTINUOUS', 'CORE_BANKING', 'ACCOUNT', 
 N'Hạn mức tín dụng thể hiện mức độ rủi ro mà ngân hàng sẵn sàng chấp nhận. Thường được thiết lập dựa trên đánh giá tín dụng ban đầu.', 
 0, 0, '0', '0', '1000000000', NULL, 
 N'Credit Risk Management Team', 'MONTHLY'),

('Interest Rate', 'INT_RATE', N'Lãi suất áp dụng cho tài khoản (%)', 
 'NUMERIC', 'CONTINUOUS', 'CORE_BANKING', 'ACCOUNT', 
 N'Lãi suất thường phản ánh mức độ rủi ro được đánh giá, với lãi suất cao hơn đối với khách hàng rủi ro cao hơn.', 
 0, 0, '0', '0', '50', NULL, 
 N'Product Management Team', 'MONTHLY'),

('Loan Term', 'LOAN_TERM', N'Kỳ hạn của khoản vay (tháng)', 
 'NUMERIC', 'DISCRETE', 'CORE_BANKING', 'ACCOUNT', 
 N'Kỳ hạn khoản vay ảnh hưởng đến chi phí hàng tháng và tổng chi phí lãi. Kỳ hạn dài hơn thường có rủi ro cao hơn.', 
 0, 0, '0', '1', '360', NULL, 
 N'Credit Products Team', 'STATIC'),

-- Đặc trưng thanh toán và hành vi
('Current Balance', 'CUR_BAL', N'Số dư hiện tại của tài khoản (VND)', 
 'NUMERIC', 'CONTINUOUS', 'CORE_BANKING', 'BALANCE', 
 N'Số dư hiện tại là thước đo quan trọng về mức độ vay nợ và nghĩa vụ tài chính của khách hàng tại một thời điểm.', 
 0, 0, '0', '-1000000000', '10000000000', NULL, 
 N'Finance Data Team', 'DAILY'),

('Utilization Ratio', 'UTIL_RATIO', N'Tỷ lệ sử dụng hạn mức tín dụng (%)', 
 'NUMERIC', 'CONTINUOUS', 'DATA_WAREHOUSE', 'BEHAVIORAL', 
 N'Tỷ lệ sử dụng hạn mức là một chỉ báo quan trọng về hành vi tín dụng và mức độ phụ thuộc vào tín dụng của khách hàng. Tỷ lệ cao (>70%) thường liên quan đến rủi ro cao hơn.', 
 0, 0, '0', '0', '1', NULL, 
 N'Risk Analytics Team', 'DAILY'),

('Days Past Due', 'DPD', N'Số ngày quá hạn hiện tại', 
 'NUMERIC', 'DISCRETE', 'COLLECTION_SYSTEM', 'DELINQUENCY', 
 N'DPD là thước đo trực tiếp về hành vi thanh toán, với số ngày cao hơn chỉ ra nguy cơ vỡ nợ lớn hơn.', 
 0, 0, '0', '0', '180', NULL, 
 N'Collections Team', 'DAILY'),

('DPD 30+ Last 12M', 'DPD_30_L12M', N'Số lần quá hạn trên 30 ngày trong 12 tháng qua', 
 'NUMERIC', 'DISCRETE', 'DATA_WAREHOUSE', 'DELINQUENCY', 
 N'Tần suất quá hạn là một chỉ báo mạnh mẽ về hành vi thanh toán và khả năng vỡ nợ trong tương lai.', 
 0, 0, '0', '0', '12', NULL, 
 N'Risk Analytics Team', 'MONTHLY'),

('Maximum DPD Last 12M', 'MAX_DPD_L12M', N'Số ngày quá hạn tối đa trong 12 tháng qua', 
 'NUMERIC', 'DISCRETE', 'DATA_WAREHOUSE', 'DELINQUENCY', 
 N'Mức độ quá hạn tối đa trong quá khứ là chỉ báo về mức độ nghiêm trọng của hành vi trễ hạn.', 
 0, 0, '0', '0', '180', NULL, 
 N'Risk Analytics Team', 'MONTHLY'),

('Payment Ratio', 'PMT_RATIO', N'Tỷ lệ thanh toán trên dư nợ (%)', 
 'NUMERIC', 'CONTINUOUS', 'DATA_WAREHOUSE', 'BEHAVIORAL', 
 N'Tỷ lệ thanh toán chỉ ra mức độ khách hàng đang giảm dư nợ so với chỉ trả lãi hoặc số tiền tối thiểu.', 
 0, 0, '0', '0', '1', NULL, 
 N'Risk Analytics Team', 'MONTHLY'),

('Average Balance Last 3M', 'AVG_BAL_L3M', N'Số dư tài khoản trung bình trong 3 tháng gần nhất (VND)', 
 'NUMERIC', 'CONTINUOUS', 'DATA_WAREHOUSE', 'BALANCE', 
 N'Số dư trung bình gần đây cung cấp thông tin về hành vi gần đây và các xu hướng sử dụng tài khoản.', 
 0, 0, '0', '-1000000000', '10000000000', NULL, 
 N'Finance Data Team', 'MONTHLY'),

('Balance Growth Rate', 'BAL_GROWTH', N'Tỷ lệ tăng trưởng dư nợ trong 6 tháng qua (%)', 
 'NUMERIC', 'CONTINUOUS', 'DATA_WAREHOUSE', 'BEHAVIORAL', 
 N'Tốc độ tăng trưởng dư nợ là chỉ báo về hành vi vay nợ. Tăng trưởng nhanh có thể chỉ ra rủi ro chồng chất nợ.', 
 0, 0, '0', '-1', '10', NULL, 
 N'Risk Analytics Team', 'MONTHLY'),

-- Đặc trưng cục thông tin tín dụng
('Bureau Score', 'BUREAU_SCORE', N'Điểm tín dụng từ cục thông tin tín dụng', 
 'NUMERIC', 'DISCRETE', 'CREDIT_BUREAU', 'BUREAU', 
 N'Điểm tín dụng bên ngoài cung cấp đánh giá khách quan về hồ sơ tín dụng của khách hàng trên toàn thị trường.', 
 0, 0, NULL, '300', '900', NULL, 
 N'Credit Bureau Team', 'MONTHLY'),

('Credit Utilization External', 'CREDIT_UTIL_EXT', N'Tỷ lệ sử dụng tín dụng tổng thể trên tất cả các tổ chức tín dụng (%)', 
 'NUMERIC', 'CONTINUOUS', 'CREDIT_BUREAU', 'BUREAU', 
 N'Tỷ lệ sử dụng tín dụng bên ngoài cho thấy mức độ khách hàng đang sử dụng tín dụng có sẵn tại các tổ chức khác.', 
 0, 0, NULL, '0', '1', NULL, 
 N'Credit Bureau Team', 'MONTHLY'),

('Inquiries Last 6M', 'INQ_L6M', N'Số lần truy vấn thông tin tín dụng trong 6 tháng qua', 
 'NUMERIC', 'DISCRETE', 'CREDIT_BUREAU', 'BUREAU', 
 N'Số lượng truy vấn gần đây có thể chỉ ra khách hàng đang tìm kiếm tín dụng tích cực, có thể là dấu hiệu khó khăn tài chính.', 
 0, 0, '0', '0', '50', NULL, 
 N'Credit Bureau Team', 'MONTHLY'),

('Delinquencies Last 24M External', 'DLQ_L24M_EXT', N'Số lần quá hạn ghi nhận tại cục thông tin tín dụng trong 24 tháng qua', 
 'NUMERIC', 'DISCRETE', 'CREDIT_BUREAU', 'BUREAU', 
 N'Lịch sử quá hạn rộng hơn trên toàn thị trường, bao gồm các nợ tại các tổ chức khác.', 
 0, 0, '0', '0', '24', NULL, 
 N'Credit Bureau Team', 'MONTHLY'),

('Credit History Length', 'CREDIT_HIST_LEN', N'Độ dài lịch sử tín dụng tính theo tháng', 
 'NUMERIC', 'DISCRETE', 'CREDIT_BUREAU', 'BUREAU', 
 N'Lịch sử tín dụng dài hơn thường chỉ ra hồ sơ tín dụng thành thục hơn và ít rủi ro hơn.', 
 0, 0, '0', '0', '600', NULL, 
 N'Credit Bureau Team', 'MONTHLY'),

('Total Defaults', 'TOTAL_DEFAULTS', N'Tổng số lần vỡ nợ trong lịch sử tín dụng', 
 'NUMERIC', 'DISCRETE', 'CREDIT_BUREAU', 'BUREAU', 
 N'Lịch sử vỡ nợ là một trong những chỉ báo mạnh nhất về rủi ro vỡ nợ trong tương lai.', 
 0, 0, '0', '0', '10', NULL, 
 N'Credit Bureau Team', 'MONTHLY'),

-- Đặc trưng tổng hợp và dẫn xuất
('Debt to Income Ratio', 'DTI', N'Tỷ lệ tổng dư nợ trên thu nhập hàng tháng (%)', 
 'NUMERIC', 'CONTINUOUS', 'DATA_WAREHOUSE', 'FINANCIAL', 
 N'DTI là thước đo quan trọng về khả năng trả nợ, đo lường nghĩa vụ nợ so với thu nhập. Tỷ lệ cao hơn chỉ ra gánh nặng nợ lớn hơn.', 
 0, 0, NULL, '0', '10', NULL, 
 N'Risk Analytics Team', 'MONTHLY'),

('Probability of Default', 'PD', N'Xác suất vỡ nợ trong 12 tháng tới', 
 'NUMERIC', 'CONTINUOUS', 'RISK_MODELS', 'RISK_METRIC', 
 N'PD là ước lượng thống kê về khả năng khách hàng sẽ vỡ nợ trong 12 tháng tới, dựa trên mô hình PD được phát triển nội bộ.', 
 0, 1, NULL, '0', '1', NULL, 
 N'Risk Modeling Team', 'MONTHLY'),

('Risk Grade', 'RISK_GRADE', N'Cấp độ rủi ro dựa trên xác suất vỡ nợ', 
 'CATEGORICAL', 'ORDINAL', 'RISK_MODELS', 'RISK_METRIC', 
 N'Risk Grade là cách ánh xạ PD thành các loại rủi ro được hiểu rộng rãi để hỗ trợ ra quyết định.', 
 0, 1, 'B', NULL, NULL, N'["AAA", "AA", "A", "BBB", "BB", "B", "CCC", "CC", "C"]', 
 N'Risk Modeling Team', 'MONTHLY'),

('Behavior Score', 'BEH_SCORE', N'Điểm đánh giá hành vi tổng hợp', 
 'NUMERIC', 'DISCRETE', 'RISK_MODELS', 'RISK_METRIC', 
 N'Behavior Score là điểm tổng hợp dựa trên nhiều đặc trưng hành vi, cao hơn chỉ ra rủi ro thấp hơn.', 
 0, 0, NULL, '300', '900', NULL, 
 N'Risk Modeling Team', 'MONTHLY'),

('Risk Category', 'RISK_CAT', N'Phân loại mức độ rủi ro', 
 'CATEGORICAL', 'ORDINAL', 'RISK_MODELS', 'RISK_METRIC', 
 N'Risk Category là phân loại rủi ro tổng thể dựa trên nhiều chỉ số rủi ro, được sử dụng cho ra quyết định kinh doanh.', 
 0, 0, 'MEDIUM_RISK', NULL, NULL, N'["LOW_RISK", "MEDIUM_RISK", "HIGH_RISK", "VERY_HIGH_RISK"]', 
 N'Risk Modeling Team', 'MONTHLY'),

-- Đặc trưng sản phẩm nâng cao
('Loan to Value Ratio', 'LTV', N'Tỷ lệ khoản vay trên giá trị tài sản (%)', 
 'NUMERIC', 'CONTINUOUS', 'DATA_WAREHOUSE', 'FINANCIAL', 
 N'LTV quan trọng cho các khoản vay thế chấp, đo lường giá trị khoản vay so với giá trị tài sản thế chấp. Tỷ lệ cao hơn chỉ ra rủi ro cao hơn nếu giá trị tài sản giảm.', 
 0, 0, '0.8', '0', '1.5', NULL, 
 N'Mortgage Team', 'QUARTERLY'),

('Cash Advance Ratio', 'CASH_ADV_RATIO', N'Tỷ lệ rút tiền mặt trên hạn mức tín dụng (%)', 
 'NUMERIC', 'CONTINUOUS', 'DATA_WAREHOUSE', 'BEHAVIORAL', 
 N'Tỷ lệ rút tiền mặt cao trên thẻ tín dụng thường là dấu hiệu của khó khăn tài chính và rủi ro cao hơn.', 
 0, 0, '0', '0', '1', NULL, 
 N'Credit Card Team', 'MONTHLY'),

('Number of Products', 'NUM_PRODUCTS', N'Số lượng sản phẩm tài chính khách hàng đang sử dụng', 
 'NUMERIC', 'DISCRETE', 'DATA_WAREHOUSE', 'RELATIONSHIP', 
 N'Số lượng sản phẩm chỉ ra mức độ quan hệ với ngân hàng. Nhiều sản phẩm thường chỉ ra quan hệ sâu hơn và khách hàng ít rủi ro hơn.', 
 0, 0, '1', '0', '20', NULL, 
 N'Customer Analytics Team', 'MONTHLY'),

('Months on Book', 'MOB', N'Số tháng kể từ khi mở tài khoản/sản phẩm hiện tại', 
 'NUMERIC', 'DISCRETE', 'CORE_BANKING', 'ACCOUNT', 
 N'MOB là thước đo về thời gian tài khoản đã hoạt động, liên quan đến hiệu ứng "seasoning" trong rủi ro tín dụng.', 
 0, 0, '0', '0', '600', NULL, 
 N'Account Management Team', 'MONTHLY');
GO

PRINT N'Đã nhập dữ liệu mẫu cho bảng FEATURE_REGISTRY thành công.';
GO