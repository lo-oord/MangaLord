package com.mlord.app.core.exceptions

import okio.IOException

class WrapperIOException(override val cause: Exception) : IOException(cause)
