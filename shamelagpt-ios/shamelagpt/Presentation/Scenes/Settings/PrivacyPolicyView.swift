//
//  PrivacyPolicyView.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                Text("Privacy Policy")
                    .font(AppTheme.Typography.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.primaryText)

                Text("Last updated: November 5, 2025")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.tertiaryText)

                Divider()

                sectionContent(
                    title: "Introduction",
                    content: """
ShamelaGPT ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.
"""
                )

                sectionContent(
                    title: "Information We Collect",
                    content: """
We may collect the following types of information:

• Conversation Data: Questions you ask and responses provided
• Account Information: Email, name (if you create an account)
• Usage Data: App interactions, preferences, and settings
• Device Information: Device type, operating system, unique identifiers
"""
                )

                sectionContent(
                    title: "How We Use Your Information",
                    content: """
We use collected information to:

• Provide and improve our services
• Personalize your experience
• Process your questions and generate responses
• Maintain conversation history (if logged in)
• Analyze usage patterns to improve the app
• Communicate with you about updates and features
"""
                )

                sectionContent(
                    title: "Data Security",
                    content: """
We implement appropriate technical and organizational security measures to protect your personal information. However, no method of transmission over the internet is 100% secure.
"""
                )

                sectionContent(
                    title: "Your Rights",
                    content: """
You have the right to:

• Access your personal data
• Request correction of your data
• Request deletion of your data
• Opt-out of certain data collection
• Export your conversation history
"""
                )

                sectionContent(
                    title: "Contact Us",
                    content: """
If you have questions about this Privacy Policy, please contact us at:
support@shamelagpt.com
"""
                )
            }
            .padding(AppTheme.Spacing.lg)
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.Colors.background)
    }

    private func sectionContent(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(AppTheme.Typography.heading)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.Colors.primaryText)

            Text(content)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .lineSpacing(4)
        }
    }
}

#Preview {
    NavigationView {
        PrivacyPolicyView()
    }
}
