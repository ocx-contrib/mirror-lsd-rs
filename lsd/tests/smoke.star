# lsd/tests/smoke.star — stable across upstream lsd releases.
# Asserts the contract (exit code, version shape, computed entry sets), never
# help/version prose. See ocx.mirror testing-practices.md.
#
# ⚠ lsd is a COLORIZED ls replacement, and SGR escapes land per token — a
# directory name comes back as "\e[38;5;4m\e[1msub\e[0m", so any multi-word
# plain substring assertion against its output is a false red waiting to
# happen. Every listing below therefore pins `--color never --icon never` and
# is compared as a parsed ENTRY SET, never as raw text. The one place colour
# is asserted (Tier 3c) compares `--color always` against that same plain
# baseline with `expect.ne`, which needs no knowledge of the escape codes.
#
# All flags used here were verified present and identically behaved on BOTH
# ends of the mirrored range — v1.1.3 (the floor) and v1.2.0 (latest).

LSD = "lsd.exe" if ocx.target_platform.os == ocx.os.Windows else "lsd"

# Tier 1 + 2: liveness on the composed PATH + version SHAPE (not the vendor
# banner, not the exact version — the digits are the contract).
r_version = ocx.run(LSD, "--version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")


def lines(s):
    # `\r` tolerates a Windows console translating the line endings.
    return [l for l in s.replace("\r", "").split("\n") if l != ""]


# Hermetic input: a four-entry tree written into the scratch root, so every
# expected set below is fully determined by this script and nothing else on
# the runner. `ocx.run`'s cwd IS the scratch root, so "tree" resolves here.
ocx.mkdir("tree/sub")
ocx.write_file("tree/alpha.txt", "a\n")
ocx.write_file("tree/bravo.txt", "b\n")
ocx.write_file("tree/gamma.log", "g\n")
ocx.write_file("tree/sub/nested.txt", "n\n")

# Tier 3a: the core contract — lsd lists exactly the directory's own entries,
# one per line, and does NOT recurse (nested.txt must be absent). Compared as
# a sorted SET so a future sort-order change is not a false red, but the COUNT
# is pinned: a truncated or wrong-arch archive that still managed to exec, or
# a listing that silently swallowed an entry, reds here.
r_plain = ocx.run(LSD, "--color", "never", "--icon", "never", "-1", "tree")
expect.ok(r_plain)
out_plain = lines(r_plain.stdout)
expect.eq(len(out_plain), 4)
expect.eq(sorted(out_plain), ["alpha.txt", "bravo.txt", "gamma.log", "sub"])

# Tier 3b: filtering really filters. `--ignore-glob '*.txt'` must drop exactly
# the two .txt entries and keep the other two. Assert the COUNT, never
# `expect.ok` alone — lsd exits 0 on an empty listing, so a filter that
# matched everything (or a glob engine that silently no-op'd and matched
# nothing) would sail past an exit-code check and is caught only here.
r_filtered = ocx.run(
    LSD, "--color", "never", "--icon", "never", "-1", "--ignore-glob", "*.txt", "tree",
)
expect.ok(r_filtered)
out_filtered = lines(r_filtered.stdout)
expect.eq(len(out_filtered), 2)
expect.eq(sorted(out_filtered), ["gamma.log", "sub"])

# Tier 3c: the colour engine is live — the whole point of this tool. Same
# listing, one flag value changed, so the delta can only be colour. Asserting
# `ne` against the plain baseline records that WITHOUT hard-coding an SGR
# sequence or a palette choice, either of which would red on an upstream
# theme tweak. The count is re-pinned because the escapes are inline: four
# entries in, four lines out.
r_color = ocx.run(LSD, "--color", "always", "--icon", "never", "-1", "tree")
expect.ok(r_color)
expect.eq(len(lines(r_color.stdout)), 4)
expect.ne(r_color.stdout, r_plain.stdout)

# Tier 3d: a missing path is a failure, not an empty listing. Recording it
# here is what stops a future edit from "fixing" the assertions above with a
# blanket `expect.ok` — the diagnostic goes to stderr and stdout stays empty.
r_missing = ocx.run(LSD, "--color", "never", "--icon", "never", "-1", "tree/nope")
expect.ne(r_missing.exit_code, 0)
expect.eq(len(lines(r_missing.stdout)), 0)

# No Tier 4: metadata.json declares PATH only (proven by Tier 1 liveness).
