// Companion to ~/bin/chrome-tab-router (native messaging host) and
// workspace-url-open. Chrome's CLI cannot target a window: a URL handed to a
// running instance lands in the most recently activated window, which on
// Wayland is whichever window last received keyboard focus. That breaks after
// a layer-shell launcher (fuzzel-open). This extension receives
// {id, url, title} over native messaging, finds the window whose active tab
// carries `title` (the niri window title, minus the " - Google Chrome"
// suffix), and opens the URL as an active tab there. No focus change needed.
//
// Requires "Allow access to file URLs" on chrome://extensions, otherwise
// tabs.create rejects file:// URLs.

const HOST = 'com.schickm.chrome_tab_router';
const TITLE_SUFFIX = / - Google Chrome$/;

let port = null;
let retryMs = 1000;

// Idempotent: a second connectNative would spawn a second host process, and
// both hosts bind the same socket path. Requests then reach one host while
// replies go out the other port, so every client times out after the tab has
// already opened — and workspace-url-open falls back and opens it again.
function connect() {
  if (port) return;
  let p;
  try {
    p = chrome.runtime.connectNative(HOST);
  } catch (e) {
    console.warn('connectNative failed', e);
    scheduleReconnect();
    return;
  }
  port = p;
  p.onMessage.addListener((msg) => handle(msg, p));
  p.onDisconnect.addListener(() => {
    console.warn('host disconnected', chrome.runtime.lastError?.message);
    if (port === p) port = null;
    scheduleReconnect();
  });
  retryMs = 1000;
}

function scheduleReconnect() {
  setTimeout(connect, retryMs);
  retryMs = Math.min(retryMs * 2, 30000);
}

async function findWindow(title) {
  const want = title.replace(TITLE_SUFFIX, '');
  const wins = await chrome.windows.getAll({ populate: true, windowTypes: ['normal'] });
  for (const w of wins) {
    const active = w.tabs.find((t) => t.active);
    if (active && active.title === want) return w;
  }
  return null;
}

async function handle(msg, from) {
  const reply = { id: msg.id, ok: false };
  try {
    const w = await findWindow(msg.title || '');
    if (!w) {
      reply.error = `no Chrome window with active tab titled: ${msg.title}`;
    } else {
      const tab = await chrome.tabs.create({ windowId: w.id, url: msg.url, active: true });
      reply.ok = true;
      reply.windowId = w.id;
      reply.tabId = tab.id;
    }
  } catch (e) {
    reply.error = String(e?.message || e);
  }
  from.postMessage(reply);
}

// The top-level call runs on every service worker start, which already covers
// browser startup and install/reload. onStartup/onInstalled listeners on top
// of it produced the duplicate host described above.
connect();
