package com.foo.acme;

import java.net.URISyntaxException;
import java.util.logging.Logger;

import org.apache.camel.Endpoint;
import org.apache.camel.Exchange;
import org.apache.camel.tracing.decorators.HttpSpanDecorator;
import org.apache.camel.util.URISupport;

public class MyCustomDecorator extends HttpSpanDecorator {

    Logger logger = Logger.getLogger(MyCustomDecorator.class.getName());

    @Override
    public String getOperationName(Exchange exchange, Endpoint endpoint) {
        Logger.getLogger(MyCustomDecorator.class.getName()).warning("TEST");
        try {
            return "TEST " + super.getOperationName(exchange, endpoint) + " "
                    + URISupport.normalizeUriAsURI(endpoint.getEndpointBaseUri()).getPath();
        } catch (URISyntaxException e) {
            throw new RuntimeException(e);
        }
    }

}
