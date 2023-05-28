// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICreditToken is IERC20 {
    struct CrossChainAsset {
        uint256 amountLockedFor;
        uint256 amountLockedFrom;
    }

    function chainIds() external view returns (uint256[] memory);

    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    function mint(address account, uint256 amount) external;

    function transferUnderlyingTo(address account, uint256 amount) external;

    function burn(address account, address receiver, uint256 amount) external;

    function collateralAmountOf(
        address account
    ) external view returns (uint256);

    function lockedBalanceOf(address account) external view returns (uint256);

    function unlockedBalanceOf(address account) external view returns (uint256);

    function burnLockedFor(
        address account,
        address receiver,
        uint256 amount,
        uint256 srcChainId
    ) external;

    function amountLockedFor(
        address account,
        uint256 chainId
    ) external view returns (uint256);

    function amountLockedFrom(
        address account,
        uint256 chainId
    ) external view returns (uint256);

    event LockCreated(
        address indexed account,
        uint256 amount,
        uint256 dstChainId
    );

    event Received(address indexed account, uint256 amount, uint256 srcChainId);

    function lockFor(
        address account,
        uint256 amount,
        uint256 dstChainId
    ) external;

    function unlockFor(
        address account,
        uint256 amount,
        uint256 srcChainId
    ) external;

    function setLendingPool(address _lendingPool) external;

    function setChainsight(address _chainsight) external;

    function onLockCreated(
        address account,
        uint256 amount,
        uint256 srcChainId
    ) external;

    function transferOnLiquidation(
        address from,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDebtToken is IERC20 {
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ILendingPool {
    event LockCreated(
        address indexed account,
        address indexed asset,
        string symbol,
        uint256 amount,
        uint256 dstChainId
    );
    event LockReleased(
        address indexed account,
        address indexed asset,
        string symbol,
        uint256 amount,
        uint256 dstChainId,
        address indexed to
    );

    function deposit(address asset, uint256 amount) external;

    function withdraw(address asset, uint256 amount) external returns (uint256);

    function borrow(address asset, uint256 amount) external;

    function repay(address asset, uint256 amount) external;

    function healthFactorOf(address user) external view returns (uint256);

    function unLockFor(
        address asset,
        uint256 amount,
        uint256 srcChainId
    ) external;

    function initReserve(
        address reserve,
        address creditToken,
        address debtToken
    ) external;

    function liquidationCall(
        address collateral,
        address debt,
        address user,
        uint256 debtToCover
    ) external;

    function chainsight() external view returns (address);

    function assetAddresses(
        string memory symbol
    ) external view returns (address);

    function creditTokenAddress(address asset) external returns (address);

    function debtTokenAddress(address asset) external returns (address);

    function lockFor(
        address asset,
        uint256 amount,
        uint256 dstChainId
    ) external;

    // returns amount of underlying token of debt asset needed to liquidate debt
    function amountNeededToLiquidate(
        address collateral,
        address debt,
        address user,
        uint256 debtToCover
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IPriceOracle {
    function getPriceInUsd(
        string memory symbol
    ) external view returns (uint256);

    function BASE() external view returns (uint256);

    function setPrice(string memory symbol, uint256 price) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "../interfaces/ILendingPool.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/ICreditToken.sol";
import "../interfaces/IDebtToken.sol";
import "../interfaces/IPriceOracle.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LendingPool is ILendingPool, Ownable {
    struct Asset {
        IERC20Metadata underlying;
        ICreditToken creditToken;
        IDebtToken debtToken;
        string symbol;
        uint256 liquidationThreshold;
    }

    uint256 internal constant BASE = 1e18;

    mapping(address => Asset) public assets;
    Asset[] public assetList;
    mapping(string => address) public assetAddresses;

    IPriceOracle priceOracle;
    address public chainsight;

    modifier onlyChainsight() {
        require(msg.sender == chainsight, "only chainsight");
        _;
    }

    function setOracle(address _priceOracle) external onlyOwner {
        priceOracle = IPriceOracle(_priceOracle);
    }

    function creditTokenAddress(
        address asset
    ) external view override returns (address) {
        return address(assets[asset].creditToken);
    }

    function debtTokenAddress(
        address asset
    ) external view override returns (address) {
        return address(assets[asset].debtToken);
    }

    function setChainsight(address _chainsight) external onlyOwner {
        chainsight = _chainsight;
    }

    function priceOf(address _asset) internal view returns (uint256) {
        return priceOracle.getPriceInUsd(assets[_asset].underlying.symbol());
    }

    function amountInUsd(
        address _asset,
        uint256 amount
    ) internal view returns (uint256) {
        return
            (amount * priceOf(_asset)) /
            (10 ** assets[_asset].underlying.decimals());
    }

    function deposit(address _asset, uint256 amount) external override {
        Asset memory asset = assets[_asset];
        asset.underlying.transferFrom(
            msg.sender,
            address(asset.creditToken),
            amount
        );
        asset.creditToken.mint(msg.sender, amount);
    }

    function withdraw(
        address _asset,
        uint256 amount
    ) external override returns (uint256) {
        Asset memory asset = assets[_asset];
        asset.creditToken.burn(msg.sender, msg.sender, amount);
        return 0;
    }

    function borrow(address _asset, uint256 amount) external override {
        Asset memory asset = assets[_asset];
        require(
            _healthFactorAfterDecrease(msg.sender, _asset, 0, amount) >= BASE,
            "health factor too low"
        );
        asset.debtToken.mint(msg.sender, amount);
        asset.creditToken.transferUnderlyingTo(msg.sender, amount);
    }

    function repay(address _asset, uint256 amount) external override {
        Asset memory asset = assets[_asset];
        asset.debtToken.burn(msg.sender, amount);
        asset.underlying.transferFrom(
            msg.sender,
            address(asset.creditToken),
            amount
        );
    }

    function healthFactorOf(
        address user
    ) external view override returns (uint256) {
        return _healthFactorOf(user);
    }

    function _healthFactorOf(address user) internal view returns (uint256) {
        return _healthFactorAfterDecrease(user, address(0), 0, 0);
    }

    function _healthFactorAfterDecrease(
        address user,
        address _asset,
        uint256 collateralDecreased,
        uint256 borrowAdded
    ) internal view returns (uint256) {
        uint256 totalBorrowsInUsd = 0;
        uint256 totalCollateral = 0;
        for (uint256 i = 0; i < assetList.length; i++) {
            Asset memory asset = assetList[i];
            totalBorrowsInUsd += amountInUsd(
                address(asset.underlying),
                asset.debtToken.balanceOf(user)
            );
            uint256 collateralAmountInUsd = amountInUsd(
                address(asset.underlying),
                asset.creditToken.collateralAmountOf(user)
            );
            uint256 collateralizable = collateralAmountInUsd *
                asset.liquidationThreshold;
            totalCollateral += collateralizable;
            if (_asset == address(asset.underlying)) {
                totalBorrowsInUsd += amountInUsd(
                    address(asset.underlying),
                    borrowAdded
                );
                totalCollateral -= amountInUsd(
                    address(asset.underlying),
                    collateralDecreased
                );
            }
        }
        if (totalBorrowsInUsd == 0) {
            return type(uint256).max;
        }
        return totalCollateral / totalBorrowsInUsd;
    }

    function initReserve(
        address reserve,
        address creditToken,
        address debtToken
    ) external override onlyOwner {
        Asset memory asset = Asset({
            underlying: IERC20Metadata(reserve),
            creditToken: ICreditToken(creditToken),
            debtToken: IDebtToken(debtToken),
            symbol: IERC20Metadata(reserve).symbol(),
            liquidationThreshold: (80 * BASE) / 100 // 80%
        });
        assets[reserve] = asset;
        assetList.push(asset);
        assetAddresses[asset.symbol] = reserve;
    }

    function liquidationCall(
        address collateral,
        address debt,
        address user,
        uint256 debtToCover
    ) external override {
        Asset memory debtAsset = assets[debt];
        debtAsset.underlying.transferFrom(
            msg.sender,
            address(debtAsset.creditToken),
            _liquidationCallOnBehalfOf(
                collateral,
                debt,
                user,
                debtToCover,
                msg.sender
            )
        );
    }

    //function liquidationCallByChainsight(
    //    address collateral,
    //    address debt,
    //    address user,
    //    uint256 debtToCover,
    //    address onBehalfOf
    //) external override onlyChainsight returns (uint256) {
    //    return
    //        _liquidationCallOnBehalfOf(
    //            collateral,
    //            debt,
    //            user,
    //            debtToCover,
    //            onBehalfOf
    //        );
    //}

    function amountNeededToLiquidate(
        address collateral,
        address debt,
        address user,
        uint256 debtToCover
    ) external view override returns (uint256) {
        (, uint256 act) = _actualDebtToLiquidate(
            collateral,
            debt,
            user,
            debtToCover
        );
        return act;
    }

    function lockFor(
        address asset,
        uint256 amount,
        uint256 dstChainId
    ) external override {
        assets[asset].creditToken.lockFor(msg.sender, amount, dstChainId);
        emit LockCreated(
            msg.sender,
            asset,
            assets[asset].underlying.symbol(),
            amount,
            dstChainId
        );
    }

    function _actualDebtToLiquidate(
        address collateral,
        address debt,
        address user,
        uint256 debtToCover
    ) internal view returns (uint256 max, uint256 act) {
        Asset memory collateralAsset = assets[collateral];
        Asset memory debtAsset = assets[debt];
        uint256 debtAmount = debtAsset.debtToken.balanceOf(user);
        uint256 maxLiquidatable = debtAmount / 2;
        act = debtToCover > maxLiquidatable ? maxLiquidatable : debtToCover;
        (
            uint256 maxAmountCollateralToLiquidate,
            uint256 debtAmountNeeded
        ) = _calculateAvailableCollateralToLiquidate(
                collateral,
                debt,
                act,
                collateralAsset.creditToken.collateralAmountOf(user)
            );
        if (debtAmountNeeded < act) {
            act = debtAmountNeeded;
        }
        return (maxAmountCollateralToLiquidate, act);
    }

    function _liquidationCallOnBehalfOf(
        address collateral,
        address debt,
        address user,
        uint256 debtToCover,
        address onBehalfOf
    ) internal returns (uint256) {
        require(
            _healthFactorOf(user) < BASE,
            "health factor is not low enough"
        );
        Asset memory collateralAsset = assets[collateral];
        Asset memory debtAsset = assets[debt];
        (
            uint256 maxAmountCollateralToLiquidate,
            uint256 act
        ) = _actualDebtToLiquidate(collateral, debt, user, debtToCover);
        uint256 currentAvailableCollateral = collateralAsset
            .underlying
            .balanceOf(address(collateralAsset.creditToken));
        require(
            currentAvailableCollateral >= maxAmountCollateralToLiquidate,
            "not enough collateral to liquidate"
        );
        debtAsset.debtToken.burn(user, act);
        uint256 releaseableOnCurrentChain = collateralAsset
            .creditToken
            .unlockedBalanceOf(user);
        if (releaseableOnCurrentChain > 0) {
            collateralAsset.creditToken.burn(
                user,
                onBehalfOf,
                releaseableOnCurrentChain > maxAmountCollateralToLiquidate
                    ? maxAmountCollateralToLiquidate
                    : releaseableOnCurrentChain
            );
        }
        // if enough collateral on curre1nt chain, it's done
        if (releaseableOnCurrentChain >= maxAmountCollateralToLiquidate) {
            return act;
        }
        // burn CreditToken on other chains
        uint256 amountToBurn = maxAmountCollateralToLiquidate -
            releaseableOnCurrentChain;
        _liquidateOnOtherChain(user, onBehalfOf, collateral, amountToBurn);
        return act;
    }

    function unLockFor(
        address asset,
        uint256 amount,
        uint256 srcChainId
    ) external override {
        require(
            _healthFactorAfterDecrease(msg.sender, asset, amount, 0) >= BASE,
            "health factor is too low"
        );
        assets[asset].creditToken.unlockFor(msg.sender, amount, srcChainId);
        emit LockReleased(
            msg.sender,
            asset,
            assets[asset].underlying.symbol(),
            amount,
            srcChainId,
            msg.sender
        );
    }

    function _liquidateOnOtherChain(
        address user,
        address onBehalfOf,
        address asset,
        uint256 amountToBurn
    ) internal {
        Asset memory collateralAsset = assets[asset];
        uint256[] memory _chainIds = collateralAsset.creditToken.chainIds();
        for (uint256 i = 0; i < _chainIds.length; i++) {
            uint256 chainId = _chainIds[i];
            uint256 lockedFrom = collateralAsset.creditToken.amountLockedFrom(
                user,
                chainId
            );
            if (lockedFrom == 0) {
                continue;
            }
            uint256 amountToBurnFromChain = amountToBurn > lockedFrom
                ? lockedFrom
                : amountToBurn;
            amountToBurn -= amountToBurnFromChain;
            collateralAsset.creditToken.unlockFor(
                user,
                amountToBurnFromChain,
                chainId
            );
            emit LockReleased(
                user,
                asset,
                collateralAsset.symbol,
                amountToBurnFromChain,
                chainId,
                onBehalfOf
            );
            if (amountToBurn == 0) {
                break;
            }
        }
    }

    struct AvailableCollateralToLiquidateLocalVars {
        uint256 userCompoundedBorrowBalance;
        uint256 liquidationBonus;
        uint256 collateralPrice;
        uint256 debtAssetPrice;
        uint256 maxAmountCollateralToLiquidate;
        uint256 debtAssetDecimals;
        uint256 collateralDecimals;
    }

    function _calculateAvailableCollateralToLiquidate(
        address collateralAsset,
        address debtAsset,
        uint256 debtToCover,
        uint256 userCollateralBalance
    ) internal view returns (uint256, uint256) {
        uint256 collateralAmount = 0;
        uint256 debtAmountNeeded = 0;
        AvailableCollateralToLiquidateLocalVars memory vars;
        vars.collateralPrice = priceOracle.getPriceInUsd(
            assets[collateralAsset].symbol
        );
        vars.debtAssetPrice = priceOracle.getPriceInUsd(
            assets[debtAsset].symbol
        );
        vars.collateralDecimals = assets[collateralAsset].underlying.decimals();
        vars.debtAssetDecimals = assets[debtAsset].underlying.decimals();
        vars.maxAmountCollateralToLiquidate =
            (vars.debtAssetPrice *
                debtToCover *
                (10 ** vars.collateralDecimals)) /
            (vars.collateralPrice * (10 ** vars.debtAssetDecimals));
        if (vars.maxAmountCollateralToLiquidate > userCollateralBalance) {
            collateralAmount = userCollateralBalance;
            debtAmountNeeded =
                (vars.collateralPrice *
                    collateralAmount *
                    (10 ** vars.debtAssetDecimals)) /
                (vars.debtAssetPrice * (10 ** vars.collateralDecimals));
        } else {
            collateralAmount = vars.maxAmountCollateralToLiquidate;
            debtAmountNeeded = debtToCover;
        }
        return (collateralAmount, debtAmountNeeded);
    }
}