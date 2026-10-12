# Changelog

## [Unreleased]

## [0.23.0] - 2026-10-12

### Added

- Flow runs take a random code from the public_code gem. In an app that has run the `AddPublicCodeToEasyFlowRuns` migration, every run address carries the run's code, runs are found by it, and a numbered run address is not found.
- An app that has not run that migration keeps addressing and finding runs by id exactly as before.

### Upgrading

To switch an app's runs to codes, copy and run the new migration, then restart the app:

```
bin/rails easy_flow:install:migrations
bin/rails db:migrate
```

A host that overrides `run_address` and `find_run` keeps the addresses it builds.
