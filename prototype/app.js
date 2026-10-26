/* Local-only prototype: no network API, analytics, or messaging permissions. */
(() => {
  "use strict";
  const $ = (s) => document.querySelector(s);
  const $$ = (s) => [...document.querySelectorAll(s)];
  const stickers = window.STICKERS || [];
  const asset = (p) => "../" + p.split("/").map(encodeURIComponent).join("/");
  const safeRead = (key, fallback) => {
    try {
      return JSON.parse(localStorage.getItem(key)) ?? fallback;
    } catch {
      return fallback;
    }
  };
  const validIds = new Set(stickers.map((s) => s.id));
  const storedFavorites = safeRead("8bit-favorites", []);
  const favorites = new Set(
    (Array.isArray(storedFavorites) ? storedFavorites : []).filter((id) =>
      validIds.has(id),
    ),
  );
  let filter = "all",
    category = "all",
    selected = null,
    toastTimer;
  const save = (key, value) => {
    try {
      localStorage.setItem(key, JSON.stringify(value));
      return true;
    } catch {
      return false;
    }
  };
  const toast = (message) => {
    $("#toast").textContent = message;
    $("#toast").classList.add("show");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => $("#toast").classList.remove("show"), 2600);
  };
  function view(name) {
    $("#collection-view").hidden = name !== "collection";
    $("#lab-view").hidden = name !== "lab";
    $$(".nav-tab").forEach((b) => {
      const active = b.dataset.view === name;
      b.classList.toggle("active", active);
      b.setAttribute("aria-pressed", active);
    });
  }
  $$(".nav-tab").forEach((b) =>
    b.addEventListener("click", () => view(b.dataset.view)),
  );
  $("#make-sticker").addEventListener("click", () => {
    view("lab");
    window.scrollTo(0, 0);
  });
  const titles = {
    all: "A feeling for every message",
    tiny: "Tiny pixels. Huge reactions",
    new: "Meet your fresh pixels",
    original: "The ones that started it all",
    animated: "A little movement. A lot of joy",
    favorites: "Your very own tiny favorites",
  };
  function render() {
    const q = $("#search").value.toLowerCase().trim();
    const result = stickers.filter(
      (s) =>
        (filter !== "new" || !s.original) &&
        (filter !== "tiny" || s.collection === "tiny-pixels") &&
        (filter !== "original" || s.original) &&
        (filter !== "animated" || s.animated) &&
        (filter !== "favorites" || favorites.has(s.id)) &&
        (category === "all" || s.category === category) &&
        (!q ||
          [s.title, s.category, ...s.tags].join(" ").toLowerCase().includes(q)),
    );
    $("#collection-title").textContent = titles[filter] + ".";
    $("#results-summary").textContent =
      `${result.length} ${result.length === 1 ? "sticker" : "stickers"} · ${filter === "original" ? "Recovered from your 2018 project" : "Tiny expressions, ready to explore"}`;
    $("#all-count").textContent = stickers.length;
    $("#new-count").textContent = stickers.filter((s) => !s.original).length;
    $("#tiny-count").textContent = stickers.filter(
      (s) => s.collection === "tiny-pixels",
    ).length;
    $("#animated-count").textContent = stickers.filter(
      (s) => s.animated,
    ).length;
    $("#favorite-count").textContent = favorites.size;
    $("#sticker-grid").replaceChildren(
      ...result.map((s) => {
        const card = document.createElement("article");
        card.className = "sticker-card";
        card.dataset.sticker = s.id;
        const open = document.createElement("button");
        open.className = "sticker-open";
        open.setAttribute("aria-label", `Preview ${s.title}`);
        const art = document.createElement("div");
        art.className = "sticker-art";
        const img = new Image();
        img.src = asset(s.preview);
        img.alt = s.title;
        img.loading = "lazy";
        art.append(img);
        const meta = document.createElement("div");
        meta.className = "sticker-meta";
        const title = document.createElement("strong");
        title.textContent = s.title;
        const detail = document.createElement("span");
        detail.textContent = s.original
          ? "THE 2018 ORIGINALS"
          : s.category +
            (s.collection === "tiny-pixels" ? " · 16 × 16" : " · NEW");
        meta.append(title, detail);
        open.append(art, meta);
        open.onclick = () => openSticker(s);
        const fav = document.createElement("button");
        fav.className =
          "favorite-button" + (favorites.has(s.id) ? " saved" : "");
        fav.textContent = favorites.has(s.id) ? "♥" : "♡";
        fav.setAttribute(
          "aria-label",
          `${favorites.has(s.id) ? "Unsave" : "Save"} ${s.title}`,
        );
        fav.setAttribute("aria-pressed", favorites.has(s.id));
        fav.onclick = () => toggleFavorite(s);
        card.append(open, fav);
        if (s.animated) {
          const badge = document.createElement("span");
          badge.className = "motion-badge";
          badge.textContent = "▷ ANIMATED";
          card.append(badge);
        }
        return card;
      }),
    );
    $("#empty-state").hidden = result.length !== 0;
    $$(".shelf").forEach((b) => {
      const active = b.dataset.filter === filter;
      b.classList.toggle("active", active);
      b.setAttribute("aria-pressed", active);
    });
    $$(".category").forEach((b) => {
      const active = b.dataset.category === category;
      b.classList.toggle("active", active);
      b.setAttribute("aria-pressed", active);
    });
  }
  function toggleFavorite(s) {
    const fromCard =
      document.activeElement?.classList.contains("favorite-button");
    favorites.has(s.id) ? favorites.delete(s.id) : favorites.add(s.id);
    const persisted = save("8bit-favorites", [...favorites]);
    render();
    if (selected) updateFavorite();
    if (fromCard)
      (
        document.querySelector(`[data-sticker="${s.id}"] .favorite-button`) ||
        $("#collection-title")
      ).focus();
    toast(
      persisted
        ? favorites.has(s.id)
          ? "Saved to your tiny favorites"
          : "Removed from favorites"
        : "Favorite changed for this session",
    );
  }
  function updateFavorite() {
    $("#dialog-favorite").textContent = favorites.has(selected.id)
      ? "♥ Saved favorite"
      : "♡ Save favorite";
  }
  function openSticker(s) {
    selected = s;
    $("#dialog-image").src = asset(s.preview);
    $("#dialog-image").alt = s.title;
    $("#dialog-title").textContent = s.title;
    $("#dialog-category").textContent = s.original
      ? "RECOVERED · THE 2018 ORIGINALS"
      : "FRESH PIXELS · " + s.category.toUpperCase();
    $("#dialog-description").textContent =
      s.collection === "tiny-pixels"
        ? "Just 16 × 16 pixels. Download the tiny original or a crisp, transparent sticker enlarged without smoothing."
        : s.animated
          ? "A tiny animated expression. Try it in the local chat or download the original animated PNG."
          : "A little pixel personality for your next conversation. Try it in the local chat or download the transparent PNG.";
    $("#download-sticker").href = asset(s.filename);
    $("#download-sticker").download = s.filename.split("/").pop();
    $("#download-pixels").hidden = s.collection !== "tiny-pixels";
    if (s.pixelSource) {
      $("#download-pixels").href = asset(s.pixelSource);
      $("#download-pixels").download = s.id + "-16x16.png";
    }
    updateFavorite();
    $("#sticker-dialog").showModal();
  }
  $("#close-dialog").onclick = () => $("#sticker-dialog").close();
  $("#sticker-dialog").addEventListener("close", () => {
    if (!$("#collection-view").hidden && selected)
      (
        document.querySelector(
          `[data-sticker="${selected.id}"] .sticker-open`,
        ) || $("#collection-title")
      ).focus();
  });
  $("#sticker-dialog").addEventListener("click", (e) => {
    if (e.target === $("#sticker-dialog")) {
      const r = e.target.getBoundingClientRect();
      if (
        e.clientX < r.left ||
        e.clientX > r.right ||
        e.clientY < r.top ||
        e.clientY > r.bottom
      )
        e.target.close();
    }
  });
  $("#dialog-favorite").onclick = () => toggleFavorite(selected);
  function preview(s) {
    const img = $("#chat-sticker");
    img.src = asset(s.preview);
    img.alt = s.title + " in local chat preview";
  }
  $("#preview-in-chat").onclick = () => {
    preview(selected);
    $("#sticker-dialog").close();
    view("collection");
    window.scrollTo({ top: 0, behavior: "smooth" });
    toast("Added to the local chat preview");
  };
  $("#random-sticker").onclick = () =>
    preview(stickers[Math.floor(Math.random() * stickers.length)]);
  $$(".shelf").forEach(
    (b) =>
      (b.onclick = () => {
        filter = b.dataset.filter;
        category = "all";
        render();
      }),
  );
  $$(".category").forEach(
    (b) =>
      (b.onclick = () => {
        category = b.dataset.category;
        render();
      }),
  );
  $("#search").addEventListener("input", render);
  $("#reset-filters").onclick = () => {
    filter = "all";
    category = "all";
    $("#search").value = "";
    render();
  };
  const getSticker = (id, fallback) =>
    stickers.find((s) => s.id === id) || stickers[fallback];
  if (stickers.length) {
    $("#hero-star").src = asset(getSticker("tiny_frog", 0).preview);
    $("#hero-cat").src = asset(getSticker("tiny_cat", 1).preview);
    preview(getSticker("tiny_sideeye", 2));
  }
  // Pixel editor uses an editable 32×32 array, exported at integer 8× into 300px padding.
  const N = 32,
    size = 16,
    canvas = $("#pixel-canvas"),
    ctx = canvas.getContext("2d"),
    mini = $("#mini-canvas"),
    mctx = mini.getContext("2d");
  const palette = [
    "#302438",
    "#f16b85",
    "#e65268",
    "#ffaf70",
    "#f6d95c",
    "#fff3c9",
    "#98d7ad",
    "#4f9c85",
    "#94ccdf",
    "#5c92bd",
    "#b7a0d5",
    "#8066a8",
    "#fffdf5",
    "#c2b9b3",
    "#7e7485",
    "#54475e",
    "#bf805e",
    "#e1b895",
  ];
  let pixels = Array(N * N).fill(null),
    color = palette[1],
    tool = "pencil",
    history = [],
    drawing = false,
    last = null,
    cursor = [16, 16];
  const restored = safeRead("8bit-draft", null);
  if (
    Array.isArray(restored) &&
    restored.length === N * N &&
    restored.every((v) => v === null || /^#[\da-f]{6}$/i.test(v))
  )
    pixels = restored;
  function draw() {
    ctx.clearRect(0, 0, 512, 512);
    for (let y = 0; y < N; y++)
      for (let x = 0; x < N; x++) {
        ctx.fillStyle = (x + y) % 2 ? "#e9e4dc" : "#fffcf7";
        ctx.fillRect(x * size, y * size, size, size);
        if (pixels[y * N + x]) {
          ctx.fillStyle = pixels[y * N + x];
          ctx.fillRect(x * size, y * size, size, size);
        }
      }
    if ($("#show-grid").checked) {
      ctx.strokeStyle = "#42352b16";
      ctx.lineWidth = 0.5;
      ctx.beginPath();
      for (let i = 0; i <= N; i++) {
        ctx.moveTo(i * size, 0);
        ctx.lineTo(i * size, 512);
        ctx.moveTo(0, i * size);
        ctx.lineTo(512, i * size);
      }
      ctx.stroke();
    }
    if (document.activeElement === canvas) {
      ctx.strokeStyle = "#8066a8";
      ctx.lineWidth = 2;
      ctx.strokeRect(
        cursor[0] * size + 1,
        cursor[1] * size + 1,
        size - 2,
        size - 2,
      );
    }
    mctx.clearRect(0, 0, 300, 300);
    pixels.forEach((p, i) => {
      if (p) {
        mctx.fillStyle = p;
        mctx.fillRect(22 + (i % N) * 8, 22 + Math.floor(i / N) * 8, 8, 8);
      }
    });
    $("#undo").disabled = !history.length;
  }
  function persist() {
    const saved = save("8bit-draft", pixels);
    $("#draft-status").textContent = saved
      ? "Draft saved locally"
      : "Draft kept this session";
  }
  function snapshot() {
    history.push([...pixels]);
    if (history.length > 50) history.shift();
  }
  function chooseTool(t) {
    tool = t;
    $$(".tool").forEach((b) => {
      const active = b.dataset.tool === t;
      b.classList.toggle("active", active);
      b.setAttribute("aria-pressed", active);
    });
  }
  $$(".tool").forEach((b) => (b.onclick = () => chooseTool(b.dataset.tool)));
  function chooseColor(c) {
    color = c;
    $("#custom-color").value = c;
    $$(".swatch").forEach((b) => {
      const active = b.dataset.color === c;
      b.classList.toggle("active", active);
      b.setAttribute("aria-pressed", active);
    });
    if (tool === "eraser") chooseTool("pencil");
  }
  $("#palette").replaceChildren(
    ...palette.map((c) => {
      const b = document.createElement("button");
      b.className = "swatch";
      b.dataset.color = c;
      b.style.background = c;
      b.setAttribute("aria-label", "Use color " + c);
      b.onclick = () => chooseColor(c);
      return b;
    }),
  );
  $("#custom-color").oninput = (e) => chooseColor(e.target.value);
  $("#show-grid").onchange = draw;
  function point(e) {
    const r = canvas.getBoundingClientRect();
    return [
      Math.min(
        31,
        Math.max(0, Math.floor(((e.clientX - r.left) / r.width) * N)),
      ),
      Math.min(
        31,
        Math.max(0, Math.floor(((e.clientY - r.top) / r.height) * N)),
      ),
    ];
  }
  function paint(x, y) {
    pixels[y * N + x] = tool === "eraser" ? null : color;
  }
  function line(a, b) {
    let [x, y] = a;
    const [x1, y1] = b,
      dx = Math.abs(x1 - x),
      dy = -Math.abs(y1 - y),
      sx = x < x1 ? 1 : -1,
      sy = y < y1 ? 1 : -1;
    let err = dx + dy;
    while (true) {
      paint(x, y);
      if (x === x1 && y === y1) break;
      const e = 2 * err;
      if (e >= dy) {
        err += dy;
        x += sx;
      }
      if (e <= dx) {
        err += dx;
        y += sy;
      }
    }
  }
  function fill(x, y) {
    const before = pixels[y * N + x];
    if (before === color) return;
    const todo = [[x, y]];
    while (todo.length) {
      const [a, b] = todo.pop();
      if (a < 0 || a >= N || b < 0 || b >= N || pixels[b * N + a] !== before)
        continue;
      pixels[b * N + a] = color;
      todo.push([a - 1, b], [a + 1, b], [a, b - 1], [a, b + 1]);
    }
  }
  canvas.onfocus = draw;
  canvas.onblur = draw;
  canvas.onkeydown = (e) => {
    const directions = {
      ArrowLeft: [-1, 0],
      ArrowRight: [1, 0],
      ArrowUp: [0, -1],
      ArrowDown: [0, 1],
    };
    if (directions[e.key]) {
      e.preventDefault();
      const [dx, dy] = directions[e.key];
      cursor = [
        Math.max(0, Math.min(31, cursor[0] + dx)),
        Math.max(0, Math.min(31, cursor[1] + dy)),
      ];
      draw();
      $("#draft-status").textContent =
        `Pixel ${cursor[0] + 1}, ${cursor[1] + 1}`;
    }
    if (e.key === " " || e.key === "Enter") {
      e.preventDefault();
      snapshot();
      tool === "fill" ? fill(...cursor) : paint(...cursor);
      persist();
      draw();
    }
  };
  canvas.onpointerdown = (e) => {
    if (e.button !== 0) return;
    e.preventDefault();
    snapshot();
    canvas.setPointerCapture(e.pointerId);
    drawing = true;
    last = point(e);
    if (tool === "fill") {
      fill(...last);
    } else paint(...last);
    draw();
  };
  canvas.onpointermove = (e) => {
    if (!drawing || tool === "fill") return;
    const p = point(e);
    line(last, p);
    last = p;
    draw();
  };
  function finish() {
    if (drawing) {
      drawing = false;
      persist();
      draw();
    }
  }
  canvas.onpointerup = finish;
  canvas.onpointercancel = finish;
  $("#undo").onclick = () => {
    if (history.length) {
      pixels = history.pop();
      persist();
      draw();
    }
  };
  $("#clear-drawing").onclick = () => {
    snapshot();
    pixels.fill(null);
    persist();
    draw();
    toast("Canvas cleared · Undo brings it back");
  };
  function heartSample() {
    snapshot();
    pixels.fill(null);
    const pattern = [
      "  xxxx   xxxx  ",
      " xxxxxx xxxxxx ",
      "xxxxxxxxxxxxxxx",
      "xxxxxxxxxxxxxxx",
      "xxxxxxxxxxxxxxx",
      " xxxxxxxxxxxxx ",
      "  xxxxxxxxxxx  ",
      "   xxxxxxxxx   ",
      "    xxxxxxx    ",
      "     xxxxx     ",
      "      xxx      ",
      "       x       ",
    ];
    pattern.forEach((row, y) =>
      [...row].forEach((p, x) => {
        if (p === "x")
          pixels[(y + 9) * N + x + 8] = y > 15 ? "#e65268" : "#f16b85";
      }),
    );
    pixels[11 * N + 11] = "#fff3c9";
    pixels[11 * N + 12] = "#fff3c9";
    pixels[12 * N + 10] = "#fff3c9";
    persist();
    draw();
  }
  $("#sample-drawing").onclick = heartSample;
  $("#export-drawing").onclick = () => {
    if (!pixels.some(Boolean)) {
      toast("Draw a few pixels first");
      return;
    }
    mini.toBlob((blob) => {
      if (!blob) return;
      const url = URL.createObjectURL(blob),
        a = document.createElement("a");
      a.href = url;
      a.download = "8-bit-art-my-sticker.png";
      a.click();
      setTimeout(() => URL.revokeObjectURL(url), 30000);
      toast("Your transparent PNG is ready");
    }, "image/png");
  };
  $("#edit-sticker").onclick = async () => {
    const s = selected,
      img = new Image();
    img.src = asset(s.preview);
    try {
      await img.decode();
      const off = document.createElement("canvas");
      off.width = off.height = N;
      const oc = off.getContext("2d", { willReadFrequently: true });
      oc.imageSmoothingEnabled = false;
      oc.drawImage(img, 0, 0, N, N);
      const data = oc.getImageData(0, 0, N, N).data;
      snapshot();
      pixels = Array.from({ length: N * N }, (_, i) =>
        data[i * 4 + 3] > 128
          ? "#" +
            [data[i * 4], data[i * 4 + 1], data[i * 4 + 2]]
              .map((v) => v.toString(16).padStart(2, "0"))
              .join("")
          : null,
      );
      persist();
      draw();
      $("#sticker-dialog").close();
      view("lab");
      window.scrollTo(0, 0);
      toast(
        s.animated
          ? "Loaded one frame as editable pixels"
          : "Loaded into your pixel canvas",
      );
    } catch {
      toast("Could not load this image into the canvas");
    }
  };
  document.addEventListener("keydown", (e) => {
    if (
      e.ctrlKey ||
      e.metaKey ||
      e.altKey ||
      /INPUT|TEXTAREA/.test(e.target.tagName) ||
      $("#sticker-dialog").open
    )
      return;
    if (e.key === "/" && !$("#collection-view").hidden) {
      e.preventDefault();
      $("#search").focus();
    }
    if (!$("#lab-view").hidden) {
      if (e.key.toLowerCase() === "p") chooseTool("pencil");
      if (e.key.toLowerCase() === "e") chooseTool("eraser");
      if (e.key.toLowerCase() === "f") chooseTool("fill");
    }
  });
  chooseColor(color);
  draw();
  render();
})();
