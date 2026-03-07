---
name: android-gradle
description: Expert guidance on Android Gradle build systems — convention plugins, version catalogs, build performance optimization, CI/CD caching, and build scan analysis. Use when setting up build logic, configuring convention plugins, debugging slow builds, analyzing build scans, optimizing CI/CD pipelines, enabling configuration cache, migrating kapt to KSP, or troubleshooting compilation and cache issues in Android/Gradle projects.
---

# Android Gradle

Comprehensive guidance for structuring and optimizing Android Gradle builds. This skill covers two complementary areas — pick the one that matches your task.

## Routing

### Build Structure & Convention Plugins

Read [references/conventions.md](references/conventions.md) when the task involves:

- Setting up or refactoring `build-logic/` with convention plugins
- Configuring `settings.gradle.kts` for composite builds
- Creating or managing a `libs.versions.toml` version catalog
- Reducing duplication across module-level `build.gradle.kts` files
- Following the "Now in Android" (NiA) build architecture

### Build Performance & Optimization

Read [references/performance.md](references/performance.md) when the task involves:

- Slow build times (clean or incremental)
- Generating or analyzing Gradle Build Scans
- Identifying configuration vs. execution bottlenecks
- Enabling configuration cache, build cache, or parallel execution
- Migrating kapt to KSP
- Optimizing CI/CD build pipelines
- Debugging cache misses or unnecessary recompilation

## Cross-Cutting Principles

These apply regardless of which reference you're working from:

**Pin dependency versions.** Never use dynamic versions (`+` or `1.0.+`) — they force resolution on every build and break reproducibility.

**Prefer KSP over kapt.** KSP is ~2x faster for Kotlin annotation processing. Migrate when your annotation processors support it (Hilt, Room, Moshi all do).

**Use `tasks.register()`, not `tasks.create()`.** Lazy task configuration avoids unnecessary work during the configuration phase.

**Defer I/O to execution time.** Don't read files or make network calls in `build.gradle.kts` — use `providers.fileContents()` or similar lazy APIs.

**Standardize the JDK.** Mismatched JDK versions between local and CI cause cache misses. Pin the JDK in your project and CI configuration.

## References

- [Optimize Build Speed (Android Developers)](https://developer.android.com/build/optimize-your-build)
- [Gradle Configuration Cache](https://docs.gradle.org/current/userguide/configuration_cache.html)
- [Gradle Build Cache](https://docs.gradle.org/current/userguide/build_cache.html)
- [Migrate from kapt to KSP](https://developer.android.com/build/migrate-to-ksp)
