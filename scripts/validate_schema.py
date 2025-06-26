#!/usr/bin/env python3
"""
Schema Validation Script for Model Registry
Validates database schema consistency and dependencies
"""

import os
import sys
import re
import argparse
import json
from pathlib import Path
from typing import Dict, List, Set, Tuple
import xml.etree.ElementTree as ET

class SchemaValidator:
    def __init__(self, schema_path: str):
        self.schema_path = Path(schema_path)
        self.tables = {}
        self.foreign_keys = []
        self.dependencies = {}
        self.errors = []
        self.warnings = []
        
    def parse_sql_files(self):
        """Parse all SQL schema files to extract table and dependency information"""
        for sql_file in self.schema_path.glob("*.sql"):
            self._parse_sql_file(sql_file)
    
    def _parse_sql_file(self, file_path: Path):
        """Parse individual SQL file for table definitions and foreign keys"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Extract table name
            table_match = re.search(r'CREATE TABLE\s+(\w+\.)?(\w+)\s*\(', content, re.IGNORECASE)
            if table_match:
                table_name = table_match.group(2)
                self.tables[table_name] = {
                    'file': file_path.name,
                    'columns': self._extract_columns(content),
                    'foreign_keys': self._extract_foreign_keys(content)
                }
                
        except Exception as e:
            self.errors.append(f"Error parsing {file_path.name}: {str(e)}")
    
    def _extract_columns(self, content: str) -> List[str]:
        """Extract column definitions from CREATE TABLE statement"""
        columns = []
        # Simple regex to extract column names (can be improved)
        column_matches = re.findall(r'^\s*(\w+)\s+\w+', content, re.MULTILINE)
        return [col for col in column_matches if col.upper() not in ['CREATE', 'TABLE', 'CONSTRAINT', 'PRIMARY', 'FOREIGN', 'KEY', 'INDEX']]
    
    def _extract_foreign_keys(self, content: str) -> List[Dict]:
        """Extract foreign key constraints"""
        fks = []
        # Extract FOREIGN KEY constraints
        fk_pattern = r'FOREIGN KEY\s*\(([^)]+)\)\s*REFERENCES\s+(\w+\.)?(\w+)\s*\(([^)]+)\)'
        matches = re.findall(fk_pattern, content, re.IGNORECASE)
        
        for match in matches:
            fks.append({
                'column': match[0].strip(),
                'references_table': match[2],
                'references_column': match[3].strip()
            })
        
        return fks
    
    def validate_dependencies(self):
        """Validate that all foreign key dependencies exist"""
        for table_name, table_info in self.tables.items():
            for fk in table_info['foreign_keys']:
                ref_table = fk['references_table']
                if ref_table not in self.tables:
                    self.errors.append(f"Table {table_name} references non-existent table {ref_table}")
                else:
                    ref_columns = self.tables[ref_table]['columns']
                    if fk['references_column'] not in ref_columns:
                        self.errors.append(f"Table {table_name} references non-existent column {ref_table}.{fk['references_column']}")
    
    def validate_naming_conventions(self):
        """Validate naming conventions"""
        for table_name in self.tables.keys():
            # Check table naming convention (should be uppercase with underscores)
            if not re.match(r'^[A-Z][A-Z0-9_]*$', table_name):
                self.warnings.append(f"Table {table_name} doesn't follow naming convention (uppercase with underscores)")
    
    def generate_dependency_order(self) -> List[str]:
        """Generate correct order for table creation based on dependencies"""
        ordered_tables = []
        remaining_tables = set(self.tables.keys())
        
        while remaining_tables:
            # Find tables with no dependencies on remaining tables
            independent_tables = []
            for table in remaining_tables:
                dependencies = [fk['references_table'] for fk in self.tables[table]['foreign_keys']]
                if not any(dep in remaining_tables for dep in dependencies):
                    independent_tables.append(table)
            
            if not independent_tables:
                # Circular dependency detected
                self.errors.append(f"Circular dependency detected among tables: {', '.join(remaining_tables)}")
                break
            
            ordered_tables.extend(independent_tables)
            remaining_tables -= set(independent_tables)
        
        return ordered_tables
    
    def generate_report(self) -> Dict:
        """Generate validation report"""
        return {
            'total_tables': len(self.tables),
            'errors': self.errors,
            'warnings': self.warnings,
            'tables': self.tables,
            'dependency_order': self.generate_dependency_order()
        }
    
    def generate_junit_xml(self, output_path: str):
        """Generate JUnit XML report for CI/CD integration"""
        root = ET.Element('testsuite')
        root.set('name', 'Schema Validation')
        root.set('tests', str(len(self.tables) + 2))  # +2 for dependency and naming tests
        root.set('failures', str(len(self.errors)))
        root.set('errors', '0')
        
        # Test case for each table
        for table_name, table_info in self.tables.items():
            testcase = ET.SubElement(root, 'testcase')
            testcase.set('name', f'validate_table_{table_name}')
            testcase.set('classname', 'SchemaValidation')
            
            # Check if this table has any errors
            table_errors = [err for err in self.errors if table_name in err]
            if table_errors:
                failure = ET.SubElement(testcase, 'failure')
                failure.set('message', f'Table {table_name} validation failed')
                failure.text = '\n'.join(table_errors)
        
        # Test case for dependency validation
        dep_testcase = ET.SubElement(root, 'testcase')
        dep_testcase.set('name', 'validate_dependencies')
        dep_testcase.set('classname', 'SchemaValidation')
        
        dep_errors = [err for err in self.errors if 'references' in err or 'Circular' in err]
        if dep_errors:
            failure = ET.SubElement(dep_testcase, 'failure')
            failure.set('message', 'Dependency validation failed')
            failure.text = '\n'.join(dep_errors)
        
        # Test case for naming conventions
        naming_testcase = ET.SubElement(root, 'testcase')
        naming_testcase.set('name', 'validate_naming_conventions')
        naming_testcase.set('classname', 'SchemaValidation')
        
        if self.warnings:
            system_out = ET.SubElement(naming_testcase, 'system-out')
            system_out.text = '\n'.join(self.warnings)
        
        # Write XML file
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        tree = ET.ElementTree(root)
        tree.write(output_path, encoding='utf-8', xml_declaration=True)

def main():
    parser = argparse.ArgumentParser(description='Validate Model Registry database schema')
    parser.add_argument('--schema-path', default='database/schema', help='Path to schema files')
    parser.add_argument('--output', default='test-reports/schema-validation.xml', help='Output path for JUnit XML')
    parser.add_argument('--verbose', action='store_true', help='Verbose output')
    
    args = parser.parse_args()
    
    validator = SchemaValidator(args.schema_path)
    validator.parse_sql_files()
    validator.validate_dependencies()
    validator.validate_naming_conventions()
    
    report = validator.generate_report()
    
    if args.verbose:
        print(f"Total tables found: {report['total_tables']}")
        print(f"Errors: {len(report['errors'])}")
        print(f"Warnings: {len(report['warnings'])}")
        
        if report['errors']:
            print("\nErrors:")
            for error in report['errors']:
                print(f"  - {error}")
        
        if report['warnings']:
            print("\nWarnings:")
            for warning in report['warnings']:
                print(f"  - {warning}")
        
        print(f"\nRecommended table creation order:")
        for i, table in enumerate(report['dependency_order'], 1):
            print(f"  {i}. {table}")
    
    # Generate JUnit XML report
    validator.generate_junit_xml(args.output)
    
    # Exit with error code if there are errors
    if report['errors']:
        print(f"Schema validation failed with {len(report['errors'])} errors")
        sys.exit(1)
    else:
        print("Schema validation passed")
        sys.exit(0)

if __name__ == '__main__':
    main()