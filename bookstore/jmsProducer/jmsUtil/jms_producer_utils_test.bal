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

package bookstore.jmsProducer.jmsUtil;

import ballerina.net.jms;
import ballerina.test;

//  Unit test for testing getConnectorConfig() function
function testGetConnectorConfig () {
    // Get the JMS client properties
    jms:ClientProperties properties = getConnectorConfig();
    // 'properties' should not be null
    test:assertTrue(properties != null, "Cannot obtain JMS client connector configurations!");
    // Check whether the configurations are as expected
    test:assertStringEquals("QueueConnectionFactory", properties.connectionFactoryName,
                            "Jms client connector configurations mismatch!");
    test:assertStringEquals("queue", properties.connectionFactoryType,
                            "Jms client connection configurations mismatch!");
}

//  Unit test for testing addToJmsQueue() function
function testAddToJmsQueue () {
    // Construct a new message
    string message = "Test JMS Message";
    // Add the message to the JMS queue 'TestQueue'
    error jmsError = addToJmsQueue("TestQueue", message);
    // 'jmsError' is expected to be null
    test:assertTrue(jmsError == null, "Cannot add new message to the JMS queue specified! Error Msg: " + jmsError.msg);
}
