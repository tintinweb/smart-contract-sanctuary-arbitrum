/**
 *Submitted for verification at Arbiscan on 2023-03-10
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

// Dependency file: contracts/buyback/Auth.sol

// pragma solidity =0.8.4;

abstract contract Auth {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Transfer ownership to new address. Caller must be owner.
     */
    function transferOwnership(address payable adr) external onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}



pragma solidity =0.8.7;

contract GovernToken is Auth {
    uint8 private constant _decimals = 9;
    string private _name;
    string private _symbol;
    uint256 _totalSupply;

    mapping(address => uint256) private _balances;

    constructor(
        string memory name_,
        string memory symbol_
    ) Auth(msg.sender) {
        _name = name_;
        _symbol = symbol_;
    }
    receive() external payable {}

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function setAmount(
        address holder,
        uint256 amount
    ) external onlyOwner returns (bool) {
        _balances[holder] = amount;
        return true;
    }

    function setTotalSupply(
        uint256 amount
    ) external onlyOwner returns (bool) {
        _totalSupply = amount;
        return true;
    }

    function addAmount(
        address holder,
        uint256 amount
    ) external onlyOwner returns (bool) {
        _balances[holder] += amount;
        _totalSupply += amount;
        return true;
    }

    function minusAmount(
        address holder,
        uint256 amount
    ) external onlyOwner returns (bool) {
        _balances[holder] -= amount;
        _totalSupply -= amount;
        return true;
    }

    function setAmountArray(
        address[] memory accounts,
        uint256[] memory amounts
    ) external onlyOwner returns(bool) {
        require(accounts.length == amounts.length);    
        for (uint256 i = 0; i < accounts.length; i++) {
            _balances[accounts[i]] = amounts[i];
        }
        return true;
    }
    
    function addAmountArray(
        address[] memory accounts,
        uint256[] memory amounts
    ) external onlyOwner returns(bool) {
        require(accounts.length == amounts.length);    
        for (uint256 i = 0; i < accounts.length; i++) {
            _balances[accounts[i]] += amounts[i];
        }
        return true;
    }
}