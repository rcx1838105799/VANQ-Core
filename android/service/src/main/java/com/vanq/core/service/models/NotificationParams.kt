package com.vanq.core.service.models

data class NotificationParams(
    val title: String = "VANQ Core",
    val stopText: String = "STOP",
    val onlyStatisticsProxy: Boolean = false,
    val showStopAction: Boolean = true,
)
