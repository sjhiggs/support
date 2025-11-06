package com.redhat.support.examples;

import org.apache.activemq.artemis.jms.client.ActiveMQConnection;
import org.apache.activemq.artemis.jms.client.ActiveMQConnectionFactory;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import io.quarkiverse.messaginghub.pooled.jms.PooledJmsWrapper;
import io.smallrye.common.annotation.Identifier;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;
import jakarta.enterprise.inject.Typed;
import jakarta.jms.ConnectionFactory;

@ApplicationScoped
public class MyFactory {


    @Produces
    @Typed({ ActiveMQConnectionFactory.class })
    @ApplicationScoped
    @Identifier("cf")
    ActiveMQConnectionFactory cf (
            @ConfigProperty(name = "artemis.cf.url") String url,
            @ConfigProperty(name = "artemis.cf.username") String username,
            @ConfigProperty(name = "artemis.cf.password") String password) {

        ActiveMQConnectionFactory cf = new ActiveMQConnectionFactory(url,username,password);
        cf.setReconnectAttempts(30);
        return cf;
    }



    @Produces
    @Typed({ ConnectionFactory.class })
    @ApplicationScoped
    @Identifier("pooledcf")
    public ConnectionFactory createPooledCF(
            PooledJmsWrapper wrapper, 
            @Identifier("cf") ActiveMQConnectionFactory connectionFactory) {
        return wrapper.wrapConnectionFactory(connectionFactory);
    }
}
