# StonkWatch App

Native iOS companion to [StonkWatch](https://github.com/koalazub/stonkwatch) — an **AI-native** mobile experience for digesting stock market news, sentiment, and community discussion in seconds.

## What is this?

StonkWatch (web) gives users forums, social feeds, and sentiment analysis for stocks. **StonkWatch App** is the mobile counterpart that puts AI summarisation at the centre of the experience:

- **AI Digests** — every feed, thread, and data point is summarised on-the-fly so users never have to scroll through walls of text.
- **Social Feeds** — aggregated posts and commentary from the StonkWatch community, compressed into actionable summaries.
- **Discussion Forums** — participate in stock-specific discussions with AI-generated TLDRs for every thread.
- **Sentiment Dashboard** — our proprietary sentiment analysis pipeline, visualised and narrated by AI so users understand the *why* behind the numbers.
- **Watchlist** — follow specific tickers and get personalised, AI-corroborated briefings on what matters.

Think [Syft AI](https://syft.ai/) — hyper-personalised AI news channels — but purpose-built for the stock market and tightly integrated with our own community data.

## Requirements

| Requirement | Version |
|---|---|
| macOS | 26 beta (or 15.x+) |
| Xcode | 26 beta (or 16.x+) |
| Swift | 6.3 (auto-installed via [Swiftly](https://www.swift.org/install/macos/)) |
| iOS deployment target | 18.0+ |
| Nix | 2.18+ ([Determinate Nix](https://determinate.systems/nix/) recommended) |

## Getting started

### 1. Clone

```bash
git clone https://github.com/koalazub/stonkwatch-app.git
cd stonkwatch-app
```

### 2. Enter the dev shell

Running `nix develop` does everything automatically:

- Installs [Swiftly](https://www.swift.org/install/macos/) (Swift's official toolchain manager) if not present
- Installs Swift 6.3 via Swiftly if not present
- Provides ancillary tools: `swiftlint`, `xcbeautify`, `gh`, `jq`, `grpcurl`, etc.

```bash
nix develop
```

On first run this takes a minute or two. After that it's instant.

> **Note:** Xcode must be installed separately via the App Store. The flake handles everything else.

### 3. Open & run

```bash
open stonkwatch-app.xcodeproj
```

Or build from the command line:

```bash
xcodebuild -scheme stonkwatch-app \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build | xcbeautify
```

## Project structure

```
stonkwatch-app/
├── App/                  # @main entry point, app config
├── Features/             # Feature modules (vertical slices)
│   ├── Feed/             #   Social feed + AI digest
│   ├── Forums/           #   Discussion threads
│   ├── Sentiment/        #   Sentiment analysis views
│   ├── Watchlist/        #   Followed stocks & briefings
│   └── Settings/         #   User preferences
├── Core/                 # Shared logic
│   ├── Models/           #   SwiftData models, DTOs
│   ├── Services/         #   API client, AI summariser
│   └── Extensions/       #   Helpers & extensions
├── UI/                   # Shared UI components & theming
└── Resources/            # Assets, localisation strings
```

See [AGENT.md](./AGENT.md) for detailed architecture decisions and coding conventions.

## Development

```bash
# Format (built into Swift toolchain)
swift format format --recursive .

# Lint
swiftlint lint --strict

# Run tests
xcodebuild test -scheme stonkwatch-app \
  -destination 'platform=iOS Simulator,name=iPhone 16' | xcbeautify
```

## Tech stack

- **Swift 6.3** via [Swiftly](https://www.swift.org/install/macos/) with full concurrency checking
- **SwiftUI** + **SwiftData** for UI and persistence
- **Swift Concurrency** (async/await, actors) for all async work
- **Swift Testing** (`@Test`, `#expect`) for unit tests
- **`@Observable`** (Observation framework) for view models
- **`swift format`** for code formatting (ships with toolchain)
- **APNs** for push notifications
- **CloudKit** for cloud sync
- **Nix** for reproducible developer tooling
- No third-party HTTP libraries — `URLSession` + `Codable`

## Design philosophy

1. **AI-first, not AI-bolted-on.** Every screen asks: "how can AI make this faster to consume?" Summaries, corroboration, and synthesis are the default — not an add-on feature.
2. **Seconds, not minutes.** Users open the app to get a briefing, not to browse. Optimise for time-to-insight.
3. **Community + data.** Combine our forums, social feeds, and sentiment pipeline into a single coherent narrative per stock.
4. **Native quality.** SwiftUI-native, follows Apple HIG, feels like it belongs on iOS. No web views, no Electron, no React Native.

## Related projects

- [StonkWatch (web)](https://github.com/koalazub/stonkwatch) — the web platform with forums, social feeds, and sentiment analysis

## License

Private. All rights reserved.
