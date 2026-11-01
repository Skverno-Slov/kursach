package com.rtsr.signal.screens

import android.os.Build
import androidx.annotation.RequiresApi
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.rtsr.signal.models.AppScreen
import com.rtsr.signal.viewmodel.AppViewModel
import kotlinx.coroutines.launch

@RequiresApi(Build.VERSION_CODES.O)
@Composable
fun AppNavigationScreen(vm: AppViewModel) {
    val uiState by vm.uiState.collectAsState()

    when {
        uiState.isAutoLoginChecking -> {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        }

        !uiState.isAuthorized -> {
            when (uiState.currentScreen){
                AppScreen.SETTINGS -> {
                    SettingsScreen(
                        uiState = vm.uiState.collectAsState().value,
                        onSaveClick = { address, port, protocol -> vm.saveSettings(address, port, protocol) },
                        onFieldsValueChange = { address, port, protocol ->
                            vm.onSettingsInputChanged(
                                address,
                                port,
                                protocol
                            )
                        },
                        onCheckConnectionClick = { address, port, protocol ->
                            vm.checkConnection(
                                address,
                                port,
                                protocol
                            )
                        },
                        onBack = { screen -> vm.navigateTo(screen) },
                        screen = AppScreen.MONITORING
                    )
                }
                else -> {
                    AuthorizationScreen(
                        uiState = uiState,
                        onLoginClick = { login, password ->
                            vm.login(login, password)
                        },
                        toSettingsClick = { targetScreen: AppScreen ->
                            vm.navigateTo(targetScreen)
                        },
                        screen = AppScreen.SETTINGS
                    )
                }
            }
        }

        else -> {
            MainNavigationContainer(vm)
        }
    }
}