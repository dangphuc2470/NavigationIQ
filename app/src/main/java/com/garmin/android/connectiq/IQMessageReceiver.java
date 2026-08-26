package com.garmin.android.connectiq;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;
import com.garmin.android.connectiq.ConnectIQ;
import com.garmin.android.connectiq.IQDevice;
import com.garmin.monkeybrains.serialization.MonkeyArray;
import com.garmin.monkeybrains.serialization.MonkeyHash;
import com.garmin.monkeybrains.serialization.MonkeyType;
import com.garmin.monkeybrains.serialization.Serializer;
import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;

/* JADX INFO: Access modifiers changed from: package-private */
/* loaded from: classes.dex */
public class IQMessageReceiver extends BroadcastReceiver {
    private static final int INVALID_APP_VERSION = 65535;
    private final HashMap<Long, IQDeviceListenerContainer> mDeviceListenerContainers = new HashMap<>();

    /* JADX INFO: Access modifiers changed from: package-private */
    public IQDeviceListenerContainer getDeviceListenerContainer(long j) {
        return this.mDeviceListenerContainers.get(Long.valueOf(j));
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    public void addDeviceListenerContainer(long j, IQDeviceListenerContainer iQDeviceListenerContainer) {
        this.mDeviceListenerContainers.put(Long.valueOf(j), iQDeviceListenerContainer);
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    public void clearDeviceAndAppListeners() {
        for (IQDeviceListenerContainer iQDeviceListenerContainer : this.mDeviceListenerContainers.values()) {
            iQDeviceListenerContainer.clearDeviceListener();
            iQDeviceListenerContainer.clearAppListeners();
        }
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    public void clearApiCallbackListeners() {
        for (IQDeviceListenerContainer iQDeviceListenerContainer : this.mDeviceListenerContainers.values()) {
            iQDeviceListenerContainer.clearApplicationInfoListeners();
            iQDeviceListenerContainer.clearOpenApplicationListeners();
            iQDeviceListenerContainer.clearSendMessageListeners();
        }
    }

    @Override // android.content.BroadcastReceiver
    public void onReceive(Context context, Intent intent) {
        IQDevice iQDevice;
        if (intent.getAction().equals(ConnectIQ.OPEN_APPLICATION)) {
            iQDevice = (IQDevice) intent.getParcelableExtra(ConnectIQ.EXTRA_OPEN_APPLICATION_DEVICE);
        } else {
            iQDevice = (IQDevice) intent.getParcelableExtra(ConnectIQ.EXTRA_REMOTE_DEVICE);
        }
        if (iQDevice == null) {
            return;
        }
        IQDeviceListenerContainer iQDeviceListenerContainer = this.mDeviceListenerContainers.get(Long.valueOf(iQDevice.getDeviceIdentifier()));
        ConnectIQ.IQDeviceEventListener iQDeviceEventListener = null;
        ConnectIQ.IQApplicationInfoListener iQApplicationInfoListener = null;
        ConnectIQ.IQOpenApplicationListener iQOpenApplicationListener = null;
        if (intent.getAction().equals(ConnectIQ.INCOMING_MESSAGE)) {
            IQApp iQApp = (IQApp) intent.getParcelableExtra(ConnectIQ.EXTRA_REMOTE_APPLICATION);
            byte[] byteArrayExtra = intent.getByteArrayExtra(ConnectIQ.EXTRA_PAYLOAD);
            ConnectIQ.IQApplicationEventListener appListener = iQDeviceListenerContainer != null ? iQDeviceListenerContainer.getAppListener(iQApp.getApplicationId()) : null;
            if (byteArrayExtra == null && appListener != null) {
                appListener.onMessageReceived(iQDevice, iQApp, null, ConnectIQ.IQMessageStatus.FAILURE_UNKNOWN);
            }
            try {
                List<MonkeyType<?>> deserialize = Serializer.deserialize(byteArrayExtra);
                ArrayList arrayList = new ArrayList();
                Iterator<MonkeyType<?>> it = deserialize.iterator();
                while (it.hasNext()) {
                    arrayList.add(convertToJava(it.next()));
                }
                if (appListener != null) {
                    appListener.onMessageReceived(iQDevice, iQApp, arrayList, ConnectIQ.IQMessageStatus.SUCCESS);
                    return;
                }
                return;
            } catch (UnsupportedEncodingException e) {
                Log.e("RemoteMessageReceiver", "Error deserializing message", e);
                if (appListener != null) {
                    appListener.onMessageReceived(iQDevice, iQApp, null, ConnectIQ.IQMessageStatus.FAILURE_INVALID_FORMAT);
                    return;
                }
                return;
            }
        }
        if (intent.getAction().equals(ConnectIQ.DEVICE_STATUS)) {
            int intExtra = intent.getIntExtra(ConnectIQ.EXTRA_STATUS, IQDevice.IQDeviceStatus.UNKNOWN.ordinal());
            IQDevice.IQDeviceStatus iQDeviceStatus = IQDevice.IQDeviceStatus.UNKNOWN;
            try {
                iQDeviceStatus = IQDevice.IQDeviceStatus.values()[intExtra];
            } catch (IndexOutOfBoundsException unused) {
            }
            if (iQDeviceListenerContainer != null) {
                iQDeviceEventListener = iQDeviceListenerContainer.getDeviceListener();
                if (iQDeviceStatus != IQDevice.IQDeviceStatus.CONNECTED) {
                    iQDeviceListenerContainer.clearApplicationInfoListeners();
                    iQDeviceListenerContainer.clearOpenApplicationListeners();
                    iQDeviceListenerContainer.clearSendMessageListeners();
                }
            }
            if (iQDeviceEventListener != null) {
                iQDeviceEventListener.onDeviceStatusChanged(iQDevice, iQDeviceStatus);
                return;
            }
            return;
        }
        if (intent.getAction().equals(ConnectIQ.APPLICATION_INFO)) {
            String stringExtra = intent.getStringExtra(ConnectIQ.EXTRA_APPLICATION_ID);
            int intExtra2 = intent.getIntExtra(ConnectIQ.EXTRA_APPLICATION_VERSION, 65535);
            if (iQDeviceListenerContainer != null && stringExtra != null) {
                iQApplicationInfoListener = iQDeviceListenerContainer.getApplicationInfoListener(stringExtra);
            }
            if (iQApplicationInfoListener != null) {
                if (intExtra2 >= 0 && 65535 != intExtra2) {
                    iQApplicationInfoListener.onApplicationInfoReceived(new IQApp(stringExtra, intExtra2));
                    return;
                } else {
                    iQApplicationInfoListener.onApplicationNotInstalled(stringExtra);
                    return;
                }
            }
            return;
        }
        if (intent.getAction().equals(ConnectIQ.OPEN_APPLICATION)) {
            String stringExtra2 = intent.getStringExtra(ConnectIQ.EXTRA_OPEN_APPLICATION_ID);
            int intExtra3 = intent.getIntExtra(ConnectIQ.EXTRA_OPEN_APPLICATION_RESULT_CODE, -1);
            if (iQDeviceListenerContainer != null && stringExtra2 != null) {
                iQOpenApplicationListener = iQDeviceListenerContainer.getOpenApplicationListener(stringExtra2);
            }
            if (iQOpenApplicationListener == null || intExtra3 < 0) {
                return;
            }
            iQOpenApplicationListener.onOpenApplicationResponse(iQDevice, new IQApp(stringExtra2), ConnectIQ.IQOpenApplicationStatus.fromInt(intExtra3));
            return;
        }
        if (intent.getAction().equals(ConnectIQ.SEND_MESSAGE_STATUS)) {
            int intExtra4 = intent.getIntExtra(ConnectIQ.EXTRA_STATUS, 0);
            String stringExtra3 = intent.getStringExtra(ConnectIQ.EXTRA_APPLICATION_ID);
            ConnectIQ.IQSendMessageListener sendMessageListener = iQDeviceListenerContainer != null ? iQDeviceListenerContainer.getSendMessageListener(stringExtra3) : null;
            if (sendMessageListener != null) {
                sendMessageListener.onMessageStatus(iQDevice, new IQApp(stringExtra3), intExtra4 == 0 ? ConnectIQ.IQMessageStatus.SUCCESS : ConnectIQ.IQMessageStatus.FAILURE_DURING_TRANSFER);
            }
        }
    }

    private Object convertToJava(MonkeyType<?> monkeyType) {
        byte b = monkeyType.mType;
        if (b != 1 && b != 2 && b != 3) {
            if (b == 5) {
                List<MonkeyType<?>> java = ((MonkeyArray) monkeyType).toJava();
                ArrayList arrayList = new ArrayList();
                Iterator<MonkeyType<?>> it = java.iterator();
                while (it.hasNext()) {
                    arrayList.add(convertToJava(it.next()));
                }
                return arrayList;
            }
            if (b != 9) {
                if (b == 11) {
                    HashMap<MonkeyType<?>, MonkeyType<?>> java2 = ((MonkeyHash) monkeyType).toJava();
                    HashMap hashMap = new HashMap();
                    for (MonkeyType<?> monkeyType2 : java2.keySet()) {
                        hashMap.put(convertToJava(monkeyType2), convertToJava(java2.get(monkeyType2)));
                    }
                    return hashMap;
                }
                if (b != 19 && b != 14 && b != 15) {
                    return null;
                }
            }
        }
        return monkeyType.toJava();
    }
}
