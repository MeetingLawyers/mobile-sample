package com.meetinglawyers.meetingpros.sample

import android.Manifest
import android.os.Build
import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.TextView
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.isVisible
import androidx.lifecycle.lifecycleScope
import com.meetinglawyers.meetingpros.sample.MeetingProsIntegration.DoctorsFeature
import com.meetinglawyers.meetingpros.sample.MeetingProsIntegration.ProfessionalType
import kotlinx.coroutines.launch

/** Home screen: sign in, open the lawyers, doctors or vets list, a lawyer chat or a doctors feature, log out. */
class MainActivity : AppCompatActivity() {

    private enum class Status(val label: String) {
        MISSING_CREDENTIALS("Missing credentials"),
        CONFIGURED("Configured"),
        AUTHENTICATED("Authenticated"),
    }

    private val integration = MeetingProsIntegration
    private val notificationPermission = registerForActivityResult(ActivityResultContracts.RequestPermission()) { }

    private lateinit var statusText: TextView
    private lateinit var messageText: TextView
    private lateinit var hashInput: EditText
    private lateinit var signInButton: Button
    private lateinit var chatButton: Button
    private lateinit var logoutButton: Button
    private lateinit var listButtons: List<Button>
    private val featureButtons = mutableMapOf<DoctorsFeature, Button>()

    private var features = emptySet<DoctorsFeature>()
    private var status = Status.CONFIGURED
        set(value) {
            field = value
            render()
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        statusText = findViewById(R.id.status)
        messageText = findViewById(R.id.message)
        hashInput = findViewById(R.id.professional_hash)
        signInButton = findViewById<Button>(R.id.sign_in).apply { setOnClickListener { signIn() } }
        chatButton = findViewById<Button>(R.id.open_chat).apply { setOnClickListener { openChat() } }
        logoutButton = findViewById<Button>(R.id.log_out).apply { setOnClickListener { logOut() } }
        listButtons = ProfessionalType.entries.map { type -> addButton(R.id.lists, "Open ${type.name.lowercase()} list") {
            integration.openProfessionalList(this, type)
        } }
        DoctorsFeature.entries.forEach { feature ->
            featureButtons[feature] = addButton(R.id.features, "Open ${feature.name.lowercase().replace('_', ' ')}") {
                run { integration.open(this, feature) }
            }
        }

        status = when {
            !integration.isConfigured || Constants.userId.isEmpty() -> Status.MISSING_CREDENTIALS
            integration.isAuthenticated -> Status.AUTHENTICATED.also { loadFeatures() }
            else -> Status.CONFIGURED
        }
        if (status == Status.MISSING_CREDENTIALS) {
            show("Fill in ML_API_KEY, MD_API_KEY and ML_USER_ID in the repo-root .env, then rebuild.")
        }
    }

    private fun signIn() = run {
        integration.authenticate(Constants.userId)
        status = Status.AUTHENTICATED
        askNotificationPermission()
        loadFeatures()
    }

    private fun openChat() {
        val hash = hashInput.text.toString().trim()
        if (hash.isEmpty()) {
            show("Type a lawyer's professional hash first.")
            return
        }
        integration.openLawyerChat(this, hash)
    }

    private fun logOut() = run {
        integration.logout()
        features = emptySet()
        status = Status.CONFIGURED
    }

    private fun loadFeatures() = run {
        features = integration.availableFeatures()
        render()
    }

    /** Runs an SDK call on the main thread and shows its error, if any. */
    private fun run(operation: suspend () -> Unit) {
        show(null)
        lifecycleScope.launch {
            runCatching { operation() }.onFailure { show(it.message ?: it.toString()) }
        }
    }

    /** Android 13+ needs the runtime permission before showing any push. */
    private fun askNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            notificationPermission.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }

    private fun addButton(containerId: Int, title: String, onClick: () -> Unit): Button {
        val button = layoutInflater.inflate(R.layout.sample_button, findViewById<LinearLayout>(containerId), false) as Button
        button.text = title
        button.setOnClickListener { onClick() }
        findViewById<LinearLayout>(containerId).addView(button)
        return button
    }

    private fun render() {
        val environment = if (Constants.isProduction) "PROD" else "DEV"
        statusText.text = getString(R.string.status, status.label, environment)
        val authenticated = status == Status.AUTHENTICATED
        signInButton.isEnabled = status == Status.CONFIGURED
        listButtons.forEach { it.isEnabled = authenticated }
        hashInput.isEnabled = authenticated
        chatButton.isEnabled = authenticated
        featureButtons.forEach { (feature, button) -> button.isEnabled = authenticated && feature in features }
        logoutButton.isEnabled = authenticated
    }

    private fun show(message: String?) {
        messageText.text = message
        messageText.isVisible = message != null
    }
}
