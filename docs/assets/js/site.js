(() => {
  'use strict';

  const root = document.documentElement;
  const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');
  const desktopNavigation = matchMedia('(min-width: 60rem)');
  const sidebarToggle = document.querySelector('#sidebarToggle');
  const sidebar = document.querySelector('#sidebar');
  const sidebarOverlay = document.querySelector('#sidebarOverlay');
  const themeToggle = document.querySelector('#themeToggle');
  const searchDialog = document.querySelector('#searchDialog');
  const searchTrigger = document.querySelector('#searchTrigger');
  const searchInput = document.querySelector('#searchInput');
  const searchItems = [...document.querySelectorAll('[data-search-item]')];
  const searchEmpty = document.querySelector('#searchEmpty');
  const themeColor = document.querySelector('meta[name="theme-color"]');

  const setSidebar = (expanded) => {
    sidebarToggle?.setAttribute('aria-expanded', String(expanded));
    sidebarToggle?.setAttribute('aria-label', expanded ? 'Close documentation navigation' : 'Open documentation navigation');
    if (sidebar) sidebar.inert = !desktopNavigation.matches && !expanded;
  };

  const recoverNavigationState = () => setSidebar(false);
  sidebarToggle?.addEventListener('click', () => setSidebar(sidebarToggle.getAttribute('aria-expanded') !== 'true'));
  sidebarOverlay?.addEventListener('click', () => setSidebar(false));
  sidebar?.querySelectorAll('a').forEach((link) => link.addEventListener('click', () => setSidebar(false)));
  desktopNavigation.addEventListener('change', recoverNavigationState);
  recoverNavigationState();

  const syncThemeControl = () => {
    const light = root.dataset.theme === 'light';
    themeToggle?.setAttribute('aria-pressed', String(light));
    themeToggle?.setAttribute('aria-label', light ? 'Use dark theme' : 'Use light theme');
    themeColor?.setAttribute('content', light ? '#f8f7f2' : '#0a0d12');
  };

  themeToggle?.addEventListener('click', () => {
    root.dataset.theme = root.dataset.theme === 'light' ? 'dark' : 'light';
    try { localStorage.setItem('glvigor-theme', root.dataset.theme); } catch (_) {}
    syncThemeControl();
  });
  syncThemeControl();

  const filterSearch = () => {
    const query = searchInput?.value.trim().toLocaleLowerCase() || '';
    let matches = 0;
    searchItems.forEach((item) => {
      const visible = !query || item.dataset.searchText.includes(query);
      item.hidden = !visible;
      if (visible) matches += 1;
    });
    if (searchEmpty) searchEmpty.hidden = matches !== 0;
  };

  const openSearch = () => {
    if (!searchDialog?.open) searchDialog?.showModal();
    requestAnimationFrame(() => searchInput?.focus());
  };

  searchTrigger?.addEventListener('click', openSearch);
  searchInput?.addEventListener('input', filterSearch);
  searchDialog?.addEventListener('close', () => {
    if (searchInput) searchInput.value = '';
    filterSearch();
  });
  searchDialog?.addEventListener('click', (event) => {
    if (event.target === searchDialog) searchDialog.close();
  });

  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') setSidebar(false);
    if ((event.ctrlKey || event.metaKey) && event.key.toLocaleLowerCase() === 'k') {
      event.preventDefault();
      openSearch();
    }
    if (event.key === '/' && !/input|textarea|select/i.test(document.activeElement?.tagName || '')) {
      event.preventDefault();
      openSearch();
    }
  });

  const copyText = async (text) => {
    if (navigator.clipboard?.writeText) {
      await navigator.clipboard.writeText(text);
      return;
    }

    const field = document.createElement('textarea');
    field.value = text;
    field.setAttribute('readonly', '');
    field.className = 'visually-hidden';
    document.body.append(field);
    field.select();
    const copied = document.execCommand('copy');
    field.remove();
    if (!copied) throw new Error('Clipboard API is unavailable.');
  };

  document.querySelectorAll('[data-copy], [data-copy-code]').forEach((button) => {
    button.addEventListener('click', async () => {
      const pane = button.closest('.pane');
      const text = button.dataset.copy || pane?.querySelector('code')?.textContent || '';
      const label = button.querySelector('[data-copy-label]') || button.querySelector('span:last-child');
      try {
        await copyText(text);
        if (label) {
          const original = label.textContent;
          label.textContent = 'Copied';
          window.setTimeout(() => { label.textContent = original; }, 1400);
        }
      } catch (_) {
        button.setAttribute('aria-label', 'Copy failed; select the code manually');
      }
    });
  });

  const headings = [...document.querySelectorAll('.article h2, .article h3, .article h4')];
  const toc = document.querySelector('#tocList');
  if (toc && headings.length) {
    const usedIds = new Set();
    headings.forEach((heading) => {
      let id = heading.id || heading.textContent.trim().toLocaleLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '') || 'section';
      const baseId = id;
      let suffix = 2;
      while (usedIds.has(id)) id = baseId + '-' + suffix++;
      heading.id = id;
      usedIds.add(id);
      const item = document.createElement('li');
      const link = document.createElement('a');
      link.href = `#${heading.id}`;
      const label = heading.cloneNode(true);
      label.querySelectorAll('.anchor').forEach((anchor) => anchor.remove());
      link.textContent = label.textContent.trim();
      link.dataset.level = heading.tagName.slice(1);
      item.append(link);
      toc.append(item);
    });

    const links = [...toc.querySelectorAll('a')];
    const byId = new Map(links.map((link) => [decodeURIComponent(link.hash.slice(1)), link]));
    const tocPanel = toc.closest('.toc');
    let activeId = '';
    let scrollFrame = 0;

    const setCurrentHeading = () => {
      scrollFrame = 0;
      const threshold = Math.max(96, window.innerHeight * 0.16);
      let current = headings[0];
      headings.forEach((heading) => {
        if (heading.getBoundingClientRect().top <= threshold) current = heading;
      });
      if (current.id === activeId) return;
      activeId = current.id;
      links.forEach((link) => link.removeAttribute('aria-current'));
      const activeLink = byId.get(activeId);
      activeLink?.setAttribute('aria-current', 'location');

      if (activeLink && tocPanel) {
        const linkTop = activeLink.offsetTop;
        const linkBottom = linkTop + activeLink.offsetHeight;
        const viewTop = tocPanel.scrollTop;
        const viewBottom = viewTop + tocPanel.clientHeight;
        const behavior = reducedMotion.matches ? 'auto' : 'smooth';
        if (linkTop < viewTop) tocPanel.scrollTo({ top: Math.max(0, linkTop - 24), behavior });
        if (linkBottom > viewBottom) tocPanel.scrollTo({ top: linkBottom - tocPanel.clientHeight + 24, behavior });
      }
    };

    const requestHeadingSync = () => {
      if (!scrollFrame) scrollFrame = requestAnimationFrame(setCurrentHeading);
    };
    addEventListener('scroll', requestHeadingSync, { passive: true });
    addEventListener('resize', requestHeadingSync, { passive: true });
    addEventListener('hashchange', requestHeadingSync);
    setCurrentHeading();
  }

  document.querySelectorAll('a[href^="#"]').forEach((link) => {
    link.addEventListener('click', (event) => {
      const target = document.querySelector(link.hash);
      if (!target) return;
      event.preventDefault();
      target.scrollIntoView({ behavior: reducedMotion.matches ? 'auto' : 'smooth', block: 'start' });
      history.replaceState(null, '', link.hash);
    });
  });
})();
