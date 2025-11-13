//
//  SafariDocumentView.swift
//  FitHub
//
//  Created by GPT-5 Codex on 11/13/25.
//

import SwiftUI
import SafariServices

struct SafariDocumentView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.dismissButtonStyle = .close
        return controller
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) { }
}

struct LegalDocumentSheetHost: View {
    let title: String
    let urlString: String
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title2.weight(.semibold))

            Text("Tap the button below if the document does not open automatically.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button {
                isPresented = true
            } label: {
                Label("Open \(title)", systemImage: "safari")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(title)
        .sheet(isPresented: $isPresented) {
            if let url = URL(string: urlString) {
                SafariDocumentView(url: url)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.yellow)
                    Text("\(title) is temporarily unavailable.")
                        .font(.headline)
                    Text("Please try again later or contact support@fithub.app if the issue persists.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
    }
}

