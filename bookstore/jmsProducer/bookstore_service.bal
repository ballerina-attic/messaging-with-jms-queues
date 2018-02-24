package bookstore.jmsProducer;

import ballerina.log;
import ballerina.net.http;
import bookstore.jmsProducer.jmsUtil;

// Struct to construct an order
struct order {
    string customerName;
    string address;
    string contactNumber;
    string orderedBookName;
}

// Global variable containing all the available books
json[] bookInventory = ["Tom Jones", "The Rainbow", "Lolita", "Atonement", "Hamlet"];

// Book store service, which allows users to order books online for delivery
@http:configuration {basePath:"/bookStore"}
service<http> bookstoreService {
    // Resource that allows users to place an order for a book
    @http:resourceConfig {methods:["POST"]}
    resource placeOrder (http:Connection httpConnection, http:InRequest request) {
        http:OutResponse response = {};
        order bookOrder = {};

        // Try getting the JSON payload from the user request
        try {
            json reqPayload = request.getJsonPayload();
            bookOrder.customerName = reqPayload["Name"].toString();
            bookOrder.address = reqPayload["Address"].toString();
            bookOrder.contactNumber = reqPayload["ContactNumber"].toString();
            bookOrder.orderedBookName = reqPayload["BookName"].toString().trim();
        } catch (error err) {
            // If payload parsing fails, send a "Bad Request" message as the response
            response.statusCode = 400;
            response.setJsonPayload({"Message":"Bad Request: Invalid payload"});
            _ = httpConnection.respond(response);
            return;
        }

        // boolean variable to track the availability of a requested book
        boolean isBookAvailable;
        // Check whether the requested book available
        foreach book in bookInventory {
            if (bookOrder.orderedBookName.equalsIgnoreCase(book.toString())) {
                isBookAvailable = true;
                break;
            }
        }

        json responseMessage;
        // If requested book is available then try adding the order to the JMS queue 'OrderQueue'
        if (isBookAvailable) {
            var bookOrderDetails, _ = <json>bookOrder;
            error jmsError = jmsUtil:addToJmsQueue("OrderQueue", bookOrderDetails.toString());
            // If adding order to the JMS queue fails, send an "Internal Server Error" message as the response
            if (jmsError != null) {
                response.statusCode = 500;
                response.setJsonPayload({"Message":"Internal Server Error"});
                _ = httpConnection.respond(response);
                return;
            }
            // If order successfully added to the JMS queue, construct a success message for the response
            responseMessage = {"Message":"Your order is successfully placed. Ordered book will be delivered soon"};
            log:printInfo("New order added to the JMS Queue; CustomerName: '" + bookOrder.customerName
                          + "', OrderedBook: '" + bookOrder.orderedBookName + "';");
        }
        else {
            // If book is not available, construct a proper response message to notify user
            responseMessage = {"Message":"Requested book not available"};
        }

        // Send response to the user
        response.setJsonPayload(responseMessage);
        _ = httpConnection.respond(response);
    }

    // Resource that allows users to get a list of all the available books
    @http:resourceConfig {methods:["GET"]}
    resource getAvailableBooks (http:Connection httpConnection, http:InRequest request) {
        http:OutResponse response = {};
        // Send json array 'bookInventory' as the response, which contains all the available books
        response.setJsonPayload(bookInventory);
        _ = httpConnection.respond(response);
    }
}
