/*
Tên file: 02_fn_calculate_psi.sql
Mô tả: Tạo function FN_CALCULATE_PSI để tính toán chỉ số Population Stability Index
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.2 - Fix: Enhanced PSI calculation with improved error handling and security fixes
*/

-- Đảm bảo sử dụng đúng database
USE MODEL_REGISTRY;
GO

-- Kiểm tra nếu function đã tồn tại thì xóa
IF OBJECT_ID('dbo.FN_CALCULATE_PSI', 'FN') IS NOT NULL
    DROP FUNCTION dbo.FN_CALCULATE_PSI;
GO

-- Tạo function FN_CALCULATE_PSI
CREATE FUNCTION dbo.FN_CALCULATE_PSI (
    @EXPECTED_DISTRIBUTION NVARCHAR(MAX), -- Chuỗi JSON, mảng các giá trị tần suất
    @ACTUAL_DISTRIBUTION NVARCHAR(MAX),   -- Chuỗi JSON, mảng các giá trị tần suất
    @MIN_PERCENTAGE FLOAT = 0.0001       -- Giá trị tối thiểu để tránh chia cho 0
)
RETURNS FLOAT
AS
BEGIN
    DECLARE @PSI FLOAT = 0;
    
    -- Tạo bảng tạm để lưu trữ các giá trị phân phối
    DECLARE @Distribution TABLE (
        BinIndex INT IDENTITY(1,1),
        ExpectedPct FLOAT,
        ActualPct FLOAT
    );
    
    -- Chèn dữ liệu từ chuỗi JSON vào bảng tạm - Sử dụng FULL OUTER JOIN để giữ tất cả bin
    INSERT INTO @Distribution (ExpectedPct, ActualPct)
    SELECT 
        ISNULL(j1.value, 0) AS ExpectedPct,
        ISNULL(j2.value, 0) AS ActualPct
    FROM OPENJSON(@EXPECTED_DISTRIBUTION) j1
    FULL OUTER JOIN OPENJSON(@ACTUAL_DISTRIBUTION) j2 ON j1.[key] = j2.[key];
    
    -- Tính toán PSI với xử lý cẩn thận hơn cho các giá trị nhỏ hoặc bằng 0
    SELECT @PSI = SUM(
        CASE
            -- Skip when either value is NULL
            WHEN ActualPct IS NULL OR ExpectedPct IS NULL THEN 0
            -- When both values are extremely small, contribute 0 to PSI
            WHEN ActualPct < @MIN_PERCENTAGE AND ExpectedPct < @MIN_PERCENTAGE THEN 0
            -- Handle potential numeric overflow
            WHEN ABS((ActualPct - ExpectedPct) * LOG(
                CASE 
                    WHEN ActualPct <= 0 THEN @MIN_PERCENTAGE
                    WHEN ExpectedPct <= 0 THEN ActualPct / @MIN_PERCENTAGE
                    WHEN ExpectedPct < @MIN_PERCENTAGE THEN ActualPct / @MIN_PERCENTAGE
                    ELSE ActualPct / ExpectedPct
                END)) > 100 THEN 
                SIGN((ActualPct - ExpectedPct)) * 100
            -- Normal calculation with protection
            ELSE (ActualPct - ExpectedPct) * LOG(
                CASE 
                    WHEN ActualPct <= 0 THEN @MIN_PERCENTAGE
                    WHEN ExpectedPct <= 0 THEN ActualPct / @MIN_PERCENTAGE
                    WHEN ExpectedPct < @MIN_PERCENTAGE THEN ActualPct / @MIN_PERCENTAGE
                    ELSE ActualPct / ExpectedPct
                END
            )
        END
    )
    FROM @Distribution;
    
    RETURN ISNULL(ABS(@PSI), 0);
END;
GO

-- Tạo function bổ sung để tính PSI từ 2 bảng dữ liệu
-- Lưu ý: Chúng ta cần sử dụng stored procedure thay vì function 
-- vì function không thể sử dụng bảng tạm (#temp tables)
IF OBJECT_ID('dbo.SP_CALCULATE_PSI_TABLES', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SP_CALCULATE_PSI_TABLES;
GO

CREATE PROCEDURE dbo.SP_CALCULATE_PSI_TABLES
    @MODEL_ID INT,
    @BASE_PERIOD_DATE DATE,
    @COMPARISON_PERIOD_DATE DATE,
    @NUM_BINS INT = 10,
    @PSI FLOAT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @BaseSQL NVARCHAR(MAX);
    DECLARE @ComparisonSQL NVARCHAR(MAX);
    DECLARE @SqlParams NVARCHAR(MAX);
    
    -- Lấy thông tin về mô hình
    DECLARE @SOURCE_DATABASE NVARCHAR(128);
    DECLARE @SOURCE_SCHEMA NVARCHAR(128);
    DECLARE @SOURCE_TABLE_NAME NVARCHAR(128);
    DECLARE @SCORE_COLUMN NVARCHAR(128) = 'SCORE'; -- Mặc định
    
    SELECT 
        @SOURCE_DATABASE = mr.SOURCE_DATABASE,
        @SOURCE_SCHEMA = mr.SOURCE_SCHEMA,
        @SOURCE_TABLE_NAME = mr.SOURCE_TABLE_NAME,
        -- Xác định cột điểm dựa trên loại mô hình
        @SCORE_COLUMN = CASE 
            WHEN mt.TYPE_CODE = 'EARLY_WARN' THEN 'WARNING_SCORE'
            ELSE 'SCORE'
        END
    FROM dbo.MODEL_REGISTRY mr
    JOIN dbo.MODEL_TYPE mt ON mr.TYPE_ID = mt.TYPE_ID
    WHERE mr.MODEL_ID = @MODEL_ID;
    
    -- Kiểm tra thông tin mô hình hợp lệ
    IF @SOURCE_DATABASE IS NULL OR @SOURCE_SCHEMA IS NULL OR @SOURCE_TABLE_NAME IS NULL
    BEGIN
        SET @PSI = 0;
        RETURN;
    END
    
    -- Tạo bảng tạm để lưu trữ phân phối điểm
    CREATE TABLE #BinResults (
        BinIndex INT,
        BinStart FLOAT,
        BinEnd FLOAT,
        BaseCount INT,
        BasePct FLOAT,
        ComparisonCount INT,
        ComparisonPct FLOAT,
        PSI FLOAT
    );
    
    -- Tìm min và max score để tạo bins
    DECLARE @MinScore FLOAT;
    DECLARE @MaxScore FLOAT;
    
    SET @SqlParams = N'@BaseDate DATE, @ComparisonDate DATE';
    
    SET @BaseSQL = N'
    SELECT 
        MIN(' + QUOTENAME(@SCORE_COLUMN) + ') AS MinScore,
        MAX(' + QUOTENAME(@SCORE_COLUMN) + ') AS MaxScore
    FROM ' + QUOTENAME(@SOURCE_DATABASE) + '.' + QUOTENAME(@SOURCE_SCHEMA) + '.' + QUOTENAME(@SOURCE_TABLE_NAME) + '
    WHERE PROCESS_DATE IN (@BaseDate, @ComparisonDate)';
    
    -- Tạo bảng tạm để lưu kết quả
    CREATE TABLE #ScoreRange (MinScore FLOAT, MaxScore FLOAT);
    
    -- Thực thi truy vấn với tham số
    INSERT INTO #ScoreRange
    EXEC sp_executesql @BaseSQL, @SqlParams, 
                      @BaseDate = @BASE_PERIOD_DATE, 
                      @ComparisonDate = @COMPARISON_PERIOD_DATE;
    
    -- Lấy giá trị min và max
    SELECT @MinScore = MinScore, @MaxScore = MaxScore FROM #ScoreRange;
    
    -- Kiểm tra phạm vi điểm hợp lệ
    IF @MinScore IS NULL OR @MaxScore IS NULL OR @MinScore >= @MaxScore
    BEGIN
        DROP TABLE #ScoreRange;
        DROP TABLE #BinResults;
        SET @PSI = 0;
        RETURN;
    END
    
    -- Tính kích thước bins
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
        INSERT INTO #BinResults (BinIndex, BinStart, BinEnd, BaseCount, BasePct, ComparisonCount, ComparisonPct)
        VALUES (@i, @MinScore + @i * @BinWidth, @MinScore + (@i + 1) * @BinWidth, 0, 0, 0, 0);
        
        SET @i = @i + 1;
    END;
    
    -- Thiết lập tham số cho truy vấn động
    SET @SqlParams = N'@BaseDate DATE, @MinScoreParam FLOAT, @MaxScoreParam FLOAT, @BinWidthParam FLOAT, @NumBinsParam INT';
    
    -- Tính toán phân phối cho kỳ cơ sở
    SET @BaseSQL = N'
    WITH ScoreBins AS (
        SELECT 
            CASE 
                WHEN ' + QUOTENAME(@SCORE_COLUMN) + ' >= @MaxScoreParam THEN @NumBinsParam - 1
                ELSE FLOOR((' + QUOTENAME(@SCORE_COLUMN) + ' - @MinScoreParam) / @BinWidthParam)
            END AS BinIndex,
            COUNT(*) AS BinCount
        FROM ' + QUOTENAME(@SOURCE_DATABASE) + '.' + QUOTENAME(@SOURCE_SCHEMA) + '.' + QUOTENAME(@SOURCE_TABLE_NAME) + '
        WHERE PROCESS_DATE = @BaseDate
        GROUP BY 
            CASE 
                WHEN ' + QUOTENAME(@SCORE_COLUMN) + ' >= @MaxScoreParam THEN @NumBinsParam - 1
                ELSE FLOOR((' + QUOTENAME(@SCORE_COLUMN) + ' - @MinScoreParam) / @BinWidthParam)
            END
    ),
    TotalCount AS (
        SELECT SUM(BinCount) AS Total FROM ScoreBins
    )
    SELECT 
        sb.BinIndex,
        sb.BinCount,
        CAST(sb.BinCount AS FLOAT) / NULLIF(tc.Total, 0) AS BinPct
    FROM ScoreBins sb
    CROSS JOIN TotalCount tc';
    
    -- Tạo bảng tạm để lưu kết quả
    CREATE TABLE #BaseDistribution (BinIndex INT, BinCount INT, BinPct FLOAT);
    
    -- Thực thi truy vấn với tham số
    EXEC sp_executesql @BaseSQL, @SqlParams, 
                      @BaseDate = @BASE_PERIOD_DATE, 
                      @MinScoreParam = @MinScore,
                      @MaxScoreParam = @MaxScore,
                      @BinWidthParam = @BinWidth,
                      @NumBinsParam = @NUM_BINS;
    
    -- Kiểm tra nếu không có dữ liệu cho kỳ cơ sở
    IF NOT EXISTS (SELECT 1 FROM #BaseDistribution)
    BEGIN
        DROP TABLE #ScoreRange;
        DROP TABLE #BaseDistribution;
        DROP TABLE #BinResults;
        SET @PSI = 0;
        RETURN;
    END
    
    -- Cập nhật kết quả cho kỳ cơ sở
    UPDATE br
    SET 
        BaseCount = ISNULL(bd.BinCount, 0),
        BasePct = ISNULL(bd.BinPct, 0)
    FROM #BinResults br
    LEFT JOIN #BaseDistribution bd ON br.BinIndex = bd.BinIndex;
    
    -- Tính toán phân phối cho kỳ so sánh
    -- Tạo bảng tạm để lưu kết quả
    CREATE TABLE #ComparisonDistribution (BinIndex INT, BinCount INT, BinPct FLOAT);
    
    -- Thực thi truy vấn với tham số cho kỳ so sánh
    EXEC sp_executesql @BaseSQL, @SqlParams, 
                      @BaseDate = @COMPARISON_PERIOD_DATE,
                      @MinScoreParam = @MinScore,
                      @MaxScoreParam = @MaxScore,
                      @BinWidthParam = @BinWidth,
                      @NumBinsParam = @NUM_BINS;
    
    -- Kiểm tra nếu không có dữ liệu cho kỳ so sánh
    IF NOT EXISTS (SELECT 1 FROM #ComparisonDistribution)
    BEGIN
        DROP TABLE #ScoreRange;
        DROP TABLE #BaseDistribution;
        DROP TABLE #ComparisonDistribution;
        DROP TABLE #BinResults;
        SET @PSI = 0;
        RETURN;
    END
    
    -- Cập nhật kết quả cho kỳ so sánh
    UPDATE br
    SET 
        ComparisonCount = ISNULL(cd.BinCount, 0),
        ComparisonPct = ISNULL(cd.BinPct, 0)
    FROM #BinResults br
    LEFT JOIN #ComparisonDistribution cd ON br.BinIndex = cd.BinIndex;
    
    -- Tính PSI cho từng bin với xử lý cẩn thận hơn cho các giá trị nhỏ
    DECLARE @MIN_PCT FLOAT = 0.000001; -- Giá trị tối thiểu để tránh chia cho 0
    
    UPDATE #BinResults
    SET PSI = 
        CASE 
            -- Khi cả hai tỷ lệ phần trăm đều rất nhỏ, đóng góp PSI là 0
            WHEN BasePct < @MIN_PCT AND ComparisonPct < @MIN_PCT THEN 0
            -- Khi tỷ lệ phần trăm cơ sở quá nhỏ, sử dụng giá trị tối thiểu
            WHEN BasePct < @MIN_PCT THEN 
                (ComparisonPct - @MIN_PCT) * LOG(ComparisonPct / @MIN_PCT)
            -- Khi tỷ lệ phần trăm so sánh quá nhỏ, sử dụng giá trị tối thiểu
            WHEN ComparisonPct < @MIN_PCT THEN 
                (@MIN_PCT - BasePct) * LOG(@MIN_PCT / BasePct)
            -- Xử lý trường hợp tràn số
            WHEN ABS((ComparisonPct - BasePct) * LOG(ComparisonPct / BasePct)) > 100 THEN
                SIGN((ComparisonPct - BasePct)) * 100
            -- Trường hợp bình thường
            ELSE (ComparisonPct - BasePct) * LOG(ComparisonPct / BasePct)
        END;
    
    -- Tính tổng PSI
    SELECT @PSI = SUM(ISNULL(PSI, 0)) 
    FROM #BinResults;
    
    -- Dọn dẹp
    DROP TABLE #ScoreRange;
    DROP TABLE #BaseDistribution;
    DROP TABLE #ComparisonDistribution;
    DROP TABLE #BinResults;
    
    -- Đảm bảo không trả về giá trị NULL hoặc PSI âm
    SET @PSI = CASE WHEN @PSI IS NULL OR @PSI < 0 THEN 0 ELSE @PSI END;
END;
GO

-- Tạo thêm một function wrapper để gọi stored procedure từ các truy vấn
IF OBJECT_ID('dbo.FN_GET_PSI_TABLES', 'FN') IS NOT NULL
    DROP FUNCTION dbo.FN_GET_PSI_TABLES;
GO

CREATE FUNCTION dbo.FN_GET_PSI_TABLES (
    @MODEL_ID INT,
    @BASE_PERIOD_DATE DATE,
    @COMPARISON_PERIOD_DATE DATE,
    @NUM_BINS INT = 10
)
RETURNS FLOAT
AS
BEGIN
    DECLARE @PSI FLOAT;
    
    -- Không thể gọi stored procedure trực tiếp từ function
    -- Đây chỉ là một function wrapper để dễ sử dụng
    -- Thực tế, người dùng nên gọi SP_CALCULATE_PSI_TABLES trực tiếp
    
    -- Giả lập trả về một kết quả để function hoạt động
    -- (Trong thực tế, cần gọi stored procedure từ bên ngoài)
    SET @PSI = -1; -- Giá trị đặc biệt để chỉ ra function này chỉ để chuyển đổi
    
    RETURN @PSI; -- Cần gọi SP_CALCULATE_PSI_TABLES trực tiếp
END;
GO

-- Thêm comment cho functions và stored procedures
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Tính toán chỉ số Population Stability Index từ 2 phân phối', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'FUNCTION',  @level1name = N'FN_CALCULATE_PSI';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Stored procedure tính toán chỉ số Population Stability Index từ 2 bảng dữ liệu', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'PROCEDURE',  @level1name = N'SP_CALCULATE_PSI_TABLES';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Function wrapper để gọi SP_CALCULATE_PSI_TABLES (chỉ dùng cho tương thích)', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'FUNCTION',  @level1name = N'FN_GET_PSI_TABLES';
GO

PRINT N'Function FN_CALCULATE_PSI, SP_CALCULATE_PSI_TABLES và FN_GET_PSI_TABLES đã được tạo thành công';
GO

-- Hướng dẫn sử dụng:
PRINT N'
-- Ví dụ cách sử dụng Function FN_CALCULATE_PSI:
DECLARE @expected NVARCHAR(MAX) = ''[0.1, 0.2, 0.3, 0.4]'';
DECLARE @actual NVARCHAR(MAX) = ''[0.12, 0.18, 0.35, 0.35]'';
SELECT dbo.FN_CALCULATE_PSI(@expected, @actual, 0.0001) AS PSI_Value;

-- Ví dụ cách sử dụng Stored Procedure SP_CALCULATE_PSI_TABLES:
DECLARE @result FLOAT;
EXEC dbo.SP_CALCULATE_PSI_TABLES 
    @MODEL_ID = 1, 
    @BASE_PERIOD_DATE = ''2025-01-01'', 
    @COMPARISON_PERIOD_DATE = ''2025-02-01'', 
    @NUM_BINS = 10, 
    @PSI = @result OUTPUT;
SELECT @result AS PSI_Result;';
GO