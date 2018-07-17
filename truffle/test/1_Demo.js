require('truffle-test-utils').init();

var BlockSpaceTokenArtifact = artifacts.require("BlockSpaceToken");
var DexArtifact = artifacts.require("Dex");
var ProtocolGasFuturesArtifact = artifacts.require("ProtocolGasFutures");
var ProtocolGasFuturesTokenArtifact = artifacts.require("ProtocolGasFuturesToken");

var Utils = require('./Utils')(DexArtifact);

contract('In Protocol', function(accounts) {

  let miner = accounts[0];
  let gasFutureId;

  it('should be able to issue a gas future', async () => {

    let web3 = ProtocolGasFuturesArtifact.web3;

    let protocolInstance = await ProtocolGasFuturesArtifact.deployed();
    assert.ok(protocolInstance);
    Utils.log("Protocol deployed at " + protocolInstance.address);

    let bal = await Utils.getBalance(protocolInstance.address);
    let expectedBalance = web3.toWei(5, 'ether');
    if(bal < expectedBalance){
      let ethTx = await Utils.sendTransaction({
        from: accounts[0],
        to: protocolInstance.address,
        value: new web3.BigNumber(expectedBalance).sub(bal)
      });
      assert.ok(ethTx);
    }

    bal = await Utils.getBalance(protocolInstance.address);
    assert.equal(bal,expectedBalance);
    Utils.log("Balance: " + bal);

    let issueTx = await protocolInstance.issue();
    assert.web3Event(issueTx, {
        'event': 'CreatedGasFuture',
        'args': {
            'id': 0
        }
    });

    gasFutureId = issueTx.logs[0].args.id;

    Utils.log("Created gas future (id=" + gasFutureId + ")");

  });

  it('should be able to add gas future to DEX', async() => {

    let token = await ProtocolGasFuturesTokenArtifact.deployed();
    let dex = await DexArtifact.deployed();

    let tokenName = await token.name.call();
    let symbolName = await token.symbol.call();
    let exists = await dex.checkToken.call(tokenName);
    if(!exists){
      Utils.log(tokenName + " doesn't exist in DEX");
      let symbol = await token.symbol.call();
      Utils.log("Adding " + tokenName + " to DEX");
      let addTx = await dex.addNFToken(token.address, tokenName, { from: accounts[0] });
      Utils.log("Adding " + tokenName + " to DEX");
      let id = await token.totalSupply.call();
      Utils.log("id=" + id);
      assert.web3Event(addTx,{
        'event': 'TokenAdded',
        'args': {
          'symbolName': symbolName, 
          'addr': token.address, 
          'idx': id.sub(1).toNumber()
        }
      });
    }

    let depositTx = await dex.depositNFToken(name,gasFutureId, { from: accounts[1] });
    assert.web3Event(depositTx, {
        'event': 'Deposit',
        'args': {
          'symbolName': symbol,
          'user': accounts[1], 
          'value': gasFutureId,
          'balance': 1
        }
    });


  });

});