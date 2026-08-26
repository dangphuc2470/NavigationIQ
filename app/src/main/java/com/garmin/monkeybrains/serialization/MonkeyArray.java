package com.garmin.monkeybrains.serialization;

import java.io.UnsupportedEncodingException;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

/* loaded from: classes.dex */
public class MonkeyArray extends MonkeyType<List<MonkeyType<?>>> implements MonkeyContainer {
    private int mChildCount;
    private List<MonkeyType<?>> mList;

    public <T> MonkeyArray(List<T> list) {
        super((byte) 5);
        this.mList = new ArrayList();
        Iterator<T> it = list.iterator();
        while (it.hasNext()) {
            this.mList.add(MonkeyType.fromJava(it.next()));
        }
    }

    public MonkeyArray(byte[] bArr) throws UnsupportedEncodingException {
        super(bArr[0]);
        this.mList = new ArrayList();
        this.mChildCount = ByteBuffer.wrap(bArr, 1, 4).getInt();
    }

    @Override // com.garmin.monkeybrains.serialization.MonkeyType
    public int getNumBytes() {
        Iterator<MonkeyType<?>> it = this.mList.iterator();
        int i = 5;
        while (it.hasNext()) {
            i += it.next().getNumBytes();
        }
        return i;
    }

    @Override // com.garmin.monkeybrains.serialization.MonkeyType
    public byte[] serialize() {
        ByteBuffer allocate = ByteBuffer.allocate(5);
        allocate.put((byte) 5);
        allocate.putInt(this.mList.size());
        return allocate.array();
    }

    @Override // com.garmin.monkeybrains.serialization.MonkeyType
    public List<MonkeyType<?>> toJava() {
        return this.mList;
    }

    public List<MonkeyType<?>> getValues() {
        return this.mList;
    }

    @Override // com.garmin.monkeybrains.serialization.MonkeyContainer
    public List<MonkeyType<?>> getChildren() {
        return this.mList;
    }

    @Override // com.garmin.monkeybrains.serialization.MonkeyContainer
    public int getChildCount() {
        return this.mChildCount;
    }
}
