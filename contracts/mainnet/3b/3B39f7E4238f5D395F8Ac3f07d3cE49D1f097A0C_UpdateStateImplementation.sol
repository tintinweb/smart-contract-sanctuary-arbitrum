// SPDX-License-Identifier: Apache-2.0.
pragma solidity >=0.8.0 <0.9.0;


import "./UpdateStateStorage.sol";
import "../utils/SafeMath.sol";
import "../utils/SafeERC20.sol";
import "../vault/IVault.sol";

contract ForcedAction is UpdateStateStorage{

    using SafeMath for uint256;
    using SafeMath for int256;
    using SafeERC20 for IERC20;

    uint256 constant public UONE = 1E18;
    int256 constant public  ONE = 1E18;
    int256 constant public  FUNDING_PRECISION = 1E8;

    IVault immutable public vault;

    event LogBalanceChange(
        address account,
        address asset,
        int256 balanceDiff
    );

    event LogPositionChange(
        address account,
        bytes32 symbolId,
        int64 volume,
        int64 lastCumulativeFundingPerVolume,
        int128 entryCost
    );

    constructor(address _vault) {
        vault = IVault(_vault);
    }

    function forcedWithdraw(address asset) _reentryLock_ external
    {
        require(isFreezed, "forced: only at freezed");
        address account = msg.sender;
        require(holdPositions[account] == 0, "forced: exist active positions");
        int256 balance = balances[account][asset];
        require(balance>0, "forced: not enough balance");

        balances[account][asset] = 0;
        emit LogBalanceChange(account, asset, -balance);

        if (asset == address(0)) {
            vault.transferOut(account, asset, balance.itou());
        } else {
            vault.transferOut(account, asset, balance.itou().rescale(18, IERC20(asset).decimals()));
        }
    }

    function _updatePnlAndFunding(address account, AccountPosition memory pos, SymbolInfo memory symbolInfo, SymbolStats memory symbolStats, int32 tradeVolume) internal {
        int256 pricePrecision = symbolInfo.pricePrecision.utoi();
        int256 volumePrecision = symbolInfo.volumePrecision.utoi();
        int256 balanceDiff;
        {
            int256 funding = -int256(symbolStats.cumulativeFundingPerVolume - pos.lastCumulativeFundingPerVolume) * ONE / pricePrecision / volumePrecision / FUNDING_PRECISION * int256(pos.volume) * ONE / volumePrecision / ONE;
            int256 pnl = - (int256(pos.entryCost) * ONE * int256(tradeVolume).abs() / int256(pos.volume).abs() / pricePrecision / volumePrecision +
                 int256(tradeVolume) * ONE / volumePrecision * int256(symbolStats.indexPrice) * ONE / pricePrecision / ONE);
            balanceDiff = funding + pnl;
        }
        int256 entryCostAfter = int256(pos.entryCost) - int256(pos.entryCost) * int256(tradeVolume).abs() / int256(pos.volume).abs();

        address asset = symbolInfo.marginAsset;
        bytes32 symbolId = symbolInfo.symbolId;
        balances[account][asset] += balanceDiff;
        emit LogBalanceChange(account, asset, balanceDiff);

        accountPositions[account][symbolId] = AccountPosition({
                    volume: int64(pos.volume + tradeVolume),
                    lastCumulativeFundingPerVolume: symbolStats.cumulativeFundingPerVolume,
                    entryCost: int128(entryCostAfter)
                });
        emit LogPositionChange(account, symbolId, int64(pos.volume + tradeVolume), symbolStats.cumulativeFundingPerVolume, int128(entryCostAfter));
    }

    function forceTrade(address target, bytes32 symbolId, int32 tradeVolume) external _reentryLock_ {
        require(isFreezed, "forced: only at freezed");

        address account = msg.sender;
        AccountPosition memory pos = accountPositions[account][symbolId];
        AccountPosition memory targetPos = accountPositions[target][symbolId];

        require(pos.volume != 0 && targetPos.volume != 0, "forced: no position");
        require((pos.volume > 0 && tradeVolume < 0 && int256(pos.volume).abs() >= int256(tradeVolume).abs()) ||
            (pos.volume < 0 && tradeVolume > 0 && int256(pos.volume).abs() <= int256(tradeVolume).abs()), "forced: only close position");

        SymbolInfo memory symbolInfo = symbols[symbolId];
        SymbolStats memory symbolStats = symbolStats[symbolId];
        require(int256(tradeVolume) % symbolInfo.minVolume.utoi() == 0, "forced: invalid trade volume");

        if (pos.volume == -tradeVolume) {
                holdPositions[account] -= 1;
        }
        if (targetPos.volume == tradeVolume) {
                holdPositions[target] -= 1;
        }

        _updatePnlAndFunding(account, pos, symbolInfo, symbolStats, tradeVolume);
        _updatePnlAndFunding(target, targetPos, symbolInfo, symbolStats, -tradeVolume);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./UpdateStateStorage.sol";

contract UpdateState is UpdateStateStorage {
    event NewImplementation(address newImplementation);

    function setImplementation(address newImplementation) external _onlyAdmin_ {
        implementation = newImplementation;
        emit NewImplementation(newImplementation);
    }

    receive() external payable {}

    fallback() external payable {
        address imp = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), imp, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../utils/SafeERC20.sol";
import "../utils/NameVersion.sol";
import "./UpdateStateStorage.sol";
import "./UpdateState.sol";
import "./ForcedAction.sol";

contract UpdateStateImplementation is ForcedAction, NameVersion {
    using SafeERC20 for IERC20;

    // shift the 1s by (256 - 64) to get (256 - 64) 0s followed by 64 1s
    uint256 public constant PRICE_BITMASK = type(uint256).max >> (256 - 64);

    uint256 public constant FREEZE_LIMIT = 7 days;

    uint256 public constant GRACE_PERIOD = 7 days;

    event SetOperator(address operator, bool isActive);

    event AddSymbol(
        string symbolName,
        bytes32 symbolId,
        uint256 minVolume,
        uint256 priceDecimals,
        uint256 volumeDecimals,
        address marginAsset
    );

    event UpdateSymbol(
        string symbolName,
        bytes32 symbolId,
        uint256 minVolume,
        uint256 priceDecimals,
        uint256 volumeDecimals,
        address marginAsset
    );

    event DelistSymbol(string symbolName, bytes32 symbolId);

    constructor(
        address _vault
    ) ForcedAction(_vault) NameVersion("UpdateState", "1.0.0") {}

    // ========================================================
    // Admin Functions
    // ========================================================
    function setOperator(
        address operator_,
        bool isActive
    ) external _onlyAdmin_ {
        isOperator[operator_] = isActive;
        emit SetOperator(operator_, isActive);
    }

    // ========================================================
    // External Calls For Vault
    // ========================================================
    function updateBalance(
        address account,
        address asset,
        int256 balanceDiff
    ) external {
        require(msg.sender == address(vault), "update: not vault");
        balances[account][asset] += balanceDiff;
        emit LogBalanceChange(account, asset, balanceDiff);
    }

    function updatePosition(uint256[] calldata positionInput) external {
        require(msg.sender == address(vault), "update: not vault");
        _updateAccountPosition(positionInput);
    }

    function resetFreezeStart() external {
        require(msg.sender == address(vault), "update: not vault");
        if (isFreezeStart) isFreezeStart = false;
    }

    // ========================================================
    // Symbol Management
    // ========================================================
    function addSymbol(
        string calldata _symbolName,
        uint256 _minVolume,
        uint256 _pricePrecision,
        uint256 _volumePrecision,
        address _marginAsset
    ) external _onlyOperator {
        bytes32 _symbolId = keccak256(abi.encodePacked(_symbolName));
        require(
            symbols[_symbolId].symbolId == bytes32(0),
            "update: addSymbol already exist"
        );
        SymbolInfo memory symbolInfo = SymbolInfo({
            symbolName: _symbolName,
            symbolId: _symbolId,
            minVolume: _minVolume,
            pricePrecision: _pricePrecision,
            volumePrecision: _volumePrecision,
            marginAsset: _marginAsset,
            delisted: false
        });
        symbols[_symbolId] = symbolInfo;
        indexedSymbols.push(symbolInfo);

        emit AddSymbol(
            _symbolName,
            _symbolId,
            _minVolume,
            _pricePrecision,
            _volumePrecision,
            _marginAsset
        );
    }

    function updateSymbol(
        string calldata _symbolName,
        uint256 _minVolume,
        uint256 _pricePrecision,
        uint256 _volumePrecision,
        address _marginAsset
    ) external _onlyOperator {
        bytes32 _symbolId = keccak256(abi.encodePacked(_symbolName));
        require(
            symbols[_symbolId].symbolId != bytes32(0),
            "update: updateSymbol not exist"
        );
        SymbolInfo memory symbolInfo = SymbolInfo({
            symbolName: _symbolName,
            symbolId: _symbolId,
            minVolume: _minVolume,
            pricePrecision: _pricePrecision,
            volumePrecision: _volumePrecision,
            marginAsset: _marginAsset,
            delisted: false
        });
        symbols[_symbolId] = symbolInfo;
        emit UpdateSymbol(
            _symbolName,
            _symbolId,
            _minVolume,
            _pricePrecision,
            _volumePrecision,
            _marginAsset
        );
    }

    function delistSymbol(bytes32 symbolId) external _onlyOperator {
        require(
            symbols[symbolId].minVolume != 0 && !symbols[symbolId].delisted,
            "update: symbol not exist or delisted"
        );
        symbols[symbolId].delisted = true;
        emit DelistSymbol(symbols[symbolId].symbolName, symbolId);
    }

    // ========================================================
    // Forced Functions
    // ========================================================
    function requestFreeze() external _notFreezed {
        uint256 duration = block.timestamp - lastUpdateTimestamp;
        require(
            duration > FREEZE_LIMIT,
            "update: last update time less than freeze limit"
        );
        isFreezeStart = true;
        freezeStartTimestamp = block.timestamp;
    }

    function activateFreeze() external _notFreezed {
        require(isFreezeStart, "update: freeze request not started");
        uint256 duration = block.timestamp - freezeStartTimestamp;
        require(
            duration > GRACE_PERIOD,
            "update: freeze time did not past grace period"
        );
        isFreezed = true;
    }

    // ========================================================
    // batch update
    // ========================================================
    function batchUpdate(
        uint256[] calldata priceInput,
        uint256[] calldata fundingInput,
        int256[] calldata balanceInput,
        uint256[] calldata positionInput,
        uint256 batchId,
        uint256 endTimestamp
    ) external _notFreezed _onlyOperator {
        require(isOperator[msg.sender], "update: operator only");
        require(lastBatchId == batchId - 1, "update: invalid batch id");

        if (isFreezeStart) isFreezeStart = false;

        _updateSymbols(priceInput, fundingInput);
        _updateAccountBalance(balanceInput);
        _updateAccountPosition(positionInput);

        lastBatchId += 1;
        lastUpdateTimestamp = block.timestamp;
        lastEndTimestamp = endTimestamp;
    }

    function _updateSymbols(
        uint256[] calldata _indexPrices,
        uint256[] calldata _cumulativeFundingPerVolumes
    ) internal {
        require(
            _indexPrices.length == _cumulativeFundingPerVolumes.length,
            "update: invalid length"
        );

        for (uint256 i = 0; i < _indexPrices.length; i++) {
            uint256 indexPrice = _indexPrices[i];
            uint256 cumulativeFundingPerVolume = _cumulativeFundingPerVolumes[
                i
            ];
            for (uint256 j = 0; j < 4; j++) {
                uint256 index = i * 4 + j;
                if (index >= indexedSymbols.length) {
                    return;
                }
                uint256 startBit = 64 * j;
                int256 _indexPrice = int256(
                    (indexPrice >> startBit) & PRICE_BITMASK
                );
                if (_indexPrice == 0) continue;
                int256 _cumulativeFundingPerVolume = int256(
                    (cumulativeFundingPerVolume >> startBit) & PRICE_BITMASK
                );
                bytes32 symbolId = indexedSymbols[index].symbolId;
                symbolStats[symbolId] = SymbolStats({
                    indexPrice: int64(_indexPrice),
                    cumulativeFundingPerVolume: int64(
                        _cumulativeFundingPerVolume
                    )
                });
            }
        }
    }

    function _updateAccountBalance(int256[] calldata balanceInput) internal {
        require(
            balanceInput.length % 3 == 0,
            "update: invalid balanceInput length"
        );
        uint256 nUpdates = balanceInput.length / 3;
        uint256 offset = 0;
        for (uint256 i = 0; i < nUpdates; i++) {
            address account = address(uint160(uint256(balanceInput[offset])));
            address asset = address(uint160(uint256(balanceInput[offset + 1])));
            int256 balanceDiff = balanceInput[offset + 2];

            balances[account][asset] += balanceDiff;
            emit LogBalanceChange(account, asset, balanceDiff);
            offset += 3;
        }
    }

    function _updateAccountPosition(uint256[] calldata positionInput) internal {
        require(
            positionInput.length % 3 == 0,
            "update: invalid positionInput length"
        );
        uint256 nUpdates = positionInput.length / 3;
        uint256 offset = 0;
        for (uint256 i = 0; i < nUpdates; i++) {
            address account = address(uint160(uint256(positionInput[offset])));
            bytes32 symbolId = bytes32(uint256(positionInput[offset + 1]));
            uint256 positionStat = positionInput[offset + 2];

            int256 _volume = int256(positionStat & ((1 << 64) - 1));
            int256 _lastCumulativeFundingPerVolume = int256(
                (positionStat >> 64) & ((1 << 128) - 1)
            );
            int256 _entryCost = int256(
                (positionStat >> 128) & ((1 << 128) - 1)
            );

            if (
                accountPositions[account][symbolId].volume == 0 && _volume != 0
            ) {
                holdPositions[account] += 1;
            } else if (
                accountPositions[account][symbolId].volume != 0 && _volume == 0
            ) {
                holdPositions[account] -= 1;
            }
            accountPositions[account][symbolId] = AccountPosition({
                volume: int64(_volume),
                lastCumulativeFundingPerVolume: int64(
                    _lastCumulativeFundingPerVolume
                ),
                entryCost: int128(_entryCost)
            });
            emit LogPositionChange(
                account,
                symbolId,
                int64(_volume),
                int64(_lastCumulativeFundingPerVolume),
                int128(_entryCost)
            );
            offset += 3;
        }
    }

    function getSymbolNum() external view returns (uint256) {
        return indexedSymbols.length;
    }

    function getSymbolNames(
        uint256 start,
        uint256 end
    ) external view returns (string[] memory) {
        string[] memory symbolNames = new string[](end - start);
        for (uint256 i = start; i < end; i++) {
            symbolNames[i] = indexedSymbols[i].symbolName;
        }
        return symbolNames;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../utils/Admin.sol";

abstract contract UpdateStateStorage is Admin {

    address public implementation;

    bool internal _mutex;

    modifier _reentryLock_() {
        require(!_mutex, "update: reentry");
        _mutex = true;
        _;
        _mutex = false;
    }

    uint256 public lastUpdateTimestamp;

    uint256 public lastBatchId;

    uint256 public lastEndTimestamp;

    bool public isFreezed;

    bool public isFreezeStart;

    uint256 public freezeStartTimestamp;

    modifier _notFreezed() {
        require(!isFreezed, "update: freezed");
        _;
    }

    modifier _onlyOperator() {
        require(isOperator[msg.sender], "update: only operator");
        _;
    }

    struct SymbolInfo {
        string symbolName;
        bytes32 symbolId;
        uint256 minVolume;
        uint256 pricePrecision;
        uint256 volumePrecision;
        address marginAsset;
        bool delisted;
    }

    struct SymbolStats {
        int64 indexPrice;
        int64 cumulativeFundingPerVolume;
    }

    struct AccountPosition {
        int64 volume;
        int64 lastCumulativeFundingPerVolume;
        int128 entryCost;
    }

    mapping(address => bool) public isOperator;

    // indexed symbols for looping
    SymbolInfo[] public indexedSymbols;

    // symbolId => symbolInfo
    mapping (bytes32 => SymbolInfo) public symbols;

    // symbolId => symbolStats
    mapping(bytes32 => SymbolStats) public symbolStats;

    // user => asset => balance
    mapping(address => mapping(address => int256)) public balances;

    // account => symbolId => AccountPosition
    mapping(address => mapping(bytes32 => AccountPosition)) public accountPositions;

    // account => hold position #
    mapping(address => int256) public holdPositions;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IAdmin.sol';

abstract contract Admin is IAdmin {

    address public admin;

    modifier _onlyAdmin_() {
        require(msg.sender == admin, 'Admin: only admin');
        _;
    }

    constructor () {
        admin = msg.sender;
        emit NewAdmin(admin);
    }

    function setAdmin(address newAdmin) external _onlyAdmin_ {
        admin = newAdmin;
        emit NewAdmin(newAdmin);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IAdmin {

    event NewAdmin(address indexed newAdmin);

    function admin() external view returns (address);

    function setAdmin(address newAdmin) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface INameVersion {

    function nameId() external view returns (bytes32);

    function versionId() external view returns (bytes32);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './INameVersion.sol';

/**
 * @dev Convenience contract for name and version information
 */
abstract contract NameVersion is INameVersion {

    bytes32 public immutable nameId;
    bytes32 public immutable versionId;

    constructor (string memory name, string memory version) {
        nameId = keccak256(abi.encodePacked(name));
        versionId = keccak256(abi.encodePacked(version));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./IERC20.sol";
import "./Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library SafeMath {

    uint256 constant UMAX = 2 ** 255 - 1;
    int256  constant IMIN = -2 ** 255;

    function utoi(uint256 a) internal pure returns (int256) {
        require(a <= UMAX, 'SafeMath.utoi: overflow');
        return int256(a);
    }

    function itou(int256 a) internal pure returns (uint256) {
        require(a >= 0, 'SafeMath.itou: underflow');
        return uint256(a);
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != IMIN, 'SafeMath.abs: overflow');
        return a >= 0 ? a : -a;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a <= b ? a : b;
    }

    // rescale a uint256 from base 10**decimals1 to 10**decimals2
    function rescale(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256) {
        return decimals1 == decimals2 ? a : a * 10**decimals2 / 10**decimals1;
    }

    // rescale towards zero
    // b: rescaled value in decimals2
    // c: the remainder
    function rescaleDown(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256 b, uint256 c) {
        b = rescale(a, decimals1, decimals2);
        c = a - rescale(b, decimals2, decimals1);
    }

    // rescale towards infinity
    // b: rescaled value in decimals2
    // c: the excessive
    function rescaleUp(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256 b, uint256 c) {
        b = rescale(a, decimals1, decimals2);
        uint256 d = rescale(b, decimals2, decimals1);
        if (d != a) {
            b += 1;
            c = rescale(b, decimals2, decimals1) - a;
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/INameVersion.sol';
import '../utils/IAdmin.sol';

interface IVault is INameVersion, IAdmin {

    function transferOut(address account, address asset, uint256 amount) external;
}