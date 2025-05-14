/*
Tên file: 03_model_parameters.sql
Mô tả: Tạo bảng MODEL_PARAMETERS để lưu trữ tham số và hệ số của các mô hình
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.1 - Sửa lỗi extended properties
*/

-- Xác nhận database đã được chọn
IF DB_NAME() != 'MODEL_REGISTRY'
BEGIN
    RAISERROR('Vui lòng đảm bảo đang sử dụng database MODEL_REGISTRY', 16, 1)
    RETURN
END

-- Kiểm tra nếu bảng đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_PARAMETERS', 'U') IS NOT NULL
    DROP TABLE MODEL_REGISTRY.dbo.MODEL_PARAMETERS;
GO

-- Tạo bảng MODEL_PARAMETERS
CREATE TABLE MODEL_REGISTRY.dbo.MODEL_PARAMETERS (
    PARAMETER_ID INT IDENTITY(1,1) PRIMARY KEY,
    MODEL_ID INT NOT NULL,
    PARAMETER_NAME NVARCHAR(100) NOT NULL,
    PARAMETER_DESCRIPTION NVARCHAR(500) NULL,
    PARAMETER_VALUE NVARCHAR(MAX) NOT NULL,
    PARAMETER_TYPE NVARCHAR(50) NOT NULL, -- 'COEFFICIENT', 'THRESHOLD', 'SCALING', 'LOOKUP', 'CALIBRATION'
    PARAMETER_FORMAT NVARCHAR(20) NOT NULL, -- 'NUMERIC', 'JSON', 'TEXT'
    MIN_VALUE FLOAT NULL,
    MAX_VALUE FLOAT NULL,
    IS_CALIBRATED BIT DEFAULT 0, -- Đánh dấu các tham số được hiệu chỉnh
    LAST_CALIBRATION_DATE DATE NULL,
    EFF_DATE DATE NOT NULL,
    EXP_DATE DATE NOT NULL,
    IS_ACTIVE BIT DEFAULT 1,
    CHANGE_REASON NVARCHAR(500) NULL, -- Lý do thay đổi tham số
    CREATED_BY NVARCHAR(50) DEFAULT SUSER_NAME(),
    CREATED_DATE DATETIME DEFAULT GETDATE(),
    UPDATED_BY NVARCHAR(50) NULL,
    UPDATED_DATE DATETIME NULL,
    FOREIGN KEY (MODEL_ID) REFERENCES MODEL_REGISTRY.dbo.MODEL_REGISTRY(MODEL_ID)
);
GO

-- Tạo các chỉ mục (indexes) để tối ưu hiệu suất truy vấn
CREATE INDEX IDX_PARAMETERS_MODEL_ID ON MODEL_REGISTRY.dbo.MODEL_PARAMETERS(MODEL_ID);
CREATE INDEX IDX_PARAMETERS_NAME ON MODEL_REGISTRY.dbo.MODEL_PARAMETERS(PARAMETER_NAME);
CREATE INDEX IDX_PARAMETERS_TYPE ON MODEL_REGISTRY.dbo.MODEL_PARAMETERS(PARAMETER_TYPE);
CREATE INDEX IDX_PARAMETERS_DATES ON MODEL_REGISTRY.dbo.MODEL_PARAMETERS(EFF_DATE, EXP_DATE);
CREATE INDEX IDX_PARAMETERS_ACTIVE ON MODEL_REGISTRY.dbo.MODEL_PARAMETERS(IS_ACTIVE);
GO

-- Thêm comment cho bảng và các cột quan trọng
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Bảng lưu trữ tham số và hệ số của các mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_PARAMETERS';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'ID của tham số, khóa chính tự động tăng', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_PARAMETERS',
    @level2type = N'COLUMN', @level2name = N'PARAMETER_ID';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'ID của mô hình, tham chiếu đến bảng MODEL_REGISTRY', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_PARAMETERS',
    @level2type = N'COLUMN', @level2name = N'MODEL_ID';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Tên tham số', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_PARAMETERS',
    @level2type = N'COLUMN', @level2name = N'PARAMETER_NAME';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Giá trị tham số', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_PARAMETERS',
    @level2type = N'COLUMN', @level2name = N'PARAMETER_VALUE';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Loại tham số: COEFFICIENT (hệ số), THRESHOLD (ngưỡng), SCALING (hệ số tỷ lệ), LOOKUP (tra cứu), CALIBRATION (hiệu chỉnh)', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_PARAMETERS',
    @level2type = N'COLUMN', @level2name = N'PARAMETER_TYPE';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Định dạng tham số: NUMERIC (số), JSON (chuỗi JSON), TEXT (văn bản)', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_PARAMETERS',
    @level2type = N'COLUMN', @level2name = N'PARAMETER_FORMAT';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Đánh dấu tham số đã được hiệu chỉnh', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_PARAMETERS',
    @level2type = N'COLUMN', @level2name = N'IS_CALIBRATED';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Ngày hiệu chỉnh gần nhất', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_PARAMETERS',
    @level2type = N'COLUMN', @level2name = N'LAST_CALIBRATION_DATE';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Ngày tham số bắt đầu có hiệu lực', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_PARAMETERS',
    @level2type = N'COLUMN', @level2name = N'EFF_DATE';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Ngày tham số hết hiệu lực', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_PARAMETERS',
    @level2type = N'COLUMN', @level2name = N'EXP_DATE';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Lý do thay đổi tham số', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE',  @level1name = N'MODEL_PARAMETERS',
    @level2type = N'COLUMN', @level2name = N'CHANGE_REASON';
GO

PRINT N'Bảng MODEL_PARAMETERS đã được tạo thành công';
GO