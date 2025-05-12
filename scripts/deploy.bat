@echo off
:: =================================================================
:: Script triển khai Hệ Thống Đăng Ký Mô Hình (Windows)
:: Tác giả: Nguyễn Ngọc Bình
:: Ngày tạo: 2025-05-12
:: Phiên bản: 1.0
:: =================================================================

echo =================================================================
echo             TRIEN KHAI HE THONG DANG KY MO HINH
echo =================================================================
echo.

:: Thiết lập biến môi trường
set SCRIPT_DIR=%~dp0
set DATABASE_NAME=MODEL_REGISTRY
set SQL_INSTANCE=localhost

:: Yêu cầu người dùng xác nhận thông tin kết nối
echo THONG TIN KET NOI:
echo ------------------
set /p SQL_INSTANCE=Ten SQL Server (mac dinh: localhost): 
set /p SQL_USER=Ten dang nhap (Enter de dung Windows Authentication): 
set /p DATABASE_NAME=Ten database (mac dinh: MODEL_REGISTRY): 

:: Thiết lập chuỗi kết nối dựa trên phương thức xác thực
set CONNECTION_STRING=-S %SQL_INSTANCE%
if "%SQL_USER%"=="" (
    echo Su dung Windows Authentication...
) else (
    set /p SQL_PASSWORD=Mat khau: 
    set CONNECTION_STRING=%CONNECTION_STRING% -U %SQL_USER% -P %SQL_PASSWORD%
)

:: Quay lại thư mục gốc của dự án (giả sử script nằm trong thư mục scripts)
cd %SCRIPT_DIR%\..\

:: Hiển thị thông tin cài đặt
echo.
echo THONG TIN CAI DAT:
echo ------------------
echo SQL Server: %SQL_INSTANCE%
echo Database: %DATABASE_NAME%
echo Thu muc du an: %CD%
echo.
set /p CONFIRM=Ban co muon tien hanh cai dat? (Y/N): 

if /I NOT "%CONFIRM%"=="Y" (
    echo Cai dat da bi huy.
    goto :EOF
)

echo.
echo Dang trien khai he thong...
echo ------------------

:: Kiểm tra kết nối đến SQL Server
echo Kiem tra ket noi SQL Server...
sqlcmd %CONNECTION_STRING% -Q "SELECT @@VERSION" -b
if %ERRORLEVEL% NEQ 0 (
    echo Khong the ket noi den SQL Server. Vui long kiem tra thong tin ket noi.
    goto :EOF
)

:: Kiểm tra xem database đã tồn tại chưa
echo Kiem tra database %DATABASE_NAME%...
sqlcmd %CONNECTION_STRING% -Q "IF DB_ID('%DATABASE_NAME%') IS NULL PRINT 'NOT_EXIST' ELSE PRINT 'EXIST'" -h-1 > temp.txt
set /p DB_EXISTS=<temp.txt
del temp.txt

:: Tạo database nếu chưa tồn tại
if "%DB_EXISTS%"=="NOT_EXIST" (
    echo Dang tao database %DATABASE_NAME%...
    sqlcmd %CONNECTION_STRING% -Q "CREATE DATABASE [%DATABASE_NAME%]" -b
    if %ERRORLEVEL% NEQ 0 (
        echo Khong the tao database. Vui long kiem tra quyen han va thu lai.
        goto :EOF
    )
) else (
    echo Database %DATABASE_NAME% da ton tai.
    set /p OVERWRITE=Ban co muon cai dat de len database hien co? (Y/N): 
    if /I NOT "%OVERWRITE%"=="Y" (
        echo Cai dat da bi huy.
        goto :EOF
    )
)

echo.
echo Dang cai dat cau truc co so du lieu...
echo ------------------

:: Chạy script cài đặt chính
echo Dang chay script cai dat...
sqlcmd %CONNECTION_STRING% -d %DATABASE_NAME% -i install_all.sql -b
if %ERRORLEVEL% NEQ 0 (
    echo Loi khi cai dat. Vui long xem thong bao loi phia tren.
    goto :EOF
)

echo.
echo =================================================================
echo           CAI DAT HE THONG DANG KY MO HINH THANH CONG!
echo =================================================================
echo.
echo Thong tin quan trong:
echo * Database: %DATABASE_NAME%
echo * Thu muc co so: %CD%
echo * Cac bao cao co san trong thu muc: %CD%\reports
echo.
echo De kiem tra cai dat, hay mo SQL Server Management Studio va ket noi
echo den SQL Server %SQL_INSTANCE%, sau do kiem tra database %DATABASE_NAME%.
echo.

pause