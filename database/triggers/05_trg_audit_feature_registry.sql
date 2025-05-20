/*
Tên file: 05_trg_audit_feature_registry.sql
Mô tả: Tạo trigger TRG_AUDIT_FEATURE_REGISTRY để ghi nhật ký thay đổi trong bảng FEATURE_REGISTRY
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-16
Phiên bản: 1.2 - Sửa lỗi truy cập cột động và kiểm tra đầy đủ các bảng liên quan
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra và tạo bảng audit nếu chưa tồn tại
IF OBJECT_ID('MODEL_REGISTRY.dbo.TRG_AUDIT_FEATURE_REGISTRY', 'U') IS NULL
BEGIN
    CREATE TABLE MODEL_REGISTRY.dbo.TRG_AUDIT_FEATURE_REGISTRY (
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

-- Kiểm tra xem bảng FEATURE_MODEL_MAPPING có tồn tại không
IF OBJECT_ID('MODEL_REGISTRY.dbo.FEATURE_MODEL_MAPPING', 'U') IS NULL
BEGIN
    -- Tạo bảng FEATURE_MODEL_MAPPING nếu chưa tồn tại
    CREATE TABLE MODEL_REGISTRY.dbo.FEATURE_MODEL_MAPPING (
        MAPPING_ID INT IDENTITY(1,1) PRIMARY KEY,
        MODEL_ID INT NOT NULL,
        FEATURE_ID INT NOT NULL,
        USAGE_TYPE NVARCHAR(50) DEFAULT 'INPUT',
        IS_MANDATORY BIT DEFAULT 1,
        IS_ACTIVE BIT DEFAULT 1,
        CREATED_BY NVARCHAR(50) DEFAULT SUSER_NAME(),
        CREATED_DATE DATETIME DEFAULT GETDATE(),
        UPDATED_BY NVARCHAR(50) NULL,
        UPDATED_DATE DATETIME NULL,
        FOREIGN KEY (MODEL_ID) REFERENCES MODEL_REGISTRY.dbo.MODEL_REGISTRY(MODEL_ID),
        FOREIGN KEY (FEATURE_ID) REFERENCES MODEL_REGISTRY.dbo.FEATURE_REGISTRY(FEATURE_ID),
        CONSTRAINT UC_MODEL_FEATURE UNIQUE (MODEL_ID, FEATURE_ID)
    );
    
    PRINT N'Đã tạo bảng FEATURE_MODEL_MAPPING để quản lý mối quan hệ giữa mô hình và đặc trưng';
END
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
    
    -- Kiểm tra xem bảng FEATURE_MODEL_MAPPING có tồn tại không và có dữ liệu không
    IF OBJECT_ID('MODEL_REGISTRY.dbo.FEATURE_MODEL_MAPPING', 'U') IS NOT NULL
    BEGIN
        -- Xác định các mô hình bị ảnh hưởng bởi việc thay đổi đặc trưng
        INSERT INTO @AffectedModels (FEATURE_ID, MODEL_LIST)
        SELECT 
            f.FEATURE_ID,
            STRING_AGG(CONVERT(NVARCHAR(10), fmm.MODEL_ID), ', ') AS MODEL_LIST
        FROM (
            SELECT FEATURE_ID FROM inserted
            UNION
            SELECT FEATURE_ID FROM deleted
            WHERE FEATURE_ID IS NOT NULL
        ) f
        LEFT JOIN MODEL_REGISTRY.dbo.FEATURE_MODEL_MAPPING fmm ON f.FEATURE_ID = fmm.FEATURE_ID
        WHERE fmm.IS_ACTIVE = 1 OR fmm.IS_ACTIVE IS NULL
        GROUP BY f.FEATURE_ID;
    END
    ELSE
    BEGIN
        -- Nếu bảng FEATURE_MODEL_MAPPING không tồn tại, vẫn tạo bản ghi cho đặc trưng
        INSERT INTO @AffectedModels (FEATURE_ID, MODEL_LIST)
        SELECT 
            f.FEATURE_ID,
            NULL AS MODEL_LIST
        FROM (
            SELECT FEATURE_ID FROM inserted
            UNION
            SELECT FEATURE_ID FROM deleted
            WHERE FEATURE_ID IS NOT NULL
        ) f;
    END
    
    -- Ghi nhật ký cho các thao tác INSERT
    IF @action_type = 'INSERT'
    BEGIN
-- Lấy tất cả các cột cần theo dõi
        DECLARE @InsertColumns TABLE (
            column_id INT, 
            column_name NVARCHAR(128),
            system_type_id INT
        );
        
        INSERT INTO @InsertColumns
        SELECT 
            column_id, 
            name AS column_name,
            system_type_id
        FROM sys.columns 
        WHERE object_id = OBJECT_ID('MODEL_REGISTRY.dbo.FEATURE_REGISTRY')
        AND name NOT IN ('CREATED_DATE', 'CREATED_BY', 'UPDATED_DATE', 'UPDATED_BY');
        
        -- Xử lý từng cột cho mỗi đặc trưng được thêm mới
        DECLARE @insert_feature_id INT;
        DECLARE @insert_column_name NVARCHAR(128);
        DECLARE @insert_column_id INT;
        DECLARE @insert_system_type_id INT;
        DECLARE @insert_model_list NVARCHAR(MAX);
        DECLARE @insert_sql NVARCHAR(MAX);
        DECLARE @insert_params NVARCHAR(MAX);
        DECLARE @insert_value NVARCHAR(MAX);
        
        -- Cursor cho các đặc trưng mới
        DECLARE insert_feature_cursor CURSOR FOR
        SELECT FEATURE_ID FROM inserted;
        
        OPEN insert_feature_cursor;
        FETCH NEXT FROM insert_feature_cursor INTO @insert_feature_id;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Lấy danh sách mô hình bị ảnh hưởng bởi đặc trưng này
            SELECT @insert_model_list = MODEL_LIST
            FROM @AffectedModels
            WHERE FEATURE_ID = @insert_feature_id;
            
            -- Cursor cho các cột cần theo dõi
            DECLARE insert_column_cursor CURSOR FOR
            SELECT column_id, column_name, system_type_id FROM @InsertColumns;
            
            OPEN insert_column_cursor;
            FETCH NEXT FROM insert_column_cursor INTO @insert_column_id, @insert_column_name, @insert_system_type_id;
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- Lấy giá trị của cột
                SET @insert_sql = N'SELECT @value = CASE 
                                     WHEN ' + QUOTENAME(@insert_column_name) + ' IS NULL THEN NULL 
                                     WHEN ' + CAST(@insert_system_type_id AS NVARCHAR) + ' = 61 THEN CONVERT(NVARCHAR(MAX), ' + QUOTENAME(@insert_column_name) + ', 121) 
                                     ELSE CAST(' + QUOTENAME(@insert_column_name) + ' AS NVARCHAR(MAX)) 
                                   END 
                                   FROM inserted WHERE FEATURE_ID = @feature_id';
                                   
                SET @insert_params = N'@feature_id INT, @value NVARCHAR(MAX) OUTPUT';
                SET @insert_value = NULL;
                
                EXEC sp_executesql @insert_sql, @insert_params, 
                     @feature_id = @insert_feature_id, 
                     @value = @insert_value OUTPUT;
                
                -- Ghi lại trong bảng audit
                INSERT INTO MODEL_REGISTRY.dbo.TRG_AUDIT_FEATURE_REGISTRY (
                    FEATURE_ID, 
                    ACTION_TYPE, 
                    FIELD_NAME, 
                    OLD_VALUE, 
                    NEW_VALUE,
                    AFFECTED_MODELS
                )
                VALUES (
                    @insert_feature_id,
                    'INSERT',
                    @insert_column_name,
                    NULL, -- Không có giá trị cũ cho INSERT
                    @insert_value,
                    @insert_model_list
                );
                
                FETCH NEXT FROM insert_column_cursor INTO @insert_column_id, @insert_column_name, @insert_system_type_id;
            END
            
            CLOSE insert_column_cursor;
            DEALLOCATE insert_column_cursor;
            
            FETCH NEXT FROM insert_feature_cursor INTO @insert_feature_id;
        END
        
        CLOSE insert_feature_cursor;
        DEALLOCATE insert_feature_cursor;
    END
    
    -- Ghi nhật ký cho các thao tác UPDATE
    ELSE IF @action_type = 'UPDATE'
    BEGIN
        -- Lấy tất cả các cột cần theo dõi
        DECLARE @UpdateColumns TABLE (
            column_id INT, 
            column_name NVARCHAR(128),
            system_type_id INT
        );
        
        INSERT INTO @UpdateColumns
        SELECT 
            column_id, 
            name AS column_name,
            system_type_id
        FROM sys.columns 
        WHERE object_id = OBJECT_ID('MODEL_REGISTRY.dbo.FEATURE_REGISTRY')
        AND name NOT IN ('CREATED_DATE', 'CREATED_BY', 'UPDATED_DATE', 'UPDATED_BY');
        
        -- Xử lý từng cột cho mỗi đặc trưng được cập nhật
        DECLARE @update_feature_id INT;
        DECLARE @update_column_name NVARCHAR(128);
        DECLARE @update_column_id INT;
        DECLARE @update_system_type_id INT;
        DECLARE @update_model_list NVARCHAR(MAX);
        DECLARE @update_sql_old NVARCHAR(MAX);
        DECLARE @update_sql_new NVARCHAR(MAX);
        DECLARE @update_params NVARCHAR(MAX);
        DECLARE @update_old_value NVARCHAR(MAX);
        DECLARE @update_new_value NVARCHAR(MAX);
        
        -- Cursor cho các đặc trưng được cập nhật
        DECLARE update_feature_cursor CURSOR FOR
        SELECT i.FEATURE_ID 
        FROM inserted i
        JOIN deleted d ON i.FEATURE_ID = d.FEATURE_ID;
        
        OPEN update_feature_cursor;
        FETCH NEXT FROM update_feature_cursor INTO @update_feature_id;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Lấy danh sách mô hình bị ảnh hưởng bởi đặc trưng này
            SELECT @update_model_list = MODEL_LIST
            FROM @AffectedModels
            WHERE FEATURE_ID = @update_feature_id;
            
            -- Cursor cho các cột cần theo dõi
            DECLARE update_column_cursor CURSOR FOR
            SELECT column_id, column_name, system_type_id FROM @UpdateColumns;
            
            OPEN update_column_cursor;
            FETCH NEXT FROM update_column_cursor INTO @update_column_id, @update_column_name, @update_system_type_id;
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- Lấy giá trị cũ
                SET @update_sql_old = N'SELECT @value = CASE 
                                     WHEN ' + QUOTENAME(@update_column_name) + ' IS NULL THEN NULL 
                                     WHEN ' + CAST(@update_system_type_id AS NVARCHAR) + ' = 61 THEN CONVERT(NVARCHAR(MAX), ' + QUOTENAME(@update_column_name) + ', 121) 
                                     ELSE CAST(' + QUOTENAME(@update_column_name) + ' AS NVARCHAR(MAX)) 
                                   END 
                                   FROM deleted WHERE FEATURE_ID = @feature_id';
                
                SET @update_params = N'@feature_id INT, @value NVARCHAR(MAX) OUTPUT';
                SET @update_old_value = NULL;
                
                EXEC sp_executesql @update_sql_old, @update_params, 
                     @feature_id = @update_feature_id, 
                     @value = @update_old_value OUTPUT;
                
                -- Lấy giá trị mới
                SET @update_sql_new = N'SELECT @value = CASE 
                                     WHEN ' + QUOTENAME(@update_column_name) + ' IS NULL THEN NULL 
                                     WHEN ' + CAST(@update_system_type_id AS NVARCHAR) + ' = 61 THEN CONVERT(NVARCHAR(MAX), ' + QUOTENAME(@update_column_name) + ', 121) 
                                     ELSE CAST(' + QUOTENAME(@update_column_name) + ' AS NVARCHAR(MAX)) 
                                   END 
                                   FROM inserted WHERE FEATURE_ID = @feature_id';
                
                SET @update_new_value = NULL;
                
                EXEC sp_executesql @update_sql_new, @update_params, 
                     @feature_id = @update_feature_id, 
                     @value = @update_new_value OUTPUT;
                
                -- Chỉ ghi nhật ký nếu giá trị thực sự thay đổi
                IF (@update_old_value IS NULL AND @update_new_value IS NOT NULL) OR
                   (@update_old_value IS NOT NULL AND @update_new_value IS NULL) OR
                   (@update_old_value <> @update_new_value)
                BEGIN
                    -- Ghi lại trong bảng audit
                    INSERT INTO MODEL_REGISTRY.dbo.TRG_AUDIT_FEATURE_REGISTRY (
                        FEATURE_ID, 
                        ACTION_TYPE, 
                        FIELD_NAME, 
                        OLD_VALUE, 
                        NEW_VALUE,
                        AFFECTED_MODELS
                    )
                    VALUES (
                        @update_feature_id,
                        'UPDATE',
                        @update_column_name,
                        @update_old_value,
                        @update_new_value,
                        @update_model_list
                    );
                END
                
                FETCH NEXT FROM update_column_cursor INTO @update_column_id, @update_column_name, @update_system_type_id;
            END
            
            CLOSE update_column_cursor;
            DEALLOCATE update_column_cursor;
            
            FETCH NEXT FROM update_feature_cursor INTO @update_feature_id;
        END
        
        CLOSE update_feature_cursor;
        DEALLOCATE update_feature_cursor;
        
        -- Cập nhật trường UPDATED_BY và UPDATED_DATE
        UPDATE MODEL_REGISTRY.dbo.FEATURE_REGISTRY
        SET 
            UPDATED_BY = SUSER_SNAME(),
            UPDATED_DATE = GETDATE()
        FROM MODEL_REGISTRY.dbo.FEATURE_REGISTRY fr
        JOIN inserted i ON fr.FEATURE_ID = i.FEATURE_ID;
    END
    
    -- Ghi nhật ký cho các thao tác DELETE
    ELSE
    BEGIN
        -- Lấy tất cả các cột cần theo dõi
        DECLARE @DeleteColumns TABLE (
            column_id INT, 
            column_name NVARCHAR(128),
            system_type_id INT
        );
        
        INSERT INTO @DeleteColumns
        SELECT 
            column_id, 
            name AS column_name,
            system_type_id
        FROM sys.columns 
        WHERE object_id = OBJECT_ID('MODEL_REGISTRY.dbo.FEATURE_REGISTRY')
        AND name NOT IN ('CREATED_DATE', 'CREATED_BY', 'UPDATED_DATE', 'UPDATED_BY');
        
        -- Xử lý từng cột cho mỗi đặc trưng bị xóa
        DECLARE @delete_feature_id INT;
        DECLARE @delete_column_name NVARCHAR(128);
        DECLARE @delete_column_id INT;
        DECLARE @delete_system_type_id INT;
        DECLARE @delete_model_list NVARCHAR(MAX);
        DECLARE @delete_sql NVARCHAR(MAX);
        DECLARE @delete_params NVARCHAR(MAX);
        DECLARE @delete_value NVARCHAR(MAX);
        
        -- Cursor cho các đặc trưng bị xóa
        DECLARE delete_feature_cursor CURSOR FOR
        SELECT FEATURE_ID FROM deleted;
        
        OPEN delete_feature_cursor;
        FETCH NEXT FROM delete_feature_cursor INTO @delete_feature_id;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Lấy danh sách mô hình bị ảnh hưởng bởi đặc trưng này
            SELECT @delete_model_list = MODEL_LIST
            FROM @AffectedModels
            WHERE FEATURE_ID = @delete_feature_id;
            
            -- Cursor cho các cột cần theo dõi
            DECLARE delete_column_cursor CURSOR FOR
            SELECT column_id, column_name, system_type_id FROM @DeleteColumns;
            
            OPEN delete_column_cursor;
            FETCH NEXT FROM delete_column_cursor INTO @delete_column_id, @delete_column_name, @delete_system_type_id;
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- Lấy giá trị của cột
                SET @delete_sql = N'SELECT @value = CASE 
                                     WHEN ' + QUOTENAME(@delete_column_name) + ' IS NULL THEN NULL 
                                     WHEN ' + CAST(@delete_system_type_id AS NVARCHAR) + ' = 61 THEN CONVERT(NVARCHAR(MAX), ' + QUOTENAME(@delete_column_name) + ', 121) 
                                     ELSE CAST(' + QUOTENAME(@delete_column_name) + ' AS NVARCHAR(MAX)) 
                                   END 
                                   FROM deleted WHERE FEATURE_ID = @feature_id';
                                   
                SET @delete_params = N'@feature_id INT, @value NVARCHAR(MAX) OUTPUT';
                SET @delete_value = NULL;
                
                EXEC sp_executesql @delete_sql, @delete_params, 
                     @feature_id = @delete_feature_id, 
                     @value = @delete_value OUTPUT;
                
                -- Ghi lại trong bảng audit
                INSERT INTO MODEL_REGISTRY.dbo.TRG_AUDIT_FEATURE_REGISTRY (
                    FEATURE_ID, 
                    ACTION_TYPE, 
                    FIELD_NAME, 
                    OLD_VALUE, 
                    NEW_VALUE,
                    AFFECTED_MODELS
                )
                VALUES (
                    @delete_feature_id,
                    'DELETE',
                    @delete_column_name,
                    @delete_value,
                    NULL, -- Không có giá trị mới cho DELETE
                    @delete_model_list
                );
                
                FETCH NEXT FROM delete_column_cursor INTO @delete_column_id, @delete_column_name, @delete_system_type_id;
            END
            
            CLOSE delete_column_cursor;
            DEALLOCATE delete_column_cursor;
            
            FETCH NEXT FROM delete_feature_cursor INTO @delete_feature_id;
        END
        
        CLOSE delete_feature_cursor;
        DEALLOCATE delete_feature_cursor;
    END
    
    -- Thông báo về các mô hình bị ảnh hưởng 
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
            -- Kiểm tra xem bảng MODEL_REGISTRY có tồn tại không
            IF OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_REGISTRY', 'U') IS NOT NULL
            BEGIN
                -- Lấy ID các mô hình từ chuỗi MODEL_LIST
                DECLARE @models_to_update TABLE (MODEL_ID INT);
                
                INSERT INTO @models_to_update
                SELECT DISTINCT TRY_CAST(value AS INT) AS MODEL_ID
                FROM @AffectedModels
                CROSS APPLY STRING_SPLIT(MODEL_LIST, ',')
                WHERE MODEL_LIST IS NOT NULL AND TRIM(value) <> '';
                
                -- Cập nhật trạng thái cho các mô hình bị ảnh hưởng
                UPDATE MODEL_REGISTRY.dbo.MODEL_REGISTRY
                SET 
                    MODEL_STATUS = 'NEEDS_REVIEW',
                    UPDATED_BY = SUSER_SNAME(),
                    UPDATED_DATE = GETDATE()
                WHERE MODEL_ID IN (SELECT MODEL_ID FROM @models_to_update)
                AND IS_ACTIVE = 1
                AND MODEL_STATUS = 'ACTIVE';
                
                IF @@ROWCOUNT > 0
                    PRINT N'CẢNH BÁO: Các mô hình bị ảnh hưởng đã được đánh dấu là "NEEDS_REVIEW"';
            END
            ELSE
            BEGIN
                PRINT N'CẢNH BÁO: Bảng MODEL_REGISTRY không tồn tại. Không thể cập nhật trạng thái mô hình.';
            END
        END
    END
END;
GO

PRINT N'Trigger TRG_AUDIT_FEATURE_REGISTRY đã được tạo thành công';
GO