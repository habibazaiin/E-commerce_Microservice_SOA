<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <title>E-Commerce System - Test Page</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
        }
        .status {
            padding: 15px;
            margin: 10px 0;
            border-radius: 4px;
        }
        .success {
            background-color: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        button {
            background-color: #007bff;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
        }
        button:hover {
            background-color: #0056b3;
        }
    </style>
</head>
<body>
<div class="container">
    <h1>🛒 E-Commerce Order Management System</h1>

    <div class="status success">
        ✓ JSP Application is running successfully!
    </div>

    <h2>System Status:</h2>
    <ul>
        <li>Java JSP Frontend: <strong>Port 8080</strong> ✓</li>
        <li>Order Service: Port 5001</li>
        <li>Inventory Service: Port 5002</li>
        <li>Pricing Service: Port 5003</li>
        <li>Customer Service: Port 5004</li>
        <li>Notification Service: Port 5005</li>
    </ul>

    <h2>Test Connection:</h2>
    <form action="testConnection" method="get">
        <button type="submit">Test Flask Services Connection</button>
    </form>

    <hr>

    <p><strong>Current Time:</strong> <%= new java.util.Date() %></p>
    <p><strong>Server Info:</strong> <%= application.getServerInfo() %></p>
</div>
</body>
</html>