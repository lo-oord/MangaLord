package com.mlord.app.app.core.util

import kotlinx.coroutines.CoroutineExceptionHandler
import com.mlord.app.app.app.core.util.ext.printStackTraceDebug
import com.mlord.app.app.app.core.util.ext.report
import kotlin.coroutines.AbstractCoroutineContextElement
import kotlin.coroutines.CoroutineContext

class AcraCoroutineErrorHandler : AbstractCoroutineContextElement(CoroutineExceptionHandler),
	CoroutineExceptionHandler {

	override fun handleException(context: CoroutineContext, exception: Throwable) {
		exception.printStackTraceDebug()
		exception.report()
	}
}
