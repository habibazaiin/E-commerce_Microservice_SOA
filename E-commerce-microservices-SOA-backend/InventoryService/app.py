"""
Inventory Service - إدارة المخزون
Port: 5002
Database: ecommerce_system.inventory
"""

from flask import Flask, request, jsonify
import mysql.connector
from mysql.connector import pooling, Error
from decimal import Decimal
import logging

# ============================================================
# Configuration
# ============================================================

DB_CONFIG = {
    "host": "localhost",
    "user": "ecommerce_user",
    "password": "123456",
    "database": "ecommerce_system",
    "autocommit": False
}
POOL_SIZE = 5

app = Flask(__name__)

# Logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# ============================================================
# Database Connection Pool
# ============================================================

try:
    pool = mysql.connector.pooling.MySQLConnectionPool(
        pool_name="inventory_pool",
        pool_size=POOL_SIZE,
        **DB_CONFIG
    )
    logger.info("✓ Database connection pool created successfully")
except Error as e:
    logger.error(f"✗ Error creating DB pool: {e}")
    raise RuntimeError(f"Error creating DB pool: {e}")


def get_conn():
    """Get a connection from the pool."""
    return pool.get_connection()


def decimal_to_native(value):
    """Convert Decimal to float."""
    if value is None:
        return None
    if isinstance(value, Decimal):
        return float(value)
    return value


def row_to_item(row):
    """Convert database row to dictionary."""
    (product_id, product_name, quantity_available, unit_price, last_updated) = row
    return {
        "product_id": product_id,
        "product_name": product_name,
        "quantity_available": quantity_available,
        "unit_price": decimal_to_native(unit_price),
        "last_updated": last_updated.isoformat() if last_updated else None
    }


# ============================================================
# API Endpoints
# ============================================================

@app.route('/inventory', methods=['GET'])
def list_products():
    """
    Get all products
    
    Response:
        [
            {
                "product_id": 1,
                "product_name": "Laptop",
                "quantity_available": 50,
                "unit_price": 999.99,
                "last_updated": "2025-12-13T10:30:00"
            },
            ...
        ]
    """
    logger.info("📦 GET /inventory - Listing all products")
    
    try:
        conn = get_conn()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT product_id, product_name, quantity_available, 
                   unit_price, last_updated 
            FROM inventory
            ORDER BY product_id
        """)
        rows = cursor.fetchall()
        cursor.close()
        conn.close()
        
        items = [row_to_item(r) for r in rows]
        logger.info(f"✓ Found {len(items)} products")
        
        return jsonify(items), 200
        
    except Error as e:
        logger.error(f"✗ Database error: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/inventory/<int:product_id>', methods=['GET'])
def get_product(product_id):
    """
    Get single product by ID
    
    Used by: Order Service to check product availability
    
    Response:
        {
            "product_id": 1,
            "product_name": "Laptop",
            "quantity_available": 50,
            "unit_price": 999.99,
            "last_updated": "2025-12-13T10:30:00"
        }
    """
    logger.info(f"🔍 GET /inventory/{product_id} - Checking product")
    
    try:
        conn = get_conn()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT product_id, product_name, quantity_available, 
                   unit_price, last_updated 
            FROM inventory 
            WHERE product_id = %s
        """, (product_id,))
        row = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if not row:
            logger.warning(f"⚠ Product {product_id} not found")
            return jsonify({"error": "Product not found"}), 404
        
        product = row_to_item(row)
        logger.info(f"✓ Product found: {product['product_name']}, Available: {product['quantity_available']}")
        
        return jsonify(product), 200
        
    except Error as e:
        logger.error(f"✗ Database error: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/inventory/<int:product_id>', methods=['PUT', 'PATCH'])
def update_product(product_id):
    """
    Update product inventory
    
    Request Body:
        {
            "quantity_available": 45
        }
    """
    logger.info(f"📝 PUT/PATCH /inventory/{product_id} - Updating product")
    
    data = request.get_json(force=True, silent=True)
    if not data:
        return jsonify({"error": "JSON body required"}), 400

    fields = []
    params = []

    if "product_name" in data:
        fields.append("product_name = %s")
        params.append(data["product_name"])
    if "quantity_available" in data:
        fields.append("quantity_available = %s")
        params.append(int(data["quantity_available"]))
    if "unit_price" in data:
        fields.append("unit_price = %s")
        params.append(data["unit_price"])

    if not fields:
        return jsonify({"error": "No updatable fields provided"}), 400

    set_clause = ", ".join(fields + ["last_updated = CURRENT_TIMESTAMP"])
    params.append(product_id)

    try:
        conn = get_conn()
        cursor = conn.cursor()
        sql = f"UPDATE inventory SET {set_clause} WHERE product_id = %s"
        cursor.execute(sql, tuple(params))
        conn.commit()
        changed = cursor.rowcount
        cursor.close()
        conn.close()
        
        if changed == 0:
            logger.warning(f"⚠ Product {product_id} not found")
            return jsonify({"error": "Product not found"}), 404
        
        logger.info(f"✓ Product {product_id} updated successfully")
        return jsonify({"message": "Product updated", "product_id": product_id}), 200
        
    except Error as e:
        logger.error(f"✗ Database error: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "service": "Inventory Service",
        "port": 5002
    }), 200


# ============================================================
# Main
# ============================================================

if __name__ == "__main__":
    logger.info("=" * 60)
    logger.info("🚀 STARTING INVENTORY SERVICE")
    logger.info("Port: 5002")
    logger.info("Database: ecommerce_system")
    logger.info("=" * 60)
    
    app.run(
        host='0.0.0.0',
        port=5002,
        debug=True
    )