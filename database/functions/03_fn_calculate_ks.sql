/*
Tên file: 03_fn_calculate_ks.sql
Mô tả: Tạo function FN_CALCULATE_KS để tính toán chỉ số Kolmogorov-Smirnov (KS) cho việc đánh giá mô hình
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-15
Phiên bản: 1.0
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu function đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.FN_CALCULATE_KS', 'FN') IS NOT NULL
    DROP FUNCTION dbo.FN_CALCULATE_KS;
GO

-- Tạo function FN_CALCULATE_KS
CREATE FUNCTION dbo.FN_CALCULATE_KS (
    @SCORE_DATA NVARCHAR(MAX), -- Chuỗi JSON, mảng các objects {score, is_event}
    @NUM_BINS INT = 10,        -- Số lượng bins để phân chia điểm số
    @USE_EQUAL_BINS BIT = 1    -- 1: sử dụng bins có kích thước bằng nhau, 0: sử dụng bins có số lượng mẫu bằng nhau
)
RETURNS FLOAT
AS
BEGIN
    DECLARE @KS_STAT FLOAT = 0;
    
    -- Tạo bảng tạm để lưu trữ dữ liệu điểm và nhãn
    DECLARE @ScoreData TABLE (
        RowID INT IDENTITY(1,1),
        Score FLOAT,
        IsEvent BIT
    );
    
    -- Chèn dữ liệu từ chuỗi JSON vào bảng tạm
    INSERT INTO @ScoreData (Score, IsEvent)
    SELECT 
        JSON_VALUE(value, '$.score') AS Score,
        CAST(JSON_VALUE(value, '$.is_event') AS BIT) AS IsEvent
    FROM OPENJSON(@SCORE_DATA);
    
    -- Kiểm tra dữ liệu hợp lệ
    IF NOT EXISTS (SELECT 1 FROM @ScoreData)
    BEGIN
        RETURN 0; -- Trả về 0 nếu không có dữ liệu
    END
    
    -- Tính toán min và max score
    DECLARE @MinScore FLOAT;
    DECLARE @MaxScore FLOAT;
    
    SELECT 
        @MinScore = MIN(Score),
        @MaxScore = MAX(Score)
    FROM @ScoreData;
    
    -- Tạo bảng tạm để lưu trữ các bins
    DECLARE @Bins TABLE (
        BinIndex INT,
        LowerBound FLOAT,
        UpperBound FLOAT,
        EventCount INT DEFAULT 0,
        NonEventCount INT DEFAULT 0,
        TotalCount INT DEFAULT 0
    );
    
    -- Tạo các bins dựa trên @USE_EQUAL_BINS
    IF @USE_EQUAL_BINS = 1
    BEGIN
        -- Tạo bins có kích thước bằng nhau
        DECLARE @BinWidth FLOAT = (@MaxScore - @MinScore) / @NUM_BINS;
        
        -- Xử lý trường hợp đặc biệt khi bin width quá nhỏ
        IF @BinWidth < 0.000001 -- Giá trị nhỏ tùy ý
        BEGIN
            SET @BinWidth = 0.000001;
        END
        
        -- Tạo các bins
        DECLARE @i INT = 0;
        WHILE @i < @NUM_BINS
        BEGIN
            INSERT INTO @Bins (BinIndex, LowerBound, UpperBound)
            VALUES (
                @i, 
                @MinScore + @i * @BinWidth, 
                @MinScore + (@i + 1) * @BinWidth
            );
            
            SET @i = @i + 1;
        END;
        
        -- Cập nhật bin cuối cùng để đảm bảo bao gồm giá trị max
        UPDATE @Bins
        SET UpperBound = @MaxScore
        WHERE BinIndex = @NUM_BINS - 1;
    END
    ELSE
    BEGIN
        -- Tạo bins có số lượng mẫu bằng nhau (percentile-based)
        DECLARE @TotalSamples INT;
        DECLARE @SamplesPerBin INT;
        
        SELECT @TotalSamples = COUNT(*) FROM @ScoreData;
        SET @SamplesPerBin = @TotalSamples / @NUM_BINS;
        
        -- Cần ít nhất 10 mẫu cho mỗi bin để đảm bảo tính chính xác
        IF @SamplesPerBin < 10
        BEGIN
            SET @NUM_BINS = @TotalSamples / 10;
            IF @NUM_BINS < 2 SET @NUM_BINS = 2;
            SET @SamplesPerBin = @TotalSamples / @NUM_BINS;
        END
        
        -- Tạo bảng tạm chứa thông tin percentile
        DECLARE @Percentiles TABLE (
            BinIndex INT,
            PercentileValue FLOAT
        );
        
        -- Tạo mốc percentile cho mỗi bin
        DECLARE @p INT = 1;
        WHILE @p <= @NUM_BINS
        BEGIN
            INSERT INTO @Percentiles (BinIndex, PercentileValue)
            SELECT 
                @p - 1,
                Score
            FROM @ScoreData
            ORDER BY Score
            OFFSET ((@p * @TotalSamples) / @NUM_BINS) - 1 ROWS
            FETCH NEXT 1 ROWS ONLY;
            
            SET @p = @p + 1;
        END;
        
        -- Tạo bins dựa trên percentiles
        INSERT INTO @Bins (BinIndex, LowerBound, UpperBound)
        SELECT 
            p1.BinIndex,
            CASE 
                WHEN p1.BinIndex = 0 THEN @MinScore
                ELSE p2.PercentileValue
            END,
            CASE 
                WHEN p1.BinIndex = @NUM_BINS - 1 THEN @MaxScore
                ELSE p1.PercentileValue
            END
        FROM @Percentiles p1
        LEFT JOIN @Percentiles p2 ON p1.BinIndex = p2.BinIndex + 1
        WHERE p1.BinIndex < @NUM_BINS
        ORDER BY p1.BinIndex;
    END
    
    -- Đếm số lượng sự kiện và không phải sự kiện trong mỗi bin
    UPDATE b
    SET 
        EventCount = e.EventCount,
        NonEventCount = e.NonEventCount,
        TotalCount = e.TotalCount
    FROM @Bins b
    JOIN (
        SELECT 
            MAX(CASE 
                WHEN sd.Score > b.UpperBound THEN b.BinIndex + 1
                WHEN sd.Score >= b.LowerBound AND sd.Score <= b.UpperBound THEN b.BinIndex
                ELSE -1 -- Không thuộc bin này
            END) AS BinIndex,
            SUM(CASE WHEN sd.IsEvent = 1 THEN 1 ELSE 0 END) AS EventCount,
            SUM(CASE WHEN sd.IsEvent = 0 THEN 1 ELSE 0 END) AS NonEventCount,
            COUNT(*) AS TotalCount
        FROM @ScoreData sd
        CROSS JOIN @Bins b
        WHERE sd.Score >= b.LowerBound AND sd.Score <= b.UpperBound
        GROUP BY CASE 
            WHEN sd.Score > b.UpperBound THEN b.BinIndex + 1
            WHEN sd.Score >= b.LowerBound AND sd.Score <= b.UpperBound THEN b.BinIndex
            ELSE -1 -- Không thuộc bin này
        END
    ) e ON b.BinIndex = e.BinIndex;
    
    -- Tạo bảng tạm để tính cumulative distributions
    DECLARE @Cumulative TABLE (
        BinIndex INT,
        CumEventCount INT,
        CumNonEventCount INT,
        TotalEventCount INT,
        TotalNonEventCount INT,
        CumEventRate FLOAT,
        CumNonEventRate FLOAT,
        KS FLOAT
    );
    
    -- Tính tổng số lượng sự kiện và không phải sự kiện
    DECLARE @TotalEventCount INT;
    DECLARE @TotalNonEventCount INT;
    
    SELECT 
        @TotalEventCount = SUM(EventCount),
        @TotalNonEventCount = SUM(NonEventCount)
    FROM @Bins;
    
    -- Đảm bảo không có lỗi chia cho 0
    IF @TotalEventCount = 0 OR @TotalNonEventCount = 0
    BEGIN
        RETURN 0; -- Trả về 0 nếu không có đủ dữ liệu cho cả hai nhóm
    END
    
    -- Tính toán phân phối tích lũy và KS cho mỗi bin
    INSERT INTO @Cumulative
    SELECT 
        b.BinIndex,
        SUM(b2.EventCount) AS CumEventCount,
        SUM(b2.NonEventCount) AS CumNonEventCount,
        @TotalEventCount AS TotalEventCount,
        @TotalNonEventCount AS TotalNonEventCount,
        CAST(SUM(b2.EventCount) AS FLOAT) / @TotalEventCount AS CumEventRate,
        CAST(SUM(b2.NonEventCount) AS FLOAT) / @TotalNonEventCount AS CumNonEventRate,
        ABS(CAST(SUM(b2.EventCount) AS FLOAT) / @TotalEventCount - 
            CAST(SUM(b2.NonEventCount) AS FLOAT) / @TotalNonEventCount) AS KS
    FROM @Bins b
    JOIN @Bins b2 ON b2.BinIndex <= b.BinIndex
    GROUP BY b.BinIndex
    ORDER BY b.BinIndex;
    
    -- Lấy giá trị KS lớn nhất
    SELECT @KS_STAT = MAX(KS)
    FROM @Cumulative;
    
    RETURN @KS_STAT;
END;
GO

-- Thêm comment cho function
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Tính toán chỉ số Kolmogorov-Smirnov (KS) từ dữ liệu điểm mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'FUNCTION',  @level1name = N'FN_CALCULATE_KS';
GO

-- Tạo thêm một stored procedure để tính KS từ bảng dữ liệu
IF OBJECT_ID('dbo.SP_CALCULATE_KS_TABLE', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SP_CALCULATE_KS_TABLE;
GO

CREATE PROCEDURE dbo.SP_CALCULATE_KS_TABLE
    @MODEL_ID INT,
    @VALIDATION_DATE DATE,
    @SCORE_COLUMN_NAME NVARCHAR(128) = 'SCORE',
    @TARGET_COLUMN_NAME NVARCHAR(128) = 'TARGET',
    @NUM_BINS INT = 10,
    @USE_EQUAL_BINS BIT = 1,
    @KS FLOAT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Lấy thông tin về mô hình
    DECLARE @SOURCE_DATABASE NVARCHAR(128);
    DECLARE @SOURCE_SCHEMA NVARCHAR(128);
    DECLARE @SOURCE_TABLE_NAME NVARCHAR(128);
    
    SELECT 
        @SOURCE_DATABASE = mr.SOURCE_DATABASE,
        @SOURCE_SCHEMA = mr.SOURCE_SCHEMA,
        @SOURCE_TABLE_NAME = mr.SOURCE_TABLE_NAME
    FROM dbo.MODEL_REGISTRY mr
    WHERE mr.MODEL_ID = @MODEL_ID;
    
    -- Kiểm tra thông tin mô hình hợp lệ
    IF @SOURCE_DATABASE IS NULL OR @SOURCE_SCHEMA IS NULL OR @SOURCE_TABLE_NAME IS NULL
    BEGIN
        SET @KS = 0;
        RAISERROR('Không tìm thấy thông tin mô hình', 16, 1);
        RETURN;
    END
    
    -- Tạo bảng tạm để lưu trữ dữ liệu
    CREATE TABLE #ScoreData (
        Score FLOAT,
        IsEvent BIT
    );
    
    -- Tạo câu lệnh dynamic SQL để truy vấn dữ liệu từ bảng nguồn
    DECLARE @SqlCmd NVARCHAR(MAX);
    DECLARE @ParmDefinition NVARCHAR(500);
    
    SET @SqlCmd = N'
    INSERT INTO #ScoreData (Score, IsEvent)
    SELECT 
        CAST(' + QUOTENAME(@SCORE_COLUMN_NAME) + ' AS FLOAT) AS Score,
        CAST(' + QUOTENAME(@TARGET_COLUMN_NAME) + ' AS BIT) AS IsEvent
    FROM ' + QUOTENAME(@SOURCE_DATABASE) + '.' + QUOTENAME(@SOURCE_SCHEMA) + '.' + QUOTENAME(@SOURCE_TABLE_NAME) + '
    WHERE PROCESS_DATE = @ValidationDate
    AND ' + QUOTENAME(@SCORE_COLUMN_NAME) + ' IS NOT NULL
    AND ' + QUOTENAME(@TARGET_COLUMN_NAME) + ' IS NOT NULL';
    
    SET @ParmDefinition = N'@ValidationDate DATE';
    
    -- Thực thi câu lệnh
    EXEC sp_executesql @SqlCmd, @ParmDefinition, @ValidationDate = @VALIDATION_DATE;
    
    -- Kiểm tra nếu dữ liệu rỗng
    IF NOT EXISTS (SELECT 1 FROM #ScoreData)
    BEGIN
        DROP TABLE #ScoreData;
        SET @KS = 0;
        RAISERROR('Không có dữ liệu cho mô hình vào ngày xác định', 16, 1);
        RETURN;
    END
    
    -- Chuyển đổi dữ liệu từ bảng tạm sang định dạng JSON
    DECLARE @ScoreDataJson NVARCHAR(MAX);
    
    SET @ScoreDataJson = (
        SELECT 
            Score AS 'score',
            IsEvent AS 'is_event'
        FROM #ScoreData
        FOR JSON PATH
    );
    
    -- Tính toán KS
    SET @KS = dbo.FN_CALCULATE_KS(@ScoreDataJson, @NUM_BINS, @USE_EQUAL_BINS);
    
    -- Dọn dẹp
    DROP TABLE #ScoreData;
END;
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Stored procedure để tính KS từ bảng dữ liệu mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'PROCEDURE',  @level1name = N'SP_CALCULATE_KS_TABLE';
GO

PRINT N'Function FN_CALCULATE_KS và Stored Procedure SP_CALCULATE_KS_TABLE đã được tạo thành công';
GO

-- Ví dụ sử dụng FN_CALCULATE_KS
PRINT N'
-- Ví dụ cách sử dụng Function FN_CALCULATE_KS:
DECLARE @score_data NVARCHAR(MAX) = ''[
    {"score": 0.92, "is_event": 1},
    {"score": 0.86, "is_event": 1},
    {"score": 0.79, "is_event": 1},
    {"score": 0.75, "is_event": 0},
    {"score": 0.68, "is_event": 1},
    {"score": 0.65, "is_event": 0},
    {"score": 0.58, "is_event": 0},
    {"score": 0.52, "is_event": 0},
    {"score": 0.47, "is_event": 0},
    {"score": 0.41, "is_event": 0}
]'';

SELECT dbo.FN_CALCULATE_KS(@score_data, 5, 1) AS KS_Value;

-- Ví dụ cách sử dụng Stored Procedure SP_CALCULATE_KS_TABLE:
DECLARE @result FLOAT;
EXEC dbo.SP_CALCULATE_KS_TABLE 
    @MODEL_ID = 1, 
    @VALIDATION_DATE = ''2025-01-01'', 
    @SCORE_COLUMN_NAME = ''SCORE'',
    @TARGET_COLUMN_NAME = ''TARGET'',
    @NUM_BINS = 10,
    @USE_EQUAL_BINS = 1,
    @KS = @result OUTPUT;
SELECT @result AS KS_Result;
';