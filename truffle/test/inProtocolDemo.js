require('truffle-test-utils').init();

var ProtocolGasFuturesArtifact = artifacts.require("ProtocolGasFutures");
var ProtocolGasFuturesTokenArtifact = artifacts.require("ProtocolGasFuturesToken");

var DexArtifact = artifacts.require("Dex");

var Utils = require('./Utils')(DexArtifact);

contract('In Protocol', function(accounts) {

  let web3 = ProtocolGasFuturesArtifact.web3;

  let dexAdmin = accounts[0];
  let miner = accounts[1];
  let taker = accounts[2];
  let gasFutureId;

  it('miner should be able to issue gas future', async () => {

    let protocolInstance = await ProtocolGasFuturesArtifact.deployed();

    Utils.log("Protocol deployed at " + protocolInstance.address);

    // let bal = await Utils.getBalance(protocolInstance.address);
    // let expectedBalance = web3.toWei(5, 'ether');
    // if(bal < expectedBalance){
    //   let ethTx = await Utils.sendTransaction({
    //     from: accounts[0],
    //     to: protocolInstance.address,
    //     value: new web3.BigNumber(expectedBalance).sub(bal)
    //   });
    // }

    let issueTx = await protocolInstance.issue({ from: miner });
    gasFutureId = issueTx.logs[0].args.id;
    
    Utils.log("Created gas future (id=" + gasFutureId + ")");

  });

  it('DEX admin should be able to add token to DEX', async() => {

    let dex = await DexArtifact.deployed();
    let token = await ProtocolGasFuturesTokenArtifact.deployed();

    let tokenName = await token.name.call();
    let exists = await dex.checkToken.call(tokenName);
    if(!exists){
      Utils.log(tokenName + " doesn't exist in DEX");
      Utils.log("Adding " + tokenName + " to DEX");
      let addTx = await dex.addNFToken(token.address, tokenName, { from: dexAdmin });
      let id = await token.totalSupply.call();
    }

  });

  it('miner should be able to deposit token in DEX', async() => {

    let dex = await DexArtifact.deployed();
    let token = await ProtocolGasFuturesTokenArtifact.deployed();
    
    let symbolName = await token.symbol.call();
    let depositTx = await dex.depositNFToken(symbolName, gasFutureId, { from: miner });
    assert.web3Event(depositTx, {
      'event': 'Deposit',
      'args': {
        'symbolName': symbol,
        'user': miner, 
        'value': gasFutureId,
        'balance': 1
      }
    });

  });

  it('should be able gas future to transfer to taker', async () => {

    let transferTx = await token.safeTransferFrom(miner, taker, id, { from: miner });
    let owner = await instance.ownerOf(id);
    if(owner == taker){
      Utils.log("miner " +  miner + " transferred gas future (id=" + gasFutureId + ") to " + taker);
    }

  });

});