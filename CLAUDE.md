# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A collection of deployment templates for [Conure](https://conure.io), packaged as
**OCI artifacts** and published to `ghcr.io/coffeenights/conure-templates` in two
flavours that template the *same kinds of resources* two different ways:

- **Helm charts** (`helm/components/<name>/`) — standard `helm package` + `helm push`.
- **Timoni modules** (`timoni/components/<name>/`) — CUE-based, pushed with `timoni mod push`.

Only `webservice` (both flavours) and `helm/components/stackgres` are maintained.
Other `timoni/components/*` folders are experiments not wired into release tooling
(despite what older README text may imply).

## Release workflow (the core of this repo)

All build/push logic lives in `scripts/oci-release.sh`; the `Makefile` is a thin
wrapper. Helm vs Timoni is auto-detected from the target folder (`Chart.yaml` →
Helm, `cue.mod/` → Timoni).

```sh
make push DIR=helm/components/stackgres            # push the CURRENT VERSION as-is
make push DIR=helm/components/stackgres BUMP=patch # patch|minor|major bump, then push
make push DIR=timoni/components/webservice VERSION=1.2.3  # pin exact version, then push
make push DIR=... DRY_RUN=1                         # preview, change/push nothing
make bump DIR=...                                   # bump VERSION file only (defaults to patch)
make version DIR=...                                # print current version
```

Key behavioral contract (changed deliberately — preserve it):

- **`push` does NOT bump by default.** It publishes the current `VERSION` as-is.
  It only changes the version when `BUMP` or `VERSION` is explicitly set.
- The standalone **`bump`** command still defaults to a patch bump (via the
  Makefile's separate `BUMPENV`). Don't collapse `BUMPENV` back into `RUNENV`.
- The per-component **`VERSION` file is the single source of truth.** For Helm
  components, `Chart.yaml`'s `version` and `appVersion` are rewritten from it on
  every push (via `perl -0pi`). Never hand-edit those two fields to differ from
  `VERSION`.
- `push` does not git-commit or tag the bumped `VERSION` — commit it yourself
  after a successful release.

In this sandbox shell `make` is a zsh autoload stub, not a real binary — if
`make` fails with "function definition file not found", invoke the script
directly: `./scripts/oci-release.sh push helm/components/stackgres`.

## Validating charts before pushing

```sh
helm lint ./helm/components/<name>
helm template <release> ./helm/components/<name> --namespace <ns> -f /tmp/values.yaml
```

There is no Go/unit test harness in the tree. `_tests` is gitignored (an
out-of-tree Go harness loads/unifies the Timoni CUE modules from the OCI
registry; it is not part of this repo's working set).

## Helm chart architecture

Both Helm charts follow an identical convention — match it when adding charts:

- `templates/_helpers.tpl` defines `<chart>.name` (defaults to `.Release.Name`,
  overridable via `.Values.nameOverride`), `<chart>.labels` (merges
  `.Values.labels` over the reserved `app.kubernetes.io/*` set — name/version
  cannot be overridden), and chart-specific name helpers.
- Optional spec fields are **omitted from output when empty** (via `with`/`if`),
  not rendered as empty/null. This is a deliberate pattern — keep it.
- `values.yaml` is intentionally a flat, minimal surface. These charts favour
  few knobs over completeness; do not add features speculatively.

`stackgres` renders four StackGres CRs from one release (SGCluster +
SGInstanceProfile + SGPostgresConfig, plus an SGScript that is only emitted when
`init.scripts` is non-empty — and the cluster's `managedSql` block is gated on
the same condition). It does not create a dedicated app user/Secret; consumers
connect via the StackGres-generated superuser Secret (named after the release).

## Timoni module architecture

`timoni/components/webservice/` is a CUE module:

- `timoni.cue` is the entrypoint: `values: templates.#Config` is the user
  schema; Timoni injects `name`/`namespace`/`moduleVersion`/`kubeVersion` via
  `@tag(...)` at apply time.
- `templates/*.cue` define `#Config` and the per-resource templates; the
  `#Instance` aggregates `objects` which `apply` flattens.
- `cue.mod/gen/` is generated CUE from Go types (k8s + the Conure
  `apis/core/v1alpha1`); `deps.go`/`go.mod` exist only to pin the Go module that
  `cue get go` generates from. Treat `cue.mod/gen/` as generated — don't hand-edit.
- `cue.mod/module.cue` must declare transitive deps and (for publishing)
  `source: { kind: "self" }`. `timoni.ignore` excludes Go/VCS/debug files from
  the pushed artifact.

## Conventions

- Keep the Helm and Timoni `webservice` schemas in parity — the values surface
  of one mirrors the other (see each component's README for the mapping).
- New components: create both the chart files and a `VERSION` file; the README's
  layout/published-artifacts tables are not auto-generated, so update them when
  adding a maintained component.
