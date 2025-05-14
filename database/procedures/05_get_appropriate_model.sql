/*
Tên file: 05_get_appropriate_model.sql
Mô tả: Tạo stored procedure GET_APPROPRIATE_MODEL để xác định mô hình phù hợp nhất cho một khách hàng
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.0
*/

USE MODEL_REGISTRY
GO

-- Kiểm tra nếu proc đã tồn tại thì xóa
IF OBJECT_ID('MODEL_REGISTRY.dbo.GET_APPROPRIATE_MODEL', 'P') IS NOT NULL
    DROP PROCEDURE dbo.GET_APPROPRIATE_MODEL;
GO

-- Tạo stored procedure GET_APPROPRIATE_MODEL
CREATE PROCEDURE dbo.GET_APPROPRIATE_MODEL
    @CUSTOMER_ID NVARCHAR(50),
    @PROCESS_DATE DATE = NULL,
    @MODEL_TYPE_CODE NVARCHAR(20) = NULL,
    @MODEL_CATEGORY NVARCHAR(50) = NULL,
    @CUSTOMER_ATTRIBUTES NVARCHAR(MAX) = NULL, -- JSON format chứa các thuộc tính của khách hàng
    @DEBUG BIT = 0  -- Thiết lập 1 để xem thông tin gỡ lỗi
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Xử lý tham số mặc định
    IF @PROCESS_DATE IS NULL
        SET @PROCESS_DATE = CONVERT(DATE, GETDATE());
        
    -- Xác thực đầu vào
    IF @CUSTOMER_ID IS NULL
    BEGIN
        RAISERROR(N'Phải cung cấp CUSTOMER_ID', 16, 1);
        RETURN;
    END
    
    -- Tạo bảng tạm để lưu các mô hình phù hợp
    CREATE TABLE #EligibleModels (
        MODEL_ID INT,
        MODEL_NAME NVARCHAR(100),
        MODEL_VERSION NVARCHAR(20),
        TYPE_CODE NVARCHAR(20),
        TYPE_NAME NVARCHAR(100),
        MODEL_CATEGORY NVARCHAR(50),
        SEGMENT_NAME NVARCHAR(100),
        SEGMENT_DESCRIPTION NVARCHAR(500),
        PRIORITY INT,
        IS_ACTIVE BIT,
        MODEL_STATUS NVARCHAR(20),
        MATCH_SCORE INT -- Điểm đánh giá mức độ phù hợp
    );
    
    -- Lấy danh sách tất cả các mô hình đang hoạt động và có thể áp dụng
    INSERT INTO #EligibleModels (
        MODEL_ID,
        MODEL_NAME,
        MODEL_VERSION,
        TYPE_CODE,
        TYPE_NAME,
        MODEL_CATEGORY,
        SEGMENT_NAME,
        SEGMENT_DESCRIPTION,
        PRIORITY,
        IS_ACTIVE,
        MODEL_STATUS,
        MATCH_SCORE
    )
    SELECT 
        mr.MODEL_ID,
        mr.MODEL_NAME,
        mr.MODEL_VERSION,
        mt.TYPE_CODE,
        mt.TYPE_NAME,
        mr.MODEL_CATEGORY,
        sm.SEGMENT_NAME,
        sm.SEGMENT_DESCRIPTION,
        sm.PRIORITY,
        mr.IS_ACTIVE,
        CASE 
            WHEN mr.IS_ACTIVE = 1 AND @PROCESS_DATE BETWEEN mr.EFF_DATE AND mr.EXP_DATE THEN 'ACTIVE'
            WHEN mr.IS_ACTIVE = 1 AND @PROCESS_DATE < mr.EFF_DATE THEN 'PENDING'
            WHEN mr.IS_ACTIVE = 1 AND @PROCESS_DATE > mr.EXP_DATE THEN 'EXPIRED'
            ELSE 'INACTIVE'
        END AS MODEL_STATUS,
        0 AS MATCH_SCORE -- Giá trị ban đầu, sẽ được cập nhật sau
    FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
    JOIN MODEL_REGISTRY.dbo.MODEL_TYPE mt ON mr.TYPE_ID = mt.TYPE_ID
    JOIN MODEL_REGISTRY.dbo.MODEL_SEGMENT_MAPPING sm ON mr.MODEL_ID = sm.MODEL_ID
    WHERE mr.IS_ACTIVE = 1
      AND @PROCESS_DATE BETWEEN mr.EFF_DATE AND mr.EXP_DATE
      AND @PROCESS_DATE BETWEEN sm.EFF_DATE AND sm.EXP_DATE
      AND sm.IS_ACTIVE = 1
      AND (@MODEL_TYPE_CODE IS NULL OR mt.TYPE_CODE = @MODEL_TYPE_CODE)
      AND (@MODEL_CATEGORY IS NULL OR mr.MODEL_CATEGORY = @MODEL_CATEGORY);
    
    -- Nếu không tìm thấy mô hình nào phù hợp
    IF NOT EXISTS (SELECT 1 FROM #EligibleModels)
    BEGIN
        -- In thông báo
        SELECT 
            'NO_ELIGIBLE_MODELS' AS RESULT,
            N'Không tìm thấy mô hình nào phù hợp với các tiêu chí đã chọn' AS MESSAGE,
            @CUSTOMER_ID AS CUSTOMER_ID,
            @PROCESS_DATE AS PROCESS_DATE,
            @MODEL_TYPE_CODE AS MODEL_TYPE_CODE,
            @MODEL_CATEGORY AS MODEL_CATEGORY;
            
        -- Dọn dẹp và thoát
        DROP TABLE #EligibleModels;
        RETURN;
    END
    
    -- Cập nhật điểm đánh giá mức độ phù hợp dựa trên các thuộc tính
    IF @CUSTOMER_ATTRIBUTES IS NOT NULL
    BEGIN
        -- Parse JSON thuộc tính khách hàng
        DECLARE @CustomerAttrs TABLE (
            AttributeName NVARCHAR(100),
            AttributeValue NVARCHAR(MAX)
        );
        
        -- Phân tích chuỗi JSON thành bảng
        INSERT INTO @CustomerAttrs
        SELECT 
            [key] AS AttributeName,
            [value] AS AttributeValue
        FROM OPENJSON(@CUSTOMER_ATTRIBUTES);
        
        -- In thông tin gỡ lỗi nếu cần
        IF @DEBUG = 1
        BEGIN
            SELECT 'Customer Attributes:' AS DEBUG_INFO;
            SELECT * FROM @CustomerAttrs;
        END
        
        -- Cập nhật điểm số cho từng mô hình dựa trên các thuộc tính khách hàng
        -- Mỗi phân khúc có một tiêu chí, chúng ta sẽ đánh giá mức độ phù hợp
        
        -- Lấy danh sách tất cả các tiêu chí phân khúc
        DECLARE @SegmentCriteria TABLE (
            MODEL_ID INT,
            SEGMENT_NAME NVARCHAR(100),
            CriteriaField NVARCHAR(100),
            CriteriaOperator NVARCHAR(10),
            CriteriaValue NVARCHAR(MAX)
        );
        
        -- Giả định rằng SEGMENT_CRITERIA có định dạng "field1 = 'value1' AND field2 IN ('value2a', 'value2b')"
        -- Trong thực tế, bạn có thể cần một phân tích phức tạp hơn hoặc lưu trữ tiêu chí ở định dạng JSON
        
        -- Ví dụ đơn giản: Phân tích chuỗi tiêu chí thành các phần
        INSERT INTO @SegmentCriteria
        SELECT 
            sm.MODEL_ID,
            sm.SEGMENT_NAME,
            s.value AS CriteriaField,
            '=' AS CriteriaOperator, -- Đơn giản hóa, trong thực tế cần phân tích chi tiết hơn
            s.value AS CriteriaValue -- Đơn giản hóa, trong thực tế cần phân tích chi tiết hơn
        FROM MODEL_REGISTRY.dbo.MODEL_SEGMENT_MAPPING sm
        CROSS APPLY STRING_SPLIT(sm.SEGMENT_CRITERIA, ' AND ') s
        WHERE sm.MODEL_ID IN (SELECT MODEL_ID FROM #EligibleModels);
        
        -- In thông tin gỡ lỗi nếu cần
        IF @DEBUG = 1
        BEGIN
            SELECT 'Segment Criteria:' AS DEBUG_INFO;
            SELECT * FROM @SegmentCriteria;
        END
        
        -- Thực hiện đánh giá phức tạp và cập nhật điểm số
        -- Trong ví dụ này, chúng ta sẽ sử dụng một cách tiếp cận đơn giản:
        -- +10 điểm cho mỗi tiêu chí phù hợp với thuộc tính khách hàng
        
        UPDATE m
        SET MATCH_SCORE = MATCH_SCORE + 10
        FROM #EligibleModels m
        JOIN @SegmentCriteria sc ON m.MODEL_ID = sc.MODEL_ID
        JOIN @CustomerAttrs ca ON sc.CriteriaField = ca.AttributeName
        WHERE ca.AttributeValue = sc.CriteriaValue;
        
        -- Cập nhật thêm điểm dựa trên PRIORITY
        -- Mô hình có độ ưu tiên cao hơn sẽ được cộng thêm điểm
        UPDATE #EligibleModels
        SET MATCH_SCORE = MATCH_SCORE + (PRIORITY * 5);
    END
    ELSE
    BEGIN
        -- Nếu không có thuộc tính khách hàng, chỉ dựa vào độ ưu tiên
        UPDATE #EligibleModels
        SET MATCH_SCORE = PRIORITY * 10;
    END
    
    -- In thông tin gỡ lỗi nếu cần
    IF @DEBUG = 1
    BEGIN
        SELECT 'Eligible Models with Match Scores:' AS DEBUG_INFO;
        SELECT * FROM #EligibleModels ORDER BY MATCH_SCORE DESC, PRIORITY DESC;
    END
    
    -- Chọn mô hình phù hợp nhất (điểm cao nhất, nếu bằng nhau thì chọn độ ưu tiên cao hơn)
    DECLARE @SelectedModelID INT;
    DECLARE @SelectedModelName NVARCHAR(100);
    DECLARE @SelectedModelVersion NVARCHAR(20);
    DECLARE @SelectedTypeCode NVARCHAR(20);
    DECLARE @SelectedTypeName NVARCHAR(100);
    DECLARE @SelectedCategory NVARCHAR(50);
    DECLARE @SelectedSegment NVARCHAR(100);
    DECLARE @SelectedMatchScore INT;
    
    SELECT TOP 1
        @SelectedModelID = MODEL_ID,
        @SelectedModelName = MODEL_NAME,
        @SelectedModelVersion = MODEL_VERSION,
        @SelectedTypeCode = TYPE_CODE,
        @SelectedTypeName = TYPE_NAME,
        @SelectedCategory = MODEL_CATEGORY,
        @SelectedSegment = SEGMENT_NAME,
        @SelectedMatchScore = MATCH_SCORE
    FROM #EligibleModels
    WHERE MODEL_STATUS = 'ACTIVE' -- Chỉ xem xét các mô hình đang hoạt động
    ORDER BY MATCH_SCORE DESC, PRIORITY DESC;
    
    -- Kiểm tra xem có mô hình nào được chọn không
    IF @SelectedModelID IS NULL
    BEGIN
        -- In thông báo
        SELECT 
            'NO_ACTIVE_MODELS' AS RESULT,
            N'Không tìm thấy mô hình đang hoạt động' AS MESSAGE,
            @CUSTOMER_ID AS CUSTOMER_ID,
            @PROCESS_DATE AS PROCESS_DATE,
            @MODEL_TYPE_CODE AS MODEL_TYPE_CODE,
            @MODEL_CATEGORY AS MODEL_CATEGORY;
            
        -- Dọn dẹp và thoát
        DROP TABLE #EligibleModels;
        RETURN;
    END
    
    -- Tìm thông tin bổ sung về mô hình được chọn
    DECLARE @SelectedModelInfo TABLE (
        MODEL_ID INT,
        SOURCE_DATABASE NVARCHAR(128),
        SOURCE_SCHEMA NVARCHAR(128),
        SOURCE_TABLE_NAME NVARCHAR(128),
        MODEL_READY_STATUS NVARCHAR(20)
    );
    
    -- Kiểm tra xem mô hình có sẵn sàng để sử dụng không
    INSERT INTO @SelectedModelInfo
    SELECT TOP 1
        mr.MODEL_ID,
        mr.SOURCE_DATABASE,
        mr.SOURCE_SCHEMA,
        mr.SOURCE_TABLE_NAME,
        CASE 
            -- Kiểm tra xem bảng đầu ra có tồn tại không
            WHEN NOT EXISTS (
                SELECT 1 
                FROM INFORMATION_SCHEMA.TABLES 
                WHERE TABLE_CATALOG = mr.SOURCE_DATABASE 
                  AND TABLE_SCHEMA = mr.SOURCE_SCHEMA 
                  AND TABLE_NAME = mr.SOURCE_TABLE_NAME
            ) THEN 'OUTPUT_TABLE_MISSING'
            -- Kiểm tra xem bảng có dữ liệu cho ngày xử lý không
            WHEN NOT EXISTS (
                SELECT 1 
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_CATALOG = mr.SOURCE_DATABASE 
                  AND TABLE_SCHEMA = mr.SOURCE_SCHEMA 
                  AND TABLE_NAME = mr.SOURCE_TABLE_NAME
                  AND COLUMN_NAME = 'PROCESS_DATE'
            ) THEN 'READY' -- Nếu không có cột PROCESS_DATE, giả định là sẵn sàng
            ELSE 'READY' -- Giả định sẵn sàng, trong thực tế cần kiểm tra dữ liệu
        END AS MODEL_READY_STATUS
    FROM MODEL_REGISTRY.dbo.MODEL_REGISTRY mr
    WHERE mr.MODEL_ID = @SelectedModelID;
    
    -- Trả về kết quả
    SELECT 
        'SUCCESS' AS RESULT,
        'Đã tìm thấy mô hình phù hợp nhất' AS MESSAGE,
        @CUSTOMER_ID AS CUSTOMER_ID,
        @PROCESS_DATE AS PROCESS_DATE,
        @SelectedModelID AS MODEL_ID,
        @SelectedModelName AS MODEL_NAME,
        @SelectedModelVersion AS MODEL_VERSION,
        @SelectedTypeCode AS TYPE_CODE,
        @SelectedTypeName AS TYPE_NAME,
        @SelectedCategory AS MODEL_CATEGORY,
        @SelectedSegment AS SEGMENT_NAME,
        @SelectedMatchScore AS MATCH_SCORE,
        si.SOURCE_DATABASE AS OUTPUT_DATABASE,
        si.SOURCE_SCHEMA AS OUTPUT_SCHEMA,
        si.SOURCE_TABLE_NAME AS OUTPUT_TABLE,
        si.MODEL_READY_STATUS,
        CASE 
            WHEN si.MODEL_READY_STATUS = 'READY' THEN N'Mô hình sẵn sàng để sử dụng'
            WHEN si.MODEL_READY_STATUS = 'OUTPUT_TABLE_MISSING' THEN N'Bảng đầu ra không tồn tại'
            ELSE N'Mô hình chưa sẵn sàng, cần kiểm tra dữ liệu'
        END AS READY_STATUS_DESCRIPTION
    FROM @SelectedModelInfo si;
    
    -- Trả về danh sách các mô hình phù hợp khác (5 mô hình có điểm cao tiếp theo)
    SELECT TOP 5
        MODEL_ID,
        MODEL_NAME,
        MODEL_VERSION,
        TYPE_CODE,
        TYPE_NAME,
        MODEL_CATEGORY,
        SEGMENT_NAME,
        MATCH_SCORE,
        PRIORITY,
        MODEL_STATUS
    FROM #EligibleModels
    WHERE MODEL_ID <> @SelectedModelID
    AND MODEL_STATUS = 'ACTIVE'
    ORDER BY MATCH_SCORE DESC, PRIORITY DESC;
    
    -- Dọn dẹp
    DROP TABLE #EligibleModels;
END;
GO

-- Thêm comment cho stored procedure
EXEC sys.sp_addextendedproperty @name = N'MS_Description', 
    @value = N'Xác định mô hình phù hợp nhất cho một khách hàng', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'PROCEDURE',  @level1name = N'GET_APPROPRIATE_MODEL';
GO

PRINT N'Stored procedure GET_APPROPRIATE_MODEL đã được tạo thành công';
GO