# Excel Templates for Model Registry Data Upload

## Tổng quan
Thư mục này chứa các template Excel để upload dữ liệu vào hệ thống Model Registry. Các template được thiết kế dựa trên cấu trúc bảng trong database.

## Cấu trúc thư mục
```
excel_templates/
├── README.md
├── templates/
│   ├── 01_model_type_template.xlsx
│   ├── 02_model_registry_template.xlsx
│   ├── 03_model_parameters_template.xlsx
│   ├── 04_model_source_tables_template.xlsx
│   ├── 05_model_column_details_template.xlsx
│   ├── 06_model_table_usage_template.xlsx
│   ├── 07_model_segment_mapping_template.xlsx
│   ├── 08_model_validation_results_template.xlsx
│   ├── 09_feature_registry_template.xlsx
│   ├── 10_feature_transformations_template.xlsx
│   ├── 11_feature_source_tables_template.xlsx
│   └── 12_feature_model_mapping_template.xlsx
├── sample_data/
│   ├── 01_model_type_sample.xlsx
│   ├── 02_model_registry_sample.xlsx
│   └── 09_feature_registry_sample.xlsx
└── upload_scripts/
    ├── excel_upload.py
    ├── config.py
    └── requirements.txt
```

## Hướng dẫn sử dụng

### 1. Template Files
- **Template files**: Chứa cấu trúc cột và validation rules
- **Sample data**: Chứa dữ liệu mẫu để tham khảo
- **Upload scripts**: Code Python để upload dữ liệu từ Excel vào database

### 2. Quy trình upload
1. Tải template Excel tương ứng với bảng cần upload
2. Điền dữ liệu theo format đã định sẵn
3. Chạy script upload để import dữ liệu vào database
4. Kiểm tra log để đảm bảo upload thành công

### 3. Validation Rules
- Các trường bắt buộc được đánh dấu màu đỏ
- Dropdown lists cho các trường có giá trị cố định
- Data validation cho format ngày tháng, số, text
- Unique constraints được kiểm tra

### 4. Dependencies
- Python 3.8+
- pandas
- openpyxl
- pyodbc
- sqlalchemy

## Lưu ý quan trọng
- Backup database trước khi upload
- Kiểm tra dữ liệu trước khi upload
- Đảm bảo thứ tự upload đúng (từ bảng master đến bảng detail)
- Xử lý lỗi và rollback nếu cần thiết 