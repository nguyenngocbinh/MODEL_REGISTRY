/*
Tên file: 04_log_source_table_refresh.sql
Mô tả: Tạo stored procedure LOG_SOURCE_TABLE_REFRESH để ghi nhật ký cập nhật dữ liệu nguồn
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.0
*/

-- Kiểm tra nếu proc đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.LOG_SOURCE_TABLE_REFRESH', 'P') IS NOT NULL
    DROP PROCEDURE MODEL_REGISTRY.dbo.LOG_SOURCE_TABLE_REFRESH;
GO

-- Tạo stored procedure LOG_SOURCE_TABLE_REFRESH
CREATE PROCEDURE MODEL_REGISTRY.dbo.LOG_SOURCE_TABLE_REFRESH
    @SOURCE_DATABASE NVARCHAR(128),
    @SOURCE_SCHEMA NVARCHAR(128),
    @SOURCE_TABLE_NAME NVARCHAR(128),
    @PROCESS_DATE DATE,
    @REFRESH_STATUS NVARCHAR(20), -- 'STARTED', 'COMPLETED', 'FAILED', 'PARTIAL'
    @REFRESH_TYPE NVARCHAR(50) = 'FULL', -- 'FULL', 'INCREMENTAL', 'DELTA', 'RESTATEMENT'
    @REFRESH_METHOD NVARCHAR(50) = 'MANUAL', -- 'ETL', 'MANUAL', 'SCHEDULED'
    @RECORDS_PROCESSED INT = NULL,
    @RECORDS_INSERTED INT = NULL,
    @RECORDS_UPDATED INT = NULL,
    @RECORDS_DELETED INT = NULL,
    @RECORDS_REJECTED INT = NULL,
    @DATA_VOLUME_MB DECIMAL(10,2) = NULL,
    @ERROR_MESSAGE NVARCHAR(MAX) = NULL,
    @ERROR_DETAILS NVARCHAR(MAX) = NULL,
    @AUTO_COMPLETE BIT = 0 -- Tự động đánh dấu hoàn thành nếu trước đó đã bắt đầu
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Xác thực đầu vào
    IF @SOURCE_DATABASE IS NULL OR @SOURCE_SCHEMA IS NULL OR @SOURCE_TABLE_NAME IS NULL OR @PROCESS_DATE IS NULL OR @REFRESH_STATUS IS NULL
    BEGIN
        RAISERROR('Phải cung cấp đầy đủ thông tin: SOURCE_DATABASE, SOURCE_SCHEMA, SOURCE_TABLE_NAME, PROCESS_DATE, REFRESH_STATUS', 16, 1);
        RETURN;
    END
    
    -- Xác thực trạng thái
    IF @REFRESH_STATUS NOT IN ('STARTED', 'COMPLETED', 'FAILED', 'PARTIAL')
    BEGIN
        RAISERROR('REFRESH_STATUS không hợp lệ. Giá trị hợp lệ là: STARTED, COMPLETED, FAILED, PARTIAL', 16, 1);
        RETURN;
    END
    
    -- Lấy SOURCE_TABLE_ID từ tên bảng
    DECLARE @SOURCE_TABLE_ID INT;
    
    SELECT @SOURCE_TABLE_ID = SOURCE_TABLE_ID
    FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES
    WHERE SOURCE_DATABASE = @SOURCE_DATABASE
      AND SOURCE_SCHEMA = @SOURCE_SCHEMA
      AND SOURCE_TABLE_NAME = @SOURCE_TABLE_NAME;
      
    -- Nếu bảng chưa có trong danh mục, tự động thêm vào
    IF @SOURCE_TABLE_ID IS NULL
    BEGIN
        INSERT INTO MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES (
            SOURCE_DATABASE,
            SOURCE_SCHEMA,
            SOURCE_TABLE_NAME,
            TABLE_TYPE,
            TABLE_DESCRIPTION,
            DATA_OWNER,
            UPDATE_FREQUENCY,
            DATA_LATENCY,
            CREATED_BY,
            CREATED_DATE
        )
        VALUES (
            @SOURCE_DATABASE,
            @SOURCE_SCHEMA,
            @SOURCE_TABLE_NAME,
            'INPUT', -- Giả định mặc định là bảng đầu vào
            'Tự động thêm bởi LOG_SOURCE_TABLE_REFRESH',
            'Unknown',
            CASE 
                WHEN @REFRESH_METHOD = 'SCHEDULED' THEN 'DAILY'
                ELSE 'AS NEEDED'
            END,
            'Unknown',
            SUSER_NAME(),
            GETDATE()
        );
        
        SET @SOURCE_TABLE_ID = SCOPE_IDENTITY();
        
        PRINT 'Đã thêm mới bảng ' + @SOURCE_DATABASE + '.' + @SOURCE_SCHEMA + '.' + @SOURCE_TABLE_NAME + ' vào danh mục với ID ' + CAST(@SOURCE_TABLE_ID AS VARCHAR);
    END
    
    -- Tính thời gian thực thi
    DECLARE @EXECUTION_TIME_SECONDS INT = NULL;
    
    -- Kiểm tra xem có bản ghi đang trong trạng thái STARTED không
    DECLARE @EXISTING_REFRESH_ID INT;
    DECLARE @EXISTING_START_TIME DATETIME;
    
    SELECT TOP 1 
        @EXISTING_REFRESH_ID = REFRESH_ID,
        @EXISTING_START_TIME = REFRESH_START_TIME
    FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG
    WHERE SOURCE_TABLE_ID = @SOURCE_TABLE_ID
      AND PROCESS_DATE = @PROCESS_DATE
      AND REFRESH_STATUS = 'STARTED'
    ORDER BY REFRESH_START_TIME DESC;
    
    -- Nếu tìm thấy bản ghi đang bắt đầu và trạng thái hiện tại là kết thúc (COMPLETED, FAILED, PARTIAL)
    IF @EXISTING_REFRESH_ID IS NOT NULL AND @REFRESH_STATUS IN ('COMPLETED', 'FAILED', 'PARTIAL')
    BEGIN
        -- Tính thời gian thực thi
        SET @EXECUTION_TIME_SECONDS = DATEDIFF(SECOND, @EXISTING_START_TIME, GETDATE());
        
        -- Cập nhật bản ghi hiện có
        UPDATE MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG
        SET 
            REFRESH_END_TIME = GETDATE(),
            REFRESH_STATUS = @REFRESH_STATUS,
            REFRESH_TYPE = ISNULL(@REFRESH_TYPE, REFRESH_TYPE),
            REFRESH_METHOD = ISNULL(@REFRESH_METHOD, REFRESH_METHOD),
            RECORDS_PROCESSED = ISNULL(@RECORDS_PROCESSED, RECORDS_PROCESSED),
            RECORDS_INSERTED = ISNULL(@RECORDS_INSERTED, RECORDS_INSERTED),
            RECORDS_UPDATED = ISNULL(@RECORDS_UPDATED, RECORDS_UPDATED),
            RECORDS_DELETED = ISNULL(@RECORDS_DELETED, RECORDS_DELETED),
            RECORDS_REJECTED = ISNULL(@RECORDS_REJECTED, RECORDS_REJECTED),
            EXECUTION_TIME_SECONDS = @EXECUTION_TIME_SECONDS,
            DATA_VOLUME_MB = ISNULL(@DATA_VOLUME_MB, DATA_VOLUME_MB),
            ERROR_MESSAGE = ISNULL(@ERROR_MESSAGE, ERROR_MESSAGE),
            ERROR_DETAILS = ISNULL(@ERROR_DETAILS, ERROR_DETAILS),
            UPDATED_BY = SUSER_NAME(),
            UPDATED_DATE = GETDATE()
        WHERE REFRESH_ID = @EXISTING_REFRESH_ID;
        
        -- Cập nhật lại thời gian cập nhật mới nhất trong MODEL_SOURCE_TABLES
        IF @REFRESH_STATUS = 'COMPLETED'
        BEGIN
            UPDATE MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES
            SET 
                UPDATED_BY = SUSER_NAME(),
                UPDATED_DATE = GETDATE()
            WHERE SOURCE_TABLE_ID = @SOURCE_TABLE_ID;
        END
        
        PRINT 'Cập nhật bản ghi refresh với ID ' + CAST(@EXISTING_REFRESH_ID AS VARCHAR) + ' thành ' + @REFRESH_STATUS;
    END
    -- Nếu không tìm thấy bản ghi STARTED hoặc đang tạo bản ghi STARTED mới
    ELSE
    BEGIN
        -- Chèn bản ghi mới
        INSERT INTO MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG (
            SOURCE_TABLE_ID,
            PROCESS_DATE,
            REFRESH_START_TIME,
            REFRESH_END_TIME,
            REFRESH_STATUS,
            REFRESH_TYPE,
            REFRESH_METHOD,
            RECORDS_PROCESSED,
            RECORDS_INSERTED,
            RECORDS_UPDATED,
            RECORDS_DELETED,
            RECORDS_REJECTED,
            EXECUTION_TIME_SECONDS,
            DATA_VOLUME_MB,
            ERROR_MESSAGE,
            ERROR_DETAILS,
            INITIATED_BY,
            CREATED_BY,
            CREATED_DATE
        )
        VALUES (
            @SOURCE_TABLE_ID,
            @PROCESS_DATE,
            GETDATE(), -- Thời gian bắt đầu luôn là thời gian hiện tại
            CASE 
                WHEN @REFRESH_STATUS IN ('COMPLETED', 'FAILED', 'PARTIAL') THEN GETDATE() -- Thời gian kết thúc chỉ khi hoàn thành hoặc lỗi
                ELSE NULL 
            END,
            @REFRESH_STATUS,
            @REFRESH_TYPE,
            @REFRESH_METHOD,
            @RECORDS_PROCESSED,
            @RECORDS_INSERTED,
            @RECORDS_UPDATED,
            @RECORDS_DELETED,
            @RECORDS_REJECTED,
            NULL, -- Thời gian thực thi chỉ được tính khi cập nhật từ STARTED sang kết quả khác
            @DATA_VOLUME_MB,
            @ERROR_MESSAGE,
            @ERROR_DETAILS,
            SUSER_NAME(),
            SUSER_NAME(),
            GETDATE()
        );
        
        DECLARE @NEW_REFRESH_ID INT = SCOPE_IDENTITY();
        
        PRINT 'Tạo mới bản ghi refresh với ID ' + CAST(@NEW_REFRESH_ID AS VARCHAR) + ' với trạng thái ' + @REFRESH_STATUS;
        
        -- Nếu AUTO_COMPLETE = 1 và trạng thái hiện tại là STARTED, tự động tạo bản ghi COMPLETED mới
        IF @AUTO_COMPLETE = 1 AND @REFRESH_STATUS = 'STARTED'
        BEGIN
            -- Chèn bản ghi hoàn thành
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
                @DATA_VOLUME_MB = @DATA_VOLUME_MB,
                @ERROR_MESSAGE = NULL,
                @ERROR_DETAILS = NULL,
                @AUTO_COMPLETE = 0; -- Ngăn đệ quy vô hạn
        END
    END
    
    -- Trả về thông tin về bản ghi refresh
    SELECT 
        r.REFRESH_ID,
        st.SOURCE_DATABASE + '.' + st.SOURCE_SCHEMA + '.' + st.SOURCE_TABLE_NAME AS TABLE_NAME,
        r.PROCESS_DATE,
        r.REFRESH_STATUS,
        r.REFRESH_TYPE,
        r.REFRESH_METHOD,
        r.REFRESH_START_TIME,
        r.REFRESH_END_TIME,
        r.EXECUTION_TIME_SECONDS,
        r.RECORDS_PROCESSED,
        r.RECORDS_INSERTED,
        r.RECORDS_UPDATED,
        r.RECORDS_DELETED,
        r.RECORDS_REJECTED,
        r.DATA_VOLUME_MB,
        r.ERROR_MESSAGE,
        r.CREATED_BY,
        r.CREATED_DATE,
        CASE 
            WHEN r.REFRESH_STATUS = 'COMPLETED' THEN 'Dữ liệu đã sẵn sàng cho xử lý mô hình'
            WHEN r.REFRESH_STATUS = 'FAILED' THEN 'Cập nhật dữ liệu thất bại, xem thông báo lỗi'
            WHEN r.REFRESH_STATUS = 'PARTIAL' THEN 'Dữ liệu được cập nhật một phần, có thể có vấn đề'
            ELSE 'Cập nhật dữ liệu đang tiến hành'
        END AS DESCRIPTION
    FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG r
    JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON r.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
    WHERE r.SOURCE_TABLE_ID = @SOURCE_TABLE_ID
      AND r.PROCESS_DATE = @PROCESS_DATE
    ORDER BY r.REFRESH_START_TIME DESC;
    
    -- Nếu trạng thái là COMPLETED, trả về danh sách các mô hình sử dụng bảng này
    IF @REFRESH_STATUS = 'COMPLETED'
    BEGIN
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
    END
END;
GO

-- Thêm comment cho stored procedure
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Ghi nhật ký cập nhật dữ liệu nguồn', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'PROCEDURE',  @level1name = N'LOG_SOURCE_TABLE_REFRESH';
GO

PRINT 'Stored procedure LOG_SOURCE_TABLE_REFRESH đã được tạo thành công';
GO