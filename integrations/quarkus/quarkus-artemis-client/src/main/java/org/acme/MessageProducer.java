package org.acme;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.jms.ConnectionFactory;
import jakarta.jms.JMSContext;
import jakarta.jms.JMSRuntimeException;
import jakarta.jms.Queue;

import io.smallrye.common.annotation.Identifier;

@ApplicationScoped
public class MessageProducer {

    @Inject
    @Identifier("pooledcf")
    ConnectionFactory connectionFactory;


    public void sendMessage(String messageContent, String queueName) {

        // Use the ConnectionFactory to create a JMSContext for sending the message.
        // The try-with-resources block ensures the JMSContext is closed.
        try (JMSContext context = connectionFactory.createContext()) {
            

            // 1. Create the Destination (Queue in this case)
            Queue destination = context.createQueue(queueName);
            
            // 2. Get the Producer
            // The producer is created from the JMSContext
            // and then sends the message to the specified destination.
            context.createProducer()
                   .send(destination, messageContent);
            
            System.out.println("✅ Sent message to " + queueName + ": " + messageContent);

        } catch (JMSRuntimeException ex) {
            System.err.println("❌ Error sending JMS message: " + ex.getMessage());
            // Handle the exception, e.g., logging or retrying
        }
    }
}