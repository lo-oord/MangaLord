package com.mlord.app.app.favourites.ui

import android.os.Bundle
import com.mlord.app.app.app.core.nav.AppRouter
import com.mlord.app.app.app.core.ui.FragmentContainerActivity
import com.mlord.app.app.app.favourites.ui.list.FavouritesListFragment

class FavouritesActivity : FragmentContainerActivity(FavouritesListFragment::class.java) {

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		val categoryTitle = intent.getStringExtra(AppRouter.KEY_TITLE)
		if (categoryTitle != null) {
			title = categoryTitle
		}
	}
}
