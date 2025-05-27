import org.apache.camel.builder.RouteBuilder;

public class MyRoute extends RouteBuilder {

    @Override
    public void configure() throws Exception {
        from("netty-http:http://0.0.0.0:8080/route/health")
            .id("foo-route")
            .setBody()
                .simple("Hello Camel from ${routeId}")
             .log("${body}");
        from("netty-http:http://0.0.0.0:8080/route2/health")
            .id("foo-route-2")
            .setBody()
                .simple("Hello Camel from ${routeId}")
            .log("${body}");
    }
}
