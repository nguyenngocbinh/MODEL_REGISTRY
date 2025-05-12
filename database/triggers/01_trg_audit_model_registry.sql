/*
Tên file: 01_trg_audit_model_registry.sql
Mô tả: Tạo trigger TRG_AUDIT_MODEL_REGISTRY để ghi nhật ký thay đổi trong bảng MODEL_REGISTRY
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.0
*/

-- Kiểm tra và tạo bảng audit nếu chưa tồn tại
IF OBJECT_ID('MODEL_REGISTRY.dbo.AUDIT_MODEL_REGISTRY', 'U') IS NULL
BEGIN
    CREATE TABLE MODEL_REGISTRY.dbo.AUDIT_MODEL_REGISTRY (
        AUDIT_ID INT IDENTITY(1,1) PRIMARY KEY,
        MODEL_ID INT NOT NULL,
        ACTION_TYPE NVARCHAR(10) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
        FIELD_NAME NVARCHAR(128) NOT NULL,
        OLD_VALUE NVARCHAR(MAX) NULL,
        NEW_VALUE NVARCHAR(MAX) NULL,
        CHANGE_DATE DATETIME NOT NULL DEFAULT GETDATE(),
        CHANGED_BY NVARCHAR(128) NOT NULL DEFAULT SUSER_SNAME(),
        HOST_NAME NVARCHAR(128) NOT NULL DEFAULT HOST_NAME()
    );
    
    PRINT 'Đã tạo bảng AUDIT_MODEL_REGISTRY để ghi nhật ký thay đổi';
END

-- Kiểm tra nếu trigger đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.TRG_AUDIT_MODEL_REGISTRY', 'TR') IS NOT NULL
    DROP TRIGGER MODEL_REGISTRY.dbo.TRG_AUDIT_MODEL_REGISTRY;
GO

-- Tạo trigger TRG_AUDIT_MODEL_REGISTRY
CREATE TRIGGER MODEL_REGISTRY.dbo.TRG_AUDIT_MODEL_REGISTRY
ON MODEL_REGISTRY.dbo.MODEL_REGISTRY
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @action_type NVARCHAR(10);
    
    -- Xác định loại thay đổi
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @action_type = 'UPDATE';
    ELSE IF EXISTS (SELECT * FROM inserted)
        SET @action_type = 'INSERT';
    ELSE
        SET @action_type = 'DELETE';
    
    -- Ghi nhật ký cho các thao tác INSERT
    IF @action_type = 'INSERT'
    BEGIN
        INSERT INTO MODEL_REGISTRY.dbo.AUDIT_MODEL_REGISTRY (
            MODEL_ID, 
            ACTION_TYPE, 
            FIELD_NAME, 
            OLD_VALUE, 
            NEW_VALUE
        )
        SELECT 
            i.MODEL_ID,
            'INSERT',
            c.name, -- Tên cột
            NULL,   -- Không có giá trị cũ
            CASE 
                WHEN SQL_VARIANT_PROPERTY(i.[MODEL_NAME], 'BaseType') = 'date' 
                    THEN CONVERT(NVARCHAR, i.[MODEL_NAME], 121)
                ELSE CAST(i.[MODEL_NAME] AS NVARCHAR(MAX)) 
            END
        FROM inserted i
        CROSS JOIN sys.columns c
        WHERE c.object_id = OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_REGISTRY')
          AND c.name NOT IN ('CREATED_DATE', 'CREATED_BY', 'UPDATED_DATE', 'UPDATED_BY');
    END
    
    -- Ghi nhật ký cho các thao tác UPDATE
    ELSE IF @action_type = 'UPDATE'
    BEGIN
        INSERT INTO MODEL_REGISTRY.dbo.AUDIT_MODEL_REGISTRY (
            MODEL_ID, 
            ACTION_TYPE, 
            FIELD_NAME, 
            OLD_VALUE, 
            NEW_VALUE
        )
        SELECT 
            i.MODEL_ID,
            'UPDATE',
            c.name, -- Tên cột
            CASE 
                WHEN c.system_type_id = 61 /* datetime */ 
                    THEN CONVERT(NVARCHAR, d.[c.name], 121)
                ELSE CAST(d.[c.name] AS NVARCHAR(MAX)) 
            END,
            CASE 
                WHEN c.system_type_id = 61 /* datetime */ 
                    THEN CONVERT(NVARCHAR, i.[c.name], 121)
                ELSE CAST(i.[c.name] AS NVARCHAR(MAX)) 
            END
        FROM deleted d
        JOIN inserted i ON d.MODEL_ID = i.MODEL_ID
        CROSS JOIN sys.columns c
        WHERE c.object_id = OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_REGISTRY')
          AND c.name NOT IN ('CREATED_DATE', 'CREATED_BY', 'UPDATED_DATE', 'UPDATED_BY')
          AND (
                 (d.[c.name] IS NULL AND i.[c.name] IS NOT NULL)
              OR (d.[c.name] IS NOT NULL AND i.[c.name] IS NULL)
              OR d.[c.name] <> i.[c.name]
          );
    END
    
    -- Ghi nhật ký cho các thao tác DELETE
    ELSE
    BEGIN
        INSERT INTO MODEL_REGISTRY.dbo.AUDIT_MODEL_REGISTRY (
            MODEL_ID, 
            ACTION_TYPE, 
            FIELD_NAME, 
            OLD_VALUE, 
            NEW_VALUE
        )
        SELECT 
            d.MODEL_ID,
            'DELETE',
            c.name, -- Tên cột
            CASE 
                WHEN c.system_type_id = 61 /* datetime */ 
                    THEN CONVERT(NVARCHAR, d.[c.name], 121)
                ELSE CAST(d.[c.name] AS NVARCHAR(MAX)) 
            END,
            NULL    -- Không có giá trị mới
        FROM deleted d
        CROSS JOIN sys.columns c
        WHERE c.object_id = OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_REGISTRY')
          AND c.name NOT IN ('CREATED_DATE', 'CREATED_BY', 'UPDATED_DATE', 'UPDATED_BY');
    END
    
    -- Cập nhật trường UPDATED_BY và UPDATED_DATE trong bảng MODEL_REGISTRY cho các thao tác UPDATE
    IF @action_type = 'UPDATE'
    BEGIN
        UPDATE MODEL_REGISTRY.dbo.MODEL_REGISTRY
        SET 
            UPDATED_BY = SUSER_SNAME(),
            UPDATED_DATE = GETDATE()
        FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY m
        JOIN inserted i ON m.MODEL_ID = i.MODEL_ID;
    END
END;
GO

-- Thêm comment cho trigger
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Trigger ghi nhật ký thay đổi trong bảng MODEL_REGISTRY', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TRIGGER',  @level1name = N'TRG_AUDIT_MODEL_REGISTRY';
GO

PRINT 'Trigger TRG_AUDIT_MODEL_REGISTRY đã được tạo thành công';
GO