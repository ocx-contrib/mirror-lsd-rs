# NOTICE

This repository packages and redistributes upstream software published by the
[lsd](https://github.com/lsd-rs/lsd) project. The Apache-2.0 license in
[`LICENSE`](LICENSE) covers the OCX pipeline files authored here. It does
**not** cover any upstream-derived asset — each package's redistributed bytes
carry their own license, recorded below.

Each package's logo is reproduced for catalog identification only, under
nominative fair use. The marks remain the property of their respective owners
and no endorsement is implied.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `lsd` | `ghcr.io/ocx-contrib/lsd-rs/lsd` | `Apache-2.0` |

---

## `lsd`

Upstream: <https://github.com/lsd-rs/lsd>
Published to `ghcr.io/ocx-contrib/lsd-rs/lsd`.

| Component | SPDX | Holder |
|---|---|---|
| lsd (`lsd`) | **Apache-2.0** | Peltoche \<dev@halium.fr\> and the lsd contributors |

Apache License 2.0 grants redistribution of the binary form (§4) on condition
that recipients receive a copy of the license, that existing copyright, patent,
trademark and attribution notices are retained, and that modified files are
marked as changed. All three conditions are met without further action here:
the mirrored archives each ship upstream's own `LICENSE` file at their root,
republished unmodified, and nothing in any archive is altered. The published
binaries statically link third-party Rust crates under permissive licenses,
enumerated in upstream's `Cargo.lock`.

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle.
