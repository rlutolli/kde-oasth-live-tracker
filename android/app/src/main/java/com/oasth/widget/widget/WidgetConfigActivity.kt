package com.oasth.widget.widget

import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import android.widget.Button
import android.widget.EditText
import com.oasth.widget.R
import com.oasth.widget.data.WidgetConfig
import com.oasth.widget.data.WidgetConfigRepository

/**
 * Configuration activity for setting up a widget's stop code
 */
class WidgetConfigActivity : AppCompatActivity() {
    
    private var widgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private lateinit var configRepo: WidgetConfigRepository
    
    private lateinit var stopCodeInput: EditText
    private lateinit var stopNameInput: EditText
    private lateinit var saveButton: Button
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_config)
        
        // Set result to canceled in case user backs out
        setResult(RESULT_CANCELED)
        
        configRepo = WidgetConfigRepository(this)
        
        // Get widget ID from intent
        widgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        )
        
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }
        
        // Initialize views
        stopCodeInput = findViewById(R.id.stop_code_input)
        stopNameInput = findViewById(R.id.stop_name_input)
        saveButton = findViewById(R.id.save_button)
        
        // Load existing config if reconfiguring
        val existingConfig = configRepo.getConfig(widgetId)
        if (existingConfig != null) {
            stopCodeInput.setText(existingConfig.stopCode)
            stopNameInput.setText(existingConfig.stopName)
        }
        
        saveButton.setOnClickListener {
            saveConfiguration()
        }
    }
    
    private fun saveConfiguration() {
        val stopCode = stopCodeInput.text.toString().trim()
        val stopName = stopNameInput.text.toString().trim()
        
        if (stopCode.isEmpty()) {
            Toast.makeText(this, R.string.enter_stop_code, Toast.LENGTH_SHORT).show()
            return
        }
        
        // Use stop code as name if name not provided
        val displayName = if (stopName.isEmpty()) "Stop $stopCode" else stopName
        
        // Save configuration
        val config = WidgetConfig(
            widgetId = widgetId,
            stopCode = stopCode,
            stopName = displayName
        )
        configRepo.saveConfig(config)
        
        // Trigger widget update
        val appWidgetManager = AppWidgetManager.getInstance(this)
        val intent = Intent(this, BusWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(widgetId))
        }
        sendBroadcast(intent)
        
        // Update widget immediately
        BusWidgetProvider().onUpdate(this, appWidgetManager, intArrayOf(widgetId))
        
        // Return success
        val resultIntent = Intent().apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        }
        setResult(RESULT_OK, resultIntent)
        finish()
    }
}
