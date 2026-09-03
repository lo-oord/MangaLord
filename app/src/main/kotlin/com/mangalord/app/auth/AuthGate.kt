package com.mangalord.app.auth

import android.content.Context
import android.content.Intent
import android.widget.Toast
import com.google.firebase.auth.FirebaseAuth
import com.mangalord.app.R
import com.mangalord.app.auth.ui.AuthActivity

object AuthGate {
    fun isSignedIn(): Boolean = FirebaseAuth.getInstance().currentUser != null

    fun requireSignIn(context: Context): Boolean {
        if (isSignedIn()) return true
        Toast.makeText(context, R.string.auth_required_for_feature, Toast.LENGTH_LONG).show()
        context.startActivity(Intent(context, AuthActivity::class.java))
        return false
    }
}
