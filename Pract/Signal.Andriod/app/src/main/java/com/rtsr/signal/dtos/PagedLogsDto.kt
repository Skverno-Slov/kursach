package com.rtsr.signal.dtos

data class PagedLogsDto(
    val logs: List<ReadingLogDto>,
    val availableIdentifiers: List<String>,
    val totalCount: Int
)
