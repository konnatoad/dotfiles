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
      ["n", "next track", () => S.Player.next()],
      ["p", "previous track", () => S.Player.back()],
      ["h", "seek -10s", () => seek(-10000)],
      ["l", "seek +10s", () => seek(10000)],
      ["+", "volume up", () => volume(0.05)],
      ["-", "volume down", () => volume(-0.05)],
      ["m", "mute", () => clickTestId("volume-bar-toggle-mute-button")],
      ["s", "shuffle", () => { S.Player.toggleShuffle(); toast(`shuffle ${S.Player.getShuffle() ? "on" : "off"}`); }],
      ["r", "repeat", () => { S.Player.toggleRepeat(); toast(["repeat off", "repeat all", "repeat one"][S.Player.getRepeat()] ?? "repeat"); }],
      ["y", "like / unlike track", () => { S.Player.toggleHeart(); setTimeout(() => toast(S.Player.getHeart() ? "liked" : "unliked"), 150); }],
    ]],
    ["move", [
      ["j / k", "scroll down / up", null],
      ["d / u", "half page down / up", null],
      ["gg / G", "top / bottom", null],
      ["H / L", "back / forward", null],
      ["f", "hint mode: type the letters to click", () => hints()],
      ["/", "search", () => search()],
      ["o", "open playlist (fuzzy)", () => picker()],
    ]],
    ["go to  (g …)", [
      ["g l", "liked songs", () => go("/collection/tracks")],
      ["g s", "stats", () => go("/stats")],
      ["g m", "marketplace", () => go("/marketplace")],
      ["g r", "recently played", () => history()],
      ["g q", "queue", () => clickTestId("control-button-queue")],
      ["g n", "now playing panel", () => $('[data-testid="cover-art-button"]')?.click()],
      ["g t", "lyrics", () => clickTestId("lyrics-button")],
    ]],
    ["", [["?", "this sheet", () => help()], ["esc", "close / leave input", null]]],
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
    j: () => scrollBy(140),
    k: () => scrollBy(-140),
    d: () => scrollBy((scroller()?.clientHeight ?? 800) / 2),
    u: () => scrollBy(-(scroller()?.clientHeight ?? 800) / 2),
    G: () => scrollTo(1e7),
    H: () => P.History.goBack(),
    L: () => P.History.goForward(),
    "=": () => volume(0.05),
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
    top.append(el("span", "konna-key", "g"), el("span", "konna-desc", "top of page"));
    overlay.appendChild(top);
    document.body.appendChild(overlay);
  }

  // ---------- search ----------
  function search() {
    const input = $(".Root__globalNav input");
    if (!input) return go("/search");
    input.focus();
    input.select();
  }
  const setPlaceholder = () => {
    const input = $(".Root__globalNav input");
    if (input && input.placeholder !== "/ search") input.placeholder = "/ search";
  };

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
      if (e.key === "Escape") {
        if (overlay) { closeOverlay(); e.preventDefault(); return; }
        if (typing(document.activeElement)) { document.activeElement.blur(); e.preventDefault(); return; }
      }
      if (typing(e.target) || e.ctrlKey || e.metaKey || e.altKey) return;

      if (pendingG) {
        clearTimeout(pendingG);
        pendingG = null;
        closeOverlay();
        if (e.key === "g") scrollTo(0);
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
        fn();
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

  setPlaceholder();
  new MutationObserver(setPlaceholder).observe(document.body, { childList: true, subtree: true });
})();
