// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IKeepers {
    function isKeeper(address _address) external view returns (bool);
    function isKeeperNode(address _address) external view returns (bool);
    function isCouncil(address _address) external view returns (bool);
    function council() external view returns (address);
    function isVesterUnderCouncilControl(address _address) external view returns (bool);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

error InvalidDiscountRatio(uint256 provided, uint256 max);

// The NetValueCalculator contract calculates the net value for each party involved in a transaction:
// the buyer, the seller, the affiliator, and the token holders.
contract NetValueCalculator {
    // The calculateNetValue function calculates the net value for each party involved in a transaction
    // based on the full item price, whether the buyer is affiliated, the base fee percentage, and the ratio between the discount
    // and rebate percentages.
    //
    // Example:
    // --------
    // Assuming the following input values:
    // - fullItemPrice = 1,000 tokens
    // - isBuyerAffiliated = true
    // - baseFeePercent = 2
    // - discountRatio = 10
    //
    // Steps:
    // 1. Calculate the base fee:
    //    - baseFee = (fullItemPrice * baseFeePercent) / 100
    //    - baseFee = (1,000 * 2) / 100 = 20 tokens
    //
    // 2. Calculate the discounted fee and affiliator reward:
    //    - discountedFee = (baseFee * discountRatio) / 100
    //    - discountedFee = (20 * 10) / 100 = 2 tokens
    //    - affiliatorReward = (baseFee * (50 - discountRatio)) / 100
    //    - affiliatorReward = (20 * (50 - 10)) / 100 = 8 tokens
    //
    // 3. Calculate the net value for the buyer, the seller, the affiliator, and the token holders:
    //    - buyerNetPrice = fullItemPrice - discountedFee
    //    - buyerNetPrice = 1,000 - 2 = 998 tokens
    //    - sellerNetProceeds = fullItemPrice - baseFee
    //    - sellerNetProceeds = 1,000 - 20 = 980 tokens
    //    - tokenHoldersNetReward = baseFee - discountedFee - affiliatorReward
    //    - tokenHoldersNetReward = 20 - 2 - 8 = 10 tokens
    /**
     * @notice Calculates the net value for each party involved in a transaction
     * @param fullItemPrice The full item price in tokens
     * @param isBuyerAffiliated Whether the buyer is affiliated or not
     * @param baseFeePercentTen The base fee percentage multiplied by 10. e.g., 26 represents 2.6%
     * @param discountRatio The ratio between the discount and reward percentages
     * @return buyerNetPrice 
     * @return sellerNetProceeds 
     * @return affiliatorNetReward 
     * @return tokenHoldersNetReward 
     */
    function calculateNetValue(
        uint256 fullItemPrice,
        bool isBuyerAffiliated,
        uint256 baseFeePercentTen, // Now the base fee can have one decimal. e.g., 26 represents 2.6%
        uint256 discountRatio // Ratio between the discount and reward percentages
    )
        external
        pure
        returns (
            uint256 buyerNetPrice, // Net price for the buyer
            uint256 sellerNetProceeds, // Net proceeds for the seller
            uint256 affiliatorNetReward, // Net reward for the affiliator
            uint256 tokenHoldersNetReward // Net reward for token holders
        )
    {
        if (discountRatio > 50) {
            revert InvalidDiscountRatio(discountRatio, 50);
        }

        // Calculate the base fee
        uint256 baseFee = (fullItemPrice * baseFeePercentTen) / 1000; // divide by 1000 instead of 100

        uint256 discountedFee;
        // Calculate the discounted fee and affiliator reward if the buyer is affiliated
        if (isBuyerAffiliated) {
            discountedFee = (fullItemPrice * baseFeePercentTen * discountRatio) / 100000; // divide by 100000 instead of 10000
            affiliatorNetReward = (fullItemPrice * baseFeePercentTen * (50 - discountRatio)) / 100000; // divide by 100000 instead of 10000
        } else {
            discountedFee = 0;
            affiliatorNetReward = 0;
        }

        // Calculate the buyer net price
        buyerNetPrice = fullItemPrice - discountedFee;

        // Calculate the seller net proceeds
        sellerNetProceeds = fullItemPrice - baseFee;
        // Calculate the token holders net reward
        tokenHoldersNetReward = baseFee - discountedFee - affiliatorNetReward;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {NetValueCalculator} from "./NetValueCalculator.sol";
import {ITradeFactory} from "../TradeFactory/ITradeFactory.sol";
import {IKeepers} from "../Keepers/IKeepers.sol";

error ZeroAddress();
error InvalidReferralCode(string reason);
error InvalidRatios(string reason);
error Unauthorized(string reason);

error NotTradeContract();
error ReferralCodeNotRegistered(string reason);
error OwnerOfReferralCode(string reason);
error ReferralCodeAlreadySet(string reason);


contract ReferralRegistry is NetValueCalculator {
    ITradeFactory public factory;
    IKeepers private keepers;

    constructor(address _keepers) {
        if (_keepers == address(0)) {
            revert ZeroAddress();
        }
        keepers = IKeepers(_keepers);
    }

    mapping(bytes32 => mapping(address => uint256)) rebatePerCodePerPaymentToken;

    /**
     * @notice Get the rebate for a referral code and payment token
     * @param referralCode The referral code
     * @param paymentToken The payment token address
     * @return The rebate for the referral code and payment token
     */
    function getRebatePerCodePerPaymentToken(bytes32 referralCode, address paymentToken) external view returns (uint256) {
        return rebatePerCodePerPaymentToken[referralCode][paymentToken];
    }

    struct ReferralInfo {
        address owner;
        uint256 ownerRatio;
        uint256 buyerRatio;        
    }

    modifier onlyTradeContracts(address contractAddress) {
        if (msg.sender != contractAddress) {
            revert NotTradeContract();            
        }
        if(factory.isThisTradeContract(contractAddress)){
            revert NotTradeContract();
        }
        _;
    }

    // Map to store referral codes with corresponding owner's address and distribution ratios
    mapping(bytes32 => ReferralInfo) private referralInfos;

    mapping(address => bytes32) private userReferralCode;

    mapping(address => bytes32[]) private userCreatedCodes;

    /**
     * @notice Get the referral codes created by a user
     * @param user The user address
     * @return The referral codes created by the user
     */
    function getReferralCodesByUser(address user) external view returns (bytes32[] memory) {
        return userCreatedCodes[user];
    }

    /**
     * @notice Set a referral code for a user
     * @dev This function can only be called by a trade contract
     * @param referralCode The referral code
     * @param user The user address
     */
    function setReferralCodeAsTC(bytes32 referralCode, address user) external onlyTradeContracts(msg.sender) {
        if(user == address(0)){
            revert ZeroAddress();
        }
        _setReferralCode(referralCode, user);
    }

    /**
     * @notice Set a referral code as a user
     * @param referralCode The referral code
     */
    function setReferralCodeAsUser(bytes32 referralCode) external {
        if (referralCode == 0) revert InvalidReferralCode("Referral code cannot be empty");
        if (referralInfos[referralCode].owner == address(0)) revert ReferralCodeNotRegistered("Referral code not registered");
        if (referralInfos[referralCode].owner == msg.sender) revert OwnerOfReferralCode("You are the owner of this referral code");
        if (userReferralCode[msg.sender] == referralCode) revert ReferralCodeAlreadySet("Referral code already set for this user");
        if (containsSpace(referralCode)) revert InvalidReferralCode("Referral code cannot contain spaces");

        _setReferralCode(referralCode, msg.sender);
    }

    /**
     * @notice Change the relying contracts
     * @dev This function can only be called by council
     * @param _factory CSXTradeFactory Address
     * @param _keepers Keepers Contract Address
     */
    function changeContracts(address _factory, address _keepers) external {
        if(!keepers.isCouncil(msg.sender)){
            revert Unauthorized("Only council can change contracts");
        }
        if(_factory == address(0)){
            revert ZeroAddress();
        }
        if(_keepers == address(0)){
            revert ZeroAddress();
        }
        factory = ITradeFactory(_factory);
        keepers = IKeepers(_keepers);
    }

    /**
     * @notice Get the referral code of a user
     * @param user The user address
     * @return The referral code of the user
     */
    function getReferralCode(address user) external view returns (bytes32) {
        return userReferralCode[user];
    }

    /**
     * @notice Set the referral code of a user
     * @dev Private function to set the referral code of a user
     * @param referralCode The referral code
     * @param user The user address
     */
    function _setReferralCode(bytes32 referralCode, address user) private {
        userReferralCode[user] = referralCode;
    }
    

    // Event to be emitted when a referral code is registered
    event ReferralCodeRegistered(
        bytes32 indexed referralCode,
        address indexed owner,
        uint256 ownerRatio,
        uint256 buyerRatio
    );

    event ReferralCodeRebateUpdated(
        address indexed contractAddress,
        bytes32 indexed referralCode,
        address indexed owner,
        address paymentToken,
        uint256 rebate
    );

    /**
     * @notice Emit event when a referral code is registered
     * @dev This function can only be called by a trade contract
     * @param contractAddress The trade contract address
     * @param _paymentToken The payment token address
     * @param referralCode The referral code
     * @param rebate The rebate amount
     */
    function emitReferralCodeRebateUpdated(
        address contractAddress,
        address _paymentToken,
        bytes32 referralCode,
        uint256 rebate
    ) external onlyTradeContracts(contractAddress) {        
        rebatePerCodePerPaymentToken[referralCode][_paymentToken] += rebate;
        address owner = referralInfos[referralCode].owner;
        emit ReferralCodeRebateUpdated(contractAddress, referralCode, owner, _paymentToken, rebate);
    }

    /**
     * @notice Register a referral code with distribution ratios
     * @param referralCode The referral code
     * @param ownerRatio affiliator rebate ratio
     * @param buyerRatio buyer discount ratio
     */
    function registerReferralCode(
        bytes32 referralCode,
        uint256 ownerRatio,
        uint256 buyerRatio
    ) external {
        if (referralCode == 0) revert InvalidReferralCode("Referral code cannot be empty");
        if (referralInfos[referralCode].owner != address(0)) revert InvalidReferralCode("Referral code already registered");
        if (ownerRatio + buyerRatio != 100) revert InvalidRatios("The sum of ownerRatio and buyerRatio must be 100");
        if (containsSpace(referralCode)) revert InvalidReferralCode("Referral code cannot contain spaces");

        referralInfos[referralCode] = ReferralInfo({
            owner: msg.sender,
            ownerRatio: ownerRatio,
            buyerRatio: buyerRatio
        });

        userCreatedCodes[msg.sender].push(referralCode);

        emit ReferralCodeRegistered(
            referralCode,
            msg.sender,
            ownerRatio,
            buyerRatio
        );
    }

    /**
     * @notice Get the referral info of a referral code
     * @param referralCode The referral code
     */
    function getReferralInfo(
        bytes32 referralCode
    ) external view returns (ReferralInfo memory) {
        return referralInfos[referralCode];
    }

    /**
     * @notice Get the owner of a referral code
     * @param referralCode The referral code
     */
    function getReferralCodeOwner(
        bytes32 referralCode
    ) external view returns (address) {
        return referralInfos[referralCode].owner;
    }

    /**
     * @notice Get the distribution ratios of a referral code
     * @param referralCode The referral code
     * @return ownerRatio 
     * @return buyerRatio 
     */
    function getReferralCodeRatios(
        bytes32 referralCode
    ) external view returns (uint256 ownerRatio, uint256 buyerRatio) {
        ownerRatio = referralInfos[referralCode].ownerRatio;
        buyerRatio = referralInfos[referralCode].buyerRatio;
    }

    /**
     * @notice Check if a referral code is registered
     * @param referralCode The referral code
     * @return true if the referral code is registered
     */
    function isReferralCodeRegistered(
        bytes32 referralCode
    ) external view returns (bool) {
        return referralInfos[referralCode].owner != address(0);
    }

    /**
     * @notice Check if a referral code contains a space
     * @dev Helper function to check if a referral code contains a space
     * @param code The referral code
     */
    function containsSpace(bytes32 code) private pure returns (bool) {
        for (uint256 i; i < 32; ++i) {
            if (code[i] == 0x20) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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