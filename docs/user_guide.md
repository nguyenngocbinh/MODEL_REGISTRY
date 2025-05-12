# Hướng Dẫn Sử Dụng Hệ Thống Đăng Ký Mô Hình

## Giới Thiệu

Hệ Thống Đăng Ký Mô Hình (Model Registry) là một công cụ tập trung để quản lý, theo dõi và đánh giá các mô hình đánh giá rủi ro tín dụng. Tài liệu này hướng dẫn người dùng cách sử dụng các chức năng chính của hệ thống.

## Mục Lục

1. [Đăng Nhập và Giao Diện](#đăng-nhập-và-giao-diện)
2. [Tìm Kiếm Mô Hình](#tìm-kiếm-mô-hình)
3. [Xem Chi Tiết Mô Hình](#xem-chi-tiết-mô-hình)
4. [Tra Cứu Bảng Dữ Liệu](#tra-cứu-bảng-dữ-liệu)
5. [Xem Lịch Sử Hiệu Suất](#xem-lịch-sử-hiệu-suất)
6. [Kiểm Tra Phụ Thuộc Dữ Liệu](#kiểm-tra-phụ-thuộc-dữ-liệu)
7. [Báo Cáo và Xuất Dữ Liệu](#báo-cáo-và-xuất-dữ-liệu)
8. [Cảnh Báo và Thông Báo](#cảnh-báo-và-thông-báo)

## Đăng Nhập và Giao Diện

1. **Đăng nhập**:
   - Truy cập hệ thống qua URL: `http://[tên-máy-chủ]/model-registry`
   - Nhập tên người dùng và mật khẩu (sử dụng thông tin đăng nhập Windows của bạn)
   - Nhấn "Đăng nhập"

2. **Giao diện chính**:
   - **Bảng điều khiển**: Hiển thị tổng quan về mô hình, cảnh báo và công việc sắp tới
   - **Menu chính**: Danh sách các chức năng chính của hệ thống
   - **Thanh tìm kiếm**: Cho phép tìm kiếm nhanh mô hình hoặc bảng dữ liệu
   - **Khu vực thông báo**: Hiển thị các cảnh báo và thông báo từ hệ thống

## Tìm Kiếm Mô Hình

1. **Tìm kiếm cơ bản**:
   - Nhập tên mô hình hoặc từ khóa vào thanh tìm kiếm
   - Kết quả sẽ được hiển thị theo độ phù hợp

2. **Tìm kiếm nâng cao**:
   - Nhấn vào "Tìm kiếm nâng cao" để mở bộ lọc
   - Chọn các tiêu chí tìm kiếm:
     - Loại mô hình (PD, LGD, Scorecard, v.v.)
     - Phân khúc (Retail, SME, Corporate, v.v.)
     - Trạng thái (Active, Expired, Pending)
     - Ngày hiệu lực
     - Người phát triển
   - Nhấn "Áp dụng" để lọc kết quả

3. **Lưu tìm kiếm**:
   - Sau khi thiết lập bộ lọc, nhấn "Lưu tìm kiếm này"
   - Đặt tên cho bộ lọc và nhấn "Lưu"
   - Bộ lọc đã lưu sẽ xuất hiện trong menu "Tìm kiếm đã lưu"

## Xem Chi Tiết Mô Hình

1. **Thông tin tổng quan**:
   - Nhấn vào tên mô hình từ danh sách kết quả tìm kiếm
   - Trang chi tiết sẽ hiển thị:
     - Tên và phiên bản mô hình
     - Loại mô hình
     - Ngày hiệu lực và hết hạn
     - Mô tả và tài liệu tham khảo
     - Trạng thái hiện tại

2. **Xem tham số mô hình**:
   - Trên trang chi tiết mô hình, chuyển đến tab "Tham số"
   - Bảng hiển thị danh sách tham số với tên, giá trị và mô tả
   - Nếu có quyền, bạn có thể xem lịch sử thay đổi tham số bằng cách nhấn "Xem lịch sử thay đổi"

3. **Xem phụ thuộc dữ liệu**:
   - Chuyển đến tab "Phụ thuộc dữ liệu"
   - Danh sách các bảng dữ liệu đầu vào và đầu ra sẽ được hiển thị
   - Nhấn vào tên bảng để xem chi tiết về bảng dữ liệu

4. **Xem phân khúc**:
   - Chuyển đến tab "Phân khúc"
   - Danh sách các phân khúc khách hàng mà mô hình được áp dụng
   - Hiển thị tiêu chí phân khúc và độ ưu tiên

5. **Xem kết quả đánh giá**:
   - Chuyển đến tab "Đánh giá hiệu suất"
   - Biểu đồ xu hướng hiệu suất theo thời gian
   - Bảng các chỉ số hiệu suất (GINI, KS, PSI, v.v.)
   - Nhấn vào ngày đánh giá để xem chi tiết kết quả đánh giá

## Tra Cứu Bảng Dữ Liệu

1. **Tìm kiếm bảng dữ liệu**:
   - Từ menu chính, chọn "Danh mục dữ liệu"
   - Nhập tên bảng hoặc từ khóa vào thanh tìm kiếm
   - Sử dụng bộ lọc để thu hẹp kết quả (loại bảng, nguồn dữ liệu, v.v.)

2. **Xem chi tiết bảng dữ liệu**:
   - Nhấn vào tên bảng từ danh sách kết quả
   - Trang chi tiết sẽ hiển thị:
     - Thông tin cơ bản về bảng (tên, schema, database)
     - Mô tả và chủ sở hữu dữ liệu
     - Tần suất cập nhật và độ trễ dữ liệu
     - Danh sách cột với kiểu dữ liệu và mô tả
     - Chỉ số chất lượng dữ liệu

3. **Xem mối quan hệ với mô hình**:
   - Trên trang chi tiết bảng, chuyển đến tab "Mô hình liên quan"
   - Danh sách các mô hình sử dụng bảng này sẽ được hiển thị
   - Thông tin về mục đích sử dụng bảng trong từng mô hình

4. **Xem lịch sử cập nhật dữ liệu**:
   - Chuyển đến tab "Lịch sử cập nhật"
   - Bảng hiển thị lịch sử cập nhật dữ liệu cho bảng này
   - Thông tin về thời gian, trạng thái và số lượng bản ghi được xử lý

5. **Xem vấn đề chất lượng dữ liệu**:
   - Chuyển đến tab "Chất lượng dữ liệu"
   - Danh sách các vấn đề chất lượng dữ liệu đã phát hiện
   - Thông tin về mức độ nghiêm trọng, trạng thái khắc phục và tác động

## Xem Lịch Sử Hiệu Suất

1. **Truy cập báo cáo hiệu suất**:
   - Từ trang chi tiết mô hình, chọn tab "Đánh giá hiệu suất"
   - Hoặc từ menu chính, chọn "Báo cáo" > "Lịch sử hiệu suất mô hình"

2. **Cấu hình báo cáo**:
   - Chọn mô hình cần xem (nếu đang ở trang Báo cáo)
   - Chọn khoảng thời gian
   - Chọn các chỉ số cần hiển thị
   - Nhấn "Tạo báo cáo"

3. **Phân tích xu hướng**:
   - Biểu đồ xu hướng hiển thị các chỉ số hiệu suất theo thời gian
   - Vùng màu xanh, vàng, đỏ thể hiện các ngưỡng đánh giá
   - Nhấn vào điểm dữ liệu để xem chi tiết đánh giá tại thời điểm đó

4. **So sánh hiệu suất theo phân khúc**:
   - Chuyển đến tab "So sánh phân khúc"
   - Biểu đồ so sánh hiệu suất của mô hình trên các phân khúc khác nhau
   - Lựa chọn các phân khúc cần so sánh từ danh sách thả xuống

5. **Xuất báo cáo**:
   - Nhấn "Xuất báo cáo" để tải báo cáo dưới dạng PDF hoặc Excel
   - Chọn định dạng và nội dung cần xuất
   - Báo cáo sẽ được tạo và tải xuống tự động

## Kiểm Tra Phụ Thuộc Dữ Liệu

1. **Xem phụ thuộc dữ liệu của mô hình**:
   - Từ trang chi tiết mô hình, chọn tab "Phụ thuộc dữ liệu"
   - Sơ đồ phụ thuộc sẽ hiển thị các bảng đầu vào và đầu ra của mô hình
   - Nhấn vào từng bảng để xem chi tiết về mối quan hệ

2. **Phân tích tác động**:
   - Từ menu chính, chọn "Công cụ" > "Phân tích tác động"
   - Chọn bảng dữ liệu cần phân tích
   - Hệ thống sẽ hiển thị danh sách các mô hình bị ảnh hưởng nếu bảng này thay đổi
   - Mức độ ưu tiên sẽ được hiển thị cho từng mô hình

3. **Kiểm tra tính khả dụng của dữ liệu**:
   - Từ trang chi tiết mô hình, nhấn "Kiểm tra tính khả dụng"
   - Hệ thống sẽ kiểm tra tất cả các bảng nguồn cần thiết
   - Báo cáo sẽ hiển thị trạng thái của từng bảng và các vấn đề nếu có

## Báo Cáo và Xuất Dữ Liệu

1. **Các loại báo cáo có sẵn**:
   - Danh mục mô hình
   - Lịch sử hiệu suất mô hình
   - Phụ thuộc dữ liệu
   - Danh sách vấn đề chất lượng dữ liệu
   - Báo cáo tuân thủ

2. **Tạo báo cáo**:
   - Từ menu chính, chọn "Báo cáo" > loại báo cáo mong muốn
   - Cấu hình các tham số báo cáo
   - Nhấn "Tạo báo cáo"

3. **Lên lịch báo cáo tự động**:
   - Từ trang báo cáo, nhấn "Lên lịch báo cáo này"
   - Chọn tần suất (hàng ngày, hàng tuần, hàng tháng)
   - Nhập địa chỉ email nhận báo cáo
   - Nhấn "Lưu lịch"

4. **Xuất dữ liệu**:
   - Từ bất kỳ trang danh sách nào, nhấn "Xuất dữ liệu"
   - Chọn định dạng (Excel, CSV, PDF)
   - Chọn các cột cần xuất
   - Nhấn "Xuất"

## Cảnh Báo và Thông Báo

1. **Xem cảnh báo**:
   - Biểu tượng chuông trên thanh điều hướng hiển thị số lượng cảnh báo mới
   - Nhấn vào biểu tượng để xem danh sách cảnh báo
   - Cảnh báo được phân loại theo mức độ nghiêm trọng (Cao, Trung bình, Thấp)

2. **Cấu hình thông báo**:
   - Từ menu người dùng, chọn "Cài đặt thông báo"
   - Chọn các loại thông báo bạn muốn nhận
   - Chọn phương thức nhận thông báo (Ứng dụng, Email)
   - Nhấn "Lưu cài đặt"

3. **Phản hồi cảnh báo**:
   - Nhấn vào cảnh báo để xem chi tiết
   - Chọn "Đánh dấu đã đọc" hoặc "Phân công cho" để chuyển cho người khác
   - Khi vấn đề được giải quyết, nhấn "Đánh dấu đã giải quyết" và nhập bình luận

## Hỗ Trợ và Phản Hồi

Nếu bạn gặp khó khăn khi sử dụng hệ thống hoặc có câu hỏi, vui lòng liên hệ:

- **Email hỗ trợ**: support@model-registry.example.com
- **Điện thoại**: +84 xxx xxx xxx
- **Diễn đàn nội bộ**: [link đến diễn đàn nội bộ]

Bạn cũng có thể gửi phản hồi trực tiếp từ hệ thống bằng cách nhấn vào "Phản hồi" ở góc dưới bên phải của trang.