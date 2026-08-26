package com.garmin.monkeybrains.serialization;

import java.io.UnsupportedEncodingException;
import java.util.List;

/* loaded from: classes.dex */
public class Serializer {
    private SerializedObject mSerializedObject;

    public static List<MonkeyType<?>> deserialize(byte[] bArr) throws UnsupportedEncodingException {
        return new SerializedObject(bArr).getValues();
    }

    public static <T> byte[] serialize(T t) throws Exception {
        return new Serializer(t).serialize();
    }

    public Serializer() {
        this.mSerializedObject = new SerializedObject();
    }

    public Serializer(Object obj) throws UnsupportedEncodingException {
        this();
        addObject(obj);
    }

    public <T> void addObject(T t) throws UnsupportedEncodingException {
        this.mSerializedObject.addObject(MonkeyType.fromJava(t));
    }

    public byte[] serialize() throws Exception {
        return this.mSerializedObject.serialize();
    }
}
