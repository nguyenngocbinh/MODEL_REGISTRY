# FUNCTIONS DESCRIPTION

## Tổng Quan

Thư mục `functions` chứa các scalar và table-valued functions cùng với stored procedures được sử dụng trong Hệ Thống Đăng Ký Mô Hình để thực hiện các tác vụ tính toán và truy xuất dữ liệu. Các functions này cung cấp các tính năng quan trọng để truy xuất điểm số mô hình và tính toán các chỉ số đánh giá hiệu suất mô hình.

## Danh Sách Functions

### 1. FN_GET_MODEL_SCORE

**Mô tả**: Table-valued function truy xuất điểm số của một khách hàng dựa trên mô hình cụ thể.

**Tham số đầu vào**:
- `@MODEL_ID` (INT): ID của mô hình cần sử dụng
- `@CUSTOMER_ID` (NVARCHAR(50)): ID của khách hàng cần tính điểm
- `@AS_OF_DATE` (DATE, tùy chọn): Ngày cụ thể để truy xuất điểm, mặc định là NULL (lấy điểm hiện tại)

**Kết quả trả về**: Bảng chứa thông tin về:
- Thông tin mô hình (ID, tên, phiên bản, loại)
- ID khách hàng
- Điểm số (SCORE)
- Xác suất vỡ nợ (PROBABILITY) nếu có
- Phân loại rủi ro (RISK_CATEGORY)
- Ngày tính điểm (SCORE_DATE)
- Trạng thái điểm (SCORE_STATUS): 'CURRENT', 'OUTDATED', hoặc 'NOT_FOUND'

**Ví dụ sử dụng**:
```sql
-- Lấy điểm hiện tại của khách hàng 'CUST12345' theo mô hình ID 1
SELECT * FROM MODEL_REGISTRY.dbo.FN_GET_MODEL_SCORE(1, 'CUST12345', NULL);

-- Lấy điểm lịch sử của khách hàng tại ngày cụ thể
SELECT * FROM MODEL_REGISTRY.dbo.FN_GET_MODEL_SCORE(1, 'CUST12345', '2025-01-31');
```

**Đặc điểm nổi bật**:
- Sử dụng CTE (Common Table Expression) để xử lý thông tin mô hình
- Tự động xác định loại mô hình (PD, BSCORE, ASCORE, EARLY_WARN) và điều chỉnh kết quả phù hợp
- Trả về trạng thái điểm số dựa trên việc tìm thấy mô hình và ngày tham chiếu

### 2. FN_CALCULATE_PSI

**Mô tả**: Scalar function tính toán chỉ số Population Stability Index (PSI) từ hai phân phối.

**Tham số đầu vào**:
- `@EXPECTED_DISTRIBUTION` (NVARCHAR(MAX)): Chuỗi JSON chứa mảng các giá trị tần suất của phân phối kỳ vọng
- `@ACTUAL_DISTRIBUTION` (NVARCHAR(MAX)): Chuỗi JSON chứa mảng các giá trị tần suất của phân phối thực tế
- `@MIN_PERCENTAGE` (FLOAT, tùy chọn): Giá trị tối thiểu để tránh chia cho 0, mặc định là 0.0001

**Kết quả trả về**: Giá trị PSI (FLOAT)

**Ví dụ sử dụng**:
```sql
-- Tính PSI từ hai mảng phân phối
DECLARE @expected NVARCHAR(MAX) = '[0.1, 0.2, 0.3, 0.2, 0.1, 0.1]';
DECLARE @actual NVARCHAR(MAX) = '[0.15, 0.25, 0.25, 0.15, 0.1, 0.1]';

SELECT MODEL_REGISTRY.dbo.FN_CALCULATE_PSI(@expected, @actual, 0.0001) AS PSI_Value;
```

**Đặc điểm nổi bật**:
- Sử dụng bảng tạm để xử lý dữ liệu phân phối
- Sử dụng FULL OUTER JOIN để đảm bảo mọi bin đều được xem xét
- Xử lý cẩn thận các trường hợp đặc biệt như giá trị bằng 0 hoặc quá nhỏ
- Tăng cường xử lý lỗi và bảo mật theo phiên bản 1.2

### 3. SP_CALCULATE_PSI_TABLES

**Mô tả**: Stored procedure tính toán chỉ số PSI từ hai kỳ dữ liệu trong bảng.

**Tham số đầu vào**:
- `@MODEL_ID` (INT): ID của mô hình cần đánh giá
- `@BASE_PERIOD_DATE` (DATE): Ngày của kỳ cơ sở
- `@COMPARISON_PERIOD_DATE` (DATE): Ngày của kỳ so sánh
- `@NUM_BINS` (INT, tùy chọn): Số lượng bins để phân chia điểm số, mặc định là 10
- `@PSI` (FLOAT OUTPUT): Tham số đầu ra chứa giá trị PSI tính được

**Kết quả trả về**: Không có (thông qua tham số OUTPUT)

**Ví dụ sử dụng**:
```sql
-- Tính PSI giữa hai kỳ dữ liệu
DECLARE @result FLOAT;
EXEC MODEL_REGISTRY.dbo.SP_CALCULATE_PSI_TABLES 
    @MODEL_ID = 1, 
    @BASE_PERIOD_DATE = '2025-01-01', 
    @COMPARISON_PERIOD_DATE = '2025-02-01', 
    @NUM_BINS = 10, 
    @PSI = @result OUTPUT;
SELECT @result AS PSI_Result;
```

**Đặc điểm nổi bật**:
- Sử dụng dynamic SQL để truy vấn bảng dữ liệu của mô hình
- Tự động xác định cột điểm số dựa trên loại mô hình
- Tạo bins tự động dựa trên phạm vi điểm số
- Xử lý cẩn thận các trường hợp đặc biệt và tràn số
- Xử lý lỗi toàn diện với nhiều kiểm tra hợp lệ

### 4. FN_GET_PSI_TABLES

**Mô tả**: Function wrapper để gọi SP_CALCULATE_PSI_TABLES. Lưu ý rằng function này chỉ dùng cho mục đích tương thích và không hoạt động trực tiếp.

**Tham số đầu vào**:
- `@MODEL_ID` (INT): ID của mô hình cần đánh giá
- `@BASE_PERIOD_DATE` (DATE): Ngày của kỳ cơ sở
- `@COMPARISON_PERIOD_DATE` (DATE): Ngày của kỳ so sánh
- `@NUM_BINS` (INT, tùy chọn): Số lượng bins để phân chia điểm số, mặc định là 10

**Kết quả trả về**: Giá trị -1 (FLOAT), chỉ ra rằng người dùng cần gọi SP_CALCULATE_PSI_TABLES thay vì function này

**Ví dụ sử dụng**:
```sql
-- KHÔNG KHUYẾN KHÍCH: Function này chỉ trả về -1
SELECT MODEL_REGISTRY.dbo.FN_GET_PSI_TABLES(
    1, -- MODEL_ID
    '2025-01-01', -- Kỳ cơ sở
    '2025-02-01', -- Kỳ so sánh
    10 -- Số bins
) AS PSI_Value; -- Luôn trả về -1
```

**Lưu ý**: Function này chỉ được tạo ra để duy trì tương thích với mã hiện có. Người dùng nên sử dụng SP_CALCULATE_PSI_TABLES trực tiếp.

## Cách Sử Dụng Trong Quy Trình

### Trong Quy Trình Tính Điểm

1. Sử dụng `FN_GET_MODEL_SCORE` để truy xuất điểm khách hàng từ mô hình phù hợp nhất
2. Kiểm tra trạng thái điểm (SCORE_STATUS) để xác định xem điểm có cập nhật không
3. Sử dụng thông tin điểm và phân loại rủi ro cho các quyết định nghiệp vụ

### Trong Quy Trình Đánh Giá Mô Hình

1. Sử dụng `SP_CALCULATE_PSI_TABLES` để tính PSI giữa kỳ phát triển và kỳ đánh giá hiện tại
2. So sánh giá trị PSI với ngưỡng đánh giá để xác định sự ổn định của mô hình:
   - PSI < 0.1: Không có sự thay đổi đáng kể
   - 0.1 <= PSI < 0.25: Có sự thay đổi nhỏ, cần theo dõi
   - PSI >= 0.25: Thay đổi đáng kể, cần xem xét lại mô hình
3. Nếu PSI vượt ngưỡng, xem xét việc tái huấn luyện mô hình

## Lưu Ý Khi Sử Dụng

- Function `FN_GET_MODEL_SCORE` hiện tại sử dụng dữ liệu giả định cho mục đích thử nghiệm. Trong môi trường thực tế, bạn cần thay thế phần này bằng các truy vấn tới bảng dữ liệu thực.
- Function `FN_CALCULATE_PSI` đã được cập nhật (phiên bản 1.2) để xử lý tốt hơn các trường hợp đặc biệt và cải thiện bảo mật.
- Khi tính PSI, nên sử dụng số lượng bins phù hợp (thường từ 10-20) để đảm bảo kết quả chính xác.
- Không nên sử dụng `FN_GET_PSI_TABLES` trực tiếp mà thay vào đó nên gọi `SP_CALCULATE_PSI_TABLES`.
- Đảm bảo các quyền truy cập database phù hợp khi sử dụng dynamic SQL trong stored procedure.