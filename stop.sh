docker stop cli 
docker stop peer0.org1.example.com 
docker rm peer0.org1.example.com 
docker rm cli
docker stop orderer0.example.com
docker stop orderer1.example.com
docker stop orderer2.example.com
docker rm orderer0.example.com
docker rm orderer1.example.com
docker rm orderer2.example.com
docker network rm resource_default 