/*
Tên file: install_all.sql
Mô tả: Script chính để cài đặt toàn bộ hệ thống Đăng Ký Mô Hình
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.0
*/

SET NOCOUNT ON;
GO

PRINT '=============================================';
PRINT 'BẮT ĐẦU CÀI ĐẶT HỆ THỐNG ĐĂNG KÝ MÔ HÌNH';
PRINT '=============================================';
PRINT '';
GO

-- Tạo database MODEL_REGISTRY nếu chưa tồn tại
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'MODEL_REGISTRY')
BEGIN
    PRINT 'Tạo database MODEL_REGISTRY...';
    CREATE DATABASE MODEL_REGISTRY;
    PRINT 'Đã tạo database MODEL_REGISTRY thành công.';
END
ELSE
BEGIN
    PRINT 'Database MODEL_REGISTRY đã tồn tại, tiếp tục cài đặt...';
END
GO

USE MODEL_REGISTRY;
GO

-- Tạo bảng (Schema)
PRINT 'Bắt đầu tạo cấu trúc dữ liệu...';
PRINT '-----------------------------------------';

PRINT 'Tạo bảng MODEL_TYPE...';
:r .\schema\01_model_type.sql
PRINT '';

PRINT 'Tạo bảng MODEL_REGISTRY...';
:r .\schema\02_model_registry.sql
PRINT '';

PRINT 'Tạo bảng MODEL_PARAMETERS...';
:r .\schema\03_model_parameters.sql
PRINT '';

PRINT 'Tạo bảng MODEL_SOURCE_TABLES...';
:r .\schema\04_model_source_tables.sql
PRINT '';

PRINT 'Tạo bảng MODEL_COLUMN_DETAILS...';
:r .\schema\05_model_column_details.sql
PRINT '';

PRINT 'Tạo bảng MODEL_TABLE_USAGE...';
:r .\schema\06_model_table_usage.sql
PRINT '';

PRINT 'Tạo bảng MODEL_TABLE_MAPPING...';
:r .\schema\07_model_table_mapping.sql
PRINT '';

PRINT 'Tạo bảng MODEL_SEGMENT_MAPPING...';
:r .\schema\08_model_segment_mapping.sql
PRINT '';

PRINT 'Tạo bảng MODEL_VALIDATION_RESULTS...';
:r .\schema\09_model_validation_results.sql
PRINT '';

PRINT 'Tạo bảng MODEL_SOURCE_REFRESH_LOG...';
:r .\schema\10_model_source_refresh_log.sql
PRINT '';

PRINT 'Tạo bảng MODEL_DATA_QUALITY_LOG...';
:r .\schema\11_model_data_quality_log.sql
PRINT '';

PRINT 'Cấu trúc dữ liệu đã được tạo thành công.';
PRINT '';

-- Tạo các view
PRINT 'Bắt đầu tạo các view...';
PRINT '-----------------------------------------';

PRINT 'Tạo view VW_MODEL_TABLE_RELATIONSHIPS...';
:r .\views\01_vw_model_table_relationships.sql
PRINT '';

PRINT 'Tạo view VW_MODEL_TYPE_INFO...';
:r .\views\02_vw_model_type_info.sql
PRINT '';

PRINT 'Tạo view VW_MODEL_PERFORMANCE...';
:r .\views\03_vw_model_performance.sql
PRINT '';

PRINT 'Các view đã được tạo thành công.';
PRINT '';

-- Tạo các stored procedures
PRINT 'Bắt đầu tạo các stored procedures...';
PRINT '-----------------------------------------';

PRINT 'Tạo procedure GET_MODEL_TABLES...';
:r .\procedures\01_get_model_tables.sql
PRINT '';

PRINT 'Tạo procedure GET_TABLE_MODELS...';
:r .\procedures\02_get_table_models.sql
PRINT '';

PRINT 'Tạo procedure VALIDATE_MODEL_SOURCES...';
:r .\procedures\03_validate_model_sources.sql
PRINT '';

PRINT 'Tạo procedure LOG_SOURCE_TABLE_REFRESH...';
:r .\procedures\04_log_source_table_refresh.sql
PRINT '';

PRINT 'Tạo procedure GET_APPROPRIATE_MODEL...';
:r .\procedures\05_get_appropriate_model.sql
PRINT '';

PRINT 'Tạo procedure GET_MODEL_PERFORMANCE_HISTORY...';
:r .\procedures\06_get_model_performance_history.sql
PRINT '';

PRINT 'Các stored procedures đã được tạo thành công.';
PRINT '';

-- Tạo các functions
PRINT 'Bắt đầu tạo các functions...';
PRINT '-----------------------------------------';

PRINT 'Tạo function FN_GET_MODEL_SCORE...';
:r .\functions\01_fn_get_model_score.sql
PRINT '';

PRINT 'Tạo function FN_CALCULATE_PSI...';
:r .\functions\02_fn_calculate_psi.sql
PRINT '';

PRINT 'Các functions đã được tạo thành công.';
PRINT '';

-- Tạo các triggers
PRINT 'Bắt đầu tạo các triggers...';
PRINT '-----------------------------------------';

PRINT 'Tạo trigger TRG_AUDIT_MODEL_REGISTRY...';
:r .\triggers\01_trg_audit_model_registry.sql
PRINT '';

PRINT 'Tạo trigger TRG_AUDIT_MODEL_PARAMETERS...';
:r .\triggers\02_trg_audit_model_parameters.sql
PRINT '';

PRINT 'Các triggers đã được tạo thành công.';
PRINT '';

-- Nhập dữ liệu mẫu
PRINT 'Bắt đầu nhập dữ liệu mẫu...';
PRINT '-----------------------------------------';

PRINT 'Nhập dữ liệu mẫu cho MODEL_TYPE...';
:r .\sample_data\01_model_type_data.sql
PRINT '';

PRINT 'Nhập dữ liệu mẫu cho MODEL_REGISTRY...';
:r .\sample_data\02_model_registry_data.sql
PRINT '';

PRINT 'Nhập dữ liệu mẫu cho MODEL_PARAMETERS...';
:r .\sample_data\03_model_parameters_data.sql
PRINT '';

PRINT 'Nhập dữ liệu mẫu cho MODEL_SOURCE_TABLES...';
:r .\sample_data\04_model_source_tables_data.sql
PRINT '';

PRINT 'Nhập dữ liệu mẫu cho MODEL_TABLE_USAGE...';
:r .\sample_data\05_model_table_usage_data.sql
PRINT '';

PRINT 'Nhập dữ liệu mẫu cho MODEL_VALIDATION_RESULTS...';
:r .\sample_data\06_model_validation_results_data.sql
PRINT '';

PRINT 'Dữ liệu mẫu đã được nhập thành công.';
PRINT '';

PRINT '=============================================';
PRINT 'CÀI ĐẶT HỆ THỐNG ĐĂNG KÝ MÔ HÌNH HOÀN TẤT';
PRINT '=============================================';
PRINT '';
PRINT 'Thông tin tóm tắt:';
PRINT '- Database: MODEL_REGISTRY';
PRINT '- Số bảng: 11';
PRINT '- Số view: 3';
PRINT '- Số stored procedures: 6';
PRINT '- Số functions: 2';
PRINT '- Số triggers: 2';
PRINT '';
PRINT 'Hệ thống đã sẵn sàng để sử dụng.';
GO