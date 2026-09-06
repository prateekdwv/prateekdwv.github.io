// bsky-comments 1.0.1, Copyright (c) 2026 Florian Schepp, MIT License.
// Modified locally to omit author avatars. See the adjacent LICENSE file.
var u = Object.defineProperty;
var _ = (d, l, e) => l in d ? u(d, l, { enumerable: !0, configurable: !0, writable: !0, value: e }) : d[l] = e;
var o = (d, l, e) => _(d, typeof l != "symbol" ? l + "" : l, e);
const m = "https://public.api.bsky.app/xrpc";
class v extends HTMLElement {
  constructor() {
    super(...arguments);
    o(this, "_post", null);
    o(this, "_uri", null);
    o(this, "_service", m);
    o(this, "_iconLike", "❤️");
    o(this, "_iconReply", "💬");
    o(this, "_sortOrder", "asc");
    o(this, "_depth", 10);
    o(this, "_data", null);
    o(this, "_loading", !1);
    o(this, "_error", null);
    o(this, "_connected", !1);
    o(this, "_abortController", null);
  }
  static get observedAttributes() {
    return ["post", "uri", "service", "icon-like", "icon-reply", "sort", "depth"];
  }
  attributeChangedCallback(e, s, t) {
    if (s !== t) {
      switch (e) {
        case "post":
          this._post = t;
          break;
        case "uri":
          this._uri = t;
          break;
        case "service":
          this._service = t || m;
          break;
        case "icon-like":
          this._iconLike = t || "❤️";
          break;
        case "icon-reply":
          this._iconReply = t || "💬";
          break;
        case "sort":
          this._sortOrder = t === "desc" ? "desc" : "asc";
          break;
        case "depth":
          this._depth = Math.max(1, parseInt(t, 10) || 10);
          break;
      }
      this._connected && (["post", "uri", "service"].includes(e) ? (this._post || this._uri) && this.init() : this.render());
    }
  }
  connectedCallback() {
    this._connected = !0, (this._post || this._uri) && this.init();
  }
  disconnectedCallback() {
    var e;
    this._connected = !1, (e = this._abortController) == null || e.abort(), this._abortController = null;
  }
  async init() {
    var s;
    (s = this._abortController) == null || s.abort(), this._abortController = new AbortController();
    const { signal: e } = this._abortController;
    this._loading = !0, this._error = null, this.render();
    try {
      let t = this._uri;
      if (!t && this._post && (t = await this.resolveUrlToUri(this._post, e)), e.aborted) return;
      t ? await this.fetchThread(t, e) : this._data = null;
    } catch (t) {
      if (e.aborted) return;
      this._error = t.message;
    } finally {
      e.aborted || (this._loading = !1, this.render());
    }
  }
  async resolveUrlToUri(e, s) {
    const t = e.match(/profile\/([^\/]+)\/post\/([^\/]+)/);
    if (!t) throw new Error("Invalid Bluesky URL");
    const [, r, i] = t;
    if (r.startsWith("did:")) return `at://${r}/app.bsky.feed.post/${i}`;
    const n = await fetch(`${this._service}/com.atproto.identity.resolveHandle?handle=${encodeURIComponent(r)}`, { signal: s });
    if (!n.ok) throw new Error("Could not resolve handle");
    const p = await n.json();
    if (!p.did) throw new Error("No DID found");
    return `at://${p.did}/app.bsky.feed.post/${i}`;
  }
  async fetchThread(e, s) {
    var i;
    const t = await fetch(`${this._service}/app.bsky.feed.getPostThread?uri=${encodeURIComponent(e)}&depth=${this._depth}`, { signal: s });
    if (!t.ok) throw new Error("Failed to fetch thread");
    const r = await t.json();
    ((i = r.thread) == null ? void 0 : i.$type) === "app.bsky.feed.defs#threadViewPost" ? this._data = r.thread : this._data = null;
  }
  escapeHtml(e) {
    return e.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#039;");
  }
  renderRichText(e) {
    const { text: s, facets: t } = e;
    if (!t || t.length === 0) return this.escapeHtml(s);
    const r = new TextEncoder(), i = new TextDecoder(), n = r.encode(s), p = [...t].sort((y, h) => y.index.byteStart - h.index.byteStart);
    let c = "", f = 0;
    for (const y of p) {
      const { byteStart: h, byteEnd: k } = y.index;
      if (h < f || k > n.length) continue;
      c += this.escapeHtml(i.decode(n.slice(f, h)));
      const b = this.escapeHtml(i.decode(n.slice(h, k))), a = y.features[0];
      a ? a.$type === "app.bsky.richtext.facet#link" && a.uri ? c += `<a href="${this.escapeHtml(a.uri)}" target="_blank" rel="noopener noreferrer">${b}</a>` : a.$type === "app.bsky.richtext.facet#mention" && a.did ? c += `<a href="https://bsky.app/profile/${encodeURIComponent(a.did)}" target="_blank" rel="noopener noreferrer">${b}</a>` : a.$type === "app.bsky.richtext.facet#tag" && a.tag ? c += `<a href="https://bsky.app/hashtag/${encodeURIComponent(a.tag)}" target="_blank" rel="noopener noreferrer">${b}</a>` : c += b : c += b, f = k;
    }
    return c += this.escapeHtml(i.decode(n.slice(f))), c;
  }
  formatDate(e) {
    return "· " + new Date(e).toLocaleDateString(void 0, { month: "short", day: "numeric", year: "numeric" });
  }
  sortReplies(e) {
    return [...e].sort((s, t) => {
      const r = new Date(s.post.indexedAt).getTime(), i = new Date(t.post.indexedAt).getTime();
      return this._sortOrder === "asc" ? r - i : i - r;
    });
  }
  renderComment(e) {
    if (!e.post) return "";
    const { post: s, replies: t } = e, r = s.uri.split("/").pop() || "", i = `https://bsky.app/profile/${encodeURIComponent(s.author.handle)}/post/${encodeURIComponent(r)}`, n = t && t.length > 0 ? `<div class="bsky-replies">
           ${this.sortReplies(t).map((p) => this.renderComment(p)).join("")}
         </div>` : "";
    return `
      <div class="bsky-comment">
        <div class="bsky-comment-header">
          <div class="bsky-meta">
            <a href="https://bsky.app/profile/${encodeURIComponent(s.author.handle)}" target="_blank" rel="noopener noreferrer" class="bsky-author">
              ${this.escapeHtml(s.author.displayName || s.author.handle)}
            </a>
            <span class="bsky-handle">@${this.escapeHtml(s.author.handle)}</span>
            <a href="${i}" target="_blank" rel="noopener noreferrer" class="bsky-date">
              ${this.formatDate(s.indexedAt)}
            </a>
          </div>
        </div>
        <div class="bsky-body"><p>${this.renderRichText(s.record)}</p></div>
        <div class="bsky-actions">
          <span class="bsky-like"><span class="bsky-icon bsky-icon-like">${this._iconLike}</span>${s.likeCount ?? 0}</span>
          <span class="bsky-reply"><span class="bsky-icon bsky-icon-reply">${this._iconReply}</span>${s.replyCount ?? 0}</span>
        </div>
        ${n}
      </div>
    `;
  }
  render() {
    if (this._loading) {
      this.innerHTML = '<div class="bsky-loading">Loading comments...</div>';
      return;
    }
    if (this._error) {
      this.innerHTML = `<div class="bsky-error">Error: ${this.escapeHtml(this._error)}</div>`;
      return;
    }
    if (!this._uri && !this._post) {
      this.innerHTML = "";
      return;
    }
    if (!this._data) {
      this.innerHTML = `
        <div class="bsky-empty">
          <p class="bsky-empty-text">No discussion found for this post.</p>
        </div>
      `;
      return;
    }
    const e = `https://bsky.app/profile/${encodeURIComponent(this._data.post.author.handle)}/post/${encodeURIComponent(this._data.post.uri.split("/").pop() || "")}`, t = (this._data.replies ? this.sortReplies(this._data.replies) : []).map((r) => this.renderComment(r)).join("") || "";
    this.innerHTML = `
      <div class="bsky-container">
        <div class="bsky-header">
            <span class="bsky-header-text">
                Discussion found on <a href="${e}" target="_blank" rel="noopener noreferrer">Bluesky</a>
            </span>
            <a href="${e}" target="_blank" rel="noopener noreferrer" class="bsky-reply-btn">
                Reply to join discussion
            </a>
        </div>
        ${t || '<div class="bsky-no-replies">No replies yet. Be the first to comment!</div>'}
      </div>
    `;
  }
}
customElements.get("bsky-comments") || customElements.define("bsky-comments", v);
export {
  v as BskyComments
};
