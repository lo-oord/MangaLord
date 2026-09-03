package com.mangalord.app.auth.data

import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.GoogleAuthProvider
import com.mangalord.app.R
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class FirebaseAuthRepository @Inject constructor(
    private val auth: FirebaseAuth,
) {
    val currentUser: Flow<FirebaseUser?> = callbackFlow {
        val listener = FirebaseAuth.AuthStateListener { trySend(it.currentUser) }
        auth.addAuthStateListener(listener)
        trySend(auth.currentUser)
        awaitClose { auth.removeAuthStateListener(listener) }
    }

    fun googleSignInOptions(activity: Activity): GoogleSignInOptions =
        GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestIdToken(activity.getString(R.string.default_web_client_id))
            .requestEmail()
            .build()

    suspend fun signInWithEmail(email: String, password: String): FirebaseUser {
        return auth.signInWithEmailAndPassword(email.trim(), password).await().user
            ?: error("Firebase did not return a user")
    }

    suspend fun createAccount(email: String, password: String): FirebaseUser {
        val user = auth.createUserWithEmailAndPassword(email.trim(), password).await().user
            ?: error("Firebase did not return a user")
        user.sendEmailVerification().await()
        return user
    }

    suspend fun signInWithGoogle(idToken: String): FirebaseUser {
        return auth.signInWithCredential(GoogleAuthProvider.getCredential(idToken, null)).await().user
            ?: error("Firebase did not return a user")
    }

    suspend fun resendVerificationEmail() {
        auth.currentUser?.sendEmailVerification()?.await()
    }

    suspend fun sendPasswordReset(email: String) {
        auth.sendPasswordResetEmail(email.trim()).await()
    }

    suspend fun reloadUser(): FirebaseUser? {
        auth.currentUser?.reload()?.await()
        return auth.currentUser
    }

    fun signOut() {
        auth.signOut()
    }

    fun isEmailVerified(): Boolean = auth.currentUser?.isEmailVerified == true
}
