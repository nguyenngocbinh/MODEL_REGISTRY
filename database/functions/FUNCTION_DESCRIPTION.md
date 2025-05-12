# FUNCTIONS DESCRIPTION

## Tổng Quan

Thư mục `functions` chứa các scalar và table-valued functions được sử dụng trong Hệ Thống Đăng Ký Mô Hình để thực hiện các tác vụ tính toán và truy xuất dữ liệu. Các functions này cung cấp các tính năng quan trọng để truy xuất điểm số mô hình và tính toán các chỉ số đánh giá hiệu suất mô hình.

## Danh Sách Functions

### 1. FN_GET_MODEL_SCORE

**Mô tả**: Table-valued function truy xuất điểm số của một khách hàng dựa trên mô hình cụ thể.

**Tham số đầu vào**:
- `@MODEL_ID` (INT): ID của mô hình cần sử dụng
- `@CUSTOMER_ID` (NVARCHAR(50)): ID của khách hàng cần tính điểm
- `@AS_OF_DATE` (DATE, tùy chọn): Ngày cụ thể để truy xuất điểm, mặc định là ngày hiện tại

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
- Tự động xác định loại mô hình và truy vấn bảng dữ liệu phù hợp
- Xử lý các cấu trúc bảng khác nhau cho các loại mô hình khác nhau (PD, Behavioral Scorecard, Application Scorecard, EWS)
- Đánh giá tính cập nhật của điểm số dựa trên ngày tham chiếu

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

### 3. FN_CALCULATE_PSI_TABLES

**Mô tả**: Scalar function tính toán chỉ số PSI từ hai kỳ dữ liệu trong bảng.

**Tham số đầu vào**:
- `@MODEL_ID` (INT): ID của mô hình cần đánh giá
- `@BASE_PERIOD_DATE` (DATE): Ngày của kỳ cơ sở
- `@COMPARISON_PERIOD_DATE` (DATE): Ngày của kỳ so sánh
- `@NUM_BINS` (INT, tùy chọn): Số lượng bins để phân chia điểm số, mặc định là 10

**Kết quả trả về**: Giá trị PSI (FLOAT)

**Ví dụ sử dụng**:
```sql
-- Tính PSI giữa hai kỳ dữ liệu
SELECT MODEL_REGISTRY.dbo.FN_CALCULATE_PSI_TABLES(
    1, -- MODEL_ID
    '2024-12-31', -- Kỳ cơ sở
    '2025-03-31', -- Kỳ so sánh
    20 -- Sử dụng 20 bins
) AS PSI_Value;
```

**Đặc điểm nổi bật**:
- Tự động xác định bảng dữ liệu và cột điểm dựa trên thông tin mô hình
- Tính toán phân phối điểm số cho cả hai kỳ và so sánh sự khác biệt
- Điều chỉnh số lượng bins để tối ưu hóa việc phân tích sự ổn định

## Cách Sử Dụng Trong Quy Trình

### Trong Quy Trình Tính Điểm

1. Sử dụng `FN_GET_MODEL_SCORE` để truy xuất điểm khách hàng từ mô hình phù hợp nhất
2. Kiểm tra trạng thái điểm (SCORE_STATUS) để xác định xem điểm có cập nhật không
3. Sử dụng thông tin điểm và phân loại rủi ro cho các quyết định nghiệp vụ

### Trong Quy Trình Đánh Giá Mô Hình

1. Sử dụng `FN_CALCULATE_PSI_TABLES` để tính PSI giữa kỳ phát triển và kỳ đánh giá hiện tại
2. So sánh giá trị PSI với ngưỡng đánh giá để xác định sự ổn định của mô hình
3. Nếu PSI vượt ngưỡng, xem xét việc tái huấn luyện mô hình

## Lưu Ý Khi Sử Dụng

- Function `FN_GET_MODEL_SCORE` sử dụng OPENDATASOURCE để truy cập bảng dữ liệu, do đó cần cấu hình phù hợp để cho phép truy cập từ xa.
- Đảm bảo các bảng đầu ra của mô hình có cấu trúc phù hợp với các trường được tham chiếu trong function.
- Khi tính PSI, nên sử dụng số lượng bins phù hợp (thường từ 10-20) để đảm bảo kết quả chính xác.
- Các giá trị PSI thường được diễn giải như sau:
  - PSI < 0.1: Không có sự thay đổi đáng kể
  - 0.1 <= PSI < 0.25: Có sự thay đổi nhỏ, cần theo dõi
  - PSI >= 0.25: Thay đổi đáng kể, cần xem xét lại mô hình