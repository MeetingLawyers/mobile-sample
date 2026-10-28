package com.meetinglawyers.sample.flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/** Registers the MeetingLawyers channel on the Flutter engine. */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MeetingLawyersChannel.register(flutterEngine, this)
    }
}
