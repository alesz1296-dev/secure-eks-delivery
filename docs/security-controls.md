# Security Controls: Trivy and Falco

## Purpose

This project demonstrates two complementary security practices:

1. **Prevent vulnerable software from reaching EKS** with Trivy image scanning.
2. **Detect suspicious behavior after deployment** with Falco runtime monitoring.

Neither tool replaces the other.

| Control | Tool | When it operates | Primary question answered |
| --- | --- | --- | --- |
| Image and dependency scanning | Trivy | Before image publication and deployment | Does this image contain known vulnerabilities? |
| Runtime behavior monitoring | Falco | While containers run on EKS nodes | Is this workload behaving suspiciously? |

## Trivy: build and delivery security gate

### Planned workflow

```text
Source change
  -> application tests
  -> container image build
  -> Trivy image scan
  -> fail or pass security gate
  -> publish immutable image digest to ECR
  -> deploy that exact digest to EKS
```

### Initial policy

- Scan the built container image in GitHub Actions.
- Preserve a report of all findings as a workflow artifact.
- Fail the pipeline for **fixable HIGH and CRITICAL** vulnerabilities.
- Review findings without an available fix; record any temporary exception with owner, rationale, expiry date, and remediation plan.
- Never deploy an image merely because it has a convenient mutable tag.

### Remediation practice

| Finding location | Expected response |
| --- | --- |
| Python application dependency | Update dependency and lockfile, test, rebuild, and rescan. |
| Python base image or OS package | Update the pinned base-image digest or package source, rebuild, and rescan. |
| EKS worker-node operating system | Update managed-node AMI and roll nodes safely. |

### Evidence to keep

- Failing Trivy scan report.
- Commit or pull request showing the remediation.
- Passing scan report after the remediation.
- ECR image digest and deployment evidence proving the passing image was deployed.

## Falco: runtime detection

### Planned deployment

- Install Falco through Helm after the base application deployment is stable.
- Use EC2-backed EKS managed nodes so Falco can observe relevant host/container activity.
- Start with Falco logs as the alert destination; do not add automated remediation in the first iteration.

### Controlled detection exercises

Run exercises only in the isolated lab cluster and restore the baseline afterward.

| Exercise | Expected signal | Investigation questions |
| --- | --- | --- |
| Open a shell in a designated test container | Shell activity alert, where an appropriate rule is enabled | Which user, pod, container, process, and command triggered it? |
| Write below `/etc` in a designated test container | Sensitive file-write alert, where an appropriate rule is enabled | Was the activity expected, and did the workload security context allow too much access? |
| Unexpected package-management or network utility activity | Process/behavior alert, depending on active rules | Does the container image contain unnecessary tools or capabilities? |

### Falco response workflow

```text
Falco event
  -> capture rule, timestamp, pod, container, node, process, and command
  -> determine whether the activity was authorized test activity or unexpected
  -> contain the workload if needed
  -> remediate the image, manifest, RBAC, or node configuration
  -> deploy the corrected version and record the outcome
```

## Security boundaries and limitations

- Trivy identifies known vulnerabilities; it does not prove that an image is safe from exploitation.
- Falco detects configured behavioral patterns; it does not detect every malicious action.
- Findings must be interpreted in context and documented with evidence.
- The initial lab does not implement automated blocking, SIEM integration, or production incident response.

## Completion criteria

The security portion of the portfolio is complete only after demonstrating both:

1. **Vulnerability remediation:** failing Trivy result -> fix -> passing result -> successful deployment by digest.
2. **Runtime detection:** controlled suspicious activity -> Falco alert -> documented investigation and mitigation.

