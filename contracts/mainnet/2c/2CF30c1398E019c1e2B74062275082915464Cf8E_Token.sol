/**
 *Submitted for verification at Arbiscan.io on 2024-03-12
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://eips.ethereum.org/EIPS/eip-20
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract Token is IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    address public owner;
    uint256 private _totalSupply = 1_000_000 * 1e18; // 10k tokens with 18 decimals
    string public name;
    string public symbol;
    uint256 public decimals = 18;
    uint256 public fee;
    uint256 public feeBps = 10000; // fee / feeBps

    modifier onlyOwner {
        require(msg.sender == owner, 'This function can only be executed by the owner');
        _;
    }

    // _feeInHundreds where 10000 is 100%, 1000 is 10%, 100 is 1%, 10 is 0.1%, 1 is 0.01%
    // when mutiplied it is (10000) 100% is 1, (100) 1% is 0.01, (1) 0.01% is 0.00001

    // 100 -> 1% -> 0.01 -> 100 / 10000
    constructor (string memory _nameAndSymbol, uint256 _feeInThousands) {
        _balances[msg.sender] = _totalSupply;
        owner = msg.sender;
        name = _nameAndSymbol;
        symbol = _nameAndSymbol;
        fee = _feeInThousands;
    }

    function changeOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _user) public view returns (uint256) {
        return _balances[_user];
    }

    function allowance(address _user, address spender) public view returns (uint256) {
        return _allowed[_user][spender];
    }

    /**
     * @dev Transfer token to a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender] - value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender] - addedValue);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender] - subtractedValue);
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        uint256 myFee = value * fee / feeBps;
        uint256 valueWithoutFee = value - myFee;

        _balances[from] = _balances[from] - value;
        _balances[owner] += myFee;
        _balances[to] += valueWithoutFee;
        emit Transfer(from, to, value);
    }

    function _approve(address _user, address spender, uint256 value) internal {
        require(spender != address(0));
        require(_user != address(0));

        _allowed[_user][spender] = value;
        emit Approval(_user, spender, value);
    }
}