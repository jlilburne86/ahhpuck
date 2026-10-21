#!/usr/bin/env python3
"""Fill App Store Connect for AhhPuck (app 6825259927): listing, app info, age rating, review
details and screenshots, and attach a build. It never submits anything for review.

Usage: ASC_ENV=/path/to/deploy.env python3 asc-fill.py <build-number> [screenshots-dir]
deploy.env must define ASC_KEY_ID, ASC_ISSUER_ID and ASC_PRIVATE_KEY_PATH (never committed).
Needs PyJWT + cryptography.
"""
import hashlib, json, os, sys, time, urllib.error, urllib.request
from pathlib import Path
import jwt

APP = '6825259927'
VERSION = '1.2'
LOCALE = 'en-AU'

SUBTITLE = 'Read your FC-03. Change nothing'
PROMO = ('Record what your Freedom FC-03 ECU reports, compare runs and see the evidence. '
         'Read-only: AhhPuck never writes to the ECU.')
KEYWORDS = 'ecu,fc-03,freedom,engine,tuning,lambda,afr,datalog,dyno,ae86,4a-ge,jdm,motorsport,track'
DESCRIPTION = """AhhPuck is a read-only companion for engines run by an E&E Systems Freedom FC-03 ECU.

READ, DON'T WRITE
AhhPuck reads what the ECU reports. It never writes to the ECU, changes a calibration or ignition timing, or controls the engine.

EVIDENCE ON EVERY VALUE
Each number is tagged DOCUMENTED, OBSERVED, INFERRED or UNVERIFIED, so you can see where it came from. Unverified values are never used for decisions.

COMPARE CONTROLLED RUNS
Record a baseline, then compare later runs against it on the map trace, lambda overlay and gain charts. The ledger keeps every run, with what was accepted, repeated or rolled back.

IMPORT, ANALYSE AND EXPORT
Import a run (JSON) or an FC-03 raw session from Files, look through the raw frames and their validation, and export a session with its file hashes.

YOUR DATA STAYS ON YOUR PHONE
No account and no analytics. Everything is stored on the phone. You choose what to export.

ENGLISH AND JAPANESE
Switch language from Garage.

PLEASE NOTE
Until the FC-03 cable connection is verified on a phone, the engine values in the app are labelled demo data, not readings from your engine. Imported captures show what is in the file.
Information only, not tuning advice. Use only with the vehicle stationary, on a bench or a closed course, never on a public road or while driving. You are responsible for your vehicle and for complying with local laws, including emissions rules. Terms: wheelhave.com/terms. AhhPuck is independent and not affiliated with E&E Systems."""

REVIEW_NOTES = """AhhPuck is a read-only companion app for the E&E Systems Freedom FC-03 engine ECU. There is no account or sign-in, and no in-app purchase.

READ-ONLY SAFETY BOUNDARY: the app never writes to the ECU. ECU writes, ignition or map changes and automatic tuning do not exist in the binary. The first-launch disclaimer (accepted with "I understand", re-readable under Garage > About) says it is information only, for use with the vehicle stationary or on a closed course, never on a public road.

WHAT WORKS WITHOUT THE HARDWARE (everything you can review):
1. First launch: read and accept the disclaimer. The Terms of Service and Privacy Policy open in the app from that screen.
2. Setup: How it works, Permissions (none are requested), Hardware guide, Connection (explains the cable), Vehicle profile, Phone mount.
3. Tabs: Live, Map, Runs, Review, Garage. They run on the built-in sample session; every screen shows a "DEMO DATA" strip so it is never mistaken for a live reading.
4. Runs > "Import run JSON" or "Import FC-03 raw session" opens Files; Session detail > Export shares a session. Raw frames, validation and the analysis work on imported files.
5. Garage > About: Terms of Service, Privacy Policy, Disclaimer, Open-source notices (all readable offline).

WHAT NEEDS THE HARDWARE: a live connection to an FC-03 ECU through its serial cable. That path is not yet verified on a phone, so the app says so on the Connection screen and does not pretend to be connected. We can provide a video of the app with the hardware on request.

PERMISSIONS AND PRIVACY: none requested (no location, motion, Bluetooth, camera, photos, notifications or tracking). No network requests and no data collected; files move only when the user imports or exports them.

TRADEMARKS: E&E Systems, Freedom and FC-03 are named only to say which ECU the app works with; AhhPuck is independent (see Garage > About > Open-source notices).

Contact: contact@wheelhave.com."""

env = {}
for line in open(os.environ['ASC_ENV']):
    if '=' in line and not line.startswith('#'):
        k, v = line.strip().split('=', 1); env[k] = v.strip('"\'')
KEY = open(os.path.expanduser(env['ASC_PRIVATE_KEY_PATH'])).read()


def tok():
    now = int(time.time())
    return jwt.encode({'iss': env['ASC_ISSUER_ID'], 'iat': now, 'exp': now + 900, 'aud': 'appstoreconnect-v1'},
                      KEY, algorithm='ES256', headers={'kid': env['ASC_KEY_ID']})


def call(method, path, body=None):
    req = urllib.request.Request('https://api.appstoreconnect.apple.com' + path, method=method,
                                 data=json.dumps(body).encode() if body is not None else None,
                                 headers={'Authorization': 'Bearer ' + tok(), 'Content-Type': 'application/json'})
    try:
        r = urllib.request.urlopen(req); t = r.read()
        return r.status, (json.loads(t) if t else {})
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read() or b'{}')


def must(label, res):
    code, j = res
    if code >= 300:
        print(f'FAIL {label}: HTTP {code}', [(e.get('code'), e.get('detail')) for e in j.get('errors', [])])
        return None
    print(f'OK   {label}')
    return j


def main(build_number, shots_dir):
    assert APP != '6815223956'
    # Build
    c, j = call('GET', f'/v1/builds?filter[app]={APP}&filter[version]={build_number}')
    build = j['data'][0] if c == 200 and j['data'] else None
    if not build or build['attributes']['processingState'] != 'VALID':
        sys.exit(f'build {build_number} is not VALID yet')
    bid = build['id']

    # Version 1.2 (create if missing)
    c, j = call('GET', f'/v1/apps/{APP}/appStoreVersions?filter[platform]=IOS')
    ver = next((v for v in j.get('data', []) if v['attributes']['versionString'] == VERSION), None)
    if not ver:
        r = must('create version', call('POST', '/v1/appStoreVersions', {'data': {'type': 'appStoreVersions', 'attributes': {'platform': 'IOS', 'versionString': VERSION}, 'relationships': {'app': {'data': {'type': 'apps', 'id': APP}}}}}))
        ver = r['data']
    vid = ver['id']
    print('version state:', ver['attributes'].get('appStoreState'))
    must('version copyright + release', call('PATCH', f'/v1/appStoreVersions/{vid}', {'data': {'type': 'appStoreVersions', 'id': vid, 'attributes': {'copyright': '2026 Wheel Have', 'releaseType': 'AFTER_APPROVAL'}}}))
    must('attach build', call('PATCH', f'/v1/appStoreVersions/{vid}/relationships/build', {'data': {'type': 'builds', 'id': bid}}))

    # Version localization
    c, j = call('GET', f'/v1/appStoreVersions/{vid}/appStoreVersionLocalizations')
    loc = next((x for x in j.get('data', []) if x['attributes']['locale'] == LOCALE), None)
    la = {'description': DESCRIPTION, 'keywords': KEYWORDS, 'promotionalText': PROMO,
          'supportUrl': 'https://wheelhave.com/ahhpuck', 'marketingUrl': 'https://wheelhave.com/ahhpuck'}
    if loc:
        must('version localization', call('PATCH', f"/v1/appStoreVersionLocalizations/{loc['id']}", {'data': {'type': 'appStoreVersionLocalizations', 'id': loc['id'], 'attributes': la}}))
    else:
        r = must('version localization', call('POST', '/v1/appStoreVersionLocalizations', {'data': {'type': 'appStoreVersionLocalizations', 'attributes': {**la, 'locale': LOCALE}, 'relationships': {'appStoreVersion': {'data': {'type': 'appStoreVersions', 'id': vid}}}}}))
        loc = r['data'] if r else None

    # App info: subtitle, privacy URL, categories, age rating
    c, j = call('GET', f'/v1/apps/{APP}/appInfos')
    info = next((i for i in j['data'] if i['attributes'].get('appStoreState') not in ('READY_FOR_SALE', 'REPLACED_WITH_NEW_INFO')), j['data'][0])
    iid = info['id']
    must('categories', call('PATCH', f'/v1/appInfos/{iid}', {'data': {'type': 'appInfos', 'id': iid, 'relationships': {
        'primaryCategory': {'data': {'type': 'appCategories', 'id': 'UTILITIES'}},
        'secondaryCategory': {'data': {'type': 'appCategories', 'id': 'REFERENCE'}}}}}))
    c, j = call('GET', f'/v1/appInfos/{iid}/appInfoLocalizations')
    il = next((x for x in j.get('data', []) if x['attributes']['locale'] == LOCALE), None)
    ia = {'name': 'AhhPuck', 'subtitle': SUBTITLE, 'privacyPolicyUrl': 'https://wheelhave.com/privacy'}
    if il:
        must('app info localization', call('PATCH', f"/v1/appInfoLocalizations/{il['id']}", {'data': {'type': 'appInfoLocalizations', 'id': il['id'], 'attributes': ia}}))
    else:
        must('app info localization', call('POST', '/v1/appInfoLocalizations', {'data': {'type': 'appInfoLocalizations', 'attributes': {**ia, 'locale': LOCALE}, 'relationships': {'appInfo': {'data': {'type': 'appInfos', 'id': iid}}}}}))
    c, j = call('GET', f'/v1/appInfos/{iid}/ageRatingDeclaration')
    if c == 200:
        ad = j['data']; attrs = {}
        for k, v in ad['attributes'].items():
            if k in ('kidsAgeBand', 'ageRatingOverride', 'ageRatingOverrideV2', 'koreaAgeRatingOverride', 'developerAgeRatingInfoUrl'):
                continue
            if isinstance(v, bool) or k in ('gambling', 'unrestrictedWebAccess', 'lootBox', 'messagingAndChat', 'parentalControls', 'ageAssurance', 'userGeneratedContent', 'advertising', 'healthOrWellnessTopics', 'seventeenPlus'):
                attrs[k] = False
            else:
                attrs[k] = 'NONE'
        must('age rating (all none/no)', call('PATCH', f"/v1/ageRatingDeclarations/{ad['id']}", {'data': {'type': 'ageRatingDeclarations', 'id': ad['id'], 'attributes': attrs}}))
    must('content rights', call('PATCH', f'/v1/apps/{APP}', {'data': {'type': 'apps', 'id': APP, 'attributes': {'contentRightsDeclaration': 'DOES_NOT_USE_THIRD_PARTY_CONTENT'}}}))

    # Review details (phone copied from the owner's existing review contact; never printed)
    phone = None
    c, wv = call('GET', '/v1/apps/6815223956/appStoreVersions?limit=1')
    if c == 200 and wv['data']:
        c2, d = call('GET', f"/v1/appStoreVersions/{wv['data'][0]['id']}/appStoreReviewDetail")
        if c2 == 200: phone = d['data']['attributes'].get('contactPhone')
    ra = {'contactFirstName': 'Justin', 'contactLastName': 'Lilburne', 'contactEmail': 'jlilburne@outlook.com.au',
          'demoAccountRequired': False, 'notes': REVIEW_NOTES}
    if phone: ra['contactPhone'] = phone
    c, j = call('GET', f'/v1/appStoreVersions/{vid}/appStoreReviewDetail')
    if c == 200 and j.get('data'):
        rid = j['data']['id']
        must('review details', call('PATCH', f'/v1/appStoreReviewDetails/{rid}', {'data': {'type': 'appStoreReviewDetails', 'id': rid, 'attributes': ra}}))
    else:
        must('review details', call('POST', '/v1/appStoreReviewDetails', {'data': {'type': 'appStoreReviewDetails', 'attributes': ra, 'relationships': {'appStoreVersion': {'data': {'type': 'appStoreVersions', 'id': vid}}}}}))

    # Screenshots (6.9": APP_IPHONE_67 takes 1320x2868), replacing any already there
    if shots_dir and loc:
        files = sorted(Path(shots_dir).glob('*.png'))
        c, j = call('GET', f"/v1/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets")
        sset = next((s for s in j.get('data', []) if s['attributes']['screenshotDisplayType'] == 'APP_IPHONE_67'), None)
        if not sset:
            sset = must('screenshot set', call('POST', '/v1/appScreenshotSets', {'data': {'type': 'appScreenshotSets', 'attributes': {'screenshotDisplayType': 'APP_IPHONE_67'}, 'relationships': {'appStoreVersionLocalization': {'data': {'type': 'appStoreVersionLocalizations', 'id': loc['id']}}}}}))['data']
        c, j = call('GET', f"/v1/appScreenshotSets/{sset['id']}/appScreenshots")
        for old in j.get('data', []):
            call('DELETE', f"/v1/appScreenshots/{old['id']}")
        for f in files:
            data = f.read_bytes()
            r = must(f'reserve {f.name}', call('POST', '/v1/appScreenshots', {'data': {'type': 'appScreenshots', 'attributes': {'fileName': f.name, 'fileSize': len(data)}, 'relationships': {'appScreenshotSet': {'data': {'type': 'appScreenshotSets', 'id': sset['id']}}}}}))
            if not r: continue
            sid = r['data']['id']
            for op in r['data']['attributes']['uploadOperations']:
                part = data[op['offset']:op['offset'] + op['length']]
                req = urllib.request.Request(op['url'], data=part, method=op['method'], headers={h['name']: h['value'] for h in op['requestHeaders']})
                urllib.request.urlopen(req).read()
            must(f'commit {f.name}', call('PATCH', f'/v1/appScreenshots/{sid}', {'data': {'type': 'appScreenshots', 'id': sid, 'attributes': {'uploaded': True, 'sourceFileChecksum': hashlib.md5(data).hexdigest()}}}))
        time.sleep(10)
        c, j = call('GET', f"/v1/appScreenshotSets/{sset['id']}/appScreenshots")
        print('screenshots:', [(s['attributes']['fileName'], s['attributes'].get('assetDeliveryState', {}).get('state')) for s in j.get('data', [])])

    c, j = call('GET', f'/v1/appStoreVersions/{vid}?include=build')
    print('version', VERSION, 'state:', j['data']['attributes'].get('appStoreState'), '| build attached:', bool(j['data']['relationships']['build'].get('data')))
    print('NOT submitted for review (by design).')


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
