// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation

// Role of this instance - client or server
public enum XPCRole {
    case client
    case server
}

public class XPCBridge {

    private let serviceName: String
    private let role: XPCRole

    private var serverListener: XPCServerListener?
    private var clientConnection: XPCClientConnection?
    private var onReceiveHandler: ((String) -> Void)?

    public init(serviceName: String, role: XPCRole) {
        self.serviceName = serviceName
        self.role = role
    }

    // Set handler for incoming messages
    public func onReceive(_ handler: @escaping (String) -> Void) {
        onReceiveHandler = handler
    }

    // Start the bridge
    public func start() {
        switch role {
        case .server:
            startServer()
        case .client:
            startClient()
        }
    }

    // Send message to the other side
    public func send(_ message: String) {
        switch role {
        case .server:
            serverListener?.serverImpl?.sendToClient(message)
        case .client:
            clientConnection?.send(message)
        }
    }

    // MARK: - Private

    private func startServer() {
        let listener = NSXPCListener(machServiceName: serviceName)
        let delegate = XPCServerListener()
        delegate.onReceive = onReceiveHandler
        listener.delegate = delegate
        listener.resume()
        serverListener = delegate
        print("XPCBridge: Server started on \(serviceName)")
        RunLoop.main.run()
    }

    private func startClient() {
        let connection = XPCClientConnection(serviceName: serviceName)
        connection.onReceive { [weak self] message in
            self?.onReceiveHandler?(message)
        }
        clientConnection = connection
        print("XPCBridge: Client connected to \(serviceName)")
    }
}
