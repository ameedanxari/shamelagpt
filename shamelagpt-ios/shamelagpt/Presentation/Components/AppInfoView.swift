//
//  AppInfoView.swift
//  ShamelaGPT
//
//  Lightweight reusable view for displaying app name and version.
//

import SwiftUI

struct AppInfoView: View {
    var nameFont: Font = AppTheme.Typography.title
    var versionFont: Font = AppTheme.Typography.caption
    var nameColor: Color = AppTheme.Colors.primaryText
    var versionColor: Color = AppTheme.Colors.tertiaryText
    var spacing: CGFloat = AppTheme.Spacing.xs

    var body: some View {
        VStack(spacing: spacing) {
            Text(LocalizationKeys.shamelaGPT.localizedKey)
                .font(nameFont)
                .fontWeight(.bold)
                .foregroundColor(nameColor)

            HStack(spacing: 4) {
                Text(LocalizationKeys.settingsVersion.localizedKey)
                    .font(versionFont)
                    .foregroundColor(versionColor)
                Text(Bundle.main.appVersionString)
                    .font(versionFont)
                    .foregroundColor(versionColor)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
struct AppInfoView_Previews: PreviewProvider {
    static var previews: some View {
        AppInfoView()
            .padding()
            .background(Color.black.opacity(0.05))
    }
}
#endif
