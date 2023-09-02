// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "./IOwnable.sol";
import "./IUnifiedOracleAggregator.sol";

interface ILendingController is IOwnable {
    function oracleAggregator()
        external
        view
        returns (IUnifiedOracleAggregator);

    function liqFeeSystem(address _token) external view returns (uint256);

    function liqFeeCaller(address _token) external view returns (uint256);

    function colFactor(address _token) external view returns (uint256);

    function defaultColFactor() external view returns (uint256);

    function depositLimit(
        address _lendingPair,
        address _token
    ) external view returns (uint256);

    function borrowLimit(
        address _lendingPair,
        address _token
    ) external view returns (uint256);

    function tokenPrice(address _token) external view returns (uint256);

    function minBorrow(address _token) external view returns (uint256);

    function tokenPrices(
        address _tokenA,
        address _tokenB
    ) external view returns (uint256, uint256);

    function tokenSupported(address _token) external view returns (bool);

    function hasChainlinkOracle(address _token) external view returns (bool);

    function isBaseAsset(address _token) external view returns (bool);

    function minObservationCardinalityNext() external view returns (uint16);

    function preparePool(address _tokenA, address _tokenB) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IOwnable {
    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;

    function acceptOwnership() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title Oracle aggergator for uni and link oracles
/// @author flora.loans
/// @notice Owner can set Chainlink oracles for specific tokens
/// @notice returns the token price from chainlink oracle (if available) otherwise the uni oracle will be used
interface IUnifiedOracleAggregator {
    function linkOracles(address) external view returns (address);

    function setOracle(address, AggregatorV3Interface) external;

    function preparePool(address, address, uint16) external;

    function tokenSupported(address) external view returns (bool);

    function tokenPrice(address) external view returns (uint256);

    function tokenPrices(
        address,
        address
    ) external view returns (uint256, uint256);

    /// @dev Not used in any code to save gas. But useful for external usage.
    function convertTokenValues(
        address,
        address,
        uint256
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) FloraLoans - All rights reserved
// https://twitter.com/Flora_Loans

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/ILendingController.sol";
import "./interfaces/IUnifiedOracleAggregator.sol";

/// @title LendingController
/// @author 0xdev and flora.loans
/// @notice This contract is the control center for flora, an ERC20-based lending platform.
/// @dev This contract allows the owner to manage parameters crucial for the functionality of the protocol.

contract LendingController is ILendingController, Ownable2Step {
    using Address for address;

    uint256 private constant MAX_COL_FACTOR = 99e18; // 99%
    uint256 private constant MAX_LIQ_FEES = 50e18; // 50%
    uint256 public defaultColFactor = 60e18;

    /// @notice Minimum observation cardinality for Uniswap oracle (Arbitrum specific)
    uint16 public minObservationCardinalityNext = 1_800;

    IUnifiedOracleAggregator public oracleAggregator;

    uint256 public liqFeeCallerDefault;
    uint256 public liqFeeSystemDefault;

    mapping(address userAddress => bool) public isGuardian;
    mapping(address lendingPair => mapping(address token => uint256 depositLimit))
        public
        override depositLimit;
    mapping(address lendingPair => mapping(address token => uint256 borrowLimit))
        public
        override borrowLimit;

    mapping(address token => uint256) public liqFeeCallerToken; // 1e18  = 1%
    mapping(address token => uint256) public liqFeeSystemToken; // 1e18  = 1%
    mapping(address token => uint256) public override colFactor; // 99e18 = 99%
    mapping(address token => uint256) public override minBorrow;

    mapping(address token => bool) public isBaseAsset; // Pairs can only be created against those assets

    event OracleAggregatorSet(
        address oldOracleAggregator,
        address indexed oracleAggregator
    );
    event ColFactorSet(address indexed token, uint256 oldValue, uint256 value);
    event DefaultColFactorSet(uint256 oldValue, uint256 value);
    event DepositLimitSet(
        address indexed pair,
        address indexed token,
        uint256 oldValue,
        uint256 value
    );
    event BorrowLimitSet(
        address indexed pair,
        address indexed token,
        uint256 oldValue,
        uint256 value
    );
    event GuardianAllowed(address indexed guardian, bool value);
    event LiqParamsTokenSet(
        address indexed token,
        uint256 oldLiqFeeSystem,
        uint256 oldLiqFeeCaller,
        uint256 liqFeeSystem,
        uint256 liqFeeCaller
    );
    event LiqParamsDefaultSet(
        uint256 oldLiqFeeSystem,
        uint256 oldLiqFeeCaller,
        uint256 liqFeeSystem,
        uint256 liqFeeCaller
    );
    event BaseAssetSet(address indexed token, bool isBaseAsset);
    event MinBorrowSet(address indexed token, uint256 oldValue, uint256 value);

    /// @notice restrict operations to guardians
    modifier onlyGuardian() {
        require(
            isGuardian[msg.sender],
            "LendingController: caller is not a guardian"
        );
        _;
    }

    /// @notice Constructor for the LendingController contract.
    /// @dev dev need to verify minObservationCardinalityNext, which are network specific
    /// @param _liqFeeSystemDefault The default liquidation fee for the system.
    /// @param _liqFeeCallerDefault The default liquidation fee for the caller.
    constructor(uint256 _liqFeeSystemDefault, uint256 _liqFeeCallerDefault) {
        require(
            _liqFeeSystemDefault + _liqFeeCallerDefault <= MAX_LIQ_FEES,
            "LendingController: liquidation fees too high."
        );

        liqFeeSystemDefault = _liqFeeSystemDefault;
        liqFeeCallerDefault = _liqFeeCallerDefault;
    }

    /// @notice Set the liquidation parameters for an individual token.
    /// @dev During liquidation, the lending Pair will query the liquidationParameters for each individual token from the LendingController.
    /// @param _token The address of the token.
    /// @param _liqFeeSystem The liquidation fee for the protocol.
    /// @param _liqFeeCaller The liquidation fee for the liquidator.
    function setLiqParamsToken(
        address _token,
        uint256 _liqFeeSystem,
        uint256 _liqFeeCaller
    ) external onlyOwner {
        require(
            _liqFeeCaller + _liqFeeSystem <= MAX_LIQ_FEES,
            "LendingController: fees too high"
        );
        require(
            _token.isContract(),
            "LendingController: _token must be a contract."
        );
        uint256 oldLiqFeeSystem = liqFeeSystemToken[_token];
        uint256 oldLiqFeeCaller = liqFeeCallerToken[_token];

        liqFeeSystemToken[_token] = _liqFeeSystem;
        liqFeeCallerToken[_token] = _liqFeeCaller;

        emit LiqParamsTokenSet(
            _token,
            oldLiqFeeSystem,
            oldLiqFeeCaller,
            _liqFeeSystem,
            _liqFeeCaller
        );
    }

    /// @notice Set the default liquidation parameters.
    /// @dev During liquidation, the lending Pair will query the liquidationParameters for each individual token from the LendingController.
    /// @dev Tokens without specific parameters set will default to this.
    /// @param _liqFeeSystem The default liquidation fee for the protocol.
    /// @param _liqFeeCaller The default liquidation fee for the liquidator.
    function setLiqParamsDefault(
        uint256 _liqFeeSystem,
        uint256 _liqFeeCaller
    ) external onlyOwner {
        require(
            _liqFeeCaller + _liqFeeSystem <= MAX_LIQ_FEES,
            "LendingController: fees too high"
        );
        uint256 oldLiqFeeSystem = liqFeeSystemDefault;
        uint256 oldLiqFeeCaller = liqFeeCallerDefault;

        liqFeeSystemDefault = _liqFeeSystem;
        liqFeeCallerDefault = _liqFeeCaller;

        emit LiqParamsDefaultSet(
            oldLiqFeeSystem,
            oldLiqFeeCaller,
            _liqFeeSystem,
            _liqFeeCaller
        );
    }

    /// @notice Set the OracleAggregator address.
    /// @dev All Oracle logic is executed by the unifiedOracleAggregator.
    /// @param _value The address of the OracleAggregator contract.
    function setOracleAggregator(address _value) external onlyOwner {
        require(
            _value.isContract(),
            "LendingController: _value must be a contract."
        );
        address oldValue = address(oracleAggregator);
        oracleAggregator = IUnifiedOracleAggregator(_value);
        emit OracleAggregatorSet(oldValue, address(_value));
    }

    /// @notice Set a token as a base asset or disable it.
    /// @dev Set a token as a base asset or disable it. Base assets are required for creating new pairs, and they must have an active oracle in the OracleAggregator.
    /// @param _token ERC20 token address.
    /// @param _isBaseAsset True to enable the token as a base asset, false to disable it.
    function setBaseAsset(
        address _token,
        bool _isBaseAsset
    ) external onlyOwner {
        require(
            oracleAggregator.tokenSupported(_token),
            "LendingController: Token not supported by Oracle."
        );
        isBaseAsset[_token] = _isBaseAsset;
        emit BaseAssetSet(_token, _isBaseAsset);
    }

    /// @notice Prepare a pool for a token pair in the OracleAggregator using a specific cardinality.
    /// @param _tokenA The address of the first token in the pair.
    /// @param _tokenB The address of the second token in the pair.
    function preparePool(address _tokenA, address _tokenB) external {
        oracleAggregator.preparePool(
            _tokenA,
            _tokenB,
            minObservationCardinalityNext
        );
    }

    /// @notice set the min Amount which the user need to borrow
    /// @dev Set the minimum borrow amount for a token to prevent unprofitable liquidations due to gas costs exceeding liquidation fees.
    /// @param _token ERC20 token address.
    /// @param _value The minimum borrow amount.
    function setMinBorrow(address _token, uint256 _value) external onlyOwner {
        require(
            _token.isContract(),
            "LendingController: _token must be a contract."
        );
        uint256 oldValue = minBorrow[_token];
        minBorrow[_token] = _value;
        emit MinBorrowSet(_token, oldValue, _value);
    }

    /// @notice set a new deposit limit for a specific _token within one pair
    /// @param _pair Address of the lending pair.
    /// @param _token ERC20 token address.
    /// @param _value The deposit limit value.
    function setDepositLimit(
        address _pair,
        address _token,
        uint256 _value
    ) external onlyOwner {
        require(
            _pair.isContract() && _token.isContract(),
            "LendingController: _pair & _token must be a contract."
        );
        uint256 oldValue = depositLimit[_pair][_token];
        depositLimit[_pair][_token] = _value;
        emit DepositLimitSet(_pair, _token, oldValue, _value);
    }

    /// @notice Allow or disallow an address to act as a guardian
    /// @dev Guardians can perform specific operations in the contract.
    /// @param _guardian Address of the guardian.
    /// @param _value True to allow the address to act as a guardian, false to disallow it.
    function allowGuardian(address _guardian, bool _value) external onlyOwner {
        isGuardian[_guardian] = _value;
        emit GuardianAllowed(_guardian, _value);
    }

    /// @notice set a borrow for a specific token within a pair
    /// @param _pair Address of the lending pair.
    /// @param _token ERC20 token address.
    /// @param _value The borrow limit value.
    function setBorrowLimit(
        address _pair,
        address _token,
        uint256 _value
    ) external onlyOwner {
        require(
            _pair.isContract() && _token.isContract(),
            "LendingController: _pair & _token must be a contract."
        );
        uint256 oldValue = borrowLimit[_pair][_token];
        borrowLimit[_pair][_token] = _value;
        emit BorrowLimitSet(_pair, _token, oldValue, _value);
    }

    /// @notice Set an individual collateralization factor for a token.
    /// @dev Set the collateralization factor for a token, which determines how much a user can borrow against their collateral.
    /// @param _token The address of the token.
    /// @param _value The collateralization factor value.
    function setColFactor(address _token, uint256 _value) external onlyOwner {
        require(
            _value <= MAX_COL_FACTOR,
            "LendingController: _value <= MAX_COL_FACTOR"
        );
        require(
            _token.isContract(),
            "LendingController: _token must be a contract."
        );
        uint256 oldValue = colFactor[_token];
        colFactor[_token] = _value;
        emit ColFactorSet(_token, oldValue, _value);
    }

    /// @notice Set the default collateral factor for all new pairs created.
    /// @param _value The new default collateral factor.
    function setDefaultColFactor(uint256 _value) external {
        require(
            _value <= MAX_COL_FACTOR,
            "LendingController: _value <= MAX_COL_FACTOR"
        );
        uint256 oldValue = defaultColFactor;
        defaultColFactor = _value;
        emit DefaultColFactorSet(oldValue, _value);
    }

    /// @notice Set the minimum observation cardinality for pools in the OracleAggregator.
    /// @dev Set the minimum observation cardinality for pools in the OracleAggregator. This value is used to prepare pools in the `preparePool` function.
    /// @param _minObservationCardinalityNext The new minimum observation cardinality.
    function setMinObservationCardinalityNext(
        uint16 _minObservationCardinalityNext
    ) external onlyOwner {
        minObservationCardinalityNext = _minObservationCardinalityNext;
    }

    /// @notice Retrieve the liquidation fee for a token that goes to the total of both the protocol and the liquidator.
    /// @param _token The address of the token.
    /// @return uint256 The total liquidation fee for the token.
    function liqFeesTotal(
        address _token
    ) external view returns (uint256 /* liquidationFees in percent */) {
        return liqFeeSystem(_token) + liqFeeCaller(_token);
    }

    /// @notice Query if a token is secured via Chainlink oracle.
    /// @param _token The address of the token.
    /// @return bool.
    function hasChainlinkOracle(address _token) public view returns (bool) {
        return (oracleAggregator.linkOracles(_token) != address(0));
    }

    /// @notice Fetch the current token price for two tokens.
    /// @param _tokenA The address of the first token.
    /// @param _tokenB The address of the second token.
    /// @return (uint256, uint256) The price of 1 unit of _tokenA and _tokenB in terms of ETH, respectively.
    function tokenPrices(
        address _tokenA,
        address _tokenB
    )
        external
        view
        override
        returns (
            uint256 /* price of `_tokenA` in ETH */,
            uint256 /* price of `_tokenB` in ETH */
        )
    {
        return (oracleAggregator.tokenPrices(_tokenA, _tokenB));
    }

    /// @notice Check if a token is supported by the OracleAggregator and can be used in a LendingPair.
    /// @param _token The address of the token.
    /// @return bool True if the token is supported, false otherwise.
    function tokenSupported(
        address _token
    ) external view override returns (bool /* tokenSupported */) {
        return oracleAggregator.tokenSupported(_token);
    }

    /// @notice Fetch the current price for 1 wei of a token in terms of ETH using the OracleAggregator.
    /// @param _token The address of the token.
    /// @return uint256 The current token price.
    function tokenPrice(
        address _token
    ) public view override returns (uint256 /* price of `_token` in ETH */) {
        return oracleAggregator.tokenPrice(_token);
    }

    /// @notice define power of override function
    /// @dev needed to import interface
    function owner()
        public
        view
        override(IOwnable, Ownable)
        returns (address /* owner address */)
    {
        return Ownable.owner();
    }

    function acceptOwnership() public override(IOwnable, Ownable2Step) {
        return Ownable2Step.acceptOwnership();
    }

    function transferOwnership(
        address newOwner
    ) public override(IOwnable, Ownable2Step) {
        return Ownable2Step.transferOwnership(newOwner);
    }

    /// @notice Retrieve the liquidation fee for a token that goes to the protocol.
    /// @param _token The address of the token.
    /// @return uint256 The liquidation fee for the token.
    function liqFeeSystem(
        address _token
    )
        public
        view
        override
        returns (uint256 /* liquidation fee going to the system in percent */)
    {
        return
            liqFeeSystemToken[_token] > 0
                ? liqFeeSystemToken[_token]
                : liqFeeSystemDefault;
    }

    /// @notice Retrieve the liquidation fee for a token that goes to the liquidator.
    /// @param _token The address of the token.
    /// @return uint256 The liquidation fee for the token.
    function liqFeeCaller(
        address _token
    )
        public
        view
        override
        returns (
            uint256 /* liquidation fee going to the liquidator in percent */
        )
    {
        return
            liqFeeCallerToken[_token] > 0
                ? liqFeeCallerToken[_token]
                : liqFeeCallerDefault;
    }
}