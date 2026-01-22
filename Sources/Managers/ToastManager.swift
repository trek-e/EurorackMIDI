import Foundation
import Observation

/// Toast notification types
enum ToastType {
    case info
    case success
    case warning
    case error
}

/// Centralized toast notification state
@Observable
final class ToastManager {
    static let shared = ToastManager()

    var showToast: Bool = false
    var toastMessage: String = ""
    var toastType: ToastType = .info

    private init() {}

    /// Show a toast notification
    func show(message: String, type: ToastType) {
        self.toastMessage = message
        self.toastType = type
        self.showToast = true
    }
}
