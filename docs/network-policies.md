# Local Kubernetes Network Policies

The local cluster uses three additive NetworkPolicies in the `secure-eks-delivery` namespace:

1. A default-deny policy for ingress and egress.
2. An egress exception allowing application DNS queries to CoreDNS.
3. An ingress exception allowing port `8080` only from explicitly labelled client pods.

## Default-deny boundary

The default-deny policy selects every pod in the application namespace and establishes the baseline:

```text
All application ingress: denied
All application egress: denied
```

The policy does not automatically govern pods in other namespaces or replace host, control-plane, or security-group controls.

NetworkPolicies are additive. An allow policy adds permission; it does not override another policy with a separate deny statement.

## DNS exception

The DNS policy selects the FastAPI pod and allows egress only when the destination is:

```text
Namespace: kube-system
Pod label: k8s-app=kube-dns
Ports: UDP 53 and TCP 53
```

The namespace and pod selectors are combined with logical `AND` semantics. DNS access does not grant general internet access.

```text
FastAPI pod -> CoreDNS: allowed
FastAPI pod -> external API on TCP 443: denied
FastAPI pod -> arbitrary pod: denied
```

## API ingress exception

The API policy selects the FastAPI pod and requires both source conditions:

```text
Source namespace: secure-eks-delivery
Source pod label: access=api-client
Destination port: TCP 8080
```

The following traffic is denied:

```text
Pod in another namespace -> FastAPI:8080
Unlabelled pod in secure-eks-delivery -> FastAPI:8080
FastAPI pod -> arbitrary application port
```

The intended traffic model is:

```text
                         +--------------+
                         | CoreDNS       |
                         | UDP/TCP 53    |
                         +------+--------+
                                | allowed
                                v
+--------------+       +------------------+
| api-client   |------>| FastAPI pod      |
| access label | :8080| ingress allowed  |
+--------------+       +------------------+
                                |
                                +-- all other egress denied
```

## Port-forward limitation

`kubectl port-forward` may continue to work because it uses the Kubernetes API and kubelet path rather than normal pod-to-pod networking. A successful port-forward is therefore not evidence that arbitrary pods can reach the application.

## Verification exercise

Create an unlabelled test pod and confirm that access to the Service fails. Then create a pod labelled `access=api-client` and confirm that access to port `8080` succeeds. Save both results as evidence.

The policy model is enforced locally by Cilium and is intended to remain portable to EKS. NetworkPolicies complement, but do not replace, AWS security groups, IAM, Pod Security Admission, or application authorization.

## Label limitation

The `access=api-client` label is a network-selection mechanism, not an identity control. Any identity with permission to create or modify Pods in this namespace could apply that label. The local lab demonstrates least-privilege traffic selection; it does not treat the label as authentication.

Future hardening will restrict workload-creation permissions with RBAC and use an admission policy to limit which workloads may use this label.

## Evidence: unlabelled pod denied

**Date:** 2026-10-18

**Source:** `test-denied`

**Source label:** none

**Destination:** `secure-eks-delivery:8080` (`ClusterIP` `10.96.195.251`)

**Result:** denied; connection timed out after 3 seconds.

Observed output:

```text
curl: (28) Failed to connect to 10.96.195.251 port 8080 after 3002 ms: Timeout was reached
command terminated with exit code 28
```

This verifies that an unlabelled pod cannot reach the FastAPI Service. The corresponding allowed-path test must use a restricted pod labelled `access=api-client` and an explicit client egress policy.

## Evidence: labelled client allowed

**Date:** 2026-10-18

**Source:** `test-allowed`

**Source label:** `access=api-client`

**Destination:** `secure-eks-delivery:8080` (`ClusterIP` `10.96.195.251`)

**Result:** allowed; HTTP 200 response received.

**Observed response:**

```json
{"status":"ready"}
```

This verifies that the labelled client satisfies both directions required by the policy model: client egress to the FastAPI pod and FastAPI ingress from the labelled client.
