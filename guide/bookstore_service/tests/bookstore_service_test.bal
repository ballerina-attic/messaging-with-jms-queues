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

import ballerina/http;
import ballerina/test;

// Client endpoint
http:Client clientEP = new("http://localhost:9090/bookstore");

// Function to test 'getBookList' resource
@test:Config
function testResourceGetBookList() {
    // Initialize the empty http request
    http:Request req = new;

    // Send a 'get' request and obtain the response
    var response = clientEP->get("/getBookList", message = req);
    if (response is http:Response) {
        // Expected response code is 200
        test:assertEquals(response.statusCode, 200, msg = "bookstore service did not respond with 200 OK signal!");
        // Check whether the response is as expected
        var resPayload = response.getJsonPayload();
        if (resPayload is json) {
            string stringPayload = resPayload.toString();
            test:assertTrue(stringPayload.contains("Lolita"), msg = "Response mismatch!");
        } else {
            test:assertFail(msg = "Failed to retrieve the payload");
        }
    } else {
        test:assertFail(msg = "Error sending request");
    }
}

// Function to test 'placeOrder' resource
@test:Config
function testResourcePlaceOrder() {
    // Initialize the empty http request
    http:Request req = new;
    // Construct a request payload
    json payload = {
        "Name": "Alice",
        "Address": "20, Palm Grove, Colombo, Sri Lanka",
        "ContactNumber": "+94777123456",
        "BookName": "The Rainbow"
    };
    req.setJsonPayload(payload);
    // Send a 'post' request and obtain the response
    var response = clientEP->post("/placeOrder", req);
    if (response is http:Response) {
        // Expected response code is 200
        test:assertEquals(response.statusCode, 200, msg = "bookstore service did not respond with 200 OK signal!");
        // Check whether the response is as expected
        var resPayload = response.getJsonPayload();
        if (resPayload is json) {
            json expected = { "Message": "Your order is successfully placed. Ordered book will be delivered soon" };
            test:assertEquals(resPayload, expected, msg = "Response mismatch!");
        } else {
            test:assertFail(msg = "Failed to retrieve the payload");
        }
    } else {
        test:assertFail(msg = "Error sending request");
    }
}
