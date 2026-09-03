package com.mlord.scrobbling.common.domain

import okio.IOException
import com.mlord.scrobbling.common.domain.model.ScrobblerService

class ScrobblerAuthRequiredException(
	val scrobbler: ScrobblerService,
) : IOException()
