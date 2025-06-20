#!/usr/bin/env python3
"""
Unit Test Runner for Model Registry
Tests stored procedures, functions, and database logic
"""

import os
import sys
import argparse
import pyodbc
import json
from datetime import datetime
from pathlib import Path
import xml.etree.ElementTree as ET

class ModelRegistryUnitTester:
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
            
            # Try to fetch results
            try:
                return cursor.fetchall()
            except:
                return None
        except Exception as e:
            raise Exception(f"Query execution failed: {e}")
        finally:
            cursor.close()
    
    def test_stored_procedure(self, proc_name: str, test_cases: list):
        """Test a stored procedure with multiple test cases"""
        for i, test_case in enumerate(test_cases):
            test_name = f"{proc_name}_test_{i+1}"
            try:
                # Execute the stored procedure
                params = test_case.get('params', {})
                param_list = [params.get(p, None) for p in test_case.get('param_order', [])]
                
                query = f"EXEC {proc_name} " + ", ".join(['?' for _ in param_list])
                result = self.execute_query(query, tuple(param_list))
                
                # Validate result
                expected = test_case.get('expected', {})
                success = self.validate_result(result, expected, test_case.get('validation_type', 'row_count'))
                
                self.test_results.append({
                    'name': test_name,
                    'status': 'PASS' if success else 'FAIL',
                    'message': test_case.get('description', ''),
                    'error': None if success else f"Validation failed for {proc_name}"
                })
                
            except Exception as e:
                self.test_results.append({
                    'name': test_name,
                    'status': 'ERROR',
                    'message': test_case.get('description', ''),
                    'error': str(e)
                })
    
    def test_function(self, func_name: str, test_cases: list):
        """Test a scalar function with multiple test cases"""
        for i, test_case in enumerate(test_cases):
            test_name = f"{func_name}_test_{i+1}"
            try:
                # Execute the function
                params = test_case.get('params', {})
                param_list = [params.get(p, None) for p in test_case.get('param_order', [])]
                
                query = f"SELECT dbo.{func_name}(" + ", ".join(['?' for _ in param_list]) + ")"
                result = self.execute_query(query, tuple(param_list))
                
                # Validate result
                expected = test_case.get('expected')
                actual = result[0][0] if result and len(result) > 0 else None
                success = (actual == expected)
                
                self.test_results.append({
                    'name': test_name,
                    'status': 'PASS' if success else 'FAIL',
                    'message': test_case.get('description', ''),
                    'error': None if success else f"Expected {expected}, got {actual}"
                })
                
            except Exception as e:
                self.test_results.append({
                    'name': test_name,
                    'status': 'ERROR',
                    'message': test_case.get('description', ''),
                    'error': str(e)
                })
    
    def validate_result(self, result, expected, validation_type):
        """Validate query results based on validation type"""
        if validation_type == 'row_count':
            expected_count = expected.get('row_count', 0)
            actual_count = len(result) if result else 0
            return actual_count >= expected_count
        
        elif validation_type == 'not_empty':
            return result is not None and len(result) > 0
        
        elif validation_type == 'contains_columns':
            if not result or len(result) == 0:
                return False
            expected_columns = expected.get('columns', [])
            # This is a simplified check - in practice you'd check column names
            return len(result[0]) >= len(expected_columns)
        
        return True
    
    def run_all_tests(self):
        """Run all predefined unit tests"""
        
        # Test GET_MODEL_FEATURES procedure
        self.test_stored_procedure('GET_MODEL_FEATURES', [
            {
                'description': 'Test getting features for valid model',
                'params': {'MODEL_ID': 1, 'AS_OF_DATE': None, 'INCLUDE_INACTIVE': 0},
                'param_order': ['MODEL_ID', 'AS_OF_DATE', 'INCLUDE_INACTIVE'],
                'expected': {'row_count': 1},
                'validation_type': 'row_count'
            }
        ])
        
        # Test REGISTER_NEW_MODEL procedure
        self.test_stored_procedure('REGISTER_NEW_MODEL', [
            {
                'description': 'Test registering a new model',
                'params': {
                    'MODEL_NAME': 'TEST_MODEL_CI',
                    'MODEL_VERSION': '1.0',
                    'MODEL_TYPE_CODE': 'PD',
                    'SOURCE_DATABASE': 'TEST_DB',
                    'SOURCE_SCHEMA': 'dbo',
                    'SOURCE_TABLE_NAME': 'TEST_OUTPUT'
                },
                'param_order': ['MODEL_NAME', 'MODEL_VERSION', 'MODEL_TYPE_CODE', 
                              'SOURCE_DATABASE', 'SOURCE_SCHEMA', 'SOURCE_TABLE_NAME'],
                'expected': {'row_count': 1},
                'validation_type': 'not_empty'
            }
        ])
        
        # Test FN_CALCULATE_PSI function
        self.test_function('FN_CALCULATE_PSI', [
            {
                'description': 'Test PSI calculation with valid inputs',
                'params': {'expected_dist': 0.5, 'actual_dist': 0.6},
                'param_order': ['expected_dist', 'actual_dist'],
                'expected': 0.02  # Expected PSI value
            }
        ])
        
        # Test CHECK_MODEL_DEPENDENCIES procedure
        self.test_stored_procedure('CHECK_MODEL_DEPENDENCIES', [
            {
                'description': 'Test dependency check for model',
                'params': {'MODEL_ID': 1, 'AS_OF_DATE': None},
                'param_order': ['MODEL_ID', 'AS_OF_DATE'],
                'expected': {'row_count': 0},
                'validation_type': 'row_count'
            }
        ])
        
        # Test feature validation
        self.test_basic_queries()
    
    def test_basic_queries(self):
        """Test basic database queries and data integrity"""
        
        # Test 1: Check if essential tables exist
        test_name = "check_essential_tables"
        try:
            tables_to_check = [
                'MODEL_REGISTRY', 'MODEL_TYPE', 'FEATURE_REGISTRY',
                'MODEL_VALIDATION_RESULTS', 'FEATURE_STATS'
            ]
            
            missing_tables = []
            for table in tables_to_check:
                result = self.execute_query(
                    "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = ?",
                    (table,)
                )
                if not result or result[0][0] == 0:
                    missing_tables.append(table)
            
            success = len(missing_tables) == 0
            self.test_results.append({
                'name': test_name,
                'status': 'PASS' if success else 'FAIL',
                'message': 'Check if essential tables exist',
                'error': f"Missing tables: {missing_tables}" if missing_tables else None
            })
            
        except Exception as e:
            self.test_results.append({
                'name': test_name,
                'status': 'ERROR',
                'message': 'Check if essential tables exist',
                'error': str(e)
            })
        
        # Test 2: Check referential integrity
        test_name = "check_referential_integrity"
        try:
            # Check if there are any orphaned records
            orphan_checks = [
                ("MODEL_REGISTRY with invalid TYPE_ID", 
                 "SELECT COUNT(*) FROM MODEL_REGISTRY mr LEFT JOIN MODEL_TYPE mt ON mr.TYPE_ID = mt.TYPE_ID WHERE mt.TYPE_ID IS NULL"),
                ("FEATURE_STATS with invalid FEATURE_ID",
                 "SELECT COUNT(*) FROM FEATURE_STATS fs LEFT JOIN FEATURE_REGISTRY fr ON fs.FEATURE_ID = fr.FEATURE_ID WHERE fr.FEATURE_ID IS NULL")
            ]
            
            integrity_issues = []
            for check_name, query in orphan_checks:
                result = self.execute_query(query)
                if result and result[0][0] > 0:
                    integrity_issues.append(f"{check_name}: {result[0][0]} orphaned records")
            
            success = len(integrity_issues) == 0
            self.test_results.append({
                'name': test_name,
                'status': 'PASS' if success else 'FAIL',
                'message': 'Check referential integrity',
                'error': "; ".join(integrity_issues) if integrity_issues else None
            })
            
        except Exception as e:
            self.test_results.append({
                'name': test_name,
                'status': 'ERROR',
                'message': 'Check referential integrity', 
                'error': str(e)
            })
    
    def cleanup_test_data(self):
        """Clean up any test data created during testing"""
        try:
            # Remove test model if it exists
            self.execute_query("DELETE FROM MODEL_REGISTRY WHERE MODEL_NAME = 'TEST_MODEL_CI'")
        except:
            pass  # Ignore cleanup errors
    
    def generate_junit_xml(self, output_path: str):
        """Generate JUnit XML report"""
        root = ET.Element('testsuite')
        root.set('name', 'Model Registry Unit Tests')
        root.set('tests', str(len(self.test_results)))
        
        failures = len([t for t in self.test_results if t['status'] == 'FAIL'])
        errors = len([t for t in self.test_results if t['status'] == 'ERROR'])
        
        root.set('failures', str(failures))
        root.set('errors', str(errors))
        
        for test in self.test_results:
            testcase = ET.SubElement(root, 'testcase')
            testcase.set('name', test['name'])
            testcase.set('classname', 'ModelRegistryUnitTests')
            
            if test['status'] == 'FAIL':
                failure = ET.SubElement(testcase, 'failure')
                failure.set('message', test['error'] or 'Test failed')
                failure.text = test['message']
            elif test['status'] == 'ERROR':
                error = ET.SubElement(testcase, 'error')
                error.set('message', test['error'] or 'Test error')
                error.text = test['message']
        
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        tree = ET.ElementTree(root)
        tree.write(output_path, encoding='utf-8', xml_declaration=True)
    
    def close_connection(self):
        """Close database connection"""
        if self.connection:
            self.connection.close()

def main():
    parser = argparse.ArgumentParser(description='Run Model Registry unit tests')
    parser.add_argument('--database', required=True, help='Database name')
    parser.add_argument('--server', default='localhost', help='Database server')
    parser.add_argument('--output', default='test-reports/unit-tests.xml', help='Output XML file')
    parser.add_argument('--verbose', action='store_true', help='Verbose output')
    
    args = parser.parse_args()
    
    # Build connection string
    connection_string = f"DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={args.server};DATABASE={args.database};Trusted_Connection=yes;"
    
    tester = ModelRegistryUnitTester(connection_string)
    
    try:
        print("Running Model Registry unit tests...")
        tester.run_all_tests()
        
        # Generate report
        tester.generate_junit_xml(args.output)
        
        # Print results
        total_tests = len(tester.test_results)
        passed = len([t for t in tester.test_results if t['status'] == 'PASS'])
        failed = len([t for t in tester.test_results if t['status'] == 'FAIL'])
        errors = len([t for t in tester.test_results if t['status'] == 'ERROR'])
        
        print(f"\nTest Results:")
        print(f"Total: {total_tests}")
        print(f"Passed: {passed}")
        print(f"Failed: {failed}")
        print(f"Errors: {errors}")
        
        if args.verbose:
            print("\nDetailed Results:")
            for test in tester.test_results:
                status_symbol = "✓" if test['status'] == 'PASS' else "✗"
                print(f"{status_symbol} {test['name']}: {test['message']}")
                if test['error']:
                    print(f"   Error: {test['error']}")
        
        # Clean up test data
        tester.cleanup_test_data()
        
        # Exit with error code if tests failed
        if failed > 0 or errors > 0:
            sys.exit(1)
        else:
            print("All tests passed!")
            sys.exit(0)
            
    finally:
        tester.close_connection()

if __name__ == '__main__':
    main()