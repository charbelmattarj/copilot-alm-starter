# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly:

1. **Do not** create a public GitHub issue
2. Email details to the repository maintainers
3. Include steps to reproduce the vulnerability
4. Allow time for the issue to be addressed before disclosure

## Security Best Practices

When using this repository:

### Secrets Management

- Never commit secrets to the repository
- Use GitHub Secrets for sensitive values
- Rotate credentials regularly
- Use environment-specific secrets

### Service Principal Security

- Follow principle of least privilege
- Use environment-level permissions when possible
- Monitor service principal activity
- Set appropriate secret expiration

### Repository Security

- Enable branch protection rules
- Require PR reviews for main branch
- Use environment protection rules
- Enable security alerts

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| Latest  | :white_check_mark: |
| Older   | :x:                |
