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
    private var onReceiveHandler: ((String, (String) -> Void) -> Void)?
    private var onClientDisconnectedHandler: (() -> Void)?
    
    private var pendingRequests: [String: CheckedContinuation<String, Error>] = [:]
    private let pendingLock = NSLock()

    public init(serviceName: String, role: XPCRole) {
        self.serviceName = serviceName
        self.role = role
    }

    // Set handler for incoming messages
    // new
    public func onReceive(_ handler: @escaping (String, (String) -> Void) -> Void) {
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
        delegate.onReceive = { [weak self] raw in
            guard let self else { return }

            if let message = try? XPCMessage.decoded(from: raw) {
                self.onReceiveHandler?(message.payload) { replyPayload in
                    if let reply = try? XPCMessage(id: UUID().uuidString,
                                                   payload: replyPayload,
                                                   replyTo: message.id).encoded() {
                        self.serverListener?.serverImpl?.sendToClient(reply)
                    }
                }
            } else {
                self.onReceiveHandler?(raw) { _ in }
            }
        }
        delegate.onClientDisconnected = onClientDisconnectedHandler
        listener.delegate = delegate
        listener.resume()
        serverListener = delegate
        print("XPCBridge: Server started on \(serviceName)")
        RunLoop.main.run()
    }
    private func startClient() {
        print("XPCBridge: startClient called")
        let connection = XPCClientConnection(serviceName: serviceName)
        connection.onReceive { [weak self] raw in
            guard let self else { return }

            // Try to decode as an envelope
            if let message = try? XPCMessage.decoded(from: raw) {
                if let replyTo = message.replyTo {
                    // This is a reply — resume the waiting continuation
                    if let continuation = self.removePending(id: replyTo) {
                        continuation.resume(returning: message.payload)
                    }
                } else {
                    // This is a regular incoming message
                    self.onReceiveHandler?(message.payload) { _ in }
                }
            } else {
                // Not an envelope — pass raw string through (backward compat)
                self.onReceiveHandler?(raw) { _ in }
            }
        }
        clientConnection = connection
        print("XPCBridge: Client connected to \(serviceName)")
    }
    

    public func onClientDisconnected(_ handler: @escaping () -> Void) {
        onClientDisconnectedHandler = handler
    }
    
    private func addPending(id: String, continuation: CheckedContinuation<String, Error>) {
        pendingLock.lock()
        pendingRequests[id] = continuation
        pendingLock.unlock()
    }
    
    @discardableResult
    private func removePending(id: String) -> CheckedContinuation<String, Error>? {
        pendingLock.lock()
        defer { pendingLock.unlock() }
        return pendingRequests.removeValue(forKey: id)
    }
    
    public func request(_ payload: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let id = UUID().uuidString
            addPending(id: id, continuation: continuation)
            
            do {
                let message = XPCMessage(id: id, payload: payload, replyTo: nil)
                let encoded = try message.encoded()
                send(encoded)
            } catch {
                removePending(id: id)
                continuation.resume(throwing: error)
            }
        }
    }
}
