# BÁO CÁO HỆ THỐNG ĐĂNG KÝ MÔ HÌNH

## Tổng Quan

Thư mục `reports` chứa các tập tin SQL dùng để tạo báo cáo theo dõi và quản lý mô hình trong Hệ Thống Đăng Ký Mô Hình. Các báo cáo này cung cấp thông tin toàn diện về danh mục mô hình, hiệu suất mô hình theo thời gian, và chất lượng dữ liệu đầu vào. Các báo cáo được thiết kế để hỗ trợ quản trị mô hình, đánh giá rủi ro, và tuân thủ các quy định liên quan.

## Danh Sách Báo Cáo

### 1. model_inventory_report.sql

**Mô tả**: Báo cáo danh mục mô hình trong hệ thống, cung cấp thông tin tổng quan về tất cả các mô hình.

**Mục đích**: Giúp theo dõi tổng thể các mô hình trong hệ thống, trạng thái hoạt động, loại mô hình, và mối quan hệ với nguồn dữ liệu.

**Nội dung chính**:
- **Thống kê tổng quan**: Số lượng mô hình theo loại và phân khúc
- **Danh sách chi tiết mô hình**: Liệt kê tất cả các mô hình với thông tin cơ bản
- **Chi tiết mô hình đang hoạt động**: Thông tin chi tiết về các mô hình đang hoạt động
- **Mô hình sắp hết hạn**: Danh sách các mô hình sẽ hết hạn trong vòng 90 ngày tới
- **Mô hình có vấn đề về hiệu suất**: Danh sách các mô hình có cảnh báo về hiệu suất
- **Thống kê bảng dữ liệu**: Số lượng bảng dữ liệu theo loại và tình trạng cập nhật
- **Thống kê mối quan hệ mô hình - bảng dữ liệu**: Phân tích mối quan hệ giữa mô hình và dữ liệu
- **Mô hình mới/cập nhật gần đây**: Mô hình được tạo mới hoặc cập nhật trong 30 ngày qua
- **Thống kê theo người tạo**: Phân tích mô hình theo người phát triển

**Đối tượng sử dụng**: Quản lý rủi ro, Quản trị mô hình, Kiểm toán, Ban lãnh đạo

**Tần suất sử dụng**: Hàng tháng hoặc theo yêu cầu

### 2. model_performance_report.sql

**Mô tả**: Báo cáo hiệu suất của các mô hình theo thời gian, tập trung vào các chỉ số đánh giá và xu hướng.

**Mục đích**: Giúp đánh giá hiệu quả của các mô hình, phát hiện sự suy giảm hiệu suất, và đưa ra quyết định về việc tái huấn luyện hoặc thay thế mô hình.

**Nội dung chính**:
- **Thống kê tổng quan về hiệu suất**: Số lượng mô hình theo mức đánh giá hiệu suất
- **Thống kê hiệu suất theo loại và phân khúc**: Phân tích hiệu suất theo nhóm
- **Chi tiết hiệu suất các mô hình**: Các chỉ số hiệu suất chính của từng mô hình
- **Mô hình có hiệu suất suy giảm**: So sánh hiệu suất hiện tại với lần đánh giá trước
- **Xu hướng hiệu suất theo thời gian**: Phân tích xu hướng hiệu suất cho các mô hình có nhiều lần đánh giá
- **Phân tích hiệu suất theo quý**: Hiệu suất mô hình theo quý trong năm hiện tại
- **Đề xuất hành động**: Các hành động cần thực hiện với mô hình có vấn đề
- **Lịch đánh giá tiếp theo**: Dự kiến ngày đánh giá tiếp theo cho các mô hình

**Đối tượng sử dụng**: Nhóm phát triển mô hình, Quản trị mô hình, Quản lý rủi ro

**Tần suất sử dụng**: Hàng quý hoặc sau mỗi đợt đánh giá hiệu suất

### 3. data_quality_report.sql

**Mô tả**: Báo cáo chất lượng dữ liệu của các bảng nguồn sử dụng bởi các mô hình, tập trung vào các vấn đề chất lượng dữ liệu và tác động của chúng.

**Mục đích**: Giúp giám sát chất lượng dữ liệu đầu vào, xác định và ưu tiên xử lý các vấn đề chất lượng dữ liệu ảnh hưởng đến mô hình.

**Nội dung chính**:
- **Thống kê tổng quan chất lượng dữ liệu**: Số lượng bảng dữ liệu theo điểm chất lượng
- **Thống kê chất lượng theo loại bảng**: Phân tích chất lượng dữ liệu theo loại bảng
- **Chi tiết chất lượng từng bảng**: Thông tin chi tiết về chất lượng của từng bảng dữ liệu
- **Trạng thái cập nhật dữ liệu**: Thông tin về lần cập nhật gần nhất của các bảng
- **Các vấn đề chất lượng dữ liệu nghiêm trọng**: Danh sách các vấn đề cần ưu tiên xử lý
- **Tất cả các vấn đề chất lượng dữ liệu**: Danh sách đầy đủ các vấn đề đang mở
- **Thống kê vấn đề theo loại**: Phân tích vấn đề chất lượng dữ liệu theo loại
- **Tác động đến các mô hình**: Phân tích ảnh hưởng của vấn đề chất lượng dữ liệu đến mô hình
- **Đề xuất hành động**: Các bảng cần ưu tiên cải thiện chất lượng
- **Lịch làm mới dữ liệu**: Đề xuất kế hoạch cập nhật dữ liệu

**Đối tượng sử dụng**: Nhóm quản lý dữ liệu, Nhóm vận hành, Quản trị mô hình

**Tần suất sử dụng**: Hàng tuần hoặc hàng tháng

## Cách Sử Dụng Báo Cáo

### Môi Trường Thực Thi

Các báo cáo SQL được thiết kế để chạy trong môi trường SQL Server. Báo cáo có thể được thực thi thông qua:
- SQL Server Management Studio (SSMS)
- Azure Data Studio
- Công cụ tích hợp báo cáo khác (SQL Server Reporting Services, Power BI, Tableau, v.v.)

### Thực Thi Báo Cáo

Để thực thi một báo cáo:

1. Kết nối đến cơ sở dữ liệu MODEL_REGISTRY
2. Mở tập tin báo cáo cần thực thi (ví dụ: model_inventory_report.sql)
3. Thực thi báo cáo (execute) để xem kết quả

### Tùy Chỉnh Báo Cáo

Mỗi báo cáo có thể được tùy chỉnh theo nhu cầu cụ thể bằng cách:
- Điều chỉnh các tham số ngày tháng trong các phần truy vấn
- Thêm hoặc loại bỏ các phần truy vấn tùy theo nhu cầu
- Thay đổi tiêu chí sắp xếp hoặc lọc dữ liệu

### Kết Xuất Báo Cáo

Kết quả báo cáo có thể được kết xuất dưới nhiều định dạng khác nhau:
- Bảng tính Excel để phân tích thêm
- Tệp PDF để chia sẻ với các bên liên quan
- Tích hợp vào bảng điều khiển (dashboard) trong Power BI hoặc Tableau
- Gửi theo lịch định kỳ qua email

## Lập Lịch Báo Cáo

Các báo cáo có thể được lập lịch chạy tự động theo định kỳ. Dưới đây là đề xuất lịch thực thi:

- **model_inventory_report.sql**: Chạy vào ngày đầu tiên của mỗi tháng
- **model_performance_report.sql**: Chạy sau mỗi đợt đánh giá hiệu suất (thường là hàng quý)
- **data_quality_report.sql**: Chạy vào ngày thứ Hai hàng tuần hoặc ngày đầu tiên của mỗi tháng

Việc lập lịch có thể thực hiện thông qua:
- SQL Server Agent Jobs
- Công cụ quản lý nhiệm vụ (Task Scheduler)
- Công cụ điều phối quy trình (ETL/workflow orchestration tools)

## Các Chỉ Số Chính Cần Theo Dõi

### Danh Mục Mô Hình
- Số lượng mô hình đang hoạt động
- Tỷ lệ mô hình hết hạn hoặc sắp hết hạn
- Phân bố mô hình theo loại và phân khúc

### Hiệu Suất Mô Hình
- Tỷ lệ mô hình có hiệu suất tốt/cảnh báo/kém
- Số lượng mô hình có xu hướng suy giảm hiệu suất
- Chỉ số GINI, KS, PSI trung bình của các mô hình

### Chất Lượng Dữ Liệu
- Số lượng vấn đề chất lượng dữ liệu nghiêm trọng
- Số lượng bảng có điểm chất lượng thấp
- Tỷ lệ bảng dữ liệu được cập nhật đúng hạn

## Luồng Công Việc Quản Trị Mô Hình

Các báo cáo này hỗ trợ quy trình quản trị mô hình sau:

1. **Theo Dõi Danh Mục**: Sử dụng model_inventory_report.sql để theo dõi tổng thể danh mục mô hình
2. **Đánh Giá Hiệu Suất**: Sử dụng model_performance_report.sql để đánh giá hiệu suất mô hình định kỳ
3. **Giám Sát Chất Lượng Dữ Liệu**: Sử dụng data_quality_report.sql để theo dõi và xử lý vấn đề chất lượng dữ liệu
4. **Phân Tích Tác Động**: Kết hợp cả ba báo cáo để xác định mối quan hệ giữa chất lượng dữ liệu và hiệu suất mô hình
5. **Đưa Ra Quyết Định**: Dựa trên các báo cáo để đưa ra quyết định về việc duy trì, tái huấn luyện, hoặc thay thế mô hình

## Tùy Chỉnh và Mở Rộng

Các báo cáo này có thể được mở rộng hoặc tùy chỉnh để đáp ứng nhu cầu cụ thể:

- **Tích hợp với bảng điều khiển trực quan**: Chuyển đổi các báo cáo SQL thành bảng điều khiển trực quan
- **Báo cáo bổ sung**: Phát triển thêm các báo cáo chuyên sâu cho những khía cạnh cụ thể
- **Cảnh báo tự động**: Thiết lập cảnh báo dựa trên các ngưỡng được định nghĩa trong báo cáo
- **Tích hợp với quy trình làm việc**: Tự động hóa việc tạo và phân phối báo cáo trong quy trình làm việc

## Lưu Ý và Thực Hành Tốt Nhất

- Luôn xem xét các mô hình có cảnh báo hiệu suất trước tiên
- Ưu tiên xử lý các vấn đề chất lượng dữ liệu ảnh hưởng đến nhiều mô hình
- Lưu trữ lịch sử báo cáo để theo dõi xu hướng theo thời gian
- Thường xuyên rà soát và cập nhật các ngưỡng đánh giá trong báo cáo
- Kết hợp đánh giá định tính và định lượng khi đưa ra quyết định về mô hình