//
//  SafariDocumentView.swift
//  FitHub
//
//  Created by Anthony Cantu on 11/13/25.
//

import SwiftUI
import SafariServices

struct LegalSheetDisplay: View {    
    @State private var showSheet = false
    let document: LegalURL
    let dismiss: () -> Void

    var body: some View {
        LegalDocumentSheetHost(
            title: document.title,
            urlString: document.rawURL,
            isPresented: $showSheet
        )
        .onAppear { showSheet = true }
        .onChange(of: showSheet) { _, isPresented in
            if !isPresented { dismiss() }   // sheet closed -> pop this view
        }
    }
}

struct SafariDocumentView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.dismissButtonStyle = .close
        return controller
    }
    
    func updateUIViewController(_ controller: SFSafariViewController, context: Context) { }
}

private struct LegalDocumentSheetHost: View {
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
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(title)
        .sheet(isPresented: $isPresented) {
            if let url = URL(string: urlString) {
                SafariDocumentView(url: url)
            } else {
                EmptyState(
                    systemName: "exclamationmark.triangle.fill",
                    title: "\(title) is temporarily unavailable.",
                    subtitle: "Please try again later or contact support@fithub.app if the issue persists."
                )
            }
        }
    }
}
