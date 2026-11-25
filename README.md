# Anynix API

This Rails application exposes the public read-only portion of the Anynix v1
registry API and an authenticated candidate blob upload. Release publication
and signature verification are not implemented.

The proposed shared signed-release and publication contract is documented in
[RELEASE_CONTRACT.md](RELEASE_CONTRACT.md); it is not implemented or finalized.

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
| `POST` | `/v1/blobs` | Upload a verified, non-public candidate blob |

Package and release metadata are returned under `data`. A release includes its
sources, targets, dependencies, file digests and install metadata, attestations,
and `metadata_signature`; the signature fields are opaque until the shared
cryptographic format is defined. The latest endpoint currently means the
release with the most recent `published_at` timestamp.

## Candidate blob uploads

Set `ANYNIX_MANAGER_TOKEN` to a strong secret on the server and send it as
`Authorization: Bearer <token>` over HTTPS. Upload a multipart form with
`file`, `digest` (lowercase BLAKE3 hex), and `size` (decimal bytes). Files are
limited to 256 MiB; configure the reverse proxy to limit request sizes too.
The response contains the verified digest and size under `data`. Existing
digests return 409, mismatched content returns 422, and an unset token disables
uploads. Candidates are not downloadable through the public blob API until
referenced by a published release. This endpoint does not publish releases.

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
