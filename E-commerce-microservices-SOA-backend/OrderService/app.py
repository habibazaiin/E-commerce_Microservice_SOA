from flask import Flask, request, jsonify
import requests
import mysql.connector
from mysql.connector import Error
from datetime import datetime
import logging

app = Flask(__name__)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# ============================================================
# Configuration
# ============================================================

# Service URLs
INVENTORY_SERVICE_URL = 'http://localhost:5002'
PRICING_SERVICE_URL = 'http://localhost:5003'
CUSTOMER_SERVICE_URL = 'http://localhost:5004'
NOTIFICATION_SERVICE_URL = 'http://localhost:5005'

# Database Configuration
DB_CONFIG = {
    "host": "localhost",
    "user": "ecommerce_user",
    "password": "123456",
    "database": "ecommerce_system",
    "autocommit": False
}

def get_db_connection():
    """Create database connection"""
    return mysql.connector.connect(**DB_CONFIG)

# ============================================================
# Input Validation
# ============================================================

def validate_order_input(data):
    if 'customer_id' not in data:
        return False, "Missing required field: customer_id"
    
    if not isinstance(data['customer_id'], int) or data['customer_id'] <= 0:
        return False, "Invalid customer_id: must be a positive integer"
    
    if 'products' not in data:
        return False, "Missing required field: products"
    
    if not isinstance(data['products'], list) or len(data['products']) == 0:
        return False, "Products list cannot be empty"
    
    for idx, product in enumerate(data['products']):
        if 'product_id' not in product:
            return False, f"Product at index {idx} missing product_id"
        
        if not isinstance(product['product_id'], int) or product['product_id'] <= 0:
            return False, f"Invalid product_id at index {idx}"
        
        if 'quantity' not in product:
            return False, f"Product at index {idx} missing quantity"
        
        if not isinstance(product['quantity'], int) or product['quantity'] <= 0:
            return False, f"Invalid quantity at index {idx}: must be positive"
    
    return True, None

# ============================================================
# Check Inventory (with price fetching)
# ============================================================

def check_inventory(products):
    inventory_items = []
    
    logger.info(f"🔍 Checking inventory for {len(products)} products...")
    
    for product in products:
        product_id = product['product_id']
        requested_qty = product['quantity']
        
        try:
            response = requests.get(
                f"{INVENTORY_SERVICE_URL}/inventory/{product_id}",
                timeout=30
            )
            
            if response.status_code != 200:
                logger.error(f"❌ Inventory service error for product {product_id}: {response.status_code}")
                return False, f"Failed to check inventory for product {product_id}"
            
            inventory_data = response.json()
            available_qty = inventory_data.get('quantity_available', 0)
            unit_price = inventory_data.get('unit_price', 0.0)
            product_name = inventory_data.get('product_name', 'Unknown')
            
            logger.info(f"  ✓ Product {product_id}: {product_name}")
            logger.info(f"    Price: {unit_price}, Available: {available_qty}, Requested: {requested_qty}")
            
            # Check quantity availability
            if available_qty < requested_qty:
                logger.warning(f"⚠️ Insufficient stock for product {product_id}")
                return False, f"Insufficient stock for product {product_id}. Available: {available_qty}, Requested: {requested_qty}"
            
            # Save all data including unit_price
            inventory_items.append({
                'product_id': product_id,
                'product_name': product_name,
                'quantity': requested_qty,
                'unit_price': unit_price
            })
            
        except requests.exceptions.Timeout:
            logger.error(f"⏱️ Timeout checking inventory for product {product_id}")
            return False, f"Inventory service timeout for product {product_id}"
        
        except requests.exceptions.ConnectionError:
            logger.error(f"🔌 Cannot connect to Inventory service")
            return False, "Cannot connect to Inventory service. Ensure it's running on port 5002"
        
        except Exception as e:
            logger.error(f"❌ Error checking inventory: {str(e)}")
            return False, f"Error checking inventory: {str(e)}"
    
    logger.info(f"✅ All products available and prices fetched")
    return True, inventory_items

# ============================================================
# Calculate Pricing
# ============================================================

def calculate_pricing(inventory_items, region='Cairo'):
    payload = {
        "products": inventory_items,
        "region": region
    }
    
    logger.info(f"💰 Calculating pricing...")
    logger.info(f"📤 Payload: {payload}")
    
    try:
        response = requests.post(
            f"{PRICING_SERVICE_URL}/api/pricing/calculate",
            json=payload,
            timeout=30,
            headers={'Content-Type': 'application/json'}
        )
        
        logger.info(f"📥 Pricing service response code: {response.status_code}")
        
        if response.status_code != 200:
            logger.error(f"❌ Pricing service error: {response.status_code}")
            logger.error(f"Response: {response.text}")
            return False, f"Pricing service error: {response.text}"
        
        pricing_data = response.json()
        
        logger.info(f"✅ Pricing calculated successfully")
        logger.info(f"  Subtotal: {pricing_data.get('subtotal', 0)}")
        logger.info(f"  Discount: {pricing_data.get('discount', 0)}")
        logger.info(f"  Tax: {pricing_data.get('tax', 0)}")
        logger.info(f"  Total: {pricing_data.get('total_amount', 0)}")
        
        return True, pricing_data
        
    except requests.exceptions.Timeout:
        logger.error("⏱️ Timeout calculating pricing")
        return False, "Pricing service timeout"
    
    except requests.exceptions.ConnectionError:
        logger.error("🔌 Cannot connect to Pricing service")
        return False, "Cannot connect to Pricing service. Ensure it's running on port 5003"
    
    except Exception as e:
        logger.error(f"❌ Error calculating pricing: {str(e)}")
        return False, f"Error calculating pricing: {str(e)}"

# ============================================================
# Save Order to Database
# ============================================================

def save_order_to_database(customer_id, pricing_data, inventory_items):
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        conn.start_transaction()
        
        logger.info(f"💾 Saving order to database...")
        
        # Extract data
        subtotal = pricing_data.get('subtotal', 0.0)
        discount = pricing_data.get('discount', 0.0)
        tax = pricing_data.get('tax', 0.0)
        total_amount = pricing_data.get('total_amount', 0.0)
        
        logger.info(f"📊 Order financials:")
        logger.info(f"  Subtotal: {subtotal}")
        logger.info(f"  Discount: {discount}")
        logger.info(f"  Tax: {tax}")
        logger.info(f"  Total: {total_amount}")
        
        # Validate data
        if total_amount == 0:
            logger.error("❌ Total amount is 0! Pricing data invalid!")
            logger.error(f"Pricing data: {pricing_data}")
            return False, "Invalid pricing data: total amount is 0"
        
        # 1. Save Order
        cursor.execute("""
            INSERT INTO orders 
            (customer_id, total_amount, subtotal, discount, tax, status)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (
            customer_id,
            total_amount,
            subtotal,
            discount,
            tax,
            'confirmed'
        ))
        
        order_id = cursor.lastrowid
        logger.info(f"✓ Order {order_id} record created")
        
        # 2. Save Order Items
        items = pricing_data.get('items', [])
        
        if not items:
            logger.error("❌ No items in pricing data!")
            return False, "No items in pricing response"
        
        logger.info(f"📦 Saving {len(items)} order items...")
        
        for item in items:
            product_id = item.get('product_id')
            quantity = item.get('quantity')
            unit_price = item.get('unit_price')
            discounted_price = item.get('discounted_price')
            discount_pct = item.get('discount_percentage', 0.0)
            line_total = item.get('line_total')
            
            logger.info(f"  Item: Product {product_id}, Qty {quantity}, Price {unit_price}, Total {line_total}")
            
            cursor.execute("""
                INSERT INTO order_items
                (order_id, product_id, quantity, unit_price, discounted_price, 
                 discount_percentage, line_total)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (
                order_id,
                product_id,
                quantity,
                unit_price,
                discounted_price,
                discount_pct,
                line_total
            ))
        
        logger.info(f"✓ {len(items)} items saved")
        
        # 3. Update Inventory
        logger.info(f"📉 Updating inventory...")
        for item in inventory_items:
            cursor.execute("""
                UPDATE inventory
                SET quantity_available = quantity_available - %s,
                    last_updated = CURRENT_TIMESTAMP
                WHERE product_id = %s
            """, (item['quantity'], item['product_id']))
            
            logger.info(f"  ✓ Product {item['product_id']}: -{item['quantity']} units")
        
        # 4. Commit
        conn.commit()
        logger.info(f"✅ Order {order_id} saved and committed successfully!")
        
        cursor.close()
        conn.close()
        
        return True, order_id
        
    except Error as e:
        if conn:
            conn.rollback()
            logger.error(f"❌ Database error, rolled back: {e}")
        return False, f"Database error: {str(e)}"
        
    except Exception as e:
        if conn:
            conn.rollback()
            logger.error(f"❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        return False, f"Unexpected error: {str(e)}"
    
    finally:
        if conn and conn.is_connected():
            conn.close()

# ============================================================
# Main Endpoint - Create Order
# ============================================================

@app.route('/api/orders/create', methods=['POST'])
def create_order():
    logger.info("=" * 60)
    logger.info("🛒 NEW ORDER REQUEST RECEIVED")
    logger.info("=" * 60)
    
    try:
        # 1. Get data
        data = request.get_json()
        logger.info(f"📥 Received data: {data}")
        
        # 2. Validate input
        is_valid, error_msg = validate_order_input(data)
        if not is_valid:
            logger.warning(f"❌ Invalid input: {error_msg}")
            return jsonify({'success': False, 'error': error_msg}), 400
        
        # 3. Check inventory (and fetch prices)
        inventory_success, inventory_result = check_inventory(data['products'])
        if not inventory_success:
            logger.warning(f"❌ Inventory check failed: {inventory_result}")
            return jsonify({
                'success': False,
                'error': inventory_result,
                'stage': 'inventory_check'
            }), 400
        
        # 4. Calculate pricing
        pricing_success, pricing_result = calculate_pricing(
            inventory_result,
            region='Cairo'
        )
        
        if not pricing_success:
            logger.warning(f"❌ Pricing failed: {pricing_result}")
            return jsonify({
                'success': False,
                'error': pricing_result,
                'stage': 'pricing_calculation'
            }), 400
        
        # 5. Save to Database
        save_success, order_id_or_error = save_order_to_database(
            data['customer_id'], 
            pricing_result, 
            inventory_result
        )
        
        if not save_success:
            logger.error(f"❌ Failed to save: {order_id_or_error}")
            return jsonify({
                'success': False,
                'error': f"Failed to save order: {order_id_or_error}",
                'stage': 'database_save'
            }), 500
        
        # 6. Update loyalty points
        try:
            total_amount = pricing_result.get('total_amount', 0)
            points_to_add = int(total_amount / 10)  # 1 point per 10 EGP
            
            if points_to_add > 0:
                loyalty_response = requests.put(
                    f"{CUSTOMER_SERVICE_URL}/api/customers/{data['customer_id']}/loyalty",
                    json={'points_to_add': points_to_add},
                    timeout=10
                )
                
                if loyalty_response.status_code == 200:
                    logger.info(f"✅ Added {points_to_add} loyalty points")
                else:
                    logger.warning(f"⚠️ Failed to update loyalty points")
        except Exception as e:
            logger.warning(f"⚠️ Loyalty points update failed: {e}")
        
        # 7. Send notification
        try:
            notification_response = requests.post(
                f"{NOTIFICATION_SERVICE_URL}/api/notifications/send",
                json={
                    'order_id': order_id_or_error,
                    'notification_type': 'order_confirmation'
                },
                timeout=10
            )
            
            if notification_response.status_code == 201:
                logger.info(f"✅ Notification sent successfully")
            else:
                logger.warning(f"⚠️ Failed to send notification")
        except Exception as e:
            logger.warning(f"⚠️ Notification sending failed: {e}")
        
        # 8. Prepare final response
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        response_data = {
            'success': True,
            'order_id': order_id_or_error,
            'customer_id': data['customer_id'],
            'products': inventory_result,
            'pricing': pricing_result,
            'timestamp': timestamp,
            'status': 'confirmed',
            'message': 'Order created successfully'
        }
        
        logger.info("=" * 60)
        logger.info(f"✅ ORDER {order_id_or_error} COMPLETED SUCCESSFULLY!")
        logger.info("=" * 60)
        
        return jsonify(response_data), 201
        
    except Exception as e:
        logger.error(f"❌ Unexpected error: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({
            'success': False,
            'error': 'Internal server error',
            'details': str(e)
        }), 500

# ============================================================
# Retrieve Order from Database
# ============================================================

@app.route('/api/orders/<int:order_id>', methods=['GET'])
def get_order(order_id):
    """Retrieve Order from Database"""
    logger.info(f"🔍 Retrieving order {order_id}")
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("SELECT * FROM orders WHERE order_id = %s", (order_id,))
        order = cursor.fetchone()
        
        if not order:
            return jsonify({'error': 'Order not found'}), 404
        
        cursor.execute("""
            SELECT oi.*, i.product_name
            FROM order_items oi
            JOIN inventory i ON oi.product_id = i.product_id
            WHERE oi.order_id = %s
        """, (order_id,))
        items = cursor.fetchall()
        
        cursor.close()
        conn.close()
        
        # Convert datetime to string
        if order.get('created_at'):
            order['created_at'] = order['created_at'].strftime('%Y-%m-%d %H:%M:%S')
        
        # Convert Decimal to float
        from decimal import Decimal
        for key in list(order.keys()):
            if isinstance(order[key], Decimal):
                order[key] = float(order[key])
        
        for item in items:
            for key in list(item.keys()):
                if isinstance(item[key], Decimal):
                    item[key] = float(item[key])
        
        order['items'] = items
        
        return jsonify(order), 200
        
    except Error as e:
        logger.error(f"Database error: {e}")
        return jsonify({'error': str(e)}), 500

# ============================================================
# Health Check
# ============================================================

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'healthy',
        'service': 'Order Service',
        'port': 5001
    }), 200

# ============================================================
# Run Service
# ============================================================

if __name__ == '__main__':
    logger.info("=" * 60)
    logger.info("🚀 STARTING ORDER SERVICE")
    logger.info(f"📍 Port: 5001")
    logger.info(f"🗄️  Database: ecommerce_system")
    logger.info(f"📦 Inventory URL: {INVENTORY_SERVICE_URL}")
    logger.info(f"💰 Pricing URL: {PRICING_SERVICE_URL}")
    logger.info(f"👤 Customer URL: {CUSTOMER_SERVICE_URL}")
    logger.info(f"📧 Notification URL: {NOTIFICATION_SERVICE_URL}")
    logger.info("=" * 60)
    
    app.run(
        host='0.0.0.0',
        port=5001,
        debug=True
    )