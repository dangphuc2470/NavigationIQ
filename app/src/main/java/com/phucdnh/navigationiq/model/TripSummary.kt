package com.phucdnh.navigationiq.model

import java.io.Serializable

/**
 * Data model capturing completed trip telemetry and arrival details.
 */
data class TripSummary(
    val destination: String,
    val duration: String,
    val distance: String,
    val avgSpeed: String,
    val startTime: String = "",
    val endTime: String = ""
) : Serializable
