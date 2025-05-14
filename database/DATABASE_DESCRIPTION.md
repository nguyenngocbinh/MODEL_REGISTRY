# DATABASE DESCRIPTION: MODEL_REGISTRY

## Tổng Quan

Database MODEL_REGISTRY được thiết kế để quản lý toàn diện vòng đời của các mô hình đánh giá rủi ro tín dụng. Hệ thống cơ sở dữ liệu này bao gồm các bảng để lưu trữ thông tin về mô hình, nguồn dữ liệu, phân khúc khách hàng, kết quả đánh giá hiệu suất, và chất lượng dữ liệu.

## Cấu Trúc Chính

### 1. Quản Lý Mô Hình

#### 1.1 MODEL_TYPE
Phân loại các loại mô hình (PD, LGD, EAD, Scorecard, v.v.) để dễ dàng quản lý và tìm kiếm. Bảng này giúp tổ chức các mô hình theo chức năng và mục đích của chúng.

**Trường chính:**
- TYPE_ID: Khóa chính, ID tự động tăng
- TYPE_CODE: Mã loại mô hình (ví dụ: "PD", "LGD", "B-SCORE")
- TYPE_NAME: Tên đầy đủ của loại mô hình
- TYPE_DESCRIPTION: Mô tả chi tiết về loại mô hình

#### 1.2 MODEL_REGISTRY
Kho lưu trữ trung tâm chứa thông tin cơ bản về tất cả các mô hình. Bảng này lưu trữ tên mô hình, phiên bản, ngày có hiệu lực, và các thông tin mô tả khác. Thông qua liên kết với MODEL_TYPE, mỗi mô hình được gán vào một loại cụ thể.

**Trường chính:**
- MODEL_ID: Khóa chính, ID tự động tăng
- TYPE_ID: Khóa ngoại tham chiếu đến MODEL_TYPE
- MODEL_NAME: Tên mô hình
- MODEL_VERSION: Phiên bản mô hình
- MODEL_DESCRIPTION: Mô tả chi tiết về mô hình
- EFF_DATE: Ngày bắt đầu hiệu lực
- EXP_DATE: Ngày hết hiệu lực
- IS_ACTIVE: Trạng thái hoạt động của mô hình
- MODEL_CATEGORY: Danh mục mô hình (Retail, Corporate, SME)
- SOURCE_DATABASE, SOURCE_SCHEMA, SOURCE_TABLE_NAME: Thông tin bảng lưu kết quả mô hình

#### 1.3 MODEL_PARAMETERS
Lưu trữ tham số và hệ số của các mô hình. Bảng này quan trọng cho việc tái tạo kết quả mô hình và theo dõi các thay đổi trong cách tính toán theo thời gian.

**Trường chính:**
- PARAMETER_ID: Khóa chính, ID tự động tăng
- MODEL_ID: Khóa ngoại tham chiếu đến MODEL_REGISTRY
- PARAMETER_NAME: Tên tham số
- PARAMETER_VALUE: Giá trị tham số
- PARAMETER_TYPE: Loại tham số (COEFFICIENT, THRESHOLD, SCALING, LOOKUP)
- PARAMETER_FORMAT: Định dạng tham số (NUMERIC, JSON, TEXT)
- IS_CALIBRATED: Đánh dấu tham số đã được hiệu chỉnh
- LAST_CALIBRATION_DATE: Ngày hiệu chỉnh gần nhất
- EFF_DATE, EXP_DATE: Thời gian hiệu lực của tham số

### 2. Quản Lý Nguồn Dữ Liệu

#### 2.1 MODEL_SOURCE_TABLES
Quản lý các bảng nguồn được sử dụng bởi các mô hình. Bảng này lưu trữ thông tin về tất cả các bảng dữ liệu được sử dụng trong hệ thống mô hình, bao gồm vị trí, chủ sở hữu dữ liệu, tần suất cập nhật, và đánh giá chất lượng. Việc theo dõi nguồn dữ liệu giúp đảm bảo tính minh bạch và truy xuất nguồn gốc dữ liệu.

**Trường chính:**
- SOURCE_TABLE_ID: Khóa chính, ID tự động tăng
- SOURCE_DATABASE, SOURCE_SCHEMA, SOURCE_TABLE_NAME: Thông tin định danh bảng
- TABLE_TYPE: Loại bảng (INPUT, OUTPUT, REFERENCE, TEMPORARY)
- TABLE_DESCRIPTION: Mô tả chi tiết về bảng
- DATA_OWNER: Chủ sở hữu dữ liệu
- UPDATE_FREQUENCY: Tần suất cập nhật dữ liệu
- DATA_QUALITY_SCORE: Điểm đánh giá chất lượng dữ liệu (1-10)
- KEY_COLUMNS: Danh sách các cột khóa (JSON)

#### 2.2 MODEL_COLUMN_DETAILS
Lưu trữ thông tin chi tiết về các cột dữ liệu trong bảng nguồn. Bảng này theo dõi siêu dữ liệu (metadata) của từng cột, bao gồm ý nghĩa nghiệp vụ, kiểu dữ liệu, mức độ quan trọng của đặc trưng, và logic biến đổi dữ liệu. Thông tin này rất quan trọng cho việc hiểu cách mô hình sử dụng dữ liệu và tác động của từng biến.

**Trường chính:**
- COLUMN_ID: Khóa chính, ID tự động tăng
- SOURCE_TABLE_ID: Khóa ngoại tham chiếu đến MODEL_SOURCE_TABLES
- COLUMN_NAME: Tên cột
- DATA_TYPE: Kiểu dữ liệu
- COLUMN_DESCRIPTION: Mô tả chi tiết về cột
- IS_MANDATORY: Đánh dấu cột bắt buộc
- IS_FEATURE: Đánh dấu cột được sử dụng làm đặc trưng
- FEATURE_IMPORTANCE: Mức độ quan trọng của đặc trưng
- BUSINESS_DEFINITION: Định nghĩa nghiệp vụ
- TRANSFORMATION_LOGIC: Logic biến đổi dữ liệu

### 3. Mối Quan Hệ Mô Hình - Dữ Liệu

#### 3.1 MODEL_TABLE_USAGE
Quản lý mối quan hệ nhiều-nhiều giữa mô hình và bảng dữ liệu. Bảng này mô tả cách mô hình sử dụng các bảng dữ liệu, bao gồm mục đích sử dụng (đầu vào chính, lưu trữ kết quả, dữ liệu tham chiếu) và thời gian hiệu lực của mối quan hệ. Điều này giúp theo dõi sự phụ thuộc giữa mô hình và dữ liệu.

**Trường chính:**
- USAGE_ID: Khóa chính, ID tự động tăng
- MODEL_ID: Khóa ngoại tham chiếu đến MODEL_REGISTRY
- SOURCE_TABLE_ID: Khóa ngoại tham chiếu đến MODEL_SOURCE_TABLES
- USAGE_PURPOSE: Mục đích sử dụng (Primary Input, Result Storage, Reference Data)
- PRIORITY: Mức độ ưu tiên
- EFF_DATE, EXP_DATE: Thời gian hiệu lực của mối quan hệ
- IS_ACTIVE: Trạng thái hoạt động

#### 3.2 MODEL_TABLE_MAPPING
Lưu trữ chi tiết về cách mô hình sử dụng các bảng dữ liệu. Bảng này chi tiết hơn về cách thức từng mô hình tương tác với các bảng nguồn, bao gồm các cột cần thiết, bộ lọc áp dụng, và thứ tự xử lý. Thông tin này rất quan trọng để hiểu đầy đủ cách dữ liệu được xử lý và biến đổi trong mô hình.

**Trường chính:**
- MAPPING_ID: Khóa chính, ID tự động tăng
- MODEL_ID: Khóa ngoại tham chiếu đến MODEL_REGISTRY
- SOURCE_TABLE_ID: Khóa ngoại tham chiếu đến MODEL_SOURCE_TABLES
- USAGE_TYPE: Loại sử dụng (FEATURE_SOURCE, RESULT_STORE, LOOKUP, VALIDATION)
- REQUIRED_COLUMNS: Danh sách các cột cần thiết (JSON)
- FILTERS_APPLIED: Điều kiện lọc được áp dụng
- IS_CRITICAL: Đánh dấu bảng quan trọng thiết yếu
- SEQUENCE_ORDER: Thứ tự xử lý bảng
- DATA_TRANSFORMATION: Mô tả các biến đổi dữ liệu

### 4. Phân Khúc và Đánh Giá

#### 4.1 MODEL_SEGMENT_MAPPING
Quản lý việc áp dụng mô hình cho các phân khúc khách hàng. Bảng này giúp xác định mô hình nào áp dụng cho nhóm khách hàng nào, dựa trên các tiêu chí phân khúc và mức độ ưu tiên. Điều này đảm bảo rằng mô hình phù hợp được áp dụng cho từng nhóm khách hàng.

**Trường chính:**
- MAPPING_ID: Khóa chính, ID tự động tăng
- MODEL_ID: Khóa ngoại tham chiếu đến MODEL_REGISTRY
- SEGMENT_NAME: Tên phân khúc
- SEGMENT_DESCRIPTION: Mô tả chi tiết về phân khúc
- SEGMENT_CRITERIA: Tiêu chí phân khúc
- PRIORITY: Mức độ ưu tiên
- EFF_DATE, EXP_DATE: Thời gian hiệu lực
- IS_ACTIVE: Trạng thái hoạt động

#### 4.2 MODEL_VALIDATION_RESULTS
Lưu trữ kết quả đánh giá hiệu suất mô hình. Bảng này ghi lại các chỉ số hiệu suất quan trọng như GINI, KS, PSI, v.v., cho mỗi lần đánh giá mô hình. Việc theo dõi hiệu suất theo thời gian giúp phát hiện sự suy giảm và đưa ra quyết định về việc tái huấn luyện hoặc thay thế mô hình.

**Trường chính:**
- VALIDATION_ID: Khóa chính, ID tự động tăng
- MODEL_ID: Khóa ngoại tham chiếu đến MODEL_REGISTRY
- VALIDATION_DATE: Ngày thực hiện đánh giá
- VALIDATION_TYPE: Loại đánh giá (DEVELOPMENT, BACKTESTING, OUT_OF_TIME)
- DATA_SAMPLE_SIZE: Kích thước mẫu dữ liệu
- KS_STATISTIC, GINI, PSI, ACCURACY, PRECISION, RECALL, F1_SCORE: Chỉ số đánh giá
- DETAILED_METRICS: Chỉ số chi tiết theo phân khúc (JSON)
- VALIDATION_STATUS: Trạng thái đánh giá (DRAFT, COMPLETED, APPROVED)
- VALIDATION_THRESHOLD_BREACHED: Cờ đánh dấu vượt ngưỡng

### 5. Giám Sát và Chất Lượng

#### 5.1 MODEL_SOURCE_REFRESH_LOG
Ghi nhật ký cập nhật dữ liệu nguồn. Bảng này theo dõi quá trình cập nhật dữ liệu cho các bảng nguồn, bao gồm thời gian bắt đầu, kết thúc, trạng thái, và số lượng bản ghi xử lý. Điều này giúp giám sát tính kịp thời và đầy đủ của dữ liệu, cũng như giải quyết các vấn đề liên quan đến việc cập nhật dữ liệu.

**Trường chính:**
- REFRESH_ID: Khóa chính, ID tự động tăng
- SOURCE_TABLE_ID: Khóa ngoại tham chiếu đến MODEL_SOURCE_TABLES
- PROCESS_DATE: Ngày xử lý dữ liệu
- REFRESH_START_TIME, REFRESH_END_TIME: Thời gian bắt đầu và kết thúc
- REFRESH_STATUS: Trạng thái cập nhật (STARTED, COMPLETED, FAILED, PARTIAL)
- REFRESH_TYPE: Loại cập nhật (FULL, INCREMENTAL, DELTA, RESTATEMENT)
- RECORDS_PROCESSED: Số lượng bản ghi đã xử lý
- ERROR_MESSAGE: Thông báo lỗi nếu có

#### 5.2 MODEL_DATA_QUALITY_LOG
Ghi nhật ký các vấn đề chất lượng dữ liệu. Bảng này theo dõi các vấn đề về chất lượng dữ liệu như dữ liệu thiếu, ngoài phạm vi, trùng lặp, và không nhất quán. Nó cũng theo dõi mức độ nghiêm trọng, số lượng bản ghi bị ảnh hưởng, và trạng thái khắc phục. Việc giám sát chất lượng dữ liệu rất quan trọng để đảm bảo độ tin cậy của kết quả mô hình.

**Trường chính:**
- LOG_ID: Khóa chính, ID tự động tăng
- SOURCE_TABLE_ID: Khóa ngoại tham chiếu đến MODEL_SOURCE_TABLES
- COLUMN_ID: Khóa ngoại tham chiếu đến MODEL_COLUMN_DETAILS (NULL cho vấn đề cấp bảng)
- PROCESS_DATE: Ngày phát hiện vấn đề
- ISSUE_TYPE: Loại vấn đề (MISSING_DATA, OUT_OF_RANGE, DUPLICATE, INCONSISTENT)
- ISSUE_DESCRIPTION: Mô tả chi tiết về vấn đề
- SEVERITY: Mức độ nghiêm trọng (LOW, MEDIUM, HIGH, CRITICAL)
- RECORDS_AFFECTED: Số lượng bản ghi bị ảnh hưởng
- REMEDIATION_STATUS: Trạng thái khắc phục (OPEN, IN_PROGRESS, RESOLVED, WONTFIX)

### 6. Các Bảng Bổ Sung

#### 6.1 Bảng Audit
- AUDIT_MODEL_REGISTRY: Ghi nhật ký thay đổi trong bảng MODEL_REGISTRY
- AUDIT_MODEL_PARAMETERS: Ghi nhật ký thay đổi trong bảng MODEL_PARAMETERS

#### 6.2 Views
- VW_MODEL_TABLE_RELATIONSHIPS: Hiển thị mối quan hệ giữa mô hình và bảng dữ liệu
- VW_MODEL_TYPE_INFO: Hiển thị thông tin tổng hợp về mô hình và loại mô hình
- VW_MODEL_PERFORMANCE: Hiển thị thông tin về hiệu suất của các mô hình theo thời gian

## Mối Quan Hệ Giữa Các Bảng

- **MODEL_REGISTRY** liên kết với **MODEL_TYPE** thông qua trường TYPE_ID để phân loại mô hình.
- **MODEL_PARAMETERS** liên kết với **MODEL_REGISTRY** thông qua trường MODEL_ID để lưu trữ tham số của mô hình.
- **MODEL_TABLE_USAGE** và **MODEL_TABLE_MAPPING** liên kết **MODEL_REGISTRY** với **MODEL_SOURCE_TABLES** để mô tả cách mô hình sử dụng dữ liệu.
- **MODEL_COLUMN_DETAILS** liên kết với **MODEL_SOURCE_TABLES** thông qua trường SOURCE_TABLE_ID để lưu trữ thông tin chi tiết về các cột.
- **MODEL_SEGMENT_MAPPING** liên kết với **MODEL_REGISTRY** thông qua trường MODEL_ID để xác định phân khúc áp dụng.
- **MODEL_VALIDATION_RESULTS** liên kết với **MODEL_REGISTRY** thông qua trường MODEL_ID để lưu trữ kết quả đánh giá.
- **MODEL_SOURCE_REFRESH_LOG** liên kết với **MODEL_SOURCE_TABLES** thông qua trường SOURCE_TABLE_ID để ghi nhật ký cập nhật.
- **MODEL_DATA_QUALITY_LOG** liên kết với **MODEL_SOURCE_TABLES** và **MODEL_COLUMN_DETAILS** để ghi nhật ký vấn đề chất lượng dữ liệu.

## Functions và Stored Procedures

### Functions
- **FN_GET_MODEL_SCORE**: Tính điểm của một khách hàng dựa trên mô hình.
- **FN_CALCULATE_PSI**: Tính Population Stability Index giữa hai phân phối.

### Stored Procedures
- **GET_MODEL_TABLES**: Lấy danh sách bảng dữ liệu được sử dụng bởi một mô hình.
- **GET_TABLE_MODELS**: Lấy danh sách mô hình sử dụng một bảng dữ liệu.
- **VALIDATE_MODEL_SOURCES**: Kiểm tra tính khả dụng của các bảng nguồn cho một mô hình.
- **LOG_SOURCE_TABLE_REFRESH**: Ghi nhật ký cập nhật dữ liệu nguồn.
- **GET_APPROPRIATE_MODEL**: Xác định mô hình phù hợp nhất cho một khách hàng.
- **GET_MODEL_PERFORMANCE_HISTORY**: Lấy lịch sử hiệu suất của mô hình theo thời gian.

## Triggers
- **TRG_AUDIT_MODEL_REGISTRY**: Ghi nhật ký thay đổi trong bảng MODEL_REGISTRY.
- **TRG_AUDIT_MODEL_PARAMETERS**: Ghi nhật ký thay đổi trong bảng MODEL_PARAMETERS.

## Sử Dụng Hệ Thống Cơ Sở Dữ Liệu

### Quản Lý Mô Hình

1. Đăng ký mô hình mới trong bảng MODEL_REGISTRY, kết nối với loại mô hình phù hợp từ MODEL_TYPE.
2. Lưu trữ tham số mô hình trong MODEL_PARAMETERS.
3. Quản lý phân khúc áp dụng mô hình thông qua MODEL_SEGMENT_MAPPING.

### Quản Lý Dữ Liệu

1. Đăng ký các bảng nguồn dữ liệu trong MODEL_SOURCE_TABLES.
2. Mô tả chi tiết về các cột trong MODEL_COLUMN_DETAILS.
3. Thiết lập mối quan hệ giữa mô hình và dữ liệu thông qua MODEL_TABLE_USAGE và MODEL_TABLE_MAPPING.

### Giám Sát và Đánh Giá

1. Ghi nhật ký cập nhật dữ liệu trong MODEL_SOURCE_REFRESH_LOG.
2. Ghi nhận vấn đề chất lượng dữ liệu trong MODEL_DATA_QUALITY_LOG.
3. Lưu trữ kết quả đánh giá hiệu suất mô hình trong MODEL_VALIDATION_RESULTS.

### Sử Dụng Mô Hình

1. Xác định mô hình phù hợp nhất cho khách hàng sử dụng stored procedure GET_APPROPRIATE_MODEL.
2. Tính điểm cho khách hàng sử dụng function FN_GET_MODEL_SCORE.
3. Đánh giá hiệu suất mô hình theo thời gian sử dụng stored procedure GET_MODEL_PERFORMANCE_HISTORY.