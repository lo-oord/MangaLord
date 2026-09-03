package com.mlord.app.scrobbling.common.domain

import okio.IOException
import com.mlord.app.app.scrobbling.common.domain.model.ScrobblerService

class ScrobblerAuthRequiredException(
	val scrobbler: ScrobblerService,
) : IOException()
