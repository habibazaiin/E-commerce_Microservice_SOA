# test_connection.py
from db_config import get_db_connection, close_connection

def test_database_connection():
    """اختبار الاتصال بقاعدة البيانات"""
    print("🔄 Testing database connection...")
    
    # محاولة الاتصال
    conn = get_db_connection()
    
    if conn:
        try:
            cursor = conn.cursor(dictionary=True)
            
            # اختبار 1: عرض الجداول
            cursor.execute("SHOW TABLES")
            tables = cursor.fetchall()
            print(f"\n📊 Tables in database:")
            for table in tables:
                print(f"  - {table}")
            
            # اختبار 2: عرض عدد المنتجات
            cursor.execute("SELECT COUNT(*) as count FROM inventory")
            result = cursor.fetchone()
            print(f"\n📦 Products in inventory: {result['count']}")
            
            # اختبار 3: عرض أول 3 منتجات
            cursor.execute("SELECT * FROM inventory LIMIT 3")
            products = cursor.fetchall()
            print(f"\n🛍️ Sample products:")
            for product in products:
                print(f"  - {product['product_name']}: ${product['unit_price']}")
            
            print("\n✅ All tests passed!")
            
        except Exception as e:
            print(f"❌ Error during testing: {e}")
        
        finally:
            close_connection(conn, cursor)
    else:
        print("❌ Connection failed!")

if __name__ == "__main__":
    test_database_connection()