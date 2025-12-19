package com.ecommerce.servlets;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;

import java.io.IOException;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;


@WebServlet("/getProducts")
public class InventoryServlet extends HttpServlet {


    private static final String INVENTORY_SERVICE_URL = "http://localhost:5002/inventory";


    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        System.out.println("========================================");
        System.out.println("INVENTORY SERVLET: Fetching products");
        System.out.println("========================================");

        try {

            String productsJson = sendGetRequest(INVENTORY_SERVICE_URL);
            System.out.println("Products received: " + productsJson);

            Gson gson = new Gson();


            JsonArray productsArray = gson.fromJson(productsJson, JsonArray.class);
            List<Product> products = new ArrayList<>();


            for (int i = 0; i < productsArray.size(); i++) {
                JsonObject productJson = productsArray.get(i).getAsJsonObject();

                Product product = new Product();
                product.setProductId(productJson.get("product_id").getAsInt());
                product.setProductName(productJson.get("product_name").getAsString());
                product.setQuantityAvailable(productJson.get("quantity_available").getAsInt());
                product.setUnitPrice(productJson.get("unit_price").getAsDouble());

                products.add(product);
            }


            request.setAttribute("products", products);
            request.setAttribute("success", true);

            System.out.println("✓ " + products.size() + " products loaded successfully");


            request.getRequestDispatcher("index.jsp").forward(request, response);

        } catch (Exception e) {
            System.err.println("ERROR in InventoryServlet: " + e.getMessage());
            e.printStackTrace();


            request.setAttribute("products", new ArrayList<>());
            request.setAttribute("success", false);
            request.setAttribute("error", "Cannot connect to Inventory Service: " + e.getMessage());

            request.getRequestDispatcher("index.jsp").forward(request, response);
        }
    }


    private String sendGetRequest(String urlString) throws IOException {
        URL url = new URL(urlString);
        HttpURLConnection connection = (HttpURLConnection) url.openConnection();

        try {
            connection.setRequestMethod("GET");
            connection.setRequestProperty("Accept", "application/json");
            connection.setConnectTimeout(5000);
            connection.setReadTimeout(5000);

            int responseCode = connection.getResponseCode();
            System.out.println("Response Code: " + responseCode);

            if (responseCode >= 200 && responseCode < 300) {
                BufferedReader br = new BufferedReader(
                        new InputStreamReader(connection.getInputStream(), "utf-8")
                );
                String response = br.lines().collect(Collectors.joining());
                br.close();
                return response;
            } else {
                throw new IOException("HTTP error code: " + responseCode);
            }

        } finally {
            connection.disconnect();
        }
    }


    public static class Product {
        private int productId;
        private String productName;
        private int quantityAvailable;
        private double unitPrice;


        public int getProductId() {
            return productId;
        }

        public void setProductId(int productId) {
            this.productId = productId;
        }

        public String getProductName() {
            return productName;
        }

        public void setProductName(String productName) {
            this.productName = productName;
        }

        public int getQuantityAvailable() {
            return quantityAvailable;
        }

        public void setQuantityAvailable(int quantityAvailable) {
            this.quantityAvailable = quantityAvailable;
        }

        public double getUnitPrice() {
            return unitPrice;
        }

        public void setUnitPrice(double unitPrice) {
            this.unitPrice = unitPrice;
        }
    }
}