# Anynix API

This Rails application exposes the public, read-only portion of the Anynix v1
registry API. Writes, manager authentication, and cryptographic verification
are intentionally not implemented until the Rust and Rails release/signature
formats are agreed.

## Public API

All responses are JSON except the blob endpoint, which redirects to the
Active Storage download URL. A release is public only when `published_at` is
set; package, release, and blob lookups exclude unpublished releases.

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/v1/packages?query=...` | Search public packages (up to 50 results) |
| `GET` | `/v1/packages/:name` | Read package metadata |
| `GET` | `/v1/packages/:name/releases/latest` | Read the most recently published release |
| `GET` | `/v1/packages/:name/releases/:version` | Read a public release |
| `GET` | `/v1/blobs/:blake3` | Redirect to a blob used by a public release |
| `GET` | `/v1/keys/:fingerprint` | Read public signing-key metadata |

Package and release metadata are returned under `data`. A release includes its
sources, targets, dependencies, file digests and install metadata, attestations,
and `metadata_signature`; the signature fields are opaque until the shared
cryptographic format is defined. The latest endpoint currently means the
release with the most recent `published_at` timestamp.

## Local development

The app requires PostgreSQL. Configure `DATABASE_URL` or update
`config/database.yml`, then run:

```sh
bin/rails db:prepare
bin/rails test
bin/rails server
```

Uploaded content is stored using the configured Active Storage service. For
local development, that is the local disk service.
