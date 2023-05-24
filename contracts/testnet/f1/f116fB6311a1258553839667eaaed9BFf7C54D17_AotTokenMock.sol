// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

contract SafeMath {
    // https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
    // slither-disable-next-line dead-code
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    // slither-disable-next-line dead-code
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    // slither-disable-next-line dead-code
    function safePower(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a**b;
        return c;
    }
}

interface IToken {
    // https://github.com/crytic/slither/wiki/Detector-Documentation#incorrect-erc20-interface
    // slither-disable-next-line erc20-interface
    function transfer(address _to, uint256 _value) external;
}

contract AotTokenMock is SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address payable public owner;
    address payable public ownerTemp;
    uint256 public blocknumberLastAcceptOwner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public blacklist;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event SetOwner(address user);
    event SetBlacklist(address user, bool isBlacklist);
    event AcceptOwner(address user);

    constructor() {
        // https://github.com/crytic/slither/wiki/Detector-Documentation#too-many-digits
        // slither-disable-next-line too-many-digits
        balanceOf[msg.sender] = 300000000000000; // Give the creator all initial tokens
        // slither-disable-next-line too-many-digits
        totalSupply = 300000000000000; // Update total supply
        name = "A.O.T.M"; // Set the name for display purposes
        symbol = "A.O.T.M"; // Set the symbol for display purposes
        decimals = 6; // Amount of decimals for display purposes
        owner = msg.sender;
        // slither-disable-next-line too-many-digits
        emit Transfer(
            0x0000000000000000000000000000000000000000,
            msg.sender,
            totalSupply
        );
    }

    function transfer(address to_, uint256 value_)
        external
        returns (bool success)
    {
        /* Send coins */
        require(
            to_ != address(0x0) && !blacklist[msg.sender],
            "AotTokenMock: zero address"
        ); // Prevent transfer to 0x0 address. Use burn() instead
        require(
            balanceOf[msg.sender] >= value_,
            "AotTokenMock: insufficient balance"
        ); // Check if the sender has enough
        require(
            safeAdd(balanceOf[to_], value_) >= balanceOf[to_],
            "AotTokenMock: overflow"
        ); // Check for overflows
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value_); // Subtract from the sender
        balanceOf[to_] = safeAdd(balanceOf[to_], value_); // Add the same to the recipient
        emit Transfer(msg.sender, to_, value_); // Notify anyone listening that this transfer took place
        return true;
    }

    function approve(address spender_, uint256 value_)
        external
        returns (bool success)
    {
        /* Allow another contract to spend some tokens in your behalf */
        allowance[msg.sender][spender_] = value_;
        emit Approval(msg.sender, spender_, value_);
        return true;
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 value_
    ) external returns (bool success) {
        /* A contract attempts to get the coins */
        require(
            to_ != address(0x0) && !blacklist[from_],
            "AotTokenMock: zero address"
        ); // Prevent transfer to 0x0 address. Use burn() instead
        require(
            balanceOf[from_] >= value_,
            "AotTokenMock: insufficient balance"
        ); // Check if the sender has enough
        require(
            safeAdd(balanceOf[to_], value_) >= balanceOf[to_],
            "AotTokenMock: overflow"
        ); // Check for overflows
        require(
            value_ <= allowance[from_][msg.sender],
            "AotTokenMock: insufficient allowance"
        ); // Check allowance
        balanceOf[from_] = safeSub(balanceOf[from_], value_); // Subtract from the sender
        balanceOf[to_] = safeAdd(balanceOf[to_], value_); // Add the same to the recipient
        allowance[from_][msg.sender] = safeSub(
            allowance[from_][msg.sender],
            value_
        );
        emit Transfer(from_, to_, value_);
        return true;
    }

    function burn(uint256 value_) external returns (bool success) {
        require(
            balanceOf[msg.sender] >= value_,
            "AotTokenMock: insufficient balance"
        ); // Check if the sender has enough
        require(value_ > 0, "AotTokenMock: negative value");
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value_); // Subtract from the sender
        totalSupply = safeSub(totalSupply, value_); // Updates totalSupply
        emit Burn(msg.sender, value_);
        emit Transfer(msg.sender, address(0), value_);
        return true;
    }

    function setBlacklist(address user_, bool isBlacklist_) external {
        require(msg.sender == owner, "AotTokenMock: unauthorized sender");
        blacklist[user_] = isBlacklist_;
        emit SetBlacklist(user_, isBlacklist_);
    }

    function setOwner(address payable add_) external {
        require(
            msg.sender == owner && add_ != address(0x0),
            "AotTokenMock: zero address"
        );
        ownerTemp = add_;
        blocknumberLastAcceptOwner = block.number + 201600;
        emit SetOwner(add_);
    }

    function acceptOwner() external {
        require(
            msg.sender == ownerTemp &&
                block.number < blocknumberLastAcceptOwner &&
                block.number > blocknumberLastAcceptOwner - 172800,
            "AotTokenMock: invalid owner"
        );
        owner = ownerTemp;
        emit AcceptOwner(owner);
    }

    // transfer balance to owner
    function withdrawToken(address token, uint256 amount) external {
        require(msg.sender == owner, "AotTokenMock: unauthorized sender");
        if (token == address(0x0)) owner.transfer(amount);
        else IToken(token).transfer(owner, amount);
    }
}