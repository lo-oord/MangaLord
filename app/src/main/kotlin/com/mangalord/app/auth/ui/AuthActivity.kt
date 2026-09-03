package com.mangalord.app.auth.ui

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.isVisible
import androidx.lifecycle.lifecycleScope
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.common.api.ApiException
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
        if (result.resultCode != RESULT_OK) return@registerForActivityResult
        val account = runCatching {
            GoogleSignIn.getSignedInAccountFromIntent(result.data)
                .getResult(ApiException::class.java)
        }.getOrElse { error ->
            showError(error)
            return@registerForActivityResult
        }
        val token = account.idToken
        if (token.isNullOrBlank()) {
            showError(IllegalStateException("Google ID token is missing"))
        } else {
            runAuth { authRepository.signInWithGoogle(token) }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(ActivityAuthBinding.inflate(layoutInflater))
        setDisplayHomeAsUp(true, true)
        viewBinding.buttonEmailSignIn.setOnClickListener { runAuth { authRepository.signInWithEmail(email(), password()) } }
        viewBinding.buttonCreateAccount.setOnClickListener { runAuth { authRepository.createAccount(email(), password()) } }
        viewBinding.buttonSignOut.isVisible = authRepository.isSignedIn()
        viewBinding.buttonSignOut.setOnClickListener {
            authRepository.signOut()
            finish()
        }
        viewBinding.buttonGoogle.setOnClickListener {
            val client = GoogleSignIn.getClient(this, authRepository.googleSignInOptions(this))
            googleLauncher.launch(client.signInIntent)
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

    private fun <T> runAuth(requiresPassword: Boolean = true, block: suspend () -> T) {
        viewBinding.emailLayout.error = null
        viewBinding.passwordLayout.error = null
        if (!android.util.Patterns.EMAIL_ADDRESS.matcher(email()).matches()) {
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
                    showError(it)
                }
        }
    }

    private fun showError(error: Throwable) {
        val message = when (error) {
            is FirebaseAuthWeakPasswordException -> R.string.auth_weak_password
            is FirebaseAuthUserCollisionException -> R.string.auth_email_in_use
            is FirebaseAuthInvalidCredentialsException, is FirebaseAuthInvalidUserException -> R.string.auth_invalid_credentials
            else -> null
        }
        if (message != null) toast(message) else Snackbar.make(viewBinding.root, error.localizedMessage ?: getString(R.string.operation_not_supported), Snackbar.LENGTH_LONG).show()
    }

    private fun toast(message: Int) = Toast.makeText(this, message, Toast.LENGTH_LONG).show()
}
