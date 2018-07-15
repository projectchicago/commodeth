require('truffle-test-utils').init();

var DexArtifact = artifacts.require("Dex");

async function mineBlock(){
    await BlockSpaceTokenArtifact.web3.currentProvider.send({
        jsonrpc: '2.0',
        method: 'evm_mine',
        params: [],
        id: 0
    });
}

function getBalance(address){
    return new Promise((resolve, reject) => {
        BlockSpaceTokenArtifact.web3.eth.getBalance(address, function(err,balance){
            if(err){
                reject(err);
            }else{
                resolve(balance);
            }
        });
    });
}

contract('Dex', function(accounts) {



});