/*
Tên file: 01_fn_get_model_score.sql
Mô tả: Tạo function FN_GET_MODEL_SCORE để tính điểm của một khách hàng dựa trên mô hình
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.0
*/

-- Kiểm tra nếu function đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.FN_GET_MODEL_SCORE', 'FN') IS NOT NULL
    DROP FUNCTION MODEL_REGISTRY.dbo.FN_GET_MODEL_SCORE;
GO

-- Tạo function FN_GET_MODEL_SCORE
CREATE FUNCTION MODEL_REGISTRY.dbo.FN_GET_MODEL_SCORE (
    @MODEL_ID INT,
    @CUSTOMER_ID NVARCHAR(50),
    @AS_OF_DATE DATE = NULL
)
RETURNS TABLE
AS
RETURN (
    WITH ModelInfo AS (
        -- Lấy thông tin về mô hình
        SELECT 
            mr.MODEL_ID,
            mr.MODEL_NAME,
            mr.MODEL_VERSION,
            mr.SOURCE_DATABASE,
            mr.SOURCE_SCHEMA,
            mr.SOURCE_TABLE_NAME,
            mt.TYPE_CODE,
            mt.TYPE_NAME
        FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
        JOIN MODEL_REGISTRY.dbo.MODEL_TYPE mt ON mr.TYPE_ID = mt.TYPE_ID
        WHERE mr.MODEL_ID = @MODEL_ID
          AND mr.IS_ACTIVE = 1
          AND (@AS_OF_DATE IS NULL OR @AS_OF_DATE BETWEEN mr.EFF_DATE AND mr.EXP_DATE)
    ),
    ScoreTable AS (
        -- Lấy điểm từ bảng đích của mô hình
        SELECT 
            CASE
                -- Nếu là mô hình PD
                WHEN mi.TYPE_CODE = 'PD' THEN 
                    (SELECT TOP 1 ISNULL(SCORE, 0) 
                     FROM OPENDATASOURCE('SQLNCLI', 
                          'Server=' + CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128)) + ';Trusted_Connection=yes;')
                            .mi.SOURCE_DATABASE.mi.SOURCE_SCHEMA.mi.SOURCE_TABLE_NAME
                     WHERE CUSTOMER_ID = @CUSTOMER_ID 
                       AND (@AS_OF_DATE IS NULL OR PROCESS_DATE = @AS_OF_DATE)
                     ORDER BY PROCESS_DATE DESC)
                
                -- Nếu là mô hình Behavioral Scorecard
                WHEN mi.TYPE_CODE = 'BSCORE' THEN 
                    (SELECT TOP 1 ISNULL(SCORE, 0) 
                     FROM OPENDATASOURCE('SQLNCLI', 
                          'Server=' + CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128)) + ';Trusted_Connection=yes;')
                            .mi.SOURCE_DATABASE.mi.SOURCE_SCHEMA.mi.SOURCE_TABLE_NAME
                     WHERE CUSTOMER_ID = @CUSTOMER_ID 
                       AND (@AS_OF_DATE IS NULL OR PROCESS_DATE = @AS_OF_DATE)
                     ORDER BY PROCESS_DATE DESC)
                
                -- Nếu là mô hình Application Scorecard
                WHEN mi.TYPE_CODE = 'APP_SCORE' THEN 
                    (SELECT TOP 1 ISNULL(SCORE, 0) 
                     FROM OPENDATASOURCE('SQLNCLI', 
                          'Server=' + CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128)) + ';Trusted_Connection=yes;')
                            .mi.SOURCE_DATABASE.mi.SOURCE_SCHEMA.mi.SOURCE_TABLE_NAME
                     WHERE CUSTOMER_ID = @CUSTOMER_ID 
                       AND (@AS_OF_DATE IS NULL OR PROCESS_DATE = @AS_OF_DATE)
                     ORDER BY PROCESS_DATE DESC)
                
                -- Nếu là mô hình Early Warning Signal
                WHEN mi.TYPE_CODE = 'EARLY_WARN' THEN 
                    (SELECT TOP 1 ISNULL(WARNING_SCORE, 0) 
                     FROM OPENDATASOURCE('SQLNCLI', 
                          'Server=' + CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128)) + ';Trusted_Connection=yes;')
                            .mi.SOURCE_DATABASE.mi.SOURCE_SCHEMA.mi.SOURCE_TABLE_NAME
                     WHERE CUSTOMER_ID = @CUSTOMER_ID 
                       AND (@AS_OF_DATE IS NULL OR PROCESS_DATE = @AS_OF_DATE)
                     ORDER BY PROCESS_DATE DESC)
                
                -- Mặc định
                ELSE 0
            END AS SCORE,
            
            CASE
                -- Nếu là mô hình PD
                WHEN mi.TYPE_CODE = 'PD' THEN 
                    (SELECT TOP 1 ISNULL(PD, 0) 
                     FROM OPENDATASOURCE('SQLNCLI', 
                          'Server=' + CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128)) + ';Trusted_Connection=yes;')
                            .mi.SOURCE_DATABASE.mi.SOURCE_SCHEMA.mi.SOURCE_TABLE_NAME
                     WHERE CUSTOMER_ID = @CUSTOMER_ID 
                       AND (@AS_OF_DATE IS NULL OR PROCESS_DATE = @AS_OF_DATE)
                     ORDER BY PROCESS_DATE DESC)
                
                -- Nếu là mô hình Behavioral Scorecard
                WHEN mi.TYPE_CODE = 'BSCORE' THEN 
                    (SELECT TOP 1 ISNULL(DEFAULT_PROBABILITY, 0) 
                     FROM OPENDATASOURCE('SQLNCLI', 
                          'Server=' + CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128)) + ';Trusted_Connection=yes;')
                            .mi.SOURCE_DATABASE.mi.SOURCE_SCHEMA.mi.SOURCE_TABLE_NAME
                     WHERE CUSTOMER_ID = @CUSTOMER_ID 
                       AND (@AS_OF_DATE IS NULL OR PROCESS_DATE = @AS_OF_DATE)
                     ORDER BY PROCESS_DATE DESC)
                
                -- Các loại khác không trả về xác suất
                ELSE NULL
            END AS PROBABILITY,
            
            CASE
                -- Nếu là mô hình PD
                WHEN mi.TYPE_CODE = 'PD' THEN 
                    (SELECT TOP 1 ISNULL(RISK_GRADE, 'UNKNOWN') 
                     FROM OPENDATASOURCE('SQLNCLI', 
                          'Server=' + CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128)) + ';Trusted_Connection=yes;')
                            .mi.SOURCE_DATABASE.mi.SOURCE_SCHEMA.mi.SOURCE_TABLE_NAME
                     WHERE CUSTOMER_ID = @CUSTOMER_ID 
                       AND (@AS_OF_DATE IS NULL OR PROCESS_DATE = @AS_OF_DATE)
                     ORDER BY PROCESS_DATE DESC)
                
                -- Nếu là mô hình Behavioral Scorecard
                WHEN mi.TYPE_CODE IN ('BSCORE', 'APP_SCORE') THEN 
                    (SELECT TOP 1 ISNULL(RISK_CATEGORY, 'UNKNOWN') 
                     FROM OPENDATASOURCE('SQLNCLI', 
                          'Server=' + CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128)) + ';Trusted_Connection=yes;')
                            .mi.SOURCE_DATABASE.mi.SOURCE_SCHEMA.mi.SOURCE_TABLE_NAME
                     WHERE CUSTOMER_ID = @CUSTOMER_ID 
                       AND (@AS_OF_DATE IS NULL OR PROCESS_DATE = @AS_OF_DATE)
                     ORDER BY PROCESS_DATE DESC)
                
                -- Nếu là mô hình Early Warning Signal
                WHEN mi.TYPE_CODE = 'EARLY_WARN' THEN 
                    (SELECT TOP 1 ISNULL(WARNING_LEVEL, 'UNKNOWN') 
                     FROM OPENDATASOURCE('SQLNCLI', 
                          'Server=' + CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128)) + ';Trusted_Connection=yes;')
                            .mi.SOURCE_DATABASE.mi.SOURCE_SCHEMA.mi.SOURCE_TABLE_NAME
                     WHERE CUSTOMER_ID = @CUSTOMER_ID 
                       AND (@AS_OF_DATE IS NULL OR PROCESS_DATE = @AS_OF_DATE)
                     ORDER BY PROCESS_DATE DESC)
                
                -- Mặc định
                ELSE 'UNKNOWN'
            END AS RISK_CATEGORY,
            
            (SELECT TOP 1 PROCESS_DATE 
             FROM OPENDATASOURCE('SQLNCLI', 
                  'Server=' + CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128)) + ';Trusted_Connection=yes;')
                    .mi.SOURCE_DATABASE.mi.SOURCE_SCHEMA.mi.SOURCE_TABLE_NAME
             WHERE CUSTOMER_ID = @CUSTOMER_ID 
               AND (@AS_OF_DATE IS NULL OR PROCESS_DATE <= @AS_OF_DATE)
             ORDER BY PROCESS_DATE DESC) AS SCORE_DATE
        FROM ModelInfo mi
    )
    
    -- Trả về kết quả cuối cùng
    SELECT 
        mi.MODEL_ID,
        mi.MODEL_NAME,
        mi.MODEL_VERSION,
        mi.TYPE_CODE,
        mi.TYPE_NAME,
        @CUSTOMER_ID AS CUSTOMER_ID,
        st.SCORE,
        st.PROBABILITY,
        st.RISK_CATEGORY,
        st.SCORE_DATE,
        CASE 
            WHEN st.SCORE IS NULL THEN 'NOT_FOUND'
            WHEN @AS_OF_DATE IS NOT NULL AND st.SCORE_DATE <> @AS_OF_DATE THEN 'OUTDATED'
            ELSE 'CURRENT'
        END AS SCORE_STATUS
    FROM ModelInfo mi
    LEFT JOIN ScoreTable st ON 1=1
);
GO

-- Thêm comment cho function
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Tính điểm của một khách hàng dựa trên mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'FUNCTION',  @level1name = N'FN_GET_MODEL_SCORE';
GO

PRINT 'Function FN_GET_MODEL_SCORE đã được tạo thành công';
GO