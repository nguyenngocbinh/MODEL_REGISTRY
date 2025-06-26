# CI/CD Integration for Model Registry

This document describes the comprehensive CI/CD pipeline implementation for the Model Registry project.

## 🚀 Pipeline Overview

The CI/CD pipeline consists of 6 stages:
1. **Validate** - SQL syntax and schema validation
2. **Test** - Unit, integration, and performance testing
3. **Build** - Documentation generation and release packaging
4. **Deploy** - Environment-specific deployments
5. **Notify** - Success/failure notifications
6. **Cleanup** - Test database cleanup

## 📋 Pipeline Stages

### Validation Stage
- **SQL Syntax Validation**: Checks all SQL files for syntax errors
- **Schema Consistency**: Validates table dependencies and naming conventions
- **Triggers**: Runs only when database files are changed

### Test Stage
- **Unit Tests**: Tests individual stored procedures and functions
- **Integration Tests**: Tests complete workflows and system integration
- **Performance Tests**: Validates query performance and system load
- **Coverage Reporting**: Generates test coverage reports

### Build Stage
- **Documentation Generation**: Auto-generates technical documentation
- **Release Packaging**: Creates versioned deployment packages
- **Artifact Management**: Stores build artifacts for deployment

### Deploy Stage
- **Staging Deployment**: Automatic deployment to staging environment
- **Production Deployment**: Manual deployment with safety checks
- **GitHub Sync**: Syncs master branch to GitHub dev branch

### Notification Stage
- **Success Notifications**: Sends success messages to Slack
- **Failure Alerts**: Immediate notifications on pipeline failures

## 🛠️ Setup Instructions

### 1. GitLab CI Variables

Configure these variables in your GitLab project:

```bash
# Database Configuration
DB_SERVER=your_sql_server
DB_NAME_TEST=MODEL_REGISTRY_TEST
DB_NAME_STAGING=MODEL_REGISTRY_STAGING
DB_NAME_PROD=MODEL_REGISTRY

# GitHub Integration
GITHUB_TOKEN=your_github_token
GITLAB_PERSONAL_ACCESS_TOKEN=your_gitlab_token

# Notifications
SLACK_WEBHOOK_URL=your_slack_webhook
```

### 2. Database Permissions

Ensure the CI/CD runner has:
- Database creation permissions for test databases
- Read/write access to staging and production databases
- Backup permissions for production deployments

### 3. Python Dependencies

Install required Python packages in your runner:

```bash
pip install pyodbc xml.etree.ElementTree argparse
```

## 🧪 Testing Framework

### Unit Tests (`tests/run_unit_tests.py`)

Tests individual components:
- Stored procedure functionality
- Function calculations
- Data integrity checks
- Basic query validation

```bash
# Run unit tests
python tests/run_unit_tests.py --database MODEL_REGISTRY_TEST --verbose
```

### Integration Tests (`tests/run_integration_tests.py`)

Tests complete workflows:
- Model lifecycle (registration → validation → monitoring)
- Feature management workflow
- Cross-system integration
- View functionality

```bash
# Run integration tests
python tests/run_integration_tests.py --database MODEL_REGISTRY_TEST --verbose
```

### Health Checks (`tests/health_check.py`)

Post-deployment validation:
- Database connectivity
- Essential components availability
- Data integrity
- Performance metrics

```bash
# Run health check
python tests/health_check.py --database MODEL_REGISTRY --exit-on-warning
```

## 🚀 Deployment Process

### Staging Deployment

**Trigger**: Push to `develop` branch
**Process**:
1. Automatic schema installation
2. Environment-specific configurations
3. Smoke tests execution
4. Health check validation

**Safety Features**:
- Automatic backup before changes
- Rollback on failure
- Reduced monitoring frequency

### Production Deployment

**Trigger**: Manual approval on `master` branch
**Process**:
1. **Pre-deployment Safety Checks**:
   - Database name verification
   - Recent backup verification
   - Active session check
2. **Backup Creation**:
   - Timestamped table backups
   - Critical data preservation
3. **Schema Deployment**:
   - Single-user mode activation
   - Schema updates execution
   - Production configurations
4. **Validation**:
   - Comprehensive health checks
   - Data integrity verification
   - Monitoring system validation

**Safety Features**:
- Multiple validation layers
- Automatic rollback on failure
- Production-specific configurations
- Comprehensive logging

## 📊 Monitoring and Alerting

### Automated Monitoring

The pipeline includes automated monitoring setup:
- Performance threshold monitoring
- Data quality issue detection
- Model validation tracking
- Alert management

### Notification Channels

- **Slack**: Real-time pipeline status
- **Email**: Critical production issues
- **Dashboard**: Performance metrics

## 🔧 Customization

### Adding New Tests

1. **Unit Tests**: Add test cases to `run_unit_tests.py`
2. **Integration Tests**: Extend workflows in `run_integration_tests.py`
3. **Health Checks**: Add checks to `health_check.py`

### Environment-Specific Configurations

Modify deployment scripts:
- `deploy_staging.sql`: Staging-specific settings
- `deploy_production.sql`: Production configurations

### Validation Rules

Extend `validate_schema.py`:
- Add naming convention rules
- Include custom dependency checks
- Enhance validation logic

## 📈 Performance Considerations

### Test Optimization
- Parallel test execution where possible
- Efficient test data cleanup
- Optimized query performance validation

### Deployment Optimization
- Incremental schema updates
- Minimal downtime deployments
- Efficient backup strategies

## 🚨 Troubleshooting

### Common Issues

1. **Connection Failures**
   - Check database connectivity
   - Verify credentials and permissions
   - Ensure SQL Server accessibility

2. **Test Failures**
   - Review test logs in artifacts
   - Check test data dependencies
   - Validate schema consistency

3. **Deployment Issues**
   - Check deployment logs
   - Verify backup creation
   - Review safety check failures

### Debug Commands

```bash
# Verbose unit testing
python tests/run_unit_tests.py --database TEST_DB --verbose

# Schema validation with details
python scripts/validate_schema.py --verbose --schema-path database/schema

# Health check with detailed output
python tests/health_check.py --database PROD_DB --exit-on-warning
```

## 📚 Related Documentation

- [Database Schema Documentation](database/DATABASE_DESCRIPTION.md)
- [Stored Procedures Guide](database/procedures/PROCEDURE_DESCRIPTION.md)
- [Deployment Guide](docs/admin_guide.md)
- [User Manual](docs/user_guide.md)

## 🤝 Contributing

When contributing to the CI/CD pipeline:

1. **Test Locally**: Run tests locally before committing
2. **Update Documentation**: Keep this README current
3. **Follow Standards**: Maintain coding and naming conventions
4. **Test Coverage**: Ensure new features have appropriate tests

## 📞 Support

For CI/CD pipeline issues:
- Create an issue in the repository
- Contact the DevOps team
- Check pipeline logs in GitLab CI/CD section
- Review health check outputs

---

**Last Updated**: June 19, 2025
**Version**: 1.0
**Maintainer**: Nguyễn Ngọc Bình