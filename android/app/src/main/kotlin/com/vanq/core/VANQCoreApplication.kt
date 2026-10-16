package com.vanq.core

import android.app.Application
import android.content.Context
import com.vanq.core.common.GlobalState

class VANQCoreApplication : Application() {
    override fun attachBaseContext(base: Context?) {
        super.attachBaseContext(base)
        GlobalState.init(this)
    }
}
