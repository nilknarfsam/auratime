package com.seunome.auratime

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider

class AuratimeWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views =
                RemoteViews(context.packageName, R.layout.auratime_widget).apply {
                    setTextViewText(
                        R.id.widget_status_text,
                        widgetData.getString(
                            "widget_status_text",
                            context.getString(R.string.widget_status_placeholder),
                        ),
                    )
                    val punchIntent =
                        HomeWidgetBackgroundIntent.getBroadcast(
                            context,
                            Uri.parse("auratime://bater_ponto"),
                        )
                    setOnClickPendingIntent(R.id.widget_action_button, punchIntent)
                }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
