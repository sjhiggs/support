from proton import Message, SSLDomain
from proton.handlers import MessagingHandler
from proton.reactor import Container

class mTLSClient(MessagingHandler):
    def __init__(self, server_url, address, cert_pem_path, truststore_pem_path):
        super(mTLSClient, self).__init__()
        self.server_url = server_url
        self.address = address
        self.cert_pem_path = cert_pem_path
        self.truststore_pem_path = truststore_pem_path
        self.sent = False

    def on_start(self, event):
        print("Configuring AMQP SSL/mTLS domain...")
        
        # 1. Create a client SSL domain
        ssl_domain = SSLDomain(SSLDomain.MODE_CLIENT)
        
        # 2. Tell Proton how to verify the Artemis server (Truststore)
        ssl_domain.set_trusted_ca_db(self.truststore_pem_path)
        ssl_domain.set_peer_authentication(SSLDomain.VERIFY_PEER)
        
        # 3. Provide the client cert and private key for mTLS
        # Since our previous OpenSSL command put both the cert and the unencrypted 
        # private key into the same myuser.pem file, we pass it for both arguments.
        ssl_domain.set_credentials(self.cert_pem_path, self.cert_pem_path, None)

        print(f"Connecting to {self.server_url}...")
        
        # 4. Create the connection with the SSL domain
        conn = event.container.connect(self.server_url, ssl_domain=ssl_domain)
        
        # 5. Create a sender and a receiver to the same queue
        event.container.create_receiver(conn, self.address)
        event.container.create_sender(conn, self.address)

    def on_sendable(self, event):
        # The connection is ready to accept messages
        if not self.sent:
            msg_body = "Hello Artemis! This message was sent via AMQP 1.0 and mTLS."
            msg = Message(body=msg_body)
            print(f"Sending message: '{msg.body}'")
            
            event.sender.send(msg)
            self.sent = True # Prevent sending in a loop

    def on_message(self, event):
        # A message has arrived
        print(f"[+] Successfully received message: {event.message.body}")
        
        # Close the connection and exit the app once the message is received
        event.connection.close()

def main():
    # File paths to your converted PEM files
    CLIENT_CERT_PEM = '/tmp/myapp-certs/myuser.pem'
    TRUSTSTORE_PEM = '/tmp/myapp-certs/truststore.pem'
    
    # Note: Use 'amqps://' to indicate an SSL connection
    SERVER_URL = "amqps://127.0.0.1:61617" 
    QUEUE_NAME = "TEST.QUEUE"
    
    # Start the Qpid Proton Reactor container
    try:
        Container(mTLSClient(SERVER_URL, QUEUE_NAME, CLIENT_CERT_PEM, TRUSTSTORE_PEM)).run()
    except KeyboardInterrupt:
        pass

if __name__ == "__main__":
    main()
