/*
Tên file: 15_feature_values.sql
Mô tả: Tạo bảng FEATURE_VALUES để lưu trữ các giá trị và phân phối của đặc trưng
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
IF OBJECT_ID('MODEL_REGISTRY.dbo.FEATURE_VALUES', 'U') IS NOT NULL
    DROP TABLE MODEL_REGISTRY.dbo.FEATURE_VALUES;
GO

-- Tạo bảng FEATURE_VALUES
CREATE TABLE MODEL_REGISTRY.dbo.FEATURE_VALUES (
    VALUE_ID INT IDENTITY(1,1) PRIMARY KEY,
    FEATURE_ID INT NOT NULL,
    SEGMENT_ID INT NULL, -- Optional reference to a customer segment (NULL for overall values)
    VALUE_TYPE NVARCHAR(50) NOT NULL, -- 'CATEGORICAL', 'NUMERIC_RANGE', 'NUMERIC_BUCKET', 'DATE_RANGE'
    VALUE_LABEL NVARCHAR(100) NOT NULL, -- Display name for this value or range
    VALUE_CODE NVARCHAR(50) NULL, -- Shortcode for the value/bucket
    VALUE_DESCRIPTION NVARCHAR(500) NULL,
    MIN_VALUE NVARCHAR(100) NULL, -- Min value for a range (stored as string for flexibility)
    MAX_VALUE NVARCHAR(100) NULL, -- Max value for a range
    FREQUENCY FLOAT NULL, -- Percentage of records with this value (0-1)
    RECORD_COUNT INT NULL, -- Absolute count of records with this value
    MEAN_FOR_RANGE FLOAT NULL, -- Mean value within this range (for numeric)
    MEDIAN_FOR_RANGE FLOAT NULL, -- Median value within this range (for numeric)
    EXAMPLE_VALUES NVARCHAR(MAX) NULL, -- JSON array of example values
    WOE FLOAT NULL, -- Weight of Evidence for this value/bin
    IV_CONTRIBUTION FLOAT NULL, -- Information Value contribution from this bin
    EVENT_RATE FLOAT NULL, -- Target event rate for this value/bin
    TARGET_CORRELATION FLOAT NULL, -- Correlation with target variable
    IS_OUTLIER BIT DEFAULT 0, -- Flag if this value/bin is considered an outlier
    BUCKET_ORDER INT NULL, -- Order for display of buckets
    CREATED_BY NVARCHAR(50) DEFAULT SUSER_NAME(),
    CREATED_DATE DATETIME DEFAULT GETDATE(),
    UPDATED_BY NVARCHAR(50) NULL,
    UPDATED_DATE DATETIME NULL,
    IS_ACTIVE BIT DEFAULT 1,
    EFF_DATE DATE DEFAULT GETDATE(),
    EXP_DATE DATE DEFAULT '9999-12-31',
    FOREIGN KEY (FEATURE_ID) REFERENCES MODEL_REGISTRY.dbo.FEATURE_REGISTRY(FEATURE_ID)
);
GO

-- Tạo chỉ mục để tăng tốc độ truy vấn
CREATE INDEX IDX_FEATURE_VALUES_FEATURE_ID ON MODEL_REGISTRY.dbo.FEATURE_VALUES(FEATURE_ID);
CREATE INDEX IDX_FEATURE_VALUES_SEGMENT_ID ON MODEL_REGISTRY.dbo.FEATURE_VALUES(SEGMENT_ID) WHERE SEGMENT_ID IS NOT NULL;
CREATE INDEX IDX_FEATURE_VALUES_TYPE ON MODEL_REGISTRY.dbo.FEATURE_VALUES(VALUE_TYPE);
CREATE INDEX IDX_FEATURE_VALUES_DATES ON MODEL_REGISTRY.dbo.FEATURE_VALUES(EFF_DATE, EXP_DATE);
GO

-- Thêm comment cho bảng và các cột
BEGIN TRY
    -- Thêm comment cho bảng
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Bảng lưu trữ các giá trị và phân phối của đặc trưng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_VALUES';

    -- Thêm comment cho cột VALUE_ID
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'ID của giá trị đặc trưng, khóa chính tự động tăng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_VALUES',
        @level2type = N'COLUMN', @level2name = N'VALUE_ID';

    -- Thêm comment cho cột FEATURE_ID
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'ID của đặc trưng, tham chiếu đến bảng FEATURE_REGISTRY', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_VALUES',
        @level2type = N'COLUMN', @level2name = N'FEATURE_ID';

    -- Thêm comment cho cột SEGMENT_ID
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'ID phân khúc khách hàng (NULL cho giá trị tổng thể)', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_VALUES',
        @level2type = N'COLUMN', @level2name = N'SEGMENT_ID';

    -- Thêm comment cho cột VALUE_TYPE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Loại giá trị: CATEGORICAL (phân loại), NUMERIC_RANGE (phạm vi số), NUMERIC_BUCKET (nhóm số), DATE_RANGE (phạm vi ngày)', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_VALUES',
        @level2type = N'COLUMN', @level2name = N'VALUE_TYPE';

    -- Thêm comment cho cột VALUE_LABEL
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Nhãn hiển thị cho giá trị hoặc phạm vi này', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_VALUES',
        @level2type = N'COLUMN', @level2name = N'VALUE_LABEL';

    -- Thêm comment cho cột VALUE_CODE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Mã ngắn cho giá trị/nhóm', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_VALUES',
        @level2type = N'COLUMN', @level2name = N'VALUE_CODE';

    -- Thêm comment cho cột MIN_VALUE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Giá trị tối thiểu cho một phạm vi (lưu dưới dạng chuỗi để linh hoạt)', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_VALUES',
        @level2type = N'COLUMN', @level2name = N'MIN_VALUE';

    -- Thêm comment cho cột MAX_VALUE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Giá trị tối đa cho một phạm vi', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_VALUES',
        @level2type = N'COLUMN', @level2name = N'MAX_VALUE';

    -- Thêm comment cho cột FREQUENCY
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Tần suất xuất hiện của giá trị này (0-1)', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_VALUES',
        @level2type = N'COLUMN', @level2name = N'FREQUENCY';

    -- Thêm comment cho cột RECORD_COUNT
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Số lượng bản ghi tuyệt đối có giá trị này', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_VALUES',
        @level2type = N'COLUMN', @level2name = N'RECORD_COUNT';

    -- Thêm comment cho cột WOE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Weight of Evidence (Trọng số bằng chứng) cho giá trị/nhóm này', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_VALUES',
        @level2type = N'COLUMN', @level2name = N'WOE';

    -- Thêm comment cho cột IV_CONTRIBUTION
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Đóng góp Information Value từ nhóm này', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_VALUES',
        @level2type = N'COLUMN', @level2name = N'IV_CONTRIBUTION';

    -- Thêm comment cho cột EVENT_RATE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Tỷ lệ sự kiện mục tiêu cho giá trị/nhóm này', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_VALUES',
        @level2type = N'COLUMN', @level2name = N'EVENT_RATE';

    -- Thêm comment cho cột IS_OUTLIER
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Cờ đánh dấu nếu giá trị/nhóm này được coi là ngoại lệ', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_VALUES',
        @level2type = N'COLUMN', @level2name = N'IS_OUTLIER';

    -- Thêm comment cho cột BUCKET_ORDER
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Thứ tự hiển thị của các nhóm', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_VALUES',
        @level2type = N'COLUMN', @level2name = N'BUCKET_ORDER';

    PRINT N'Các extended properties đã được thêm thành công';
END TRY
BEGIN CATCH
    PRINT N'Cảnh báo: Không thể thêm extended properties. Error: ' + ERROR_MESSAGE();
    PRINT N'Quá trình tạo bảng vẫn thành công.';
END CATCH
GO

PRINT N'Bảng FEATURE_VALUES đã được tạo thành công';
GO