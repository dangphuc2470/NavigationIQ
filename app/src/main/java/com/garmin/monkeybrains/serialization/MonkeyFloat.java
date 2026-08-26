package com.garmin.monkeybrains.serialization;

import java.nio.ByteBuffer;

/* loaded from: classes.dex */
public class MonkeyFloat extends MonkeyType<Float> {
    private float mValue;

    @Override // com.garmin.monkeybrains.serialization.MonkeyType
    public int getNumBytes() {
        return 5;
    }

    public MonkeyFloat(float f) {
        super((byte) 2);
        this.mValue = f;
    }

    public MonkeyFloat(byte[] bArr) {
        super(bArr[0]);
        this.mValue = ByteBuffer.wrap(bArr, 1, bArr.length - 1).getFloat();
    }

    @Override // com.garmin.monkeybrains.serialization.MonkeyType
    public byte[] serialize() {
        ByteBuffer allocate = ByteBuffer.allocate(getNumBytes());
        allocate.put((byte) 2);
        allocate.putFloat(this.mValue);
        return allocate.array();
    }

    /* JADX WARN: Can't rename method to resolve collision */
    @Override // com.garmin.monkeybrains.serialization.MonkeyType
    public Float toJava() {
        return Float.valueOf(this.mValue);
    }
}
