package com.meetinglawyers.meetingpros_sample

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

/** A FlutterFragmentActivity, because the MeetingDoctors lists are fragments. */
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MeetingProsChannel.register(flutterEngine, this)
    }
}
