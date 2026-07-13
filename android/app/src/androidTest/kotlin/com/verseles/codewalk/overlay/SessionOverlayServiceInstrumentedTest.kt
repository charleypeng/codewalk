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
import org.junit.Assert.assertEquals
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
        assertEquals(7L, SessionOverlayService.currentSnapshotRevision())
        assertEquals(
            android.app.Service.START_STICKY,
            SessionOverlayService.dispatchNullStartForTest(),
        )

        scenario.close()

        assertTrue(SessionOverlayService.isRunning())
        assertTrue(SessionOverlayService.hasAttachedOverlay())
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

    private fun attentionSnapshot(revision: Int): Map<String, Any?> {
        return mapOf(
            "schemaVersion" to 1,
            "generation" to "instrumentation",
            "revision" to revision,
            "presentation" to "bubble",
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

    private fun waitUntil(predicate: () -> Boolean): Boolean {
        repeat(100) {
            if (predicate()) return true
            Thread.sleep(100)
        }
        return predicate()
    }
}
