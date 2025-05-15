/*
Tên file: 17_feature_dependencies.sql
Mô tả: Tạo bảng FEATURE_DEPENDENCIES để quản lý mối quan hệ phụ thuộc giữa các đặc trưng
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
IF OBJECT_ID('MODEL_REGISTRY.dbo.FEATURE_DEPENDENCIES', 'U') IS NOT NULL
    DROP TABLE MODEL_REGISTRY.dbo.FEATURE_DEPENDENCIES;
GO

-- Tạo bảng FEATURE_DEPENDENCIES
CREATE TABLE MODEL_REGISTRY.dbo.FEATURE_DEPENDENCIES (
    DEPENDENCY_ID INT IDENTITY(1,1) PRIMARY KEY,
    FEATURE_ID INT NOT NULL, -- Feature that depends on another
    DEPENDS_ON_FEATURE_ID INT NOT NULL, -- Feature that is depended upon
    DEPENDENCY_TYPE NVARCHAR(50) NOT NULL, -- 'DERIVATION', 'CALCULATION', 'CORRELATION', 'CAUSAL'
    DEPENDENCY_STRENGTH FLOAT NULL, -- Strength of dependency (0-1)
    DEPENDENCY_DESCRIPTION NVARCHAR(500) NULL, -- Description of the dependency relationship
    CALCULATION_LOGIC NVARCHAR(MAX) NULL, -- SQL or formula used in calculation
    REGRESSION_COEFFICIENT FLOAT NULL, -- When one feature is used in regression for another
    CORRELATION_VALUE FLOAT NULL, -- Statistical correlation between features
    MUTUAL_INFORMATION FLOAT NULL, -- Information theoretic measure of dependency
    VIF_VALUE FLOAT NULL, -- Variance Inflation Factor for multicollinearity
    UPDATED_FREQUENCY NVARCHAR(50) NULL, -- How often this dependency is recalculated
    LAST_UPDATED DATE NULL, -- When this dependency was last updated/verified
    CREATED_BY NVARCHAR(50) DEFAULT SUSER_NAME(),
    CREATED_DATE DATETIME DEFAULT GETDATE(),
    UPDATED_BY NVARCHAR(50) NULL,
    UPDATED_DATE DATETIME NULL,
    IS_ACTIVE BIT DEFAULT 1,
    FOREIGN KEY (FEATURE_ID) REFERENCES MODEL_REGISTRY.dbo.FEATURE_REGISTRY(FEATURE_ID),
    FOREIGN KEY (DEPENDS_ON_FEATURE_ID) REFERENCES MODEL_REGISTRY.dbo.FEATURE_REGISTRY(FEATURE_ID),
    CONSTRAINT UC_FEATURE_DEPENDENCY UNIQUE (FEATURE_ID, DEPENDS_ON_FEATURE_ID, DEPENDENCY_TYPE)
);
GO

-- Tạo chỉ mục để tăng tốc độ truy vấn
CREATE INDEX IDX_DEPENDENCY_FEATURE_ID ON MODEL_REGISTRY.dbo.FEATURE_DEPENDENCIES(FEATURE_ID);
CREATE INDEX IDX_DEPENDENCY_ON_FEATURE_ID ON MODEL_REGISTRY.dbo.FEATURE_DEPENDENCIES(DEPENDS_ON_FEATURE_ID);
CREATE INDEX IDX_DEPENDENCY_TYPE ON MODEL_REGISTRY.dbo.FEATURE_DEPENDENCIES(DEPENDENCY_TYPE);
CREATE INDEX IDX_DEPENDENCY_ACTIVE ON MODEL_REGISTRY.dbo.FEATURE_DEPENDENCIES(IS_ACTIVE);
GO

-- Thêm comment cho bảng và các cột
BEGIN TRY
    -- Thêm comment cho bảng
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Bảng quản lý mối quan hệ phụ thuộc giữa các đặc trưng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_DEPENDENCIES';

    -- Thêm comment cho cột DEPENDENCY_ID
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'ID của phụ thuộc, khóa chính tự động tăng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_DEPENDENCIES',
        @level2type = N'COLUMN', @level2name = N'DEPENDENCY_ID';

    -- Thêm comment cho cột FEATURE_ID
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'ID của đặc trưng phụ thuộc vào đặc trưng khác', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_DEPENDENCIES',
        @level2type = N'COLUMN', @level2name = N'FEATURE_ID';

    -- Thêm comment cho cột DEPENDS_ON_FEATURE_ID
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'ID của đặc trưng được phụ thuộc vào', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_DEPENDENCIES',
        @level2type = N'COLUMN', @level2name = N'DEPENDS_ON_FEATURE_ID';

    -- Thêm comment cho cột DEPENDENCY_TYPE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Loại phụ thuộc: DERIVATION (dẫn xuất), CALCULATION (tính toán), CORRELATION (tương quan), CAUSAL (nhân quả)', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_DEPENDENCIES',
        @level2type = N'COLUMN', @level2name = N'DEPENDENCY_TYPE';

    -- Thêm comment cho cột DEPENDENCY_STRENGTH
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Độ mạnh của phụ thuộc (0-1)', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_DEPENDENCIES',
        @level2type = N'COLUMN', @level2name = N'DEPENDENCY_STRENGTH';

    -- Thêm comment cho cột DEPENDENCY_DESCRIPTION
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Mô tả về mối quan hệ phụ thuộc', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_DEPENDENCIES',
        @level2type = N'COLUMN', @level2name = N'DEPENDENCY_DESCRIPTION';

    -- Thêm comment cho cột CALCULATION_LOGIC
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'SQL hoặc công thức được sử dụng trong tính toán', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_DEPENDENCIES',
        @level2type = N'COLUMN', @level2name = N'CALCULATION_LOGIC';

    -- Thêm comment cho cột REGRESSION_COEFFICIENT
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Hệ số hồi quy khi một đặc trưng được sử dụng trong hồi quy cho đặc trưng khác', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_DEPENDENCIES',
        @level2type = N'COLUMN', @level2name = N'REGRESSION_COEFFICIENT';

    -- Thêm comment cho cột CORRELATION_VALUE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Tương quan thống kê giữa các đặc trưng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_DEPENDENCIES',
        @level2type = N'COLUMN', @level2name = N'CORRELATION_VALUE';

    -- Thêm comment cho cột MUTUAL_INFORMATION
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Đo lường phụ thuộc theo lý thuyết thông tin', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_DEPENDENCIES',
        @level2type = N'COLUMN', @level2name = N'MUTUAL_INFORMATION';

    -- Thêm comment cho cột VIF_VALUE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Hệ số phóng đại phương sai (Variance Inflation Factor) đo lường đa cộng tuyến', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_DEPENDENCIES',
        @level2type = N'COLUMN', @level2name = N'VIF_VALUE';

    -- Thêm comment cho cột UPDATED_FREQUENCY
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Tần suất tính toán lại phụ thuộc này', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_DEPENDENCIES',
        @level2type = N'COLUMN', @level2name = N'UPDATED_FREQUENCY';

    PRINT N'Các extended properties đã được thêm thành công';
END TRY
BEGIN CATCH
    PRINT N'Cảnh báo: Không thể thêm extended properties. Error: ' + ERROR_MESSAGE();
    PRINT N'Quá trình tạo bảng vẫn thành công.';
END CATCH
GO

PRINT N'Bảng FEATURE_DEPENDENCIES đã được tạo thành công';
GO