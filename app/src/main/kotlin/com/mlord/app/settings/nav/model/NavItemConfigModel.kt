package com.mlord.app.settings.nav.model

import androidx.annotation.StringRes
import com.mlord.app.app.core.prefs.NavItem
import com.mlord.app.app.list.ui.model.ListModel

data class NavItemConfigModel(
	val item: NavItem,
	@StringRes val disabledHintResId: Int,
) : ListModel {

	override fun areItemsTheSame(other: ListModel): Boolean {
		return other is NavItemConfigModel && other.item == item
	}
}
