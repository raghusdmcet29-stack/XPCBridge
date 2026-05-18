//
//  XPCMessage.swift
//
//
//  Created by Anussha on 18/05/26.
//

import Foundation

import Foundation

struct XPCMessage: Codable {
    let id: String          // unique ID for every message
    let payload: String     // the actual content
    let replyTo: String?    // set only on reply messages
}

extension XPCMessage {
    func encoded() throws -> String {
        let data = try JSONEncoder().encode(self)
        return String(data: data, encoding: .utf8)!
    }

    static func decoded(from string: String) throws -> XPCMessage {
        let data = Data(string.utf8)
        return try JSONDecoder().decode(XPCMessage.self, from: data)
    }
}
