# MÔ TẢ CÁC STORED PROCEDURE

## Tổng Quan

Các stored procedure trong Hệ Thống Đăng Ký Mô Hình cung cấp các chức năng chính để tương tác với cơ sở dữ liệu và thực hiện các tác vụ quản lý mô hình, quản lý nguồn dữ liệu, và xác định mô hình phù hợp nhất cho khách hàng. Tài liệu này mô tả chi tiết về các stored procedure chính, tham số đầu vào, và cách sử dụng chúng.

## Danh Sách Các Stored Procedure

### 1. GET_MODEL_TABLES

**Mô tả**: Lấy danh sách tất cả các bảng dữ liệu được sử dụng bởi một mô hình.

**Tham số đầu vào**:
- `@MODEL_ID` (INT, tùy chọn): ID của mô hình cần truy vấn
- `@MODEL_NAME` (NVARCHAR(100), tùy chọn): Tên của mô hình cần truy vấn
- `@MODEL_VERSION` (NVARCHAR(20), tùy chọn): Phiên bản của mô hình 
- `@AS_OF_DATE` (DATE, tùy chọn): Ngày tham chiếu, mặc định là ngày hiện tại
- `@INCLUDE_INACTIVE` (BIT, tùy chọn): Có bao gồm các bảng không hoạt động không, mặc định là 0

**Kết quả trả về**:
1. Thông tin cơ bản về mô hình
2. Danh sách các bảng dữ liệu được sử dụng bởi mô hình, bao gồm trạng thái, ngày cập nhật cuối cùng
3. Thông tin về các cột là đặc trưng của mô hình
4. Danh sách các vấn đề chất lượng dữ liệu gần đây liên quan đến các bảng này

**Ví dụ sử dụng**:
```sql
-- Lấy danh sách bảng cho mô hình có tên là 'BSCORE_RETAIL'
EXEC MODEL_REGISTRY.dbo.GET_MODEL_TABLES @MODEL_NAME = 'BSCORE_RETAIL';

-- Lấy danh sách bảng cho mô hình có ID là 1 tại một ngày cụ thể
EXEC MODEL_REGISTRY.dbo.GET_MODEL_TABLES @MODEL_ID = 1, @AS_OF_DATE = '2025-01-01';
```

### 2. GET_TABLE_MODELS

**Mô tả**: Lấy danh sách tất cả các mô hình sử dụng một bảng dữ liệu cụ thể.

**Tham số đầu vào**:
- `@DATABASE_NAME` (NVARCHAR(128)): Tên database chứa bảng
- `@SCHEMA_NAME` (NVARCHAR(128)): Tên schema chứa bảng
- `@TABLE_NAME` (NVARCHAR(128)): Tên bảng
- `@AS_OF_DATE` (DATE, tùy chọn): Ngày tham chiếu, mặc định là ngày hiện tại
- `@INCLUDE_INACTIVE` (BIT, tùy chọn): Có bao gồm các mô hình không hoạt động không, mặc định là 0

**Kết quả trả về**:
1. Thông tin chi tiết về bảng dữ liệu
2. Danh sách các cột được theo dõi
3. Danh sách các mô hình sử dụng bảng này
4. Danh sách các vấn đề chất lượng dữ liệu gần đây liên quan đến bảng này

**Ví dụ sử dụng**:
```sql
-- Lấy danh sách mô hình sử dụng bảng ifrs9_dep_amt_txn
EXEC MODEL_REGISTRY.dbo.GET_TABLE_MODELS 
    @DATABASE_NAME = 'DATA', 
    @SCHEMA_NAME = 'dbo', 
    @TABLE_NAME = 'ifrs9_dep_amt_txn';
```

### 3. VALIDATE_MODEL_SOURCES

**Mô tả**: Kiểm tra tính khả dụng của các bảng nguồn cho một mô hình. Procedure này rất hữu ích để xác định xem mô hình có thể thực thi được không.

**Tham số đầu vào**:
- `@MODEL_ID` (INT, tùy chọn): ID của mô hình cần kiểm tra
- `@MODEL_NAME` (NVARCHAR(100), tùy chọn): Tên của mô hình cần kiểm tra
- `@MODEL_VERSION` (NVARCHAR(20), tùy chọn): Phiên bản của mô hình
- `@PROCESS_DATE` (DATE, tùy chọn): Ngày xử lý, mặc định là ngày hiện tại
- `@DETAILED_RESULTS` (BIT, tùy chọn): Có trả về kết quả chi tiết không, mặc định là 1
- `@CHECK_DATA_QUALITY` (BIT, tùy chọn): Có kiểm tra chất lượng dữ liệu không, mặc định là 1

**Kết quả trả về**:
1. Thông tin tổng hợp về trạng thái của mô hình (READY, NOT_READY_CRITICAL_ISSUES, READY_WITH_WARNINGS, v.v.)
2. Nếu @DETAILED_RESULTS = 1, trả về thông tin chi tiết về từng bảng nguồn
3. Nếu @CHECK_DATA_QUALITY = 1 và có vấn đề chất lượng dữ liệu, trả về thông tin chi tiết về các vấn đề

**Ví dụ sử dụng**:
```sql
-- Kiểm tra nguồn dữ liệu cho mô hình có tên 'BSCORE_RETAIL'
EXEC MODEL_REGISTRY.dbo.VALIDATE_MODEL_SOURCES 
    @MODEL_NAME = 'BSCORE_RETAIL', 
    @PROCESS_DATE = '2025-03-31';

-- Kiểm tra nguồn dữ liệu cho mô hình có ID là 1 mà không kiểm tra chất lượng dữ liệu
EXEC MODEL_REGISTRY.dbo.VALIDATE_MODEL_SOURCES 
    @MODEL_ID = 1, 
    @CHECK_DATA_QUALITY = 0;
```

### 4. LOG_SOURCE_TABLE_REFRESH

**Mô tả**: Ghi nhật ký cập nhật dữ liệu nguồn. Procedure này được sử dụng để theo dõi quá trình cập nhật dữ liệu cho các bảng nguồn, từ đó giúp xác định tính sẵn sàng của dữ liệu.

**Tham số đầu vào**:
- `@SOURCE_DATABASE` (NVARCHAR(128)): Tên database chứa bảng
- `@SOURCE_SCHEMA` (NVARCHAR(128)): Tên schema chứa bảng
- `@SOURCE_TABLE_NAME` (NVARCHAR(128)): Tên bảng
- `@PROCESS_DATE` (DATE): Ngày xử lý
- `@REFRESH_STATUS` (NVARCHAR(20)): Trạng thái cập nhật: 'STARTED', 'COMPLETED', 'FAILED', 'PARTIAL'
- `@REFRESH_TYPE` (NVARCHAR(50), tùy chọn): Loại cập nhật: 'FULL', 'INCREMENTAL', 'DELTA', 'RESTATEMENT'
- `@REFRESH_METHOD` (NVARCHAR(50), tùy chọn): Phương thức cập nhật: 'ETL', 'MANUAL', 'SCHEDULED'
- `@RECORDS_PROCESSED` (INT, tùy chọn): Số lượng bản ghi đã xử lý
- `@RECORDS_INSERTED` (INT, tùy chọn): Số lượng bản ghi đã chèn
- `@RECORDS_UPDATED` (INT, tùy chọn): Số lượng bản ghi đã cập nhật
- `@RECORDS_DELETED` (INT, tùy chọn): Số lượng bản ghi đã xóa
- `@RECORDS_REJECTED` (INT, tùy chọn): Số lượng bản ghi bị từ chối
- `@DATA_VOLUME_MB` (DECIMAL(10,2), tùy chọn): Kích thước dữ liệu tính bằng MB
- `@ERROR_MESSAGE` (NVARCHAR(MAX), tùy chọn): Thông báo lỗi nếu có
- `@ERROR_DETAILS` (NVARCHAR(MAX), tùy chọn): Chi tiết lỗi nếu có
- `@AUTO_COMPLETE` (BIT, tùy chọn): Tự động đánh dấu hoàn thành nếu trước đó đã bắt đầu, mặc định là 0

**Kết quả trả về**:
1. Thông tin về bản ghi cập nhật vừa được tạo hoặc cập nhật
2. Nếu trạng thái là COMPLETED, trả về danh sách các mô hình sử dụng bảng này

**Ví dụ sử dụng**:
```sql
-- Ghi nhật ký bắt đầu cập nhật dữ liệu
EXEC MODEL_REGISTRY.dbo.LOG_SOURCE_TABLE_REFRESH 
    @SOURCE_DATABASE = 'DATA', 
    @SOURCE_SCHEMA = 'dbo', 
    @SOURCE_TABLE_NAME = 'ifrs9_dep_amt_txn',
    @PROCESS_DATE = '2025-03-31',
    @REFRESH_STATUS = 'STARTED',
    @REFRESH_TYPE = 'FULL',
    @REFRESH_METHOD = 'ETL';

-- Ghi nhật ký hoàn thành cập nhật dữ liệu
EXEC MODEL_REGISTRY.dbo.LOG_SOURCE_TABLE_REFRESH 
    @SOURCE_DATABASE = 'DATA', 
    @SOURCE_SCHEMA = 'dbo', 
    @SOURCE_TABLE_NAME = 'ifrs9_dep_amt_txn',
    @PROCESS_DATE = '2025-03-31',
    @REFRESH_STATUS = 'COMPLETED',
    @RECORDS_PROCESSED = 1000000,
    @RECORDS_INSERTED = 950000,
    @RECORDS_UPDATED = 50000,
    @RECORDS_DELETED = 0,
    @DATA_VOLUME_MB = 256.75;
```

### 5. GET_APPROPRIATE_MODEL

**Mô tả**: Xác định mô hình phù hợp nhất cho một khách hàng dựa trên các thuộc tính và tiêu chí phân khúc.

**Tham số đầu vào**:
- `@CUSTOMER_ID` (NVARCHAR(50)): ID của khách hàng
- `@PROCESS_DATE` (DATE, tùy chọn): Ngày xử lý, mặc định là ngày hiện tại
- `@MODEL_TYPE_CODE` (NVARCHAR(20), tùy chọn): Mã loại mô hình cần tìm (PD, LGD, EAD, v.v.)
- `@MODEL_CATEGORY` (NVARCHAR(50), tùy chọn): Danh mục mô hình (Retail, Corporate, v.v.)
- `@CUSTOMER_ATTRIBUTES` (NVARCHAR(MAX), tùy chọn): Chuỗi JSON chứa các thuộc tính của khách hàng
- `@DEBUG` (BIT, tùy chọn): Hiển thị thông tin gỡ lỗi, mặc định là 0

**Kết quả trả về**:
1. Thông tin về mô hình phù hợp nhất
2. Danh sách các mô hình phù hợp khác (5 mô hình có điểm cao tiếp theo)

**Ví dụ sử dụng**:
```sql
-- Tìm mô hình phù hợp nhất cho khách hàng
EXEC MODEL_REGISTRY.dbo.GET_APPROPRIATE_MODEL 
    @CUSTOMER_ID = 'CUST12345',
    @MODEL_TYPE_CODE = 'PD',
    @MODEL_CATEGORY = 'Retail',
    @CUSTOMER_ATTRIBUTES = '{"segment": "KHCN", "product_type": "LN_MORTGAGE", "mob": 12, "dpd": 0}';

-- Tìm mô hình phù hợp nhất với thông tin gỡ lỗi
EXEC MODEL_REGISTRY.dbo.GET_APPROPRIATE_MODEL 
    @CUSTOMER_ID = 'CUST12345',
    @PROCESS_DATE = '2025-03-31',
    @DEBUG = 1;
```

### 6. GET_MODEL_PERFORMANCE_HISTORY

**Mô tả**: Lấy lịch sử hiệu suất của một mô hình theo thời gian.

**Tham số đầu vào**:
- `@MODEL_ID` (INT, tùy chọn): ID của mô hình cần truy vấn
- `@MODEL_NAME` (NVARCHAR(100), tùy chọn): Tên của mô hình cần truy vấn
- `@START_DATE` (DATE, tùy chọn): Ngày bắt đầu khoảng thời gian, mặc định là 2 năm trước
- `@END_DATE` (DATE, tùy chọn): Ngày kết thúc khoảng thời gian, mặc định là ngày hiện tại
- `@VALIDATION_TYPE` (NVARCHAR(50), tùy chọn): Loại đánh giá cần lọc
- `@INCLUDE_DETAILS` (BIT, tùy chọn): Có hiển thị chi tiết không, mặc định là 0

**Kết quả trả về**:
1. Thông tin cơ bản về mô hình
2. Danh sách các kết quả đánh giá hiệu suất theo thời gian
3. Nếu @INCLUDE_DETAILS = 1, hiển thị thêm chi tiết như ma trận nhầm lẫn, dữ liệu đường cong ROC, v.v.
4. Tóm tắt xu hướng hiệu suất

**Ví dụ sử dụng**:
```sql
-- Lấy lịch sử hiệu suất mô hình trong 6 tháng gần đây
EXEC MODEL_REGISTRY.dbo.GET_MODEL_PERFORMANCE_HISTORY 
    @MODEL_NAME = 'BSCORE_RETAIL',
    @START_DATE = DATEADD(MONTH, -6, GETDATE()),
    @INCLUDE_DETAILS = 1;

-- Lấy lịch sử hiệu suất mô hình theo loại đánh giá
EXEC MODEL_REGISTRY.dbo.GET_MODEL_PERFORMANCE_HISTORY 
    @MODEL_ID = 1,
    @VALIDATION_TYPE = 'OUT_OF_TIME';
```

## Cách Sử Dụng Các Stored Procedure Trong Quy Trình

### Quy Trình Quản Lý Dữ Liệu

1. Ghi nhật ký bắt đầu cập nhật dữ liệu bằng `LOG_SOURCE_TABLE_REFRESH` với trạng thái 'STARTED'
2. Thực hiện ETL hoặc cập nhật dữ liệu
3. Ghi nhật ký hoàn thành cập nhật dữ liệu bằng `LOG_SOURCE_TABLE_REFRESH` với trạng thái 'COMPLETED'
4. Kiểm tra tính sẵn sàng của dữ liệu cho các mô hình bằng `VALIDATE_MODEL_SOURCES`

### Quy Trình Xử Lý Mô Hình

1. Kiểm tra tính sẵn sàng của dữ liệu bằng `VALIDATE_MODEL_SOURCES`
2. Xác định mô hình phù hợp cho từng khách hàng bằng `GET_APPROPRIATE_MODEL`
3. Thực thi mô hình
4. Ghi nhận kết quả và đánh giá hiệu suất

### Quy Trình Quản Trị Mô Hình

1. Theo dõi lịch sử hiệu suất mô hình bằng `GET_MODEL_PERFORMANCE_HISTORY`
2. Quản lý phụ thuộc dữ liệu bằng `GET_MODEL_TABLES` và `GET_TABLE_MODELS`
3. Đánh giá tác động của thay đổi bảng dữ liệu bằng `GET_TABLE_MODELS`

## Kết Luận

Các stored procedure trong Hệ Thống Đăng Ký Mô Hình cung cấp các chức năng cần thiết để quản lý toàn bộ vòng đời của mô hình đánh giá rủi ro tín dụng, từ quản lý nguồn dữ liệu, xác định mô hình phù hợp, đến theo dõi hiệu suất. Bằng cách sử dụng các stored procedure này, tổ chức có thể đạt được quản trị mô hình tốt hơn, giám sát chất lượng dữ liệu chặt chẽ hơn, và đưa ra quyết định dựa trên dữ liệu về việc tái huấn luyện hoặc thay thế mô hình.