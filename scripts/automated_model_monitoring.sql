/*
Tên file: automated_model_monitoring.sql
Mô tả: Script tự động hóa việc giám sát hiệu suất mô hình và cảnh báo
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-06-19
Phiên bản: 1.0
*/

USE MODEL_REGISTRY
GO

-- =====================================
-- 1. Tạo bảng lưu cấu hình giám sát
-- =====================================

IF OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_MONITORING_CONFIG', 'U') IS NULL
BEGIN
    CREATE TABLE MODEL_REGISTRY.dbo.MODEL_MONITORING_CONFIG (
        CONFIG_ID INT IDENTITY(1,1) PRIMARY KEY,
        MODEL_ID INT NULL, -- NULL = áp dụng cho tất cả mô hình của loại này
        MODEL_TYPE_CODE NVARCHAR(20) NULL, -- NULL = áp dụng cho tất cả loại mô hình
        METRIC_NAME NVARCHAR(50) NOT NULL, -- 'GINI', 'PSI', 'KS', 'ACCURACY', etc.
        WARNING_THRESHOLD FLOAT NULL,
        CRITICAL_THRESHOLD FLOAT NULL,
        THRESHOLD_DIRECTION NVARCHAR(10) NOT NULL DEFAULT 'BELOW', -- 'BELOW', 'ABOVE'
        CHECK_FREQUENCY_DAYS INT DEFAULT 30, -- Tần suất kiểm tra (ngày)
        IS_ACTIVE BIT DEFAULT 1,
        EMAIL_RECIPIENTS NVARCHAR(MAX) NULL, -- JSON array of email addresses
        SLACK_WEBHOOK NVARCHAR(500) NULL,
        CREATED_BY NVARCHAR(50) DEFAULT SUSER_NAME(),
        CREATED_DATE DATETIME DEFAULT GETDATE(),
        UPDATED_BY NVARCHAR(50) NULL,
        UPDATED_DATE DATETIME NULL,
        
        CONSTRAINT FK_MONITORING_CONFIG_MODEL FOREIGN KEY (MODEL_ID) 
            REFERENCES MODEL_REGISTRY.dbo.MODEL_REGISTRY(MODEL_ID)
    );
    
    -- Tạo index
    CREATE INDEX IDX_MONITORING_CONFIG_MODEL ON MODEL_REGISTRY.dbo.MODEL_MONITORING_CONFIG(MODEL_ID);
    CREATE INDEX IDX_MONITORING_CONFIG_TYPE ON MODEL_REGISTRY.dbo.MODEL_MONITORING_CONFIG(MODEL_TYPE_CODE);
    CREATE INDEX IDX_MONITORING_CONFIG_ACTIVE ON MODEL_REGISTRY.dbo.MODEL_MONITORING_CONFIG(IS_ACTIVE);
    
    PRINT 'Đã tạo bảng MODEL_MONITORING_CONFIG';
END

-- =====================================
-- 2. Tạo bảng lưu lịch sử cảnh báo
-- =====================================

IF OBJECT_ID('MODEL_REGISTRY.dbo.MODEL_MONITORING_ALERTS', 'U') IS NULL
BEGIN
    CREATE TABLE MODEL_REGISTRY.dbo.MODEL_MONITORING_ALERTS (
        ALERT_ID INT IDENTITY(1,1) PRIMARY KEY,
        MODEL_ID INT NOT NULL,
        CONFIG_ID INT NOT NULL,
        ALERT_TYPE NVARCHAR(20) NOT NULL, -- 'WARNING', 'CRITICAL'
        METRIC_NAME NVARCHAR(50) NOT NULL,
        CURRENT_VALUE FLOAT NULL,
        THRESHOLD_VALUE FLOAT NULL,
        PREVIOUS_VALUE FLOAT NULL, -- Giá trị lần đánh giá trước
        VALIDATION_DATE DATE NOT NULL,
        ALERT_DATE DATETIME DEFAULT GETDATE(),
        ALERT_STATUS NVARCHAR(20) DEFAULT 'OPEN', -- 'OPEN', 'ACKNOWLEDGED', 'RESOLVED'
        ALERT_MESSAGE NVARCHAR(MAX) NULL,
        RESOLUTION_NOTES NVARCHAR(MAX) NULL,
        ACKNOWLEDGED_BY NVARCHAR(50) NULL,
        ACKNOWLEDGED_DATE DATETIME NULL,
        RESOLVED_BY NVARCHAR(50) NULL,
        RESOLVED_DATE DATETIME NULL,
        EMAIL_SENT BIT DEFAULT 0,
        SLACK_SENT BIT DEFAULT 0,
        
        CONSTRAINT FK_MONITORING_ALERTS_MODEL FOREIGN KEY (MODEL_ID) 
            REFERENCES MODEL_REGISTRY.dbo.MODEL_REGISTRY(MODEL_ID),
        CONSTRAINT FK_MONITORING_ALERTS_CONFIG FOREIGN KEY (CONFIG_ID) 
            REFERENCES MODEL_REGISTRY.dbo.MODEL_MONITORING_CONFIG(CONFIG_ID)
    );
    
    -- Tạo index
    CREATE INDEX IDX_MONITORING_ALERTS_MODEL ON MODEL_REGISTRY.dbo.MODEL_MONITORING_ALERTS(MODEL_ID);
    CREATE INDEX IDX_MONITORING_ALERTS_DATE ON MODEL_REGISTRY.dbo.MODEL_MONITORING_ALERTS(ALERT_DATE);
    CREATE INDEX IDX_MONITORING_ALERTS_STATUS ON MODEL_REGISTRY.dbo.MODEL_MONITORING_ALERTS(ALERT_STATUS);
    
    PRINT 'Đã tạo bảng MODEL_MONITORING_ALERTS';
END

-- =====================================
-- 3. Tạo stored procedure để kiểm tra hiệu suất
-- =====================================

IF OBJECT_ID('MODEL_REGISTRY.dbo.SP_CHECK_MODEL_PERFORMANCE', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SP_CHECK_MODEL_PERFORMANCE;
GO

CREATE PROCEDURE dbo.SP_CHECK_MODEL_PERFORMANCE
    @MODEL_ID INT = NULL, -- NULL để kiểm tra tất cả mô hình
    @SEND_NOTIFICATIONS BIT = 1,
    @DEBUG BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @NewAlerts TABLE (
        MODEL_ID INT,
        MODEL_NAME NVARCHAR(100),
        CONFIG_ID INT,
        ALERT_TYPE NVARCHAR(20),
        METRIC_NAME NVARCHAR(50),
        CURRENT_VALUE FLOAT,
        THRESHOLD_VALUE FLOAT,
        ALERT_MESSAGE NVARCHAR(MAX)
    );
    
    -- Lấy danh sách mô hình cần kiểm tra
    DECLARE @ModelsToCheck TABLE (MODEL_ID INT);
    
    IF @MODEL_ID IS NOT NULL
    BEGIN
        INSERT INTO @ModelsToCheck VALUES (@MODEL_ID);
    END
    ELSE
    BEGIN
        INSERT INTO @ModelsToCheck (MODEL_ID)
        SELECT mr.MODEL_ID
        FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
        WHERE mr.IS_ACTIVE = 1
        AND GETDATE() BETWEEN mr.EFF_DATE AND mr.EXP_DATE;
    END
    
    -- Kiểm tra từng mô hình
    DECLARE @CurrentModelID INT;
    DECLARE model_cursor CURSOR FOR
        SELECT MODEL_ID FROM @ModelsToCheck;
    
    OPEN model_cursor;
    FETCH NEXT FROM model_cursor INTO @CurrentModelID;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Lấy thông tin mô hình
        DECLARE @ModelName NVARCHAR(100), @ModelTypeCode NVARCHAR(20);
        SELECT @ModelName = mr.MODEL_NAME, @ModelTypeCode = mt.TYPE_CODE
        FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
        JOIN MODEL_REGISTRY.dbo.MODEL_TYPE mt ON mr.TYPE_ID = mt.TYPE_ID
        WHERE mr.MODEL_ID = @CurrentModelID;
        
        -- Lấy kết quả đánh giá mới nhất
        DECLARE @LatestValidation TABLE (
            VALIDATION_DATE DATE,
            GINI FLOAT,
            KS_STATISTIC FLOAT,
            PSI FLOAT,
            ACCURACY FLOAT,
            PRECISION_SCORE FLOAT,
            RECALL SCORE FLOAT,
            F1_SCORE FLOAT
        );
        
        INSERT INTO @LatestValidation
        SELECT TOP 1
            mvr.VALIDATION_DATE,
            mvr.GINI,
            mvr.KS_STATISTIC,
            mvr.PSI,
            mvr.ACCURACY,
            mvr.PRECISION_SCORE,
            mvr.RECALL,
            mvr.F1_SCORE
        FROM MODEL_REGISTRY.dbo.MODEL_VALIDATION_RESULTS mvr
        WHERE mvr.MODEL_ID = @CurrentModelID
        ORDER BY mvr.VALIDATION_DATE DESC;
        
        -- Kiểm tra các cấu hình giám sát áp dụng cho mô hình này
        DECLARE @ConfigCursor CURSOR;
        SET @ConfigCursor = CURSOR FOR
        SELECT 
            mc.CONFIG_ID,
            mc.METRIC_NAME,
            mc.WARNING_THRESHOLD,
            mc.CRITICAL_THRESHOLD,
            mc.THRESHOLD_DIRECTION
        FROM MODEL_REGISTRY.dbo.MODEL_MONITORING_CONFIG mc
        WHERE mc.IS_ACTIVE = 1
        AND (mc.MODEL_ID = @CurrentModelID OR 
             (mc.MODEL_ID IS NULL AND mc.MODEL_TYPE_CODE = @ModelTypeCode) OR
             (mc.MODEL_ID IS NULL AND mc.MODEL_TYPE_CODE IS NULL));
        
        DECLARE @ConfigID INT, @MetricName NVARCHAR(50), @WarningThreshold FLOAT, 
                @CriticalThreshold FLOAT, @ThresholdDirection NVARCHAR(10);
        
        OPEN @ConfigCursor;
        FETCH NEXT FROM @ConfigCursor INTO @ConfigID, @MetricName, @WarningThreshold, @CriticalThreshold, @ThresholdDirection;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @CurrentValue FLOAT = NULL;
            DECLARE @ValidationDate DATE;
            
            -- Lấy giá trị metric hiện tại
            SELECT 
                @CurrentValue = CASE @MetricName
                    WHEN 'GINI' THEN lv.GINI
                    WHEN 'KS' THEN lv.KS_STATISTIC
                    WHEN 'PSI' THEN lv.PSI
                    WHEN 'ACCURACY' THEN lv.ACCURACY
                    WHEN 'PRECISION' THEN lv.PRECISION_SCORE
                    WHEN 'RECALL' THEN lv.RECALL
                    WHEN 'F1' THEN lv.F1_SCORE
                END,
                @ValidationDate = lv.VALIDATION_DATE
            FROM @LatestValidation lv;
            
            -- Kiểm tra ngưỡng nếu có giá trị
            IF @CurrentValue IS NOT NULL
            BEGIN
                DECLARE @AlertType NVARCHAR(20) = NULL;
                DECLARE @ThresholdValue FLOAT = NULL;
                
                -- Kiểm tra ngưỡng critical trước
                IF @CriticalThreshold IS NOT NULL
                BEGIN
                    IF (@ThresholdDirection = 'BELOW' AND @CurrentValue < @CriticalThreshold) OR
                       (@ThresholdDirection = 'ABOVE' AND @CurrentValue > @CriticalThreshold)
                    BEGIN
                        SET @AlertType = 'CRITICAL';
                        SET @ThresholdValue = @CriticalThreshold;
                    END
                END
                
                -- Nếu chưa có critical, kiểm tra warning
                IF @AlertType IS NULL AND @WarningThreshold IS NOT NULL
                BEGIN
                    IF (@ThresholdDirection = 'BELOW' AND @CurrentValue < @WarningThreshold) OR
                       (@ThresholdDirection = 'ABOVE' AND @CurrentValue > @WarningThreshold)
                    BEGIN
                        SET @AlertType = 'WARNING';
                        SET @ThresholdValue = @WarningThreshold;
                    END
                END
                
                -- Tạo cảnh báo nếu cần
                IF @AlertType IS NOT NULL
                BEGIN
                    -- Kiểm tra xem đã có cảnh báo tương tự chưa (trong 7 ngày qua)
                    IF NOT EXISTS (
                        SELECT 1 FROM MODEL_REGISTRY.dbo.MODEL_MONITORING_ALERTS
                        WHERE MODEL_ID = @CurrentModelID 
                        AND CONFIG_ID = @ConfigID
                        AND ALERT_TYPE = @AlertType
                        AND ALERT_DATE >= DATEADD(DAY, -7, GETDATE())
                        AND ALERT_STATUS IN ('OPEN', 'ACKNOWLEDGED')
                    )
                    BEGIN
                        DECLARE @AlertMessage NVARCHAR(MAX) = 
                            'Model ' + @ModelName + ' (' + @MetricName + '): ' +
                            'Current value ' + CAST(@CurrentValue AS NVARCHAR(20)) + ' ' +
                            'is ' + @ThresholdDirection + ' threshold ' + CAST(@ThresholdValue AS NVARCHAR(20)) +
                            ' (Validation Date: ' + CAST(@ValidationDate AS NVARCHAR(20)) + ')';
                        
                        -- Thêm vào bảng tạm
                        INSERT INTO @NewAlerts
                        VALUES (@CurrentModelID, @ModelName, @ConfigID, @AlertType, @MetricName, 
                                @CurrentValue, @ThresholdValue, @AlertMessage);
                        
                        -- Lưu vào bảng chính
                        INSERT INTO MODEL_REGISTRY.dbo.MODEL_MONITORING_ALERTS (
                            MODEL_ID, CONFIG_ID, ALERT_TYPE, METRIC_NAME, CURRENT_VALUE,
                            THRESHOLD_VALUE, VALIDATION_DATE, ALERT_MESSAGE
                        )
                        VALUES (@CurrentModelID, @ConfigID, @AlertType, @MetricName, @CurrentValue,
                                @ThresholdValue, @ValidationDate, @AlertMessage);
                        
                        IF @DEBUG = 1
                            PRINT 'Created ' + @AlertType + ' alert for Model ' + @ModelName + ': ' + @AlertMessage;
                    END
                END
            END
            
            FETCH NEXT FROM @ConfigCursor INTO @ConfigID, @MetricName, @WarningThreshold, @CriticalThreshold, @ThresholdDirection;
        END
        
        CLOSE @ConfigCursor;
        DEALLOCATE @ConfigCursor;
        
        -- Dọn dẹp bảng tạm
        DELETE FROM @LatestValidation;
        
        FETCH NEXT FROM model_cursor INTO @CurrentModelID;
    END
    
    CLOSE model_cursor;
    DEALLOCATE model_cursor;
    
    -- Hiển thị kết quả
    SELECT * FROM @NewAlerts ORDER BY ALERT_TYPE DESC, MODEL_NAME;
    
    -- Gửi thông báo nếu được yêu cầu
    IF @SEND_NOTIFICATIONS = 1 AND EXISTS (SELECT 1 FROM @NewAlerts)
    BEGIN
        EXEC dbo.SP_SEND_MONITORING_NOTIFICATIONS;
    END
    
    -- Thống kê tổng quan
    SELECT 
        COUNT(*) AS TOTAL_NEW_ALERTS,
        SUM(CASE WHEN ALERT_TYPE = 'CRITICAL' THEN 1 ELSE 0 END) AS CRITICAL_ALERTS,
        SUM(CASE WHEN ALERT_TYPE = 'WARNING' THEN 1 ELSE 0 END) AS WARNING_ALERTS
    FROM @NewAlerts;
END;
GO

-- =====================================
-- 4. Tạo stored procedure gửi thông báo
-- =====================================

IF OBJECT_ID('MODEL_REGISTRY.dbo.SP_SEND_MONITORING_NOTIFICATIONS', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SP_SEND_MONITORING_NOTIFICATIONS;
GO

CREATE PROCEDURE dbo.SP_SEND_MONITORING_NOTIFICATIONS
    @ALERT_ID INT = NULL -- NULL để gửi tất cả alerts chưa gửi
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Lấy danh sách alerts cần gửi
    DECLARE @AlertsToSend TABLE (
        ALERT_ID INT,
        MODEL_NAME NVARCHAR(100),
        ALERT_TYPE NVARCHAR(20),
        ALERT_MESSAGE NVARCHAR(MAX),
        EMAIL_RECIPIENTS NVARCHAR(MAX),
        SLACK_WEBHOOK NVARCHAR(500)
    );
    
    INSERT INTO @AlertsToSend
    SELECT 
        ma.ALERT_ID,
        mr.MODEL_NAME,
        ma.ALERT_TYPE,
        ma.ALERT_MESSAGE,
        mc.EMAIL_RECIPIENTS,
        mc.SLACK_WEBHOOK
    FROM MODEL_REGISTRY.dbo.MODEL_MONITORING_ALERTS ma
    JOIN MODEL_REGISTRY.dbo.MODEL_REGISTRY mr ON ma.MODEL_ID = mr.MODEL_ID
    JOIN MODEL_REGISTRY.dbo.MODEL_MONITORING_CONFIG mc ON ma.CONFIG_ID = mc.CONFIG_ID
    WHERE ma.ALERT_STATUS = 'OPEN'
    AND ma.EMAIL_SENT = 0
    AND (@ALERT_ID IS NULL OR ma.ALERT_ID = @ALERT_ID);
    
    -- Gửi từng thông báo
    DECLARE @CurrentAlertID INT, @CurrentMessage NVARCHAR(MAX), @EmailRecipients NVARCHAR(MAX);
    DECLARE alert_cursor CURSOR FOR
        SELECT ALERT_ID, ALERT_MESSAGE, EMAIL_RECIPIENTS 
        FROM @AlertsToSend 
        WHERE EMAIL_RECIPIENTS IS NOT NULL;
    
    OPEN alert_cursor;
    FETCH NEXT FROM alert_cursor INTO @CurrentAlertID, @CurrentMessage, @EmailRecipients;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Gửi email (giả lập - cần tích hợp với hệ thống email thực tế)
        DECLARE @EmailSubject NVARCHAR(255) = 'Model Registry Alert - ' + 
            (SELECT ALERT_TYPE FROM @AlertsToSend WHERE ALERT_ID = @CurrentAlertID);
        
        DECLARE @EmailBody NVARCHAR(MAX) = 
            'Dear Team,' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +
            @CurrentMessage + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +
            'Please investigate and take appropriate action.' + CHAR(13) + CHAR(10) +
            'Time: ' + CONVERT(NVARCHAR, GETDATE(), 120) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +
            'Best regards,' + CHAR(13) + CHAR(10) +
            'Model Registry System';
        
        -- Ở đây bạn có thể tích hợp với Database Mail hoặc hệ thống email khác
        -- EXEC msdb.dbo.sp_send_dbmail @recipients = @EmailRecipients, @subject = @EmailSubject, @body = @EmailBody;
        
        PRINT 'Email sent for Alert ID: ' + CAST(@CurrentAlertID AS NVARCHAR) + ' to ' + @EmailRecipients;
        
        -- Đánh dấu đã gửi email
        UPDATE MODEL_REGISTRY.dbo.MODEL_MONITORING_ALERTS
        SET EMAIL_SENT = 1
        WHERE ALERT_ID = @CurrentAlertID;
        
        FETCH NEXT FROM alert_cursor INTO @CurrentAlertID, @CurrentMessage, @EmailRecipients;
    END
    
    CLOSE alert_cursor;
    DEALLOCATE alert_cursor;
    
    PRINT 'Notification sending completed';
END;
GO

-- =====================================
-- 5. Thêm dữ liệu cấu hình mẫu
-- =====================================

-- Cấu hình mặc định cho PD models
INSERT INTO MODEL_REGISTRY.dbo.MODEL_MONITORING_CONFIG (
    MODEL_TYPE_CODE, METRIC_NAME, WARNING_THRESHOLD, CRITICAL_THRESHOLD, 
    THRESHOLD_DIRECTION, EMAIL_RECIPIENTS
)
VALUES 
('PD', 'GINI', 0.35, 0.25, 'BELOW', '["model_team@company.com", "risk_team@company.com"]'),
('PD', 'PSI', 0.25, 0.35, 'ABOVE', '["model_team@company.com", "risk_team@company.com"]'),
('BSCORE', 'GINI', 0.30, 0.20, 'BELOW', '["model_team@company.com"]'),
('BSCORE', 'PSI', 0.25, 0.35, 'ABOVE', '["model_team@company.com"]'),
('ASCORE', 'GINI', 0.25, 0.15, 'BELOW', '["model_team@company.com"]'),
('ASCORE', 'PSI', 0.25, 0.35, 'ABOVE', '["model_team@company.com"]');

PRINT 'Đã thêm cấu hình giám sát mẫu';

-- =====================================
-- 6. Tạo job tự động (SQL Agent Job)
-- =====================================

PRINT 'Để tạo SQL Agent Job tự động, chạy script sau:';
PRINT '
USE msdb;
GO

EXEC dbo.sp_add_job
    @job_name = N''Model Registry Performance Check'';

EXEC dbo.sp_add_jobstep
    @job_name = N''Model Registry Performance Check'',
    @step_name = N''Check Model Performance'',
    @command = N''EXEC MODEL_REGISTRY.dbo.SP_CHECK_MODEL_PERFORMANCE @SEND_NOTIFICATIONS = 1'',
    @database_name = N''MODEL_REGISTRY'';

EXEC dbo.sp_add_schedule
    @schedule_name = N''Daily Performance Check'',
    @freq_type = 4, -- Daily
    @freq_interval = 1,
    @active_start_time = 080000; -- 8:00 AM

EXEC dbo.sp_attach_schedule
    @job_name = N''Model Registry Performance Check'',
    @schedule_name = N''Daily Performance Check'';

EXEC dbo.sp_add_jobserver
    @job_name = N''Model Registry Performance Check'';
';

PRINT '';
PRINT '===========================================';
PRINT 'AUTOMATED MODEL MONITORING SETUP COMPLETE';
PRINT '===========================================';
PRINT '';
PRINT 'Các tính năng đã được tạo:';
PRINT '1. Bảng cấu hình giám sát (MODEL_MONITORING_CONFIG)';
PRINT '2. Bảng lưu cảnh báo (MODEL_MONITORING_ALERTS)';
PRINT '3. Stored procedure kiểm tra hiệu suất (SP_CHECK_MODEL_PERFORMANCE)';
PRINT '4. Stored procedure gửi thông báo (SP_SEND_MONITORING_NOTIFICATIONS)';
PRINT '5. Dữ liệu cấu hình mẫu';
PRINT '';
PRINT 'Để sử dụng:';
PRINT '1. Chạy: EXEC dbo.SP_CHECK_MODEL_PERFORMANCE';
PRINT '2. Tạo SQL Agent Job để chạy tự động hàng ngày';
PRINT '3. Cấu hình Database Mail để gửi email thông báo';
PRINT '4. Tùy chỉnh ngưỡng cảnh báo trong bảng MODEL_MONITORING_CONFIG';

GO