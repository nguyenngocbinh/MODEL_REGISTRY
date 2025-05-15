# Hệ Thống Đăng Ký Mô Hình

## Tổng Quan

Hệ Thống Đăng Ký Mô Hình là một giải pháp cơ sở dữ liệu toàn diện để quản lý và theo dõi các mô hình đánh giá rủi ro tín dụng, các nguồn dữ liệu phụ thuộc và tham số thực thi của chúng. Hệ thống này giúp duy trì tài liệu rõ ràng về tất cả các mô hình, bảng dữ liệu đầu vào và đầu ra, cũng như mối quan hệ giữa các thành phần khác nhau trong hệ sinh thái mô hình.

## Cấu trúc thư mục

```
model-registry/
├── README.md                               # Tài liệu tổng quan về dự án
├── database/                               # Thư mục chứa tất cả các script SQL
│   ├── schema/                             # Định nghĩa cấu trúc cơ sở dữ liệu
│   │   ├── 01_model_type.sql               # Tạo bảng MODEL_TYPE
│   │   ├── 02_model_registry.sql           # Tạo bảng MODEL_REGISTRY
│   │   ├── 03_model_parameters.sql         # Tạo bảng MODEL_PARAMETERS
│   │   ├── 04_model_source_tables.sql      # Tạo bảng MODEL_SOURCE_TABLES
│   │   ├── 05_model_column_details.sql     # Tạo bảng MODEL_COLUMN_DETAILS
│   │   ├── 06_model_table_usage.sql        # Tạo bảng MODEL_TABLE_USAGE
│   │   ├── 07_model_table_mapping.sql      # Tạo bảng MODEL_TABLE_MAPPING
│   │   ├── 08_model_segment_mapping.sql    # Tạo bảng MODEL_SEGMENT_MAPPING
│   │   ├── 09_model_validation_results.sql # Tạo bảng MODEL_VALIDATION_RESULTS
│   │   ├── 10_model_source_refresh_log.sql # Tạo bảng MODEL_SOURCE_REFRESH_LOG
│   │   ├── 11_model_data_quality_log.sql   # Tạo bảng MODEL_DATA_QUALITY_LOG
│   │   ├── 12_feature_registry.sql         # Tạo bảng FEATURE_REGISTRY
│   │   ├── 13_feature_transformations.sql  # Tạo bảng FEATURE_TRANSFORMATIONS
│   │   ├── 14_feature_source_tables.sql    # Tạo bảng FEATURE_SOURCE_TABLES
│   │   ├── 15_feature_values.sql           # Tạo bảng FEATURE_VALUES
│   │   ├── 16_feature_stats.sql            # Tạo bảng FEATURE_STATS 
│   │   ├── 17_feature_dependencies.sql     # Tạo bảng FEATURE_DEPENDENCIES
│   │   ├── 18_feature_model_mapping.sql    # Tạo bảng FEATURE_MODEL_MAPPING
│   │   └── 19_feature_refresh_log.sql      # Tạo bảng FEATURE_REFRESH_LOG
│   │
│   ├── views/                              # View SQL
│   │   ├── 01_vw_model_table_relationships.sql
│   │   ├── 02_vw_model_type_info.sql
│   │   ├── 03_vw_model_performance.sql
│   │   ├── 04_vw_data_quality_summary.sql
│   │   ├── 05_vw_model_lineage.sql
│   │   ├── 06_vw_feature_catalog.sql       # View danh mục features
│   │   ├── 07_vw_feature_model_usage.sql   # View sử dụng features trong models
│   │   ├── 08_vw_feature_dependencies.sql  # View phụ thuộc giữa các features
│   │   └── 09_vw_feature_lineage.sql       # View lineage từ nguồn đến feature đến model
│   │
│   ├── procedures/                         # Stored Procedures
│   │   ├── 01_get_model_tables.sql
│   │   ├── 02_get_table_models.sql
│   │   ├── 03_validate_model_sources.sql
│   │   ├── 04_log_source_table_refresh.sql
│   │   ├── 05_get_appropriate_model.sql
│   │   ├── 06_get_model_performance_history.sql
│   │   ├── 07_register_new_model.sql
│   │   ├── 08_check_model_dependencies.sql
│   │   ├── 09_register_new_feature.sql     # Đăng ký feature mới vào hệ thống
│   │   ├── 10_update_feature_stats.sql     # Cập nhật thống kê của feature
│   │   ├── 11_link_feature_to_model.sql    # Liên kết feature với model
│   │   ├── 12_get_model_features.sql       # Lấy danh sách features của model
│   │   └── 13_refresh_feature_values.sql   # Cập nhật giá trị của features
│   │
│   ├── functions/                          # Scalar và Table-Valued Functions
│   │   ├── 01_fn_get_model_score.sql
│   │   ├── 02_fn_calculate_psi.sql
│   │   ├── 03_fn_calculate_ks.sql
│   │   ├── 04_fn_get_model_version_info.sql
│   │   ├── 05_fn_calculate_feature_drift.sql  # Tính toán độ dịch chuyển của feature
│   │   ├── 06_fn_get_feature_history.sql      # Lấy lịch sử giá trị của feature
│   │   └── 07_fn_validate_feature.sql         # Kiểm tra tính hợp lệ của feature
│   │
│   ├── triggers/                           # Triggers
│   │   ├── 01_trg_audit_model_registry.sql
│   │   ├── 02_trg_audit_model_parameters.sql
│   │   ├── 03_trg_validate_model_sources.sql
│   │   ├── 04_trg_update_model_status.sql
│   │   ├── 05_trg_audit_feature_registry.sql  # Ghi audit log khi feature thay đổi
│   │   ├── 06_trg_feature_stat_update.sql     # Tự động cập nhật thống kê feature
│   │   └── 07_trg_update_model_feature_dependencies.sql  # Cập nhật phụ thuộc feature-model
│   │
│   ├── sample_data/                        # Script nhập dữ liệu mẫu
│   │   ├── 01_model_type_data.sql
│   │   ├── 02_model_registry_data.sql
│   │   ├── 03_model_parameters_data.sql
│   │   ├── 04_model_source_tables_data.sql
│   │   ├── 05_model_table_usage_data.sql
│   │   ├── 06_model_validation_results_data.sql
│   │   ├── 07_model_segment_mapping_data.sql
│   │   ├── 08_model_column_details_data.sql
│   │   ├── 09_feature_registry_data.sql       # Dữ liệu mẫu cho feature registry
│   │   ├── 10_feature_transformations_data.sql # Dữ liệu mẫu cho transformations
│   │   ├── 11_feature_source_tables_data.sql  # Dữ liệu mẫu cho feature sources
│   │   └── 12_feature_model_mapping_data.sql  # Dữ liệu mẫu cho feature-model mapping
│   │
│   └── migrations/                         # Script nâng cấp schema
│       ├── v1.0-to-v1.1/
│       │   ├── 01_add_column_model_registry.sql
│       │   └── 02_update_view_model_type_info.sql
│       ├── v1.1-to-v1.2/
│       │   ├── 01_add_model_validation_results.sql
│       │   └── 02_add_performance_metrics.sql
│       └── v1.2-to-v1.3/
│           ├── 01_add_feature_store_tables.sql
│           └── 02_update_model_registry_for_features.sql
│
├── docs/                                   # Tài liệu
│   ├── diagrams/                           # Các sơ đồ
│   │   ├── er_diagram.png
│   │   ├── architecture_diagram.png
│   │   ├── data_flow_diagram.png
│   │   ├── component_diagram.png
│   │   └── feature_store_integration.png   # Sơ đồ tích hợp feature store
│   │
│   ├── user_guide.md                       # Hướng dẫn sử dụng
│   ├── admin_guide.md                      # Hướng dẫn quản trị
│   ├── implementation_guide.md             # Hướng dẫn triển khai
│   ├── api_documentation.md                # Tài liệu API
│   ├── data_dictionary.md                  # Từ điển dữ liệu
│   ├── troubleshooting.md                  # Hướng dẫn xử lý sự cố
│   ├── best_practices.md                   # Các thực hành tốt nhất
│   ├── feature_store_guide.md              # Hướng dẫn sử dụng feature store
│   └── feature_management.md               # Quản lý features
│
├── tests/                                  # Kiểm thử
│   ├── unit_tests/                         # Kiểm thử đơn vị
│   │   ├── test_model_registry.sql
│   │   ├── test_model_validation.sql
│   │   ├── test_functions.sql
│   │   ├── test_triggers.sql
│   │   ├── test_feature_registry.sql       # Kiểm thử feature registry
│   │   └── test_feature_transformations.sql # Kiểm thử feature transformations
│   │
│   ├── integration_tests/                  # Kiểm thử tích hợp
│   │   ├── test_procedures.sql
│   │   ├── test_views.sql
│   │   ├── test_end_to_end.sql
│   │   └── test_model_feature_integration.sql # Kiểm thử tích hợp model-feature
│   │
│   └── performance_tests/                  # Kiểm thử hiệu năng
│       ├── test_query_performance.sql
│       ├── test_load_performance.sql
│       └── test_feature_store_performance.sql # Kiểm thử hiệu năng feature store
│
├── api/                                    # API cho Model Registry
│   ├── endpoints/                          # Các endpoint API
│   │   ├── model_registry_api.sql
│   │   ├── model_validation_api.sql
│   │   ├── model_metrics_api.sql
│   │   ├── feature_registry_api.sql        # API cho feature registry
│   │   └── feature_transformations_api.sql # API cho feature transformations
│   │
│   ├── authentication/                     # Xác thực API
│   │   ├── api_roles.sql
│   │   └── api_permissions.sql
│   │
│   └── examples/                           # Ví dụ sử dụng API
│       ├── register_model_example.sql
│       ├── get_model_metrics_example.sql
│       ├── register_feature_example.sql    # Ví dụ đăng ký feature
│       └── get_model_features_example.sql  # Ví dụ lấy features của model
│
├── reports/                                # Mẫu báo cáo
│   ├── model_inventory_report.sql
│   ├── model_performance_report.sql
│   ├── data_quality_report.sql
│   ├── model_compliance_report.sql
│   ├── model_drift_report.sql
│   ├── model_usage_report.sql
│   ├── feature_inventory_report.sql        # Báo cáo danh mục features
│   ├── feature_usage_report.sql            # Báo cáo sử dụng features
│   ├── feature_drift_report.sql            # Báo cáo dịch chuyển features
│   ├── feature_reuse_analysis.sql          # Phân tích tái sử dụng features
│   ├── feature_data_quality_report.sql     # Báo cáo chất lượng dữ liệu features
│   └── model_feature_impact_report.sql     # Báo cáo tác động feature đến model
│
├── utilities/                              # Tiện ích
│   ├── data_extraction/                    # Các script trích xuất dữ liệu
│   │   ├── extract_model_metadata.sql
│   │   ├── extract_model_performance.sql
│   │   ├── extract_feature_metadata.sql    # Trích xuất metadata của features
│   │   └── extract_feature_transformations.sql # Trích xuất transformations
│   │
│   ├── data_import/                        # Các script nhập dữ liệu
│   │   ├── import_model_registry.sql
│   │   ├── import_model_parameters.sql
│   │   ├── import_feature_registry.sql     # Nhập dữ liệu vào feature registry
│   │   └── import_feature_transformations.sql # Nhập dữ liệu transformations
│   │
│   ├── maintenance/                        # Script bảo trì
│   │   ├── cleanup_old_logs.sql
│   │   ├── optimize_tables.sql
│   │   └── validate_data_integrity.sql
│   │
│   └── feature_store/                      # Tiện ích feature store
│       ├── calculate_offline_features.sql  # Tính toán features cho offline store
│       ├── refresh_online_store.sql        # Cập nhật online store
│       └── validate_feature_quality.sql    # Kiểm tra chất lượng features
│
└── scripts/                                # Scripts hỗ trợ
    ├── deploy.bat                          # Script triển khai cho Windows
    ├── deploy.sh                           # Script triển khai cho Linux/Unix
    ├── install_all.sql                     # Script cài đặt tất cả
    ├── uninstall.sql                       # Script gỡ bỏ
    ├── backup_registry.sql                 # Script sao lưu registry
    ├── restore_registry.sql                # Script khôi phục registry
    ├── generate_documentation.sql          # Script tạo tài liệu tự động
    ├── health_check.sql                    # Script kiểm tra tình trạng hệ thống
    ├── setup_feature_store.sql             # Script cài đặt feature store
    ├── backup_feature_store.sql            # Script sao lưu feature store
    └── restore_feature_store.sql           # Script khôi phục feature store
    
```

## Tính Năng Chính

- Đăng ký tập trung tất cả các mô hình rủi ro với quản lý phiên bản
- Phân loại mô hình theo loại (PD, LGD, EAD, Scorecard, Segmentation, v.v.)
- Theo dõi chi tiết các nguồn dữ liệu cho từng mô hình
- Quản lý tham số và hệ số của mô hình
- Lập tài liệu về việc áp dụng mô hình cho từng phân khúc khách hàng
- Ghi lại kết quả đánh giá hiệu suất mô hình (GINI, KS, PSI, v.v.)
- Giám sát chất lượng dữ liệu và trạng thái cập nhật
- Hỗ trợ xác thực mô hình và quản trị

## Cấu Trúc Cơ Sở Dữ Liệu

Hệ thống bao gồm nhiều bảng kết nối với nhau, cùng quản lý tất cả các khía cạnh của mô hình rủi ro:

### Bảng Cơ Bản

1. **MODEL_TYPE**: Định nghĩa các loại mô hình (PD, LGD, EAD, Scorecard, EWS, v.v.)
2. **MODEL_REGISTRY**: Kho lưu trữ trung tâm cho tất cả các mô hình rủi ro
3. **MODEL_SOURCE_TABLES**: Danh mục tất cả các bảng dữ liệu được sử dụng bởi các mô hình
4. **MODEL_TABLE_USAGE**: Mối quan hệ nhiều-nhiều giữa mô hình và nguồn dữ liệu
5. **MODEL_PARAMETERS**: Hệ số mô hình và tham số tính toán
6. **MODEL_COLUMN_DETAILS**: Thông tin chi tiết về các cột được sử dụng trong mô hình
7. **MODEL_SEGMENT_MAPPING**: Áp dụng mô hình cho các phân khúc khách hàng cụ thể

### Bảng Giám Sát và Đánh Giá

8. **MODEL_VALIDATION_RESULTS**: Lưu trữ kết quả đánh giá hiệu suất mô hình
9. **MODEL_SOURCE_REFRESH_LOG**: Theo dõi việc cập nhật dữ liệu cho các bảng nguồn
10. **MODEL_DATA_QUALITY_LOG**: Ghi lại các vấn đề về chất lượng dữ liệu

### View và Thủ Tục

- **VW_MODEL_TABLE_RELATIONSHIPS**: View tổng hợp về tất cả các mối quan hệ mô hình-bảng
- **VW_MODEL_TYPE_INFO**: View tổng hợp thông tin về mô hình và loại mô hình
- **GET_MODEL_TABLES**: Lấy tất cả các bảng được sử dụng bởi một mô hình cụ thể
- **GET_TABLE_MODELS**: Lấy tất cả các mô hình sử dụng một bảng cụ thể
- **GET_MODEL_PERFORMANCE_HISTORY**: Lấy lịch sử hiệu suất của mô hình theo thời gian
- **VALIDATE_MODEL_SOURCES**: Xác thực tính khả dụng của dữ liệu nguồn cho một mô hình
- **LOG_SOURCE_TABLE_REFRESH**: Ghi lại trạng thái cập nhật của bảng nguồn
- **GET_APPROPRIATE_MODEL**: Xác định mô hình phù hợp nhất cho một khách hàng

## Chi Tiết Các Bảng Chính

### MODEL_TYPE

Bảng này định nghĩa các loại mô hình khác nhau như:
- Probability of Default (PD)
- Loss Given Default (LGD)
- Exposure at Default (EAD)
- Behavioral Scorecard (Bscore)
- Application Scorecard (Ascore)
- Collection Scorecard (Cscore)
- Early Warning Signals (EWS)
- Segmentation Models

Mỗi loại mô hình có mã duy nhất, tên, mô tả và trạng thái hoạt động.

### MODEL_VALIDATION_RESULTS

Bảng này lưu trữ các chỉ số đo lường hiệu suất của mô hình:
- Gini Coefficient - Area Under the Curve (AUC-ROC)
- Kolmogorov-Smirnov (KS)
- Population Stability Index (PSI)
- Accuracy, Precision, Recall, F1-Score
- Information Value (IV)
- Kappa Score

Mỗi bản ghi bao gồm thông tin về ngày đánh giá, loại đánh giá (phát triển, backtesting, out-of-time, out-of-sample), và giai đoạn đánh giá, cho phép theo dõi hiệu suất mô hình theo thời gian.

## Ví Dụ Sử Dụng

### Tìm Tất Cả Các Bảng Được Sử Dụng Bởi Một Mô Hình

```sql
EXEC EWS.dbo.GET_MODEL_TABLES 'BSCORE_RETAIL';
```

### Tìm Tất Cả Các Mô Hình Sử Dụng Một Bảng Cụ Thể

```sql
EXEC EWS.dbo.GET_TABLE_MODELS 'DMT', 'dbo', 'ifrs9_dep_amt_txn';
```

### Xem Lịch Sử Hiệu Suất Của Một Mô Hình

```sql
EXEC EWS.dbo.GET_MODEL_PERFORMANCE_HISTORY @MODEL_NAME = 'BSCORE_RETAIL';
```

### Xác Thực Nguồn Dữ Liệu Trước Khi Thực Thi Mô Hình

```sql
EXEC EWS.dbo.VALIDATE_MODEL_SOURCES 1, '2023-10-31';
```

### Xác Định Mô Hình Phù Hợp Cho Một Khách Hàng

```sql
EXEC EWS.dbo.GET_APPROPRIATE_MODEL 'CUST12345', '2023-10-31';
```

## Quy Trình Xử Lý Mô Hình

1. **Xác Thực Dữ Liệu Nguồn**: Kiểm tra xem tất cả các bảng nguồn cần thiết đã được cập nhật chưa
2. **Phân Khúc Khách Hàng**: Xác định khách hàng nào sẽ được xử lý bởi mỗi mô hình
3. **Lựa Chọn Mô Hình**: Chọn mô hình tính điểm phù hợp dựa trên thuộc tính của khách hàng
4. **Tính Toán Đặc Trưng**: Tính toán các đặc trưng mô hình từ dữ liệu nguồn
5. **Tính Toán Điểm**: Áp dụng tham số mô hình để tính toán điểm và xác suất
6. **Gán Cấp Độ**: Ánh xạ điểm số thành cấp độ rủi ro sử dụng ngưỡng đã định nghĩa
7. **Lưu Trữ Kết Quả**: Lưu kết quả vào các bảng đầu ra thích hợp
8. **Đánh Giá Hiệu Suất**: Định kỳ đánh giá hiệu suất của mô hình và ghi lại kết quả

## Quy Trình Đánh Giá Mô Hình

Hệ thống hỗ trợ một quy trình đánh giá mô hình toàn diện:

1. **Đánh Giá Ban Đầu**: Trong quá trình phát triển mô hình
2. **Đánh Giá Định Kỳ**: Theo lịch định kỳ (hàng quý, nửa năm, hàng năm)
3. **Đánh Giá Đặc Biệt**: Khi có thay đổi đáng kể trong môi trường hoặc dữ liệu

Mỗi đánh giá bao gồm:
- Tính toán các chỉ số hiệu suất quan trọng
- So sánh với kết quả đánh giá trước đó
- Phân tích sự ổn định của mô hình qua thời gian
- Khuyến nghị về việc tiếp tục sử dụng, hiệu chỉnh, hoặc xây dựng lại mô hình

## Các Vấn Đề Bảo Mật

- Triển khai kiểm soát truy cập dựa trên vai trò
- Tạo dấu vết kiểm toán cho bất kỳ thay đổi nào đối với tham số mô hình
- Xác thực tính nhất quán của dữ liệu nguồn trước khi thực thi mô hình
- Giám sát các chỉ số chất lượng dữ liệu cho tất cả các bảng nguồn

## Tích Hợp Với Hệ Thống EWS Hiện Có

Hệ Thống Đăng Ký Mô Hình được thiết kế để nâng cao Hệ Thống Cảnh Báo Sớm (EWS) hiện có bằng cách cung cấp:

1. Tài liệu tốt hơn về các phụ thuộc của mô hình
2. Dấu vết kiểm toán rõ ràng hơn cho việc tuân thủ quy định
3. Khắc phục sự cố hiệu quả hơn đối với các vấn đề thực thi mô hình
4. Cải thiện quản trị mô hình và kiểm soát phiên bản
5. Theo dõi hiệu suất mô hình theo thời gian

## Hướng Dẫn Bảo Trì

- Thường xuyên xem xét và cập nhật tài liệu mô hình
- Lưu trữ các mô hình không hoạt động thay vì xóa chúng
- Ghi lại bất kỳ thay đổi nào đối với tham số mô hình kèm theo lý do
- Theo dõi xu hướng chất lượng dữ liệu theo thời gian
- Định kỳ (ít nhất hàng quý) đánh giá hiệu suất của các mô hình đang hoạt động
- Thiết lập ngưỡng cảnh báo cho các chỉ số hiệu suất quan trọng (AUC, KS, PSI)
- Xem xét tác động của các thay đổi về môi trường kinh tế lên hiệu suất mô hình

## Quy Trình Quản Lý Vòng Đời Mô Hình

Hệ thống hỗ trợ quản lý toàn bộ vòng đời của mô hình:

1. **Phát Triển**: Lưu trữ tài liệu phát triển, dữ liệu đào tạo và thông số mô hình
2. **Xác Thực**: Ghi lại kết quả đánh giá ban đầu và các thử nghiệm mô hình
3. **Triển Khai**: Quản lý việc triển khai mô hình vào hệ thống sản xuất
4. **Giám Sát**: Theo dõi hiệu suất mô hình liên tục thông qua các chỉ số quan trọng
5. **Tái Huấn Luyện**: Ghi lại việc cập nhật tham số mô hình khi cần thiết
6. **Xây Dựng Lại**: Quản lý quá trình phát triển phiên bản mô hình mới
7. **Ngưng Hoạt Động**: Lưu trữ tài liệu của các mô hình không còn sử dụng

## Cải Tiến Trong Tương Lai

- Tích hợp với hệ thống giám sát hiệu suất mô hình tự động
- Quy trình xác thực mô hình tự động
- Bảng điều khiển trực quan cho các chỉ số sức khỏe mô hình
- Tài liệu nâng cao về kết quả xác thực mô hình
- API cho việc truy cập theo chương trình vào dữ liệu đăng ký mô hình
- Tích hợp với các công cụ machine learning để phân tích xu hướng hiệu suất
- Hệ thống cảnh báo tự động khi hiệu suất mô hình suy giảm

## Báo Cáo và Phân Tích

Hệ thống cung cấp các báo cáo tích hợp để hỗ trợ quản trị mô hình:

1. **Báo Cáo Danh Mục Mô Hình**: Tổng quan về tất cả các mô hình đang hoạt động
2. **Báo Cáo Hiệu Suất Theo Thời Gian**: Theo dõi sự thay đổi của các chỉ số chính theo thời gian
3. **Báo Cáo Phụ Thuộc Dữ Liệu**: Hiển thị mối quan hệ giữa các mô hình và nguồn dữ liệu
4. **Báo Cáo Đánh Giá Chất Lượng**: Phân tích các vấn đề chất lượng dữ liệu ảnh hưởng đến mô hình
5. **Báo Cáo Tuân Thủ**: Hỗ trợ các yêu cầu tuân thủ quy định về quản trị mô hình

## Tác Giả

Nguyễn Ngọc Bình

## Giấy Phép

© 2025 - Bản quyền thuộc về Nguyễn Ngọc Bình