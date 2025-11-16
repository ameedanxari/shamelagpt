//
//  SafariView.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI
import SafariServices

/// Wrapper for SFSafariViewController to display web content in-app
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false
        configuration.barCollapsingEnabled = true

        let controller = SFSafariViewController(url: url, configuration: configuration)
        controller.preferredBarTintColor = UIColor(AppTheme.Colors.primary)
        controller.preferredControlTintColor = .white

        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - View Extension for Safari
extension View {
    func openSafari(url: URL, isPresented: Binding<Bool>) -> some View {
        self.sheet(isPresented: isPresented) {
            SafariView(url: url)
                .ignoresSafeArea()
        }
    }
}
