package com.garmin.monkeybrains.serialization;

import java.io.UnsupportedEncodingException;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/* loaded from: classes.dex */
public class MonkeyHash extends MonkeyType<HashMap<MonkeyType<?>, MonkeyType<?>>> implements MonkeyContainer {
    private HashMap<MonkeyType<?>, MonkeyType<?>> mHash;
    private int mHashSize;

    public MonkeyHash(Map<Object, Object> map) {
        super((byte) 11);
        this.mHash = new HashMap<>();
        for (Map.Entry<Object, Object> entry : map.entrySet()) {
            Object key = entry.getKey();
            Object value = entry.getValue();
            this.mHash.put(MonkeyType.fromJava(key), MonkeyType.fromJava(value));
        }
    }

    public MonkeyHash(byte[] bArr) throws UnsupportedEncodingException {
        super(bArr[0]);
        this.mHash = new HashMap<>();
        this.mHashSize = ByteBuffer.wrap(bArr, 1, 4).getInt();
    }

    @Override // com.garmin.monkeybrains.serialization.MonkeyType
    public int getNumBytes() {
        int i = 5;
        for (Map.Entry<MonkeyType<?>, MonkeyType<?>> entry : this.mHash.entrySet()) {
            i += entry.getKey().getNumBytes() + entry.getValue().getNumBytes();
        }
        return i;
    }

    @Override // com.garmin.monkeybrains.serialization.MonkeyType
    public byte[] serialize() {
        ByteBuffer allocate = ByteBuffer.allocate(5);
        allocate.put((byte) 11);
        allocate.putInt(this.mHash.size());
        return allocate.array();
    }

    @Override // com.garmin.monkeybrains.serialization.MonkeyType
    public HashMap<MonkeyType<?>, MonkeyType<?>> toJava() {
        return this.mHash;
    }

    public HashMap<MonkeyType<?>, MonkeyType<?>> getHashMap() {
        return this.mHash;
    }

    @Override // com.garmin.monkeybrains.serialization.MonkeyContainer
    public List<MonkeyType<?>> getChildren() {
        ArrayList arrayList = new ArrayList();
        for (Map.Entry<MonkeyType<?>, MonkeyType<?>> entry : this.mHash.entrySet()) {
            arrayList.add(entry.getKey());
            arrayList.add(entry.getValue());
        }
        return arrayList;
    }

    @Override // com.garmin.monkeybrains.serialization.MonkeyContainer
    public int getChildCount() {
        return this.mHashSize;
    }
}
