@echo off
:: =================================================================
:: Script triển khai Hệ Thống Đăng Ký Mô Hình (Windows)
:: Tác giả: Nguyễn Ngọc Bình
:: Ngày tạo: 2025-05-12
:: Phiên bản: 1.2 - Optimized without overlap with install_all.sql
:: =================================================================

echo =================================================================
echo             TRIEN KHAI HE THONG DANG KY MO HINH
echo =================================================================
echo.

:: Thiết lập biến môi trường
set SCRIPT_DIR=%~dp0
set DATABASE_NAME=MODEL_REGISTRY
set SQL_INSTANCE=localhost
set LOG_DIR=%SCRIPT_DIR%..\logs
set TIMESTAMP=%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%
set LOG_FILE=%LOG_DIR%\deploy_%TIMESTAMP%.log

:: Tạo thư mục logs nếu chưa tồn tại
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

:: Bắt đầu ghi log
echo [%date% %time%] Bắt đầu triển khai Hệ Thống Đăng Ký Mô Hình > "%LOG_FILE%"

:: Yêu cầu người dùng xác nhận thông tin kết nối
echo THONG TIN KET NOI:
echo ------------------
set /p SQL_INSTANCE=Ten SQL Server (mac dinh: localhost): 
set /p SQL_USER=Ten dang nhap (Enter de dung Windows Authentication): 
set /p DATABASE_NAME=Ten database (mac dinh: MODEL_REGISTRY): 

:: Ghi log thông tin kết nối
echo [%date% %time%] Thông tin kết nối: >> "%LOG_FILE%"
echo [%date% %time%] - SQL Server: %SQL_INSTANCE% >> "%LOG_FILE%"
echo [%date% %time%] - Người dùng: %SQL_USER% >> "%LOG_FILE%"
echo [%date% %time%] - Database: %DATABASE_NAME% >> "%LOG_FILE%"

:: Thiết lập chuỗi kết nối dựa trên phương thức xác thực
set CONNECTION_STRING=-S %SQL_INSTANCE%
if "%SQL_USER%"=="" (
    echo Su dung Windows Authentication...
    echo [%date% %time%] Sử dụng Windows Authentication >> "%LOG_FILE%"
) else (
    set /p SQL_PASSWORD=Mat khau: 
    set CONNECTION_STRING=%CONNECTION_STRING% -U %SQL_USER% -P %SQL_PASSWORD%
    echo [%date% %time%] Sử dụng SQL Authentication với người dùng: %SQL_USER% >> "%LOG_FILE%"
)

:: Quay lại thư mục gốc của dự án (giả sử script nằm trong thư mục scripts)
cd %SCRIPT_DIR%\..\
echo [%date% %time%] Thư mục dự án: %CD% >> "%LOG_FILE%"

:: Hiển thị thông tin cài đặt
echo.
echo THONG TIN CAI DAT:
echo ------------------
echo SQL Server: %SQL_INSTANCE%
echo Database: %DATABASE_NAME%
echo Thu muc du an: %CD%
echo Thu muc log: %LOG_DIR%
echo File log: %LOG_FILE%
echo.
set /p CONFIRM=Ban co muon tien hanh cai dat? (Y/N): 

if /I NOT "%CONFIRM%"=="Y" (
    echo Cai dat da bi huy.
    echo [%date% %time%] Cài đặt đã bị hủy bởi người dùng >> "%LOG_FILE%"
    goto :EOF
)

echo.
echo Dang trien khai he thong...
echo ------------------
echo [%date% %time%] Đang triển khai hệ thống... >> "%LOG_FILE%"

:: Kiểm tra kết nối đến SQL Server
echo Kiem tra ket noi SQL Server...
echo [%date% %time%] Kiểm tra kết nối SQL Server... >> "%LOG_FILE%"
sqlcmd %CONNECTION_STRING% -Q "SELECT @@VERSION" -b >> "%LOG_FILE%" 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Khong the ket noi den SQL Server. Vui long kiem tra thong tin ket noi.
    echo [%date% %time%] Lỗi: Không thể kết nối đến SQL Server. Mã lỗi: %ERRORLEVEL% >> "%LOG_FILE%"
    goto :EOF
)
echo [%date% %time%] Kết nối SQL Server thành công >> "%LOG_FILE%"

:: Kiểm tra xem database đã tồn tại chưa
echo Kiem tra database %DATABASE_NAME%...
echo [%date% %time%] Kiểm tra database %DATABASE_NAME%... >> "%LOG_FILE%"
sqlcmd %CONNECTION_STRING% -Q "IF DB_ID('%DATABASE_NAME%') IS NULL PRINT 'NOT_EXIST' ELSE PRINT 'EXIST'" -h-1 > temp.txt
set /p DB_EXISTS=<temp.txt
del temp.txt
echo [%date% %time%] Kết quả kiểm tra database: %DB_EXISTS% >> "%LOG_FILE%"

:: Tạo database nếu chưa tồn tại
if "%DB_EXISTS%"=="NOT_EXIST" (
    echo Dang tao database %DATABASE_NAME%...
    echo [%date% %time%] Đang tạo database %DATABASE_NAME%... >> "%LOG_FILE%"
    sqlcmd %CONNECTION_STRING% -Q "CREATE DATABASE [%DATABASE_NAME%]" -b >> "%LOG_FILE%" 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo Khong the tao database. Vui long kiem tra quyen han va thu lai.
        echo [%date% %time%] Lỗi: Không thể tạo database. Mã lỗi: %ERRORLEVEL% >> "%LOG_FILE%"
        goto :EOF
    )
    echo [%date% %time%] Tạo database %DATABASE_NAME% thành công >> "%LOG_FILE%"
) else (
    echo Database %DATABASE_NAME% da ton tai.
    echo [%date% %time%] Database %DATABASE_NAME% đã tồn tại >> "%LOG_FILE%"
    set /p OVERWRITE=Ban co muon cai dat de len database hien co? (Y/N): 
    echo [%date% %time%] Yêu cầu xác nhận cài đặt đè lên database hiện có >> "%LOG_FILE%"
    
    if /I NOT "%OVERWRITE%"=="Y" (
        echo Cai dat da bi huy.
        echo [%date% %time%] Cài đặt đã bị hủy bởi người dùng >> "%LOG_FILE%"
        goto :EOF
    )
    echo [%date% %time%] Xác nhận cài đặt đè lên database hiện có >> "%LOG_FILE%"
)

echo.
echo Dang cai dat cau truc co so du lieu...
echo ------------------
echo [%date% %time%] Bắt đầu cài đặt cấu trúc cơ sở dữ liệu... >> "%LOG_FILE%"

:: Chạy script cài đặt chính với tham số log file
echo Dang chay script cai dat...
echo [%date% %time%] Đang chạy script install_all.sql... >> "%LOG_FILE%"

:: Truyền đường dẫn file log cho install_all.sql
sqlcmd %CONNECTION_STRING% -d %DATABASE_NAME% -i install_all.sql -v LogFilePath="%LOG_FILE%" -b >> "%LOG_FILE%" 2>&1

:: Kiểm tra lỗi
if %ERRORLEVEL% NEQ 0 (
    echo Loi khi cai dat. Vui long xem thong bao loi tai file log %LOG_FILE%.
    echo [%date% %time%] Lỗi: Quá trình cài đặt không thành công. Mã lỗi: %ERRORLEVEL% >> "%LOG_FILE%"
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
echo * File log: %LOG_FILE%
echo.
echo De kiem tra cai dat, hay mo SQL Server Management Studio va ket noi
echo den SQL Server %SQL_INSTANCE%, sau do kiem tra database %DATABASE_NAME%.
echo.

echo [%date% %time%] Cài đặt Hệ Thống Đăng Ký Mô Hình hoàn thành thành công >> "%LOG_FILE%"

pause