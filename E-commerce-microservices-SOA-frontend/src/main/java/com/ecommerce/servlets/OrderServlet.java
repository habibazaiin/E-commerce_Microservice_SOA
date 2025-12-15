package com.ecommerce.servlets;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.google.gson.JsonArray;

import java.io.IOException;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.stream.Collectors;

/**
 * OrderServlet - معالج طلبات الشراء
 *
 * المهام:
 * 1. استقبال بيانات الفورم من checkout.jsp
 * 2. تحويل البيانات إلى JSON
 * 3. إرسال POST request لـ Order Service
 * 4. استقبال الرد
 * 5. إرسال البيانات لـ confirmation.jsp
 *
 * @author Your Name
 */
@WebServlet("/submitOrder")
public class OrderServlet extends HttpServlet {

    // Order Service URL
    private static final String ORDER_SERVICE_URL = "http://localhost:5001/api/orders/create";

    /**
     * معالجة POST requests من checkout.jsp
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // تسجيل استقبال الطلب
        System.out.println("========================================");
        System.out.println("ORDER SERVLET: New order request received");
        System.out.println("========================================");

        try {
            // الخطوة 1: الحصول على البيانات من الفورم
            String customerId = request.getParameter("customer_id");
            String productIds = request.getParameter("product_ids"); // "1,2,3"
            String quantities = request.getParameter("quantities");   // "2,1,3"

            System.out.println("Customer ID: " + customerId);
            System.out.println("Product IDs: " + productIds);
            System.out.println("Quantities: " + quantities);

            // التحقق من وجود البيانات
            if (customerId == null || productIds == null || quantities == null) {
                request.setAttribute("error", "Missing required fields");
                request.getRequestDispatcher("checkout.jsp").forward(request, response);
                return;
            }

            // الخطوة 2: تحويل البيانات إلى JSON
            String jsonPayload = buildJsonPayload(customerId, productIds, quantities);
            System.out.println("JSON Payload: " + jsonPayload);

            // الخطوة 3: إرسال الطلب لـ Order Service
            String orderServiceResponse = sendPostRequest(ORDER_SERVICE_URL, jsonPayload);
            System.out.println("Order Service Response: " + orderServiceResponse);

            // الخطوة 4: معالجة الرد
            Gson gson = new Gson();
            JsonObject responseJson = gson.fromJson(orderServiceResponse, JsonObject.class);

            // التحقق من نجاح الطلب
            boolean success = responseJson.has("success") && responseJson.get("success").getAsBoolean();

            if (success) {
                // نجح الطلب - إرسال البيانات لصفحة التأكيد
                request.setAttribute("orderData", responseJson);
                request.setAttribute("success", true);

                System.out.println("✓ Order created successfully!");
                request.getRequestDispatcher("confirmation.jsp").forward(request, response);
            } else {
                // فشل الطلب - إرسال رسالة الخطأ
                String errorMessage = responseJson.has("error")
                        ? responseJson.get("error").getAsString()
                        : "Unknown error occurred";

                request.setAttribute("error", errorMessage);
                request.setAttribute("success", false);

                System.out.println("✗ Order failed: " + errorMessage);
                request.getRequestDispatcher("checkout.jsp").forward(request, response);
            }

        } catch (Exception e) {
            // معالجة الأخطاء
            System.err.println("ERROR in OrderServlet: " + e.getMessage());
            e.printStackTrace();

            request.setAttribute("error", "Internal server error: " + e.getMessage());
            request.setAttribute("success", false);
            request.getRequestDispatcher("checkout.jsp").forward(request, response);
        }
    }

    /**
     * بناء JSON payload من بيانات الفورم
     *
     * @param customerId معرف العميل
     * @param productIds معرفات المنتجات (مفصولة بفاصلة)
     * @param quantities الكميات (مفصولة بفاصلة)
     * @return JSON string
     */
    private String buildJsonPayload(String customerId, String productIds, String quantities) {
        Gson gson = new Gson();

        // إنشاء JSON object
        JsonObject payload = new JsonObject();
        payload.addProperty("customer_id", Integer.parseInt(customerId));

        // إنشاء مصفوفة المنتجات
        JsonArray productsArray = new JsonArray();

        String[] productIdArray = productIds.split(",");
        String[] quantityArray = quantities.split(",");

        // التأكد من تطابق الأطوال
        int length = Math.min(productIdArray.length, quantityArray.length);

        for (int i = 0; i < length; i++) {
            JsonObject product = new JsonObject();
            product.addProperty("product_id", Integer.parseInt(productIdArray[i].trim()));
            product.addProperty("quantity", Integer.parseInt(quantityArray[i].trim()));
            productsArray.add(product);
        }

        payload.add("products", productsArray);

        return gson.toJson(payload);
    }

    /**
     * إرسال POST request لـ Flask Service
     *
     * @param urlString URL الخدمة
     * @param jsonPayload البيانات بصيغة JSON
     * @return رد الخدمة
     * @throws IOException في حالة فشل الاتصال
     */
    private String sendPostRequest(String urlString, String jsonPayload) throws IOException {
        URL url = new URL(urlString);
        HttpURLConnection connection = (HttpURLConnection) url.openConnection();

        try {
            // إعداد الاتصال
            connection.setRequestMethod("POST");
            connection.setRequestProperty("Content-Type", "application/json");
            connection.setRequestProperty("Accept", "application/json");
            connection.setDoOutput(true);
            connection.setConnectTimeout(5000); // 5 ثواني timeout
            connection.setReadTimeout(5000);

            // إرسال JSON payload
            try (OutputStream os = connection.getOutputStream()) {
                byte[] input = jsonPayload.getBytes("utf-8");
                os.write(input, 0, input.length);
            }

            // قراءة الرد
            int responseCode = connection.getResponseCode();
            System.out.println("Response Code: " + responseCode);

            BufferedReader br;
            if (responseCode >= 200 && responseCode < 300) {
                // نجح الطلب
                br = new BufferedReader(new InputStreamReader(connection.getInputStream(), "utf-8"));
            } else {
                // فشل الطلب
                br = new BufferedReader(new InputStreamReader(connection.getErrorStream(), "utf-8"));
            }

            String response = br.lines().collect(Collectors.joining());
            br.close();

            return response;

        } finally {
            connection.disconnect();
        }
    }

    /**
     * معالجة GET requests (إعادة توجيه لصفحة checkout)
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect("checkout.jsp");
    }
}