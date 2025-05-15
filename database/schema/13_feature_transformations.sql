/*
Tên file: 13_feature_transformations.sql
Mô tả: Tạo bảng FEATURE_TRANSFORMATIONS để lưu trữ thông tin về các phép biến đổi dữ liệu cho đặc trưng
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
IF OBJECT_ID('MODEL_REGISTRY.dbo.FEATURE_TRANSFORMATIONS', 'U') IS NOT NULL
    DROP TABLE MODEL_REGISTRY.dbo.FEATURE_TRANSFORMATIONS;
GO

-- Tạo bảng FEATURE_TRANSFORMATIONS
CREATE TABLE MODEL_REGISTRY.dbo.FEATURE_TRANSFORMATIONS (
    TRANSFORMATION_ID INT IDENTITY(1,1) PRIMARY KEY,
    FEATURE_ID INT NOT NULL,
    TRANSFORMATION_NAME NVARCHAR(100) NOT NULL,
    TRANSFORMATION_TYPE NVARCHAR(50) NOT NULL, -- 'SCALING', 'NORMALIZATION', 'BINNING', 'ENCODING', 'IMPUTATION', 'LOG', 'POWER'
    TRANSFORMATION_DESCRIPTION NVARCHAR(500) NULL,
    TRANSFORMATION_SQL NVARCHAR(MAX) NULL, -- SQL code implementing the transformation
    TRANSFORMATION_PARAMS NVARCHAR(MAX) NULL, -- JSON with parameters for transformation
    PREPROCESSING_STEPS NVARCHAR(MAX) NULL, -- Description of preprocessing steps before transformation
    POSTPROCESSING_STEPS NVARCHAR(MAX) NULL, -- Description of postprocessing steps after transformation
    EXECUTION_ORDER INT NOT NULL, -- Order in which transformations are applied
    IS_MANDATORY BIT DEFAULT 1, -- Flag if this transformation must be applied
    IS_REVERSIBLE BIT DEFAULT 0, -- Flag if transformation can be reversed
    REVERSE_TRANSFORMATION_SQL NVARCHAR(MAX) NULL, -- SQL to reverse the transformation
    CREATED_DATE DATETIME DEFAULT GETDATE(),
    CREATED_BY NVARCHAR(50) DEFAULT SUSER_NAME(),
    UPDATED_DATE DATETIME NULL,
    UPDATED_BY NVARCHAR(50) NULL,
    IS_ACTIVE BIT DEFAULT 1,
    EFF_DATE DATE DEFAULT GETDATE(),
    EXP_DATE DATE DEFAULT '9999-12-31',
    FOREIGN KEY (FEATURE_ID) REFERENCES MODEL_REGISTRY.dbo.FEATURE_REGISTRY(FEATURE_ID),
    CONSTRAINT UC_FEATURE_TRANSFORMATION UNIQUE (FEATURE_ID, TRANSFORMATION_NAME)
);
GO

-- Tạo chỉ mục để tăng tốc độ truy vấn
CREATE INDEX IDX_TRANSFORMATION_FEATURE_ID ON MODEL_REGISTRY.dbo.FEATURE_TRANSFORMATIONS(FEATURE_ID);
CREATE INDEX IDX_TRANSFORMATION_TYPE ON MODEL_REGISTRY.dbo.FEATURE_TRANSFORMATIONS(TRANSFORMATION_TYPE);
CREATE INDEX IDX_TRANSFORMATION_ACTIVE ON MODEL_REGISTRY.dbo.FEATURE_TRANSFORMATIONS(IS_ACTIVE);
CREATE INDEX IDX_TRANSFORMATION_ORDER ON MODEL_REGISTRY.dbo.FEATURE_TRANSFORMATIONS(EXECUTION_ORDER);
GO

-- Thêm comment cho bảng và các cột
BEGIN TRY
    -- Thêm comment cho bảng
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Bảng lưu trữ thông tin về các phép biến đổi dữ liệu cho đặc trưng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_TRANSFORMATIONS';

    -- Thêm comment cho cột TRANSFORMATION_ID
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'ID của phép biến đổi, khóa chính tự động tăng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_TRANSFORMATIONS',
        @level2type = N'COLUMN', @level2name = N'TRANSFORMATION_ID';

    -- Thêm comment cho cột FEATURE_ID
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'ID của đặc trưng, tham chiếu đến bảng FEATURE_REGISTRY', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_TRANSFORMATIONS',
        @level2type = N'COLUMN', @level2name = N'FEATURE_ID';

    -- Thêm comment cho cột TRANSFORMATION_NAME
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Tên của phép biến đổi', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_TRANSFORMATIONS',
        @level2type = N'COLUMN', @level2name = N'TRANSFORMATION_NAME';

    -- Thêm comment cho cột TRANSFORMATION_TYPE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Loại biến đổi: SCALING (tỷ lệ), NORMALIZATION (chuẩn hóa), BINNING (phân nhóm), ENCODING (mã hóa), IMPUTATION (điền khuyết), LOG (logarithm), POWER (lũy thừa)', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_TRANSFORMATIONS',
        @level2type = N'COLUMN', @level2name = N'TRANSFORMATION_TYPE';

    -- Thêm comment cho cột TRANSFORMATION_DESCRIPTION
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Mô tả chi tiết về phép biến đổi', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_TRANSFORMATIONS',
        @level2type = N'COLUMN', @level2name = N'TRANSFORMATION_DESCRIPTION';

    -- Thêm comment cho cột TRANSFORMATION_SQL
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Mã SQL thực hiện phép biến đổi', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_TRANSFORMATIONS',
        @level2type = N'COLUMN', @level2name = N'TRANSFORMATION_SQL';

    -- Thêm comment cho cột TRANSFORMATION_PARAMS
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Tham số cho phép biến đổi dưới dạng JSON', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_TRANSFORMATIONS',
        @level2type = N'COLUMN', @level2name = N'TRANSFORMATION_PARAMS';

    -- Thêm comment cho cột EXECUTION_ORDER
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Thứ tự thực hiện các phép biến đổi', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_TRANSFORMATIONS',
        @level2type = N'COLUMN', @level2name = N'EXECUTION_ORDER';

    -- Thêm comment cho cột IS_MANDATORY
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Cờ đánh dấu nếu phép biến đổi này phải được áp dụng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_TRANSFORMATIONS',
        @level2type = N'COLUMN', @level2name = N'IS_MANDATORY';

    -- Thêm comment cho cột IS_REVERSIBLE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Cờ đánh dấu nếu phép biến đổi có thể đảo ngược', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_TRANSFORMATIONS',
        @level2type = N'COLUMN', @level2name = N'IS_REVERSIBLE';

    -- Thêm comment cho cột REVERSE_TRANSFORMATION_SQL
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Mã SQL để đảo ngược phép biến đổi', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_TRANSFORMATIONS',
        @level2type = N'COLUMN', @level2name = N'REVERSE_TRANSFORMATION_SQL';

    PRINT N'Các extended properties đã được thêm thành công';
END TRY
BEGIN CATCH
    PRINT N'Cảnh báo: Không thể thêm extended properties. Error: ' + ERROR_MESSAGE();
    PRINT N'Quá trình tạo bảng vẫn thành công.';
END CATCH
GO

PRINT N'Bảng FEATURE_TRANSFORMATIONS đã được tạo thành công';
GO