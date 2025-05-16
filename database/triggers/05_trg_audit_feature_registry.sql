/*
Tên file: 05_trg_audit_feature_registry.sql
Mô tả: Tạo trigger TRG_AUDIT_FEATURE_REGISTRY để ghi nhật ký thay đổi trong bảng FEATURE_REGISTRY
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-16
Phiên bản: 1.0
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra và tạo bảng audit nếu chưa tồn tại
IF OBJECT_ID('MODEL_REGISTRY.dbo.AUDIT_FEATURE_REGISTRY', 'U') IS NULL
BEGIN
    CREATE TABLE MODEL_REGISTRY.dbo.AUDIT_FEATURE_REGISTRY (
        AUDIT_ID INT IDENTITY(1,1) PRIMARY KEY,
        FEATURE_ID INT NOT NULL,
        ACTION_TYPE NVARCHAR(10) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
        FIELD_NAME NVARCHAR(128) NOT NULL,
        OLD_VALUE NVARCHAR(MAX) NULL,
        NEW_VALUE NVARCHAR(MAX) NULL,
        CHANGE_DATE DATETIME NOT NULL DEFAULT GETDATE(),
        CHANGED_BY NVARCHAR(128) NOT NULL DEFAULT SUSER_SNAME(),
        HOST_NAME NVARCHAR(128) NOT NULL DEFAULT HOST_NAME(),
        AFFECTED_MODELS NVARCHAR(MAX) NULL -- Danh sách ID các mô hình bị ảnh hưởng
    );
    
    PRINT N'Đã tạo bảng AUDIT_FEATURE_REGISTRY để ghi nhật ký thay đổi';
END

-- Kiểm tra nếu trigger đã tồn tại thì xóa
IF OBJECT_ID('dbo.TRG_AUDIT_FEATURE_REGISTRY', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TRG_AUDIT_FEATURE_REGISTRY;
GO

-- Tạo trigger TRG_AUDIT_FEATURE_REGISTRY
CREATE TRIGGER dbo.TRG_AUDIT_FEATURE_REGISTRY
ON MODEL_REGISTRY.dbo.FEATURE_REGISTRY
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
    
    -- Tạo bảng tạm để lưu trữ danh sách mô hình bị ảnh hưởng bởi mỗi đặc trưng
    DECLARE @AffectedModels TABLE (
        FEATURE_ID INT,
        MODEL_LIST NVARCHAR(MAX)
    );
    
    -- Xác định các mô hình bị ảnh hưởng bởi việc thay đổi đặc trưng
    INSERT INTO @AffectedModels (FEATURE_ID, MODEL_LIST)
    SELECT 
        f.FEATURE_ID,
        STRING_AGG(CONVERT(NVARCHAR(10), fmm.MODEL_ID), ', ') AS MODEL_LIST
    FROM (
        SELECT FEATURE_ID FROM inserted
        UNION
        SELECT FEATURE_ID FROM deleted
    ) f
    LEFT JOIN MODEL_REGISTRY.dbo.FEATURE_MODEL_MAPPING fmm ON f.FEATURE_ID = fmm.FEATURE_ID
    WHERE fmm.IS_ACTIVE = 1
    GROUP BY f.FEATURE_ID;
    
    -- Ghi nhật ký cho các thao tác INSERT
    IF @action_type = 'INSERT'
    BEGIN
        INSERT INTO MODEL_REGISTRY.dbo.AUDIT_FEATURE_REGISTRY (
            FEATURE_ID, 
            ACTION_TYPE, 
            FIELD_NAME, 
            OLD_VALUE, 
            NEW_VALUE,
            AFFECTED_MODELS
        )
        SELECT 
            i.FEATURE_ID,
            'INSERT',
            c.name, -- Tên cột
            NULL,   -- Không có giá trị cũ
            CASE 
                WHEN c.system_type_id = 61 /* datetime */ 
                    THEN CONVERT(NVARCHAR, i.[c.name], 121)
                ELSE CAST(i.[c.name] AS NVARCHAR(MAX)) 
            END,
            am.MODEL_LIST
        FROM inserted i
        LEFT JOIN @AffectedModels am ON i.FEATURE_ID = am.FEATURE_ID
        CROSS JOIN sys.columns c
        WHERE c.object_id = OBJECT_ID('MODEL_REGISTRY.dbo.FEATURE_REGISTRY')
          AND c.name NOT IN ('CREATED_DATE', 'CREATED_BY', 'UPDATED_DATE', 'UPDATED_BY');
    END
    
    -- Ghi nhật ký cho các thao tác UPDATE
    ELSE IF @action_type = 'UPDATE'
    BEGIN
        INSERT INTO MODEL_REGISTRY.dbo.AUDIT_FEATURE_REGISTRY (
            FEATURE_ID, 
            ACTION_TYPE, 
            FIELD_NAME, 
            OLD_VALUE, 
            NEW_VALUE,
            AFFECTED_MODELS
        )
        SELECT 
            i.FEATURE_ID,
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
            END,
            am.MODEL_LIST
        FROM deleted d
        JOIN inserted i ON d.FEATURE_ID = i.FEATURE_ID
        LEFT JOIN @AffectedModels am ON i.FEATURE_ID = am.FEATURE_ID
        CROSS JOIN sys.columns c
        WHERE c.object_id = OBJECT_ID('MODEL_REGISTRY.dbo.FEATURE_REGISTRY')
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
        INSERT INTO MODEL_REGISTRY.dbo.AUDIT_FEATURE_REGISTRY (
            FEATURE_ID, 
            ACTION_TYPE, 
            FIELD_NAME, 
            OLD_VALUE, 
            NEW_VALUE,
            AFFECTED_MODELS
        )
        SELECT 
            d.FEATURE_ID,
            'DELETE',
            c.name, -- Tên cột
            CASE 
                WHEN c.system_type_id = 61 /* datetime */ 
                    THEN CONVERT(NVARCHAR, d.[c.name], 121)
                ELSE CAST(d.[c.name] AS NVARCHAR(MAX)) 
            END,
            NULL,    -- Không có giá trị mới
            am.MODEL_LIST
        FROM deleted d
        LEFT JOIN @AffectedModels am ON d.FEATURE_ID = am.FEATURE_ID
        CROSS JOIN sys.columns c
        WHERE c.object_id = OBJECT_ID('MODEL_REGISTRY.dbo.FEATURE_REGISTRY')
          AND c.name NOT IN ('CREATED_DATE', 'CREATED_BY', 'UPDATED_DATE', 'UPDATED_BY');
    END
    
    -- Cập nhật trường UPDATED_BY và UPDATED_DATE trong bảng FEATURE_REGISTRY cho các thao tác UPDATE
    IF @action_type = 'UPDATE'
    BEGIN
        UPDATE MODEL_REGISTRY.dbo.FEATURE_REGISTRY
        SET 
            UPDATED_BY = SUSER_SNAME(),
            UPDATED_DATE = GETDATE()
        FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY fr
        JOIN inserted i ON fr.FEATURE_ID = i.FEATURE_ID;
    END
    
    -- Ghi thông báo về các mô hình bị ảnh hưởng 
    IF EXISTS (SELECT 1 FROM @AffectedModels WHERE MODEL_LIST IS NOT NULL)
    BEGIN
        DECLARE @AffectedFeatureList NVARCHAR(MAX) = '';
        
        SELECT @AffectedFeatureList = @AffectedFeatureList + 
               CASE WHEN @AffectedFeatureList = '' THEN '' ELSE '; ' END +
               'Feature ID: ' + CAST(FEATURE_ID AS NVARCHAR) + ' affects models: ' + MODEL_LIST
        FROM @AffectedModels
        WHERE MODEL_LIST IS NOT NULL;
        
        PRINT N'THÔNG BÁO: Các thay đổi đặc trưng ảnh hưởng đến các mô hình sau: ' + @AffectedFeatureList;
        
        -- Nếu là thao tác UPDATE hoặc DELETE, có thể cần cập nhật trạng thái các mô hình bị ảnh hưởng
        IF @action_type IN ('UPDATE', 'DELETE')
        BEGIN
            -- Cập nhật trạng thái cho các mô hình bị ảnh hưởng
            UPDATE MODEL_REGISTRY.dbo.MODEL_REGISTRY
            SET 
                MODEL_STATUS = 'NEEDS_REVIEW',
                UPDATED_BY = SUSER_SNAME(),
                UPDATED_DATE = GETDATE()
            WHERE MODEL_ID IN (
                SELECT CAST(value AS INT)
                FROM @AffectedModels
                CROSS APPLY STRING_SPLIT(MODEL_LIST, ',')
            );
            
            PRINT N'CẢNH BÁO: Các mô hình bị ảnh hưởng đã được đánh dấu là "NEEDS_REVIEW"';
        END
    END
END;
GO

-- Thêm comment cho trigger
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Trigger ghi nhật ký thay đổi trong bảng FEATURE_REGISTRY và theo dõi các mô hình bị ảnh hưởng', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TRIGGER',  @level1name = N'TRG_AUDIT_FEATURE_REGISTRY';
GO

PRINT N'Trigger TRG_AUDIT_FEATURE_REGISTRY đã được tạo thành công';
GO