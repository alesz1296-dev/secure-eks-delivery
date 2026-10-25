# Pre-commit baseline

The repository uses `.pre-commit-config.yaml` to run fast checks before a
commit is created:

- whitespace, YAML, JSON, and merge-conflict checks;
- Terraform formatting;
- TFLint;
- Checkov Terraform scanning;
- Gitleaks working-tree scanning; and
- actionlint for GitHub Actions workflows.

The hooks are local-system hooks, so contributors must install the tools and
ensure they are available on `PATH`. Image builds, Trivy scans, SBOM generation,
tests, and Terraform plan/apply remain CI responsibilities.
