//
//  Notifications.swift
//  ShamelaGPT
//
//  Created by Codex on 12/07/2025.
//

import Foundation

extension Notification.Name {
    /// Posted when History requests a new chat (guest flow) so the Chat tab can present the new-chat warning.
    static let requestNewChatFromHistory = Notification.Name("requestNewChatFromHistory")
}
