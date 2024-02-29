## CHANNELS AND SMART CONTRACT MANAGEMENT:
You need to update different files:
```bash
chaincode/
└── oemContract/
    ├── go.mod
    ├── go.sum
    └── oemContract.go
```
```json
Added
deployOEMChaincode.sh

invokeOEMChaincode.sh

Must change

setOrgEnv.sh
```

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

**Set the environment variables**
```json
YOU MUST WRITE THE PART TO CHANGE ALL THIS TO MAKE IT ACCORDING TO YOUR NETWORK
```
```json
Added
deployOEMChaincode.sh

invokeOEMChaincode.sh

Must change

setOrgEnv.sh
```


**SetOrgEnv.sh**

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


```bash
 source setOrgEnv.sh OEM
```

### Deploy your chaincode

Step 1: Define Channel Profiles in configtx.yaml
First, ensure your configtx.yaml file includes profiles for your channels. Since the detailed content of configtx.yaml wasn't provided, I'll give you a generic example of what the profile section might look like for one of your channels, say OEMChannel. You'll need to replicate and adapt this for each channel (AirlineOEMChannel, SupplierOEMChannel, etc.) based on your network's requirements.

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
  # Repeat for AirlineOEMChannel, SupplierOEMChannel with respective organizations
```

In this example, *OEM refers to an organization definition elsewhere in your configtx.yaml. You would replace OEM with the actual names of the organizations participating in each channel.

**Step 2: Generate Channel Configuration Transactions**

Using the configtxgen tool, you'll generate the channel creation transaction for each channel. Here's how you'd do it for the OEMChannel. Repeat this step for each channel by changing the profile and output file name accordingly.

```bash
configtxgen -profile OEMChannel -outputCreateChannelTx ./channel-artifacts/OEMChannel.tx -channelID oemchannel
```
Step 3: Create the Channels
Assuming you have access to the network and the necessary permissions, you'll use the peer CLI to create the channel on the network. This step requires the channel transaction files you generated in the previous step. Here's an example command to create the OEMChannel:

```bash
peer channel create -o <OrdererAddress> -c oemchannel -f ./channel-artifacts/OEMChannel.tx --outputBlock ./channel-artifacts/oemchannel.block --tls --cafile <OrdererCAFile>

```
Replace <OrdererAddress> and <OrdererCAFile> with the actual orderer address and CA file path in your network.

**Step 4: Deploy the Chaincode**
With the channels created, you can now deploy your chaincode to the network. The deployment process involves packaging the chaincode, installing it on your peers, approving it for your organization(s), and then committing it to the channel. Here's a simplified version of these steps for the assetTransfer chaincode:

Package the Chaincode:

```bash
peer lifecycle chaincode package assetTransfer.tar.gz --path /fabric-samples/asset-transfer-basic/chaincode-go --lang golang --label assetTransfer_1
```

Install the Chaincode on the peer:

```bash
peer lifecycle chaincode install assetTransfer.tar.gz
```
Approve the Chaincode for Your Organization:

```bash
peer lifecycle chaincode approveformyorg -o <OrdererAddress> --channelID oemchannel --name assetTransfer --version 1 --package-id <PackageID> --sequence 1 --tls --cafile <OrdererCAFile>
```
Replace <PackageID> with the ID returned by the install command.

Commit the Chaincode to the channel:

```bash
peer lifecycle chaincode commit -o <OrdererAddress> --channelID oemchannel --name assetTransfer --version 1 --sequence 1 --tls --cafile <OrdererCAFile> --peerAddresses <PeerAddress> --tlsRootCertFiles <PeerTLSCACert>
```
Replace placeholders with actual values from your network configuration. Repeat these steps for each channel, adjusting the --channelID and other relevant parameters as necessary.

This process should adapt the channel creation and chaincode deployment to your specific channels and chaincode based on the provided configtx.yaml and chaincode file.

## DEPLOY YOUR CHAINCODE 

Great! Now that you've successfully set the environment variables for the OEM organization, you can proceed with the following steps to interact with the Hyperledger Fabric network:

Using the configtxgen tool, you'll generate the channel creation transaction for each channel. Here's how you'd do it for the OEMChannel. Repeat this step for each channel by changing the profile and output file name accordingly.
```bash
configtxgen -profile OEMChannel -outputCreateChannelTx ./channel-artifacts/OEMChannel.tx -channelID oemchannel
```

Create a Channel: If you haven't already created a channel, you can do so by using the network.sh script with the createChannel option. This will create a new channel that the organizations can join.

```json
./network.sh createChannel -c <channelName>
```


Join the Channel: Make sure that the OEM peer joins the channel you've created or an existing one. You might have a script similar to network.sh with an option to join a channel, or you can use the peer CLI commands directly.

```json
peer channel join -b <channelName>.block
```

Update Anchor Peers (Optional): If you're setting up a network with multiple organizations, you'll want to update the anchor peers for each organization in the channel. This step ensures that organizations can communicate more efficiently within the channel.

```json
peer channel update -o <ordererAddress> -c <channelName> -f ./channel-artifacts/<OrgName>anchors.tx --tls --cafile $ORDERER_CA
```
Deploy Chaincode: Deploy or install chaincode on your peer. You can use the peer lifecycle chaincode commands to package, install, approve, and commit your chaincode. The exact commands depend on whether you're using the new lifecycle introduced in Fabric 2.x or the older lifecycle from Fabric 1.4.x.

For Fabric 2.x, the sequence of commands would look something like this:

bash
Copy code
peer lifecycle chaincode package mycc.tar.gz --path <pathToChaincode> --lang <language> --label <label>
peer lifecycle chaincode install mycc.tar.gz
peer lifecycle chaincode queryinstalled
You'll need to follow this with the approveformyorg and commit steps, ensuring you meet the endorsement policy requirements for your network.

Invoke Chaincode: Once the chaincode is deployed, you can invoke it to perform transactions. Here's an example of how to invoke a chaincode function:

bash
Copy code
peer chaincode invoke -o <ordererAddress> --tls true --cafile $ORDERER_CA -C <channelName> -n <chaincodeName> --peerAddresses $CORE_PEER_ADDRESS --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE -c '{"function":"<chaincodeFunction>","Args":["<arg1>","<arg2>"]}'
Query Chaincode: Similarly, you can query the chaincode to read data from the ledger:

bash
Copy code
peer chaincode query -C <channelName> -n <chaincodeName> -c '{"Args":["<queryFunction>","<queryArg>"]}'
