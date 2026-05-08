//
//  XPCBridgeProtocol.swift
//
//
//  Created by Anussha on 08/05/26.
//



import Foundation

@objc public protocol XPCBridgeProtocol {
    func send(_ message: String)
}

@objc public protocol XPCBridgeClientProtocol {
    func receive(_ message: String)
}
