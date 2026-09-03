package com.mlord.core.exceptions

import com.mlord.core.model.UnknownMangaSource
import com.mlord.parsers.model.MangaSource
import com.mlord.parsers.network.CloudFlareHelper

class CloudFlareBlockedException(
	override val url: String,
	source: MangaSource?,
) : CloudFlareException("Blocked by CloudFlare", CloudFlareHelper.PROTECTION_BLOCKED) {

	override val source: MangaSource = source ?: UnknownMangaSource
}
