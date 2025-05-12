/*
Tên file: test_model_validation.sql
Mô tả: Kiểm thử đơn vị cho bảng MODEL_VALIDATION_RESULTS và các hàm đánh giá hiệu suất
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-12
Phiên bản: 1.0
*/

SET NOCOUNT ON;
GO

PRINT '=========================================================';
PRINT 'BẮT ĐẦU KIỂM THỬ ĐƠN VỊ CHO MODEL_VALIDATION_RESULTS';
PRINT '=========================================================';
PRINT '';

-- Biến lưu số lượng lỗi
DECLARE @ERROR_COUNT INT = 0;

-- Biến lưu ID được tạo mới
DECLARE @NEW_TYPE_ID INT;
DECLARE @NEW_MODEL_ID INT;
DECLARE @NEW_VALIDATION_ID INT;

-- 1. Thiết lập đối tượng kiểm thử
PRINT 'Thiết lập đối tượng kiểm thử...';

-- Tạo bản ghi kiểm thử trong MODEL_TYPE
BEGIN TRY
    INSERT INTO MODEL_REGISTRY.dbo.MODEL_TYPE (
        TYPE_CODE, 
        TYPE_NAME, 
        TYPE_DESCRIPTION
    )
    VALUES ('VTEST', 'Validation Test Type', 'Type created for validation unit testing');
    
    SET @NEW_TYPE_ID = SCOPE_IDENTITY();
    PRINT 'Đã tạo bản ghi kiểm thử trong MODEL_TYPE với TYPE_ID = ' + CAST(@NEW_TYPE_ID AS VARCHAR);
END TRY
BEGIN CATCH
    PRINT 'LỖI: Không thể tạo bản ghi kiểm thử trong MODEL_TYPE. Lỗi: ' + ERROR_MESSAGE();
    SET @ERROR_COUNT = @ERROR_COUNT + 1;
END CATCH

-- Tạo bản ghi kiểm thử trong MODEL_REGISTRY
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
        'VALIDATION_TEST_MODEL',
        'Test Model for Validation Unit Testing',
        '1.0',
        'TEST_DB',
        'dbo',
        'TEST_RESULTS',
        'Validation Unit Test Reference',
        GETDATE(),
        DATEADD(YEAR, 1, GETDATE()),
        1,
        1,
        'Test',
        '{"test_segment": "TEST", "product_type": "VALIDATION_TEST"}'
    );
    
    SET @NEW_MODEL_ID = SCOPE_IDENTITY();
    PRINT 'Đã tạo bản ghi kiểm thử trong MODEL_REGISTRY với MODEL_ID = ' + CAST(@NEW_MODEL_ID AS VARCHAR);
END TRY
BEGIN CATCH
    PRINT 'LỖI: Không thể tạo bản ghi kiểm thử trong MODEL_REGISTRY. Lỗi: ' + ERROR_MESSAGE();
    SET @ERROR_COUNT = @ERROR_COUNT + 1;
END CATCH

-- 2. Kiểm tra sự tồn tại của bảng MODEL_VALIDATION_RESULTS
PRINT '';
PRINT 'Kiểm tra cấu trúc bảng MODEL_VALIDATION_RESULTS...';

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'MODEL_VALIDATION_RESULTS' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    PRINT 'LỖI: Bảng MODEL_VALIDATION_RESULTS không tồn tại.';
    SET @ERROR_COUNT = @ERROR_COUNT + 1;
END
ELSE
BEGIN
    PRINT 'Đã xác nhận bảng MODEL_VALIDATION_RESULTS tồn tại.';
    
    -- Kiểm tra cấu trúc bảng
    DECLARE @MISSING_COLUMNS NVARCHAR(MAX) = '';
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS') AND name = 'VALIDATION_ID')
        SET @MISSING_COLUMNS = @MISSING_COLUMNS + 'VALIDATION_ID, ';
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS') AND name = 'MODEL_ID')
        SET @MISSING_COLUMNS = @MISSING_COLUMNS + 'MODEL_ID, ';
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS') AND name = 'VALIDATION_DATE')
        SET @MISSING_COLUMNS = @MISSING_COLUMNS + 'VALIDATION_DATE, ';
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS') AND name = 'GINI')
        SET @MISSING_COLUMNS = @MISSING_COLUMNS + 'GINI, ';
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS') AND name = 'KS_STATISTIC')
        SET @MISSING_COLUMNS = @MISSING_COLUMNS + 'KS_STATISTIC, ';
    
    IF LEN(@MISSING_COLUMNS) > 0
    BEGIN
        SET @MISSING_COLUMNS = LEFT(@MISSING_COLUMNS, LEN(@MISSING_COLUMNS) - 1); -- Xóa dấu phẩy cuối cùng
        PRINT 'LỖI: Thiếu các cột: ' + @MISSING_COLUMNS + ' trong bảng MODEL_VALIDATION_RESULTS.';
        SET @ERROR_COUNT = @ERROR_COUNT + 1;
    END
    ELSE
    BEGIN
        PRINT 'Đã xác nhận cấu trúc cơ bản của bảng MODEL_VALIDATION_RESULTS.';
    END
END

-- 3. Kiểm thử chèn dữ liệu vào MODEL_VALIDATION_RESULTS
PRINT '';
PRINT 'Kiểm thử chèn dữ liệu vào MODEL_VALIDATION_RESULTS...';

BEGIN TRY
    INSERT INTO MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS (
        MODEL_ID,
        VALIDATION_DATE,
        VALIDATION_TYPE,
        VALIDATION_PERIOD,
        DATA_SAMPLE_SIZE,
        DATA_SAMPLE_DESCRIPTION,
        MODEL_SUBTYPE,
        GINI,
        KS_STATISTIC,
        PSI,
        ACCURACY,
        PRECISION,
        RECALL,
        F1_SCORE,
        IV,
        VALIDATION_COMMENTS,
        VALIDATION_STATUS,
        VALIDATED_BY
    )
    VALUES (
        @NEW_MODEL_ID,
        GETDATE(),
        'UNIT_TEST',
        'JAN2025-MAY2025',
        1000,
        'Sample for unit testing',
        'Test Model Subtype',
        0.65, -- GINI
        0.45, -- KS_STATISTIC
        0.08, -- PSI
        0.82, -- ACCURACY
        0.75, -- PRECISION
        0.68, -- RECALL
        0.71, -- F1_SCORE
        0.40, -- IV
        'Validation record created for unit testing',
        'COMPLETED',
        'Unit Test'
    );
    
    SET @NEW_VALIDATION_ID = SCOPE_IDENTITY();
    PRINT 'Đã tạo bản ghi kiểm thử trong MODEL_VALIDATION_RESULTS với VALIDATION_ID = ' + CAST(@NEW_VALIDATION_ID AS VARCHAR);
END TRY
BEGIN CATCH
    PRINT 'LỖI: Không thể tạo bản ghi kiểm thử trong MODEL_VALIDATION_RESULTS. Lỗi: ' + ERROR_MESSAGE();
    SET @ERROR_COUNT = @ERROR_COUNT + 1;
END CATCH

-- 4. Kiểm thử hàm đánh giá hiệu suất mô hình
PRINT '';
PRINT 'Kiểm thử thủ tục đánh giá hiệu suất mô hình...';

IF OBJECT_ID('MODEL_REGISTRY.dbo.EVALUATE_MODEL_PERFORMANCE', 'P') IS NOT NULL
BEGIN
    BEGIN TRY
        -- Thực thi thủ tục đánh giá
        EXEC MODEL_REGISTRY.dbo.EVALUATE_MODEL_PERFORMANCE @MODEL_ID = @NEW_MODEL_ID;
        PRINT 'Đã thực thi thủ tục EVALUATE_MODEL_PERFORMANCE thành công.';
        
        -- Kiểm tra xem cờ VALIDATION_THRESHOLD_BREACHED đã được cập nhật chưa
        DECLARE @THRESHOLD_BREACHED BIT;
        SELECT @THRESHOLD_BREACHED = VALIDATION_THRESHOLD_BREACHED
        FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS
        WHERE VALIDATION_ID = @NEW_VALIDATION_ID;
        
        IF @THRESHOLD_BREACHED IS NOT NULL
            PRINT 'Đã xác nhận thủ tục đã cập nhật cờ VALIDATION_THRESHOLD_BREACHED.';
        ELSE
        BEGIN
            PRINT 'LỖI: Thủ tục không cập nhật cờ VALIDATION_THRESHOLD_BREACHED.';
            SET @ERROR_COUNT = @ERROR_COUNT + 1;
        END
    END TRY
    BEGIN CATCH
        PRINT 'LỖI: Không thể thực thi thủ tục EVALUATE_MODEL_PERFORMANCE. Lỗi: ' + ERROR_MESSAGE();
        SET @ERROR_COUNT = @ERROR_COUNT + 1;
    END CATCH
END
ELSE
BEGIN
    PRINT 'LỖI: Thủ tục EVALUATE_MODEL_PERFORMANCE không tồn tại.';
    SET @ERROR_COUNT = @ERROR_COUNT + 1;
END

-- 5. Kiểm thử cập nhật MODEL_VALIDATION_RESULTS
PRINT '';
PRINT 'Kiểm thử cập nhật MODEL_VALIDATION_RESULTS...';

BEGIN TRY
    UPDATE MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS
    SET 
        GINI = 0.70,
        KS_STATISTIC = 0.50,
        VALIDATION_COMMENTS = 'Updated validation record for unit testing'
    WHERE VALIDATION_ID = @NEW_VALIDATION_ID;
    
    -- Kiểm tra xem cập nhật có thành công không
    DECLARE @UPDATED_GINI FLOAT;
    SELECT @UPDATED_GINI = GINI 
    FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS 
    WHERE VALIDATION_ID = @NEW_VALIDATION_ID;
    
    IF @UPDATED_GINI = 0.70
        PRINT 'Đã cập nhật bản ghi MODEL_VALIDATION_RESULTS thành công.';
    ELSE
    BEGIN
        PRINT 'LỖI: Cập nhật bản ghi MODEL_VALIDATION_RESULTS không thành công.';
        SET @ERROR_COUNT = @ERROR_COUNT + 1;
    END
END TRY
BEGIN CATCH
    PRINT 'LỖI: Không thể cập nhật MODEL_VALIDATION_RESULTS. Lỗi: ' + ERROR_MESSAGE();
    SET @ERROR_COUNT = @ERROR_COUNT + 1;
END CATCH

-- 6. Kiểm thử trigger TRG_SET_GINI_THRESHOLDS
PRINT '';
PRINT 'Kiểm thử trigger TRG_SET_GINI_THRESHOLDS...';

IF OBJECT_ID('MODEL_REGISTRY.dbo.TRG_SET_GINI_THRESHOLDS', 'TR') IS NOT NULL
BEGIN
    BEGIN TRY
        -- Cập nhật MODEL_SUBTYPE để kích hoạt trigger
        UPDATE MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS
        SET MODEL_SUBTYPE = 'Retail BScore'
        WHERE VALIDATION_ID = @NEW_VALIDATION_ID;
        
        -- Kiểm tra xem thresholds đã được cập nhật tự động chưa
        DECLARE @GINI_THRESHOLD_RED FLOAT;
        DECLARE @GINI_THRESHOLD_AMBER FLOAT;
        
        SELECT 
            @GINI_THRESHOLD_RED = GINI_THRESHOLD_RED,
            @GINI_THRESHOLD_AMBER = GINI_THRESHOLD_AMBER
        FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS
        WHERE VALIDATION_ID = @NEW_VALIDATION_ID;
        
        IF @GINI_THRESHOLD_RED = 0.35 AND @GINI_THRESHOLD_AMBER = 0.45
            PRINT 'Đã xác nhận trigger TRG_SET_GINI_THRESHOLDS hoạt động đúng.';
        ELSE
        BEGIN
            PRINT 'LỖI: Trigger TRG_SET_GINI_THRESHOLDS không hoạt động đúng. Giá trị hiện tại: RED=' + 
                  CAST(@GINI_THRESHOLD_RED AS VARCHAR) + ', AMBER=' + CAST(@GINI_THRESHOLD_AMBER AS VARCHAR);
            SET @ERROR_COUNT = @ERROR_COUNT + 1;
        END
    END TRY
    BEGIN CATCH
        PRINT 'LỖI: Không thể kiểm thử trigger TRG_SET_GINI_THRESHOLDS. Lỗi: ' + ERROR_MESSAGE();
        SET @ERROR_COUNT = @ERROR_COUNT + 1;
    END CATCH
END
ELSE
BEGIN
    PRINT 'Trigger TRG_SET_GINI_THRESHOLDS không tồn tại. Bỏ qua kiểm thử trigger.';
END

-- 7. Kiểm thử view VW_MODEL_PERFORMANCE
PRINT '';
PRINT 'Kiểm thử view VW_MODEL_PERFORMANCE...';

IF EXISTS (SELECT * FROM sys.views WHERE name = 'VW_MODEL_PERFORMANCE' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    BEGIN TRY
        -- Truy vấn thông tin từ view
        DECLARE @VIEW_MODEL_ID INT;
        DECLARE @VIEW_GINI FLOAT;
        DECLARE @VIEW_OVERALL_RATING NVARCHAR(10);
        
        SELECT TOP 1
            @VIEW_MODEL_ID = MODEL_ID,
            @VIEW_GINI = GINI,
            @VIEW_OVERALL_RATING = OVERALL_RATING
        FROM MODEL_REGISTRY.dbo.VW_MODEL_PERFORMANCE
        WHERE MODEL_ID = @NEW_MODEL_ID
        ORDER BY VALIDATION_DATE DESC;
        
        IF @VIEW_MODEL_ID = @NEW_MODEL_ID AND @VIEW_GINI = 0.70
            PRINT 'Đã xác nhận view VW_MODEL_PERFORMANCE truy vấn đúng dữ liệu. Đánh giá tổng thể: ' + @VIEW_OVERALL_RATING;
        ELSE
        BEGIN
            PRINT 'LỖI: View VW_MODEL_PERFORMANCE không truy vấn đúng dữ liệu.';
            SET @ERROR_COUNT = @ERROR_COUNT + 1;
        END
    END TRY
    BEGIN CATCH
        PRINT 'LỖI: Không thể truy vấn view VW_MODEL_PERFORMANCE. Lỗi: ' + ERROR_MESSAGE();
        SET @ERROR_COUNT = @ERROR_COUNT + 1;
    END CATCH
END
ELSE
BEGIN
    PRINT 'LỖI: View VW_MODEL_PERFORMANCE không tồn tại.';
    SET @ERROR_COUNT = @ERROR_COUNT + 1;
END

-- 8. Kiểm thử xóa bản ghi MODEL_VALIDATION_RESULTS
PRINT '';
PRINT 'Kiểm thử xóa bản ghi MODEL_VALIDATION_RESULTS...';

BEGIN TRY
    DELETE FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS
    WHERE VALIDATION_ID = @NEW_VALIDATION_ID;
    
    -- Kiểm tra xem xóa có thành công không
    IF NOT EXISTS (SELECT 1 FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS WHERE VALIDATION_ID = @NEW_VALIDATION_ID)
        PRINT 'Đã xóa bản ghi MODEL_VALIDATION_RESULTS thành công.';
    ELSE
    BEGIN
        PRINT 'LỖI: Xóa bản ghi MODEL_VALIDATION_RESULTS không thành công.';
        SET @ERROR_COUNT = @ERROR_COUNT + 1;
    END
END TRY
BEGIN CATCH
    PRINT 'LỖI: Không thể xóa MODEL_VALIDATION_RESULTS. Lỗi: ' + ERROR_MESSAGE();
    SET @ERROR_COUNT = @ERROR_COUNT + 1;
END CATCH

-- 9. Dọn dẹp đối tượng kiểm thử
PRINT '';
PRINT 'Dọn dẹp đối tượng kiểm thử...';

-- Xóa bản ghi MODEL_REGISTRY
BEGIN TRY
    DELETE FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY
    WHERE MODEL_ID = @NEW_MODEL_ID;
    
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

-- Xóa bản ghi MODEL_TYPE
BEGIN TRY
    DELETE FROM MODEL_REGISTRY.dbo.MODEL_TYPE
    WHERE TYPE_ID = @NEW_TYPE_ID;
    
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
PRINT 'KẾT QUẢ KIỂM THỬ MODEL_VALIDATION_RESULTS';
PRINT '=========================================================';
PRINT '';
IF @ERROR_COUNT = 0
    PRINT 'TẤT CẢ CÁC KIỂM THỬ ĐỀU THÀNH CÔNG!';
ELSE
    PRINT 'CÓ ' + CAST(@ERROR_COUNT AS VARCHAR) + ' LỖI TRONG QUÁ TRÌNH KIỂM THỬ.';
PRINT '';
PRINT 'Hoàn thành kiểm thử đơn vị cho MODEL_VALIDATION_RESULTS.';
GO