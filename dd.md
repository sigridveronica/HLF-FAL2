The sequence is as follows: Define your network configuration in configtx2.yml → Generate network artifacts using configtxgen → Create channels with ./network.sh createChannel → Join peers to the channel → Optionally update anchor peers → Deploy chaincode.


**Step 1: Revise Your Network Configuration**
Remember, the configtx.yml file defines your network's configuration, including organizations, capabilities, application parameters, orderer parameters, channel parameters, and profiles for your channels (e.g., OEMChannel, AirlineOEMChannel, SupplierOEMChannel).

This configuration file is crucial for generating the necessary artifacts for your network, such as the genesis block for the system channel and the channel creation transactions for your application channels.

**Step 2: Generate Network Artifacts**

Use the configtxgen tool to generate the necessary artifacts based on your configtx2.yml configuration. This includes the genesis block for the system channel and the channel creation transactions for your application channels.
These artifacts are required to create new channels and to configure the network according to your setup.
Commands:
```bash
configtxgen -profile OEMChannel -outputCreateChannelTx ./channel-artifacts/OEMChannel.tx -channelID oemchannel
```


**Step 3: Create the Channels**

Use the the following command to create your channels:
```json
./network.sh createChannel -c <channelName> 
```

This script simplifies the process of creating a channel by automating the use of the channel creation transactions generated in the previous step.
This step officially creates the channels on your network, allowing for isolated communication between the members of each channel.

*Step 4: Join Peers to the Channel**

Ensure that the peers of each organization join the created channels. This can be done automatically as part of the createChannel script or manually using the peer channel join command.
Commands:
```json

peer channel join -b <channelName>.block
```

Peers need to join a channel to participate in the ledger and smart contract (chaincode) activities of that channel.

**Step 5: Update Anchor Peers (Optional)**

Action: Update the anchor peers for each organization in the channel. This step is optional but recommended for efficient communication between organizations in a channel.
Commands:
```json
peer channel update -o <ordererAddress> -c <channelName> -f ./channel-artifacts/<OrgName>anchors.tx --tls --cafile $ORDERER_CA
```
Anchor peers play a crucial role in communication between different organizations in a channel, especially for gossip protocol.

**Step 6: Deploy the Chaincode**

 Deploy your chaincode to the network. This involves packaging the chaincode, installing it on your peers, approving it for your organization(s), and then committing it to the channel.
Commands:
```json
peer lifecycle chaincode package assetTransfer.tar.gz --path /fabric-samples/asset-transfer-basic/chaincode-go --lang golang --label assetTransfer_1
```
Purpose: Deploying the chaincode allows you to implement the business logic that the peers in the channel will execute.
