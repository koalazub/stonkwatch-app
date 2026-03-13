# AGENT.md — StonkWatch App

Guidelines for AI coding agents (Claude Code, Cursor, Copilot, etc.) working in this repository.

## Project overview

StonkWatch App is a native iOS companion to the [StonkWatch](https://github.com/koalazub/stonkwatch) web platform. Its core differentiator is **AI-first information delivery**: instead of a traditional forum/feed experience, every surface summarises, corroborates, and distils content so users can digest stock-relevant news in seconds.

Think of it as a vertically-integrated, finance-focused version of [Syft AI](https://syft.ai/) — hyper-personalised AI news digests — but tightly coupled to our own discussion forums, social feeds, and proprietary sentiment analysis pipeline.

## Tech stack

| Layer | Technology |
|---|---|
| Language | Swift 6.3 (installed via [Swiftly](https://www.swift.org/install/macos/)) |
| UI framework | SwiftUI |
| Persistence | SwiftData |
| Async | Swift Concurrency (async/await, actors) |
| Networking | URLSession + Codable (no Alamofire) |
| Testing | Swift Testing framework (`import Testing`, `@Test`, `#expect`) |
| Push notifications | APNs (entitlement already configured) |
| Cloud sync | CloudKit (entitlement already configured) |
| Toolchain manager | [Swiftly](https://www.swift.org/install/macos/) (auto-installed by `nix develop`) |
| Formatting | `swift format` (bundled with Swift toolchain) |
| Linting | SwiftLint (via Nix) |
| Dev environment | Nix flake (`nix develop`) — bootstraps Swiftly + Swift automatically |
| IDE | Xcode (required for builds & signing) |
| Min deployment | iOS 18.0 |

## Architecture

Follow a clean, layered architecture:

```
stonkwatch-app/
├── App/                  # @main entry, app-level config
├── Features/             # Feature modules (vertical slices)
│   ├── Feed/             #   Social feed + AI digest
│   ├── Forums/           #   Discussion forums
│   ├── Sentiment/        #   Sentiment analysis views
│   ├── Watchlist/        #   User's followed stocks
│   └── Settings/         #   Preferences, account
├── Core/                 # Shared domain logic
│   ├── Models/           #   SwiftData models, DTOs
│   ├── Services/         #   API client, AI summariser, auth
│   └── Extensions/       #   Swift/SwiftUI extensions
├── UI/                   # Shared UI components
│   ├── Components/       #   Reusable views (cards, badges)
│   └── Theme/            #   Colours, typography, spacing
└── Resources/            # Assets, localisation
```

Each Feature module should contain its own Views, ViewModels, and any feature-specific models. Prefer vertical slices over horizontal layers.

## Coding conventions

### Swift style

- Format with `swift format` (ships with the Swift toolchain via Swiftly — no third-party formatter needed).
- Lint with `swiftlint` (provided via `nix develop`).
- Prefer value types (`struct`, `enum`) over classes unless reference semantics are needed (SwiftData `@Model` classes are the exception).
- Mark all types and properties with the narrowest access control possible (`private`, `internal`). Only use `public` for module boundaries.
- Use `async/await` and structured concurrency. Do not use Combine for new code.
- Prefer `@Observable` (Observation framework) over `ObservableObject` for view models. `@Observable` is the modern replacement — do not use `@Published`, `@StateObject`, or `@ObservedObject` in new code.

### Naming

- Types: `UpperCamelCase`
- Properties, functions, parameters: `lowerCamelCase`
- Feature directories match the feature name exactly: `Feed/`, `Sentiment/`, etc.
- View files: `<Name>View.swift` (e.g., `FeedView.swift`)
- ViewModel files: `<Name>ViewModel.swift`
- Model files: plain name (e.g., `Stock.swift`, `Post.swift`)

### SwiftUI

- Keep views small. Extract sub-views into separate structs when a body exceeds ~40 lines.
- Use `#Preview` macros (not the legacy `PreviewProvider` protocol).
- Always provide preview data using in-memory SwiftData containers or mock data.

### Error handling

- Prefer typed errors (`enum AppError: Error`) over raw strings.
- Surface errors to the user via `.alert` modifiers — never silently swallow them.

### Testing

Use the **Swift Testing** framework (`import Testing`), not XCTest, for all new tests.

- Unit tests live in `stonkwatch-appTests/`.
- UI tests live in `stonkwatch-appUITests/`.
- Use `@Test` to declare test functions, `@Suite` for grouping.
- Use `#expect(...)` and `#require(...)` for assertions — not `XCTAssert*`.
- Use parameterised tests (`@Test(arguments:)`) instead of writing repetitive test cases.
- Use traits like `@Test(.tags(.network))` for categorisation.
- Mock network calls — never hit real APIs in tests.

```swift
import Testing

@Suite("Feed summarisation")
struct FeedSummaryTests {
    @Test("Summarises multiple posts into a single digest")
    func summarisesMultiplePosts() async throws {
        let posts = [Post.mock(), Post.mock()]
        let digest = try await Summariser.digest(posts)
        #expect(!digest.text.isEmpty)
        #expect(digest.sourceCount == 2)
    }
}
```

## Build & run

```bash
# Enter dev shell — auto-installs Swiftly + Swift 6.3 on first run, plus swiftlint, xcbeautify, etc.
nix develop

# Build from command line
xcodebuild -scheme stonkwatch-app -destination 'platform=iOS Simulator,name=iPhone 16' build | xcbeautify

# Run tests
xcodebuild test -scheme stonkwatch-app -destination 'platform=iOS Simulator,name=iPhone 16' | xcbeautify

# Lint
swiftlint lint --strict

# Format (uses the toolchain's built-in swift-format)
swift format format --recursive .
```

Or open `stonkwatch-app.xcodeproj` in Xcode and hit Cmd+R.

## Key decisions log

| Decision | Rationale |
|---|---|
| SwiftData over Core Data | Modern API, tighter SwiftUI integration, less boilerplate |
| No third-party HTTP lib | URLSession + Codable is sufficient; reduces dependency surface |
| Swiftly for Swift toolchain | Official Swift toolchain manager; nixpkgs doesn't ship Swift 6.x yet |
| `swift format` over swiftformat | Ships with the toolchain — zero extra deps, always version-matched |
| Swift Testing over XCTest | First-class parameterised tests, traits, better diagnostics, the future of Swift testing |
| `@Observable` over ObservableObject | Simpler API, no Combine dependency, better performance, the modern standard |
| Nix + Swiftly together | Nix provides ancillary tools; Swiftly provides Swift. `nix develop` bootstraps both |
| Feature-sliced architecture | Keeps features isolated, easier to parallelise work |

## What NOT to do

- Do not add CocoaPods or Carthage. Use Swift Package Manager if a dependency is truly needed.
- Do not use UIKit unless SwiftUI has a genuine gap (e.g., certain camera APIs). Wrap it in `UIViewRepresentable`.
- Do not commit `.xcuserstate` or other Xcode user data. These should be gitignored.
- Do not store API keys or secrets in source code. Use Xcode build configurations or environment variables.
- Do not create massive "God" view models. One view model per feature screen, keep them focused.
- Do not use `ObservableObject`, `@Published`, `@StateObject`, or `@ObservedObject` — use `@Observable` and `@State` instead.
- Do not use `XCTest` / `XCTAssert` for new tests — use Swift Testing (`@Test`, `#expect`).
- Do not install `swiftformat` or `swift-format` separately — `swift format` is built into the toolchain.
- **CRITICAL**: Use Turso DB (successor to libSQL) for backend database — NOT libSQL client. Turso DB is non-negotiable.
- UI must implement Liquid Glass + Neumorphic hybrid theme (translucent glass materials with soft 3D neumorphic shadows)
- **Commit Messages**: All jj commits must use good prose — clear, descriptive explanations of what changed and why. Avoid terse messages like "fix bug" or "update file". Instead write "Resolve race condition in watchlist sync by serializing database access through dedicated actor".
