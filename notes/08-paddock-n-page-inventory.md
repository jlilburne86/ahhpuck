# Paddock-N Freedom Computer page inventory

Scope: Freedom Computer pages captured locally from the Paddock-N Google Site.
The Google Site root was not available to the current web crawler, so this is
the complete inventory of captured pages, not a claim that every page on the
whole site has been retrieved.

## Page 1 — ECU/Freedom Computer setup

- Local capture: `downloads/paddock_freedom_setup.html`
- Canonical path: `/home/car-life/ecufreedom-computerセットアップ`
- Role: entry/setup page for the Freedom Computer material.
- Product implication: this is the navigation root for the FCSS/FCST material;
  preserve its linked page structure when building our documentation UI.
- Evidence: `observed` locally; detailed technical claims require the linked
  child pages below.

## Page 2 — FCST development

- Local capture: `downloads/paddock_fcst_development.html`
- Canonical path: `/home/car-life/ecufreedom-computerセットアップ/fcstの開発`
- Role: development history for FCST, a replacement/companion setting tool.
- Captured linked leads include the author's protocol-analysis articles and
  later FCST development entries.
- Product implication: FCST is a valuable reference for UI/workflow and may
  expose practical map/control concepts, but it is not proof of a complete or
  safe FC-03 protocol implementation.
- Evidence: `observed` local page/captured links; protocol semantics remain
  `unverified` until reproduced from serial captures.

## Page 3 — FCST usage environment

- Local capture: `downloads/paddock_fcst_environment.html`
- Canonical path: `/home/car-life/ecufreedom-computerセットアップ/fcst活用環境`
- Role: environment/setup notes for using FCST with Freedom/FCSS.
- Product implication: use this as a compatibility and workflow reference,
  not as authorization to send writes. Keep original FCSS backups and test in
  replay mode first.
- Evidence: `observed` locally; hardware and protocol details require direct
  confirmation.

## Page 4 — FCSS limitations

- Local capture: `downloads/paddock_fcss_limits.html`
- Canonical path: `/home/car-life/ecufreedom-computerセットアップ/fcssの限界`
- Role: limitations and failure modes of legacy FCSS.
- Product implication: this supports fail-closed input validation, frequent
  backups, no unchecked real-time edits, and explicit recovery/rollback flows.
- Evidence: `observed` locally; treat author commentary as community evidence,
  not manufacturer documentation.

## Linked external research leads found in the captures

The FCST development page links to a sequence of Ameba articles by the author,
including protocol-analysis and later FCST development posts. The captured
links include:

- `entry-11412525148.html` — protocol-analysis lead referenced in the source
  register;
- `entry-11492183426.html` and `entry-11616893447.html` — older development
  leads supplied for review;
- later FCST development entries through `entry-128...` IDs.

These are third-party development notes. They should be imported as research
leads, with page title, date, screenshots, and exact claims recorded separately
from verified FC-03 observations.

## Site-crawl gap and next capture action

The next research action is to use a normal browser session to open the Paddock-N
root, expand the left navigation, and save each linked Freedom page as HTML or
PDF. For every page, capture URL, title, update date, screenshots, linked files,
and a SHA-256 hash. Do not treat Google Sites' generated JavaScript as the
technical source; preserve the rendered page and images as evidence.
