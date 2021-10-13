# dockerfiles
A set of Dockerfiles

## Usage with private registry
```shell
docker build -t centos7-systemd-proxy centos8-systemd-proxy

docker tag centos7-systemd-proxy localhost:5000/centos8-systemd-proxy

docker push localhost:5000/centos8-systemd-proxy

docker run -d --tmpfs /tmp --tmpfs /run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  --name centos8-systemd-proxy localhost:5000/centos8-systemd-proxy

docker exec  centos8-systemd-proxy systemctl list-units

docker exec -it centos8-systemd-proxy bash
```