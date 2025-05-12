/*
Tên file: 02_trg_audit_model_parameters.sql
Mô tả: Tạo trigger TRG_AUDIT_MODEL_PARAMETERS để ghi nhật ký thay đổi trong bảng MODEL_PARAMETERS
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.0
*/

-- Kiểm tra và tạo bảng audit nếu chưa tồn tại
IF OBJECT_ID('MODEL_REGISTRY.dbo.AUDIT_MODEL_PARAMETERS', 'U') IS NULL
BEGIN
    CREATE TABLE MODEL_REGISTRY.dbo.AUDIT_MODEL_PARAMETERS (
        AUDIT_ID INT IDENTITY(1,1) PRIMARY KEY,
        PARAMETER_ID INT NOT NULL,
        MODEL_ID INT NOT NULL,
        ACTION_TYPE NVARCHAR(10) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
        FIELD_NAME NVARCHAR(128) NOT NULL,
        OLD_VALUE NVARCHAR(MAX) NULL,
        NEW_VALUE NVARCHAR(MAX) NULL,
        CHANGE_DATE DATETIME NOT NULL DEFAULT GETDATE(),
        CHANGED_BY NVARCHAR(128) NOT NULL DEFAULT SUSER_SNAME(),
        HOST_NAME NVARCHAR(128) NOT NULL DEFAULT HOST_NAME(),
        CHANGE_REASON NVARCHAR(500) NULL -- Lý do thay đổi tham số
    );
    
    PRINT 'Đã tạo bảng AUDIT_MODEL_PARAMETERS để ghi nhật ký thay đổi';
END

-- Thêm cột CHANGE_REASON vào bảng MODEL_PARAMETERS nếu chưa tồn tại
IF NOT EXISTS (
    SELECT 1 FROM sys.columns 
    WHERE object_id = OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_PARAMETERS') 
    AND name = 'CHANGE_REASON'
)
BEGIN
    ALTER TABLE MODEL_REGISTRY.dbo.MODEL_PARAMETERS
    ADD CHANGE_REASON NVARCHAR(500) NULL;
    
    PRINT 'Đã thêm cột CHANGE_REASON vào bảng MODEL_PARAMETERS';
END

-- Kiểm tra nếu trigger đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.TRG_AUDIT_MODEL_PARAMETERS', 'TR') IS NOT NULL
    DROP TRIGGER MODEL_REGISTRY.dbo.TRG_AUDIT_MODEL_PARAMETERS;
GO

-- Tạo trigger TRG_AUDIT_MODEL_PARAMETERS
CREATE TRIGGER MODEL_REGISTRY.dbo.TRG_AUDIT_MODEL_PARAMETERS
ON MODEL_REGISTRY.dbo.MODEL_PARAMETERS
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @action_type NVARCHAR(10);
    DECLARE @change_reason NVARCHAR(500) = NULL;
    
    -- Xác định loại thay đổi
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @action_type = 'UPDATE';
    ELSE IF EXISTS (SELECT * FROM inserted)
        SET @action_type = 'INSERT';
    ELSE
        SET @action_type = 'DELETE';
    
    -- Lấy lý do thay đổi từ bảng CONTEXT_INFO nếu có
    IF @action_type IN ('UPDATE', 'INSERT')
    BEGIN
        -- Kiểm tra xem đã thiết lập CONTEXT_INFO chưa
        DECLARE @context VARBINARY(128) = CONTEXT_INFO();
        IF @context IS NOT NULL
        BEGIN
            SET @change_reason = CAST(@context AS NVARCHAR(500));
        END
        ELSE
        BEGIN
            -- Nếu không có, lấy từ bảng inserted
            SELECT TOP 1 @change_reason = CHANGE_REASON
            FROM inserted;
        END
    END
    
    -- Ghi nhật ký cho các thao tác INSERT
    IF @action_type = 'INSERT'
    BEGIN
        INSERT INTO MODEL_REGISTRY.dbo.AUDIT_MODEL_PARAMETERS (
            PARAMETER_ID,
            MODEL_ID,
            ACTION_TYPE, 
            FIELD_NAME, 
            OLD_VALUE, 
            NEW_VALUE,
            CHANGE_REASON
        )
        SELECT 
            i.PARAMETER_ID,
            i.MODEL_ID,
            'INSERT',
            c.name, -- Tên cột
            NULL,   -- Không có giá trị cũ
            CASE 
                WHEN c.name = 'PARAMETER_VALUE' AND i.PARAMETER_VALUE IS NOT NULL THEN
                    CAST(i.PARAMETER_VALUE AS NVARCHAR(MAX))
                WHEN c.name <> 'PARAMETER_VALUE' THEN
                    CAST(i.[c.name] AS NVARCHAR(MAX))
                ELSE NULL
            END,
            @change_reason
        FROM inserted i
        CROSS JOIN sys.columns c
        WHERE c.object_id = OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_PARAMETERS')
          AND c.name NOT IN ('CREATED_DATE', 'CREATED_BY', 'UPDATED_DATE', 'UPDATED_BY', 'CHANGE_REASON');
    END
    
    -- Ghi nhật ký cho các thao tác UPDATE
    ELSE IF @action_type = 'UPDATE'
    BEGIN
        INSERT INTO MODEL_REGISTRY.dbo.AUDIT_MODEL_PARAMETERS (
            PARAMETER_ID,
            MODEL_ID,
            ACTION_TYPE, 
            FIELD_NAME, 
            OLD_VALUE, 
            NEW_VALUE,
            CHANGE_REASON
        )
        SELECT 
            i.PARAMETER_ID,
            i.MODEL_ID,
            'UPDATE',
            c.name, -- Tên cột
            CASE 
                WHEN c.name = 'PARAMETER_VALUE' AND d.PARAMETER_VALUE IS NOT NULL THEN
                    CAST(d.PARAMETER_VALUE AS NVARCHAR(MAX))
                WHEN c.name <> 'PARAMETER_VALUE' THEN
                    CAST(d.[c.name] AS NVARCHAR(MAX))
                ELSE NULL
            END,
            CASE 
                WHEN c.name = 'PARAMETER_VALUE' AND i.PARAMETER_VALUE IS NOT NULL THEN
                    CAST(i.PARAMETER_VALUE AS NVARCHAR(MAX))
                WHEN c.name <> 'PARAMETER_VALUE' THEN
                    CAST(i.[c.name] AS NVARCHAR(MAX))
                ELSE NULL
            END,
            @change_reason
        FROM deleted d
        JOIN inserted i ON d.PARAMETER_ID = i.PARAMETER_ID
        CROSS JOIN sys.columns c
        WHERE c.object_id = OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_PARAMETERS')
          AND c.name NOT IN ('CREATED_DATE', 'CREATED_BY', 'UPDATED_DATE', 'UPDATED_BY', 'CHANGE_REASON')
          AND (
                 (d.[c.name] IS NULL AND i.[c.name] IS NOT NULL)
              OR (d.[c.name] IS NOT NULL AND i.[c.name] IS NULL)
              OR d.[c.name] <> i.[c.name]
          );
    END
    
    -- Ghi nhật ký cho các thao tác DELETE
    ELSE
    BEGIN
        INSERT INTO MODEL_REGISTRY.dbo.AUDIT_MODEL_PARAMETERS (
            PARAMETER_ID,
            MODEL_ID,
            ACTION_TYPE, 
            FIELD_NAME, 
            OLD_VALUE, 
            NEW_VALUE,
            CHANGE_REASON
        )
        SELECT 
            d.PARAMETER_ID,
            d.MODEL_ID,
            'DELETE',
            c.name, -- Tên cột
            CASE 
                WHEN c.name = 'PARAMETER_VALUE' AND d.PARAMETER_VALUE IS NOT NULL THEN
                    CAST(d.PARAMETER_VALUE AS NVARCHAR(MAX))
                WHEN c.name <> 'PARAMETER_VALUE' THEN
                    CAST(d.[c.name] AS NVARCHAR(MAX))
                ELSE NULL
            END,
            NULL,    -- Không có giá trị mới
            NULL     -- Không có lý do thay đổi cho DELETE
        FROM deleted d
        CROSS JOIN sys.columns c
        WHERE c.object_id = OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_PARAMETERS')
          AND c.name NOT IN ('CREATED_DATE', 'CREATED_BY', 'UPDATED_DATE', 'UPDATED_BY', 'CHANGE_REASON');
    END
    
    -- Cập nhật trường UPDATED_BY và UPDATED_DATE trong bảng MODEL_PARAMETERS cho các thao tác UPDATE
    IF @action_type = 'UPDATE'
    BEGIN
        UPDATE MODEL_REGISTRY.dbo.MODEL_PARAMETERS
        SET 
            UPDATED_BY = SUSER_SNAME(),
            UPDATED_DATE = GETDATE()
        FROM MODEL_REGISTRY.dbo.MODEL_PARAMETERS mp
        JOIN inserted i ON mp.PARAMETER_ID = i.PARAMETER_ID;
    END
    
    -- Reset CONTEXT_INFO sau khi sử dụng
    SET CONTEXT_INFO 0x;
END;
GO

-- Tạo stored procedure để thiết lập lý do thay đổi
IF OBJECT_ID('MODEL_REGISTRY.dbo.SET_PARAMETER_CHANGE_REASON', 'P') IS NOT NULL
    DROP PROCEDURE MODEL_REGISTRY.dbo.SET_PARAMETER_CHANGE_REASON;
GO

CREATE PROCEDURE MODEL_REGISTRY.dbo.SET_PARAMETER_CHANGE_REASON
    @REASON NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Đặt CONTEXT_INFO để sử dụng trong trigger
    SET CONTEXT_INFO CAST(@REASON AS VARBINARY(128));
    
    PRINT 'Đã thiết lập lý do thay đổi: ' + @REASON;
END;
GO

-- Thêm comment cho trigger và stored procedure
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Trigger ghi nhật ký thay đổi trong bảng MODEL_PARAMETERS', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TRIGGER',  @level1name = N'TRG_AUDIT_MODEL_PARAMETERS';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Thiết lập lý do thay đổi tham số mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'PROCEDURE',  @level1name = N'SET_PARAMETER_CHANGE_REASON';
GO

PRINT 'Trigger TRG_AUDIT_MODEL_PARAMETERS và stored procedure SET_PARAMETER_CHANGE_REASON đã được tạo thành công';
GO