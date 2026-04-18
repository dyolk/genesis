# 生成 k8s 根证书
openssl genrsa -out k8s-ca.key 4096

openssl req -x509 -new -nodes -key k8s-ca.key -subj "/C=CN/ST=Suzhou/L=Jiangsu/O=Dyolk/CN=k8s-ca" -days 3650 -out k8s-ca.crt

# 生成 etcd-server etcd-client 证书

# etcd-server
openssl genrsa -out ectd-server.key 4096
openssl req -new -key etcd-server.key -config etcd_ssl.cnf -subj "/CN=etcd-server" -out etcd-server.csr
openssl req -x509 -in etcd-client.csr -CA /etc/kubernetes/pki/k8s-ca.crt -CAkey /etc/kubernetes/pki/k8s-ca.key -CAcreateserial -days 3650 -extensions v3_req -extfile etcd_ssl.cnf -out etcd-server.crt

# etcd-client
openssl genrsa -out ectd-client.key 4096
openssl req -new -key etcd-client.key -config etcd_ssl.cnf -subj "/CN=etcd-server" -out etcd-client.csr
openssl req -x509 -in etcd-client.csr -CA /etc/kubernetes/pki/k8s-ca.crt -CAkey /etc/kubernetes/pki/k8s-ca.key -CAcreateserial -days 3650 -extensions v3_req -extfile etcd_ssl.cnf -out etcd-client.crt
