package app.one.tome

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class ContinueReadingWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs: SharedPreferences = HomeWidgetPlugin.getData(context)
            val title = prefs.getString("title", "No active book") ?: "No active book"
            val progress = prefs.getString("progress", "Start a book") ?: "Start a book"
            val percent = prefs.getInt("percent", 0)

            val views = RemoteViews(context.packageName, R.layout.continue_reading_widget)
            views.setTextViewText(R.id.widget_title, title)
            views.setTextViewText(R.id.widget_progress, progress)
            views.setProgressBar(R.id.widget_bar, 100, percent, false)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
