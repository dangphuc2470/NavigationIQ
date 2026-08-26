package com.garmin.monkeybrains.serialization;

import java.nio.ByteBuffer;

/* loaded from: classes.dex */
public class MonkeyChar extends MonkeyType<Integer> {
    private Integer mValue;

    @Override // com.garmin.monkeybrains.serialization.MonkeyType
    public int getNumBytes() {
        return 5;
    }

    public MonkeyChar(Integer num) {
        super((byte) 19);
        this.mValue = num;
    }

    public MonkeyChar(byte[] bArr) {
        super(bArr[0]);
        this.mValue = Integer.valueOf(ByteBuffer.wrap(bArr, 1, bArr.length - 1).getInt());
    }

    @Override // com.garmin.monkeybrains.serialization.MonkeyType
    public byte[] serialize() {
        ByteBuffer allocate = ByteBuffer.allocate(getNumBytes());
        allocate.put((byte) 19);
        allocate.putInt(this.mValue.intValue());
        return allocate.array();
    }

    /* JADX WARN: Can't rename method to resolve collision */
    @Override // com.garmin.monkeybrains.serialization.MonkeyType
    public Integer toJava() {
        return Integer.valueOf(this.mValue.intValue());
    }
}
