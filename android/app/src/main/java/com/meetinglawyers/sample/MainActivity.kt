package com.meetinglawyers.sample

import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.meetinglawyers.sdk.MeetingLawyersSDK
import com.meetinglawyers.sdk.SDKCallbackWithoutData

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        val signInButton: Button = findViewById(R.id.sign_in)
        signInButton.setOnClickListener {
            signInAndLaunchProfessionalList()
        }
    }

    private fun signInAndLaunchProfessionalList() {
        MeetingLawyersSDK.getClientInstance().authenticate(
            Constants.userId, object : SDKCallbackWithoutData {
                override fun onSuccess() {
                    runOnUiThread { launchProfessionalList() }
                }

                override fun onError(message: String?) {
                    runOnUiThread {
                        Toast.makeText(this@MainActivity, "Error sign in", Toast.LENGTH_SHORT).show()
                    }
                    println(message)
                }
            })
    }

    private fun launchProfessionalList() {
        val frameLayout = FrameLayout(this).apply {
            id = View.generateViewId()
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }

        (findViewById<ViewGroup>(android.R.id.content)).addView(frameLayout)

        supportFragmentManager.beginTransaction()
            .add(frameLayout.id, ProfessionalListFragment())
            .commit()
    }
}
