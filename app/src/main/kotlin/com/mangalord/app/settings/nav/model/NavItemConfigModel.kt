package com.mangalord.app.settings.nav.model

import androidx.annotation.StringRes
import com.mangalord.app.core.prefs.NavItem
import com.mangalord.app.list.ui.model.ListModel

data class NavItemConfigModel(
	val item: NavItem,
	@StringRes val disabledHintResId: Int,
) : ListModel {

	override fun areItemsTheSame(other: ListModel): Boolean {
		return other is NavItemConfigModel && other.item == item
	}
}
