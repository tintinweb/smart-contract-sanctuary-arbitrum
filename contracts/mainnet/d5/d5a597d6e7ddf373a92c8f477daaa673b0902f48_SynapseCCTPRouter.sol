// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ISynapseCCTP} from "./interfaces/ISynapseCCTP.sol";
import {ISynapseCCTPFees} from "./interfaces/ISynapseCCTPFees.sol";
import {BridgeToken, DestRequest, SwapQuery, ISynapseCCTPRouter} from "./interfaces/ISynapseCCTPRouter.sol";
import {ITokenMinter} from "./interfaces/ITokenMinter.sol";
import {UnknownRequestAction} from "./libs/RouterErrors.sol";
import {RequestLib} from "./libs/Request.sol";
import {MsgValueIncorrect, DefaultRouter} from "../router/DefaultRouter.sol";

import {IDefaultPool} from "../router/interfaces/IDefaultPool.sol";
import {Action, DefaultParams} from "../router/libs/Structs.sol";

import {SafeERC20, IERC20} from "@openzeppelin/contracts-4.5.0/token/ERC20/utils/SafeERC20.sol";
import {Pausable} from "@openzeppelin/contracts-4.5.0/security/Pausable.sol";

contract SynapseCCTPRouter is DefaultRouter, ISynapseCCTPRouter {
    using SafeERC20 for IERC20;

    address public immutable synapseCCTP;

    constructor(address _synapseCCTP) {
        synapseCCTP = _synapseCCTP;
    }

    // ════════════════════════════════════════════ BRIDGE INTERACTIONS ════════════════════════════════════════════════

    /// @inheritdoc ISynapseCCTPRouter
    function bridge(
        address recipient,
        uint256 chainId,
        address token,
        uint256 amount,
        SwapQuery memory originQuery,
        SwapQuery memory destQuery
    ) external payable {
        if (originQuery.hasAdapter()) {
            // Perform a swap using the swap adapter, set this contract as recipient
            (token, amount) = _doSwap(address(this), token, amount, originQuery);
        } else {
            // If no swap is required, msg.value must be left as zero
            if (msg.value != 0) revert MsgValueIncorrect();
            // Pull the token from the user to this contract
            amount = _pullToken(address(this), token, amount);
        }
        // Either way, this contract has `amount` worth of `token`
        (uint32 requestVersion, bytes memory swapParams) = _deriveCCTPSwapParams(destQuery);
        // Approve SynapseCCTP to spend the token
        _approveToken(token, synapseCCTP, amount);
        ISynapseCCTP(synapseCCTP).sendCircleToken({
            recipient: recipient,
            chainId: chainId,
            burnToken: token,
            amount: amount,
            requestVersion: requestVersion,
            swapParams: swapParams
        });
    }

    // ═══════════════════════════════════════════════════ VIEWS ═══════════════════════════════════════════════════════

    /// @inheritdoc ISynapseCCTPRouter
    function calculateFeeAmount(
        address token,
        uint256 amount,
        bool isSwap
    ) external view returns (uint256 fee) {
        return ISynapseCCTPFees(synapseCCTP).calculateFeeAmount(token, amount, isSwap);
    }

    /// @inheritdoc ISynapseCCTPRouter
    function feeStructures(address token)
        external
        view
        returns (
            uint40 relayerFee,
            uint72 minBaseFee,
            uint72 minSwapFee,
            uint72 maxFee
        )
    {
        return ISynapseCCTPFees(synapseCCTP).feeStructures(token);
    }

    /// @inheritdoc ISynapseCCTPRouter
    function getConnectedBridgeTokens(address tokenOut) external view returns (BridgeToken[] memory tokens) {
        BridgeToken[] memory cctpTokens = ISynapseCCTPFees(synapseCCTP).getBridgeTokens();
        uint256 length = cctpTokens.length;
        bool[] memory isConnected = new bool[](length);
        uint256 count = 0;
        for (uint256 i = 0; i < length; ++i) {
            address circleToken = cctpTokens[i].token;
            if (circleToken == tokenOut || _isConnected(circleToken, tokenOut)) {
                isConnected[i] = true;
                ++count;
            }
        }
        // Populate the returned array with connected tokens
        tokens = new BridgeToken[](count);
        // This will track the index of the next element to be inserted in the returned array
        count = 0;
        for (uint256 i = 0; i < length; ++i) {
            if (isConnected[i]) {
                tokens[count++] = cctpTokens[i];
            }
        }
    }

    /// @inheritdoc ISynapseCCTPRouter
    function getOriginAmountOut(
        address tokenIn,
        string[] memory tokenSymbols,
        uint256 amountIn
    ) external view returns (SwapQuery[] memory originQueries) {
        uint256 length = tokenSymbols.length;
        originQueries = new SwapQuery[](length);
        address tokenMinter = ISynapseCCTP(synapseCCTP).tokenMessenger().localMinter();
        // Check if it is possible to send Circle tokens (it is always possible to receive them though).
        bool isPaused = Pausable(synapseCCTP).paused();
        for (uint256 i = 0; i < length; ++i) {
            address circleToken = ISynapseCCTPFees(synapseCCTP).symbolToToken(tokenSymbols[i]);
            address pool = ISynapseCCTP(synapseCCTP).circleTokenPool(circleToken);
            // Get the quote for tokenIn -> circleToken swap
            // Note: this only populates `tokenOut`, `minAmountOut` and `rawParams` fields.
            originQueries[i] = _getAmountOut(pool, tokenIn, circleToken, amountIn);
            // Check if the amount out is higher than the burn limit
            uint256 burnLimit = ITokenMinter(tokenMinter).burnLimitsPerMessage(circleToken);
            if (originQueries[i].minAmountOut > burnLimit || isPaused) {
                // Nullify the query, leaving tokenOut intact (this allows SDK to get the bridge token address)
                originQueries[i].minAmountOut = 0;
                originQueries[i].rawParams = "";
            } else {
                // Fill the remaining fields, use this contract as "Router Adapter"
                originQueries[i].fillAdapterAndDeadline({routerAdapter: address(this)});
            }
        }
    }

    /// @inheritdoc ISynapseCCTPRouter
    function getDestinationAmountOut(DestRequest[] memory requests, address tokenOut)
        external
        view
        returns (SwapQuery[] memory destQueries)
    {
        uint256 length = requests.length;
        destQueries = new SwapQuery[](length);
        for (uint256 i = 0; i < length; ++i) {
            address circleToken = ISynapseCCTPFees(synapseCCTP).symbolToToken(requests[i].symbol);
            address pool = ISynapseCCTP(synapseCCTP).circleTokenPool(circleToken);
            // Calculate the relayer fee amount
            uint256 amountIn = requests[i].amountIn;
            uint256 feeAmount = ISynapseCCTPFees(synapseCCTP).calculateFeeAmount({
                token: circleToken,
                amount: amountIn,
                isSwap: circleToken != tokenOut
            });
            // Only populate the query if the amountIn is higher than the feeAmount
            if (amountIn > feeAmount) {
                // Get the quote for circleToken -> tokenOut swap after the fee is applied
                // Note: this only populates `tokenOut`, `minAmountOut` and `rawParams` fields.
                destQueries[i] = _getAmountOut(pool, circleToken, tokenOut, amountIn - feeAmount);
                // Fill the remaining fields, use this contract as "Router Adapter"
                destQueries[i].fillAdapterAndDeadline({routerAdapter: address(this)});
            } else {
                // Fill only tokenOut otherwise
                destQueries[i].tokenOut = tokenOut;
            }
        }
    }

    // ══════════════════════════════════════════════ INTERNAL LOGIC ═══════════════════════════════════════════════════

    /// @dev Approves the token to be spent by the given spender indefinitely by giving infinite allowance.
    /// Doesn't modify the allowance if it's already enough for the given amount.
    function _approveToken(
        address token,
        address spender,
        uint256 amount
    ) internal {
        uint256 allowance = IERC20(token).allowance(address(this), spender);
        if (allowance < amount) {
            // Reset allowance to 0 before setting it to the new value.
            if (allowance != 0) IERC20(token).safeApprove(spender, 0);
            IERC20(token).safeApprove(spender, type(uint256).max);
        }
    }

    // ══════════════════════════════════════════════ INTERNAL VIEWS ═══════════════════════════════════════════════════

    /// @dev Finds the quote for tokenIn -> tokenOut swap using a given pool.
    /// Note: only populates `tokenOut`, `minAmountOut` and `rawParams` fields.
    function _getAmountOut(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal view returns (SwapQuery memory query) {
        query.tokenOut = tokenOut;
        if (tokenIn == tokenOut) {
            query.minAmountOut = amountIn;
            // query.rawParams is "", indicating that no further action is required
            return query;
        }
        if (pool == address(0)) {
            // query.minAmountOut is 0, indicating that no quote was found
            // query.rawParams is "", indicating that no further action is required
            return query;
        }
        address[] memory poolTokens = _getPoolTokens(pool);
        uint256 numTokens = poolTokens.length;
        // Iterate over all valid (tokenIndexFrom, tokenIndexTo) combinations for tokenIn -> tokenOut swap
        for (uint8 tokenIndexFrom = 0; tokenIndexFrom < numTokens; ++tokenIndexFrom) {
            // We are only interested in the tokenFrom == tokenIn case
            if (poolTokens[tokenIndexFrom] != tokenIn) continue;
            for (uint8 tokenIndexTo = 0; tokenIndexTo < numTokens; ++tokenIndexTo) {
                // We are only interested in the tokenTo == tokenOut case
                if (poolTokens[tokenIndexTo] != tokenOut) continue;
                uint256 amountOut = _getPoolSwapQuote(pool, tokenIndexFrom, tokenIndexTo, amountIn);
                // Update the query if the new quote is better than the previous one
                if (amountOut > query.minAmountOut) {
                    query.minAmountOut = amountOut;
                    query.rawParams = abi.encode(DefaultParams(Action.Swap, pool, tokenIndexFrom, tokenIndexTo));
                }
            }
        }
    }

    /// @dev Checks if a token is connected to a Circle token: whether the token is in the whitelisted liquidity pool
    /// for the Circle token.
    function _isConnected(address circleToken, address token) internal view returns (bool) {
        // Get the whitelisted liquidity pool for the  Circle token
        address pool = ISynapseCCTP(synapseCCTP).circleTokenPool(circleToken);
        if (pool == address(0)) return false;
        // Iterate over pool tokens to check if the token is in the pool (meaning it is connected to the Circle token)
        for (uint8 index = 0; ; ++index) {
            try IDefaultPool(pool).getToken(index) returns (address poolToken) {
                if (poolToken == token) return true;
            } catch {
                // End of pool reached
                break;
            }
        }
        return false;
    }

    /// @dev Derives the `swapParams` for following interaction with SynapseCCTP contract.
    function _deriveCCTPSwapParams(SwapQuery memory destQuery)
        internal
        pure
        returns (uint32 requestVersion, bytes memory swapParams)
    {
        // Check if any action was specified in `destQuery`
        if (destQuery.routerAdapter == address(0)) {
            // No action was specified, so no swap is required
            return (RequestLib.REQUEST_BASE, "");
        }
        DefaultParams memory params = abi.decode(destQuery.rawParams, (DefaultParams));
        // Check if the action is a swap
        if (params.action != Action.Swap) {
            // Actions other than swap are not supported for Circle tokens on the destination chain
            revert UnknownRequestAction();
        }
        requestVersion = RequestLib.REQUEST_SWAP;
        swapParams = RequestLib.formatSwapParams({
            tokenIndexFrom: params.tokenIndexFrom,
            tokenIndexTo: params.tokenIndexTo,
            deadline: destQuery.deadline,
            minAmountOut: destQuery.minAmountOut
        });
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ITokenMessenger} from "./ITokenMessenger.sol";
import {ISynapseCCTPFees} from "./ISynapseCCTPFees.sol";

interface ISynapseCCTP is ISynapseCCTPFees {
    /// @notice Send a Circle token supported by CCTP to a given chain
    /// with the request for the action to take on the destination chain.
    /// @dev The request is a bytes array containing information about the end recipient of the tokens,
    /// as well as an optional swap action to take on the destination chain.
    /// `chainId` refers to value from EIP-155 (block.chainid).
    /// @param recipient            Recipient of the tokens on destination chain
    /// @param chainId              Chain ID of the destination chain
    /// @param burnToken            Address of Circle token to burn
    /// @param amount               Amount of tokens to burn
    /// @param requestVersion       Version of the request format
    /// @param swapParams           Swap parameters for the action to take on the destination chain (could be empty)
    function sendCircleToken(
        address recipient,
        uint256 chainId,
        address burnToken,
        uint256 amount,
        uint32 requestVersion,
        bytes memory swapParams
    ) external;

    /// @notice Receive  Circle token supported by CCTP with the request for the action to take.
    /// @dev The request is a bytes array containing information about the end recipient of the tokens,
    /// as well as an optional swap action to take on this chain.
    /// @dev The relayers need to use SynapseCCTP.chainGasAmount() as `msg.value` when calling this function,
    /// or the call will revert.
    /// @param message              Message raw bytes emitted by CCTP MessageTransmitter on origin chain
    /// @param signature            Circle's attestation for the message obtained from Circle's API
    /// @param requestVersion       Version of the request format
    /// @param formattedRequest     Formatted request for the action to take on this chain
    function receiveCircleToken(
        bytes calldata message,
        bytes calldata signature,
        uint32 requestVersion,
        bytes memory formattedRequest
    ) external payable;

    // ═══════════════════════════════════════════════════ VIEWS ═══════════════════════════════════════════════════════

    /// @notice Returns the whitelisted liquidity pool for a given Circle token.
    /// @dev Returns address(0) if the token bridge+swap is not supported.
    function circleTokenPool(address token) external view returns (address pool);

    /// @notice Returns the address of Circle's TokenMessenger contract used for bridging Circle tokens.
    function tokenMessenger() external view returns (ITokenMessenger);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BridgeToken} from "../../router/libs/Structs.sol";

interface ISynapseCCTPFees {
    /// @notice Calculates the fee amount for bridging a token to this chain using CCTP.
    /// @dev Will not check if fee exceeds the token amount. Will return 0 if the token is not supported.
    /// @param token        Address of the Circle token
    /// @param amount       Amount of the Circle tokens to be bridged to this chain
    /// @param isSwap       Whether the request is a swap request
    /// @return fee         Fee amount
    function calculateFeeAmount(
        address token,
        uint256 amount,
        bool isSwap
    ) external view returns (uint256 fee);

    /// @notice Gets the fee structure for bridging a token to this chain.
    /// @dev Will return 0 for all fields if the token is not supported.
    /// @param token        Address of the Circle token
    /// @return relayerFee  Fee % for bridging a token to this chain, multiplied by `FEE_DENOMINATOR`
    /// @return minBaseFee  Minimum fee for bridging a token to this chain using a base request
    /// @return minSwapFee  Minimum fee for bridging a token to this chain using a swap request
    /// @return maxFee      Maximum fee for bridging a token to this chain
    function feeStructures(address token)
        external
        view
        returns (
            uint40 relayerFee,
            uint72 minBaseFee,
            uint72 minSwapFee,
            uint72 maxFee
        );

    /// @notice Returns the list of all supported bridge tokens and their symbols.
    function getBridgeTokens() external view returns (BridgeToken[] memory bridgeTokens);

    /// @notice Returns the address of the CCTP token for a given symbol.
    /// @dev Will return address(0) if the token is not supported.
    function symbolToToken(string memory symbol) external view returns (address token);

    /// @notice Returns the symbol of a given CCTP token.
    /// @dev Will return empty string if the token is not supported.
    function tokenToSymbol(address token) external view returns (string memory symbol);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BridgeToken, DestRequest, SwapQuery} from "../../router/libs/Structs.sol";

interface ISynapseCCTPRouter {
    /// @notice Initiate a bridge transaction with an optional swap on both origin and destination chains.
    /// @dev Note that method is payable.
    /// If token is ETH_ADDRESS, this method should be invoked with `msg.value = amountIn`.
    /// If token is ERC20, the tokens will be pulled from msg.sender (use `msg.value = 0`).
    /// Make sure to approve this contract for spending `token` beforehand.
    /// originQuery.tokenOut should never be ETH_ADDRESS, bridge only works with ERC20 tokens.
    ///
    /// `originQuery` is supposed to be fetched using Router.getOriginAmountOut().
    /// Alternatively one could use an external adapter for more complex swaps on the origin chain.
    ///
    /// `destQuery` is supposed to be fetched using Router.getDestinationAmountOut().
    /// Complex swaps on destination chain are not supported for the time being.
    /// @param recipient    Address to receive tokens on destination chain
    /// @param chainId      Destination chain id
    /// @param token        Initial token for the bridge transaction to be pulled from the user
    /// @param amount       Amount of the initial tokens for the bridge transaction
    /// @param originQuery  Origin swap query. Empty struct indicates no swap is required
    /// @param destQuery    Destination swap query. Empty struct indicates no swap is required
    function bridge(
        address recipient,
        uint256 chainId,
        address token,
        uint256 amount,
        SwapQuery memory originQuery,
        SwapQuery memory destQuery
    ) external payable;

    // ═══════════════════════════════════════════════════ VIEWS ═══════════════════════════════════════════════════════

    /// @notice Calculates the fee amount for bridging a token to this chain using CCTP.
    /// @dev Will not check if fee exceeds the token amount. Will return 0 if the token is not supported.
    /// @param token        Address of the Circle token
    /// @param amount       Amount of the Circle tokens to be bridged to this chain
    /// @param isSwap       Whether the request is a swap request
    /// @return fee         Fee amount
    function calculateFeeAmount(
        address token,
        uint256 amount,
        bool isSwap
    ) external view returns (uint256 fee);

    /// @notice Gets the fee structure for bridging a token to this chain.
    /// @dev Will return 0 for all fields if the token is not supported.
    /// @param token        Address of the Circle token
    /// @return relayerFee  Fee % for bridging a token to this chain, multiplied by `FEE_DENOMINATOR`
    /// @return minBaseFee  Minimum fee for bridging a token to this chain using a base request
    /// @return minSwapFee  Minimum fee for bridging a token to this chain using a swap request
    /// @return maxFee      Maximum fee for bridging a token to this chain
    function feeStructures(address token)
        external
        view
        returns (
            uint40 relayerFee,
            uint72 minBaseFee,
            uint72 minSwapFee,
            uint72 maxFee
        );

    /// @notice Gets the list of all bridge tokens (and their symbols), such that destination swap
    /// from a bridge token to `tokenOut` is possible.
    /// @param tokenOut  Token address to swap to on destination chain
    /// @return tokens   List of structs with following information:
    ///                  - symbol: unique token ID consistent among all chains
    ///                  - token: bridge token address
    function getConnectedBridgeTokens(address tokenOut) external view returns (BridgeToken[] memory tokens);

    /// @notice Finds the best path between `tokenIn` and every supported bridge token from the given list,
    /// treating the swap as "origin swap", without putting any restrictions on the swap.
    /// @dev Will NOT revert if any of the tokens are not supported, instead will return an empty query for that symbol.
    /// Check (query.minAmountOut != 0): this is true only if the swap is possible and bridge token is supported.
    /// The returned queries with minAmountOut != 0 could be used as `originQuery` with SynapseRouter.
    /// Note: it is possible to form a SwapQuery off-chain using alternative SwapAdapter for the origin swap.
    /// @param tokenIn       Initial token that user wants to bridge/swap
    /// @param tokenSymbols  List of symbols representing bridge tokens
    /// @param amountIn      Amount of tokens user wants to bridge/swap
    /// @return originQueries    List of structs that could be used as `originQuery` in SynapseRouter.
    ///                          minAmountOut and deadline fields will need to be adjusted based on the user settings.
    function getOriginAmountOut(
        address tokenIn,
        string[] memory tokenSymbols,
        uint256 amountIn
    ) external view returns (SwapQuery[] memory originQueries);

    /// @notice Finds the best path between every supported bridge token from the given list and `tokenOut`,
    /// treating the swap as "destination swap", limiting possible actions to those available for every bridge token.
    /// @dev Will NOT revert if any of the tokens are not supported, instead will return an empty query for that symbol.
    /// Note: it is NOT possible to form a SwapQuery off-chain using alternative SwapAdapter for the destination swap.
    /// For the time being, only swaps through the Synapse-supported pools are available on destination chain.
    /// @param requests  List of structs with following information:
    ///                  - symbol: unique token ID consistent among all chains
    ///                  - amountIn: amount of bridge token to start with, before the bridge fee is applied
    /// @param tokenOut  Token user wants to receive on destination chain
    /// @return destQueries  List of structs that could be used as `destQuery` in SynapseRouter.
    ///                      minAmountOut and deadline fields will need to be adjusted based on the user settings.
    function getDestinationAmountOut(DestRequest[] memory requests, address tokenOut)
        external
        view
        returns (SwapQuery[] memory destQueries);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITokenMinter {
    /**
     * @notice Mints `amount` of local tokens corresponding to the
     * given (`sourceDomain`, `burnToken`) pair, to `to` address.
     * @dev reverts if the (`sourceDomain`, `burnToken`) pair does not
     * map to a nonzero local token address. This mapping can be queried using
     * getLocalToken().
     * @param sourceDomain Source domain where `burnToken` was burned.
     * @param burnToken Burned token address as bytes32.
     * @param to Address to receive minted tokens, corresponding to `burnToken`,
     * on this domain.
     * @param amount Amount of tokens to mint. Must be less than or equal
     * to the minterAllowance of this TokenMinter for given `_mintToken`.
     * @return mintToken token minted.
     */
    function mint(
        uint32 sourceDomain,
        bytes32 burnToken,
        address to,
        uint256 amount
    ) external returns (address mintToken);

    /**
     * @notice Burn tokens owned by this ITokenMinter.
     * @param burnToken burnable token.
     * @param amount amount of tokens to burn. Must be less than or equal to this ITokenMinter's
     * account balance of the given `_burnToken`.
     */
    function burn(address burnToken, uint256 amount) external;

    /**
     * @notice Get the local token associated with the given remote domain and token.
     * @param remoteDomain Remote domain
     * @param remoteToken Remote token
     * @return local token address
     */
    function getLocalToken(uint32 remoteDomain, bytes32 remoteToken) external view returns (address);

    // local token (address) => maximum burn amounts per message
    function burnLimitsPerMessage(address token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

error UnknownRequestAction();

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IncorrectRequestLength, UnknownRequestVersion} from "./Errors.sol";

/// # Base Request layout
///
/// | Field           | Type    | Description                                    |
/// | --------------- | ------- | ---------------------------------------------- |
/// | originDomain    | uint32  | Domain of the origin chain used by Circle CCTP |
/// | nonce           | uint64  | Nonce of the CCTP message on origin chain      |
/// | originBurnToken | address | Circle token that was burned on origin chain   |
/// | amount          | uint256 | Amount of tokens burned on origin chain        |
/// | recipient       | address | Recipient of the tokens on destination chain   |
///
/// # Swap Params layout
///
/// | Field          | Type    | Description                                                   |
/// | -------------- | ------- | ------------------------------------------------------------- |
/// | tokenIndexFrom | uint8   | Index of the minted Circle token in the pool                  |
/// | tokenIndexTo   | uint8   | Index of the final token in the pool                          |
/// | deadline       | uint256 | Latest timestamp to execute the swap                          |
/// | minAmountOut   | uint256 | Minimum amount of tokens to receive from the swap             |
library RequestLib {
    uint32 internal constant REQUEST_BASE = 0;
    uint32 internal constant REQUEST_SWAP = 1;

    /// @notice Length of the encoded base request.
    uint256 internal constant REQUEST_BASE_LENGTH = 5 * 32;
    /// @notice Length of the encoded swap parameters.
    uint256 internal constant SWAP_PARAMS_LENGTH = 4 * 32;
    /// @notice Length of the encoded swap request.
    /// Need 2 extra words for each `bytes` field to store its offset in the full payload, and length.
    uint256 internal constant REQUEST_SWAP_LENGTH = 4 * 32 + REQUEST_BASE_LENGTH + SWAP_PARAMS_LENGTH;

    // ════════════════════════════════════════════════ FORMATTING ═════════════════════════════════════════════════════

    /// @notice Formats the base request into a bytes array.
    /// @param originDomain         Domain of the origin chain
    /// @param nonce                Nonce of the CCTP message on origin chain
    /// @param originBurnToken      Circle token that was burned on origin chain
    /// @param amount               Amount of tokens burned on origin chain
    /// @param recipient            Recipient of the tokens on destination chain
    /// @return formattedRequest    Properly formatted base request
    function formatBaseRequest(
        uint32 originDomain,
        uint64 nonce,
        address originBurnToken,
        uint256 amount,
        address recipient
    ) internal pure returns (bytes memory formattedRequest) {
        return abi.encode(originDomain, nonce, originBurnToken, amount, recipient);
    }

    /// @notice Formats the swap parameters part of the swap request into a bytes array.
    /// @param tokenIndexFrom       Index of the minted Circle token in the pool
    /// @param tokenIndexTo         Index of the final token in the pool
    /// @param deadline             Latest timestamp to execute the swap
    /// @param minAmountOut         Minimum amount of tokens to receive from the swap
    /// @return formattedSwapParams Properly formatted swap parameters
    function formatSwapParams(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 deadline,
        uint256 minAmountOut
    ) internal pure returns (bytes memory formattedSwapParams) {
        return abi.encode(tokenIndexFrom, tokenIndexTo, deadline, minAmountOut);
    }

    /// @notice Formats the request into a bytes array.
    /// @dev Will revert if the either of these is true:
    /// - Request version is unknown.
    /// - Base request is not properly formatted.
    /// - Swap parameters are specified for a base request.
    /// - Swap parameters are not properly formatted.
    /// @param requestVersion       Version of the request format
    /// @param baseRequest          Formatted base request
    /// @param swapParams           Formatted swap parameters
    /// @return formattedRequest    Properly formatted request
    function formatRequest(
        uint32 requestVersion,
        bytes memory baseRequest,
        bytes memory swapParams
    ) internal pure returns (bytes memory formattedRequest) {
        if (baseRequest.length != REQUEST_BASE_LENGTH) revert IncorrectRequestLength();
        if (requestVersion == REQUEST_BASE) {
            if (swapParams.length != 0) revert IncorrectRequestLength();
            // swapParams is empty, so we can just return the base request
            return baseRequest;
        } else if (requestVersion == REQUEST_SWAP) {
            if (swapParams.length != SWAP_PARAMS_LENGTH) revert IncorrectRequestLength();
            // Encode both the base request and the swap parameters
            return abi.encode(baseRequest, swapParams);
        } else {
            revert UnknownRequestVersion();
        }
    }

    // ═════════════════════════════════════════════════ DECODING ══════════════════════════════════════════════════════

    /// @notice Decodes the base request from a bytes array.
    /// @dev Will revert if the request is not properly formatted.
    /// @param baseRequest          Formatted base request
    /// @return originDomain        Domain of the origin chain
    /// @return nonce               Nonce of the CCTP message on origin domain
    /// @return originBurnToken     Circle token that was burned on origin domain
    /// @return amount              Amount of tokens to burn
    /// @return recipient           Recipient of the tokens on destination domain
    function decodeBaseRequest(bytes memory baseRequest)
        internal
        pure
        returns (
            uint32 originDomain,
            uint64 nonce,
            address originBurnToken,
            uint256 amount,
            address recipient
        )
    {
        if (baseRequest.length != REQUEST_BASE_LENGTH) revert IncorrectRequestLength();
        return abi.decode(baseRequest, (uint32, uint64, address, uint256, address));
    }

    /// @notice Decodes the swap parameters from a bytes array.
    /// @dev Will revert if the swap parameters are not properly formatted.
    /// @param swapParams           Formatted swap parameters
    /// @return tokenIndexFrom      Index of the minted Circle token in the pool
    /// @return tokenIndexTo        Index of the final token in the pool
    /// @return deadline            Latest timestamp to execute the swap
    /// @return minAmountOut        Minimum amount of tokens to receive from the swap
    function decodeSwapParams(bytes memory swapParams)
        internal
        pure
        returns (
            uint8 tokenIndexFrom,
            uint8 tokenIndexTo,
            uint256 deadline,
            uint256 minAmountOut
        )
    {
        if (swapParams.length != SWAP_PARAMS_LENGTH) revert IncorrectRequestLength();
        return abi.decode(swapParams, (uint8, uint8, uint256, uint256));
    }

    /// @notice Decodes the versioned request from a bytes array.
    /// @dev Will revert if the either of these is true:
    /// - Request version is unknown.
    /// - Request is not properly formatted.
    /// @param requestVersion       Version of the request format
    /// @param formattedRequest     Formatted request
    /// @return baseRequest         Formatted base request
    /// @return swapParams          Formatted swap parameters
    function decodeRequest(uint32 requestVersion, bytes memory formattedRequest)
        internal
        pure
        returns (bytes memory baseRequest, bytes memory swapParams)
    {
        if (requestVersion == REQUEST_BASE) {
            if (formattedRequest.length != REQUEST_BASE_LENGTH) revert IncorrectRequestLength();
            return (formattedRequest, "");
        } else if (requestVersion == REQUEST_SWAP) {
            if (formattedRequest.length != REQUEST_SWAP_LENGTH) revert IncorrectRequestLength();
            return abi.decode(formattedRequest, (bytes, bytes));
        } else {
            revert UnknownRequestVersion();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {DefaultAdapter} from "./adapters/DefaultAdapter.sol";
import {IRouterAdapter} from "./interfaces/IRouterAdapter.sol";
import {DeadlineExceeded, InsufficientOutputAmount, MsgValueIncorrect, TokenNotETH} from "./libs/Errors.sol";
import {Action, DefaultParams, SwapQuery} from "./libs/Structs.sol";
import {UniversalTokenLib} from "./libs/UniversalToken.sol";

import {SafeERC20, IERC20} from "@openzeppelin/contracts-4.5.0/token/ERC20/utils/SafeERC20.sol";

/// @title DefaultRouter
/// @notice Base contract for all Synapse Routers, that is able to natively work with Default Pools
/// due to the fact that it inherits from DefaultAdapter.
abstract contract DefaultRouter is DefaultAdapter {
    using SafeERC20 for IERC20;
    using UniversalTokenLib for address;

    /// @dev Performs a "swap from tokenIn" following instructions from `query`.
    /// `query` will include the router adapter to use, and the exact type of "tokenIn -> tokenOut swap"
    /// should be encoded in `query.rawParams`.
    function _doSwap(
        address recipient,
        address tokenIn,
        uint256 amountIn,
        SwapQuery memory query
    ) internal returns (address tokenOut, uint256 amountOut) {
        // First, check the deadline for the swap
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp > query.deadline) revert DeadlineExceeded();
        // Pull initial token from the user to specified router adapter
        amountIn = _pullToken(query.routerAdapter, tokenIn, amountIn);
        tokenOut = query.tokenOut;
        address routerAdapter = query.routerAdapter;
        if (routerAdapter == address(this)) {
            // If the router adapter is this contract, we can perform the swap directly and trust the result
            amountOut = _adapterSwap(recipient, tokenIn, amountIn, tokenOut, query.rawParams);
        } else {
            // Otherwise, we need to call the router adapter. Adapters are permissionless, so we verify the result
            // Record tokenOut balance before swap
            amountOut = tokenOut.universalBalanceOf(recipient);
            IRouterAdapter(routerAdapter).adapterSwap{value: msg.value}({
                recipient: recipient,
                tokenIn: tokenIn,
                amountIn: amountIn,
                tokenOut: tokenOut,
                rawParams: query.rawParams
            });
            // Use the difference between the recorded balance and the current balance as the amountOut
            amountOut = tokenOut.universalBalanceOf(recipient) - amountOut;
        }
        // Finally, check that the recipient received at least as much as they wanted
        if (amountOut < query.minAmountOut) revert InsufficientOutputAmount();
    }

    /// @dev Pulls a requested token from the user to the requested recipient.
    /// Or, if msg.value was provided, check that ETH_ADDRESS was used and msg.value is correct.
    function _pullToken(
        address recipient,
        address token,
        uint256 amount
    ) internal returns (uint256 amountPulled) {
        if (msg.value == 0) {
            token.assertIsContract();
            // Record token balance before transfer
            amountPulled = IERC20(token).balanceOf(recipient);
            // Token needs to be pulled only if msg.value is zero
            // This way user can specify WETH as the origin asset
            IERC20(token).safeTransferFrom(msg.sender, recipient, amount);
            // Use the difference between the recorded balance and the current balance as the amountPulled
            amountPulled = IERC20(token).balanceOf(recipient) - amountPulled;
        } else {
            // Otherwise, we need to check that ETH was specified
            if (token != UniversalTokenLib.ETH_ADDRESS) revert TokenNotETH();
            // And that amount matches msg.value
            if (amount != msg.value) revert MsgValueIncorrect();
            // We will forward msg.value in the external call later, if recipient is not this contract
            amountPulled = msg.value;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IDefaultPool {
    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256 amountOut);

    function getToken(uint8 index) external view returns (address token);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13; // "using A for B global" requires 0.8.13 or higher

// ══════════════════════════════════════════ TOKEN AND POOL DESCRIPTION ═══════════════════════════════════════════════

/// @notice Struct representing a bridge token. Used as the return value in view functions.
/// @param symbol   Bridge token symbol: unique token ID consistent among all chains
/// @param token    Bridge token address
struct BridgeToken {
    string symbol;
    address token;
}

/// @notice Struct used by IPoolHandler to represent a token in a pool
/// @param index    Token index in the pool
/// @param token    Token address
struct IndexedToken {
    uint8 index;
    address token;
}

/// @notice Struct representing a token, and the available Actions for performing a swap.
/// @param actionMask   Bitmask representing what actions (see ActionLib) are available for swapping a token
/// @param token        Token address
struct LimitedToken {
    uint256 actionMask;
    address token;
}

/// @notice Struct representing how pool tokens are stored by `SwapQuoter`.
/// @param isWeth   Whether the token represents Wrapped ETH.
/// @param token    Token address.
struct PoolToken {
    bool isWeth;
    address token;
}

/// @notice Struct representing a liquidity pool. Used as the return value in view functions.
/// @param pool         Pool address.
/// @param lpToken      Address of pool's LP token.
/// @param tokens       List of pool's tokens.
struct Pool {
    address pool;
    address lpToken;
    PoolToken[] tokens;
}

// ════════════════════════════════════════════════ ROUTER STRUCTS ═════════════════════════════════════════════════════

/// @notice Struct representing a quote request for swapping a bridge token.
/// Used in destination chain's SynapseRouter, hence the name "Destination Request".
/// @dev tokenOut is passed externally.
/// @param symbol   Bridge token symbol: unique token ID consistent among all chains
/// @param amountIn Amount of bridge token to start with, before the bridge fee is applied
struct DestRequest {
    string symbol;
    uint256 amountIn;
}

/// @notice Struct representing a swap request for SynapseRouter.
/// @dev tokenIn is supplied separately.
/// @param routerAdapter    Contract that will perform the swap for the Router. Address(0) specifies a "no swap" query.
/// @param tokenOut         Token address to swap to.
/// @param minAmountOut     Minimum amount of tokens to receive after the swap, or tx will be reverted.
/// @param deadline         Latest timestamp for when the transaction needs to be executed, or tx will be reverted.
/// @param rawParams        ABI-encoded params for the swap that will be passed to `routerAdapter`.
///                         Should be DefaultParams for swaps via DefaultAdapter.
struct SwapQuery {
    address routerAdapter;
    address tokenOut;
    uint256 minAmountOut;
    uint256 deadline;
    bytes rawParams;
}

using SwapQueryLib for SwapQuery global;

library SwapQueryLib {
    /// @notice Checks whether the router adapter was specified in the query.
    /// Query without a router adapter specifies that no action needs to be taken.
    function hasAdapter(SwapQuery memory query) internal pure returns (bool) {
        return query.routerAdapter != address(0);
    }

    /// @notice Fills `routerAdapter` and `deadline` fields in query, if it specifies one of the supported Actions,
    /// and if a path for this action was found.
    function fillAdapterAndDeadline(SwapQuery memory query, address routerAdapter) internal pure {
        // Fill the fields only if some path was found.
        if (query.minAmountOut == 0) return;
        // Empty params indicates no action needs to be done, thus no adapter is needed.
        query.routerAdapter = query.rawParams.length == 0 ? address(0) : routerAdapter;
        // Set default deadline to infinity. Not using the value of 0,
        // which would lead to every swap to revert by default.
        query.deadline = type(uint256).max;
    }
}

// ════════════════════════════════════════════════ ADAPTER STRUCTS ════════════════════════════════════════════════════

/// @notice Struct representing parameters for swapping via DefaultAdapter.
/// @param action           Action that DefaultAdapter needs to perform.
/// @param pool             Liquidity pool that will be used for Swap/AddLiquidity/RemoveLiquidity actions.
/// @param tokenIndexFrom   Token index to swap from. Used for swap/addLiquidity actions.
/// @param tokenIndexTo     Token index to swap to. Used for swap/removeLiquidity actions.
struct DefaultParams {
    Action action;
    address pool;
    uint8 tokenIndexFrom;
    uint8 tokenIndexTo;
}

/// @notice All possible actions that DefaultAdapter could perform.
enum Action {
    Swap, // swap between two pools tokens
    AddLiquidity, // add liquidity in a form of a single pool token
    RemoveLiquidity, // remove liquidity in a form of a single pool token
    HandleEth // ETH <> WETH interaction
}

using ActionLib for Action global;

/// @notice Library for dealing with bit masks which describe what set of Actions is available.
library ActionLib {
    /// @notice Returns a bitmask with all possible actions set to True.
    function allActions() internal pure returns (uint256 actionMask) {
        actionMask = type(uint256).max;
    }

    /// @notice Returns whether the given action is set to True in the bitmask.
    function isIncluded(Action action, uint256 actionMask) internal pure returns (bool) {
        return actionMask & mask(action) != 0;
    }

    /// @notice Returns a bitmask with only the given action set to True.
    function mask(Action action) internal pure returns (uint256) {
        return 1 << uint256(action);
    }

    /// @notice Returns a bitmask with only two given actions set to True.
    function mask(Action a, Action b) internal pure returns (uint256) {
        return mask(a) | mask(b);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITokenMessenger {
    /**
     * @notice Deposits and burns tokens from sender to be minted on destination domain. The mint
     * on the destination domain must be called by `destinationCaller`.
     * WARNING: if the `destinationCaller` does not represent a valid address as bytes32, then it will not be possible
     * to broadcast the message on the destination domain. This is an advanced feature, and the standard
     * depositForBurn() should be preferred for use cases where a specific destination caller is not required.
     * Emits a `DepositForBurn` event.
     * @dev reverts if:
     * - given destinationCaller is zero address
     * - given burnToken is not supported
     * - given destinationDomain has no TokenMessenger registered
     * - transferFrom() reverts. For example, if sender's burnToken balance or approved allowance
     * to this contract is less than `amount`.
     * - burn() reverts. For example, if `amount` is 0.
     * - MessageTransmitter returns false or reverts.
     * @param amount amount of tokens to burn
     * @param destinationDomain destination domain
     * @param mintRecipient address of mint recipient on destination domain
     * @param burnToken address of contract to burn deposited tokens, on local domain
     * @param destinationCaller caller on the destination domain, as bytes32
     * @return nonce unique nonce reserved by message
     */
    function depositForBurnWithCaller(
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient,
        address burnToken,
        bytes32 destinationCaller
    ) external returns (uint64 nonce);

    /**
     * @notice Handles an incoming message received by the local MessageTransmitter,
     * and takes the appropriate action. For a burn message, mints the
     * associated token to the requested recipient on the local domain.
     * @dev Validates the local sender is the local MessageTransmitter, and the
     * remote sender is a registered remote TokenMessenger for `remoteDomain`.
     * @param remoteDomain The domain where the message originated from.
     * @param sender The sender of the message (remote TokenMessenger).
     * @param messageBody The message body bytes.
     * @return success Bool, true if successful.
     */
    function handleReceiveMessage(
        uint32 remoteDomain,
        bytes32 sender,
        bytes calldata messageBody
    ) external returns (bool success);

    // ═══════════════════════════════════════════════════ VIEWS ═══════════════════════════════════════════════════════

    // Local Message Transmitter responsible for sending and receiving messages to/from remote domains
    function localMessageTransmitter() external view returns (address);

    // Minter responsible for minting and burning tokens on the local domain
    function localMinter() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

error CastOverflow();

error IncorrectRequestLength();
error UnknownRequestVersion();

error CCTPGasRescueFailed();
error CCTPIncorrectChainId();
error CCTPIncorrectConfig();
error CCTPIncorrectDomain();
error CCTPIncorrectGasAmount();
error CCTPIncorrectProtocolFee();
error CCTPIncorrectTokenAmount();
error CCTPInsufficientAmount();
error CCTPSymbolAlreadyAdded();
error CCTPSymbolIncorrect();
error CCTPTokenAlreadyAdded();
error CCTPTokenNotFound();
error CCTPZeroAddress();
error CCTPZeroAmount();

error CCTPMessageNotReceived();
error RemoteCCTPDeploymentNotSet();
error RemoteCCTPTokenNotSet();

error ForwarderDeploymentFailed();

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IDefaultPool, IDefaultExtendedPool} from "../interfaces/IDefaultExtendedPool.sol";
import {IRouterAdapter} from "../interfaces/IRouterAdapter.sol";
import {IWETH9} from "../interfaces/IWETH9.sol";
import {MsgValueIncorrect, PoolNotFound, TokenAddressMismatch, TokensIdentical} from "../libs/Errors.sol";
import {Action, DefaultParams} from "../libs/Structs.sol";
import {UniversalTokenLib} from "../libs/UniversalToken.sol";

import {SafeERC20, IERC20} from "@openzeppelin/contracts-4.5.0/token/ERC20/utils/SafeERC20.sol";

contract DefaultAdapter is IRouterAdapter {
    using SafeERC20 for IERC20;
    using UniversalTokenLib for address;

    /// @notice Enable this contract to receive Ether when withdrawing from WETH.
    /// @dev Consider implementing rescue functions to withdraw Ether from this contract.
    receive() external payable {}

    /// @inheritdoc IRouterAdapter
    function adapterSwap(
        address recipient,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        bytes memory rawParams
    ) external payable returns (uint256 amountOut) {
        return _adapterSwap(recipient, tokenIn, amountIn, tokenOut, rawParams);
    }

    /// @dev Internal logic for doing a tokenIn -> tokenOut swap.
    /// Note: `tokenIn` is assumed to have already been transferred to this contract.
    function _adapterSwap(
        address recipient,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        bytes memory rawParams
    ) internal virtual returns (uint256 amountOut) {
        // We define a few phases for the whole Adapter's swap process.
        // (?) means the phase is optional.
        // (!) means the phase is mandatory.

        // PHASE 0(!): CHECK ALL THE PARAMS
        DefaultParams memory params = _checkParams(tokenIn, tokenOut, rawParams);

        // PHASE 1(?): WRAP RECEIVED ETH INTO WETH
        tokenIn = _wrapReceivedETH(tokenIn, amountIn, tokenOut, params);
        // After PHASE 1 this contract has `amountIn` worth of `tokenIn`, tokenIn != ETH_ADDRESS

        // PHASE 2(?): PREPARE TO UNWRAP SWAPPED WETH
        address tokenSwapTo = _deriveTokenSwapTo(tokenIn, tokenOut, params);
        // We need to perform tokenIn -> tokenSwapTo action in PHASE 3.
        // if tokenOut == ETH_ADDRESS, we need to unwrap WETH in PHASE 4.
        // Recipient will receive `tokenOut` in PHASE 5.

        // PHASE 3(?): PERFORM A REQUESTED SWAP
        amountOut = _performPoolAction(tokenIn, amountIn, tokenSwapTo, params);
        // After PHASE 3 this contract has `amountOut` worth of `tokenSwapTo`, tokenSwapTo != ETH_ADDRESS

        // PHASE 4(?): UNWRAP SWAPPED WETH
        // Check if the final token is native ETH
        if (tokenOut == UniversalTokenLib.ETH_ADDRESS) {
            // PHASE 2: WETH address was stored as `tokenSwapTo`
            _unwrapETH(tokenSwapTo, amountOut);
        }

        // PHASE 5(!): TRANSFER SWAPPED TOKENS TO RECIPIENT
        // Note: this will transfer native ETH, if tokenOut == ETH_ADDRESS
        // Note: this is a no-op if recipient == address(this)
        tokenOut.universalTransfer(recipient, amountOut);
    }

    /// @dev Checks the params and decodes them into a struct.
    function _checkParams(
        address tokenIn,
        address tokenOut,
        bytes memory rawParams
    ) internal pure returns (DefaultParams memory params) {
        if (tokenIn == tokenOut) revert TokensIdentical();
        // Decode params for swapping via a Default pool
        params = abi.decode(rawParams, (DefaultParams));
        // Swap pool should exist, if action other than HandleEth was requested
        if (params.pool == address(0) && params.action != Action.HandleEth) revert PoolNotFound();
    }

    /// @dev Wraps native ETH into WETH, if requested.
    /// Returns the address of the token this contract ends up with.
    function _wrapReceivedETH(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        DefaultParams memory params
    ) internal returns (address wrappedTokenIn) {
        // tokenIn was already transferred to this contract, check if we start from native ETH
        if (tokenIn == UniversalTokenLib.ETH_ADDRESS) {
            // Determine WETH address: this is either tokenOut (if no swap is needed),
            // or a pool token with index `tokenIndexFrom` (if swap is needed).
            wrappedTokenIn = _deriveWethAddress({token: tokenOut, params: params, isTokenFromWeth: true});
            // Wrap ETH into WETH and leave it in this contract
            _wrapETH(wrappedTokenIn, amountIn);
        } else {
            wrappedTokenIn = tokenIn;
            // For ERC20 tokens msg.value should be zero
            if (msg.value != 0) revert MsgValueIncorrect();
        }
    }

    /// @dev Derives the address of token to be received after an action defined in `params`.
    function _deriveTokenSwapTo(
        address tokenIn,
        address tokenOut,
        DefaultParams memory params
    ) internal view returns (address tokenSwapTo) {
        // Check if swap to native ETH was requested
        if (tokenOut == UniversalTokenLib.ETH_ADDRESS) {
            // Determine WETH address: this is either tokenIn (if no swap is needed),
            // or a pool token with index `tokenIndexTo` (if swap is needed).
            tokenSwapTo = _deriveWethAddress({token: tokenIn, params: params, isTokenFromWeth: false});
        } else {
            tokenSwapTo = tokenOut;
        }
    }

    /// @dev Performs an action defined in `params` and returns the amount of `tokenSwapTo` received.
    function _performPoolAction(
        address tokenIn,
        uint256 amountIn,
        address tokenSwapTo,
        DefaultParams memory params
    ) internal returns (uint256 amountOut) {
        // Determine if we need to perform a swap
        if (params.action == Action.HandleEth) {
            // If no swap is required, amountOut doesn't change
            amountOut = amountIn;
        } else {
            // Record balance before the swap
            amountOut = IERC20(tokenSwapTo).balanceOf(address(this));
            // Approve the pool for spending exactly `amountIn` of `tokenIn`
            IERC20(tokenIn).safeIncreaseAllowance(params.pool, amountIn);
            if (params.action == Action.Swap) {
                _swap(params.pool, params, amountIn, tokenSwapTo);
            } else if (params.action == Action.AddLiquidity) {
                _addLiquidity(params.pool, params, amountIn, tokenSwapTo);
            } else {
                // The only remaining action is RemoveLiquidity
                _removeLiquidity(params.pool, params, amountIn, tokenSwapTo);
            }
            // Use the difference between the balance after the swap and the recorded balance as `amountOut`
            amountOut = IERC20(tokenSwapTo).balanceOf(address(this)) - amountOut;
        }
    }

    // ═══════════════════════════════════════ INTERNAL LOGIC: SWAP ACTIONS ════════════════════════════════════════════

    /// @dev Performs a swap through the given pool.
    /// Note: The pool should be already approved for spending `tokenIn`.
    function _swap(
        address pool,
        DefaultParams memory params,
        uint256 amountIn,
        address tokenOut
    ) internal {
        // tokenOut should match the "swap to" token
        if (IDefaultPool(pool).getToken(params.tokenIndexTo) != tokenOut) revert TokenAddressMismatch();
        // amountOut and deadline are not checked in RouterAdapter
        IDefaultPool(pool).swap({
            tokenIndexFrom: params.tokenIndexFrom,
            tokenIndexTo: params.tokenIndexTo,
            dx: amountIn,
            minDy: 0,
            deadline: type(uint256).max
        });
    }

    /// @dev Adds liquidity in a form of a single token to the given pool.
    /// Note: The pool should be already approved for spending `tokenIn`.
    function _addLiquidity(
        address pool,
        DefaultParams memory params,
        uint256 amountIn,
        address tokenOut
    ) internal {
        uint256 numTokens = _getPoolNumTokens(pool);
        address lpToken = _getPoolLPToken(pool);
        // tokenOut should match the LP token
        if (lpToken != tokenOut) revert TokenAddressMismatch();
        uint256[] memory amounts = new uint256[](numTokens);
        amounts[params.tokenIndexFrom] = amountIn;
        // amountOut and deadline are not checked in RouterAdapter
        IDefaultExtendedPool(pool).addLiquidity({amounts: amounts, minToMint: 0, deadline: type(uint256).max});
    }

    /// @dev Removes liquidity in a form of a single token from the given pool.
    /// Note: The pool should be already approved for spending `tokenIn`.
    function _removeLiquidity(
        address pool,
        DefaultParams memory params,
        uint256 amountIn,
        address tokenOut
    ) internal {
        // tokenOut should match the "swap to" token
        if (IDefaultPool(pool).getToken(params.tokenIndexTo) != tokenOut) revert TokenAddressMismatch();
        // amountOut and deadline are not checked in RouterAdapter
        IDefaultExtendedPool(pool).removeLiquidityOneToken({
            tokenAmount: amountIn,
            tokenIndex: params.tokenIndexTo,
            minAmount: 0,
            deadline: type(uint256).max
        });
    }

    // ═════════════════════════════════════════ INTERNAL LOGIC: POOL LENS ═════════════════════════════════════════════

    /// @dev Returns the LP token address of the given pool.
    function _getPoolLPToken(address pool) internal view returns (address lpToken) {
        (, , , , , , lpToken) = IDefaultExtendedPool(pool).swapStorage();
    }

    /// @dev Returns the number of tokens in the given pool.
    function _getPoolNumTokens(address pool) internal view returns (uint256 numTokens) {
        // Iterate over all tokens in the pool until the end is reached
        for (uint8 index = 0; ; ++index) {
            try IDefaultPool(pool).getToken(index) returns (address) {} catch {
                // End of pool reached
                numTokens = index;
                break;
            }
        }
    }

    /// @dev Returns the tokens in the given pool.
    function _getPoolTokens(address pool) internal view returns (address[] memory tokens) {
        uint256 numTokens = _getPoolNumTokens(pool);
        tokens = new address[](numTokens);
        for (uint8 i = 0; i < numTokens; ++i) {
            // This will not revert because we already know the number of tokens in the pool
            tokens[i] = IDefaultPool(pool).getToken(i);
        }
    }

    /// @dev Returns the quote for a swap through the given pool.
    /// Note: will return 0 on invalid swaps.
    function _getPoolSwapQuote(
        address pool,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 amountIn
    ) internal view returns (uint256 amountOut) {
        try IDefaultPool(pool).calculateSwap(tokenIndexFrom, tokenIndexTo, amountIn) returns (uint256 dy) {
            amountOut = dy;
        } catch {
            // Return 0 instead of reverting
            amountOut = 0;
        }
    }

    // ════════════════════════════════════════ INTERNAL LOGIC: ETH <> WETH ════════════════════════════════════════════

    /// @dev Wraps ETH into WETH.
    function _wrapETH(address weth, uint256 amount) internal {
        if (amount != msg.value) revert MsgValueIncorrect();
        // Deposit in order to have WETH in this contract
        IWETH9(weth).deposit{value: amount}();
    }

    /// @dev Unwraps WETH into ETH.
    function _unwrapETH(address weth, uint256 amount) internal {
        // Withdraw ETH to this contract
        IWETH9(weth).withdraw(amount);
    }

    /// @dev Derives WETH address from swap parameters.
    function _deriveWethAddress(
        address token,
        DefaultParams memory params,
        bool isTokenFromWeth
    ) internal view returns (address weth) {
        if (params.action == Action.HandleEth) {
            // If we only need to wrap/unwrap ETH, WETH address should be specified as the other token
            weth = token;
        } else {
            // Otherwise, we need to get WETH address from the liquidity pool
            weth = address(
                IDefaultPool(params.pool).getToken(isTokenFromWeth ? params.tokenIndexFrom : params.tokenIndexTo)
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRouterAdapter {
    /// @notice Performs a tokenIn -> tokenOut swap, according to the provided params.
    /// If tokenIn is ETH_ADDRESS, this method should be invoked with `msg.value = amountIn`.
    /// If tokenIn is ERC20, the tokens should be already transferred to this contract (using `msg.value = 0`).
    /// If tokenOut is ETH_ADDRESS, native ETH will be sent to the recipient (be aware of potential reentrancy).
    /// If tokenOut is ERC20, the tokens will be transferred to the recipient.
    /// @dev Contracts implementing {IRouterAdapter} interface are required to enforce the above restrictions.
    /// On top of that, they must ensure that exactly `amountOut` worth of `tokenOut` is transferred to the recipient.
    /// Swap deadline and slippage is checked outside of this contract.
    /// @param recipient    Address to receive the swapped token
    /// @param tokenIn      Token to sell (use ETH_ADDRESS to start from native ETH)
    /// @param amountIn     Amount of tokens to sell
    /// @param tokenOut     Token to buy (use ETH_ADDRESS to end with native ETH)
    /// @param rawParams    Additional swap parameters
    /// @return amountOut   Amount of bought tokens
    function adapterSwap(
        address recipient,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        bytes calldata rawParams
    ) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

error DeadlineExceeded();
error InsufficientOutputAmount();

error MsgValueIncorrect();
error PoolNotFound();
error TokenAddressMismatch();
error TokenNotContract();
error TokenNotETH();
error TokensIdentical();

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TokenNotContract} from "./Errors.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts-4.5.0/token/ERC20/utils/SafeERC20.sol";

library UniversalTokenLib {
    using SafeERC20 for IERC20;

    address internal constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice Transfers tokens to the given account. Reverts if transfer is not successful.
    /// @dev This might trigger fallback, if ETH is transferred to the contract.
    /// Make sure this can not lead to reentrancy attacks.
    function universalTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // Don't do anything, if need to send tokens to this address
        if (to == address(this)) return;
        if (token == ETH_ADDRESS) {
            /// @dev Note: this can potentially lead to executing code in `to`.
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = to.call{value: value}("");
            require(success, "ETH transfer failed");
        } else {
            IERC20(token).safeTransfer(to, value);
        }
    }

    /// @notice Issues an infinite allowance to the spender, if the current allowance is insufficient
    /// to spend the given amount.
    function universalApproveInfinity(
        address token,
        address spender,
        uint256 amountToSpend
    ) internal {
        // ETH Chad doesn't require your approval
        if (token == ETH_ADDRESS) return;
        // No-op if allowance is already sufficient
        uint256 allowance = IERC20(token).allowance(address(this), spender);
        if (allowance >= amountToSpend) return;
        // Otherwise, reset approval to 0 and set to max allowance
        if (allowance > 0) IERC20(token).safeApprove(spender, 0);
        IERC20(token).safeApprove(spender, type(uint256).max);
    }

    /// @notice Returns the balance of the given token (or native ETH) for the given account.
    function universalBalanceOf(address token, address account) internal view returns (uint256) {
        if (token == ETH_ADDRESS) {
            return account.balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }

    /// @dev Checks that token is a contract and not ETH_ADDRESS.
    function assertIsContract(address token) internal view {
        // Check that ETH_ADDRESS was not used (in case this is a predeploy on any of the chains)
        if (token == UniversalTokenLib.ETH_ADDRESS) revert TokenNotContract();
        // Check that token is not an EOA
        if (token.code.length == 0) revert TokenNotContract();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IDefaultPool} from "./IDefaultPool.sol";

interface IDefaultExtendedPool is IDefaultPool {
    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    ) external returns (uint256);

    // ═══════════════════════════════════════════════════ VIEWS ═══════════════════════════════════════════════════════

    function calculateRemoveLiquidity(uint256 amount) external view returns (uint256[] memory);

    function calculateRemoveLiquidityOneToken(uint256 tokenAmount, uint8 tokenIndex)
        external
        view
        returns (uint256 availableTokenAmount);

    function getAPrecise() external view returns (uint256);

    function getTokenBalance(uint8 index) external view returns (uint256);

    function swapStorage()
        external
        view
        returns (
            uint256 initialA,
            uint256 futureA,
            uint256 initialATime,
            uint256 futureATime,
            uint256 swapFee,
            uint256 adminFee,
            address lpToken
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IWETH9 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}