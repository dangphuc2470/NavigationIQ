package com.garmin.monkeybrains.serialization;

import java.util.List;

/* loaded from: classes.dex */
public interface MonkeyContainer {
    int getChildCount();

    List<MonkeyType<?>> getChildren();
}
