package com.garmin.android.connectiq;

import android.app.AlertDialog;
import android.content.ActivityNotFoundException;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import com.garmin.android.connectiq.IQDevice;
import com.garmin.android.connectiq.adb.AdbConnection;
import com.garmin.android.connectiq.exception.InvalidStateException;
import com.garmin.android.connectiq.exception.ServiceUnavailableException;
import com.garmin.monkeybrains.serialization.Serializer;
import java.util.List;

/* loaded from: classes.dex */
public abstract class ConnectIQ {
    public static final String APPLICATION_INFO = "com.garmin.android.connectiq.APPLICATION_INFO";
    public static final String DEVICE_STATUS = "com.garmin.android.connectiq.DEVICE_STATUS";
    public static final String EXTRA_APPLICATION_ID = "com.garmin.android.connectiq.EXTRA_APPLICATION_ID";
    public static final String EXTRA_APPLICATION_VERSION = "com.garmin.android.connectiq.EXTRA_APPLICATION_VERSION";
    public static final String EXTRA_OPEN_APPLICATION_DEVICE = "com.garmin.android.connectiq.EXTRA_OPEN_APPLICATION_DEVICE";
    public static final String EXTRA_OPEN_APPLICATION_ID = "com.garmin.android.connectiq.EXTRA_OPEN_APPLICATION_ID";
    public static final String EXTRA_OPEN_APPLICATION_RESULT_CODE = "com.garmin.android.connectiq.EXTRA_OPEN_APPLICATION_RESULT_CODE";
    public static final String EXTRA_PAYLOAD = "com.garmin.android.connectiq.EXTRA_PAYLOAD";
    public static final String EXTRA_REMOTE_APPLICATION = "com.garmin.android.connectiq.EXTRA_REMOTE_APPLICATION";
    public static final String EXTRA_REMOTE_DEVICE = "com.garmin.android.connectiq.EXTRA_REMOTE_DEVICE";
    public static final String EXTRA_STATUS = "com.garmin.android.connectiq.EXTRA_STATUS";
    protected static final String GCM_CONNECTIQ_SERVICE_ACTION = "com.garmin.android.apps.connectmobile.CONNECTIQ_SERVICE_ACTION";
    protected static final String GCM_CONNECTIQ_SERVICE_CLASS = "com.garmin.android.apps.connectmobile.connectiq.ConnectIQService";
    protected static final String GCM_PACKAGE_NAME = "com.garmin.android.apps.connectmobile";
    public static final String INCOMING_MESSAGE = "com.garmin.android.connectiq.INCOMING_MESSAGE";
    protected static final int MIN_GCM_VERSION = 9964;
    public static final String OPEN_APPLICATION = "com.garmin.android.connectiq.OPEN_APPLICATION";
    public static final String SEND_MESSAGE_STATUS = "com.garmin.android.connectiq.SEND_MESSAGE_STATUS";
    protected static IQConnectType sConnectType = IQConnectType.WIRELESS;
    protected static ConnectIQ sInstance;
    protected Context mContext;
    private Handler mHandler;
    protected boolean mInitialized = false;
    protected ConnectIQListener mListener;
    private IQMessageReceiver mMessageReceiver;

    /* loaded from: classes.dex */
    public interface ConnectIQListener {
        void onInitializeError(IQSdkErrorStatus iQSdkErrorStatus);

        void onSdkReady();

        void onSdkShutDown();
    }

    /* loaded from: classes.dex */
    public interface IQApplicationEventListener {
        void onMessageReceived(IQDevice iQDevice, IQApp iQApp, List<Object> list, IQMessageStatus iQMessageStatus);
    }

    /* loaded from: classes.dex */
    public interface IQApplicationInfoListener {
        void onApplicationInfoReceived(IQApp iQApp);

        void onApplicationNotInstalled(String str);
    }

    /* loaded from: classes.dex */
    public enum IQConnectType {
        TETHERED,
        WIRELESS
    }

    /* loaded from: classes.dex */
    public interface IQDeviceEventListener {
        void onDeviceStatusChanged(IQDevice iQDevice, IQDevice.IQDeviceStatus iQDeviceStatus);
    }

    /* loaded from: classes.dex */
    public enum IQMessageStatus {
        SUCCESS,
        FAILURE_UNKNOWN,
        FAILURE_INVALID_FORMAT,
        FAILURE_MESSAGE_TOO_LARGE,
        FAILURE_UNSUPPORTED_TYPE,
        FAILURE_DURING_TRANSFER,
        FAILURE_INVALID_DEVICE,
        FAILURE_DEVICE_NOT_CONNECTED
    }

    /* loaded from: classes.dex */
    public interface IQOpenApplicationListener {
        void onOpenApplicationResponse(IQDevice iQDevice, IQApp iQApp, IQOpenApplicationStatus iQOpenApplicationStatus);
    }

    /* loaded from: classes.dex */
    public enum IQSdkErrorStatus {
        GCM_NOT_INSTALLED,
        GCM_UPGRADE_NEEDED,
        SERVICE_ERROR
    }

    /* loaded from: classes.dex */
    public interface IQSendImageListener {
        void onImageStatus(IQDevice iQDevice, IQApp iQApp, IQMessageStatus iQMessageStatus);
    }

    /* loaded from: classes.dex */
    public interface IQSendMessageListener {
        void onMessageStatus(IQDevice iQDevice, IQApp iQApp, IQMessageStatus iQMessageStatus);
    }

    public abstract List<IQDevice> getConnectedDevices() throws InvalidStateException, ServiceUnavailableException;

    public abstract String getDevicePartNumber(IQDevice iQDevice) throws InvalidStateException, ServiceUnavailableException, IllegalArgumentException;

    public abstract IQDevice.IQDeviceStatus getDeviceStatus(IQDevice iQDevice) throws InvalidStateException, ServiceUnavailableException;

    public abstract List<IQDevice> getKnownDevices() throws InvalidStateException, ServiceUnavailableException;

    protected abstract void registerForRemoteAppEvents(IQDevice iQDevice, IQApp iQApp) throws InvalidStateException, ServiceUnavailableException;

    protected abstract void sendImageProtocol(IQDevice iQDevice, IQApp iQApp, byte[] bArr, IQSendImageListener iQSendImageListener) throws InvalidStateException, ServiceUnavailableException;

    protected abstract void sendMessageProtocol(IQDevice iQDevice, IQApp iQApp, byte[] bArr, IQSendMessageListener iQSendMessageListener, boolean z) throws InvalidStateException, ServiceUnavailableException;

    /* loaded from: classes.dex */
    public enum IQOpenApplicationStatus {
        PROMPT_SHOWN_ON_DEVICE,
        PROMPT_NOT_SHOWN_ON_DEVICE,
        APP_IS_NOT_INSTALLED,
        APP_IS_ALREADY_RUNNING,
        UNKNOWN_FAILURE;

        public static IQOpenApplicationStatus fromInt(int i) {
            if (i < values().length - 1) {
                return values()[i];
            }
            return UNKNOWN_FAILURE;
        }
    }

    public static ConnectIQ getInstance() {
        if (sInstance == null) {
            if (sConnectType.ordinal() == 0) {
                sInstance = new ConnectIQAdbStrategy();
            } else {
                sInstance = new ConnectIQDeviceStrategy();
            }
        }
        return sInstance;
    }

    public static ConnectIQ getInstance(Context context, IQConnectType iQConnectType) {
        ConnectIQ connectIQ = sInstance;
        if (connectIQ != null && sConnectType != iQConnectType) {
            try {
                connectIQ.shutdown(context);
            } catch (InvalidStateException unused) {
            }
            sInstance = null;
        }
        sConnectType = iQConnectType;
        return getInstance();
    }

    public void setAdbPort(int i) throws IllegalArgumentException {
        if (i < 1025 || i > 65535) {
            throw new IllegalArgumentException("Invalid port number.  Must be between 1025 - 65535");
        }
        AdbConnection.getInstance().setPort(i);
    }

    public int getAdbPort() {
        return AdbConnection.getInstance().getPort();
    }

    public void initialize(Context context, boolean z, ConnectIQListener connectIQListener) {
        this.mContext = context;
        this.mListener = connectIQListener;
        this.mHandler = new Handler(Looper.getMainLooper());
        this.mMessageReceiver = new IQMessageReceiver();
        IntentFilter intentFilter = new IntentFilter();
        intentFilter.addAction(APPLICATION_INFO);
        intentFilter.addAction(OPEN_APPLICATION);
        intentFilter.addAction(SEND_MESSAGE_STATUS);
        intentFilter.addAction(DEVICE_STATUS);
        intentFilter.addAction(INCOMING_MESSAGE);
        if (Build.VERSION.SDK_INT >= 33) {
            context.registerReceiver(this.mMessageReceiver, intentFilter, 2);
        } else {
            context.registerReceiver(this.mMessageReceiver, intentFilter);
        }
        this.mInitialized = true;
    }

    public void shutdown(Context context) throws InvalidStateException {
        unregisterAllForEvents();
        this.mMessageReceiver.clearApiCallbackListeners();
        ConnectIQListener connectIQListener = this.mListener;
        if (connectIQListener != null) {
            connectIQListener.onSdkShutDown();
        }
        context.unregisterReceiver(this.mMessageReceiver);
        this.mMessageReceiver = null;
        this.mInitialized = false;
    }

    /* JADX INFO: Access modifiers changed from: protected */
    public void displayGCMDialog(final String str, final String str2, final String str3, final String str4) {
        Handler handler = this.mHandler;
        if (handler != null) {
            handler.post(new Runnable() { // from class: com.garmin.android.connectiq.ConnectIQ.1
                @Override // java.lang.Runnable
                public void run() {
                    AlertDialog.Builder builder = new AlertDialog.Builder(ConnectIQ.this.mContext);
                    builder.setTitle(str).setMessage(str2).setNegativeButton(str3, (DialogInterface.OnClickListener) null).setPositiveButton(str4, new DialogInterface.OnClickListener() { // from class: com.garmin.android.connectiq.ConnectIQ.1.1
                        @Override // android.content.DialogInterface.OnClickListener
                        public void onClick(DialogInterface dialogInterface, int i) {
                            try {
                                ConnectIQ.this.mContext.startActivity(new Intent("android.intent.action.VIEW", Uri.parse("market://details?id=com.garmin.android.apps.connectmobile")));
                            } catch (ActivityNotFoundException unused) {
                                ConnectIQ.this.mContext.startActivity(new Intent("android.intent.action.VIEW", Uri.parse("https://play.google.com/store/apps/details?id=com.garmin.android.apps.connectmobile")));
                            }
                        }
                    });
                    builder.create().show();
                }
            });
        }
    }

    public void registerForEvents(IQDevice iQDevice, IQDeviceEventListener iQDeviceEventListener, IQApp iQApp, IQApplicationEventListener iQApplicationEventListener) throws InvalidStateException {
        verifyInitialized();
        registerForDeviceEvents(iQDevice, iQDeviceEventListener);
        registerForAppEvents(iQDevice, iQApp, iQApplicationEventListener);
    }

    public void registerForDeviceEvents(IQDevice iQDevice, IQDeviceEventListener iQDeviceEventListener) throws InvalidStateException {
        verifyInitialized();
        IQDeviceListenerContainer deviceListenerContainer = this.mMessageReceiver.getDeviceListenerContainer(iQDevice.getDeviceIdentifier());
        if (deviceListenerContainer == null) {
            IQDeviceListenerContainer iQDeviceListenerContainer = new IQDeviceListenerContainer(iQDevice.getDeviceIdentifier());
            iQDeviceListenerContainer.setDeviceListener(iQDeviceEventListener);
            this.mMessageReceiver.addDeviceListenerContainer(iQDevice.getDeviceIdentifier(), iQDeviceListenerContainer);
            if (iQDeviceEventListener != null) {
                IQDevice.IQDeviceStatus iQDeviceStatus = IQDevice.IQDeviceStatus.UNKNOWN;
                try {
                    iQDeviceStatus = getDeviceStatus(iQDevice);
                } catch (InvalidStateException unused) {
                } catch (ServiceUnavailableException unused2) {
                    iQDeviceStatus = IQDevice.IQDeviceStatus.NOT_CONNECTED;
                }
                iQDeviceEventListener.onDeviceStatusChanged(iQDevice, iQDeviceStatus);
                return;
            }
            return;
        }
        if (deviceListenerContainer.getDeviceListener() != iQDeviceEventListener) {
            deviceListenerContainer.setDeviceListener(iQDeviceEventListener);
        }
    }

    public void registerForAppEvents(IQDevice iQDevice, IQApp iQApp, IQApplicationEventListener iQApplicationEventListener) throws InvalidStateException {
        verifyInitialized();
        try {
            registerForRemoteAppEvents(iQDevice, iQApp);
        } catch (InvalidStateException | ServiceUnavailableException unused) {
        }
        String str = iQDevice.getDeviceIdentifier() + "";
        IQDeviceListenerContainer deviceListenerContainer = this.mMessageReceiver.getDeviceListenerContainer(iQDevice.getDeviceIdentifier());
        if (deviceListenerContainer == null) {
            IQDeviceListenerContainer iQDeviceListenerContainer = new IQDeviceListenerContainer(iQDevice.getDeviceIdentifier());
            iQDeviceListenerContainer.setAppListener(iQApp.getApplicationId(), iQApplicationEventListener);
            this.mMessageReceiver.addDeviceListenerContainer(iQDevice.getDeviceIdentifier(), iQDeviceListenerContainer);
        } else if (deviceListenerContainer.getAppListener(iQApp.getApplicationId()) != iQApplicationEventListener) {
            deviceListenerContainer.setAppListener(iQApp.getApplicationId(), iQApplicationEventListener);
        }
    }

    public void unregisterAllForEvents() throws InvalidStateException {
        verifyInitialized();
        this.mMessageReceiver.clearDeviceAndAppListeners();
    }

    public void unregisterForEvents(IQDevice iQDevice) throws InvalidStateException {
        verifyInitialized();
        IQDeviceListenerContainer deviceListenerContainer = this.mMessageReceiver.getDeviceListenerContainer(iQDevice.getDeviceIdentifier());
        if (deviceListenerContainer != null) {
            deviceListenerContainer.clearDeviceListener();
            deviceListenerContainer.clearAppListeners();
        }
    }

    public void unregisterForDeviceEvents(IQDevice iQDevice) throws InvalidStateException {
        verifyInitialized();
        IQDeviceListenerContainer deviceListenerContainer = this.mMessageReceiver.getDeviceListenerContainer(iQDevice.getDeviceIdentifier());
        if (deviceListenerContainer != null) {
            deviceListenerContainer.clearDeviceListener();
        }
    }

    public void unregisterForApplicationEvents(IQDevice iQDevice, IQApp iQApp) throws InvalidStateException {
        verifyInitialized();
        IQDeviceListenerContainer deviceListenerContainer = this.mMessageReceiver.getDeviceListenerContainer(iQDevice.getDeviceIdentifier());
        if (deviceListenerContainer != null) {
            deviceListenerContainer.setAppListener(iQApp.getApplicationId(), null);
        }
    }

    public boolean openStore(String str) throws IllegalArgumentException, InvalidStateException, ServiceUnavailableException {
        throw new UnsupportedOperationException();
    }

    public void getApplicationInfo(String str, IQDevice iQDevice, IQApplicationInfoListener iQApplicationInfoListener) throws InvalidStateException, ServiceUnavailableException {
        throw new UnsupportedOperationException();
    }

    public void openApplication(IQDevice iQDevice, IQApp iQApp, IQOpenApplicationListener iQOpenApplicationListener) throws InvalidStateException, ServiceUnavailableException {
        throw new UnsupportedOperationException();
    }

    public void sendMessage(IQDevice iQDevice, IQApp iQApp, Object obj, IQSendMessageListener iQSendMessageListener) throws InvalidStateException, ServiceUnavailableException {
        byte[] bArr;
        verifyInitialized();
        try {
            bArr = Serializer.serialize(obj);
        } catch (Exception unused) {
            if (iQSendMessageListener != null) {
                iQSendMessageListener.onMessageStatus(iQDevice, iQApp, IQMessageStatus.FAILURE_INVALID_FORMAT);
            }
            bArr = null;
        }
        byte[] bArr2 = bArr;
        if (bArr2 != null) {
            sendMessage(iQDevice, iQApp, bArr2, iQSendMessageListener, false);
        }
    }

    public void sendMessage(IQDevice iQDevice, IQApp iQApp, Object obj, IQSendMessageListener iQSendMessageListener, boolean z) throws InvalidStateException, ServiceUnavailableException {
        byte[] bArr;
        verifyInitialized();
        try {
            bArr = Serializer.serialize(obj);
        } catch (Exception unused) {
            if (iQSendMessageListener != null) {
                iQSendMessageListener.onMessageStatus(iQDevice, iQApp, IQMessageStatus.FAILURE_INVALID_FORMAT);
            }
            bArr = null;
        }
        byte[] bArr2 = bArr;
        if (bArr2 != null) {
            sendMessage(iQDevice, iQApp, bArr2, iQSendMessageListener, z);
        }
    }

    private void sendMessage(IQDevice iQDevice, IQApp iQApp, byte[] bArr, IQSendMessageListener iQSendMessageListener, boolean z) throws InvalidStateException, ServiceUnavailableException {
        if (bArr.length > 16384 && iQSendMessageListener != null) {
            iQSendMessageListener.onMessageStatus(iQDevice, iQApp, IQMessageStatus.FAILURE_MESSAGE_TOO_LARGE);
        }
        sendMessageProtocol(iQDevice, iQApp, bArr, iQSendMessageListener, z);
    }

    /* JADX INFO: Access modifiers changed from: protected */
    public void deviceStatusChanged(final IQDevice iQDevice, final IQDevice.IQDeviceStatus iQDeviceStatus) {
        Handler handler = this.mHandler;
        if (handler != null) {
            handler.post(new Runnable() { // from class: com.garmin.android.connectiq.ConnectIQ.2
                @Override // java.lang.Runnable
                public void run() {
                    IQDeviceEventListener deviceListener;
                    if (ConnectIQ.this.mMessageReceiver == null) {
                        return;
                    }
                    IQDeviceListenerContainer deviceListenerContainer = ConnectIQ.this.mMessageReceiver.getDeviceListenerContainer(iQDevice.getDeviceIdentifier());
                    if (deviceListenerContainer == null || (deviceListener = deviceListenerContainer.getDeviceListener()) == null) {
                        return;
                    }
                    deviceListener.onDeviceStatusChanged(iQDevice, iQDeviceStatus);
                }
            });
        }
    }

    /* JADX INFO: Access modifiers changed from: protected */
    public void verifyInitialized() throws InvalidStateException {
        if (!this.mInitialized) {
            throw new InvalidStateException("SDK not initialized");
        }
    }

    /* JADX INFO: Access modifiers changed from: protected */
    public final IQMessageReceiver getMessageReceiver() {
        return this.mMessageReceiver;
    }
}
