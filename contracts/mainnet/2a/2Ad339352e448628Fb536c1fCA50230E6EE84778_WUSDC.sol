// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20Wrapper.sol";


contract WUSDC is ERC20Wrapper {
    constructor(address usdc) ERC20Wrapper("Wrapped USDC", "wUSDC", usdc) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";


/** 
Extension of the ERC20 standard that replicates the functionality of the 
Wrapped Ether contract. It allows to wrap other tokens whose contracts are behind 
a proxy or that include censorship functions so that they can be used respecting 
the principles of transparency and decentralization of the blockchain. It also
removes any unexpected behavior from those tokens easing their use.
*/
contract ERC20Wrapper is ERC20 {

    IERC20Metadata public token;
    uint8 public tokenDecimals;

    constructor(string memory name, string memory symbol, address token_) ERC20(name, symbol) {
        token = IERC20Metadata(token_);
        tokenDecimals = token.decimals();
        require(tokenDecimals <= 18);
    }

    
    /// @dev Deposit amount of tokens in contract and mints amount of wrapped tokens
    /// @param amount using 18 decimals
    function deposit(uint256 amount) external {
        uint256 unWrappedAmount = amount / 10**(18-tokenDecimals);
        amount = unWrappedAmount * 10**(18-tokenDecimals); // Remove rounding errors
        token.transferFrom(msg.sender, address(this), unWrappedAmount);
        fulfillDeposit(amount);
    }

    /// @dev Withdraws amount of tokens to sender
    /// @param amount using 18 decimals
    function withdraw(uint256 amount) external {
        withdrawTo(msg.sender, amount);
    }
    
    /// @dev Low level method that allows direct transfer of tokens to this contract to skip the
    /// approve step. This function should only be called from another smart contract that performs 
    /// the token transfer before calling this function in an atomic transaction. Calling this 
    /// function manually after sending the tokens in a different transaction could result in the 
    /// loss of the funds if an attacker front-runs the call to this function.
    /// @param amount using 18 decimals
    function fulfillDeposit(uint256 amount) public {
        uint256 wrappedBalance = token.balanceOf(address(this)) * 10**(18-tokenDecimals);
        require(wrappedBalance >= totalSupply() + amount, "Insufficient deposit");
        _mint(msg.sender, amount);
    }
    
    /// @dev Withdraws amount of tokens to a different address
    /// @param amount using 18 decimals
    function withdrawTo(address to, uint256 amount) public {
        uint256 unWrappedAmount = amount / 10**(18-tokenDecimals);
        amount = unWrappedAmount * 10**(18-tokenDecimals); // Remove rounding errors
        
        _burnFrom(msg.sender, amount);
        token.transfer(to, unWrappedAmount);
        
        uint256 wrappedBalance = token.balanceOf(address(this)) * 10**(18-tokenDecimals);
        require(wrappedBalance >= totalSupply(), "Insufficient resulting balance");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20Metadata.sol";


contract ERC20 is IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;


    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }


    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }


    function transfer(address to, uint256 amount) public override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }


    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        if (amount > 0) { // avoid the zero transfer phishing attack
            emit Transfer(from, to, amount);
        }
    }


    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burnFrom(address from, uint256 amount) internal {
        address spender = msg.sender;
        if (from != spender) {
            _spendAllowance(from, spender, amount);
        }
        _burn(from, amount);
    }

    function _burn(address account, uint256 amount) private {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }


    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}