package com.garmin.monkeybrains.serialization;

import java.io.UnsupportedEncodingException;
import java.util.List;
import java.util.Map;

/* loaded from: classes.dex */
public abstract class MonkeyType<T> {
    public static final byte ARRAY = 5;
    public static final byte BOOLEAN = 9;
    public static final byte CHAR = 19;
    public static final byte DOUBLE = 15;
    public static final byte FLOAT = 2;
    public static final byte HASH = 11;
    public static final byte INT = 1;
    public static final byte LONG = 14;
    public static final byte NULL = 0;
    public static final byte STRING = 3;
    public byte mType;

    public abstract int getNumBytes();

    public abstract byte[] serialize();

    public abstract T toJava();

    public static MonkeyType<?> deserialize(byte[] bArr) throws UnsupportedEncodingException {
        byte b = bArr[0];
        if (b == 0) {
            return new MonkeyNull();
        }
        if (b == 1) {
            return new MonkeyInt(bArr);
        }
        if (b == 2) {
            return new MonkeyFloat(bArr);
        }
        if (b == 3) {
            return new MonkeyString(bArr);
        }
        if (b == 5) {
            return new MonkeyArray(bArr);
        }
        if (b == 9) {
            return new MonkeyBool(bArr);
        }
        if (b == 11) {
            return new MonkeyHash(bArr);
        }
        if (b == 19) {
            return new MonkeyChar(bArr);
        }
        if (b == 14) {
            return new MonkeyLong(bArr);
        }
        if (b != 15) {
            return null;
        }
        return new MonkeyDouble(bArr);
    }

    /* JADX WARN: Multi-variable type inference failed */
    public static <T> MonkeyType<?> fromJava(T t) {
        if (t == null) {
            return new MonkeyNull((byte[]) null);
        }
        if (t instanceof MonkeyType) {
            return (MonkeyType) t;
        }
        if (t instanceof Integer) {
            return new MonkeyInt(((Integer) t).intValue());
        }
        boolean z = t instanceof Long;
        if (z) {
            Number number = (Number) t;
            if (number.longValue() <= 2147483647L && number.longValue() >= -2147483648L) {
                return new MonkeyInt(number.intValue());
            }
            return new MonkeyLong(((Long) t).longValue());
        }
        if (t instanceof Float) {
            return new MonkeyFloat(((Float) t).floatValue());
        }
        if (t instanceof Double) {
            Number number2 = (Number) t;
            if (Math.abs(number2.floatValue() - number2.doubleValue()) < 1.0E-5d) {
                return new MonkeyFloat(number2.floatValue());
            }
            return new MonkeyDouble(((Double) t).doubleValue());
        }
        if (z) {
            return new MonkeyInt(((Long) t).intValue());
        }
        if (t instanceof String) {
            return new MonkeyString((String) t);
        }
        if (t instanceof List) {
            return new MonkeyArray((List) t);
        }
        if (t instanceof Boolean) {
            return new MonkeyBool(((Boolean) t).booleanValue());
        }
        if (t instanceof Map) {
            return new MonkeyHash((Map<Object, Object>) t);
        }
        return new MonkeyNull((byte[]) null);
    }

    public MonkeyType(byte b) {
        this.mType = b;
    }

    public boolean equals(Object obj) {
        if (!(obj instanceof MonkeyType)) {
            return false;
        }
        if (obj instanceof MonkeyNull) {
            return this instanceof MonkeyNull;
        }
        return toJava().equals(((MonkeyType) obj).toJava());
    }

    public int hashCode() {
        return toJava().hashCode();
    }
}
