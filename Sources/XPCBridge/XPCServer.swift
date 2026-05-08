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
        print("XPCBridge: sendToClient called with: \(message)")
        guard let connection = connection else {
            print("XPCBridge: No client connected, message dropped: \(message)")
            return
        }
        let proxy = connection.remoteObjectProxyWithErrorHandler { error in
            print("XPCBridge: Send to client failed - \(error.localizedDescription)")
        } as? XPCBridgeClientProtocol
        
        guard let proxy = proxy else {
            print("XPCBridge: Client proxy unavailable")
            return
        }
        proxy.receive(message)
    }
}

class XPCServerListener: NSObject, NSXPCListenerDelegate {

    var onReceive: ((String) -> Void)?
    var serverImpl: XPCServerImpl?

    // Called when a new client connects
    func listener(_ listener: NSXPCListener,
                  shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        print("XPCBridge: New connection request, serverImpl exists: \(serverImpl != nil)")
        // Prevent duplicate connections
        if serverImpl != nil {
            return false
        }
        
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
