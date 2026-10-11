# MacWindowSwitcher

<!-- macos-app:project:start -->
## เกี่ยวกับแอพ

แอพ menu bar แทน `Cmd+Tab` ด้วย switcher ระดับหน้าต่าง แสดงเฉพาะหน้าต่างใน Space ปัจจุบันและจอที่เมาส์อยู่ แล้ว raise หน้าต่างที่เลือกเมื่อปล่อย Command

## สิทธิ์ macOS ที่ใช้

- Accessibility (global keyboard event tap และการ raise หน้าต่าง)
- Launch at Login ผ่าน `SMAppService`

## ข้อควรระวังเฉพาะแอพ

- private API ของ Space/window โหลดแบบ dynamic ใน `PrivateApis.swift` ถ้าไม่มี symbol ต้อง fallback ห้าม crash
- การกรองหน้าต่าง: กฎที่เป็น logic ล้วน (layer, invisible, bounds ผิด, helper ชั่วคราว, Space) อยู่ที่ `WindowFilterRules` ใน Core ส่วนการเช็กผ่าน AX (minimized, role/subrole) อยู่ที่ `Services/WindowCollector.swift` ให้เพิ่ม test ทุกครั้งที่แก้กฎ

**ข้อยกเว้นจากมาตรฐาน (ชั่วคราว):**

- มี test target ที่สอง `Tests/MacWindowSwitcherTests` (Swift Testing) ทดสอบพฤติกรรม AppKit ของ overlay (hit test, panel ไม่รับ key focus) ซึ่งย้ายเข้า Core ไม่ได้ test logic ใหม่ให้ใส่ใน `MacWindowSwitcherCoreTests`
<!-- macos-app:project:end -->

<!-- macos-app:standard:start v1 -->
## Stack

- Swift 6 + SwiftPM เท่านั้น ห้ามสร้าง `.xcodeproj` หรือ `.xcworkspace`
- AppKit สำหรับ app lifecycle, menu bar, window และ event tap; SwiftUI สำหรับ view ข้างใน
- เป็นแอพ menu bar (`LSUIElement = true`) เว้นแต่ส่วน "เกี่ยวกับแอพ" ระบุไว้เป็นอย่างอื่น
- ห้ามเพิ่ม dependency ภายนอกก่อนถามผู้ใช้ ถ้าต้องใช้โค้ดจากที่อื่นให้ vendor ไว้ใน `Vendor/` พร้อม license

## โครงสร้าง repo

```
MacWindowSwitcher/
├── AGENTS.md              # ไฟล์นี้ (CLAUDE.md มีแค่ @AGENTS.md)
├── README.md
├── Package.swift
├── Sources/
│   ├── MacWindowSwitcher/      # executable target: AppKit/SwiftUI
│   │   ├── App/           # main.swift, AppDelegate, MenuBarController
│   │   ├── Views/         # SwiftUI view, NSWindow/NSPanel
│   │   └── Services/      # ส่วนที่แตะระบบ: permission, event tap, login item, private API
│   ├── MacWindowSwitcherCore/  # library target: logic ล้วน ไม่ import AppKit/SwiftUI
│   └── MacWindowSwitcherBridge/ # (ถ้าจำเป็น) C/ObjC bridge สำหรับ private API
├── Tests/
│   └── MacWindowSwitcherCoreTests/
├── Scripts/
│   ├── dev-app.sh         # build + run แบบ debug
│   └── build-app.sh       # สร้าง dist/<Display Name>.app
├── Assets/AppIcon.png     # 1024x1024
├── Docs/                  # spec, idea, init prompt
├── Vendor/                # (ถ้ามี) โค้ดภายนอกที่ vendor มา
└── dist/                  # output (gitignored)
```

- ไฟล์ที่ห้ามอยู่ที่ root: `Info.plist`, `*.icns`, `build-app.sh` หรือสคริปต์อื่น (สคริปต์ทั้งหมดอยู่ใน `Scripts/`)
- ชื่อโฟลเดอร์ใช้ตามนี้ตรงตัว (`Docs` ไม่ใช่ `docs`, `Scripts` ไม่ใช่ `scripts`)
- ไม่ใช้ `resources:` ใน `Package.swift` รูปและไฟล์ที่ต้องอยู่ใน bundle ให้วางใน `Assets/` แล้วให้ `build-app.sh` copy เข้า `Contents/Resources`

## คำสั่ง

| งาน | คำสั่ง |
|---|---|
| รันระหว่างพัฒนา | `Scripts/dev-app.sh` |
| test | `swift test` |
| build `.app` | `Scripts/build-app.sh [debug\|release]` → `dist/Mac Window Switcher.app` |

- `Info.plist` สร้างใน `Scripts/build-app.sh` ที่เดียว ถ้าจะแก้ version, bundle id หรือ usage description ให้แก้ที่ตัวแปรด้านบนของสคริปต์
- Bundle id: `dev.sumetph.MacWindowSwitcher`
- Sign ด้วย `Apple Development` เพื่อให้สิทธิ์ Accessibility/Input Monitoring ไม่หายหลัง rebuild (override ด้วย `CODE_SIGN_IDENTITY=-`)

## แนวทางเขียนโค้ด

- logic ที่ test ได้ (parser, state machine, การคำนวณ layout, model) อยู่ใน `MacWindowSwitcherCore` ส่วน target แอพทำหน้าที่ต่อสายกับระบบและ UI เท่านั้น
- โค้ดที่แตะ UI ใส่ `@MainActor`
- การเช็กและขอสิทธิ์รวมไว้ที่ `Services/PermissionManager.swift` ที่เดียว
- ค่า settings เก็บใน `UserDefaults` ผ่าน type เดียว (`AppSettings`) ห้ามเรียก `UserDefaults` กระจายหลายที่
- ใช้ `os.Logger` (subsystem = bundle id) ห้ามใช้ `print`
- ถ้าใช้ private API ให้รวมไว้ในไฟล์ `PrivateApis.swift` หรือ Bridge target พร้อม comment ว่ามาจากไหน และ fail แบบปลอดภัยถ้า symbol ไม่มี
- ห้าม hardcode path ของเครื่อง ให้ใช้ `FileManager` หา Application Support ของแอพ

## Tests

- ใช้ Swift Testing (`import Testing`, `@Test`, `#expect`) และทดสอบ target `MacWindowSwitcherCore`
- โค้ดที่ต้องใช้สิทธิ์หรือ UI จริงไม่ต้องเขียน unit test แต่ให้แยก logic ออกมาเป็น Core เพื่อ test แทน

## ก่อนบอกว่างานเสร็จ

1. `swift build` และ `swift test` ผ่าน
2. ถ้าแก้ `Scripts/` หรือ `Package.swift` ต้องรัน `Scripts/build-app.sh` ผ่านด้วย
3. ปิดแอพที่รันไว้ทดสอบ (`pkill -x MacWindowSwitcher`)
4. ถ้ามีการเปลี่ยนสิทธิ์ ฟีเจอร์ หรือคำสั่ง ให้อัปเดต README และส่วน project ด้านบนของไฟล์นี้
<!-- macos-app:standard:end -->
