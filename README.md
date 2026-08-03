# mirror-lsd-rs

OCX mirror for [lsd](https://github.com/lsd-rs/lsd) (LSDeluxe), an `ls` command
with a lot of pretty colors. One repository, one spec directory per package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [lsd](https://github.com/lsd-rs/lsd) | [`lsd/mirror.yml`](lsd/mirror.yml) | `ghcr.io/ocx-contrib/lsd-rs/lsd` | [`ocx.sh/lsd-rs/lsd`](https://index.ocx.sh/lsd-rs/lsd) | `Apache-2.0` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(version, platform)` and only then pushed with cascade tags, after which the
result is announced into the OCX index.

> The namespace carries the `-rs` suffix and the package does not: `lsd-rs` is
> the project's own GitHub org, while the crate, the repo and the binary are
> all named `lsd`. Namespace is identity; provenance lives in the index claim's
> `upstream` block.

## Layout

```
mirror-base.yml         repo-wide policy every spec inherits via `extends:`
lsd/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
└── tests/smoke.star    Starlark smoke test
```

`LICENSE` and `NOTICE.md` are shared at the root. Logos are **not** — each
package carries its own, because a repo-root `logo.*` sits in no workflow's
`paths:` filter, so replacing it would publish nothing until some unrelated
edit happened to fire.

⚠️ `extends:` is a **shallow** merge of top-level keys. A spec that restates
`platforms:` to change one runner drops every `containers:` entry with it, and
nothing reds — the legs simply stop existing, and every `os.features` claim
goes back to being asserted rather than verified. Restate a block in full or
not at all.

## Platforms

`lsd` publishes **five** platform entries: both Linux arches, both macOS arches
and `windows/amd64`.

**There is no `windows/arm64`, and none is planned.** Upstream has never
shipped an aarch64 Windows asset — every in-range release (v1.1.3, v1.1.5,
v1.2.0) carries exactly `x86_64-pc-windows-msvc.zip` and
`i686-pc-windows-msvc.zip`, and i686 has no OCX platform key. Declaring the key
anyway would boot a `windows-11-arm` runner that resolves no asset and reports
success having tested nothing.

Windows uses the **msvc** variant deliberately. The `-pc-windows-gnu.zip`
siblings are new at v1.2.0 and absent at the v1.1.3 floor, so a gnu pattern
would resolve zero assets on two of the three in-range releases — silently
skipped, not an error. The declared patterns end `-msvc\.zip$` so the gnu
sibling can never match one.

Upstream ships **both** `-gnu` and `-musl` Linux assets for amd64 and arm64.
This mirror carries the **musl** ones, and both Linux keys are **bare** — no
`+libc.*` suffix. That is a measurement, not an inference: on v1.2.0 *and* on
the v1.1.3 floor, on x86-64 and aarch64 alike, the musl binaries have no
`PT_INTERP` and no `DT_NEEDED` — musl is linked *in*, not linked *against*. The
gnu binaries by contrast name `/lib64/ld-linux-x86-64.so.2` and need
`libc.so.6`, `libgcc_s.so.1`, `librt.so.1` and `libpthread.so.0`, so they would
require `+libc.glibc`. `os.features` states what an artifact requires *of the
host*, and a static binary requires nothing — tagging it `+libc.musl` would be
a false requirement that hid the package from every glibc host it in fact runs
on. The second, gnu-keyed platform is not carried because lsd only ever touches
the local filesystem: the usual reason to ship one (musl's resolver ignores
`nsswitch.conf`) does not apply. The `alpine:3.20` container leg in
`mirror-base.yml` is what turns the universality claim into evidence; the
measurement itself is recorded above the `assets:` block in `lsd/mirror.yml`.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror-base.yml`, `lsd/mirror.yml` | hand | yes — see below |
| `lsd/{metadata.json,CATALOG.md,logo.*}` | hand | — |
| `lsd/tests/smoke.star` | hand | — |
| `.github/workflows/*.yml` | **generated — never hand-edit** | re-run when a spec changes |

```bash
ocx-mirror package pipeline generate ci --spec lsd/mirror.yml
```

**Name every spec.** `--spec` *appends* rather than replaces, so a command
naming a subset silently stops rendering the rest while staying green — and the
drift guard reds on a generated workflow the current spec set no longer
produces.

`verify-generated.yml` exits 65 on drift. If a generated workflow is wrong, the
spec or the renderer template is wrong — fix it there and regenerate.

Run `direnv allow` once to put the pinned toolchain on `PATH`, and invoke
`ocx-mirror` directly — never `ocx run -- ocx-mirror`, which pins
`OCX_BINARY_PIN` to the bootstrap `ocx` and false-reds the nested push.

## The binaries claim

`lsd/metadata.json` declares `binaries: ["lsd"]` by hand, and `lsd/mirror.yml`
sets `bin_scan: "off"` — forced, not preferred. Every upstream archive wraps
its payload in one directory named after the asset itself
(`lsd-v1.2.0-x86_64-unknown-linux-musl/`), whose name embeds both the version
and the target triple and so cannot be named in a static PATH. `strip_components: 1`
removes it, which lands `lsd` at the content root with no subdirectory left for
the scan to inspect — and with nothing to inspect, `auto` and `verify` both
fail spec load at exit 65 rather than offer a hollow check. The hand-written
list is what the error message itself directs, and it is short and stable: the
binary is the only mode-0755 entry, while `LICENSE`, `README.md`, the `lsd.1`
man page and everything under `autocomplete/` are 0644 data.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from the `ocx-contrib/index` fork |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL. GHCR pushes use the
run's own `GITHUB_TOKEN` — no registry secret needed.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of scope; each
package's redistribution license is recorded in [`NOTICE.md`](NOTICE.md).
