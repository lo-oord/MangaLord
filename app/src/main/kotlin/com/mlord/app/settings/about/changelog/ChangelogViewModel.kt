package com.mlord.app.settings.about.changelog

import android.content.Context
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import org.jsoup.internal.StringUtil
import com.mlord.app.R
import com.mlord.app.core.LocalizedAppContext
import com.mlord.app.core.github.AppUpdateRepository
import com.mlord.app.core.ui.BaseViewModel
import javax.inject.Inject

@HiltViewModel
class ChangelogViewModel @Inject constructor(
	private val appUpdateRepository: AppUpdateRepository,
	@LocalizedAppContext private val context: Context,
) : BaseViewModel() {

	val changelog = MutableStateFlow<String?>(null)

	init {
		launchLoadingJob(Dispatchers.Default) {
			val versions = appUpdateRepository.getAvailableVersions()
			val stringJoiner = StringUtil.StringJoiner("\n\n\n")
			stringJoiner.add(context.getString(R.string.changelog_current_entry))
			for (version in versions) {
				stringJoiner.add("# ")
					.append(version.name)
					.append("\n\n")
					.append(version.description)
			}
			changelog.value = stringJoiner.complete()
		}
	}
}
