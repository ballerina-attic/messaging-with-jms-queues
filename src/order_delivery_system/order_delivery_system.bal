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

package order_delivery_system;

import ballerina/log;
import ballerina/net.jms;

@Description {value:"Service level annotation to provide connection details.
                      Connection factory type can be either queue or topic depending on the requirement."}

// JMS Configurations
// 'Apache ActiveMQ' has been used as the message broker
endpoint jms:ConsumerEndpoint jmsConsumerEP {
    initialContextFactory:"org.apache.activemq.jndi.ActiveMQInitialContextFactory",
    providerUrl:"tcp://localhost:61616"
};

@jms:ServiceConfig {
    destination:"OrderQueue"
}
// JMS service that consumes messages from the JMS queue
service<jms:Service> orderDeliverySystem bind jmsConsumerEP {
    // Triggered whenever an order is added to the 'OrderQueue'
    onMessage (endpoint client, jms:Message message) {
        log:printInfo("New order received from the JMS Queue");
        // Retrieve the string payload using native function
        string stringPayload = message.getTextMessageContent();
        log:printInfo("Order Details: " + stringPayload);
    }
}
