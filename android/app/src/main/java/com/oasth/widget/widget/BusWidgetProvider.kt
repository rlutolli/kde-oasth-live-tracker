package com.oasth.widget.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.oasth.widget.R
import com.oasth.widget.data.BusArrival
import com.oasth.widget.data.OasthApi
import com.oasth.widget.data.SessionManager
import com.oasth.widget.data.WidgetConfigRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/**
 * Home screen widget provider for bus arrivals
 */
class BusWidgetProvider : AppWidgetProvider() {
    
    companion object {
        const val ACTION_REFRESH = "com.oasth.widget.ACTION_REFRESH"
        private const val MAX_ARRIVALS = 4
    }
    
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        if (intent.action == ACTION_REFRESH) {
            val widgetId = intent.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID
            )
            if (widgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                val manager = AppWidgetManager.getInstance(context)
                updateWidget(context, manager, widgetId)
            }
        }
    }
    
    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        val configRepo = WidgetConfigRepository(context)
        for (widgetId in appWidgetIds) {
            configRepo.deleteConfig(widgetId)
        }
    }
    
    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int
    ) {
        val configRepo = WidgetConfigRepository(context)
        val config = configRepo.getConfig(widgetId)
        
        if (config == null) {
            // Widget not configured yet
            showNotConfigured(context, appWidgetManager, widgetId)
            return
        }
        
        // Show loading state
        showLoading(context, appWidgetManager, widgetId, config.stopName)
        
        // Fetch arrivals in background
        scope.launch {
            try {
                val sessionManager = SessionManager(context)
                val api = OasthApi(sessionManager)
                val arrivals = api.getArrivals(config.stopCode)
                
                showArrivals(context, appWidgetManager, widgetId, config.stopName, arrivals)
            } catch (e: Exception) {
                showError(context, appWidgetManager, widgetId, config.stopName)
            }
        }
    }
    
    private fun showNotConfigured(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_layout)
        views.setTextViewText(R.id.stop_name, context.getString(R.string.tap_to_configure))
        views.setTextViewText(R.id.arrivals_text, "")
        
        // Click to open config
        val configIntent = Intent(context, WidgetConfigActivity::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        }
        val pendingIntent = PendingIntent.getActivity(
            context, widgetId, configIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
        
        appWidgetManager.updateAppWidget(widgetId, views)
    }
    
    private fun showLoading(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        stopName: String
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_layout)
        views.setTextViewText(R.id.stop_name, stopName)
        views.setTextViewText(R.id.arrivals_text, context.getString(R.string.loading))
        
        appWidgetManager.updateAppWidget(widgetId, views)
    }
    
    private fun showArrivals(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        stopName: String,
        arrivals: List<BusArrival>
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_layout)
        views.setTextViewText(R.id.stop_name, stopName)
        
        val arrivalsText = if (arrivals.isEmpty()) {
            context.getString(R.string.no_buses)
        } else {
            arrivals.take(MAX_ARRIVALS)
                .groupBy { it.lineId }
                .map { (lineId, buses) ->
                    val times = buses.sortedBy { it.estimatedMinutes }
                        .take(2)
                        .joinToString(", ") { "${it.estimatedMinutes}'" }
                    "$lineId: $times"
                }
                .joinToString("\n")
        }
        
        views.setTextViewText(R.id.arrivals_text, arrivalsText)
        
        // Refresh on click
        val refreshIntent = Intent(context, BusWidgetProvider::class.java).apply {
            action = ACTION_REFRESH
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context, widgetId, refreshIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
        
        appWidgetManager.updateAppWidget(widgetId, views)
    }
    
    private fun showError(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        stopName: String
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_layout)
        views.setTextViewText(R.id.stop_name, stopName)
        views.setTextViewText(R.id.arrivals_text, context.getString(R.string.error_loading))
        
        // Refresh on click
        val refreshIntent = Intent(context, BusWidgetProvider::class.java).apply {
            action = ACTION_REFRESH
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context, widgetId, refreshIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
        
        appWidgetManager.updateAppWidget(widgetId, views)
    }
}
