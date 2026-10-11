// Ahhpuck landing page: mobile nav + illustrative hero telemetry.
(function () {
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

  // Demo values only. They are not ECU data.
  var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (reduce) return;

  var rpmEl = document.querySelector('[data-tick="rpm"]');
  var rpmBar = document.querySelector('[data-bar="rpm"]');
  var lamEl = document.querySelector('[data-tick="lambda"]');
  var loadEl = document.querySelector('[data-tick="load"]');
  var ignEl = document.querySelector('[data-tick="ign"]');
  var cltEl = document.querySelector('[data-tick="clt"]');
  if (!rpmEl) return;

  var t = 0;
  function fmt(n) { return String(Math.round(n)).replace(/\B(?=(\d{3})+(?!\d))/g, ' '); }
  function unit(v, u) { return v + '<span class="unit">' + u + '</span>'; }

  setInterval(function () {
    t += 0.35;
    var rpm = 4850 + Math.sin(t) * 650 + Math.sin(t * 2.3) * 140;
    var load = 72 + Math.sin(t * 0.8) * 9;
    var lam = 0.92 + Math.sin(t * 1.4) * 0.015;
    var ign = 24 + Math.round(Math.sin(t * 0.6) * 2);
    var clt = 84 + Math.sin(t * 0.1) * 1.2;
    rpmEl.textContent = fmt(rpm);
    if (rpmBar) rpmBar.style.width = Math.min(100, rpm / 8200 * 100) + '%';
    if (loadEl) loadEl.innerHTML = unit(Math.round(load), '%');
    if (lamEl) lamEl.textContent = lam.toFixed(2);
    if (ignEl) ignEl.innerHTML = unit(ign, '°');
    if (cltEl) cltEl.innerHTML = unit(Math.round(clt), '°C');
  }, 700);
})();
