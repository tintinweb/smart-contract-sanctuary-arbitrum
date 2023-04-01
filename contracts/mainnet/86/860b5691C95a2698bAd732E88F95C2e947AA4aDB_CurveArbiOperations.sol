/**
 *Submitted for verification at Arbiscan on 2023-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// ███████╗░█████╗░██████╗░████████╗██████╗░███████╗░██████╗░██████╗
// ██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔════╝██╔════╝██╔════╝
// █████╗░░██║░░██║██████╔╝░░░██║░░░██████╔╝█████╗░░╚█████╗░╚█████╗░
// ██╔══╝░░██║░░██║██╔══██╗░░░██║░░░██╔══██╗██╔══╝░░░╚═══██╗░╚═══██╗
// ██║░░░░░╚█████╔╝██║░░██║░░░██║░░░██║░░██║███████╗██████╔╝██████╔╝
// ╚═╝░░░░░░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═════╝░╚═════╝░
// ███████╗██╗███╗░░██╗░█████╗░███╗░░██╗░█████╗░███████╗
// ██╔════╝██║████╗░██║██╔══██╗████╗░██║██╔══██╗██╔════╝
// █████╗░░██║██╔██╗██║███████║██╔██╗██║██║░░╚═╝█████╗░░
// ██╔══╝░░██║██║╚████║██╔══██║██║╚████║██║░░██╗██╔══╝░░
// ██║░░░░░██║██║░╚███║██║░░██║██║░╚███║╚█████╔╝███████╗
// ╚═╝░░░░░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝╚═╝░░╚══╝░╚════╝░╚══════╝

//  _____                 _____     _   _ _____                 _   _             
// |     |_ _ ___ _ _ ___|  _  |___| |_|_|     |___ ___ ___ ___| |_|_|___ ___ ___ 
// |   --| | |  _| | | -_|     |  _| . | |  |  | . | -_|  _| .'|  _| | . |   |_ -|
// |_____|___|_|  \_/|___|__|__|_| |___|_|_____|  _|___|_| |__,|_| |_|___|_|_|___|
//                                             |_|                                

// Github - https://github.com/FortressFinance


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)



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


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)





// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)



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


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)



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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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






interface ICurvePool {

  function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external payable returns (uint256);

  function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external payable returns (uint256);
  
  function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount) external returns (uint256);
  
  function coins(uint256 index) external view returns (address);
}



// https://curve.fi/tricrypto2 - ETH is wETH

interface ICurve3Pool {
  
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external payable;
    
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external payable;
    
    function remove_liquidity_one_coin(uint256 token_amount, uint256 i, uint256 min_amount) external payable;

    function coins(uint256 index) external view returns (address);
}



// https://curve.fi/susdv2

interface ICurvesUSD4Pool {
  
    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount) external;
    
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
    
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_uamount) external;

    function coins(int128 arg0) external view returns (address);
}



// (Curve Crypto V1 Pools)

// https://curve.fi/reth
// https://curve.fi/ankreth
// https://curve.fi/steth
// https://curve.fi/seth
// https://curve.fi/factory/155 - fraxETH
// https://curve.fi/factory/38 - alETH
// https://curve.fi/factory/194 - pETH
// https://curve.fi/#/ethereum/pools/frxeth - frxETH

interface ICurveETHPool {

    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external payable returns (uint256);

    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external payable returns (uint256);
    
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount) external returns (uint256);

    function coins(uint256 index) external view returns (address);
}



// https://curve.fi/cvxeth
// https://curve.fi/crveth
// https://curve.fi/spelleth
// https://curve.fi/factory-crypto/3 - FXS/ETH
// https://curve.fi/factory-crypto/8 - YFI/ETH
// https://curve.fi/factory-crypto/85 - BTRFLY/ETH
// https://curve.fi/factory-crypto/39 - KP3R/ETH
// https://curve.fi/factory-crypto/43 - JPEG/ETH
// https://curve.fi/factory-crypto/55 - TOKE/ETH
// https://curve.fi/factory-crypto/21 - OHM/ETH

interface ICurveCryptoETHV2Pool {

    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount, bool use_eth) external payable returns (uint256);

    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy, bool use_eth) external payable returns (uint256);

    function remove_liquidity_one_coin(uint256 _token_amount, uint256 i, uint256 _min_amount, bool use_eth) external returns (uint256);

    function coins(uint256 index) external view returns (address);
}



// https://curve.fi/frax
// https://curve.fi/tusd
// https://curve.fi/lusd
// https://curve.fi/gusd
// https://curve.fi/mim
// https://curve.fi/factory/113 - pUSD
// https://curve.fi/alusd

interface ICurveCRVMeta {
  
  function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external returns (uint256);

  function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount) external returns (uint256);

  function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);

  // function remove_liquidity(uint256 _burn_amount, uint256[2] memory _min_amounts) external returns (uint256[2]);

  function coins(uint256 index) external view returns (address);
}



// https://curve.fi/factory/144 - tUSD/FRAXBP
// https://curve.fi/factory/147 - alUSD/FRAXBP
// https://curve.fi/factory/137 - LUSD/FRAXBP

interface ICurveFraxMeta {

  function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external returns (uint256);

  function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount) external returns (uint256);

  function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);

  function coins(uint256 index) external view returns (address);
}



// https://curve.fi/3pool
// https://curve.fi/ib

interface ICurveBase3Pool {
  
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;
    
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;

    function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount) external;

    function coins(uint256 index) external view returns (address);
}



// https://curve.fi/factory-crypto/95 - CVX/crvFRAX
// https://curve.fi/factory-crypto/94 - cvxFXS/crvFRAX
// https://curve.fi/factory-crypto/96 - ALCX/crvFRAX
// https://curve.fi/factory-crypto/97 - cvxCRV/crvFRAX

interface ICurveFraxCryptoMeta {

  function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external returns (uint256);

  function remove_liquidity_one_coin(uint256 token_amount, uint256 i, uint256 min_amount) external returns (uint256);

  function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external returns (uint256);

  function coins(uint256 index) external view returns (address);
}



// https://curve.fi/factory-crypto/37 - USDC/STG
// https://curve.fi/factory-crypto/23 - USDC/FIDU
// https://curve.fi/factory-crypto/4 - wBTC/BADGER
// https://curve.fi/factory-crypto/18 - cvxFXS/FXS
// https://curve.fi/factory-crypto/62 - pxCVX/CVX
// https://curve.fi/factory-crypto/22 - SILO/FRAX
// https://curve.fi/factory-crypto/48 - FRAX/FPI
// https://curve.fi/factory-crypto/90 - FXS/FPIS

interface ICurveCryptoV2Pool {

    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external payable returns (uint256);

    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external payable returns (uint256);
    
    function remove_liquidity_one_coin(uint256 _token_amount, uint256 i, uint256 _min_amount) external returns (uint256);

    function coins(uint256 index) external view returns (address);
}



interface ICurveMetaRegistry {
    
    function get_lp_token(address _pool) external view returns (address);

    function get_pool_from_lp_token(address _token) external view returns (address);
}



interface IWETH {
  function deposit() external payable;

  function withdraw(uint256 wad) external;
}

contract CurveArbiOperations {

    using SafeERC20 for IERC20;
    using Address for address payable;

    /// @notice The address of Curve MetaRegistry
    ICurveMetaRegistry internal immutable metaRegistry = ICurveMetaRegistry(0x445FE580eF8d70FF569aB36e80c647af338db351);

    /// @notice The address of the owner
    address public owner;
    
    /// @notice The address of WETH token (Arbitrum)
    address internal constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    /// @notice The address representing ETH in Curve V1
    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @notice The address of CRV_3_CRYPTO LP token (Curve BP Arbitrum)
    // address internal constant CRV_3_CRYPTO = 0x8e0B8c8BB9db49a46697F3a5Bb8A308e744821D2
     /// @notice The address of Curve Base Pool (https://curve.fi/3pool)
    address internal constant CURVE_BP = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    /// @notice The address of Curve's Frax Base Pool (https://curve.fi/fraxusdc)
    address internal constant FRAX_BP = 0xDcEF968d416a41Cdac0ED8702fAC8128A64241A2;
    /// @notice The address of crvFRAX LP token (Frax BP)
    address internal constant CRV_FRAX = 0x3175Df0976dFA876431C2E9eE6Bc45b65d3473CC;
    /// @notice The address of 3CRV LP token (Curve BP)
    address internal constant TRI_CRV = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

    /// @notice The mapping of whitelisted addresses, which are Fortress Vaults
    mapping(address => bool) public whitelist;

    /********************************** Constructor **********************************/

    constructor(address _owner) {
        owner = _owner;
    }

    /********************************** View Functions **********************************/

    function getPoolFromLpToken(address _lpToken) public view returns (address _pool) {
        return metaRegistry.get_pool_from_lp_token(_lpToken);
    }

    function getLpTokenFromPool(address _pool) public view returns (address _lpToken) {
        return metaRegistry.get_lp_token(_pool);
    }


    /********************************** Restricted Functions **********************************/

    // The type of the pool:
    // 0 - 3Pool
    // 1 - PlainPool
    // 2 - CryptoV2Pool
    // 3 - CrvMetaPool
    // 4 - FraxMetaPool
    // 5 - ETHPool
    // 6 - ETHV2Pool
    // 7 - Base3Pool
    // 8 - FraxCryptoMetaPool
    // 9 - sUSD 4Pool
    function addLiquidity(address _poolAddress, uint256 _poolType, address _token, uint256 _amount) external payable returns (uint256 _assets) {
        if (!whitelist[msg.sender]) revert Unauthorized();

        address _lpToken = getLpTokenFromPool(_poolAddress);
        
        if (msg.value > 0) {
            if (_token != ETH) revert InvalidAsset();
            if (_amount > address(this).balance) revert InvalidAmount();
        } else {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }

        uint256 _before = IERC20(_lpToken).balanceOf(address(this));
        if (_poolType == 0) {
            _addLiquidity3AssetPool(_poolAddress, _token, _amount);
        } else if (_poolType == 1 || _poolType == 2) {
            _addLiquidity2AssetPool(_poolAddress, _token, _amount);
        } else if (_poolType == 3) {
            _addLiquidityCrvMetaPool(_poolAddress, _token, _amount);
        } else if (_poolType == 4) {
            _addLiquidityFraxMetaPool(_poolAddress, _token, _amount);
        } else if (_poolType == 5) {
            _addLiquidityETHPool(_poolAddress, _token, _amount);
        } else if (_poolType == 6) {
            _addLiquidityETHV2Pool(_poolAddress, _token, _amount);
        } else if (_poolType == 7) {
            _addLiquidityCurveBase3Pool(_poolAddress, _token, _amount);
        } else if (_poolType == 8) {
            _addLiquidityFraxCryptoMetaPool(_poolAddress, _token, _amount);
        } else if (_poolType == 9) {
            _addLiquiditysUSD4Pool(_poolAddress, _token, _amount);
        } else {
            revert InvalidPoolType();
        }

        _assets = IERC20(_lpToken).balanceOf(address(this)) - _before;
        IERC20(_lpToken).safeTransfer(msg.sender, _assets);

        return _assets;
    }

    // The type of the pool:
    // 0 - 3Pool
    // 1 - PlainPool
    // 2 - CryptoV2Pool
    // 3 - CrvMetaPool
    // 4 - FraxMetaPool
    // 5 - ETHPool
    // 6 - ETHV2Pool
    // 7 - Base3Pool
    // 8 - FraxCryptoMetaPool
    // 9 - sUSD 4Pool
    function removeLiquidity(address _poolAddress, uint256 _poolType, address _token, uint256 _amount) external returns (uint256 _underlyingAmount) {
        if (!whitelist[msg.sender]) revert Unauthorized();

        uint256 _before;
        if (_token == ETH) {
            _before = address(this).balance;
        } else {
            _before = IERC20(_token).balanceOf(address(this));
        }

        address _lpToken = metaRegistry.get_lp_token(_poolAddress);
        IERC20(_lpToken).safeTransferFrom(msg.sender, address(this), _amount);
        
        if (_poolType == 0) {
            _removeLiquidity3AssetPool(_poolAddress, _token, _amount);
        } else if (_poolType == 1 || _poolType == 5) {
            _removeLiquidity2AssetPool(_poolAddress, _token, _amount);
        } else if (_poolType == 2) {
            _removeLiquidityCryptoV2Pool(_poolAddress, _token, _amount);
        } else if (_poolType == 3) {
            _removeLiquidityCrvMetaPool(_poolAddress, _token, _amount);
        } else if (_poolType == 4) {
            _removeLiquidityFraxMetaPool(_poolAddress, _token, _amount);
        } else if (_poolType == 6) {
            _removeLiquidityETHV2Pool(_poolAddress, _token, _amount);
        } else if (_poolType == 7) {
            _removeLiquidityBase3Pool(_poolAddress, _token, _amount);
        } else if (_poolType == 8) {
            _removeLiquidityFraxMetaCryptoPool(_poolAddress, _token, _amount);
        } else if (_poolType == 9) {
            _removeLiquiditysUSD4Pool(_poolAddress, _token, _amount);
        } else {
            revert InvalidPoolType();
        }

        if (_token == ETH) {
            _underlyingAmount = address(this).balance - _before;
            payable(msg.sender).sendValue(_underlyingAmount);
        } else {
            _underlyingAmount = IERC20(_token).balanceOf(address(this)) - _before;
            IERC20(_token).safeTransfer(msg.sender, _underlyingAmount);
        }

        return _underlyingAmount;
    }

    function updateWhitelist(address _vault, bool _whitelisted) external {
        if (msg.sender != owner) revert OnlyOwner();

        whitelist[_vault] = _whitelisted;
    }

    function updateOwner(address _owner) external {
        if (msg.sender != owner) revert OnlyOwner();

        owner = _owner;
    }

    /********************************** Internal Functions **********************************/

    // ICurvesUSD4Pool
    function _addLiquiditysUSD4Pool(address _poolAddress, address _token, uint256 _amount) internal {
        ICurvesUSD4Pool _pool = ICurvesUSD4Pool(_poolAddress);

        _approveOperations(_token, _poolAddress, _amount);

        if (_token == _pool.coins(0)) {
            _pool.add_liquidity([_amount, 0, 0, 0], 0);
        } else if (_token == _pool.coins(1)) {
            _pool.add_liquidity([0, _amount, 0, 0], 0);
        } else if (_token == _pool.coins(2)) {
            _pool.add_liquidity([0, 0, _amount, 0], 0);
        } else if (_token == _pool.coins(3)) {
            _pool.add_liquidity([0, 0, 0, _amount], 0);
        } else {
            revert InvalidToken();
        }
    }

    // ICurveBase3Pool
    function _addLiquidityCurveBase3Pool(address _poolAddress, address _token, uint256 _amount) internal {
        ICurveBase3Pool _pool = ICurveBase3Pool(_poolAddress);

        _approveOperations(_token, _poolAddress, _amount);
        
        if (_token == _pool.coins(0)) {
            _pool.add_liquidity([_amount, 0, 0], 0);
        } else if (_token == _pool.coins(1)) {
            _pool.add_liquidity([0, _amount, 0], 0);
        } else if (_token == _pool.coins(2)) {
            _pool.add_liquidity([0, 0, _amount], 0);
        } else {
            revert InvalidToken();
        }
    }

    // ICurve3Pool
    // ICurveSBTCPool
    function _addLiquidity3AssetPool(address _poolAddress, address _token, uint256 _amount) internal {
        ICurve3Pool _pool = ICurve3Pool(_poolAddress);

        if (_token == ETH) {
            _wrapETH(_amount);
            _token = WETH;
        }
        _approveOperations(_token, _poolAddress, _amount);

        if (_token == _pool.coins(0)) {  
            _pool.add_liquidity([_amount, 0, 0], 0);
        } else if (_token == _pool.coins(1)) {
            _pool.add_liquidity([0, _amount, 0], 0);
        } else if (_token == _pool.coins(2)) {
            _pool.add_liquidity([0, 0, _amount], 0);
        } else {
            revert InvalidToken();
        }
    }

    // ICurveCryptoV2Pool
    // ICurvePlainPool
    function _addLiquidity2AssetPool(address _poolAddress, address _token, uint256 _amount) internal {
        ICurvePool _pool = ICurvePool(_poolAddress);
        
        _approveOperations(_token, _poolAddress, _amount);
        if (_token == _pool.coins(0)) {
            _pool.add_liquidity([_amount, 0], 0);
        } else if (_token == _pool.coins(1)) {
            _pool.add_liquidity([0, _amount], 0);
        } else {
            revert InvalidToken();
        }
    }

    // ICurveCRVMeta - CurveBP
    function _addLiquidityCrvMetaPool(address _poolAddress, address _token, uint256 _amount) internal {
        ICurveCRVMeta _pool = ICurveCRVMeta(_poolAddress);
         
        if (_token == _pool.coins(0)) {
            _approveOperations(_token, _poolAddress, _amount);
            _pool.add_liquidity([_amount, 0], 0);
        } else {
            _addLiquidityCurveBase3Pool(CURVE_BP, _token, _amount);
            _amount = IERC20(TRI_CRV).balanceOf(address(this));
            _approveOperations(TRI_CRV, _poolAddress, _amount);
            _pool.add_liquidity([0, _amount], 0);
        }
    }

    // ICurveFraxMeta - FraxBP
    function _addLiquidityFraxMetaPool(address _poolAddress, address _token, uint256 _amount) internal {
        ICurveFraxMeta _pool = ICurveFraxMeta(_poolAddress);
        
        if (_token == _pool.coins(0)) {
            _approveOperations(_token, _poolAddress, _amount);
            _pool.add_liquidity([_amount, 0], 0);
        } else {
            _addLiquidity2AssetPool(FRAX_BP, _token, _amount);
            _amount = IERC20(CRV_FRAX).balanceOf(address(this));
            _approveOperations(CRV_FRAX, _poolAddress, _amount);
            _pool.add_liquidity([0, _amount], 0);
        }
    }

    // ICurveFraxCryptoMeta - FraxBP/Crypto
    function _addLiquidityFraxCryptoMetaPool(address _poolAddress, address _token, uint256 _amount) internal {
        ICurveFraxCryptoMeta _pool = ICurveFraxCryptoMeta(_poolAddress);
        
        if (_token == _pool.coins(0)) {
            _approveOperations(_token, _poolAddress, _amount);
            _pool.add_liquidity([_amount, 0], 0);
        } else {
            _addLiquidity2AssetPool(FRAX_BP, _token, _amount);
            _amount = IERC20(CRV_FRAX).balanceOf(address(this));
            _approveOperations(CRV_FRAX, _poolAddress, _amount);
            _pool.add_liquidity([0, _amount], 0);
        }
    }

    // ICurveETHPool
    function _addLiquidityETHPool(address _poolAddress, address _token, uint256 _amount) internal {
        ICurveETHPool _pool = ICurveETHPool(_poolAddress);

        if (_pool.coins(0) == _token) {
            payable(address(_pool)).functionCallWithValue(abi.encodeWithSignature("add_liquidity(uint256[2],uint256)", [_amount, 0], 0), _amount);
        } else if (_pool.coins(1) == _token) {
            _approveOperations(_token, _poolAddress, _amount);
            _pool.add_liquidity([0, _amount], 0);
        } else {
            revert InvalidToken();
        }
    }

    // ICurveCryptoETHV2Pool
    function _addLiquidityETHV2Pool(address _poolAddress, address _token, uint256 _amount) internal {
        ICurveCryptoETHV2Pool _pool = ICurveCryptoETHV2Pool(_poolAddress);

        if (_token == ETH) {
            payable(address(_pool)).functionCallWithValue(abi.encodeWithSignature("add_liquidity(uint256[2],uint256,bool)", [_amount, 0], 0, true), _amount);
        } else if (_token == _pool.coins(0)) {
            _approveOperations(_token, _poolAddress, _amount);
            _pool.add_liquidity([_amount, 0], 0, false);
        } else if (_token == _pool.coins(1)) {
            _approveOperations(_token, _poolAddress, _amount);
            _pool.add_liquidity([0, _amount], 0, false);
        } else {
            revert InvalidToken();
        }
    }

    // ICurvesUSD4Pool
    function _removeLiquiditysUSD4Pool(address _poolAddress, address _token, uint256 _amount) internal {
        ICurvesUSD4Pool _poolWrapper = ICurvesUSD4Pool(address(0xFCBa3E75865d2d561BE8D220616520c171F12851));
        ICurvesUSD4Pool _pool = ICurvesUSD4Pool(_poolAddress);

        _approveOperations(address(0xC25a3A3b969415c80451098fa907EC722572917F), address(_poolWrapper), _amount);
        
        if (_token == _pool.coins(0)) {
            _poolWrapper.remove_liquidity_one_coin(_amount, 0, 0);
        } else if (_token == _pool.coins(1)) {
            _poolWrapper.remove_liquidity_one_coin(_amount, 1, 0);
        } else if (_token == _pool.coins(2)) {
            _poolWrapper.remove_liquidity_one_coin(_amount, 2, 0);
        } else if (_token == _pool.coins(3)) {
            _poolWrapper.remove_liquidity_one_coin(_amount, 3, 0);
        } else {
            revert InvalidToken();
        }
    }

    // ICurve3Pool
    function _removeLiquidity3AssetPool(address _poolAddress, address _token, uint256 _amount) internal {
        ICurve3Pool _pool = ICurve3Pool(_poolAddress);
        
        bool _isEth = false;
        if (_token == ETH) {
            _token = WETH;
            _isEth = true;
        }

        uint256 _before = IERC20(_token).balanceOf(address(this));
        if (_token == _pool.coins(0)) {
             _pool.remove_liquidity_one_coin(_amount, 0, 0);
        } else if (_token == _pool.coins(1)) {
            _pool.remove_liquidity_one_coin(_amount, 1, 0);
        } else if (_token == _pool.coins(2)) {
            _pool.remove_liquidity_one_coin(_amount, 2, 0);
        } else {
            revert InvalidToken();
        }

        if (_isEth) {
            _unwrapETH(IERC20(_token).balanceOf(address(this)) - _before);
        }
    }

    // ICurveBase3Pool
    // ICurveSBTCPool
    function _removeLiquidityBase3Pool(address _poolAddress, address _token, uint256 _amount) internal {
        ICurveBase3Pool _pool = ICurveBase3Pool(_poolAddress);

        if (_token == _pool.coins(0)) {
            _pool.remove_liquidity_one_coin(_amount, 0, 0);
        } else if (_token == _pool.coins(1)) {
            _pool.remove_liquidity_one_coin(_amount, 1, 0);
        } else if (_token == _pool.coins(2)) {
            _pool.remove_liquidity_one_coin(_amount, 2, 0);
        } else {
            revert InvalidToken();
        }
    }

    // ICurveETHPool
    // ICurvePlainPool
    function _removeLiquidity2AssetPool(address _poolAddress, address _token, uint256 _amount) internal {
        ICurvePool _pool = ICurvePool(_poolAddress);

        if (_token == _pool.coins(0)) {
            _pool.remove_liquidity_one_coin(_amount, 0, 0);
        } else if (_token == _pool.coins(1)) {
            _pool.remove_liquidity_one_coin(_amount, 1, 0);
        } else {
            revert InvalidToken();
        }
    }

    // ICurveCryptoV2Pool
    function _removeLiquidityCryptoV2Pool(address _poolAddress, address _token, uint256 _amount) internal {
        ICurveCryptoV2Pool _pool = ICurveCryptoV2Pool(_poolAddress);

        if (_token == _pool.coins(0)) {
            _pool.remove_liquidity_one_coin(_amount, 0, 0);
        } else if (_token == _pool.coins(1)) {
            _pool.remove_liquidity_one_coin(_amount, 1, 0);
        } else {
            revert InvalidToken();
        }
    }

    // ICurveCryptoETHV2Pool
    function _removeLiquidityETHV2Pool(address _poolAddress, address _token, uint256 _amount) internal {
        ICurveCryptoETHV2Pool _pool = ICurveCryptoETHV2Pool(_poolAddress);
        
        if (_token == ETH) {
            _pool.remove_liquidity_one_coin(_amount, 0, 0, true);
        } else if (_token == _pool.coins(0)) {
            _pool.remove_liquidity_one_coin(_amount, 0, 0, false);
        } else if (_token == _pool.coins(1)) {
            _pool.remove_liquidity_one_coin(_amount, 1, 0, false);
        } else {
            revert InvalidToken();
        }
    }

    // ICurveCRVMeta - CurveBP
    function _removeLiquidityCrvMetaPool(address _poolAddress, address _token, uint256 _amount) internal {
        ICurveCRVMeta _pool = ICurveCRVMeta(_poolAddress);
        
        if (_token == _pool.coins(0)) {
            _pool.remove_liquidity_one_coin(_amount, 0, 0);
        } else {
            _amount = _pool.remove_liquidity_one_coin(_amount, 1, 0);
            _removeLiquidityBase3Pool(CURVE_BP, _token, _amount);
        }
    }

    // ICurveFraxMeta - FraxBP/Stable
    function _removeLiquidityFraxMetaPool(address _poolAddress, address _token, uint256 _amount) internal {
        ICurveFraxMeta _pool = ICurveFraxMeta(_poolAddress);
        
        if (_token == _pool.coins(0)) {
            _pool.remove_liquidity_one_coin(_amount, 0, 0);
        } else {
            _amount = _pool.remove_liquidity_one_coin(_amount, 1, 0);
            _removeLiquidity2AssetPool(FRAX_BP, _token, _amount);
        }
    }

    // ICurveFraxCryptoMeta - FraxBP/Crypto
    function _removeLiquidityFraxMetaCryptoPool(address _poolAddress, address _token, uint256 _amount) internal {
        ICurveFraxCryptoMeta _pool = ICurveFraxCryptoMeta(_poolAddress);
        
        if (_token == _pool.coins(0)) {
            _pool.remove_liquidity_one_coin(_amount, 0, 0);
        } else {
            _amount = _pool.remove_liquidity_one_coin(_amount, 1, 0);
            _removeLiquidity2AssetPool(FRAX_BP, _token, _amount);
        }
    }

    function _wrapETH(uint256 _amount) internal {
        payable(WETH).functionCallWithValue(abi.encodeWithSignature("deposit()"), _amount);
    }

    function _unwrapETH(uint256 _amount) internal {
        IWETH(WETH).withdraw(_amount);
    }

    function _approveOperations(address _token, address _spender, uint256 _amount) internal virtual {
        IERC20(_token).safeApprove(_spender, 0);
        IERC20(_token).safeApprove(_spender, _amount);
    }

    receive() external payable {}

    /********************************** Errors **********************************/

    error InvalidToken();
    error InvalidAsset();
    error InvalidAmount();
    error InvalidPoolType();
    error FailedToSendETH();
    error OnlyOwner();
    error Unauthorized();
}