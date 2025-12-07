package com.oasth.widget.data

import android.annotation.SuppressLint
import android.content.Context
import android.content.SharedPreferences
import android.webkit.CookieManager
import android.webkit.WebView
import android.webkit.WebViewClient
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeout
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * Manages OASTH session via WebView for initial auth, then caches credentials.
 */
class SessionManager(private val context: Context) {
    
    companion object {
        private const val PREFS_NAME = "oasth_session"
        private const val KEY_PHP_SESSION_ID = "php_session_id"
        private const val KEY_TOKEN = "token"
        private const val KEY_CREATED_AT = "created_at"
        
        // Static token discovered through reverse-engineering
        private const val STATIC_TOKEN = "e2287129f7a2bbae422f3673c4944d703b84a1cf71e189f869de7da527d01137"
        
        private const val OASTH_URL = "https://telematics.oasth.gr/en/"
        private const val SESSION_TIMEOUT_MS = 15000L
    }
    
    private val prefs: SharedPreferences by lazy {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }
    
    /**
     * Get valid session, refreshing if needed
     */
    suspend fun getSession(): SessionData {
        val cached = getCachedSession()
        if (cached != null && cached.isValid()) {
            return cached
        }
        
        return refreshSession()
    }
    
    /**
     * Get cached session if exists
     */
    private fun getCachedSession(): SessionData? {
        val phpSessionId = prefs.getString(KEY_PHP_SESSION_ID, null) ?: return null
        val token = prefs.getString(KEY_TOKEN, null) ?: return null
        val createdAt = prefs.getLong(KEY_CREATED_AT, 0)
        
        return SessionData(phpSessionId, token, createdAt)
    }
    
    /**
     * Save session to SharedPreferences
     */
    private fun saveSession(session: SessionData) {
        prefs.edit()
            .putString(KEY_PHP_SESSION_ID, session.phpSessionId)
            .putString(KEY_TOKEN, session.token)
            .putLong(KEY_CREATED_AT, session.createdAt)
            .apply()
    }
    
    /**
     * Refresh session using WebView
     */
    @SuppressLint("SetJavaScriptEnabled")
    suspend fun refreshSession(): SessionData = withTimeout(SESSION_TIMEOUT_MS) {
        suspendCancellableCoroutine { continuation ->
            val webView = WebView(context)
            
            webView.settings.apply {
                javaScriptEnabled = true
                domStorageEnabled = true
                userAgentString = "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile"
            }
            
            webView.webViewClient = object : WebViewClient() {
                override fun onPageFinished(view: WebView?, url: String?) {
                    super.onPageFinished(view, url)
                    
                    // Wait a bit for JavaScript to execute
                    view?.postDelayed({
                        extractCredentials(view) { session ->
                            webView.destroy()
                            if (session != null) {
                                saveSession(session)
                                continuation.resume(session)
                            } else {
                                continuation.resumeWithException(
                                    Exception("Failed to extract session credentials")
                                )
                            }
                        }
                    }, 2000)
                }
            }
            
            // Clear existing cookies and load page
            CookieManager.getInstance().removeAllCookies(null)
            webView.loadUrl(OASTH_URL)
            
            continuation.invokeOnCancellation {
                webView.destroy()
            }
        }
    }
    
    /**
     * Extract token and PHPSESSID from WebView
     */
    private fun extractCredentials(webView: WebView, callback: (SessionData?) -> Unit) {
        // Extract JavaScript token
        webView.evaluateJavascript("window.token || '$STATIC_TOKEN'") { tokenResult ->
            val token = tokenResult?.trim('"') ?: STATIC_TOKEN
            
            // Get PHPSESSID from cookies
            val cookies = CookieManager.getInstance().getCookie(OASTH_URL)
            val phpSessionId = extractPhpSessionId(cookies)
            
            if (phpSessionId != null && token.isNotEmpty()) {
                callback(SessionData(
                    phpSessionId = phpSessionId,
                    token = token,
                    createdAt = System.currentTimeMillis()
                ))
            } else {
                callback(null)
            }
        }
    }
    
    /**
     * Parse PHPSESSID from cookie string
     */
    private fun extractPhpSessionId(cookies: String?): String? {
        if (cookies.isNullOrEmpty()) return null
        
        return cookies.split(";")
            .map { it.trim() }
            .find { it.startsWith("PHPSESSID=") }
            ?.substringAfter("PHPSESSID=")
    }
    
    /**
     * Clear cached session
     */
    fun clearSession() {
        prefs.edit().clear().apply()
    }
}
