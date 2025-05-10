/*
Tên file: 06_get_model_performance_history.sql
Mô tả: Tạo stored procedure GET_MODEL_PERFORMANCE_HISTORY để lấy lịch sử hiệu suất của mô hình theo thời gian
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.0
*/

-- Kiểm tra nếu proc đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.GET_MODEL_PERFORMANCE_HISTORY', 'P') IS NOT NULL
    DROP PROCEDURE MODEL_REGISTRY.dbo.GET_MODEL_PERFORMANCE_HISTORY;
GO

-- Tạo stored procedure GET_MODEL_PERFORMANCE_HISTORY
CREATE PROCEDURE MODEL_REGISTRY.dbo.GET_MODEL_PERFORMANCE_HISTORY
    @MODEL_ID INT = NULL,
    @MODEL_NAME NVARCHAR(100) = NULL,
    @START_DATE DATE = NULL,
    @END_DATE DATE = NULL,
    @VALIDATION_TYPE NVARCHAR(50) = NULL,
    @INCLUDE_DETAILS BIT = 0  -- Thêm tham số để chọn có hiển thị chi tiết hay không
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Xử lý lỗi nếu không có MODEL_ID hoặc MODEL_NAME
    IF @MODEL_ID IS NULL AND @MODEL_NAME IS NULL
    BEGIN
        RAISERROR('Phải cung cấp MODEL_ID hoặc MODEL_NAME', 16, 1);
        RETURN;
    END
    
    -- Nếu không có MODEL_ID nhưng có MODEL_NAME, tìm MODEL_ID
    IF @MODEL_ID IS NULL AND @MODEL_NAME IS NOT NULL
    BEGIN
        SELECT @MODEL_ID = MODEL_ID 
        FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY 
        WHERE MODEL_NAME = @MODEL_NAME AND IS_ACTIVE = 1;
        
        IF @MODEL_ID IS NULL
        BEGIN
            RAISERROR('Không tìm thấy mô hình có tên "%s"', 16, 1, @MODEL_NAME);
            RETURN;
        END
    END
    
    -- Nếu không có ngày bắt đầu, lấy 2 năm trước
    IF @START_DATE IS NULL
        SET @START_DATE = DATEADD(YEAR, -2, GETDATE());
    
    -- Nếu không có ngày kết thúc, lấy ngày hiện tại
    IF @END_DATE IS NULL
        SET @END_DATE = GETDATE();
    
    -- Hiển thị thông tin cơ bản về mô hình
    SELECT 
        mr.MODEL_ID,
        mr.MODEL_NAME,
        mr.MODEL_VERSION,
        mt.TYPE_CODE,
        mt.TYPE_NAME,
        mr.EFF_DATE AS MODEL_EFF_DATE,
        mr.EXP_DATE AS MODEL_EXP_DATE,
        mr.IS_ACTIVE,
        CASE 
            WHEN mr.IS_ACTIVE = 1 AND GETDATE() BETWEEN mr.EFF_DATE AND mr.EXP_DATE THEN 'ACTIVE'
            WHEN mr.IS_ACTIVE = 1 AND GETDATE() < mr.EFF_DATE THEN 'PENDING'
            WHEN mr.IS_ACTIVE = 1 AND GETDATE() > mr.EXP_DATE THEN 'EXPIRED'
            ELSE 'INACTIVE'
        END AS MODEL_STATUS
    FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
    JOIN MODEL_REGISTRY.dbo.MODEL_TYPE mt ON mr.TYPE_ID = mt.TYPE_ID
    WHERE mr.MODEL_ID = @MODEL_ID;
    
    -- Truy vấn kết quả hiệu suất mô hình theo thời gian
    SELECT 
        mvr.VALIDATION_ID,
        mvr.VALIDATION_DATE,
        mvr.VALIDATION_TYPE,
        mvr.VALIDATION_PERIOD,
        mvr.DATA_SAMPLE_SIZE,
        mvr.VALIDATION_STATUS,
        
        -- Các chỉ số hiệu suất chính
        mvr.AUC_ROC,
        mvr.KS_STATISTIC,
        mvr.GINI,
        mvr.PSI,
        
        -- Các chỉ số phân loại
        mvr.ACCURACY,
        mvr.PRECISION,
        mvr.RECALL,
        mvr.F1_SCORE,
        
        -- Các chỉ số khác
        mvr.BRIER_SCORE,
        mvr.IV,
        
        -- Thông tin quản lý
        mvr.VALIDATION_THRESHOLD_BREACHED,
        mvr.VALIDATED_BY,
        mvr.CREATED_DATE,
        
        -- Chỉ hiển thị comment khi tham số INCLUDE_DETAILS = 1
        CASE WHEN @INCLUDE_DETAILS = 1 THEN mvr.VALIDATION_COMMENTS ELSE NULL END AS VALIDATION_COMMENTS,
        
        -- Tính toán % thay đổi so với lần đánh giá trước đó
        LAG(mvr.AUC_ROC) OVER (ORDER BY mvr.VALIDATION_DATE) AS PREV_AUC_ROC,
        CASE 
            WHEN LAG(mvr.AUC_ROC) OVER (ORDER BY mvr.VALIDATION_DATE) IS NOT NULL 
            THEN (mvr.AUC_ROC - LAG(mvr.AUC_ROC) OVER (ORDER BY mvr.VALIDATION_DATE)) 
                  / LAG(mvr.AUC_ROC) OVER (ORDER BY mvr.VALIDATION_DATE) * 100
            ELSE NULL
        END AS AUC_CHANGE_PCT,
        
        CASE 
            WHEN LAG(mvr.KS_STATISTIC) OVER (ORDER BY mvr.VALIDATION_DATE) IS NOT NULL 
            THEN (mvr.KS_STATISTIC - LAG(mvr.KS_STATISTIC) OVER (ORDER BY mvr.VALIDATION_DATE)) 
                  / LAG(mvr.KS_STATISTIC) OVER (ORDER BY mvr.VALIDATION_DATE) * 100
            ELSE NULL
        END AS KS_CHANGE_PCT,
        
        CASE 
            WHEN LAG(mvr.PSI) OVER (ORDER BY mvr.VALIDATION_DATE) IS NOT NULL 
            THEN (mvr.PSI - LAG(mvr.PSI) OVER (ORDER BY mvr.VALIDATION_DATE)) 
                  / LAG(mvr.PSI) OVER (ORDER BY mvr.VALIDATION_DATE) * 100
            ELSE NULL
        END AS PSI_CHANGE_PCT
    FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS mvr
    WHERE mvr.MODEL_ID = @MODEL_ID
    AND mvr.VALIDATION_DATE BETWEEN @START_DATE AND @END_DATE
    AND (@VALIDATION_TYPE IS NULL OR mvr.VALIDATION_TYPE = @VALIDATION_TYPE)
    ORDER BY mvr.VALIDATION_DATE DESC;
    
    -- Chỉ hiển thị chi tiết khi tham số INCLUDE_DETAILS = 1
    IF @INCLUDE_DETAILS = 1
    BEGIN
        -- Hiển thị chi tiết ma trận nhầm lẫn cho đánh giá gần nhất
        SELECT TOP 1
            mvr.VALIDATION_ID,
            mvr.VALIDATION_DATE,
            mvr.CONFUSION_MATRIX,
            mvr.ROC_CURVE_DATA,
            mvr.CAP_CURVE_DATA,
            mvr.CALIBRATION_CURVE,
            mvr.DETAILED_METRICS
        FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS mvr
        WHERE mvr.MODEL_ID = @MODEL_ID
        AND mvr.VALIDATION_DATE BETWEEN @START_DATE AND @END_DATE
        AND (@VALIDATION_TYPE IS NULL OR mvr.VALIDATION_TYPE = @VALIDATION_TYPE)
        ORDER BY mvr.VALIDATION_DATE DESC;
    END
    
    -- Hiển thị tóm tắt xu hướng hiệu suất
    SELECT 
        MIN(mvr.VALIDATION_DATE) AS EARLIEST_VALIDATION,
        MAX(mvr.VALIDATION_DATE) AS LATEST_VALIDATION,
        COUNT(*) AS VALIDATION_COUNT,
        AVG(mvr.AUC_ROC) AS AVG_AUC_ROC,
        MIN(mvr.AUC_ROC) AS MIN_AUC_ROC,
        MAX(mvr.AUC_ROC) AS MAX_AUC_ROC,
        AVG(mvr.KS_STATISTIC) AS AVG_KS,
        AVG(mvr.PSI) AS AVG_PSI,
        CASE 
            WHEN MIN(mvr.VALIDATION_DATE) = MAX(mvr.VALIDATION_DATE) THEN NULL
            WHEN 
                FIRST_VALUE(mvr.AUC_ROC) OVER (ORDER BY mvr.VALIDATION_DATE DESC) - 
                FIRST_VALUE(mvr.AUC_ROC) OVER (ORDER BY mvr.VALIDATION_DATE ASC) > 0 
            THEN 'IMPROVING'
            WHEN 
                FIRST_VALUE(mvr.AUC_ROC) OVER (ORDER BY mvr.VALIDATION_DATE DESC) - 
                FIRST_VALUE(mvr.AUC_ROC) OVER (ORDER BY mvr.VALIDATION_DATE ASC) < 0 
            THEN 'DEGRADING'
            ELSE 'STABLE'
        END AS PERFORMANCE_TREND
    FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS mvr
    WHERE mvr.MODEL_ID = @MODEL_ID
    AND mvr.VALIDATION_DATE BETWEEN @START_DATE AND @END_DATE
    AND (@VALIDATION_TYPE IS NULL OR mvr.VALIDATION_TYPE = @VALIDATION_TYPE);
END;
GO

-- Thêm comment cho stored procedure
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Lấy lịch sử hiệu suất của một mô hình theo thời gian', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'PROCEDURE',  @level1name = N'GET_MODEL_PERFORMANCE_HISTORY';
GO

PRINT 'Stored procedure GET_MODEL_PERFORMANCE_HISTORY đã được tạo thành công';
GO