openssl genrsa -out client.key 4096
openssl req -new -key client.key -subj "/CN=admin/O=system:masters" -out client.csr
openssl x509 -req -in client.csr -CA /etc/kubernetes/pki/k8s-ca.crt -CAkey /etc/kubernetes/pki/k8s-ca.key -CAcreateserial -out client.crt -days 3650
