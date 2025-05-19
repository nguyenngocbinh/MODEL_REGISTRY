/*
Tên file: 03_trg_validate_model_sources.sql
Mô tả: Tạo trigger TRG_VALIDATE_MODEL_SOURCES để tự động kiểm tra tính khả dụng của các bảng nguồn
      khi thêm mới hoặc cập nhật mối quan hệ giữa mô hình và bảng dữ liệu
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-16
Phiên bản: 1.0
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu trigger đã tồn tại thì xóa
IF OBJECT_ID('dbo.TRG_VALIDATE_MODEL_SOURCES', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TRG_VALIDATE_MODEL_SOURCES;
GO

-- Tạo trigger TRG_VALIDATE_MODEL_SOURCES
CREATE TRIGGER dbo.TRG_VALIDATE_MODEL_SOURCES
ON MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Biến tạm để lưu trữ thông tin lỗi (nếu có)
    DECLARE @ErrorMessage NVARCHAR(MAX) = '';
    DECLARE @ValidationErrors TABLE (ErrorDescription NVARCHAR(MAX));
    
    -- Kiểm tra tính khả dụng của các bảng nguồn vừa được thêm hoặc cập nhật
    WITH SourceInfo AS (
        SELECT 
            i.MODEL_ID,
            i.SOURCE_TABLE_ID,
            i.USAGE_PURPOSE,
            st.SOURCE_DATABASE,
            st.SOURCE_SCHEMA,
            st.SOURCE_TABLE_NAME,
            mr.MODEL_NAME,
            mr.MODEL_VERSION,
            tm.IS_CRITICAL
        FROM inserted i
        JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON i.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
        JOIN MODEL_REGISTRY.dbo.MODEL_REGISTRY mr ON i.MODEL_ID = mr.MODEL_ID
        LEFT JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING tm ON i.MODEL_ID = tm.MODEL_ID AND i.SOURCE_TABLE_ID = tm.SOURCE_TABLE_ID
    )
    INSERT INTO @ValidationErrors (ErrorDescription)
    SELECT 
        'Bảng nguồn [' + si.SOURCE_DATABASE + '.' + si.SOURCE_SCHEMA + '.' + si.SOURCE_TABLE_NAME + 
        '] được sử dụng cho mục đích [' + si.USAGE_PURPOSE + '] trong mô hình [' + 
        si.MODEL_NAME + ' v' + si.MODEL_VERSION + '] không tồn tại trong cơ sở dữ liệu.'
    FROM SourceInfo si
    WHERE NOT EXISTS (
        SELECT 1 
        FROM INFORMATION_SCHEMA.TABLES t
        WHERE t.TABLE_CATALOG = si.SOURCE_DATABASE
          AND t.TABLE_SCHEMA = si.SOURCE_SCHEMA
          AND t.TABLE_NAME = si.SOURCE_TABLE_NAME
    );
    
    -- Nếu có lỗi, tạo thông báo và hủy giao dịch nếu có bảng quan trọng không tồn tại
    IF EXISTS (SELECT 1 FROM @ValidationErrors)
    BEGIN
        -- Tổng hợp các thông báo lỗi
        SELECT @ErrorMessage = @ErrorMessage + ErrorDescription + CHAR(13) + CHAR(10)
        FROM @ValidationErrors;
        
        -- Ghi nhật ký lỗi vào bảng theo dõi
        INSERT INTO MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG (
            SOURCE_TABLE_ID,
            COLUMN_ID,
            PROCESS_DATE,
            ISSUE_TYPE,
            ISSUE_DESCRIPTION,
            ISSUE_CATEGORY,
            SEVERITY,
            IMPACT_DESCRIPTION,
            REMEDIATION_STATUS,
            CREATED_BY,
            CREATED_DATE
        )
        SELECT 
            i.SOURCE_TABLE_ID,
            NULL, -- Không liên quan đến cột cụ thể
            GETDATE(),
            'TABLE_MISSING',
            'Bảng nguồn [' + st.SOURCE_DATABASE + '.' + st.SOURCE_SCHEMA + '.' + st.SOURCE_TABLE_NAME + '] không tồn tại trong cơ sở dữ liệu.',
            'DATA_AVAILABILITY',
            CASE WHEN EXISTS (
                SELECT 1 FROM MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING tm 
                WHERE tm.MODEL_ID = i.MODEL_ID 
                  AND tm.SOURCE_TABLE_ID = i.SOURCE_TABLE_ID
                  AND tm.IS_CRITICAL = 1
            ) THEN 'CRITICAL' ELSE 'HIGH' END,
            'Mô hình [' + mr.MODEL_NAME + ' v' + mr.MODEL_VERSION + '] không thể thực thi nếu thiếu bảng này.',
            'OPEN',
            SUSER_SNAME(),
            GETDATE()
        FROM inserted i
        JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON i.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
        JOIN MODEL_REGISTRY.dbo.MODEL_REGISTRY mr ON i.MODEL_ID = mr.MODEL_ID
        WHERE NOT EXISTS (
            SELECT 1 
            FROM INFORMATION_SCHEMA.TABLES t
            WHERE t.TABLE_CATALOG = st.SOURCE_DATABASE
              AND t.TABLE_SCHEMA = st.SOURCE_SCHEMA
              AND t.TABLE_NAME = st.SOURCE_TABLE_NAME
        );
        
        -- Kiểm tra nếu có bảng quan trọng bị thiếu, hủy giao dịch
        IF EXISTS (
            SELECT 1 
            FROM inserted i
            JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON i.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
            WHERE EXISTS (
                SELECT 1 
                FROM MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING tm 
                WHERE tm.MODEL_ID = i.MODEL_ID 
                  AND tm.SOURCE_TABLE_ID = i.SOURCE_TABLE_ID
                  AND tm.IS_CRITICAL = 1
            )
            AND NOT EXISTS (
                SELECT 1 
                FROM INFORMATION_SCHEMA.TABLES t
                WHERE t.TABLE_CATALOG = st.SOURCE_DATABASE
                  AND t.TABLE_SCHEMA = st.SOURCE_SCHEMA
                  AND t.TABLE_NAME = st.SOURCE_TABLE_NAME
            )
        )
        BEGIN
            RAISERROR('Một hoặc nhiều bảng nguồn quan trọng không tồn tại. Không thể tiếp tục. Chi tiết lỗi: %s', 16, 1, @ErrorMessage);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        ELSE
        BEGIN
            -- Chỉ in cảnh báo nếu không có bảng quan trọng bị thiếu
            PRINT 'CẢNH BÁO: Một hoặc nhiều bảng không quan trọng không tồn tại. Giao dịch vẫn tiếp tục. Chi tiết:';
            PRINT @ErrorMessage;
        END
    END
    
    -- Các kiểm tra thêm về chất lượng dữ liệu có thể được thêm vào đây
    -- Ví dụ: kiểm tra xem bảng có dữ liệu mới nhất không, cột bắt buộc có tồn tại không, v.v.
    
    -- Tự động cập nhật trạng thái sẵn sàng của dữ liệu trong bảng MODEL_SOURCE_TABLES
    UPDATE MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES
    SET 
        DATA_QUALITY_SCORE = CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM INFORMATION_SCHEMA.TABLES t
                WHERE t.TABLE_CATALOG = st.SOURCE_DATABASE
                  AND t.TABLE_SCHEMA = st.SOURCE_SCHEMA
                  AND t.TABLE_NAME = st.SOURCE_TABLE_NAME
            ) THEN
                CASE
                    WHEN EXISTS (
                        SELECT 1
                        FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG r
                        WHERE r.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
                        AND r.REFRESH_STATUS = 'COMPLETED'
                        AND r.PROCESS_DATE > DATEADD(DAY, -7, GETDATE())
                    ) THEN 8 -- Dữ liệu mới trong vòng 7 ngày
                    WHEN EXISTS (
                        SELECT 1
                        FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG r
                        WHERE r.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
                        AND r.REFRESH_STATUS = 'COMPLETED'
                        AND r.PROCESS_DATE > DATEADD(DAY, -30, GETDATE())
                    ) THEN 6 -- Dữ liệu mới trong vòng 30 ngày
                    WHEN EXISTS (
                        SELECT 1
                        FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG r
                        WHERE r.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
                        AND r.REFRESH_STATUS = 'COMPLETED'
                    ) THEN 4 -- Có dữ liệu nhưng cũ
                    ELSE 2 -- Bảng tồn tại nhưng không có bản ghi làm mới
                END
            ELSE 0 -- Bảng không tồn tại
        END,
        UPDATED_BY = SUSER_SNAME(),
        UPDATED_DATE = GETDATE()
    FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st
    JOIN inserted i ON st.SOURCE_TABLE_ID = i.SOURCE_TABLE_ID;
END;
GO

-- Thêm comment cho trigger - Sửa lỗi ở đây
PRINT N'Thêm extended property cho trigger TRG_VALIDATE_MODEL_SOURCES';
BEGIN TRY
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Trigger tự động kiểm tra tính khả dụng của các bảng nguồn khi thêm mới hoặc cập nhật mối quan hệ giữa mô hình và bảng dữ liệu', 
        @level0type = N'SCHEMA', 
        @level0name = N'dbo', 
        @level1type = N'TRIGGER', 
        @level1name = N'TRG_VALIDATE_MODEL_SOURCES';
END TRY
BEGIN CATCH
    PRINT N'Lỗi khi thêm extended property: ' + ERROR_MESSAGE();
END CATCH
GO

PRINT N'Trigger TRG_VALIDATE_MODEL_SOURCES đã được tạo thành công';
GO