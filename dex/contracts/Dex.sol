pragma solidity ^0.4.10;

import "./FixedSupplyToken.sol";

library SafeMathLib {
    function times(uint a, uint b) public pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function minus(uint a, uint b) public pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function plus(uint a, uint b) public pure returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}

/*library PriorityQueueLib {
    using OrderBookLib for OrderBookLib.Order;
    function compare(OrderBookLib.OrderBook storage self, uint a, uint b) 
        private returns (bool) {
        return self.orders[a].price > self.orders[b].price;
        //randomness not added when there is a tie in price!!!
    }
    
    function swap(OrderBookLib.OrderBook storage self, uint a, uint b) public {
        uint c = self.idx[a];
        self.idx[a] = self.idx[b];
        self.idx[b] = c;
    }
    
    function clear(OrderBookLib.OrderBook storage self) public {
        for (uint i = 0; i < self.numOrder; i++) {
            self.idx[i] = i;
            self.orders[i].init();
        }
    }
    
    function push(OrderBookLib.OrderBook storage self, 
        OrderBookLib.Order storage newOrder) public {
        self.orders[self.numOrder] = newOrder;
        for (uint i = self.numOrder; i > 0 && compare(self, i, (i - 1) / 2);) {
            swap(self, i, (i - 1) / 2);
            i = (i - 1) / 2;
        }
        self.numOrder++;
    }
    
    function pop(OrderBookLib.OrderBook storage self) 
        public returns (OrderBookLib.Order storage) {
        OrderBookLib.Order storage ret = self.orders[0];
        self.orders[0].init();
        
        for (uint i = 0; i < self.numOrder;) {
            if (compare(self, i, i * 2 + 1)) {
                if (compare(self, i, i * 2 + 2)) {
                    break;
                } else {
                    swap(self, i, i * 2 + 2);
                    i = i * 2 + 2;
                }
            } else {
                if (compare(self, i * 2 + 1, i * 2 + 2)) {
                    swap(self, i, i * 2 + 1);
                    i = i * 2 + 1;
                } else {
                    swap(self, i, i * 2 + 2);
                    i = i * 2 + 2;
                }
            }
        }
        
        self.numOrder--;
        return ret;
    }
}

library OrderBookLib {
    uint constant MAXORDER = 2**20;

    struct Order {
        uint volume;
        uint price;
        address trader;
    }
    
    function init(Order storage self) public {
        self.volume = 0;
        self.price = 0;
    }
    
    struct OrderBook {
        uint numOrder;
        uint[MAXORDER] idx;
        Order[MAXORDER] orders;
    }
    
    using PriorityQueueLib for OrderBook;
}
*/

library DexLib {
    using SafeMathLib for uint;
    uint constant MAXORDER = 2**20;
    uint constant MAXTOKEN = 2**8;
    uint constant MAXBATCH = 2**8;

    enum OrderType {Bid, Ask}
    
    //order fee not implemented!!!
    
    struct Order {
        uint volume;
        uint price;
        address trader;
        bytes32 nonce;
        uint timestamp;
    }
    
    struct OrderBook {
        uint numOrder;
        Order[MAXORDER] orders;
    }
    
    struct Batch {
        uint batchHead; //the actual head - 1
        uint batchTail; //the actual tail
        uint[MAXBATCH] timestamp;
        OrderBook[MAXBATCH] bidBook;
        OrderBook[MAXBATCH] askBook;
    }
    
    struct Token {
        string symbolName;
        address tokenAddr;
        Batch[MAXTOKEN] batches;
    }
    
    struct Dex {
        uint8 numToken;
        Token[MAXTOKEN] tokens;
        mapping (string => uint8) tokenIndex;
    
        mapping (address => mapping (uint8 => uint)) balance;
        mapping (address => mapping (uint8 => uint)) freeBal;

        address admin;
        uint lenPeriod;
        uint staPeriod;
    }

    function initOrder(Order storage self, address trader, uint volume, uint price, 
        bytes32 nonce, uint timestamp) internal {
        self.trader = trader;
        self.volume = volume;
        self.price = price;
        self.nonce = nonce;
        self.timestamp = timestamp;
    }

    function copyOrder(Order storage self, Order storage origin) internal{
        initOrder(self, origin.trader, origin.volume, origin.price, origin.nonce, origin.timestamp);
    }
    
    function initBatch(Batch storage self) internal {
        self.batchHead = 0;
        self.batchTail = 0;
    }

    function initToken(Token storage self, address addr, string name, uint numToken) internal {
        self.symbolName = name;
        self.tokenAddr = addr;

        for (uint i = 0; i < numToken; i++) {
            initBatch(self.batches[i]);
        }
    }
    
    function initDex (Dex storage self, address admin_, uint lenPeriod) internal {
        self.admin = admin_;
        self.lenPeriod = lenPeriod;
        self.staPeriod = block.number;
        
        initToken(self.tokens[self.numToken], 0, "ETH", self.numToken);
        self.tokenIndex["ETH"] = self.numToken;
        self.numToken = 1;
    }

    function updateBatchIndex(uint idx) public pure returns (uint) {
        if (idx == MAXBATCH - 1) {
            return 0;
        } else {
            return idx + 1;
        }
    }

    function currentPeriod(Dex storage self, uint cur) public view returns (uint) {
        return ((cur - self.staPeriod) / self.lenPeriod) * self.lenPeriod + self.staPeriod;
    }

/*    function updatePeriod(Dex storage self) public {
        //Handle who is responsible for gas cost in this function!!!
        if (self.curPeriod + self.lenPeriod <= block.number) {
            self.curPeriod += self.lenPeriod;

            for (uint i = 0; i < self.numToken; i++) {
                for (uint j = 0; j < i; j++) {
                    self.tokens[i].batches[j].batchTail = updateBatchIndex(
                        self.tokens[i].batches[j].batchTail);
                    self.tokens[i].batches[j].timeTail += self.lenPeriod;
                    self.tokens[i].batches[j].bidBook[self.tokens[i].batches[j].batchTail].numOrder = 0;
                    self.tokens[i].batches[j].askBook[self.tokens[i].batches[j].batchTail].numOrder = 0;
                }
            }
         }
    }
*/
    function insertOrder(Batch storage self, uint timestamp, Order storage order, 
        OrderType t) internal {
        if (self.batchHead == self.batchTail || self.timestamp[self.batchTail] < timestamp) {
            self.batchTail = updateBatchIndex(self.batchTail);
            self.timestamp[self.batchTail] = timestamp;
            self.bidBook[self.batchTail].numOrder = 0;
            self.askBook[self.batchTail].numOrder = 0;
        }
        if (t == OrderType.Bid) {
            copyOrder(self.bidBook[self.batchTail].orders[self.bidBook[self.batchTail].numOrder], 
                order);
            self.bidBook[self.batchTail].numOrder++;
        } else {
            copyOrder(self.askBook[self.batchTail].orders[self.askBook[self.batchTail].numOrder], 
                order);
            self.askBook[self.batchTail].numOrder++;
        }
    }

    //check whether priceA < priceB
    function compareOrder(Order storage orderA, Order storage orderB) 
        public view returns(bool) {
            return (orderA.price < orderB.price || 
                (orderA.price == orderB.price && orderA.nonce < orderB.nonce));
    }

    //bids price in descending order, asks price in ascending order
    function checkSortedBook(OrderBook storage self, uint[] sortedOrder, OrderType t)
        public view returns(bool) {
            if (self.numOrder != sortedOrder.length) return false;
            for (uint i = 1; i < sortedOrder.length; i++) {
                if (sortedOrder[i] == sortedOrder[i - 1]) return false;
                if (t == OrderType.Bid) {
                    if (compareOrder(self.orders[sortedOrder[i - 1]], 
                        self.orders[sortedOrder[i]])) return false;
                } else {
                    if (compareOrder(self.orders[sortedOrder[i]],
                        self.orders[sortedOrder[i - 1]])) return false;
                }
            }
            return true;
    }

    function checkSorting(Batch storage self, uint[] sortedBid, uint[] sortedAsk) 
        public view returns(bool) {
            uint next = updateBatchIndex(self.batchHead);
            return (checkSortedBook(self.bidBook[next], sortedBid, OrderType.Bid)
                && checkSortedBook(self.askBook[next], sortedAsk, OrderType.Ask));
    }

    function min(uint a, uint b) public pure returns(uint) {
        if (a < b) return a; else return b;
    }

    function firstPriceAuction(Dex storage dex, uint[] sortedBid, uint[] sortedAsk, 
        uint8 tokenA, uint8 tokenB) internal {
        Batch storage self = dex.tokens[tokenA].batches[tokenB];
        uint curPeriod = currentPeriod(dex, block.number);
        uint cur = updateBatchIndex(self.batchHead);
        uint i = 0;
        uint j = 0;
        Order storage orderBid;
        if (i < sortedBid.length) orderBid = self.bidBook[cur].orders[sortedBid[i]];
        Order storage orderAsk;
        if (j < sortedAsk.length) orderAsk = self.askBook[cur].orders[sortedAsk[j]];

        for (; i < sortedBid.length && j < sortedAsk.length;) {
            if (orderBid.price >= orderAsk.price) {
                //how to set the settlement price when bid and ask prices are not equal???
                uint price = (orderBid.price + orderAsk.price) / 2;
                uint volume = min(orderBid.volume, orderAsk.volume);

                //buy (volume) "tokenTo" with (volume * price) "tokenFrom" [tokenFrom][tokenTo] 
                dex.balance[orderBid.trader][tokenA].minus(volume * price);
                dex.balance[orderBid.trader][tokenB].plus(volume);
                dex.freeBal[orderBid.trader][tokenB].plus(volume);
                orderBid.volume -= volume;
                if (orderBid.volume == 0) {
                    i++;
                    if (i < sortedBid.length) orderBid = self.bidBook[cur].orders[sortedBid[i]];
                }

                //sell (volume) "tokenFrom" for (volume * price) "tokenTo" [tokenTo][tokenFrom]
                dex.balance[orderAsk.trader][tokenA].plus(volume * price);
                dex.freeBal[orderAsk.trader][tokenA].plus(volume * price);
                dex.balance[orderAsk.trader][tokenB].minus(volume);
                orderAsk.volume -= volume;
                if (orderAsk.volume == 0) {
                    j++;
                    if (j < sortedAsk.length) orderAsk = self.askBook[cur].orders[sortedAsk[j]];
                }
            } else {
                break;
            }
        }

        if (i < sortedBid.length || j < sortedAsk.length) {
            if (cur == self.batchTail) {
                self.batchTail = updateBatchIndex(self.batchTail);
                self.timestamp[self.batchTail] = curPeriod;
                self.bidBook[self.batchTail].numOrder = 0;
                self.askBook[self.batchTail].numOrder = 0;
            }
            uint next = updateBatchIndex(cur);
            for (; i < sortedBid.length; i++) {
                orderBid = self.bidBook[cur].orders[sortedBid[i]];
                copyOrder(self.bidBook[next].orders[self.bidBook[next].numOrder], orderBid);
                self.bidBook[next].numOrder++;
            }
            for (; j < sortedAsk.length; j++) {
                orderAsk = self.askBook[cur].orders[sortedAsk[i]];
                copyOrder(self.askBook[next].orders[self.askBook[next].numOrder], orderAsk);
                self.askBook[next].numOrder++;
            }

        }
        self.batchHead = cur;
    }    

    function settle(Dex storage dex, uint[] sortedBid, uint[] sortedAsk, 
        uint8 tokenA, uint8 tokenB) internal {
        Batch storage self = dex.tokens[tokenA].batches[tokenB];
        require(self.batchHead != self.batchTail);
        require(self.timestamp[updateBatchIndex(self.batchHead)] + dex.lenPeriod <= block.number);

        require(checkSorting(self, sortedBid, sortedAsk));
        firstPriceAuction(dex, sortedBid, sortedAsk, tokenA, tokenB);
    }
    
}

contract Dex {
    using DexLib for DexLib.Dex;
    using DexLib for DexLib.Token;
    using DexLib for DexLib.Batch;
    using DexLib for DexLib.Order;
    using SafeMathLib for uint;
    
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
        dex.tokens[dex.numToken].initToken(addr, name, dex.numToken);
        dex.tokenIndex[name] = dex.numToken;
        dex.numToken++;
        
        emit TokenAdded(name, addr, dex.numToken - 1);
    }
    

    function depositEther() public payable {
        dex.balance[msg.sender][0].plus(msg.value);
        dex.freeBal[msg.sender][0].plus(msg.value);
        emit Deposit("ETH", msg.sender, msg.value, dex.balance[msg.sender][0]);
    }
    
    function withdrawalEther(uint amount) public {
        require(dex.freeBal[msg.sender][0] >= amount);
        dex.freeBal[msg.sender][0].minus(amount);
        dex.balance[msg.sender][0].minus(amount);
        msg.sender.transfer(amount);
        emit Withdrawal("ETH", msg.sender, amount, dex.balance[msg.sender][0]);
    }
    
    function depositToken(string name, uint amount) public {
        require(dex.tokenIndex[name] != 0);
        ERC20Interface token= ERC20Interface(dex.tokens[dex.tokenIndex[name]].tokenAddr);
        require(token.transferFrom(msg.sender, address(this), amount) == true);
        dex.balance[msg.sender][dex.tokenIndex[name]].plus(amount);
        dex.freeBal[msg.sender][dex.tokenIndex[name]].plus(amount);
        emit Deposit(dex.tokens[dex.tokenIndex[name]].symbolName, msg.sender, amount, 
            dex.balance[msg.sender][dex.tokenIndex[name]]);
    }
    
    function withdrawalToken(string name, uint amount) public {
        require(dex.tokenIndex[name] != 0);
        require(dex.freeBal[msg.sender][dex.tokenIndex[name]] >= amount);
        ERC20Interface token = ERC20Interface(dex.tokens[dex.tokenIndex[name]].tokenAddr);
        dex.balance[msg.sender][dex.tokenIndex[name]].minus(amount);
        dex.freeBal[msg.sender][dex.tokenIndex[name]].minus(amount);
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

        require(dex.freeBal[msg.sender][idxFrom] >= volume.times(price));
        DexLib.Order storage order;
        order.initOrder(msg.sender, volume, price, nonce, block.number);
        DexLib.insertOrder(dex.tokens[idxFrom].batches[idxTo], dex.currentPeriod(block.number), 
            order, DexLib.OrderType.Bid);
        dex.freeBal[msg.sender][idxFrom].minus(volume.times(price));

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
        dex.freeBal[msg.sender][idxFrom].minus(volume);

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