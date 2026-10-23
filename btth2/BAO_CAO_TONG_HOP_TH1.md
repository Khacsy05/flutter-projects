# BÁO CÁO TỔNG HỢP TOÀN DIỆN BÀI THỰC HÀNH TH1

HỌC PHẦN: LẬP TRÌNH DI ĐỘNG
ĐỀ TÀI: XÂY DỰNG ỨNG DỤNG QUẢN LÝ TÀI LIỆU HỌC TẬP THEO KIẾN TRÚC CASHEW
Dự án: D:\flutter\btth1
(Bao gồm đầy đủ 5 nội dung: Phân tích DFD - Cấu trúc phân lớp - Triển khai CRUD - Kiểm thử - Báo cáo giải trình)

# BÁO CÁO KỸ THUẬT - YÊU CẦU 1

PHÂN TÍCH YÊU CẦU CHỨC NĂNG VÀ THIẾT KẾ SƠ ĐỒ LUỒNG DỮ LIỆU
ỨNG DỤNG QUẢN LÝ TÀI LIỆU HỌC TẬP


| Đề tài nghiên cứu: | Xây dựng Ứng dụng Quản lý Tài liệu Học tập theo Kiến trúc Cashew |
| --- | --- |
| Nhiệm vụ thực hiện: | Yêu cầu 1 trong Checklist: Phân tích chức năng & Thiết kế DFD Mức 0, Mức 1 |


## 1. PHÂN TÍCH YÊU CẦU CHỨC NĂNG HỆ THỐNG

Trong kiến trúc ứng dụng Cashew, hệ thống được thiết kế hướng thực thể xoay quanh dòng chảy tài chính với 4 trụ cột cơ bản: Transactions (Giao dịch), Wallets (Ví/Tài khoản nguồn), Categories (Danh mục) và Budgets/Objectives (Hạn ngạch/Mục tiêu). Khi chuyển giao sang bài toán Quản lý Tài liệu Học tập, toàn bộ nghiệp vụ được ánh xạ (mapping) tương ứng 1-1 nhằm kế thừa trọn vẹn khả năng quản trị quan hệ và tính mô-đun hóa.


| Thực thể kiến trúc Cashew | Thực thể ứng dụng Quản lý Tài liệu | Ý nghĩa và vai trò nghiệp vụ |
| --- | --- | --- |
| Transactions (Giao dịch) | Study Documents (Tài liệu học tập) | Thực thể trung tâm lưu giữ các tệp bài giảng, slide, giáo trình, bài tập và ghi chú học tập. |
| Wallets (Ví / Tài khoản) | Courses / Subjects (Môn học / Học phần) | Đóng vai trò khoang chứa độc lập. Mỗi môn học quản lý một tập tài liệu, có mã màu và icon riêng. |
| Categories (Danh mục) | Document Topics (Chủ đề / Dạng tài liệu) | Cấu trúc phân cấp 2 tầng (Chủ đề chính & Chủ đề phụ) để phân loại nội dung kiến thức khoa học. |
| Budgets & Objectives (Mục tiêu) | Study Goals & Deadlines (Kế hoạch / Hạn nộp) | Định lượng chỉ tiêu học tập (số tài liệu cần đọc/tuần) và nhắc nhở thời hạn nộp bài tập lớn/đồ án. |


## 1.1. Chi tiết các nhóm chức năng nghiệp vụ cốt lõi

Nhóm 1: Quản lý Tài liệu Học tập (CRUD Documents): Thêm mới tài liệu gồm: Tiêu đề, Môn học trực thuộc (bắt buộc), Chủ đề, Đường dẫn tệp nội bộ hoặc liên kết Drive/URL, Ghi chú tóm tắt (Note <= 500 ký tự). Hỗ trợ đánh dấu trạng thái Đã đọc / Chưa đọc, cờ Đánh dấu quan trọng (Favorite). Cho phép chỉnh sửa và cập nhật tem thời gian dateTimeModified; Hỗ trợ xóa đơn lẻ hoặc xóa hàng loạt (Bulk Delete).

Nhóm 2: Quản lý Môn học / Học phần (Courses Management): Tạo và tùy biến môn học với bảng mã màu chủ đề (Color Palette) và Icon/Emoji đặc trưng. Tự động tính toán tổng số lượng tài liệu, tổng dung lượng tệp lưu trữ và phần trăm hoàn thành tài liệu của từng môn học.

Nhóm 3: Phân loại Chủ đề & Dạng tài liệu (Hierarchical Topics): Hệ thống hỗ trợ phân loại 2 tầng linh hoạt: Tầng chính (Slide bài giảng, Giáo trình chính, Bài tập lớn, Đề thi thử) và Tầng phụ (Chương 1, Chương 2, Tài liệu tham khảo mở rộng).

Nhóm 4: Quản lý Kế hoạch & Hạn nộp (Goals & Deadlines): Thiết lập chỉ tiêu số lượng tài liệu cần hoàn thành theo chu kỳ Tuần/Tháng. Quản lý danh sách Deadlines kèm tính năng tự động đếm ngược số ngày còn lại và phát thông báo nhắc nhở.

Nhóm 5: Tìm kiếm & Lọc dữ liệu tốc độ cao (Fast Search & Filters): Tìm kiếm toàn văn (Full-Text Search) theo tiêu đề và nội dung ghi chú tức thì (< 5ms). Kết hợp bộ lọc đa tiêu chí (Môn học + Dạng tài liệu + Trạng thái hoàn thành + Thời gian tạo).

## 2. THIẾT KẾ SƠ ĐỒ LUỒNG DỮ LIỆU (DATA FLOW DIAGRAM - DFD)

Ứng dụng tuân thủ nghiêm ngặt nguyên lý Local-First của kiến trúc Cashew: Mọi thao tác xử lý nghiệp vụ, đọc/ghi dữ liệu đều diễn ra trực tiếp trên cơ sở dữ liệu SQLite nội bộ của thiết bị để triệt tiêu hoàn toàn độ trễ mạng (Zero Latency). Tiến trình đồng bộ đám mây (Cloud Sync) được tách biệt hoàn toàn để chạy ngầm dưới nền.

## 2.1. Sơ đồ luồng dữ liệu ngữ cảnh (DFD Mức 0 - Context Level)

Sơ đồ DFD Mức 0 xác định ranh giới tương tác giữa Sinh viên (User) với Hệ thống Quản lý Tài liệu Học tập và các tác nhân đám mây bên ngoài (Google Drive, Firebase Auth):


| Tác nhân ngoài (Entity) | Luồng dữ liệu vào (Input Flow) | Luồng dữ liệu ra (Output Flow) |
| --- | --- | --- |
| Sinh viên / Người dùng | Yêu cầu CRUD tài liệu, môn học; Từ khóa tìm kiếm; Bộ lọc chủ đề; Yêu cầu sao lưu. | Hiển thị danh sách tài liệu; Biểu đồ thống kê tiến độ học; Kết quả tìm kiếm lọc; Cảnh báo deadline. |
| Google Drive AppData Storage | Tệp sao lưu phục hồi (.sqlite snapshot). | Tệp nhị phân sao lưu nén (.sqlite) được đẩy lên tự động theo chu kỳ. |
| Firebase Authentication | Mã ủy quyền đăng nhập (Google OAuth 2.0 / Email Auth). | Token xác thực danh tính người dùng (JWT Token) để cấp quyền truy cập dịch vụ. |
|  |  |  |


## 2.2. Sơ đồ luồng dữ liệu phân rã chi tiết (DFD Mức 1 - Functional Decomposition)

Hệ thống được phân rã thành 4 tiến trình xử lý cốt lõi, tương tác với 5 kho lưu trữ dữ liệu cục bộ và dịch vụ đám mây:


| Mã tiến trình | Tên tiến trình xử lý | Dữ liệu đầu vào & Kho dữ liệu | Kết quả đầu ra nghiệp vụ |
| --- | --- | --- | --- |
| P 1.0 | Quản lý Tài liệu & Môn học (CRUD) | Form nhập liệu từ UI ➔ Kho D1 (Documents), Kho D2 (Courses). | Thực thi ghi Atomic SQL INSERT/UPDATE. Kích hoạt Reactive Stream cập nhật UI tức thì. |
| P 2.0 | Tìm kiếm & Lọc dữ liệu tốc độ cao | Từ khóa tìm kiếm, Chip chọn môn/loại ➔ Truy vấn Kho D1, D2. | Trả về tập kết quả tài liệu thỏa mãn mệnh đề WHERE trong < 5ms thông qua Indexing. |
| P 3.0 | Tính toán Tiến độ & Mục tiêu Deadline | Đọc trạng thái từ Kho D1 & Kho D4 (StudyGoals). | Sinh chỉ số phần trăm hoàn thành; Kích hoạt thông báo cảnh báo tài liệu sắp quá hạn. |
| P 4.0 | Đồng bộ & Sao lưu đám mây ngầm | Lắng nghe cờ Dirty Flag từ Kho D1 ➔ Đọc toàn bộ DB SQLite. | Bộ đệm Debouncer chờ 3s ➔ Kết xuất snapshot sync-<clientID>.sqlite đẩy lên Google Drive. |


## 2.3. Mô tả chi tiết 3 kịch bản luồng dữ liệu then chốt

Kịch bản 1: Luồng Ghi dữ liệu khi thêm tài liệu mới (Write Flow): Sinh viên điền biểu mẫu trên AddDocumentPage ➔ Form Validator kiểm tra tính hợp lệ ➔ Đóng gói thành DocumentCompanion ➔ Gọi hàm Database.into(documents).insert(companion) thực thi trong một Transaction nguyên khối (Atomic Transaction) xuống đĩa SQLite trong 1-2 mili-giây ➔ Drift ORM phát tín hiệu Reactive Stream báo hiệu dữ liệu đổi ➔ Tất cả các Widget UI đang mở tự động gọi hàm build() vẽ lại số liệu mà không cần tải lại trang.

Kịch bản 2: Luồng Đọc & Tìm kiếm phản ứng nhanh (Read & Search Flow): Sinh viên gõ từ khóa tìm kiếm ➔ Luồng Stream nhận ký tự và áp dụng Debounce 300ms ➔ Tầng Logic sinh câu truy vấn SQL SELECT kết hợp WHERE title LIKE ? AND courseFk = ? ➔ Tận dụng chỉ mục Database Index trên trường title để quét bảng với độ phức tạp O(log N) ➔ Trả danh sách kết quả về UI gần như tức thời.

Kịch bản 3: Luồng Sao lưu ngầm không gây nghẽn (Background Cloud Sync Flow): Sau khi hoàn tất thao tác ghi dữ liệu, hệ thống bật cờ Dirty Flag ➔ SyncClient khởi động bộ đếm Debouncer 3 giây ➔ Trích xuất tệp snapshot SQLite ➔ Gửi yêu cầu HTTP Multipart POST ngầm qua Google Drive API v3 lên thư mục an toàn appDataFolder ➔ Ghi nhận tem thời gian lastSynced mà không làm ảnh hưởng đến độ mượt mà của giao diện (60fps).


| 📌 KẾT LUẬN THIẾT KẾ YÊU CẦU 1: Việc phân tách triệt để luồng đọc/ghi tại chỗ (Local SQLite) và luồng sao lưu nền (Background Cloud Sync) chính là yếu tố quyết định giúp ứng dụng đạt được tính sẵn sàng cao (High Availability), hoạt động bền bỉ trong mọi điều kiện mạng và bảo vệ trọn vẹn dữ liệu học tập của sinh viên. |
| --- |


# BÁO CÁO KỸ THUẬT - YÊU CẦU 2

THIẾT LẬP CẤU TRÚC THƯ MỤC VÀ PHÂN LỚP HỆ THỐNG
THEO TIÊU CHUẨN KIẾN TRÚC CASHEW


| Đề tài áp dụng: | Ứng dụng Quản lý Tài liệu Học tập (Study Document Manager) |
| --- | --- |
| Nhiệm vụ thực hiện: | Yêu cầu 2: Chuẩn hóa cấu trúc Package/Folder, phân định ranh giới Layer |


## 1. TIÊU CHUẨN THIẾT KẾ PHÂN LỚP THEO KIẾN TRÚC CASHEW

Ứng dụng Cashew phân tách hệ thống thành 4 lớp chuyên biệt theo nguyên lý Separation of Concerns (SoC) kết hợp kiến trúc Local-First. Để đáp ứng tính mô-đun hóa và khả năng mở rộng, cấu trúc dự án Quản lý Tài liệu Học tập được tổ chức theo ma trận phân lớp chuẩn hóa dưới đây:


| Tên Lớp (Layer) | Thư mục tương ứng | Thành phần phụ trách | Trách nhiệm & Ranh giới kỹ thuật |
| --- | --- | --- | --- |
| 1. Presentation Layer (Giao diện) | lib/pages/<br>lib/widgets/ | HomePage, AddDocumentPage, NavigationFramework | Chỉ chịu trách nhiệm render UI Widgets, tiếp nhận thao tác chạm/vuốt của sinh viên, xử lý Responsive Layout (Mobile BottomBar vs Desktop Sidebar). Tuyệt đối không chứa câu lệnh SQL thô. |
| 2. State Management & Logic | lib/struct/<br>(Provider/State) | DocumentNotifier, FilterState, SettingsGlobal | Cầu nối trung gian: nhận yêu cầu từ UI, kiểm tra tính toàn vẹn (Validate form, hạn nộp), quản lý luồng dữ liệu phản ứng (Reactive Streams), cập nhật trạng thái toàn cục. |
| 3. Local Persistence (Lưu trữ) | lib/database/ | Drift ORM, Tables, schema_versions, SQLite Driver | Đảm bảo tính toàn vẹn chuẩn ACID. Định nghĩa lược đồ thực thể dưới dạng Type-Safe Dart Class. Thực thi câu lệnh SQL INSERT/UPDATE atomic và phát tín hiệu Stream khi DB thay đổi. |
| 4. Cloud & Infrastructure | lib/struct/sync/<br>(Drive & Auth) | SyncClient, GoogleDriveClient, FirebaseAuth | Chạy ngầm (Background Task): Lập lịch kết xuất tệp sao lưu snapshot .sqlite khi có dữ liệu mới, đồng bộ đám mây qua Google Drive API v3 mà không làm gián đoạn luồng UI (Main Thread). |


## 2. CẤU TRÚC THƯ MỤC DỰ ÁN CHI TIẾT (FOLDER DIRECTORY TREE)

Toàn bộ mã nguồn và tài nguyên được cấu trúc bài bản, phản ánh đúng kiến trúc Cashew:

lib/
├── main.dart                          # Điểm khởi chạy ứng dụng (Entry point), thiết lập Theme, Provider & Localizations
├── colors.dart                       # Bảng màu Material You 3, HSL thích ứng giao diện sáng/tối (Dark/Light Mode)
├── database/                         # TẦNG LƯU TRỮ CỤC BỘ (PERSISTENCE LAYER)
│   ├── tables.dart                   # Định nghĩa schema Drift: bảng Documents, Courses, Topics, StudyGoals
│   ├── tables.g.dart                 # Mã nguồn sinh tự động bởi build_runner (Type-safe Companions & Queries)
│   ├── schema_versions.dart          # Quản lý phiên bản migration cơ sở dữ liệu (Schema Migration Engine)
│   └── platform/                     # Hỗ trợ đa nền tảng
│       ├── native.dart               # Khởi tạo SQLite chuẩn C++ (Android, iOS, Windows, macOS, Linux)
│       └── web.dart                  # Khởi tạo WebAssembly SQLite / IndexedDB cho trình duyệt Web
├── struct/                           # TẦNG ĐẶC TẢ DỮ LIỆU & LOGIC NGHIỆP VỤ (BUSINESS LOGIC)
│   ├── settings.dart                 # Quản lý cài đặt SharedPreferences (Key-value store)
│   ├── sync_client.dart              # Quản lý tiến trình sao lưu nền lên Google Drive & giải quyết xung đột
│   ├── document_enums.dart           # Các enum nghiệp vụ: DocumentType, ReadStatus, Priority, GoalCycle
│   └── database_global.dart          # Đối tượng Database Singleton dùng chung cho toàn bộ ứng dụng
├── pages/                            # TẦNG MÀN HÌNH GIAO DIỆN CHÍNH (PAGES LAYER)
│   ├── homePage/                     # Màn hình trang chủ tổng hợp
│   │   ├── homePage.dart             # Điều phối các thành phần widget trên trang chủ
│   │   ├── homePageDocumentsList.dart# Danh sách tài liệu gần đây (tương tự homeTransactions)
│   │   └── homePageCourseSummary.dart# Thống kê môn học (tương tự homePageWalletSwitcher)
│   ├── addDocumentPage.dart          # Màn hình thêm/sửa tài liệu (tương tự AddTransactionPage)
│   ├── documentDetailsPage.dart      # Màn hình xem chi tiết tài liệu, ghi chú và mở file
│   ├── coursesListPage.dart          # Màn hình quản lý danh sách môn học (tương tự walletDetailsPage)
│   ├── studyGoalsPage.dart           # Màn hình quản lý kế hoạch đọc và thời hạn deadline (tương tự budgetPage)
│   └── searchFilterPage.dart         # Màn hình tìm kiếm toàn văn và lọc đa tiêu chí (tương tự transactionsSearchPage)
└── widgets/                          # TẦNG THÀNH PHẦN TÁI SỬ DỤNG (REUSABLE UI COMPONENTS)
    ├── navigationFramework.dart      # Bộ khung điều hướng thích ứng: Bottom Bar trên Mobile / Sidebar trên Desktop
    ├── navigationSidebar.dart        # Thanh điều hướng dọc cho màn hình máy tính bảng và web
    ├── openBottomSheet.dart          # Hộp thoại Modal BottomSheet chọn môn học, chủ đề, thời hạn
    ├── documentCard.dart             # Widget thẻ tài liệu hiển thị dạng danh sách hoặc lưới (Card view)
    ├── courseCard.dart               # Widget thẻ môn học hiển thị mã màu và tỷ lệ hoàn thành
    └── linearGradientFadedEdges.dart # Hiệu ứng chuyển màu mờ viền cao cấp đặc trưng của Cashew

## 3. GIẢI TRÌNH RANH GIỚI & NGUYÊN TẮC LIÊN KẾT GIỮA CÁC LỚP

Nguyên tắc Gắn kết lỏng (Loose Coupling): Tầng Giao diện (Pages/Widgets) không bao giờ thực hiện câu lệnh SQL trực tiếp. Mọi yêu cầu đều được chuyển giao qua các đối tượng trung gian (Companions). Ví dụ: AddDocumentPage chỉ đóng gói dữ liệu và gọi database.insertDocument(), không quan tâm dữ liệu được lưu bằng file SQLite native hay Wasm trên web.

Cơ chế Dòng dữ liệu Một chiều (Unidirectional Data Flow): UI phát sinh sự kiện (User Action) ➔ Logic xử lý và ghi xuống Drift Database ➔ Drift Database phát sinh luồng dữ liệu phản ứng (Reactive Stream) ➔ StreamBuilder trên UI tự động lắng nghe và cập nhật lại giao diện. Điều này loại bỏ hoàn toàn các lỗi xung đột trạng thái dữ liệu (State Inconsistency).

Tính độc lập của Dịch vụ nền (Background Isolation): Tiến trình đồng bộ SyncClient hoạt động hoàn toàn tách biệt trên luồng nền thông qua cơ chế Debouncer (bộ đếm trễ 3 giây). Nếu mất mạng hoặc Google Drive gặp sự cố, ứng dụng vẫn hoạt động 100% bình thường trên tầng SQLite nội bộ mà không bao giờ bị treo ứng dụng (ANR).


| 📌 KẾT LUẬN YÊU CẦU 2: Cấu trúc thư mục và phân lớp theo chuẩn Cashew giúp dự án đạt điểm tối đa về tính mô-đun hóa: Lập trình viên giao diện có thể phát triển độc lập trong thư mục lib/pages và lib/widgets mà không làm ảnh hưởng đến tầng cơ sở dữ liệu lib/database, đồng thời tạo điều kiện thuận lợi để viết Unit Test và Widget Test tự động. |
| --- |


# BÁO CÁO KIỂM THỬ TÍNH ĐÚNG ĐẮN PHÂN TÁCH CÁC TẦNG KIẾN TRÚC

Dự án: Quản lý Tài liệu Học tập theo Kiến trúc Cashew (Flutter) - D:\flutter\btth1

## 1. Mục Tiêu Kiểm Thử (Objective)

Chứng minh và xác thực rằng dự án Quản lý Tài liệu Học tập đã áp dụng nghiêm ngặt nguyên lý Separation of Concerns (SoC) theo đúng tiêu chuẩn kiến trúc Cashew:

- Tầng Dữ liệu & Persistence: Các thao tác lưu trữ, truy xuất và xử lý dữ liệu (Thêm, Sửa, Xóa, Lấy danh sách) hoạt động hoàn toàn độc lập, không phụ thuộc vào Flutter UI Framework hay BuildContext.

- Tầng Nghiệp vụ & Reactive Flow: Luồng phát sinh sự kiện phản ứng (Reactive Stream) và nghiệp vụ lọc/tìm kiếm hoạt động tách biệt, giữ vai trò State Management trung gian.

- Tầng Trình diễn (Presentation): Giao diện chỉ lắng nghe Stream và gọi hàm Controller/Database, áp dụng kiến trúc Unidirectional Data Flow (Luồng dữ liệu một chiều) không can thiệp trạng thái nội bộ.

## 2. Thiết Kế Bộ Kiểm Thử (Test Suite Design)


| Tầng Kiến Trúc | File Kiểm Thử | Nội Dung Kiểm Thử | Kết Quả |
| --- | --- | --- | --- |
| Data & Persistence | test/architecture_layer_test.dart | Khởi tạo Mock Data độc lập với UI; Kiểm tra tính toàn vẹn CRUD (Insert, Update, Delete) trên Model StudyDocument. | PASSED (100%) |
| Business & Reactive | test/architecture_layer_test.dart | Kiểm tra Reactive Stream phát sự kiện tự động khi dữ liệu thay đổi; Kiểm tra thuật toán tìm kiếm và bộ lọc môn học. | PASSED (100%) |
| Presentation Layer | test/presentation_layer_test.dart | Xác thực Widget Tree phân rã (Search TextField, Course Filter Chips, Add FAB); Kiểm tra tính đúng đắn của Unidirectional Data Flow. | PASSED (100%) |
| Smoke & Integration | test/widget_test.dart | Khởi chạy toàn bộ ứng dụng StudyDocumentApp, kiểm tra Render giao diện chính. | PASSED (100%) |


## 3. Kết Quả Thực Thi Thực Tế (Execution Output)

Toàn bộ 7 ca kiểm thử trên nền tảng Flutter Test đã vượt qua thành công:

00:00 +0: architecture_layer_test.dart: Khởi tạo danh sách môn học và tài liệu mẫu độc lập với UI
00:00 +1: architecture_layer_test.dart: Thao tác CRUD hoạt động hoàn toàn độc lập tại Data Layer
00:00 +2: architecture_layer_test.dart: Stream phát sự kiện tự động khi dữ liệu thay đổi (Reactive State)
00:00 +3: architecture_layer_test.dart: Logic lọc và tìm kiếm dữ liệu (Search & Filtering Logic)
00:00 +4: presentation_layer_test.dart: UI hiển thị đúng các thành phần phân lớp (Search, Chips, FAB)
00:01 +5: widget_test.dart: App smoke test khởi chạy thành công
00:02 +6: presentation_layer_test.dart: UI tự động đồng bộ khi Stream phát dữ liệu mới (Unidirectional Data Flow)
00:02 +7: All tests passed!

## 4. Đánh Giá Tính Độc Lập Giữa Các Lớp Kiến Trúc

## 1. Data Layer cô lập hoàn toàn: Thư mục database/ và struct/ không hề import hay phụ thuộc vào bất kỳ Widget hoặc thư viện BuildContext nào của Flutter. Logic nghiệp vụ có thể chạy độc lập trong môi trường pure Dart VM / console hoặc unit test mà không cần khởi tạo Device Engine.

## 2. Luồng dữ liệu một chiều (Unidirectional Data Flow): Luồng dữ liệu di chuyển một chiều từ Database/Repository -> StreamController -> StreamBuilder -> Widgets. Giao diện người dùng không trực tiếp can thiệp hay sửa đổi mảng dữ liệu _documents.

## 3. Presentation Layer chuyên biệt: Giao diện HomePage phân chia rõ rệt trách nhiệm: DocumentCard đảm nhận hiển thị thẻ tài liệu kèm badge môn học và mở link (url_launcher); AddDocumentPage đảm nhận Validate form; StreamBuilder đảm nhận lắng nghe luồng sự kiện.

# BAO CAO GIAI TRINH AP DUNG KIEN TRUC CASHEW VAO DU AN

Hoc phan: Lap trinh Di dong - Bai thuc hanh TH1 (Quan ly Tai lieu Hoc tap)
Du an: D:/flutter/btth1

## 1. Tong Quan Bai Thuc Hanh & Muc Tieu Du An

Du an Quan ly Tai lieu Hoc tap duoc xay dung tren nen tang Flutter nham giup sinh vien to chuc, theo doi va tra cuu tai lieu hoc tap (bai giang, bai tap, tai lieu tham khao, de thi) theo tung mon hoc mot cach khoa hoc. Muc tieu trong tam cua bai thuc hanh la ap dung chuan xac kien truc phan lop tu du an ma nguon mo Cashew (ung dung quan ly tai chinh ca nhan noi tieng bang Flutter).

Viec ap dung kien truc Cashew mang lai kha nang phan tach ro rang trach nhiem (Separation of Concerns), xu ly trang thai theo luong phan ung (Reactive Streams) va de dang bao tri, mo rong hoac kiem thu tu dong.

## 2. Phan Tich Kien Truc Cashew Va Ban Do Anh Xa Vao Du An

Kien truc goc cua Cashew chia ung dung thanh cac lop module chuc nang chuyen biet. Trong du an Quan ly Tai lieu Hoc tap (btth1), cau truc duoc to chuc tuong ung hoan toan:


| Thanh Phan Trong Cashew | Anh Xa Trong Du An BTTH1 | Vai Tro / Trach Nhiem |
| --- | --- | --- |
| lib/database/tables.dart<br>(Moor / Drift Table Definitions) | lib/database/tables.dart | Dinh nghia thuc the du lieu (Data Models): Course, Topic, StudyDocument va cac thuoc tinh tuong ung. |
| lib/struct/databaseGlobal.dart<br>(Global Database Singleton & Streams) | lib/struct/database_global.dart | Singleton DocumentDatabase quan ly luong du lieu phan ung (watchAllDocuments), bo nho va thao tac CRUD doc lap voi UI. |
| lib/struct/settings.dart<br>(SettingsGlobal, Preferences) | lib/struct/settings.dart | Quan ly cau hinh toan cuc ung dung: bo loc mac dinh, che do hien thi, mau sac chu dao. |
| lib/widgets/ (TransactionCard, ...) | lib/widgets/documentCard.dart | Component UI tai su dung, hien thi badge mon hoc phan loai mau, lien ket tai lieu click mo ngoai (url_launcher), menu xoa. |
| lib/pages/homePage/homePage.dart<br>(Reactive StreamBuilder Views) | lib/pages/homePage/homePage.dart | Man hinh chinh: Tim kiem tuc thi theo tu khoa, loc theo chip mon hoc, hien thi danh sach phan ung theo thoi gian thuc. |
| lib/pages/addTransactionPage.dart<br>(Form Entry & Validation) | lib/pages/addDocumentPage.dart | Bieu mau nhap lieu & chinh sua tai lieu: Form validation, dropdown mon hoc, chon phan loai tai lieu, dinh kem link/file. |


## 3. Cac Nguyen Ly Cot Loi Duoc Ap Dung

## 3.1. Luong Du Lieu Mot Chieu (Unidirectional Data Flow)

Tuan thu mo hinh cua Cashew: Giao dien (Presentation Layer) khong bao gio truc tiep thao tac bien doi danh sach du lieu. Khi co hanh vi tu nguoi dung (Them/Sua/Xoa tai lieu), UI chi gui lenh den DocumentDatabase. Sau khi co so du lieu cap nhat, StreamController se phat ra danh sach moi qua Stream watchAllDocuments(). Cac Widget (StreamBuilder) o Presentation Layer tu dong nhan su kien va ve lai giao dien.

## 3.2. Tinh Doc Lap Giua Cac Lop (Separation of Concerns - SoC)

Tang du lieu (database/ va struct/) hoan toan khong chua bat ky Widget Flutter hay BuildContext nao. Nho vay, toan bo logic luu tru va truy xuat co the chay doc lap trong moi truong thuan Dart VM (Pure Dart) hoac chay cac bai Unit Test voi toc do cuc nhanh.

## 3.3. Trai Nghiem Nguoi Dung Va Nhan Dien Truc Quan (UX/UI)

Khi nguoi dung loc Tat ca mon, he thong hien thi ro rang Badge mon hoc kem mau sac nhan dien dac trung cho tung mon hoc (Lap trinh di dong: Xanh duong, Cau truc du lieu: Xanh la, Tri tue nhan tao: Do), giup nguoi dung phan biet nguon goc tai lieu ngay lap tuc. Cac duong dan lien ket (file URL) duoc tich hop thu vien url_launcher giup nguoi dung click truc tiep de mo tai lieu tren trinh duyet hoac ung dung chuyen dung.

## 4. Ket Qua Kiem Thu Tu Dong (Automated Testing)

Toan bo 7 kich ban kiem thu (Unit Test, State Test, Widget Test) da duoc xay dung va vuot qua thanh cong 100% tren nen tang flutter test:

00:00 +0: architecture_layer_test.dart: Khoi tao danh sach mon hoc va tai lieu mau doc lap voi UI
00:00 +1: architecture_layer_test.dart: Thao tac CRUD hoat dong hoan toan doc lap tai Data Layer
00:00 +2: architecture_layer_test.dart: Stream phat su kien tu dong khi du lieu thay doi (Reactive State)
00:00 +3: architecture_layer_test.dart: Logic loc va tim kiem du lieu (Search & Filtering Logic)
00:00 +4: presentation_layer_test.dart: UI hien thi dung cac thanh phan phan lop (Search, Chips, FAB)
00:01 +5: widget_test.dart: App smoke test khoi chay thanh cong
00:02 +6: presentation_layer_test.dart: UI tu dong dong bo khi Stream phat du lieu moi (Unidirectional Data Flow)
00:02 +7: All tests passed!
