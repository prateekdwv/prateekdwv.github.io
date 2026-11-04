export function chooseDiagrams(items, years, random = Math.random) {
  return years.flatMap(year => {
    const candidates = items.filter(item => item.year === year);
    return candidates.length ? [candidates[Math.floor(random() * candidates.length)]] : [];
  });
}

async function initialize(root) {
  const column = root.querySelector('[data-publication-column]');
  const gallery = root.querySelector('[data-diagram-gallery]');
  if (!gallery) return;
  const headings = [...column.querySelectorAll('.publication-year > h2')];
  const years = headings.map(heading => Number(heading.textContent.trim()));
  const items = JSON.parse(root.querySelector('[data-diagram-manifest]').textContent);
  const links = chooseDiagrams(items, years).map(item => {
    const link = document.createElement('a');
    link.href = item.url;
    link.setAttribute('aria-label', `Open diagram: ${item.id.replaceAll('-', ' ')}`);
    const img = document.createElement('img');
    Object.assign(img, { alt: '', width: Math.round(item.width), height: Math.round(item.height),
      loading: 'lazy', decoding: 'async' });
    link.append(img);
    gallery.append(link);
    const yearIndex = years.indexOf(item.year);
    const anchor = [...headings[yearIndex].parentElement.querySelectorAll('[data-diagram]')]
      .find(entry => entry.dataset.diagram === item.id) ?? headings[yearIndex];
    return { link, img, item, yearIndex, anchor };
  });
  if (document.fonts) await document.fonts.ready;
  gallery.hidden = false;

  function render() {
    const mobile = window.matchMedia('(max-width: 767px)').matches;
    const top = gallery.getBoundingClientRect().top;
    const bottom = column.getBoundingClientRect().bottom;
    const positions = headings.map(heading => heading.getBoundingClientRect().top);
    links.forEach(({ link, img, item, yearIndex, anchor }, index) => {
      const anchorTop = anchor.getBoundingClientRect().top;
      // 38px frame padding plus 32px clearance before the next year.
      const available = mobile ? 282 : Math.min(282,
        (positions[yearIndex + 1] ?? bottom) - anchorTop - 70);
      link.hidden = (mobile && index >= 3) || available <= 0;
      link.style.top = mobile ? '' : `${anchorTop - top}px`;
      img.style.maxHeight = `${Math.max(0, available)}px`;
      if (!link.hidden && !img.hasAttribute('src')) img.src = item.url;
    });
  }
  let frame;
  const observer = new ResizeObserver(() => {
    cancelAnimationFrame(frame);
    frame = requestAnimationFrame(render);
  });
  [column, gallery, ...headings.map(heading => heading.parentElement)].forEach(el => observer.observe(el));
  render();
}

if (typeof document !== 'undefined') {
  document.querySelectorAll('[data-research-layout]').forEach(initialize);
}
