Web | OpenCode     [Skip to content](#_top)

  [![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg) OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/docs/)

[](https://github.com/anomalyco/opencode)[](https://opencode.ai/discord)

Search CtrlK

Cancel

-   [Intro](/docs/)
-   [Config](/docs/config/)
-   [Providers](/docs/providers/)
-   [Network](/docs/network/)
-   [Enterprise](/docs/enterprise/)
-   [Troubleshooting](/docs/troubleshooting/)
-   [Windows](/docs/windows-wsl)
-   Usage
    
    -   [Go](/docs/go/)
    -   [TUI](/docs/tui/)
    -   [CLI](/docs/cli/)
    -   [Web](/docs/web/)
    -   [IDE](/docs/ide/)
    -   [Zen](/docs/zen/)
    -   [Share](/docs/share/)
    -   [GitHub](/docs/github/)
    -   [GitLab](/docs/gitlab/)
    
-   Configure
    
    -   [Tools](/docs/tools/)
    -   [Rules](/docs/rules/)
    -   [Agents](/docs/agents/)
    -   [Models](/docs/models/)
    -   [Themes](/docs/themes/)
    -   [Keybinds](/docs/keybinds/)
    -   [Commands](/docs/commands/)
    -   [Formatters](/docs/formatters/)
    -   [Permissions](/docs/permissions/)
    -   [LSP Servers](/docs/lsp/)
    -   [MCP servers](/docs/mcp-servers/)
    -   [ACP Support](/docs/acp/)
    -   [Agent Skills](/docs/skills/)
    -   [Custom Tools](/docs/custom-tools/)
    
-   Develop
    
    -   [SDK](/docs/sdk/)
    -   [Server](/docs/server/)
    -   [Plugins](/docs/plugins/)
    -   [Ecosystem](/docs/ecosystem/)
    

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

Select theme DarkLightAuto   Select language EnglishالعربيةBosanskiDanskDeutschEspañolFrançaisItaliano日本語한국어Norsk BokmålPolskiPortuguês (Brasil)РусскийไทยTürkçe简体中文繁體中文

On this page

-   [Overview](#_top)
-   [Getting Started](#getting-started)
-   [Configuration](#configuration)
    -   [Port](#port)
    -   [Hostname](#hostname)
    -   [mDNS Discovery](#mdns-discovery)
    -   [CORS](#cors)
    -   [Authentication](#authentication)
-   [Using the Web Interface](#using-the-web-interface)
    -   [Sessions](#sessions)
    -   [Server Status](#server-status)
-   [Attaching a Terminal](#attaching-a-terminal)
-   [Config File](#config-file)

## On this page

-   [Overview](#_top)
-   [Getting Started](#getting-started)
-   [Configuration](#configuration)
    -   [Port](#port)
    -   [Hostname](#hostname)
    -   [mDNS Discovery](#mdns-discovery)
    -   [CORS](#cors)
    -   [Authentication](#authentication)
-   [Using the Web Interface](#using-the-web-interface)
    -   [Sessions](#sessions)
    -   [Server Status](#server-status)
-   [Attaching a Terminal](#attaching-a-terminal)
-   [Config File](#config-file)

# Web

Using OpenCode in your browser.

OpenCode can run as a web application in your browser, providing the same powerful AI coding experience without needing a terminal.

![OpenCode Web - New Session](/docs/_astro/web-homepage-new-session.BB1mEdgo_Z1AT1v3.webp)

## [Getting Started](#getting-started)

Start the web interface by running:

Terminal window

```
opencode web
```

This starts a local server on `127.0.0.1` with a random available port and automatically opens OpenCode in your default browser.

Caution

If `OPENCODE_SERVER_PASSWORD` is not set, the server will be unsecured. This is fine for local use but should be set for network access.

Windows Users

For the best experience, run `opencode web` from [WSL](/docs/windows-wsl) rather than PowerShell. This ensures proper file system access and terminal integration.

---

## [Configuration](#configuration)

You can configure the web server using command line flags or in your [config file](/docs/config).

### [Port](#port)

By default, OpenCode picks an available port. You can specify a port:

Terminal window

```
opencode web --port 4096
```

### [Hostname](#hostname)

By default, the server binds to `127.0.0.1` (localhost only). To make OpenCode accessible on your network:

Terminal window

```
opencode web --hostname 0.0.0.0
```

When using `0.0.0.0`, OpenCode will display both local and network addresses:

```
  Local access:       http://localhost:4096  Network access:     http://192.168.1.100:4096
```

### [mDNS Discovery](#mdns-discovery)

Enable mDNS to make your server discoverable on the local network:

Terminal window

```
opencode web --mdns
```

This automatically sets the hostname to `0.0.0.0` and advertises the server as `opencode.local`.

You can customize the mDNS domain name to run multiple instances on the same network:

Terminal window

```
opencode web --mdns --mdns-domain myproject.local
```

### [CORS](#cors)

To allow additional domains for CORS (useful for custom frontends):

Terminal window

```
opencode web --cors https://example.com
```

### [Authentication](#authentication)

To protect access, set a password using the `OPENCODE_SERVER_PASSWORD` environment variable:

Terminal window

```
OPENCODE_SERVER_PASSWORD=secret opencode web
```

The username defaults to `opencode` but can be changed with `OPENCODE_SERVER_USERNAME`.

---

## [Using the Web Interface](#using-the-web-interface)

Once started, the web interface provides access to your OpenCode sessions.

### [Sessions](#sessions)

View and manage your sessions from the homepage. You can see active sessions and start new ones.

![OpenCode Web - Active Session](/docs/_astro/web-homepage-active-session.BbK4Ph6e_Z1O7nO1.webp)

### [Server Status](#server-status)

Click “See Servers” to view connected servers and their status.

![OpenCode Web - See Servers](/docs/_astro/web-homepage-see-servers.BpCOef2l_ZB0rJd.webp)

---

## [Attaching a Terminal](#attaching-a-terminal)

You can attach a terminal TUI to a running web server:

Terminal window

```
# Start the web serveropencode web --port 4096
# In another terminal, attach the TUIopencode attach http://localhost:4096
```

This allows you to use both the web interface and terminal simultaneously, sharing the same sessions and state.

---

## [Config File](#config-file)

You can also configure server settings in your `opencode.json` config file:

```
{  "server": {    "port": 4096,    "hostname": "0.0.0.0",    "mdns": true,    "cors": ["https://example.com"]  }}
```

Command line flags take precedence over config file settings.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/web.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord) Select language EnglishالعربيةBosanskiDanskDeutschEspañolFrançaisItaliano日本語한국어Norsk BokmålPolskiPortuguês (Brasil)РусскийไทยTürkçe简体中文繁體中文 

© [Anomaly](https://anoma.ly)

Last updated: May 15, 2026