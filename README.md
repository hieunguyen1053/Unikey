<div align="center">
  <img src="Unikey/Assets.xcassets/AppIcon.appiconset/Icon-macOS-Default-128x128@1x.png" alt="Unikey Logo" width="128" height="128">
  
  # Unikey for macOS
  
  **Bộ gõ tiếng Việt mạnh mẽ và mã nguồn mở cho macOS**
  
  [![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
  [![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)](https://www.apple.com/macos)
  [![License](https://img.shields.io/badge/License-GPL--3.0-green.svg)](LICENSE)
  [![Build](https://github.com/hieunguyen1053/Unikey/actions/workflows/swift.yml/badge.svg)](https://github.com/hieunguyen1053/Unikey/actions)
</div>

---

## Giới thiệu

**Unikey for macOS** là một dự án mã nguồn mở, được xây dựng dựa trên core engine nổi tiếng của [UniKey](https://www.unikey.org/) - bộ gõ tiếng Việt được phát triển bởi **Phạm Kim Long** từ năm 2001.

Dự án này port engine gốc từ C++ sang Swift, tận dụng tối đa sức mạnh của nền tảng Apple để mang đến trải nghiệm gõ tiếng Việt mượt mà và hiệu quả trên macOS.

> **Tham khảo mã nguồn gốc:** [unikey.org/source.html](https://www.unikey.org/source.html)

## Tính năng

| Tính năng | Mô tả |
|-----------|-------|
| **Telex & VNI** | Hỗ trợ đầy đủ 2 kiểu gõ phổ biến nhất |
| **Unicode** | Hỗ trợ chuẩn Unicode, tương thích mọi ứng dụng |
| **Đặt dấu thông minh** | Đặt dấu theo chuẩn chính tả tiếng Việt |
| **Kiểm tra chính tả** | Kiểm tra chính tả cơ bản |
| **Tự động khôi phục** | Tự động khôi phục từ không hợp lệ |
| **Macro** | Hỗ trợ macro để gõ nhanh |
| **Đa ngôn ngữ** | Giao diện hỗ trợ tiếng Việt và tiếng Anh |
| **Khởi động cùng hệ thống** | Tự động chạy khi đăng nhập |
| **Menu Bar App** | Chạy gọn trong menu bar |

## Yêu cầu hệ thống

- **macOS 13.0** (Ventura) trở lên
- **Xcode 15.0** trở lên (để build từ source)
- **Swift 5.9** trở lên

## Cài đặt

### Từ Source Code

```bash
# Clone repository
git clone https://github.com/hieunguyen1053/Unikey.git
cd Unikey

# Mở project trong Xcode
open Unikey.xcodeproj

# Build và chạy (⌘R)
```

### Cấu hình Accessibility

Để Unikey hoạt động, bạn cần cấp quyền Accessibility:

1. Mở **System Settings** → **Privacy & Security** → **Accessibility**
2. Thêm **Unikey** vào danh sách và bật quyền truy cập

## Cấu trúc dự án

```
Unikey/
├── Unikey/
│   ├── Engine/           # Core engine - port từ UniKey C++
│   │   ├── UkEngine.swift
│   │   ├── VowelSequence.swift
│   │   ├── CharacterTable.swift
│   │   └── ...
│   ├── EventTapHandling/ # Xử lý keyboard events
│   ├── UI/               # SwiftUI views
│   ├── Localization/     # Hỗ trợ đa ngôn ngữ
│   └── AppDelegate.swift
├── UnikeyTests/          # Unit tests
└── .github/              # CI/CD workflows
```

## Đóng góp

Chúng tôi rất hoan nghênh mọi đóng góp từ cộng đồng! 

Xem [CONTRIBUTING.md](CONTRIBUTING.md) để biết chi tiết về:
- Cách báo cáo lỗi
- Cách đề xuất tính năng mới
- Quy trình Pull Request
- Coding standards

## Ủng hộ dự án

Nếu bạn thấy dự án hữu ích, hãy cân nhắc:
- Star repository này
- Báo cáo lỗi hoặc đề xuất tính năng
- Đóng góp code
- Ủng hộ tài chính qua GitHub Sponsors

## Giấy phép

Dự án này được phát hành dưới giấy phép [GNU General Public License v3.0](LICENSE), tuân thủ giấy phép của mã nguồn UniKey gốc.

---

<div align="center">

## Lời cảm ơn

Xin gửi lời cảm ơn đặc biệt đến **Phạm Kim Long** - người đã tạo ra và mở mã nguồn UniKey engine, giúp hàng triệu người Việt Nam có thể gõ tiếng Việt trên máy tính.

---

**Made in Vietnam**

</div>
