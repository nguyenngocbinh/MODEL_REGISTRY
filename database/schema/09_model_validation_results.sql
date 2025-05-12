/*
Tên file: 09_model_validation_results.sql
Mô tả: Tạo bảng MODEL_VALIDATION_RESULTS để lưu trữ các kết quả đánh giá hiệu suất mô hình
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.2 - Cập nhật thêm điều chỉnh loại bỏ AUC_ROC, cập nhật ngưỡng GINI và sử dụng chỉ KAPPA
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
    MODEL_SUBTYPE NVARCHAR(50) NULL, -- 'Retail AScore (without Bureau)', 'Retail AScore (with Bureau)', 'Retail BScore', 'Wholesale Scorecard'
    
    -- Chỉ số đánh giá mô hình phân loại
    -- AUC_ROC đã được loại bỏ
    KS_STATISTIC FLOAT NULL,
    GINI FLOAT NULL,
    ACCURACY FLOAT NULL,
    PRECISION FLOAT NULL,
    RECALL FLOAT NULL,
    F1_SCORE FLOAT NULL,
    IV FLOAT NULL, -- Information Value
    KAPPA FLOAT NULL, -- Kappa coefficient
    
    -- Chỉ số đánh giá mô hình dự báo xác suất
    BRIER_SCORE FLOAT NULL,
    LOG_LOSS FLOAT NULL,
    
    -- Chỉ số ổn định
    PSI FLOAT NULL, -- Population Stability Index
    CSI FLOAT NULL, -- Characteristic Stability Index
    
    -- Chỉ số đánh giá theo ngưỡng
    -- AUC_THRESHOLD_RED và AUC_THRESHOLD_AMBER đã được loại bỏ
    KS_THRESHOLD_RED FLOAT DEFAULT 0.2,
    KS_THRESHOLD_AMBER FLOAT DEFAULT 0.3,
    
    -- Ngưỡng GINI được mặc định theo model_subtype
    GINI_THRESHOLD_RED FLOAT DEFAULT 0.2,
    GINI_THRESHOLD_AMBER FLOAT DEFAULT 0.25,
    
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
    @value = N'Phân loại mô hình con: Retail AScore (with/without Bureau), Retail BScore, Wholesale Scorecard', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS',
    @level2type = N'COLUMN', @level2name = N'MODEL_SUBTYPE';
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
    @value = N'Ngưỡng đỏ cho GINI, GINI < giá trị này sẽ được đánh giá là Red', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS',
    @level2type = N'COLUMN', @level2name = N'GINI_THRESHOLD_RED';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Ngưỡng vàng cho GINI, GINI ≥ giá trị này sẽ được đánh giá là Green', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_VALIDATION_RESULTS',
    @level2type = N'COLUMN', @level2name = N'GINI_THRESHOLD_AMBER';
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
        MODEL_SUBTYPE NVARCHAR(50),
        GINI FLOAT,
        GINI_RATING NVARCHAR(10),
        KS_STATISTIC FLOAT,
        KS_RATING NVARCHAR(10),
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
    
    -- Lấy kết quả đánh giá
    INSERT INTO #ModelEvaluation (
        VALIDATION_ID,
        VALIDATION_DATE,
        MODEL_SUBTYPE,
        GINI,
        KS_STATISTIC,
        PSI,
        IV,
        KAPPA,
        RED_COUNT,
        AMBER_COUNT,
        GREEN_COUNT,
        OVERALL_RATING
    )
    SELECT 
        mvr.VALIDATION_ID,
        mvr.VALIDATION_DATE,
        mvr.MODEL_SUBTYPE,
        mvr.GINI,
        mvr.KS_STATISTIC,
        mvr.PSI,
        mvr.IV,
        mvr.KAPPA, -- Sử dụng trực tiếp KAPPA, không sử dụng F1_SCORE
        0, -- Sẽ được cập nhật sau
        0, -- Sẽ được cập nhật sau
        0, -- Sẽ được cập nhật sau
        'PENDING' -- Sẽ được cập nhật sau
    FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS mvr
    WHERE mvr.MODEL_ID = @MODEL_ID
    AND (@VALIDATION_ID IS NULL OR mvr.VALIDATION_ID = @VALIDATION_ID);
    
    -- Cập nhật ngưỡng GINI dựa trên MODEL_SUBTYPE
    UPDATE #ModelEvaluation
    SET 
        GINI_RATING = 
            CASE 
                WHEN MODEL_SUBTYPE = 'Retail AScore (without Bureau)' THEN
                    CASE 
                        WHEN GINI < 0.20 THEN 'RED'
                        WHEN GINI >= 0.20 AND GINI < 0.25 THEN 'AMBER'
                        WHEN GINI >= 0.25 THEN 'GREEN'
                        ELSE 'N/A'
                    END
                WHEN MODEL_SUBTYPE = 'Retail AScore (with Bureau)' THEN
                    CASE 
                        WHEN GINI < 0.25 THEN 'RED'
                        WHEN GINI >= 0.25 AND GINI < 0.45 THEN 'AMBER'
                        WHEN GINI >= 0.45 THEN 'GREEN'
                        ELSE 'N/A'
                    END
                WHEN MODEL_SUBTYPE = 'Retail BScore' THEN
                    CASE 
                        WHEN GINI < 0.35 THEN 'RED'
                        WHEN GINI >= 0.35 AND GINI < 0.45 THEN 'AMBER'
                        WHEN GINI >= 0.45 THEN 'GREEN'
                        ELSE 'N/A'
                    END
                WHEN MODEL_SUBTYPE = 'Wholesale Scorecard' THEN
                    CASE 
                        WHEN GINI < 0.40 THEN 'RED'
                        WHEN GINI >= 0.40 AND GINI < 0.50 THEN 'AMBER'
                        WHEN GINI >= 0.50 THEN 'GREEN'
                        ELSE 'N/A'
                    END
                ELSE -- Default case
                    CASE 
                        WHEN GINI < 0.25 THEN 'RED'
                        WHEN GINI >= 0.25 AND GINI < 0.35 THEN 'AMBER'
                        WHEN GINI >= 0.35 THEN 'GREEN'
                        ELSE 'N/A'
                    END
            END,
        KS_RATING = 
            CASE 
                WHEN KS_STATISTIC < 0.2 THEN 'RED'
                WHEN KS_STATISTIC >= 0.2 AND KS_STATISTIC < 0.3 THEN 'AMBER'
                WHEN KS_STATISTIC >= 0.3 THEN 'GREEN'
                ELSE 'N/A'
            END,
        PSI_RATING = 
            CASE 
                WHEN PSI > 0.25 THEN 'RED'
                WHEN PSI <= 0.25 AND PSI >= 0.1 THEN 'AMBER'
                WHEN PSI < 0.1 THEN 'GREEN'
                ELSE 'N/A'
            END,
        IV_RATING = 
            CASE 
                WHEN IV < 0.02 THEN 'RED'
                WHEN IV >= 0.02 AND IV < 0.1 THEN 'AMBER'
                WHEN IV >= 0.1 THEN 'GREEN'
                ELSE 'N/A'
            END,
        KAPPA_RATING = 
            CASE 
                WHEN KAPPA < 0.2 THEN 'RED'
                WHEN KAPPA >= 0.2 AND KAPPA < 0.6 THEN 'AMBER'
                WHEN KAPPA >= 0.6 THEN 'GREEN'
                ELSE 'N/A'
            END;
    
    -- Đếm số lượng đánh giá theo mức
    UPDATE #ModelEvaluation
    SET 
        RED_COUNT = 
            CASE WHEN GINI_RATING = 'RED' THEN 1 ELSE 0 END +
            CASE WHEN KS_RATING = 'RED' THEN 1 ELSE 0 END +
            CASE WHEN PSI_RATING = 'RED' THEN 1 ELSE 0 END +
            CASE WHEN IV_RATING = 'RED' THEN 1 ELSE 0 END +
            CASE WHEN KAPPA_RATING = 'RED' THEN 1 ELSE 0 END,
        AMBER_COUNT = 
            CASE WHEN GINI_RATING = 'AMBER' THEN 1 ELSE 0 END +
            CASE WHEN KS_RATING = 'AMBER' THEN 1 ELSE 0 END +
            CASE WHEN PSI_RATING = 'AMBER' THEN 1 ELSE 0 END +
            CASE WHEN IV_RATING = 'AMBER' THEN 1 ELSE 0 END +
            CASE WHEN KAPPA_RATING = 'AMBER' THEN 1 ELSE 0 END,
        GREEN_COUNT = 
            CASE WHEN GINI_RATING = 'GREEN' THEN 1 ELSE 0 END +
            CASE WHEN KS_RATING = 'GREEN' THEN 1 ELSE 0 END +
            CASE WHEN PSI_RATING = 'GREEN' THEN 1 ELSE 0 END +
            CASE WHEN IV_RATING = 'GREEN' THEN 1 ELSE 0 END +
            CASE WHEN KAPPA_RATING = 'GREEN' THEN 1 ELSE 0 END;
    
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
        me.MODEL_SUBTYPE,
        me.GINI,
        me.GINI_RATING,
        me.KS_STATISTIC,
        me.KS_RATING,
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

-- Trigger để tự động cập nhật ngưỡng GINI dựa trên MODEL_SUBTYPE
CREATE OR ALTER TRIGGER MODEL_REGISTRY.dbo.TRG_SET_GINI_THRESHOLDS
ON MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Cập nhật ngưỡng GINI dựa trên MODEL_SUBTYPE
    UPDATE mvr
    SET 
        GINI_THRESHOLD_RED = 
            CASE 
                WHEN mvr.MODEL_SUBTYPE = 'Retail AScore (without Bureau)' THEN 0.20
                WHEN mvr.MODEL_SUBTYPE = 'Retail AScore (with Bureau)' THEN 0.25
                WHEN mvr.MODEL_SUBTYPE = 'Retail BScore' THEN 0.35
                WHEN mvr.MODEL_SUBTYPE = 'Wholesale Scorecard' THEN 0.40
                ELSE 0.25 -- Default
            END,
        GINI_THRESHOLD_AMBER = 
            CASE 
                WHEN mvr.MODEL_SUBTYPE = 'Retail AScore (without Bureau)' THEN 0.25
                WHEN mvr.MODEL_SUBTYPE = 'Retail AScore (with Bureau)' THEN 0.45
                WHEN mvr.MODEL_SUBTYPE = 'Retail BScore' THEN 0.45
                WHEN mvr.MODEL_SUBTYPE = 'Wholesale Scorecard' THEN 0.50
                ELSE 0.35 -- Default
            END
    FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS mvr
    INNER JOIN inserted i ON mvr.VALIDATION_ID = i.VALIDATION_ID
    WHERE mvr.MODEL_SUBTYPE IS NOT NULL;
END;
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Trigger để tự động cập nhật ngưỡng GINI dựa trên MODEL_SUBTYPE', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TRIGGER',  @level1name = N'TRG_SET_GINI_THRESHOLDS';
GO

PRINT 'Bảng MODEL_VALIDATION_RESULTS đã được tạo thành công với cập nhật loại bỏ AUC_ROC, sử dụng chỉ KAPPA và ngưỡng GINI theo phân loại mô hình';
GO