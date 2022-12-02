/*

    Copyright 2022 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IDolomiteMargin } from "../../protocol/interfaces/IDolomiteMargin.sol";

import { Account } from "../../protocol/lib/Account.sol";
import { Actions } from "../../protocol/lib/Actions.sol";
import { Decimal } from "../../protocol/lib/Decimal.sol";
import { Interest } from "../../protocol/lib/Interest.sol";
import { DolomiteMarginMath } from "../../protocol/lib/DolomiteMarginMath.sol";
import { Monetary } from "../../protocol/lib/Monetary.sol";
import { Require } from "../../protocol/lib/Require.sol";
import { Time } from "../../protocol/lib/Time.sol";
import { Types } from "../../protocol/lib/Types.sol";

import { AccountActionHelper } from "../helpers/AccountActionHelper.sol";
import { LiquidatorProxyHelper } from "../helpers/LiquidatorProxyHelper.sol";
import { IExpiry } from "../interfaces/IExpiry.sol";

import { DolomiteAmmRouterProxy } from "./DolomiteAmmRouterProxy.sol";


/**
 * @title LiquidatorProxyV1WithAmm
 * @author Dolomite
 *
 * Contract for liquidating other accounts in DolomiteMargin and atomically selling off collateral via Dolomite AMM
 * markets.
 */
contract LiquidatorProxyV1WithAmm is ReentrancyGuard, LiquidatorProxyHelper {
    using DolomiteMarginMath for uint256;
    using SafeMath for uint256;
    using Types for Types.Par;
    using Types for Types.Wei;

    // ============ Constants ============

    bytes32 constant FILE = "LiquidatorProxyV1WithAmm";

    // ============ Events ============

    /**
     * @param solidAccountOwner         The liquidator's address
     * @param solidAccountOwner         The liquidator's account number
     * @param heldMarket                The held market (collateral) that will be received by the liquidator
     * @param heldDeltaWeiWithReward    The amount of heldMarket the liquidator will receive, including the reward
     *                                  (positive number)
     * @param profitHeldWei             The amount of profit the liquidator will realize by performing the liquidation
     *                                  and atomically selling off the collateral. Can be negative or positive.
     * @param owedMarket                The debt market that will be received by the liquidator
     * @param owedDeltaWei              The amount of owedMarket that will be received by the liquidator (negative
     *                                  number)
     */
    event LogLiquidateWithAmm(
        address indexed solidAccountOwner,
        uint256 solidAccountNumber,
        uint256 heldMarket,
        uint256 heldDeltaWeiWithReward,
        Types.Wei profitHeldWei, // calculated as `heldWeiWithReward - soldHeldWeiToBreakEven`
        uint256 owedMarket,
        uint256 owedDeltaWei
    );

    // ============ Storage ============

    IDolomiteMargin DOLOMITE_MARGIN;
    DolomiteAmmRouterProxy ROUTER_PROXY;
    IExpiry EXPIRY_PROXY;

    // ============ Constructor ============

    constructor (
        address dolomiteMargin,
        address dolomiteAmmRouterProxy,
        address expiryProxy
    )
    public
    {
        DOLOMITE_MARGIN = IDolomiteMargin(dolomiteMargin);
        ROUTER_PROXY = DolomiteAmmRouterProxy(dolomiteAmmRouterProxy);
        EXPIRY_PROXY = IExpiry(expiryProxy);
    }

    // ============ Public Functions ============

    /**
     * Liquidate liquidAccount using solidAccount. This contract and the msg.sender to this contract
     * must both be operators for the solidAccount.
     *
     * @param _solidAccount                 The account that will do the liquidating
     * @param _liquidAccount                The account that will be liquidated
     * @param _owedMarket                   The owed market whose borrowed value will be added to `owedWeiToLiquidate`
     * @param _heldMarket                   The held market whose collateral will be recovered to take on the debt of
     *                                      `owedMarket`
     * @param _tokenPath                    The path through which the trade will be routed to recover the collateral
     * @param _expiry                       The time at which the position expires, if this liquidation is for closing
     *                                      an expired position. Else, 0.
     * @param _minOwedOutputAmount          The minimum amount that should be outputted by the trade from heldWei to
     *                                      owedWei. Used to prevent sandwiching and mem-pool other attacks. Only used
     *                                      if `revertOnFailToSellCollateral` is set to `false` and the collateral
     *                                      cannot cover the `liquidAccount`'s debt.
     * @param _revertOnFailToSellCollateral True to revert the transaction completely if all collateral from the
     *                                      liquidation cannot repay the owed debt. False to swallow the error and sell
     *                                      whatever is possible. If set to false, the liquidator must have sufficient
     *                                      assets to be prevent becoming liquidated or under-collateralized.
     */
    function liquidate(
        Account.Info memory _solidAccount,
        Account.Info memory _liquidAccount,
        uint256 _owedMarket,
        uint256 _heldMarket,
        address[] memory _tokenPath,
        uint256 _expiry,
        uint256 _minOwedOutputAmount,
        bool _revertOnFailToSellCollateral
    )
    public
    nonReentrant
    {
        // put all values that will not change into a single struct
        Constants memory constants;
        constants.dolomiteMargin = DOLOMITE_MARGIN;
        _checkConstants(
            constants,
            _liquidAccount,
            _owedMarket,
            _heldMarket,
            _expiry
        );

        constants.solidAccount = _solidAccount;
        constants.liquidAccount = _liquidAccount;
        constants.liquidMarkets = constants.dolomiteMargin.getAccountMarketsWithBalances(_liquidAccount);
        constants.markets = _getMarketInfos(
            constants.dolomiteMargin,
            constants.dolomiteMargin.getAccountMarketsWithBalances(_solidAccount),
            constants.liquidMarkets
        );
        constants.expiryProxy = _expiry > 0 ? EXPIRY_PROXY: IExpiry(address(0));
        constants.expiry = uint32(_expiry);

        LiquidatorProxyCache memory cache = _initializeCache(
            constants,
            _heldMarket,
            _owedMarket
        );

        // validate the msg.sender and that the liquidAccount can be liquidated
        _checkRequirements(
            constants,
            _heldMarket,
            _owedMarket,
            _tokenPath
        );

        // get the max liquidation amount
        _calculateAndSetMaxLiquidationAmount(cache);

        uint256 totalSolidHeldWei = cache.solidHeldUpdateWithReward;
        if (cache.solidHeldWei.sign) {
            // If the solid account has held wei, add the amount the solid account will receive from liquidation to its
            // total held wei
            // We do this so we can accurately track how much the solid account has (and will have after the swap), in
            // case we need to input it exactly to Router#getParamsForSwapExactTokensForTokens
            totalSolidHeldWei = totalSolidHeldWei.add(cache.solidHeldWei.value);
        }

        (
            Account.Info[] memory accounts,
            Actions.ActionArgs[] memory actions
        ) = ROUTER_PROXY.getParamsForSwapTokensForExactTokens(
            constants.solidAccount.owner,
            constants.solidAccount.number,
            /* _amountInMaxWei = */ uint(- 1), // solium-disable-line indentation
            cache.owedWeiToLiquidate, // the amount of owedMarket that needs to be repaid. Exact output amount
            _tokenPath
        );

        if (cache.solidHeldUpdateWithReward >= actions[0].amount.value) {
            uint256 profit = cache.solidHeldUpdateWithReward.sub(actions[0].amount.value);
            emit LogLiquidateWithAmm(
                constants.solidAccount.owner,
                constants.solidAccount.number,
                cache.heldMarket,
                cache.solidHeldUpdateWithReward,
                Types.Wei(true, profit),
                cache.owedMarket,
                cache.owedWeiToLiquidate
            );
        } else {
            Require.that(
                !_revertOnFailToSellCollateral,
                FILE,
                "totalSolidHeldWei is too small",
                totalSolidHeldWei,
                actions[0].amount.value
            );

            // This value needs to be calculated before `actions` is overwritten below with the new swap parameters
            uint256 profit = actions[0].amount.value.sub(cache.solidHeldUpdateWithReward);
            (accounts, actions) = ROUTER_PROXY.getParamsForSwapExactTokensForTokens(
                constants.solidAccount.owner,
                constants.solidAccount.number,
                totalSolidHeldWei, // inputWei
                _minOwedOutputAmount,
                _tokenPath
            );

            emit LogLiquidateWithAmm(
                constants.solidAccount.owner,
                constants.solidAccount.number,
                cache.heldMarket,
                cache.solidHeldUpdateWithReward,
                Types.Wei(false, profit),
                cache.owedMarket,
                cache.owedWeiToLiquidate
            );
        }

        accounts = _constructAccountsArray(constants, accounts);

        // execute the liquidations
        constants.dolomiteMargin.operate(
            accounts,
            _constructActionsArray(
                constants,
                cache,
                /* _solidAccountId = */ 0, // solium-disable-line indentation
                /* _liquidAccount = */ accounts.length - 1, // solium-disable-line indentation
                actions
            )
        );
    }

    // ============ Internal Functions ============

    /**
     * Make some basic checks before attempting to liquidate an account.
     *  - Ensure `tokenPath` is aligned with `heldMarket` and `owedMarket`
     *  - Basic checks by calling `checkBasicRequirements`
     */
    function _checkRequirements(
        Constants memory _constants,
        uint256 _heldMarket,
        uint256 _owedMarket,
        address[] memory _tokenPath
    )
    internal
    view {
        Require.that(
            _constants.dolomiteMargin.getMarketIdByTokenAddress(_tokenPath[0]) == _heldMarket,
            FILE,
            "0-index token path incorrect",
            _tokenPath[0]
        );

        Require.that(
            _constants.dolomiteMargin.getMarketIdByTokenAddress(_tokenPath[_tokenPath.length - 1]) == _owedMarket,
            FILE,
            "last-index token path incorrect",
            _tokenPath[_tokenPath.length - 1]
        );

        _checkBasicRequirements(_constants, _owedMarket);
    }

    function _constructAccountsArray(
        Constants memory _constants,
        Account.Info[] memory _accountsForTrade
    )
    internal
    pure
    returns (Account.Info[] memory)
    {
        Account.Info[] memory accounts = new Account.Info[](_accountsForTrade.length + 1);
        for (uint256 i = 0; i < _accountsForTrade.length; i++) {
            accounts[i] = _accountsForTrade[i];
        }
        assert(
            accounts[0].owner == _constants.solidAccount.owner &&
            accounts[0].number == _constants.solidAccount.number
        );

        accounts[accounts.length - 1] = _constants.liquidAccount;
        return accounts;
    }

    function _constructActionsArray(
        Constants memory _constants,
        LiquidatorProxyCache memory _cache,
        uint256 _solidAccountId,
        uint256 _liquidAccountId,
        Actions.ActionArgs[] memory _actionsForTrade
    )
    internal
    pure
    returns (Actions.ActionArgs[] memory)
    {
        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](_actionsForTrade.length + 1);

        if (_constants.expiry > 0) {
            // First action is a trade for closing the expired account
            // accountId is solidAccount; otherAccountId is liquidAccount
            actions[0] = AccountActionHelper.encodeExpiryLiquidateAction(
                _solidAccountId,
                _liquidAccountId,
                _cache.owedMarket,
                _cache.heldMarket,
                address(_constants.expiryProxy),
                _constants.expiry,
                _cache.flipMarkets
            );
        } else {
            // First action is a liquidation
            // accountId is solidAccount; otherAccountId is liquidAccount
            actions[0] = AccountActionHelper.encodeLiquidateAction(
                _solidAccountId,
                _liquidAccountId,
                _cache.owedMarket,
                _cache.heldMarket,
                _cache.owedWeiToLiquidate
            );
        }

        for (uint256 i = 0; i < _actionsForTrade.length; i++) {
            actions[i + 1] = _actionsForTrade[i];
        }

        return actions;
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Types } from "./Types.sol";
import { EnumerableSet } from "./EnumerableSet.sol";


/**
 * @title Account
 * @author dYdX
 *
 * Library of structs and functions that represent an account
 */
library Account {
    // ============ Enums ============

    /*
     * Most-recently-cached account status.
     *
     * Normal: Can only be liquidated if the account values are violating the global margin-ratio.
     * Liquid: Can be liquidated no matter the account values.
     *         Can be vaporized if there are no more positive account values.
     * Vapor:  Has only negative (or zeroed) account values. Can be vaporized.
     *
     */
    enum Status {
        Normal,
        Liquid,
        Vapor
    }

    // ============ Structs ============

    // Represents the unique key that specifies an account
    struct Info {
        address owner;  // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }

    // The complete storage for any account
    struct Storage {
        Status status;
        uint32 numberOfMarketsWithDebt;
        EnumerableSet.Set marketsWithNonZeroBalanceSet;
        mapping (uint256 => Types.Par) balances; // Mapping from marketId to principal
    }

    // ============ Library Functions ============

    function equals(
        Info memory a,
        Info memory b
    )
        internal
        pure
        returns (bool)
    {
        return a.owner == b.owner && a.number == b.number;
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { DolomiteMarginMath } from "./DolomiteMarginMath.sol";


/**
 * @title Types
 * @author dYdX
 *
 * Library for interacting with the basic structs used in DolomiteMargin
 */
library Types {
    using DolomiteMarginMath for uint256;

    // ============ Permission ============

    struct OperatorArg {
        address operator;
        bool trusted;
    }

    // ============ AssetAmount ============

    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par  // the amount is denominated in par
    }

    enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    // ============ Par (Principal Amount) ============

    // Total borrow and supply values for a market
    struct TotalPar {
        uint128 borrow;
        uint128 supply;
    }

    // Individual principal amount for an account
    struct Par {
        bool sign; // true if positive
        uint128 value;
    }

    function zeroPar()
        internal
        pure
        returns (Par memory)
    {
        return Par({
            sign: false,
            value: 0
        });
    }

    function sub(
        Par memory a,
        Par memory b
    )
        internal
        pure
        returns (Par memory)
    {
        return add(a, negative(b));
    }

    function add(
        Par memory a,
        Par memory b
    )
        internal
        pure
        returns (Par memory)
    {
        Par memory result;
        if (a.sign == b.sign) {
            result.sign = a.sign;
            result.value = SafeMath.add(a.value, b.value).to128();
        } else {
            if (a.value >= b.value) {
                result.sign = a.sign;
                result.value = SafeMath.sub(a.value, b.value).to128();
            } else {
                result.sign = b.sign;
                result.value = SafeMath.sub(b.value, a.value).to128();
            }
        }
        return result;
    }

    function equals(
        Par memory a,
        Par memory b
    )
        internal
        pure
        returns (bool)
    {
        if (a.value == b.value) {
            if (a.value == 0) {
                return true;
            }
            return a.sign == b.sign;
        }
        return false;
    }

    function negative(
        Par memory a
    )
        internal
        pure
        returns (Par memory)
    {
        return Par({
            sign: !a.sign,
            value: a.value
        });
    }

    function isNegative(
        Par memory a
    )
        internal
        pure
        returns (bool)
    {
        return !a.sign && a.value > 0;
    }

    function isPositive(
        Par memory a
    )
        internal
        pure
        returns (bool)
    {
        return a.sign && a.value > 0;
    }

    function isZero(
        Par memory a
    )
        internal
        pure
        returns (bool)
    {
        return a.value == 0;
    }

    function isLessThanZero(
        Par memory a
    )
        internal
        pure
        returns (bool)
    {
        return a.value > 0 && !a.sign;
    }

    function isGreaterThanOrEqualToZero(
        Par memory a
    )
        internal
        pure
        returns (bool)
    {
        return isZero(a) || a.sign;
    }

    // ============ Wei (Token Amount) ============

    // Individual token amount for an account
    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }

    function zeroWei()
        internal
        pure
        returns (Wei memory)
    {
        return Wei({
            sign: false,
            value: 0
        });
    }

    function sub(
        Wei memory a,
        Wei memory b
    )
        internal
        pure
        returns (Wei memory)
    {
        return add(a, negative(b));
    }

    function add(
        Wei memory a,
        Wei memory b
    )
        internal
        pure
        returns (Wei memory)
    {
        Wei memory result;
        if (a.sign == b.sign) {
            result.sign = a.sign;
            result.value = SafeMath.add(a.value, b.value);
        } else {
            if (a.value >= b.value) {
                result.sign = a.sign;
                result.value = SafeMath.sub(a.value, b.value);
            } else {
                result.sign = b.sign;
                result.value = SafeMath.sub(b.value, a.value);
            }
        }
        return result;
    }

    function equals(
        Wei memory a,
        Wei memory b
    )
        internal
        pure
        returns (bool)
    {
        if (a.value == b.value) {
            if (a.value == 0) {
                return true;
            }
            return a.sign == b.sign;
        }
        return false;
    }

    function negative(
        Wei memory a
    )
        internal
        pure
        returns (Wei memory)
    {
        return Wei({
            sign: !a.sign,
            value: a.value
        });
    }

    function isNegative(
        Wei memory a
    )
        internal
        pure
        returns (bool)
    {
        return !a.sign && a.value > 0;
    }

    function isPositive(
        Wei memory a
    )
        internal
        pure
        returns (bool)
    {
        return a.sign && a.value > 0;
    }

    function isZero(
        Wei memory a
    )
        internal
        pure
        returns (bool)
    {
        return a.value == 0;
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { IERC20Detailed } from "../interfaces/IERC20Detailed.sol";


/**
 * @title Token
 * @author dYdX
 *
 * This library contains basic functions for interacting with ERC20 tokens. Modified to work with
 * tokens that don't adhere strictly to the ERC20 standard (for example tokens that don't return a
 * boolean value on success).
 */
library Token {

    // ============ Library Functions ============

    function transfer(
        address token,
        address to,
        uint256 amount
    )
        internal
    {
        if (amount == 0 || to == address(this)) {
            return;
        }

        _callOptionalReturn(
            token,
            abi.encodeWithSelector(IERC20Detailed(token).transfer.selector, to, amount),
            "Token: transfer failed"
        );
    }

    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    )
        internal
    {
        if (amount == 0 || to == from) {
            return;
        }

        // solium-disable arg-overflow
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(IERC20Detailed(token).transferFrom.selector, from, to, amount),
            "Token: transferFrom failed"
        );
        // solium-enable arg-overflow
    }

    // ============ Private Functions ============

    function _callOptionalReturn(address token, bytes memory data, string memory error) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        // 1. The target address is checked to contain contract code. Not needed since tokens are manually added
        // 2. The call itself is made, and success asserted
        // 3. The return value is decoded, which in turn checks the size of the returned data.

        // solium-disable-next-line security/no-low-level-calls
        (bool success, bytes memory returnData) = token.call(data);
        require(success, error);

        if (returnData.length > 0) {
            // Return data is optional
            require(abi.decode(returnData, (bool)), error);
        }
    }

}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { DolomiteMarginMath } from "./DolomiteMarginMath.sol";


/**
 * @title Time
 * @author dYdX
 *
 * Library for dealing with time, assuming timestamps fit within 32 bits (valid until year 2106)
 */
library Time {

    // ============ Library Functions ============

    function currentTime()
        internal
        view
        returns (uint32)
    {
        return DolomiteMarginMath.to32(block.timestamp);
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Account } from "./Account.sol";
import { Bits } from "./Bits.sol";
import { Cache } from "./Cache.sol";
import { Decimal } from "./Decimal.sol";
import { Interest } from "./Interest.sol";
import { EnumerableSet } from "./EnumerableSet.sol";
import { DolomiteMarginMath } from "./DolomiteMarginMath.sol";
import { Monetary } from "./Monetary.sol";
import { Require } from "./Require.sol";
import { Time } from "./Time.sol";
import { Token } from "./Token.sol";
import { Types } from "./Types.sol";
import { IERC20Detailed } from "../interfaces/IERC20Detailed.sol";
import { IInterestSetter } from "../interfaces/IInterestSetter.sol";
import { IPriceOracle } from "../interfaces/IPriceOracle.sol";


/**
 * @title Storage
 * @author dYdX
 *
 * Functions for reading, writing, and verifying state in DolomiteMargin
 */
library Storage {
    using Cache for Cache.MarketCache;
    using Storage for Storage.State;
    using DolomiteMarginMath for uint256;
    using Types for Types.Par;
    using Types for Types.Wei;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.Set;

    // ============ Constants ============

    bytes32 internal constant FILE = "Storage";

    // ============ Structs ============

    // All information necessary for tracking a market
    struct Market {
        // Contract address of the associated ERC20 token
        address token;

        // Whether additional borrows are allowed for this market
        bool isClosing;

        // Whether this market can be removed and its ID can be recycled and reused
        bool isRecyclable;

        // Total aggregated supply and borrow amount of the entire market
        Types.TotalPar totalPar;

        // Interest index of the market
        Interest.Index index;

        // Contract address of the price oracle for this market
        IPriceOracle priceOracle;

        // Contract address of the interest setter for this market
        IInterestSetter interestSetter;

        // Multiplier on the marginRatio for this market, IE 5% (0.05 * 1e18). This number increases the market's
        // required collateralization by: reducing the user's supplied value (in terms of dollars) for this market and
        // increasing its borrowed value. This is done through the following operation:
        // `suppliedWei = suppliedWei + (assetValueForThisMarket / (1 + marginPremium))`
        // This number increases the user's borrowed wei by multiplying it by:
        // `borrowedWei = borrowedWei + (assetValueForThisMarket * (1 + marginPremium))`
        Decimal.D256 marginPremium;

        // Multiplier on the liquidationSpread for this market, IE 20% (0.2 * 1e18). This number increases the
        // `liquidationSpread` using the following formula:
        // `liquidationSpread = liquidationSpread * (1 + spreadPremium)`
        // NOTE: This formula is applied up to two times - one for each market whose spreadPremium is greater than 0
        // (when performing a liquidation between two markets)
        Decimal.D256 spreadPremium;

        // The maximum amount that can be held by the protocol. This allows the protocol to cap any additional risk
        // that is inferred by allowing borrowing against low-cap or assets with increased volatility. Setting this
        // value to 0 is analogous to having no limit. This value can never be below 0.
        Types.Wei maxWei;
    }

    // The global risk parameters that govern the health and security of the system
    struct RiskParams {
        // Required ratio of over-collateralization
        Decimal.D256 marginRatio;

        // Percentage penalty incurred by liquidated accounts
        Decimal.D256 liquidationSpread;

        // Percentage of the borrower's interest fee that gets passed to the suppliers
        Decimal.D256 earningsRate;

        // The minimum absolute borrow value of an account
        // There must be sufficient incentivize to liquidate undercollateralized accounts
        Monetary.Value minBorrowedValue;

        // The maximum number of markets a user can have a non-zero balance for a given account.
        uint256 accountMaxNumberOfMarketsWithBalances;
    }

    // The maximum RiskParam values that can be set
    struct RiskLimits {
        // The highest that the ratio can be for liquidating under-water accounts
        uint64 marginRatioMax;
        // The highest that the liquidation rewards can be when a liquidator liquidates an account
        uint64 liquidationSpreadMax;
        // The highest that the supply APR can be for a market, as a proportion of the borrow rate. Meaning, a rate of
        // 100% (1e18) would give suppliers all of the interest that borrowers are paying. A rate of 90% would give
        // suppliers 90% of the interest that borrowers pay.
        uint64 earningsRateMax;
        // The highest min margin ratio premium that can be applied to a particular market. Meaning, a value of 100%
        // (1e18) would require borrowers to maintain an extra 100% collateral to maintain a healthy margin ratio. This
        // value works by increasing the debt owed and decreasing the supply held for the particular market by this
        // amount, plus 1e18 (since a value of 10% needs to be applied as `decimal.plusOne`)
        uint64 marginPremiumMax;
        // The highest liquidation reward that can be applied to a particular market. This percentage is applied
        // in addition to the liquidation spread in `RiskParams`. Meaning a value of 1e18 is 100%. It is calculated as:
        // `liquidationSpread * Decimal.onePlus(spreadPremium)`
        uint64 spreadPremiumMax;
        uint128 minBorrowedValueMax;
    }

    // The entire storage state of DolomiteMargin
    struct State {
        // number of markets
        uint256 numMarkets;

        // marketId => Market
        mapping (uint256 => Market) markets;

        // token address => marketId
        mapping (address => uint256) tokenToMarketId;

        // Linked list from marketId to the next recycled market id
        mapping(uint256 => uint256) recycledMarketIds;

        // owner => account number => Account
        mapping (address => mapping (uint256 => Account.Storage)) accounts;

        // Addresses that can control other users accounts
        mapping (address => mapping (address => bool)) operators;

        // Addresses that can control all users accounts
        mapping (address => bool) globalOperators;

        // Addresses of auto traders that can only be called by global operators. IE for expirations
        mapping (address => bool) specialAutoTraders;

        // mutable risk parameters of the system
        RiskParams riskParams;

        // immutable risk limits of the system
        RiskLimits riskLimits;
    }

    // ============ Functions ============

    function getToken(
        Storage.State storage state,
        uint256 marketId
    )
        internal
        view
        returns (address)
    {
        return state.markets[marketId].token;
    }

    function getTotalPar(
        Storage.State storage state,
        uint256 marketId
    )
        internal
        view
        returns (Types.TotalPar memory)
    {
        return state.markets[marketId].totalPar;
    }

    function getMaxWei(
        Storage.State storage state,
        uint256 marketId
    )
        internal
        view
        returns (Types.Wei memory)
    {
        return state.markets[marketId].maxWei;
    }

    function getIndex(
        Storage.State storage state,
        uint256 marketId
    )
        internal
        view
        returns (Interest.Index memory)
    {
        return state.markets[marketId].index;
    }

    function getNumExcessTokens(
        Storage.State storage state,
        uint256 marketId
    )
        internal
        view
        returns (Types.Wei memory)
    {
        Interest.Index memory index = state.getIndex(marketId);
        Types.TotalPar memory totalPar = state.getTotalPar(marketId);

        address token = state.getToken(marketId);

        Types.Wei memory balanceWei = Types.Wei({
            sign: true,
            value: IERC20Detailed(token).balanceOf(address(this))
        });

        (
            Types.Wei memory supplyWei,
            Types.Wei memory borrowWei
        ) = Interest.totalParToWei(totalPar, index);

        // borrowWei is negative, so subtracting it makes the value more positive
        return balanceWei.sub(borrowWei).sub(supplyWei);
    }

    function getStatus(
        Storage.State storage state,
        Account.Info memory account
    )
        internal
        view
        returns (Account.Status)
    {
        return state.accounts[account.owner][account.number].status;
    }

    function getPar(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId
    )
        internal
        view
        returns (Types.Par memory)
    {
        return state.accounts[account.owner][account.number].balances[marketId];
    }

    function getWei(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId,
        Interest.Index memory index
    )
        internal
        view
        returns (Types.Wei memory)
    {
        Types.Par memory par = state.getPar(account, marketId);

        if (par.isZero()) {
            return Types.zeroWei();
        }

        return Interest.parToWei(par, index);
    }

    function getMarketsWithBalancesSet(
        Storage.State storage state,
        Account.Info memory account
    )
    internal
    view
    returns (EnumerableSet.Set storage)
    {
        return state.accounts[account.owner][account.number].marketsWithNonZeroBalanceSet;
    }

    function getMarketsWithBalances(
        Storage.State storage state,
        Account.Info memory account
    )
    internal
    view
    returns (uint256[] memory)
    {
        return state.accounts[account.owner][account.number].marketsWithNonZeroBalanceSet.values();
    }

    function getAccountMarketWithBalanceAtIndex(
        Storage.State storage state,
        Account.Info memory account,
        uint256 index
    )
    internal
    view
    returns (uint256)
    {
        return state.accounts[account.owner][account.number].marketsWithNonZeroBalanceSet.getAtIndex(index);
    }

    function getNumberOfMarketsWithBalances(
        Storage.State storage state,
        Account.Info memory account
    )
    internal
    view
    returns (uint256)
    {
        return state.accounts[account.owner][account.number].marketsWithNonZeroBalanceSet.length();
    }

    function getAccountNumberOfMarketsWithDebt(
        Storage.State storage state,
        Account.Info memory account
    )
    internal
    view
    returns (uint256)
    {
        return state.accounts[account.owner][account.number].numberOfMarketsWithDebt;
    }

    function getLiquidationSpreadForPair(
        Storage.State storage state,
        uint256 heldMarketId,
        uint256 owedMarketId
    )
        internal
        view
        returns (Decimal.D256 memory)
    {
        uint256 result = state.riskParams.liquidationSpread.value;
        result = Decimal.mul(result, Decimal.onePlus(state.markets[heldMarketId].spreadPremium));
        result = Decimal.mul(result, Decimal.onePlus(state.markets[owedMarketId].spreadPremium));
        return Decimal.D256({
            value: result
        });
    }

    function fetchNewIndex(
        Storage.State storage state,
        uint256 marketId,
        Interest.Index memory index
    )
        internal
        view
        returns (Interest.Index memory)
    {
        Interest.Rate memory rate = state.fetchInterestRate(marketId, index);

        return Interest.calculateNewIndex(
            index,
            rate,
            state.getTotalPar(marketId),
            state.riskParams.earningsRate
        );
    }

    function fetchInterestRate(
        Storage.State storage state,
        uint256 marketId,
        Interest.Index memory index
    )
        internal
        view
        returns (Interest.Rate memory)
    {
        Types.TotalPar memory totalPar = state.getTotalPar(marketId);
        (
            Types.Wei memory supplyWei,
            Types.Wei memory borrowWei
        ) = Interest.totalParToWei(totalPar, index);

        Interest.Rate memory rate = state.markets[marketId].interestSetter.getInterestRate(
            state.getToken(marketId),
            borrowWei.value,
            supplyWei.value
        );

        return rate;
    }

    function fetchPrice(
        Storage.State storage state,
        uint256 marketId,
        address token
    )
        internal
        view
        returns (Monetary.Price memory)
    {
        IPriceOracle oracle = IPriceOracle(state.markets[marketId].priceOracle);
        Monetary.Price memory price = oracle.getPrice(token);
        Require.that(
            price.value != 0,
            FILE,
            "Price cannot be zero",
            marketId
        );
        return price;
    }

    function getAccountValues(
        Storage.State storage state,
        Account.Info memory account,
        Cache.MarketCache memory cache,
        bool adjustForLiquidity
    )
        internal
        view
        returns (Monetary.Value memory, Monetary.Value memory)
    {
        Monetary.Value memory supplyValue;
        Monetary.Value memory borrowValue;

        uint256 numMarkets = cache.getNumMarkets();
        for (uint256 i = 0; i < numMarkets; i++) {
            Types.Wei memory userWei = state.getWei(account, cache.getAtIndex(i).marketId, cache.getAtIndex(i).index);

            if (userWei.isZero()) {
                continue;
            }

            uint256 assetValue = userWei.value.mul(cache.getAtIndex(i).price.value);
            Decimal.D256 memory adjust = Decimal.one();
            if (adjustForLiquidity) {
                adjust = Decimal.onePlus(state.markets[cache.getAtIndex(i).marketId].marginPremium);
            }

            if (userWei.sign) {
                supplyValue.value = supplyValue.value.add(Decimal.div(assetValue, adjust));
            } else {
                borrowValue.value = borrowValue.value.add(Decimal.mul(assetValue, adjust));
            }
        }

        return (supplyValue, borrowValue);
    }

    function isCollateralized(
        Storage.State storage state,
        Account.Info memory account,
        Cache.MarketCache memory cache,
        bool requireMinBorrow
    )
        internal
        view
        returns (bool)
    {
        if (state.getAccountNumberOfMarketsWithDebt(account) == 0) {
            // The user does not have a balance with a borrow amount, so they must be collateralized
            return true;
        }

        // get account values (adjusted for liquidity)
        (
            Monetary.Value memory supplyValue,
            Monetary.Value memory borrowValue
        ) = state.getAccountValues(account, cache, /* adjustForLiquidity = */ true);

        if (requireMinBorrow) {
            Require.that(
                borrowValue.value >= state.riskParams.minBorrowedValue.value,
                FILE,
                "Borrow value too low",
                account.owner,
                account.number
            );
        }

        uint256 requiredMargin = Decimal.mul(borrowValue.value, state.riskParams.marginRatio);

        return supplyValue.value >= borrowValue.value.add(requiredMargin);
    }

    function isGlobalOperator(
        Storage.State storage state,
        address operator
    )
        internal
        view
        returns (bool)
    {
        return state.globalOperators[operator];
    }

    function isAutoTraderSpecial(
        Storage.State storage state,
        address autoTrader
    )
        internal
        view
        returns (bool)
    {
        return state.specialAutoTraders[autoTrader];
    }

    function isLocalOperator(
        Storage.State storage state,
        address owner,
        address operator
    )
        internal
        view
        returns (bool)
    {
        return state.operators[owner][operator];
    }

    function requireIsGlobalOperator(
        Storage.State storage state,
        address operator
    )
        internal
        view
    {
        bool isValidOperator = state.isGlobalOperator(operator);

        Require.that(
            isValidOperator,
            FILE,
            "Unpermissioned global operator",
            operator
        );
    }

    function requireIsOperator(
        Storage.State storage state,
        Account.Info memory account,
        address operator
    )
        internal
        view
    {
        bool isValidOperator =
            operator == account.owner
            || state.isGlobalOperator(operator)
            || state.isLocalOperator(account.owner, operator);

        Require.that(
            isValidOperator,
            FILE,
            "Unpermissioned operator",
            operator
        );
    }

    /**
     * Determine and set an account's balance based on the intended balance change. Return the
     * equivalent amount in wei
     */
    function getNewParAndDeltaWei(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId,
        Interest.Index memory index,
        Types.AssetAmount memory amount
    )
        internal
        view
        returns (Types.Par memory, Types.Wei memory)
    {
        Types.Par memory oldPar = state.getPar(account, marketId);

        if (amount.value == 0 && amount.ref == Types.AssetReference.Delta) {
            return (oldPar, Types.zeroWei());
        }

        Types.Wei memory oldWei = Interest.parToWei(oldPar, index);
        Types.Par memory newPar;
        Types.Wei memory deltaWei;

        if (amount.denomination == Types.AssetDenomination.Wei) {
            deltaWei = Types.Wei({
                sign: amount.sign,
                value: amount.value
            });
            if (amount.ref == Types.AssetReference.Target) {
                deltaWei = deltaWei.sub(oldWei);
            }
            newPar = Interest.weiToPar(oldWei.add(deltaWei), index);
        } else { // AssetDenomination.Par
            newPar = Types.Par({
                sign: amount.sign,
                value: amount.value.to128()
            });
            if (amount.ref == Types.AssetReference.Delta) {
                newPar = oldPar.add(newPar);
            }
            deltaWei = Interest.parToWei(newPar, index).sub(oldWei);
        }

        return (newPar, deltaWei);
    }

    function getNewParAndDeltaWeiForLiquidation(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId,
        Interest.Index memory index,
        Types.AssetAmount memory amount
    )
        internal
        view
        returns (Types.Par memory, Types.Wei memory)
    {
        Types.Par memory oldPar = state.getPar(account, marketId);

        Require.that(
            !oldPar.isPositive(),
            FILE,
            "Owed balance cannot be positive",
            account.owner,
            account.number
        );

        (
            Types.Par memory newPar,
            Types.Wei memory deltaWei
        ) = state.getNewParAndDeltaWei(
            account,
            marketId,
            index,
            amount
        );

        // if attempting to over-repay the owed asset, bound it by the maximum
        if (newPar.isPositive()) {
            newPar = Types.zeroPar();
            deltaWei = state.getWei(account, marketId, index).negative();
        }

        Require.that(
            !deltaWei.isNegative() && oldPar.value >= newPar.value,
            FILE,
            "Owed balance cannot increase",
            account.owner,
            account.number
        );

        // if not paying back enough wei to repay any par, then bound wei to zero
        if (oldPar.equals(newPar)) {
            deltaWei = Types.zeroWei();
        }

        return (newPar, deltaWei);
    }

    function isVaporizable(
        Storage.State storage state,
        Account.Info memory account,
        Cache.MarketCache memory cache
    )
        internal
        view
        returns (bool)
    {
        bool hasNegative = false;
        uint256 numMarkets = cache.getNumMarkets();
        for (uint256 i = 0; i < numMarkets; i++) {
            Types.Par memory par = state.getPar(account, cache.getAtIndex(i).marketId);
            if (par.isZero()) {
                continue;
            } else if (par.sign) {
                return false;
            } else {
                hasNegative = true;
            }
        }
        return hasNegative;
    }

    // =============== Setter Functions ===============

    function updateIndex(
        Storage.State storage state,
        uint256 marketId
    )
        internal
        returns (Interest.Index memory)
    {
        Interest.Index memory index = state.getIndex(marketId);
        if (index.lastUpdate == Time.currentTime()) {
            return index;
        }
        return state.markets[marketId].index = state.fetchNewIndex(marketId, index);
    }

    function setStatus(
        Storage.State storage state,
        Account.Info memory account,
        Account.Status status
    )
        internal
    {
        state.accounts[account.owner][account.number].status = status;
    }

    function setPar(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId,
        Types.Par memory newPar
    )
        internal
    {
        Types.Par memory oldPar = state.getPar(account, marketId);

        if (Types.equals(oldPar, newPar)) {
            // GUARD statement
            return;
        }

        // updateTotalPar
        Types.TotalPar memory totalPar = state.getTotalPar(marketId);

        // roll-back oldPar
        if (oldPar.sign) {
            totalPar.supply = uint256(totalPar.supply).sub(oldPar.value).to128();
        } else {
            totalPar.borrow = uint256(totalPar.borrow).sub(oldPar.value).to128();
        }

        // roll-forward newPar
        if (newPar.sign) {
            totalPar.supply = uint256(totalPar.supply).add(newPar.value).to128();
        } else {
            totalPar.borrow = uint256(totalPar.borrow).add(newPar.value).to128();
        }

        if (oldPar.isLessThanZero() && newPar.isGreaterThanOrEqualToZero()) {
            // user went from borrowing to repaying or positive
            state.accounts[account.owner][account.number].numberOfMarketsWithDebt -= 1;
        } else if (oldPar.isGreaterThanOrEqualToZero() && newPar.isLessThanZero()) {
            // user went from zero or positive to borrowing
            state.accounts[account.owner][account.number].numberOfMarketsWithDebt += 1;
        }

        if (newPar.isZero() && (!oldPar.isZero())) {
            // User went from a non-zero balance to zero. Remove the market from the set.
            state.accounts[account.owner][account.number].marketsWithNonZeroBalanceSet.remove(marketId);
        } else if ((!newPar.isZero()) && oldPar.isZero()) {
            // User went from zero to non-zero. Add the market to the set.
            state.accounts[account.owner][account.number].marketsWithNonZeroBalanceSet.add(marketId);
        }

        state.markets[marketId].totalPar = totalPar;
        state.accounts[account.owner][account.number].balances[marketId] = newPar;
    }

    /**
     * Determine and set an account's balance based on a change in wei
     */
    function setParFromDeltaWei(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId,
        Interest.Index memory index,
        Types.Wei memory deltaWei
    )
        internal
    {
        if (deltaWei.isZero()) {
            return;
        }
        Types.Wei memory oldWei = state.getWei(account, marketId, index);
        Types.Wei memory newWei = oldWei.add(deltaWei);
        Types.Par memory newPar = Interest.weiToPar(newWei, index);
        state.setPar(
            account,
            marketId,
            newPar
        );
    }

    /**
     * Initializes the cache using the set bits
     */
    function initializeCache(
        Storage.State storage state,
        Cache.MarketCache memory cache
    ) internal view {
        cache.markets = new Cache.MarketInfo[](cache.marketsLength);
        uint counter = 0;

        // Really neat byproduct of iterating through a bitmap using the least significant bit, where each set flag
        // represents the marketId, --> the initialized `cache.markets` array is sorted in O(n)!
        // Meaning, this function call is O(n) where `n` is the number of markets in the cache
        for (uint i = 0; i < cache.marketBitmaps.length; i++) {
            uint bitmap = cache.marketBitmaps[i];
            while (bitmap != 0) {
                uint nextSetBit = Bits.getLeastSignificantBit(bitmap);
                uint marketId = Bits.getMarketIdFromBit(i, nextSetBit);
                address token = state.getToken(marketId);
                Types.TotalPar memory totalPar = state.getTotalPar(marketId);
                cache.markets[counter++] = Cache.MarketInfo({
                    marketId: marketId,
                    token: token,
                    isClosing: state.markets[marketId].isClosing,
                    borrowPar: totalPar.borrow,
                    supplyPar: totalPar.supply,
                    index: state.getIndex(marketId),
                    price: state.fetchPrice(marketId, token)
                });

                // unset the set bit
                bitmap = Bits.unsetBit(bitmap, nextSetBit);
            }
            if (counter == cache.marketsLength) {
                break;
            }
        }

        assert(cache.marketsLength == counter);
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;


/**
 * @title Require
 * @author dYdX
 *
 * Stringifies parameters to pretty-print revert messages. Costs more gas than regular require()
 */
library Require {

    // ============ Constants ============

    uint256 constant ASCII_ZERO = 48; // '0'
    uint256 constant ASCII_RELATIVE_ZERO = 87; // 'a' - 10
    uint256 constant ASCII_LOWER_EX = 120; // 'x'
    bytes2 constant COLON = 0x3a20; // ': '
    bytes2 constant COMMA = 0x2c20; // ', '
    bytes2 constant LPAREN = 0x203c; // ' <'
    byte constant RPAREN = 0x3e; // '>'
    uint256 constant FOUR_BIT_MASK = 0xf;

    // ============ Library Functions ============

    function that(
        bool must,
        bytes32 file,
        bytes32 reason
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason)
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA,
        uint256 payloadB
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        COMMA,
                        stringify(payloadC),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        COMMA,
                        stringify(payloadC),
                        RPAREN
                    )
                )
            );
        }
    }

    // ============ Private Functions ============

    function stringifyTruncated(
        bytes32 input
    )
        internal
        pure
        returns (bytes memory)
    {
        // put the input bytes into the result
        bytes memory result = abi.encodePacked(input);

        // determine the length of the input by finding the location of the last non-zero byte
        for (uint256 i = 32; i > 0; ) {
            // reverse-for-loops with unsigned integer
            /* solium-disable-next-line security/no-modify-for-iter-var */
            i--;

            // find the last non-zero byte in order to determine the length
            if (result[i] != 0) {
                uint256 length = i + 1;

                /* solium-disable-next-line security/no-inline-assembly */
                assembly {
                    mstore(result, length) // r.length = length;
                }

                return result;
            }
        }

        // all bytes are zero
        return new bytes(0);
    }

    function stringify(
        uint256 input
    )
        private
        pure
        returns (bytes memory)
    {
        if (input == 0) {
            return "0";
        }

        // get the final string length
        uint256 j = input;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }

        // allocate the string
        bytes memory bstr = new bytes(length);

        // populate the string starting with the least-significant character
        j = input;
        for (uint256 i = length; i > 0; ) {
            // reverse-for-loops with unsigned integer
            /* solium-disable-next-line security/no-modify-for-iter-var */
            i--;

            // take last decimal digit
            bstr[i] = byte(uint8(ASCII_ZERO + (j % 10)));

            // remove the last decimal digit
            j /= 10;
        }

        return bstr;
    }

    function stringify(
        address input
    )
        private
        pure
        returns (bytes memory)
    {
        uint256 z = uint256(input);

        // addresses are "0x" followed by 20 bytes of data which take up 2 characters each
        bytes memory result = new bytes(42);

        // populate the result with "0x"
        result[0] = byte(uint8(ASCII_ZERO));
        result[1] = byte(uint8(ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 20; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[41 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[40 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function stringify(
        bytes32 input
    )
        private
        pure
        returns (bytes memory)
    {
        uint256 z = uint256(input);

        // bytes32 are "0x" followed by 32 bytes of data which take up 2 characters each
        bytes memory result = new bytes(66);

        // populate the result with "0x"
        result[0] = byte(uint8(ASCII_ZERO));
        result[1] = byte(uint8(ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 32; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[65 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[64 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function char(
        uint256 input
    )
        private
        pure
        returns (byte)
    {
        // return ASCII digit (0-9)
        if (input < 10) {
            return byte(uint8(input + ASCII_ZERO));
        }

        // return ASCII letter (a-f)
        return byte(uint8(input + ASCII_RELATIVE_ZERO));
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;


/**
 * @title Monetary
 * @author dYdX
 *
 * Library for types involving money
 */
library Monetary {

    /*
     * The price of a base-unit of an asset. Has `36 - token.decimals` decimals
     */
    struct Price {
        uint256 value;
    }

    /*
     * Total value of an some amount of an asset. Equal to (price * amount). Has 36 decimals.
     */
    struct Value {
        uint256 value;
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Decimal } from "./Decimal.sol";
import { DolomiteMarginMath } from "./DolomiteMarginMath.sol";
import { Time } from "./Time.sol";
import { Types } from "./Types.sol";


/**
 * @title Interest
 * @author dYdX
 *
 * Library for managing the interest rate and interest indexes of DolomiteMargin
 */
library Interest {
    using DolomiteMarginMath for uint256;
    using SafeMath for uint256;

    // ============ Constants ============

    bytes32 constant FILE = "Interest";
    uint64 constant BASE = 10**18;

    // ============ Structs ============

    struct Rate {
        uint256 value;
    }

    struct Index {
        uint96 borrow;
        uint96 supply;
        uint32 lastUpdate;
    }

    // ============ Library Functions ============

    /**
     * Get a new market Index based on the old index and market interest rate.
     * Calculate interest for borrowers by using the formula rate * time. Approximates
     * continuously-compounded interest when called frequently, but is much more
     * gas-efficient to calculate. For suppliers, the interest rate is adjusted by the earningsRate,
     * then prorated across all suppliers.
     *
     * @param  index         The old index for a market
     * @param  rate          The current interest rate of the market
     * @param  totalPar      The total supply and borrow par values of the market
     * @param  earningsRate  The portion of the interest that is forwarded to the suppliers
     * @return               The updated index for a market
     */
    function calculateNewIndex(
        Index memory index,
        Rate memory rate,
        Types.TotalPar memory totalPar,
        Decimal.D256 memory earningsRate
    )
        internal
        view
        returns (Index memory)
    {
        (
            Types.Wei memory supplyWei,
            Types.Wei memory borrowWei
        ) = totalParToWei(totalPar, index);

        // get interest increase for borrowers
        uint32 currentTime = Time.currentTime();
        uint256 borrowInterest = rate.value.mul(uint256(currentTime).sub(index.lastUpdate));

        // get interest increase for suppliers
        uint256 supplyInterest;
        if (Types.isZero(supplyWei)) {
            supplyInterest = 0;
        } else {
            supplyInterest = Decimal.mul(borrowInterest, earningsRate);
            if (borrowWei.value < supplyWei.value) {
                // scale down the interest by the amount being supplied. Why? Because interest is only being paid on
                // the borrowWei, which means it's split amongst all of the supplyWei. Scaling it down normalizes it
                // for the suppliers to share what's being paid by borrowers
                supplyInterest = DolomiteMarginMath.getPartial(supplyInterest, borrowWei.value, supplyWei.value);
            }
        }
        assert(supplyInterest <= borrowInterest);

        return Index({
            borrow: DolomiteMarginMath.getPartial(index.borrow, borrowInterest, BASE).add(index.borrow).to96(),
            supply: DolomiteMarginMath.getPartial(index.supply, supplyInterest, BASE).add(index.supply).to96(),
            lastUpdate: currentTime
        });
    }

    function newIndex()
        internal
        view
        returns (Index memory)
    {
        return Index({
            borrow: BASE,
            supply: BASE,
            lastUpdate: Time.currentTime()
        });
    }

    /*
     * Convert a principal amount to a token amount given an index.
     */
    function parToWei(
        Types.Par memory input,
        Index memory index
    )
        internal
        pure
        returns (Types.Wei memory)
    {
        uint256 inputValue = uint256(input.value);
        if (input.sign) {
            return Types.Wei({
                sign: true,
                value: inputValue.getPartialRoundHalfUp(index.supply, BASE)
            });
        } else {
            return Types.Wei({
                sign: false,
                value: inputValue.getPartialRoundHalfUp(index.borrow, BASE)
            });
        }
    }

    /*
     * Convert a token amount to a principal amount given an index.
     */
    function weiToPar(
        Types.Wei memory input,
        Index memory index
    )
        internal
        pure
        returns (Types.Par memory)
    {
        if (input.sign) {
            return Types.Par({
                sign: true,
                value: input.value.getPartialRoundHalfUp(BASE, index.supply).to128()
            });
        } else {
            return Types.Par({
                sign: false,
                value: input.value.getPartialRoundHalfUp(BASE, index.borrow).to128()
            });
        }
    }

    /*
     * Convert the total supply and borrow principal amounts of a market to total supply and borrow
     * token amounts.
     */
    function totalParToWei(
        Types.TotalPar memory totalPar,
        Index memory index
    )
        internal
        pure
        returns (Types.Wei memory, Types.Wei memory)
    {
        Types.Par memory supplyPar = Types.Par({
            sign: true,
            value: totalPar.supply
        });
        Types.Par memory borrowPar = Types.Par({
            sign: false,
            value: totalPar.borrow
        });
        Types.Wei memory supplyWei = parToWei(supplyPar, index);
        Types.Wei memory borrowWei = parToWei(borrowPar, index);
        return (supplyWei, borrowWei);
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Account } from "./Account.sol";
import { Actions } from "./Actions.sol";
import { Cache } from "./Cache.sol";
import { Interest } from "./Interest.sol";
import { Monetary } from "./Monetary.sol";
import { Storage } from "./Storage.sol";
import { Types } from "./Types.sol";


/**
 * @title Events
 * @author dYdX
 *
 * Library to parse and emit logs from which the state of all accounts and indexes can be followed
 */
library Events {
    using Types for Types.Wei;
    using Storage for Storage.State;

    // ============ Events ============

    event LogIndexUpdate(
        uint256 indexed market,
        Interest.Index index
    );

    event LogOraclePrice(
        uint256 indexed market,
        Monetary.Price price
    );

    event LogOperation(
        address sender
    );

    event LogDeposit(
        address indexed accountOwner,
        uint256 accountNumber,
        uint256 market,
        BalanceUpdate update,
        address from
    );

    event LogWithdraw(
        address indexed accountOwner,
        uint256 accountNumber,
        uint256 market,
        BalanceUpdate update,
        address to
    );

    event LogTransfer(
        address indexed accountOneOwner,
        uint256 accountOneNumber,
        address indexed accountTwoOwner,
        uint256 accountTwoNumber,
        uint256 market,
        BalanceUpdate updateOne,
        BalanceUpdate updateTwo
    );

    event LogBuy(
        address indexed accountOwner,
        uint256 accountNumber,
        uint256 takerMarket,
        uint256 makerMarket,
        BalanceUpdate takerUpdate,
        BalanceUpdate makerUpdate,
        address exchangeWrapper
    );

    event LogSell(
        address indexed accountOwner,
        uint256 accountNumber,
        uint256 takerMarket,
        uint256 makerMarket,
        BalanceUpdate takerUpdate,
        BalanceUpdate makerUpdate,
        address exchangeWrapper
    );

    event LogTrade(
        address indexed takerAccountOwner,
        uint256 takerAccountNumber,
        address indexed makerAccountOwner,
        uint256 makerAccountNumber,
        uint256 inputMarket,
        uint256 outputMarket,
        BalanceUpdate takerInputUpdate,
        BalanceUpdate takerOutputUpdate,
        BalanceUpdate makerInputUpdate,
        BalanceUpdate makerOutputUpdate,
        address autoTrader
    );

    event LogCall(
        address indexed accountOwner,
        uint256 accountNumber,
        address callee
    );

    event LogLiquidate(
        address indexed solidAccountOwner,
        uint256 solidAccountNumber,
        address indexed liquidAccountOwner,
        uint256 liquidAccountNumber,
        uint256 heldMarket,
        uint256 owedMarket,
        BalanceUpdate solidHeldUpdate,
        BalanceUpdate solidOwedUpdate,
        BalanceUpdate liquidHeldUpdate,
        BalanceUpdate liquidOwedUpdate
    );

    event LogVaporize(
        address indexed solidAccountOwner,
        uint256 solidAccountNumber,
        address indexed vaporAccountOwner,
        uint256 vaporAccountNumber,
        uint256 heldMarket,
        uint256 owedMarket,
        BalanceUpdate solidHeldUpdate,
        BalanceUpdate solidOwedUpdate,
        BalanceUpdate vaporOwedUpdate
    );

    // ============ Structs ============

    struct BalanceUpdate {
        Types.Wei deltaWei;
        Types.Par newPar;
    }

    // ============ Internal Functions ============

    function logIndexUpdate(
        uint256 marketId,
        Interest.Index memory index
    )
        internal
    {
        emit LogIndexUpdate(
            marketId,
            index
        );
    }

    function logOraclePrice(
        Cache.MarketInfo memory marketInfo
    )
        internal
    {
        emit LogOraclePrice(
            marketInfo.marketId,
            marketInfo.price
        );
    }

    function logOperation()
        internal
    {
        emit LogOperation(msg.sender);
    }

    function logDeposit(
        Storage.State storage state,
        Actions.DepositArgs memory args,
        Types.Wei memory deltaWei
    )
        internal
    {
        emit LogDeposit(
            args.account.owner,
            args.account.number,
            args.market,
            getBalanceUpdate(
                state,
                args.account,
                args.market,
                deltaWei
            ),
            args.from
        );
    }

    function logWithdraw(
        Storage.State storage state,
        Actions.WithdrawArgs memory args,
        Types.Wei memory deltaWei
    )
        internal
    {
        emit LogWithdraw(
            args.account.owner,
            args.account.number,
            args.market,
            getBalanceUpdate(
                state,
                args.account,
                args.market,
                deltaWei
            ),
            args.to
        );
    }

    function logTransfer(
        Storage.State storage state,
        Actions.TransferArgs memory args,
        Types.Wei memory deltaWei
    )
        internal
    {
        emit LogTransfer(
            args.accountOne.owner,
            args.accountOne.number,
            args.accountTwo.owner,
            args.accountTwo.number,
            args.market,
            getBalanceUpdate(
                state,
                args.accountOne,
                args.market,
                deltaWei
            ),
            getBalanceUpdate(
                state,
                args.accountTwo,
                args.market,
                deltaWei.negative()
            )
        );
    }

    function logBuy(
        Storage.State storage state,
        Actions.BuyArgs memory args,
        Types.Wei memory takerWei,
        Types.Wei memory makerWei
    )
        internal
    {
        emit LogBuy(
            args.account.owner,
            args.account.number,
            args.takerMarket,
            args.makerMarket,
            getBalanceUpdate(
                state,
                args.account,
                args.takerMarket,
                takerWei
            ),
            getBalanceUpdate(
                state,
                args.account,
                args.makerMarket,
                makerWei
            ),
            args.exchangeWrapper
        );
    }

    function logSell(
        Storage.State storage state,
        Actions.SellArgs memory args,
        Types.Wei memory takerWei,
        Types.Wei memory makerWei
    )
        internal
    {
        emit LogSell(
            args.account.owner,
            args.account.number,
            args.takerMarket,
            args.makerMarket,
            getBalanceUpdate(
                state,
                args.account,
                args.takerMarket,
                takerWei
            ),
            getBalanceUpdate(
                state,
                args.account,
                args.makerMarket,
                makerWei
            ),
            args.exchangeWrapper
        );
    }

    function logTrade(
        Storage.State storage state,
        Actions.TradeArgs memory args,
        Types.Wei memory inputWei,
        Types.Wei memory outputWei
    )
        internal
    {
        BalanceUpdate[4] memory updates = [
            getBalanceUpdate(
                state,
                args.takerAccount,
                args.inputMarket,
                inputWei.negative()
            ),
            getBalanceUpdate(
                state,
                args.takerAccount,
                args.outputMarket,
                outputWei.negative()
            ),
            getBalanceUpdate(
                state,
                args.makerAccount,
                args.inputMarket,
                inputWei
            ),
            getBalanceUpdate(
                state,
                args.makerAccount,
                args.outputMarket,
                outputWei
            )
        ];

        emit LogTrade(
            args.takerAccount.owner,
            args.takerAccount.number,
            args.makerAccount.owner,
            args.makerAccount.number,
            args.inputMarket,
            args.outputMarket,
            updates[0],
            updates[1],
            updates[2],
            updates[3],
            args.autoTrader
        );
    }

    function logCall(
        Actions.CallArgs memory args
    )
        internal
    {
        emit LogCall(
            args.account.owner,
            args.account.number,
            args.callee
        );
    }

    function logLiquidate(
        Storage.State storage state,
        Actions.LiquidateArgs memory args,
        Types.Wei memory heldWei,
        Types.Wei memory owedWei
    )
        internal
    {
        BalanceUpdate memory solidHeldUpdate = getBalanceUpdate(
            state,
            args.solidAccount,
            args.heldMarket,
            heldWei.negative()
        );
        BalanceUpdate memory solidOwedUpdate = getBalanceUpdate(
            state,
            args.solidAccount,
            args.owedMarket,
            owedWei.negative()
        );
        BalanceUpdate memory liquidHeldUpdate = getBalanceUpdate(
            state,
            args.liquidAccount,
            args.heldMarket,
            heldWei
        );
        BalanceUpdate memory liquidOwedUpdate = getBalanceUpdate(
            state,
            args.liquidAccount,
            args.owedMarket,
            owedWei
        );

        emit LogLiquidate(
            args.solidAccount.owner,
            args.solidAccount.number,
            args.liquidAccount.owner,
            args.liquidAccount.number,
            args.heldMarket,
            args.owedMarket,
            solidHeldUpdate,
            solidOwedUpdate,
            liquidHeldUpdate,
            liquidOwedUpdate
        );
    }

    function logVaporize(
        Storage.State storage state,
        Actions.VaporizeArgs memory args,
        Types.Wei memory heldWei,
        Types.Wei memory owedWei,
        Types.Wei memory excessWei
    )
        internal
    {
        BalanceUpdate memory solidHeldUpdate = getBalanceUpdate(
            state,
            args.solidAccount,
            args.heldMarket,
            heldWei.negative()
        );
        BalanceUpdate memory solidOwedUpdate = getBalanceUpdate(
            state,
            args.solidAccount,
            args.owedMarket,
            owedWei.negative()
        );
        BalanceUpdate memory vaporOwedUpdate = getBalanceUpdate(
            state,
            args.vaporAccount,
            args.owedMarket,
            owedWei.add(excessWei)
        );

        emit LogVaporize(
            args.solidAccount.owner,
            args.solidAccount.number,
            args.vaporAccount.owner,
            args.vaporAccount.number,
            args.heldMarket,
            args.owedMarket,
            solidHeldUpdate,
            solidOwedUpdate,
            vaporOwedUpdate
        );
    }

    // ============ Private Functions ============

    function getBalanceUpdate(
        Storage.State storage state,
        Account.Info memory account,
        uint256 market,
        Types.Wei memory deltaWei
    )
        private
        view
        returns (BalanceUpdate memory)
    {
        return BalanceUpdate({
            deltaWei: deltaWei,
            newPar: state.getPar(account, market)
        });
    }
}

/*

    Copyright 2021 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;


library EnumerableSet {

    struct Set {
        // Storage of set values
        uint256[] _values;
        // Value to the index in `_values` array, plus 1 because index 0 means a value is not in the set.
        mapping(uint256 => uint256) _valueToIndexMap;
    }

    /**
    * @dev Add a value to a set. O(1).
     *
     * @return true if the value was added to the set, that is if it was not already present.
     */
    function add(Set storage set, uint256 value) internal returns (bool) {
        if (!contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._valueToIndexMap[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * @return true if the value was removed from the set, that is if it was present.
     */
    function remove(Set storage set, uint256 value) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._valueToIndexMap[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                uint256 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._valueToIndexMap[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored, which is the last index
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._valueToIndexMap[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Set storage set, uint256 value) internal view returns (bool) {
        return set._valueToIndexMap[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value at the corresponding index. O(1).
     */
    function getAtIndex(Set storage set, uint256 index) internal view returns (uint256) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Set storage set) internal view returns (uint256[] memory) {
        return set._values;
    }

}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Require } from "./Require.sol";


/**
 * @title Math
 * @author dYdX
 *
 * Library for non-standard Math functions
 */
library DolomiteMarginMath {
    using SafeMath for uint256;

    // ============ Constants ============

    bytes32 constant FILE = "Math";

    // ============ Library Functions ============

    /*
     * Return target * (numerator / denominator).
     */
    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
        internal
        pure
        returns (uint256)
    {
        return target.mul(numerator).div(denominator);
    }

    /*
     * Return target * (numerator / denominator), but rounded half-up. Meaning, a result of 101.1 rounds to 102
     * instead of 101.
     */
    function getPartialRoundUp(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
        internal
        pure
        returns (uint256)
    {
        if (target == 0 || numerator == 0) {
            // SafeMath will check for zero denominator
            return SafeMath.div(0, denominator);
        }
        return target.mul(numerator).sub(1).div(denominator).add(1);
    }

    /*
     * Return target * (numerator / denominator), but rounded half-up. Meaning, a result of 101.5 rounds to 102
     * instead of 101.
     */
    function getPartialRoundHalfUp(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
        internal
        pure
        returns (uint256)
    {
        if (target == 0 || numerator == 0) {
            // SafeMath will check for zero denominator
            return SafeMath.div(0, denominator);
        }
        uint result = target.mul(numerator);
        // round the denominator comparator up to ensure a fair comparison is done on the `result`'s modulo.
        // For example, 51 / 103 == 0; 51 % 103 == 51; ((103 - 1) / 2) + 1 == 52; 51 < 52, therefore no round up
        return result.div(denominator).add(result.mod(denominator) >= denominator.sub(1).div(2).add(1) ? 1 : 0);
    }

    function to128(
        uint256 number
    )
        internal
        pure
        returns (uint128)
    {
        uint128 result = uint128(number);
        Require.that(
            result == number,
            FILE,
            "Unsafe cast to uint128",
            number
        );
        return result;
    }

    function to96(
        uint256 number
    )
        internal
        pure
        returns (uint96)
    {
        uint96 result = uint96(number);
        Require.that(
            result == number,
            FILE,
            "Unsafe cast to uint96",
            number
        );
        return result;
    }

    function to32(
        uint256 number
    )
        internal
        pure
        returns (uint32)
    {
        uint32 result = uint32(number);
        Require.that(
            result == number,
            FILE,
            "Unsafe cast to uint32",
            number
        );
        return result;
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { DolomiteMarginMath } from "./DolomiteMarginMath.sol";


/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant BASE = 10**18;

    // ============ Structs ============

    struct D256 {
        uint256 value;
    }

    // ============ Functions ============

    function one()
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: BASE });
    }

    function onePlus(
        D256 memory d
    )
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: d.value.add(BASE) });
    }

    function mul(
        uint256 target,
        D256 memory d
    )
        internal
        pure
        returns (uint256)
    {
        return DolomiteMarginMath.getPartial(target, d.value, BASE);
    }

    function div(
        uint256 target,
        D256 memory d
    )
        internal
        pure
        returns (uint256)
    {
        return DolomiteMarginMath.getPartial(target, BASE, d.value);
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Bits } from "./Bits.sol";
import { Interest } from "./Interest.sol";
import { Monetary } from "./Monetary.sol";
import { Require } from "./Require.sol";


/**
 * @title Cache
 * @author dYdX
 *
 * Library for caching information about markets
 */
library Cache {

    // ============ Constants ============

    bytes32 internal constant FILE = "Cache";

    // ============ Structs ============

    struct MarketInfo {
        uint marketId;
        address token;
        bool isClosing;
        uint128 borrowPar;
        uint128 supplyPar;
        Interest.Index index;
        Monetary.Price price;
    }

    struct MarketCache {
        MarketInfo[] markets;
        uint256[] marketBitmaps;
        uint256 marketsLength;
    }

    // ============ Setter Functions ============

    /**
     * Initialize an empty cache for some given number of total markets.
     */
    function create(
        uint256 numMarkets
    )
        internal
        pure
        returns (MarketCache memory)
    {
        return MarketCache({
            markets: new MarketInfo[](0),
            marketBitmaps: Bits.createBitmaps(numMarkets),
            marketsLength: 0
        });
    }

    // ============ Getter Functions ============

    function getNumMarkets(
        MarketCache memory cache
    )
        internal
        pure
        returns (uint256)
    {
        return cache.markets.length;
    }

    function hasMarket(
        MarketCache memory cache,
        uint256 marketId
    )
        internal
        pure
        returns (bool)
    {
        return Bits.hasBit(cache.marketBitmaps, marketId);
    }

    function get(
        MarketCache memory cache,
        uint256 marketId
    )
        internal
        pure
        returns (MarketInfo memory)
    {
        Require.that(
            cache.markets.length > 0,
            FILE,
            "not initialized"
        );
        return _getInternal(
            cache.markets,
            0,
            cache.marketsLength,
            marketId
        );
    }

    function set(
        MarketCache memory cache,
        uint256 marketId
    )
        internal
        pure
    {
        // Devs should not be able to call this function once the `markets` array has been initialized (non-zero length)
        Require.that(
            cache.markets.length == 0,
            FILE,
            "already initialized"
        );

        Bits.setBit(cache.marketBitmaps, marketId);

        cache.marketsLength += 1;
    }

    function getAtIndex(
        MarketCache memory cache,
        uint256 index
    )
        internal
        pure
        returns (MarketInfo memory)
    {
        Require.that(
            index < cache.markets.length,
            FILE,
            "invalid index",
            index,
            cache.markets.length
        );
        return cache.markets[index];
    }

    // ============ Private Functions ============

    function _getInternal(
        MarketInfo[] memory data,
        uint beginInclusive,
        uint endExclusive,
        uint marketId
    ) private pure returns (MarketInfo memory) {
        uint len = endExclusive - beginInclusive;
        // If length equals 0 OR length equals 1 but the item wasn't found, revert
        assert(!(len == 0 || (len == 1 && data[beginInclusive].marketId != marketId)));

        uint mid = beginInclusive + len / 2;
        uint midMarketId = data[mid].marketId;
        if (marketId < midMarketId) {
            return _getInternal(
                data,
                beginInclusive,
                mid,
                marketId
            );
        } else if (marketId > midMarketId) {
            return _getInternal(
                data,
                mid + 1,
                endExclusive,
                marketId
            );
        } else {
            return data[mid];
        }
    }

}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Require } from "./Require.sol";


/**
 * @title Bits
 * @author Dolomite
 *
 * Library for caching information about markets
 */
library Bits {

    // ============ Constants ============

    uint internal constant ONE = 1;
    uint256 internal constant MAX_UINT_BITS = 256;

    // ============ Functions ============

    function createBitmaps(uint maxLength) internal pure returns (uint[] memory) {
        return new uint[]((maxLength / MAX_UINT_BITS) + ONE);
    }

    function getMarketIdFromBit(
        uint index,
        uint bit
    ) internal pure returns (uint) {
        return (MAX_UINT_BITS * index) + bit;
    }

    function setBit(
        uint[] memory bitmaps,
        uint marketId
    ) internal pure {
        uint bucketIndex = marketId / MAX_UINT_BITS;
        uint indexFromRight = marketId % MAX_UINT_BITS;
        bitmaps[bucketIndex] |= (ONE << indexFromRight);
    }

    function hasBit(
        uint[] memory bitmaps,
        uint marketId
    ) internal pure returns (bool) {
        uint bucketIndex = marketId / MAX_UINT_BITS;
        uint indexFromRight = marketId % MAX_UINT_BITS;
        uint bit = bitmaps[bucketIndex] & (ONE << indexFromRight);
        return bit > 0;
    }

    function unsetBit(
        uint bitmap,
        uint bit
    ) internal pure returns (uint) {
        return bitmap - (ONE << bit);
    }

    // solium-disable security/no-assign-params
    function getLeastSignificantBit(uint256 x) internal pure returns (uint) {
        // gas usage peaks at 350 per call

        uint lsb = 255;

        if (x & uint128(-1) > 0) {
            lsb -= 128;
        } else {
            x >>= 128;
        }

        if (x & uint64(-1) > 0) {
            lsb -= 64;
        } else {
            x >>= 64;
        }

        if (x & uint32(-1) > 0) {
            lsb -= 32;
        } else {
            x >>= 32;
        }

        if (x & uint16(-1) > 0) {
            lsb -= 16;
        } else {
            x >>= 16;
        }

        if (x & uint8(-1) > 0) {
            lsb -= 8;
        } else {
            x >>= 8;
        }

        if (x & 0xf > 0) {
            lsb -= 4;
        } else {
            x >>= 4;
        }

        if (x & 0x3 > 0) {
            lsb -= 2;
        } else {
            x >>= 2;
            // solium-enable security/no-assign-params
        }

        if (x & 0x1 > 0) {
            lsb -= 1;
        }

        return lsb;
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Account } from "./Account.sol";
import { Types } from "./Types.sol";


/**
 * @title Actions
 * @author dYdX
 *
 * Library that defines and parses valid Actions
 */
library Actions {

    // ============ Constants ============

    bytes32 constant FILE = "Actions";

    // ============ Enums ============

    enum ActionType {
        Deposit,   // supply tokens
        Withdraw,  // borrow tokens
        Transfer,  // transfer balance between accounts
        Buy,       // buy an amount of some token (externally)
        Sell,      // sell an amount of some token (externally)
        Trade,     // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize,  // use excess tokens to zero-out a completely negative account
        Call       // send arbitrary data to an address
    }

    enum AccountLayout {
        OnePrimary,
        TwoPrimary,
        PrimaryAndSecondary
    }

    enum MarketLayout {
        ZeroMarkets,
        OneMarket,
        TwoMarkets
    }

    // ============ Structs ============

    /*
     * Arguments that are passed to DolomiteMargin in an ordered list as part of a single operation.
     * Each ActionArgs has an actionType which specifies which action struct that this data will be
     * parsed into before being processed.
     */
    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        Types.AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    // ============ Action Types ============

    /*
     * Moves tokens from an address to DolomiteMargin. Can either repay a borrow or provide additional supply.
     */
    struct DepositArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 market;
        address from;
    }

    /*
     * Moves tokens from DolomiteMargin to another address. Can either borrow tokens or reduce the amount
     * previously supplied.
     */
    struct WithdrawArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 market;
        address to;
    }

    /*
     * Transfers balance between two accounts. The msg.sender must be an operator for both accounts.
     * The amount field applies to accountOne.
     * This action does not require any token movement since the trade is done internally to DolomiteMargin.
     */
    struct TransferArgs {
        Types.AssetAmount amount;
        Account.Info accountOne;
        Account.Info accountTwo;
        uint256 market;
    }

    /*
     * Acquires a certain amount of tokens by spending other tokens. Sends takerMarket tokens to the
     * specified exchangeWrapper contract and expects makerMarket tokens in return. The amount field
     * applies to the makerMarket.
     */
    struct BuyArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 makerMarket;
        uint256 takerMarket;
        address exchangeWrapper;
        bytes orderData;
    }

    /*
     * Spends a certain amount of tokens to acquire other tokens. Sends takerMarket tokens to the
     * specified exchangeWrapper and expects makerMarket tokens in return. The amount field applies
     * to the takerMarket.
     */
    struct SellArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 takerMarket;
        uint256 makerMarket;
        address exchangeWrapper;
        bytes orderData;
    }

    /*
     * Trades balances between two accounts using any external contract that implements the
     * AutoTrader interface. The AutoTrader contract must be an operator for the makerAccount (for
     * which it is trading on-behalf-of). The amount field applies to the makerAccount and the
     * inputMarket. This proposed change to the makerAccount is passed to the AutoTrader which will
     * quote a change for the makerAccount in the outputMarket (or will disallow the trade).
     * This action does not require any token movement since the trade is done internally to DolomiteMargin.
     */
    struct TradeArgs {
        Types.AssetAmount amount;
        Account.Info takerAccount;
        Account.Info makerAccount;
        uint256 inputMarket;
        uint256 outputMarket;
        address autoTrader;
        bytes tradeData;
    }

    /*
     * Each account must maintain a certain margin-ratio (specified globally). If the account falls
     * below this margin-ratio, it can be liquidated by any other account. This allows anyone else
     * (arbitrageurs) to repay any borrowed asset (owedMarket) of the liquidating account in
     * exchange for any collateral asset (heldMarket) of the liquidAccount. The ratio is determined
     * by the price ratio (given by the oracles) plus a spread (specified globally). Liquidating an
     * account also sets a flag on the account that the account is being liquidated. This allows
     * anyone to continue liquidating the account until there are no more borrows being taken by the
     * liquidating account. Liquidators do not have to liquidate the entire account all at once but
     * can liquidate as much as they choose. The liquidating flag allows liquidators to continue
     * liquidating the account even if it becomes collateralized through partial liquidation or
     * price movement.
     */
    struct LiquidateArgs {
        Types.AssetAmount amount;
        Account.Info solidAccount;
        Account.Info liquidAccount;
        uint256 owedMarket;
        uint256 heldMarket;
    }

    /*
     * Similar to liquidate, but vaporAccounts are accounts that have only negative balances remaining. The arbitrageur
     * pays back the negative asset (owedMarket) of the vaporAccount in exchange for a collateral asset (heldMarket) at
     * a favorable spread. However, since the liquidAccount has no collateral assets, the collateral must come from
     * DolomiteMargin's excess tokens.
     */
    struct VaporizeArgs {
        Types.AssetAmount amount;
        Account.Info solidAccount;
        Account.Info vaporAccount;
        uint256 owedMarket;
        uint256 heldMarket;
    }

    /*
     * Passes arbitrary bytes of data to an external contract that implements the Callee interface.
     * Does not change any asset amounts. This function may be useful for setting certain variables
     * on layer-two contracts for certain accounts without having to make a separate Ethereum
     * transaction for doing so. Also, the second-layer contracts can ensure that the call is coming
     * from an operator of the particular account.
     */
    struct CallArgs {
        Account.Info account;
        address callee;
        bytes data;
    }

    // ============ Helper Functions ============

    function getMarketLayout(
        ActionType actionType
    )
        internal
        pure
        returns (MarketLayout)
    {
        if (
            actionType == Actions.ActionType.Deposit
            || actionType == Actions.ActionType.Withdraw
            || actionType == Actions.ActionType.Transfer
        ) {
            return MarketLayout.OneMarket;
        }
        else if (actionType == Actions.ActionType.Call) {
            return MarketLayout.ZeroMarkets;
        }
        return MarketLayout.TwoMarkets;
    }

    function getAccountLayout(
        ActionType actionType
    )
        internal
        pure
        returns (AccountLayout)
    {
        if (
            actionType == Actions.ActionType.Transfer
            || actionType == Actions.ActionType.Trade
        ) {
            return AccountLayout.TwoPrimary;
        } else if (
            actionType == Actions.ActionType.Liquidate
            || actionType == Actions.ActionType.Vaporize
        ) {
            return AccountLayout.PrimaryAndSecondary;
        }
        return AccountLayout.OnePrimary;
    }

    // ============ Parsing Functions ============

    function parseDepositArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (DepositArgs memory)
    {
        return DepositArgs({
            amount: args.amount,
            account: accounts[args.accountId],
            market: args.primaryMarketId,
            from: args.otherAddress
        });
    }

    function parseWithdrawArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (WithdrawArgs memory)
    {
        return WithdrawArgs({
            amount: args.amount,
            account: accounts[args.accountId],
            market: args.primaryMarketId,
            to: args.otherAddress
        });
    }

    function parseTransferArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (TransferArgs memory)
    {
        return TransferArgs({
            amount: args.amount,
            accountOne: accounts[args.accountId],
            accountTwo: accounts[args.otherAccountId],
            market: args.primaryMarketId
        });
    }

    function parseBuyArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (BuyArgs memory)
    {
        return BuyArgs({
            amount: args.amount,
            account: accounts[args.accountId],
            makerMarket: args.primaryMarketId,
            takerMarket: args.secondaryMarketId,
            exchangeWrapper: args.otherAddress,
            orderData: args.data
        });
    }

    function parseSellArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (SellArgs memory)
    {
        return SellArgs({
            amount: args.amount,
            account: accounts[args.accountId],
            takerMarket: args.primaryMarketId,
            makerMarket: args.secondaryMarketId,
            exchangeWrapper: args.otherAddress,
            orderData: args.data
        });
    }

    function parseTradeArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (TradeArgs memory)
    {
        return TradeArgs({
            amount: args.amount,
            takerAccount: accounts[args.accountId],
            makerAccount: accounts[args.otherAccountId],
            inputMarket: args.primaryMarketId,
            outputMarket: args.secondaryMarketId,
            autoTrader: args.otherAddress,
            tradeData: args.data
        });
    }

    function parseLiquidateArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (LiquidateArgs memory)
    {
        return LiquidateArgs({
            amount: args.amount,
            solidAccount: accounts[args.accountId],
            liquidAccount: accounts[args.otherAccountId],
            owedMarket: args.primaryMarketId,
            heldMarket: args.secondaryMarketId
        });
    }

    function parseVaporizeArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (VaporizeArgs memory)
    {
        return VaporizeArgs({
            amount: args.amount,
            solidAccount: accounts[args.accountId],
            vaporAccount: accounts[args.otherAccountId],
            owedMarket: args.primaryMarketId,
            heldMarket: args.secondaryMarketId
        });
    }

    function parseCallArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (CallArgs memory)
    {
        return CallArgs({
            account: accounts[args.accountId],
            callee: args.otherAddress,
            data: args.data
        });
    }
}

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Monetary } from "../lib/Monetary.sol";


/**
 * @title IPriceOracle
 * @author dYdX
 *
 * Interface that Price Oracles for DolomiteMargin must implement in order to report prices.
 */
contract IPriceOracle {

    // ============ Constants ============

    uint256 public constant ONE_DOLLAR = 10 ** 36;

    // ============ Public Functions ============

    /**
     * Get the price of a token
     *
     * @param  token  The ERC20 token address of the market
     * @return        The USD price of a base unit of the token, then multiplied by 10^36.
     *                So a USD-stable coin with 18 decimal places would return 10^18.
     *                This is the price of the base unit rather than the price of a "human-readable"
     *                token amount. Every ERC20 may have a different number of decimals.
     */
    function getPrice(
        address token
    )
        public
        view
        returns (Monetary.Price memory);
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Interest } from "../lib/Interest.sol";


/**
 * @title IInterestSetter
 * @author dYdX
 *
 * Interface that Interest Setters for DolomiteMargin must implement in order to report interest rates.
 */
interface IInterestSetter {

    // ============ Public Functions ============

    /**
     * Get the interest rate of a token given some borrowed and supplied amounts
     *
     * @param  token        The address of the ERC20 token for the market
     * @param  borrowWei    The total borrowed token amount for the market
     * @param  supplyWei    The total supplied token amount for the market
     * @return              The interest rate per second
     */
    function getInterestRate(
        address token,
        uint256 borrowWei,
        uint256 supplyWei
    )
        external
        view
        returns (Interest.Rate memory);
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title IERC20
 * @author dYdX
 *
 * Interface for using ERC20 Tokens. We have to use a special interface to call ERC20 functions so
 * that we don't automatically revert when calling non-compliant tokens that have no return value for
 * transfer(), transferFrom(), or approve().
 */
contract IERC20Detailed is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

/*

    Copyright 2021 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import { IInterestSetter } from "../interfaces/IInterestSetter.sol";
import { IPriceOracle } from "../interfaces/IPriceOracle.sol";

import { Account } from "../lib/Account.sol";
import { Actions } from "../lib/Actions.sol";
import { Decimal } from "../lib/Decimal.sol";
import { Interest } from "../lib/Interest.sol";
import { Monetary } from "../lib/Monetary.sol";
import { Storage } from "../lib/Storage.sol";
import { Types } from "../lib/Types.sol";

interface IDolomiteMargin {

    // ============ Getters for Markets ============

    /**
     * Get the ERC20 token address for a market.
     *
     * @param  token    The token to query
     * @return          The token's marketId if the token is valid
     */
    function getMarketIdByTokenAddress(
        address token
    ) external view returns (uint256);

    /**
     * Get the ERC20 token address for a market.
     *
     * @param  marketId  The market to query
     * @return           The token address
     */
    function getMarketTokenAddress(
        uint256 marketId
    ) external view returns (address);

    /**
     * Return true if a particular market is in closing mode. Additional borrows cannot be taken
     * from a market that is closing.
     *
     * @param  marketId  The market to query
     * @return           True if the market is closing
     */
    function getMarketIsClosing(
        uint256 marketId
    )
    external
    view
    returns (bool);

    /**
     * Get the price of the token for a market.
     *
     * @param  marketId  The market to query
     * @return           The price of each atomic unit of the token
     */
    function getMarketPrice(
        uint256 marketId
    ) external view returns (Monetary.Price memory);

    /**
     * Get the total number of markets.
     *
     * @return  The number of markets
     */
    function getNumMarkets() external view returns (uint256);

    /**
     * Get the total principal amounts (borrowed and supplied) for a market.
     *
     * @param  marketId  The market to query
     * @return           The total principal amounts
     */
    function getMarketTotalPar(
        uint256 marketId
    ) external view returns (Types.TotalPar memory);

    /**
     * Get the most recently cached interest index for a market.
     *
     * @param  marketId  The market to query
     * @return           The most recent index
     */
    function getMarketCachedIndex(
        uint256 marketId
    ) external view returns (Interest.Index memory);

    /**
     * Get the interest index for a market if it were to be updated right now.
     *
     * @param  marketId  The market to query
     * @return           The estimated current index
     */
    function getMarketCurrentIndex(
        uint256 marketId
    ) external view returns (Interest.Index memory);

    /**
     * Get the price oracle address for a market.
     *
     * @param  marketId  The market to query
     * @return           The price oracle address
     */
    function getMarketPriceOracle(
        uint256 marketId
    ) external view returns (IPriceOracle);

    /**
     * Get the interest-setter address for a market.
     *
     * @param  marketId  The market to query
     * @return           The interest-setter address
     */
    function getMarketInterestSetter(
        uint256 marketId
    ) external view returns (IInterestSetter);

    /**
     * Get the margin premium for a market. A margin premium makes it so that any positions that
     * include the market require a higher collateralization to avoid being liquidated.
     *
     * @param  marketId  The market to query
     * @return           The market's margin premium
     */
    function getMarketMarginPremium(
        uint256 marketId
    ) external view returns (Decimal.D256 memory);

    /**
     * Get the spread premium for a market. A spread premium makes it so that any liquidations
     * that include the market have a higher spread than the global default.
     *
     * @param  marketId  The market to query
     * @return           The market's spread premium
     */
    function getMarketSpreadPremium(
        uint256 marketId
    ) external view returns (Decimal.D256 memory);

    /**
     * Return true if this market can be removed and its ID can be recycled and reused
     *
     * @param  marketId  The market to query
     * @return           True if the market is recyclable
     */
    function getMarketIsRecyclable(
        uint256 marketId
    ) external view returns (bool);

    /**
     * Gets the recyclable markets, up to `n` length. If `n` is greater than the length of the list, 0's are returned
     * for the empty slots.
     *
     * @param  n    The number of markets to get, bounded by the linked list being smaller than `n`
     * @return      The list of recyclable markets, in the same order held by the linked list
     */
    function getRecyclableMarkets(
        uint256 n
    ) external view returns (uint[] memory);

    /**
     * Get the current borrower interest rate for a market.
     *
     * @param  marketId  The market to query
     * @return           The current interest rate
     */
    function getMarketInterestRate(
        uint256 marketId
    ) external view returns (Interest.Rate memory);

    /**
     * Get basic information about a particular market.
     *
     * @param  marketId  The market to query
     * @return           A Storage.Market struct with the current state of the market
     */
    function getMarket(
        uint256 marketId
    ) external view returns (Storage.Market memory);

    /**
     * Get comprehensive information about a particular market.
     *
     * @param  marketId  The market to query
     * @return           A tuple containing the values:
     *                    - A Storage.Market struct with the current state of the market
     *                    - The current estimated interest index
     *                    - The current token price
     *                    - The current market interest rate
     */
    function getMarketWithInfo(
        uint256 marketId
    )
    external
    view
    returns (
        Storage.Market memory,
        Interest.Index memory,
        Monetary.Price memory,
        Interest.Rate memory
    );

    /**
     * Get the number of excess tokens for a market. The number of excess tokens is calculated by taking the current
     * number of tokens held in DolomiteMargin, adding the number of tokens owed to DolomiteMargin by borrowers, and
     * subtracting the number of tokens owed to suppliers by DolomiteMargin.
     *
     * @param  marketId  The market to query
     * @return           The number of excess tokens
     */
    function getNumExcessTokens(
        uint256 marketId
    ) external view returns (Types.Wei memory);

    // ============ Getters for Accounts ============

    /**
     * Get the principal value for a particular account and market.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The principal value
     */
    function getAccountPar(
        Account.Info calldata account,
        uint256 marketId
    ) external view returns (Types.Par memory);

    /**
     * Get the principal value for a particular account and market, with no check the market is valid. Meaning, markets
     * that don't exist return 0.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The principal value
     */
    function getAccountParNoMarketCheck(
        Account.Info calldata account,
        uint256 marketId
    ) external view returns (Types.Par memory);

    /**
     * Get the token balance for a particular account and market.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The token amount
     */
    function getAccountWei(
        Account.Info calldata account,
        uint256 marketId
    ) external view returns (Types.Wei memory);

    /**
     * Get the status of an account (Normal, Liquidating, or Vaporizing).
     *
     * @param  account  The account to query
     * @return          The account's status
     */
    function getAccountStatus(
        Account.Info calldata account
    ) external view returns (Account.Status);

    /**
     * Get a list of markets that have a non-zero balance for an account
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountMarketsWithBalances(
        Account.Info calldata account
    ) external view returns (uint256[] memory);

    /**
     * Get the number of markets that have a non-zero balance for an account
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountNumberOfMarketsWithBalances(
        Account.Info calldata account
    ) external view returns (uint256);

    /**
     * Get the marketId for an account's market with a non-zero balance at the given index
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountMarketWithBalanceAtIndex(
        Account.Info calldata account,
        uint256 index
    ) external view returns (uint256);

    /**
     * Get the number of markets with which an account has a negative balance.
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountNumberOfMarketsWithDebt(
        Account.Info calldata account
    ) external view returns (uint256);

    /**
     * Get the total supplied and total borrowed value of an account.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The supplied value of the account
     *                   - The borrowed value of the account
     */
    function getAccountValues(
        Account.Info calldata account
    ) external view returns (Monetary.Value memory, Monetary.Value memory);

    /**
     * Get the total supplied and total borrowed values of an account adjusted by the marginPremium
     * of each market. Supplied values are divided by (1 + marginPremium) for each market and
     * borrowed values are multiplied by (1 + marginPremium) for each market. Comparing these
     * adjusted values gives the margin-ratio of the account which will be compared to the global
     * margin-ratio when determining if the account can be liquidated.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The supplied value of the account (adjusted for marginPremium)
     *                   - The borrowed value of the account (adjusted for marginPremium)
     */
    function getAdjustedAccountValues(
        Account.Info calldata account
    ) external view returns (Monetary.Value memory, Monetary.Value memory);

    /**
     * Get an account's summary for each market.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The market IDs for each market
     *                   - The ERC20 token address for each market
     *                   - The account's principal value for each market
     *                   - The account's (supplied or borrowed) number of tokens for each market
     */
    function getAccountBalances(
        Account.Info calldata account
    ) external view returns (uint[] memory, address[] memory, Types.Par[] memory, Types.Wei[] memory);

    // ============ Getters for Account Permissions ============

    /**
     * Return true if a particular address is approved as an operator for an owner's accounts.
     * Approved operators can act on the accounts of the owner as if it were the operator's own.
     *
     * @param  owner     The owner of the accounts
     * @param  operator  The possible operator
     * @return           True if operator is approved for owner's accounts
     */
    function getIsLocalOperator(
        address owner,
        address operator
    ) external view returns (bool);

    /**
     * Return true if a particular address is approved as a global operator. Such an address can
     * act on any account as if it were the operator's own.
     *
     * @param  operator  The address to query
     * @return           True if operator is a global operator
     */
    function getIsGlobalOperator(
        address operator
    ) external view returns (bool);

    /**
     * Checks if the autoTrader can only be called invoked by a global operator
     *
     * @param autoTrader    The trader that should be checked for special call privileges.
     */
    function getIsAutoTraderSpecial(address autoTrader) external view returns (bool);

    // ============ Getters for Risk Params ============

    /**
     * Get the global minimum margin-ratio that every position must maintain to prevent being
     * liquidated.
     *
     * @return  The global margin-ratio
     */
    function getMarginRatio() external view returns (Decimal.D256 memory);

    /**
     * Get the global liquidation spread. This is the spread between oracle prices that incentivizes
     * the liquidation of risky positions.
     *
     * @return  The global liquidation spread
     */
    function getLiquidationSpread() external view returns (Decimal.D256 memory);

    /**
     * Get the adjusted liquidation spread for some market pair. This is equal to the global
     * liquidation spread multiplied by (1 + spreadPremium) for each of the two markets.
     *
     * @param  heldMarketId  The market for which the account has collateral
     * @param  owedMarketId  The market for which the account has borrowed tokens
     * @return               The adjusted liquidation spread
     */
    function getLiquidationSpreadForPair(
        uint256 heldMarketId,
        uint256 owedMarketId
    ) external view returns (Decimal.D256 memory);

    /**
     * Get the global earnings-rate variable that determines what percentage of the interest paid
     * by borrowers gets passed-on to suppliers.
     *
     * @return  The global earnings rate
     */
    function getEarningsRate() external view returns (Decimal.D256 memory);

    /**
     * Get the global minimum-borrow value which is the minimum value of any new borrow on DolomiteMargin.
     *
     * @return  The global minimum borrow value
     */
    function getMinBorrowedValue() external view returns (Monetary.Value memory);

    /**
     * Get all risk parameters in a single struct.
     *
     * @return  All global risk parameters
     */
    function getRiskParams() external view returns (Storage.RiskParams memory);

    /**
     * Get all risk parameter limits in a single struct. These are the maximum limits at which the
     * risk parameters can be set by the admin of DolomiteMargin.
     *
     * @return  All global risk parameter limits
     */
    function getRiskLimits() external view returns (Storage.RiskLimits memory);

    // ============ Write Functions ============

    /**
     * The main entry-point to DolomiteMargin that allows users and contracts to manage accounts.
     * Take one or more actions on one or more accounts. The msg.sender must be the owner or
     * operator of all accounts except for those being liquidated, vaporized, or traded with.
     * One call to operate() is considered a singular "operation". Account collateralization is
     * ensured only after the completion of the entire operation.
     *
     * @param  accounts  A list of all accounts that will be used in this operation. Cannot contain
     *                   duplicates. In each action, the relevant account will be referred-to by its
     *                   index in the list.
     * @param  actions   An ordered list of all actions that will be taken in this operation. The
     *                   actions will be processed in order.
     */
    function operate(
        Account.Info[] calldata accounts,
        Actions.ActionArgs[] calldata actions
    ) external;

    /**
     * Approves/disapproves any number of operators. An operator is an external address that has the
     * same permissions to manipulate an account as the owner of the account. Operators are simply
     * addresses and therefore may either be externally-owned Ethereum accounts OR smart contracts.
     *
     * Operators are also able to act as AutoTrader contracts on behalf of the account owner if the
     * operator is a smart contract and implements the IAutoTrader interface.
     *
     * @param  args  A list of OperatorArgs which have an address and a boolean. The boolean value
     *               denotes whether to approve (true) or revoke approval (false) for that address.
     */
    function setOperators(
        Types.OperatorArg[] calldata args
    ) external;

}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    )
        external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity ^0.5.0;

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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

/*

    Copyright 2021 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IDolomiteMargin } from  "../../protocol/interfaces/IDolomiteMargin.sol";

import { Account } from "../../protocol/lib/Account.sol";
import { Actions } from "../../protocol/lib/Actions.sol";
import { Events } from "../../protocol/lib/Events.sol";
import { Interest } from "../../protocol/lib/Interest.sol";
import { Require } from "../../protocol/lib/Require.sol";
import { Types } from "../../protocol/lib/Types.sol";

import { AccountActionHelper } from "../helpers/AccountActionHelper.sol";
import { AccountBalanceHelper } from "../helpers/AccountBalanceHelper.sol";
import { AccountMarginHelper } from "../helpers/AccountMarginHelper.sol";
import { ERC20Helper } from "../helpers/ERC20Helper.sol";

import { TypedSignature } from "../lib/TypedSignature.sol";
import { DolomiteAmmLibrary } from "../lib/DolomiteAmmLibrary.sol";

import { IExpiry } from "../interfaces/IExpiry.sol";
import { IDolomiteAmmFactory } from "../interfaces/IDolomiteAmmFactory.sol";
import { IDolomiteAmmPair } from "../interfaces/IDolomiteAmmPair.sol";
import { IDolomiteAmmRouterProxy } from "../interfaces/IDolomiteAmmRouterProxy.sol";


/**
 * @title DolomiteAmmRouterProxy
 * @author Dolomite
 *
 * Contract for routing trades to the Dolomite AMM pools and potentially opening margin positions
 */
contract DolomiteAmmRouterProxy is IDolomiteAmmRouterProxy, ReentrancyGuard {
    using SafeMath for uint;
    using Types for Types.Wei;

    // ==================== Constants ====================

    bytes32 constant internal FILE = "DolomiteAmmRouterProxy";

    // ==================== Modifiers ====================

    modifier ensure(uint256 deadline) {
        Require.that(
            deadline >= block.timestamp,
            FILE,
            "deadline expired",
            deadline,
            block.timestamp
        );
        _;
    }

    // ============ State Variables ============

    IDolomiteMargin public DOLOMITE_MARGIN;
    IDolomiteAmmFactory public DOLOMITE_AMM_FACTORY;
    address public EXPIRY;

    constructor(
        address _dolomiteMargin,
        address _dolomiteAmmFactory,
        address _expiry
    ) public {
        DOLOMITE_MARGIN = IDolomiteMargin(_dolomiteMargin);
        DOLOMITE_AMM_FACTORY = IDolomiteAmmFactory(_dolomiteAmmFactory);
        EXPIRY = _expiry;
    }

    // ==================== External Functions ====================

    function getPairInitCodeHash() external view returns (bytes32) {
        return DolomiteAmmLibrary.getPairInitCodeHash(address(DOLOMITE_AMM_FACTORY));
    }

    function swapExactTokensForTokens(
        uint256 _accountNumber,
        uint256 _amountInWei,
        uint256 _amountOutMinWei,
        address[] calldata _tokenPath,
        uint256 _deadline,
        AccountBalanceHelper.BalanceCheckFlag _balanceCheckFlag
    )
    external
    ensure(_deadline) {
        _swapExactTokensForTokensAndModifyPosition(
            _initializeModifyPositionCache(
                msg.sender,
                ModifyPositionParams({
                    tradeAccountNumber : _accountNumber,
                    otherAccountNumber : _accountNumber,
                    amountIn : _toPositiveDeltaWeiAssetAmount(_amountInWei),
                    amountOut : _toPositiveDeltaWeiAssetAmount(_amountOutMinWei),
                    tokenPath : _tokenPath,
                    marginTransferToken : address(0),
                    marginTransferWei : 0,
                    isDepositIntoTradeAccount : false,
                    expiryTimeDelta : 0,
                    balanceCheckFlag: _balanceCheckFlag
                })
            )
        );
    }

    function getParamsForSwapExactTokensForTokens(
        address _account,
        uint256 _accountNumber,
        uint256 _amountInWei,
        uint256 _amountOutMinWei,
        address[] calldata _tokenPath
    )
    external view returns (Account.Info[] memory, Actions.ActionArgs[] memory) {
        return _getParamsForSwapExactTokensForTokens(
            _initializeModifyPositionCache(
                _account,
                ModifyPositionParams({
                    tradeAccountNumber : _accountNumber,
                    otherAccountNumber : _accountNumber,
                    amountIn : _toPositiveDeltaWeiAssetAmount(_amountInWei),
                    amountOut : _toPositiveDeltaWeiAssetAmount(_amountOutMinWei),
                    tokenPath : _tokenPath,
                    marginTransferToken : address(0),
                    marginTransferWei : 0,
                    isDepositIntoTradeAccount : false,
                    expiryTimeDelta : 0,
                    balanceCheckFlag : AccountBalanceHelper.BalanceCheckFlag.None
                })
            )
        );
    }

    function swapTokensForExactTokens(
        uint256 _accountNumber,
        uint256 _amountInMaxWei,
        uint256 _amountOutWei,
        address[] calldata _tokenPath,
        uint256 _deadline,
        AccountBalanceHelper.BalanceCheckFlag _balanceCheckFlag
    )
    external
    ensure(_deadline) {
        _swapTokensForExactTokensAndModifyPosition(
            _initializeModifyPositionCache(
                msg.sender,
                ModifyPositionParams({
                    tradeAccountNumber : _accountNumber,
                    otherAccountNumber : _accountNumber,
                    amountIn : _toPositiveDeltaWeiAssetAmount(_amountInMaxWei),
                    amountOut : _toPositiveDeltaWeiAssetAmount(_amountOutWei),
                    tokenPath : _tokenPath,
                    marginTransferToken : address(0),
                    marginTransferWei : 0,
                    isDepositIntoTradeAccount : false,
                    expiryTimeDelta : 0,
                    balanceCheckFlag : _balanceCheckFlag
                })
            )
        );
    }

    function getParamsForSwapTokensForExactTokens(
        address _account,
        uint256 _accountNumber,
        uint256 _amountInMaxWei,
        uint256 _amountOutWei,
        address[] calldata _tokenPath
    )
    external view returns (Account.Info[] memory, Actions.ActionArgs[] memory) {
        return _getParamsForSwapTokensForExactTokens(
            _initializeModifyPositionCache(
                _account,
                ModifyPositionParams({
                    tradeAccountNumber : _accountNumber,
                    otherAccountNumber : _accountNumber,
                    amountIn : _toPositiveDeltaWeiAssetAmount(_amountInMaxWei),
                    amountOut : _toPositiveDeltaWeiAssetAmount(_amountOutWei),
                    tokenPath : _tokenPath,
                    marginTransferToken : address(0),
                    marginTransferWei : 0,
                    isDepositIntoTradeAccount : false,
                    expiryTimeDelta : 0,
                    balanceCheckFlag : AccountBalanceHelper.BalanceCheckFlag.None
                })
            )
        );
    }

    // ==================== Public Functions ====================

    function addLiquidity(
        AddLiquidityParams memory _params,
        address _toAccount
    )
    public
    ensure(_params.deadline)
    returns (uint256 amountAWei, uint256 amountBWei, uint256 liquidity) {
        IDolomiteAmmFactory dolomiteAmmFactory = DOLOMITE_AMM_FACTORY;
        // create the pair if it doesn't exist yet
        if (dolomiteAmmFactory.getPair(_params.tokenA, _params.tokenB) == address(0)) {
            dolomiteAmmFactory.createPair(_params.tokenA, _params.tokenB);
        }

        (amountAWei, amountBWei) = getAddLiquidityAmounts(
            _params.tokenA,
            _params.tokenB,
            _params.amountADesiredWei,
            _params.amountBDesiredWei,
            _params.amountAMinWei,
            _params.amountBMinWei
        );
        address pair = DolomiteAmmLibrary.pairFor(address(dolomiteAmmFactory), _params.tokenA, _params.tokenB);

        IDolomiteMargin dolomiteMargin = DOLOMITE_MARGIN;
        uint256 marketIdA = dolomiteMargin.getMarketIdByTokenAddress(_params.tokenA);
        uint256 marketIdB = dolomiteMargin.getMarketIdByTokenAddress(_params.tokenB);

        // solium-disable indentation, arg-overflow
        {
            Account.Info[] memory accounts = new Account.Info[](2);
            accounts[0] = Account.Info(msg.sender, _params.fromAccountNumber);
            accounts[1] = Account.Info(pair, 0);

            Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](2);
            actions[0] = AccountActionHelper.encodeTransferAction(0, 1, marketIdA, amountAWei);
            actions[1] = AccountActionHelper.encodeTransferAction(0, 1, marketIdB, amountBWei);
            dolomiteMargin.operate(accounts, actions);
        }
        // solium-enable indentation, arg-overflow

        liquidity = IDolomiteAmmPair(pair).mint(_toAccount);

        if (
            _params.balanceCheckFlag == AccountBalanceHelper.BalanceCheckFlag.Both ||
            _params.balanceCheckFlag == AccountBalanceHelper.BalanceCheckFlag.From
        ) {
            AccountBalanceHelper.verifyBalanceIsNonNegative(
                dolomiteMargin,
                msg.sender,
                _params.fromAccountNumber,
                marketIdA
            );
            AccountBalanceHelper.verifyBalanceIsNonNegative(
                dolomiteMargin,
                msg.sender,
                _params.fromAccountNumber,
                marketIdB
            );
        }
    }

    function addLiquidityAndDepositIntoDolomite(
        AddLiquidityParams memory _params,
        uint256 _toAccountNumber
    )
    public
    ensure(_params.deadline)
    returns (uint256 amountAWei, uint256 amountBWei, uint256 liquidity) {
        (amountAWei, amountBWei, liquidity) = addLiquidity(
            _params,
            /* _toAccount = */ address(this) // solium-disable-line indentation
        );

        IDolomiteMargin dolomiteMargin = DOLOMITE_MARGIN;
        address pair = DOLOMITE_AMM_FACTORY.getPair(_params.tokenA, _params.tokenB);
        ERC20Helper.checkAllowanceAndApprove(pair, address(dolomiteMargin), liquidity);

        AccountActionHelper.deposit(
            dolomiteMargin,
            /* _accountOwner = */ msg.sender, // solium-disable-line indentation
            /* _fromAccount = */ address(this), // solium-disable-line indentation
            _toAccountNumber,
            dolomiteMargin.getMarketIdByTokenAddress(pair),
            _toPositiveDeltaWeiAssetAmount(liquidity)
        );
    }

    function getAddLiquidityAmounts(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesiredWei,
        uint256 _amountBDesiredWei,
        uint256 _amountAMinWei,
        uint256 _amountBMinWei
    ) public view returns (uint256 amountAWei, uint256 amountBWei) {
        (uint256 reserveAWei, uint256 reserveBWei) = DolomiteAmmLibrary.getReservesWei(
            address(DOLOMITE_AMM_FACTORY),
            _tokenA,
            _tokenB
        );
        if (reserveAWei == 0 && reserveBWei == 0) {
            (amountAWei, amountBWei) = (_amountADesiredWei, _amountBDesiredWei);
        } else {
            uint256 amountBOptimal = DolomiteAmmLibrary.quote(_amountADesiredWei, reserveAWei, reserveBWei);
            if (amountBOptimal <= _amountBDesiredWei) {
                Require.that(
                    amountBOptimal >= _amountBMinWei,
                    FILE,
                    "insufficient B amount",
                    amountBOptimal,
                    _amountBMinWei
                );
                (amountAWei, amountBWei) = (_amountADesiredWei, amountBOptimal);
            } else {
                uint256 amountAOptimal = DolomiteAmmLibrary.quote(_amountBDesiredWei, reserveBWei, reserveAWei);
                assert(amountAOptimal <= _amountADesiredWei);
                Require.that(
                    amountAOptimal >= _amountAMinWei,
                    FILE,
                    "insufficient A amount",
                    amountAOptimal,
                    _amountAMinWei
                );
                (amountAWei, amountBWei) = (amountAOptimal, _amountBDesiredWei);
            }
        }
    }

    function removeLiquidity(
        RemoveLiquidityParams memory _params,
        address _to
    ) public ensure(_params.deadline) returns (uint256 amountAWei, uint256 amountBWei) {
        address pair = _getPairFromParams(_params);
        // send liquidity to pair
        IDolomiteAmmPair(pair).transferFrom(msg.sender, pair, _params.liquidityWei);
        (amountAWei, amountBWei) = _removeLiquidity(_params, _to, pair);
    }

    function removeLiquidityWithPermit(
        RemoveLiquidityParams memory _params,
        address _to,
        PermitSignature memory _permit
    ) public returns (uint256 amountAWei, uint256 amountBWei) {
        address pair = _getPairFromParams(_params);
        IDolomiteAmmPair(pair).permit(
            msg.sender,
            address(this),
            _permit.approveMax ? uint(- 1) : _params.liquidityWei,
            _params.deadline,
            _permit.v,
            _permit.r,
            _permit.s
        );

        (amountAWei, amountBWei) = removeLiquidity(_params, _to);
    }

    function removeLiquidityFromWithinDolomite(
        RemoveLiquidityParams memory _params,
        uint256 _fromAccountNumber,
        AccountBalanceHelper.BalanceCheckFlag _balanceCheckFlag
    ) public ensure(_params.deadline) returns (uint256 amountAWei, uint256 amountBWei) {
        IDolomiteMargin dolomiteMargin = DOLOMITE_MARGIN;
        address pair = _getPairFromParams(_params);

        // initialized as a variable to prevent "stack too deep"
        Types.AssetAmount memory assetAmount = Types.AssetAmount({
            sign: false,
            denomination: Types.AssetDenomination.Wei,
            ref: _params.liquidityWei == uint(-1) ? Types.AssetReference.Target : Types.AssetReference.Delta,
            value: _params.liquidityWei == uint(-1) ? 0 : _params.liquidityWei
        });
        // send liquidity to pair
        AccountActionHelper.withdraw(
            dolomiteMargin,
            msg.sender,
            _fromAccountNumber,
            pair,
            dolomiteMargin.getMarketIdByTokenAddress(pair),
            assetAmount,
            _balanceCheckFlag
        );

        (amountAWei, amountBWei) = _removeLiquidity(_params, msg.sender, pair);
    }

    function swapExactTokensForTokensAndModifyPosition(
        ModifyPositionParams memory _params,
        uint256 _deadline
    ) public ensure(_deadline) {
        _swapExactTokensForTokensAndModifyPosition(_initializeModifyPositionCache(msg.sender, _params));
    }

    function swapTokensForExactTokensAndModifyPosition(
        ModifyPositionParams memory _params,
        uint256 _deadline
    ) public ensure(_deadline) {
        _swapTokensForExactTokensAndModifyPosition(_initializeModifyPositionCache(msg.sender, _params));
    }

    // *************************
    // ***** Internal Functions
    // *************************

    function _initializeModifyPositionCache(
        address _account,
        ModifyPositionParams memory _params
    ) internal view returns (ModifyPositionCache memory) {
        return ModifyPositionCache({
            params : _params,
            dolomiteMargin : DOLOMITE_MARGIN,
            ammFactory : DOLOMITE_AMM_FACTORY,
            account : _account,
            marketPath : new uint[](0),
            amountsWei : new uint[](0),
            marginDepositMarketId : uint(-1),
            marginDepositDeltaWei : 0
        });
    }

    function _getPairFromParams(RemoveLiquidityParams memory _params) internal view returns (address) {
        return DolomiteAmmLibrary.pairFor(address(DOLOMITE_AMM_FACTORY), _params.tokenA, _params.tokenB);
    }

    function _removeLiquidity(
        RemoveLiquidityParams memory _params,
        address _to,
        address _pair
    ) internal returns (uint256 amountAWei, uint256 amountBWei) {
        (uint256 amount0Wei, uint256 amount1Wei) = IDolomiteAmmPair(_pair).burn(_to, _params.toAccountNumber);
        (address token0,) = DolomiteAmmLibrary.sortTokens(_params.tokenA, _params.tokenB);
        (amountAWei, amountBWei) = _params.tokenA == token0 ? (amount0Wei, amount1Wei) : (amount1Wei, amount0Wei);
        Require.that(
            amountAWei >= _params.amountAMinWei,
            FILE,
            "insufficient A amount",
            amountAWei,
            _params.amountAMinWei
        );
        Require.that(
            amountBWei >= _params.amountBMinWei,
            FILE,
            "insufficient B amount",
            amountBWei,
            _params.amountBMinWei
        );
    }

    function _swapExactTokensForTokensAndModifyPosition(
        ModifyPositionCache memory _cache
    ) internal {
        (
            Account.Info[] memory accounts,
            Actions.ActionArgs[] memory actions
        ) = _getParamsForSwapExactTokensForTokens(_cache);

        _cache.dolomiteMargin.operate(accounts, actions);

        _verifyAllBalancesForTrade(_cache);

        _logEvents(_cache, accounts);
    }

    function _swapTokensForExactTokensAndModifyPosition(
        ModifyPositionCache memory _cache
    ) internal {
        (
            Account.Info[] memory accounts,
            Actions.ActionArgs[] memory actions
        ) = _getParamsForSwapTokensForExactTokens(_cache);

        _cache.dolomiteMargin.operate(accounts, actions);

        _verifyAllBalancesForTrade(_cache);

        _logEvents(_cache, accounts);
    }

    function _verifyAllBalancesForTrade(
        ModifyPositionCache memory _cache
    ) internal view {
        _verifySingleBalanceForTrade(_cache, _cache.marketPath[0]);
        _verifySingleBalanceForTrade(_cache, _cache.marketPath[_cache.marketPath.length - 1]);
        if (
            _cache.marginDepositMarketId != uint(-1)
            && _cache.marginDepositMarketId != _cache.marketPath[0]
            && _cache.marginDepositMarketId != _cache.marketPath[_cache.marketPath.length - 1]
        ) {
            _verifySingleBalanceForTrade(_cache, _cache.marginDepositMarketId);
        }
    }


    function _verifySingleBalanceForTrade(
        ModifyPositionCache memory _cache,
        uint256 _marketId
    ) internal view {
        if (
            _cache.params.balanceCheckFlag == AccountBalanceHelper.BalanceCheckFlag.Both
            || _cache.params.balanceCheckFlag == AccountBalanceHelper.BalanceCheckFlag.From
        ) {
            AccountBalanceHelper.verifyBalanceIsNonNegative(
                DOLOMITE_MARGIN,
                _cache.account,
                _cache.params.tradeAccountNumber,
                _marketId
            );
        }
        if (_cache.params.tradeAccountNumber != _cache.params.otherAccountNumber) {
            if (
                _cache.params.balanceCheckFlag == AccountBalanceHelper.BalanceCheckFlag.Both
                || _cache.params.balanceCheckFlag == AccountBalanceHelper.BalanceCheckFlag.To
            ) {
                AccountBalanceHelper.verifyBalanceIsNonNegative(
                    DOLOMITE_MARGIN,
                    _cache.account,
                    _cache.params.otherAccountNumber,
                    _marketId
                );
            }
        }
    }

    function _getParamsForSwapExactTokensForTokens(
        ModifyPositionCache memory _cache
    ) internal view returns (
        Account.Info[] memory,
        Actions.ActionArgs[] memory
    ) {
        _cache.marketPath = _getMarketPathFromTokenPath(_cache);

        // Convert from par to wei, if necessary
        uint256 amountInWei = _convertAssetAmountToWei(_cache.params.amountIn, _cache.marketPath[0], _cache);

        // Convert from par to wei, if necessary
        uint256 amountOutMinWei = _convertAssetAmountToWei(
            _cache.params.amountOut,
            _cache.marketPath[_cache.marketPath.length - 1],
            _cache
        );

        // amountsWei[0] == amountInWei
        // amountsWei[amountsWei.length - 1] == amountOutWei
        _cache.amountsWei = DolomiteAmmLibrary.getAmountsOutWei(
            address(_cache.ammFactory),
            amountInWei,
            _cache.params.tokenPath
        );

        Require.that(
            _cache.amountsWei[_cache.amountsWei.length - 1] >= amountOutMinWei,
            FILE,
            "insufficient output amount",
            _cache.amountsWei[_cache.amountsWei.length - 1],
            amountOutMinWei
        );

        return _getParamsForSwap(_cache);
    }

    function _getParamsForSwapTokensForExactTokens(
        ModifyPositionCache memory _cache
    ) internal view returns (
        Account.Info[] memory,
        Actions.ActionArgs[] memory
    ) {
        _cache.marketPath = _getMarketPathFromTokenPath(_cache);

        // Convert from par to wei, if necessary
        uint256 amountInMaxWei = _convertAssetAmountToWei(_cache.params.amountIn, _cache.marketPath[0], _cache);

        // Convert from par to wei, if necessary
        uint256 amountOutWei = _convertAssetAmountToWei(
            _cache.params.amountOut,
            _cache.marketPath[_cache.marketPath.length - 1],
            _cache
        );

        // cache.amountsWei[0] == amountInWei
        // cache.amountsWei[amountsWei.length - 1] == amountOutWei
        _cache.amountsWei = DolomiteAmmLibrary.getAmountsInWei(
            address(_cache.ammFactory),
            amountOutWei,
            _cache.params.tokenPath
        );
        Require.that(
            _cache.amountsWei[0] <= amountInMaxWei,
            FILE,
            "excessive input amount",
            _cache.amountsWei[0],
            amountInMaxWei
        );

        return _getParamsForSwap(_cache);
    }

    function _getParamsForSwap(
        ModifyPositionCache memory _cache
    ) internal view returns (
        Account.Info[] memory,
        Actions.ActionArgs[] memory
    ) {
        // pools.length == cache.params.tokenPath.length - 1
        address[] memory pools = DolomiteAmmLibrary.getPools(address(_cache.ammFactory), _cache.params.tokenPath);

        Account.Info[] memory accounts = _getAccountsForModifyPosition(_cache, pools);
        Actions.ActionArgs[] memory actions = _getActionArgsForModifyPosition(_cache, accounts, pools);

        if (_cache.params.marginTransferToken != address(0) && _cache.params.marginTransferWei == uint(- 1)) {
            if (_cache.params.isDepositIntoTradeAccount) {
                // the user is depositing into a margin account from accounts[accounts.length - 1] == otherAccountNumber
                // the marginDeposit is equal to the amount of `marketId` in otherAccountNumber
                _cache.marginDepositDeltaWei = _cache.dolomiteMargin.getAccountWei(
                    accounts[accounts.length - 1],
                    _cache.marginDepositMarketId
                ).value;
            } else {
                // the user is withdrawing from a margin account from accounts[0] == tradeAccountNumber
                Types.Wei memory marginDepositBalanceWei = _cache.dolomiteMargin.getAccountWei(
                    accounts[0],
                    _cache.marginDepositMarketId
                );
                if (_cache.marketPath[0] == _cache.marginDepositMarketId) {
                    // the trade downsizes the potential withdrawal
                    _cache.marginDepositDeltaWei = marginDepositBalanceWei
                        .sub(Types.Wei(true, _cache.amountsWei[0]))
                        .value;
                } else if (_cache.marketPath[_cache.marketPath.length - 1] == _cache.marginDepositMarketId) {
                    // the trade upsizes the withdrawal
                    _cache.marginDepositDeltaWei = marginDepositBalanceWei
                        .add(Types.Wei(true, _cache.amountsWei[_cache.amountsWei.length - 1]))
                        .value;
                } else {
                    // the trade doesn't impact the withdrawal
                    _cache.marginDepositDeltaWei = marginDepositBalanceWei.value;
                }
            }
        } else {
            _cache.marginDepositDeltaWei = _cache.params.marginTransferWei;
        }

        return (accounts, actions);
    }

    function _getMarketPathFromTokenPath(
        ModifyPositionCache memory _cache
    ) internal view returns (uint[] memory) {
        uint[] memory marketPath = new uint[](_cache.params.tokenPath.length);
        for (uint256 i = 0; i < _cache.params.tokenPath.length; i++) {
            marketPath[i] = _cache.dolomiteMargin.getMarketIdByTokenAddress(_cache.params.tokenPath[i]);
        }
        return marketPath;
    }

    function _getAccountsForModifyPosition(
        ModifyPositionCache memory _cache,
        address[] memory _pools
    ) internal pure returns (Account.Info[] memory) {
        Account.Info[] memory accounts;
        if (_cache.params.marginTransferToken == address(0)) {
            accounts = new Account.Info[](1 + _pools.length);
            Require.that(
                _cache.params.tradeAccountNumber == _cache.params.otherAccountNumber,
                FILE,
                "accounts must eq for swaps"
            );
        } else {
            accounts = new Account.Info[](2 + _pools.length);
            accounts[accounts.length - 1] = Account.Info(_cache.account, _cache.params.otherAccountNumber);
            Require.that(
                _cache.params.tradeAccountNumber != _cache.params.otherAccountNumber,
                FILE,
                "accounts must not eq for margin"
            );
        }

        accounts[0] = Account.Info(_cache.account, _cache.params.tradeAccountNumber);

        for (uint256 i = 0; i < _pools.length; i++) {
            accounts[i + 1] = Account.Info(_pools[i], 0);
        }

        return accounts;
    }

    function _getActionArgsForModifyPosition(
        ModifyPositionCache memory _cache,
        Account.Info[] memory _accounts,
        address[] memory _pools
    ) internal view returns (Actions.ActionArgs[] memory) {
        Actions.ActionArgs[] memory actions;
        if (_cache.params.marginTransferToken == address(0)) {
            Require.that(
                _cache.params.marginTransferWei == 0,
                FILE,
                "margin deposit must eq 0"
            );

            actions = new Actions.ActionArgs[](_pools.length);
        } else {
            Require.that(
                _cache.params.marginTransferWei != 0,
                FILE,
                "invalid margin deposit"
            );

            uint256 expiryActionCount = _cache.params.expiryTimeDelta == 0 ? 0 : 1;
            actions = new Actions.ActionArgs[](_pools.length + 1 + expiryActionCount);

            _cache.marginDepositMarketId = _cache.dolomiteMargin.getMarketIdByTokenAddress(_cache.params.marginTransferToken);
            /* solium-disable indentation */
            {
                uint256 fromAccountId;
                uint256 toAccountId;
                if (_cache.params.isDepositIntoTradeAccount) {
                    fromAccountId = _accounts.length - 1; // otherAccountNumber
                    toAccountId = 0; // tradeAccountNumber
                } else {
                    fromAccountId = 0; // tradeAccountNumber
                    toAccountId = _accounts.length - 1; // otherAccountNumber
                }

                actions[actions.length - 1 - expiryActionCount] = AccountActionHelper.encodeTransferAction(
                    fromAccountId,
                    toAccountId,
                    _cache.marginDepositMarketId,
                    _cache.params.marginTransferWei
                );
            }
            /* solium-enable indentation */

            if (expiryActionCount == 1) {
                // always use the tradeAccountId, which is at index=0
                actions[actions.length - 1] = AccountActionHelper.encodeExpirationAction(
                    _accounts[0],
                    /* _accountId = */ 0, // solium-disable-line indentation
                    /* _owedMarketId = */ _cache.marketPath[0], // solium-disable-line indentation
                    EXPIRY,
                    _cache.params.expiryTimeDelta
                );
            }
        }

        for (uint256 i = 0; i < _pools.length; i++) {
            assert(_accounts[i + 1].owner == _pools[i]);
            // use _cache.params.tradeAccountId for the trade
            actions[i] = AccountActionHelper.encodeInternalTradeAction(
                /* _fromAccountId = */ 0, // solium-disable-line indentation
                /* _toAccountId = */ i + 1, // solium-disable-line indentation
                _cache.marketPath[i],
                _cache.marketPath[i + 1],
                _pools[i],
                _cache.amountsWei[i],
                _cache.amountsWei[i + 1]
            );
        }

        return actions;
    }

    function _toPositiveDeltaWeiAssetAmount(uint256 _value) internal pure returns (Types.AssetAmount memory) {
        return Types.AssetAmount({
            sign : true,
            denomination : Types.AssetDenomination.Wei,
            ref : Types.AssetReference.Delta,
            value : _value
        });
    }

    function _convertAssetAmountToWei(
        Types.AssetAmount memory _amount,
        uint256 _marketId,
        ModifyPositionCache memory _cache
    ) internal view returns (uint256) {
        Require.that(
            _amount.ref == Types.AssetReference.Delta,
            FILE,
            "invalid asset reference"
        );
        _amount.value = _amount.value == uint256(-1) ? uint128(-1) : _amount.value;
        Require.that(
            uint128(_amount.value) == _amount.value,
            FILE,
            "invalid asset amount"
        );

        if (_amount.denomination == Types.AssetDenomination.Wei) {
            return _amount.value;
        } else {
            return Interest.parToWei(
                Types.Par({sign : _amount.sign, value : uint128(_amount.value)}),
                _cache.dolomiteMargin.getMarketCurrentIndex(_marketId)
            ).value;
        }
    }

    function _logEvents(
        ModifyPositionCache memory _cache,
        Account.Info[] memory _accounts
    ) internal {
        if (_cache.params.marginTransferToken != address(0)) {
            Events.BalanceUpdate memory inputBalanceUpdate = Events.BalanceUpdate({
                deltaWei : Types.Wei(false, _cache.amountsWei[0]),
                newPar : _cache.dolomiteMargin.getAccountPar(_accounts[0], _cache.marketPath[0])
            });
            Events.BalanceUpdate memory outputBalanceUpdate = Events.BalanceUpdate({
                deltaWei : Types.Wei(true, _cache.amountsWei[_cache.amountsWei.length - 1]),
                newPar : _cache.dolomiteMargin.getAccountPar(_accounts[0], _cache.marketPath[_cache.marketPath.length - 1])
            });
            Events.BalanceUpdate memory marginBalanceUpdate = Events.BalanceUpdate({
                deltaWei : Types.Wei(true, _cache.marginDepositDeltaWei),
                newPar : _cache.dolomiteMargin.getAccountPar(_accounts[0], _cache.marginDepositMarketId)
            });

            if (_cache.params.isDepositIntoTradeAccount) {
                emit MarginPositionOpen(
                    msg.sender,
                    _cache.params.tradeAccountNumber,
                    _cache.params.tokenPath[0],
                    _cache.params.tokenPath[_cache.params.tokenPath.length - 1],
                    _cache.params.marginTransferToken,
                    inputBalanceUpdate,
                    outputBalanceUpdate,
                    marginBalanceUpdate
                );
            } else {
                marginBalanceUpdate.deltaWei.sign = false;
                emit MarginPositionClose(
                    msg.sender,
                    _cache.params.tradeAccountNumber,
                    _cache.params.tokenPath[0],
                    _cache.params.tokenPath[_cache.params.tokenPath.length - 1],
                    _cache.params.marginTransferToken,
                    inputBalanceUpdate,
                    outputBalanceUpdate,
                    marginBalanceUpdate
                );
            }
        }
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Require } from "../../protocol/lib/Require.sol";


/**
 * @title TypedSignature
 * @author dYdX
 *
 * Library to unparse typed signatures
 */
library TypedSignature {

    // ============ Constants ============

    bytes32 constant private FILE = "TypedSignature";

    // prepended message with the length of the signed hash in decimal
    bytes constant private PREPEND_DEC = "\x19Ethereum Signed Message:\n32";

    // prepended message with the length of the signed hash in hexadecimal
    bytes constant private PREPEND_HEX = "\x19Ethereum Signed Message:\n\x20";

    // Number of bytes in a typed signature
    uint256 constant private NUM_SIGNATURE_BYTES = 66;

    // ============ Enums ============

    // Different RPC providers may implement signing methods differently, so we allow different
    // signature types depending on the string prepended to a hash before it was signed.
    enum SignatureType {
        NoPrepend,   // No string was prepended.
        Decimal,     // PREPEND_DEC was prepended.
        Hexadecimal, // PREPEND_HEX was prepended.
        Invalid      // Not a valid type. Used for bound-checking.
    }

    // ============ Functions ============

    /**
     * Gives the address of the signer of a hash. Also allows for the commonly prepended string of
     * '\x19Ethereum Signed Message:\n' + message.length
     *
     * @param  hash               Hash that was signed (does not include prepended message)
     * @param  signatureWithType  Type and ECDSA signature with structure: {32:r}{32:s}{1:v}{1:type}
     * @return                    address of the signer of the hash
     */
    function recover(
        bytes32 hash,
        bytes memory signatureWithType
    )
        internal
        pure
        returns (address)
    {
        Require.that(
            signatureWithType.length == NUM_SIGNATURE_BYTES,
            FILE,
            "Invalid signature length"
        );

        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 rawSigType;

        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            r := mload(add(signatureWithType, 0x20))
            s := mload(add(signatureWithType, 0x40))
            let lastSlot := mload(add(signatureWithType, 0x60))
            v := byte(0, lastSlot)
            rawSigType := byte(1, lastSlot)
        }

        Require.that(
            rawSigType < uint8(SignatureType.Invalid),
            FILE,
            "Invalid signature type"
        );

        SignatureType sigType = SignatureType(rawSigType);

        bytes32 signedHash;
        if (sigType == SignatureType.NoPrepend) {
            signedHash = hash;
        } else if (sigType == SignatureType.Decimal) {
            signedHash = keccak256(abi.encodePacked(PREPEND_DEC, hash));
        } else {
            assert(sigType == SignatureType.Hexadecimal);
            signedHash = keccak256(abi.encodePacked(PREPEND_HEX, hash));
        }

        return ecrecover(
            signedHash,
            v,
            r,
            s
        );
    }
}

/*

    Copyright 2021 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity >=0.5.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { Require } from "../../protocol/lib/Require.sol";

import { IUniswapV2Pair } from "../uniswap-v2/interfaces/IUniswapV2Pair.sol";

import { IDolomiteAmmFactory } from "../interfaces/IDolomiteAmmFactory.sol";
import { IDolomiteAmmPair } from "../interfaces/IDolomiteAmmPair.sol";


library DolomiteAmmLibrary {
    using SafeMath for uint;

    bytes32 private constant FILE = "DolomiteAmmLibrary";
    bytes32 private constant PAIR_INIT_CODE_HASH = 0x4df2ee6019f2710aaf8021cd3b58c30f3132e4dfc773f2fc3dfab9eedb60030a;

    function getPairInitCodeHash(address factory) internal pure returns (bytes32) {
        // Instead of only returning PAIR_INIT_CODE_HASH, this value is used to make running test coverage possible;
        // test coverage changes the bytecode on the fly, which messes up the static value for init_code_hash
        return PAIR_INIT_CODE_HASH == bytes32(0)
            ? IDolomiteAmmFactory(factory).getPairInitCodeHash()
            : PAIR_INIT_CODE_HASH;
    }

    function getPools(
        address factory,
        address[] memory path
    ) internal pure returns (address[] memory) {
        return getPools(factory, getPairInitCodeHash(factory), path);
    }

    function getPools(
        address factory,
        bytes32 initCodeHash,
        address[] memory path
    ) internal pure returns (address[] memory) {
        Require.that(
            path.length >= 2,
            FILE,
            "invalid path length"
        );

        address[] memory pools = new address[](path.length - 1);
        for (uint i = 0; i < path.length - 1; i++) {
            pools[i] = pairFor(
                factory,
                path[i],
                path[i + 1],
                initCodeHash
            );
        }
        return pools;
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        Require.that(
            tokenA != tokenB,
            FILE,
            "identical addresses"
        );
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        Require.that(
            token0 != address(0),
            FILE,
            "zero address"
        );
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        return pairFor(
            factory,
            tokenA,
            tokenB,
            getPairInitCodeHash(factory)
        );
    }

    function pairFor(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 initCodeHash
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        initCodeHash
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReservesWei(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint reserveA, uint reserveB) {
        return getReservesWei(
            factory,
            getPairInitCodeHash(factory),
            tokenA,
            tokenB
        );
    }

    function getReserves(
        address factory,
        bytes32 initCodeHash,
        address tokenA,
        address tokenB
    ) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(
            pairFor(
                factory,
                tokenA,
                tokenB,
                initCodeHash
            )
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getReservesWei(
        address factory,
        bytes32 initCodeHash,
        address tokenA,
        address tokenB
    ) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IDolomiteAmmPair(
            pairFor(
                factory,
                tokenA,
                tokenB,
                initCodeHash
            )
        ).getReservesWei();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        Require.that(
            amountA > 0,
            FILE,
            "insufficient amount"
        );
        Require.that(
            reserveA > 0 && reserveB > 0,
            FILE,
            "insufficient liquidity"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        Require.that(
            amountIn > 0,
            FILE,
            "insufficient input amount"
        );
        Require.that(
            reserveIn > 0 && reserveOut > 0,
            FILE,
            "insufficient liquidity"
        );
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        Require.that(
            amountOut > 0,
            FILE,
            "insufficient output amount"
        );
        Require.that(
            reserveIn > 0 && reserveOut > 0 && reserveOut > amountOut,
            FILE,
            "insufficient liquidity"
        );
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = numerator.div(denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOutWei(
        address factory,
        uint amountIn,
        address[] memory path
    ) internal view returns (uint[] memory) {
        return getAmountsOutWei(
            factory,
            getPairInitCodeHash(factory),
            amountIn,
            path
        );
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOutWei(
        address factory,
        bytes32 initCodeHash,
        uint amountIn,
        address[] memory path
    ) internal view returns (uint[] memory amounts) {
        Require.that(
            path.length >= 2,
            FILE,
            "invalid path"
        );
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReservesWei(
                factory,
                initCodeHash,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    function getAmountsInWei(
        address factory,
        bytes32 initCodeHash,
        uint amountOut,
        address[] memory path
    ) internal view returns (uint[] memory amounts) {
        Require.that(
            path.length >= 2,
            FILE,
            "invalid path"
        );
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReservesWei(
                factory,
                initCodeHash,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    function getAmountsIn(
        address factory,
        bytes32 initCodeHash,
        uint amountOut,
        address[] memory path
    ) internal view returns (uint[] memory amounts) {
        Require.that(
            path.length >= 2,
            FILE,
            "invalid path"
        );
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(
                factory,
                initCodeHash,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsInWei(
        address factory,
        uint amountOut,
        address[] memory path
    ) internal view returns (uint[] memory amounts) {
        return getAmountsInWei(
            factory,
            getPairInitCodeHash(factory),
            amountOut,
            path
        );
    }
}

/*

    Copyright 2021 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Account } from "../../protocol/lib/Account.sol";
import { Monetary } from "../../protocol/lib/Monetary.sol";


/**
 * @title IExpiry
 * @author Dolomite
 */
contract IExpiry {

    // ============ Enums ============

    enum CallFunctionType {
        SetExpiry,
        SetApproval
    }

    // ============ Structs ============

    struct SetExpiryArg {
        Account.Info account;
        uint256 marketId;
        uint32 timeDelta;
        bool forceUpdate;
    }

    struct SetApprovalArg {
        address sender;
        uint32 minTimeDelta;
    }

    function getSpreadAdjustedPrices(
        uint256 heldMarketId,
        uint256 owedMarketId,
        uint32 expiry
    )
        public
        view
        returns (Monetary.Price memory heldPrice, Monetary.Price memory owedPriceAdj);

    function getExpiry(
        Account.Info memory account,
        uint256 marketId
    )
        public
        view
        returns (uint32);

}

/*

    Copyright 2022 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { IDolomiteMargin } from "../../protocol/interfaces/IDolomiteMargin.sol";

import { Account } from "../../protocol/lib/Account.sol";
import { Actions } from "../../protocol/lib/Actions.sol";
import { Events } from "../../protocol/lib/Events.sol";
import { Types } from "../../protocol/lib/Types.sol";

import { AccountBalanceHelper } from "../helpers/AccountBalanceHelper.sol";

import { IDolomiteAmmFactory } from "../interfaces/IDolomiteAmmFactory.sol";
import { IDolomiteAmmPair } from "../interfaces/IDolomiteAmmPair.sol";


interface IDolomiteAmmRouterProxy {

    // ============ Events ============

    event MarginPositionOpen(
        address indexed account,
        uint256 indexed accountNumber,
        address inputToken,
        address outputToken,
        address depositToken,
        Events.BalanceUpdate inputBalanceUpdate, // the amount of borrow amount being sold to purchase collateral
        Events.BalanceUpdate outputBalanceUpdate, // the amount of collateral purchased by the borrowed amount
        Events.BalanceUpdate marginDepositUpdate
    );

    event MarginPositionClose(
        address indexed account,
        uint256 indexed accountNumber,
        address inputToken,
        address outputToken,
        address withdrawalToken,
        Events.BalanceUpdate inputBalanceUpdate, // the amount of held amount being sold to repay debt
        Events.BalanceUpdate outputBalanceUpdate, // the amount of borrow amount being repaid
        Events.BalanceUpdate marginWithdrawalUpdate
    );

    // ============ Structs ============

    struct ModifyPositionParams {
        /// the account number that's executing the trade
        uint256 tradeAccountNumber;
        /// used for transferring in/out of the position
        uint256 otherAccountNumber;
        Types.AssetAmount amountIn;
        Types.AssetAmount amountOut;
        address[] tokenPath;
        /// the token to be deposited/withdrawn to/from account number. To not perform any margin deposits or
        /// withdrawals, simply set this to `address(0)`
        address marginTransferToken;
        /// the amount of the margin deposit/withdrawal, in wei. Whether or not this is a deposit or withdrawal depends
        /// on what fromAccountNumber or toAccountNumber are set to. Setting this value to `uint(-1)` will deposit or
        /// withdraw all assets from the source account number
        uint256 marginTransferWei;
        /// true to deposit into `tradeAccountNumber` from `otherAccountNumber` , false to withdraw from it.
        bool isDepositIntoTradeAccount;
        /// the amount of seconds from the time at which the position is opened to expiry. 0 for no expiration
        uint256 expiryTimeDelta;
        /// Setting this to `FROM` will check `tradeAccountNumber`. Setting this to `TO` will check
        /// `otherAccountNumber`. Setting this to `BOTH` will check `tradeAccountNumber` and `otherAccountNumber`.
        AccountBalanceHelper.BalanceCheckFlag balanceCheckFlag;
    }

    struct ModifyPositionCache {
        ModifyPositionParams params;
        IDolomiteMargin dolomiteMargin;
        IDolomiteAmmFactory ammFactory;
        address account;
        uint[] marketPath;
        uint[] amountsWei;
        uint256 marginDepositMarketId;
        /// this value is calculated for emitting an event only
        uint256 marginDepositDeltaWei;
    }

    struct AddLiquidityParams {
        uint256 fromAccountNumber;
        address tokenA;
        address tokenB;
        uint256 amountADesiredWei;
        uint256 amountBDesiredWei;
        uint256 amountAMinWei;
        uint256 amountBMinWei;
        uint256 deadline;
        AccountBalanceHelper.BalanceCheckFlag balanceCheckFlag;
    }

    struct RemoveLiquidityParams {
        uint256 toAccountNumber;
        address tokenA;
        address tokenB;
        uint256 liquidityWei;
        uint256 amountAMinWei;
        uint256 amountBMinWei;
        uint256 deadline;
    }

    struct PermitSignature {
        bool approveMax;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function getPairInitCodeHash() external view returns (bytes32);

    function addLiquidity(
        AddLiquidityParams calldata _params,
        address _toAccount
    )
    external
    returns (uint256 amountAWei, uint256 amountBWei, uint256 liquidity);

    function addLiquidityAndDepositIntoDolomite(
        AddLiquidityParams calldata _params,
        uint256 _toAccountNumber
    )
    external
    returns (uint256 amountAWei, uint256 amountBWei, uint256 liquidity);

    function getAddLiquidityAmounts(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesiredWei,
        uint256 _amountBDesiredWei,
        uint256 _amountAMinWei,
        uint256 _amountBMinWei
    ) external view returns (uint256 amountAWei, uint256 amountBWei);

    function swapExactTokensForTokens(
        uint256 _accountNumber,
        uint256 _amountInWei,
        uint256 _amountOutMinWei,
        address[] calldata _tokenPath,
        uint256 _deadline,
        AccountBalanceHelper.BalanceCheckFlag _balanceCheckFlag
    )
    external;

    function getParamsForSwapExactTokensForTokens(
        address _account,
        uint256 _accountNumber,
        uint256 _amountInWei,
        uint256 _amountOutMinWei,
        address[] calldata _tokenPath
    )
    external view returns (Account.Info[] memory, Actions.ActionArgs[] memory);

    function swapTokensForExactTokens(
        uint256 _accountNumber,
        uint256 _amountInMaxWei,
        uint256 _amountOutWei,
        address[] calldata _tokenPath,
        uint256 _deadline,
        AccountBalanceHelper.BalanceCheckFlag _balanceCheckFlag
    )
    external;

    function getParamsForSwapTokensForExactTokens(
        address _account,
        uint256 _accountNumber,
        uint256 _amountInMaxWei,
        uint256 _amountOutWei,
        address[] calldata _tokenPath
    )
    external view returns (Account.Info[] memory, Actions.ActionArgs[] memory);

    function removeLiquidity(
        RemoveLiquidityParams calldata _params,
        address _to
    ) external returns (uint256 amountAWei, uint256 amountBWei);

    function removeLiquidityWithPermit(
        RemoveLiquidityParams calldata _params,
        address _to,
        PermitSignature calldata _permit
    ) external returns (uint256 amountAWei, uint256 amountBWei);

    function removeLiquidityFromWithinDolomite(
        RemoveLiquidityParams calldata _params,
        uint256 _fromAccountNumber,
        AccountBalanceHelper.BalanceCheckFlag _balanceCheckFlag
    ) external returns (uint256 amountAWei, uint256 amountBWei);

    function swapExactTokensForTokensAndModifyPosition(
        ModifyPositionParams calldata _params,
        uint256 _deadline
    ) external;

    function swapTokensForExactTokensAndModifyPosition(
        ModifyPositionParams calldata _params,
        uint256 _deadline
    ) external;
}

/*

    Copyright 2021 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import { Account } from "../../protocol/lib/Account.sol";
import { Types } from "../../protocol/lib/Types.sol";


interface IDolomiteAmmPair {

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0Wei, uint amount1Wei);
    event Burn(address indexed sender, uint amount0Wei, uint amount1Wei, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReservesWei() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function getReservesPar() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to, uint toAccountNumber) external returns (uint amount0Wei, uint amount1Wei);

    function getTradeCost(
        uint256 inputMarketId,
        uint256 outputMarketId,
        Account.Info calldata makerAccount,
        Account.Info calldata takerAccount,
        Types.Par calldata,
        Types.Par calldata,
        Types.Wei calldata inputWei,
        bytes calldata data
    )
    external
    returns (Types.AssetAmount memory);

    function skim(address to, uint toAccountNumber) external;

    function sync() external;

    function initialize(address _token0, address _token1, address _transferProxy) external;
}

/*

    Copyright 2021 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import { Account } from "../../protocol/lib/Account.sol";
import { Actions } from "../../protocol/lib/Actions.sol";


interface IDolomiteAmmFactory {

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function dolomiteMargin() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function getPairInitCode() external pure returns (bytes memory);
    function getPairInitCodeHash() external pure returns (bytes32);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { IDolomiteMargin } from "../../protocol/interfaces/IDolomiteMargin.sol";
import { IExpiry } from "../interfaces/IExpiry.sol";

import { Account } from "../../protocol/lib/Account.sol";
import { Bits } from "../../protocol/lib/Bits.sol";
import { Decimal } from "../../protocol/lib/Decimal.sol";
import { DolomiteMarginMath } from "../../protocol/lib/DolomiteMarginMath.sol";
import { Interest } from "../../protocol/lib/Interest.sol";
import { Monetary } from "../../protocol/lib/Monetary.sol";
import { Require } from "../../protocol/lib/Require.sol";
import { Time } from "../../protocol/lib/Time.sol";
import { Types } from "../../protocol/lib/Types.sol";


/**
 * @title LiquidatorProxyHelper
 * @author Dolomite
 *
 * Inheritable contract that allows sharing code across different liquidator proxy contracts
 */
contract LiquidatorProxyHelper {
    using SafeMath for uint;
    using Types for Types.Par;

    // ============ Constants ============

    bytes32 private constant FILE = "LiquidatorProxyHelper";
    uint256 private constant MAX_UINT_BITS = 256;
    uint256 private constant ONE = 1;

    // ============ Structs ============

    struct MarketInfo {
        uint256 marketId;
        Monetary.Price price;
        Interest.Index index;
    }

    // ============ Structs ============

    struct Constants {
        IDolomiteMargin dolomiteMargin;
        Account.Info solidAccount;
        Account.Info liquidAccount;
        MarketInfo[] markets;
        uint256[] liquidMarkets;
        IExpiry expiryProxy;
        uint32 expiry;
    }

    struct LiquidatorProxyCache {
        // mutable
        uint256 owedWeiToLiquidate;
        // The amount of heldMarket the solidAccount will receive. Includes the liquidation reward. Useful as the
        // `amountIn` for a trade
        uint256 solidHeldUpdateWithReward;
        Types.Wei solidHeldWei;
        Types.Wei solidOwedWei;
        Types.Wei liquidHeldWei;
        Types.Wei liquidOwedWei;

        // immutable
        uint256 heldMarket;
        uint256 owedMarket;
        uint256 heldPrice;
        uint256 owedPrice;
        uint256 owedPriceAdj;
        bool flipMarkets;
    }

    // ============ Internal Functions ============

    /**
     * Pre-populates cache values for some pair of markets.
     */
    function _initializeCache(
        Constants memory _constants,
        uint256 _heldMarket,
        uint256 _owedMarket
    )
    internal
    view
    returns (LiquidatorProxyCache memory)
    {
        MarketInfo memory heldMarketInfo = _binarySearch(_constants.markets, _heldMarket);
        MarketInfo memory owedMarketInfo = _binarySearch(_constants.markets, _owedMarket);

        uint256 owedPriceAdj;
        if (_constants.expiry > 0) {
            (, Monetary.Price memory owedPricePrice) = _constants.expiryProxy.getSpreadAdjustedPrices(
                _heldMarket,
                _owedMarket,
                _constants.expiry
            );
            owedPriceAdj = owedPricePrice.value;
        } else {
            Decimal.D256 memory spread = _constants.dolomiteMargin.getLiquidationSpreadForPair(
                _heldMarket,
                _owedMarket
            );
            owedPriceAdj = owedMarketInfo.price.value.add(Decimal.mul(owedMarketInfo.price.value, spread));
        }

        return LiquidatorProxyCache({
            owedWeiToLiquidate: 0,
            solidHeldUpdateWithReward: 0,
            solidHeldWei: Interest.parToWei(
                _constants.dolomiteMargin.getAccountPar(_constants.solidAccount, _heldMarket),
                heldMarketInfo.index
            ),
            solidOwedWei: Interest.parToWei(
                _constants.dolomiteMargin.getAccountPar(_constants.solidAccount, _owedMarket),
                owedMarketInfo.index
            ),
            liquidHeldWei: Interest.parToWei(
                _constants.dolomiteMargin.getAccountPar(_constants.liquidAccount, _heldMarket),
                heldMarketInfo.index
            ),
            liquidOwedWei: Interest.parToWei(
                _constants.dolomiteMargin.getAccountPar(_constants.liquidAccount, _owedMarket),
                owedMarketInfo.index
            ),
            heldMarket: _heldMarket,
            owedMarket: _owedMarket,
            heldPrice: heldMarketInfo.price.value,
            owedPrice: owedMarketInfo.price.value,
            owedPriceAdj: owedPriceAdj,
            flipMarkets: false
        });
    }

    /**
     * Make some basic checks before attempting to liquidate an account.
     *  - Require that the msg.sender has the permission to use the liquidator account
     *  - Require that the liquid account is liquidatable based on the accounts global value (all assets held and owed,
     *    not just what's being liquidated)
     */
    function _checkConstants(
        Constants memory _constants,
        Account.Info memory _liquidAccount,
        uint256 _owedMarket,
        uint256 _heldMarket,
        uint256 _expiry
    )
    internal
    view
    {
        assert(address(_constants.dolomiteMargin) != address(0));
        Require.that(
            _owedMarket != _heldMarket,
            FILE,
            "owedMarket equals heldMarket",
            _owedMarket
        );

        Require.that(
            !_constants.dolomiteMargin.getAccountPar(_liquidAccount, _owedMarket).isPositive(),
            FILE,
            "owed market cannot be positive",
            _owedMarket
        );

        Require.that(
            _constants.dolomiteMargin.getAccountPar(_liquidAccount, _heldMarket).isPositive(),
            FILE,
            "held market cannot be negative",
            _heldMarket
        );

        Require.that(
            uint32(_expiry) == _expiry,
            FILE,
            "expiry overflow",
            _expiry
        );
    }

    /**
     * Make some basic checks before attempting to liquidate an account.
     *  - Require that the msg.sender has the permission to use the liquidator account
     *  - Require that the liquid account is liquidatable based on the accounts global value (all assets held and owed,
     *    not just what's being liquidated)
     */
    function _checkBasicRequirements(
        Constants memory _constants,
        uint256 _owedMarket
    )
    internal
    view
    {
        // check credentials for msg.sender
        Require.that(
            _constants.solidAccount.owner == msg.sender
            || _constants.dolomiteMargin.getIsLocalOperator(_constants.solidAccount.owner, msg.sender),
            FILE,
            "Sender not operator",
            msg.sender
        );

        if (_constants.expiry != 0) {
            // check the expiration is valid; to get here we already know constants.expiry != 0
            uint32 expiry = _constants.expiryProxy.getExpiry(_constants.liquidAccount, _owedMarket);
            Require.that(
                expiry == _constants.expiry,
                FILE,
                "Expiry mismatch",
                expiry,
                _constants.expiry
            );
            Require.that(
                expiry <= Time.currentTime(),
                FILE,
                "Borrow not yet expired",
                expiry
            );
        }
    }

    /**
     * Calculate the additional owedAmount that can be liquidated until the collateralization of the liquidator account
     * reaches the minLiquidatorRatio. By this point, the cache will be set such that the amount of owedMarket is
     * non-positive and the amount of heldMarket is non-negative.
     */
    function _calculateAndSetMaxLiquidationAmount(
        LiquidatorProxyCache memory _cache
    )
    internal
    pure
    {
        uint256 liquidHeldValue = _cache.heldPrice.mul(_cache.liquidHeldWei.value);
        uint256 liquidOwedValue = _cache.owedPriceAdj.mul(_cache.liquidOwedWei.value);
        if (liquidHeldValue < liquidOwedValue) {
            // The held collateral is worth less than the debt
            _cache.solidHeldUpdateWithReward = _cache.liquidHeldWei.value;
            _cache.owedWeiToLiquidate = DolomiteMarginMath.getPartialRoundUp(
                _cache.liquidHeldWei.value,
                _cache.heldPrice,
                _cache.owedPriceAdj
            );
            _cache.flipMarkets = true;
        } else {
            _cache.solidHeldUpdateWithReward = DolomiteMarginMath.getPartial(
                _cache.liquidOwedWei.value,
                _cache.owedPriceAdj,
                _cache.heldPrice
            );
            _cache.owedWeiToLiquidate = _cache.liquidOwedWei.value;
        }
    }

    /**
     * Returns true if the supplyValue over-collateralizes the borrowValue by the ratio.
     */
    function _isCollateralized(
        uint256 supplyValue,
        uint256 borrowValue,
        Decimal.D256 memory ratio
    )
    internal
    pure
    returns (bool)
    {
        uint256 requiredMargin = Decimal.mul(borrowValue, ratio);
        return supplyValue >= borrowValue.add(requiredMargin);
    }

    /**
     * Gets the current total supplyValue and borrowValue for some account. Takes into account what
     * the current index will be once updated.
     */
    function _getAccountValues(
        IDolomiteMargin dolomiteMargin,
        MarketInfo[] memory marketInfos,
        Account.Info memory account,
        uint256[] memory marketIds
    )
    internal
    view
    returns (
        Monetary.Value memory,
        Monetary.Value memory
    )
    {
        return _getAccountValues(
            dolomiteMargin,
            marketInfos,
            account,
            marketIds,
            /* adjustForMarginPremiums = */ false // solium-disable-line indentation
        );
    }

    /**
     * Gets the adjusted current total supplyValue and borrowValue for some account. Takes into account what
     * the current index will be once updated and the margin premium.
     */
    function _getAdjustedAccountValues(
        IDolomiteMargin dolomiteMargin,
        MarketInfo[] memory marketInfos,
        Account.Info memory account,
        uint256[] memory marketIds
    )
    internal
    view
    returns (
        Monetary.Value memory,
        Monetary.Value memory
    )
    {
        return _getAccountValues(
            dolomiteMargin,
            marketInfos,
            account,
            marketIds,
            /* adjustForMarginPremiums = */ true // solium-disable-line indentation
        );
    }

    function _getMarketInfos(
        IDolomiteMargin dolomiteMargin,
        uint256[] memory solidMarkets,
        uint256[] memory liquidMarkets
    ) internal view returns (MarketInfo[] memory) {
        uint[] memory marketBitmaps = Bits.createBitmaps(dolomiteMargin.getNumMarkets());
        uint marketsLength = 0;
        marketsLength = _addMarketsToBitmap(solidMarkets, marketBitmaps, marketsLength);
        marketsLength = _addMarketsToBitmap(liquidMarkets, marketBitmaps, marketsLength);

        uint counter = 0;
        MarketInfo[] memory marketInfos = new MarketInfo[](marketsLength);
        for (uint i = 0; i < marketBitmaps.length; i++) {
            uint bitmap = marketBitmaps[i];
            while (bitmap != 0) {
                uint nextSetBit = Bits.getLeastSignificantBit(bitmap);
                uint marketId = Bits.getMarketIdFromBit(i, nextSetBit);

                marketInfos[counter++] = MarketInfo({
                    marketId: marketId,
                    price: dolomiteMargin.getMarketPrice(marketId),
                    index: dolomiteMargin.getMarketCurrentIndex(marketId)
                });

                // unset the set bit
                bitmap = Bits.unsetBit(bitmap, nextSetBit);
            }
            if (counter == marketsLength) {
                break;
            }
        }

        return marketInfos;
    }

    function _binarySearch(
        MarketInfo[] memory markets,
        uint marketId
    ) internal pure returns (MarketInfo memory) {
        return _binarySearch(
            markets,
            0,
            markets.length,
            marketId
        );
    }

    // ============ Private Functions ============

    function _getAccountValues(
        IDolomiteMargin dolomiteMargin,
        MarketInfo[] memory marketInfos,
        Account.Info memory account,
        uint256[] memory marketIds,
        bool adjustForMarginPremiums
    )
    private
    view
    returns (
        Monetary.Value memory,
        Monetary.Value memory
    )
    {
        Monetary.Value memory supplyValue;
        Monetary.Value memory borrowValue;

        for (uint256 i = 0; i < marketIds.length; i++) {
            Types.Par memory par = dolomiteMargin.getAccountPar(account, marketIds[i]);
            MarketInfo memory marketInfo = _binarySearch(marketInfos, marketIds[i]);
            Types.Wei memory userWei = Interest.parToWei(par, marketInfo.index);
            uint256 assetValue = userWei.value.mul(marketInfo.price.value);
            Decimal.D256 memory marginPremium = Decimal.one();
            if (adjustForMarginPremiums) {
                marginPremium = Decimal.onePlus(dolomiteMargin.getMarketMarginPremium(marketIds[i]));
            }
            if (userWei.sign) {
                supplyValue.value = supplyValue.value.add(Decimal.div(assetValue, marginPremium));
            } else {
                borrowValue.value = borrowValue.value.add(Decimal.mul(assetValue, marginPremium));
            }
        }

        return (supplyValue, borrowValue);
    }

    // solium-disable-next-line security/no-assign-params
    function _addMarketsToBitmap(
        uint256[] memory markets,
        uint256[] memory bitmaps,
        uint marketsLength
    ) private pure returns (uint) {
        for (uint i = 0; i < markets.length; i++) {
            if (!Bits.hasBit(bitmaps, markets[i])) {
                Bits.setBit(bitmaps, markets[i]);
                marketsLength += 1;
            }
        }
        return marketsLength;
    }

    function _binarySearch(
        MarketInfo[] memory markets,
        uint beginInclusive,
        uint endExclusive,
        uint marketId
    ) private pure returns (MarketInfo memory) {
        uint len = endExclusive - beginInclusive;
        if (len == 0 || (len == 1 && markets[beginInclusive].marketId != marketId)) {
            revert("LiquidatorProxyHelper: market not found");
        }

        uint mid = beginInclusive + len / 2;
        uint midMarketId = markets[mid].marketId;
        if (marketId < midMarketId) {
            return _binarySearch(
                markets,
                beginInclusive,
                mid,
                marketId
            );
        } else if (marketId > midMarketId) {
            return _binarySearch(
                markets,
                mid + 1,
                endExclusive,
                marketId
            );
        } else {
            return markets[mid];
        }
    }

}

/*

    Copyright 2022 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


/**
 * @title ERC20Helper
 * @author Dolomite
 *
 * Library contract for reusable token actions
 */
library ERC20Helper {
    using SafeERC20 for IERC20;

    // ============ Functions ============

    function checkAllowanceAndApprove(
        address token,
        address spender,
        uint256 amount
    ) internal {
        if (IERC20(token).allowance(address(this), spender) < amount) {
            IERC20(token).safeApprove(spender, uint(- 1));
        }
    }
}

/*

    Copyright 2022 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Account } from "../../protocol/lib/Account.sol";


/**
 * @title AccountMarginHelper
 * @author Dolomite
 *
 * Library contract that has various utility functions for margin positions/accounts
 */
library AccountMarginHelper {

    // ============ Constants ============

    bytes32 constant FILE = "AccountMarginHelper";

    // ============ Functions ============

    /**
     *  Checks if an account is margin account by whether or not it's `>= 100` (since users have to split assets into
     *  segments of 32).
     */
    function isMarginAccount(
        uint256 _accountIndex
    ) internal pure returns (bool) {
        return _accountIndex >= 100;
    }

    /**
     *  Checks if an account is margin account by whether or not it's `>= 100` (since users have to split assets into
     *  segments of 32).
     */
    function isMarginAccount(
        Account.Info memory _account
    ) internal pure returns (bool) {
        return _account.number >= 100;
    }
}

/*

    Copyright 2022 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { IDolomiteMargin } from "../../protocol/interfaces/IDolomiteMargin.sol";

import { Account } from "../../protocol/lib/Account.sol";
import { Require } from "../../protocol/lib/Require.sol";
import { Types } from "../../protocol/lib/Types.sol";


/**
 * @title AccountBalanceHelper
 * @author Dolomite
 *
 * Library contract that checks a user's balance after transaction to be non-negative
 */
library AccountBalanceHelper {
    using Types for Types.Par;

    // ============ Constants ============

    bytes32 constant FILE = "AccountBalanceHelper";

    // ============ Types ============

    /// Checks that either BOTH, FROM, or TO accounts all have non-negative balances
    enum BalanceCheckFlag {
        Both,
        From,
        To,
        None
    }

    // ============ Functions ============

    /**
     *  Checks that the account's balance is non-negative. Reverts if the check fails
     */
    function verifyBalanceIsNonNegative(
        IDolomiteMargin dolomiteMargin,
        address _owner,
        uint256 _accountIndex,
        uint256 _marketId
    ) internal view {
        Account.Info memory account = Account.Info(_owner, _accountIndex);
        Types.Par memory par = dolomiteMargin.getAccountPar(account, _marketId);
        Require.that(
            par.isPositive() || par.isZero(),
            FILE,
            "account cannot go negative",
            _owner,
            _accountIndex,
            _marketId
        );
    }
}

/*

    Copyright 2022 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { IDolomiteMargin } from "../../protocol/interfaces/IDolomiteMargin.sol";

import { Account } from "../../protocol/lib/Account.sol";
import { Actions } from "../../protocol/lib/Actions.sol";
import { Require } from "../../protocol/lib/Require.sol";
import { Types } from "../../protocol/lib/Types.sol";

import { IExpiry } from "../interfaces/IExpiry.sol";

import { AccountBalanceHelper } from "./AccountBalanceHelper.sol";


/**
 * @title AccountActionHelper
 * @author Dolomite
 *
 * Library contract that makes specific actions easy to call
 */
library AccountActionHelper {

    // ============ Constants ============

    bytes32 constant FILE = "AccountActionHelper";

    uint256 constant ALL = uint256(-1);

    // ============ Functions ============

    function all() internal pure returns (uint256) {
        return ALL;
    }

    function deposit(
        IDolomiteMargin _dolomiteMargin,
        address _accountOwner,
        address _fromAccount,
        uint256 _toAccountNumber,
        uint256 _marketId,
        Types.AssetAmount memory _amount
    ) internal {
        Account.Info[] memory accounts = new Account.Info[](1);
        accounts[0] = Account.Info({
            owner: _accountOwner,
            number: _toAccountNumber
        });

        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](1);
        actions[0] = Actions.ActionArgs({
            actionType: Actions.ActionType.Deposit,
            accountId: 0,
            amount: _amount,
            primaryMarketId: _marketId,
            secondaryMarketId: 0,
            otherAddress: _fromAccount,
            otherAccountId: 0,
            data: bytes("")
        });

        _dolomiteMargin.operate(accounts, actions);
    }

    /**
     *  Withdraws `_marketId` from `_fromAccount` to `_toAccount`
     */
    function withdraw(
        IDolomiteMargin _dolomiteMargin,
        address _accountOwner,
        uint256 _fromAccountNumber,
        address _toAccount,
        uint256 _marketId,
        Types.AssetAmount memory _amount,
        AccountBalanceHelper.BalanceCheckFlag _balanceCheckFlag
    ) internal {
        Account.Info[] memory accounts = new Account.Info[](1);
        accounts[0] = Account.Info({
            owner: _accountOwner,
            number: _fromAccountNumber
        });

        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](1);
        actions[0] = Actions.ActionArgs({
            actionType: Actions.ActionType.Withdraw,
            accountId: 0,
            amount: _amount,
            primaryMarketId: _marketId,
            secondaryMarketId: 0,
            otherAddress: _toAccount,
            otherAccountId: 0,
            data: bytes("")
        });

        _dolomiteMargin.operate(accounts, actions);

        if (
            _balanceCheckFlag == AccountBalanceHelper.BalanceCheckFlag.Both
            || _balanceCheckFlag == AccountBalanceHelper.BalanceCheckFlag.From
        ) {
            AccountBalanceHelper.verifyBalanceIsNonNegative(
                _dolomiteMargin,
                accounts[0].owner,
                _fromAccountNumber,
                _marketId
            );
        }
    }

    /**
     * Transfers `_marketId` from `_fromAccount` to `_toAccount`
     */
    function transfer(
        IDolomiteMargin _dolomiteMargin,
        address _accountOwner,
        uint256 _fromAccountNumber,
        uint256 _toAccountNumber,
        uint256 _marketId,
        Types.AssetAmount memory _amount,
        AccountBalanceHelper.BalanceCheckFlag _balanceCheckFlag
    ) internal {
        Account.Info[] memory accounts = new Account.Info[](2);
        accounts[0] = Account.Info({
            owner: _accountOwner,
            number: _fromAccountNumber
        });
        accounts[1] = Account.Info({
            owner: _accountOwner,
            number: _toAccountNumber
        });

        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](1);
        actions[0] = Actions.ActionArgs({
            actionType: Actions.ActionType.Transfer,
            accountId: 0,
            amount: _amount,
            primaryMarketId: _marketId,
            secondaryMarketId: 0,
            otherAddress: address(0),
            otherAccountId: 1,
            data: bytes("")
        });

        _dolomiteMargin.operate(accounts, actions);

        if (
            _balanceCheckFlag == AccountBalanceHelper.BalanceCheckFlag.Both
            || _balanceCheckFlag == AccountBalanceHelper.BalanceCheckFlag.From
        ) {
            AccountBalanceHelper.verifyBalanceIsNonNegative(
                _dolomiteMargin,
                _accountOwner,
                _fromAccountNumber,
                _marketId
            );
        }

        if (
            _balanceCheckFlag == AccountBalanceHelper.BalanceCheckFlag.Both
            || _balanceCheckFlag == AccountBalanceHelper.BalanceCheckFlag.To
        ) {
            AccountBalanceHelper.verifyBalanceIsNonNegative(
                _dolomiteMargin,
                _accountOwner,
                _toAccountNumber,
                _marketId
            );
        }
    }

    function encodeExpirationAction(
        Account.Info memory _account,
        uint256 _accountId,
        uint256 _owedMarketId,
        address _expiry,
        uint256 _expiryTimeDelta
    ) internal pure returns (Actions.ActionArgs memory) {
        Require.that(
            _expiryTimeDelta == uint32(_expiryTimeDelta),
            FILE,
            "invalid expiry time"
        );

        IExpiry.SetExpiryArg[] memory expiryArgs = new IExpiry.SetExpiryArg[](1);
        expiryArgs[0] = IExpiry.SetExpiryArg({
            account : _account,
            marketId : _owedMarketId,
            timeDelta : uint32(_expiryTimeDelta),
            forceUpdate : true
        });

        return Actions.ActionArgs({
            actionType : Actions.ActionType.Call,
            accountId : _accountId,
            // solium-disable-next-line arg-overflow
            amount : Types.AssetAmount(true, Types.AssetDenomination.Wei, Types.AssetReference.Delta, 0),
            primaryMarketId : 0,
            secondaryMarketId : 0,
            otherAddress : _expiry,
            otherAccountId : 0,
            data : abi.encode(IExpiry.CallFunctionType.SetExpiry, expiryArgs)
        });
    }

    function encodeExpiryLiquidateAction(
        uint256 _solidAccountId,
        uint256 _liquidAccountId,
        uint256 _owedMarketId,
        uint256 _heldMarketId,
        address _expiryProxy,
        uint32 _expiry,
        bool _flipMarkets
    ) internal pure returns (Actions.ActionArgs memory) {
        return Actions.ActionArgs({
        actionType: Actions.ActionType.Trade,
            accountId: _solidAccountId,
            amount: Types.AssetAmount({
                sign: true,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Target,
                value: 0
            }),
            primaryMarketId: !_flipMarkets ? _owedMarketId : _heldMarketId,
            secondaryMarketId: !_flipMarkets ? _heldMarketId : _owedMarketId,
            otherAddress: _expiryProxy,
            otherAccountId: _liquidAccountId,
            data: abi.encode(_owedMarketId, _expiry)
        });
    }

    function encodeLiquidateAction(
        uint256 _solidAccountId,
        uint256 _liquidAccountId,
        uint256 _owedMarketId,
        uint256 _heldMarketId,
        uint256 _owedWeiToLiquidate
    ) internal pure returns (Actions.ActionArgs memory) {
        return Actions.ActionArgs({
            actionType: Actions.ActionType.Liquidate,
            accountId: _solidAccountId,
            amount: Types.AssetAmount({
                sign: true,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: _owedWeiToLiquidate
            }),
            primaryMarketId: _owedMarketId,
            secondaryMarketId: _heldMarketId,
            otherAddress: address(0),
            otherAccountId: _liquidAccountId,
            data: new bytes(0)
        });
    }

    function encodeExternalSellAction(
        uint256 _fromAccountId,
        uint256 _primaryMarketId,
        uint256 _secondaryMarketId,
        address _trader,
        uint256 _amountInWei,
        uint256 _amountOutMinWei,
        bytes memory _orderData
    ) internal pure returns (Actions.ActionArgs memory) {
        return Actions.ActionArgs({
            actionType : Actions.ActionType.Sell,
            accountId : _fromAccountId,
            // solium-disable-next-line arg-overflow
            amount : Types.AssetAmount(false, Types.AssetDenomination.Wei, Types.AssetReference.Delta, _amountInWei),
            primaryMarketId : _primaryMarketId,
            secondaryMarketId : _secondaryMarketId,
            otherAddress : _trader,
            otherAccountId : 0,
            data : abi.encode(_amountOutMinWei, _orderData)
        });
    }

    function encodeInternalTradeAction(
        uint256 _fromAccountId,
        uint256 _toAccountId,
        uint256 _primaryMarketId,
        uint256 _secondaryMarketId,
        address _traderAddress,
        uint256 _amountInWei,
        uint256 _amountOutWei
    ) internal pure returns (Actions.ActionArgs memory) {
        return Actions.ActionArgs({
            actionType : Actions.ActionType.Trade,
            accountId : _fromAccountId,
            // solium-disable-next-line arg-overflow
            amount : Types.AssetAmount(true, Types.AssetDenomination.Wei, Types.AssetReference.Delta, _amountInWei),
            primaryMarketId : _primaryMarketId,
            secondaryMarketId : _secondaryMarketId,
            otherAddress : _traderAddress,
            otherAccountId : _toAccountId,
            data : abi.encode(_amountOutWei)
        });
    }

    function encodeTransferAction(
        uint256 _fromAccountId,
        uint256 _toAccountId,
        uint256 _marketId,
        uint256 _amount
    ) internal pure returns (Actions.ActionArgs memory) {
        Types.AssetAmount memory assetAmount;
        if (_amount == uint(- 1)) {
            assetAmount = Types.AssetAmount(
                true,
                Types.AssetDenomination.Wei,
                Types.AssetReference.Target,
                0
            );
        } else {
            assetAmount = Types.AssetAmount(
                false,
                Types.AssetDenomination.Wei,
                Types.AssetReference.Delta,
                _amount
            );
        }
        return Actions.ActionArgs({
            actionType : Actions.ActionType.Transfer,
            accountId : _fromAccountId,
            amount : assetAmount,
            primaryMarketId : _marketId,
            secondaryMarketId : 0,
            otherAddress : address(0),
            otherAccountId : _toAccountId,
            data : bytes("")
        });
    }
}