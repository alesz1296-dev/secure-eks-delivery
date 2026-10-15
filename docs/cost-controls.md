# Cost Controls and Teardown

## Principle

This is a short-lived learning environment. Do not leave billable infrastructure running between intentional lab sessions.

## Required controls before provisioning

- Set an AWS Budget and billing alert.
- Use a dedicated sandbox account or clearly isolated project namespace.
- Apply consistent tags: `project`, `environment`, `owner`, and `cleanup_deadline`.
- Review `terraform plan` before every apply and destroy.
- Keep the default configuration minimal.

## Planned Terraform feature flags

| Flag                 | Purpose                                 | Cost behavior                                                       |
| -------------------- | --------------------------------------- | ------------------------------------------------------------------- |
| `enable_eks`         | Creates the EKS cluster                 | EKS control-plane charge continues while the cluster exists         |
| `enable_node_group`  | Creates EC2 worker nodes                | EC2 and attached storage charge while nodes/volumes exist           |
| `enable_nat_gateway` | Enables private-subnet internet egress  | NAT Gateway incurs hourly and data-processing charges               |
| `enable_ingress`     | Enables external ingress/load balancing | Load balancer and related data charges may apply                    |
| `enable_falco`       | Deploys Falco to existing nodes         | No separate AWS service charge, but consumes node capacity and logs |

Flags must remove or avoid creating a resource when disabled. Merely scaling an application deployment to zero does not remove EKS, networking, or storage charges.

## Initial low-cost approach

- Use one small EC2 managed node only during active lab sessions.
- Use `kubectl port-forward`; do not create a load balancer initially.
- Avoid NAT Gateway initially where the selected design can operate without it.
- Keep CloudWatch log retention short and intentional.
- Use current Kubernetes versions to avoid EKS extended-support charges.

## Teardown checklist

- [ ] Destroy Terraform-managed infrastructure when the session ends.
- [ ] Confirm the EKS cluster no longer exists.
- [ ] Confirm EC2 instances and managed node groups are gone.
- [ ] Confirm EBS volumes and snapshots are not unintentionally retained.
- [ ] Confirm NAT Gateways, load balancers, public IPv4 addresses, and Elastic IPs are gone.
- [ ] Confirm CloudWatch log groups and retained artifacts match the intended evidence policy.
- [ ] Confirm ECR repositories and images are retained or removed intentionally.
- [ ] Record cleanup date and remaining intentional costs.
