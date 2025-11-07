import Foundation
import UserNotifications
import BackgroundTasks

class NotificationManager {
    static let shared = NotificationManager()
    
    private let backgroundTaskIdentifier = "com.arifozdemir.ekos.notification"
    private let userDefaults = UserDefaults.standard
    private let lastCheckKey = "last_notification_check"
    
    private init() {}
    
    func scheduleWork() {
        // Request notification permissions
        requestNotificationPermission()
        
        // Register background task
        registerBackgroundTask()
        
        // Schedule background app refresh
        scheduleBackgroundAppRefresh()
        
        print("✅ Notification manager scheduled")
    }
    
    func cancelWork() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundTaskIdentifier)
        print("❌ Notification work cancelled")
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("❌ Notification permission denied")
            }
            
            if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    private func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            self.handleBackgroundTask(task: task as! BGAppRefreshTask)
        }
    }
    
    private func scheduleBackgroundAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 1 * 60 * 60) // 1 hour from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Background app refresh scheduled")
        } catch {
            print("❌ Could not schedule app refresh: \(error)")
        }
    }
    
    private func handleBackgroundTask(task: BGAppRefreshTask) {
        print("🔔 Background notification task started")
        
        // Schedule the next background refresh
        scheduleBackgroundAppRefresh()
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Perform notification check
        performNotificationCheck { success in
            task.setTaskCompleted(success: success)
        }
    }
    
    private func performNotificationCheck(completion: @escaping (Bool) -> Void) {
        let currentTime = Date().timeIntervalSince1970 * 1000 // Convert to milliseconds
        let lastCheckTime = userDefaults.double(forKey: lastCheckKey)
        
        let timeDiff = currentTime - lastCheckTime
        let minutesSinceLastCheck = timeDiff / (1000 * 60)
        
        if minutesSinceLastCheck < 30 {
            print("⏰ Last check was \(Int(minutesSinceLastCheck)) minutes ago. Skipping...")
            completion(true)
            return
        }
        
        // Update last check time
        userDefaults.set(currentTime, forKey: lastCheckKey)
        
        // Here you would typically check for new events and send notifications
        // For now, we'll just complete successfully
        print("✅ Notification check completed")
        completion(true)
    }
    
    func sendLocalNotification(title: String, body: String, identifier: String = UUID().uuidString) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error sending notification: \(error.localizedDescription)")
            } else {
                print("✅ Notification sent: \(title)")
            }
        }
    }
}