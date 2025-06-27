# GitHub Actions Workflows

This directory contains GitHub Actions workflows for the MODEL_REGISTRY project's CI/CD pipeline.

## Workflows Overview

### 1. Main CI/CD Pipeline (`ci-cd.yml`)
The primary workflow that handles the complete CI/CD process.

**Triggers:**
- Push to `main`, `develop`, or `master` branches
- Pull requests to protected branches
- Release creation

**Stages:**
1. **Validation**: SQL syntax validation and schema consistency checks
2. **Testing**: Unit tests, integration tests, and performance tests
3. **Build**: Documentation generation and release packaging
4. **Deploy**: Staging and production deployments
5. **Notification**: Success/failure notifications via Slack

### 2. Pull Request Checks (`pr-checks.yml`)
Dedicated workflow for pull request validation and testing.

**Features:**
- Validates only changed SQL files
- Runs tests on PR changes
- Automatic cleanup of test resources
- Faster feedback for developers

### 3. Security Scanning (`security-scan.yml`)
Comprehensive security analysis workflow.

**Scans:**
- **CodeQL Analysis**: Static code analysis for Python and JavaScript
- **Dependency Review**: Checks for vulnerable dependencies
- **Python Security**: Bandit, Safety, and pip-audit scans
- **SQL Security**: SQL injection and credential scanning
- **Container Security**: Trivy vulnerability scanning
- **Secret Scanning**: TruffleHog and GitLeaks for exposed secrets

### 4. Automated Release (`release.yml`)
Handles automated releases when tags are pushed.

**Features:**
- Creates GitHub releases automatically
- Builds release packages
- Deploys to production
- Updates release notes with deployment status
- Sends notifications

## Required Secrets

Configure these secrets in your GitHub repository settings:

### Database Configuration
- `DB_SERVER`: SQL Server instance name
- `DB_USERNAME`: Database username (if not using Windows Authentication)
- `DB_PASSWORD`: Database password (if not using Windows Authentication)

### Notifications
- `SLACK_WEBHOOK_URL`: Slack webhook URL for notifications

### Optional
- `GITHUB_TOKEN`: Automatically provided by GitHub
- `DB_NAME_TEST`: Test database name (defaults to MODEL_REGISTRY_TEST)
- `DB_NAME_STAGING`: Staging database name (defaults to MODEL_REGISTRY_STAGING)
- `DB_NAME_PROD`: Production database name (defaults to MODEL_REGISTRY)

## Environment Protection

### Staging Environment
- Requires approval for deployments
- Runs on `develop` branch pushes
- Includes smoke tests

### Production Environment
- Requires approval for deployments
- Runs on `main`/`master` branch pushes or releases
- Includes database backup and health checks

## Usage Examples

### Creating a Release
```bash
# Create and push a new tag
git tag v1.2.0
git push origin v1.2.0
```

### Running Tests Locally
```bash
# Run unit tests
python3 tests/run_unit_tests.py --database MODEL_REGISTRY_TEST

# Run integration tests
python3 tests/run_integration_tests.py --database MODEL_REGISTRY_TEST
```

### Manual Deployment
1. Go to the Actions tab in GitHub
2. Select the desired workflow
3. Click "Run workflow"
4. Choose the branch and input parameters
5. Click "Run workflow"

## Workflow Dependencies

### Job Dependencies
- `unit-tests` and `integration-tests` depend on `setup-test-database`
- `deploy-staging` depends on `unit-tests` and `integration-tests`
- `deploy-production` depends on `unit-tests`, `integration-tests`, and `performance-tests`

### Artifact Sharing
- Test results are shared between jobs using GitHub Actions artifacts
- Documentation is generated and deployed to GitHub Pages
- Release packages are uploaded to GitHub releases

## Monitoring and Troubleshooting

### Workflow Status
- Check the Actions tab for workflow status
- Review job logs for detailed error information
- Use the "Re-run jobs" feature for failed workflows

### Common Issues
1. **Database Connection**: Ensure SQL Server is accessible and credentials are correct
2. **Test Failures**: Check test database setup and data requirements
3. **Permission Issues**: Verify repository secrets and environment protection rules
4. **Timeout Issues**: Increase job timeout limits for long-running operations

### Logs and Artifacts
- Test reports are available as downloadable artifacts
- Security scan results are uploaded to the Security tab
- Release packages are attached to GitHub releases

## Customization

### Adding New Tests
1. Create test files in the `tests/` directory
2. Update the workflow to include your test command
3. Add test result reporting if needed

### Modifying Deployment
1. Update deployment scripts in the `scripts/` directory
2. Modify the deployment steps in the workflow
3. Add new environment variables as needed

### Security Scanning
1. Add new security tools to the security workflow
2. Configure tool-specific parameters
3. Update the security summary generation

## Best Practices

1. **Branch Protection**: Enable branch protection rules for main branches
2. **Required Checks**: Configure required status checks for PRs
3. **Environment Protection**: Use environment protection for production deployments
4. **Secret Management**: Use GitHub secrets for sensitive information
5. **Artifact Cleanup**: Set appropriate retention periods for artifacts
6. **Monitoring**: Set up notifications for workflow failures
7. **Documentation**: Keep this README updated with workflow changes

## Support

For issues with the CI/CD pipeline:
1. Check the workflow logs for error details
2. Verify repository secrets and permissions
3. Review the troubleshooting section above
4. Create an issue in the repository with workflow details 