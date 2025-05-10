/*
Tên file: 09_model_validation_results.sql
Mô tả: Tạo bảng MODEL_VALIDATION_RESULTS để lưu trữ các kết quả đánh giá hiệu suất mô hình
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.0
*/

-- Kiểm tra nếu bảng đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS', 'U') IS NOT NULL
    DROP TABLE MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS;
GO

-- Tạo bảng MODEL_VALIDATION_RESULTS
CREATE TABLE MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS (
    VALIDATION_ID INT IDENTITY(1,1) PRIMARY KEY,
    MODEL_ID INT NOT NULL,
    VALIDATION_DATE DATE NOT NULL,
    VALIDATION_TYPE NVARCHAR(50) NOT NULL, -- 'DEVELOPMENT', 'BACKTESTING', 'OUT_OF_TIME', 'OUT_OF_SAMPLE'
    VALIDATION_PERIOD NVARCHAR(100) NULL, -- e.g., 'JAN2023-JUN2023'
    DATA_SAMPLE_SIZE INT NULL, -- Số lượng mẫu dữ liệu sử dụng trong đánh giá
    DATA_SAMPLE_DESCRIPTION NVARCHAR(255) NULL,
    
    -- Chỉ số đánh giá mô hình phân loại
    AUC_ROC FLOAT NULL,
    KS_STATISTIC FLOAT NULL,
    GINI FLOAT NULL,
    ACCURACY FLOAT NULL,
    PRECISION FLOAT NULL,
    RECALL FLOAT NULL,
    F1_SCORE FLOAT NULL,
    IV FLOAT NULL, -- Information Value
    
    -- Chỉ số đánh giá mô hình dự báo xác suất
    BRIER_SCORE FLOAT NULL,
    LOG_LOSS FLOAT NULL,
    
    -- Chỉ số ổn định
    PSI FLOAT NULL, -- Population Stability Index
    CSI FLOAT NULL, -- Characteristic Stability Index
    
    -- Chi tiết đánh giá theo phân khúc (dạng JSON)
    DETAILED_METRICS NVARCHAR(MAX) NULL, -- JSON với đánh giá chi tiết theo phân khúc
    CONFUSION_MATRIX NVARCHAR(MAX) NULL, -- JSON format
    ROC_CURVE_DATA NVARCHAR(MAX) NULL, -- JSON format
    CAP_CURVE_DATA NVARCHAR(MAX) NULL, -- JSON format
    CALIBRATION_CURVE NVARCHAR(MAX) NULL, -- JSON format
    
    -- Thông tin quản lý
    VALIDATION_COMMENTS NVARCHAR(MAX) NULL,
    VALIDATION_STATUS NVARCHAR(20) DEFAULT 'DRAFT', -- 'DRAFT', 'COMPLETED', 'APPROVED', 'REJECTED'
    VALIDATION_THRESHOLD_BREACHED BIT DEFAULT 0, -- Cờ đánh dấu nếu có chỉ số vượt ngưỡng cảnh báo
    VALIDATED_BY NVARCHAR(100) NULL,
    APPROVED_BY NVARCHAR(100) NULL,
    APPROVED_DATE DATETIME NULL,
    CREATED_DATE DATETIME DEFAULT GETDATE(),
    CREATED_BY NVARCHAR(50) DEFAULT SUSER_NAME(),
    UPDATED_DATE DATETIME NULL,
    UPDATED_BY NVARCHAR(50) NULL,
    
    -- Ràng buộc khóa ngoại
    FOREIGN KEY (MODEL_ID) REFERENCES MODEL_REGISTRY.dbo.MODEL_REGISTRY(MODEL_ID)
);
GO

-- Tạo chỉ mục cho hiệu suất truy vấn
CREATE INDEX IDX_MODEL_VALIDATION_MODEL_ID ON MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS (MODEL_ID);
CREATE INDEX IDX_MODEL_VALIDATION_DATE ON MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS (VALIDATION_DATE);
CREATE INDEX IDX_MODEL_VALIDATION_TYPE ON MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS (VALIDATION_TYPE);
CREATE INDEX IDX_MODEL_VALIDATION_STATUS ON MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS (VALIDATION_STATUS);
GO

-- Thêm comment cho bảng và các cột
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Bảng lưu trữ kết quả đánh giá hiệu suất của các mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'ID của kết quả đánh giá, khóa chính tự động tăng', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS',
    @level2type = N'COLUMN', @level2name = N'VALIDATION_ID';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'ID mô hình được đánh giá, tham chiếu đến MODEL_REGISTRY', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS',
    @level2type = N'COLUMN', @level2name = N'MODEL_ID';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Ngày thực hiện đánh giá', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS',
    @level2type = N'COLUMN', @level2name = N'VALIDATION_DATE';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Loại đánh giá: DEVELOPMENT (phát triển), BACKTESTING, OUT_OF_TIME, OUT_OF_SAMPLE', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS',
    @level2type = N'COLUMN', @level2name = N'VALIDATION_TYPE';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Diện tích dưới đường cong ROC (0-1, càng cao càng tốt)', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS',
    @level2type = N'COLUMN', @level2name = N'AUC_ROC';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Chỉ số Kolmogorov-Smirnov (0-1, càng cao càng tốt)', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS',
    @level2type = N'COLUMN', @level2name = N'KS_STATISTIC';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Chỉ số Population Stability Index (0-1, càng thấp càng tốt)', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS',
    @level2type = N'COLUMN', @level2name = N'PSI';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Trạng thái của báo cáo đánh giá: DRAFT, COMPLETED, APPROVED, REJECTED', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS',
    @level2type = N'COLUMN', @level2name = N'VALIDATION_STATUS';
GO

PRINT 'Bảng MODEL_VALIDATION_RESULTS đã được tạo thành công';
GO/*
Tên file: 09_model_validation_results.sql
Mô tả: Tạo bảng MODEL_VALIDATION_RESULTS để lưu trữ các kết quả đánh giá hiệu suất mô hình
Tác giả: 
Ngày tạo: 2025-05-10
Phiên bản: 1.0
*/

-- Kiểm tra nếu bảng đã tồn tại thì xóa
IF OBJECT_ID('EWS.dbo.MODEL_VALIDATION_RESULTS', 'U') IS NOT NULL
    DROP TABLE EWS.dbo.MODEL_VALIDATION_RESULTS;
GO

-- Tạo bảng MODEL_VALIDATION_RESULTS
CREATE TABLE EWS.dbo.MODEL_VALIDATION_RESULTS (
    VALIDATION_ID INT IDENTITY(1,1) PRIMARY KEY,
    MODEL_ID INT NOT NULL,
    VALIDATION_DATE DATE NOT NULL,
    VALIDATION_TYPE NVARCHAR(50) NOT NULL, -- 'DEVELOPMENT', 'BACKTESTING', 'OUT_OF_TIME', 'OUT_OF_SAMPLE'
    VALIDATION_PERIOD NVARCHAR(100) NULL, -- e.g., 'JAN2023-JUN2023'
    DATA_SAMPLE_SIZE INT NULL, -- Số lượng mẫu dữ liệu sử dụng trong đánh giá
    DATA_SAMPLE_DESCRIPTION NVARCHAR(255) NULL,
    
    -- Chỉ số đánh giá mô hình phân loại
    AUC_ROC FLOAT NULL,
    KS_STATISTIC FLOAT NULL,
    GINI FLOAT NULL,
    ACCURACY FLOAT NULL,
    PRECISION FLOAT NULL,
    RECALL FLOAT NULL,
    F1_SCORE FLOAT NULL,
    IV FLOAT NULL, -- Information Value
    
    -- Chỉ số đánh giá mô hình dự báo xác suất
    BRIER_SCORE FLOAT NULL,
    LOG_LOSS FLOAT NULL,
    
    -- Chỉ số ổn định
    PSI FLOAT NULL, -- Population Stability Index
    CSI FLOAT NULL, -- Characteristic Stability Index
    
    -- Chi tiết đánh giá theo phân khúc (dạng JSON)
    DETAILED_METRICS NVARCHAR(MAX) NULL, -- JSON với đánh giá chi tiết theo phân khúc
    CONFUSION_MATRIX NVARCHAR(MAX) NULL, -- JSON format
    ROC_CURVE_DATA NVARCHAR(MAX) NULL, -- JSON format
    CAP_CURVE_DATA NVARCHAR(MAX) NULL, -- JSON format
    CALIBRATION_CURVE NVARCHAR(MAX) NULL, -- JSON format
    
    -- Thông tin quản lý
    VALIDATION_COMMENTS NVARCHAR(MAX) NULL,
    VALIDATION_STATUS NVARCHAR(20) DEFAULT 'DRAFT', -- 'DRAFT', 'COMPLETED', 'APPROVED', 'REJECTED'
    VALIDATION_THRESHOLD_BREACHED BIT DEFAULT 0, -- Cờ đánh dấu nếu có chỉ số vượt ngưỡng cảnh báo
    VALIDATED_BY NVARCHAR(100) NULL,
    APPROVED_BY NVARCHAR(100) NULL,
    APPROVED_DATE DATETIME NULL,
    CREATED_DATE DATETIME DEFAULT GETDATE(),
    CREATED_BY NVARCHAR(50) DEFAULT SUSER_NAME(),
    UPDATED_DATE DATETIME NULL,
    UPDATED_BY NVARCHAR(50) NULL,
    
    -- Ràng buộc khóa ngoại
    FOREIGN KEY (MODEL_ID) REFERENCES EWS.dbo.MODEL_REGISTRY(MODEL_ID)
);
GO

-- Tạo chỉ mục cho hiệu suất truy vấn
CREATE INDEX IDX_MODEL_VALIDATION_MODEL_ID ON EWS.dbo.MODEL_VALIDATION_RESULTS (MODEL_ID);
CREATE INDEX IDX_MODEL_VALIDATION_DATE ON EWS.dbo.MODEL_VALIDATION_RESULTS (VALIDATION_DATE);
CREATE INDEX IDX_MODEL_VALIDATION_TYPE ON EWS.dbo.MODEL_VALIDATION_RESULTS (VALIDATION_TYPE);
CREATE INDEX IDX_MODEL_VALIDATION_STATUS ON EWS.dbo.MODEL_VALIDATION_RESULTS (VALIDATION_STATUS);
GO

-- Thêm comment cho bảng và các cột
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Bảng lưu trữ kết quả đánh giá hiệu suất của các mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'ID của kết quả đánh giá, khóa chính tự động tăng', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS',
    @level2type = N'COLUMN', @level2name = N'VALIDATION_ID';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'ID mô hình được đánh giá, tham chiếu đến MODEL_REGISTRY', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS',
    @level2type = N'COLUMN', @level2name = N'MODEL_ID';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Ngày thực hiện đánh giá', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS',
    @level2type = N'COLUMN', @level2name = N'VALIDATION_DATE';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Loại đánh giá: DEVELOPMENT (phát triển), BACKTESTING, OUT_OF_TIME, OUT_OF_SAMPLE', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS',
    @level2type = N'COLUMN', @level2name = N'VALIDATION_TYPE';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Diện tích dưới đường cong ROC (0-1, càng cao càng tốt)', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS',
    @level2type = N'COLUMN', @level2name = N'AUC_ROC';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Chỉ số Kolmogorov-Smirnov (0-1, càng cao càng tốt)', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS',
    @level2type = N'COLUMN', @level2name = N'KS_STATISTIC';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Chỉ số Population Stability Index (0-1, càng thấp càng tốt)', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS',
    @level2type = N'COLUMN', @level2name = N'PSI';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Trạng thái của báo cáo đánh giá: DRAFT, COMPLETED, APPROVED, REJECTED', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS',
    @level2type = N'COLUMN', @level2name = N'VALIDATION_STATUS';
GO

PRINT 'Bảng MODEL_VALIDATION_RESULTS đã được tạo thành công';
GO