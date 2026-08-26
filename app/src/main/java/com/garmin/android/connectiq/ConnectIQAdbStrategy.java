package com.garmin.android.connectiq;

import android.content.Context;
import com.garmin.android.connectiq.ConnectIQ;
import com.garmin.android.connectiq.IQDevice;
import com.garmin.android.connectiq.adb.AdbConnection;
import com.garmin.android.connectiq.exception.InvalidStateException;
import com.garmin.android.connectiq.exception.ServiceUnavailableException;
import java.util.ArrayList;
import java.util.List;

/* loaded from: classes.dex */
public class ConnectIQAdbStrategy extends ConnectIQ {
    private AdbConnection.AdbConnectionListener connListener = new AdbConnection.AdbConnectionListener() { // from class: com.garmin.android.connectiq.ConnectIQAdbStrategy.1
        @Override // com.garmin.android.connectiq.adb.AdbConnection.AdbConnectionListener
        public void onConnectionStatusChanged(IQDevice iQDevice, IQDevice.IQDeviceStatus iQDeviceStatus) {
            ConnectIQAdbStrategy.this.deviceStatusChanged(iQDevice, iQDeviceStatus);
        }
    };

    @Override // com.garmin.android.connectiq.ConnectIQ
    protected void registerForRemoteAppEvents(IQDevice iQDevice, IQApp iQApp) {
    }

    @Override // com.garmin.android.connectiq.ConnectIQ
    public void initialize(Context context, boolean z, ConnectIQ.ConnectIQListener connectIQListener) {
        super.initialize(context, z, connectIQListener);
        AdbConnection adbConnection = AdbConnection.getInstance();
        adbConnection.setContext(context);
        if (!adbConnection.isActive()) {
            adbConnection.establishConnection(this.connListener);
        }
        if (connectIQListener != null) {
            connectIQListener.onSdkReady();
        }
    }

    @Override // com.garmin.android.connectiq.ConnectIQ
    public List<IQDevice> getConnectedDevices() throws InvalidStateException {
        verifyInitialized();
        if (AdbConnection.getInstance().isConnected()) {
            ArrayList arrayList = new ArrayList(1);
            arrayList.add(new IQDevice(12345L, "Simulator"));
            return arrayList;
        }
        return new ArrayList();
    }

    @Override // com.garmin.android.connectiq.ConnectIQ
    public List<IQDevice> getKnownDevices() throws InvalidStateException {
        verifyInitialized();
        ArrayList arrayList = new ArrayList(1);
        arrayList.add(new IQDevice(12345L, "Simulator"));
        return arrayList;
    }

    @Override // com.garmin.android.connectiq.ConnectIQ
    public IQDevice.IQDeviceStatus getDeviceStatus(IQDevice iQDevice) throws InvalidStateException, ServiceUnavailableException {
        verifyInitialized();
        IQDevice.IQDeviceStatus iQDeviceStatus = IQDevice.IQDeviceStatus.UNKNOWN;
        if (AdbConnection.getInstance().isConnected()) {
            return IQDevice.IQDeviceStatus.CONNECTED;
        }
        return IQDevice.IQDeviceStatus.NOT_CONNECTED;
    }

    @Override // com.garmin.android.connectiq.ConnectIQ
    public void getApplicationInfo(String str, IQDevice iQDevice, ConnectIQ.IQApplicationInfoListener iQApplicationInfoListener) throws InvalidStateException, ServiceUnavailableException {
        verifyInitialized();
        if (!AdbConnection.getInstance().isConnected()) {
            throw new InvalidStateException("SDK not initialized. Did you forget to call ConnectIQ::initialize()?");
        }
        if (iQDevice == null && iQApplicationInfoListener != null) {
            iQApplicationInfoListener.onApplicationNotInstalled(str);
        } else {
            iQApplicationInfoListener.onApplicationInfoReceived(new IQApp(str));
        }
    }

    @Override // com.garmin.android.connectiq.ConnectIQ
    public void openApplication(IQDevice iQDevice, IQApp iQApp, ConnectIQ.IQOpenApplicationListener iQOpenApplicationListener) throws InvalidStateException {
        verifyInitialized();
        if (!AdbConnection.getInstance().isConnected()) {
            throw new InvalidStateException("SDK not initialized. Did you forget to call ConnectIQ::initialize()?");
        }
        if (iQDevice != null && iQOpenApplicationListener != null) {
            iQOpenApplicationListener.onOpenApplicationResponse(iQDevice, iQApp, ConnectIQ.IQOpenApplicationStatus.APP_IS_NOT_INSTALLED);
        } else {
            iQOpenApplicationListener.onOpenApplicationResponse(iQDevice, iQApp, ConnectIQ.IQOpenApplicationStatus.PROMPT_NOT_SHOWN_ON_DEVICE);
        }
    }

    @Override // com.garmin.android.connectiq.ConnectIQ
    public String getDevicePartNumber(IQDevice iQDevice) throws InvalidStateException, ServiceUnavailableException {
        verifyInitialized();
        if (AdbConnection.getInstance().isConnected()) {
            return "SIMULATOR-PART-NUMBER";
        }
        return null;
    }

    @Override // com.garmin.android.connectiq.ConnectIQ
    protected void sendMessageProtocol(IQDevice iQDevice, IQApp iQApp, byte[] bArr, ConnectIQ.IQSendMessageListener iQSendMessageListener, boolean z) {
        if (AdbConnection.getInstance().sendMessage(bArr)) {
            if (iQSendMessageListener != null) {
                iQSendMessageListener.onMessageStatus(iQDevice, iQApp, ConnectIQ.IQMessageStatus.SUCCESS);
            }
        } else if (iQSendMessageListener != null) {
            iQSendMessageListener.onMessageStatus(iQDevice, iQApp, ConnectIQ.IQMessageStatus.FAILURE_UNKNOWN);
        }
    }

    @Override // com.garmin.android.connectiq.ConnectIQ
    protected void sendImageProtocol(IQDevice iQDevice, IQApp iQApp, byte[] bArr, ConnectIQ.IQSendImageListener iQSendImageListener) {
        throw new UnsupportedOperationException();
    }
}
