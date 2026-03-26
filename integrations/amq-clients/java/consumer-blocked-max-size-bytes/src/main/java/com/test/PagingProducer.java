package com.test;

import org.apache.activemq.artemis.jms.client.ActiveMQConnectionFactory;
import javax.jms.*;

public class PagingProducer {
    public static void main(String[] args) {
        // clientFailureCheckPeriod and connectionTTL ensure a fast shutdown
        String url = "tcp://localhost:61616?minLargeMessageSize=10000000&clientFailureCheckPeriod=500&connectionTTL=1000";
        
        System.out.println("Initializing connection to: " + url);

        try (ActiveMQConnectionFactory cf = new ActiveMQConnectionFactory(url)) {
            
            try (Connection connection = cf.createConnection();
                 Session session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE)) {
                
                // 2. Define the destination
                Queue queue = session.createQueue("FOO");
                MessageProducer producer = session.createProducer(queue);

                // 3. Create a 1MB payload
                byte[] payload = new byte[1024 * 1024]; 
                BytesMessage message = session.createBytesMessage();
                message.writeBytes(payload);

                System.out.println("--- Starting Production ---");
                System.out.println("Target: FOO | Payload: 1MB | Count: 200");
                
                for (int i = 1; i <= 200; i++) {
                    producer.send(message);
                    if (i % 20 == 0) {
                        System.out.println("Sent " + i + " MB of data...");
                    }
                }

                System.out.println("--- Production Finished ---");
                System.out.println("Verify the 'data/paging/FOO' directory on your broker.");
                
            } catch (JMSException e) {
                System.err.println("JMS Exception occurred: " + e.getMessage());
                e.printStackTrace();
            }
        } catch (Exception e) {
            System.err.println("Exception occurred: " + e.getMessage());
            e.printStackTrace();
        }

        // Force instant exit to prevent any lingering daemon threads from holding the JVM open
        System.exit(0);
    }
}
