/*
Tên file: 00_feature_registry_prereq_data.sql
Mô tả: Nhập dữ liệu tiên quyết cho bảng FEATURE_REGISTRY trước khi chạy các script khác
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-19
Phiên bản: 1.2 - Sửa lỗi tham chiếu "inserted" và tách các lệnh INSERT
*/

-- Kiểm tra xem đã có dữ liệu trong bảng FEATURE_REGISTRY chưa
IF NOT EXISTS (SELECT 1 FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY WHERE FEATURE_CODE = 'CUST_AGE')
BEGIN
    PRINT N'Bắt đầu nhập dữ liệu tiên quyết cho bảng FEATURE_REGISTRY...';

    -- Đặc trưng tổng hợp và dẫn xuất
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
    ('Debt to Income Ratio', 'DTI', N'Tỷ lệ tổng dư nợ trên thu nhập hàng tháng (%)', 
     'NUMERIC', 'CONTINUOUS', 'DATA_WAREHOUSE', 'FINANCIAL', 
     N'DTI là thước đo quan trọng về khả năng trả nợ, đo lường nghĩa vụ nợ so với thu nhập. Tỷ lệ cao hơn chỉ ra gánh nặng nợ lớn hơn.', 
     0, 0, NULL, '0', '10', NULL, 
     N'Risk Analytics Team', 'MONTHLY');

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
    ('Probability of Default', 'PD', N'Xác suất vỡ nợ trong 12 tháng tới', 
     'NUMERIC', 'CONTINUOUS', 'RISK_MODELS', 'RISK_METRIC', 
     N'PD là ước lượng thống kê về khả năng khách hàng sẽ vỡ nợ trong 12 tháng tới, dựa trên mô hình PD được phát triển nội bộ.', 
     0, 1, NULL, '0', '1', NULL, 
     N'Risk Modeling Team', 'MONTHLY');

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
    ('Risk Grade', 'RISK_GRADE', N'Cấp độ rủi ro dựa trên xác suất vỡ nợ', 
     'CATEGORICAL', 'ORDINAL', 'RISK_MODELS', 'RISK_METRIC', 
     N'Risk Grade là cách ánh xạ PD thành các loại rủi ro được hiểu rộng rãi để hỗ trợ ra quyết định.', 
     0, 1, 'B', NULL, NULL, N'["AAA", "AA", "A", "BBB", "BB", "B", "CCC", "CC", "C"]', 
     N'Risk Modeling Team', 'MONTHLY');

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
    ('Behavior Score', 'BEH_SCORE', N'Điểm đánh giá hành vi tổng hợp', 
     'NUMERIC', 'DISCRETE', 'RISK_MODELS', 'RISK_METRIC', 
     N'Behavior Score là điểm tổng hợp dựa trên nhiều đặc trưng hành vi, cao hơn chỉ ra rủi ro thấp hơn.', 
     0, 0, NULL, '300', '900', NULL, 
     N'Risk Modeling Team', 'MONTHLY');

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
    ('Risk Category', 'RISK_CAT', N'Phân loại mức độ rủi ro', 
     'CATEGORICAL', 'ORDINAL', 'RISK_MODELS', 'RISK_METRIC', 
     N'Risk Category là phân loại rủi ro tổng thể dựa trên nhiều chỉ số rủi ro, được sử dụng cho ra quyết định kinh doanh.', 
     0, 0, 'MEDIUM_RISK', NULL, NULL, N'["LOW_RISK", "MEDIUM_RISK", "HIGH_RISK", "VERY_HIGH_RISK"]', 
     N'Risk Modeling Team', 'MONTHLY');

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
    ('Loan to Value Ratio', 'LTV', N'Tỷ lệ khoản vay trên giá trị tài sản (%)', 
     'NUMERIC', 'CONTINUOUS', 'DATA_WAREHOUSE', 'FINANCIAL', 
     N'LTV quan trọng cho các khoản vay thế chấp, đo lường giá trị khoản vay so với giá trị tài sản thế chấp. Tỷ lệ cao hơn chỉ ra rủi ro cao hơn nếu giá trị tài sản giảm.', 
     0, 0, '0.8', '0', '1.5', NULL, 
     N'Mortgage Team', 'QUARTERLY');

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
    ('Cash Advance Ratio', 'CASH_ADV_RATIO', N'Tỷ lệ rút tiền mặt trên hạn mức tín dụng (%)', 
     'NUMERIC', 'CONTINUOUS', 'DATA_WAREHOUSE', 'BEHAVIORAL', 
     N'Tỷ lệ rút tiền mặt cao trên thẻ tín dụng thường là dấu hiệu của khó khăn tài chính và rủi ro cao hơn.', 
     0, 0, '0', '0', '1', NULL, 
     N'Credit Card Team', 'MONTHLY');

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
    ('Months on Book', 'MOB', N'Số tháng kể từ khi mở tài khoản/sản phẩm hiện tại', 
     'NUMERIC', 'DISCRETE', 'CORE_BANKING', 'ACCOUNT', 
     N'MOB là thước đo về thời gian tài khoản đã hoạt động, liên quan đến hiệu ứng "seasoning" trong rủi ro tín dụng.', 
     0, 0, '0', '0', '600', NULL, 
     N'Account Management Team', 'MONTHLY');

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
    ('Customer Age', 'CUST_AGE', N'Tuổi của khách hàng tại thời điểm tính toán', 
     'NUMERIC', 'CONTINUOUS', 'CORE_BANKING', 'DEMOGRAPHIC', 
     N'Tuổi là một yếu tố quan trọng trong đánh giá rủi ro. Thông thường, khách hàng trung niên (35-55) có xu hướng ổn định hơn về mặt tài chính.', 
     0, 0, NULL, '18', '100', NULL, 
     N'Customer Data Management Team', 'MONTHLY');

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
    ('Customer Income', 'INCOME', N'Thu nhập hàng tháng của khách hàng (VND)', 
     'NUMERIC', 'CONTINUOUS', 'CORE_BANKING', 'FINANCIAL', 
     N'Thu nhập là yếu tố chính trong đánh giá khả năng trả nợ. Quan trọng để tính tỷ lệ nợ trên thu nhập (DTI) và khả năng thanh toán.', 
     0, 1, '0', '0', '1000000000', NULL, 
     N'Risk Analytics Team', 'QUARTERLY');

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
    ('Gender', 'GENDER', N'Giới tính của khách hàng', 
     'CATEGORICAL', 'NOMINAL', 'CORE_BANKING', 'DEMOGRAPHIC', 
     N'Giới tính có thể có ảnh hưởng đến các mẫu hành vi tài chính và rủi ro. Tác động thực tế phụ thuộc vào từng thị trường và phân khúc khách hàng.', 
     1, 0, 'UNKNOWN', NULL, NULL, N'["MALE", "FEMALE", "OTHER", "UNKNOWN"]', 
     N'Customer Data Management Team', 'STATIC');

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
    ('Occupation', 'OCCUP', N'Nghề nghiệp hoặc lĩnh vực làm việc của khách hàng', 
     'CATEGORICAL', 'NOMINAL', 'CORE_BANKING', 'DEMOGRAPHIC', 
     N'Nghề nghiệp ảnh hưởng đến độ ổn định thu nhập và khả năng tìm kiếm việc làm mới. Một số ngành (như y tế, giáo dục) thường có việc làm ổn định hơn.', 
     0, 0, 'UNKNOWN', NULL, NULL, N'["PROFESSIONAL", "MANAGER", "TECHNICIAN", "CLERICAL", "SERVICE", "AGRICULTURE", "PRODUCTION", "MILITARY", "UNEMPLOYED", "RETIRED", "STUDENT", "HOMEMAKER", "SELF_EMPLOYED", "OTHER", "UNKNOWN"]', 
     N'Customer Data Management Team', 'QUARTERLY');

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
    ('Employment Status', 'EMP_STATUS', N'Tình trạng việc làm hiện tại của khách hàng', 
     'CATEGORICAL', 'NOMINAL', 'CORE_BANKING', 'DEMOGRAPHIC', 
     N'Tình trạng việc làm ảnh hưởng đến độ ổn định tài chính. Khách hàng có việc làm toàn thời gian thường được đánh giá ít rủi ro hơn.', 
     0, 0, 'UNKNOWN', NULL, NULL, N'["EMPLOYED", "SELF_EMPLOYED", "UNEMPLOYED", "RETIRED", "STUDENT", "UNKNOWN"]', 
     N'Customer Data Management Team', 'MONTHLY');

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
    ('Residence Status', 'RES_STATUS', N'Tình trạng sở hữu nơi ở của khách hàng', 
     'CATEGORICAL', 'NOMINAL', 'CORE_BANKING', 'DEMOGRAPHIC', 
     N'Tình trạng sở hữu nhà ở là một chỉ báo về sự ổn định. Khách hàng sở hữu nhà thường được coi là ổn định hơn những người thuê nhà.', 
     0, 0, 'UNKNOWN', NULL, NULL, N'["OWNED", "MORTGAGED", "RENTED", "LIVING_WITH_PARENTS", "OTHER", "UNKNOWN"]', 
     N'Customer Data Management Team', 'QUARTERLY');

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
    ('Customer Tenure', 'CUST_TENURE', N'Thời gian khách hàng quan hệ với ngân hàng (tháng)', 
     'NUMERIC', 'DISCRETE', 'CORE_BANKING', 'RELATIONSHIP', 
     N'Thời gian quan hệ với ngân hàng là chỉ báo về sự trung thành và ổn định. Quan hệ lâu dài thường đi kèm với nhận thức tốt hơn về rủi ro của khách hàng.', 
     0, 0, '0', '0', '600', NULL, 
     N'Customer Experience Team', 'MONTHLY');

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
    ('Customer Segment', 'CUST_SEGMENT', N'Phân khúc khách hàng theo chính sách của ngân hàng', 
     'CATEGORICAL', 'ORDINAL', 'CORE_BANKING', 'RELATIONSHIP', 
     N'Phân khúc khách hàng dựa trên giá trị, mức độ tương tác và các thuộc tính khác để phục vụ chiến lược phân biệt.', 
     0, 0, 'MASS', NULL, NULL, N'["MASS", "AFFLUENT", "PREMIER", "PRIVATE_BANKING"]', 
     N'Customer Experience Team', 'MONTHLY');
    
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
    ('DPD 30+ Last 12M', 'DPD_30_L12M', N'Số lần quá hạn trên 30 ngày trong 12 tháng qua', 
     'NUMERIC', 'DISCRETE', 'DATA_WAREHOUSE', 'DELINQUENCY', 
     N'Tần suất quá hạn là một chỉ báo mạnh mẽ về hành vi thanh toán và khả năng vỡ nợ trong tương lai.', 
     0, 0, '0', '0', '12', NULL, 
     N'Risk Analytics Team', 'MONTHLY');

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
    ('Maximum DPD Last 12M', 'MAX_DPD_L12M', N'Số ngày quá hạn tối đa trong 12 tháng qua', 
     'NUMERIC', 'DISCRETE', 'DATA_WAREHOUSE', 'DELINQUENCY', 
     N'Mức độ quá hạn tối đa trong quá khứ là chỉ báo về mức độ nghiêm trọng của hành vi trễ hạn.', 
     0, 0, '0', '0', '180', NULL, 
     N'Risk Analytics Team', 'MONTHLY');

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
    ('Utilization Ratio', 'UTIL_RATIO', N'Tỷ lệ sử dụng hạn mức tín dụng (%)', 
     'NUMERIC', 'CONTINUOUS', 'DATA_WAREHOUSE', 'BEHAVIORAL', 
     N'Tỷ lệ sử dụng hạn mức là một chỉ báo quan trọng về hành vi tín dụng và mức độ phụ thuộc vào tín dụng của khách hàng. Tỷ lệ cao (>70%) thường liên quan đến rủi ro cao hơn.', 
     0, 0, '0', '0', '1', NULL, 
     N'Risk Analytics Team', 'DAILY');

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
    ('Average Balance Last 3M', 'AVG_BAL_L3M', N'Số dư tài khoản trung bình trong 3 tháng gần nhất (VND)', 
     'NUMERIC', 'CONTINUOUS', 'DATA_WAREHOUSE', 'BALANCE', 
     N'Số dư trung bình gần đây cung cấp thông tin về hành vi gần đây và các xu hướng sử dụng tài khoản.', 
     0, 0, '0', '-1000000000', '10000000000', NULL, 
     N'Finance Data Team', 'MONTHLY');

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
    ('Credit Limit', 'CREDIT_LIMIT', N'Hạn mức tín dụng được cấp (VND)', 
     'NUMERIC', 'CONTINUOUS', 'CORE_BANKING', 'ACCOUNT', 
     N'Hạn mức tín dụng thể hiện mức độ rủi ro mà ngân hàng sẵn sàng chấp nhận. Thường được thiết lập dựa trên đánh giá tín dụng ban đầu.', 
     0, 0, '0', '0', '1000000000', NULL, 
     N'Credit Risk Management Team', 'MONTHLY');

    PRINT N'Đã nhập dữ liệu tiên quyết cho bảng FEATURE_REGISTRY thành công.';
END
ELSE
BEGIN
    PRINT N'Dữ liệu đã tồn tại trong bảng FEATURE_REGISTRY. Không cần nhập lại.';
END
GO