// konna-keys: vim-style keyboard control for spotify.
// press ? inside spotify for the cheat sheet.
(function konnaKeys() {
  const S = window.Spicetify;
  if (!S?.Player?.togglePlay || !S?.Platform?.History) {
    setTimeout(konnaKeys, 300);
    return;
  }
  const P = S.Platform;
  const $ = (sel, root = document) => root.querySelector(sel);

  // ---------- helpers ----------
  const typing = (el) => el && (el.tagName === "INPUT" || el.tagName === "TEXTAREA" || el.isContentEditable);
  const go = (path) => P.History.push(path);
  const clickTestId = (id) => $(`[data-testid="${id}"]`)?.click();

  let scrollEl = null;
  function scroller() {
    if (scrollEl?.isConnected && scrollEl.closest(".Root__main-view")) return scrollEl;
    const mv = $(".Root__main-view");
    if (!mv) return null;
    scrollEl = [...mv.querySelectorAll("div")].find((el) => {
      const oy = getComputedStyle(el).overflowY;
      return (oy === "auto" || oy === "scroll") && el.scrollHeight > el.clientHeight + 20;
    });
    return scrollEl;
  }
  const scrollBy = (dy) => scroller()?.scrollBy({ top: dy, behavior: "smooth" });
  const scrollTo = (top) => scroller()?.scrollTo({ top, behavior: "smooth" });

  function seek(ms) {
    const pos = S.Player.getProgress() + ms;
    S.Player.seek(Math.max(0, Math.min(pos, S.Player.getDuration() - 500)));
  }
  function volume(delta) {
    S.Player.setVolume(Math.max(0, Math.min(1, S.Player.getVolume() + delta)));
    toast(`vol ${Math.round(S.Player.getVolume() * 100)}%`);
  }

  // opens the queue panel on its "Recently played" tab
  function history() {
    const tab = () => [...document.querySelectorAll(".Root__right-sidebar button, .Root__right-sidebar [role=tab]")].find((b) => /recently played/i.test(b.textContent));
    if (!tab()) clickTestId("control-button-queue");
    setTimeout(() => tab()?.click(), 250);
  }

  // ---------- tiny ui pieces ----------
  function el(tag, cls, text) {
    const e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text != null) e.textContent = text;
    return e;
  }

  let toastTimer;
  function toast(text) {
    let t = $(".konna-toast");
    if (!t) document.body.appendChild((t = el("div", "konna-toast")));
    t.textContent = text;
    t.classList.add("show");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => t.classList.remove("show"), 900);
  }

  let overlay = null;
  function closeOverlay() {
    overlay?.remove();
    overlay = null;
  }

  // ---------- keymap ----------
  // [keys, description, action]; groups drive the ? sheet and the g-prefix popup
  const groups = [
    ["playback", [
      ["space", "play / pause", () => S.Player.togglePlay()],
      ["n", "next track (next match after /)", () => (search ? stepMatch(1) : S.Player.next())],
      ["p", "previous track", () => S.Player.back()],
      [",", "seek -10s", () => seek(-10000)],
      [".", "seek +10s", () => seek(10000)],
      ["+", "volume up", () => volume(0.05)],
      ["-", "volume down", () => volume(-0.05)],
      ["m", "mute", () => clickTestId("volume-bar-toggle-mute-button")],
      ["s", "shuffle", () => { S.Player.toggleShuffle(); toast(`shuffle ${S.Player.getShuffle() ? "on" : "off"}`); }],
      ["r", "repeat", () => { S.Player.toggleRepeat(); toast(["repeat off", "repeat all", "repeat one"][S.Player.getRepeat()] ?? "repeat"); }],
      ["y", "like / unlike track", () => { S.Player.toggleHeart(); setTimeout(() => toast(S.Player.getHeart() ? "liked" : "unliked"), 150); }],
    ]],
    ["move", [
      ["j / k", "cursor down / up", null],
      ["d / u", "cursor 10 down / up", null],
      ["gg / G", "first / last item", null],
      ["l / enter", "open item / play track", null],
      ["h", "back to library", null],
      ["H / L", "page back / forward", null],
      ["f", "hint mode: type the letters to click", () => hints()],
      ["/", "find in this list", () => find()],
      ["n / N", "next / previous match", null],
      ["o", "open playlist (fuzzy)", () => picker()],
    ]],
    ["go to  (g …)", [
      ["g /", "spotify search", () => spotifySearch()],
      ["g l", "liked songs", () => go("/collection/tracks")],
      ["g s", "stats", () => go("/stats")],
      ["g m", "marketplace", () => go("/marketplace")],
      ["g r", "recently played", () => history()],
      ["g q", "queue", () => clickTestId("control-button-queue")],
      ["g n", "now playing panel", () => $('[data-testid="cover-art-button"]')?.click()],
      ["g t", "lyrics", () => clickTestId("lyrics-button")],
    ]],
    ["", [["?", "this sheet", () => help()], ["esc", "close / leave input / clear find", null]]],
  ];
  const single = {};
  const gmap = {};
  for (const [, binds] of groups)
    for (const [k, , fn] of binds) {
      if (!fn) continue;
      if (k.startsWith("g ")) gmap[k.slice(2)] = fn;
      else single[k === "space" ? " " : k] = fn;
    }
  Object.assign(single, {
    j: () => move(1, () => scrollBy(140)),
    k: () => move(-1, () => scrollBy(-140)),
    d: () => move(10, () => scrollBy((scroller()?.clientHeight ?? 800) / 2)),
    u: () => move(-10, () => scrollBy(-(scroller()?.clientHeight ?? 800) / 2)),
    G: () => jump(true, () => scrollTo(1e7)),
    l: () => activate(),
    Enter: () => activate(),
    h: () => toLibrary(),
    N: () => (search ? stepMatch(-1) : false),
    H: () => P.History.goBack(),
    L: () => P.History.goForward(),
    "=": () => volume(0.05),
  });

  // ---------- cursor (like ranger): library on the left, the opened list on the right ----------
  // rows are virtualized and get recycled while scrolling, so the cursor is { grid, aria-rowindex }, not an element.
  // a page can hold several lists (a playlist and "recommended" below it), each numbering its rows from the top,
  // so the cursor remembers which list it's in and j/k step from one list into the next.
  const panes = { lib: ".Root__nav-bar", main: ".Root__main-view" };
  const cur = { pane: "lib", lib: null, main: null };

  const rindex = (r) => +r.getAttribute("aria-rowindex");
  const gridOf = (r) => r.closest('[role="grid"], [role="treegrid"]') ?? r.parentElement;
  const rowSel = '[role="row"][aria-rowindex]';
  const rowsIn = (grid) =>
    [...grid.querySelectorAll(rowSel)].filter((r) => !r.querySelector('[role="columnheader"]')).sort((a, b) => rindex(a) - rindex(b));
  // lists in the pane, top to bottom
  function grids(pane) {
    const root = $(panes[pane]);
    return root ? [...new Set([...root.querySelectorAll(rowSel)].map(gridOf))] : [];
  }
  const rowAt = (pane, c) => (c?.grid.isConnected ? rowsIn(c.grid).find((r) => rindex(r) === c.i) : null);
  function bounds(grid, rs = rowsIn(grid)) {
    const base = grid.querySelector('[role="columnheader"]') ? 2 : 1;
    const lo = rs.length ? Math.min(base, rindex(rs[0])) : base;
    const hi = +grid.getAttribute("aria-rowcount") || (rs.length ? rindex(rs.at(-1)) : lo);
    return [lo, hi];
  }
  function scrollerOf(el) {
    for (let e = el.parentElement; e; e = e.parentElement) {
      const oy = getComputedStyle(e).overflowY;
      if ((oy === "auto" || oy === "scroll") && e.scrollHeight > e.clientHeight) return e;
    }
  }

  function select(pane, grid, i, tries = 0) {
    if (!grid.isConnected) return;
    const rs = rowsIn(grid);
    const [lo, hi] = bounds(grid, rs);
    i = Math.max(lo, Math.min(hi, i));
    cur[pane] = { grid, i };
    const r = rs.find((x) => rindex(x) === i);
    if (r) {
      r.scrollIntoView({ block: "nearest" });
      paint();
      return;
    }
    if (tries > 20) return;
    // row not rendered yet: jump roughly there first, then step until the list renders it
    if (!rs.length) grid.scrollIntoView({ block: i > lo ? "end" : "start" });
    else {
      const sc = scrollerOf(grid);
      if (sc) {
        if (!tries) sc.scrollTop = ((i - lo) / Math.max(1, hi - lo)) * sc.scrollHeight;
        else sc.scrollTop += (i > rindex(rs.at(-1)) ? 0.8 : -0.8) * sc.clientHeight;
      }
    }
    setTimeout(() => select(pane, grid, i, tries + 1), 50);
  }
  // pages without a list (artist, search, …) fall back to plain scrolling
  function move(delta, fallback) {
    const gs = grids(cur.pane);
    if (!gs.length) return cur.pane === "main" ? fallback() : false;
    const c = cur[cur.pane];
    if (!c?.grid.isConnected) return select(cur.pane, gs[0], 0);
    const [lo, hi] = bounds(c.grid);
    const k = gs.indexOf(c.grid);
    const i = c.i + delta;
    // ran off the end of this list: continue into the next one (playlist -> recommended), or back up
    if (i > hi && gs[k + 1]) return select(cur.pane, gs[k + 1], 0);
    if (i < lo && k > 0) return select(cur.pane, gs[k - 1], 1e9);
    select(cur.pane, c.grid, i);
  }
  // gg: top of the first list on the page, G: bottom of the list you're in
  function jump(toEnd, fallback) {
    const gs = grids(cur.pane);
    if (!gs.length) return cur.pane === "main" ? fallback() : false;
    const c = cur[cur.pane];
    if (!toEnd) return select(cur.pane, gs[0], 0);
    select(cur.pane, c?.grid.isConnected ? c.grid : gs[0], 1e9);
  }

  function open(r) {
    try {
      const uri = r.querySelector('[aria-labelledby*="spotify:"]')?.getAttribute("aria-labelledby").match(/spotify:\S+/)?.[0];
      const path = uri && S.URI.fromString(uri).toURLPath(true);
      if (path) return go(path);
    } catch {}
    (r.querySelector('[role="button"]') ?? r).click();
  }
  function activate() {
    const r = rowAt(cur.pane, cur[cur.pane]);
    if (!r) return false;
    if (cur.pane === "lib") {
      cur.pane = "main";
      cur.main = null;
      waitForList();
      open(r);
    } else {
      playRow(r);
    }
    paint();
  }
  // the row's own hover play button keeps the playlist/album as context; if it's missing, play through the api
  function playRow(r) {
    const btn = r.querySelector('.main-trackList-rowPlayPauseButton, .main-trackList-rowImagePlayButton, button[aria-label^="Play"]');
    // on the song that's already playing the button says "Pause": leave it playing (space is pause)
    if (/^pause/i.test(btn?.getAttribute("aria-label") ?? "")) return;
    // blur afterwards: a focused play button would also fire on space, so play/pause would toggle twice
    if (btn) return btn.click(), btn.blur();
    const id = r.querySelector('a[href*="/track/"]')?.getAttribute("href").match(/\/track\/(\w+)/)?.[1];
    if (!id) return toast("can't find a track here");
    const track = `spotify:track:${id}`;
    const ctx = P.History.location.pathname.match(/^\/(playlist|album)\/(\w+)/);
    if (ctx) S.Player.playUri(`spotify:${ctx[1]}:${ctx[2]}`, {}, { skipTo: { uri: track } });
    else S.Player.playUri(track);
  }
  // the collapsed library is covers only, which is blank without artwork: always bring the names back
  function uncollapseLibrary() {
    const btn = $('.Root__nav-bar [aria-label="Open Your Library"]');
    btn?.click();
    return !!btn;
  }
  function toLibrary() {
    uncollapseLibrary();
    cur.pane = "lib";
    if (!cur.lib?.grid.isConnected) return move(1);
    select("lib", cur.lib.grid, cur.lib.i);
  }

  // after navigating, the old page stays up until the new one loads: wait for a different list
  let waitTimer;
  function waitForList() {
    clearInterval(waitTimer);
    const staleGrid = grids("main")[0];
    const started = Date.now();
    waitTimer = setInterval(() => {
      const first = grids("main")[0];
      const fresh = first && (first !== staleGrid || Date.now() - started > 1500);
      if (fresh && cur.pane === "main" && cur.main == null) select("main", first, 0);
      if (fresh || Date.now() - started > 5000) clearInterval(waitTimer);
    }, 100);
  }

  // active pane's row gets the bright outline, the other pane keeps a dim one so you see where you were
  function paint() {
    for (const p of ["lib", "main"]) {
      const want = rowAt(p, cur[p]);
      const cls = p === cur.pane ? "konna-cursor" : "konna-cursor-idle";
      $(panes[p])?.querySelectorAll(".konna-cursor, .konna-cursor-idle").forEach((r) => r !== want && r.classList.remove("konna-cursor", "konna-cursor-idle"));
      if (want && !want.classList.contains(cls)) {
        want.classList.remove("konna-cursor", "konna-cursor-idle");
        want.classList.add(cls);
      }
    }
    // rows matching the / search get a marker, like vim's hlsearch
    const hits = new Set();
    if (search?.q) {
      for (const g of search.grids) {
        if (!g.isConnected) continue;
        const is = new Set(search.matches.filter((m) => m.grid === g).map((m) => m.i));
        for (const r of rowsIn(g)) if (is.has(rindex(r))) hits.add(r);
      }
    }
    document.querySelectorAll(".konna-match").forEach((r) => hits.has(r) || r.classList.remove("konna-match"));
    hits.forEach((r) => r.classList.contains("konna-match") || r.classList.add("konna-match"));
  }
  let paintQueued = false;
  const schedulePaint = () => {
    if (paintQueued) return;
    paintQueued = true;
    requestAnimationFrame(() => { paintQueued = false; paint(); });
  };

  P.History.listen(() => {
    endFind();
    cur.main = null;
    if (cur.pane === "main") waitForList();
    paint();
  });

  // ---------- ? cheat sheet ----------
  function help() {
    closeOverlay();
    overlay = el("div", "konna-overlay");
    const box = el("div", "konna-sheet");
    box.appendChild(el("div", "konna-title", "~/keys"));
    const grid = el("div", "konna-sheet-grid");
    for (const [name, binds] of groups) {
      const col = el("div", "konna-sheet-col");
      if (name) col.appendChild(el("div", "konna-sheet-head", name));
      for (const [k, desc] of binds) {
        const row = el("div", "konna-sheet-row");
        row.append(el("span", "konna-key", k), el("span", "konna-desc", desc));
        col.appendChild(row);
      }
      grid.appendChild(col);
    }
    box.appendChild(grid);
    overlay.appendChild(box);
    overlay.addEventListener("click", closeOverlay);
    document.body.appendChild(overlay);
  }

  // g-prefix popup, like which-key
  function gPopup() {
    closeOverlay();
    overlay = el("div", "konna-whichkey");
    overlay.appendChild(el("div", "konna-sheet-head", "g …"));
    for (const [k, desc] of groups[2][1]) {
      const row = el("div", "konna-sheet-row");
      row.append(el("span", "konna-key", k.slice(2)), el("span", "konna-desc", desc));
      overlay.appendChild(row);
    }
    overlay.appendChild(Object.assign(el("div", "konna-sheet-row"), {}));
    const top = el("div", "konna-sheet-row");
    top.append(el("span", "konna-key", "g"), el("span", "konna-desc", "first item"));
    overlay.appendChild(top);
    document.body.appendChild(overlay);
  }

  // ---------- spotify's own search (g /) ----------
  function spotifySearch() {
    const input = $(".Root__globalNav input");
    if (!input) return go("/search");
    input.focus();
    input.select();
  }
  const setPlaceholder = () => {
    const input = $(".Root__globalNav input");
    if (input && input.placeholder !== "g/ search") input.placeholder = "g/ search";
  };

  // ---------- / find in the list you're in (like vim: jumps while typing, n / N for next / previous) ----------
  // { pane, grids, q, matches: [{ grid, i }], bar, input, count } while a find is active, else null
  let search = null;
  const texts = new WeakMap(); // grid -> Map(rowindex -> lowercased row text)
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  function rowText(r) {
    const w = document.createTreeWalker(r, NodeFilter.SHOW_TEXT);
    const parts = [];
    while (w.nextNode()) parts.push(w.currentNode.nodeValue);
    return parts.join(" ").toLowerCase();
  }
  function record(grid) {
    let m = texts.get(grid);
    if (!m) texts.set(grid, (m = new Map()));
    for (const r of rowsIn(grid)) m.set(rindex(r), rowText(r));
    return m;
  }
  // only on-screen rows exist, so scroll through the list once to read all of them
  async function scanAll(grid) {
    const [lo, hi] = bounds(grid);
    if (record(grid).size >= hi - lo + 1) return;
    const sc = scrollerOf(grid);
    if (!sc) return;
    const top = grid.getBoundingClientRect().top - sc.getBoundingClientRect().top + sc.scrollTop;
    for (let y = Math.max(0, top - sc.clientHeight / 2); y < top + grid.offsetHeight; y += sc.clientHeight * 0.8) {
      sc.scrollTop = y;
      await sleep(40);
      record(grid);
    }
  }

  // list order: which list on the page first, then row
  const order = (a, b) => search.grids.indexOf(a.grid) - search.grids.indexOf(b.grid) || a.i - b.i;
  function nextMatch(from, dir, inclusive = false) {
    const ms = search.matches;
    if (!ms.length) return null;
    if (!from) return dir > 0 ? ms[0] : ms.at(-1);
    if (dir > 0) return ms.find((m) => order(m, from) > (inclusive ? -1 : 0)) ?? ms[0];
    return ms.findLast((m) => order(m, from) < 0) ?? ms.at(-1);
  }
  function showMatch(m) {
    if (m) select(search.pane, m.grid, m.i);
    const text = !search.q ? "" : m ? `${search.matches.indexOf(m) + 1}/${search.matches.length}` : "no match";
    if (search.count) search.count.textContent = text;
    paint();
    return text;
  }

  async function find() {
    const pane = cur.pane;
    const gs = grids(pane);
    if (!gs.length) return spotifySearch(); // nothing to find in here (artist page, …)
    endFind();
    const start = cur[pane];
    const bar = el("div", "konna-cmdline");
    const input = el("input", "konna-cmdline-input");
    const count = el("span", "konna-cmdline-count");
    bar.append(el("span", "konna-key", "/"), input, count);
    document.body.appendChild(bar);
    search = { pane, grids: gs, q: "", matches: [], bar, input, count };
    input.placeholder = "reading list…";
    input.focus();

    const sc = scrollerOf(gs[0]);
    const keep = sc?.scrollTop;
    for (const g of gs) await scanAll(g);
    if (sc) sc.scrollTop = keep;
    if (search?.bar !== bar) return; // closed while reading
    input.placeholder = pane === "lib" ? "find in library" : "find in list";

    const update = () => {
      search.q = input.value.toLowerCase().trim();
      search.matches = [];
      if (search.q)
        for (const g of gs)
          for (const [i, t] of [...(texts.get(g) ?? [])].sort((a, b) => a[0] - b[0]))
            if (t.includes(search.q)) search.matches.push({ grid: g, i });
      const m = nextMatch(start, 1, true);
      if (!m && start) select(pane, start.grid, start.i); // nothing matches (yet): stay where you started
      showMatch(m);
    };
    input.addEventListener("input", update);
    update(); // anything typed while the list was being read
  }
  // enter: keep the matches for n / N and go back to normal keys
  function confirmFind() {
    search.bar.remove();
    search.bar = search.input = search.count = null;
    if (!search.matches.length) {
      if (search.q) toast("no match");
      search = null;
    }
    paint();
  }
  // esc: close it completely, n is next track again
  function endFind() {
    if (!search) return;
    search.bar?.remove();
    search = null;
    paint();
  }
  function stepMatch(dir) {
    cur.pane = search.pane;
    toast(showMatch(nextMatch(cur[search.pane], dir)));
  }

  // ---------- fuzzy playlist picker (like snacks/telescope) ----------
  async function picker() {
    closeOverlay();
    const items = [{ name: "liked songs", path: "/collection/tracks", uri: "spotify:collection:tracks" }];
    try {
      const c = await P.RootlistAPI.getContents();
      const walk = (list) => list.forEach((i) => {
        if (i.type === "playlist") items.push({ name: i.name, path: "/playlist/" + i.uri.split(":").pop(), uri: i.uri });
        else if (i.items) walk(i.items);
      });
      walk(c.items);
    } catch {}

    overlay = el("div", "konna-overlay");
    const box = el("div", "konna-picker");
    const input = el("input", "konna-picker-input");
    input.placeholder = "open playlist…";
    const list = el("div", "konna-picker-list");
    const hint = el("div", "konna-picker-hint", "enter open · shift+enter play · ctrl+n/p or ↑↓ move · esc close");
    box.append(el("div", "konna-title", "~/playlists"), input, list, hint);
    overlay.appendChild(box);
    overlay.addEventListener("mousedown", (e) => e.target === overlay && closeOverlay());
    document.body.appendChild(overlay);

    let shown = [], sel = 0;
    const score = (name, q) => {
      // subsequence match; tighter matches score higher
      let i = 0, last = -1, s = 0;
      for (const ch of name.toLowerCase()) {
        if (i < q.length && ch === q[i]) { s += last === -1 ? 0 : 10 - Math.min(9, i - last); last = i; i++; }
      }
      return i === q.length ? s + 1 : -1;
    };
    function render() {
      const q = input.value.toLowerCase().trim();
      shown = items.map((it) => ({ it, s: q ? score(it.name, q) : 0 })).filter((x) => x.s >= 0).sort((a, b) => b.s - a.s).map((x) => x.it);
      sel = Math.min(sel, Math.max(0, shown.length - 1));
      list.replaceChildren(...shown.map((it, i) => {
        const r = el("div", "konna-picker-row" + (i === sel ? " sel" : ""), it.name);
        r.addEventListener("mousedown", () => { sel = i; choose(false); });
        return r;
      }));
      list.children[sel]?.scrollIntoView({ block: "nearest" });
    }
    function choose(play) {
      const it = shown[sel];
      if (!it) return;
      closeOverlay();
      // land in the song list, like l from the library (the navigation puts the cursor on the first song)
      cur.pane = "main";
      cur.main = null;
      waitForList();
      go(it.path);
      if (play) S.Player.playUri(it.uri);
    }
    input.addEventListener("input", () => { sel = 0; render(); });
    input.addEventListener("keydown", (e) => {
      const down = e.key === "ArrowDown" || (e.ctrlKey && e.key === "n");
      const up = e.key === "ArrowUp" || (e.ctrlKey && e.key === "p");
      if (down || up) { sel = (sel + (down ? 1 : -1) + shown.length) % Math.max(1, shown.length); render(); e.preventDefault(); }
      else if (e.key === "Enter") { choose(e.shiftKey); e.preventDefault(); }
      else if (e.key === "Escape") { closeOverlay(); e.preventDefault(); }
      e.stopPropagation();
    });
    render();
    input.focus();
  }

  // ---------- hint mode (like vimium's f) ----------
  let hintState = null;
  function hints() {
    closeOverlay();
    const vw = innerWidth, vh = innerHeight;
    const targets = [...document.querySelectorAll('a[href], button, [role="row"], [role="button"], [role="tab"], input')]
      .filter((t) => {
        if (t.closest(".konna-overlay, .konna-hints")) return false;
        const r = t.getBoundingClientRect();
        if (r.width < 4 || r.height < 4 || r.bottom < 0 || r.right < 0 || r.top > vh || r.left > vw) return false;
        // one hint per row: links/buttons inside track and library rows are skipped
        if (t.getAttribute("role") !== "row" && t.closest('[role="row"]')) return false;
        // only things actually on top at their center (skips hidden panels and covered elements)
        const hit = document.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2);
        return hit && (hit === t || t.contains(hit));
      });
    if (!targets.length) return;
    const alphabet = "asdfghjklqwertyuiopzxcvbnm";
    const len = targets.length <= alphabet.length ? 1 : 2;
    const labels = targets.map((_, i) => (len === 1 ? alphabet[i] : alphabet[Math.floor(i / alphabet.length) % alphabet.length] + alphabet[i % alphabet.length]));
    const layer = el("div", "konna-hints");
    targets.forEach((t, i) => {
      const r = t.getBoundingClientRect();
      const tag = el("span", "konna-hint", labels[i]);
      tag.style.left = `${Math.max(0, r.left)}px`;
      tag.style.top = `${Math.max(0, r.top + (r.height - 18) / 2)}px`;
      layer.appendChild(tag);
    });
    document.body.appendChild(layer);
    hintState = { targets, labels, layer, typed: "" };
  }
  function hintKey(e) {
    if (e.key === "Escape") return endHints();
    if (e.key.length !== 1) return;
    hintState.typed += e.key.toLowerCase();
    const { targets, labels, layer, typed } = hintState;
    const i = labels.indexOf(typed);
    if (i >= 0) {
      const t = targets[i];
      endHints();
      if (t.getAttribute("role") === "row") {
        // rows: open on click, play on double click (tracks); shift+letter plays
        t.dispatchEvent(new MouseEvent(e.shiftKey ? "dblclick" : "click", { bubbles: true }));
        if (!e.shiftKey) t.click?.();
      } else if (t.tagName === "INPUT") t.focus();
      else t.click();
      return;
    }
    [...layer.children].forEach((h, j) => h.classList.toggle("dim", !labels[j].startsWith(typed)));
    if (!labels.some((l) => l.startsWith(typed))) endHints();
  }
  function endHints() {
    hintState?.layer.remove();
    hintState = null;
  }

  // ---------- dispatcher ----------
  let pendingG = null;
  document.addEventListener(
    "keydown",
    (e) => {
      if (hintState) { hintKey(e); e.preventDefault(); e.stopPropagation(); return; }
      if (search?.input && e.target === search.input) {
        if (e.key === "Escape") endFind();
        else if (e.key === "Enter") confirmFind();
        else return;
        e.preventDefault();
        e.stopPropagation();
        return;
      }
      if (e.key === "Escape") {
        if (overlay) { closeOverlay(); e.preventDefault(); return; }
        if (search) { endFind(); toast("find cleared"); e.preventDefault(); return; }
        if (typing(document.activeElement)) { document.activeElement.blur(); e.preventDefault(); return; }
      }
      if (typing(e.target) || e.ctrlKey || e.metaKey || e.altKey) return;

      if (pendingG) {
        clearTimeout(pendingG);
        pendingG = null;
        closeOverlay();
        if (e.key === "g") jump(false, () => scrollTo(0));
        else gmap[e.key]?.();
        e.preventDefault();
        e.stopPropagation();
        return;
      }
      if (e.key === "g") {
        gPopup();
        pendingG = setTimeout(() => { pendingG = null; closeOverlay(); }, 1500);
        e.preventDefault();
        e.stopPropagation();
        return;
      }
      const fn = single[e.key];
      if (fn) {
        if (overlay && e.key !== "?") closeOverlay();
        // false = nothing to act on (e.g. enter with no cursor): let spotify have the key
        if (fn() === false) return;
        e.preventDefault();
        e.stopPropagation();
      }
    },
    true,
  );

  // ---------- no home feed: open on liked songs ----------
  const skipHome = (loc) => {
    if ((loc?.pathname ?? P.History.location.pathname) === "/") P.History.replace("/collection/tracks");
  };
  skipHome();
  P.History.listen(skipHome);

  // spotify saves "collapsed" when it starts in a narrow window; undo that once the library has rendered
  let uncollapseTries = 0;
  const uncollapseTimer = setInterval(() => {
    uncollapseLibrary();
    if (++uncollapseTries >= 30) clearInterval(uncollapseTimer);
  }, 500);

  setPlaceholder();
  // repaint too: spotify re-renders rows and drops the cursor class
  new MutationObserver(() => {
    setPlaceholder();
    schedulePaint();
  }).observe(document.body, { childList: true, subtree: true, attributes: true, attributeFilter: ["class", "aria-rowindex"] });
})();
