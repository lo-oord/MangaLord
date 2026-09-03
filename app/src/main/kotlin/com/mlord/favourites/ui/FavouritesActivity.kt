package com.mlord.favourites.ui

import android.os.Bundle
import com.mlord.core.nav.AppRouter
import com.mlord.core.ui.FragmentContainerActivity
import com.mlord.favourites.ui.list.FavouritesListFragment

class FavouritesActivity : FragmentContainerActivity(FavouritesListFragment::class.java) {

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		val categoryTitle = intent.getStringExtra(AppRouter.KEY_TITLE)
		if (categoryTitle != null) {
			title = categoryTitle
		}
	}
}
