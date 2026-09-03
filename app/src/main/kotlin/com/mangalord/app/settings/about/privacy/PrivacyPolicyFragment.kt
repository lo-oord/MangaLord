package com.mangalord.app.settings.about.privacy

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.core.view.WindowInsetsCompat
import io.noties.markwon.Markwon
import com.mangalord.app.R
import com.mangalord.app.core.ui.BaseFragment
import com.mangalord.app.core.util.ext.container
import com.mangalord.app.databinding.FragmentChangelogBinding

class PrivacyPolicyFragment : BaseFragment<FragmentChangelogBinding>() {

    override fun onCreateViewBinding(
        inflater: LayoutInflater,
        container: ViewGroup?,
    ) = FragmentChangelogBinding.inflate(inflater, container, false)

    override fun onViewBindingCreated(binding: FragmentChangelogBinding, savedInstanceState: Bundle?) {
        super.onViewBindingCreated(binding, savedInstanceState)
        val markwon = Markwon.create(binding.root.context)
        markwon.setMarkdown(binding.textViewContent, getString(R.string.privacy_policy_content))
        binding.progressBar.visibility = View.GONE
    }

    override fun onResume() {
        super.onResume()
        activity?.setTitle(R.string.privacy_policy)
    }

    override fun onApplyWindowInsets(
        v: View,
        insets: WindowInsetsCompat,
    ): WindowInsetsCompat {
        val typeMask = WindowInsetsCompat.Type.systemBars()
        val barsInsets = insets.getInsets(typeMask)
        val isTablet = !resources.getBoolean(R.bool.is_tablet)
        val isMaster = container?.id == R.id.container_master
        val basePadding = resources.getDimensionPixelOffset(R.dimen.screen_padding)
        requireViewBinding().textViewContent.setPaddingRelative(
            basePadding + if (isTablet && !isMaster) 0 else barsInsets.left,
            basePadding,
            basePadding + if (isTablet && isMaster) 0 else barsInsets.right,
            basePadding + barsInsets.bottom,
        )
        return insets
    }
}
