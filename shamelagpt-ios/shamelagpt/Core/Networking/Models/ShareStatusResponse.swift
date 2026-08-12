//
//  ShareStatusResponse.swift
//  ShamelaGPT
//
//  Models for the conversation sharing endpoints
//  (GET/PUT /api/conversations/{id}/share).
//

import Foundation

/// Server response describing whether a conversation is publicly shared.
///
/// Decoded with `.convertFromSnakeCase`, so `conversation_id`, `is_shared`
/// and `share_url` map onto these camelCase properties automatically.
struct ShareStatusResponse: Codable, Equatable {
    let conversationId: String
    let isShared: Bool
    let shareUrl: String?
}

/// Body for `PUT /api/conversations/{id}/share`.
///
/// Encoded with `.convertToSnakeCase`, producing `{"is_shared": true}`.
struct ShareConversationRequest: Codable, Equatable {
    let isShared: Bool
}

/// Builds the canonical public share link for a conversation.
///
/// WHY this exists: the app and the backend deploy independently, and the iOS
/// client always points at production (`APIClient.Configuration.baseURLString`)
/// with no debug override. An older backend still returns the legacy
/// path-segment form `https://shamelagpt.com/shared/<id>`, which the web SPA
/// does not route — it falls into the catch-all and silently redirects to the
/// landing page. Worse, nginx serves `index.html` for every unknown path, so
/// that dead link still answers HTTP 200 and cannot be detected by status code.
/// Normalizing client-side makes the shared link correct regardless of which
/// side ships first.
enum ShareLink {

    /// Origin used when the server gives us nothing usable to work with.
    static let productionOrigin = "https://shamelagpt.com"

    /// Normalizes a server-supplied share URL into the working query form.
    ///
    /// - Parameters:
    ///   - raw: The `share_url` returned by the backend, if any.
    ///   - conversationId: The conversation the link should point at.
    /// - Returns: A link of the shape `<origin>/shared?chatid=<id>`, or `raw`
    ///   unchanged when the backend already returned that shape.
    static func normalize(_ raw: String?, conversationId: String) -> String {
        let canonical = link(origin: productionOrigin, conversationId: conversationId)

        // 1. Nothing from the server (unshared, older build, empty string).
        guard let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return canonical
        }

        // 4. Unparseable, or missing an origin we can rebuild from.
        guard let components = URLComponents(string: trimmed),
              let scheme = components.scheme,
              let host = components.host else {
            return canonical
        }

        // 2. Backend is already up to date — trust it verbatim.
        let hasChatId = components.queryItems?.contains {
            $0.name == "chatid" && !($0.value ?? "").isEmpty
        } ?? false
        if hasChatId {
            return trimmed
        }

        // 3. Legacy path-segment form: `/shared/<id>`. Rebuild it against the
        //    origin the server gave us so staging/preview hosts keep working.
        let segments = components.path.split(separator: "/").map(String.init)
        guard segments.first?.lowercased() == "shared" else {
            return canonical
        }

        var origin = "\(scheme)://\(host)"
        if let port = components.port {
            origin += ":\(port)"
        }
        return link(origin: origin, conversationId: conversationId)
    }

    /// Assembles `<origin>/shared?chatid=<id>` with the id query-escaped.
    private static func link(origin: String, conversationId: String) -> String {
        let escaped = conversationId
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? conversationId
        return "\(origin)/shared?chatid=\(escaped)"
    }
}
