/*
Tên file: 18_feature_model_mapping.sql
Mô tả: Tạo bảng FEATURE_MODEL_MAPPING để quản lý mối quan hệ giữa đặc trưng và các mô hình
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
IF OBJECT_ID('MODEL_REGISTRY.dbo.FEATURE_MODEL_MAPPING', 'U') IS NOT NULL
    DROP TABLE MODEL_REGISTRY.dbo.FEATURE_MODEL_MAPPING;
GO

-- Tạo bảng FEATURE_MODEL_MAPPING
CREATE TABLE MODEL_REGISTRY.dbo.FEATURE_MODEL_MAPPING (
    MAPPING_ID INT IDENTITY(1,1) PRIMARY KEY,
    FEATURE_ID INT NOT NULL,
    MODEL_ID INT NOT NULL,
    USAGE_TYPE NVARCHAR(50) NOT NULL, -- 'INPUT', 'OUTPUT', 'DERIVED', 'INTERMEDIATE'
    FEATURE_IMPORTANCE FLOAT NULL, -- Feature importance in this model (0-1)
    FEATURE_WEIGHT FLOAT NULL, -- Model coefficient/weight for this feature
    IS_MANDATORY BIT DEFAULT 1, -- Flag if feature is required for model
    TRANSFORMATION_APPLIED NVARCHAR(MAX) NULL, -- Description of transformations applied
    FEATURE_RANK INT NULL, -- Rank of feature importance in model
    PERMUTATION_IMPORTANCE FLOAT NULL, -- Importance measured by permutation method
    SHAP_VALUE FLOAT NULL, -- SHAP value for feature importance
    PARTIAL_DEPENDENCE_DATA NVARCHAR(MAX) NULL, -- JSON with partial dependence data
    ICE_CURVES_DATA NVARCHAR(MAX) NULL, -- JSON with Individual Conditional Expectation curves
    FEATURE_SPECIFICATION NVARCHAR(MAX) NULL, -- Requirements or specifications for this feature
    USAGE_DESCRIPTION NVARCHAR(500) NULL, -- How this feature is used in the model
    EFF_DATE DATE DEFAULT GETDATE(),
    EXP_DATE DATE DEFAULT '9999-12-31',
    CREATED_BY NVARCHAR(50) DEFAULT SUSER_NAME(),
    CREATED_DATE DATETIME DEFAULT GETDATE(),
    UPDATED_BY NVARCHAR(50) NULL,
    UPDATED_DATE DATETIME NULL,
    IS_ACTIVE BIT DEFAULT 1,
    FOREIGN KEY (FEATURE_ID) REFERENCES MODEL_REGISTRY.dbo.FEATURE_REGISTRY(FEATURE_ID),
    FOREIGN KEY (MODEL_ID) REFERENCES MODEL_REGISTRY.dbo.MODEL_REGISTRY(MODEL_ID),
    CONSTRAINT UC_FEATURE_MODEL UNIQUE (FEATURE_ID, MODEL_ID, USAGE_TYPE)
);
GO

-- Tạo chỉ mục để tăng tốc độ truy vấn
CREATE INDEX IDX_FM_MAPPING_FEATURE_ID ON MODEL_REGISTRY.dbo.FEATURE_MODEL_MAPPING(FEATURE_ID);
CREATE INDEX IDX_FM_MAPPING_MODEL_ID ON MODEL_REGISTRY.dbo.FEATURE_MODEL_MAPPING(MODEL_ID);
CREATE INDEX IDX_FM_MAPPING_USAGE_TYPE ON MODEL_REGISTRY.dbo.FEATURE_MODEL_MAPPING(USAGE_TYPE);
CREATE INDEX IDX_FM_MAPPING_IMPORTANCE ON MODEL_REGISTRY.dbo.FEATURE_MODEL_MAPPING(FEATURE_IMPORTANCE);
CREATE INDEX IDX_FM_MAPPING_ACTIVE ON MODEL_REGISTRY.dbo.FEATURE_MODEL_MAPPING(IS_ACTIVE);
CREATE INDEX IDX_FM_MAPPING_DATES ON MODEL_REGISTRY.dbo.FEATURE_MODEL_MAPPING(EFF_DATE, EXP_DATE);
GO

-- Thêm comment cho bảng và các cột
BEGIN TRY
    -- Thêm comment cho bảng
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Bảng quản lý mối quan hệ giữa đặc trưng và các mô hình', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_MODEL_MAPPING';

    -- Thêm comment cho cột MAPPING_ID
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'ID của bản đồ, khóa chính tự động tăng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_MODEL_MAPPING',
        @level2type = N'COLUMN', @level2name = N'MAPPING_ID';

    -- Thêm comment cho cột FEATURE_ID
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'ID của đặc trưng, tham chiếu đến bảng FEATURE_REGISTRY', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_MODEL_MAPPING',
        @level2type = N'COLUMN', @level2name = N'FEATURE_ID';

    -- Thêm comment cho cột MODEL_ID
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'ID của mô hình, tham chiếu đến bảng MODEL_REGISTRY', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_MODEL_MAPPING',
        @level2type = N'COLUMN', @level2name = N'MODEL_ID';

    -- Thêm comment cho cột USAGE_TYPE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Loại sử dụng: INPUT (đầu vào), OUTPUT (đầu ra), DERIVED (dẫn xuất), INTERMEDIATE (trung gian)', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_MODEL_MAPPING',
        @level2type = N'COLUMN', @level2name = N'USAGE_TYPE';

    -- Thêm comment cho cột FEATURE_IMPORTANCE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Mức độ quan trọng của đặc trưng trong mô hình này (0-1)', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_MODEL_MAPPING',
        @level2type = N'COLUMN', @level2name = N'FEATURE_IMPORTANCE';

    -- Thêm comment cho cột FEATURE_WEIGHT
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Hệ số/trọng số mô hình cho đặc trưng này', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_MODEL_MAPPING',
        @level2type = N'COLUMN', @level2name = N'FEATURE_WEIGHT';

    -- Thêm comment cho cột IS_MANDATORY
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Cờ đánh dấu nếu đặc trưng là bắt buộc cho mô hình', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_MODEL_MAPPING',
        @level2type = N'COLUMN', @level2name = N'IS_MANDATORY';

    -- Thêm comment cho cột TRANSFORMATION_APPLIED
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Mô tả các phép biến đổi được áp dụng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_MODEL_MAPPING',
        @level2type = N'COLUMN', @level2name = N'TRANSFORMATION_APPLIED';

    -- Thêm comment cho cột FEATURE_RANK
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Xếp hạng mức độ quan trọng của đặc trưng trong mô hình', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_MODEL_MAPPING',
        @level2type = N'COLUMN', @level2name = N'FEATURE_RANK';

    -- Thêm comment cho cột PERMUTATION_IMPORTANCE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Mức độ quan trọng được đo bằng phương pháp hoán vị', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_MODEL_MAPPING',
        @level2type = N'COLUMN', @level2name = N'PERMUTATION_IMPORTANCE';

    -- Thêm comment cho cột SHAP_VALUE
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Giá trị SHAP cho mức độ quan trọng của đặc trưng', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_MODEL_MAPPING',
        @level2type = N'COLUMN', @level2name = N'SHAP_VALUE';

    -- Thêm comment cho cột PARTIAL_DEPENDENCE_DATA
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Dữ liệu phụ thuộc một phần dưới dạng JSON', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_MODEL_MAPPING',
        @level2type = N'COLUMN', @level2name = N'PARTIAL_DEPENDENCE_DATA';

    -- Thêm comment cho cột USAGE_DESCRIPTION
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Cách sử dụng đặc trưng này trong mô hình', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'FEATURE_MODEL_MAPPING',
        @level2type = N'COLUMN', @level2name = N'USAGE_DESCRIPTION';

    PRINT N'Các extended properties đã được thêm thành công';
END TRY
BEGIN CATCH
    PRINT N'Cảnh báo: Không thể thêm extended properties. Error: ' + ERROR_MESSAGE();
    PRINT N'Quá trình tạo bảng vẫn thành công.';
END CATCH
GO

PRINT N'Bảng FEATURE_MODEL_MAPPING đã được tạo thành công';
GO