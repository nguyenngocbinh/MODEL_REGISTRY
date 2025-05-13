/*
Tên file: install_all.sql
Mô tả: Script chính để cài đặt toàn bộ hệ thống Đăng Ký Mô Hình
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.2 - Optimized for logging
*/

SET NOCOUNT ON;
GO

-- Lấy đường dẫn file log từ tham số
DECLARE @LogFilePath NVARCHAR(500) = '$(LogFilePath)';
DECLARE @LogCmd NVARCHAR(1000);
DECLARE @Now NVARCHAR(50);

-- Hàm để tạo chuỗi thời gian hiện tại
CREATE OR ALTER FUNCTION dbo.GetCurrentTimeString()
RETURNS NVARCHAR(50)
AS
BEGIN
    RETURN CONVERT(NVARCHAR, GETDATE(), 120);
END
GO

-- Thủ tục để ghi log
CREATE OR ALTER PROCEDURE dbo.LogMessage
    @LogFilePath NVARCHAR(500),
    @Message NVARCHAR(1000)
AS
BEGIN
    DECLARE @Cmd NVARCHAR(4000);
    DECLARE @TimeStr NVARCHAR(50) = dbo.GetCurrentTimeString();
    
    SET @Cmd = 'echo [' + @TimeStr + '] ' + @Message + ' >> "' + @LogFilePath + '"';
    
    -- Sử dụng xp_cmdshell nếu có quyền
    DECLARE @CmdShellEnabled INT;
    EXEC sp_configure 'show advanced options', 1;
    RECONFIGURE;
    EXEC sp_configure 'xp_cmdshell', 1;
    RECONFIGURE;
    
    EXEC xp_cmdshell @Cmd, no_output;
    
    -- Vô hiệu hóa lại xp_cmdshell nếu cần
    EXEC sp_configure 'xp_cmdshell', 0;
    RECONFIGURE;
    EXEC sp_configure 'show advanced options', 0;
    RECONFIGURE;
END
GO

-- Ghi log bắt đầu cài đặt
EXEC dbo.LogMessage @LogFilePath, 'install_all.sql: Bắt đầu cài đặt database';

PRINT '=============================================';
PRINT 'BẮT ĐẦU CÀI ĐẶT HỆ THỐNG ĐĂNG KÝ MÔ HÌNH';
PRINT '=============================================';
PRINT '';
GO

-- Tạo bảng (Schema)
PRINT 'Bắt đầu tạo cấu trúc dữ liệu...';
PRINT '-----------------------------------------';
EXEC dbo.LogMessage @LogFilePath, 'Bắt đầu tạo cấu trúc dữ liệu';

PRINT 'Tạo bảng MODEL_TYPE...';
EXEC dbo.LogMessage @LogFilePath, 'Đang tạo bảng MODEL_TYPE...';
:r .\database\schema\01_model_type.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành tạo bảng MODEL_TYPE';
PRINT '';

PRINT 'Tạo bảng MODEL_REGISTRY...';
EXEC dbo.LogMessage @LogFilePath, 'Đang tạo bảng MODEL_REGISTRY...';
:r .\database\schema\02_model_registry.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành tạo bảng MODEL_REGISTRY';
PRINT '';

PRINT 'Tạo bảng MODEL_PARAMETERS...';
EXEC dbo.LogMessage @LogFilePath, 'Đang tạo bảng MODEL_PARAMETERS...';
:r .\database\schema\03_model_parameters.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành tạo bảng MODEL_PARAMETERS';
PRINT '';

PRINT 'Tạo bảng MODEL_SOURCE_TABLES...';
EXEC dbo.LogMessage @LogFilePath, 'Đang tạo bảng MODEL_SOURCE_TABLES...';
:r .\database\schema\04_model_source_tables.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành tạo bảng MODEL_SOURCE_TABLES';
PRINT '';

PRINT 'Tạo bảng MODEL_COLUMN_DETAILS...';
EXEC dbo.LogMessage @LogFilePath, 'Đang tạo bảng MODEL_COLUMN_DETAILS...';
:r .\database\schema\05_model_column_details.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành tạo bảng MODEL_COLUMN_DETAILS';
PRINT '';

PRINT 'Tạo bảng MODEL_TABLE_USAGE...';
EXEC dbo.LogMessage @LogFilePath, 'Đang tạo bảng MODEL_TABLE_USAGE...';
:r .\database\schema\06_model_table_usage.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành tạo bảng MODEL_TABLE_USAGE';
PRINT '';

PRINT 'Tạo bảng MODEL_TABLE_MAPPING...';
EXEC dbo.LogMessage @LogFilePath, 'Đang tạo bảng MODEL_TABLE_MAPPING...';
:r .\database\schema\07_model_table_mapping.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành tạo bảng MODEL_TABLE_MAPPING';
PRINT '';

PRINT 'Tạo bảng MODEL_SEGMENT_MAPPING...';
EXEC dbo.LogMessage @LogFilePath, 'Đang tạo bảng MODEL_SEGMENT_MAPPING...';
:r .\database\schema\08_model_segment_mapping.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành tạo bảng MODEL_SEGMENT_MAPPING';
PRINT '';

PRINT 'Tạo bảng MODEL_VALIDATION_RESULTS...';
EXEC dbo.LogMessage @LogFilePath, 'Đang tạo bảng MODEL_VALIDATION_RESULTS...';
:r .\database\schema\09_model_validation_results.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành tạo bảng MODEL_VALIDATION_RESULTS';
PRINT '';

PRINT 'Tạo bảng MODEL_SOURCE_REFRESH_LOG...';
EXEC dbo.LogMessage @LogFilePath, 'Đang tạo bảng MODEL_SOURCE_REFRESH_LOG...';
:r .\database\schema\10_model_source_refresh_log.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành tạo bảng MODEL_SOURCE_REFRESH_LOG';
PRINT '';

PRINT 'Tạo bảng MODEL_DATA_QUALITY_LOG...';
EXEC dbo.LogMessage @LogFilePath, 'Đang tạo bảng MODEL_DATA_QUALITY_LOG...';
:r .\database\schema\11_model_data_quality_log.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành tạo bảng MODEL_DATA_QUALITY_LOG';
PRINT '';

PRINT 'Cấu trúc dữ liệu đã được tạo thành công.';
EXEC dbo.LogMessage @LogFilePath, 'Tất cả các bảng đã được tạo thành công';
PRINT '';

-- Tạo các view
PRINT 'Bắt đầu tạo các view...';
PRINT '-----------------------------------------';
EXEC dbo.LogMessage @LogFilePath, 'Bắt đầu tạo các view';

PRINT 'Tạo view VW_MODEL_TABLE_RELATIONSHIPS...';
EXEC dbo.LogMessage @LogFilePath, 'Đang tạo view VW_MODEL_TABLE_RELATIONSHIPS...';
:r .\database\views\01_vw_model_table_relationships.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành tạo view VW_MODEL_TABLE_RELATIONSHIPS';
PRINT '';

PRINT 'Tạo view VW_MODEL_TYPE_INFO...';
EXEC dbo.LogMessage @LogFilePath, 'Đang tạo view VW_MODEL_TYPE_INFO...';
:r .\database\views\02_vw_model_type_info.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành tạo view VW_MODEL_TYPE_INFO';
PRINT '';

PRINT 'Tạo view VW_MODEL_PERFORMANCE...';
EXEC dbo.LogMessage @LogFilePath, 'Đang tạo view VW_MODEL_PERFORMANCE...';
:r .\database\views\03_vw_model_performance.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành tạo view VW_MODEL_PERFORMANCE';
PRINT '';

PRINT 'Các view đã được tạo thành công.';
EXEC dbo.LogMessage @LogFilePath, 'Tất cả các view đã được tạo thành công';
PRINT '';

-- Tạo các stored procedures
PRINT 'Bắt đầu tạo các stored procedures...';
PRINT '-----------------------------------------';
EXEC dbo.LogMessage @LogFilePath, 'Bắt đầu tạo các stored procedures';

PRINT 'Tạo procedure GET_MODEL_TABLES...';
EXEC dbo.LogMessage @LogFilePath, 'Đang tạo procedure GET_MODEL_TABLES...';
:r .\database\procedures\01_get_model_tables.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành tạo procedure GET_MODEL_TABLES';
PRINT '';

PRINT 'Tạo procedure GET_TABLE_MODELS...';
EXEC dbo.LogMessage @LogFilePath, 'Đang tạo procedure GET_TABLE_MODELS...';
:r .\database\procedures\02_get_table_models.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành tạo procedure GET_TABLE_MODELS';
PRINT '';

PRINT 'Tạo procedure VALIDATE_MODEL_SOURCES...';
EXEC dbo.LogMessage @LogFilePath, 'Đang tạo procedure VALIDATE_MODEL_SOURCES...';
:r .\database\procedures\03_validate_model_sources.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành tạo procedure VALIDATE_MODEL_SOURCES';
PRINT '';

PRINT 'Tạo procedure LOG_SOURCE_TABLE_REFRESH...';
EXEC dbo.LogMessage @LogFilePath, 'Đang tạo procedure LOG_SOURCE_TABLE_REFRESH...';
:r .\database\procedures\04_log_source_table_refresh.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành tạo procedure LOG_SOURCE_TABLE_REFRESH';
PRINT '';

PRINT 'Tạo procedure GET_APPROPRIATE_MODEL...';
EXEC dbo.LogMessage @LogFilePath, 'Đang tạo procedure GET_APPROPRIATE_MODEL...';
:r .\database\procedures\05_get_appropriate_model.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành tạo procedure GET_APPROPRIATE_MODEL';
PRINT '';

PRINT 'Tạo procedure GET_MODEL_PERFORMANCE_HISTORY...';
EXEC dbo.LogMessage @LogFilePath, 'Đang tạo procedure GET_MODEL_PERFORMANCE_HISTORY...';
:r .\database\procedures\06_get_model_performance_history.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành tạo procedure GET_MODEL_PERFORMANCE_HISTORY';
PRINT '';

PRINT 'Các stored procedures đã được tạo thành công.';
EXEC dbo.LogMessage @LogFilePath, 'Tất cả các stored procedures đã được tạo thành công';
PRINT '';

-- Tạo các functions
PRINT 'Bắt đầu tạo các functions...';
PRINT '-----------------------------------------';
EXEC dbo.LogMessage @LogFilePath, 'Bắt đầu tạo các functions';

PRINT 'Tạo function FN_GET_MODEL_SCORE...';
EXEC dbo.LogMessage @LogFilePath, 'Đang tạo function FN_GET_MODEL_SCORE...';
:r .\database\functions\01_fn_get_model_score.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành tạo function FN_GET_MODEL_SCORE';
PRINT '';

PRINT 'Tạo function FN_CALCULATE_PSI...';
EXEC dbo.LogMessage @LogFilePath, 'Đang tạo function FN_CALCULATE_PSI...';
:r .\database\functions\02_fn_calculate_psi.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành tạo function FN_CALCULATE_PSI';
PRINT '';

PRINT 'Các functions đã được tạo thành công.';
EXEC dbo.LogMessage @LogFilePath, 'Tất cả các functions đã được tạo thành công';
PRINT '';

-- Tạo các triggers
PRINT 'Bắt đầu tạo các triggers...';
PRINT '-----------------------------------------';
EXEC dbo.LogMessage @LogFilePath, 'Bắt đầu tạo các triggers';

PRINT 'Tạo trigger TRG_AUDIT_MODEL_REGISTRY...';
EXEC dbo.LogMessage @LogFilePath, 'Đang tạo trigger TRG_AUDIT_MODEL_REGISTRY...';
:r .\database\triggers\01_trg_audit_model_registry.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành tạo trigger TRG_AUDIT_MODEL_REGISTRY';
PRINT '';

PRINT 'Tạo trigger TRG_AUDIT_MODEL_PARAMETERS...';
EXEC dbo.LogMessage @LogFilePath, 'Đang tạo trigger TRG_AUDIT_MODEL_PARAMETERS...';
:r .\database\triggers\02_trg_audit_model_parameters.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành tạo trigger TRG_AUDIT_MODEL_PARAMETERS';
PRINT '';

PRINT 'Các triggers đã được tạo thành công.';
EXEC dbo.LogMessage @LogFilePath, 'Tất cả các triggers đã được tạo thành công';
PRINT '';

-- Nhập dữ liệu mẫu
PRINT 'Bắt đầu nhập dữ liệu mẫu...';
PRINT '-----------------------------------------';
EXEC dbo.LogMessage @LogFilePath, 'Bắt đầu nhập dữ liệu mẫu';

PRINT 'Nhập dữ liệu mẫu cho MODEL_TYPE...';
EXEC dbo.LogMessage @LogFilePath, 'Đang nhập dữ liệu mẫu cho MODEL_TYPE...';
:r .\database\sample_data\01_model_type_data.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành nhập dữ liệu mẫu MODEL_TYPE';
PRINT '';

PRINT 'Nhập dữ liệu mẫu cho MODEL_REGISTRY...';
EXEC dbo.LogMessage @LogFilePath, 'Đang nhập dữ liệu mẫu cho MODEL_REGISTRY...';
:r .\database\sample_data\02_model_registry_data.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành nhập dữ liệu mẫu MODEL_REGISTRY';
PRINT '';

PRINT 'Nhập dữ liệu mẫu cho MODEL_PARAMETERS...';
EXEC dbo.LogMessage @LogFilePath, 'Đang nhập dữ liệu mẫu cho MODEL_PARAMETERS...';
:r .\database\sample_data\03_model_parameters_data.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành nhập dữ liệu mẫu MODEL_PARAMETERS';
PRINT '';

PRINT 'Nhập dữ liệu mẫu cho MODEL_SOURCE_TABLES...';
EXEC dbo.LogMessage @LogFilePath, 'Đang nhập dữ liệu mẫu cho MODEL_SOURCE_TABLES...';
:r .\database\sample_data\04_model_source_tables_data.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành nhập dữ liệu mẫu MODEL_SOURCE_TABLES';
PRINT '';

PRINT 'Nhập dữ liệu mẫu cho MODEL_TABLE_USAGE...';
EXEC dbo.LogMessage @LogFilePath, 'Đang nhập dữ liệu mẫu cho MODEL_TABLE_USAGE...';
:r .\database\sample_data\05_model_table_usage_data.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành nhập dữ liệu mẫu MODEL_TABLE_USAGE';
PRINT '';

PRINT 'Nhập dữ liệu mẫu cho MODEL_VALIDATION_RESULTS...';
EXEC dbo.LogMessage @LogFilePath, 'Đang nhập dữ liệu mẫu cho MODEL_VALIDATION_RESULTS...';
:r .\database\sample_data\06_model_validation_results_data.sql
EXEC dbo.LogMessage @LogFilePath, 'Hoàn thành nhập dữ liệu mẫu MODEL_VALIDATION_RESULTS';
PRINT '';

PRINT 'Dữ liệu mẫu đã được nhập thành công.';
EXEC dbo.LogMessage @LogFilePath, 'Tất cả dữ liệu mẫu đã được nhập thành công';
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
EXEC dbo.LogMessage @LogFilePath, 'Cài đặt hoàn tất - Hệ thống đã sẵn sàng để sử dụng';

-- Xóa các thủ tục tạm thời đã tạo cho việc ghi log
DROP FUNCTION IF EXISTS dbo.GetCurrentTimeString;
DROP PROCEDURE IF EXISTS dbo.LogMessage;

GO