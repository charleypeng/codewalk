package com.verseles.codewalk.overlay

import android.app.Activity
import android.graphics.Color
import android.os.Bundle
import android.view.View

class SessionOverlayTestActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(
            View(this).apply { setBackgroundColor(BACKGROUND_COLOR) },
        )
    }

    companion object {
        val BACKGROUND_COLOR: Int = Color.rgb(230, 100, 220)
    }
}
