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
    - Price of the contract is the price of the future
    - Bond needs to be set in the contract by the miner
  */
  
  struct Derivative {
    uint lower;
    uint upper;
    uint gasLimit;
    address offerer;
  }
  
  event DerivativeCreated(uint indexed id, uint lower, uint upper, uint gasLimit, address offerer);
  
  mapping (uint => Derivative) public derivativeData;
  
  function mint(uint _lower, uint _upper, uint _gasLimit, address _offerer) public returns (uint)  {
    require(_lower < _upper);
    require(_lower > block.number);
    
    uint id = totalSupply();
    derivativeData[id] = Derivative(_lower, _upper, _gasLimit, _offerer);
    
    emit DerivativeCreated(id, _lower, _upper, _gasLimit, _offerer);
    
    _mint(msg.sender, id);
    
    return id;
  }
  
  // Add function to get information
  // function setOfferer() {}
  // function setBond() {}
}