import Foundation
import CoreMotion

/// Lightweight accelerometer-based shake detector.
/// Call `start()` and assign `onShake` to respond when a shake is detected.
final class ShakeDetector: ObservableObject {
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    private let threshold: Double = 2.7
    private let minShakeInterval: TimeInterval = 1.2
    private var lastShakeDate: Date = .distantPast

    /// Invoked on main thread when a shake is detected.
    var onShake: (() -> Void)?

    func start() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: queue) { [weak self] data, _ in
            guard let self, let accel = data?.acceleration else { return }
            let gForce = sqrt(accel.x * accel.x + accel.y * accel.y + accel.z * accel.z)
            let now = Date()
            if gForce > threshold && now.timeIntervalSince(lastShakeDate) > minShakeInterval {
                lastShakeDate = now
                DispatchQueue.main.async { [weak self] in
                    self?.onShake?()
                }
            }
        }
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
    }
}
