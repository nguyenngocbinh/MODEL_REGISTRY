/*
Tên file: 02_fn_calculate_psi.sql
Mô tả: Tạo function FN_CALCULATE_PSI để tính toán chỉ số Population Stability Index
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.0
*/

-- Kiểm tra nếu function đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.FN_CALCULATE_PSI', 'FN') IS NOT NULL
    DROP FUNCTION MODEL_REGISTRY.dbo.FN_CALCULATE_PSI;
GO

-- Tạo function FN_CALCULATE_PSI
CREATE FUNCTION MODEL_REGISTRY.dbo.FN_CALCULATE_PSI (
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
    
    -- Chèn dữ liệu từ chuỗi JSON vào bảng tạm
    INSERT INTO @Distribution (ExpectedPct, ActualPct)
    SELECT 
        j1.value AS ExpectedPct,
        j2.value AS ActualPct
    FROM OPENJSON(@EXPECTED_DISTRIBUTION) j1
    JOIN OPENJSON(@ACTUAL_DISTRIBUTION) j2 ON j1.[key] = j2.[key];
    
    -- Tính toán PSI
    SELECT @PSI = SUM(
        (ActualPct - ExpectedPct) * LOG(
            CASE 
                WHEN ActualPct <= 0 THEN @MIN_PERCENTAGE
                WHEN ExpectedPct <= 0 THEN ActualPct / @MIN_PERCENTAGE
                ELSE ActualPct / ExpectedPct
            END
        )
    )
    FROM @Distribution
    WHERE ExpectedPct IS NOT NULL
      AND ActualPct IS NOT NULL;
    
    RETURN ISNULL(ABS(@PSI), 0);
END;
GO

-- Tạo function bổ sung để tính PSI từ 2 bảng dữ liệu
CREATE FUNCTION MODEL_REGISTRY.dbo.FN_CALCULATE_PSI_TABLES (
    @MODEL_ID INT,
    @BASE_PERIOD_DATE DATE,
    @COMPARISON_PERIOD_DATE DATE,
    @NUM_BINS INT = 10
)
RETURNS FLOAT
AS
BEGIN
    DECLARE @PSI FLOAT = 0;
    DECLARE @BaseSQL NVARCHAR(MAX);
    DECLARE @ComparisonSQL NVARCHAR(MAX);
    
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
    FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
    JOIN MODEL_REGISTRY.dbo.MODEL_TYPE mt ON mr.TYPE_ID = mt.TYPE_ID
    WHERE mr.MODEL_ID = @MODEL_ID;
    
    -- Tạo bảng tạm để lưu trữ phân phối điểm
    DECLARE @BinResults TABLE (
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
    
    SET @BaseSQL = N'
    SELECT 
        MIN(' + QUOTENAME(@SCORE_COLUMN) + ') AS MinScore,
        MAX(' + QUOTENAME(@SCORE_COLUMN) + ') AS MaxScore
    FROM ' + QUOTENAME(@SOURCE_DATABASE) + '.' + QUOTENAME(@SOURCE_SCHEMA) + '.' + QUOTENAME(@SOURCE_TABLE_NAME) + '
    WHERE PROCESS_DATE IN (''' + CONVERT(VARCHAR, @BASE_PERIOD_DATE, 121) + ''', ''' + CONVERT(VARCHAR, @COMPARISON_PERIOD_DATE, 121) + ''')';
    
    -- Tạo bảng tạm để lưu kết quả
    CREATE TABLE #ScoreRange (MinScore FLOAT, MaxScore FLOAT);
    
    -- Thực thi truy vấn
    INSERT INTO #ScoreRange
    EXEC sp_executesql @BaseSQL;
    
    -- Lấy giá trị min và max
    SELECT @MinScore = MinScore, @MaxScore = MaxScore FROM #ScoreRange;
    
    -- Tính kích thước bins
    DECLARE @BinWidth FLOAT = (@MaxScore - @MinScore) / @NUM_BINS;
    
    -- Tạo các bins
    DECLARE @i INT = 0;
    WHILE @i < @NUM_BINS
    BEGIN
        INSERT INTO @BinResults (BinIndex, BinStart, BinEnd, BaseCount, BasePct, ComparisonCount, ComparisonPct)
        VALUES (@i, @MinScore + @i * @BinWidth, @MinScore + (@i + 1) * @BinWidth, 0, 0, 0, 0);
        
        SET @i = @i + 1;
    END;
    
    -- Tính toán phân phối cho kỳ cơ sở
    SET @BaseSQL = N'
    WITH ScoreBins AS (
        SELECT 
            CASE 
                WHEN ' + QUOTENAME(@SCORE_COLUMN) + ' >= ' + CAST(@MaxScore AS NVARCHAR) + ' THEN ' + CAST(@NUM_BINS - 1 AS NVARCHAR) + '
                ELSE FLOOR((' + QUOTENAME(@SCORE_COLUMN) + ' - ' + CAST(@MinScore AS NVARCHAR) + ') / ' + CAST(@BinWidth AS NVARCHAR) + ')
            END AS BinIndex,
            COUNT(*) AS BinCount
        FROM ' + QUOTENAME(@SOURCE_DATABASE) + '.' + QUOTENAME(@SOURCE_SCHEMA) + '.' + QUOTENAME(@SOURCE_TABLE_NAME) + '
        WHERE PROCESS_DATE = ''' + CONVERT(VARCHAR, @BASE_PERIOD_DATE, 121) + '''
        GROUP BY 
            CASE 
                WHEN ' + QUOTENAME(@SCORE_COLUMN) + ' >= ' + CAST(@MaxScore AS NVARCHAR) + ' THEN ' + CAST(@NUM_BINS - 1 AS NVARCHAR) + '
                ELSE FLOOR((' + QUOTENAME(@SCORE_COLUMN) + ' - ' + CAST(@MinScore AS NVARCHAR) + ') / ' + CAST(@BinWidth AS NVARCHAR) + ')
            END
    ),
    TotalCount AS (
        SELECT SUM(BinCount) AS Total FROM ScoreBins
    )
    SELECT 
        sb.BinIndex,
        sb.BinCount,
        CAST(sb.BinCount AS FLOAT) / tc.Total AS BinPct
    FROM ScoreBins sb
    CROSS JOIN TotalCount tc';
    
    -- Tạo bảng tạm để lưu kết quả
    CREATE TABLE #BaseDistribution (BinIndex INT, BinCount INT, BinPct FLOAT);
    
    -- Thực thi truy vấn
    INSERT INTO #BaseDistribution
    EXEC sp_executesql @BaseSQL;
    
    -- Cập nhật kết quả cho kỳ cơ sở
    UPDATE br
    SET 
        BaseCount = ISNULL(bd.BinCount, 0),
        BasePct = ISNULL(bd.BinPct, 0)
    FROM @BinResults br
    LEFT JOIN #BaseDistribution bd ON br.BinIndex = bd.BinIndex;
    
    -- Tính toán phân phối cho kỳ so sánh
    SET @ComparisonSQL = REPLACE(@BaseSQL, @BASE_PERIOD_DATE, @COMPARISON_PERIOD_DATE);
    
    -- Tạo bảng tạm để lưu kết quả
    CREATE TABLE #ComparisonDistribution (BinIndex INT, BinCount INT, BinPct FLOAT);
    
    -- Thực thi truy vấn
    INSERT INTO #ComparisonDistribution
    EXEC sp_executesql @ComparisonSQL;
    
    -- Cập nhật kết quả cho kỳ so sánh
    UPDATE br
    SET 
        ComparisonCount = ISNULL(cd.BinCount, 0),
        ComparisonPct = ISNULL(cd.BinPct, 0)
    FROM @BinResults br
    LEFT JOIN #ComparisonDistribution cd ON br.BinIndex = cd.BinIndex;
    
    -- Tính PSI cho từng bin
    UPDATE @BinResults
    SET PSI = 
        CASE 
            WHEN BasePct = 0 OR ComparisonPct = 0 THEN 0 -- Tránh lỗi chia cho 0
            ELSE (ComparisonPct - BasePct) * LOG(ComparisonPct / BasePct)
        END;
    
    -- Tính tổng PSI
    SELECT @PSI = SUM(PSI) 
    FROM @BinResults 
    WHERE BasePct > 0 AND ComparisonPct > 0;
    
    -- Dọn dẹp
    DROP TABLE #ScoreRange;
    DROP TABLE #BaseDistribution;
    DROP TABLE #ComparisonDistribution;
    
    RETURN ISNULL(@PSI, 0);
END;
GO

-- Thêm comment cho functions
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Tính toán chỉ số Population Stability Index từ 2 phân phối', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'FUNCTION',  @level1name = N'FN_CALCULATE_PSI';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Tính toán chỉ số Population Stability Index từ 2 bảng dữ liệu', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'FUNCTION',  @level1name = N'FN_CALCULATE_PSI_TABLES';
GO

PRINT 'Function FN_CALCULATE_PSI và FN_CALCULATE_PSI_TABLES đã được tạo thành công';
GO