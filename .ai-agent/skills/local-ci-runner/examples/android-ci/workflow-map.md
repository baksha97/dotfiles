# Workflow Map

This map keeps local commands aligned to repository-root workflows.

## Source workflows

1. `<repository-root>/.github/workflows/pr-android.yml`
2. `<repository-root>/.github/workflows/Android-Integrity.yml`
3. `<repository-root>/.github/workflows/Android-MiLB-Integrity.yml`
4. `<repository-root>/.github/workflows/android-milb-fastlane-build-workflow.yml`

## Trigger groups from `pr-android.yml`

- `android-mobile`: Android mobile app changes (`Android/MLBAppMobile/**`) plus workflow/action infra paths.
- `android-tv`: Android TV app changes (`Android/MLBAndroidTV/**`) plus workflow/action infra paths.
- `android-library`: Android shared libs and root Android build files.
- `xplat-library`: xplat modules used by Android (`xplat/MLBObservabilityKit`, `xplat/MLBAuthKit`, `xplat/MLBDeepLinkSchema`, `xplat/Gradle/gradle/libs.versions.toml`).

## Derived checks from `Android-Integrity.yml`

- `check-spotless`: always enabled when Android Integrity runs.
- `check-xplat`: enabled when `xplat-library` changed.
- `check-libraries`: enabled when `android-library` changed.
- `check-mobile`: enabled when any of `android-library`, `xplat-library`, or `android-mobile` changed.
- `check-tv`: enabled when any of `android-library`, `xplat-library`, or `android-tv` changed.
- `check-ui`: enabled when `android-library` changed.

## Local command parity

All Gradle commands use flags:

```bash
--console=plain -DtestIncludePatterns="mlb.atbat.suite.*,mlb.atbat.suites.*"
```

### Spotless (local equivalent)

- Workflow job: `suggest-spotless`
- CI behavior: runs `spotlessApply` then suggests diff on PR.
- Local default: `./gradlew spotlessCheck`
- Local fix mode: `./gradlew spotlessApply`

### Xplat integrity (`check-xplat`)

1. `xplat/MLBObservabilityKit/jvm`: `./gradlew assemble test`
2. `xplat/MLBObservabilityKit/jvm/compiler`: `./gradlew assemble test`
3. `xplat/MLBObservabilityKit/android`: `./gradlew assemble test`
4. `xplat/MLBAuthKit/jvm`: `./gradlew assemble test`
5. `xplat/MLBAuthKit/android`: `./gradlew assemble test`
6. `xplat/MLBDeepLinkSchema/jvm`: `./gradlew assemble test`

### Library integrity (`check-libraries`)

1. `Android/MAASDK`: `./gradlew assemble testDebugUnitTest testAmazonDebugUnitTest testGoogleDebugUnitTest`
2. `Android/MLBAndroidPlatform`: `./gradlew assemble testDebug`
3. `Android/Onboarding`: `./gradlew -x app:assembleRelease assemble testDebug`
4. `Android/FieldPass`: `./gradlew -x app:assembleRelease assemble testDebug`
5. `Android/Bullpen`: `./gradlew -x app:assembleRelease assemble testDebug`
6. `Android/SurfaceBuilder`: `./gradlew -x app:assembleRelease assemble testDebug`
7. `Android/MLBTVWatch`: `./gradlew -x app:assembleRelease assemble testDebug`
8. `Android/MLBUIDataModels`: `./gradlew assemble testDebug`
9. `Android/DesignTokens`: `./gradlew assemble testDebug`
10. `Android/MLBUIComponents`: `./gradlew -x app:assembleRelease assemble testDebug`

### Mobile integrity (`check-mobile`)

- `Android/MLBAppMobile`: `./gradlew assemble testDebugUnitTest`

### TV integrity (`check-tv`)

- `Android/MLBAndroidTV`: `./gradlew assemble testDebugUnitTest`

### UI integrity (`check-ui`)

1. `Android/MLBUIComponents`: `./gradlew verifyPaparazziDebug`
2. `Android/SurfaceBuilder`: `./gradlew verifyPaparazziDebug`
3. `Android/MLBAndroidTV`: `./gradlew :tvUIComponents:verifyPaparazziDebug`
4. `Android/MLBAndroidTV`: `./gradlew :app:assembleAndroidTest`
5. `Android/MLBAppMobile`: `./gradlew :app:assembleAndroidTest`

### MiLB integrity (`Android-MiLB-Integrity.yml`)

- Workflow trigger paths include `Android/MiLB-App/**` and `MiLB/milb-midfield-kmp/**`.
- CI delegates to reusable workflow `android-milb-fastlane-build-workflow.yml` with lane `PR`.
- Local full equivalent (requires Ruby/Bundler + Firebase credentials in env):

```bash
bundle exec fastlane PR --verbose
```

- Local fallback when Firebase credentials / bundler are unavailable:

```bash
./gradlew build --console=plain '-DtestIncludePatterns=mlb.atbat.suite.*,mlb.atbat.suites.*'
```

The script auto-detects which to use: if `bundle` is on `$PATH` **and** `FIRST_PITCH_FIREBASE_CREDENTIALS_STAGING` or `FIRST_PITCH_FIREBASE_CREDENTIALS_PROD` is set, fastlane is used; otherwise the Gradle build runs instead.

## Known parity caveats

- GitHub Actions uses CI secrets, runner images, and setup actions not always present locally.
- MiLB fastlane lane may require Firebase credentials and other env vars from CI.
- Local failures are still useful for fast feedback, but passing locally is not a strict guarantee that hosted CI will pass.

## Known local environment behaviors (handled automatically)

### `CI` env var set by IDEs

Cursor and some other tools set `CI=1` in the shell environment. The monorepo's `build-cache.settings.gradle.kts` validates that `BUILD_CACHE_NODE_USERNAME` is set whenever `CI` is present — which fails immediately when credentials are absent locally. The script unsets `CI` before any Gradle invocation so the remote build cache path is never activated.

### Git worktrees and Spotless

When the repo is checked out as a git worktree, the `.git` entry at the repo root is a **file** (a pointer to the main `.git` directory), not a directory. Spotless's `ratchetFrom` feature uses JGit internally, and JGit does not follow the worktree indirection file — it fails with `Cannot find git repository in any parent directory` during Gradle configuration.

The script detects this automatically at startup (`[[ -f "$REPO_ROOT/.git" ]]`) and sets `--skip-spotless` with an explanatory warning. To run spotless, use a standard `git clone` instead of a worktree.
