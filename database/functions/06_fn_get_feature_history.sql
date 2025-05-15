/*
Tên file: 06_fn_get_feature_history.sql
Mô tả: Tạo function FN_GET_FEATURE_HISTORY để lấy lịch sử giá trị của đặc trưng theo thời gian
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-15
Phiên bản: 1.0
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu function đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.FN_GET_FEATURE_HISTORY', 'TF') IS NOT NULL
    DROP FUNCTION dbo.FN_GET_FEATURE_HISTORY;
GO

-- Tạo function FN_GET_FEATURE_HISTORY
CREATE FUNCTION dbo.FN_GET_FEATURE_HISTORY (
    @FEATURE_ID INT,                     -- ID của đặc trưng cần lấy lịch sử
    @START_DATE DATE = NULL,             -- Ngày bắt đầu của khoảng thời gian
    @END_DATE DATE = NULL,               -- Ngày kết thúc của khoảng thời gian
    @GROUP_BY NVARCHAR(20) = 'MONTHLY',  -- Nhóm theo: 'DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY', 'YEARLY'
    @SEGMENT_ID INT = NULL               -- ID của phân khúc, NULL nếu lấy tổng thể
)
RETURNS TABLE
AS
RETURN (
    WITH FeatureStats AS (
        -- Lấy thống kê đặc trưng từ bảng FEATURE_STATS
        SELECT 
            fs.FEATURE_ID,
            fs.SEGMENT_ID,
            fs.CALCULATION_DATE,
            fs.MIN_VALUE,
            fs.MAX_VALUE,
            fs.MEAN,
            fs.MEDIAN,
            fs.STD_DEVIATION,
            fs.MISSING_RATIO,
            fs.STABILITY_INDEX,
            fs.TARGET_CORRELATION,
            fs.INFORMATION_VALUE,
            fr.FEATURE_NAME,
            fr.DATA_TYPE,
            fr.VALUE_TYPE,
            -- Tạo trường thời gian theo GROUP_BY
            CASE 
                WHEN @GROUP_BY = 'DAILY' THEN fs.CALCULATION_DATE
                WHEN @GROUP_BY = 'WEEKLY' THEN DATEADD(DAY, -(DATEPART(WEEKDAY, fs.CALCULATION_DATE)-1), fs.CALCULATION_DATE)
                WHEN @GROUP_BY = 'MONTHLY' THEN DATEFROMPARTS(YEAR(fs.CALCULATION_DATE), MONTH(fs.CALCULATION_DATE), 1)
                WHEN @GROUP_BY = 'QUARTERLY' THEN DATEFROMPARTS(YEAR(fs.CALCULATION_DATE), ((DATEPART(QUARTER, fs.CALCULATION_DATE)-1)*3)+1, 1)
                WHEN @GROUP_BY = 'YEARLY' THEN DATEFROMPARTS(YEAR(fs.CALCULATION_DATE), 1, 1)
                ELSE fs.CALCULATION_DATE
            END AS TIME_PERIOD
        FROM dbo.FEATURE_STATS fs
        JOIN dbo.FEATURE_REGISTRY fr ON fs.FEATURE_ID = fr.FEATURE_ID
        WHERE fs.FEATURE_ID = @FEATURE_ID
        AND (fs.SEGMENT_ID = @SEGMENT_ID OR (@SEGMENT_ID IS NULL AND fs.SEGMENT_ID IS NULL))
        AND fs.IS_ACTIVE = 1
        AND (@START_DATE IS NULL OR fs.CALCULATION_DATE >= @START_DATE)
        AND (@END_DATE IS NULL OR fs.CALCULATION_DATE <= @END_DATE)
    ),
    FeatureRefreshInfo AS (
        -- Lấy thông tin làm mới đặc trưng từ bảng FEATURE_REFRESH_LOG
        SELECT 
            frl.FEATURE_ID,
            frl.REFRESH_TYPE,
            frl.REFRESH_STATUS,
            frl.AFFECTED_RECORDS,
            frl.REFRESH_START_TIME,
            -- Chuyển đổi REFRESH_START_TIME thành DATE để nhóm
            CAST(frl.REFRESH_START_TIME AS DATE) AS REFRESH_DATE,
            -- Tạo trường thời gian theo GROUP_BY
            CASE 
                WHEN @GROUP_BY = 'DAILY' THEN CAST(frl.REFRESH_START_TIME AS DATE)
                WHEN @GROUP_BY = 'WEEKLY' THEN DATEADD(DAY, -(DATEPART(WEEKDAY, frl.REFRESH_START_TIME)-1), CAST(frl.REFRESH_START_TIME AS DATE))
                WHEN @GROUP_BY = 'MONTHLY' THEN DATEFROMPARTS(YEAR(frl.REFRESH_START_TIME), MONTH(frl.REFRESH_START_TIME), 1)
                WHEN @GROUP_BY = 'QUARTERLY' THEN DATEFROMPARTS(YEAR(frl.REFRESH_START_TIME), ((DATEPART(QUARTER, frl.REFRESH_START_TIME)-1)*3)+1, 1)
                WHEN @GROUP_BY = 'YEARLY' THEN DATEFROMPARTS(YEAR(frl.REFRESH_START_TIME), 1, 1)
                ELSE CAST(frl.REFRESH_START_TIME AS DATE)
            END AS TIME_PERIOD
        FROM dbo.FEATURE_REFRESH_LOG frl
        WHERE frl.FEATURE_ID = @FEATURE_ID
        AND (@START_DATE IS NULL OR CAST(frl.REFRESH_START_TIME AS DATE) >= @START_DATE)
        AND (@END_DATE IS NULL OR CAST(frl.REFRESH_START_TIME AS DATE) <= @END_DATE)
    ),
    FeatureValueHistory AS (
        -- Lấy lịch sử giá trị đặc trưng từ bảng FEATURE_VALUES
        SELECT 
            fv.FEATURE_ID,
            fv.SEGMENT_ID,
            fv.VALUE_TYPE,
            fv.EFF_DATE,
            -- Tạo trường thời gian theo GROUP_BY
            CASE 
                WHEN @GROUP_BY = 'DAILY' THEN fv.EFF_DATE
                WHEN @GROUP_BY = 'WEEKLY' THEN DATEADD(DAY, -(DATEPART(WEEKDAY, fv.EFF_DATE)-1), fv.EFF_DATE)
                WHEN @GROUP_BY = 'MONTHLY' THEN DATEFROMPARTS(YEAR(fv.EFF_DATE), MONTH(fv.EFF_DATE), 1)
                WHEN @GROUP_BY = 'QUARTERLY' THEN DATEFROMPARTS(YEAR(fv.EFF_DATE), ((DATEPART(QUARTER, fv.EFF_DATE)-1)*3)+1, 1)
                WHEN @GROUP_BY = 'YEARLY' THEN DATEFROMPARTS(YEAR(fv.EFF_DATE), 1, 1)
                ELSE fv.EFF_DATE
            END AS TIME_PERIOD,
            -- Tổng hợp dữ liệu theo loại VALUE_TYPE
            AVG(CASE WHEN fv.MIN_VALUE IS NOT NULL THEN fv.MIN_VALUE END) AS AVG_MIN_VALUE,
            AVG(CASE WHEN fv.MAX_VALUE IS NOT NULL THEN fv.MAX_VALUE END) AS AVG_MAX_VALUE,
            AVG(CASE WHEN fv.MEAN_FOR_RANGE IS NOT NULL THEN fv.MEAN_FOR_RANGE END) AS AVG_MEAN_VALUE,
            AVG(CASE WHEN fv.MEDIAN_FOR_RANGE IS NOT NULL THEN fv.MEDIAN_FOR_RANGE END) AS AVG_MEDIAN_VALUE,
            SUM(fv.RECORD_COUNT) AS TOTAL_RECORDS,
            AVG(CASE WHEN fv.FREQUENCY IS NOT NULL THEN fv.FREQUENCY END) AS AVG_FREQUENCY,
            AVG(CASE WHEN fv.EVENT_RATE IS NOT NULL THEN fv.EVENT_RATE END) AS AVG_EVENT_RATE,
            AVG(CASE WHEN fv.WOE IS NOT NULL THEN fv.WOE END) AS AVG_WOE,
            AVG(CASE WHEN fv.IV_CONTRIBUTION IS NOT NULL THEN fv.IV_CONTRIBUTION END) AS AVG_IV_CONTRIBUTION,
            COUNT(DISTINCT fv.VALUE_LABEL) AS UNIQUE_VALUES_COUNT
        FROM dbo.FEATURE_VALUES fv
        WHERE fv.FEATURE_ID = @FEATURE_ID
        AND (fv.SEGMENT_ID = @SEGMENT_ID OR (@SEGMENT_ID IS NULL AND fv.SEGMENT_ID IS NULL))
        AND fv.IS_ACTIVE = 1
        AND (@START_DATE IS NULL OR fv.EFF_DATE >= @START_DATE)
        AND (@END_DATE IS NULL OR fv.EFF_DATE <= @END_DATE)
        GROUP BY 
            fv.FEATURE_ID,
            fv.SEGMENT_ID,
            fv.VALUE_TYPE,
            fv.EFF_DATE,
            CASE 
                WHEN @GROUP_BY = 'DAILY' THEN fv.EFF_DATE
                WHEN @GROUP_BY = 'WEEKLY' THEN DATEADD(DAY, -(DATEPART(WEEKDAY, fv.EFF_DATE)-1), fv.EFF_DATE)
                WHEN @GROUP_BY = 'MONTHLY' THEN DATEFROMPARTS(YEAR(fv.EFF_DATE), MONTH(fv.EFF_DATE), 1)
                WHEN @GROUP_BY = 'QUARTERLY' THEN DATEFROMPARTS(YEAR(fv.EFF_DATE), ((DATEPART(QUARTER, fv.EFF_DATE)-1)*3)+1, 1)
                WHEN @GROUP_BY = 'YEARLY' THEN DATEFROMPARTS(YEAR(fv.EFF_DATE), 1, 1)
                ELSE fv.EFF_DATE
            END
    ),
    -- Tạo timeline cho tất cả các thời kỳ trong khoảng thời gian
    TimePeriods AS (
        -- Xác định ngày bắt đầu và kết thúc của timeline
        SELECT 
            COALESCE(
                @START_DATE, 
                (SELECT MIN(CALCULATION_DATE) FROM dbo.FEATURE_STATS WHERE FEATURE_ID = @FEATURE_ID),
                (SELECT MIN(CAST(REFRESH_START_TIME AS DATE)) FROM dbo.FEATURE_REFRESH_LOG WHERE FEATURE_ID = @FEATURE_ID),
                (SELECT MIN(EFF_DATE) FROM dbo.FEATURE_VALUES WHERE FEATURE_ID = @FEATURE_ID),
                DATEADD(YEAR, -1, GETDATE()) -- Mặc định 1 năm trở lại
            ) AS StartDate,
            COALESCE(
                @END_DATE,
                (SELECT MAX(CALCULATION_DATE) FROM dbo.FEATURE_STATS WHERE FEATURE_ID = @FEATURE_ID),
                (SELECT MAX(CAST(REFRESH_START_TIME AS DATE)) FROM dbo.FEATURE_REFRESH_LOG WHERE FEATURE_ID = @FEATURE_ID),
                (SELECT MAX(EFF_DATE) FROM dbo.FEATURE_VALUES WHERE FEATURE_ID = @FEATURE_ID),
                GETDATE() -- Mặc định đến hiện tại
            ) AS EndDate
    ),
    RecursiveTimeline AS (
        -- CTE đệ quy để tạo timeline
        SELECT 
            CASE 
                WHEN @GROUP_BY = 'DAILY' THEN tp.StartDate
                WHEN @GROUP_BY = 'WEEKLY' THEN DATEADD(DAY, -(DATEPART(WEEKDAY, tp.StartDate)-1), tp.StartDate)
                WHEN @GROUP_BY = 'MONTHLY' THEN DATEFROMPARTS(YEAR(tp.StartDate), MONTH(tp.StartDate), 1)
                WHEN @GROUP_BY = 'QUARTERLY' THEN DATEFROMPARTS(YEAR(tp.StartDate), ((DATEPART(QUARTER, tp.StartDate)-1)*3)+1, 1)
                WHEN @GROUP_BY = 'YEARLY' THEN DATEFROMPARTS(YEAR(tp.StartDate), 1, 1)
                ELSE tp.StartDate
            END AS TIME_PERIOD
        FROM TimePeriods tp
        
        UNION ALL
        
        SELECT 
            CASE 
                WHEN @GROUP_BY = 'DAILY' THEN DATEADD(DAY, 1, rt.TIME_PERIOD)
                WHEN @GROUP_BY = 'WEEKLY' THEN DATEADD(WEEK, 1, rt.TIME_PERIOD)
                WHEN @GROUP_BY = 'MONTHLY' THEN DATEADD(MONTH, 1, rt.TIME_PERIOD)
                WHEN @GROUP_BY = 'QUARTERLY' THEN DATEADD(MONTH, 3, rt.TIME_PERIOD)
                WHEN @GROUP_BY = 'YEARLY' THEN DATEADD(YEAR, 1, rt.TIME_PERIOD)
                ELSE DATEADD(DAY, 1, rt.TIME_PERIOD)
            END
        FROM RecursiveTimeline rt, TimePeriods tp
        WHERE 
            CASE 
                WHEN @GROUP_BY = 'DAILY' THEN DATEADD(DAY, 1, rt.TIME_PERIOD)
                WHEN @GROUP_BY = 'WEEKLY' THEN DATEADD(WEEK, 1, rt.TIME_PERIOD)
                WHEN @GROUP_BY = 'MONTHLY' THEN DATEADD(MONTH, 1, rt.TIME_PERIOD)
                WHEN @GROUP_BY = 'QUARTERLY' THEN DATEADD(MONTH, 3, rt.TIME_PERIOD)
                WHEN @GROUP_BY = 'YEARLY' THEN DATEADD(YEAR, 1, rt.TIME_PERIOD)
                ELSE DATEADD(DAY, 1, rt.TIME_PERIOD)
            END <= tp.EndDate
    ),
    UniqueTimePeriods AS (
        -- Lấy các thời kỳ duy nhất để tránh trùng lặp
        SELECT DISTINCT TIME_PERIOD
        FROM RecursiveTimeline
    ),
    -- Tổng hợp tất cả dữ liệu theo thời kỳ
    FeatureHistorySummary AS (
        SELECT 
            utp.TIME_PERIOD,
            fr.FEATURE_ID,
            fr.FEATURE_NAME,
            fr.DATA_TYPE,
            fr.VALUE_TYPE,
            @SEGMENT_ID AS SEGMENT_ID,
            CASE 
                WHEN @GROUP_BY = 'DAILY' THEN 'Daily'
                WHEN @GROUP_BY = 'WEEKLY' THEN 'Weekly'
                WHEN @GROUP_BY = 'MONTHLY' THEN 'Monthly'
                WHEN @GROUP_BY = 'QUARTERLY' THEN 'Quarterly'
                WHEN @GROUP_BY = 'YEARLY' THEN 'Yearly'
                ELSE 'Custom'
            END AS TIME_GRANULARITY,
            @START_DATE AS START_DATE,
            @END_DATE AS END_DATE,
            
            -- Lấy giá trị thống kê gần nhất theo thời kỳ
            (
                SELECT TOP 1 fs.MIN_VALUE
                FROM FeatureStats fs
                WHERE fs.TIME_PERIOD = utp.TIME_PERIOD
                ORDER BY fs.CALCULATION_DATE DESC
            ) AS MIN_VALUE,
            
            (
                SELECT TOP 1 fs.MAX_VALUE
                FROM FeatureStats fs
                WHERE fs.TIME_PERIOD = utp.TIME_PERIOD
                ORDER BY fs.CALCULATION_DATE DESC
            ) AS MAX_VALUE,
            
            (
                SELECT TOP 1 fs.MEAN
                FROM FeatureStats fs
                WHERE fs.TIME_PERIOD = utp.TIME_PERIOD
                ORDER BY fs.CALCULATION_DATE DESC
            ) AS MEAN_VALUE,
            
            (
                SELECT TOP 1 fs.MEDIAN
                FROM FeatureStats fs
                WHERE fs.TIME_PERIOD = utp.TIME_PERIOD
                ORDER BY fs.CALCULATION_DATE DESC
            ) AS MEDIAN_VALUE,
            
            (
                SELECT TOP 1 fs.STD_DEVIATION
                FROM FeatureStats fs
                WHERE fs.TIME_PERIOD = utp.TIME_PERIOD
                ORDER BY fs.CALCULATION_DATE DESC
            ) AS STD_DEVIATION,
            
            (
                SELECT TOP 1 fs.MISSING_RATIO
                FROM FeatureStats fs
                WHERE fs.TIME_PERIOD = utp.TIME_PERIOD
                ORDER BY fs.CALCULATION_DATE DESC
            ) AS MISSING_RATIO,
            
            (
                SELECT TOP 1 fs.STABILITY_INDEX
                FROM FeatureStats fs
                WHERE fs.TIME_PERIOD = utp.TIME_PERIOD
                ORDER BY fs.CALCULATION_DATE DESC
            ) AS STABILITY_INDEX,
            
            (
                SELECT TOP 1 fs.TARGET_CORRELATION
                FROM FeatureStats fs
                WHERE fs.TIME_PERIOD = utp.TIME_PERIOD
                ORDER BY fs.CALCULATION_DATE DESC
            ) AS TARGET_CORRELATION,
            
            (
                SELECT TOP 1 fs.INFORMATION_VALUE
                FROM FeatureStats fs
                WHERE fs.TIME_PERIOD = utp.TIME_PERIOD
                ORDER BY fs.CALCULATION_DATE DESC
            ) AS INFORMATION_VALUE,
            
            -- Lấy thông tin từ lịch sử giá trị
            (
                SELECT TOP 1 fvh.AVG_MIN_VALUE
                FROM FeatureValueHistory fvh
                WHERE fvh.TIME_PERIOD = utp.TIME_PERIOD
                ORDER BY fvh.EFF_DATE DESC
            ) AS HIST_MIN_VALUE,
            
            (
                SELECT TOP 1 fvh.AVG_MAX_VALUE
                FROM FeatureValueHistory fvh
                WHERE fvh.TIME_PERIOD = utp.TIME_PERIOD
                ORDER BY fvh.EFF_DATE DESC
            ) AS HIST_MAX_VALUE,
            
            (
                SELECT TOP 1 fvh.AVG_MEAN_VALUE
                FROM FeatureValueHistory fvh
                WHERE fvh.TIME_PERIOD = utp.TIME_PERIOD
                ORDER BY fvh.EFF_DATE DESC
            ) AS HIST_MEAN_VALUE,
            
            (
                SELECT TOP 1 fvh.AVG_MEDIAN_VALUE
                FROM FeatureValueHistory fvh
                WHERE fvh.TIME_PERIOD = utp.TIME_PERIOD
                ORDER BY fvh.EFF_DATE DESC
            ) AS HIST_MEDIAN_VALUE,
            
            (
                SELECT TOP 1 fvh.TOTAL_RECORDS
                FROM FeatureValueHistory fvh
                WHERE fvh.TIME_PERIOD = utp.TIME_PERIOD
                ORDER BY fvh.EFF_DATE DESC
            ) AS TOTAL_RECORDS,
            
            (
                SELECT TOP 1 fvh.UNIQUE_VALUES_COUNT
                FROM FeatureValueHistory fvh
                WHERE fvh.TIME_PERIOD = utp.TIME_PERIOD
                ORDER BY fvh.EFF_DATE DESC
            ) AS UNIQUE_VALUES_COUNT,
            
            (
                SELECT TOP 1 fvh.AVG_EVENT_RATE
                FROM FeatureValueHistory fvh
                WHERE fvh.TIME_PERIOD = utp.TIME_PERIOD
                ORDER BY fvh.EFF_DATE DESC
            ) AS EVENT_RATE,
            
            (
                SELECT TOP 1 fvh.AVG_WOE
                FROM FeatureValueHistory fvh
                WHERE fvh.TIME_PERIOD = utp.TIME_PERIOD
                ORDER BY fvh.EFF_DATE DESC
            ) AS AVG_WOE,
            
            -- Lấy thông tin làm mới đặc trưng
            (
                SELECT COUNT(*)
                FROM FeatureRefreshInfo fri
                WHERE fri.TIME_PERIOD = utp.TIME_PERIOD
            ) AS REFRESH_COUNT,
            
            (
                SELECT SUM(CASE WHEN fri.REFRESH_STATUS = 'COMPLETED' THEN 1 ELSE 0 END)
                FROM FeatureRefreshInfo fri
                WHERE fri.TIME_PERIOD = utp.TIME_PERIOD
            ) AS SUCCESSFUL_REFRESH_COUNT,
            
            (
                SELECT SUM(CASE WHEN fri.REFRESH_STATUS = 'FAILED' THEN 1 ELSE 0 END)
                FROM FeatureRefreshInfo fri
                WHERE fri.TIME_PERIOD = utp.TIME_PERIOD
            ) AS FAILED_REFRESH_COUNT,
            
            (
                SELECT SUM(fri.AFFECTED_RECORDS)
                FROM FeatureRefreshInfo fri
                WHERE fri.TIME_PERIOD = utp.TIME_PERIOD
                AND fri.REFRESH_STATUS = 'COMPLETED'
            ) AS TOTAL_AFFECTED_RECORDS,
            
            -- Thêm cờ báo hiệu có dữ liệu cho thời kỳ này hay không
            CASE 
                WHEN EXISTS (SELECT 1 FROM FeatureStats fs WHERE fs.TIME_PERIOD = utp.TIME_PERIOD)
                    OR EXISTS (SELECT 1 FROM FeatureValueHistory fvh WHERE fvh.TIME_PERIOD = utp.TIME_PERIOD)
                    OR EXISTS (SELECT 1 FROM FeatureRefreshInfo fri WHERE fri.TIME_PERIOD = utp.TIME_PERIOD)
                THEN 1
                ELSE 0
            END AS HAS_DATA_FOR_PERIOD,
            
            -- Tính số ngày kể từ kỳ trước có dữ liệu
            (
                SELECT TOP 1 DATEDIFF(DAY, prev.TIME_PERIOD, utp.TIME_PERIOD)
                FROM UniqueTimePeriods prev
                WHERE prev.TIME_PERIOD < utp.TIME_PERIOD
                AND EXISTS (
                    SELECT 1 
                    FROM FeatureStats fs 
                    WHERE fs.TIME_PERIOD = prev.TIME_PERIOD
                    UNION ALL
                    SELECT 1 
                    FROM FeatureValueHistory fvh 
                    WHERE fvh.TIME_PERIOD = prev.TIME_PERIOD
                    UNION ALL
                    SELECT 1 
                    FROM FeatureRefreshInfo fri 
                    WHERE fri.TIME_PERIOD = prev.TIME_PERIOD
                )
                ORDER BY prev.TIME_PERIOD DESC
            ) AS DAYS_SINCE_LAST_DATA
        FROM UniqueTimePeriods utp
        CROSS JOIN (
            SELECT DISTINCT fr.FEATURE_ID, fr.FEATURE_NAME, fr.DATA_TYPE, fr.VALUE_TYPE
            FROM dbo.FEATURE_REGISTRY fr
            WHERE fr.FEATURE_ID = @FEATURE_ID
        ) fr
    )
    -- Trả về kết quả cuối cùng
    SELECT 
        TIME_PERIOD,
        FEATURE_ID,
        FEATURE_NAME,
        DATA_TYPE,
        VALUE_TYPE,
        SEGMENT_ID,
        TIME_GRANULARITY,
        START_DATE,
        END_DATE,
        -- Ưu tiên giá trị từ FeatureStats nếu có, nếu không thì sử dụng giá trị từ FeatureValueHistory
        COALESCE(MIN_VALUE, HIST_MIN_VALUE) AS MIN_VALUE,
        COALESCE(MAX_VALUE, HIST_MAX_VALUE) AS MAX_VALUE,
        COALESCE(MEAN_VALUE, HIST_MEAN_VALUE) AS MEAN_VALUE,
        COALESCE(MEDIAN_VALUE, HIST_MEDIAN_VALUE) AS MEDIAN_VALUE,
        STD_DEVIATION,
        MISSING_RATIO,
        STABILITY_INDEX,
        TARGET_CORRELATION,
        INFORMATION_VALUE,
        TOTAL_RECORDS,
        UNIQUE_VALUES_COUNT,
        EVENT_RATE,
        AVG_WOE,
        REFRESH_COUNT,
        SUCCESSFUL_REFRESH_COUNT,
        FAILED_REFRESH_COUNT,
        TOTAL_AFFECTED_RECORDS,
        HAS_DATA_FOR_PERIOD,
        DAYS_SINCE_LAST_DATA
    FROM FeatureHistorySummary
    WHERE HAS_DATA_FOR_PERIOD = 1 -- Chỉ lấy các thời kỳ có dữ liệu
    ORDER BY TIME_PERIOD DESC
);
GO

-- Thêm comment cho function
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Lấy lịch sử giá trị của đặc trưng theo thời gian', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'FUNCTION',  @level1name = N'FN_GET_FEATURE_HISTORY';
GO

-- Tạo thêm một function để lấy lịch sử giá trị của đặc trưng theo tên
IF OBJECT_ID('dbo.FN_GET_FEATURE_HISTORY_BY_NAME', 'TF') IS NOT NULL
    DROP FUNCTION dbo.FN_GET_FEATURE_HISTORY_BY_NAME;
GO

CREATE FUNCTION dbo.FN_GET_FEATURE_HISTORY_BY_NAME (
    @FEATURE_NAME NVARCHAR(100),         -- Tên của đặc trưng
    @START_DATE DATE = NULL,             -- Ngày bắt đầu của khoảng thời gian
    @END_DATE DATE = NULL,               -- Ngày kết thúc của khoảng thời gian
    @GROUP_BY NVARCHAR(20) = 'MONTHLY',  -- Nhóm theo: 'DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY', 'YEARLY'
    @SEGMENT_ID INT = NULL               -- ID của phân khúc, NULL nếu lấy tổng thể
)
RETURNS TABLE
AS
RETURN (
    -- Lấy FEATURE_ID từ tên đặc trưng
    WITH FeatureInfo AS (
        SELECT FEATURE_ID
        FROM dbo.FEATURE_REGISTRY
        WHERE FEATURE_NAME = @FEATURE_NAME
        AND IS_ACTIVE = 1
    )
    -- Sử dụng function FN_GET_FEATURE_HISTORY với FEATURE_ID
    SELECT *
    FROM FeatureInfo fi
    CROSS APPLY dbo.FN_GET_FEATURE_HISTORY(
        fi.FEATURE_ID,
        @START_DATE,
        @END_DATE,
        @GROUP_BY,
        @SEGMENT_ID
    )
);
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Lấy lịch sử giá trị của đặc trưng theo tên', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'FUNCTION',  @level1name = N'FN_GET_FEATURE_HISTORY_BY_NAME';
GO

PRINT N'Function FN_GET_FEATURE_HISTORY và FN_GET_FEATURE_HISTORY_BY_NAME đã được tạo thành công';
GO

-- Ví dụ sử dụng
PRINT N'
-- Ví dụ cách sử dụng Function FN_GET_FEATURE_HISTORY:
-- Lấy lịch sử giá trị của đặc trưng theo ID, phân tổ theo tháng
SELECT * FROM dbo.FN_GET_FEATURE_HISTORY(1, ''2025-01-01'', ''2025-05-01'', ''MONTHLY'', NULL);

-- Lấy lịch sử giá trị của đặc trưng theo tháng cho phân khúc cụ thể
SELECT * FROM dbo.FN_GET_FEATURE_HISTORY(1, ''2025-01-01'', ''2025-05-01'', ''MONTHLY'', 2);

-- Lấy lịch sử giá trị của đặc trưng theo ID, phân tổ theo quý
SELECT * FROM dbo.FN_GET_FEATURE_HISTORY(1, ''2024-01-01'', ''2025-05-01'', ''QUARTERLY'', NULL);

-- Ví dụ cách sử dụng Function FN_GET_FEATURE_HISTORY_BY_NAME:
-- Lấy lịch sử giá trị của đặc trưng theo tên, phân tổ theo tháng
SELECT * FROM dbo.FN_GET_FEATURE_HISTORY_BY_NAME(''Customer Age'', ''2025-01-01'', ''2025-05-01'', ''MONTHLY'', NULL);
';