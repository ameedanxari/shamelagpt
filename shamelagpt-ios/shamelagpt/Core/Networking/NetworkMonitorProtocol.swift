//
//  NetworkMonitorProtocol.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation
import Combine

/// Protocol for network monitoring
protocol NetworkMonitorProtocol {
    var isConnected: Bool { get }
    var connectionType: NetworkMonitor.ConnectionType { get }
    var isConnectedPublisher: AnyPublisher<Bool, Never> { get }
    var connectionTypePublisher: AnyPublisher<NetworkMonitor.ConnectionType, Never> { get }
    
    func startMonitoring()
    func stopMonitoring()
}

/// Extension to make NetworkMonitor conform to the protocol
extension NetworkMonitor: NetworkMonitorProtocol {}
