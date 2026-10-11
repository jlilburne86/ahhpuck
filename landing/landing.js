// Ahhpuck landing page: mobile nav + illustrative hero telemetry.
(function () {
  var toggle = document.getElementById('navToggle');
  var links = document.getElementById('navLinks');
  if (toggle && links) {
    toggle.addEventListener('click', function () {
      var open = links.classList.toggle('open');
      toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
    links.addEventListener('click', function (e) {
      if (e.target.tagName === 'A') {
        links.classList.remove('open');
        toggle.setAttribute('aria-expanded', 'false');
      }
    });
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
