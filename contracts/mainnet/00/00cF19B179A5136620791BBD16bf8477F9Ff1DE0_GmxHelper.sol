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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

pragma solidity 0.8.11;

import {IVault as IGmxVault} from "./interfaces/gmx/IVault.sol";
import {IPositionRouter} from "./interfaces/gmx/IPositionRouter.sol";
import {IOnBot} from "./interfaces/IOnBot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

struct GmxConfig {
    address vault;
    address glp;
    address fsGlp;
    address glpManager;
    address positionRouter;
    address usdg;
}

contract GmxHelper is Ownable, ReentrancyGuard {
    // GMX contracts
    address public gmxVault;
    address public gmxPositionRouter;

    uint256 public constant BASE_LEVERAGE = 10000; // 1x

    mapping(address => bool) public isKeeper;
    // Modifier for execution roles
    modifier onlyKeeper() {
        require(isKeeper[msg.sender], "GmxHelper: Is not keeper");
        _;
    }

    struct Increase {
        address _trader;
        address _account;
        address[] _path;
        address _indexToken;
        uint256 _amountIn;
        bool _isLong;
        uint256 _acceptablePrice;
        address _traderTokenIn;
        uint256 _traderAmountIn;
        uint256 _traderSizeDelta;
    }
    struct Decrease {
        address _trader;
        address _account;
        address[] _path;
        address _indexToken;
        bool _isLong;
        uint256 _acceptablePrice;
        address _traderCollateralToken;
        uint256 _traderCollateralDelta;
        uint256 _traderSizeDelta;
    }
    struct Close {
        address _trader;
        address _account;
        address[] _path;
        address _indexToken;
        bool _isLong;
        uint256 _sizeDelta;
        uint256 _collateralDelta;
        uint256 _acceptablePrice;
    }

    struct UpdateBalance {
        address _bot;
        uint256 _collateralDelta;
        uint256 _sizeDelta;
        address _indexToken;
        bool _isLong;
    }

    event UpdateBalanceFail(address bot, uint256 collateralDelta, uint256 sizeDelta, address indexToken, bool isLong);
    event SendIncreaseOrderFail(
        address trader,
        address account,
        address indexToken,
        uint256 amountIn,
        bool isLong,
        uint256 acceptablePrice
    );
    event SendDecreaseOrderFail(
        address trader,
        address account,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 acceptablePrice
    );

    constructor(address _gmxVault, address _gmxPositionRouter) {
        gmxVault = _gmxVault;
        gmxPositionRouter = _gmxPositionRouter;
    }

    function setKeeper(address _account, bool _status) external onlyOwner {
        isKeeper[_account] = _status;
    }

    // Handle multiple update balance for user when close position
    function bulkUpdateBalance(UpdateBalance[] memory updateBalances)
        external
        payable
        nonReentrant
        onlyKeeper
        returns (bool)
    {
        for (uint256 index = 0; index < updateBalances.length; index++) {
            try IOnBot(updateBalances[index]._bot).updateBalanceToVault() {} catch {
                emit UpdateBalanceFail(
                    updateBalances[index]._bot,
                    updateBalances[index]._collateralDelta,
                    updateBalances[index]._sizeDelta,
                    updateBalances[index]._indexToken,
                    updateBalances[index]._isLong
                );
            }
        }
        return true;
    }

    function bulkOrders(Increase[] memory increases, Decrease[] memory decreases)
        external
        payable
        nonReentrant
        onlyKeeper
        returns (bool)
    {
        uint256 minExecutionFee = IPositionRouter(gmxPositionRouter).minExecutionFee();
        require(
            msg.value >= (increases.length + decreases.length) * minExecutionFee,
            "GmxHelper: insufficient execution fee."
        );

        for (uint256 index = 0; index < increases.length; index++) {
            Increase memory increase = increases[index];
            uint256 newSizeDelta = this.getIncreaseData(
                increase._account,
                increase._traderTokenIn,
                increase._traderAmountIn,
                increase._traderSizeDelta,
                increase._isLong,
                increase._amountIn
            );
            try
                IOnBot(increase._account).createIncreasePosition{value: minExecutionFee}(
                    increase._trader,
                    increase._path,
                    increase._indexToken,
                    increase._amountIn,
                    0,
                    newSizeDelta,
                    increase._isLong,
                    increase._acceptablePrice,
                    minExecutionFee
                )
            {} catch {
                emit SendIncreaseOrderFail(
                    increase._trader,
                    increase._account,
                    increase._indexToken,
                    increase._amountIn,
                    increase._isLong,
                    increase._acceptablePrice
                );
            }
        }
        //
        for (uint256 index = 0; index < decreases.length; index++) {
            Decrease memory decrease = decreases[index];
            (uint256 newSizeDelta, uint256 newCollateralDetal, ) = this.getDecreaseData(
                decrease._trader,
                decrease._traderCollateralToken,
                decrease._traderCollateralDelta,
                decrease._traderSizeDelta,
                decrease._isLong,
                decrease._account,
                decrease._path[0],
                decrease._indexToken
            );
            try
                IOnBot(decrease._account).createDecreasePosition{value: minExecutionFee}(
                    decrease._trader,
                    decrease._path,
                    decrease._indexToken,
                    newCollateralDetal,
                    newSizeDelta,
                    decrease._isLong,
                    decrease._acceptablePrice,
                    0,
                    minExecutionFee,
                    address(0)
                )
            {} catch {
                emit SendDecreaseOrderFail(
                    decrease._trader,
                    decrease._account,
                    decrease._indexToken,
                    newCollateralDetal,
                    newSizeDelta,
                    decrease._isLong,
                    decrease._acceptablePrice
                );
            }
        }
        return true;
    }

    function bulkTakeProfiStoploss(Close[] memory closes) external payable nonReentrant onlyKeeper returns (bool) {
        uint256 minExecutionFee = IPositionRouter(gmxPositionRouter).minExecutionFee();
        require(msg.value >= (closes.length) * minExecutionFee, "GmxHelper: insufficient execution fee.");

        for (uint256 index = 0; index < closes.length; index++) {
            Close memory closes = closes[index];

            try
                IOnBot(closes._account).createDecreasePosition{value: minExecutionFee}(
                    closes._trader,
                    closes._path,
                    closes._indexToken,
                    closes._collateralDelta,
                    closes._sizeDelta,
                    closes._isLong,
                    closes._acceptablePrice,
                    0,
                    minExecutionFee,
                    address(0)
                )
            {} catch {
                emit SendDecreaseOrderFail(
                    closes._trader,
                    closes._account,
                    closes._indexToken,
                    closes._collateralDelta,
                    closes._sizeDelta,
                    closes._isLong,
                    closes._acceptablePrice
                );
            }
        }
        return true;
    }

    function getPrice(address _token, bool _maximise) public view returns (uint256) {
        return _maximise ? IGmxVault(gmxVault).getMaxPrice(_token) : IGmxVault(gmxVault).getMinPrice(_token);
    }

    function getLeverage(
        address tokenIn,
        uint256 amountIn,
        uint256 sizeDelta,
        bool isLong
    ) public view returns (uint256) {
        IGmxVault _gmxVault = IGmxVault(gmxVault);
        uint256 decimals = _gmxVault.tokenDecimals(tokenIn);

        uint256 price = getPrice(tokenIn, isLong);
        uint256 amountInUsd = (price * amountIn) / (10**decimals);
        uint256 leverage = ((sizeDelta * BASE_LEVERAGE) / amountInUsd);
        return leverage;
    }

    function getIncreaseData(
        address bot,
        address tokenIn,
        uint256 amountIn,
        uint256 sizeDelta,
        bool isLong,
        uint256 fixedMargin
    ) public view returns (uint256) {
        address tokenPlay = IOnBot(bot).getTokenPlay();
        IGmxVault _gmxVault = IGmxVault(gmxVault);

        uint256 tokenPlayPrice = getPriceBySide(tokenPlay, isLong, true);

        uint256 leverage = this.getLeverage(tokenIn, amountIn, sizeDelta, isLong);

        return (((fixedMargin * tokenPlayPrice * leverage) / BASE_LEVERAGE) / (10**_gmxVault.tokenDecimals(tokenPlay))); // sizeDelta
    }

    function getDecreaseData(
        address pAccount,
        address pCollateralToken,
        uint256 pCollateralDelta,
        uint256 pSizeDelta,
        bool isLong,
        address account,
        address collateralToken,
        address indexToken
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 pSize, uint256 pCollateral, , , , , , ) = IGmxVault(gmxVault).getPosition(
            pAccount,
            pCollateralToken,
            indexToken,
            isLong
        );
        pSize = pSizeDelta + pSize;
        pCollateral = pCollateralDelta + pCollateral;
        (uint256 size, uint256 collateral, , , , , , ) = IGmxVault(gmxVault).getPosition(
            account,
            collateralToken,
            indexToken,
            isLong
        );
        if (pSize == 0 || pCollateral == 0) {
            // Close
            return (size, 0, BASE_LEVERAGE);
        }

        uint256 ratio = pSizeDelta == 0
            ? (pCollateralDelta * BASE_LEVERAGE) / pCollateral
            : (pSizeDelta * BASE_LEVERAGE) / pSize;

        if (pSize == pSizeDelta || ratio > (100 * BASE_LEVERAGE)) {
            // Close
            return (
                size, // 0
                0, // 1
                ratio
            );
        }

        return (
            (ratio * size) / BASE_LEVERAGE, // 0
            (ratio * collateral) / BASE_LEVERAGE, // 1
            ratio
        );
    }

    function getPriceBySide(
        address token,
        bool isLong,
        bool isIncrease
    ) public view returns (uint256 price) {
        if (isIncrease) {
            return isLong ? getPrice(token, true) : getPrice(token, false);
        } else {
            return isLong ? getPrice(token, false) : getPrice(token, true);
        }
    }

    function _validatePositionLimit(
        address _bot,
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _pendingSize,
        bool _isLong,
        uint256 positionLimit
    ) private view {
        (uint256 size, , , , , , , ) = IGmxVault(gmxVault).getPosition(
            _account,
            _collateralToken,
            _indexToken,
            _isLong
        );
        require(size + _pendingSize <= positionLimit, "Position limit size");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IPositionRouter {
    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);

    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external payable;

    function increasePositionRequestKeysStart() external view returns (uint256);
    function decreasePositionRequestKeysStart() external view returns (uint256);
    function maxGlobalShortSizes(address _indexToken) external view returns (uint256);
    function minExecutionFee() external view returns (uint256);
    function setPositionKeeper(address keeper, bool isActive) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IVault {
    function taxBasisPoints() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function whitelistedTokens(address) external view returns (bool);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function stableTokens(address) external view returns (bool);

    function poolAmounts(address) external view returns (uint256);

    function globalShortSizes(address) external view returns (uint256);

    function globalShortAveragePrices(address) external view returns (uint256);

    function guaranteedUsd(address) external view returns (uint256);

    function reservedAmounts(address) external view returns (uint256);

    function cumulativeFundingRates(address) external view returns (uint256);

    function getFundingFee(address _token, uint256 _size, uint256 _entryFundingRate) external view returns (uint256);

    function getPositionFee(uint256 _sizeDelta) external view returns (uint256);

    function lastFundingTimes(address) external view returns (uint256);

    function updateCumulativeFundingRate(address _token) external;

    function getFeeBasisPoints(address _token, uint256 _usdgDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);

    function getRedemptionAmount(address _token, uint256 _usdgAmount) external view returns (uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);

    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);

    function decreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256);

    function increasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external;

    function getPositionDelta(address _account, address _collateralToken, address _indexToken, bool _isLong) external view returns (bool, uint256);

    function usdToTokenMin(address _token, uint256 _usdAmount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IOnBot {
    function initialize(
        address _tokenPlay,
        address _positionRouter,
        address _vault,
        address _router,
        address _botFactory,
        address _userAddress
    ) external;

    function botFactoryCollectToken() external returns (uint256);

    function getIncreasePositionRequests(uint256 _count) external returns (
        address,
        address,
        bytes32,
        address,
        uint256,
        uint256,
        bool,
        bool
    );

    function getUser() external view returns (
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    );

    function getTokenPlay() external view returns (address);
    function createIncreasePosition(
        address _trader,
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee
    ) external payable;
    function createDecreasePosition(
        address _trader,
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        address _callbackTarget
    ) external payable;

    function updateBalanceToVault() external;
}