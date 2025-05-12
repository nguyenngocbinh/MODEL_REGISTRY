/*
Tên file: 09_model_validation_results.sql
Mô tả: Tạo bảng MODEL_VALIDATION_RESULTS để lưu trữ các kết quả đánh giá hiệu suất mô hình
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.1 - Cập nhật thêm trường KAPPA và các chỉ số khác theo yêu cầu
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
    KAPPA FLOAT NULL, -- Thêm chỉ số Kappa
    
    -- Chỉ số đánh giá mô hình dự báo xác suất
    BRIER_SCORE FLOAT NULL,
    LOG_LOSS FLOAT NULL,
    
    -- Chỉ số ổn định
    PSI FLOAT NULL, -- Population Stability Index
    CSI FLOAT NULL, -- Characteristic Stability Index
    
    -- Chỉ số đánh giá theo ngưỡng
    AUC_THRESHOLD_RED FLOAT DEFAULT 0.6,
    AUC_THRESHOLD_AMBER FLOAT DEFAULT 0.7,
    KS_THRESHOLD_RED FLOAT DEFAULT 0.2,
    KS_THRESHOLD_AMBER FLOAT DEFAULT 0.3,
    GINI_THRESHOLD_RED FLOAT DEFAULT 0.2,
    GINI_THRESHOLD_AMBER FLOAT DEFAULT 0.4,
    PSI_THRESHOLD_RED FLOAT DEFAULT 0.25,
    PSI_THRESHOLD_AMBER FLOAT DEFAULT 0.1,
    IV_THRESHOLD_RED FLOAT DEFAULT 0.02,
    IV_THRESHOLD_AMBER FLOAT DEFAULT 0.1,
    KAPPA_THRESHOLD_RED FLOAT DEFAULT 0.2,
    KAPPA_THRESHOLD_AMBER FLOAT DEFAULT 0.6,
    
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
    @value = N'Chỉ số Gini (0-1, càng cao càng tốt)', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS',
    @level2type = N'COLUMN', @level2name = N'GINI';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Chỉ số Population Stability Index (0-1, càng thấp càng tốt)', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS',
    @level2type = N'COLUMN', @level2name = N'PSI';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Chỉ số Information Value (0-∞, càng cao càng tốt)', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS',
    @level2type = N'COLUMN', @level2name = N'IV';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Chỉ số Kappa (0-1, càng cao càng tốt)', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS',
    @level2type = N'COLUMN', @level2name = N'KAPPA';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Ngưỡng đỏ cho AUC-ROC, AUC < giá trị này sẽ được đánh giá là Red', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS',
    @level2type = N'COLUMN', @level2name = N'AUC_THRESHOLD_RED';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Ngưỡng vàng cho AUC-ROC, AUC ≥ giá trị này sẽ được đánh giá là Green', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS',
    @level2type = N'COLUMN', @level2name = N'AUC_THRESHOLD_AMBER';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Trạng thái của báo cáo đánh giá: DRAFT, COMPLETED, APPROVED, REJECTED', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS',
    @level2type = N'COLUMN', @level2name = N'VALIDATION_STATUS';
GO

-- Tạo stored procedure để áp dụng đánh giá hiệu suất dựa trên các ngưỡng
CREATE OR ALTER PROCEDURE MODEL_REGISTRY.dbo.EVALUATE_MODEL_PERFORMANCE
    @MODEL_ID INT,
    @VALIDATION_ID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Xác thực đầu vào
    IF @MODEL_ID IS NULL
    BEGIN
        RAISERROR('MODEL_ID không được để trống', 16, 1);
        RETURN;
    END
    
    -- Lấy thông tin mô hình
    DECLARE @MODEL_NAME NVARCHAR(100);
    DECLARE @MODEL_VERSION NVARCHAR(20);
    
    SELECT 
        @MODEL_NAME = MODEL_NAME,
        @MODEL_VERSION = MODEL_VERSION
    FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY
    WHERE MODEL_ID = @MODEL_ID;
    
    IF @MODEL_NAME IS NULL
    BEGIN
        RAISERROR('Không tìm thấy mô hình với ID = %d', 16, 1, @MODEL_ID);
        RETURN;
    END
    
    -- Tạo bảng tạm để lưu kết quả đánh giá
    CREATE TABLE #ModelEvaluation (
        VALIDATION_ID INT,
        VALIDATION_DATE DATE,
        AUC_ROC FLOAT,
        AUC_RATING NVARCHAR(10),
        KS_STATISTIC FLOAT,
        KS_RATING NVARCHAR(10),
        GINI FLOAT,
        GINI_RATING NVARCHAR(10),
        PSI FLOAT,
        PSI_RATING NVARCHAR(10),
        IV FLOAT,
        IV_RATING NVARCHAR(10),
        KAPPA FLOAT,
        KAPPA_RATING NVARCHAR(10),
        OVERALL_RATING NVARCHAR(10),
        RED_COUNT INT,
        AMBER_COUNT INT,
        GREEN_COUNT INT
    );
    
    -- Lấy kết quả đánh giá và tính toán đánh giá theo các ngưỡng
    INSERT INTO #ModelEvaluation
    SELECT 
        mvr.VALIDATION_ID,
        mvr.VALIDATION_DATE,
        mvr.AUC_ROC,
        CASE 
            WHEN mvr.AUC_ROC < mvr.AUC_THRESHOLD_RED THEN 'RED'
            WHEN mvr.AUC_ROC >= mvr.AUC_THRESHOLD_RED AND mvr.AUC_ROC < mvr.AUC_THRESHOLD_AMBER THEN 'AMBER'
            WHEN mvr.AUC_ROC >= mvr.AUC_THRESHOLD_AMBER THEN 'GREEN'
            ELSE 'N/A'
        END AS AUC_RATING,
        
        mvr.KS_STATISTIC,
        CASE 
            WHEN mvr.KS_STATISTIC < mvr.KS_THRESHOLD_RED THEN 'RED'
            WHEN mvr.KS_STATISTIC >= mvr.KS_THRESHOLD_RED AND mvr.KS_STATISTIC < mvr.KS_THRESHOLD_AMBER THEN 'AMBER'
            WHEN mvr.KS_STATISTIC >= mvr.KS_THRESHOLD_AMBER THEN 'GREEN'
            ELSE 'N/A'
        END AS KS_RATING,
        
        mvr.GINI,
        CASE 
            WHEN mvr.GINI < mvr.GINI_THRESHOLD_RED THEN 'RED'
            WHEN mvr.GINI >= mvr.GINI_THRESHOLD_RED AND mvr.GINI < mvr.GINI_THRESHOLD_AMBER THEN 'AMBER'
            WHEN mvr.GINI >= mvr.GINI_THRESHOLD_AMBER THEN 'GREEN'
            ELSE 'N/A'
        END AS GINI_RATING,
        
        mvr.PSI,
        CASE 
            WHEN mvr.PSI > mvr.PSI_THRESHOLD_RED THEN 'RED'
            WHEN mvr.PSI <= mvr.PSI_THRESHOLD_RED AND mvr.PSI >= mvr.PSI_THRESHOLD_AMBER THEN 'AMBER'
            WHEN mvr.PSI < mvr.PSI_THRESHOLD_AMBER THEN 'GREEN'
            ELSE 'N/A'
        END AS PSI_RATING,
        
        mvr.IV,
        CASE 
            WHEN mvr.IV < mvr.IV_THRESHOLD_RED THEN 'RED'
            WHEN mvr.IV >= mvr.IV_THRESHOLD_RED AND mvr.IV < mvr.IV_THRESHOLD_AMBER THEN 'AMBER'
            WHEN mvr.IV >= mvr.IV_THRESHOLD_AMBER THEN 'GREEN'
            ELSE 'N/A'
        END AS IV_RATING,
        
        ISNULL(mvr.KAPPA, mvr.F1_SCORE) AS KAPPA,
        CASE 
            WHEN ISNULL(mvr.KAPPA, mvr.F1_SCORE) < mvr.KAPPA_THRESHOLD_RED THEN 'RED'
            WHEN ISNULL(mvr.KAPPA, mvr.F1_SCORE) >= mvr.KAPPA_THRESHOLD_RED AND ISNULL(mvr.KAPPA, mvr.F1_SCORE) < mvr.KAPPA_THRESHOLD_AMBER THEN 'AMBER'
            WHEN ISNULL(mvr.KAPPA, mvr.F1_SCORE) >= mvr.KAPPA_THRESHOLD_AMBER THEN 'GREEN'
            ELSE 'N/A'
        END AS KAPPA_RATING,
        
        -- Sẽ được cập nhật sau
        'PENDING' AS OVERALL_RATING,
        
        -- Đếm số lượng đánh giá Red
        CASE WHEN mvr.AUC_ROC < mvr.AUC_THRESHOLD_RED THEN 1 ELSE 0 END +
        CASE WHEN mvr.KS_STATISTIC < mvr.KS_THRESHOLD_RED THEN 1 ELSE 0 END +
        CASE WHEN mvr.GINI < mvr.GINI_THRESHOLD_RED THEN 1 ELSE 0 END +
        CASE WHEN mvr.PSI > mvr.PSI_THRESHOLD_RED THEN 1 ELSE 0 END +
        CASE WHEN mvr.IV < mvr.IV_THRESHOLD_RED THEN 1 ELSE 0 END +
        CASE WHEN ISNULL(mvr.KAPPA, mvr.F1_SCORE) < mvr.KAPPA_THRESHOLD_RED THEN 1 ELSE 0 END AS RED_COUNT,
        
        -- Đếm số lượng đánh giá Amber
        CASE WHEN mvr.AUC_ROC >= mvr.AUC_THRESHOLD_RED AND mvr.AUC_ROC < mvr.AUC_THRESHOLD_AMBER THEN 1 ELSE 0 END +
        CASE WHEN mvr.KS_STATISTIC >= mvr.KS_THRESHOLD_RED AND mvr.KS_STATISTIC < mvr.KS_THRESHOLD_AMBER THEN 1 ELSE 0 END +
        CASE WHEN mvr.GINI >= mvr.GINI_THRESHOLD_RED AND mvr.GINI < mvr.GINI_THRESHOLD_AMBER THEN 1 ELSE 0 END +
        CASE WHEN mvr.PSI <= mvr.PSI_THRESHOLD_RED AND mvr.PSI >= mvr.PSI_THRESHOLD_AMBER THEN 1 ELSE 0 END +
        CASE WHEN mvr.IV >= mvr.IV_THRESHOLD_RED AND mvr.IV < mvr.IV_THRESHOLD_AMBER THEN 1 ELSE 0 END +
        CASE WHEN ISNULL(mvr.KAPPA, mvr.F1_SCORE) >= mvr.KAPPA_THRESHOLD_RED AND ISNULL(mvr.KAPPA, mvr.F1_SCORE) < mvr.KAPPA_THRESHOLD_AMBER THEN 1 ELSE 0 END AS AMBER_COUNT,
        
        -- Đếm số lượng đánh giá Green
        CASE WHEN mvr.AUC_ROC >= mvr.AUC_THRESHOLD_AMBER THEN 1 ELSE 0 END +
        CASE WHEN mvr.KS_STATISTIC >= mvr.KS_THRESHOLD_AMBER THEN 1 ELSE 0 END +
        CASE WHEN mvr.GINI >= mvr.GINI_THRESHOLD_AMBER THEN 1 ELSE 0 END +
        CASE WHEN mvr.PSI < mvr.PSI_THRESHOLD_AMBER THEN 1 ELSE 0 END +
        CASE WHEN mvr.IV >= mvr.IV_THRESHOLD_AMBER THEN 1 ELSE 0 END +
        CASE WHEN ISNULL(mvr.KAPPA, mvr.F1_SCORE) >= mvr.KAPPA_THRESHOLD_AMBER THEN 1 ELSE 0 END AS GREEN_COUNT
    FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS mvr
    WHERE mvr.MODEL_ID = @MODEL_ID
    AND (@VALIDATION_ID IS NULL OR mvr.VALIDATION_ID = @VALIDATION_ID);
    
    -- Cập nhật đánh giá tổng thể dựa trên quy tắc mới
    UPDATE #ModelEvaluation
    SET OVERALL_RATING = 
        CASE 
            WHEN RED_COUNT > 0 THEN 'RED'
            WHEN AMBER_COUNT > 2 THEN 'RED'
            WHEN AMBER_COUNT > 0 THEN 'AMBER'
            ELSE 'GREEN'
        END;
    
    -- Hiển thị kết quả
    SELECT 
        @MODEL_NAME AS MODEL_NAME,
        @MODEL_VERSION AS MODEL_VERSION,
        me.VALIDATION_ID,
        me.VALIDATION_DATE,
        me.AUC_ROC,
        me.AUC_RATING,
        me.KS_STATISTIC,
        me.KS_RATING,
        me.GINI,
        me.GINI_RATING,
        me.PSI,
        me.PSI_RATING,
        me.IV,
        me.IV_RATING,
        me.KAPPA,
        me.KAPPA_RATING,
        me.OVERALL_RATING,
        me.RED_COUNT,
        me.AMBER_COUNT,
        me.GREEN_COUNT
    FROM #ModelEvaluation me
    ORDER BY me.VALIDATION_DATE DESC;
    
    -- Cập nhật cờ ngưỡng trong bảng MODEL_VALIDATION_RESULTS
    UPDATE mvr
    SET 
        VALIDATION_THRESHOLD_BREACHED = CASE WHEN me.OVERALL_RATING = 'RED' THEN 1 ELSE 0 END,
        UPDATED_BY = SUSER_NAME(),
        UPDATED_DATE = GETDATE()
    FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS mvr
    JOIN #ModelEvaluation me ON mvr.VALIDATION_ID = me.VALIDATION_ID
    WHERE mvr.MODEL_ID = @MODEL_ID
    AND (@VALIDATION_ID IS NULL OR mvr.VALIDATION_ID = @VALIDATION_ID);
    
    -- Dọn dẹp
    DROP TABLE #ModelEvaluation;
END;
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Đánh giá hiệu suất mô hình dựa trên các ngưỡng đã được thiết lập', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'PROCEDURE',  @level1name = N'EVALUATE_MODEL_PERFORMANCE';
GO

PRINT 'Bảng MODEL_VALIDATION_RESULTS đã được tạo thành công với các ngưỡng đánh giá mới';
GO