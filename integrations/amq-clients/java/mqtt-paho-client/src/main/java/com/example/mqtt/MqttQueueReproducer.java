package com.example.mqtt;

import org.eclipse.paho.mqttv5.client.MqttClient;
import org.eclipse.paho.mqttv5.client.MqttConnectionOptions;
import org.eclipse.paho.mqttv5.client.persist.MemoryPersistence;
import org.eclipse.paho.mqttv5.common.MqttException;
import org.eclipse.paho.mqttv5.common.MqttSubscription;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.UUID;

/**
 * MQTT v5 client reproducer for queue cleanup behavior on AMQ 7.x.
 *
 * Tests scenario where client disconnects WITHOUT calling unsubscribe.
 */
public class MqttQueueReproducer {
    private static final Logger log = LoggerFactory.getLogger(MqttQueueReproducer.class);
    private static final String CLIENT_ID_PREFIX = "mqtt-client-";

    private final String brokerUrl;
    private final String topic;
    private final int qos;

    public MqttQueueReproducer(String brokerUrl, String topic, int qos) {
        this.brokerUrl = brokerUrl;
        this.topic = topic;
        this.qos = qos;
    }

    /**
     * Creates client, subscribes to topic, then disconnects WITHOUT unsubscribing.
     */
    public void run(int clientCount, int delaySeconds) throws MqttException, InterruptedException {
        log.info("=== Creating {} client(s) WITHOUT calling unsubscribe ===", clientCount);

        for (int i = 0; i < clientCount; i++) {
            String clientId = CLIENT_ID_PREFIX + UUID.randomUUID();

            MqttConnectionOptions options = createConnectionOptions();
            MqttClient client = new MqttClient(brokerUrl, clientId, new MemoryPersistence());

            log.info("Connecting with clientId: {}", clientId);
            client.connect(options);

            MqttSubscription subscription = new MqttSubscription(topic, qos);
            client.subscribe(new MqttSubscription[]{subscription});
            log.info("Subscribed to {} with QoS {}", topic, qos);

            log.info(">>> CHECK BROKER NOW - Queue/Address should exist for clientId: {}", clientId);
            log.info(">>> Waiting {} seconds before disconnect...", delaySeconds);
            Thread.sleep(delaySeconds * 1000L);

            log.warn("Disconnecting WITHOUT calling unsubscribe()");
            client.disconnect();
            client.close();
            log.info("Client disconnected and closed");

            if (i < clientCount - 1) {
                Thread.sleep(100);
            }
        }
    }

    /**
     * Creates MQTT connection options.
     * Default configuration uses ephemeral sessions.
     */
    private MqttConnectionOptions createConnectionOptions() {
        MqttConnectionOptions options = new MqttConnectionOptions();

        options.setAutomaticReconnect(true);
        options.setConnectionTimeout(30);
        options.setKeepAliveInterval(30);
        options.setSessionExpiryInterval(0L);  // Session ends with connection
        options.setCleanStart(true);           // Start fresh

        return options;
    }

    public static void main(String[] args) {
        String brokerUrl = System.getProperty("broker.url", "tcp://localhost:1883");
        String topic = System.getProperty("topic", "test/queue/#");
        int qos = Integer.parseInt(System.getProperty("qos", "1"));
        int clientCount = Integer.parseInt(System.getProperty("client.count", "1"));
        int delaySeconds = Integer.parseInt(System.getProperty("delay.seconds", "30"));

        log.info("MQTT Queue Cleanup Reproducer");
        log.info("Broker: {}", brokerUrl);
        log.info("Topic: {}", topic);
        log.info("QoS: {}", qos);
        log.info("Client Count: {}", clientCount);
        log.info("Delay: {} seconds", delaySeconds);
        log.info("");

        MqttQueueReproducer reproducer = new MqttQueueReproducer(brokerUrl, topic, qos);

        try {
            reproducer.run(clientCount, delaySeconds);

            log.info("");
            log.info("=== COMPLETE ===");
            log.info("Check AMQ broker console to verify queue/address cleanup");

        } catch (Exception e) {
            log.error("Error running reproducer", e);
            System.exit(1);
        }
    }
}
