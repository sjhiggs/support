package com.redhat.support.examples;

import org.apache.camel.builder.RouteBuilder;

public class ExampleRoute extends RouteBuilder {

    @Override
    public void configure() throws Exception {
        
        from("timer:producer?period={{timer.period}}")
            .routeId("sendMessageToArtemis")
            .setBody(simple("hello world"))
            .to("jms:queue:{{test.queue}}");

        from("jms:queue:{{test.queue}}")
            .routeId("consumeMessageFromArtemis")
            .log("${body}");
    }
    

}
