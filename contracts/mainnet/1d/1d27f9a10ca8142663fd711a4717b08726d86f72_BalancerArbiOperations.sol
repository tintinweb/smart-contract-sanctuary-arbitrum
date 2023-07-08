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

//  _____     _                     _____                 _   _             
// | __  |___| |___ ___ ___ ___ ___|     |___ ___ ___ ___| |_|_|___ ___ ___ 
// | __ -| .'| | .'|   |  _| -_|  _|  |  | . | -_|  _| .'|  _| | . |   |_ -|
// |_____|__,|_|__,|_|_|___|___|_| |_____|  _|___|_| |__,|_| |_|___|_|_|___|
//                                       |_|                                

// Github - https://github.com/FortressFinance

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import "src/shared/fortress-interfaces/IFortressSwap.sol";
import "src/shared/interfaces/IWETH.sol";

import "src/shared/interfaces/IBalancerVault.sol";
import "src/shared/interfaces/IBalancerPool.sol";

contract BalancerArbiOperations {

    using SafeERC20 for IERC20;
    using Address for address payable;
    
    /// @notice The address of the owner
    address public owner;

    /// @notice The mapping of whitelisted addresses, which are Fortress Vaults
    mapping(address => bool) public whitelist;

    /// @notice The address of Balancer vault.
    address internal constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    /// @notice The address representing ETH.
    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @notice The address of WETH.
    address internal constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
        
    /********************************** Constructor **********************************/

    constructor(address _owner) {
        owner = _owner;
    }

    /********************************** Restricted Functions **********************************/

    function updateWhitelist(address _vault, bool _whitelisted) external {
        if (msg.sender != owner) revert OnlyOwner();

        whitelist[_vault] = _whitelisted;
    }

    function updateOwner(address _owner) external {
        if (msg.sender != owner) revert OnlyOwner();

        owner = _owner;
    }

    /********************************** Restricted Functions **********************************/

    function addLiquidity(address _poolAddress, address _asset, uint256 _amount) external returns (uint256 _assets) {
        if (!whitelist[msg.sender]) revert Unauthorized_();
        
        bytes32 _poolId = IBalancerPool(_poolAddress).getPoolId();
        IBalancerVault _vault = IBalancerVault(BALANCER_VAULT);

        (address[] memory _tokens,,) = _vault.getPoolTokens(_poolId);

        uint256 _before = IERC20(_poolAddress).balanceOf(address(this));
        
        if (_asset == ETH) {
            _wrapETH(_amount);
            _asset = WETH;
        }
        IERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);

        uint256[] memory _amounts = new uint256[](_tokens.length);
        for (uint256 _i = 0; _i < _tokens.length; _i++) {
            if (_tokens[_i] == _asset) {
                _amounts[_i] = _amount;

                uint256[] memory _noBptAmounts = _isComposablePool(_tokens, _poolAddress) ? _dropBptItem(_tokens, _amounts, _poolAddress) : _amounts;
                
                _approveOperations(_tokens[_i], address(_vault), _amount);
                // _approveOperations(_tokens[_i], BALANCER_VAULT, _amount);
                _vault.joinPool(
                    _poolId,
                    address(this), // sender
                    address(this), // recipient
                    IBalancerVault.JoinPoolRequest({
                        assets: _tokens,
                        maxAmountsIn: _amounts,
                        userData: abi.encode(
                            IBalancerVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
                            _noBptAmounts, // amountsIn
                            0 // minimumBPT
                        ),
                        fromInternalBalance: false
                    })
                );
                break;
            }
        }
        _assets = IERC20(_poolAddress).balanceOf(address(this)) - _before;
        IERC20(_poolAddress).safeTransfer(msg.sender, _assets);
        
        return _assets;
    }

    function removeLiquidity(address _poolAddress, address _asset, uint256 _bptAmountIn) external returns (uint256 _underlyingAmount) {
        if (!whitelist[msg.sender]) revert Unauthorized_();
        
        bytes32 _poolId = IBalancerPool(_poolAddress).getPoolId();
        IBalancerVault _vault = IBalancerVault(BALANCER_VAULT);

        (address[] memory _tokens,,) = _vault.getPoolTokens(_poolId);
        uint256 _before = IERC20(_asset).balanceOf(address(this));
        
        IERC20(_poolAddress).safeTransferFrom(msg.sender, address(this), _bptAmountIn);

        uint256[] memory _amounts = new uint256[](_tokens.length);
        for (uint256 _i = 0; _i < _tokens.length; _i++) {
            if (_tokens[_i] == _asset) {
                _vault.exitPool(
                    _poolId,
                    address(this), // sender
                    payable(address(this)), // recipient
                    IBalancerVault.ExitPoolRequest({
                        assets: _tokens,
                        minAmountsOut: _amounts,
                        userData: abi.encode(
                            IBalancerVault.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
                            _bptAmountIn, // bptAmountIn
                            _i // enterTokenIndex
                        ),
                        toInternalBalance: false
                    })
                );
                break;
            }
        }
        _underlyingAmount = IERC20(_asset).balanceOf(address(this)) - _before;
        IERC20(_asset).safeTransfer(msg.sender, _underlyingAmount);

        return _underlyingAmount;
    }

    /********************************** Internal Functions **********************************/

    function _isComposablePool(address[] memory _tokens, address _poolAddress) internal pure returns (bool) {
        for(uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i] == _poolAddress) {
                return true;
            }
        }
        return false;
    }
    
    function _dropBptItem(address[] memory _tokens, uint256[] memory _amounts, address _poolAddress) internal pure returns (uint256[] memory) {
        uint256[] memory _noBPTAmounts = new uint256[](_tokens.length - 1);
        uint256 _j = 0;
        for(uint256 _i = 0; _i < _tokens.length; _i++) {
            if (_tokens[_i] != _poolAddress) {
                _noBPTAmounts[_j] = _amounts[_i];
                _j++;
            }
        }
        return _noBPTAmounts;
    }

    function _approveOperations(address _token, address _spender, uint256 _amount) internal virtual {
        IERC20(_token).safeApprove(_spender, 0);
        IERC20(_token).safeApprove(_spender, _amount);
    }

    function _wrapETH(uint256 _amount) internal {
        IWETH(WETH).deposit{ value: _amount }();
    }

    // receive() external payable {}

/********************************** Errors **********************************/

    error OnlyOwner();
    error Unauthorized_();

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.17;

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.17;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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
pragma solidity 0.8.17;

interface IFortressSwap {

    /// @notice swap _amount of _fromToken to _toToken.
    /// @param _fromToken The address of the token to swap from.
    /// @param _toToken The address of the token to swap to.
    /// @param _amount The amount of _fromToken to swap.
    /// @return _amount The amount of _toToken after swap.  
    function swap(address _fromToken, address _toToken, uint256 _amount) external payable returns (uint256);

    /********************************** Events & Errors **********************************/

    event Swap(address indexed _fromToken, address indexed _toToken, uint256 _amount);
    event UpdateRoute(address indexed fromToken, address indexed toToken, address[] indexed poolAddress);
    event DeleteRoute(address indexed fromToken, address indexed toToken);
    event UpdateOwner(address indexed _newOwner);
    event Rescue(address[] indexed _tokens, address indexed _recipient);
    event RescueETH(address indexed _recipient);

    error Unauthorized();
    error UnsupportedPoolType();
    error FailedToSendETH();
    error InvalidTokens();
    error RouteUnavailable();
    error AmountMismatch();
    error TokenMismatch();
    error RouteAlreadyExists();
    error ZeroInput();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IWETH {
  function deposit() external payable;

  function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma abicoder v2;

import "src/mainnet/interfaces/IAsset.sol";

interface IBalancerVault {
    
    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT,
        ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
    }

    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT,
        MANAGEMENT_FEE_TOKENS_OUT
    }

    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    struct ExitPoolRequest{
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance; 
    }

    function getPoolTokens(bytes32 poolId) external view returns (address[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);

    function swap(SingleSwap memory singleSwap, FundManagement memory funds, uint256 limit, uint256 deadline) external payable returns (uint256 amountCalculated);

    function batchSwap(SwapKind kind, BatchSwapStep[] memory swaps, IAsset[] memory assets, FundManagement memory funds, int256[] memory limits, uint256 deadline) external payable returns (int256[] memory);

    function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request) external payable;

    function exitPool(bytes32 poolId, address sender, address payable recipient, ExitPoolRequest memory request) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IBalancerPool {

  function getPoolId() external view returns (bytes32);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity 0.8.17;

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity 0.8.17;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}