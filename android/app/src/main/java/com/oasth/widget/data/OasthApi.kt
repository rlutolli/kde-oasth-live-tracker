package com.oasth.widget.data

import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import java.util.concurrent.TimeUnit

/**
 * OASTH API client using native HTTP with session credentials
 */
class OasthApi(private val sessionManager: SessionManager) {
    
    companion object {
        private const val BASE_URL = "https://telematics.oasth.gr/api/"
    }
    
    private val client = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(10, TimeUnit.SECONDS)
        .build()
    
    private val gson = Gson()
    
    /**
     * Get arrivals for a specific stop
     */
    suspend fun getArrivals(stopCode: String): List<BusArrival> = withContext(Dispatchers.IO) {
        val session = sessionManager.getSession()
        
        val request = Request.Builder()
            .url("${BASE_URL}?act=getStopArrivals&p1=$stopCode")
            .addHeader("User-Agent", "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36")
            .addHeader("Accept", "application/json, text/javascript, */*; q=0.01")
            .addHeader("X-Requested-With", "XMLHttpRequest")
            .addHeader("X-CSRF-Token", session.token)
            .addHeader("Cookie", "PHPSESSID=${session.phpSessionId}")
            .addHeader("Origin", "https://telematics.oasth.gr")
            .addHeader("Referer", "https://telematics.oasth.gr/en/")
            .get()
            .build()
        
        val response = client.newCall(request).execute()
        
        if (response.code == 401) {
            // Session expired, refresh and retry
            sessionManager.refreshSession()
            return@withContext getArrivals(stopCode)
        }
        
        val body = response.body?.string() ?: "[]"
        
        try {
            val type = object : TypeToken<List<BusArrival>>() {}.type
            gson.fromJson<List<BusArrival>>(body, type) ?: emptyList()
        } catch (e: Exception) {
            emptyList()
        }
    }
    
    /**
     * Get all bus lines
     */
    suspend fun getLines(): List<BusLine> = withContext(Dispatchers.IO) {
        val session = sessionManager.getSession()
        
        val request = Request.Builder()
            .url("${BASE_URL}?act=webGetLines")
            .addHeader("User-Agent", "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36")
            .addHeader("Accept", "application/json, text/javascript, */*; q=0.01")
            .addHeader("X-Requested-With", "XMLHttpRequest")
            .addHeader("X-CSRF-Token", session.token)
            .addHeader("Cookie", "PHPSESSID=${session.phpSessionId}")
            .post(okhttp3.RequestBody.create(null, ByteArray(0)))
            .build()
        
        val response = client.newCall(request).execute()
        val body = response.body?.string() ?: "[]"
        
        try {
            val type = object : TypeToken<List<BusLine>>() {}.type
            gson.fromJson<List<BusLine>>(body, type) ?: emptyList()
        } catch (e: Exception) {
            emptyList()
        }
    }
}
