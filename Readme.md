# HLF-FAL

Previous Steps: 

1. Clone this repo

2. Download the binaries of fabric:
```bash
cd fabric-samples-main/test-network
./network.sh down
curl -sSL https://bit.ly/2ysbOFE | bash -s
```

**HLF-FAL Configuration Guide**

**Step 1: Define Organizations and Peers**

1. Create Crypto Material for Organizations:
**Organizations and Peers Configuration:**
You'll need to define your organizations (OEM, Supplier, Airline) and their peers in the network configuration files. 

**Path:** /test-network/organizations/cryptogen/
**Files to Edit:** If using cryptogen, edit crypto-config.yaml to include your organizations and peers.

**Example Entry for OEM in crypto-config-oem.yaml:**


```yaml
PeerOrgs:
  - Name: OEM
    Domain: oem.example.com
    EnableNodeOUs: true
    Template:
      Count: 5
    Users:
      Count: 1
```

Adjust the Count under Template for the number of peers and add similar entries for Supplier and Airline with their respective peer counts.


2. Generate the Crypto Material: Run the cryptogen tool using your custom crypto-config.yaml for each organization.

Same directory: fabric-samples/test-network/organizations/cryptogen

Here, Generate the Crypto Material: Run the cryptogen tool using your custom crypto-config.yaml for each organization.

cryptogen generate --config=./crypto-config.yaml —output="organizations"

First, export the path to the binaries: 

```json
Your Specific Case Sigrid:
export PATH=$PATH:/Users/sigridveronica/go/src/github.com/FAL/fabric-samples/bin
```

```bash
export PATH=$PATH:path-to-your-fabric-samples/bin
```

> [!warning]  
> From test-network, run:

For every organization:
```bash
cryptogen generate --config=./organizations/cryptogen/crypto-config-oem.yaml --output="organizations"
cryptogen generate --config=./organizations/cryptogen/crypto-config-airline.yaml --output="organizations"
cryptogen generate --config=./organizations/cryptogen/crypto-config-supplier.yaml --output="organizations"
```
```bash
cryptogen generate --config=./organizations/cryptogen/crypto-config-orderer.yaml --output="organizations"
```

This will generate the crypto material. Therefore a new folder will be generated called organizations, where you will find:
inside test-network/organizations:
- Peeroganizations
- OrdererOrganizations
There will be the msp and tls certificates you need for the next steps

To make sure it has been correctly generated navigate to cryptogen/organizations and look for a folder for each of the organizations you just called with the cryptogen command

****Update Network Configuration****
**Step 2: Configure Channel Artifacts**


2.1. Edit the configtx.yaml File: Modify the configtx.yaml file to include your new organizations. You can use the structure in /test-network/addOrg3/configtx.yaml as a reference. Define each organization under the Organizations: section.

*Channel Configuration:*
Channels are defined in the configtx.yaml file. You'll need to define your channels and which organizations are part of each channel.

Path: /test-network/configtx/
File to Edit: configtx.yaml

2.1.1 Define the Organizations:

```yaml
Organizations:
  - &OEM
    Name: OEMMSP
    ID: OEMMSP
    MSPDir: ../organizations/peerOrganizations/oem.example.com/msp
    Policies:
      Readers:
        Type: Signature
        Rule: "OR('OEMMSP.member')"
      Writers:
        Type: Signature
        Rule: "OR('OEMMSP.member')"
      Admins:
        Type: Signature
        Rule: "OR('OEMMSP.admin')"
  - &Airline
    Name: AirlineMSP
    ID: AirlineMSP
    MSPDir: ../organizations/peerOrganizations/airline.example.com/msp
    Policies:
      Readers:
        Type: Signature
        Rule: "OR('AirlineMSP.member')"
      Writers:
        Type: Signature
        Rule: "OR('AirlineMSP.member')"
      Admins:
        Type: Signature
        Rule: "OR('AirlineMSP.admin')"
  - &Supplier
    Name: SupplierMSP
    ID: SupplierMSP
    MSPDir: ../organizations/peerOrganizations/supplier.example.com/msp
    Policies:
      Readers:
        Type: Signature
        Rule: "OR('SupplierMSP.member')"
      Writers:
        Type: Signature
        Rule: "OR('SupplierMSP.member')"
      Admins:
        Type: Signature
        Rule: "OR('SupplierMSP.admin')"
``` 
2.1.2 Define the Channel Configurations:

Next, you'll need to define the profiles for your channels. Since your network is new and you're adding this configuration, you'll also need to define the consortium and the default channel configurations. Here's how you might define the profiles for your channels, including the specific peers for each organization within those channels:
Example Entry for Channels:
```yaml
Profiles:
  OEMChannel:
    Consortium: SampleConsortium
    Application:
      <<: *ApplicationDefaults
      Organizations:
        - *OEM
      Capabilities:
        <<: *ApplicationCapabilities
  AirlineOEMChannel:
    Consortium: SampleConsortium
    Application:
      <<: *ApplicationDefaults
      Organizations:
        - *OEM
        - *Airline
      Capabilities:
        <<: *ApplicationCapabilities
  SupplierOEMChannel:
    Consortium: SampleConsortium
    Application:
      <<: *ApplicationDefaults
      Organizations:
        - *OEM
        - *Supplier
      Capabilities:
        <<: *ApplicationCapabilities
```
2.2 Specify Peers in Channel Configurations

Hyperledger Fabric's configtx.yaml does not directly specify peers within each channel in this file. Instead, peers are added to channels and configured to endorse transactions as part of the network setup and channel creation process, typically using the Fabric CLI or SDKs. The configtx.yaml file is used to define the structure of the network at a higher level, including which organizations are part of which channels, but not the specific peers.

2.3 Generate the Genesis Block and Channel Configuration Transactions

After updating your configtx.yaml, you'll use the configtxgen tool to generate the genesis block for the system channel and the channel creation transactions for your custom channels.

The genesis block is the first block on the blockchain and serves as the starting point of the network.
 *Why not creating a genesis block for each channel?*
 *Creating a genesis block for each channel isn't typically necessary because the genesis block is primarily used to bootstrap the Hyperledger Fabric network itself, particularly the ordering service. For each additional channel you create after the network is up and running, you generate a channel configuration transaction (not a genesis block) that defines the policies, members, and settings for that specific channel. This channel configuration transaction is then submitted to the network to create the new channel.*

> [!warning]  
> Still from test-network

First, export the path to configtx to be able to run this command: 

```diff
+ export FABRIC_CFG_PATH=<path-to-your-fabric-samples>/test-network/configtx/
```
```json
export FABRIC_CFG_PATH=$PWD/configtx/
```
in your case
```dif
- export FABRIC_CFG_PATH=/Users/sigridveronica/go/src/github.com/FAL/fabric-samples/test-network/configtx/
```

2.3.1: Generate the Genesis Block for the Consortium
```bash
configtxgen -profile OEMChannel -outputBlock ./channel-artifacts/genesis.block -channelID system-channel
```

**Step 3: Update Docker Compose Files**



3.1. **Update docker-compose-test-net.yaml:**

docker-compose-test-net.yaml
This file is used to define and configure the network components necessary for a Hyperledger Fabric test network. It specifies the Docker containers that will run the Fabric peer nodes, orderer nodes, and other necessary services for the network to function. The configuration includes:

- Peer Services: Defines the peer nodes for the organizations in the network. For example, peer0.org1.example.com and peer0.org2.example.com are defined as peers for two different organizations. Each peer service configuration includes the Docker image to use (hyperledger/fabric-peer:latest), environment variables to configure the peer, and volumes for data persistence and configuration.
- Volumes: Specifies the directories on the host that are mounted into the containers. This is used for configuration files and to ensure data persistence across container restarts.
- Network Settings: Defines the Docker network settings, such as the network mode, to ensure that all containers can communicate with each other.


3.1.1 Add New Peer Services: For each new organization, you need to define peer services similar to those for peer0.org1.example.com and peer0.org2.example.com. Use the provided service definitions as a template. For example, to add a peer for the OEM organization, you might add:

```yaml
peer0.oem.example.com:
  container_name: peer0.oem.example.com
  image: hyperledger/fabric-peer:latest
  labels:
    service: hyperledger-fabric
  environment:
    - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
    - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=fabric_test
  volumes:
    - ./docker/peercfg:/etc/hyperledger/peercfg
    - ${DOCKER_SOCK}:/host/var/run/docker.sock
```
3.1.2 Repeat for Other Organizations: Repeat the above step for each peer of the Airline and Supplier organizations, adjusting the service names and container names accordingly (e.g., peer0.airline.example.com, peer0.supplier.example.com).

3.2 **Update docker-compose-ca.yaml:**

*docker-compose-ca.yaml*
This file is specifically focused on setting up the Certificate Authorities (CAs) for the network. The Certificate Authorities are responsible for issuing and managing the digital certificates for network participants, which are crucial for the authentication and authorization mechanisms in Hyperledger Fabric. However, based on the provided content, it appears that the specific configurations for the CAs were not included in the snippet. Typically, this file would include:

- CA Services: Each organization in the network would have its own CA service defined in this file. The service configuration would specify the Docker image for the CA (hyperledger/fabric-ca:latest), environment variables for CA configuration, ports for accessing the CA, and volumes for data persistence.
Environment Variables: Used to configure the CA, such as setting the home directory, CA name, and enabling TLS.
- Ports: Specifies the ports that the CA services will listen on, allowing network participants to communicate with the CA for operations like enrolling and registering identities.
In summary, the docker-compose-test-net.yaml file is used to configure and launch the core network components (peers, orderers, etc.), while the docker-compose-ca.yaml file is focused on setting up the Certificate Authorities necessary for managing identities within the network. Both are essential for deploying a functioning Hyperledger Fabric network environment using Docker.

If you're using separate CA services for each organization (which is a common practice for managing identities and permissions within Hyperledger Fabric networks), you'll need to add services for the CAs of your new organizations in the docker-compose-ca.yaml file. This file might not be explicitly mentioned in the summaries, but it's commonly used for defining Certificate Authorities in Fabric networks.

3.2.1 Define CA Services: For each new organization, define a CA service. You can base your definitions on any existing CA service definitions, modifying them to suit your new organizations. For example:
```yaml
ca_oem:
  image: hyperledger/fabric-ca:latest
  environment:
    - FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server
    - FABRIC_CA_SERVER_CA_NAME=ca-oem
  ports:
    - "7054:7054"
  command: sh -c 'fabric-ca-server start -b admin:adminpw -d'
  volumes:
    - ./fabric-ca/oem:/etc/hyperledger/fabric-ca-server
```
3.2.2 Adjust Ports and Volumes: Make sure to adjust the ports and volume paths for each CA service to avoid conflicts and ensure that each organization's data is stored separately.

3.3 Network and Volume Definitions
- Network: Ensure all your services are defined to use the same network (e.g., fabric_test). This might involve setting networks at the bottom of your Docker Compose file and ensuring each service is attached to it.
- Volumes: Adjust volume paths as necessary to ensure that configuration files, certificates, and other data are correctly mapped into your containers.

**Final Steps**
Review and Validate: After making these changes, review your Docker Compose files to ensure that all services are correctly defined and that there are no conflicts in names, ports, or volumes.
Start the Network: 
Run the following command to start your network with the new configuration: 
> [!warning]  
> From test-network

Before running the docker-compose command, export the DOCKER_SOCK environment variable with the path to your Docker socket. On Unix-based systems, including macOS, the Docker socket is typically located at /var/run/docker.sock. You can set the variable like this:

```json
export DOCKER_SOCK=/var/run/docker.sock
```
After setting the environment variable, you can rerun your docker-compose command:

```json
docker-compose -f compose/docker/docker-compose-ca.yaml -f compose/docker/docker-compose-test-net.yaml up -d
```

Your output in the terminal should look like this:

![Alt Text](https://github.com/sigridveronica/HLF-FAL2/blob/main/Images/output%20docker-ps-.png)

> [!note]  
> If you encounter issues, check the Docker logs for your containers to identify any errors in the configuration or startup process.
> This guide provides a high-level overview of the steps required to include new organizations in your Hyperledger Fabric network using Docker Compose. Depending on your specific requirements, additional configuration or adjustments may be necessary.


**Step 4: Update the network.sh Script**

The network.sh script is used to bring up the network, create channels, and deploy chaincode. You'll need to modify this script to handle your new organizations.

**4.1.1 Modify network.sh:** 
Update the script to include your new organizations when bringing up the network, creating channels, and setting anchor peers. This might involve significant changes, depending on how different your setup is from the default.

```yaml
# Define organizations and peers
ORG1_PEERS=("QA1.1.oem.example.com" "QA1.2.oem.example.com")
ORG2_PEERS=("QA2.1.supplier.example.com")
ORG3_PEERS=("QA3.1.airline.example.com")

# Create Channel OEM
./network.sh createChannel -c channelOEM
# Join OEM peers to Channel OEM
for peer in "${ORG1_PEERS[@]}"; do
    ./network.sh joinChannel -c channelOEM -p $peer
done

# Create Channel Airline-OEM
./network.sh createChannel -c channelAirlineOEM
# Join relevant peers
./network.sh joinChannel -c channelAirlineOEM -p "QA1.2.oem.example.com"
./network.sh joinChannel -c channelAirlineOEM -p "QA3.1.airline.example.com"

# Similar steps for Channel Supplier-OEM
```

**Step 5: Update network.sh**
To adapt the network.sh script for your network configuration involving three organizations (Supplier, Airline, OEM) with specific peers and channels, you'll need to make several modifications. 

- Organization and Peer Configuration
You need to modify the script to recognize three organizations with their respective peers. This involves adjusting the createOrgs function to generate crypto material for all three organizations and their peers. 

OEM with 5 peers: QA1.1, QA1.2, SW1.1, SW1.2, SW1.3
Supplier with 1 peer: QA2.1
Airline with 1 peer: QA3.1
-Channel Creation and Management
Modify the createChannel function to create three channels (OEM, Airline-OEM, Supplier-OEM) instead of the default one. You will need to use the configtxgen tool to generate the channel creation transaction and update the script to create and manage these channels.

-Joining Peers to Channels
Adjust the script to join the correct peers to each channel. This involves modifying the logic that handles peer joining post-channel creation. Ensure that:

All 5 OEM peers join the OEM channel.
QA1.2 (OEM) and QA3.1 (Airline) join the Airline-OEM channel.
QA2.1 (Supplier) and QA1.2 (OEM) join the Supplier-OEM channel.
- Chaincode Deployment
If deploying chaincodes to these channels, modify the deployCC or deployCCAAS functions to target the correct channels and peers. This includes specifying the correct chaincode package, policy, and initialization parameters for each deployment.

-Network Cleanup and Reset
Ensure the networkDown function correctly cleans up all artifacts related to your three organizations and their channels. This is crucial for resetting the network state during testing or after network shutdown.


For each channel, you need to create a channel configuration transaction. This defines the initial configuration of the channel, including which organizations are members.
For the OEM channel, you've already created the genesis block which acts as the initial configuration. For the Airline-OEM and Supplier-OEM channels, you'll need to create configuration transactions.
> [!Warning]
>  DO NOT copy paste this, it's part of the yaml file, not a command to paste on the terminal

```yaml
configtxgen -profile OEMChannel -outputCreateChannelTx ./channel-artifacts/OEMChannel.tx -channelID oemchannel
#Create Channel Transaction for AirlineOEMChannel

configtxgen -profile AirlineOEMChannel -outputCreateChannelTx ./channel-artifacts/AirlineOEMChannel.tx -channelID airlineoemchannel

#2.3.4 Create Channel Transaction for SupplierOEMChannel

configtxgen -profile SupplierOEMChannel -outputCreateChannelTx ./channel-artifacts/SupplierOEMChannel.tx -channelID supplieroemchannel
```


**5.2 Bring Up the Network** 
Once you've made the necessary updates, you can use the network.sh script to bring up your network. Since you've modified the organizations, ensure you also update any flags or parameters you pass to the script to reflect your new setup.

```bash
./network.sh up
```

## CHANNELS AND SMART CONTRACT MANAGEMENT:
You need to update different files:
```bash
chaincode/
└── oemContract/
    ├── go.mod
    ├── go.sum
    └── oemContract.go
```
Also, modify SetOrgEnv.sh
Create, for each channel: deployOEMChaincode.sh, invokeOEMChaincode.sh

## Writing the Smart Contract

First, you need to write your smart contract code. Let's assume you're writing a smart contract in Go for simplicity, but you can use other supported languages like JavaScript or Java.

Create a directory for your smart contract code. For example, if your smart contract is named oemContract, you might create a directory structure like this:
```bash
chaincode/
└── oemContract/
    ├── go.mod
    ├── go.sum
    └── oemContract.go
```
Inside oemContract.go, you'll define the logic for your smart contract. 

### 2. Packaging the Smart Contract


Use the peer lifecycle chaincode package command to package your smart contract. This step is done from a machine that has access to the Hyperledger Fabric binaries.

```bash
peer lifecycle chaincode package oemContract.tar.gz --path ./chaincode/oemContract/ --lang golang --label oemContract_1
```

### 3. Installing the Smart Contract**


Install the smart contract on the relevant peers. Since Channel OEM involves all 5 peers of the OEM organization, you'll need to install the chaincode on each of these peers. You'll use the peer lifecycle chaincode install command for this:

```bash
peer lifecycle chaincode install oemContract.tar.gz
```

**4. Approving the Smart Contract for the Channel**

Each organization participating in the channel must approve the smart contract. This is done using the peer lifecycle chaincode approveformyorg command.

```bash
peer lifecycle chaincode approveformyorg --channelID ChannelOEM --name oemContract --version 1 --package-id <PackageID> --sequence 1 --init-required
```
> [!note]
>  "PackageID" is returned by the install command and is unique to the chaincode package on each peer.

**5. Committing the Smart Contract to the Channel**

After all organizations have approved the smart contract, any organization can commit it to the channel using the peer lifecycle chaincode commit command.

```bash
peer lifecycle chaincode commit --channelID ChannelOEM --name oemContract --version 1 --sequence 1 --init-required
```

***6. Initializing the Smart Contract (Optional)***

If your smart contract requires initialization, you can do so after committing it.
```json
peer chaincode invoke -o <OrdererAddress> --isInit --channelID ChannelOEM --name oemContract -c '{"function":"InitLedger","Args":[]}'
```
```json
REMOVE THIS IS CHATGPT
Replace <OrdererAddress> with the address of your orderer.

This guide provides a high-level overview of deploying a smart contract to a specific channel in your modified network. Repeat similar steps for deploying smart contracts to other channels, adjusting the peers and channel names as necessary.
```


### Writing the Smart Contract
To create a smart contract structure that simulates the transfer of an aircraft (Asset) through different stations within the OEM organization, you can follow a modular approach. This involves defining a smart contract for each activity (Drill for engine allocation, Add engines, Coating+Finishing for delivery) with the specified attributes. Here's a conceptual outline based on the provided structure and the existing asset_transfer.go smart contract as a reference.

**Step 1: Define the Asset and Activity Structures**

First, define the structures for the Asset and the Activity. Each activity will have its own set of attributes as specified.
```go
package chaincode

import (
    "encoding/json"
    "fmt"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// Asset represents the aircraft being assembled
type Asset struct {
    ACNumber string `json:"acNumber"` // Aircraft number
}

// Activity represents an activity in the assembly line
type Activity struct {
    ActivityID       string `json:"activityID"`
    StartTime        string `json:"startTime"`
    EndTime          string `json:"endTime"`
    StationNumber    int    `json:"stationNumber"`
    MachineID        string `json:"machineID"`
    ToolsOrDrill     string `json:"toolsOrDrill"`
    PartsID          string `json:"partsID"` // Part Number (P/N)
    WorkerID         string `json:"workerID"`
    StationResponsible string `json:"stationResponsible"`
    PreviousStation  string `json:"previousStation"`
    NextStation      string `json:"nextStation"`
}
```
**Step 2: Implement Activity Functions**

For each activity, implement a function that creates an entry for the activity. Here's an example for the "Drill for engine allocation" activity:

```go
// CreateDrillActivity creates an entry for the Drill activity
func (s *SmartContract) CreateDrillActivity(ctx contractapi.TransactionContextInterface, activityID string, startTime string, endTime string, stationNumber int, machineID string, toolsOrDrill string, partsID string, workerID string, stationResponsible string, previousStation string, nextStation string) error {
    activity := Activity{
        ActivityID:       activityID,
        StartTime:        startTime,
        EndTime:          endTime,
        StationNumber:    stationNumber,
        MachineID:        machineID,
        ToolsOrDrill:     toolsOrDrill,
        PartsID:          partsID,
        WorkerID:         workerID,
        StationResponsible: stationResponsible,
        PreviousStation:  previousStation,
        NextStation:      nextStation,
    }

    activityJSON, err := json.Marshal(activity)
    if err != nil {
        return fmt.Errorf("failed to marshal activity: %v", err)
    }

    // Use a composite key to uniquely identify the activity
    activityKey, err := ctx.GetStub().CreateCompositeKey("Activity", []string{activityID})
    if err != nil {
        return fmt.Errorf("failed to create composite key: %v", err)
    }

    return ctx.GetStub().PutState(activityKey, activityJSON)
}
```
**Step 3: Transfer Asset to Next Station**
Implement a function to transfer the asset to the next station. This function updates the asset's current station and validates the transfer with peers.

```go
// TransferAssetToNextStation transfers the asset to the next station
func (s *SmartContract) TransferAssetToNextStation(ctx contractapi.TransactionContextInterface, acNumber string, nextStation string) error {
    // Implementation for transferring the asset and validation
}

```
**Step 4: Validation by Peers**

Ensure that each activity entry and asset transfer is validated by peers. This can be achieved through endorsement policies in Hyperledger Fabric, where you specify which organizations' peers need to endorse a transaction.

**Step 5: Deploy and Test**

After implementing the smart contracts, deploy them to your Hyperledger Fabric network. Test the workflow by invoking the smart contract functions and verifying that the asset moves through the stations as expected, with all activities being recorded and validated.

**COMMANDS**

> [!warning]  
> TO PROPERLY RUN, YOU MUST BE INSIDE THE CHAINCODE FOLDER WHERE YOU HAVE THE .go file 

```diff
@@ go mod init <module name>
```

```bash
go mod init oemChaincode.go
```
Add Dependencies: If your chaincode depends on external packages, such as Hyperledger Fabric's contract API, you'll need to add them to your module. Usually, running go build or go test inside the module directory automatically adds required dependencies to your go.mod file. However, you can also manually add dependencies by running:
```fine
@@ go get <dependency>
```
```bash
go get github.com/hyperledger/fabric-contract-api-go@latest
```

> [!warning]  
> GO BACK TO TEST-NETWORK
set the FABRIC_CFG_PATH to the parent config directory like so:
```bash
export FABRIC_CFG_PATH=${PWD}/../config/
```
Verify the existence of core.yaml: After setting the FABRIC_CFG_PATH, verify that the core.yaml file exists at the specified path by running:
```bash
ls ${FABRIC_CFG_PATH}
```
*This command should list the core.yaml among other configuration files. If the file is not present, you'll need to locate it and ensure it's in the correct directory.*

```bash
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/oem.example.com/msp
```
**1.Package your chaincode**
```bash
peer lifecycle chaincode package oemContract.tar.gz --path ./chaincode/oemContract/ --lang golang --label oemContract_1
```
**2.Install the chaincode package on all the peers**

You need to install the chaincode package on all peers that will execute and endorse the chaincode. Use the following command to install the chaincode:
```bash
peer lifecycle chaincode install oemContract.tar.gz
```
*This command will return a package ID, which is needed for the next steps. The package ID is a combination of the label you specified when packaging the chaincode and a hash of the package contents, for example, oemContract_1:74aaf6c776....*

**3.Approve the Chaincode Definition for Your Organization**

Before a chaincode can be committed to a channel, it must be approved by a sufficient number of organizations according to the channel's lifecycle policy. To approve the chaincode definition for your organization, use the following command:
```bash
peer lifecycle chaincode approveformyorg --channelID mychannel --name oemContract --version 1 --package-id oemContract_1:74aaf6c776... --sequence 1 --tls --cafile $ORDERER_CA --orderer orderer.example.com:7050
```
```json
Replace mychannel with the name of your channel, oemContract_1:74aaf6c776... with the actual package ID returned by the install command, and adjust the --orderer and --cafile flags according to your network configuration.
```
**3.Check Commit Readiness (Optional)**

Before committing the chaincode definition to the channel, you can check whether the required organizations have approved the definition:
```bash
peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name oemContract --version 1 --sequence 1 --tls --cafile $ORDERER_CA --output json
```
This command returns a JSON payload that indicates whether each organization in the channel has approved the proposed chaincode definition.

**Commit the Chaincode Definition to the Channel**

Once the necessary organizations have approved the chaincode definition, any organization can commit it to the channel:

```bash

peer lifecycle chaincode commit -o orderer.example.com:7050 --channelID mychannel --name oemContract --version 1 --sequence 1 --tls --cafile $ORDERER_CA --peerAddresses peer0.org1.example.com:7051 --peerAddresses peer0.org2.example.com:9051
```
*Adjust the --peerAddresses flags to include the peers from all required organizations according to your channel's endorsement policy.*

**Step 5: Verify the Chaincode is Committed**

Finally, you can verify that the chaincode has been successfully committed to the channel:
```bash
peer lifecycle chaincode querycommitted --channelID mychannel --name oemContract --cafile $ORDERER_CA
```
This command will list the committed chaincode definitions on the channel, including the version, sequence, and endorsement policy.





```json
#############################################################################################################
```

****NETWORK UP AND RUNNING: DEPLOY CHAINCODE****

Given the modifications we've made to the network setup, including the addition of new organizations, peers, and channels, you'll need to adjust the setOrgEnv.sh script to correctly set environment variables for your new organizational structure. 

**Modifying setOrgEnv.sh**

The setOrgEnv.sh script is likely setting environment variables based on the original network configuration, which includes Org1 and Org2. For your new setup, you need to modify this script to include your new organizations (Supplier, Airline, OEM) and their respective peers.

Here's a general approach:

- Define Environment Variables for Each Organization and Peer: For each of your organizations and their peers, you'll need to define environment variables. These variables typically include peer addresses, MSP (Membership Service Provider) IDs, and wallet paths for each peer.

- Add Conditional Blocks for Each Organization: You can use conditional blocks (if-else statements) to set these environment variables based on the organization and peer being targeted. For example:

```sh
if [ "$ORG" == "OEM" ]; then
    if [ "$PEER" == "QA1.1" ]; then
        export CORE_PEER_ADDRESS=qa1.1.oem.example.com:7051
        # Set other environment variables specific to QA1.1
    elif [ "$PEER" == "QA1.2" ]; then
        export CORE_PEER_ADDRESS=qa1.2.oem.example.com:7051
        # Set other environment variables specific to QA1.2
    fi
    # Repeat for other peers
elif [ "$ORG" == "Supplier" ]; then
    if [ "$PEER" == "QA2.1" ]; then
        export CORE_PEER_ADDRESS=qa2.1.supplier.example.com:7051
        # Set other environment variables specific to QA2.1
    fi
elif [ "$ORG" == "Airline" ]; then
    if [ "$PEER" == "QA3.1" ]; then
        export CORE_PEER_ADDRESS=qa3.1.airline.example.com:7051
        # Set other environment variables specific to QA3.1
    fi
fi
```
> [!Warning]   Update the Script Invocation: When you run scripts that depend on setOrgEnv.sh, ensure you're passing the correct organization and peer names as arguments or
> environment variables, depending on how setOrgEnv.sh is set up to receive input.

**Running Chaincode Commands**

After updating the setOrgEnv.sh script, you should be able to run chaincode lifecycle commands without encountering the previous errors. Ensure you set the environment variables by sourcing setOrgEnv.sh with the correct parameters before running any peer lifecycle chaincode commands.

For example, before packaging the chaincode for the OEM, you might run:
```bash
source setOrgEnv.sh OEM QA1.1
peer lifecycle chaincode package oemContract.tar.gz --path ./chaincode/oemContract/ --lang golang --label oemContract_1
```

2.3.2: Create Channel Transaction for OEMChannel

> [!note]  
> Troubleshooting: zsh: command not found: cryptogen

```diff
+ export FABRIC_CFG_PATH=<path-to-your-fabric-samples-main>/test-network/configtx/
```

> [!note]  
> Troubleshooting: zsh: *command not found: cryptogen:* indicates that the cryptogen tool is either not installed or not included in your system's PATH. The cryptogen tool is a utility provided by Hyperledger Fabric for generating cryptographic material (such as keys and certificates) for the network's organizations and orderers. 

```diff
+ export PATH=<path_to_fabric_samples>/bin:$PATH
```

****INTERACT WITH YOUR NETWORK****

Creating an application from scratch that interacts with your oemContract.go smart contract involves several steps, including setting up your development environment, writing the application code, and deploying the application. Below is a comprehensive guide to get you started.

**Step 1: Environment Setup**

> [!note]  
> If you are following the tutorial, step 1 has been described above: Use the Hyperledger Fabric test network from the fabric-samples repository as a starting point.
> Navigate to the test-network directory and start the network 
> Deploy Your Smart Contract:
> Package your oemContract.go smart contract.
> Install the chaincode on your network using the peer CLI.
> Approve and commit the chaincode.


**Step 2: Application Development**
Create a New Go Module:

In a new directory, initialize a Go module:
```bash
go mod init oemContractApp
```

**Write Your Application Code:**

Refer to the assetTransfer.go file for examples of how to interact with the network.
Implement functions to interact with your smart contract's CreateActivity and TransferAsset functions. 

**Manage Dependencies:**

Add the Fabric SDK Go to your module:
```bash
go get github.com/hyperledger/fabric-sdk-go
```
Ensure all dependencies are correctly installed by running:
```bash
go mod tidy
```

**Step 3: Application Execution**

**Run Your Application:**
Execute your application with:
```bash
go run .
```
This will interact with your deployed smart contract on the Hyperledger Fabric network.

**Step 4: Frontend (Optional)**

If you plan to create a frontend for your application:

Choose a Framework:

Decide on a frontend framework or library (e.g., React, Angular, Vue.js).
Set Up Your Frontend Project:

Initialize your project using your chosen framework's CLI.
Implement the UI to interact with your backend application.
Integrate with the Backend:

Use REST APIs or a similar approach to connect your frontend with the Go application.



















-------- NOT SURE THIS IS CORRECT ----------

```diff
- text in red
+ text in green
! text in orange
# text in gray
@@ text in purple (and bold)@@
```




To set up your Hyperledger Fabric network with the specific organizations (OEM, Airline, Supplier) instead of the default Org1 and Org2, you'll need to modify several configuration files and potentially scripts within the test-network directory. Here's a step-by-step guide to help you through this process:

Step 1: Update Cryptographic Material
First, you need to generate cryptographic material for your new organizations. Since the cryptogen tool uses a configuration file to generate these materials, you'll need to create or modify existing crypto-config.yaml files for each of your organizations (OEM, Airline, Supplier).

Create or Modify Crypto Config Files: Ensure you have a crypto-config.yaml for each of your organizations with the correct specifications. If these don't exist, you'll need to create them based on the examples provided for Org1 and Org2.

Generate Cryptographic Material: Run the cryptogen tool for each of your organizations. For example:

```bash
cryptogen generate --config=./organizations/cryptogen/crypto-config-oem.yaml --output="organizations"
cryptogen generate --config=./organizations/cryptogen/crypto-config-airline.yaml --output="organizations"
cryptogen generate --config=./organizations/cryptogen/crypto-config-supplier.yaml --output="organizations"
```

**Step 2: Update Network Configuration**
The configtx.yaml file defines the network configuration, including the consortiums and the channel configurations. You'll need to modify this file to include your new organizations.

Modify configtx.yaml: Add your organizations under the Organizations section, and update the Profiles section to include your organizations in the consortium and channel configurations.

**Step 3: Update Docker Compose Files**
The Docker Compose files define the network's infrastructure. You'll need to modify these files to include your new organizations' peers, CAs, etc.

Modify or Create Docker Compose Files: Based on the existing docker-compose-test-net.yaml, docker-compose-ca.yaml, and others, include services for your new organizations. Make sure to update service names, container names, and any relevant configurations to reflect your organizational structure.

**Step 4: Update the network.sh Script**

The network.sh script is used to bring up the network, create channels, and deploy chaincode. You'll need to modify this script to handle your new organizations.

Modify network.sh: Update the script to include your new organizations when bringing up the network, creating channels, and setting anchor peers. This might involve significant changes, depending on how different your setup is from the default.

**Step 5: Bring Up the Network**
Once you've made the necessary updates, you can use the network.sh script to bring up your network. Since you've modified the organizations, ensure you also update any flags or parameters you pass to the script to reflect your new setup.

```bash
Copy code
./network.sh up
./network.sh createChannel
```

**Step 6: Deploy Chaincode**
Follow the instructions in the README and the modified network.sh script to deploy your chaincode to the new network.


**Additional Notes**
Backup Original Files: Before making any changes, it's a good idea to backup the original configuration files and scripts.
Review Changes Carefully: Ensure that your modifications are consistent across all files. Mismatches in organization names, MSP IDs, or channel configurations can lead to errors when starting the network.
Documentation: Refer to the Hyperledger Fabric documentation for more details on configuration file formats and network setup.
This process involves significant customization of the test network. Ensure you have a good understanding of Hyperledger Fabric's configuration mechanisms and the purpose of each component in the network.




