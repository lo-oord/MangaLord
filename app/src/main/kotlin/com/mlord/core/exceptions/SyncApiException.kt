package com.mlord.core.exceptions

class SyncApiException(
	message: String,
	val code: Int,
) : RuntimeException(message)
