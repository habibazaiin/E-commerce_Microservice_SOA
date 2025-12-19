
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


@WebServlet("/submitOrder")
public class OrderServlet extends HttpServlet {


    private static final String ORDER_SERVICE_URL = "http://localhost:5001/api/orders/create";


    private static final int CONNECTION_TIMEOUT = 60000;
    private static final int READ_TIMEOUT = 60000;


    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        System.out.println("========================================");
        System.out.println("ORDER SERVLET: New order request received");
        System.out.println("========================================");

        try {

            String customerId = request.getParameter("customer_id");
            String productIds = request.getParameter("product_ids");
            String quantities = request.getParameter("quantities");

            System.out.println("Customer ID: " + customerId);
            System.out.println("Product IDs: " + productIds);
            System.out.println("Quantities: " + quantities);

            if (customerId == null || productIds == null || quantities == null) {
                request.setAttribute("error", "Missing required fields");
                request.getRequestDispatcher("checkout.jsp").forward(request, response);
                return;
            }


            String jsonPayload = buildJsonPayload(customerId, productIds, quantities);
            System.out.println("JSON Payload: " + jsonPayload);

            System.out.println("Sending request to Order Service...");
            String orderServiceResponse = sendPostRequest(ORDER_SERVICE_URL, jsonPayload);
            System.out.println("Order Service Response: " + orderServiceResponse);


            Gson gson = new Gson();
            JsonObject responseJson = gson.fromJson(orderServiceResponse, JsonObject.class);


            boolean success = responseJson.has("success") && responseJson.get("success").getAsBoolean();

            if (success) {

                request.setAttribute("orderData", responseJson);
                request.setAttribute("success", true);

                System.out.println("✓ Order created successfully!");
                request.getRequestDispatcher("confirmation.jsp").forward(request, response);
            } else {

                String errorMessage = responseJson.has("error")
                        ? responseJson.get("error").getAsString()
                        : "Unknown error occurred";

                request.setAttribute("error", errorMessage);
                request.setAttribute("success", false);

                System.out.println("✗ Order failed: " + errorMessage);
                request.getRequestDispatcher("checkout.jsp").forward(request, response);
            }

        } catch (Exception e) {
            System.err.println("ERROR in OrderServlet: " + e.getMessage());
            e.printStackTrace();

            request.setAttribute("error", "Internal server error: " + e.getMessage());
            request.setAttribute("success", false);
            request.getRequestDispatcher("checkout.jsp").forward(request, response);
        }
    }


    private String buildJsonPayload(String customerId, String productIds, String quantities) {
        Gson gson = new Gson();


        JsonObject payload = new JsonObject();
        payload.addProperty("customer_id", Integer.parseInt(customerId));


        JsonArray productsArray = new JsonArray();

        String[] productIdArray = productIds.split(",");
        String[] quantityArray = quantities.split(",");


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


    private String sendPostRequest(String urlString, String jsonPayload) throws IOException {
        URL url = new URL(urlString);
        HttpURLConnection connection = (HttpURLConnection) url.openConnection();

        try {

            connection.setRequestMethod("POST");
            connection.setRequestProperty("Content-Type", "application/json");
            connection.setRequestProperty("Accept", "application/json");
            connection.setDoOutput(true);


            connection.setConnectTimeout(CONNECTION_TIMEOUT);
            connection.setReadTimeout(READ_TIMEOUT);

            System.out.println("Connection timeout: " + CONNECTION_TIMEOUT + "ms");
            System.out.println("Read timeout: " + READ_TIMEOUT + "ms");


            try (OutputStream os = connection.getOutputStream()) {
                byte[] input = jsonPayload.getBytes("utf-8");
                os.write(input, 0, input.length);
            }


            int responseCode = connection.getResponseCode();
            System.out.println("Response Code: " + responseCode);

            BufferedReader br;
            if (responseCode >= 200 && responseCode < 300) {

                br = new BufferedReader(new InputStreamReader(connection.getInputStream(), "utf-8"));
            } else {

                br = new BufferedReader(new InputStreamReader(connection.getErrorStream(), "utf-8"));
            }

            String response = br.lines().collect(Collectors.joining());
            br.close();

            return response;

        } finally {
            connection.disconnect();
        }
    }


    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect("checkout.jsp");
    }
}