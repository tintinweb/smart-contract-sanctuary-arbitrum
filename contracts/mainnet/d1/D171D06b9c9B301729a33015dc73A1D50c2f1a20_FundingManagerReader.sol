pragma solidity ^0.8.0;

import "./IFundingManager.sol";
import "./FundingManager.sol";

contract FundingManagerReader {

    address public fundingManager;

    constructor(address _fundingManager) public {
        fundingManager = _fundingManager;
    }

    function getFundingData(
        uint256 productId
    ) external view returns(
        int256 fundingPayment,
        int256 fundingRate,
        uint256 lastUpdateTimestamp
    ) {
        fundingPayment = IFundingManager(fundingManager).getFunding(productId);
        fundingRate = IFundingManager(fundingManager).getFundingRate(productId);
        lastUpdateTimestamp = FundingManager(fundingManager).lastUpdateTimes(productId);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFundingManager {
    function updateFunding(uint256) external;
    function getFunding(uint256) external view returns(int256);
    function getFundingRate(uint256) external view returns(int256);
}

pragma solidity ^0.8.0;

import "./IPikaPerp.sol";
import "../access/Governable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";

contract FundingManager is Governable {

    address public pikaPerp;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    event UpdateOwner(address owner);

    uint256 constant public FUNDING_BASE = 10**12;
    uint256 public maxFundingRate = 10 * FUNDING_BASE;
    uint256 public minFundingMultiplier = 2 * FUNDING_BASE;
    mapping(uint256 => uint256) public fundingMultipliers;
    mapping(uint256 => int256) public cumulativeFundings;
    mapping(uint256 => uint256) public lastUpdateTimes;

    event FundingUpdated(uint256 productId, int256 fundingRate, int256 fundingChange, int256 cumulativeFunding);
    event PikaPerpSet(address pikaPerp);
    event MinFundingMultiplierSet(uint256 minFundingMultiplier);
    event FundingMultiplierSet(uint256 productId, uint256 fundingMultiplier);
    event MaxFundingRateSet(uint256 maxFundingRate);

    function updateFunding(uint256 _productId) external {
        require(msg.sender == pikaPerp, "FundingManager: !pikaPerp");
        if (lastUpdateTimes[_productId] == 0) {
            lastUpdateTimes[_productId] = block.timestamp;
            return;
        }
        int256 fundingRate = getFundingRate(_productId);
        int256 fundingChange = fundingRate * int256(block.timestamp - lastUpdateTimes[_productId]) / int256(365 days);
        cumulativeFundings[_productId] = cumulativeFundings[_productId] + fundingChange;
        lastUpdateTimes[_productId] = block.timestamp;
        emit FundingUpdated(_productId, fundingRate, fundingChange, cumulativeFundings[_productId]);
    }

    function getFundingRate(uint256 _productId) public view returns(int256) {
        (,,,,uint256 openInterestLong, uint256 openInterestShort,,uint256 productWeight,) = IPikaPerp(pikaPerp).getProduct(_productId);
        uint256 maxExposure = IPikaPerp(pikaPerp).getMaxExposure(productWeight);
        uint256 fundingMultiplier = Math.max(fundingMultipliers[_productId], minFundingMultiplier);
        if (openInterestLong > openInterestShort) {
            return int256(Math.min((openInterestLong - openInterestShort) * fundingMultiplier / maxExposure, maxFundingRate));
        } else {
            return -1 * int256(Math.min((openInterestShort - openInterestLong) * fundingMultiplier / maxExposure, maxFundingRate));
        }
    }

    function getFunding(uint256 _productId) external view returns(int256) {
        return cumulativeFundings[_productId];
    }

    function setPikaPerp(address _pikaPerp) external onlyOwner {
        pikaPerp = _pikaPerp;
        emit PikaPerpSet(_pikaPerp);
    }

    function setMinFundingMultiplier(uint256 _minFundingMultiplier) external onlyOwner {
        minFundingMultiplier = _minFundingMultiplier;
        emit MinFundingMultiplierSet(_minFundingMultiplier);
    }

    function setFundingMultiplier(uint256 _productId, uint256 _fundingMultiplier) external onlyOwner {
        fundingMultipliers[_productId] = _fundingMultiplier;
        emit FundingMultiplierSet(_productId, _fundingMultiplier);
    }

    function setMaxFundingRate(uint256 _maxFundingRate) external onlyOwner {
        maxFundingRate = _maxFundingRate;
        emit MaxFundingRateSet(_maxFundingRate);
    }

    function setOwner(address _owner) external onlyGov {
        owner = _owner;
        emit UpdateOwner(_owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "FundingManager: !owner");
        _;
    }

}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPikaPerp {
    function getTotalShare() external view returns(uint256);
    function getShare(address stakeOwner) external view returns(uint256);
    function distributeProtocolReward() external returns(uint256);
    function distributePikaReward() external returns(uint256);
    function distributeVaultReward() external returns(uint256);
    function getPendingPikaReward() external view returns(uint256);
    function getPendingProtocolReward() external view returns(uint256);
    function getPendingVaultReward() external view returns(uint256);
    function stake(uint256 amount, address user) external payable;
    function redeem(uint256 shares) external;
    function openPosition(
        address user,
        uint256 productId,
        uint256 margin,
        bool isLong,
        uint256 leverage
    ) external payable;
    function closePositionWithId(
        uint256 positionId,
        uint256 margin
    ) external;
    function closePosition(
        address user,
        uint256 productId,
        uint256 margin,
        bool isLong
    ) external;
    function liquidatePositions(uint256[] calldata positionIds) external;
    function getProduct(uint256 productId) external view returns (
        address,uint256,uint256,bool,uint256,uint256,uint256,uint256,uint256);
    function getPosition(
        address account,
        uint256 productId,
        bool isLong
    ) external view returns (uint256,uint256,uint256,uint256,uint256,address,uint256,bool,int256);
    function getMaxExposure(uint256 productWeight) external view returns(uint256);
    function getCumulativeFunding(uint256 _productId) external view returns(uint256);
    function liquidationThreshold() external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Governable {
    address public gov;

    constructor() public {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}