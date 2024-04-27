/**
 *Submitted for verification at Arbiscan.io on 2024-04-27
*/

// SPDX-License-Identifier: GPL-3.0-or-later

// website: https://farmgrid.org :ORIGINAL

pragma solidity >=0.8.19;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}

contract Owned {
    address payable tokenMaker;

    bool private _notEntered = true;

    // address payable newOwner; // When contract creator wish to make another address the creator(handover)

    event Received(address, uint256); // this contract can/has receive ETH

    // event OwnerSet(address indexed oldOwner, address indexed newOwner); // contract owner can be changed by the owner

    event TokenTransfer(
        address contractAddress,
        address indexed recipient,
        uint256 amount,
        uint256 indexed date
    );

    modifier restricted() {
        require(msg.sender == tokenMaker);
        _;
    }

    modifier nonReentrant() {
        require(_notEntered, "ReentrancyGuard: reentrant call");
        _notEntered = false;
        _;
        _notEntered = true;
    }

    function getBalance() public view returns (uint256) {
        // return the ETH balance of the contract
        return address(this).balance;
    }

    function withdrawEther(address payable recipient, uint256 amount)
        external
        restricted
        nonReentrant
        returns (bool)
    {
        // transfer Ether to the recipient address

        // make sure we have the balance

        //---

        recipient.transfer(amount);

        return true;
    }

    function transferToken(
        address payable contract_address,
        address payable recipient,
        uint256 amount
    ) external restricted nonReentrant returns (bool) {
        // Transfers any ERC20 token found in this contract given the token contract address:
        // only owner can perform this action: should anyone mistakinly send us ERC20 token,
        // we can return it to them instead of the token to get lost

        // check if contract_address is actually a contract
        /*   uint256 tokenCode;
           assembly { tokenCode := extcodesize(contract_address) } // contract code size
           require(tokenCode > 0 && contract_address.call(bytes4(0x70a08231), recipient),
            "transfer Token fails: pass token contract address only");
        */

        Token token = Token(contract_address); // ERC20 token contract
        require(token.transfer(recipient, amount), "transfer Token fails");
        emit TokenTransfer(
            contract_address,
            recipient,
            amount,
            block.timestamp
        );
        return true;
    }

    function relinquishOwnership() public restricted nonReentrant {
        require(msg.sender != address(0));
        tokenMaker = payable(address(0));
    }
}

abstract contract ERC20 {
    uint256 public totalSupply;

    function balanceOf(address _owner)
        public
        view
        virtual
        returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        public
        virtual
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public virtual returns (bool success);

    function approve(address _spender, uint256 _value)
        public
        virtual
        returns (bool success);

    function allowance(address _owner, address _spender)
        public
        view
        virtual
        returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

contract Token is Owned, ERC20 {
    using SafeMath for uint256;
    string public symbol;
    string public name;
    uint8 public decimals;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    function balanceOf(address _owner)
        public
        view
        virtual
        override
        returns (uint256 balance)
    {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _amount)
        public
        virtual
        override
        nonReentrant
        returns (bool success)
    {
        require(_to != address(0), "Invalid recipient address");
        require(
            balances[msg.sender] >= _amount && _amount > 0,
            "Insufficient balance"
        );

        uint256 previousSenderBalance = balances[msg.sender];
        uint256 previousRecipientBalance = balances[_to];

        balances[msg.sender] = previousSenderBalance.sub(_amount);
        balances[_to] = previousRecipientBalance.add(_amount);

        emit Transfer(msg.sender, _to, _amount);

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public virtual override nonReentrant returns (bool success) {
        require(
            balances[_from] >= _amount &&
                allowed[_from][msg.sender] >= _amount &&
                _amount > 0 &&
                balances[_to] + _amount > balances[_to],
            "SafeMath: transfer amount exceeds balance or allowance"
        );

        balances[_from] = SafeMath.sub(balances[_from], _amount);
        allowed[_from][msg.sender] = SafeMath.sub(
            allowed[_from][msg.sender],
            _amount
        );
        balances[_to] = SafeMath.add(balances[_to], _amount);

        emit Transfer(_from, _to, _amount);
        return true;
    }

    function approve(address _spender, uint256 _amount)
        public
        virtual
        override
        nonReentrant
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        virtual
        override
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
}

contract FarmGrid is Token {
    constructor() {
        symbol = "GRID";
        name = "FarmGrid";
        decimals = 18;
        totalSupply = 100000000000000000000000000000000000;
        tokenMaker = payable(msg.sender);
        balances[tokenMaker] = totalSupply;
    }

    // if someone mistakinly transfer BNB to the contract we can help retrieve it for them
    receive() external payable {
        require(msg.value > 0);
        tokenMaker.transfer(msg.value);
    }
}