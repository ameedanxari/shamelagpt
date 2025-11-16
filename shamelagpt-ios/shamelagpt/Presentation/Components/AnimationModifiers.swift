//
//  AnimationModifiers.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI

// MARK: - Message Appearance Animation
struct MessageAppearanceModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Button Press Feedback
struct ButtonPressModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

// MARK: - Loading Rotation
struct LoadingRotationModifier: ViewModifier {
    @State private var isRotating = false

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    isRotating = true
                }
            }
    }
}

// MARK: - Pulse Animation
struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    let scale: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? scale : 1.0)
            .opacity(isPulsing ? 0.6 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - Shake Animation (for errors)
struct ShakeModifier: ViewModifier {
    let animatableData: CGFloat

    func body(content: Content) -> some View {
        content
            .offset(x: sin(animatableData * .pi * 2) * 5)
    }
}

// MARK: - View Extensions
extension View {
    func messageAppearance(delay: Double = 0) -> some View {
        modifier(MessageAppearanceModifier(delay: delay))
    }

    func buttonPress() -> some View {
        modifier(ButtonPressModifier())
    }

    func loadingRotation() -> some View {
        modifier(LoadingRotationModifier())
    }

    func pulse(scale: CGFloat = 1.2) -> some View {
        modifier(PulseModifier(scale: scale))
    }

    func shake(trigger: Int) -> some View {
        modifier(ShakeModifier(animatableData: CGFloat(trigger)))
    }
}
