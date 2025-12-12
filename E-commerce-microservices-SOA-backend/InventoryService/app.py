from flask import Flask, request, jsonify, abort
import mysql.connector
from mysql.connector import pooling, Error
from decimal import Decimal

# --- CONFIG: adjust as needed ---
DB_CONFIG = {
    "host": "localhost",
    "user": "ecommerce_user",
    "password": "123456",
    "database": "ecommerce_system",
    "autocommit": False
}
POOL_SIZE = 5
# -------------------------------

app = Flask(__name__)

# Create a connection pool
try:
    pool = mysql.connector.pooling.MySQLConnectionPool(
        pool_name="inventory_pool",
        pool_size=POOL_SIZE,
        **DB_CONFIG
    )
except Error as e:
    raise RuntimeError(f"Error creating DB pool: {e}")

def get_conn():
    """Get a connection from the pool."""
    return pool.get_connection()

def decimal_to_native(value):
    """Convert Decimal to float (or return None)."""
    if value is None:
        return None
    if isinstance(value, Decimal):
        return float(value)
    return value

# -----------------------
# Helper: fetch inventory
# -----------------------
def row_to_item(row):
    # row is tuple in column order we selected
    # We'll return a dict matching the inventory table
    (product_id, product_name, quantity_available, unit_price, last_updated) = row
    return {
        "product_id": product_id,
        "product_name": product_name,
        "quantity_available": quantity_available,
        "unit_price": decimal_to_native(unit_price),
        "last_updated": last_updated.isoformat() if last_updated else None
    }

# -----------------------
# CRUD Routes
# -----------------------

# Create - add a new product
@app.route("/inventory", methods=["POST"])
def create_product():
    data = request.get_json(force=True, silent=True)
    if not data:
        return jsonify({"error": "JSON body required"}), 400

    name = data.get("product_name")
    quantity = data.get("quantity_available")
    unit_price = data.get("unit_price")

    if not name or quantity is None or unit_price is None:
        return jsonify({"error": "product_name, quantity_available, and unit_price are required"}), 400

    try:
        conn = get_conn()
        cursor = conn.cursor()
        sql = """
            INSERT INTO inventory (product_name, quantity_available, unit_price)
            VALUES (%s, %s, %s)
        """
        cursor.execute(sql, (name, int(quantity), unit_price))
        conn.commit()
        new_id = cursor.lastrowid
        cursor.close()
        conn.close()
        return jsonify({"message": "Product created", "product_id": new_id}), 201
    except Error as e:
        return jsonify({"error": str(e)}), 500

# Read - list all products
@app.route("/inventory", methods=["GET"])
def list_products():
    try:
        conn = get_conn()
        cursor = conn.cursor()
        cursor.execute("SELECT product_id, product_name, quantity_available, unit_price, last_updated FROM inventory")
        rows = cursor.fetchall()
        cursor.close()
        conn.close()
        items = [row_to_item(r) for r in rows]
        return jsonify(items), 200
    except Error as e:
        return jsonify({"error": str(e)}), 500

# Read - get single product by id
@app.route("/inventory/<int:product_id>", methods=["GET"])
def get_product(product_id):
    try:
        conn = get_conn()
        cursor = conn.cursor()
        cursor.execute(
            "SELECT product_id, product_name, quantity_available, unit_price, last_updated FROM inventory WHERE product_id = %s",
            (product_id,)
        )
        row = cursor.fetchone()
        cursor.close()
        conn.close()
        if not row:
            return jsonify({"error": "Product not found"}), 404
        return jsonify(row_to_item(row)), 200
    except Error as e:
        return jsonify({"error": str(e)}), 500

# Update - full or partial update
@app.route("/inventory/<int:product_id>", methods=["PUT", "PATCH"])
def update_product(product_id):
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

    # update last_updated explicitly to CURRENT_TIMESTAMP
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
            return jsonify({"error": "Product not found"}), 404
        return jsonify({"message": "Product updated", "product_id": product_id}), 200
    except Error as e:
        return jsonify({"error": str(e)}), 500

# Delete - remove product
@app.route("/inventory/<int:product_id>", methods=["DELETE"])
def delete_product(product_id):
    try:
        conn = get_conn()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM inventory WHERE product_id = %s", (product_id,))
        conn.commit()
        deleted = cursor.rowcount
        cursor.close()
        conn.close()
        if deleted == 0:
            return jsonify({"error": "Product not found"}), 404
        return jsonify({"message": "Product deleted", "product_id": product_id}), 200
    except Error as e:
        return jsonify({"error": str(e)}), 500


# Health check
@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"}), 200

if __name__ == "__main__":
    app.run(debug=True)
