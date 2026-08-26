package com.garmin.monkeybrains.serialization;

import java.io.UnsupportedEncodingException;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;

/* loaded from: classes.dex */
public class StringBlock extends ArrayList<MonkeyString> {
    private static final long serialVersionUID = 7158590947509522494L;
    private HashMap<Integer, String> mDeserializedStrings;
    private int mTotalBytes;

    public StringBlock() {
    }

    public StringBlock(byte[] bArr) throws UnsupportedEncodingException {
        this.mDeserializedStrings = new HashMap<>();
        int length = bArr.length;
        int i = 0;
        while (i < length) {
            int i2 = i + 2;
            int i3 = ByteBuffer.wrap(bArr, i, 2).getShort() + i2;
            this.mDeserializedStrings.put(Integer.valueOf(i), new String(Arrays.copyOfRange(bArr, i2, i3 - 1), "UTF-8"));
            i = i3;
        }
    }

    public int addString(MonkeyString monkeyString) throws UnsupportedEncodingException {
        int offsetFor = getOffsetFor(monkeyString);
        monkeyString.setOffset(offsetFor);
        if (!contains(monkeyString)) {
            add(monkeyString);
            this.mTotalBytes += monkeyString.getValue().getBytes("UTF-8").length + 3;
        }
        return offsetFor;
    }

    private int getOffsetFor(MonkeyString monkeyString) throws UnsupportedEncodingException {
        int i = 0;
        for (int i2 = 0; i2 < size() && !get(i2).equals(monkeyString); i2++) {
            i += get(i2).getValue().getBytes("UTF-8").length + 3;
        }
        return i;
    }

    public byte[] serialize() throws UnsupportedEncodingException {
        ByteBuffer allocate = ByteBuffer.allocate(this.mTotalBytes);
        for (int i = 0; i < size(); i++) {
            allocate.put(get(i).serializeString());
        }
        return allocate.array();
    }

    public HashMap<Integer, String> getDeserializedStrings() {
        return this.mDeserializedStrings;
    }
}
