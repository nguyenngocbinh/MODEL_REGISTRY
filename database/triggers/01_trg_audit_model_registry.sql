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
    DROP TRIGGER dbo.TRG_AUDIT_MODEL_REGISTRY;
GO

-- Tạo trigger TRG_AUDIT_MODEL_REGISTRY
CREATE TRIGGER dbo.TRG_AUDIT_MODEL_REGISTRY
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
        -- Lấy danh sách các cột cần kiểm tra
        DECLARE @InsertColumns TABLE (column_id INT, column_name NVARCHAR(128), system_type_id INT);
        
        INSERT INTO @InsertColumns
        SELECT 
            column_id, 
            name AS column_name,
            system_type_id
        FROM sys.columns 
        WHERE object_id = OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_REGISTRY')
        AND name NOT IN ('CREATED_DATE', 'CREATED_BY', 'UPDATED_DATE', 'UPDATED_BY');
        
        -- Xử lý từng cột cho mỗi MODEL_ID mới
        DECLARE @insert_model_id INT;
        DECLARE insert_model_cursor CURSOR FOR SELECT MODEL_ID FROM inserted;
        
        OPEN insert_model_cursor;
        FETCH NEXT FROM insert_model_cursor INTO @insert_model_id;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Xử lý từng cột
            DECLARE @insert_column_name NVARCHAR(128);
            DECLARE @insert_column_id INT;
            DECLARE @insert_system_type_id INT;
            DECLARE @insert_sql NVARCHAR(MAX);
            DECLARE @insert_params NVARCHAR(MAX);
            DECLARE @insert_value NVARCHAR(MAX);
            
            DECLARE insert_column_cursor CURSOR FOR 
            SELECT column_id, column_name, system_type_id FROM @InsertColumns;
            
            OPEN insert_column_cursor;
            FETCH NEXT FROM insert_column_cursor INTO @insert_column_id, @insert_column_name, @insert_system_type_id;
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- Xây dựng câu lệnh SQL động để lấy giá trị của cột
                SET @insert_sql = N'
                    SELECT @value = CASE 
                        WHEN ' + QUOTENAME(@insert_column_name) + ' IS NULL THEN NULL 
                        WHEN ' + CAST(@insert_system_type_id AS NVARCHAR) + ' = 61 THEN CONVERT(NVARCHAR(MAX), ' + QUOTENAME(@insert_column_name) + ', 121) 
                        ELSE CAST(' + QUOTENAME(@insert_column_name) + ' AS NVARCHAR(MAX)) 
                    END 
                    FROM inserted WHERE MODEL_ID = @model_id';
                
                SET @insert_params = N'@model_id INT, @value NVARCHAR(MAX) OUTPUT';
                SET @insert_value = NULL;
                
                -- Thực thi câu lệnh SQL động
                EXEC sp_executesql @insert_sql, @insert_params, 
                    @model_id = @insert_model_id, 
                    @value = @insert_value OUTPUT;
                
                -- Thêm bản ghi audit
                INSERT INTO MODEL_REGISTRY.dbo.AUDIT_MODEL_REGISTRY (
                    MODEL_ID, 
                    ACTION_TYPE, 
                    FIELD_NAME, 
                    OLD_VALUE, 
                    NEW_VALUE
                )
                VALUES (
                    @insert_model_id,
                    'INSERT',
                    @insert_column_name,
                    NULL, -- Không có giá trị cũ cho INSERT
                    @insert_value
                );
                
                FETCH NEXT FROM insert_column_cursor INTO @insert_column_id, @insert_column_name, @insert_system_type_id;
            END
            
            CLOSE insert_column_cursor;
            DEALLOCATE insert_column_cursor;
            
            FETCH NEXT FROM insert_model_cursor INTO @insert_model_id;
        END
        
        CLOSE insert_model_cursor;
        DEALLOCATE insert_model_cursor;
    END
    
    -- Ghi nhật ký cho các thao tác UPDATE
    ELSE IF @action_type = 'UPDATE'
    BEGIN
        -- Lấy danh sách các cột cần kiểm tra
        DECLARE @UpdateColumns TABLE (column_id INT, column_name NVARCHAR(128), system_type_id INT);
        
        INSERT INTO @UpdateColumns
        SELECT 
            column_id, 
            name AS column_name,
            system_type_id
        FROM sys.columns 
        WHERE object_id = OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_REGISTRY')
        AND name NOT IN ('CREATED_DATE', 'CREATED_BY', 'UPDATED_DATE', 'UPDATED_BY');
        
        -- Xử lý từng cột cho mỗi MODEL_ID được cập nhật
        DECLARE @update_model_id INT;
        DECLARE update_model_cursor CURSOR FOR 
        SELECT i.MODEL_ID 
        FROM inserted i
        JOIN deleted d ON i.MODEL_ID = d.MODEL_ID;
        
        OPEN update_model_cursor;
        FETCH NEXT FROM update_model_cursor INTO @update_model_id;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Xử lý từng cột
            DECLARE @update_column_name NVARCHAR(128);
            DECLARE @update_column_id INT;
            DECLARE @update_system_type_id INT;
            DECLARE @update_sql NVARCHAR(MAX);
            DECLARE @update_params NVARCHAR(MAX);
            DECLARE @update_old_value NVARCHAR(MAX);
            DECLARE @update_new_value NVARCHAR(MAX);
            
            DECLARE update_column_cursor CURSOR FOR 
            SELECT column_id, column_name, system_type_id FROM @UpdateColumns;
            
            OPEN update_column_cursor;
            FETCH NEXT FROM update_column_cursor INTO @update_column_id, @update_column_name, @update_system_type_id;
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- Xây dựng câu lệnh SQL động để lấy giá trị cũ và mới của cột
                SET @update_sql = N'
                    SELECT 
                        @old_value = CASE 
                            WHEN d.' + QUOTENAME(@update_column_name) + ' IS NULL THEN NULL 
                            WHEN ' + CAST(@update_system_type_id AS NVARCHAR) + ' = 61 THEN CONVERT(NVARCHAR(MAX), d.' + QUOTENAME(@update_column_name) + ', 121) 
                            ELSE CAST(d.' + QUOTENAME(@update_column_name) + ' AS NVARCHAR(MAX)) 
                        END,
                        @new_value = CASE 
                            WHEN i.' + QUOTENAME(@update_column_name) + ' IS NULL THEN NULL 
                            WHEN ' + CAST(@update_system_type_id AS NVARCHAR) + ' = 61 THEN CONVERT(NVARCHAR(MAX), i.' + QUOTENAME(@update_column_name) + ', 121) 
                            ELSE CAST(i.' + QUOTENAME(@update_column_name) + ' AS NVARCHAR(MAX)) 
                        END
                    FROM deleted d
                    JOIN inserted i ON d.MODEL_ID = i.MODEL_ID
                    WHERE d.MODEL_ID = @model_id';
                
                SET @update_params = N'@model_id INT, @old_value NVARCHAR(MAX) OUTPUT, @new_value NVARCHAR(MAX) OUTPUT';
                SET @update_old_value = NULL;
                SET @update_new_value = NULL;
                
                -- Thực thi câu lệnh SQL động
                EXEC sp_executesql @update_sql, @update_params, 
                    @model_id = @update_model_id, 
                    @old_value = @update_old_value OUTPUT, 
                    @new_value = @update_new_value OUTPUT;
                
                -- Chỉ thêm bản ghi audit nếu giá trị thực sự thay đổi
                IF (@update_old_value IS NULL AND @update_new_value IS NOT NULL) OR
                   (@update_old_value IS NOT NULL AND @update_new_value IS NULL) OR
                   (@update_old_value <> @update_new_value)
                BEGIN
                    INSERT INTO MODEL_REGISTRY.dbo.AUDIT_MODEL_REGISTRY (
                        MODEL_ID, 
                        ACTION_TYPE, 
                        FIELD_NAME, 
                        OLD_VALUE, 
                        NEW_VALUE
                    )
                    VALUES (
                        @update_model_id,
                        'UPDATE',
                        @update_column_name,
                        @update_old_value,
                        @update_new_value
                    );
                END
                
                FETCH NEXT FROM update_column_cursor INTO @update_column_id, @update_column_name, @update_system_type_id;
            END
            
            CLOSE update_column_cursor;
            DEALLOCATE update_column_cursor;
            
            FETCH NEXT FROM update_model_cursor INTO @update_model_id;
        END
        
        CLOSE update_model_cursor;
        DEALLOCATE update_model_cursor;
        
        -- Cập nhật trường UPDATED_BY và UPDATED_DATE trong bảng MODEL_REGISTRY
        UPDATE MODEL_REGISTRY.dbo.MODEL_REGISTRY
        SET 
            UPDATED_BY = SUSER_SNAME(),
            UPDATED_DATE = GETDATE()
        FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY m
        JOIN inserted i ON m.MODEL_ID = i.MODEL_ID;
    END
    
    -- Ghi nhật ký cho các thao tác DELETE
    ELSE
    BEGIN
        -- Lấy danh sách các cột cần kiểm tra
        DECLARE @DeleteColumns TABLE (column_id INT, column_name NVARCHAR(128), system_type_id INT);
        
        INSERT INTO @DeleteColumns
        SELECT 
            column_id, 
            name AS column_name,
            system_type_id
        FROM sys.columns 
        WHERE object_id = OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_REGISTRY')
        AND name NOT IN ('CREATED_DATE', 'CREATED_BY', 'UPDATED_DATE', 'UPDATED_BY');
        
        -- Xử lý từng cột cho mỗi MODEL_ID bị xóa
        DECLARE @delete_model_id INT;
        DECLARE delete_model_cursor CURSOR FOR SELECT MODEL_ID FROM deleted;
        
        OPEN delete_model_cursor;
        FETCH NEXT FROM delete_model_cursor INTO @delete_model_id;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Xử lý từng cột
            DECLARE @delete_column_name NVARCHAR(128);
            DECLARE @delete_column_id INT;
            DECLARE @delete_system_type_id INT;
            DECLARE @delete_sql NVARCHAR(MAX);
            DECLARE @delete_params NVARCHAR(MAX);
            DECLARE @delete_value NVARCHAR(MAX);
            
            DECLARE delete_column_cursor CURSOR FOR 
            SELECT column_id, column_name, system_type_id FROM @DeleteColumns;
            
            OPEN delete_column_cursor;
            FETCH NEXT FROM delete_column_cursor INTO @delete_column_id, @delete_column_name, @delete_system_type_id;
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- Xây dựng câu lệnh SQL động để lấy giá trị của cột
                SET @delete_sql = N'
                    SELECT @value = CASE 
                        WHEN ' + QUOTENAME(@delete_column_name) + ' IS NULL THEN NULL 
                        WHEN ' + CAST(@delete_system_type_id AS NVARCHAR) + ' = 61 THEN CONVERT(NVARCHAR(MAX), ' + QUOTENAME(@delete_column_name) + ', 121) 
                        ELSE CAST(' + QUOTENAME(@delete_column_name) + ' AS NVARCHAR(MAX)) 
                    END 
                    FROM deleted WHERE MODEL_ID = @model_id';
                
                SET @delete_params = N'@model_id INT, @value NVARCHAR(MAX) OUTPUT';
                SET @delete_value = NULL;
                
                -- Thực thi câu lệnh SQL động
                EXEC sp_executesql @delete_sql, @delete_params, 
                    @model_id = @delete_model_id, 
                    @value = @delete_value OUTPUT;
                
                -- Thêm bản ghi audit
                INSERT INTO MODEL_REGISTRY.dbo.AUDIT_MODEL_REGISTRY (
                    MODEL_ID, 
                    ACTION_TYPE, 
                    FIELD_NAME, 
                    OLD_VALUE, 
                    NEW_VALUE
                )
                VALUES (
                    @delete_model_id,
                    'DELETE',
                    @delete_column_name,
                    @delete_value,
                    NULL -- Không có giá trị mới cho DELETE
                );
                
                FETCH NEXT FROM delete_column_cursor INTO @delete_column_id, @delete_column_name, @delete_system_type_id;
            END
            
            CLOSE delete_column_cursor;
            DEALLOCATE delete_column_cursor;
            
            FETCH NEXT FROM delete_model_cursor INTO @delete_model_id;
        END
        
        CLOSE delete_model_cursor;
        DEALLOCATE delete_model_cursor;
    END
END;
GO

PRINT N'Trigger TRG_AUDIT_MODEL_REGISTRY đã được tạo thành công';
GO