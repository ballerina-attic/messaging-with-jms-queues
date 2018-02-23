# Messaging with JMS

This is a use-case example explains the process of publishing and subscribing to queue messages using a JMS broker.
In this example WSO2 MB server has been used as the JMS broker. Ballerina JMS Connector is used to connect Ballerina 
with JMS Message Broker. With the JMS Connector, Ballerina can act as both JMS Message Consumer and JMS Message 
Producer.

This example consists of a simple cab booking service using which a user can book a vehicle for his/her journey by 
specifying source, destination, preferred vehicle type and phone number. Once a vehicle of preferred type is available, 
server will add the phone number of that user to a JMS queue. A JMS service, which acts as a JMS-consumer will then 
consume the message from the queue and send an SMS to user's phone number stating that a vehicle is available for 
his/her journey. This process is done asynchronously with the help of JMS. That is to say, a user does not want to 
wait in the http connection until a vehicle becomes available. `jms-producer.bal` contains the cab service logic as 
well as jms message producing logic. `jms-consumer.bal` contains jms message consuming logic. 
`cab-booking-service-client.bal` is used to initiate a http request to the cab booking service.

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
