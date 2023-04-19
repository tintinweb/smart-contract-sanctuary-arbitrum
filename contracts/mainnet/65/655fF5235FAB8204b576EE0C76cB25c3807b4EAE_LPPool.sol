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

    struct HedgeTreatmentInfo {
        bool isSell;
        address token;
        uint256 amount;
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
        bool hasUnrealisedProfit;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title Initializable
 *
 * @dev Deprecated. This contract is kept in the Upgrades Plugins for backwards compatibility purposes.
 * Users should use openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol instead.
 *
 * Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.9;

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

    // constructor() {
    //     _status = _NOT_ENTERED;
    // }

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

    function _initNonReentrant() internal virtual {
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: UNLICENSED

/// This contract is responsible for LP investment record management.

pragma solidity ^0.8.9;

import {Initializable} from "../library/common/Initializable.sol";
import {ReentrancyGuard} from "../library/common/ReentrancyGuard.sol";
import "../library/common/DataTypes.sol";

contract LPPool is Initializable, ReentrancyGuard {
    address public proxy;
    address public ownerAddress;
    mapping(address => DataTypes.LPAmountInfo[]) LPAmountPool;
    DataTypes.LPPendingInit[] LPPendingInitList;
    DataTypes.HedgingAggregatorInfo[] productHedgingAggregatorPool;

    /// @dev Initialise important addresses for the contract.
    function initialize(address _proxy) external initializer {
        _initNonReentrant();
        proxy = _proxy;
        ownerAddress = msg.sender;
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

    modifier onlyOwner() {
        require(ownerAddress == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyProxy() {
        require(proxy == msg.sender, "Ownable: caller is not the proxy");
        _;
    }
}