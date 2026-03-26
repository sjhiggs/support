package com.test;

import org.apache.activemq.artemis.jms.client.ActiveMQConnectionFactory;
import javax.jms.*;

public class BatchConsumer {
    public static void main(String[] args) {

        String url = "tcp://localhost:61616";
        
        System.out.println("Initializing consumer connection to: " + url);

        try (ActiveMQConnectionFactory cf = new ActiveMQConnectionFactory(url);
             Connection connection = cf.createConnection()) {
            connection.start();
            try (Session session = connection.createSession(false, Session.CLIENT_ACKNOWLEDGE)) {
                
                Queue queue = session.createQueue("FOO");
                MessageConsumer consumer = session.createConsumer(queue);

                System.out.println("--- Starting Consumer ---");
                System.out.println("Listening on queue: FOO | Batch Size: 100");
                
                int count = 0;
                Message lastMessage = null;

                while (true) {
                    Message message = consumer.receive();
                    lastMessage = message;
                    count++;
                    
                    if (count % 100 == 0) {
                        message.acknowledge();
                        System.out.println("Consumed and ACKED batch of 100. Total consumed so far: " + count);
                        lastMessage = null;
                    }
                }
                
                
            } catch (JMSException e) {
                System.err.println("JMS Exception occurred: " + e.getMessage());
                e.printStackTrace();
            }
        } catch (Exception e) {
            System.err.println("Exception occurred: " + e.getMessage());
            e.printStackTrace();
        }
        
        System.exit(0);
    }
}
