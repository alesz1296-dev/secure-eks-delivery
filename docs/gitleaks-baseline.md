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

## Historical findings

The earlier Git-history scan reported matches in generated Trivy JSON reports
and a generated `gitleaks.sarif` file. These findings were not in application,
Terraform, or Kubernetes source files. The generated reports are excluded from
future commits and scans; historical matches remain repository-history hygiene
items and are not treated as confirmed credentials.

The manual baseline is complete. CI integration remains pending until the
pull-request workflow is validated and its report-retention behavior is tested.
