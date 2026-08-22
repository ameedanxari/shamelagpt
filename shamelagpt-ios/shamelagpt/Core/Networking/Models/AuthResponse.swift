//
//  AuthResponse.swift
//  ShamelaGPT
//
//  Created by Codex on 05/12/2025.
//

import Foundation

struct AuthResponse: Codable, Equatable {
    let token: String
    let refreshToken: String
    let expiresIn: String
    let user: [String: AnyCodable]

    /// The Firebase uid inside the untyped user payload.
    ///
    /// Read from `firebaseUid` and nothing else. The payload also carries a database `id`,
    /// and falling back to it would be worse than returning nil: `GET /api/auth/me` reports
    /// identity as `UserResponse.firebaseUid`, so a fallback would let one account be filed
    /// under two different owners depending on which call resolved it first, and the cache
    /// written under one would be invisible under the other.
    ///
    /// The key is `firebase_uid` on the wire and stays that way here.
    /// `.convertFromSnakeCase` rewrites *coding* keys, which are generated from a type's
    /// properties — it does not touch the keys of a dictionary decoded as `[String: _]`,
    /// because there are no properties to match them against. Verified against the live
    /// payload, whose user object is:
    /// `id, firebase_uid, email, display_name, mode_preference, created_at, updated_at, last_login`
    ///
    /// Both spellings are read so this keeps working if the payload is ever decoded by a
    /// path that does convert, or the backend switches to camelCase.
    var firebaseUserId: String? {
        let value = (user["firebase_uid"] ?? user["firebaseUid"])?.value as? String
        guard let value, !value.isEmpty else { return nil }
        return value
    }
}

/// Type-erased codable to keep parity with dynamic user payload
struct AnyCodable: Codable, Equatable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let dictVal = try? container.decode([String: AnyCodable].self) {
            value = dictVal
        } else if let arrayVal = try? container.decode([AnyCodable].self) {
            value = arrayVal
        } else {
            value = ()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let intVal as Int:
            try container.encode(intVal)
        case let doubleVal as Double:
            try container.encode(doubleVal)
        case let boolVal as Bool:
            try container.encode(boolVal)
        case let stringVal as String:
            try container.encode(stringVal)
        case let dictVal as [String: AnyCodable]:
            try container.encode(dictVal)
        case let arrayVal as [AnyCodable]:
            try container.encode(arrayVal)
        default:
            try container.encodeNil()
        }
    }

    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case let (l as Int, r as Int):
            return l == r
        case let (l as Double, r as Double):
            return l == r
        case let (l as Bool, r as Bool):
            return l == r
        case let (l as String, r as String):
            return l == r
        case let (l as [String: AnyCodable], r as [String: AnyCodable]):
            return l == r
        case let (l as [AnyCodable], r as [AnyCodable]):
            return l == r
        default:
            return false
        }
    }
}
