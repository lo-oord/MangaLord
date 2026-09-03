package com.mlord.core.exceptions

import okhttp3.Headers
import com.mlord.core.model.UnknownMangaSource
import com.mlord.parsers.model.MangaSource
import com.mlord.parsers.network.CloudFlareHelper

class CloudFlareProtectedException(
	override val url: String,
	source: MangaSource?,
	@Transient val headers: Headers,
) : CloudFlareException("Protected by CloudFlare", CloudFlareHelper.PROTECTION_CAPTCHA) {

	override val source: MangaSource = source ?: UnknownMangaSource
}
