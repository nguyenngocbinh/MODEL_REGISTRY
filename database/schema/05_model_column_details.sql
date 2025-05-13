/*
Tên file: 05_model_column_details.sql
Mô tả: Tạo bảng MODEL_COLUMN_DETAILS để lưu trữ thông tin chi tiết về các cột dữ liệu trong bảng nguồn
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
IF OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS', 'U') IS NOT NULL
    DROP TABLE MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS;
GO

-- Tạo bảng MODEL_COLUMN_DETAILS
CREATE TABLE MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS (
    COLUMN_ID INT IDENTITY(1,1) PRIMARY KEY,
    SOURCE_TABLE_ID INT NOT NULL,
    COLUMN_NAME NVARCHAR(128) NOT NULL,
    DATA_TYPE NVARCHAR(50) NOT NULL,
    COLUMN_DESCRIPTION NVARCHAR(500) NULL,
    IS_MANDATORY BIT DEFAULT 0,
    IS_FEATURE BIT DEFAULT 0,
    FEATURE_IMPORTANCE FLOAT NULL,
    BUSINESS_DEFINITION NVARCHAR(MAX) NULL,
    TRANSFORMATION_LOGIC NVARCHAR(MAX) NULL, -- How this column is processed for models
    EXPECTED_VALUES NVARCHAR(MAX) NULL, -- Description of valid values or range
    DATA_QUALITY_CHECKS NVARCHAR(MAX) NULL, -- Checks performed on this column
    CREATED_BY NVARCHAR(50) DEFAULT SUSER_NAME(),
    CREATED_DATE DATETIME DEFAULT GETDATE(),
    UPDATED_BY NVARCHAR(50) NULL,
    UPDATED_DATE DATETIME NULL,
    FOREIGN KEY (SOURCE_TABLE_ID) REFERENCES MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES(SOURCE_TABLE_ID),
    CONSTRAINT UC_SOURCE_COLUMN UNIQUE (SOURCE_TABLE_ID, COLUMN_NAME)
);
GO

-- Tạo chỉ mục để tăng tốc truy vấn
CREATE INDEX IDX_COLUMN_DETAILS_TABLE_ID ON MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS(SOURCE_TABLE_ID);
CREATE INDEX IDX_COLUMN_DETAILS_IS_FEATURE ON MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS(IS_FEATURE);
GO

-- Thêm comment cho bảng và các cột
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Bảng lưu trữ thông tin chi tiết về các cột dữ liệu', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_COLUMN_DETAILS';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'ID của cột, khóa chính tự động tăng', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_COLUMN_DETAILS',
    @level2type = N'COLUMN', @level2name = N'COLUMN_ID';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'ID của bảng nguồn, tham chiếu đến bảng MODEL_SOURCE_TABLES', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_COLUMN_DETAILS',
    @level2type = N'COLUMN', @level2name = N'SOURCE_TABLE_ID';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Tên cột trong bảng nguồn', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_COLUMN_DETAILS',
    @level2type = N'COLUMN', @level2name = N'COLUMN_NAME';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Kiểu dữ liệu của cột', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_COLUMN_DETAILS',
    @level2type = N'COLUMN', @level2name = N'DATA_TYPE';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Cờ đánh dấu nếu cột là bắt buộc', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_COLUMN_DETAILS',
    @level2type = N'COLUMN', @level2name = N'IS_MANDATORY';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Cờ đánh dấu nếu cột được sử dụng làm đặc trưng cho mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_COLUMN_DETAILS',
    @level2type = N'COLUMN', @level2name = N'IS_FEATURE';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Mức độ quan trọng của đặc trưng trong mô hình (nếu có)', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_COLUMN_DETAILS',
    @level2type = N'COLUMN', @level2name = N'FEATURE_IMPORTANCE';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Định nghĩa nghiệp vụ của cột dữ liệu', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_COLUMN_DETAILS',
    @level2type = N'COLUMN', @level2name = N'BUSINESS_DEFINITION';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Logic biến đổi dữ liệu của cột cho mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_COLUMN_DETAILS',
    @level2type = N'COLUMN', @level2name = N'TRANSFORMATION_LOGIC';
GO

PRINT N'Bảng MODEL_COLUMN_DETAILS đã được tạo thành công';
GO