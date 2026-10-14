# Security policy

## Scope

The app is local-first and read-only. It stores capture sessions locally and does not require an AhhPuck API key, backend secret, cloud database credential or ECU write credential. App Store Connect credentials are release-operator secrets and must never be committed.

## Never commit

- App Store Connect API private keys, issuer credentials, app-specific passwords or signing certificates.
- `.env` files, tokens, passwords, session cookies, provisioning profiles or private vehicle/customer data.
- ECU dumps or captures containing personally identifying information unless explicitly sanitised and approved.
- Private signing material or generated TestFlight archives/exports.

The public-looking `public_api_key` found in a downloaded provider HTML page is a browser-facing third-party research value, not an AhhPuck credential. It must not be copied into the app or treated as permission to use that service.

## Reporting

Do not open a public issue for an exposed credential or private capture. Contact the repository owner privately, revoke/rotate the credential first, then provide the affected path, commit and remediation details. Do not paste secret values into issues, pull requests or chat.

## Release security gates

Before publishing a release:

1. Run `python3 tools/public_release_check.py`.
2. Review `git ls-files` for private archives, profiles and captures.
3. Confirm no secrets are present in tracked text or app resources.
4. Confirm the app contains no write command path.
5. Confirm App Store Connect credentials are supplied only through local tooling/keychain/API-key flags.
6. Run unit tests and inspect the final IPA contents.
