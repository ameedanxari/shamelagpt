//
//  NetworkMonitor.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation
import Network
import Combine

/// Monitors network connectivity status
final class NetworkMonitor: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var isConnected: Bool = true
    @Published private(set) var connectionType: ConnectionType = .unknown

    // MARK: - Connection Type

    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }

    // MARK: - Properties

    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        self.monitor = NWPathMonitor()
        self.queue = DispatchQueue(label: "com.shamelagpt.networkmonitor")
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Public Methods

    /// Starts monitoring network connectivity
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
                self.connectionType = self.determineConnectionType(path)
            }
        }

        monitor.start(queue: queue)
    }

    /// Stops monitoring network connectivity
    func stopMonitoring() {
        monitor.cancel()
    }

    // MARK: - Private Methods

    /// Determines the type of network connection
    private func determineConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }
}

// MARK: - Combine Support

extension NetworkMonitor {
    /// Publisher for connection status changes
    var isConnectedPublisher: AnyPublisher<Bool, Never> {
        $isConnected.eraseToAnyPublisher()
    }

    /// Publisher for connection type changes
    var connectionTypePublisher: AnyPublisher<ConnectionType, Never> {
        $connectionType.eraseToAnyPublisher()
    }
}

// MARK: - Convenience Properties

extension NetworkMonitor {
    /// Returns true if connected via Wi-Fi
    var isConnectedViaWiFi: Bool {
        isConnected && connectionType == .wifi
    }

    /// Returns true if connected via cellular
    var isConnectedViaCellular: Bool {
        isConnected && connectionType == .cellular
    }

    /// Returns true if connected via Ethernet
    var isConnectedViaEthernet: Bool {
        isConnected && connectionType == .ethernet
    }

    /// Human-readable connection status
    var connectionStatusDescription: String {
        guard isConnected else {
            return "No Connection"
        }

        switch connectionType {
        case .wifi:
            return "Connected via Wi-Fi"
        case .cellular:
            return "Connected via Cellular"
        case .ethernet:
            return "Connected via Ethernet"
        case .unknown:
            return "Connected"
        }
    }
}

// MARK: - Singleton Access (Optional)

extension NetworkMonitor {
    /// Shared instance for convenience
    static let shared = NetworkMonitor()
}
