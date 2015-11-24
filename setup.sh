# Create the etcd host machine
docker-machine create \
    -d vmwarefusion \
    etcd

# set the HOSTIP enviornment variable to etcd host
export HOSTIP=$(docker-machine ip etcd)

# Bootstrap the etcd container on the host
docker run -d -p 4001:4001 -p 2380:2380 -p 2379:2379 --name etcd quay.io/coreos/etcd:v2.0.3 \
 -name etcd \
 -advertise-client-urls http://${HOSTIP}:2379,http://${HOSTIP}:4001 \
 -listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 \
 -initial-advertise-peer-urls http://${HOSTIP}:2380 \
 -listen-peer-urls http://0.0.0.0:2380 \
 -initial-cluster-token etcd-cluster-1 \
 -initial-cluster etcd=http://${HOSTIP}:2380 \
 -initial-cluster-state new

# Create the first node
docker-machine create \
    -d vmwarefusion \
    --engine-opt="cluster-store=etcd://${HOSTIP}:2379" \
    --engine-opt="cluster-advertise=eth0:0" \
    node1

# Create the second node
docker-machine create \
    -d vmwarefusion \
    --engine-opt="cluster-store=etcd://${HOSTIP}:2379" \
    --engine-opt="cluster-advertise=eth0:0" \
    node2

# Create the overlay network
docker $(docker-machine config node1) network create -d overlay mynet

# Run the Nginx container on node1
docker $(docker-machine config node1) run -itd --name=web --net=mynet nginx

# Run the busybox container on node2
docker $(docker-machine config node2) run -it --rm --net=mynet busybox wget -qO- http://web
