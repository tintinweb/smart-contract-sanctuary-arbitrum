// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

pragma solidity ^0.8.0;

interface IAToken is IERC20Upgradeable {

    function decimals() external view returns (uint8);
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

}

// SPDX-License-Identifier: BUSL-1.1
// Teahouse Finance

pragma solidity =0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interface/IAssetOracle.sol";
import "../interface/AAVE/IAToken.sol";

//import "hardhat/console.sol";
contract AaveATokenOracle is IAssetOracle, Ownable {

    address immutable public baseAsset;
    IAssetOracle public baseAssetOracle;
    uint8 private constant DECIMALS = 18;
    mapping (address => address) public underlyingAsset;

    constructor(address _baseAsset, IAssetOracle _baseAssetOracle) {
        if (_baseAsset != _baseAssetOracle.getBaseAsset()) revert BaseAssetMismatch();
        baseAsset = _baseAsset;
        baseAssetOracle = _baseAssetOracle;
    }

    /// @inheritdoc IAssetOracle
    function decimals() external override pure returns (uint8) {
        return DECIMALS;
    }

    /// @inheritdoc IAssetOracle
    function getBaseAsset() external override view returns (address) {
        return baseAsset;
    }

    /// @inheritdoc IAssetOracle
    function isOracleEnabled(address _asset) external override view returns (bool) {
        return underlyingAsset[_asset] != address(0);
    }

    function enableOracle(IAToken _aaveAToken) external onlyOwner {
        underlyingAsset[address(_aaveAToken)] = _aaveAToken.UNDERLYING_ASSET_ADDRESS();
    }

    /// @inheritdoc IAssetOracle
    function getValue(address _asset, uint256 _amount) external override view returns (uint256 value) {
        return _getValue(baseAssetOracle, _asset, _amount);
    }

    /// @inheritdoc IAssetOracle
    function getBatchValue(
        address[] calldata _assets,
        uint256[] calldata _amounts
    ) external override view returns (
        uint256[] memory values
    ) {
        if (_assets.length != _amounts.length) revert BatchLengthMismatched();
        IAssetOracle _baseAssetOracle = baseAssetOracle;
        values = new uint256[](_assets.length);
        // AUDIT: AAT-01C
        for (uint256 i; i < _assets.length; ) {
            values[i] = _getValue(_baseAssetOracle, _assets[i], _amounts[i]);
            unchecked { i = i + 1; }
        }
    }

    /// @inheritdoc IAssetOracle
    function getValueWithTwap(address _asset, uint256 _amount, uint256 _twap) external override view returns (uint256 value) {
        return _getValueWithTwap(baseAssetOracle, _asset, _amount, _twap);
    }

    /// @inheritdoc IAssetOracle
    function getBatchValueWithTwap(
        address[] calldata _assets,
        uint256[] calldata _amounts,
        uint256[] calldata _twaps
    ) external override view returns (
        uint256[] memory values
    ) {
        // AUDIT: AAT-01M
        if (_assets.length != _amounts.length) revert BatchLengthMismatched();
        if (_assets.length != _twaps.length) revert BatchLengthMismatched();

        IAssetOracle _baseAssetOracle = baseAssetOracle;
        values = new uint256[](_assets.length);

        // AUDIT: AAT-01C
        for (uint256 i; i < _assets.length; ) {
            values[i] = _getValueWithTwap(_baseAssetOracle, _assets[i], _amounts[i], _twaps[i]);
            unchecked { i = i + 1; }
        }
    }

    /// @inheritdoc IAssetOracle
    function getTwap(address _asset) external override view returns (uint256 price) {
        return _getTwap(baseAssetOracle, _asset);
    }

    /// @inheritdoc IAssetOracle
    function getBatchTwap(address[] calldata _assets) external override view returns (uint256[] memory prices) {
        IAssetOracle _baseAssetOracle = baseAssetOracle;
        prices = new uint256[](_assets.length);

        // AUDIT: AAT-01C
        for (uint256 i; i < _assets.length; ) {
            prices[i] = _getTwap(_baseAssetOracle, _assets[i]);
            unchecked { i = i + 1; }
        }
    }

    function _getValue(IAssetOracle _baseAssetOracle, address _asset, uint256 _amount) internal view returns (uint256 value) {
        return _baseAssetOracle.getValue(underlyingAsset[_asset], _amount);
    }

    function _getValueWithTwap(
        IAssetOracle _baseAssetOracle,
        address _asset,
        uint256 _amount,
        uint256 _twap
    ) internal view returns (
        uint256 value
    ) {
        return _baseAssetOracle.getValueWithTwap(underlyingAsset[_asset], _amount, _twap);
    }

    function _getTwap(IAssetOracle _baseAssetOracle, address _asset) internal view returns (uint256 price) {
        return _baseAssetOracle.getTwap(underlyingAsset[_asset]);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Teahouse Finance

pragma solidity =0.8.21;

interface IAssetOracle {

    error BaseAssetCannotBeReenabled();
    error ConfigLengthMismatch();
    error BaseAssetMismatch();
    error AssetNotEnabled();
    error BatchLengthMismatched();
    error AssetNotInPool();
    error ZeroTwapIntervalNotAllowed();    

    /*
        sample: asset = USDT (decimals = 6), TWAP (USDT/USDC) = 1.001, oracle decimals = 4, amount = 123000000
        returns:
            getValue: 123 * getTwap = 1231230
            getTwap: 10010
    */

    /// @notice get oracle decimals
    function decimals() external view returns (uint8);

    /// @notice get oracle base asset
    function getBaseAsset() external view returns (address);

    /// @notice get whether asset oracle is enabled
    function isOracleEnabled(address _asset) external view returns (bool);

    /// @notice get asset value in TWAP with the given amount
    function getValue(address _asset, uint256 _amount) external view returns (uint256 value);

    /// @notice batch version of getValue
    function getBatchValue(address[] calldata _assets,uint256[] calldata _amounts) external view returns (uint256[] memory values);
    
    /// @notice get asset value in TWAP with the given amount and TWAP
    function getValueWithTwap(address _asset, uint256 _amount, uint256 _twap) external view returns (uint256 value);

    /// @notice batch version of getValueWithTwap
    function getBatchValueWithTwap(
        address[] calldata _assets,
        uint256[] calldata _amounts,
        uint256[] calldata _twaps
    ) external view returns (
        uint256[] memory values
    );

    /// @notice get unit TWAP of asset
    function getTwap(address _asset) external view returns (uint256 price);

    /// @notice batch version of getTwap
    function getBatchTwap(address[] calldata _assets) external view returns (uint256[] memory prices);
}