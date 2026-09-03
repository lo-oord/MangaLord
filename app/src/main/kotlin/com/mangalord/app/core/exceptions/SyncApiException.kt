package com.mangalord.app.core.exceptions

class SyncApiException(
	message: String,
	val code: Int,
) : RuntimeException(message)
