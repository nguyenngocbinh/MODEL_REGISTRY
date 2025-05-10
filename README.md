# Hệ Thống Đăng Ký Mô Hình

## Tổng Quan

Hệ Thống Đăng Ký Mô Hình là một giải pháp cơ sở dữ liệu toàn diện để quản lý và theo dõi các mô hình đánh giá rủi ro tín dụng, các nguồn dữ liệu phụ thuộc và tham số thực thi của chúng. Hệ thống này giúp duy trì tài liệu rõ ràng về tất cả các mô hình, bảng dữ liệu đầu vào và đầu ra, cũng như mối quan hệ giữa các thành phần khác nhau trong hệ sinh thái mô hình.

## Tính Năng Chính

- Đăng ký tập trung tất cả các mô hình rủi ro với quản lý phiên bản
- Phân loại mô hình theo loại (PD, LGD, EAD, Scorecard, Segmentation, v.v.)
- Theo dõi chi tiết các nguồn dữ liệu cho từng mô hình
- Quản lý tham số và hệ số của mô hình
- Lập tài liệu về việc áp dụng mô hình cho từng phân khúc khách hàng
- Ghi lại kết quả đánh giá hiệu suất mô hình (GINI, KS, PSI, v.v.)
- Giám sát chất lượng dữ liệu và trạng thái cập nhật
- Hỗ trợ xác thực mô hình và quản trị

## Cấu Trúc Cơ Sở Dữ Liệu

Hệ thống bao gồm nhiều bảng kết nối với nhau, cùng quản lý tất cả các khía cạnh của mô hình rủi ro:

### Bảng Cơ Bản

1. **MODEL_TYPE**: Định nghĩa các loại mô hình (PD, LGD, EAD, Scorecard, EWS, v.v.)
2. **MODEL_REGISTRY**: Kho lưu trữ trung tâm cho tất cả các mô hình rủi ro
3. **MODEL_SOURCE_TABLES**: Danh mục tất cả các bảng dữ liệu được sử dụng bởi các mô hình
4. **MODEL_TABLE_USAGE**: Mối quan hệ nhiều-nhiều giữa mô hình và nguồn dữ liệu
5. **MODEL_PARAMETERS**: Hệ số mô hình và tham số tính toán
6. **MODEL_COLUMN_DETAILS**: Thông tin chi tiết về các cột được sử dụng trong mô hình
7. **MODEL_SEGMENT_MAPPING**: Áp dụng mô hình cho các phân khúc khách hàng cụ thể

### Bảng Giám Sát và Đánh Giá

8. **MODEL_VALIDATION_RESULTS**: Lưu trữ kết quả đánh giá hiệu suất mô hình
9. **MODEL_SOURCE_REFRESH_LOG**: Theo dõi việc cập nhật dữ liệu cho các bảng nguồn
10. **MODEL_DATA_QUALITY_LOG**: Ghi lại các vấn đề về chất lượng dữ liệu

### View và Thủ Tục

- **VW_MODEL_TABLE_RELATIONSHIPS**: View tổng hợp về tất cả các mối quan hệ mô hình-bảng
- **VW_MODEL_TYPE_INFO**: View tổng hợp thông tin về mô hình và loại mô hình
- **GET_MODEL_TABLES**: Lấy tất cả các bảng được sử dụng bởi một mô hình cụ thể
- **GET_TABLE_MODELS**: Lấy tất cả các mô hình sử dụng một bảng cụ thể
- **GET_MODEL_PERFORMANCE_HISTORY**: Lấy lịch sử hiệu suất của mô hình theo thời gian
- **VALIDATE_MODEL_SOURCES**: Xác thực tính khả dụng của dữ liệu nguồn cho một mô hình
- **LOG_SOURCE_TABLE_REFRESH**: Ghi lại trạng thái cập nhật của bảng nguồn
- **GET_APPROPRIATE_MODEL**: Xác định mô hình phù hợp nhất cho một khách hàng

## Chi Tiết Các Bảng Chính

### MODEL_TYPE

Bảng này định nghĩa các loại mô hình khác nhau như:
- Probability of Default (PD)
- Loss Given Default (LGD)
- Exposure at Default (EAD)
- Behavioral Scorecard (Bscore)
- Application Scorecard (Ascore)
- Collection Scorecard (Cscore)
- Early Warning Signals (EWS)
- Segmentation Models

Mỗi loại mô hình có mã duy nhất, tên, mô tả và trạng thái hoạt động.

### MODEL_VALIDATION_RESULTS

Bảng này lưu trữ các chỉ số đo lường hiệu suất của mô hình:
- Gini Coefficient - Area Under the Curve (AUC-ROC)
- Kolmogorov-Smirnov (KS)
- Population Stability Index (PSI)
- Accuracy, Precision, Recall, F1-Score
- Information Value (IV)
- Kappa Score

Mỗi bản ghi bao gồm thông tin về ngày đánh giá, loại đánh giá (phát triển, backtesting, out-of-time, out-of-sample), và giai đoạn đánh giá, cho phép theo dõi hiệu suất mô hình theo thời gian.

## Ví Dụ Sử Dụng

### Tìm Tất Cả Các Bảng Được Sử Dụng Bởi Một Mô Hình

```sql
EXEC EWS.dbo.GET_MODEL_TABLES 'BSCORE_RETAIL';
```

### Tìm Tất Cả Các Mô Hình Sử Dụng Một Bảng Cụ Thể

```sql
EXEC EWS.dbo.GET_TABLE_MODELS 'DMT', 'dbo', 'ifrs9_dep_amt_txn';
```

### Xem Lịch Sử Hiệu Suất Của Một Mô Hình

```sql
EXEC EWS.dbo.GET_MODEL_PERFORMANCE_HISTORY @MODEL_NAME = 'BSCORE_RETAIL';
```

### Xác Thực Nguồn Dữ Liệu Trước Khi Thực Thi Mô Hình

```sql
EXEC EWS.dbo.VALIDATE_MODEL_SOURCES 1, '2023-10-31';
```

### Xác Định Mô Hình Phù Hợp Cho Một Khách Hàng

```sql
EXEC EWS.dbo.GET_APPROPRIATE_MODEL 'CUST12345', '2023-10-31';
```

## Quy Trình Xử Lý Mô Hình

1. **Xác Thực Dữ Liệu Nguồn**: Kiểm tra xem tất cả các bảng nguồn cần thiết đã được cập nhật chưa
2. **Phân Khúc Khách Hàng**: Xác định khách hàng nào sẽ được xử lý bởi mỗi mô hình
3. **Lựa Chọn Mô Hình**: Chọn mô hình tính điểm phù hợp dựa trên thuộc tính của khách hàng
4. **Tính Toán Đặc Trưng**: Tính toán các đặc trưng mô hình từ dữ liệu nguồn
5. **Tính Toán Điểm**: Áp dụng tham số mô hình để tính toán điểm và xác suất
6. **Gán Cấp Độ**: Ánh xạ điểm số thành cấp độ rủi ro sử dụng ngưỡng đã định nghĩa
7. **Lưu Trữ Kết Quả**: Lưu kết quả vào các bảng đầu ra thích hợp
8. **Đánh Giá Hiệu Suất**: Định kỳ đánh giá hiệu suất của mô hình và ghi lại kết quả

## Quy Trình Đánh Giá Mô Hình

Hệ thống hỗ trợ một quy trình đánh giá mô hình toàn diện:

1. **Đánh Giá Ban Đầu**: Trong quá trình phát triển mô hình
2. **Đánh Giá Định Kỳ**: Theo lịch định kỳ (hàng quý, nửa năm, hàng năm)
3. **Đánh Giá Đặc Biệt**: Khi có thay đổi đáng kể trong môi trường hoặc dữ liệu

Mỗi đánh giá bao gồm:
- Tính toán các chỉ số hiệu suất quan trọng
- So sánh với kết quả đánh giá trước đó
- Phân tích sự ổn định của mô hình qua thời gian
- Khuyến nghị về việc tiếp tục sử dụng, hiệu chỉnh, hoặc xây dựng lại mô hình

## Các Vấn Đề Bảo Mật

- Triển khai kiểm soát truy cập dựa trên vai trò
- Tạo dấu vết kiểm toán cho bất kỳ thay đổi nào đối với tham số mô hình
- Xác thực tính nhất quán của dữ liệu nguồn trước khi thực thi mô hình
- Giám sát các chỉ số chất lượng dữ liệu cho tất cả các bảng nguồn

## Tích Hợp Với Hệ Thống EWS Hiện Có

Hệ Thống Đăng Ký Mô Hình được thiết kế để nâng cao Hệ Thống Cảnh Báo Sớm (EWS) hiện có bằng cách cung cấp:

1. Tài liệu tốt hơn về các phụ thuộc của mô hình
2. Dấu vết kiểm toán rõ ràng hơn cho việc tuân thủ quy định
3. Khắc phục sự cố hiệu quả hơn đối với các vấn đề thực thi mô hình
4. Cải thiện quản trị mô hình và kiểm soát phiên bản
5. Theo dõi hiệu suất mô hình theo thời gian

## Hướng Dẫn Bảo Trì

- Thường xuyên xem xét và cập nhật tài liệu mô hình
- Lưu trữ các mô hình không hoạt động thay vì xóa chúng
- Ghi lại bất kỳ thay đổi nào đối với tham số mô hình kèm theo lý do
- Theo dõi xu hướng chất lượng dữ liệu theo thời gian
- Định kỳ (ít nhất hàng quý) đánh giá hiệu suất của các mô hình đang hoạt động
- Thiết lập ngưỡng cảnh báo cho các chỉ số hiệu suất quan trọng (AUC, KS, PSI)
- Xem xét tác động của các thay đổi về môi trường kinh tế lên hiệu suất mô hình

## Quy Trình Quản Lý Vòng Đời Mô Hình

Hệ thống hỗ trợ quản lý toàn bộ vòng đời của mô hình:

1. **Phát Triển**: Lưu trữ tài liệu phát triển, dữ liệu đào tạo và thông số mô hình
2. **Xác Thực**: Ghi lại kết quả đánh giá ban đầu và các thử nghiệm mô hình
3. **Triển Khai**: Quản lý việc triển khai mô hình vào hệ thống sản xuất
4. **Giám Sát**: Theo dõi hiệu suất mô hình liên tục thông qua các chỉ số quan trọng
5. **Tái Huấn Luyện**: Ghi lại việc cập nhật tham số mô hình khi cần thiết
6. **Xây Dựng Lại**: Quản lý quá trình phát triển phiên bản mô hình mới
7. **Ngưng Hoạt Động**: Lưu trữ tài liệu của các mô hình không còn sử dụng

## Cải Tiến Trong Tương Lai

- Tích hợp với hệ thống giám sát hiệu suất mô hình tự động
- Quy trình xác thực mô hình tự động
- Bảng điều khiển trực quan cho các chỉ số sức khỏe mô hình
- Tài liệu nâng cao về kết quả xác thực mô hình
- API cho việc truy cập theo chương trình vào dữ liệu đăng ký mô hình
- Tích hợp với các công cụ machine learning để phân tích xu hướng hiệu suất
- Hệ thống cảnh báo tự động khi hiệu suất mô hình suy giảm

## Báo Cáo và Phân Tích

Hệ thống cung cấp các báo cáo tích hợp để hỗ trợ quản trị mô hình:

1. **Báo Cáo Danh Mục Mô Hình**: Tổng quan về tất cả các mô hình đang hoạt động
2. **Báo Cáo Hiệu Suất Theo Thời Gian**: Theo dõi sự thay đổi của các chỉ số chính theo thời gian
3. **Báo Cáo Phụ Thuộc Dữ Liệu**: Hiển thị mối quan hệ giữa các mô hình và nguồn dữ liệu
4. **Báo Cáo Đánh Giá Chất Lượng**: Phân tích các vấn đề chất lượng dữ liệu ảnh hưởng đến mô hình
5. **Báo Cáo Tuân Thủ**: Hỗ trợ các yêu cầu tuân thủ quy định về quản trị mô hình
