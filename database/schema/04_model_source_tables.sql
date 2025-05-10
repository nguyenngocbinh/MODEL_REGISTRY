/*
Tên file: 04_model_source_tables.sql
Mô tả: Tạo bảng MODEL_SOURCE_TABLES để quản lý các bảng nguồn được sử dụng bởi các mô hình
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.0
*/

-- Kiểm tra nếu bảng đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES', 'U') IS NOT NULL
    DROP TABLE MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES;
GO

-- Tạo bảng MODEL_SOURCE_TABLES
CREATE TABLE MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES (
    SOURCE_TABLE_ID INT IDENTITY(1,1) PRIMARY KEY,
    SOURCE_DATABASE NVARCHAR(128) NOT NULL,
    SOURCE_SCHEMA NVARCHAR(128) NOT NULL,
    SOURCE_TABLE_NAME NVARCHAR(128) NOT NULL,
    TABLE_TYPE NVARCHAR(50) NOT NULL, -- 'INPUT', 'OUTPUT', 'REFERENCE', 'TEMPORARY'
    TABLE_DESCRIPTION NVARCHAR(500) NULL,
    DATA_OWNER NVARCHAR(100) NULL, -- Business owner of the data
    UPDATE_FREQUENCY NVARCHAR(50) NULL, -- 'DAILY', 'MONTHLY', 'QUARTERLY', etc.
    DATA_LATENCY NVARCHAR(50) NULL, -- How fresh the data is expected to be
    DATA_QUALITY_SCORE INT NULL, -- Optional quality metric (1-10)
    KEY_COLUMNS NVARCHAR(MAX) NULL, -- JSON array of key column names
    CREATED_BY NVARCHAR(50) DEFAULT SUSER_NAME(),
    CREATED_DATE DATETIME DEFAULT GETDATE(),
    UPDATED_BY NVARCHAR(50) NULL,
    UPDATED_DATE DATETIME NULL,
    IS_ACTIVE BIT DEFAULT 1,
    CONSTRAINTS UC_SOURCE_TABLE UNIQUE (SOURCE_DATABASE, SOURCE_SCHEMA, SOURCE_TABLE_NAME)
);
GO

-- Tạo chỉ mục cho các trường thường được tìm kiếm
CREATE INDEX IDX_SOURCE_TABLES_NAME ON MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES(SOURCE_TABLE_NAME);
CREATE INDEX IDX_SOURCE_TABLES_TYPE ON MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES(TABLE_TYPE);
CREATE INDEX IDX_SOURCE_TABLES_ACTIVE ON MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES(IS_ACTIVE);
GO

-- Thêm comment cho bảng và các cột
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Bảng quản lý các bảng nguồn được sử dụng bởi các mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SOURCE_TABLES';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'ID của bảng nguồn, khóa chính tự động tăng', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SOURCE_TABLES',
    @level2type = N'COLUMN', @level2name = N'SOURCE_TABLE_ID';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Tên database chứa bảng nguồn', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SOURCE_TABLES',
    @level2type = N'COLUMN', @level2name = N'SOURCE_DATABASE';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Tên schema chứa bảng nguồn', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SOURCE_TABLES',
    @level2type = N'COLUMN', @level2name = N'SOURCE_SCHEMA';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Tên bảng nguồn', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SOURCE_TABLES',
    @level2type = N'COLUMN', @level2name = N'SOURCE_TABLE_NAME';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Loại bảng: INPUT (dữ liệu đầu vào), OUTPUT (đầu ra), REFERENCE (tham chiếu), TEMPORARY (tạm thời)', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SOURCE_TABLES',
    @level2type = N'COLUMN', @level2name = N'TABLE_TYPE';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Mảng JSON chứa tên các cột khóa của bảng', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SOURCE_TABLES',
    @level2type = N'COLUMN', @level2name = N'KEY_COLUMNS';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Điểm đánh giá chất lượng dữ liệu (1-10)', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SOURCE_TABLES',
    @level2type = N'COLUMN', @level2name = N'DATA_QUALITY_SCORE';
GO

PRINT 'Bảng MODEL_SOURCE_TABLES đã được tạo thành công';
GO