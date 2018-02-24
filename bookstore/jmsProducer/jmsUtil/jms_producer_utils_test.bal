package bookstore.jmsProducer.jmsUtil;

import ballerina.test;
import ballerina.net.jms;

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
