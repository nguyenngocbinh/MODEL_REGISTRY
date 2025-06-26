"""
Simple Excel Upload Script for Model Registry
Uploads data from Excel files to SQL Server database
"""
import pandas as pd
import pyodbc
import logging
import sys
import os
from datetime import datetime
from typing import Dict, List, Tuple

# Database configuration
DB_CONFIG = {
    'server': 'localhost',
    'database': 'MODEL_REGISTRY',
    'driver': 'ODBC Driver 17 for SQL Server',
    'trusted_connection': 'yes'
}

# Table configurations
TABLE_CONFIGS = {
    'model_type': {
        'table_name': 'MODEL_TYPE',
        'required_columns': ['TYPE_CODE', 'TYPE_NAME'],
        'unique_columns': ['TYPE_CODE'],
        'identity_column': 'TYPE_ID'
    },
    'model_registry': {
        'table_name': 'MODEL_REGISTRY',
        'required_columns': ['MODEL_NAME', 'MODEL_VERSION', 'SOURCE_DATABASE', 'SOURCE_SCHEMA', 'SOURCE_TABLE_NAME', 'EFF_DATE', 'EXP_DATE'],
        'unique_columns': ['MODEL_NAME', 'MODEL_VERSION'],
        'identity_column': 'MODEL_ID',
        'foreign_keys': {'TYPE_ID': 'MODEL_TYPE(TYPE_ID)'}
    },
    'feature_registry': {
        'table_name': 'FEATURE_REGISTRY',
        'required_columns': ['FEATURE_NAME', 'FEATURE_CODE', 'DATA_TYPE', 'VALUE_TYPE', 'SOURCE_SYSTEM'],
        'unique_columns': ['FEATURE_CODE', 'FEATURE_NAME'],
        'identity_column': 'FEATURE_ID'
    }
}

class SimpleExcelUploader:
    def __init__(self, table_name: str):
        self.table_name = table_name
        self.config = TABLE_CONFIGS.get(table_name)
        
        if not self.config:
            raise ValueError(f"Unknown table: {table_name}")
        
        # Setup logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)
        
    def connect_database(self):
        """Connect to SQL Server database"""
        try:
            if DB_CONFIG['trusted_connection'] == 'yes':
                conn_str = (
                    f"DRIVER={{{DB_CONFIG['driver']}}};"
                    f"SERVER={DB_CONFIG['server']};"
                    f"DATABASE={DB_CONFIG['database']};"
                    f"Trusted_Connection=yes;"
                )
            else:
                conn_str = (
                    f"DRIVER={{{DB_CONFIG['driver']}}};"
                    f"SERVER={DB_CONFIG['server']};"
                    f"DATABASE={DB_CONFIG['database']};"
                    f"UID={DB_CONFIG.get('username')};"
                    f"PWD={DB_CONFIG.get('password')};"
                )
            
            return pyodbc.connect(conn_str)
            
        except Exception as e:
            self.logger.error(f"Database connection failed: {str(e)}")
            return None
    
    def read_excel(self, file_path: str):
        """Read Excel file"""
        try:
            df = pd.read_excel(file_path, sheet_name=0)
            df = df.dropna(how='all')  # Remove empty rows
            
            # Clean string columns
            for col in df.select_dtypes(include=['object']).columns:
                df[col] = df[col].astype(str).str.strip()
            
            self.logger.info(f"Loaded {len(df)} rows from {file_path}")
            return df
            
        except Exception as e:
            self.logger.error(f"Error reading Excel file: {str(e)}")
            return None
    
    def validate_data(self, df):
        """Basic data validation"""
        errors = []
        
        # Check required columns
        missing_cols = set(self.config['required_columns']) - set(df.columns)
        if missing_cols:
            errors.append(f"Missing required columns: {missing_cols}")
        
        # Check for empty required fields
        for col in self.config['required_columns']:
            if col in df.columns:
                empty_count = df[col].isna().sum()
                if empty_count > 0:
                    errors.append(f"Column '{col}' has {empty_count} empty values")
        
        # Check unique constraints
        for unique_col in self.config['unique_columns']:
            if isinstance(unique_col, str):
                unique_cols = [unique_col]
            else:
                unique_cols = unique_col
            
            if all(col in df.columns for col in unique_cols):
                duplicates = df[unique_cols].duplicated().sum()
                if duplicates > 0:
                    errors.append(f"Duplicate values in unique columns: {unique_cols}")
        
        return errors
    
    def upload_data(self, df, connection):
        """Upload data to database"""
        try:
            # Remove identity column if present
            upload_df = df.copy()
            if self.config['identity_column'] in upload_df.columns:
                upload_df = upload_df.drop(columns=[self.config['identity_column']])
            
            # Handle boolean columns
            bool_cols = ['IS_ACTIVE', 'IS_PII', 'IS_SENSITIVE']
            for col in bool_cols:
                if col in upload_df.columns:
                    upload_df[col] = upload_df[col].map({True: 1, False: 0, 'True': 1, 'False': 0, 1: 1, 0: 0})
            
            # Generate INSERT statement
            columns = list(upload_df.columns)
            placeholders = ','.join(['?' for _ in columns])
            insert_query = f"INSERT INTO {self.config['table_name']} ({','.join(columns)}) VALUES ({placeholders})"
            
            # Execute inserts
            cursor = connection.cursor()
            uploaded_count = 0
            
            for _, row in upload_df.iterrows():
                values = [row[col] if pd.notna(row[col]) else None for col in columns]
                cursor.execute(insert_query, values)
                uploaded_count += 1
            
            connection.commit()
            self.logger.info(f"Successfully uploaded {uploaded_count} rows")
            return True, uploaded_count
            
        except Exception as e:
            connection.rollback()
            self.logger.error(f"Upload failed: {str(e)}")
            return False, 0
    
    def process_file(self, file_path: str):
        """Main method to process Excel file"""
        print(f"Processing {self.table_name} upload...")
        
        # Connect to database
        connection = self.connect_database()
        if not connection:
            return False
        
        try:
            # Read Excel file
            df = self.read_excel(file_path)
            if df is None:
                return False
            
            # Validate data
            print("Validating data...")
            validation_errors = self.validate_data(df)
            
            if validation_errors:
                print("Validation failed:")
                for error in validation_errors:
                    print(f"  - {error}")
                return False
            
            print("Data validation passed")
            
            # Upload data
            print("Uploading data...")
            success, uploaded_count = self.upload_data(df, connection)
            
            if success:
                print(f"Upload successful: {uploaded_count} rows uploaded")
                return True
            else:
                print("Upload failed")
                return False
                
        finally:
            connection.close()

def main():
    """Main function"""
    if len(sys.argv) < 3:
        print("Usage: python simple_upload.py <table_name> <excel_file_path>")
        print("Available tables:", list(TABLE_CONFIGS.keys()))
        sys.exit(1)
    
    table_name = sys.argv[1]
    excel_file = sys.argv[2]
    
    if not os.path.exists(excel_file):
        print(f"Excel file not found: {excel_file}")
        sys.exit(1)
    
    try:
        uploader = SimpleExcelUploader(table_name)
        success = uploader.process_file(excel_file)
        sys.exit(0 if success else 1)
        
    except Exception as e:
        print(f"Error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main() 