# Hướng dẫn sử dụng Excel Templates cho Model Registry

## Tổng quan
Hệ thống Excel Templates được thiết kế để upload dữ liệu vào Model Registry một cách dễ dàng và an toàn. Hệ thống bao gồm:
- **Excel Templates**: Các file mẫu với validation rules
- **Sample Data**: Dữ liệu mẫu để tham khảo
- **Upload Scripts**: Code Python để upload dữ liệu

## Cấu trúc thư mục
```
excel_templates/
├── README.md                 # Tài liệu tổng quan
├── USAGE_GUIDE.md           # Hướng dẫn sử dụng (file này)
├── create_templates.py      # Script tạo templates
├── create_templates.bat     # Batch script để chạy
├── templates/               # Thư mục chứa Excel templates
├── sample_data/            # Thư mục chứa dữ liệu mẫu
└── upload_scripts/         # Scripts upload dữ liệu
    ├── simple_upload.py    # Script upload đơn giản
    └── requirements.txt    # Dependencies
```

## Bước 1: Tạo Excel Templates

### Cách 1: Sử dụng Batch Script (Khuyến nghị)
```bash
# Chạy file batch
create_templates.bat
```

### Cách 2: Chạy trực tiếp Python
```bash
# Cài đặt dependencies
pip install pandas openpyxl

# Chạy script tạo templates
python create_templates.py
```

### Templates được tạo:
1. **model_type_template.xlsx** - Template cho bảng MODEL_TYPE
2. **model_registry_template.xlsx** - Template cho bảng MODEL_REGISTRY  
3. **feature_registry_template.xlsx** - Template cho bảng FEATURE_REGISTRY

## Bước 2: Điền dữ liệu vào Templates

### Quy tắc chung:
- **Cột màu đỏ**: Bắt buộc phải điền
- **Dropdown lists**: Chỉ chọn từ danh sách có sẵn
- **Định dạng ngày**: YYYY-MM-DD
- **Giá trị boolean**: 1 (True) hoặc 0 (False)
- **Không xóa tên cột**

### Template MODEL_TYPE:
| Cột | Bắt buộc | Mô tả | Ví dụ |
|-----|----------|-------|-------|
| TYPE_CODE | ✓ | Mã loại mô hình | PD, LGD, EAD |
| TYPE_NAME | ✓ | Tên đầy đủ | Probability of Default |
| TYPE_DESCRIPTION | | Mô tả chi tiết | Mô hình ước tính xác suất vỡ nợ |
| IS_ACTIVE | | Trạng thái hoạt động | 1 |

### Template MODEL_REGISTRY:
| Cột | Bắt buộc | Mô tả | Ví dụ |
|-----|----------|-------|-------|
| TYPE_ID | ✓ | ID loại mô hình | 1 (tham chiếu MODEL_TYPE) |
| MODEL_NAME | ✓ | Tên mô hình | PD_RETAIL |
| MODEL_VERSION | ✓ | Phiên bản | 1.0 |
| SOURCE_DATABASE | ✓ | Database nguồn | RISK_MODELS |
| SOURCE_SCHEMA | ✓ | Schema nguồn | dbo |
| SOURCE_TABLE_NAME | ✓ | Bảng nguồn | PD_RETAIL_RESULTS |
| EFF_DATE | ✓ | Ngày có hiệu lực | 2024-01-01 |
| EXP_DATE | ✓ | Ngày hết hiệu lực | 2026-01-01 |

### Template FEATURE_REGISTRY:
| Cột | Bắt buộc | Mô tả | Ví dụ |
|-----|----------|-------|-------|
| FEATURE_NAME | ✓ | Tên đặc trưng | Customer Age |
| FEATURE_CODE | ✓ | Mã đặc trưng | CUST_AGE |
| DATA_TYPE | ✓ | Kiểu dữ liệu | NUMERIC (dropdown) |
| VALUE_TYPE | ✓ | Loại giá trị | CONTINUOUS (dropdown) |
| SOURCE_SYSTEM | ✓ | Hệ thống nguồn | CORE_BANKING |

## Bước 3: Upload dữ liệu

### Cài đặt dependencies:
```bash
cd upload_scripts
pip install -r requirements.txt
```

### Upload từng bảng:

#### 1. Upload MODEL_TYPE (phải upload trước):
```bash
python simple_upload.py model_type "path/to/model_type_data.xlsx"
```

#### 2. Upload MODEL_REGISTRY:
```bash
python simple_upload.py model_registry "path/to/model_registry_data.xlsx"
```

#### 3. Upload FEATURE_REGISTRY:
```bash
python simple_upload.py feature_registry "path/to/feature_registry_data.xlsx"
```

## Bước 4: Kiểm tra kết quả

### Kiểm tra log:
- Script sẽ tạo log file trong thư mục `logs/`
- Kiểm tra thông báo lỗi nếu có

### Kiểm tra database:
```sql
-- Kiểm tra dữ liệu đã upload
SELECT * FROM MODEL_TYPE;
SELECT * FROM MODEL_REGISTRY;
SELECT * FROM FEATURE_REGISTRY;
```

## Xử lý lỗi thường gặp

### 1. Lỗi kết nối database:
```
Error: Database connection failed
```
**Giải pháp:**
- Kiểm tra SQL Server đang chạy
- Kiểm tra tên database: MODEL_REGISTRY
- Kiểm tra quyền truy cập

### 2. Lỗi validation:
```
Validation failed:
- Missing required columns: ['TYPE_CODE']
- Column 'MODEL_NAME' has 2 empty values
```
**Giải pháp:**
- Điền đầy đủ các cột bắt buộc
- Kiểm tra định dạng dữ liệu

### 3. Lỗi foreign key:
```
Invalid foreign key values in 'TYPE_ID': [5, 6]
```
**Giải pháp:**
- Upload bảng master trước (MODEL_TYPE)
- Kiểm tra giá trị TYPE_ID tồn tại trong bảng MODEL_TYPE

### 4. Lỗi duplicate:
```
Duplicate values in unique columns: ['MODEL_NAME', 'MODEL_VERSION']
```
**Giải pháp:**
- Kiểm tra và xóa dữ liệu trùng lặp
- Đảm bảo unique constraint

## Quy trình upload an toàn

### 1. Backup database:
```sql
-- Tạo backup trước khi upload
BACKUP DATABASE MODEL_REGISTRY TO DISK = 'C:\Backup\MODEL_REGISTRY_Backup.bak'
```

### 2. Upload theo thứ tự:
1. MODEL_TYPE (bảng master)
2. MODEL_REGISTRY (tham chiếu MODEL_TYPE)
3. FEATURE_REGISTRY (độc lập)

### 3. Kiểm tra sau upload:
```sql
-- Kiểm tra số lượng records
SELECT COUNT(*) FROM MODEL_TYPE;
SELECT COUNT(*) FROM MODEL_REGISTRY;
SELECT COUNT(*) FROM FEATURE_REGISTRY;

-- Kiểm tra dữ liệu mẫu
SELECT TOP 5 * FROM MODEL_TYPE;
SELECT TOP 5 * FROM MODEL_REGISTRY;
SELECT TOP 5 * FROM FEATURE_REGISTRY;
```

## Tùy chỉnh nâng cao

### Thêm template mới:
1. Cập nhật `TEMPLATE_CONFIGS` trong `create_templates.py`
2. Chạy lại script tạo templates
3. Cập nhật `TABLE_CONFIGS` trong `simple_upload.py`

### Tùy chỉnh validation:
- Sửa đổi hàm `validate_data()` trong upload script
- Thêm validation rules mới

### Tùy chỉnh database connection:
- Sửa đổi `DB_CONFIG` trong upload script
- Thêm authentication nếu cần

## Hỗ trợ

Nếu gặp vấn đề:
1. Kiểm tra log files trong thư mục `logs/`
2. Kiểm tra cấu hình database
3. Kiểm tra định dạng dữ liệu Excel
4. Liên hệ team phát triển với thông tin lỗi chi tiết 