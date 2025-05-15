/*
Tên file: 19_feature_refresh_log.sql
Mô tả: Tạo bảng FEATURE_REFRESH_LOG để ghi nhật ký quá trình cập nhật và tính toán lại các đặc trưng
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
IF OBJECT_ID('MODEL_REGISTRY.dbo.FEATURE_REFRESH_LOG', 'U') IS NOT NULL
    DROP TABLE MODEL_REGISTRY.dbo.FEATURE_REFRESH_LOG;
GO

-- Tạo bảng FEATURE_REFRESH_LOG
CREATE TABLE MODEL_REGISTRY.dbo.FEATURE_REFRESH_LOG (
    LOG_ID INT IDENTITY(1,1) PRIMARY KEY,
    FEATURE_ID INT NULL, -- NULL when refreshing multiple features in a batch
    REFRESH_BATCH_ID NVARCHAR(50) NULL, -- Identifier for batch operations
    REFRESH_TYPE NVARCHAR(50) NOT NULL, -- 'CALCULATION', 'RECALIBRATION', 'VALIDATION', 'PERIODIC'
    REFRESH_START_TIME DATETIME NOT NULL DEFAULT GETDATE(),
    REFRESH_END_TIME DATETIME NULL,
    REFRESH_STATUS NVARCHAR(20) NOT NULL DEFAULT 'STARTED', -- 'STARTED', 'COMPLETED', 'FAILED', 'PARTIAL'
    AFFECTED_RECORDS INT NULL, -- Number of records affected
    SOURCE_DATA_START_DATE DATE NULL, -- Start date of source data period
    SOURCE_DATA_END_DATE DATE NULL, -- End date of source data period
    REFRESH_SQL NVARCHAR(MAX) NULL, -- SQL used for refresh operation
    ERROR_MESSAGE NVARCHAR(MAX) NULL, -- Error message if failed
    ERROR_DETAILS NVARCHAR(MAX) NULL, -- Detailed error information
    PERFORMANCE_METRICS NVARCHAR(MAX) NULL, -- JSON with performance metrics
    FEATURE_OLD_STATS NVARCHAR(MAX) NULL, -- JSON with old feature statistics
    FEATURE_NEW_STATS NVARCHAR(MAX) NULL, -- JSON with new feature statistics
    REFRESH_REASON NVARCHAR(500) NULL, -- Reason for refresh (e.g., scheduled, drift detected)
    REFRESH_TRIGGERED_BY NVARCHAR(100) NULL, -- User, system, or process that triggered refresh
    ENVIRONMENT NVARCHAR(50) NULL, -- 'DEV', 'TEST', 'PROD'
    SUCCESS_VALIDATION_FLAG BIT NULL, -- Whether validation was successful after refresh
    VALIDATION_DETAILS NVARCHAR(MAX) NULL, -- Details of validation after refresh
    CREATED_BY NVARCHAR(50) DEFAULT SUSER_NAME(),
    CREATED_DATE DATETIME DEFAULT GETDATE(),
    UPDATED_BY NVARCHAR(50) NULL,
    UPDATED_DATE DATETIME NULL,
    FOREIGN KEY (FEATURE_ID) REFERENCES MODEL_REGISTRY.dbo.FEATURE_REGISTRY(FEATURE_ID)
);
GO

-- Tạo chỉ mục để tăng tốc độ truy vấn
CREATE INDEX IDX_FEATURE_REFRESH_FEATURE_ID ON MODEL_REGISTRY.dbo.FEATURE_REFRESH_LOG(FEATURE_ID) WHERE FEATURE_ID IS NOT NULL;
CREATE INDEX IDX_FEATURE_REFRESH_BATCH_ID ON MODEL_REGISTRY.dbo.FEATURE_REFRESH_LOG(REFRESH_BATCH_ID) WHERE REFRESH_BATCH_ID IS NOT NULL;
CREATE INDEX IDX_FEATURE_REFRESH_TYPE ON MODEL_REGISTRY.dbo.FEATURE_REFRESH_LOG(REFRESH_TYPE);
CREATE INDEX IDX_FEATURE_REFRESH_STATUS ON MODEL_REGISTRY.dbo.FEATURE_REFRESH_LOG(REFRESH_STATUS);
CREATE INDEX IDX_FEATURE_REFRESH_DATES ON MODEL_REGISTRY.dbo.FEATURE_REFRESH_LOG(REFRESH_START_TIME, REFRESH_END_TIME);
GO

-- Thêm comment cho bảng và các cột
BEGIN TRY
    -- Thêm comment cho bảng
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Bảng ghi nhật ký quá trình cập nhật và tính toán lại các đặc trưng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REFRESH_LOG';

    -- Thêm comment cho cột LOG_ID
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'ID của bản ghi nhật ký, khóa chính tự động tăng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REFRESH_LOG',
        @level2type = N'COLUMN', @level2name = N'LOG_ID';

    -- Thêm comment cho cột FEATURE_ID
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'ID của đặc trưng, tham chiếu đến bảng FEATURE_REGISTRY (NULL khi làm mới nhiều đặc trưng trong một lô)', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REFRESH_LOG',
        @level2type = N'COLUMN', @level2name = N'FEATURE_ID';

    -- Thêm comment cho cột REFRESH_BATCH_ID
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Định danh cho các hoạt động theo lô', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REFRESH_LOG',
        @level2type = N'COLUMN', @level2name = N'REFRESH_BATCH_ID';

    -- Thêm comment cho cột REFRESH_TYPE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Loại làm mới: CALCULATION (tính toán), RECALIBRATION (hiệu chỉnh lại), VALIDATION (xác thực), PERIODIC (định kỳ)', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REFRESH_LOG',
        @level2type = N'COLUMN', @level2name = N'REFRESH_TYPE';

    -- Thêm comment cho cột REFRESH_START_TIME
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Thời gian bắt đầu làm mới', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REFRESH_LOG',
        @level2type = N'COLUMN', @level2name = N'REFRESH_START_TIME';

    -- Thêm comment cho cột REFRESH_END_TIME
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Thời gian kết thúc làm mới', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REFRESH_LOG',
        @level2type = N'COLUMN', @level2name = N'REFRESH_END_TIME';

    -- Thêm comment cho cột REFRESH_STATUS
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Trạng thái làm mới: STARTED (đã bắt đầu), COMPLETED (hoàn thành), FAILED (thất bại), PARTIAL (một phần)', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REFRESH_LOG',
        @level2type = N'COLUMN', @level2name = N'REFRESH_STATUS';

    -- Thêm comment cho cột AFFECTED_RECORDS
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Số lượng bản ghi bị ảnh hưởng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REFRESH_LOG',
        @level2type = N'COLUMN', @level2name = N'AFFECTED_RECORDS';

    -- Thêm comment cho cột SOURCE_DATA_START_DATE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Ngày bắt đầu của khoảng thời gian dữ liệu nguồn', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REFRESH_LOG',
        @level2type = N'COLUMN', @level2name = N'SOURCE_DATA_START_DATE';

    -- Thêm comment cho cột SOURCE_DATA_END_DATE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Ngày kết thúc của khoảng thời gian dữ liệu nguồn', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REFRESH_LOG',
        @level2type = N'COLUMN', @level2name = N'SOURCE_DATA_END_DATE';

    -- Thêm comment cho cột REFRESH_SQL
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'SQL được sử dụng cho hoạt động làm mới', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REFRESH_LOG',
        @level2type = N'COLUMN', @level2name = N'REFRESH_SQL';

    -- Thêm comment cho cột ERROR_MESSAGE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Thông báo lỗi nếu thất bại', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REFRESH_LOG',
        @level2type = N'COLUMN', @level2name = N'ERROR_MESSAGE';

    -- Thêm comment cho cột FEATURE_OLD_STATS
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'JSON với thống kê đặc trưng cũ', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REFRESH_LOG',
        @level2type = N'COLUMN', @level2name = N'FEATURE_OLD_STATS';

    -- Thêm comment cho cột FEATURE_NEW_STATS
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'JSON với thống kê đặc trưng mới', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REFRESH_LOG',
        @level2type = N'COLUMN', @level2name = N'FEATURE_NEW_STATS';

    -- Thêm comment cho cột REFRESH_REASON
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Lý do làm mới (ví dụ: theo lịch trình, phát hiện sai lệch)', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REFRESH_LOG',
        @level2type = N'COLUMN', @level2name = N'REFRESH_REASON';

    -- Thêm comment cho cột ENVIRONMENT
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Môi trường: DEV (phát triển), TEST (kiểm thử), PROD (sản xuất)', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REFRESH_LOG',
        @level2type = N'COLUMN', @level2name = N'ENVIRONMENT';

    PRINT N'Các extended properties đã được thêm thành công';
END TRY
BEGIN CATCH
    PRINT N'Cảnh báo: Không thể thêm extended properties. Error: ' + ERROR_MESSAGE();
    PRINT N'Quá trình tạo bảng vẫn thành công.';
END CATCH
GO

PRINT N'Bảng FEATURE_REFRESH_LOG đã được tạo thành công';
GO