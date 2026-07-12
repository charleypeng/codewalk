package com.verseles.codewalk.overlay

import android.content.Intent
import androidx.core.content.ContextCompat
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.verseles.codewalk.MainActivity
import org.junit.After
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class SessionOverlayServiceInstrumentedTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val targetContext = instrumentation.targetContext

    @After
    fun tearDown() {
        targetContext.stopService(Intent(targetContext, SessionOverlayService::class.java))
        waitUntil { !SessionOverlayService.isRunning() }
    }

    @Test
    fun startsFromVisibleActivityAndStopsCleanly() {
        grantOverlayAppOp()

        ActivityScenario.launch(MainActivity::class.java).use { scenario ->
            scenario.onActivity {
                ContextCompat.startForegroundService(
                    it,
                    Intent(it, SessionOverlayService::class.java),
                )
            }
            assertTrue(waitUntil { SessionOverlayService.isRunning() })
            assertTrue(
                targetContext.stopService(
                    Intent(targetContext, SessionOverlayService::class.java),
                ),
            )
            assertTrue(waitUntil { !SessionOverlayService.isRunning() })
        }
    }

    @Test
    fun stopActionIsIdempotentAfterPermissionGrant() {
        grantOverlayAppOp()
        assertFalse(SessionOverlayService.isRunning())
        targetContext.stopService(Intent(targetContext, SessionOverlayService::class.java))
        assertFalse(SessionOverlayService.isRunning())
    }

    private fun grantOverlayAppOp() {
        instrumentation.uiAutomation.executeShellCommand(
            "appops set ${targetContext.packageName} SYSTEM_ALERT_WINDOW allow",
        ).close()
    }

    private fun waitUntil(predicate: () -> Boolean): Boolean {
        repeat(100) {
            if (predicate()) return true
            Thread.sleep(100)
        }
        return predicate()
    }
}
