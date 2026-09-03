package com.mangalord.app.core.exceptions

import okio.IOException

class WrapperIOException(override val cause: Exception) : IOException(cause)
