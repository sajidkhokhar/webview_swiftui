//
//  WebViewSheet.swift
//  MenuSmart
//
//  In-app web view sheet for Privacy Policy and Terms of Use.
//  Uses WKWebView for full UI control (hidden address bar, custom loader,
//  no-internet state, branded chrome).
//

import SwiftUI
import WebKit
import Network
import Combine
import SwiftyUIX

// MARK: - LegalDocument

enum LegalDocument: String, Identifiable {
    case privacy = "Privacy Policy"
    case terms   = "Terms of Use"

    var id: String { rawValue }

    var url: URL {
        switch self {
        case .privacy:
            return URL(string: "https://maximaapps.com/policy/privacy_policy.html")!
        case .terms:
            return URL(string: "https://maximaapps.com/policy/terms_of_use.html")!
        }
    }

    var title: String { rawValue }

    var icon: String {
        switch self {
        case .privacy: return "hand.raised.fill"
        case .terms:   return "doc.text.fill"
        }
    }
}

// MARK: - WebViewSheet (main sheet content)

struct WebViewSheet: View {

    let document: LegalDocument
    @Environment(\.dismiss) private var dismiss

    @State private var isLoading    = true
    @State private var hasError     = false
    @State private var isConnected  = true
    @StateObject private var monitor = NetworkMonitor()

    var body: some View {
        ZStack {
            Color.primary.ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack {
                    WebViewRepresentable(
                        url:       document.url,
                        isLoading: $isLoading,
                        hasError:  $hasError
                    )
                    .opacity(isLoading || hasError || !isConnected ? 0 : 1)

                    if isLoading && isConnected && !hasError { loadingView    }
                    if !isConnected                          { noInternetView }
                    if hasError && isConnected               { errorView      }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .fullFrame()
        .ignoresSafeArea()
        .onReceive(monitor.$isConnected) { connected in
            let wasDisconnected = !isConnected
            isConnected = connected
            if connected && wasDisconnected {
                hasError  = false
                isLoading = true
            }
        }
    }

    // MARK: Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.1)
                .tint(.secondary)
            Text("Loading…")
                .font(.custom("HostGrotesk-Medium", size: 14))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: No Internet View

    private var noInternetView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(.secondary)
                    .frame(width: 80, height: 80)
                Image(systemName: "wifi.slash")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            VStack(spacing: 8) {
                Text("No Internet Connection")
                    .font(.custom("HostGrotesk-SemiBold", size: 17))
                    .foregroundStyle(.primary)
                Text("Please check your connection.\nThe page will reload automatically when you're back online.")
                    .font(.custom("HostGrotesk-Regular", size: 14))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Error View

    private var errorView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(.secondary)
                    .frame(width: 80, height: 80)
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            VStack(spacing: 8) {
                Text("Couldn't Load Page")
                    .font(.custom("HostGrotesk-SemiBold", size: 17))
                    .foregroundStyle(.primary)
                Text("Something went wrong. Please try again.")
                    .font(.custom("HostGrotesk-Regular", size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button {
                hasError  = false
                isLoading = true
            } label: {
                Text("Try Again")
                    .font(.custom("HostGrotesk-SemiBold", size: 15))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 13)
                    .background(Color.black, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - WKWebView Representable

private struct WebViewRepresentable: UIViewRepresentable {

    let url:        URL
    @Binding var isLoading: Bool
    @Binding var hasError:  Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let config                   = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true

        let webView                  = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate   = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        webView.allowsLinkPreview    = false   // suppresses URL tooltip on long-press

        let script = WKUserScript(
            source: """
            var s = document.createElement('style');
            s.textContent = '::-webkit-scrollbar{display:none!important}';
            document.head.appendChild(s);
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        webView.configuration.userContentController.addUserScript(script)

        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if isLoading && !webView.isLoading {
            webView.load(URLRequest(url: url))
        }
    }

    // MARK: Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate {

        var parent: WebViewRepresentable

        init(_ parent: WebViewRepresentable) { self.parent = parent }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
            parent.isLoading = true
            parent.hasError  = false
        }

        func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
            parent.isLoading = false
            parent.hasError  = false
        }

        func webView(_ webView: WKWebView, didFail _: WKNavigation!, withError error: Error) {
            guard (error as NSError).code != NSURLErrorCancelled else { return }
            parent.isLoading = false
            parent.hasError  = true
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
            guard (error as NSError).code != NSURLErrorCancelled else { return }
            parent.isLoading = false
            parent.hasError  = true
        }

        // No decidePolicyFor — all link navigation is allowed freely.
    }
}

// MARK: - NetworkMonitor

final class NetworkMonitor: ObservableObject {
    @Published private(set) var isConnected: Bool = true

    private let monitor = NWPathMonitor()
    private let queue   = DispatchQueue(label: "NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }
}

// MARK: - View Modifier

private struct WebViewSheetModifier: ViewModifier {
    @Binding var item: LegalDocument?

    func body(content: Content) -> some View {
        content
            .sheet(item: $item) { doc in
                WebViewSheet(document: doc)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(UIScreen.main.displayCorner(minimum: 28))
                    .presentationBackground(.primary)
            }
    }
}

extension View {
    func webViewSheet(item: Binding<LegalDocument?>) -> some View {
        modifier(WebViewSheetModifier(item: item))
    }
}

// MARK: - PolicyLinksView

struct PolicyLinksView: View {

    var tintColor:     Color          = .primary
    var fontSize:      CGFloat        = 12
    var restoreAction: (() -> Void)?  = nil

    @State private var shownDoc: LegalDocument? = nil

    var body: some View {
        HStack(spacing: 4) {
            policyButton(.privacy)

            Text("•")
                .font(.system(size: fontSize))
                .foregroundStyle(tintColor.opacity(0.5))

            policyButton(.terms)

            if let restore = restoreAction {
                Text("•")
                    .font(.system(size: fontSize))
                    .foregroundStyle(tintColor.opacity(0.5))

                Button(action: restore) {
                    Text("Restore")
                        .font(.system(size: fontSize))
                        .foregroundStyle(tintColor)
                        .underline(color: tintColor.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
        }
        .webViewSheet(item: $shownDoc)
    }

    private func policyButton(_ doc: LegalDocument) -> some View {
        Button { shownDoc = doc } label: {
            Text(doc.title)
                .font(.system(size: fontSize))
                .foregroundStyle(tintColor)
                .underline(color: tintColor.opacity(0.4))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PolicyLinkText

struct PolicyLinkText: View {

    var fontSize:  CGFloat = 12
    var textColor: Color   = .primary
    var linkColor: Color   = .secondary

    @State private var shownDoc: LegalDocument? = nil

    var body: some View {
        Group {
            Text("By continuing you agree to our ")
                .foregroundStyle(textColor)
            + Text("Privacy Policy")
                .foregroundStyle(linkColor)
                .underline()
            + Text(" and ")
                .foregroundStyle(textColor)
            + Text("Terms of Use")
                .foregroundStyle(linkColor)
                .underline()
            + Text(".")
                .foregroundStyle(textColor)
        }
        .font(.custom("HostGrotesk-Regular", size: fontSize))
        .multilineTextAlignment(.center)
        .overlay(
            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { shownDoc = .privacy }
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { shownDoc = .terms }
            }
        )
        .webViewSheet(item: $shownDoc)
    }
}
