//ethers js 
import {ethers} from "../lib/ethers-5.6.esm.min.js"
//abi 
import * as ABI from "../solidity/abi.js"
let provider = null, signer = null;

//id,name, rpc
const NETDATA = {
  5 : [5,"gETH",""],
  9001 : [9001,"EVMOS",""],
}

if(window.ethereum) {
  // A Web3Provider wraps a standard Web3 provider, which is what Metamask injects as window.ethereum into each page
  provider = new ethers.providers.Web3Provider(window.ethereum, "any");
  let {chainId} = await provider.getNetwork()
  
  provider.on("network", (newNetwork, oldNetwork) => {
        // When a Provider makes its initial connection, it emits a "network" event with a null oldNetwork along with the newNetwork. 
        // So, if the oldNetwork exists, it represents a changing network
        if (oldNetwork) {
            window.location.reload();
        }
  });
}
else {
  provider =  ethers.getDefaultProvider()
}

//export {ERC721Buyer, ERC721FullNoBurn, ERC721CommitReveal, Stats, ShardCosmicClaim}

const CONTRACTS = {
  5 : {
    "Shard" : "0xA9e186666C3f87eB3368659710FaD22228A64ceC",
    "ShardGen" : "0x8e2C6266942a54f8ECbD295080F89922Ab810289",
  },
  9001 : {
    "Shard" : "0x39075B9DB05C0E1Bb12a05341424BA2031d8Ce67",
    "ShardGen" : "0x039c0AAabB8Ee98DAf26ab12A82780dE1054276D",
  },
}
const READONLY = []

//load the contracts given a network name 
const loadContracts = (netId) => {
  if(!CONTRACTS[netId]) return null 

  let c = {};
  for(let x in CONTRACTS[netId]){
    let [id,name] = x.split(".")
    name = name || id
    
    if(ABI[id]) {
      c[name] = new ethers.Contract(CONTRACTS[netId][x], ABI[id], signer)
    }
  }

  return c
}

const pullShards = async (app,address,n) => {
  let c = app.contracts.Shard 
  let g = app.contracts.ShardGen
  //pull existing shards 
  let shards = app.UI.main.state.shards 

  //pull svg data from chain 
  const getSVG = async (id) => {
    id = id.toNumber()
    //don't pull if it exists 
    if(shards[id]) return

    let seed = await c.seed(id)
    //decode 
    let d = (await g.propertiesString(seed)).split(",")
    //save
    shards[id] = {id,seed,d}

    //set ui state 
    app.UI.main.setState({shards})
  }

  for(let i = 0; i < n; i++){
    getSVG(await c.tokenOfOwnerByIndex(address,i))
  }
}

const init = (app) => {
  //establish eth utilities 
  app.eth = {
    parseEther : ethers.utils.parseEther,
    parseUnits : ethers.utils.parseUnits,
    decode (types,data) {
      return data == "0x" ? [null] : ethers.utils.defaultAbiCoder.decode(types, data)
    }
  }

  app.eth.connect = async () => {
    // Prompt user for account connections
    await provider.send("eth_requestAccounts", []);

    // The Metamask plugin also allows signing transactions to
    // send ether and pay to change state within the blockchain.
    // For this, you need the account signer...
    signer = provider.getSigner();
    console.log("Account:", await signer.getAddress());
  }

  //poll for changes 
  setInterval(async ()=>{
    let {address} = app.UI.main.state

    //poll for address change 
    let newAddress = signer ? await signer.getAddress() : null
    if(address != newAddress) {
      app.UI.main.setState({address:newAddress,shards:{}})
      
      //chain
      let {chainId} = await provider.getNetwork()
      app.chainId = chainId
      //load contracts again 
      app.contracts = loadContracts(chainId)
    }

    //block 
    app.block = await provider.getBlockNumber()
    //get balance 
    let balance = signer ? Number(ethers.utils.formatUnits(await signer.getBalance())) : 0 
    app.UI.main.setState({balance})

    //check if the chain exists
    if(CONTRACTS[app.chainId]){
      let {address} = app.UI.main.state
      let _shard = app.contracts.Shard 
      let cost = Number(ethers.utils.formatUnits(await _shard.COST()))
      let totalSupply = Number((await _shard.totalSupply()).toNumber())
      let balanceOf = address != "" ? Number((await _shard.balanceOf(address)).toNumber()) : 0

      if(balanceOf > 0) {
        pullShards(app,address,balanceOf)
      }
      else {
        app.UI.main.setState({shards:{}})
      }
      
      //update UI 
      app.UI.main.setState({cost,totalSupply,balanceOf})
    }

  },4000)
}

export {init}
