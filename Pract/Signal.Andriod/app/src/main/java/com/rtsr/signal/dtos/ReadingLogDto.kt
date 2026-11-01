package com.rtsr.signal.dtos

data class ReadingLogDto(
    val readingName: String,
    val readingValue: String,
    val readingUnit: String?,
    val readingStatus: String,
    val writeDateTime: String
)