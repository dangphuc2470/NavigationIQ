package com.garmin.monkeybrains.serialization;

import java.io.UnsupportedEncodingException;
import java.nio.BufferUnderflowException;
import java.nio.ByteBuffer;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

/* loaded from: classes.dex */
public class SerializedObject {
    private static final int DATA_BLOCK_SENTINEL = -629482886;
    private static final int STRING_BLOCK_SENTINEL = -1412584499;
    private DataBlock mDataBlock;
    private StringBlock mStringBlock;

    public SerializedObject() {
        this.mStringBlock = new StringBlock();
        this.mDataBlock = new DataBlock();
    }

    public SerializedObject(byte[] bArr) throws UnsupportedEncodingException {
        int i;
        int stringBlock = getStringBlock(bArr);
        if (stringBlock > 0) {
            i = stringBlock + 8;
            if (i > bArr.length) {
                throw new BufferUnderflowException();
            }
            this.mStringBlock = new StringBlock(Arrays.copyOfRange(bArr, 8, i));
        } else {
            i = 0;
        }
        int i2 = i + 8;
        if (i2 > bArr.length) {
            throw new BufferUnderflowException();
        }
        ByteBuffer wrap = ByteBuffer.wrap(bArr, i, 8);
        wrap.getInt();
        int i3 = wrap.getInt() + i2;
        if (i3 > bArr.length) {
            throw new BufferUnderflowException();
        }
        this.mDataBlock = new DataBlock(Arrays.copyOfRange(bArr, i2, i3), this.mStringBlock);
    }

    public void addObject(MonkeyType<?> monkeyType) throws UnsupportedEncodingException {
        this.mDataBlock.add(monkeyType);
        addToStrings(monkeyType);
    }

    private void addToStrings(MonkeyType<?> monkeyType) throws UnsupportedEncodingException {
        if (monkeyType instanceof MonkeyString) {
            MonkeyString monkeyString = (MonkeyString) monkeyType;
            monkeyString.setOffset(this.mStringBlock.addString(monkeyString));
            return;
        }
        if (monkeyType instanceof MonkeyArray) {
            Iterator<MonkeyType<?>> it = ((MonkeyArray) monkeyType).getValues().iterator();
            while (it.hasNext()) {
                addToStrings(it.next());
            }
        } else if (monkeyType instanceof MonkeyHash) {
            for (Map.Entry<MonkeyType<?>, MonkeyType<?>> entry : ((MonkeyHash) monkeyType).getHashMap().entrySet()) {
                addToStrings(entry.getKey());
                addToStrings(entry.getValue());
            }
        }
    }

    public byte[] serialize() throws Exception {
        int length;
        byte[] serialize = this.mStringBlock.serialize();
        byte[] serialize2 = this.mDataBlock.serialize();
        if (serialize.length > 0) {
            length = serialize.length + 16 + serialize2.length;
        } else {
            length = serialize2.length + 8;
        }
        ByteBuffer allocate = ByteBuffer.allocate(length);
        if (serialize.length > 0) {
            allocate.putInt(STRING_BLOCK_SENTINEL);
            allocate.putInt(serialize.length);
            allocate.put(serialize);
        }
        allocate.putInt(DATA_BLOCK_SENTINEL);
        allocate.putInt(serialize2.length);
        allocate.put(serialize2);
        return allocate.array();
    }

    private int getStringBlock(byte[] bArr) {
        ByteBuffer wrap = ByteBuffer.wrap(bArr);
        if (wrap.getInt() == STRING_BLOCK_SENTINEL) {
            return wrap.getInt();
        }
        return 0;
    }

    public List<MonkeyType<?>> getValues() {
        return this.mDataBlock;
    }
}
