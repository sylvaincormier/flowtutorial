# Deploy flow smart contracts 

## Install flow-cli

macOS

```
brew install flow-cli
```

Linux

```
sh -ci “$(curl -fsSL https://storage.googleapis.com/flow-cli/install.sh)"
```

Windows

```
iex “& { $(irm ‘https://storage.googleapis.com/flow-cli/install.ps1') }”
```

## Create IPFS ressource

https://pinata.cloud/

## clone project

```
git clone https://github.com/sylvaincormier/flowtutorial.git
```

## Init project

```
cd flowtutorial
flow project init
```

## Install Visual Studio cadence extention --optional–

## create configuration file

touch flow.json

flow.js

```
{
"emulators": {
	"default": {
	"port":  3569,
	"serviceAccount":  "emulator-account"
	}
	},
	"contracts": {
	"TutorialContract":  "./cadence/contracts/Tutorial.cdc"
	},
	"networks": {
		"emulator":  "127.0.0.1:3569",
		"mainnet":  "access.mainnet.nodes.onflow.org:9000",
		"testnet":  "access.devnet.nodes.onflow.org:9000"
	},
	"deployments": {
		"emulator": {
			"emulator-account": ["TutorialAccount"]
		}
	}
}
```

## create smart contracts

```
mkdir -p cadence/contracts
touch cadence/contracts/tutorial.cdc
pub  contract  TutorialContract {
	pub  resource  NFT {
		pub  let  id: UInt64
		init(initID: UInt64) {
		self.id = initID
		}
	}
	pub  resource  interface  NFTReceiver {
		pub  fun  deposit(token: @NFT, metadata: { String: String })
		pub  fun  getIDs(): [UInt64]
		pub  fun  idExists(id: UInt64): Bool
		pub  fun  getMetadata(id: UInt64) : { String: String }
	}
	pub  resource  Collection: NFTReceiver {
		pub  var  ownedNFTs: @{ UInt64: NFT }
		pub  var  metadataObjs: { UInt64: { String: String } }
		init() {
			self.ownedNFTs < - {}
			self.metadataObjs = {}
		}
		pub  fun  withdraw(withdrawID: UInt64): @NFT {
			let  token < - self.ownedNFTs.remove(key: withdrawID)! 
			return < -token
		}
		pub  fun  deposit(token: @NFT, metadata: { String:  String }) {
			self.metadataObjs[token.id] = metadata
			self.ownedNFTs[token.id] < -!token
		}
		pub  fun  idExists(id: UInt64): Bool {
			return  self.ownedNFTs[id] != nil
		}
		pub  fun  getIDs(): [UInt64] {
			return  self.ownedNFTs.keys
		}
		pub  fun  updateMetadata(id: UInt64, metadata: { String:  String }) {
			self.metadataObjs[id] = metadata
		}
		pub  fun  getMetadata(id: UInt64): { String:  String } {
			return  self.metadataObjs[id]!
		}
		destroy() {
		destroy  self.ownedNFTs
		}
	}
	pub  fun  createEmptyCollection(): @Collection {
		return < - create  Collection()
	}
}
pub  resource  NFTMinter {
	pub  var  idCount: UInt640
	init() {
		self.idCount = 1
	}
	pub  fun  mintNFT(): @NFT {
		var  newNFT < - create NFT(initID: self.idCount)
		self.idCount = self.idCount + 1  as  UInt64
		return < -newNFT
	}
	pub  fun  splitNFT(): @NFT {
		var  newNFT < - create NFT(initID: self.idCount)
		self.idCount = self.idCount + 1  as  UInt64
		return < -newNFT
	}
	init() {
		self.account.save(< -self.createEmptyCollection(), to: /storage/NFTCollection)
		self.account.link <& { NFTReceiver } > (/public/NFTReceiver, target: /storage/NFTCollection)
		self.account.save(< -create  NFTMinter(), to: /storage/NFTMinter)
	}
}
```

Try saving your contracts and deploying here:
https://play.onflow.org/


```
flow project start-emulator

flow project deploy
```

# Mint NFT

## Create transaction

```
mkdir transactions
touch transactions MintTutorial.cdc
```

MintTurorial.cdc

```
import TutorialContract from 0xf8d6e0586b0a20c7

transaction {
  let receiverRef: &{TutorialContract.NFTReceiver}
  let minterRef: &TutorialContract.NFTMinter

  prepare(acct: AuthAccount) {
      self.receiverRef = acct.getCapability<&{TutorialContract.NFTReceiver}>(/public/NFTReceiver).borrow()
          ?? panic("Could not borrow receiver reference")        
      
      self.minterRef = acct.borrow<&TutorialContract.NFTMinter>(from: /storage/NFTMinter)
          ?? panic("could not borrow minter reference")
  }

  execute {
      let metadata : {String : String} = {
          "name": "All I have is my dream (Too funky it hurts)",
          "uri": "ipfs://QmS4RoRMNwTbK2vpLUXqL9dbzSd5qaUoytuM3LGqKGGutB"
      }
      let newNFT <- self.minterRef.mintNFT()
  
      self.receiverRef.deposit(token: <-newNFT, metadata: metadata)

      log("NFT Minted and deposited to Account 2's Collection")
  }
}



```

## Create keys

```
flow keys generate
```

With the output add an accounts object to the flow.js file

```
{
"emulators": {
	"default": {
	"port":  3569,
	"serviceAccount":  "emulator-account"
	}
	},
	"contracts": {
	"TutorialContract":  "./cadence/contracts/Tutorial.cdc"
	},
	"networks": {
		"emulator":  "127.0.0.1:3569",
		"mainnet":  "access.mainnet.nodes.onflow.org:9000",
		"testnet":  "access.devnet.nodes.onflow.org:9000"
	},
	"accounts": {
		"emulator-account": {
			"address":  "0xf8d6e0586b0a20c7",
			"key":  "8ac8e9db88ae254e01fecac26831de137215aee461bab52839198183a87c3ac5"
		}
	},
	"deployments": {
		"emulator": {
			"emulator-account": ["TutorialAccount"]
		}
	}
}
```

## Send minting transaction
```
flow transactions send --code ./transactions/MintPinataParty.cdc --signer emulator-account
```
## Verify the token is in the account and fetch the metadata

```
mkdir scripts
touch CheckTokenMetadata.cdc
```
CheckTokenMetatdat.cdc
```
import TutorialContract from 0xf8d6e0586b0a20c7

pub fun main() : {String : String} {
    let nftOwner = getAccount(0xf8d6e0586b0a20c7)
    // log("NFT Owner")    
    let capability = nftOwner.getCapability<&{PinataPartyContract.NFTReceiver}>(/public/NFTReceiver)

    let receiverRef = capability.borrow()
        ?? panic("Could not borrow the receiver reference")

    return receiverRef.getMetadata(id: 1)
}
```

## Run the script

```
flow scripts execute ./scripts/CheckTokenMetadata.cdc
```

