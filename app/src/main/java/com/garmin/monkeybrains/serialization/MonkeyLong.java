package com.garmin.monkeybrains.serialization;

import java.nio.ByteBuffer;

/* loaded from: classes.dex */
public class MonkeyLong extends MonkeyType<Long> {
    private long mValue;

    @Override // com.garmin.monkeybrains.serialization.MonkeyType
    public int getNumBytes() {
        return 9;
    }

    public MonkeyLong(long j) {
        super((byte) 14);
        this.mValue = j;
    }

    public MonkeyLong(byte[] bArr) {
        super(bArr[0]);
        this.mValue = ByteBuffer.wrap(bArr, 1, bArr.length - 1).getLong();
    }

    @Override // com.garmin.monkeybrains.serialization.MonkeyType
    public byte[] serialize() {
        ByteBuffer allocate = ByteBuffer.allocate(getNumBytes());
        allocate.put((byte) 14);
        allocate.putLong(this.mValue);
        return allocate.array();
    }

    /* JADX WARN: Can't rename method to resolve collision */
    @Override // com.garmin.monkeybrains.serialization.MonkeyType
    public Long toJava() {
        return Long.valueOf(this.mValue);
    }
}
