/**
 *Submitted for verification at Arbiscan.io on 2024-04-17
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/utils/Pausable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: AKTokenPreSwap.sol


pragma solidity ^0.8.20;




/**
 * @title AKTokenPreSwap
 * @dev This contract implements the AKTokenPreSwap functionality.
 * It is an Ownable and Pausable contract.
 */
contract AKTokenPreSwap is Ownable, Pausable {

    // USDT token contract
    IERC20 public usdtToken;

    // AK token contract
    IERC20 public akToken;

    // AK token supply for swap in the current chain
    uint256 public akSupply;

    /**
     * @dev The price of swap (unit: wei)
     * @notice To be precise, here is the price of USDT relative to AK
     * @notice For example, if the price is 25, it means that 1 USDT can be exchanged for 25 AK
     */
    uint256 public akPrice;

    // The cumulative number of AK sold in the current chain
    uint256 public akSold;

    // The cumulative amount of USDT received in the current chain
    uint256 public usdtReceived;

    // Maximum quota for a single account in the current chain
    uint256 public accountMaxQuota;

    // The wallet address of the foundation
    address public foundationWallet;

    // The accumulated amount purchased by the user in the current chain
    // account => quota
    mapping(address => uint256) public accountQuotas;

    // Event to notify the swap of AK
    event SwapAK(
        address account,
        uint256 usdtAmount,
        uint256 akAmount,
        uint256 timestamp
    );

    /**
     * @dev Constructor
     * @param _usdtToken USDT token contract
     * @param _akToken AK token contract
     * @param _akSupply AK token supply for swap in the current chain
     * @param _akPrice The price of swap (unit: wei)
     * @param _accountMaxQuota Maximum quota for a single account in the current chain
     * @param _foundationWallet The wallet address of the foundation
     */
    constructor(
        IERC20 _usdtToken,
        IERC20 _akToken,
        uint256 _akSupply,
        uint256 _akPrice,
        uint256 _accountMaxQuota,
        address _foundationWallet
    ) Ownable(msg.sender) {
        usdtToken = _usdtToken;
        akToken = _akToken;
        akSupply = _akSupply;
        akPrice = _akPrice;
        accountMaxQuota = _accountMaxQuota;
        foundationWallet = _foundationWallet;
    }

    /**
     * @dev Set the price of swap
     * @param _akPrice The price of swap (unit: wei)
     * 
     * @notice For example:
     * if the _akPrice is 25, 
     * it means that 1 USDT can be exchanged for 25 AK
     */
    function setPrice(uint256 _akPrice) public onlyOwner {
        require(_akPrice > 0, "Token price must be greater than zero");
        akPrice = _akPrice;
    }

    /**
     * @dev Set the foundation wallet address
     * @param _foundationWallet The wallet address of the foundation
     */
    function setFoundationWallet(address _foundationWallet) public onlyOwner {
        require(_foundationWallet != address(0), "Foundation wallet can't be zero");
        foundationWallet = _foundationWallet;
    }

    /**
     * @dev Set the maximum quota for a single account
     * @param _accountMaxQuota Maximum quota for a single account
     */
    function setAccountMaxQuota(uint256 _accountMaxQuota) public onlyOwner {
        require(
            _accountMaxQuota > 0,
            "Account quota must be greater than zero"
        );
        accountMaxQuota = _accountMaxQuota;
    }

    /**
     * @dev Set the AK token supply for swap in the current chain
     * @param _akSupply AK token supply for swap in the current chain
     */
    function setAkSupply(uint256 _akSupply) public onlyOwner {
        require(
            _akSupply > 0,
            "_akSupply must be greater than zero"
        );
        akSupply = _akSupply;
    }

    /**
     * @dev Set the USDT and AK token contract
     * @param _usdt USDT token contract
     * @param _ak AK token contract
     */
    function setToken(IERC20 _usdt, IERC20 _ak) public onlyOwner {
        usdtToken = _usdt;
        akToken = _ak;
    }

    /**
     * @dev Calculate the amount of AK swaped by USDT
     * @param usdtAmount The amount of USDT
     */
    function evaSwapAK(uint256 usdtAmount) public view returns (uint256) {
        return (usdtAmount * akPrice) / 1e18;
    }

    /**
     * @dev Swap AK by USDT
     * @param usdtAmount The amount of USDT
     */
    function swapAK(uint256 usdtAmount) public whenNotPaused {
        uint256 akAmount = evaSwapAK(usdtAmount);
        require(foundationWallet != address(0), "Foundation wallet can't be zero");
        require(usdtAmount > 0, "USDT amount must be greater than zero");
        require((akAmount + akSold) <= akSupply, "Exceeded maximum AK supply");
        require(
            (akAmount + accountQuotas[msg.sender]) <= accountMaxQuota,
            "Exceeded account maximum quota"
        );
        require(
            usdtToken.allowance(msg.sender, address(this)) >= usdtAmount,
            "Insufficient allowance for USDT"
        );
        require(
            akToken.balanceOf(address(this)) >= akAmount,
            "Insufficient AK token balance"
        );

        usdtToken.transferFrom(msg.sender, foundationWallet, usdtAmount);
        akToken.transfer(msg.sender, akAmount);

        akSold += akAmount;
        usdtReceived += usdtAmount;
        accountQuotas[msg.sender] += akAmount;

        emit SwapAK(msg.sender, usdtAmount, akAmount, block.timestamp);
    }

    /**
     * @dev Withdraw tokens from the contract
     * only the owner can call, 
     * Prevent tokens from being transferred to this contract address due to errors.
     * 
     * @param token The token contract
     * @param to The recipient address
     * @param amount The amount of token
     */
    function withdraw(
        IERC20 token,
        address to,
        uint256 amount
    ) public onlyOwner {
        require(
            token.balanceOf(address(this)) >= amount,
            "Not enough token balance"
        );
        require(to != address(0), "Withdraw to the zero address");
        token.transfer(to, amount);
    }
    
    /**
     * @dev Get the account information
     * @param account The account address
     * 
     * @return _chainId Chain ID
     * @return _isPause Whether the purchase has been suspended
     * @return _usdtToken USDT token contract address
     * @return _akToken AK token contract address
     * @return _akSwap AK purchase contract address
     * @return _akSupply The maximum supply of AK in the current chain
     * @return _akPrice The price of AK (unit: wei)
     * @return _akSold The cumulative number of AK sold in the current chain
     * @return _usdtReceived Accumulate the amount of USDT received in the current chain
     * @return _accountMaxQuota Maximum quota for a single account
     * @return _accountQuota The accumulated amount purchased by the user in the current chain
     */
    function getAccountInfo(
        address account
    )
        public
        view
        returns (
            uint256 _chainId,
            bool _isPause,
            address _usdtToken,
            address _akToken,
            address _akSwap,
            uint256 _akSupply,
            uint256 _akPrice,
            uint256 _akSold,
            uint256 _usdtReceived,
            uint256 _accountMaxQuota,
            // **************************************************
            // If the user is not connected to the wallet, 
            // pass 0 address, and the following values are 0,
            // After the user successfully connects to the wallet, 
            // re-request the interface to obtain the user information.
            // **************************************************
            uint256 _accountQuota
        )
    {
        _akSwap = address(this);
        _chainId = block.chainid;
        _usdtToken = address(usdtToken);
        _akToken = address(akToken);
        _akSold = akSold;
        _akPrice = akPrice;
        _akSupply = akSupply;
        _accountMaxQuota = accountMaxQuota;
        _accountQuota = accountQuotas[account];
        _isPause = paused();
        _usdtReceived = usdtReceived;
    }
}