#!/bin/bash
# =================================================================
# Script triển khai Hệ Thống Đăng Ký Mô Hình (Linux/Unix)
# Tác giả: Nguyễn Ngọc Bình
# Ngày tạo: 2025-05-12
# Phiên bản: 1.0
# =================================================================

echo "================================================================="
echo "             TRIỂN KHAI HỆ THỐNG ĐĂNG KÝ MÔ HÌNH"
echo "================================================================="
echo ""

# Thiết lập biến môi trường
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
DATABASE_NAME="MODEL_REGISTRY"
SQL_INSTANCE="localhost"

# Kiểm tra xem sqlcmd có được cài đặt không
if ! command -v sqlcmd &> /dev/null; then
    echo "Lỗi: Công cụ sqlcmd không được tìm thấy."
    echo "Vui lòng cài đặt SQL Server Command Line Tools trước khi tiếp tục."
    exit 1
fi

# Yêu cầu người dùng xác nhận thông tin kết nối
echo "THÔNG TIN KẾT NỐI:"
echo "------------------"
read -p "Tên SQL Server (mặc định: localhost): " input_sql_instance
SQL_INSTANCE=${input_sql_instance:-$SQL_INSTANCE}

read -p "Tên đăng nhập (Enter để dùng Windows Authentication): " SQL_USER

read -p "Tên database (mặc định: MODEL_REGISTRY): " input_database_name
DATABASE_NAME=${input_database_name:-$DATABASE_NAME}

# Thiết lập chuỗi kết nối dựa trên phương thức xác thực
CONNECTION_STRING="-S $SQL_INSTANCE"
if [ -z "$SQL_USER" ]; then
    echo "Sử dụng Windows Authentication..."
    # Thêm tham số -E cho Windows Authentication nếu cần
    CONNECTION_STRING="$CONNECTION_STRING -E"
else
    read -s -p "Mật khẩu: " SQL_PASSWORD
    echo ""
    CONNECTION_STRING="$CONNECTION_STRING -U $SQL_USER -P $SQL_PASSWORD"
fi

# Quay lại thư mục gốc của dự án (giả sử script nằm trong thư mục scripts)
cd "$SCRIPT_DIR/.."

# Hiển thị thông tin cài đặt
echo ""
echo "THÔNG TIN CÀI ĐẶT:"
echo "------------------"
echo "SQL Server: $SQL_INSTANCE"
echo "Database: $DATABASE_NAME"
echo "Thư mục dự án: $(pwd)"
echo ""
read -p "Bạn có muốn tiến hành cài đặt? (Y/N): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Cài đặt đã bị hủy."
    exit 0
fi

echo ""
echo "Đang triển khai hệ thống..."
echo "------------------"

# Kiểm tra kết nối đến SQL Server
echo "Kiểm tra kết nối SQL Server..."
sqlcmd $CONNECTION_STRING -Q "SELECT @@VERSION" -b
if [ $? -ne 0 ]; then
    echo "Không thể kết nối đến SQL Server. Vui lòng kiểm tra thông tin kết nối."
    exit 1
fi

# Kiểm tra xem database đã tồn tại chưa
echo "Kiểm tra database $DATABASE_NAME..."
DB_EXISTS=$(sqlcmd $CONNECTION_STRING -Q "IF DB_ID('$DATABASE_NAME') IS NULL PRINT 'NOT_EXIST' ELSE PRINT 'EXIST'" -h -1)

# Tạo database nếu chưa tồn tại
if [[ "$DB_EXISTS" == *"NOT_EXIST"* ]]; then
    echo "Đang tạo database $DATABASE_NAME..."
    sqlcmd $CONNECTION_STRING -Q "CREATE DATABASE [$DATABASE_NAME]" -b
    if [ $? -ne 0 ]; then
        echo "Không thể tạo database. Vui lòng kiểm tra quyền hạn và thử lại."
        exit 1
    fi
else
    echo "Database $DATABASE_NAME đã tồn tại."
    read -p "Bạn có muốn cài đặt đè lên database hiện có? (Y/N): " OVERWRITE
    if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
        echo "Cài đặt đã bị hủy."
        exit 0
    fi
fi

echo ""
echo "Đang cài đặt cấu trúc cơ sở dữ liệu..."
echo "------------------"

# Chạy script cài đặt chính
echo "Đang chạy script cài đặt..."
sqlcmd $CONNECTION_STRING -d $DATABASE_NAME -i install_all.sql -b
if [ $? -ne 0 ]; then
    echo "Lỗi khi cài đặt. Vui lòng xem thông báo lỗi phía trên."
    exit 1
fi

echo ""
echo "================================================================="
echo "           CÀI ĐẶT HỆ THỐNG ĐĂNG KÝ MÔ HÌNH THÀNH CÔNG!"
echo "================================================================="
echo ""
echo "Thông tin quan trọng:"
echo "* Database: $DATABASE_NAME"
echo "* Thư mục cơ sở: $(pwd)"
echo "* Các báo cáo có sẵn trong thư mục: $(pwd)/reports"
echo ""
echo "Để kiểm tra cài đặt, hãy mở SQL Server Management Studio và kết nối"
echo "đến SQL Server $SQL_INSTANCE, sau đó kiểm tra database $DATABASE_NAME."
echo ""

# Cấp quyền thực thi cho script
chmod +x "$SCRIPT_DIR/deploy.sh"