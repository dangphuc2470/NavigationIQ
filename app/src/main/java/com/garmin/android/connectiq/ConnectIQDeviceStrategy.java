package com.garmin.android.connectiq;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.pm.PackageManager;
import android.content.res.Resources;
import android.os.IBinder;
import android.os.RemoteException;
import com.garmin.android.apps.connectmobile.connectiq.IConnectIQService;
import com.garmin.android.connectiq.ConnectIQ;
import com.garmin.android.connectiq.IQDevice;
import com.garmin.android.connectiq.exception.InvalidStateException;
import com.garmin.android.connectiq.exception.ServiceUnavailableException;
import java.util.List;
import java.util.UUID;

/* loaded from: classes.dex */
public class ConnectIQDeviceStrategy extends ConnectIQ {
    private boolean mBound = false;
    private ServiceConnection mConnection = new ServiceConnection() { // from class: com.garmin.android.connectiq.ConnectIQDeviceStrategy.1
        @Override // android.content.ServiceConnection
        public void onServiceConnected(ComponentName componentName, IBinder iBinder) {
            ConnectIQDeviceStrategy.this.mRemoteService = IConnectIQService.Stub.asInterface(iBinder);
            ConnectIQDeviceStrategy.this.mBound = true;
            if (ConnectIQDeviceStrategy.this.mListener != null) {
                ConnectIQDeviceStrategy.this.mListener.onSdkReady();
            }
        }

        @Override // android.content.ServiceConnection
        public void onServiceDisconnected(ComponentName componentName) {
            ConnectIQDeviceStrategy.this.mRemoteService = null;
            ConnectIQDeviceStrategy.this.mBound = false;
            if (ConnectIQDeviceStrategy.this.mListener != null) {
                ConnectIQDeviceStrategy.this.mListener.onSdkShutDown();
            }
        }
    };
    private IConnectIQService mRemoteService;

    @Override // com.garmin.android.connectiq.ConnectIQ
    public void initialize(Context context, boolean z, ConnectIQ.ConnectIQListener connectIQListener) {
        String str;
        String str2;
        String str3;
        String str4;
        String str5 = "Cancel";
        super.initialize(context, z, connectIQListener);
        try {
            if (this.mContext.getPackageManager().getPackageInfo(GCM_PACKAGE_NAME, 0).versionCode < 9964) {
                if (this.mListener != null) {
                    this.mListener.onInitializeError(ConnectIQ.IQSdkErrorStatus.GCM_UPGRADE_NEEDED);
                }
                if (z) {
                    String packageName = this.mContext.getPackageName();
                    Resources resources = this.mContext.getResources();
                    int identifier = resources.getIdentifier("upgrade_needed_title", "string", packageName);
                    int identifier2 = resources.getIdentifier("upgrade_needed_message", "string", packageName);
                    int identifier3 = resources.getIdentifier("upgrade_cancel", "string", packageName);
                    int identifier4 = resources.getIdentifier("upgrade_yes", "string", packageName);
                    String str6 = "Upgrade Needed";
                    String str7 = "An upgrade to Garmin Connect Mobile is required to use this application. Would you like to upgrade now?";
                    String str8 = "Upgrade";
                    if (identifier != 0) {
                        str6 = this.mContext.getString(identifier);
                    }
                    if (identifier2 != 0) {
                        str7 = this.mContext.getString(identifier2);
                    }
                    if (identifier3 == 0) {
                        str4 = "Cancel";
                    } else {
                        str4 = this.mContext.getString(identifier3);
                    }
                    if (identifier4 != 0) {
                        str8 = this.mContext.getString(identifier4);
                    }
                    displayGCMDialog(str6, str7, str4, str8);
                    return;
                }
                return;
            }
            Intent intent = new Intent("com.garmin.android.apps.connectmobile.CONNECTIQ_SERVICE_ACTION");
            intent.setComponent(new ComponentName(GCM_PACKAGE_NAME, "com.garmin.android.apps.connectmobile.connectiq.ConnectIQService"));
            this.mContext.bindService(intent, this.mConnection, 1);
        } catch (PackageManager.NameNotFoundException unused) {
            if (z) {
                String packageName2 = this.mContext.getPackageName();
                Resources resources2 = this.mContext.getResources();
                int identifier5 = resources2.getIdentifier("install_needed_title", "string", packageName2);
                int identifier6 = resources2.getIdentifier("install_needed_message", "string", packageName2);
                int identifier7 = resources2.getIdentifier("install_cancel", "string", packageName2);
                int identifier8 = resources2.getIdentifier("install_yes", "string", packageName2);
                if (identifier5 == 0) {
                    str = "Additional App Required";
                } else {
                    str = this.mContext.getString(identifier5);
                }
                if (identifier6 == 0) {
                    str2 = "Garmin Connect Mobile is required to use this application. Would you like to install it now?";
                } else {
                    str2 = this.mContext.getString(identifier6);
                }
                if (identifier7 != 0) {
                    str5 = this.mContext.getString(identifier7);
                }
                if (identifier8 == 0) {
                    str3 = "Yes";
                } else {
                    str3 = this.mContext.getString(identifier8);
                }
                displayGCMDialog(str, str2, str5, str3);
            }
            if (this.mListener != null) {
                this.mListener.onInitializeError(ConnectIQ.IQSdkErrorStatus.GCM_NOT_INSTALLED);
            }
            super.initialize(context, z, connectIQListener);
        }
    }

    @Override // com.garmin.android.connectiq.ConnectIQ
    public void shutdown(Context context) throws InvalidStateException {
        super.shutdown(context);
        if (this.mBound) {
            this.mContext.unbindService(this.mConnection);
        }
    }

    @Override // com.garmin.android.connectiq.ConnectIQ
    public List<IQDevice> getConnectedDevices() throws InvalidStateException, ServiceUnavailableException {
        verifyInitialized();
        if (!this.mBound) {
            throw new InvalidStateException("SDK not initialized.  Did you forget to call ConnectIQ::initialize()?");
        }
        try {
            return this.mRemoteService.getConnectedDevices();
        } catch (RemoteException e) {
            throw new ServiceUnavailableException(e.getMessage());
        }
    }

    @Override // com.garmin.android.connectiq.ConnectIQ
    public List<IQDevice> getKnownDevices() throws InvalidStateException, ServiceUnavailableException {
        verifyInitialized();
        if (!this.mBound) {
            throw new InvalidStateException("SDK not initialized.  Did you forget to call ConnectIQ::initialize()?");
        }
        try {
            return this.mRemoteService.getKnownDevices();
        } catch (RemoteException e) {
            throw new ServiceUnavailableException(e.getMessage());
        }
    }

    @Override // com.garmin.android.connectiq.ConnectIQ
    public IQDevice.IQDeviceStatus getDeviceStatus(IQDevice iQDevice) throws InvalidStateException, ServiceUnavailableException {
        verifyInitialized();
        if (!this.mBound) {
            throw new InvalidStateException("SDK not initialized.  Did you forget to call ConnectIQ::initialize()?");
        }
        try {
            return IQDevice.IQDeviceStatus.values()[this.mRemoteService.getStatus(iQDevice)];
        } catch (RemoteException e) {
            throw new ServiceUnavailableException(e.getMessage());
        } catch (IndexOutOfBoundsException unused) {
            return IQDevice.IQDeviceStatus.UNKNOWN;
        }
    }

    @Override // com.garmin.android.connectiq.ConnectIQ
    protected void sendMessageProtocol(IQDevice iQDevice, IQApp iQApp, byte[] bArr, ConnectIQ.IQSendMessageListener iQSendMessageListener, boolean z) throws InvalidStateException, ServiceUnavailableException {
        verifyInitialized();
        if (!this.mBound) {
            throw new InvalidStateException("SDK not initialized.  Did you forget to call ConnectIQ::initialize()?");
        }
        if (iQDevice == null) {
            if (iQSendMessageListener != null) {
                iQSendMessageListener.onMessageStatus(iQDevice, iQApp, ConnectIQ.IQMessageStatus.FAILURE_INVALID_DEVICE);
                return;
            }
            return;
        }
        IQDeviceListenerContainer deviceListenerContainer = getMessageReceiver().getDeviceListenerContainer(iQDevice.getDeviceIdentifier());
        if (deviceListenerContainer != null) {
            deviceListenerContainer.setSendMessageListener(iQApp.getApplicationId(), iQSendMessageListener);
        } else {
            IQDeviceListenerContainer iQDeviceListenerContainer = new IQDeviceListenerContainer(iQDevice.getDeviceIdentifier());
            iQDeviceListenerContainer.setSendMessageListener(iQApp.getApplicationId(), iQSendMessageListener);
            getMessageReceiver().addDeviceListenerContainer(iQDevice.getDeviceIdentifier(), iQDeviceListenerContainer);
        }
        IQMessage iQMessage = new IQMessage(bArr, this.mContext.getPackageName(), ConnectIQ.SEND_MESSAGE_STATUS);
        try {
            if (z) {
                this.mRemoteService.sendTransientMessage(iQMessage, iQDevice, iQApp);
            } else {
                this.mRemoteService.sendMessage(iQMessage, iQDevice, iQApp);
            }
        } catch (RemoteException e) {
            throw new ServiceUnavailableException(e.getMessage());
        }
    }

    @Override // com.garmin.android.connectiq.ConnectIQ
    protected void sendImageProtocol(IQDevice iQDevice, IQApp iQApp, byte[] bArr, ConnectIQ.IQSendImageListener iQSendImageListener) {
        throw new UnsupportedOperationException();
    }

    @Override // com.garmin.android.connectiq.ConnectIQ
    public void getApplicationInfo(String str, IQDevice iQDevice, ConnectIQ.IQApplicationInfoListener iQApplicationInfoListener) throws InvalidStateException, ServiceUnavailableException {
        verifyInitialized();
        String replaceAll = str.toUpperCase().replaceAll("[\\s\\-]", "");
        if (!this.mBound) {
            throw new InvalidStateException("SDK not initialized.  Did you forget to call ConnectIQ::initialize()?");
        }
        if (iQDevice == null) {
            if (iQApplicationInfoListener != null) {
                iQApplicationInfoListener.onApplicationNotInstalled(replaceAll);
                return;
            }
            return;
        }
        IQDeviceListenerContainer deviceListenerContainer = getMessageReceiver().getDeviceListenerContainer(iQDevice.getDeviceIdentifier());
        if (deviceListenerContainer != null) {
            deviceListenerContainer.setApplicationInfoListener(replaceAll, iQApplicationInfoListener);
        } else {
            IQDeviceListenerContainer iQDeviceListenerContainer = new IQDeviceListenerContainer(iQDevice.getDeviceIdentifier());
            iQDeviceListenerContainer.setApplicationInfoListener(replaceAll, iQApplicationInfoListener);
            getMessageReceiver().addDeviceListenerContainer(iQDevice.getDeviceIdentifier(), iQDeviceListenerContainer);
        }
        try {
            this.mRemoteService.getApplicationInfo(this.mContext.getPackageName(), ConnectIQ.APPLICATION_INFO, iQDevice, replaceAll);
        } catch (RemoteException e) {
            throw new ServiceUnavailableException(e.getMessage());
        }
    }

    @Override // com.garmin.android.connectiq.ConnectIQ
    public void openApplication(IQDevice iQDevice, IQApp iQApp, ConnectIQ.IQOpenApplicationListener iQOpenApplicationListener) throws InvalidStateException, ServiceUnavailableException {
        verifyInitialized();
        if (!this.mBound) {
            throw new InvalidStateException("SDK not initialized.  Did you forget to call ConnectIQ::initialize()?");
        }
        if (iQDevice == null) {
            if (iQOpenApplicationListener != null) {
                iQOpenApplicationListener.onOpenApplicationResponse(iQDevice, iQApp, ConnectIQ.IQOpenApplicationStatus.APP_IS_NOT_INSTALLED);
                return;
            }
            return;
        }
        IQDeviceListenerContainer deviceListenerContainer = getMessageReceiver().getDeviceListenerContainer(iQDevice.getDeviceIdentifier());
        if (deviceListenerContainer != null) {
            deviceListenerContainer.setOpenApplicationListener(iQApp.getApplicationId(), iQOpenApplicationListener);
        } else {
            IQDeviceListenerContainer iQDeviceListenerContainer = new IQDeviceListenerContainer(iQDevice.getDeviceIdentifier());
            iQDeviceListenerContainer.setOpenApplicationListener(iQApp.getApplicationId(), iQOpenApplicationListener);
            getMessageReceiver().addDeviceListenerContainer(iQDevice.getDeviceIdentifier(), iQDeviceListenerContainer);
        }
        try {
            this.mRemoteService.openApplication(this.mContext.getPackageName(), ConnectIQ.OPEN_APPLICATION, iQDevice, iQApp);
        } catch (RemoteException e) {
            throw new ServiceUnavailableException(e.getMessage());
        }
    }

    @Override // com.garmin.android.connectiq.ConnectIQ
    public String getDevicePartNumber(IQDevice iQDevice) throws InvalidStateException, ServiceUnavailableException, IllegalArgumentException {
        verifyInitialized();
        if (!this.mBound) {
            throw new InvalidStateException("SDK not initialized.  Did you forget to call ConnectIQ::initialize()?");
        }
        if (iQDevice == null) {
            throw new IllegalArgumentException("Device cannot be null");
        }
        try {
            return this.mRemoteService.getPartNumber(iQDevice);
        } catch (RemoteException e) {
            throw new ServiceUnavailableException(e.getMessage());
        }
    }

    @Override // com.garmin.android.connectiq.ConnectIQ
    protected void registerForRemoteAppEvents(IQDevice iQDevice, IQApp iQApp) throws InvalidStateException, ServiceUnavailableException {
        verifyInitialized();
        if (!this.mBound) {
            throw new InvalidStateException("SDK not initialized.  Did you forget to call ConnectIQ::initialize()?");
        }
        try {
            this.mRemoteService.registerApp(iQApp, ConnectIQ.INCOMING_MESSAGE, this.mContext.getPackageName());
        } catch (RemoteException e) {
            throw new ServiceUnavailableException(e.getMessage());
        }
    }

    @Override // com.garmin.android.connectiq.ConnectIQ
    public boolean openStore(String str) throws IllegalArgumentException, InvalidStateException, ServiceUnavailableException {
        verifyInitialized();
        if (!this.mBound) {
            throw new InvalidStateException("SDK not initialized.  Did you forget to call ConnectIQ::initialize()?");
        }
        try {
            if (str != null && !str.isEmpty()) {
                if (!str.contains("-")) {
                    str = str.replaceAll("(\\w{8})(\\w{4})(\\w{4})(\\w{4})(\\w{12})", "$1-$2-$3-$4-$5");
                }
                return this.mRemoteService.openStore(UUID.fromString(str).toString());
            }
            return this.mRemoteService.openStore(null);
        } catch (RemoteException e) {
            throw new ServiceUnavailableException(e.getMessage());
        }
    }
}
