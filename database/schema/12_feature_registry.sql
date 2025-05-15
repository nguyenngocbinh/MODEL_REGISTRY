/*
Tên file: 12_feature_registry.sql
Mô tả: Tạo bảng FEATURE_REGISTRY để lưu trữ thông tin về các đặc trưng (features) sử dụng trong các mô hình
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-15
Phiên bản: 1.0
*/

-- Xác nhận database đã được chọn
IF DB_NAME() != 'MODEL_REGISTRY'
BEGIN
    RAISERROR('Vui lòng đảm bảo đang sử dụng database MODEL_REGISTRY', 16, 1)
    RETURN
END

-- Kiểm tra nếu bảng đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.FEATURE_REGISTRY', 'U') IS NOT NULL
    DROP TABLE MODEL_REGISTRY.dbo.FEATURE_REGISTRY;
GO

-- Tạo bảng FEATURE_REGISTRY
CREATE TABLE MODEL_REGISTRY.dbo.FEATURE_REGISTRY (
    FEATURE_ID INT IDENTITY(1,1) PRIMARY KEY,
    FEATURE_NAME NVARCHAR(100) NOT NULL,
    FEATURE_CODE NVARCHAR(50) NOT NULL,
    FEATURE_DESCRIPTION NVARCHAR(500) NULL,
    DATA_TYPE NVARCHAR(50) NOT NULL, -- 'NUMERIC', 'CATEGORICAL', 'DATE', 'TEXT', 'BINARY'
    VALUE_TYPE NVARCHAR(50) NOT NULL, -- 'CONTINUOUS', 'DISCRETE', 'BINARY', 'NOMINAL', 'ORDINAL'
    SOURCE_SYSTEM NVARCHAR(100) NOT NULL, -- System of record for this feature
    BUSINESS_CATEGORY NVARCHAR(100) NULL, -- e.g., 'DEMOGRAPHIC', 'FINANCIAL', 'BEHAVIORAL'
    DOMAIN_KNOWLEDGE NVARCHAR(MAX) NULL, -- Business domain knowledge about this feature
    IS_PII BIT DEFAULT 0, -- Flag for Personally Identifiable Information
    IS_SENSITIVE BIT DEFAULT 0, -- Flag for sensitive/regulated data
    DEFAULT_VALUE NVARCHAR(100) NULL, -- Default value if missing
    VALID_MIN_VALUE NVARCHAR(100) NULL, -- Min valid value (for numerical features)
    VALID_MAX_VALUE NVARCHAR(100) NULL, -- Max valid value (for numerical features)
    VALID_VALUES NVARCHAR(MAX) NULL, -- JSON array for categorical features
    BUSINESS_OWNER NVARCHAR(100) NULL, -- Department/person responsible for feature definition
    UPDATE_FREQUENCY NVARCHAR(50) NULL, -- 'DAILY', 'WEEKLY', 'MONTHLY', etc.
    CREATED_BY NVARCHAR(50) DEFAULT SUSER_NAME(),
    CREATED_DATE DATETIME DEFAULT GETDATE(),
    UPDATED_BY NVARCHAR(50) NULL,
    UPDATED_DATE DATETIME NULL,
    IS_ACTIVE BIT DEFAULT 1,
    EFF_DATE DATE DEFAULT GETDATE(),
    EXP_DATE DATE DEFAULT '9999-12-31',
    CONSTRAINT UC_FEATURE_CODE UNIQUE (FEATURE_CODE),
    CONSTRAINT UC_FEATURE_NAME UNIQUE (FEATURE_NAME)
);
GO

-- Tạo chỉ mục để tăng tốc độ truy vấn
CREATE INDEX IDX_FEATURE_CODE ON MODEL_REGISTRY.dbo.FEATURE_REGISTRY(FEATURE_CODE);
CREATE INDEX IDX_FEATURE_DATA_TYPE ON MODEL_REGISTRY.dbo.FEATURE_REGISTRY(DATA_TYPE);
CREATE INDEX IDX_FEATURE_BUSINESS_CATEGORY ON MODEL_REGISTRY.dbo.FEATURE_REGISTRY(BUSINESS_CATEGORY);
CREATE INDEX IDX_FEATURE_ACTIVE ON MODEL_REGISTRY.dbo.FEATURE_REGISTRY(IS_ACTIVE);
CREATE INDEX IDX_FEATURE_PII ON MODEL_REGISTRY.dbo.FEATURE_REGISTRY(IS_PII, IS_SENSITIVE);
GO

-- Thêm comment cho bảng và các cột
BEGIN TRY
    -- Thêm comment cho bảng
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Bảng chứa thông tin về các đặc trưng (features) sử dụng trong các mô hình', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REGISTRY';

    -- Thêm comment cho cột FEATURE_ID
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'ID của đặc trưng, khóa chính tự động tăng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REGISTRY',
        @level2type = N'COLUMN', @level2name = N'FEATURE_ID';

    -- Thêm comment cho cột FEATURE_NAME
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Tên đầy đủ của đặc trưng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REGISTRY',
        @level2type = N'COLUMN', @level2name = N'FEATURE_NAME';

    -- Thêm comment cho cột FEATURE_CODE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Mã ngắn gọn của đặc trưng, sử dụng trong mã nguồn và truy vấn', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REGISTRY',
        @level2type = N'COLUMN', @level2name = N'FEATURE_CODE';

    -- Thêm comment cho cột FEATURE_DESCRIPTION
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Mô tả chi tiết về đặc trưng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REGISTRY',
        @level2type = N'COLUMN', @level2name = N'FEATURE_DESCRIPTION';

    -- Thêm comment cho cột DATA_TYPE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Kiểu dữ liệu: NUMERIC (số), CATEGORICAL (phân loại), DATE (ngày), TEXT (văn bản), BINARY (nhị phân)', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REGISTRY',
        @level2type = N'COLUMN', @level2name = N'DATA_TYPE';

    -- Thêm comment cho cột VALUE_TYPE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Loại giá trị: CONTINUOUS (liên tục), DISCRETE (rời rạc), BINARY (nhị phân), NOMINAL (danh nghĩa), ORDINAL (thứ tự)', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REGISTRY',
        @level2type = N'COLUMN', @level2name = N'VALUE_TYPE';

    -- Thêm comment cho cột SOURCE_SYSTEM
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Hệ thống nguồn của đặc trưng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REGISTRY',
        @level2type = N'COLUMN', @level2name = N'SOURCE_SYSTEM';

    -- Thêm comment cho cột BUSINESS_CATEGORY
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Phân loại nghiệp vụ: DEMOGRAPHIC (nhân khẩu học), FINANCIAL (tài chính), BEHAVIORAL (hành vi), ...', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REGISTRY',
        @level2type = N'COLUMN', @level2name = N'BUSINESS_CATEGORY';

    -- Thêm comment cho cột IS_PII
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Cờ đánh dấu thông tin nhận dạng cá nhân', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REGISTRY',
        @level2type = N'COLUMN', @level2name = N'IS_PII';

    -- Thêm comment cho cột IS_SENSITIVE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Cờ đánh dấu dữ liệu nhạy cảm/được quy định', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REGISTRY',
        @level2type = N'COLUMN', @level2name = N'IS_SENSITIVE';

    -- Thêm comment cho cột DEFAULT_VALUE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Giá trị mặc định nếu thiếu', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REGISTRY',
        @level2type = N'COLUMN', @level2name = N'DEFAULT_VALUE';

    -- Thêm comment cho cột VALID_VALUES
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Mảng JSON chứa các giá trị hợp lệ cho đặc trưng phân loại', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REGISTRY',
        @level2type = N'COLUMN', @level2name = N'VALID_VALUES';

    -- Thêm comment cho cột IS_ACTIVE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Cờ đánh dấu đặc trưng có còn sử dụng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_REGISTRY',
        @level2type = N'COLUMN', @level2name = N'IS_ACTIVE';

    PRINT N'Các extended properties đã được thêm thành công';
END TRY
BEGIN CATCH
    PRINT N'Cảnh báo: Không thể thêm extended properties. Error: ' + ERROR_MESSAGE();
    PRINT N'Quá trình tạo bảng vẫn thành công.';
END CATCH
GO

PRINT N'Bảng FEATURE_REGISTRY đã được tạo thành công';
GO