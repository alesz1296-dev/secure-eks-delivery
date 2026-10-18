# Kubernetes Pod Security

Document the security decisions and verification evidence for the application namespace here.

Planned controls:

- Pod Security Admission labels using the restricted profile.
- `runAsNonRoot` and explicit UID/GID.
- Dropped Linux capabilities.
- `allowPrivilegeEscalation: false`.
- `readOnlyRootFilesystem: true` where compatible.
- `seccompProfile: RuntimeDefault`.
- Resource requests and limits.
