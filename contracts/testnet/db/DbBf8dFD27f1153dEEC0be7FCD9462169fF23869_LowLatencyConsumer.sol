/**
 *Submitted for verification at Arbiscan.io on 2023-10-09
*/

// Sources flattened with hardhat v2.17.3 https://hardhat.org

// SPDX-License-Identifier: GPL-2.0-or-later AND MIT

pragma abicoder v2;

// File @chainlink/contracts/src/v0.8/automation/interfaces/[email protected]

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
    /**
     * @notice method that is simulated by the keepers to see if any work actually
     * needs to be performed. This method does does not actually need to be
     * executable, and since it is only ever simulated it can consume lots of gas.
     * @dev To ensure that it is never called, you may want to add the
     * cannotExecute modifier from KeeperBase to your implementation of this
     * method.
     * @param checkData specified in the upkeep registration so it is always the
     * same for a registered upkeep. This can easily be broken down into specific
     * arguments using `abi.decode`, so multiple upkeeps can be registered on the
     * same contract and easily differentiated by the contract.
     * @return upkeepNeeded boolean to indicate whether the keeper should call
     * performUpkeep or not.
     * @return performData bytes that the keeper should call performUpkeep with, if
     * upkeep is needed. If you would like to encode data to decode later, try
     * `abi.encode`.
     */
    function checkUpkeep(
        bytes calldata checkData
    ) external returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @notice method that is actually executed by the keepers, via the registry.
     * The data returned by the checkUpkeep simulation will be passed into
     * this method to actually be executed.
     * @dev The input to this method should not be trusted, and the caller of the
     * method should not even be restricted to any single registry. Anyone should
     * be able call it, and the input should be validated, there is no guarantee
     * that the data passed in is the performData returned from checkUpkeep. This
     * could happen due to malicious keepers, racing keepers, or simply a state
     * change while the performUpkeep transaction is waiting for confirmation.
     * Always validate the data passed in.
     * @param performData is the data which was passed back from the checkData
     * simulation. If it is encoded, it can easily be decoded into other types by
     * calling `abi.decode`. This data should not be trusted, and should be
     * validated against the contract's current state.
     */
    function performUpkeep(bytes calldata performData) external;
}

// File @chainlink/contracts/src/v0.8/automation/interfaces/[email protected]

// Original license: SPDX_License_Identifier: MIT
/**
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;

// File @chainlink/contracts/src/v0.8/libraries/[email protected]

// Original license: SPDX_License_Identifier: MIT
pragma solidity 0.8.16;

/*
 * @title Common
 * @author Michael Fletcher
 * @notice Common functions and structs
 */
library Common {
    // @notice The asset struct to hold the address of an asset and amount
    struct Asset {
        address assetAddress;
        uint256 amount;
    }

    // @notice Struct to hold the address and its associated weight
    struct AddressAndWeight {
        address addr;
        uint64 weight;
    }

    /**
     * @notice Checks if an array of AddressAndWeight has duplicate addresses
     * @param recipients The array of AddressAndWeight to check
     * @return bool True if there are duplicates, false otherwise
     */
    function hasDuplicateAddresses(
        Common.AddressAndWeight[] memory recipients
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < recipients.length; ) {
            for (uint256 j = i + 1; j < recipients.length; ) {
                if (recipients[i].addr == recipients[j].addr) {
                    return true;
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
        return false;
    }
}

// File @chainlink/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/contracts/utils/introspection/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File @chainlink/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/contracts/interfaces/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

// File @chainlink/contracts/src/v0.8/llo-feeds/interfaces/[email protected]

// Original license: SPDX_License_Identifier: MIT
pragma solidity 0.8.16;

interface IVerifier is IERC165 {
    /**
     * @notice Verifies that the data encoded has been signed
     * correctly by routing to the correct verifier.
     * @param signedReport The encoded data to be verified.
     * @param sender The address that requested to verify the contract.
     * This is only used for logging purposes.
     * @dev Verification is typically only done through the proxy contract so
     * we can't just use msg.sender to log the requester as the msg.sender
     * contract will always be the proxy.
     * @return verifierResponse The encoded verified response.
     */
    function verify(
        bytes calldata signedReport,
        address sender
    ) external returns (bytes memory verifierResponse);

    /**
     * @notice sets offchain reporting protocol configuration incl. participating oracles
     * @param feedId Feed ID to set config for
     * @param signers addresses with which oracles sign the reports
     * @param offchainTransmitters CSA key for the ith Oracle
     * @param f number of faulty oracles the system can tolerate
     * @param onchainConfig serialized configuration used by the contract (and possibly oracles)
     * @param offchainConfigVersion version number for offchainEncoding schema
     * @param offchainConfig serialized configuration used by the oracles exclusively and only passed through the contract
     * @param recipientAddressesAndWeights the addresses and weights of all the recipients to receive rewards
     */
    function setConfig(
        bytes32 feedId,
        address[] memory signers,
        bytes32[] memory offchainTransmitters,
        uint8 f,
        bytes memory onchainConfig,
        uint64 offchainConfigVersion,
        bytes memory offchainConfig,
        Common.AddressAndWeight[] memory recipientAddressesAndWeights
    ) external;

    /**
     * @notice identical to `setConfig` except with args for sourceChainId and sourceAddress
     * @param feedId Feed ID to set config for
     * @param sourceChainId Chain ID of source config
     * @param sourceAddress Address of source config Verifier
     * @param newConfigCount Param to force the new config count
     * @param signers addresses with which oracles sign the reports
     * @param offchainTransmitters CSA key for the ith Oracle
     * @param f number of faulty oracles the system can tolerate
     * @param onchainConfig serialized configuration used by the contract (and possibly oracles)
     * @param offchainConfigVersion version number for offchainEncoding schema
     * @param offchainConfig serialized configuration used by the oracles exclusively and only passed through the contract
     * @param recipientAddressesAndWeights the addresses and weights of all the recipients to receive rewards
     */
    function setConfigFromSource(
        bytes32 feedId,
        uint256 sourceChainId,
        address sourceAddress,
        uint32 newConfigCount,
        address[] memory signers,
        bytes32[] memory offchainTransmitters,
        uint8 f,
        bytes memory onchainConfig,
        uint64 offchainConfigVersion,
        bytes memory offchainConfig,
        Common.AddressAndWeight[] memory recipientAddressesAndWeights
    ) external;

    /**
     * @notice Activates the configuration for a config digest
     * @param feedId Feed ID to activate config for
     * @param configDigest The config digest to activate
     * @dev This function can be called by the contract admin to activate a configuration.
     */
    function activateConfig(bytes32 feedId, bytes32 configDigest) external;

    /**
     * @notice Deactivates the configuration for a config digest
     * @param feedId Feed ID to deactivate config for
     * @param configDigest The config digest to deactivate
     * @dev This function can be called by the contract admin to deactivate an incorrect configuration.
     */
    function deactivateConfig(bytes32 feedId, bytes32 configDigest) external;

    /**
     * @notice Activates the given feed
     * @param feedId Feed ID to activated
     * @dev This function can be called by the contract admin to activate a feed
     */
    function activateFeed(bytes32 feedId) external;

    /**
     * @notice Deactivates the given feed
     * @param feedId Feed ID to deactivated
     * @dev This function can be called by the contract admin to deactivate a feed
     */
    function deactivateFeed(bytes32 feedId) external;

    /**
     * @notice returns the latest config digest and epoch for a feed
     * @param feedId Feed ID to fetch data for
     * @return scanLogs indicates whether to rely on the configDigest and epoch
     * returned or whether to scan logs for the Transmitted event instead.
     * @return configDigest
     * @return epoch
     */
    function latestConfigDigestAndEpoch(
        bytes32 feedId
    ) external view returns (bool scanLogs, bytes32 configDigest, uint32 epoch);

    /**
     * @notice information about current offchain reporting protocol configuration
     * @param feedId Feed ID to fetch data for
     * @return configCount ordinal number of current config, out of all configs applied to this contract so far
     * @return blockNumber block at which this config was set
     * @return configDigest domain-separation tag for current config
     */
    function latestConfigDetails(
        bytes32 feedId
    )
        external
        view
        returns (uint32 configCount, uint32 blockNumber, bytes32 configDigest);
}

// File @uniswap/v3-core/contracts/interfaces/callback/[email protected]

// Original license: SPDX_License_Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// File contracts/interfaces/ISwapRouter.sol

// Original license: SPDX_License_Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

// Original pragma directive: pragma abicoder v2

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
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
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(
        ExactOutputSingleParams calldata params
    ) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(
        ExactOutputParams calldata params
    ) external payable returns (uint256 amountIn);
}

// File @chainlink/contracts/src/v0.8/automation/interfaces/[email protected]

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @member index the index of the log in the block. 0 for the first log
 * @member timestamp the timestamp of the block containing the log
 * @member txHash the hash of the transaction containing the log
 * @member blockNumber the number of the block containing the log
 * @member blockHash the hash of the block containing the log
 * @member source the address of the contract that emitted the log
 * @member topics the indexed topics of the log
 * @member data the data of the log
 */
struct Log {
    uint256 index;
    uint256 timestamp;
    bytes32 txHash;
    uint256 blockNumber;
    bytes32 blockHash;
    address source;
    bytes32[] topics;
    bytes data;
}

interface ILogAutomation {
    /**
     * @notice method that is simulated by the keepers to see if any work actually
     * needs to be performed. This method does does not actually need to be
     * executable, and since it is only ever simulated it can consume lots of gas.
     * @dev To ensure that it is never called, you may want to add the
     * cannotExecute modifier from KeeperBase to your implementation of this
     * method.
     * @param log the raw log data matching the filter that this contract has
     * registered as a trigger
     * @param checkData user-specified extra data to provide context to this upkeep
     * @return upkeepNeeded boolean to indicate whether the keeper should call
     * performUpkeep or not.
     * @return performData bytes that the keeper should call performUpkeep with, if
     * upkeep is needed. If you would like to encode data to decode later, try
     * `abi.encode`.
     */
    function checkLog(
        Log calldata log,
        bytes memory checkData
    ) external returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @notice method that is actually executed by the keepers, via the registry.
     * The data returned by the checkUpkeep simulation will be passed into
     * this method to actually be executed.
     * @dev The input to this method should not be trusted, and the caller of the
     * method should not even be restricted to any single registry. Anyone should
     * be able call it, and the input should be validated, there is no guarantee
     * that the data passed in is the performData returned from checkUpkeep. This
     * could happen due to malicious keepers, racing keepers, or simply a state
     * change while the performUpkeep transaction is waiting for confirmation.
     * Always validate the data passed in.
     * @param performData is the data which was passed back from the checkData
     * simulation. If it is encoded, it can easily be decoded into other types by
     * calling `abi.decode`. This data should not be trusted, and should be
     * validated against the contract's current state.
     */
    function performUpkeep(bytes calldata performData) external;
}

// File @chainlink/contracts/src/v0.8/automation/interfaces/[email protected]

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;

interface StreamsLookupCompatibleInterface {
    error StreamsLookup(
        string feedParamKey,
        string[] feeds,
        string timeParamKey,
        uint256 time,
        bytes extraData
    );

    /**
     * @notice any contract which wants to utilize StreamsLookup feature needs to
     * implement this interface as well as the automation compatible interface.
     * @param values an array of bytes returned from data streams endpoint.
     * @param extraData context data from streams lookup process.
     * @return upkeepNeeded boolean to indicate whether the keeper should call performUpkeep or not.
     * @return performData bytes that the keeper should call performUpkeep with, if
     * upkeep is needed. If you would like to encode data to decode later, try `abi.encode`.
     */
    function checkCallback(
        bytes[] memory values,
        bytes memory extraData
    ) external view returns (bool upkeepNeeded, bytes memory performData);
}

// File @uniswap/v2-core/contracts/interfaces/[email protected]

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);
}

// File contracts/LowLatencyConsumer.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.16;

contract LowLatencyConsumer is
    ILogAutomation,
    StreamsLookupCompatibleInterface
{
    // ================================================================
    // |                        CONSTANTS                             |
    // ================================================================

    string public constant STRING_DATASTREAMS_FEEDLABEL = "feedIDs";
    string public constant STRING_DATASTREAMS_QUERYLABEL = "timestamp";
    uint24 public constant FEE = 3000;

    // ================================================================
    // |                            STATE                             |
    // ================================================================

    string[] public s_feedsHex;

    // ================================================================
    // |                         IMMUTABLES                           |
    // ================================================================

    address immutable i_usdc;
    address immutable i_linkToken;
    IERC20 immutable i_weth;
    ISwapRouter immutable i_router;
    IVerifier immutable i_verifier;

    // ================================================================
    // |                         STRUCTS                              |
    // ================================================================

    struct Report {
        bytes32 feedId;
        uint32 lowerTimestamp;
        uint32 observationsTimestamp;
        uint192 nativeFee;
        uint192 linkFee;
        uint64 upperTimestamp;
        int192 benchmark;
    }

    struct Quote {
        address quoteAddress;
    }

    // ================================================================
    // |                          Events                              |
    // ================================================================

    event ShouldTrade(address indexed msgSender, uint256 indexed amount);
    event SuccessfulTrade(uint256 tokensAmount);

    constructor(
        address usdc,
        address weth,
        address router,
        address verifier,
        address linkToken,
        string[] memory feedsHex
    ) {
        i_usdc = usdc;
        i_weth = IERC20(weth);
        i_router = ISwapRouter(router);
        i_verifier = IVerifier(verifier);
        i_linkToken = linkToken;
        s_feedsHex = feedsHex;
    }

    // ================================================================
    // |                        EXTERNAL                              |
    // ================================================================

    function checkLog(
        Log calldata log,
        bytes memory
    ) external view returns (bool, bytes memory) {
        revert StreamsLookup(
            STRING_DATASTREAMS_FEEDLABEL,
            s_feedsHex,
            STRING_DATASTREAMS_QUERYLABEL,
            log.timestamp,
            log.data
        );
    }

    function trade(uint256 amount) external {
        emit ShouldTrade(msg.sender, amount);
    }

    function performUpkeep(bytes calldata performData) external {
        /*
        (bytes[] memory signedReports, bytes memory extraData) = abi.decode(
            performData,
            (bytes[], bytes)
        );

        (address recipient, uint256 wethIn) = abi.decode(
            extraData,
            (address, uint256)
        );
        bytes memory report = signedReports[0];
        bytes memory bundledReport = _bundleReport(report);
        Report memory unverifiedReport = _getReportData(bundledReport);

        uint192 usdcOut = uint192(unverifiedReport.benchmark) / 10 ** 6;

        i_weth.transferFrom(recipient, address(this), wethIn);
        i_weth.approve(address(i_router), wethIn);

        uint256 successfullyTradedTokens = swapEthForUSDC(
            wethIn,
            usdcOut,
            recipient
        );
        emit SuccessfulTrade(successfullyTradedTokens);
        */
    }

    function swapEthForUSDC(
        uint256 wethIn,
        uint256 usdcOut,
        address recipient
    ) private returns (uint256) {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams(
                address(i_weth),
                i_usdc,
                FEE,
                recipient,
                wethIn,
                usdcOut,
                0
            );
        return i_router.exactInputSingle(params);
    }

    function checkCallback(
        bytes[] memory values,
        bytes memory extraData
    ) external pure returns (bool upkeepNeeded, bytes memory performData) {
        return (true, abi.encode(values, extraData));
    }

    // ================================================================
    // |                         PRIVATE                              |
    // ================================================================

    function _bundleReport(
        bytes memory report
    ) private view returns (bytes memory) {
        Quote memory quote;
        quote.quoteAddress = i_linkToken;
        (
            bytes32[3] memory reportContext,
            bytes memory reportData,
            bytes32[] memory rs,
            bytes32[] memory ss,
            bytes32 raw
        ) = abi.decode(
                report,
                (bytes32[3], bytes, bytes32[], bytes32[], bytes32)
            );
        bytes memory bundledReport = abi.encode(
            reportContext,
            reportData,
            rs,
            ss,
            raw,
            abi.encode(quote)
        );
        return bundledReport;
    }

    function _getReportData(
        bytes memory signedReport
    ) internal pure returns (Report memory) {
        (, bytes memory reportData, , , ) = abi.decode(
            signedReport,
            (bytes32[3], bytes, bytes32[], bytes32[], bytes32)
        );

        Report memory report = abi.decode(reportData, (Report));
        return report;
    }

    function bytesToAddress(
        bytes memory bys
    ) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}

// File contracts/mocks/KeeperRegistryMock.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperRegistryMock {
    enum Trigger {
        CONDITION,
        LOG
    }

    bytes4 internal constant CHECK_SELECTOR =
        AutomationCompatibleInterface.checkUpkeep.selector;
    bytes4 internal constant PERFORM_SELECTOR =
        AutomationCompatibleInterface.performUpkeep.selector;

    bytes4 internal constant CHECK_LOG_SELECTOR =
        ILogAutomation.checkLog.selector;

    function performUpkeep(address upkeep) public {
        AutomationCompatibleInterface(upkeep).performUpkeep(
            hex"000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000003400000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000002a000063ed9f4aa3c0bd13c602966f7d257a1bf50e4605eac15a26cb48684fc187f00000000000000000000000000000000000000000000000000000000007a3a05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000001e00000000000000000000000000000000000000000000000000000000000000240010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e000023496426b520583ae20a66d80484e0fc18544866a5b0bfee15ec77196327400000000000000000000000000000000000000000000000000000000651a698e00000000000000000000000000000000000000000000000000000000651a698e000000000000000000000000000000000000000000000000000034c1fe677ba0000000000000000000000000000000000000000000000000002c1e3a58b0e0c800000000000000000000000000000000000000000000000000000000651bbb0e000000000000000000000000000000000000000000000000000000282347e0c80000000000000000000000000000000000000000000000000000000000000002ee64397c7172805eb1b67b72ac0effe27b56bc80cd370d7e54b7ff1680c956a658830520b2a40fbcba4c52ddbb9131e9fe0bd0fd0a22eed4587cd21b812e5964000000000000000000000000000000000000000000000000000000000000000218607cc02b234bff0c1737d5cdf06f9e17cead2bdbc3d3870c4968ba02e38a1b4874dd8cda0932f48bc00f05f2fd5c0ee373474d1154f9b5e1ed2274fd4162090000000000000000000000000000000000000000000000000000000000000014f39fd6e51aad88f6f4ce6ab8827279cfffb92266000000000000000000000000"
        );
    }
}