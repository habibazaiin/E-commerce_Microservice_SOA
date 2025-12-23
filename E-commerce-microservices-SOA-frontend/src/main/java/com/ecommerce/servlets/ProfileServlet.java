package com.ecommerce.servlets;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import com.google.gson.Gson;
import com.google.gson.JsonObject;

import java.io.IOException;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.stream.Collectors;

@WebServlet("/getProfile")
public class ProfileServlet extends HttpServlet {

    private static final String CUSTOMER_SERVICE_URL = "http://localhost:5004/api/customers/";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        System.out.println("========================================");
        System.out.println("PROFILE SERVLET: Fetching customer profile");
        System.out.println("========================================");

        try {
            // Get customer ID from parameter (default to 1 for demo)
            String customerIdParam = request.getParameter("customer_id");
            int customerId = (customerIdParam != null) ? Integer.parseInt(customerIdParam) : 1;

            System.out.println("Customer ID: " + customerId);

            // Call Customer Service
            String customerJson = sendGetRequest(CUSTOMER_SERVICE_URL + customerId);
            System.out.println("Customer data received: " + customerJson);

            // Parse JSON response
            Gson gson = new Gson();
            JsonObject customerData = gson.fromJson(customerJson, JsonObject.class);

            // Set attributes for JSP
            request.setAttribute("customerData", customerData);
            request.setAttribute("success", true);

            System.out.println("✓ Customer profile loaded successfully");

            // Forward to profile.jsp
            request.getRequestDispatcher("profile.jsp").forward(request, response);

        } catch (NumberFormatException e) {
            System.err.println("ERROR: Invalid customer ID format");
            request.setAttribute("success", false);
            request.setAttribute("error", "Invalid customer ID");
            request.getRequestDispatcher("profile.jsp").forward(request, response);

        } catch (Exception e) {
            System.err.println("ERROR in ProfileServlet: " + e.getMessage());
            e.printStackTrace();

            request.setAttribute("success", false);
            request.setAttribute("error", "Cannot connect to Customer Service: " + e.getMessage());
            request.getRequestDispatcher("profile.jsp").forward(request, response);
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
}