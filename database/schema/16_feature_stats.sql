/*
Tên file: 16_feature_stats.sql
Mô tả: Tạo bảng FEATURE_STATS để lưu trữ thống kê về các đặc trưng
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
IF OBJECT_ID('MODEL_REGISTRY.dbo.FEATURE_STATS', 'U') IS NOT NULL
    DROP TABLE MODEL_REGISTRY.dbo.FEATURE_STATS;
GO

-- Tạo bảng FEATURE_STATS
CREATE TABLE MODEL_REGISTRY.dbo.FEATURE_STATS (
    STATS_ID INT IDENTITY(1,1) PRIMARY KEY,
    FEATURE_ID INT NOT NULL,
    SEGMENT_ID INT NULL, -- Optional reference to a segment (NULL for overall statistics)
    CALCULATION_DATE DATE NOT NULL DEFAULT GETDATE(),
    SAMPLE_SIZE INT NOT NULL, -- Number of records used in calculation
    SAMPLE_PERIOD_START DATE NULL, -- Start date of data sample used
    SAMPLE_PERIOD_END DATE NULL, -- End date of data sample used
    
    -- Thống kê cho đặc trưng số
    MIN_VALUE FLOAT NULL,
    MAX_VALUE FLOAT NULL,
    MEAN FLOAT NULL,
    MEDIAN FLOAT NULL,
    MODE NVARCHAR(100) NULL, -- Mode can be for categorical or numeric
    STD_DEVIATION FLOAT NULL,
    VARIANCE FLOAT NULL,
    SKEWNESS FLOAT NULL,
    KURTOSIS FLOAT NULL,
    PERCENTILE_25 FLOAT NULL,
    PERCENTILE_75 FLOAT NULL,
    PERCENTILE_95 FLOAT NULL,
    
    -- Thống kê cho đặc trưng phân loại
    UNIQUE_VALUES INT NULL, -- Number of distinct values
    TOP_VALUE NVARCHAR(100) NULL, -- Most common value
    TOP_VALUE_FREQ FLOAT NULL, -- Frequency of most common value (0-1)
    ENTROPY FLOAT NULL, -- Information entropy of distribution
    
    -- Các chỉ số đánh giá phổ biến
    MISSING_RATIO FLOAT NULL, -- Ratio of missing values (0-1)
    INFORMATION_VALUE FLOAT NULL, -- IV relative to target
    GINI_COEFFICIENT FLOAT NULL, -- Measure of inequality in distribution
    STABILITY_INDEX FLOAT NULL, -- PSI - Population Stability Index
    TARGET_CORRELATION FLOAT NULL, -- Correlation with target variable
    
    -- Thông tin kiểm định thống kê
    CHI_SQUARE_VALUE FLOAT NULL, -- For categorical features 
    CHI_SQUARE_P_VALUE FLOAT NULL,
    KOLMOGOROV_SMIRNOV FLOAT NULL, -- K-S statistic
    KS_P_VALUE FLOAT NULL,
    
    -- Cờ cảnh báo
    HAS_OUTLIERS BIT DEFAULT 0,
    HIGH_CARDINALITY BIT DEFAULT 0, -- Flag for too many unique values
    LOW_VARIANCE BIT DEFAULT 0, -- Flag for near-constant features
    
    DATA_SCHEMA_VERSION NVARCHAR(20) NULL, -- Version of feature schema used
    STATS_CALCULATION_METHOD NVARCHAR(50) NULL, -- Method used to calculate statistics
    CREATED_BY NVARCHAR(50) DEFAULT SUSER_NAME(),
    CREATED_DATE DATETIME DEFAULT GETDATE(),
    UPDATED_BY NVARCHAR(50) NULL,
    UPDATED_DATE DATETIME NULL,
    IS_ACTIVE BIT DEFAULT 1,
    FOREIGN KEY (FEATURE_ID) REFERENCES MODEL_REGISTRY.dbo.FEATURE_REGISTRY(FEATURE_ID)
);
GO

-- Tạo chỉ mục để tăng tốc độ truy vấn
CREATE INDEX IDX_FEATURE_STATS_FEATURE_ID ON MODEL_REGISTRY.dbo.FEATURE_STATS(FEATURE_ID);
CREATE INDEX IDX_FEATURE_STATS_SEGMENT_ID ON MODEL_REGISTRY.dbo.FEATURE_STATS(SEGMENT_ID) WHERE SEGMENT_ID IS NOT NULL;
CREATE INDEX IDX_FEATURE_STATS_DATE ON MODEL_REGISTRY.dbo.FEATURE_STATS(CALCULATION_DATE);
CREATE INDEX IDX_FEATURE_STATS_ACTIVE ON MODEL_REGISTRY.dbo.FEATURE_STATS(IS_ACTIVE);
GO

-- Thêm comment cho bảng và các cột
BEGIN TRY
    -- Thêm comment cho bảng
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Bảng lưu trữ thống kê về các đặc trưng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_STATS';

    -- Thêm comment cho cột STATS_ID
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'ID của bản ghi thống kê, khóa chính tự động tăng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_STATS',
        @level2type = N'COLUMN', @level2name = N'STATS_ID';

    -- Thêm comment cho cột FEATURE_ID
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'ID của đặc trưng, tham chiếu đến bảng FEATURE_REGISTRY', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_STATS',
        @level2type = N'COLUMN', @level2name = N'FEATURE_ID';

    -- Thêm comment cho cột SEGMENT_ID
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'ID của phân khúc (NULL cho thống kê tổng thể)', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_STATS',
        @level2type = N'COLUMN', @level2name = N'SEGMENT_ID';

    -- Thêm comment cho cột CALCULATION_DATE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Ngày tính toán thống kê', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_STATS',
        @level2type = N'COLUMN', @level2name = N'CALCULATION_DATE';

    -- Thêm comment cho cột SAMPLE_SIZE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Số lượng bản ghi được sử dụng trong tính toán', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_STATS',
        @level2type = N'COLUMN', @level2name = N'SAMPLE_SIZE';

    -- Thêm comment cho cột MIN_VALUE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Giá trị nhỏ nhất của đặc trưng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_STATS',
        @level2type = N'COLUMN', @level2name = N'MIN_VALUE';

    -- Thêm comment cho cột MAX_VALUE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Giá trị lớn nhất của đặc trưng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_STATS',
        @level2type = N'COLUMN', @level2name = N'MAX_VALUE';

    -- Thêm comment cho cột MEAN
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Giá trị trung bình của đặc trưng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_STATS',
        @level2type = N'COLUMN', @level2name = N'MEAN';

    -- Thêm comment cho cột MEDIAN
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Giá trị trung vị của đặc trưng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_STATS',
        @level2type = N'COLUMN', @level2name = N'MEDIAN';

    -- Thêm comment cho cột MODE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Giá trị phổ biến nhất của đặc trưng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_STATS',
        @level2type = N'COLUMN', @level2name = N'MODE';

    -- Thêm comment cho cột STD_DEVIATION
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Độ lệch chuẩn của đặc trưng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_STATS',
        @level2type = N'COLUMN', @level2name = N'STD_DEVIATION';

    -- Thêm comment cho cột MISSING_RATIO
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Tỷ lệ giá trị bị thiếu (0-1)', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_STATS',
        @level2type = N'COLUMN', @level2name = N'MISSING_RATIO';

    -- Thêm comment cho cột INFORMATION_VALUE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Chỉ số Information Value so với biến mục tiêu', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_STATS',
        @level2type = N'COLUMN', @level2name = N'INFORMATION_VALUE';

    -- Thêm comment cho cột STABILITY_INDEX
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Chỉ số Population Stability Index (PSI)', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_STATS',
        @level2type = N'COLUMN', @level2name = N'STABILITY_INDEX';

    -- Thêm comment cho cột TARGET_CORRELATION
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Tương quan với biến mục tiêu', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_STATS',
        @level2type = N'COLUMN', @level2name = N'TARGET_CORRELATION';

    PRINT N'Các extended properties đã được thêm thành công';
END TRY
BEGIN CATCH
    PRINT N'Cảnh báo: Không thể thêm extended properties. Error: ' + ERROR_MESSAGE();
    PRINT N'Quá trình tạo bảng vẫn thành công.';
END CATCH
GO

PRINT N'Bảng FEATURE_STATS đã được tạo thành công';
GO