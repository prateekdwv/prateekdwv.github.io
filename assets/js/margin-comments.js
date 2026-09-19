(() => {
  const article = document.querySelector('.post-with-comments');
  if (!article) return;
  const content = article.querySelector('.post-content');
  const notes = [...article.querySelectorAll('.margin-comments > ol > li')];
  const references = notes.map(note => [...content.querySelectorAll('a.footnote')]
    .find(link => decodeURIComponent(link.hash.slice(1)) === note.id));
  if (!notes.length || references.some(reference => !reference)) return;

  const wide = matchMedia('screen and (min-width: 1280px)');
  let pending = false;
  let firstLayout = true;

  function layout() {
    pending = false;
    article.classList.toggle('has-margin-comments', wide.matches);
    article.style.removeProperty('--margin-comments-space');
    if (!wide.matches) return;

    const origin = article.getBoundingClientRect().top;
    let bottom = 0;
    notes.forEach((note, index) => {
      const top = Math.max(references[index].getBoundingClientRect().top - origin,
        index ? bottom + 16 : 0);
      note.style.top = `${top}px`;
      bottom = top + note.getBoundingClientRect().height;
    });
    article.style.setProperty('--margin-comments-space',
      `${Math.max(0, bottom - content.getBoundingClientRect().height)}px`);

    // Restore direct note/reference links after moving notes out of the end list.
    if (firstLayout && location.hash) {
      const target = document.getElementById(decodeURIComponent(location.hash.slice(1)));
      if (target && (target.closest('.margin-comments') || target.matches('sup[id]'))) {
        target.scrollIntoView();
      }
    }
    firstLayout = false;
  }

  function schedule() {
    if (!pending) {
      pending = true;
      requestAnimationFrame(layout);
    }
  }

  // Observe natural content and note sizes, never the padding we set on article.
  const observer = new ResizeObserver(schedule);
  observer.observe(content);
  notes.forEach(note => observer.observe(note));
  wide.addEventListener('change', schedule);
  window.addEventListener('resize', schedule);
  document.fonts.ready.then(schedule);
  schedule();
})();
