package com.meetinglawyers.sample.ionic;

import android.os.Bundle;

import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        registerPlugin(MeetingLawyersPlugin.class);
        super.onCreate(savedInstanceState);
    }
}
