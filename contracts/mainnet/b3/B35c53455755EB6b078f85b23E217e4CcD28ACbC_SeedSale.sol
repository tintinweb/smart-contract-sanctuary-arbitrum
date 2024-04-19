// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IxELN {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address,address,uint256) external returns (bool);
    function burn(uint256) external returns (bool);
    function burnFrom(address, uint256) external returns (bool);
    function owner() external returns (address);
    function setOwner(address) external;
    function ELN() external returns (address);
    function setELN(address) external;
}

// contracts/SeedSale.sol

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./xELN.sol";  

contract SeedSale {
    IERC20 public token;
    IERC20 public usdt;
    uint256 public rate = 1250 * 10**18;  // Rate adjusted for xELN decimals
    uint256 public sold = 0;
    uint256 public end = 250 * 10**6 * 10**18;  // 250 million tokens in smallest unit
    address public owner;

    constructor(IERC20 _token, IERC20 _usdt) {
        token = _token;
        usdt = _usdt;
        owner = msg.sender;
    }

    function buy(uint256 _usdtAmount) external {
        require(sold < end, "Sale ended");
        uint256 tokens = _usdtAmount * rate / 10**6;  // Adjust for USDT decimals
        require(sold + tokens <= end, "Not enough tokens left");
        usdt.transferFrom(msg.sender, owner, _usdtAmount);
        token.transfer(msg.sender, tokens);
        sold += tokens;
    }

    function withdraw() external {
        require(msg.sender == owner, "Only owner can withdraw");
        uint256 balance = token.balanceOf(address(this));  
        token.transfer(owner, balance);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "./interfaces/IxELN.sol";

contract xELN is IxELN {

    string public constant name = "xELN";
    string public constant symbol = "xELN";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 0;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    bool public initialMinted;
    address public owner;
    address public ELN;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        owner = msg.sender;
        _mint(msg.sender, 0);
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, "Only the owner can set a new owner.");
        owner = _owner;
    }

    function setELN(address _ELN) external {
        require(msg.sender == owner, "Only the owner can set ELN.");
        ELN = _ELN;
    }

    function initialMint(address _recipient) external {
        require(msg.sender == owner && !initialMinted, "Only the owner can perform the initial mint and only once.");
        initialMinted = true;  // Set the flag to true to ensure this function cannot be called again
        _mint(_recipient, 10 * 1e9 * 1e18);  // Mint 10 billion tokens accounting for the 18 decimals
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _mint(address _to, uint256 _amount) internal returns (bool) {
        totalSupply += _amount;
        balanceOf[_to] += _amount;
        emit Transfer(address(0x0), _to, _amount);
        return true;
    }

    function _burn(address _from, uint256 _amount) internal returns (bool) {
        require(balanceOf[_from] >= _amount, "Insufficient balance to burn.");
        totalSupply -= _amount;
        balanceOf[_from] -= _amount;
        emit Transfer(_from, address(0x0), _amount);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        require(balanceOf[_from] >= _value, "Insufficient balance to transfer.");
        balanceOf[_from] -= _value;
        unchecked {
            balanceOf[_to] += _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        uint allowed_from = allowance[_from][msg.sender];
        if (allowed_from != type(uint256).max) {
            allowance[_from][msg.sender] -= _value;
        }
        return _transfer(_from, _to, _value);
    }

    function burn(uint256 amount) external returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }

    function burnFrom(address _from, uint256 amount) external returns (bool) {
        require(msg.sender == ELN, "Only ELN can initiate burnFrom.");
        _burn(_from, amount);
        return true;
    }

}