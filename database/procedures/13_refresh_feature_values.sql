/*
Tên file: 13_refresh_feature_values.sql
Mô tả: Tạo stored procedure REFRESH_FEATURE_VALUES để cập nhật giá trị của đặc trưng
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-15
Phiên bản: 1.0
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu proc đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.REFRESH_FEATURE_VALUES', 'P') IS NOT NULL
    DROP PROCEDURE dbo.REFRESH_FEATURE_VALUES;
GO

-- Tạo stored procedure REFRESH_FEATURE_VALUES
CREATE PROCEDURE dbo.REFRESH_FEATURE_VALUES
    @SOURCE_DATABASE NVARCHAR(128),
    @SOURCE_SCHEMA NVARCHAR(128),
    @SOURCE_TABLE_NAME NVARCHAR(128),
    @COLUMN_NAME NVARCHAR(128) = NULL, -- Nếu NULL thì cập nhật tất cả các đặc trưng trong bảng
    @PROCESS_DATE DATE = NULL,
    @REFRESH_TYPE NVARCHAR(50) = 'FULL', -- 'FULL', 'INCREMENTAL', 'DELTA', 'RESTATEMENT'
    @REFRESH_METHOD NVARCHAR(50) = 'MANUAL', -- 'ETL', 'MANUAL', 'SCHEDULED'
    @RECORDS_PROCESSED INT = NULL,
    @RECORDS_INSERTED INT = NULL,
    @RECORDS_UPDATED INT = NULL,
    @RECORDS_DELETED INT = NULL,
    @RECORDS_REJECTED INT = NULL,
    @DATA_VOLUME_MB DECIMAL(10,2) = NULL,
    @STATS_JSON NVARCHAR(MAX) = NULL, -- JSON chứa thống kê cho các đặc trưng
    @AUTO_DETECT_QUALITY_ISSUES BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Xử lý tham số mặc định
    IF @PROCESS_DATE IS NULL
        SET @PROCESS_DATE = GETDATE();
        
    -- Xác thực đầu vào
    IF @SOURCE_DATABASE IS NULL OR @SOURCE_SCHEMA IS NULL OR @SOURCE_TABLE_NAME IS NULL
    BEGIN
        RAISERROR(N'Phải cung cấp đầy đủ thông tin bảng: SOURCE_DATABASE, SOURCE_SCHEMA, và SOURCE_TABLE_NAME', 16, 1);
        RETURN;
    END
    
    -- Lấy thông tin bảng nguồn
    DECLARE @SOURCE_TABLE_ID INT;
    
    SELECT @SOURCE_TABLE_ID = SOURCE_TABLE_ID
    FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES
    WHERE SOURCE_DATABASE = @SOURCE_DATABASE
    AND SOURCE_SCHEMA = @SOURCE_SCHEMA
    AND SOURCE_TABLE_NAME = @SOURCE_TABLE_NAME;
    
    IF @SOURCE_TABLE_ID IS NULL
    BEGIN
        RAISERROR(N'Bảng %s.%s.%s không tồn tại trong registry', 16, 1, @SOURCE_DATABASE, @SOURCE_SCHEMA, @SOURCE_TABLE_NAME);
        RETURN;
    END
    
    -- Bắt đầu giao dịch
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Bước 1: Ghi nhật ký bắt đầu cập nhật dữ liệu
        EXEC MODEL_REGISTRY.dbo.LOG_SOURCE_TABLE_REFRESH
            @SOURCE_DATABASE = @SOURCE_DATABASE,
            @SOURCE_SCHEMA = @SOURCE_SCHEMA,
            @SOURCE_TABLE_NAME = @SOURCE_TABLE_NAME,
            @PROCESS_DATE = @PROCESS_DATE,
            @REFRESH_STATUS = 'STARTED',
            @REFRESH_TYPE = @REFRESH_TYPE,
            @REFRESH_METHOD = @REFRESH_METHOD;
            
        -- Bước 2: Xử lý thống kê cho từng đặc trưng nếu có
        IF @STATS_JSON IS NOT NULL
        BEGIN
            -- Kiểm tra xem JSON có hợp lệ không
            IF ISJSON(@STATS_JSON) = 0
            BEGIN
                RAISERROR(N'STATS_JSON không phải là chuỗi JSON hợp lệ', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END
            
            -- Tạo bảng tạm để lưu thống kê từng cột
            CREATE TABLE #ColumnStats (
                COLUMN_NAME NVARCHAR(128),
                FEATURE_IMPORTANCE FLOAT,
                NULL_PERCENTAGE FLOAT,
                UNIQUE_VALUES INT,
                DUPLICATES_PERCENTAGE FLOAT,
                OUTLIERS_PERCENTAGE FLOAT,
                INVALID_VALUES_PERCENTAGE FLOAT,
                TOTAL_RECORDS INT
            );
            
            -- Phân tích dữ liệu JSON
            INSERT INTO #ColumnStats
            SELECT 
                [key] AS COLUMN_NAME,
                JSON_VALUE(value, '$.feature_importance') AS FEATURE_IMPORTANCE,
                JSON_VALUE(value, '$.null_percentage') AS NULL_PERCENTAGE,
                JSON_VALUE(value, '$.unique_values') AS UNIQUE_VALUES,
                JSON_VALUE(value, '$.duplicates_percentage') AS DUPLICATES_PERCENTAGE,
                JSON_VALUE(value, '$.outliers_percentage') AS OUTLIERS_PERCENTAGE,
                JSON_VALUE(value, '$.invalid_values_percentage') AS INVALID_VALUES_PERCENTAGE,
                JSON_VALUE(value, '$.total_records') AS TOTAL_RECORDS
            FROM OPENJSON(@STATS_JSON);
            
            -- Xử lý từng cột
            DECLARE @CurrColumnName NVARCHAR(128);
            DECLARE @CurrFeatureImportance FLOAT;
            DECLARE @CurrStatsJSON NVARCHAR(MAX);
            
            DECLARE columns_cursor CURSOR FOR
            SELECT 
                COLUMN_NAME,
                FEATURE_IMPORTANCE,
                (
                    SELECT 
                        NULL_PERCENTAGE AS [null_percentage],
                        UNIQUE_VALUES AS [unique_values],
                        DUPLICATES_PERCENTAGE AS [duplicates_percentage],
                        OUTLIERS_PERCENTAGE AS [outliers_percentage],
                        INVALID_VALUES_PERCENTAGE AS [invalid_values_percentage],
                        TOTAL_RECORDS AS [total_records]
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ) AS STATS_JSON
            FROM #ColumnStats
            WHERE (@COLUMN_NAME IS NULL OR COLUMN_NAME = @COLUMN_NAME);
            
            OPEN columns_cursor;
            FETCH NEXT FROM columns_cursor INTO @CurrColumnName, @CurrFeatureImportance, @CurrStatsJSON;
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- Tìm COLUMN_ID
                DECLARE @CurrColumnID INT;
                
                SELECT @CurrColumnID = COLUMN_ID
                FROM MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS
                WHERE SOURCE_TABLE_ID = @SOURCE_TABLE_ID
                  AND COLUMN_NAME = @CurrColumnName;
                  
                -- Nếu cột tồn tại, cập nhật thống kê
                IF @CurrColumnID IS NOT NULL
                BEGIN
                    -- Sử dụng stored procedure UPDATE_FEATURE_STATS
                    EXEC MODEL_REGISTRY.dbo.UPDATE_FEATURE_STATS
                        @COLUMN_ID = @CurrColumnID,
                        @FEATURE_IMPORTANCE = @CurrFeatureImportance,
                        @PROCESS_DATE = @PROCESS_DATE,
                        @STATS_JSON = @CurrStatsJSON,
                        @AUTO_DETECT_QUALITY_ISSUES = @AUTO_DETECT_QUALITY_ISSUES;
                        
                    PRINT N'Đã cập nhật thống kê cho đặc trưng ' + @CurrColumnName;
                END
                ELSE
                BEGIN
                    PRINT N'Cảnh báo: Cột ' + @CurrColumnName + ' không tồn tại trong registry. Bỏ qua.';
                END
                
                FETCH NEXT FROM columns_cursor INTO @CurrColumnName, @CurrFeatureImportance, @CurrStatsJSON;
            END
            
            CLOSE columns_cursor;
            DEALLOCATE columns_cursor;
            
            -- Dọn dẹp
            DROP TABLE #ColumnStats;
        END
        
        -- Bước 3: Nếu không có dữ liệu thống kê JSON, cập nhật cho từng đặc trưng trong bảng
        IF @STATS_JSON IS NULL
        BEGIN
            -- Lấy danh sách các đặc trưng cần cập nhật
            DECLARE @AllColumns TABLE (
                COLUMN_ID INT,
                COLUMN_NAME NVARCHAR(128)
            );
            
            INSERT INTO @AllColumns
            SELECT 
                COLUMN_ID,
                COLUMN_NAME
            FROM MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS
            WHERE SOURCE_TABLE_ID = @SOURCE_TABLE_ID
              AND IS_FEATURE = 1
              AND (@COLUMN_NAME IS NULL OR COLUMN_NAME = @COLUMN_NAME);
            
            -- Đánh dấu các đặc trưng đã được cập nhật
            DECLARE @Msg NVARCHAR(500);
            SET @Msg = N'Đã cập nhật ' + CAST((SELECT COUNT(*) FROM @AllColumns) AS NVARCHAR) + N' đặc trưng trong bảng ' + 
                        @SOURCE_DATABASE + '.' + @SOURCE_SCHEMA + '.' + @SOURCE_TABLE_NAME + N' vào ' + 
                        CONVERT(NVARCHAR, @PROCESS_DATE, 103);
                        
            PRINT @Msg;
        END
        
        -- Bước 4: Ghi nhật ký kết thúc cập nhật dữ liệu
        EXEC MODEL_REGISTRY.dbo.LOG_SOURCE_TABLE_REFRESH
            @SOURCE_DATABASE = @SOURCE_DATABASE,
            @SOURCE_SCHEMA = @SOURCE_SCHEMA,
            @SOURCE_TABLE_NAME = @SOURCE_TABLE_NAME,
            @PROCESS_DATE = @PROCESS_DATE,
            @REFRESH_STATUS = 'COMPLETED',
            @REFRESH_TYPE = @REFRESH_TYPE,
            @REFRESH_METHOD = @REFRESH_METHOD,
            @RECORDS_PROCESSED = @RECORDS_PROCESSED,
            @RECORDS_INSERTED = @RECORDS_INSERTED,
            @RECORDS_UPDATED = @RECORDS_UPDATED,
            @RECORDS_DELETED = @RECORDS_DELETED,
            @RECORDS_REJECTED = @RECORDS_REJECTED,
            @DATA_VOLUME_MB = @DATA_VOLUME_MB;
        
        -- Hoàn thành giao dịch
        COMMIT TRANSACTION;
        
        -- Trả về thông tin bảng và các đặc trưng đã được cập nhật
        SELECT 
            st.SOURCE_DATABASE,
            st.SOURCE_SCHEMA,
            st.SOURCE_TABLE_NAME,
            st.TABLE_TYPE,
            st.DATA_OWNER,
            st.DATA_QUALITY_SCORE,
            @PROCESS_DATE AS PROCESS_DATE,
            'COMPLETED' AS REFRESH_STATUS,
            @REFRESH_TYPE AS REFRESH_TYPE,
            @RECORDS_PROCESSED AS RECORDS_PROCESSED,
            'SUCCESS' AS RESULT,
            N'Đã cập nhật thành công dữ liệu đặc trưng' AS MESSAGE
        FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st
        WHERE st.SOURCE_TABLE_ID = @SOURCE_TABLE_ID;
        
        -- Trả về danh sách các đặc trưng đã được cập nhật
        -- Sử dụng phương thức sắp xếp thay thế cho "NULLS LAST" (không được hỗ trợ trong SQL Server)
        SELECT 
            cd.COLUMN_ID,
            cd.COLUMN_NAME,
            cd.DATA_TYPE,
            cd.IS_FEATURE,
            cd.FEATURE_IMPORTANCE,
            cd.UPDATED_DATE
        FROM MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd
        WHERE cd.SOURCE_TABLE_ID = @SOURCE_TABLE_ID
          AND cd.IS_FEATURE = 1
          AND (@COLUMN_NAME IS NULL OR cd.COLUMN_NAME = @COLUMN_NAME)
        ORDER BY 
            CASE WHEN cd.FEATURE_IMPORTANCE IS NULL THEN 0 ELSE 1 END DESC, 
            cd.FEATURE_IMPORTANCE DESC, 
            cd.COLUMN_NAME;
        
        -- Trả về danh sách các mô hình sử dụng bảng này
        SELECT 
            mr.MODEL_ID,
            mr.MODEL_NAME,
            mr.MODEL_VERSION,
            mt.TYPE_NAME AS MODEL_TYPE,
            tu.USAGE_PURPOSE,
            CASE 
                WHEN mr.IS_ACTIVE = 1 AND @PROCESS_DATE BETWEEN mr.EFF_DATE AND mr.EXP_DATE THEN 'ACTIVE'
                WHEN mr.IS_ACTIVE = 1 AND @PROCESS_DATE < mr.EFF_DATE THEN 'PENDING'
                WHEN mr.IS_ACTIVE = 1 AND @PROCESS_DATE > mr.EXP_DATE THEN 'EXPIRED'
                ELSE 'INACTIVE'
            END AS MODEL_STATUS
        FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
        JOIN MODEL_REGISTRY.dbo.MODEL_TYPE mt ON mr.TYPE_ID = mt.TYPE_ID
        JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE tu ON mr.MODEL_ID = tu.MODEL_ID
        WHERE tu.SOURCE_TABLE_ID = @SOURCE_TABLE_ID
          AND tu.IS_ACTIVE = 1
          AND mr.IS_ACTIVE = 1
          AND @PROCESS_DATE BETWEEN tu.EFF_DATE AND tu.EXP_DATE
        ORDER BY mr.MODEL_NAME, mr.MODEL_VERSION;
    END TRY
    BEGIN CATCH
        -- Nếu có lỗi, ghi nhật ký thất bại
        IF @@TRANCOUNT > 0
        BEGIN
            -- Lấy thông tin lỗi
            DECLARE @ErrorMessage NVARCHAR(4000);
            DECLARE @ErrorDetails NVARCHAR(100);
            
            SET @ErrorMessage = ERROR_MESSAGE();
            SET @ErrorDetails = N'Line ' + CAST(ERROR_LINE() AS NVARCHAR(10));
            
            -- Ghi nhật ký lỗi
            EXEC MODEL_REGISTRY.dbo.LOG_SOURCE_TABLE_REFRESH
                @SOURCE_DATABASE = @SOURCE_DATABASE,
                @SOURCE_SCHEMA = @SOURCE_SCHEMA,
                @SOURCE_TABLE_NAME = @SOURCE_TABLE_NAME,
                @PROCESS_DATE = @PROCESS_DATE,
                @REFRESH_STATUS = 'FAILED',
                @REFRESH_TYPE = @REFRESH_TYPE,
                @REFRESH_METHOD = @REFRESH_METHOD,
                @ERROR_MESSAGE = @ErrorMessage,
                @ERROR_DETAILS = @ErrorDetails;
                
            -- Rollback transaction
            ROLLBACK TRANSACTION;
        END
            
        -- Chuyển tiếp thông báo lỗi
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

-- Thêm comment cho stored procedure
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Cập nhật giá trị của đặc trưng và ghi nhật ký thống kê', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'PROCEDURE',  @level1name = N'REFRESH_FEATURE_VALUES';
GO

PRINT N'Stored procedure REFRESH_FEATURE_VALUES đã được tạo thành công';
GO