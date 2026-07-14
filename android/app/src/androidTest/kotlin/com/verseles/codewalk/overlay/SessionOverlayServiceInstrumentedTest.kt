package com.verseles.codewalk.overlay

import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.Rect
import android.os.ParcelFileDescriptor
import android.os.SystemClock
import android.provider.Settings
import android.view.View
import android.view.WindowManager
import androidx.core.content.ContextCompat
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.verseles.codewalk.MainActivity
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import java.util.concurrent.FutureTask
import kotlin.math.abs
import kotlin.math.roundToInt

@RunWith(AndroidJUnit4::class)
class SessionOverlayServiceInstrumentedTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val targetContext = instrumentation.targetContext

    @Before
    fun setUp() {
        assertTrue("Session overlay service did not stop", stopOverlayService())
        SessionOverlayService.setDisableSecureForTest(targetContext, false)
        targetContext.getSharedPreferences(TEST_PREFERENCES, 0).edit().clear().commit()
        grantOverlayAppOp()
    }

    @After
    fun tearDown() {
        SessionOverlayService.setDisableSecureForTest(targetContext, false)
        val stopped = stopOverlayService()
        SessionOverlayService.setDisableSecureForTest(targetContext, false)
        targetContext.getSharedPreferences(TEST_PREFERENCES, 0).edit().clear().commit()
        resetOverlayAppOp()
        assertTrue("Session overlay service did not stop", stopped)
    }

    @Test
    fun startsFromVisibleActivityAndStopsCleanly() {
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
        assertFalse(SessionOverlayService.isRunning())
        targetContext.stopService(Intent(targetContext, SessionOverlayService::class.java))
        assertFalse(SessionOverlayService.isRunning())
    }

    @Test
    fun attachesRevisionedSnapshotAndSurvivesNullIntentAndActivityDestroy() {
        val scenario = ActivityScenario.launch(MainActivity::class.java)
        scenario.onActivity {
            ContextCompat.startForegroundService(
                it,
                Intent(it, SessionOverlayService::class.java),
            )
        }
        assertTrue(waitUntil { SessionOverlayService.isRunning() })
        assertTrue(updateSnapshot(attentionSnapshot(revision = 7)))
        assertTrue(waitUntil { hasAttachedOverlay() })
        assertTrue(waitUntil { hasRenderedFirstFrame() })
        assertEquals(7L, currentSnapshotRevision())
        assertOverlayGeometry("bubble")
        assertTrue(
            requireNotNull(currentOverlayFlags()) and
                WindowManager.LayoutParams.FLAG_SECURE != 0,
        )
        assertEquals(
            android.app.Service.START_STICKY,
            runOnMainThread { SessionOverlayService.dispatchNullStartForTest() },
        )

        scenario.close()

        assertTrue(SessionOverlayService.isRunning())
        assertTrue(hasAttachedOverlay())
    }

    @Test
    fun transparentBubbleAndPanelCornersRevealTheActivity() {
        SessionOverlayService.setDisableSecureForTest(targetContext, true)
        ActivityScenario.launch(MainActivity::class.java).use { scenario ->
            scenario.onActivity { activity ->
                activity.setContentView(
                    View(activity).apply { setBackgroundColor(TEST_BACKGROUND_COLOR) },
                )
                ContextCompat.startForegroundService(
                    activity,
                    Intent(activity, SessionOverlayService::class.java),
                )
            }
            assertTrue(waitUntil { SessionOverlayService.isRunning() })
            val baseline = captureActivityBaseline()
            try {
                assertTrue(updateSnapshot(attentionSnapshot(revision = 20)))
                assertTrue(waitUntil { hasRenderedFirstFrame() })
                assertOverlayGeometry("bubble")
                assertTransparentTopLeftCorner(baseline, "bubble")

                assertTrue(
                    updateSnapshot(
                        attentionSnapshot(revision = 21, presentation = "panel"),
                    ),
                )
                assertTrue(waitUntil { overlayHasExpectedSize("panel") })
                assertOverlayGeometry("panel")
                assertTransparentTopLeftCorner(baseline, "panel")
            } finally {
                baseline.recycle()
            }
        }
    }

    @Test
    fun permissionRevocationDetachesAndStopsService() {
        ActivityScenario.launch(MainActivity::class.java).use { scenario ->
            scenario.onActivity {
                ContextCompat.startForegroundService(
                    it,
                    Intent(it, SessionOverlayService::class.java),
                )
            }
            assertTrue(waitUntil { SessionOverlayService.isRunning() })
            updateSnapshot(attentionSnapshot(revision = 9))
            assertTrue(waitUntil { hasAttachedOverlay() })

            executeShellCommand(
                "appops set ${targetContext.packageName} SYSTEM_ALERT_WINDOW deny",
            )

            assertTrue(waitUntil { !SessionOverlayService.isRunning() })
            assertFalse(hasAttachedOverlay())
        }
    }

    @Test
    fun fallbackSnapshotIsRejectedAfterMainHeartbeatReturns() {
        ActivityScenario.launch(MainActivity::class.java).use { scenario ->
            scenario.onActivity {
                ContextCompat.startForegroundService(
                    it,
                    Intent(it, SessionOverlayService::class.java),
                )
            }
            assertTrue(waitUntil { SessionOverlayService.isRunning() })
            SessionOverlayService.expireMainHeartbeatForTest()
            assertTrue(
                applyFallbackSnapshot(
                    attentionSnapshot(revision = 10),
                ),
            )

            assertTrue(updateSnapshot(attentionSnapshot(revision = 11)))

            assertFalse(
                applyFallbackSnapshot(
                    attentionSnapshot(revision = 12),
                ),
            )
        }
    }

    private fun attentionSnapshot(
        revision: Int,
        presentation: String = "bubble",
    ): Map<String, Any?> {
        return mapOf(
            "schemaVersion" to 1,
            "generation" to "instrumentation",
            "revision" to revision,
            "presentation" to presentation,
            "activeServerId" to "server-a",
            "fullResynchronization" to true,
            "producer" to "main",
            "items" to listOf(
                mapOf(
                    "schemaVersion" to 1,
                    "revision" to revision,
                    "identity" to mapOf(
                        "serverId" to "server-a",
                        "directory" to "/repo/a",
                        "sessionId" to "session-a",
                    ),
                    "title" to "Session A",
                    "projectLabel" to "Project A",
                    "kind" to "active",
                    "startedAtEpochMs" to 1,
                    "lastObservedAtEpochMs" to 2,
                    "observableBusyElapsedMs" to 1,
                    "displayText" to "",
                    "speechText" to "",
                    "displayTruncated" to false,
                    "speechTruncated" to false,
                    "opened" to false,
                    "dismissed" to false,
                    "transportCapability" to "live",
                    "contentDigest" to "",
                ),
            ),
        )
    }

    private fun grantOverlayAppOp() {
        executeShellCommand(
            "appops set ${targetContext.packageName} SYSTEM_ALERT_WINDOW allow",
        )
        assertTrue(
            "Overlay app-op was not granted",
            waitUntil { Settings.canDrawOverlays(targetContext) },
        )
    }

    private fun resetOverlayAppOp() {
        executeShellCommand(
            "appops set ${targetContext.packageName} SYSTEM_ALERT_WINDOW default",
        )
    }

    private fun executeShellCommand(command: String) {
        ParcelFileDescriptor.AutoCloseInputStream(
            instrumentation.uiAutomation.executeShellCommand(command),
        ).use { it.readBytes() }
    }

    private fun stopOverlayService(): Boolean {
        targetContext.stopService(Intent(targetContext, SessionOverlayService::class.java))
        val stopped = waitUntil { !SessionOverlayService.isRunning() }
        if (stopped) {
            runOnMainThread { Unit }
        }
        return stopped
    }

    private fun updateSnapshot(snapshot: Map<String, Any?>): Boolean =
        runOnMainThread { SessionOverlayService.updateSnapshot(snapshot) }

    private fun applyFallbackSnapshot(snapshot: Map<String, Any?>): Boolean =
        runOnMainThread { SessionOverlayService.applyFallbackSnapshotForTest(snapshot) }

    private fun hasAttachedOverlay(): Boolean =
        runOnMainThread { SessionOverlayService.hasAttachedOverlay() }

    private fun hasRenderedFirstFrame(): Boolean =
        runOnMainThread { SessionOverlayService.hasRenderedFirstFrameForTest() }

    private fun currentSnapshotRevision(): Long =
        runOnMainThread { SessionOverlayService.currentSnapshotRevision() }

    private fun currentOverlayFlags(): Int? =
        runOnMainThread { SessionOverlayService.currentOverlayFlagsForTest() }

    private fun currentMovementBounds(): Rect? =
        runOnMainThread { SessionOverlayService.currentMovementBoundsForTest() }

    private fun currentOverlaySize(): Pair<Int, Int>? =
        runOnMainThread { SessionOverlayService.currentOverlaySizeForTest() }

    private fun <T> runOnMainThread(action: () -> T): T {
        val task = FutureTask<T> { action() }
        instrumentation.runOnMainSync(task)
        return task.get()
    }

    private fun assertOverlayGeometry(presentation: String) {
        val bounds = requireNotNull(currentMovementBounds())
        val rect = overlayRectOnMainThread()
        assertTrue("Overlay $rect must remain inside $bounds", bounds.contains(rect))
        assertTrue(overlayHasExpectedSize(presentation))
    }

    private fun overlayHasExpectedSize(presentation: String): Boolean {
        val bounds = currentMovementBounds() ?: return false
        val actual = currentOverlaySize() ?: return false
        val density = targetContext.resources.displayMetrics.density
        val expectedWidthDp = if (presentation == "panel") 360 else 96
        val expectedHeightDp = if (presentation == "panel") 240 else 96
        val expectedWidth = (expectedWidthDp * density).roundToInt().coerceAtMost(bounds.width())
        val expectedHeight = (expectedHeightDp * density).roundToInt().coerceAtMost(bounds.height())
        return actual == (expectedWidth to expectedHeight)
    }

    private fun assertTransparentTopLeftCorner(
        baseline: Bitmap,
        presentation: String,
    ) {
        val rect = overlayRectOnMainThread()
        val screenshot = captureWhenContentIsVisible(baseline, rect, presentation)
        try {
            assertTrue(rect.left >= 0 && rect.top >= 0)
            assertTrue(rect.right <= screenshot.width && rect.bottom <= screenshot.height)
            assertEquals(baseline.width, screenshot.width)
            assertEquals(baseline.height, screenshot.height)
            val cornerX = rect.left + 1
            val cornerY = rect.top + 1
            val baselineCorner = baseline.getPixel(cornerX, cornerY)
            val overlayCorner = screenshot.getPixel(cornerX, cornerY)
            assertTrue(
                "Test activity background was not visible before attaching the overlay",
                maxChannelDistance(baselineCorner, TEST_BACKGROUND_COLOR) <= 12,
            )
            assertTrue(
                "Expected the baseline at the rounded overlay corner, but captured #${
                    Integer.toHexString(overlayCorner)
                } over #${Integer.toHexString(baselineCorner)}",
                maxChannelDistance(overlayCorner, baselineCorner) <= 12,
            )
            val contentPoint = contentProbe(rect, presentation)
            assertTrue(
                "Expected rendered overlay content at the probe point",
                colorDistance(
                    screenshot.getPixel(contentPoint.first, contentPoint.second),
                    baseline.getPixel(contentPoint.first, contentPoint.second),
                ) > 40,
            )
        } finally {
            screenshot.recycle()
        }
    }

    private fun captureActivityBaseline(): Bitmap {
        val deadline = SystemClock.elapsedRealtime() + SCREENSHOT_TIMEOUT_MS
        while (true) {
            val screenshot = instrumentation.uiAutomation.takeScreenshot()
            if (screenshot != null) {
                val centerPixel = screenshot.getPixel(screenshot.width / 2, screenshot.height / 2)
                if (maxChannelDistance(centerPixel, TEST_BACKGROUND_COLOR) <= 12) {
                    return screenshot
                }
                screenshot.recycle()
            }
            check(SystemClock.elapsedRealtime() < deadline) {
                "Test activity background did not become visible"
            }
            Thread.sleep(100)
        }
    }

    private fun captureWhenContentIsVisible(
        baseline: Bitmap,
        rect: Rect,
        presentation: String,
    ): Bitmap {
        val point = contentProbe(rect, presentation)
        val deadline = SystemClock.elapsedRealtime() + 3_000
        while (true) {
            val screenshot = instrumentation.uiAutomation.takeScreenshot()
            if (screenshot != null) {
                val contentVisible = colorDistance(
                    screenshot.getPixel(point.first, point.second),
                    baseline.getPixel(point.first, point.second),
                ) > 40
                if (contentVisible || SystemClock.elapsedRealtime() >= deadline) {
                    return screenshot
                }
                screenshot.recycle()
            }
            check(SystemClock.elapsedRealtime() < deadline) {
                "Overlay content did not become visible"
            }
            Thread.sleep(100)
        }
    }

    private fun contentProbe(rect: Rect, presentation: String): Pair<Int, Int> {
        if (presentation != "panel") return rect.centerX() to rect.centerY()
        val inset = (24 * targetContext.resources.displayMetrics.density).roundToInt()
        return (rect.left + inset).coerceAtMost(rect.right - 1) to
            (rect.top + inset).coerceAtMost(rect.bottom - 1)
    }

    private fun overlayRectOnMainThread(): Rect =
        requireNotNull(runOnMainThread { SessionOverlayService.currentOverlayRectForTest() })

    private fun colorDistance(left: Int, right: Int): Int =
        abs(Color.red(left) - Color.red(right)) +
            abs(Color.green(left) - Color.green(right)) +
            abs(Color.blue(left) - Color.blue(right))

    private fun maxChannelDistance(left: Int, right: Int): Int =
        maxOf(
            abs(Color.red(left) - Color.red(right)),
            abs(Color.green(left) - Color.green(right)),
            abs(Color.blue(left) - Color.blue(right)),
        )

    private fun waitUntil(predicate: () -> Boolean): Boolean {
        repeat(100) {
            if (predicate()) return true
            Thread.sleep(100)
        }
        return predicate()
    }

    private companion object {
        const val SCREENSHOT_TIMEOUT_MS = 10_000L
        const val TEST_PREFERENCES = "session_attention_native"
        val TEST_BACKGROUND_COLOR: Int = Color.rgb(230, 100, 220)
    }
}
