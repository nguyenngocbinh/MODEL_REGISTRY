/*
Tên file: 10_update_feature_stats.sql
Mô tả: Tạo stored procedure UPDATE_FEATURE_STATS để cập nhật thống kê của đặc trưng
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-15
Phiên bản: 1.0
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu proc đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.UPDATE_FEATURE_STATS', 'P') IS NOT NULL
    DROP PROCEDURE dbo.UPDATE_FEATURE_STATS;
GO

-- Tạo stored procedure UPDATE_FEATURE_STATS
CREATE PROCEDURE dbo.UPDATE_FEATURE_STATS
    @COLUMN_ID INT = NULL,
    @SOURCE_DATABASE NVARCHAR(128) = NULL,
    @SOURCE_SCHEMA NVARCHAR(128) = NULL,
    @SOURCE_TABLE_NAME NVARCHAR(128) = NULL,
    @COLUMN_NAME NVARCHAR(128) = NULL,
    @FEATURE_IMPORTANCE FLOAT = NULL,
    @DATA_QUALITY_SCORE INT = NULL,
    @PROCESS_DATE DATE = NULL,
    @STATS_JSON NVARCHAR(MAX) = NULL, -- JSON chứa các thống kê chi tiết
    @AUTO_DETECT_QUALITY_ISSUES BIT = 1 -- Tự động phát hiện vấn đề chất lượng dữ liệu
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Xử lý tham số mặc định
    IF @PROCESS_DATE IS NULL
        SET @PROCESS_DATE = GETDATE();
        
    -- Xác thực đầu vào: Phải có @COLUMN_ID hoặc đủ thông tin để xác định cột
    IF @COLUMN_ID IS NULL AND (@SOURCE_DATABASE IS NULL OR @SOURCE_SCHEMA IS NULL OR @SOURCE_TABLE_NAME IS NULL OR @COLUMN_NAME IS NULL)
    BEGIN
        RAISERROR(N'Phải cung cấp COLUMN_ID hoặc đầy đủ thông tin SOURCE_DATABASE, SOURCE_SCHEMA, SOURCE_TABLE_NAME, và COLUMN_NAME', 16, 1);
        RETURN;
    END
    
    -- Nếu không có COLUMN_ID, tìm kiếm dựa trên thông tin bảng và cột
    IF @COLUMN_ID IS NULL
    BEGIN
        SELECT @COLUMN_ID = cd.COLUMN_ID
        FROM MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd
        JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON cd.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
        WHERE st.SOURCE_DATABASE = @SOURCE_DATABASE
          AND st.SOURCE_SCHEMA = @SOURCE_SCHEMA
          AND st.SOURCE_TABLE_NAME = @SOURCE_TABLE_NAME
          AND cd.COLUMN_NAME = @COLUMN_NAME
          AND cd.IS_FEATURE = 1; -- Đảm bảo đây là một đặc trưng
          
        IF @COLUMN_ID IS NULL
        BEGIN
            RAISERROR(N'Không tìm thấy đặc trưng %s trong bảng %s.%s.%s hoặc không phải là đặc trưng', 16, 1, @COLUMN_NAME, @SOURCE_DATABASE, @SOURCE_SCHEMA, @SOURCE_TABLE_NAME);
            RETURN;
        END
    END
    
    -- Lấy thông tin cột và bảng
    DECLARE @TABLE_ID INT;
    DECLARE @CURRENT_COLUMN_NAME NVARCHAR(128);
    DECLARE @CURRENT_DATA_TYPE NVARCHAR(50);
    DECLARE @CURRENT_TABLE_NAME NVARCHAR(128);
    DECLARE @CURRENT_DB_NAME NVARCHAR(128);
    DECLARE @CURRENT_SCHEMA_NAME NVARCHAR(128);
    
    SELECT 
        @TABLE_ID = cd.SOURCE_TABLE_ID,
        @CURRENT_COLUMN_NAME = cd.COLUMN_NAME,
        @CURRENT_DATA_TYPE = cd.DATA_TYPE,
        @CURRENT_TABLE_NAME = st.SOURCE_TABLE_NAME,
        @CURRENT_DB_NAME = st.SOURCE_DATABASE,
        @CURRENT_SCHEMA_NAME = st.SOURCE_SCHEMA
    FROM MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd
    JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON cd.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
    WHERE cd.COLUMN_ID = @COLUMN_ID;
    
    IF @TABLE_ID IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy đặc trưng với COLUMN_ID = %d', 16, 1, @COLUMN_ID);
        RETURN;
    END
    
    -- Cập nhật thông tin đặc trưng
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Cập nhật FEATURE_IMPORTANCE nếu được cung cấp
        IF @FEATURE_IMPORTANCE IS NOT NULL
        BEGIN
            UPDATE MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS
            SET 
                FEATURE_IMPORTANCE = @FEATURE_IMPORTANCE,
                UPDATED_BY = SUSER_NAME(),
                UPDATED_DATE = GETDATE()
            WHERE COLUMN_ID = @COLUMN_ID;
            
            PRINT N'Đã cập nhật FEATURE_IMPORTANCE cho đặc trưng ' + @CURRENT_COLUMN_NAME + ' thành ' + CAST(@FEATURE_IMPORTANCE AS NVARCHAR);
        END
        
        -- Cập nhật DATA_QUALITY_SCORE nếu được cung cấp
        IF @DATA_QUALITY_SCORE IS NOT NULL
        BEGIN
            -- Cập nhật điểm chất lượng dữ liệu cho bảng
            UPDATE MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES
            SET 
                DATA_QUALITY_SCORE = @DATA_QUALITY_SCORE,
                UPDATED_BY = SUSER_NAME(),
                UPDATED_DATE = GETDATE()
            WHERE SOURCE_TABLE_ID = @TABLE_ID;
            
            PRINT N'Đã cập nhật DATA_QUALITY_SCORE cho bảng ' + @CURRENT_DB_NAME + '.' + @CURRENT_SCHEMA_NAME + '.' + @CURRENT_TABLE_NAME + ' thành ' + CAST(@DATA_QUALITY_SCORE AS NVARCHAR);
        END
        
        -- Nếu có thống kê JSON, lưu trữ vào một bảng riêng hoặc xử lý
        IF @STATS_JSON IS NOT NULL
        BEGIN
            -- Kiểm tra xem JSON có hợp lệ không
            IF ISJSON(@STATS_JSON) = 0
            BEGIN
                RAISERROR(N'STATS_JSON không phải là chuỗi JSON hợp lệ', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END
            
            -- Xử lý thông tin thống kê 
            -- Ở đây, chúng ta sẽ tự động phát hiện các vấn đề chất lượng dữ liệu nếu @AUTO_DETECT_QUALITY_ISSUES = 1
            IF @AUTO_DETECT_QUALITY_ISSUES = 1
            BEGIN
                -- Lấy các giá trị thống kê từ JSON
                DECLARE @NULL_PERCENTAGE FLOAT = JSON_VALUE(@STATS_JSON, '$.null_percentage');
                DECLARE @UNIQUE_VALUES INT = JSON_VALUE(@STATS_JSON, '$.unique_values');
                DECLARE @DUPLICATES_PERCENTAGE FLOAT = JSON_VALUE(@STATS_JSON, '$.duplicates_percentage');
                DECLARE @OUTLIERS_PERCENTAGE FLOAT = JSON_VALUE(@STATS_JSON, '$.outliers_percentage');
                DECLARE @INVALID_VALUES_PERCENTAGE FLOAT = JSON_VALUE(@STATS_JSON, '$.invalid_values_percentage');
                DECLARE @TOTAL_RECORDS INT = JSON_VALUE(@STATS_JSON, '$.total_records');
                
                -- Định nghĩa ngưỡng phát hiện vấn đề
                DECLARE @HIGH_NULL_THRESHOLD FLOAT = 30.0; -- > 30% giá trị NULL là vấn đề nghiêm trọng
                DECLARE @MEDIUM_NULL_THRESHOLD FLOAT = 10.0; -- > 10% giá trị NULL là vấn đề trung bình
                DECLARE @HIGH_OUTLIER_THRESHOLD FLOAT = 5.0; -- > 5% giá trị ngoại lai là vấn đề nghiêm trọng
                DECLARE @HIGH_INVALID_THRESHOLD FLOAT = 2.0; -- > 2% giá trị không hợp lệ là vấn đề nghiêm trọng
                
                -- Kiểm tra các vấn đề và ghi nhật ký
                
                -- Kiểm tra vấn đề giá trị NULL
                IF @NULL_PERCENTAGE IS NOT NULL AND @NULL_PERCENTAGE > @MEDIUM_NULL_THRESHOLD
                BEGIN
                    -- Tính toán số lượng bản ghi bị ảnh hưởng
                    DECLARE @NULL_RECORDS INT = ROUND(@TOTAL_RECORDS * @NULL_PERCENTAGE / 100, 0);
                    
                    -- Xác định mức độ nghiêm trọng
                    DECLARE @NULL_SEVERITY NVARCHAR(20) = 
                        CASE 
                            WHEN @NULL_PERCENTAGE > @HIGH_NULL_THRESHOLD THEN 'HIGH'
                            ELSE 'MEDIUM'
                        END;
                    
                    -- Ghi nhật ký vấn đề chất lượng dữ liệu
                    INSERT INTO MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG (
                        SOURCE_TABLE_ID,
                        COLUMN_ID,
                        PROCESS_DATE,
                        ISSUE_TYPE,
                        ISSUE_DESCRIPTION,
                        ISSUE_DETAILS,
                        ISSUE_CATEGORY,
                        SEVERITY,
                        RECORDS_AFFECTED,
                        PERCENTAGE_AFFECTED,
                        IMPACT_DESCRIPTION,
                        DETECTION_METHOD,
                        REMEDIATION_STATUS,
                        CREATED_BY,
                        CREATED_DATE
                    )
                    VALUES (
                        @TABLE_ID,
                        @COLUMN_ID,
                        @PROCESS_DATE,
                        'MISSING_DATA',
                        N'Phát hiện tỷ lệ giá trị NULL cao trong đặc trưng ' + @CURRENT_COLUMN_NAME,
                        N'Tỷ lệ NULL: ' + CAST(@NULL_PERCENTAGE AS NVARCHAR) + '%',
                        'DATA_COMPLETENESS',
                        @NULL_SEVERITY,
                        @NULL_RECORDS,
                        @NULL_PERCENTAGE,
                        N'Tỷ lệ NULL cao có thể ảnh hưởng đến hiệu suất của mô hình. Cần xem xét các cách xử lý giá trị thiếu.',
                        'AUTOMATIC_STATS_ANALYSIS',
                        'OPEN',
                        SUSER_NAME(),
                        GETDATE()
                    );
                    
                    PRINT N'Đã phát hiện và ghi nhật ký vấn đề MISSING_DATA với mức độ ' + @NULL_SEVERITY + ' cho đặc trưng ' + @CURRENT_COLUMN_NAME;
                END
                
                -- Kiểm tra vấn đề giá trị ngoại lai
                IF @OUTLIERS_PERCENTAGE IS NOT NULL AND @OUTLIERS_PERCENTAGE > @HIGH_OUTLIER_THRESHOLD
                BEGIN
                    DECLARE @OUTLIER_RECORDS INT = ROUND(@TOTAL_RECORDS * @OUTLIERS_PERCENTAGE / 100, 0);
                    
                    INSERT INTO MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG (
                        SOURCE_TABLE_ID,
                        COLUMN_ID,
                        PROCESS_DATE,
                        ISSUE_TYPE,
                        ISSUE_DESCRIPTION,
                        ISSUE_DETAILS,
                        ISSUE_CATEGORY,
                        SEVERITY,
                        RECORDS_AFFECTED,
                        PERCENTAGE_AFFECTED,
                        IMPACT_DESCRIPTION,
                        DETECTION_METHOD,
                        REMEDIATION_STATUS,
                        CREATED_BY,
                        CREATED_DATE
                    )
                    VALUES (
                        @TABLE_ID,
                        @COLUMN_ID,
                        @PROCESS_DATE,
                        'OUT_OF_RANGE',
                        N'Phát hiện tỷ lệ giá trị ngoại lai cao trong đặc trưng ' + @CURRENT_COLUMN_NAME,
                        N'Tỷ lệ ngoại lai: ' + CAST(@OUTLIERS_PERCENTAGE AS NVARCHAR) + '%',
                        'DATA_ACCURACY',
                        'HIGH',
                        @OUTLIER_RECORDS,
                        @OUTLIERS_PERCENTAGE,
                        N'Tỷ lệ ngoại lai cao có thể làm giảm độ chính xác của mô hình. Cần xem xét các phương pháp lọc hoặc chuyển đổi.',
                        'AUTOMATIC_STATS_ANALYSIS',
                        'OPEN',
                        SUSER_NAME(),
                        GETDATE()
                    );
                    
                    PRINT N'Đã phát hiện và ghi nhật ký vấn đề OUT_OF_RANGE cho đặc trưng ' + @CURRENT_COLUMN_NAME;
                END
                
                -- Kiểm tra vấn đề giá trị không hợp lệ
                IF @INVALID_VALUES_PERCENTAGE IS NOT NULL AND @INVALID_VALUES_PERCENTAGE > @HIGH_INVALID_THRESHOLD
                BEGIN
                    DECLARE @INVALID_RECORDS INT = ROUND(@TOTAL_RECORDS * @INVALID_VALUES_PERCENTAGE / 100, 0);
                    
                    INSERT INTO MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG (
                        SOURCE_TABLE_ID,
                        COLUMN_ID,
                        PROCESS_DATE,
                        ISSUE_TYPE,
                        ISSUE_DESCRIPTION,
                        ISSUE_DETAILS,
                        ISSUE_CATEGORY,
                        SEVERITY,
                        RECORDS_AFFECTED,
                        PERCENTAGE_AFFECTED,
                        IMPACT_DESCRIPTION,
                        DETECTION_METHOD,
                        REMEDIATION_STATUS,
                        CREATED_BY,
                        CREATED_DATE
                    )
                    VALUES (
                        @TABLE_ID,
                        @COLUMN_ID,
                        @PROCESS_DATE,
                        'INVALID_FORMAT',
                        N'Phát hiện tỷ lệ giá trị không hợp lệ trong đặc trưng ' + @CURRENT_COLUMN_NAME,
                        N'Tỷ lệ không hợp lệ: ' + CAST(@INVALID_VALUES_PERCENTAGE AS NVARCHAR) + '%',
                        'DATA_CONSISTENCY',
                        'HIGH',
                        @INVALID_RECORDS,
                        @INVALID_VALUES_PERCENTAGE,
                        N'Giá trị không hợp lệ có thể gây ra vấn đề trong quá trình xử lý và tính toán.',
                        'AUTOMATIC_STATS_ANALYSIS',
                        'OPEN',
                        SUSER_NAME(),
                        GETDATE()
                    );
                    
                    PRINT N'Đã phát hiện và ghi nhật ký vấn đề INVALID_FORMAT cho đặc trưng ' + @CURRENT_COLUMN_NAME;
                END
            END
        END
        
        -- Hoàn thành giao dịch
        COMMIT TRANSACTION;
        
        -- Trả về thông tin cập nhật
        SELECT 
            cd.COLUMN_ID,
            st.SOURCE_DATABASE,
            st.SOURCE_SCHEMA,
            st.SOURCE_TABLE_NAME,
            cd.COLUMN_NAME,
            cd.DATA_TYPE,
            cd.FEATURE_IMPORTANCE,
            cd.UPDATED_DATE,
            st.DATA_QUALITY_SCORE,
            @STATS_JSON AS STATISTICS_JSON,
            'SUCCESS' AS UPDATE_STATUS,
            'Đã cập nhật thống kê đặc trưng thành công' AS MESSAGE
        FROM MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd
        JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON cd.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
        WHERE cd.COLUMN_ID = @COLUMN_ID;
        
        -- Trả về danh sách các vấn đề chất lượng dữ liệu được phát hiện (nếu có)
        IF @AUTO_DETECT_QUALITY_ISSUES = 1
        BEGIN
            SELECT 
                LOG_ID,
                ISSUE_TYPE,
                ISSUE_DESCRIPTION,
                SEVERITY,
                RECORDS_AFFECTED,
                PERCENTAGE_AFFECTED,
                PROCESS_DATE,
                REMEDIATION_STATUS
            FROM MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG
            WHERE COLUMN_ID = @COLUMN_ID
              AND PROCESS_DATE = @PROCESS_DATE
            ORDER BY SEVERITY DESC, PROCESS_DATE DESC;
        END
    END TRY
    BEGIN CATCH
        -- Nếu có lỗi, rollback transaction
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        -- In thông báo lỗi
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

-- Thêm comment cho stored procedure
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Cập nhật thống kê của đặc trưng và phát hiện vấn đề chất lượng dữ liệu', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'PROCEDURE',  @level1name = N'UPDATE_FEATURE_STATS';
GO

PRINT N'Stored procedure UPDATE_FEATURE_STATS đã được tạo thành công';
GO