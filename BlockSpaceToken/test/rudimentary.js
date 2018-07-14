require('truffle-test-utils').init();

var BlockSpaceTokenArtifact = artifacts.require("BlockSpaceToken");

contract('BlockSpaceToken', function(accounts) {

    it("should have a name and ticker that are proper", async () => {
        let instance = await BlockSpaceTokenArtifact.deployed();
        let retName = await instance.name();
        assert.equal(retName, "BlockSpaceToken", "Name on contract does not match expected value");
        let retSymbol = await instance.symbol();
        assert.equal(retSymbol, "SPACE", "Symbol on contract does not match expected value");
    });

    it("should properly mint a token and fire an event", async () => {
        let instance = await BlockSpaceTokenArtifact.deployed();
        let bn = web3.eth.blockNumber;
        let mintedTransaction = await instance.mint(bn+2,bn+4,100,accounts[1], { from: accounts[0] }) ;
        let supply = await instance.totalSupply();
        assert.equal(supply.toString(), "1", "Minting should increase supply...");
        assert.web3Event(mintedTransaction, {
            'event': 'DerivativeCreated',
            'args': {
                'id': 0,
                'lower': bn+2,
                'upper':bn+4,
                'gasLimit': 100,
                'offerer': accounts[1]
            }
        });
    });

    it("should properly allow someone to take tokens", async () => {
        let instance = await BlockSpaceTokenArtifact.deployed();
        let bn = web3.eth.blockNumber;
        let mintedTransaction = await instance.mint(bn+2,bn+4,100,accounts[1], { "from": accounts[0] }) ;
        assert.web3Event(mintedTransaction, {
            'event': 'DerivativeCreated',
            'args': {
                'id': 1,
                'lower': bn+2,
                'upper': bn+4,
                'gasLimit': 100,
                'offerer': accounts[1]
            }
        });
        
        let takenTransaction = await instance.take(new web3.BigNumber("1"), { "from": accounts[2], "value": new web3.BigNumber("20000000000000000") } );
        assert.web3Event(takenTransaction, {
            'event': 'DerivativeTaken',
            'args': {
                'id': 1,
                'offerer': accounts[1],
                'taker': accounts[2],
                'bond' : 20000000000000000
            }
        });
    });

    it("should let someone cancel their own token mint", async () => {
        let instance = await BlockSpaceTokenArtifact.deployed();
        let bn = web3.eth.blockNumber;
        let mintedTransaction = await instance.mint(bn+2,bn+4,100,accounts[1], { "from": accounts[1] }) ;
        assert.web3Event(mintedTransaction, {
            'event': 'DerivativeCreated',
            'args': {
                'id': 2,
                'lower': bn+2,
                'upper': bn+4,
                'gasLimit': 100,
                'offerer': accounts[1]
            }
        });
        let canceledTransaction = await instance.cancel(new web3.BigNumber("2"), { "from":accounts[1] } );
        assert.web3Event(canceledTransaction, {
            'event': 'DerivativeCanceled',
            'args': {
                'id': 2,
                'offerer': accounts[1],
                'gasLimit': 100,
                'bond': 0
            }
        });
    });

});
