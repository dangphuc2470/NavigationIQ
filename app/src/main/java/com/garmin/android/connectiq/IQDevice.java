package com.garmin.android.connectiq;

import android.os.Parcel;
import android.os.Parcelable;

/* loaded from: classes.dex */
public class IQDevice implements Parcelable {
    public static final Parcelable.Creator<IQDevice> CREATOR = new Parcelable.Creator<IQDevice>() { // from class: com.garmin.android.connectiq.IQDevice.1
        /* JADX WARN: Can't rename method to resolve collision */
        @Override // android.os.Parcelable.Creator
        public IQDevice createFromParcel(Parcel parcel) {
            return new IQDevice(parcel);
        }

        /* JADX WARN: Can't rename method to resolve collision */
        @Override // android.os.Parcelable.Creator
        public IQDevice[] newArray(int i) {
            return new IQDevice[i];
        }
    };
    private long deviceIdentifier;
    private String friendlyName;
    private IQDeviceStatus status;

    /* loaded from: classes.dex */
    public enum IQDeviceStatus {
        NOT_PAIRED,
        NOT_CONNECTED,
        CONNECTED,
        UNKNOWN
    }

    @Override // android.os.Parcelable
    public int describeContents() {
        return 0;
    }

    public IQDevice(long j, String str) {
        this.status = IQDeviceStatus.UNKNOWN;
        this.deviceIdentifier = j;
        this.friendlyName = str;
    }

    public IQDevice(Parcel parcel) {
        this.status = IQDeviceStatus.UNKNOWN;
        this.deviceIdentifier = parcel.readLong();
        this.friendlyName = parcel.readString();
        try {
            this.status = IQDeviceStatus.valueOf(parcel.readString());
        } catch (IllegalArgumentException unused) {
            this.status = IQDeviceStatus.UNKNOWN;
        }
    }

    public String getFriendlyName() {
        return this.friendlyName;
    }

    public long getDeviceIdentifier() {
        return this.deviceIdentifier;
    }

    public void setStatus(IQDeviceStatus iQDeviceStatus) {
        this.status = iQDeviceStatus;
    }

    public IQDeviceStatus getStatus() {
        return this.status;
    }

    @Override // android.os.Parcelable
    public void writeToParcel(Parcel parcel, int i) {
        parcel.writeLong(this.deviceIdentifier);
        parcel.writeString(this.friendlyName);
        parcel.writeString(this.status.name());
    }

    public String toString() {
        return this.friendlyName;
    }
}
