# conure-templates

A collection of templates used for deploying and running workflows in
[Conure](https://conure.io). Components are packaged as **OCI artifacts** and
published to `ghcr.io/coffeenights/conure-templates` in two flavours:

- **Helm charts** — standard `helm package` + `helm push`
- **Timoni modules** — CUE-based, pushed with `timoni mod push`

## Repository layout

```
.
├── Makefile                       # build & push entrypoint
├── scripts/oci-release.sh         # all release logic (runnable standalone)
├── helm/
│   └── components/
│       └── webservice/            # Helm chart  (Chart.yaml, templates/, values.yaml)
└── timoni/
    └── components/
        ├── webservice/            # Timoni module (cue.mod/, templates/, values.cue)
        ├── service/               # experiment — not maintained
        ├── service-flat/          # experiment — not maintained
        └── cron/                  # experiment — not maintained
```

> **Only `webservice` is functional** (both the Helm chart and the Timoni
> module). The other `timoni/components/*` folders were experiments and are not
> wired into the release tooling.

## Prerequisites

- `bash`, `perl`, `awk` (preinstalled on macOS/Linux)
- [`helm`](https://helm.sh) — for the Helm chart
- [`timoni`](https://timoni.sh) — for the Timoni module
- Authentication to the GHCR registry (`helm registry login ghcr.io`,
  `timoni registry login ghcr.io`, or a `GITHUB_TOKEN`/`docker login`)

Any GNU Make version works (the logic lives in `scripts/oci-release.sh`, so
macOS's bundled Make 3.81 is fine).

## Versioning

Each component owns a `VERSION` file (e.g.
`timoni/components/webservice/VERSION`) which is the **single source of truth**
for that component's version. The tooling reads it, bumps it, writes it back,
and publishes that version.

For Helm components, `Chart.yaml`'s `version` and `appVersion` fields are kept
in sync with the `VERSION` file automatically on every push.

## Usage

Pass the component folder via `DIR=`. Helm vs Timoni is auto-detected
(`Chart.yaml` → Helm, `cue.mod/` → Timoni).

```sh
# Patch bump (default) + build + push
make push DIR=timoni/components/webservice
make push DIR=helm/components/webservice

# Minor / major bump
make push DIR=helm/components/webservice BUMP=minor
make push DIR=timoni/components/webservice BUMP=major

# Pin an exact version instead of bumping
make push DIR=timoni/components/webservice VERSION=1.2.3

# Preview everything without changing files or pushing
make push DIR=helm/components/webservice DRY_RUN=1

# Bump the VERSION file only (no build, no push)
make bump DIR=timoni/components/webservice

# Print the current version
make version DIR=helm/components/webservice
```

| Option     | Values                 | Default                                    |
|------------|------------------------|--------------------------------------------|
| `DIR`      | component folder       | *(required)*                               |
| `BUMP`     | `patch`/`minor`/`major`| `patch`                                    |
| `VERSION`  | `x.y.z`                | *(unset — bump instead)*                   |
| `DRY_RUN`  | `1`                    | *(unset — perform the push)*               |
| `REGISTRY` | OCI base               | `ghcr.io/coffeenights/conure-templates`    |

The script can also be invoked directly without Make:

```sh
./scripts/oci-release.sh push timoni/components/webservice
./scripts/oci-release.sh version helm/components/webservice
```

## Published artifacts

| Component | Source folder                  | OCI reference                                                          |
|-----------|--------------------------------|------------------------------------------------------------------------|
| Helm      | `helm/components/webservice`   | `oci://ghcr.io/coffeenights/conure-templates/helm/components/webservice:<ver>` |
| Timoni    | `timoni/components/webservice` | `oci://ghcr.io/coffeenights/conure-templates/components/webservice:<ver>`       |

Under the hood the Timoni push runs:

```sh
timoni mod push ./ oci://ghcr.io/coffeenights/conure-templates/components/webservice --version <ver>
```

> **Note:** `push` does not `git commit` or tag the bumped `VERSION` file —
> commit it yourself after a successful release.
