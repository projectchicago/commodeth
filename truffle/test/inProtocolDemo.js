require('truffle-test-utils').init();

var ProtocolGasFuturesArtifact = artifacts.require("ProtocolGasFutures");
var ProtocolGasFuturesTokenArtifact = artifacts.require("ProtocolGasFuturesToken");

var DexArtifact = artifacts.require("Dex");

var Utils = require('./Utils')(DexArtifact);

contract('In Protocol', function(accounts) {

  let web3 = ProtocolGasFuturesArtifact.web3;

  let dexAdmin = accounts[0];
  let miner = accounts[1];
  let bidder1 = accounts[2];
  let bidder2 = accounts[3];
  let bidder3 = accounts[4];
  let gasFutureId;

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

  it('miner should be able to issue gas future', async () => {

    let dex = await DexArtifact.deployed();
    let protocolInstance = await ProtocolGasFuturesArtifact.deployed();
    let token = await ProtocolGasFuturesTokenArtifact.deployed();

    Utils.log("Protocol deployed at " + protocolInstance.address);

    let tokenName = await token.name.call();
    let issueTx = await protocolInstance.issue(dex.address, { from: miner });
    assert(issueTx.logs.length > 0);
    gasFutureId = issueTx.logs[0].args.id;
    assert.web3Event(issueTx, {
      'event': 'CreatedGasFuture',
      'args': {
        'id': gasFutureId.toNumber()
      }
    });

    let owner = await token.ownerOf.call(gasFutureId);
    Utils.log(owner);
    
    Utils.log("Created gas future (id=" + gasFutureId + ")");

  });

  it('bidder should be able to submit bids', async () => {

    let dex = await DexArtifact.deployed();
    let token = await ProtocolGasFuturesTokenArtifact.deployed();
    let tokenName = await token.name.call();
    
    let fiveETH = Number(web3.toWei(5,'ether'));
    let deposit1 = await dex.depositEther({ from: bidder1, value: fiveETH });
    assert.web3Event(deposit1, {
      'event': 'Deposit',
      'args': {
        'symbolName': 'ETH', 
        'user': bidder1,
        'value': fiveETH,
        'balance': fiveETH
      }
    });
    let bid1 = await dex.bidOrderERC721(tokenName, 'ETH', gasFutureId, 10, 0x0, { from: bidder1 });
    assert.web3Event(bid1, {
      'event': 'NewOrder',
      'args': {
        'tokenA': tokenName, 
        'tokenB': 'ETH', 
        'orderType': 'Bid', 
        'volume': gasFutureId.toNumber(),
        'price': 10
      }
    });

    let deposit2 = await dex.depositEther({ from: bidder2, value: fiveETH });
    assert.web3Event(deposit2, {
      'event': 'Deposit',
      'args': {
        'symbolName': 'ETH', 
        'user': bidder2,
        'value': fiveETH,
        'balance': fiveETH
      }
    });
    let bid2 = await dex.bidOrderERC721(tokenName, 'ETH', gasFutureId, 20, 0x1, { from: bidder2 });
    assert.web3Event(bid2, {
      'event': 'NewOrder',
      'args': {
        'tokenA': tokenName, 
        'tokenB': 'ETH', 
        'orderType': 'Bid', 
        'volume': gasFutureId.toNumber(),
        'price': 20
      }
    });

    let deposit3 = await dex.depositEther({ from: bidder3, value: fiveETH });
    assert.web3Event(deposit3, {
      'event': 'Deposit',
      'args': {
        'symbolName': 'ETH', 
        'user': bidder3,
        'value': fiveETH,
        'balance': fiveETH
      }
    });
    let bid3 = await dex.bidOrderERC721(tokenName, 'ETH', gasFutureId, 30, 0x2, { from: bidder3 });
    assert.web3Event(bid3, {
      'event': 'NewOrder',
      'args': {
        'tokenA': tokenName, 
        'tokenB': 'ETH', 
        'orderType': 'Bid', 
        'volume': gasFutureId.toNumber(),
        'price': 30
      }
    });


  });

  it('dex should run auction', async () => {

    let protocolInstance = await ProtocolGasFuturesArtifact.deployed();
    let dex = await DexArtifact.deployed();
    let token = await ProtocolGasFuturesTokenArtifact.deployed();
    let tokenName = await token.name.call();

    let auctionTx = await protocolInstance.runAuction(gasFutureId, { from: miner });

  });

});