package com.rtsr.signal.screens

import android.graphics.Typeface
import android.os.Build
import android.text.Layout
import android.text.SpannableStringBuilder
import android.text.TextUtils
import android.text.style.AbsoluteSizeSpan
import android.text.style.ForegroundColorSpan
import android.text.style.StyleSpan
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.ExitToApp
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material.icons.outlined.CloudOff
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.ShowChart
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DrawerValue
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.MaterialTheme.colorScheme
import androidx.compose.material3.ModalDrawerSheet
import androidx.compose.material3.ModalNavigationDrawer
import androidx.compose.material3.NavigationDrawerItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.material3.rememberDrawerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.rtsr.signal.R
import com.rtsr.signal.models.AppScreen
import com.rtsr.signal.models.MainUiState
import com.rtsr.signal.models.PeriodType
import com.rtsr.signal.viewmodel.AppViewModel
import kotlinx.coroutines.launch
import kotlin.collections.map
import kotlin.math.ceil

import com.patrykandpatrick.vico.compose.cartesian.CartesianChartHost
import com.patrykandpatrick.vico.compose.cartesian.layer.rememberLineCartesianLayer
import com.patrykandpatrick.vico.compose.cartesian.layer.rememberLine
import com.patrykandpatrick.vico.compose.cartesian.rememberCartesianChart
import com.patrykandpatrick.vico.compose.cartesian.axis.rememberBottom
import com.patrykandpatrick.vico.compose.cartesian.axis.rememberStart
import com.patrykandpatrick.vico.compose.cartesian.marker.rememberDefaultCartesianMarker
import com.patrykandpatrick.vico.compose.cartesian.rememberVicoZoomState
import com.patrykandpatrick.vico.compose.common.component.rememberShapeComponent
import com.patrykandpatrick.vico.compose.common.component.rememberTextComponent
import com.patrykandpatrick.vico.compose.common.fill
import com.patrykandpatrick.vico.core.cartesian.Zoom
import com.patrykandpatrick.vico.core.cartesian.axis.HorizontalAxis
import com.patrykandpatrick.vico.core.cartesian.axis.VerticalAxis
import com.patrykandpatrick.vico.core.cartesian.data.CartesianChartModelProducer
import com.patrykandpatrick.vico.core.cartesian.data.lineSeries
import com.patrykandpatrick.vico.core.cartesian.layer.LineCartesianLayer
import com.patrykandpatrick.vico.core.cartesian.marker.LineCartesianLayerMarkerTarget
import com.patrykandpatrick.vico.core.common.Insets
import com.rtsr.signal.dtos.LatestReadingResponse
import com.rtsr.signal.models.ViewMode

@RequiresApi(Build.VERSION_CODES.O)
@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun MainNavigationContainer(vm: AppViewModel) {
    val uiState by vm.uiState.collectAsState()
    val drawerState = rememberDrawerState(initialValue = DrawerValue.Closed)
    val scope = rememberCoroutineScope()

    val pagerState = rememberPagerState(pageCount = { 2 })

    ModalNavigationDrawer(
        drawerState = drawerState,
        drawerContent = {
            ModalDrawerSheet {
                Spacer(modifier = Modifier.height(16.dp))
                NavigationDrawerItem(
                    icon = { Icon(Icons.Default.Home, contentDescription = null) },
                    label = { Text(stringResource(R.string.menu_monitoring)) },
                    selected = uiState.currentScreen == AppScreen.MONITORING,
                    onClick = {
                        vm.navigateTo(AppScreen.MONITORING)
                        scope.launch { drawerState.close() }
                    }
                )
                NavigationDrawerItem(
                    icon = { Icon(Icons.Default.Settings, contentDescription = null) },
                    label = { Text(stringResource(R.string.menu_settings)) },
                    selected = uiState.currentScreen == AppScreen.SETTINGS,
                    onClick = {
                        vm.navigateTo(AppScreen.SETTINGS)
                        scope.launch { drawerState.close() }
                    }
                )
                NavigationDrawerItem(
                    icon = { Icon(Icons.Default.Info, contentDescription = null) },
                    label = { Text(stringResource(R.string.menu_report_issue)) },
                    selected = false,
                    onClick = {
                        vm.navigateTo(AppScreen.CONTACT)
                        scope.launch { drawerState.close() }
                    }
                )
                NavigationDrawerItem(
                    icon = { Icon(Icons.Default.ExitToApp, contentDescription = null) },
                    label = { Text(stringResource(R.string.menu_logout)) },
                    selected = false,
                    onClick = { vm.logout() }
                )
            }
        }
    ) {
        Scaffold(
            topBar = {
                TopAppBar(
                    title = {},
                    navigationIcon = {
                        IconButton(onClick = { scope.launch { drawerState.open() } }) {
                            Icon(Icons.Default.Menu, contentDescription = "", tint = MaterialTheme.colorScheme.onPrimary)
                        }
                    },
                    actions = {
                        Text(
                            text = uiState.userFullName,
                            modifier = Modifier.padding(end = 16.dp),
                            color = MaterialTheme.colorScheme.onPrimary
                        )
                    },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant,
                        navigationIconContentColor = MaterialTheme.colorScheme.onSurfaceVariant,
                        actionIconContentColor = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                )
            },
            bottomBar = {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(MaterialTheme.colorScheme.surfaceVariant)
                        .windowInsetsPadding(WindowInsets.navigationBars)
                        .padding(8.dp),
                    contentAlignment = Alignment.CenterStart
                ) {
                    Text(
                        text = stringResource(R.string.footer_copyright),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onPrimary
                    )
                }
            }
        ) { paddingValues ->
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
            ) {
                when (uiState.currentScreen) {
                    AppScreen.SETTINGS -> {
                        SettingsScreen(
                            uiState = vm.uiState.collectAsState().value,
                            onSaveClick = { address, port, protocol -> vm.saveSettings(address, port, protocol) },
                            onFieldsValueChange = { address, port, protocol -> vm.onSettingsInputChanged(address, port, protocol) },
                            onCheckConnectionClick = { address, port, protocol -> vm.checkConnection(address, port, protocol) },
                            onBack = { screen -> vm.navigateTo(screen) },
                            screen = AppScreen.MONITORING
                        )
                    }
                    AppScreen.CONTACT ->{
                        ContactScreen()
                    }
                    AppScreen.MONITORING -> {
                        when {
                            uiState.isLoading -> {
                                LoadingStateScreen()
                            }

                            !uiState.isConnected -> {
                                EmptyStateScreen({ vm.loadAllData() })
                            }

                            else -> {
                                PullToRefreshBox(
                                    isRefreshing = uiState.isRefreshing,
                                    onRefresh = { vm.refreshData() },
                                    modifier = Modifier.fillMaxSize()
                                ) {
                                    HorizontalPager(
                                        state = pagerState,
                                        modifier = Modifier
                                            .fillMaxSize()
                                    ) { page ->
                                        when (page) {
                                            0 -> DashboardScreen(
                                                vm.uiState.collectAsState().value,
                                                { period -> vm.selectPeriod(period) },
                                                { isGraph -> vm.toggleViewMode(isGraph) },
                                                { paramId -> vm.selectParamIdentifier(paramId) },
                                                { pageNum -> vm.changePage(pageNum) },
                                                {paramId -> vm.getParamColor(paramId)}
                                            )

                                            1 -> DeviceListScreen(
                                                uiState,
                                                { deviceId ->
                                                    vm.selectDevice(deviceId)
                                                    scope.launch { pagerState.animateScrollToPage(0) }
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}


@RequiresApi(Build.VERSION_CODES.O)
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(
    uiState: MainUiState,
    onPeriodSelected: (PeriodType) -> Unit,
    onViewModeChanged: (ViewMode) -> Unit,
    onParamSelected: (String?) -> Unit,
    onPageSelected: (Int) -> Unit,
    getParamColor: (String) -> Color
) {
    val currentDevice = uiState.devices.find { it.serialNumber == uiState.selectedDeviceId }
    val colorScheme = MaterialTheme.colorScheme

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp)
    ) {
        item {
            Spacer(modifier = Modifier.height(16.dp))
            Text(text = stringResource(R.string.data_actual_at, uiState.lastUpdateTime), style = MaterialTheme.typography.bodySmall, color = Color.Gray)
            Spacer(modifier = Modifier.height(4.dp))
            Text(text = currentDevice?.name ?: "—", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
            Spacer(modifier = Modifier.height(12.dp))

            if(uiState.viewMode != ViewMode.LATEST) {
                val isGraphView = uiState.viewMode == ViewMode.GRAPH
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    if (!isGraphView) {
                        item {
                            FilterChip(
                                selected = uiState.selectedParamIdentifier == null,
                                onClick = { onParamSelected(null) },
                                label = { Text(stringResource(R.string.str_all)) },
                                border = FilterChipDefaults.filterChipBorder(
                                    enabled = true,
                                    selected = uiState.selectedParamIdentifier == null,
                                    borderColor = Color.Gray,
                                    selectedBorderColor = MaterialTheme.colorScheme.primary
                                )
                            )
                        }
                    }
                    items(uiState.availableParams) { paramId ->
                        val paramColor = remember(paramId) { getParamColor(paramId) }
                        FilterChip(
                            selected = uiState.selectedParamIdentifier == paramId,
                            onClick = { onParamSelected(paramId) },
                            label = { Text(paramId) },
                            border = FilterChipDefaults.filterChipBorder(
                                enabled = true,
                                selected = uiState.selectedParamIdentifier == paramId,
                                borderColor = paramColor,
                                selectedBorderColor = paramColor,
                                selectedBorderWidth = 2.dp
                            )
                        )
                    }
                }
                Spacer(modifier = Modifier.height(12.dp))
            }
        }

        when (uiState.viewMode) {
            ViewMode.GRAPH -> {
                item {
                    if (uiState.isGraphLoading) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(280.dp), contentAlignment = Alignment.Center
                        ) {
                            CircularProgressIndicator()
                        }
                    } else {
                        val filteredPoints =
                            remember(uiState.graphPoints, uiState.selectedParamIdentifier) {
                                if (uiState.selectedParamIdentifier == null) {
                                    uiState.graphPoints
                                } else {
                                    uiState.graphPoints.filter { it.param == uiState.selectedParamIdentifier }
                                }
                            }

                        val pointsByParam = remember(filteredPoints) {
                            filteredPoints.groupBy { it.param }
                        }

                        val modelProducer = remember { CartesianChartModelProducer() }

                        val xDateLabels = remember(filteredPoints) {
                            filteredPoints.map { it.dt }.distinct().sorted()
                        }

                        val hasAnyNumericData = remember(pointsByParam) {
                            pointsByParam.values.any { points ->
                                points.any { it.value?.toFloatOrNull() != null }
                            }
                        }

                        if (pointsByParam.isNotEmpty() && hasAnyNumericData) {
                            LaunchedEffect(pointsByParam, xDateLabels) {
                                if (pointsByParam.isNotEmpty() && xDateLabels.isNotEmpty()) {
                                    modelProducer.runTransaction {
                                        lineSeries {
                                            pointsByParam.forEach { (_, points) ->
                                                val segments =
                                                    mutableListOf<MutableList<Pair<Float, Float>>>()
                                                var currentSegment =
                                                    mutableListOf<Pair<Float, Float>>()

                                                points.forEach { point ->
                                                    val xValue =
                                                        xDateLabels.indexOf(point.dt).toFloat()
                                                    val yValue = point.value?.toFloatOrNull()

                                                    if (yValue != null && xValue >= 0) {
                                                        currentSegment.add(xValue to yValue)
                                                    } else {
                                                        if (currentSegment.isNotEmpty()) {
                                                            segments.add(currentSegment)
                                                            currentSegment = mutableListOf()
                                                        }
                                                    }
                                                }
                                                if (currentSegment.isNotEmpty()) {
                                                    segments.add(currentSegment)
                                                }

                                                segments.forEach { segment ->
                                                    series(
                                                        x = segment.map { it.first },
                                                        y = segment.map { it.second }
                                                    )
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        if (pointsByParam.isNotEmpty() && hasAnyNumericData) {

                            val lineProvider = LineCartesianLayer.LineProvider.series(
                                pointsByParam.keys.map { paramId ->
                                    val paramColor = getParamColor(paramId)
                                    LineCartesianLayer.rememberLine(
                                        fill = LineCartesianLayer.LineFill.single(fill(paramColor))
                                    )
                                }
                            )

                            val density = androidx.compose.ui.platform.LocalDensity.current
                            val valueTextSizePx =
                                remember(density) { with(density) { 18.sp.toPx().toInt() } }
                            val dateTextSizePx =
                                remember(density) { with(density) { 12.sp.toPx().toInt() } }

                            val defaultMarker = rememberDefaultCartesianMarker(
                                label = rememberTextComponent(
                                    color = Color.White,
                                    background = rememberShapeComponent(
                                        shape = com.patrykandpatrick.vico.core.common.shape.Shape.Rectangle,
                                        fill = fill(MaterialTheme.colorScheme.surface.copy(alpha = 0.95f))
                                    ),
                                    lineCount = 3,
                                    truncateAt = TextUtils.TruncateAt.MARQUEE,
                                    textAlignment = Layout.Alignment.ALIGN_CENTER,
                                    padding = Insets(horizontalDp = 12f, verticalDp = 8f),
                                    minWidth = com.patrykandpatrick.vico.core.common.component.TextComponent.MinWidth.fixed(
                                        160f
                                    )
                                ),
                                valueFormatter = { _, targets ->
                                    val lineTarget =
                                        targets.firstOrNull() as? LineCartesianLayerMarkerTarget
                                    val xIndex = lineTarget?.x?.toInt() ?: 0

                                    val rawY = lineTarget?.points?.firstOrNull()?.entry?.y
                                    val yValue = if (rawY != null) {
                                        String.format(java.util.Locale.US, "%.2f", rawY)
                                            .dropLastWhile { it == '0' }
                                            .dropLastWhile { it == '.' }
                                    } else {
                                        "0.0"
                                    }

                                    val fullDateTime = xDateLabels.getOrNull(xIndex) ?: "—"
                                    val formattedTime = try {
                                        val instant = java.time.Instant.parse(fullDateTime)

                                        val localDateTime = java.time.LocalDateTime.ofInstant(
                                            instant,
                                            java.time.ZoneId.systemDefault()
                                        )

                                        val outputFormatter =
                                            java.time.format.DateTimeFormatter.ofPattern("yyyy:MM:dd HH:mm:ss")
                                        localDateTime.format(outputFormatter)
                                    } catch (_: Exception) {
                                        try {
                                            val cleanFormat =
                                                fullDateTime.take(19).replace("T", " ")
                                            val inputFormatter =
                                                java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")
                                            val outputFormatter =
                                                java.time.format.DateTimeFormatter.ofPattern("yyyy:MM:dd HH:mm:ss")
                                            java.time.LocalDateTime.parse(
                                                cleanFormat,
                                                inputFormatter
                                            ).format(outputFormatter)
                                        } catch (_: Exception) {
                                            fullDateTime
                                        }
                                    }

                                    SpannableStringBuilder().apply {
                                        val valueStart = length
                                        append(yValue)
                                        val valueEnd = length

                                        setSpan(StyleSpan(Typeface.BOLD), valueStart, valueEnd, 0)
                                        setSpan(
                                            ForegroundColorSpan(android.graphics.Color.WHITE),
                                            valueStart,
                                            valueEnd,
                                            0
                                        )
                                        setSpan(
                                            AbsoluteSizeSpan(valueTextSizePx, false),
                                            valueStart,
                                            valueEnd,
                                            0
                                        )

                                        append("\n")

                                        val dateStart = length
                                        append(formattedTime)
                                        val dateEnd = length

                                        setSpan(
                                            ForegroundColorSpan(
                                                android.graphics.Color.parseColor(
                                                    "#A0A0A0"
                                                )
                                            ), dateStart, dateEnd, 0
                                        )
                                        setSpan(
                                            AbsoluteSizeSpan(dateTextSizePx, false),
                                            dateStart,
                                            dateEnd,
                                            0
                                        )
                                    }
                                }
                            )

                            val chart = rememberCartesianChart(
                                rememberLineCartesianLayer(lineProvider = lineProvider),
                                startAxis = VerticalAxis.rememberStart(
                                    label = rememberTextComponent(color = MaterialTheme.colorScheme.onBackground)
                                ),
                                bottomAxis = HorizontalAxis.rememberBottom(
                                    label = rememberTextComponent(color = MaterialTheme.colorScheme.onBackground),
                                    labelRotationDegrees = 0f,
                                    valueFormatter = { _, value, _ ->
                                        val index = kotlin.math.round(value).toInt()
                                        val fullDateTime = xDateLabels.getOrNull(index) ?: ""

                                        if (fullDateTime.isEmpty()) {
                                            ""
                                        } else {
                                            try {
                                                val instant = java.time.Instant.parse(fullDateTime)
                                                val localDateTime =
                                                    java.time.LocalDateTime.ofInstant(
                                                        instant,
                                                        java.time.ZoneId.systemDefault()
                                                    )
                                                localDateTime.format(
                                                    java.time.format.DateTimeFormatter.ofPattern(
                                                        "yyyy.MM.dd"
                                                    )
                                                )
                                            } catch (_: Exception) {
                                                try {
                                                    val cleanFormat =
                                                        fullDateTime.take(19).replace("T", " ")
                                                    val inputFormatter =
                                                        java.time.format.DateTimeFormatter.ofPattern(
                                                            "yyyy-MM-dd HH:mm:ss"
                                                        )
                                                    val outputFormatter =
                                                        java.time.format.DateTimeFormatter.ofPattern(
                                                            "yyyy.MM.dd"
                                                        )
                                                    java.time.LocalDateTime.parse(
                                                        cleanFormat,
                                                        inputFormatter
                                                    ).format(outputFormatter)
                                                } catch (_: Exception) {
                                                    fullDateTime.take(10).replace("-", ".")
                                                }
                                            }
                                        }
                                    },
                                    itemPlacer = HorizontalAxis.ItemPlacer.aligned(
                                        spacing = { 4 },
                                        addExtremeLabelPadding = true
                                    )
                                ),
                                marker = defaultMarker
                            )

                            CartesianChartHost(
                                chart = chart,
                                modelProducer = modelProducer,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(320.dp),
                                zoomState = rememberVicoZoomState(
                                    minZoom = Zoom.Content,
                                    maxZoom = Zoom.fixed(8f)
                                )
                            )
                        } else if(pointsByParam.isNotEmpty()) {
                            Column(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(320.dp),
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.Center
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Clear,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.error,
                                    modifier = Modifier
                                        .size(48.dp)
                                        .padding(bottom = 8.dp)
                                )
                                Text(
                                    text = stringResource(R.string.err_graph_unavalable),
                                    style = MaterialTheme.typography.bodyLarge,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                    textAlign = TextAlign.Center
                                )
                            }
                        } else{
                            Column(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(320.dp),
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.Center
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Clear,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.error,
                                    modifier = Modifier
                                        .size(48.dp)
                                        .padding(bottom = 8.dp)
                                )
                                Text(
                                    text = stringResource(R.string.err_graf_no_data),
                                    style = MaterialTheme.typography.bodyLarge,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                    textAlign = TextAlign.Center
                                )
                            }
                        }
                    }
                }
            }

            ViewMode.TABLE -> {
                item {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(4.dp)
                    ) {
                        if (uiState.isPageLoading) {
                            LinearProgressIndicator(
                                modifier = Modifier.fillMaxWidth(),
                                color = colorScheme.primary,
                                trackColor = Color.Transparent
                            )
                        }
                    }
                }

                item {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 8.dp),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = stringResource(R.string.header_param_name),
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.weight(1.5f)
                        )
                        Text(
                            text = stringResource(R.string.header_param_value),
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.weight(1.5f),
                            textAlign = TextAlign.End
                        )
                        Text(
                            text = stringResource(R.string.header_status_name),
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.weight(1f),
                            textAlign = TextAlign.End
                        )
                        Text(
                            text = stringResource(R.string.header_param_date),
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.weight(2f),
                            textAlign = TextAlign.End
                        )
                    }
                    HorizontalDivider(color = colorScheme.outlineVariant)
                }

                items(uiState.logsList) { log ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .graphicsLayer {
                                alpha = if (uiState.isPageLoading) 0.5f else 1f
                            }
                            .padding(vertical = 10.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = log.readingName,
                            style = MaterialTheme.typography.bodyMedium,
                            modifier = Modifier.weight(1.5f)
                        )
                        Text(
                            text = "${log.readingValue} ${log.readingUnit ?: ""}".trim(),
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.weight(1.5f),
                            textAlign = TextAlign.End
                        )
                        Text(
                            text = log.readingStatus.trim(),
                            style = MaterialTheme.typography.bodySmall,
                            fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.weight(1f),
                            textAlign = TextAlign.End
                        )
                        Text(
                            text = log.writeDateTime.take(16).replace("T", " "),
                            style = MaterialTheme.typography.bodySmall,
                            color = Color.Gray,
                            modifier = Modifier.weight(2f),
                            textAlign = TextAlign.End
                        )
                    }
                    HorizontalDivider(color = colorScheme.outlineVariant.copy(alpha = 0.3f))
                }

                if (uiState.logsList.isNotEmpty()) {
                    item {
                        PaginationControl(
                            currentPage = uiState.currentPage,
                            totalCount = uiState.totalCount,
                            pageSize = 8,
                            onPageChanged = { newPage ->
                                if (!uiState.isPageLoading) onPageSelected(newPage)
                            }
                        )
                    }
                }
            }

            ViewMode.LATEST -> {
                if (uiState.latestReadings.isEmpty() && !uiState.isLoading) {
                    item {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(200.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(text = stringResource(R.string.err_no_actual_data), color = Color.Gray)
                        }
                    }
                } else {
                    items(uiState.latestReadings) { reading ->
                        LatestReadingCard(
                            reading = reading,
                            getParamColor = getParamColor
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                    }
                }
            }
        }

        if (uiState.isLoading && uiState.logsList.isEmpty()) {
            item {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(32.dp), contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(modifier = Modifier.size(32.dp))
                }
            }
        }

        item {
            Spacer(modifier = Modifier.height(8.dp))
            Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween) {
                if (uiState.viewMode != ViewMode.LATEST) {
                    var expanded by remember { mutableStateOf(false) }
                    Box {
                        Button(onClick = { expanded = true }) {
                            Text(stringResource(uiState.selectedPeriod.resId))
                            Icon(Icons.Default.ArrowDropDown, contentDescription = null)
                        }
                        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
                            PeriodType.entries.forEach { period ->
                                DropdownMenuItem(
                                    text = { Text(stringResource(period.resId)) },
                                    onClick = { onPeriodSelected(period); expanded = false })
                            }
                        }
                    }
                }

                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Absolute.Right) {
                    IconButton(
                        onClick = { onViewModeChanged(ViewMode.LATEST) },
                        colors = IconButtonDefaults.iconButtonColors(
                            containerColor = if (uiState.viewMode == ViewMode.LATEST) colorScheme.primary else Color.Transparent,
                            contentColor = if (uiState.viewMode == ViewMode.LATEST) colorScheme.onPrimary else colorScheme.onSurface
                        )
                    ) {
                        Icon(Icons.Outlined.Info, contentDescription = "Latest readings")
                    }

                    IconButton(
                        onClick = { onViewModeChanged(ViewMode.GRAPH) },
                        colors = IconButtonDefaults.iconButtonColors(
                            containerColor = if (uiState.viewMode == ViewMode.GRAPH) colorScheme.primary else Color.Transparent,
                            contentColor = if (uiState.viewMode == ViewMode.GRAPH) colorScheme.onPrimary else colorScheme.onSurface
                        )
                    ) {
                        Icon(Icons.Outlined.ShowChart, contentDescription = "Metric/Graph")
                    }

                    IconButton(
                        onClick = { onViewModeChanged(ViewMode.TABLE) },
                        colors = IconButtonDefaults.iconButtonColors(
                            containerColor = if (uiState.viewMode == ViewMode.TABLE) colorScheme.primary else Color.Transparent,
                            contentColor = if (uiState.viewMode == ViewMode.TABLE) colorScheme.onPrimary else colorScheme.onSurface
                        )
                    ) {
                        Icon(Icons.Default.List, contentDescription = "Table/Logs")
                    }
                }
            }
            Spacer(modifier = Modifier.height(24.dp))
        }
    }
}

@Composable
fun LatestReadingCard(
    reading: LatestReadingResponse,
    getParamColor: (String) -> Color,
    modifier: Modifier = Modifier
) {
    val borderColor = getParamColor(reading.metricKey)

    val (statusIcon, statusColor) = when (reading.status.uppercase()) {
        "WARNING" -> Icons.Default.Warning to Color(0xFFFFB300)
        "ERROR" -> Icons.Default.Clear to Color(0xFFE53935)
        else -> Icons.Default.Check to Color(0xFF43A047)
    }

    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)),
        border = BorderStroke(2.dp, borderColor)
    ) {
        Row(
            modifier = Modifier
                .padding(16.dp)
                .fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = reading.label,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface
                )

                Spacer(modifier = Modifier.height(4.dp))

                val minStr = reading.minValue?.let { it } ?: " — "
                val maxStr = reading.maxValue?.let { it } ?: " — "

                Text(
                    text = "$minStr  |  $maxStr",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.Gray
                )
            }

            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(
                    text = "${reading.value} ${reading.unit ?: ""}".trim(),
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )

                Icon(
                    imageVector = statusIcon,
                    contentDescription = reading.status,
                    tint = statusColor,
                    modifier = Modifier.size(28.dp)
                )
            }
        }
    }
}

@Composable
fun PaginationControl(
    currentPage: Int,
    totalCount: Int,
    pageSize: Int = 8,
    onPageChanged: (Int) -> Unit
) {
    val maxPages = ceil(totalCount.toDouble() / pageSize).toInt().coerceAtLeast(1)

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 16.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically
    ) {
        TextButton(
            onClick = { onPageChanged(1) },
            enabled = currentPage > 1
        ) { Text("◀◀", fontWeight = FontWeight.Bold) }

        TextButton(
            onClick = { onPageChanged(currentPage - 1) },
            enabled = currentPage > 1
        ) { Text("◀", fontWeight = FontWeight.Bold) }

        Card(
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer),
            modifier = Modifier.padding(horizontal = 8.dp)
        ) {
            Text(
                text = "$currentPage / $maxPages",
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )
        }

        TextButton(
            onClick = { onPageChanged(currentPage + 1) },
            enabled = currentPage < maxPages
        ) { Text("▶", fontWeight = FontWeight.Bold) }

        TextButton(
            onClick = { onPageChanged(maxPages) },
            enabled = currentPage < maxPages
        ) { Text("▶▶", fontWeight = FontWeight.Bold) }
    }
}

@OptIn(ExperimentalFoundationApi::class, ExperimentalMaterial3Api::class)
@Composable
fun DeviceListScreen(
    uiState: MainUiState,
    onDeviceSelected: (String) -> Unit
) {
    val groupedDevices = remember(uiState.devices) {
        uiState.devices.groupBy { it.model }
    }

    val expandedStates = remember {
        mutableStateMapOf<String, Boolean>().apply {
            groupedDevices.keys.forEach { model -> this[model] = true }
        }
    }

    Column(modifier = Modifier.fillMaxSize()) {
        Text(
            text = stringResource(R.string.connected_devices),
            style = MaterialTheme.typography.titleLarge,
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            textAlign = TextAlign.Center,
            fontWeight = FontWeight.Bold
        )

        LazyColumn(modifier = Modifier.fillMaxSize()) {
            groupedDevices.forEach { (model, devices) ->
                val isExpanded = expandedStates[model] ?: true

                stickyHeader {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(MaterialTheme.colorScheme.surfaceVariant)
                            .clickable {
                                expandedStates[model] = !isExpanded
                            }
                            .padding(horizontal = 16.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = model,
                            style = MaterialTheme.typography.labelLarge,
                            fontWeight = FontWeight.Black,
                            color = MaterialTheme.colorScheme.onPrimary
                        )
                        Icon(
                            imageVector = if (isExpanded) Icons.Default.KeyboardArrowUp else Icons.Default.KeyboardArrowDown,
                            contentDescription = if (isExpanded) "Hide" else "Expand",
                            tint = MaterialTheme.colorScheme.onPrimary
                        )
                    }
                }

                if (isExpanded) {
                    items(devices) { device ->
                        val isSelected = device.serialNumber == uiState.selectedDeviceId

                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(if (isSelected) MaterialTheme.colorScheme.primaryContainer else Color.Transparent)
                                .clickable { onDeviceSelected(device.serialNumber) }
                                .padding(16.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = device.name,
                                    style = MaterialTheme.typography.bodyLarge,
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                                )
                                Text(
                                    text = device.statusName,
                                    style = MaterialTheme.typography.bodySmall,
                                    color = Color.Gray
                                )
                            }
                            if (isSelected) {
                                Icon(
                                    imageVector = Icons.Default.Check,
                                    contentDescription = "Checked",
                                    tint = colorScheme.onSurface
                                )
                            }
                        }
                        HorizontalDivider(color = colorScheme.outlineVariant.copy(alpha = 0.5f))
                    }
                }
            }
        }
    }
}

@Composable
fun LoadingStateScreen() {
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        CircularProgressIndicator(color = MaterialTheme.colorScheme.primary)
    }
}

@RequiresApi(Build.VERSION_CODES.O)
@Composable
fun EmptyStateScreen(onRefresh: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            imageVector = Icons.Outlined.CloudOff,
            contentDescription = null,
            modifier = Modifier.size(64.dp),
            tint = MaterialTheme.colorScheme.primary.copy(alpha = 0.6f)
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = stringResource(R.string.state_empty_title),
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onBackground
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = stringResource(R.string.state_empty_subtitle),
            style = MaterialTheme.typography.bodyMedium,
            color = Color.Gray,
            textAlign = TextAlign.Center
        )
        TextButton(
            onClick = { onRefresh() }
        ) {
            Text(
                text = stringResource(R.string.state_empty_refresh),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
        }
    }
}