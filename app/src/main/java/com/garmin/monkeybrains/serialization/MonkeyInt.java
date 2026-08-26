package com.garmin.monkeybrains.serialization;

import java.nio.ByteBuffer;

/* loaded from: classes.dex */
public class MonkeyInt extends MonkeyType<Integer> {
    private int mValue;

    @Override // com.garmin.monkeybrains.serialization.MonkeyType
    public int getNumBytes() {
        return 5;
    }

    public MonkeyInt(int i) {
        super((byte) 1);
        this.mValue = i;
    }

    public MonkeyInt(byte[] bArr) {
        super(bArr[0]);
        this.mValue = ByteBuffer.wrap(bArr, 1, bArr.length - 1).getInt();
    }

    @Override // com.garmin.monkeybrains.serialization.MonkeyType
    public byte[] serialize() {
        ByteBuffer allocate = ByteBuffer.allocate(getNumBytes());
        allocate.put(this.mType);
        allocate.putInt(this.mValue);
        return allocate.array();
    }

    /* JADX WARN: Can't rename method to resolve collision */
    @Override // com.garmin.monkeybrains.serialization.MonkeyType
    public Integer toJava() {
        return Integer.valueOf(this.mValue);
    }
}
