/*
Tên file: 07_model_table_mapping.sql
Mô tả: Tạo bảng MODEL_TABLE_MAPPING để lưu trữ chi tiết về cách mô hình sử dụng các bảng dữ liệu
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.0
*/

-- Kiểm tra nếu bảng đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING', 'U') IS NOT NULL
    DROP TABLE MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING;
GO

-- Tạo bảng MODEL_TABLE_MAPPING
CREATE TABLE MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING (
    MAPPING_ID INT IDENTITY(1,1) PRIMARY KEY,
    MODEL_ID INT NOT NULL,
    SOURCE_TABLE_ID INT NOT NULL,
    USAGE_TYPE NVARCHAR(50) NOT NULL, -- 'FEATURE_SOURCE', 'RESULT_STORE', 'LOOKUP', 'VALIDATION'
    REQUIRED_COLUMNS NVARCHAR(MAX) NULL, -- JSON array of required columns from this table
    FILTERS_APPLIED NVARCHAR(MAX) NULL, -- WHERE clause or description of filters used
    IS_CRITICAL BIT DEFAULT 0, -- Flag for tables that are mission-critical
    DATA_TRANSFORMATION NVARCHAR(MAX) NULL, -- Description of transformations applied
    SEQUENCE_ORDER INT DEFAULT 1, -- Processing order for tables
    EFF_DATE DATE NOT NULL,
    EXP_DATE DATE NOT NULL DEFAULT '9999-12-31',
    IS_ACTIVE BIT DEFAULT 1,
    CREATED_BY NVARCHAR(50) DEFAULT SUSER_NAME(),
    CREATED_DATE DATETIME DEFAULT GETDATE(),
    UPDATED_BY NVARCHAR(50) NULL,
    UPDATED_DATE DATETIME NULL,
    FOREIGN KEY (MODEL_ID) REFERENCES MODEL_REGISTRY.dbo.MODEL_REGISTRY(MODEL_ID),
    FOREIGN KEY (SOURCE_TABLE_ID) REFERENCES MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES(SOURCE_TABLE_ID),
    CONSTRAINT UC_MODEL_TABLE_SOURCE UNIQUE (MODEL_ID, SOURCE_TABLE_ID, USAGE_TYPE)
);
GO

-- Tạo chỉ mục để tăng tốc độ truy vấn
CREATE INDEX IDX_TABLE_MAPPING_MODEL_ID ON MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING(MODEL_ID);
CREATE INDEX IDX_TABLE_MAPPING_SOURCE_TABLE_ID ON MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING(SOURCE_TABLE_ID);
CREATE INDEX IDX_TABLE_MAPPING_USAGE_TYPE ON MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING(USAGE_TYPE);
CREATE INDEX IDX_TABLE_MAPPING_CRITICAL ON MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING(IS_CRITICAL);
GO

-- Thêm comment cho bảng và các cột
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Bảng lưu trữ chi tiết về cách mô hình sử dụng các bảng dữ liệu', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_TABLE_MAPPING';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'ID của bản đồ bảng, khóa chính tự động tăng', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_TABLE_MAPPING',
    @level2type = N'COLUMN', @level2name = N'MAPPING_ID';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'ID của mô hình, tham chiếu đến bảng MODEL_REGISTRY', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_TABLE_MAPPING',
    @level2type = N'COLUMN', @level2name = N'MODEL_ID';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'ID của bảng nguồn, tham chiếu đến bảng MODEL_SOURCE_TABLES', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_TABLE_MAPPING',
    @level2type = N'COLUMN', @level2name = N'SOURCE_TABLE_ID';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Loại sử dụng: FEATURE_SOURCE (nguồn đặc trưng), RESULT_STORE (lưu trữ kết quả), LOOKUP (tra cứu), VALIDATION (kiểm định)', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_TABLE_MAPPING',
    @level2type = N'COLUMN', @level2name = N'USAGE_TYPE';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Mảng JSON chứa các cột cần thiết từ bảng này', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_TABLE_MAPPING',
    @level2type = N'COLUMN', @level2name = N'REQUIRED_COLUMNS';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Điều kiện WHERE hoặc mô tả về các bộ lọc được sử dụng', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_TABLE_MAPPING',
    @level2type = N'COLUMN', @level2name = N'FILTERS_APPLIED';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Cờ đánh dấu cho các bảng quan trọng thiết yếu', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_TABLE_MAPPING',
    @level2type = N'COLUMN', @level2name = N'IS_CRITICAL';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Thứ tự xử lý các bảng', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_TABLE_MAPPING',
    @level2type = N'COLUMN', @level2name = N'SEQUENCE_ORDER';
GO

PRINT 'Bảng MODEL_TABLE_MAPPING đã được tạo thành công';
GO