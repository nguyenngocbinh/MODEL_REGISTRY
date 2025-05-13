/*
Tên file: uninstall.sql
Mô tả: Script gỡ bỏ Hệ Thống Đăng Ký Mô Hình
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-12
Phiên bản: 1.0
*/

-- Thiết lập các biến cấu hình
DECLARE @CONFIRM NVARCHAR(3) = 'NO'; -- Thay đổi thành 'YES' để xác nhận gỡ bỏ
DECLARE @DROP_DATABASE NVARCHAR(3) = 'NO'; -- Thay đổi thành 'YES' để xóa toàn bộ database
DECLARE @DATABASE_NAME NVARCHAR(128) = DB_NAME();

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
    BEGIN TRANSACTION;
    
    PRINT 'Bắt đầu gỡ bỏ các đối tượng...';
    PRINT '';
    
    -- Vô hiệu hóa các ràng buộc khóa ngoại
    PRINT 'Vô hiệu hóa các ràng buộc khóa ngoại để tránh xung đột khi xóa...';
    EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';
    
    -- 1. Xóa các trigger (phụ thuộc vào bảng)
    PRINT 'Xóa các trigger...';
    IF OBJECT_ID('MODEL_REGISTRY.dbo.TRG_AUDIT_MODEL_PARAMETERS', 'TR') IS NOT NULL
    BEGIN
        DROP TRIGGER MODEL_REGISTRY.dbo.TRG_AUDIT_MODEL_PARAMETERS;
        PRINT '- Đã xóa trigger TRG_AUDIT_MODEL_PARAMETERS';
    END
    
    IF OBJECT_ID('MODEL_REGISTRY.dbo.TRG_AUDIT_MODEL_REGISTRY', 'TR') IS NOT NULL
    BEGIN
        DROP TRIGGER MODEL_REGISTRY.dbo.TRG_AUDIT_MODEL_REGISTRY;
        PRINT '- Đã xóa trigger TRG_AUDIT_MODEL_REGISTRY';
    END
    
    IF OBJECT_ID('MODEL_REGISTRY.dbo.TRG_SET_GINI_THRESHOLDS', 'TR') IS NOT NULL
    BEGIN
        DROP TRIGGER MODEL_REGISTRY.dbo.TRG_SET_GINI_THRESHOLDS;
        PRINT '- Đã xóa trigger TRG_SET_GINI_THRESHOLDS';
    END
    
    -- 2. Xóa các views
    PRINT 'Xóa các views...';
    
    IF EXISTS (SELECT * FROM sys.views WHERE name = 'VW_MODEL_PERFORMANCE' AND schema_id = SCHEMA_ID('dbo'))
    BEGIN
        DROP VIEW MODEL_REGISTRY.dbo.VW_MODEL_PERFORMANCE;
        PRINT '- Đã xóa view VW_MODEL_PERFORMANCE';
    END
    
    IF EXISTS (SELECT * FROM sys.views WHERE name = 'VW_MODEL_TYPE_INFO' AND schema_id = SCHEMA_ID('dbo'))
    BEGIN
        DROP VIEW MODEL_REGISTRY.dbo.VW_MODEL_TYPE_INFO;
        PRINT '- Đã xóa view VW_MODEL_TYPE_INFO';
    END
    
    IF EXISTS (SELECT * FROM sys.views WHERE name = 'VW_MODEL_TABLE_RELATIONSHIPS' AND schema_id = SCHEMA_ID('dbo'))
    BEGIN
        DROP VIEW MODEL_REGISTRY.dbo.VW_MODEL_TABLE_RELATIONSHIPS;
        PRINT '- Đã xóa view VW_MODEL_TABLE_RELATIONSHIPS';
    END
    
    -- 3. Xóa các stored procedures
    PRINT 'Xóa các stored procedures...';
    
    IF OBJECT_ID('MODEL_REGISTRY.dbo.GET_MODEL_PERFORMANCE_HISTORY', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE MODEL_REGISTRY.dbo.GET_MODEL_PERFORMANCE_HISTORY;
        PRINT '- Đã xóa procedure GET_MODEL_PERFORMANCE_HISTORY';
    END
    
    IF OBJECT_ID('MODEL_REGISTRY.dbo.GET_APPROPRIATE_MODEL', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE MODEL_REGISTRY.dbo.GET_APPROPRIATE_MODEL;
        PRINT '- Đã xóa procedure GET_APPROPRIATE_MODEL';
    END
    
    IF OBJECT_ID('MODEL_REGISTRY.dbo.LOG_SOURCE_TABLE_REFRESH', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE MODEL_REGISTRY.dbo.LOG_SOURCE_TABLE_REFRESH;
        PRINT '- Đã xóa procedure LOG_SOURCE_TABLE_REFRESH';
    END
    
    IF OBJECT_ID('MODEL_REGISTRY.dbo.VALIDATE_MODEL_SOURCES', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE MODEL_REGISTRY.dbo.VALIDATE_MODEL_SOURCES;
        PRINT '- Đã xóa procedure VALIDATE_MODEL_SOURCES';
    END
    
    IF OBJECT_ID('MODEL_REGISTRY.dbo.GET_TABLE_MODELS', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE MODEL_REGISTRY.dbo.GET_TABLE_MODELS;
        PRINT '- Đã xóa procedure GET_TABLE_MODELS';
    END
    
    IF OBJECT_ID('MODEL_REGISTRY.dbo.GET_MODEL_TABLES', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE MODEL_REGISTRY.dbo.GET_MODEL_TABLES;
        PRINT '- Đã xóa procedure GET_MODEL_TABLES';
    END
    
    IF OBJECT_ID('MODEL_REGISTRY.dbo.EVALUATE_MODEL_PERFORMANCE', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE MODEL_REGISTRY.dbo.EVALUATE_MODEL_PERFORMANCE;
        PRINT '- Đã xóa procedure EVALUATE_MODEL_PERFORMANCE';
    END
    
    IF OBJECT_ID('MODEL_REGISTRY.dbo.SET_PARAMETER_CHANGE_REASON', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE MODEL_REGISTRY.dbo.SET_PARAMETER_CHANGE_REASON;
        PRINT '- Đã xóa procedure SET_PARAMETER_CHANGE_REASON';
    END
    
    -- 4. Xóa các functions
    PRINT 'Xóa các functions...';
    
    IF OBJECT_ID('MODEL_REGISTRY.dbo.FN_CALCULATE_PSI_TABLES', 'FN') IS NOT NULL
    BEGIN
        DROP FUNCTION MODEL_REGISTRY.dbo.FN_CALCULATE_PSI_TABLES;
        PRINT '- Đã xóa function FN_CALCULATE_PSI_TABLES';
    END
    
    IF OBJECT_ID('MODEL_REGISTRY.dbo.FN_CALCULATE_PSI', 'FN') IS NOT NULL
    BEGIN
        DROP FUNCTION MODEL_REGISTRY.dbo.FN_CALCULATE_PSI;
        PRINT '- Đã xóa function FN_CALCULATE_PSI';
    END
    
    IF OBJECT_ID('MODEL_REGISTRY.dbo.FN_GET_MODEL_SCORE', 'FN') IS NOT NULL
    BEGIN
        DROP FUNCTION MODEL_REGISTRY.dbo.FN_GET_MODEL_SCORE;
        PRINT '- Đã xóa function FN_GET_MODEL_SCORE';
    END
    
    -- 5. Xóa các bảng audit
    PRINT 'Xóa các bảng audit...';
    
    IF OBJECT_ID('MODEL_REGISTRY.dbo.AUDIT_MODEL_PARAMETERS', 'U') IS NOT NULL
    BEGIN
        DROP TABLE MODEL_REGISTRY.dbo.AUDIT_MODEL_PARAMETERS;
        PRINT '- Đã xóa bảng AUDIT_MODEL_PARAMETERS';
    END
    
    IF OBJECT_ID('MODEL_REGISTRY.dbo.AUDIT_MODEL_REGISTRY', 'U') IS NOT NULL
    BEGIN
        DROP TABLE MODEL_REGISTRY.dbo.AUDIT_MODEL_REGISTRY;
        PRINT '- Đã xóa bảng AUDIT_MODEL_REGISTRY';
    END
    
    -- 6. Xóa các bảng chính theo thứ tự phụ thuộc
    PRINT 'Xóa các bảng chính...';
    
    -- Xóa các bảng phụ thuộc (chứa khóa ngoại)
    IF OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG', 'U') IS NOT NULL
    BEGIN
        DROP TABLE MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG;
        PRINT '- Đã xóa bảng MODEL_DATA_QUALITY_LOG';
    END
    
    IF OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG', 'U') IS NOT NULL
    BEGIN
        DROP TABLE MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG;
        PRINT '- Đã xóa bảng MODEL_SOURCE_REFRESH_LOG';
    END
    
    IF OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS', 'U') IS NOT NULL
    BEGIN
        DROP TABLE MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS;
        PRINT '- Đã xóa bảng MODEL_VALIDATION_RESULTS';
    END
    
    IF OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_SEGMENT_MAPPING', 'U') IS NOT NULL
    BEGIN
        DROP TABLE MODEL_REGISTRY.dbo.MODEL_SEGMENT_MAPPING;
        PRINT '- Đã xóa bảng MODEL_SEGMENT_MAPPING';
    END
    
    IF OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING', 'U') IS NOT NULL
    BEGIN
        DROP TABLE MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING;
        PRINT '- Đã xóa bảng MODEL_TABLE_MAPPING';
    END
    
    IF OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE', 'U') IS NOT NULL
    BEGIN
        DROP TABLE MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE;
        PRINT '- Đã xóa bảng MODEL_TABLE_USAGE';
    END
    
    IF OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS', 'U') IS NOT NULL
    BEGIN
        DROP TABLE MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS;
        PRINT '- Đã xóa bảng MODEL_COLUMN_DETAILS';
    END
    
    IF OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_PARAMETERS', 'U') IS NOT NULL
    BEGIN
        DROP TABLE MODEL_REGISTRY.dbo.MODEL_PARAMETERS;
        PRINT '- Đã xóa bảng MODEL_PARAMETERS';
    END
    
    -- Xóa các bảng chính (không có khóa ngoại hoặc đã giải phóng các phụ thuộc)
    IF OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES', 'U') IS NOT NULL
    BEGIN
        DROP TABLE MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES;
        PRINT '- Đã xóa bảng MODEL_SOURCE_TABLES';
    END
    
    IF OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_REGISTRY', 'U') IS NOT NULL
    BEGIN
        DROP TABLE MODEL_REGISTRY.dbo.MODEL_REGISTRY;
        PRINT '- Đã xóa bảng MODEL_REGISTRY';
    END
    
    IF OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_TYPE', 'U') IS NOT NULL
    BEGIN
        DROP TABLE MODEL_REGISTRY.dbo.MODEL_TYPE;
        PRINT '- Đã xóa bảng MODEL_TYPE';
    END
    
    PRINT '';
    PRINT 'Tất cả các đối tượng của Hệ Thống Đăng Ký Mô Hình đã được gỡ bỏ thành công.';
    
    COMMIT TRANSACTION;
    
DropDatabase:
    -- Xóa database nếu yêu cầu
    IF @DROP_DATABASE = 'YES'
    BEGIN
        -- Không thể xóa database hiện tại, cần chuyển về master
        PRINT '';
        PRINT 'Chuẩn bị xóa database ' + @DATABASE_NAME + '...';
        
        -- Tạo một câu lệnh động để xóa database
        DECLARE @SQL NVARCHAR(200) = N'USE master; DROP DATABASE [' + @DATABASE_NAME + '];';
        
        -- In thông báo
        PRINT 'Thực thi: ' + @SQL;
        PRINT '';
        PRINT 'LƯU Ý: Database sẽ bị xóa sau khi script kết thúc.';
        PRINT 'Để hoàn tất việc xóa database, vui lòng chạy lệnh sau trong một phiên query mới:';
        PRINT @SQL;
        
        -- Thực hiện xóa database nếu không phải là database hiện tại
        IF DB_NAME() <> @DATABASE_NAME
        BEGIN
            EXEC sp_executesql @SQL;
            PRINT 'Database ' + @DATABASE_NAME + ' đã được xóa thành công.';
        END
    END
    
    PRINT '';
    PRINT '=======================================================================';
    PRINT 'GỠ BỎ HỆ THỐNG ĐĂNG KÝ MÔ HÌNH HOÀN TẤT';
    PRINT '=======================================================================';
    
END TRY
BEGIN CATCH
    -- Xử lý lỗi
    PRINT 'Đã xảy ra lỗi trong quá trình gỡ bỏ:';
    PRINT 'Mã lỗi: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10));
    PRINT 'Thông báo: ' + ERROR_MESSAGE();
    PRINT 'Dòng: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
    
    -- Rollback transaction nếu đang trong transaction
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
END CATCH;
GO