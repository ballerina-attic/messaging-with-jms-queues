package bookstore.jmsProducer.jmsUtil;

import ballerina.net.jms;
import ballerina.log;

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
    // 'WSO2 EI Message Broker' from product 'EI' has been used as the message broker in this example
    properties = {initialContextFactory:"wso2mbInitialContextFactory",
                     providerUrl:"amqp://admin:admin@carbon/carbon?brokerlist='tcp://localhost:5675'",
                     connectionFactoryName:"QueueConnectionFactory",
                     connectionFactoryType:"queue"};
    return;
}
