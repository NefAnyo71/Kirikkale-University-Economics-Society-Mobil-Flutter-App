package com.arifozdemir.ekos
import android.os.Bundle
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executor

class MainActivity: FlutterFragmentActivity() {
    private val BIOMETRIC_CHANNEL = "com.arifozdemir.ekos/biometric"
    private lateinit var executor: Executor
    private lateinit var biometricPrompt: BiometricPrompt
    private lateinit var promptInfo: BiometricPrompt.PromptInfo
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        executor = ContextCompat.getMainExecutor(this)
        
        // Bildirim worker'ını başlat
        NotificationWorker.scheduleWork(this)
        
        // Biometric Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BIOMETRIC_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isBiometricAvailable" -> {
                    result.success(isBiometricAvailable())
                }
                "authenticateWithBiometric" -> {
                    pendingResult = result
                    authenticateWithBiometric()
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun isBiometricAvailable(): Boolean {
        val biometricManager = BiometricManager.from(this)
        val result = biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK)
        
        println("🔍 Biometric check result: $result")
        
        return when (result) {
            BiometricManager.BIOMETRIC_SUCCESS -> {
                println("✅ Biometric available")
                true
            }
            BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE -> {
                println("❌ No biometric hardware")
                false
            }
            BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE -> {
                println("❌ Biometric hardware unavailable")
                false
            }
            BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> {
                println("❌ No biometric enrolled")
                false
            }
            else -> {
                println("❌ Other biometric error: $result")
                false
            }
        }
    }

    private fun authenticateWithBiometric() {
        println("🔐 Starting biometric authentication...")
        
        try {
            biometricPrompt = BiometricPrompt(this, executor,
                object : BiometricPrompt.AuthenticationCallback() {
                    override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                        super.onAuthenticationError(errorCode, errString)
                        println("❌ Biometric error: $errorCode - $errString")
                        pendingResult?.success(false)
                        pendingResult = null
                    }

                    override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                        super.onAuthenticationSucceeded(result)
                        println("✅ Biometric authentication succeeded")
                        pendingResult?.success(true)
                        pendingResult = null
                    }

                    override fun onAuthenticationFailed() {
                        super.onAuthenticationFailed()
                        println("❌ Biometric authentication failed")
                        pendingResult?.success(false)
                        pendingResult = null
                    }
                })

            promptInfo = BiometricPrompt.PromptInfo.Builder()
                .setTitle("Yönetici Paneli Girişi")
                .setSubtitle("Parmak izi veya yüz tanıma ile giriş yapın")
                .setNegativeButtonText("İptal")
                .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_WEAK)
                .build()

            println("🔐 Showing biometric prompt...")
            biometricPrompt.authenticate(promptInfo)
        } catch (e: Exception) {
            println("❌ Exception in biometric auth: ${e.message}")
            pendingResult?.success(false)
            pendingResult = null
        }
    }
}
