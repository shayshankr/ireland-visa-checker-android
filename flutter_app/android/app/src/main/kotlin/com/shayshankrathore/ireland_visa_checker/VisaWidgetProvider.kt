package com.shayshankrathore.ireland_visa_checker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.graphics.Color
import es.antoniomarquezo.home_widget.HomeWidgetPlugin

class VisaWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.visa_widget)

        // Retrieve widget data from shared preferences
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val number = prefs.getString("flutter.number", "") ?: ""
        val status = prefs.getString("flutter.status", "No applications") ?: ""
        val detail = prefs.getString("flutter.detail", "Add an application to track") ?: ""
        val label = prefs.getString("flutter.label", "") ?: ""

        // Update views
        views.setTextViewText(R.id.widget_number, number)
        views.setTextViewText(R.id.widget_status, status)
        views.setTextViewText(R.id.widget_detail, detail)

        if (label.isNotEmpty()) {
            views.setTextViewText(R.id.widget_label, label)
        }

        // Color the status based on decision
        val statusColor = when {
            status.contains("Approved", ignoreCase = true) -> Color.parseColor("#2E7D32") // Green
            status.contains("Refused", ignoreCase = true) -> Color.parseColor("#C62828") // Red
            status.contains("Not published", ignoreCase = true) -> Color.parseColor("#F57F17") // Orange
            else -> Color.parseColor("#616161") // Grey
        }
        views.setTextColor(R.id.widget_status, statusColor)

        // Set up tap to open app
        val intent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
