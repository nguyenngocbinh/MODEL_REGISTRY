# DATABASE DESCRIPTION

## Tổng Quan

Database MODEL_REGISTRY được thiết kế để quản lý toàn diện vòng đời của các mô hình đánh giá rủi ro tín dụng. Hệ thống cơ sở dữ liệu này bao gồm các bảng để lưu trữ thông tin về mô hình, nguồn dữ liệu, phân khúc khách hàng, kết quả đánh giá hiệu suất, và chất lượng dữ liệu.

## Cấu Trúc Chính

### Quản Lý Mô Hình

1. **MODEL_TYPE**: Phân loại các loại mô hình (PD, LGD, EAD, Scorecard, v.v.) để dễ dàng quản lý và tìm kiếm. Bảng này giúp tổ chức các mô hình theo chức năng và mục đích của chúng.

2. **MODEL_REGISTRY**: Kho lưu trữ trung tâm chứa thông tin cơ bản về tất cả các mô hình. Bảng này lưu trữ tên mô hình, phiên bản, ngày có hiệu lực, và các thông tin mô tả khác. Thông qua liên kết với MODEL_TYPE, mỗi mô hình được gán vào một loại cụ thể.

3. **MODEL_PARAMETERS**: Lưu trữ tham số và hệ số của các mô hình. Bảng này quan trọng cho việc tái tạo kết quả mô hình và theo dõi các thay đổi trong cách tính toán theo thời gian.

### Quản Lý Nguồn Dữ Liệu

4. **MODEL_SOURCE_TABLES**: Quản lý các bảng nguồn được sử dụng bởi các mô hình. Bảng này lưu trữ thông tin về tất cả các bảng dữ liệu được sử dụng trong hệ thống mô hình, bao gồm vị trí, chủ sở hữu dữ liệu, tần suất cập nhật, và đánh giá chất lượng. Việc theo dõi nguồn dữ liệu giúp đảm bảo tính minh bạch và truy xuất nguồn gốc dữ liệu.

5. **MODEL_COLUMN_DETAILS**: Lưu trữ thông tin chi tiết về các cột dữ liệu trong bảng nguồn. Bảng này theo dõi siêu dữ liệu (metadata) của từng cột, bao gồm ý nghĩa nghiệp vụ, kiểu dữ liệu, mức độ quan trọng của đặc trưng, và logic biến đổi dữ liệu. Thông tin này rất quan trọng cho việc hiểu cách mô hình sử dụng dữ liệu và tác động của từng biến.

### Mối Quan Hệ Mô Hình - Dữ Liệu

6. **MODEL_TABLE_USAGE**: Quản lý mối quan hệ nhiều-nhiều giữa mô hình và bảng dữ liệu. Bảng này mô tả cách mô hình sử dụng các bảng dữ liệu, bao gồm mục đích sử dụng (đầu vào chính, lưu trữ kết quả, dữ liệu tham chiếu) và thời gian hiệu lực của mối quan hệ. Điều này giúp theo dõi sự phụ thuộc giữa mô hình và dữ liệu.

7. **MODEL_TABLE_MAPPING**: Lưu trữ chi tiết về cách mô hình sử dụng các bảng dữ liệu. Bảng này chi tiết hơn về cách thức từng mô hình tương tác với các bảng nguồn, bao gồm các cột cần thiết, bộ lọc áp dụng, và thứ tự xử lý. Thông tin này rất quan trọng để hiểu đầy đủ cách dữ liệu được xử lý và biến đổi trong mô hình.

### Phân Khúc và Đánh Giá

8. **MODEL_SEGMENT_MAPPING**: Quản lý việc áp dụng mô hình cho các phân khúc khách hàng. Bảng này giúp xác định mô hình nào áp dụng cho nhóm khách hàng nào, dựa trên các tiêu chí phân khúc và mức độ ưu tiên. Điều này đảm bảo rằng mô hình phù hợp được áp dụng cho từng nhóm khách hàng.

9. **MODEL_VALIDATION_RESULTS**: Lưu trữ kết quả đánh giá hiệu suất mô hình. Bảng này ghi lại các chỉ số hiệu suất quan trọng như AUC, KS, PSI, v.v., cho mỗi lần đánh giá mô hình. Việc theo dõi hiệu suất theo thời gian giúp phát hiện sự suy giảm và đưa ra quyết định về việc tái huấn luyện hoặc thay thế mô hình.

### Giám Sát và Chất Lượng

10. **MODEL_SOURCE_REFRESH_LOG**: Ghi nhật ký cập nhật dữ liệu nguồn. Bảng này theo dõi quá trình cập nhật dữ liệu cho các bảng nguồn, bao gồm thời gian bắt đầu, kết thúc, trạng thái, và số lượng bản ghi xử lý. Điều này giúp giám sát tính kịp thời và đầy đủ của dữ liệu, cũng như giải quyết các vấn đề liên quan đến việc cập nhật dữ liệu.

11. **MODEL_DATA_QUALITY_LOG**: Ghi nhật ký các vấn đề chất lượng dữ liệu. Bảng này theo dõi các vấn đề về chất lượng dữ liệu như dữ liệu thiếu, ngoài phạm vi, trùng lặp, và không nhất quán. Nó cũng theo dõi mức độ nghiêm trọng, số lượng bản ghi bị ảnh hưởng, và trạng thái khắc phục. Việc giám sát chất lượng dữ liệu rất quan trọng để đảm bảo độ tin cậy của kết quả mô hình.

## Mối Quan Hệ Giữa Các Bảng

- **MODEL_REGISTRY** liên kết với **MODEL_TYPE** thông qua trường TYPE_ID để phân loại mô hình.
- **MODEL_PARAMETERS** liên kết với **MODEL_REGISTRY** thông qua trường MODEL_ID để lưu trữ tham số của mô hình.
- **MODEL_TABLE_USAGE** và **MODEL_TABLE_MAPPING** liên kết **MODEL_REGISTRY** với **MODEL_SOURCE_TABLES** để mô tả cách mô hình sử dụng dữ liệu.
- **MODEL_COLUMN_DETAILS** liên kết với **MODEL_SOURCE_TABLES** thông qua trường SOURCE_TABLE_ID để lưu trữ thông tin chi tiết về các cột.
- **MODEL_SEGMENT_MAPPING** liên kết với **MODEL_REGISTRY** thông qua trường MODEL_ID để xác định phân khúc áp dụng.
- **MODEL_VALIDATION_RESULTS** liên kết với **MODEL_REGISTRY** thông qua trường MODEL_ID để lưu trữ kết quả đánh giá.
- **MODEL_SOURCE_REFRESH_LOG** liên kết với **MODEL_SOURCE_TABLES** thông qua trường SOURCE_TABLE_ID để ghi nhật ký cập nhật.
- **MODEL_DATA_QUALITY_LOG** liên kết với **MODEL_SOURCE_TABLES** và **MODEL_COLUMN_DETAILS** để ghi nhật ký vấn đề chất lượng dữ liệu.
