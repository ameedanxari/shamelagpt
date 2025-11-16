//
//  Extensions.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 04/11/2025.
//

import Foundation
import SwiftUI

// MARK: - Date Extensions
extension Date {
    /// Returns a relative time string (e.g., "2 hours ago")
    func relativeTimeString() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Formats date for display
    func formatted() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - String Extensions
extension String {
    /// Trims whitespace and newlines
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Checks if string is empty after trimming
    var isBlankOrEmpty: Bool {
        trimmed.isEmpty
    }

    /// Truncates string to specified length with ellipsis
    func truncated(to length: Int, trailing: String = "...") -> String {
        if count > length {
            return String(prefix(length)) + trailing
        }
        return self
    }
}

// MARK: - View Extensions
extension View {
    /// Applies corner radius to specific corners
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }

    /// Hides keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    /// Makes view adapt to keyboard appearance/disappearance
    func keyboardAdaptive() -> some View {
        modifier(KeyboardAdaptive())
    }
}

// MARK: - Keyboard Adaptive Modifier
struct KeyboardAdaptive: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            // Prevent double-insetting when SwiftUI already adjusts for the keyboard
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onAppear {
                NotificationCenter.default.addObserver(
                    forName: UIResponder.keyboardWillShowNotification,
                    object: nil,
                    queue: .main
                ) { notification in
                    guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                    let keyWindow = UIApplication.shared.connectedScenes
                        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                        .first
                    let safeBottom = keyWindow?.safeAreaInsets.bottom ?? 0
                    let tabBarHeight: CGFloat = 0
                    AppLogger.ui.logInfo("Keyboard will show: frame=\(keyboardFrame), height=\(keyboardFrame.height), safeBottom=\(safeBottom), tabBarHeight=\(tabBarHeight), previousPadding=\(keyboardHeight)")

                    withAnimation(.easeOut(duration: 0.25)) {
                        // Subtract safe-area (tab bar sits behind keyboard) to avoid extra gap
                        keyboardHeight = keyboardFrame.height - safeBottom - tabBarHeight
                    }
                }

                NotificationCenter.default.addObserver(
                    forName: UIResponder.keyboardWillHideNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    AppLogger.ui.logInfo("Keyboard will hide: previousPadding=\(keyboardHeight)")
                    withAnimation(.easeOut(duration: 0.25)) {
                        keyboardHeight = 0
                    }
                }
        }
    }
}

// MARK: - Bundle Extensions
extension Bundle {
    /// Returns a display-ready app version string, including build when available.
    var appVersionString: String {
        let version = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
        if let build = object(forInfoDictionaryKey: "CFBundleVersion") as? String, !build.isEmpty {
            return "\(version) (\(build))"
        }
        return version
    }
}

// MARK: - Custom Shapes
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Color Extensions
extension Color {
    // MARK: - Primary Brand Colors
    static let primaryGreen = Color(hex: "#10B981") // Emerald-500
    static let primaryLight = Color(hex: "#5CDBB3") // Emerald-400
    static let primaryDark = Color(hex: "#059669") // Emerald-600
    static let accentGold = Color(hex: "#F59E0B") // Amber-500
    
    // MARK: - Gradient Colors
    static let teal = Color(hex: "#2DD4BF") // Teal-400
    static let cyan = Color(hex: "#22D3EE") // Cyan-400
    
    // MARK: - Dark Mode Backgrounds (matching website)
    static let darkBackground = Color(hex: "#0f0f0f") // Deep black
    static let darkSurface = Color(hex: "#171717") // Charcoal
    static let darkCard = Color(hex: "#1F2937") // Gray-800
    
    // MARK: - Light Mode Backgrounds
    static let lightBackground = Color(hex: "#FAFAFA")
    static let lightSurface = Color(hex: "#F5F5F5")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
