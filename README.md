# Messaging with JMS Queues

This guide walks you through the process of messaging with jms queues using a message broker in Ballerina language.
Java Message Service (JMS) is used for sending messages between two or more clients. JMS support two models, point-to-point model and publish/subscribe model. This example is based on poit-to-point model where messages are routed to an individual consumer which maintains a queue of "incoming" messages. This messaging type is built on the concept of message queues, senders, and receivers. Each message is addressed to a specific queue, and the receiving clients extract messages from the queues established to hold their messages. In point-to-point model each message is guaranteed to be delivered, and consumed by one consumer in an asynchronous manner.

## <a name="what-you-build"></a>  What you’ll Build
To understanding how you can use JMS queues for messaging, let's consider a real-world use case of an online bookstore service using which a user can order books for home delivery. Once an order is placed, the service will add it to a JMS queue named "OrderQueue" if the order is valid. Hence, this bookstore service acts as the JMS message producer. An order delivery system, which acts as the JMS message consumer polls the "OrderQueue" and gets the order details whenever the queue becomes populated. The below diagram illustrates this use case clearly.



![alt text](https://github.com/pranavan15/messaging-with-jms-queues/blob/master/images/JMSQueue.png)



In this example WSO2 EI Message Broker has been used as the JMS broker. Ballerina JMS Connector is used to connect Ballerina 
and JMS Message Broker. With this JMS Connector, Ballerina can act as both JMS Message Consumer and JMS Message 
Producer.

## <a name="pre-req"></a> Prerequisites
 
- JDK 1.8 or later
- Ballerina Distribution (Install Instructions:  https://ballerinalang.org/docs/quick-tour/quick-tour/#install-ballerina)
- Ballerina JMS Connector (Download: https://github.com/ballerinalang/connector-jms/releases)
  * After downloading the zip file, extract it and copy the containing jars into <BALLERINA_HOME>/bre/lib folder
- A JMS Broker (Example: WSO2 EI Message Broker - Refer: https://docs.wso2.com/display/EI611/Message+Brokering)
  * After downloading and installing, copy the JMS Broker Client jars into <BALLERINA_HOME>/bre/lib folder
- A Text Editor or an IDE 

Optional Requirements
- Docker (Follow instructions in https://docs.docker.com/engine/installation/)
- Ballerina IDE plugins. ( IntelliJ IDEA, VSCode, Atom)
- Testerina (Refer: https://github.com/ballerinalang/testerina)
- Container-support (Refer: https://github.com/ballerinalang/container-support)
- Docerina (Refer: https://github.com/ballerinalang/docerina)

## <a name="developing-service"></a> Developing the Service

### <a name="before-begin"></a> Before You Begin
##### Understand the Package Structure
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

##### Understand the `jndi.properties` File

```properties
# Register the connection factory
# connectionfactory.[jndiname] = [ConnectionURL]
connectionfactory.QueueConnectionFactory = amqp://admin:admin@clientID/carbon?brokerlist='tcp://localhost:5675'

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
    // 'WSO2 MB server' from product 'EI' has been used as the message broker in this example
    properties = {initialContextFactory:"wso2mbInitialContextFactory",
                     providerUrl:"amqp://admin:admin@carbon/carbon?brokerlist='tcp://localhost:5675'",
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
// 'WSO2 MB server' from product 'EI' has been used as the message broker
@jms:configuration {
    initialContextFactory:"wso2mbInitialContextFactory",
    providerUrl:
    "amqp://admin:admin@carbon/carbon?brokerlist='tcp://localhost:5675'",
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

// Book store service, which allows users to order books online for delivery
@http:configuration {basePath:"/bookStore"}
service<http> bookstoreService {
    // Resource that allows users to place an order for a book
    @http:resourceConfig {methods:["POST"]}
    resource placeOrder (http:Connection httpConnection, http:InRequest request) {
     
        // Try getting the JSON payload from the user request
  
        // Check whether the requested book available
      
        // If requested book is available then try adding the order to the JMS queue 'OrderQueue'
        
        // Send appropriate JSON response
    }

    // Resource that allows users to get a list of all the available books
    @http:resourceConfig {methods:["GET"]}
    resource getAvailableBooks (http:Connection httpConnection, http:InRequest request) {
      // Send a JSON response with all the available books  
    }
}

```

Refer https://github.com/ballerina-guides/messaging-with-jms-queues/blob/master/bookstore/jmsProducer/bookstore_service.bal file to see the complete implementation of `bookstore_service.bal`.



#### How to interact with this web service
* POST `localhost:9090/cabBookingService/placeOrder` with appropriate payload

Example payload: `{Source:"Colombo", Destination: "Kandy", Vehicle: "Car", PhoneNumber: "0777123123"}`

Response for the above request will be in Application/Json format.

To check the above service, either you can send the above mentioned POST request or simply run the 
cab booking service client, which will initiate the POST request to the service and log the response from the server .

#### Sample Response 
```
[cab-booking-service-client.bal] 2018-01-22 10:52:16,854 INFO  [] - {"message":"Order successful. You will get an SMS when a vehicle is available"} 
[jms-producer.bal] 2018-01-22 10:52:32,469 INFO  [] - Phone number added to the message queue 
[jms-consumer.bal] 2018-01-22 10:52:34,981 INFO  [] - Message received from jms-producer 
[jms-consumer.bal] 2018-01-22 10:52:34,984 INFO  [] - Successfully sent SMS to: 0777123123 
[jms-consumer.bal] 2018-01-22 10:52:34,985 INFO  [] - SMS Content: Hello user! Vehicle available for your journey
```

## <a name="testing"></a> Testing 

### <a name="unit-testing"></a> Writing Unit Tests 

In ballerina, the unit test cases should be in the same package and the naming convention should be as follows,
* Test files should contain _test.bal suffix.
* Test functions should contain test prefix.
  * e.g.: testOrderService()

This guide contains unit test cases in the respective folders. The two test cases are written to test the `orderServices` and the `inventoryStores` service.
To run the unit tests, go to the sample root directory and run the following command
```bash
$ ballerina test orderServices/
```

```bash
$ ballerina test inventoryServices/
```

## <a name="deploying-the-scenario"></a> Deployment

Once you are done with the development, you can deploy the service using any of the methods that we listed below. 

### <a name="deploying-on-locally"></a> Deploying Locally
You can deploy the RESTful service that you developed above, in your local environment. You can use the Ballerina executable archive (.balx) archive that we created above and run it in your local environment as follows. 

```
ballerina run orderServices.balx 
```


```
ballerina run inventoryServices.balx 
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
