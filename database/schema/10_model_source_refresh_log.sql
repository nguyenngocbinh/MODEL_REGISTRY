/*
Tên file: 10_model_source_refresh_log.sql
Mô tả: Tạo bảng MODEL_SOURCE_REFRESH_LOG để ghi nhật ký cập nhật dữ liệu nguồn
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.0
*/

-- Kiểm tra nếu bảng đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG', 'U') IS NOT NULL
    DROP TABLE MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG;
GO

-- Tạo bảng MODEL_SOURCE_REFRESH_LOG
CREATE TABLE MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG (
    REFRESH_ID INT IDENTITY(1,1) PRIMARY KEY,
    SOURCE_TABLE_ID INT NOT NULL,
    PROCESS_DATE DATE NOT NULL,
    REFRESH_START_TIME DATETIME NOT NULL,
    REFRESH_END_TIME DATETIME NULL,
    REFRESH_STATUS NVARCHAR(20) NOT NULL, -- 'STARTED', 'COMPLETED', 'FAILED', 'PARTIAL'
    REFRESH_TYPE NVARCHAR(50) NOT NULL, -- 'FULL', 'INCREMENTAL', 'DELTA', 'RESTATEMENT'
    REFRESH_METHOD NVARCHAR(50) NULL, -- 'ETL', 'MANUAL', 'SCHEDULED'
    RECORDS_PROCESSED INT NULL,
    RECORDS_INSERTED INT NULL,
    RECORDS_UPDATED INT NULL,
    RECORDS_DELETED INT NULL,
    RECORDS_REJECTED INT NULL,
    EXECUTION_TIME_SECONDS INT NULL, -- Performance metric
    DATA_VOLUME_MB DECIMAL(10,2) NULL, -- Size of processed data
    ERROR_MESSAGE NVARCHAR(MAX) NULL,
    ERROR_DETAILS NVARCHAR(MAX) NULL, -- Stack trace or detailed error info
    INITIATED_BY NVARCHAR(100) NULL, -- User or process that initiated the refresh
    CREATED_BY NVARCHAR(50) DEFAULT SUSER_NAME(),
    CREATED_DATE DATETIME DEFAULT GETDATE(),
    UPDATED_BY NVARCHAR(50) NULL,
    UPDATED_DATE DATETIME NULL,
    FOREIGN KEY (SOURCE_TABLE_ID) REFERENCES MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES(SOURCE_TABLE_ID)
);
GO

-- Tạo chỉ mục để tăng tốc độ truy vấn
CREATE INDEX IDX_REFRESH_LOG_TABLE_ID ON MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG(SOURCE_TABLE_ID);
CREATE INDEX IDX_REFRESH_LOG_DATE ON MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG(PROCESS_DATE);
CREATE INDEX IDX_REFRESH_LOG_STATUS ON MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG(REFRESH_STATUS);
CREATE INDEX IDX_REFRESH_LOG_START_TIME ON MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG(REFRESH_START_TIME);
GO

-- Thêm comment cho bảng và các cột
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Bảng ghi nhật ký cập nhật dữ liệu nguồn', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SOURCE_REFRESH_LOG';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'ID của bản ghi cập nhật, khóa chính tự động tăng', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SOURCE_REFRESH_LOG',
    @level2type = N'COLUMN', @level2name = N'REFRESH_ID';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'ID của bảng nguồn, tham chiếu đến bảng MODEL_SOURCE_TABLES', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SOURCE_REFRESH_LOG',
    @level2type = N'COLUMN', @level2name = N'SOURCE_TABLE_ID';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Ngày xử lý dữ liệu', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SOURCE_REFRESH_LOG',
    @level2type = N'COLUMN', @level2name = N'PROCESS_DATE';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Thời gian bắt đầu cập nhật', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SOURCE_REFRESH_LOG',
    @level2type = N'COLUMN', @level2name = N'REFRESH_START_TIME';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Thời gian kết thúc cập nhật', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SOURCE_REFRESH_LOG',
    @level2type = N'COLUMN', @level2name = N'REFRESH_END_TIME';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Trạng thái cập nhật: STARTED (đã bắt đầu), COMPLETED (hoàn thành), FAILED (thất bại), PARTIAL (một phần)', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SOURCE_REFRESH_LOG',
    @level2type = N'COLUMN', @level2name = N'REFRESH_STATUS';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Loại cập nhật: FULL (toàn bộ), INCREMENTAL (tăng dần), DELTA (chỉ dữ liệu mới), RESTATEMENT (điều chỉnh lại)', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SOURCE_REFRESH_LOG',
    @level2type = N'COLUMN', @level2name = N'REFRESH_TYPE';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Số lượng bản ghi đã xử lý', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SOURCE_REFRESH_LOG',
    @level2type = N'COLUMN', @level2name = N'RECORDS_PROCESSED';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Thông báo lỗi nếu có', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_SOURCE_REFRESH_LOG',
    @level2type = N'COLUMN', @level2name = N'ERROR_MESSAGE';
GO

PRINT 'Bảng MODEL_SOURCE_REFRESH_LOG đã được tạo thành công';
GO