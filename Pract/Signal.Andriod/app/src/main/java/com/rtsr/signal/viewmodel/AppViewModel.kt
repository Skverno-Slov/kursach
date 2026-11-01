package com.rtsr.signal.viewmodel

import android.app.Application
import kotlinx.coroutines.flow.update
import android.content.Context
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.compose.ui.graphics.Color
import com.rtsr.signal.models.MainUiState
import com.rtsr.signal.models.PeriodType
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import androidx.core.content.edit
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.rtsr.signal.R
import com.rtsr.signal.dtos.LoginRequest
import com.rtsr.signal.dtos.RefreshRequest
import com.rtsr.signal.models.AppScreen
import com.rtsr.signal.models.ConnectionStatus
import com.rtsr.signal.models.SignalApplication
import com.rtsr.signal.models.ViewMode
import com.rtsr.signal.services.NetworkClient
import kotlinx.coroutines.launch

@RequiresApi(Build.VERSION_CODES.O)
class AppViewModel(application: Application) : AndroidViewModel(application) {
    private val sharedPrefs = application.getSharedPreferences("app_prefs", Context.MODE_PRIVATE)
    private val _uiState = MutableStateFlow(MainUiState())
    val uiState: StateFlow<MainUiState> = _uiState.asStateFlow()

    val savedAddress = sharedPrefs.getString("api_address", "127.0.0.1") ?: "127.0.0.1"
    val savedPort = sharedPrefs.getString("api_port", "5000") ?: "5000"

    val savedHttpsStatus = sharedPrefs.getString("api_protocol", "") ?: ""

    val api get() = NetworkClient.getApi()

    val tokenManager = SignalApplication.tokenManager

    init {
        loadConnectionSettings(savedAddress, savedPort, savedHttpsStatus)

        tryAutoLogin()
    }

    fun updateClient(){
        NetworkClient.init(_uiState.value, tokenManager)
    }

    fun loadDataForCurrentView() {
        when (_uiState.value.viewMode) {
            ViewMode.LATEST ->  loadLatestReadings()
            ViewMode.GRAPH -> loadGraphData()
            ViewMode.TABLE -> loadDeviceData()
        }
    }

    fun loadAllData() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, isConnected = true) }
            try {
                val remoteDevices = api.getEquipmentList()
                val firstDeviceId = remoteDevices.firstOrNull()?.serialNumber
                val currentSelectedId = _uiState.value.selectedDeviceId ?: sharedPrefs.getString("selected_device_id", firstDeviceId)

                _uiState.update { currentState ->
                    currentState.copy(
                        devices = remoteDevices,
                        selectedDeviceId = currentSelectedId,
                        currentPage = 1
                    )
                }

                if (currentSelectedId != null) {
                    try {
                        when (_uiState.value.viewMode){
                            ViewMode.GRAPH -> {
                                _uiState.update { it.copy(isGraphLoading = true) }
                                val points = api.getFullGraphData(currentSelectedId, _uiState.value.selectedPeriod.name)

                                val response = api.getEquipmentLogs(
                                    currentSelectedId,
                                    _uiState.value.selectedPeriod.name,
                                    _uiState.value.selectedParamIdentifier,
                                    1,
                                    8
                                )

                                _uiState.update { currentState ->
                                    currentState.copy(
                                        isLoading = false,
                                        isGraphLoading = false,
                                        graphPoints = points,
                                        availableParams = response.availableIdentifiers,
                                        lastUpdateTime = getCurrentFormattedTime(),
                                    )
                                }

                                setFirstParam()
                            }
                            ViewMode.TABLE -> {
                                val response = api.getEquipmentLogs(
                                    currentSelectedId,
                                    _uiState.value.selectedPeriod.name,
                                    _uiState.value.selectedParamIdentifier,
                                    1,
                                    8
                                )
                                _uiState.update { currentState ->
                                    currentState.copy(
                                        isLoading = false,
                                        logsList = response.logs,
                                        availableParams = response.availableIdentifiers,
                                        selectedParamIdentifier = null,
                                        totalCount = response.totalCount,
                                        lastUpdateTime = getCurrentFormattedTime()
                                    )
                                }
                            }
                            ViewMode.LATEST -> {
                                val response = api.getEquipmentLogs(
                                    currentSelectedId,
                                    _uiState.value.selectedPeriod.name,
                                    null,
                                    1,
                                    8
                                )
                                val readingsResponse = api.getLatestReadings(currentSelectedId)

                                _uiState.update { currentState ->
                                    currentState.copy(
                                        isLoading = false,
                                        logsList = response.logs,
                                        availableParams = response.availableIdentifiers,
                                        selectedParamIdentifier = null,
                                        totalCount = response.totalCount,
                                        lastUpdateTime = getCurrentFormattedTime(),
                                        latestReadings = readingsResponse,
                                    )
                                }
                            }
                        }
                    } catch (_: Exception) {
                        _uiState.update { it.copy(isLoading = false, isConnected = false, isGraphLoading = false, logsList = emptyList(), totalCount = 0) }
                    }
                } else {
                    _uiState.update { it.copy(isLoading = false, logsList = emptyList(), totalCount = 0) }
                }
            } catch (_: Exception) {
                _uiState.update { it.copy(isLoading = false, isConnected = false) }
            }
        }
    }

    fun setFirstParam(){
        _uiState.update { currentState ->
            currentState.copy(
                selectedParamIdentifier = _uiState.value.selectedParamIdentifier ?: _uiState.value.availableParams.firstOrNull(),
                currentPage = 1
            )
        }
    }

    fun loadLatestReadings(){
        val deviceId = _uiState.value.selectedDeviceId ?: return
        viewModelScope.launch {
            try {
                val readingsResponse = api.getLatestReadings(deviceId)
                _uiState.update { currentState ->
                    currentState.copy(
                        isLoading = false,
                        latestReadings = readingsResponse
                    )
                }
            } catch (_: Exception) {
                _uiState.update { it.copy(isLoading = false) }
            }
        }
    }

    fun loadDeviceData() {
        val deviceId = _uiState.value.selectedDeviceId ?: return
        val period = _uiState.value.selectedPeriod.name
        val param = _uiState.value.selectedParamIdentifier
        val page = _uiState.value.currentPage
        val pageSize = 8

        viewModelScope.launch {
            try {
                val response = api.getEquipmentLogs(deviceId, period, param, page, pageSize)
                _uiState.update { currentState ->
                    currentState.copy(
                        isLoading = false,
                        isPageLoading = false,
                        logsList = response.logs,
                        availableParams = response.availableIdentifiers,
                        totalCount = response.totalCount
                    )
                }
            } catch (_: Exception) {
                _uiState.update { it.copy(isLoading = false, isPageLoading = false) }
            }
        }
    }

    fun loadGraphData() {
        val deviceId = _uiState.value.selectedDeviceId ?: return
        val period = _uiState.value.selectedPeriod.name

        viewModelScope.launch {
            _uiState.update { it.copy(isGraphLoading = true) }
            try {
                val points = api.getFullGraphData(deviceId, period).onEach { point -> if(point.value == "n/a") point.value = null }

                _uiState.update { currentState ->
                    currentState.copy(
                        isGraphLoading = false,
                        graphPoints = points
                    )
                }

                setFirstParam()
            } catch (_: Exception) {
                _uiState.update { it.copy(isGraphLoading = false) }
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    fun selectDevice(id: String) {
        sharedPrefs.edit {
            putString("selected_device_id", id)
        }

        _uiState.update { currentState ->
            currentState.copy(
                selectedDeviceId = id,
                currentPage = 1
            )
        }

        loadAllData()
    }

    fun refreshData() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isRefreshing = true)

            loadAllData()

            _uiState.value = _uiState.value.copy(
                isRefreshing = false
            )
        }
    }

    private fun tryAutoLogin() {
        val refreshToken = tokenManager.getRefreshToken()
        if (refreshToken.isNullOrBlank()) {
            _uiState.update { it.copy(isAutoLoginChecking = false, isAuthorized = false) }
            return
        }

        viewModelScope.launch {
            try {
                val response = api.refreshTokensAsync(RefreshRequest(refreshToken))
                tokenManager.saveTokens(response.accessToken, response.refreshToken)
                val fullName = listOfNotNull(response.lastName, response.firstName, response.middleName)
                    .joinToString(" ")
                    .ifBlank { " " }

                _uiState.update { it.copy(isAuthorized = true, userFullName = fullName) }
                loadAllData()
            } catch (e: retrofit2.HttpException) {
                tokenManager.clearTokens()
                _uiState.update { it.copy(isAuthorized = false) }
            } catch (e: java.io.IOException) {
                _uiState.update { it.copy(isAuthorized = false) }
            } finally {
                _uiState.update { it.copy(isAutoLoginChecking = false) }
            }
        }
    }

    suspend fun login(loginText: String, passwordText: String) {
        _uiState.update { it.copy(loginErrorMessage = null,isLoginLoading = true) }

        if (loginText.isNotBlank() && passwordText.isNotBlank()) {
            try {
                val response = api.login(LoginRequest(loginText, passwordText), getDeviceName())
                tokenManager.saveTokens(response.accessToken, response.refreshToken)

                val fullName = listOfNotNull(response.lastName, response.firstName, response.middleName)
                    .joinToString(" ")
                    .ifBlank { " " }

                _uiState.update { it.copy(
                    isAuthorized = true,
                    userFullName = fullName,
                    currentScreen = AppScreen.MONITORING
                ) }
                loadAllData()
            } catch (_: retrofit2.HttpException) {
                _uiState.update { it.copy(loginErrorMessage = R.string.error_login_failed) }
            } catch (_: java.io.IOException) {
                _uiState.update { it.copy(loginErrorMessage = R.string.error_api_no_response) }
            } finally {
                _uiState.update { it.copy(isLoginLoading = false) }
            }
        } else {
            _uiState.update { it.copy(loginErrorMessage = R.string.error_empty_fields, isLoginLoading = false) }
        }
    }

    fun loadConnectionSettings(address: String, port: String, httpsStatus: String){
        _uiState.value = _uiState.value.copy(
            apiAddress = address,
            apiPort = port,
            useHttps = httpsStatus
        )
        updateClient()
    }

    fun saveSettings(address: String, port: String, httpsStatus: String) {
        val isAddressValid = validateAddress(address)
        val isPortValid = validatePort(port)
        if (!isAddressValid || !isPortValid) {

            _uiState.update { currentState ->
                currentState.copy(
                    addressErrorResId = if (isAddressValid) null else R.string.error_invalid_address,
                    portErrorResId = if (isPortValid) null else R.string.error_invalid_port
                )
            }

            return
        }

        sharedPrefs.edit {
            putString("api_address", address.trim())
                .putString("api_port", port.trim())
                .putString("api_protocol", httpsStatus)
        }

        loadConnectionSettings(address, port, httpsStatus)

        _uiState.update { currentState ->
            currentState.copy(
                addressErrorResId = null,
                portErrorResId = null,
                isAddressSaved = true
            )
        }
    }

    fun onSettingsInputChanged(inputAddress: String, inputPort: String, httpsStatus: String) {
        _uiState.update { it.copy(
            apiAddress = inputAddress,
            apiPort = inputPort,
            useHttps = httpsStatus
        )}

        if (inputAddress.trim() == savedAddress && inputPort.trim() == savedPort) {
            _uiState.update { it.copy(
                connectionStatus = ConnectionStatus.SUCCESS,
                isAddressSaved = true
            )}
        } else {
            _uiState.update { it.copy(
                connectionStatus = ConnectionStatus.NOT_TESTED,
                isAddressSaved = false
            )}
        }
    }

    fun checkConnection(address: String, port: String, protocol: String) {
        val isAddressValid = validateAddress(address)
        val isPortValid = validatePort(port)

        if (!isAddressValid || !isPortValid) {
            _uiState.update { it.copy(
                addressErrorResId = if (isAddressValid) null else R.string.error_invalid_address,
                portErrorResId = if (isPortValid) null else R.string.error_invalid_port,
                connectionStatus = ConnectionStatus.FAILED
            ) }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isConnectionChecking = true, apiAddress = address, apiPort = port) }
            try {
                val testUrl = "http$protocol://${address.trim()}:${port.trim()}/api/ping"

                val response = api.checkApiHealth(testUrl)

                if (response.service == "SignalTrack.Api") {
                    _uiState.update { it.copy(isConnectionChecking = false, connectionStatus = ConnectionStatus.SUCCESS) }
                } else {
                    _uiState.update { it.copy(isConnectionChecking = false, connectionStatus = ConnectionStatus.FAILED) }
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(isConnectionChecking = false, connectionStatus = ConnectionStatus.FAILED) }
            }
        }
    }

    private fun validateAddress(address: String): Boolean{
        val ipWithDomainRegex = Regex("^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\$|^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,6}\$")
        return address.trim().matches(ipWithDomainRegex)
    }

    private fun validatePort(port: String): Boolean{
        val portInt = port.trim().toIntOrNull()
        return portInt != null && portInt in 1..65535
    }

    fun navigateTo(screen: AppScreen) {
        val isSettingsScreen = screen == AppScreen.SETTINGS
        _uiState.update { currentState ->
            currentState.copy(
                currentScreen = screen,
                addressErrorResId = if (isSettingsScreen) null else currentState.addressErrorResId,
                portErrorResId = if (isSettingsScreen) null else currentState.portErrorResId,
                connectionStatus = if (isSettingsScreen &&
                    currentState.apiAddress == savedAddress &&
                    currentState.apiPort == savedPort) {
                    ConnectionStatus.SUCCESS
                } else {
                    ConnectionStatus.NOT_TESTED
                }
            )
        }
    }

    fun logout() {
        val refreshToken = tokenManager.getRefreshToken()

        viewModelScope.launch {
            try {
                if (!refreshToken.isNullOrBlank()) {
                    NetworkClient.getApi().logoutServer(RefreshRequest(refreshToken))
                }
            } catch (_: Exception) {}
            finally {
                tokenManager.clearTokens()

                sharedPrefs.edit(commit = true) {
                    remove("selected_device_id")
                }

                _uiState.update { currentState ->
                    currentState.copy(
                        isAuthorized = false,
                        selectedDeviceId = null,
                        userFullName = " ",
                        currentPage = 1
                    )
                }
            }
        }
    }

    fun selectPeriod(period: PeriodType) {
        _uiState.update { it.copy(
            selectedPeriod = period,
            currentPage = 1)
        }
        loadDataForCurrentView()
    }

    fun selectParamIdentifier(identifier: String?) {
        _uiState.update {
            it.copy(selectedParamIdentifier = identifier,
                currentPage = 1)
        }
        loadDataForCurrentView()
    }

    fun changePage(page: Int) {
        if (page < 1 || _uiState.value.isPageLoading || _uiState.value.isLoading) return
        _uiState.update { it.copy(currentPage = page, isPageLoading = true) }
        loadDeviceData()
    }

    fun toggleViewMode(newMode: ViewMode) {
        _uiState.update { it.copy(viewMode = newMode) }
        loadDataForCurrentView()
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun getCurrentFormattedTime(): String {
        return LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd.MM.yyyy HH:mm:ss"))
    }

    fun getParamColor(paramId: String): Color {
        val hash = paramId.hashCode()
        return Color(
            red = (hash and 0xFF0000 shr 16) / 255f * 0.6f + 0.4f,
            green = (hash and 0x00FF00 shr 8) / 255f * 0.6f + 0.4f,
            blue = (hash and 0x0000FF) / 255f * 0.6f + 0.4f,
            alpha = 1f
        )
    }

    fun getDeviceName(): String {
        val manufacturer = Build.MANUFACTURER
        val model = Build.MODEL
        return if (model.startsWith(manufacturer)) {
            model
        } else {
            "$manufacturer $model"
        }
    }

}