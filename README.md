[![Build Status](https://travis-ci.org/ballerina-guides/messaging-with-jms-queues.svg?branch=master)](https://travis-ci.org/ballerina-guides/messaging-with-jms-queues)

# Messaging with JMS

Java Message Service (JMS) is used to send messages between two or more clients. JMS supports two models: point-to-point model and publish/subscribe model. This guide is based on the point-to-point model where messages are routed to an individual consumer that maintains a queue of "incoming" messages. This messaging type is built on the concept of message queues, senders, and receivers. Each message is addressed to a specific queue, and the receiving clients extract messages from the queues established to hold their messages. In the point-to-point model, each message is guaranteed to be delivered and consumed by one consumer in an asynchronous manner.

> This guide walks you through the process of using Ballerina to send messages with JMS queues using a message broker.

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Testing](#testing)
- [Deployment](#deployment)

## What you’ll build
To understand how you can use JMS queues for messaging, let's consider a real-world use case of an online bookstore service using which a user can order books for home delivery. Once an order is placed, the service will add it to a JMS queue named "OrderQueue" if the order is valid. Hence, this bookstore service acts as the JMS message producer. An order delivery system, which acts as the JMS message consumer polls the "OrderQueue" and gets the order details whenever the queue becomes populated. The below diagram illustrates this use case.



![alt text](/images/messaging-with-jms-queues.svg)



In this example `Apache ActiveMQ` has been used as the JMS broker. Ballerina JMS Connector is used to connect Ballerina 
and JMS Message Broker. With this JMS Connector, Ballerina can act as both JMS Message Consumer and JMS Message 
Producer.

## Prerequisites
 
- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A JMS Broker (Example: [Apache ActiveMQ](http://activemq.apache.org/getting-started.html))
  * After installing the JMS broker, copy its .jar files into the `<BALLERINA_HOME>/bre/lib` folder
    * For ActiveMQ 5.15.4: Copy `activemq-client-5.15.4.jar`, `geronimo-j2ee-management_1.1_spec-1.0.1.jar` and `hawtbuf-1.11.jar`
- A Text Editor or an IDE 

### Optional Requirements
- Ballerina IDE plugins ([IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina), [VSCode](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina), [Atom](https://atom.io/packages/language-ballerina))
- [Docker](https://docs.docker.com/engine/installation/)
- [Kubernetes](https://kubernetes.io/docs/setup/)

## Implementation

> If you want to skip the basics, you can download the source from the Git repo and directly move to the "Testing" section by skipping the "Implementation" section.    

### Create the project structure

Ballerina is a complete programming language that supports custom project structures. Use the following package structure for this guide.
```
messaging-with-jms-queues
 └── guide
      ├── bookstore_service
      │    ├── bookstore_service.bal
      │    └── tests
      │         └── bookstore_service_test.bal
      └── order_delivery_system
           └── order_delivery_system.bal
```

- Create the above directories in your local machine and also create empty `.bal` files.

- Then open the terminal and navigate to `messaging-with-jms-queues/guide` and run Ballerina project initializing toolkit.
```bash
   $ ballerina init
```

### Developing the service

Let's get started with the implementation of the `order_delivery_system`, which acts as the JMS message consumer. 
Refer to the code attached below. Inline comments added for better understanding.

##### order_delivery_system.bal
```ballerina
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
jms:QueueReceiver jmsConsumer = new({
        session:jmsSession,
        queueName:"OrderQueue"
    });

// JMS service that consumes messages from the JMS queue
// Attach the service to the created JMS consumer
service orderDeliverySystem on jmsConsumer {
    // Triggered whenever an order is added to the 'OrderQueue'
    resource function onMessage(jms:QueueReceiverCaller consumer, jms:Message message) {
        log:printInfo("New order received from the JMS Queue");
        // Retrieve the string payload using native function
        var stringPayload = message.getTextMessageContent();
        if (stringPayload is string) {
            log:printInfo("Order Details: " + stringPayload);
        } else {
            log:printInfo("Error occurred while retrieving the order details");
        }
    }
}
```

In Ballerina, you can directly set the JMS configuration in the endpoint definition.

In the above code, `orderDeliverySystem` is a JMS consumer service that handles the JMS message consuming logic. This
 service is attached to a `jms:QueueReceiver` endpoint that defines the `jms:Session` and the queue to which the messages are added.

`jms:Connection` is used to initialize a JMS connection with the provider details. `initialContextFactory` and `providerUrl` configuration change based on the JMS provider you use. 

`jms:Session` is used to initialize a session with the required connection properties.

Resource `onMessage` will be triggered whenever the queue specified as the destination gets populated. 


Next let's focus on the implementation of the `bookstore_service` , which contains the JMS message producing logic 
as well as the service logic for the online bookstore considered in this guide. This service has two resources, namely `getBookList` and `placeOrder`.

Resource `getBookList` can be consumed by a user to get a list of all the available books through a GET request. The user receives a JSON response with the names of all the available books.

Resource `placeOrder` can be consumed by a user to place an order for a book delivery. The user needs to send a POST request with an appropriate JSON payload to the service. Service will then check for the availability of the book and send a JSON response to the user. If the book is available then the order will be added to the JMS queue `OrderQueue`, which will be consumed by the order delivery system later. Skeleton of the `bookstore_service.bal` is attached below.

##### bookstore_service.bal
```ballerina
import ballerina/log;
import ballerina/http;
import ballerina/jms;

// Type definition for a book order
type bookOrder record {
    string customerName?;
    string address?;
    string contactNumber?;
    string orderedBookName?;
};

// Global variable containing all the available books
json[] bookInventory = ["Tom Jones", "The Rainbow", "Lolita", "Atonement", "Hamlet"];

// Initialize a JMS connection with the provider
// 'providerUrl' and 'initialContextFactory' vary based on the JMS provider you use
// 'Apache ActiveMQ' has been used as the message broker in this example
jms:Connection jmsConnection = new({
        initialContextFactory: "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initialize a JMS session on top of the created connection
jms:Session jmsSession = new(jmsConnection, {
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

// Initialize a queue sender using the created session
jms:QueueSender jmsProducer = new({
        session: jmsSession,
        queueName: "OrderQueue"
    });

// Service endpoint
listener http:Listener httpListener = new(9090);

// Book store service, which allows users to order books online for delivery
@http:ServiceConfig { basePath: "/bookstore" }
service bookstoreService on httpListener {
    // Resource that allows users to place an order for a book
    @http:ResourceConfig {
        methods: ["POST"],
        consumes: ["application/json"],
        produces: ["application/json"]
    }
    resource function placeOrder(http:Caller caller, http:Request request) {
        // Try parsing the JSON payload from the request
  
        // Check whether the requested book is available
      
        // If the requested book is available, then add the order to the 'OrderQueue'
        
        // Send an appropriate JSON response
    }

    // Resource that allows users to get a list of all the available books
    @http:ResourceConfig {
        methods: ["GET"],
        produces: ["application/json"]
    }
    resource function getBookList(http:Caller caller, http:Request request) {
        // Send a JSON response with all the available books
    }
}
```

Similar to the JMS consumer, here also we require to provide JMS configuration details when defining the `jms:QueueSender` endpoint. We need to provide the JMS session and the queue to which the producer pushes the messages.   

To see the complete implementation of the above, refer [bookstore_service.bal](https://github.com/ballerina-guides/messaging-with-jms-queues/blob/master/guide/bookstore_service/bookstore_service.bal).

## Testing 

### Invoking the service

- First, start the `Apache ActiveMQ` server by entering the following command in a terminal from `<ActiveMQ_BIN_DIRECTORY>`.
```bash
   $ ./activemq start
```

- Navigate to `messaging-with-jms-queues/guide` and run the following commands in separate terminals to start both the JMS producer `bookstoreService` and  JMS consumer `orderDeliverySystem`.
```bash
   $ ballerina run bookstore_service
```

```bash
   $ ballerina run order_delivery_system
```
   
- Invoke the `bookstoreService` by sending a GET request to check the available books.

```bash
   $ curl -v -X GET localhost:9090/bookstore/getBookList
```

  The bookstoreService sends a response similar to the following.
```
   < HTTP/1.1 200 OK
   ["Tom Jones","The Rainbow","Lolita","Atonement","Hamlet"]
```
   
- Place an order using the following command.

```bash
   $ curl -v -X POST -d \
   '{"Name":"Bob", "Address":"20, Palm Grove, Colombo, Sri Lanka", 
   "ContactNumber":"+94777123456", "BookName":"The Rainbow"}' \
   "http://localhost:9090/bookstore/placeOrder" -H "Content-Type:application/json"
```

  The bookstoreService sends a response similar to the following.
```
   < HTTP/1.1 200 OK
   {"Message":"Your order is successfully placed. Ordered book will be delivered soon"} 
```

  Sample Log Messages:
```
    INFO  [bookstore_service] - New order added to the JMS Queue;
        CustomerName: 'Bob', OrderedBook: 'The Rainbow';

    INFO  [order_delivery_system] - New order received from the JMS Queue
    INFO  [order_delivery_system] - Order Details: {"customerName":"Bob", 
        "address":"20, Palm Grove, Colombo, Sri Lanka", "contactNumber":"+94777123456",
        "orderedBookName":"The Rainbow"} 
```

### Writing unit tests 

In Ballerina, the unit test cases should be in the same package inside a folder named `tests`.  When writing the test functions the below convention should be followed.
- Test functions should be annotated with `@test:Config`. See the below example.
```ballerina
   @test:Config
   function testResourcePlaceOrder() {
```
  
This guide contains unit test cases for each resource available in the 'bookstore_service' implemented above. 

To run the unit tests, navigate to `messaging-with-jms-queues/guide` and run the following command. 
```bash
   $ ballerina test
```

When running these unit tests, make sure that the JMS Broker is up and running.

To check the implementation of the test file, refer [bookstore_service_test.bal](https://github.com/ballerina-guides/messaging-with-jms-queues/blob/master/guide/bookstore_service/tests/bookstore_service_test.bal).

## Deployment

Once you are done with the development, you can deploy the services using any of the methods listed below. 

### Deploying locally

As the first step, you can build Ballerina executable archives (.balx) of the services that we developed above. Navigate to `messaging-with-jms-queues/guide` and run the following command.
```bash
   $ ballerina build
```

- Once the .balx files are created inside the target folder, you can run them using the following command. 
```bash
   $ ballerina run target/<Exec_Archive_File_Name>
```

- The successful execution of a service will show us something similar to the following output.
```
   Initiating service(s) in 'target/bookstore_service.balx'
   ballerina: started HTTP/WS endpoint 0.0.0.0:9090
```

### Deploying on Docker

You can run the service that we developed above as a Docker container.
As Ballerina platform includes [Ballerina_Docker_Extension](https://github.com/ballerinax/docker), which offers native support for running ballerina programs on containers,
you just need to add the corresponding Docker annotations to your service code.
Since this guide requires `ActiveMQ` as a prerequisite, you need a couple of more steps to configure it in a Docker container.   

First let's see how to configure `ActiveMQ` in a Docker container.

- Initially, you need to pull the `ActiveMQ` Docker image using the following command.
```bash
   $ docker pull webcenter/activemq
```

- Then launch the pulled image using the following command. This will start the `ActiveMQ` server in Docker with default configurations.
```bash
   $ docker run -d --name='activemq' -it --rm -P webcenter/activemq:latest
```

- Check whether the `ActiveMQ` container is up and running using the following command.
```bash
   $ docker ps
```

Now let's see how we can deploy the `bookstore_service` we developed above on Docker. We need to import `ballerinax/docker` and use the annotation `@docker:Config` as shown below to enable Docker image generation at build time. 

##### bookstore_service.bal
```ballerina
import ballerinax/docker;
// Other imports

// Type definition for a book order

json[] bookInventory = ["Tom Jones", "The Rainbow", "Lolita", "Atonement", "Hamlet"];

// 'jms:Connection' definition

// 'jms:Session' definition

// 'jms:QueueSender' endpoint definition

@docker:Config {
    registry:"ballerina.guides.io",
    name:"bookstore_service",
    tag:"v1.0"
}

@docker:CopyFiles {
    files:[{source:<path_to_JMS_broker_jars>,
            target:"/ballerina/runtime/bre/lib"}]
}

@docker:Expose{}
listener http:Listener httpListener = new(9090);

@http:ServiceConfig {basePath:"/bookstore"}
service bookstoreService on httpListener {
``` 

>NOTE: Replace "localhost" in the provider URL of the JMS connection definition, with the IP address of the running `ActiveMQ` server container in Docker.

- `@docker:Config` annotation is used to provide the basic Docker image configurations for the sample. `@docker:CopyFiles` is used to copy the JMS broker jar files into the ballerina bre/lib folder. You can provide multiple files as an array to field `files` of CopyFiles Docker annotation. `@docker:Expose {}` is used to expose the port. 

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. This will also create the corresponding Docker image using the Docker annotations that you have configured above. Navigate to `messaging-with-jms-queues/guide` and run the following command.  
  
```bash
   $ ballerina build bookstore_service --skiptests
  
   Run following command to start docker container: 
   docker run -d -p 9090:9090 ballerina.guides.io/bookstore_service:v1.0
```

- Once you successfully build the Docker image, you can run it with the `` docker run`` command that is shown in the previous step.  

```bash
   $ docker run -d -p 9090:9090 ballerina.guides.io/bookstore_service:v1.0
```

   Here we run the Docker image with flag`` -p <host_port>:<container_port>`` so that we use the host port 9090 and the container port 9090. Therefore you can access the service through the host port. 

- Verify docker container is running with the use of `` $ docker ps``. The status of the Docker container should be shown as 'Up'. 

- You can access the service using the same curl commands that we've used above.
```bash
   $ curl -v -X POST -d \
   '{"Name":"Bob", "Address":"20, Palm Grove, Colombo, Sri Lanka", 
   "ContactNumber":"+94777123456", "BookName":"The Rainbow"}' \
   "http://localhost:9090/bookstore/placeOrder" -H "Content-Type:application/json"
```


### Deploying on Kubernetes

- You can run the service that we developed above, on Kubernetes. The Ballerina language offers native support to run a Ballerina program on Kubernetes, with the use of Kubernetes annotations that you can include as part of your 
service code. Also, it will take care of the creation of the Docker images. So you don't need to explicitly create Docker images prior to deploying it on Kubernetes. Refer [Ballerina_Kubernetes_Extension](https://github.com/ballerinax/kubernetes) for more details and samples on Kubernetes deployment with Ballerina. You can also find details on using Minikube to deploy Ballerina programs. 

- Since this guide requires `ActiveMQ` as a prerequisite, you need an additional step to create a pod for `ActiveMQ` and use it with our sample.  

- Navigate to `messaging-with-jms-queues/resources` directory and run the below command to create the ActiveMQ pod by creating a deployment and service for ActiveMQ. You can find the deployment descriptor and service descriptor in the `./resources/kubernetes` folder.
```bash
   $ kubectl create -f ./kubernetes/
```

- Now let's see how we can deploy the `bookstore_service` on Kubernetes. We need to import `` ballerinax/kubernetes; `` and use `` @kubernetes `` annotations as shown below to enable kubernetes deployment.

##### bookstore_service.bal

```ballerina
import ballerinax/kubernetes;
// Other imports

// Type definition for a book order

json[] bookInventory = ["Tom Jones", "The Rainbow", "Lolita", "Atonement", "Hamlet"];

// 'jms:Connection' definition

// 'jms:Session' definition

// 'jms:QueueSender' endpoint definition

@kubernetes:Ingress {
  hostname:"ballerina.guides.io",
  name:"ballerina-guides-bookstore-service",
  path:"/"
}

@kubernetes:Service {
  serviceType:"NodePort",
  name:"ballerina-guides-bookstore-service"
}

@kubernetes:Deployment {
  image:"ballerina.guides.io/bookstore_service:v1.0",
  name:"ballerina-guides-bookstore-service",
  copyFiles:[{target:"/ballerina/runtime/bre/lib",
                  source:<path_to_JMS_broker_jars>}]
}

listener http:Listener httpListener = new(9090);

@http:ServiceConfig {basePath:"/bookstore"}
service bookstoreService on httpListener {
``` 

- Here we have used ``  @kubernetes:Deployment `` to specify the Docker image name which will be created as part of building this service. `copyFiles` field is used to copy required JMS broker jar files into the ballerina bre/lib folder. You can provide multiple files as an array to this field.
- We have also specified `` @kubernetes:Service `` so that it will create a Kubernetes service, which will expose the Ballerina service that is running on a Pod.  
- In addition we have used `` @kubernetes:Ingress ``, which is the external interface to access your service (with path `` /`` and host name ``ballerina.guides.io``)

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. This will also create the corresponding Docker image and the Kubernetes artifacts using the Kubernetes annotations that you have configured above.
  
```bash
   $ ballerina build bookstore_service
  
   Run following command to deploy kubernetes artifacts:  
   $ kubectl apply -f ./target/kubernetes/bookstore_service
```

- You can verify that the Docker image that we specified in `` @kubernetes:Deployment `` is created, by using `` docker images ``. 
- Also the Kubernetes artifacts related our service, will be generated under `` ./target/kubernetes/bookstore_service``. 
- Now you can create the Kubernetes deployment using:

```bash
   $ kubectl apply -f ./target/kubernetes/bookstore_service 
 
   deployment.extensions "ballerina-guides-bookstore-service" created
   ingress.extensions "ballerina-guides-bookstore-service" created
   service "ballerina-guides-bookstore-service" created
```

- You can verify Kubernetes deployment, service and ingress are running properly, by using following Kubernetes commands. 

```bash
   $ kubectl get service
   $ kubectl get deploy
   $ kubectl get pods
   $ kubectl get ingress
```

- If everything is successfully deployed, you can invoke the service either via Node port or ingress. 

Node Port:
```bash
   $ curl -v -X POST -d '{"Name":"Bob", "Address":"20, Palm Grove, Colombo, Sri Lanka", 
   "ContactNumber":"+94777123456", "BookName":"The Rainbow"}' \
   "http://localhost:<Node_Port>/bookstore/placeOrder" -H \
   "Content-Type:application/json"  
```

Ingress:

Add `/etc/hosts` entry to match hostname. 
``` 
   127.0.0.1 ballerina.guides.io
```

Access the service 
```bash
   $ curl -v -X POST -d '{"Name":"Bob", "Address":"20, Palm Grove, Colombo, Sri Lanka", 
   "ContactNumber":"+94777123456", "BookName":"The Rainbow"}' \
   "http://ballerina.guides.io/bookstore/placeOrder" -H "Content-Type:application/json" 
```
