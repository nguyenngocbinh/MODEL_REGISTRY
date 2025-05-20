/*
Tên file: install_all.sql
Mô tả: Script chính để cài đặt toàn bộ hệ thống Đăng Ký Mô Hình
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-20
Phiên bản: 1.2 - Simplified version
*/

SET NOCOUNT ON;
GO

-- Cleanup các cursor có thể còn sót lại
IF CURSOR_STATUS('global','file_cursor') >= -1
    DEALLOCATE file_cursor;
GO

-- Đặt đường dẫn cơ sở
DECLARE @BasePath NVARCHAR(500) = 'd:\TPB\MODEL_REGISTRY';

PRINT '=============================================';
PRINT N'BẮT ĐẦU CÀI ĐẶT HỆ THỐNG ĐĂNG KÝ MÔ HÌNH';
PRINT '=============================================';

-- Danh sách các file cần cài đặt theo thứ tự
DECLARE @FileList TABLE (
    ID INT IDENTITY(1,1),
    FileType NVARCHAR(50),
    FilePath NVARCHAR(500)
);

-- Thêm các file theo thứ tự cài đặt
INSERT INTO @FileList (FileType, FilePath) VALUES
-- Tables
('TABLE', @BasePath + '\database\schema\01_model_type.sql'),
('TABLE', @BasePath + '\database\schema\02_model_registry.sql'),
('TABLE', @BasePath + '\database\schema\03_model_parameters.sql'),
('TABLE', @BasePath + '\database\schema\04_model_source_tables.sql'),
('TABLE', @BasePath + '\database\schema\05_model_column_details.sql'),
('TABLE', @BasePath + '\database\schema\06_model_table_usage.sql'),
('TABLE', @BasePath + '\database\schema\07_model_table_mapping.sql'),
('TABLE', @BasePath + '\database\schema\08_model_segment_mapping.sql'),
('TABLE', @BasePath + '\database\schema\09_model_validation_results.sql'),
('TABLE', @BasePath + '\database\schema\10_model_source_refresh_log.sql'),
('TABLE', @BasePath + '\database\schema\11_model_data_quality_log.sql'),
('TABLE', @BasePath + '\database\schema\12_feature_registry.sql'),
('TABLE', @BasePath + '\database\schema\13_feature_transformations.sql'),
('TABLE', @BasePath + '\database\schema\14_feature_source_tables.sql'),
('TABLE', @BasePath + '\database\schema\15_feature_values.sql'),
('TABLE', @BasePath + '\database\schema\16_feature_stats.sql'),
('TABLE', @BasePath + '\database\schema\17_feature_dependencies.sql'),
('TABLE', @BasePath + '\database\schema\18_feature_model_mapping.sql'),
('TABLE', @BasePath + '\database\schema\19_feature_refresh_log.sql'),
-- Views
('VIEW', @BasePath + '\database\views\01_vw_model_table_relationships.sql'),
('VIEW', @BasePath + '\database\views\02_vw_model_type_info.sql'),
('VIEW', @BasePath + '\database\views\03_vw_model_performance.sql'),
('VIEW', @BasePath + '\database\views\04_vw_data_quality_summary.sql'),
('VIEW', @BasePath + '\database\views\05_vw_model_lineage.sql'),
('VIEW', @BasePath + '\database\views\06_vw_feature_catalog.sql'),
('VIEW', @BasePath + '\database\views\07_vw_feature_model_usage.sql'),
('VIEW', @BasePath + '\database\views\08_vw_feature_dependencies.sql'),
('VIEW', @BasePath + '\database\views\09_vw_feature_lineage.sql'),
-- Functions
('FUNCTION', @BasePath + '\database\functions\01_fn_get_model_score.sql'),
('FUNCTION', @BasePath + '\database\functions\02_fn_calculate_psi.sql'),
('FUNCTION', @BasePath + '\database\functions\03_fn_calculate_ks.sql'),
('FUNCTION', @BasePath + '\database\functions\04_fn_get_model_version_info.sql'),
('FUNCTION', @BasePath + '\database\functions\05_fn_calculate_feature_drift.sql'),
('FUNCTION', @BasePath + '\database\functions\06_fn_get_feature_history.sql'),
('FUNCTION', @BasePath + '\database\functions\07_fn_validate_feature.sql'),
-- Triggers
('TRIGGER', @BasePath + '\database\triggers\01_trg_audit_model_registry.sql'),
('TRIGGER', @BasePath + '\database\triggers\02_trg_audit_model_parameters.sql'),
('TRIGGER', @BasePath + '\database\triggers\03_trg_validate_model_sources.sql'),
('TRIGGER', @BasePath + '\database\triggers\04_trg_update_model_status.sql'),
('TRIGGER', @BasePath + '\database\triggers\05_trg_audit_feature_registry.sql'),
('TRIGGER', @BasePath + '\database\triggers\06_trg_feature_stat_update.sql'),
('TRIGGER', @BasePath + '\database\triggers\07_trg_update_model_feature_dependencies.sql'),
-- Sample Data
('DATA', @BasePath + '\database\sample_data\01_model_type_data.sql'),
('DATA', @BasePath + '\database\sample_data\02_model_registry_data.sql'),
('DATA', @BasePath + '\database\sample_data\03_model_parameters_data.sql'),
('DATA', @BasePath + '\database\sample_data\04_model_source_tables_data.sql'),
('DATA', @BasePath + '\database\sample_data\05_model_table_usage_data.sql'),
('DATA', @BasePath + '\database\sample_data\06_model_validation_results_data.sql'),
('DATA', @BasePath + '\database\sample_data\07_model_segment_mapping_data.sql'),
('DATA', @BasePath + '\database\sample_data\08_model_column_details_data.sql'),
('DATA', @BasePath + '\database\sample_data\09_feature_registry_data.sql'),
('DATA', @BasePath + '\database\sample_data\10_feature_transformations_data.sql'),
('DATA', @BasePath + '\database\sample_data\11_feature_source_tables_data.sql'),
('DATA', @BasePath + '\database\sample_data\12_feature_model_mapping_data.sql');

-- Cài đặt từng file
BEGIN TRY
    DECLARE @CurrentID INT = 1;
    DECLARE @MaxID INT;
    DECLARE @CurrentType NVARCHAR(50);
    DECLARE @CurrentPath NVARCHAR(500);
    DECLARE @LastType NVARCHAR(50) = '';
    DECLARE @Cmd NVARCHAR(4000);
    
    SELECT @MaxID = MAX(ID) FROM @FileList;
    
    -- Kích hoạt xp_cmdshell
    EXEC sp_configure 'show advanced options', 1; RECONFIGURE;
    EXEC sp_configure 'xp_cmdshell', 1; RECONFIGURE;
    
    WHILE @CurrentID <= @MaxID
    BEGIN
        SELECT @CurrentType = FileType, @CurrentPath = FilePath 
        FROM @FileList WHERE ID = @CurrentID;
        
        -- In header cho nhóm mới
        IF @LastType <> @CurrentType
        BEGIN
            PRINT '';
            PRINT N'Đang cài đặt các ' + @CurrentType;
            PRINT '---------------------------------------------';
            SET @LastType = @CurrentType;
        END
        
        -- Kiểm tra file tồn tại
        DECLARE @FileCheck TABLE (result NVARCHAR(255));
        SET @Cmd = 'IF EXIST "' + @CurrentPath + '" (echo EXISTS) ELSE (echo NOT_FOUND)';
        
        DELETE FROM @FileCheck;
        INSERT INTO @FileCheck EXEC xp_cmdshell @Cmd;
        
        IF EXISTS (SELECT 1 FROM @FileCheck WHERE result = 'EXISTS')
        BEGIN
            PRINT 'Executing: ' + @CurrentPath;
            SET @Cmd = 'sqlcmd -E -d ' + DB_NAME() + ' -i "' + @CurrentPath + '" -b';
            EXEC xp_cmdshell @Cmd;
        END
        ELSE
        BEGIN
            PRINT 'WARNING: File not found - ' + @CurrentPath;
        END
        
        SET @CurrentID = @CurrentID + 1;
    END
    
    -- Tắt xp_cmdshell
    EXEC sp_configure 'xp_cmdshell', 0; RECONFIGURE;
    EXEC sp_configure 'show advanced options', 0; RECONFIGURE;
    
    PRINT '';
    PRINT '=============================================';
    PRINT N'CÀI ĐẶT HỆ THỐNG HOÀN TẤT!';
    PRINT '=============================================';
    
END TRY
BEGIN CATCH
    -- Tắt xp_cmdshell trong trường hợp lỗi
    EXEC sp_configure 'xp_cmdshell', 0; RECONFIGURE;
    EXEC sp_configure 'show advanced options', 0; RECONFIGURE;
    
    PRINT '';
    PRINT N'LỖI: ' + ERROR_MESSAGE();
    PRINT N'Vui lòng kiểm tra và chạy lại script.';
END CATCH;

PRINT '';
PRINT N'Lưu ý:';
PRINT N'- Nếu có file không tồn tại, hãy kiểm tra đường dẫn';
PRINT N'- Script sử dụng sqlcmd để thực thi file';
PRINT N'- Có thể chạy từng file riêng nếu cần thiết';

GO