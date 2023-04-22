/**
 *Submitted for verification at Arbiscan on 2023-04-21
*/

// SPDX-License-Identifier: MIT

/*
MAIN CONTRACT
Funzioni:
-TokenFactory
-Deploy Token con nome, simbolo e supply a scelta
-Burn
-Renounce ownership 
-Tax (in development) -> 

*/

pragma solidity ^0.4.24;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

}


contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StandardToken is ERC20, Ownable {
    using SafeMath for uint256;

    address public DevWallet = 0xB86e2e66eBE96816C54a593f898959C6B0D31178;
    uint256 public taxRate = 1; // 1% tax rate
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => uint256) balances;
    mapping(address => bool) public excludedFromTax;


    function setTaxWallet(address _newTaxWallet) public onlyOwner {

        require(_newTaxWallet != address(0), "Invalid address");
        DevWallet = _newTaxWallet;
    }

    function setTaxRate(uint256 _newTaxRate) public onlyOwner {

        require(_newTaxRate >= 0, "Invalid tax rate");
        taxRate = _newTaxRate;
    }

    function setExcludedFromTax(address _account, bool _excluded) public onlyOwner {
    excludedFromTax[_account] = _excluded;
    }

    
    function transfer(address _to, uint256 _value) public returns (bool) {

        uint256 taxAmount = _value.mul(taxRate).div(100);
        uint256 netAmount = _value.sub(taxAmount);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(netAmount);
        balances[DevWallet] = balances[DevWallet].add(taxAmount);
        
        emit Transfer(msg.sender, _to, netAmount);
        emit Transfer(msg.sender, DevWallet, taxAmount);
        return true;
    }


    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    if (excludedFromTax[_from] || excludedFromTax[_to]) {
        // Transfer without tax
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
    } else {
        // Transfer with tax
        uint256 taxAmount = _value.mul(taxRate).div(100);
        uint256 netAmount = _value.sub(taxAmount);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(netAmount);
        balances[DevWallet] = balances[DevWallet].add(taxAmount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, netAmount);
        emit Transfer(_from, DevWallet, taxAmount);
    }
    return true;
}



    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
   

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }


    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


}


contract CoinToken is StandardToken {
    string public name;
    string public symbol;
    uint public decimals;
    event Mint(address indexed from, address indexed to, uint256 value);
    bool internal _INITIALIZED_;

    constructor() public {

    }
    modifier notInitialized() {
        require(!_INITIALIZED_, "INITIALIZED");
        _;
    }
    function initToken(string  _name, string  _symbol, uint256 _decimals, uint256 _supply, address tokenOwner) public notInitialized returns (bool){
        _INITIALIZED_=true;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _supply * 10**_decimals;
        balances[tokenOwner] = totalSupply;
        owner = tokenOwner;

        // // service.transfer(msg.value);
        // (bool success) = service.call.value(msg.value)();
        // require(success, "Transfer failed.");
        emit Transfer(address(0), tokenOwner, totalSupply);
    }


    function burn(uint256 amount) public {
    
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] = balances[msg.sender].sub(amount);
        totalSupply = totalSupply.sub(amount);
        emit Transfer(msg.sender, address(0), amount);
    }


}

contract CoinFactory{


    function createToken(string  _name, string  _symbol, uint256 _decimals, uint256 _supply,address tokenOwner)public returns (address){
        CoinToken token=new CoinToken();
        token.initToken(_name,_symbol,_decimals,_supply,tokenOwner);
        return address(token);
    }
}