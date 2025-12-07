package com.oasth.widget.ui

import android.os.Bundle
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.oasth.widget.R
import com.oasth.widget.data.OasthApi
import com.oasth.widget.data.SessionManager
import com.oasth.widget.data.WidgetConfigRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Main app activity showing info and configured widgets
 */
class MainActivity : AppCompatActivity() {
    
    private lateinit var statusText: TextView
    private lateinit var widgetsText: TextView
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        statusText = findViewById(R.id.status_text)
        widgetsText = findViewById(R.id.widgets_text)
        
        loadStatus()
    }
    
    private fun loadStatus() {
        val configRepo = WidgetConfigRepository(this)
        val widgetIds = configRepo.getAllWidgetIds()
        
        widgetsText.text = if (widgetIds.isEmpty()) {
            getString(R.string.no_widgets_configured)
        } else {
            buildString {
                appendLine(getString(R.string.configured_widgets, widgetIds.size))
                appendLine()
                for (id in widgetIds) {
                    val config = configRepo.getConfig(id)
                    if (config != null) {
                        appendLine("• ${config.stopName} (${config.stopCode})")
                    }
                }
            }
        }
        
        // Test session
        CoroutineScope(Dispatchers.Main).launch {
            try {
                statusText.text = getString(R.string.checking_session)
                
                val sessionManager = SessionManager(this@MainActivity)
                val session = sessionManager.getSession()
                
                statusText.text = getString(R.string.session_active)
            } catch (e: Exception) {
                statusText.text = getString(R.string.session_error, e.message)
            }
        }
    }
}
