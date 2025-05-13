/*
Tên file: 06_model_table_usage.sql
Mô tả: Tạo bảng MODEL_TABLE_USAGE để quản lý mối quan hệ nhiều-nhiều giữa mô hình và bảng dữ liệu
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
IF OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE', 'U') IS NOT NULL
    DROP TABLE MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE;
GO

-- Tạo bảng MODEL_TABLE_USAGE
CREATE TABLE MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE (
    USAGE_ID INT IDENTITY(1,1) PRIMARY KEY,
    MODEL_ID INT NOT NULL,
    SOURCE_TABLE_ID INT NOT NULL,
    USAGE_PURPOSE NVARCHAR(100) NOT NULL, -- e.g., 'Primary Input', 'Result Storage', 'Reference Data'
    PRIORITY INT DEFAULT 1, -- Indicate importance of this table to the model
    USAGE_DESCRIPTION NVARCHAR(500) NULL,
    EFF_DATE DATE NOT NULL,
    EXP_DATE DATE NOT NULL DEFAULT '9999-12-31',
    IS_ACTIVE BIT DEFAULT 1,
    CREATED_BY NVARCHAR(50) DEFAULT SUSER_NAME(),
    CREATED_DATE DATETIME DEFAULT GETDATE(),
    UPDATED_BY NVARCHAR(50) NULL,
    UPDATED_DATE DATETIME NULL,
    FOREIGN KEY (MODEL_ID) REFERENCES MODEL_REGISTRY.dbo.MODEL_REGISTRY(MODEL_ID),
    FOREIGN KEY (SOURCE_TABLE_ID) REFERENCES MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES(SOURCE_TABLE_ID),
    CONSTRAINT UC_MODEL_TABLE_USAGE UNIQUE (MODEL_ID, SOURCE_TABLE_ID, USAGE_PURPOSE)
);
GO

-- Tạo chỉ mục để tăng tốc độ truy vấn
CREATE INDEX IDX_TABLE_USAGE_MODEL_ID ON MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE(MODEL_ID);
CREATE INDEX IDX_TABLE_USAGE_SOURCE_TABLE_ID ON MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE(SOURCE_TABLE_ID);
CREATE INDEX IDX_TABLE_USAGE_DATES ON MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE(EFF_DATE, EXP_DATE);
CREATE INDEX IDX_TABLE_USAGE_ACTIVE ON MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE(IS_ACTIVE);
GO

-- Thêm comment cho bảng và các cột
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Bảng quản lý mối quan hệ nhiều-nhiều giữa mô hình và bảng dữ liệu', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_TABLE_USAGE';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'ID của mối quan hệ sử dụng, khóa chính tự động tăng', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_TABLE_USAGE',
    @level2type = N'COLUMN', @level2name = N'USAGE_ID';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'ID của mô hình, tham chiếu đến bảng MODEL_REGISTRY', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_TABLE_USAGE',
    @level2type = N'COLUMN', @level2name = N'MODEL_ID';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'ID của bảng nguồn, tham chiếu đến bảng MODEL_SOURCE_TABLES', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_TABLE_USAGE',
    @level2type = N'COLUMN', @level2name = N'SOURCE_TABLE_ID';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Mục đích sử dụng: Primary Input (đầu vào chính), Result Storage (lưu trữ kết quả), Reference Data (dữ liệu tham chiếu)', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_TABLE_USAGE',
    @level2type = N'COLUMN', @level2name = N'USAGE_PURPOSE';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Mức độ ưu tiên của bảng dữ liệu đối với mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_TABLE_USAGE',
    @level2type = N'COLUMN', @level2name = N'PRIORITY';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Ngày bắt đầu có hiệu lực của mối quan hệ', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_TABLE_USAGE',
    @level2type = N'COLUMN', @level2name = N'EFF_DATE';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Ngày hết hiệu lực của mối quan hệ', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_TABLE_USAGE',
    @level2type = N'COLUMN', @level2name = N'EXP_DATE';
GO

PRINT N'Bảng MODEL_TABLE_USAGE đã được tạo thành công';
GO