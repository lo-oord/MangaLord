package com.mlord.app.app.favourites.ui.container

import android.view.Menu
import android.view.MenuInflater
import android.view.MenuItem
import androidx.core.view.MenuProvider
import com.mlord.app.app.app.R
import com.mlord.app.app.app.core.nav.AppRouter

class FavouritesContainerMenuProvider(
	private val router: AppRouter,
) : MenuProvider {

	override fun onCreateMenu(menu: Menu, menuInflater: MenuInflater) {
		menuInflater.inflate(R.menu.opt_favourites_container, menu)
	}

	override fun onMenuItemSelected(menuItem: MenuItem): Boolean {
		when (menuItem.itemId) {
			R.id.action_manage -> {
				router.openFavoriteCategories()
			}

			else -> return false
		}
		return true
	}
}
