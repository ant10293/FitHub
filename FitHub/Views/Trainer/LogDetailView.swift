//
//  LogDetailView.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/23/25.
//

import SwiftUI

struct LogDetailView: View {
    let url: URL
    @State private var text: String = ""

    var body: some View {
        ScrollView {
            Text(text)
                .font(.system(.footnote, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(url.lastPathComponent)
        .onAppear { load() }
    }

    private func load() {
        text = (try? String(contentsOf: url)) ?? "Could not read log." }
}
