/*
Tên file: 07_register_new_model.sql
Mô tả: Tạo stored procedure REGISTER_NEW_MODEL để thêm mô hình mới vào hệ thống đăng ký mô hình
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-15
Phiên bản: 1.0
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu proc đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.REGISTER_NEW_MODEL', 'P') IS NOT NULL
    DROP PROCEDURE dbo.REGISTER_NEW_MODEL;
GO

-- Tạo stored procedure REGISTER_NEW_MODEL
CREATE PROCEDURE dbo.REGISTER_NEW_MODEL
    @MODEL_NAME NVARCHAR(100),
    @MODEL_DESCRIPTION NVARCHAR(500) = NULL,
    @MODEL_VERSION NVARCHAR(20),
    @MODEL_TYPE_CODE NVARCHAR(20),
    @SOURCE_DATABASE NVARCHAR(100),
    @SOURCE_SCHEMA NVARCHAR(100),
    @SOURCE_TABLE_NAME NVARCHAR(100),
    @REF_SOURCE NVARCHAR(255) = NULL,
    @EFF_DATE DATE = NULL,
    @EXP_DATE DATE = NULL,
    @MODEL_CATEGORY NVARCHAR(50) = NULL,
    @SEGMENT_CRITERIA NVARCHAR(MAX) = NULL,
    @PRIORITY INT = 1,
    @SEGMENT_NAME NVARCHAR(100) = NULL,
    @SEGMENT_DESCRIPTION NVARCHAR(500) = NULL,
    @OUTPUT_MODEL_ID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Xác thực đầu vào
    IF @MODEL_NAME IS NULL OR @MODEL_VERSION IS NULL OR @MODEL_TYPE_CODE IS NULL
    BEGIN
        RAISERROR(N'Các tham số MODEL_NAME, MODEL_VERSION, và MODEL_TYPE_CODE là bắt buộc', 16, 1);
        RETURN;
    END
    
    IF @SOURCE_DATABASE IS NULL OR @SOURCE_SCHEMA IS NULL OR @SOURCE_TABLE_NAME IS NULL
    BEGIN
        RAISERROR(N'Các tham số SOURCE_DATABASE, SOURCE_SCHEMA, và SOURCE_TABLE_NAME là bắt buộc', 16, 1);
        RETURN;
    END
    
    -- Xử lý tham số mặc định
    IF @EFF_DATE IS NULL
        SET @EFF_DATE = GETDATE();
        
    IF @EXP_DATE IS NULL
        SET @EXP_DATE = DATEADD(YEAR, 1, @EFF_DATE);
        
    IF @SEGMENT_NAME IS NULL
        SET @SEGMENT_NAME = 'Default';
        
    IF @SEGMENT_DESCRIPTION IS NULL
        SET @SEGMENT_DESCRIPTION = 'Default segment for ' + @MODEL_NAME;
    
    -- Kiểm tra xem mô hình & phiên bản đã tồn tại chưa
    DECLARE @EXISTING_MODEL_ID INT;
    
    SELECT @EXISTING_MODEL_ID = MODEL_ID 
    FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY 
    WHERE MODEL_NAME = @MODEL_NAME 
      AND MODEL_VERSION = @MODEL_VERSION;
      
    IF @EXISTING_MODEL_ID IS NOT NULL
    BEGIN
        RAISERROR(N'Mô hình "%s" với phiên bản "%s" đã tồn tại (ID: %d)', 16, 1, @MODEL_NAME, @MODEL_VERSION, @EXISTING_MODEL_ID);
        RETURN;
    END
    
    -- Lấy TYPE_ID từ MODEL_TYPE_CODE
    DECLARE @TYPE_ID INT;
    
    SELECT @TYPE_ID = TYPE_ID
    FROM MODEL_REGISTRY.dbo.MODEL_TYPE
    WHERE TYPE_CODE = @MODEL_TYPE_CODE;
    
    IF @TYPE_ID IS NULL
    BEGIN
        RAISERROR(N'MODEL_TYPE_CODE "%s" không tồn tại trong hệ thống. Vui lòng thêm loại mô hình này trước.', 16, 1, @MODEL_TYPE_CODE);
        RETURN;
    END
    
    -- Khởi tạo biến để lưu trữ ID của bảng nguồn
    DECLARE @SOURCE_TABLE_ID INT;
    
    -- Kiểm tra xem bảng nguồn đã tồn tại chưa
    SELECT @SOURCE_TABLE_ID = SOURCE_TABLE_ID
    FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES
    WHERE SOURCE_DATABASE = @SOURCE_DATABASE
      AND SOURCE_SCHEMA = @SOURCE_SCHEMA
      AND SOURCE_TABLE_NAME = @SOURCE_TABLE_NAME;
      
    -- Nếu bảng nguồn chưa tồn tại, thêm vào
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
            CREATED_BY,
            CREATED_DATE,
            IS_ACTIVE
        )
        VALUES (
            @SOURCE_DATABASE,
            @SOURCE_SCHEMA,
            @SOURCE_TABLE_NAME,
            'OUTPUT', -- Giả định mặc định là bảng đầu ra
            N'Output table for model ' + @MODEL_NAME,
            SUSER_NAME(),
            'AS NEEDED',
            SUSER_NAME(),
            GETDATE(),
            1
        );
        
        SET @SOURCE_TABLE_ID = SCOPE_IDENTITY();
        
        PRINT N'Đã thêm mới bảng ' + @SOURCE_DATABASE + '.' + @SOURCE_SCHEMA + '.' + @SOURCE_TABLE_NAME + ' vào danh mục với ID ' + CAST(@SOURCE_TABLE_ID AS VARCHAR);
    END
    
    -- Bắt đầu giao dịch
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Thêm mô hình mới vào MODEL_REGISTRY
        INSERT INTO MODEL_REGISTRY.dbo.MODEL_REGISTRY (
            TYPE_ID,
            MODEL_NAME,
            MODEL_DESCRIPTION,
            MODEL_VERSION,
            SOURCE_DATABASE,
            SOURCE_SCHEMA,
            SOURCE_TABLE_NAME,
            REF_SOURCE,
            EFF_DATE,
            EXP_DATE,
            IS_ACTIVE,
            PRIORITY,
            MODEL_CATEGORY,
            SEGMENT_CRITERIA,
            CREATED_BY,
            CREATED_DATE
        )
        VALUES (
            @TYPE_ID,
            @MODEL_NAME,
            @MODEL_DESCRIPTION,
            @MODEL_VERSION,
            @SOURCE_DATABASE,
            @SOURCE_SCHEMA,
            @SOURCE_TABLE_NAME,
            @REF_SOURCE,
            @EFF_DATE,
            @EXP_DATE,
            1, -- Active by default
            @PRIORITY,
            @MODEL_CATEGORY,
            @SEGMENT_CRITERIA,
            SUSER_NAME(),
            GETDATE()
        );
        
        -- Lấy ID của mô hình vừa thêm
        SET @OUTPUT_MODEL_ID = SCOPE_IDENTITY();
        
        -- Thêm mapping phân khúc cho mô hình
        INSERT INTO MODEL_REGISTRY.dbo.MODEL_SEGMENT_MAPPING (
            MODEL_ID,
            SEGMENT_NAME,
            SEGMENT_DESCRIPTION,
            SEGMENT_CRITERIA,
            PRIORITY,
            EFF_DATE,
            EXP_DATE,
            IS_ACTIVE,
            CREATED_BY,
            CREATED_DATE
        )
        VALUES (
            @OUTPUT_MODEL_ID,
            @SEGMENT_NAME,
            @SEGMENT_DESCRIPTION,
            @SEGMENT_CRITERIA,
            @PRIORITY,
            @EFF_DATE,
            @EXP_DATE,
            1, -- Active by default
            SUSER_NAME(),
            GETDATE()
        );
        
        -- Liên kết mô hình với bảng nguồn đầu ra
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
            @OUTPUT_MODEL_ID,
            @SOURCE_TABLE_ID,
            'Result Storage',
            1, -- High priority
            N'Output table for storing model results',
            @EFF_DATE,
            @EXP_DATE,
            1, -- Active by default
            SUSER_NAME(),
            GETDATE()
        );
        
        -- Thêm mapping chi tiết cho bảng
        INSERT INTO MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING (
            MODEL_ID,
            SOURCE_TABLE_ID,
            USAGE_TYPE,
            IS_CRITICAL,
            SEQUENCE_ORDER,
            EFF_DATE,
            EXP_DATE,
            IS_ACTIVE,
            CREATED_BY,
            CREATED_DATE
        )
        VALUES (
            @OUTPUT_MODEL_ID,
            @SOURCE_TABLE_ID,
            'RESULT_STORE',
            1, -- Critical
            1, -- First in sequence
            @EFF_DATE,
            @EXP_DATE,
            1, -- Active by default
            SUSER_NAME(),
            GETDATE()
        );
        
        -- Hoàn thành giao dịch
        COMMIT TRANSACTION;
        
        -- In thông báo thành công
        PRINT N'Đã đăng ký thành công mô hình mới: ' + @MODEL_NAME + ' v' + @MODEL_VERSION + ' (ID: ' + CAST(@OUTPUT_MODEL_ID AS VARCHAR) + ')';
        
        -- Trả về thông tin mô hình đã đăng ký
        SELECT 
            mr.MODEL_ID,
            mr.MODEL_NAME,
            mr.MODEL_VERSION,
            mt.TYPE_CODE,
            mt.TYPE_NAME,
            mr.MODEL_DESCRIPTION,
            mr.SOURCE_DATABASE + '.' + mr.SOURCE_SCHEMA + '.' + mr.SOURCE_TABLE_NAME AS OUTPUT_TABLE,
            mr.EFF_DATE,
            mr.EXP_DATE,
            mr.IS_ACTIVE,
            sm.SEGMENT_NAME,
            sm.SEGMENT_DESCRIPTION,
            'SUCCESS' AS REGISTRATION_STATUS
        FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
        JOIN MODEL_REGISTRY.dbo.MODEL_TYPE mt ON mr.TYPE_ID = mt.TYPE_ID
        JOIN MODEL_REGISTRY.dbo.MODEL_SEGMENT_MAPPING sm ON mr.MODEL_ID = sm.MODEL_ID
        WHERE mr.MODEL_ID = @OUTPUT_MODEL_ID;
        
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
        
        -- Đặt OUTPUT_MODEL_ID = NULL để chỉ ra đăng ký không thành công
        SET @OUTPUT_MODEL_ID = NULL;
    END CATCH;
END;
GO

-- Thêm comment cho stored procedure
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Đăng ký mô hình mới vào hệ thống', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'PROCEDURE',  @level1name = N'REGISTER_NEW_MODEL';
GO

PRINT N'Stored procedure REGISTER_NEW_MODEL đã được tạo thành công';
GO