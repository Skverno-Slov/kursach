package com.rtsr.signal.dtos

data class TokenResponse(
    val accessToken: String,
    val refreshToken: String,
    val firstName: String?,
    val lastName: String?,
    val middleName: String?,
    val role: List<String>?
)