

from flask import Flask, request, jsonify
import mysql.connector
from mysql.connector import Error
from decimal import Decimal
import logging

# ============================================================
# Configuration
# ============================================================

DB_CONFIG = {
    "host": "localhost",
    "user": "ecommerce_user",
    "password": "123456",
    "database": "ecommerce_system"
}

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
# Helper Functions
# ============================================================

def get_pricing_rules():
    """Get all pricing rules from database"""
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT product_id, min_quantity, discount_percentage 
            FROM pricing_rules
            ORDER BY product_id, min_quantity DESC
        """)
        rules = cursor.fetchall()
        cursor.close()
        return rules
    except Error as e:
        logger.error(f"Error fetching pricing rules: {e}")
        return []
    finally:
        if conn and conn.is_connected():
            conn.close()


def get_tax_rate(region='Cairo'):
    """Get tax rate for a region"""
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT tax_rate 
            FROM tax_rates 
            WHERE region = %s
        """, (region,))
        result = cursor.fetchone()
        cursor.close()
        
        if result:
            return decimal_to_float(result['tax_rate']) / 100
        
        logger.warning(f"No tax rate found for region '{region}', using default 14%")
        return 0.14
        
    except Error as e:
        logger.error(f"Error fetching tax rate: {e}")
        return 0.14
    finally:
        if conn and conn.is_connected():
            conn.close()


def apply_discount(product_id, quantity, unit_price):
    
    pricing_rules = get_pricing_rules()
    
    
    applicable_discounts = []
    
    for rule in pricing_rules:
        if rule['product_id'] == product_id:
            min_qty = rule['min_quantity']
            discount_pct = decimal_to_float(rule['discount_percentage'])
            
            
            if quantity >= min_qty:
                applicable_discounts.append({
                    'min_quantity': min_qty,
                    'discount_percentage': discount_pct
                })
                logger.debug(f"    → Rule found: {min_qty}+ items = {discount_pct}% off")
    
    
    if not applicable_discounts:
        logger.debug(f"    → No discount applicable for product {product_id}")
        return unit_price, 0.0
    
    
    best_discount = max(applicable_discounts, key=lambda x: x['discount_percentage'])
    discount_pct = best_discount['discount_percentage']
    
    
    discount_amount = unit_price * (discount_pct / 100)
    discounted_price = unit_price - discount_amount
    
    logger.info(f"  💰 Discount {discount_pct}% applied to product {product_id} (qty: {quantity})")
    
    return discounted_price, discount_pct


# ============================================================
# API Endpoints
# ============================================================

@app.route('/api/pricing/calculate', methods=['POST'])
def calculate_pricing():
    
    logger.info("=" * 60)
    logger.info("💰 POST /api/pricing/calculate")
    logger.info("=" * 60)
    
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
        
        products = data.get('products', [])
        region = data.get('region', 'Cairo')
        
        if not products:
            return jsonify({'error': 'No products provided'}), 400
        
        if not isinstance(products, list):
            return jsonify({'error': 'Products must be a list'}), 400
        
        logger.info(f"📦 Processing {len(products)} products")
        logger.info(f"🌍 Region: {region}")
        
        items_breakdown = []
        subtotal = 0.0
        total_discount = 0.0
        
        # Process each product
        for idx, product in enumerate(products):
            # Validate product data
            if not isinstance(product, dict):
                return jsonify({'error': f'Product at index {idx} is not a valid object'}), 400
            
            product_id = product.get('product_id')
            quantity = product.get('quantity', 1)
            unit_price = product.get('unit_price', 0.0)
            
            # Validation
            if not product_id:
                return jsonify({'error': f'Missing product_id at index {idx}'}), 400
            
            if not isinstance(quantity, (int, float)) or quantity <= 0:
                return jsonify({'error': f'Invalid quantity for product {product_id}'}), 400
            
            if not isinstance(unit_price, (int, float)) or unit_price < 0:
                return jsonify({'error': f'Invalid unit_price for product {product_id}'}), 400
            
            logger.info(f"\n  🔸 Product ID: {product_id}, Qty: {quantity}, Price: {unit_price}")
            
            # Apply discount
            discounted_price, discount_pct = apply_discount(product_id, quantity, unit_price)
            
            # Calculate line total
            line_total = discounted_price * quantity
            item_discount = (unit_price - discounted_price) * quantity
            
            subtotal += line_total
            total_discount += item_discount
            
            items_breakdown.append({
                'product_id': product_id,
                'quantity': quantity,
                'unit_price': round(unit_price, 2),
                'discounted_price': round(discounted_price, 2),
                'discount_percentage': discount_pct,
                'line_total': round(line_total, 2)
            })
            
            logger.info(f"  ✓ Line total: {line_total:.2f} EGP")
        
        # Get tax rate
        tax_rate = get_tax_rate(region)
        tax = subtotal * tax_rate
        
        # Calculate final total
        total_amount = subtotal + tax
        
        response = {
            'subtotal': round(subtotal, 2),
            'discount': round(total_discount, 2),
            'tax': round(tax, 2),
            'tax_rate': round(tax_rate * 100, 2),
            'total_amount': round(total_amount, 2),
            'region': region,
            'items': items_breakdown
        }
        
        logger.info("\n" + "=" * 60)
        logger.info(f"📊 PRICING SUMMARY:")
        logger.info(f"   Subtotal:       {subtotal:.2f} EGP")
        logger.info(f"   Discount:      -{total_discount:.2f} EGP")
        logger.info(f"   Tax ({tax_rate*100:.0f}%):       +{tax:.2f} EGP")
        logger.info(f"   TOTAL:          {total_amount:.2f} EGP")
        logger.info("=" * 60)
        
        return jsonify(response), 200
        
    except Exception as e:
        logger.error(f"✗ Error in pricing calculation: {str(e)}", exc_info=True)
        return jsonify({
            'error': 'Internal server error',
            'details': str(e)
        }), 500


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'Pricing Service',
        'port': 5003
    }), 200


@app.route('/api/pricing/test', methods=['GET'])
def test_endpoint():
    """Test endpoint to verify service is working"""
    try:
        # Test database connection
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM pricing_rules")
        rules_count = cursor.fetchone()[0]
        cursor.execute("SELECT COUNT(*) FROM tax_rates")
        tax_count = cursor.fetchone()[0]
        cursor.close()
        conn.close()
        
        return jsonify({
            'status': 'ok',
            'service': 'Pricing Service',
            'database': 'connected',
            'pricing_rules': rules_count,
            'tax_rates': tax_count
        }), 200
    except Exception as e:
        return jsonify({
            'status': 'error',
            'error': str(e)
        }), 500


# ============================================================
# Main
# ============================================================

if __name__ == '__main__':
    logger.info("=" * 60)
    logger.info("🚀 STARTING PRICING SERVICE")
    logger.info("Port: 5003")
    logger.info("Database: ecommerce_system")
    logger.info("=" * 60)
    
    # Test database connection on startup
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM pricing_rules")
        rules_count = cursor.fetchone()[0]
        cursor.execute("SELECT COUNT(*) FROM tax_rates")
        tax_count = cursor.fetchone()[0]
        cursor.close()
        conn.close()
        
        logger.info(f"✓ Database connected successfully")
        logger.info(f"✓ Found {rules_count} pricing rules")
        logger.info(f"✓ Found {tax_count} tax rates")
        logger.info("=" * 60)
    except Exception as e:
        logger.error(f"✗ Database connection failed: {e}")
        logger.error("Service may not work properly!")
        logger.info("=" * 60)
    
    app.run(
        host='0.0.0.0',
        port=5003,
        debug=True
    )
