# SCRIPTS HỖ TRỢ HỆ THỐNG ĐĂNG KÝ MÔ HÌNH

## Tổng Quan

Thư mục `scripts` chứa các tập tin script hỗ trợ việc triển khai, cài đặt và gỡ bỏ Hệ Thống Đăng Ký Mô Hình. Các script này giúp tự động hóa các quy trình triển khai và quản lý hệ thống, giảm thiểu khả năng xảy ra lỗi và tiết kiệm thời gian so với việc thực hiện thủ công các bước cài đặt.

## Danh Sách Scripts

### 1. deploy.bat

**Mô tả**: Script triển khai Hệ Thống Đăng Ký Mô Hình trên nền tảng Windows.

**Ngôn ngữ**: Windows Batch Script (.bat)

**Chức năng chính**:
- Thiết lập kết nối đến SQL Server với tùy chọn Windows Authentication hoặc SQL Authentication
- Tự động tạo database mới hoặc cập nhật database hiện có (với xác nhận từ người dùng)
- Thực thi script cài đặt chính (install_all.sql) để tạo cấu trúc cơ sở dữ liệu
- Hiển thị thông tin về trạng thái cài đặt và hướng dẫn kiểm tra

**Cách sử dụng**:
```
.\scripts\deploy.bat
```

**Các tham số tương tác**:
- **SQL Server**: Tên SQL Server để kết nối (mặc định: localhost)
- **Tên đăng nhập**: Tài khoản SQL Server (để trống để sử dụng Windows Authentication)
- **Mật khẩu**: Mật khẩu cho tài khoản SQL Server (nếu sử dụng SQL Authentication)
- **Database**: Tên database (mặc định: MODEL_REGISTRY)
- **Xác nhận**: Yêu cầu xác nhận trước khi tiến hành cài đặt

**Yêu cầu**:
- SQL Server Command Line Tools (sqlcmd) đã được cài đặt
- Quyền tạo và chỉnh sửa database trên SQL Server
- Quyền thực thi script trong thư mục dự án

### 2. deploy.sh

**Mô tả**: Script triển khai Hệ Thống Đăng Ký Mô Hình trên nền tảng Linux/Unix.

**Ngôn ngữ**: Bash Shell Script (.sh)

**Chức năng chính**:
- Tương tự như deploy.bat nhưng được tối ưu hóa cho môi trường Linux/Unix
- Kiểm tra sự hiện diện của công cụ sqlcmd trước khi tiến hành
- Tự động cấp quyền thực thi cho chính nó (chmod +x)
- Hỗ trợ cả SQL Authentication và Windows Authentication

**Cách sử dụng**:
```bash
./scripts/deploy.sh
```
Hoặc nếu chưa có quyền thực thi:
```bash
bash ./scripts/deploy.sh
```

**Các tham số tương tác**: 
Tương tự như deploy.bat

**Yêu cầu**:
- SQL Server Command Line Tools (sqlcmd) đã được cài đặt trên hệ thống Linux/Unix
- Quyền thực thi script (chmod +x)
- Quyền tạo và chỉnh sửa database trên SQL Server
- Quyền thực thi script trong thư mục dự án

### 3. uninstall.sql

**Mô tả**: Script SQL để gỡ bỏ toàn bộ Hệ Thống Đăng Ký Mô Hình.

**Ngôn ngữ**: Transact-SQL (.sql)

**Chức năng chính**:
- Xóa tất cả các đối tượng của hệ thống (triggers, functions, stored procedures, views, tables)
- Tuân theo thứ tự xóa hợp lý dựa trên phụ thuộc để tránh lỗi
- Tùy chọn xóa hoàn toàn database hoặc chỉ xóa các đối tượng bên trong
- Hiển thị thông báo tiến trình chi tiết

**Cách sử dụng**:
1. Mở script trong SQL Server Management Studio hoặc Azure Data Studio
2. Thay đổi biến `@CONFIRM` từ 'NO' thành 'YES' để xác nhận gỡ bỏ
3. Tùy chọn: Thay đổi biến `@DROP_DATABASE` từ 'NO' thành 'YES' nếu muốn xóa toàn bộ database
4. Thực thi script

**Các biến cấu hình**:
- `@CONFIRM`: Xác nhận gỡ bỏ các đối tượng (phải đặt thành 'YES' để thực thi)
- `@DROP_DATABASE`: Xác nhận xóa toàn bộ database (phải đặt thành 'YES' để xóa database)

**Lưu ý quan trọng**:
- Script này sẽ xóa vĩnh viễn tất cả dữ liệu và không thể phục hồi. Chỉ sử dụng khi chắc chắn muốn loại bỏ hoàn toàn hệ thống.
- Nên sao lưu dữ liệu trước khi thực thi script này.

## Quy Trình Triển Khai Hệ Thống

### Cài Đặt Mới

1. Chuẩn bị máy chủ SQL Server với quyền admin
2. Tải mã nguồn của dự án về máy
3. Chạy script deploy.bat (Windows) hoặc deploy.sh (Linux/Unix)
4. Nhập thông tin kết nối khi được yêu cầu
5. Xác nhận quá trình cài đặt
6. Kiểm tra cài đặt bằng cách kết nối đến database vừa tạo

### Nâng Cấp Hệ Thống Hiện Có

1. Sao lưu database hiện tại
2. Chạy script deploy.bat (Windows) hoặc deploy.sh (Linux/Unix)
3. Nhập thông tin kết nối và tên database hiện có
4. Xác nhận việc cài đặt đè lên database hiện tại
5. Kiểm tra database sau khi nâng cấp

### Gỡ Bỏ Hệ Thống

1. Sao lưu database (nếu cần)
2. Mở script uninstall.sql trong công cụ quản lý SQL
3. Thay đổi biến @CONFIRM thành 'YES'
4. Tùy chọn: Thay đổi biến @DROP_DATABASE thành 'YES' nếu muốn xóa database
5. Thực thi script
6. Xác nhận các đối tượng đã được xóa thành công

## Sửa Đổi Scripts

Các script có thể được tùy chỉnh để phù hợp với môi trường cụ thể:

### deploy.bat / deploy.sh

- Thay đổi giá trị mặc định cho SERVER, DATABASE
- Thêm các tham số kết nối bổ sung cho sqlcmd
- Thêm các bước cài đặt tùy chỉnh sau khi tạo cấu trúc cơ bản

### uninstall.sql

- Thay đổi thứ tự xóa các đối tượng nếu có thêm các phụ thuộc mới
- Thêm logic để sao lưu dữ liệu trước khi xóa
- Tùy chỉnh thông báo và cảnh báo

## Thực Hành Tốt Nhất

- Luôn sao lưu database trước khi chạy bất kỳ script triển khai hoặc gỡ bỏ nào
- Chạy thử scripts trên môi trường thử nghiệm trước khi áp dụng cho môi trường sản xuất
- Kiểm tra kỹ lưỡng các thông báo lỗi và nhật ký sau khi thực thi scripts
- Thực hiện lại việc triển khai nếu gặp lỗi thay vì tiếp tục với cài đặt không hoàn chỉnh
- Lưu giữ bản sao của các scripts gốc trước khi tùy chỉnh

## Xử Lý Sự Cố

### Lỗi Kết Nối SQL Server

- Kiểm tra thông tin kết nối (SERVER, USERNAME, PASSWORD)
- Đảm bảo SQL Server đang chạy và có thể truy cập từ máy thực thi script
- Xác minh rằng người dùng có đủ quyền tạo và chỉnh sửa database

### Lỗi Thực Thi Script

- Kiểm tra nhật ký lỗi được hiển thị trong quá trình thực thi
- Đảm bảo cấu trúc thư mục dự án không bị thay đổi
- Kiểm tra quyền truy cập tệp và thư mục

### Lỗi Trong Quá Trình Gỡ Bỏ

- Đảm bảo không có kết nối đang hoạt động đến database
- Kiểm tra quyền của người dùng đối với các đối tượng cần xóa
- Thử xóa thủ công các đối tượng theo thứ tự phụ thuộc

## Kết Luận

Các script hỗ trợ trong thư mục `scripts` cung cấp phương tiện tự động hóa và nhất quán để triển khai, nâng cấp và gỡ bỏ Hệ Thống Đăng Ký Mô Hình. Bằng cách tuân theo các hướng dẫn và thực hành tốt nhất được mô tả trong tài liệu này, việc quản lý vòng đời của hệ thống sẽ trở nên đơn giản và ít rủi ro hơn.