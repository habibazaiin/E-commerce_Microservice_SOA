from flask import Flask, request, jsonify
import mysql.connector
from mysql.connector import Error
from decimal import Decimal
import logging
import requests

# ============================================================
# Configuration
# ============================================================

DB_CONFIG = {
    "host": "localhost",
    "user": "ecommerce_user",
    "password": "123456",
    "database": "ecommerce_system"
}

ORDER_SERVICE_URL = "http://localhost:5001"

app = Flask(__name__)

# Logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def get_db_connection():
    """Create database connection"""
    try:
        return mysql.connector.connect(**DB_CONFIG)
    except Error as e:
        logger.error(f"Database connection error: {e}")
        raise


def decimal_to_float(value):
    """Convert Decimal to float"""
    if isinstance(value, Decimal):
        return float(value)
    return value


# ============================================================
# API Endpoints
# ============================================================

@app.route('/api/customers/<int:customer_id>', methods=['GET'])
def get_customer(customer_id):
    """Get customer profile"""
    logger.info(f"📋 GET /api/customers/{customer_id}")
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT customer_id, name, email, phone, loyalty_points, created_at
            FROM customers
            WHERE customer_id = %s
        """, (customer_id,))
        
        customer = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if not customer:
            logger.warning(f"⚠️ Customer {customer_id} not found")
            return jsonify({'error': 'Customer not found'}), 404
        
        # Convert datetime to string
        if customer.get('created_at'):
            customer['created_at'] = customer['created_at'].strftime('%Y-%m-%d %H:%M:%S')
        
        # Convert Decimal to float
        for key in list(customer.keys()):
            if isinstance(customer[key], Decimal):
                customer[key] = float(customer[key])
        
        logger.info(f"✅ Customer found: {customer['name']}")
        return jsonify(customer), 200
        
    except Error as e:
        logger.error(f"❌ Database error: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/customers/<int:customer_id>/orders', methods=['GET'])
def get_customer_orders(customer_id):
    """Get customer order history (calls Order Service)"""
    logger.info(f"📦 GET /api/customers/{customer_id}/orders")
    
    try:
        # First, verify customer exists
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT customer_id, name FROM customers WHERE customer_id = %s", (customer_id,))
        customer = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if not customer:
            logger.warning(f"⚠️ Customer {customer_id} not found")
            return jsonify({'error': 'Customer not found'}), 404
        
        # Get orders from database
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT o.order_id, o.customer_id, o.total_amount, o.subtotal, 
                   o.discount, o.tax, o.status, o.created_at
            FROM orders o
            WHERE o.customer_id = %s
            ORDER BY o.created_at DESC
        """, (customer_id,))
        
        orders = cursor.fetchall()
        
        # Get items for each order
        for order in orders:
            order_id = order['order_id']
            
            cursor.execute("""
                SELECT oi.*, i.product_name
                FROM order_items oi
                JOIN inventory i ON oi.product_id = i.product_id
                WHERE oi.order_id = %s
            """, (order_id,))
            
            items = cursor.fetchall()
            
            # Convert datetime and Decimal
            if order.get('created_at'):
                order['created_at'] = order['created_at'].strftime('%Y-%m-%d %H:%M:%S')
            
            for key in list(order.keys()):
                if isinstance(order[key], Decimal):
                    order[key] = float(order[key])
            
            for item in items:
                for key in list(item.keys()):
                    if isinstance(item[key], Decimal):
                        item[key] = float(item[key])
            
            order['items'] = items
        
        cursor.close()
        conn.close()
        
        logger.info(f"✅ Found {len(orders)} orders for customer {customer_id}")
        
        return jsonify({
            'customer_id': customer_id,
            'customer_name': customer['name'],
            'total_orders': len(orders),
            'orders': orders
        }), 200
        
    except Error as e:
        logger.error(f"❌ Database error: {e}")
        return jsonify({'error': str(e)}), 500
    except Exception as e:
        logger.error(f"❌ Error: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/customers/<int:customer_id>/loyalty', methods=['PUT'])
def update_loyalty_points(customer_id):
    """Update customer loyalty points"""
    logger.info(f"⭐ PUT /api/customers/{customer_id}/loyalty")
    
    try:
        data = request.get_json()
        
        if not data or 'points_to_add' not in data:
            return jsonify({'error': 'points_to_add is required'}), 400
        
        points_to_add = int(data['points_to_add'])
        
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Update loyalty points
        cursor.execute("""
            UPDATE customers
            SET loyalty_points = loyalty_points + %s
            WHERE customer_id = %s
        """, (points_to_add, customer_id))
        
        if cursor.rowcount == 0:
            cursor.close()
            conn.close()
            return jsonify({'error': 'Customer not found'}), 404
        
        conn.commit()
        
        # Get updated customer
        cursor.execute("""
            SELECT customer_id, name, loyalty_points
            FROM customers
            WHERE customer_id = %s
        """, (customer_id,))
        
        customer = cursor.fetchone()
        cursor.close()
        conn.close()
        
        logger.info(f"✅ Added {points_to_add} points to customer {customer_id}")
        logger.info(f"   New total: {customer['loyalty_points']} points")
        
        return jsonify({
            'success': True,
            'customer_id': customer_id,
            'customer_name': customer['name'],
            'points_added': points_to_add,
            'total_points': customer['loyalty_points']
        }), 200
        
    except ValueError:
        return jsonify({'error': 'Invalid points_to_add value'}), 400
    except Error as e:
        logger.error(f"❌ Database error: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'Customer Service',
        'port': 5004
    }), 200


# ============================================================
# Main
# ============================================================

if __name__ == '__main__':
    logger.info("=" * 60)
    logger.info("🚀 STARTING CUSTOMER SERVICE")
    logger.info("Port: 5004")
    logger.info("Database: ecommerce_system")
    logger.info("=" * 60)
    
    # Test database connection
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM customers")
        count = cursor.fetchone()[0]
        cursor.close()
        conn.close()
        logger.info(f"✓ Database connected successfully")
        logger.info(f"✓ Found {count} customers")
        logger.info("=" * 60)
    except Exception as e:
        logger.error(f"✗ Database connection failed: {e}")
        logger.error("Service may not work properly!")
        logger.info("=" * 60)
    
    app.run(
        host='0.0.0.0',
        port=5004,
        debug=True
    )