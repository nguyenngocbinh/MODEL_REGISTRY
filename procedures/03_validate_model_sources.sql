/*
Tên file: 03_validate_model_sources.sql
Mô tả: Tạo stored procedure VALIDATE_MODEL_SOURCES để kiểm tra tính khả dụng của các bảng nguồn cho một mô hình
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.0
*/

-- Kiểm tra nếu proc đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.VALIDATE_MODEL_SOURCES', 'P') IS NOT NULL
    DROP PROCEDURE MODEL_REGISTRY.dbo.VALIDATE_MODEL_SOURCES;
GO

-- Tạo stored procedure VALIDATE_MODEL_SOURCES
CREATE PROCEDURE MODEL_REGISTRY.dbo.VALIDATE_MODEL_SOURCES
    @MODEL_ID INT = NULL,
    @MODEL_NAME NVARCHAR(100) = NULL,
    @MODEL_VERSION NVARCHAR(20) = NULL,
    @PROCESS_DATE DATE = NULL,
    @DETAILED_RESULTS BIT = 1,
    @CHECK_DATA_QUALITY BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Xử lý tham số mặc định
    IF @PROCESS_DATE IS NULL
        SET @PROCESS_DATE = GETDATE();
        
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
        WHERE MODEL_NAME = @MODEL_NAME 
          AND (@MODEL_VERSION IS NULL OR MODEL_VERSION = @MODEL_VERSION)
          AND IS_ACTIVE = 1;
        
        IF @MODEL_ID IS NULL
        BEGIN
            RAISERROR('Không tìm thấy mô hình phù hợp với tên "%s" và phiên bản "%s"', 16, 1, @MODEL_NAME, ISNULL(@MODEL_VERSION, 'bất kỳ'));
            RETURN;
        END
    END
    
    -- Tạo bảng tạm để lưu kết quả kiểm tra
    CREATE TABLE #TableValidationResults (
        SOURCE_TABLE_ID INT,
        SOURCE_DATABASE NVARCHAR(128),
        SOURCE_SCHEMA NVARCHAR(128),
        SOURCE_TABLE_NAME NVARCHAR(128),
        USAGE_PURPOSE NVARCHAR(100),
        IS_CRITICAL BIT,
        TABLE_EXISTS BIT,
        HAS_DATA_FOR_DATE BIT,
        LAST_REFRESH_DATE DATE NULL,
        QUALITY_ISSUES_COUNT INT NULL,
        CRITICAL_QUALITY_ISSUES_COUNT INT NULL,
        ERROR_MESSAGE NVARCHAR(500) NULL
    );
    
    -- Nhập kết quả kiểm tra cơ bản
    INSERT INTO #TableValidationResults (
        SOURCE_TABLE_ID,
        SOURCE_DATABASE,
        SOURCE_SCHEMA,
        SOURCE_TABLE_NAME,
        USAGE_PURPOSE,
        IS_CRITICAL,
        TABLE_EXISTS,
        HAS_DATA_FOR_DATE,
        LAST_REFRESH_DATE,
        QUALITY_ISSUES_COUNT,
        CRITICAL_QUALITY_ISSUES_COUNT,
        ERROR_MESSAGE
    )
    SELECT 
        st.SOURCE_TABLE_ID,
        st.SOURCE_DATABASE,
        st.SOURCE_SCHEMA,
        st.SOURCE_TABLE_NAME,
        tu.USAGE_PURPOSE,
        ISNULL(tm.IS_CRITICAL, 0) AS IS_CRITICAL,
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM INFORMATION_SCHEMA.TABLES 
                WHERE TABLE_CATALOG = st.SOURCE_DATABASE 
                  AND TABLE_SCHEMA = st.SOURCE_SCHEMA 
                  AND TABLE_NAME = st.SOURCE_TABLE_NAME
            ) THEN 1
            ELSE 0
        END AS TABLE_EXISTS,
        0 AS HAS_DATA_FOR_DATE, -- Sẽ được cập nhật sau
        (
            SELECT MAX(PROCESS_DATE)
            FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG
            WHERE SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
            AND REFRESH_STATUS = 'COMPLETED'
            AND PROCESS_DATE <= @PROCESS_DATE
        ) AS LAST_REFRESH_DATE,
        (
            SELECT COUNT(*)
            FROM MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG
            WHERE SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
            AND REMEDIATION_STATUS IN ('OPEN', 'IN_PROGRESS')
            AND PROCESS_DATE <= @PROCESS_DATE
        ) AS QUALITY_ISSUES_COUNT,
        (
            SELECT COUNT(*)
            FROM MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG
            WHERE SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
            AND REMEDIATION_STATUS IN ('OPEN', 'IN_PROGRESS')
            AND SEVERITY = 'CRITICAL'
            AND PROCESS_DATE <= @PROCESS_DATE
        ) AS CRITICAL_QUALITY_ISSUES_COUNT,
        CASE 
            WHEN NOT EXISTS (
                SELECT 1 
                FROM INFORMATION_SCHEMA.TABLES 
                WHERE TABLE_CATALOG = st.SOURCE_DATABASE 
                  AND TABLE_SCHEMA = st.SOURCE_SCHEMA 
                  AND TABLE_NAME = st.SOURCE_TABLE_NAME
            ) THEN 'Bảng không tồn tại'
            ELSE NULL
        END AS ERROR_MESSAGE
    FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st
    JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE tu ON st.SOURCE_TABLE_ID = tu.SOURCE_TABLE_ID
    LEFT JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING tm ON st.SOURCE_TABLE_ID = tm.SOURCE_TABLE_ID AND tm.MODEL_ID = @MODEL_ID
    WHERE tu.MODEL_ID = @MODEL_ID
    AND tu.IS_ACTIVE = 1
    AND st.IS_ACTIVE = 1
    AND @PROCESS_DATE BETWEEN tu.EFF_DATE AND tu.EXP_DATE;
    
    -- Kiểm tra dữ liệu cho từng bảng
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @TableId INT;
    DECLARE @Database NVARCHAR(128);
    DECLARE @Schema NVARCHAR(128);
    DECLARE @TableName NVARCHAR(128);
    DECLARE @HasData BIT;
    
    DECLARE table_cursor CURSOR FOR
    SELECT SOURCE_TABLE_ID, SOURCE_DATABASE, SOURCE_SCHEMA, SOURCE_TABLE_NAME
    FROM #TableValidationResults
    WHERE TABLE_EXISTS = 1;
    
    OPEN table_cursor;
    FETCH NEXT FROM table_cursor INTO @TableId, @Database, @Schema, @TableName;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Kiểm tra xem bảng có dữ liệu cho ngày xử lý không
        SET @SQL = N'
        IF EXISTS (
            SELECT 1 
            FROM ' + QUOTENAME(@Database) + '.' + QUOTENAME(@Schema) + '.' + QUOTENAME(@TableName) + '
            WHERE CASE 
                WHEN EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
                           WHERE TABLE_CATALOG = ''' + @Database + '''
                           AND TABLE_SCHEMA = ''' + @Schema + '''
                           AND TABLE_NAME = ''' + @TableName + '''
                           AND COLUMN_NAME = ''PROCESS_DATE'') THEN CONVERT(DATE, PROCESS_DATE) = ''' + CONVERT(VARCHAR, @PROCESS_DATE, 121) + '''
                ELSE 1=1 -- Nếu không có cột PROCESS_DATE, giả định dữ liệu hợp lệ
                END
        )
        SELECT @HasData = 1
        ELSE
        SELECT @HasData = 0';
        
        DECLARE @HasDataParam BIT;
        
        EXEC sp_executesql 
            @SQL, 
            N'@HasData BIT OUTPUT', 
            @HasData = @HasDataParam OUTPUT;
        
        -- Cập nhật kết quả
        UPDATE #TableValidationResults
        SET HAS_DATA_FOR_DATE = ISNULL(@HasDataParam, 0),
            ERROR_MESSAGE = CASE 
                WHEN ISNULL(@HasDataParam, 0) = 0 THEN 'Không tìm thấy dữ liệu cho ngày ' + CONVERT(VARCHAR, @PROCESS_DATE, 103)
                ELSE ERROR_MESSAGE
            END
        WHERE SOURCE_TABLE_ID = @TableId;
        
        FETCH NEXT FROM table_cursor INTO @TableId, @Database, @Schema, @TableName;
    END
    
    CLOSE table_cursor;
    DEALLOCATE table_cursor;
    
    -- Tính toán kết quả tổng hợp
    DECLARE @TotalTables INT;
    DECLARE @ReadyTables INT;
    DECLARE @CriticalIssues INT;
    DECLARE @QualityIssues INT;
    
    SELECT 
        @TotalTables = COUNT(*),
        @ReadyTables = SUM(CASE WHEN TABLE_EXISTS = 1 AND HAS_DATA_FOR_DATE = 1 THEN 1 ELSE 0 END),
        @CriticalIssues = SUM(CASE WHEN IS_CRITICAL = 1 AND (TABLE_EXISTS = 0 OR HAS_DATA_FOR_DATE = 0) THEN 1 ELSE 0 END),
        @QualityIssues = SUM(CRITICAL_QUALITY_ISSUES_COUNT)
    FROM #TableValidationResults;
    
    -- Trả về kết quả tổng hợp
    SELECT 
        mr.MODEL_ID,
        mr.MODEL_NAME,
        mr.MODEL_VERSION,
        mt.TYPE_NAME AS MODEL_TYPE,
        @PROCESS_DATE AS PROCESS_DATE,
        CASE 
            WHEN mr.IS_ACTIVE = 0 THEN 'MODEL_INACTIVE'
            WHEN @PROCESS_DATE < mr.EFF_DATE THEN 'MODEL_NOT_EFFECTIVE'
            WHEN @PROCESS_DATE > mr.EXP_DATE THEN 'MODEL_EXPIRED'
            WHEN @CriticalIssues > 0 THEN 'NOT_READY_CRITICAL_ISSUES'
            WHEN @QualityIssues > 0 AND @CHECK_DATA_QUALITY = 1 THEN 'READY_WITH_QUALITY_ISSUES'
            WHEN @ReadyTables < @TotalTables THEN 'READY_WITH_WARNINGS'
            ELSE 'READY'
        END AS MODEL_STATUS,
        @TotalTables AS TOTAL_TABLES,
        @ReadyTables AS READY_TABLES,
        @CriticalIssues AS CRITICAL_ISSUES,
        @QualityIssues AS QUALITY_ISSUES,
        CASE 
            WHEN mr.IS_ACTIVE = 0 THEN 'Mô hình không hoạt động'
            WHEN @PROCESS_DATE < mr.EFF_DATE THEN 'Mô hình chưa có hiệu lực đến ' + CONVERT(VARCHAR, mr.EFF_DATE, 103)
            WHEN @PROCESS_DATE > mr.EXP_DATE THEN 'Mô hình đã hết hiệu lực từ ' + CONVERT(VARCHAR, mr.EXP_DATE, 103)
            WHEN @CriticalIssues > 0 THEN 'Có vấn đề nghiêm trọng với ' + CAST(@CriticalIssues AS VARCHAR) + ' bảng quan trọng'
            WHEN @QualityIssues > 0 AND @CHECK_DATA_QUALITY = 1 THEN 'Sẵn sàng nhưng có ' + CAST(@QualityIssues AS VARCHAR) + ' vấn đề chất lượng dữ liệu cần xử lý'
            WHEN @ReadyTables < @TotalTables THEN 'Sẵn sàng nhưng có ' + CAST(@TotalTables - @ReadyTables AS VARCHAR) + ' bảng không sẵn sàng (không quan trọng)'
            ELSE 'Mô hình có thể thực thi với dữ liệu từ ' + CONVERT(VARCHAR, @PROCESS_DATE, 103)
        END AS STATUS_DESCRIPTION
    FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
    JOIN MODEL_REGISTRY.dbo.MODEL_TYPE mt ON mr.TYPE_ID = mt.TYPE_ID
    WHERE mr.MODEL_ID = @MODEL_ID;
    
    -- Nếu yêu cầu kết quả chi tiết, trả về thông tin chi tiết về từng bảng
    IF @DETAILED_RESULTS = 1
    BEGIN
        SELECT 
            tr.SOURCE_DATABASE + '.' + tr.SOURCE_SCHEMA + '.' + tr.SOURCE_TABLE_NAME AS TABLE_FULL_NAME,
            tr.USAGE_PURPOSE,
            tr.IS_CRITICAL,
            tr.TABLE_EXISTS,
            tr.HAS_DATA_FOR_DATE,
            tr.LAST_REFRESH_DATE,
            tr.QUALITY_ISSUES_COUNT,
            tr.CRITICAL_QUALITY_ISSUES_COUNT,
            CASE 
                WHEN tr.TABLE_EXISTS = 0 THEN 'MISSING_TABLE'
                WHEN tr.HAS_DATA_FOR_DATE = 0 THEN 'MISSING_DATA'
                WHEN tr.CRITICAL_QUALITY_ISSUES_COUNT > 0 AND @CHECK_DATA_QUALITY = 1 THEN 'QUALITY_ISSUES'
                ELSE 'READY'
            END AS TABLE_STATUS,
            tr.ERROR_MESSAGE
        FROM #TableValidationResults tr
        ORDER BY tr.IS_CRITICAL DESC, tr.TABLE_EXISTS, tr.HAS_DATA_FOR_DATE;
        
        -- Nếu có vấn đề chất lượng dữ liệu và cần kiểm tra chất lượng, trả về thông tin chi tiết
        IF @CHECK_DATA_QUALITY = 1 AND EXISTS (SELECT 1 FROM #TableValidationResults WHERE QUALITY_ISSUES_COUNT > 0)
        BEGIN
            SELECT TOP 20
                st.SOURCE_DATABASE + '.' + st.SOURCE_SCHEMA + '.' + st.SOURCE_TABLE_NAME AS TABLE_FULL_NAME,
                ISNULL(cd.COLUMN_NAME, 'N/A') AS COLUMN_NAME,
                dq.PROCESS_DATE,
                dq.ISSUE_TYPE,
                dq.ISSUE_DESCRIPTION,
                dq.SEVERITY,
                dq.REMEDIATION_STATUS,
                dq.IMPACT_DESCRIPTION
            FROM MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG dq
            JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON dq.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
            JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE tu ON st.SOURCE_TABLE_ID = tu.SOURCE_TABLE_ID
            LEFT JOIN MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd ON dq.COLUMN_ID = cd.COLUMN_ID
            WHERE tu.MODEL_ID = @MODEL_ID
            AND @PROCESS_DATE BETWEEN tu.EFF_DATE AND tu.EXP_DATE
            AND dq.PROCESS_DATE <= @PROCESS_DATE
            AND dq.REMEDIATION_STATUS IN ('OPEN', 'IN_PROGRESS')
            ORDER BY 
                CASE 
                    WHEN dq.SEVERITY = 'CRITICAL' THEN 1
                    WHEN dq.SEVERITY = 'HIGH' THEN 2
                    WHEN dq.SEVERITY = 'MEDIUM' THEN 3
                    ELSE 4
                END,
                dq.PROCESS_DATE DESC;
        END
    END
    
    -- Dọn dẹp
    DROP TABLE #TableValidationResults;
END;
GO

-- Thêm comment cho stored procedure
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Kiểm tra tính khả dụng của các bảng nguồn cho một mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'PROCEDURE',  @level1name = N'VALIDATE_MODEL_SOURCES';
GO

PRINT 'Stored procedure VALIDATE_MODEL_SOURCES đã được tạo thành công';
GO