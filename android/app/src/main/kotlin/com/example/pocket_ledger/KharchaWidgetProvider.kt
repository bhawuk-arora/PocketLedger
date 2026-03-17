package com.example.pocket_ledger

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import com.example.pocket_ledger.R

class KharchaWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            try {
                val views = RemoteViews(context.packageName, R.layout.kharcha_widget)

                val monthTotal = widgetData.getString("monthly_total", "₹0") ?: "₹0"
                val monthName = widgetData.getString("month_name", "This Month") ?: "This Month"
                val txnCount = widgetData.getString("txn_count", "0 expenses") ?: "0 expenses"
                val reaction = widgetData.getString("reaction", "Track karo paaji! 🔥") ?: "Track karo paaji! 🔥"

                views.setTextViewText(R.id.widget_month, monthName)
                views.setTextViewText(R.id.widget_total, monthTotal)
                views.setTextViewText(R.id.widget_txn_count, txnCount)
                views.setTextViewText(R.id.widget_reaction, reaction)

                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (e: Exception) {
                // Ignore errors to prevent widget crash UI
            }
        }
    }
}
