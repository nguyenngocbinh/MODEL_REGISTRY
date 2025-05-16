/*
Tên file: 04_trg_update_model_status.sql
Mô tả: Tạo trigger TRG_UPDATE_MODEL_STATUS để tự động cập nhật trạng thái của mô hình
      dựa trên các thay đổi trong dữ liệu nguồn, tham số hoặc kết quả đánh giá
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-16
Phiên bản: 1.0
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu trigger đã tồn tại thì xóa
IF OBJECT_ID('dbo.TRG_UPDATE_MODEL_STATUS', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TRG_UPDATE_MODEL_STATUS;
GO

-- Tạo trigger trên bảng MODEL_VALIDATION_RESULTS
CREATE TRIGGER dbo.TRG_UPDATE_MODEL_STATUS
ON MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Biến để lưu trữ ID của các mô hình cần cập nhật
    DECLARE @ModelsToUpdate TABLE (MODEL_ID INT);
    
    -- Thêm ID mô hình từ bản ghi mới nhất vào bảng tạm
    INSERT INTO @ModelsToUpdate (MODEL_ID)
    SELECT DISTINCT i.MODEL_ID
    FROM inserted i;
    
    -- Cập nhật thông tin về hiệu suất mô hình trong bảng MODEL_REGISTRY
    WITH LatestValidation AS (
        -- Lấy kết quả đánh giá gần nhất cho mỗi mô hình
        SELECT 
            mvr.MODEL_ID,
            mvr.VALIDATION_DATE,
            mvr.VALIDATION_TYPE,
            mvr.GINI,
            mvr.KS_STATISTIC,
            mvr.PSI,
            mvr.VALIDATION_THRESHOLD_BREACHED,
            ROW_NUMBER() OVER (PARTITION BY mvr.MODEL_ID ORDER BY mvr.VALIDATION_DATE DESC) AS RowNum
        FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS mvr
        JOIN @ModelsToUpdate mtu ON mvr.MODEL_ID = mtu.MODEL_ID
    )
    UPDATE MODEL_REGISTRY.dbo.MODEL_REGISTRY
    SET 
        -- Lưu thông tin về hiệu suất đo lường gần nhất
        PERFORMANCE_METRICS = (
            SELECT 
                GINI AS [gini],
                KS_STATISTIC AS [ks_statistic],
                PSI AS [psi],
                VALIDATION_DATE AS [last_validation_date],
                VALIDATION_TYPE AS [validation_type],
                VALIDATION_THRESHOLD_BREACHED AS [threshold_breached]
            FROM LatestValidation lv
            WHERE lv.MODEL_ID = mr.MODEL_ID AND lv.RowNum = 1
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ),
        -- Cập nhật trạng thái mô hình dựa trên kết quả đánh giá
        MODEL_STATUS = CASE 
            -- Nếu mô hình không hoạt động
            WHEN mr.IS_ACTIVE = 0 THEN 'INACTIVE'
            -- Nếu mô hình chưa có hiệu lực
            WHEN GETDATE() < mr.EFF_DATE THEN 'PENDING'
            -- Nếu mô hình đã hết hiệu lực
            WHEN GETDATE() > mr.EXP_DATE THEN 'EXPIRED'
            -- Nếu đánh giá gần nhất vượt ngưỡng, đánh dấu là cần xem xét
            WHEN EXISTS (
                SELECT 1 
                FROM LatestValidation lv 
                WHERE lv.MODEL_ID = mr.MODEL_ID 
                  AND lv.RowNum = 1 
                  AND lv.VALIDATION_THRESHOLD_BREACHED = 1
            ) THEN 'NEEDS_REVIEW'
            -- Mặc định là hoạt động nếu đáp ứng tất cả điều kiện
            ELSE 'ACTIVE'
        END,
        -- Cập nhật các trường khác nếu cần
        UPDATED_BY = SUSER_SNAME(),
        UPDATED_DATE = GETDATE()
    FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
    WHERE mr.MODEL_ID IN (SELECT MODEL_ID FROM @ModelsToUpdate);
    
    -- Ghi nhật ký cho các thay đổi trạng thái mô hình nếu cần
    INSERT INTO MODEL_REGISTRY.dbo.AUDIT_MODEL_REGISTRY (
        MODEL_ID,
        ACTION_TYPE,
        FIELD_NAME,
        OLD_VALUE,
        NEW_VALUE,
        CHANGE_DATE,
        CHANGED_BY,
        HOST_NAME
    )
    SELECT 
        mr.MODEL_ID,
        'UPDATE',
        'MODEL_STATUS',
        'ACTIVE', -- Giả định giá trị cũ là ACTIVE, trong thực tế cần xác định giá trị cũ thật
        mr.MODEL_STATUS,
        GETDATE(),
        SUSER_SNAME(),
        HOST_NAME()
    FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
    JOIN @ModelsToUpdate mtu ON mr.MODEL_ID = mtu.MODEL_ID
    WHERE mr.MODEL_STATUS = 'NEEDS_REVIEW'; -- Chỉ ghi log cho các mô hình chuyển sang NEEDS_REVIEW
    
    -- Gửi thông báo cho người dùng và quản trị viên nếu có thay đổi trạng thái
    IF EXISTS (
        SELECT 1 
        FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
        JOIN @ModelsToUpdate mtu ON mr.MODEL_ID = mtu.MODEL_ID
        WHERE mr.MODEL_STATUS = 'NEEDS_REVIEW'
    )
    BEGIN
        PRINT N'CẢNH BÁO: Một hoặc nhiều mô hình đã được đánh dấu là "NEEDS_REVIEW" do kết quả đánh giá mới vượt ngưỡng.';
        
        -- Ở đây có thể thêm mã để gửi email, thông báo hoặc tạo báo cáo nếu cần
    END
END;
GO

-- Tạo trigger tương tự cho bảng MODEL_SOURCE_REFRESH_LOG
IF OBJECT_ID('dbo.TRG_UPDATE_MODEL_STATUS_FROM_REFRESH', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TRG_UPDATE_MODEL_STATUS_FROM_REFRESH;
GO

CREATE TRIGGER dbo.TRG_UPDATE_MODEL_STATUS_FROM_REFRESH
ON MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Chỉ xử lý các bản ghi hoàn thành hoặc thất bại
    IF NOT EXISTS (SELECT 1 FROM inserted WHERE REFRESH_STATUS IN ('COMPLETED', 'FAILED'))
        RETURN;
    
    -- Biến để lưu trữ ID của các mô hình bị ảnh hưởng
    DECLARE @AffectedModels TABLE (MODEL_ID INT);
    
    -- Xác định các mô hình bị ảnh hưởng bởi việc cập nhật dữ liệu
    INSERT INTO @AffectedModels (MODEL_ID)
    SELECT DISTINCT tm.MODEL_ID
    FROM inserted i
    JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_USAGE tu ON i.SOURCE_TABLE_ID = tu.SOURCE_TABLE_ID
    JOIN MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING tm ON tu.MODEL_ID = tm.MODEL_ID AND tu.SOURCE_TABLE_ID = tm.SOURCE_TABLE_ID
    WHERE i.REFRESH_STATUS IN ('COMPLETED', 'FAILED')
      AND tm.IS_CRITICAL = 1; -- Chỉ quan tâm đến các bảng quan trọng
    
    -- Cập nhật trạng thái mô hình dựa trên việc làm mới dữ liệu
    WITH CriticalSourceStatus AS (
        -- Kiểm tra trạng thái các nguồn dữ liệu quan trọng cho mỗi mô hình
        SELECT 
            tm.MODEL_ID,
            MIN(CASE 
                -- Nếu có bất kỳ bảng quan trọng nào không có dữ liệu mới nhất
                WHEN NOT EXISTS (
                    SELECT 1 
                    FROM MODEL_REGISTRY.dbo.MODEL_SOURCE_REFRESH_LOG r
                    WHERE r.SOURCE_TABLE_ID = tm.SOURCE_TABLE_ID
                      AND r.REFRESH_STATUS = 'COMPLETED'
                      AND r.PROCESS_DATE > DATEADD(DAY, -7, GETDATE())
                ) THEN 0
                ELSE 1
            END) AS AllSourcesReady
        FROM MODEL_REGISTRY.dbo.MODEL_TABLE_MAPPING tm
        JOIN @AffectedModels am ON tm.MODEL_ID = am.MODEL_ID
        WHERE tm.IS_CRITICAL = 1
        GROUP BY tm.MODEL_ID
    )
    UPDATE MODEL_REGISTRY.dbo.MODEL_REGISTRY
    SET 
        -- Cập nhật trạng thái mô hình dựa trên tình trạng dữ liệu nguồn
        MODEL_STATUS = CASE 
            -- Nếu mô hình không hoạt động
            WHEN mr.IS_ACTIVE = 0 THEN 'INACTIVE'
            -- Nếu mô hình chưa có hiệu lực
            WHEN GETDATE() < mr.EFF_DATE THEN 'PENDING'
            -- Nếu mô hình đã hết hiệu lực
            WHEN GETDATE() > mr.EXP_DATE THEN 'EXPIRED'
            -- Nếu không phải tất cả nguồn dữ liệu quan trọng đều sẵn sàng
            WHEN css.AllSourcesReady = 0 THEN 'DATA_UNAVAILABLE'
            -- Giữ nguyên trạng thái NEEDS_REVIEW nếu đã có
            WHEN mr.MODEL_STATUS = 'NEEDS_REVIEW' THEN 'NEEDS_REVIEW'
            -- Mặc định là hoạt động
            ELSE 'ACTIVE'
        END,
        DATA_REFRESH_DATE = GETDATE(),
        UPDATED_BY = SUSER_SNAME(),
        UPDATED_DATE = GETDATE()
    FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
    JOIN CriticalSourceStatus css ON mr.MODEL_ID = css.MODEL_ID;
    
    -- Ghi nhật ký cho các thay đổi trạng thái mô hình
    INSERT INTO MODEL_REGISTRY.dbo.AUDIT_MODEL_REGISTRY (
        MODEL_ID,
        ACTION_TYPE,
        FIELD_NAME,
        OLD_VALUE,
        NEW_VALUE,
        CHANGE_DATE,
        CHANGED_BY,
        HOST_NAME
    )
    SELECT 
        mr.MODEL_ID,
        'UPDATE',
        'MODEL_STATUS',
        'ACTIVE', -- Giả định giá trị cũ, trong thực tế cần xác định giá trị cũ thật
        mr.MODEL_STATUS,
        GETDATE(),
        SUSER_SNAME(),
        HOST_NAME()
    FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
    JOIN @AffectedModels am ON mr.MODEL_ID = am.MODEL_ID
    WHERE mr.MODEL_STATUS = 'DATA_UNAVAILABLE'; -- Chỉ ghi log cho các mô hình có vấn đề về dữ liệu
    
    -- Gửi thông báo nếu có vấn đề về dữ liệu
    IF EXISTS (
        SELECT 1 
        FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
        JOIN @AffectedModels am ON mr.MODEL_ID = am.MODEL_ID
        WHERE mr.MODEL_STATUS = 'DATA_UNAVAILABLE'
    )
    BEGIN
        -- Xây dựng danh sách các mô hình bị ảnh hưởng
        DECLARE @AffectedModelsList NVARCHAR(MAX) = '';
        
        SELECT @AffectedModelsList = @AffectedModelsList + 
               CASE WHEN @AffectedModelsList = '' THEN '' ELSE ', ' END +
               MODEL_NAME + ' v' + MODEL_VERSION
        FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY
        WHERE MODEL_ID IN (SELECT MODEL_ID FROM @AffectedModels)
          AND MODEL_STATUS = 'DATA_UNAVAILABLE';
        
        PRINT N'CẢNH BÁO: Các mô hình sau đây đã chuyển sang trạng thái DATA_UNAVAILABLE do vấn đề với dữ liệu nguồn: ' + @AffectedModelsList;
        
        -- Ở đây có thể thêm mã để gửi email, thông báo hoặc tạo báo cáo nếu cần
    END
END;
GO

-- Thêm comment cho các trigger
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Trigger tự động cập nhật trạng thái mô hình dựa trên kết quả đánh giá', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TRIGGER',  @level1name = N'TRG_UPDATE_MODEL_STATUS';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Trigger tự động cập nhật trạng thái mô hình dựa trên việc làm mới dữ liệu nguồn', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TRIGGER',  @level1name = N'TRG_UPDATE_MODEL_STATUS_FROM_REFRESH';
GO

-- Kiểm tra và thêm cột mới vào bảng MODEL_REGISTRY nếu cần
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_REGISTRY') AND name = 'MODEL_STATUS')
BEGIN
    ALTER TABLE MODEL_REGISTRY.dbo.MODEL_REGISTRY
    ADD MODEL_STATUS NVARCHAR(50) DEFAULT 'ACTIVE';
    
    PRINT N'Đã thêm cột MODEL_STATUS vào bảng MODEL_REGISTRY';
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_REGISTRY') AND name = 'PERFORMANCE_METRICS')
BEGIN
    ALTER TABLE MODEL_REGISTRY.dbo.MODEL_REGISTRY
    ADD PERFORMANCE_METRICS NVARCHAR(MAX) NULL;
    
    PRINT N'Đã thêm cột PERFORMANCE_METRICS vào bảng MODEL_REGISTRY';
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_REGISTRY') AND name = 'DATA_REFRESH_DATE')
BEGIN
    ALTER TABLE MODEL_REGISTRY.dbo.MODEL_REGISTRY
    ADD DATA_REFRESH_DATE DATETIME NULL;
    
    PRINT N'Đã thêm cột DATA_REFRESH_DATE vào bảng MODEL_REGISTRY';
END

PRINT N'Các trigger cập nhật trạng thái mô hình đã được tạo thành công';
GO