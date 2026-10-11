// AhhPuck landing page: Wheel Have header menus, language switch.
(function () {
  // Language: English or Japanese. ?lang=ja wins, then the choice saved by any PuckIt page, then the browser.
  var dict = window.AHHPUCK_I18N || {};
  var KEY = 'puckit-lang';
  function apply(lang) {
    document.querySelectorAll('[data-i18n]').forEach(function (el) {
      var e = dict[el.getAttribute('data-i18n')];
      if (e && e[lang] != null) el.innerHTML = e[lang];
    });
    document.documentElement.lang = lang;
    document.documentElement.setAttribute('data-lang', lang);
    document.querySelectorAll('.lang button').forEach(function (b) {
      b.setAttribute('aria-pressed', b.getAttribute('data-lang') === lang ? 'true' : 'false');
    });
    try { localStorage.setItem(KEY, lang); } catch (e) {}
  }
  var want = null;
  try { want = new URLSearchParams(location.search).get('lang'); } catch (e) {}
  if (want !== 'ja' && want !== 'en') { try { want = localStorage.getItem(KEY); } catch (e) { want = null; } }
  if (want !== 'ja' && want !== 'en') want = (navigator.language || '').toLowerCase().indexOf('ja') === 0 ? 'ja' : 'en';
  if (want === 'ja') apply('ja');
  document.querySelectorAll('.lang button').forEach(function (b) {
    b.addEventListener('click', function () { apply(b.getAttribute('data-lang')); });
  });

  // Site header burger (the Wheel Have header's mobile menu).
  var burger = document.getElementById('whBurger');
  var mobile = document.getElementById('wh-mobile');
  if (burger && mobile) {
    burger.addEventListener('click', function () {
      var open = mobile.hasAttribute('hidden');
      if (open) mobile.removeAttribute('hidden'); else mobile.setAttribute('hidden', '');
      burger.setAttribute('aria-expanded', open ? 'true' : 'false');
      burger.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
    });
    mobile.addEventListener('click', function (e) {
      if (e.target.tagName === 'A') { mobile.setAttribute('hidden', ''); burger.setAttribute('aria-expanded', 'false'); }
    });
  }

  // Dropdown menus: click to open, click outside or Esc to close, one open at a time.
  var dds = Array.prototype.slice.call(document.querySelectorAll('.wh-dd'));
  function closeAll(except) {
    dds.forEach(function (d) {
      if (d === except) return;
      var p = d.querySelector('.whm-panel'), b = d.querySelector('.wh-dd-btn');
      if (p) p.setAttribute('hidden', '');
      if (b) b.setAttribute('aria-expanded', 'false');
    });
  }
  dds.forEach(function (d) {
    var btn = d.querySelector('.wh-dd-btn'), panel = d.querySelector('.whm-panel');
    if (!btn || !panel) return;
    btn.addEventListener('click', function (e) {
      e.stopPropagation();
      var open = panel.hasAttribute('hidden');
      closeAll(d);
      if (open) panel.removeAttribute('hidden'); else panel.setAttribute('hidden', '');
      btn.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
  });
  document.addEventListener('click', function () { closeAll(null); });
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape') closeAll(null); });

  // Sub-bar: fade the right edge while more chips hide (phones).
  var links = document.getElementById('pksLinks');
  var fade = document.getElementById('pksFade');
  if (links && fade) {
    var update = function () { fade.setAttribute('data-on', links.scrollLeft + links.clientWidth < links.scrollWidth - 2 ? 'true' : 'false'); };
    update();
    links.addEventListener('scroll', update, { passive: true });
    window.addEventListener('resize', update);
  }

})();
