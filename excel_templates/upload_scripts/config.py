"""
Configuration file for Excel upload scripts
"""
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Database Configuration
DB_CONFIG = {
    'server': os.getenv('DB_SERVER', 'localhost'),
    'database': os.getenv('DB_NAME', 'MODEL_REGISTRY'),
    'driver': os.getenv('DB_DRIVER', 'ODBC Driver 17 for SQL Server'),
    'trusted_connection': os.getenv('DB_TRUSTED_CONNECTION', 'yes'),
    'username': os.getenv('DB_USERNAME', ''),
    'password': os.getenv('DB_PASSWORD', '')
}

# Upload Configuration
UPLOAD_CONFIG = {
    'batch_size': int(os.getenv('BATCH_SIZE', '1000')),
    'max_errors': int(os.getenv('MAX_ERRORS', '100')),
    'log_level': os.getenv('LOG_LEVEL', 'INFO'),
    'backup_before_upload': os.getenv('BACKUP_BEFORE_UPLOAD', 'true').lower() == 'true'
}

# Table Mappings
TABLE_MAPPINGS = {
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
        'foreign_keys': {
            'TYPE_ID': 'MODEL_TYPE(TYPE_ID)'
        }
    },
    'feature_registry': {
        'table_name': 'FEATURE_REGISTRY',
        'required_columns': ['FEATURE_NAME', 'FEATURE_CODE', 'DATA_TYPE', 'VALUE_TYPE', 'SOURCE_SYSTEM'],
        'unique_columns': ['FEATURE_CODE', 'FEATURE_NAME'],
        'identity_column': 'FEATURE_ID'
    },
    'model_parameters': {
        'table_name': 'MODEL_PARAMETERS',
        'required_columns': ['MODEL_ID', 'PARAMETER_NAME', 'PARAMETER_VALUE'],
        'unique_columns': ['MODEL_ID', 'PARAMETER_NAME'],
        'identity_column': 'PARAMETER_ID',
        'foreign_keys': {
            'MODEL_ID': 'MODEL_REGISTRY(MODEL_ID)'
        }
    },
    'model_source_tables': {
        'table_name': 'MODEL_SOURCE_TABLES',
        'required_columns': ['MODEL_ID', 'SOURCE_DATABASE', 'SOURCE_SCHEMA', 'SOURCE_TABLE_NAME'],
        'unique_columns': ['MODEL_ID', 'SOURCE_DATABASE', 'SOURCE_SCHEMA', 'SOURCE_TABLE_NAME'],
        'identity_column': 'SOURCE_TABLE_ID',
        'foreign_keys': {
            'MODEL_ID': 'MODEL_REGISTRY(MODEL_ID)'
        }
    },
    'model_column_details': {
        'table_name': 'MODEL_COLUMN_DETAILS',
        'required_columns': ['MODEL_ID', 'COLUMN_NAME', 'DATA_TYPE'],
        'unique_columns': ['MODEL_ID', 'COLUMN_NAME'],
        'identity_column': 'COLUMN_ID',
        'foreign_keys': {
            'MODEL_ID': 'MODEL_REGISTRY(MODEL_ID)'
        }
    },
    'model_table_usage': {
        'table_name': 'MODEL_TABLE_USAGE',
        'required_columns': ['MODEL_ID', 'TABLE_NAME', 'USAGE_TYPE'],
        'unique_columns': ['MODEL_ID', 'TABLE_NAME', 'USAGE_TYPE'],
        'identity_column': 'USAGE_ID',
        'foreign_keys': {
            'MODEL_ID': 'MODEL_REGISTRY(MODEL_ID)'
        }
    },
    'model_segment_mapping': {
        'table_name': 'MODEL_SEGMENT_MAPPING',
        'required_columns': ['MODEL_ID', 'SEGMENT_NAME', 'SEGMENT_CRITERIA'],
        'unique_columns': ['MODEL_ID', 'SEGMENT_NAME'],
        'identity_column': 'MAPPING_ID',
        'foreign_keys': {
            'MODEL_ID': 'MODEL_REGISTRY(MODEL_ID)'
        }
    },
    'model_validation_results': {
        'table_name': 'MODEL_VALIDATION_RESULTS',
        'required_columns': ['MODEL_ID', 'VALIDATION_DATE', 'VALIDATION_TYPE', 'METRIC_NAME', 'METRIC_VALUE'],
        'unique_columns': ['MODEL_ID', 'VALIDATION_DATE', 'VALIDATION_TYPE', 'METRIC_NAME'],
        'identity_column': 'VALIDATION_ID',
        'foreign_keys': {
            'MODEL_ID': 'MODEL_REGISTRY(MODEL_ID)'
        }
    },
    'feature_transformations': {
        'table_name': 'FEATURE_TRANSFORMATIONS',
        'required_columns': ['FEATURE_ID', 'TRANSFORMATION_TYPE', 'TRANSFORMATION_RULE'],
        'unique_columns': ['FEATURE_ID', 'TRANSFORMATION_TYPE'],
        'identity_column': 'TRANSFORMATION_ID',
        'foreign_keys': {
            'FEATURE_ID': 'FEATURE_REGISTRY(FEATURE_ID)'
        }
    },
    'feature_source_tables': {
        'table_name': 'FEATURE_SOURCE_TABLES',
        'required_columns': ['FEATURE_ID', 'SOURCE_DATABASE', 'SOURCE_SCHEMA', 'SOURCE_TABLE_NAME', 'SOURCE_COLUMN_NAME'],
        'unique_columns': ['FEATURE_ID', 'SOURCE_DATABASE', 'SOURCE_SCHEMA', 'SOURCE_TABLE_NAME', 'SOURCE_COLUMN_NAME'],
        'identity_column': 'SOURCE_ID',
        'foreign_keys': {
            'FEATURE_ID': 'FEATURE_REGISTRY(FEATURE_ID)'
        }
    },
    'feature_model_mapping': {
        'table_name': 'FEATURE_MODEL_MAPPING',
        'required_columns': ['FEATURE_ID', 'MODEL_ID', 'USAGE_TYPE'],
        'unique_columns': ['FEATURE_ID', 'MODEL_ID', 'USAGE_TYPE'],
        'identity_column': 'MAPPING_ID',
        'foreign_keys': {
            'FEATURE_ID': 'FEATURE_REGISTRY(FEATURE_ID)',
            'MODEL_ID': 'MODEL_REGISTRY(MODEL_ID)'
        }
    }
}

# Data Type Mappings
DATA_TYPE_MAPPINGS = {
    'NUMERIC': ['int', 'bigint', 'decimal', 'float', 'real'],
    'CATEGORICAL': ['varchar', 'nvarchar', 'char', 'nchar'],
    'DATE': ['date', 'datetime', 'datetime2', 'smalldatetime'],
    'TEXT': ['text', 'ntext', 'varchar(max)', 'nvarchar(max)'],
    'BINARY': ['bit', 'binary', 'varbinary']
}

# Value Type Mappings
VALUE_TYPE_MAPPINGS = {
    'CONTINUOUS': 'Giá trị liên tục (số thực)',
    'DISCRETE': 'Giá trị rời rạc (số nguyên)',
    'BINARY': 'Giá trị nhị phân (0/1, True/False)',
    'NOMINAL': 'Giá trị danh nghĩa (không có thứ tự)',
    'ORDINAL': 'Giá trị có thứ tự (có thể sắp xếp)'
}

# Business Categories
BUSINESS_CATEGORIES = [
    'DEMOGRAPHIC', 'FINANCIAL', 'BEHAVIORAL', 'RELATIONSHIP', 
    'ACCOUNT', 'BALANCE', 'DELINQUENCY', 'BUREAU'
]

# Usage Types
USAGE_TYPES = [
    'INPUT', 'OUTPUT', 'TARGET', 'FEATURE', 'PREDICTOR', 'RESULT'
]

# Validation Types
VALIDATION_TYPES = [
    'PERFORMANCE', 'STABILITY', 'ACCURACY', 'DISCRIMINATION', 
    'CALIBRATION', 'BACKTESTING', 'STRESS_TESTING'
] 