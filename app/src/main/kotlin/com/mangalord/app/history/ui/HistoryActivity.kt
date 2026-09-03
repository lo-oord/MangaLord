package com.mangalord.app.history.ui

import android.os.Bundle
import com.mangalord.app.auth.AuthGate
import com.mangalord.app.core.ui.FragmentContainerActivity

class HistoryActivity : FragmentContainerActivity(HistoryListFragment::class.java) {
    override fun onCreate(savedInstanceState: Bundle?) {
        if (!AuthGate.requireSignIn(this)) {
            finish()
            return
        }
        super.onCreate(savedInstanceState)
    }
}
