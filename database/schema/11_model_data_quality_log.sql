/*
Tên file: 11_model_data_quality_log.sql
Mô tả: Tạo bảng MODEL_DATA_QUALITY_LOG để ghi nhật ký các vấn đề chất lượng dữ liệu
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.0
*/

-- Kiểm tra nếu bảng đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG', 'U') IS NOT NULL
    DROP TABLE MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG;
GO

-- Tạo bảng MODEL_DATA_QUALITY_LOG
CREATE TABLE MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG (
    LOG_ID INT IDENTITY(1,1) PRIMARY KEY,
    SOURCE_TABLE_ID INT NOT NULL,
    COLUMN_ID INT NULL, -- NULL for table-level issues
    PROCESS_DATE DATE NOT NULL,
    ISSUE_TYPE NVARCHAR(50) NOT NULL, -- 'MISSING_DATA', 'OUT_OF_RANGE', 'DUPLICATE', 'INCONSISTENT', etc.
    ISSUE_DESCRIPTION NVARCHAR(MAX) NOT NULL,
    ISSUE_DETAILS NVARCHAR(MAX) NULL, -- Technical details or examples
    ISSUE_CATEGORY NVARCHAR(50) NULL, -- 'DATA_COMPLETENESS', 'DATA_ACCURACY', 'DATA_CONSISTENCY', etc.
    SEVERITY NVARCHAR(20) NOT NULL, -- 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
    RECORDS_AFFECTED INT NULL,
    PERCENTAGE_AFFECTED DECIMAL(5,2) NULL, -- Percentage of records affected
    IMPACT_DESCRIPTION NVARCHAR(MAX) NULL, -- How this impacts model performance
    DETECTION_METHOD NVARCHAR(100) NULL, -- How the issue was detected
    REMEDIATION_ACTION NVARCHAR(MAX) NULL, -- What was or will be done to fix the issue
    REMEDIATION_STATUS NVARCHAR(50) DEFAULT 'OPEN', -- 'OPEN', 'IN_PROGRESS', 'RESOLVED', 'WONTFIX'
    RESOLVED_DATE DATETIME NULL,
    RESOLVED_BY NVARCHAR(50) NULL,
    CREATED_BY NVARCHAR(50) DEFAULT SUSER_NAME(),
    CREATED_DATE DATETIME DEFAULT GETDATE(),
    UPDATED_BY NVARCHAR(50) NULL,
    UPDATED_DATE DATETIME NULL,
    FOREIGN KEY (SOURCE_TABLE_ID) REFERENCES MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES(SOURCE_TABLE_ID),
    FOREIGN KEY (COLUMN_ID) REFERENCES MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS(COLUMN_ID)
);
GO

-- Tạo chỉ mục để tăng tốc độ truy vấn
CREATE INDEX IDX_QUALITY_LOG_TABLE_ID ON MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG(SOURCE_TABLE_ID);
CREATE INDEX IDX_QUALITY_LOG_COLUMN_ID ON MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG(COLUMN_ID);
CREATE INDEX IDX_QUALITY_LOG_DATE ON MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG(PROCESS_DATE);
CREATE INDEX IDX_QUALITY_LOG_SEVERITY ON MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG(SEVERITY);
CREATE INDEX IDX_QUALITY_LOG_STATUS ON MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG(REMEDIATION_STATUS);
GO

-- Thêm comment cho bảng và các cột
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Bảng ghi nhật ký các vấn đề chất lượng dữ liệu', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_DATA_QUALITY_LOG';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'ID của bản ghi vấn đề, khóa chính tự động tăng', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_DATA_QUALITY_LOG',
    @level2type = N'COLUMN', @level2name = N'LOG_ID';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'ID của bảng nguồn, tham chiếu đến bảng MODEL_SOURCE_TABLES', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_DATA_QUALITY_LOG',
    @level2type = N'COLUMN', @level2name = N'SOURCE_TABLE_ID';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'ID của cột (NULL cho vấn đề cấp bảng), tham chiếu đến bảng MODEL_COLUMN_DETAILS', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_DATA_QUALITY_LOG',
    @level2type = N'COLUMN', @level2name = N'COLUMN_ID';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Ngày phát hiện vấn đề', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_DATA_QUALITY_LOG',
    @level2type = N'COLUMN', @level2name = N'PROCESS_DATE';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Loại vấn đề: MISSING_DATA (dữ liệu thiếu), OUT_OF_RANGE (ngoài phạm vi), DUPLICATE (trùng lặp), INCONSISTENT (không nhất quán), v.v.', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_DATA_QUALITY_LOG',
    @level2type = N'COLUMN', @level2name = N'ISSUE_TYPE';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Mô tả chi tiết về vấn đề', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_DATA_QUALITY_LOG',
    @level2type = N'COLUMN', @level2name = N'ISSUE_DESCRIPTION';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Mức độ nghiêm trọng: LOW (thấp), MEDIUM (trung bình), HIGH (cao), CRITICAL (nghiêm trọng)', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_DATA_QUALITY_LOG',
    @level2type = N'COLUMN', @level2name = N'SEVERITY';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Số lượng bản ghi bị ảnh hưởng', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_DATA_QUALITY_LOG',
    @level2type = N'COLUMN', @level2name = N'RECORDS_AFFECTED';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Mô tả tác động đến hiệu suất mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_DATA_QUALITY_LOG',
    @level2type = N'COLUMN', @level2name = N'IMPACT_DESCRIPTION';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Hành động khắc phục đã hoặc sẽ được thực hiện', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_DATA_QUALITY_LOG',
    @level2type = N'COLUMN', @level2name = N'REMEDIATION_ACTION';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Trạng thái khắc phục: OPEN (mở), IN_PROGRESS (đang xử lý), RESOLVED (đã giải quyết), WONTFIX (sẽ không sửa)', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_DATA_QUALITY_LOG',
    @level2type = N'COLUMN', @level2name = N'REMEDIATION_STATUS';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Ngày giải quyết vấn đề', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_DATA_QUALITY_LOG',
    @level2type = N'COLUMN', @level2name = N'RESOLVED_DATE';
GO

PRINT 'Bảng MODEL_DATA_QUALITY_LOG đã được tạo thành công';
GO