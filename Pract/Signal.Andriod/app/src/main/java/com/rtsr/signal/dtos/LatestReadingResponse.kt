package com.rtsr.signal.dtos

data class LatestReadingResponse(
    val serialNumber: String?,
    val metricKey: String,
    val label: String,
    val value: String,
    val unit: String?,
    val status: String,
    val datetime: String?,
    val minValue: Double?,
    val maxValue: Double?
)
