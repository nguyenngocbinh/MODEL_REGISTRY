
# TRIGGERS DESCRIPTION

## Tổng Quan

Thư mục `triggers` chứa các triggers được sử dụng trong Hệ Thống Đăng Ký Mô Hình để tự động ghi nhật ký các thay đổi trong cơ sở dữ liệu. Các triggers này đóng vai trò quan trọng trong việc duy trì dấu vết kiểm toán (audit trail) cho các thay đổi trong dữ liệu mô hình và tham số, đáp ứng các yêu cầu quản trị mô hình và tuân thủ quy định.

## Danh Sách Triggers

### 1. TRG_AUDIT_MODEL_REGISTRY

**Mô tả**: Trigger sau (AFTER) theo dõi và ghi lại tất cả các thay đổi (INSERT, UPDATE, DELETE) trong bảng MODEL_REGISTRY.

**Bảng liên quan**:
- Bảng nguồn: `MODEL_REGISTRY.dbo.MODEL_REGISTRY`
- Bảng đích: `MODEL_REGISTRY.dbo.AUDIT_MODEL_REGISTRY`

**Thông tin được ghi nhật ký**:
- MODEL_ID: ID của mô hình bị thay đổi
- ACTION_TYPE: Loại hành động ('INSERT', 'UPDATE', 'DELETE')
- FIELD_NAME: Tên trường bị thay đổi
- OLD_VALUE: Giá trị cũ (NULL đối với INSERT)
- NEW_VALUE: Giá trị mới (NULL đối với DELETE)
- CHANGE_DATE: Thời gian thay đổi
- CHANGED_BY: Người thực hiện thay đổi
- HOST_NAME: Tên máy thực hiện thay đổi

**Tính năng bổ sung**:
- Tự động cập nhật UPDATED_BY và UPDATED_DATE trong bảng MODEL_REGISTRY khi có thay đổi
- Chỉ ghi nhật ký các trường thực sự thay đổi, không ghi nhật ký các trường hệ thống như CREATED_DATE, CREATED_BY
- Xử lý các kiểu dữ liệu khác nhau, bao gồm cả dữ liệu ngày tháng

### 2. TRG_AUDIT_MODEL_PARAMETERS

**Mô tả**: Trigger sau (AFTER) theo dõi và ghi lại tất cả các thay đổi (INSERT, UPDATE, DELETE) trong bảng MODEL_PARAMETERS, đặc biệt chú trọng đến việc theo dõi thay đổi trong tham số mô hình.

**Bảng liên quan**:
- Bảng nguồn: `MODEL_REGISTRY.dbo.MODEL_PARAMETERS`
- Bảng đích: `MODEL_REGISTRY.dbo.AUDIT_MODEL_PARAMETERS`

**Thông tin được ghi nhật ký**:
- PARAMETER_ID: ID của tham số bị thay đổi
- MODEL_ID: ID của mô hình liên quan
- ACTION_TYPE: Loại hành động ('INSERT', 'UPDATE', 'DELETE')
- FIELD_NAME: Tên trường bị thay đổi
- OLD_VALUE: Giá trị cũ (NULL đối với INSERT)
- NEW_VALUE: Giá trị mới (NULL đối với DELETE)
- CHANGE_DATE: Thời gian thay đổi
- CHANGED_BY: Người thực hiện thay đổi
- HOST_NAME: Tên máy thực hiện thay đổi
- CHANGE_REASON: Lý do thay đổi tham số (quan trọng cho quản trị mô hình)

**Tính năng bổ sung**:
- Tự động cập nhật UPDATED_BY và UPDATED_DATE trong bảng MODEL_PARAMETERS khi có thay đổi
- Xử lý đặc biệt cho trường PARAMETER_VALUE để đảm bảo ghi nhật ký chính xác
- Hỗ trợ CONTEXT_INFO để truyền lý do thay đổi từ ứng dụng

**Stored Procedure Đi Kèm**:
- `SET_PARAMETER_CHANGE_REASON`: Thiết lập lý do thay đổi tham số để sử dụng trong trigger

## Cách Sử Dụng Trong Quy Trình

### Ghi Nhật Ký Thay Đổi Mô Hình

Các triggers hoạt động tự động khi có thay đổi trong bảng MODEL_REGISTRY hoặc MODEL_PARAMETERS. Không cần thực hiện các bước bổ sung để kích hoạt việc ghi nhật ký.

### Ghi Nhật Ký Thay Đổi Tham Số Với Lý Do

Khi cần thay đổi tham số mô hình và ghi lại lý do, thực hiện các bước sau:

1. Gọi thủ tục SET_PARAMETER_CHANGE_REASON để thiết lập lý do:
   ```sql
   EXEC MODEL_REGISTRY.dbo.SET_PARAMETER_CHANGE_REASON 'Cập nhật tham số do thay đổi trong chính sách tín dụng';
   ```

2. Thực hiện cập nhật tham số:
   ```sql
   UPDATE MODEL_REGISTRY.dbo.MODEL_PARAMETERS
   SET PARAMETER_VALUE = 0.25
   WHERE PARAMETER_ID = 123;
   ```

3. Trigger sẽ tự động sử dụng lý do đã được thiết lập khi ghi nhật ký thay đổi.

### Truy Vấn Lịch Sử Thay Đổi

Để truy vấn lịch sử thay đổi của một mô hình cụ thể:

```sql
-- Truy vấn lịch sử thay đổi thông tin mô hình
SELECT * 
FROM MODEL_REGISTRY.dbo.AUDIT_MODEL_REGISTRY
WHERE MODEL_ID = 1
ORDER BY CHANGE_DATE DESC;

-- Truy vấn lịch sử thay đổi tham số mô hình
SELECT * 
FROM MODEL_REGISTRY.dbo.AUDIT_MODEL_PARAMETERS
WHERE MODEL_ID = 1
ORDER BY CHANGE_DATE DESC;
```