// SPDX-License-Identifier: UNLICENSED

// Copyright (c) FloraLoans - All rights reserved
// https://twitter.com/Flora_Loans

pragma solidity ^0.8.6;

import "./interfaces/IUnifiedOracleAggregator.sol";
import "./interfaces/ILendingController.sol";
import "./external/SafeOwnable.sol";
import "./external/AddressLibrary.sol";

/// @title LendingController - this is the control center for flora
/// @author 0xdev and flora.loans
contract LendingController is ILendingController, SafeOwnable {
    using AddressLibrary for address;

    uint256 private constant MAX_COL_FACTOR = 99e18;
    uint256 private constant MAX_LIQ_FEES = 50e18;
    uint256 public defaultColFactor = 50e18;
    uint16 public minObservationCardinalityNext = 1800; //Arbitrum

    IUnifiedOracleAggregator public oracleAggregator;

    bool public override depositsEnabled;
    bool public override borrowingEnabled;

    uint256 public liqFeeCallerDefault;
    uint256 public liqFeeSystemDefault;
    uint256 public override uniMinOutputPct; // 95e18 = 99%

    mapping(address => bool) public isGuardian;
    mapping(address => mapping(address => uint256))
        public
        override depositLimit;
    mapping(address => mapping(address => uint256)) public override borrowLimit;
    mapping(address => uint256) public liqFeeCallerToken; // 1e18  = 1%
    mapping(address => uint256) public liqFeeSystemToken; // 1e18  = 1%

    mapping(address => uint256) public override colFactor; // 99e18 = 99%
    mapping(address => uint256) public override minBorrow;
    mapping(address => bool) public isBaseAsset; // Pairs can only be created against those assets

    event SetOracleAggregator(address indexed oracleAggregator);
    event NewColFactor(address indexed token, uint256 value);
    event NewDefaultColFactor(uint256 value);
    event NewDepositLimit(
        address indexed pair,
        address indexed token,
        uint256 value
    );
    event NewBorrowLimit(
        address indexed pair,
        address indexed token,
        uint256 value
    );
    event ChangeBaseAsset(address indexed token, bool isBaseAsset);
    event AllowGuardian(address indexed guardian, bool value);
    event DepositsEnabled(bool value);
    event BorrowingEnabled(bool value);
    event NewLiqParamsToken(
        address indexed token,
        uint256 liqFeeSystem,
        uint256 liqFeeCaller
    );
    event NewLiqParamsDefault(uint256 liqFeeSystem, uint256 liqFeeCaller);
    event NewUniMinOutputPct(uint256 value);
    event NewMinBorrow(address indexed token, uint256 value);

    /// @notice restrict operations to guardians
    modifier onlyGuardian() {
        require(
            isGuardian[msg.sender],
            "LendingController: caller is not a guardian"
        );
        _;
    }

    /// @dev dev need to verify minObservationCardinalityNext, which are network specific
    /// @dev MAX_COL_FACTOR, MAX_LIQ_FEES, defaultColFactor initialized at variable declaration
    constructor(
        uint256 _liqFeeSystemDefault,
        uint256 _liqFeeCallerDefault,
        uint256 _uniMinOutputPct
    ) {
        require(
            _liqFeeSystemDefault + _liqFeeCallerDefault <= MAX_LIQ_FEES,
            "LendingController: fees too high"
        );

        liqFeeSystemDefault = _liqFeeSystemDefault;
        liqFeeCallerDefault = _liqFeeCallerDefault;
        uniMinOutputPct = _uniMinOutputPct; // Proposed: 95e19 (5% Slippage)
        depositsEnabled = true;
        borrowingEnabled = true;
    }

    /// @notice set the liquidation parameters for an individual token
    /// @dev during liquidation the lending Pair will query the liqidationParameters for each individual token from the LendingController
    function setLiqParamsToken(
        address _token,
        uint256 _liqFeeSystem,
        uint256 _liqFeeCaller
    ) external onlyOwner {
        require(
            _liqFeeCaller + _liqFeeSystem <= MAX_LIQ_FEES,
            "LendingController: fees too high"
        );
        _requireContract(_token);

        liqFeeSystemToken[_token] = _liqFeeSystem;
        liqFeeCallerToken[_token] = _liqFeeCaller;

        emit NewLiqParamsToken(_token, _liqFeeSystem, _liqFeeCaller);
    }

    /// @notice set the default liquidation parameters
    /// @dev during liquidation the lending Pair will query the liqidationParameters for each individual token from the LendingController
    /// @dev tokens without specific parameters set will default to this
    function setLiqParamsDefault(uint256 _liqFeeSystem, uint256 _liqFeeCaller)
        external
        onlyOwner
    {
        require(
            _liqFeeCaller + _liqFeeSystem <= MAX_LIQ_FEES,
            "LendingController: fees too high"
        );

        liqFeeSystemDefault = _liqFeeSystem;
        liqFeeCallerDefault = _liqFeeCaller;

        emit NewLiqParamsDefault(_liqFeeSystem, _liqFeeCaller);
    }

    /// @notice set the OracleAggegator address. Can use Chainlink as well as uniswap TWAP oracles
    /// @dev all Oracle logic is executed by the unifiedOracleAggregator
    function setOracleAggregator(address _value) external onlyOwner {
        _requireContract(_value);
        oracleAggregator = IUnifiedOracleAggregator(_value);
        emit SetOracleAggregator(address(_value));
    }

    /// @notice enable or disables a token to be used as a base asset. New pairs must necessarily include at least one base asset
    /// @notice the base asset must have an active oracle set in the OracleAggregator
    /// @param _token ERC20
    /// @param _isBaseAsset bool: true - set as base asset, false - disable as base asset
    function setBaseAsset(address _token, bool _isBaseAsset) public {
        require(
            oracleAggregator.tokenSupported(_token) == true,
            "LendingController: Oracle not found"
        );
        isBaseAsset[_token] = _isBaseAsset;
        emit ChangeBaseAsset(_token, _isBaseAsset);
    }

    /// @notice Call the OracleAggregators prepare Pool function with a specific cardinality
    /// @dev Will revert if there are no pools available for this pair combination
    /// @param _tokenA One of the pair's tokens
    /// @param _tokenB The other of the pair's tokens
    function preparePool(address _tokenA, address _tokenB) public {
        oracleAggregator.preparePool(
            _tokenA,
            _tokenB,
            minObservationCardinalityNext
        );
    }

    /// @notice set the min Amount which the user need to borrow
    /// @dev this is included to prevent non profitable liquidations due to gas costs exceeding liquidation fees
    function setMinBorrow(address _token, uint256 _value) external onlyOwner {
        _requireContract(_token);
        minBorrow[_token] = _value;
        emit NewMinBorrow(_token, _value);
    }

    /// @notice set a new deposit limit for a specific _token within one pair
    function setDepositLimit(
        address _pair,
        address _token,
        uint256 _value
    ) external onlyOwner {
        _requireContract(_pair);
        _requireContract(_token);
        depositLimit[_pair][_token] = _value;
        emit NewDepositLimit(_pair, _token, _value);
    }

    /// @notice add a new guardian, can only be called by the owner
    function allowGuardian(address _guardian, bool _value) external onlyOwner {
        isGuardian[_guardian] = _value;
        emit AllowGuardian(_guardian, _value);
    }

    /// @notice set a borrow for a specific token within a pair
    function setBorrowLimit(
        address _pair,
        address _token,
        uint256 _value
    ) external onlyOwner {
        _requireContract(_pair);
        _requireContract(_token);
        borrowLimit[_pair][_token] = _value;
        emit NewBorrowLimit(_pair, _token, _value);
    }

    /// @notice set the slippage tolerance. Important for liquidations
    /// @dev trade off between negative effect for users due to high slippage and not being able to liquidate large positions
    function setUniMinOutputPct(uint256 _value) external onlyOwner {
        uniMinOutputPct = _value;
        emit NewUniMinOutputPct(_value);
    }

    /// @notice set an individual col factor for a token
    function setColFactor(address _token, uint256 _value) external onlyOwner {
        require(
            _value <= MAX_COL_FACTOR,
            "LendingController: _value <= MAX_COL_FACTOR"
        );
        _requireContract(_token);
        colFactor[_token] = _value;
        emit NewColFactor(_token, _value);
    }

    /// @notice Sets the default col factor which will be adpoted by all subsequently created pairs
    /// @dev Need to have a var defaultColFactor and set colfactor[token] = defaultColFactor
    /// @dev or implement a logic: if colFactor[token] === 0 return defaultColFactor
    function setDefaultColFactor(uint256 _value) external {
        require(
            _value <= MAX_COL_FACTOR,
            "LendingController: _value <= MAX_COL_FACTOR"
        );
        defaultColFactor = _value;
        emit NewDefaultColFactor(_value);
    }

    /// @notice Set min the observations for the uni oracle
    /// @notice Added for permissionless pair creation
    function setMinObservationCardinalityNext(
        uint16 _minObservationCardinalityNext
    ) public onlyOwner {
        minObservationCardinalityNext = _minObservationCardinalityNext;
    }

    /// @notice liquidation fee going to the protocol
    /// @return current liquidation fee for _token
    function liqFeeSystem(address _token)
        public
        view
        override
        returns (uint256)
    {
        return
            liqFeeSystemToken[_token] > 0
                ? liqFeeSystemToken[_token]
                : liqFeeSystemDefault;
    }

    /// @notice liquidation fee going to the liquidator
    /// @return current liquidation fee for _token
    function liqFeeCaller(address _token)
        public
        view
        override
        returns (uint256)
    {
        return
            liqFeeCallerToken[_token] > 0
                ? liqFeeCallerToken[_token]
                : liqFeeCallerDefault;
    }

    /// @notice total liquidation fee
    /// @return total liquidation fee (protocol+liquidator) for _token
    function liqFeesTotal(address _token) external view returns (uint256) {
        return liqFeeSystem(_token) + liqFeeCaller(_token);
    }

    /// @notice Fetches the current token price for 1 unit of the token, priced in ETH
    /// @dev Link or Uni Oracle is determined by the oracleAggregator contract (Oracle Aggregator)
    /// @param _token token for which the Oracle price should be received
    /// @return the price of 1 _token in terms of ETH
    /// @dev 1 means the minimal unit representation of the token
    /// Todo: Test this for edge cases. One token not set, both set in controller, etc...
    function tokenPrice(address _token) public view override returns (uint256) {
        return oracleAggregator.tokenPrice(_token);
    }

    /// @notice Fetches the current token price for two tokens
    /// @return the price of 1 unit of _token in terms of ETH
    /// @dev 1 means the minimal unit representation of the token
    function tokenPrices(address _tokenA, address _tokenB)
        external
        view
        override
        returns (uint256, uint256)
    {
        return (oracleAggregator.tokenPrices(_tokenA, _tokenB));
    }

    /// @notice returns if this token can be used in a LendingPair
    /// @return true / false
    function tokenSupported(address _token)
        external
        view
        override
        returns (bool)
    {
        return oracleAggregator.tokenSupported(_token);
    }

    /// @notice internal function requiring that the address is a contract
    function _requireContract(address _value) internal view {
        require(
            _value.isContract(),
            "LendingController: address must be a contract"
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./IPriceOracle.sol";
import "../external/SafeOwnable.sol";

interface IExternalOracle {
    function price(address _token) external view returns (uint256);

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

/// @title Oracle aggergator for uni and link oracles
/// @author flora.loans
/// @notice Owner can set Chainlink oracles for specific tokens
/// @notice returns the token price from chainlink oracle (if available) otherwise the uni oracle will be used
/// @dev
/// @custom:this contract is configured for Arbitrum mainnet
interface IUnifiedOracleAggregator {
    function setOracle(address, IExternalOracle) external;

    function preparePool(
        address,
        address,
        uint16
    ) external;

    function tokenSupported(address) external view returns (bool);

    function tokenPrice(address) external view returns (uint256);

    function tokenPrices(address, address)
        external
        view
        returns (uint256, uint256);

    /// @dev Not used in any code to save gas. But useful for external usage.
    function convertTokenValues(
        address,
        address,
        uint256
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.6;

import "./IOwnable.sol";
import "./IUnifiedOracleAggregator.sol";

interface ILendingController is IOwnable {
    function oracleAggregator()
        external
        view
        returns (IUnifiedOracleAggregator);

    function liqFeeSystem(address _token) external view returns (uint256);

    function liqFeeCaller(address _token) external view returns (uint256);

    function uniMinOutputPct() external view returns (uint256);

    function colFactor(address _token) external view returns (uint256);

    function defaultColFactor() external view returns (uint256);

    function depositLimit(address _lendingPair, address _token)
        external
        view
        returns (uint256);

    function borrowLimit(address _lendingPair, address _token)
        external
        view
        returns (uint256);

    function depositsEnabled() external view returns (bool);

    function borrowingEnabled() external view returns (bool);

    function tokenPrice(address _token) external view returns (uint256);

    function minBorrow(address _token) external view returns (uint256);

    function tokenPrices(address _tokenA, address _tokenB)
        external
        view
        returns (uint256, uint256);

    function tokenSupported(address _token) external view returns (bool);

    function isBaseAsset(address _token) external view returns (bool);

    function minObservationCardinalityNext() external view returns (uint16);

    function preparePool(address _tokenA, address _tokenB) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.6;

import "../interfaces/IOwnable.sol";

contract SafeOwnable is IOwnable {
    uint public constant RENOUNCE_TIMEOUT = 1 hours;

    address public override owner;
    address public pendingOwner;
    uint public renouncedAt;

    event OwnershipTransferInitiated(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipTransferConfirmed(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferConfirmed(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function transferOwnership(address _newOwner) external override onlyOwner {
        require(
            _newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferInitiated(owner, _newOwner);
        pendingOwner = _newOwner;
    }

    function acceptOwnership() external override {
        require(
            msg.sender == pendingOwner,
            "Ownable: caller is not pending owner"
        );
        emit OwnershipTransferConfirmed(msg.sender, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    function initiateRenounceOwnership() external onlyOwner {
        require(renouncedAt == 0, "Ownable: already initiated");
        renouncedAt = block.timestamp;
    }

    function acceptRenounceOwnership() external onlyOwner {
        require(renouncedAt > 0, "Ownable: not initiated");
        require(
            block.timestamp - renouncedAt > RENOUNCE_TIMEOUT,
            "Ownable: too early"
        );
        owner = address(0);
        pendingOwner = address(0);
        renouncedAt = 0;
    }

    function cancelRenounceOwnership() external onlyOwner {
        require(renouncedAt > 0, "Ownable: not initiated");
        renouncedAt = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library AddressLibrary {
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint);

    function decimals() external view returns (uint8);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.6;

interface IPriceOracle {
    function tokenPrice(address _token) external view returns (uint256);

    function tokenSupported(address _token) external view returns (bool);

    function convertTokenValues(
        address _fromToken,
        address _toToken,
        uint256 _amount
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.6;

interface IOwnable {
    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;

    function acceptOwnership() external;
}