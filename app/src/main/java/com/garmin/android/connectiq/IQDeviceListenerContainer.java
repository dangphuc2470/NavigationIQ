package com.garmin.android.connectiq;

import com.garmin.android.connectiq.ConnectIQ;
import java.util.HashMap;

/* JADX INFO: Access modifiers changed from: package-private */
/* loaded from: classes.dex */
public class IQDeviceListenerContainer {
    private final long deviceIdentifier;
    private final HashMap<String, ConnectIQ.IQApplicationInfoListener> appInfoListeners = new HashMap<>();
    private final HashMap<String, ConnectIQ.IQOpenApplicationListener> openApplicationListeners = new HashMap<>();
    private final HashMap<String, ConnectIQ.IQSendMessageListener> sendMessageListeners = new HashMap<>();
    private ConnectIQ.IQDeviceEventListener deviceListener = null;
    private final HashMap<String, ConnectIQ.IQApplicationEventListener> appListeners = new HashMap<>();

    /* JADX INFO: Access modifiers changed from: package-private */
    public IQDeviceListenerContainer(long j) {
        this.deviceIdentifier = j;
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    public void setApplicationInfoListener(String str, ConnectIQ.IQApplicationInfoListener iQApplicationInfoListener) {
        this.appInfoListeners.put(str, iQApplicationInfoListener);
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    public ConnectIQ.IQApplicationInfoListener getApplicationInfoListener(String str) {
        return this.appInfoListeners.get(str);
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    public void setOpenApplicationListener(String str, ConnectIQ.IQOpenApplicationListener iQOpenApplicationListener) {
        this.openApplicationListeners.put(str, iQOpenApplicationListener);
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    public ConnectIQ.IQOpenApplicationListener getOpenApplicationListener(String str) {
        return this.openApplicationListeners.get(str);
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    public void setSendMessageListener(String str, ConnectIQ.IQSendMessageListener iQSendMessageListener) {
        this.sendMessageListeners.put(str, iQSendMessageListener);
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    public ConnectIQ.IQSendMessageListener getSendMessageListener(String str) {
        return this.sendMessageListeners.get(str);
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    public void setDeviceListener(ConnectIQ.IQDeviceEventListener iQDeviceEventListener) {
        this.deviceListener = iQDeviceEventListener;
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    public ConnectIQ.IQDeviceEventListener getDeviceListener() {
        return this.deviceListener;
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    public void setAppListener(String str, ConnectIQ.IQApplicationEventListener iQApplicationEventListener) {
        this.appListeners.put(str, iQApplicationEventListener);
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    public ConnectIQ.IQApplicationEventListener getAppListener(String str) {
        return this.appListeners.get(str);
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    public void clearApplicationInfoListeners() {
        this.appInfoListeners.clear();
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    public void clearOpenApplicationListeners() {
        this.openApplicationListeners.clear();
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    public void clearSendMessageListeners() {
        this.sendMessageListeners.clear();
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    public void clearDeviceListener() {
        this.deviceListener = null;
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    public void clearAppListeners() {
        this.appListeners.clear();
    }
}
