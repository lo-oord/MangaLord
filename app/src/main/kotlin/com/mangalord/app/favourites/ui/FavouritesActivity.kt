package com.mangalord.app.favourites.ui

import android.os.Bundle
import com.mangalord.app.core.nav.AppRouter
import com.mangalord.app.core.ui.FragmentContainerActivity
import com.mangalord.app.favourites.ui.list.FavouritesListFragment

class FavouritesActivity : FragmentContainerActivity(FavouritesListFragment::class.java) {

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		val categoryTitle = intent.getStringExtra(AppRouter.KEY_TITLE)
		if (categoryTitle != null) {
			title = categoryTitle
		}
	}
}
