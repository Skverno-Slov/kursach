package com.rtsr.signal.models

import com.rtsr.signal.dtos.EquipmentDto
import com.rtsr.signal.dtos.GraphPointDto
import com.rtsr.signal.dtos.LatestReadingResponse
import com.rtsr.signal.dtos.ReadingLogDto

data class MainUiState(
    val isAuthorized: Boolean = false,
    val isLoading: Boolean = true,
    val userFullName: String = "",
    val currentScreen: AppScreen = AppScreen.MONITORING,
    val isAutoLoginChecking: Boolean = true,
    val isRefreshing: Boolean = false,
    val devices: List<EquipmentDto> = emptyList(),
    val selectedDeviceId: String? = null,
    val selectedPeriod: PeriodType = PeriodType.ALL_TIME,
    val viewMode: ViewMode = ViewMode.LATEST,
    val lastUpdateTime: String = "",
    val apiAddress: String = "192.168.59.18",
    val apiPort: String = "22",
    val isAddressSaved: Boolean = true,
    val addressErrorResId: Int? = null,
    val portErrorResId: Int? = null,
    val loginErrorMessage: Int? = null,
    val isLoginLoading: Boolean = false,
    val logsList: List<ReadingLogDto> = emptyList(),
    val isConnectionChecking: Boolean = false,
    val connectionStatus: ConnectionStatus = ConnectionStatus.NOT_TESTED,
    val availableParams: List<String> = emptyList(),
    val selectedParamIdentifier: String? = null,
    val currentPage: Int = 1,
    val isPageLoading: Boolean = false,
    val totalCount: Int = 0,
    val graphPoints: List<GraphPointDto> = emptyList(),
    val isGraphLoading: Boolean = false,
    val latestReadings: List<LatestReadingResponse> = emptyList(),
    val isConnected: Boolean = true,
    val useHttps: String = ""
)