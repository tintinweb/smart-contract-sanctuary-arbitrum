// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1
// OpenZeppelin Contracts (last updated v4.8.0) (vendor/arbitrum/IArbSys.sol)

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface IArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

    /**
     * @notice Gets the rollup's unique chain identifier
     * @return Chain identifier as int
     */
    function arbChainID() external view returns (uint256);

    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external view returns (uint256);

    /**
     * @notice Returns 0 since Nitro has no concept of storage gas
     * @return uint 0
     */
    function getStorageGasAvailable() external view returns (uint256);

    /**
     * @notice (deprecated) check if current call is top level (meaning it was triggered by an EoA or a L1 contract)
     * @dev this call has been deprecated and may be removed in a future release
     * @return true if current execution frame is not a call by another L2 contract
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param unused argument no longer used
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address unused) external pure returns (address);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination) external payable returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
     * to a contract address without any code (as enforced by the Bridge contract).
     * @param destination recipient address on L1
     * @param data (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata data) external payable returns (uint256);

    /**
     * @notice Get send Merkle tree state
     * @return size number of sends in the history
     * @return root root hash of the send history
     * @return partials hashes of partial subtrees in the send history tree
     */
    function sendMerkleTreeState()
        external
        view
        returns (
            uint256 size,
            bytes32 root,
            bytes32[] memory partials
        );

    /**
     * @notice creates a send txn from L2 to L1
     * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
     */
    event L2ToL1Tx(
        address caller,
        address indexed destination,
        uint256 indexed hash,
        uint256 indexed position,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /// @dev DEPRECATED in favour of the new L2ToL1Tx event above after the nitro upgrade
    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /**
     * @notice logs a merkle branch for proof synthesis
     * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
     * @param hash the merkle hash
     * @param position = (level << 192) + leaf
     */
    event SendMerkleUpdate(uint256 indexed reserved, bytes32 indexed hash, uint256 indexed position);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IArbSys } from "@openzeppelin/contracts/vendor/arbitrum/IArbSys.sol";

interface IPool {
    function payout(uint256 rewardAmount) external;
}

contract ArbDice {
    using SafeERC20 for IERC20;
    /// *** Constants section

    // Each bet is deducted [houseEdgePermille]‰ in favour of the house, but no less than some minimum.
    // The lower bound is dictated by gas costs of the settleBet transaction, providing headroom for up to 10 Gwei prices.
    uint public houseEdgePermille; // Per-mille = per-thousand
    uint public houseEdgeMinimumAmount;

    // Bets lower than this amount do not participate in jackpot rolls (and are not deducted jackpotFee).
    uint public minJackpotBet;
    uint public jackpotFee;
    uint public exeuteFee;

    // There is minimum and maximum bets.
    uint public minBet;
    uint public maxBet;

    // Max bet profit. Used to cap bets against dynamic odds.
    uint public maxProfit;

    // Chance to win jackpot (currently 0.1%) and fee deducted into jackpot fund.
    uint constant JACKPOT_MODULO = 1000;

    // Modulo is a number of equiprobable outcomes in a game:
    //  - 2 for coin flip
    //  - 6 for dice
    //  - 6*6 = 36 for double dices
    //  - 37 for roulette
    //  - 100 for arbrain
    //  - 200 for arbroll
    //  - 1000 for arblotto
    //  etc.
    // It's called so because 256-bit entropy is treated like a huge integer and
    // the remainder of its division by modulo is considered bet outcome.
    uint constant MAX_MODULO = 65535;

    uint16 constant ARBROLL_MODULO = 200;
    uint16 constant ARBLOTTO_3D_MODULO = 1000;
    uint16 constant ARBLOTTO_4D_MODULO = 10000;

    // For modulos below this threshold rolls are checked against a bit mask,
    // thus allowing betting on any combination of outcomes. For example, given
    // modulo 6 for dice, 101000 mask (base-2, big endian) means betting on
    // 4 and 6; for games with modulos higher than threshold (Arbroll), a simple
    // limit is used, allowing betting on any outcome in [0, N) range.
    //
    // The specific value is dictated by the fact that 256-bit intermediate
    // multiplication result allows implementing population count efficiently
    // for numbers that are up to 42 bits, and 40 is the highest multiple of
    // eight below 42.
    uint256 constant MAX_MASK_SMALL_MODULO = 40;

    // This is a check on bet mask overflow.
    uint256 constant MAX_BET_MASK_SMALL_MODULO = 2 ** MAX_MASK_SMALL_MODULO;

    // bigger modulo, use normal bit count algorithm (slower).
    uint256 constant MAX_MASK_BIG_MODULO = 249;
    uint256 constant MAX_BET_MASK_BIG_MODULO = 2 ** MAX_MASK_BIG_MODULO;

    // EVM BLOCKHASH opcode can query no further than 256 blocks into the
    // past. Given that settleBet uses block hash of placeBet as one of
    // complementary entropy sources, we cannot process bets older than this
    // threshold. On rare occasions arbdice's croupier may fail to invoke
    // settleBet in this timespan due to technical issues or extreme Arbchain
    // congestion; such bets can be refunded via invoking refundBet.

    uint public BET_EXPIRATION_BLOCKS = 60;

    // Standard contract ownership transfer.
    address payable public owner;
    address payable private nextOwner;

    // The address corresponding to a private key used to sign placeBet commits.
    address public secretSigner;

    // Accumulated jackpot fund.
    uint128 public jackpotSize;

    // Funds that are locked in potentially winning bets. Prevents contract from
    // committing to bets it cannot pay out.
    uint128 public lockedInBets;

    // A structure representing a single bet.
    struct Bet {
        // Wager amount in wei.
        uint amount;
        // Modulo of a game.
        uint16 modulo;
        // Number of winning outcomes, used to compute winning payment (* modulo/rollUnder),
        // and used instead of mask for games with modulo > MAX_MASK_BIG_MODULO.
        uint16 rollUnder;
        // Block number of placeBet tx.
        uint40 placeBlockNumber;
        // Bit mask representing winning bet outcomes (see MAX_MASK_SMALL_MODULO comment).
        uint256 mask;
        // Address of a gambler, used to pay out winning bets.
        address payable gambler;
    }

    // Mapping from commits to all currently active & processed bets.
    mapping(uint => Bet) public bets;

    // Mapping from wallet address to its.
    mapping(address => address payable) public affiliates;

    // Commissions for referrer (5 levels) - in percent from house edge fee collected.
    uint8[] public referCommissionPrecents = [4, 2, 2, 1, 1];

    // Lotto prize structures (3-digits and 4-digits).
    uint[] public lottoPrize3D = [0, 14, 160, 1000]; // 0x, 1.4x, 16x, 100x
    uint[] public lottoPrize4D = [0, 15, 40, 400, 10000]; // 0x, 1.5x, 4x, 40x, 1000x

    address public collateralToken;
    IPool public pool;
    // Croupier account.
    mapping(address => bool) public croupiers;
    address[] public feeWallet;
    uint256[] public feePercent;

    // Events that are issued to make statistic recovery easier.
    event FailedPayment(uint indexed commit, address indexed beneficiary, uint amount);
    event Payment(uint indexed commit, address indexed beneficiary, uint amount);
    event JackpotPayment(uint indexed commit, address indexed beneficiary, uint amount);
    event AffiliatePayment(uint8 level, address indexed referrer, address indexed gambler, uint houseEdge, uint commission);
    event FailedAffiliatePayment(uint8 level, address indexed referrer, address indexed gambler, uint houseEdge, uint commission);
    event FeeWalletUpdate(address[], uint256[]);
    event SentFee(address, uint256);
    event ExeuteFeeUpdate(uint256);

    // These events are emitted in placeBet to record commit & affiliate in the logs.
    event Commit(uint commit);
    event Affiliate(address indexed referrer, address indexed gambler);

    constructor(
        address _pool,
        address _collateralToken,
        uint _houseEdgePermille,
        uint _houseEdgeMinimumAmount,
        uint _minJackpotBet,
        uint _jackpotFee,
        uint _minBet,
        uint _maxBet,
        uint _maxProfit
    ) {
        owner = payable(msg.sender);
        setHouseEdgeSettings(_houseEdgePermille, _houseEdgeMinimumAmount);
        minJackpotBet = _minJackpotBet;
        jackpotFee = _jackpotFee;
        setBetAmountSettings(_minBet, _maxBet);
        setMaxProfit(_maxProfit);
        exeuteFee = 0.0003 ether;
        pool = IPool(_pool);
        collateralToken = _collateralToken;
    }

    // Standard modifier on methods invokable only by contract owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }

    // Standard modifier on methods invokable only by contract owner.
    modifier onlyCroupier() {
        require(croupiers[msg.sender], "OnlyCroupier methods called by non-croupier.");
        _;
    }

    // Standard contract ownership transfer implementation,
    function approveNextOwner(address payable _nextOwner) external onlyOwner {
        require(_nextOwner != owner, "Cannot approve current owner.");
        nextOwner = _nextOwner;
    }

    function acceptNextOwner() external {
        require(msg.sender == nextOwner, "Can only accept preapproved new owner.");
        owner = nextOwner;
    }

    // Fallback function deliberately left empty. It's primary use case
    // is to top up the bank roll.
    receive() external payable {}

    // See comment for "secretSigner" variable.
    function setSecretSigner(address newSecretSigner) external onlyOwner {
        secretSigner = newSecretSigner;
    }

    function setBetExprirationBlock(uint256 _numberBlock) external onlyOwner {
        BET_EXPIRATION_BLOCKS = _numberBlock;
    }

    // Change the croupier address.
    function setCroupier(address _croupier, bool status) external onlyOwner {
        croupiers[_croupier] = status;
    }

    function setFeeWallet(address[] memory _wallet, uint256[] memory _percent) external onlyOwner {
        require(_wallet.length == _percent.length, "! length");
        uint256 total = 0;
        for (uint i = 0; i < _percent.length; i++) {
            total += _percent[i];
        }

        require(total == 10000, "Percent!");
        feeWallet = _wallet;
        feePercent = _percent;

        emit FeeWalletUpdate(_wallet, _percent);
    }

    // Change house edge settings
    function setHouseEdgeSettings(uint _houseEdgePermille, uint _houseEdgeMinimumAmount) public onlyOwner {
        require(_houseEdgePermille <= 100, "houseEdgePermille should not be over than 10%.");
        require(_houseEdgeMinimumAmount >= 0.001 ether, "houseEdgeMinimumAmount should be at least 0.001 Arb.");
        houseEdgePermille = _houseEdgePermille;
        houseEdgeMinimumAmount = _houseEdgeMinimumAmount;
    }

    // Change jackpot settings
    function setJackpotSettings(uint _minJackpotBet, uint _jackpotFee) public onlyOwner {
        require(_minJackpotBet >= 1 ether, "minJackpotBet should be at least 1.0 Arb.");
        require(_jackpotFee >= 0.01 ether, "jackpotFee should be at least 0.01 Arb.");
        minJackpotBet = _minJackpotBet;
        jackpotFee = _jackpotFee;
    }

    // Change bet amount settings
    function setBetAmountSettings(uint _minBet, uint _maxBet) public onlyOwner {
        require(_minBet >= 0.01 ether, "minBet should be at least 0.01 Arb.");
        require(_maxBet <= 100000 ether, "maxBet should be at most 100,000 Arb.");
        require(_minBet < _maxBet, "minBet should be less than maxBet.");
        minBet = _minBet;
        maxBet = _maxBet;
    }

    // Change max bet reward. Setting this to zero effectively disables betting.
    function setMaxProfit(uint _maxProfit) public onlyOwner {
        require(_maxProfit < maxBet * 10000, "maxProfit should be a sane number.");
        maxProfit = _maxProfit;
    }

    // Change refer commissions. Setting one level to zero will disable that level.
    function setReferCommissionPrecents(uint8[] memory _referCommissionPrecents) public onlyOwner {
        require(_referCommissionPrecents.length == 5, "referCommissionPrecents should have 5 elements");
        referCommissionPrecents = _referCommissionPrecents;
    }

    // This function is used to bump up the jackpot fund. Cannot be used to lower it.
    function increaseJackpot(uint increaseAmount) external onlyOwner {
        require(increaseAmount <= address(this).balance, "Increase amount larger than balance.");
        require(jackpotSize + lockedInBets + increaseAmount <= address(this).balance, "Not enough funds.");
        jackpotSize += uint128(increaseAmount);
    }

    // Funds withdrawal to cover costs of arbdice.com operation.
    function withdrawFunds(address payable beneficiary, uint withdrawAmount) external onlyOwner {
        require(withdrawAmount <= address(this).balance, "Increase amount larger than balance.");
        require(jackpotSize + lockedInBets + withdrawAmount <= address(this).balance, "Not enough funds.");
        sendFunds(beneficiary, withdrawAmount, withdrawAmount, 0, 0);
    }

    function exeuteFeeUpdate(uint _fee) external onlyOwner {
        exeuteFee = _fee;
        emit ExeuteFeeUpdate(_fee);
    }

    // Contract may be destroyed only when there are no ongoing bets,
    // either settled or refunded. All funds are transferred to contract owner.
    function kill() external onlyOwner {
        require(lockedInBets == 0, "All bets should be processed (settled or refunded) before self-destruct.");
        selfdestruct(owner);
    }

    /// *** Betting logic

    // Bet states:
    //  amount == 0 && gambler == 0 - 'clean' (can place a bet)
    //  amount != 0 && gambler != 0 - 'active' (can be settled or refunded)
    //  amount == 0 && gambler != 0 - 'processed' (can clean storage)
    //
    //  NOTE: Storage cleaning is not implemented in this contract version; it will be added
    //        with the next upgrade to prevent polluting Arbchain state with expired bets.

    // Bet placing transaction - issued by the player.
    //  betMask         - bet outcomes bit mask for modulo <= MAX_MASK_MODULO,
    //                    [0, betMask) for larger modulos.
    //  modulo          - game modulo.
    //  commitLastBlock - number of the maximum block where "commit" is still considered valid.
    //  commit          - Keccak256 hash of some secret "reveal" random number, to be supplied
    //                    by the arbdice.com croupier bot in the settleBet transaction. Supplying
    //                    "commit" ensures that "reveal" cannot be changed behind the scenes
    //                    after placeBet have been mined.
    //  r, s            - components of ECDSA signature of (commitLastBlock, commit). v is
    //                    guaranteed to always equal 27.
    //  affWallet       - wallet to receive commission if this sender is new
    // Commit, being essentially random 256-bit number, is used as a unique bet identifier in
    // the 'bets' mapping.
    //
    // Commits are signed with a block limit to ensure that they are used at most once - otherwise
    // it would be possible for a miner to place a bet with a known commit/reveal pair and tamper
    // with the blockhash. Croupier guarantees that commitLastBlock will always be not greater than
    // placeBet block number plus BET_EXPIRATION_BLOCKS. See whitepaper for details.
    struct VerifyData {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    function placeBet(
        uint256 betMask,
        uint16 modulo,
        uint commitLastBlock,
        uint commit,
        address payable affWallet,
        uint amount,
        VerifyData memory verifyData
    ) external payable {
        // Check that the bet is in 'clean' state.
        Bet storage bet = bets[commit];
        require(bet.gambler == address(0), "Bet should be in a 'clean' state.");

        // Validate input data ranges.
        // uint amount = msg.value;
        require(msg.value >= exeuteFee, "invalid Fee");
        require(modulo > 1 && modulo <= MAX_MODULO, "Modulo should be within range.");
        require(amount >= minBet && amount <= maxBet, "Amount should be within range.");

        // Check that commit is valid - it has not expired and its signature is valid.
        require(getBlockNumber() <= commitLastBlock, "Commit has expired.");
        bytes32 signatureHash = keccak256(abi.encodePacked(uint40(commitLastBlock), commit));

        require(
            secretSigner == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", signatureHash)), verifyData.v, verifyData.r, verifyData.s),
            "ECDSA signature is not valid."
        );

        uint rollUnder;
        uint mask;

        if (modulo == ARBROLL_MODULO || modulo > MAX_MASK_BIG_MODULO) {
            // or ARBLOTTO_3D or ARBLOTTO_4D
            // Larger modulos or specific games specify the right edge of half-open interval of winning bet outcomes.
            if (modulo == ARBLOTTO_3D_MODULO || modulo == ARBLOTTO_4D_MODULO) {
                require(betMask >= 0 && betMask < modulo, "High modulo range, betMask larger than modulo.");
            } else {
                require(betMask > 0 && betMask < modulo, "High modulo range, betMask larger than modulo.");
            }
            rollUnder = betMask;
        } else if (modulo <= MAX_MASK_SMALL_MODULO) {
            require(betMask > 0 && betMask < MAX_BET_MASK_SMALL_MODULO, "Mask should be within range.");
            // Small modulo games specify bet outcomes via bit mask.
            // rollUnder is a number of 1 bits in this mask (population count).
            // This magic looking formula is an efficient way to compute population
            // count on EVM for numbers below 2**40. For detailed proof consult
            // the arbdice.com whitepaper.
            rollUnder = ((betMask * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
            mask = betMask;
        } else if (modulo <= MAX_MASK_BIG_MODULO) {
            require(betMask > 0 && betMask < MAX_BET_MASK_BIG_MODULO, "Mask should be within range.");
            rollUnder = popcount64a(betMask);
            mask = betMask;
        }

        // Winning amount and jackpot increase.
        uint _possibleWinAmount;
        uint _jackpotFee;
        uint _houseEdge;

        (_possibleWinAmount, _jackpotFee, _houseEdge) = getDiceWinAmount(amount, modulo, rollUnder);

        // Enforce max profit limit.
        require(_possibleWinAmount <= amount + maxProfit, "maxProfit limit violation.");

        // Lock funds.
        lockedInBets += uint128(_possibleWinAmount);
        jackpotSize += uint128(_jackpotFee);

        // Check whether contract has enough funds to process this bet.
        require(jackpotSize + lockedInBets <= IERC20(collateralToken).balanceOf(address(pool)) + amount, "Cannot afford to lose this bet.");
        IERC20(collateralToken).transferFrom(msg.sender, address(this), amount);

        // Store bet parameters on blockchain.
        bet.amount = amount;
        bet.modulo = uint16(modulo);
        bet.rollUnder = uint16(rollUnder);
        bet.placeBlockNumber = uint40(getBlockNumber());
        bet.mask = uint256(mask);
        bet.gambler = payable(msg.sender);

        // Record commit in logs.
        emit Commit(commit);

        if (affiliates[msg.sender] == address(0)) {
            if (affWallet != address(0)) {
                affiliates[msg.sender] = affWallet;
                emit Affiliate(affWallet, msg.sender);
            } else {
                affiliates[msg.sender] = owner;
                emit Affiliate(owner, msg.sender);
            }
        }
    }

    // This is the method used to settle 99% of bets. To process a bet with a specific
    // "commit", settleBet should supply a "reveal" number that would Keccak256-hash to
    // "commit". "blockHash" is the block hash of placeBet block as seen by croupier; it
    // is additionally asserted to prevent changing the bet outcomes on Arbchain reorgs.
    function settleBet(uint reveal, bytes32 blockHash) external onlyCroupier {
        uint commit = uint(keccak256(abi.encodePacked(reveal)));

        Bet storage bet = bets[commit];
        uint placeBlockNumber = bet.placeBlockNumber;

        // Check that bet has not expired yet (see comment to BET_EXPIRATION_BLOCKS).
        require(getBlockNumber() >= placeBlockNumber, "settleBet in the same block as placeBet, or before.");
        require(getBlockNumber() <= placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");
        require(keccak256(abi.encodePacked(placeBlockNumber)) == blockHash, "placeBlockNumber");

        // Settle bet using reveal and blockHash as entropy sources.
        settleBetCommon(bet, reveal, blockHash);
    }

    // This is the method used to settle 1% of bets left with passed blockHash seen by croupier
    // It needs player to trust croupier and can only be executed after between [BET_EXPIRATION_BLOCKS, 10*BET_EXPIRATION_BLOCKS]
    function settleBetLate(uint reveal, bytes32 blockHash) external onlyCroupier {
        uint commit = uint(keccak256(abi.encodePacked(reveal)));

        Bet storage bet = bets[commit];
        uint placeBlockNumber = bet.placeBlockNumber;

        require(getBlockNumber() >= placeBlockNumber + BET_EXPIRATION_BLOCKS, "block.number needs to be after BET_EXPIRATION_BLOCKS");
        require(getBlockNumber() <= placeBlockNumber + 50 * BET_EXPIRATION_BLOCKS, "block.number needs to be before 50*BET_EXPIRATION_BLOCKS");

        // Settle bet using reveal and blockHash as entropy sources.
        settleBetCommon(bet, reveal, blockHash);
    }

    // Common settlement code for settleBet.
    function settleBetCommon(Bet storage bet, uint reveal, bytes32 entropyBlockHash) private {
        // Fetch bet parameters into local variables (to save gas).
        uint amount = bet.amount;
        uint modulo = bet.modulo;
        uint rollUnder = bet.rollUnder;
        address payable gambler = bet.gambler;

        // Check that bet is in 'active' state.
        require(amount != 0, "Bet should be in an 'active' state");

        // Move bet into 'processed' state already.
        bet.amount = 0;

        // The RNG - combine "reveal" and blockhash of placeBet using Keccak256. Miners
        // are not aware of "reveal" and cannot deduce it from "commit" (as Keccak256
        // preimage is intractable), and house is unable to alter the "reveal" after
        // placeBet have been mined (as Keccak256 collision finding is also intractable).
        bytes32 entropy = keccak256(abi.encodePacked(reveal, entropyBlockHash));

        // Do a roll by taking a modulo of entropy. Compute winning amount.
        uint256 dice = uint256(entropy) % modulo;

        uint diceWinAmount;
        uint _jackpotFee;
        uint _houseEdge;

        (diceWinAmount, _jackpotFee, _houseEdge) = getDiceWinAmount(amount, modulo, rollUnder);

        uint diceWin = 0;

        // Determine dice outcome.
        if (modulo == ARBLOTTO_3D_MODULO || modulo == ARBLOTTO_4D_MODULO) {
            diceWin = getLottoWinAmount(modulo, rollUnder, dice, amount - _houseEdge - _jackpotFee);
        } else if (modulo == ARBROLL_MODULO || modulo > MAX_MASK_BIG_MODULO) {
            // For larger modulos or arbroll, check inclusion into half-open interval.
            if (dice < rollUnder) {
                diceWin = diceWinAmount;
            }
        } else if (modulo <= MAX_MASK_BIG_MODULO) {
            // For small modulo games, check the outcome against a bit mask.
            if ((uint256(2) ** dice) & bet.mask != 0) {
                diceWin = diceWinAmount;
            }
        }

        uint jackpotWin = 0;

        // Unlock the bet amount, regardless of the outcome.
        lockedInBets -= uint128(diceWinAmount);

        // Roll for a jackpot (if eligible).
        if (amount >= minJackpotBet) {
            // The second modulo, statistically independent from the "main" dice roll.
            // Effectively you are playing two games at once!
            uint jackpotRng = (uint(entropy) / modulo) % JACKPOT_MODULO;

            // Bingo!
            if (jackpotRng == 0) {
                jackpotWin = jackpotSize;
                jackpotSize = 0;
            }
        }

        // Log jackpot win.
        uint commit = uint(keccak256(abi.encodePacked(reveal)));
        if (jackpotWin > 0) {
            emit JackpotPayment(commit, gambler, jackpotWin);
        }

        // Send the funds to gambler.
        uint sentAmount = diceWin + jackpotWin == 0 ? 1 wei : diceWin + jackpotWin;

        if (sentAmount > amount) {
            pool.payout(sentAmount - amount);
        } else {
            uint surplus = amount - sentAmount;
            if (surplus > 0) IERC20(collateralToken).transfer(address(pool), surplus);
        }

        if (_houseEdge > 0) pool.payout(_houseEdge);

        sendFunds(gambler, sentAmount, diceWin, _houseEdge, commit);

        if (address(this).balance >= exeuteFee) payable(msg.sender).transfer(exeuteFee);
    }

    // Refund transaction - return the bet amount of a roll that was not processed in a
    // due timeframe. Processing such blocks is not possible due to EVM limitations (see
    // BET_EXPIRATION_BLOCKS comment above for details). In case you ever find yourself
    // in a situation like this, just contact the arbdice.com support, however nothing
    // precludes you from invoking this method yourself.
    function refundBet(uint commit) external {
        // Check that bet is in 'active' state.
        Bet storage bet = bets[commit];
        uint amount = bet.amount;

        require(amount != 0, "Bet should be in an 'active' state");

        // Check that bet has already expired long ago.
        require(getBlockNumber() > bet.placeBlockNumber + 20 * BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");

        // Move bet into 'processed' state, release funds.
        bet.amount = 0;

        uint _diceWinAmount;
        uint _jackpotFee;
        uint _houseEdge;

        (_diceWinAmount, _jackpotFee, _houseEdge) = getDiceWinAmount(amount, bet.modulo, bet.rollUnder);

        lockedInBets -= uint128(_diceWinAmount);
        jackpotSize -= uint128(_jackpotFee);

        // Send the refund.
        sendFunds(bet.gambler, amount, amount, 0, commit);
    }

    // Get the expected win amount after house edge is subtracted.
    function getDiceWinAmount(uint amount, uint modulo, uint rollUnder) private view returns (uint winAmount, uint _jackpotFee, uint _houseEdge) {
        require(0 <= rollUnder && rollUnder <= modulo, "Win probability out of range.");

        _jackpotFee = (amount >= minJackpotBet) ? jackpotFee : 0;

        _houseEdge = (amount * houseEdgePermille) / 1000;

        if (_houseEdge < houseEdgeMinimumAmount) {
            _houseEdge = houseEdgeMinimumAmount;
        }

        require(_houseEdge + _jackpotFee <= amount, "Bet doesn't even cover house edge.");
        if (modulo == ARBLOTTO_3D_MODULO) {
            winAmount = ((amount - _houseEdge - _jackpotFee) * lottoPrize3D[3]) / 10;
        } else if (modulo == ARBLOTTO_4D_MODULO) {
            winAmount = ((amount - _houseEdge - _jackpotFee) * lottoPrize4D[4]) / 10;
        } else {
            winAmount = ((amount - _houseEdge - _jackpotFee) * modulo) / rollUnder;
        }
    }

    // get lotto win
    function getLottoWinAmount(uint modulo, uint rollUnder, uint dice, uint betAmount) private view returns (uint winAmount) {
        require(modulo == ARBLOTTO_3D_MODULO || modulo == ARBLOTTO_4D_MODULO, "Calculate lotto win amount only.");

        uint8 digitMatch = 0;
        if (rollUnder % 10 == dice % 10) ++digitMatch;
        if ((rollUnder % 100) / 10 == (dice % 100) / 10) ++digitMatch;
        if ((rollUnder % 1000) / 100 == (dice % 1000) / 100) ++digitMatch;
        if (modulo == ARBLOTTO_3D_MODULO) {
            winAmount = (betAmount * lottoPrize3D[digitMatch]) / 10;
        } else {
            if (rollUnder / 1000 == dice / 1000) ++digitMatch;
            winAmount = (betAmount * lottoPrize4D[digitMatch]) / 10;
        }
        return winAmount;
    }

    // Helper routine to process the payment.
    function sendFunds(address payable beneficiary, uint amount, uint successLogAmount, uint houseEdge, uint commit) private {
        try IERC20(collateralToken).transfer(beneficiary, amount) {
            emit Payment(commit, beneficiary, successLogAmount);
        } catch {
            emit FailedPayment(commit, beneficiary, amount);
        }

        uint256 transferReward = 0;

        // Send affiliate commissions
        address prevBeneficiary2 = address(0);
        address prevBeneficiary = address(0);
        if (houseEdge != 0) {
            for (uint8 level = 1; level <= 5; level++) {
                address payable referrer = affiliates[beneficiary];
                if (referrer == address(0) || referrer == beneficiary || referrer == prevBeneficiary || referrer == prevBeneficiary2) {
                    break;
                }
                uint commission = (houseEdge * referCommissionPrecents[level - 1]) / 100;
                if (commission == 0) {
                    break;
                }

                try IERC20(collateralToken).transfer(referrer, commission) {
                    transferReward += commission;
                    emit AffiliatePayment(level, referrer, beneficiary, houseEdge, commission);
                } catch {
                    emit FailedAffiliatePayment(level, referrer, beneficiary, houseEdge, commission);
                }

                prevBeneficiary2 = prevBeneficiary;
                prevBeneficiary = beneficiary;
                beneficiary = referrer;
            }
            uint256 fee = houseEdge - transferReward;
            if (fee > 0) {
                for (uint i = 0; i < feeWallet.length; i++) {
                    uint256 transferAmount = (fee * feePercent[i]) / 10000;
                    IERC20(collateralToken).transfer(feeWallet[i], transferAmount);
                    emit SentFee(feeWallet[i], transferAmount);
                }
            }
        }
    }

    event EmergencyERC20Drain(address token, address owner, uint256 amount);

    // owner can drain tokens that are sent here by mistake
    function emergencyERC20Drain(IERC20 token, uint amount) external onlyOwner {
        emit EmergencyERC20Drain(address(token), owner, amount);
        token.transfer(owner, amount);
    }

    // This are some constants making O(1) population count in placeBet possible.
    // See whitepaper for intuition and proofs behind it.
    uint constant POPCNT_MULT = 0x0000000000002000000000100000000008000000000400000000020000000001;
    uint constant POPCNT_MASK = 0x0001041041041041041041041041041041041041041041041041041041041041;
    uint constant POPCNT_MODULO = 0x3F;

    // uint64_t is an unsigned 64-bit integer variable type (defined in C99 version of C language)
    uint256 constant m1 = 0x5555555555555555555555555555555555555555555555555555555555555555;
    //binary: 0101...
    uint256 constant m2 = 0x3333333333333333333333333333333333333333333333333333333333333333;
    //binary: 00110011..
    uint256 constant m4 = 0x0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f;
    //binary:  4 zeros,  4 ones ...
    uint256 constant m8 = 0x00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff;
    //binary:  8 zeros,  8 ones ...
    uint256 constant m16 = 0x0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff;
    //binary: 16 zeros, 16 ones ...
    uint256 constant m32 = 0x00000000ffffffff00000000ffffffff00000000ffffffff00000000ffffffff;
    //binary: 32 zeros, 32 ones
    uint256 constant m64 = 0x0000000000000000ffffffffffffffff0000000000000000ffffffffffffffff;
    uint256 constant m128 = 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;

    // This is a naive implementation, shown for comparison,
    // and to help in understanding the better functions.
    // This algorithm uses 24 arithmetic operations (shift, add, and)
    function popcount64a(uint256 x) public pure returns (uint256) {
        x = (x & m1) + ((x >> 1) & m1);
        x = (x & m2) + ((x >> 2) & m2);
        x = (x & m4) + ((x >> 4) & m4);
        x = (x & m8) + ((x >> 8) & m8);
        x = (x & m16) + ((x >> 16) & m16);
        x = (x & m32) + ((x >> 32) & m32);
        x = (x & m64) + ((x >> 64) & m64);
        x = (x & m128) + ((x >> 128) & m128);
        return x;
    }

    function getBlockNumber() public view returns (uint) {
        return IArbSys(address(100)).arbBlockNumber();
    }
}