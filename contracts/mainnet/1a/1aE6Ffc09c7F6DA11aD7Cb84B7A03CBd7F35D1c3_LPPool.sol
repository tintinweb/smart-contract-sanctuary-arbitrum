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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

library DataTypes {
    struct LPAmountInfo {
        uint256 amount;
        uint256 initValue;
        address lPAddress;
        uint256 createTime;
        uint256 reservationTime;
        uint256 purchaseHeightInfo;
    }

    struct LPPendingInit {
        uint256 amount;
        address lPAddress;
        uint256 createTime;
        uint256 purchaseHeightInfo;
    }

    struct PositionDetails {
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        uint256 entryFundingRate;
        int256 unrealisedPnl;
        uint256 lastIncreasedTime;
        bool isLong;
    }

    struct IncreaseHedgingPool {
        address[] path;
        address indexToken;
        uint256 amountIn;
        uint256 sizeDelta;
        uint256 acceptablePrice;
    }

    struct DecreaseHedgingPool {
        address[] path;
        address indexToken;
        uint256 sizeDelta;
        uint256 acceptablePrice;
        uint256 collateralDelta;
    }

    struct HedgingAggregatorInfo {
        uint256 customerId;
        uint256 productId;
        uint256 amount;
        uint256 releaseHeight;
    }

    enum TransferHelperStatus {
        TOTHIS,
        TOLP,
        TOGMX,
        TOCDXCORE,
        TOMANAGE,
        GUARDIANW
    }

    struct Hedging {
        bool isSell;
        address token;
        uint256 amount;
        uint256 releaseHeight;
    }
}

// SPDX-License-Identifier: UNLICENSED

/// This contract is responsible for LP investment record management.

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../library/common/DataTypes.sol";

contract LPPool is Ownable, ReentrancyGuard {
    address public proxy;
    mapping(address => DataTypes.LPAmountInfo[]) LPAmountPool;
    DataTypes.LPPendingInit[] LPPendingInitList;
    DataTypes.HedgingAggregatorInfo[] productHedgingAggregatorPool;

    constructor(address _proxy) {
        proxy = _proxy;
    }

    /**
     * notice Update the agency contract address.
     * @param _proxy Contract address.
     */
    function updateProxy(address _proxy) public onlyOwner {
        proxy = _proxy;
    }

    /**
     * notice Make an appointment to withdraw money and record the appointment time.
     * @param lPAddress Contract address.
     * @param purchaseHeightInfo Deposit height record.
     */
    function reservationWithdrawal(address lPAddress, uint256 purchaseHeightInfo) external onlyProxy returns (bool) {
        DataTypes.LPAmountInfo[] storage lPAddressInfo = LPAmountPool[lPAddress];
        require(lPAddressInfo.length > 0, "LPPoolManager: data does not exist");
        for (uint256 i = 0; i < lPAddressInfo.length; i++) {
            if (purchaseHeightInfo == lPAddressInfo[i].purchaseHeightInfo) {
                lPAddressInfo[i].reservationTime = block.timestamp;
            }
        }
        return true;
    }

    /// @dev New LP investment record.
    function addLPAmountInfo(uint256 _amount, address _lPAddress) external onlyProxy returns (bool) {
        LPPendingInitList.push(
            DataTypes.LPPendingInit({
                amount: _amount,
                lPAddress: _lPAddress,
                createTime: block.timestamp,
                purchaseHeightInfo: block.number
            })
        );
        return true;
    }

    /// @dev LP investment net contract update.
    function dealLPPendingInit(uint256 coefficient) external onlyProxy returns (bool) {
        if (LPPendingInitList.length == 0) {
            return true;
        }
        for (uint256 i = 0; i < LPPendingInitList.length; i++) {
            DataTypes.LPAmountInfo memory lPAmountInfo = DataTypes.LPAmountInfo({
                amount: LPPendingInitList[i].amount,
                initValue: coefficient,
                lPAddress: LPPendingInitList[i].lPAddress,
                createTime: LPPendingInitList[i].createTime,
                reservationTime: 0,
                purchaseHeightInfo: LPPendingInitList[i].purchaseHeightInfo
            });
            LPAmountPool[LPPendingInitList[i].lPAddress].push(lPAmountInfo);
        }
        delete (LPPendingInitList);
        return true;
    }

    /// @dev LP withdrawal processing.
    function deleteLPAmountInfoByParam(
        address lPAddress,
        uint256 purchaseHeightInfo
    ) external onlyProxy returns (bool) {
        DataTypes.LPAmountInfo[] storage lPAddressInfo = LPAmountPool[lPAddress];
        for (uint256 i = 0; i < lPAddressInfo.length; i++) {
            if (purchaseHeightInfo == lPAddressInfo[i].purchaseHeightInfo) {
                lPAddressInfo[i] = lPAddressInfo[lPAddressInfo.length - 1];
                lPAddressInfo.pop();
            }
        }
        return true;
    }

    /// @dev LP investment base update.
    function updateInitValue(address lPAddress, uint256 purchaseHeightInfo, uint256 _initValue) private returns (bool) {
        DataTypes.LPAmountInfo[] storage lPAddressInfo = LPAmountPool[lPAddress];
        for (uint256 i = 0; i < lPAddressInfo.length; i++) {
            if (purchaseHeightInfo == lPAddressInfo[i].purchaseHeightInfo) {
                lPAddressInfo[i].initValue = _initValue;
            }
        }
        return true;
    }

    /// @dev Hedging pool adds hedging data.
    function addHedgingAggregator(
        DataTypes.HedgingAggregatorInfo memory hedgingAggregator
    ) external onlyProxy returns (bool) {
        productHedgingAggregatorPool.push(hedgingAggregator);
        return true;
    }

    /// @dev Processing hedge pool
    function deleteHedgingAggregator(uint256 _releaseHeight) external onlyProxy returns (bool) {
        uint256 hedgingLocation;
        uint256 poolLength = productHedgingAggregatorPool.length;
        require(productHedgingAggregatorPool.length > 0, "CustomerManager: productHedgingAggregatorPool is null");
        for (uint256 i = 0; i < productHedgingAggregatorPool.length; i++) {
            if (productHedgingAggregatorPool[i].releaseHeight > _releaseHeight) {
                hedgingLocation = i;
                break;
            }
        }
        if (hedgingLocation == 0) {
            delete productHedgingAggregatorPool;
        } else {
            uint256 lastHedgingLocation = hedgingLocation;
            for (uint256 i = 0; i < poolLength - hedgingLocation; i++) {
                productHedgingAggregatorPool[i] = productHedgingAggregatorPool[lastHedgingLocation];
                lastHedgingLocation++;
            }
            for (uint256 i = 0; i <= hedgingLocation - 1; i++) {
                productHedgingAggregatorPool.pop();
            }
        }
        return true;
    }

    function getProductHedgingAggregatorPool() external view returns (DataTypes.HedgingAggregatorInfo[] memory) {
        return productHedgingAggregatorPool;
    }

    function getLPPendingInit() external view returns (DataTypes.LPPendingInit[] memory) {
        return LPPendingInitList;
    }

    function getLPAmountInfo(address lPAddress) external view returns (DataTypes.LPAmountInfo[] memory) {
        return LPAmountPool[lPAddress];
    }

    function getLPAmountInfoByParams(
        address lPAddress,
        uint256 purchaseHeightInfo
    ) external view returns (DataTypes.LPAmountInfo memory) {
        DataTypes.LPAmountInfo[] storage lPAddressInfo = LPAmountPool[lPAddress];
        DataTypes.LPAmountInfo memory result;
        for (uint256 i = 0; i < lPAddressInfo.length; i++) {
            if (purchaseHeightInfo == lPAddressInfo[i].purchaseHeightInfo) {
                result = lPAddressInfo[i];
            }
        }
        return result;
    }

    modifier onlyProxy() {
        require(proxy == msg.sender, "Ownable: caller is not the proxy");
        _;
    }
}