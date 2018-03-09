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

package bookstore.jmsProducer;

import ballerina.net.http;
import ballerina.test;

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
