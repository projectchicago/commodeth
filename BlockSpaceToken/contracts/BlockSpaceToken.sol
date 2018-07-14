pragma solidity ^0.4.23;

//import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";

contract BlockSpaceToken is ERC721Token {
    
    using SafeMath for uint;
    
    /* 
        Both issuers and buyers can trade these contracts
        - Should both gas users and miners be issuers?
        - Price of the contract is the price of the future
        - Bond needs to be set in the contract by the miner
    */
    
    struct Derivative {
        uint lower;
        uint upper;
        uint gasLimit;
        address offerer;
        address taker;
        uint bond;
        bool settled;
        bool taken; 
    }
    
    event DerivativeCreated(uint indexed id, uint lower, uint upper, uint gasLimit, address indexed offerer);
    event DerivativeTaken(uint indexed id, address indexed offerer, address indexed taker, uint bond);
    // FIXME
    // event DerivativeSettled(uint indexed id, address indexed maker, address indexed taker, uint makerAmount, uint takerAmount, uint triggerPrice, uint actualPrice, uint triggerHeight, uint jackpot);
    event DerivativeCanceled(uint indexed id, address indexed offerer, uint gasLimit, uint bond);
    // FIXME
    // event DerivativeError(uint indexed id, address indexed maker, address indexed taker, uint makerAmount, uint takerAmount, uint triggerPrice, uint triggerHeight, int tcRequestId);
        
    mapping (uint => Derivative) public derivativeData;
    
    constructor() ERC721Token("BlockSpaceToken","SPACE") public { }

    function mint(uint _lower, uint _upper, uint _gasLimit, address _offerer) external payable returns (uint)  {
    
        require(_lower < _upper);
        require(_lower > block.number);
        
        uint id = totalSupply();
        derivativeData[id] = Derivative(_lower, _upper, _gasLimit, _offerer, 0x0, 0, false, false);
        
        emit DerivativeCreated(id, _lower, _upper, _gasLimit, _offerer);
        
        _mint(msg.sender, id);
        
        return id;
    }
    
    function take(uint id) public payable {
        require(id < totalSupply());
        Derivative storage d = derivativeData[id];
        require(!d.taken);
        require(!d.settled);
        d.bond = msg.value;
        d.taken = true;
        d.taker = msg.sender;
        emit DerivativeTaken(id, d.offerer, d.taker, d.bond);
    }
    
    /*function settle(uint id) public {
        // anyone can call this for now; make it an option? 
        // restrict only to taker and/or maker to be settled?
        require(id < totalSupply());
        Derivative storage d = derivativeData[id];
        require(block.number >= d.lower && block.number <= d.upper);
        require(d.taken);
        require(!d.settled);
        d.settled = true;
        // Check whether triggerPrice is greater than current price
        // If so, pay maker full value; else pay taker full value
        bytes32[] memory requestData = new bytes32[](0);
        uint8 requestType = 2;
        int64 tcRequestId = int64(tcContract.request.value(TC_FEE)(requestType, this, TC_CALLBACK_FID, 0, requestData));
         // TODO - Think about handling various requestId values differently
         //   If requestId > 0, then this is the Id uniquely assigned to this request. 
         //   If requestId = -2^250, then the request fails because the requester didn't send enough fee to the TC Contract. 
         //   If requestId = 0, then the TC service is suspended due to some internal reason. No more requests or cancellations can be made but previous requests will still be responded to by TC. 
         //   If requestId < 0 && requestId != -2^250, then the TC Contract is upgraded and requests should be sent to the new address -requestId.
        
        if (tcRequestId < 1) { // Error occured from TownCrier
                d.maker.transfer(d.makerAmount);
                d.taker.transfer(d.takerAmount.sub(TC_FEE));
                emit DerivativeError(id, d.maker, d.taker, d.makerAmount, d.takerAmount, d.triggerPrice, d.triggerHeight, tcRequestId);
                return;
        }
        
        tcIdToBTCFeeID[uint256(tcRequestId)] = (id + 1); // prevent id from ever being 0 (mapping lookup)
        emit TCRequestStatus(tcRequestId);
    }
    */

    function cancel(uint id) public {
        require(id < totalSupply());
        Derivative storage d = derivativeData[id];
        require(msg.sender == d.offerer);
        require(!d.taken);
        require(!d.settled);
        d.settled = true;
        d.offerer.transfer(d.gasLimit);
        emit DerivativeCanceled(id, d.offerer, d.gasLimit, d.bond);
    }

}