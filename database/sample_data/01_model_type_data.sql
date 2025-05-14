/*
Tên file: 01_model_type_data.sql
Mô tả: Nhập dữ liệu mẫu cho bảng MODEL_TYPE
Tác giả: Nguyễn Ngọc Bình
Ngày tạo: 2025-05-10
Phiên bản: 1.0
*/

-- Xóa dữ liệu cũ (nếu cần)
-- DELETE FROM MODEL_REGISTRY.dbo.MODEL_TYPE;

-- Nhập dữ liệu vào bảng MODEL_TYPE
INSERT INTO MODEL_REGISTRY.dbo.MODEL_TYPE (
    TYPE_CODE, 
    TYPE_NAME, 
    TYPE_DESCRIPTION
)
VALUES 
('PD', 'Probability of Default', N'Mô hình ước tính xác suất vỡ nợ của khách hàng trong khoảng thời gian nhất định. Thường được sử dụng trong tính toán dự phòng theo IFRS9 và tính toán vốn theo Basel.'),

('LGD', 'Loss Given Default', N'Mô hình ước tính tỷ lệ tổn thất khi khách hàng vỡ nợ. Đây là tỷ lệ phần trăm giá trị không thu hồi được sau khi khách hàng đã vỡ nợ.'),

('EAD', 'Exposure at Default', N'Mô hình ước tính giá trị rủi ro tại thời điểm vỡ nợ. Đo lường dư nợ thực tế của khách hàng khi xảy ra sự kiện vỡ nợ.'),

('B-SCORE', 'Behavioral Scorecard', N'Thẻ điểm đánh giá hành vi khách hàng dựa trên các biến hành vi. Thường được sử dụng để đánh giá khách hàng hiện hữu dựa trên lịch sử giao dịch và thanh toán.'),

('A-SCORE', 'Application Scorecard', N'Thẻ điểm đánh giá khách hàng tại thời điểm đăng ký. Được sử dụng trong quy trình phê duyệt khoản vay mới dựa trên thông tin đăng ký và thông tin bên ngoài.'),

('C-SCORE', 'Collection Scorecard', N'Thẻ điểm đánh giá khả năng thu hồi nợ. Dùng để phân loại khách hàng quá hạn và xác định chiến lược thu hồi nợ phù hợp.'),

('SEGMENT', 'Segmentation Model', N'Mô hình phân khúc khách hàng thành các nhóm đồng nhất. Giúp phân loại khách hàng theo tính chất rủi ro hoặc hành vi tương đồng.'),

('EARLY_WARN', 'Early Warning Signal', N'Mô hình cảnh báo sớm về khả năng vỡ nợ. Phát hiện các dấu hiệu suy giảm chất lượng tín dụng trước khi khách hàng thực sự vỡ nợ.'),

('LIMIT', 'Limit Setting Model', N'Mô hình thiết lập hạn mức tín dụng. Xác định hạn mức phù hợp dựa trên đặc điểm và khả năng trả nợ của khách hàng.'),

('STRESS', 'Stress Testing Model', N'Mô hình kiểm tra căng thẳng. Đánh giá ảnh hưởng của các kịch bản bất lợi đến danh mục tín dụng.'),

('PRICING', 'Risk-based Pricing', N'Mô hình định giá dựa trên rủi ro. Xác định lãi suất phù hợp dựa trên mức độ rủi ro của khách hàng.'),

('FRAUD', 'Fraud Detection', N'Mô hình phát hiện gian lận. Xác định các giao dịch hoặc đơn đăng ký có khả năng gian lận cao.');
GO

PRINT N'Đã nhập dữ liệu mẫu cho bảng MODEL_TYPE thành công.';
GO 
