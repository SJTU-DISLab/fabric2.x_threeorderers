#!/bin/bash
#在resourse目录下

#配置文件【已提前生成】
#cryptogen generate --config=./crypto-config.yaml
#mkdir channel-artifacts
#configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ./channel-artifacts/genesis.block -channelID system
#configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/mychannel.tx -channelID mychannel

#创建docker
docker-compose -f docker-compose-orderer-00.yaml up -d
docker-compose -f docker-compose-orderer-01.yaml up -d
docker-compose -f docker-compose-orderer-02.yaml up -d
docker-compose -f docker-compose-peer0-org1.yaml up -d


export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
docker exec cli peer channel create -o orderer0.example.com:7050 -c mychannel -f ./channel-artifacts/mychannel.tx --outputBlock ./channel-artifacts/mychannel.block --tls --cafile $ORDERER_CA
docker exec cli peer channel join -b ./channel-artifacts/mychannel.block
#export GO111MODULE=on
#export GOPROXY=https://goproxy.io
#cd chaincode/go/abstore
#go mod vendor
#cd ../../../
docker exec cli peer lifecycle chaincode package cc.tar.gz --path github.com/hyperledger/fabric/peer/chaincode/go/abstore --lang golang --label mycc
docker exec cli peer lifecycle chaincode install cc.tar.gz
docker exec cli peer lifecycle chaincode queryinstalled
#注意修改哈希值
docker exec cli peer lifecycle chaincode approveformyorg --tls true --cafile $ORDERER_CA --channelID mychannel -n mycc -v 1 --init-required --package-id mycc:a6749583ee20a2d33af487090e2307d4f0a279a703e64db7b95913380328cf9c --sequence 1 --waitForEvent
docker exec cli peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name mycc -v 1 --sequence 1 --output json --init-required

docker exec cli peer lifecycle chaincode commit -o orderer0.example.com:7050 --tls true --cafile $ORDERER_CA -C mychannel -n mycc -v 1 --sequence 1 --init-required --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
docker exec cli peer lifecycle chaincode querycommitted -C mychannel -n mycc
docker exec cli peer chaincode invoke -o orderer0.example.com:7050 --tls true --cafile $ORDERER_CA -C mychannel -n mycc --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --isInit -c '{"Args":["Init","a","100","b","100"]}'
sleep 5
docker exec cli peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'
sleep 5
docker exec cli peer chaincode invoke -C mychannel -n mycc -c '{"Args":["invoke","b","a","10"]}' --tls --cafile $ORDERER_CA
