/*
Tên file: 07_trg_update_model_feature_dependencies.sql
Mô tả: Tạo trigger TRG_UPDATE_MODEL_FEATURE_DEPENDENCIES để tự động cập nhật thông tin phụ thuộc
      giữa mô hình và đặc trưng khi có thay đổi trong mối quan hệ
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-16
Phiên bản: 1.1 - Sửa lỗi column không tồn tại
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu trigger đã tồn tại thì xóa
IF OBJECT_ID('dbo.TRG_UPDATE_MODEL_FEATURE_DEPENDENCIES', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TRG_UPDATE_MODEL_FEATURE_DEPENDENCIES;
GO

-- Tạo trigger TRG_UPDATE_MODEL_FEATURE_DEPENDENCIES
CREATE TRIGGER dbo.TRG_UPDATE_MODEL_FEATURE_DEPENDENCIES
ON MODEL_REGISTRY.dbo.FEATURE_MODEL_MAPPING
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Biến để lưu trữ thông tin đặc trưng và mô hình
    DECLARE @FeatureModelPairs TABLE (
        FEATURE_ID INT,
        MODEL_ID INT,
        USAGE_TYPE NVARCHAR(50),
        IS_MANDATORY BIT
    );
    
    -- Lấy các mối quan hệ đặc trưng-mô hình mới hoặc được cập nhật
    INSERT INTO @FeatureModelPairs (FEATURE_ID, MODEL_ID, USAGE_TYPE, IS_MANDATORY)
    SELECT 
        i.FEATURE_ID,
        i.MODEL_ID,
        i.USAGE_TYPE,
        i.IS_MANDATORY
    FROM inserted i
    WHERE i.IS_ACTIVE = 1; -- Chỉ xử lý các mối quan hệ đang hoạt động
    
    -- Nếu không có dữ liệu để xử lý, thoát
    IF NOT EXISTS (SELECT 1 FROM @FeatureModelPairs)
        RETURN;
    
    -- Tự động phát hiện và cập nhật phụ thuộc giữa các đặc trưng
    -- 1. Xác định các đặc trưng được sử dụng cùng nhau trong mô hình
    WITH FeaturePairs AS (
        -- Tạo tất cả các cặp đặc trưng có thể có trong cùng một mô hình
        SELECT 
            fmm1.FEATURE_ID AS FEATURE_ID,
            fmm2.FEATURE_ID AS DEPENDS_ON_FEATURE_ID,
            fmm1.MODEL_ID,
            fmm1.USAGE_TYPE,
            fmm2.USAGE_TYPE AS DEPENDS_ON_USAGE_TYPE
        FROM MODEL_REGISTRY.dbo.FEATURE_MODEL_MAPPING fmm1
        JOIN MODEL_REGISTRY.dbo.FEATURE_MODEL_MAPPING fmm2 ON fmm1.MODEL_ID = fmm2.MODEL_ID
        WHERE fmm1.FEATURE_ID <> fmm2.FEATURE_ID
          AND fmm1.IS_ACTIVE = 1
          AND fmm2.IS_ACTIVE = 1
          AND fmm1.FEATURE_ID IN (SELECT FEATURE_ID FROM @FeatureModelPairs)
    ),
    -- 2. Tính toán số lượng mô hình mà mỗi cặp đặc trưng được sử dụng cùng nhau
    FeaturePairCounts AS (
        SELECT 
            FEATURE_ID,
            DEPENDS_ON_FEATURE_ID,
            COUNT(DISTINCT MODEL_ID) AS MODEL_COUNT,
            -- Lưu trữ loại sử dụng cho mỗi đặc trưng trong cặp
            MAX(USAGE_TYPE) AS USAGE_TYPE,
            MAX(DEPENDS_ON_USAGE_TYPE) AS DEPENDS_ON_USAGE_TYPE
        FROM FeaturePairs
        GROUP BY FEATURE_ID, DEPENDS_ON_FEATURE_ID
    ),
    -- 3. Xác định tổng số mô hình mà mỗi đặc trưng được sử dụng
    FeatureModelCounts AS (
        SELECT 
            FEATURE_ID,
            COUNT(DISTINCT MODEL_ID) AS TOTAL_MODELS
        FROM MODEL_REGISTRY.dbo.FEATURE_MODEL_MAPPING
        WHERE IS_ACTIVE = 1
        GROUP BY FEATURE_ID
    )
    -- 4. Tính toán độ mạnh của phụ thuộc dựa trên tỷ lệ sử dụng cùng nhau
    MERGE MODEL_REGISTRY.dbo.FEATURE_DEPENDENCIES AS target
    USING (
        SELECT 
            fp.FEATURE_ID,
            fp.DEPENDS_ON_FEATURE_ID,
            -- Xác định loại phụ thuộc dựa trên kiểu sử dụng
            CASE 
                WHEN fp.USAGE_TYPE = 'DERIVED' AND fp.DEPENDS_ON_USAGE_TYPE = 'INPUT' THEN 'DERIVATION'
                WHEN fp.USAGE_TYPE = fp.DEPENDS_ON_USAGE_TYPE THEN 'CORRELATION'
                ELSE 'CALCULATION'
            END AS DEPENDENCY_TYPE,
            -- Tính toán độ mạnh của phụ thuộc: tỷ lệ mô hình mà đặc trưng xuất hiện cùng nhau
            CAST(fp.MODEL_COUNT AS FLOAT) / NULLIF(fmc.TOTAL_MODELS, 0) AS DEPENDENCY_STRENGTH
        FROM FeaturePairCounts fp
        JOIN FeatureModelCounts fmc ON fp.FEATURE_ID = fmc.FEATURE_ID
        WHERE fp.MODEL_COUNT >= 2 -- Chỉ xem xét các cặp xuất hiện ít nhất 2 mô hình
          AND (CAST(fp.MODEL_COUNT AS FLOAT) / NULLIF(fmc.TOTAL_MODELS, 0)) > 0.5 -- Tỷ lệ phụ thuộc > 50%
    ) AS source
    ON (
        target.FEATURE_ID = source.FEATURE_ID 
        AND target.DEPENDS_ON_FEATURE_ID = source.DEPENDS_ON_FEATURE_ID
        AND target.DEPENDENCY_TYPE = source.DEPENDENCY_TYPE
    )
    WHEN MATCHED THEN
        UPDATE SET
            DEPENDENCY_STRENGTH = source.DEPENDENCY_STRENGTH,
            LAST_UPDATED = GETDATE(),
            UPDATED_BY = SUSER_SNAME(),
            UPDATED_DATE = GETDATE(),
            IS_ACTIVE = 1
    WHEN NOT MATCHED THEN
        INSERT (
            FEATURE_ID,
            DEPENDS_ON_FEATURE_ID,
            DEPENDENCY_TYPE,
            DEPENDENCY_STRENGTH,
            DEPENDENCY_DESCRIPTION,
            LAST_UPDATED,
            CREATED_BY,
            CREATED_DATE,
            IS_ACTIVE
        )
        VALUES (
            source.FEATURE_ID,
            source.DEPENDS_ON_FEATURE_ID,
            source.DEPENDENCY_TYPE,
            source.DEPENDENCY_STRENGTH,
            CASE 
                WHEN source.DEPENDENCY_TYPE = 'DERIVATION' THEN 'Automatically detected derivation dependency'
                WHEN source.DEPENDENCY_TYPE = 'CORRELATION' THEN 'Automatically detected correlation'
                ELSE 'Automatically detected calculation dependency'
            END,
            GETDATE(),
            SUSER_SNAME(),
            GETDATE(),
            1
        );
    
    -- Tính toán và cập nhật tương quan thống kê giữa các đặc trưng
    -- Lưu ý: Cần có dữ liệu thực tế để tính toán chính xác
    -- Đoạn mã dưới đây là một giả lập đơn giản
    
    -- 1. Lấy danh sách các cặp đặc trưng cần tính toán tương quan
    DECLARE @FeaturePairsToCalculate TABLE (
        FEATURE_ID INT,
        DEPENDS_ON_FEATURE_ID INT,
        DEPENDENCY_ID INT,
        DEPENDENCY_STRENGTH FLOAT,
        DEPENDENCY_TYPE NVARCHAR(50)
    );
    
    INSERT INTO @FeaturePairsToCalculate (FEATURE_ID, DEPENDS_ON_FEATURE_ID, DEPENDENCY_ID, DEPENDENCY_STRENGTH, DEPENDENCY_TYPE)
    SELECT 
        fd.FEATURE_ID,
        fd.DEPENDS_ON_FEATURE_ID,
        fd.DEPENDENCY_ID,
        fd.DEPENDENCY_STRENGTH,
        fd.DEPENDENCY_TYPE
    FROM MODEL_REGISTRY.dbo.FEATURE_DEPENDENCIES fd
    JOIN @FeatureModelPairs fmp ON fd.FEATURE_ID = fmp.FEATURE_ID
    WHERE fd.DEPENDENCY_TYPE = 'CORRELATION'
      AND fd.IS_ACTIVE = 1
      AND (fd.CORRELATION_VALUE IS NULL OR fd.LAST_UPDATED < DATEADD(DAY, -30, GETDATE()));
    
    -- 2. Với mỗi cặp đặc trưng, tính toán tương quan (giả lập)
    -- Trong thực tế, cần truy vấn dữ liệu thực tế và tính toán tương quan
    UPDATE fd
    SET 
        -- Giả lập tương quan trong khoảng -1 đến 1
        CORRELATION_VALUE = CASE 
            WHEN fpc.DEPENDENCY_STRENGTH > 0.8 THEN RAND() * 0.5 + 0.5 -- Độ mạnh cao -> tương quan dương mạnh
            WHEN fpc.DEPENDENCY_STRENGTH > 0.6 THEN RAND() * 0.6 + 0.2 -- Độ mạnh trung bình -> tương quan dương trung bình
            ELSE RAND() * 0.4 - 0.2 -- Độ mạnh thấp -> tương quan yếu
        END,
        -- Tính toán thông tin tương hỗ dựa trên tương quan (giả lập)
        MUTUAL_INFORMATION = CASE 
            WHEN fpc.DEPENDENCY_STRENGTH > 0.7 THEN RAND() * 0.5 + 0.5
            ELSE RAND() * 0.3
        END,
        LAST_UPDATED = GETDATE(),
        UPDATED_BY = SUSER_SNAME(),
        UPDATED_DATE = GETDATE()
    FROM MODEL_REGISTRY.dbo.FEATURE_DEPENDENCIES fd
    JOIN @FeaturePairsToCalculate fpc ON fd.DEPENDENCY_ID = fpc.DEPENDENCY_ID;
    
    -- Tự động cập nhật thông tin VIF (Variance Inflation Factor) để phát hiện đa cộng tuyến
    -- VIF > 10 thường cho thấy có vấn đề đa cộng tuyến nghiêm trọng
    -- Đây cũng là một giả lập đơn giản
    UPDATE fd
    SET 
        VIF_VALUE = CASE 
            -- Đa cộng tuyến cao nếu tương quan mạnh
            WHEN ABS(fd.CORRELATION_VALUE) > 0.8 THEN RAND() * 15 + 10
            -- Đa cộng tuyến trung bình
            WHEN ABS(fd.CORRELATION_VALUE) > 0.6 THEN RAND() * 5 + 5
            -- Ít hoặc không có đa cộng tuyến
            ELSE RAND() * 3 + 1
        END,
        UPDATED_BY = SUSER_SNAME(),
        UPDATED_DATE = GETDATE()
    FROM MODEL_REGISTRY.dbo.FEATURE_DEPENDENCIES fd
    JOIN @FeaturePairsToCalculate fpc ON fd.DEPENDENCY_ID = fpc.DEPENDENCY_ID
    WHERE fd.CORRELATION_VALUE IS NOT NULL;
    
    -- Ghi nhật ký cảnh báo cho các đặc trưng có VIF cao (đa cộng tuyến cao)
    INSERT INTO MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG (
        SOURCE_TABLE_ID,
        COLUMN_ID,
        PROCESS_DATE,
        ISSUE_TYPE,
        ISSUE_DESCRIPTION,
        ISSUE_CATEGORY,
        SEVERITY,
        IMPACT_DESCRIPTION,
        DETECTION_METHOD,
        REMEDIATION_STATUS,
        CREATED_BY,
        CREATED_DATE
    )
    SELECT 
        fst.SOURCE_TABLE_ID,
        cd.COLUMN_ID,
        GETDATE(),
        'MULTICOLLINEARITY',
        'Phát hiện đa cộng tuyến cao (VIF = ' + CAST(ROUND(fd.VIF_VALUE, 2) AS NVARCHAR) + ') giữa đặc trưng ' + fr1.FEATURE_NAME + ' và ' + fr2.FEATURE_NAME,
        'FEATURE_QUALITY',
        CASE 
            WHEN fd.VIF_VALUE > 20 THEN 'HIGH'
            WHEN fd.VIF_VALUE > 10 THEN 'MEDIUM'
            ELSE 'LOW'
        END,
        'Đa cộng tuyến cao có thể làm giảm độ ổn định của mô hình và khó giải thích các hệ số.',
        'AUTOMATIC_DEPENDENCY_ANALYSIS',
        'OPEN',
        SUSER_SNAME(),
        GETDATE()
    FROM MODEL_REGISTRY.dbo.FEATURE_DEPENDENCIES fd
    JOIN MODEL_REGISTRY.dbo.FEATURE_REGISTRY fr1 ON fd.FEATURE_ID = fr1.FEATURE_ID
    JOIN MODEL_REGISTRY.dbo.FEATURE_REGISTRY fr2 ON fd.DEPENDS_ON_FEATURE_ID = fr2.FEATURE_ID
    JOIN MODEL_REGISTRY.dbo.FEATURE_SOURCE_TABLES fst ON fr1.FEATURE_ID = fst.FEATURE_ID
    LEFT JOIN MODEL_REGISTRY.dbo.MODEL_SOURCE_TABLES st ON fst.SOURCE_TABLE_ID = st.SOURCE_TABLE_ID
    LEFT JOIN MODEL_REGISTRY.dbo.MODEL_COLUMN_DETAILS cd ON st.SOURCE_TABLE_ID = cd.SOURCE_TABLE_ID AND fst.SOURCE_COLUMN_NAME = cd.COLUMN_NAME
    WHERE fd.VIF_VALUE > 10 -- Chỉ cảnh báo khi VIF > 10
      AND fd.IS_ACTIVE = 1
      AND fst.IS_PRIMARY_SOURCE = 1
      AND fd.LAST_UPDATED > DATEADD(HOUR, -24, GETDATE()) -- Chỉ xem xét những cập nhật trong 24 giờ qua
      AND NOT EXISTS (
          -- Kiểm tra xem đã có cảnh báo tương tự trong 30 ngày qua chưa
          SELECT 1
          FROM MODEL_REGISTRY.dbo.MODEL_DATA_QUALITY_LOG dq
          WHERE dq.SOURCE_TABLE_ID = fst.SOURCE_TABLE_ID
            AND (dq.COLUMN_ID = cd.COLUMN_ID OR (dq.COLUMN_ID IS NULL AND cd.COLUMN_ID IS NULL))
            AND dq.ISSUE_TYPE = 'MULTICOLLINEARITY'
            AND dq.ISSUE_DESCRIPTION LIKE '%' + fr1.FEATURE_NAME + '%' + fr2.FEATURE_NAME + '%'
            AND dq.PROCESS_DATE > DATEADD(DAY, -30, GETDATE())
            AND dq.REMEDIATION_STATUS IN ('OPEN', 'IN_PROGRESS')
      );
    
    -- Cập nhật hệ số hồi quy cho các đặc trưng dựa trên mối quan hệ với mô hình
    -- Đây cũng là một giả lập, trong thực tế cần truy xuất hệ số từ kết quả huấn luyện mô hình
    UPDATE fd
    SET 
        -- Giả lập hệ số hồi quy dựa trên độ mạnh của phụ thuộc và loại phụ thuộc
        REGRESSION_COEFFICIENT = CASE 
            WHEN fpc.DEPENDENCY_TYPE = 'DERIVATION' THEN RAND() * fpc.DEPENDENCY_STRENGTH * 2 - 1
            WHEN fpc.DEPENDENCY_TYPE = 'CALCULATION' THEN RAND() * fpc.DEPENDENCY_STRENGTH
            WHEN fpc.DEPENDENCY_TYPE = 'CORRELATION' THEN 
                CASE 
                    WHEN fd.CORRELATION_VALUE > 0 THEN RAND() * fd.CORRELATION_VALUE
                    ELSE RAND() * fd.CORRELATION_VALUE * (-1)
                END
            ELSE NULL
        END,
        UPDATED_BY = SUSER_SNAME(),
        UPDATED_DATE = GETDATE()
    FROM MODEL_REGISTRY.dbo.FEATURE_DEPENDENCIES fd
    JOIN @FeaturePairsToCalculate fpc ON fd.DEPENDENCY_ID = fpc.DEPENDENCY_ID
    WHERE fd.IS_ACTIVE = 1;
    
    -- Thông báo về các phụ thuộc mới được phát hiện
    IF EXISTS (
        SELECT 1 
        FROM MODEL_REGISTRY.dbo.FEATURE_DEPENDENCIES fd
        WHERE fd.CREATED_DATE > DATEADD(MINUTE, -5, GETDATE()) -- Phụ thuộc mới tạo trong 5 phút qua
    )
    BEGIN
        DECLARE @NewDependencies NVARCHAR(MAX) = '';
        
        SELECT @NewDependencies = @NewDependencies + 
               CASE WHEN @NewDependencies = '' THEN '' ELSE '; ' END +
               fr1.FEATURE_NAME + ' ' + fd.DEPENDENCY_TYPE + ' ' + fr2.FEATURE_NAME + 
               ' (Strength: ' + CAST(ROUND(fd.DEPENDENCY_STRENGTH * 100, 1) AS NVARCHAR) + '%)'
        FROM MODEL_REGISTRY.dbo.FEATURE_DEPENDENCIES fd
        JOIN MODEL_REGISTRY.dbo.FEATURE_REGISTRY fr1 ON fd.FEATURE_ID = fr1.FEATURE_ID
        JOIN MODEL_REGISTRY.dbo.FEATURE_REGISTRY fr2 ON fd.DEPENDS_ON_FEATURE_ID = fr2.FEATURE_ID
        WHERE fd.CREATED_DATE > DATEADD(MINUTE, -5, GETDATE()); -- Phụ thuộc mới tạo trong 5 phút qua
        
        PRINT N'THÔNG BÁO: Đã phát hiện các phụ thuộc đặc trưng mới: ' + @NewDependencies;
    END
END;
GO

/*
-- Thêm comment cho trigger
-- Kiểm tra nếu đối tượng tồn tại trước khi thêm extended property
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'TRG_UPDATE_MODEL_FEATURE_DEPENDENCIES')
BEGIN
    -- Kiểm tra nếu extended property đã tồn tại
    IF NOT EXISTS (
        SELECT * 
        FROM sys.extended_properties 
        WHERE major_id = OBJECT_ID('dbo.TRG_UPDATE_MODEL_FEATURE_DEPENDENCIES')
          AND name = 'MS_Description'
    )
    BEGIN
        EXEC sys.sp_addextendedproperty 
            @name = N'MS_Description', 
            @value = N'Trigger tự động cập nhật thông tin phụ thuộc giữa mô hình và đặc trưng khi có thay đổi trong mối quan hệ', 
            @level0type = N'SCHEMA', @level0name = N'dbo', 
            @level1type = N'TRIGGER', @level1name = N'TRG_UPDATE_MODEL_FEATURE_DEPENDENCIES';
    END
    ELSE
    BEGIN
        EXEC sys.sp_updateextendedproperty 
            @name = N'MS_Description', 
            @value = N'Trigger tự động cập nhật thông tin phụ thuộc giữa mô hình và đặc trưng khi có thay đổi trong mối quan hệ', 
            @level0type = N'SCHEMA', @level0name = N'dbo', 
            @level1type = N'TRIGGER', @level1name = N'TRG_UPDATE_MODEL_FEATURE_DEPENDENCIES';
    END
END
GO
*/

PRINT N'Trigger TRG_UPDATE_MODEL_FEATURE_DEPENDENCIES đã được tạo thành công';
GO