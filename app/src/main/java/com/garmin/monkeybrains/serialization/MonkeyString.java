package com.garmin.monkeybrains.serialization;

import java.io.UnsupportedEncodingException;
import java.nio.ByteBuffer;

/* loaded from: classes.dex */
public class MonkeyString extends MonkeyType<String> {
    private int mOffset;
    private String mValue;

    @Override // com.garmin.monkeybrains.serialization.MonkeyType
    public int getNumBytes() {
        return 5;
    }

    public MonkeyString(String str) {
        super((byte) 3);
        this.mValue = str;
    }

    public MonkeyString(byte[] bArr) {
        super(bArr[0]);
        this.mOffset = ByteBuffer.wrap(bArr, 1, bArr.length - 1).getInt();
    }

    @Override // com.garmin.monkeybrains.serialization.MonkeyType
    public byte[] serialize() {
        ByteBuffer allocate = ByteBuffer.allocate(getNumBytes());
        allocate.put((byte) 3);
        allocate.putInt(this.mOffset);
        return allocate.array();
    }

    public byte[] serializeString() throws UnsupportedEncodingException {
        ByteBuffer allocate = ByteBuffer.allocate(this.mValue.getBytes("UTF-8").length + 3);
        allocate.putShort((short) (this.mValue.getBytes("UTF-8").length + 1));
        allocate.put(this.mValue.getBytes("UTF-8"));
        allocate.put((byte) 0);
        return allocate.array();
    }

    @Override // com.garmin.monkeybrains.serialization.MonkeyType
    public String toJava() {
        return this.mValue;
    }

    public void setOffset(int i) {
        this.mOffset = i;
    }

    public String getValue() {
        return this.mValue;
    }

    public void setValue(String str) {
        this.mValue = str;
    }

    public int getOffset() {
        return this.mOffset;
    }

    @Override // com.garmin.monkeybrains.serialization.MonkeyType
    public int hashCode() {
        String str = this.mValue;
        return 445 + (str != null ? str.hashCode() : 0);
    }

    @Override // com.garmin.monkeybrains.serialization.MonkeyType
    public boolean equals(Object obj) {
        if (obj instanceof MonkeyString) {
            return ((MonkeyString) obj).getValue().equals(this.mValue);
        }
        return false;
    }
}
