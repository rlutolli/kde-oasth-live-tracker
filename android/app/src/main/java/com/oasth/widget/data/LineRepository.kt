package com.oasth.widget.data

import android.content.Context
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import java.io.InputStreamReader

class LineRepository(private val context: Context) {
    
    private val lineDescriptions: Map<String, String> by lazy {
        try {
            val inputStream = context.assets.open("lines.json")
            val reader = InputStreamReader(inputStream)
            val type = object : TypeToken<Map<String, String>>() {}.type
            Gson().fromJson<Map<String, String>>(reader, type) ?: emptyMap()
        } catch (e: Exception) {
            e.printStackTrace()
            emptyMap()
        }
    }
    
    fun getLineDescription(lineId: String): String? {
        // Try exact match first
        var desc = lineDescriptions[lineId]
        if (desc != null) return desc
        
        // Try trimming (sometimes LineID has spaces like " 1N")
        desc = lineDescriptions[lineId.trim()]
        if (desc != null) return desc
        
        // Try adding space padding if missing (sometimes "1N" vs " 1N")
        return lineDescriptions[" $lineId"]
    }
}
