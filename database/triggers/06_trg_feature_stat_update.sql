/*
Tên file: 06_trg_feature_stat_update.sql
Mô tả: Tạo trigger TRG_FEATURE_STAT_UPDATE để tự động cập nhật thống kê của đặc trưng
      khi có thay đổi trong dữ liệu làm mới hoặc giá trị đặc trưng
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-16
Phiên bản: 1.2 - Sửa lỗi bảng và column không tồn tại
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu trigger đã tồn tại thì xóa
IF OBJECT_ID('dbo.TRG_FEATURE_STAT_UPDATE', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TRG_FEATURE_STAT_UPDATE;
GO

-- Kiểm tra nếu bảng FEATURE_REFRESH_LOG không tồn tại thì tạo mới
IF OBJECT_ID('MODEL_REGISTRY.dbo.FEATURE_REFRESH_LOG', 'U') IS NULL
BEGIN
    CREATE TABLE MODEL_REGISTRY.dbo.FEATURE_REFRESH_LOG (
        REFRESH_ID INT IDENTITY(1,1) PRIMARY KEY,
        FEATURE_ID INT NOT NULL,
        REFRESH_BATCH_ID NVARCHAR(50) NULL,
        REFRESH_START_TIME DATETIME NOT NULL DEFAULT GETDATE(),
        REFRESH_END_TIME DATETIME NULL,
        REFRESH_STATUS NVARCHAR(20) NOT NULL, -- 'STARTED', 'COMPLETED', 'FAILED', 'PARTIAL'
        REFRESH_TYPE NVARCHAR(50) NOT NULL, -- 'FULL', 'INCREMENTAL', 'DELTA', 'RESTATEMENT'
        RECORDS_PROCESSED INT NULL,
        RECORDS_UPDATED INT NULL,
        FEATURE_NEW_STATS NVARCHAR(MAX) NULL, -- JSON string với thống kê mới
        CREATED_BY NVARCHAR(50) DEFAULT SUSER_NAME(),
        CREATED_DATE DATETIME DEFAULT GETDATE(),
        FOREIGN KEY (FEATURE_ID) REFERENCES MODEL_REGISTRY.dbo.FEATURE_REGISTRY(FEATURE_ID)
    );
    
    CREATE INDEX IDX_FEATURE_REFRESH_FEATURE_ID ON MODEL_REGISTRY.dbo.FEATURE_REFRESH_LOG(FEATURE_ID);
    CREATE INDEX IDX_FEATURE_REFRESH_STATUS ON MODEL_REGISTRY.dbo.FEATURE_REFRESH_LOG(REFRESH_STATUS);
    
    PRINT N'Đã tạo bảng FEATURE_REFRESH_LOG để lưu lịch sử làm mới đặc trưng';
END
GO

-- Kiểm tra xem column FEATURE_IMPORTANCE có tồn tại trong bảng FEATURE_REGISTRY hay không
-- Nếu không tồn tại, thêm cột này vào
IF NOT EXISTS (
    SELECT 1 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID('MODEL_REGISTRY.dbo.FEATURE_REGISTRY') 
    AND name = 'FEATURE_IMPORTANCE'
)
BEGIN
    ALTER TABLE MODEL_REGISTRY.dbo.FEATURE_REGISTRY 
    ADD FEATURE_IMPORTANCE FLOAT NULL;
    
    PRINT N'Đã thêm cột FEATURE_IMPORTANCE vào bảng FEATURE_REGISTRY';
END
GO

-- Tạo trigger TRG_FEATURE_STAT_UPDATE cho bảng FEATURE_REFRESH_LOG
CREATE TRIGGER dbo.TRG_FEATURE_STAT_UPDATE
ON MODEL_REGISTRY.dbo.FEATURE_REFRESH_LOG
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Chỉ xử lý các bản ghi có trạng thái là COMPLETED
    IF NOT EXISTS (SELECT 1 FROM inserted WHERE REFRESH_STATUS = 'COMPLETED')
        RETURN;
    
    -- Biến tạm để lưu trữ các đặc trưng cần cập nhật thống kê
    DECLARE @FeaturesToUpdate TABLE (
        FEATURE_ID INT,
        REFRESH_BATCH_ID NVARCHAR(50) NULL,
        FEATURE_NEW_STATS NVARCHAR(MAX)
    );
    
    -- Lấy các đặc trưng cần cập nhật từ bản ghi mới
    INSERT INTO @FeaturesToUpdate (FEATURE_ID, REFRESH_BATCH_ID, FEATURE_NEW_STATS)
    SELECT 
        i.FEATURE_ID,
        i.REFRESH_BATCH_ID,
        i.FEATURE_NEW_STATS
    FROM inserted i
    WHERE i.REFRESH_STATUS = 'COMPLETED'
      AND i.FEATURE_ID IS NOT NULL     -- Chỉ xử lý các bản ghi có FEATURE_ID
      AND i.FEATURE_NEW_STATS IS NOT NULL; -- Và có thống kê mới
    
    -- Nếu không có đặc trưng nào cần cập nhật, thoát
    IF NOT EXISTS (SELECT 1 FROM @FeaturesToUpdate)
        RETURN;
    
    -- Cập nhật thống kê cho từng đặc trưng
    MERGE MODEL_REGISTRY.dbo.FEATURE_STATS AS target
    USING (
        SELECT 
            f.FEATURE_ID,
            JSON_VALUE(f.FEATURE_NEW_STATS, '$.calculation_date') AS CALCULATION_DATE,
            JSON_VALUE(f.FEATURE_NEW_STATS, '$.sample_size') AS SAMPLE_SIZE,
            JSON_VALUE(f.FEATURE_NEW_STATS, '$.min_value') AS MIN_VALUE,
            JSON_VALUE(f.FEATURE_NEW_STATS, '$.max_value') AS MAX_VALUE,
            JSON_VALUE(f.FEATURE_NEW_STATS, '$.mean') AS MEAN,
            JSON_VALUE(f.FEATURE_NEW_STATS, '$.median') AS MEDIAN,
            JSON_VALUE(f.FEATURE_NEW_STATS, '$.mode') AS MODE,
            JSON_VALUE(f.FEATURE_NEW_STATS, '$.std_deviation') AS STD_DEVIATION,
            JSON_VALUE(f.FEATURE_NEW_STATS, '$.variance') AS VARIANCE,
            JSON_VALUE(f.FEATURE_NEW_STATS, '$.missing_ratio') AS MISSING_RATIO,
            JSON_VALUE(f.FEATURE_NEW_STATS, '$.information_value') AS INFORMATION_VALUE,
            JSON_VALUE(f.FEATURE_NEW_STATS, '$.stability_index') AS STABILITY_INDEX,
            JSON_VALUE(f.FEATURE_NEW_STATS, '$.target_correlation') AS TARGET_CORRELATION,
            JSON_VALUE(f.FEATURE_NEW_STATS, '$.has_outliers') AS HAS_OUTLIERS,
            JSON_VALUE(f.FEATURE_NEW_STATS, '$.unique_values') AS UNIQUE_VALUES
        FROM @FeaturesToUpdate f
        WHERE ISJSON(f.FEATURE_NEW_STATS) = 1  -- Đảm bảo đây là JSON hợp lệ
    ) AS source
    ON (target.FEATURE_ID = source.FEATURE_ID)
    WHEN MATCHED THEN
        UPDATE SET
            CALCULATION_DATE = COALESCE(TRY_CONVERT(DATE, source.CALCULATION_DATE), GETDATE()),
            SAMPLE_SIZE = COALESCE(TRY_CONVERT(INT, source.SAMPLE_SIZE), target.SAMPLE_SIZE),
            MIN_VALUE = COALESCE(TRY_CONVERT(FLOAT, source.MIN_VALUE), target.MIN_VALUE),
            MAX_VALUE = COALESCE(TRY_CONVERT(FLOAT, source.MAX_VALUE), target.MAX_VALUE),
            MEAN = COALESCE(TRY_CONVERT(FLOAT, source.MEAN), target.MEAN),
            MEDIAN = COALESCE(TRY_CONVERT(FLOAT, source.MEDIAN), target.MEDIAN),
            MODE = COALESCE(source.MODE, target.MODE),
            STD_DEVIATION = COALESCE(TRY_CONVERT(FLOAT, source.STD_DEVIATION), target.STD_DEVIATION),
            VARIANCE = COALESCE(TRY_CONVERT(FLOAT, source.VARIANCE), target.VARIANCE),
            MISSING_RATIO = COALESCE(TRY_CONVERT(FLOAT, source.MISSING_RATIO), target.MISSING_RATIO),
            INFORMATION_VALUE = COALESCE(TRY_CONVERT(FLOAT, source.INFORMATION_VALUE), target.INFORMATION_VALUE),
            STABILITY_INDEX = COALESCE(TRY_CONVERT(FLOAT, source.STABILITY_INDEX), target.STABILITY_INDEX),
            TARGET_CORRELATION = COALESCE(TRY_CONVERT(FLOAT, source.TARGET_CORRELATION), target.TARGET_CORRELATION),
            HAS_OUTLIERS = COALESCE(TRY_CONVERT(BIT, source.HAS_OUTLIERS), target.HAS_OUTLIERS),
            UNIQUE_VALUES = COALESCE(TRY_CONVERT(INT, source.UNIQUE_VALUES), target.UNIQUE_VALUES),
            IS_ACTIVE = 1,
            UPDATED_BY = SUSER_SNAME(),
            UPDATED_DATE = GETDATE()
    WHEN NOT MATCHED THEN
        INSERT (
            FEATURE_ID,
            CALCULATION_DATE,
            SAMPLE_SIZE,
            MIN_VALUE,
            MAX_VALUE,
            MEAN,
            MEDIAN,
            MODE,
            STD_DEVIATION,
            VARIANCE,
            MISSING_RATIO,
            INFORMATION_VALUE,
            STABILITY_INDEX,
            TARGET_CORRELATION,
            HAS_OUTLIERS,
            UNIQUE_VALUES,
            IS_ACTIVE,
            CREATED_BY,
            CREATED_DATE
        )
        VALUES (
            source.FEATURE_ID,
            COALESCE(TRY_CONVERT(DATE, source.CALCULATION_DATE), GETDATE()),
            COALESCE(TRY_CONVERT(INT, source.SAMPLE_SIZE), 0),
            TRY_CONVERT(FLOAT, source.MIN_VALUE),
            TRY_CONVERT(FLOAT, source.MAX_VALUE),
            TRY_CONVERT(FLOAT, source.MEAN),
            TRY_CONVERT(FLOAT, source.MEDIAN),
            source.MODE,
            TRY_CONVERT(FLOAT, source.STD_DEVIATION),
            TRY_CONVERT(FLOAT, source.VARIANCE),
            TRY_CONVERT(FLOAT, source.MISSING_RATIO),
            TRY_CONVERT(FLOAT, source.INFORMATION_VALUE),
            TRY_CONVERT(FLOAT, source.STABILITY_INDEX),
            TRY_CONVERT(FLOAT, source.TARGET_CORRELATION),
            TRY_CONVERT(BIT, source.HAS_OUTLIERS),
            TRY_CONVERT(INT, source.UNIQUE_VALUES),
            1,
            SUSER_SNAME(),
            GETDATE()
        );
    
    -- Cập nhật thông tin FEATURE_IMPORTANCE trong bảng FEATURE_REGISTRY
    -- Chỉ chạy đoạn này nếu cột FEATURE_IMPORTANCE tồn tại
    IF EXISTS (
        SELECT 1 
        FROM sys.columns 
        WHERE object_id = OBJECT_ID('MODEL_REGISTRY.dbo.FEATURE_REGISTRY') 
        AND name = 'FEATURE_IMPORTANCE'
    )
    BEGIN
        UPDATE fr
        SET 
            FEATURE_IMPORTANCE = CASE 
                WHEN fs.INFORMATION_VALUE IS NOT NULL AND fs.INFORMATION_VALUE > 0 THEN
                    CASE
                        -- Information Value (IV) thang đánh giá:
                        -- < 0.02: Không có giá trị dự báo
                        -- 0.02 to 0.1: Giá trị dự báo yếu
                        -- 0.1 to 0.3: Giá trị dự báo trung bình
                        -- > 0.3: Giá trị dự báo mạnh
                        WHEN fs.INFORMATION_VALUE > 0.3 THEN 0.9
                        WHEN fs.INFORMATION_VALUE > 0.1 THEN 0.7
                        WHEN fs.INFORMATION_VALUE > 0.02 THEN 0.4
                        ELSE 0.1
                    END
                WHEN fs.TARGET_CORRELATION IS NOT NULL AND ABS(fs.TARGET_CORRELATION) > 0 THEN
                    ABS(fs.TARGET_CORRELATION) -- Sử dụng tương quan (giá trị tuyệt đối)
                ELSE fr.FEATURE_IMPORTANCE -- Giữ nguyên giá trị hiện tại nếu không có thông tin mới
            END,
            UPDATED_BY = SUSER_SNAME(),
            UPDATED_DATE = GETDATE()
        FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY fr
        JOIN MODEL_REGISTRY.dbo.FEATURE_STATS fs ON fr.FEATURE_ID = fs.FEATURE_ID
        WHERE fr.FEATURE_ID IN (SELECT FEATURE_ID FROM @FeaturesToUpdate)
          AND (fs.INFORMATION_VALUE IS NOT NULL OR fs.TARGET_CORRELATION IS NOT NULL);
    END
    
    -- Cập nhật bảng FEATURE_VALUES dựa trên thống kê mới nếu có
    -- Đây là một quy trình phức tạp và phụ thuộc vào cấu trúc của FEATURE_NEW_STATS
    -- Ví dụ cơ bản:
    BEGIN TRY
        -- Lấy thông tin chi tiết về phân phối từ JSON và cập nhật vào FEATURE_VALUES
        MERGE MODEL_REGISTRY.dbo.FEATURE_VALUES AS target
        USING (
            SELECT 
                f.FEATURE_ID,
                v.[key] AS BUCKET_ORDER,
                JSON_VALUE(v.[value], '$.value_label') AS VALUE_LABEL,
                JSON_VALUE(v.[value], '$.min_value') AS MIN_VALUE,
                JSON_VALUE(v.[value], '$.max_value') AS MAX_VALUE,
                JSON_VALUE(v.[value], '$.frequency') AS FREQUENCY,
                JSON_VALUE(v.[value], '$.woe') AS WOE,
                JSON_VALUE(v.[value], '$.iv_contribution') AS IV_CONTRIBUTION,
                JSON_VALUE(v.[value], '$.event_rate') AS EVENT_RATE
            FROM @FeaturesToUpdate f
            CROSS APPLY OPENJSON(JSON_QUERY(f.FEATURE_NEW_STATS, '$.distribution')) v
            WHERE ISJSON(f.FEATURE_NEW_STATS) = 1 
              AND JSON_QUERY(f.FEATURE_NEW_STATS, '$.distribution') IS NOT NULL
        ) AS source
        ON (
            target.FEATURE_ID = source.FEATURE_ID 
            AND target.BUCKET_ORDER = TRY_CONVERT(INT, source.BUCKET_ORDER)
        )
        WHEN MATCHED THEN
            UPDATE SET
                VALUE_LABEL = COALESCE(source.VALUE_LABEL, target.VALUE_LABEL),
                MIN_VALUE = COALESCE(source.MIN_VALUE, target.MIN_VALUE),
                MAX_VALUE = COALESCE(source.MAX_VALUE, target.MAX_VALUE),
                FREQUENCY = COALESCE(TRY_CONVERT(FLOAT, source.FREQUENCY), target.FREQUENCY),
                WOE = COALESCE(TRY_CONVERT(FLOAT, source.WOE), target.WOE),
                IV_CONTRIBUTION = COALESCE(TRY_CONVERT(FLOAT, source.IV_CONTRIBUTION), target.IV_CONTRIBUTION),
                EVENT_RATE = COALESCE(TRY_CONVERT(FLOAT, source.EVENT_RATE), target.EVENT_RATE),
                UPDATED_BY = SUSER_SNAME(),
                UPDATED_DATE = GETDATE()
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                FEATURE_ID,
                VALUE_TYPE,
                VALUE_LABEL,
                MIN_VALUE,
                MAX_VALUE,
                FREQUENCY,
                WOE,
                IV_CONTRIBUTION,
                EVENT_RATE,
                BUCKET_ORDER,
                CREATED_BY,
                CREATED_DATE
            )
            VALUES (
                source.FEATURE_ID,
                'NUMERIC_BUCKET', -- Mặc định
                COALESCE(source.VALUE_LABEL, 'Bucket ' + source.BUCKET_ORDER),
                source.MIN_VALUE,
                source.MAX_VALUE,
                TRY_CONVERT(FLOAT, source.FREQUENCY),
                TRY_CONVERT(FLOAT, source.WOE),
                TRY_CONVERT(FLOAT, source.IV_CONTRIBUTION),
                TRY_CONVERT(FLOAT, source.EVENT_RATE),
                TRY_CONVERT(INT, source.BUCKET_ORDER),
                SUSER_SNAME(),
                GETDATE()
            );
    END TRY
    BEGIN CATCH
        -- Ghi log lỗi nếu cần
        PRINT N'Lỗi khi cập nhật FEATURE_VALUES: ' + ERROR_MESSAGE();
    END CATCH;
    
    -- Kiểm tra và tạo bản ghi vấn đề chất lượng dữ liệu nếu cần
    -- Ví dụ: Phát hiện tỷ lệ giá trị bị thiếu cao
    IF EXISTS (
        SELECT 1 
        FROM MODEL_REGISTRY.dbo.FEATURE_STATS fs
        JOIN @FeaturesToUpdate f ON fs.FEATURE_ID = f.FEATURE_ID
        WHERE fs.MISSING_RATIO > 0.3 -- Tỷ lệ giá trị bị thiếu > 30%
    )
    BEGIN
        -- Lấy thông tin bảng nguồn của đặc trưng
        WITH FeatureSourceInfo AS (
            SELECT 
                fs.FEATURE_ID,
                fst.SOURCE_TABLE_ID,
                fst.SOURCE_COLUMN_NAME,
                fs.MISSING_RATIO
            FROM MODEL_REGISTRY.dbo.FEATURE_STATS fs
            JOIN @FeaturesToUpdate f ON fs.FEATURE_ID = f.FEATURE_ID
            JOIN MODEL_REGISTRY.dbo.FEATURE_SOURCE_TABLES fst ON fs.FEATURE_ID = fst.FEATURE_ID
            WHERE fs.MISSING_RATIO > 0.3
              AND fst.IS_PRIMARY_SOURCE = 1
        )
        -- Ghi nhật ký vấn đề chất lượng dữ liệu
        INSERT INTO MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG (
            SOURCE_TABLE_ID,
            COLUMN_ID,
            PROCESS_DATE,
            ISSUE_TYPE,
            ISSUE_DESCRIPTION,
            ISSUE_CATEGORY,
            SEVERITY,
            PERCENTAGE_AFFECTED,
            IMPACT_DESCRIPTION,
            DETECTION_METHOD,
            REMEDIATION_STATUS,
            CREATED_BY,
            CREATED_DATE
        )
        SELECT 
            fsi.SOURCE_TABLE_ID,
            cd.COLUMN_ID,
            GETDATE(),
            'MISSING_DATA',
            'Phát hiện tỷ lệ giá trị bị thiếu cao (' + CAST(ROUND(fsi.MISSING_RATIO * 100, 2) AS NVARCHAR) + '%) cho đặc trưng ' + fr.FEATURE_NAME,
            'DATA_COMPLETENESS',
            CASE 
                WHEN fsi.MISSING_RATIO > 0.5 THEN 'HIGH' 
                ELSE 'MEDIUM' 
            END,
            fsi.MISSING_RATIO * 100,
            'Tỷ lệ giá trị bị thiếu cao có thể ảnh hưởng đến hiệu suất của mô hình.',
            'AUTOMATIC_STATS_ANALYSIS',
            'OPEN',
            SUSER_SNAME(),
            GETDATE()
        FROM FeatureSourceInfo fsi
        JOIN MODEL_REGISTRY.dbo.FEATURE_REGISTRY fr ON fsi.FEATURE_ID = fr.FEATURE_ID
        JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON fsi.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
        LEFT JOIN MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd ON st.SOURCE_TABLE_ID = cd.SOURCE_TABLE_ID AND fsi.SOURCE_COLUMN_NAME = cd.COLUMN_NAME
        WHERE NOT EXISTS (
            -- Kiểm tra xem đã có bản ghi cho vấn đề này trong 7 ngày qua chưa
            SELECT 1 
            FROM MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG dq
            WHERE dq.SOURCE_TABLE_ID = fsi.SOURCE_TABLE_ID
              AND (dq.COLUMN_ID = cd.COLUMN_ID OR (dq.COLUMN_ID IS NULL AND cd.COLUMN_ID IS NULL))
              AND dq.ISSUE_TYPE = 'MISSING_DATA'
              AND dq.PROCESS_DATE > DATEADD(DAY, -7, GETDATE())
              AND dq.REMEDIATION_STATUS IN ('OPEN', 'IN_PROGRESS')
        );
    END
    
    -- Kiểm tra và cập nhật thang đánh giá đặc trưng
    -- Phát hiện đặc trưng không ổn định (PSI cao)
    IF EXISTS (
        SELECT 1 
        FROM MODEL_REGISTRY.dbo.FEATURE_STATS fs
        JOIN @FeaturesToUpdate f ON fs.FEATURE_ID = f.FEATURE_ID
        WHERE fs.STABILITY_INDEX > 0.25 -- PSI > 0.25 cho thấy đặc trưng không ổn định
    )
    BEGIN
        -- Ghi nhật ký vấn đề chất lượng dữ liệu cho đặc trưng không ổn định
        WITH UnstableFeatures AS (
            SELECT 
                fs.FEATURE_ID,
                fst.SOURCE_TABLE_ID,
                fst.SOURCE_COLUMN_NAME,
                fs.STABILITY_INDEX
            FROM MODEL_REGISTRY.dbo.FEATURE_STATS fs
            JOIN @FeaturesToUpdate f ON fs.FEATURE_ID = f.FEATURE_ID
            JOIN MODEL_REGISTRY.dbo.FEATURE_SOURCE_TABLES fst ON fs.FEATURE_ID = fst.FEATURE_ID
            WHERE fs.STABILITY_INDEX > 0.25
              AND fst.IS_PRIMARY_SOURCE = 1
        )
        INSERT INTO MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG (
            SOURCE_TABLE_ID,
            COLUMN_ID,
            PROCESS_DATE,
            ISSUE_TYPE,
            ISSUE_DESCRIPTION,
            ISSUE_CATEGORY,
            SEVERITY,
            PERCENTAGE_AFFECTED,
            IMPACT_DESCRIPTION,
            DETECTION_METHOD,
            REMEDIATION_STATUS,
            CREATED_BY,
            CREATED_DATE
        )
        SELECT 
            uf.SOURCE_TABLE_ID,
            cd.COLUMN_ID,
            GETDATE(),
            'FEATURE_INSTABILITY',
            'Phát hiện đặc trưng không ổn định (PSI = ' + CAST(ROUND(uf.STABILITY_INDEX, 2) AS NVARCHAR) + ') cho ' + fr.FEATURE_NAME,
            'DATA_STABILITY',
            CASE 
                WHEN uf.STABILITY_INDEX > 0.5 THEN 'CRITICAL' 
                WHEN uf.STABILITY_INDEX > 0.35 THEN 'HIGH'
                ELSE 'MEDIUM' 
            END,
            100, -- Ảnh hưởng đến toàn bộ phân phối
            'Đặc trưng không ổn định giữa các thời kỳ có thể làm giảm hiệu suất dự báo của mô hình.',
            'AUTOMATIC_STATS_ANALYSIS',
            'OPEN',
            SUSER_SNAME(),
            GETDATE()
        FROM UnstableFeatures uf
        JOIN MODEL_REGISTRY.dbo.FEATURE_REGISTRY fr ON uf.FEATURE_ID = fr.FEATURE_ID
        JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON uf.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
        LEFT JOIN MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd ON st.SOURCE_TABLE_ID = cd.SOURCE_TABLE_ID AND uf.SOURCE_COLUMN_NAME = cd.COLUMN_NAME
        WHERE NOT EXISTS (
            -- Kiểm tra xem đã có bản ghi cho vấn đề này trong 30 ngày qua chưa
            SELECT 1 
            FROM MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG dq
            WHERE dq.SOURCE_TABLE_ID = uf.SOURCE_TABLE_ID
              AND (dq.COLUMN_ID = cd.COLUMN_ID OR (dq.COLUMN_ID IS NULL AND cd.COLUMN_ID IS NULL))
              AND dq.ISSUE_TYPE = 'FEATURE_INSTABILITY'
              AND dq.PROCESS_DATE > DATEADD(DAY, -30, GETDATE())
              AND dq.REMEDIATION_STATUS IN ('OPEN', 'IN_PROGRESS')
        );
        
        -- Cập nhật trạng thái các mô hình bị ảnh hưởng bởi đặc trưng không ổn định
        -- Kiểm tra xem bảng MODEL_REGISTRY có tồn tại hay không
        IF OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_REGISTRY', 'U') IS NOT NULL
        BEGIN
            -- Kiểm tra xem bảng FEATURE_MODEL_MAPPING và cột FEATURE_IMPORTANCE có tồn tại không
            IF OBJECT_ID('MODEL_REGISTRY.dbo.FEATURE_MODEL_MAPPING', 'U') IS NOT NULL
            AND EXISTS (
                SELECT 1 
                FROM sys.columns 
                WHERE object_id = OBJECT_ID('MODEL_REGISTRY.dbo.FEATURE_MODEL_MAPPING') 
                AND name = 'FEATURE_IMPORTANCE'
            )
            BEGIN
                UPDATE mr
                SET 
                    MODEL_STATUS = 'NEEDS_REVIEW',
                    UPDATED_BY = SUSER_SNAME(),
                    UPDATED_DATE = GETDATE()
                FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
                JOIN MODEL_REGISTRY.dbo.FEATURE_MODEL_MAPPING fmm ON mr.MODEL_ID = fmm.MODEL_ID
                JOIN MODEL_REGISTRY.dbo.FEATURE_STATS fs ON fmm.FEATURE_ID = fs.FEATURE_ID
                JOIN @FeaturesToUpdate f ON fs.FEATURE_ID = f.FEATURE_ID
                WHERE fs.STABILITY_INDEX > 0.25 -- Đặc trưng không ổn định
                  AND fmm.FEATURE_IMPORTANCE > 0.5 -- Đặc trưng quan trọng đối với mô hình
                  AND fmm.IS_ACTIVE = 1
                  AND mr.IS_ACTIVE = 1
                  AND mr.MODEL_STATUS = 'ACTIVE'; -- Chỉ cập nhật nếu mô hình đang hoạt động
            END
        END
    END
END;
GO

PRINT N'Trigger TRG_FEATURE_STAT_UPDATE đã được tạo thành công';
GO