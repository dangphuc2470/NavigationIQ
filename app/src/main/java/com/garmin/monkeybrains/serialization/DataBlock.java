package com.garmin.monkeybrains.serialization;

import java.io.UnsupportedEncodingException;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.Map;

/* loaded from: classes.dex */
public class DataBlock extends ArrayList<MonkeyType<?>> {
    private static final long serialVersionUID = -8058543222042601383L;
    private LinkedList<MonkeyType<?>> mComplexDeserialQueue;
    private LinkedList<MonkeyType<?>> mDeserialQueue;
    private LinkedList<MonkeyType<?>> mSerialQueue;
    private int mTotalBytes;

    public DataBlock() {
        this.mSerialQueue = new LinkedList<>();
    }

    public DataBlock(byte[] bArr, StringBlock stringBlock) throws UnsupportedEncodingException {
        this.mDeserialQueue = new LinkedList<>();
        this.mComplexDeserialQueue = new LinkedList<>();
        int i = 0;
        while (i < bArr.length) {
            MonkeyType<?> deserialize = MonkeyType.deserialize(Arrays.copyOfRange(bArr, i, bArr.length));
            if (deserialize == null) {
                throw new UnsupportedEncodingException("Failed to deserialize MonkeyC objects");
            }
            this.mDeserialQueue.add(deserialize);
            if (stringBlock != null && (deserialize instanceof MonkeyString)) {
                attachStrings(deserialize, stringBlock);
            }
            i += deserialize.getNumBytes();
        }
        processDeserializeQueue();
    }

    private void processDeserializeQueue() {
        MonkeyType<?> poll;
        do {
            poll = this.mDeserialQueue.poll();
            if (poll != null) {
                if (poll instanceof MonkeyArray) {
                    processArray((MonkeyArray) poll);
                } else if (poll instanceof MonkeyHash) {
                    processHash((MonkeyHash) poll);
                }
                add(poll);
            }
        } while (poll != null);
    }

    private void processComplexDeserializeQueue() {
        MonkeyType<?> poll;
        do {
            poll = this.mComplexDeserialQueue.poll();
            if (poll != null) {
                if (poll instanceof MonkeyArray) {
                    processArray((MonkeyArray) poll);
                } else if (poll instanceof MonkeyHash) {
                    processHash((MonkeyHash) poll);
                }
            }
        } while (poll != null);
    }

    private void queueComplex(MonkeyType<?> monkeyType) {
        this.mComplexDeserialQueue.add(monkeyType);
    }

    private void processArray(MonkeyArray monkeyArray) {
        for (int i = 0; i < monkeyArray.getChildCount(); i++) {
            MonkeyType<?> poll = this.mDeserialQueue.poll();
            if (poll instanceof MonkeyContainer) {
                queueComplex(poll);
            }
            monkeyArray.getChildren().add(poll);
        }
        processComplexDeserializeQueue();
    }

    private void processHash(MonkeyHash monkeyHash) {
        for (int i = 0; i < monkeyHash.getChildCount(); i++) {
            MonkeyType<?> poll = this.mDeserialQueue.poll();
            if (poll instanceof MonkeyContainer) {
                queueComplex(poll);
            }
            MonkeyType<?> poll2 = this.mDeserialQueue.poll();
            if (poll2 instanceof MonkeyContainer) {
                queueComplex(poll2);
            }
            monkeyHash.getHashMap().put(poll, poll2);
        }
        processComplexDeserializeQueue();
    }

    @Override // java.util.ArrayList, java.util.AbstractList, java.util.AbstractCollection, java.util.Collection, java.util.List
    public boolean add(MonkeyType<?> monkeyType) {
        boolean add = super.add(monkeyType);
        if (add) {
            try {
                this.mTotalBytes += monkeyType.getNumBytes();
            } catch (Exception unused) {
            }
        }
        return add;
    }

    /* JADX WARN: Multi-variable type inference failed */
    public byte[] serialize() throws Exception {
        MonkeyType monkeyType;
        this.mSerialQueue.clear();
        this.mSerialQueue.addAll(this);
        ByteBuffer allocate = ByteBuffer.allocate(this.mTotalBytes);
        do {
            monkeyType = (MonkeyType) this.mSerialQueue.poll();
            if (monkeyType != null) {
                allocate.put(monkeyType.serialize());
                if (monkeyType instanceof MonkeyContainer) {
                    this.mSerialQueue.addAll(((MonkeyContainer) monkeyType).getChildren());
                }
            }
        } while (monkeyType != null);
        return allocate.array();
    }

    private void attachStrings(MonkeyType<?> monkeyType, StringBlock stringBlock) {
        if (monkeyType instanceof MonkeyString) {
            MonkeyString monkeyString = (MonkeyString) monkeyType;
            monkeyString.setValue(stringBlock.getDeserializedStrings().get(Integer.valueOf(monkeyString.getOffset())));
            return;
        }
        if (monkeyType instanceof MonkeyArray) {
            Iterator<MonkeyType<?>> it = ((MonkeyArray) monkeyType).getValues().iterator();
            while (it.hasNext()) {
                attachStrings(it.next(), stringBlock);
            }
        } else if (monkeyType instanceof MonkeyHash) {
            for (Map.Entry<MonkeyType<?>, MonkeyType<?>> entry : ((MonkeyHash) monkeyType).getHashMap().entrySet()) {
                attachStrings(entry.getKey(), stringBlock);
                attachStrings(entry.getValue(), stringBlock);
            }
        }
    }
}
