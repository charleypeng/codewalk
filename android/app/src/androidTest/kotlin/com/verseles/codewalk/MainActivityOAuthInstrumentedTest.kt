package com.verseles.codewalk

import android.content.Intent
import android.net.Uri
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class MainActivityOAuthInstrumentedTest {
    @Test
    fun acceptsOnlyHttpsAuthorizationUris() {
        assertTrue(
            MainActivity.isTrustedOAuthAuthorizationUri(
                Uri.parse("https://team.cloudflareaccess.com/oauth/authorize"),
            ),
        )
        assertFalse(
            MainActivity.isTrustedOAuthAuthorizationUri(
                Uri.parse("http://team.cloudflareaccess.com/oauth/authorize"),
            ),
        )
        assertFalse(MainActivity.isTrustedOAuthAuthorizationUri(Uri.parse("https:///missing-host")))
    }

    @Test
    fun browserIntentsStayExternalAndBrowsable() {
        val uri = Uri.parse("https://team.cloudflareaccess.com/oauth/authorize")
        val customTab = MainActivity.buildOAuthCustomTabIntent(uri, "browser.package")
        val external = MainActivity.buildOAuthExternalBrowserIntent(uri)

        assertEquals(Intent.ACTION_VIEW, customTab.action)
        assertEquals(uri, customTab.data)
        assertEquals("browser.package", customTab.`package`)
        assertTrue(customTab.categories?.contains(Intent.CATEGORY_BROWSABLE) == true)
        assertNull(customTab.component)

        assertEquals(Intent.ACTION_VIEW, external.action)
        assertEquals(uri, external.data)
        assertTrue(external.categories?.contains(Intent.CATEGORY_BROWSABLE) == true)
        assertNull(external.component)
        assertNull(external.`package`)
    }
}
