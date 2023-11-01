// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity 0.8.19;

import "./FeeManager.sol";
import "./IProcessingChainManager.sol";
// import "../../Rollup/Rollup.sol";
// import "../../CrossChain/LayerZero/ProcessingChainLz.sol";
// import "./WalletDelegation.sol";
// import "../../Oracle/Oracle.sol";

/// The ProcessingChainManager is deployed on the processing chain.
/// It handles deployment of core protocol contracts, authorizes addresses to perform actions across the protocol, and
/// stores protocol parameters.
/// Each contract on the processing chain defers to the ProcessingChainManager for determining
contract ProcessingChainManager is IProcessingChainManager, FeeManager {
    address public admin;
    address public insuranceFund;
    address public participatingInterface;
    address public rollup;
    address public fraudEngine;
    address public staking;
    address public walletDelegation;
    address public relayer;
    address public oracle;
    address public stablecoin;
    address public protocolToken;

    /// Number of blocks that must pass after a state root is submitted in Rollup before it can be confirmed.
    uint256 public fraudPeriod = 28_800; // ~ 4 days on Ethereum
    /// Amount of protocol token that must be locked to propose a state root
    uint256 public rootProposalLockAmount = 10_000e18;
    /// Maps chain ID to boolean indicated whether or not this EVM chain is supported by the protocol.
    mapping(uint256 => bool) public supportedChains;
    /// Maps chain ID to token address to decimals of precision
    /// A value of zero means this asset is not supported
    mapping(uint256 => mapping(address => uint8)) public supportedAsset;
    /// Maps address to boolean indicating whether or not it's authorized as a validator
    mapping(address => bool) public validators;

    constructor(
        address _admin,
        address _participatingInterface,
        address _validator,
        address _stablecoin,
        address _protocolToken
    ) {
        admin = _admin;
        participatingInterface = _participatingInterface;
        // rollup = address(new Rollup(_participatingInterface, address(this)));
        // walletDelegation = address(new WalletDelegation(_participatingInterface, address(this)));
        stablecoin = _stablecoin;
        protocolToken = _protocolToken;
        validators[_validator] = true;
    }

    address public newAdmin;

    function transferAdmin(address _admin) external {
        if (msg.sender != admin) revert("Sender not admin");
        if(_admin == address(0)) revert("New admin cannot be empty");
        if(newAdmin != address(0)) revert("New admin already set");
        newAdmin = _admin;
    }

    function cancelAdminTransfer() external {
        if (msg.sender != admin) revert("Sender not admin");
        newAdmin = address(0);
    }

    function acceptAdminTransfer() external {
        if(msg.sender != newAdmin) revert("Sender not new admin");
        admin = newAdmin;
        newAdmin = address(0);
    }

    function replaceRelayer(address _relayer) external {
        if (msg.sender != admin) revert("Sender not admin");
        if (_relayer == address(0)) revert();
        relayer = _relayer;
    }

    function replaceWalletDelegation(address _walletDelegation) external {
        if (msg.sender != admin) revert("Sender not admin");
        if (_walletDelegation == address(0)) revert();
        walletDelegation = _walletDelegation;
    }

    function replaceOracle(address _oracle) external {
        if (msg.sender != admin) revert("Sender not admin");
        oracle = _oracle;
    }

    function setFraudEngine(address _fraudEngine) external {
        if (msg.sender != admin) revert("Sender not admin");
        if (fraudEngine != address(0)) revert();
        fraudEngine = _fraudEngine;
    }

    function replaceFraudEngine(address _fraudEngine) external {
        if (msg.sender != admin) revert("Sender not admin");
        if (_fraudEngine == address(0)) revert();
        fraudEngine = _fraudEngine;
    }

    function setStaking(address _staking) external {
        if (msg.sender != admin) revert("Sender not admin");
        if (staking != address(0)) revert();
        staking = _staking;
    }

    function replaceStaking(address _staking) external {
        if (msg.sender != admin) revert("Sender not admin");
        if (_staking == address(0)) revert();
        staking = _staking;
    }

    function replaceRollup(address _rollup) external {
        if (msg.sender != admin) revert("Sender not admin");
        if (_rollup == address(0)) revert();
        rollup = _rollup;
    }

    function replaceParticipatingInterface(address _participatingInterface) external {
        if (msg.sender != admin) revert("Sender not admin");
        participatingInterface = _participatingInterface;
    }

    function grantValidator(address _validator) external {
        if (msg.sender != admin) revert("Sender not admin");
        validators[_validator] = true;
    }

    function revokeValidator(address _validator) external {
        if (msg.sender != admin) revert("Sender not admin");
        validators[_validator] = false;
    }

    function updateInsuranceFund(address _insuranceFund) external {
        if (msg.sender != admin) revert("Sender not admin");
        if (_insuranceFund == address(0)) revert();
        insuranceFund = _insuranceFund;
    }

    /// Called by the admin to add support for a new chain
    /// @param _chainId Chain ID of the new EVM chain supported by the protocol
    function addSupportedChain(uint256 _chainId) external {
        if (msg.sender != admin) revert("Sender not admin");
        if (supportedChains[_chainId]) revert();
        supportedChains[_chainId] = true;
    }

    /// Called by admin to support a new asset on the protocol.
    /// If an asset is added here, it should also be added on the corresponding chain's manager.
    /// @param _chainId Chain ID of the asset being added
    /// @param _asset Token address of the assset being added
    /// @param _precision Decimals of precision for the asset being added
    function addSupportedAsset(uint256 _chainId, address _asset, uint8 _precision) external {
        if (msg.sender != admin) revert("Only admin");
        if (!supportedChains[_chainId]) revert("Chain ID not supported");
        if (supportedAsset[_chainId][_asset] != 0) revert("Asset already supported");
        if (_precision == 0) revert("Precision cannot be 0");
        supportedAsset[_chainId][_asset] = _precision;
    }

    /// Called by admin to update the amount of the protocol token a validator needs to lock in order to propose a state
    /// root.
    /// @param _rootProposalLockAmount Updated amount of protocol token a validator must lock to propose a state root
    function updateRootProposalLockAmount(uint256 _rootProposalLockAmount) external {
        if (msg.sender != admin) revert("Only admin");
        if (_rootProposalLockAmount == 0) revert("Lock amount cannot be 0");
        rootProposalLockAmount = _rootProposalLockAmount;
    }

    /// Called by the participating interface to propose new trading fees.
    /// See `FeeManager.sol` for `_proposeFees`
    /// @param _makerFee Numerator of the new maker fee
    /// @param _takerFee Numerator of the new taker fee
    function proposeFees(uint256 _makerFee, uint256 _takerFee) external override {
        if (msg.sender != participatingInterface) revert();
        _proposeFees(_makerFee, _takerFee);
    }

    /// Called by the participating interface to activate proposed trading fees.
    /// See `FeeManager.sol` for `_updateFees`
    function updateFees() external override {
        if (msg.sender != participatingInterface) revert();
        _updateFees();
    }

    /// View function to determine if an address is authorized to be a validator
    function isValidator(address _validator) external view returns (bool) {
        return validators[_validator];
    }

    /// View function to show whether an asset is supported or not.
    function isSupportedAsset(uint256 _chainId, address _asset) external view returns (bool) {
        return supportedAsset[_chainId][_asset] > 0;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../../util/Id.sol";

abstract contract FeeManager {
    using IdLib for Id;

    struct TradingFees {
        uint256 makerFee;
        uint256 takerFee;
    }

    uint256 public constant BASE = 10;
    uint256 public constant DENOMINATOR = 10 ** BASE;
    uint256 public constant ONE_PERCENT_NUMERATOR = 10 ** (BASE - 2); // 1.00%
    uint256 public constant ONE_BPS_NUMERATOR = 10 ** (BASE - 4); // 0.01%

    uint256 public constant MAX_FEE_NUMERATOR = 5 * (10 ** (BASE - 3)); // 0.50%
    uint256 public constant MIN_FEE_NUMERATOR = ONE_BPS_NUMERATOR; // 0.01%

    uint256 proposalTime = type(uint256).max;
    TradingFees public currentFees = TradingFees(1 * ONE_BPS_NUMERATOR, 5 * ONE_BPS_NUMERATOR);
    TradingFees public proposedFees = currentFees;
    Id public feeSequenceId = ID_ZERO;
    mapping(Id => TradingFees) public feeHistory;
    // Amount of time that must pass before a proposed fee can be enacted.
    uint256 public constant FEE_TIMEOUT = 1 days;

    // Determines which percentage of trading fees go to the settlement layer.
    // Remaining goes to the participating interface.
    // uint256 public protocolFee = 50 * ONE_PERCENT_NUMERATOR;

    uint256 public settlementFeeNumerator = ONE_BPS_NUMERATOR * 10; // 0.1 %

    // Determines how much of settlement fee goes to the insurance fund.
    // Remaining goes to stakers
    uint256 public insuranceFundFee = 50 * ONE_PERCENT_NUMERATOR;

    // Given a settlement amount, returns the portions that go to the insurance fund and staker rewards
    function calculateSettlementFees(uint256 settlementAmount) external view returns(uint256 insuranceFee, uint256 stakerReward) {
        uint256 settlementFee = (settlementAmount * settlementFeeNumerator) / DENOMINATOR;
        insuranceFee = (settlementFee * insuranceFundFee) / DENOMINATOR;
        stakerReward = settlementFee - insuranceFee;
    }

    function calculateInsuranceFee(uint256 amount) external view returns(uint256) {
        return (amount * insuranceFundFee) / DENOMINATOR;
    }

    // How much of staking rewards go to the stable coin pool
    // Remaining goes to the protocol token pool
    uint256 public stablePoolPortion = ONE_BPS_NUMERATOR * 8696;

    function calculateStakingRewards(uint256 stakingReward) external view returns (uint256 stablePoolReward, uint256 protocolPoolReward) {
        stablePoolReward = (stakingReward * stablePoolPortion) / DENOMINATOR;
        protocolPoolReward = stakingReward - stablePoolReward;
    }

    event TradingFeesProposed(uint256 makerFee, uint256 takerFee);
    event TradingFeesUpdated(Id indexed feeSequenceId, uint256 makerFee, uint256 takerFee);

    constructor() {
        feeHistory[ID_ZERO] = currentFees;
        emit TradingFeesUpdated(ID_ZERO, currentFees.makerFee, currentFees.takerFee);
    }

    function proposeFees(uint256 _makerFee, uint256 _takerFee) external virtual;
    function updateFees() external virtual;

    modifier withinFeeLimits(uint256 _makerFee, uint256 _takerFee) {
        if (_takerFee > MAX_FEE_NUMERATOR || _makerFee > MAX_FEE_NUMERATOR) revert();
        if (_takerFee != 0 && _takerFee < MIN_FEE_NUMERATOR) revert();
        if (_makerFee != 0 && _makerFee < MIN_FEE_NUMERATOR) revert();
        _;
    }

    function _proposeFees(uint256 _makerFee, uint256 _takerFee) internal withinFeeLimits(_makerFee, _takerFee) {
        proposedFees = TradingFees(_makerFee, _takerFee);
        proposalTime = block.timestamp;
        emit TradingFeesProposed(_makerFee, _takerFee);
    }

    function _updateFees() internal {
        if (block.timestamp < proposalTime + FEE_TIMEOUT) revert();
        currentFees = proposedFees;
        feeSequenceId = feeSequenceId.increment();
        feeHistory[feeSequenceId] = proposedFees;
        proposalTime = type(uint256).max;
        emit TradingFeesUpdated(feeSequenceId, proposedFees.makerFee, proposedFees.takerFee);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity 0.8.19;

interface IProcessingChainManager {
    function admin() external view returns (address);
    function participatingInterface() external view returns (address);
    function insuranceFund() external view returns (address);
    function fraudPeriod() external view returns (uint256);
    function rootProposalLockAmount() external view returns (uint256);
    function staking() external view returns (address);
    function rollup() external view returns (address);
    function relayer() external view returns (address);
    function fraudEngine() external view returns (address);
    function walletDelegation() external view returns (address);
    function oracle() external view returns (address);
    function supportedAsset(uint256 chainId, address asset) external view returns (uint8);
    function isValidator(address validator) external view returns (bool);
    function isSupportedAsset(uint256 chainId, address asset) external view returns (bool);
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
//
// An identifier that can only be incremented by one.
//
pragma solidity 0.8.19;

type Id is uint256;
using {neq as !=, eq as ==, gt as >, gte as >=} for Id global;

Id constant ID_ZERO = Id.wrap(0);
Id constant ID_ONE = Id.wrap(1);
function neq(Id a, Id b) pure returns (bool) { return Id.unwrap(a) != Id.unwrap(b); }
function eq(Id a, Id b) pure returns (bool) { return Id.unwrap(a) == Id.unwrap(b); }
function gt(Id a, Id b) pure returns (bool) { return Id.unwrap(a) > Id.unwrap(b); }
function gte(Id a, Id b) pure returns (bool) { return Id.unwrap(a) >= Id.unwrap(b); }

library IdLib {
    function increment(Id id) internal pure returns (Id) {
        unchecked {
            return Id.wrap(Id.unwrap(id) + Id.unwrap(ID_ONE));
        }
    }

    function isSubsequent(Id a, Id b) internal pure returns (bool) {
        unchecked {
            return Id.unwrap(a) == Id.unwrap(b) + 1;
        }
    }
}