# Contributing to MCS ALM Starter

Thank you for your interest in contributing! This document provides guidelines and steps for contributing.

## How to Contribute

### Reporting Issues

- Use GitHub Issues to report bugs or suggest features
- Search existing issues before creating a new one
- Provide detailed information including:
  - Steps to reproduce (for bugs)
  - Expected vs actual behavior
  - Environment details (OS, Power Platform version, etc.)

### Submitting Changes

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
   - Follow existing code style and conventions
   - Update documentation if needed
   - Test your changes thoroughly
4. **Commit with clear messages**
   ```bash
   git commit -m "feat: add support for connection references"
   ```
5. **Push and create a Pull Request**
   ```bash
   git push origin feature/your-feature-name
   ```

### Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `chore:` - Maintenance tasks
- `refactor:` - Code refactoring

### Code Style

- **PowerShell**: Follow [PowerShell Best Practices](https://poshcode.gitbook.io/powershell-practice-and-style/)
- **YAML**: Use 2-space indentation
- **Markdown**: Use proper headings and formatting

## Development Setup

1. Clone the repository
2. Install Power Platform CLI: `pac install latest`
3. Install GitHub CLI (optional): `gh auth login`

## Questions?

Open a GitHub Issue or start a Discussion.
