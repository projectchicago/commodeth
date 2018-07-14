pragma solidity ^0.4.17;

//import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";

contract BlockSpaceToken is ERC721Token {
  string public constant name = "BlockSpaceToken";
  string public constant symbol = "SPACE";
  
  using SafeMath for uint;
  
  /* 
    Both issuers and buyers can trade these contracts
    - Should both gas users and miners be issuers?
     -> Anyone can be an issuer, it's okay to have NFTs floating around who don't have offerers and takers
     -> Though the current implimentation, whoever creates the NFT is the owner -> taker?
     -> If a taker creates the contract, then they have to transfer money to the offerer...
      -> how to do this safely and atomically... Might be best just to have the miner be the issuer
     -> UX could be like a taker goes to an miner and gives them parameters and asks them to be an issuer...
    - Price of the contract is the price of the future
    - Bond needs to be set in the contract by the miner
  */
  
  struct Derivative {
    uint lower;
    uint upper;
    uint gasLimit;
    address offerer; // AKA Miner
    uint bond; // Have to note the value here, need to track state for refunding
  }
  
  event DerivativeCreated(uint indexed id, uint lower, uint upper, uint gasLimit, address offerer);
  
  mapping (uint => Derivative) public derivativeData;
  
  // If a miner where to issue this, then they would set themselves as the offerer
  // If random person created this they would have to find a miner to fill it + fulfill
  function mint(uint _lower, uint _upper, uint _gasLimit, address _offerer) public returns (uint)  {
    require(_lower < _upper);
    require(_lower > block.number);
    
    uint id = totalSupply();
    derivativeData[id] = Derivative(_lower, _upper, _gasLimit, _offerer, 0);
    
    emit DerivativeCreated(id, _lower, _upper, _gasLimit, _offerer);
    
    _mint(msg.sender, id);
    
    return id;
  }

  // Note bond can only be increased, not decreased in current implimentation
  function setBond(uint _id) public payable {
  	derivativeData[_id].bond += msg.value;
  }

  // Only msg.sender should be able to set themselves as the offerer
  // Needs to be some level of access controls here, where the previous
  function setOfferer(uint _id) public {
  	require(derivativeData[_id].offerer != address(0)
  	derivativeData[_id].offerer += msg.sender;	
  }
  
  // Add function to get information
  // function setOfferer() {}
  // function cancel() {}
  // function settle() {}
}