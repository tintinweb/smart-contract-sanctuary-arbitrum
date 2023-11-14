// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// //SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IKeepers {
    function indexOf(address _keeper) external view returns (uint256);
    function isKeeperNode(address _address) external view returns (bool);
    function isCouncil(address _address) external view returns (bool);
    function council() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IReferralRegistry {
    struct ReferralInfo {
        address owner;
        uint256 ownerRatio;
        uint256 buyerRatio;
    }

    event ReferralCodeRegistered(
        bytes32 indexed referralCode,
        address indexed owner,
        uint256 ownerRatio,
        uint256 buyerRatio
    );

    function emitReferralCodeRegistered(
        bytes32 referralCode,
        address owner,
        uint256 ownerRatio,
        uint256 buyerRatio
    ) external;

    function emitReferralCodeRebateUpdated(
        address contractAddress,
        address _paymentToken,
        bytes32 referralCode,
        uint256 rebate
    ) external;

    function registerReferralCode(
        bytes32 referralCode,
        uint256 ownerRatio,
        uint256 buyerRatio
    ) external;

    function getReferralInfo(
        bytes32 referralCode
    ) external view returns (ReferralInfo memory);

    function getReferralCodeOwner(
        bytes32 referralCode
    ) external view returns (address);

    function getReferralCodeRatios(
        bytes32 referralCode
    ) external view returns (uint256 ownerRatio, uint256 buyerRatio);

    function isReferralCodeRegistered(
        bytes32 referralCode
    ) external view returns (bool);

     function calculateNetValue(
        uint256 fullItemPrice,
        bool isBuyerAffiliated,
        uint256 baseFeePercent,
        uint256 discountRatio // Ratio between the discount and reward percentages
    )
        external
        pure
        returns (
            uint256 buyerNetPrice, // Net price for the buyer
            uint256 sellerNetProceeds, // Net proceeds for the seller
            uint256 affiliatorNetReward, // Net reward for the affiliator
            uint256 tokenHoldersNetReward // Net reward for token holders
        );

    function setReferralCodeAsTC(bytes32 referralCode, address user) external;

    function getReferralCode(address user) external view returns (bytes32);
}

// //SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Strings} from "../utils/Strings.sol";
import {Role, TradeStatus} from "../Users/IUsers.sol";
import {IReferralRegistry} from "../Referrals/IReferralRegistry.sol";

struct Sticker {
    string name;
    string material;
    uint8 slot;
    string imageLink;
}

// struct FloatInfo {
//     string value;
//     string min;
//     string max;
// }

struct SkinInfo {
    string floatValues; // "[0.00, 0.00, 0.000000]" (max, min, value)
    uint256 paintSeed; // ranging from 1 to 1000, determines the unique pattern of a skin, such as the placement of the artwork, wear, and color distribution.
    uint256 paintIndex; // Paint index is a fixed value for each skin and does not change across different instances of the same skin. Ex. the AWP Dragon Lore has a paint index of 344. 
}

struct TradeUrl {
    uint256 partner;
    string token;
}

enum PriceType {
    WETH,
    USDC,
    USDT
}

struct UserInteraction {
    //uint256 contractIndex;
    address contractAddress;
    Role role;
    TradeStatus status;
}

struct TradeInfo {
    address contractAddress;
    address seller;
    TradeUrl sellerTradeUrl;
    address buyer;
    TradeUrl buyerTradeUrl;
    string itemMarketName;
    string inspectLink;
    string itemImageUrl;
    uint256 weiPrice;
    uint256 averageSellerDeliveryTime;
    SkinInfo skinInfo;
    TradeStatus status;
    Sticker[] stickers;
    string weaponType;
    PriceType priceType;
    string assetId;
}

interface ITradeFactory {
    // Trade Contract
    function removeAssetIdUsed(string memory _assetId, address sellerAddrss) external returns (bool);

    function onStatusChange(TradeStatus status, TradeStatus prevStatus, string memory data, address sellerAddress, address buyerAddress) external;

    //Users
    function isThisTradeContract(address contractAddress)
        external
        view
        returns (bool);

    function getTradeDetailsByAddress(address tradeAddrs)
        external
        view
        returns (TradeInfo memory result);

    
    function baseFee() external view returns (uint256);

    function buyAssistoor() external view returns (address);

    function totalContracts() external view returns (uint256);
}

// //SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

enum TradeStatus {
    ForSale, // Seller Lists Item
    SellerCancelled, // Seller Cancels Item
    BuyerCommitted, // Buyer Commits coins to Buy
    BuyerCancelled, // Buyer Cancels Commitment
    SellerCommitted, // Seller Commits to Sell
    SellerCancelledAfterBuyerCommitted, // Seller Cancels After Buyer Commits (refunds buyer)
    Completed, // Trade Completed
    Disputed, // Trade Disputed
    Resolved, // Trade Resolved
    Clawbacked // Trade Clawbacked
}

enum Role {
    BUYER,
    SELLER
}

import {PriceType} from "../TradeFactory/ITradeFactory.sol";

interface IUsers {
    function warnUser(address _user) external;

    function banUser(address _user) external;

    function isBanned(address _user) external view returns (bool);

    function repAfterTrade(address _user, bool isPositive) external;

    function startDeliveryTimer(address contractAddress, address user) external;

    function endDeliveryTimer(address contractAddress, address user) external;

    function getAverageDeliveryTime(address user) external view returns (uint256);

    function addUserInteractionStatus(address tradeAddress, Role role,  address userAddress, TradeStatus status) external;

    function changeUserInteractionStatus(address tradeAddress, address userAddress, TradeStatus status) external;

    function setAssetIdUsed(string memory _assetId, address sellerAddrss, address tradeAddrss) external returns (bool);

    function removeAssetIdUsed(string memory _assetId, address sellerAddrss) external returns (bool);

    function hasAlreadyListedItem(string memory _assetId, address sellerAddrss) external view returns (bool);

    function emitNewTrade(address seller, address buyer, bytes32 refCode, PriceType priceType, uint256 value) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IKeepers} from "../Keepers/IKeepers.sol";
import {ITradeFactory, PriceType, UserInteraction, Role, TradeStatus, TradeInfo} from "../TradeFactory/ITradeFactory.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error NotFactory();
error NotCouncil();
error NotTradeContract();
error NotKeepersOrTradeContract();
error TradeNotCompleted();
error AlreadyReppedAsBuyer();
error AlreadyReppedAsSeller();
error NotPartOfTrade();
error ZeroTradeAddress();
error AlreadyRepresentedAsBuyer();
error AlreadyRepresentedAsSeller();

contract Users is ReentrancyGuard {
    struct User {
        uint256 reputationPos;
        uint256 reputationNeg;
        uint256 totalTrades;
        uint256 warnings;
        bool isBanned;
        DeliveryTimes deliveryInfo;
        uint256 totalTradesAsSeller;
        uint256 totalTradesAsBuyer;
    }

    event NewTrade(
        address indexed seller,
        address indexed buyer,
        bytes32 indexed refCode,
        PriceType priceType,
        uint256 value
    );

    function emitNewTrade(
        address seller,
        address buyer,
        bytes32 refCode,
        PriceType priceType,
        uint256 value
    ) external onlyTradeContracts(msg.sender) {
        ++users[seller].totalTradesAsSeller;
        ++users[buyer].totalTradesAsBuyer;
        emit NewTrade(seller, buyer, refCode, priceType, value);
    }

    struct DeliveryTimes {
        uint256 totalStarts;
        uint256 totalDeliveryTime;
        uint256 numberOfDeliveries;
        uint256 averageDeliveryTime;
    }

    mapping(address => User) public users;
    mapping(address => mapping(address => uint256)) UserToContractDeliveryStartTime;

    IKeepers public keepers;
    ITradeFactory public factory;

    constructor(address _keepers) {
        keepers = IKeepers(_keepers);
    }

    /**
     * @notice Function to change the keepers and factory contracts
     * @dev This is used when the keepers or factory contracts are upgraded
     * @dev This function can only be called by a council member
     * @param _factoryAddress The address of the new factory contract
     * @param _keepers The address of the new keepers contract
     */
    function changeContracts(address _factoryAddress, address _keepers) external {
        if (!keepers.isCouncil(msg.sender)) {
            revert NotCouncil();
        }
        factory = ITradeFactory(_factoryAddress);
        keepers = IKeepers(_keepers);
    }

    modifier onlyTradeContracts(address contractAddress) {
        if (
            msg.sender != contractAddress ||
            !factory.isThisTradeContract(contractAddress)
        ) {
            revert NotTradeContract();
        }
        _;
    }

    modifier onlyKeepersOrTradeContracts(address contractAddress) {
        // Check if the sender is a keeper
        bool isKeeperOrKeeperNode = (keepers.indexOf(msg.sender) != 0 || keepers.indexOf(tx.origin) != 0 || keepers.isKeeperNode(msg.sender));
        
        // Check if the sender is a trade contract
        bool isTradeContract = msg.sender == contractAddress && factory.isThisTradeContract(contractAddress);
        
        if (!isKeeperOrKeeperNode) {
            if(!isTradeContract){
                revert NotKeepersOrTradeContract();
            }
        }
        _;
    }

    /**
     * @notice Give user a warning
     * @dev This function can only be called by a keeper or a trade contract
     * @param _user The address of the user to warn
     */
    function warnUser(address _user) external onlyKeepersOrTradeContracts(msg.sender) {
        User storage user = users[_user];
        user.reputationNeg += 3;
        ++user.warnings;
        if (user.warnings >= 3) {
            user.isBanned = true;
        }
    }

    /**
     * @notice Ban a user
     * @dev This function can only be called by a keeper or a trade contract
     * @param _user The address of the user to ban
     */
    function banUser(address _user) external onlyKeepersOrTradeContracts(msg.sender) {
        User storage user = users[_user];
        user.isBanned = true;
    }

    /**
     * @notice Unban a user
     * @param _user The address of the user to unban
     * @dev This function can only be called by a keeper or a trade contract
     */
    function unbanUser(address _user) external onlyKeepersOrTradeContracts(msg.sender) {
        User storage user = users[_user];
        user.isBanned = false;
    }

    /**
     * @notice Get user data
     * @param user The address of the user
     * @return User struct
     */
    function getUserData(address user) external view returns (User memory) {
        return users[user];
    }

    /**
     * @notice Get if user is banned
     * @param _user The address of the user
     * @return true if user is banned, false otherwise
     */
    function isBanned(address _user) external view returns (bool) {
        return users[_user].isBanned;
    }

    /**
     * @notice Give reputation to a user
     * @param _user The address of the user to give reputation to
     * @param isPositive Whether the reputation is positive or negative
     */
    function _repAfterTrade(address _user, bool isPositive) private {
        User storage user = users[_user];
        if (isPositive) {
            ++user.reputationPos;
        } else {
            ++user.reputationNeg;
        }
    }

    /**
     * @notice Start delivery timer for a seller
     * @dev This function can only be called by a trade contract
     * @param contractAddress The address of the trade contract
     * @param user The address of the seller
     */
    function startDeliveryTimer(
        address contractAddress,
        address user
    ) external onlyTradeContracts(contractAddress) {
        UserToContractDeliveryStartTime[user][contractAddress] = block
            .timestamp;
        ++users[user].deliveryInfo.totalStarts;
    }

    /**
     * @notice End delivery timer for a seller
     * @dev This function can only be called by a trade contract
     * @param contractAddress The address of the trade contract
     * @param user The address of the seller
     */
    function endDeliveryTimer(
        address contractAddress,
        address user
    ) external onlyTradeContracts(contractAddress) {
        uint256 deliveryTime = block.timestamp -
            UserToContractDeliveryStartTime[user][contractAddress];
        users[user].deliveryInfo.totalDeliveryTime += deliveryTime;
        ++users[user].deliveryInfo.numberOfDeliveries;
        users[user].deliveryInfo.averageDeliveryTime =
            users[user].deliveryInfo.totalDeliveryTime /
            users[user].deliveryInfo.numberOfDeliveries;
    }

    /**
     * @notice Get the average delivery time for a seller
     * @param user The address of the seller
     * @return Average delivery time
     */
    function getAverageDeliveryTime(
        address user
    ) external view returns (uint256) {
        return users[user].deliveryInfo.averageDeliveryTime;
    }

    //User to Trades
    mapping(address => UserInteraction[]) userTrades;
    mapping(address => mapping(address => uint256)) tradeAddrsToUserAddrsInteractionIndex;

    /**
     * @notice Add a trade to a user's interaction list
     * @dev This function can only be called by a trade contract
     * @param tradeAddress The address of the trade contract
     * @param role The role of the user in the trade
     * @param userAddress The address of the user
     * @param status The status of the trade
     */
    function addUserInteractionStatus(
        address tradeAddress,
        Role role,
        address userAddress,
        TradeStatus status
    ) external onlyTradeContracts(tradeAddress) {
        userTrades[userAddress].push(
            UserInteraction(tradeAddress, role, status)
        );
        tradeAddrsToUserAddrsInteractionIndex[tradeAddress][userAddress] =
            userTrades[userAddress].length -
            1;
    }

    /**
     * @notice Change the status of a trade in a user's interaction list
     * @dev This function can only be called by a trade contract
     * @param tradeAddress The address of the trade contract
     * @param userAddress The address of the user
     * @param status The status of the trade
     */
    function changeUserInteractionStatus(
        address tradeAddress,
        address userAddress,
        TradeStatus status
    ) external onlyTradeContracts(tradeAddress) {
        uint256 iIndex = tradeAddrsToUserAddrsInteractionIndex[tradeAddress][
            userAddress
        ];
        userTrades[userAddress][iIndex].status = status;
    }

    /**
     * @notice Get the total number of trades in a user's interaction list
     * @param userAddrss The address of the user
     * @return The total number of trades in a user's interaction list
     */
    function getUserTotalTradeUIs(
        address userAddrss
    ) external view returns (uint256) {
        return userTrades[userAddrss].length;
    }

    /**
     * @notice Get a trade in a user's interaction list by index
     * @param userAddrss The address of the user
     * @param i The index of the trade
     * @return UserInteraction struct
     */
    function getUserTradeUIByIndex(
        address userAddrss,
        uint256 i
    ) external view returns (UserInteraction memory) {
        return userTrades[userAddrss][i];
    }

    mapping(address => mapping(Role => bool)) tradeAdrsToRoleToHasRep;

    /**
     * @notice Give reputation to a user after a trade
     * @dev This function can only be called by buyer or seller of a trade contract
     * @param tradeAddrs The address of the trade contract
     * @param isPositive Whether the reputation is positive or negative
     */
    function repAfterTrade(
        address tradeAddrs,
        bool isPositive
    ) external nonReentrant {
        if (tradeAddrs == address(0)) {
            revert ZeroTradeAddress();
        }

        TradeInfo memory _tradeContract = factory.getTradeDetailsByAddress(
            tradeAddrs
        );

        if (_tradeContract.status < TradeStatus.Completed) {
            revert TradeNotCompleted();
        }

        if (msg.sender != _tradeContract.buyer) {
            if (msg.sender != _tradeContract.seller) {
                revert NotPartOfTrade();
            }
        }

        if (msg.sender == _tradeContract.buyer) {
            if (tradeAdrsToRoleToHasRep[tradeAddrs][Role.BUYER]) {
                revert AlreadyRepresentedAsBuyer();
            }
            tradeAdrsToRoleToHasRep[tradeAddrs][Role.BUYER] = true;
            _repAfterTrade(_tradeContract.seller, isPositive);
        } else if (msg.sender == _tradeContract.seller) {
            if (tradeAdrsToRoleToHasRep[tradeAddrs][Role.SELLER]) {
                revert AlreadyRepresentedAsSeller();
            }
            tradeAdrsToRoleToHasRep[tradeAddrs][Role.SELLER] = true;
            _repAfterTrade(_tradeContract.buyer, isPositive);
        }
    }

    /**
     * @notice Check if a user has given reputation to a trade
     * @param tradeAddrs The address of the trade contract
     * @return hasBuyer
     * @return hasSeller 
     * @return isTime 
     */
    function hasMadeRepOnTrade(
        address tradeAddrs
    ) external view returns (bool hasBuyer, bool hasSeller, bool isTime) {
        TradeInfo memory _tradeContract = factory.getTradeDetailsByAddress(
            tradeAddrs
        );

        isTime = (_tradeContract.status >= TradeStatus.Completed);

        hasBuyer = tradeAdrsToRoleToHasRep[tradeAddrs][Role.BUYER];

        hasSeller = tradeAdrsToRoleToHasRep[tradeAddrs][Role.SELLER];
    }

    mapping(string => mapping(address => address))
        public assetIdFromUserAddrssToTradeAddrss;

    /**
     * @notice Remove an asset ID from a user's address mapping
     * @dev This function can only be called by a trade contract
     * @param _assetId The asset ID
     * @param sellerAddrss The address of the seller
     */
    function removeAssetIdUsed(
        string memory _assetId,
        address sellerAddrss
    ) external onlyTradeContracts(msg.sender) returns (bool) {
        assetIdFromUserAddrssToTradeAddrss[_assetId][sellerAddrss] = address(0);
        return true;
    }

    /**
     * @notice Check if a user has already listed an item
     * @param _assetId The asset ID
     * @param sellerAddrss The address of the seller
     * @return true if the user has already listed an item, false otherwise
     */
    function hasAlreadyListedItem(
        string memory _assetId,
        address sellerAddrss
    ) external view returns (bool) {
        if (
            assetIdFromUserAddrssToTradeAddrss[_assetId][sellerAddrss] ==
            address(0)
        ) {
            return false;
        } else {
            return true;
        }
    }

    /**
     * @notice Set the Asset Id used
     * @dev This function can only be called by the factory contract
     * @param _assetId The asset ID
     * @param sellerAddrss The address of the seller
     * @param tradeAddrss The address of the trade contract
     */
    function setAssetIdUsed(
        string memory _assetId,
        address sellerAddrss,
        address tradeAddrss
    ) external returns (bool) {
        if (msg.sender != address(factory)) {
            revert NotFactory();
        }
        assetIdFromUserAddrssToTradeAddrss[_assetId][
            sellerAddrss
        ] = tradeAddrss;
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}