package bookstore.jmsProducer;

import ballerina.test;
import ballerina.net.http;

function testBookstoreService () {
    endpoint<http:HttpClient> httpEndpoint {
        create http:HttpClient("http://localhost:9090/bookstore", {});
    }
    // Initialize the empty http requests and responses
    http:OutRequest getBooksRequest = {};
    http:InResponse getBooksResponse = {};
    http:OutRequest placeOrderRequest = {};
    http:InResponse placeOrderResponse = {};
    http:HttpConnectorError httpErrorGet;
    http:HttpConnectorError httpErrorPost;

    // Start bookstore service
    _ = test:startService("bookstoreService");

    // Test the 'getAvailableBooks' resource
    // Send a 'get' request and obtain the response
    getBooksResponse, httpErrorGet = httpEndpoint.get("/getAvailableBooks", getBooksRequest);
    // 'httpErrorGet' is expected to be null
    test:assertTrue(httpErrorGet == null, "Cannot get the available books from the service! Error: " + httpErrorGet.msg);
    // Expected response code is 200
    test:assertIntEquals(getBooksResponse.statusCode, 200, "bookstore service did not respond with 200 OK signal!");
    // Check whether the response is as expected
    test:assertTrue(getBooksResponse.getJsonPayload().toString().contains("Lolita"), "Response mismatch!");

    // Test the 'placeOrder' resource
    // Construct a request payload
    placeOrderRequest.setJsonPayload({"Name":"Alice", "Address":"20, Palm Grove, Colombo, Sri Lanka",
                                         "ContactNumber":"+94777123456", "BookName":"The Rainbow"});
    // Send a 'post' request and obtain the response
    placeOrderResponse, httpErrorPost = httpEndpoint.post("/placeOrder", placeOrderRequest);
    // 'httpErrorPost' is expected to be null
    test:assertTrue(httpErrorPost == null, "Cannot place order! Error: " + httpErrorPost.msg);
    // Expected response code is 200
    test:assertIntEquals(placeOrderResponse.statusCode, 200, "bookstore service did not respond with 200 OK signal!");
    // Check whether the response is as expected
    test:assertStringEquals(placeOrderResponse.getJsonPayload().toString(),
                            "{\"Message\":\"Your order is successfully placed. Ordered book will be delivered soon\"}",
                            "Response mismatch!");
}
