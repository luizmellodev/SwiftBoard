# SwiftBoard

A Playbook-inspired component gallery for SwiftUI — but instead of a native
in-app screen, it serves a live, browsable **website** from inside your
running app. Register scenarios (a component + a named state), run your app,
and open the URL it prints. Once running, click "?" in the site's header for
the same walkthrough below, live.

This package's **SwiftBoard** / **SwiftBoardServer** products do not use
[SwiftDS](https://github.com/luizmellodev/SwiftDS-package). For a ready-made
catalog, add the **SwiftBoardKit** product instead (it pulls SwiftDS for you).

## What you actually need

No special folder, filename, or project layout. The site is not generated from disk — it is
whatever the running app registered.

1. Add the **SwiftBoardServer** library.
2. Call `SwiftBoard.shared.addScenarios(...)` with your SwiftUI views (any file).
3. Attach `.swiftBoard { … }` to the root view, behind `#if DEBUG` — that starts
   the server and shows a live badge (green = up). Tap the badge to open the
   in-app gallery; copy the URL from the sheet and paste it in a Mac browser.
4. Open `http://127.0.0.1:8080` in a Mac browser. That website is the gallery.

The **only** SwiftBoard UI in the app is that badge. It does not replace your
root screen. `BoardServer().start()` still exists if you want the server with no badge.

Optional: pass `summary`, `parameters`, and `ScenarioDocs(snippet:)` so the board shows API
copy. Skip them and you still get the snapshots.

## Getting started

### 1. See it working (zero setup)

This repo already has a working demo — you don't need to write anything yet.

```bash
cd SwiftBoard
swift run SwiftBoardDemo
```

Wait for a small window to appear and the status text to say
`Running at http://127.0.0.1:8080` (also printed in the terminal), then click
**Open in Browser**, or open that URL yourself. That website — a sidebar of
components, click one, see its states — is the whole idea.

If you also want the SwiftDS catalog, add the **SwiftBoardKit** product and run:

```bash
swift run SwiftBoardKitDemo --package-path Examples
```

(from this repo), or `cd Examples && swift run SwiftBoardKitDemo`.

### 2. Pick your case

**1a — New app, design system from scratch**

Add **only** this package. In Xcode: *File → Add Package Dependencies…*, paste
`https://github.com/luizmellodev/SwiftBoard`, add the **SwiftBoardServer**
library to your app target. Do **not** add the **SwiftBoardKit** product.

```swift
// Package.swift
.package(url: "https://github.com/luizmellodev/SwiftBoard", from: "0.1.0")
// target dependencies: .product(name: "SwiftBoardServer", package: "SwiftBoard")
```

Create `BoardScenarios.swift` in the app target:

```swift
import SwiftBoardServer

enum BoardScenarios {
    @MainActor
    static func registerAll() {
        SwiftBoard.shared.addScenarios(category: "Actions", component: "Button") {
            Scenario("Primary") {
                Button("Continue") {}.buttonStyle(.borderedProminent)
            }
        }
    }
}
```

Call it once at startup, behind `#if DEBUG`:

```swift
#if DEBUG
.swiftBoard {
    BoardScenarios.registerAll()
}
#endif
```

Run (⌘R). A green **SwiftBoard** badge appears on the app; tap it to open the
gallery sheet. Copy the URL there and paste it in Safari/Chrome on the Mac.

For more than a couple of components, conform each type to `BoardScenarioProvider`
in its own file (see Reference) instead of growing one file. That is what
`SwiftBoardDemo` in this repo does.

**1b — New app, use SwiftDS as the default design system**

Add this package and link **SwiftBoardKit** (not only SwiftBoardServer). That
product already contains the SwiftDS registrar — you do **not** copy any file.

Xcode: *File → Add Package Dependencies…* → SwiftBoard → add **SwiftBoardKit**
to the app target. SwiftDS comes in transitively.

```swift
#if DEBUG
import SwiftBoardKit

.swiftBoard {
    SwiftBoardKit.registerAll()
}
#endif
```

Use SwiftDS views in your UI (`import SwiftDS` or `import SwiftBoardKit`, which
re-exports it). To *change* how a SwiftDS component looks, fork SwiftDS; depending
on the original only lets you register extra scenarios.

**2 — Existing app (with or without a design system)**

Same as 1a: add **SwiftBoardServer**, one new file, a few lines behind
`#if DEBUG`. Nothing existing is touched.

1. Add the dependency and build. Nothing calls it yet.
2. Register one scenario wrapping a view you already have.
3. Attach `.swiftBoard { … }` in DEBUG. Prefer Simulator first.
4. Confirm the URL shows that component.
5. Add the rest of your views as providers, one at a time.
6. On a physical iPhone, add `NSLocalNetworkUsageDescription` to Info.plist.

If that app already uses SwiftDS, add **SwiftBoardKit** and call
`SwiftBoardKit.registerAll()` plus your own `BoardScenarioProvider`s so both
share the same board.

> **On a real iOS device** (not needed on the Simulator or macOS):
> `BoardServer` listens on all interfaces, not just loopback, so add
> `NSLocalNetworkUsageDescription` to your app's Info.plist (any string
> explaining why, e.g. "Used to preview the design system in a browser") —
> without it, iOS may block the first connection instead of serving it.

## FAQ

**Does this work on iOS, or only macOS?** The libraries (and FlyingFox) compile
for iOS. `SwiftBoardDemo` / `SwiftBoardKitDemo` are macOS-only (AppKit).
`BoardGallery` is cross-platform SwiftUI and works on iOS.

**I cloned this repo and `swift build` failed looking for SwiftDS.** Core
targets (`SwiftBoard`, `SwiftBoardServer`, `SwiftBoardDemo`) do not need it.
`SwiftBoardKit` does — SPM will fetch
[SwiftDS-package](https://github.com/luizmellodev/SwiftDS-package) when resolving
this package. `swift test` does not build Kit.

## Reference

### Install

```swift
.package(url: "https://github.com/luizmellodev/SwiftBoard", from: "0.1.0")
```

Add `SwiftBoardServer` as a dependency of a debug/dev target — it re-exports
`SwiftBoard`, so `import SwiftBoardServer` is all you need.

### Registering scenarios

```swift
import SwiftBoardServer

SwiftBoard.shared.addScenarios(category: "Actions", component: "Button") {
    Scenario("Primary") {
        Button("Continue") {}.buttonStyle(.borderedProminent)
    }
    Scenario("Disabled") {
        Button("Continue") {}.buttonStyle(.borderedProminent).disabled(true)
    }
    Scenario("Loading") {
        HStack { ProgressView(); Text("Continue") }
    }
}
```

Open the printed URL: a sidebar lists every registered category/component;
selecting one shows all of its registered states as live-rendered snapshots.

The server only runs in DEBUG builds by default. To opt in for a Release
build, set the `SWIFTBOARD_ENABLE=1` environment variable.

**Documenting a component** — SwiftBoard cannot read a SwiftUI view's
initializer (no runtime reflection of `init` arguments). You attach copy
when you register. If you skip it, the site still lists the named states
and a hint to add docs:

```swift
board.addScenarios(
    category: "Actions",
    component: "Button",
    summary: "Primary tappable action.",
    parameters: [
        ScenarioParameter(name: "title", type: "String", description: "Label on the button."),
        ScenarioParameter(name: "style", type: "Style", defaultValue: ".primary")
    ]
) {
    Scenario("Primary", docs: ScenarioDocs(snippet: "DemoButton(title: \"Continue\", style: .primary)")) {
        DemoButton(title: "Continue", style: .primary)
    }
}
```

**Creating a new component / state** — call `addScenarios` again, for a new
component or one that already exists (it appends). No file-naming convention
is enforced — but don't pile every component's registration into one file as
your design system grows. Two ways to keep it manageable:

- **Co-located, one file per component (recommended default).** Conform the
  component's own type to `BoardScenarioProvider`, right in the same file as
  the component — the same way you'd add a `#Preview` block:
  ```swift
  // DemoButton.swift — the file where DemoButton is already defined
  extension DemoButton: BoardScenarioProvider {
      static func provideScenarios(into board: SwiftBoard) {
          board.addScenarios(category: "Actions", component: "Button") {
              Scenario("Primary") { DemoButton(title: "Continue", style: .primary) }
              Scenario("Disabled") { DemoButton(title: "Continue", style: .disabled) }
          }
      }
  }
  ```
  Then one line per component ties them together, wherever you call it:
  ```swift
  SwiftBoard.shared.addScenarios(from: [DemoButton.self, DemoBadge.self, DemoCard.self])
  ```
  Adding a component means adding one line to that list, not growing a
  central file. See `Sources/SwiftBoardDemo/*.swift` in this repo for a real
  example of this pattern.
- **Data-driven, from an existing catalog.** If you already have (or want) a
  structured array of "component × variant" data — like SwiftDS's
  `DSComponentCatalog` — map it once with a small loop into the data-driven
  `addScenarios(category:component:scenarios:)` overload. This is what
  `Sources/SwiftBoardKit/SwiftDSCatalogRegistrar.swift` does for SwiftDS's catalog;
  it scales to hundreds without hand-writing a registration call per state. Apps
  never copy that file — they depend on **SwiftBoardKit** and call
  `SwiftBoardKit.registerAll()`.

**Modifying an existing component** — edit the SwiftUI view code inside the
`Scenario`'s closure (or the underlying component's own source). This is
compiled Swift, not a script — there's no live-reload: stop the process,
rebuild/run again, then reload the browser.

**Removing a component** — delete or comment out its `addScenarios` call and
restart. There's no persisted registry to clean up — the board only exists
in memory for the life of the running process.

### Static export

```swift
try await StaticExporter.export(to: URL(fileURLWithPath: "./site"))
```

Produces a self-contained `index.html` + `app.css` + `app.js` + `docs.html` +
`manifest.json` + `snapshots/**/*.png` folder — deployable to any static
host, or just open `index.html` via `file://`.

### Native gallery view (no server required)

Everything above serves a *website*. If you'd rather show the same registered
scenarios **inside your own app**, natively — no HTTP server, no
`SwiftBoardServer`/FlyingFox dependency at all — use `BoardGallery`, a plain
SwiftUI `View` that lives in the base `SwiftBoard` target:

```swift
import SwiftBoard

.sheet(isPresented: $showGallery) {
    BoardGallery() // reads SwiftBoard.shared by default
}
```

It reads the exact same registry the website reads, so a single
`addScenarios` call feeds both — but here each state renders as your actual
live SwiftUI view (not a snapshot image), inside a searchable
sidebar/detail layout you can present however you like (sheet, push, a
shake-gesture debug menu, whatever fits your app). This is the piece
equivalent to Playbook's in-app `PlaybookGallery`/`PlaybookCatalog`, or to
SwiftDS's own `DSShowcaseRoot` — except generic, driven by whatever you've
registered.

### Previewing on iOS (not just macOS)

`SwiftBoardDemo` and `SwiftBoardKitDemo` are plain macOS processes
(`swift run` just runs a binary on your Mac) — fine for the website, but if
your design system targets iOS, a macOS process renders SwiftUI with macOS's
chrome (fonts, control styles), not iOS's. That's misleading for anything
that isn't purely custom-drawn.

To see `BoardGallery` — and the website's snapshots — rendered by a real
iOS Simulator instead (needs sibling SwiftDS):

```bash
Scripts/run-ios-demo.sh
```

This builds `SwiftBoardiOSDemo` from `Examples/` for the iOS Simulator,
hand-assembles it into an installable `.app` (plain `swift run`/`swift build`
can't produce one — that packaging is normally Xcode's job, and this repo
has no `.xcodeproj`), installs it, and launches it on your currently booted
Simulator. Pass a device UDID as an argument to target a specific one. The
website it starts is also reachable at `http://127.0.0.1:8080` from your Mac
— same URL as the macOS demos, but now genuinely iOS-rendered.
