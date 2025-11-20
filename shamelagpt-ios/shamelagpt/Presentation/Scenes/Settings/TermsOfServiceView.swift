//
//  TermsOfServiceView.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                Text("Terms of Service")
                    .font(AppTheme.Typography.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.primaryText)

                Text("Last updated: November 5, 2025")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.tertiaryText)

                Divider()

                sectionContent(
                    title: "Acceptance of Terms",
                    content: """
By accessing and using ShamelaGPT, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to these terms, please do not use our service.
"""
                )

                sectionContent(
                    title: "Description of Service",
                    content: """
ShamelaGPT provides AI-powered responses to questions about Islamic knowledge, drawing from the Shamela.ws digital library. The service includes:

• AI-generated responses based on Islamic sources
• Conversation history (for registered users)
• Reference citations from Islamic texts
• Multi-language support
"""
                )

                sectionContent(
                    title: "User Responsibilities",
                    content: """
You agree to:

• Use the service lawfully and respectfully
• Not misuse or attempt to manipulate the AI
• Not share offensive or inappropriate content
• Verify important religious rulings with qualified scholars
• Understand that AI responses are for informational purposes
"""
                )

                sectionContent(
                    title: "Disclaimer",
                    content: """
ShamelaGPT provides information for educational purposes only. While we strive for accuracy:

• AI responses should not replace consultation with qualified Islamic scholars
• Users should verify important religious matters independently
• We are not responsible for decisions made based on AI responses
• References are provided for verification purposes
"""
                )

                sectionContent(
                    title: "Intellectual Property",
                    content: """
The ShamelaGPT application and its original content are owned by us and protected by international copyright laws. The underlying Islamic texts belong to their respective authors and publishers.
"""
                )

                sectionContent(
                    title: "Limitation of Liability",
                    content: """
We shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the service.
"""
                )

                sectionContent(
                    title: "Changes to Terms",
                    content: """
We reserve the right to modify these terms at any time. Continued use of the service after changes constitutes acceptance of the modified terms.
"""
                )

                sectionContent(
                    title: "Contact Information",
                    content: """
For questions about these Terms of Service, please contact:
support@shamelagpt.com
"""
                )
            }
            .padding(AppTheme.Spacing.lg)
        }
        .navigationTitle("Terms of Service")
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
        TermsOfServiceView()
    }
}
