package com.arifozdemir.ekos

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import androidx.work.*
import java.util.concurrent.TimeUnit

class NotificationWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    
    companion object {
        private const val TAG = "NotificationWorker"
        private const val WORK_NAME = "event_notification_work"
        private const val PREF_NAME = "notification_prefs"
        private const val LAST_CHECK_KEY = "last_notification_check"
        
        fun scheduleWork(context: Context) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .setRequiresBatteryNotLow(true)
                .build()

            val workRequest = PeriodicWorkRequestBuilder<NotificationWorker>(
                1, TimeUnit.HOURS // 1 saatte bir çalış
            )
                .setConstraints(constraints)
                .setInitialDelay(5, TimeUnit.MINUTES) // İlk çalışma 5 dakika sonra
                .build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.REPLACE,
                workRequest
            )
            
            Log.d(TAG, "✅ Notification worker scheduled (1 hour interval)")
        }
        
        fun cancelWork(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
            Log.d(TAG, "❌ Notification worker cancelled")
        }
    }

    override fun doWork(): Result {
        return try {
            Log.d(TAG, "🔔 Notification worker started")
            
            val prefs = applicationContext.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
            val currentTime = System.currentTimeMillis()
            val lastCheckTime = prefs.getLong(LAST_CHECK_KEY, 0)
            
            val timeDiff = currentTime - lastCheckTime
            val minutesSinceLastCheck = timeDiff / (1000 * 60)
            
            if (minutesSinceLastCheck < 30) {
                Log.d(TAG, "⏰ Last check was $minutesSinceLastCheck minutes ago. Skipping...")
                return Result.success()
            }
            

            prefs.edit().putLong(LAST_CHECK_KEY, currentTime).apply()

            Log.d(TAG, "✅ Notification check completed")
            
            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "❌ Notification worker failed: ${e.message}")
            Result.retry()
        }
    }
}