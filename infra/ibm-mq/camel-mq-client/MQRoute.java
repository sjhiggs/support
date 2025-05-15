//DEPS org.apache.camel:camel-bom:null@pom
//DEPS org.apache.camel:camel-main
//DEPS org.apache.camel:camel-jms
//DEPS org.apache.camel:camel-log
//DEPS org.apache.camel:camel-observability-services
//DEPS org.apache.camel:camel-timer
//DEPS com.ibm.mq:com.ibm.mq.jakarta.client:9.4.2.0

import com.ibm.mq.jakarta.jms.MQQueueConnectionFactory;
import com.ibm.msg.client.jakarta.wmq.WMQConstants;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.PropertyInject;
import org.apache.camel.BindToRegistry;


public class MQRoute extends RouteBuilder {

    @PropertyInject("mq.host")
    public String mqHost;

    @PropertyInject("mq.user")
    public String mqUser;

    @PropertyInject("mq.password")
    public String mqPassword;

    @PropertyInject ("mq.ssl-cipher-suite")
    public String sslCipherSuite;

    static int mqPort = 1414;
    static String mqQueueManager = "QM1";
    static String mqChannel = "DEV.APP.SVRCONN";
    static String mqQueue = "DEV.QUEUE.1";

    @Override
    public void configure() {

        System.setProperty("com.ibm.mq.cfg.useIBMCipherMappings", "false");
        
        from("timer:tick")
            .setBody()
              .simple("Hello Camel K! #${exchangeProperty.CamelTimerCounter}")
            .to("jms:queue:" + mqQueue + "?connectionFactory=#mqConnectionFactory");

        from("jms:queue:" + mqQueue + "?connectionFactory=#mqConnectionFactory")
            .to("log:info");
    }

    @BindToRegistry(lazy=true, value="mqConnectionFactory")
    public MQQueueConnectionFactory createWMQConnectionFactory() {
        
        MQQueueConnectionFactory mqQueueConnectionFactory = new MQQueueConnectionFactory();
        try {
            mqQueueConnectionFactory.setHostName(mqHost);
            mqQueueConnectionFactory.setChannel(mqChannel);
            mqQueueConnectionFactory.setPort(mqPort);
            mqQueueConnectionFactory.setQueueManager(mqQueueManager);
            mqQueueConnectionFactory.setTransportType(WMQConstants.WMQ_CM_CLIENT);

            if(mqUser != null && mqUser.length() > 0) {
                mqQueueConnectionFactory.setStringProperty(WMQConstants.USERID, mqUser);
                mqQueueConnectionFactory.setStringProperty(WMQConstants.PASSWORD, mqPassword);
            }

            if(sslCipherSuite != null && sslCipherSuite.length() > 0) {
                mqQueueConnectionFactory.setSSLCipherSuite(sslCipherSuite);
            }


        } catch (Exception e) {
            e.printStackTrace();
        }
        return mqQueueConnectionFactory;
    }
}
