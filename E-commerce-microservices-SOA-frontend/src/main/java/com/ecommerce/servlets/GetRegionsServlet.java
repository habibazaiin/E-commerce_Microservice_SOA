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
import java.util.stream.Collectors;

@WebServlet("/getRegions")
public class GetRegionsServlet extends HttpServlet {

    private static final String PRICING_SERVICE_URL = "http://localhost:5003/api/pricing/regions";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        System.out.println("========================================");
        System.out.println("GET REGIONS: Fetching regions from DB");
        System.out.println("========================================");

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        try {
            // Call Pricing Service to get regions
            String regionsJson = sendGetRequest(PRICING_SERVICE_URL);
            System.out.println("Regions data received: " + regionsJson);

            // Return JSON directly
            response.getWriter().write(regionsJson);
            System.out.println("✓ Regions list sent to client");

        } catch (Exception e) {
            System.err.println("ERROR in GetRegionsServlet: " + e.getMessage());
            e.printStackTrace();

            // Return error as JSON
            JsonObject error = new JsonObject();
            error.addProperty("success", false);
            error.addProperty("error", "Cannot connect to Pricing Service: " + e.getMessage());

            response.getWriter().write(error.toString());
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