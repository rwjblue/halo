# Recorder dependencies

The KX3 panadapter needs native validation of the selected stereo input and
sample rate. The published recorder backends do not provide all of those
guarantees. HaLo keeps the required patches and authored capture sources here;
upstream package sources are downloaded during build preparation and stay out
of Git. Installed applications never download source code.

`UPSTREAM.json` pins each pub.dev archive by version and SHA-256, lists the
patch and authored overlay, and records the hash of every resulting source
file. The preparation tool verifies the archive, applies the patch, adds the
overlay, and verifies the complete source inventory before publishing each
generated package under `packages/record_*_patched/`. Source text is normalized
to LF so Windows and Unix hosts produce the same tree. Upstream MIT licenses
remain in the generated packages; authored sources retain their MPL-2.0 headers.

## Preparing a checkout

Normal setup, run, deployment, and test tasks prepare these packages before
resolving the app. To prepare them directly:

```sh
mise run prepare-record
```

The equivalent command works from a shell with the Flutter SDK's `dart` on
PATH, including PowerShell:

```sh
cd packages/halo_build_tools
dart run bin/prepare_record.dart
```

Run preparation once before using an IDE or plain `flutter pub get`,
`flutter run`, or `flutter build` from a fresh checkout. Flutter reads path
dependencies during package resolution, before native build hooks run; a hook
inside a missing recorder package cannot install that package. Preparing all
five packages is necessary even for web builds, although browser capture does
not use their native implementations.

Verified archives are cached outside the checkout. `HALO_RECORD_CACHE` selects
an explicit cache directory. Each checkout gets its own generated package
copies so native build tools cannot modify another checkout's sources. Valid
source trees are reused without discarding build outputs. Missing or modified
generated sources are reconstructed from the pinned inputs.

For an offline build, first resolve `halo_build_tools` dependencies and run
`dart run bin/prepare_record.dart --prefetch` while online. Later,
`dart run bin/prepare_record.dart --offline` prepares from the verified archive
cache without downloading recorder sources. Normal Flutter dependency and
engine caches are still required for an entirely offline build.

## Updating a backend

1. Select the new published version and verify its archive SHA-256.
2. Review the upstream changes against the package-specific notes below.
3. Update the focused patch and authored overlay, then the expected source
   hashes in `UPSTREAM.json`. Do not edit generated packages as the final fix.
4. Prepare from a cold cache, run `./scripts/test.sh`, and verify the affected
   native build and stereo hardware capture. Remove a patch when upstream
   provides the same capture guarantees.

The five package notes describe the maintained changes and hardware limits:
[Android](record_android.md), [iOS](record_ios.md),
[Linux](record_linux.md), [macOS](record_macos.md),
and [Windows](record_windows.md).

Private release and code-push tooling must run preparation before its first
app dependency resolution and treat changes under `dependencies/record/` as
native dependency changes requiring a rebuilt application.
