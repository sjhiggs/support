package org.acme;

import io.quarkiverse.messaginghub.pooled.jms.PooledJmsWrapper;
import io.smallrye.common.annotation.Identifier;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;
import jakarta.inject.Inject;
import jakarta.jms.ConnectionFactory;

@ApplicationScoped
public class MyFactory {
    
    @Inject
    ConnectionFactory connectionFactory;

    @Produces
    @Identifier("pooledcf")
    public ConnectionFactory createPooledCF(PooledJmsWrapper wrapper) {
        return wrapper.wrapConnectionFactory(connectionFactory);
    }
}
