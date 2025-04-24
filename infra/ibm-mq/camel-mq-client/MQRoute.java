//DEPS com.ibm.mq:com.ibm.mq.jakarta.client:9.4.2.0
import com.ibm.mq.jakarta.jms.MQQueueConnectionFactory;
import com.ibm.msg.client.jakarta.wmq.WMQConstants;
import org.apache.camel.CamelContext;
import org.apache.camel.ProducerTemplate;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.component.jms.JmsComponent;
import org.apache.camel.impl.DefaultCamelContext;


import org.apache.camel.BindToRegistry;


public class MQRoute extends RouteBuilder {

    static String mqHost = "127.0.0.1";

    static int mqPort = 1414;
    static String mqQueueManager = "QM1";
    static String mqChannel = "DEV.APP.SVRCONN";
    static String mqQueue = "DEV.QUEUE.1";
    static String user = "app";
    static String password = "foobar";

    @Override
    public void configure() {
        // MQQueueConnectionFactory mqFactory = createWMQConnectionFactory(mqHost);
        // getContext().getRegistry().bind("mqConnectionFactory", mqFactory);
        
        from("timer:tick")
            .setBody()
              .simple("Hello Camel K! #${exchangeProperty.CamelTimerCounter}")
            .to("jms:queue:" + mqQueue + "?connectionFactory=#mqConnectionFactory");

        from("jms:queue:" + mqQueue + "?connectionFactory=#mqConnectionFactory")
            .to("log:info");
    }

    // @BindToRegistry(lazy=true)
    // private MQQueueConnectionFactory createWMQConnectionFactory(String mqHost) {
    @BindToRegistry(lazy=true, value="mqConnectionFactory")
    public MQQueueConnectionFactory createWMQConnectionFactory() {
        
        MQQueueConnectionFactory mqQueueConnectionFactory = new MQQueueConnectionFactory();
        try {
            mqQueueConnectionFactory.setHostName(mqHost);
            mqQueueConnectionFactory.setChannel(mqChannel);
            mqQueueConnectionFactory.setPort(mqPort);
            mqQueueConnectionFactory.setQueueManager(mqQueueManager);
            mqQueueConnectionFactory.setTransportType(WMQConstants.WMQ_CM_CLIENT);
            mqQueueConnectionFactory.setStringProperty(WMQConstants.USERID, user);
            mqQueueConnectionFactory.setStringProperty(WMQConstants.PASSWORD, password);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return mqQueueConnectionFactory;
    }
}
