# SwiftBoard

A Playbook-inspired component gallery for SwiftUI — but instead of a native
in-app screen, it serves a live, browsable **website** from inside your
running app. Register scenarios (a component + a named state), run your app,
and open the URL it prints. Once running, click "?" in the site's header for
the same walkthrough below, live.

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

If you also have [SwiftDS](https://github.com/luizmellodev/SwiftDS-package)
checked out as a sibling folder, run `swift run SwiftBoardKitDemo` instead to
see the same thing with a real, ~40-component design system already wired up.

### 2. Point it at your own components

Once you've seen it work, hook it up to code you actually care about. Pick
whichever matches what you have today:

**A. You already have an app (Xcode project or SPM executable)**

1. Add the dependency — in Xcode: *File → Add Package Dependencies…*, enter
   this repo's path/URL, add the **SwiftBoardServer** library to your app
   target. (Or in a `Package.swift`-based app: add
   `.package(path: "../SwiftBoard")` and `"SwiftBoardServer"` to your
   target's `dependencies`.)
2. Create one file, e.g. `BoardScenarios.swift`, anywhere in your app target:
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
3. Call it once at startup, behind `#if DEBUG` so nothing ships in Release —
   e.g. in your `App`'s root view:
   ```swift
   #if DEBUG
   .task {
       BoardScenarios.registerAll()
       try? await BoardServer().start()
   }
   #endif
   ```
4. Run your app as usual (⌘R). Watch the console for the printed URL, open
   it in a browser.

   > This one-file example is for getting one component on screen. Once you
   > have more than a couple, don't keep growing `BoardScenarios.swift` —
   > see "Creating a new component / state" under Reference below for a
   > pattern that scales to a whole design system.

**B. You don't have a project yet and just want to try this on its own**

```bash
mkdir MyBoard && cd MyBoard
swift package init --type executable
```

Edit the generated `Package.swift`:

```swift
dependencies: [.package(path: "../SwiftBoard")],
targets: [
    .executableTarget(
        name: "MyBoard",
        dependencies: [.product(name: "SwiftBoardServer", package: "SwiftBoard")]
    )
]
```

Replace `Sources/MyBoard/main.swift` with:

```swift
import SwiftBoardServer

SwiftBoard.shared.addScenarios(category: "Actions", component: "Button") {
    Scenario("Primary") {
        Button("Continue") {}.buttonStyle(.borderedProminent)
    }
}

try await BoardServer().start()
RunLoop.main.run() // keep the process alive
```

Then `swift run`.

Either way you end up with the same thing: some code that calls
`addScenarios`, and some code that calls `BoardServer().start()` after it.
Where those two calls physically live — your main app, a separate
design-system package, a tiny standalone executable — is entirely up to you;
SwiftBoard doesn't require a specific project layout.

> **On a real iOS device** (not needed on the Simulator or macOS):
> `BoardServer` listens on all interfaces, not just loopback, so add
> `NSLocalNetworkUsageDescription` to your app's Info.plist (any string
> explaining why, e.g. "Used to preview the design system in a browser") —
> without it, iOS may block the first connection instead of serving it.

## FAQ

**I'm starting a brand-new project and want to build my own design system
from scratch.** Create your app, add `SwiftBoardServer` as a dependency,
build your components as normal SwiftUI views, and conform each one to
`BoardScenarioProvider` right in its own file (see "Creating a new component
/ state" below). Register + start behind `#if DEBUG`. This is the most
tested path — it's exactly what `SwiftBoardDemo` in this repo does.

**I want to start from a complete, ready-made design system instead of
building one from scratch.** Depend on the `SwiftBoardKit` product instead
of `SwiftBoardServer`, and call `SwiftDSCatalogRegistrar.registerAll()` — it
registers all of SwiftDS's existing components for you, nothing to write.
To later *change* a component's actual appearance, you need your own copy
of SwiftDS (a fork) — depending on the original and registering more
scenarios on top lets you add things, not edit SwiftDS's own component code.

**Does that mean I need to add two package dependencies — SwiftBoard and
SwiftDS?** No. Declaring just `.package(path: "path/to/SwiftBoard")` and
depending on its `SwiftBoardKit` product is enough — `import SwiftDS` will
compile in your own code too, since it comes along transitively (tested:
this works even without declaring SwiftDS directly). That said, if you
intend to actually *use* SwiftDS's components in your own app code (not just
see them on the board), declare SwiftDS as your own direct dependency too —
relying on the transitive/"free ride" import is an SPM implementation detail
that would break silently if `SwiftBoardKit` ever stopped depending on
SwiftDS.

**I already have an app that doesn't use any design system — will adding
SwiftBoard break anything, error, or crash?** No — it's purely additive: one
new file plus a few lines in your app's startup code, behind `#if DEBUG`.
Nothing existing gets touched. To roll it in gradually and safely:
1. Add the `SwiftBoardServer` dependency and build. Nothing calls anything
   yet, so there's nothing to break.
2. Register one scenario wrapping a view you already have.
3. Call `BoardServer().start()` from a `.task`, behind `#if DEBUG`. Test in
   the Simulator first (sidesteps the local-network question below).
4. Confirm the printed URL shows that one component.
5. Add the rest of your real views as providers, one at a time.
6. Only once you're confident, try a physical device and add
   `NSLocalNetworkUsageDescription` (see above).

**Does this actually work on iOS, or only macOS?** The core library (and
FlyingFox, the HTTP server it uses) compiles cleanly for iOS. The two demo
*apps* bundled in this repo (`SwiftBoardDemo`, `SwiftBoardKitDemo`) are
macOS-only (they use `AppKit`/`NSWorkspace` to open a window and a browser)
— that's a limitation of the demos, not of SwiftBoard itself. `BoardGallery`
uses only cross-platform SwiftUI and works on iOS today.

## Reference

### Install

```swift
.package(url: "https://github.com/<you>/SwiftBoard", from: "0.1.0")
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
  `SwiftBoardKit`'s `SwiftDSCatalogRegistrar` does for SwiftDS's ~40 entries;
  it scales to hundreds without hand-writing a registration call per state.

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

`SwiftBoardDemo` and `SwiftBoardKitDemo` (below) are plain macOS processes
(`swift run` just runs a binary on your Mac) — fine for the website, but if
your design system targets iOS, a macOS process renders SwiftUI with macOS's
chrome (fonts, control styles), not iOS's. That's misleading for anything
that isn't purely custom-drawn.

To see `BoardGallery` — and the website's snapshots — rendered by a real
iOS Simulator instead:

```bash
Scripts/run-ios-demo.sh
```

This builds `SwiftBoardiOSDemo` (same SwiftDS registration as
`SwiftBoardKitDemo`, hosted in `BoardGallery`) for the iOS Simulator,
hand-assembles it into an installable `.app` (plain `swift run`/`swift build`
can't produce one — that packaging is normally Xcode's job, and this repo
has no `.xcodeproj`), installs it, and launches it on your currently booted
Simulator. Pass a device UDID as an argument to target a specific one. The
website it starts is also reachable at `http://127.0.0.1:8080` from your Mac
— same URL as the macOS demos, but now genuinely iOS-rendered.

### Design system starter (SwiftDS)

`SwiftBoardKit` and `SwiftBoardKitDemo` are two extra targets that already
live inside *this same* repository — not a separate package, plugin, or
feature flag. There's nothing to "activate"; you just choose which target to
build/run/depend on:

- **Just want to browse SwiftDS standalone?** `swift run SwiftBoardKitDemo`
  (in Xcode: pick "SwiftBoardKitDemo" from the scheme picker, then Run). It
  registers SwiftDS's existing component catalog (`DSComponentCatalog`, in
  the SwiftDS package) automatically.
- **Want it inside your own app instead?** Depend on the `SwiftBoardKit`
  product (not just `SwiftBoardServer`), then call
  `SwiftDSCatalogRegistrar.registerAll()` followed by `BoardServer().start()`.

> Depending on `SwiftBoardKit` pulls in SwiftDS as a transitive dependency,
> even if your app only uses a couple of its components elsewhere. If you
> don't want that, stick to `SwiftBoard`/`SwiftBoardServer` and register your
> own views instead.
