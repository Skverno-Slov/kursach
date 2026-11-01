package com.rtsr.signal.models

import androidx.annotation.StringRes
import com.rtsr.signal.R

enum class PeriodType(@StringRes val resId: Int) {
    ALL_TIME(R.string.period_all_time),
    LAST_MONTH(R.string.period_last_month),
    CURRENT_MONTH(R.string.period_current_month),
    LAST_WEEK(R.string.period_last_week),
    CURRENT_WEEK(R.string.period_current_week),
    YESTERDAY(R.string.period_yesterday),
    TODAY(R.string.period_today),
    HOUR_1(R.string.period_1_hour)
}