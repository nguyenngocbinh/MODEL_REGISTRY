/*
Tên file: uninstall.sql
Mô tả: Script đầy đủ để gỡ bỏ hệ thống Đăng Ký Mô Hình - Complete version
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-20
Cập nhật: 2025-06-20 - Bổ sung cleanup hoàn chỉnh
*/

SET NOCOUNT ON;
PRINT N'=============================================';
PRINT N'BẮT ĐẦU GỠ BỎ HỆ THỐNG MODEL REGISTRY';
PRINT N'=============================================';

USE MODEL_REGISTRY;
GO

-- Disable all constraints first to avoid dependency issues
PRINT N'Tắt tất cả constraints...';
EXEC sp_msforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all";

BEGIN TRY
    -- Don't use transaction for DROP operations to avoid rollback issues
    
    -- Xóa Triggers (check existence first)
    PRINT N'Đang xóa Triggers...';
    
    IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TRG_UPDATE_MODEL_FEATURE_DEPENDENCIES')
        DROP TRIGGER dbo.TRG_UPDATE_MODEL_FEATURE_DEPENDENCIES;
    
    IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TRG_FEATURE_STAT_UPDATE')
        DROP TRIGGER dbo.TRG_FEATURE_STAT_UPDATE;
    
    IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TRG_AUDIT_FEATURE_REGISTRY')
        DROP TRIGGER dbo.TRG_AUDIT_FEATURE_REGISTRY;
    
    IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TRG_UPDATE_MODEL_STATUS')
        DROP TRIGGER dbo.TRG_UPDATE_MODEL_STATUS;
    
    IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TRG_VALIDATE_MODEL_SOURCES')
        DROP TRIGGER dbo.TRG_VALIDATE_MODEL_SOURCES;
    
    IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TRG_AUDIT_MODEL_PARAMETERS')
        DROP TRIGGER dbo.TRG_AUDIT_MODEL_PARAMETERS;
    
    IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TRG_AUDIT_MODEL_REGISTRY')
        DROP TRIGGER dbo.TRG_AUDIT_MODEL_REGISTRY;

    -- Xóa Stored Procedures
    PRINT N'Đang xóa Stored Procedures...';
    DROP PROCEDURE IF EXISTS dbo.GET_MODEL_PERFORMANCE_HISTORY;
    DROP PROCEDURE IF EXISTS dbo.GET_FEATURE_HISTORY;
    DROP PROCEDURE IF EXISTS dbo.GET_APPROPRIATE_MODEL;
    DROP PROCEDURE IF EXISTS dbo.GET_MODEL_PERFORMANCE;
    DROP PROCEDURE IF EXISTS dbo.GET_FEATURE_DRIFT;
    DROP PROCEDURE IF EXISTS dbo.GET_MODEL_SCORE;
    DROP PROCEDURE IF EXISTS dbo.GET_MODEL_METADATA;
    DROP PROCEDURE IF EXISTS dbo.GET_MODEL_FEATURES;
    DROP PROCEDURE IF EXISTS dbo.REGISTER_NEW_MODEL;
    DROP PROCEDURE IF EXISTS dbo.CHECK_MODEL_DEPENDENCIES;
    DROP PROCEDURE IF EXISTS dbo.VALIDATE_MODEL_SOURCES;
    DROP PROCEDURE IF EXISTS dbo.LOG_SOURCE_TABLE_REFRESH;
    DROP PROCEDURE IF EXISTS dbo.GET_TABLE_MODELS;
    DROP PROCEDURE IF EXISTS dbo.GET_MODEL_TABLES;
    DROP PROCEDURE IF EXISTS dbo.SP_CHECK_MODEL_PERFORMANCE;
    
    -- Xóa các procedures còn thiếu
    DROP PROCEDURE IF EXISTS dbo.SP_CALCULATE_KS_TABLE;
    DROP PROCEDURE IF EXISTS dbo.SP_CALCULATE_PSI_TABLES;
    DROP PROCEDURE IF EXISTS dbo.SP_UPDATE_FEATURE_STABILITY;
    DROP PROCEDURE IF EXISTS dbo.SP_VALIDATE_FEATURES;

    -- Xóa Views
    PRINT N'Đang xóa Views...';
    DROP VIEW IF EXISTS dbo.VW_FEATURE_LINEAGE;
    DROP VIEW IF EXISTS dbo.VW_FEATURE_DEPENDENCIES;
    DROP VIEW IF EXISTS dbo.VW_FEATURE_MODEL_USAGE;
    DROP VIEW IF EXISTS dbo.VW_FEATURE_CATALOG;
    DROP VIEW IF EXISTS dbo.VW_MODEL_LINEAGE;
    DROP VIEW IF EXISTS dbo.VW_DATA_QUALITY_SUMMARY;
    DROP VIEW IF EXISTS dbo.VW_MODEL_PERFORMANCE;
    DROP VIEW IF EXISTS dbo.VW_MODEL_TYPE_INFO;
    DROP VIEW IF EXISTS dbo.VW_MODEL_TABLE_RELATIONSHIPS;

    -- Xóa Functions
    PRINT N'Đang xóa Functions...';
    DROP FUNCTION IF EXISTS dbo.FN_VALIDATE_FEATURE;
    DROP FUNCTION IF EXISTS dbo.FN_GET_FEATURE_HISTORY;
    DROP FUNCTION IF EXISTS dbo.FN_CALCULATE_FEATURE_DRIFT;
    DROP FUNCTION IF EXISTS dbo.FN_GET_MODEL_VERSION_INFO;
    DROP FUNCTION IF EXISTS dbo.FN_CALCULATE_KS;
    DROP FUNCTION IF EXISTS dbo.FN_CALCULATE_PSI;
    DROP FUNCTION IF EXISTS dbo.FN_GET_MODEL_SCORE;

    -- Xóa Tables (theo thứ tự dependency - ngược lại với install)
    PRINT N'Đang xóa Tables...';
    
    -- Feature-related tables (dependent tables first)
    DROP TABLE IF EXISTS dbo.FEATURE_REFRESH_LOG;
    DROP TABLE IF EXISTS dbo.FEATURE_MODEL_MAPPING;
    DROP TABLE IF EXISTS dbo.FEATURE_DEPENDENCIES;
    DROP TABLE IF EXISTS dbo.FEATURE_STATS;
    DROP TABLE IF EXISTS dbo.FEATURE_VALUES;
    DROP TABLE IF EXISTS dbo.FEATURE_SOURCE_TABLES;
    DROP TABLE IF EXISTS dbo.FEATURE_TRANSFORMATIONS;
    DROP TABLE IF EXISTS dbo.FEATURE_REGISTRY;
    
    -- Model-related tables (dependent tables first)
    DROP TABLE IF EXISTS dbo.MODEL_DATA_QUALITY_LOG;
    DROP TABLE IF EXISTS dbo.MODEL_SOURCE_REFRESH_LOG;
    DROP TABLE IF EXISTS dbo.MODEL_VALIDATION_RESULTS;
    DROP TABLE IF EXISTS dbo.MODEL_SEGMENT_MAPPING;
    DROP TABLE IF EXISTS dbo.MODEL_TABLE_MAPPING;
    DROP TABLE IF EXISTS dbo.MODEL_TABLE_USAGE;
    DROP TABLE IF EXISTS dbo.MODEL_COLUMN_DETAILS;
    DROP TABLE IF EXISTS dbo.MODEL_SOURCE_TABLES;
    DROP TABLE IF EXISTS dbo.MODEL_PARAMETERS;
    DROP TABLE IF EXISTS dbo.MODEL_REGISTRY;
    DROP TABLE IF EXISTS dbo.MODEL_TYPE;

    -- Xóa monitoring tables nếu có
    DROP TABLE IF EXISTS dbo.MODEL_MONITORING_ALERTS;
    DROP TABLE IF EXISTS dbo.MODEL_MONITORING_CONFIG;
    DROP TABLE IF EXISTS dbo.DEPLOYMENT_LOG;

    PRINT N'Hoàn thành xóa các components chính.';

END TRY
BEGIN CATCH
    PRINT N'';
    PRINT N'LỖI TRONG QUÁ TRÌNH GỠ BỎ:';
    PRINT N'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
    PRINT N'Error Message: ' + ERROR_MESSAGE();
    PRINT N'Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR);
    PRINT N'';
    PRINT N'Tiếp tục với cleanup bổ sung...';
END CATCH;

-- CLEANUP BỔ SUNG - Xóa tất cả components còn sót lại
PRINT N'';
PRINT N'=============================================';
PRINT N'CLEANUP BỔ SUNG - XÓA CÁC COMPONENTS CÒN LẠI';
PRINT N'=============================================';

-- Xóa tất cả stored procedures không thuộc hệ thống
PRINT N'Xóa các stored procedures còn lại...';

DECLARE @procName NVARCHAR(128);
DECLARE @sql NVARCHAR(MAX);

DECLARE proc_cursor CURSOR FOR
SELECT ROUTINE_NAME 
FROM INFORMATION_SCHEMA.ROUTINES 
WHERE ROUTINE_TYPE = 'PROCEDURE' 
AND ROUTINE_SCHEMA = 'dbo'
AND ROUTINE_NAME NOT LIKE 'sp_%'  -- Exclude system procedures
AND ROUTINE_NAME NOT LIKE 'dt_%'  -- Exclude system procedures
AND ROUTINE_NAME NOT LIKE 'fn_%'; -- Exclude system functions

OPEN proc_cursor;
FETCH NEXT FROM proc_cursor INTO @procName;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        SET @sql = 'DROP PROCEDURE [dbo].[' + @procName + ']';
        EXEC sp_executesql @sql;
        PRINT N'Đã xóa procedure: ' + @procName;
    END TRY
    BEGIN CATCH
        PRINT N'Không thể xóa procedure: ' + @procName + ' - ' + ERROR_MESSAGE();
    END CATCH
    
    FETCH NEXT FROM proc_cursor INTO @procName;
END

CLOSE proc_cursor;
DEALLOCATE proc_cursor;

-- Xóa tất cả functions không thuộc hệ thống
PRINT N'Xóa các functions còn lại...';

DECLARE @funcName NVARCHAR(128);

DECLARE func_cursor CURSOR FOR
SELECT ROUTINE_NAME 
FROM INFORMATION_SCHEMA.ROUTINES 
WHERE ROUTINE_TYPE = 'FUNCTION' 
AND ROUTINE_SCHEMA = 'dbo'
AND ROUTINE_NAME NOT LIKE 'fn_diagramobjects'  -- Exclude system functions
AND ROUTINE_NAME NOT LIKE 'fn_helpdiagram%';   -- Exclude system functions

OPEN func_cursor;
FETCH NEXT FROM func_cursor INTO @funcName;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        SET @sql = 'DROP FUNCTION [dbo].[' + @funcName + ']';
        EXEC sp_executesql @sql;
        PRINT N'Đã xóa function: ' + @funcName;
    END TRY
    BEGIN CATCH
        PRINT N'Không thể xóa function: ' + @funcName + ' - ' + ERROR_MESSAGE();
    END CATCH
    
    FETCH NEXT FROM func_cursor INTO @funcName;
END

CLOSE func_cursor;
DEALLOCATE func_cursor;

-- Force cleanup any remaining tables that match our patterns
PRINT N'Cleanup tables bổ sung...';
DECLARE @tableName NVARCHAR(128);

-- Get all tables that might be from our system
DECLARE cleanup_cursor CURSOR FOR
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE' 
AND (TABLE_NAME LIKE '%MODEL%' OR TABLE_NAME LIKE '%FEATURE%')
AND TABLE_NAME NOT IN ('sysdatabase_files', 'sysfiles')
AND TABLE_NAME NOT LIKE 'sys%';

OPEN cleanup_cursor;
FETCH NEXT FROM cleanup_cursor INTO @tableName;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        SET @sql = 'DROP TABLE [dbo].[' + @tableName + ']';
        EXEC sp_executesql @sql;
        PRINT N'Đã xóa table: ' + @tableName;
    END TRY
    BEGIN CATCH
        PRINT N'Không thể xóa table: ' + @tableName + ' - ' + ERROR_MESSAGE();
    END CATCH
    
    FETCH NEXT FROM cleanup_cursor INTO @tableName;
END

CLOSE cleanup_cursor;
DEALLOCATE cleanup_cursor;

-- Kiểm tra kết quả cuối cùng
PRINT N'';
PRINT N'KIỂM TRA KẾT QUẢ CUỐI CÙNG:';
PRINT N'---------------------------------------------';

DECLARE @FinalTables INT, @FinalProcs INT, @FinalFuncs INT, @FinalViews INT, @FinalTriggers INT;

SELECT @FinalTables = COUNT(*) 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE' 
AND TABLE_SCHEMA = 'dbo'
AND (TABLE_NAME LIKE '%MODEL%' OR TABLE_NAME LIKE '%FEATURE%')
AND TABLE_NAME NOT LIKE 'sys%';

SELECT @FinalProcs = COUNT(*) 
FROM INFORMATION_SCHEMA.ROUTINES 
WHERE ROUTINE_TYPE = 'PROCEDURE' 
AND ROUTINE_SCHEMA = 'dbo'
AND ROUTINE_NAME NOT LIKE 'sp_%'
AND ROUTINE_NAME NOT LIKE 'dt_%';

SELECT @FinalFuncs = COUNT(*) 
FROM INFORMATION_SCHEMA.ROUTINES 
WHERE ROUTINE_TYPE = 'FUNCTION' 
AND ROUTINE_SCHEMA = 'dbo'
AND ROUTINE_NAME NOT LIKE 'fn_diagram%'
AND ROUTINE_NAME NOT LIKE 'fn_helpdiagram%';

SELECT @FinalViews = COUNT(*) 
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_SCHEMA = 'dbo';

SELECT @FinalTriggers = COUNT(*)
FROM sys.triggers t
INNER JOIN sys.tables tb ON t.parent_id = tb.object_id
WHERE t.name LIKE 'TRG_%';

PRINT N'Tables Model Registry: ' + CAST(@FinalTables AS NVARCHAR);
PRINT N'Procedures còn lại: ' + CAST(@FinalProcs AS NVARCHAR);
PRINT N'Functions còn lại: ' + CAST(@FinalFuncs AS NVARCHAR);
PRINT N'Views còn lại: ' + CAST(@FinalViews AS NVARCHAR);
PRINT N'Triggers còn lại: ' + CAST(@FinalTriggers AS NVARCHAR);

IF @FinalTables = 0 AND @FinalProcs = 0 AND @FinalFuncs = 0 AND @FinalViews = 0 AND @FinalTriggers = 0
BEGIN
    PRINT N'';
    PRINT N'🎉 GỠ BỎ HOÀN TOÀN THÀNH CÔNG!';
    PRINT N'Database MODEL_REGISTRY đã được dọn dẹp hoàn toàn.';
END
ELSE
BEGIN
    PRINT N'';
    PRINT N'⚠ Còn một số objects không thuộc Model Registry:';
    
    IF @FinalTables > 0
    BEGIN
        PRINT N'Tables còn lại:';
        SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_TYPE = 'BASE TABLE' 
        AND (TABLE_NAME LIKE '%MODEL%' OR TABLE_NAME LIKE '%FEATURE%')
        AND TABLE_NAME NOT LIKE 'sys%';
    END
    
    IF @FinalProcs > 0
    BEGIN
        PRINT N'Procedures còn lại:';
        SELECT ROUTINE_NAME FROM INFORMATION_SCHEMA.ROUTINES 
        WHERE ROUTINE_TYPE = 'PROCEDURE' 
        AND ROUTINE_SCHEMA = 'dbo'
        AND ROUTINE_NAME NOT LIKE 'sp_%'
        AND ROUTINE_NAME NOT LIKE 'dt_%';
    END
    
    IF @FinalFuncs > 0
    BEGIN
        PRINT N'Functions còn lại:';
        SELECT ROUTINE_NAME FROM INFORMATION_SCHEMA.ROUTINES 
        WHERE ROUTINE_TYPE = 'FUNCTION' 
        AND ROUTINE_SCHEMA = 'dbo'
        AND ROUTINE_NAME NOT LIKE 'fn_diagram%'
        AND ROUTINE_NAME NOT LIKE 'fn_helpdiagram%';
    END
END

PRINT N'';
PRINT N'=============================================';
PRINT N'GỠ BỎ HOÀN TẤT!';
PRINT N'=============================================';
PRINT N'Tất cả thành phần Model Registry đã được xóa.';

GO