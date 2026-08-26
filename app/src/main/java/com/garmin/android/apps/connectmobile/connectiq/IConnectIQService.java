package com.garmin.android.apps.connectmobile.connectiq;

import android.os.Binder;
import android.os.IBinder;
import android.os.IInterface;
import android.os.Parcel;
import android.os.Parcelable;
import android.os.RemoteException;
import com.garmin.android.connectiq.IQApp;
import com.garmin.android.connectiq.IQDevice;
import com.garmin.android.connectiq.IQMessage;
import java.util.List;

/* loaded from: classes.dex */
public interface IConnectIQService extends IInterface {
    public static final String DESCRIPTOR = "com.garmin.android.apps.connectmobile.connectiq.IConnectIQService";

    /* loaded from: classes.dex */
    public static class Default implements IConnectIQService {
        @Override // android.os.IInterface
        public IBinder asBinder() {
            return null;
        }

        @Override // com.garmin.android.apps.connectmobile.connectiq.IConnectIQService
        public void getApplicationInfo(String str, String str2, IQDevice iQDevice, String str3) throws RemoteException {
        }

        @Override // com.garmin.android.apps.connectmobile.connectiq.IConnectIQService
        public List<IQDevice> getConnectedDevices() throws RemoteException {
            return null;
        }

        @Override // com.garmin.android.apps.connectmobile.connectiq.IConnectIQService
        public List<IQDevice> getKnownDevices() throws RemoteException {
            return null;
        }

        @Override // com.garmin.android.apps.connectmobile.connectiq.IConnectIQService
        public String getPartNumber(IQDevice iQDevice) throws RemoteException {
            return null;
        }

        @Override // com.garmin.android.apps.connectmobile.connectiq.IConnectIQService
        public int getStatus(IQDevice iQDevice) throws RemoteException {
            return 0;
        }

        @Override // com.garmin.android.apps.connectmobile.connectiq.IConnectIQService
        public void openApplication(String str, String str2, IQDevice iQDevice, IQApp iQApp) throws RemoteException {
        }

        @Override // com.garmin.android.apps.connectmobile.connectiq.IConnectIQService
        public boolean openStore(String str) throws RemoteException {
            return false;
        }

        @Override // com.garmin.android.apps.connectmobile.connectiq.IConnectIQService
        public void registerApp(IQApp iQApp, String str, String str2) throws RemoteException {
        }

        @Override // com.garmin.android.apps.connectmobile.connectiq.IConnectIQService
        public void sendImage(IQMessage iQMessage, IQDevice iQDevice, IQApp iQApp) throws RemoteException {
        }

        @Override // com.garmin.android.apps.connectmobile.connectiq.IConnectIQService
        public void sendMessage(IQMessage iQMessage, IQDevice iQDevice, IQApp iQApp) throws RemoteException {
        }

        @Override // com.garmin.android.apps.connectmobile.connectiq.IConnectIQService
        public void sendTransientMessage(IQMessage iQMessage, IQDevice iQDevice, IQApp iQApp) throws RemoteException {
        }
    }

    void getApplicationInfo(String str, String str2, IQDevice iQDevice, String str3) throws RemoteException;

    List<IQDevice> getConnectedDevices() throws RemoteException;

    List<IQDevice> getKnownDevices() throws RemoteException;

    String getPartNumber(IQDevice iQDevice) throws RemoteException;

    int getStatus(IQDevice iQDevice) throws RemoteException;

    void openApplication(String str, String str2, IQDevice iQDevice, IQApp iQApp) throws RemoteException;

    boolean openStore(String str) throws RemoteException;

    void registerApp(IQApp iQApp, String str, String str2) throws RemoteException;

    void sendImage(IQMessage iQMessage, IQDevice iQDevice, IQApp iQApp) throws RemoteException;

    void sendMessage(IQMessage iQMessage, IQDevice iQDevice, IQApp iQApp) throws RemoteException;

    void sendTransientMessage(IQMessage iQMessage, IQDevice iQDevice, IQApp iQApp) throws RemoteException;

    /* loaded from: classes.dex */
    public static abstract class Stub extends Binder implements IConnectIQService {
        static final int TRANSACTION_getApplicationInfo = 5;
        static final int TRANSACTION_getConnectedDevices = 2;
        static final int TRANSACTION_getKnownDevices = 3;
        static final int TRANSACTION_getPartNumber = 11;
        static final int TRANSACTION_getStatus = 4;
        static final int TRANSACTION_openApplication = 6;
        static final int TRANSACTION_openStore = 1;
        static final int TRANSACTION_registerApp = 9;
        static final int TRANSACTION_sendImage = 8;
        static final int TRANSACTION_sendMessage = 7;
        static final int TRANSACTION_sendTransientMessage = 10;

        @Override // android.os.IInterface
        public IBinder asBinder() {
            return this;
        }

        public Stub() {
            attachInterface(this, IConnectIQService.DESCRIPTOR);
        }

        public static IConnectIQService asInterface(IBinder iBinder) {
            if (iBinder == null) {
                return null;
            }
            IInterface queryLocalInterface = iBinder.queryLocalInterface(IConnectIQService.DESCRIPTOR);
            if (queryLocalInterface != null && (queryLocalInterface instanceof IConnectIQService)) {
                return (IConnectIQService) queryLocalInterface;
            }
            return new Proxy(iBinder);
        }

        @Override // android.os.Binder
        public boolean onTransact(int i, Parcel parcel, Parcel parcel2, int i2) throws RemoteException {
            if (i >= 1 && i <= 16777215) {
                parcel.enforceInterface(IConnectIQService.DESCRIPTOR);
            }
            if (i == 1598968902) {
                parcel2.writeString(IConnectIQService.DESCRIPTOR);
                return true;
            }
            switch (i) {
                case 1:
                    boolean openStore = openStore(parcel.readString());
                    parcel2.writeNoException();
                    parcel2.writeInt(openStore ? 1 : 0);
                    return true;
                case 2:
                    List<IQDevice> connectedDevices = getConnectedDevices();
                    parcel2.writeNoException();
                    _Parcel.writeTypedList(parcel2, connectedDevices, 1);
                    return true;
                case 3:
                    List<IQDevice> knownDevices = getKnownDevices();
                    parcel2.writeNoException();
                    _Parcel.writeTypedList(parcel2, knownDevices, 1);
                    return true;
                case 4:
                    int status = getStatus((IQDevice) _Parcel.readTypedObject(parcel, IQDevice.CREATOR));
                    parcel2.writeNoException();
                    parcel2.writeInt(status);
                    return true;
                case 5:
                    getApplicationInfo(parcel.readString(), parcel.readString(), (IQDevice) _Parcel.readTypedObject(parcel, IQDevice.CREATOR), parcel.readString());
                    return true;
                case 6:
                    openApplication(parcel.readString(), parcel.readString(), (IQDevice) _Parcel.readTypedObject(parcel, IQDevice.CREATOR), (IQApp) _Parcel.readTypedObject(parcel, IQApp.CREATOR));
                    return true;
                case 7:
                    sendMessage((IQMessage) _Parcel.readTypedObject(parcel, IQMessage.CREATOR), (IQDevice) _Parcel.readTypedObject(parcel, IQDevice.CREATOR), (IQApp) _Parcel.readTypedObject(parcel, IQApp.CREATOR));
                    return true;
                case 8:
                    sendImage((IQMessage) _Parcel.readTypedObject(parcel, IQMessage.CREATOR), (IQDevice) _Parcel.readTypedObject(parcel, IQDevice.CREATOR), (IQApp) _Parcel.readTypedObject(parcel, IQApp.CREATOR));
                    return true;
                case 9:
                    registerApp((IQApp) _Parcel.readTypedObject(parcel, IQApp.CREATOR), parcel.readString(), parcel.readString());
                    return true;
                case 10:
                    sendTransientMessage((IQMessage) _Parcel.readTypedObject(parcel, IQMessage.CREATOR), (IQDevice) _Parcel.readTypedObject(parcel, IQDevice.CREATOR), (IQApp) _Parcel.readTypedObject(parcel, IQApp.CREATOR));
                    return true;
                case 11:
                    String partNumber = getPartNumber((IQDevice) _Parcel.readTypedObject(parcel, IQDevice.CREATOR));
                    parcel2.writeNoException();
                    parcel2.writeString(partNumber);
                    return true;
                default:
                    return super.onTransact(i, parcel, parcel2, i2);
            }
        }

        /* loaded from: classes.dex */
        private static class Proxy implements IConnectIQService {
            private IBinder mRemote;

            Proxy(IBinder iBinder) {
                this.mRemote = iBinder;
            }

            @Override // android.os.IInterface
            public IBinder asBinder() {
                return this.mRemote;
            }

            public String getInterfaceDescriptor() {
                return IConnectIQService.DESCRIPTOR;
            }

            @Override // com.garmin.android.apps.connectmobile.connectiq.IConnectIQService
            public boolean openStore(String str) throws RemoteException {
                Parcel obtain = Parcel.obtain();
                Parcel obtain2 = Parcel.obtain();
                try {
                    obtain.writeInterfaceToken(IConnectIQService.DESCRIPTOR);
                    obtain.writeString(str);
                    this.mRemote.transact(1, obtain, obtain2, 0);
                    obtain2.readException();
                    return obtain2.readInt() != 0;
                } finally {
                    obtain2.recycle();
                    obtain.recycle();
                }
            }

            @Override // com.garmin.android.apps.connectmobile.connectiq.IConnectIQService
            public List<IQDevice> getConnectedDevices() throws RemoteException {
                Parcel obtain = Parcel.obtain();
                Parcel obtain2 = Parcel.obtain();
                try {
                    obtain.writeInterfaceToken(IConnectIQService.DESCRIPTOR);
                    this.mRemote.transact(2, obtain, obtain2, 0);
                    obtain2.readException();
                    return obtain2.createTypedArrayList(IQDevice.CREATOR);
                } finally {
                    obtain2.recycle();
                    obtain.recycle();
                }
            }

            @Override // com.garmin.android.apps.connectmobile.connectiq.IConnectIQService
            public List<IQDevice> getKnownDevices() throws RemoteException {
                Parcel obtain = Parcel.obtain();
                Parcel obtain2 = Parcel.obtain();
                try {
                    obtain.writeInterfaceToken(IConnectIQService.DESCRIPTOR);
                    this.mRemote.transact(3, obtain, obtain2, 0);
                    obtain2.readException();
                    return obtain2.createTypedArrayList(IQDevice.CREATOR);
                } finally {
                    obtain2.recycle();
                    obtain.recycle();
                }
            }

            @Override // com.garmin.android.apps.connectmobile.connectiq.IConnectIQService
            public int getStatus(IQDevice iQDevice) throws RemoteException {
                Parcel obtain = Parcel.obtain();
                Parcel obtain2 = Parcel.obtain();
                try {
                    obtain.writeInterfaceToken(IConnectIQService.DESCRIPTOR);
                    _Parcel.writeTypedObject(obtain, iQDevice, 0);
                    this.mRemote.transact(4, obtain, obtain2, 0);
                    obtain2.readException();
                    return obtain2.readInt();
                } finally {
                    obtain2.recycle();
                    obtain.recycle();
                }
            }

            @Override // com.garmin.android.apps.connectmobile.connectiq.IConnectIQService
            public void getApplicationInfo(String str, String str2, IQDevice iQDevice, String str3) throws RemoteException {
                Parcel obtain = Parcel.obtain();
                try {
                    obtain.writeInterfaceToken(IConnectIQService.DESCRIPTOR);
                    obtain.writeString(str);
                    obtain.writeString(str2);
                    _Parcel.writeTypedObject(obtain, iQDevice, 0);
                    obtain.writeString(str3);
                    this.mRemote.transact(5, obtain, null, 1);
                } finally {
                    obtain.recycle();
                }
            }

            @Override // com.garmin.android.apps.connectmobile.connectiq.IConnectIQService
            public void openApplication(String str, String str2, IQDevice iQDevice, IQApp iQApp) throws RemoteException {
                Parcel obtain = Parcel.obtain();
                try {
                    obtain.writeInterfaceToken(IConnectIQService.DESCRIPTOR);
                    obtain.writeString(str);
                    obtain.writeString(str2);
                    _Parcel.writeTypedObject(obtain, iQDevice, 0);
                    _Parcel.writeTypedObject(obtain, iQApp, 0);
                    this.mRemote.transact(6, obtain, null, 1);
                } finally {
                    obtain.recycle();
                }
            }

            @Override // com.garmin.android.apps.connectmobile.connectiq.IConnectIQService
            public void sendMessage(IQMessage iQMessage, IQDevice iQDevice, IQApp iQApp) throws RemoteException {
                Parcel obtain = Parcel.obtain();
                try {
                    obtain.writeInterfaceToken(IConnectIQService.DESCRIPTOR);
                    _Parcel.writeTypedObject(obtain, iQMessage, 0);
                    _Parcel.writeTypedObject(obtain, iQDevice, 0);
                    _Parcel.writeTypedObject(obtain, iQApp, 0);
                    this.mRemote.transact(7, obtain, null, 1);
                } finally {
                    obtain.recycle();
                }
            }

            @Override // com.garmin.android.apps.connectmobile.connectiq.IConnectIQService
            public void sendImage(IQMessage iQMessage, IQDevice iQDevice, IQApp iQApp) throws RemoteException {
                Parcel obtain = Parcel.obtain();
                try {
                    obtain.writeInterfaceToken(IConnectIQService.DESCRIPTOR);
                    _Parcel.writeTypedObject(obtain, iQMessage, 0);
                    _Parcel.writeTypedObject(obtain, iQDevice, 0);
                    _Parcel.writeTypedObject(obtain, iQApp, 0);
                    this.mRemote.transact(8, obtain, null, 1);
                } finally {
                    obtain.recycle();
                }
            }

            @Override // com.garmin.android.apps.connectmobile.connectiq.IConnectIQService
            public void registerApp(IQApp iQApp, String str, String str2) throws RemoteException {
                Parcel obtain = Parcel.obtain();
                try {
                    obtain.writeInterfaceToken(IConnectIQService.DESCRIPTOR);
                    _Parcel.writeTypedObject(obtain, iQApp, 0);
                    obtain.writeString(str);
                    obtain.writeString(str2);
                    this.mRemote.transact(9, obtain, null, 1);
                } finally {
                    obtain.recycle();
                }
            }

            @Override // com.garmin.android.apps.connectmobile.connectiq.IConnectIQService
            public void sendTransientMessage(IQMessage iQMessage, IQDevice iQDevice, IQApp iQApp) throws RemoteException {
                Parcel obtain = Parcel.obtain();
                try {
                    obtain.writeInterfaceToken(IConnectIQService.DESCRIPTOR);
                    _Parcel.writeTypedObject(obtain, iQMessage, 0);
                    _Parcel.writeTypedObject(obtain, iQDevice, 0);
                    _Parcel.writeTypedObject(obtain, iQApp, 0);
                    this.mRemote.transact(10, obtain, null, 1);
                } finally {
                    obtain.recycle();
                }
            }

            @Override // com.garmin.android.apps.connectmobile.connectiq.IConnectIQService
            public String getPartNumber(IQDevice iQDevice) throws RemoteException {
                Parcel obtain = Parcel.obtain();
                Parcel obtain2 = Parcel.obtain();
                try {
                    obtain.writeInterfaceToken(IConnectIQService.DESCRIPTOR);
                    _Parcel.writeTypedObject(obtain, iQDevice, 0);
                    this.mRemote.transact(11, obtain, obtain2, 0);
                    obtain2.readException();
                    return obtain2.readString();
                } finally {
                    obtain2.recycle();
                    obtain.recycle();
                }
            }
        }
    }

    /* loaded from: classes.dex */
    public static class _Parcel {
        /* JADX INFO: Access modifiers changed from: private */
        public static <T> T readTypedObject(Parcel parcel, Parcelable.Creator<T> creator) {
            if (parcel.readInt() != 0) {
                return creator.createFromParcel(parcel);
            }
            return null;
        }

        /* JADX INFO: Access modifiers changed from: private */
        public static <T extends Parcelable> void writeTypedObject(Parcel parcel, T t, int i) {
            if (t != null) {
                parcel.writeInt(1);
                t.writeToParcel(parcel, i);
            } else {
                parcel.writeInt(0);
            }
        }

        /* JADX INFO: Access modifiers changed from: private */
        public static <T extends Parcelable> void writeTypedList(Parcel parcel, List<T> list, int i) {
            if (list == null) {
                parcel.writeInt(-1);
                return;
            }
            int size = list.size();
            parcel.writeInt(size);
            for (int i2 = 0; i2 < size; i2++) {
                writeTypedObject(parcel, list.get(i2), i);
            }
        }
    }
}
