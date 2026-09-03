package com.mlord.sync.ui.history

import android.accounts.Account
import android.content.AbstractThreadedSyncAdapter
import android.content.ContentProviderClient
import android.content.Context
import android.content.SyncResult
import android.os.Bundle
import dagger.hilt.android.EntryPointAccessors
import com.mlord.R
import com.mlord.core.util.ext.onError
import com.mlord.parsers.util.runCatchingCancellable
import com.mlord.sync.domain.SyncController
import com.mlord.sync.ui.SyncAdapterEntryPoint

class HistorySyncAdapter(context: Context) : AbstractThreadedSyncAdapter(context, true) {

	override fun onPerformSync(
		account: Account,
		extras: Bundle,
		authority: String,
		provider: ContentProviderClient,
		syncResult: SyncResult,
	) {
		if (!context.resources.getBoolean(R.bool.is_sync_enabled)) {
			return
		}
		val entryPoint = EntryPointAccessors.fromApplication(context, SyncAdapterEntryPoint::class.java)
		val syncHelper = entryPoint.syncHelperFactory.create(account, provider)
		runCatchingCancellable {
			syncHelper.syncHistory(syncResult.stats)
			SyncController.setLastSync(context, account, authority, System.currentTimeMillis())
		}.onFailure { e ->
			syncResult.onError(e)
			syncHelper.onError(e)
		}
		syncHelper.onSyncComplete(syncResult)
	}
}
