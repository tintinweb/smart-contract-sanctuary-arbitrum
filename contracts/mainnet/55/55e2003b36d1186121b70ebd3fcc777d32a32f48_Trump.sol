/**
 *Submitted for verification at Arbiscan.io on 2024-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ERC20 Cat in Base Token
 * @dev Implementation of the ERC20 standard token with no supply mechanisms.
 *      This token contract does not support token burning or minting.
 */
contract Trump  {
    string private _name = "Trump Coin";
    string private _symbol = "TRUMP";
    uint8 private _decimals = 10;
    uint256 private _totalSupply = 1000000000 * 10**10; // 1 billion tokens with 10 decimals

    address private _owner;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        _owner = msg.sender;
        _balances[msg.sender] = _totalSupply;
    }

    /**
     * @dev Modifier to check if the caller is the current owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the contract owner can perform this action");
        _;
    }

    /**
     * @dev Returns the current owner of the contract.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Cannot transfer ownership to zero address");
        _owner = newOwner;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the total supply of the token.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the balance of the `account` address.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner`
     */
    function allowance(address ownerAddress, address spender) public view returns (uint256) {
        return _allowances[ownerAddress][spender]; // Changed function name to allowance
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism.
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    /**
     * @dev Internal function that transfers `amount` tokens from `sender` to `recipient`.
     * Emits a {Transfer} event.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Internal function that approves `spender` to spend `amount` of `owner`'s tokens.
     * Emits an {Approval} event.
     */
    function _approve(address ownerAddress, address spender, uint256 amount) internal {
        require(ownerAddress != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[ownerAddress][spender] = amount;
        emit Approval(ownerAddress, spender, amount);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}