# Security Policy

## Reporting a vulnerability

If you discover a security vulnerability in the Z3rno Helm chart or any Z3rno project, please report it responsibly.

**Do not open a public GitHub issue for security vulnerabilities.**

### Contact

Email: **security@z3rno.dev**

Please include:

- A description of the vulnerability
- Steps to reproduce
- The potential impact
- (Optional) A suggested fix

### Scope

This policy covers:

- Kubernetes manifest templates that could lead to privilege escalation or insecure defaults
- Secrets management issues (credentials exposed in ConfigMaps, insufficient RBAC, etc.)
- Container image vulnerabilities in default image references
- Helm chart logic that could result in insecure deployments

### Response timeline

| Stage | Timeline |
|---|---|
| Acknowledgement | Within 2 business days |
| Initial assessment | Within 5 business days |
| Resolution target | Within 30 days for critical issues |

We will keep you informed of our progress and credit you in the advisory (unless you prefer to remain anonymous).

## Supported versions

We address security issues in the latest version of the Helm chart. There is no backporting to previous versions.

## Responsible disclosure

We kindly ask that you:

- Give us reasonable time to address the issue before public disclosure
- Do not access or modify other users' data
- Act in good faith to avoid disruption to our services
