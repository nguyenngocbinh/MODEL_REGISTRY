/*
Tên file: 05_fn_calculate_feature_drift.sql
Mô tả: Tạo function FN_CALCULATE_FEATURE_DRIFT để phát hiện và đo lường sự trôi dạt của đặc trưng theo thời gian
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-16
Phiên bản: 1.0

Function này cung cấp các chức năng:
1. Tính toán chỉ số drift (PSI, KL Divergence, Wasserstein) của một đặc trưng giữa hai kỳ thời gian
2. Hỗ trợ PSI (Population Stability Index) để đo lường sự thay đổi phân phối
3. Hỗ trợ KL Divergence (Kullback-Leibler) để đo khoảng cách phân phối
4. Hỗ trợ Wasserstein Distance để đo lường dịch chuyển phân phối

Đi kèm với Stored Procedure SP_UPDATE_FEATURE_STABILITY để cập nhật thông tin vào cơ sở dữ liệu
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu function đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.FN_CALCULATE_FEATURE_DRIFT', 'FN') IS NOT NULL
    DROP FUNCTION dbo.FN_CALCULATE_FEATURE_DRIFT;
GO

-- Tạo function FN_CALCULATE_FEATURE_DRIFT
CREATE FUNCTION dbo.FN_CALCULATE_FEATURE_DRIFT (
    @FEATURE_ID INT,
    @BASE_PERIOD_START DATE,
    @BASE_PERIOD_END DATE,
    @COMPARISON_PERIOD_START DATE,
    @COMPARISON_PERIOD_END DATE,
    @DRIFT_METRIC NVARCHAR(50) = 'PSI'  -- 'PSI', 'KL_DIVERGENCE', 'WASSERSTEIN'
)
RETURNS FLOAT
AS
BEGIN
    DECLARE @DRIFT_VALUE FLOAT = 0;
    DECLARE @FEATURE_CODE NVARCHAR(50);
    DECLARE @DATA_TYPE NVARCHAR(50);
    DECLARE @VALUE_TYPE NVARCHAR(50);
    
    -- Lấy thông tin về đặc trưng
    SELECT 
        @FEATURE_CODE = FEATURE_CODE,
        @DATA_TYPE = DATA_TYPE,
        @VALUE_TYPE = VALUE_TYPE
    FROM dbo.FEATURE_REGISTRY
    WHERE FEATURE_ID = @FEATURE_ID;
    
    -- Kiểm tra đặc trưng tồn tại
    IF @FEATURE_CODE IS NULL
        RETURN -1; -- Đặc trưng không tồn tại
    
    -- Kiểm tra xem đã có dữ liệu thống kê cho các kỳ này chưa
    DECLARE @BASE_STATS_ID INT;
    DECLARE @COMPARISON_STATS_ID INT;
    
    SELECT TOP 1 @BASE_STATS_ID = STATS_ID
    FROM dbo.FEATURE_STATS
    WHERE FEATURE_ID = @FEATURE_ID
      AND CALCULATION_DATE BETWEEN @BASE_PERIOD_START AND @BASE_PERIOD_END
    ORDER BY CALCULATION_DATE DESC;
    
    SELECT TOP 1 @COMPARISON_STATS_ID = STATS_ID
    FROM dbo.FEATURE_STATS
    WHERE FEATURE_ID = @FEATURE_ID
      AND CALCULATION_DATE BETWEEN @COMPARISON_PERIOD_START AND @COMPARISON_PERIOD_END
    ORDER BY CALCULATION_DATE DESC;
    
    -- Nếu không có dữ liệu thống kê, trả về giá trị mặc định
    IF @BASE_STATS_ID IS NULL OR @COMPARISON_STATS_ID IS NULL
        RETURN -2; -- Không đủ dữ liệu thống kê
    
    -- Lấy dữ liệu phân phối từ bảng FEATURE_VALUES
    DECLARE @BASE_DISTRIBUTION TABLE (
        BUCKET_ORDER INT,
        FREQUENCY FLOAT
    );
    
    DECLARE @COMPARISON_DISTRIBUTION TABLE (
        BUCKET_ORDER INT,
        FREQUENCY FLOAT
    );
    
    -- Lấy phân phối cơ sở
    INSERT INTO @BASE_DISTRIBUTION (BUCKET_ORDER, FREQUENCY)
    SELECT 
        fv.BUCKET_ORDER,
        fv.FREQUENCY
    FROM dbo.FEATURE_VALUES fv
    WHERE fv.FEATURE_ID = @FEATURE_ID
      AND fv.EFF_DATE <= @BASE_PERIOD_END
      AND fv.EXP_DATE >= @BASE_PERIOD_START
      AND fv.IS_ACTIVE = 1
    ORDER BY fv.BUCKET_ORDER;
    
    -- Lấy phân phối so sánh
    INSERT INTO @COMPARISON_DISTRIBUTION (BUCKET_ORDER, FREQUENCY)
    SELECT 
        fv.BUCKET_ORDER,
        fv.FREQUENCY
    FROM dbo.FEATURE_VALUES fv
    WHERE fv.FEATURE_ID = @FEATURE_ID
      AND fv.EFF_DATE <= @COMPARISON_PERIOD_END
      AND fv.EXP_DATE >= @COMPARISON_PERIOD_START
      AND fv.IS_ACTIVE = 1
    ORDER BY fv.BUCKET_ORDER;
    
    -- Nếu không có dữ liệu phân phối, kiểm tra xem có dữ liệu PSI đã tính sẵn không
    IF NOT EXISTS (SELECT 1 FROM @BASE_DISTRIBUTION) OR NOT EXISTS (SELECT 1 FROM @COMPARISON_DISTRIBUTION)
    BEGIN
        -- Kiểm tra xem có dữ liệu PSI đã tính sẵn trong FEATURE_STATS không
        IF @DRIFT_METRIC = 'PSI'
        BEGIN
            DECLARE @STORED_PSI FLOAT;
            
            SELECT @STORED_PSI = STABILITY_INDEX
            FROM dbo.FEATURE_STATS
            WHERE STATS_ID = @COMPARISON_STATS_ID;
            
            IF @STORED_PSI IS NOT NULL
                RETURN @STORED_PSI;
            ELSE
                RETURN -3; -- Không có dữ liệu phân phối và không có PSI được tính sẵn
        END
        ELSE
            RETURN -3; -- Không có dữ liệu phân phối
    END
    
    -- Chuyển đổi phân phối thành chuỗi JSON để sử dụng FN_CALCULATE_PSI
    DECLARE @BASE_JSON NVARCHAR(MAX) = N'[';
    DECLARE @COMPARISON_JSON NVARCHAR(MAX) = N'[';
    
    -- Tạo JSON cho phân phối cơ sở
    SELECT @BASE_JSON = @BASE_JSON + 
        CASE WHEN @BASE_JSON = N'[' THEN N'' ELSE N', ' END + 
        CAST(FREQUENCY AS NVARCHAR(20))
    FROM @BASE_DISTRIBUTION
    ORDER BY BUCKET_ORDER;
    
    SET @BASE_JSON = @BASE_JSON + N']';
    
    -- Tạo JSON cho phân phối so sánh
    SELECT @COMPARISON_JSON = @COMPARISON_JSON + 
        CASE WHEN @COMPARISON_JSON = N'[' THEN N'' ELSE N', ' END + 
        CAST(FREQUENCY AS NVARCHAR(20))
    FROM @COMPARISON_DISTRIBUTION
    ORDER BY BUCKET_ORDER;
    
    SET @COMPARISON_JSON = @COMPARISON_JSON + N']';
    
    -- Tính toán độ trôi dạt dựa trên metric được chọn
    IF @DRIFT_METRIC = 'PSI'
    BEGIN
        -- Sử dụng FN_CALCULATE_PSI để tính PSI
        SET @DRIFT_VALUE = dbo.FN_CALCULATE_PSI(@BASE_JSON, @COMPARISON_JSON, 0.0001);
    END
    ELSE IF @DRIFT_METRIC = 'KL_DIVERGENCE'
    BEGIN
        -- Tính Kullback-Leibler Divergence
        -- Lưu ý: KL Divergence tương tự như PSI nhưng không có thành phần (actual - expected)
        DECLARE @KL_DIVERGENCE FLOAT = 0;
        
        SELECT @KL_DIVERGENCE = SUM(
            CASE
                WHEN cd.FREQUENCY <= 0 OR bd.FREQUENCY <= 0 THEN 0
                ELSE cd.FREQUENCY * LOG(cd.FREQUENCY / bd.FREQUENCY)
            END
        )
        FROM @COMPARISON_DISTRIBUTION cd
        JOIN @BASE_DISTRIBUTION bd ON cd.BUCKET_ORDER = bd.BUCKET_ORDER;
        
        SET @DRIFT_VALUE = ISNULL(@KL_DIVERGENCE, 0);
    END
    ELSE IF @DRIFT_METRIC = 'WASSERSTEIN'
    BEGIN
        -- Tính Wasserstein Distance (Earth Mover's Distance)
        -- Lưu ý: Cần thêm thông tin về giá trị trung tâm của mỗi bin, đây là ước tính đơn giản
        DECLARE @WASSERSTEIN_DISTANCE FLOAT = 0;
        
        -- Tính tổng tích lũy cho cả hai phân phối
        DECLARE @CUM_BASE TABLE (BUCKET_ORDER INT, CUM_FREQ FLOAT);
        DECLARE @CUM_COMPARISON TABLE (BUCKET_ORDER INT, CUM_FREQ FLOAT);
        
        -- Tính tổng tích lũy cho phân phối cơ sở
        DECLARE @RUNNING_SUM FLOAT = 0;
        INSERT INTO @CUM_BASE
        SELECT 
            BUCKET_ORDER,
            (@RUNNING_SUM + FREQUENCY) AS CUM_FREQ
        FROM @BASE_DISTRIBUTION
        ORDER BY BUCKET_ORDER;
        
        -- Cập nhật @RUNNING_SUM sau mỗi lần chèn
        SELECT @RUNNING_SUM = MAX(CUM_FREQ) FROM @CUM_BASE;
        
        -- Đặt lại @RUNNING_SUM cho phân phối so sánh
        SET @RUNNING_SUM = 0;
        
        -- Tính tổng tích lũy cho phân phối so sánh
        INSERT INTO @CUM_COMPARISON
        SELECT 
            BUCKET_ORDER,
            (@RUNNING_SUM + FREQUENCY) AS CUM_FREQ
        FROM @COMPARISON_DISTRIBUTION
        ORDER BY BUCKET_ORDER;
        
        -- Tính Wasserstein Distance là tổng khoảng cách tuyệt đối giữa hai CDF
        SELECT @WASSERSTEIN_DISTANCE = SUM(ABS(cb.CUM_FREQ - cc.CUM_FREQ))
        FROM @CUM_BASE cb
        JOIN @CUM_COMPARISON cc ON cb.BUCKET_ORDER = cc.BUCKET_ORDER;
        
        SET @DRIFT_VALUE = ISNULL(@WASSERSTEIN_DISTANCE, 0);
    END
    ELSE
    BEGIN
        -- Metric không được hỗ trợ
        RETURN -4; -- Metric không được hỗ trợ
    END
    
    -- Cập nhật giá trị STABILITY_INDEX trong FEATURE_STATS nếu chưa có
    -- Lưu ý: Chúng ta không thể cập nhật dữ liệu trong một function, 
    -- nên đây chỉ là ghi chú để nhắc nhở cần cập nhật dữ liệu sau khi gọi function này
    -- Phần cập nhật này sẽ được thực hiện trong SP_UPDATE_FEATURE_STABILITY
    
    RETURN @DRIFT_VALUE;
END;
GO

-- Thêm comment cho function
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Tính toán độ trôi dạt của đặc trưng giữa hai kỳ thời gian', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'FUNCTION',  @level1name = N'FN_CALCULATE_FEATURE_DRIFT';
GO

PRINT N'Function FN_CALCULATE_FEATURE_DRIFT đã được tạo thành công';
GO

-- Tạo stored procedure để cập nhật STABILITY_INDEX trong FEATURE_STATS
IF OBJECT_ID('dbo.SP_UPDATE_FEATURE_STABILITY', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SP_UPDATE_FEATURE_STABILITY;
GO

CREATE PROCEDURE dbo.SP_UPDATE_FEATURE_STABILITY
    @FEATURE_ID INT,
    @BASE_PERIOD_START DATE,
    @BASE_PERIOD_END DATE,
    @COMPARISON_PERIOD_START DATE,
    @COMPARISON_PERIOD_END DATE,
    @DRIFT_METRIC NVARCHAR(50) = 'PSI'
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Tính toán độ trôi dạt của đặc trưng
    DECLARE @DRIFT_VALUE FLOAT;
    SET @DRIFT_VALUE = dbo.FN_CALCULATE_FEATURE_DRIFT(
        @FEATURE_ID,
        @BASE_PERIOD_START,
        @BASE_PERIOD_END,
        @COMPARISON_PERIOD_START,
        @COMPARISON_PERIOD_END,
        @DRIFT_METRIC
    );
    
    -- Kiểm tra kết quả tính toán
    IF @DRIFT_VALUE < 0
    BEGIN
        DECLARE @ERROR_MESSAGE NVARCHAR(500);
        SET @ERROR_MESSAGE = CASE
            WHEN @DRIFT_VALUE = -1 THEN 'Đặc trưng không tồn tại'
            WHEN @DRIFT_VALUE = -2 THEN 'Không đủ dữ liệu thống kê'
            WHEN @DRIFT_VALUE = -3 THEN 'Không có dữ liệu phân phối'
            WHEN @DRIFT_VALUE = -4 THEN 'Metric không được hỗ trợ'
            ELSE 'Lỗi không xác định'
        END;
        
        RAISERROR(@ERROR_MESSAGE, 16, 1);
        RETURN;
    END
    
    -- Lấy ID của bản ghi thống kê gần nhất trong kỳ so sánh
    DECLARE @STATS_ID INT;
    
    SELECT TOP 1 @STATS_ID = STATS_ID
    FROM dbo.FEATURE_STATS
    WHERE FEATURE_ID = @FEATURE_ID
      AND CALCULATION_DATE BETWEEN @COMPARISON_PERIOD_START AND @COMPARISON_PERIOD_END
    ORDER BY CALCULATION_DATE DESC;
    
    -- Cập nhật giá trị STABILITY_INDEX trong FEATURE_STATS
    IF @STATS_ID IS NOT NULL
    BEGIN
        UPDATE dbo.FEATURE_STATS
        SET STABILITY_INDEX = @DRIFT_VALUE,
            UPDATED_BY = SUSER_NAME(),
            UPDATED_DATE = GETDATE()
        WHERE STATS_ID = @STATS_ID;
        
        PRINT N'Đã cập nhật STABILITY_INDEX = ' + CAST(@DRIFT_VALUE AS NVARCHAR(20)) + N' cho đặc trưng ID = ' + CAST(@FEATURE_ID AS NVARCHAR(10));
    END
    ELSE
    BEGIN
        PRINT N'Không tìm thấy bản ghi thống kê để cập nhật';
    END
    
    -- Ghi log việc tính toán độ ổn định của đặc trưng
    INSERT INTO dbo.FEATURE_REFRESH_LOG (
        FEATURE_ID,
        REFRESH_TYPE,
        REFRESH_STATUS,
        SOURCE_DATA_START_DATE,
        SOURCE_DATA_END_DATE,
        REFRESH_END_TIME,
        REFRESH_REASON,
        REFRESH_TRIGGERED_BY,
        ENVIRONMENT
    )
    VALUES (
        @FEATURE_ID,
        'STABILITY_CALCULATION',
        'COMPLETED',
        @COMPARISON_PERIOD_START,
        @COMPARISON_PERIOD_END,
        GETDATE(),
        'Calculate feature stability against base period ' + 
            CONVERT(NVARCHAR(10), @BASE_PERIOD_START, 120) + ' to ' + 
            CONVERT(NVARCHAR(10), @BASE_PERIOD_END, 120) + 
            ' using ' + @DRIFT_METRIC,
        SUSER_NAME(),
        'PROD'
    );
    
    -- Trả về giá trị độ trôi dạt
    SELECT @DRIFT_VALUE AS DRIFT_VALUE,
           CASE 
               WHEN @DRIFT_VALUE < 0.1 THEN 'STABLE'
               WHEN @DRIFT_VALUE >= 0.1 AND @DRIFT_VALUE < 0.2 THEN 'SLIGHT_DRIFT'
               WHEN @DRIFT_VALUE >= 0.2 AND @DRIFT_VALUE < 0.3 THEN 'MODERATE_DRIFT'
               ELSE 'SIGNIFICANT_DRIFT'
           END AS DRIFT_CATEGORY,
           CASE 
               WHEN @DRIFT_VALUE < 0.1 THEN 'Không có sự thay đổi đáng kể'
               WHEN @DRIFT_VALUE >= 0.1 AND @DRIFT_VALUE < 0.2 THEN 'Có sự thay đổi nhỏ, cần theo dõi'
               WHEN @DRIFT_VALUE >= 0.2 AND @DRIFT_VALUE < 0.3 THEN 'Có sự thay đổi đáng kể, cần xem xét tác động'
               ELSE 'Thay đổi rất lớn, cần đánh giá lại đặc trưng ngay lập tức'
           END AS RECOMMENDATION;
END;
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Tính toán độ trôi dạt của đặc trưng và cập nhật vào bảng FEATURE_STATS', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'PROCEDURE',  @level1name = N'SP_UPDATE_FEATURE_STABILITY';
GO

PRINT N'Stored Procedure SP_UPDATE_FEATURE_STABILITY đã được tạo thành công';
GO

-- Hướng dẫn sử dụng:
PRINT N'
-- Ví dụ cách sử dụng Function FN_CALCULATE_FEATURE_DRIFT:
SELECT dbo.FN_CALCULATE_FEATURE_DRIFT(
    1,                -- FEATURE_ID 
    ''2025-01-01'',     -- BASE_PERIOD_START
    ''2025-01-31'',     -- BASE_PERIOD_END
    ''2025-04-01'',     -- COMPARISON_PERIOD_START
    ''2025-04-30'',     -- COMPARISON_PERIOD_END
    ''PSI''             -- DRIFT_METRIC (PSI, KL_DIVERGENCE, WASSERSTEIN)
) AS FEATURE_DRIFT;

-- Ví dụ cách sử dụng Stored Procedure SP_UPDATE_FEATURE_STABILITY:
EXEC dbo.SP_UPDATE_FEATURE_STABILITY
    @FEATURE_ID = 1,
    @BASE_PERIOD_START = ''2025-01-01'',
    @BASE_PERIOD_END = ''2025-01-31'',
    @COMPARISON_PERIOD_START = ''2025-04-01'',
    @COMPARISON_PERIOD_END = ''2025-04-30'',
    @DRIFT_METRIC = ''PSI'';';
GO