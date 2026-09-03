package com.mangalord.app.auth.ui

import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.Toast
import com.google.firebase.auth.FirebaseUser
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.isVisible
import androidx.lifecycle.lifecycleScope
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.auth.api.signin.GoogleSignInStatusCodes
import com.google.firebase.auth.FirebaseAuthInvalidCredentialsException
import com.google.firebase.auth.FirebaseAuthInvalidUserException
import com.google.firebase.auth.FirebaseAuthUserCollisionException
import com.google.firebase.auth.FirebaseAuthWeakPasswordException
import com.google.android.material.snackbar.Snackbar
import com.mangalord.app.R
import com.mangalord.app.core.ui.BaseActivity
import com.mangalord.app.databinding.ActivityAuthBinding
import com.mangalord.app.auth.data.FirebaseAuthRepository
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch
import javax.inject.Inject

@AndroidEntryPoint
class AuthActivity : BaseActivity<ActivityAuthBinding>() {

    @Inject lateinit var authRepository: FirebaseAuthRepository

    private val googleLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult(),
    ) { result ->
        Log.d(TAG, "Google account result received: resultCode=${result.resultCode}")
        val account = runCatching {
            GoogleSignIn.getSignedInAccountFromIntent(result.data)
                .getResult(ApiException::class.java)
        }.getOrElse { error ->
            Log.e(TAG, "Google credential retrieval failed", error)
            showError(error)
            return@registerForActivityResult
        }
        Log.d(TAG, "Google account selected; credential received")
        val token = account.idToken
        if (token.isNullOrBlank()) {
            Log.e(TAG, "Google credential did not contain an ID token")
            showError(IllegalStateException("Google ID token is missing"))
            return@registerForActivityResult
        }
        Log.d(TAG, "Firebase authentication started with Google credential")
        runAuth(requiresPassword = false, validateEmail = false) {
            authRepository.signInWithGoogle(token)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(ActivityAuthBinding.inflate(layoutInflater))
        setDisplayHomeAsUp(true, true)
        lifecycleScope.launch {
            val signedInUser = authRepository.reloadUser()
            if (signedInUser != null) {
                showProfile(signedInUser)
            } else {
                viewBinding.authForm.isVisible = true
                viewBinding.profilePanel.isVisible = false
            }
        }
        viewBinding.buttonEmailSignIn.setOnClickListener { runAuth { authRepository.signInWithEmail(email(), password()) } }
        viewBinding.buttonCreateAccount.setOnClickListener { runAuth { authRepository.createAccount(email(), password()) } }
        viewBinding.buttonSignOut.isVisible = false
        viewBinding.buttonSignOut.setOnClickListener { signOutAndFinish() }
        viewBinding.buttonProfileSignOut.setOnClickListener { signOutAndFinish() }
        viewBinding.buttonSaveProfile.setOnClickListener {
            viewBinding.profileNameLayout.error = null
            viewBinding.progress.isVisible = true
            lifecycleScope.launch {
                runCatching { authRepository.updateDisplayName(viewBinding.profileName.text?.toString().orEmpty()) }
                    .onSuccess {
                        viewBinding.progress.isVisible = false
                        showProfile(it)
                        toast(R.string.profile_saved)
                    }
                    .onFailure {
                        viewBinding.progress.isVisible = false
                        viewBinding.profileNameLayout.error = it.localizedMessage
                    }
            }
        }
        viewBinding.buttonGoogle.setOnClickListener {
            Log.d(TAG, "Google button clicked; launching account picker")
            viewBinding.buttonGoogle.isEnabled = false
            val client = GoogleSignIn.getClient(this, authRepository.googleSignInOptions(this))
            client.signOut().addOnCompleteListener {
                googleLauncher.launch(client.signInIntent)
            }
        }
        viewBinding.buttonForgotPassword.setOnClickListener {
            val email = email()
            if (email.isBlank()) {
                viewBinding.emailLayout.error = getString(R.string.auth_invalid_email)
            } else {
                runAuth(requiresPassword = false) {
                    authRepository.sendPasswordReset(email)
                    null
                }
            }
        }
        viewBinding.textVerification.setOnClickListener {
            lifecycleScope.launch {
                runCatching { authRepository.resendVerificationEmail() }
                    .onSuccess { toast(R.string.verification_email_sent) }
                    .onFailure(::showError)
            }
        }
    }

    override fun onApplyWindowInsets(v: View, insets: WindowInsetsCompat): WindowInsetsCompat = insets

    private fun email() = viewBinding.email.text?.toString().orEmpty()
    private fun password() = viewBinding.password.text?.toString().orEmpty()

    private fun <T> runAuth(
        requiresPassword: Boolean = true,
        validateEmail: Boolean = true,
        block: suspend () -> T,
    ) {
        viewBinding.emailLayout.error = null
        viewBinding.passwordLayout.error = null
        if (validateEmail && !android.util.Patterns.EMAIL_ADDRESS.matcher(email()).matches()) {
            viewBinding.emailLayout.error = getString(R.string.auth_invalid_email)
            return
        }
        if (requiresPassword && password().length < 6) {
            viewBinding.passwordLayout.error = getString(R.string.auth_weak_password)
            return
        }
        viewBinding.progress.visibility = View.VISIBLE
        lifecycleScope.launch {
            runCatching { block() }
                .onSuccess {
                    viewBinding.progress.visibility = View.GONE
                    viewBinding.buttonGoogle.isEnabled = true
                    Log.d(TAG, "Firebase authentication succeeded")
                    val user = authRepository.reloadUser()
                    if (user != null && !user.isEmailVerified && user.providerData.none { it.providerId == "google.com" }) {
                        viewBinding.textVerification.text = getString(R.string.email_verification_required)
                        viewBinding.textVerification.visibility = View.VISIBLE
                        toast(R.string.account_created_verify_email)
                    } else {
                        setResult(RESULT_OK)
                        finish()
                    }
                }
                .onFailure {
                    viewBinding.progress.visibility = View.GONE
                    viewBinding.buttonGoogle.isEnabled = true
                    Log.e(TAG, "Authentication failed", it)
                    showError(it)
                }
        }
    }

    private fun showError(error: Throwable) {
        val message = when (error) {
            is ApiException -> when (error.statusCode) {
                GoogleSignInStatusCodes.SIGN_IN_CANCELLED -> R.string.google_sign_in_cancelled
                else -> R.string.google_sign_in_failed
            }
            is FirebaseAuthWeakPasswordException -> R.string.auth_weak_password
            is FirebaseAuthUserCollisionException -> R.string.auth_email_in_use
            is FirebaseAuthInvalidCredentialsException, is FirebaseAuthInvalidUserException -> R.string.auth_invalid_credentials
            else -> null
        }
        if (message != null) toast(message)
        else Snackbar.make(viewBinding.root, getString(R.string.google_sign_in_failed), Snackbar.LENGTH_LONG).show()
    }

    private fun showProfile(user: FirebaseUser) {
        viewBinding.authForm.isVisible = false
        viewBinding.profilePanel.isVisible = true
        viewBinding.profileEmail.text = user.email.orEmpty()
        viewBinding.profileName.setText(user.displayName.orEmpty())
        viewBinding.profileAvatar.text = user.displayName?.trim()?.firstOrNull()?.uppercase() ?: "M"
    }

    private fun signOutAndFinish() {
        authRepository.signOut()
        finish()
    }

    private fun toast(message: Int) = Toast.makeText(this, message, Toast.LENGTH_LONG).show()

    private companion object {
        const val TAG = "AuthActivity"
    }
}
