//
//  DeviceFingerprintManager.swift
//  FitHub
//
//  Retrieves the browser device fingerprint via WKWebView
//

import Foundation
import WebKit
import UIKit

@MainActor
final class DeviceFingerprintManager {
    static let shared = DeviceFingerprintManager()

    private var activeWebView: WKWebView?
    private var activeHandler: FingerprintMessageHandler?

    private init() {}

    /// Retrieves the device fingerprint by loading the landing page in WKWebView
    /// This ensures we get the same fingerprint that Safari uses
    func getBrowserFingerprint() async -> String? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let config = WKWebViewConfiguration()
                config.websiteDataStore = .default() // Use default store to share cookies with Safari

                // Create handler to receive fingerprint from JavaScript
                let handler = FingerprintMessageHandler { [weak self] fingerprint in
                    self?.activeWebView?.configuration.userContentController.removeScriptMessageHandler(forName: "fingerprintHandler")
                    self?.activeWebView = nil
                    self?.activeHandler = nil
                    continuation.resume(returning: fingerprint)
                }
                self.activeHandler = handler

                // Add message handler
                config.userContentController.add(handler, name: "fingerprintHandler")

                // Inject script to read or generate fingerprint
                let script = WKUserScript(
                    source: self.getFingerprintScript(),
                    injectionTime: .atDocumentEnd,
                    forMainFrameOnly: true
                )
                config.userContentController.addUserScript(script)

                // Create webview (1x1 pixel, hidden)
                let webView = WKWebView(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1), configuration: config)
                self.activeWebView = webView

                // Load landing page to access its cookies
                if let url = URL(string: "https://fithubv1-d3c91.web.app") {
                    print("📱 [DeviceFingerprintManager] Loading webpage to retrieve fingerprint cookie...")
                    let request = URLRequest(url: url)
                    webView.load(request)

                    // Timeout after 10 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        if self.activeWebView != nil {
                            print("⚠️ [DeviceFingerprintManager] Timeout waiting for fingerprint")
                            self.activeWebView?.configuration.userContentController.removeScriptMessageHandler(forName: "fingerprintHandler")
                            self.activeWebView = nil
                            self.activeHandler = nil
                            continuation.resume(returning: nil)
                        }
                    }
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func getFingerprintScript() -> String {
        return """
        (function() {
            try {
                // Get cookie helper (same as landing page)
                function getCookie(name) {
                    const nameEQ = name + "=";
                    const ca = document.cookie.split(';');
                    for (let i = 0; i < ca.length; i++) {
                        let c = ca[i];
                        while (c.charAt(0) === ' ') c = c.substring(1, c.length);
                        if (c.indexOf(nameEQ) === 0) return c.substring(nameEQ.length, c.length);
                    }
                    return null;
                }

                // Try to get existing cookie first
                let fingerprint = getCookie('deviceFingerprint');

                if (fingerprint) {
                    console.log('Found existing fingerprint cookie');
                    window.webkit.messageHandlers.fingerprintHandler.postMessage(fingerprint);
                    return;
                }

                // Generate fingerprint (exact same logic as landing page)
                console.log('Generating new fingerprint...');
                const canvas = document.createElement('canvas');
                const ctx = canvas.getContext('2d');
                ctx.textBaseline = 'top';
                ctx.font = '14px Arial';
                ctx.fillText('Device fingerprint', 2, 2);
                const canvasFingerprint = canvas.toDataURL();

                fingerprint = btoa(
                    navigator.userAgent +
                    navigator.language +
                    screen.width +
                    screen.height +
                    new Date().getTimezoneOffset() +
                    canvasFingerprint
                ).substring(0, 64);

                // Store in cookie (same domain and settings as landing page)
                const expires = new Date();
                expires.setTime(expires.getTime() + (365 * 24 * 60 * 60 * 1000));
                document.cookie = 'deviceFingerprint=' + fingerprint + ';expires=' + expires.toUTCString() + ';path=/;SameSite=Lax';

                console.log('Generated and stored fingerprint');
                window.webkit.messageHandlers.fingerprintHandler.postMessage(fingerprint);
            } catch (error) {
                console.error('Error getting fingerprint:', error);
                window.webkit.messageHandlers.fingerprintHandler.postMessage(null);
            }
        })();
        """
    }
}

private class FingerprintMessageHandler: NSObject, WKScriptMessageHandler {
    let completion: (String?) -> Void

    init(completion: @escaping (String?) -> Void) {
        self.completion = completion
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let fingerprint = message.body as? String, !fingerprint.isEmpty {
            print("✅ [DeviceFingerprintManager] Received fingerprint from JavaScript")
            completion(fingerprint)
        } else {
            print("⚠️ [DeviceFingerprintManager] Received null or empty fingerprint")
            completion(nil)
        }
    }
}
