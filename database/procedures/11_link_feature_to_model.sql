/*
Tên file: 11_link_feature_to_model.sql
Mô tả: Tạo stored procedure LINK_FEATURE_TO_MODEL để liên kết đặc trưng với mô hình
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-15
Phiên bản: 1.0
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu proc đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.LINK_FEATURE_TO_MODEL', 'P') IS NOT NULL
    DROP PROCEDURE dbo.LINK_FEATURE_TO_MODEL;
GO

-- Tạo stored procedure LINK_FEATURE_TO_MODEL
CREATE PROCEDURE dbo.LINK_FEATURE_TO_MODEL
    @MODEL_ID INT = NULL,
    @MODEL_NAME NVARCHAR(100) = NULL,
    @MODEL_VERSION NVARCHAR(20) = NULL,
    @COLUMN_ID INT = NULL,
    @SOURCE_DATABASE NVARCHAR(128) = NULL,
    @SOURCE_SCHEMA NVARCHAR(128) = NULL,
    @SOURCE_TABLE_NAME NVARCHAR(128) = NULL,
    @COLUMN_NAME NVARCHAR(128) = NULL,
    @USAGE_PURPOSE NVARCHAR(100) = 'Feature Source',
    @USAGE_TYPE NVARCHAR(50) = 'FEATURE_SOURCE',
    @IS_CRITICAL BIT = 0,
    @PRIORITY INT = 5,
    @SEQUENCE_ORDER INT = NULL,
    @EFF_DATE DATE = NULL,
    @EXP_DATE DATE = NULL,
    @DESCRIPTION NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Xử lý tham số mặc định
    IF @EFF_DATE IS NULL
        SET @EFF_DATE = GETDATE();
        
    IF @EXP_DATE IS NULL
        SET @EXP_DATE = DATEADD(YEAR, 10, @EFF_DATE); -- Mặc định hiệu lực 10 năm
    
    -- Xác thực đầu vào
    IF @MODEL_ID IS NULL AND (@MODEL_NAME IS NULL OR @MODEL_VERSION IS NULL)
    BEGIN
        RAISERROR(N'Phải cung cấp MODEL_ID hoặc cả MODEL_NAME và MODEL_VERSION', 16, 1);
        RETURN;
    END
    
    IF @COLUMN_ID IS NULL AND (@SOURCE_DATABASE IS NULL OR @SOURCE_SCHEMA IS NULL OR @SOURCE_TABLE_NAME IS NULL OR @COLUMN_NAME IS NULL)
    BEGIN
        RAISERROR(N'Phải cung cấp COLUMN_ID hoặc đầy đủ thông tin SOURCE_DATABASE, SOURCE_SCHEMA, SOURCE_TABLE_NAME, và COLUMN_NAME', 16, 1);
        RETURN;
    END
    
    -- Nếu không có MODEL_ID, tìm kiếm dựa trên tên và phiên bản
    IF @MODEL_ID IS NULL
    BEGIN
        SELECT @MODEL_ID = MODEL_ID 
        FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY 
        WHERE MODEL_NAME = @MODEL_NAME 
          AND MODEL_VERSION = @MODEL_VERSION
          AND IS_ACTIVE = 1;
          
        IF @MODEL_ID IS NULL
        BEGIN
            RAISERROR(N'Không tìm thấy mô hình hoạt động với tên "%s" và phiên bản "%s"', 16, 1, @MODEL_NAME, @MODEL_VERSION);
            RETURN;
        END
    END
    
    -- Lấy thông tin mô hình
    DECLARE @MODEL_TYPE_CODE NVARCHAR(20);
    DECLARE @MODEL_STATUS NVARCHAR(20);
    DECLARE @CURRENT_MODEL_NAME NVARCHAR(100);
    
    SELECT 
        @CURRENT_MODEL_NAME = mr.MODEL_NAME,
        @MODEL_TYPE_CODE = mt.TYPE_CODE,
        @MODEL_STATUS = CASE 
            WHEN mr.IS_ACTIVE = 1 AND GETDATE() BETWEEN mr.EFF_DATE AND mr.EXP_DATE THEN 'ACTIVE'
            WHEN mr.IS_ACTIVE = 1 AND GETDATE() < mr.EFF_DATE THEN 'PENDING'
            WHEN mr.IS_ACTIVE = 1 AND GETDATE() > mr.EXP_DATE THEN 'EXPIRED'
            ELSE 'INACTIVE'
        END
    FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
    JOIN MODEL_REGISTRY.dbo.MODEL_TYPE mt ON mr.TYPE_ID = mt.TYPE_ID
    WHERE mr.MODEL_ID = @MODEL_ID;
    
    IF @CURRENT_MODEL_NAME IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy mô hình với ID = %d', 16, 1, @MODEL_ID);
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
    DECLARE @CURRENT_TABLE_NAME NVARCHAR(128);
    DECLARE @CURRENT_DB_NAME NVARCHAR(128);
    DECLARE @CURRENT_SCHEMA_NAME NVARCHAR(128);
    
    SELECT 
        @TABLE_ID = cd.SOURCE_TABLE_ID,
        @CURRENT_COLUMN_NAME = cd.COLUMN_NAME,
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
    
    -- Kiểm tra xem đặc trưng đã được liên kết với mô hình chưa
    DECLARE @EXISTING_USAGE_ID INT;
    
    SELECT @EXISTING_USAGE_ID = tu.USAGE_ID
    FROM MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE tu
    WHERE tu.MODEL_ID = @MODEL_ID
      AND tu.SOURCE_TABLE_ID = @TABLE_ID
      AND tu.USAGE_PURPOSE = @USAGE_PURPOSE;
      
    -- Bắt đầu giao dịch
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Nếu chưa có liên kết bảng, tạo liên kết mới
        IF @EXISTING_USAGE_ID IS NULL
        BEGIN
            -- Thêm liên kết bảng
            INSERT INTO MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE (
                MODEL_ID,
                SOURCE_TABLE_ID,
                USAGE_PURPOSE,
                PRIORITY,
                USAGE_DESCRIPTION,
                EFF_DATE,
                EXP_DATE,
                IS_ACTIVE,
                CREATED_BY,
                CREATED_DATE
            )
            VALUES (
                @MODEL_ID,
                @TABLE_ID,
                @USAGE_PURPOSE,
                @PRIORITY,
                ISNULL(@DESCRIPTION, N'Bảng nguồn cho đặc trưng ' + @CURRENT_COLUMN_NAME),
                @EFF_DATE,
                @EXP_DATE,
                1, -- Active by default
                SUSER_NAME(),
                GETDATE()
            );
            
            SET @EXISTING_USAGE_ID = SCOPE_IDENTITY();
            
            PRINT N'Đã tạo liên kết mới giữa mô hình ' + @CURRENT_MODEL_NAME + ' và bảng ' + @CURRENT_DB_NAME + '.' + @CURRENT_SCHEMA_NAME + '.' + @CURRENT_TABLE_NAME;
        END
        ELSE
        BEGIN
            -- Cập nhật liên kết hiện có
            UPDATE MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE
            SET 
                PRIORITY = @PRIORITY,
                USAGE_DESCRIPTION = ISNULL(@DESCRIPTION, USAGE_DESCRIPTION),
                EFF_DATE = @EFF_DATE,
                EXP_DATE = @EXP_DATE,
                IS_ACTIVE = 1,
                UPDATED_BY = SUSER_NAME(),
                UPDATED_DATE = GETDATE()
            WHERE USAGE_ID = @EXISTING_USAGE_ID;
            
            PRINT N'Đã cập nhật liên kết giữa mô hình ' + @CURRENT_MODEL_NAME + ' và bảng ' + @CURRENT_DB_NAME + '.' + @CURRENT_SCHEMA_NAME + '.' + @CURRENT_TABLE_NAME;
        END
        
        -- Kiểm tra xem đã có ánh xạ chi tiết chưa
        DECLARE @EXISTING_MAPPING_ID INT;
        
        SELECT @EXISTING_MAPPING_ID = MAPPING_ID
        FROM MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING
        WHERE MODEL_ID = @MODEL_ID
          AND SOURCE_TABLE_ID = @TABLE_ID
          AND USAGE_TYPE = @USAGE_TYPE;
          
        -- Tạo chuỗi danh sách các cột cần thiết
        DECLARE @REQUIRED_COLUMNS NVARCHAR(MAX);
        SET @REQUIRED_COLUMNS = '["' + @CURRENT_COLUMN_NAME + '"]';
        
        -- Xác định thứ tự xử lý nếu chưa được cung cấp
        IF @SEQUENCE_ORDER IS NULL
        BEGIN
            -- Tìm giá trị lớn nhất hiện tại và cộng 10
            SELECT @SEQUENCE_ORDER = ISNULL(MAX(SEQUENCE_ORDER), 0) + 10
            FROM MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING
            WHERE MODEL_ID = @MODEL_ID;
        END
        
        -- Nếu chưa có ánh xạ chi tiết, tạo mới
        IF @EXISTING_MAPPING_ID IS NULL
        BEGIN
            -- Thêm ánh xạ chi tiết
            INSERT INTO MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING (
                MODEL_ID,
                SOURCE_TABLE_ID,
                USAGE_TYPE,
                REQUIRED_COLUMNS,
                IS_CRITICAL,
                SEQUENCE_ORDER,
                EFF_DATE,
                EXP_DATE,
                IS_ACTIVE,
                CREATED_BY,
                CREATED_DATE
            )
            VALUES (
                @MODEL_ID,
                @TABLE_ID,
                @USAGE_TYPE,
                @REQUIRED_COLUMNS,
                @IS_CRITICAL,
                @SEQUENCE_ORDER,
                @EFF_DATE,
                @EXP_DATE,
                1, -- Active by default
                SUSER_NAME(),
                GETDATE()
            );
            
            SET @EXISTING_MAPPING_ID = SCOPE_IDENTITY();
            
            PRINT N'Đã tạo ánh xạ chi tiết giữa mô hình ' + @CURRENT_MODEL_NAME + ' và đặc trưng ' + @CURRENT_COLUMN_NAME;
        END
        ELSE
        BEGIN
            -- Cập nhật ánh xạ chi tiết hiện có
            DECLARE @EXISTING_REQUIRED_COLUMNS NVARCHAR(MAX);
            SELECT @EXISTING_REQUIRED_COLUMNS = REQUIRED_COLUMNS 
            FROM MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING
            WHERE MAPPING_ID = @EXISTING_MAPPING_ID;
            
            -- Kiểm tra xem cột đã tồn tại trong danh sách chưa
            DECLARE @UPDATED_REQUIRED_COLUMNS NVARCHAR(MAX);
            
            -- Nếu danh sách cột hiện tại không phải JSON hợp lệ hoặc rỗng, sử dụng cột mới
            IF @EXISTING_REQUIRED_COLUMNS IS NULL OR ISJSON(@EXISTING_REQUIRED_COLUMNS) = 0 OR @EXISTING_REQUIRED_COLUMNS = '[]'
            BEGIN
                SET @UPDATED_REQUIRED_COLUMNS = @REQUIRED_COLUMNS;
            END
            ELSE
            BEGIN
                -- Kiểm tra xem cột đã tồn tại trong danh sách chưa
                IF CHARINDEX('"' + @CURRENT_COLUMN_NAME + '"', @EXISTING_REQUIRED_COLUMNS) > 0
                BEGIN
                    -- Cột đã tồn tại, giữ nguyên danh sách
                    SET @UPDATED_REQUIRED_COLUMNS = @EXISTING_REQUIRED_COLUMNS;
                END
                ELSE
                BEGIN
                    -- Cột chưa tồn tại, thêm vào danh sách
                    -- Xóa dấu ngoặc vuông đóng ở cuối
                    DECLARE @TEMP_COLUMNS NVARCHAR(MAX) = LEFT(@EXISTING_REQUIRED_COLUMNS, LEN(@EXISTING_REQUIRED_COLUMNS) - 1);
                    -- Nối cột mới vào danh sách
                    SET @UPDATED_REQUIRED_COLUMNS = @TEMP_COLUMNS + ', "' + @CURRENT_COLUMN_NAME + '"]';
                END
            END
            
            -- Cập nhật ánh xạ
            UPDATE MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING
            SET 
                REQUIRED_COLUMNS = @UPDATED_REQUIRED_COLUMNS,
                IS_CRITICAL = CASE WHEN @IS_CRITICAL = 1 THEN 1 ELSE IS_CRITICAL END, -- Chỉ cập nhật IS_CRITICAL thành 1 nếu có yêu cầu
                SEQUENCE_ORDER = @SEQUENCE_ORDER,
                EFF_DATE = @EFF_DATE,
                EXP_DATE = @EXP_DATE,
                IS_ACTIVE = 1,
                UPDATED_BY = SUSER_NAME(),
                UPDATED_DATE = GETDATE()
            WHERE MAPPING_ID = @EXISTING_MAPPING_ID;
            
            PRINT N'Đã cập nhật ánh xạ chi tiết giữa mô hình ' + @CURRENT_MODEL_NAME + ' và đặc trưng ' + @CURRENT_COLUMN_NAME;
        END
        
        -- Hoàn thành giao dịch
        COMMIT TRANSACTION;
        
        -- Trả về thông tin liên kết
        SELECT 
            'SUCCESS' AS RESULT,
            'Đã liên kết đặc trưng với mô hình thành công' AS MESSAGE,
            mr.MODEL_ID,
            mr.MODEL_NAME,
            mr.MODEL_VERSION,
            mt.TYPE_CODE,
            cd.COLUMN_ID,
            cd.COLUMN_NAME,
            st.SOURCE_DATABASE + '.' + st.SOURCE_SCHEMA + '.' + st.SOURCE_TABLE_NAME AS TABLE_FULL_NAME,
            tu.USAGE_PURPOSE,
            tm.USAGE_TYPE,
            tm.IS_CRITICAL,
            tm.SEQUENCE_ORDER,
            tu.PRIORITY
        FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
        JOIN MODEL_REGISTRY.dbo.MODEL_TYPE mt ON mr.TYPE_ID = mt.TYPE_ID
        JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE tu ON mr.MODEL_ID = tu.MODEL_ID
        JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING tm ON tu.MODEL_ID = tm.MODEL_ID AND tu.SOURCE_TABLE_ID = tm.SOURCE_TABLE_ID
        JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON tu.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
        JOIN MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd ON st.SOURCE_TABLE_ID = cd.SOURCE_TABLE_ID
        WHERE mr.MODEL_ID = @MODEL_ID
          AND cd.COLUMN_ID = @COLUMN_ID
          AND tu.USAGE_ID = @EXISTING_USAGE_ID
          AND tm.MAPPING_ID = @EXISTING_MAPPING_ID;
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
    @value = N'Liên kết đặc trưng với mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'PROCEDURE',  @level1name = N'LINK_FEATURE_TO_MODEL';
GO

PRINT N'Stored procedure LINK_FEATURE_TO_MODEL đã được tạo thành công';
GO