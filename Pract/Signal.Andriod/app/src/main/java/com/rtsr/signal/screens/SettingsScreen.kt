package com.rtsr.signal.screens

import androidx.compose.animation.Crossfade
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.rtsr.signal.R
import com.rtsr.signal.models.AppScreen
import com.rtsr.signal.models.ConnectionStatus
import com.rtsr.signal.models.MainUiState
import java.nio.file.WatchEvent

@Composable
fun SettingsScreen(
    uiState: MainUiState,
    onSaveClick: (String, String, String) -> Unit,
    onFieldsValueChange: (String, String, String) -> Unit,
    onCheckConnectionClick: (String, String, String) -> Unit,
    onBack: (AppScreen) -> Unit,
    screen: AppScreen
) {
    val colorScheme = MaterialTheme.colorScheme

    var httpsStatus by remember { mutableStateOf(uiState.useHttps) }
    val isChecked = httpsStatus == "s"

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = stringResource(R.string.settings_title),
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(bottom = 32.dp, top = 16.dp)
        )

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            OutlinedTextField(
                value = uiState.apiAddress,
                onValueChange = { newAddress ->
                    onFieldsValueChange(newAddress, uiState.apiPort, uiState.useHttps)
                },
                label = { Text(stringResource(R.string.api_address_hint)) },
                modifier = Modifier.weight(0.7f),
                isError = uiState.addressErrorResId != null,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                supportingText = {
                    uiState.addressErrorResId?.let { resId ->
                        Text(text = stringResource(resId), color = colorScheme.error)
                    }
                },
                enabled = !uiState.isConnectionChecking
            )

            OutlinedTextField(
                value = uiState.apiPort,
                onValueChange = { newPort ->
                    onFieldsValueChange(uiState.apiAddress, newPort, uiState.useHttps)
                },
                label = { Text(stringResource(R.string.port_hint)) },
                modifier = Modifier.weight(0.3f),
                isError = uiState.portErrorResId != null,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                supportingText = {
                    uiState.portErrorResId?.let { resId ->
                        Text(text = stringResource(resId), color = colorScheme.error)
                    }
                },
                enabled = !uiState.isConnectionChecking
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Button(
                onClick = { onSaveClick(uiState.apiAddress, uiState.apiPort, httpsStatus) },
                modifier = Modifier
                    .weight(0.5f)
                    .height(50.dp),
                enabled = uiState.connectionStatus == ConnectionStatus.SUCCESS && !uiState.isConnectionChecking
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center
                ) {
                    Text(
                        text = stringResource(R.string.btn_save),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )

                    Spacer(modifier = Modifier.width(8.dp))

                    val icon = if (uiState.isAddressSaved) Icons.Default.Check else Icons.Default.Clear
                    val iconContentDescription = if (uiState.isAddressSaved) "Saved" else "Unsaved"

                    Icon(
                        imageVector = icon,
                        contentDescription = iconContentDescription,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }

            Button(
                onClick = { onCheckConnectionClick(uiState.apiAddress, uiState.apiPort, uiState.useHttps) },
                modifier = Modifier
                    .weight(0.5f)
                    .height(50.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = when (uiState.connectionStatus) {
                        ConnectionStatus.SUCCESS -> colorScheme.surfaceVariant
                        ConnectionStatus.FAILED -> colorScheme.errorContainer
                        ConnectionStatus.NOT_TESTED -> colorScheme.primary
                    }
                ),
                enabled = !uiState.isConnectionChecking
            ) {
                if (uiState.isConnectionChecking) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        color = colorScheme.onPrimary,
                        strokeWidth = 2.dp
                    )
                } else {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Text(
                            text = stringResource(R.string.btn_check_connection),
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Crossfade(targetState = uiState.connectionStatus, label = "icon") { status ->
                            when (status) {
                                ConnectionStatus.SUCCESS -> Icon(Icons.Default.Check, contentDescription = "OK")
                                ConnectionStatus.FAILED -> Icon(Icons.Default.Clear, contentDescription = "Fail")
                                ConnectionStatus.NOT_TESTED -> Icon(Icons.Default.Warning, contentDescription = "Warning")
                            }
                        }
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        Switch(
            checked = isChecked,
            onCheckedChange = { checked ->
                httpsStatus = if (checked) "s" else ""
                onFieldsValueChange(uiState.apiAddress, uiState.apiPort, httpsStatus)
            }
        )
        Text(
            text = stringResource(R.string.str_use_https),
            modifier = Modifier.padding(start = 8.dp)
        )

        Spacer(modifier = Modifier.height(8.dp))

        TextButton(
            onClick = { onBack(screen) },
            content = {
                Text(
                    text = stringResource(R.string.btn_back),
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold
                )
            }
        )
    }
}