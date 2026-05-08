//
//  File.swift
//  
//
//  Created by Anussha on 08/05/26.
//

import Foundation

class XPCClientReceiver: NSObject, XPCBridgeClientProtocol {

    var onReceive: ((String) -> Void)?

    // Called when server sends a message to client
    func receive(_ message: String) {
        print("Client received: \(message)")
        onReceive?(message)
    }
}

class XPCClientConnection {

    private let connection: NSXPCConnection
    private let receiver = XPCClientReceiver()

    init(serviceName: String) {
        // Setup connection to server
        connection = NSXPCConnection(machServiceName: serviceName)
        connection.remoteObjectInterface = NSXPCInterface(with: XPCBridgeProtocol.self)
        connection.exportedInterface = NSXPCInterface(with: XPCBridgeClientProtocol.self)
        connection.exportedObject = receiver
        connection.resume()
    }

    // Set handler for incoming messages from server
    func onReceive(_ handler: @escaping (String) -> Void) {
        receiver.onReceive = handler
    }

    // Send message to server
    func send(_ message: String) {
        let proxy = connection.remoteObjectProxyWithErrorHandler { error in
            print("XPC Error: \(error.localizedDescription)")
        } as? XPCBridgeProtocol
        proxy?.send(message)
    }
}
