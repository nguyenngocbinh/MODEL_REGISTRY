/*
Tên file: 01_model_type.sql
Mô tả: Tạo bảng MODEL_TYPE để phân loại các loại mô hình khác nhau
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.1 - Sửa lỗi extended properties
*/

-- Xác nhận database đã được chọn
IF DB_NAME() != 'MODEL_REGISTRY'
BEGIN
    RAISERROR('Vui lòng đảm bảo đang sử dụng database MODEL_REGISTRY', 16, 1)
    RETURN
END

-- Kiểm tra nếu bảng đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_TYPE', 'U') IS NOT NULL
    DROP TABLE MODEL_REGISTRY.dbo.MODEL_TYPE;
GO

-- Tạo bảng MODEL_TYPE để phân loại các mô hình
CREATE TABLE MODEL_REGISTRY.dbo.MODEL_TYPE (
    TYPE_ID INT IDENTITY(1,1) PRIMARY KEY,
    TYPE_CODE NVARCHAR(20) NOT NULL,
    TYPE_NAME NVARCHAR(100) NOT NULL,
    TYPE_DESCRIPTION NVARCHAR(500) NULL,
    IS_ACTIVE BIT DEFAULT 1,
    CREATED_DATE DATETIME DEFAULT GETDATE(),
    CREATED_BY NVARCHAR(50) DEFAULT SUSER_NAME(),
    UPDATED_DATE DATETIME NULL,
    UPDATED_BY NVARCHAR(50) NULL,
    CONSTRAINT UC_MODEL_TYPE_CODE UNIQUE (TYPE_CODE)
);
GO

-- Tạo chỉ mục cho trường TYPE_CODE để tăng tốc độ tìm kiếm
CREATE INDEX IDX_MODEL_TYPE_CODE ON MODEL_REGISTRY.dbo.MODEL_TYPE(TYPE_CODE);
GO

-- Thêm comment cho bảng và các cột - phương pháp cải tiến tránh lỗi
BEGIN TRY
    -- Thêm comment cho bảng
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Bảng phân loại các loại mô hình đánh giá rủi ro', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'MODEL_TYPE';

    -- Thêm comment cho cột TYPE_ID
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Mã loại mô hình, khóa chính tự động tăng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'MODEL_TYPE',
        @level2type = N'COLUMN', @level2name = N'TYPE_ID';

    -- Thêm comment cho cột TYPE_CODE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Mã ngắn của loại mô hình (PD, LGD, EAD, SCORECARD, v.v.)', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'MODEL_TYPE',
        @level2type = N'COLUMN', @level2name = N'TYPE_CODE';

    -- Thêm comment cho cột TYPE_NAME
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Tên đầy đủ của loại mô hình', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'MODEL_TYPE',
        @level2type = N'COLUMN', @level2name = N'TYPE_NAME';

    -- Thêm comment cho cột TYPE_DESCRIPTION
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Mô tả chi tiết về loại mô hình', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'MODEL_TYPE',
        @level2type = N'COLUMN', @level2name = N'TYPE_DESCRIPTION';

    PRINT N'Các extended properties đã được thêm thành công';
END TRY
BEGIN CATCH
    PRINT N'Cảnh báo: Không thể thêm extended properties. Error: ' + ERROR_MESSAGE();
    PRINT N'Quá trình tạo bảng vẫn thành công.';
END CATCH
GO

PRINT N'Bảng MODEL_TYPE đã được tạo thành công';
GO