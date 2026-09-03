package com.mangalord.app.scrobbling.common.domain

import okio.IOException
import com.mangalord.app.scrobbling.common.domain.model.ScrobblerService

class ScrobblerAuthRequiredException(
	val scrobbler: ScrobblerService,
) : IOException()
