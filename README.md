# WebViewSheet

A single-file SwiftUI component that presents Privacy Policy and Terms of Use in a clean in-app web sheet — no address bar, no browser chrome, with a custom loader, offline detection, and automatic retry.

![iOS 16+](https://img.shields.io/badge/iOS-16%2B-blue) ![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange) ![No dependencies](https://img.shields.io/badge/dependencies-none-brightgreen)

---

## Preview

| Loading | Loaded | No Internet | Error |
|---------|--------|-------------|-------|
| Spinner + label | Clean web page, no chrome | wifi.slash icon, auto-retries | Triangle icon + Try Again |

---

## Installation

Copy `WebViewSheet.swift` into your Xcode project. No package manager needed — it has zero external dependencies and works with any SwiftUI app targeting iOS 16+.

---

## Setup — configure your URLs

Open `WebViewSheet.swift` and replace the placeholder strings in the `LegalDocument` enum:

```swift
enum LegalDocument: String, Identifiable {
    case privacy = "Privacy Policy"
    case terms   = "Terms of Use"

    var url: URL {
        switch self {
        case .privacy:
            return URL(string: "ADD_YOUR_PRIVACY_POLICY_URL_HERE")!
        case .terms:
            return URL(string: "ADD_YOUR_TERMS_OF_USE_URL_HERE")!
        }
    }
}
```

That's the only change required before use.

---

## Usage

### Option 1 — Inline consent sentence (sign-up / onboarding screen)

```swift
struct SignUpView: View {
    var body: some View {
        VStack {
            // ... your sign-up content ...

            PolicyLinkText()
            // "By continuing you agree to our Privacy Policy and Terms of Use."
        }
    }
}
```

---

### Option 2 — Link row (settings / profile screen)

Without restore — shows **Privacy Policy • Terms of Use**:

```swift
struct SettingsView: View {
    var body: some View {
        PolicyLinksView()
    }
}
```

---

### Option 3 — Paywall / premium screen (with Restore button)

Pass `restoreAction` and the row automatically prepends a **Restore** button. Leave it out and the button disappears — no other change needed.

```swift
import StoreKit

struct PaywallView: View {
    var body: some View {
        VStack {
            // ... pricing cards, feature list, subscribe button ...

            PolicyLinksView(
                restoreAction: {
                    Task { try? await AppStore.sync() }
                }
            )
        }
    }
}
```

**With `restoreAction`** → `Privacy Policy • Terms of Use • Restore`

**Without `restoreAction`** → `Privacy Policy • Terms of Use`

> **App Store note:** Apple requires a visible "Restore Purchases" option on every paywall. Passing `restoreAction` satisfies this in the same footer row as your legal links.

---

### Option 4 — Manual control from any view

```swift
struct MyView: View {
    @State private var shownDoc: LegalDocument? = nil

    var body: some View {
        VStack {
            Button("Privacy Policy") { shownDoc = .privacy }
            Button("Terms of Use")   { shownDoc = .terms   }
        }
        .webViewSheet(item: $shownDoc)
    }
}
```

---

## Behaviour

| Situation | What happens |
|-----------|-------------|
| Page loading | Spinner + "Loading…" shown; web view hidden until ready |
| Page loaded | Web view fades in; no address bar, no navigation controls |
| No internet | Offline icon shown; reloads **automatically** when connection restores |
| Load error | Error icon + "Try Again" button; tapping reloads the page |
| Long-press on a link | URL tooltip suppressed |

---

## Requirements

- iOS 16.0+
- Swift 5.9+
- Xcode 15+
- No external dependencies

---

## License

MIT — free to use in personal and commercial projects.
