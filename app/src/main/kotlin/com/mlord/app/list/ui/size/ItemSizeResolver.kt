package com.mlord.app.list.ui.size

import android.view.View
import android.widget.TextView
import com.mlord.app.app.history.ui.util.ReadingProgressView

interface ItemSizeResolver {

	val cellWidth: Int

	fun attachToView(
		view: View,
		textView: TextView?,
		progressView: ReadingProgressView?,
	)
}
