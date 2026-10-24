# CI Tooling Manual Baseline

These checks were run locally before enabling the GitHub Actions workflows.

## TFLint

```text
Command: tflint --init
Result:  plugins already installed

Command: tflint --chdir=infra
Result:  no findings
```

## actionlint

```text
Version: 1.7.12
Files:   .github/workflows/pr-validation.yml
         .github/workflows/terraform-deploy.yml
         .github/workflows/container-delivery.yml
Result:  no findings
```

These results establish that the Terraform configuration passes the local
TFLint baseline and the current workflow YAML passes actionlint. They do not
yet prove that GitHub Actions can authenticate to AWS, execute a remote plan,
or perform an approved apply.
