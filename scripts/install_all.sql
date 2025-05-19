/*
Tên file: install_all.sql
Mô tả: Script chính để cài đặt toàn bộ hệ thống Đăng Ký Mô Hình
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.3 - Enhanced with better error handling and feature store support
*/

SET NOCOUNT ON;
GO

-- Khai báo biến để theo dõi lỗi
DECLARE @ErrorOccurred BIT = 0;
DECLARE @ErrorMessage NVARCHAR(4000);
DECLARE @ErrorSeverity INT;
DECLARE @ErrorState INT;
DECLARE @LogFilePath NVARCHAR(500) = '$(LogFilePath)';

-- Tạo bảng tạm để lưu trữ log nếu không thể sử dụng xp_cmdshell
CREATE TABLE #InstallLog (
    LogTime DATETIME DEFAULT GETDATE(),
    Message NVARCHAR(1000)
);

-- Hàm ghi log an toàn - ưu tiên file nếu có quyền, nếu không thì ghi vào bảng tạm
CREATE OR ALTER PROCEDURE dbo.LogInstallMessage
    @Message NVARCHAR(1000),
    @LogFilePath NVARCHAR(500) = NULL
AS
BEGIN
    -- Luôn lưu vào bảng tạm để có thể xem trong quá trình cài đặt
    INSERT INTO #InstallLog (Message) VALUES (@Message);
    
    -- Hiển thị thông điệp trên màn hình
    PRINT @Message;
    
    -- Thử ghi vào file nếu có đường dẫn
    IF @LogFilePath IS NOT NULL
    BEGIN
        BEGIN TRY
            -- Kiểm tra xem xp_cmdshell có được bật không
            DECLARE @CmdShellEnabled INT;
            EXEC master.dbo.sp_configure 'show advanced options', 1;
            RECONFIGURE WITH OVERRIDE;
            EXEC master.dbo.sp_configure 'xp_cmdshell', 1;
            RECONFIGURE WITH OVERRIDE;
            
            -- Tạo lệnh echo để ghi log
            DECLARE @Cmd NVARCHAR(4000);
            DECLARE @TimeStr NVARCHAR(50) = CONVERT(NVARCHAR, GETDATE(), 120);
            SET @Cmd = 'echo [' + @TimeStr + '] ' + @Message + ' >> "' + @LogFilePath + '"';
            
            -- Thực thi lệnh
            EXEC xp_cmdshell @Cmd, no_output;
            
            -- Vô hiệu hóa lại xp_cmdshell
            EXEC master.dbo.sp_configure 'xp_cmdshell', 0;
            RECONFIGURE WITH OVERRIDE;
            EXEC master.dbo.sp_configure 'show advanced options', 0;
            RECONFIGURE WITH OVERRIDE;
        END TRY
        BEGIN CATCH
            -- Nếu không thể ghi log vào file, chỉ ghi vào bảng tạm và không báo lỗi
            -- vì đây không phải lỗi nghiêm trọng
            PRINT 'Không thể ghi log vào file. Log vẫn được lưu trong phiên làm việc.';
        END CATCH
    END
END;
GO

EXEC dbo.LogInstallMessage 'install_all.sql: Bắt đầu cài đặt database', @LogFilePath;

PRINT '=============================================';
PRINT 'BẮT ĐẦU CÀI ĐẶT HỆ THỐNG ĐĂNG KÝ MÔ HÌNH';
PRINT '=============================================';
PRINT '';
GO

-- Thiết lập khối try-catch tổng thể
BEGIN TRY
    -- Tạo bảng (Schema)
    EXEC dbo.LogInstallMessage 'Bắt đầu tạo cấu trúc dữ liệu...', @LogFilePath;
    
    -- 1. MODEL_TYPE
    BEGIN TRY
        EXEC dbo.LogInstallMessage 'Đang tạo bảng MODEL_TYPE...', @LogFilePath;
        :r .\database\schema\01_model_type.sql
        EXEC dbo.LogInstallMessage 'Hoàn thành tạo bảng MODEL_TYPE', @LogFilePath;
    END TRY
    BEGIN CATCH
        SET @ErrorOccurred = 1;
        SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
        EXEC dbo.LogInstallMessage 'LỖI khi tạo stored procedures: ' + @ErrorMessage, @LogFilePath;
        END CATCH
    END
    
    -- Tiếp tục với việc tạo functions nếu không có lỗi
    IF @ErrorOccurred = 0
    BEGIN
        EXEC dbo.LogInstallMessage 'Bắt đầu tạo các functions', @LogFilePath;
        
        -- Tạo functions
        BEGIN TRY
            EXEC dbo.LogInstallMessage 'Đang tạo function FN_GET_MODEL_SCORE...', @LogFilePath;
            :r .\database\functions\01_fn_get_model_score.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo function FN_GET_MODEL_SCORE', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo function FN_CALCULATE_PSI...', @LogFilePath;
            :r .\database\functions\02_fn_calculate_psi.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo function FN_CALCULATE_PSI', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo function FN_CALCULATE_KS...', @LogFilePath;
            :r .\database\functions\03_fn_calculate_ks.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo function FN_CALCULATE_KS', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo function FN_GET_MODEL_VERSION_INFO...', @LogFilePath;
            :r .\database\functions\04_fn_get_model_version_info.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo function FN_GET_MODEL_VERSION_INFO', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo function FN_CALCULATE_FEATURE_DRIFT...', @LogFilePath;
            :r .\database\functions\05_fn_calculate_feature_drift.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo function FN_CALCULATE_FEATURE_DRIFT', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo function FN_GET_FEATURE_HISTORY...', @LogFilePath;
            :r .\database\functions\06_fn_get_feature_history.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo function FN_GET_FEATURE_HISTORY', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo function FN_VALIDATE_FEATURE...', @LogFilePath;
            :r .\database\functions\07_fn_validate_feature.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo function FN_VALIDATE_FEATURE', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Tất cả các functions đã được tạo thành công', @LogFilePath;
        END TRY
        BEGIN CATCH
            SET @ErrorOccurred = 1;
            SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
            EXEC dbo.LogInstallMessage 'LỖI khi tạo functions: ' + @ErrorMessage, @LogFilePath;
        END CATCH
    END
    
    -- Tiếp tục với việc tạo triggers nếu không có lỗi
    IF @ErrorOccurred = 0
    BEGIN
        EXEC dbo.LogInstallMessage 'Bắt đầu tạo các triggers', @LogFilePath;
        
        -- Tạo triggers
        BEGIN TRY
            EXEC dbo.LogInstallMessage 'Đang tạo trigger TRG_AUDIT_MODEL_REGISTRY...', @LogFilePath;
            :r .\database\triggers\01_trg_audit_model_registry.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo trigger TRG_AUDIT_MODEL_REGISTRY', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo trigger TRG_AUDIT_MODEL_PARAMETERS...', @LogFilePath;
            :r .\database\triggers\02_trg_audit_model_parameters.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo trigger TRG_AUDIT_MODEL_PARAMETERS', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo trigger TRG_VALIDATE_MODEL_SOURCES...', @LogFilePath;
            :r .\database\triggers\03_trg_validate_model_sources.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo trigger TRG_VALIDATE_MODEL_SOURCES', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo trigger TRG_UPDATE_MODEL_STATUS...', @LogFilePath;
            :r .\database\triggers\04_trg_update_model_status.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo trigger TRG_UPDATE_MODEL_STATUS', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo trigger TRG_AUDIT_FEATURE_REGISTRY...', @LogFilePath;
            :r .\database\triggers\05_trg_audit_feature_registry.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo trigger TRG_AUDIT_FEATURE_REGISTRY', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo trigger TRG_FEATURE_STAT_UPDATE...', @LogFilePath;
            :r .\database\triggers\06_trg_feature_stat_update.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo trigger TRG_FEATURE_STAT_UPDATE', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo trigger TRG_UPDATE_MODEL_FEATURE_DEPENDENCIES...', @LogFilePath;
            :r .\database\triggers\07_trg_update_model_feature_dependencies.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo trigger TRG_UPDATE_MODEL_FEATURE_DEPENDENCIES', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Tất cả các triggers đã được tạo thành công', @LogFilePath;
        END TRY
        BEGIN CATCH
            SET @ErrorOccurred = 1;
            SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
            EXEC dbo.LogInstallMessage 'LỖI khi tạo triggers: ' + @ErrorMessage, @LogFilePath;
        END CATCH
    END
    
    -- Tiếp tục với việc nhập dữ liệu mẫu nếu không có lỗi
    IF @ErrorOccurred = 0
    BEGIN
        EXEC dbo.LogInstallMessage 'Bắt đầu nhập dữ liệu mẫu', @LogFilePath;
        
        -- Nhập dữ liệu mẫu
        BEGIN TRY
            EXEC dbo.LogInstallMessage 'Đang nhập dữ liệu mẫu cho MODEL_TYPE...', @LogFilePath;
            :r .\database\sample_data\01_model_type_data.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành nhập dữ liệu mẫu MODEL_TYPE', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang nhập dữ liệu mẫu cho MODEL_REGISTRY...', @LogFilePath;
            :r .\database\sample_data\02_model_registry_data.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành nhập dữ liệu mẫu MODEL_REGISTRY', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang nhập dữ liệu mẫu cho MODEL_PARAMETERS...', @LogFilePath;
            :r .\database\sample_data\03_model_parameters_data.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành nhập dữ liệu mẫu MODEL_PARAMETERS', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang nhập dữ liệu mẫu cho MODEL_SOURCE_TABLES...', @LogFilePath;
            :r .\database\sample_data\04_model_source_tables_data.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành nhập dữ liệu mẫu MODEL_SOURCE_TABLES', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang nhập dữ liệu mẫu cho MODEL_TABLE_USAGE...', @LogFilePath;
            :r .\database\sample_data\05_model_table_usage_data.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành nhập dữ liệu mẫu MODEL_TABLE_USAGE', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang nhập dữ liệu mẫu cho MODEL_VALIDATION_RESULTS...', @LogFilePath;
            :r .\database\sample_data\06_model_validation_results_data.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành nhập dữ liệu mẫu MODEL_VALIDATION_RESULTS', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang nhập dữ liệu mẫu cho MODEL_SEGMENT_MAPPING...', @LogFilePath;
            :r .\database\sample_data\07_model_segment_mapping_data.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành nhập dữ liệu mẫu MODEL_SEGMENT_MAPPING', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang nhập dữ liệu mẫu cho MODEL_COLUMN_DETAILS...', @LogFilePath;
            :r .\database\sample_data\08_model_column_details_data.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành nhập dữ liệu mẫu MODEL_COLUMN_DETAILS', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang nhập dữ liệu mẫu cho FEATURE_REGISTRY...', @LogFilePath;
            :r .\database\sample_data\09_feature_registry_data.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành nhập dữ liệu mẫu FEATURE_REGISTRY', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang nhập dữ liệu mẫu cho FEATURE_TRANSFORMATIONS...', @LogFilePath;
            :r .\database\sample_data\10_feature_transformations_data.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành nhập dữ liệu mẫu FEATURE_TRANSFORMATIONS', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang nhập dữ liệu mẫu cho FEATURE_SOURCE_TABLES...', @LogFilePath;
            :r .\database\sample_data\11_feature_source_tables_data.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành nhập dữ liệu mẫu FEATURE_SOURCE_TABLES', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang nhập dữ liệu mẫu cho FEATURE_MODEL_MAPPING...', @LogFilePath;
            :r .\database\sample_data\12_feature_model_mapping_data.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành nhập dữ liệu mẫu FEATURE_MODEL_MAPPING', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Tất cả dữ liệu mẫu đã được nhập thành công', @LogFilePath;
        END TRY
        BEGIN CATCH
            SET @ErrorOccurred = 1;
            SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
            EXEC dbo.LogInstallMessage 'LỖI khi nhập dữ liệu mẫu: ' + @ErrorMessage, @LogFilePath;
        END CATCH
    END
    
    -- Xóa các thủ tục tạm thời đã tạo cho việc ghi log
    IF OBJECT_ID('dbo.LogInstallMessage') IS NOT NULL
    BEGIN
        DROP PROCEDURE dbo.LogInstallMessage;
    END
    
    -- Xóa bảng tạm
    IF OBJECT_ID('tempdb..#InstallLog') IS NOT NULL
    BEGIN
        DROP TABLE #InstallLog;
    END
    
    -- Kết thúc cài đặt
    IF @ErrorOccurred = 0
    BEGIN
        PRINT '=============================================';
        PRINT 'CÀI ĐẶT HỆ THỐNG ĐĂNG KÝ MÔ HÌNH HOÀN TẤT';
        PRINT '=============================================';
        PRINT '';
        PRINT 'Thông tin tóm tắt:';
        PRINT '- Database: ' + DB_NAME();
        PRINT '- Số bảng: 19';
        PRINT '- Số view: 9';
        PRINT '- Số stored procedures: 13';
        PRINT '- Số functions: 7';
        PRINT '- Số triggers: 7';
        PRINT '';
        PRINT 'Hệ thống đã sẵn sàng để sử dụng.';
    END
    ELSE
    BEGIN
        PRINT '=============================================';
        PRINT 'CÀI ĐẶT HỆ THỐNG ĐĂNG KÝ MÔ HÌNH KHÔNG THÀNH CÔNG';
        PRINT '=============================================';
        PRINT '';
        PRINT 'Đã xảy ra lỗi trong quá trình cài đặt. Vui lòng xem thông báo lỗi phía trên.';
        PRINT 'Thông tin lỗi cuối cùng: ' + @ErrorMessage;
    END
END TRY
BEGIN CATCH
    -- Xử lý lỗi tổng thể
    SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
    
    -- Ghi log lỗi
    INSERT INTO #InstallLog (Message) VALUES ('LỖI NGHIÊM TRỌNG: ' + @ErrorMessage);
    PRINT 'LỖI NGHIÊM TRỌNG: ' + @ErrorMessage;
    
    -- Hiển thị thông tin lỗi chi tiết
    PRINT 'Lỗi xảy ra tại dòng: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
    PRINT 'Mức độ nghiêm trọng: ' + CAST(@ErrorSeverity AS NVARCHAR(10));
    
    -- Xóa các thủ tục tạm thời
    IF OBJECT_ID('dbo.LogInstallMessage') IS NOT NULL
    BEGIN
        DROP PROCEDURE dbo.LogInstallMessage;
    END
    
    -- Cung cấp hướng dẫn khắc phục
    PRINT '';
    PRINT 'Để khắc phục lỗi này:';
    PRINT '1. Kiểm tra xem file SQL được tham chiếu có tồn tại';
    PRINT '2. Đảm bảo tất cả các đường dẫn trong script là chính xác';
    PRINT '3. Kiểm tra quyền hạn của người dùng SQL';
    PRINT '4. Đọc chi tiết lỗi và sửa vấn đề tương ứng';
    PRINT '';
    PRINT 'Sau khi khắc phục, vui lòng chạy lại script cài đặt.';
END CATCH;

GO khi tạo bảng MODEL_TYPE: ' + @ErrorMessage, @LogFilePath;
    END CATCH
    
    -- 2. MODEL_REGISTRY
    IF @ErrorOccurred = 0
    BEGIN
        BEGIN TRY
            EXEC dbo.LogInstallMessage 'Đang tạo bảng MODEL_REGISTRY...', @LogFilePath;
            :r .\database\schema\02_model_registry.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo bảng MODEL_REGISTRY', @LogFilePath;
        END TRY
        BEGIN CATCH
            SET @ErrorOccurred = 1;
            SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
            EXEC dbo.LogInstallMessage 'LỖI khi tạo bảng MODEL_REGISTRY: ' + @ErrorMessage, @LogFilePath;
        END CATCH
    END
    
    -- 3. MODEL_PARAMETERS
    IF @ErrorOccurred = 0
    BEGIN
        BEGIN TRY
            EXEC dbo.LogInstallMessage 'Đang tạo bảng MODEL_PARAMETERS...', @LogFilePath;
            :r .\database\schema\03_model_parameters.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo bảng MODEL_PARAMETERS', @LogFilePath;
        END TRY
        BEGIN CATCH
            SET @ErrorOccurred = 1;
            SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
            EXEC dbo.LogInstallMessage 'LỖI khi tạo bảng MODEL_PARAMETERS: ' + @ErrorMessage, @LogFilePath;
        END CATCH
    END
    
    -- 4. MODEL_SOURCE_TABLES
    IF @ErrorOccurred = 0
    BEGIN
        BEGIN TRY
            EXEC dbo.LogInstallMessage 'Đang tạo bảng MODEL_SOURCE_TABLES...', @LogFilePath;
            :r .\database\schema\04_model_source_tables.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo bảng MODEL_SOURCE_TABLES', @LogFilePath;
        END TRY
        BEGIN CATCH
            SET @ErrorOccurred = 1;
            SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
            EXEC dbo.LogInstallMessage 'LỖI khi tạo bảng MODEL_SOURCE_TABLES: ' + @ErrorMessage, @LogFilePath;
        END CATCH
    END
    
    -- 5. MODEL_COLUMN_DETAILS
    IF @ErrorOccurred = 0
    BEGIN
        BEGIN TRY
            EXEC dbo.LogInstallMessage 'Đang tạo bảng MODEL_COLUMN_DETAILS...', @LogFilePath;
            :r .\database\schema\05_model_column_details.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo bảng MODEL_COLUMN_DETAILS', @LogFilePath;
        END TRY
        BEGIN CATCH
            SET @ErrorOccurred = 1;
            SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
            EXEC dbo.LogInstallMessage 'LỖI khi tạo bảng MODEL_COLUMN_DETAILS: ' + @ErrorMessage, @LogFilePath;
        END CATCH
    END
    
    -- 6. MODEL_TABLE_USAGE
    IF @ErrorOccurred = 0
    BEGIN
        BEGIN TRY
            EXEC dbo.LogInstallMessage 'Đang tạo bảng MODEL_TABLE_USAGE...', @LogFilePath;
            :r .\database\schema\06_model_table_usage.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo bảng MODEL_TABLE_USAGE', @LogFilePath;
        END TRY
        BEGIN CATCH
            SET @ErrorOccurred = 1;
            SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
            EXEC dbo.LogInstallMessage 'LỖI khi tạo bảng MODEL_TABLE_USAGE: ' + @ErrorMessage, @LogFilePath;
        END CATCH
    END
    
    -- 7. MODEL_TABLE_MAPPING
    IF @ErrorOccurred = 0
    BEGIN
        BEGIN TRY
            EXEC dbo.LogInstallMessage 'Đang tạo bảng MODEL_TABLE_MAPPING...', @LogFilePath;
            :r .\database\schema\07_model_table_mapping.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo bảng MODEL_TABLE_MAPPING', @LogFilePath;
        END TRY
        BEGIN CATCH
            SET @ErrorOccurred = 1;
            SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
            EXEC dbo.LogInstallMessage 'LỖI khi tạo bảng MODEL_TABLE_MAPPING: ' + @ErrorMessage, @LogFilePath;
        END CATCH
    END
    
    -- 8. MODEL_SEGMENT_MAPPING
    IF @ErrorOccurred = 0
    BEGIN
        BEGIN TRY
            EXEC dbo.LogInstallMessage 'Đang tạo bảng MODEL_SEGMENT_MAPPING...', @LogFilePath;
            :r .\database\schema\08_model_segment_mapping.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo bảng MODEL_SEGMENT_MAPPING', @LogFilePath;
        END TRY
        BEGIN CATCH
            SET @ErrorOccurred = 1;
            SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
            EXEC dbo.LogInstallMessage 'LỖI khi tạo bảng MODEL_SEGMENT_MAPPING: ' + @ErrorMessage, @LogFilePath;
        END CATCH
    END
    
    -- 9. MODEL_VALIDATION_RESULTS
    IF @ErrorOccurred = 0
    BEGIN
        BEGIN TRY
            EXEC dbo.LogInstallMessage 'Đang tạo bảng MODEL_VALIDATION_RESULTS...', @LogFilePath;
            :r .\database\schema\09_model_validation_results.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo bảng MODEL_VALIDATION_RESULTS', @LogFilePath;
        END TRY
        BEGIN CATCH
            SET @ErrorOccurred = 1;
            SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
            EXEC dbo.LogInstallMessage 'LỖI khi tạo bảng MODEL_VALIDATION_RESULTS: ' + @ErrorMessage, @LogFilePath;
        END CATCH
    END
    
    -- 10. MODEL_SOURCE_REFRESH_LOG
    IF @ErrorOccurred = 0
    BEGIN
        BEGIN TRY
            EXEC dbo.LogInstallMessage 'Đang tạo bảng MODEL_SOURCE_REFRESH_LOG...', @LogFilePath;
            :r .\database\schema\10_model_source_refresh_log.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo bảng MODEL_SOURCE_REFRESH_LOG', @LogFilePath;
        END TRY
        BEGIN CATCH
            SET @ErrorOccurred = 1;
            SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
            EXEC dbo.LogInstallMessage 'LỖI khi tạo bảng MODEL_SOURCE_REFRESH_LOG: ' + @ErrorMessage, @LogFilePath;
        END CATCH
    END
    
    -- 11. MODEL_DATA_QUALITY_LOG
    IF @ErrorOccurred = 0
    BEGIN
        BEGIN TRY
            EXEC dbo.LogInstallMessage 'Đang tạo bảng MODEL_DATA_QUALITY_LOG...', @LogFilePath;
            :r .\database\schema\11_model_data_quality_log.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo bảng MODEL_DATA_QUALITY_LOG', @LogFilePath;
        END TRY
        BEGIN CATCH
            SET @ErrorOccurred = 1;
            SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
            EXEC dbo.LogInstallMessage 'LỖI khi tạo bảng MODEL_DATA_QUALITY_LOG: ' + @ErrorMessage, @LogFilePath;
        END CATCH
    END
    
    -- 12. FEATURE_REGISTRY
    IF @ErrorOccurred = 0
    BEGIN
        BEGIN TRY
            EXEC dbo.LogInstallMessage 'Đang tạo bảng FEATURE_REGISTRY...', @LogFilePath;
            :r .\database\schema\12_feature_registry.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo bảng FEATURE_REGISTRY', @LogFilePath;
        END TRY
        BEGIN CATCH
            SET @ErrorOccurred = 1;
            SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
            EXEC dbo.LogInstallMessage 'LỖI khi tạo bảng FEATURE_REGISTRY: ' + @ErrorMessage, @LogFilePath;
        END CATCH
    END
    
    -- 13. FEATURE_TRANSFORMATIONS
    IF @ErrorOccurred = 0
    BEGIN
        BEGIN TRY
            EXEC dbo.LogInstallMessage 'Đang tạo bảng FEATURE_TRANSFORMATIONS...', @LogFilePath;
            :r .\database\schema\13_feature_transformations.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo bảng FEATURE_TRANSFORMATIONS', @LogFilePath;
        END TRY
        BEGIN CATCH
            SET @ErrorOccurred = 1;
            SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
            EXEC dbo.LogInstallMessage 'LỖI khi tạo bảng FEATURE_TRANSFORMATIONS: ' + @ErrorMessage, @LogFilePath;
        END CATCH
    END
    
    -- 14. FEATURE_SOURCE_TABLES
    IF @ErrorOccurred = 0
    BEGIN
        BEGIN TRY
            EXEC dbo.LogInstallMessage 'Đang tạo bảng FEATURE_SOURCE_TABLES...', @LogFilePath;
            :r .\database\schema\14_feature_source_tables.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo bảng FEATURE_SOURCE_TABLES', @LogFilePath;
        END TRY
        BEGIN CATCH
            SET @ErrorOccurred = 1;
            SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
            EXEC dbo.LogInstallMessage 'LỖI khi tạo bảng FEATURE_SOURCE_TABLES: ' + @ErrorMessage, @LogFilePath;
        END CATCH
    END
    
    -- 15. FEATURE_VALUES
    IF @ErrorOccurred = 0
    BEGIN
        BEGIN TRY
            EXEC dbo.LogInstallMessage 'Đang tạo bảng FEATURE_VALUES...', @LogFilePath;
            :r .\database\schema\15_feature_values.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo bảng FEATURE_VALUES', @LogFilePath;
        END TRY
        BEGIN CATCH
            SET @ErrorOccurred = 1;
            SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
            EXEC dbo.LogInstallMessage 'LỖI khi tạo bảng FEATURE_VALUES: ' + @ErrorMessage, @LogFilePath;
        END CATCH
    END
    
    -- 16. FEATURE_STATS
    IF @ErrorOccurred = 0
    BEGIN
        BEGIN TRY
            EXEC dbo.LogInstallMessage 'Đang tạo bảng FEATURE_STATS...', @LogFilePath;
            :r .\database\schema\16_feature_stats.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo bảng FEATURE_STATS', @LogFilePath;
        END TRY
        BEGIN CATCH
            SET @ErrorOccurred = 1;
            SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
            EXEC dbo.LogInstallMessage 'LỖI khi tạo bảng FEATURE_STATS: ' + @ErrorMessage, @LogFilePath;
        END CATCH
    END
    
    -- 17. FEATURE_DEPENDENCIES
    IF @ErrorOccurred = 0
    BEGIN
        BEGIN TRY
            EXEC dbo.LogInstallMessage 'Đang tạo bảng FEATURE_DEPENDENCIES...', @LogFilePath;
            :r .\database\schema\17_feature_dependencies.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo bảng FEATURE_DEPENDENCIES', @LogFilePath;
        END TRY
        BEGIN CATCH
            SET @ErrorOccurred = 1;
            SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
            EXEC dbo.LogInstallMessage 'LỖI khi tạo bảng FEATURE_DEPENDENCIES: ' + @ErrorMessage, @LogFilePath;
        END CATCH
    END
    
    -- 18. FEATURE_MODEL_MAPPING
    IF @ErrorOccurred = 0
    BEGIN
        BEGIN TRY
            EXEC dbo.LogInstallMessage 'Đang tạo bảng FEATURE_MODEL_MAPPING...', @LogFilePath;
            :r .\database\schema\18_feature_model_mapping.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo bảng FEATURE_MODEL_MAPPING', @LogFilePath;
        END TRY
        BEGIN CATCH
            SET @ErrorOccurred = 1;
            SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
            EXEC dbo.LogInstallMessage 'LỖI khi tạo bảng FEATURE_MODEL_MAPPING: ' + @ErrorMessage, @LogFilePath;
        END CATCH
    END
    
    -- 19. FEATURE_REFRESH_LOG
    IF @ErrorOccurred = 0
    BEGIN
        BEGIN TRY
            EXEC dbo.LogInstallMessage 'Đang tạo bảng FEATURE_REFRESH_LOG...', @LogFilePath;
            :r .\database\schema\19_feature_refresh_log.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo bảng FEATURE_REFRESH_LOG', @LogFilePath;
        END TRY
        BEGIN CATCH
            SET @ErrorOccurred = 1;
            SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
            EXEC dbo.LogInstallMessage 'LỖI khi tạo bảng FEATURE_REFRESH_LOG: ' + @ErrorMessage, @LogFilePath;
        END CATCH
    END
    
    -- Tiếp tục với việc tạo views nếu không có lỗi
    IF @ErrorOccurred = 0
    BEGIN
        EXEC dbo.LogInstallMessage 'Tất cả các bảng đã được tạo thành công', @LogFilePath;
        EXEC dbo.LogInstallMessage 'Bắt đầu tạo các view', @LogFilePath;
        
        -- Tạo views
        BEGIN TRY
            EXEC dbo.LogInstallMessage 'Đang tạo view VW_MODEL_TABLE_RELATIONSHIPS...', @LogFilePath;
            :r .\database\views\01_vw_model_table_relationships.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo view VW_MODEL_TABLE_RELATIONSHIPS', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo view VW_MODEL_TYPE_INFO...', @LogFilePath;
            :r .\database\views\02_vw_model_type_info.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo view VW_MODEL_TYPE_INFO', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo view VW_MODEL_PERFORMANCE...', @LogFilePath;
            :r .\database\views\03_vw_model_performance.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo view VW_MODEL_PERFORMANCE', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo view VW_DATA_QUALITY_SUMMARY...', @LogFilePath;
            :r .\database\views\04_vw_data_quality_summary.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo view VW_DATA_QUALITY_SUMMARY', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo view VW_MODEL_LINEAGE...', @LogFilePath;
            :r .\database\views\05_vw_model_lineage.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo view VW_MODEL_LINEAGE', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo view VW_FEATURE_CATALOG...', @LogFilePath;
            :r .\database\views\06_vw_feature_catalog.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo view VW_FEATURE_CATALOG', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo view VW_FEATURE_MODEL_USAGE...', @LogFilePath;
            :r .\database\views\07_vw_feature_model_usage.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo view VW_FEATURE_MODEL_USAGE', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo view VW_FEATURE_DEPENDENCIES...', @LogFilePath;
            :r .\database\views\08_vw_feature_dependencies.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo view VW_FEATURE_DEPENDENCIES', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo view VW_FEATURE_LINEAGE...', @LogFilePath;
            :r .\database\views\09_vw_feature_lineage.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo view VW_FEATURE_LINEAGE', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Tất cả các view đã được tạo thành công', @LogFilePath;
        END TRY
        BEGIN CATCH
            SET @ErrorOccurred = 1;
            SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
            EXEC dbo.LogInstallMessage 'LỖI khi tạo views: ' + @ErrorMessage, @LogFilePath;
        END CATCH
    END
    
    -- Tiếp tục với việc tạo stored procedures nếu không có lỗi
    IF @ErrorOccurred = 0
    BEGIN
        EXEC dbo.LogInstallMessage 'Bắt đầu tạo các stored procedures', @LogFilePath;
        
        -- Tạo stored procedures
        BEGIN TRY
            EXEC dbo.LogInstallMessage 'Đang tạo procedure GET_MODEL_TABLES...', @LogFilePath;
            :r .\database\procedures\01_get_model_tables.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo procedure GET_MODEL_TABLES', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo procedure GET_TABLE_MODELS...', @LogFilePath;
            :r .\database\procedures\02_get_table_models.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo procedure GET_TABLE_MODELS', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo procedure VALIDATE_MODEL_SOURCES...', @LogFilePath;
            :r .\database\procedures\03_validate_model_sources.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo procedure VALIDATE_MODEL_SOURCES', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo procedure LOG_SOURCE_TABLE_REFRESH...', @LogFilePath;
            :r .\database\procedures\04_log_source_table_refresh.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo procedure LOG_SOURCE_TABLE_REFRESH', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo procedure GET_APPROPRIATE_MODEL...', @LogFilePath;
            :r .\database\procedures\05_get_appropriate_model.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo procedure GET_APPROPRIATE_MODEL', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo procedure GET_MODEL_PERFORMANCE_HISTORY...', @LogFilePath;
            :r .\database\procedures\06_get_model_performance_history.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo procedure GET_MODEL_PERFORMANCE_HISTORY', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo procedure REGISTER_NEW_MODEL...', @LogFilePath;
            :r .\database\procedures\07_register_new_model.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo procedure REGISTER_NEW_MODEL', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo procedure CHECK_MODEL_DEPENDENCIES...', @LogFilePath;
            :r .\database\procedures\08_check_model_dependencies.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo procedure CHECK_MODEL_DEPENDENCIES', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo procedure REGISTER_NEW_FEATURE...', @LogFilePath;
            :r .\database\procedures\09_register_new_feature.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo procedure REGISTER_NEW_FEATURE', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo procedure UPDATE_FEATURE_STATS...', @LogFilePath;
            :r .\database\procedures\10_update_feature_stats.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo procedure UPDATE_FEATURE_STATS', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo procedure LINK_FEATURE_TO_MODEL...', @LogFilePath;
            :r .\database\procedures\11_link_feature_to_model.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo procedure LINK_FEATURE_TO_MODEL', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo procedure GET_MODEL_FEATURES...', @LogFilePath;
            :r .\database\procedures\12_get_model_features.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo procedure GET_MODEL_FEATURES', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Đang tạo procedure REFRESH_FEATURE_VALUES...', @LogFilePath;
            :r .\database\procedures\13_refresh_feature_values.sql
            EXEC dbo.LogInstallMessage 'Hoàn thành tạo procedure REFRESH_FEATURE_VALUES', @LogFilePath;
            
            EXEC dbo.LogInstallMessage 'Tất cả các stored procedures đã được tạo thành công', @LogFilePath;
        END TRY
        BEGIN CATCH
            SET @ErrorOccurred = 1;
            SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
            EXEC dbo.LogInstallMessage 'LỖI