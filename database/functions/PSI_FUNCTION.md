# Hướng dẫn cách chạy ví dụ tính PSI

Để chạy các ví dụ tính toán Population Stability Index (PSI) với các function và stored procedure vừa tạo, tôi sẽ hướng dẫn từng bước:

## 1. Chuẩn bị môi trường

Trước khi chạy ví dụ, hãy đảm bảo:
- Bạn đã tạo cơ sở dữ liệu MODEL_REGISTRY
- Script cài đặt các function và stored procedure đã chạy thành công
- Bạn có quyền truy cập vào database và thực thi các stored procedure

## 2. Ví dụ sử dụng FN_CALCULATE_PSI

Function này tính PSI từ hai mảng phân phối được cung cấp dưới dạng chuỗi JSON.

```sql
-- Đảm bảo đang sử dụng đúng database
USE MODEL_REGISTRY;

-- Khai báo biến
DECLARE @expected NVARCHAR(MAX) = '[0.1, 0.2, 0.3, 0.4]';  -- Phân phối kỳ vọng
DECLARE @actual NVARCHAR(MAX) = '[0.12, 0.18, 0.35, 0.35]';  -- Phân phối thực tế
DECLARE @min_pct FLOAT = 0.0001;  -- Giá trị tối thiểu để tránh chia cho 0

-- Tính PSI
SELECT dbo.FN_CALCULATE_PSI(@expected, @actual, @min_pct) AS PSI_Value;
```

### Giải thích:
- `@expected`: Mảng JSON chứa phân phối kỳ vọng (tổng các giá trị = 1)
- `@actual`: Mảng JSON chứa phân phối thực tế (tổng các giá trị = 1)
- `@min_pct`: Giá trị tối thiểu để tránh lỗi chia cho 0 hoặc log(0)

### Ví dụ thực tế hơn:
```sql
-- Phân phối điểm tín dụng trước và sau COVID
DECLARE @before_covid NVARCHAR(MAX) = '[0.05, 0.15, 0.20, 0.30, 0.20, 0.10]';
DECLARE @after_covid NVARCHAR(MAX) = '[0.10, 0.25, 0.25, 0.20, 0.15, 0.05]';

-- Tính PSI
SELECT dbo.FN_CALCULATE_PSI(@before_covid, @after_covid, 0.0001) AS Credit_Score_PSI;
```

## 3. Ví dụ sử dụng SP_CALCULATE_PSI_TABLES

Stored procedure này tính PSI từ dữ liệu thực tế trong bảng, cho các điểm số được tính toán ở hai thời điểm khác nhau.

```sql
-- Đảm bảo đang sử dụng đúng database
USE MODEL_REGISTRY;

-- Khai báo biến để nhận kết quả
DECLARE @result FLOAT;

-- Gọi stored procedure
EXEC dbo.SP_CALCULATE_PSI_TABLES 
    @MODEL_ID = 1,                          -- ID của mô hình trong bảng MODEL_REGISTRY
    @BASE_PERIOD_DATE = '2025-01-01',       -- Ngày tham chiếu
    @COMPARISON_PERIOD_DATE = '2025-02-01', -- Ngày so sánh
    @NUM_BINS = 10,                         -- Số lượng bin (phân đoạn)
    @PSI = @result OUTPUT;                  -- Biến nhận kết quả

-- Hiển thị kết quả
SELECT @result AS PSI_Result;
```

### Giải thích tham số:
- `@MODEL_ID`: ID của mô hình trong bảng MODEL_REGISTRY (bạn cần thay bằng ID thực tế từ bảng)
- `@BASE_PERIOD_DATE`: Ngày của dữ liệu cơ sở/tham chiếu
- `@COMPARISON_PERIOD_DATE`: Ngày của dữ liệu cần so sánh
- `@NUM_BINS`: Số lượng bin (phân đoạn) để chia dải điểm 
- `@PSI`: Biến OUTPUT để nhận giá trị PSI sau khi tính toán

### Điều kiện tiên quyết để chạy SP_CALCULATE_PSI_TABLES:

1. Phải có bảng `MODEL_REGISTRY` và `MODEL_TYPE` với cấu trúc:
   - `MODEL_REGISTRY`: Chứa thông tin về mô hình (MODEL_ID, TYPE_ID, SOURCE_DATABASE, SOURCE_SCHEMA, SOURCE_TABLE_NAME...)
   - `MODEL_TYPE`: Chứa thông tin về loại mô hình (TYPE_ID, TYPE_CODE...)

2. Phải có bảng dữ liệu nguồn (được tham chiếu từ SOURCE_DATABASE, SOURCE_SCHEMA, SOURCE_TABLE_NAME) với:
   - Cột điểm số (SCORE hoặc WARNING_SCORE tùy thuộc vào loại mô hình)
   - Cột PROCESS_DATE để lọc dữ liệu theo ngày

## 4. Ví dụ thực tế tích hợp

Dưới đây là ví dụ đầy đủ để đánh giá sự ổn định của mô hình scoring theo thời gian:

```sql
USE MODEL_REGISTRY;
GO

-- 1. Tạo một bản ghi mô hình mẫu nếu chưa có
-- Giả sử chúng ta đã có các bảng schema cần thiết
IF NOT EXISTS (SELECT 1 FROM dbo.MODEL_TYPE WHERE TYPE_CODE = 'CREDIT_SCORE')
BEGIN
    INSERT INTO dbo.MODEL_TYPE (TYPE_ID, TYPE_CODE, TYPE_NAME, DESCRIPTION)
    VALUES (1, 'CREDIT_SCORE', N'Mô hình chấm điểm tín dụng', N'Mô hình đánh giá xếp hạng tín dụng khách hàng');
END

-- Thêm mô hình mẫu nếu chưa có
IF NOT EXISTS (SELECT 1 FROM dbo.MODEL_REGISTRY WHERE MODEL_ID = 1)
BEGIN
    INSERT INTO dbo.MODEL_REGISTRY 
    (MODEL_ID, MODEL_NAME, VERSION, TYPE_ID, SOURCE_DATABASE, SOURCE_SCHEMA, SOURCE_TABLE_NAME, CREATE_DATE, STATUS)
    VALUES 
    (1, N'Credit Scoring Model', '1.0', 1, 'RISK_DB', 'dbo', 'CUSTOMER_SCORES', GETDATE(), 'ACTIVE');
END

-- 2. Tính PSI giữa hai kỳ
DECLARE @psi_result FLOAT;

EXEC dbo.SP_CALCULATE_PSI_TABLES 
    @MODEL_ID = 1,                          
    @BASE_PERIOD_DATE = '2025-01-01',       
    @COMPARISON_PERIOD_DATE = '2025-02-01', 
    @NUM_BINS = 10,                         
    @PSI = @psi_result OUTPUT;              

-- 3. Đánh giá mức độ ổn định dựa trên PSI
SELECT 
    @psi_result AS PSI_Value,
    CASE 
        WHEN @psi_result < 0.1 THEN N'Không có sự thay đổi đáng kể'
        WHEN @psi_result < 0.25 THEN N'Có sự thay đổi nhỏ, cần theo dõi'        
        ELSE N'Thay đổi đáng kể - Mô hình cần được xem xét lại ngay lập tức'
    END AS Stability_Assessment;
```

## 5. Lưu ý quan trọng

1. **Đảm bảo dữ liệu đầy đủ**: 
   - Cả hai kỳ cần có đủ dữ liệu để tính toán chính xác
   - Nếu một trong hai kỳ không có dữ liệu, kết quả PSI sẽ là 0

2. **Giá trị PSI và ý nghĩa**:
   - PSI < 0.1: Không có sự thay đổi đáng kể
   - 0.1 ≤ PSI < 0.25: Có sự thay đổi nhỏ, cần theo dõi   
   - PSI ≥ 0.25: Thay đổi đáng kể - Mô hình cần được xem xét lại ngay lập tức

3. **Xử lý số lượng bin**:
   - Số lượng bin (@NUM_BINS) cần được chọn phù hợp với kích thước dữ liệu
   - Thường dùng 10-20 bin cho dữ liệu lớn, 5-10 bin cho dữ liệu nhỏ

4. **Xử lý lỗi chia cho 0**:
   - Function đã có bảo vệ đối với trường hợp đặc biệt (chia cho 0, log(0))
   - Tham số @MIN_PERCENTAGE (trong FN_CALCULATE_PSI) điều chỉnh mức xử lý tối thiểu

## 6. Khắc phục sự cố

Nếu bạn gặp lỗi khi chạy ví dụ:

1. **Lỗi không tìm thấy bảng MODEL_REGISTRY hoặc MODEL_TYPE**:
   - Kiểm tra xem database MODEL_REGISTRY đã tồn tại chưa
   - Đảm bảo các bảng đã được tạo với cấu trúc phù hợp

2. **Lỗi không tìm thấy dữ liệu nguồn**:
   - Kiểm tra các tham số SOURCE_DATABASE, SOURCE_SCHEMA, SOURCE_TABLE_NAME trong bảng MODEL_REGISTRY
   - Đảm bảo dữ liệu nguồn tồn tại với cột PROCESS_DATE và cột điểm (SCORE hoặc WARNING_SCORE)

3. **PSI luôn trả về 0**:
   - Kiểm tra xem dữ liệu có tồn tại cho hai kỳ được chọn không
   - Đảm bảo range điểm không quá nhỏ (MIN và MAX khác nhau)
   - Thử tăng tham số @NUM_BINS nếu dải điểm rất rộng

Với hướng dẫn này, bạn có thể dễ dàng chạy và tận dụng các function tính PSI để đánh giá tính ổn định của mô hình theo thời gian.