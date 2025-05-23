import org.apache.camel.builder.RouteBuilder;

public class MyRoute extends RouteBuilder {

    @Override
    public void configure() throws Exception {
        from("netty-http:http://0.0.0.0:8080")
            .setBody()
                .simple("Hello Camel from ${routeId}")
            .log("${body}");
    }
}
