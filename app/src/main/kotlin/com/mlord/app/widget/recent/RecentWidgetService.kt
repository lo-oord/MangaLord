package com.mlord.app.widget.recent

import android.content.Intent
import android.widget.RemoteViewsService
import coil3.ImageLoader
import dagger.Lazy
import dagger.hilt.android.AndroidEntryPoint
import com.mlord.app.app.core.prefs.AppSettings
import com.mlord.app.app.history.data.HistoryRepository
import javax.inject.Inject

@AndroidEntryPoint
class RecentWidgetService : RemoteViewsService() {

	@Inject
	lateinit var historyRepository: HistoryRepository

	@Inject
	lateinit var settings: AppSettings

	@Inject
	lateinit var coilLazy: Lazy<ImageLoader>

	override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
		return RecentListFactory(applicationContext, historyRepository, coilLazy, settings)
	}
}
