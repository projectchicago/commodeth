pragma solidity ^0.4.10;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

import "./DexLib.sol";

contract Dex {

    using DexLib for DexLib.Dex;
    using DexLib for DexLib.Token;
    using DexLib for DexLib.Batch;
    using DexLib for DexLib.Order;
    using SafeMath for uint;
    
    DexLib.Dex dex;

    event TokenAdded(string symbolName, address addr, uint idx);
    event Deposit(string symbolName, address user, uint value, uint balance);
    event Withdrawal(string symbolName, address user, uint value, uint balance);
    event NewOrder(string tokenA, string tokenB, string orderType, uint volume, uint price);
    
    
    function () public {
        revert();
    }
    
    constructor (address admin, uint lenPeriod) public {
        dex.initDex(admin, lenPeriod);
    }

    function changeAdmin (address admin) public {
        require(msg.sender == dex.admin);
        dex.admin = admin;
    }
    
    function changePeriod (uint lenPeriod) public {
        require(msg.sender == dex.admin);
        dex.lenPeriod = lenPeriod;
        //need to modify to change in the next period!!!
    }

    //check if the token is known
    function checkToken(string token) public view returns (bool) {
        return (dex.tokenIndex[token] != 0 || keccak256(abi.encode(token)) == keccak256("ETH"));
    }
        
    function addToken (address addr, string name) public {
        require(msg.sender == dex.admin);
        require(!checkToken(name));
        dex.tokens[dex.numToken].initToken(addr, name);
        dex.tokenIndex[name] = dex.numToken;
        dex.numToken++;
        
        emit TokenAdded(name, addr, dex.numToken - 1);
    }
    

    function depositEther() public payable {
        dex.balance[msg.sender][0].add(msg.value);
        dex.freeBal[msg.sender][0].add(msg.value);
        emit Deposit("ETH", msg.sender, msg.value, dex.balance[msg.sender][0]);
    }
    
    function withdrawalEther(uint amount) public {
        require(dex.freeBal[msg.sender][0] >= amount);
        dex.freeBal[msg.sender][0].sub(amount);
        dex.balance[msg.sender][0].sub(amount);
        msg.sender.transfer(amount);
        emit Withdrawal("ETH", msg.sender, amount, dex.balance[msg.sender][0]);
    }
    
    function depositToken(string name, uint amount) public {
        require(dex.tokenIndex[name] != 0);
        ERC20 token = ERC20(dex.tokens[dex.tokenIndex[name]].tokenAddr);
        require(token.transferFrom(msg.sender, address(this), amount) == true);
        dex.balance[msg.sender][dex.tokenIndex[name]].add(amount);
        dex.freeBal[msg.sender][dex.tokenIndex[name]].add(amount);
        emit Deposit(dex.tokens[dex.tokenIndex[name]].symbolName, msg.sender, amount, 
            dex.balance[msg.sender][dex.tokenIndex[name]]);
    }
    
    function withdrawalToken(string name, uint amount) public {
        require(dex.tokenIndex[name] != 0);
        require(dex.freeBal[msg.sender][dex.tokenIndex[name]] >= amount);
        ERC20 token = ERC20(dex.tokens[dex.tokenIndex[name]].tokenAddr);
        dex.balance[msg.sender][dex.tokenIndex[name]].sub(amount);
        dex.freeBal[msg.sender][dex.tokenIndex[name]].sub(amount);
        require(token.transfer(msg.sender, amount) == true);
        emit Withdrawal(dex.tokens[dex.tokenIndex[name]].symbolName, msg.sender, amount, 
            dex.balance[msg.sender][dex.tokenIndex[name]]);
    }

    //buy (volume) "tokenTo" with (volume * price) "tokenFrom" [tokenFrom][tokenTo] 
    function bidOrder(string tokenFrom, string tokenTo, uint volume, uint price, 
        bytes32 nonce) public {
        require(checkToken(tokenFrom) && checkToken(tokenTo));

        uint8 idxFrom = dex.tokenIndex[tokenFrom];
        uint8 idxTo = dex.tokenIndex[tokenTo];
        require(idxFrom < idxTo); //different for ask

        require(dex.freeBal[msg.sender][idxFrom] >= volume.mul(price));
        DexLib.Order storage order;
        order.initOrder(msg.sender, volume, price, nonce, block.number);
        DexLib.insertOrder(dex.tokens[idxFrom].batches[idxTo], dex.currentPeriod(block.number), 
            order, DexLib.OrderType.Bid);
        dex.freeBal[msg.sender][idxFrom].sub(volume.mul(price));

        emit NewOrder(tokenFrom, tokenTo, "Bid", price, volume);
    }
    
    //sell (volume) "tokenFrom" for (volume * price) "tokenTo" [tokenTo][tokenFrom]
    function askOrder(string tokenFrom, string tokenTo, uint volume, uint price, 
        bytes32 nonce) public {
        require(checkToken(tokenFrom) && checkToken(tokenTo));

        uint8 idxFrom = dex.tokenIndex[tokenFrom];
        uint8 idxTo = dex.tokenIndex[tokenTo];
        require(idxFrom > idxTo); //different for bid

        require(dex.freeBal[msg.sender][idxFrom] >= volume);
        DexLib.Order storage order;
        order.initOrder(msg.sender, volume, price, nonce, block.number);
        DexLib.insertOrder(dex.tokens[idxTo].batches[idxFrom],dex.currentPeriod(block.number), 
            order, DexLib.OrderType.Ask);
        dex.freeBal[msg.sender][idxFrom].sub(volume);

        emit NewOrder(tokenTo, tokenFrom, "Ask", price, volume);
    }

    //not supporting cancellation yet!!!

    function settle(string tokenA, string tokenB, uint[] sortedBid, uint[] sortedAsk) public {
        require(checkToken(tokenA) && checkToken(tokenB));

        uint8 idxA = dex.tokenIndex[tokenA];
        uint8 idxB = dex.tokenIndex[tokenB];
        require(idxA < idxB);

        dex.settle(sortedBid, sortedAsk, idxA, idxB);
    }
}