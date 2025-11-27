# db_config.py
import mysql.connector
from mysql.connector import Error

def get_db_connection():
    """إنشاء اتصال بقاعدة البيانات"""
    try:
        connection = mysql.connector.connect(
            host='localhost',         
            database='ecommerce_system',  
            user='ecommerce_user',     
            password='123456'          
        )
        
        if connection.is_connected():
            db_info = connection.get_server_info()
            print(f"✅ Successfully connected to MySQL Server version {db_info}")
            return connection
            
    except Error as e:
        print(f"❌ Error while connecting to MySQL: {e}")
        return None

def close_connection(connection, cursor=None):
    """إغلاق الاتصال"""
    if cursor:
        cursor.close()
        print("🔒 Cursor closed")
    
    if connection and connection.is_connected():
        connection.close()
        print("🔒 MySQL connection closed")