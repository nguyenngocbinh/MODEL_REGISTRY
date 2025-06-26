"""
Excel Upload Script for Model Registry
Handles data validation and upload from Excel files to SQL Server database
"""
import pandas as pd
import pyodbc
import logging
import sys
import os
from datetime import datetime
from typing import Dict, List, Tuple, Optional
from tqdm import tqdm
from colorama import init, Fore, Style
import json

# Import configuration
from config import DB_CONFIG, UPLOAD_CONFIG, TABLE_MAPPINGS, DATA_TYPE_MAPPINGS, VALUE_TYPE_MAPPINGS

# Initialize colorama for colored output
init()

class ExcelUploader:
    """Main class for handling Excel file uploads to Model Registry database"""
    
    def __init__(self, table_name: str):
        """
        Initialize the uploader for a specific table
        
        Args:
            table_name: Name of the table to upload to (e.g., 'model_type', 'feature_registry')
        """
        self.table_name = table_name
        self.table_config = TABLE_MAPPINGS.get(table_name)
        
        if not self.table_config:
            raise ValueError(f"Unknown table: {table_name}")
        
        self.db_table = self.table_config['table_name']
        self.required_columns = self.table_config['required_columns']
        self.unique_columns = self.table_config['unique_columns']
        self.identity_column = self.table_config['identity_column']
        self.foreign_keys = self.table_config.get('foreign_keys', {})
        
        # Setup logging
        self.setup_logging()
        
        # Database connection
        self.connection = None
        
    def setup_logging(self):
        """Setup logging configuration"""
        log_dir = "logs"
        if not os.path.exists(log_dir):
            os.makedirs(log_dir)
            
        log_file = f"{log_dir}/excel_upload_{self.table_name}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
        
        logging.basicConfig(
            level=getattr(logging, UPLOAD_CONFIG['log_level']),
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file, encoding='utf-8'),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger(__name__)
        
    def connect_database(self) -> bool:
        """Establish database connection"""
        try:
            if DB_CONFIG['trusted_connection'] == 'yes':
                connection_string = (
                    f"DRIVER={{{DB_CONFIG['driver']}}};"
                    f"SERVER={DB_CONFIG['server']};"
                    f"DATABASE={DB_CONFIG['database']};"
                    f"Trusted_Connection=yes;"
                )
            else:
                connection_string = (
                    f"DRIVER={{{DB_CONFIG['driver']}}};"
                    f"SERVER={DB_CONFIG['server']};"
                    f"DATABASE={DB_CONFIG['database']};"
                    f"UID={DB_CONFIG['username']};"
                    f"PWD={DB_CONFIG['password']};"
                )
            
            self.connection = pyodbc.connect(connection_string)
            self.logger.info(f"Connected to database: {DB_CONFIG['database']}")
            return True
            
        except Exception as e:
            self.logger.error(f"Database connection failed: {str(e)}")
            return False
    
    def read_excel_file(self, file_path: str) -> Optional[pd.DataFrame]:
        """Read Excel file and return DataFrame"""
        try:
            self.logger.info(f"Reading Excel file: {file_path}")
            df = pd.read_excel(file_path, sheet_name=0)
            
            # Remove empty rows
            df = df.dropna(how='all')
            
            # Strip whitespace from string columns
            for col in df.select_dtypes(include=['object']).columns:
                df[col] = df[col].astype(str).str.strip()
            
            self.logger.info(f"Loaded {len(df)} rows from Excel file")
            return df
            
        except Exception as e:
            self.logger.error(f"Error reading Excel file: {str(e)}")
            return None
    
    def validate_data(self, df: pd.DataFrame) -> Tuple[bool, List[str]]:
        """Validate data before upload"""
        errors = []
        
        # Check required columns
        missing_columns = set(self.required_columns) - set(df.columns)
        if missing_columns:
            errors.append(f"Missing required columns: {missing_columns}")
        
        # Check for empty required fields
        for col in self.required_columns:
            if col in df.columns:
                empty_count = df[col].isna().sum()
                if empty_count > 0:
                    errors.append(f"Column '{col}' has {empty_count} empty values")
        
        # Check unique constraints
        for unique_cols in self.unique_columns:
            if isinstance(unique_cols, str):
                unique_cols = [unique_cols]
            
            if all(col in df.columns for col in unique_cols):
                duplicates = df[unique_cols].duplicated().sum()
                if duplicates > 0:
                    errors.append(f"Duplicate values found in unique columns: {unique_cols} ({duplicates} duplicates)")
        
        # Validate foreign keys
        for fk_col, fk_ref in self.foreign_keys.items():
            if fk_col in df.columns:
                errors.extend(self.validate_foreign_key(df, fk_col, fk_ref))
        
        # Validate data types
        errors.extend(self.validate_data_types(df))
        
        return len(errors) == 0, errors
    
    def validate_foreign_key(self, df: pd.DataFrame, fk_col: str, fk_ref: str) -> List[str]:
        """Validate foreign key constraints"""
        errors = []
        
        try:
            # Extract referenced table and column
            ref_table, ref_col = fk_ref.split('(')
            ref_col = ref_col.rstrip(')')
            
            # Get unique values from foreign key column
            fk_values = df[fk_col].dropna().unique()
            
            if len(fk_values) > 0:
                # Query referenced table
                query = f"SELECT DISTINCT {ref_col} FROM {ref_table} WHERE {ref_col} IN ({','.join(['?' for _ in fk_values])})"
                cursor = self.connection.cursor()
                cursor.execute(query, fk_values)
                existing_values = {row[0] for row in cursor.fetchall()}
                
                # Find invalid foreign keys
                invalid_values = set(fk_values) - existing_values
                if invalid_values:
                    errors.append(f"Invalid foreign key values in '{fk_col}': {invalid_values}")
                    
        except Exception as e:
            errors.append(f"Error validating foreign key '{fk_col}': {str(e)}")
        
        return errors
    
    def validate_data_types(self, df: pd.DataFrame) -> List[str]:
        """Validate data types for specific columns"""
        errors = []
        
        # Date validation
        date_columns = ['EFF_DATE', 'EXP_DATE', 'VALIDATION_DATE', 'CREATED_DATE', 'UPDATED_DATE']
        for col in date_columns:
            if col in df.columns:
                try:
                    pd.to_datetime(df[col], errors='raise')
                except:
                    errors.append(f"Invalid date format in column '{col}'")
        
        # Boolean validation
        bool_columns = ['IS_ACTIVE', 'IS_PII', 'IS_SENSITIVE']
        for col in bool_columns:
            if col in df.columns:
                invalid_bools = df[col].dropna().apply(lambda x: x not in [True, False, 1, 0, '1', '0', 'True', 'False'])
                if invalid_bools.any():
                    errors.append(f"Invalid boolean values in column '{col}'")
        
        # Numeric validation
        numeric_columns = ['PRIORITY', 'TYPE_ID', 'MODEL_ID', 'FEATURE_ID']
        for col in numeric_columns:
            if col in df.columns:
                try:
                    pd.to_numeric(df[col], errors='raise')
                except:
                    errors.append(f"Invalid numeric values in column '{col}'")
        
        return errors
    
    def backup_table(self) -> bool:
        """Create backup of target table before upload"""
        if not UPLOAD_CONFIG['backup_before_upload']:
            return True
            
        try:
            backup_table_name = f"{self.db_table}_BACKUP_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
            backup_query = f"SELECT * INTO {backup_table_name} FROM {self.db_table}"
            
            cursor = self.connection.cursor()
            cursor.execute(backup_query)
            self.connection.commit()
            
            self.logger.info(f"Created backup table: {backup_table_name}")
            return True
            
        except Exception as e:
            self.logger.error(f"Backup failed: {str(e)}")
            return False
    
    def upload_data(self, df: pd.DataFrame) -> Tuple[bool, int, List[str]]:
        """Upload data to database"""
        errors = []
        uploaded_count = 0
        
        try:
            # Create backup
            if not self.backup_table():
                return False, 0, ["Backup failed"]
            
            # Prepare data for upload
            upload_df = df.copy()
            
            # Remove identity column if present
            if self.identity_column in upload_df.columns:
                upload_df = upload_df.drop(columns=[self.identity_column])
            
            # Handle boolean columns
            bool_columns = ['IS_ACTIVE', 'IS_PII', 'IS_SENSITIVE']
            for col in bool_columns:
                if col in upload_df.columns:
                    upload_df[col] = upload_df[col].map({True: 1, False: 0, 'True': 1, 'False': 0, 1: 1, 0: 0})
            
            # Upload in batches
            batch_size = UPLOAD_CONFIG['batch_size']
            total_batches = (len(upload_df) + batch_size - 1) // batch_size
            
            with tqdm(total=len(upload_df), desc=f"Uploading to {self.db_table}") as pbar:
                for i in range(0, len(upload_df), batch_size):
                    batch_df = upload_df.iloc[i:i+batch_size]
                    
                    try:
                        # Generate INSERT statement
                        columns = list(batch_df.columns)
                        placeholders = ','.join(['?' for _ in columns])
                        insert_query = f"INSERT INTO {self.db_table} ({','.join(columns)}) VALUES ({placeholders})"
                        
                        # Execute batch insert
                        cursor = self.connection.cursor()
                        for _, row in batch_df.iterrows():
                            values = [row[col] if pd.notna(row[col]) else None for col in columns]
                            cursor.execute(insert_query, values)
                        
                        self.connection.commit()
                        uploaded_count += len(batch_df)
                        pbar.update(len(batch_df))
                        
                    except Exception as e:
                        self.connection.rollback()
                        errors.append(f"Batch {i//batch_size + 1} failed: {str(e)}")
                        
                        if len(errors) >= UPLOAD_CONFIG['max_errors']:
                            break
            
            success = len(errors) == 0
            self.logger.info(f"Upload completed: {uploaded_count} rows uploaded, {len(errors)} errors")
            
            return success, uploaded_count, errors
            
        except Exception as e:
            self.logger.error(f"Upload failed: {str(e)}")
            return False, 0, [str(e)]
    
    def process_file(self, file_path: str) -> bool:
        """Main method to process Excel file upload"""
        print(f"{Fore.CYAN}Processing {self.table_name} upload...{Style.RESET_ALL}")
        
        # Connect to database
        if not self.connect_database():
            return False
        
        try:
            # Read Excel file
            df = self.read_excel_file(file_path)
            if df is None:
                return False
            
            # Validate data
            print(f"{Fore.YELLOW}Validating data...{Style.RESET_ALL}")
            is_valid, validation_errors = self.validate_data(df)
            
            if not is_valid:
                print(f"{Fore.RED}Validation failed:{Style.RESET_ALL}")
                for error in validation_errors:
                    print(f"  - {error}")
                return False
            
            print(f"{Fore.GREEN}Data validation passed{Style.RESET_ALL}")
            
            # Upload data
            print(f"{Fore.YELLOW}Uploading data...{Style.RESET_ALL}")
            success, uploaded_count, upload_errors = self.upload_data(df)
            
            if success:
                print(f"{Fore.GREEN}Upload successful: {uploaded_count} rows uploaded{Style.RESET_ALL}")
                return True
            else:
                print(f"{Fore.RED}Upload failed:{Style.RESET_ALL}")
                for error in upload_errors:
                    print(f"  - {error}")
                return False
                
        finally:
            if self.connection:
                self.connection.close()

def main():
    """Main function to run the upload script"""
    if len(sys.argv) < 3:
        print("Usage: python excel_upload.py <table_name> <excel_file_path>")
        print("Available tables:", list(TABLE_MAPPINGS.keys()))
        sys.exit(1)
    
    table_name = sys.argv[1]
    excel_file = sys.argv[2]
    
    if not os.path.exists(excel_file):
        print(f"Excel file not found: {excel_file}")
        sys.exit(1)
    
    try:
        uploader = ExcelUploader(table_name)
        success = uploader.process_file(excel_file)
        sys.exit(0 if success else 1)
        
    except Exception as e:
        print(f"Error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main() 