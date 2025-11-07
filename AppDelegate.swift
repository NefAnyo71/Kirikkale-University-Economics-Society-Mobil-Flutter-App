import Flutter
import UIKit
import LocalAuthentication
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    private let biometricChannel = "com.arifozdemir.ekos/biometric"
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        // Schedule notification work
        NotificationManager.shared.scheduleWork()
        
        // Setup biometric channel
        setupBiometricChannel()
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func setupBiometricChannel() {
        guard let controller = window?.rootViewController as? FlutterViewController else {
            return
        }
        
        let channel = FlutterMethodChannel(name: biometricChannel, binaryMessenger: controller.binaryMessenger)
        
        channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "isBiometricAvailable":
                result(self?.isBiometricAvailable() ?? false)
            case "authenticateWithBiometric":
                self?.authenticateWithBiometric(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    private func isBiometricAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        
        let result = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        print("🔍 Biometric check result: \(result)")
        
        if let error = error {
            print("❌ Biometric error: \(error.localizedDescription)")
            return false
        }
        
        if result {
            print("✅ Biometric available")
        } else {
            print("❌ Biometric not available")
        }
        
        return result
    }
    
    private func authenticateWithBiometric(result: @escaping FlutterResult) {
        print("🔐 Starting biometric authentication...")
        
        let context = LAContext()
        let reason = "Yönetici Paneli Girişi - Parmak izi veya Face ID ile giriş yapın"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ Biometric authentication succeeded")
                    result(true)
                } else {
                    if let error = error {
                        print("❌ Biometric error: \(error.localizedDescription)")
                    } else {
                        print("❌ Biometric authentication failed")
                    }
                    result(false)
                }
            }
        }
    }
}
