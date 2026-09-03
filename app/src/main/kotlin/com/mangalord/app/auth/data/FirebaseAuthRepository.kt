package com.mangalord.app.auth.data

import android.app.Activity
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.GoogleAuthProvider
import com.google.firebase.auth.UserProfileChangeRequest
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
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
    private val firestore: FirebaseFirestore,
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
        val user = auth.signInWithEmailAndPassword(email.trim(), password).await().user
            ?: error("Firebase did not return a user")
        ensureUserProfile(user, "email")
        return user
    }

    suspend fun createAccount(email: String, password: String): FirebaseUser {
        val user = auth.createUserWithEmailAndPassword(email.trim(), password).await().user
            ?: error("Firebase did not return a user")
        ensureUserProfile(user, "password")
        user.sendEmailVerification().await()
        return user
    }

    suspend fun signInWithGoogle(idToken: String): FirebaseUser {
        require(idToken.isNotBlank()) { "Google ID token is missing" }
        val credential = GoogleAuthProvider.getCredential(idToken, null)
        val user = auth.signInWithCredential(credential).await().user
            ?: error("Firebase did not return a user")
        ensureUserProfile(user, "google.com")
        return user
    }

    suspend fun linkGoogleToCurrentUser(idToken: String): FirebaseUser {
        val user = auth.currentUser ?: error("No signed-in user")
        val linked = user.linkWithCredential(GoogleAuthProvider.getCredential(idToken, null)).await().user
            ?: error("Firebase did not return a user")
        ensureUserProfile(linked, "google.com")
        return linked
    }

    suspend fun updateDisplayName(name: String): FirebaseUser {
        val user = auth.currentUser ?: error("No signed-in user")
        val cleanName = name.trim().takeIf { it.isNotEmpty() } ?: error("Name cannot be empty")
        user.updateProfile(UserProfileChangeRequest.Builder().setDisplayName(cleanName).build()).await()
        user.reload().await()
        val refreshed = auth.currentUser ?: user
        ensureUserProfile(refreshed, providerOf(refreshed))
        return refreshed
    }

    suspend fun resendVerificationEmail() {
        auth.currentUser?.sendEmailVerification()?.await()
            ?: error("No signed-in user")
    }

    suspend fun sendPasswordReset(email: String) {
        auth.sendPasswordResetEmail(email.trim()).await()
    }

    suspend fun reloadUser(): FirebaseUser? {
        auth.currentUser?.reload()?.await()
        return auth.currentUser
    }

    fun signOut() = auth.signOut()

    fun isSignedIn(): Boolean = auth.currentUser != null

    fun isEmailVerified(): Boolean = auth.currentUser?.isEmailVerified == true

    private suspend fun ensureUserProfile(user: FirebaseUser, provider: String) {
        val ref = firestore.collection("users").document(user.uid)
        val existing = ref.get().await()
        val now = System.currentTimeMillis()
        val profile = hashMapOf<String, Any?>(
            "uid" to user.uid,
            "email" to user.email,
            "displayName" to user.displayName,
            "photoUrl" to user.photoUrl?.toString(),
            "provider" to provider,
            "updatedAt" to now,
        )
        if (!existing.exists()) profile["createdAt"] = now
        ref.set(profile, SetOptions.merge()).await()
    }

    private fun providerOf(user: FirebaseUser): String =
        user.providerData.firstOrNull { it.providerId != "firebase" }?.providerId ?: "password"
}
