package com.verseles.codewalk.overlay

import android.content.Intent
import android.graphics.Color
import android.graphics.Rect
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
import org.junit.Test
import org.junit.runner.RunWith
import kotlin.math.abs
import kotlin.math.roundToInt

@RunWith(AndroidJUnit4::class)
class SessionOverlayServiceInstrumentedTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val targetContext = instrumentation.targetContext

    @After
    fun tearDown() {
        targetContext.stopService(Intent(targetContext, SessionOverlayService::class.java))
        waitUntil { !SessionOverlayService.isRunning() }
        SessionOverlayService.setDisableSecureForTest(false)
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

    @Test
    fun attachesRevisionedSnapshotAndSurvivesNullIntentAndActivityDestroy() {
        grantOverlayAppOp()
        val scenario = ActivityScenario.launch(MainActivity::class.java)
        scenario.onActivity {
            ContextCompat.startForegroundService(
                it,
                Intent(it, SessionOverlayService::class.java),
            )
        }
        assertTrue(waitUntil { SessionOverlayService.isRunning() })
        assertTrue(SessionOverlayService.updateSnapshot(attentionSnapshot(revision = 7)))
        assertTrue(waitUntil { SessionOverlayService.hasAttachedOverlay() })
        assertTrue(waitUntil { SessionOverlayService.hasRenderedFirstFrameForTest() })
        assertEquals(7L, SessionOverlayService.currentSnapshotRevision())
        assertOverlayGeometry("bubble")
        assertTrue(
            requireNotNull(SessionOverlayService.currentOverlayFlagsForTest()) and
                WindowManager.LayoutParams.FLAG_SECURE != 0,
        )
        assertEquals(
            android.app.Service.START_STICKY,
            SessionOverlayService.dispatchNullStartForTest(),
        )

        scenario.close()

        assertTrue(SessionOverlayService.isRunning())
        assertTrue(SessionOverlayService.hasAttachedOverlay())
    }

    @Test
    fun transparentBubbleAndPanelCornersRevealTheActivity() {
        grantOverlayAppOp()
        SessionOverlayService.setDisableSecureForTest(true)
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

            assertTrue(SessionOverlayService.updateSnapshot(attentionSnapshot(revision = 20)))
            assertTrue(waitUntil { SessionOverlayService.hasRenderedFirstFrameForTest() })
            assertOverlayGeometry("bubble")
            assertTransparentTopLeftCorner()

            assertTrue(
                SessionOverlayService.updateSnapshot(
                    attentionSnapshot(revision = 21, presentation = "panel"),
                ),
            )
            assertTrue(waitUntil { overlayHasExpectedSize("panel") })
            assertOverlayGeometry("panel")
            assertTransparentTopLeftCorner()
        }
    }

    @Test
    fun permissionRevocationDetachesAndStopsService() {
        grantOverlayAppOp()
        ActivityScenario.launch(MainActivity::class.java).use { scenario ->
            scenario.onActivity {
                ContextCompat.startForegroundService(
                    it,
                    Intent(it, SessionOverlayService::class.java),
                )
            }
            assertTrue(waitUntil { SessionOverlayService.isRunning() })
            SessionOverlayService.updateSnapshot(attentionSnapshot(revision = 9))
            assertTrue(waitUntil { SessionOverlayService.hasAttachedOverlay() })

            instrumentation.uiAutomation.executeShellCommand(
                "appops set ${targetContext.packageName} SYSTEM_ALERT_WINDOW deny",
            ).close()

            assertTrue(waitUntil { !SessionOverlayService.isRunning() })
            assertFalse(SessionOverlayService.hasAttachedOverlay())
        }
        grantOverlayAppOp()
    }

    @Test
    fun fallbackSnapshotIsRejectedAfterMainHeartbeatReturns() {
        grantOverlayAppOp()
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
                SessionOverlayService.applyFallbackSnapshotForTest(
                    attentionSnapshot(revision = 10),
                ),
            )

            assertTrue(SessionOverlayService.updateSnapshot(attentionSnapshot(revision = 11)))

            assertFalse(
                SessionOverlayService.applyFallbackSnapshotForTest(
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
        instrumentation.uiAutomation.executeShellCommand(
            "appops set ${targetContext.packageName} SYSTEM_ALERT_WINDOW allow",
        ).close()
    }

    private fun assertOverlayGeometry(presentation: String) {
        val bounds = requireNotNull(SessionOverlayService.currentMovementBoundsForTest())
        val rect = overlayRectOnMainThread()
        assertTrue("Overlay $rect must remain inside $bounds", bounds.contains(rect))
        assertTrue(overlayHasExpectedSize(presentation))
    }

    private fun overlayHasExpectedSize(presentation: String): Boolean {
        val bounds = SessionOverlayService.currentMovementBoundsForTest() ?: return false
        val actual = SessionOverlayService.currentOverlaySizeForTest() ?: return false
        val density = targetContext.resources.displayMetrics.density
        val expectedWidthDp = if (presentation == "panel") 360 else 96
        val expectedHeightDp = if (presentation == "panel") 240 else 96
        val expectedWidth = (expectedWidthDp * density).roundToInt().coerceAtMost(bounds.width())
        val expectedHeight = (expectedHeightDp * density).roundToInt().coerceAtMost(bounds.height())
        return actual == (expectedWidth to expectedHeight)
    }

    private fun assertTransparentTopLeftCorner() {
        instrumentation.waitForIdleSync()
        Thread.sleep(250)
        val rect = overlayRectOnMainThread()
        val screenshot = requireNotNull(instrumentation.uiAutomation.takeScreenshot())
        try {
            assertTrue(rect.left >= 0 && rect.top >= 0)
            assertTrue(rect.right <= screenshot.width && rect.bottom <= screenshot.height)
            val pixel = screenshot.getPixel(rect.left + 1, rect.top + 1)
            assertTrue(
                "Expected the activity at the rounded overlay corner, but captured #${
                    Integer.toHexString(pixel)
                }",
                colorDistance(pixel, TEST_BACKGROUND_COLOR) < 180,
            )
        } finally {
            screenshot.recycle()
        }
    }

    private fun overlayRectOnMainThread(): Rect {
        var rect: Rect? = null
        instrumentation.runOnMainSync {
            rect = SessionOverlayService.currentOverlayRectForTest()
        }
        return requireNotNull(rect)
    }

    private fun colorDistance(left: Int, right: Int): Int =
        abs(Color.red(left) - Color.red(right)) +
            abs(Color.green(left) - Color.green(right)) +
            abs(Color.blue(left) - Color.blue(right))

    private fun waitUntil(predicate: () -> Boolean): Boolean {
        repeat(100) {
            if (predicate()) return true
            Thread.sleep(100)
        }
        return predicate()
    }

    private companion object {
        val TEST_BACKGROUND_COLOR: Int = Color.rgb(230, 100, 220)
    }
}
