pragma solidity >=0.5.11 <0.6.0;

import "./SimpleToken.sol";

contract Bank {
   
    SimpleToken public token;
    constructor(SimpleToken _token) public {
        token = _token;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        return token.transferFrom(_from, _to, _value);
    }
    function transfer(address _to, uint256 _value) public returns (bool) {
        return token.transfer(_to, _value);
    }
    function getTokenName() public returns (string memory) {
        return token.name();
    }
}
