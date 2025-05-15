/*
Tên file: 09_register_new_feature.sql
Mô tả: Tạo stored procedure REGISTER_NEW_FEATURE để đăng ký đặc trưng mới vào hệ thống
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-15
Phiên bản: 1.0
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu proc đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.REGISTER_NEW_FEATURE', 'P') IS NOT NULL
    DROP PROCEDURE dbo.REGISTER_NEW_FEATURE;
GO

-- Tạo stored procedure REGISTER_NEW_FEATURE
CREATE PROCEDURE dbo.REGISTER_NEW_FEATURE
    @SOURCE_DATABASE NVARCHAR(128),
    @SOURCE_SCHEMA NVARCHAR(128),
    @SOURCE_TABLE_NAME NVARCHAR(128),
    @COLUMN_NAME NVARCHAR(128),
    @DATA_TYPE NVARCHAR(50),
    @COLUMN_DESCRIPTION NVARCHAR(500) = NULL,
    @IS_MANDATORY BIT = 0,
    @IS_FEATURE BIT = 1,
    @FEATURE_IMPORTANCE FLOAT = NULL,
    @BUSINESS_DEFINITION NVARCHAR(MAX) = NULL,
    @TRANSFORMATION_LOGIC NVARCHAR(MAX) = NULL,
    @EXPECTED_VALUES NVARCHAR(MAX) = NULL,
    @DATA_QUALITY_CHECKS NVARCHAR(MAX) = NULL,
    @AUTO_CREATE_TABLE BIT = 0, -- Tự động tạo bảng nếu chưa tồn tại
    @OUTPUT_COLUMN_ID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Xác thực đầu vào
    IF @SOURCE_DATABASE IS NULL OR @SOURCE_SCHEMA IS NULL OR @SOURCE_TABLE_NAME IS NULL OR @COLUMN_NAME IS NULL OR @DATA_TYPE IS NULL
    BEGIN
        RAISERROR(N'Các tham số SOURCE_DATABASE, SOURCE_SCHEMA, SOURCE_TABLE_NAME, COLUMN_NAME, và DATA_TYPE là bắt buộc', 16, 1);
        RETURN;
    END
    
    -- Kiểm tra xem bảng nguồn đã tồn tại trong registry chưa
    DECLARE @SOURCE_TABLE_ID INT;
    
    SELECT @SOURCE_TABLE_ID = SOURCE_TABLE_ID
    FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES
    WHERE SOURCE_DATABASE = @SOURCE_DATABASE
      AND SOURCE_SCHEMA = @SOURCE_SCHEMA
      AND SOURCE_TABLE_NAME = @SOURCE_TABLE_NAME;
      
    -- Nếu bảng chưa tồn tại, có thể tự động tạo nếu @AUTO_CREATE_TABLE = 1
    IF @SOURCE_TABLE_ID IS NULL
    BEGIN
        IF @AUTO_CREATE_TABLE = 1
        BEGIN
            -- Tự động thêm bảng mới vào registry
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
                'INPUT', -- Giả định mặc định là bảng đầu vào cho đặc trưng
                N'Bảng chứa đặc trưng ' + @COLUMN_NAME,
                SUSER_NAME(), -- Người tạo đặc trưng là người sở hữu dữ liệu
                'AS NEEDED',
                SUSER_NAME(),
                GETDATE(),
                1
            );
            
            SET @SOURCE_TABLE_ID = SCOPE_IDENTITY();
            
            PRINT N'Đã tự động thêm bảng ' + @SOURCE_DATABASE + '.' + @SOURCE_SCHEMA + '.' + @SOURCE_TABLE_NAME + ' vào registry với ID ' + CAST(@SOURCE_TABLE_ID AS VARCHAR);
            
            -- Kiểm tra xem bảng có thực sự tồn tại trong cơ sở dữ liệu không
            IF NOT EXISTS (
                SELECT 1 
                FROM INFORMATION_SCHEMA.TABLES 
                WHERE TABLE_CATALOG = @SOURCE_DATABASE 
                  AND TABLE_SCHEMA = @SOURCE_SCHEMA 
                  AND TABLE_NAME = @SOURCE_TABLE_NAME
            )
            BEGIN
                PRINT N'Cảnh báo: Bảng ' + @SOURCE_DATABASE + '.' + @SOURCE_SCHEMA + '.' + @SOURCE_TABLE_NAME + ' không tồn tại trong cơ sở dữ liệu. Đã thêm vào registry nhưng cần tạo bảng vật lý.';
            END
        END
        ELSE
        BEGIN
            RAISERROR(N'Bảng %s.%s.%s không tồn tại trong registry. Hãy thêm bảng trước hoặc sử dụng tham số AUTO_CREATE_TABLE = 1', 16, 1, @SOURCE_DATABASE, @SOURCE_SCHEMA, @SOURCE_TABLE_NAME);
            RETURN;
        END
    END
    
    -- Kiểm tra xem cột đã tồn tại chưa
    DECLARE @EXISTING_COLUMN_ID INT;
    
    SELECT @EXISTING_COLUMN_ID = COLUMN_ID
    FROM MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS
    WHERE SOURCE_TABLE_ID = @SOURCE_TABLE_ID
      AND COLUMN_NAME = @COLUMN_NAME;
      
    IF @EXISTING_COLUMN_ID IS NOT NULL
    BEGIN
        -- Hiển thị thông báo cảnh báo
        PRINT N'Cảnh báo: Đặc trưng ' + @COLUMN_NAME + ' đã tồn tại trong bảng ' + @SOURCE_DATABASE + '.' + @SOURCE_SCHEMA + '.' + @SOURCE_TABLE_NAME + '. Sẽ cập nhật thông tin thay vì tạo mới.';
        
        -- Cập nhật thông tin cột
        UPDATE MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS
        SET 
            DATA_TYPE = @DATA_TYPE,
            COLUMN_DESCRIPTION = ISNULL(@COLUMN_DESCRIPTION, COLUMN_DESCRIPTION),
            IS_MANDATORY = ISNULL(@IS_MANDATORY, IS_MANDATORY),
            IS_FEATURE = ISNULL(@IS_FEATURE, IS_FEATURE),
            FEATURE_IMPORTANCE = ISNULL(@FEATURE_IMPORTANCE, FEATURE_IMPORTANCE),
            BUSINESS_DEFINITION = ISNULL(@BUSINESS_DEFINITION, BUSINESS_DEFINITION),
            TRANSFORMATION_LOGIC = ISNULL(@TRANSFORMATION_LOGIC, TRANSFORMATION_LOGIC),
            EXPECTED_VALUES = ISNULL(@EXPECTED_VALUES, EXPECTED_VALUES),
            DATA_QUALITY_CHECKS = ISNULL(@DATA_QUALITY_CHECKS, DATA_QUALITY_CHECKS),
            UPDATED_BY = SUSER_NAME(),
            UPDATED_DATE = GETDATE()
        WHERE COLUMN_ID = @EXISTING_COLUMN_ID;
        
        -- Thiết lập OUTPUT_COLUMN_ID
        SET @OUTPUT_COLUMN_ID = @EXISTING_COLUMN_ID;
        
        -- Trả về thông tin cột đã cập nhật
        SELECT 
            cd.COLUMN_ID,
            st.SOURCE_DATABASE,
            st.SOURCE_SCHEMA,
            st.SOURCE_TABLE_NAME,
            cd.COLUMN_NAME,
            cd.DATA_TYPE,
            cd.COLUMN_DESCRIPTION,
            cd.IS_MANDATORY,
            cd.IS_FEATURE,
            cd.FEATURE_IMPORTANCE,
            cd.BUSINESS_DEFINITION,
            cd.TRANSFORMATION_LOGIC,
            cd.EXPECTED_VALUES,
            cd.DATA_QUALITY_CHECKS,
            'UPDATED' AS REGISTRATION_STATUS,
            'Đã cập nhật thông tin đặc trưng' AS MESSAGE
        FROM MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd
        JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON cd.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
        WHERE cd.COLUMN_ID = @EXISTING_COLUMN_ID;
        
        RETURN;
    END
    
    -- Thêm đặc trưng mới
    INSERT INTO MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS (
        SOURCE_TABLE_ID,
        COLUMN_NAME,
        DATA_TYPE,
        COLUMN_DESCRIPTION,
        IS_MANDATORY,
        IS_FEATURE,
        FEATURE_IMPORTANCE,
        BUSINESS_DEFINITION,
        TRANSFORMATION_LOGIC,
        EXPECTED_VALUES,
        DATA_QUALITY_CHECKS,
        CREATED_BY,
        CREATED_DATE
    )
    VALUES (
        @SOURCE_TABLE_ID,
        @COLUMN_NAME,
        @DATA_TYPE,
        @COLUMN_DESCRIPTION,
        @IS_MANDATORY,
        @IS_FEATURE,
        @FEATURE_IMPORTANCE,
        @BUSINESS_DEFINITION,
        @TRANSFORMATION_LOGIC,
        @EXPECTED_VALUES,
        @DATA_QUALITY_CHECKS,
        SUSER_NAME(),
        GETDATE()
    );
    
    -- Lấy ID của cột vừa thêm
    SET @OUTPUT_COLUMN_ID = SCOPE_IDENTITY();
    
    -- Kiểm tra xem cột có thực sự tồn tại trong cơ sở dữ liệu không
    IF NOT EXISTS (
        SELECT 1 
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_CATALOG = @SOURCE_DATABASE 
          AND TABLE_SCHEMA = @SOURCE_SCHEMA 
          AND TABLE_NAME = @SOURCE_TABLE_NAME
          AND COLUMN_NAME = @COLUMN_NAME
    )
    BEGIN
        PRINT N'Cảnh báo: Cột ' + @COLUMN_NAME + ' không tồn tại trong bảng ' + @SOURCE_DATABASE + '.' + @SOURCE_SCHEMA + '.' + @SOURCE_TABLE_NAME + ' trong cơ sở dữ liệu. Đã thêm vào registry nhưng cần tạo cột vật lý.';
    END
    
    -- Trả về thông tin đặc trưng mới
    SELECT 
        cd.COLUMN_ID,
        st.SOURCE_DATABASE,
        st.SOURCE_SCHEMA,
        st.SOURCE_TABLE_NAME,
        cd.COLUMN_NAME,
        cd.DATA_TYPE,
        cd.COLUMN_DESCRIPTION,
        cd.IS_MANDATORY,
        cd.IS_FEATURE,
        cd.FEATURE_IMPORTANCE,
        cd.BUSINESS_DEFINITION,
        cd.TRANSFORMATION_LOGIC,
        cd.EXPECTED_VALUES,
        cd.DATA_QUALITY_CHECKS,
        'CREATED' AS REGISTRATION_STATUS,
        'Đã đăng ký đặc trưng mới thành công' AS MESSAGE
    FROM MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd
    JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON cd.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
    WHERE cd.COLUMN_ID = @OUTPUT_COLUMN_ID;
END;
GO

-- Thêm comment cho stored procedure
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Đăng ký đặc trưng mới vào hệ thống', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'PROCEDURE',  @level1name = N'REGISTER_NEW_FEATURE';
GO

PRINT N'Stored procedure REGISTER_NEW_FEATURE đã được tạo thành công';
GO