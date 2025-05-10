/*
Tên file: 02_model_registry.sql
Mô tả: Tạo bảng MODEL_REGISTRY để lưu trữ thông tin về các mô hình
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.0
*/

-- Kiểm tra nếu bảng đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_REGISTRY', 'U') IS NOT NULL
    DROP TABLE MODEL_REGISTRY.dbo.MODEL_REGISTRY;
GO

-- Tạo bảng MODEL_REGISTRY
CREATE TABLE MODEL_REGISTRY.dbo.MODEL_REGISTRY (
    MODEL_ID INT IDENTITY(1,1) PRIMARY KEY,
    TYPE_ID INT NULL,
    MODEL_NAME NVARCHAR(100) NOT NULL,
    MODEL_DESCRIPTION NVARCHAR(500) NULL,
    MODEL_VERSION NVARCHAR(20) NOT NULL,
    SOURCE_DATABASE NVARCHAR(100) NOT NULL,
    SOURCE_SCHEMA NVARCHAR(100) NOT NULL,
    SOURCE_TABLE_NAME NVARCHAR(100) NOT NULL,
    REF_SOURCE NVARCHAR(255) NULL,  -- Reference document or business source
    EFF_DATE DATE NOT NULL,         -- Effective date of the model version
    EXP_DATE DATE NOT NULL,         -- Expiration date of the model version
    IS_ACTIVE BIT DEFAULT 1,
    PRIORITY INT DEFAULT 1,         -- Used when multiple models might apply
    MODEL_CATEGORY NVARCHAR(50),    -- e.g., 'Retail', 'Corporate', 'SME'
    SEGMENT_CRITERIA NVARCHAR(MAX), -- JSON or description of segmentation criteria
    CREATED_BY NVARCHAR(50) DEFAULT SUSER_NAME(),
    CREATED_DATE DATETIME DEFAULT GETDATE(),
    UPDATED_BY NVARCHAR(50) NULL,
    UPDATED_DATE DATETIME NULL,
    CONSTRAINTS UC_MODEL_VERSION UNIQUE (MODEL_NAME, MODEL_VERSION),
    FOREIGN KEY (TYPE_ID) REFERENCES MODEL_REGISTRY.dbo.MODEL_TYPE(TYPE_ID)
);
GO

-- Tạo chỉ mục
CREATE INDEX IDX_MODEL_REGISTRY_TYPE ON MODEL_REGISTRY.dbo.MODEL_REGISTRY(TYPE_ID);
CREATE INDEX IDX_MODEL_REGISTRY_DATES ON MODEL_REGISTRY.dbo.MODEL_REGISTRY(EFF_DATE, EXP_DATE);
CREATE INDEX IDX_MODEL_REGISTRY_NAME ON MODEL_REGISTRY.dbo.MODEL_REGISTRY(MODEL_NAME, IS_ACTIVE);
GO

-- Thêm comment cho bảng và các cột
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Bảng đăng ký chính cho tất cả các mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_REGISTRY';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'ID mô hình, khóa chính tự động tăng', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_REGISTRY',
    @level2type = N'COLUMN', @level2name = N'MODEL_ID';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'ID loại mô hình, khóa ngoại tham chiếu đến bảng MODEL_TYPE', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_REGISTRY',
    @level2type = N'COLUMN', @level2name = N'TYPE_ID';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Tên mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_REGISTRY',
    @level2type = N'COLUMN', @level2name = N'MODEL_NAME';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Mô tả chi tiết về mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_REGISTRY',
    @level2type = N'COLUMN', @level2name = N'MODEL_DESCRIPTION';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Phiên bản mô hình (e.g., 1.0, 2.1)', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_REGISTRY',
    @level2type = N'COLUMN', @level2name = N'MODEL_VERSION';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Ngày mô hình bắt đầu có hiệu lực', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_REGISTRY',
    @level2type = N'COLUMN', @level2name = N'EFF_DATE';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Ngày mô hình hết hiệu lực', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_REGISTRY',
    @level2type = N'COLUMN', @level2name = N'EXP_DATE';
GO

PRINT 'Bảng MODEL_REGISTRY đã được tạo thành công';
GO