/**
 *Submitted for verification at Arbiscan on 2023-04-04
*/

// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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


// File contracts/interfaces/IAggregatorV3.sol

pragma solidity >=0.6.0;

interface IAggregatorV3 {
  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}


// File contracts/interfaces/IForgeAsset.sol

pragma solidity >=0.8.4;

interface IForgeAsset {
  function decimals() external returns (uint8);
  function mint(address _to, uint256 _amount) external;
  function burn(address _from, uint256 _amount) external;
  function balanceOf(address account) external view returns (uint256);
}


// File contracts/Forge.sol

// ███████╗ ██████╗ ██████╗  ██████╗ ███████╗   ███████╗ ██████╗ ██╗     
// ██╔════╝██╔═══██╗██╔══██╗██╔════╝ ██╔════╝   ██╔════╝██╔═══██╗██║     
// █████╗  ██║   ██║██████╔╝██║  ███╗█████╗     ███████╗██║   ██║██║     
// ██╔══╝  ██║   ██║██╔══██╗██║   ██║██╔══╝     ╚════██║██║   ██║██║     
// ██║     ╚██████╔╝██║  ██║╚██████╔╝███████╗██╗███████║╚██████╔╝███████╗
// ╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝╚══════╝ ╚═════╝ ╚══════╝
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;



contract Forge {
    using SafeERC20 for IERC20;
    struct Oven {
        address account;        // owner of oven
        uint collateral;        // collateral amount
        uint amount;            // forged synthetic amount
        uint token;             // synthetic id
    }
    struct Asset {
        IForgeAsset token;          // synthetic token address
        uint8 decimals;             // synthetic token decimals
        address oracle;             // oracle address
        uint8 oracleDecimals;       // decimals of oracle data feed
        bool paused;                // pause a single asset
        uint depositRatio;          // minimum cratio for deposits
        uint liquidationThreshold;  // cratio at which liquidation is possible
    }

    // Pauses everything
    bool public isPaused;

    // Special addresses
    address public admin;
    address public pauser;
    address public collector;

    // Collateral currency
    address public currency; 
    uint8 public currencyDecimals;

    // C-Ratio decimals
    uint8 public cRatioDecimals = 8;

    // Fees scheme
    uint256 public fee = 50; // 0.5%
    uint256 public feeBase = 10000;
    uint256 public feeLiquidatorPercent = 500; // 5%
    uint256 public feeLiquidatorPercentBase = 10000;

    // Minimum required collateral in an oven
    uint public minCollateral;

    // List of all ovens
    mapping(address => Oven[]) public ovens;

    // List of all users addresses
    address[] public users;
    mapping(address => bool) public isUser;

    // List of available synthetic assets
    Asset[] public assets;
    
    event Close(address indexed account, uint indexed id);
    event Edit(address indexed account, uint indexed id, uint collateral, uint amount);
    event Liquidate(address indexed account, address indexed liquidator, uint indexed id, uint collateral, uint amount, uint fee);
    event Open(address indexed account, uint indexed id, uint amount, uint collateral, uint token);

    constructor(
		address _currency,
		uint8 _currencyDecimals,
        uint256 _minCollateral
    ) {
        admin = msg.sender;
        pauser = msg.sender;
        collector = msg.sender;
		currency = _currency;
		currencyDecimals = _currencyDecimals;
        minCollateral = _minCollateral;
    }

    // VIEWS
    function getUsersLength() public view returns (uint numUsers) {
        return users.length;
    }

    function getOvensLength(address account) public view returns (uint numOvens) {
        return ovens[account].length;
    }

    function getOvenRatio(address account, uint id) public view returns (uint ratio) {
        Oven memory oven = ovens[account][id];
        Asset storage asset = assets[oven.token];
        (, int price, uint startedAt, uint updatedAt, ) = IAggregatorV3(asset.oracle).latestRoundData();
        require(price > 0 && startedAt > 0 && updatedAt > 0, "Invalid oracle data");
        return 
            oven.collateral * 10**(cRatioDecimals + asset.oracleDecimals + asset.decimals - currencyDecimals)
            / (oven.amount * uint(price));
    }

    // EXTERNAL FUNCTIONS
    function open(uint collateral, uint amount, uint assetId) external {
        require(!isPaused, "All paused");
        Asset storage asset = assets[assetId];
        require(!asset.paused, "Asset paused");
        require(collateral >= minCollateral, "Not enough collateral");
        require(amount > 0, "Amount must be greater than 0");
        (, int price, uint startedAt, uint updatedAt, ) = IAggregatorV3(asset.oracle).latestRoundData();
        require(price > 0 && startedAt > 0 && updatedAt > 0, "Invalid oracle data");
        uint maxAmount =
            collateral * 10**(asset.decimals + cRatioDecimals + asset.oracleDecimals - currencyDecimals)
            / (asset.depositRatio * uint(price));
        require(amount <= maxAmount, "Mint amount too big");

        IERC20(currency).safeTransferFrom(msg.sender, address(this), collateral);
        ovens[msg.sender].push(Oven({
            account: msg.sender,
            collateral: collateral,
            amount: amount,
            token: assetId
        }));
        if (amount > 0) {
            asset.token.mint(msg.sender, amount);
        }
        if (!isUser[msg.sender]) {
            users.push(msg.sender);
            isUser[msg.sender] = true;
        }
        
        emit Open(msg.sender, ovens[msg.sender].length-1, amount, collateral, assetId);
    }
    
    function close(uint id) external {
        require(!isPaused, "All paused");
        Oven memory oven = ovens[msg.sender][id];
        require(msg.sender == oven.account, "Only issuer");
        Asset storage asset = assets[oven.token];
        require(!asset.paused, "Asset paused");
        
        if (oven.amount > 0) {
            asset.token.burn(msg.sender, oven.amount);
        }
        if (oven.collateral > 0) {
            uint collateral = oven.collateral;
            uint paidFee = collateral * fee / feeBase;
            IERC20(currency).safeTransfer(collector, paidFee);   
            IERC20(currency).safeTransfer(msg.sender, collateral - paidFee);
        }
        if (id != ovens[msg.sender].length -1) {
            ovens[msg.sender][id] = ovens[msg.sender][ovens[msg.sender].length - 1];
        }
        ovens[msg.sender].pop();

        emit Close(msg.sender, id);
    }

    function edit(uint id, uint collateral, uint amount) external {
        require(!isPaused, "All paused");
        Oven memory oven = ovens[msg.sender][id];
        require(msg.sender == oven.account, "Only issuer");
        Asset storage asset = assets[oven.token];
        require(!asset.paused, "Asset paused");
        require(collateral >= minCollateral, "Not enough collateral");
        require(amount > 0, "Amount must be >0");
        (, int price, uint startedAt, uint updatedAt, ) = IAggregatorV3(asset.oracle).latestRoundData();
        require(price > 0 && startedAt > 0 && updatedAt > 0, "Invalid oracle data");
        uint newRatio = 
            collateral * 10**(cRatioDecimals + asset.oracleDecimals + asset.decimals - currencyDecimals)
            / (amount * uint(price));
        require(newRatio >= asset.depositRatio, "New collateralization ratio too low");

        if (collateral > oven.collateral) {
            // add collateral
            IERC20(currency).safeTransferFrom(msg.sender, address(this), collateral - oven.collateral);
            oven.collateral = collateral;
        }
        else if (collateral < oven.collateral) {
            // remove collateral
            uint withdrawAmount = oven.collateral - collateral;
            uint paidFee = withdrawAmount * fee / feeBase;
            withdrawAmount -= paidFee;
            IERC20(currency).safeTransfer(collector, paidFee);
            IERC20(currency).safeTransfer(msg.sender, withdrawAmount);
            oven.collateral = collateral;
        }
        if (amount > oven.amount) {
            // mint fAsset
            asset.token.mint(msg.sender, amount - oven.amount);
            oven.amount = amount;
        }
        else if (amount < oven.amount) {
            // burn fAsset
            asset.token.burn(msg.sender, oven.amount - amount);
            oven.amount = amount;
        }

        ovens[msg.sender][id] = oven;
        emit Edit(msg.sender, id, collateral, amount);
    }
    
    function liquidate(address account, uint id, uint amount) external {
        require(!isPaused, "All paused");
        require(amount > 0, "Cant burn zero");
        Oven memory oven = ovens[account][id];
        require(oven.amount >= amount, "Amount larger than oven");
        Asset storage asset = assets[oven.token];
        require(!asset.paused, "Asset paused");
        uint cratio = getOvenRatio(account, id);
        require (cratio < asset.liquidationThreshold, "Not below liquidation threshold");
        uint collateral = oven.collateral * amount / oven.amount;
        oven.collateral = oven.collateral - collateral;
        require(oven.collateral == 0 || oven.collateral >= minCollateral, "Partial liquidation cannot go below minimum collateral");

        asset.token.burn(msg.sender, amount);
        oven.amount = oven.amount - amount;
        ovens[account][id] = oven;
        uint liquidatorReward = 
            collateral * 10**cRatioDecimals
            / cratio;
        uint paidFee = 0;
        if (liquidatorReward >= collateral) {
            // no fee in this case
            // should not happen under normal conditions
            IERC20(currency).safeTransfer(msg.sender, collateral);
        } else {
            uint left = collateral - liquidatorReward;
            uint liquidatorFee = left * feeLiquidatorPercent / feeLiquidatorPercentBase;
            left = left - liquidatorFee;
            liquidatorReward += liquidatorFee;
            uint paidFeeByLiquidator = liquidatorReward * fee / feeBase;
            liquidatorReward -= paidFeeByLiquidator;
            uint paidFeeByLiquidated = left * fee / feeBase;
            left -= paidFeeByLiquidated;
            paidFee = paidFeeByLiquidated + paidFeeByLiquidator;
            IERC20(currency).safeTransfer(collector, paidFee);
            IERC20(currency).safeTransfer(msg.sender, liquidatorReward);
            IERC20(currency).safeTransfer(oven.account, left);
        }

        emit Liquidate(oven.account, msg.sender, id, collateral, amount, paidFee);
        if (oven.collateral == 0) {
            require(oven.amount == 0, "Oven should be closing but amount is >0");
            if (id != ovens[account].length -1) {
                ovens[account][id] = ovens[account][ovens[account].length - 1];
            }
            ovens[account].pop();
            emit Close(account, id);
        }
    }

    // PAUSER FUNCTIONS
    function pause() external {
        require(msg.sender == pauser, "Pauser only");
        isPaused = true;
    }

    function unpause() external {
        require(msg.sender == pauser, "Pauser only");
        isPaused = false;
    }

    function pauseAsset(uint id) external {
        require(msg.sender == pauser, "Pauser only");
        assets[id].paused = true;
    }

    function resumeAsset(uint id) external {
        require(msg.sender == pauser, "Pauser only");
        assets[id].paused = false;
    }
    
    // ADMIN FUNCTIONS
    function setAdmin(address _admin) external {
        require(msg.sender == admin, "Admin only");
        admin = _admin;
    }
    
    function setCollector(address _collector) external {
        require(msg.sender == admin, "Admin only");
        collector = _collector;
    }

    function setPauser(address _pauser) external {
        require(msg.sender == admin, "Admin only");
        pauser = _pauser;
    }

    function setFee(uint256 _fee) external {
        require(msg.sender == admin, "Admin only");
        fee = _fee;
    }

    function setFeeLiquidation(uint256 _feeLiquidatorPercent) external {
        require(msg.sender == admin, "Admin only");
        feeLiquidatorPercent = _feeLiquidatorPercent;
    }
    
    function setMinCollateral(uint _minCollateral) external {
        require(msg.sender == admin, "Admin only");
        minCollateral = _minCollateral;
    }
    
    function setAssetOracle(address _oracle, uint id) external {
        require(msg.sender == admin, "Admin only");
        assets[id].oracle = _oracle;
        assets[id].oracleDecimals = IAggregatorV3(_oracle).decimals();
    }
    
    function addAsset(IForgeAsset _token, address _oracle, bool _paused, uint _depositRatio, uint _liquidationThreshold) external {
        require(msg.sender == admin, "Admin only");
        require(_liquidationThreshold < _depositRatio, "liquidationThreshold is bigger than depositRatio");
        assets.push(Asset({
            token: _token,
            decimals: IForgeAsset(_token).decimals(),
            oracle: _oracle,
            oracleDecimals: IAggregatorV3(_oracle).decimals(),
            paused: _paused,
			depositRatio: _depositRatio,
            liquidationThreshold: _liquidationThreshold
        }));
    }
}


// File contracts/LiquidationFinder.sol

pragma solidity >=0.8.4;

contract LiquidationFinder {
  struct Liquidation {
    address account;        // owner of oven
    uint ovenId;            // id of oven
    uint collateral;        // collateral amount
    uint amount;            // forged synthetic amount
    uint ratio;             // collateralization ratio
  }
  Forge forge;

  constructor(address forgeAddress) {
    forge = Forge(forgeAddress);
  }

  function getLiquidation(uint fassetId, uint maxRatio, int skip) public view returns(
    Liquidation memory liq
  ) {
    uint nUsers = forge.getUsersLength();
    for (uint256 i = nUsers-1; i >= 0; i--) {
      address userAddr = forge.users(i);
      uint nOvens = forge.getOvensLength(userAddr);
      for (uint256 y = 0; y < nOvens; y++) {
        (address acc, uint colla, uint am, uint token) = forge.ovens(userAddr,y);
        if (token != fassetId)
          continue;
        uint ovenRatio = forge.getOvenRatio(userAddr, y);
        if (ovenRatio < maxRatio) {
          if (skip > 0)
            skip--;
          else
            return Liquidation({
              account: acc,
              ovenId: y,
              collateral: colla,
              amount: am,
              ratio: ovenRatio
            });
        }
      }
      if (i == 0)
        return Liquidation({
          account: address(0),
          ovenId: 0,
          collateral: 0,
          amount: 0,
          ratio: 0
        });
    }
  }
}