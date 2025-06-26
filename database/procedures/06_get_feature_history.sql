/*
Tên file: 06_get_feature_history.sql
Mô tả: Tạo stored procedure GET_FEATURE_HISTORY để lấy lịch sử giá trị của đặc trưng
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-06-19
Phiên bản: 1.0
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu proc đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.GET_FEATURE_HISTORY', 'P') IS NOT NULL
    DROP PROCEDURE dbo.GET_FEATURE_HISTORY;
GO

-- Tạo stored procedure GET_FEATURE_HISTORY
CREATE PROCEDURE dbo.GET_FEATURE_HISTORY
    @FEATURE_ID INT = NULL,
    @FEATURE_CODE NVARCHAR(50) = NULL,
    @START_DATE DATE = NULL,
    @END_DATE DATE = NULL,
    @GROUP_BY NVARCHAR(20) = 'MONTHLY', -- 'DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY'
    @INCLUDE_STATISTICS BIT = 1,
    @INCLUDE_REFRESH_LOG BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Xử lý tham số mặc định
    IF @START_DATE IS NULL
        SET @START_DATE = DATEADD(YEAR, -1, GETDATE());
        
    IF @END_DATE IS NULL
        SET @END_DATE = GETDATE();
    
    -- Xác định FEATURE_ID nếu chỉ có FEATURE_CODE
    IF @FEATURE_ID IS NULL AND @FEATURE_CODE IS NOT NULL
    BEGIN
        SELECT @FEATURE_ID = FEATURE_ID
        FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY
        WHERE FEATURE_CODE = @FEATURE_CODE AND IS_ACTIVE = 1;
        
        IF @FEATURE_ID IS NULL
        BEGIN
            RAISERROR(N'Không tìm thấy đặc trưng với mã "%s"', 16, 1, @FEATURE_CODE);
            RETURN;
        END
    END
    
    IF @FEATURE_ID IS NULL
    BEGIN
        RAISERROR(N'Phải cung cấp FEATURE_ID hoặc FEATURE_CODE', 16, 1);
        RETURN;
    END
    
    -- Trả về thông tin cơ bản về đặc trưng
    SELECT 
        fr.FEATURE_ID,
        fr.FEATURE_NAME,
        fr.FEATURE_CODE,
        fr.FEATURE_DESCRIPTION,
        fr.DATA_TYPE,
        fr.VALUE_TYPE,
        fr.SOURCE_SYSTEM,
        fr.BUSINESS_CATEGORY,
        fr.UPDATE_FREQUENCY,
        fr.BUSINESS_OWNER
    FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY fr
    WHERE fr.FEATURE_ID = @FEATURE_ID;
    
    -- Trả về lịch sử giá trị đặc trưng
    SELECT 
        fv.VALUE_ID,
        fv.VALUE_TYPE,
        fv.VALUE_LABEL,
        fv.MIN_VALUE,
        fv.MAX_VALUE,
        fv.FREQUENCY,
        fv.WOE,
        fv.IV_CONTRIBUTION,
        fv.EVENT_RATE,
        fv.IS_OUTLIER,
        fv.BUCKET_ORDER,
        fv.EFF_DATE,
        fv.EXP_DATE,
        fv.CREATED_DATE,
        CASE 
            WHEN @GROUP_BY = 'DAILY' THEN CAST(fv.EFF_DATE AS VARCHAR)
            WHEN @GROUP_BY = 'WEEKLY' THEN 'Week ' + CAST(DATEPART(WEEK, fv.EFF_DATE) AS VARCHAR) + ' ' + CAST(YEAR(fv.EFF_DATE) AS VARCHAR)
            WHEN @GROUP_BY = 'MONTHLY' THEN DATENAME(MONTH, fv.EFF_DATE) + ' ' + CAST(YEAR(fv.EFF_DATE) AS VARCHAR)
            WHEN @GROUP_BY = 'QUARTERLY' THEN 'Q' + CAST(DATEPART(QUARTER, fv.EFF_DATE) AS VARCHAR) + ' ' + CAST(YEAR(fv.EFF_DATE) AS VARCHAR)
            ELSE CAST(YEAR(fv.EFF_DATE) AS VARCHAR)
        END AS TIME_PERIOD
    FROM MODEL_REGISTRY.dbo.FEATURE_VALUES fv
    WHERE fv.FEATURE_ID = @FEATURE_ID
      AND fv.EFF_DATE BETWEEN @START_DATE AND @END_DATE
      AND fv.IS_ACTIVE = 1
    ORDER BY fv.EFF_DATE DESC, fv.BUCKET_ORDER;
    
    -- Trả về thống kê nếu được yêu cầu
    IF @INCLUDE_STATISTICS = 1
    BEGIN
        SELECT 
            fs.STATS_ID,
            fs.CALCULATION_DATE,
            fs.SAMPLE_SIZE,
            fs.MIN_VALUE,
            fs.MAX_VALUE,
            fs.MEAN,
            fs.MEDIAN,
            fs.MODE,
            fs.STD_DEVIATION,
            fs.VARIANCE,
            fs.MISSING_RATIO,
            fs.INFORMATION_VALUE,
            fs.STABILITY_INDEX,
            fs.TARGET_CORRELATION,
            fs.HAS_OUTLIERS,
            fs.UNIQUE_VALUES,
            CASE 
                WHEN @GROUP_BY = 'DAILY' THEN CAST(fs.CALCULATION_DATE AS VARCHAR)
                WHEN @GROUP_BY = 'WEEKLY' THEN 'Week ' + CAST(DATEPART(WEEK, fs.CALCULATION_DATE) AS VARCHAR) + ' ' + CAST(YEAR(fs.CALCULATION_DATE) AS VARCHAR)
                WHEN @GROUP_BY = 'MONTHLY' THEN DATENAME(MONTH, fs.CALCULATION_DATE) + ' ' + CAST(YEAR(fs.CALCULATION_DATE) AS VARCHAR)
                WHEN @GROUP_BY = 'QUARTERLY' THEN 'Q' + CAST(DATEPART(QUARTER, fs.CALCULATION_DATE) AS VARCHAR) + ' ' + CAST(YEAR(fs.CALCULATION_DATE) AS VARCHAR)
                ELSE CAST(YEAR(fs.CALCULATION_DATE) AS VARCHAR)
            END AS TIME_PERIOD
        FROM MODEL_REGISTRY.dbo.FEATURE_STATS fs
        WHERE fs.FEATURE_ID = @FEATURE_ID
          AND fs.CALCULATION_DATE BETWEEN @START_DATE AND @END_DATE
          AND fs.IS_ACTIVE = 1
        ORDER BY fs.CALCULATION_DATE DESC;
    END
    
    -- Trả về log cập nhật nếu được yêu cầu
    IF @INCLUDE_REFRESH_LOG = 1
    BEGIN
        SELECT 
            frl.LOG_ID,
            frl.REFRESH_TYPE,
            frl.REFRESH_START_TIME,
            frl.REFRESH_END_TIME,
            frl.REFRESH_STATUS,
            frl.AFFECTED_RECORDS,
            frl.SOURCE_DATA_START_DATE,
            frl.SOURCE_DATA_END_DATE,
            frl.REFRESH_REASON,
            frl.ENVIRONMENT,
            DATEDIFF(SECOND, frl.REFRESH_START_TIME, frl.REFRESH_END_TIME) AS DURATION_SECONDS,
            frl.CREATED_BY
        FROM MODEL_REGISTRY.dbo.FEATURE_REFRESH_LOG frl
        WHERE frl.FEATURE_ID = @FEATURE_ID
          AND frl.REFRESH_START_TIME BETWEEN @START_DATE AND @END_DATE
        ORDER BY frl.REFRESH_START_TIME DESC;
    END
END;
GO

-- Thêm comment cho stored procedure
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Lấy lịch sử giá trị và thống kê của đặc trưng', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'PROCEDURE',  @level1name = N'GET_FEATURE_HISTORY';
GO

PRINT N'Stored procedure GET_FEATURE_HISTORY đã được tạo thành công';
GO