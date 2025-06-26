#!/usr/bin/env python3
"""
Integration Test Runner for Model Registry
Tests end-to-end workflows and system integration
"""

import os
import sys
import argparse
import pyodbc
import json
from datetime import datetime
from pathlib import Path
import xml.etree.ElementTree as ET

class ModelRegistryIntegrationTester:
    def __init__(self, connection_string: str):
        self.connection_string = connection_string
        self.connection = None
        self.test_results = []
        self.setup_connection()
    
    def setup_connection(self):
        """Establish database connection"""
        try:
            self.connection = pyodbc.connect(self.connection_string)
            self.connection.autocommit = True
        except Exception as e:
            print(f"Failed to connect to database: {e}")
            sys.exit(1)
    
    def execute_query(self, query: str, params: tuple = None):
        """Execute SQL query and return results"""
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
    
    def run_integration_tests(self):
        """Run all integration tests"""
        
        # Test 1: Complete model lifecycle workflow
        self.test_model_lifecycle_workflow()
        
        # Test 2: Feature registration and validation workflow
        self.test_feature_workflow()
        
        # Test 3: Model monitoring workflow
        self.test_monitoring_workflow()
        
        # Test 4: Data quality workflow
        self.test_data_quality_workflow()
        
        # Test 5: Cross-system integration
        self.test_cross_system_integration()
    
    def test_model_lifecycle_workflow(self):
        """Test complete model lifecycle from registration to validation"""
        test_name = "model_lifecycle_workflow"
        
        try:
            # Step 1: Register a new model
            model_name = "INTEGRATION_TEST_MODEL"
            
            # Clean up any existing test data
            self.execute_query("DELETE FROM MODEL_REGISTRY WHERE MODEL_NAME = ?", (model_name,))
            
            # Register new model
            result = self.execute_query("""
                EXEC REGISTER_NEW_MODEL 
                    @MODEL_NAME = ?,
                    @MODEL_VERSION = '1.0',
                    @MODEL_TYPE_CODE = 'PD',
                    @SOURCE_DATABASE = 'TEST_DB',
                    @SOURCE_SCHEMA = 'dbo',
                    @SOURCE_TABLE_NAME = 'TEST_OUTPUT'
            """, (model_name,))
            
            # Verify model was created
            model_check = self.execute_query(
                "SELECT MODEL_ID FROM MODEL_REGISTRY WHERE MODEL_NAME = ?", 
                (model_name,)
            )
            
            if not model_check or len(model_check) == 0:
                raise Exception("Model registration failed")
            
            model_id = model_check[0][0]
            
            # Step 2: Add model validation results
            self.execute_query("""
                INSERT INTO MODEL_VALIDATION_RESULTS 
                (MODEL_ID, VALIDATION_DATE, GINI, KS_STATISTIC, PSI, ACCURACY)
                VALUES (?, GETDATE(), 0.45, 0.35, 0.15, 0.85)
            """, (model_id,))
            
            # Step 3: Check model dependencies
            dependency_result = self.execute_query(
                "EXEC CHECK_MODEL_DEPENDENCIES @MODEL_ID = ?", 
                (model_id,)
            )
            
            # Step 4: Get model features
            features_result = self.execute_query(
                "EXEC GET_MODEL_FEATURES @MODEL_ID = ?", 
                (model_id,)
            )
            
            # Clean up
            self.execute_query("DELETE FROM MODEL_VALIDATION_RESULTS WHERE MODEL_ID = ?", (model_id,))
            self.execute_query("DELETE FROM MODEL_REGISTRY WHERE MODEL_ID = ?", (model_id,))
            
            self.test_results.append({
                'name': test_name,
                'status': 'PASS',
                'message': 'Complete model lifecycle workflow executed successfully',
                'error': None
            })
            
        except Exception as e:
            self.test_results.append({
                'name': test_name,
                'status': 'ERROR',
                'message': 'Model lifecycle workflow test',
                'error': str(e)
            })
    
    def test_feature_workflow(self):
        """Test feature registration and validation workflow"""
        test_name = "feature_workflow"
        
        try:
            # Step 1: Register a new feature
            feature_code = "INTEGRATION_TEST_FEATURE"
            
            # Clean up any existing test data
            self.execute_query("DELETE FROM FEATURE_REGISTRY WHERE FEATURE_CODE = ?", (feature_code,))
            
            # Register new feature
            self.execute_query("""
                INSERT INTO FEATURE_REGISTRY 
                (FEATURE_NAME, FEATURE_CODE, FEATURE_DESCRIPTION, DATA_TYPE, VALUE_TYPE, SOURCE_SYSTEM, BUSINESS_CATEGORY)
                VALUES ('Integration Test Feature', ?, 'Test feature for integration testing', 
                        'NUMERIC', 'CONTINUOUS', 'TEST_SYSTEM', 'TEST_CATEGORY')
            """, (feature_code,))
            
            # Get feature ID
            feature_check = self.execute_query(
                "SELECT FEATURE_ID FROM FEATURE_REGISTRY WHERE FEATURE_CODE = ?", 
                (feature_code,)
            )
            
            if not feature_check or len(feature_check) == 0:
                raise Exception("Feature registration failed")
            
            feature_id = feature_check[0][0]
            
            # Step 2: Add feature statistics
            self.execute_query("""
                INSERT INTO FEATURE_STATS 
                (FEATURE_ID, CALCULATION_DATE, SAMPLE_SIZE, MIN_VALUE, MAX_VALUE, MEAN, MISSING_RATIO)
                VALUES (?, GETDATE(), 1000, 0.0, 100.0, 50.0, 0.05)
            """, (feature_id,))
            
            # Step 3: Validate feature using the validation function
            if self.function_exists('FN_VALIDATE_FEATURE'):
                validation_result = self.execute_query(
                    "SELECT * FROM dbo.FN_VALIDATE_FEATURE(?, NULL, NULL)", 
                    (feature_id,)
                )
            
            # Clean up
            self.execute_query("DELETE FROM FEATURE_STATS WHERE FEATURE_ID = ?", (feature_id,))
            self.execute_query("DELETE FROM FEATURE_REGISTRY WHERE FEATURE_ID = ?", (feature_id,))
            
            self.test_results.append({
                'name': test_name,
                'status': 'PASS',
                'message': 'Feature workflow executed successfully',
                'error': None
            })
            
        except Exception as e:
            self.test_results.append({
                'name': test_name,
                'status': 'ERROR',
                'message': 'Feature workflow test',
                'error': str(e)
            })
    
    def test_monitoring_workflow(self):
        """Test model monitoring workflow"""
        test_name = "monitoring_workflow"
        
        try:
            # Check if monitoring tables exist
            if not self.table_exists('MODEL_MONITORING_CONFIG'):
                self.test_results.append({
                    'name': test_name,
                    'status': 'SKIP',
                    'message': 'Monitoring tables not available',
                    'error': 'MODEL_MONITORING_CONFIG table does not exist'
                })
                return
            
            # Step 1: Create monitoring configuration
            config_result = self.execute_query("""
                INSERT INTO MODEL_MONITORING_CONFIG 
                (MODEL_TYPE_CODE, METRIC_NAME, WARNING_THRESHOLD, CRITICAL_THRESHOLD, THRESHOLD_DIRECTION)
                VALUES ('TEST_TYPE', 'GINI', 0.3, 0.2, 'BELOW')
            """)
            
            # Step 2: Run performance check if procedure exists
            if self.procedure_exists('SP_CHECK_MODEL_PERFORMANCE'):
                performance_result = self.execute_query(
                    "EXEC SP_CHECK_MODEL_PERFORMANCE @SEND_NOTIFICATIONS = 0, @DEBUG = 1"
                )
            
            # Clean up
            self.execute_query("DELETE FROM MODEL_MONITORING_CONFIG WHERE MODEL_TYPE_CODE = 'TEST_TYPE'")
            
            self.test_results.append({
                'name': test_name,
                'status': 'PASS',
                'message': 'Monitoring workflow executed successfully',
                'error': None
            })
            
        except Exception as e:
            self.test_results.append({
                'name': test_name,
                'status': 'ERROR',
                'message': 'Monitoring workflow test',
                'error': str(e)
            })
    
    def test_data_quality_workflow(self):
        """Test data quality logging and tracking workflow"""
        test_name = "data_quality_workflow"
        
        try:
            # Step 1: Create a test data quality issue
            test_table_id = 1  # Assuming at least one source table exists
            
            self.execute_query("""
                INSERT INTO MODEL_DATA_QUALITY_LOG 
                (SOURCE_TABLE_ID, PROCESS_DATE, ISSUE_TYPE, ISSUE_DESCRIPTION, 
                 ISSUE_CATEGORY, SEVERITY, REMEDIATION_STATUS)
                VALUES (?, GETDATE(), 'TEST_ISSUE', 'Integration test quality issue', 
                        'DATA_QUALITY', 'LOW', 'OPEN')
            """, (test_table_id,))
            
            # Step 2: Query quality issues
            quality_issues = self.execute_query("""
                SELECT COUNT(*) FROM MODEL_DATA_QUALITY_LOG 
                WHERE ISSUE_TYPE = 'TEST_ISSUE' AND REMEDIATION_STATUS = 'OPEN'
            """)
            
            if not quality_issues or quality_issues[0][0] == 0:
                raise Exception("Quality issue was not logged properly")
            
            # Step 3: Update remediation status
            self.execute_query("""
                UPDATE MODEL_DATA_QUALITY_LOG 
                SET REMEDIATION_STATUS = 'RESOLVED', RESOLVED_DATE = GETDATE()
                WHERE ISSUE_TYPE = 'TEST_ISSUE'
            """)
            
            # Clean up
            self.execute_query("DELETE FROM MODEL_DATA_QUALITY_LOG WHERE ISSUE_TYPE = 'TEST_ISSUE'")
            
            self.test_results.append({
                'name': test_name,
                'status': 'PASS',
                'message': 'Data quality workflow executed successfully',
                'error': None
            })
            
        except Exception as e:
            self.test_results.append({
                'name': test_name,
                'status': 'ERROR',
                'message': 'Data quality workflow test',
                'error': str(e)
            })
    
    def test_cross_system_integration(self):
        """Test integration between different system components"""
        test_name = "cross_system_integration"
        
        try:
            # Test relationship between models, features, and validation results
            integration_query = """
                SELECT 
                    mr.MODEL_NAME,
                    COUNT(DISTINCT mvr.VALIDATION_ID) as VALIDATION_COUNT,
                    COUNT(DISTINCT fmm.FEATURE_ID) as FEATURE_COUNT
                FROM MODEL_REGISTRY mr
                LEFT JOIN MODEL_VALIDATION_RESULTS mvr ON mr.MODEL_ID = mvr.MODEL_ID
                LEFT JOIN FEATURE_MODEL_MAPPING fmm ON mr.MODEL_ID = fmm.MODEL_ID
                WHERE mr.IS_ACTIVE = 1
                GROUP BY mr.MODEL_ID, mr.MODEL_NAME
                HAVING COUNT(DISTINCT mvr.VALIDATION_ID) > 0 OR COUNT(DISTINCT fmm.FEATURE_ID) > 0
            """
            
            result = self.execute_query(integration_query)
            
            # Test view functionality if available
            views_to_test = [
                'VW_MODEL_PERFORMANCE',
                'VW_FEATURE_CATALOG',
                'VW_DATA_QUALITY_SUMMARY'
            ]
            
            view_test_results = []
            for view_name in views_to_test:
                if self.view_exists(view_name):
                    try:
                        view_result = self.execute_query(f"SELECT TOP 1 * FROM {view_name}")
                        view_test_results.append(f"{view_name}: OK")
                    except Exception as e:
                        view_test_results.append(f"{view_name}: ERROR - {str(e)}")
                else:
                    view_test_results.append(f"{view_name}: NOT_FOUND")
            
            self.test_results.append({
                'name': test_name,
                'status': 'PASS',
                'message': f'Cross-system integration test completed. Views tested: {"; ".join(view_test_results)}',
                'error': None
            })
            
        except Exception as e:
            self.test_results.append({
                'name': test_name,
                'status': 'ERROR',
                'message': 'Cross-system integration test',
                'error': str(e)
            })
    
    def table_exists(self, table_name: str) -> bool:
        """Check if a table exists"""
        result = self.execute_query(
            "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = ?",
            (table_name,)
        )
        return result and result[0][0] > 0
    
    def view_exists(self, view_name: str) -> bool:
        """Check if a view exists"""
        result = self.execute_query(
            "SELECT COUNT(*) FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = ?",
            (view_name,)
        )
        return result and result[0][0] > 0
    
    def procedure_exists(self, proc_name: str) -> bool:
        """Check if a procedure exists"""
        result = self.execute_query(
            "SELECT COUNT(*) FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = ? AND ROUTINE_TYPE = 'PROCEDURE'",
            (proc_name,)
        )
        return result and result[0][0] > 0
    
    def function_exists(self, func_name: str) -> bool:
        """Check if a function exists"""
        result = self.execute_query(
            "SELECT COUNT(*) FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = ? AND ROUTINE_TYPE = 'FUNCTION'",
            (func_name,)
        )
        return result and result[0][0] > 0
    
    def generate_junit_xml(self, output_path: str):
        """Generate JUnit XML report"""
        root = ET.Element('testsuite')
        root.set('name', 'Model Registry Integration Tests')
        root.set('tests', str(len(self.test_results)))
        
        failures = len([t for t in self.test_results if t['status'] == 'FAIL'])
        errors = len([t for t in self.test_results if t['status'] == 'ERROR'])
        skipped = len([t for t in self.test_results if t['status'] == 'SKIP'])
        
        root.set('failures', str(failures))
        root.set('errors', str(errors))
        root.set('skipped', str(skipped))
        
        for test in self.test_results:
            testcase = ET.SubElement(root, 'testcase')
            testcase.set('name', test['name'])
            testcase.set('classname', 'ModelRegistryIntegrationTests')
            
            if test['status'] == 'FAIL':
                failure = ET.SubElement(testcase, 'failure')
                failure.set('message', test['error'] or 'Test failed')
                failure.text = test['message']
            elif test['status'] == 'ERROR':
                error = ET.SubElement(testcase, 'error')
                error.set('message', test['error'] or 'Test error')
                error.text = test['message']
            elif test['status'] == 'SKIP':
                skipped_elem = ET.SubElement(testcase, 'skipped')
                skipped_elem.set('message', test['error'] or 'Test skipped')
                skipped_elem.text = test['message']
        
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        tree = ET.ElementTree(root)
        tree.write(output_path, encoding='utf-8', xml_declaration=True)
    
    def close_connection(self):
        """Close database connection"""
        if self.connection:
            self.connection.close()

def main():
    parser = argparse.ArgumentParser(description='Run Model Registry integration tests')
    parser.add_argument('--database', required=True, help='Database name')
    parser.add_argument('--server', default='localhost', help='Database server')
    parser.add_argument('--output', default='test-reports/integration-tests.xml', help='Output XML file')
    parser.add_argument('--verbose', action='store_true', help='Verbose output')
    
    args = parser.parse_args()
    
    # Build connection string
    connection_string = f"DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={args.server};DATABASE={args.database};Trusted_Connection=yes;"
    
    tester = ModelRegistryIntegrationTester(connection_string)
    
    try:
        print("Running Model Registry integration tests...")
        tester.run_integration_tests()
        
        # Generate report
        tester.generate_junit_xml(args.output)
        
        # Print results
        total_tests = len(tester.test_results)
        passed = len([t for t in tester.test_results if t['status'] == 'PASS'])
        failed = len([t for t in tester.test_results if t['status'] == 'FAIL'])
        errors = len([t for t in tester.test_results if t['status'] == 'ERROR'])
        skipped = len([t for t in tester.test_results if t['status'] == 'SKIP'])
        
        print(f"\nIntegration Test Results:")
        print(f"Total: {total_tests}")
        print(f"Passed: {passed}")
        print(f"Failed: {failed}")
        print(f"Errors: {errors}")
        print(f"Skipped: {skipped}")
        
        if args.verbose:
            print("\nDetailed Results:")
            for test in tester.test_results:
                status_symbol = {"PASS": "✓", "FAIL": "✗", "ERROR": "⚠", "SKIP": "⏭"}[test['status']]
                print(f"{status_symbol} {test['name']}: {test['message']}")
                if test['error']:
                    print(f"   Details: {test['error']}")
        
        # Exit with error code if tests failed
        if failed > 0 or errors > 0:
            sys.exit(1)
        else:
            print("All integration tests passed!")
            sys.exit(0)
            
    finally:
        tester.close_connection()

if __name__ == '__main__':
    main()