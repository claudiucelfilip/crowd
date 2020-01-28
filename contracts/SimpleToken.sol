pragma solidity >=0.5.11 <0.6.0;

contract SimpleToken {
    string public name = "SimpleToken";
    string public symbol = "STK";
    string public standard = "SimpleToken v1.0";

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply;
    address public owner;

    constructor(uint256 _supply, address _owner) public {
        owner = _owner;
        balanceOf[owner] = _supply;
        totalSupply = _supply;
    }

    function mint(address _to, uint256 _value) public {
        balanceOf[_to] += _value;
        totalSupply += _value;
    }

    function withdraw(address payable _to, uint256 _value) public {
        require(balanceOf[_to] >= _value, "Withdrawer doesn't have enough tokens for withdraw");
        _to.call.value(_value)("");
        balanceOf[_to] -= _value;
        totalSupply -= _value;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Sender doesn't have enough tokens for transfer");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Sender doesn't have enough tokens for approval");
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        // require(allowance[_from][msg.sender] >= _value, "Transferer doesn't have enought allowance to send");
        require(balanceOf[_from] >= _value, "Source doesn't have enought tokens to send");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        // allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }
}
