package com.ecommerce.servlets;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.HashMap;
import java.util.Map;

@WebServlet("/testConnection")
public class TestConnectionServlet extends HttpServlet {

    private static final Map<String, String> SERVICES = new HashMap<>();

    static {
        SERVICES.put("Order Service", "http://localhost:5001/api/health");
        SERVICES.put("Inventory Service", "http://localhost:5002/api/health");
        SERVICES.put("Pricing Service", "http://localhost:5003/api/health");
        SERVICES.put("Customer Service", "http://localhost:5004/api/health");
        SERVICES.put("Notification Service", "http://localhost:5005/api/health");
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("text/html;charset=UTF-8");
        PrintWriter out = response.getWriter();

        out.println("<!DOCTYPE html>");
        out.println("<html>");
        out.println("<head>");
        out.println("<title>Connection Test Results</title>");
        out.println("<style>");
        out.println("body { font-family: Arial; max-width: 800px; margin: 50px auto; padding: 20px; }");
        out.println(".service { padding: 15px; margin: 10px 0; border-radius: 4px; }");
        out.println(".online { background-color: #d4edda; border: 1px solid #c3e6cb; }");
        out.println(".offline { background-color: #f8d7da; border: 1px solid #f5c6cb; }");
        out.println("button { background: #007bff; color: white; padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; margin-top: 20px; }");
        out.println("</style>");
        out.println("</head>");
        out.println("<body>");
        out.println("<h1>🔌 Service Connection Test</h1>");

        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();

        for (Map.Entry<String, String> service : SERVICES.entrySet()) {
            String serviceName = service.getKey();
            String serviceUrl = service.getValue();

            out.println("<div class='service ");

            try {
                HttpRequest testRequest = HttpRequest.newBuilder()
                        .uri(URI.create(serviceUrl))
                        .GET()
                        .timeout(Duration.ofSeconds(3))
                        .build();

                HttpResponse<String> testResponse = client.send(
                        testRequest,
                        HttpResponse.BodyHandlers.ofString()
                );

                if (testResponse.statusCode() == 200) {
                    out.println("online'>");
                    out.println("<strong>✓ " + serviceName + "</strong> - ONLINE");
                    out.println("<br><small>Response: " + testResponse.body() + "</small>");
                } else {
                    out.println("offline'>");
                    out.println("<strong>✗ " + serviceName + "</strong> - OFFLINE (Status: " + testResponse.statusCode() + ")");
                }

            } catch (Exception e) {
                out.println("offline'>");
                out.println("<strong>✗ " + serviceName + "</strong> - OFFLINE");
                out.println("<br><small>Error: " + e.getMessage() + "</small>");
            }

            out.println("</div>");
        }

        out.println("<button onclick='window.location.reload()'>🔄 Test Again</button>");
        out.println("<button onclick='window.location=\"index.jsp\"'>← Back to Home</button>");
        out.println("</body>");
        out.println("</html>");
        out.close();
    }
}