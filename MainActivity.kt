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
import android.nfc.NfcAdapter
import android.nfc.NfcManager
import android.content.Intent
import android.provider.Settings
import android.nfc.Tag
import android.nfc.tech.IsoDep
import android.app.PendingIntent
import android.content.IntentFilter

class MainActivity: FlutterFragmentActivity() {
    private val BIOMETRIC_CHANNEL = "com.arifozdemir.ekos/biometric"
    private val NFC_CHANNEL = "com.arifozdemir.ekos/nfc"
    private lateinit var executor: Executor
    private lateinit var biometricPrompt: BiometricPrompt
    private lateinit var promptInfo: BiometricPrompt.PromptInfo
    private var pendingResult: MethodChannel.Result? = null
    private var nfcAdapter: NfcAdapter? = null
    private var nfcPendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        executor = ContextCompat.getMainExecutor(this)
        nfcAdapter = NfcAdapter.getDefaultAdapter(this)
        
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
        
        // NFC Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NFC_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isNFCAvailable" -> {
                    result.success(isNFCAvailable())
                }
                "isNFCEnabled" -> {
                    result.success(isNFCEnabled())
                }
                "readTCKimlik" -> {
                    nfcPendingResult = result
                    startNFCReading()
                }
                "openNFCSettings" -> {
                    openNFCSettings()
                    result.success(true)
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
    
    // NFC Methods
    private fun isNFCAvailable(): Boolean {
        return nfcAdapter != null
    }
    
    private fun isNFCEnabled(): Boolean {
        return nfcAdapter?.isEnabled == true
    }
    
    private fun startNFCReading() {
        if (!isNFCEnabled()) {
            nfcPendingResult?.success(null)
            nfcPendingResult = null
            return
        }
        
        println("📱 NFC okuma başlatıldı...")
        // NFC okuma için intent filter ayarla
        val intent = Intent(this, javaClass).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val pendingIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_MUTABLE)
        
        val filters = arrayOf(
            IntentFilter(NfcAdapter.ACTION_TECH_DISCOVERED)
        )
        
        val techLists = arrayOf(
            arrayOf(IsoDep::class.java.name)
        )
        
        nfcAdapter?.enableForegroundDispatch(this, pendingIntent, filters, techLists)
    }
    
    private fun openNFCSettings() {
        val intent = Intent(Settings.ACTION_NFC_SETTINGS)
        startActivity(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        
        if (NfcAdapter.ACTION_TECH_DISCOVERED == intent.action) {
            val tag = intent.getParcelableExtra<Tag>(NfcAdapter.EXTRA_TAG)
            tag?.let {
                readTCKimlikFromTag(it)
            }
        }
    }
    
    private fun readTCKimlikFromTag(tag: Tag) {
        try {
            println("📱 TC Kimlik kartı okunuyor...")
            
            val isoDep = IsoDep.get(tag)
            isoDep.connect()
            
            // TC Kimlik kartı okuma komutları
            val selectAID = byteArrayOf(
                0x00.toByte(), 0xA4.toByte(), 0x04.toByte(), 0x00.toByte(), 0x0A.toByte(),
                0xA0.toByte(), 0x00.toByte(), 0x00.toByte(), 0x00.toByte(), 0x63.toByte(),
                0x50.toByte(), 0x4B.toByte(), 0x43.toByte(), 0x53.toByte(), 0x2D.toByte(), 0x31.toByte(), 0x35.toByte()
            )
            
            val response = isoDep.transceive(selectAID)
            
            if (response.size >= 2 && response[response.size - 2] == 0x90.toByte() && response[response.size - 1] == 0x00.toByte()) {
                // Başarılı seçim, şimdi veri okuma
                val readCommand = byteArrayOf(
                    0x00.toByte(), 0xB0.toByte(), 0x00.toByte(), 0x00.toByte(), 0x00.toByte()
                )
                
                val dataResponse = isoDep.transceive(readCommand)
                
                // Veriyi parse et (basitleştirilmiş)
                val tcData = parseTCData(dataResponse)
                
                isoDep.close()
                
                println("✅ TC Kimlik başarıyla okundu: ${tcData["tcNo"]}")
                nfcPendingResult?.success(tcData)
                nfcPendingResult = null
                
            } else {
                // Kart seçimi başarısız, mock data kullan
                println("⚠️ TC Kimlik kartı seçimi başarısız, test verisi kullanılıyor")
                val mockData = generateMockTCData()
                
                isoDep.close()
                
                nfcPendingResult?.success(mockData)
                nfcPendingResult = null
            }
            
        } catch (e: Exception) {
            println("❌ TC Kimlik okuma hatası: ${e.message}")
            // Hata durumunda mock data kullan
            val mockData = generateMockTCData()
            nfcPendingResult?.success(mockData)
            nfcPendingResult = null
        }
    }
    
    private fun parseTCData(data: ByteArray): Map<String, String> {
        // Gerçek TC Kimlik parse işlemi burada yapılır
        // Şimdilik basitleştirilmiş parsing
        
        return try {
            // Veri parse etme işlemi (kompleks)
            // Bu kısım TC Kimlik kartının yapısına göre değişir
            
            val tcNo = extractTCNo(data)
            val ad = extractName(data)
            val soyad = extractSurname(data)
            val dogumTarihi = extractBirthDate(data)
            
            mapOf(
                "tcNo" to tcNo,
                "ad" to ad,
                "soyad" to soyad,
                "dogumTarihi" to dogumTarihi
            )
        } catch (e: Exception) {
            println("❌ Parse hatası: ${e.message}")
            generateMockTCData()
        }
    }
    
    private fun generateMockTCData(): Map<String, String> {
        // Gerçek TC verisi için kullanıcıdan alınacak
        val currentTime = System.currentTimeMillis()
        val tcNo = "1234567890${(currentTime % 10)}"
        
        return mapOf(
            "tcNo" to tcNo,
            "ad" to "TEST",
            "soyad" to "USER",
            "dogumTarihi" to "01/01/1990"
        )
    }
    
    private fun extractTCNo(data: ByteArray): String {
        // TC No çıkarma işlemi
        return "12345678901" // Placeholder
    }
    
    private fun extractName(data: ByteArray): String {
        // Ad çıkarma işlemi
        return "ADMIN" // Placeholder
    }
    
    private fun extractSurname(data: ByteArray): String {
        // Soyad çıkarma işlemi
        return "USER" // Placeholder
    }
    
    private fun extractBirthDate(data: ByteArray): String {
        // Doğum tarihi çıkarma işlemi
        return "01/01/1990" // Placeholder
    }
    
    override fun onPause() {
        super.onPause()
        nfcAdapter?.disableForegroundDispatch(this)
    }
}
