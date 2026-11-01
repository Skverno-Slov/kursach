package com.rtsr.signal.dtos

data class EquipmentDto(
    val equipmentId: Int,
    val serialNumber: String,
    val name: String,
    val model: String,
    val statusName: String
)