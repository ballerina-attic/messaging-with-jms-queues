// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/log;
import ballerina/http;
import ballerina/jms;

// Type definition for a book order
type bookOrder record {
    string customerName?;
    string address?;
    string contactNumber?;
    string orderedBookName?;
};

// Global variable containing all the available books
json[] bookInventory = ["Tom Jones", "The Rainbow", "Lolita", "Atonement", "Hamlet"];

// Initialize a JMS connection with the provider
// 'providerUrl' and 'initialContextFactory' vary based on the JMS provider you use
// 'Apache ActiveMQ' has been used as the message broker in this example
jms:Connection jmsConnection = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection
jms:Session jmsSession = new(jmsConnection, {
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

// Initialize a queue sender using the created session
jms:QueueSender jmsProducer = new(jmsSession, queueName = "OrderQueue");

// Service endpoint
listener http:Listener httpListener = new(9090);

// Book store service, which allows users to order books online for delivery
@http:ServiceConfig { basePath: "/bookstore" }
service bookstoreService on httpListener {
    // Resource that allows users to place an order for a book
    @http:ResourceConfig {
        methods: ["POST"],
        consumes: ["application/json"],
        produces: ["application/json"]
    }
    resource function placeOrder(http:Caller caller, http:Request request) {
        http:Response response = new;
        bookOrder newOrder = {};
        json reqPayload = ();

        // Try parsing the JSON payload from the request
        var payload = request.getJsonPayload();
        if (payload is json) {
            // Valid JSON payload
            reqPayload = payload;
        } else {
            // Not a valid JSON payload
            response.statusCode = 400;
            response.setJsonPayload({ "Message": "Invalid payload - Not a valid JSON payload" });
            var result = caller->respond(response);
            if (result is error) {
                log:printError("Error sending response", err = result);
            }
            return;
        }

        json name = reqPayload.Name;
        json address = reqPayload.Address;
        json contact = reqPayload.ContactNumber;
        json bookName = reqPayload.BookName;

        // If payload parsing fails, send a "Bad Request" message as the response
        if (name == null || address == null || contact == null || bookName == null) {
            response.statusCode = 400;
            response.setJsonPayload({ "Message": "Bad Request - Invalid payload" });
            var result = caller->respond(response);
            if (result is error) {
                log:printError("Error sending response", err = result);
            }
            return;
        }

        // Order details
        newOrder.customerName = name.toString();
        newOrder.address = address.toString();
        newOrder.contactNumber = contact.toString();
        newOrder.orderedBookName = bookName.toString();

        // boolean variable to track the availability of a requested book
        boolean isBookAvailable = false;
        // Check whether the requested book is available
        foreach var book in bookInventory {
            if (newOrder.orderedBookName.equalsIgnoreCase(book.toString())) {
                isBookAvailable = true;
                break;
            }
        }

        json responseMessage = ();
        // If the requested book is available, then add the order to the 'OrderQueue'
        if (isBookAvailable) {
            var bookOrderDetails = json.convert(newOrder);
            // Create a JMS message
            if (bookOrderDetails is json) {
                var queueMessage = jmsSession.createTextMessage(bookOrderDetails.toString());
                if (queueMessage is jms:Message) {
                    // Send the message to the JMS queue
                    var result = jmsProducer->send(queueMessage);
                    if (result is error) {
                        log:printError("Error sending the message", err = result);
                    }
                    // Construct a success message for the response
                    responseMessage = { "Message": "Your order is successfully placed."
                            + " Ordered book will be delivered soon" };
                    log:printInfo("New order added to the JMS Queue; CustomerName: '"
                            + newOrder.customerName + "', OrderedBook: '"
                            + newOrder.orderedBookName + "';");
                }
            }
        }
        else {
            // If book is not available, construct a proper response message to notify user
            responseMessage = { "Message": "Requested book not available" };
        }

        // Send response to the user
        response.setJsonPayload(responseMessage);
        var result = caller->respond(response);
        if (result is error) {
            log:printError("Error sending response", err = result);
        }
    }

    // Resource that allows users to get a list of all the available books
    @http:ResourceConfig {
        methods: ["GET"],
        produces: ["application/json"]
    }
    resource function getBookList(http:Caller caller, http:Request request) {
        http:Response response = new;
        // Send json array 'bookInventory' as the response, which contains all the available books
        response.setJsonPayload(bookInventory);
        var result = caller->respond(response);
        if (result is error) {
            log:printError("Error sending response", err = result);
        }
    }
}
