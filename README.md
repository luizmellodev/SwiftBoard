# SwiftBoard

A Playbook-style gallery for SwiftUI: you **register** component states in code, then browse them as a **website** (and optionally a sheet in the app).

Nothing is scanned from disk. The board is whatever the running process registered.

> **Work in progress.** SwiftBoard is pre-1.0 and actively developed: features are still being added, and a minor release may change an API. Pin a version and check the release notes before upgrading.

| Product | Use when |
|---|---|
| **SwiftBoardServer** | You have (or will write) your own design system |
| **SwiftBoardKit** | You want [SwiftDS](https://github.com/luizmellodev/SwiftDS-package) as a ready-made system *and* its catalog on the board |

Same Swift package URL. In Xcode you only **link** the product you need. Kit pulls SwiftDS; you do not copy a registrar file.

SwiftDS is a **separate** UI library. Fork it to change how controls look. Kit only wires its catalog into SwiftBoard.

---

## Try it (this repo)

```bash
swift run SwiftBoardDemo
```

When it says `Running at http://127.0.0.1:8080`, open that URL. That site *is* the product.

SwiftDS catalog demo:

```bash
cd Examples && swift run SwiftBoardKitDemo
```

---

## Add it to an app

Requirements: iOS 17+ / macOS 14+, Xcode 15.3+ (Swift 5.10).

Xcode: *File → Add Package Dependencies…* → `https://github.com/luizmellodev/SwiftBoard` → *Up to Next Major* from `0.1.1`.

Package.swift:

```swift
.package(url: "https://github.com/luizmellodev/SwiftBoard", from: "0.1.1")
// target:
.product(name: "SwiftBoardServer", package: "SwiftBoard")
```

### Own design system

Link **SwiftBoardServer** only (not Kit).

```swift
// App.swift
WindowGroup {
    ContentView()           // your real UI — unchanged
    #if DEBUG
    .swiftBoard {
        BoardScenarios.registerAll()
    }
    #endif
}
```

On each component, a DEBUG extension (like a `#Preview`):

```swift
#if DEBUG
import SwiftBoardServer

extension AppButton: BoardScenarioProvider {
    static func provideScenarios(into board: SwiftBoard) {
        board.addScenarios(
            category: "Actions",
            component: "Button",
            summary: "Primary tappable action.",
            parameters: [ScenarioParameter(name: "title", type: "String")]
        ) {
            Scenario("Primary", docs: ScenarioDocs(snippet: "AppButton(title: \"Continue\")")) {
                AppButton(title: "Continue")
            }
            Scenario("Disabled") { AppButton(title: "Continue").disabled(true) }
        }
    }
}
#endif
```

One list of types:

```swift
#if DEBUG
import SwiftBoardServer

enum BoardScenarios {
    @MainActor
    static func registerAll() {
        SwiftBoard.shared.addScenarios(from: [AppButton.self, AppBadge.self])
    }
}
#endif
```

⌘R → green **SwiftBoard** badge → sheet (in-app gallery) or copy the URL and open it on the Mac. Stop the app and localhost dies.

Existing app: same steps, one component at a time. On a **physical iPhone**, add `NSLocalNetworkUsageDescription` to Info.plist. The copied `127.0.0.1` link only works on the device itself (or from the Simulator's host Mac); from a Mac, open `http://<iPhone-IP>:8080` instead (Settings → Wi-Fi → ⓘ shows the IP), with both on the same network.

### SwiftDS as the template

Link **SwiftBoardKit**. Do not copy any registrar.

```swift
#if DEBUG
import SwiftBoardKit

.swiftBoard {
    SwiftBoardKit.registerAll()
}
#endif
```

Use `DSButton` (etc.) in your UI. You can still register *your* types in the same `registerAll()` after `SwiftBoardKit.registerAll()`.

---

## While the app is running vs a hosted URL

**Localhost** (`http://127.0.0.1:8080`) is a live server inside the DEBUG app. Designers only see it if that process is up. Reloading the browser after a code change is not enough: rebuild/run, then reload.

**Hosted site** (Vercel, Netlify, S3, GitHub Pages) is a **static snapshot**. Running the app does **not** update Vercel. You export a folder of HTML + PNGs and **upload that folder**.

### How to publish / update the hosted board

The hosted site is a photograph of one build. New components or a new DS version do **not** appear until you export again and replace what is on the host.

1. Change the design system and registrations. Rebuild.
2. On a **Mac** (or iOS Simulator) — SwiftUI snapshots cannot be generated on Linux/Vercel — export:

   ```swift
   try await StaticExporter.export(to: URL(fileURLWithPath: "./site"))
   ```

   From this repo:

   ```bash
   SWIFTBOARD_EXPORT=./site swift run SwiftBoardDemo
   ```

3. That folder is the whole site: `index.html`, `app.css`, `app.js`, `docs.html`, `manifest.json`, `snapshots/**/*.png`. Upload **all of it**, not only the HTML.
4. Point the host at that folder (Vercel: deploy the directory, or drag-and-drop). Designers open the public URL. No app running.

To ship **0.0.2** after 0.0.1: repeat 1–4. Overwrite the previous deploy. Old PNGs are not patched in place; each export is a full new tree.

Optional: a **macOS** CI job that runs the export and deploys the folder. A Linux Vercel build cannot call `StaticExporter`.

Without a server, `.swiftBoard` still shows `BoardGallery` in the sheet. `BoardGallery` alone (product **SwiftBoard**, no FlyingFox) is the same registry as live SwiftUI, not snapshots.

---

## Registering, docs, edits

SwiftBoard does not discover views. Skip `summary` / `parameters` / `ScenarioDocs` and you still get named states and pictures.

Same category+component again **appends** states. Remove a component by deleting its registration and restarting — nothing is persisted.

Default: server is DEBUG-only. Release: `SWIFTBOARD_ENABLE=1`.

**Network exposure.** The server listens on every network interface, not only `127.0.0.1`. That is what lets a Mac open the board served by a physical iPhone, but it also means anyone on the same Wi-Fi can browse your registered components and their snippets while the app runs. Avoid running it on untrusted networks (cafés, conferences). Custom actions (`addAction`) only run for requests from the device itself; other devices get `403`.

Without `.swiftBoard`, you can still `.task { register(); try await BoardServer().start() }`.

---

## iOS chrome vs Mac demos

`swift run SwiftBoardDemo` uses **macOS** SwiftUI. For iOS-accurate snapshots:

```bash
Scripts/run-ios-demo.sh
```

(from this repo; uses the Kit demo on the Simulator). The Mac can still open `http://127.0.0.1:8080`.

---

## FAQ

**Does adding SwiftBoard change my production UI?** No. Link it, call it only in DEBUG.

**Does SPM download SwiftDS if I only wanted Server?** Resolving this package may fetch SwiftDS because Kit exists. Your app binary only includes SwiftDS if you link **SwiftBoardKit** (or SwiftDS yourself).

**Does SwiftDS import SwiftBoard?** No. Kit is the bridge.

**Can I git clone a “Kit repo”?** No. One package, two products.

**Live-reload?** No. Rebuild, run, reload the browser.
