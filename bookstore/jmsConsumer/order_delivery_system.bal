package bookstore.jmsConsumer;

import ballerina.log;
import ballerina.net.jms;

@Description {value:"Service level annotation to provide connection details.
                      Connection factory type can be either queue or topic depending on the requirement."}

// JMS Configurations
// 'Apache ActiveMQ' has been used as the message broker
@jms:configuration {
    initialContextFactory:"org.apache.activemq.jndi.ActiveMQInitialContextFactory",
    providerUrl:
    "tcp://localhost:61616",
    connectionFactoryType:"queue",
    connectionFactoryName:"QueueConnectionFactory",
    destination:"OrderQueue"
}

// JMS service that consumes messages from the JMS queue
service<jms> orderDeliverySystem {
    // Triggered whenever an order is added to the 'OrderQueue'
    resource onMessage (jms:JMSMessage message) {
        log:printInfo("New order received from the JMS Queue");
        // Retrieve the string payload using native function
        string stringPayload = message.getTextMessageContent();
        log:printInfo("Order Details: " + stringPayload);
    }
}
