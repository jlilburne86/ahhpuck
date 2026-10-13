// AhhPuck landing page: language switch, release modes, ECU requests, FAQ.
// The wheelhave.com/ahhpuck port (AhhPuckLanding.tsx) mirrors this file; keep them in step.
(function () {
  var root = document.getElementById('ahp');
  if (!root) return;
  var dict = window.AHHPUCK_I18N || {};
  var KEY = 'puckit-lang';
  var lang = 'en';

  function t(key) {
    var e = dict[key];
    return e ? e[lang] : '';
  }

  // Release modes: which of the nine loop steps each mode includes.
  var MODE_STEPS = [[1, 2, 3, 4], [1, 2, 3, 4, 5, 8], [1, 2, 3, 4, 5, 6, 7, 8, 9]];
  function setMode(mode) {
    root.querySelectorAll('.ap-mode').forEach(function (b) {
      b.setAttribute('aria-pressed', String(Number(b.getAttribute('data-mode')) === mode));
    });
    root.querySelectorAll('[data-mode-desc]').forEach(function (el) {
      el.hidden = Number(el.getAttribute('data-mode-desc')) !== mode;
    });
    root.querySelectorAll('.ap-step').forEach(function (el) {
      el.setAttribute('data-off', String(MODE_STEPS[mode].indexOf(Number(el.getAttribute('data-step'))) < 0));
    });
  }

  // "Which ECU should be next?": toggle chips, then open an email with the picks.
  var sent = false;
  var send = document.getElementById('apSend');
  function picked() {
    return Array.prototype.map.call(root.querySelectorAll('.ap-chip[aria-pressed="true"]'), function (c) { return c.getAttribute('data-ecu'); });
  }
  function renderSend() {
    if (!send) return;
    var n = picked().length;
    var state = sent ? 'sent' : n ? 'ready' : 'empty';
    send.setAttribute('data-state', state);
    send.setAttribute('aria-disabled', state === 'empty' ? 'true' : 'false');
    send.textContent = state === 'sent' ? t('vote.sent') : state === 'ready' ? t(n > 1 ? 'vote.reqN' : 'vote.req1').replace('{n}', n) : t('vote.empty');
  }

  // FAQ: one answer open at a time; the first starts open.
  function toggleFaq(item) {
    var open = item.getAttribute('data-open') !== 'true';
    root.querySelectorAll('.ap-faq-item').forEach(function (it) {
      var on = open && it === item;
      it.setAttribute('data-open', String(on));
      it.querySelector('.ap-faq-q').setAttribute('aria-expanded', String(on));
      it.querySelector('.ap-faq-sign').textContent = on ? '−' : '+';
      it.querySelector('.ap-faq-a').hidden = !on;
    });
  }

  // Language: English or Japanese. ?lang= wins, then the choice saved by any PuckIt page, then the browser.
  function apply(next) {
    lang = next;
    root.querySelectorAll('[data-i18n]').forEach(function (el) {
      var e = dict[el.getAttribute('data-i18n')];
      if (e && e[lang] != null) el.innerHTML = e[lang];
    });
    root.querySelectorAll('[data-i18n-alt]').forEach(function (el) {
      var e = dict[el.getAttribute('data-i18n-alt')];
      if (e && e[lang] != null) el.setAttribute('alt', e[lang]);
    });
    root.querySelectorAll('[data-i18n-aria]').forEach(function (el) {
      var e = dict[el.getAttribute('data-i18n-aria')];
      if (e && e[lang] != null) el.setAttribute('aria-label', e[lang]);
    });
    root.setAttribute('data-lang', lang);
    document.documentElement.lang = lang;
    document.documentElement.setAttribute('data-lang', lang);
    root.querySelectorAll('.ap-lang button').forEach(function (b) {
      b.setAttribute('aria-pressed', b.getAttribute('data-lang') === lang ? 'true' : 'false');
    });
    renderSend();
    try { localStorage.setItem(KEY, lang); } catch (e) {}
  }

  root.addEventListener('click', function (ev) {
    var el = ev.target.closest ? ev.target : ev.target.parentElement;
    var b;
    if ((b = el.closest('.ap-lang button'))) { apply(b.getAttribute('data-lang')); return; }
    if ((b = el.closest('.ap-mode'))) { setMode(Number(b.getAttribute('data-mode'))); return; }
    if ((b = el.closest('.ap-chip'))) {
      b.setAttribute('aria-pressed', b.getAttribute('aria-pressed') === 'true' ? 'false' : 'true');
      sent = false;
      renderSend();
      return;
    }
    if ((b = el.closest('.ap-send'))) {
      var ecus = picked();
      if (!ecus.length) return;
      // There is no request backend: the picks go to the team as an email draft.
      location.href = 'mailto:contact@wheelhave.com?subject=' + encodeURIComponent('AhhPuck: ECU request') +
        '&body=' + encodeURIComponent(t('vote.mail') + '\n\n- ' + ecus.join('\n- ') + '\n');
      sent = true;
      renderSend();
      return;
    }
    if ((b = el.closest('.ap-faq-q'))) toggleFaq(b.closest('.ap-faq-item'));
  });

  var want = null;
  try { want = new URLSearchParams(location.search).get('lang'); } catch (e) {}
  if (want !== 'ja' && want !== 'en') { try { want = localStorage.getItem(KEY); } catch (e) { want = null; } }
  if (want !== 'ja' && want !== 'en') want = (navigator.language || '').toLowerCase().indexOf('ja') === 0 ? 'ja' : 'en';
  // Apply either language: ?lang=en must also persist, or a saved 'ja' would return next visit.
  apply(want);
  setMode(2);
})();
