package com.mlord.app.app.details.domain

import com.mlord.app.app.app.core.util.LocaleStringComparator
import com.mlord.app.app.app.details.ui.model.MangaBranch

class BranchComparator : Comparator<MangaBranch> {

	private val delegate = LocaleStringComparator()

	override fun compare(o1: MangaBranch, o2: MangaBranch): Int = delegate.compare(o1.name, o2.name)
}
