package com.meetinglawyers.sample

import android.Manifest
import android.os.Build
import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.isVisible

/** Home screen with the same flow as the Capacitor sample: sign in, open the list or a chat, log out. */
class MainActivity : AppCompatActivity() {

    private enum class Status(val label: String) {
        MISSING_CREDENTIALS("Missing credentials"),
        CONFIGURED("Configured"),
        AUTHENTICATED("Authenticated"),
    }

    private val integration = MeetingLawyersIntegration
    private val notificationPermission = registerForActivityResult(ActivityResultContracts.RequestPermission()) { }

    private lateinit var statusText: TextView
    private lateinit var messageText: TextView
    private lateinit var hashInput: EditText
    private lateinit var signInButton: Button
    private lateinit var listButton: Button
    private lateinit var chatButton: Button
    private lateinit var logoutButton: Button

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
        listButton = findViewById<Button>(R.id.open_list).apply {
            setOnClickListener { integration.openProfessionalList(this@MainActivity) }
        }
        chatButton = findViewById<Button>(R.id.open_chat).apply { setOnClickListener { openChat() } }
        logoutButton = findViewById<Button>(R.id.log_out).apply { setOnClickListener { logOut() } }

        status = when {
            !integration.isConfigured || Constants.userId.isEmpty() -> Status.MISSING_CREDENTIALS
            integration.isAuthenticated -> Status.AUTHENTICATED
            else -> Status.CONFIGURED
        }
        if (status == Status.MISSING_CREDENTIALS) {
            show("Fill in ML_API_KEY and ML_USER_ID in the repo-root .env, then rebuild.")
        }
    }

    private fun signIn() {
        show(null)
        integration.authenticate(Constants.userId) { error ->
            runOnUiThread {
                show(error)
                if (error == null) {
                    status = Status.AUTHENTICATED
                    askNotificationPermission()
                }
            }
        }
    }

    private fun openChat() {
        val hash = hashInput.text.toString().trim()
        if (hash.isEmpty()) {
            show("Type a professional hash first.")
            return
        }
        show(null)
        integration.openChat(this, hash)
    }

    private fun logOut() {
        show(null)
        integration.logout { error ->
            runOnUiThread {
                show(error)
                if (error == null) status = Status.CONFIGURED
            }
        }
    }

    /** Android 13+ needs the runtime permission before showing any push. */
    private fun askNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            notificationPermission.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }

    private fun render() {
        val environment = if (Constants.isProduction) "PROD" else "DEV"
        statusText.text = getString(R.string.status, status.label, environment)
        val authenticated = status == Status.AUTHENTICATED
        signInButton.isEnabled = status == Status.CONFIGURED
        listButton.isEnabled = authenticated
        hashInput.isEnabled = authenticated
        chatButton.isEnabled = authenticated
        logoutButton.isEnabled = authenticated
    }

    private fun show(message: String?) {
        messageText.text = message
        messageText.isVisible = message != null
    }
}
