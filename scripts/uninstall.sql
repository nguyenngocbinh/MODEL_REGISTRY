/*
Tên file: uninstall.sql
Mô tả: Script gỡ bỏ Hệ Thống Đăng Ký Mô Hình
Tác giả: Nguyễn Ngọc Bình
Ngày cập nhật: 2025-05-17
Phiên bản: 1.1 - Enhanced with feature store support
*/

-- Thiết lập các biến cấu hình
DECLARE @CONFIRM NVARCHAR(3) = 'NO'; -- Thay đổi thành 'YES' để xác nhận gỡ bỏ
DECLARE @DROP_DATABASE NVARCHAR(3) = 'NO'; -- Thay đổi thành 'YES' để xóa toàn bộ database
DECLARE @DATABASE_NAME NVARCHAR(128) = DB_NAME();
DECLARE @ErrorMessage NVARCHAR(MAX);
DECLARE @ErrorSeverity INT;
DECLARE @ErrorState INT;

-- Xác nhận yêu cầu
IF @CONFIRM <> 'YES'
BEGIN
    PRINT '=======================================================================';
    PRINT 'CẢNH BÁO: Script này sẽ gỡ bỏ toàn bộ Hệ Thống Đăng Ký Mô Hình!';
    PRINT 'Tất cả dữ liệu sẽ bị xóa vĩnh viễn và không thể phục hồi.';
    PRINT '';
    PRINT 'Để xác nhận, vui lòng thay đổi biến @CONFIRM từ ''NO'' thành ''YES''';
    PRINT 'và chạy lại script này.';
    PRINT '=======================================================================';
    RETURN;
END

PRINT '=======================================================================';
PRINT 'BẮT ĐẦU GỠ BỎ HỆ THỐNG ĐĂNG KÝ MÔ HÌNH';
PRINT '=======================================================================';
PRINT '';
PRINT 'Database hiện tại: ' + @DATABASE_NAME;
PRINT '';

-- Kiểm tra xem database có phải là Hệ Thống Đăng Ký Mô Hình không
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'MODEL_REGISTRY')
BEGIN
    PRINT 'Không tìm thấy bảng MODEL_REGISTRY trong database ' + @DATABASE_NAME;
    PRINT 'Database có vẻ không phải là Hệ Thống Đăng Ký Mô Hình hoặc đã bị gỡ bỏ.';
    
    -- Nếu yêu cầu xóa database
    IF @DROP_DATABASE = 'YES'
    BEGIN
        PRINT 'Tiếp tục xóa database do biến @DROP_DATABASE = ''YES''';
        GOTO DropDatabase;
    END
    ELSE
    BEGIN
        PRINT 'Kết thúc gỡ bỏ.';
        RETURN;
    END
END

BEGIN TRY
    SET XACT_ABORT ON; -- Dừng transaction nếu xảy ra lỗi
    BEGIN TRANSACTION;
    
    PRINT 'Bắt đầu gỡ bỏ các đối tượng...';
    PRINT '';
    
    -- Vô hiệu hóa các ràng buộc khóa ngoại
    PRINT 'Vô hiệu hóa các ràng buộc khóa ngoại để tránh xung đột khi xóa...';
    
    -- Sử dụng cursor để vô hiệu hóa từng ràng buộc một cách an toàn
    DECLARE @DisableFKSQL NVARCHAR(MAX);
    DECLARE disable_cursor CURSOR FOR
        SELECT 'ALTER TABLE [' + OBJECT_SCHEMA_NAME(parent_object_id) + '].[' + 
               OBJECT_NAME(parent_object_id) + '] NOCHECK CONSTRAINT [' + name + ']'
        FROM sys.foreign_keys;
    
    OPEN disable_cursor;
    FETCH NEXT FROM disable_cursor INTO @DisableFKSQL;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            EXEC sp_executesql @DisableFKSQL;
        END TRY
        BEGIN CATCH
            -- Bỏ qua lỗi và tiếp tục
            PRINT '-- Bỏ qua: ' + @DisableFKSQL;
        END CATCH
        FETCH NEXT FROM disable_cursor INTO @DisableFKSQL;
    END
    
    CLOSE disable_cursor;
    DEALLOCATE disable_cursor;
    
    -- 1. Xóa các trigger (phụ thuộc vào bảng)
    PRINT 'Xóa các trigger...';
    
    -- Feature store triggers
    IF OBJECT_ID('dbo.TRG_UPDATE_MODEL_FEATURE_DEPENDENCIES', 'TR') IS NOT NULL
    BEGIN
        DROP TRIGGER dbo.TRG_UPDATE_MODEL_FEATURE_DEPENDENCIES;
        PRINT '- Đã xóa trigger TRG_UPDATE_MODEL_FEATURE_DEPENDENCIES';
    END
    
    IF OBJECT_ID('dbo.TRG_FEATURE_STAT_UPDATE', 'TR') IS NOT NULL
    BEGIN
        DROP TRIGGER dbo.TRG_FEATURE_STAT_UPDATE;
        PRINT '- Đã xóa trigger TRG_FEATURE_STAT_UPDATE';
    END
    
    IF OBJECT_ID('dbo.TRG_AUDIT_FEATURE_REGISTRY', 'TR') IS NOT NULL
    BEGIN
        DROP TRIGGER dbo.TRG_AUDIT_FEATURE_REGISTRY;
        PRINT '- Đã xóa trigger TRG_AUDIT_FEATURE_REGISTRY';
    END
    
    -- Model triggers
    IF OBJECT_ID('dbo.TRG_UPDATE_MODEL_STATUS', 'TR') IS NOT NULL
    BEGIN
        DROP TRIGGER dbo.TRG_UPDATE_MODEL_STATUS;
        PRINT '- Đã xóa trigger TRG_UPDATE_MODEL_STATUS';
    END
    
    IF OBJECT_ID('dbo.TRG_VALIDATE_MODEL_SOURCES', 'TR') IS NOT NULL
    BEGIN
        DROP TRIGGER dbo.TRG_VALIDATE_MODEL_SOURCES;
        PRINT '- Đã xóa trigger TRG_VALIDATE_MODEL_SOURCES';
    END
    
    IF OBJECT_ID('dbo.TRG_AUDIT_MODEL_PARAMETERS', 'TR') IS NOT NULL
    BEGIN
        DROP TRIGGER dbo.TRG_AUDIT_MODEL_PARAMETERS;
        PRINT '- Đã xóa trigger TRG_AUDIT_MODEL_PARAMETERS';
    END
    
    IF OBJECT_ID('dbo.TRG_AUDIT_MODEL_REGISTRY', 'TR') IS NOT NULL
    BEGIN
        DROP TRIGGER dbo.TRG_AUDIT_MODEL_REGISTRY;
        PRINT '- Đã xóa trigger TRG_AUDIT_MODEL_REGISTRY';
    END
    
    -- 2. Xóa các views
    PRINT 'Xóa các views...';
    
    -- Feature store views
    IF EXISTS (SELECT * FROM sys.views WHERE name = 'VW_FEATURE_LINEAGE')
    BEGIN
        DROP VIEW dbo.VW_FEATURE_LINEAGE;
        PRINT '- Đã xóa view VW_FEATURE_LINEAGE';
    END
    
    IF EXISTS (SELECT * FROM sys.views WHERE name = 'VW_FEATURE_DEPENDENCIES')
    BEGIN
        DROP VIEW dbo.VW_FEATURE_DEPENDENCIES;
        PRINT '- Đã xóa view VW_FEATURE_DEPENDENCIES';
    END
    
    IF EXISTS (SELECT * FROM sys.views WHERE name = 'VW_FEATURE_MODEL_USAGE')
    BEGIN
        DROP VIEW dbo.VW_FEATURE_MODEL_USAGE;
        PRINT '- Đã xóa view VW_FEATURE_MODEL_USAGE';
    END
    
    IF EXISTS (SELECT * FROM sys.views WHERE name = 'VW_FEATURE_CATALOG')
    BEGIN
        DROP VIEW dbo.VW_FEATURE_CATALOG;
        PRINT '- Đã xóa view VW_FEATURE_CATALOG';
    END
    
    -- Model views
    IF EXISTS (SELECT * FROM sys.views WHERE name = 'VW_MODEL_LINEAGE')
    BEGIN
        DROP VIEW dbo.VW_MODEL_LINEAGE;
        PRINT '- Đã xóa view VW_MODEL_LINEAGE';
    END
    
    IF EXISTS (SELECT * FROM sys.views WHERE name = 'VW_DATA_QUALITY_SUMMARY')
    BEGIN
        DROP VIEW dbo.VW_DATA_QUALITY_SUMMARY;
        PRINT '- Đã xóa view VW_DATA_QUALITY_SUMMARY';
    END
    
    IF EXISTS (SELECT * FROM sys.views WHERE name = 'VW_MODEL_PERFORMANCE')
    BEGIN
        DROP VIEW dbo.VW_MODEL_PERFORMANCE;
        PRINT '- Đã xóa view VW_MODEL_PERFORMANCE';
    END
    
    IF EXISTS (SELECT * FROM sys.views WHERE name = 'VW_MODEL_TYPE_INFO')
    BEGIN
        DROP VIEW dbo.VW_MODEL_TYPE_INFO;
        PRINT '- Đã xóa view VW_MODEL_TYPE_INFO';
    END
    
    IF EXISTS (SELECT * FROM sys.views WHERE name = 'VW_MODEL_TABLE_RELATIONSHIPS')
    BEGIN
        DROP VIEW dbo.VW_MODEL_TABLE_RELATIONSHIPS;
        PRINT '- Đã xóa view VW_MODEL_TABLE_RELATIONSHIPS';
    END
    
    -- 3. Xóa các stored procedures
    PRINT 'Xóa các stored procedures...';
    
    -- Feature store procedures
    IF OBJECT_ID('dbo.REFRESH_FEATURE_VALUES', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE dbo.REFRESH_FEATURE_VALUES;
        PRINT '- Đã xóa procedure REFRESH_FEATURE_VALUES';
    END
    
    IF OBJECT_ID('dbo.GET_MODEL_FEATURES', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE dbo.GET_MODEL_FEATURES;
        PRINT '- Đã xóa procedure GET_MODEL_FEATURES';
    END
    
    IF OBJECT_ID('dbo.LINK_FEATURE_TO_MODEL', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE dbo.LINK_FEATURE_TO_MODEL;
        PRINT '- Đã xóa procedure LINK_FEATURE_TO_MODEL';
    END
    
    IF OBJECT_ID('dbo.UPDATE_FEATURE_STATS', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE dbo.UPDATE_FEATURE_STATS;
        PRINT '- Đã xóa procedure UPDATE_FEATURE_STATS';
    END
    
    IF OBJECT_ID('dbo.REGISTER_NEW_FEATURE', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE dbo.REGISTER_NEW_FEATURE;
        PRINT '- Đã xóa procedure REGISTER_NEW_FEATURE';
    END
    
    -- Model procedures
    IF OBJECT_ID('dbo.CHECK_MODEL_DEPENDENCIES', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE dbo.CHECK_MODEL_DEPENDENCIES;
        PRINT '- Đã xóa procedure CHECK_MODEL_DEPENDENCIES';
    END
    
    IF OBJECT_ID('dbo.REGISTER_NEW_MODEL', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE dbo.REGISTER_NEW_MODEL;
        PRINT '- Đã xóa procedure REGISTER_NEW_MODEL';
    END
    
    IF OBJECT_ID('dbo.GET_MODEL_PERFORMANCE_HISTORY', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE dbo.GET_MODEL_PERFORMANCE_HISTORY;
        PRINT '- Đã xóa procedure GET_MODEL_PERFORMANCE_HISTORY';
    END
    
    IF OBJECT_ID('dbo.GET_APPROPRIATE_MODEL', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE dbo.GET_APPROPRIATE_MODEL;
        PRINT '- Đã xóa procedure GET_APPROPRIATE_MODEL';
    END
    
    IF OBJECT_ID('dbo.LOG_SOURCE_TABLE_REFRESH', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE dbo.LOG_SOURCE_TABLE_REFRESH;
        PRINT '- Đã xóa procedure LOG_SOURCE_TABLE_REFRESH';
    END
    
    IF OBJECT_ID('dbo.VALIDATE_MODEL_SOURCES', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE dbo.VALIDATE_MODEL_SOURCES;
        PRINT '- Đã xóa procedure VALIDATE_MODEL_SOURCES';
    END
    
    IF OBJECT_ID('dbo.GET_TABLE_MODELS', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE dbo.GET_TABLE_MODELS;
        PRINT '- Đã xóa procedure GET_TABLE_MODELS';
    END
    
    IF OBJECT_ID('dbo.GET_MODEL_TABLES', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE dbo.GET_MODEL_TABLES;
        PRINT '- Đã xóa procedure GET_MODEL_TABLES';
    END
    
    -- 4. Xóa các functions
    PRINT 'Xóa các functions...';
    
    -- Feature store functions
    IF OBJECT_ID('dbo.FN_VALIDATE_FEATURE', 'FN') IS NOT NULL
    BEGIN
        DROP FUNCTION dbo.FN_VALIDATE_FEATURE;
        PRINT '- Đã xóa function FN_VALIDATE_FEATURE';
    END
    
    IF OBJECT_ID('dbo.FN_GET_FEATURE_HISTORY', 'FN') IS NOT NULL
    BEGIN
        DROP FUNCTION dbo.FN_GET_FEATURE_HISTORY;
        PRINT '- Đã xóa function FN_GET_FEATURE_HISTORY';
    END
    
    IF OBJECT_ID('dbo.FN_CALCULATE_FEATURE_DRIFT', 'FN') IS NOT NULL
    BEGIN
        DROP FUNCTION dbo.FN_CALCULATE_FEATURE_DRIFT;
        PRINT '- Đã xóa function FN_CALCULATE_FEATURE_DRIFT';
    END
    
    -- Model functions
    IF OBJECT_ID('dbo.FN_GET_MODEL_VERSION_INFO', 'FN') IS NOT NULL
    BEGIN
        DROP FUNCTION dbo.FN_GET_MODEL_VERSION_INFO;
        PRINT '- Đã xóa function FN_GET_MODEL_VERSION_INFO';
    END
    
    IF OBJECT_ID('dbo.FN_CALCULATE_KS', 'FN') IS NOT NULL
    BEGIN
        DROP FUNCTION dbo.FN_CALCULATE_KS;
        PRINT '- Đã xóa function FN_CALCULATE_KS';
    END
    
    IF OBJECT_ID('dbo.FN_CALCULATE_PSI', 'FN') IS NOT NULL
    BEGIN
        DROP FUNCTION dbo.FN_CALCULATE_PSI;
        PRINT '- Đã xóa function FN_CALCULATE_PSI';
    END
    
    IF OBJECT_ID('dbo.FN_GET_MODEL_SCORE', 'FN') IS NOT NULL
    BEGIN
        DROP FUNCTION dbo.FN_GET_MODEL_SCORE;
        PRINT '- Đã xóa function FN_GET_MODEL_SCORE';
    END
    
    -- 5. Xóa các bảng audit
    PRINT 'Xóa các bảng audit...';
    
    IF OBJECT_ID('dbo.AUDIT_FEATURE_REGISTRY', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.AUDIT_FEATURE_REGISTRY;
        PRINT '- Đã xóa bảng AUDIT_FEATURE_REGISTRY';
    END
    
    IF OBJECT_ID('dbo.AUDIT_MODEL_PARAMETERS', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.AUDIT_MODEL_PARAMETERS;
        PRINT '- Đã xóa bảng AUDIT_MODEL_PARAMETERS';
    END
    
    IF OBJECT_ID('dbo.AUDIT_MODEL_REGISTRY', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.AUDIT_MODEL_REGISTRY;
        PRINT '- Đã xóa bảng AUDIT_MODEL_REGISTRY';
    END
    
    -- 6. Xóa các bảng chính theo thứ tự phụ thuộc
    PRINT 'Xóa các bảng chính...';
    
    -- Xóa các bảng feature store (phụ thuộc)
    IF OBJECT_ID('dbo.FEATURE_REFRESH_LOG', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.FEATURE_REFRESH_LOG;
        PRINT '- Đã xóa bảng FEATURE_REFRESH_LOG';
    END
    
    IF OBJECT_ID('dbo.FEATURE_MODEL_MAPPING', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.FEATURE_MODEL_MAPPING;
        PRINT '- Đã xóa bảng FEATURE_MODEL_MAPPING';
    END
    
    IF OBJECT_ID('dbo.FEATURE_DEPENDENCIES', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.FEATURE_DEPENDENCIES;
        PRINT '- Đã xóa bảng FEATURE_DEPENDENCIES';
    END
    
    IF OBJECT_ID('dbo.FEATURE_STATS', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.FEATURE_STATS;
        PRINT '- Đã xóa bảng FEATURE_STATS';
    END
    
    IF OBJECT_ID('dbo.FEATURE_VALUES', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.FEATURE_VALUES;
        PRINT '- Đã xóa bảng FEATURE_VALUES';
    END
    
    IF OBJECT_ID('dbo.FEATURE_SOURCE_TABLES', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.FEATURE_SOURCE_TABLES;
        PRINT '- Đã xóa bảng FEATURE_SOURCE_TABLES';
    END
    
    IF OBJECT_ID('dbo.FEATURE_TRANSFORMATIONS', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.FEATURE_TRANSFORMATIONS;
        PRINT '- Đã xóa bảng FEATURE_TRANSFORMATIONS';
    END
    
    IF OBJECT_ID('dbo.FEATURE_REGISTRY', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.FEATURE_REGISTRY;
        PRINT '- Đã xóa bảng FEATURE_REGISTRY';
    END
    
    -- Xóa các bảng phụ thuộc model (chứa khóa ngoại)
    IF OBJECT_ID('dbo.MODEL_DATA_QUALITY_LOG', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.MODEL_DATA_QUALITY_LOG;
        PRINT '- Đã xóa bảng MODEL_DATA_QUALITY_LOG';
    END
    
    IF OBJECT_ID('dbo.MODEL_SOURCE_REFRESH_LOG', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.MODEL_SOURCE_REFRESH_LOG;
        PRINT '- Đã xóa bảng MODEL_SOURCE_REFRESH_LOG';
    END
    
    IF OBJECT_ID('dbo.MODEL_VALIDATION_RESULTS', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.MODEL_VALIDATION_RESULTS;
        PRINT '- Đã xóa bảng MODEL_VALIDATION_RESULTS';
    END
    
    IF OBJECT_ID('dbo.MODEL_SEGMENT_MAPPING', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.MODEL_SEGMENT_MAPPING;
        PRINT '- Đã xóa bảng MODEL_SEGMENT_MAPPING';
    END
    
    IF OBJECT_ID('dbo.MODEL_TABLE_MAPPING', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.MODEL_TABLE_MAPPING;
        PRINT '- Đã xóa bảng MODEL_TABLE_MAPPING';
    END
    
    IF OBJECT_ID('dbo.MODEL_TABLE_USAGE', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.MODEL_TABLE_USAGE;
        PRINT '- Đã xóa bảng MODEL_TABLE_USAGE';
    END
    
    IF OBJECT_ID('dbo.MODEL_COLUMN_DETAILS', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.MODEL_COLUMN_DETAILS;
        PRINT '- Đã xóa bảng MODEL_COLUMN_DETAILS';
    END
    
    IF OBJECT_ID('dbo.MODEL_PARAMETERS', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.MODEL_PARAMETERS;
        PRINT '- Đã xóa bảng MODEL_PARAMETERS';
    END
    
    -- Xóa các bảng chính (không có khóa ngoại hoặc đã giải phóng các phụ thuộc)
    IF OBJECT_ID('dbo.MODEL_SOURCE_TABLES', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.MODEL_SOURCE_TABLES;
        PRINT '- Đã xóa bảng MODEL_SOURCE_TABLES';
    END
    
    IF OBJECT_ID('dbo.MODEL_REGISTRY', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.MODEL_REGISTRY;
        PRINT '- Đã xóa bảng MODEL_REGISTRY';
    END
    
    IF OBJECT_ID('dbo.MODEL_TYPE', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.MODEL_TYPE;
        PRINT '- Đã xóa bảng MODEL_TYPE';
    END
    
    PRINT '';
    PRINT N'Tất cả các đối tượng của Hệ Thống Đăng Ký Mô Hình đã được gỡ bỏ thành công.';
    
    COMMIT TRANSACTION;
    
DropDatabase:
    -- Xóa database nếu yêu cầu
    IF @DROP_DATABASE = 'YES'
    BEGIN
        -- Không thể xóa database hiện tại, cần chuyển về master
        PRINT '';
        PRINT 'Chuẩn bị xóa database ' + @DATABASE_NAME + '...';
        
        -- Đảm bảo không có kết nối nào đến database
        DECLARE @KillConnectionsSQL NVARCHAR(MAX) = N'
        USE master;
        
        DECLARE @kill varchar(8000) = '''';  
        SELECT @kill = @kill + ''kill '' + CONVERT(varchar(5), session_id) + '';''  
        FROM sys.dm_exec_sessions
        WHERE database_id  = db_id(''' + @DATABASE_NAME + ''')
        
        EXEC(@kill);
        ';
        
        BEGIN TRY
            EXEC sp_executesql @KillConnectionsSQL;
            PRINT 'Đã đóng tất cả kết nối đến database ' + @DATABASE_NAME;
        END TRY
        BEGIN CATCH
            PRINT 'Cảnh báo: Không thể đóng tất cả kết nối đến database. Quá trình xóa database có thể thất bại.';
        END CATCH
        
        -- Tạo một câu lệnh động để xóa database
        DECLARE @SQL NVARCHAR(200) = N'USE master; DROP DATABASE [' + @DATABASE_NAME + '];';
        
        -- In thông báo
        PRINT 'Thực thi: ' + @SQL;
        
        -- Thực hiện xóa database nếu không phải là database hiện tại
        IF DB_NAME() <> @DATABASE_NAME
        BEGIN
            BEGIN TRY
                EXEC sp_executesql @SQL;
                PRINT 'Database ' + @DATABASE_NAME + ' đã được xóa thành công.';
            END TRY
            BEGIN CATCH
                SELECT @ErrorMessage = ERROR_MESSAGE();
                PRINT 'Lỗi khi xóa database: ' + @ErrorMessage;
                PRINT '';
                PRINT 'Để hoàn tất việc xóa database, vui lòng chạy lệnh sau trong một phiên query mới:';
                PRINT @SQL;
            END CATCH
        END
        ELSE
        BEGIN
            PRINT '';
            PRINT 'LƯU Ý: Database hiện tại không thể tự xóa chính nó.';
            PRINT 'Để hoàn tất việc xóa database, vui lòng chạy lệnh sau trong một phiên query mới:';
            PRINT @SQL;
        END
    END
    
    PRINT '';
    PRINT '=======================================================================';
    PRINT 'GỠ BỎ HỆ THỐNG ĐĂNG KÝ MÔ HÌNH HOÀN TẤT';
    PRINT '=======================================================================';
    
END TRY
BEGIN CATCH
    -- Xử lý lỗi
    SELECT @ErrorMessage = ERROR_MESSAGE(), 
           @ErrorSeverity = ERROR_SEVERITY(),
           @ErrorState = ERROR_STATE();
           
    PRINT 'Đã xảy ra lỗi trong quá trình gỡ bỏ:';
    PRINT 'Mã lỗi: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10));
    PRINT 'Thông báo: ' + @ErrorMessage;
    PRINT 'Dòng: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
    
    -- Rollback transaction nếu đang trong transaction
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
        
    -- Cung cấp thông tin về cách thủ công để xóa các đối tượng còn lại
    PRINT '';
    PRINT 'LỜI KHUYÊN:';
    PRINT '- Các đối tượng còn lại có thể được xóa thủ công theo thứ tự:';
    PRINT '  1. Triggers';
    PRINT '  2. Views';
    PRINT '  3. Stored Procedures';
    PRINT '  4. Functions';
    PRINT '  5. Các bảng có quan hệ phụ thuộc';
    PRINT '  6. Các bảng chính';
    PRINT '';
    PRINT 'Vui lòng kiểm tra lỗi, khắc phục và thử lại.';
END CATCH;
GO