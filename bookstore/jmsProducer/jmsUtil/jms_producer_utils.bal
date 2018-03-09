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

import ballerina.log;
import ballerina.net.jms;

// Function to add messages to the JMS queue
public function addToJmsQueue (string queueName, string message) (error jmsError) {
    endpoint<jms:JmsClient> jmsEP {
    }

    // Try obtaining JMS client and add the order to the JMS queue
    try {
        jms:JmsClient jmsClient = create jms:JmsClient(getConnectorConfig());
        bind jmsClient with jmsEP;
        // Create an empty Ballerina message
        jms:JMSMessage queueMessage = jms:createTextMessage(getConnectorConfig());
        // Set a string payload to the message
        queueMessage.setTextMessageContent(message);
        // Send the message to the JMS provider
        jmsEP.send(queueName, queueMessage);
    } catch (error err) {
        log:printError(err.msg);
        // If obtaining JMS client fails, catch and return the error message
        jmsError = err;
    }

    return;
}

// Private function to get the JMS client connector configurations
function getConnectorConfig () (jms:ClientProperties properties) {
    // JMS client properties
    // 'providerUrl' or 'configFilePath', and the 'initialContextFactory' vary according to the JMS provider you use
    // 'Apache ActiveMQ' has been used as the message broker in this example
    properties = {initialContextFactory:"org.apache.activemq.jndi.ActiveMQInitialContextFactory",
                     providerUrl:"tcp://localhost:61616",
                     connectionFactoryName:"QueueConnectionFactory",
                     connectionFactoryType:"queue"};
    return;
}
