/*
Tên file: 04_fn_get_model_version_info.sql
Mô tả: Tạo function FN_GET_MODEL_VERSION_INFO để lấy thông tin về các phiên bản khác nhau của mô hình (đã sửa lỗi ORDER BY)
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-15
Phiên bản: 1.1 - Fix: Removed invalid ORDER BY clause in table-valued function
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu function đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.FN_GET_MODEL_VERSION_INFO', 'TF') IS NOT NULL
    DROP FUNCTION dbo.FN_GET_MODEL_VERSION_INFO;
GO

-- Tạo function FN_GET_MODEL_VERSION_INFO
CREATE FUNCTION dbo.FN_GET_MODEL_VERSION_INFO (
    @MODEL_NAME NVARCHAR(100), -- Tên mô hình cần lấy thông tin
    @INCLUDE_INACTIVE BIT = 0, -- 1: bao gồm cả phiên bản không hoạt động, 0: chỉ phiên bản đang hoạt động
    @AS_OF_DATE DATE = NULL    -- Ngày tham chiếu, mặc định là ngày hiện tại
)
RETURNS TABLE
AS
RETURN (
    WITH LatestValidation AS (
        -- Lấy thông tin đánh giá gần nhất cho mỗi phiên bản mô hình
        SELECT 
            mvr.MODEL_ID,
            MAX(mvr.VALIDATION_DATE) AS LATEST_VALIDATION_DATE
        FROM dbo.MODEL_VALIDATION_RESULTS mvr
        JOIN dbo.MODEL_REGISTRY mr ON mvr.MODEL_ID = mr.MODEL_ID
        WHERE mr.MODEL_NAME = @MODEL_NAME
        AND mvr.VALIDATION_STATUS = 'COMPLETED'
        GROUP BY mvr.MODEL_ID
    ),
    ModelPerformance AS (
        -- Lấy các chỉ số hiệu suất mới nhất cho mỗi phiên bản mô hình
        SELECT 
            lv.MODEL_ID,
            mvr.GINI,
            mvr.KS_STATISTIC,
            mvr.PSI,
            mvr.ACCURACY,
            mvr.PRECISION,
            mvr.RECALL,
            mvr.F1_SCORE,
            mvr.IV,
            mvr.KAPPA,
            mvr.VALIDATION_THRESHOLD_BREACHED,
            CASE 
                WHEN mvr.VALIDATION_THRESHOLD_BREACHED = 1 THEN 'RED'
                WHEN mvr.PSI > 0.1 THEN 'AMBER'
                ELSE 'GREEN'
            END AS PERFORMANCE_STATUS
        FROM LatestValidation lv
        JOIN dbo.MODEL_VALIDATION_RESULTS mvr 
            ON lv.MODEL_ID = mvr.MODEL_ID 
            AND lv.LATEST_VALIDATION_DATE = mvr.VALIDATION_DATE
    ),
    ModelVersions AS (
        -- Add a sort order column to allow ordering in the final result
        SELECT 
            mr.MODEL_ID,
            mr.MODEL_NAME,
            mr.MODEL_VERSION,
            mt.TYPE_CODE AS MODEL_TYPE,
            mt.TYPE_NAME AS MODEL_TYPE_NAME,
            mr.MODEL_DESCRIPTION,
            mr.MODEL_CATEGORY,
            mr.EFF_DATE,
            mr.EXP_DATE,
            mr.IS_ACTIVE,
            mr.CREATED_DATE,
            mr.CREATED_BY,
            mr.UPDATED_DATE,
            mr.UPDATED_BY,
            mp.GINI,
            mp.KS_STATISTIC,
            mp.PSI,
            mp.ACCURACY,
            mp.PRECISION,
            mp.RECALL,
            mp.F1_SCORE,
            mp.IV,
            mp.KAPPA,
            mp.PERFORMANCE_STATUS,
            
            -- Thông tin về số lượng tham số
            (
                SELECT COUNT(*) 
                FROM dbo.MODEL_PARAMETERS mp 
                WHERE mp.MODEL_ID = mr.MODEL_ID AND mp.IS_ACTIVE = 1
            ) AS ACTIVE_PARAMETERS_COUNT,
            
            -- Thông tin về các bảng nguồn
            (
                SELECT COUNT(DISTINCT mtu.SOURCE_TABLE_ID)
                FROM dbo.MODEL_TABLE_USAGE mtu
                WHERE mtu.MODEL_ID = mr.MODEL_ID AND mtu.IS_ACTIVE = 1
            ) AS SOURCE_TABLES_COUNT,
            
            -- Thông tin về số lượng phân khúc
            (
                SELECT COUNT(*) 
                FROM dbo.MODEL_SEGMENT_MAPPING msm 
                WHERE msm.MODEL_ID = mr.MODEL_ID AND msm.IS_ACTIVE = 1
            ) AS SEGMENTS_COUNT,
            
            -- Trạng thái của mô hình
            CASE 
                WHEN mr.IS_ACTIVE = 0 THEN 'INACTIVE'
                WHEN @AS_OF_DATE < mr.EFF_DATE THEN 'PENDING'
                WHEN @AS_OF_DATE > mr.EXP_DATE THEN 'EXPIRED'
                WHEN mp.PERFORMANCE_STATUS = 'RED' THEN 'DEGRADED'
                ELSE 'ACTIVE'
            END AS MODEL_STATUS,
            
            -- Thông tin về các đặc trưng
            (
                SELECT COUNT(*) 
                FROM dbo.FEATURE_MODEL_MAPPING fmm
                WHERE fmm.MODEL_ID = mr.MODEL_ID AND fmm.IS_ACTIVE = 1
            ) AS FEATURES_COUNT,
            
            -- Thêm thông tin về sự kiểm soát/phê duyệt mô hình
            mr.REF_SOURCE AS MODEL_REFERENCE_DOC,
            
            -- Thông tin về số lượng lần đánh giá mô hình
            (
                SELECT COUNT(*) 
                FROM dbo.MODEL_VALIDATION_RESULTS mvr
                WHERE mvr.MODEL_ID = mr.MODEL_ID
            ) AS VALIDATION_COUNT,
            
            -- Số ngày còn lại cho đến khi mô hình hết hạn
            CASE 
                WHEN mr.EXP_DATE IS NULL THEN NULL
                ELSE DATEDIFF(DAY, ISNULL(@AS_OF_DATE, GETDATE()), mr.EXP_DATE)
            END AS DAYS_TO_EXPIRATION,
            
            -- Add a column for sorting by model version
            TRY_CAST(REPLACE(REPLACE(mr.MODEL_VERSION, 'v', ''), '.', '') AS INT) AS VERSION_SORT_ORDER
        FROM dbo.MODEL_REGISTRY mr
        JOIN dbo.MODEL_TYPE mt ON mr.TYPE_ID = mt.TYPE_ID
        LEFT JOIN ModelPerformance mp ON mr.MODEL_ID = mp.MODEL_ID
        WHERE mr.MODEL_NAME = @MODEL_NAME
        AND (@INCLUDE_INACTIVE = 1 OR mr.IS_ACTIVE = 1)
        AND (@AS_OF_DATE IS NULL 
             OR @AS_OF_DATE BETWEEN mr.EFF_DATE AND mr.EXP_DATE
             OR (@INCLUDE_INACTIVE = 1 
                 AND (@AS_OF_DATE >= mr.EFF_DATE OR @AS_OF_DATE <= mr.EXP_DATE))
            )
    )
    -- Final SELECT without ORDER BY (not allowed in table-valued functions)
    SELECT 
        MODEL_ID,
        MODEL_NAME,
        MODEL_VERSION,
        MODEL_TYPE,
        MODEL_TYPE_NAME,
        MODEL_DESCRIPTION,
        MODEL_CATEGORY,
        EFF_DATE,
        EXP_DATE,
        IS_ACTIVE,
        CREATED_DATE,
        CREATED_BY,
        UPDATED_DATE,
        UPDATED_BY,
        GINI,
        KS_STATISTIC,
        PSI,
        ACCURACY,
        PRECISION,
        RECALL,
        F1_SCORE,
        IV,
        KAPPA,
        PERFORMANCE_STATUS,
        ACTIVE_PARAMETERS_COUNT,
        SOURCE_TABLES_COUNT,
        SEGMENTS_COUNT,
        MODEL_STATUS,
        FEATURES_COUNT,
        MODEL_REFERENCE_DOC,
        VALIDATION_COUNT,
        DAYS_TO_EXPIRATION,
        VERSION_SORT_ORDER -- Include the sort order column
    FROM ModelVersions
);
GO

-- Thêm comment cho function
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Lấy thông tin chi tiết về các phiên bản khác nhau của một mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'FUNCTION',  @level1name = N'FN_GET_MODEL_VERSION_INFO';
GO

-- Tạo thêm một function scalar để lấy thông tin version mới nhất
IF OBJECT_ID('dbo.FN_GET_LATEST_MODEL_VERSION', 'FN') IS NOT NULL
    DROP FUNCTION dbo.FN_GET_LATEST_MODEL_VERSION;
GO

CREATE FUNCTION dbo.FN_GET_LATEST_MODEL_VERSION (
    @MODEL_NAME NVARCHAR(100),
    @ACTIVE_ONLY BIT = 1
)
RETURNS NVARCHAR(20)
AS
BEGIN
    DECLARE @LATEST_VERSION NVARCHAR(20);
    
    SELECT TOP 1 @LATEST_VERSION = MODEL_VERSION
    FROM dbo.MODEL_REGISTRY
    WHERE MODEL_NAME = @MODEL_NAME
      AND (@ACTIVE_ONLY = 0 OR IS_ACTIVE = 1)
    ORDER BY 
        CAST(REPLACE(REPLACE(MODEL_VERSION, 'v', ''), '.', '') AS INT) DESC;
    
    RETURN @LATEST_VERSION;
END;
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Lấy phiên bản mới nhất của một mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'FUNCTION',  @level1name = N'FN_GET_LATEST_MODEL_VERSION';
GO

PRINT N'Function FN_GET_MODEL_VERSION_INFO và FN_GET_LATEST_MODEL_VERSION đã được tạo thành công (đã sửa lỗi ORDER BY)';
GO

-- Ví dụ sử dụng
PRINT N'
-- Ví dụ cách sử dụng Function FN_GET_MODEL_VERSION_INFO (với ORDER BY khi sử dụng):
-- Lấy tất cả các phiên bản của mô hình "Credit Scoring Model" bao gồm cả không hoạt động và sắp xếp theo phiên bản
SELECT * FROM dbo.FN_GET_MODEL_VERSION_INFO(''Credit Scoring Model'', 1, NULL)
ORDER BY VERSION_SORT_ORDER DESC; -- Use the sort order column for ordering

-- Lấy các phiên bản đang hoạt động tại một thời điểm cụ thể
SELECT * FROM dbo.FN_GET_MODEL_VERSION_INFO(''Credit Scoring Model'', 0, ''2025-01-15'')
ORDER BY VERSION_SORT_ORDER DESC;

-- Ví dụ cách sử dụng Function FN_GET_LATEST_MODEL_VERSION:
-- Lấy phiên bản mới nhất của mô hình đang hoạt động
SELECT dbo.FN_GET_LATEST_MODEL_VERSION(''Credit Scoring Model'', 1) AS LATEST_VERSION;

-- Lấy phiên bản mới nhất của mô hình (bao gồm cả không hoạt động)
SELECT dbo.FN_GET_LATEST_MODEL_VERSION(''Credit Scoring Model'', 0) AS LATEST_VERSION;
';