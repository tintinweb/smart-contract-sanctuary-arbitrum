// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOracle} from "./interfaces/IOracle.sol";

/**
 * @title The contract handles whitelist related features
 * @notice The main functionalities are:
 * - Self whitelist by sending ETH to this contract(only when self whitelist is allowed - controlled by _isSelfWhitelistDisabled flag)
 * - Ownable: Add whitelisted/blacklisted addresses
 * - Ownable: Set max ETH amount to buy(default 3 ETH)
 * - Ownable: Set univ3 TWAP oracle
 * - Vultisig contract `_beforeTokenTransfer` hook will call `checkWhitelist` function and this function will check if buyer is eligible
 */
contract Whitelist is Ownable {
    error NotWhitelisted();
    error Locked();
    error NotVultisig();
    error SelfWhitelistDisabled();
    error Blacklisted();
    error MaxAddressCapOverflow();

    /// @notice Maximum ETH amount to contribute
    uint256 private _maxAddressCap;
    /// @notice Flag for locked period
    bool private _locked;
    /// @notice Flag for self whitelist period
    bool private _isSelfWhitelistDisabled;
    /// @notice Vultisig token contract address
    address private _vultisig;
    /// @notice Uniswap v3 TWAP oracle
    address private _oracle;
    /// @notice Uniswap v3 pool address
    address private _pool;
    /// @notice Total number of whitelisted addresses
    uint256 private _whitelistCount;
    /// @notice Max index allowed
    uint256 private _allowedWhitelistIndex;
    /// @notice Whitelist index for each whitelisted address
    mapping(address => uint256) private _whitelistIndex;
    /// @notice Mapping for blacklisted addresses
    mapping(address => bool) private _isBlacklisted;
    /// @notice Contributed ETH amounts
    mapping(address => uint256) private _contributed;

    /// @notice Set the default max address cap to 3 ETH and lock token transfers initially
    constructor() {
        _maxAddressCap = 3 ether;
        _locked = true; // Initially, liquidity will be locked
        _transferOwnership(0xa3e78aB6f120C730D6F3939c0Dc6dcD0E3da7278);
    }

    /// @notice Check if called from vultisig token contract.
    modifier onlyVultisig() {
        if (_msgSender() != _vultisig) {
            revert NotVultisig();
        }
        _;
    }

    /// @notice Self-whitelist using ETH transfer
    /// @dev reverts if whitelist is disabled
    /// @dev reverts if address is already blacklisted
    /// @dev ETH will be sent back to the sender
    receive() external payable {
        if (_isSelfWhitelistDisabled) {
            revert SelfWhitelistDisabled();
        }
        if (_isBlacklisted[_msgSender()]) {
            revert Blacklisted();
        }
        _addWhitelistedAddress(_msgSender());
        payable(_msgSender()).transfer(msg.value);
    }

    /// @notice Returns max address cap
    function maxAddressCap() external view returns (uint256) {
        return _maxAddressCap;
    }

    /// @notice Returns vultisig address
    function vultisig() external view returns (address) {
        return _vultisig;
    }

    /// @notice Returns the whitelisted index. If not whitelisted, then it will be 0
    /// @param account The address to be checked
    function whitelistIndex(address account) external view returns (uint256) {
        return _whitelistIndex[account];
    }

    /// @notice Returns if the account is blacklisted or not
    /// @param account The address to be checked
    function isBlacklisted(address account) external view returns (bool) {
        return _isBlacklisted[account];
    }

    /// @notice Returns if self-whitelist is allowed or not
    function isSelfWhitelistDisabled() external view returns (bool) {
        return _isSelfWhitelistDisabled;
    }

    /// @notice Returns Univ3 TWAP oracle address
    function oracle() external view returns (address) {
        return _oracle;
    }

    /// @notice Returns Univ3 pool address
    function pool() external view returns (address) {
        return _pool;
    }

    /// @notice Returns current whitelisted address count
    function whitelistCount() external view returns (uint256) {
        return _whitelistCount;
    }

    /// @notice Returns current allowed whitelist index
    function allowedWhitelistIndex() external view returns (uint256) {
        return _allowedWhitelistIndex;
    }

    /// @notice Returns contributed ETH amount for address
    /// @param to The address to be checked
    function contributed(address to) external view returns (uint256) {
        return _contributed[to];
    }

    /// @notice If token transfer is locked or not
    function locked() external view returns (bool) {
        return _locked;
    }

    /// @notice Setter for locked flag
    /// @param newLocked New flag to be set
    function setLocked(bool newLocked) external onlyOwner {
        _locked = newLocked;
    }

    /// @notice Setter for max address cap
    /// @param newCap New cap for max ETH amount
    function setMaxAddressCap(uint256 newCap) external onlyOwner {
        _maxAddressCap = newCap;
    }

    /// @notice Setter for vultisig token
    /// @param newVultisig New vultisig token address
    function setVultisig(address newVultisig) external onlyOwner {
        _vultisig = newVultisig;
    }

    /// @notice Setter for self-whitelist period
    /// @param newFlag New flag for self-whitelist period
    function setIsSelfWhitelistDisabled(bool newFlag) external onlyOwner {
        _isSelfWhitelistDisabled = newFlag;
    }

    /// @notice Setter for Univ3 TWAP oracle
    /// @param newOracle New oracle address
    function setOracle(address newOracle) external onlyOwner {
        _oracle = newOracle;
    }

    /// @notice Setter for Univ3 pool
    /// @param newPool New pool address
    function setPool(address newPool) external onlyOwner {
        _pool = newPool;
    }

    /// @notice Setter for blacklist
    /// @param blacklisted Address to be added
    /// @param flag New flag for address
    function setBlacklisted(address blacklisted, bool flag) external onlyOwner {
        _isBlacklisted[blacklisted] = flag;
    }

    /// @notice Setter for allowed whitelist index
    /// @param newIndex New index for allowed whitelist
    function setAllowedWhitelistIndex(uint256 newIndex) external onlyOwner {
        _allowedWhitelistIndex = newIndex;
    }

    /// @notice Add whitelisted address
    /// @param whitelisted Address to be added
    function addWhitelistedAddress(address whitelisted) external onlyOwner {
        _addWhitelistedAddress(whitelisted);
    }

    /// @notice Add batch whitelists
    /// @param whitelisted Array of addresses to be added
    function addBatchWhitelist(address[] calldata whitelisted) external onlyOwner {
        for (uint i = 0; i < whitelisted.length; i++) {
            _addWhitelistedAddress(whitelisted[i]);
        }
    }

    /// @notice Check if address to is eligible for whitelist
    /// @param from sender address
    /// @param to recipient address
    /// @param amount Number of tokens to be transferred
    /// @dev Check WL should be applied only
    /// @dev Revert if locked, not whitelisted, blacklisted or already contributed more than capped amount
    /// @dev Update contributed amount
    function checkWhitelist(address from, address to, uint256 amount) external onlyVultisig {
        if (from == _pool && to != owner()) {
            // We only add limitations for buy actions via uniswap v3 pool
            // Still need to ignore WL check if it's owner related actions
            if (_locked) {
                revert Locked();
            }

            if (_isBlacklisted[to]) {
                revert Blacklisted();
            }

            if (_allowedWhitelistIndex == 0 || _whitelistIndex[to] > _allowedWhitelistIndex) {
                revert NotWhitelisted();
            }

            // // Calculate rough ETH amount for VULT amount
            uint256 estimatedETHAmount = IOracle(_oracle).peek(amount);
            if (_contributed[to] + estimatedETHAmount > _maxAddressCap) {
                revert MaxAddressCapOverflow();
            }

            _contributed[to] += estimatedETHAmount;
        }
    }

    /// @notice Internal function used for whitelisting. Only increase whitelist count if address is not whitelisted before
    /// @param whitelisted Address to be added
    function _addWhitelistedAddress(address whitelisted) private {
        if (_whitelistIndex[whitelisted] == 0) {
            _whitelistIndex[whitelisted] = ++_whitelistCount;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IOracle {
    function name() external view returns (string memory);

    function peek(uint256 baseAmount) external view returns (uint256 answer);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

pragma solidity ^0.8.0;

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