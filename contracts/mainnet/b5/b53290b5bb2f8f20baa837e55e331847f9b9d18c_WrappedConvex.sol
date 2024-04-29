// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "src/wrappers/BaseWrapper.sol";
import "src/interfaces/convex/IConvexBooster.sol";
import "src/interfaces/convex/IConvexRewardPool.sol";
import "src/interfaces/curve/ICurvePool.sol";

contract WrappedConvex is BaseWrapper {

    using SafeERC20 for IERC20;
    using SafeERC20 for ICurvePool;
    using SafeERC20 for IConvexRewardPool;

    IConvexRewardPool public CVX_REWARD_POOL;
    IConvexBooster public CVX_BOOSTER;
    ICurvePool public CRV_POOL;
    
    uint public CVX_POOL_ID;
    uint public CRV_N_COINS;
    address[] public CRV_COINS;
    uint public CVX_REWARD_LENGTH;
    address[] public CVX_REWARD_COINS;

    function initialize(address asset_, string memory name_, string memory symbol_, address authority_, address convexRewardPool_) public initializer {
        __Wrapper_init(asset_, name_, symbol_, authority_);

        CVX_REWARD_POOL = IConvexRewardPool(convexRewardPool_);

        CVX_POOL_ID = CVX_REWARD_POOL.convexPoolId();
        CVX_BOOSTER = IConvexBooster(CVX_REWARD_POOL.convexBooster());

        (address lptoken,,,,) = CVX_BOOSTER.poolInfo(CVX_POOL_ID);
        CRV_POOL = ICurvePool(lptoken);

        CRV_N_COINS = CRV_POOL.N_COINS();
        CRV_COINS = new address[](CRV_N_COINS);
        for (uint i = 0; i < CRV_N_COINS; i++) {
            CRV_COINS[i] = CRV_POOL.coins(i);
        }

        CVX_REWARD_LENGTH = CVX_REWARD_POOL.rewardLength();
        CVX_REWARD_COINS = new address[](CVX_REWARD_LENGTH);
        for (uint i = 0; i < CVX_REWARD_LENGTH; i++) {
            (CVX_REWARD_COINS[i],,) = CVX_REWARD_POOL.rewards(i);
        }
    }

    function _invest() internal override {
        uint256[] memory amounts = new uint256[](CRV_N_COINS);
        bool depositEmpty = true;
        for (uint i = 0; i < CRV_N_COINS; i++) {
            IERC20 coin = IERC20(CRV_COINS[i]);
            uint balance = coin.balanceOf(address(this));
            if (balance > 0) {
                coin.forceApprove(address(CRV_POOL), balance);
                amounts[i] = balance;
                depositEmpty = false;
            }
        }

        if (!depositEmpty) {
            CRV_POOL.add_liquidity(amounts, 0);
        }
        
        uint lpBalance = CRV_POOL.balanceOf(address(this));
        if (lpBalance > 0) {
            CRV_POOL.forceApprove(address(CVX_BOOSTER), lpBalance);
            CVX_BOOSTER.depositAll(CVX_POOL_ID);
        }
    }

    function _redeem(uint lpAmount, address to)
        internal
        override
        returns (address[] memory tokens, uint[] memory amounts)
    {
        CVX_REWARD_POOL.withdraw(lpAmount, false);
        uint256 lpBalance = CRV_POOL.balanceOf(address(this));
        
        uint[] memory minAmounts = new uint[](CRV_N_COINS);
        
        amounts = CRV_POOL.remove_liquidity(lpBalance, minAmounts, to);
        tokens = CRV_COINS;

        if (CRV_POOL.balanceOf(address(this)) > 0) {
            revert('Not all LP tokens burned');
        }
    }

    function _claim(address to) internal override {
        CVX_REWARD_POOL.getReward(address(this), to);
    }

    function negotiableTokens() public virtual override returns(address[] memory tokens) {
        tokens = new address[](2 + CRV_N_COINS + CVX_REWARD_LENGTH);

        tokens[0] = address(CRV_POOL);
        tokens[1] = address(CVX_REWARD_POOL);

        for (uint i = 0; i < CRV_N_COINS; i++) {
           tokens[2 + i] = CRV_COINS[i];
        }

        for (uint i = 0; i < CVX_REWARD_LENGTH; i++) {
            tokens[2 + CRV_N_COINS + i] = CVX_REWARD_COINS[i];
        }
    }

    function depositTokens() public override view returns (address[] memory tokens) {
        tokens = CRV_COINS;
    }

    function rewardTokens() public override view returns (address[] memory tokens) {
        tokens = CVX_REWARD_COINS;
    }

    function poolTokens() public override view returns (address[] memory tokens) {
        tokens = CRV_COINS;
    }

    function farmingPool() public view returns (address) {
        return address(CVX_REWARD_POOL);
    }

    /// @dev for offchain use 
    function ratios()
        external
        override
        view
        returns (address[] memory tokens, uint[] memory ratio)
    {
        tokens = CRV_COINS;
        ratio = CRV_POOL.get_balances();
    }

    /// @dev for offchain use 
    function description() external override view returns (string memory) {
        return string.concat(
            '{',
            '"type":"convex",',
            '"cvxPoolId":"',Strings.toHexString(CVX_POOL_ID),'",',
            '"cvxRewardPool":"',Strings.toHexString(address(CVX_REWARD_POOL)),'",',
            '"cvxBooster":"',Strings.toHexString(address(CVX_BOOSTER)),'",',
            '"crvPool":"',Strings.toHexString(address(CRV_POOL)),'"',
            '}'
        );
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

pragma solidity ^0.8.20;

import {Math} from "./math/Math.sol";
import {SignedMath} from "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

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
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
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
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
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
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

import {removeSelector} from "vulcan/utils.sol";

import "src/helpers/SwapExecutor.sol";
import "src/interfaces/IWrapper.sol";

abstract contract BaseWrapper is IWrapper, ERC4626Upgradeable, AccessManagedUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    
    using SafeERC20 for IERC20;
    using Math for uint256;

    error _ClaimAmountsResult(address[] rewardTokens, uint[] rewardsClaimed);
    error UnexpectedErrorSignature(bytes revertData);
    error Unexpected();
    address constant MAGIC_ADDRESS = 0x000000000000000000000000000000000badF00D;

    constructor() {
        _disableInitializers();
    }

    function __Wrapper_init(address asset_, string memory name_, string memory symbol_, address authority_) public onlyInitializing {
        __ERC4626_init(IERC20(asset_));
        __ERC20_init(name_, symbol_);
        __AccessManaged_init(authority_);
        __ReentrancyGuard_init();
        __Pausable_init();
    }

    function _authorizeUpgrade(address) internal override restricted {    
    }

    function pause() public restricted {
        _pause();
    }

    function unpause() public restricted {
        _unpause();
    }

    function investOrigin(address dustReceiver) 
        external
        override
        whenNotPaused
        nonReentrant
        returns (uint shares) {
        return investOrigin(_msgSender(), dustReceiver);
    }

    function investOrigin(address receiver, address dustReceiver) 
        public
        override
        whenNotPaused
        nonReentrant
        returns (uint shares) {

        (uint lpBefore, uint lpAfter) = _investInternal(dustReceiver);

        require(lpAfter > lpBefore, "Empty invest");
        uint assets = lpAfter - lpBefore;

        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }

        shares = _convertToShares(assets, lpBefore, Math.Rounding.Floor);
        _mint(receiver, shares);

        emit Deposit(receiver, receiver, assets, shares);
    }

    function redeemOrigin(uint256 shares, address to)
        external
        override
        nonReentrant
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        address owner = _msgSender();

        uint256 maxShares = maxRedeem(owner);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(owner, shares, maxShares);
        }

        uint256 assets = previewRedeem(shares);
        _burn(owner, shares);
        emit Withdraw(owner, to, owner, assets, shares);

        (tokens, amounts) = _redeem(assets, to);
    }

    function claimSimple(address receiver)
        external
        override
        virtual
        restricted
    {
        _claim(receiver);
    }

    function claim(address receiver)
        external
        override
        virtual
        restricted
        returns (address[] memory rewardTokens_, uint[] memory rewardsClaimed_, uint[] memory rewardBalances_)
    {
        return _claimInternal(receiver);
    }

    function recoverFunds(TransferInfo calldata transfer, address to) 
        external
        override 
        virtual 
        restricted
    {
        address[] memory tokens = negotiableTokens();
        for (uint i = 0; i < tokens.length; i++) {
            require(tokens[i] != transfer.token, "Unupported token");
        }
        IERC20(transfer.token).safeTransfer(to, transfer.amount);
    }

    function pendingRewards() external override returns (address[] memory tokens, uint[] memory amounts) {
        try this._claimAndRevert() {
        } catch (bytes memory data) {
            if(bytes4(data) != _ClaimAmountsResult.selector) {
                revert UnexpectedErrorSignature(data);
            }
            return abi.decode(removeSelector(data), (address[], uint[]));
        }
        revert Unexpected();
    }

    function _claimAndRevert() external {
        (address[] memory _rewardTokens, uint[] memory _rewardsClaimed,) = _claimInternal(MAGIC_ADDRESS);
        revert _ClaimAmountsResult(_rewardTokens, _rewardsClaimed);
    }

    function _claimInternal(address receiver)
    private
    returns (address[] memory rewardTokens_, uint[] memory rewardsClaimed_, uint[] memory rewardBalances_)
    {
        rewardTokens_ = rewardTokens();
        rewardsClaimed_ = new uint[](rewardTokens_.length);
        rewardBalances_ = new uint[](rewardTokens_.length);

        for (uint i = 0; i < rewardTokens_.length; ++i) {
            // will be calculated later
            rewardsClaimed_[i] = IERC20(rewardTokens_[i]).balanceOf(receiver);
        }

        _claim(receiver);

        for (uint i = 0; i < rewardTokens_.length; ++i) {
            uint rewardBalance = IERC20(rewardTokens_[i]).balanceOf(receiver);
            rewardsClaimed_[i] = rewardBalance - rewardsClaimed_[i];
            rewardBalances_[i] = rewardBalance;
        }
    }

    function _investInternal(address dustReceiver) internal returns (uint256 lpBefore, uint256 lpAfter) {
        lpBefore = totalAssets();
        _invest();
        lpAfter = totalAssets();
        _returnDust(dustReceiver);
    }

    function _returnDust(address dustReceiver) internal {
        address[] memory tokens = depositTokens();
        uint tokensLength = tokens.length;

        for (uint i = 0; i < tokensLength; ++i) {
            IERC20 token = IERC20(tokens[i]);
            uint256 tokenBalance = token.balanceOf(address(this));

            if (tokenBalance > 0) {
                SafeERC20.safeTransfer(token, dustReceiver, tokenBalance);
            }
        }
    }

    function _convertToShares(uint256 assets, uint256 assetsBefore, Math.Rounding rounding) internal view virtual returns (uint256) {
        return assets.mulDiv(totalSupply() + 10 ** _decimalsOffset(), assetsBefore + 1, rounding);
    }

    function _invest() internal virtual;
    function _redeem(uint256 lpAmount, address to)
        internal
        virtual
        returns (address[] memory tokens, uint[] memory amounts);
    function _claim(address receiver) internal virtual;

    function negotiableTokens() public override virtual returns(address[] memory tokens);
    function depositTokens() public override virtual view returns (address[] memory tokens);
    function rewardTokens() public override view virtual returns(address[] memory tokens);
    function poolTokens() public override view virtual returns(address[] memory tokens);
    function ratios() external override view virtual returns(address[] memory tokens, uint[] memory ratio);
    function description() external override virtual returns (string memory);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IConvexBooster {

    function depositAll(uint256 _pid) external returns(bool);
    function poolInfo(uint256 _pid) external returns(address lptoken, address gauge, address rewards, bool shutdown, address factory);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IConvexRewardPool is IERC20 {

    function convexBooster() external returns(address);
    function convexPoolId() external returns(uint256);

    function withdraw(uint256 _amount, bool _claim) external returns(bool);

    function rewardLength() external returns(uint256);
    function rewards(uint256) external returns(address _rewardToken, uint256 _rewardIntegral, uint256 _rewardRemaining);
    function claimable_reward(address _rewardToken, address _account) external view returns(uint256);
    function getReward(address _account, address _forwardTo) external;

    function user_checkpoint(address _account) external returns(bool);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICurvePool is IERC20 {

    function N_COINS() external returns (uint);
    function coins(uint) external returns (address);

    function get_balances() external view returns (uint256[] memory _balances);
    function add_liquidity(uint256[] memory _depositAmounts, uint256 _minMintAmount) external;
    function remove_liquidity(uint256 _burnAmount, uint256[] memory _minAmounts, address _receiver) external returns (uint256[] memory _amounts);

    function calc_token_amount(uint256[] memory _depositAmounts, bool _isDeposit) external returns (uint256);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     *
     * CAUTION: See Security Considerations above.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
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
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
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
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (access/manager/AccessManaged.sol)

pragma solidity ^0.8.20;

import {IAuthority} from "@openzeppelin/contracts/access/manager/IAuthority.sol";
import {AuthorityUtils} from "@openzeppelin/contracts/access/manager/AuthorityUtils.sol";
import {IAccessManager} from "@openzeppelin/contracts/access/manager/IAccessManager.sol";
import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import {ContextUpgradeable} from "../../utils/ContextUpgradeable.sol";
import {Initializable} from "../../proxy/utils/Initializable.sol";

/**
 * @dev This contract module makes available a {restricted} modifier. Functions decorated with this modifier will be
 * permissioned according to an "authority": a contract like {AccessManager} that follows the {IAuthority} interface,
 * implementing a policy that allows certain callers to access certain functions.
 *
 * IMPORTANT: The `restricted` modifier should never be used on `internal` functions, judiciously used in `public`
 * functions, and ideally only used in `external` functions. See {restricted}.
 */
abstract contract AccessManagedUpgradeable is Initializable, ContextUpgradeable, IAccessManaged {
    /// @custom:storage-location erc7201:openzeppelin.storage.AccessManaged
    struct AccessManagedStorage {
        address _authority;

        bool _consumingSchedule;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.AccessManaged")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant AccessManagedStorageLocation = 0xf3177357ab46d8af007ab3fdb9af81da189e1068fefdc0073dca88a2cab40a00;

    function _getAccessManagedStorage() private pure returns (AccessManagedStorage storage $) {
        assembly {
            $.slot := AccessManagedStorageLocation
        }
    }

    /**
     * @dev Initializes the contract connected to an initial authority.
     */
    function __AccessManaged_init(address initialAuthority) internal onlyInitializing {
        __AccessManaged_init_unchained(initialAuthority);
    }

    function __AccessManaged_init_unchained(address initialAuthority) internal onlyInitializing {
        _setAuthority(initialAuthority);
    }

    /**
     * @dev Restricts access to a function as defined by the connected Authority for this contract and the
     * caller and selector of the function that entered the contract.
     *
     * [IMPORTANT]
     * ====
     * In general, this modifier should only be used on `external` functions. It is okay to use it on `public`
     * functions that are used as external entry points and are not called internally. Unless you know what you're
     * doing, it should never be used on `internal` functions. Failure to follow these rules can have critical security
     * implications! This is because the permissions are determined by the function that entered the contract, i.e. the
     * function at the bottom of the call stack, and not the function where the modifier is visible in the source code.
     * ====
     *
     * [WARNING]
     * ====
     * Avoid adding this modifier to the https://docs.soliditylang.org/en/v0.8.20/contracts.html#receive-ether-function[`receive()`]
     * function or the https://docs.soliditylang.org/en/v0.8.20/contracts.html#fallback-function[`fallback()`]. These
     * functions are the only execution paths where a function selector cannot be unambiguosly determined from the calldata
     * since the selector defaults to `0x00000000` in the `receive()` function and similarly in the `fallback()` function
     * if no calldata is provided. (See {_checkCanCall}).
     *
     * The `receive()` function will always panic whereas the `fallback()` may panic depending on the calldata length.
     * ====
     */
    modifier restricted() {
        _checkCanCall(_msgSender(), _msgData());
        _;
    }

    /// @inheritdoc IAccessManaged
    function authority() public view virtual returns (address) {
        AccessManagedStorage storage $ = _getAccessManagedStorage();
        return $._authority;
    }

    /// @inheritdoc IAccessManaged
    function setAuthority(address newAuthority) public virtual {
        address caller = _msgSender();
        if (caller != authority()) {
            revert AccessManagedUnauthorized(caller);
        }
        if (newAuthority.code.length == 0) {
            revert AccessManagedInvalidAuthority(newAuthority);
        }
        _setAuthority(newAuthority);
    }

    /// @inheritdoc IAccessManaged
    function isConsumingScheduledOp() public view returns (bytes4) {
        AccessManagedStorage storage $ = _getAccessManagedStorage();
        return $._consumingSchedule ? this.isConsumingScheduledOp.selector : bytes4(0);
    }

    /**
     * @dev Transfers control to a new authority. Internal function with no access restriction. Allows bypassing the
     * permissions set by the current authority.
     */
    function _setAuthority(address newAuthority) internal virtual {
        AccessManagedStorage storage $ = _getAccessManagedStorage();
        $._authority = newAuthority;
        emit AuthorityUpdated(newAuthority);
    }

    /**
     * @dev Reverts if the caller is not allowed to call the function identified by a selector. Panics if the calldata
     * is less than 4 bytes long.
     */
    function _checkCanCall(address caller, bytes calldata data) internal virtual {
        AccessManagedStorage storage $ = _getAccessManagedStorage();
        (bool immediate, uint32 delay) = AuthorityUtils.canCallWithDelay(
            authority(),
            caller,
            address(this),
            bytes4(data[0:4])
        );
        if (!immediate) {
            if (delay > 0) {
                $._consumingSchedule = true;
                IAccessManager(authority()).consumeScheduledOp(caller, data);
                $._consumingSchedule = false;
            } else {
                revert AccessManagedUnauthorized(caller);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.20;

import {IERC1822Proxiable} from "@openzeppelin/contracts/interfaces/draft-IERC1822.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {Initializable} from "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822Proxiable {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable __self = address(this);

    /**
     * @dev The version of the upgrade interface of the contract. If this getter is missing, both `upgradeTo(address)`
     * and `upgradeToAndCall(address,bytes)` are present, and `upgradeTo` must be used if no function should be called,
     * while `upgradeToAndCall` will invoke the `receive` function if the second argument is the empty byte string.
     * If the getter returns `"5.0.0"`, only `upgradeToAndCall(address,bytes)` is present, and the second argument must
     * be the empty byte string if no function should be called, making it impossible to invoke the `receive` function
     * during an upgrade.
     */
    string public constant UPGRADE_INTERFACE_VERSION = "5.0.0";

    /**
     * @dev The call is from an unauthorized context.
     */
    error UUPSUnauthorizedCallContext();

    /**
     * @dev The storage `slot` is unsupported as a UUID.
     */
    error UUPSUnsupportedProxiableUUID(bytes32 slot);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        _checkProxy();
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        _checkNotDelegated();
        _;
    }

    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual notDelegated returns (bytes32) {
        return ERC1967Utils.IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data);
    }

    /**
     * @dev Reverts if the execution is not performed via delegatecall or the execution
     * context is not of a proxy with an ERC1967-compliant implementation pointing to self.
     * See {_onlyProxy}.
     */
    function _checkProxy() internal view virtual {
        if (
            address(this) == __self || // Must be called through delegatecall
            ERC1967Utils.getImplementation() != __self // Must be called through an active proxy
        ) {
            revert UUPSUnauthorizedCallContext();
        }
    }

    /**
     * @dev Reverts if the execution is performed via delegatecall.
     * See {notDelegated}.
     */
    function _checkNotDelegated() internal view virtual {
        if (address(this) != __self) {
            // Must not be called through delegatecall
            revert UUPSUnauthorizedCallContext();
        }
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev Performs an implementation upgrade with a security check for UUPS proxies, and additional setup call.
     *
     * As a security check, {proxiableUUID} is invoked in the new implementation, and the return value
     * is expected to be the implementation slot in ERC1967.
     *
     * Emits an {IERC1967-Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data) private {
        try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
            if (slot != ERC1967Utils.IMPLEMENTATION_SLOT) {
                revert UUPSUnsupportedProxiableUUID(slot);
            }
            ERC1967Utils.upgradeToAndCall(newImplementation, data);
        } catch {
            // The implementation is not UUPS
            revert ERC1967Utils.ERC1967InvalidImplementation(newImplementation);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    /// @custom:storage-location erc7201:openzeppelin.storage.ReentrancyGuard
    struct ReentrancyGuardStorage {
        uint256 _status;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ReentrancyGuard")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ReentrancyGuardStorageLocation = 0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00;

    function _getReentrancyGuardStorage() private pure returns (ReentrancyGuardStorage storage $) {
        assembly {
            $.slot := ReentrancyGuardStorageLocation
        }
    }

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        $._status = NOT_ENTERED;
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
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if ($._status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        $._status = ENTERED;
    }

    function _nonReentrantAfter() private {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        $._status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        return $._status == ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Pausable
    struct PausableStorage {
        bool _paused;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Pausable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant PausableStorageLocation = 0xcd5ed15c6e187e77e9aee88184c21f4f2182ab5827cb3b7e07fbedcd63f03300;

    function _getPausableStorage() private pure returns (PausableStorage storage $) {
        assembly {
            $.slot := PausableStorageLocation
        }
    }

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        PausableStorage storage $ = _getPausableStorage();
        $._paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        PausableStorage storage $ = _getPausableStorage();
        return $._paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        PausableStorage storage $ = _getPausableStorage();
        $._paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        PausableStorage storage $ = _getPausableStorage();
        $._paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/ERC4626.sol)

pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ERC20Upgradeable} from "../ERC20Upgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Initializable} from "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the ERC4626 "Tokenized Vault Standard" as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[EIP-4626].
 *
 * This extension allows the minting and burning of "shares" (represented using the ERC20 inheritance) in exchange for
 * underlying "assets" through standardized {deposit}, {mint}, {redeem} and {burn} workflows. This contract extends
 * the ERC20 standard. Any additional extensions included along it would affect the "shares" token represented by this
 * contract and not the "assets" token which is an independent contract.
 *
 * [CAUTION]
 * ====
 * In empty (or nearly empty) ERC-4626 vaults, deposits are at high risk of being stolen through frontrunning
 * with a "donation" to the vault that inflates the price of a share. This is variously known as a donation or inflation
 * attack and is essentially a problem of slippage. Vault deployers can protect against this attack by making an initial
 * deposit of a non-trivial amount of the asset, such that price manipulation becomes infeasible. Withdrawals may
 * similarly be affected by slippage. Users can protect against this attack as well as unexpected slippage in general by
 * verifying the amount received is as expected, using a wrapper that performs these checks such as
 * https://github.com/fei-protocol/ERC4626#erc4626router-and-base[ERC4626Router].
 *
 * Since v4.9, this implementation uses virtual assets and shares to mitigate that risk. The `_decimalsOffset()`
 * corresponds to an offset in the decimal representation between the underlying asset's decimals and the vault
 * decimals. This offset also determines the rate of virtual shares to virtual assets in the vault, which itself
 * determines the initial exchange rate. While not fully preventing the attack, analysis shows that the default offset
 * (0) makes it non-profitable, as a result of the value being captured by the virtual shares (out of the attacker's
 * donation) matching the attacker's expected gains. With a larger offset, the attack becomes orders of magnitude more
 * expensive than it is profitable. More details about the underlying math can be found
 * xref:erc4626.adoc#inflation-attack[here].
 *
 * The drawback of this approach is that the virtual shares do capture (a very small) part of the value being accrued
 * to the vault. Also, if the vault experiences losses, the users try to exit the vault, the virtual shares and assets
 * will cause the first user to exit to experience reduced losses in detriment to the last users that will experience
 * bigger losses. Developers willing to revert back to the pre-v4.9 behavior just need to override the
 * `_convertToShares` and `_convertToAssets` functions.
 *
 * To learn more, check out our xref:ROOT:erc4626.adoc[ERC-4626 guide].
 * ====
 */
abstract contract ERC4626Upgradeable is Initializable, ERC20Upgradeable, IERC4626 {
    using Math for uint256;

    /// @custom:storage-location erc7201:openzeppelin.storage.ERC4626
    struct ERC4626Storage {
        IERC20 _asset;
        uint8 _underlyingDecimals;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ERC4626")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ERC4626StorageLocation = 0x0773e532dfede91f04b12a73d3d2acd361424f41f76b4fb79f090161e36b4e00;

    function _getERC4626Storage() private pure returns (ERC4626Storage storage $) {
        assembly {
            $.slot := ERC4626StorageLocation
        }
    }

    /**
     * @dev Attempted to deposit more assets than the max amount for `receiver`.
     */
    error ERC4626ExceededMaxDeposit(address receiver, uint256 assets, uint256 max);

    /**
     * @dev Attempted to mint more shares than the max amount for `receiver`.
     */
    error ERC4626ExceededMaxMint(address receiver, uint256 shares, uint256 max);

    /**
     * @dev Attempted to withdraw more assets than the max amount for `receiver`.
     */
    error ERC4626ExceededMaxWithdraw(address owner, uint256 assets, uint256 max);

    /**
     * @dev Attempted to redeem more shares than the max amount for `receiver`.
     */
    error ERC4626ExceededMaxRedeem(address owner, uint256 shares, uint256 max);

    /**
     * @dev Set the underlying asset contract. This must be an ERC20-compatible contract (ERC20 or ERC777).
     */
    function __ERC4626_init(IERC20 asset_) internal onlyInitializing {
        __ERC4626_init_unchained(asset_);
    }

    function __ERC4626_init_unchained(IERC20 asset_) internal onlyInitializing {
        ERC4626Storage storage $ = _getERC4626Storage();
        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(asset_);
        $._underlyingDecimals = success ? assetDecimals : 18;
        $._asset = asset_;
    }

    /**
     * @dev Attempts to fetch the asset decimals. A return value of false indicates that the attempt failed in some way.
     */
    function _tryGetAssetDecimals(IERC20 asset_) private view returns (bool, uint8) {
        (bool success, bytes memory encodedDecimals) = address(asset_).staticcall(
            abi.encodeCall(IERC20Metadata.decimals, ())
        );
        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }

    /**
     * @dev Decimals are computed by adding the decimal offset on top of the underlying asset's decimals. This
     * "original" value is cached during construction of the vault contract. If this read operation fails (e.g., the
     * asset has not been created yet), a default of 18 is used to represent the underlying asset's decimals.
     *
     * See {IERC20Metadata-decimals}.
     */
    function decimals() public view virtual override(IERC20Metadata, ERC20Upgradeable) returns (uint8) {
        ERC4626Storage storage $ = _getERC4626Storage();
        return $._underlyingDecimals + _decimalsOffset();
    }

    /** @dev See {IERC4626-asset}. */
    function asset() public view virtual returns (address) {
        ERC4626Storage storage $ = _getERC4626Storage();
        return address($._asset);
    }

    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view virtual returns (uint256) {
        ERC4626Storage storage $ = _getERC4626Storage();
        return $._asset.balanceOf(address(this));
    }

    /** @dev See {IERC4626-convertToShares}. */
    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Floor);
    }

    /** @dev See {IERC4626-convertToAssets}. */
    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Floor);
    }

    /** @dev See {IERC4626-maxDeposit}. */
    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxMint}. */
    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxWithdraw}. */
    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return _convertToAssets(balanceOf(owner), Math.Rounding.Floor);
    }

    /** @dev See {IERC4626-maxRedeem}. */
    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf(owner);
    }

    /** @dev See {IERC4626-previewDeposit}. */
    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Floor);
    }

    /** @dev See {IERC4626-previewMint}. */
    function previewMint(uint256 shares) public view virtual returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Ceil);
    }

    /** @dev See {IERC4626-previewWithdraw}. */
    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Ceil);
    }

    /** @dev See {IERC4626-previewRedeem}. */
    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Floor);
    }

    /** @dev See {IERC4626-deposit}. */
    function deposit(uint256 assets, address receiver) public virtual returns (uint256) {
        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-mint}.
     *
     * As opposed to {deposit}, minting is allowed even if the vault is in a state where the price of a share is zero.
     * In this case, the shares will be minted without requiring any assets to be deposited.
     */
    function mint(uint256 shares, address receiver) public virtual returns (uint256) {
        uint256 maxShares = maxMint(receiver);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxMint(receiver, shares, maxShares);
        }

        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }

    /** @dev See {IERC4626-withdraw}. */
    function withdraw(uint256 assets, address receiver, address owner) public virtual returns (uint256) {
        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-redeem}. */
    function redeem(uint256 shares, address receiver, address owner) public virtual returns (uint256) {
        uint256 maxShares = maxRedeem(owner);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(owner, shares, maxShares);
        }

        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view virtual returns (uint256) {
        return assets.mulDiv(totalSupply() + 10 ** _decimalsOffset(), totalAssets() + 1, rounding);
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view virtual returns (uint256) {
        return shares.mulDiv(totalAssets() + 1, totalSupply() + 10 ** _decimalsOffset(), rounding);
    }

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal virtual {
        ERC4626Storage storage $ = _getERC4626Storage();
        // If _asset is ERC777, `transferFrom` can trigger a reentrancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20.safeTransferFrom($._asset, caller, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Withdraw/redeem common workflow.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        ERC4626Storage storage $ = _getERC4626Storage();
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transferred, which is a valid state.
        _burn(owner, shares);
        SafeERC20.safeTransfer($._asset, receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function _decimalsOffset() internal view virtual returns (uint8) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 <0.9.0;

import "./_internal/Utils.sol";

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IBalancer.sol";
import "../interfaces/uniswap/IV3SwapRouter.sol";

contract SwapExecutor {
    using SafeERC20 for IERC20;
    IV3SwapRouter public immutable UNISWAP_ROUTER;
    uint24 public immutable UNISWAP_POOL_FEE;

    constructor(uint24 _uniswapPoolFee, address _uniswapRouter) {
        UNISWAP_POOL_FEE = _uniswapPoolFee;
        UNISWAP_ROUTER = IV3SwapRouter(_uniswapRouter);
    }

    function executeSwaps(IBalancer.SwapInfo[] calldata swaps) public {
        for (uint i = 0; i < swaps.length; i++) {
            IBalancer.SwapInfo calldata swap = swaps[i];
            IERC20(swap.token).forceApprove(swap.callee, swap.amount);
            Address.functionCall(swap.callee, swap.data);
        }
    }

    function defaultSwap(
        address fromToken,
        address toToken,
        uint256 amountOutMinimum
    ) external virtual returns (uint256 toAmount) {
        uint256 fromAmount = IERC20(fromToken).balanceOf(address(this));
        IERC20(fromToken).forceApprove(address(UNISWAP_ROUTER), fromAmount);

        toAmount = UNISWAP_ROUTER.exactInputSingle(
            IV3SwapRouter.ExactInputSingleParams(
                fromToken,
                toToken,
                UNISWAP_POOL_FEE,
                msg.sender,
                fromAmount,
                amountOutMinimum,
                0
            )
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/access/manager/IAccessManaged.sol";

interface IWrapper is IERC4626, IAccessManaged {

    // TODO move to common library
    struct TransferInfo {
        uint256 amount; // amount to transfer
        address token; // token to transfer
    }

    function investOrigin(address dustReceiver) external returns (uint shares);
    function investOrigin(address receiver, address dustReceiver) external returns (uint shares);
    function redeemOrigin(uint lpAmount, address receiver)
        external
        returns (
            address[] memory tokens,
            uint[] memory amounts
        );
    function claimSimple(address receiver) external;
    function claim(address receiver)
        external
        returns (address[] memory rewardTokens, uint[] memory rewardsClaimed, uint[] memory rewardBalances);
    function recoverFunds(TransferInfo calldata transfer, address to) external;

    function negotiableTokens() external returns(address[] memory tokens);
    function depositTokens() external returns (address[] memory tokens);
    function rewardTokens() external returns(address[] memory tokens);
    function poolTokens() external returns(address[] memory tokens);
    function ratios() external returns(address[] memory tokens, uint[] memory ratio);
    function description() external returns (string memory);

    function pendingRewards() external returns(address[] memory tokens, uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/manager/IAuthority.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard interface for permissioning originally defined in Dappsys.
 */
interface IAuthority {
    /**
     * @dev Returns true if the caller can invoke on a target the function identified by a function selector.
     */
    function canCall(address caller, address target, bytes4 selector) external view returns (bool allowed);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/manager/AuthorityUtils.sol)

pragma solidity ^0.8.20;

import {IAuthority} from "./IAuthority.sol";

library AuthorityUtils {
    /**
     * @dev Since `AccessManager` implements an extended IAuthority interface, invoking `canCall` with backwards compatibility
     * for the preexisting `IAuthority` interface requires special care to avoid reverting on insufficient return data.
     * This helper function takes care of invoking `canCall` in a backwards compatible way without reverting.
     */
    function canCallWithDelay(
        address authority,
        address caller,
        address target,
        bytes4 selector
    ) internal view returns (bool immediate, uint32 delay) {
        (bool success, bytes memory data) = authority.staticcall(
            abi.encodeCall(IAuthority.canCall, (caller, target, selector))
        );
        if (success) {
            if (data.length >= 0x40) {
                (immediate, delay) = abi.decode(data, (bool, uint32));
            } else if (data.length >= 0x20) {
                immediate = abi.decode(data, (bool));
            }
        }
        return (immediate, delay);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/manager/IAccessManager.sol)

pragma solidity ^0.8.20;

import {IAccessManaged} from "./IAccessManaged.sol";
import {Time} from "../../utils/types/Time.sol";

interface IAccessManager {
    /**
     * @dev A delayed operation was scheduled.
     */
    event OperationScheduled(
        bytes32 indexed operationId,
        uint32 indexed nonce,
        uint48 schedule,
        address caller,
        address target,
        bytes data
    );

    /**
     * @dev A scheduled operation was executed.
     */
    event OperationExecuted(bytes32 indexed operationId, uint32 indexed nonce);

    /**
     * @dev A scheduled operation was canceled.
     */
    event OperationCanceled(bytes32 indexed operationId, uint32 indexed nonce);

    /**
     * @dev Informational labelling for a roleId.
     */
    event RoleLabel(uint64 indexed roleId, string label);

    /**
     * @dev Emitted when `account` is granted `roleId`.
     *
     * NOTE: The meaning of the `since` argument depends on the `newMember` argument.
     * If the role is granted to a new member, the `since` argument indicates when the account becomes a member of the role,
     * otherwise it indicates the execution delay for this account and roleId is updated.
     */
    event RoleGranted(uint64 indexed roleId, address indexed account, uint32 delay, uint48 since, bool newMember);

    /**
     * @dev Emitted when `account` membership or `roleId` is revoked. Unlike granting, revoking is instantaneous.
     */
    event RoleRevoked(uint64 indexed roleId, address indexed account);

    /**
     * @dev Role acting as admin over a given `roleId` is updated.
     */
    event RoleAdminChanged(uint64 indexed roleId, uint64 indexed admin);

    /**
     * @dev Role acting as guardian over a given `roleId` is updated.
     */
    event RoleGuardianChanged(uint64 indexed roleId, uint64 indexed guardian);

    /**
     * @dev Grant delay for a given `roleId` will be updated to `delay` when `since` is reached.
     */
    event RoleGrantDelayChanged(uint64 indexed roleId, uint32 delay, uint48 since);

    /**
     * @dev Target mode is updated (true = closed, false = open).
     */
    event TargetClosed(address indexed target, bool closed);

    /**
     * @dev Role required to invoke `selector` on `target` is updated to `roleId`.
     */
    event TargetFunctionRoleUpdated(address indexed target, bytes4 selector, uint64 indexed roleId);

    /**
     * @dev Admin delay for a given `target` will be updated to `delay` when `since` is reached.
     */
    event TargetAdminDelayUpdated(address indexed target, uint32 delay, uint48 since);

    error AccessManagerAlreadyScheduled(bytes32 operationId);
    error AccessManagerNotScheduled(bytes32 operationId);
    error AccessManagerNotReady(bytes32 operationId);
    error AccessManagerExpired(bytes32 operationId);
    error AccessManagerLockedAccount(address account);
    error AccessManagerLockedRole(uint64 roleId);
    error AccessManagerBadConfirmation();
    error AccessManagerUnauthorizedAccount(address msgsender, uint64 roleId);
    error AccessManagerUnauthorizedCall(address caller, address target, bytes4 selector);
    error AccessManagerUnauthorizedConsume(address target);
    error AccessManagerUnauthorizedCancel(address msgsender, address caller, address target, bytes4 selector);
    error AccessManagerInvalidInitialAdmin(address initialAdmin);

    /**
     * @dev Check if an address (`caller`) is authorised to call a given function on a given contract directly (with
     * no restriction). Additionally, it returns the delay needed to perform the call indirectly through the {schedule}
     * & {execute} workflow.
     *
     * This function is usually called by the targeted contract to control immediate execution of restricted functions.
     * Therefore we only return true if the call can be performed without any delay. If the call is subject to a
     * previously set delay (not zero), then the function should return false and the caller should schedule the operation
     * for future execution.
     *
     * If `immediate` is true, the delay can be disregarded and the operation can be immediately executed, otherwise
     * the operation can be executed if and only if delay is greater than 0.
     *
     * NOTE: The IAuthority interface does not include the `uint32` delay. This is an extension of that interface that
     * is backward compatible. Some contracts may thus ignore the second return argument. In that case they will fail
     * to identify the indirect workflow, and will consider calls that require a delay to be forbidden.
     *
     * NOTE: This function does not report the permissions of this manager itself. These are defined by the
     * {_canCallSelf} function instead.
     */
    function canCall(
        address caller,
        address target,
        bytes4 selector
    ) external view returns (bool allowed, uint32 delay);

    /**
     * @dev Expiration delay for scheduled proposals. Defaults to 1 week.
     *
     * IMPORTANT: Avoid overriding the expiration with 0. Otherwise every contract proposal will be expired immediately,
     * disabling any scheduling usage.
     */
    function expiration() external view returns (uint32);

    /**
     * @dev Minimum setback for all delay updates, with the exception of execution delays. It
     * can be increased without setback (and reset via {revokeRole} in the case event of an
     * accidental increase). Defaults to 5 days.
     */
    function minSetback() external view returns (uint32);

    /**
     * @dev Get whether the contract is closed disabling any access. Otherwise role permissions are applied.
     */
    function isTargetClosed(address target) external view returns (bool);

    /**
     * @dev Get the role required to call a function.
     */
    function getTargetFunctionRole(address target, bytes4 selector) external view returns (uint64);

    /**
     * @dev Get the admin delay for a target contract. Changes to contract configuration are subject to this delay.
     */
    function getTargetAdminDelay(address target) external view returns (uint32);

    /**
     * @dev Get the id of the role that acts as an admin for the given role.
     *
     * The admin permission is required to grant the role, revoke the role and update the execution delay to execute
     * an operation that is restricted to this role.
     */
    function getRoleAdmin(uint64 roleId) external view returns (uint64);

    /**
     * @dev Get the role that acts as a guardian for a given role.
     *
     * The guardian permission allows canceling operations that have been scheduled under the role.
     */
    function getRoleGuardian(uint64 roleId) external view returns (uint64);

    /**
     * @dev Get the role current grant delay.
     *
     * Its value may change at any point without an event emitted following a call to {setGrantDelay}.
     * Changes to this value, including effect timepoint are notified in advance by the {RoleGrantDelayChanged} event.
     */
    function getRoleGrantDelay(uint64 roleId) external view returns (uint32);

    /**
     * @dev Get the access details for a given account for a given role. These details include the timepoint at which
     * membership becomes active, and the delay applied to all operation by this user that requires this permission
     * level.
     *
     * Returns:
     * [0] Timestamp at which the account membership becomes valid. 0 means role is not granted.
     * [1] Current execution delay for the account.
     * [2] Pending execution delay for the account.
     * [3] Timestamp at which the pending execution delay will become active. 0 means no delay update is scheduled.
     */
    function getAccess(uint64 roleId, address account) external view returns (uint48, uint32, uint32, uint48);

    /**
     * @dev Check if a given account currently has the permission level corresponding to a given role. Note that this
     * permission might be associated with an execution delay. {getAccess} can provide more details.
     */
    function hasRole(uint64 roleId, address account) external view returns (bool, uint32);

    /**
     * @dev Give a label to a role, for improved role discoverability by UIs.
     *
     * Requirements:
     *
     * - the caller must be a global admin
     *
     * Emits a {RoleLabel} event.
     */
    function labelRole(uint64 roleId, string calldata label) external;

    /**
     * @dev Add `account` to `roleId`, or change its execution delay.
     *
     * This gives the account the authorization to call any function that is restricted to this role. An optional
     * execution delay (in seconds) can be set. If that delay is non 0, the user is required to schedule any operation
     * that is restricted to members of this role. The user will only be able to execute the operation after the delay has
     * passed, before it has expired. During this period, admin and guardians can cancel the operation (see {cancel}).
     *
     * If the account has already been granted this role, the execution delay will be updated. This update is not
     * immediate and follows the delay rules. For example, if a user currently has a delay of 3 hours, and this is
     * called to reduce that delay to 1 hour, the new delay will take some time to take effect, enforcing that any
     * operation executed in the 3 hours that follows this update was indeed scheduled before this update.
     *
     * Requirements:
     *
     * - the caller must be an admin for the role (see {getRoleAdmin})
     * - granted role must not be the `PUBLIC_ROLE`
     *
     * Emits a {RoleGranted} event.
     */
    function grantRole(uint64 roleId, address account, uint32 executionDelay) external;

    /**
     * @dev Remove an account from a role, with immediate effect. If the account does not have the role, this call has
     * no effect.
     *
     * Requirements:
     *
     * - the caller must be an admin for the role (see {getRoleAdmin})
     * - revoked role must not be the `PUBLIC_ROLE`
     *
     * Emits a {RoleRevoked} event if the account had the role.
     */
    function revokeRole(uint64 roleId, address account) external;

    /**
     * @dev Renounce role permissions for the calling account with immediate effect. If the sender is not in
     * the role this call has no effect.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     *
     * Emits a {RoleRevoked} event if the account had the role.
     */
    function renounceRole(uint64 roleId, address callerConfirmation) external;

    /**
     * @dev Change admin role for a given role.
     *
     * Requirements:
     *
     * - the caller must be a global admin
     *
     * Emits a {RoleAdminChanged} event
     */
    function setRoleAdmin(uint64 roleId, uint64 admin) external;

    /**
     * @dev Change guardian role for a given role.
     *
     * Requirements:
     *
     * - the caller must be a global admin
     *
     * Emits a {RoleGuardianChanged} event
     */
    function setRoleGuardian(uint64 roleId, uint64 guardian) external;

    /**
     * @dev Update the delay for granting a `roleId`.
     *
     * Requirements:
     *
     * - the caller must be a global admin
     *
     * Emits a {RoleGrantDelayChanged} event.
     */
    function setGrantDelay(uint64 roleId, uint32 newDelay) external;

    /**
     * @dev Set the role required to call functions identified by the `selectors` in the `target` contract.
     *
     * Requirements:
     *
     * - the caller must be a global admin
     *
     * Emits a {TargetFunctionRoleUpdated} event per selector.
     */
    function setTargetFunctionRole(address target, bytes4[] calldata selectors, uint64 roleId) external;

    /**
     * @dev Set the delay for changing the configuration of a given target contract.
     *
     * Requirements:
     *
     * - the caller must be a global admin
     *
     * Emits a {TargetAdminDelayUpdated} event.
     */
    function setTargetAdminDelay(address target, uint32 newDelay) external;

    /**
     * @dev Set the closed flag for a contract.
     *
     * Requirements:
     *
     * - the caller must be a global admin
     *
     * Emits a {TargetClosed} event.
     */
    function setTargetClosed(address target, bool closed) external;

    /**
     * @dev Return the timepoint at which a scheduled operation will be ready for execution. This returns 0 if the
     * operation is not yet scheduled, has expired, was executed, or was canceled.
     */
    function getSchedule(bytes32 id) external view returns (uint48);

    /**
     * @dev Return the nonce for the latest scheduled operation with a given id. Returns 0 if the operation has never
     * been scheduled.
     */
    function getNonce(bytes32 id) external view returns (uint32);

    /**
     * @dev Schedule a delayed operation for future execution, and return the operation identifier. It is possible to
     * choose the timestamp at which the operation becomes executable as long as it satisfies the execution delays
     * required for the caller. The special value zero will automatically set the earliest possible time.
     *
     * Returns the `operationId` that was scheduled. Since this value is a hash of the parameters, it can reoccur when
     * the same parameters are used; if this is relevant, the returned `nonce` can be used to uniquely identify this
     * scheduled operation from other occurrences of the same `operationId` in invocations of {execute} and {cancel}.
     *
     * Emits a {OperationScheduled} event.
     *
     * NOTE: It is not possible to concurrently schedule more than one operation with the same `target` and `data`. If
     * this is necessary, a random byte can be appended to `data` to act as a salt that will be ignored by the target
     * contract if it is using standard Solidity ABI encoding.
     */
    function schedule(address target, bytes calldata data, uint48 when) external returns (bytes32, uint32);

    /**
     * @dev Execute a function that is delay restricted, provided it was properly scheduled beforehand, or the
     * execution delay is 0.
     *
     * Returns the nonce that identifies the previously scheduled operation that is executed, or 0 if the
     * operation wasn't previously scheduled (if the caller doesn't have an execution delay).
     *
     * Emits an {OperationExecuted} event only if the call was scheduled and delayed.
     */
    function execute(address target, bytes calldata data) external payable returns (uint32);

    /**
     * @dev Cancel a scheduled (delayed) operation. Returns the nonce that identifies the previously scheduled
     * operation that is cancelled.
     *
     * Requirements:
     *
     * - the caller must be the proposer, a guardian of the targeted function, or a global admin
     *
     * Emits a {OperationCanceled} event.
     */
    function cancel(address caller, address target, bytes calldata data) external returns (uint32);

    /**
     * @dev Consume a scheduled operation targeting the caller. If such an operation exists, mark it as consumed
     * (emit an {OperationExecuted} event and clean the state). Otherwise, throw an error.
     *
     * This is useful for contract that want to enforce that calls targeting them were scheduled on the manager,
     * with all the verifications that it implies.
     *
     * Emit a {OperationExecuted} event.
     */
    function consumeScheduledOp(address caller, bytes calldata data) external;

    /**
     * @dev Hashing function for delayed operations.
     */
    function hashOperation(address caller, address target, bytes calldata data) external view returns (bytes32);

    /**
     * @dev Changes the authority of a target managed by this manager instance.
     *
     * Requirements:
     *
     * - the caller must be a global admin
     */
    function updateAuthority(address target, address newAuthority) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/manager/IAccessManaged.sol)

pragma solidity ^0.8.20;

interface IAccessManaged {
    /**
     * @dev Authority that manages this contract was updated.
     */
    event AuthorityUpdated(address authority);

    error AccessManagedUnauthorized(address caller);
    error AccessManagedRequiredDelay(address caller, uint32 delay);
    error AccessManagedInvalidAuthority(address authority);

    /**
     * @dev Returns the current authority.
     */
    function authority() external view returns (address);

    /**
     * @dev Transfers control to a new authority. The caller must be the current authority.
     */
    function setAuthority(address) external;

    /**
     * @dev Returns true only in the context of a delayed restricted call, at the moment that the scheduled operation is
     * being consumed. Prevents denial of service for delayed restricted calls in the case that the contract performs
     * attacker controlled calls.
     */
    function isConsumingScheduledOp() external view returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.20;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/ERC1967/ERC1967Utils.sol)

pragma solidity ^0.8.20;

import {IBeacon} from "../beacon/IBeacon.sol";
import {Address} from "../../utils/Address.sol";
import {StorageSlot} from "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 */
library ERC1967Utils {
    // We re-declare ERC-1967 events here because they can't be used directly from IERC1967.
    // This will be fixed in Solidity 0.8.21. At that point we should remove these events.
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev The `implementation` of the proxy is invalid.
     */
    error ERC1967InvalidImplementation(address implementation);

    /**
     * @dev The `admin` of the proxy is invalid.
     */
    error ERC1967InvalidAdmin(address admin);

    /**
     * @dev The `beacon` of the proxy is invalid.
     */
    error ERC1967InvalidBeacon(address beacon);

    /**
     * @dev An upgrade function sees `msg.value > 0` that may be lost.
     */
    error ERC1967NonPayable();

    /**
     * @dev Returns the current implementation address.
     */
    function getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        if (newImplementation.code.length == 0) {
            revert ERC1967InvalidImplementation(newImplementation);
        }
        StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Performs implementation upgrade with additional setup call if data is nonempty.
     * This function is payable only if the setup call is performed, otherwise `msg.value` is rejected
     * to avoid stuck value in the contract.
     *
     * Emits an {IERC1967-Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);

        if (data.length > 0) {
            Address.functionDelegateCall(newImplementation, data);
        } else {
            _checkNonPayable();
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using
     * the https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        if (newAdmin == address(0)) {
            revert ERC1967InvalidAdmin(address(0));
        }
        StorageSlot.getAddressSlot(ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {IERC1967-AdminChanged} event.
     */
    function changeAdmin(address newAdmin) internal {
        emit AdminChanged(getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is the keccak-256 hash of "eip1967.proxy.beacon" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        if (newBeacon.code.length == 0) {
            revert ERC1967InvalidBeacon(newBeacon);
        }

        StorageSlot.getAddressSlot(BEACON_SLOT).value = newBeacon;

        address beaconImplementation = IBeacon(newBeacon).implementation();
        if (beaconImplementation.code.length == 0) {
            revert ERC1967InvalidImplementation(beaconImplementation);
        }
    }

    /**
     * @dev Change the beacon and trigger a setup call if data is nonempty.
     * This function is payable only if the setup call is performed, otherwise `msg.value` is rejected
     * to avoid stuck value in the contract.
     *
     * Emits an {IERC1967-BeaconUpgraded} event.
     *
     * CAUTION: Invoking this function has no effect on an instance of {BeaconProxy} since v5, since
     * it uses an immutable beacon without looking at the value of the ERC-1967 beacon slot for
     * efficiency.
     */
    function upgradeBeaconToAndCall(address newBeacon, bytes memory data) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);

        if (data.length > 0) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        } else {
            _checkNonPayable();
        }
    }

    /**
     * @dev Reverts if `msg.value` is not zero. It can be used to avoid `msg.value` stuck in the contract
     * if an upgrade doesn't perform an initialization call.
     */
    function _checkNonPayable() private {
        if (msg.value > 0) {
            revert ERC1967NonPayable();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ContextUpgradeable} from "../../utils/ContextUpgradeable.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Initializable} from "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 */
abstract contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20, IERC20Metadata, IERC20Errors {
    /// @custom:storage-location erc7201:openzeppelin.storage.ERC20
    struct ERC20Storage {
        mapping(address account => uint256) _balances;

        mapping(address account => mapping(address spender => uint256)) _allowances;

        uint256 _totalSupply;

        string _name;
        string _symbol;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ERC20")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ERC20StorageLocation = 0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace00;

    function _getERC20Storage() private pure returns (ERC20Storage storage $) {
        assembly {
            $.slot := ERC20StorageLocation
        }
    }

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        ERC20Storage storage $ = _getERC20Storage();
        $._name = name_;
        $._symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        ERC20Storage storage $ = _getERC20Storage();
        return $._name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        ERC20Storage storage $ = _getERC20Storage();
        return $._symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        ERC20Storage storage $ = _getERC20Storage();
        return $._totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        ERC20Storage storage $ = _getERC20Storage();
        return $._balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        ERC20Storage storage $ = _getERC20Storage();
        return $._allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        ERC20Storage storage $ = _getERC20Storage();
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            $._totalSupply += value;
        } else {
            uint256 fromBalance = $._balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                $._balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                $._totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                $._balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        ERC20Storage storage $ = _getERC20Storage();
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        $._allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../token/ERC20/IERC20.sol";
import {IERC20Metadata} from "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 <0.9.0;

import {fmt} from "./Fmt.sol";

uint256 constant UINT256_MAX = type(uint256).max;
uint256 constant INT256_MIN_ABS = uint256(type(int256).max) + 1;

// Extracted from forge-std stdUtils: https://github.com/foundry-rs/forge-std/blob/7b4876e8de2a232a54159035f173e35421000c19/src/StdUtils.sol
// The main difference is that we use file-level functions instead of an abstract contract.
function bound(uint256 x, uint256 min, uint256 max) pure returns (uint256 result) {
    require(min <= max, formatError("_utils", "bound(uint256,uint256,uint256)", "Max is less than min."));
    // If x is between min and max, return x directly. This is to ensure that dictionary values
    // do not get shifted if the min is nonzero. More info: https://github.com/foundry-rs/forge-std/issues/188
    if (x >= min && x <= max) return x;

    uint256 size = max - min + 1;

    // If the value is 0, 1, 2, 3, wrap that to min, min+1, min+2, min+3. Similarly for the UINT256_MAX side.
    // This helps ensure coverage of the min/max values.
    if (x <= 3 && size > x) return min + x;
    if (x >= UINT256_MAX - 3 && size > UINT256_MAX - x) return max - (UINT256_MAX - x);

    // Otherwise, wrap x into the range [min, max], i.e. the range is inclusive.
    if (x > max) {
        uint256 diff = x - max;
        uint256 rem = diff % size;
        if (rem == 0) return max;
        result = min + rem - 1;
    } else if (x < min) {
        uint256 diff = min - x;
        uint256 rem = diff % size;
        if (rem == 0) return min;
        result = max - rem + 1;
    }
}

function bound(int256 x, int256 min, int256 max) pure returns (int256 result) {
    require(min <= max, formatError("_utils", "bound(int256,int256,int256)", "Max is less than min."));

    // Shifting all int256 values to uint256 to use _bound function. The range of two types are:
    // int256 : -(2**255) ~ (2**255 - 1)
    // uint256:     0     ~ (2**256 - 1)
    // So, add 2**255, INT256_MIN_ABS to the integer values.
    //
    // If the given integer value is -2**255, we cannot use `-uint256(-x)` because of the overflow.
    // So, use `~uint256(x) + 1` instead.
    uint256 _x = x < 0 ? (INT256_MIN_ABS - ~uint256(x) - 1) : (uint256(x) + INT256_MIN_ABS);
    uint256 _min = min < 0 ? (INT256_MIN_ABS - ~uint256(min) - 1) : (uint256(min) + INT256_MIN_ABS);
    uint256 _max = max < 0 ? (INT256_MIN_ABS - ~uint256(max) - 1) : (uint256(max) + INT256_MIN_ABS);

    uint256 y = bound(_x, _min, _max);

    // To move it back to int256 value, subtract INT256_MIN_ABS at here.
    result = y < INT256_MIN_ABS ? int256(~(INT256_MIN_ABS - y) + 1) : int256(y - INT256_MIN_ABS);
}

// Adapted from forge-std stdMath https://github.com/foundry-rs/forge-std/blob/c2236853aadb8e2d9909bbecdc490099519b70a4/src/StdMath.sol#L7
function abs(int256 a) pure returns (uint256) {
    if (a == type(int256).min) {
        return uint256(type(int256).max) + 1;
    }

    return uint256(a > 0 ? a : -a);
}

function delta(uint256 a, uint256 b) pure returns (uint256) {
    return a > b ? a - b : b - a;
}

// Adapted from forge-std stdMath https://github.com/foundry-rs/forge-std/blob/c2236853aadb8e2d9909bbecdc490099519b70a4/src/StdMath.sol#L20
function delta(int256 a, int256 b) pure returns (uint256) {
    uint256 absA = abs(a);
    uint256 absB = abs(b);

    // Same sign
    if ((a ^ b) > -1) {
        return delta(absA, absB);
    } else {
        return absA + absB;
    }
}

function format(string memory template, bytes memory args) pure returns (string memory) {
    return fmt.format(template, args);
}

function formatError(string memory module, string memory func, string memory message) pure returns (string memory) {
    return string.concat("vulcan.", module, ".", func, ": ", message);
}

function println(string memory template, bytes memory args) view {
    rawConsoleLog(fmt.format(template, args));
}

function println(string memory arg) view {
    rawConsoleLog(arg);
}

function rawConsoleLog(string memory arg) view {
    address console2Addr = 0x000000000000000000636F6e736F6c652e6c6f67;
    (bool status,) = console2Addr.staticcall(abi.encodeWithSignature("log(string)", arg));
    status;
}

function removeSelector(bytes memory data) pure returns (bytes memory) {
    require(data.length >= 4, "Input data is too short");

    // Create a new bytes variable to store the result
    bytes memory result = new bytes(data.length - 4);

    // Copy the remaining data (excluding the first 4 bytes) into the result
    for (uint256 i = 4; i < data.length; i++) {
        result[i - 4] = data[i];
    }

    return result;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "./IAdapter.sol";
import "./ISwapProvider.sol";

interface IBalancer is ISwapProvider {

    struct AdapterCache {
        uint value;    // equivalent value
        uint lpAmount; // amount of controlled underlying LP tokens
    }

    event Invest(address indexed adapter, address from, uint totalValueBefore, uint valueAdded, uint sharesWithFee, uint sharesMinted);
    event Redeem(address indexed adapter, address to, uint shares, uint totalValueBefore, uint valueSubtracted);
    event Rebalance(address indexed fromAdapter, address indexed toAdapter, uint amount);
    event FeeLocked(uint valueBefore, uint feeLocked, uint lockedUntil);
    event AdapterActivityChanged(address adapter, bool active);
    event AdapterAdded(address adapter);
    event AdapterRemoved(address adapter);
    event FeeReceiverChanged(address oldFeeReceiver, address newFeeReceiver);
    event Compound(address adapter, uint totalValueBefore, uint valueAdded, uint tokensBought, uint fee);
    event RewardLocked(uint256 reward, uint lockedUntil);
    event TakePerformanceFee(uint112 feeValue, uint totalValue);
    event Harvest(address indexed user, uint256 reward);
    event SwapPoolAddressAdded(address);
    event SwapPoolAddressRemoved(address);
    event Donated(address donor, uint amount);

    error InsufficientFunds(uint has, uint wants);
    error AdapterRedeemExceeds(uint adapterValue, uint redeemValue);
    error EmptyRedeem(uint shares, uint redeemValue, address adapter, uint adapterValue, uint adapterLpAmount);
    error SharesInflationError(uint valueAdded, uint valuePrior);
    error InvalidAdapter(address adapter);
    error ValueLost(uint diff);
    error MinRebalanceSlippageExceeds(uint minRebalancedValue, uint actualValueAfter);
    error Cooldown(uint until);
    error AdapterNotEmpty(address adapter);
    error DeactivationFailed(address adapter);
    error InvalidPerformanceFee(uint performanceFee);
    error HugePerformanceFee(uint performanceFee, uint totalValue);
    error Expired(uint deadline);
    error UpgradeAdaptersDontMatch(address sourceAdapter, address targetAdatper);
    error ArrayIndexOutOfBounds();

    function invest(address targetAdapter, address receiver) external returns (uint sharesAdded);
    function invest(address targetAdapter, address receiver, address dustReceiver) external returns (uint sharesAdded);
    function redeem(uint shares, IAdapter targetAdapter, address receiver)
        external
        returns (
            address[] memory tokens,
            uint[] memory amounts
        );
    function totalNAV() external view returns (uint nav, uint112 lockedFee);
    function totalValue() external view returns (uint value);
    function adapters() external view returns (address[] memory);
    function chargedAdapters() external view returns (address[] memory);

    //╔═══════════════════════════════════════════ ADMINISTRATIVE FUNCTIONS ═══════════════════════════════════════════╗
    function rebalance(
        IAdapter fromAdapter,
        IAdapter toAdapter,
        uint amount,
        SwapInfo[] calldata swaps,
        TransferInfo[] calldata transfers,
        uint minRebalancedValue,
        uint32 deadline
    ) external;
    function compound(
        address adapter, 
        uint performanceFee, 
        SwapInfo[] calldata swaps,
        uint256 minTokensBought, 
        uint32 deadline
    ) external returns (uint tokensBought, uint liquidityMinted);
    function compoundToExternalBalancer(
        address adapter, 
        uint performanceFee, 
        SwapInfo[] calldata swaps,
        address balancerOrFromToken,
        address externalAdapter,
        uint256 minTokensBought,
        uint32 deadline
    ) external  returns (uint tokensBought, uint liquidityMinted);

    function addAdapter(address adapterAddress) external returns (bool);
    function removeAdapter(address adapterAddress) external returns (bool);
    function activateAdapter(address adapterAddress) external returns (bool);
    function deactivateAdapter(address adapterAddress) external;
    function upgradeAdapter(IAdapter sourceAdapter, IAdapter targetAdapter, uint32 deadline)  external;
    function setFeeReceiver(address feeReceiver_) external;
    function takePerformanceFee(uint112 feeValue, uint256 minTokensBought, uint32 deadline) external;
    function recoverFunds(address adapter, TransferInfo calldata transfer, address to) external;
    function addSwapPoolAddress(address swapPool) external;
    function removeSwapPoolAddress(uint index) external;

    //╔═══════════════════════════════════════════ GAUGE FUNCTIONS ═══════════════════════════════════════════╗
    function lastTimeRewardApplicable() external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function getReward() external;
    function getSwapPoolsReward() external returns (uint reward);
    function donate(uint amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

interface IV3SwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/types/Time.sol)

pragma solidity ^0.8.20;

import {Math} from "../math/Math.sol";
import {SafeCast} from "../math/SafeCast.sol";

/**
 * @dev This library provides helpers for manipulating time-related objects.
 *
 * It uses the following types:
 * - `uint48` for timepoints
 * - `uint32` for durations
 *
 * While the library doesn't provide specific types for timepoints and duration, it does provide:
 * - a `Delay` type to represent duration that can be programmed to change value automatically at a given point
 * - additional helper functions
 */
library Time {
    using Time for *;

    /**
     * @dev Get the block timestamp as a Timepoint.
     */
    function timestamp() internal view returns (uint48) {
        return SafeCast.toUint48(block.timestamp);
    }

    /**
     * @dev Get the block number as a Timepoint.
     */
    function blockNumber() internal view returns (uint48) {
        return SafeCast.toUint48(block.number);
    }

    // ==================================================== Delay =====================================================
    /**
     * @dev A `Delay` is a uint32 duration that can be programmed to change value automatically at a given point in the
     * future. The "effect" timepoint describes when the transitions happens from the "old" value to the "new" value.
     * This allows updating the delay applied to some operation while keeping some guarantees.
     *
     * In particular, the {update} function guarantees that if the delay is reduced, the old delay still applies for
     * some time. For example if the delay is currently 7 days to do an upgrade, the admin should not be able to set
     * the delay to 0 and upgrade immediately. If the admin wants to reduce the delay, the old delay (7 days) should
     * still apply for some time.
     *
     *
     * The `Delay` type is 112 bits long, and packs the following:
     *
     * ```
     *   | [uint48]: effect date (timepoint)
     *   |           | [uint32]: value before (duration)
     *   ↓           ↓       ↓ [uint32]: value after (duration)
     * 0xAAAAAAAAAAAABBBBBBBBCCCCCCCC
     * ```
     *
     * NOTE: The {get} and {withUpdate} functions operate using timestamps. Block number based delays are not currently
     * supported.
     */
    type Delay is uint112;

    /**
     * @dev Wrap a duration into a Delay to add the one-step "update in the future" feature
     */
    function toDelay(uint32 duration) internal pure returns (Delay) {
        return Delay.wrap(duration);
    }

    /**
     * @dev Get the value at a given timepoint plus the pending value and effect timepoint if there is a scheduled
     * change after this timepoint. If the effect timepoint is 0, then the pending value should not be considered.
     */
    function _getFullAt(Delay self, uint48 timepoint) private pure returns (uint32, uint32, uint48) {
        (uint32 valueBefore, uint32 valueAfter, uint48 effect) = self.unpack();
        return effect <= timepoint ? (valueAfter, 0, 0) : (valueBefore, valueAfter, effect);
    }

    /**
     * @dev Get the current value plus the pending value and effect timepoint if there is a scheduled change. If the
     * effect timepoint is 0, then the pending value should not be considered.
     */
    function getFull(Delay self) internal view returns (uint32, uint32, uint48) {
        return _getFullAt(self, timestamp());
    }

    /**
     * @dev Get the current value.
     */
    function get(Delay self) internal view returns (uint32) {
        (uint32 delay, , ) = self.getFull();
        return delay;
    }

    /**
     * @dev Update a Delay object so that it takes a new duration after a timepoint that is automatically computed to
     * enforce the old delay at the moment of the update. Returns the updated Delay object and the timestamp when the
     * new delay becomes effective.
     */
    function withUpdate(
        Delay self,
        uint32 newValue,
        uint32 minSetback
    ) internal view returns (Delay updatedDelay, uint48 effect) {
        uint32 value = self.get();
        uint32 setback = uint32(Math.max(minSetback, value > newValue ? value - newValue : 0));
        effect = timestamp() + setback;
        return (pack(value, newValue, effect), effect);
    }

    /**
     * @dev Split a delay into its components: valueBefore, valueAfter and effect (transition timepoint).
     */
    function unpack(Delay self) internal pure returns (uint32 valueBefore, uint32 valueAfter, uint48 effect) {
        uint112 raw = Delay.unwrap(self);

        valueAfter = uint32(raw);
        valueBefore = uint32(raw >> 32);
        effect = uint48(raw >> 64);

        return (valueBefore, valueAfter, effect);
    }

    /**
     * @dev pack the components into a Delay object.
     */
    function pack(uint32 valueBefore, uint32 valueAfter, uint48 effect) internal pure returns (Delay) {
        return Delay.wrap((uint112(effect) << 64) | (uint112(valueBefore) << 32) | uint112(valueAfter));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {UpgradeableBeacon} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(newImplementation.code.length > 0);
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 <0.9.0;

import "./Strings.sol";
import {formatError} from "./Utils.sol";

enum Type {
    Bool,
    Uint256,
    Int256,
    String,
    Address,
    Bytes32,
    Bytes
}

struct Placeholder {
    uint256 start;
    uint256 end;
    Type t;
    bytes mod;
}

library fmt {
    bytes32 constant ADDRESS_HASH = keccak256(bytes("address"));
    bytes32 constant ABBREVIATED_ADDRESS_HASH = keccak256(bytes("a"));
    bytes32 constant BYTES32_HASH = keccak256(bytes("bytes32"));
    bytes32 constant ABBREVIATED_BYTES32_HASH = keccak256(bytes("b32"));
    bytes32 constant STRING_HASH = keccak256(bytes("string"));
    bytes32 constant ABBREVIATED_STRING_HASH = keccak256(bytes("s"));
    bytes32 constant BYTES_HASH = keccak256(bytes("bytes"));
    bytes32 constant ABBREVIATED_BYTES_HASH = keccak256(bytes("b"));
    bytes32 constant UINT_HASH = keccak256(bytes("uint"));
    bytes32 constant ABBREVIATED_UINT_HASH = keccak256(bytes("u"));
    bytes32 constant INT_HASH = keccak256(bytes("int"));
    bytes32 constant ABBREVIATED_INT_HASH = keccak256(bytes("i"));
    bytes32 constant BOOL_HASH = keccak256(bytes("bool"));

    function format(string memory template, bytes memory args) internal pure returns (string memory) {
        Placeholder[] memory placeholders = _parseTemplate(template);
        string[] memory decoded = _decodeArgs(placeholders, args);
        return _format(template, decoded, placeholders);
    }

    function _parseTemplate(string memory template) private pure returns (Placeholder[] memory) {
        bytes memory templateBytes = bytes(template);

        Placeholder[] memory placeholders = new Placeholder[](_countPlaceholders(templateBytes));

        if (placeholders.length == 0) {
            return placeholders;
        }

        uint256 currentIndex = 0;

        for (uint256 i; i < placeholders.length; i++) {
            placeholders[i] = _findPlaceholder(templateBytes, currentIndex);
            currentIndex = placeholders[i].end;
        }

        return placeholders;
    }

    function _countPlaceholders(bytes memory template) private pure returns (uint256) {
        uint256 count = 0;
        uint256 currentIndex = 0;
        while (true) {
            uint256 placeholderStart = _findPlaceholderStart(template, currentIndex);
            if (placeholderStart == template.length) {
                break; // No more placeholders found
            }
            count++;
            currentIndex = _findPlaceholderEnd(template, placeholderStart);
        }
        return count;
    }

    function _findPlaceholderStart(bytes memory template, uint256 offset) private pure returns (uint256) {
        for (uint256 i = offset; i < template.length - 1; i++) {
            if (template[i] == "{") {
                return i;
            }
        }
        return template.length;
    }

    function _findPlaceholderEnd(bytes memory template, uint256 start) private pure returns (uint256) {
        for (uint256 i = start + 1; i < template.length; i++) {
            if (template[i] == "}") {
                return i + 1;
            }
        }
        return template.length;
    }

    function _findModifierStart(bytes memory template, uint256 start, uint256 end) private pure returns (uint256) {
        for (uint256 i = start + 1; i < end - 1; i++) {
            if (template[i] == ":") {
                return i + 1;
            }
        }

        return end;
    }

    function _findPlaceholder(bytes memory template, uint256 start) private pure returns (Placeholder memory) {
        uint256 placeholderStart = _findPlaceholderStart(template, start);

        uint256 placeholderEnd = _findPlaceholderEnd(template, placeholderStart);

        uint256 modifierStart = _findModifierStart(template, placeholderStart, placeholderEnd);

        bytes32 typeHash = keccak256(_readSlice(template, placeholderStart + 1, modifierStart - placeholderStart - 2));

        Type t;
        if (typeHash == UINT_HASH || typeHash == ABBREVIATED_UINT_HASH) {
            t = Type.Uint256;
        } else if (typeHash == ADDRESS_HASH || typeHash == ABBREVIATED_ADDRESS_HASH) {
            t = Type.Address;
        } else if (typeHash == BOOL_HASH) {
            t = Type.Bool;
        } else if (typeHash == STRING_HASH || typeHash == ABBREVIATED_STRING_HASH) {
            t = Type.String;
        } else if (typeHash == INT_HASH || typeHash == ABBREVIATED_INT_HASH) {
            t = Type.Int256;
        } else if (typeHash == BYTES_HASH || typeHash == ABBREVIATED_BYTES_HASH) {
            t = Type.Bytes;
        } else if (typeHash == BYTES32_HASH || typeHash == ABBREVIATED_BYTES32_HASH) {
            t = Type.Bytes32;
        } else {
            revert(_formatError("_findPlaceholder(bytes,uint256)", "Unsupported placeholder type"));
        }

        bytes memory mod = modifierStart == placeholderEnd
            ? new bytes(0)
            : _readSlice(template, modifierStart, placeholderEnd - modifierStart - 1);
        return Placeholder(placeholderStart, placeholderEnd, t, mod);
    }

    function _readWord(bytes memory data, uint256 offset) private pure returns (bytes32) {
        bytes32 result;

        assembly {
            result := mload(add(add(data, 0x20), offset))
        }

        return result;
    }

    function _readSlice(bytes memory data, uint256 start, uint256 len) private pure returns (bytes memory) {
        if (len == 0) {
            return new bytes(0);
        }

        require(start + len <= data.length, _formatError("_readSlice(bytes,uint256,uint256)", "Slice out of bounds"));

        bytes memory result = new bytes(len);

        for (uint256 i = 0; i < len; i++) {
            result[i] = data[start + i];
        }

        return result;
    }

    // @dev Performs abi decoding of the given data using the given placeholders.
    function _decodeArgs(Placeholder[] memory placeholders, bytes memory data) private pure returns (string[] memory) {
        string[] memory result = new string[](placeholders.length);
        for (uint256 i = 0; i < placeholders.length; i++) {
            Placeholder memory p = placeholders[i];
            uint256 offset = i * 32;
            string memory value;
            if (p.t == Type.Bool) {
                value = strings.toString(uint256(_readWord(data, offset)) == 1);
            } else if (p.t == Type.Uint256) {
                value = _display(uint256(_readWord(data, offset)), p.mod);
            } else if (p.t == Type.Int256) {
                value = strings.toString(int256(uint256(_readWord(data, offset))));
            } else if (p.t == Type.Address) {
                value = strings.toString(address(uint160(uint256(_readWord(data, offset)))));
            } else if (p.t == Type.Bytes32) {
                value = strings.toString(_readWord(data, offset));
            } else if (p.t == Type.Bytes) {
                offset = uint256(_readWord(data, offset));
                uint256 len = uint256(_readWord(data, offset));
                value = strings.toString(_readSlice(data, offset + 32, len));
            } else if (p.t == Type.String) {
                offset = uint256(_readWord(data, offset));
                uint256 len = uint256(_readWord(data, offset));
                value = string(_readSlice(data, offset + 32, len));
            } else {
                revert(_formatError("_decodeArgs(Placeholder[],bytes)", "Unsupported type"));
            }
            result[i] = value;
        }

        return result;
    }

    // Note: create other display functions for different types if necessary
    function _display(uint256 value, bytes memory mod) private pure returns (string memory) {
        if (mod.length == 0) {
            return strings.toString(value);
        } else if (mod[0] == "d" && mod.length <= 4) {
            // Max decimals is 256
            uint8 decimals = uint8(strings.parseUint(string(_readSlice(mod, 1, mod.length - 1))));
            string memory integer = strings.toString(value / 10 ** decimals);

            // Get decimal part and pad with zeroes
            string memory remainder = strings.toString(value % 10 ** decimals);

            while (bytes(remainder).length < decimals) {
                remainder = string.concat("0", remainder);
            }

            // Get expected remainder length without trailing zeroes
            uint256 len = decimals;
            while (len > 1 && bytes(remainder)[len - 1] == "0") {
                len--;
            }

            // Set new length to remove trailing zeroes
            assembly {
                mstore(remainder, len)
            }

            return string.concat(integer, ".", remainder);
        } else {
            revert(_formatError("_display(uint256,bytes)", "Unsupported modifier"));
        }
    }

    function _format(string memory template, string[] memory decoded, Placeholder[] memory placeholders)
        private
        pure
        returns (string memory)
    {
        uint256 resultLength = bytes(template).length;

        for (uint256 i = 0; i < decoded.length; i++) {
            resultLength += bytes(decoded[i]).length;
        }

        for (uint256 i = 0; i < placeholders.length; i++) {
            Placeholder memory p = placeholders[i];
            resultLength -= p.end - p.start;
        }

        bytes memory result = new bytes(resultLength);

        // Copy template to result, replacing placeholders with decoded values
        uint256 resultIndex = 0;
        uint256 placeholderIndex = 0;
        for (uint256 i = 0; i < bytes(template).length; i++) {
            if (placeholderIndex < placeholders.length && i == placeholders[placeholderIndex].start) {
                // Copy decoded value
                bytes memory decodedValue = bytes(decoded[placeholderIndex]);
                for (uint256 j = 0; j < decodedValue.length; j++) {
                    result[resultIndex++] = decodedValue[j];
                }
                i = placeholders[placeholderIndex].end - 1;
                placeholderIndex++;
            } else {
                result[resultIndex++] = bytes(template)[i];
            }
        }

        return string(result);
    }

    function _formatError(string memory func, string memory message) private pure returns (string memory) {
        return formatError("fmt", func, message);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "./ISwapProvider.sol";

interface IAdapter {

    struct CallInfo {
        address callee;
        bytes data;
    }

    error UnsolvableRatio(uint balance0, uint balance1, uint r0, uint r1);
    error UnsupportedToken(address token);
    error ZeroReserveBalance(uint reserve0, uint reserve1);

    function invest(address dustReceiver) external returns (uint valueBefore, uint valueAfter);
    function redeem(uint lpAmount, address receiver)
        external
        returns (
            address[] memory tokens,
            uint[] memory amounts
        );
    function compound(ISwapProvider.SwapInfo[] calldata swaps) external returns (uint leqBefore,uint leqAfter);
    function claim() external;
    function claim(address receiver)
        external
        returns (address[] memory rewardTokens, uint[] memory rewardsClaimed, uint[] memory rewardBalances);
    function recoverFunds(ISwapProvider.TransferInfo calldata transfer, address to) external;
    function negotiableTokens() external returns(address[] memory tokens);
    function pendingRewards() external view returns(address[] memory tokens, uint[] memory amounts);
    function depositTokens() external view returns (address[] memory tokens);
    function value()  external view returns (uint estimatedValue, uint lpAmount);
    function ratios() external view returns(address[] memory tokens, uint[] memory ratio);
    function description() external returns (string memory);
    function parent() external view returns(address parent);
    function emergencyCall(CallInfo[] calldata calls) external;

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

interface ISwapProvider {

    struct SwapInfo {
        address callee; // callee
        bytes data; // swap call data
        uint256 amount; // amount to swap
        address token; // token to swap
    }

    struct TransferInfo {
        uint256 amount; // amount to transfer
        address token; // token to transfer
    }

    function swapExecutor() external view returns(address);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.20;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeCast {
    /**
     * @dev Value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);

    /**
     * @dev An int value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedIntToUint(int256 value);

    /**
     * @dev Value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedIntDowncast(uint8 bits, int256 value);

    /**
     * @dev An uint value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedUintToInt(uint256 value);

    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        if (value > type(uint248).max) {
            revert SafeCastOverflowedUintDowncast(248, value);
        }
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        if (value > type(uint240).max) {
            revert SafeCastOverflowedUintDowncast(240, value);
        }
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        if (value > type(uint232).max) {
            revert SafeCastOverflowedUintDowncast(232, value);
        }
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        if (value > type(uint224).max) {
            revert SafeCastOverflowedUintDowncast(224, value);
        }
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        if (value > type(uint216).max) {
            revert SafeCastOverflowedUintDowncast(216, value);
        }
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        if (value > type(uint208).max) {
            revert SafeCastOverflowedUintDowncast(208, value);
        }
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        if (value > type(uint200).max) {
            revert SafeCastOverflowedUintDowncast(200, value);
        }
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        if (value > type(uint192).max) {
            revert SafeCastOverflowedUintDowncast(192, value);
        }
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        if (value > type(uint184).max) {
            revert SafeCastOverflowedUintDowncast(184, value);
        }
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        if (value > type(uint176).max) {
            revert SafeCastOverflowedUintDowncast(176, value);
        }
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        if (value > type(uint168).max) {
            revert SafeCastOverflowedUintDowncast(168, value);
        }
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        if (value > type(uint160).max) {
            revert SafeCastOverflowedUintDowncast(160, value);
        }
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        if (value > type(uint152).max) {
            revert SafeCastOverflowedUintDowncast(152, value);
        }
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        if (value > type(uint144).max) {
            revert SafeCastOverflowedUintDowncast(144, value);
        }
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        if (value > type(uint136).max) {
            revert SafeCastOverflowedUintDowncast(136, value);
        }
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        if (value > type(uint128).max) {
            revert SafeCastOverflowedUintDowncast(128, value);
        }
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        if (value > type(uint120).max) {
            revert SafeCastOverflowedUintDowncast(120, value);
        }
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        if (value > type(uint112).max) {
            revert SafeCastOverflowedUintDowncast(112, value);
        }
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        if (value > type(uint104).max) {
            revert SafeCastOverflowedUintDowncast(104, value);
        }
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        if (value > type(uint96).max) {
            revert SafeCastOverflowedUintDowncast(96, value);
        }
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        if (value > type(uint88).max) {
            revert SafeCastOverflowedUintDowncast(88, value);
        }
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        if (value > type(uint80).max) {
            revert SafeCastOverflowedUintDowncast(80, value);
        }
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        if (value > type(uint72).max) {
            revert SafeCastOverflowedUintDowncast(72, value);
        }
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        if (value > type(uint64).max) {
            revert SafeCastOverflowedUintDowncast(64, value);
        }
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        if (value > type(uint56).max) {
            revert SafeCastOverflowedUintDowncast(56, value);
        }
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        if (value > type(uint48).max) {
            revert SafeCastOverflowedUintDowncast(48, value);
        }
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        if (value > type(uint40).max) {
            revert SafeCastOverflowedUintDowncast(40, value);
        }
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        if (value > type(uint32).max) {
            revert SafeCastOverflowedUintDowncast(32, value);
        }
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        if (value > type(uint24).max) {
            revert SafeCastOverflowedUintDowncast(24, value);
        }
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        if (value > type(uint16).max) {
            revert SafeCastOverflowedUintDowncast(16, value);
        }
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        if (value > type(uint8).max) {
            revert SafeCastOverflowedUintDowncast(8, value);
        }
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        if (value < 0) {
            revert SafeCastOverflowedIntToUint(value);
        }
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(248, value);
        }
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(240, value);
        }
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(232, value);
        }
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(224, value);
        }
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(216, value);
        }
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(208, value);
        }
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(200, value);
        }
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(192, value);
        }
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(184, value);
        }
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(176, value);
        }
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(168, value);
        }
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(160, value);
        }
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(152, value);
        }
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(144, value);
        }
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(136, value);
        }
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(128, value);
        }
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(120, value);
        }
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(112, value);
        }
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(104, value);
        }
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(96, value);
        }
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(88, value);
        }
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(80, value);
        }
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(72, value);
        }
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(64, value);
        }
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(56, value);
        }
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(48, value);
        }
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(40, value);
        }
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(32, value);
        }
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(24, value);
        }
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(16, value);
        }
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(8, value);
        }
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        if (value > uint256(type(int256).max)) {
            revert SafeCastOverflowedUintToInt(value);
        }
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 <0.9.0;

import "./Vulcan.sol";
import {fmt} from "./Fmt.sol";

library strings {
    function format(string memory template, bytes memory args) public pure returns (string memory) {
        return fmt.format(template, args);
    }

    /// @dev Transforms an address to a string.
    /// @param value The address to parse.
    /// @return The string representation of `value`.
    function toString(address value) internal pure returns (string memory) {
        return vulcan.hevm.toString(value);
    }

    /// @dev Transforms a byte array to a string.
    /// @param value The byte array to parse.
    /// @return The string representation of `value`.
    function toString(bytes memory value) internal pure returns (string memory) {
        return vulcan.hevm.toString(value);
    }

    /// @dev Transforms a bytes32 to a string.
    /// @param value The bytes32 to parse.
    /// @return The string representation of `value`.
    function toString(bytes32 value) internal pure returns (string memory) {
        return vulcan.hevm.toString(value);
    }

    /// @dev Transforms a boolean to a string.
    /// @param value The boolean to parse.
    /// @return The string representation of `value`.
    function toString(bool value) internal pure returns (string memory) {
        return vulcan.hevm.toString(value);
    }

    /// @dev Transforms an uint256 to a string.
    /// @param value The uint256 to parse.
    /// @return The string representation of `value`.
    function toString(uint256 value) internal pure returns (string memory) {
        return vulcan.hevm.toString(value);
    }

    /// @dev Transforms an int256 to a string.
    /// @param value The int256 to parse.
    /// @return The string representation of `value`.
    function toString(int256 value) internal pure returns (string memory) {
        return vulcan.hevm.toString(value);
    }

    /// @dev Parses a byte array string.
    /// @param value The string to parse.
    /// @return The parsed byte array.
    function parseBytes(string memory value) internal pure returns (bytes memory) {
        return vulcan.hevm.parseBytes(value);
    }

    /// @dev Parses an address string.
    /// @param value The string to parse.
    /// @return The parsed address.
    function parseAddress(string memory value) internal pure returns (address) {
        return vulcan.hevm.parseAddress(value);
    }

    /// @dev Parses an uint256 string.
    /// @param value The string to parse.
    /// @return The parsed uint256.
    function parseUint(string memory value) internal pure returns (uint256) {
        return vulcan.hevm.parseUint(value);
    }

    /// @dev Parses an int256 string.
    /// @param value The string to parse.
    /// @return The parsed int256.
    function parseInt(string memory value) internal pure returns (int256) {
        return vulcan.hevm.parseInt(value);
    }

    /// @dev Parses a bytes32 string.
    /// @param value The string to parse.
    /// @return The parsed bytes32.
    function parseBytes32(string memory value) internal pure returns (bytes32) {
        return vulcan.hevm.parseBytes32(value);
    }

    /// @dev Parses a boolean string.
    /// @param value The string to parse.
    /// @return The parsed boolean.
    function parseBool(string memory value) internal pure returns (bool) {
        return vulcan.hevm.parseBool(value);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import {Vm as Hevm} from "forge-std/Vm.sol";
import {watchersUnsafe as _watchersUnsafe, Call, Watcher} from "./Watchers.sol";
import {ctxUnsafe as _ctxUnsafe} from "./Context.sol";

/// @dev Struct that represent an EVM log
struct Log {
    bytes32[] topics;
    bytes data;
    address emitter;
}

library vulcan {
    using vulcan for *;

    bytes32 constant GLOBAL_FAILED_SLOT = bytes32("failed");

    /// @dev forge-std VM
    Hevm internal constant hevm = Hevm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    /// @dev Initializes the context module
    function init() internal {
        _ctxUnsafe.init();
    }

    /// @dev Checks if `fail` was called at some point.
    /// @return true if `fail` was called, false otherwise
    function failed() internal view returns (bool) {
        bytes32 globalFailed = vulcan.hevm.load(address(hevm), GLOBAL_FAILED_SLOT);
        return globalFailed == bytes32(uint256(1));
    }

    /// @dev Signal that an expectation/assertion failed.
    function fail() internal {
        vulcan.hevm.store(address(hevm), GLOBAL_FAILED_SLOT, bytes32(uint256(1)));
    }

    /// @dev Resets the failed state.
    function clearFailure() internal {
        vulcan.hevm.store(address(hevm), GLOBAL_FAILED_SLOT, bytes32(uint256(0)));
    }

    /// @dev Starts monitoring an address.
    /// @param _target The address to monitor.
    /// @return The Watcher contract that monitors the `_target` address.
    function watch(address _target) internal returns (Watcher) {
        return _watchersUnsafe.watch(_target);
    }

    /// @dev Stops monitoring an address.
    /// @param _target The address to stop monitoring.
    function stopWatcher(address _target) internal {
        _watchersUnsafe.stop(_target);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

pragma experimental ABIEncoderV2;

// Cheatcodes are marked as view/pure/none using the following rules:
// 0. A call's observable behaviour includes its return value, logs, reverts and state writes,
// 1. If you can influence a later call's observable behaviour, you're neither `view` nor `pure (you are modifying some state be it the EVM, interpreter, filesystem, etc),
// 2. Otherwise if you can be influenced by an earlier call, or if reading some state, you're `view`,
// 3. Otherwise you're `pure`.

// The `VmSafe` interface does not allow manipulation of the EVM state or other actions that may
// result in Script simulations differing from on-chain execution. It is recommended to only use
// these cheats in scripts.
interface VmSafe {
    //  ======== Types ========
    enum CallerMode {
        None,
        Broadcast,
        RecurrentBroadcast,
        Prank,
        RecurrentPrank
    }

    enum AccountAccessKind {
        Call,
        DelegateCall,
        CallCode,
        StaticCall,
        Create,
        SelfDestruct,
        Resume
    }

    struct Log {
        bytes32[] topics;
        bytes data;
        address emitter;
    }

    struct Rpc {
        string key;
        string url;
    }

    struct EthGetLogs {
        address emitter;
        bytes32[] topics;
        bytes data;
        bytes32 blockHash;
        uint64 blockNumber;
        bytes32 transactionHash;
        uint64 transactionIndex;
        uint256 logIndex;
        bool removed;
    }

    struct DirEntry {
        string errorMessage;
        string path;
        uint64 depth;
        bool isDir;
        bool isSymlink;
    }

    struct FsMetadata {
        bool isDir;
        bool isSymlink;
        uint256 length;
        bool readOnly;
        uint256 modified;
        uint256 accessed;
        uint256 created;
    }

    struct Wallet {
        address addr;
        uint256 publicKeyX;
        uint256 publicKeyY;
        uint256 privateKey;
    }

    struct FfiResult {
        int32 exitCode;
        bytes stdout;
        bytes stderr;
    }

    struct ChainInfo {
        uint256 forkId;
        uint256 chainId;
    }

    struct AccountAccess {
        ChainInfo chainInfo;
        AccountAccessKind kind;
        address account;
        address accessor;
        bool initialized;
        uint256 oldBalance;
        uint256 newBalance;
        bytes deployedCode;
        uint256 value;
        bytes data;
        bool reverted;
        StorageAccess[] storageAccesses;
    }

    struct StorageAccess {
        address account;
        bytes32 slot;
        bool isWrite;
        bytes32 previousValue;
        bytes32 newValue;
        bool reverted;
    }

    // ======== EVM  ========

    // Gets the address for a given private key
    function addr(uint256 privateKey) external pure returns (address keyAddr);

    // Gets the nonce of an account.
    // See `getNonce(Wallet memory wallet)` for an alternative way to manage users and get their nonces.
    function getNonce(address account) external view returns (uint64 nonce);

    // Loads a storage slot from an address
    function load(address target, bytes32 slot) external view returns (bytes32 data);

    // Signs data
    function sign(uint256 privateKey, bytes32 digest) external pure returns (uint8 v, bytes32 r, bytes32 s);

    // -------- Record Storage --------
    // Records all storage reads and writes
    function record() external;

    // Gets all accessed reads and write slot from a `vm.record` session, for a given address
    function accesses(address target) external returns (bytes32[] memory readSlots, bytes32[] memory writeSlots);

    // Record all account accesses as part of CREATE, CALL or SELFDESTRUCT opcodes in order,
    // along with the context of the calls.
    function startStateDiffRecording() external;

    // Returns an ordered array of all account accesses from a `vm.startStateDiffRecording` session.
    function stopAndReturnStateDiff() external returns (AccountAccess[] memory accountAccesses);

    // -------- Recording Map Writes --------

    // Starts recording all map SSTOREs for later retrieval.
    function startMappingRecording() external;

    // Stops recording all map SSTOREs for later retrieval and clears the recorded data.
    function stopMappingRecording() external;

    // Gets the number of elements in the mapping at the given slot, for a given address.
    function getMappingLength(address target, bytes32 mappingSlot) external returns (uint256 length);

    // Gets the elements at index idx of the mapping at the given slot, for a given address. The
    // index must be less than the length of the mapping (i.e. the number of keys in the mapping).
    function getMappingSlotAt(address target, bytes32 mappingSlot, uint256 idx) external returns (bytes32 value);

    // Gets the map key and parent of a mapping at a given slot, for a given address.
    function getMappingKeyAndParentOf(address target, bytes32 elementSlot)
        external
        returns (bool found, bytes32 key, bytes32 parent);

    // -------- Record Logs --------
    // Record all the transaction logs
    function recordLogs() external;

    // Gets all the recorded logs
    function getRecordedLogs() external returns (Log[] memory logs);

    // -------- Gas Metering --------
    // It's recommend to use the `noGasMetering` modifier included with forge-std, instead of
    // using these functions directly.

    // Pauses gas metering (i.e. gas usage is not counted). Noop if already paused.
    function pauseGasMetering() external;

    // Resumes gas metering (i.e. gas usage is counted again). Noop if already on.
    function resumeGasMetering() external;

    // -------- RPC Methods --------

    /// Gets all the logs according to specified filter.
    function eth_getLogs(uint256 fromBlock, uint256 toBlock, address target, bytes32[] calldata topics)
        external
        returns (EthGetLogs[] memory logs);

    // Performs an Ethereum JSON-RPC request to the current fork URL.
    function rpc(string calldata method, string calldata params) external returns (bytes memory data);

    // ======== Test Configuration ========

    // If the condition is false, discard this run's fuzz inputs and generate new ones.
    function assume(bool condition) external pure;

    // Writes a breakpoint to jump to in the debugger
    function breakpoint(string calldata char) external;

    // Writes a conditional breakpoint to jump to in the debugger
    function breakpoint(string calldata char, bool value) external;

    // Returns the RPC url for the given alias
    function rpcUrl(string calldata rpcAlias) external view returns (string memory json);

    // Returns all rpc urls and their aliases `[alias, url][]`
    function rpcUrls() external view returns (string[2][] memory urls);

    // Returns all rpc urls and their aliases as structs.
    function rpcUrlStructs() external view returns (Rpc[] memory urls);

    // Suspends execution of the main thread for `duration` milliseconds
    function sleep(uint256 duration) external;

    // ======== OS and Filesystem ========

    // -------- Metadata --------

    // Returns true if the given path points to an existing entity, else returns false
    function exists(string calldata path) external returns (bool result);

    // Given a path, query the file system to get information about a file, directory, etc.
    function fsMetadata(string calldata path) external view returns (FsMetadata memory metadata);

    // Returns true if the path exists on disk and is pointing at a directory, else returns false
    function isDir(string calldata path) external returns (bool result);

    // Returns true if the path exists on disk and is pointing at a regular file, else returns false
    function isFile(string calldata path) external returns (bool result);

    // Get the path of the current project root.
    function projectRoot() external view returns (string memory path);

    // Returns the time since unix epoch in milliseconds
    function unixTime() external returns (uint256 milliseconds);

    // -------- Reading and writing --------

    // Closes file for reading, resetting the offset and allowing to read it from beginning with readLine.
    // `path` is relative to the project root.
    function closeFile(string calldata path) external;

    // Copies the contents of one file to another. This function will **overwrite** the contents of `to`.
    // On success, the total number of bytes copied is returned and it is equal to the length of the `to` file as reported by `metadata`.
    // Both `from` and `to` are relative to the project root.
    function copyFile(string calldata from, string calldata to) external returns (uint64 copied);

    // Creates a new, empty directory at the provided path.
    // This cheatcode will revert in the following situations, but is not limited to just these cases:
    // - User lacks permissions to modify `path`.
    // - A parent of the given path doesn't exist and `recursive` is false.
    // - `path` already exists and `recursive` is false.
    // `path` is relative to the project root.
    function createDir(string calldata path, bool recursive) external;

    // Reads the directory at the given path recursively, up to `max_depth`.
    // `max_depth` defaults to 1, meaning only the direct children of the given directory will be returned.
    // Follows symbolic links if `follow_links` is true.
    function readDir(string calldata path) external view returns (DirEntry[] memory entries);
    function readDir(string calldata path, uint64 maxDepth) external view returns (DirEntry[] memory entries);
    function readDir(string calldata path, uint64 maxDepth, bool followLinks)
        external
        view
        returns (DirEntry[] memory entries);

    // Reads the entire content of file to string. `path` is relative to the project root.
    function readFile(string calldata path) external view returns (string memory data);

    // Reads the entire content of file as binary. `path` is relative to the project root.
    function readFileBinary(string calldata path) external view returns (bytes memory data);

    // Reads next line of file to string.
    function readLine(string calldata path) external view returns (string memory line);

    // Reads a symbolic link, returning the path that the link points to.
    // This cheatcode will revert in the following situations, but is not limited to just these cases:
    // - `path` is not a symbolic link.
    // - `path` does not exist.
    function readLink(string calldata linkPath) external view returns (string memory targetPath);

    // Removes a directory at the provided path.
    // This cheatcode will revert in the following situations, but is not limited to just these cases:
    // - `path` doesn't exist.
    // - `path` isn't a directory.
    // - User lacks permissions to modify `path`.
    // - The directory is not empty and `recursive` is false.
    // `path` is relative to the project root.
    function removeDir(string calldata path, bool recursive) external;

    // Removes a file from the filesystem.
    // This cheatcode will revert in the following situations, but is not limited to just these cases:
    // - `path` points to a directory.
    // - The file doesn't exist.
    // - The user lacks permissions to remove the file.
    // `path` is relative to the project root.
    function removeFile(string calldata path) external;

    // Writes data to file, creating a file if it does not exist, and entirely replacing its contents if it does.
    // `path` is relative to the project root.
    function writeFile(string calldata path, string calldata data) external;

    // Writes binary data to a file, creating a file if it does not exist, and entirely replacing its contents if it does.
    // `path` is relative to the project root.
    function writeFileBinary(string calldata path, bytes calldata data) external;

    // Writes line to file, creating a file if it does not exist.
    // `path` is relative to the project root.
    function writeLine(string calldata path, string calldata data) external;

    // -------- Foreign Function Interface --------

    // Performs a foreign function call via the terminal
    function ffi(string[] calldata commandInput) external returns (bytes memory result);

    // Performs a foreign function call via terminal and returns the exit code, stdout, and stderr
    function tryFfi(string[] calldata commandInput) external returns (FfiResult memory result);

    // ======== Environment Variables ========

    // Sets environment variables
    function setEnv(string calldata name, string calldata value) external;

    // Reads environment variables, (name) => (value)
    function envBool(string calldata name) external view returns (bool value);
    function envUint(string calldata name) external view returns (uint256 value);
    function envInt(string calldata name) external view returns (int256 value);
    function envAddress(string calldata name) external view returns (address value);
    function envBytes32(string calldata name) external view returns (bytes32 value);
    function envString(string calldata name) external view returns (string memory value);
    function envBytes(string calldata name) external view returns (bytes memory value);

    // Reads environment variables as arrays
    function envBool(string calldata name, string calldata delim) external view returns (bool[] memory value);
    function envUint(string calldata name, string calldata delim) external view returns (uint256[] memory value);
    function envInt(string calldata name, string calldata delim) external view returns (int256[] memory value);
    function envAddress(string calldata name, string calldata delim) external view returns (address[] memory value);
    function envBytes32(string calldata name, string calldata delim) external view returns (bytes32[] memory value);
    function envString(string calldata name, string calldata delim) external view returns (string[] memory value);
    function envBytes(string calldata name, string calldata delim) external view returns (bytes[] memory value);

    // Read environment variables with default value
    function envOr(string calldata name, bool defaultValue) external returns (bool value);
    function envOr(string calldata name, uint256 defaultValue) external returns (uint256 value);
    function envOr(string calldata name, int256 defaultValue) external returns (int256 value);
    function envOr(string calldata name, address defaultValue) external returns (address value);
    function envOr(string calldata name, bytes32 defaultValue) external returns (bytes32 value);
    function envOr(string calldata name, string calldata defaultValue) external returns (string memory value);
    function envOr(string calldata name, bytes calldata defaultValue) external returns (bytes memory value);

    // Read environment variables as arrays with default value
    function envOr(string calldata name, string calldata delim, bool[] calldata defaultValue)
        external
        returns (bool[] memory value);
    function envOr(string calldata name, string calldata delim, uint256[] calldata defaultValue)
        external
        returns (uint256[] memory value);
    function envOr(string calldata name, string calldata delim, int256[] calldata defaultValue)
        external
        returns (int256[] memory value);
    function envOr(string calldata name, string calldata delim, address[] calldata defaultValue)
        external
        returns (address[] memory value);
    function envOr(string calldata name, string calldata delim, bytes32[] calldata defaultValue)
        external
        returns (bytes32[] memory value);
    function envOr(string calldata name, string calldata delim, string[] calldata defaultValue)
        external
        returns (string[] memory value);
    function envOr(string calldata name, string calldata delim, bytes[] calldata defaultValue)
        external
        returns (bytes[] memory value);

    // ======== User Management ========

    // Derives a private key from the name, labels the account with that name, and returns the wallet
    function createWallet(string calldata walletLabel) external returns (Wallet memory wallet);

    // Generates a wallet from the private key and returns the wallet
    function createWallet(uint256 privateKey) external returns (Wallet memory wallet);

    // Generates a wallet from the private key, labels the account with that name, and returns the wallet
    function createWallet(uint256 privateKey, string calldata walletLabel) external returns (Wallet memory wallet);

    // Gets the label for the specified address
    function getLabel(address account) external returns (string memory currentLabel);

    // Get nonce for a Wallet.
    // See `getNonce(address account)` for an alternative way to get a nonce.
    function getNonce(Wallet calldata wallet) external returns (uint64 nonce);

    // Labels an address in call traces
    function label(address account, string calldata newLabel) external;

    // Signs data, (Wallet, digest) => (v, r, s)
    function sign(Wallet calldata wallet, bytes32 digest) external returns (uint8 v, bytes32 r, bytes32 s);

    // ======== Scripts ========

    // -------- Broadcasting Transactions --------

    // Using the address that calls the test contract, has the next call (at this call depth only) create a transaction that can later be signed and sent onchain
    function broadcast() external;

    // Has the next call (at this call depth only) create a transaction with the address provided as the sender that can later be signed and sent onchain
    function broadcast(address signer) external;

    // Has the next call (at this call depth only) create a transaction with the private key provided as the sender that can later be signed and sent onchain
    function broadcast(uint256 privateKey) external;

    // Using the address that calls the test contract, has all subsequent calls (at this call depth only) create transactions that can later be signed and sent onchain
    function startBroadcast() external;

    // Has all subsequent calls (at this call depth only) create transactions with the address provided that can later be signed and sent onchain
    function startBroadcast(address signer) external;

    // Has all subsequent calls (at this call depth only) create transactions with the private key provided that can later be signed and sent onchain
    function startBroadcast(uint256 privateKey) external;

    // Stops collecting onchain transactions
    function stopBroadcast() external;

    // -------- Key Management --------

    // Derive a private key from a provided mnenomic string (or mnenomic file path) at the derivation path m/44'/60'/0'/0/{index}
    function deriveKey(string calldata mnemonic, uint32 index) external pure returns (uint256 privateKey);

    // Derive a private key from a provided mnenomic string (or mnenomic file path) at {derivationPath}{index}
    function deriveKey(string calldata mnemonic, string calldata derivationPath, uint32 index)
        external
        pure
        returns (uint256 privateKey);

    // Adds a private key to the local forge wallet and returns the address
    function rememberKey(uint256 privateKey) external returns (address keyAddr);

    // ======== Utilities ========

    // Convert values to a string
    function toString(address value) external pure returns (string memory stringifiedValue);
    function toString(bytes calldata value) external pure returns (string memory stringifiedValue);
    function toString(bytes32 value) external pure returns (string memory stringifiedValue);
    function toString(bool value) external pure returns (string memory stringifiedValue);
    function toString(uint256 value) external pure returns (string memory stringifiedValue);
    function toString(int256 value) external pure returns (string memory stringifiedValue);

    // Convert values from a string
    function parseBytes(string calldata stringifiedValue) external pure returns (bytes memory parsedValue);
    function parseAddress(string calldata stringifiedValue) external pure returns (address parsedValue);
    function parseUint(string calldata stringifiedValue) external pure returns (uint256 parsedValue);
    function parseInt(string calldata stringifiedValue) external pure returns (int256 parsedValue);
    function parseBytes32(string calldata stringifiedValue) external pure returns (bytes32 parsedValue);
    function parseBool(string calldata stringifiedValue) external pure returns (bool parsedValue);

    // Gets the creation bytecode from an artifact file. Takes in the relative path to the json file
    function getCode(string calldata artifactPath) external view returns (bytes memory creationBytecode);

    // Gets the deployed bytecode from an artifact file. Takes in the relative path to the json file
    function getDeployedCode(string calldata artifactPath) external view returns (bytes memory runtimeBytecode);

    // Compute the address a contract will be deployed at for a given deployer address and nonce.
    function computeCreateAddress(address deployer, uint256 nonce) external pure returns (address);

    // Compute the address of a contract created with CREATE2 using the given CREATE2 deployer.
    function computeCreate2Address(bytes32 salt, bytes32 initCodeHash, address deployer)
        external
        pure
        returns (address);

    // Compute the address of a contract created with CREATE2 using foundry's default CREATE2
    // deployer: 0x4e59b44847b379578588920cA78FbF26c0B4956C, https://github.com/Arachnid/deterministic-deployment-proxy
    function computeCreate2Address(bytes32 salt, bytes32 initCodeHash) external pure returns (address);

    // ======== JSON Parsing and Manipulation ========

    // -------- Reading --------

    // NOTE: Please read https://book.getfoundry.sh/cheatcodes/parse-json to understand the
    // limitations and caveats of the JSON parsing cheats.

    // Checks if a key exists in a JSON object.
    function keyExists(string calldata json, string calldata key) external view returns (bool);

    // Given a string of JSON, return it as ABI-encoded
    function parseJson(string calldata json, string calldata key) external pure returns (bytes memory abiEncodedData);
    function parseJson(string calldata json) external pure returns (bytes memory abiEncodedData);

    // The following parseJson cheatcodes will do type coercion, for the type that they indicate.
    // For example, parseJsonUint will coerce all values to a uint256. That includes stringified numbers '12'
    // and hex numbers '0xEF'.
    // Type coercion works ONLY for discrete values or arrays. That means that the key must return a value or array, not
    // a JSON object.
    function parseJsonUint(string calldata json, string calldata key) external pure returns (uint256);
    function parseJsonUintArray(string calldata json, string calldata key) external pure returns (uint256[] memory);
    function parseJsonInt(string calldata json, string calldata key) external pure returns (int256);
    function parseJsonIntArray(string calldata json, string calldata key) external pure returns (int256[] memory);
    function parseJsonBool(string calldata json, string calldata key) external pure returns (bool);
    function parseJsonBoolArray(string calldata json, string calldata key) external pure returns (bool[] memory);
    function parseJsonAddress(string calldata json, string calldata key) external pure returns (address);
    function parseJsonAddressArray(string calldata json, string calldata key)
        external
        pure
        returns (address[] memory);
    function parseJsonString(string calldata json, string calldata key) external pure returns (string memory);
    function parseJsonStringArray(string calldata json, string calldata key) external pure returns (string[] memory);
    function parseJsonBytes(string calldata json, string calldata key) external pure returns (bytes memory);
    function parseJsonBytesArray(string calldata json, string calldata key) external pure returns (bytes[] memory);
    function parseJsonBytes32(string calldata json, string calldata key) external pure returns (bytes32);
    function parseJsonBytes32Array(string calldata json, string calldata key)
        external
        pure
        returns (bytes32[] memory);

    // Returns array of keys for a JSON object
    function parseJsonKeys(string calldata json, string calldata key) external pure returns (string[] memory keys);

    // -------- Writing --------

    // NOTE: Please read https://book.getfoundry.sh/cheatcodes/serialize-json to understand how
    // to use the serialization cheats.

    // Serialize a key and value to a JSON object stored in-memory that can be later written to a file
    // It returns the stringified version of the specific JSON file up to that moment.
    function serializeJson(string calldata objectKey, string calldata value) external returns (string memory json);
    function serializeBool(string calldata objectKey, string calldata valueKey, bool value)
        external
        returns (string memory json);
    function serializeUint(string calldata objectKey, string calldata valueKey, uint256 value)
        external
        returns (string memory json);
    function serializeInt(string calldata objectKey, string calldata valueKey, int256 value)
        external
        returns (string memory json);
    function serializeAddress(string calldata objectKey, string calldata valueKey, address value)
        external
        returns (string memory json);
    function serializeBytes32(string calldata objectKey, string calldata valueKey, bytes32 value)
        external
        returns (string memory json);
    function serializeString(string calldata objectKey, string calldata valueKey, string calldata value)
        external
        returns (string memory json);
    function serializeBytes(string calldata objectKey, string calldata valueKey, bytes calldata value)
        external
        returns (string memory json);

    function serializeBool(string calldata objectKey, string calldata valueKey, bool[] calldata values)
        external
        returns (string memory json);
    function serializeUint(string calldata objectKey, string calldata valueKey, uint256[] calldata values)
        external
        returns (string memory json);
    function serializeInt(string calldata objectKey, string calldata valueKey, int256[] calldata values)
        external
        returns (string memory json);
    function serializeAddress(string calldata objectKey, string calldata valueKey, address[] calldata values)
        external
        returns (string memory json);
    function serializeBytes32(string calldata objectKey, string calldata valueKey, bytes32[] calldata values)
        external
        returns (string memory json);
    function serializeString(string calldata objectKey, string calldata valueKey, string[] calldata values)
        external
        returns (string memory json);
    function serializeBytes(string calldata objectKey, string calldata valueKey, bytes[] calldata values)
        external
        returns (string memory json);

    // NOTE: Please read https://book.getfoundry.sh/cheatcodes/write-json to understand how
    // to use the JSON writing cheats.

    // Write a serialized JSON object to a file. If the file exists, it will be overwritten.
    function writeJson(string calldata json, string calldata path) external;

    // Write a serialized JSON object to an **existing** JSON file, replacing a value with key = <value_key>
    // This is useful to replace a specific value of a JSON file, without having to parse the entire thing
    function writeJson(string calldata json, string calldata path, string calldata valueKey) external;
}

// The `Vm` interface does allow manipulation of the EVM state. These are all intended to be used
// in tests, but it is not recommended to use these cheats in scripts.
interface Vm is VmSafe {
    // ======== EVM  ========

    // -------- Block and Transaction Properties --------

    // Sets block.chainid
    function chainId(uint256 newChainId) external;

    // Sets block.coinbase
    function coinbase(address newCoinbase) external;

    // Sets block.difficulty
    // Not available on EVM versions from Paris onwards. Use `prevrandao` instead.
    // If used on unsupported EVM versions it will revert.
    function difficulty(uint256 newDifficulty) external;

    // Sets block.basefee
    function fee(uint256 newBasefee) external;

    // Sets block.prevrandao
    // Not available on EVM versions before Paris. Use `difficulty` instead.
    // If used on unsupported EVM versions it will revert.
    function prevrandao(bytes32 newPrevrandao) external;

    // Sets block.height
    function roll(uint256 newHeight) external;

    // Sets tx.gasprice
    function txGasPrice(uint256 newGasPrice) external;

    // Sets block.timestamp
    function warp(uint256 newTimestamp) external;

    // -------- Account State --------

    // Sets an address' balance
    function deal(address account, uint256 newBalance) external;

    // Sets an address' code
    function etch(address target, bytes calldata newRuntimeBytecode) external;

    // Load a genesis JSON file's `allocs` into the in-memory state.
    function loadAllocs(string calldata pathToAllocsJson) external;

    // Resets the nonce of an account to 0 for EOAs and 1 for contract accounts
    function resetNonce(address account) external;

    // Sets the nonce of an account; must be higher than the current nonce of the account
    function setNonce(address account, uint64 newNonce) external;

    // Sets the nonce of an account to an arbitrary value
    function setNonceUnsafe(address account, uint64 newNonce) external;

    // Stores a value to an address' storage slot.
    function store(address target, bytes32 slot, bytes32 value) external;

    // -------- Call Manipulation --------
    // --- Mocks ---

    // Clears all mocked calls
    function clearMockedCalls() external;

    // Mocks a call to an address, returning specified data.
    // Calldata can either be strict or a partial match, e.g. if you only
    // pass a Solidity selector to the expected calldata, then the entire Solidity
    // function will be mocked.
    function mockCall(address callee, bytes calldata data, bytes calldata returnData) external;

    // Mocks a call to an address with a specific msg.value, returning specified data.
    // Calldata match takes precedence over msg.value in case of ambiguity.
    function mockCall(address callee, uint256 msgValue, bytes calldata data, bytes calldata returnData) external;

    // Reverts a call to an address with specified revert data.
    function mockCallRevert(address callee, bytes calldata data, bytes calldata revertData) external;

    // Reverts a call to an address with a specific msg.value, with specified revert data.
    function mockCallRevert(address callee, uint256 msgValue, bytes calldata data, bytes calldata revertData)
        external;

    // --- Impersonation (pranks) ---

    // Sets the *next* call's msg.sender to be the input address
    function prank(address msgSender) external;

    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called
    function startPrank(address msgSender) external;

    // Sets the *next* call's msg.sender to be the input address, and the tx.origin to be the second input
    function prank(address msgSender, address txOrigin) external;

    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called, and the tx.origin to be the second input
    function startPrank(address msgSender, address txOrigin) external;

    // Resets subsequent calls' msg.sender to be `address(this)`
    function stopPrank() external;

    // Reads the current `msg.sender` and `tx.origin` from state and reports if there is any active caller modification
    function readCallers() external returns (CallerMode callerMode, address msgSender, address txOrigin);

    // -------- State Snapshots --------

    // Snapshot the current state of the evm.
    // Returns the id of the snapshot that was created.
    // To revert a snapshot use `revertTo`
    function snapshot() external returns (uint256 snapshotId);

    // Revert the state of the EVM to a previous snapshot
    // Takes the snapshot id to revert to.
    // This deletes the snapshot and all snapshots taken after the given snapshot id.
    function revertTo(uint256 snapshotId) external returns (bool success);

    // -------- Forking --------
    // --- Creation and Selection ---

    // Returns the identifier of the currently active fork. Reverts if no fork is currently active.
    function activeFork() external view returns (uint256 forkId);

    // Creates a new fork with the given endpoint and block and returns the identifier of the fork
    function createFork(string calldata urlOrAlias, uint256 blockNumber) external returns (uint256 forkId);

    // Creates a new fork with the given endpoint and the _latest_ block and returns the identifier of the fork
    function createFork(string calldata urlOrAlias) external returns (uint256 forkId);

    // Creates a new fork with the given endpoint and at the block the given transaction was mined in, replays all transaction mined in the block before the transaction,
    // and returns the identifier of the fork
    function createFork(string calldata urlOrAlias, bytes32 txHash) external returns (uint256 forkId);

    // Creates and also selects a new fork with the given endpoint and block and returns the identifier of the fork
    function createSelectFork(string calldata urlOrAlias, uint256 blockNumber) external returns (uint256 forkId);

    // Creates and also selects new fork with the given endpoint and at the block the given transaction was mined in, replays all transaction mined in the block before
    // the transaction, returns the identifier of the fork
    function createSelectFork(string calldata urlOrAlias, bytes32 txHash) external returns (uint256 forkId);

    // Creates and also selects a new fork with the given endpoint and the latest block and returns the identifier of the fork
    function createSelectFork(string calldata urlOrAlias) external returns (uint256 forkId);

    // Updates the currently active fork to given block number
    // This is similar to `roll` but for the currently active fork
    function rollFork(uint256 blockNumber) external;

    // Updates the currently active fork to given transaction
    // this will `rollFork` with the number of the block the transaction was mined in and replays all transaction mined before it in the block
    function rollFork(bytes32 txHash) external;

    // Updates the given fork to given block number
    function rollFork(uint256 forkId, uint256 blockNumber) external;

    // Updates the given fork to block number of the given transaction and replays all transaction mined before it in the block
    function rollFork(uint256 forkId, bytes32 txHash) external;

    // Takes a fork identifier created by `createFork` and sets the corresponding forked state as active.
    function selectFork(uint256 forkId) external;

    // Fetches the given transaction from the active fork and executes it on the current state
    function transact(bytes32 txHash) external;

    // Fetches the given transaction from the given fork and executes it on the current state
    function transact(uint256 forkId, bytes32 txHash) external;

    // --- Behavior ---

    // In forking mode, explicitly grant the given address cheatcode access
    function allowCheatcodes(address account) external;

    // Marks that the account(s) should use persistent storage across fork swaps in a multifork setup
    // Meaning, changes made to the state of this account will be kept when switching forks
    function makePersistent(address account) external;
    function makePersistent(address account0, address account1) external;
    function makePersistent(address account0, address account1, address account2) external;
    function makePersistent(address[] calldata accounts) external;

    // Revokes persistent status from the address, previously added via `makePersistent`
    function revokePersistent(address account) external;
    function revokePersistent(address[] calldata accounts) external;

    // Returns true if the account is marked as persistent
    function isPersistent(address account) external view returns (bool persistent);

    // ======== Test Assertions and Utilities ========

    // Expects a call to an address with the specified calldata.
    // Calldata can either be a strict or a partial match
    function expectCall(address callee, bytes calldata data) external;

    // Expects given number of calls to an address with the specified calldata.
    function expectCall(address callee, bytes calldata data, uint64 count) external;

    // Expects a call to an address with the specified msg.value and calldata
    function expectCall(address callee, uint256 msgValue, bytes calldata data) external;

    // Expects given number of calls to an address with the specified msg.value and calldata
    function expectCall(address callee, uint256 msgValue, bytes calldata data, uint64 count) external;

    // Expect a call to an address with the specified msg.value, gas, and calldata.
    function expectCall(address callee, uint256 msgValue, uint64 gas, bytes calldata data) external;

    // Expects given number of calls to an address with the specified msg.value, gas, and calldata.
    function expectCall(address callee, uint256 msgValue, uint64 gas, bytes calldata data, uint64 count) external;

    // Expect a call to an address with the specified msg.value and calldata, and a *minimum* amount of gas.
    function expectCallMinGas(address callee, uint256 msgValue, uint64 minGas, bytes calldata data) external;

    // Expect given number of calls to an address with the specified msg.value and calldata, and a *minimum* amount of gas.
    function expectCallMinGas(address callee, uint256 msgValue, uint64 minGas, bytes calldata data, uint64 count)
        external;

    // Prepare an expected log with (bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData).
    // Call this function, then emit an event, then call a function. Internally after the call, we check if
    // logs were emitted in the expected order with the expected topics and data (as specified by the booleans).
    function expectEmit(bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData) external;

    // Same as the previous method, but also checks supplied address against emitting contract.
    function expectEmit(bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData, address emitter)
        external;

    // Prepare an expected log with all topic and data checks enabled.
    // Call this function, then emit an event, then call a function. Internally after the call, we check if
    // logs were emitted in the expected order with the expected topics and data.
    function expectEmit() external;

    // Same as the previous method, but also checks supplied address against emitting contract.
    function expectEmit(address emitter) external;

    // Expects an error on next call that exactly matches the revert data.
    function expectRevert(bytes calldata revertData) external;

    // Expects an error on next call that starts with the revert data.
    function expectRevert(bytes4 revertData) external;

    // Expects an error on next call with any revert data.
    function expectRevert() external;

    // Only allows memory writes to offsets [0x00, 0x60) ∪ [min, max) in the current subcontext. If any other
    // memory is written to, the test will fail. Can be called multiple times to add more ranges to the set.
    function expectSafeMemory(uint64 min, uint64 max) external;

    // Only allows memory writes to offsets [0x00, 0x60) ∪ [min, max) in the next created subcontext.
    // If any other memory is written to, the test will fail. Can be called multiple times to add more ranges
    // to the set.
    function expectSafeMemoryCall(uint64 min, uint64 max) external;

    // Marks a test as skipped. Must be called at the top of the test.
    function skip(bool skipTest) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 <0.9.0;

import "./Vulcan.sol";
import "./Events.sol";
import {accountsUnsafe as accounts} from "./Accounts.sol";
import {ctxUnsafe as ctx} from "./Context.sol";
import {formatError} from "./Utils.sol";

struct Call {
    bytes callData;
    bool success;
    bytes returnData;
    Log[] logs;
}

library watchersUnsafe {
    using watchersUnsafe for *;

    /// @dev Magic.
    bytes32 constant WATCHERS_MAGIC = keccak256("vulcan.watchers.magic");

    /// @dev Obtains the address of the watcher for `target`.
    /// @param target The address for which we need to get the watcher address.
    /// @return The address of the watcher.
    function watcherAddress(address target) internal pure returns (address) {
        return address(uint160(uint256(uint160(target)) ^ uint256(WATCHERS_MAGIC)));
    }

    /// @dev Obtains the address of the target for `_target`.
    /// @param _watcher The address for which we need to get the target address.
    /// @return The address of the target.
    function targetAddress(address _watcher) internal pure returns (address) {
        return address(uint160(uint256(uint160(_watcher)) ^ uint256(WATCHERS_MAGIC)));
    }

    /// @dev Obtains the Watcher implementation for the `target` address.
    /// @param target The address used to obtain the watcher implementation address.
    /// @return The Watcher implementation.
    function watcher(address target) internal view returns (Watcher) {
        address _watcher = watcherAddress(target);
        require(_watcher.code.length != 0, _formatError("watcher(address)", "Address doesn't have a watcher"));

        return Watcher(_watcher);
    }

    /// @dev Starts watching a `target` address.
    /// @param target The address to watch.
    /// @return The Watcher implementation.
    function watch(address target) internal returns (Watcher) {
        address _watcher = watcherAddress(target);
        require(_watcher.code.length == 0, _formatError("watch(address)", "Address already has a watcher"));

        accounts.setCode(_watcher, type(Watcher).runtimeCode);

        WatcherProxy proxy = new WatcherProxy();

        bytes memory targetCode = target.code;

        // Switcheroo
        accounts.setCode(target, address(proxy).code);
        accounts.setCode(address(proxy), targetCode);

        Watcher(_watcher).setImplementationAddress(address(proxy));

        return Watcher(_watcher);
    }

    /// @dev Stops watching the `target` address.
    /// @param target The address to stop watching.
    function stop(address target) internal {
        target.stopWatcher();
    }

    /// @dev Stops watching the `target` address.
    /// @param target The address to stop watching.
    function stopWatcher(address target) internal {
        watcher(target).stop();
    }

    /// @dev Obtains all the calls made to the `target` address.
    /// @param target The address of the target contract to query.
    /// @return An array of `Call` structs, each containing information about a call.
    function calls(address target) internal view returns (Call[] memory) {
        return watcher(target).calls();
    }

    /// @dev Obtains an specific call made to the `target` address at an specific index.
    /// @param target The address of the target contract to query.
    /// @param index The index of the call to query.
    /// @return A `Call` struct that contains the information about the call.
    function getCall(address target, uint256 index) internal view returns (Call memory) {
        return watcher(target).getCall(index);
    }

    /// @dev Obtains the first call made to the `target` address.
    /// @param target The address of the target contract to query.
    /// @return A `Call` struct that contains the information about the call.
    function firstCall(address target) internal view returns (Call memory) {
        return watcher(target).firstCall();
    }

    /// @dev Obtains the last call made to the `target` address.
    /// @param target The address of the target contract to query.
    /// @return A `Call` struct that contains the information about the call.
    function lastCall(address target) internal view returns (Call memory) {
        return watcher(target).lastCall();
    }

    /// @dev Starts capturing reverts for the `target` address. This will prevent the `target` contract to
    /// revert until `disableCaptureReverts` is called. This is meant to be used in conjunction with the `toHaveReverted` and
    /// `toHaveRevertedWith` functions from the expect library.
    /// @param target The address for which the reverts are going to be captured.
    /// @return The Watcher implementation.
    function captureReverts(address target) internal returns (Watcher) {
        Watcher _watcher = watcher(target);
        _watcher.captureReverts();
        return _watcher;
    }

    /// @dev Stops capturing reverts for the `target` address.
    /// @param target The target address.
    /// @return The Watcher implementation.
    function disableCaptureReverts(address target) internal returns (Watcher) {
        Watcher _watcher = watcher(target);
        _watcher.disableCaptureReverts();
        return _watcher;
    }

    function _formatError(string memory func, string memory message) private pure returns (string memory) {
        return formatError("watchers", func, message);
    }
}

contract Watcher {
    /// @dev Whether to capture reverts or not.
    bool public shouldCaptureReverts;
    /// @dev The address of the implementation.
    address public implementation;

    /// @dev Stores all the calls made.
    Call[] private _calls;

    /// @dev Stores a call.
    /// @param _callData The data for the call.
    /// @param _success True if the call succeeded, false otherwise.
    /// @param _returnData The data that was returned from the call.
    /// @param _logs The logs that were emitted on the call.
    function storeCall(bytes memory _callData, bool _success, bytes memory _returnData, Log[] memory _logs) external {
        Call storage call = _calls.push();
        call.callData = _callData;
        call.success = _success;
        call.returnData = _returnData;

        Log[] storage logs = call.logs;

        for (uint256 i; i < _logs.length; ++i) {
            logs.push(_logs[i]);
        }
    }

    /// @dev Returns all the calls that were made to the `implementation` contract.
    /// @return An array of `Call` structs, each containing information about a call.
    function calls() external view returns (Call[] memory) {
        return _calls;
    }

    /// @dev Returns a specific call that was made to the `implementation` contract.
    /// @return A `Call` struct containing information about a call.
    function getCall(uint256 index) external view returns (Call memory) {
        return _calls[index];
    }

    /// @dev Returns the first call that was made to the `implementation` contract.
    /// @return A `Call` struct containing information about a call.
    function firstCall() external view returns (Call memory) {
        return _calls[0];
    }

    /// @dev Returns the last call that was made to the `implementation` contract.
    /// @return A `Call` struct containing information about a call.
    function lastCall() external view returns (Call memory) {
        Call[] memory currentCalls = _calls;

        return currentCalls[currentCalls.length - 1];
    }

    /// @dev Starts capturing reverts for the `implementation` contract.
    function captureReverts() external {
        shouldCaptureReverts = true;
    }

    /// @dev Stops capturing reverts for the `implementation` contract.
    function disableCaptureReverts() external {
        shouldCaptureReverts = false;
    }

    /// @dev Stops watching calls for the `implementation` contract.
    function stop() external {
        address target = watchersUnsafe.targetAddress(address(this));
        accounts.setCode(target, implementation.code);

        shouldCaptureReverts = false;
        implementation = address(0);
        // Sets the array length to 0. Invoking `storeCall` after `stop` will override the items on
        // the array
        delete _calls;

        accounts.setCode(address(this), bytes(""));
    }

    /// @dev Sets the address of the `implementation` contract.
    /// @param _implementation The address of the implementation contract.
    function setImplementationAddress(address _implementation) external {
        implementation = _implementation;
    }
}

contract WatcherProxy {
    using vulcan for *;

    /// @dev The target contract
    address private immutable _target;

    constructor() {
        _target = address(this);
    }

    /// @dev A fallback function that will capture every call made to this contract and proxy them
    /// to `_target`.
    /// @param _callData The call data.
    /// @return The data returnded from the `_target` contract proxied call.
    fallback(bytes calldata _callData) external payable returns (bytes memory) {
        ctx.pauseGasMetering();
        bool isStatic = ctx.isStaticcall();

        if (!isStatic) {
            events.recordLogs();
        }

        ctx.resumeGasMetering();

        (bool success, bytes memory returnData) = _target.delegatecall(_callData);

        ctx.pauseGasMetering();

        // TODO: ugly, try to clean up
        if (!isStatic) {
            Log[] memory logs = events.getRecordedLogs();

            // Filter logs by address and replace in place
            uint256 watcherLogCount = 0;
            for (uint256 i = 0; i < logs.length; i++) {
                if (logs[i].emitter == address(this)) {
                    logs[watcherLogCount] = logs[i];
                    watcherLogCount++;
                }
            }

            Log[] memory filteredLogs = new Log[](watcherLogCount);

            // Add logs to call
            for (uint256 i = 0; i < watcherLogCount; i++) {
                filteredLogs[i] = logs[i];
            }

            Watcher watcher = watchersUnsafe.watcher(address(this));
            watcher.storeCall(_callData, success, returnData, filteredLogs);

            if (!watcher.shouldCaptureReverts() && !success) {
                ctx.resumeGasMetering();
                assembly {
                    revert(add(returnData, 32), mload(returnData))
                }
            }
        } else if (!success) {
            ctx.resumeGasMetering();
            assembly {
                revert(add(returnData, 32), mload(returnData))
            }
        }

        ctx.resumeGasMetering();

        return returnData;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 <0.9.0;

import {vulcan} from "./Vulcan.sol";
import {accountsUnsafe as accounts} from "./Accounts.sol";
import {strings} from "./Strings.sol";
import {println, formatError} from "./Utils.sol";

type Context is bytes32;

interface IMutator {
    function mutate() external pure;
}

library ctxSafe {
    function broadcast() internal {
        vulcan.hevm.broadcast();
    }

    function broadcast(address from) internal {
        vulcan.hevm.broadcast(from);
    }

    function broadcast(uint256 privKey) internal {
        vulcan.hevm.broadcast(privKey);
    }

    function startBroadcast() internal {
        vulcan.hevm.startBroadcast();
    }

    function startBroadcast(address from) internal {
        vulcan.hevm.startBroadcast(from);
    }

    function startBroadcast(uint256 privKey) internal {
        vulcan.hevm.startBroadcast(privKey);
    }

    function stopBroadcast() internal {
        vulcan.hevm.stopBroadcast();
    }

    function assume(bool condition) internal pure {
        vulcan.hevm.assume(condition);
    }

    function pauseGasMetering() internal {
        vulcan.hevm.pauseGasMetering();
    }

    function resumeGasMetering() internal {
        vulcan.hevm.resumeGasMetering();
    }

    function startGasReport(string memory name) internal {
        if (bytes(name).length > 32) {
            revert(_formatError("startGasReport", "Gas report name can't have more than 32 characters"));
        }

        bytes32 b32Name = bytes32(bytes(name));
        bytes32 slot = keccak256(bytes("vulcan.ctx.gasReport.name"));
        accounts.setStorage(address(vulcan.hevm), slot, b32Name);
        bytes32 valueSlot = keccak256(abi.encodePacked("vulcan.ctx.gasReport", b32Name));
        accounts.setStorage(address(vulcan.hevm), valueSlot, bytes32(gasleft()));
    }

    function endGasReport() internal view {
        uint256 gas = gasleft();
        bytes32 slot = keccak256(bytes("vulcan.ctx.gasReport.name"));
        bytes32 b32Name = accounts.readStorage(address(vulcan.hevm), slot);
        bytes32 valueSlot = keccak256(abi.encodePacked("vulcan.ctx.gasReport", b32Name));
        uint256 prevGas = uint256(accounts.readStorage(address(vulcan.hevm), valueSlot));
        if (gas > prevGas) {
            revert(_formatError("endGasReport", "Gas used can't have a negative value"));
        }
        println(string.concat("gas(", string(abi.encodePacked(b32Name)), "):", strings.toString(prevGas - gas)));
    }

    function _formatError(string memory func, string memory message) private pure returns (string memory) {
        return formatError("ctx", func, message);
    }
}

/// @dev Contract used to check if a call is static or not.
contract CallContext {
    uint256 private val = 0;

    /// @dev Function used to check if the call can mutate the storage.
    function mutate() external {
        val = 0;
    }

    /// @dev Function to check if the current call is a staticcall.
    function isStaticcall() external view returns (bool) {
        try IMutator(address(this)).mutate() {
            return true;
        } catch {
            return false;
        }
    }
}

library ctxUnsafe {
    /// @dev Deterministic address that will hold the code of the `CallContext` contract.
    address internal constant CALL_CONTEXT_ADDRESS = address(uint160(uint256(keccak256("vulcan.ctx.callContext"))));

    /// @dev Function to initialize and set the code of `CALL_CONTEXT_ADDRESS`.
    function init() internal {
        accounts.setCode(CALL_CONTEXT_ADDRESS, type(CallContext).runtimeCode);
    }

    function broadcast() internal {
        ctxSafe.broadcast();
    }

    function broadcast(address from) internal {
        ctxSafe.broadcast(from);
    }

    function broadcast(uint256 privKey) internal {
        ctxSafe.broadcast(privKey);
    }

    function startBroadcast() internal {
        ctxSafe.startBroadcast();
    }

    function startBroadcast(address from) internal {
        ctxSafe.startBroadcast(from);
    }

    function startBroadcast(uint256 privKey) internal {
        ctxSafe.startBroadcast(privKey);
    }

    function stopBroadcast() internal {
        ctxSafe.stopBroadcast();
    }

    function assume(bool condition) internal pure {
        ctxSafe.assume(condition);
    }

    function pauseGasMetering() internal {
        ctxSafe.pauseGasMetering();
    }

    function resumeGasMetering() internal {
        ctxSafe.resumeGasMetering();
    }

    function startGasReport(string memory name) internal {
        ctxSafe.startGasReport(name);
    }

    function endGasReport() internal view {
        ctxSafe.endGasReport();
    }

    /// @dev Checks whether the current call is a static call or not.
    /// @return True if the current call is a static call, false otherwise.
    function isStaticcall() internal view returns (bool) {
        return CallContext(CALL_CONTEXT_ADDRESS).isStaticcall();
    }

    /// @dev sets the `block.timestamp` to `ts`
    /// @param ts the new block timestamp
    function setBlockTimestamp(Context self, uint256 ts) internal returns (Context) {
        vulcan.hevm.warp(ts);
        return self;
    }

    /// @dev sets the `block.timestamp` to `ts`
    /// @param ts the new block timestamp
    function setBlockTimestamp(uint256 ts) internal returns (Context) {
        return setBlockTimestamp(Context.wrap(0), ts);
    }

    /// @dev sets the `block.number` to `blockNumber`
    /// @param blockNumber the new block number
    function setBlockNumber(Context self, uint256 blockNumber) internal returns (Context) {
        vulcan.hevm.roll(blockNumber);
        return self;
    }

    /// @dev sets the `block.number` to `blockNumber`
    /// @param blockNumber the new block number
    function setBlockNumber(uint256 blockNumber) internal returns (Context) {
        return setBlockNumber(Context.wrap(0), blockNumber);
    }

    /// @dev sets the `block.basefee` to `baseFee`
    /// @param baseFee the new block base fee
    function setBlockBaseFee(Context self, uint256 baseFee) internal returns (Context) {
        vulcan.hevm.fee(baseFee);
        return self;
    }

    /// @dev sets the `block.basefee` to `baseFee`
    /// @param baseFee the new block base fee
    function setBlockBaseFee(uint256 baseFee) internal returns (Context) {
        return setBlockBaseFee(Context.wrap(0), baseFee);
    }

    /// @dev Sets block.prevrandao.
    /// @param newPrevrandao The new `block.prevrandao`.
    function setBlockPrevrandao(Context self, bytes32 newPrevrandao) internal returns (Context) {
        vulcan.hevm.prevrandao(newPrevrandao);
        return self;
    }

    /// @dev Sets block.prevrandao.
    /// @param newPrevrandao The new `block.prevrandao`.
    function setBlockPrevrandao(bytes32 newPrevrandao) internal returns (Context) {
        return setBlockPrevrandao(Context.wrap(0), newPrevrandao);
    }

    /// @dev sets the `block.chainid` to `chainId`
    /// @param chainId the new block chain id
    function setChainId(Context self, uint64 chainId) internal returns (Context) {
        vulcan.hevm.chainId(chainId);
        return self;
    }

    /// @dev sets the `block.chainid` to `chainId`
    /// @param chainId the new block chain id
    function setChainId(uint64 chainId) internal returns (Context) {
        return setChainId(Context.wrap(0), chainId);
    }

    /// @dev Sets the block coinbase to `who`.
    /// @param self The context.
    /// @param who The address to set as the block coinbase.
    /// @return The same context in order to allow function chaining.
    function setBlockCoinbase(Context self, address who) internal returns (Context) {
        vulcan.hevm.coinbase(who);
        return self;
    }

    /// @dev Sets the block coinbase to `who`.
    /// @param who The address to set as the block coinbase.
    /// @return The same context to allow function chaining.
    function setBlockCoinbase(address who) internal returns (Context) {
        return setBlockCoinbase(Context.wrap(0), who);
    }

    /// @dev Sets the transaction gas price.
    /// @param newGasPrice The new transaction gas price.
    function setGasPrice(Context self, uint256 newGasPrice) internal returns (Context) {
        vulcan.hevm.txGasPrice(newGasPrice);
        return self;
    }

    /// @dev Sets the transaction gas price.
    /// @param newGasPrice The new transaction gas price.
    function setGasPrice(uint256 newGasPrice) internal returns (Context) {
        return setGasPrice(Context.wrap(0), newGasPrice);
    }

    /// @dev Function used to check whether the next call reverts or not.
    /// @param revertData The function call data that that is expected to fail.
    function expectRevert(bytes memory revertData) internal {
        vulcan.hevm.expectRevert(revertData);
    }

    /// @dev Function used to check whether the next call reverts or not.
    /// @param revertData The function call signature that that is expected to fail.
    function expectRevert(bytes4 revertData) internal {
        vulcan.hevm.expectRevert(revertData);
    }

    /// @dev Function used to check whether the next call reverts or not.
    function expectRevert() internal {
        vulcan.hevm.expectRevert();
    }

    /// @dev Checks if an event was emitted with the given properties.
    /// @param checkTopic1 Whether to check the first topic match.
    /// @param checkTopic2 Whether to check the second topic match.
    /// @param checkTopic3 Whether to check the third topic match.
    /// @param checkData Whether to check the data field match.
    function expectEmit(bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData) internal {
        vulcan.hevm.expectEmit(checkTopic1, checkTopic2, checkTopic3, checkData);
    }

    /// @dev Checks if an event was emitted with the given properties.
    /// @param checkTopic1 Whether to check the first topic match.
    /// @param checkTopic2 Whether to check the second topic match.
    /// @param checkTopic3 Whether to check the third topic match.
    /// @param checkData Whether to check the data field match.
    /// @param emitter The address of the expected emitter.
    function expectEmit(bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData, address emitter)
        internal
    {
        vulcan.hevm.expectEmit(checkTopic1, checkTopic2, checkTopic3, checkData, emitter);
    }

    /// @dev Function to mock a call to a specified address.
    /// @param callee The address for which the call should be mocked.
    /// @param data The data for which the call should be mocked.
    /// @param returnData The data that should be returned if `data` matches the provided call data.
    function mockCall(address callee, bytes memory data, bytes memory returnData) internal {
        vulcan.hevm.mockCall(callee, data, returnData);
    }

    /// @dev Function to mock a call to a specified address.
    /// @param callee The address for which the call should be mocked.
    /// @param msgValue The `msg.value` for which the call should be mocked.
    /// @param data The data for which the call should be mocked.
    /// @param returnData The data that should be returned if `data` matches the provided call data.
    function mockCall(address callee, uint256 msgValue, bytes memory data, bytes memory returnData) internal {
        vulcan.hevm.mockCall(callee, msgValue, data, returnData);
    }

    /// @dev Function to clear all the mocked calls.
    function clearMockedCalls() internal {
        vulcan.hevm.clearMockedCalls();
    }

    /// @dev Used to check if a call to `callee` with `data` was made.
    /// @param callee The address that is expected to be called.
    /// @param data The call data that is expected to be used.
    function expectCall(address callee, bytes memory data) internal {
        vulcan.hevm.expectCall(callee, data);
    }

    /// @dev Used to check if a call to `callee` with `data` and `msgValue` was made.
    /// @param callee The address that is expected to be called.
    /// @param msgValue The `msg.value` that is expected to be sent.
    /// @param data The call data that is expected to be used.
    function expectCall(address callee, uint256 msgValue, bytes memory data) internal {
        vulcan.hevm.expectCall(callee, msgValue, data);
    }

    /// @dev Expect a call to an address with the specified msg.value and calldata, and a minimum amount of gas.
    /// @param callee The address that is expected to be called.
    /// @param msgValue The `msg.value` that is expected to be sent.
    /// @param minGas The expected minimum amount of gas for the call.
    /// @param data The call data that is expected to be used.
    function expectCallMinGas(address callee, uint256 msgValue, uint64 minGas, bytes calldata data) internal {
        vulcan.hevm.expectCallMinGas(callee, msgValue, minGas, data);
    }

    /// @dev Expect a number call to an address with the specified msg.value and calldata, and a minimum amount of gas.
    /// @param callee The address that is expected to be called.
    /// @param msgValue The `msg.value` that is expected to be sent.
    /// @param minGas The expected minimum amount of gas for the call.
    /// @param data The call data that is expected to be used.
    /// @param count The number of calls that are expected.
    function expectCallMinGas(address callee, uint256 msgValue, uint64 minGas, bytes calldata data, uint64 count)
        external
    {
        vulcan.hevm.expectCallMinGas(callee, msgValue, minGas, data, count);
    }

    /// @dev Allows to  write on memory only between [0x00, 0x60) and [min, max) in the current.
    /// subcontext.
    /// @param min The lower limit of the allowed memory slot.
    /// @param max The upper limit of the allowed memory slot.
    function expectSafeMemory(uint64 min, uint64 max) external {
        vulcan.hevm.expectSafeMemory(min, max);
    }

    /// @dev Allows to  write on memory only between [0x00, 0x60) and [min, max) in the next
    // subcontext.
    /// @param min The lower limit of the allowed memory slot.
    /// @param max The upper limit of the allowed memory slot.
    function expectsafememorycall(uint64 min, uint64 max) external {
        vulcan.hevm.expectSafeMemoryCall(min, max);
    }

    /// @dev Takes a snapshot of the current state of the vm and returns an identifier.
    /// @return The snapshot identifier.
    function snapshot(Context) internal returns (uint256) {
        return vulcan.hevm.snapshot();
    }

    /// @dev Takes a snapshot of the current state of the vm and returns an identifier.
    /// @return The snapshot identifier.
    function snapshot() internal returns (uint256) {
        return snapshot(Context.wrap(0));
    }

    /// @dev Reverts the state of the vm to the snapshot with id `snapshotId`.
    /// @param snapshotId The id of the snapshot to revert to.
    /// @return true if the vm was reverted to the selected snapshot.
    function revertToSnapshot(Context, uint256 snapshotId) internal returns (bool) {
        return vulcan.hevm.revertTo(snapshotId);
    }

    /// @dev Reverts the state of the vm to the snapshot with id `snapshotId`.
    /// @param snapshotId The id of the snapshot to revert to.
    /// @return true if the vm was reverted to the selected snapshot.
    function revertToSnapshot(uint256 snapshotId) internal returns (bool) {
        return revertToSnapshot(Context.wrap(0), snapshotId);
    }

    /// @dev Creates a breakpoint to jump to in the debugger.
    /// @param name The name of the breakpoint.
    function addBreakpoint(Context self, string memory name) internal returns (Context) {
        vulcan.hevm.breakpoint(name);
        return self;
    }

    /// @dev Creates a breakpoint to jump to in the debugger.
    /// @param name The name of the breakpoint.
    function addBreakpoint(string memory name) internal returns (Context) {
        return addBreakpoint(Context.wrap(0), name);
    }

    /// @dev Creates a breakpoint to jump to in the debugger.
    /// @param name The name of the breakpoint.
    /// @param condition The condition that needs to be fulfilled in order to add the breakpoint.
    function addConditionalBreakpoint(Context self, string memory name, bool condition) internal returns (Context) {
        vulcan.hevm.breakpoint(name, condition);
        return self;
    }

    /// @dev Creates a breakpoint to jump to in the debugger.
    /// @param name The name of the breakpoint.
    /// @param condition The condition that needs to be fulfilled in order to add the breakpoint.
    function addConditionalBreakpoint(string memory name, bool condition) internal returns (Context) {
        return addConditionalBreakpoint(Context.wrap(0), name, condition);
    }
}

using ctxUnsafe for Context global;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 <0.9.0;

import {Vm as Hevm} from "forge-std/Vm.sol";
import "./Vulcan.sol";

library events {
    /// @dev Obtains the topic representation of an `uint256` parameter.
    /// @param _param The `uint256` value.
    /// @return The representation of `_param` as an event topic.
    function topic(uint256 _param) internal pure returns (bytes32) {
        return bytes32(_param);
    }

    /// @dev Obtains the topic representation of a `string` parameter.
    /// @param _param The `string` value.
    /// @return The representation of `_param` as an event topic.
    function topic(string memory _param) internal pure returns (bytes32) {
        return keccak256(bytes(_param));
    }

    /// @dev Obtains the topic representation of an `address` parameter.
    /// @param _param The `address` value.
    /// @return The representation of `_param` as an event topic.
    function topic(address _param) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_param)));
    }

    /// @dev Obtains the topic representation of a `bytes32` parameter.
    /// @param _param The `bytes32` value.
    /// @return The representation of `_param` as an event topic.
    function topic(bytes32 _param) internal pure returns (bytes32) {
        return _param;
    }

    /// @dev Obtains the topic representation of a `bytes` parameter.
    /// @param _param The `bytes` value.
    /// @return The representation of `_param` as an event topic.
    function topic(bytes memory _param) internal pure returns (bytes32) {
        return keccak256(_param);
    }

    /// @dev Obtains the topic representation of a `bool` parameter.
    /// @param _param The `bool` value.
    /// @return The representation of `_param` as an event topic.
    function topic(bool _param) internal pure returns (bytes32) {
        return bytes32(uint256(_param ? 1 : 0));
    }

    /// @dev Obtains the topic representation of a `int256` parameter.
    /// @param _param The `int256` value.
    /// @return The representation of `_param` as an event topic.
    function topic(int256 _param) internal pure returns (bytes32) {
        return bytes32(uint256(_param));
    }

    /// @dev Starts recording all transactions logs.
    function recordLogs() internal {
        vulcan.hevm.recordLogs();
    }

    /// @dev Obtains all recorded transactions logs.
    function getRecordedLogs() internal returns (Log[] memory logs) {
        Hevm.Log[] memory recorded = vulcan.hevm.getRecordedLogs();
        assembly {
            logs := recorded
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 <0.9.0;

import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";

import {strings} from "./Strings.sol";
import "./Vulcan.sol";
import {formatError} from "./Utils.sol";

/// @dev Accounts module for scripts
library accountsSafe {
    /// @dev Reads the storage at the specified `slot` for the given `who` address and returns the content.
    /// @param who The address whose storage will be read.
    /// @param slot The position of the storage slot to read.
    /// @return The contents of the specified storage slot as a bytes32 value.
    function readStorage(address who, bytes32 slot) internal view returns (bytes32) {
        return vulcan.hevm.load(who, slot);
    }

    /// @dev Signs the specified `digest` using the provided `privKey` and returns the signature in the form of `(v, r, s)`.
    /// @param privKey The private key to use for signing the digest.
    /// @param digest The message digest to sign.
    /// @return A tuple containing the signature parameters `(v, r, s)` as a `uint8`, `bytes32`, and `bytes32`, respectively.
    function sign(uint256 privKey, bytes32 digest) internal pure returns (uint8, bytes32, bytes32) {
        return vulcan.hevm.sign(privKey, digest);
    }

    /// @dev Derives the Ethereum address corresponding to the provided `privKey`.
    /// @param privKey The private key to use for deriving the Ethereum address.
    /// @return The Ethereum address derived from the provided private key.
    function derive(uint256 privKey) internal pure returns (address) {
        return vulcan.hevm.addr(privKey);
    }

    /// @dev Derives the private key corresponding to the specified `mnemonicOrPath` and `index`.
    /// @param mnemonicOrPath The mnemonic or derivation path to use for deriving the private key.
    /// @param index The index of the derived private key to retrieve.
    /// @return The private key derived from the specified mnemonic and index as a `uint256` value.
    function deriveKey(string memory mnemonicOrPath, uint32 index) internal pure returns (uint256) {
        return vulcan.hevm.deriveKey(mnemonicOrPath, index);
    }

    /// @dev Derives the private key corresponding to the specified `mnemonicOrPath`, `derivationPath`, and `index`.
    /// @param mnemonicOrPath The mnemonic or derivation path to use for deriving the master key.
    /// @param derivationPath The specific derivation path to use for deriving the private key (optional).
    /// @param index The index of the derived private key to retrieve.
    /// @return The private key derived from the specified mnemonic, derivation path, and index as a `uint256` value.
    function deriveKey(string memory mnemonicOrPath, string memory derivationPath, uint32 index)
        internal
        pure
        returns (uint256)
    {
        return vulcan.hevm.deriveKey(mnemonicOrPath, derivationPath, index);
    }

    /// @dev Adds the specified `privKey` to the local forge wallet.
    /// @param privKey The private key to add to the local forge wallet.
    /// @return The Ethereum address corresponding to the added private key.
    function rememberKey(uint256 privKey) internal returns (address) {
        return vulcan.hevm.rememberKey(privKey);
    }

    /// @dev Returns the current `nonce` of the specified `who` address.
    /// @param who The address for which to obtain the current `nonce`.
    /// @return The current `nonce` of the specified address as a `uint64` value.
    function getNonce(address who) internal view returns (uint64) {
        return vulcan.hevm.getNonce(who);
    }

    /// @dev Starts recording all storage reads and writes for later analysis.
    function recordStorage() internal {
        vulcan.hevm.record();
    }

    /// @dev Obtains an array of slots that have been read and written for the specified address `who`.
    /// @param who The address for which to obtain the storage accesses.
    /// @return reads An array of storage slots that have been read.
    /// @return writes An array of storage slots that have been written.
    function getStorageAccesses(address who) internal returns (bytes32[] memory reads, bytes32[] memory writes) {
        return vulcan.hevm.accesses(who);
    }

    /// @dev Adds a label to the specified address `who` for identification purposes in debug traces.
    /// @param who The address to label.
    /// @param lbl The label to apply to the address.
    /// @return The same address that was passed as input.
    function label(address who, string memory lbl) internal returns (address) {
        vulcan.hevm.label(who, lbl);
        return who;
    }

    /// @dev Creates an address without label.
    function create() internal returns (address) {
        uint256 id = _incrementId();
        return derive(uint256(keccak256(abi.encode(id))));
    }

    /// @dev Creates an address using the hash of the specified `name` as the private key and adds a label to the address.
    /// @param name The name to use as the basis for the address.
    /// @return The newly created address.
    function create(string memory name) internal returns (address) {
        return create(name, name);
    }

    /// @dev Creates an address using the hash of the specified `name` as the private key and adds a label to the address.
    /// @param name The name to use as the basis for the address.
    /// @param lbl The label to apply to the address.
    /// @return The newly created address.
    function create(string memory name, string memory lbl) internal returns (address) {
        address addr = derive(uint256(keccak256(abi.encodePacked(name))));

        return label(addr, lbl);
    }

    /// @dev Calculates the deployment address of `who` with nonce `nonce`.
    /// @param who The deployer address.
    /// @param nonce The deployer nonce.
    function getDeploymentAddress(address who, uint64 nonce) internal pure returns (address) {
        bytes memory data;

        if (nonce == 0x00) {
            data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), who, bytes1(0x80));
        } else if (nonce <= 0x7f) {
            data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), who, uint8(nonce));
        } else if (nonce <= 0xff) {
            data = abi.encodePacked(bytes1(0xd7), bytes1(0x94), who, bytes1(0x81), uint8(nonce));
        } else if (nonce <= 0xffff) {
            data = abi.encodePacked(bytes1(0xd8), bytes1(0x94), who, bytes1(0x82), uint16(nonce));
        } else if (nonce <= 0xffffff) {
            data = abi.encodePacked(bytes1(0xd9), bytes1(0x94), who, bytes1(0x83), uint24(nonce));
        } else if (nonce <= 0xffffffff) {
            data = abi.encodePacked(bytes1(0xda), bytes1(0x94), who, bytes1(0x84), uint32(nonce));
        } else if (nonce <= 0xffffffffff) {
            data = abi.encodePacked(bytes1(0xdb), bytes1(0x94), who, bytes1(0x85), uint40(nonce));
        } else if (nonce <= 0xffffffffffff) {
            data = abi.encodePacked(bytes1(0xdc), bytes1(0x94), who, bytes1(0x86), uint48(nonce));
        } else if (nonce <= 0xffffffffffffff) {
            data = abi.encodePacked(bytes1(0xdd), bytes1(0x94), who, bytes1(0x87), uint56(nonce));
        } else if (nonce <= 0xffffffffffffffff) {
            data = abi.encodePacked(bytes1(0xde), bytes1(0x94), who, bytes1(0x88), uint64(nonce));
        }

        return address(uint160(uint256(keccak256(data))));
    }

    /// @dev Calculates the deployment address of `who` with the current nonce.
    /// @param who The deployer address.
    function getDeploymentAddress(address who) internal view returns (address) {
        return getDeploymentAddress(who, getNonce(who));
    }

    /// @dev Generates an array of addresses with a specific length.
    /// @param length The amount of addresses to generate.
    function createMany(uint256 length) internal returns (address[] memory) {
        require(length > 0, _formatError("createMany(uint256)", "Invalid length for addresses array"));

        address[] memory addresses = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            addresses[i] = create();
        }

        return addresses;
    }

    /// @dev Generates an array of addresses with a specific length and a prefix as label.
    /// The label for each address will be `{prefix}_{i}`.
    /// @param length The amount of addresses to generate.
    /// @param prefix The prefix of the label for each address.
    function createMany(uint256 length, string memory prefix) internal returns (address[] memory) {
        require(length > 0, "accounts: invalid length for addresses array");

        address[] memory addresses = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            addresses[i] = create(string.concat(prefix, "_", strings.toString(i)));
        }

        return addresses;
    }

    function _incrementId() private returns (uint256 count) {
        bytes32 slot = keccak256("vulcan.accounts.id.counter");

        assembly {
            count := sload(slot)
            sstore(slot, add(count, 1))
        }
    }

    function _formatError(string memory func, string memory message) private pure returns (string memory) {
        return formatError("accounts", func, message);
    }
}

/// @dev Accounts module for tests
library accountsUnsafe {
    using stdStorage for StdStorage;

    function stdStore() internal pure returns (StdStorage storage s) {
        bytes32 slot = keccak256("vulcan.accounts.stdStore");

        assembly {
            s.slot := slot
        }
    }

    function readStorage(address who, bytes32 slot) internal view returns (bytes32) {
        return accountsSafe.readStorage(who, slot);
    }

    function sign(uint256 privKey, bytes32 digest) internal pure returns (uint8, bytes32, bytes32) {
        return accountsSafe.sign(privKey, digest);
    }

    function derive(uint256 privKey) internal pure returns (address) {
        return accountsSafe.derive(privKey);
    }

    function deriveKey(string memory mnemonicOrPath, uint32 index) internal pure returns (uint256) {
        return accountsSafe.deriveKey(mnemonicOrPath, index);
    }

    function deriveKey(string memory mnemonicOrPath, string memory derivationPath, uint32 index)
        internal
        pure
        returns (uint256)
    {
        return accountsSafe.deriveKey(mnemonicOrPath, derivationPath, index);
    }

    function rememberKey(uint256 privKey) internal returns (address) {
        return accountsSafe.rememberKey(privKey);
    }

    function getNonce(address who) internal view returns (uint64) {
        return accountsSafe.getNonce(who);
    }

    function recordStorage() internal {
        return accountsSafe.recordStorage();
    }

    function getStorageAccesses(address who) internal returns (bytes32[] memory reads, bytes32[] memory writes) {
        return accountsSafe.getStorageAccesses(who);
    }

    function label(address who, string memory lbl) internal returns (address) {
        return accountsSafe.label(who, lbl);
    }

    function create() internal returns (address) {
        return accountsSafe.create();
    }

    function create(string memory name) internal returns (address) {
        return accountsSafe.create(name);
    }

    function create(string memory name, string memory lbl) internal returns (address) {
        return accountsSafe.create(name, lbl);
    }

    /// @dev Calculates the deployment address of `who` with nonce `nonce`.
    /// @param who The deployer address.
    /// @param nonce The deployer nonce.
    function getDeploymentAddress(address who, uint64 nonce) internal pure returns (address) {
        return accountsSafe.getDeploymentAddress(who, nonce);
    }

    /// @dev Calculates the deployment address of `who` with the current nonce.
    /// @param who The deployer address.
    function getDeploymentAddress(address who) internal view returns (address) {
        return accountsSafe.getDeploymentAddress(who);
    }

    /// @dev Sets the specified `slot` in the storage of the given `self` address to the provided `value`.
    /// @param self The address to modify the storage of.
    /// @param slot The storage slot to set.
    /// @param value The value to set the storage slot to.
    /// @return The address that was modified.
    function setStorage(address self, bytes32 slot, bytes32 value) internal returns (address) {
        vulcan.hevm.store(self, slot, value);
        return self;
    }

    /// @dev Sets the nonce of the given `self` address to the provided value `n`. It will revert if
    // the new nonce is lower than the current address nonce.
    /// @param self The address to set the nonce for.
    /// @param n The value to set the nonce to.
    /// @return The updated address with the modified nonce.
    function setNonce(address self, uint64 n) internal returns (address) {
        vulcan.hevm.setNonce(self, n);
        return self;
    }

    /// @dev Sets the nonce of the given `self` address to the arbitrary provided value `n`.
    /// @param self The address to set the nonce for.
    /// @param n The value to set the nonce to.
    /// @return The updated address with the modified nonce.
    function setNonceUnsafe(address self, uint64 n) internal returns (address) {
        vulcan.hevm.setNonceUnsafe(self, n);
        return self;
    }

    /// @dev Sets the `msg.sender` of the next call to `self`.
    /// @param self The address to impersonate.
    /// @return The address that was impersonated.
    function impersonateOnce(address self) internal returns (address) {
        stopImpersonate();
        vulcan.hevm.prank(self);
        return self;
    }

    /// @notice Sets the `msg.sender` of all subsequent calls to `self` until `stopImpersonate` is called
    /// @param self The address to impersonate.
    /// @return The address being impersonated.
    function impersonate(address self) internal returns (address) {
        stopImpersonate();
        vulcan.hevm.startPrank(self);
        return self;
    }

    /// @dev Sets the `msg.sender` of the next call to `self` and the `tx.origin`
    /// to `origin`.
    /// @param self The address to impersonate.
    /// @param origin The new `tx.origin`.
    /// @return The address that was impersonated.
    function impersonateOnce(address self, address origin) internal returns (address) {
        stopImpersonate();
        vulcan.hevm.prank(self, origin);
        return self;
    }

    /// @dev Sets the `msg.sender` and `tx.origin` of all the subsequent calls to `self` and `origin`
    /// respectively until `stopImpersonate` is called.
    /// @param self The address to impersonate.
    /// @param origin The new value for `tx.origin`.
    /// @return The address being impersonated.
    function impersonate(address self, address origin) internal returns (address) {
        stopImpersonate();
        vulcan.hevm.startPrank(self, origin);
        return self;
    }

    /// @notice Resets the values of `msg.sender` and `tx.origin` to the original values.
    function stopImpersonate() internal {
        try vulcan.hevm.stopPrank() {} catch (bytes memory) {}
    }

    /// @dev Sets the balance of an address and returns the address that was modified.
    /// @param self The address to set the balance of.
    /// @param bal The new balance to set.
    /// @return The address that was modified.
    function setBalance(address self, uint256 bal) internal returns (address) {
        vulcan.hevm.deal(self, bal);
        return self;
    }

    /// @dev Mints an amount of tokens to an address. This operation modifies the total supply of the token.
    /// @dev self The address that will own the tokens.
    /// @dev token The token to mint.
    /// @dev amount The amount of tokens to mint.
    /// @return The address that owns the minted tokens.
    function mintToken(address self, address token, uint256 amount) internal returns (address) {
        (, bytes memory balData) = token.call(abi.encodeWithSelector(0x70a08231, self));

        uint256 prevBal = abi.decode(balData, (uint256));

        setTokenBalance(self, token, prevBal + amount);

        (, bytes memory totSupData) = token.call(abi.encodeWithSelector(0x18160ddd));
        uint256 totSup = abi.decode(totSupData, (uint256));

        setTotalSupply(token, totSup + amount);

        return self;
    }

    /// @dev Burns an amount of tokens from an address. This operation modifies the total supply of the token.
    /// @dev self The address that owns the tokens.
    /// @dev token The token to burn.
    /// @dev amount The amount of tokens to burn.
    /// @return The address that owned the burned tokens.
    function burnToken(address self, address token, uint256 amount) internal returns (address) {
        (, bytes memory balData) = token.call(abi.encodeWithSelector(0x70a08231, self));

        uint256 prevBal = abi.decode(balData, (uint256));

        setTokenBalance(self, token, prevBal - amount);

        (, bytes memory totSupData) = token.call(abi.encodeWithSelector(0x18160ddd));
        uint256 totSup = abi.decode(totSupData, (uint256));

        setTotalSupply(token, totSup - amount);

        return self;
    }

    /// @dev Sets the token balance of an address.
    /// @param self The address to set the balance of.
    /// @param token The token that will be given to `self`.
    /// @param bal The new token balance of `self`.
    /// @return The address that was modified.
    function setTokenBalance(address self, address token, uint256 bal) internal returns (address) {
        stdStore().target(token).sig(0x70a08231).with_key(self).checked_write(bal);

        return self;
    }

    /// @dev Sets the total supply of a token.
    /// @param token The token that will be modified.
    /// @param totalSupply The new total supply of token.
    /// @return The token address.
    function setTotalSupply(address token, uint256 totalSupply) private returns (address) {
        stdStore().target(token).sig(0x18160ddd).checked_write(totalSupply);

        return token;
    }

    /// @dev Sets the code of an address.
    /// @param self The address to set the code for.
    /// @param code The new code to set for the address.
    /// @return The address that was modified.
    function setCode(address self, bytes memory code) internal returns (address) {
        vulcan.hevm.etch(self, code);
        return self;
    }

    /// @dev Generates an array of addresses with a specific length.
    /// @param length The amount of addresses to generate.
    function createMany(uint256 length) internal returns (address[] memory) {
        return accountsSafe.createMany(length);
    }

    /// @dev Generates an array of addresses with a specific length and a prefix as label.
    /// The label for each address will be `{prefix}_{i}`.
    /// @param length The amount of addresses to generate.
    /// @param prefix The prefix of the label for each address.
    function createMany(uint256 length, string memory prefix) internal returns (address[] memory) {
        return accountsSafe.createMany(length, prefix);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

import {Vm} from "./Vm.sol";

struct StdStorage {
    mapping(address => mapping(bytes4 => mapping(bytes32 => uint256))) slots;
    mapping(address => mapping(bytes4 => mapping(bytes32 => bool))) finds;
    bytes32[] _keys;
    bytes4 _sig;
    uint256 _depth;
    address _target;
    bytes32 _set;
}

library stdStorageSafe {
    event SlotFound(address who, bytes4 fsig, bytes32 keysHash, uint256 slot);
    event WARNING_UninitedSlot(address who, uint256 slot);

    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function sigs(string memory sigStr) internal pure returns (bytes4) {
        return bytes4(keccak256(bytes(sigStr)));
    }

    /// @notice find an arbitrary storage slot given a function sig, input data, address of the contract and a value to check against
    // slot complexity:
    //  if flat, will be bytes32(uint256(uint));
    //  if map, will be keccak256(abi.encode(key, uint(slot)));
    //  if deep map, will be keccak256(abi.encode(key1, keccak256(abi.encode(key0, uint(slot)))));
    //  if map struct, will be bytes32(uint256(keccak256(abi.encode(key1, keccak256(abi.encode(key0, uint(slot)))))) + structFieldDepth);
    function find(StdStorage storage self) internal returns (uint256) {
        address who = self._target;
        bytes4 fsig = self._sig;
        uint256 field_depth = self._depth;
        bytes32[] memory ins = self._keys;

        // calldata to test against
        if (self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))]) {
            return self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))];
        }
        bytes memory cald = abi.encodePacked(fsig, flatten(ins));
        vm.record();
        bytes32 fdat;
        {
            (, bytes memory rdat) = who.staticcall(cald);
            fdat = bytesToBytes32(rdat, 32 * field_depth);
        }

        (bytes32[] memory reads,) = vm.accesses(address(who));
        if (reads.length == 1) {
            bytes32 curr = vm.load(who, reads[0]);
            if (curr == bytes32(0)) {
                emit WARNING_UninitedSlot(who, uint256(reads[0]));
            }
            if (fdat != curr) {
                require(
                    false,
                    "stdStorage find(StdStorage): Packed slot. This would cause dangerous overwriting and currently isn't supported."
                );
            }
            emit SlotFound(who, fsig, keccak256(abi.encodePacked(ins, field_depth)), uint256(reads[0]));
            self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = uint256(reads[0]);
            self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = true;
        } else if (reads.length > 1) {
            for (uint256 i = 0; i < reads.length; i++) {
                bytes32 prev = vm.load(who, reads[i]);
                if (prev == bytes32(0)) {
                    emit WARNING_UninitedSlot(who, uint256(reads[i]));
                }
                if (prev != fdat) {
                    continue;
                }
                bytes32 new_val = ~prev;
                // store
                vm.store(who, reads[i], new_val);
                bool success;
                {
                    bytes memory rdat;
                    (success, rdat) = who.staticcall(cald);
                    fdat = bytesToBytes32(rdat, 32 * field_depth);
                }

                if (success && fdat == new_val) {
                    // we found which of the slots is the actual one
                    emit SlotFound(who, fsig, keccak256(abi.encodePacked(ins, field_depth)), uint256(reads[i]));
                    self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = uint256(reads[i]);
                    self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = true;
                    vm.store(who, reads[i], prev);
                    break;
                }
                vm.store(who, reads[i], prev);
            }
        } else {
            revert("stdStorage find(StdStorage): No storage use detected for target.");
        }

        require(
            self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))],
            "stdStorage find(StdStorage): Slot(s) not found."
        );

        delete self._target;
        delete self._sig;
        delete self._keys;
        delete self._depth;

        return self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))];
    }

    function target(StdStorage storage self, address _target) internal returns (StdStorage storage) {
        self._target = _target;
        return self;
    }

    function sig(StdStorage storage self, bytes4 _sig) internal returns (StdStorage storage) {
        self._sig = _sig;
        return self;
    }

    function sig(StdStorage storage self, string memory _sig) internal returns (StdStorage storage) {
        self._sig = sigs(_sig);
        return self;
    }

    function with_key(StdStorage storage self, address who) internal returns (StdStorage storage) {
        self._keys.push(bytes32(uint256(uint160(who))));
        return self;
    }

    function with_key(StdStorage storage self, uint256 amt) internal returns (StdStorage storage) {
        self._keys.push(bytes32(amt));
        return self;
    }

    function with_key(StdStorage storage self, bytes32 key) internal returns (StdStorage storage) {
        self._keys.push(key);
        return self;
    }

    function depth(StdStorage storage self, uint256 _depth) internal returns (StdStorage storage) {
        self._depth = _depth;
        return self;
    }

    function read(StdStorage storage self) private returns (bytes memory) {
        address t = self._target;
        uint256 s = find(self);
        return abi.encode(vm.load(t, bytes32(s)));
    }

    function read_bytes32(StdStorage storage self) internal returns (bytes32) {
        return abi.decode(read(self), (bytes32));
    }

    function read_bool(StdStorage storage self) internal returns (bool) {
        int256 v = read_int(self);
        if (v == 0) return false;
        if (v == 1) return true;
        revert("stdStorage read_bool(StdStorage): Cannot decode. Make sure you are reading a bool.");
    }

    function read_address(StdStorage storage self) internal returns (address) {
        return abi.decode(read(self), (address));
    }

    function read_uint(StdStorage storage self) internal returns (uint256) {
        return abi.decode(read(self), (uint256));
    }

    function read_int(StdStorage storage self) internal returns (int256) {
        return abi.decode(read(self), (int256));
    }

    function parent(StdStorage storage self) internal returns (uint256, bytes32) {
        address who = self._target;
        uint256 field_depth = self._depth;
        vm.startMappingRecording();
        uint256 child = find(self) - field_depth;
        (bool found, bytes32 key, bytes32 parent_slot) = vm.getMappingKeyAndParentOf(who, bytes32(child));
        if (!found) {
            revert(
                "stdStorage read_bool(StdStorage): Cannot find parent. Make sure you give a slot and startMappingRecording() has been called."
            );
        }
        return (uint256(parent_slot), key);
    }

    function root(StdStorage storage self) internal returns (uint256) {
        address who = self._target;
        uint256 field_depth = self._depth;
        vm.startMappingRecording();
        uint256 child = find(self) - field_depth;
        bool found;
        bytes32 root_slot;
        bytes32 parent_slot;
        (found,, parent_slot) = vm.getMappingKeyAndParentOf(who, bytes32(child));
        if (!found) {
            revert(
                "stdStorage read_bool(StdStorage): Cannot find parent. Make sure you give a slot and startMappingRecording() has been called."
            );
        }
        while (found) {
            root_slot = parent_slot;
            (found,, parent_slot) = vm.getMappingKeyAndParentOf(who, bytes32(root_slot));
        }
        return uint256(root_slot);
    }

    function bytesToBytes32(bytes memory b, uint256 offset) private pure returns (bytes32) {
        bytes32 out;

        uint256 max = b.length > 32 ? 32 : b.length;
        for (uint256 i = 0; i < max; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function flatten(bytes32[] memory b) private pure returns (bytes memory) {
        bytes memory result = new bytes(b.length * 32);
        for (uint256 i = 0; i < b.length; i++) {
            bytes32 k = b[i];
            /// @solidity memory-safe-assembly
            assembly {
                mstore(add(result, add(32, mul(32, i))), k)
            }
        }

        return result;
    }
}

library stdStorage {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function sigs(string memory sigStr) internal pure returns (bytes4) {
        return stdStorageSafe.sigs(sigStr);
    }

    function find(StdStorage storage self) internal returns (uint256) {
        return stdStorageSafe.find(self);
    }

    function target(StdStorage storage self, address _target) internal returns (StdStorage storage) {
        return stdStorageSafe.target(self, _target);
    }

    function sig(StdStorage storage self, bytes4 _sig) internal returns (StdStorage storage) {
        return stdStorageSafe.sig(self, _sig);
    }

    function sig(StdStorage storage self, string memory _sig) internal returns (StdStorage storage) {
        return stdStorageSafe.sig(self, _sig);
    }

    function with_key(StdStorage storage self, address who) internal returns (StdStorage storage) {
        return stdStorageSafe.with_key(self, who);
    }

    function with_key(StdStorage storage self, uint256 amt) internal returns (StdStorage storage) {
        return stdStorageSafe.with_key(self, amt);
    }

    function with_key(StdStorage storage self, bytes32 key) internal returns (StdStorage storage) {
        return stdStorageSafe.with_key(self, key);
    }

    function depth(StdStorage storage self, uint256 _depth) internal returns (StdStorage storage) {
        return stdStorageSafe.depth(self, _depth);
    }

    function checked_write(StdStorage storage self, address who) internal {
        checked_write(self, bytes32(uint256(uint160(who))));
    }

    function checked_write(StdStorage storage self, uint256 amt) internal {
        checked_write(self, bytes32(amt));
    }

    function checked_write_int(StdStorage storage self, int256 val) internal {
        checked_write(self, bytes32(uint256(val)));
    }

    function checked_write(StdStorage storage self, bool write) internal {
        bytes32 t;
        /// @solidity memory-safe-assembly
        assembly {
            t := write
        }
        checked_write(self, t);
    }

    function checked_write(StdStorage storage self, bytes32 set) internal {
        address who = self._target;
        bytes4 fsig = self._sig;
        uint256 field_depth = self._depth;
        bytes32[] memory ins = self._keys;

        bytes memory cald = abi.encodePacked(fsig, flatten(ins));
        if (!self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))]) {
            find(self);
        }
        bytes32 slot = bytes32(self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))]);

        bytes32 fdat;
        {
            (, bytes memory rdat) = who.staticcall(cald);
            fdat = bytesToBytes32(rdat, 32 * field_depth);
        }
        bytes32 curr = vm.load(who, slot);

        if (fdat != curr) {
            require(
                false,
                "stdStorage find(StdStorage): Packed slot. This would cause dangerous overwriting and currently isn't supported."
            );
        }
        vm.store(who, slot, set);
        delete self._target;
        delete self._sig;
        delete self._keys;
        delete self._depth;
    }

    function read_bytes32(StdStorage storage self) internal returns (bytes32) {
        return stdStorageSafe.read_bytes32(self);
    }

    function read_bool(StdStorage storage self) internal returns (bool) {
        return stdStorageSafe.read_bool(self);
    }

    function read_address(StdStorage storage self) internal returns (address) {
        return stdStorageSafe.read_address(self);
    }

    function read_uint(StdStorage storage self) internal returns (uint256) {
        return stdStorageSafe.read_uint(self);
    }

    function read_int(StdStorage storage self) internal returns (int256) {
        return stdStorageSafe.read_int(self);
    }

    function parent(StdStorage storage self) internal returns (uint256, bytes32) {
        return stdStorageSafe.parent(self);
    }

    function root(StdStorage storage self) internal returns (uint256) {
        return stdStorageSafe.root(self);
    }

    // Private function so needs to be copied over
    function bytesToBytes32(bytes memory b, uint256 offset) private pure returns (bytes32) {
        bytes32 out;

        uint256 max = b.length > 32 ? 32 : b.length;
        for (uint256 i = 0; i < max; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    // Private function so needs to be copied over
    function flatten(bytes32[] memory b) private pure returns (bytes memory) {
        bytes memory result = new bytes(b.length * 32);
        for (uint256 i = 0; i < b.length; i++) {
            bytes32 k = b[i];
            /// @solidity memory-safe-assembly
            assembly {
                mstore(add(result, add(32, mul(32, i))), k)
            }
        }

        return result;
    }
}