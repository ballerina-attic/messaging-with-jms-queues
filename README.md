# Messaging with JMS

Java Message Service (JMS) is used to send messages between two or more clients. JMS supports two models: point-to-point model and publish/subscribe model. This guide is based on the point-to-point model where messages are routed to an individual consumer that maintains a queue of "incoming" messages. This messaging type is built on the concept of message queues, senders, and receivers. Each message is addressed to a specific queue, and the receiving clients extract messages from the queues established to hold their messages. In the point-to-point model, each message is guaranteed to be delivered and consumed by one consumer in an asynchronous manner.

> This guide walks you through the process of using Ballerina to send messages with JMS queues using a message broker.

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Developing the service](#developing-the-service)
- [Testing](#testing)
- [Deployment](#deployment)

## What you’ll build
To understand how you can use JMS queues for messaging, let's consider a real-world use case of an online bookstore service using which a user can order books for home delivery. Once an order is placed, the service will add it to a JMS queue named "OrderQueue" if the order is valid. Hence, this bookstore service acts as the JMS message producer. An order delivery system, which acts as the JMS message consumer polls the "OrderQueue" and gets the order details whenever the queue becomes populated. The below diagram illustrates this use case clearly.



![alt text](/images/messaging-with-jms-queues.svg)



In this example `Apache ActiveMQ` has been used as the JMS broker. Ballerina JMS Connector is used to connect Ballerina 
and JMS Message Broker. With this JMS Connector, Ballerina can act as both JMS Message Consumer and JMS Message 
Producer.

## Prerequisites
 
- JDK 1.8 or later
- [Ballerina Distribution](https://github.com/ballerina-lang/ballerina/blob/master/docs/quick-tour.md)
- [Ballerina JMS Connector](https://github.com/ballerinalang/connector-jms/releases)
  * After downloading the ZIP file, extract it and copy the containing .jar files into the <BALLERINA_HOME>/bre/lib folder.
- A JMS Broker (Example: [Apache ActiveMQ](http://activemq.apache.org/getting-started.html))
  * After downloading and installing, copy the JMS Broker Client .jar files into the <BALLERINA_HOME>/bre/lib folder.
    * For ActiveMQ 5.12.0 - activemq-client-5.12.0.jar, geronimo-j2ee-management_1.1_spec-1.0.1.jar
- A Text Editor or an IDE 

### Optional Requirements
- Ballerina IDE plugins ([IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina), [VSCode](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina), [Atom](https://atom.io/packages/language-ballerina))
- [Docker](https://docs.docker.com/engine/installation/)

## Developing the service

### Before you begin
#### Understand the package structure
Ballerina is a complete programming language that can have any custom project structure that you wish. Although the language allows you to have any package structure, use the following package structure for this project to follow this guide.

```
messaging-with-jms-queues
 └── src
     ├── bookstore_service
     │   ├── bookstore_service.bal
     │   └── tests
     │       └── bookstore_service_test.bal
     └── order_delivery_system
         └── order_delivery_system.bal
```

The `bookstore_service` package contains the file that handle the JMS message producing logic and unit tests. 

The `order_delivery_system` package contains the file that handles the logic of message consumption from the JMS queue.

### Implementation

Let's get started with the implementation of `order_delivery_system.bal`, which acts as the JMS message consumer. Refer to the code attached below. Inline comments added for better understanding.

##### order_delivery_system.bal
```ballerina
package order_delivery_system;

import ballerina/log;
import ballerina/jms;

// Initialize a JMS connection with the provider
// 'Apache ActiveMQ' has been used as the message broker
jms:Connection conn = new({
        initialContextFactory:"org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl:"tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection
jms:Session jmsSession = new(conn, {
        // Optional property. Defaults to AUTO_ACKNOWLEDGE
        acknowledgementMode:"AUTO_ACKNOWLEDGE"
    });

// Initialize a queue receiver using the created session
endpoint jms:QueueReceiver jmsConsumer {
    session:jmsSession,
    queueName:"OrderQueue"
};

// JMS service that consumes messages from the JMS queue
// Bind the created consumer to the listener service
service<jms:Consumer> orderDeliverySystem bind jmsConsumer {
// Triggered whenever an order is added to the 'OrderQueue'
    onMessage(endpoint consumer, jms:Message message) {
        log:printInfo("New order received from the JMS Queue");
        // Retrieve the string payload using native function
        string stringPayload = check message.getTextMessageContent();
        log:printInfo("Order Details: " + stringPayload);
    }
}
```

In Ballerina, you can directly set the JMS configurations in the endpoint definition.

In the above code, `orderDeliverySystem` is a JMS consumer service that handles the JMS message consuming logic. This service binds to a `jms:QueueReceiver` endpoint that defines the `jms:session` and the queue to which the messages are added.

`jms:Connection` is used to initialize a JMS connection with the provider details. `initialContextFactory` and `providerUrl` configurations change based on the JMS provider you use. 

`jms:Session` is used to initialize a session with the required connection properties.

Resource `onMessage` will be triggered whenever the queue specified as the destination gets populated. 


Let's next focus on the implementation of `bookstore_service.bal` , which contains the JMS message producing logic as well as the service logic for the online bookstore considered in this guide. This service has two resourses, namely `getBookList` and `placeOrder`.

Resource `getBookList` can be consumed by a user to get a list of all the available books through a GET request. The user receives a JSON response with the names of all the available books.

Resource `placeOrder` can be consumed by a user to place an order for a book delivery. The user needs to send a POST request with an appropriate JSON payload to the service. Service will then check for the availability of the book and send a JSON response to the user. If the book is available then the order will be added to the JMS queue `OrderQueue`, which will be consumed by the order delivery system later. Skeleton of the `bookstore_service.bal` is attached below.

##### bookstore_service.bal
```ballerina

package bookstore_service;

import ballerina/log;
import ballerina/http;
import ballerina/jms;

// Struct to construct an order
type bookOrder {
    string customerName;
    string address;
    string contactNumber;
    string orderedBookName;
};

// Global variable containing all the available books
json[] bookInventory = ["Tom Jones", "The Rainbow", "Lolita", "Atonement", "Hamlet"];

// Initialize a JMS connection with the provider
// 'providerUrl' and the 'initialContextFactory' vary according to the JMS provider you use
// 'Apache ActiveMQ' has been used as the message broker in this example
jms:Connection jmsConnection = new({
        initialContextFactory:"org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl:"tcp://localhost:61616"
});

// Initialize a JMS session on top of the created connection
jms:Session jmsSession = new(jmsConnection, {
        acknowledgementMode:"AUTO_ACKNOWLEDGE"
});

// Initialize a queue sender using the created session
endpoint jms:QueueSender jmsProducer {
    session:jmsSession,
    queueName:"OrderQueue"
};

// Service endpoint
endpoint http:Listener listener {
    port:9090
};

// Book store service, which allows users to order books online for delivery
@http:ServiceConfig {basePath:"/bookstore"}
service<http:Service> bookstoreService bind listener {
// Resource that allows users to place an order for a book
    @http:ResourceConfig {methods:["POST"], consumes:["application/json"],
        produces:["application/json"]}
    placeOrder(endpoint caller, http:Request request) {
     
        // Try parsing the JSON payload from the request
  
        // Check whether the requested book is available
      
        // If the requested book is available, add the order to the JMS queue 'OrderQueue'
        
        // Send an appropriate JSON response
    }

    // Resource that allows users to get a list of all the available books
    @http:ResourceConfig {methods:["GET"], produces:["application/json"]}
    getBookList(endpoint client, http:Request request) {
      // Send a JSON response with all the available books  
    }
}
```

Similar to the JMS consumer, here also we require to provide JMS configuration details when defining the `jms:QueueSender` endpoint. We need to provide the JMS session and the queue to which the producer pushes the messages.   

To see the complete implementation of the above, refer to the [bookstore_service.bal](https://github.com/ballerina-guides/messaging-with-jms-queues/blob/master/src/bookstore_service/bookstore_service.bal).

## Testing 

### Try it out

- Start `Apache ActiveMQ` server by entering the following command in a terminal.

```bash
   <ActiveMQ_BIN_DIRECTORY>$ ./activemq start
```

- Run both the HTTP service `bookstoreService`, which acts as the JMS producer, and the JMS service `orderDeliverySystem`, which acts as the JMS consumer, by entering the following commands in sperate terminals.

```bash
   <SAMPLE_ROOT_DIRECTORY>$ ballerina run bookstore/jmsProducer/
```

```bash
   <SAMPLE_ROOT_DIRECTORY>$ ballerina run bookstore/jmsConsumer/
```
   
- Invoke the `bookstoreService` by sending a GET request to check all the available books.

```bash
   curl -v -X GET localhost:9090/bookstore/getAvailableBooks
```

   The bookstoreService sends a response similar to the following.
```
   < HTTP/1.1 200 OK
   ["Tom Jones","The Rainbow","Lolita","Atonement","Hamlet"]
```
   
- Place an order using the following command.

```bash
   curl -v -X POST -d \
   '{"Name":"Bob", "Address":"20, Palm Grove, Colombo, Sri Lanka", "ContactNumber":"+94777123456",
     "BookName":"The Rainbow"}' \
   "http://localhost:9090/bookstore/placeOrder" -H "Content-Type:application/json"
```

  The bookstoreService sends a response similar to the following.
```
   < HTTP/1.1 200 OK
   {"Message":"Your order is successfully placed. Ordered book will be delivered soon"}
```

  Sample Log Messages:
```bash
    INFO  [bookstore.jmsProducer] - New order added to the JMS Queue; CustomerName: 'Bob',
    OrderedBook: 'The Rainbow'; 

    INFO  [bookstore.jmsConsumer] - New order received from the JMS Queue 
    INFO  [bookstore.jmsConsumer] - Order Details: {"customerName":"Bob","address":"20, Palm Grove,
    Colombo, Sri Lanka","contactNumber":"+94777123456","orderedBookName":"The Rainbow"} 
```

### Writing unit tests 

In Ballerina, the unit test cases are in the same package and the naming convention should be as follows.
* Test files should contain _test.bal suffix.
* Test functions should contain test prefix.
  * e.g., testBookstoreService()

This guide contains unit test cases for each method implemented in the `bookstore_service.bal` and `jms_producer_utils.bal` files.
Test files are in the same packages in which the above files are located.

To run the unit tests, go to the sample root directory and run the following command.
```bash
   <SAMPLE_ROOT_DIRECTORY>$ ballerina test bookstore/jmsProducer/
```

To check the implementations of these test files, refer to the [bookstore_service_test.bal](https://github.com/ballerina-guides/messaging-with-jms-queues/blob/master/bookstore/jmsProducer/bookstore_service_test.bal) and [jms_producer_utils_test.bal](https://github.com/ballerina-guides/messaging-with-jms-queues/blob/master/bookstore/jmsProducer/jmsUtil/jms_producer_utils_test.bal).

## Deployment

Once you are done with the development, you can deploy the service using any of the methods that we listed below. 

### Deploying locally
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
