package com.mlord.app.sync.ui.favourites

import android.accounts.Account
import android.content.AbstractThreadedSyncAdapter
import android.content.ContentProviderClient
import android.content.Context
import android.content.SyncResult
import android.os.Bundle
import dagger.hilt.android.EntryPointAccessors
import com.mlord.app.app.R
import com.mlord.app.app.core.util.ext.onError
import org.koitharu.kotatsu.parsers.util.runCatchingCancellable
import com.mlord.app.app.sync.domain.SyncController
import com.mlord.app.app.sync.ui.SyncAdapterEntryPoint

class FavouritesSyncAdapter(context: Context) : AbstractThreadedSyncAdapter(context, true) {

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
			syncHelper.syncFavourites(syncResult.stats)
			SyncController.setLastSync(context, account, authority, System.currentTimeMillis())
		}.onFailure { e ->
			syncResult.onError(e)
			syncHelper.onError(e)
		}
		syncHelper.onSyncComplete(syncResult)
	}
}
