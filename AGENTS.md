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
- `Tests/MacWindowSwitcherTests` ทดสอบพฤติกรรม AppKit ของ overlay (hit test, panel ไม่รับ key focus) test logic ใหม่ให้ใส่ใน `MacWindowSwitcherCoreTests`
<!-- macos-app:project:end -->

<!-- macos-app:standard:start v2 -->
## Stack

- Swift 6 + SwiftPM เท่านั้น ห้ามสร้าง `.xcodeproj` หรือ `.xcworkspace`
- ใช้ Swift 6 language mode (ค่าเริ่มต้นของ tools 6.x) ห้ามใส่ `swiftLanguageModes: [.v5]`
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
│   │   ├── App/           # entry point (main.swift หรือ type ที่มี @main), AppDelegate, MenuBarController, controller ระดับแอพ
│   │   ├── Views/         # SwiftUI view, NSWindow/NSPanel
│   │   └── Services/      # ส่วนที่แตะระบบ: permission, event tap, login item, private API, settings, file I/O
│   ├── MacWindowSwitcherCore/  # library target: logic ล้วน ไม่ import AppKit/SwiftUI ไม่มี side effect
│   └── MacWindowSwitcherBridge/ # (ถ้าจำเป็น) C/ObjC bridge สำหรับ private API
├── Tests/
│   ├── MacWindowSwitcherCoreTests/
│   └── MacWindowSwitcherTests/ # (ถ้าจำเป็น) test พฤติกรรม AppKit ของ target แอพ
├── Scripts/
│   ├── dev-app.sh         # build + run แบบ debug
│   └── build-app.sh       # สร้าง dist/<Display Name>.app
├── Assets/AppIcon.png     # 1024x1024
├── Docs/                  # spec, idea, init prompt
├── Vendor/                # (ถ้ามี) โค้ดภายนอกที่ vendor มา ห้ามเก็บโฟลเดอร์ว่าง
└── dist/                  # output (gitignored)
```

- ไฟล์ที่ห้ามอยู่ที่ root: `Info.plist`, `*.icns`, `build-app.sh` หรือสคริปต์อื่น (สคริปต์ทั้งหมดอยู่ใน `Scripts/`)
- ชื่อโฟลเดอร์ใช้ตามนี้ตรงตัว (`Docs` ไม่ใช่ `docs`, `Scripts` ไม่ใช่ `scripts`)
- ไฟล์ `.swift` ใน target แอพต้องอยู่ใน `App/`, `Views/` หรือ `Services/` ห้ามวางที่ root ของ target type ข้อมูลที่ต้องใช้ AppKit ให้วางไว้ข้าง service ที่ใช้มัน
- ไม่ใช้ `resources:` ใน `Package.swift` รูปและไฟล์ที่ต้องอยู่ใน bundle ให้วางใน `Assets/` แล้วให้ `build-app.sh` copy เข้า `Contents/Resources`

## คำสั่ง

| งาน | คำสั่ง |
|---|---|
| รันระหว่างพัฒนา | `Scripts/dev-app.sh` |
| test | `swift test` |
| build `.app` | `Scripts/build-app.sh [debug\|release]` → `dist/Mac Window Switcher.app` |

- `Info.plist` สร้างใน `Scripts/build-app.sh` ที่เดียว ถ้าจะแก้ version, bundle id หรือ usage description ให้แก้ที่ตัวแปรด้านบนของสคริปต์
- Bundle id ของแอพใหม่: `dev.sumetph.MacWindowSwitcher` แอพเก่าที่ใช้ id อื่นอยู่แล้วห้ามเปลี่ยน (สิทธิ์ macOS ผูกกับ bundle id) และให้ระบุ id จริงไว้ในส่วน project
- Sign ด้วย `Apple Development` เพื่อให้สิทธิ์ Accessibility/Input Monitoring ไม่หายหลัง rebuild (override ด้วย `CODE_SIGN_IDENTITY=-`)

## แนวทางเขียนโค้ด

- logic ที่ test ได้ (parser, state machine, การคำนวณ layout, model) อยู่ใน `MacWindowSwitcherCore` ส่วน side effect ทั้งหมด (UserDefaults, file I/O, คำสั่งระบบ, private API) อยู่ใน `Services/` ของ target แอพ
- โค้ดที่แตะ UI ใส่ `@MainActor`
- ถ้าแอพต้องใช้สิทธิ์ ให้รวมการเช็กและขอสิทธิ์ไว้ที่ `Services/PermissionManager.swift` ที่เดียว
- ค่า settings เก็บใน `UserDefaults` ผ่าน type เดียว (`AppSettings`) ห้ามเรียก `UserDefaults` กระจายหลายที่ (`@AppStorage` ใช้ได้ถ้า key มาจาก `AppSettings`)
- log ด้วย `os.Logger` ห้ามใช้ `print` และ `NSLog` ให้ hardcode subsystem เป็น bundle id (เพราะ `Bundle.main.bundleIdentifier` เป็น nil ตอน `swift run`) และใช้ category ตามส่วนของโค้ด ดู log ด้วย `log stream --level info --predicate 'subsystem == "<bundle id>"'`
- ข้อยกเว้นเดียวของ `print`/`fputs` คือข้อความตอน start ที่สคริปต์หรือ terminal ต้องอ่าน ให้ใส่ comment `// macos-app:allow-print <เหตุผล>` ไว้บรรทัดเดียวกัน
- ถ้าใช้ private API ให้รวมไว้ในไฟล์ `PrivateApis.swift` หรือ Bridge target พร้อม comment ว่ามาจากไหน และ fail แบบปลอดภัยถ้า symbol ไม่มี (ใช้ `dlsym` แทน `@_silgen_name` ซึ่งทำให้แอพเปิดไม่ขึ้นถ้า symbol หาย)
- ห้าม hardcode path ของเครื่อง ให้ใช้ `FileManager` หา Application Support ของแอพ
- `nonisolated(unsafe)` และ `@unchecked Sendable` ใช้ได้เมื่อมี comment อธิบายว่าทำไมปลอดภัยเท่านั้น
- ถ้าเปลี่ยนชื่อ target ห้ามเปลี่ยนชื่อโฟลเดอร์ใน Application Support, UserDefaults key และ Keychain item เดิม เพื่อไม่ให้ข้อมูลของผู้ใช้หาย

## Tests

- ใช้ Swift Testing (`import Testing`, `@Test`, `#expect`) ห้ามใช้ XCTest และทดสอบ target `MacWindowSwitcherCore` เป็นหลัก
- test พฤติกรรม AppKit ที่แยกเป็น Core ไม่ได้ (hit testing, focus ของ panel) ให้วางใน `Tests/MacWindowSwitcherTests` ส่วนโค้ดที่ต้องใช้สิทธิ์จริงไม่ต้องเขียน test
- Swift Testing รัน test แบบ parallel ถ้า test ใช้ state กลางร่วมกัน (เช่น URLProtocol stub) ให้ใช้ `@Suite(.serialized)`
- test ห้ามแตะข้อมูลจริงของผู้ใช้ (Application Support, UserDefaults domain ของแอพ, Keychain) ให้ใช้ temp dir หรือ suite แยก
- เมื่อย้าย logic เข้า Core ให้เขียน test ให้ส่วนที่ย้ายด้วย ส่วนจำนวน test เดิมห้ามลดลง

## ก่อนบอกว่างานเสร็จ

1. `swift build` และ `swift test` ผ่าน
2. ถ้าแก้ `Scripts/` หรือ `Package.swift` ต้องรัน `Scripts/build-app.sh` ผ่านด้วย
3. ไม่ต้องเปิดแอพเพื่อทดสอบ ถ้าแอพดัก input (event tap) หรือเปลี่ยนค่าระบบ ถ้าเปิดไว้ทดสอบต้องปิดด้วย PID หรือ `pkill -f "dist/Mac Window Switcher.app"` ห้ามใช้ `pkill -x` เพราะจะปิดตัวที่ผู้ใช้ติดตั้งไว้ใน `/Applications` ด้วย
4. ถ้ามีการเปลี่ยนสิทธิ์ ฟีเจอร์ หรือคำสั่ง ให้อัปเดต README และส่วน project ด้านบนของไฟล์นี้
<!-- macos-app:standard:end -->
