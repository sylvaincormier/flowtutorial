
import TutorialContract from 0xf8d6e0586b0a20c7

transaction {
  let receiverRef: &{TutorialContract.NFTReceiver}
  let minterRef: &TutorialContract.NFTMinter

  prepare(acct: AuthAccount) {
      self.receiverRef = acct.getCapability<&{PinataPartyContract.NFTReceiver}>(/public/NFTReceiver)
          .borrow()
          ?? panic("Could not borrow receiver reference")        
      
      self.minterRef = acct.borrow<&PinataPartyContract.NFTMinter>(from: /storage/NFTMinter)
          ?? panic("could not borrow minter reference")
  }

  execute {
      let metadata : {String : String} = {
          "name": "The Big Swing",
          "swing_velocity": "29", 
          "swing_angle": "45", 
          "rating": "5",
          "uri": "ipfs://QmS4RoRMNwTbK2vpLUXqL9dbzSd5qaUoytuM3LGqKGGutB"
      }
      let newNFT <- self.minterRef.mintNFT()
  
      self.receiverRef.deposit(token: <-newNFT, metadata: metadata)

      log("NFT Minted and deposited to Account 2's Collection")
  }
}