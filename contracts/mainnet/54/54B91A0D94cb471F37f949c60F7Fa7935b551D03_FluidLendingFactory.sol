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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IProxy {
    function setAdmin(address newAdmin_) external;

    function setDummyImplementation(address newDummyImplementation_) external;

    function addImplementation(address implementation_, bytes4[] calldata sigs_) external;

    function removeImplementation(address implementation_) external;

    function getAdmin() external view returns (address);

    function getDummyImplementation() external view returns (address);

    function getImplementationSigs(address impl_) external view returns (bytes4[] memory);

    function getSigsImplementation(bytes4 sig_) external view returns (address);

    function readFromStorage(bytes32 slot_) external view returns (uint256 result_);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

/// @notice library that helps in reading / working with storage slot data of Fluid Liquidity.
/// @dev as all data for Fluid Liquidity is internal, any data must be fetched directly through manual
/// slot reading through this library or, if gas usage is less important, through the FluidLiquidityResolver.
library LiquiditySlotsLink {
    /// @dev storage slot for status at Liquidity
    uint256 internal constant LIQUIDITY_STATUS_SLOT = 1;
    /// @dev storage slot for auths mapping at Liquidity
    uint256 internal constant LIQUIDITY_AUTHS_MAPPING_SLOT = 2;
    /// @dev storage slot for guardians mapping at Liquidity
    uint256 internal constant LIQUIDITY_GUARDIANS_MAPPING_SLOT = 3;
    /// @dev storage slot for user class mapping at Liquidity
    uint256 internal constant LIQUIDITY_USER_CLASS_MAPPING_SLOT = 4;
    /// @dev storage slot for exchangePricesAndConfig mapping at Liquidity
    uint256 internal constant LIQUIDITY_EXCHANGE_PRICES_MAPPING_SLOT = 5;
    /// @dev storage slot for rateData mapping at Liquidity
    uint256 internal constant LIQUIDITY_RATE_DATA_MAPPING_SLOT = 6;
    /// @dev storage slot for totalAmounts mapping at Liquidity
    uint256 internal constant LIQUIDITY_TOTAL_AMOUNTS_MAPPING_SLOT = 7;
    /// @dev storage slot for user supply double mapping at Liquidity
    uint256 internal constant LIQUIDITY_USER_SUPPLY_DOUBLE_MAPPING_SLOT = 8;
    /// @dev storage slot for user borrow double mapping at Liquidity
    uint256 internal constant LIQUIDITY_USER_BORROW_DOUBLE_MAPPING_SLOT = 9;
    /// @dev storage slot for listed tokens array at Liquidity
    uint256 internal constant LIQUIDITY_LISTED_TOKENS_ARRAY_SLOT = 10;

    // --------------------------------
    // @dev stacked uint256 storage slots bits position data for each:

    // ExchangePricesAndConfig
    uint256 internal constant BITS_EXCHANGE_PRICES_BORROW_RATE = 0;
    uint256 internal constant BITS_EXCHANGE_PRICES_FEE = 16;
    uint256 internal constant BITS_EXCHANGE_PRICES_UTILIZATION = 30;
    uint256 internal constant BITS_EXCHANGE_PRICES_UPDATE_THRESHOLD = 44;
    uint256 internal constant BITS_EXCHANGE_PRICES_LAST_TIMESTAMP = 58;
    uint256 internal constant BITS_EXCHANGE_PRICES_SUPPLY_EXCHANGE_PRICE = 91;
    uint256 internal constant BITS_EXCHANGE_PRICES_BORROW_EXCHANGE_PRICE = 155;
    uint256 internal constant BITS_EXCHANGE_PRICES_SUPPLY_RATIO = 219;
    uint256 internal constant BITS_EXCHANGE_PRICES_BORROW_RATIO = 234;

    // RateData:
    uint256 internal constant BITS_RATE_DATA_VERSION = 0;
    // RateData: V1
    uint256 internal constant BITS_RATE_DATA_V1_RATE_AT_UTILIZATION_ZERO = 4;
    uint256 internal constant BITS_RATE_DATA_V1_UTILIZATION_AT_KINK = 20;
    uint256 internal constant BITS_RATE_DATA_V1_RATE_AT_UTILIZATION_KINK = 36;
    uint256 internal constant BITS_RATE_DATA_V1_RATE_AT_UTILIZATION_MAX = 52;
    // RateData: V2
    uint256 internal constant BITS_RATE_DATA_V2_RATE_AT_UTILIZATION_ZERO = 4;
    uint256 internal constant BITS_RATE_DATA_V2_UTILIZATION_AT_KINK1 = 20;
    uint256 internal constant BITS_RATE_DATA_V2_RATE_AT_UTILIZATION_KINK1 = 36;
    uint256 internal constant BITS_RATE_DATA_V2_UTILIZATION_AT_KINK2 = 52;
    uint256 internal constant BITS_RATE_DATA_V2_RATE_AT_UTILIZATION_KINK2 = 68;
    uint256 internal constant BITS_RATE_DATA_V2_RATE_AT_UTILIZATION_MAX = 84;

    // TotalAmounts
    uint256 internal constant BITS_TOTAL_AMOUNTS_SUPPLY_WITH_INTEREST = 0;
    uint256 internal constant BITS_TOTAL_AMOUNTS_SUPPLY_INTEREST_FREE = 64;
    uint256 internal constant BITS_TOTAL_AMOUNTS_BORROW_WITH_INTEREST = 128;
    uint256 internal constant BITS_TOTAL_AMOUNTS_BORROW_INTEREST_FREE = 192;

    // UserSupplyData
    uint256 internal constant BITS_USER_SUPPLY_MODE = 0;
    uint256 internal constant BITS_USER_SUPPLY_AMOUNT = 1;
    uint256 internal constant BITS_USER_SUPPLY_PREVIOUS_WITHDRAWAL_LIMIT = 65;
    uint256 internal constant BITS_USER_SUPPLY_LAST_UPDATE_TIMESTAMP = 129;
    uint256 internal constant BITS_USER_SUPPLY_EXPAND_PERCENT = 162;
    uint256 internal constant BITS_USER_SUPPLY_EXPAND_DURATION = 176;
    uint256 internal constant BITS_USER_SUPPLY_BASE_WITHDRAWAL_LIMIT = 200;
    uint256 internal constant BITS_USER_SUPPLY_IS_PAUSED = 255;

    // UserBorrowData
    uint256 internal constant BITS_USER_BORROW_MODE = 0;
    uint256 internal constant BITS_USER_BORROW_AMOUNT = 1;
    uint256 internal constant BITS_USER_BORROW_PREVIOUS_BORROW_LIMIT = 65;
    uint256 internal constant BITS_USER_BORROW_LAST_UPDATE_TIMESTAMP = 129;
    uint256 internal constant BITS_USER_BORROW_EXPAND_PERCENT = 162;
    uint256 internal constant BITS_USER_BORROW_EXPAND_DURATION = 176;
    uint256 internal constant BITS_USER_BORROW_BASE_BORROW_LIMIT = 200;
    uint256 internal constant BITS_USER_BORROW_MAX_BORROW_LIMIT = 218;
    uint256 internal constant BITS_USER_BORROW_IS_PAUSED = 255;

    // --------------------------------

    /// @notice Calculating the slot ID for Liquidity contract for single mapping at `slot_` for `key_`
    function calculateMappingStorageSlot(uint256 slot_, address key_) internal pure returns (bytes32) {
        return keccak256(abi.encode(key_, slot_));
    }

    /// @notice Calculating the slot ID for Liquidity contract for double mapping at `slot_` for `key1_` and `key2_`
    function calculateDoubleMappingStorageSlot(
        uint256 slot_,
        address key1_,
        address key2_
    ) internal pure returns (bytes32) {
        bytes32 intermediateSlot_ = keccak256(abi.encode(key1_, slot_));
        return keccak256(abi.encode(key2_, intermediateSlot_));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

abstract contract Structs {
    struct AddressBool {
        address addr;
        bool value;
    }

    struct AddressUint256 {
        address addr;
        uint256 value;
    }

    /// @notice struct to set borrow rate data for version 1
    struct RateDataV1Params {
        ///
        /// @param token for rate data
        address token;
        ///
        /// @param kink in borrow rate. in 1e2: 100% = 10_000; 1% = 100
        /// utilization below kink usually means slow increase in rate, once utilization is above kink borrow rate increases fast
        uint256 kink;
        ///
        /// @param rateAtUtilizationZero desired borrow rate when utilization is zero. in 1e2: 100% = 10_000; 1% = 100
        /// i.e. constant minimum borrow rate
        /// e.g. at utilization = 0.01% rate could still be at least 4% (rateAtUtilizationZero would be 400 then)
        uint256 rateAtUtilizationZero;
        ///
        /// @param rateAtUtilizationKink borrow rate when utilization is at kink. in 1e2: 100% = 10_000; 1% = 100
        /// e.g. when rate should be 7% at kink then rateAtUtilizationKink would be 700
        uint256 rateAtUtilizationKink;
        ///
        /// @param rateAtUtilizationMax borrow rate when utilization is maximum at 100%. in 1e2: 100% = 10_000; 1% = 100
        /// e.g. when rate should be 125% at 100% then rateAtUtilizationMax would be 12_500
        uint256 rateAtUtilizationMax;
    }

    /// @notice struct to set borrow rate data for version 2
    struct RateDataV2Params {
        ///
        /// @param token for rate data
        address token;
        ///
        /// @param kink1 first kink in borrow rate. in 1e2: 100% = 10_000; 1% = 100
        /// utilization below kink 1 usually means slow increase in rate, once utilization is above kink 1 borrow rate increases faster
        uint256 kink1;
        ///
        /// @param kink2 second kink in borrow rate. in 1e2: 100% = 10_000; 1% = 100
        /// utilization below kink 2 usually means slow / medium increase in rate, once utilization is above kink 2 borrow rate increases fast
        uint256 kink2;
        ///
        /// @param rateAtUtilizationZero desired borrow rate when utilization is zero. in 1e2: 100% = 10_000; 1% = 100
        /// i.e. constant minimum borrow rate
        /// e.g. at utilization = 0.01% rate could still be at least 4% (rateAtUtilizationZero would be 400 then)
        uint256 rateAtUtilizationZero;
        ///
        /// @param rateAtUtilizationKink1 desired borrow rate when utilization is at first kink. in 1e2: 100% = 10_000; 1% = 100
        /// e.g. when rate should be 7% at first kink then rateAtUtilizationKink would be 700
        uint256 rateAtUtilizationKink1;
        ///
        /// @param rateAtUtilizationKink2 desired borrow rate when utilization is at second kink. in 1e2: 100% = 10_000; 1% = 100
        /// e.g. when rate should be 7% at second kink then rateAtUtilizationKink would be 1_200
        uint256 rateAtUtilizationKink2;
        ///
        /// @param rateAtUtilizationMax desired borrow rate when utilization is maximum at 100%. in 1e2: 100% = 10_000; 1% = 100
        /// e.g. when rate should be 125% at 100% then rateAtUtilizationMax would be 12_500
        uint256 rateAtUtilizationMax;
    }

    /// @notice struct to set token config
    struct TokenConfig {
        ///
        /// @param token address
        address token;
        ///
        /// @param fee charges on borrower's interest. in 1e2: 100% = 10_000; 1% = 100
        uint256 fee;
        ///
        /// @param threshold on when to update the storage slot. in 1e2: 100% = 10_000; 1% = 100
        uint256 threshold;
    }

    /// @notice struct to set user supply & withdrawal config
    struct UserSupplyConfig {
        ///
        /// @param user address
        address user;
        ///
        /// @param token address
        address token;
        ///
        /// @param mode: 0 = without interest. 1 = with interest
        uint8 mode;
        ///
        /// @param expandPercent withdrawal limit expand percent. in 1e2: 100% = 10_000; 1% = 100
        /// Also used to calculate rate at which withdrawal limit should decrease (instant).
        uint256 expandPercent;
        ///
        /// @param expandDuration withdrawal limit expand duration in seconds.
        /// used to calculate rate together with expandPercent
        uint256 expandDuration;
        ///
        /// @param baseWithdrawalLimit base limit, below this, user can withdraw the entire amount.
        /// amount in raw (to be multiplied with exchange price) or normal depends on configured mode in user config for the token:
        /// with interest -> raw, without interest -> normal
        uint256 baseWithdrawalLimit;
    }

    /// @notice struct to set user borrow & payback config
    struct UserBorrowConfig {
        ///
        /// @param user address
        address user;
        ///
        /// @param token address
        address token;
        ///
        /// @param mode: 0 = without interest. 1 = with interest
        uint8 mode;
        ///
        /// @param expandPercent debt limit expand percent. in 1e2: 100% = 10_000; 1% = 100
        /// Also used to calculate rate at which debt limit should decrease (instant).
        uint256 expandPercent;
        ///
        /// @param expandDuration debt limit expand duration in seconds.
        /// used to calculate rate together with expandPercent
        uint256 expandDuration;
        ///
        /// @param baseDebtCeiling base borrow limit. until here, borrow limit remains as baseDebtCeiling
        /// (user can borrow until this point at once without stepped expansion). Above this, automated limit comes in place.
        /// amount in raw (to be multiplied with exchange price) or normal depends on configured mode in user config for the token:
        /// with interest -> raw, without interest -> normal
        uint256 baseDebtCeiling;
        ///
        /// @param maxDebtCeiling max borrow ceiling, maximum amount the user can borrow.
        /// amount in raw (to be multiplied with exchange price) or normal depends on configured mode in user config for the token:
        /// with interest -> raw, without interest -> normal
        uint256 maxDebtCeiling;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IProxy } from "../../infiniteProxy/interfaces/iProxy.sol";
import { Structs as AdminModuleStructs } from "../adminModule/structs.sol";

interface IFluidLiquidityAdmin {
    /// @notice adds/removes auths. Auths generally could be contracts which can have restricted actions defined on contract.
    ///         auths can be helpful in reducing governance overhead where it's not needed.
    /// @param authsStatus_ array of structs setting allowed status for an address.
    ///                     status true => add auth, false => remove auth
    function updateAuths(AdminModuleStructs.AddressBool[] calldata authsStatus_) external;

    /// @notice adds/removes guardians. Only callable by Governance.
    /// @param guardiansStatus_ array of structs setting allowed status for an address.
    ///                         status true => add guardian, false => remove guardian
    function updateGuardians(AdminModuleStructs.AddressBool[] calldata guardiansStatus_) external;

    /// @notice changes the revenue collector address (contract that is sent revenue). Only callable by Governance.
    /// @param revenueCollector_  new revenue collector address
    function updateRevenueCollector(address revenueCollector_) external;

    /// @notice changes current status, e.g. for pausing or unpausing all user operations. Only callable by Auths.
    /// @param newStatus_ new status
    ///        status = 2 -> pause, status = 1 -> resume.
    function changeStatus(uint256 newStatus_) external;

    /// @notice                  update tokens rate data version 1. Only callable by Auths.
    /// @param tokensRateData_   array of RateDataV1Params with rate data to set for each token
    function updateRateDataV1s(AdminModuleStructs.RateDataV1Params[] calldata tokensRateData_) external;

    /// @notice                  update tokens rate data version 2. Only callable by Auths.
    /// @param tokensRateData_   array of RateDataV2Params with rate data to set for each token
    function updateRateDataV2s(AdminModuleStructs.RateDataV2Params[] calldata tokensRateData_) external;

    /// @notice updates token configs: fee charge on borrowers interest & storage update utilization threshold.
    ///         Only callable by Auths.
    /// @param tokenConfigs_ contains token address, fee & utilization threshold
    function updateTokenConfigs(AdminModuleStructs.TokenConfig[] calldata tokenConfigs_) external;

    /// @notice updates user classes: 0 is for new protocols, 1 is for established protocols.
    ///         Only callable by Auths.
    /// @param userClasses_ struct array of uint256 value to assign for each user address
    function updateUserClasses(AdminModuleStructs.AddressUint256[] calldata userClasses_) external;

    /// @notice sets user supply configs per token basis. Eg: with interest or interest-free and automated limits.
    ///         Only callable by Auths.
    /// @param userSupplyConfigs_ struct array containing user supply config, see `UserSupplyConfig` struct for more info
    function updateUserSupplyConfigs(AdminModuleStructs.UserSupplyConfig[] memory userSupplyConfigs_) external;

    /// @notice setting user borrow configs per token basis. Eg: with interest or interest-free and automated limits.
    ///         Only callable by Auths.
    /// @param userBorrowConfigs_ struct array containing user borrow config, see `UserBorrowConfig` struct for more info
    function updateUserBorrowConfigs(AdminModuleStructs.UserBorrowConfig[] memory userBorrowConfigs_) external;

    /// @notice pause operations for a particular user in class 0 (class 1 users can't be paused by guardians).
    /// Only callable by Guardians.
    /// @param user_          address of user to pause operations for
    /// @param supplyTokens_  token addresses to pause withdrawals for
    /// @param borrowTokens_  token addresses to pause borrowings for
    function pauseUser(address user_, address[] calldata supplyTokens_, address[] calldata borrowTokens_) external;

    /// @notice unpause operations for a particular user in class 0 (class 1 users can't be paused by guardians).
    /// Only callable by Guardians.
    /// @param user_          address of user to unpause operations for
    /// @param supplyTokens_  token addresses to unpause withdrawals for
    /// @param borrowTokens_  token addresses to unpause borrowings for
    function unpauseUser(address user_, address[] calldata supplyTokens_, address[] calldata borrowTokens_) external;

    /// @notice         collects revenue for tokens to configured revenueCollector address.
    /// @param tokens_  array of tokens to collect revenue for
    /// @dev            Note that this can revert if token balance is < revenueAmount (utilization > 100%)
    function collectRevenue(address[] calldata tokens_) external;

    /// @notice gets the current updated exchange prices for n tokens and updates all prices, rates related data in storage.
    /// @param tokens_ tokens to update exchange prices for
    /// @return supplyExchangePrices_ new supply rates of overall system for each token
    /// @return borrowExchangePrices_ new borrow rates of overall system for each token
    function updateExchangePrices(
        address[] calldata tokens_
    ) external returns (uint256[] memory supplyExchangePrices_, uint256[] memory borrowExchangePrices_);
}

interface IFluidLiquidityLogic is IFluidLiquidityAdmin {
    /// @notice Single function which handles supply, withdraw, borrow & payback
    /// @param token_ address of token (0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE for native)
    /// @param supplyAmount_ if +ve then supply, if -ve then withdraw, if 0 then nothing
    /// @param borrowAmount_ if +ve then borrow, if -ve then payback, if 0 then nothing
    /// @param withdrawTo_ if withdrawal then to which address
    /// @param borrowTo_ if borrow then to which address
    /// @param callbackData_ callback data passed to `liquidityCallback` method of protocol
    /// @return memVar3_ updated supplyExchangePrice
    /// @return memVar4_ updated borrowExchangePrice
    /// @dev to trigger skipping in / out transfers when in&out amounts balance themselves out (gas optimization):
    /// -   supply(+) == borrow(+), withdraw(-) == payback(-).
    /// -   `withdrawTo_` / `borrowTo_` must be msg.sender (protocol)
    /// -   `callbackData_` MUST be encoded so that "from" address is at last 20 bytes (if this optimization is desired),
    ///     also for native token operations where liquidityCallback is not triggered!
    ///     from address must come at last position if there is more data. I.e. encode like:
    ///     abi.encode(otherVar1, otherVar2, FROM_ADDRESS). Note dynamic types used with abi.encode come at the end
    ///     so if dynamic types are needed, you must use abi.encodePacked to ensure the from address is at the end.
    function operate(
        address token_,
        int256 supplyAmount_,
        int256 borrowAmount_,
        address withdrawTo_,
        address borrowTo_,
        bytes calldata callbackData_
    ) external payable returns (uint256 memVar3_, uint256 memVar4_);
}

interface IFluidLiquidity is IProxy, IFluidLiquidityLogic {}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

abstract contract Error {
    error FluidLendingError(uint256 errorId_);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

library ErrorTypes {
    /***********************************|
    |               fToken              | 
    |__________________________________*/

    /// @notice thrown when a deposit amount is too small to increase BigMath stored balance in Liquidity.
    /// precision of BigMath is 1e12, so if token holds 120_000_000_000 USDC, min amount to make a difference would be 0.1 USDC.
    /// i.e. user would send a very small deposit which mints no shares -> revert
    uint256 internal constant fToken__DepositInsignificant = 20001;

    /// @notice thrown when minimum output amount is not reached, e.g. for minimum shares minted (deposit) or
    ///         minimum assets received (redeem)
    uint256 internal constant fToken__MinAmountOut = 20002;

    /// @notice thrown when maximum amount is surpassed, e.g. for maximum shares burned (withdraw) or
    ///         maximum assets input (mint)
    uint256 internal constant fToken__MaxAmount = 20003;

    /// @notice thrown when invalid params are sent to a method, e.g. zero address
    uint256 internal constant fToken__InvalidParams = 20004;

    /// @notice thrown when an unauthorized caller is trying to execute an auth-protected method
    uint256 internal constant fToken__Unauthorized = 20005;

    /// @notice thrown when a with permit / signature method is called from msg.sender that is the owner.
    /// Should call the method without permit instead if msg.sender is the owner.
    uint256 internal constant fToken__PermitFromOwnerCall = 20006;

    /// @notice thrown when a reentrancy is detected.
    uint256 internal constant fToken__Reentrancy = 20007;

    /// @notice thrown when _tokenExchangePrice overflows type(uint64).max
    uint256 internal constant fToken__ExchangePriceOverflow = 20008;

    /// @notice thrown when msg.sender is not rebalancer
    uint256 internal constant fToken__NotRebalancer = 20009;

    /// @notice thrown when rebalance is called with msg.value > 0 for non NativeUnderlying fToken
    uint256 internal constant fToken__NotNativeUnderlying = 20010;

    /// @notice thrown when the received new liquidity exchange price is of unexpected value (< than the old one)
    uint256 internal constant fToken__LiquidityExchangePriceUnexpected = 20011;

    /***********************************|
    |     fToken Native Underlying      | 
    |__________________________________*/

    /// @notice thrown when native deposit is called but sent along `msg.value` does not cover the deposit amount
    uint256 internal constant fTokenNativeUnderlying__TransferInsufficient = 21001;

    /// @notice thrown when a liquidity callback is called for a native token operation
    uint256 internal constant fTokenNativeUnderlying__UnexpectedLiquidityCallback = 21002;

    /***********************************|
    |         Lending Factory         | 
    |__________________________________*/

    /// @notice thrown when a method is called with invalid params
    uint256 internal constant LendingFactory__InvalidParams = 22001;

    /// @notice thrown when the provided input param address is zero
    uint256 internal constant LendingFactory__ZeroAddress = 22002;

    /// @notice thrown when the token already exists
    uint256 internal constant LendingFactory__TokenExists = 22003;

    /// @notice thrown when the fToken has not yet been configured at Liquidity
    uint256 internal constant LendingFactory__LiquidityNotConfigured = 22004;

    /// @notice thrown when an unauthorized caller is trying to execute an auth-protected method
    uint256 internal constant LendingFactory__Unauthorized = 22005;

    /***********************************|
    |   Lending Rewards Rate Model      | 
    |__________________________________*/

    /// @notice thrown when invalid params are given as input
    uint256 internal constant LendingRewardsRateModel__InvalidParams = 23001;

    /// @notice thrown when calculated rewards rate is exceeding the maximum rate
    uint256 internal constant LendingRewardsRateModel__MaxRate = 23002;

    /// @notice thrown when start is called by any other address other than initiator
    uint256 internal constant LendingRewardsRateModel__NotTheInitiator = 23003;

    /// @notice thrown when start is called after the rewards are already started
    uint256 internal constant LendingRewardsRateModel__AlreadyStarted = 23004;

    /// @notice thrown when the provided input param address is zero
    uint256 internal constant LendingRewardsRateModel__ZeroAddress = 23005;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IFluidLiquidity } from "../../../liquidity/interfaces/iLiquidity.sol";

interface IFluidLendingFactoryAdmin {
    /// @notice reads if a certain `auth_` address is an allowed auth or not. Owner is auth by default.
    function isAuth(address auth_) external view returns (bool);

    /// @notice              Sets an address as allowed auth or not. Only callable by owner.
    /// @param auth_         address to set auth value for
    /// @param allowed_      bool flag for whether address is allowed as auth or not
    function setAuth(address auth_, bool allowed_) external;

    /// @notice reads if a certain `deployer_` address is an allowed deployer or not. Owner is deployer by default.
    function isDeployer(address deployer_) external view returns (bool);

    /// @notice              Sets an address as allowed deployer or not. Only callable by owner.
    /// @param deployer_     address to set deployer value for
    /// @param allowed_      bool flag for whether address is allowed as deployer or not
    function setDeployer(address deployer_, bool allowed_) external;

    /// @notice              Sets the `creationCode_` bytecode for a certain `fTokenType_`. Only callable by auths.
    /// @param fTokenType_   the fToken Type used to refer the creation code
    /// @param creationCode_ contract creation code. can be set to bytes(0) to remove a previously available `fTokenType_`
    function setFTokenCreationCode(string memory fTokenType_, bytes calldata creationCode_) external;

    /// @notice creates token for `asset_` for a lending protocol with interest. Only callable by deployers.
    /// @param  asset_              address of the asset
    /// @param  fTokenType_         type of fToken:
    /// - if it's the native token, it should use `NativeUnderlying`
    /// - otherwise it should use `fToken`
    /// - could be more types available, check `fTokenTypes()`
    /// @param  isNativeUnderlying_ flag to signal fToken type that uses native underlying at Liquidity
    /// @return token_              address of the created token
    function createToken(
        address asset_,
        string calldata fTokenType_,
        bool isNativeUnderlying_
    ) external returns (address token_);
}

interface IFluidLendingFactory is IFluidLendingFactoryAdmin {
    /// @notice list of all created tokens
    function allTokens() external view returns (address[] memory);

    /// @notice list of all fToken types that can be deployed
    function fTokenTypes() external view returns (string[] memory);

    /// @notice returns the creation code for a certain `fTokenType_`
    function fTokenCreationCode(string memory fTokenType_) external view returns (bytes memory);

    /// @notice address of the Liquidity contract.
    function LIQUIDITY() external view returns (IFluidLiquidity);

    /// @notice computes deterministic token address for `asset_` for a lending protocol
    /// @param  asset_      address of the asset
    /// @param  fTokenType_         type of fToken:
    /// - if it's the native token, it should use `NativeUnderlying`
    /// - otherwise it should use `fToken`
    /// - could be more types available, check `fTokenTypes()`
    /// @return token_      detemrinistic address of the computed token
    function computeToken(address asset_, string calldata fTokenType_) external view returns (address token_);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import { IFluidLendingFactory } from "../interfaces/iLendingFactory.sol";

abstract contract Events {
    /// @notice emitted when a new fToken is created
    event LogTokenCreated(address indexed token, address indexed asset, uint256 indexed count, string fTokenType);

    /// @notice emitted when an auth is modified by owner
    event LogSetAuth(address indexed auth, bool indexed allowed);

    /// @notice emitted when a deployer is modified by owner
    event LogSetDeployer(address indexed deployer, bool indexed allowed);

    /// @notice emitted when the creation code for an fTokenType is set
    event LogSetFTokenCreationCode(string indexed fTokenType, address indexed creationCodePointer);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import { CREATE3 } from "solmate/src/utils/CREATE3.sol";
import { SSTORE2 } from "solmate/src/utils/SSTORE2.sol";
import { Owned } from "solmate/src/auth/Owned.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { IFluidLiquidity } from "../../../liquidity/interfaces/iLiquidity.sol";
import { IFluidLendingFactory, IFluidLendingFactoryAdmin } from "../interfaces/iLendingFactory.sol";
import { LiquiditySlotsLink } from "../../../libraries/liquiditySlotsLink.sol";
import { ErrorTypes } from "../errorTypes.sol";
import { Error } from "../error.sol";
import { Events } from "./events.sol";

abstract contract LendingFactoryVariables is Owned, Error, IFluidLendingFactory {
    /*//////////////////////////////////////////////////////////////
                          CONSTANTS / IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IFluidLendingFactory
    IFluidLiquidity public immutable LIQUIDITY;

    /// @dev address that is mapped to the chain native token
    address internal constant _NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /*//////////////////////////////////////////////////////////////
                          STORAGE VARIABLES
    //////////////////////////////////////////////////////////////*/

    // ------------ storage variables from inherited contracts (Owned) come before vars here --------

    // ----------------------- slot 0 ---------------------------
    // address public owner;

    // 12 bytes empty

    // ----------------------- slot 1 ---------------------------
    /// @dev auths can update rewards related config at created fToken contracts.
    /// owner can add/remove auths.
    /// Owner is auth by default.
    mapping(address => uint256) internal _auths;

    // ----------------------- slot 2 ---------------------------
    /// @dev deployers can deploy new fTokens.
    /// owner can add/remove deployers.
    /// Owner is deployer by default.
    mapping(address => uint256) internal _deployers;

    // ----------------------- slot 3 ---------------------------
    /// @dev list of all created tokens.
    /// Solidity creates an automatic getter only to fetch at a certain position, so explicitly define a getter that returns all.
    address[] internal _allTokens;

    // ----------------------- slot 4 ---------------------------

    /// @dev available fTokenTypes for deployment. At least EIP2612Deposits, Permit2Deposits, NativeUnderlying.
    /// Solidity creates an automatic getter only to fetch at a certain position, so explicitly define a getter that returns all.
    string[] internal _fTokenTypes;

    // ----------------------- slot 5 ---------------------------

    /// @dev fToken creation code for each fTokenType, accessed via SSTORE2.
    /// maps keccak256(abi.encode(fTokenType)) -> SSTORE2 written creation code for the fToken contract
    mapping(bytes32 => address) internal _fTokenCreationCodePointers;

    /*//////////////////////////////////////////////////////////////
                          CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IFluidLiquidity liquidity_, address owner_) Owned(owner_) {
        if (owner_ == address(0)) {
            // Owned does not have a zero check for owner_
            revert FluidLendingError(ErrorTypes.LendingFactory__ZeroAddress);
        }

        LIQUIDITY = liquidity_;
    }

    /// @inheritdoc IFluidLendingFactory
    function allTokens() public view returns (address[] memory) {
        return _allTokens;
    }

    /// @inheritdoc IFluidLendingFactory
    function fTokenTypes() public view returns (string[] memory) {
        return _fTokenTypes;
    }

    /// @inheritdoc IFluidLendingFactory
    function fTokenCreationCode(string memory fTokenType_) public view returns (bytes memory) {
        address creationCodePointer_ = _fTokenCreationCodePointers[keccak256(abi.encode(fTokenType_))];
        return creationCodePointer_ == address(0) ? new bytes(0) : SSTORE2.read(creationCodePointer_);
    }
}

abstract contract LendingFactoryAdmin is LendingFactoryVariables, Events {
    /// @dev validates that an address is not the zero address
    modifier validAddress(address value_) {
        if (value_ == address(0)) {
            revert FluidLendingError(ErrorTypes.LendingFactory__ZeroAddress);
        }
        _;
    }

    /// @dev validates that msg.sender is auth or owner
    modifier onlyAuths() {
        if (!isAuth(msg.sender)) {
            revert FluidLendingError(ErrorTypes.LendingFactory__Unauthorized);
        }
        _;
    }

    /// @dev validates that msg.sender is deployer or owner
    modifier onlyDeployers() {
        if (!isDeployer(msg.sender)) {
            revert FluidLendingError(ErrorTypes.LendingFactory__Unauthorized);
        }
        _;
    }

    /// @inheritdoc IFluidLendingFactoryAdmin
    function isAuth(address auth_) public view returns (bool) {
        return auth_ == owner || _auths[auth_] == 1;
    }

    /// @inheritdoc IFluidLendingFactoryAdmin
    function isDeployer(address deployer_) public view returns (bool) {
        return deployer_ == owner || _deployers[deployer_] == 1;
    }

    /// @inheritdoc IFluidLendingFactoryAdmin
    function setAuth(address auth_, bool allowed_) external onlyOwner validAddress(auth_) {
        _auths[auth_] = allowed_ ? 1 : 0;

        emit LogSetAuth(auth_, allowed_);
    }

    /// @inheritdoc IFluidLendingFactoryAdmin
    function setDeployer(address deployer_, bool allowed_) external onlyOwner validAddress(deployer_) {
        _deployers[deployer_] = allowed_ ? 1 : 0;

        emit LogSetDeployer(deployer_, allowed_);
    }

    /// @inheritdoc IFluidLendingFactoryAdmin
    function setFTokenCreationCode(string memory fTokenType_, bytes calldata creationCode_) external onlyAuths {
        uint256 length_ = _fTokenTypes.length;
        bytes32 fTokenTypeHash_ = keccak256(abi.encode(fTokenType_));

        if (creationCode_.length == 0) {
            // remove any previously stored creation code for `fTokenType_`
            delete _fTokenCreationCodePointers[keccak256(abi.encode(fTokenType_))];

            // remove key from array _fTokenTypes. _fTokenTypes is most likely an array of very few elements,
            // where setFTokenCreationCode is a rarely called method and the removal of an fTokenType is even more rare.
            // So gas cost is not really an issue here but even if it were, this should still be cheaper than having
            // an additional mapping like with an OpenZeppelin EnumerableSet
            for (uint256 i; i < length_; ++i) {
                if (keccak256(abi.encode(_fTokenTypes[i])) == fTokenTypeHash_) {
                    _fTokenTypes[i] = _fTokenTypes[length_ - 1];
                    _fTokenTypes.pop();
                    break;
                }
            }

            emit LogSetFTokenCreationCode(fTokenType_, address(0));
        } else {
            // write creation code to SSTORE2 pointer and set in mapping
            address creationCodePointer_ = SSTORE2.write(creationCode_);
            _fTokenCreationCodePointers[keccak256(abi.encode(fTokenType_))] = creationCodePointer_;

            // make sure `fTokenType_` is present in array _fTokenTypes
            bool isPresent_;
            for (uint256 i; i < length_; ++i) {
                if (keccak256(abi.encode(_fTokenTypes[i])) == fTokenTypeHash_) {
                    isPresent_ = true;
                    break;
                }
            }
            if (!isPresent_) {
                _fTokenTypes.push(fTokenType_);
            }

            emit LogSetFTokenCreationCode(fTokenType_, creationCodePointer_);
        }
    }

    /// @inheritdoc IFluidLendingFactoryAdmin
    function createToken(
        address asset_,
        string calldata fTokenType_,
        bool isNativeUnderlying_
    ) external validAddress(asset_) onlyDeployers returns (address token_) {
        address creationCodePointer_ = _fTokenCreationCodePointers[keccak256(abi.encode(fTokenType_))];
        if (creationCodePointer_ == address(0)) {
            revert FluidLendingError(ErrorTypes.LendingFactory__InvalidParams);
        }

        bytes32 salt_ = _getSalt(asset_, fTokenType_);

        if (Address.isContract(CREATE3.getDeployed(salt_))) {
            // revert if token already exists (Solmate CREATE3 does not check before deploying)
            revert FluidLendingError(ErrorTypes.LendingFactory__TokenExists);
        }

        bytes32 liquidityExchangePricesSlot_ = LiquiditySlotsLink.calculateMappingStorageSlot(
            LiquiditySlotsLink.LIQUIDITY_EXCHANGE_PRICES_MAPPING_SLOT,
            // native underlying always uses the native token at Liquidity, but also supports WETH
            isNativeUnderlying_ ? _NATIVE_TOKEN_ADDRESS : asset_
        );
        if (LIQUIDITY.readFromStorage(liquidityExchangePricesSlot_) == 0) {
            // revert if fToken has not been configured at Liquidity contract yet (exchange prices config)
            revert FluidLendingError(ErrorTypes.LendingFactory__LiquidityNotConfigured);
        }

        // Use CREATE3 for deterministic deployments. Unfortunately it has 55k gas overhead
        token_ = CREATE3.deploy(
            salt_,
            abi.encodePacked(
                SSTORE2.read(creationCodePointer_), // creation code
                abi.encode(LIQUIDITY, address(this), asset_) // constructor params
            ),
            0
        );

        // Add the created token to the allTokens array
        _allTokens.push(token_);

        // Emit the TokenCreated event
        emit LogTokenCreated(token_, asset_, _allTokens.length, fTokenType_);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @dev gets the CREATE3 salt for `asset_` and `fTokenType_`
    function _getSalt(address asset_, string calldata fTokenType_) internal pure returns (bytes32) {
        return keccak256(abi.encode(asset_, fTokenType_));
    }
}

/// @title Fluid LendingFactory
/// @notice creates Fluid lending protocol fTokens, which are interacting with Fluid Liquidity.
/// fTokens are ERC20 & ERC4626 compatible tokens that allow to deposit to Fluid Liquidity to earn interest.
/// Tokens are created at a deterministic address (see `computeToken()`), only executable by allow-listed auths.
/// @dev Note the deployed token starts out with no config at Liquidity contract.
/// This must be done by Liquidity auths in a separate step, otherwise no deposits will be possible.
/// This contract is not upgradeable. It supports adding new fToken creation codes for future new fToken types.
contract FluidLendingFactory is LendingFactoryVariables, LendingFactoryAdmin {
    /// @notice initialize liquidity contract address & owner
    constructor(
        IFluidLiquidity liquidity_,
        address owner_
    ) validAddress(address(liquidity_)) validAddress(owner) LendingFactoryVariables(liquidity_, owner_) {}

    /// @inheritdoc IFluidLendingFactory
    function computeToken(address asset_, string calldata fTokenType_) public view returns (address token_) {
        return CREATE3.getDeployed(_getSalt(asset_, fTokenType_));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Library for converting between addresses and bytes32 values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Bytes32AddressLib.sol)
library Bytes32AddressLib {
    function fromLast20Bytes(bytes32 bytesValue) internal pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    function fillLast12Bytes(address addressValue) internal pure returns (bytes32) {
        return bytes32(bytes20(addressValue));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {Bytes32AddressLib} from "./Bytes32AddressLib.sol";

/// @notice Deploy to deterministic addresses without an initcode factor.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/CREATE3.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/create3/blob/master/contracts/Create3.sol)
library CREATE3 {
    using Bytes32AddressLib for bytes32;

    //--------------------------------------------------------------------------------//
    // Opcode     | Opcode + Arguments    | Description      | Stack View             //
    //--------------------------------------------------------------------------------//
    // 0x36       |  0x36                 | CALLDATASIZE     | size                   //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 size                 //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 0 size               //
    // 0x37       |  0x37                 | CALLDATACOPY     |                        //
    // 0x36       |  0x36                 | CALLDATASIZE     | size                   //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 size                 //
    // 0x34       |  0x34                 | CALLVALUE        | value 0 size           //
    // 0xf0       |  0xf0                 | CREATE           | newContract            //
    //--------------------------------------------------------------------------------//
    // Opcode     | Opcode + Arguments    | Description      | Stack View             //
    //--------------------------------------------------------------------------------//
    // 0x67       |  0x67XXXXXXXXXXXXXXXX | PUSH8 bytecode   | bytecode               //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 bytecode             //
    // 0x52       |  0x52                 | MSTORE           |                        //
    // 0x60       |  0x6008               | PUSH1 08         | 8                      //
    // 0x60       |  0x6018               | PUSH1 18         | 24 8                   //
    // 0xf3       |  0xf3                 | RETURN           |                        //
    //--------------------------------------------------------------------------------//
    bytes internal constant PROXY_BYTECODE = hex"67_36_3d_3d_37_36_3d_34_f0_3d_52_60_08_60_18_f3";

    bytes32 internal constant PROXY_BYTECODE_HASH = keccak256(PROXY_BYTECODE);

    function deploy(
        bytes32 salt,
        bytes memory creationCode,
        uint256 value
    ) internal returns (address deployed) {
        bytes memory proxyChildBytecode = PROXY_BYTECODE;

        address proxy;
        /// @solidity memory-safe-assembly
        assembly {
            // Deploy a new contract with our pre-made bytecode via CREATE2.
            // We start 32 bytes into the code to avoid copying the byte length.
            proxy := create2(0, add(proxyChildBytecode, 32), mload(proxyChildBytecode), salt)
        }
        require(proxy != address(0), "DEPLOYMENT_FAILED");

        deployed = getDeployed(salt);
        (bool success, ) = proxy.call{value: value}(creationCode);
        require(success && deployed.code.length != 0, "INITIALIZATION_FAILED");
    }

    function getDeployed(bytes32 salt) internal view returns (address) {
        address proxy = keccak256(
            abi.encodePacked(
                // Prefix:
                bytes1(0xFF),
                // Creator:
                address(this),
                // Salt:
                salt,
                // Bytecode hash:
                PROXY_BYTECODE_HASH
            )
        ).fromLast20Bytes();

        return
            keccak256(
                abi.encodePacked(
                    // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01)
                    // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex)
                    hex"d6_94",
                    proxy,
                    hex"01" // Nonce of the proxy contract (1)
                )
            ).fromLast20Bytes();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    uint256 internal constant DATA_OFFSET = 1; // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.

    /*//////////////////////////////////////////////////////////////
                               WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    function write(bytes memory data) internal returns (address pointer) {
        // Prefix the bytecode with a STOP opcode to ensure it cannot be called.
        bytes memory runtimeCode = abi.encodePacked(hex"00", data);

        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x600B             | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xf3    |  0xf3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            hex"60_0B_59_81_38_03_80_92_59_39_F3", // Returns all code in the contract except for the first 11 (0B in hex) bytes.
            runtimeCode // The bytecode we want the contract to have after deployment. Capped at 1 byte less than the code size limit.
        );

        /// @solidity memory-safe-assembly
        assembly {
            // Deploy a new contract with the generated creation code.
            // We start 32 bytes into the code to avoid copying the byte length.
            pointer := create(0, add(creationCode, 32), mload(creationCode))
        }

        require(pointer != address(0), "DEPLOYMENT_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    function read(address pointer) internal view returns (bytes memory) {
        return readBytecode(pointer, DATA_OFFSET, pointer.code.length - DATA_OFFSET);
    }

    function read(address pointer, uint256 start) internal view returns (bytes memory) {
        start += DATA_OFFSET;

        return readBytecode(pointer, start, pointer.code.length - start);
    }

    function read(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory) {
        start += DATA_OFFSET;
        end += DATA_OFFSET;

        require(pointer.code.length >= end, "OUT_OF_BOUNDS");

        return readBytecode(pointer, start, end - start);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function readBytecode(
        address pointer,
        uint256 start,
        uint256 size
    ) private view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to size and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), start, size)
        }
    }
}