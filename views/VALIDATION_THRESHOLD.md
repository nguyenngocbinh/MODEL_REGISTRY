# NGƯỠNG ĐÁNH GIÁ MÔ HÌNH (VALIDATION THRESHOLDS)

## Tổng Quan

Tài liệu này mô tả các ngưỡng đánh giá được sử dụng để đánh giá hiệu suất của các mô hình trong Hệ Thống Đăng Ký Mô Hình. Các ngưỡng này giúp xác định mức độ hiệu suất của mô hình và cung cấp cảnh báo khi hiệu suất không đạt yêu cầu.

## Hệ Thống Đánh Giá

Hệ thống đánh giá sử dụng ba mức độ:

- **RED (Đỏ)**: Hiệu suất không đạt yêu cầu, cần xem xét lại mô hình.
- **AMBER (Vàng)**: Hiệu suất chấp nhận được nhưng cần theo dõi.
- **GREEN (Xanh)**: Hiệu suất tốt, mô hình hoạt động như mong đợi.

## Các Chỉ Số Đánh Giá và Ngưỡng

### 1. AUC-ROC (Area Under the Receiver Operating Characteristic Curve)

AUC-ROC là chỉ số đánh giá khả năng phân biệt của mô hình giữa các trường hợp tích cực và tiêu cực.

| Mức Đánh Giá | Ngưỡng | Mô Tả |
|-------------|--------|-------|
| **RED** | < 0.6 | Khả năng phân biệt kém |
| **AMBER** | 0.6 - 0.7 | Khả năng phân biệt chấp nhận được |
| **GREEN** | > 0.7 | Khả năng phân biệt tốt |

### 2. KS (Kolmogorov-Smirnov)

KS là chỉ số đo lường sự khác biệt tối đa giữa phân phối tích lũy của các trường hợp tích cực và tiêu cực.

| Mức Đánh Giá | Ngưỡng | Mô Tả |
|-------------|--------|-------|
| **RED** | < 0.2 | Khả năng phân biệt kém |
| **AMBER** | 0.2 - 0.3 | Khả năng phân biệt chấp nhận được |
| **GREEN** | > 0.3 | Khả năng phân biệt tốt |

### 3. GINI (Gini Coefficient)

Gini Coefficient là chỉ số đánh giá sự không đồng đều trong phân phối của mô hình, có mối quan hệ với AUC-ROC (GINI = 2 × AUC - 1).

| Mức Đánh Giá | Ngưỡng | Mô Tả |
|-------------|--------|-------|
| **RED** | < 0.2 | Khả năng phân biệt kém |
| **AMBER** | 0.2 - 0.4 | Khả năng phân biệt chấp nhận được |
| **GREEN** | > 0.4 | Khả năng phân biệt tốt |

### 4. PSI (Population Stability Index)

PSI là chỉ số đánh giá sự ổn định của mô hình, đo lường mức độ khác biệt giữa phân phối điểm số của dữ liệu phát triển và dữ liệu kiểm định.

| Mức Đánh Giá | Ngưỡng | Mô Tả |
|-------------|--------|-------|
| **RED** | > 0.25 | Không ổn định, cần xem xét lại mô hình |
| **AMBER** | 0.1 - 0.25 | Có dấu hiệu thay đổi, cần theo dõi |
| **GREEN** | < 0.1 | Ổn định |

### 5. IV (Information Value)

IV là chỉ số đánh giá khả năng dự đoán của các biến trong mô hình.

| Mức Đánh Giá | Ngưỡng | Mô Tả |
|-------------|--------|-------|
| **RED** | < 0.02 | Khả năng dự đoán kém |
| **AMBER** | 0.02 - 0.1 | Khả năng dự đoán trung bình |
| **GREEN** | > 0.1 | Khả năng dự đoán tốt |

### 6. KAPPA (Cohen's Kappa)

Kappa là chỉ số đánh giá mức độ đồng thuận giữa dự đoán của mô hình và giá trị thực tế, sau khi loại bỏ đồng thuận do ngẫu nhiên.

| Mức Đánh Giá | Ngưỡng | Mô Tả |
|-------------|--------|-------|
| **RED** | < 0.2 | Mức độ đồng thuận kém |
| **AMBER** | 0.2 - 0.6 | Mức độ đồng thuận trung bình |
| **GREEN** | > 0.6 | Mức độ đồng thuận tốt |

## Quy Tắc Đánh Giá Tổng Thể

Đánh giá tổng thể của mô hình được xác định dựa trên các quy tắc sau:

1. Nếu bất kỳ chỉ số nào có mức đánh giá **RED**, thì đánh giá tổng thể là **RED**.
2. Nếu không có chỉ số nào ở mức **RED**, nhưng có nhiều hơn 2 chỉ số ở mức **AMBER**, thì đánh giá tổng thể là **RED**.
3. Nếu không có chỉ số nào ở mức **RED**, và có 1-2 chỉ số ở mức **AMBER**, thì đánh giá tổng thể là **AMBER**.
4. Nếu tất cả các chỉ số đều ở mức **GREEN**, thì đánh giá tổng thể là **GREEN**.

## Hành Động Đề Xuất Theo Đánh Giá

### Khi Đánh Giá Tổng Thể là RED

- Xem xét lại mô hình và cân nhắc việc tái huấn luyện hoặc thay thế.
- Phân tích chi tiết các chỉ số có đánh giá RED để xác định nguyên nhân.
- Đánh giá dữ liệu đầu vào và kiểm tra sự thay đổi của dữ liệu theo thời gian.
- Báo cáo cho các bên liên quan về vấn đề hiệu suất của mô hình.

### Khi Đánh Giá Tổng Thể là AMBER

- Tiếp tục sử dụng mô hình nhưng tăng cường giám sát.
- Theo dõi thêm các chỉ số có đánh giá AMBER để đảm bảo chúng không suy giảm thêm.
- Chuẩn bị kế hoạch dự phòng trong trường hợp hiệu suất tiếp tục suy giảm.
- Lên lịch đánh giá lại mô hình trong thời gian sớm hơn thông thường.

### Khi Đánh Giá Tổng Thể là GREEN

- Tiếp tục sử dụng mô hình như bình thường.
- Duy trì lịch đánh giá định kỳ theo quy định.
- Ghi nhận kết quả tốt và chia sẻ bài học kinh nghiệm từ mô hình này.

## Quy Trình Đánh Giá

1. Sau mỗi lần thực hiện đánh giá hiệu suất mô hình, các chỉ số được tính toán và ghi nhận vào bảng `MODEL_VALIDATION_RESULTS`.
2. Thủ tục `EVALUATE_MODEL_PERFORMANCE` được sử dụng để đánh giá các chỉ số dựa trên ngưỡng và xác định đánh giá tổng thể.
3. Kết quả đánh giá được hiển thị trong view `VW_MODEL_PERFORMANCE` để theo dõi và phân tích.
4. Cờ `VALIDATION_THRESHOLD_BREACHED` trong bảng `MODEL_VALIDATION_RESULTS` được cập nhật để đánh dấu các đánh giá có vấn đề.

## Điều Chỉnh Ngưỡng

Các ngưỡng đánh giá có thể được điều chỉnh tùy theo loại mô hình và yêu cầu nghiệp vụ. Các trường ngưỡng được lưu trữ trong bảng `MODEL_VALIDATION_RESULTS`:

- `AUC_THRESHOLD_RED`, `AUC_THRESHOLD_AMBER`
- `KS_THRESHOLD_RED`, `KS_THRESHOLD_AMBER`
- `GINI_THRESHOLD_RED`, `GINI_THRESHOLD_AMBER`
- `PSI_THRESHOLD_RED`, `PSI_THRESHOLD_AMBER`
- `IV_THRESHOLD_RED`, `IV_THRESHOLD_AMBER`
- `KAPPA_THRESHOLD_RED`, `KAPPA_THRESHOLD_AMBER`

Để điều chỉnh ngưỡng cho một lần đánh giá cụ thể, bạn có thể cập nhật các trường này trước khi gọi thủ tục `EVALUATE_MODEL_PERFORMANCE`.

## Kết Luận

Việc sử dụng các ngưỡng đánh giá rõ ràng giúp tổ chức hiểu được hiệu suất của mô hình và đưa ra quyết định kịp thời về việc tiếp tục sử dụng, điều chỉnh hoặc thay thế mô hình. Hệ thống đánh giá này giúp nâng cao chất lượng của các mô hình đánh giá rủi ro, đồng thời đảm bảo tuân thủ các quy định về quản trị mô hình.