//
//  File.swift
//  
//
//  Created by Anussha on 08/05/26.
//

import Foundation

class XPCServerImpl: NSObject, XPCBridgeProtocol {
    
    var onReceive: ((String) -> Void)?
    weak var connection: NSXPCConnection?

    // Called when client sends a message to server
    func send(_ message: String) {
        print("Server received: \(message)")
        onReceive?(message)
    }

    // Called when server wants to send a message to client
    func sendToClient(_ message: String) {
        let proxy = connection?.remoteObjectProxy as? XPCBridgeClientProtocol
        proxy?.receive(message)
    }
}

class XPCServerListener: NSObject, NSXPCListenerDelegate {

    var onReceive: ((String) -> Void)?
    var serverImpl: XPCServerImpl?

    // Called when a new client connects
    func listener(_ listener: NSXPCListener,
                  shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {

        // Create server implementation
        let impl = XPCServerImpl()
        impl.onReceive = onReceive
        impl.connection = connection

        // Setup connection
        connection.exportedInterface = NSXPCInterface(with: XPCBridgeProtocol.self)
        connection.exportedObject = impl
        connection.remoteObjectInterface = NSXPCInterface(with: XPCBridgeClientProtocol.self)
        connection.resume()

        serverImpl = impl
        return true
    }
}
