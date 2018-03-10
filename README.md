# Messaging with JMS Queues

Java Message Service (JMS) is used to send messages between two or more clients. JMS supports two models: point-to-point model and publish/subscribe model. This guide is based on the point-to-point model where messages are routed to an individual consumer that maintains a queue of "incoming" messages. This messaging type is built on the concept of message queues, senders, and receivers. Each message is addressed to a specific queue, and the receiving clients extract messages from the queues established to hold their messages. In the point-to-point model, each message is guaranteed to be delivered and consumed by one consumer in an asynchronous manner.

> This guide walks you through the process of using Ballerina to send messages with JMS queues using a message broker.

The following are the sections available in this guide.

- [What you'll build](#what-you-build)
- [Prerequisites](#pre-req)
- [Developing the RESTFul service with circuit breaker](#developing-service)
- [Testing](#testing)
- [Deployment](#deploying-the-scenario)
- [Observability](#observability)

## <a name="what-you-build"></a>  What you’ll build
To understand how you can use JMS queues for messaging, let's consider a real-world use case of an online bookstore service using which a user can order books for home delivery. Once an order is placed, the service will add it to a JMS queue named "OrderQueue" if the order is valid. Hence, this bookstore service acts as the JMS message producer. An order delivery system, which acts as the JMS message consumer polls the "OrderQueue" and gets the order details whenever the queue becomes populated. The below diagram illustrates this use case clearly.



![alt text](/images/JMS_queue.png)



In this example `Apache ActiveMQ` has been used as the JMS broker. Ballerina JMS Connector is used to connect Ballerina 
and JMS Message Broker. With this JMS Connector, Ballerina can act as both JMS Message Consumer and JMS Message 
Producer.

## <a name="pre-req"></a> Prerequisites
 
- JDK 1.8 or later
- [Ballerina Distribution](https://ballerinalang.org/docs/quick-tour/quick-tour/#install-ballerina)
- [Ballerina JMS Connector](https://github.com/ballerinalang/connector-jms/releases)
  * After downloading the zip file, extract it and copy the containing jars into <BALLERINA_HOME>/bre/lib folder
- A JMS Broker (Example: [Apache ActiveMQ](http://activemq.apache.org/getting-started.html))
  * After downloading and installing, copy the JMS Broker Client jars into <BALLERINA_HOME>/bre/lib folder
    * For ActiveMQ 5.12.0 - activemq-client-5.12.0.jar, geronimo-j2ee-management_1.1_spec-1.0.1.jar
- A Text Editor or an IDE 

Optional Requirements
- Ballerina IDE plugins (IntelliJ IDEA, VSCode, Atom)

## <a name="developing-service"></a> Developing the service

### <a name="before-begin"></a> Before you begin
##### Understand the package structure
Ballerina is a complete programming language that can have any custom project structure as you wish. Although language allows you to have any package structure, we'll stick with the following package structure for this project.

```
messaging-with-jms-queues
├── bookstore
│   ├── jmsConsumer
│   │   └── order_delivery_system.bal
│   ├── jmsProducer
│   │   ├── bookstore_service.bal
│   │   ├── bookstore_service_test.bal
│   │   └── jmsUtil
│   │       ├── jms_producer_utils.bal
│   │       └── jms_producer_utils_test.bal
│   └── resources
│       └── jndi.properties
└── README.md

```

The `jmsConsumer` package contains file that handles the logic of message consumption from the JMS queue.

The `jmsProducer` package contains files that handle the JMS message producing logic and test files. 

The `resources` package contains `jndi.properties` file, which manages connections for JMS.

##### Understand the `jndi.properties` file

```properties
# Register the connection factory
# connectionfactory.[jndiname] = [ConnectionURL]
connectionfactory.QueueConnectionFactory = tcp://localhost:61616

# Register the queue in JNDI
# queue.[jndiName] = [physicalName]
queue.OrderQueue = OrderQueue
# Queue used for testing
queue.TestQueue = TestQueue

```

The above segment contains the `jndi.properties` file used in this sample. This file contains the details to manage connections for JMS. For this point-to-point example, we require to register the `connectionfactory.[jndiname]` and 
`queue.[jndiName]`. 

### <a name="Implementation"></a> Implementation

Let's get started with the implementation of `jms_producer_utils.bal`file, which contains the JMS configurations required by the message producer. Refer the code attached below. Inline comments are added for better understanding.

##### jms_producer_utils.bal
```ballerina
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
    // 'Apache ActiveMQ' has been used as the message broker in this example
    properties = {initialContextFactory:"org.apache.activemq.jndi.ActiveMQInitialContextFactory",
                     providerUrl:"tcp://localhost:61616",
                     connectionFactoryName:"QueueConnectionFactory",
                     connectionFactoryType:"queue"};
    return;
}

```

In the above implementation, private function `getConnectorConfig()` is used to get the JMS client connector configurations.
This function returns `jms:ClientProperties` required by the JMS client. Fields `initialContextFactory`, `providerUrl`, `connectionFactoryName` and `connectionFactoryType` determine the properties needed for the JMS client. Instead of `providerUrl` you could also provide `configFilePath`, which will be the file path of your `jndi.properties` file.
Change the `providerUrl` and the `initialContextFactory` according to the JMS provider you use. 

Function `addToJmsQueue()` takes a message and a queue name as parameters and tries to add the message to the queue specified. It gets the JMS client configuration details by calling the method `getConnectorConfig()`. Function `addToJmsQueue()` returns an error if it fails to obtain the JMS client.


Let's next focus on the implementation of `order_delivery_system.bal` file, which consists of the message consuming logic.
Consider the below code. Inline comments are added for better understanding.

##### order_delivery_system.bal
```ballerina
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

```

`orderDeliverySystem` is a JMS service, which acts as the JMS message receiver. We require to provide the JMS configuration details for this JMS service. `@jms:configuration {}` block contains these configurations. Except `destination` other fields are similar to what we had in the `getConnectorConfig()`. Field `destination` is used to specify the JMS queue name from which the consumer needs to consume messages. This should be the same name you specified for `[physicalName]` in line 
`queue.[jndiName] = [physicalName]` in the `jndi.properties` file.

Resource `onMessage` will be triggered whenever the queue specified as the destination gets populated. 


Finally, let's focus on the implementation of `bookstore_service.bal` file, which contains the service logic for the online bookstore service use-case we considered. This service has two resourses namely `getAvailableBooks` and `placeOrder`.
Resource `getAvailableBooks` can be consumed by a user to get a list of all the available books through a GET request. User will get a JSON response with the names of all the available books.
Resource `placeOrder` can be consumed by a user to place an order for a book delivery. User needs to send a POST request with an appropriate JSON payload to the service. Service will then check for the availability of the book and send a JSON response to the user. If the book is available then the order will be added to the JMS queue `OrderQueue`, which will be consumed by the order delivery system later. Skeleton of the `bookstore_service.bal` is attached below.

##### bookstore_service.bal
```ballerina

// Struct to construct an order
struct order {
   // Implementation
}

// Book store service that allows users to order books online for delivery
@http:configuration {basePath:"/bookStore"}
service<http> bookstoreService {
    // Resource that allows users to place an order for a book
    @http:resourceConfig {methods:["POST"]}
    resource placeOrder (http:Connection httpConnection, http:InRequest request) {
     
        // Try getting the JSON payload from the user request
  
        // Check whether the requested book is available
      
        // If the requested book is available, try adding the order to the JMS queue 'OrderQueue'
        
        // Send an appropriate JSON response
    }

    // Resource that allows users to get a list of all the available books
    @http:resourceConfig {methods:["GET"]}
    resource getAvailableBooks (http:Connection httpConnection, http:InRequest request) {
      // Send a JSON response with all the available books  
    }
}

```

To see the complete implementation of the `bookstore_service.bal` file, refer to
[https://github.com/ballerina-guides/messaging-with-jms-queues/blob/master/bookstore/jmsProducer/bookstore_service.bal](https://github.com/ballerina-guides/messaging-with-jms-queues/blob/master/bookstore/jmsProducer/bookstore_service.bal).


## <a name="testing"></a> Testing 

### <a name="try-it"></a> Try it out

1. Start `Apache ActiveMQ` server by entering the following command in a terminal.

   ```bash
   <ActiveMQ_BIN_DIRECTORY>$ ./activemq start
   ```

2. Run both the HTTP service `bookstoreService`, which acts as the JMS producer, and the JMS service `orderDeliverySystem`, which acts as the JMS consumer, by entering the following commands in sperate terminals.

    ```bash
    <SAMPLE_ROOT_DIRECTORY>$ ballerina run bookstore/jmsProducer/
   ```

    ```bash
    <SAMPLE_ROOT_DIRECTORY>$ ballerina run bookstore/jmsConsumer/
    ```
   
3. Invoke the `bookstoreService` by sending a GET request to check all the available books.

    ```bash
    curl -v -X GET localhost:9090/bookstore/getAvailableBooks
    ```

     The bookstoreService sends a response similar to the following.
     ```
    < HTTP/1.1 200 OK
    ["Tom Jones","The Rainbow","Lolita","Atonement","Hamlet"]
     ```
   
4. Place an order using the following command.

    ```bash
    curl -v -X POST -d \
    '{"Name":"Bob", "Address":"20, Palm Grove, Colombo, Sri Lanka", "ContactNumber":"+94777123456", "BookName":"The Rainbow"}' \
     "http://localhost:9090/bookstore/placeOrder" -H "Content-Type:application/json"
    ```

    The bookstoreService sends a response similar to the following.
    ```
     < HTTP/1.1 200 OK
    {"Message":"Your order is successfully placed. Ordered book will be delivered soon"}
    ```

    Sample Log Messages:
    ```bash
    2018-02-23 21:22:21,268 INFO  [bookstore.jmsProducer] - New order added to the JMS Queue; CustomerName: 'Bob', OrderedBook: 'The Rainbow'; 

    2018-02-23 21:22:24,181 INFO  [bookstore.jmsConsumer] - New order received from the JMS Queue 
    2018-02-23 21:22:24,184 INFO  [bookstore.jmsConsumer] - Order Details: {"customerName":"Bob","address":"20, Palm Grove, Colombo, Sri Lanka","contactNumber":"+94777123456","orderedBookName":"The Rainbow"} 
    ```

### <a name="unit-testing"></a> Writing unit tests 

In Ballerina, the unit test cases are in the same package and the naming convention should be as follows.
* Test files should contain _test.bal suffix.
* Test functions should contain test prefix.
  * e.g., testBookstoreService()

This guide contains unit test cases for each method implemented in the `jms_producer_utils.bal` and `bookstore_service.bal` files.
Test files are in the same packages in which the above files are located.

To run the unit tests, go to the sample root directory and run the following command.
   ```bash
   <SAMPLE_ROOT_DIRECTORY>$ ballerina test bookstore/jmsProducer/
   ```

To check the implementations of these test files, please go to [https://github.com/ballerina-guides/messaging-with-jms-queues/blob/master/bookstore/jmsProducer/](https://github.com/ballerina-guides/messaging-with-jms-queues/blob/master/bookstore/jmsProducer/) and refer to the respective folders of the `jms_producer_utils.bal` and `bookstore_service.bal` files. 

## <a name="deploying-the-scenario"></a> Deployment

Once you are done with the development, you can deploy the service using any of the methods that we listed below. 

### <a name="deploying-on-locally"></a> Deploying locally
You can deploy the RESTful service that you developed above in your local environment. You can create the Ballerina executable archive (.balx) first and then run it in your local environment as follows.

Building 
   ```bash
    <SAMPLE_ROOT_DIRECTORY>$ ballerina build bookstore/jmsConsumer/

    <SAMPLE_ROOT_DIRECTORY>$ ballerina build bookstore/jmsProducer/

   ```

Running
   ```bash
    <SAMPLE_ROOT_DIRECTORY>$ ballerina run jmsConsumer.balx 

    <SAMPLE_ROOT_DIRECTORY>$ ballerina run jmsProducer.balx 

   ```

### <a name="deploying-on-docker"></a> Deploying on Docker
(Work in progress) 

### <a name="deploying-on-k8s"></a> Deploying on Kubernetes
(Work in progress) 


## <a name="observability"></a> Observability 

### <a name="logging"></a> Logging
(Work in progress) 

### <a name="metrics"></a> Metrics
(Work in progress) 


### <a name="tracing"></a> Tracing 
(Work in progress) 


## P.S.

Due to an [issue](https://github.com/wso2-ballerina/package-jms/issues/49), Ballerina JMS Connector does not work with Ballerina versions later 0.96.0 (exclusive). Therefore, when trying this guide use Ballerina version 0.96.0.
