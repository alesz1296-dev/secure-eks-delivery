# Security Controls: Delivery and Runtime

## Purpose

This project uses layered security controls. Trivy and Falco remain the first two runtime-delivery controls, while GitHub OIDC, Gitleaks, Checkov, SonarQube, CodeQL or Semgrep, Kyverno, Kubernetes RBAC, and NetworkPolicies are introduced in staged iterations described in the [DevSecOps Security Roadmap](devsecops-roadmap.md).

SonarQube is the planned source-code quality and static-analysis control for
pull requests. It complements Gitleaks, Checkov, and Trivy: SonarQube evaluates
code quality, bugs, security hotspots, and duplication, but does not replace
secret, IaC, dependency, or container scanning. The initial SonarQube trial is
manual; CI enforcement begins only after the local project and quality gate are
verified.

This document demonstrates two complementary security practices:

1. **Prevent vulnerable software from reaching EKS** with Trivy image scanning.
2. **Detect suspicious behavior after deployment** with Falco runtime monitoring.

Neither tool replaces the other.

## Kubernetes RBAC baseline: no API access by default

The FastAPI workload uses a dedicated `secure-eks-delivery` ServiceAccount, but
it does not need to call the Kubernetes API. The baseline therefore grants no
application Role or RoleBinding and disables token mounting at both the
ServiceAccount and pod levels:

```yaml
automountServiceAccountToken: false
```

This was verified in the local cluster with the following evidence:

| Check | Result |
| --- | --- |
| ServiceAccount token inside the running pod | `token-absent` |
| `kubectl auth can-i get pods` | `no` |
| `kubectl auth can-i list nodes` | `no` |
| `kubectl auth can-i get secrets` | Not granted by the workload identity |
| `kubectl auth can-i update deployments` | Not granted by the workload identity |

`kubectl auth can-i --list` still reports Kubernetes' limited built-in
discovery and self-review permissions, such as API discovery endpoints and
`selfsubjectreviews`. These do not grant access to pods, Secrets, ConfigMaps,
Deployments, Services, Nodes, or Namespaces.

This is intentional least privilege: the workload has an identity but no
Kubernetes resource permissions. A namespace-scoped Role and RoleBinding should
be introduced only if the application later gains a demonstrated Kubernetes
API requirement. `cluster-admin` must not be granted to the application,
deployment pipeline, or GitOps identities.

## Namespace resource governance

The FastAPI workload is currently stateless. It has no `PersistentVolumeClaim`,
database, queue, or durable application-data requirement, so the initial
namespace quota does **not** include PVC or storage limits. Storage quotas will
be added only after the project defines a persistence requirement and its RPO,
RTO, backup, and capacity expectations.

The current Deployment requests `100m` CPU and `64Mi` memory, with limits of
`250m` CPU and `256Mi` memory. The proposed namespace baseline uses those
values as the per-container defaults and leaves controlled headroom for future
replicas:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: secure-eks-delivery-quota
  namespace: secure-eks-delivery
spec:
  hard:
    pods: "10"
    requests.cpu: "1"
    limits.cpu: "2"
    requests.memory: 1Gi
    limits.memory: 2Gi
```

The quota values were selected as a lab starting point, not as universal
production limits:

- `pods: 10` prevents an accidental deployment loop from creating unbounded
  pods while allowing rollout testing and modest horizontal growth.
- `requests.cpu: 1` and `requests.memory: 1Gi` allow the current workload and
  several small replicas to reserve capacity.
- `limits.cpu: 2` and `limits.memory: 2Gi` provide burst headroom while keeping
  the namespace bounded.

A companion `LimitRange` should supply safe defaults to future containers and
  reject obviously unreasonable values:

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: secure-eks-delivery-defaults
  namespace: secure-eks-delivery
spec:
  limits:
    - type: Container
      defaultRequest:
        cpu: 100m
        memory: 64Mi
      default:
        cpu: 250m
        memory: 256Mi
      min:
        cpu: 10m
        memory: 16Mi
      max:
        cpu: "1"
        memory: 1Gi
      maxLimitRequestRatio:
        cpu: "4"
        memory: "4"
```

These values must be revisited after observing startup and peak usage. Quotas
should be increased only when replica counts, traffic, and capacity evidence
justify the change.

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

### Portfolio-lab policy

- Scan the built container image in GitHub Actions.
- Preserve a report of all findings as a workflow artifact.
- Retain the SARIF report and triage material findings in the project documentation.
- Do not fail this portfolio-lab workflow on severity alone; its purpose is to demonstrate evidence collection and contextual risk assessment.
- For a production service, define a blocking threshold, an exception owner, rationale, expiry date, and remediation plan before release.
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

### Baseline finding: pinned Python base image

The following baseline was captured before remediation while scanning the selected
`python:3.12-slim-bookworm@sha256:34386ef0cb081344d7ec1c103ba398e6e9f64e9ab3a1509accc92a4e24a07258`
base image. It is intentionally retained as vulnerability-management evidence;
it is not an approved exception or a release decision.

| Component | Installed version | Finding | Severity | Fixed version reported by Trivy | Initial disposition |
| --- | --- | --- | --- | --- | --- |
| `pip` | `25.0.1` | CVE-2025-8869 | Medium | `25.3` | Test a newer pinned Python base-image digest. |
| `pip` | `25.0.1` | CVE-2026-13346 | Medium | `26.2.0` | Test a newer pinned Python base-image digest. |
| `pip` | `25.0.1` | CVE-2026-3219 | Medium | `26.1` | Test a newer pinned Python base-image digest. |
| `pip` | `25.0.1` | CVE-2026-6357 | Medium | No fix reported | Reassess after completing the locked-dependency and final-runtime-image work; do not suppress silently. |
| `pip` | `25.0.1` | CVE-2026-8643 | Medium | `26.1.2` | Test a newer pinned Python base-image digest. |
| `pip` | `25.0.1` | CVE-2026-1703 | Low | `26.0` | Test a newer pinned Python base-image digest. |

**Baseline summary:** 6 findings (5 Medium, 1 Low; 0 High, 0 Critical).

The next action is not an in-place `pip` upgrade. First complete the reproducible
dependency workflow and build the final runtime image, then scan a newer candidate
base-image digest and the finished application image. The application does not need
`pip` at runtime, so the final-image design should avoid retaining unnecessary
package-management tooling where practical.

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

### Local Kind validation

Falco chart `9.2.1` / Falco `0.45.1` was installed on the three-node Kind
cluster using the `modern_ebpf` driver and least-privileged eBPF settings. All
Falco DaemonSet pods reached `2/2 Running`.

An interactive shell was deliberately opened in the application pod as a
controlled test. Falco generated the expected notice on all three nodes:

```text
Notice A shell was spawned in a container with an attached terminal
user_uid=10001 process=sh proc_exepath=/usr/bin/dash
```

One node included complete container and Kubernetes metadata:

```text
container_name=api
container_image_repository=docker.io/library/import-2026-10-20
container_image_tag=local
k8s_pod_name=secure-eks-delivery-596c655b5d-7dgqb
k8s_ns_name=secure-eks-delivery
```

The other nodes reported the syscall event but lacked some runtime metadata in
the output. This is retained as a local Kind/Docker Desktop observation to
reassess on EKS; it does not invalidate the detection result.

### Falco response workflow

```text
Falco event
  -> capture rule, timestamp, pod, container, node, process, and command
  -> determine whether the activity was authorized test activity or unexpected
  -> contain the workload if needed
  -> remediate the image, manifest, RBAC, or node configuration
  -> deploy the corrected version and record the outcome
```

### Planned alert forwarding and automated response

Falco Talon remains a pending enhancement. It may eventually perform narrowly
scoped actions such as quarantining or deleting a confirmed-compromised pod,
but the first production posture should remain detection-only to avoid harmful
false-positive responses.

For AWS notifications, the preferred path is:

```text
Falco -> Falcosidekick -> Amazon SNS -> subscribers or downstream responders
```

Falcosidekick supports AWS SNS as an output and can use AWS workload identity
(IRSA or EKS Pod Identity) rather than embedding access keys in Helm values.
SES is better treated as a downstream email service: use SNS email subscriptions
for simple notifications, or route the event through Lambda/SMTP when a
formatted SES message and application-controlled recipients are required.
The local Kind cluster should use logs, a webhook, or a test endpoint; AWS
credentials should not be added to the lab cluster merely to test alerting.

## Security boundaries and limitations

- Trivy identifies known vulnerabilities; it does not prove that an image is safe from exploitation.
- Falco detects configured behavioral patterns; it does not detect every malicious action.
- Findings must be interpreted in context and documented with evidence.
- The initial lab does not implement automated blocking, SIEM integration, or production incident response.

## Container publication identity

The ECR publication workflow is a separate trust boundary. Its GitHub
environment releases an OIDC token only to the publisher job after quality
checks, secret detection, build, and retained Trivy evidence complete. The AWS
publisher role is limited to authentication and image upload for the project
ECR repository. It is not the Terraform plan role, does not have EKS access,
and cannot modify IAM or infrastructure.

The lab intentionally retains Trivy as evidence rather than a vulnerability
blocking gate. This does not remove the need for a production vulnerability
policy; it keeps the portfolio focus on the pipeline design and separated
identities.

## Temporary network egress exception

During the initial EKS networking phase, the cluster and worker-node security groups use unrestricted outbound traffic. This is a deliberate temporary lab decision so that EKS, image pulls, node updates, and AWS service integrations can be validated before the egress architecture is finalized.

This is not the target production posture. The follow-up hardening work is to restrict outbound traffic through the selected egress design:

- NAT Gateway routes, if internet egress is required; or
- VPC endpoints for services such as ECR, S3, STS, and CloudWatch Logs.

Until that work is complete, record the exception in reviews and do not treat unrestricted egress as an acceptable production control.

The VPC interface-endpoint security group currently also relies on the default outbound behavior. This is a temporary lab exception: endpoint ENIs must be able to return traffic for the AWS services they expose. The hardening phase must replace the implicit rule with an explicit, reviewed egress policy and verify that ECR, STS, and EC2 API calls continue to work.

## Completion criteria

Trivy and Falco are the first security milestone. The full DevSecOps scope is complete only after demonstrating:

1. **Vulnerability remediation:** failing Trivy result -> fix -> passing result -> successful deployment by digest.
2. **Runtime detection:** controlled suspicious activity -> Falco alert -> documented investigation and mitigation.
3. **Identity and pipeline protection:** GitHub OIDC trust conditions, least-privilege permissions, SHA-pinned actions, Gitleaks, and Checkov evidence.
4. **Kubernetes prevention:** non-root/security-context controls, Pod Security Admission or Kyverno rejection evidence, RBAC review, and a denied NetworkPolicy test.
5. **Cloud detection and response:** EKS audit logs plus a documented CloudTrail/GuardDuty or equivalent simulated-event investigation.
6. **Supply-chain traceability:** SBOM and source-to-image-to-deployment evidence; signing is a later enhancement if selected.
