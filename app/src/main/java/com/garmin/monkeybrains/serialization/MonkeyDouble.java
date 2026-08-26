package com.garmin.monkeybrains.serialization;

import java.nio.ByteBuffer;

/* loaded from: classes.dex */
public class MonkeyDouble extends MonkeyType<Double> {
    private double mValue;

    @Override // com.garmin.monkeybrains.serialization.MonkeyType
    public int getNumBytes() {
        return 9;
    }

    public MonkeyDouble(double d) {
        super((byte) 15);
        this.mValue = d;
    }

    public MonkeyDouble(byte[] bArr) {
        super(bArr[0]);
        this.mValue = ByteBuffer.wrap(bArr, 1, bArr.length - 1).getDouble();
    }

    @Override // com.garmin.monkeybrains.serialization.MonkeyType
    public byte[] serialize() {
        ByteBuffer allocate = ByteBuffer.allocate(getNumBytes());
        allocate.put((byte) 15);
        allocate.putDouble(this.mValue);
        return allocate.array();
    }

    /* JADX WARN: Can't rename method to resolve collision */
    @Override // com.garmin.monkeybrains.serialization.MonkeyType
    public Double toJava() {
        return Double.valueOf(this.mValue);
    }
}
