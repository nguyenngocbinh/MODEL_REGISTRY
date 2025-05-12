/*
Tên file: test_model_registry.sql
Mô tả: Kiểm thử đơn vị cho bảng MODEL_REGISTRY và các chức năng liên quan
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-12
Phiên bản: 1.0
*/

SET NOCOUNT ON;
GO

PRINT '=========================================================';
PRINT 'BẮT ĐẦU KIỂM THỬ ĐƠN VỊ CHO MODEL_REGISTRY';
PRINT '=========================================================';
PRINT '';

-- Biến lưu số lượng lỗi
DECLARE @ERROR_COUNT INT = 0;

-- Biến lưu ID được tạo mới
DECLARE @NEW_MODEL_ID INT;
DECLARE @NEW_TYPE_ID INT;

-- Tạo đối tượng tạm để kiểm thử
PRINT 'Thiết lập đối tượng kiểm thử...';

-- 1. Kiểm tra sự tồn tại của bảng MODEL_TYPE
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'MODEL_TYPE' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    PRINT 'LỖI: Bảng MODEL_TYPE không tồn tại.';
    SET @ERROR_COUNT = @ERROR_COUNT + 1;
END
ELSE
BEGIN
    PRINT 'Đã xác nhận bảng MODEL_TYPE tồn tại.';
    
    -- Tạo một bản ghi kiểm thử trong MODEL_TYPE
    BEGIN TRY
        INSERT INTO MODEL_REGISTRY.dbo.MODEL_TYPE (
            TYPE_CODE, 
            TYPE_NAME, 
            TYPE_DESCRIPTION
        )
        VALUES ('TEST', 'Test Model Type', 'Type created for unit testing');
        
        SET @NEW_TYPE_ID = SCOPE_IDENTITY();
        PRINT 'Đã tạo bản ghi kiểm thử trong MODEL_TYPE với TYPE_ID = ' + CAST(@NEW_TYPE_ID AS VARCHAR);
    END TRY
    BEGIN CATCH
        PRINT 'LỖI: Không thể tạo bản ghi kiểm thử trong MODEL_TYPE. Lỗi: ' + ERROR_MESSAGE();
        SET @ERROR_COUNT = @ERROR_COUNT + 1;
    END CATCH
END

-- 2. Kiểm tra sự tồn tại của bảng MODEL_REGISTRY
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'MODEL_REGISTRY' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    PRINT 'LỖI: Bảng MODEL_REGISTRY không tồn tại.';
    SET @ERROR_COUNT = @ERROR_COUNT + 1;
END
ELSE
BEGIN
    PRINT 'Đã xác nhận bảng MODEL_REGISTRY tồn tại.';
    
    -- Tạo một bản ghi kiểm thử trong MODEL_REGISTRY
    BEGIN TRY
        INSERT INTO MODEL_REGISTRY.dbo.MODEL_REGISTRY (
            TYPE_ID,
            MODEL_NAME,
            MODEL_DESCRIPTION,
            MODEL_VERSION,
            SOURCE_DATABASE,
            SOURCE_SCHEMA,
            SOURCE_TABLE_NAME,
            REF_SOURCE,
            EFF_DATE,
            EXP_DATE,
            IS_ACTIVE,
            PRIORITY,
            MODEL_CATEGORY,
            SEGMENT_CRITERIA
        )
        VALUES (
            @NEW_TYPE_ID,
            'TEST_MODEL',
            'Test Model for Unit Testing',
            '1.0',
            'TEST_DB',
            'dbo',
            'TEST_RESULTS',
            'Unit Test Reference',
            GETDATE(),
            DATEADD(YEAR, 1, GETDATE()),
            1,
            1,
            'Test',
            '{"test_segment": "TEST", "product_type": "UNIT_TEST"}'
        );
        
        SET @NEW_MODEL_ID = SCOPE_IDENTITY();
        PRINT 'Đã tạo bản ghi kiểm thử trong MODEL_REGISTRY với MODEL_ID = ' + CAST(@NEW_MODEL_ID AS VARCHAR);
    END TRY
    BEGIN CATCH
        PRINT 'LỖI: Không thể tạo bản ghi kiểm thử trong MODEL_REGISTRY. Lỗi: ' + ERROR_MESSAGE();
        SET @ERROR_COUNT = @ERROR_COUNT + 1;
    END CATCH
END

-- Kiểm thử kiểm tra các ràng buộc khóa ngoại
PRINT '';
PRINT 'Kiểm thử ràng buộc khóa ngoại...';

-- Thử chèn bản ghi với TYPE_ID không tồn tại
BEGIN TRY
    DECLARE @INVALID_TYPE_ID INT = (SELECT MAX(TYPE_ID) + 1 FROM MODEL_REGISTRY.dbo.MODEL_TYPE);
    
    INSERT INTO MODEL_REGISTRY.dbo.MODEL_REGISTRY (
        TYPE_ID,
        MODEL_NAME,
        MODEL_VERSION,
        SOURCE_DATABASE,
        SOURCE_SCHEMA,
        SOURCE_TABLE_NAME,
        EFF_DATE,
        EXP_DATE
    )
    VALUES (
        @INVALID_TYPE_ID,
        'INVALID_MODEL',
        '1.0',
        'TEST_DB',
        'dbo',
        'TEST_RESULTS',
        GETDATE(),
        DATEADD(YEAR, 1, GETDATE())
    );
    
    PRINT 'LỖI: Đã chèn được bản ghi với TYPE_ID không tồn tại.';
    SET @ERROR_COUNT = @ERROR_COUNT + 1;
END TRY
BEGIN CATCH
    PRINT 'Đã xác nhận không thể chèn bản ghi với TYPE_ID không tồn tại. Lỗi được bắt đúng.';
END CATCH

-- Kiểm thử ràng buộc duy nhất cho (MODEL_NAME, MODEL_VERSION)
PRINT '';
PRINT 'Kiểm thử ràng buộc duy nhất cho (MODEL_NAME, MODEL_VERSION)...';

BEGIN TRY
    INSERT INTO MODEL_REGISTRY.dbo.MODEL_REGISTRY (
        TYPE_ID,
        MODEL_NAME,
        MODEL_VERSION,
        SOURCE_DATABASE,
        SOURCE_SCHEMA,
        SOURCE_TABLE_NAME,
        EFF_DATE,
        EXP_DATE
    )
    VALUES (
        @NEW_TYPE_ID,
        'TEST_MODEL', -- Trùng với bản ghi đã tạo
        '1.0',        -- Trùng với bản ghi đã tạo
        'TEST_DB',
        'dbo',
        'TEST_RESULTS',
        GETDATE(),
        DATEADD(YEAR, 1, GETDATE())
    );
    
    PRINT 'LỖI: Đã chèn được bản ghi trùng (MODEL_NAME, MODEL_VERSION).';
    SET @ERROR_COUNT = @ERROR_COUNT + 1;
END TRY
BEGIN CATCH
    PRINT 'Đã xác nhận không thể chèn bản ghi trùng (MODEL_NAME, MODEL_VERSION). Lỗi được bắt đúng.';
END CATCH

-- Kiểm thử cập nhật MODEL_REGISTRY
PRINT '';
PRINT 'Kiểm thử cập nhật MODEL_REGISTRY...';

BEGIN TRY
    UPDATE MODEL_REGISTRY.dbo.MODEL_REGISTRY
    SET MODEL_DESCRIPTION = 'Updated Test Model Description'
    WHERE MODEL_ID = @NEW_MODEL_ID;
    
    -- Kiểm tra xem cập nhật có thành công không
    DECLARE @UPDATED_DESC NVARCHAR(500);
    SELECT @UPDATED_DESC = MODEL_DESCRIPTION 
    FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY 
    WHERE MODEL_ID = @NEW_MODEL_ID;
    
    IF @UPDATED_DESC = 'Updated Test Model Description'
        PRINT 'Đã cập nhật mô tả mô hình thành công.';
    ELSE
    BEGIN
        PRINT 'LỖI: Cập nhật mô tả mô hình không thành công.';
        SET @ERROR_COUNT = @ERROR_COUNT + 1;
    END
END TRY
BEGIN CATCH
    PRINT 'LỖI: Không thể cập nhật MODEL_REGISTRY. Lỗi: ' + ERROR_MESSAGE();
    SET @ERROR_COUNT = @ERROR_COUNT + 1;
END CATCH

-- Kiểm thử trigger audit
PRINT '';
PRINT 'Kiểm thử trigger audit...';

IF OBJECT_ID('MODEL_REGISTRY.dbo.AUDIT_MODEL_REGISTRY', 'U') IS NOT NULL
BEGIN
    -- Kiểm tra xem bản ghi audit có được tạo ra không
    DECLARE @AUDIT_COUNT INT;
    SELECT @AUDIT_COUNT = COUNT(*) 
    FROM MODEL_REGISTRY.dbo.AUDIT_MODEL_REGISTRY 
    WHERE MODEL_ID = @NEW_MODEL_ID;
    
    IF @AUDIT_COUNT > 0
        PRINT 'Đã xác nhận trigger audit hoạt động đúng. Tìm thấy ' + CAST(@AUDIT_COUNT AS VARCHAR) + ' bản ghi audit.';
    ELSE
    BEGIN
        PRINT 'LỖI: Không tìm thấy bản ghi audit cho MODEL_ID = ' + CAST(@NEW_MODEL_ID AS VARCHAR);
        SET @ERROR_COUNT = @ERROR_COUNT + 1;
    END
END
ELSE
BEGIN
    PRINT 'Bảng AUDIT_MODEL_REGISTRY không tồn tại. Bỏ qua kiểm thử trigger audit.';
END

-- Kiểm thử xóa MODEL_REGISTRY
PRINT '';
PRINT 'Kiểm thử xóa MODEL_REGISTRY...';

BEGIN TRY
    DELETE FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY
    WHERE MODEL_ID = @NEW_MODEL_ID;
    
    -- Kiểm tra xem xóa có thành công không
    IF NOT EXISTS (SELECT 1 FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY WHERE MODEL_ID = @NEW_MODEL_ID)
        PRINT 'Đã xóa bản ghi MODEL_REGISTRY thành công.';
    ELSE
    BEGIN
        PRINT 'LỖI: Xóa bản ghi MODEL_REGISTRY không thành công.';
        SET @ERROR_COUNT = @ERROR_COUNT + 1;
    END
END TRY
BEGIN CATCH
    PRINT 'LỖI: Không thể xóa MODEL_REGISTRY. Lỗi: ' + ERROR_MESSAGE();
    SET @ERROR_COUNT = @ERROR_COUNT + 1;
END CATCH

-- Xóa đối tượng kiểm thử trong MODEL_TYPE
PRINT '';
PRINT 'Dọn dẹp đối tượng kiểm thử...';

BEGIN TRY
    DELETE FROM MODEL_REGISTRY.dbo.MODEL_TYPE
    WHERE TYPE_ID = @NEW_TYPE_ID;
    
    -- Kiểm tra xem xóa có thành công không
    IF NOT EXISTS (SELECT 1 FROM MODEL_REGISTRY.dbo.MODEL_TYPE WHERE TYPE_ID = @NEW_TYPE_ID)
        PRINT 'Đã xóa bản ghi MODEL_TYPE thành công.';
    ELSE
    BEGIN
        PRINT 'LỖI: Xóa bản ghi MODEL_TYPE không thành công.';
        SET @ERROR_COUNT = @ERROR_COUNT + 1;
    END
END TRY
BEGIN CATCH
    PRINT 'LỖI: Không thể xóa MODEL_TYPE. Lỗi: ' + ERROR_MESSAGE();
    SET @ERROR_COUNT = @ERROR_COUNT + 1;
END CATCH

-- Tổng kết kết quả kiểm thử
PRINT '';
PRINT '=========================================================';
PRINT 'KẾT QUẢ KIỂM THỬ MODEL_REGISTRY';
PRINT '=========================================================';
PRINT '';
IF @ERROR_COUNT = 0
    PRINT 'TẤT CẢ CÁC KIỂM THỬ ĐỀU THÀNH CÔNG!';
ELSE
    PRINT 'CÓ ' + CAST(@ERROR_COUNT AS VARCHAR) + ' LỖI TRONG QUÁ TRÌNH KIỂM THỬ.';
PRINT '';
PRINT 'Hoàn thành kiểm thử đơn vị cho MODEL_REGISTRY.';
GO