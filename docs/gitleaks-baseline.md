# Gitleaks Baseline

## Current working-tree scan

Gitleaks was run against the current repository directory after generated
Trivy and Gitleaks reports were removed from the scan input and ignored as
local evidence artifacts.

```text
Command: gitleaks dir . --no-banner --redact
Result:  no leaks found
Scanned: approximately 711 KB
```

## Historical findings and cleanup

An earlier Git-history scan reported matches in generated Trivy JSON reports.
The generated reports were removed from repository history with `git
filter-repo`, and the rewritten `main` branch was pushed with an explicit
force-with-lease. The local backup branch
`backup-before-report-cleanup` preserves the pre-cleanup history if recovery is
needed.

The post-cleanup full-history scan completed successfully:

```text
Command: gitleaks detect --source . --no-banner --redact
Commits scanned: 15
Result: no leaks found
```

Generated scan reports remain ignored and should be retained through CI
artifacts rather than committed to the source repository. CI integration
remains pending until the pull-request workflow is validated.
