/*
Tên file: 14_feature_source_tables.sql
Mô tả: Tạo bảng FEATURE_SOURCE_TABLES để quản lý mối quan hệ giữa đặc trưng và các bảng nguồn dữ liệu
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-15
Phiên bản: 1.0
*/

-- Xác nhận database đã được chọn
IF DB_NAME() != 'MODEL_REGISTRY'
BEGIN
    RAISERROR('Vui lòng đảm bảo đang sử dụng database MODEL_REGISTRY', 16, 1)
    RETURN
END

-- Kiểm tra nếu bảng đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.FEATURE_SOURCE_TABLES', 'U') IS NOT NULL
    DROP TABLE MODEL_REGISTRY.dbo.FEATURE_SOURCE_TABLES;
GO

-- Tạo bảng FEATURE_SOURCE_TABLES
CREATE TABLE MODEL_REGISTRY.dbo.FEATURE_SOURCE_TABLES (
    MAPPING_ID INT IDENTITY(1,1) PRIMARY KEY,
    FEATURE_ID INT NOT NULL,
    SOURCE_TABLE_ID INT NOT NULL,
    SOURCE_COLUMN_NAME NVARCHAR(128) NOT NULL,
    COLUMN_ALIAS NVARCHAR(128) NULL, -- Alias name used for the column in feature derivation
    SQL_SNIPPET NVARCHAR(MAX) NULL, -- SQL snippet for extracting the feature from this source
    JOIN_CONDITIONS NVARCHAR(MAX) NULL, -- SQL JOIN conditions for this source table
    FILTERS_APPLIED NVARCHAR(MAX) NULL, -- WHERE clause conditions applied to this source
    IS_PRIMARY_SOURCE BIT DEFAULT 0, -- Flag indicating if this is the primary source for the feature
    DATA_FRESHNESS_REQ NVARCHAR(50) NULL, -- e.g., 'REAL_TIME', 'DAILY', 'WEEKLY'
    JOINS_REQUIRED NVARCHAR(MAX) NULL, -- JSON array of tables required to join
    PRIORITY INT DEFAULT 1, -- Used when multiple sources might be available
    CREATED_BY NVARCHAR(50) DEFAULT SUSER_NAME(),
    CREATED_DATE DATETIME DEFAULT GETDATE(),
    UPDATED_BY NVARCHAR(50) NULL,
    UPDATED_DATE DATETIME NULL,
    IS_ACTIVE BIT DEFAULT 1,
    EFF_DATE DATE DEFAULT GETDATE(),
    EXP_DATE DATE DEFAULT '9999-12-31',
    FOREIGN KEY (FEATURE_ID) REFERENCES MODEL_REGISTRY.dbo.FEATURE_REGISTRY(FEATURE_ID),
    FOREIGN KEY (SOURCE_TABLE_ID) REFERENCES MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES(SOURCE_TABLE_ID),
    CONSTRAINT UC_FEATURE_SOURCE_TABLE UNIQUE (FEATURE_ID, SOURCE_TABLE_ID, SOURCE_COLUMN_NAME)
);
GO

-- Tạo chỉ mục để tăng tốc độ truy vấn
CREATE INDEX IDX_FEATURE_SOURCE_FEATURE_ID ON MODEL_REGISTRY.dbo.FEATURE_SOURCE_TABLES(FEATURE_ID);
CREATE INDEX IDX_FEATURE_SOURCE_TABLE_ID ON MODEL_REGISTRY.dbo.FEATURE_SOURCE_TABLES(SOURCE_TABLE_ID);
CREATE INDEX IDX_FEATURE_SOURCE_PRIMARY ON MODEL_REGISTRY.dbo.FEATURE_SOURCE_TABLES(IS_PRIMARY_SOURCE);
CREATE INDEX IDX_FEATURE_SOURCE_ACTIVE ON MODEL_REGISTRY.dbo.FEATURE_SOURCE_TABLES(IS_ACTIVE);
CREATE INDEX IDX_FEATURE_SOURCE_DATES ON MODEL_REGISTRY.dbo.FEATURE_SOURCE_TABLES(EFF_DATE, EXP_DATE);
GO

-- Thêm comment cho bảng và các cột
BEGIN TRY
    -- Thêm comment cho bảng
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Bảng quản lý mối quan hệ giữa đặc trưng và các bảng nguồn dữ liệu', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_SOURCE_TABLES';

    -- Thêm comment cho cột MAPPING_ID
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'ID của bản đồ nguồn, khóa chính tự động tăng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_SOURCE_TABLES',
        @level2type = N'COLUMN', @level2name = N'MAPPING_ID';

    -- Thêm comment cho cột FEATURE_ID
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'ID của đặc trưng, tham chiếu đến bảng FEATURE_REGISTRY', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_SOURCE_TABLES',
        @level2type = N'COLUMN', @level2name = N'FEATURE_ID';

    -- Thêm comment cho cột SOURCE_TABLE_ID
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'ID của bảng nguồn, tham chiếu đến bảng MODEL_SOURCE_TABLES', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_SOURCE_TABLES',
        @level2type = N'COLUMN', @level2name = N'SOURCE_TABLE_ID';

    -- Thêm comment cho cột SOURCE_COLUMN_NAME
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Tên cột trong bảng nguồn', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_SOURCE_TABLES',
        @level2type = N'COLUMN', @level2name = N'SOURCE_COLUMN_NAME';

    -- Thêm comment cho cột COLUMN_ALIAS
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Tên bí danh được sử dụng cho cột trong quá trình tạo đặc trưng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_SOURCE_TABLES',
        @level2type = N'COLUMN', @level2name = N'COLUMN_ALIAS';

    -- Thêm comment cho cột SQL_SNIPPET
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Đoạn mã SQL để trích xuất đặc trưng từ nguồn này', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_SOURCE_TABLES',
        @level2type = N'COLUMN', @level2name = N'SQL_SNIPPET';

    -- Thêm comment cho cột JOIN_CONDITIONS
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Điều kiện JOIN SQL cho bảng nguồn này', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_SOURCE_TABLES',
        @level2type = N'COLUMN', @level2name = N'JOIN_CONDITIONS';

    -- Thêm comment cho cột FILTERS_APPLIED
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Điều kiện WHERE áp dụng cho nguồn này', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_SOURCE_TABLES',
        @level2type = N'COLUMN', @level2name = N'FILTERS_APPLIED';

    -- Thêm comment cho cột IS_PRIMARY_SOURCE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Cờ đánh dấu nếu đây là nguồn chính cho đặc trưng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_SOURCE_TABLES',
        @level2type = N'COLUMN', @level2name = N'IS_PRIMARY_SOURCE';

    -- Thêm comment cho cột DATA_FRESHNESS_REQ
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Yêu cầu độ mới của dữ liệu: REAL_TIME (thời gian thực), DAILY (hàng ngày), WEEKLY (hàng tuần)', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_SOURCE_TABLES',
        @level2type = N'COLUMN', @level2name = N'DATA_FRESHNESS_REQ';

    -- Thêm comment cho cột JOINS_REQUIRED
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Mảng JSON của các bảng cần thiết để kết nối', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_SOURCE_TABLES',
        @level2type = N'COLUMN', @level2name = N'JOINS_REQUIRED';

    -- Thêm comment cho cột PRIORITY
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Mức độ ưu tiên khi có nhiều nguồn có sẵn', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_SOURCE_TABLES',
        @level2type = N'COLUMN', @level2name = N'PRIORITY';

    PRINT N'Các extended properties đã được thêm thành công';
END TRY
BEGIN CATCH
    PRINT N'Cảnh báo: Không thể thêm extended properties. Error: ' + ERROR_MESSAGE();
    PRINT N'Quá trình tạo bảng vẫn thành công.';
END CATCH
GO

PRINT N'Bảng FEATURE_SOURCE_TABLES đã được tạo thành công';
GO