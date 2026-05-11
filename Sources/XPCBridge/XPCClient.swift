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
        onReceive?(message)
    }
}

class XPCClientConnection {

    private let connection: NSXPCConnection
    private let receiver = XPCClientReceiver()
    private var proxy: XPCBridgeProtocol?

    init(serviceName: String) {
        connection = NSXPCConnection(machServiceName: serviceName)
        connection.remoteObjectInterface = NSXPCInterface(with: XPCBridgeProtocol.self)
        connection.exportedInterface = NSXPCInterface(with: XPCBridgeClientProtocol.self)
        connection.exportedObject = receiver
        
        connection.invalidationHandler = { [weak self] in
            print("XPCBridge: Connection invalidated")
            self?.proxy = nil
        }
        connection.interruptionHandler = { [weak self] in
            print("XPCBridge: Connection interrupted")
            self?.proxy = nil
        }
        
        connection.resume()
        proxy = connection.remoteObjectProxyWithErrorHandler { error in
            print("XPC Error: \(error.localizedDescription)")
        } as? XPCBridgeProtocol
    }

    func onReceive(_ handler: @escaping (String) -> Void) {
        receiver.onReceive = handler
    }

    func send(_ message: String) {
        if proxy == nil {
            proxy = connection.remoteObjectProxyWithErrorHandler { error in
                print("XPC Error: \(error.localizedDescription)")
            } as? XPCBridgeProtocol
        }
        proxy?.send(message)
    }
}
