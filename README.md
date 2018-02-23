# Messaging with JMS Queues

This guide walks you through the process of messaging with jms queues using a message broker in Ballerina language.
Java Message Service (JMS) is used for sending messages between two or more clients. JMS support two models, point-to-point model and publish/subscribe model. This example is based on poit-to-point model where messages are routed to an individual consumer which maintains a queue of "incoming" messages. This messaging type is built on the concept of message queues, senders, and receivers. Each message is addressed to a specific queue, and the receiving clients extract messages from the queues established to hold their messages. In point-to-point model each message is guaranteed to be delivered, and consumed by one consumer in an asynchronous manner.

## <a name="what-you-build"></a>  What you’ll Build
To understanding how you can use JMS queues for messaging, let's consider a real-world use case of an online bookstore service using which a user can order books for home delivery. Once an order is placed, the service will add it to a JMS queue named "OrderQueue" if the order is valid. Hence, this bookstore service acts as the JMS message producer. An order delivery system, which acts as the JMS message consumer polls the "OrderQueue" and gets the order details whenever the queue becomes populated. The below diagram illustrates this use case clearly.



![alt text](https://github.com/pranavan15/messaging-with-jms-queues/blob/master/images/JMSQueue.png)



In this example WSO2 MB server has been used as the JMS broker. Ballerina JMS Connector is used to connect Ballerina 
and JMS Message Broker. With this JMS Connector, Ballerina can act as both JMS Message Consumer and JMS Message 
Producer.


## How to Run
1) Go to https://ballerinalang.org and click Download.
2) Download the Ballerina Tools distribution and unzip it on your computer. Ballerina Tools includes the Ballerina 
runtime plus the visual editor (Composer) and other tools.
3) Add the `<BALLERINA_HOME>/bin` directory to your $PATH environment variable so that you can run the Ballerina 
commands from anywhere.
4) Go to https://ballerinalang.org/connectors and download JMS Connector.
5) Extract `ballerina-jms-connector-<version>.zip` and copy containing jars into `<BALLERINA_HOME>/bre/lib/`
6) Download a JMS Broker client and copy its jars into `<BALLERINA_HOME>/bre/lib/` (Here, WSO2 MB is used as the JMS 
Broker client)
7) Start the JMS broker server you downloaded.
8) After that, navigate to the `MessagingWithJMS` folder and run the followings in the same order: 
`$ ballerina run jms-producer.bal`, `$ ballerina run jms-consumer.bal`, `$ ballerina run cab-booking-service-client.bal`

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
