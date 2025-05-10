/*
Tên file: 08_model_segment_mapping.sql
Mô tả: Tạo bảng MODEL_SEGMENT_MAPPING để quản lý việc áp dụng mô hình cho các phân khúc khách hàng
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.0
*/

-- Kiểm tra nếu bảng đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_SEGMENT_MAPPING', 'U') IS NOT NULL
    DROP TABLE MODEL_REGISTRY.dbo.MODEL_SEGMENT_MAPPING;
GO

-- Tạo bảng MODEL_SEGMENT_MAPPING
CREATE TABLE MODEL_REGISTRY.dbo.MODEL_SEGMENT_MAPPING (
    MAPPING_ID INT IDENTITY(1,1) PRIMARY KEY,
    MODEL_ID INT NOT NULL,
    SEGMENT_NAME NVARCHAR(100) NOT NULL,
    SEGMENT_DESCRIPTION NVARCHAR(500) NULL,
    SEGMENT_CRITERIA NVARCHAR(MAX) NULL, -- SQL WHERE clause or logic description
    PRIORITY INT DEFAULT 1,              -- If multiple segments could apply
    EXPECTED_VOLUME INT NULL,            -- Expected number of records in this segment
    SEGMENT_PERFORMANCE NVARCHAR(MAX) NULL, -- JSON with performance metrics for this segment
    EFF_DATE DATE NOT NULL,
    EXP_DATE DATE NOT NULL,
    IS_ACTIVE BIT DEFAULT 1,
    CREATED_BY NVARCHAR(50) DEFAULT SUSER_NAME(),
    CREATED_DATE DATETIME DEFAULT GETDATE(),
    UPDATED_BY NVARCHAR(50) NULL,
    UPDATED_DATE DATETIME NULL,
    FOREIGN KEY (MODEL_ID) REFERENCES MODEL_REGISTRY.dbo.MODEL_REGISTRY(MODEL_ID)
);
GO

-- Tạo chỉ mục để tăng tốc độ truy vấn
CREATE INDEX IDX_SEGMENT_MAPPING_MODEL_ID ON MODEL_REGISTRY.dbo.MODEL_SEGMENT_MAPPING(MODEL_ID);
CREATE INDEX IDX_SEGMENT_MAPPING_NAME ON MODEL_REGISTRY.dbo.MODEL_SEGMENT_MAPPING(SEGMENT_NAME);
CREATE INDEX IDX_SEGMENT_MAPPING_DATES ON MODEL_REGISTRY.dbo.MODEL_SEGMENT_MAPPING(EFF_DATE, EXP_DATE);
CREATE INDEX IDX_SEGMENT_MAPPING_ACTIVE ON MODEL_REGISTRY.dbo.MODEL_SEGMENT_MAPPING(IS_ACTIVE);
GO

-- Thêm comment cho bảng và các cột
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Bảng quản lý việc áp dụng mô hình cho các phân khúc khách hàng', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SEGMENT_MAPPING';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'ID của bản đồ phân khúc, khóa chính tự động tăng', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SEGMENT_MAPPING',
    @level2type = N'COLUMN', @level2name = N'MAPPING_ID';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'ID của mô hình, tham chiếu đến bảng MODEL_REGISTRY', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SEGMENT_MAPPING',
    @level2type = N'COLUMN', @level2name = N'MODEL_ID';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Tên phân khúc khách hàng', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SEGMENT_MAPPING',
    @level2type = N'COLUMN', @level2name = N'SEGMENT_NAME';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Mô tả chi tiết về phân khúc khách hàng', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SEGMENT_MAPPING',
    @level2type = N'COLUMN', @level2name = N'SEGMENT_DESCRIPTION';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Tiêu chí phân khúc dưới dạng mệnh đề WHERE SQL hoặc mô tả logic', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SEGMENT_MAPPING',
    @level2type = N'COLUMN', @level2name = N'SEGMENT_CRITERIA';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Mức độ ưu tiên nếu nhiều phân khúc có thể áp dụng', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SEGMENT_MAPPING',
    @level2type = N'COLUMN', @level2name = N'PRIORITY';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Khối lượng bản ghi dự kiến trong phân khúc này', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SEGMENT_MAPPING',
    @level2type = N'COLUMN', @level2name = N'EXPECTED_VOLUME';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Hiệu suất của mô hình trên phân khúc này dưới dạng JSON', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SEGMENT_MAPPING',
    @level2type = N'COLUMN', @level2name = N'SEGMENT_PERFORMANCE';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Ngày bắt đầu có hiệu lực của áp dụng', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SEGMENT_MAPPING',
    @level2type = N'COLUMN', @level2name = N'EFF_DATE';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Ngày hết hiệu lực của áp dụng', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SEGMENT_MAPPING',
    @level2type = N'COLUMN', @level2name = N'EXP_DATE';
GO

PRINT 'Bảng MODEL_SEGMENT_MAPPING đã được tạo thành công';
GO