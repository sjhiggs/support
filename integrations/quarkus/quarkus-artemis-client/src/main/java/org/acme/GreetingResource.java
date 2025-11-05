package org.acme;

import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.MediaType;



@Path("/hello")
public class GreetingResource {

    private static final String QUEUE_NAME = "FOO";


    @Inject
    MessageProducer producer;

    @POST
    @Produces(MediaType.TEXT_PLAIN)
    @Consumes(MediaType.TEXT_PLAIN)
    public Response postMessage(String message) {
        producer.sendMessage(message, QUEUE_NAME);
        return Response.status(Response.Status.ACCEPTED)
                       .entity("Message accepted and sent to " + QUEUE_NAME)
                       .build();
    }

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public String hello() {
        return "Hello from Quarkus REST";
    }
}
