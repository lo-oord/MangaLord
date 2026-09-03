package com.mangalord.app.browser

import android.content.Intent
import dagger.hilt.android.AndroidEntryPoint
import com.mangalord.app.core.network.webview.adblock.AdBlock
import com.mangalord.app.core.ui.CoroutineIntentService
import javax.inject.Inject

@AndroidEntryPoint
class AdListUpdateService : CoroutineIntentService() {

	@Inject
	lateinit var updater: AdBlock.Updater

	override suspend fun IntentJobContext.processIntent(intent: Intent) {
		updater.updateList()
	}

	override fun IntentJobContext.onError(error: Throwable) = Unit
}
