/*
Tên file: 01_fn_get_model_score_function.sql
Mô tả: Tạo function FN_GET_MODEL_SCORE để tính điểm của một khách hàng dựa trên mô hình (không sử dụng dynamic SQL)
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-14
Phiên bản: 1.3
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu function đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.FN_GET_MODEL_SCORE', 'IF') IS NOT NULL
    DROP FUNCTION dbo.FN_GET_MODEL_SCORE;
GO

-- Tạo function FN_GET_MODEL_SCORE
CREATE FUNCTION dbo.FN_GET_MODEL_SCORE (
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
    )
    -- Trả về kết quả cuối cùng - sử dụng dữ liệu mẫu thay vì truy vấn bảng thực tế
    -- Trong trường hợp thực tế, bạn cần có một kho dữ liệu tập trung hoặc các bảng tạm để truy vấn
    SELECT 
        mi.MODEL_ID,
        mi.MODEL_NAME,
        mi.MODEL_VERSION,
        mi.TYPE_CODE,
        mi.TYPE_NAME,
        @CUSTOMER_ID AS CUSTOMER_ID,
        
        -- Dữ liệu giả định sẽ được thay thế trong môi trường thực tế
        CASE 
            WHEN mi.TYPE_CODE IN ('PD', 'BSCORE', 'ASCORE') THEN 
                -- Trong thực tế, đây sẽ là truy vấn đến bảng thực sự
                -- Ví dụ: (SELECT TOP 1 SCORE FROM CUSTOMER_SCORES WHERE CUSTOMER_ID = @CUSTOMER_ID)
                750.0  -- Giá trị giả định
            WHEN mi.TYPE_CODE = 'EARLY_WARN' THEN 
                -- Tương tự ở trên
                85.0  -- Giá trị giả định
            ELSE 0
        END AS SCORE,
        
        CASE 
            WHEN mi.TYPE_CODE = 'PD' THEN 
                0.05  -- Giá trị giả định
            WHEN mi.TYPE_CODE = 'BSCORE' THEN 
                0.15  -- Giá trị giả định
            ELSE NULL
        END AS PROBABILITY,
        
        CASE 
            WHEN mi.TYPE_CODE = 'PD' THEN 
                'A+'  -- Giá trị giả định
            WHEN mi.TYPE_CODE IN ('BSCORE', 'ASCORE') THEN 
                'LOW_RISK'  -- Giá trị giả định
            WHEN mi.TYPE_CODE = 'EARLY_WARN' THEN 
                'MEDIUM'  -- Giá trị giả định
            ELSE 'UNKNOWN'
        END AS RISK_CATEGORY,
        
        -- Ngày xử lý giả định
        DATEADD(DAY, -1, GETDATE()) AS SCORE_DATE,
        
        -- Trạng thái điểm số
        CASE 
            WHEN mi.MODEL_ID IS NULL THEN 'NOT_FOUND'
            WHEN @AS_OF_DATE IS NOT NULL AND DATEADD(DAY, -1, GETDATE()) <> @AS_OF_DATE THEN 'OUTDATED'
            ELSE 'CURRENT'
        END AS SCORE_STATUS
    FROM ModelInfo mi
);
GO

-- Thêm comment cho function
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Tính điểm của một khách hàng dựa trên mô hình', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'FUNCTION',  @level1name = N'FN_GET_MODEL_SCORE';
GO

PRINT N'Function FN_GET_MODEL_SCORE đã được tạo thành công';
GO