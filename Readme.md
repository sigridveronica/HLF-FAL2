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

```json
LOCATE IN TEST-NETWORK TO RUN
```

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

```diff
- WARNING!!
- inside the cryptogen:
```

First, export the path to configtx to be able to run this command: 

```diff
+ export FABRIC_CFG_PATH=<path-to-your-fabric-samples>/test-network/configtx/
```
in your case
```dif
- export FABRIC_CFG_PATH=/Users/sigridveronica/go/src/github.com/FAL/fabric-samples/test-network/configtx/
```

2.3.1: Generate the Genesis Block for the Consortium
```bash
configtxgen -profile OEMChannel -outputBlock ./channel-artifacts/genesis.block -channelID system-channel
```
2.3.2: Create Channel Transaction for OEMChannel

For each channel, you need to create a channel configuration transaction. This defines the initial configuration of the channel, including which organizations are members.
For the OEM channel, you've already created the genesis block which acts as the initial configuration. For the Airline-OEM and Supplier-OEM channels, you'll need to create configuration transactions.

```bash
configtxgen -profile OEMChannel -outputCreateChannelTx ./channel-artifacts/OEMChannel.tx -channelID oemchannel
```
2.3.3 Create Channel Transaction for AirlineOEMChannel
```bash
configtxgen -profile AirlineOEMChannel -outputCreateChannelTx ./channel-artifacts/AirlineOEMChannel.tx -channelID airlineoemchannel
```
2.3.4 Create Channel Transaction for SupplierOEMChannel
```bash
configtxgen -profile SupplierOEMChannel -outputCreateChannelTx ./channel-artifacts/SupplierOEMChannel.tx -channelID supplieroemchannel
```

Troubleshooting: 

```diff
+ export FABRIC_CFG_PATH=<path-to-your-fabric-samples-main>/test-network/configtx/
```
zsh: command not found: cryptogen

```diff
+ export PATH=<path_to_fabric_samples>/bin:$PATH
```
*command not found: cryptogen* indicates that the cryptogen tool is either not installed or not included in your system's PATH. The cryptogen tool is a utility provided by Hyperledger Fabric for generating cryptographic material (such as keys and certificates) for the network's organizations and orderers. 





-------- NOT SURE THIS IS CORRECT ----------

```diff
- text in red
+ text in green
! text in orange
# text in gray
@@ text in purple (and bold)@@
```

```bash
configtxgen -profile SampleMultiNodeEtcdRaft -channelID system-channel -outputBlock ./channel-artifacts/genesis.block
```
SampleMultiNodeEtcdRaft is a commonly used profile for networks that use the Raft consensus protocol. You should replace this with the profile name that matches your network's configuration in configtx.yaml. The system-channel is a default name for the system channel; you might need to adjust it according to your setup.

2. Generate Channel Configuration Transaction: Use the configtxgen tool to create the channel creation transaction and channel update transactions for each channel.


```bash
# Generate the channel configuration transaction for OEMAirlineChannel
configtxgen -profile OEMAirlineChannel -outputCreateChannelTx ./channel-artifacts/oemairlinechannel.tx -channelID oemairlinechannel

# Generate the channel configuration transaction for AllOrgsChannel
configtxgen -profile AllOrgsChannel -outputCreateChannelTx ./channel-artifacts/allorgschannel.tx -channelID allorgschannel
```
Now the files oemairlinechannel.tx and allorgschannel.tx will be generated insite channel-artifacts. Replace ./channel-artifacts/ with the actual path where you want to store the generated channel artifacts.

Adjust the Organizations section under each channel profile to include the correct organizations.

**Step 3: Deploy Network**

After configuring your organizations and channels, you'll need to generate the necessary cryptographic material and channel artifacts.

*Generate Crypto Material:*
```bash
cryptogen generate --config=./organizations/cryptogen/crypto-config.yaml
```

*Generate Channel Artifacts:* Generate the Genesis Block:
The genesis block is the first block on the chain and is used to bootstrap the network. You can generate it using the configtxgen tool with a command like:
```bash
configtxgen -profile OEMChannel -outputCreateChannelTx ./channel-artifacts/oemchannel.tx -channelID oemchannel
configtxgen -profile AirlineOEMChannel -outputCreateChannelTx ./channel-artifacts/airlineoemchannel.tx -channelID airlineoemchannel
```


<span style="color:red">
Real case Sigrid:
</span>
For every organization:
```bash
cryptogen generate --config=./crypto-config-oem.yaml --output="organizations"
cryptogen generate --config=./crypto-config-airline.yaml --output="organizations"
cryptogen generate --config=./crypto-config-supplier.yaml --output="organizations"
```


Replace oemchannel and airlineoemchannel with your channel names and adjust profiles as per your configtx.yaml.

**Step 4: Start the Network**

Use the provided network scripts or Docker Compose files (if available) to start your network.

**Step 5: Create and Join Channels**

For each channel, you'll need to create the channel and then join the relevant peers to it.
```bash
peer channel create -o orderer.example.com:7050 -c oemchannel -f ./channel-artifacts/oemchannel.tx
peer channel join -b oemchannel.block
```

Repeat the process for each channel and for each peer that needs to join a channel, adjusting the command parameters as necessary.

Note:

This guide assumes familiarity with Hyperledger Fabric CLI tools and basic network setup procedures.
The exact commands and file paths might vary based on your specific version of fabric-samples and your network configuration.
Ensure you have all necessary binaries and Docker images for the version of Hyperledger Fabric you are using.
This overview provides a starting point. Given the complexity of Hyperledger Fabric networks, you may need to adjust these instructions based on your specific requirements and the current state of your network configuration.
