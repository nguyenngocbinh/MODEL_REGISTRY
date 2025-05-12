# Hướng Dẫn Quản Trị Hệ Thống Đăng Ký Mô Hình

## Giới Thiệu

Tài liệu này cung cấp hướng dẫn chi tiết cho quản trị viên hệ thống Đăng Ký Mô Hình (Model Registry). Các quản trị viên sẽ học cách thiết lập, cấu hình và bảo trì hệ thống, quản lý người dùng và quyền truy cập, cũng như thực hiện các tác vụ giám sát và khắc phục sự cố.

## Mục Lục

1. [Tổng Quan về Quản Trị Hệ Thống](#tổng-quan-về-quản-trị-hệ-thống)
2. [Quản Lý Người Dùng và Phân Quyền](#quản-lý-người-dùng-và-phân-quyền)
3. [Cấu Hình Hệ Thống](#cấu-hình-hệ-thống)
4. [Quản Lý Dữ Liệu](#quản-lý-dữ-liệu)
5. [Giám Sát và Ghi Nhật Ký](#giám-sát-và-ghi-nhật-ký)
6. [Sao Lưu và Phục Hồi](#sao-lưu-và-phục-hồi)
7. [Bảo Mật Hệ Thống](#bảo-mật-hệ-thống)
8. [Khắc Phục Sự Cố](#khắc-phục-sự-cố)
9. [Nâng Cấp và Bảo Trì](#nâng-cấp-và-bảo-trì)

## Tổng Quan về Quản Trị Hệ Thống

### Các Thành Phần Hệ Thống

Hệ thống Đăng Ký Mô Hình gồm các thành phần chính sau:

1. **Cơ sở dữ liệu SQL Server**: Lưu trữ tất cả dữ liệu mô hình, tham số và kết quả đánh giá
2. **Ứng dụng web**: Giao diện người dùng để tương tác với hệ thống
3. **Dịch vụ API**: Cung cấp các API cho ứng dụng khác gọi
4. **Dịch vụ tích hợp**: Kết nối với các hệ thống khác để đồng bộ dữ liệu
5. **Hệ thống báo cáo**: Tạo và phân phối báo cáo tự động

### Vai Trò Quản Trị Viên

Quản trị viên hệ thống có các trách nhiệm sau:

- Thiết lập và cấu hình hệ thống
- Quản lý người dùng và phân quyền
- Giám sát hiệu suất hệ thống
- Bảo trì và sao lưu dữ liệu
- Khắc phục sự cố
- Quản lý cấu hình và tham số hệ thống
- Đảm bảo tuân thủ các chính sách bảo mật

## Quản Lý Người Dùng và Phân Quyền

### Mô Hình Phân Quyền

Hệ thống sử dụng mô hình phân quyền dựa trên vai trò (Role-Based Access Control - RBAC) với các vai trò mặc định:

1. **Quản trị viên hệ thống (System Administrator)**:
   - Quyền truy cập đầy đủ vào tất cả chức năng
   - Quản lý người dùng và phân quyền
   - Cấu hình hệ thống

2. **Quản trị viên mô hình (Model Administrator)**:
   - Quản lý danh mục mô hình
   - Phê duyệt thay đổi mô hình và tham số
   - Xem tất cả báo cáo

3. **Phát triển mô hình (Model Developer)**:
   - Tạo và cập nhật mô hình
   - Thực hiện đánh giá mô hình
   - Xem các mô hình thuộc phạm vi của họ

4. **Người dùng thông thường (Regular User)**:
   - Xem thông tin mô hình
   - Xem báo cáo
   - Không có quyền thay đổi

5. **Kiểm toán (Auditor)**:
   - Truy cập chỉ đọc vào tất cả thông tin
   - Xem nhật ký hệ thống và lịch sử thay đổi

### Thêm Người Dùng Mới

1. Đăng nhập với tài khoản quản trị viên
2. Chọn "Quản lý người dùng" từ menu quản trị
3. Nhấn "Thêm người dùng mới"
4. Điền thông tin người dùng:
   - Tên người dùng (Username)
   - Họ tên đầy đủ
   - Email liên hệ
   - Số điện thoại (tùy chọn)
   - Phòng ban
5. Chọn phương thức xác thực:
   - Xác thực Windows (khuyến nghị)
   - Xác thực cơ sở dữ liệu (nếu cần)
6. Gán vai trò cho người dùng
7. Nhấn "Lưu" để tạo người dùng

### Quản Lý Vai Trò và Quyền

1. Chọn "Quản lý vai trò" từ menu quản trị
2. Để tạo vai trò mới:
   - Nhấn "Thêm vai trò mới"
   - Nhập tên và mô tả vai trò
   - Chọn các quyền cho vai trò
   - Nhấn "Lưu"
3. Để sửa vai trò hiện có:
   - Nhấn vào tên vai trò
   - Chỉnh sửa quyền
   - Nhấn "Lưu thay đổi"
4. Để gán vai trò cho người dùng:
   - Chọn "Quản lý người dùng"
   - Nhấn vào tên người dùng
   - Ở tab "Vai trò", thêm hoặc xóa vai trò
   - Nhấn "Lưu thay đổi"

### Quản Lý Quyền Theo Phân Khúc

Hệ thống hỗ trợ phân quyền chi tiết theo phân khúc (mô hình, loại mô hình, phân khúc khách hàng):

1. Chọn "Quyền theo phân khúc" từ menu quản trị
2. Chọn vai trò cần cấu hình
3. Chọn các phân khúc mà vai trò này có quyền truy cập
4. Nhấn "Lưu"

Ví dụ: Một người phát triển mô hình có thể chỉ được truy cập mô hình Retail, trong khi người khác có thể chỉ truy cập mô hình Corporate.

## Cấu Hình Hệ Thống

### Tham Số Hệ Thống

1. Chọn "Cấu hình hệ thống" từ menu quản trị
2. Các nhóm tham số cấu hình:
   - **Tham số chung**: Tên hệ thống, URL, logo
   - **Cấu hình email**: Máy chủ SMTP, địa chỉ gửi
   - **Cấu hình báo cáo**: Thư mục lưu báo cáo, định dạng mặc định
   - **Cấu hình tích hợp**: Kết nối API, hệ thống bên ngoài
   - **Cấu hình hiệu suất**: Kích thước cache, timeout
   - **Ngưỡng cảnh báo**: Ngưỡng cho các chỉ số đánh giá mô hình

3. Thay đổi cấu hình:
   - Chọn nhóm tham số
   - Sửa giá trị tham số
   - Nhấn "Lưu thay đổi"

### Tùy Chỉnh Giao Diện

1. Chọn "Tùy chỉnh giao diện" từ menu quản trị
2. Tải lên logo tổ chức
3. Chọn bảng màu và phông chữ
4. Tùy chỉnh trang chủ:
   - Tiêu đề và thông điệp chào mừng
   - Các widget hiển thị trên trang chủ
5. Nhấn "Xem trước" để kiểm tra
6. Nhấn "Lưu" để áp dụng thay đổi

### Cấu Hình Thông Báo

1. Chọn "Cấu hình thông báo" từ menu quản trị
2. Cấu hình các kênh thông báo:
   - Email
   - Ứng dụng (trong hệ thống)
   - SMS (nếu có)
   - Tích hợp với hệ thống tin nhắn nội bộ
3. Cấu hình các loại thông báo:
   - Cảnh báo hiệu suất mô hình
   - Sắp hết hạn mô hình
   - Vấn đề chất lượng dữ liệu
   - Thay đổi tham số mô hình
4. Cấu hình mẫu thông báo:
   - Chọn loại thông báo
   - Chỉnh sửa mẫu (tiêu đề, nội dung)
   - Kiểm tra thử bằng cách nhấn "Gửi thử"
5. Nhấn "Lưu" để áp dụng thay đổi

## Quản Lý Dữ Liệu

### Quản Lý Mô Hình

1. **Nhập mô hình mới**:
   - Chọn "Quản lý mô hình" từ menu quản trị
   - Nhấn "Thêm mô hình mới"
   - Nhập thông tin mô hình hoặc nhập từ tệp (XML, JSON)
   - Nhấn "Lưu" để thêm mô hình

2. **Xóa mô hình**:
   - Chọn mô hình từ danh sách
   - Nhấn "Xóa mô hình"
   - Xác nhận hành động
   - Lưu ý: Nên vô hiệu hóa mô hình thay vì xóa để duy trì lịch sử

3. **Khóa/mở khóa mô hình**:
   - Chọn mô hình từ danh sách
   - Nhấn "Khóa" để ngăn chỉnh sửa
   - Nhấn "Mở khóa" để cho phép chỉnh sửa

4. **Phê duyệt thay đổi**:
   - Xem danh sách các thay đổi đang chờ phê duyệt
   - Kiểm tra chi tiết thay đổi
   - Chọn "Phê duyệt" hoặc "Từ chối"
   - Nhập bình luận khi cần

### Quản Lý Loại Mô Hình

1. Chọn "Loại mô hình" từ menu quản trị
2. Xem danh sách các loại mô hình hiện có
3. Để thêm loại mới:
   - Nhấn "Thêm loại mới"
   - Nhập mã loại, tên và mô tả
   - Nhấn "Lưu"
4. Để chỉnh sửa:
   - Nhấn vào tên loại
   - Sửa thông tin
   - Nhấn "Lưu thay đổi"

### Quản Lý Bảng Dữ Liệu

1. Chọn "Quản lý bảng dữ liệu" từ menu quản trị
2. Xem danh sách các bảng đã đăng ký
3. Để thêm bảng mới:
   - Nhấn "Thêm bảng mới"
   - Nhập thông tin bảng
   - Nhấn "Lưu"
4. Để cập nhật thông tin bảng:
   - Nhấn vào tên bảng
   - Sửa thông tin
   - Nhấn "Lưu thay đổi"
5. Để quét tự động cấu trúc bảng:
   - Chọn bảng từ danh sách
   - Nhấn "Quét cấu trúc"
   - Xác nhận để cập nhật thông tin cột

### Quản Lý Lịch Sử Thay Đổi

1. Chọn "Lịch sử thay đổi" từ menu quản trị
2. Lọc lịch sử theo:
   - Loại đối tượng (Mô hình, Tham số, Bảng dữ liệu)
   - Khoảng thời gian
   - Người thực hiện
3. Xem chi tiết thay đổi:
   - Nhấn vào sự kiện thay đổi
   - Xem giá trị trước và sau khi thay đổi
4. Xuất báo cáo lịch sử thay đổi:
   - Cấu hình bộ lọc
   - Nhấn "Xuất báo cáo"
   - Chọn định dạng (Excel, PDF)

### Dọn Dẹp Dữ Liệu

1. Chọn "Bảo trì dữ liệu" từ menu quản trị
2. Các tùy chọn dọn dẹp:
   - Lưu trữ lịch sử đánh giá cũ
   - Xóa bản ghi nhật ký cũ
   - Lưu trữ mô hình hết hạn
   - Tối ưu hóa cơ sở dữ liệu
3. Lên lịch dọn dẹp tự động:
   - Cấu hình quy tắc dọn dẹp
   - Chọn tần suất
   - Nhấn "Lưu lịch"

## Giám Sát và Ghi Nhật Ký

### Giám Sát Hiệu Suất Hệ Thống

1. Chọn "Giám sát hệ thống" từ menu quản trị
2. Bảng điều khiển hiển thị:
   - Tình trạng dịch vụ
   - Thời gian phản hồi
   - Sử dụng tài nguyên (CPU, bộ nhớ, đĩa)
   - Số lượng phiên hoạt động
   - Thời gian chạy

3. Cài đặt cảnh báo hiệu suất:
   - Nhấn "Cấu hình cảnh báo"
   - Thiết lập ngưỡng cho các chỉ số
   - Chọn kênh thông báo
   - Nhấn "Lưu"

### Xem Nhật Ký Hệ Thống

1. Chọn "Nhật ký hệ thống" từ menu quản trị
2. Lọc nhật ký theo:
   - Mức độ (Thông tin, Cảnh báo, Lỗi, Nghiêm trọng)
   - Thành phần (Web, Cơ sở dữ liệu, API)
   - Khoảng thời gian
   - Người dùng
3. Xem chi tiết sự kiện:
   - Nhấn vào sự kiện để xem thông tin đầy đủ
   - Xem ngăn xếp lỗi (nếu có)
4. Xuất nhật ký:
   - Cấu hình bộ lọc
   - Nhấn "Xuất nhật ký"
   - Chọn định dạng (CSV, Excel)

### Theo Dõi Hoạt Động Người Dùng

1. Chọn "Theo dõi hoạt động" từ menu quản trị
2. Xem danh sách các phiên đăng nhập:
   - Thời gian đăng nhập/đăng xuất
   - IP và thiết bị
   - Các hoạt động chính
3. Lọc theo người dùng hoặc thời gian
4. Phát hiện hoạt động bất thường:
   - Đăng nhập không thành công nhiều lần
   - Truy cập ngoài giờ làm việc
   - Truy cập từ địa điểm lạ

### Cấu Hình Ghi Nhật Ký

1. Chọn "Cấu hình nhật ký" từ menu quản trị
2. Cấu hình mức ghi nhật ký:
   - Toàn hệ thống
   - Theo thành phần
3. Cấu hình lưu trữ nhật ký:
   - Thời gian lưu giữ
   - Vị trí lưu trữ
   - Luân chuyển tệp nhật ký
4. Cấu hình tích hợp nhật ký:
   - Gửi nhật ký đến máy chủ Syslog
   - Tích hợp với hệ thống giám sát trung tâm
5. Nhấn "Lưu" để áp dụng thay đổi

## Sao Lưu và Phục Hồi

### Cấu Hình Sao Lưu Tự Động

1. Chọn "Quản lý sao lưu" từ menu quản trị
2. Cấu hình lịch sao lưu:
   - Sao lưu đầy đủ: Tuần một lần
   - Sao lưu gia tăng: Hàng ngày
   - Sao lưu nhật ký giao dịch: Mỗi giờ
3. Cấu hình vị trí lưu trữ:
   - Thư mục local
   - Ổ đĩa mạng
   - Dịch vụ lưu trữ đám mây
4. Cấu hình tùy chọn nén và mã hóa
5. Thiết lập chính sách lưu giữ:
   - Số lượng bản sao lưu giữ lại
   - Thời gian lưu giữ (ngày, tuần, tháng)
6. Nhấn "Lưu" để áp dụng cấu hình

### Thực Hiện Sao Lưu Thủ Công

1. Chọn "Quản lý sao lưu" từ menu quản trị
2. Nhấn "Sao lưu ngay"
3. Chọn loại sao lưu:
   - Đầy đủ
   - Chỉ dữ liệu
   - Chỉ cấu hình
4. Nhập mô tả cho bản sao lưu
5. Chọn vị trí lưu trữ
6. Nhấn "Bắt đầu sao lưu"
7. Theo dõi tiến trình sao lưu

### Phục Hồi Từ Bản Sao Lưu

1. Chọn "Quản lý sao lưu" từ menu quản trị
2. Chọn tab "Phục hồi"
3. Chọn bản sao lưu từ danh sách
4. Chọn chế độ phục hồi:
   - Phục hồi toàn bộ
   - Phục hồi cơ sở dữ liệu
   - Phục hồi cấu hình
5. Chọn vị trí phục hồi (phục hồi tại chỗ hoặc hệ thống mới)
6. Nhấn "Bắt đầu phục hồi"
7. Xác nhận hành động
8. Theo dõi tiến trình phục hồi

### Kiểm Tra Tính Toàn Vẹn Sao Lưu

1. Chọn "Quản lý sao lưu" từ menu quản trị
2. Chọn tab "Xác thực"
3. Chọn bản sao lưu cần kiểm tra
4. Nhấn "Kiểm tra tính toàn vẹn"
5. Hệ thống sẽ xác thực bản sao lưu và báo cáo kết quả
6. Tùy chọn: Nhấn "Kiểm tra khả năng phục hồi" để thử nghiệm phục hồi vào môi trường thử

## Bảo Mật Hệ Thống

### Cấu Hình Bảo Mật

1. Chọn "Cấu hình bảo mật" từ menu quản trị
2. Cấu hình chính sách mật khẩu:
   - Độ dài tối thiểu
   - Độ phức tạp (chữ thường, chữ hoa, số, ký tự đặc biệt)
   - Thời gian hết hạn
   - Lịch sử mật khẩu (không lặp lại N mật khẩu gần nhất)
3. Cấu hình phiên làm việc:
   - Thời gian chờ không hoạt động
   - Số lượng phiên đồng thời tối đa
   - Khóa tài khoản sau N lần đăng nhập thất bại
4. Cấu hình mã hóa:
   - Mã hóa dữ liệu nhạy cảm
   - Quản lý khóa mã hóa
5. Cấu hình HTTPS và chứng chỉ SSL
6. Nhấn "Lưu" để áp dụng cấu hình

### Quản Lý Chứng Chỉ

1. Chọn "Quản lý chứng chỉ" từ menu quản trị
2. Xem danh sách chứng chỉ hiện tại
3. Để thêm chứng chỉ mới:
   - Nhấn "Thêm chứng chỉ mới"
   - Tải lên tệp chứng chỉ và khóa
   - Nhập mật khẩu khóa (nếu có)
   - Nhấn "Lưu"
4. Để cập nhật chứng chỉ:
   - Chọn chứng chỉ từ danh sách
   - Nhấn "Cập nhật"
   - Tải lên chứng chỉ mới
   - Nhấn "Lưu"
5. Hệ thống sẽ thông báo khi chứng chỉ sắp hết hạn

### Kiểm Toán Bảo Mật

1. Chọn "Kiểm toán bảo mật" từ menu quản trị
2. Các kiểm tra bảo mật:
   - Kiểm tra cấu hình hệ thống
   - Quét lỗ hổng
   - Kiểm tra kiểm soát truy cập
   - Xem xét nhật ký bảo mật
3. Để thực hiện kiểm toán:
   - Chọn loại kiểm toán
   - Nhấn "Bắt đầu kiểm toán"
   - Xem báo cáo và khuyến nghị
4. Xuất báo cáo kiểm toán:
   - Nhấn "Xuất báo cáo"
   - Chọn định dạng (PDF, Excel)

## Khắc Phục Sự Cố

### Công Cụ Chẩn Đoán

1. Chọn "Công cụ chẩn đoán" từ menu quản trị
2. Các công cụ có sẵn:
   - Kiểm tra kết nối cơ sở dữ liệu
   - Kiểm tra dịch vụ API
   - Kiểm tra tích hợp email
   - Kiểm tra hiệu suất hệ thống
   - Kiểm tra nhất quán dữ liệu
3. Để sử dụng công cụ:
   - Chọn công cụ từ danh sách
   - Nhấn "Chạy chẩn đoán"
   - Xem kết quả và khuyến nghị

### Xử Lý Lỗi Phổ Biến

1. **Lỗi kết nối cơ sở dữ liệu**:
   - Kiểm tra chuỗi kết nối trong tệp cấu hình
   - Xác nhận tài khoản SQL có quyền truy cập
   - Kiểm tra tường lửa và mạng

2. **Lỗi đăng nhập**:
   - Kiểm tra cấu hình xác thực
   - Xác nhận người dùng tồn tại và không bị khóa
   - Kiểm tra tích hợp Active Directory (nếu sử dụng)

3. **Lỗi API**:
   - Kiểm tra nhật ký API
   - Xác nhận cấu hình endpoint
   - Kiểm tra token xác thực

4. **Lỗi gửi email**:
   - Kiểm tra cấu hình SMTP
   - Xác nhận tài khoản email
   - Kiểm tra kết nối đến máy chủ mail

5. **Lỗi báo cáo**:
   - Kiểm tra thư mục báo cáo có quyền ghi
   - Xác nhận mẫu báo cáo tồn tại
   - Kiểm tra dịch vụ báo cáo đang chạy

### Công Cụ Hỗ Trợ Từ Xa

1. Chọn "Hỗ trợ từ xa" từ menu quản trị
2. Các tùy chọn:
   - Xuất thông tin chẩn đoán
   - Tạo phiên hỗ trợ an toàn
   - Tải lên nhật ký để phân tích
3. Để xuất gói chẩn đoán:
   - Chọn phạm vi thông tin (hệ thống, cơ sở dữ liệu, nhật ký)
   - Nhập mô tả vấn đề
   - Nhấn "Tạo gói" để xuất thông tin
   - Gửi gói cho đội hỗ trợ

## Nâng Cấp và Bảo Trì

### Quy Trình Nâng Cấp

1. **Chuẩn bị nâng cấp**:
   - Tải phiên bản mới từ cổng hỗ trợ
   - Đọc ghi chú phát hành và hướng dẫn nâng cấp
   - Sao lưu hệ thống hiện tại
   - Thông báo cho người dùng về lịch bảo trì

2. **Thực hiện nâng cấp**:
   - Đăng nhập với tài khoản quản trị
   - Chọn "Quản lý nâng cấp" từ menu quản trị
   - Nhấn "Tải lên gói nâng cấp"
   - Chọn tệp nâng cấp đã tải xuống
   - Nhấn "Kiểm tra tương thích" để xác nhận
   - Nhấn "Bắt đầu nâng cấp"
   - Theo dõi tiến trình nâng cấp

3. **Kiểm tra sau nâng cấp**:
   - Xác nhận dịch vụ đang chạy
   - Kiểm tra phiên bản hệ thống
   - Thực hiện kiểm tra cơ bản
   - Xem nhật ký để phát hiện lỗi

4. **Khắc phục sự cố nâng cấp**:
   - Nếu gặp lỗi, xem nhật ký nâng cấp
   - Thử khởi động lại dịch vụ
   - Liên hệ hỗ trợ kỹ thuật nếu cần
   - Thực hiện phục hồi từ bản sao lưu nếu cần thiết

### Bảo Trì Định Kỳ

1. **Lên lịch bảo trì**:
   - Chọn "Lịch bảo trì" từ menu quản trị
   - Thiết lập lịch định kỳ (hàng tuần, hàng tháng)
   - Cấu hình thông báo cho người dùng
   - Nhấn "Lưu lịch"

2. **Tác vụ bảo trì khuyến nghị**:
   - Sao lưu cơ sở dữ liệu
   - Dọn dẹp dữ liệu tạm
   - Tối ưu hóa cơ sở dữ liệu
   - Cập nhật chỉ mục
   - Kiểm tra nhất quán dữ liệu
   - Xem xét và xóa nhật ký cũ

3. **Bảo trì thủ công**:
   - Chọn "Bảo trì thủ công" từ menu quản trị
   - Chọn các tác vụ cần thực hiện
   - Nhấn "Bắt đầu bảo trì"
   - Theo dõi tiến trình và kết quả

## Phụ Lục

### Tài Nguyên Bổ Sung

- [Trang hỗ trợ kỹ thuật](#)
- [Tài liệu API](#)
- [Cổng thông tin khách hàng](#)
- [Cộng đồng người dùng](#)

### Thông Tin Liên Hệ Hỗ Trợ

- **Hỗ trợ kỹ thuật**: support@model-registry.example.com
- **Điện thoại hỗ trợ khẩn cấp**: +84 xxx xxx xxx
- **Thời gian hỗ trợ**: 8:00 - 18:00 từ thứ Hai đến thứ Sáu

### Danh Sách Kiểm Tra Bảo Trì

- [ ] Sao lưu cơ sở dữ liệu
- [ ] Kiểm tra không gian đĩa
- [ ] Xem xét nhật ký lỗi
- [ ] Xác minh dịch vụ đang chạy
- [ ] Kiểm tra các tác vụ đang chờ
- [ ] Dọn dẹp nhật ký cũ
- [ ] Kiểm tra chứng chỉ SSL
- [ ] Xem xét quyền người dùng
- [ ] Kiểm tra hiệu suất hệ thống