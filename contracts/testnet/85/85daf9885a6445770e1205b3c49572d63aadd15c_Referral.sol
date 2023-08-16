// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {OwnableInternal} from "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";
import {UD60x18} from "@prb/math/UD60x18.sol";

import {ZERO} from "../libraries/OptionMath.sol";

import {IPoolFactory} from "../factory/PoolFactory.sol";

import {IReferral} from "./IReferral.sol";
import {ReferralStorage} from "./ReferralStorage.sol";

contract Referral is IReferral, OwnableInternal, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;
    using ReferralStorage for address;

    address internal immutable FACTORY;

    constructor(address factory) {
        FACTORY = factory;
    }

    /// @inheritdoc IReferral
    function getReferrer(address user) public view returns (address) {
        return ReferralStorage.layout().referrals[user];
    }

    /// @inheritdoc IReferral
    function getRebateTier(address referrer) public view returns (RebateTier) {
        return ReferralStorage.layout().rebateTiers[referrer];
    }

    /// @inheritdoc IReferral
    function getRebatePercents()
        external
        view
        returns (UD60x18[] memory primaryRebatePercents, UD60x18 secondaryRebatePercent)
    {
        ReferralStorage.Layout storage l = ReferralStorage.layout();
        primaryRebatePercents = l.primaryRebatePercents;
        secondaryRebatePercent = l.secondaryRebatePercent;
    }

    /// @inheritdoc IReferral
    function getRebatePercents(
        address referrer
    ) public view returns (UD60x18 primaryRebatePercents, UD60x18 secondaryRebatePercent) {
        ReferralStorage.Layout storage l = ReferralStorage.layout();

        return (
            l.primaryRebatePercents[uint8(getRebateTier(referrer))],
            l.referrals[referrer] != address(0) ? l.secondaryRebatePercent : ZERO
        );
    }

    /// @inheritdoc IReferral
    function getRebates(address referrer) public view returns (address[] memory, uint256[] memory) {
        ReferralStorage.Layout storage l = ReferralStorage.layout();

        address[] memory tokens = l.rebateTokens[referrer].toArray();
        uint256[] memory rebates = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            rebates[i] = l.rebates[referrer][tokens[i]];
        }

        return (tokens, rebates);
    }

    /// @inheritdoc IReferral
    function getRebateAmounts(
        address user,
        address referrer,
        UD60x18 tradingFee
    ) external view returns (UD60x18 primaryRebate, UD60x18 secondaryRebate) {
        if (referrer == address(0)) referrer = getReferrer(user);
        if (referrer == address(0)) return (ZERO, ZERO);

        (UD60x18 primaryRebatePercent, UD60x18 secondaryRebatePercent) = getRebatePercents(referrer);
        primaryRebate = tradingFee * primaryRebatePercent;
        secondaryRebate = primaryRebate * secondaryRebatePercent;
    }

    /// @inheritdoc IReferral
    function setRebateTier(address referrer, RebateTier tier) external onlyOwner {
        ReferralStorage.Layout storage l = ReferralStorage.layout();
        emit SetRebateTier(referrer, l.rebateTiers[referrer], tier);
        l.rebateTiers[referrer] = tier;
    }

    /// @inheritdoc IReferral
    function setPrimaryRebatePercent(UD60x18 percent, RebateTier tier) external onlyOwner {
        ReferralStorage.Layout storage l = ReferralStorage.layout();
        emit SetPrimaryRebatePercent(tier, l.primaryRebatePercents[uint8(tier)], percent);
        l.primaryRebatePercents[uint8(tier)] = percent;
    }

    /// @inheritdoc IReferral
    function setSecondaryRebatePercent(UD60x18 percent) external onlyOwner {
        ReferralStorage.Layout storage l = ReferralStorage.layout();
        emit SetSecondaryRebatePercent(l.secondaryRebatePercent, percent);
        l.secondaryRebatePercent = percent;
    }

    /// @inheritdoc IReferral
    function useReferral(
        address user,
        address referrer,
        address token,
        UD60x18 primaryRebate,
        UD60x18 secondaryRebate
    ) external nonReentrant {
        _revertIfPoolNotAuthorized();

        referrer = _trySetReferrer(user, referrer);
        if (referrer == address(0)) return;

        UD60x18 totalRebate = primaryRebate + secondaryRebate;
        if (totalRebate == ZERO) return;

        IERC20(token).safeTransferFrom(msg.sender, address(this), token.toTokenDecimals(totalRebate));

        ReferralStorage.Layout storage l = ReferralStorage.layout();
        address secondaryReferrer = l.referrals[referrer];
        _tryUpdateRebate(l, secondaryReferrer, token, secondaryRebate);
        _tryUpdateRebate(l, referrer, token, primaryRebate);

        (UD60x18 primaryRebatePercent, ) = getRebatePercents(referrer);
        emit Refer(user, referrer, secondaryReferrer, token, primaryRebatePercent, primaryRebate, secondaryRebate);
    }

    /// @inheritdoc IReferral
    function claimRebate(address[] memory tokens) external nonReentrant {
        ReferralStorage.Layout storage l = ReferralStorage.layout();

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 rebate = l.rebates[msg.sender][tokens[i]];
            if (rebate == 0) continue;

            l.rebates[msg.sender][tokens[i]] = 0;
            l.rebateTokens[msg.sender].remove(tokens[i]);

            IERC20(tokens[i]).safeTransfer(msg.sender, rebate);
            emit ClaimRebate(msg.sender, tokens[i], rebate);
        }
    }

    /// @notice Updates the `referrer` rebate balance and rebate tokens, if `amount` is greater than zero
    function _tryUpdateRebate(
        ReferralStorage.Layout storage l,
        address referrer,
        address token,
        UD60x18 amount
    ) internal {
        if (amount > ZERO) {
            l.rebates[referrer][token] += token.toTokenDecimals(amount);
            if (!l.rebateTokens[referrer].contains(token)) l.rebateTokens[referrer].add(token);
        }
    }

    /// @notice Sets the `referrer` for a `user` if they don't already have one. If a referrer has already been set,
    ///         return the existing referrer.
    function _trySetReferrer(address user, address referrer) internal returns (address) {
        ReferralStorage.Layout storage l = ReferralStorage.layout();

        if (l.referrals[user] == address(0)) {
            if (referrer == address(0)) return address(0);
            l.referrals[user] = referrer;
        } else {
            referrer = l.referrals[user];
        }

        return referrer;
    }

    /// @notice Reverts if the caller is not an authorized pool
    function _revertIfPoolNotAuthorized() internal view {
        if (!IPoolFactory(FACTORY).isPool(msg.sender)) revert Referral__PoolNotAuthorized();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { AddressUtils } from '../../utils/AddressUtils.sol';
import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using AddressUtils for address;

    modifier onlyOwner() {
        if (msg.sender != _owner()) revert Ownable__NotOwner();
        _;
    }

    modifier onlyTransitiveOwner() {
        if (msg.sender != _transitiveOwner())
            revert Ownable__NotTransitiveOwner();
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transitiveOwner() internal view virtual returns (address owner) {
        owner = _owner();

        while (owner.isContract()) {
            try IERC173(owner).owner() returns (address transitiveOwner) {
                owner = transitiveOwner;
            } catch {
                break;
            }
        }
    }

    function _transferOwnership(address account) internal virtual {
        _setOwner(account);
    }

    function _setOwner(address account) internal virtual {
        OwnableStorage.Layout storage l = OwnableStorage.layout();
        emit OwnershipTransferred(l.owner, account);
        l.owner = account;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    error EnumerableSet__IndexOutOfBounds();

    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(
        Bytes32Set storage set,
        uint256 index
    ) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function at(
        AddressSet storage set,
        uint256 index
    ) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(
        UintSet storage set,
        uint256 index
    ) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function contains(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function contains(
        AddressSet storage set,
        address value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(
        UintSet storage set,
        uint256 value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, value);
    }

    function indexOf(
        AddressSet storage set,
        address value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(
        UintSet storage set,
        uint256 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _add(set._inner, value);
    }

    function add(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function remove(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(
        UintSet storage set,
        uint256 value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(
        Bytes32Set storage set
    ) internal view returns (bytes32[] memory) {
        return set._inner._values;
    }

    function toArray(
        AddressSet storage set
    ) internal view returns (address[] memory) {
        bytes32[] storage values = set._inner._values;
        address[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function toArray(
        UintSet storage set
    ) internal view returns (uint256[] memory) {
        bytes32[] storage values = set._inner._values;
        uint256[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function _at(
        Set storage set,
        uint256 index
    ) private view returns (bytes32) {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(
        Set storage set,
        bytes32 value
    ) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _indexOf(
        Set storage set,
        bytes32 value
    ) private view returns (uint256) {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            status = true;
        }
    }

    function _remove(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            status = true;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Internal } from './IERC20Internal.sol';

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 is IERC20Internal {
    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return token allowance
     */
    function allowance(
        address holder,
        address spender
    ) external view returns (uint256);

    /**
     * @notice grant approval to spender to spend tokens
     * @dev prefer ERC20Extended functions to avoid transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice transfer tokens to given recipient
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IReentrancyGuard } from './IReentrancyGuard.sol';
import { ReentrancyGuardStorage } from './ReentrancyGuardStorage.sol';

/**
 * @title Utility contract for preventing reentrancy attacks
 */
abstract contract ReentrancyGuard is IReentrancyGuard {
    uint256 internal constant REENTRANCY_STATUS_LOCKED = 2;
    uint256 internal constant REENTRANCY_STATUS_UNLOCKED = 1;

    modifier nonReentrant() {
        if (ReentrancyGuardStorage.layout().status == REENTRANCY_STATUS_LOCKED)
            revert ReentrancyGuard__ReentrantCall();
        _lockReentrancyGuard();
        _;
        _unlockReentrancyGuard();
    }

    /**
     * @notice lock functions that use the nonReentrant modifier
     */
    function _lockReentrancyGuard() internal virtual {
        ReentrancyGuardStorage.layout().status = REENTRANCY_STATUS_LOCKED;
    }

    /**
     * @notice unlock funtions that use the nonReentrant modifier
     */
    function _unlockReentrancyGuard() internal virtual {
        ReentrancyGuardStorage.layout().status = REENTRANCY_STATUS_UNLOCKED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20 } from '../interfaces/IERC20.sol';
import { AddressUtils } from './AddressUtils.sol';

/**
 * @title Safe ERC20 interaction library
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library SafeERC20 {
    using AddressUtils for address;

    error SafeERC20__ApproveFromNonZeroToNonZero();
    error SafeERC20__DecreaseAllowanceBelowZero();
    error SafeERC20__OperationFailed();

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev safeApprove (like approve) should only be called when setting an initial allowance or when resetting it to zero; otherwise prefer safeIncreaseAllowance and safeDecreaseAllowance
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        if ((value != 0) && (token.allowance(address(this), spender) != 0))
            revert SafeERC20__ApproveFromNonZeroToNonZero();

        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            if (oldAllowance < value)
                revert SafeERC20__DecreaseAllowanceBelowZero();
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    /**
     * @notice send transaction data and check validity of return value, if present
     * @param token ERC20 token interface
     * @param data transaction data
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            'SafeERC20: low-level call failed'
        );

        if (returndata.length > 0) {
            if (!abi.decode(returndata, (bool)))
                revert SafeERC20__OperationFailed();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

/*

██████╗ ██████╗ ██████╗ ███╗   ███╗ █████╗ ████████╗██╗  ██╗
██╔══██╗██╔══██╗██╔══██╗████╗ ████║██╔══██╗╚══██╔══╝██║  ██║
██████╔╝██████╔╝██████╔╝██╔████╔██║███████║   ██║   ███████║
██╔═══╝ ██╔══██╗██╔══██╗██║╚██╔╝██║██╔══██║   ██║   ██╔══██║
██║     ██║  ██║██████╔╝██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║
╚═╝     ╚═╝  ╚═╝╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝

██╗   ██╗██████╗  ██████╗  ██████╗ ██╗  ██╗ ██╗ █████╗
██║   ██║██╔══██╗██╔════╝ ██╔═████╗╚██╗██╔╝███║██╔══██╗
██║   ██║██║  ██║███████╗ ██║██╔██║ ╚███╔╝ ╚██║╚█████╔╝
██║   ██║██║  ██║██╔═══██╗████╔╝██║ ██╔██╗  ██║██╔══██╗
╚██████╔╝██████╔╝╚██████╔╝╚██████╔╝██╔╝ ██╗ ██║╚█████╔╝
 ╚═════╝ ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝ ╚═╝ ╚════╝

*/

import "./ud60x18/Casting.sol";
import "./ud60x18/Constants.sol";
import "./ud60x18/Conversions.sol";
import "./ud60x18/Errors.sol";
import "./ud60x18/Helpers.sol";
import "./ud60x18/Math.sol";
import "./ud60x18/ValueType.sol";

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {BokkyPooBahsDateTimeLibrary as DateTime} from "@bokkypoobah/BokkyPooBahsDateTimeLibrary.sol";
import {UD60x18, ud} from "@prb/math/UD60x18.sol";
import {SD59x18} from "@prb/math/SD59x18.sol";

import {ZERO, ONE, TWO, iZERO, iONE, iTWO, iFOUR, iNINE} from "./Constants.sol";

library OptionMath {
    struct BlackScholesPriceVarsInternal {
        int256 discountFactor;
        int256 timeScaledVol;
        int256 timeScaledVar;
        int256 timeScaledRiskFreeRate;
    }

    UD60x18 internal constant INITIALIZATION_ALPHA = UD60x18.wrap(5e18);
    UD60x18 internal constant ATM_MONEYNESS = UD60x18.wrap(0.5e18);
    uint256 internal constant NEAR_TERM_TTM = 14 days;
    uint256 internal constant ONE_YEAR_TTM = 365 days;
    UD60x18 internal constant FEE_SCALAR = UD60x18.wrap(100e18);

    SD59x18 internal constant ALPHA = SD59x18.wrap(-6.37309208e18);
    SD59x18 internal constant LAMBDA = SD59x18.wrap(-0.61228883e18);
    SD59x18 internal constant S1 = SD59x18.wrap(-0.11105481e18);
    SD59x18 internal constant S2 = SD59x18.wrap(0.44334159e18);
    int256 internal constant SQRT_2PI = 2_506628274631000502;

    UD60x18 internal constant MIN_INPUT_PRICE = UD60x18.wrap(1e1);
    UD60x18 internal constant MAX_INPUT_PRICE = UD60x18.wrap(1e34);

    error OptionMath__NonPositiveVol();
    error OptionMath__OutOfBoundsPrice(UD60x18 min, UD60x18 max, UD60x18 price);
    error OptionMath__Underflow();

    /// @notice Helper function to evaluate used to compute the normal CDF approximation
    /// @param x The input to the normal CDF (18 decimals)
    /// @return result The value of the evaluated helper function (18 decimals)
    function helperNormal(SD59x18 x) internal pure returns (SD59x18 result) {
        SD59x18 a = (ALPHA / LAMBDA) * S1;
        SD59x18 b = (S1 * x + iONE).pow(LAMBDA / S1) - iONE;
        result = ((a * b + S2 * x).exp() * (-iTWO.ln())).exp();
    }

    /// @notice Approximation of the normal CDF
    /// @dev The approximation implemented is based on the paper 'Accurate RMM-Based Approximations for the CDF of the
    ///      Normal Distribution' by Haim Shore
    /// @param x input value to evaluate the normal CDF on, F(Z<=x) (18 decimals)
    /// @return result The normal CDF evaluated at x (18 decimals)
    function normalCdf(SD59x18 x) internal pure returns (SD59x18 result) {
        if (x <= -iNINE) {
            result = iZERO;
        } else if (x >= iNINE) {
            result = iONE;
        } else {
            result = ((iONE + helperNormal(-x)) - helperNormal(x)) / iTWO;
        }
    }

    /// @notice Normal Distribution Probability Density Function.
    /// @dev Equal to `Z(x) = (1 / σ√2π)e^( (-(x - µ)^2) / 2σ^2 )`. Only computes pdf of a distribution with `µ = 0` and
    ///      `σ = 1`.
    /// @custom:error Maximum error of 1.2e-7.
    /// @custom:source https://mathworld.wolfram.com/ProbabilityDensityFunction.html.
    /// @param x Number to get PDF for (18 decimals)
    /// @return z z-number (18 decimals)
    function normalPdf(SD59x18 x) internal pure returns (SD59x18 z) {
        SD59x18 e;
        int256 one = iONE.unwrap();
        uint256 two = TWO.unwrap();

        assembly {
            e := sdiv(mul(add(not(x), 1), x), two) // (-x * x) / 2.
        }
        e = e.exp();
        assembly {
            z := sdiv(mul(e, one), SQRT_2PI)
        }
    }

    /// @notice Implementation of the ReLu function `f(x)=(x)^+` to compute call / put payoffs
    /// @param x Input value (18 decimals)
    /// @return result Output of the relu function (18 decimals)
    function relu(SD59x18 x) internal pure returns (UD60x18) {
        if (x >= iZERO) {
            return x.intoUD60x18();
        }
        return ZERO;
    }

    /// @notice Returns the terms `d1` and `d2` from the Black-Scholes formula that are used to compute the price of a
    ///         call / put option.
    /// @param spot The spot price. (18 decimals)
    /// @param strike The strike price of the option. (18 decimals)
    /// @param timeToMaturity The time until the option expires. (18 decimals)
    /// @param volAnnualized The percentage volatility of the geometric Brownian motion. (18 decimals)
    /// @param riskFreeRate The rate of the risk-less asset, i.e. the risk-free interest rate. (18 decimals)
    /// @return d1 The term d1 from the Black-Scholes formula. (18 decimals)
    /// @return d2 The term d2 from the Black-Scholes formula. (18 decimals)
    function d1d2(
        UD60x18 spot,
        UD60x18 strike,
        UD60x18 timeToMaturity,
        UD60x18 volAnnualized,
        UD60x18 riskFreeRate
    ) internal pure returns (SD59x18 d1, SD59x18 d2) {
        UD60x18 timeScaledRiskFreeRate = riskFreeRate * timeToMaturity;
        UD60x18 timeScaledVariance = (volAnnualized.powu(2) / TWO) * timeToMaturity;
        UD60x18 timeScaledStd = volAnnualized * timeToMaturity.sqrt();
        SD59x18 lnSpot = (spot / strike).intoSD59x18().ln();

        d1 =
            (lnSpot + timeScaledVariance.intoSD59x18() + timeScaledRiskFreeRate.intoSD59x18()) /
            timeScaledStd.intoSD59x18();

        d2 = d1 - timeScaledStd.intoSD59x18();
    }

    /// @notice Calculate option delta
    /// @param spot Spot price
    /// @param strike Strike price
    /// @param timeToMaturity Duration of option contract (in years)
    /// @param volAnnualized Annualized volatility
    /// @param isCall whether to price "call" or "put" option
    /// @return price Option delta
    function optionDelta(
        UD60x18 spot,
        UD60x18 strike,
        UD60x18 timeToMaturity,
        UD60x18 volAnnualized,
        UD60x18 riskFreeRate,
        bool isCall
    ) internal pure returns (SD59x18) {
        (SD59x18 d1, ) = d1d2(spot, strike, timeToMaturity, volAnnualized, riskFreeRate);

        if (isCall) {
            return normalCdf(d1);
        } else {
            return -normalCdf(-d1);
        }
    }

    /// @notice Calculate the price of an option using the Black-Scholes model
    /// @dev this implementation assumes zero interest
    /// @param spot Spot price (18 decimals)
    /// @param strike Strike price (18 decimals)
    /// @param timeToMaturity Duration of option contract (in years) (18 decimals)
    /// @param volAnnualized Annualized volatility (18 decimals)
    /// @param riskFreeRate The risk-free rate (18 decimals)
    /// @param isCall whether to price "call" or "put" option
    /// @return price The Black-Scholes option price (18 decimals)
    function blackScholesPrice(
        UD60x18 spot,
        UD60x18 strike,
        UD60x18 timeToMaturity,
        UD60x18 volAnnualized,
        UD60x18 riskFreeRate,
        bool isCall
    ) internal pure returns (UD60x18) {
        SD59x18 _spot = spot.intoSD59x18();
        SD59x18 _strike = strike.intoSD59x18();
        if (volAnnualized == ZERO) revert OptionMath__NonPositiveVol();

        if (timeToMaturity == ZERO) {
            if (isCall) {
                return relu(_spot - _strike);
            }
            return relu(_strike - _spot);
        }

        SD59x18 discountFactor;
        if (riskFreeRate > ZERO) {
            discountFactor = (riskFreeRate * timeToMaturity).intoSD59x18().exp();
        } else {
            discountFactor = iONE;
        }

        (SD59x18 d1, SD59x18 d2) = d1d2(spot, strike, timeToMaturity, volAnnualized, riskFreeRate);
        SD59x18 sign = isCall ? iONE : -iONE;
        SD59x18 a = (_spot / _strike) * normalCdf(d1 * sign);
        SD59x18 b = normalCdf(d2 * sign) / discountFactor;
        SD59x18 scaledPrice = (a - b) * sign;

        if (scaledPrice < SD59x18.wrap(-1e12)) revert OptionMath__Underflow();
        if (scaledPrice >= SD59x18.wrap(-1e12) && scaledPrice <= iZERO) scaledPrice = iZERO;

        return (scaledPrice * _strike).intoUD60x18();
    }

    /// @notice Returns true if the maturity time is 8AM UTC
    /// @param maturity The maturity timestamp of the option
    /// @return True if the maturity time is 8AM UTC, false otherwise
    function is8AMUTC(uint256 maturity) internal pure returns (bool) {
        return maturity % 24 hours == 8 hours;
    }

    /// @notice Returns true if the maturity day is Friday
    /// @param maturity The maturity timestamp of the option
    /// @return True if the maturity day is Friday, false otherwise
    function isFriday(uint256 maturity) internal pure returns (bool) {
        return DateTime.getDayOfWeek(maturity) == DateTime.DOW_FRI;
    }

    /// @notice Returns true if the maturity day is the last Friday of the month
    /// @param maturity The maturity timestamp of the option
    /// @return True if the maturity day is the last Friday of the month, false otherwise
    function isLastFriday(uint256 maturity) internal pure returns (bool) {
        uint256 dayOfMonth = DateTime.getDay(maturity);
        uint256 lastDayOfMonth = DateTime.getDaysInMonth(maturity);
        if (lastDayOfMonth - dayOfMonth >= 7) return false;
        return isFriday(maturity);
    }

    /// @notice Calculates the time to maturity in seconds
    /// @param maturity The maturity timestamp of the option
    /// @return Time to maturity in seconds
    function calculateTimeToMaturity(uint256 maturity) internal view returns (uint256) {
        return maturity - block.timestamp;
    }

    /// @notice Calculates the strike interval for `strike`
    /// @param strike The price to calculate strike interval for (18 decimals)
    /// @return The strike interval (18 decimals)
    function calculateStrikeInterval(UD60x18 strike) internal pure returns (UD60x18) {
        if (strike < MIN_INPUT_PRICE || strike > MAX_INPUT_PRICE)
            revert OptionMath__OutOfBoundsPrice(MIN_INPUT_PRICE, MAX_INPUT_PRICE, strike);

        uint256 _strike = strike.unwrap();
        uint256 exponent = log10Floor(_strike);
        uint256 multiplier = (_strike >= 5 * 10 ** exponent) ? 5 : 1;
        return ud(multiplier * 10 ** (exponent - 1));
    }

    /// @notice Rounds `strike` using the calculated strike interval
    /// @param strike The price to round (18 decimals)
    /// @return The rounded strike price (18 decimals)
    function roundToStrikeInterval(UD60x18 strike) internal pure returns (UD60x18) {
        uint256 _strike = strike.div(ONE).unwrap();
        uint256 interval = calculateStrikeInterval(strike).div(ONE).unwrap();
        uint256 lower = interval * (_strike / interval);
        uint256 upper = interval * ((_strike / interval) + 1);
        return (_strike - lower < upper - _strike) ? ud(lower) : ud(upper);
    }

    /// @notice Calculate the log moneyness of a strike/spot price pair
    /// @param spot The spot price (18 decimals)
    /// @param strike The strike price (18 decimals)
    /// @return The log moneyness of the strike price (18 decimals)
    function logMoneyness(UD60x18 spot, UD60x18 strike) internal pure returns (UD60x18) {
        return (spot / strike).intoSD59x18().ln().abs().intoUD60x18();
    }

    /// @notice Calculate the initialization fee for a pool
    /// @param spot The spot price (18 decimals)
    /// @param strike The strike price (18 decimals)
    /// @param maturity The maturity timestamp of the option
    /// @return The initialization fee (18 decimals)
    function initializationFee(UD60x18 spot, UD60x18 strike, uint256 maturity) internal view returns (UD60x18) {
        UD60x18 moneyness = logMoneyness(spot, strike);
        uint256 timeToMaturity = calculateTimeToMaturity(maturity);
        UD60x18 kBase = moneyness < ATM_MONEYNESS
            ? (ATM_MONEYNESS - moneyness).intoSD59x18().pow(iFOUR).intoUD60x18()
            : moneyness - ATM_MONEYNESS;
        uint256 tBase = timeToMaturity < NEAR_TERM_TTM
            ? 3 * (NEAR_TERM_TTM - timeToMaturity) + NEAR_TERM_TTM
            : timeToMaturity;
        UD60x18 scaledT = (ud(tBase * 1e18) / ud(ONE_YEAR_TTM * 1e18)).sqrt();

        return INITIALIZATION_ALPHA * (kBase + scaledT) * scaledT * FEE_SCALAR;
    }

    /// @notice Converts a number with `inputDecimals`, to a number with given amount of decimals
    /// @param value The value to convert
    /// @param inputDecimals The amount of decimals the input value has
    /// @param targetDecimals The amount of decimals to convert to
    /// @return The converted value
    function scaleDecimals(uint256 value, uint8 inputDecimals, uint8 targetDecimals) internal pure returns (uint256) {
        if (targetDecimals == inputDecimals) return value;
        if (targetDecimals > inputDecimals) return value * (10 ** (targetDecimals - inputDecimals));

        return value / (10 ** (inputDecimals - targetDecimals));
    }

    /// @notice Converts a number with `inputDecimals`, to a number with given amount of decimals
    /// @param value The value to convert
    /// @param inputDecimals The amount of decimals the input value has
    /// @param targetDecimals The amount of decimals to convert to
    /// @return The converted value
    function scaleDecimals(int256 value, uint8 inputDecimals, uint8 targetDecimals) internal pure returns (int256) {
        if (targetDecimals == inputDecimals) return value;
        if (targetDecimals > inputDecimals) return value * int256(10 ** (targetDecimals - inputDecimals));

        return value / int256(10 ** (inputDecimals - targetDecimals));
    }

    /// @notice Performs a naive log10 calculation on `input` returning the floor of the result
    function log10Floor(uint256 input) internal pure returns (uint256 count) {
        while (input >= 10) {
            input /= 10;
            count++;
        }

        return count;
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity =0.8.19;

import {Denominations} from "@chainlink/contracts/src/v0.8/Denominations.sol";

import {OwnableInternal} from "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";

import {UD60x18} from "@prb/math/UD60x18.sol";

import {IPoolFactory} from "./IPoolFactory.sol";
import {IPoolFactoryDeployer} from "./IPoolFactoryDeployer.sol";
import {PoolFactoryStorage} from "./PoolFactoryStorage.sol";
import {PoolStorage} from "../pool/PoolStorage.sol";
import {IOracleAdapter} from "../adapter/IOracleAdapter.sol";

import {OptionMath} from "../libraries/OptionMath.sol";
import {ZERO, ONE} from "../libraries/Constants.sol";

contract PoolFactory is IPoolFactory, OwnableInternal, ReentrancyGuard {
    using PoolFactoryStorage for PoolFactoryStorage.Layout;
    using PoolFactoryStorage for PoolKey;
    using PoolStorage for PoolStorage.Layout;

    address internal immutable DIAMOND;
    // Chainlink price oracle for the WrappedNative/USD pair
    address internal immutable CHAINLINK_ADAPTER;
    // Wrapped native token address (eg WETH, WFTM, etc)
    address internal immutable WRAPPED_NATIVE_TOKEN;
    // Address of the contract handling the proxy deployment.
    // This is in a separate contract so that we can upgrade this contract without having deterministic address calculation change
    address internal immutable POOL_FACTORY_DEPLOYER;

    constructor(address diamond, address chainlinkAdapter, address wrappedNativeToken, address poolFactoryDeployer) {
        DIAMOND = diamond;
        CHAINLINK_ADAPTER = chainlinkAdapter;
        WRAPPED_NATIVE_TOKEN = wrappedNativeToken;
        POOL_FACTORY_DEPLOYER = poolFactoryDeployer;
    }

    /// @inheritdoc IPoolFactory
    function isPool(address contractAddress) external view returns (bool) {
        return PoolFactoryStorage.layout().isPool[contractAddress];
    }

    /// @inheritdoc IPoolFactory
    function getPoolAddress(PoolKey calldata k) external view returns (address pool, bool isDeployed) {
        pool = _getPoolAddress(k.poolKey());
        isDeployed = true;

        if (pool == address(0)) {
            _revertIfAddressInvalid(k);
            _revertIfOptionStrikeInvalid(k.strike);
            _revertIfOptionMaturityInvalid(k.maturity);

            pool = IPoolFactoryDeployer(POOL_FACTORY_DEPLOYER).calculatePoolAddress(k);
            isDeployed = false;
        }
    }

    /// @notice Returns the address of a pool using the encoded `poolKey`
    function _getPoolAddress(bytes32 poolKey) internal view returns (address) {
        return PoolFactoryStorage.layout().pools[poolKey];
    }

    /// @inheritdoc IPoolFactory
    function setDiscountPerPool(UD60x18 discountPerPool) external onlyOwner {
        if (discountPerPool == ZERO || discountPerPool >= ONE) revert PoolFactory__InvalidInput();
        PoolFactoryStorage.Layout storage l = PoolFactoryStorage.layout();
        l.discountPerPool = discountPerPool;
        emit SetDiscountPerPool(discountPerPool);
    }

    /// @inheritdoc IPoolFactory
    function setFeeReceiver(address feeReceiver) external onlyOwner {
        PoolFactoryStorage.Layout storage l = PoolFactoryStorage.layout();
        l.feeReceiver = feeReceiver;
        emit SetFeeReceiver(feeReceiver);
    }

    /// @inheritdoc IPoolFactory
    function deployPool(PoolKey calldata k) external payable nonReentrant returns (address poolAddress) {
        if (k.oracleAdapter != CHAINLINK_ADAPTER) revert PoolFactory__InvalidOracleAdapter();

        _revertIfAddressInvalid(k);

        IOracleAdapter(k.oracleAdapter).upsertPair(k.base, k.quote);

        _revertIfOptionStrikeInvalid(k.strike);
        _revertIfOptionMaturityInvalid(k.maturity);

        bytes32 poolKey = k.poolKey();
        uint256 fee = initializationFee(k).unwrap();

        if (fee == 0) revert PoolFactory__InitializationFeeIsZero();
        if (msg.value < fee) revert PoolFactory__InitializationFeeRequired(msg.value, fee);

        address _poolAddress = _getPoolAddress(poolKey);
        if (_poolAddress != address(0)) revert PoolFactory__PoolAlreadyDeployed(_poolAddress);

        _safeTransferNativeToken(PoolFactoryStorage.layout().feeReceiver, fee);
        if (msg.value > fee) _safeTransferNativeToken(msg.sender, msg.value - fee);

        poolAddress = IPoolFactoryDeployer(POOL_FACTORY_DEPLOYER).deployPool(k);

        PoolFactoryStorage.Layout storage l = PoolFactoryStorage.layout();
        l.pools[poolKey] = poolAddress;
        l.isPool[poolAddress] = true;
        l.strikeCount[k.strikeKey()] += 1;
        l.maturityCount[k.maturityKey()] += 1;

        emit PoolDeployed(k.base, k.quote, k.oracleAdapter, k.strike, k.maturity, k.isCallPool, poolAddress);

        {
            (
                IOracleAdapter.AdapterType baseAdapterType,
                address[][] memory basePath,
                uint8[] memory basePathDecimals
            ) = IOracleAdapter(k.oracleAdapter).describePricingPath(k.base);

            (
                IOracleAdapter.AdapterType quoteAdapterType,
                address[][] memory quotePath,
                uint8[] memory quotePathDecimals
            ) = IOracleAdapter(k.oracleAdapter).describePricingPath(k.quote);

            emit PricingPath(
                poolAddress,
                basePath,
                basePathDecimals,
                baseAdapterType,
                quotePath,
                quotePathDecimals,
                quoteAdapterType
            );
        }
    }

    /// @inheritdoc IPoolFactory
    function removeDiscount(PoolKey calldata k) external nonReentrant {
        if (block.timestamp < k.maturity) revert PoolFactory__PoolNotExpired();

        if (PoolFactoryStorage.layout().pools[k.poolKey()] != msg.sender) revert PoolFactory__NotAuthorized();

        PoolFactoryStorage.layout().strikeCount[k.strikeKey()] -= 1;
        PoolFactoryStorage.layout().maturityCount[k.maturityKey()] -= 1;
    }

    /// @inheritdoc IPoolFactory
    function initializationFee(IPoolFactory.PoolKey calldata k) public view returns (UD60x18) {
        PoolFactoryStorage.Layout storage l = PoolFactoryStorage.layout();

        uint256 discountFactor = l.maturityCount[k.maturityKey()] + l.strikeCount[k.strikeKey()];
        UD60x18 discount = (ONE - l.discountPerPool).intoSD59x18().powu(discountFactor).intoUD60x18();

        UD60x18 spot = _getSpotPrice(k.oracleAdapter, k.base, k.quote);
        UD60x18 fee = OptionMath.initializationFee(spot, k.strike, k.maturity);

        return (fee * discount) / _getWrappedNativeUSDSpotPrice();
    }

    /// @notice We use the given oracle adapter to fetch the spot price of the base/quote pair.
    ///         This is used in the calculation of the initializationFee
    function _getSpotPrice(address oracleAdapter, address base, address quote) internal view returns (UD60x18) {
        return IOracleAdapter(oracleAdapter).getPrice(base, quote);
    }

    /// @notice We use the Premia Chainlink Adapter to fetch the spot price of the wrapped native token in USD.
    ///         This is used to convert the initializationFee from USD to native token
    function _getWrappedNativeUSDSpotPrice() internal view returns (UD60x18) {
        return IOracleAdapter(CHAINLINK_ADAPTER).getPrice(WRAPPED_NATIVE_TOKEN, Denominations.USD);
    }

    /// @notice Safely transfer native token to the given address
    function _safeTransferNativeToken(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}("");
        if (!success) revert PoolFactory__TransferNativeTokenFailed();
    }

    /// @notice Revert if the base and quote are identical or if the base, quote, or oracle adapter are zero
    function _revertIfAddressInvalid(PoolKey calldata k) internal pure {
        if (k.base == k.quote) revert PoolFactory__IdenticalAddresses();
        if (k.base == address(0) || k.quote == address(0) || k.oracleAdapter == address(0))
            revert PoolFactory__ZeroAddress();
    }

    /// @notice Revert if the strike price is not a multiple of the strike interval
    function _revertIfOptionStrikeInvalid(UD60x18 strike) internal pure {
        if (strike == ZERO) revert PoolFactory__OptionStrikeEqualsZero();
        UD60x18 strikeInterval = OptionMath.calculateStrikeInterval(strike);
        if (strike % strikeInterval != ZERO) revert PoolFactory__OptionStrikeInvalid(strike, strikeInterval);
    }

    /// @notice Revert if the maturity is invalid
    function _revertIfOptionMaturityInvalid(uint256 maturity) internal view {
        if (maturity <= block.timestamp) revert PoolFactory__OptionExpired(maturity);
        if (!OptionMath.is8AMUTC(maturity)) revert PoolFactory__OptionMaturityNot8UTC(maturity);

        uint256 ttm = OptionMath.calculateTimeToMaturity(maturity);

        if (ttm >= 3 days && ttm <= 30 days) {
            if (!OptionMath.isFriday(maturity)) revert PoolFactory__OptionMaturityNotFriday(maturity);
        }

        if (ttm > 30 days) {
            if (!OptionMath.isLastFriday(maturity)) revert PoolFactory__OptionMaturityNotLastFriday(maturity);
        }

        if (ttm > 365 days) revert PoolFactory__OptionMaturityExceedsMax(maturity);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "@prb/math/UD60x18.sol";

interface IReferral {
    enum RebateTier {
        PrimaryRebate1,
        PrimaryRebate2,
        PrimaryRebate3
    }

    error Referral__PoolNotAuthorized();

    event ClaimRebate(address indexed referrer, address indexed token, uint256 amount);
    event SetPrimaryRebatePercent(RebateTier tier, UD60x18 oldPercent, UD60x18 newPercent);
    event SetRebateTier(address indexed referrer, RebateTier oldTier, RebateTier newTier);
    event SetSecondaryRebatePercent(UD60x18 oldPercent, UD60x18 newPercent);

    event Refer(
        address indexed user,
        address indexed primaryReferrer,
        address indexed secondaryReferrer,
        address token,
        UD60x18 tier,
        UD60x18 primaryRebate,
        UD60x18 secondaryRebate
    );

    /// @notice Returns the address of the referrer for a given user
    /// @param user The address of the user
    /// @return referrer The address of the referrer
    function getReferrer(address user) external view returns (address referrer);

    /// @notice Returns the rebate tier for a given referrer
    /// @param referrer The address of the referrer
    /// @return tier The rebate tier
    function getRebateTier(address referrer) external view returns (RebateTier tier);

    /// @notice Returns the primary and secondary rebate percents
    /// @return primaryRebatePercents The primary rebate percents (18 decimals)
    /// @return secondaryRebatePercent The secondary rebate percent (18 decimals)
    function getRebatePercents()
        external
        view
        returns (UD60x18[] memory primaryRebatePercents, UD60x18 secondaryRebatePercent);

    /// @notice Returns the primary and secondary rebate percents for a given referrer
    /// @param referrer The address of the referrer
    /// @return primaryRebatePercent The primary rebate percent (18 decimals)
    /// @return secondaryRebatePercent The secondary rebate percent (18 decimals)
    function getRebatePercents(
        address referrer
    ) external view returns (UD60x18 primaryRebatePercent, UD60x18 secondaryRebatePercent);

    /// @notice Returns the rebates for a given referrer
    /// @param referrer The address of the referrer
    /// @return tokens The tokens for which the referrer has rebates
    /// @return rebates The rebates for each token (token decimals)
    function getRebates(address referrer) external view returns (address[] memory tokens, uint256[] memory rebates);

    /// @notice Returns the primary and secondary rebate amounts for a given `user` and `referrer`
    /// @param user The address of the user
    /// @param referrer The address of the referrer
    /// @param tradingFee The trading fee (18 decimals)
    /// @return primaryRebate The primary rebate amount (18 decimals)
    /// @return secondaryRebate The secondary rebate amount (18 decimals)
    function getRebateAmounts(
        address user,
        address referrer,
        UD60x18 tradingFee
    ) external view returns (UD60x18 primaryRebate, UD60x18 secondaryRebate);

    /// @notice Sets the rebate tier for a given referrer - caller must be owner
    /// @param referrer The address of the referrer
    /// @param tier The rebate tier
    function setRebateTier(address referrer, RebateTier tier) external;

    /// @notice Sets the primary rebate percents - caller must be owner
    /// @param percent The primary rebate percent (18 decimals)
    /// @param tier The rebate tier
    function setPrimaryRebatePercent(UD60x18 percent, RebateTier tier) external;

    /// @notice Sets the secondary rebate percent - caller must be owner
    /// @param percent The secondary rebate percent (18 decimals)
    function setSecondaryRebatePercent(UD60x18 percent) external;

    /// @notice Pulls the total rebate amount from msg.sender - caller must be an authorized pool
    /// @dev The tokens must be approved for transfer
    /// @param user The address of the user
    /// @param referrer The address of the primary referrer
    /// @param token The address of the token
    /// @param primaryRebate The primary rebate amount (18 decimals)
    /// @param secondaryRebate The secondary rebate amount (18 decimals)
    function useReferral(
        address user,
        address referrer,
        address token,
        UD60x18 primaryRebate,
        UD60x18 secondaryRebate
    ) external;

    /// @notice Claims the rebates for the msg.sender
    /// @param tokens The tokens to claim
    function claimRebate(address[] memory tokens) external;
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";
import {IERC20Metadata} from "@solidstate/contracts/token/ERC20/metadata/IERC20Metadata.sol";
import {UD60x18} from "@prb/math/UD60x18.sol";

import {OptionMath} from "../libraries/OptionMath.sol";

import {IReferral} from "./IReferral.sol";

library ReferralStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.storage.Referral");

    struct Layout {
        UD60x18[] primaryRebatePercents;
        UD60x18 secondaryRebatePercent;
        mapping(address user => IReferral.RebateTier tier) rebateTiers;
        mapping(address user => address referrer) referrals;
        mapping(address user => mapping(address token => uint256 amount)) rebates;
        mapping(address user => EnumerableSet.AddressSet tokens) rebateTokens;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @notice Adjust decimals of `value` with 18 decimals to match the `token` decimals
    function toTokenDecimals(address token, UD60x18 value) internal view returns (uint256) {
        uint8 decimals = IERC20Metadata(token).decimals();
        return OptionMath.scaleDecimals(value.unwrap(), 18, decimals);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from './IERC173Internal.sol';

/**
 * @title Contract ownership standard interface
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173 is IERC173Internal {
    /**
     * @notice get the ERC173 contract owner
     * @return contract owner
     */
    function owner() external view returns (address);

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    error AddressUtils__InsufficientBalance();
    error AddressUtils__NotContract();
    error AddressUtils__SendValueFailed();

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        if (!success) revert AddressUtils__SendValueFailed();
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance)
            revert AddressUtils__InsufficientBalance();
        return _functionCallWithValue(target, data, value, error);
    }

    /**
     * @notice execute arbitrary external call with limited gas usage and amount of copied return data
     * @dev derived from https://github.com/nomad-xyz/ExcessivelySafeCall (MIT License)
     * @param target recipient of call
     * @param gasAmount gas allowance for call
     * @param value native token value to include in call
     * @param maxCopy maximum number of bytes to copy from return data
     * @param data encoded call data
     * @return success whether call is successful
     * @return returnData copied return data
     */
    function excessivelySafeCall(
        address target,
        uint256 gasAmount,
        uint256 value,
        uint16 maxCopy,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {
        returnData = new bytes(maxCopy);

        assembly {
            // execute external call via assembly to avoid automatic copying of return data
            success := call(
                gasAmount,
                target,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )

            // determine whether to limit amount of data to copy
            let toCopy := returndatasize()

            if gt(toCopy, maxCopy) {
                toCopy := maxCopy
            }

            // store the length of the copied bytes
            mstore(returnData, toCopy)

            // copy the bytes from returndata[0:toCopy]
            returndatacopy(add(returnData, 0x20), 0, toCopy)
        }
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from '../../interfaces/IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {
    error Ownable__NotOwner();
    error Ownable__NotTransitiveOwner();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC20 interface needed by internal functions
 */
interface IERC20Internal {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IReentrancyGuard {
    error ReentrancyGuard__ReentrantCall();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ReentrancyGuardStorage {
    struct Layout {
        uint256 status;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ReentrancyGuard');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./Errors.sol" as CastingErrors;
import { MAX_UINT128, MAX_UINT40 } from "../Common.sol";
import { uMAX_SD1x18 } from "../sd1x18/Constants.sol";
import { SD1x18 } from "../sd1x18/ValueType.sol";
import { uMAX_SD59x18 } from "../sd59x18/Constants.sol";
import { SD59x18 } from "../sd59x18/ValueType.sol";
import { uMAX_UD2x18 } from "../ud2x18/Constants.sol";
import { UD2x18 } from "../ud2x18/ValueType.sol";
import { UD60x18 } from "./ValueType.sol";

/// @notice Casts a UD60x18 number into SD1x18.
/// @dev Requirements:
/// - x must be less than or equal to `uMAX_SD1x18`.
function intoSD1x18(UD60x18 x) pure returns (SD1x18 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > uint256(int256(uMAX_SD1x18))) {
        revert CastingErrors.PRBMath_UD60x18_IntoSD1x18_Overflow(x);
    }
    result = SD1x18.wrap(int64(uint64(xUint)));
}

/// @notice Casts a UD60x18 number into UD2x18.
/// @dev Requirements:
/// - x must be less than or equal to `uMAX_UD2x18`.
function intoUD2x18(UD60x18 x) pure returns (UD2x18 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > uMAX_UD2x18) {
        revert CastingErrors.PRBMath_UD60x18_IntoUD2x18_Overflow(x);
    }
    result = UD2x18.wrap(uint64(xUint));
}

/// @notice Casts a UD60x18 number into SD59x18.
/// @dev Requirements:
/// - x must be less than or equal to `uMAX_SD59x18`.
function intoSD59x18(UD60x18 x) pure returns (SD59x18 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > uint256(uMAX_SD59x18)) {
        revert CastingErrors.PRBMath_UD60x18_IntoSD59x18_Overflow(x);
    }
    result = SD59x18.wrap(int256(xUint));
}

/// @notice Casts a UD60x18 number into uint128.
/// @dev This is basically an alias for {unwrap}.
function intoUint256(UD60x18 x) pure returns (uint256 result) {
    result = UD60x18.unwrap(x);
}

/// @notice Casts a UD60x18 number into uint128.
/// @dev Requirements:
/// - x must be less than or equal to `MAX_UINT128`.
function intoUint128(UD60x18 x) pure returns (uint128 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > MAX_UINT128) {
        revert CastingErrors.PRBMath_UD60x18_IntoUint128_Overflow(x);
    }
    result = uint128(xUint);
}

/// @notice Casts a UD60x18 number into uint40.
/// @dev Requirements:
/// - x must be less than or equal to `MAX_UINT40`.
function intoUint40(UD60x18 x) pure returns (uint40 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > MAX_UINT40) {
        revert CastingErrors.PRBMath_UD60x18_IntoUint40_Overflow(x);
    }
    result = uint40(xUint);
}

/// @notice Alias for {wrap}.
function ud(uint256 x) pure returns (UD60x18 result) {
    result = UD60x18.wrap(x);
}

/// @notice Alias for {wrap}.
function ud60x18(uint256 x) pure returns (UD60x18 result) {
    result = UD60x18.wrap(x);
}

/// @notice Unwraps a UD60x18 number into uint256.
function unwrap(UD60x18 x) pure returns (uint256 result) {
    result = UD60x18.unwrap(x);
}

/// @notice Wraps a uint256 number into the UD60x18 value type.
function wrap(uint256 x) pure returns (UD60x18 result) {
    result = UD60x18.wrap(x);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { UD60x18 } from "./ValueType.sol";

// NOTICE: the "u" prefix stands for "unwrapped".

/// @dev Euler's number as a UD60x18 number.
UD60x18 constant E = UD60x18.wrap(2_718281828459045235);

/// @dev The maximum input permitted in {exp}.
uint256 constant uEXP_MAX_INPUT = 133_084258667509499440;
UD60x18 constant EXP_MAX_INPUT = UD60x18.wrap(uEXP_MAX_INPUT);

/// @dev The maximum input permitted in {exp2}.
uint256 constant uEXP2_MAX_INPUT = 192e18 - 1;
UD60x18 constant EXP2_MAX_INPUT = UD60x18.wrap(uEXP2_MAX_INPUT);

/// @dev Half the UNIT number.
uint256 constant uHALF_UNIT = 0.5e18;
UD60x18 constant HALF_UNIT = UD60x18.wrap(uHALF_UNIT);

/// @dev $log_2(10)$ as a UD60x18 number.
uint256 constant uLOG2_10 = 3_321928094887362347;
UD60x18 constant LOG2_10 = UD60x18.wrap(uLOG2_10);

/// @dev $log_2(e)$ as a UD60x18 number.
uint256 constant uLOG2_E = 1_442695040888963407;
UD60x18 constant LOG2_E = UD60x18.wrap(uLOG2_E);

/// @dev The maximum value a UD60x18 number can have.
uint256 constant uMAX_UD60x18 = 115792089237316195423570985008687907853269984665640564039457_584007913129639935;
UD60x18 constant MAX_UD60x18 = UD60x18.wrap(uMAX_UD60x18);

/// @dev The maximum whole value a UD60x18 number can have.
uint256 constant uMAX_WHOLE_UD60x18 = 115792089237316195423570985008687907853269984665640564039457_000000000000000000;
UD60x18 constant MAX_WHOLE_UD60x18 = UD60x18.wrap(uMAX_WHOLE_UD60x18);

/// @dev PI as a UD60x18 number.
UD60x18 constant PI = UD60x18.wrap(3_141592653589793238);

/// @dev The unit number, which gives the decimal precision of UD60x18.
uint256 constant uUNIT = 1e18;
UD60x18 constant UNIT = UD60x18.wrap(uUNIT);

/// @dev The unit number squared.
uint256 constant uUNIT_SQUARED = 1e36;
UD60x18 constant UNIT_SQUARED = UD60x18.wrap(uUNIT_SQUARED);

/// @dev Zero as a UD60x18 number.
UD60x18 constant ZERO = UD60x18.wrap(0);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { uMAX_UD60x18, uUNIT } from "./Constants.sol";
import { PRBMath_UD60x18_Convert_Overflow } from "./Errors.sol";
import { UD60x18 } from "./ValueType.sol";

/// @notice Converts a UD60x18 number to a simple integer by dividing it by `UNIT`.
/// @dev The result is rounded down.
/// @param x The UD60x18 number to convert.
/// @return result The same number in basic integer form.
function convert(UD60x18 x) pure returns (uint256 result) {
    result = UD60x18.unwrap(x) / uUNIT;
}

/// @notice Converts a simple integer to UD60x18 by multiplying it by `UNIT`.
///
/// @dev Requirements:
/// - x must be less than or equal to `MAX_UD60x18 / UNIT`.
///
/// @param x The basic integer to convert.
/// @param result The same number converted to UD60x18.
function convert(uint256 x) pure returns (UD60x18 result) {
    if (x > uMAX_UD60x18 / uUNIT) {
        revert PRBMath_UD60x18_Convert_Overflow(x);
    }
    unchecked {
        result = UD60x18.wrap(x * uUNIT);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { UD60x18 } from "./ValueType.sol";

/// @notice Thrown when ceiling a number overflows UD60x18.
error PRBMath_UD60x18_Ceil_Overflow(UD60x18 x);

/// @notice Thrown when converting a basic integer to the fixed-point format overflows UD60x18.
error PRBMath_UD60x18_Convert_Overflow(uint256 x);

/// @notice Thrown when taking the natural exponent of a base greater than 133_084258667509499441.
error PRBMath_UD60x18_Exp_InputTooBig(UD60x18 x);

/// @notice Thrown when taking the binary exponent of a base greater than 192e18.
error PRBMath_UD60x18_Exp2_InputTooBig(UD60x18 x);

/// @notice Thrown when taking the geometric mean of two numbers and multiplying them overflows UD60x18.
error PRBMath_UD60x18_Gm_Overflow(UD60x18 x, UD60x18 y);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in SD1x18.
error PRBMath_UD60x18_IntoSD1x18_Overflow(UD60x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in SD59x18.
error PRBMath_UD60x18_IntoSD59x18_Overflow(UD60x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in UD2x18.
error PRBMath_UD60x18_IntoUD2x18_Overflow(UD60x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint128.
error PRBMath_UD60x18_IntoUint128_Overflow(UD60x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint40.
error PRBMath_UD60x18_IntoUint40_Overflow(UD60x18 x);

/// @notice Thrown when taking the logarithm of a number less than 1.
error PRBMath_UD60x18_Log_InputTooSmall(UD60x18 x);

/// @notice Thrown when calculating the square root overflows UD60x18.
error PRBMath_UD60x18_Sqrt_Overflow(UD60x18 x);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { wrap } from "./Casting.sol";
import { UD60x18 } from "./ValueType.sol";

/// @notice Implements the checked addition operation (+) in the UD60x18 type.
function add(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() + y.unwrap());
}

/// @notice Implements the AND (&) bitwise operation in the UD60x18 type.
function and(UD60x18 x, uint256 bits) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() & bits);
}

/// @notice Implements the AND (&) bitwise operation in the UD60x18 type.
function and2(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() & y.unwrap());
}

/// @notice Implements the equal operation (==) in the UD60x18 type.
function eq(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = x.unwrap() == y.unwrap();
}

/// @notice Implements the greater than operation (>) in the UD60x18 type.
function gt(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = x.unwrap() > y.unwrap();
}

/// @notice Implements the greater than or equal to operation (>=) in the UD60x18 type.
function gte(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = x.unwrap() >= y.unwrap();
}

/// @notice Implements a zero comparison check function in the UD60x18 type.
function isZero(UD60x18 x) pure returns (bool result) {
    // This wouldn't work if x could be negative.
    result = x.unwrap() == 0;
}

/// @notice Implements the left shift operation (<<) in the UD60x18 type.
function lshift(UD60x18 x, uint256 bits) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() << bits);
}

/// @notice Implements the lower than operation (<) in the UD60x18 type.
function lt(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = x.unwrap() < y.unwrap();
}

/// @notice Implements the lower than or equal to operation (<=) in the UD60x18 type.
function lte(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = x.unwrap() <= y.unwrap();
}

/// @notice Implements the checked modulo operation (%) in the UD60x18 type.
function mod(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() % y.unwrap());
}

/// @notice Implements the not equal operation (!=) in the UD60x18 type.
function neq(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = x.unwrap() != y.unwrap();
}

/// @notice Implements the NOT (~) bitwise operation in the UD60x18 type.
function not(UD60x18 x) pure returns (UD60x18 result) {
    result = wrap(~x.unwrap());
}

/// @notice Implements the OR (|) bitwise operation in the UD60x18 type.
function or(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() | y.unwrap());
}

/// @notice Implements the right shift operation (>>) in the UD60x18 type.
function rshift(UD60x18 x, uint256 bits) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() >> bits);
}

/// @notice Implements the checked subtraction operation (-) in the UD60x18 type.
function sub(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() - y.unwrap());
}

/// @notice Implements the unchecked addition operation (+) in the UD60x18 type.
function uncheckedAdd(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    unchecked {
        result = wrap(x.unwrap() + y.unwrap());
    }
}

/// @notice Implements the unchecked subtraction operation (-) in the UD60x18 type.
function uncheckedSub(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    unchecked {
        result = wrap(x.unwrap() - y.unwrap());
    }
}

/// @notice Implements the XOR (^) bitwise operation in the UD60x18 type.
function xor(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() ^ y.unwrap());
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "../Common.sol" as Common;
import "./Errors.sol" as Errors;
import { wrap } from "./Casting.sol";
import {
    uEXP_MAX_INPUT,
    uEXP2_MAX_INPUT,
    uHALF_UNIT,
    uLOG2_10,
    uLOG2_E,
    uMAX_UD60x18,
    uMAX_WHOLE_UD60x18,
    UNIT,
    uUNIT,
    uUNIT_SQUARED,
    ZERO
} from "./Constants.sol";
import { UD60x18 } from "./ValueType.sol";

/*//////////////////////////////////////////////////////////////////////////
                            MATHEMATICAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

/// @notice Calculates the arithmetic average of x and y using the following formula:
///
/// $$
/// avg(x, y) = (x & y) + ((xUint ^ yUint) / 2)
/// $$
//
/// In English, this is what this formula does:
///
/// 1. AND x and y.
/// 2. Calculate half of XOR x and y.
/// 3. Add the two results together.
///
/// This technique is known as SWAR, which stands for "SIMD within a register". You can read more about it here:
/// https://devblogs.microsoft.com/oldnewthing/20220207-00/?p=106223
///
/// @dev Notes:
/// - The result is rounded down.
///
/// @param x The first operand as a UD60x18 number.
/// @param y The second operand as a UD60x18 number.
/// @return result The arithmetic average as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function avg(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();
    uint256 yUint = y.unwrap();
    unchecked {
        result = wrap((xUint & yUint) + ((xUint ^ yUint) >> 1));
    }
}

/// @notice Yields the smallest whole number greater than or equal to x.
///
/// @dev This is optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional
/// counterparts. See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
///
/// Requirements:
/// - x must be less than or equal to `MAX_WHOLE_UD60x18`.
///
/// @param x The UD60x18 number to ceil.
/// @param result The smallest whole number greater than or equal to x, as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function ceil(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();
    if (xUint > uMAX_WHOLE_UD60x18) {
        revert Errors.PRBMath_UD60x18_Ceil_Overflow(x);
    }

    assembly ("memory-safe") {
        // Equivalent to `x % UNIT`.
        let remainder := mod(x, uUNIT)

        // Equivalent to `UNIT - remainder`.
        let delta := sub(uUNIT, remainder)

        // Equivalent to `x + delta * (remainder > 0 ? 1 : 0)`.
        result := add(x, mul(delta, gt(remainder, 0)))
    }
}

/// @notice Divides two UD60x18 numbers, returning a new UD60x18 number.
///
/// @dev Uses {Common.mulDiv} to enable overflow-safe multiplication and division.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv}.
///
/// Requirements:
/// - Refer to the requirements in {Common.mulDiv}.
///
/// @param x The numerator as a UD60x18 number.
/// @param y The denominator as a UD60x18 number.
/// @param result The quotient as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function div(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(Common.mulDiv(x.unwrap(), uUNIT, y.unwrap()));
}

/// @notice Calculates the natural exponent of x using the following formula:
///
/// $$
/// e^x = 2^{x * log_2{e}}
/// $$
///
/// @dev Requirements:
/// - x must be less than 133_084258667509499441.
///
/// @param x The exponent as a UD60x18 number.
/// @return result The result as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function exp(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();

    // This check prevents values greater than 192 from being passed to {exp2}.
    if (xUint > uEXP_MAX_INPUT) {
        revert Errors.PRBMath_UD60x18_Exp_InputTooBig(x);
    }

    unchecked {
        // Inline the fixed-point multiplication to save gas.
        uint256 doubleUnitProduct = xUint * uLOG2_E;
        result = exp2(wrap(doubleUnitProduct / uUNIT));
    }
}

/// @notice Calculates the binary exponent of x using the binary fraction method.
///
/// @dev See https://ethereum.stackexchange.com/q/79903/24693
///
/// Requirements:
/// - x must be less than 192e18.
/// - The result must fit in UD60x18.
///
/// @param x The exponent as a UD60x18 number.
/// @return result The result as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function exp2(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();

    // Numbers greater than or equal to 192e18 don't fit in the 192.64-bit format.
    if (xUint > uEXP2_MAX_INPUT) {
        revert Errors.PRBMath_UD60x18_Exp2_InputTooBig(x);
    }

    // Convert x to the 192.64-bit fixed-point format.
    uint256 x_192x64 = (xUint << 64) / uUNIT;

    // Pass x to the {Common.exp2} function, which uses the 192.64-bit fixed-point number representation.
    result = wrap(Common.exp2(x_192x64));
}

/// @notice Yields the greatest whole number less than or equal to x.
/// @dev Optimized for fractional value inputs, because every whole value has (1e18 - 1) fractional counterparts.
/// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
/// @param x The UD60x18 number to floor.
/// @param result The greatest whole number less than or equal to x, as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function floor(UD60x18 x) pure returns (UD60x18 result) {
    assembly ("memory-safe") {
        // Equivalent to `x % UNIT`.
        let remainder := mod(x, uUNIT)

        // Equivalent to `x - remainder * (remainder > 0 ? 1 : 0)`.
        result := sub(x, mul(remainder, gt(remainder, 0)))
    }
}

/// @notice Yields the excess beyond the floor of x using the odd function definition.
/// @dev See https://en.wikipedia.org/wiki/Fractional_part.
/// @param x The UD60x18 number to get the fractional part of.
/// @param result The fractional part of x as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function frac(UD60x18 x) pure returns (UD60x18 result) {
    assembly ("memory-safe") {
        result := mod(x, uUNIT)
    }
}

/// @notice Calculates the geometric mean of x and y, i.e. $\sqrt{x * y}$, rounding down.
///
/// @dev Requirements:
/// - x * y must fit in UD60x18.
///
/// @param x The first operand as a UD60x18 number.
/// @param y The second operand as a UD60x18 number.
/// @return result The result as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function gm(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();
    uint256 yUint = y.unwrap();
    if (xUint == 0 || yUint == 0) {
        return ZERO;
    }

    unchecked {
        // Checking for overflow this way is faster than letting Solidity do it.
        uint256 xyUint = xUint * yUint;
        if (xyUint / xUint != yUint) {
            revert Errors.PRBMath_UD60x18_Gm_Overflow(x, y);
        }

        // We don't need to multiply the result by `UNIT` here because the x*y product picked up a factor of `UNIT`
        // during multiplication. See the comments in {Common.sqrt}.
        result = wrap(Common.sqrt(xyUint));
    }
}

/// @notice Calculates the inverse of x.
///
/// @dev Notes:
/// - The result is rounded down.
///
/// Requirements:
/// - x must not be zero.
///
/// @param x The UD60x18 number for which to calculate the inverse.
/// @return result The inverse as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function inv(UD60x18 x) pure returns (UD60x18 result) {
    unchecked {
        result = wrap(uUNIT_SQUARED / x.unwrap());
    }
}

/// @notice Calculates the natural logarithm of x using the following formula:
///
/// $$
/// ln{x} = log_2{x} / log_2{e}
/// $$
///
/// @dev Notes:
/// - Refer to the notes in {log2}.
/// - The precision isn't sufficiently fine-grained to return exactly `UNIT` when the input is `E`.
///
/// Requirements:
/// - Refer to the requirements in {log2}.
///
/// @param x The UD60x18 number for which to calculate the natural logarithm.
/// @return result The natural logarithm as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function ln(UD60x18 x) pure returns (UD60x18 result) {
    unchecked {
        // Inline the fixed-point multiplication to save gas. This is overflow-safe because the maximum value that
        // {log2} can return is ~196_205294292027477728.
        result = wrap(log2(x).unwrap() * uUNIT / uLOG2_E);
    }
}

/// @notice Calculates the common logarithm of x using the following formula:
///
/// $$
/// log_{10}{x} = log_2{x} / log_2{10}
/// $$
///
/// However, if x is an exact power of ten, a hard coded value is returned.
///
/// @dev Notes:
/// - Refer to the notes in {log2}.
///
/// Requirements:
/// - Refer to the requirements in {log2}.
///
/// @param x The UD60x18 number for which to calculate the common logarithm.
/// @return result The common logarithm as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function log10(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();
    if (xUint < uUNIT) {
        revert Errors.PRBMath_UD60x18_Log_InputTooSmall(x);
    }

    // Note that the `mul` in this assembly block is the standard multiplication operation, not {UD60x18.mul}.
    // prettier-ignore
    assembly ("memory-safe") {
        switch x
        case 1 { result := mul(uUNIT, sub(0, 18)) }
        case 10 { result := mul(uUNIT, sub(1, 18)) }
        case 100 { result := mul(uUNIT, sub(2, 18)) }
        case 1000 { result := mul(uUNIT, sub(3, 18)) }
        case 10000 { result := mul(uUNIT, sub(4, 18)) }
        case 100000 { result := mul(uUNIT, sub(5, 18)) }
        case 1000000 { result := mul(uUNIT, sub(6, 18)) }
        case 10000000 { result := mul(uUNIT, sub(7, 18)) }
        case 100000000 { result := mul(uUNIT, sub(8, 18)) }
        case 1000000000 { result := mul(uUNIT, sub(9, 18)) }
        case 10000000000 { result := mul(uUNIT, sub(10, 18)) }
        case 100000000000 { result := mul(uUNIT, sub(11, 18)) }
        case 1000000000000 { result := mul(uUNIT, sub(12, 18)) }
        case 10000000000000 { result := mul(uUNIT, sub(13, 18)) }
        case 100000000000000 { result := mul(uUNIT, sub(14, 18)) }
        case 1000000000000000 { result := mul(uUNIT, sub(15, 18)) }
        case 10000000000000000 { result := mul(uUNIT, sub(16, 18)) }
        case 100000000000000000 { result := mul(uUNIT, sub(17, 18)) }
        case 1000000000000000000 { result := 0 }
        case 10000000000000000000 { result := uUNIT }
        case 100000000000000000000 { result := mul(uUNIT, 2) }
        case 1000000000000000000000 { result := mul(uUNIT, 3) }
        case 10000000000000000000000 { result := mul(uUNIT, 4) }
        case 100000000000000000000000 { result := mul(uUNIT, 5) }
        case 1000000000000000000000000 { result := mul(uUNIT, 6) }
        case 10000000000000000000000000 { result := mul(uUNIT, 7) }
        case 100000000000000000000000000 { result := mul(uUNIT, 8) }
        case 1000000000000000000000000000 { result := mul(uUNIT, 9) }
        case 10000000000000000000000000000 { result := mul(uUNIT, 10) }
        case 100000000000000000000000000000 { result := mul(uUNIT, 11) }
        case 1000000000000000000000000000000 { result := mul(uUNIT, 12) }
        case 10000000000000000000000000000000 { result := mul(uUNIT, 13) }
        case 100000000000000000000000000000000 { result := mul(uUNIT, 14) }
        case 1000000000000000000000000000000000 { result := mul(uUNIT, 15) }
        case 10000000000000000000000000000000000 { result := mul(uUNIT, 16) }
        case 100000000000000000000000000000000000 { result := mul(uUNIT, 17) }
        case 1000000000000000000000000000000000000 { result := mul(uUNIT, 18) }
        case 10000000000000000000000000000000000000 { result := mul(uUNIT, 19) }
        case 100000000000000000000000000000000000000 { result := mul(uUNIT, 20) }
        case 1000000000000000000000000000000000000000 { result := mul(uUNIT, 21) }
        case 10000000000000000000000000000000000000000 { result := mul(uUNIT, 22) }
        case 100000000000000000000000000000000000000000 { result := mul(uUNIT, 23) }
        case 1000000000000000000000000000000000000000000 { result := mul(uUNIT, 24) }
        case 10000000000000000000000000000000000000000000 { result := mul(uUNIT, 25) }
        case 100000000000000000000000000000000000000000000 { result := mul(uUNIT, 26) }
        case 1000000000000000000000000000000000000000000000 { result := mul(uUNIT, 27) }
        case 10000000000000000000000000000000000000000000000 { result := mul(uUNIT, 28) }
        case 100000000000000000000000000000000000000000000000 { result := mul(uUNIT, 29) }
        case 1000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 30) }
        case 10000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 31) }
        case 100000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 32) }
        case 1000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 33) }
        case 10000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 34) }
        case 100000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 35) }
        case 1000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 36) }
        case 10000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 37) }
        case 100000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 38) }
        case 1000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 39) }
        case 10000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 40) }
        case 100000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 41) }
        case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 42) }
        case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 43) }
        case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 44) }
        case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 45) }
        case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 46) }
        case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 47) }
        case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 48) }
        case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 49) }
        case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 50) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 51) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 52) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 53) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 54) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 55) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 56) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 57) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 58) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 59) }
        default { result := uMAX_UD60x18 }
    }

    if (result.unwrap() == uMAX_UD60x18) {
        unchecked {
            // Inline the fixed-point division to save gas.
            result = wrap(log2(x).unwrap() * uUNIT / uLOG2_10);
        }
    }
}

/// @notice Calculates the binary logarithm of x using the iterative approximation algorithm.
///
/// For $0 \leq x < 1$, the logarithm is calculated as:
///
/// $$
/// log_2{x} = -log_2{\frac{1}{x}}
/// $$
///
/// @dev See https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
///
/// Notes:
/// - Due to the lossy precision of the iterative approximation, the results are not perfectly accurate to the last decimal.
///
/// Requirements:
/// - x must be greater than zero.
///
/// @param x The UD60x18 number for which to calculate the binary logarithm.
/// @return result The binary logarithm as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function log2(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();

    if (xUint < uUNIT) {
        revert Errors.PRBMath_UD60x18_Log_InputTooSmall(x);
    }

    unchecked {
        // Calculate the integer part of the logarithm, add it to the result and finally calculate $y = x * 2^{-n}$.
        uint256 n = Common.msb(xUint / uUNIT);

        // This is the integer part of the logarithm as a UD60x18 number. The operation can't overflow because n
        // n is at most 255 and UNIT is 1e18.
        uint256 resultUint = n * uUNIT;

        // This is $y = x * 2^{-n}$.
        uint256 y = xUint >> n;

        // If y is the unit number, the fractional part is zero.
        if (y == uUNIT) {
            return wrap(resultUint);
        }

        // Calculate the fractional part via the iterative approximation.
        // The `delta >>= 1` part is equivalent to `delta /= 2`, but shifting bits is more gas efficient.
        uint256 DOUBLE_UNIT = 2e18;
        for (uint256 delta = uHALF_UNIT; delta > 0; delta >>= 1) {
            y = (y * y) / uUNIT;

            // Is y^2 >= 2e18 and so in the range [2e18, 4e18)?
            if (y >= DOUBLE_UNIT) {
                // Add the 2^{-m} factor to the logarithm.
                resultUint += delta;

                // Corresponds to z/2 in the Wikipedia article.
                y >>= 1;
            }
        }
        result = wrap(resultUint);
    }
}

/// @notice Multiplies two UD60x18 numbers together, returning a new UD60x18 number.
///
/// @dev Uses {Common.mulDiv} to enable overflow-safe multiplication and division.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv}.
///
/// Requirements:
/// - Refer to the requirements in {Common.mulDiv}.
///
/// @dev See the documentation in {Common.mulDiv18}.
/// @param x The multiplicand as a UD60x18 number.
/// @param y The multiplier as a UD60x18 number.
/// @return result The product as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function mul(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(Common.mulDiv18(x.unwrap(), y.unwrap()));
}

/// @notice Raises x to the power of y.
///
/// For $1 \leq x \leq \infty$, the following standard formula is used:
///
/// $$
/// x^y = 2^{log_2{x} * y}
/// $$
///
/// For $0 \leq x \lt 1$, since the unsigned {log2} is undefined, an equivalent formula is used:
///
/// $$
/// i = \frac{1}{x}
/// w = 2^{log_2{i} * y}
/// x^y = \frac{1}{w}
/// $$
///
/// @dev Notes:
/// - Refer to the notes in {log2} and {mul}.
/// - Returns `UNIT` for 0^0.
/// - It may not perform well with very small values of x. Consider using SD59x18 as an alternative.
///
/// Requirements:
/// - Refer to the requirements in {exp2}, {log2}, and {mul}.
///
/// @param x The base as a UD60x18 number.
/// @param y The exponent as a UD60x18 number.
/// @return result The result as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function pow(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();
    uint256 yUint = y.unwrap();

    // If both x and y are zero, the result is `UNIT`. If just x is zero, the result is always zero.
    if (xUint == 0) {
        return yUint == 0 ? UNIT : ZERO;
    }
    // If x is `UNIT`, the result is always `UNIT`.
    else if (xUint == uUNIT) {
        return UNIT;
    }

    // If y is zero, the result is always `UNIT`.
    if (yUint == 0) {
        return UNIT;
    }
    // If y is `UNIT`, the result is always x.
    else if (yUint == uUNIT) {
        return x;
    }

    // If x is greater than `UNIT`, use the standard formula.
    if (xUint > uUNIT) {
        result = exp2(mul(log2(x), y));
    }
    // Conversely, if x is less than `UNIT`, use the equivalent formula.
    else {
        UD60x18 i = wrap(uUNIT_SQUARED / xUint);
        UD60x18 w = exp2(mul(log2(i), y));
        result = wrap(uUNIT_SQUARED / w.unwrap());
    }
}

/// @notice Raises x (a UD60x18 number) to the power y (an unsigned basic integer) using the well-known
/// algorithm "exponentiation by squaring".
///
/// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv18}.
/// - Returns `UNIT` for 0^0.
///
/// Requirements:
/// - The result must fit in UD60x18.
///
/// @param x The base as a UD60x18 number.
/// @param y The exponent as a uint256.
/// @return result The result as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function powu(UD60x18 x, uint256 y) pure returns (UD60x18 result) {
    // Calculate the first iteration of the loop in advance.
    uint256 xUint = x.unwrap();
    uint256 resultUint = y & 1 > 0 ? xUint : uUNIT;

    // Equivalent to `for(y /= 2; y > 0; y /= 2)`.
    for (y >>= 1; y > 0; y >>= 1) {
        xUint = Common.mulDiv18(xUint, xUint);

        // Equivalent to `y % 2 == 1`.
        if (y & 1 > 0) {
            resultUint = Common.mulDiv18(resultUint, xUint);
        }
    }
    result = wrap(resultUint);
}

/// @notice Calculates the square root of x using the Babylonian method.
///
/// @dev See https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
///
/// Notes:
/// - The result is rounded down.
///
/// Requirements:
/// - x must be less than `MAX_UD60x18 / UNIT`.
///
/// @param x The UD60x18 number for which to calculate the square root.
/// @return result The result as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function sqrt(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();

    unchecked {
        if (xUint > uMAX_UD60x18 / uUNIT) {
            revert Errors.PRBMath_UD60x18_Sqrt_Overflow(x);
        }
        // Multiply x by `UNIT` to account for the factor of `UNIT` picked up when multiplying two UD60x18 numbers.
        // In this case, the two numbers are both the square root.
        result = wrap(Common.sqrt(xUint * uUNIT));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./Casting.sol" as Casting;
import "./Helpers.sol" as Helpers;
import "./Math.sol" as Math;

/// @notice The unsigned 60.18-decimal fixed-point number representation, which can have up to 60 digits and up to 18
/// decimals. The values of this are bound by the minimum and the maximum values permitted by the Solidity type uint256.
/// @dev The value type is defined here so it can be imported in all other files.
type UD60x18 is uint256;

/*//////////////////////////////////////////////////////////////////////////
                                    CASTING
//////////////////////////////////////////////////////////////////////////*/

using {
    Casting.intoSD1x18,
    Casting.intoUD2x18,
    Casting.intoSD59x18,
    Casting.intoUint128,
    Casting.intoUint256,
    Casting.intoUint40,
    Casting.unwrap
} for UD60x18 global;

/*//////////////////////////////////////////////////////////////////////////
                            MATHEMATICAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

// The global "using for" directive makes the functions in this library callable on the UD60x18 type.
using {
    Math.avg,
    Math.ceil,
    Math.div,
    Math.exp,
    Math.exp2,
    Math.floor,
    Math.frac,
    Math.gm,
    Math.inv,
    Math.ln,
    Math.log10,
    Math.log2,
    Math.mul,
    Math.pow,
    Math.powu,
    Math.sqrt
} for UD60x18 global;

/*//////////////////////////////////////////////////////////////////////////
                                HELPER FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

// The global "using for" directive makes the functions in this library callable on the UD60x18 type.
using {
    Helpers.add,
    Helpers.and,
    Helpers.eq,
    Helpers.gt,
    Helpers.gte,
    Helpers.isZero,
    Helpers.lshift,
    Helpers.lt,
    Helpers.lte,
    Helpers.mod,
    Helpers.neq,
    Helpers.not,
    Helpers.or,
    Helpers.rshift,
    Helpers.sub,
    Helpers.uncheckedAdd,
    Helpers.uncheckedSub,
    Helpers.xor
} for UD60x18 global;

/*//////////////////////////////////////////////////////////////////////////
                                    OPERATORS
//////////////////////////////////////////////////////////////////////////*/

// The global "using for" directive makes it possible to use these operators on the UD60x18 type.
using {
    Helpers.add as +,
    Helpers.and2 as &,
    Math.div as /,
    Helpers.eq as ==,
    Helpers.gt as >,
    Helpers.gte as >=,
    Helpers.lt as <,
    Helpers.lte as <=,
    Helpers.or as |,
    Helpers.mod as %,
    Math.mul as *,
    Helpers.neq as !=,
    Helpers.not as ~,
    Helpers.sub as -,
    Helpers.xor as ^
} for UD60x18 global;

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   https://aa.usno.navy.mil/faq/JD_formula.html
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

/*

██████╗ ██████╗ ██████╗ ███╗   ███╗ █████╗ ████████╗██╗  ██╗
██╔══██╗██╔══██╗██╔══██╗████╗ ████║██╔══██╗╚══██╔══╝██║  ██║
██████╔╝██████╔╝██████╔╝██╔████╔██║███████║   ██║   ███████║
██╔═══╝ ██╔══██╗██╔══██╗██║╚██╔╝██║██╔══██║   ██║   ██╔══██║
██║     ██║  ██║██████╔╝██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║
╚═╝     ╚═╝  ╚═╝╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝

███████╗██████╗ ███████╗ █████╗ ██╗  ██╗ ██╗ █████╗
██╔════╝██╔══██╗██╔════╝██╔══██╗╚██╗██╔╝███║██╔══██╗
███████╗██║  ██║███████╗╚██████║ ╚███╔╝ ╚██║╚█████╔╝
╚════██║██║  ██║╚════██║ ╚═══██║ ██╔██╗  ██║██╔══██╗
███████║██████╔╝███████║ █████╔╝██╔╝ ██╗ ██║╚█████╔╝
╚══════╝╚═════╝ ╚══════╝ ╚════╝ ╚═╝  ╚═╝ ╚═╝ ╚════╝

*/

import "./sd59x18/Casting.sol";
import "./sd59x18/Constants.sol";
import "./sd59x18/Conversions.sol";
import "./sd59x18/Errors.sol";
import "./sd59x18/Helpers.sol";
import "./sd59x18/Math.sol";
import "./sd59x18/ValueType.sol";

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "@prb/math/UD60x18.sol";
import {SD59x18} from "@prb/math/SD59x18.sol";
import {UD50x28} from "./UD50x28.sol";
import {SD49x28} from "./SD49x28.sol";

UD60x18 constant ZERO = UD60x18.wrap(0);
UD60x18 constant ONE_HALF = UD60x18.wrap(0.5e18);
UD60x18 constant ONE = UD60x18.wrap(1e18);
UD60x18 constant TWO = UD60x18.wrap(2e18);
UD60x18 constant THREE = UD60x18.wrap(3e18);
UD60x18 constant FIVE = UD60x18.wrap(5e18);

SD59x18 constant iZERO = SD59x18.wrap(0);
SD59x18 constant iONE = SD59x18.wrap(1e18);
SD59x18 constant iTWO = SD59x18.wrap(2e18);
SD59x18 constant iFOUR = SD59x18.wrap(4e18);
SD59x18 constant iNINE = SD59x18.wrap(9e18);

UD50x28 constant UD50_ZERO = UD50x28.wrap(0);
UD50x28 constant UD50_ONE = UD50x28.wrap(1e28);
UD50x28 constant UD50_TWO = UD50x28.wrap(2e28);

SD49x28 constant SD49_ZERO = SD49x28.wrap(0);
SD49x28 constant SD49_ONE = SD49x28.wrap(1e28);
SD49x28 constant SD49_TWO = SD49x28.wrap(2e28);

uint256 constant WAD = 1e18;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Denominations {
  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

  // Fiat currencies follow https://en.wikipedia.org/wiki/ISO_4217
  address public constant USD = address(840);
  address public constant GBP = address(826);
  address public constant EUR = address(978);
  address public constant JPY = address(392);
  address public constant KRW = address(410);
  address public constant CNY = address(156);
  address public constant AUD = address(36);
  address public constant CAD = address(124);
  address public constant CHF = address(756);
  address public constant ARS = address(32);
  address public constant PHP = address(608);
  address public constant NZD = address(554);
  address public constant SGD = address(702);
  address public constant NGN = address(566);
  address public constant ZAR = address(710);
  address public constant RUB = address(643);
  address public constant INR = address(356);
  address public constant BRL = address(986);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "@prb/math/UD60x18.sol";

import {IPoolFactoryEvents} from "./IPoolFactoryEvents.sol";

interface IPoolFactory is IPoolFactoryEvents {
    error PoolFactory__IdenticalAddresses();
    error PoolFactory__InitializationFeeIsZero();
    error PoolFactory__InitializationFeeRequired(uint256 msgValue, uint256 fee);
    error PoolFactory__InvalidInput();
    error PoolFactory__InvalidOracleAdapter();
    error PoolFactory__NotAuthorized();
    error PoolFactory__OptionExpired(uint256 maturity);
    error PoolFactory__OptionMaturityExceedsMax(uint256 maturity);
    error PoolFactory__OptionMaturityNot8UTC(uint256 maturity);
    error PoolFactory__OptionMaturityNotFriday(uint256 maturity);
    error PoolFactory__OptionMaturityNotLastFriday(uint256 maturity);
    error PoolFactory__OptionStrikeEqualsZero();
    error PoolFactory__OptionStrikeInvalid(UD60x18 strike, UD60x18 strikeInterval);
    error PoolFactory__PoolAlreadyDeployed(address poolAddress);
    error PoolFactory__PoolNotExpired();
    error PoolFactory__TransferNativeTokenFailed();
    error PoolFactory__ZeroAddress();

    struct PoolKey {
        // Address of base token
        address base;
        // Address of quote token
        address quote;
        // Address of oracle adapter
        address oracleAdapter;
        // The strike of the option (18 decimals)
        UD60x18 strike;
        // The maturity timestamp of the option
        uint256 maturity;
        // Whether the pool is for call or put options
        bool isCallPool;
    }

    /// @notice Returns whether the given address is a pool
    /// @param contractAddress The address to check
    /// @return Whether the given address is a pool
    function isPool(address contractAddress) external view returns (bool);

    /// @notice Returns the address of a valid pool, and whether it has been deployed. If the pool configuration is invalid
    ///         the transaction will revert.
    /// @param k The pool key
    /// @return pool The pool address
    /// @return isDeployed Whether the pool has been deployed
    function getPoolAddress(PoolKey calldata k) external view returns (address pool, bool isDeployed);

    /// @notice Set the discountPerPool for new pools - only callable by owner
    /// @param discountPerPool The new discount percentage (18 decimals)
    function setDiscountPerPool(UD60x18 discountPerPool) external;

    /// @notice Set the feeReceiver for initialization fees - only callable by owner
    /// @param feeReceiver The new fee receiver address
    function setFeeReceiver(address feeReceiver) external;

    /// @notice Deploy a new option pool
    /// @param k The pool key
    /// @return poolAddress The address of the deployed pool
    function deployPool(PoolKey calldata k) external payable returns (address poolAddress);

    /// @notice Removes the discount caused by an existing pool, can only be called by the pool after maturity
    /// @param k The pool key
    function removeDiscount(PoolKey calldata k) external;

    /// @notice Calculates the initialization fee for a pool
    /// @param k The pool key
    /// @return The initialization fee (18 decimals)
    function initializationFee(PoolKey calldata k) external view returns (UD60x18);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {IPoolFactory} from "./IPoolFactory.sol";

interface IPoolFactoryDeployer {
    error PoolFactoryDeployer__NotPoolFactory(address caller);

    /// @notice Deploy a new option pool
    /// @param k The pool key
    /// @return poolAddress The address of the deployed pool
    function deployPool(IPoolFactory.PoolKey calldata k) external returns (address poolAddress);

    /// @notice Calculate the deterministic address deployment of a pool
    function calculatePoolAddress(IPoolFactory.PoolKey calldata k) external view returns (address);
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "@prb/math/UD60x18.sol";

import {IPoolFactory} from "./IPoolFactory.sol";

library PoolFactoryStorage {
    using PoolFactoryStorage for PoolFactoryStorage.Layout;

    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.storage.PoolFactory");

    struct Layout {
        mapping(bytes32 key => address pool) pools;
        mapping(address pool => bool) isPool;
        mapping(bytes32 key => uint256 count) strikeCount;
        mapping(bytes32 key => uint256 count) maturityCount;
        // Discount % per neighboring strike/maturity (18 decimals)
        UD60x18 discountPerPool;
        // Initialization fee receiver
        address feeReceiver;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @notice Returns the encoded pool key using the pool key `k`
    function poolKey(IPoolFactory.PoolKey memory k) internal pure returns (bytes32) {
        return keccak256(abi.encode(k.base, k.quote, k.oracleAdapter, k.strike, k.maturity, k.isCallPool));
    }

    /// @notice Returns the encoded strike key using the pool key `k`
    function strikeKey(IPoolFactory.PoolKey memory k) internal pure returns (bytes32) {
        return keccak256(abi.encode(k.base, k.quote, k.oracleAdapter, k.strike, k.isCallPool));
    }

    /// @notice Returns the encoded maturity key using the pool key `k`
    function maturityKey(IPoolFactory.PoolKey memory k) internal pure returns (bytes32) {
        return keccak256(abi.encode(k.base, k.quote, k.oracleAdapter, k.maturity, k.isCallPool));
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18, ud} from "@prb/math/UD60x18.sol";
import {SD59x18, sd} from "@prb/math/SD59x18.sol";

import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";
import {DoublyLinkedList} from "@solidstate/contracts/data/DoublyLinkedList.sol";
import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";

import {Position} from "../libraries/Position.sol";
import {OptionMath} from "../libraries/OptionMath.sol";
import {ZERO} from "../libraries/Constants.sol";
import {UD50x28} from "../libraries/UD50x28.sol";

import {IOracleAdapter} from "../adapter/IOracleAdapter.sol";

import {IERC20Router} from "../router/IERC20Router.sol";

import {IPoolInternal} from "./IPoolInternal.sol";

library PoolStorage {
    using SafeERC20 for IERC20;
    using PoolStorage for PoolStorage.Layout;

    // Token id for SHORT
    uint256 internal constant SHORT = 0;
    // Token id for LONG
    uint256 internal constant LONG = 1;

    // The version of LP token, used to know how to decode it, if upgrades are made
    uint8 internal constant TOKEN_VERSION = 1;

    UD60x18 internal constant MIN_TICK_DISTANCE = UD60x18.wrap(0.001e18); // 0.001
    UD60x18 internal constant MIN_TICK_PRICE = UD60x18.wrap(0.001e18); // 0.001
    UD60x18 internal constant MAX_TICK_PRICE = UD60x18.wrap(1e18); // 1

    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.storage.Pool");

    struct Layout {
        // ERC20 token addresses
        address base;
        address quote;
        address oracleAdapter;
        // token metadata
        uint8 baseDecimals;
        uint8 quoteDecimals;
        uint256 maturity;
        // Whether its a call or put pool
        bool isCallPool;
        // Index of all existing ticks sorted
        DoublyLinkedList.Bytes32List tickIndex;
        mapping(UD60x18 normalizedPrice => IPoolInternal.Tick) ticks;
        UD50x28 marketPrice;
        UD50x28 globalFeeRate;
        UD60x18 protocolFees;
        UD60x18 strike;
        UD50x28 liquidityRate;
        UD50x28 longRate;
        UD50x28 shortRate;
        // Current tick normalized price
        UD60x18 currentTick;
        // Settlement price of option
        UD60x18 settlementPrice;
        mapping(bytes32 key => Position.Data) positions;
        // Size of OB quotes already filled
        mapping(address provider => mapping(bytes32 hash => UD60x18 amountFilled)) quoteOBAmountFilled;
        // Set to true after maturity, to remove factory initialization discount
        bool initFeeDiscountRemoved;
        EnumerableSet.UintSet tokenIds;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @notice Returns the token decimals for the pool token
    function getPoolTokenDecimals(Layout storage l) internal view returns (uint8) {
        return l.isCallPool ? l.baseDecimals : l.quoteDecimals;
    }

    /// @notice Adjust decimals of a value with 18 decimals to match the pool token decimals
    function toPoolTokenDecimals(Layout storage l, uint256 value) internal view returns (uint256) {
        uint8 decimals = l.getPoolTokenDecimals();
        return OptionMath.scaleDecimals(value, 18, decimals);
    }

    /// @notice Adjust decimals of a value with 18 decimals to match the pool token decimals
    function toPoolTokenDecimals(Layout storage l, int256 value) internal view returns (int256) {
        uint8 decimals = l.getPoolTokenDecimals();
        return OptionMath.scaleDecimals(value, 18, decimals);
    }

    /// @notice Adjust decimals of a value with 18 decimals to match the pool token decimals
    function toPoolTokenDecimals(Layout storage l, UD60x18 value) internal view returns (uint256) {
        return l.toPoolTokenDecimals(value.unwrap());
    }

    /// @notice Adjust decimals of a value with 18 decimals to match the pool token decimals
    function toPoolTokenDecimals(Layout storage l, SD59x18 value) internal view returns (int256) {
        return l.toPoolTokenDecimals(value.unwrap());
    }

    /// @notice Adjust decimals of a value with pool token decimals to 18 decimals
    function fromPoolTokenDecimals(Layout storage l, uint256 value) internal view returns (UD60x18) {
        uint8 decimals = l.getPoolTokenDecimals();
        return ud(OptionMath.scaleDecimals(value, decimals, 18));
    }

    /// @notice Adjust decimals of a value with pool token decimals to 18 decimals
    function fromPoolTokenDecimals(Layout storage l, int256 value) internal view returns (SD59x18) {
        uint8 decimals = l.getPoolTokenDecimals();
        return sd(OptionMath.scaleDecimals(value, decimals, 18));
    }

    /// @notice Get the token used as options collateral and for payment of premium. (quote for PUT pools, base for CALL
    ///         pools)
    function getPoolToken(Layout storage l) internal view returns (address) {
        return l.isCallPool ? l.base : l.quote;
    }

    /// @notice calculate ERC1155 token id for given option parameters
    /// @param operator The current operator of the position
    /// @param lower The lower bound normalized option price (18 decimals)
    /// @param upper The upper bound normalized option price (18 decimals)
    /// @return tokenId token id
    function formatTokenId(
        address operator,
        UD60x18 lower,
        UD60x18 upper,
        Position.OrderType orderType
    ) internal pure returns (uint256 tokenId) {
        if (lower >= upper || lower < MIN_TICK_PRICE || upper > MAX_TICK_PRICE)
            revert IPoolInternal.Pool__InvalidRange(lower, upper);

        tokenId =
            (uint256(TOKEN_VERSION) << 252) +
            (uint256(orderType) << 180) +
            (uint256(uint160(operator)) << 20) +
            ((upper.unwrap() / MIN_TICK_DISTANCE.unwrap()) << 10) +
            (lower.unwrap() / MIN_TICK_DISTANCE.unwrap());
    }

    /// @notice derive option maturity and strike price from ERC1155 token id
    /// @param tokenId token id
    /// @return version The version of LP token, used to know how to decode it, if upgrades are made
    /// @return operator The current operator of the position
    /// @return lower The lower bound normalized option price (18 decimals)
    /// @return upper The upper bound normalized option price (18 decimals)
    function parseTokenId(
        uint256 tokenId
    )
        internal
        pure
        returns (uint8 version, address operator, UD60x18 lower, UD60x18 upper, Position.OrderType orderType)
    {
        uint256 minTickDistance = MIN_TICK_DISTANCE.unwrap();

        assembly {
            version := shr(252, tokenId)
            orderType := and(shr(180, tokenId), 0xF) // 4 bits mask
            operator := shr(20, tokenId)
            upper := mul(
                and(shr(10, tokenId), 0x3FF), // 10 bits mask
                minTickDistance
            )
            lower := mul(
                and(tokenId, 0x3FF), // 10 bits mask
                minTickDistance
            )
        }
    }

    /// @notice Converts `value` to pool token decimals and approves `spender`
    function approve(IERC20 token, address spender, UD60x18 value) internal {
        token.approve(spender, PoolStorage.layout().toPoolTokenDecimals(value));
    }

    /// @notice Converts `value` to pool token decimals and transfers `token`
    function safeTransferFrom(IERC20Router router, address token, address from, address to, UD60x18 value) internal {
        router.safeTransferFrom(token, from, to, PoolStorage.layout().toPoolTokenDecimals(value));
    }

    /// @notice Transfers token amount to recipient. Ignores if dust is missing on the exchange level,
    ///         i.e. if the pool balance is 0.01% less than the amount that should be sent, then the pool balance is
    ///         transferred instead of the amount. If the relative difference is larger than 0.01% then the transaction
    ///         will revert.
    /// @param token IERC20 token that is intended to be sent.
    /// @param to Recipient address of the tokens.
    /// @param value The amount of tokens that are intended to be sent (poolToken decimals).
    function safeTransferIgnoreDust(IERC20 token, address to, uint256 value) internal {
        PoolStorage.Layout storage l = PoolStorage.layout();
        uint256 balance = IERC20(l.getPoolToken()).balanceOf(address(this));

        if (value == 0) return;

        if (balance < value) {
            UD60x18 _balance = l.fromPoolTokenDecimals(balance);
            UD60x18 _value = l.fromPoolTokenDecimals(value);
            UD60x18 relativeDiff = (_value - _balance) / _value;

            // If relativeDiff is larger than the 0.01% tolerance, then revert
            if (relativeDiff > ud(0.0001 ether)) revert IPoolInternal.Pool__InsufficientFunds();

            value = balance;
        }

        token.safeTransfer(to, value);
    }

    /// @notice Transfers token amount to recipient. Ignores if dust is missing on the exchange level,
    ///         i.e. if the pool balance is 0.01% less than the amount that should be sent, then the pool balance is
    ///         transferred instead of the amount. If the relative difference is larger than 0.01% then the transaction
    ///         will revert.
    /// @param token IERC20 token that is intended to be sent.
    /// @param to Recipient address of the tokens.
    /// @param value The amount of tokens that are intended to be sent. (18 decimals)
    function safeTransferIgnoreDust(IERC20 token, address to, UD60x18 value) internal {
        PoolStorage.Layout storage l = PoolStorage.layout();
        safeTransferIgnoreDust(token, to, toPoolTokenDecimals(l, value));
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "@prb/math/UD60x18.sol";

interface IOracleAdapter {
    /// @notice The type of adapter
    enum AdapterType {
        None,
        Chainlink
    }

    /// @notice Thrown when attempting to increase array size
    error OracleAdapter__ArrayCannotExpand(uint256 arrayLength, uint256 size);

    /// @notice Thrown when the target is zero or before the current block timestamp
    error OracleAdapter__InvalidTarget(uint256 target, uint256 blockTimestamp);

    /// @notice Thrown when the price is non-positive
    error OracleAdapter__InvalidPrice(int256 price);

    /// @notice Thrown when trying to add support for a pair that cannot be supported
    error OracleAdapter__PairCannotBeSupported(address tokenA, address tokenB);

    /// @notice Thrown when trying to execute a quote with a pair that isn't supported
    error OracleAdapter__PairNotSupported(address tokenA, address tokenB);

    /// @notice Thrown when trying to add pair where addresses are the same
    error OracleAdapter__TokensAreSame(address tokenA, address tokenB);

    /// @notice Thrown when one of the parameters is a zero address
    error OracleAdapter__ZeroAddress();

    /// @notice Returns whether the pair has already been added to the adapter and if it supports the path required for
    ///         the pair
    ///         (true, true): Pair is fully supported
    ///         (false, true): Pair is not supported, but can be added
    ///         (false, false): Pair cannot be supported
    /// @dev tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
    /// @param tokenA One of the pair's tokens
    /// @param tokenB The other of the pair's tokens
    /// @return isCached True if the pair has been cached, false otherwise
    /// @return hasPath True if the pair has a valid path, false otherwise
    function isPairSupported(address tokenA, address tokenB) external view returns (bool isCached, bool hasPath);

    /// @notice Stores or updates the given token pair data provider configuration. This function will let the adapter
    ///         take some actions to configure the pair, in preparation for future quotes. Can be called many times in
    ///         order to let the adapter re-configure for a new context
    /// @param tokenA One of the pair's tokens
    /// @param tokenB The other of the pair's tokens
    function upsertPair(address tokenA, address tokenB) external;

    /// @notice Returns the most recent price for the given token pair
    /// @param tokenIn The exchange token (base token)
    /// @param tokenOut The token to quote against (quote token)
    /// @return The most recent price for the token pair (18 decimals)
    function getPrice(address tokenIn, address tokenOut) external view returns (UD60x18);

    /// @notice Returns the price closest to `target` for the given token pair
    /// @param tokenIn The exchange token (base token)
    /// @param tokenOut The token to quote against (quote token)
    /// @param target Reference timestamp of the quote
    /// @return Historical price for the token pair (18 decimals)
    function getPriceAt(address tokenIn, address tokenOut, uint256 target) external view returns (UD60x18);

    /// @notice Describes the pricing path used to convert the token to ETH
    /// @param token The token from where the pricing path starts
    /// @return adapterType The type of adapter
    /// @return path The path required to convert the token to ETH
    /// @return decimals The decimals of each token in the path
    function describePricingPath(
        address token
    ) external view returns (AdapterType adapterType, address[][] memory path, uint8[] memory decimals);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20MetadataInternal } from './IERC20MetadataInternal.sol';

/**
 * @title ERC20 metadata interface
 */
interface IERC20Metadata is IERC20MetadataInternal {
    /**
     * @notice return token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice return token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice return token decimals, generally used only for display purposes
     * @return token decimals
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    error UintUtils__InsufficientHexLength();

    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? sub(a, -b) : a + uint256(b);
    }

    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? add(a, -b) : a - uint256(b);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
        }

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        if (value != 0) revert UintUtils__InsufficientHexLength();

        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

// Common.sol
//
// Common mathematical functions needed by both SD59x18 and UD60x18. Note that these global functions do not
// always operate with SD59x18 and UD60x18 numbers.

/*//////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
//////////////////////////////////////////////////////////////////////////*/

/// @notice Thrown when the resultant value in {mulDiv} overflows uint256.
error PRBMath_MulDiv_Overflow(uint256 x, uint256 y, uint256 denominator);

/// @notice Thrown when the resultant value in {mulDiv18} overflows uint256.
error PRBMath_MulDiv18_Overflow(uint256 x, uint256 y);

/// @notice Thrown when one of the inputs passed to {mulDivSigned} is `type(int256).min`.
error PRBMath_MulDivSigned_InputTooSmall();

/// @notice Thrown when the resultant value in {mulDivSigned} overflows int256.
error PRBMath_MulDivSigned_Overflow(int256 x, int256 y);

/*//////////////////////////////////////////////////////////////////////////
                                    CONSTANTS
//////////////////////////////////////////////////////////////////////////*/

/// @dev The maximum value a uint128 number can have.
uint128 constant MAX_UINT128 = type(uint128).max;

/// @dev The maximum value a uint40 number can have.
uint40 constant MAX_UINT40 = type(uint40).max;

/// @dev The unit number, which the decimal precision of the fixed-point types.
uint256 constant UNIT = 1e18;

/// @dev The unit number inverted mod 2^256.
uint256 constant UNIT_INVERSE = 78156646155174841979727994598816262306175212592076161876661_508869554232690281;

/// @dev The the largest power of two that divides the decimal value of `UNIT`. The logarithm of this value is the least significant
/// bit in the binary representation of `UNIT`.
uint256 constant UNIT_LPOTD = 262144;

/*//////////////////////////////////////////////////////////////////////////
                                    FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

/// @notice Calculates the binary exponent of x using the binary fraction method.
/// @dev Has to use 192.64-bit fixed-point numbers. See https://ethereum.stackexchange.com/a/96594/24693.
/// @param x The exponent as an unsigned 192.64-bit fixed-point number.
/// @return result The result as an unsigned 60.18-decimal fixed-point number.
/// @custom:smtchecker abstract-function-nondet
function exp2(uint256 x) pure returns (uint256 result) {
    unchecked {
        // Start from 0.5 in the 192.64-bit fixed-point format.
        result = 0x800000000000000000000000000000000000000000000000;

        // The following logic multiplies the result by $\sqrt{2^{-i}}$ when the bit at position i is 1. Key points:
        //
        // 1. Intermediate results will not overflow, as the starting point is 2^191 and all magic factors are under 2^65.
        // 2. The rationale for organizing the if statements into groups of 8 is gas savings. If the result of performing
        // a bitwise AND operation between x and any value in the array [0x80; 0x40; 0x20; 0x10; 0x08; 0x04; 0x02; 0x01] is 1,
        // we know that `x & 0xFF` is also 1.
        if (x & 0xFF00000000000000 > 0) {
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
        }

        if (x & 0xFF000000000000 > 0) {
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
        }

        if (x & 0xFF0000000000 > 0) {
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
        }

        if (x & 0xFF00000000 > 0) {
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
        }

        if (x & 0xFF000000 > 0) {
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
        }

        if (x & 0xFF0000 > 0) {
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
        }

        if (x & 0xFF00 > 0) {
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
        }

        if (x & 0xFF > 0) {
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
        }

        // In the code snippet below, two operations are executed simultaneously:
        //
        // 1. The result is multiplied by $(2^n + 1)$, where $2^n$ represents the integer part, and the additional 1
        // accounts for the initial guess of 0.5. This is achieved by subtracting from 191 instead of 192.
        // 2. The result is then converted to an unsigned 60.18-decimal fixed-point format.
        //
        // The underlying logic is based on the relationship $2^{191-ip} = 2^{ip} / 2^{191}$, where $ip$ denotes the,
        // integer part, $2^n$.
        result *= UNIT;
        result >>= (191 - (x >> 64));
    }
}

/// @notice Finds the zero-based index of the first 1 in the binary representation of x.
///
/// @dev See the note on "msb" in this Wikipedia article: https://en.wikipedia.org/wiki/Find_first_set
///
/// Each step in this implementation is equivalent to this high-level code:
///
/// ```solidity
/// if (x >= 2 ** 128) {
///     x >>= 128;
///     result += 128;
/// }
/// ```
///
/// Where 128 is replaced with each respective power of two factor. See the full high-level implementation here:
/// https://gist.github.com/PaulRBerg/f932f8693f2733e30c4d479e8e980948
///
/// The Yul instructions used below are:
///
/// - "gt" is "greater than"
/// - "or" is the OR bitwise operator
/// - "shl" is "shift left"
/// - "shr" is "shift right"
///
/// @param x The uint256 number for which to find the index of the most significant bit.
/// @return result The index of the most significant bit as a uint256.
/// @custom:smtchecker abstract-function-nondet
function msb(uint256 x) pure returns (uint256 result) {
    // 2^128
    assembly ("memory-safe") {
        let factor := shl(7, gt(x, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^64
    assembly ("memory-safe") {
        let factor := shl(6, gt(x, 0xFFFFFFFFFFFFFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^32
    assembly ("memory-safe") {
        let factor := shl(5, gt(x, 0xFFFFFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^16
    assembly ("memory-safe") {
        let factor := shl(4, gt(x, 0xFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^8
    assembly ("memory-safe") {
        let factor := shl(3, gt(x, 0xFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^4
    assembly ("memory-safe") {
        let factor := shl(2, gt(x, 0xF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^2
    assembly ("memory-safe") {
        let factor := shl(1, gt(x, 0x3))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^1
    // No need to shift x any more.
    assembly ("memory-safe") {
        let factor := gt(x, 0x1)
        result := or(result, factor)
    }
}

/// @notice Calculates floor(x*y÷denominator) with 512-bit precision.
///
/// @dev Credits to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
///
/// Notes:
/// - The result is rounded down.
///
/// Requirements:
/// - The denominator must not be zero.
/// - The result must fit in uint256.
///
/// @param x The multiplicand as a uint256.
/// @param y The multiplier as a uint256.
/// @param denominator The divisor as a uint256.
/// @return result The result as a uint256.
/// @custom:smtchecker abstract-function-nondet
function mulDiv(uint256 x, uint256 y, uint256 denominator) pure returns (uint256 result) {
    // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
    // use the Chinese Remainder Theorem to reconstruct the 512-bit result. The result is stored in two 256
    // variables such that product = prod1 * 2^256 + prod0.
    uint256 prod0; // Least significant 256 bits of the product
    uint256 prod1; // Most significant 256 bits of the product
    assembly ("memory-safe") {
        let mm := mulmod(x, y, not(0))
        prod0 := mul(x, y)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    // Handle non-overflow cases, 256 by 256 division.
    if (prod1 == 0) {
        unchecked {
            return prod0 / denominator;
        }
    }

    // Make sure the result is less than 2^256. Also prevents denominator == 0.
    if (prod1 >= denominator) {
        revert PRBMath_MulDiv_Overflow(x, y, denominator);
    }

    ////////////////////////////////////////////////////////////////////////////
    // 512 by 256 division
    ////////////////////////////////////////////////////////////////////////////

    // Make division exact by subtracting the remainder from [prod1 prod0].
    uint256 remainder;
    assembly ("memory-safe") {
        // Compute remainder using the mulmod Yul instruction.
        remainder := mulmod(x, y, denominator)

        // Subtract 256 bit number from 512-bit number.
        prod1 := sub(prod1, gt(remainder, prod0))
        prod0 := sub(prod0, remainder)
    }

    unchecked {
        // Calculate the largest power of two divisor of the denominator using the unary operator ~. This operation cannot overflow
        // because the denominator cannot be zero at this point in the function execution. The result is always >= 1.
        // For more detail, see https://cs.stackexchange.com/q/138556/92363.
        uint256 lpotdod = denominator & (~denominator + 1);
        uint256 flippedLpotdod;

        assembly ("memory-safe") {
            // Factor powers of two out of denominator.
            denominator := div(denominator, lpotdod)

            // Divide [prod1 prod0] by lpotdod.
            prod0 := div(prod0, lpotdod)

            // Get the flipped value `2^256 / lpotdod`. If the `lpotdod` is zero, the flipped value is one.
            // `sub(0, lpotdod)` produces the two's complement version of `lpotdod`, which is equivalent to flipping all the bits.
            // However, `div` interprets this value as an unsigned value: https://ethereum.stackexchange.com/q/147168/24693
            flippedLpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
        }

        // Shift in bits from prod1 into prod0.
        prod0 |= prod1 * flippedLpotdod;

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
    }
}

/// @notice Calculates floor(x*y÷1e18) with 512-bit precision.
///
/// @dev A variant of {mulDiv} with constant folding, i.e. in which the denominator is hard coded to 1e18.
///
/// Notes:
/// - The body is purposely left uncommented; to understand how this works, see the documentation in {mulDiv}.
/// - The result is rounded down.
/// - We take as an axiom that the result cannot be `MAX_UINT256` when x and y solve the following system of equations:
///
/// $$
/// \begin{cases}
///     x * y = MAX\_UINT256 * UNIT \\
///     (x * y) \% UNIT \geq \frac{UNIT}{2}
/// \end{cases}
/// $$
///
/// Requirements:
/// - Refer to the requirements in {mulDiv}.
/// - The result must fit in uint256.
///
/// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
/// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
/// @return result The result as an unsigned 60.18-decimal fixed-point number.
/// @custom:smtchecker abstract-function-nondet
function mulDiv18(uint256 x, uint256 y) pure returns (uint256 result) {
    uint256 prod0;
    uint256 prod1;
    assembly ("memory-safe") {
        let mm := mulmod(x, y, not(0))
        prod0 := mul(x, y)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    if (prod1 == 0) {
        unchecked {
            return prod0 / UNIT;
        }
    }

    if (prod1 >= UNIT) {
        revert PRBMath_MulDiv18_Overflow(x, y);
    }

    uint256 remainder;
    assembly ("memory-safe") {
        remainder := mulmod(x, y, UNIT)
        result :=
            mul(
                or(
                    div(sub(prod0, remainder), UNIT_LPOTD),
                    mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, UNIT_LPOTD), UNIT_LPOTD), 1))
                ),
                UNIT_INVERSE
            )
    }
}

/// @notice Calculates floor(x*y÷denominator) with 512-bit precision.
///
/// @dev This is an extension of {mulDiv} for signed numbers, which works by computing the signs and the absolute values separately.
///
/// Notes:
/// - Unlike {mulDiv}, the result is rounded toward zero.
///
/// Requirements:
/// - Refer to the requirements in {mulDiv}.
/// - None of the inputs can be `type(int256).min`.
/// - The result must fit in int256.
///
/// @param x The multiplicand as an int256.
/// @param y The multiplier as an int256.
/// @param denominator The divisor as an int256.
/// @return result The result as an int256.
/// @custom:smtchecker abstract-function-nondet
function mulDivSigned(int256 x, int256 y, int256 denominator) pure returns (int256 result) {
    if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
        revert PRBMath_MulDivSigned_InputTooSmall();
    }

    // Get hold of the absolute values of x, y and the denominator.
    uint256 xAbs;
    uint256 yAbs;
    uint256 dAbs;
    unchecked {
        xAbs = x < 0 ? uint256(-x) : uint256(x);
        yAbs = y < 0 ? uint256(-y) : uint256(y);
        dAbs = denominator < 0 ? uint256(-denominator) : uint256(denominator);
    }

    // Compute the absolute value of x*y÷denominator. The result must fit in int256.
    uint256 resultAbs = mulDiv(xAbs, yAbs, dAbs);
    if (resultAbs > uint256(type(int256).max)) {
        revert PRBMath_MulDivSigned_Overflow(x, y);
    }

    // Get the signs of x, y and the denominator.
    uint256 sx;
    uint256 sy;
    uint256 sd;
    assembly ("memory-safe") {
        // This works thanks to two's complement.
        // "sgt" stands for "signed greater than" and "sub(0,1)" is max uint256.
        sx := sgt(x, sub(0, 1))
        sy := sgt(y, sub(0, 1))
        sd := sgt(denominator, sub(0, 1))
    }

    // XOR over sx, sy and sd. What this does is to check whether there are 1 or 3 negative signs in the inputs.
    // If there are, the result should be negative. Otherwise, it should be positive.
    unchecked {
        result = sx ^ sy ^ sd == 0 ? -int256(resultAbs) : int256(resultAbs);
    }
}

/// @notice Calculates the square root of x using the Babylonian method.
///
/// @dev See https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
///
/// Notes:
/// - If x is not a perfect square, the result is rounded down.
/// - Credits to OpenZeppelin for the explanations in comments below.
///
/// @param x The uint256 number for which to calculate the square root.
/// @return result The result as a uint256.
/// @custom:smtchecker abstract-function-nondet
function sqrt(uint256 x) pure returns (uint256 result) {
    if (x == 0) {
        return 0;
    }

    // For our first guess, we calculate the biggest power of 2 which is smaller than the square root of x.
    //
    // We know that the "msb" (most significant bit) of x is a power of 2 such that we have:
    //
    // $$
    // msb(x) <= x <= 2*msb(x)$
    // $$
    //
    // We write $msb(x)$ as $2^k$, and we get:
    //
    // $$
    // k = log_2(x)
    // $$
    //
    // Thus, we can write the initial inequality as:
    //
    // $$
    // 2^{log_2(x)} <= x <= 2*2^{log_2(x)+1} \\
    // sqrt(2^k) <= sqrt(x) < sqrt(2^{k+1}) \\
    // 2^{k/2} <= sqrt(x) < 2^{(k+1)/2} <= 2^{(k/2)+1}
    // $$
    //
    // Consequently, $2^{log_2(x) /2} is a good first approximation of sqrt(x) with at least one correct bit.
    uint256 xAux = uint256(x);
    result = 1;
    if (xAux >= 2 ** 128) {
        xAux >>= 128;
        result <<= 64;
    }
    if (xAux >= 2 ** 64) {
        xAux >>= 64;
        result <<= 32;
    }
    if (xAux >= 2 ** 32) {
        xAux >>= 32;
        result <<= 16;
    }
    if (xAux >= 2 ** 16) {
        xAux >>= 16;
        result <<= 8;
    }
    if (xAux >= 2 ** 8) {
        xAux >>= 8;
        result <<= 4;
    }
    if (xAux >= 2 ** 4) {
        xAux >>= 4;
        result <<= 2;
    }
    if (xAux >= 2 ** 2) {
        result <<= 1;
    }

    // At this point, `result` is an estimation with at least one bit of precision. We know the true value has at
    // most 128 bits, since  it is the square root of a uint256. Newton's method converges quadratically (precision
    // doubles at every iteration). We thus need at most 7 iteration to turn our partial result with one bit of
    // precision into the expected uint128 result.
    unchecked {
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;

        // If x is not a perfect square, round down the result.
        uint256 roundedDownResult = x / result;
        if (result >= roundedDownResult) {
            result = roundedDownResult;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { SD1x18 } from "./ValueType.sol";

/// @dev Euler's number as an SD1x18 number.
SD1x18 constant E = SD1x18.wrap(2_718281828459045235);

/// @dev The maximum value an SD1x18 number can have.
int64 constant uMAX_SD1x18 = 9_223372036854775807;
SD1x18 constant MAX_SD1x18 = SD1x18.wrap(uMAX_SD1x18);

/// @dev The maximum value an SD1x18 number can have.
int64 constant uMIN_SD1x18 = -9_223372036854775808;
SD1x18 constant MIN_SD1x18 = SD1x18.wrap(uMIN_SD1x18);

/// @dev PI as an SD1x18 number.
SD1x18 constant PI = SD1x18.wrap(3_141592653589793238);

/// @dev The unit number, which gives the decimal precision of SD1x18.
SD1x18 constant UNIT = SD1x18.wrap(1e18);
int256 constant uUNIT = 1e18;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./Casting.sol" as Casting;

/// @notice The signed 1.18-decimal fixed-point number representation, which can have up to 1 digit and up to 18
/// decimals. The values of this are bound by the minimum and the maximum values permitted by the underlying Solidity
/// type int64. This is useful when end users want to use int64 to save gas, e.g. with tight variable packing in contract
/// storage.
type SD1x18 is int64;

/*//////////////////////////////////////////////////////////////////////////
                                    CASTING
//////////////////////////////////////////////////////////////////////////*/

using {
    Casting.intoSD59x18,
    Casting.intoUD2x18,
    Casting.intoUD60x18,
    Casting.intoUint256,
    Casting.intoUint128,
    Casting.intoUint40,
    Casting.unwrap
} for SD1x18 global;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { SD59x18 } from "./ValueType.sol";

// NOTICE: the "u" prefix stands for "unwrapped".

/// @dev Euler's number as an SD59x18 number.
SD59x18 constant E = SD59x18.wrap(2_718281828459045235);

/// @dev The maximum input permitted in {exp}.
int256 constant uEXP_MAX_INPUT = 133_084258667509499440;
SD59x18 constant EXP_MAX_INPUT = SD59x18.wrap(uEXP_MAX_INPUT);

/// @dev The maximum input permitted in {exp2}.
int256 constant uEXP2_MAX_INPUT = 192e18 - 1;
SD59x18 constant EXP2_MAX_INPUT = SD59x18.wrap(uEXP2_MAX_INPUT);

/// @dev Half the UNIT number.
int256 constant uHALF_UNIT = 0.5e18;
SD59x18 constant HALF_UNIT = SD59x18.wrap(uHALF_UNIT);

/// @dev $log_2(10)$ as an SD59x18 number.
int256 constant uLOG2_10 = 3_321928094887362347;
SD59x18 constant LOG2_10 = SD59x18.wrap(uLOG2_10);

/// @dev $log_2(e)$ as an SD59x18 number.
int256 constant uLOG2_E = 1_442695040888963407;
SD59x18 constant LOG2_E = SD59x18.wrap(uLOG2_E);

/// @dev The maximum value an SD59x18 number can have.
int256 constant uMAX_SD59x18 = 57896044618658097711785492504343953926634992332820282019728_792003956564819967;
SD59x18 constant MAX_SD59x18 = SD59x18.wrap(uMAX_SD59x18);

/// @dev The maximum whole value an SD59x18 number can have.
int256 constant uMAX_WHOLE_SD59x18 = 57896044618658097711785492504343953926634992332820282019728_000000000000000000;
SD59x18 constant MAX_WHOLE_SD59x18 = SD59x18.wrap(uMAX_WHOLE_SD59x18);

/// @dev The minimum value an SD59x18 number can have.
int256 constant uMIN_SD59x18 = -57896044618658097711785492504343953926634992332820282019728_792003956564819968;
SD59x18 constant MIN_SD59x18 = SD59x18.wrap(uMIN_SD59x18);

/// @dev The minimum whole value an SD59x18 number can have.
int256 constant uMIN_WHOLE_SD59x18 = -57896044618658097711785492504343953926634992332820282019728_000000000000000000;
SD59x18 constant MIN_WHOLE_SD59x18 = SD59x18.wrap(uMIN_WHOLE_SD59x18);

/// @dev PI as an SD59x18 number.
SD59x18 constant PI = SD59x18.wrap(3_141592653589793238);

/// @dev The unit number, which gives the decimal precision of SD59x18.
int256 constant uUNIT = 1e18;
SD59x18 constant UNIT = SD59x18.wrap(1e18);

/// @dev The unit number squared.
int256 constant uUNIT_SQUARED = 1e36;
SD59x18 constant UNIT_SQUARED = SD59x18.wrap(uUNIT_SQUARED);

/// @dev Zero as an SD59x18 number.
SD59x18 constant ZERO = SD59x18.wrap(0);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./Casting.sol" as Casting;
import "./Helpers.sol" as Helpers;
import "./Math.sol" as Math;

/// @notice The signed 59.18-decimal fixed-point number representation, which can have up to 59 digits and up to 18
/// decimals. The values of this are bound by the minimum and the maximum values permitted by the underlying Solidity
/// type int256.
type SD59x18 is int256;

/*//////////////////////////////////////////////////////////////////////////
                                    CASTING
//////////////////////////////////////////////////////////////////////////*/

using {
    Casting.intoInt256,
    Casting.intoSD1x18,
    Casting.intoUD2x18,
    Casting.intoUD60x18,
    Casting.intoUint256,
    Casting.intoUint128,
    Casting.intoUint40,
    Casting.unwrap
} for SD59x18 global;

/*//////////////////////////////////////////////////////////////////////////
                            MATHEMATICAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {
    Math.abs,
    Math.avg,
    Math.ceil,
    Math.div,
    Math.exp,
    Math.exp2,
    Math.floor,
    Math.frac,
    Math.gm,
    Math.inv,
    Math.log10,
    Math.log2,
    Math.ln,
    Math.mul,
    Math.pow,
    Math.powu,
    Math.sqrt
} for SD59x18 global;

/*//////////////////////////////////////////////////////////////////////////
                                HELPER FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {
    Helpers.add,
    Helpers.and,
    Helpers.eq,
    Helpers.gt,
    Helpers.gte,
    Helpers.isZero,
    Helpers.lshift,
    Helpers.lt,
    Helpers.lte,
    Helpers.mod,
    Helpers.neq,
    Helpers.not,
    Helpers.or,
    Helpers.rshift,
    Helpers.sub,
    Helpers.uncheckedAdd,
    Helpers.uncheckedSub,
    Helpers.uncheckedUnary,
    Helpers.xor
} for SD59x18 global;

/*//////////////////////////////////////////////////////////////////////////
                                    OPERATORS
//////////////////////////////////////////////////////////////////////////*/

// The global "using for" directive makes it possible to use these operators on the SD59x18 type.
using {
    Helpers.add as +,
    Helpers.and2 as &,
    Math.div as /,
    Helpers.eq as ==,
    Helpers.gt as >,
    Helpers.gte as >=,
    Helpers.lt as <,
    Helpers.lte as <=,
    Helpers.mod as %,
    Math.mul as *,
    Helpers.neq as !=,
    Helpers.not as ~,
    Helpers.or as |,
    Helpers.sub as -,
    Helpers.unary as -,
    Helpers.xor as ^
} for SD59x18 global;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { UD2x18 } from "./ValueType.sol";

/// @dev Euler's number as a UD2x18 number.
UD2x18 constant E = UD2x18.wrap(2_718281828459045235);

/// @dev The maximum value a UD2x18 number can have.
uint64 constant uMAX_UD2x18 = 18_446744073709551615;
UD2x18 constant MAX_UD2x18 = UD2x18.wrap(uMAX_UD2x18);

/// @dev PI as a UD2x18 number.
UD2x18 constant PI = UD2x18.wrap(3_141592653589793238);

/// @dev The unit number, which gives the decimal precision of UD2x18.
uint256 constant uUNIT = 1e18;
UD2x18 constant UNIT = UD2x18.wrap(1e18);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./Casting.sol" as Casting;

/// @notice The unsigned 2.18-decimal fixed-point number representation, which can have up to 2 digits and up to 18
/// decimals. The values of this are bound by the minimum and the maximum values permitted by the underlying Solidity
/// type uint64. This is useful when end users want to use uint64 to save gas, e.g. with tight variable packing in contract
/// storage.
type UD2x18 is uint64;

/*//////////////////////////////////////////////////////////////////////////
                                    CASTING
//////////////////////////////////////////////////////////////////////////*/

using {
    Casting.intoSD1x18,
    Casting.intoSD59x18,
    Casting.intoUD60x18,
    Casting.intoUint256,
    Casting.intoUint128,
    Casting.intoUint40,
    Casting.unwrap
} for UD2x18 global;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./Errors.sol" as CastingErrors;
import { MAX_UINT128, MAX_UINT40 } from "../Common.sol";
import { uMAX_SD1x18, uMIN_SD1x18 } from "../sd1x18/Constants.sol";
import { SD1x18 } from "../sd1x18/ValueType.sol";
import { uMAX_UD2x18 } from "../ud2x18/Constants.sol";
import { UD2x18 } from "../ud2x18/ValueType.sol";
import { UD60x18 } from "../ud60x18/ValueType.sol";
import { SD59x18 } from "./ValueType.sol";

/// @notice Casts an SD59x18 number into int256.
/// @dev This is basically a functional alias for {unwrap}.
function intoInt256(SD59x18 x) pure returns (int256 result) {
    result = SD59x18.unwrap(x);
}

/// @notice Casts an SD59x18 number into SD1x18.
/// @dev Requirements:
/// - x must be greater than or equal to `uMIN_SD1x18`.
/// - x must be less than or equal to `uMAX_SD1x18`.
function intoSD1x18(SD59x18 x) pure returns (SD1x18 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < uMIN_SD1x18) {
        revert CastingErrors.PRBMath_SD59x18_IntoSD1x18_Underflow(x);
    }
    if (xInt > uMAX_SD1x18) {
        revert CastingErrors.PRBMath_SD59x18_IntoSD1x18_Overflow(x);
    }
    result = SD1x18.wrap(int64(xInt));
}

/// @notice Casts an SD59x18 number into UD2x18.
/// @dev Requirements:
/// - x must be positive.
/// - x must be less than or equal to `uMAX_UD2x18`.
function intoUD2x18(SD59x18 x) pure returns (UD2x18 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD59x18_IntoUD2x18_Underflow(x);
    }
    if (xInt > int256(uint256(uMAX_UD2x18))) {
        revert CastingErrors.PRBMath_SD59x18_IntoUD2x18_Overflow(x);
    }
    result = UD2x18.wrap(uint64(uint256(xInt)));
}

/// @notice Casts an SD59x18 number into UD60x18.
/// @dev Requirements:
/// - x must be positive.
function intoUD60x18(SD59x18 x) pure returns (UD60x18 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD59x18_IntoUD60x18_Underflow(x);
    }
    result = UD60x18.wrap(uint256(xInt));
}

/// @notice Casts an SD59x18 number into uint256.
/// @dev Requirements:
/// - x must be positive.
function intoUint256(SD59x18 x) pure returns (uint256 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD59x18_IntoUint256_Underflow(x);
    }
    result = uint256(xInt);
}

/// @notice Casts an SD59x18 number into uint128.
/// @dev Requirements:
/// - x must be positive.
/// - x must be less than or equal to `uMAX_UINT128`.
function intoUint128(SD59x18 x) pure returns (uint128 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD59x18_IntoUint128_Underflow(x);
    }
    if (xInt > int256(uint256(MAX_UINT128))) {
        revert CastingErrors.PRBMath_SD59x18_IntoUint128_Overflow(x);
    }
    result = uint128(uint256(xInt));
}

/// @notice Casts an SD59x18 number into uint40.
/// @dev Requirements:
/// - x must be positive.
/// - x must be less than or equal to `MAX_UINT40`.
function intoUint40(SD59x18 x) pure returns (uint40 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD59x18_IntoUint40_Underflow(x);
    }
    if (xInt > int256(uint256(MAX_UINT40))) {
        revert CastingErrors.PRBMath_SD59x18_IntoUint40_Overflow(x);
    }
    result = uint40(uint256(xInt));
}

/// @notice Alias for {wrap}.
function sd(int256 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(x);
}

/// @notice Alias for {wrap}.
function sd59x18(int256 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(x);
}

/// @notice Unwraps an SD59x18 number into int256.
function unwrap(SD59x18 x) pure returns (int256 result) {
    result = SD59x18.unwrap(x);
}

/// @notice Wraps an int256 number into SD59x18.
function wrap(int256 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(x);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { uMAX_SD59x18, uMIN_SD59x18, uUNIT } from "./Constants.sol";
import { PRBMath_SD59x18_Convert_Overflow, PRBMath_SD59x18_Convert_Underflow } from "./Errors.sol";
import { SD59x18 } from "./ValueType.sol";

/// @notice Converts a simple integer to SD59x18 by multiplying it by `UNIT`.
///
/// @dev Requirements:
/// - x must be greater than or equal to `MIN_SD59x18 / UNIT`.
/// - x must be less than or equal to `MAX_SD59x18 / UNIT`.
///
/// @param x The basic integer to convert.
/// @param result The same number converted to SD59x18.
function convert(int256 x) pure returns (SD59x18 result) {
    if (x < uMIN_SD59x18 / uUNIT) {
        revert PRBMath_SD59x18_Convert_Underflow(x);
    }
    if (x > uMAX_SD59x18 / uUNIT) {
        revert PRBMath_SD59x18_Convert_Overflow(x);
    }
    unchecked {
        result = SD59x18.wrap(x * uUNIT);
    }
}

/// @notice Converts an SD59x18 number to a simple integer by dividing it by `UNIT`.
/// @dev The result is rounded toward zero.
/// @param x The SD59x18 number to convert.
/// @return result The same number as a simple integer.
function convert(SD59x18 x) pure returns (int256 result) {
    result = SD59x18.unwrap(x) / uUNIT;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { SD59x18 } from "./ValueType.sol";

/// @notice Thrown when taking the absolute value of `MIN_SD59x18`.
error PRBMath_SD59x18_Abs_MinSD59x18();

/// @notice Thrown when ceiling a number overflows SD59x18.
error PRBMath_SD59x18_Ceil_Overflow(SD59x18 x);

/// @notice Thrown when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMath_SD59x18_Convert_Overflow(int256 x);

/// @notice Thrown when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMath_SD59x18_Convert_Underflow(int256 x);

/// @notice Thrown when dividing two numbers and one of them is `MIN_SD59x18`.
error PRBMath_SD59x18_Div_InputTooSmall();

/// @notice Thrown when dividing two numbers and one of the intermediary unsigned results overflows SD59x18.
error PRBMath_SD59x18_Div_Overflow(SD59x18 x, SD59x18 y);

/// @notice Thrown when taking the natural exponent of a base greater than 133_084258667509499441.
error PRBMath_SD59x18_Exp_InputTooBig(SD59x18 x);

/// @notice Thrown when taking the binary exponent of a base greater than 192e18.
error PRBMath_SD59x18_Exp2_InputTooBig(SD59x18 x);

/// @notice Thrown when flooring a number underflows SD59x18.
error PRBMath_SD59x18_Floor_Underflow(SD59x18 x);

/// @notice Thrown when taking the geometric mean of two numbers and their product is negative.
error PRBMath_SD59x18_Gm_NegativeProduct(SD59x18 x, SD59x18 y);

/// @notice Thrown when taking the geometric mean of two numbers and multiplying them overflows SD59x18.
error PRBMath_SD59x18_Gm_Overflow(SD59x18 x, SD59x18 y);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in SD1x18.
error PRBMath_SD59x18_IntoSD1x18_Overflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in SD1x18.
error PRBMath_SD59x18_IntoSD1x18_Underflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in UD2x18.
error PRBMath_SD59x18_IntoUD2x18_Overflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in UD2x18.
error PRBMath_SD59x18_IntoUD2x18_Underflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in UD60x18.
error PRBMath_SD59x18_IntoUD60x18_Underflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint128.
error PRBMath_SD59x18_IntoUint128_Overflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint128.
error PRBMath_SD59x18_IntoUint128_Underflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint256.
error PRBMath_SD59x18_IntoUint256_Underflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint40.
error PRBMath_SD59x18_IntoUint40_Overflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint40.
error PRBMath_SD59x18_IntoUint40_Underflow(SD59x18 x);

/// @notice Thrown when taking the logarithm of a number less than or equal to zero.
error PRBMath_SD59x18_Log_InputTooSmall(SD59x18 x);

/// @notice Thrown when multiplying two numbers and one of the inputs is `MIN_SD59x18`.
error PRBMath_SD59x18_Mul_InputTooSmall();

/// @notice Thrown when multiplying two numbers and the intermediary absolute result overflows SD59x18.
error PRBMath_SD59x18_Mul_Overflow(SD59x18 x, SD59x18 y);

/// @notice Thrown when raising a number to a power and hte intermediary absolute result overflows SD59x18.
error PRBMath_SD59x18_Powu_Overflow(SD59x18 x, uint256 y);

/// @notice Thrown when taking the square root of a negative number.
error PRBMath_SD59x18_Sqrt_NegativeInput(SD59x18 x);

/// @notice Thrown when the calculating the square root overflows SD59x18.
error PRBMath_SD59x18_Sqrt_Overflow(SD59x18 x);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { wrap } from "./Casting.sol";
import { SD59x18 } from "./ValueType.sol";

/// @notice Implements the checked addition operation (+) in the SD59x18 type.
function add(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    return wrap(x.unwrap() + y.unwrap());
}

/// @notice Implements the AND (&) bitwise operation in the SD59x18 type.
function and(SD59x18 x, int256 bits) pure returns (SD59x18 result) {
    return wrap(x.unwrap() & bits);
}

/// @notice Implements the AND (&) bitwise operation in the SD59x18 type.
function and2(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    return wrap(x.unwrap() & y.unwrap());
}

/// @notice Implements the equal (=) operation in the SD59x18 type.
function eq(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = x.unwrap() == y.unwrap();
}

/// @notice Implements the greater than operation (>) in the SD59x18 type.
function gt(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = x.unwrap() > y.unwrap();
}

/// @notice Implements the greater than or equal to operation (>=) in the SD59x18 type.
function gte(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = x.unwrap() >= y.unwrap();
}

/// @notice Implements a zero comparison check function in the SD59x18 type.
function isZero(SD59x18 x) pure returns (bool result) {
    result = x.unwrap() == 0;
}

/// @notice Implements the left shift operation (<<) in the SD59x18 type.
function lshift(SD59x18 x, uint256 bits) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() << bits);
}

/// @notice Implements the lower than operation (<) in the SD59x18 type.
function lt(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = x.unwrap() < y.unwrap();
}

/// @notice Implements the lower than or equal to operation (<=) in the SD59x18 type.
function lte(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = x.unwrap() <= y.unwrap();
}

/// @notice Implements the unchecked modulo operation (%) in the SD59x18 type.
function mod(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() % y.unwrap());
}

/// @notice Implements the not equal operation (!=) in the SD59x18 type.
function neq(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = x.unwrap() != y.unwrap();
}

/// @notice Implements the NOT (~) bitwise operation in the SD59x18 type.
function not(SD59x18 x) pure returns (SD59x18 result) {
    result = wrap(~x.unwrap());
}

/// @notice Implements the OR (|) bitwise operation in the SD59x18 type.
function or(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() | y.unwrap());
}

/// @notice Implements the right shift operation (>>) in the SD59x18 type.
function rshift(SD59x18 x, uint256 bits) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() >> bits);
}

/// @notice Implements the checked subtraction operation (-) in the SD59x18 type.
function sub(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() - y.unwrap());
}

/// @notice Implements the checked unary minus operation (-) in the SD59x18 type.
function unary(SD59x18 x) pure returns (SD59x18 result) {
    result = wrap(-x.unwrap());
}

/// @notice Implements the unchecked addition operation (+) in the SD59x18 type.
function uncheckedAdd(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    unchecked {
        result = wrap(x.unwrap() + y.unwrap());
    }
}

/// @notice Implements the unchecked subtraction operation (-) in the SD59x18 type.
function uncheckedSub(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    unchecked {
        result = wrap(x.unwrap() - y.unwrap());
    }
}

/// @notice Implements the unchecked unary minus operation (-) in the SD59x18 type.
function uncheckedUnary(SD59x18 x) pure returns (SD59x18 result) {
    unchecked {
        result = wrap(-x.unwrap());
    }
}

/// @notice Implements the XOR (^) bitwise operation in the SD59x18 type.
function xor(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() ^ y.unwrap());
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "../Common.sol" as Common;
import "./Errors.sol" as Errors;
import {
    uEXP_MAX_INPUT,
    uEXP2_MAX_INPUT,
    uHALF_UNIT,
    uLOG2_10,
    uLOG2_E,
    uMAX_SD59x18,
    uMAX_WHOLE_SD59x18,
    uMIN_SD59x18,
    uMIN_WHOLE_SD59x18,
    UNIT,
    uUNIT,
    uUNIT_SQUARED,
    ZERO
} from "./Constants.sol";
import { wrap } from "./Helpers.sol";
import { SD59x18 } from "./ValueType.sol";

/// @notice Calculates the absolute value of x.
///
/// @dev Requirements:
/// - x must be greater than `MIN_SD59x18`.
///
/// @param x The SD59x18 number for which to calculate the absolute value.
/// @param result The absolute value of x as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function abs(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt == uMIN_SD59x18) {
        revert Errors.PRBMath_SD59x18_Abs_MinSD59x18();
    }
    result = xInt < 0 ? wrap(-xInt) : x;
}

/// @notice Calculates the arithmetic average of x and y.
///
/// @dev Notes:
/// - The result is rounded toward zero.
///
/// @param x The first operand as an SD59x18 number.
/// @param y The second operand as an SD59x18 number.
/// @return result The arithmetic average as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function avg(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    int256 yInt = y.unwrap();

    unchecked {
        // This operation is equivalent to `x / 2 +  y / 2`, and it can never overflow.
        int256 sum = (xInt >> 1) + (yInt >> 1);

        if (sum < 0) {
            // If at least one of x and y is odd, add 1 to the result, because shifting negative numbers to the right
            // rounds down to infinity. The right part is equivalent to `sum + (x % 2 == 1 || y % 2 == 1)`.
            assembly ("memory-safe") {
                result := add(sum, and(or(xInt, yInt), 1))
            }
        } else {
            // Add 1 if both x and y are odd to account for the double 0.5 remainder truncated after shifting.
            result = wrap(sum + (xInt & yInt & 1));
        }
    }
}

/// @notice Yields the smallest whole number greater than or equal to x.
///
/// @dev Optimized for fractional value inputs, because every whole value has (1e18 - 1) fractional counterparts.
/// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
///
/// Requirements:
/// - x must be less than or equal to `MAX_WHOLE_SD59x18`.
///
/// @param x The SD59x18 number to ceil.
/// @param result The smallest whole number greater than or equal to x, as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function ceil(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt > uMAX_WHOLE_SD59x18) {
        revert Errors.PRBMath_SD59x18_Ceil_Overflow(x);
    }

    int256 remainder = xInt % uUNIT;
    if (remainder == 0) {
        result = x;
    } else {
        unchecked {
            // Solidity uses C fmod style, which returns a modulus with the same sign as x.
            int256 resultInt = xInt - remainder;
            if (xInt > 0) {
                resultInt += uUNIT;
            }
            result = wrap(resultInt);
        }
    }
}

/// @notice Divides two SD59x18 numbers, returning a new SD59x18 number.
///
/// @dev This is an extension of {Common.mulDiv} for signed numbers, which works by computing the signs and the absolute
/// values separately.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv}.
/// - The result is rounded toward zero.
///
/// Requirements:
/// - Refer to the requirements in {Common.mulDiv}.
/// - None of the inputs can be `MIN_SD59x18`.
/// - The denominator must not be zero.
/// - The result must fit in SD59x18.
///
/// @param x The numerator as an SD59x18 number.
/// @param y The denominator as an SD59x18 number.
/// @param result The quotient as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function div(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    int256 yInt = y.unwrap();
    if (xInt == uMIN_SD59x18 || yInt == uMIN_SD59x18) {
        revert Errors.PRBMath_SD59x18_Div_InputTooSmall();
    }

    // Get hold of the absolute values of x and y.
    uint256 xAbs;
    uint256 yAbs;
    unchecked {
        xAbs = xInt < 0 ? uint256(-xInt) : uint256(xInt);
        yAbs = yInt < 0 ? uint256(-yInt) : uint256(yInt);
    }

    // Compute the absolute value (x*UNIT÷y). The resulting value must fit in SD59x18.
    uint256 resultAbs = Common.mulDiv(xAbs, uint256(uUNIT), yAbs);
    if (resultAbs > uint256(uMAX_SD59x18)) {
        revert Errors.PRBMath_SD59x18_Div_Overflow(x, y);
    }

    // Check if x and y have the same sign using two's complement representation. The left-most bit represents the sign (1 for
    // negative, 0 for positive or zero).
    bool sameSign = (xInt ^ yInt) > -1;

    // If the inputs have the same sign, the result should be positive. Otherwise, it should be negative.
    unchecked {
        result = wrap(sameSign ? int256(resultAbs) : -int256(resultAbs));
    }
}

/// @notice Calculates the natural exponent of x using the following formula:
///
/// $$
/// e^x = 2^{x * log_2{e}}
/// $$
///
/// @dev Notes:
/// - Refer to the notes in {exp2}.
///
/// Requirements:
/// - Refer to the requirements in {exp2}.
/// - x must be less than 133_084258667509499441.
///
/// @param x The exponent as an SD59x18 number.
/// @return result The result as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function exp(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();

    // This check prevents values greater than 192 from being passed to {exp2}.
    if (xInt > uEXP_MAX_INPUT) {
        revert Errors.PRBMath_SD59x18_Exp_InputTooBig(x);
    }

    unchecked {
        // Inline the fixed-point multiplication to save gas.
        int256 doubleUnitProduct = xInt * uLOG2_E;
        result = exp2(wrap(doubleUnitProduct / uUNIT));
    }
}

/// @notice Calculates the binary exponent of x using the binary fraction method using the following formula:
///
/// $$
/// 2^{-x} = \frac{1}{2^x}
/// $$
///
/// @dev See https://ethereum.stackexchange.com/q/79903/24693.
///
/// Notes:
/// - If x is less than -59_794705707972522261, the result is zero.
///
/// Requirements:
/// - x must be less than 192e18.
/// - The result must fit in SD59x18.
///
/// @param x The exponent as an SD59x18 number.
/// @return result The result as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function exp2(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt < 0) {
        // The inverse of any number less than this is truncated to zero.
        if (xInt < -59_794705707972522261) {
            return ZERO;
        }

        unchecked {
            // Inline the fixed-point inversion to save gas.
            result = wrap(uUNIT_SQUARED / exp2(wrap(-xInt)).unwrap());
        }
    } else {
        // Numbers greater than or equal to 192e18 don't fit in the 192.64-bit format.
        if (xInt > uEXP2_MAX_INPUT) {
            revert Errors.PRBMath_SD59x18_Exp2_InputTooBig(x);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x_192x64 = uint256((xInt << 64) / uUNIT);

            // It is safe to cast the result to int256 due to the checks above.
            result = wrap(int256(Common.exp2(x_192x64)));
        }
    }
}

/// @notice Yields the greatest whole number less than or equal to x.
///
/// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional
/// counterparts. See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
///
/// Requirements:
/// - x must be greater than or equal to `MIN_WHOLE_SD59x18`.
///
/// @param x The SD59x18 number to floor.
/// @param result The greatest whole number less than or equal to x, as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function floor(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt < uMIN_WHOLE_SD59x18) {
        revert Errors.PRBMath_SD59x18_Floor_Underflow(x);
    }

    int256 remainder = xInt % uUNIT;
    if (remainder == 0) {
        result = x;
    } else {
        unchecked {
            // Solidity uses C fmod style, which returns a modulus with the same sign as x.
            int256 resultInt = xInt - remainder;
            if (xInt < 0) {
                resultInt -= uUNIT;
            }
            result = wrap(resultInt);
        }
    }
}

/// @notice Yields the excess beyond the floor of x for positive numbers and the part of the number to the right.
/// of the radix point for negative numbers.
/// @dev Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part
/// @param x The SD59x18 number to get the fractional part of.
/// @param result The fractional part of x as an SD59x18 number.
function frac(SD59x18 x) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() % uUNIT);
}

/// @notice Calculates the geometric mean of x and y, i.e. $\sqrt{x * y}$.
///
/// @dev Notes:
/// - The result is rounded toward zero.
///
/// Requirements:
/// - x * y must fit in SD59x18.
/// - x * y must not be negative, since complex numbers are not supported.
///
/// @param x The first operand as an SD59x18 number.
/// @param y The second operand as an SD59x18 number.
/// @return result The result as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function gm(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    int256 yInt = y.unwrap();
    if (xInt == 0 || yInt == 0) {
        return ZERO;
    }

    unchecked {
        // Equivalent to `xy / x != y`. Checking for overflow this way is faster than letting Solidity do it.
        int256 xyInt = xInt * yInt;
        if (xyInt / xInt != yInt) {
            revert Errors.PRBMath_SD59x18_Gm_Overflow(x, y);
        }

        // The product must not be negative, since complex numbers are not supported.
        if (xyInt < 0) {
            revert Errors.PRBMath_SD59x18_Gm_NegativeProduct(x, y);
        }

        // We don't need to multiply the result by `UNIT` here because the x*y product picked up a factor of `UNIT`
        // during multiplication. See the comments in {Common.sqrt}.
        uint256 resultUint = Common.sqrt(uint256(xyInt));
        result = wrap(int256(resultUint));
    }
}

/// @notice Calculates the inverse of x.
///
/// @dev Notes:
/// - The result is rounded toward zero.
///
/// Requirements:
/// - x must not be zero.
///
/// @param x The SD59x18 number for which to calculate the inverse.
/// @return result The inverse as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function inv(SD59x18 x) pure returns (SD59x18 result) {
    result = wrap(uUNIT_SQUARED / x.unwrap());
}

/// @notice Calculates the natural logarithm of x using the following formula:
///
/// $$
/// ln{x} = log_2{x} / log_2{e}
/// $$
///
/// @dev Notes:
/// - Refer to the notes in {log2}.
/// - The precision isn't sufficiently fine-grained to return exactly `UNIT` when the input is `E`.
///
/// Requirements:
/// - Refer to the requirements in {log2}.
///
/// @param x The SD59x18 number for which to calculate the natural logarithm.
/// @return result The natural logarithm as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function ln(SD59x18 x) pure returns (SD59x18 result) {
    // Inline the fixed-point multiplication to save gas. This is overflow-safe because the maximum value that
    // {log2} can return is ~195_205294292027477728.
    result = wrap(log2(x).unwrap() * uUNIT / uLOG2_E);
}

/// @notice Calculates the common logarithm of x using the following formula:
///
/// $$
/// log_{10}{x} = log_2{x} / log_2{10}
/// $$
///
/// However, if x is an exact power of ten, a hard coded value is returned.
///
/// @dev Notes:
/// - Refer to the notes in {log2}.
///
/// Requirements:
/// - Refer to the requirements in {log2}.
///
/// @param x The SD59x18 number for which to calculate the common logarithm.
/// @return result The common logarithm as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function log10(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt < 0) {
        revert Errors.PRBMath_SD59x18_Log_InputTooSmall(x);
    }

    // Note that the `mul` in this block is the standard multiplication operation, not {SD59x18.mul}.
    // prettier-ignore
    assembly ("memory-safe") {
        switch x
        case 1 { result := mul(uUNIT, sub(0, 18)) }
        case 10 { result := mul(uUNIT, sub(1, 18)) }
        case 100 { result := mul(uUNIT, sub(2, 18)) }
        case 1000 { result := mul(uUNIT, sub(3, 18)) }
        case 10000 { result := mul(uUNIT, sub(4, 18)) }
        case 100000 { result := mul(uUNIT, sub(5, 18)) }
        case 1000000 { result := mul(uUNIT, sub(6, 18)) }
        case 10000000 { result := mul(uUNIT, sub(7, 18)) }
        case 100000000 { result := mul(uUNIT, sub(8, 18)) }
        case 1000000000 { result := mul(uUNIT, sub(9, 18)) }
        case 10000000000 { result := mul(uUNIT, sub(10, 18)) }
        case 100000000000 { result := mul(uUNIT, sub(11, 18)) }
        case 1000000000000 { result := mul(uUNIT, sub(12, 18)) }
        case 10000000000000 { result := mul(uUNIT, sub(13, 18)) }
        case 100000000000000 { result := mul(uUNIT, sub(14, 18)) }
        case 1000000000000000 { result := mul(uUNIT, sub(15, 18)) }
        case 10000000000000000 { result := mul(uUNIT, sub(16, 18)) }
        case 100000000000000000 { result := mul(uUNIT, sub(17, 18)) }
        case 1000000000000000000 { result := 0 }
        case 10000000000000000000 { result := uUNIT }
        case 100000000000000000000 { result := mul(uUNIT, 2) }
        case 1000000000000000000000 { result := mul(uUNIT, 3) }
        case 10000000000000000000000 { result := mul(uUNIT, 4) }
        case 100000000000000000000000 { result := mul(uUNIT, 5) }
        case 1000000000000000000000000 { result := mul(uUNIT, 6) }
        case 10000000000000000000000000 { result := mul(uUNIT, 7) }
        case 100000000000000000000000000 { result := mul(uUNIT, 8) }
        case 1000000000000000000000000000 { result := mul(uUNIT, 9) }
        case 10000000000000000000000000000 { result := mul(uUNIT, 10) }
        case 100000000000000000000000000000 { result := mul(uUNIT, 11) }
        case 1000000000000000000000000000000 { result := mul(uUNIT, 12) }
        case 10000000000000000000000000000000 { result := mul(uUNIT, 13) }
        case 100000000000000000000000000000000 { result := mul(uUNIT, 14) }
        case 1000000000000000000000000000000000 { result := mul(uUNIT, 15) }
        case 10000000000000000000000000000000000 { result := mul(uUNIT, 16) }
        case 100000000000000000000000000000000000 { result := mul(uUNIT, 17) }
        case 1000000000000000000000000000000000000 { result := mul(uUNIT, 18) }
        case 10000000000000000000000000000000000000 { result := mul(uUNIT, 19) }
        case 100000000000000000000000000000000000000 { result := mul(uUNIT, 20) }
        case 1000000000000000000000000000000000000000 { result := mul(uUNIT, 21) }
        case 10000000000000000000000000000000000000000 { result := mul(uUNIT, 22) }
        case 100000000000000000000000000000000000000000 { result := mul(uUNIT, 23) }
        case 1000000000000000000000000000000000000000000 { result := mul(uUNIT, 24) }
        case 10000000000000000000000000000000000000000000 { result := mul(uUNIT, 25) }
        case 100000000000000000000000000000000000000000000 { result := mul(uUNIT, 26) }
        case 1000000000000000000000000000000000000000000000 { result := mul(uUNIT, 27) }
        case 10000000000000000000000000000000000000000000000 { result := mul(uUNIT, 28) }
        case 100000000000000000000000000000000000000000000000 { result := mul(uUNIT, 29) }
        case 1000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 30) }
        case 10000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 31) }
        case 100000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 32) }
        case 1000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 33) }
        case 10000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 34) }
        case 100000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 35) }
        case 1000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 36) }
        case 10000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 37) }
        case 100000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 38) }
        case 1000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 39) }
        case 10000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 40) }
        case 100000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 41) }
        case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 42) }
        case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 43) }
        case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 44) }
        case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 45) }
        case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 46) }
        case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 47) }
        case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 48) }
        case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 49) }
        case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 50) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 51) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 52) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 53) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 54) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 55) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 56) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 57) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 58) }
        default { result := uMAX_SD59x18 }
    }

    if (result.unwrap() == uMAX_SD59x18) {
        unchecked {
            // Inline the fixed-point division to save gas.
            result = wrap(log2(x).unwrap() * uUNIT / uLOG2_10);
        }
    }
}

/// @notice Calculates the binary logarithm of x using the iterative approximation algorithm.
///
/// For $0 \leq x \lt 1$, the logarithm is calculated as:
///
/// $$
/// log_2{x} = -log_2{\frac{1}{x}}
/// $$
///
/// @dev See https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation.
///
/// Notes:
/// - Due to the lossy precision of the iterative approximation, the results are not perfectly accurate to the last decimal.
///
/// Requirements:
/// - x must be greater than zero.
///
/// @param x The SD59x18 number for which to calculate the binary logarithm.
/// @return result The binary logarithm as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function log2(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt <= 0) {
        revert Errors.PRBMath_SD59x18_Log_InputTooSmall(x);
    }

    unchecked {
        int256 sign;
        if (xInt >= uUNIT) {
            sign = 1;
        } else {
            sign = -1;
            // Inline the fixed-point inversion to save gas.
            xInt = uUNIT_SQUARED / xInt;
        }

        // Calculate the integer part of the logarithm and add it to the result and finally calculate $y = x * 2^{-n}$.
        uint256 n = Common.msb(uint256(xInt / uUNIT));

        // This is the integer part of the logarithm as an SD59x18 number. The operation can't overflow
        // because n is at most 255, `UNIT` is 1e18, and the sign is either 1 or -1.
        int256 resultInt = int256(n) * uUNIT;

        // This is $y = x * 2^{-n}$.
        int256 y = xInt >> n;

        // If y is the unit number, the fractional part is zero.
        if (y == uUNIT) {
            return wrap(resultInt * sign);
        }

        // Calculate the fractional part via the iterative approximation.
        // The `delta >>= 1` part is equivalent to `delta /= 2`, but shifting bits is more gas efficient.
        int256 DOUBLE_UNIT = 2e18;
        for (int256 delta = uHALF_UNIT; delta > 0; delta >>= 1) {
            y = (y * y) / uUNIT;

            // Is y^2 >= 2e18 and so in the range [2e18, 4e18)?
            if (y >= DOUBLE_UNIT) {
                // Add the 2^{-m} factor to the logarithm.
                resultInt = resultInt + delta;

                // Corresponds to z/2 in the Wikipedia article.
                y >>= 1;
            }
        }
        resultInt *= sign;
        result = wrap(resultInt);
    }
}

/// @notice Multiplies two SD59x18 numbers together, returning a new SD59x18 number.
///
/// @dev Notes:
/// - Refer to the notes in {Common.mulDiv18}.
///
/// Requirements:
/// - Refer to the requirements in {Common.mulDiv18}.
/// - None of the inputs can be `MIN_SD59x18`.
/// - The result must fit in SD59x18.
///
/// @param x The multiplicand as an SD59x18 number.
/// @param y The multiplier as an SD59x18 number.
/// @return result The product as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function mul(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    int256 yInt = y.unwrap();
    if (xInt == uMIN_SD59x18 || yInt == uMIN_SD59x18) {
        revert Errors.PRBMath_SD59x18_Mul_InputTooSmall();
    }

    // Get hold of the absolute values of x and y.
    uint256 xAbs;
    uint256 yAbs;
    unchecked {
        xAbs = xInt < 0 ? uint256(-xInt) : uint256(xInt);
        yAbs = yInt < 0 ? uint256(-yInt) : uint256(yInt);
    }

    // Compute the absolute value (x*y÷UNIT). The resulting value must fit in SD59x18.
    uint256 resultAbs = Common.mulDiv18(xAbs, yAbs);
    if (resultAbs > uint256(uMAX_SD59x18)) {
        revert Errors.PRBMath_SD59x18_Mul_Overflow(x, y);
    }

    // Check if x and y have the same sign using two's complement representation. The left-most bit represents the sign (1 for
    // negative, 0 for positive or zero).
    bool sameSign = (xInt ^ yInt) > -1;

    // If the inputs have the same sign, the result should be positive. Otherwise, it should be negative.
    unchecked {
        result = wrap(sameSign ? int256(resultAbs) : -int256(resultAbs));
    }
}

/// @notice Raises x to the power of y using the following formula:
///
/// $$
/// x^y = 2^{log_2{x} * y}
/// $$
///
/// @dev Notes:
/// - Refer to the notes in {exp2}, {log2}, and {mul}.
/// - Returns `UNIT` for 0^0.
///
/// Requirements:
/// - Refer to the requirements in {exp2}, {log2}, and {mul}.
///
/// @param x The base as an SD59x18 number.
/// @param y Exponent to raise x to, as an SD59x18 number
/// @return result x raised to power y, as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function pow(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    int256 yInt = y.unwrap();

    // If both x and y are zero, the result is `UNIT`. If just x is zero, the result is always zero.
    if (xInt == 0) {
        return yInt == 0 ? UNIT : ZERO;
    }
    // If x is `UNIT`, the result is always `UNIT`.
    else if (xInt == uUNIT) {
        return UNIT;
    }

    // If y is zero, the result is always `UNIT`.
    if (yInt == 0) {
        return UNIT;
    }
    // If y is `UNIT`, the result is always x.
    else if (yInt == uUNIT) {
        return x;
    }

    // Calculate the result using the formula.
    result = exp2(mul(log2(x), y));
}

/// @notice Raises x (an SD59x18 number) to the power y (an unsigned basic integer) using the well-known
/// algorithm "exponentiation by squaring".
///
/// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv18}.
/// - Returns `UNIT` for 0^0.
///
/// Requirements:
/// - Refer to the requirements in {abs} and {Common.mulDiv18}.
/// - The result must fit in SD59x18.
///
/// @param x The base as an SD59x18 number.
/// @param y The exponent as a uint256.
/// @return result The result as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function powu(SD59x18 x, uint256 y) pure returns (SD59x18 result) {
    uint256 xAbs = uint256(abs(x).unwrap());

    // Calculate the first iteration of the loop in advance.
    uint256 resultAbs = y & 1 > 0 ? xAbs : uint256(uUNIT);

    // Equivalent to `for(y /= 2; y > 0; y /= 2)`.
    uint256 yAux = y;
    for (yAux >>= 1; yAux > 0; yAux >>= 1) {
        xAbs = Common.mulDiv18(xAbs, xAbs);

        // Equivalent to `y % 2 == 1`.
        if (yAux & 1 > 0) {
            resultAbs = Common.mulDiv18(resultAbs, xAbs);
        }
    }

    // The result must fit in SD59x18.
    if (resultAbs > uint256(uMAX_SD59x18)) {
        revert Errors.PRBMath_SD59x18_Powu_Overflow(x, y);
    }

    unchecked {
        // Is the base negative and the exponent odd? If yes, the result should be negative.
        int256 resultInt = int256(resultAbs);
        bool isNegative = x.unwrap() < 0 && y & 1 == 1;
        if (isNegative) {
            resultInt = -resultInt;
        }
        result = wrap(resultInt);
    }
}

/// @notice Calculates the square root of x using the Babylonian method.
///
/// @dev See https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
///
/// Notes:
/// - Only the positive root is returned.
/// - The result is rounded toward zero.
///
/// Requirements:
/// - x cannot be negative, since complex numbers are not supported.
/// - x must be less than `MAX_SD59x18 / UNIT`.
///
/// @param x The SD59x18 number for which to calculate the square root.
/// @return result The result as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function sqrt(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt < 0) {
        revert Errors.PRBMath_SD59x18_Sqrt_NegativeInput(x);
    }
    if (xInt > uMAX_SD59x18 / uUNIT) {
        revert Errors.PRBMath_SD59x18_Sqrt_Overflow(x);
    }

    unchecked {
        // Multiply x by `UNIT` to account for the factor of `UNIT` picked up when multiplying two SD59x18 numbers.
        // In this case, the two numbers are both the square root.
        uint256 resultUint = Common.sqrt(uint256(xInt * uUNIT));
        result = wrap(int256(resultUint));
    }
}

// SPDX-License-Identifier: MIT
// Derived from UD60x18 from PRBMath ( https://github.com/PaulRBerg/prb-math )
pragma solidity ^0.8.19;

import {mulDiv} from "@prb/math/Common.sol";
import {UD60x18} from "@prb/math/UD60x18.sol";
import {SD49x28, uMAX_SD49x28} from "./SD49x28.sol";

type UD50x28 is uint256;

/// @dev Max UD50x28 value
uint256 constant uMAX_UD50x28 = type(uint256).max;

/// @dev The unit number, which gives the decimal precision of UD50x28.
uint256 constant uUNIT = 1e28;
UD50x28 constant UNIT = UD50x28.wrap(uUNIT);

// Scaling factor = 10 ** (28 - 18)
uint256 constant SCALING_FACTOR = 1e10;

error UD50x28_IntoSD49x28_Overflow(UD50x28 x);

/// @notice Wraps a uint256 number into the UD50x28 value type.
function wrap(uint256 x) pure returns (UD50x28 result) {
    result = UD50x28.wrap(x);
}

/// @notice Unwraps a UD50x28 number into uint256.
function unwrap(UD50x28 x) pure returns (uint256 result) {
    result = UD50x28.unwrap(x);
}

function ud50x28(uint256 x) pure returns (UD50x28 result) {
    result = UD50x28.wrap(x);
}

/// @notice Casts a UD50x28 number into SD49x28.
/// @dev Requirements:
/// - x must be less than or equal to `uMAX_SD49x28`.
function intoSD49x28(UD50x28 x) pure returns (SD49x28 result) {
    uint256 xUint = UD50x28.unwrap(x);
    if (xUint > uint256(uMAX_SD49x28)) {
        revert UD50x28_IntoSD49x28_Overflow(x);
    }
    result = SD49x28.wrap(int256(xUint));
}

function intoUD60x18(UD50x28 x) pure returns (UD60x18 result) {
    result = UD60x18.wrap(x.unwrap() / SCALING_FACTOR);
}

/// @notice Implements the checked addition operation (+) in the UD50x28 type.
function add(UD50x28 x, UD50x28 y) pure returns (UD50x28 result) {
    result = wrap(x.unwrap() + y.unwrap());
}

/// @notice Implements the AND (&) bitwise operation in the UD50x28 type.
function and(UD50x28 x, uint256 bits) pure returns (UD50x28 result) {
    result = wrap(x.unwrap() & bits);
}

/// @notice Implements the AND (&) bitwise operation in the UD50x28 type.
function and2(UD50x28 x, UD50x28 y) pure returns (UD50x28 result) {
    result = wrap(x.unwrap() & y.unwrap());
}

/// @notice Implements the equal operation (==) in the UD50x28 type.
function eq(UD50x28 x, UD50x28 y) pure returns (bool result) {
    result = x.unwrap() == y.unwrap();
}

/// @notice Implements the greater than operation (>) in the UD50x28 type.
function gt(UD50x28 x, UD50x28 y) pure returns (bool result) {
    result = x.unwrap() > y.unwrap();
}

/// @notice Implements the greater than or equal to operation (>=) in the UD50x28 type.
function gte(UD50x28 x, UD50x28 y) pure returns (bool result) {
    result = x.unwrap() >= y.unwrap();
}

/// @notice Implements a zero comparison check function in the UD50x28 type.
function isZero(UD50x28 x) pure returns (bool result) {
    // This wouldn't work if x could be negative.
    result = x.unwrap() == 0;
}

/// @notice Implements the left shift operation (<<) in the UD50x28 type.
function lshift(UD50x28 x, uint256 bits) pure returns (UD50x28 result) {
    result = wrap(x.unwrap() << bits);
}

/// @notice Implements the lower than operation (<) in the UD50x28 type.
function lt(UD50x28 x, UD50x28 y) pure returns (bool result) {
    result = x.unwrap() < y.unwrap();
}

/// @notice Implements the lower than or equal to operation (<=) in the UD50x28 type.
function lte(UD50x28 x, UD50x28 y) pure returns (bool result) {
    result = x.unwrap() <= y.unwrap();
}

/// @notice Implements the checked modulo operation (%) in the UD50x28 type.
function mod(UD50x28 x, UD50x28 y) pure returns (UD50x28 result) {
    result = wrap(x.unwrap() % y.unwrap());
}

/// @notice Implements the not equal operation (!=) in the UD50x28 type.
function neq(UD50x28 x, UD50x28 y) pure returns (bool result) {
    result = x.unwrap() != y.unwrap();
}

/// @notice Implements the NOT (~) bitwise operation in the UD50x28 type.
function not(UD50x28 x) pure returns (UD50x28 result) {
    result = wrap(~x.unwrap());
}

/// @notice Implements the OR (|) bitwise operation in the UD50x28 type.
function or(UD50x28 x, UD50x28 y) pure returns (UD50x28 result) {
    result = wrap(x.unwrap() | y.unwrap());
}

/// @notice Implements the right shift operation (>>) in the UD50x28 type.
function rshift(UD50x28 x, uint256 bits) pure returns (UD50x28 result) {
    result = wrap(x.unwrap() >> bits);
}

/// @notice Implements the checked subtraction operation (-) in the UD50x28 type.
function sub(UD50x28 x, UD50x28 y) pure returns (UD50x28 result) {
    result = wrap(x.unwrap() - y.unwrap());
}

/// @notice Implements the unchecked addition operation (+) in the UD50x28 type.
function uncheckedAdd(UD50x28 x, UD50x28 y) pure returns (UD50x28 result) {
    unchecked {
        result = wrap(x.unwrap() + y.unwrap());
    }
}

/// @notice Implements the unchecked subtraction operation (-) in the UD50x28 type.
function uncheckedSub(UD50x28 x, UD50x28 y) pure returns (UD50x28 result) {
    unchecked {
        result = wrap(x.unwrap() - y.unwrap());
    }
}

/// @notice Implements the XOR (^) bitwise operation in the UD50x28 type.
function xor(UD50x28 x, UD50x28 y) pure returns (UD50x28 result) {
    result = wrap(x.unwrap() ^ y.unwrap());
}

/// @notice Calculates the arithmetic average of x and y using the following formula:
///
/// $$
/// avg(x, y) = (x & y) + ((xUint ^ yUint) / 2)
/// $$
//
/// In English, this is what this formula does:
///
/// 1. AND x and y.
/// 2. Calculate half of XOR x and y.
/// 3. Add the two results together.
///
/// This technique is known as SWAR, which stands for "SIMD within a register". You can read more about it here:
/// https://devblogs.microsoft.com/oldnewthing/20220207-00/?p=106223
///
/// @dev Notes:
/// - The result is rounded down.
///
/// @param x The first operand as a UD50x28 number.
/// @param y The second operand as a UD50x28 number.
/// @return result The arithmetic average as a UD50x28 number.
/// @custom:smtchecker abstract-function-nondet
function avg(UD50x28 x, UD50x28 y) pure returns (UD50x28 result) {
    uint256 xUint = x.unwrap();
    uint256 yUint = y.unwrap();
    unchecked {
        result = wrap((xUint & yUint) + ((xUint ^ yUint) >> 1));
    }
}

/// @notice Divides two UD50x28 numbers, returning a new UD50x28 number.
///
/// @dev Uses {Common.mulDiv} to enable overflow-safe multiplication and division.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv}.
///
/// Requirements:
/// - Refer to the requirements in {Common.mulDiv}.
///
/// @param x The numerator as a UD50x28 number.
/// @param y The denominator as a UD50x28 number.
/// @param result The quotient as a UD50x28 number.
/// @custom:smtchecker abstract-function-nondet
function div(UD50x28 x, UD50x28 y) pure returns (UD50x28 result) {
    result = UD50x28.wrap(mulDiv(x.unwrap(), uUNIT, y.unwrap()));
}

/// @notice Multiplies two UD50x28 numbers together, returning a new UD50x28 number.
///
/// @dev Uses {Common.mulDiv} to enable overflow-safe multiplication and division.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv}.
///
/// Requirements:
/// - Refer to the requirements in {Common.mulDiv}.
///
/// @dev See the documentation in {Common.mulDiv18}.
/// @param x The multiplicand as a UD50x28 number.
/// @param y The multiplier as a UD50x28 number.
/// @return result The product as a UD50x28 number.
/// @custom:smtchecker abstract-function-nondet
function mul(UD50x28 x, UD50x28 y) pure returns (UD50x28 result) {
    result = UD50x28.wrap(mulDiv(x.unwrap(), y.unwrap(), uUNIT));
}

//////////////////////////////////////////////////////////////////////////

// The global "using for" directive makes the functions in this library callable on the UD50x28 type.
using {
    unwrap,
    intoUD60x18,
    intoSD49x28,
    avg,
    add,
    and,
    eq,
    gt,
    gte,
    isZero,
    lshift,
    lt,
    lte,
    mod,
    neq,
    not,
    or,
    rshift,
    sub,
    uncheckedAdd,
    uncheckedSub,
    xor
} for UD50x28 global;

// The global "using for" directive makes it possible to use these operators on the UD50x28 type.
using {
    add as +,
    and2 as &,
    div as /,
    eq as ==,
    gt as >,
    gte as >=,
    lt as <,
    lte as <=,
    or as |,
    mod as %,
    mul as *,
    neq as !=,
    not as ~,
    sub as -,
    xor as ^
} for UD50x28 global;

// SPDX-License-Identifier: MIT
// Derived from SD59x18 from PRBMath ( https://github.com/PaulRBerg/prb-math )
pragma solidity ^0.8.19;

import {mulDiv} from "@prb/math/Common.sol";
import {UD60x18} from "@prb/math/UD60x18.sol";
import {SD59x18} from "@prb/math/SD59x18.sol";

import {UD50x28} from "./UD50x28.sol";

type SD49x28 is int256;

/// @dev Max SD49x28 value
int256 constant uMAX_SD49x28 = type(int256).max;
/// @dev Min SD49x28 value
int256 constant uMIN_SD49x28 = type(int256).min;

/// @dev The unit number, which gives the decimal precision of SD49x28.
int256 constant uUNIT = 1e28;
SD49x28 constant UNIT = SD49x28.wrap(uUNIT);

// Scaling factor = 10 ** (28 - 18)
int256 constant SCALING_FACTOR = 1e10;

error SD49x28_Mul_InputTooSmall();
error SD49x28_Mul_Overflow(SD49x28 x, SD49x28 y);

error SD49x28_Div_InputTooSmall();
error SD49x28_Div_Overflow(SD49x28 x, SD49x28 y);

error SD49x28_IntoUD50x28_Underflow(SD49x28 x);

error SD49x28_Abs_MinSD49x28();

/// @notice Wraps a int256 number into the SD49x28 value type.
function wrap(int256 x) pure returns (SD49x28 result) {
    result = SD49x28.wrap(x);
}

/// @notice Unwraps a SD49x28 number into int256.
function unwrap(SD49x28 x) pure returns (int256 result) {
    result = SD49x28.unwrap(x);
}

function sd49x28(int256 x) pure returns (SD49x28 result) {
    result = SD49x28.wrap(x);
}

/// @notice Casts an SD49x28 number into UD50x28.
/// @dev Requirements:
/// - x must be positive.
function intoUD50x28(SD49x28 x) pure returns (UD50x28 result) {
    int256 xInt = SD49x28.unwrap(x);
    if (xInt < 0) {
        revert SD49x28_IntoUD50x28_Underflow(x);
    }
    result = UD50x28.wrap(uint256(xInt));
}

function intoUD60x18(SD49x28 x) pure returns (UD60x18 result) {
    return intoUD50x28(x).intoUD60x18();
}

function intoSD59x18(SD49x28 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(x.unwrap() / SCALING_FACTOR);
}

/// @notice Implements the checked addition operation (+) in the SD49x28 type.
function add(SD49x28 x, SD49x28 y) pure returns (SD49x28 result) {
    return wrap(x.unwrap() + y.unwrap());
}

/// @notice Implements the AND (&) bitwise operation in the SD49x28 type.
function and(SD49x28 x, int256 bits) pure returns (SD49x28 result) {
    return wrap(x.unwrap() & bits);
}

/// @notice Implements the AND (&) bitwise operation in the SD49x28 type.
function and2(SD49x28 x, SD49x28 y) pure returns (SD49x28 result) {
    return wrap(x.unwrap() & y.unwrap());
}

/// @notice Implements the equal (=) operation in the SD49x28 type.
function eq(SD49x28 x, SD49x28 y) pure returns (bool result) {
    result = x.unwrap() == y.unwrap();
}

/// @notice Implements the greater than operation (>) in the SD49x28 type.
function gt(SD49x28 x, SD49x28 y) pure returns (bool result) {
    result = x.unwrap() > y.unwrap();
}

/// @notice Implements the greater than or equal to operation (>=) in the SD49x28 type.
function gte(SD49x28 x, SD49x28 y) pure returns (bool result) {
    result = x.unwrap() >= y.unwrap();
}

/// @notice Implements a zero comparison check function in the SD49x28 type.
function isZero(SD49x28 x) pure returns (bool result) {
    result = x.unwrap() == 0;
}

/// @notice Implements the left shift operation (<<) in the SD49x28 type.
function lshift(SD49x28 x, uint256 bits) pure returns (SD49x28 result) {
    result = wrap(x.unwrap() << bits);
}

/// @notice Implements the lower than operation (<) in the SD49x28 type.
function lt(SD49x28 x, SD49x28 y) pure returns (bool result) {
    result = x.unwrap() < y.unwrap();
}

/// @notice Implements the lower than or equal to operation (<=) in the SD49x28 type.
function lte(SD49x28 x, SD49x28 y) pure returns (bool result) {
    result = x.unwrap() <= y.unwrap();
}

/// @notice Implements the unchecked modulo operation (%) in the SD49x28 type.
function mod(SD49x28 x, SD49x28 y) pure returns (SD49x28 result) {
    result = wrap(x.unwrap() % y.unwrap());
}

/// @notice Implements the not equal operation (!=) in the SD49x28 type.
function neq(SD49x28 x, SD49x28 y) pure returns (bool result) {
    result = x.unwrap() != y.unwrap();
}

/// @notice Implements the NOT (~) bitwise operation in the SD49x28 type.
function not(SD49x28 x) pure returns (SD49x28 result) {
    result = wrap(~x.unwrap());
}

/// @notice Implements the OR (|) bitwise operation in the SD49x28 type.
function or(SD49x28 x, SD49x28 y) pure returns (SD49x28 result) {
    result = wrap(x.unwrap() | y.unwrap());
}

/// @notice Implements the right shift operation (>>) in the SD49x28 type.
function rshift(SD49x28 x, uint256 bits) pure returns (SD49x28 result) {
    result = wrap(x.unwrap() >> bits);
}

/// @notice Implements the checked subtraction operation (-) in the SD49x28 type.
function sub(SD49x28 x, SD49x28 y) pure returns (SD49x28 result) {
    result = wrap(x.unwrap() - y.unwrap());
}

/// @notice Implements the checked unary minus operation (-) in the SD49x28 type.
function unary(SD49x28 x) pure returns (SD49x28 result) {
    result = wrap(-x.unwrap());
}

/// @notice Implements the unchecked addition operation (+) in the SD49x28 type.
function uncheckedAdd(SD49x28 x, SD49x28 y) pure returns (SD49x28 result) {
    unchecked {
        result = wrap(x.unwrap() + y.unwrap());
    }
}

/// @notice Implements the unchecked subtraction operation (-) in the SD49x28 type.
function uncheckedSub(SD49x28 x, SD49x28 y) pure returns (SD49x28 result) {
    unchecked {
        result = wrap(x.unwrap() - y.unwrap());
    }
}

/// @notice Implements the unchecked unary minus operation (-) in the SD49x28 type.
function uncheckedUnary(SD49x28 x) pure returns (SD49x28 result) {
    unchecked {
        result = wrap(-x.unwrap());
    }
}

/// @notice Implements the XOR (^) bitwise operation in the SD49x28 type.
function xor(SD49x28 x, SD49x28 y) pure returns (SD49x28 result) {
    result = wrap(x.unwrap() ^ y.unwrap());
}

/// @notice Calculates the absolute value of x.
///
/// @dev Requirements:
/// - x must be greater than `MIN_SD49x28`.
///
/// @param x The SD49x28 number for which to calculate the absolute value.
/// @param result The absolute value of x as an SD49x28 number.
/// @custom:smtchecker abstract-function-nondet
function abs(SD49x28 x) pure returns (SD49x28 result) {
    int256 xInt = x.unwrap();
    if (xInt == uMIN_SD49x28) {
        revert SD49x28_Abs_MinSD49x28();
    }
    result = xInt < 0 ? wrap(-xInt) : x;
}

/// @notice Calculates the arithmetic average of x and y.
///
/// @dev Notes:
/// - The result is rounded toward zero.
///
/// @param x The first operand as an SD49x28 number.
/// @param y The second operand as an SD49x28 number.
/// @return result The arithmetic average as an SD49x28 number.
/// @custom:smtchecker abstract-function-nondet
function avg(SD49x28 x, SD49x28 y) pure returns (SD49x28 result) {
    int256 xInt = x.unwrap();
    int256 yInt = y.unwrap();

    unchecked {
        // This operation is equivalent to `x / 2 +  y / 2`, and it can never overflow.
        int256 sum = (xInt >> 1) + (yInt >> 1);

        if (sum < 0) {
            // If at least one of x and y is odd, add 1 to the result, because shifting negative numbers to the right
            // rounds down to infinity. The right part is equivalent to `sum + (x % 2 == 1 || y % 2 == 1)`.
            assembly ("memory-safe") {
                result := add(sum, and(or(xInt, yInt), 1))
            }
        } else {
            // Add 1 if both x and y are odd to account for the double 0.5 remainder truncated after shifting.
            result = wrap(sum + (xInt & yInt & 1));
        }
    }
}

/// @notice Divides two SD49x28 numbers, returning a new SD49x28 number.
///
/// @dev This is an extension of {Common.mulDiv} for signed numbers, which works by computing the signs and the absolute
/// values separately.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv}.
/// - The result is rounded toward zero.
///
/// Requirements:
/// - Refer to the requirements in {Common.mulDiv}.
/// - None of the inputs can be `MIN_SD49x28`.
/// - The denominator must not be zero.
/// - The result must fit in SD49x28.
///
/// @param x The numerator as an SD49x28 number.
/// @param y The denominator as an SD49x28 number.
/// @param result The quotient as an SD49x28 number.
/// @custom:smtchecker abstract-function-nondet
function div(SD49x28 x, SD49x28 y) pure returns (SD49x28 result) {
    int256 xInt = x.unwrap();
    int256 yInt = y.unwrap();
    if (xInt == uMIN_SD49x28 || yInt == uMIN_SD49x28) {
        revert SD49x28_Div_InputTooSmall();
    }

    // Get hold of the absolute values of x and y.
    uint256 xAbs;
    uint256 yAbs;
    unchecked {
        xAbs = xInt < 0 ? uint256(-xInt) : uint256(xInt);
        yAbs = yInt < 0 ? uint256(-yInt) : uint256(yInt);
    }

    // Compute the absolute value (x*UNIT÷y). The resulting value must fit in SD49x28.
    uint256 resultAbs = mulDiv(xAbs, uint256(uUNIT), yAbs);
    if (resultAbs > uint256(uMAX_SD49x28)) {
        revert SD49x28_Div_Overflow(x, y);
    }

    // Check if x and y have the same sign using two's complement representation. The left-most bit represents the sign (1 for
    // negative, 0 for positive or zero).
    bool sameSign = (xInt ^ yInt) > -1;

    // If the inputs have the same sign, the result should be positive. Otherwise, it should be negative.
    unchecked {
        result = wrap(sameSign ? int256(resultAbs) : -int256(resultAbs));
    }
}

/// @notice Multiplies two SD49x28 numbers together, returning a new SD49x28 number.
///
/// @dev Notes:
/// - Refer to the notes in {Common.mulDiv18}.
///
/// Requirements:
/// - Refer to the requirements in {Common.mulDiv18}.
/// - None of the inputs can be `MIN_SD49x28`.
/// - The result must fit in SD49x28.
///
/// @param x The multiplicand as an SD49x28 number.
/// @param y The multiplier as an SD49x28 number.
/// @return result The product as an SD49x28 number.
/// @custom:smtchecker abstract-function-nondet
function mul(SD49x28 x, SD49x28 y) pure returns (SD49x28 result) {
    int256 xInt = x.unwrap();
    int256 yInt = y.unwrap();
    if (xInt == uMIN_SD49x28 || yInt == uMIN_SD49x28) {
        revert SD49x28_Mul_InputTooSmall();
    }

    // Get hold of the absolute values of x and y.
    uint256 xAbs;
    uint256 yAbs;
    unchecked {
        xAbs = xInt < 0 ? uint256(-xInt) : uint256(xInt);
        yAbs = yInt < 0 ? uint256(-yInt) : uint256(yInt);
    }

    // Compute the absolute value (x*y÷UNIT). The resulting value must fit in SD49x28.
    uint256 resultAbs = mulDiv(xAbs, yAbs, uint256(uUNIT));
    if (resultAbs > uint256(uMAX_SD49x28)) {
        revert SD49x28_Mul_Overflow(x, y);
    }

    // Check if x and y have the same sign using two's complement representation. The left-most bit represents the sign (1 for
    // negative, 0 for positive or zero).
    bool sameSign = (xInt ^ yInt) > -1;

    // If the inputs have the same sign, the result should be positive. Otherwise, it should be negative.
    unchecked {
        result = wrap(sameSign ? int256(resultAbs) : -int256(resultAbs));
    }
}

//////////////////////////////////////////////////////////////////////////

// The global "using for" directive makes the functions in this library callable on the SD49x28 type.
using {
    unwrap,
    intoSD59x18,
    intoUD50x28,
    intoUD60x18,
    abs,
    avg,
    add,
    and,
    eq,
    gt,
    gte,
    isZero,
    lshift,
    lt,
    lte,
    mod,
    neq,
    not,
    or,
    rshift,
    sub,
    uncheckedAdd,
    uncheckedSub,
    xor
} for SD49x28 global;

// The global "using for" directive makes it possible to use these operators on the SD49x28 type.
using {
    add as +,
    and2 as &,
    div as /,
    eq as ==,
    gt as >,
    gte as >=,
    lt as <,
    lte as <=,
    or as |,
    mod as %,
    mul as *,
    neq as !=,
    not as ~,
    sub as -,
    unary as -,
    xor as ^
} for SD49x28 global;

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "@prb/math/UD60x18.sol";

import {IOracleAdapter} from "../adapter/IOracleAdapter.sol";

interface IPoolFactoryEvents {
    event SetDiscountPerPool(UD60x18 indexed discountPerPool);
    event SetFeeReceiver(address indexed feeReceiver);
    event PoolDeployed(
        address indexed base,
        address indexed quote,
        address oracleAdapter,
        UD60x18 strike,
        uint256 maturity,
        bool isCallPool,
        address poolAddress
    );

    event PricingPath(
        address pool,
        address[][] basePath,
        uint8[] basePathDecimals,
        IOracleAdapter.AdapterType baseAdapterType,
        address[][] quotePath,
        uint8[] quotePathDecimals,
        IOracleAdapter.AdapterType quoteAdapterType
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Doubly linked list implementation with enumeration functions
 */
library DoublyLinkedList {
    struct DoublyLinkedListInternal {
        mapping(bytes32 => bytes32) _nextValues;
        mapping(bytes32 => bytes32) _prevValues;
    }

    struct Bytes32List {
        DoublyLinkedListInternal _inner;
    }

    struct AddressList {
        DoublyLinkedListInternal _inner;
    }

    struct Uint256List {
        DoublyLinkedListInternal _inner;
    }

    /**
     * @notice indicate that an attempt was made to insert 0 into a list
     */
    error DoublyLinkedList__InvalidInput();

    /**
     * @notice indicate that a non-existent value was used as a reference for insertion or lookup
     */
    error DoublyLinkedList__NonExistentEntry();

    function contains(
        Bytes32List storage self,
        bytes32 value
    ) internal view returns (bool) {
        return _contains(self._inner, value);
    }

    function contains(
        AddressList storage self,
        address value
    ) internal view returns (bool) {
        return _contains(self._inner, bytes32(uint256(uint160(value))));
    }

    function contains(
        Uint256List storage self,
        uint256 value
    ) internal view returns (bool) {
        return _contains(self._inner, bytes32(value));
    }

    function prev(
        Bytes32List storage self,
        bytes32 value
    ) internal view returns (bytes32) {
        return _prev(self._inner, value);
    }

    function prev(
        AddressList storage self,
        address value
    ) internal view returns (address) {
        return
            address(
                uint160(
                    uint256(
                        _prev(self._inner, bytes32(uint256(uint160(value))))
                    )
                )
            );
    }

    function prev(
        Uint256List storage self,
        uint256 value
    ) internal view returns (uint256) {
        return uint256(_prev(self._inner, bytes32(value)));
    }

    function next(
        Bytes32List storage self,
        bytes32 value
    ) internal view returns (bytes32) {
        return _next(self._inner, value);
    }

    function next(
        AddressList storage self,
        address value
    ) internal view returns (address) {
        return
            address(
                uint160(
                    uint256(
                        _next(self._inner, bytes32(uint256(uint160(value))))
                    )
                )
            );
    }

    function next(
        Uint256List storage self,
        uint256 value
    ) internal view returns (uint256) {
        return uint256(_next(self._inner, bytes32(value)));
    }

    function insertBefore(
        Bytes32List storage self,
        bytes32 nextValue,
        bytes32 newValue
    ) internal returns (bool status) {
        status = _insertBefore(self._inner, nextValue, newValue);
    }

    function insertBefore(
        AddressList storage self,
        address nextValue,
        address newValue
    ) internal returns (bool status) {
        status = _insertBefore(
            self._inner,
            bytes32(uint256(uint160(nextValue))),
            bytes32(uint256(uint160(newValue)))
        );
    }

    function insertBefore(
        Uint256List storage self,
        uint256 nextValue,
        uint256 newValue
    ) internal returns (bool status) {
        status = _insertBefore(
            self._inner,
            bytes32(nextValue),
            bytes32(newValue)
        );
    }

    function insertAfter(
        Bytes32List storage self,
        bytes32 prevValue,
        bytes32 newValue
    ) internal returns (bool status) {
        status = _insertAfter(self._inner, prevValue, newValue);
    }

    function insertAfter(
        AddressList storage self,
        address prevValue,
        address newValue
    ) internal returns (bool status) {
        status = _insertAfter(
            self._inner,
            bytes32(uint256(uint160(prevValue))),
            bytes32(uint256(uint160(newValue)))
        );
    }

    function insertAfter(
        Uint256List storage self,
        uint256 prevValue,
        uint256 newValue
    ) internal returns (bool status) {
        status = _insertAfter(
            self._inner,
            bytes32(prevValue),
            bytes32(newValue)
        );
    }

    function push(
        Bytes32List storage self,
        bytes32 value
    ) internal returns (bool status) {
        status = _push(self._inner, value);
    }

    function push(
        AddressList storage self,
        address value
    ) internal returns (bool status) {
        status = _push(self._inner, bytes32(uint256(uint160(value))));
    }

    function push(
        Uint256List storage self,
        uint256 value
    ) internal returns (bool status) {
        status = _push(self._inner, bytes32(value));
    }

    function pop(Bytes32List storage self) internal returns (bytes32 value) {
        value = _pop(self._inner);
    }

    function pop(AddressList storage self) internal returns (address value) {
        value = address(uint160(uint256(_pop(self._inner))));
    }

    function pop(Uint256List storage self) internal returns (uint256 value) {
        value = uint256(_pop(self._inner));
    }

    function shift(Bytes32List storage self) internal returns (bytes32 value) {
        value = _shift(self._inner);
    }

    function shift(AddressList storage self) internal returns (address value) {
        value = address(uint160(uint256(_shift(self._inner))));
    }

    function shift(Uint256List storage self) internal returns (uint256 value) {
        value = uint256(_shift(self._inner));
    }

    function unshift(
        Bytes32List storage self,
        bytes32 value
    ) internal returns (bool status) {
        status = _unshift(self._inner, value);
    }

    function unshift(
        AddressList storage self,
        address value
    ) internal returns (bool status) {
        status = _unshift(self._inner, bytes32(uint256(uint160(value))));
    }

    function unshift(
        Uint256List storage self,
        uint256 value
    ) internal returns (bool status) {
        status = _unshift(self._inner, bytes32(value));
    }

    function remove(
        Bytes32List storage self,
        bytes32 value
    ) internal returns (bool status) {
        status = _remove(self._inner, value);
    }

    function remove(
        AddressList storage self,
        address value
    ) internal returns (bool status) {
        status = _remove(self._inner, bytes32(uint256(uint160(value))));
    }

    function remove(
        Uint256List storage self,
        uint256 value
    ) internal returns (bool status) {
        status = _remove(self._inner, bytes32(value));
    }

    function replace(
        Bytes32List storage self,
        bytes32 oldValue,
        bytes32 newValue
    ) internal returns (bool status) {
        status = _replace(self._inner, oldValue, newValue);
    }

    function replace(
        AddressList storage self,
        address oldValue,
        address newValue
    ) internal returns (bool status) {
        status = _replace(
            self._inner,
            bytes32(uint256(uint160(oldValue))),
            bytes32(uint256(uint160(newValue)))
        );
    }

    function replace(
        Uint256List storage self,
        uint256 oldValue,
        uint256 newValue
    ) internal returns (bool status) {
        status = _replace(self._inner, bytes32(oldValue), bytes32(newValue));
    }

    function _contains(
        DoublyLinkedListInternal storage self,
        bytes32 value
    ) private view returns (bool) {
        return
            value != 0 &&
            (self._nextValues[value] != 0 || self._prevValues[0] == value);
    }

    function _prev(
        DoublyLinkedListInternal storage self,
        bytes32 nextValue
    ) private view returns (bytes32 prevValue) {
        prevValue = self._prevValues[nextValue];
        if (
            nextValue != 0 &&
            prevValue == 0 &&
            _next(self, prevValue) != nextValue
        ) revert DoublyLinkedList__NonExistentEntry();
    }

    function _next(
        DoublyLinkedListInternal storage self,
        bytes32 prevValue
    ) private view returns (bytes32 nextValue) {
        nextValue = self._nextValues[prevValue];
        if (
            prevValue != 0 &&
            nextValue == 0 &&
            _prev(self, nextValue) != prevValue
        ) revert DoublyLinkedList__NonExistentEntry();
    }

    function _insertBefore(
        DoublyLinkedListInternal storage self,
        bytes32 nextValue,
        bytes32 newValue
    ) private returns (bool status) {
        status = _insertBetween(
            self,
            _prev(self, nextValue),
            nextValue,
            newValue
        );
    }

    function _insertAfter(
        DoublyLinkedListInternal storage self,
        bytes32 prevValue,
        bytes32 newValue
    ) private returns (bool status) {
        status = _insertBetween(
            self,
            prevValue,
            _next(self, prevValue),
            newValue
        );
    }

    function _insertBetween(
        DoublyLinkedListInternal storage self,
        bytes32 prevValue,
        bytes32 nextValue,
        bytes32 newValue
    ) private returns (bool status) {
        if (newValue == 0) revert DoublyLinkedList__InvalidInput();

        if (!_contains(self, newValue)) {
            _link(self, prevValue, newValue);
            _link(self, newValue, nextValue);
            status = true;
        }
    }

    function _push(
        DoublyLinkedListInternal storage self,
        bytes32 value
    ) private returns (bool status) {
        status = _insertBetween(self, _prev(self, 0), 0, value);
    }

    function _pop(
        DoublyLinkedListInternal storage self
    ) private returns (bytes32 value) {
        value = _prev(self, 0);
        _remove(self, value);
    }

    function _shift(
        DoublyLinkedListInternal storage self
    ) private returns (bytes32 value) {
        value = _next(self, 0);
        _remove(self, value);
    }

    function _unshift(
        DoublyLinkedListInternal storage self,
        bytes32 value
    ) private returns (bool status) {
        status = _insertBetween(self, 0, _next(self, 0), value);
    }

    function _remove(
        DoublyLinkedListInternal storage self,
        bytes32 value
    ) private returns (bool status) {
        if (_contains(self, value)) {
            _link(self, _prev(self, value), _next(self, value));
            delete self._prevValues[value];
            delete self._nextValues[value];
            status = true;
        }
    }

    function _replace(
        DoublyLinkedListInternal storage self,
        bytes32 oldValue,
        bytes32 newValue
    ) private returns (bool status) {
        if (!_contains(self, oldValue))
            revert DoublyLinkedList__NonExistentEntry();

        status = _insertBetween(
            self,
            _prev(self, oldValue),
            _next(self, oldValue),
            newValue
        );

        if (status) {
            delete self._prevValues[oldValue];
            delete self._nextValues[oldValue];
        }
    }

    function _link(
        DoublyLinkedListInternal storage self,
        bytes32 prevValue,
        bytes32 nextValue
    ) private {
        self._nextValues[prevValue] = nextValue;
        self._prevValues[nextValue] = prevValue;
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {Math} from "@solidstate/contracts/utils/Math.sol";

import {UD60x18} from "@prb/math/UD60x18.sol";
import {SD59x18, sd} from "@prb/math/SD59x18.sol";

import {iZERO, ZERO, UD50_ZERO, UD50_ONE, UD50_TWO} from "./Constants.sol";
import {IPosition} from "./IPosition.sol";
import {Pricing} from "./Pricing.sol";
import {UD50x28} from "./UD50x28.sol";
import {SD49x28} from "./SD49x28.sol";
import {PRBMathExtra} from "./PRBMathExtra.sol";

/// @notice Keeps track of LP positions.
///         Stores the lower and upper Ticks of a user's range order, and tracks the pro-rata exposure of the order.
library Position {
    using Math for int256;
    using Position for Position.Key;
    using Position for Position.KeyInternal;
    using Position for Position.OrderType;
    using PRBMathExtra for UD60x18;

    struct Key {
        // The Agent that owns the exposure change of the Position
        address owner;
        // The Agent that can control modifications to the Position
        address operator;
        // The lower tick normalized price of the range order (18 decimals)
        UD60x18 lower;
        // The upper tick normalized price of the range order (18 decimals)
        UD60x18 upper;
        OrderType orderType;
    }

    /// @notice All the data used to calculate the key of the position
    struct KeyInternal {
        // The Agent that owns the exposure change of the Position
        address owner;
        // The Agent that can control modifications to the Position
        address operator;
        // The lower tick normalized price of the range order (18 decimals)
        UD60x18 lower;
        // The upper tick normalized price of the range order (18 decimals)
        UD60x18 upper;
        OrderType orderType;
        // ---- Values under are not used to compute the key hash but are included in this struct to reduce stack depth
        bool isCall;
        // The option strike (18 decimals)
        UD60x18 strike;
    }

    /// @notice The order type of a position
    enum OrderType {
        CSUP, // Collateral <-> Short - Use Premiums
        CS, // Collateral <-> Short
        LC // Long <-> Collateral
    }

    /// @notice All the data required to be saved in storage
    struct Data {
        // Used to track claimable fees over time (28 decimals)
        SD49x28 lastFeeRate;
        // The amount of fees a user can claim now. Resets after claim (18 decimals)
        UD60x18 claimableFees;
        // The timestamp of the last deposit. Used to enforce withdrawal delay
        uint256 lastDeposit;
    }

    struct Delta {
        SD59x18 collateral;
        SD59x18 longs;
        SD59x18 shorts;
    }

    /// @notice Returns the position key hash for `self`
    function keyHash(Key memory self) internal pure returns (bytes32) {
        return keccak256(abi.encode(self.owner, self.operator, self.lower, self.upper, self.orderType));
    }

    /// @notice Returns the position key hash for `self`
    function keyHash(KeyInternal memory self) internal pure returns (bytes32) {
        return
            keyHash(
                Key({
                    owner: self.owner,
                    operator: self.operator,
                    lower: self.lower,
                    upper: self.upper,
                    orderType: self.orderType
                })
            );
    }

    /// @notice Returns the internal position key for `self`
    /// @param strike The strike of the option (18 decimals)
    function toKeyInternal(Key memory self, UD60x18 strike, bool isCall) internal pure returns (KeyInternal memory) {
        return
            KeyInternal({
                owner: self.owner,
                operator: self.operator,
                lower: self.lower,
                upper: self.upper,
                orderType: self.orderType,
                strike: strike,
                isCall: isCall
            });
    }

    /// @notice Returns true if the position `orderType` is short
    function isShort(OrderType orderType) internal pure returns (bool) {
        return orderType == OrderType.CS || orderType == OrderType.CSUP;
    }

    /// @notice Returns true if the position `orderType` is long
    function isLong(OrderType orderType) internal pure returns (bool) {
        return orderType == OrderType.LC;
    }

    /// @notice Returns the percentage by which the market price has passed through the lower and upper prices
    ///         from left to right.
    ///         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ///         Usage:
    ///         CS order: f(x) defines the amount of shorts of a CS order holding one unit of liquidity.
    ///         LC order: (1 - f(x)) defines the amount of longs of a LC order holding one unit of liquidity.
    ///
    ///         Function definition:
    ///         case 1. f(x) = 0                                for x < lower
    ///         case 2. f(x) = (x - lower) / (upper - lower)    for lower <= x <= upper
    ///         case 3. f(x) = 1                                for x > upper
    ///         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function pieceWiseLinear(KeyInternal memory self, UD50x28 price) internal pure returns (UD50x28) {
        revertIfLowerGreaterOrEqualUpper(self.lower, self.upper);

        if (price <= self.lower.intoUD50x28()) return UD50_ZERO;
        else if (self.lower.intoUD50x28() < price && price < self.upper.intoUD50x28())
            return Pricing.proportion(self.lower, self.upper, price);
        else return UD50_ONE;
    }

    /// @notice Returns the amount of 'bid-side' collateral associated to a range order with one unit of liquidity.
    ///         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ///         Usage:
    ///         CS order: bid-side collateral defines the premiums generated from selling options.
    ///         LC order: bid-side collateral defines the collateral used to pay for buying long options.
    ///
    ///         Function definition:
    ///         case 1. f(x) = 0                                            for x < lower
    ///         case 2. f(x) = (price**2 - lower) / [2 * (upper - lower)]   for lower <= x <= upper
    ///         case 3. f(x) = (upper + lower) / 2                          for x > upper
    ///         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function pieceWiseQuadratic(KeyInternal memory self, UD50x28 price) internal pure returns (UD50x28) {
        revertIfLowerGreaterOrEqualUpper(self.lower, self.upper);

        UD50x28 lowerUD50 = self.lower.intoUD50x28();
        UD50x28 upperUD50 = self.upper.intoUD50x28();

        UD50x28 a;
        if (price <= lowerUD50) {
            return UD50_ZERO;
        } else if (lowerUD50 < price && price < upperUD50) {
            a = price;
        } else {
            a = upperUD50;
        }

        UD50x28 numerator = (a * a - lowerUD50 * lowerUD50);
        UD50x28 denominator = UD50_TWO * (upperUD50 - lowerUD50);

        return (numerator / denominator);
    }

    /// @notice Converts `_collateral` to the amount of contracts normalized to 18 decimals
    /// @param strike The strike price (18 decimals)
    function collateralToContracts(UD60x18 _collateral, UD60x18 strike, bool isCall) internal pure returns (UD60x18) {
        return isCall ? _collateral : _collateral / strike;
    }

    /// @notice Converts `_contracts` to the amount of collateral normalized to 18 decimals
    /// @dev WARNING: Decimals needs to be scaled before using this amount for collateral transfers
    /// @param strike The strike price (18 decimals)
    function contractsToCollateral(UD60x18 _contracts, UD60x18 strike, bool isCall) internal pure returns (UD60x18) {
        return isCall ? _contracts : _contracts * strike;
    }

    /// @notice Converts `_collateral` to the amount of contracts normalized to 28 decimals
    /// @param strike The strike price (18 decimals)
    function collateralToContracts(UD50x28 _collateral, UD60x18 strike, bool isCall) internal pure returns (UD50x28) {
        return isCall ? _collateral : _collateral / strike.intoUD50x28();
    }

    /// @notice Converts `_contracts` to the amount of collateral normalized to 28 decimals
    /// @dev WARNING: Decimals needs to be scaled before using this amount for collateral transfers
    /// @param strike The strike price (18 decimals)
    function contractsToCollateral(UD50x28 _contracts, UD60x18 strike, bool isCall) internal pure returns (UD50x28) {
        return isCall ? _contracts : _contracts * strike.intoUD50x28();
    }

    /// @notice Returns the per-tick liquidity phi (delta) for a specific position key `self`
    /// @param size The contract amount (18 decimals)
    function liquidityPerTick(KeyInternal memory self, UD60x18 size) internal pure returns (UD50x28) {
        UD60x18 amountOfTicks = Pricing.amountOfTicksBetween(self.lower, self.upper);

        return size.intoUD50x28() / amountOfTicks.intoUD50x28();
    }

    /// @notice Returns the bid collateral (18 decimals) either used to buy back options or revenue/ income generated
    ///         from underwriting / selling options.
    ///         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ///         For a <= p <= b we have:
    ///
    ///         bid(p; a, b) = [ (p - a) / (b - a) ] * [ (a + p)  / 2 ]
    ///                      = (p^2 - a^2) / [2 * (b - a)]
    ///         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    /// @param self The internal position key
    /// @param size The contract amount (18 decimals)
    /// @param price The current market price (28 decimals)
    function bid(KeyInternal memory self, UD60x18 size, UD50x28 price) internal pure returns (UD60x18) {
        return
            contractsToCollateral(pieceWiseQuadratic(self, price) * size.intoUD50x28(), self.strike, self.isCall)
                .intoUD60x18();
    }

    /// @notice Returns the total collateral (18 decimals) held by the position key `self`. Note that here we do not
    ///         distinguish between ask- and bid-side collateral. This increases the capital efficiency of the range order
    /// @param size The contract amount (18 decimals)
    /// @param price The current market price (28 decimals)
    function collateral(
        KeyInternal memory self,
        UD60x18 size,
        UD50x28 price
    ) internal pure returns (UD60x18 _collateral) {
        UD50x28 nu = pieceWiseLinear(self, price);

        if (self.orderType.isShort()) {
            _collateral = contractsToCollateral((UD50_ONE - nu) * size.intoUD50x28(), self.strike, self.isCall)
                .intoUD60x18();

            if (self.orderType == OrderType.CSUP) {
                _collateral = _collateral - (self.bid(size, self.upper.intoUD50x28()) - self.bid(size, price));
            } else {
                _collateral = _collateral + self.bid(size, price);
            }
        } else if (self.orderType.isLong()) {
            _collateral = self.bid(size, price);
        } else {
            revert IPosition.Position__InvalidOrderType();
        }
    }

    /// @notice Returns the total contracts (18 decimals) held by the position key `self`
    /// @param size The contract amount (18 decimals)
    /// @param price The current market price (28 decimals)
    function contracts(KeyInternal memory self, UD60x18 size, UD50x28 price) internal pure returns (UD60x18) {
        UD50x28 nu = pieceWiseLinear(self, price);

        if (self.orderType.isLong()) {
            return ((UD50_ONE - nu) * size.intoUD50x28()).intoUD60x18();
        }

        return (nu * size.intoUD50x28()).intoUD60x18();
    }

    /// @notice Returns the number of long contracts (18 decimals) held in position `self` at current price
    /// @param size The contract amount (18 decimals)
    /// @param price The current market price (28 decimals)
    function long(KeyInternal memory self, UD60x18 size, UD50x28 price) internal pure returns (UD60x18) {
        if (self.orderType.isShort()) {
            return ZERO;
        } else if (self.orderType.isLong()) {
            return self.contracts(size, price);
        } else {
            revert IPosition.Position__InvalidOrderType();
        }
    }

    /// @notice Returns the number of short contracts (18 decimals) held in position `self` at current price
    /// @param size The contract amount (18 decimals)
    /// @param price The current market price (28 decimals)
    function short(KeyInternal memory self, UD60x18 size, UD50x28 price) internal pure returns (UD60x18) {
        if (self.orderType.isShort()) {
            return self.contracts(size, price);
        } else if (self.orderType.isLong()) {
            return ZERO;
        } else {
            revert IPosition.Position__InvalidOrderType();
        }
    }

    /// @notice Calculate the update for the Position. Either increments them in case withdraw is False (i.e. in case
    ///         there is a deposit) and otherwise decreases them. Returns the change in collateral, longs, shorts. These
    ///         are transferred to (withdrawal)or transferred from (deposit) the Agent (Position.operator).
    /// @param currentBalance The current balance of tokens (18 decimals)
    /// @param amount The number of tokens deposited or withdrawn (18 decimals)
    /// @param price The current market price, used to compute the change in collateral, long and shorts due to the
    ///        change in tokens (28 decimals)
    /// @return delta Absolute change in collateral / longs / shorts due to change in tokens
    function calculatePositionUpdate(
        KeyInternal memory self,
        UD60x18 currentBalance,
        SD59x18 amount,
        UD50x28 price
    ) internal pure returns (Delta memory delta) {
        if (currentBalance.intoSD59x18() + amount < iZERO)
            revert IPosition.Position__InvalidPositionUpdate(currentBalance, amount);

        UD60x18 absChangeTokens = amount.abs().intoUD60x18();
        SD59x18 sign = amount > iZERO ? sd(1e18) : sd(-1e18);

        delta.collateral = sign * (self.collateral(absChangeTokens, price)).intoSD59x18();

        delta.longs = sign * (self.long(absChangeTokens, price)).intoSD59x18();
        delta.shorts = sign * (self.short(absChangeTokens, price)).intoSD59x18();
    }

    /// @notice Revert if `lower` is greater or equal to `upper`
    function revertIfLowerGreaterOrEqualUpper(UD60x18 lower, UD60x18 upper) internal pure {
        if (lower >= upper) revert IPosition.Position__LowerGreaterOrEqualUpper(lower, upper);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

interface IERC20Router {
    error ERC20Router__NotAuthorized();

    /// @notice Transfers tokens - caller must be an authorized pool
    /// @param token Address of token to transfer
    /// @param from Address to transfer tokens from
    /// @param to Address to transfer tokens to
    /// @param amount Amount of tokens to transfer
    function safeTransferFrom(address token, address from, address to, uint256 amount) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "@prb/math/UD60x18.sol";
import {SD59x18} from "@prb/math/SD59x18.sol";

import {IPosition} from "../libraries/IPosition.sol";
import {IPricing} from "../libraries/IPricing.sol";
import {UD50x28} from "../libraries/UD50x28.sol";
import {SD49x28} from "../libraries/SD49x28.sol";

import {IUserSettings} from "../settings/IUserSettings.sol";

interface IPoolInternal is IPosition, IPricing {
    error Pool__AboveQuoteSize(UD60x18 size, UD60x18 quoteSize);
    error Pool__AboveMaxSlippage(uint256 value, uint256 minimum, uint256 maximum);
    error Pool__ActionNotAuthorized(address user, address sender, IUserSettings.Action action);
    error Pool__AgentNotAuthorized();
    error Pool__CostExceedsPayout(UD60x18 cost, UD60x18 payout);
    error Pool__CostNotAuthorized(UD60x18 costInWrappedNative, UD60x18 authorizedCost);
    error Pool__FlashLoanCallbackFailed();
    error Pool__FlashLoanNotRepayed();
    error Pool__InsufficientAskLiquidity();
    error Pool__InsufficientBidLiquidity();
    error Pool__InsufficientFunds();
    error Pool__InsufficientLiquidity();
    error Pool__InvalidAssetUpdate(SD59x18 deltaLongs, SD59x18 deltaShorts);
    error Pool__InvalidBelowPrice(UD60x18 price, UD60x18 priceBelow);
    error Pool__InvalidMonth(uint256 month);
    error Pool__InvalidPositionState(uint256 balance, uint256 lastDeposit);
    error Pool__InvalidQuoteOBSignature();
    error Pool__InvalidQuoteOBTaker();
    error Pool__InvalidRange(UD60x18 lower, UD60x18 upper);
    error Pool__InvalidReconciliation(uint256 crossings);
    error Pool__InvalidSize(UD60x18 lower, UD60x18 upper, UD60x18 depositSize);
    error Pool__InvalidTickPrice();
    error Pool__InvalidTickUpdate();
    error Pool__InvalidTransfer();
    error Pool__NotEnoughTokens(UD60x18 balance, UD60x18 size);
    error Pool__NotPoolToken(address token);
    error Pool__NotWrappedNativeTokenPool();
    error Pool__OperatorNotAuthorized(address sender);
    error Pool__OptionExpired();
    error Pool__OptionNotExpired();
    error Pool__OutOfBoundsPrice(UD60x18 price);
    error Pool__PositionDoesNotExist(address owner, uint256 tokenId);
    error Pool__PositionCantHoldLongAndShort(UD60x18 longs, UD60x18 shorts);
    error Pool__QuoteOBCancelled();
    error Pool__QuoteOBExpired();
    error Pool__QuoteOBOverfilled(UD60x18 filledAmount, UD60x18 size, UD60x18 quoteOBSize);
    error Pool__SettlementFailed();
    error Pool__SettlementPriceAlreadyCached();
    error Pool__TickDeltaNotZero(SD59x18 tickDelta);
    error Pool__TickNotFound(UD60x18 price);
    error Pool__TickOutOfRange(UD60x18 price);
    error Pool__TickWidthInvalid(UD60x18 price);
    error Pool__WithdrawalDelayNotElapsed(uint256 unlockTime);
    error Pool__ZeroSize();

    struct Tick {
        SD49x28 delta;
        UD50x28 externalFeeRate;
        SD49x28 longDelta;
        SD49x28 shortDelta;
        uint256 counter;
    }

    struct TickWithRates {
        Tick tick;
        UD60x18 price;
        UD50x28 longRate;
        UD50x28 shortRate;
    }

    struct QuoteOB {
        // The provider of the OB quote
        address provider;
        // The taker of the OB quote (address(0) if OB quote should be usable by anyone)
        address taker;
        // The normalized option price (18 decimals)
        UD60x18 price;
        // The max size (18 decimals)
        UD60x18 size;
        // Whether provider is buying or selling
        bool isBuy;
        // Timestamp until which the OB quote is valid
        uint256 deadline;
        // Salt to make OB quote unique
        uint256 salt;
    }

    enum InvalidQuoteOBError {
        None,
        QuoteOBExpired,
        QuoteOBCancelled,
        QuoteOBOverfilled,
        OutOfBoundsPrice,
        InvalidQuoteOBTaker,
        InvalidQuoteOBSignature,
        InvalidAssetUpdate,
        InsufficientCollateralAllowance,
        InsufficientCollateralBalance,
        InsufficientLongBalance,
        InsufficientShortBalance
    }

    ////////////////////
    ////////////////////
    // The structs below are used as a way to reduce stack depth and avoid "stack too deep" errors

    struct TradeArgsInternal {
        // The account doing the trade
        address user;
        // The referrer of the user doing the trade
        address referrer;
        // The number of contracts being traded (18 decimals)
        UD60x18 size;
        // Whether the taker is buying or selling
        bool isBuy;
        // Tx will revert if total premium is above this value when buying, or below this value when selling.
        // (poolToken decimals)
        uint256 premiumLimit;
        // Whether to transfer collateral to user or not if collateral value is positive. Should be false if that
        // collateral is used for a swap
        bool transferCollateralToUser;
    }

    struct ReferralVarsInternal {
        UD60x18 totalRebate;
        UD60x18 primaryRebate;
        UD60x18 secondaryRebate;
    }

    struct TradeVarsInternal {
        UD60x18 maxSize;
        UD60x18 tradeSize;
        UD50x28 oldMarketPrice;
        UD60x18 totalPremium;
        UD60x18 totalTakerFees;
        UD60x18 totalProtocolFees;
        UD50x28 longDelta;
        UD50x28 shortDelta;
        ReferralVarsInternal referral;
    }

    struct DepositArgsInternal {
        // The normalized price of nearest existing tick below lower. The search is done off-chain, passed as arg and
        // validated on-chain to save gas (18 decimals)
        UD60x18 belowLower;
        // The normalized price of nearest existing tick below upper. The search is done off-chain, passed as arg and
        // validated on-chain to save gas (18 decimals)
        UD60x18 belowUpper;
        // The position size to deposit (18 decimals)
        UD60x18 size;
        // minMarketPrice Min market price, as normalized value. (If below, tx will revert) (18 decimals)
        UD60x18 minMarketPrice;
        // maxMarketPrice Max market price, as normalized value. (If above, tx will revert) (18 decimals)
        UD60x18 maxMarketPrice;
    }

    struct WithdrawVarsInternal {
        bytes32 pKeyHash;
        uint256 tokenId;
        UD60x18 initialSize;
        UD50x28 liquidityPerTick;
        bool isFullWithdrawal;
        SD49x28 tickDelta;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct FillQuoteOBArgsInternal {
        // The user filling the OB quote
        address user;
        // The referrer of the user filling the OB quote
        address referrer;
        // The size to fill from the OB quote (18 decimals)
        UD60x18 size;
        // secp256k1 'r', 's', and 'v' value
        Signature signature;
        // Whether to transfer collateral to user or not if collateral value is positive. Should be false if that
        // collateral is used for a swap
        bool transferCollateralToUser;
    }

    struct PremiumAndFeeInternal {
        UD60x18 totalReferralRebate;
        UD60x18 premium;
        UD60x18 protocolFee;
        UD60x18 premiumTaker;
        UD60x18 premiumMaker;
        ReferralVarsInternal referral;
    }

    struct QuoteAMMVarsInternal {
        UD60x18 liquidity;
        UD60x18 maxSize;
        UD60x18 totalPremium;
        UD60x18 totalTakerFee;
    }

    struct SettlePositionVarsInternal {
        bytes32 pKeyHash;
        uint256 tokenId;
        UD60x18 size;
        UD60x18 claimableFees;
        UD60x18 payoff;
        UD60x18 collateral;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC20 metadata internal interface
 */
interface IERC20MetadataInternal {

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "../Common.sol" as Common;
import "./Errors.sol" as CastingErrors;
import { SD59x18 } from "../sd59x18/ValueType.sol";
import { UD2x18 } from "../ud2x18/ValueType.sol";
import { UD60x18 } from "../ud60x18/ValueType.sol";
import { SD1x18 } from "./ValueType.sol";

/// @notice Casts an SD1x18 number into SD59x18.
/// @dev There is no overflow check because the domain of SD1x18 is a subset of SD59x18.
function intoSD59x18(SD1x18 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(int256(SD1x18.unwrap(x)));
}

/// @notice Casts an SD1x18 number into UD2x18.
/// - x must be positive.
function intoUD2x18(SD1x18 x) pure returns (UD2x18 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD1x18_ToUD2x18_Underflow(x);
    }
    result = UD2x18.wrap(uint64(xInt));
}

/// @notice Casts an SD1x18 number into UD60x18.
/// @dev Requirements:
/// - x must be positive.
function intoUD60x18(SD1x18 x) pure returns (UD60x18 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD1x18_ToUD60x18_Underflow(x);
    }
    result = UD60x18.wrap(uint64(xInt));
}

/// @notice Casts an SD1x18 number into uint256.
/// @dev Requirements:
/// - x must be positive.
function intoUint256(SD1x18 x) pure returns (uint256 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD1x18_ToUint256_Underflow(x);
    }
    result = uint256(uint64(xInt));
}

/// @notice Casts an SD1x18 number into uint128.
/// @dev Requirements:
/// - x must be positive.
function intoUint128(SD1x18 x) pure returns (uint128 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD1x18_ToUint128_Underflow(x);
    }
    result = uint128(uint64(xInt));
}

/// @notice Casts an SD1x18 number into uint40.
/// @dev Requirements:
/// - x must be positive.
/// - x must be less than or equal to `MAX_UINT40`.
function intoUint40(SD1x18 x) pure returns (uint40 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD1x18_ToUint40_Underflow(x);
    }
    if (xInt > int64(uint64(Common.MAX_UINT40))) {
        revert CastingErrors.PRBMath_SD1x18_ToUint40_Overflow(x);
    }
    result = uint40(uint64(xInt));
}

/// @notice Alias for {wrap}.
function sd1x18(int64 x) pure returns (SD1x18 result) {
    result = SD1x18.wrap(x);
}

/// @notice Unwraps an SD1x18 number into int64.
function unwrap(SD1x18 x) pure returns (int64 result) {
    result = SD1x18.unwrap(x);
}

/// @notice Wraps an int64 number into SD1x18.
function wrap(int64 x) pure returns (SD1x18 result) {
    result = SD1x18.wrap(x);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "../Common.sol" as Common;
import "./Errors.sol" as Errors;
import { uMAX_SD1x18 } from "../sd1x18/Constants.sol";
import { SD1x18 } from "../sd1x18/ValueType.sol";
import { SD59x18 } from "../sd59x18/ValueType.sol";
import { UD2x18 } from "../ud2x18/ValueType.sol";
import { UD60x18 } from "../ud60x18/ValueType.sol";
import { UD2x18 } from "./ValueType.sol";

/// @notice Casts a UD2x18 number into SD1x18.
/// - x must be less than or equal to `uMAX_SD1x18`.
function intoSD1x18(UD2x18 x) pure returns (SD1x18 result) {
    uint64 xUint = UD2x18.unwrap(x);
    if (xUint > uint64(uMAX_SD1x18)) {
        revert Errors.PRBMath_UD2x18_IntoSD1x18_Overflow(x);
    }
    result = SD1x18.wrap(int64(xUint));
}

/// @notice Casts a UD2x18 number into SD59x18.
/// @dev There is no overflow check because the domain of UD2x18 is a subset of SD59x18.
function intoSD59x18(UD2x18 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(int256(uint256(UD2x18.unwrap(x))));
}

/// @notice Casts a UD2x18 number into UD60x18.
/// @dev There is no overflow check because the domain of UD2x18 is a subset of UD60x18.
function intoUD60x18(UD2x18 x) pure returns (UD60x18 result) {
    result = UD60x18.wrap(UD2x18.unwrap(x));
}

/// @notice Casts a UD2x18 number into uint128.
/// @dev There is no overflow check because the domain of UD2x18 is a subset of uint128.
function intoUint128(UD2x18 x) pure returns (uint128 result) {
    result = uint128(UD2x18.unwrap(x));
}

/// @notice Casts a UD2x18 number into uint256.
/// @dev There is no overflow check because the domain of UD2x18 is a subset of uint256.
function intoUint256(UD2x18 x) pure returns (uint256 result) {
    result = uint256(UD2x18.unwrap(x));
}

/// @notice Casts a UD2x18 number into uint40.
/// @dev Requirements:
/// - x must be less than or equal to `MAX_UINT40`.
function intoUint40(UD2x18 x) pure returns (uint40 result) {
    uint64 xUint = UD2x18.unwrap(x);
    if (xUint > uint64(Common.MAX_UINT40)) {
        revert Errors.PRBMath_UD2x18_IntoUint40_Overflow(x);
    }
    result = uint40(xUint);
}

/// @notice Alias for {wrap}.
function ud2x18(uint64 x) pure returns (UD2x18 result) {
    result = UD2x18.wrap(x);
}

/// @notice Unwrap a UD2x18 number into uint64.
function unwrap(UD2x18 x) pure returns (uint64 result) {
    result = UD2x18.unwrap(x);
}

/// @notice Wraps a uint64 number into UD2x18.
function wrap(uint64 x) pure returns (UD2x18 result) {
    result = UD2x18.wrap(x);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library Math {
    /**
     * @notice calculate the absolute value of a number
     * @param a number whose absoluve value to calculate
     * @return absolute value
     */
    function abs(int256 a) internal pure returns (uint256) {
        return uint256(a < 0 ? -a : a);
    }

    /**
     * @notice select the greater of two numbers
     * @param a first number
     * @param b second number
     * @return greater number
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @notice select the lesser of two numbers
     * @param a first number
     * @param b second number
     * @return lesser number
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? b : a;
    }

    /**
     * @notice calculate the average of two numbers, rounded down
     * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
     * @param a first number
     * @param b second number
     * @return mean value
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return (a & b) + ((a ^ b) >> 1);
        }
    }

    /**
     * @notice estimate square root of number
     * @dev uses Babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
     * @param x input number
     * @return y square root
     */
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) >> 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) >> 1;
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {SD59x18} from "@prb/math/SD59x18.sol";
import {UD60x18} from "@prb/math/UD60x18.sol";

interface IPosition {
    error Position__InvalidOrderType();
    error Position__InvalidPositionUpdate(UD60x18 currentBalance, SD59x18 amount);
    error Position__LowerGreaterOrEqualUpper(UD60x18 lower, UD60x18 upper);
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "@prb/math/UD60x18.sol";

import {DoublyLinkedListUD60x18, DoublyLinkedList} from "../libraries/DoublyLinkedListUD60x18.sol";
import {UD50x28} from "../libraries/UD50x28.sol";
import {PoolStorage} from "../pool/PoolStorage.sol";
import {PRBMathExtra} from "./PRBMathExtra.sol";

import {IPricing} from "./IPricing.sol";

import {ZERO, UD50_ONE} from "./Constants.sol";

/// @notice This library implements the functions necessary for computing price movements within a tick range.
/// @dev WARNING: This library should not be used for computations that span multiple ticks. Instead, the user should
///      use the functions of this library to simplify computations for more complex price calculations.
library Pricing {
    using DoublyLinkedListUD60x18 for DoublyLinkedList.Bytes32List;
    using PoolStorage for PoolStorage.Layout;
    using PRBMathExtra for UD60x18;
    using PRBMathExtra for UD50x28;

    struct Args {
        UD50x28 liquidityRate; // Amount of liquidity (28 decimals)
        UD50x28 marketPrice; // The current market price (28 decimals)
        UD60x18 lower; // The normalized price of the lower bound of the range (18 decimals)
        UD60x18 upper; // The normalized price of the upper bound of the range (18 decimals)
        bool isBuy; // The direction of the trade
    }

    /// @notice Returns the percentage by which the market price has passed through the lower and upper prices
    ///         from left to right. Reverts if the market price is not within the range of the lower and upper prices.
    function proportion(UD60x18 lower, UD60x18 upper, UD50x28 marketPrice) internal pure returns (UD50x28) {
        UD60x18 marketPriceUD60 = marketPrice.intoUD60x18();
        if (lower >= upper) revert IPricing.Pricing__UpperNotGreaterThanLower(lower, upper);
        if (lower > marketPriceUD60 || marketPriceUD60 > upper)
            revert IPricing.Pricing__PriceOutOfRange(lower, upper, marketPriceUD60);

        return (marketPrice - lower.intoUD50x28()) / (upper - lower).intoUD50x28();
    }

    /// @notice Returns the percentage by which the market price has passed through the lower and upper prices
    ///         from left to right. Reverts if the market price is not within the range of the lower and upper prices.
    function proportion(Args memory args) internal pure returns (UD50x28) {
        return proportion(args.lower, args.upper, args.marketPrice);
    }

    /// @notice Find the number of ticks of an active tick range. Used to compute the aggregate, bid or ask liquidity
    ///         either of the pool or the range order.
    ///         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ///         min_tick_distance = 0.01
    ///         lower = 0.01
    ///         upper = 0.03
    ///         num_ticks = 2
    ///
    ///         0.01               0.02               0.03
    ///          |xxxxxxxxxxxxxxxxxx|xxxxxxxxxxxxxxxxxx|
    ///
    ///         Then there are two active ticks, 0.01 and 0.02, within the active tick range.
    ///         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function amountOfTicksBetween(UD60x18 lower, UD60x18 upper) internal pure returns (UD60x18) {
        if (lower >= upper) revert IPricing.Pricing__UpperNotGreaterThanLower(lower, upper);

        return (upper - lower) / PoolStorage.MIN_TICK_DISTANCE;
    }

    /// @notice Returns the number of ticks between `args.lower` and `args.upper`
    function amountOfTicksBetween(Args memory args) internal pure returns (UD60x18) {
        return amountOfTicksBetween(args.lower, args.upper);
    }

    /// @notice Returns the liquidity between `args.lower` and `args.upper`
    function liquidity(Args memory args) internal pure returns (UD60x18) {
        return (args.liquidityRate * amountOfTicksBetween(args).intoUD50x28()).intoUD60x18();
    }

    /// @notice Returns the bid-side liquidity between `args.lower` and `args.upper`
    function bidLiquidity(Args memory args) internal pure returns (UD60x18) {
        return (proportion(args) * liquidity(args).intoUD50x28()).roundToNearestUD60x18();
    }

    /// @notice Returns the ask-side liquidity between `args.lower` and `args.upper`
    function askLiquidity(Args memory args) internal pure returns (UD60x18) {
        return ((UD50_ONE - proportion(args)) * liquidity(args).intoUD50x28()).roundToNearestUD60x18();
    }

    /// @notice Returns the maximum trade size (askLiquidity or bidLiquidity depending on the TradeSide).
    function maxTradeSize(Args memory args) internal pure returns (UD60x18) {
        return args.isBuy ? askLiquidity(args) : bidLiquidity(args);
    }

    /// @notice Computes price reached from the current lower/upper tick after buying/selling `trade_size` amount of
    ///         contracts
    function price(Args memory args, UD60x18 tradeSize) internal pure returns (UD50x28) {
        UD60x18 liq = liquidity(args);
        if (liq == ZERO) return (args.isBuy ? args.upper : args.lower).intoUD50x28();

        UD50x28 _proportion;
        if (tradeSize > ZERO) _proportion = tradeSize.intoUD50x28() / liq.intoUD50x28();

        if (_proportion > UD50_ONE) revert IPricing.Pricing__PriceCannotBeComputedWithinTickRange();

        return
            args.isBuy
                ? args.lower.intoUD50x28() + (args.upper - args.lower).intoUD50x28() * _proportion
                : args.upper.intoUD50x28() - (args.upper - args.lower).intoUD50x28() * _proportion;
    }

    /// @notice Gets the next market price within a tick range after buying/selling `tradeSize` amount of contracts
    function nextPrice(Args memory args, UD60x18 tradeSize) internal pure returns (UD50x28) {
        UD60x18 offset = args.isBuy ? bidLiquidity(args) : askLiquidity(args);
        return price(args, offset + tradeSize);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {UD60x18, ud} from "@prb/math/UD60x18.sol";
import {SD59x18} from "@prb/math/SD59x18.sol";

import {UD50x28, uMAX_UD50x28, ud50x28} from "./UD50x28.sol";
import {SD49x28, uMAX_SD49x28} from "./SD49x28.sol";

import {iZERO, SD49_ZERO} from "./Constants.sol";

library PRBMathExtra {
    error SD59x18_IntoSD49x28_Overflow(SD59x18 x);
    error UD60x18_IntoUD50x28_Overflow(UD60x18 x);

    function intoSD49x28(SD59x18 x) internal pure returns (SD49x28 result) {
        int256 xUint = x.unwrap() * int256(1e10); // Scaling factor = 10 ** (28 - 18)
        if (xUint > uMAX_SD49x28) revert SD59x18_IntoSD49x28_Overflow(x);
        result = SD49x28.wrap(xUint);
    }

    function intoUD50x28(UD60x18 x) internal pure returns (UD50x28 result) {
        uint256 xUint = x.unwrap() * 1e10; // Scaling factor = 10 ** (28 - 18)
        if (xUint > uMAX_UD50x28) revert UD60x18_IntoUD50x28_Overflow(x);
        result = UD50x28.wrap(xUint);
    }

    //

    /// @notice Returns the greater of two numbers `a` and `b`
    function max(UD60x18 a, UD60x18 b) internal pure returns (UD60x18) {
        return a > b ? a : b;
    }

    /// @notice Returns the lesser of two numbers `a` and `b`
    function min(UD60x18 a, UD60x18 b) internal pure returns (UD60x18) {
        return a > b ? b : a;
    }

    /// @notice Returns the greater of two numbers `a` and `b`
    function max(SD59x18 a, SD59x18 b) internal pure returns (SD59x18) {
        return a > b ? a : b;
    }

    /// @notice Returns the lesser of two numbers `a` and `b`
    function min(SD59x18 a, SD59x18 b) internal pure returns (SD59x18) {
        return a > b ? b : a;
    }

    /// @notice Returns the sum of `a` and `b`
    function add(UD60x18 a, SD59x18 b) internal pure returns (UD60x18) {
        return b < iZERO ? sub(a, -b) : a + b.intoUD60x18();
    }

    /// @notice Returns the difference of `a` and `b`
    function sub(UD60x18 a, SD59x18 b) internal pure returns (UD60x18) {
        return b < iZERO ? add(a, -b) : a - b.intoUD60x18();
    }

    ////////////////////////

    /// @notice Returns the greater of two numbers `a` and `b`
    function max(UD50x28 a, UD50x28 b) internal pure returns (UD50x28) {
        return a > b ? a : b;
    }

    /// @notice Returns the lesser of two numbers `a` and `b`
    function min(UD50x28 a, UD50x28 b) internal pure returns (UD50x28) {
        return a > b ? b : a;
    }

    /// @notice Returns the greater of two numbers `a` and `b`
    function max(SD49x28 a, SD49x28 b) internal pure returns (SD49x28) {
        return a > b ? a : b;
    }

    /// @notice Returns the lesser of two numbers `a` and `b`
    function min(SD49x28 a, SD49x28 b) internal pure returns (SD49x28) {
        return a > b ? b : a;
    }

    /// @notice Returns the sum of `a` and `b`
    function add(UD50x28 a, SD49x28 b) internal pure returns (UD50x28) {
        return b < SD49_ZERO ? sub(a, -b) : a + b.intoUD50x28();
    }

    /// @notice Returns the difference of `a` and `b`
    function sub(UD50x28 a, SD49x28 b) internal pure returns (UD50x28) {
        return b < SD49_ZERO ? add(a, -b) : a - b.intoUD50x28();
    }

    ////////////////////////

    /// @notice Rounds an `UD50x28` to the nearest `UD60x18`
    function roundToNearestUD60x18(UD50x28 value) internal pure returns (UD60x18 result) {
        // Rounded down by default
        result = value.intoUD60x18();

        // (10 ** (28 - 18)) / 2 = 5e9
        if (value - intoUD50x28(result) >= ud50x28(5e9)) {
            // Round up
            result = result + ud(1);
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "@prb/math/UD60x18.sol";

interface IPricing {
    error Pricing__PriceCannotBeComputedWithinTickRange();
    error Pricing__PriceOutOfRange(UD60x18 lower, UD60x18 upper, UD60x18 marketPrice);
    error Pricing__UpperNotGreaterThanLower(UD60x18 lower, UD60x18 upper);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18} from "@prb/math/UD60x18.sol";
import {IMulticall} from "@solidstate/contracts/utils/IMulticall.sol";

interface IUserSettings is IMulticall {
    /// @notice Enumeration representing different actions which `user` may authorize an `operator` to perform
    enum Action {
        __, // intentionally left blank to prevent 0 from being a valid action
        Annihilate,
        Exercise,
        Settle,
        SettlePosition,
        WriteFrom
    }

    error UserSettings__InvalidAction();
    error UserSettings__InvalidArrayLength();

    event ActionAuthorizationUpdated(
        address indexed user,
        address indexed operator,
        Action[] actions,
        bool[] authorization
    );

    event AuthorizedCostUpdated(address indexed user, UD60x18 amount);

    /// @notice Returns true if `operator` is authorized to perform `action` for `user`
    /// @param user The user who grants authorization
    /// @param operator The operator who is granted authorization
    /// @param action The action `operator` is authorized to perform
    /// @return True if `operator` is authorized to perform `action` for `user`
    function isActionAuthorized(address user, address operator, Action action) external view returns (bool);

    /// @notice Returns the actions and their corresponding authorization states. If the state of an action is true,
    ////        `operator` has been granted authorization by `user` to perform the action on their behalf. Note, the 0th
    ///         indexed enum in Action is omitted from `actions`.
    /// @param user The user who grants authorization
    /// @param operator The operator who is granted authorization
    /// @return actions All available actions a `user` may grant authorization to `operator` for
    /// @return authorization The authorization states of each `action`
    function getActionAuthorization(
        address user,
        address operator
    ) external view returns (Action[] memory actions, bool[] memory authorization);

    /// @notice Sets the authorization state for each action an `operator` may perform on behalf of `user`. `actions`
    ///         must be indexed in the same order as their corresponding `authorization` state.
    /// @param operator The operator who is granted authorization
    /// @param actions The actions to modify authorization state for
    /// @param authorization The authorization states to set for each action
    function setActionAuthorization(address operator, Action[] memory actions, bool[] memory authorization) external;

    /// @notice Returns the users authorized cost in the ERC20 Native token (WETH, WFTM, etc) used in conjunction with
    ///         `exerciseFor`, settleFor`, and `settlePositionFor`
    /// @return The users authorized cost in the ERC20 Native token (WETH, WFTM, etc) (18 decimals)
    function getAuthorizedCost(address user) external view returns (UD60x18);

    /// @notice Sets the users authorized cost in the ERC20 Native token (WETH, WFTM, etc) used in conjunction with
    ///         `exerciseFor`, `settleFor`, and `settlePositionFor`
    /// @param amount The users authorized cost in the ERC20 Native token (WETH, WFTM, etc) (18 decimals)
    function setAuthorizedCost(UD60x18 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { SD1x18 } from "./ValueType.sol";

/// @notice Thrown when trying to cast a SD1x18 number that doesn't fit in UD2x18.
error PRBMath_SD1x18_ToUD2x18_Underflow(SD1x18 x);

/// @notice Thrown when trying to cast a SD1x18 number that doesn't fit in UD60x18.
error PRBMath_SD1x18_ToUD60x18_Underflow(SD1x18 x);

/// @notice Thrown when trying to cast a SD1x18 number that doesn't fit in uint128.
error PRBMath_SD1x18_ToUint128_Underflow(SD1x18 x);

/// @notice Thrown when trying to cast a SD1x18 number that doesn't fit in uint256.
error PRBMath_SD1x18_ToUint256_Underflow(SD1x18 x);

/// @notice Thrown when trying to cast a SD1x18 number that doesn't fit in uint40.
error PRBMath_SD1x18_ToUint40_Overflow(SD1x18 x);

/// @notice Thrown when trying to cast a SD1x18 number that doesn't fit in uint40.
error PRBMath_SD1x18_ToUint40_Underflow(SD1x18 x);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { UD2x18 } from "./ValueType.sol";

/// @notice Thrown when trying to cast a UD2x18 number that doesn't fit in SD1x18.
error PRBMath_UD2x18_IntoSD1x18_Overflow(UD2x18 x);

/// @notice Thrown when trying to cast a UD2x18 number that doesn't fit in uint40.
error PRBMath_UD2x18_IntoUint40_Overflow(UD2x18 x);

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {UD60x18, ud} from "@prb/math/UD60x18.sol";

import {DoublyLinkedList} from "@solidstate/contracts/data/DoublyLinkedList.sol";

library DoublyLinkedListUD60x18 {
    using DoublyLinkedList for DoublyLinkedList.Bytes32List;

    /// @notice Returns true if the doubly linked list `self` contains the `value`
    function contains(DoublyLinkedList.Bytes32List storage self, UD60x18 value) internal view returns (bool) {
        return self.contains(bytes32(value.unwrap()));
    }

    /// @notice Returns the stored element before `value` in the doubly linked list `self`
    function prev(DoublyLinkedList.Bytes32List storage self, UD60x18 value) internal view returns (UD60x18) {
        return ud(uint256(self.prev(bytes32(value.unwrap()))));
    }

    /// @notice Returns the stored element after `value` in the doubly linked list `self`
    function next(DoublyLinkedList.Bytes32List storage self, UD60x18 value) internal view returns (UD60x18) {
        return ud(uint256(self.next(bytes32(value.unwrap()))));
    }

    /// @notice Returns true if `newValue` was successfully inserted before `nextValue` in the doubly linked list `self`
    function insertBefore(
        DoublyLinkedList.Bytes32List storage self,
        UD60x18 nextValue,
        UD60x18 newValue
    ) internal returns (bool status) {
        status = self.insertBefore(bytes32(nextValue.unwrap()), bytes32(newValue.unwrap()));
    }

    /// @notice Returns true if `newValue` was successfully inserted after `prevValue` in the doubly linked list `self`
    function insertAfter(
        DoublyLinkedList.Bytes32List storage self,
        UD60x18 prevValue,
        UD60x18 newValue
    ) internal returns (bool status) {
        status = self.insertAfter(bytes32(prevValue.unwrap()), bytes32(newValue.unwrap()));
    }

    /// @notice Returns true if `value` was successfully inserted at the end of the doubly linked list `self`
    function push(DoublyLinkedList.Bytes32List storage self, UD60x18 value) internal returns (bool status) {
        status = self.push(bytes32(value.unwrap()));
    }

    /// @notice Removes the first element in the doubly linked list `self`, returns the removed element `value`
    function pop(DoublyLinkedList.Bytes32List storage self) internal returns (UD60x18 value) {
        value = ud(uint256(self.pop()));
    }

    /// @notice Removes the last element in the doubly linked list `self`, returns the removed element `value`
    function shift(DoublyLinkedList.Bytes32List storage self) internal returns (UD60x18 value) {
        value = ud(uint256(self.shift()));
    }

    /// @notice Returns true if `value` was successfully inserted at the front of the doubly linked list `self`
    function unshift(DoublyLinkedList.Bytes32List storage self, UD60x18 value) internal returns (bool status) {
        status = self.unshift(bytes32(value.unwrap()));
    }

    /// @notice Returns true if `value` was successfully removed from the doubly linked list `self`
    function remove(DoublyLinkedList.Bytes32List storage self, UD60x18 value) internal returns (bool status) {
        status = self.remove(bytes32(value.unwrap()));
    }

    /// @notice Returns true if `oldValue` was successfully replaced with `newValue` in the doubly linked list `self`
    function replace(
        DoublyLinkedList.Bytes32List storage self,
        UD60x18 oldValue,
        UD60x18 newValue
    ) internal returns (bool status) {
        status = self.replace(bytes32(oldValue.unwrap()), bytes32(newValue.unwrap()));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Interface for the Multicall utility contract
 */
interface IMulticall {
    /**
     * @notice batch function calls to the contract and return the results of each
     * @param data array of function call data payloads
     * @return results array of function call results
     */
    function multicall(
        bytes[] calldata data
    ) external returns (bytes[] memory results);
}