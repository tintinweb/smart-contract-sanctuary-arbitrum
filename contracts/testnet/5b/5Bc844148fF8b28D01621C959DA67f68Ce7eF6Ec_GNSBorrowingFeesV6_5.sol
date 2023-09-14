// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
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
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

interface ChainlinkFeedInterfaceV5 {
    function latestRoundData() external view returns (uint80, int, uint, uint, uint80);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface GNSBorrowingFeesInterfaceV6_5 {
    // Structs
    struct PairGroup {
        uint16 groupIndex;
        uint48 block;
        uint64 initialAccFeeLong; // 1e10 (%)
        uint64 initialAccFeeShort; // 1e10 (%)
        uint64 prevGroupAccFeeLong; // 1e10 (%)
        uint64 prevGroupAccFeeShort; // 1e10 (%)
        uint64 pairAccFeeLong; // 1e10 (%)
        uint64 pairAccFeeShort; // 1e10 (%)
        uint64 _placeholder; // might be useful later
    }
    struct Pair {
        PairGroup[] groups;
        uint32 feePerBlock; // 1e10 (%)
        uint64 accFeeLong; // 1e10 (%)
        uint64 accFeeShort; // 1e10 (%)
        uint48 accLastUpdatedBlock;
        uint48 feeExponent;
        uint lastAccBlockWeightedMarketCap; // 1e40
    }
    struct PairOi {
        uint72 long; // 1e10 (DAI)
        uint72 short; // 1e10 (DAI)
        uint72 max; // 1e10 (DAI)
        uint40 _placeholder; // might be useful later
    }
    struct Group {
        uint112 oiLong; // 1e10
        uint112 oiShort; // 1e10
        uint32 feePerBlock; // 1e10 (%)
        uint64 accFeeLong; // 1e10 (%)
        uint64 accFeeShort; // 1e10 (%)
        uint48 accLastUpdatedBlock;
        uint80 maxOi; // 1e10
        uint lastAccBlockWeightedMarketCap; // 1e40
    }
    struct InitialAccFees {
        uint64 accPairFee; // 1e10 (%)
        uint64 accGroupFee; // 1e10 (%)
        uint48 block;
        uint80 _placeholder; // might be useful later
    }
    struct PairParams {
        uint16 groupIndex;
        uint32 feePerBlock; // 1e10 (%)
        uint48 feeExponent;
        uint72 maxOi;
    }
    struct GroupParams {
        uint32 feePerBlock; // 1e10 (%)
        uint72 maxOi; // 1e10
        uint48 feeExponent;
    }
    struct BorrowingFeeInput {
        address trader;
        uint pairIndex;
        uint index;
        bool long;
        uint collateral; // 1e18 (DAI)
        uint leverage;
    }
    struct LiqPriceInput {
        address trader;
        uint pairIndex;
        uint index;
        uint openPrice; // 1e10
        bool long;
        uint collateral; // 1e18 (DAI)
        uint leverage;
    }
    struct PendingAccFeesInput {
        uint64 accFeeLong; // 1e10 (%)
        uint64 accFeeShort; // 1e10 (%)
        uint oiLong; // 1e18
        uint oiShort; // 1e18
        uint32 feePerBlock; // 1e10
        uint currentBlock;
        uint accLastUpdatedBlock;
        uint72 maxOi; // 1e10
        uint48 feeExponent;
        uint collateralPrecision;
    }

    // Events
    event PairParamsUpdated(
        uint indexed pairIndex,
        uint16 indexed groupIndex,
        uint32 feePerBlock,
        uint48 feeExponent,
        uint72 maxOi
    );
    event PairGroupUpdated(uint indexed pairIndex, uint16 indexed prevGroupIndex, uint16 indexed newGroupIndex);
    event GroupUpdated(uint16 indexed groupIndex, uint32 feePerBlock, uint72 maxOi, uint48 feeExponent);
    event TradeInitialAccFeesStored(
        address indexed trader,
        uint indexed pairIndex,
        uint index,
        uint64 initialPairAccFee,
        uint64 initialGroupAccFee
    );
    event TradeActionHandled(
        address indexed trader,
        uint indexed pairIndex,
        uint index,
        bool open,
        bool long,
        uint positionSizeDai // 1e18
    );
    event PairAccFeesUpdated(uint indexed pairIndex, uint currentBlock, uint64 accFeeLong, uint64 accFeeShort);
    event GroupAccFeesUpdated(uint16 indexed groupIndex, uint currentBlock, uint64 accFeeLong, uint64 accFeeShort);
    event GroupOiUpdated(
        uint16 indexed groupIndex,
        bool indexed long,
        bool indexed increase,
        uint112 amount,
        uint112 oiLong,
        uint112 oiShort
    );

    // Functions
    function getTradeLiquidationPrice(LiqPriceInput calldata) external view returns (uint); // PRECISION

    function getTradeBorrowingFee(BorrowingFeeInput memory) external view returns (uint); // 1e18 (DAI)

    function handleTradeAction(
        address trader,
        uint pairIndex,
        uint index,
        uint positionSizeDai, // 1e18 (collateral * leverage)
        bool open,
        bool long
    ) external;

    function withinMaxGroupOi(uint pairIndex, bool long, uint positionSizeDai) external view returns (bool);

    function getPairMaxOi(uint pairIndex) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface GNSPairInfosInterfaceV6 {
    // Trade initial acc fees
    struct TradeInitialAccFees {
        uint rollover; // 1e18 (DAI)
        int funding; // 1e18 (DAI)
        bool openedAfterUpdate;
    }

    function tradeInitialAccFees(address, uint, uint) external view returns (TradeInitialAccFees memory);

    function maxNegativePnlOnOpenP() external view returns (uint); // PRECISION (%)

    function storeTradeInitialAccFees(address trader, uint pairIndex, uint index, bool long) external;

    function getTradePriceImpact(
        uint openPrice, // PRECISION
        uint pairIndex,
        bool long,
        uint openInterest // 1e18 (DAI)
    )
        external
        view
        returns (
            uint priceImpactP, // PRECISION (%)
            uint priceAfterImpact // PRECISION
        );

    function getTradeRolloverFee(
        address trader,
        uint pairIndex,
        uint index,
        uint collateral // 1e18 (DAI)
    ) external view returns (uint);

    function getTradeFundingFee(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral, // 1e18 (DAI)
        uint leverage
    )
        external
        view
        returns (
            int // 1e18 (DAI) | Positive => Fee, Negative => Reward
        );

    function getTradeLiquidationPricePure(
        uint openPrice, // PRECISION
        bool long,
        uint collateral, // 1e18 (DAI)
        uint leverage,
        uint rolloverFee, // 1e18 (DAI)
        int fundingFee // 1e18 (DAI)
    ) external pure returns (uint);

    function getTradeLiquidationPrice(
        address trader,
        uint pairIndex,
        uint index,
        uint openPrice, // PRECISION
        bool long,
        uint collateral, // 1e18 (DAI)
        uint leverage
    ) external view returns (uint); // PRECISION

    function getTradeValue(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral, // 1e18 (DAI)
        uint leverage,
        int percentProfit, // PRECISION (%)
        uint closingFee // 1e18 (DAI)
    ) external returns (uint); // 1e18 (DAI)

    function manager() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.9.0;

/**
 * @title Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface IArbSys {
    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external pure returns (uint);

    function arbChainID() external view returns (uint);

    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty calldataForL1.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination) external payable returns (uint);

    /**
     * @notice Send a transaction to L1
     * @param destination recipient address on L1
     * @param calldataForL1 (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata calldataForL1) external payable returns (uint);

    /**
     * @notice get the number of transactions issued by the given external account or the account sequence number of the given contract
     * @param account target account
     * @return the number of transactions issued by the given external account or the account sequence number of the given contract
     */
    function getTransactionCount(address account) external view returns (uint256);

    /**
     * @notice get the value of target L2 storage slot
     * This function is only callable from address 0 to prevent contracts from being able to call it
     * @param account target account
     * @param index target index of storage slot
     * @return stotage value for the given account at the given index
     */
    function getStorageAt(address account, uint256 index) external view returns (uint256);

    /**
     * @notice check if current call is coming from l1
     * @return true if the caller of this was called directly from L1
     */
    function isTopLevelCall() external view returns (bool);

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
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param dest destination address
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address dest) external pure returns (address);

    /**
     * @notice get the caller's amount of available storage gas
     * @return amount of storage gas available to the caller
     */
    function getStorageGasAvailable() external view returns (uint);

    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint indexed uniqueId,
        uint indexed batchNumber,
        uint indexInBatch,
        uint arbBlockNum,
        uint ethBlockNum,
        uint timestamp,
        uint callvalue,
        bytes data
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGToken {
    function manager() external view returns (address);

    function admin() external view returns (address);

    function currentEpoch() external view returns (uint);

    function currentEpochStart() external view returns (uint);

    function currentEpochPositiveOpenPnl() external view returns (uint);

    function updateAccPnlPerTokenUsed(uint prevPositiveOpenPnl, uint newPositiveOpenPnl) external returns (uint);

    struct LockedDeposit {
        address owner;
        uint shares; // 1e18
        uint assetsDeposited; // 1e18
        uint assetsDiscount; // 1e18
        uint atTimestamp; // timestamp
        uint lockDuration; // timestamp
    }

    function getLockedDeposit(uint depositId) external view returns (LockedDeposit memory);

    function sendAssets(uint assets, address receiver) external;

    function receiveAssets(uint assets, address user) external;

    function distributeReward(uint assets) external;

    function currentBalanceDai() external view returns (uint);

    function tvl() external view returns (uint);

    function marketCap() external view returns (uint);

    function getPendingAccBlockWeightedMarketCap(uint currentBlock) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface NftInterfaceV5 {
    function balanceOf(address) external view returns (uint);

    function ownerOf(uint) external view returns (address);

    function transferFrom(address, address, uint) external;

    function tokenOfOwnerByIndex(address, uint) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface PairsStorageInterfaceV6 {
    enum FeedCalculation {
        DEFAULT,
        INVERT,
        COMBINE
    } // FEED 1, 1 / (FEED 1), (FEED 1)/(FEED 2)
    struct Feed {
        address feed1;
        address feed2;
        FeedCalculation feedCalculation;
        uint maxDeviationP;
    } // PRECISION (%)

    function incrementCurrentOrderId() external returns (uint);

    function updateGroupCollateral(uint, uint, bool, bool) external;

    function pairJob(uint) external returns (string memory, string memory, bytes32, uint);

    function pairFeed(uint) external view returns (Feed memory);

    function pairSpreadP(uint) external view returns (uint);

    function pairMinLeverage(uint) external view returns (uint);

    function pairMaxLeverage(uint) external view returns (uint);

    function groupMaxCollateral(uint) external view returns (uint);

    function groupCollateral(uint, bool) external view returns (uint);

    function guaranteedSlEnabled(uint) external view returns (bool);

    function pairOpenFeeP(uint) external view returns (uint);

    function pairCloseFeeP(uint) external view returns (uint);

    function pairOracleFeeP(uint) external view returns (uint);

    function pairNftLimitOrderFeeP(uint) external view returns (uint);

    function pairReferralFeeP(uint) external view returns (uint);

    function pairMinLevPosDai(uint) external view returns (uint);

    function pairsCount() external view returns (uint);
}

// SPDX-License-Identifier: MIT
import "./TokenInterfaceV5.sol";
import "./NftInterfaceV5.sol";
import "./IGToken.sol";
import "./PairsStorageInterfaceV6.sol";
import "./ChainlinkFeedInterfaceV5.sol";

pragma solidity 0.8.17;

interface PoolInterfaceV5 {
    function increaseAccTokensPerLp(uint) external;
}

interface PausableInterfaceV5 {
    function isPaused() external view returns (bool);
}

interface StorageInterfaceV5 {
    enum LimitOrder {
        TP,
        SL,
        LIQ,
        OPEN
    }
    struct Trade {
        address trader;
        uint pairIndex;
        uint index;
        uint initialPosToken; // 1e18
        uint positionSizeDai; // 1e18
        uint openPrice; // PRECISION
        bool buy;
        uint leverage;
        uint tp; // PRECISION
        uint sl; // PRECISION
    }
    struct TradeInfo {
        uint tokenId;
        uint tokenPriceDai; // PRECISION
        uint openInterestDai; // 1e18
        uint tpLastUpdated;
        uint slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder {
        address trader;
        uint pairIndex;
        uint index;
        uint positionSize; // 1e18 (DAI or GFARM2)
        uint spreadReductionP;
        bool buy;
        uint leverage;
        uint tp; // PRECISION (%)
        uint sl; // PRECISION (%)
        uint minPrice; // PRECISION
        uint maxPrice; // PRECISION
        uint block;
        uint tokenId; // index in supportedTokens
    }
    struct PendingMarketOrder {
        Trade trade;
        uint block;
        uint wantedPrice; // PRECISION
        uint slippageP; // PRECISION (%)
        uint spreadReductionP;
        uint tokenId; // index in supportedTokens
    }
    struct PendingNftOrder {
        address nftHolder;
        uint nftId;
        address trader;
        uint pairIndex;
        uint index;
        LimitOrder orderType;
    }

    function PRECISION() external pure returns (uint);

    function gov() external view returns (address);

    function dev() external view returns (address);

    function dai() external view returns (TokenInterfaceV5);

    function token() external view returns (TokenInterfaceV5);

    function linkErc677() external view returns (TokenInterfaceV5);

    function priceAggregator() external view returns (AggregatorInterfaceV6_4);

    function vault() external view returns (IGToken);

    function trading() external view returns (address);

    function callbacks() external view returns (address);

    function handleTokens(address, uint, bool) external;

    function transferDai(address, address, uint) external;

    function transferLinkToAggregator(address, uint, uint) external;

    function unregisterTrade(address, uint, uint) external;

    function unregisterPendingMarketOrder(uint, bool) external;

    function unregisterOpenLimitOrder(address, uint, uint) external;

    function hasOpenLimitOrder(address, uint, uint) external view returns (bool);

    function storePendingMarketOrder(PendingMarketOrder memory, uint, bool) external;

    function openTrades(address, uint, uint) external view returns (Trade memory);

    function openTradesInfo(address, uint, uint) external view returns (TradeInfo memory);

    function updateSl(address, uint, uint, uint) external;

    function updateTp(address, uint, uint, uint) external;

    function getOpenLimitOrder(address, uint, uint) external view returns (OpenLimitOrder memory);

    function spreadReductionsP(uint) external view returns (uint);

    function storeOpenLimitOrder(OpenLimitOrder memory) external;

    function reqID_pendingMarketOrder(uint) external view returns (PendingMarketOrder memory);

    function storePendingNftOrder(PendingNftOrder memory, uint) external;

    function updateOpenLimitOrder(OpenLimitOrder calldata) external;

    function firstEmptyTradeIndex(address, uint) external view returns (uint);

    function firstEmptyOpenLimitIndex(address, uint) external view returns (uint);

    function increaseNftRewards(uint, uint) external;

    function nftSuccessTimelock() external view returns (uint);

    function reqID_pendingNftOrder(uint) external view returns (PendingNftOrder memory);

    function updateTrade(Trade memory) external;

    function nftLastSuccess(uint) external view returns (uint);

    function unregisterPendingNftOrder(uint) external;

    function handleDevGovFees(uint, uint, bool, bool) external returns (uint);

    function distributeLpRewards(uint) external;

    function storeTrade(Trade memory, TradeInfo memory) external;

    function openLimitOrdersCount(address, uint) external view returns (uint);

    function openTradesCount(address, uint) external view returns (uint);

    function pendingMarketOpenCount(address, uint) external view returns (uint);

    function pendingMarketCloseCount(address, uint) external view returns (uint);

    function maxTradesPerPair() external view returns (uint);

    function pendingOrderIdsCount(address) external view returns (uint);

    function maxPendingMarketOrders() external view returns (uint);

    function openInterestDai(uint, uint) external view returns (uint);

    function getPendingOrderIds(address) external view returns (uint[] memory);

    function nfts(uint) external view returns (NftInterfaceV5);

    function fakeBlockNumber() external view returns (uint); // Testing
}

interface IStateCopyUtils {
    function getOpenLimitOrders() external view returns (StorageInterfaceV5.OpenLimitOrder[] memory);

    function nftRewards() external view returns (NftRewardsInterfaceV6_3_1);
}

interface NftRewardsInterfaceV6_3_1 {
    struct TriggeredLimitId {
        address trader;
        uint pairIndex;
        uint index;
        StorageInterfaceV5.LimitOrder order;
    }
    enum OpenLimitOrderType {
        LEGACY,
        REVERSAL,
        MOMENTUM
    }

    function storeFirstToTrigger(TriggeredLimitId calldata, address, uint) external;

    function storeTriggerSameBlock(TriggeredLimitId calldata, address) external;

    function unregisterTrigger(TriggeredLimitId calldata) external;

    function distributeNftReward(TriggeredLimitId calldata, uint, uint) external;

    function openLimitOrderTypes(address, uint, uint) external view returns (OpenLimitOrderType);

    function setOpenLimitOrderType(address, uint, uint, OpenLimitOrderType) external;

    function triggered(TriggeredLimitId calldata) external view returns (bool);

    function timedOut(TriggeredLimitId calldata) external view returns (bool);

    function botInUse(bytes32) external view returns (bool);

    function getNftBotHashes(uint, address, uint, address, uint, uint) external pure returns (bytes32, bytes32);

    function setNftBotInUse(bytes32, bytes32) external;

    function nftBotInUse(bytes32, bytes32) external view returns (bool);

    function linkToTokenRewards(uint, uint) external view returns (uint);
}

interface AggregatorInterfaceV6_4 {
    enum OrderType {
        MARKET_OPEN,
        MARKET_CLOSE,
        LIMIT_OPEN,
        LIMIT_CLOSE
    }

    function pairsStorage() external view returns (PairsStorageInterfaceV6);

    function getPrice(uint, OrderType, uint, uint) external returns (uint);

    function tokenPriceDai() external returns (uint);

    function linkFee(uint, uint) external view returns (uint);

    function openFeeP(uint) external view returns (uint);

    function linkPriceFeed() external view returns (ChainlinkFeedInterfaceV5);

    function nodes(uint index) external view returns (address);
}

interface TradingCallbacksV6_4 {
    enum TradeType {
        MARKET,
        LIMIT
    }
    struct SimplifiedTradeId {
        address trader;
        uint pairIndex;
        uint index;
        TradeType tradeType;
    }
    struct LastUpdated {
        uint32 tp;
        uint32 sl;
        uint32 limit;
        uint32 created;
    }
    struct TradeData {
        uint40 maxSlippageP; // 1e10 (%)
        uint216 _placeholder; // for potential future data
    }

    function tradeLastUpdated(address, uint, uint, TradeType) external view returns (LastUpdated memory);

    function setTradeLastUpdated(SimplifiedTradeId calldata, LastUpdated memory) external;

    function setTradeData(SimplifiedTradeId calldata, TradeData memory) external;

    function canExecuteTimeout() external view returns (uint);

    function pairMaxLeverage(uint) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface TokenInterfaceV5 {
    function burn(address, uint256) external;

    function mint(address, uint256) external;

    function transfer(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function hasRole(bytes32, address) external view returns (bool);

    function approve(address, uint256) external returns (bool);

    function allowance(address, address) external view returns (uint256);

    function decimals() external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IArbSys.sol";

library ChainUtils {
    uint256 public constant ARBITRUM_MAINNET = 42161;
    uint256 public constant ARBITRUM_GOERLI = 421613;
    IArbSys public constant ARB_SYS = IArbSys(address(100));

    function getBlockNumber() internal view returns (uint) {
        if (block.chainid == ARBITRUM_MAINNET || block.chainid == ARBITRUM_GOERLI) {
            return ARB_SYS.arbBlockNumber();
        }

        return block.number;
    }

    function getUint48BlockNumber(uint blockNumber) internal pure returns (uint48) {
        require(blockNumber <= type(uint48).max, "OVERFLOW");
        return uint48(blockNumber);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/GNSBorrowingFeesInterfaceV6_5.sol";
import "../interfaces/StorageInterfaceV5.sol";
import "../interfaces/GNSPairInfosInterfaceV6.sol";
import "../libraries/ChainUtils.sol";

contract GNSBorrowingFeesV6_5 is Initializable, GNSBorrowingFeesInterfaceV6_5 {
    // Constants
    uint constant P_1 = 1e10;
    uint constant P_2 = 1e40;

    // Addresses
    StorageInterfaceV5 public storageT;
    GNSPairInfosInterfaceV6 public pairInfos;

    // State
    mapping(uint16 => Group) public groups;
    mapping(uint => Pair) public pairs;
    mapping(address => mapping(uint => mapping(uint => InitialAccFees))) public initialAccFees;
    mapping(uint => PairOi) public pairOis;
    mapping(uint => uint48) public groupFeeExponents;

    uint public collateralPrecision;

    // Note: Events and structs are in interface

    function initialize(StorageInterfaceV5 _storageT, GNSPairInfosInterfaceV6 _pairInfos) external initializer {
        require(address(_storageT) != address(0) && address(_pairInfos) != address(0), "WRONG_PARAMS");

        storageT = _storageT;
        pairInfos = _pairInfos;

        collateralPrecision = 10 ** storageT.dai().decimals(); // 1e18 for ETH/DAI, 1e6 for USDC/USDT
    }

    // Modifiers
    modifier onlyManager() {
        require(msg.sender == pairInfos.manager(), "MANAGER_ONLY");
        _;
    }

    modifier onlyCallbacks() {
        require(msg.sender == storageT.callbacks(), "CALLBACKS_ONLY");
        _;
    }

    // Manage pair params
    function setPairParams(uint pairIndex, PairParams calldata value) external onlyManager {
        _setPairParams(pairIndex, value);
    }

    function setPairParamsArray(uint[] calldata indices, PairParams[] calldata values) external onlyManager {
        uint len = indices.length;
        require(len == values.length, "WRONG_LENGTH");

        for (uint i; i < len; ) {
            _setPairParams(indices[i], values[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _setPairParams(uint pairIndex, PairParams calldata value) private {
        require(value.feeExponent >= 1 && value.feeExponent <= 3, "WRONG_EXPONENT");

        Pair storage p = pairs[pairIndex];

        uint16 prevGroupIndex = getPairGroupIndex(pairIndex);
        uint currentBlock = ChainUtils.getBlockNumber();

        _setPairPendingAccFees(pairIndex, currentBlock);

        if (value.groupIndex != prevGroupIndex) {
            _setGroupPendingAccFees(prevGroupIndex, currentBlock);
            _setGroupPendingAccFees(value.groupIndex, currentBlock);

            (uint oiLong, uint oiShort) = getPairOpenInterestDai(pairIndex);

            // Only remove OI from old group if old group is not 0
            _setGroupOi(prevGroupIndex, true, false, oiLong);
            _setGroupOi(prevGroupIndex, false, false, oiShort);

            // Add OI to new group if it's not group 0 (even if old group is 0)
            // So when we assign a pair to a group, it takes into account its OI
            // And group 0 OI will always be 0 but it doesn't matter since it's not used
            _setGroupOi(value.groupIndex, true, true, oiLong);
            _setGroupOi(value.groupIndex, false, true, oiShort);

            Group memory newGroup = groups[value.groupIndex];
            Group memory prevGroup = groups[prevGroupIndex];

            p.groups.push(
                PairGroup(
                    value.groupIndex,
                    ChainUtils.getUint48BlockNumber(currentBlock),
                    newGroup.accFeeLong,
                    newGroup.accFeeShort,
                    prevGroup.accFeeLong,
                    prevGroup.accFeeShort,
                    p.accFeeLong,
                    p.accFeeShort,
                    0 // placeholder
                )
            );

            emit PairGroupUpdated(pairIndex, prevGroupIndex, value.groupIndex);
        }

        p.feePerBlock = value.feePerBlock;
        p.feeExponent = value.feeExponent;
        pairOis[pairIndex].max = value.maxOi;

        emit PairParamsUpdated(pairIndex, value.groupIndex, value.feePerBlock, value.feeExponent, value.maxOi);
    }

    // Manage group params
    function setGroupParams(uint16 groupIndex, GroupParams calldata value) external onlyManager {
        _setGroupParams(groupIndex, value);
    }

    function setGroupParamsArray(uint16[] calldata indices, GroupParams[] calldata values) external onlyManager {
        uint len = indices.length;
        require(len == values.length, "WRONG_LENGTH");

        for (uint i; i < len; ) {
            _setGroupParams(indices[i], values[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _setGroupParams(uint16 groupIndex, GroupParams calldata value) private {
        require(groupIndex > 0, "GROUP_0");
        require(value.feeExponent >= 1 && value.feeExponent <= 3, "WRONG_EXPONENT");

        _setGroupPendingAccFees(groupIndex, ChainUtils.getBlockNumber());

        Group storage g = groups[groupIndex];
        g.feePerBlock = value.feePerBlock;
        g.maxOi = uint80(value.maxOi);
        groupFeeExponents[groupIndex] = value.feeExponent;

        emit GroupUpdated(groupIndex, value.feePerBlock, value.maxOi, value.feeExponent);
    }

    // Group OI setter
    function _setGroupOi(
        uint16 groupIndex,
        bool long,
        bool increase,
        uint amount // 1e18
    ) private {
        Group storage group = groups[groupIndex];
        uint112 amountFinal;

        if (groupIndex > 0) {
            amount = (amount * P_1) / collateralPrecision; // 1e10
            require(amount <= type(uint112).max, "OVERFLOW");

            amountFinal = uint112(amount);

            if (long) {
                group.oiLong = increase
                    ? group.oiLong + amountFinal
                    : group.oiLong - (group.oiLong > amountFinal ? amountFinal : group.oiLong);
            } else {
                group.oiShort = increase
                    ? group.oiShort + amountFinal
                    : group.oiShort - (group.oiShort > amountFinal ? amountFinal : group.oiShort);
            }
        }

        emit GroupOiUpdated(groupIndex, long, increase, amountFinal, group.oiLong, group.oiShort);
    }

    // Acc fees getters for pairs and groups
    function getPendingAccFees(
        PendingAccFeesInput memory input
    ) public pure returns (uint64 newAccFeeLong, uint64 newAccFeeShort, uint64 delta) {
        require(input.currentBlock >= input.accLastUpdatedBlock, "BLOCK_ORDER");

        bool moreShorts = input.oiLong < input.oiShort;
        uint netOi = moreShorts ? input.oiShort - input.oiLong : input.oiLong - input.oiShort;

        uint _delta = input.maxOi > 0 && input.feeExponent > 0
            ? ((input.currentBlock - input.accLastUpdatedBlock) *
                input.feePerBlock *
                ((netOi * 1e10) / input.maxOi) ** input.feeExponent) / (input.collateralPrecision ** input.feeExponent)
            : 0; // 1e10 (%)

        require(_delta <= type(uint64).max, "OVERFLOW");
        delta = uint64(_delta);

        newAccFeeLong = moreShorts ? input.accFeeLong : input.accFeeLong + delta;
        newAccFeeShort = moreShorts ? input.accFeeShort + delta : input.accFeeShort;
    }

    function getPairGroupAccFeesDeltas(
        uint i,
        PairGroup[] memory pairGroups,
        InitialAccFees memory initialFees,
        uint pairIndex,
        bool long,
        uint currentBlock
    ) public view returns (uint64 deltaGroup, uint64 deltaPair, bool beforeTradeOpen) {
        PairGroup memory group = pairGroups[i];

        beforeTradeOpen = group.block < initialFees.block;

        if (i == pairGroups.length - 1) {
            // Last active group
            deltaGroup = getGroupPendingAccFee(group.groupIndex, currentBlock, long);
            deltaPair = getPairPendingAccFee(pairIndex, currentBlock, long);
        } else {
            // Previous groups
            PairGroup memory nextGroup = pairGroups[i + 1];

            // If it's not the first group to be before the trade was opened then fee is 0
            if (beforeTradeOpen && nextGroup.block <= initialFees.block) {
                return (0, 0, beforeTradeOpen);
            }

            deltaGroup = long ? nextGroup.prevGroupAccFeeLong : nextGroup.prevGroupAccFeeShort;
            deltaPair = long ? nextGroup.pairAccFeeLong : nextGroup.pairAccFeeShort;
        }

        if (beforeTradeOpen) {
            deltaGroup -= initialFees.accGroupFee;
            deltaPair -= initialFees.accPairFee;
        } else {
            deltaGroup -= (long ? group.initialAccFeeLong : group.initialAccFeeShort);
            deltaPair -= (long ? group.pairAccFeeLong : group.pairAccFeeShort);
        }
    }

    // Pair acc fees helpers
    function getPairPendingAccFees(
        uint pairIndex,
        uint currentBlock
    ) public view returns (uint64 accFeeLong, uint64 accFeeShort, uint64 pairAccFeeDelta) {
        Pair memory pair = pairs[pairIndex];

        (uint pairOiLong, uint pairOiShort) = getPairOpenInterestDai(pairIndex);

        (accFeeLong, accFeeShort, pairAccFeeDelta) = getPendingAccFees(
            PendingAccFeesInput(
                pair.accFeeLong,
                pair.accFeeShort,
                pairOiLong,
                pairOiShort,
                pair.feePerBlock,
                currentBlock,
                pair.accLastUpdatedBlock,
                pairOis[pairIndex].max,
                pair.feeExponent,
                collateralPrecision
            )
        );
    }

    function getPairPendingAccFee(uint pairIndex, uint currentBlock, bool long) public view returns (uint64 accFee) {
        (uint64 accFeeLong, uint64 accFeeShort, ) = getPairPendingAccFees(pairIndex, currentBlock);
        return long ? accFeeLong : accFeeShort;
    }

    function _setPairPendingAccFees(
        uint pairIndex,
        uint currentBlock
    ) private returns (uint64 accFeeLong, uint64 accFeeShort) {
        (accFeeLong, accFeeShort, ) = getPairPendingAccFees(pairIndex, currentBlock);

        Pair storage pair = pairs[pairIndex];

        (pair.accFeeLong, pair.accFeeShort) = (accFeeLong, accFeeShort);
        pair.accLastUpdatedBlock = ChainUtils.getUint48BlockNumber(currentBlock);

        emit PairAccFeesUpdated(pairIndex, currentBlock, pair.accFeeLong, pair.accFeeShort);
    }

    // Group acc fees helpers
    function getGroupPendingAccFees(
        uint16 groupIndex,
        uint currentBlock
    ) public view returns (uint64 accFeeLong, uint64 accFeeShort, uint64 groupAccFeeDelta) {
        Group memory group = groups[groupIndex];
        uint _collateralPrecision = collateralPrecision;

        (accFeeLong, accFeeShort, groupAccFeeDelta) = getPendingAccFees(
            PendingAccFeesInput(
                group.accFeeLong,
                group.accFeeShort,
                (uint(group.oiLong) * _collateralPrecision) / P_1,
                (uint(group.oiShort) * _collateralPrecision) / P_1,
                group.feePerBlock,
                currentBlock,
                group.accLastUpdatedBlock,
                uint72(group.maxOi),
                groupFeeExponents[groupIndex],
                _collateralPrecision
            )
        );
    }

    function getGroupPendingAccFee(
        uint16 groupIndex,
        uint currentBlock,
        bool long
    ) public view returns (uint64 accFee) {
        (uint64 accFeeLong, uint64 accFeeShort, ) = getGroupPendingAccFees(groupIndex, currentBlock);
        return long ? accFeeLong : accFeeShort;
    }

    function _setGroupPendingAccFees(
        uint16 groupIndex,
        uint currentBlock
    ) private returns (uint64 accFeeLong, uint64 accFeeShort) {
        (accFeeLong, accFeeShort, ) = getGroupPendingAccFees(groupIndex, currentBlock);

        Group storage group = groups[groupIndex];

        (group.accFeeLong, group.accFeeShort) = (accFeeLong, accFeeShort);
        group.accLastUpdatedBlock = ChainUtils.getUint48BlockNumber(currentBlock);

        emit GroupAccFeesUpdated(groupIndex, currentBlock, group.accFeeLong, group.accFeeShort);
    }

    // Interaction with callbacks
    function handleTradeAction(
        address trader,
        uint pairIndex,
        uint index,
        uint positionSizeDai, // 1e18 (collateral * leverage)
        bool open,
        bool long
    ) external override onlyCallbacks {
        uint16 groupIndex = getPairGroupIndex(pairIndex);
        uint currentBlock = ChainUtils.getBlockNumber();

        (uint64 pairAccFeeLong, uint64 pairAccFeeShort) = _setPairPendingAccFees(pairIndex, currentBlock);
        (uint64 groupAccFeeLong, uint64 groupAccFeeShort) = _setGroupPendingAccFees(groupIndex, currentBlock);

        _setGroupOi(groupIndex, long, open, positionSizeDai);

        if (open) {
            InitialAccFees memory initialFees = InitialAccFees(
                long ? pairAccFeeLong : pairAccFeeShort,
                long ? groupAccFeeLong : groupAccFeeShort,
                ChainUtils.getUint48BlockNumber(currentBlock),
                0 // placeholder
            );

            initialAccFees[trader][pairIndex][index] = initialFees;

            emit TradeInitialAccFeesStored(trader, pairIndex, index, initialFees.accPairFee, initialFees.accGroupFee);
        }

        emit TradeActionHandled(trader, pairIndex, index, open, long, positionSizeDai);
    }

    // Important trade getters
    function getTradeBorrowingFee(BorrowingFeeInput memory input) public view returns (uint fee) {
        InitialAccFees memory initialFees = initialAccFees[input.trader][input.pairIndex][input.index];
        PairGroup[] memory pairGroups = pairs[input.pairIndex].groups;

        uint currentBlock = ChainUtils.getBlockNumber();

        PairGroup memory firstPairGroup;
        if (pairGroups.length > 0) {
            firstPairGroup = pairGroups[0];
        }

        // If pair has had no group after trade was opened, initialize with pair borrowing fee
        if (pairGroups.length == 0 || firstPairGroup.block > initialFees.block) {
            fee = ((
                pairGroups.length == 0
                    ? getPairPendingAccFee(input.pairIndex, currentBlock, input.long)
                    : (input.long ? firstPairGroup.pairAccFeeLong : firstPairGroup.pairAccFeeShort)
            ) - initialFees.accPairFee);
        }

        // Sum of max(pair fee, group fee) for all groups the pair was in while trade was open
        for (uint i = pairGroups.length; i > 0; ) {
            (uint64 deltaGroup, uint64 deltaPair, bool beforeTradeOpen) = getPairGroupAccFeesDeltas(
                i - 1,
                pairGroups,
                initialFees,
                input.pairIndex,
                input.long,
                currentBlock
            );

            fee += (deltaGroup > deltaPair ? deltaGroup : deltaPair);

            // Exit loop at first group before trade was open
            if (beforeTradeOpen) break;
            unchecked {
                --i;
            }
        }

        fee = (input.collateral * input.leverage * fee) / P_1 / 100; // 1e18 (DAI)
    }

    function getTradeLiquidationPrice(LiqPriceInput calldata input) external view returns (uint) {
        return
            pairInfos.getTradeLiquidationPricePure(
                input.openPrice,
                input.long,
                input.collateral,
                input.leverage,
                pairInfos.getTradeRolloverFee(input.trader, input.pairIndex, input.index, input.collateral) +
                    getTradeBorrowingFee(
                        BorrowingFeeInput(
                            input.trader,
                            input.pairIndex,
                            input.index,
                            input.long,
                            input.collateral,
                            input.leverage
                        )
                    ),
                pairInfos.getTradeFundingFee(
                    input.trader,
                    input.pairIndex,
                    input.index,
                    input.long,
                    input.collateral,
                    input.leverage
                )
            );
    }

    // Public getters
    function getPairOpenInterestDai(uint pairIndex) public view returns (uint, uint) {
        return (storageT.openInterestDai(pairIndex, 0), storageT.openInterestDai(pairIndex, 1));
    }

    function getPairGroupIndex(uint pairIndex) public view returns (uint16 groupIndex) {
        PairGroup[] memory pairGroups = pairs[pairIndex].groups;
        return pairGroups.length == 0 ? 0 : pairGroups[pairGroups.length - 1].groupIndex;
    }

    // External getters
    function withinMaxGroupOi(
        uint pairIndex,
        bool long,
        uint positionSizeDai // 1e18
    ) external view returns (bool) {
        Group memory g = groups[getPairGroupIndex(pairIndex)];
        return
            (g.maxOi == 0) ||
            ((long ? g.oiLong : g.oiShort) + (positionSizeDai * P_1) / collateralPrecision <= g.maxOi);
    }

    function getGroup(uint16 groupIndex) external view returns (Group memory, uint48) {
        return (groups[groupIndex], groupFeeExponents[groupIndex]);
    }

    function getPair(uint pairIndex) external view returns (Pair memory, PairOi memory) {
        return (pairs[pairIndex], pairOis[pairIndex]);
    }

    function getAllPairs() external view returns (Pair[] memory, PairOi[] memory) {
        uint len = storageT.priceAggregator().pairsStorage().pairsCount();
        Pair[] memory p = new Pair[](len);
        PairOi[] memory pairOi = new PairOi[](len);

        for (uint i; i < len; ) {
            p[i] = pairs[i];
            pairOi[i] = pairOis[i];
            unchecked {
                ++i;
            }
        }

        return (p, pairOi);
    }

    function getGroups(uint16[] calldata indices) external view returns (Group[] memory, uint48[] memory) {
        Group[] memory g = new Group[](indices.length);
        uint48[] memory e = new uint48[](indices.length);
        uint len = indices.length;

        for (uint i; i < len; ) {
            g[i] = groups[indices[i]];
            e[i] = groupFeeExponents[indices[i]];
            unchecked {
                ++i;
            }
        }

        return (g, e);
    }

    function getTradeInitialAccFees(
        address trader,
        uint pairIndex,
        uint index
    )
        external
        view
        returns (InitialAccFees memory borrowingFees, GNSPairInfosInterfaceV6.TradeInitialAccFees memory otherFees)
    {
        borrowingFees = initialAccFees[trader][pairIndex][index];
        otherFees = pairInfos.tradeInitialAccFees(trader, pairIndex, index);
    }

    function getPairMaxOi(uint pairIndex) external view returns (uint) {
        return pairOis[pairIndex].max;
    }
}