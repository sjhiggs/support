package com.foo.acme;

import java.util.logging.Logger;

import jakarta.enterprise.context.ApplicationScoped;
import org.apache.camel.builder.RouteBuilder;

@ApplicationScoped
public class MyRoute extends RouteBuilder {

    Logger logger = Logger.getLogger(MyRoute.class.getName());

    public void configure() throws Exception {

        from("netty-http:http://localhost:8080/route/health")
            .id("foo-route")
            .to("direct:foo")
            .log("${body}");

        from("direct:foo")
            .setBody(simple("Hello Camel from ${routeId}"));

    }
}
