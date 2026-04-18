openssl genrsa -out apiserver.key 4096
openssl req -new -key apiserver.key -config master_ssl.cnf -subj "/CN=kube-apiserver" -out apiserver.csr
openssl x509 -req -in apiserver.csr -CA /etc/kubernetes/pki/k8s-ca.crt -CAkey /etc/kubernetes/pki/k8s-ca.key -CAcreateserial -days 3650 -extensions v3_req -extfile master_ssl.cnf -out apiserver.crt
