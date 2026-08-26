package com.garmin.android.connectiq.adb;

import android.content.Context;
import android.content.Intent;
import com.garmin.android.connectiq.ConnectIQ;
import com.garmin.android.connectiq.IQApp;
import com.garmin.android.connectiq.IQDevice;

/* loaded from: classes.dex */
public class AdbDataHandler {
    public static void handleMessage(Context context, byte[] bArr) {
        Intent intent = new Intent(ConnectIQ.INCOMING_MESSAGE);
        intent.putExtra(ConnectIQ.EXTRA_REMOTE_DEVICE, new IQDevice(12345L, "Simulator"));
        intent.putExtra(ConnectIQ.EXTRA_REMOTE_APPLICATION, new IQApp("", "Simulator App", 1));
        intent.putExtra(ConnectIQ.EXTRA_PAYLOAD, bArr);
        context.sendBroadcast(intent);
    }
}
