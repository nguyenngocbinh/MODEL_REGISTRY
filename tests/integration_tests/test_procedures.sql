/*
Tên file: test_procedures.sql
Mô tả: Kiểm thử tích hợp cho các stored procedures trong hệ thống
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-12
Phiên bản: 1.0
*/

SET NOCOUNT ON;
GO

PRINT '=========================================================';
PRINT 'BẮT ĐẦU KIỂM THỬ TÍCH HỢP CHO CÁC STORED PROCEDURES';
PRINT '=========================================================';
PRINT '';

-- Biến lưu số lượng lỗi
DECLARE @ERROR_COUNT INT = 0;

-- Biến lưu ID mô hình để kiểm thử
DECLARE @TEST_MODEL_ID INT;
DECLARE @TEST_MODEL_NAME NVARCHAR(100) = 'PD_RETAIL'; -- Giả định mô hình này tồn tại trong dữ liệu mẫu

-- Biến lưu ID bảng dữ liệu để kiểm thử
DECLARE @TEST_TABLE_ID INT;
DECLARE @TEST_DATABASE NVARCHAR(128) = 'DATA_WAREHOUSE';
DECLARE @TEST_SCHEMA NVARCHAR(128) = 'dbo';
DECLARE @TEST_TABLE_NAME NVARCHAR(128) = 'DIM_CUSTOMER'; -- Giả định bảng này tồn tại trong dữ liệu mẫu

-- Lấy MODEL_ID từ dữ liệu mẫu
SELECT @TEST_MODEL_ID = MODEL_ID 
FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY 
WHERE MODEL_NAME = @TEST_MODEL_NAME;

-- Lấy SOURCE_TABLE_ID từ dữ liệu mẫu
SELECT @TEST_TABLE_ID = SOURCE_TABLE_ID 
FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES 
WHERE SOURCE_DATABASE = @TEST_DATABASE 
  AND SOURCE_SCHEMA = @TEST_SCHEMA 
  AND SOURCE_TABLE_NAME = @TEST_TABLE_NAME;

-- Kiểm tra xem có tìm thấy dữ liệu mẫu không
IF @TEST_MODEL_ID IS NULL
BEGIN
    PRINT 'CẢNH BÁO: Không tìm thấy mô hình mẫu "' + @TEST_MODEL_NAME + '" để kiểm thử.';
    PRINT 'Sẽ tiếp tục kiểm thử với mô hình bất kỳ...';
    
    -- Lấy một MODEL_ID bất kỳ
    SELECT TOP 1 @TEST_MODEL_ID = MODEL_ID, @TEST_MODEL_NAME = MODEL_NAME 
    FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY;
    
    IF @TEST_MODEL_ID IS NULL
    BEGIN
        PRINT 'LỖI: Không tìm thấy mô hình nào để kiểm thử.';
        SET @ERROR_COUNT = @ERROR_COUNT + 1;
    END
    ELSE
    BEGIN
        PRINT 'Đã chọn mô hình "' + @TEST_MODEL_NAME + '" với MODEL_ID = ' + CAST(@TEST_MODEL_ID AS VARCHAR) + ' để kiểm thử.';
    END
END
ELSE
BEGIN
    PRINT 'Đã tìm thấy mô hình mẫu "' + @TEST_MODEL_NAME + '" với MODEL_ID = ' + CAST(@TEST_MODEL_ID AS VARCHAR) + '.';
END

IF @TEST_TABLE_ID IS NULL
BEGIN
    PRINT 'CẢNH BÁO: Không tìm thấy bảng mẫu "' + @TEST_DATABASE + '.' + @TEST_SCHEMA + '.' + @TEST_TABLE_NAME + '" để kiểm thử.';
    PRINT 'Sẽ tiếp tục kiểm thử với bảng bất kỳ...';
    
    -- Lấy một SOURCE_TABLE_ID bất kỳ
    SELECT TOP 1 
        @TEST_TABLE_ID = SOURCE_TABLE_ID,
        @TEST_DATABASE = SOURCE_DATABASE,
        @TEST_SCHEMA = SOURCE_SCHEMA,
        @TEST_TABLE_NAME = SOURCE_TABLE_NAME
    FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES;
    
    IF @TEST_TABLE_ID IS NULL
    BEGIN
        PRINT 'LỖI: Không tìm thấy bảng nào để kiểm thử.';
        SET @ERROR_COUNT = @ERROR_COUNT + 1;
    END
    ELSE
    BEGIN
        PRINT 'Đã chọn bảng "' + @TEST_DATABASE + '.' + @TEST_SCHEMA + '.' + @TEST_TABLE_NAME + '" với SOURCE_TABLE_ID = ' + CAST(@TEST_TABLE_ID AS VARCHAR) + ' để kiểm thử.';
    END
END
ELSE
BEGIN
    PRINT 'Đã tìm thấy bảng mẫu "' + @TEST_DATABASE + '.' + @TEST_SCHEMA + '.' + @TEST_TABLE_NAME + '" với SOURCE_TABLE_ID = ' + CAST(@TEST_TABLE_ID AS VARCHAR) + '.';
END

PRINT '';
PRINT '--------------------------------------------------';
PRINT '1. Kiểm thử thủ tục GET_MODEL_TABLES';
PRINT '--------------------------------------------------';

IF OBJECT_ID('MODEL_REGISTRY.dbo.GET_MODEL_TABLES', 'P') IS NOT NULL
BEGIN
    BEGIN TRY
        PRINT 'Thực thi GET_MODEL_TABLES với MODEL_ID = ' + CAST(@TEST_MODEL_ID AS VARCHAR) + '...';
        
        -- Thực thi thủ tục
        EXEC MODEL_REGISTRY.dbo.GET_MODEL_TABLES @MODEL_ID = @TEST_MODEL_ID;
        
        PRINT 'Đã thực thi thủ tục GET_MODEL_TABLES thành công.';
    END TRY
    BEGIN CATCH
        PRINT 'LỖI: Không thể thực thi thủ tục GET_MODEL_TABLES. Lỗi: ' + ERROR_MESSAGE();
        SET @ERROR_COUNT = @ERROR_COUNT + 1;
    END CATCH
    
    BEGIN TRY
        PRINT 'Thực thi GET_MODEL_TABLES với MODEL_NAME = ''' + @TEST_MODEL_NAME + '''...';
        
        -- Thực thi thủ tục với tên mô hình
        EXEC MODEL_REGISTRY.dbo.GET_MODEL_TABLES @MODEL_NAME = @TEST_MODEL_NAME;
        
        PRINT 'Đã thực thi thủ tục GET_MODEL_TABLES với tên mô hình thành công.';
    END TRY
    BEGIN CATCH
        PRINT 'LỖI: Không thể thực thi thủ tục GET_MODEL_TABLES với tên mô hình. Lỗi: ' + ERROR_MESSAGE();
        SET @ERROR_COUNT = @ERROR_COUNT + 1;
    END CATCH
END
ELSE
BEGIN
    PRINT 'LỖI: Thủ tục GET_MODEL_TABLES không tồn tại.';
    SET @ERROR_COUNT = @ERROR_COUNT + 1;
END

PRINT '';
PRINT '--------------------------------------------------';
PRINT '2. Kiểm thử thủ tục GET_TABLE_MODELS';
PRINT '--------------------------------------------------';

IF OBJECT_ID('MODEL_REGISTRY.dbo.GET_TABLE_MODELS', 'P') IS NOT NULL
BEGIN
    BEGIN TRY
        PRINT 'Thực thi GET_TABLE_MODELS với bảng = ''' + @TEST_DATABASE + '.' + @TEST_SCHEMA + '.' + @TEST_TABLE_NAME + '''...';
        
        -- Thực thi thủ tục
        EXEC MODEL_REGISTRY.dbo.GET_TABLE_MODELS 
            @DATABASE_NAME = @TEST_DATABASE, 
            @SCHEMA_NAME = @TEST_SCHEMA, 
            @TABLE_NAME = @TEST_TABLE_NAME;
        
        PRINT 'Đã thực thi thủ tục GET_TABLE_MODELS thành công.';
    END TRY
    BEGIN CATCH
        PRINT 'LỖI: Không thể thực thi thủ tục GET_TABLE_MODELS. Lỗi: ' + ERROR_MESSAGE();
        SET @ERROR_COUNT = @ERROR_COUNT + 1;
    END CATCH
END
ELSE
BEGIN
    PRINT 'LỖI: Thủ tục GET_TABLE_MODELS không tồn tại.';
    SET @ERROR_COUNT = @ERROR_COUNT + 1;
END

PRINT '';
PRINT '--------------------------------------------------';
PRINT '3. Kiểm thử thủ tục VALIDATE_MODEL_SOURCES';
PRINT '--------------------------------------------------';

IF OBJECT_ID('MODEL_REGISTRY.dbo.VALIDATE_MODEL_SOURCES', 'P') IS NOT NULL
BEGIN
    BEGIN TRY
        PRINT 'Thực thi VALIDATE_MODEL_SOURCES với MODEL_ID = ' + CAST(@TEST_MODEL_ID AS VARCHAR) + '...';
        
        -- Thực thi thủ tục
        EXEC MODEL_REGISTRY.dbo.VALIDATE_MODEL_SOURCES 
            @MODEL_ID = @TEST_MODEL_ID, 
            @PROCESS_DATE = GETDATE(),
            @DETAILED_RESULTS = 1,
            @CHECK_DATA_QUALITY = 1;
        
        PRINT 'Đã thực thi thủ tục VALIDATE_MODEL_SOURCES thành công.';
    END TRY
    BEGIN CATCH
        PRINT 'LỖI: Không thể thực thi thủ tục VALIDATE_MODEL_SOURCES. Lỗi: ' + ERROR_MESSAGE();
        SET @ERROR_COUNT = @ERROR_COUNT + 1;
    END CATCH
END
ELSE
BEGIN
    PRINT 'LỖI: Thủ tục VALIDATE_MODEL_SOURCES không tồn tại.';
    SET @ERROR_COUNT = @ERROR_COUNT + 1;
END

PRINT '';
PRINT '--------------------------------------------------';
PRINT '4. Kiểm thử thủ tục LOG_SOURCE_TABLE_REFRESH';
PRINT '--------------------------------------------------';

IF OBJECT_ID('MODEL_REGISTRY.dbo.LOG_SOURCE_TABLE_REFRESH', 'P') IS NOT NULL
BEGIN
    BEGIN TRY
        PRINT 'Thực thi LOG_SOURCE_TABLE_REFRESH để ghi nhật ký cập nhật...';
        
        -- Thực thi thủ tục
        DECLARE @TEST_REFRESH_STATUS NVARCHAR(20) = 'STARTED';
        
        EXEC MODEL_REGISTRY.dbo.LOG_SOURCE_TABLE_REFRESH 
            @SOURCE_DATABASE = @TEST_DATABASE, 
            @SOURCE_SCHEMA = @TEST_SCHEMA, 
            @SOURCE_TABLE_NAME = @TEST_TABLE_NAME,
            @PROCESS_DATE = GETDATE(),
            @REFRESH_STATUS = @TEST_REFRESH_STATUS,
            @REFRESH_TYPE = 'FULL',
            @REFRESH_METHOD = 'MANUAL',
            @RECORDS_PROCESSED = 1000,
            @ERROR_MESSAGE = 'Test refresh for integration testing';
        
        PRINT 'Đã thực thi thủ tục LOG_SOURCE_TABLE_REFRESH thành công với trạng thái ' + @TEST_REFRESH_STATUS + '.';
        
        -- Hoàn thành cập nhật (đánh dấu COMPLETED)
        EXEC MODEL_REGISTRY.dbo.LOG_SOURCE_TABLE_REFRESH 
            @SOURCE_DATABASE = @TEST_DATABASE, 
            @SOURCE_SCHEMA = @TEST_SCHEMA, 
            @SOURCE_TABLE_NAME = @TEST_TABLE_NAME,
            @PROCESS_DATE = GETDATE(),
            @REFRESH_STATUS = 'COMPLETED',
            @REFRESH_TYPE = 'FULL',
            @REFRESH_METHOD = 'MANUAL',
            @RECORDS_PROCESSED = 1000;
        
        PRINT 'Đã thực thi thủ tục LOG_SOURCE_TABLE_REFRESH thành công với trạng thái COMPLETED.';
    END TRY
    BEGIN CATCH
        PRINT 'LỖI: Không thể thực thi thủ tục LOG_SOURCE_TABLE_REFRESH. Lỗi: ' + ERROR_MESSAGE();
        SET @ERROR_COUNT = @ERROR_COUNT + 1;
    END CATCH
END
ELSE
BEGIN
    PRINT 'LỖI: Thủ tục LOG_SOURCE_TABLE_REFRESH không tồn tại.';
    SET @ERROR_COUNT = @ERROR_COUNT + 1;
END

PRINT '';
PRINT '--------------------------------------------------';
PRINT '5. Kiểm thử thủ tục GET_APPROPRIATE_MODEL';
PRINT '--------------------------------------------------';

IF OBJECT_ID('MODEL_REGISTRY.dbo.GET_APPROPRIATE_MODEL', 'P') IS NOT NULL
BEGIN
    BEGIN TRY
        PRINT 'Thực thi GET_APPROPRIATE_MODEL để xác định mô hình phù hợp...';
        
        -- Thực thi thủ tục
        DECLARE @TEST_CUSTOMER_ID NVARCHAR(50) = 'TEST_CUSTOMER_001';
        DECLARE @TEST_ATTRIBUTES NVARCHAR(MAX) = '{"customer_segment": "RETAIL", "product_type": "MORTGAGE", "vintage": "NEW"}';
        
        EXEC MODEL_REGISTRY.dbo.GET_APPROPRIATE_MODEL 
            @CUSTOMER_ID = @TEST_CUSTOMER_ID,
            @PROCESS_DATE = GETDATE(),
            @MODEL_TYPE_CODE = NULL,
            @MODEL_CATEGORY = 'Retail',
            @CUSTOMER_ATTRIBUTES = @TEST_ATTRIBUTES,
            @DEBUG = 1;
        
        PRINT 'Đã thực thi thủ tục GET_APPROPRIATE_MODEL thành công.';
    END TRY
    BEGIN CATCH
        PRINT 'LỖI: Không thể thực thi thủ tục GET_APPROPRIATE_MODEL. Lỗi: ' + ERROR_MESSAGE();
        SET @ERROR_COUNT = @ERROR_COUNT + 1;
    END CATCH
END
ELSE
BEGIN
    PRINT 'LỖI: Thủ tục GET_APPROPRIATE_MODEL không tồn tại.';
    SET @ERROR_COUNT = @ERROR_COUNT + 1;
END

PRINT '';
PRINT '--------------------------------------------------';
PRINT '6. Kiểm thử thủ tục GET_MODEL_PERFORMANCE_HISTORY';
PRINT '--------------------------------------------------';

IF OBJECT_ID('MODEL_REGISTRY.dbo.GET_MODEL_PERFORMANCE_HISTORY', 'P') IS NOT NULL
BEGIN
    BEGIN TRY
        PRINT 'Thực thi GET_MODEL_PERFORMANCE_HISTORY để lấy lịch sử hiệu suất...';
        
        -- Thực thi thủ tục
        EXEC MODEL_REGISTRY.dbo.GET_MODEL_PERFORMANCE_HISTORY 
            @MODEL_ID = @TEST_MODEL_ID,
            @START_DATE = DATEADD(YEAR, -1, GETDATE()),
            @END_DATE = GETDATE(),
            @INCLUDE_DETAILS = 1;
        
        PRINT 'Đã thực thi thủ tục GET_MODEL_PERFORMANCE_HISTORY thành công.';
        
        -- Thực thi với tên mô hình
        PRINT 'Thực thi GET_MODEL_PERFORMANCE_HISTORY với tên mô hình...';
        
        EXEC MODEL_REGISTRY.dbo.GET_MODEL_PERFORMANCE_HISTORY 
            @MODEL_NAME = @TEST_MODEL_NAME,
            @START_DATE = DATEADD(YEAR, -1, GETDATE()),
            @END_DATE = GETDATE();
        
        PRINT 'Đã thực thi thủ tục GET_MODEL_PERFORMANCE_HISTORY với tên mô hình thành công.';
    END TRY
    BEGIN CATCH
        PRINT 'LỖI: Không thể thực thi thủ tục GET_MODEL_PERFORMANCE_HISTORY. Lỗi: ' + ERROR_MESSAGE();
        SET @ERROR_COUNT = @ERROR_COUNT + 1;
    END CATCH
END
ELSE
BEGIN
    PRINT 'LỖI: Thủ tục GET_MODEL_PERFORMANCE_HISTORY không tồn tại.';
    SET @ERROR_COUNT = @ERROR_COUNT + 1;
END

PRINT '';
PRINT '--------------------------------------------------';
PRINT '7. Kiểm thử thủ tục tùy chỉnh tham số PARAMETER_CHANGE_REASON';
PRINT '--------------------------------------------------';

IF OBJECT_ID('MODEL_REGISTRY.dbo.SET_PARAMETER_CHANGE_REASON', 'P') IS NOT NULL
BEGIN
    BEGIN TRY
        PRINT 'Thực thi SET_PARAMETER_CHANGE_REASON...';
        
        -- Thực thi thủ tục
        EXEC MODEL_REGISTRY.dbo.SET_PARAMETER_CHANGE_REASON 
            @REASON = 'Test reason for integration testing';
        
        PRINT 'Đã thực thi thủ tục SET_PARAMETER_CHANGE_REASON thành công.';
        
        -- Đặt lại CONTEXT_INFO
        SET CONTEXT_INFO 0x;
    END TRY
    BEGIN CATCH
        PRINT 'LỖI: Không thể thực thi thủ tục SET_PARAMETER_CHANGE_REASON. Lỗi: ' + ERROR_MESSAGE();
        SET @ERROR_COUNT = @ERROR_COUNT + 1;
    END CATCH
END
ELSE
BEGIN
    PRINT 'Thủ tục SET_PARAMETER_CHANGE_REASON không tồn tại. Đây là thủ tục tùy chọn.';
END

PRINT '';
PRINT '=========================================================';
PRINT 'KẾT QUẢ KIỂM THỬ TÍCH HỢP CHO CÁC STORED PROCEDURES';
PRINT '=========================================================';
PRINT '';
IF @ERROR_COUNT = 0
    PRINT 'TẤT CẢ CÁC KIỂM THỬ ĐỀU THÀNH CÔNG!';
ELSE
    PRINT 'CÓ ' + CAST(@ERROR_COUNT AS VARCHAR) + ' LỖI TRONG QUÁ TRÌNH KIỂM THỬ.';
PRINT '';
PRINT 'Hoàn thành kiểm thử tích hợp cho các stored procedures.';
GO