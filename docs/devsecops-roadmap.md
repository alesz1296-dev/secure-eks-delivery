# DevSecOps Security Roadmap

This roadmap turns the lab into an end-to-end security lifecycle project. Each control must be implemented, tested, and supported by retained evidence; installing a tool alone is not completion.

## Security lifecycle

```text
Threat model -> prevent -> detect before deployment -> detect at runtime
    -> respond -> remediate -> retain evidence
```

## Priority sequence

| Priority | Focus | Project implementation | Completion evidence |
| --- | --- | --- | --- |
| 1 | Identity and secrets | GitHub Actions OIDC role scoped to this repository and deployment environment; least-privilege IAM; Kubernetes RBAC | Trust policy review and successful short-lived credential workflow |
| 2 | CI/CD security | Minimal `GITHUB_TOKEN` permissions; SHA-pinned actions; protected deployment environment; Gitleaks, Checkov, SonarQube, Trivy | Blocked test finding, SonarQube quality-gate result, and saved workflow artifacts |
| 3 | Container and Kubernetes hardening | Non-root image, dropped capabilities, read-only root filesystem where compatible, seccomp, Pod Security Admission, NetworkPolicies | Rejected privileged workload and blocked unauthorized pod traffic |
| 4 | Vulnerability management | Finding triage, remediation deadlines, documented exceptions, rebuild and redeploy by digest | Before/after Trivy reports and deployed fixed digest |
| 5 | Cloud security and detection | CloudTrail, GuardDuty evaluation, EKS audit logs, security-group review, public-exposure checks | Simulated event investigation and containment notes |
| 6 | Application and supply chain | Authorization review, SBOM, dependency provenance, artifact traceability, optional signing | Traceable build artifact and documented authorization test |

## Pipeline hardening baseline

- Use GitHub OIDC rather than stored AWS access keys.
- Restrict the OIDC trust policy by repository, branch or tag, and deployment environment.
- Set workflow `permissions` explicitly and grant only the scopes each job needs.
- Pin third-party GitHub Actions to full commit SHAs.
- Do not expose deployment secrets or privileged runners to untrusted pull-request code.
- Require review for deployment-environment changes.
- Run Gitleaks, Checkov, application tests, SonarQube, and Trivy before an image can be published or deployed. For this portfolio lab, Trivy provides retained evidence and triage rather than a blocking vulnerability threshold; a production service must define and approve that threshold.

## Security-tool scope

| Tool | Purpose in this project | Does not replace |
| --- | --- | --- |
| Gitleaks | Detect committed secrets | Secret rotation and access control |
| Checkov | Find Terraform/IaC misconfigurations | Terraform plan review and architecture decisions |
| SonarQube | Analyze source-code bugs, security hotspots, code smells, and duplication; enforce a quality gate | Secret detection, dependency/image scanning, and architecture review |
| Trivy | Scan dependencies, images, and selected IaC | Runtime detection and risk triage |
| CodeQL or Semgrep | Find source-code security weaknesses | Application design review and tests |
| Kyverno | Enforce Kubernetes admission policies | Runtime behavior detection |
| Falco | Detect suspicious behavior at runtime | CVE scanning and automated remediation |

## Required demonstrations

1. **Prevent:** an unsafe Terraform, secret, or vulnerable-image change is blocked in CI.
2. **Detect:** a harmless Falco exercise produces an investigated alert.
3. **Respond:** document scope, containment action, and recovery decision for the exercise.
4. **Remediate:** fix a real or deliberately introduced safe finding, rebuild, rescan, and deploy the new immutable digest.

## Infrastructure dependency order

The private worker-node design requires an egress path before the node group can bootstrap reliably or pull images from ECR:

```text
Private node egress -> EKS node group -> application deployment
```

The first AWS baseline may use temporary unrestricted egress. The target design uses the selected NAT Gateway or VPC-endpoint combination and retains connectivity evidence.

## Six-week learning sequence

| Week | Outcome |
| --- | --- |
| 1 | OIDC, least-privilege IAM, secrets handling, and Linux permissions |
| 2 | Hardened GitHub Actions workflow with security scanners |
| 3 | Container hardening, Kubernetes security context, Pod Security Admission, and NetworkPolicies |
| 4 | Vulnerability triage, patching, remediation deadlines, and exceptions |
| 5 | Falco, EKS/audit logging, and a documented incident-response exercise |
| 6 | Integrated evidence for three before-and-after security scenarios |

## Finding-triage questions

For each vulnerability or misconfiguration, answer:

- Is the affected component actually present?
- Is the vulnerable functionality reachable or exposed?
- Is a fix available?
- What temporary mitigation is possible?
- Who owns remediation, and what is the deadline?

Do not treat scanner severity alone as the complete risk decision.
