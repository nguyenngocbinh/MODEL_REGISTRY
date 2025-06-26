#!/usr/bin/env python3
"""
Health Check Script for Model Registry
Post-deployment validation and system health monitoring
"""

import os
import sys
import argparse
import pyodbc
import time
from datetime import datetime

class ModelRegistryHealthChecker:
    def __init__(self, connection_string: str):
        self.connection_string = connection_string
        self.connection = None
        self.health_status = "HEALTHY"
        self.issues = []
        self.setup_connection()
    
    def setup_connection(self):
        """Establish database connection"""
        try:
            self.connection = pyodbc.connect(self.connection_string)
            self.connection.autocommit = True
        except Exception as e:
            self.health_status = "CRITICAL"
            self.issues.append(f"Database connection failed: {e}")
    
    def execute_query(self, query: str, params: tuple = None):
        """Execute SQL query and return results"""
        if not self.connection:
            return None
            
        cursor = self.connection.cursor()
        try:
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
            
            try:
                return cursor.fetchall()
            except:
                return None
        except Exception as e:
            raise Exception(f"Query execution failed: {e}")
        finally:
            cursor.close()
    
    def check_database_connectivity(self):
        """Test basic database connectivity"""
        try:
            result = self.execute_query("SELECT GETDATE() as CurrentTime")
            if not result:
                self.health_status = "CRITICAL"
                self.issues.append("Cannot execute basic queries")
            else:
                print(f"✓ Database connectivity: OK (Server time: {result[0][0]})")
        except Exception as e:
            self.health_status = "CRITICAL"
            self.issues.append(f"Database connectivity test failed: {e}")
    
    def check_essential_tables(self):
        """Check if all essential tables exist and are accessible"""
        essential_tables = [
            'MODEL_TYPE', 'MODEL_REGISTRY', 'FEATURE_REGISTRY',
            'MODEL_VALIDATION_RESULTS', 'FEATURE_STATS', 'MODEL_SOURCE_TABLES'
        ]
        
        missing_tables = []
        inaccessible_tables = []
        
        for table in essential_tables:
            try:
                # Check if table exists
                result = self.execute_query(
                    "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = ?",
                    (table,)
                )
                
                if not result or result[0][0] == 0:
                    missing_tables.append(table)
                else:
                    # Test table accessibility
                    try:
                        self.execute_query(f"SELECT TOP 1 * FROM {table}")
                    except:
                        inaccessible_tables.append(table)
                        
            except Exception as e:
                inaccessible_tables.append(f"{table} ({str(e)})")
        
        if missing_tables:
            self.health_status = "CRITICAL"
            self.issues.append(f"Missing essential tables: {', '.join(missing_tables)}")
        
        if inaccessible_tables:
            if self.health_status != "CRITICAL":
                self.health_status = "WARNING"
            self.issues.append(f"Inaccessible tables: {', '.join(inaccessible_tables)}")
        
        if not missing_tables and not inaccessible_tables:
            print(f"✓ Essential tables: All {len(essential_tables)} tables present and accessible")
    
    def check_stored_procedures(self):
        """Check if critical stored procedures exist"""
        critical_procedures = [
            'GET_MODEL_FEATURES', 'REGISTER_NEW_MODEL', 'CHECK_MODEL_DEPENDENCIES'
        ]
        
        missing_procedures = []
        
        for proc in critical_procedures:
            try:
                result = self.execute_query(
                    "SELECT COUNT(*) FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = ? AND ROUTINE_TYPE = 'PROCEDURE'",
                    (proc,)
                )
                
                if not result or result[0][0] == 0:
                    missing_procedures.append(proc)
                    
            except Exception as e:
                missing_procedures.append(f"{proc} (check failed)")
        
        if missing_procedures:
            if self.health_status != "CRITICAL":
                self.health_status = "WARNING"
            self.issues.append(f"Missing critical procedures: {', '.join(missing_procedures)}")
        else:
            print(f"✓ Critical procedures: All {len(critical_procedures)} procedures available")
    
    def check_data_integrity(self):
        """Check basic data integrity"""
        integrity_checks = [
            ("Orphaned models", 
             "SELECT COUNT(*) FROM MODEL_REGISTRY mr LEFT JOIN MODEL_TYPE mt ON mr.TYPE_ID = mt.TYPE_ID WHERE mt.TYPE_ID IS NULL"),
            ("Inactive model types", 
             "SELECT COUNT(*) FROM MODEL_TYPE WHERE IS_ACTIVE = 0"),
            ("Models without validation results", 
             "SELECT COUNT(*) FROM MODEL_REGISTRY mr LEFT JOIN MODEL_VALIDATION_RESULTS mvr ON mr.MODEL_ID = mvr.MODEL_ID WHERE mr.IS_ACTIVE = 1 AND mvr.MODEL_ID IS NULL")
        ]
        
        warnings = []
        
        for check_name, query in integrity_checks:
            try:
                result = self.execute_query(query)
                if result and result[0][0] > 0:
                    warnings.append(f"{check_name}: {result[0][0]} records")
            except Exception as e:
                warnings.append(f"{check_name}: Check failed - {str(e)}")
        
        if warnings:
            if self.health_status == "HEALTHY":
                self.health_status = "WARNING"
            self.issues.extend(warnings)
        else:
            print("✓ Data integrity: No issues detected")
    
    def check_monitoring_system(self):
        """Check if monitoring system is active"""
        try:
            # Check if monitoring tables exist
            monitoring_tables = ['MODEL_MONITORING_CONFIG', 'MODEL_MONITORING_ALERTS']
            missing_monitoring = []
            
            for table in monitoring_tables:
                result = self.execute_query(
                    "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = ?",
                    (table,)
                )
                if not result or result[0][0] == 0:
                    missing_monitoring.append(table)
            
            if missing_monitoring:
                print(f"⚠ Monitoring system: Tables missing ({', '.join(missing_monitoring)})")
                return
            
            # Check if there are active monitoring configurations
            active_configs = self.execute_query(
                "SELECT COUNT(*) FROM MODEL_MONITORING_CONFIG WHERE IS_ACTIVE = 1"
            )
            
            if not active_configs or active_configs[0][0] == 0:
                if self.health_status == "HEALTHY":
                    self.health_status = "WARNING"
                self.issues.append("No active monitoring configurations found")
            else:
                print(f"✓ Monitoring system: {active_configs[0][0]} active configurations")
                
        except Exception as e:
            print(f"⚠ Monitoring system: Check failed - {str(e)}")
    
    def check_performance_metrics(self):
        """Check basic performance metrics"""
        try:
            # Check database size
            db_size = self.execute_query("""
                SELECT 
                    SUM(CAST(FILEPROPERTY(name, 'SpaceUsed') AS bigint) * 8192) / 1024 / 1024 as DB_SIZE_MB
                FROM sys.database_files
            """)
            
            if db_size:
                db_size_mb = db_size[0][0]
                print(f"ℹ Database size: {db_size_mb:.1f} MB")
                
                if db_size_mb > 10000:  # 10GB
                    if self.health_status == "HEALTHY":
                        self.health_status = "WARNING"
                    self.issues.append(f"Large database size: {db_size_mb:.1f} MB")
            
            # Check recent activity
            recent_models = self.execute_query("""
                SELECT COUNT(*) FROM MODEL_REGISTRY 
                WHERE CREATED_DATE >= DATEADD(DAY, -30, GETDATE())
            """)
            
            if recent_models:
                print(f"ℹ Recent activity: {recent_models[0][0]} models created in last 30 days")
            
        except Exception as e:
            print(f"⚠ Performance metrics: Check failed - {str(e)}")
    
    def check_recent_deployments(self):
        """Check recent deployment status"""
        try:
            result = self.execute_query("""
                SELECT TOP 5 
                    DEPLOYMENT_DATE,
                    ENVIRONMENT,
                    VERSION,
                    STATUS
                FROM DEPLOYMENT_LOG 
                ORDER BY DEPLOYMENT_DATE DESC
            """)
            
            if result:
                print(f"ℹ Recent deployments:")
                for row in result:
                    status_symbol = "✓" if row[3] == "SUCCESS" else "✗"
                    print(f"  {status_symbol} {row[0]} - {row[1]} ({row[2]}) - {row[3]}")
                
                # Check if last deployment was successful
                last_deployment = result[0]
                if last_deployment[3] != "SUCCESS":
                    if self.health_status == "HEALTHY":
                        self.health_status = "WARNING"
                    self.issues.append(f"Last deployment failed: {last_deployment[3]}")
            else:
                print("ℹ No deployment history found")
                
        except Exception as e:
            print(f"ℹ Deployment history: Not available ({str(e)})")
    
    def run_health_check(self):
        """Run complete health check"""
        print("=" * 50)
        print("MODEL REGISTRY HEALTH CHECK")
        print("=" * 50)
        print(f"Check time: {datetime.now()}")
        print()
        
        self.check_database_connectivity()
        self.check_essential_tables()
        self.check_stored_procedures()
        self.check_data_integrity()
        self.check_monitoring_system()
        self.check_performance_metrics()
        self.check_recent_deployments()
        
        print()
        print("=" * 50)
        print(f"OVERALL HEALTH STATUS: {self.health_status}")
        print("=" * 50)
        
        if self.issues:
            print("\nISSUES DETECTED:")
            for i, issue in enumerate(self.issues, 1):
                print(f"{i}. {issue}")
        else:
            print("\n✓ No issues detected - System is healthy")
        
        return self.health_status
    
    def close_connection(self):
        """Close database connection"""
        if self.connection:
            self.connection.close()

def main():
    parser = argparse.ArgumentParser(description='Run Model Registry health check')
    parser.add_argument('--database', required=True, help='Database name')
    parser.add_argument('--server', default='localhost', help='Database server')
    parser.add_argument('--exit-on-warning', action='store_true', help='Exit with error code on warnings')
    
    args = parser.parse_args()
    
    # Build connection string
    connection_string = f"DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={args.server};DATABASE={args.database};Trusted_Connection=yes;"
    
    checker = ModelRegistryHealthChecker(connection_string)
    
    try:
        health_status = checker.run_health_check()
        
        # Determine exit code
        if health_status == "CRITICAL":
            sys.exit(2)
        elif health_status == "WARNING" and args.exit_on_warning:
            sys.exit(1)
        else:
            sys.exit(0)
            
    finally:
        checker.close_connection()

if __name__ == '__main__':
    main()