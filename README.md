# WebViewSheet

A single-file SwiftUI component that presents Privacy Policy, Terms of Use, or any URL in a clean in-app web sheet — no address bar, no browser chrome, with a custom loader, offline detection, and automatic retry.

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
import SwiftUI

struct SignUpView: View {
    var body: some View {
        VStack {
            // ... your sign-up content ...

            PolicyLinkText()
            // Output: "By continuing you agree to our Privacy Policy and Terms of Use."
            // Both underlined words open the correct sheet when tapped.
        }
    }
}
```

Customise the appearance:

```swift
PolicyLinkText(
    fontSize:  13,
    textColor: .white.opacity(0.6),
    linkColor: .white
)
```

---

### Option 2 — Link row (settings / profile screen)

```swift
import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section("Legal") {
                PolicyLinksView()
                // Output: "Privacy Policy · Terms of Use"
            }
        }
    }
}
```

Customise the appearance:

```swift
PolicyLinksView(tintColor: .accentColor, fontSize: 14)
```

---

### Option 3 — Manual control from any view

Use this when you want to trigger the sheet from your own buttons or gestures.

```swift
import SwiftUI

struct MyView: View {
    @State private var shownDoc: LegalDocument? = nil

    var body: some View {
        VStack {
            Button("Privacy Policy") {
                shownDoc = .privacy
            }

            Button("Terms of Use") {
                shownDoc = .terms
            }
        }
        // Attach once anywhere in the view hierarchy
        .webViewSheet(item: $shownDoc)
    }
}
```

---

### Option 4 — Paywall / premium screen (with Restore button)

`PolicyLinksView` accepts an optional `restoreAction` closure. When provided, a **Restore** button is prepended to the row automatically. When omitted the row shows only Privacy Policy and Terms of Use — no conditional logic needed at the call site.

```swift
import SwiftUI
import StoreKit

struct PaywallView: View {
    var body: some View {
        VStack {
            // ... pricing cards, feature list, subscribe button ...

            // Restore • Privacy Policy • Terms of Use
            PolicyLinksView(
                restoreAction: {
                    Task { try? await AppStore.sync() }
                }
            )
        }
    }
}
```

Custom styling to match a dark paywall background:

```swift
PolicyLinksView(
    tintColor:     .white.opacity(0.5),
    fontSize:      12,
    restoreAction: {
        Task { try? await AppStore.sync() }
    }
)
```

**Row output with `restoreAction` provided:**
```
Restore • Privacy Policy • Terms of Use
```

**Row output without `restoreAction` (sign-up, settings — default):**
```
Privacy Policy • Terms of Use
```

> **App Store guideline note:** Apple's review guidelines require a visible "Restore Purchases" option on every paywall. Passing `restoreAction` to `PolicyLinksView` satisfies this — the button appears in the same footer row as your legal links so you don't need a separate UI element.

---

## Adding more pages

Add a new case to `LegalDocument` and provide its URL:

```swift
enum LegalDocument: String, Identifiable {
    case privacy = "Privacy Policy"
    case terms   = "Terms of Use"
    case cookies = "Cookie Policy"      // ← new

    var url: URL {
        switch self {
        case .privacy: return URL(string: "https://yourapp.com/privacy")!
        case .terms:   return URL(string: "https://yourapp.com/terms")!
        case .cookies: return URL(string: "https://yourapp.com/cookies")!
        }
    }

    var systemIcon: String {
        switch self {
        case .privacy: return "hand.raised.fill"
        case .terms:   return "doc.text.fill"
        case .cookies: return "hand.raised.slash.fill"   // ← new
        }
    }
}
```

Then trigger it the same way:

```swift
Button("Cookie Policy") { shownDoc = .cookies }
.webViewSheet(item: $shownDoc)
```

---

## Behaviour

| Situation | What happens |
|-----------|-------------|
| Page loading | Spinner + "Loading…" label shown; web view hidden until ready |
| Page loaded | Web view fades in; no address bar, no navigation controls visible |
| No internet | Offline icon shown; page reloads **automatically** when connection restores |
| Load error | Error icon + "Try Again" button; tapping reloads the page |
| Long-press on a link | URL tooltip suppressed (`allowsLinkPreview = false`) |
| Tapping an external link | Navigation blocked; user stays on the policy page |

---

## Customising fonts

By default the component uses SF Pro (system font) so it works in any project. To switch to a custom font, find the `.font(.system(...))` calls in `WebViewSheet.swift` and replace them with your own:

```swift
// Before (default — works in any project)
.font(.system(size: 17, weight: .semibold))

// After (example with a custom font)
.font(.custom("YourFont-SemiBold", size: 17))
```

---

## Requirements

- iOS 16.0+
- Swift 5.9+
- Xcode 15+
- No external dependencies

---

## License

MIT — free to use in personal and commercial projects.
