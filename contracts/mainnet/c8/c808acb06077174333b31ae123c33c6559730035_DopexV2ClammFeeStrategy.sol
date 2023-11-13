// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Interfaces
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IDopexV2ClammFeeStrategy} from "./IDopexV2ClammFeeStrategy.sol";

// Contracts
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title DopexV2ClammFeeStrategy
/// @author witherblock
/// @notice Computes the fee for an option purchase on Dopex V2 CLAMM
contract DopexV2ClammFeeStrategy is IDopexV2ClammFeeStrategy, Ownable {
    /// @dev Option Market address => bool (is registered or not)
    mapping(address => bool) public registeredOptionMarkets;

    /// @dev Option Market address => Fee Percentage (fee percentage on premium)
    mapping(address => uint256) public feePercentages;

    /// @dev The precision in which fee percent is set (fee percent should always be divided by 1e6 to get the correct vaue)
    uint256 public constant FEE_PERCENT_PRECISION = 1e4;

    /// @notice Registers an option market with the fee strategy
    /// @dev Can only be called by owner.
    /// @param _optionMarket Address of the option market
    /// @param _feePercentage Fee percentage
    function registerOptionMarket(
        address _optionMarket,
        uint256 _feePercentage
    ) external onlyOwner {
        registeredOptionMarkets[_optionMarket] = true;

        updateFees(_optionMarket, _feePercentage);

        emit OptionMarketRegistered(_optionMarket);
    }

    /// @notice Updates the fee struct of an option market
    /// @dev Can only be called by owner.
    /// @param _optionMarket Address of the option market
    /// @param _feePercentage Fee percentage
    function updateFees(
        address _optionMarket,
        uint256 _feePercentage
    ) public onlyOwner {
        require(
            _feePercentage < FEE_PERCENT_PRECISION * 100,
            "Fee percentage cannot be 100% or more"
        );

        feePercentages[_optionMarket] = _feePercentage;

        emit FeeUpdate(_optionMarket, _feePercentage);
    }

    /// @inheritdoc	IDopexV2ClammFeeStrategy
    function onFeeReqReceive(
        address _optionMarket,
        uint256,
        uint256,
        uint256 _premium
    ) external view returns (uint256 fee) {
        uint256 feePercentage = feePercentages[_optionMarket];

        if (!registeredOptionMarkets[_optionMarket]) {
            revert OptionMarketNotRegistered(_optionMarket);
        }

        fee = (feePercentage * _premium) / (FEE_PERCENT_PRECISION * 100);
    }

    error OptionMarketNotRegistered(address optionMarket);

    event OptionMarketRegistered(address optionMarket);

    event FeeUpdate(address optionMarket, uint256 feePercentages);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IDopexV2ClammFeeStrategy {
    /// @notice Computes the fee for an option purchase on Dopex V2 CLAMM
    /// @param _optionMarket Address of the option market
    /// @param _amount Notional Amount
    /// @param _iv Implied Volatility
    /// @param _premium Total premium being charged for the option purchase
    /// @return fee the computed fee
    function onFeeReqReceive(
        address _optionMarket,
        uint256 _amount,
        uint256 _iv,
        uint256 _premium
    ) external view returns (uint256 fee);
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
}