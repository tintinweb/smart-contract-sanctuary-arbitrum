// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// prettier-ignore
import {
    CCTPIncorrectChainId,
    CCTPIncorrectDomain,
    CCTPMessageNotReceived,
    CCTPTokenNotFound,
    CCTPZeroAddress,
    CCTPZeroAmount,
    RemoteCCTPDeploymentNotSet,
    RemoteCCTPTokenNotSet
} from "./libs/Errors.sol";
import {SynapseCCTPEvents} from "./events/SynapseCCTPEvents.sol";
import {EnumerableSet, SynapseCCTPFees} from "./fees/SynapseCCTPFees.sol";
import {IDefaultPool} from "./interfaces/IDefaultPool.sol";
import {IMessageTransmitter} from "./interfaces/IMessageTransmitter.sol";
import {ISynapseCCTP} from "./interfaces/ISynapseCCTP.sol";
import {ITokenMinter} from "./interfaces/ITokenMinter.sol";
import {ITokenMessenger} from "./interfaces/ITokenMessenger.sol";
import {RequestLib} from "./libs/Request.sol";
import {MinimalForwarderLib} from "./libs/MinimalForwarder.sol";
import {TypeCasts} from "./libs/TypeCasts.sol";

import {SafeERC20, IERC20} from "@openzeppelin/contracts-4.5.0/token/ERC20/utils/SafeERC20.sol";

contract SynapseCCTP is SynapseCCTPFees, SynapseCCTPEvents, ISynapseCCTP {
    using EnumerableSet for EnumerableSet.AddressSet;
    using MinimalForwarderLib for address;
    using SafeERC20 for IERC20;
    using TypeCasts for address;
    using TypeCasts for bytes32;

    /// @notice Struct defining the configuration of a remote domain that has SynapseCCTP deployed.
    /// @dev CCTP uses the following convention for domain numbers:
    /// - 0: Ethereum Mainnet
    /// - 1: Avalanche Mainnet
    /// With more chains added, the convention will be extended.
    /// @param domain       Value for the remote domain used in CCTP messages.
    /// @param synapseCCTP  Address of the SynapseCCTP deployed on the remote chain.
    struct DomainConfig {
        uint32 domain;
        address synapseCCTP;
    }

    /// @notice Refers to the local domain number used in CCTP messages.
    uint32 public immutable localDomain;
    IMessageTransmitter public immutable messageTransmitter;
    ITokenMessenger public immutable tokenMessenger;

    // (chainId => configuration of the remote chain)
    mapping(uint256 => DomainConfig) public remoteDomainConfig;

    constructor(ITokenMessenger tokenMessenger_) {
        tokenMessenger = tokenMessenger_;
        messageTransmitter = IMessageTransmitter(tokenMessenger_.localMessageTransmitter());
        localDomain = messageTransmitter.localDomain();
    }

    // ═════════════════════════════════════════════ SET CONFIG LOGIC ══════════════════════════════════════════════════

    /// @notice Sets the remote domain and deployment of SynapseCCTP for the given remote chainId.
    function setRemoteDomainConfig(
        uint256 remoteChainId,
        uint32 remoteDomain,
        address remoteSynapseCCTP
    ) external onlyOwner {
        // ChainId should be non-zero and different from the local chain id.
        if (remoteChainId == 0 || remoteChainId == block.chainid) revert CCTPIncorrectChainId();
        // Remote domain should differ from the local domain.
        if (remoteDomain == localDomain) revert CCTPIncorrectDomain();
        // Remote domain should be 0 IF AND ONLY IF remote chain id is 1 (Ethereum Mainnet).
        // Or if remote chain id is 5 (Goerli). TODO: remove this in production.
        if ((remoteDomain == 0) != (remoteChainId == 1 || remoteChainId == 5)) revert CCTPIncorrectDomain();
        // Remote SynapseCCTP should be non-zero.
        if (remoteSynapseCCTP == address(0)) revert CCTPZeroAddress();
        remoteDomainConfig[remoteChainId] = DomainConfig(remoteDomain, remoteSynapseCCTP);
    }

    // ═════════════════════════════════════════════ FEES WITHDRAWING ══════════════════════════════════════════════════

    /// @notice Allows the owner to withdraw accumulated protocol fees.
    function withdrawProtocolFees(address token) external onlyOwner {
        uint256 accFees = accumulatedFees[address(0)][token];
        if (accFees == 0) revert CCTPZeroAmount();
        accumulatedFees[address(0)][token] = 0;
        IERC20(token).safeTransfer(msg.sender, accFees);
    }

    /// @notice Allows the Relayer's fee collector to withdraw accumulated relayer fees.
    function withdrawRelayerFees(address token) external {
        uint256 accFees = accumulatedFees[msg.sender][token];
        if (accFees == 0) revert CCTPZeroAmount();
        accumulatedFees[msg.sender][token] = 0;
        IERC20(token).safeTransfer(msg.sender, accFees);
    }

    // ════════════════════════════════════════════════ CCTP LOGIC ═════════════════════════════════════════════════════

    /// @inheritdoc ISynapseCCTP
    function sendCircleToken(
        address recipient,
        uint256 chainId,
        address burnToken,
        uint256 amount,
        uint32 requestVersion,
        bytes memory swapParams
    ) external {
        // Check if token is supported before doing anything else.
        if (!_bridgeTokens.contains(burnToken)) revert CCTPTokenNotFound();
        // Pull token from user and update the amount in case of transfer fee.
        amount = _pullToken(burnToken, amount);
        uint64 nonce = messageTransmitter.nextAvailableNonce();
        // This will revert if the request version is not supported, or swap params are not properly formatted.
        bytes memory formattedRequest = RequestLib.formatRequest(
            requestVersion,
            RequestLib.formatBaseRequest(localDomain, nonce, burnToken, amount, recipient),
            swapParams
        );
        DomainConfig memory config = remoteDomainConfig[chainId];
        bytes32 dstSynapseCCTP = config.synapseCCTP.addressToBytes32();
        if (dstSynapseCCTP == 0) revert RemoteCCTPDeploymentNotSet();
        uint32 destinationDomain = config.domain;
        // Construct the request identifier to be used as salt later.
        // The identifier (kappa) is unique for every single request on all the chains.
        // This is done by including origin and destination domains as well as origin nonce in the hashed data.
        // Origin domain and nonce are included in `formattedRequest`, so we only need to add the destination domain.
        bytes32 kappa = _kappa(destinationDomain, requestVersion, formattedRequest);
        // Issue allowance if needed
        _approveToken(burnToken, address(tokenMessenger), amount);
        tokenMessenger.depositForBurnWithCaller(
            amount,
            destinationDomain,
            dstSynapseCCTP,
            burnToken,
            _destinationCaller(dstSynapseCCTP.bytes32ToAddress(), kappa)
        );
        emit CircleRequestSent(chainId, nonce, burnToken, amount, requestVersion, formattedRequest, kappa);
    }

    // TODO: guard this to be only callable by the validators?
    /// @inheritdoc ISynapseCCTP
    function receiveCircleToken(
        bytes calldata message,
        bytes calldata signature,
        uint32 requestVersion,
        bytes memory formattedRequest
    ) external {
        (bytes memory baseRequest, bytes memory swapParams) = RequestLib.decodeRequest(
            requestVersion,
            formattedRequest
        );
        (uint32 originDomain, , address originBurnToken, uint256 amount, address recipient) = RequestLib
            .decodeBaseRequest(baseRequest);
        // For kappa hashing we use origin and destination domains as well as origin nonce.
        // This ensures that kappa is unique for each request, and that it is not possible to replay requests.
        bytes32 kappa = _kappa(localDomain, requestVersion, formattedRequest);
        // Kindly ask the Circle Bridge to mint the tokens for us.
        _mintCircleToken(message, signature, kappa);
        address token = _getLocalToken(originDomain, originBurnToken);
        uint256 fee;
        // Apply the bridging fee. This will revert if amount <= fee.
        (amount, fee) = _applyRelayerFee(token, amount, requestVersion == RequestLib.REQUEST_SWAP);
        // Fulfill the request: perform an optional swap and send the end tokens to the recipient.
        (address tokenOut, uint256 amountOut) = _fulfillRequest(recipient, token, amount, swapParams);
        emit CircleRequestFulfilled(recipient, token, fee, tokenOut, amountOut, kappa);
    }

    // ═══════════════════════════════════════════════════ VIEWS ═══════════════════════════════════════════════════════

    /// @notice Get the local token associated with the given remote domain and token.
    function getLocalToken(uint32 remoteDomain, address remoteToken) external view returns (address) {
        return _getLocalToken(remoteDomain, remoteToken);
    }

    /// @notice Checks if the given request is already fulfilled.
    function isRequestFulfilled(bytes32 kappa) external view returns (bool) {
        // Request is fulfilled if the kappa is already used, meaning the forwarder is already deployed.
        return MinimalForwarderLib.predictAddress(address(this), kappa).code.length > 0;
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

    /// @dev Pulls the token from the sender.
    function _pullToken(address token, uint256 amount) internal returns (uint256 amountPulled) {
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        amountPulled = IERC20(token).balanceOf(address(this)) - balanceBefore;
    }

    /// @dev Mints the Circle token by sending the message and signature to the Circle Bridge.
    function _mintCircleToken(
        bytes calldata message,
        bytes calldata signature,
        bytes32 kappa
    ) internal {
        // Deploy a forwarder specific to this request. Will revert if the kappa has been used before.
        address forwarder = MinimalForwarderLib.deploy(kappa);
        // Form the payload for the Circle Bridge.
        bytes memory payload = abi.encodeWithSelector(IMessageTransmitter.receiveMessage.selector, message, signature);
        // Use the deployed forwarder (who is the only one who can call the Circle Bridge for this message)
        // This will revert if the provided message is not properly formatted, or if the signatures are invalid.
        bytes memory returnData = forwarder.forwardCall(address(messageTransmitter), payload);
        // messageTransmitter.receiveMessage is supposed to return true if the message was received.
        if (!abi.decode(returnData, (bool))) revert CCTPMessageNotReceived();
    }

    /// @dev Performs a swap, if was requested back on origin chain, and transfers the tokens to the recipient.
    /// Should the swap fail, will transfer `token` to the recipient instead.
    function _fulfillRequest(
        address recipient,
        address token,
        uint256 amount,
        bytes memory swapParams
    ) internal returns (address tokenOut, uint256 amountOut) {
        // Fallback to Base Request if no swap params are provided
        if (swapParams.length == 0) {
            IERC20(token).safeTransfer(recipient, amount);
            return (token, amount);
        }
        // We checked request version to be a valid value when wrapping into `request`,
        // so this could only be `RequestLib.REQUEST_SWAP`.
        (address pool, uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 deadline, uint256 minAmountOut) = RequestLib
            .decodeSwapParams(swapParams);
        tokenOut = _tryGetToken(pool, tokenIndexTo);
        // Fallback to Base Request if failed to get tokenOut address
        if (tokenOut == address(0)) {
            IERC20(token).safeTransfer(recipient, amount);
            return (token, amount);
        }
        // Approve the pool to spend the token, if needed.
        _approveToken(token, pool, amount);
        amountOut = _trySwap(pool, tokenIndexFrom, tokenIndexTo, amount, deadline, minAmountOut);
        // Fallback to Base Request if failed to swap
        if (amountOut == 0) {
            IERC20(token).safeTransfer(recipient, amount);
            return (token, amount);
        }
        // Transfer the swapped tokens to the recipient.
        IERC20(tokenOut).safeTransfer(recipient, amountOut);
    }

    /// @dev Tries to swap tokens using the provided swap instructions.
    /// Instead of reverting, returns 0 if the swap failed.
    function _trySwap(
        address pool,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 amount,
        uint256 deadline,
        uint256 minAmountOut
    ) internal returns (uint256 amountOut) {
        try IDefaultPool(pool).swap(tokenIndexFrom, tokenIndexTo, amount, minAmountOut, deadline) returns (
            uint256 amountOut_
        ) {
            amountOut = amountOut_;
        } catch {
            // Swapping failed, return 0
            amountOut = 0;
        }
    }

    // ══════════════════════════════════════════════ INTERNAL VIEWS ═══════════════════════════════════════════════════

    /// @dev Gets the address of the local minted Circle token from the local TokenMinter.
    function _getLocalToken(uint32 remoteDomain, address remoteToken) internal view returns (address token) {
        ITokenMinter minter = ITokenMinter(tokenMessenger.localMinter());
        token = minter.getLocalToken(remoteDomain, remoteToken.addressToBytes32());
        // Revert if TokenMinter is not aware of this remote token.
        if (token == address(0)) revert CCTPTokenNotFound();
    }

    /// @dev Tries to get the token address from the pool.
    /// Instead of reverting, returns 0 if the getToken failed.
    function _tryGetToken(address pool, uint8 tokenIndex) internal view returns (address token) {
        try IDefaultPool(pool).getToken(tokenIndex) returns (address _token) {
            token = _token;
        } catch {
            // Return 0 on revert
            token = address(0);
        }
    }

    /// @dev Predicts the address of the destination caller that will be used to call the Circle Message Transmitter.
    function _destinationCaller(address synapseCCTP, bytes32 kappa) internal pure returns (bytes32) {
        return synapseCCTP.predictAddress(kappa).addressToBytes32();
    }

    /// @dev Calculates the unique identifier of the request.
    function _kappa(
        uint32 destinationDomain,
        uint32 requestVersion,
        bytes memory formattedRequest
    ) internal pure returns (bytes32 kappa) {
        // Merge the destination domain and the request version into a single uint256.
        uint256 prefix = (uint256(destinationDomain) << 32) | requestVersion;
        bytes32 requestHash = keccak256(formattedRequest);
        // Use assembly to return hash of the prefix and the request hash.
        // We are using scratch space to avoid unnecessary memory expansion.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Store prefix in memory at 0, and requestHash at 32.
            mstore(0, prefix)
            mstore(32, requestHash)
            // Return hash of first 64 bytes of memory.
            kappa := keccak256(0, 64)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

error CastOverflow();

error IncorrectRequestLength();
error UnknownRequestVersion();

error CCTPIncorrectChainId();
error CCTPIncorrectConfig();
error CCTPIncorrectDomain();
error CCTPIncorrectProtocolFee();
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

abstract contract SynapseCCTPEvents {
    // TODO: figure out what we need to emit for the Explorer

    /// @notice Emitted when a Circle token is sent with an attached action request.
    /// @dev To fulfill the request, the validator needs to fetch `message` from `MessageSent` event
    /// emitted by Circle's MessageTransmitter in the same tx, then fetch `signature` for the message from Circle API.
    /// This data will need to be presented to SynapseCCTP on the destination chain,
    /// along with `requestVersion` and `formattedRequest` emitted in this event.
    /// @param chainId              Chain ID of the destination chain
    /// @param nonce                Nonce of the CCTP message on origin chain
    /// @param token                Address of Circle token that was burnt
    /// @param amount               Amount of Circle tokens burnt
    /// @param requestVersion       Version of the request format
    /// @param formattedRequest     Formatted request for the action to take on the destination chain
    /// @param kappa                Unique identifier of the request
    event CircleRequestSent(
        uint256 chainId,
        uint64 nonce,
        address token,
        uint256 amount,
        uint32 requestVersion,
        bytes formattedRequest,
        bytes32 indexed kappa
    );

    /// @notice Emitted when a Circle token is received with an attached action request.
    /// @param recipient            End recipient of the tokens on this chain
    /// @param mintToken            Address of the minted Circle token
    /// @param fee                  Fee paid for fulfilling the request, in minted tokens
    /// @param token                Address of token that recipient received
    /// @param amount               Amount of tokens received by recipient
    /// @param kappa                Unique identifier of the request
    event CircleRequestFulfilled(
        address indexed recipient,
        address mintToken,
        uint256 fee,
        address token,
        uint256 amount,
        bytes32 indexed kappa
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SynapseCCTPFeesEvents} from "../events/SynapseCCTPFeesEvents.sol";
// prettier-ignore
import {
    CCTPIncorrectConfig,
    CCTPIncorrectProtocolFee,
    CCTPInsufficientAmount,
    CCTPSymbolAlreadyAdded,
    CCTPSymbolIncorrect,
    CCTPTokenAlreadyAdded,
    CCTPTokenNotFound
} from "../libs/Errors.sol";
import {BridgeToken} from "../libs/Structs.sol";
import {TypeCasts} from "../libs/TypeCasts.sol";

import {Ownable} from "@openzeppelin/contracts-4.5.0/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts-4.5.0/utils/structs/EnumerableSet.sol";

abstract contract SynapseCCTPFees is SynapseCCTPFeesEvents, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using TypeCasts for uint256;

    /// @notice CCTP fee structure for a supported Circle token.
    /// @dev Optimized for storage. 2**72 is 4*10**21, which is enough to represent adequate amounts
    /// for stable coins with 18 decimals. Circle tokens have 6 decimals, so this is more than enough.
    /// @param relayerFee   Fee % for bridging a token to this chain, multiplied by `FEE_DENOMINATOR`
    /// @param minBaseFee   Minimum fee for bridging a token to this chain using a base request
    /// @param minSwapFee   Minimum fee for bridging a token to this chain using a swap request
    /// @param maxFee       Maximum fee for bridging a token to this chain
    struct CCTPFee {
        uint40 relayerFee;
        uint72 minBaseFee;
        uint72 minSwapFee;
        uint72 maxFee;
    }

    /// @dev Denominator used to calculate the bridge fee
    uint256 private constant FEE_DENOMINATOR = 10**10;
    /// @dev Maximum relayer fee that can be set: 10 bps
    uint256 private constant MAX_RELAYER_FEE = 10**7;
    /// @dev Maximum protocol fee that can be set: 50%
    uint256 private constant MAX_PROTOCOL_FEE = FEE_DENOMINATOR / 2;
    /// @dev Mandatory prefix used for CCTP token symbols to distinguish them from other bridge symbols
    bytes private constant SYMBOL_PREFIX = "CCTP.";
    /// @dev Length of the mandatory prefix used for CCTP token symbols
    uint256 private constant SYMBOL_PREFIX_LENGTH = 5;

    // ══════════════════════════════════════════════════ STORAGE ══════════════════════════════════════════════════════

    /// @notice Maps bridge token address into bridge token symbol
    mapping(address => string) public tokenToSymbol;
    /// @notice Maps bridge token symbol into bridge token address
    mapping(string => address) public symbolToToken;
    /// @notice Maps bridge token address into CCTP fee structure
    mapping(address => CCTPFee) public feeStructures;
    /// @notice Maps fee collector address into accumulated fees for a token
    /// (feeCollector => (token => amount))
    /// @dev Fee collector address of address(0) indicates that fees are accumulated by the Protocol
    mapping(address => mapping(address => uint256)) public accumulatedFees;
    /// @notice Maps Relayer address into collector address for accumulated Relayer's fees
    /// @dev Default value of address(0) indicates that a Relayer's fees are accumulated by the Protocol
    mapping(address => address) public relayerFeeCollectors;
    /// @notice Protocol fee: percentage of the relayer fee that is collected by the Protocol
    /// @dev Protocol collects the full fee amount, if the Relayer hasn't set a fee collector
    uint256 public protocolFee;
    /// @dev A list of all supported bridge tokens
    EnumerableSet.AddressSet internal _bridgeTokens;

    // ════════════════════════════════════════════════ ONLY OWNER ═════════════════════════════════════════════════════

    /// @notice Adds a new token to the list of supported tokens, with the given symbol and fee structure.
    /// @dev The symbol must start with "CCTP."
    /// @param symbol       Symbol of the token
    /// @param token        Address of the token
    /// @param relayerFee   Fee % for bridging a token to this chain, multiplied by `FEE_DENOMINATOR`
    /// @param minBaseFee   Minimum fee for bridging a token to this chain using a base request
    /// @param minSwapFee   Minimum fee for bridging a token to this chain using a swap request
    /// @param maxFee       Maximum fee for bridging a token to this chain
    function addToken(
        string memory symbol,
        address token,
        uint256 relayerFee,
        uint256 minBaseFee,
        uint256 minSwapFee,
        uint256 maxFee
    ) external onlyOwner {
        if (token == address(0)) revert CCTPIncorrectConfig();
        // Add a new token to the list of supported tokens, and check that it hasn't been added before
        if (!_bridgeTokens.add(token)) revert CCTPTokenAlreadyAdded();
        // Check that symbol hasn't been added yet and starts with "CCTP."
        _assertCanAddSymbol(symbol);
        // Add token <> symbol link
        tokenToSymbol[token] = symbol;
        symbolToToken[symbol] = token;
        // Set token fee
        _setTokenFee(token, relayerFee, minBaseFee, minSwapFee, maxFee);
    }

    /// @notice Removes a token from the list of supported tokens.
    /// @dev Will revert if the token is not supported.
    function removeToken(address token) external onlyOwner {
        // Remove a token from the list of supported tokens, and check that it has been added before
        if (!_bridgeTokens.remove(token)) revert CCTPTokenNotFound();
        // Remove token <> symbol link
        string memory symbol = tokenToSymbol[token];
        delete tokenToSymbol[token];
        delete symbolToToken[symbol];
        // Remove token fee structure
        delete feeStructures[token];
    }

    /// @notice Updates the fee structure for a supported Circle token.
    /// @dev Will revert if the token is not supported.
    /// @param token        Address of the token
    /// @param relayerFee   Fee % for bridging a token to this chain, multiplied by `FEE_DENOMINATOR`
    /// @param minBaseFee   Minimum fee for bridging a token to this chain using a base request
    /// @param minSwapFee   Minimum fee for bridging a token to this chain using a swap request
    /// @param maxFee       Maximum fee for bridging a token to this chain
    function setTokenFee(
        address token,
        uint256 relayerFee,
        uint256 minBaseFee,
        uint256 minSwapFee,
        uint256 maxFee
    ) external onlyOwner {
        if (!_bridgeTokens.contains(token)) revert CCTPTokenNotFound();
        _setTokenFee(token, relayerFee, minBaseFee, minSwapFee, maxFee);
    }

    /// @notice Sets a new protocol fee.
    /// @dev The protocol fee is a percentage of the relayer fee that is collected by the Protocol.
    /// @param newProtocolFee   New protocol fee, multiplied by `FEE_DENOMINATOR`
    function setProtocolFee(uint256 newProtocolFee) external onlyOwner {
        if (newProtocolFee > MAX_PROTOCOL_FEE) revert CCTPIncorrectProtocolFee();
        protocolFee = newProtocolFee;
        emit ProtocolFeeUpdated(newProtocolFee);
    }

    // ═══════════════════════════════════════════ RELAYER INTERACTIONS ════════════════════════════════════════════════

    /// @notice Allows the Relayer to set a fee collector for accumulated fees.
    /// - New fees accumulated by the Relayer could only be withdrawn by new Relayer's fee collector.
    /// - Old fees accumulated by the Relayer could only be withdrawn by old Relayer's fee collector.
    /// @dev Default value of address(0) indicates that a Relayer's fees are accumulated by the Protocol.
    function setFeeCollector(address feeCollector) external {
        address oldFeeCollector = relayerFeeCollectors[msg.sender];
        relayerFeeCollectors[msg.sender] = feeCollector;
        emit FeeCollectorUpdated(msg.sender, oldFeeCollector, feeCollector);
    }

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
    ) external view returns (uint256 fee) {
        return _calculateFeeAmount(token, amount, isSwap);
    }

    /// @notice Returns the list of all supported bridge tokens and their symbols.
    function getBridgeTokens() external view returns (BridgeToken[] memory bridgeTokens) {
        uint256 length = _bridgeTokens.length();
        bridgeTokens = new BridgeToken[](length);
        for (uint256 i = 0; i < length; i++) {
            address token = _bridgeTokens.at(i);
            bridgeTokens[i] = BridgeToken({symbol: tokenToSymbol[token], token: token});
        }
    }

    // ══════════════════════════════════════════════ INTERNAL LOGIC ═══════════════════════════════════════════════════

    /// @dev Applies the relayer fee and updates the accumulated fee amount for the token.
    /// Will revert if the fee exceeds the token amount, or token is not supported.
    function _applyRelayerFee(
        address token,
        uint256 amount,
        bool isSwap
    ) internal returns (uint256 amountAfterFee, uint256 fee) {
        if (!_bridgeTokens.contains(token)) revert CCTPTokenNotFound();
        fee = _calculateFeeAmount(token, amount, isSwap);
        if (fee >= amount) revert CCTPInsufficientAmount();
        // Could use the unchecked math, as we already checked that fee < amount
        unchecked {
            amountAfterFee = amount - fee;
        }
        // Check if the Relayer has specified a fee collector
        address feeCollector = relayerFeeCollectors[msg.sender];
        if (feeCollector == address(0)) {
            // If the fee collector is not set, the Protocol will collect the full fees
            accumulatedFees[address(0)][token] += fee;
            emit FeeCollected(address(0), 0, fee);
        } else {
            // Otherwise, the Relayer and the Protocol will split the fees
            uint256 protocolFeeAmount = (fee * protocolFee) / FEE_DENOMINATOR;
            uint256 relayerFeeAmount = fee - protocolFeeAmount;
            accumulatedFees[address(0)][token] += protocolFeeAmount;
            accumulatedFees[feeCollector][token] += relayerFeeAmount;
            emit FeeCollected(feeCollector, relayerFeeAmount, protocolFeeAmount);
        }
    }

    /// @dev Sets the fee structure for a supported Circle token.
    function _setTokenFee(
        address token,
        uint256 relayerFee,
        uint256 minBaseFee,
        uint256 minSwapFee,
        uint256 maxFee
    ) internal {
        // Check that relayer fee is not too high
        if (relayerFee > MAX_RELAYER_FEE) revert CCTPIncorrectConfig();
        // Min base fee must not exceed min swap fee
        if (minBaseFee > minSwapFee) revert CCTPIncorrectConfig();
        // Min swap fee must not exceed max fee
        if (minSwapFee > maxFee) revert CCTPIncorrectConfig();
        feeStructures[token] = CCTPFee({
            relayerFee: relayerFee.safeCastToUint40(),
            minBaseFee: minBaseFee.safeCastToUint72(),
            minSwapFee: minSwapFee.safeCastToUint72(),
            maxFee: maxFee.safeCastToUint72()
        });
    }

    // ══════════════════════════════════════════════ INTERNAL VIEWS ═══════════════════════════════════════════════════

    /// @dev Checks that the symbol hasn't been added yet and starts with "CCTP."
    function _assertCanAddSymbol(string memory symbol) internal view {
        // Check if the symbol has already been added
        if (symbolToToken[symbol] != address(0)) revert CCTPSymbolAlreadyAdded();
        // Cast to bytes to check the length
        bytes memory symbolBytes = bytes(symbol);
        // Check that symbol is correct: starts with "CCTP." and has at least 1 more character
        if (symbolBytes.length <= SYMBOL_PREFIX_LENGTH) revert CCTPSymbolIncorrect();
        for (uint256 i = 0; i < SYMBOL_PREFIX_LENGTH; ) {
            if (symbolBytes[i] != SYMBOL_PREFIX[i]) revert CCTPSymbolIncorrect();
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Calculates the fee amount for bridging a token to this chain using CCTP.
    /// Will not check if fee exceeds the token amount. Will return 0 if the token is not supported.
    function _calculateFeeAmount(
        address token,
        uint256 amount,
        bool isSwap
    ) internal view returns (uint256 fee) {
        CCTPFee memory feeStructure = feeStructures[token];
        // Calculate the fee amount
        fee = (amount * feeStructure.relayerFee) / FEE_DENOMINATOR;
        // Apply minimum fee
        uint256 minFee = isSwap ? feeStructure.minSwapFee : feeStructure.minBaseFee;
        if (fee < minFee) fee = minFee;
        // Apply maximum fee
        if (fee > feeStructure.maxFee) fee = feeStructure.maxFee;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// TODO: deprecate when LinkedPool PR is merged
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
pragma solidity 0.8.17;

interface IMessageTransmitter {
    /**
     * @notice Receives an incoming message, validating the header and passing
     * the body to application-specific handler.
     * @param message The message raw bytes
     * @param signature The message signature
     * @return success bool, true if successful
     */
    function receiveMessage(bytes calldata message, bytes calldata signature) external returns (bool success);

    /**
     * @notice Sends an outgoing message from the source domain, with a specified caller on the
     * destination domain.
     * @dev Increment nonce, format the message, and emit `MessageSent` event with message information.
     * WARNING: if the `destinationCaller` does not represent a valid address as bytes32, then it will not be possible
     * to broadcast the message on the destination domain. This is an advanced feature, and the standard
     * sendMessage() should be preferred for use cases where a specific destination caller is not required.
     * @param destinationDomain Domain of destination chain
     * @param recipient Address of message recipient on destination domain as bytes32
     * @param destinationCaller caller on the destination domain, as bytes32
     * @param messageBody Raw bytes content of message
     * @return nonce reserved by message
     */
    function sendMessageWithCaller(
        uint32 destinationDomain,
        bytes32 recipient,
        bytes32 destinationCaller,
        bytes calldata messageBody
    ) external returns (uint64);

    // ═══════════════════════════════════════════════════ VIEWS ═══════════════════════════════════════════════════════

    // Domain of chain on which the contract is deployed
    function localDomain() external view returns (uint32);

    // Next available nonce from this source domain
    function nextAvailableNonce() external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISynapseCCTP {
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
    /// @param message              Message raw bytes emitted by CCTP MessageTransmitter on origin chain
    /// @param signature            Circle's attestation for the message obtained from Circle's API
    /// @param requestVersion       Version of the request format
    /// @param formattedRequest     Formatted request for the action to take on this chain
    function receiveCircleToken(
        bytes calldata message,
        bytes calldata signature,
        uint32 requestVersion,
        bytes memory formattedRequest
    ) external;
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
/// | pool           | address | Liquidity pool for swapping Circle token on destination chain |
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
    uint256 internal constant SWAP_PARAMS_LENGTH = 5 * 32;
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
    /// @param pool                 Liquidity pool for swapping Circle token on destination chain
    /// @param tokenIndexFrom       Index of the minted Circle token in the pool
    /// @param tokenIndexTo         Index of the final token in the pool
    /// @param deadline             Latest timestamp to execute the swap
    /// @param minAmountOut         Minimum amount of tokens to receive from the swap
    /// @return formattedSwapParams Properly formatted swap parameters
    function formatSwapParams(
        address pool,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 deadline,
        uint256 minAmountOut
    ) internal pure returns (bytes memory formattedSwapParams) {
        return abi.encode(pool, tokenIndexFrom, tokenIndexTo, deadline, minAmountOut);
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
    /// @return pool                Liquidity pool for swapping Circle token on destination chain
    /// @return tokenIndexFrom      Index of the minted Circle token in the pool
    /// @return tokenIndexTo        Index of the final token in the pool
    /// @return deadline            Latest timestamp to execute the swap
    /// @return minAmountOut        Minimum amount of tokens to receive from the swap
    function decodeSwapParams(bytes memory swapParams)
        internal
        pure
        returns (
            address pool,
            uint8 tokenIndexFrom,
            uint8 tokenIndexTo,
            uint256 deadline,
            uint256 minAmountOut
        )
    {
        if (swapParams.length != SWAP_PARAMS_LENGTH) revert IncorrectRequestLength();
        return abi.decode(swapParams, (address, uint8, uint8, uint256, uint256));
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

import {ForwarderDeploymentFailed} from "./Errors.sol";
import {TypeCasts} from "./TypeCasts.sol";

import {Address} from "@openzeppelin/contracts-4.5.0/utils/Address.sol";

/// Minimal Forwarder is a EIP-1167 (Minimal Proxy Contract) spin-off that
/// forwards all calls to a any target address with any payload.
/// Unlike EIP-1167, delegates calls are not used, so the forwarder contract
/// is `msg.sender` as far as the target contract is concerned.
/// # Minimal Forwarder Bytecode
/// Inspired by [EIP-1167](https://eips.ethereum.org/EIPS/eip-1167).
/// Following changes were made:
/// - Target address is not saved in the deployed contract code, but is passed as a part of the payload.
/// - To forward a call, the sender needs to provide the target address as the first 32 bytes of the payload.
/// - The payload to pass to the target contract occupies the rest of the payload, having an offset of 32 bytes.
/// - The target address is derived using CALLDATALOAD.
/// - CALLVALUE is used to pass the msg.value to the target contract.
/// - `call()` is used instead of `delegatecall()`.
/// ## Bytecode Table
/// | Pos  | OP   | OP + Args | Description    | S7  | S6   | S5  | S4  | S3     | S2  | S1     | S0     |
/// | ---- | ---- | --------- | -------------- | --- | ---- | --- | --- | ------ | --- | ------ | ------ |
/// | 0x00 | 0x60 | 0x6020    | push1 0x20     |     |      |     |     |        |     |        | 32     |
/// | 0x02 | 0x36 | 0x36      | calldatasize   |     |      |     |     |        |     | cds    | 32     |
/// | 0x03 | 0x03 | 0x03      | sub            |     |      |     |     |        |     |        | cds-32 |
/// | 0x04 | 0x80 | 0x80      | dup1           |     |      |     |     |        |     | cds-32 | cds-32 |
/// | 0x05 | 0x60 | 0x6020    | push1 0x20     |     |      |     |     |        | 32  | cds-32 | cds-32 |
/// | 0x07 | 0x3d | 0x3d      | returndatasize |     |      |     |     | 0      | 32  | cds-32 | cds-32 |
/// | 0x08 | 0x37 | 0x37      | calldatacopy   |     |      |     |     |        |     |        | cds-32 |
/// | 0x09 | 0x3d | 0x3d      | returndatasize |     |      |     |     |        |     | 0      | cds-32 |
/// | 0x0a | 0x3d | 0x3d      | returndatasize |     |      |     |     |        | 0   | 0      | cds-32 |
/// | 0x0b | 0x3d | 0x3d      | returndatasize |     |      |     |     | 0      | 0   | 0      | cds-32 |
/// | 0x0c | 0x92 | 0x92      | swap3          |     |      |     |     | cds-32 | 0   | 0      | 0      |
/// | 0x0d | 0x3d | 0x3d      | returndatasize |     |      |     | 0   | cds-32 | 0   | 0      | 0      |
/// | 0x0e | 0x34 | 0x34      | callvalue      |     |      | val | 0   | cds-32 | 0   | 0      | 0      |
/// | 0x0f | 0x3d | 0x3d      | returndatasize |     | 0    | val | 0   | cds-32 | 0   | 0      | 0      |
/// | 0x10 | 0x35 | 0x35      | calldataload   |     | addr | val | 0   | cds-32 | 0   | 0      | 0      |
/// | 0x11 | 0x5a | 0x5a      | gas            | gas | addr | val | 0   | cds-32 | 0   | 0      | 0      |
/// | 0x12 | 0xf1 | 0xf1      | call           |     |      |     |     |        |     | suc    | 0      |
/// | 0x13 | 0x3d | 0x3d      | returndatasize |     |      |     |     |        | rds | suc    | 0      |
/// | 0x14 | 0x82 | 0x82      | dup3           |     |      |     |     | 0      | rds | suc    | 0      |
/// | 0x15 | 0x80 | 0x80      | dup1           |     |      |     | 0   | 0      | rds | suc    | 0      |
/// | 0x16 | 0x3e | 0x3e      | returndatacopy |     |      |     |     |        |     | suc    | 0      |
/// | 0x17 | 0x90 | 0x90      | swap1          |     |      |     |     |        |     | 0      | suc    |
/// | 0x18 | 0x3d | 0x3d      | returndatasize |     |      |     |     |        | rds | 0      | suc    |
/// | 0x19 | 0x91 | 0x91      | swap2          |     |      |     |     |        | suc | 0      | rds    |
/// | 0x1a | 0x60 | 0x601e    | push1 0x1e     |     |      |     |     | 0x1e   | suc | 0      | rds    |
/// | 0x1c | 0x57 | 0x57      | jumpi          |     |      |     |     |        |     | 0      | rds    |
/// | 0x1d | 0xfd | 0xfd      | revert         |     |      |     |     |        |     |        |        |
/// | 0x1e | 0x5b | 0x5b      | jumpdest       |     |      |     |     |        |     | 0      | rds    |
/// | 0x1f | 0xf3 | 0xf3      | return         |     |      |     |     |        |     |        |        |
/// > - Opcode + Args refers to the bytecode of the opcode and its arguments (if there are any).
/// > - Stack View (S7..S0) is shown after the execution of the opcode.
/// > - The stack elements are shown from top to bottom.
/// > Opcodes are typically dealing with the top stack elements, so they are shown first.
/// > - `cds` refers to the calldata size.
/// > - `rds` refers to the returndata size (which is zero before the first external call).
/// > - `val` refers to the provided `msg.value`.
/// > - `addr` refers to the target address loaded from calldata.
/// > - `gas` refers to the return value of the `gas()` opcode: the amount of gas left.
/// > - `suc` refers to the return value of the `call()` opcode: 0 on failure, 1 on success.
/// ## Bytecode Explanation
/// - `0x00..0x03` - Calculate the offset of the payload in the calldata (first 32 bytes is target address).
/// > - `sub` pops the top two stack items, subtracts them, and pushes the result onto the stack.
/// - `0x04..0x04` - Duplicate the offset to use it later as "payload length".
/// > - `dup1` duplicates the top stack item.
/// - `0x05..0x08` - Copy the target call payload to memory.
/// > - `calldatacopy` copies a portion of the calldata to memory. Pops three top stack elements:
/// > memory offset to write to, calldata offset to read from, and length of the data to copy.
/// - `0x09..0x11` - Prepare the stack for the `call` opcode.
/// > - We are putting an extra zero on the stack to use it later on, as `returndatacopy` will not return zero
/// > after we perform the first external call.
/// > - `swap3` swaps the top stack item with the fourth stack item.
/// > - `callvalue` pushes `msg.value` onto the stack.
/// > - `calldataload` pushes a word (32 bytes) onto the stack from calldata. Pops the calldata offset from the stack.
/// > Writes the word from calldata to the stack. We are using offset==0 to load the target address.
/// > - `gas` pushes the remaining gas onto the stack.
/// - `0x12..0x12` - Call the target contract.
/// > - `call` issues an external call to a target address.
/// > -  Pops seven top stack items: gas, target address, value, input offset, input length,
/// > memory offset to write return data to, and length of return data to write to memory.
/// > - Pushes on stack: 0 on failure, 1 on success.
/// - `0x13..0x16` - Copy the return data to memory.
/// > - `returndatasize` pushes the size of the returned data from the external call onto the stack.
/// > - `dup3` duplicates the third stack item.
/// > - `returncopydata` copies a portion of the returned data to memory. Pops three top stack elements:
/// > memory offset to write to, return data offset to read from, and length of the data to copy.
/// - `0x17..0x1b` - Prepare the stack for either revert or return: jump dst, success flag, zero, and return data size.
/// > - `swap1` swaps the top stack item with the second stack item.
/// > - `swap2` swaps the top stack item with the third stack item.
/// > - `0x1e` refers to the position of the `jumpdest` opcode.
/// >  It is used to jump to the `return` opcode, if call was successful.
/// - `0x1c..0x1c` - Jump to 0x1e position, if call was successful.
/// > - `jumpi` pops two top stack items: jump destination and jump condition.
/// > If jump condition is nonzero, jumps to the jump destination.
/// - `0x1d..0x1d` - Revert if call was unsuccessful.
/// > - `revert` pops two top stack items: memory offset to read revert message from and length of the revert message.
/// > - This allows us to bubble the revert message from the external call.
/// - `0x1e..0x1e` - Jump destination for successful call.
/// > - `jumpdest` is a no-op that marks a valid jump destination.
/// - `0x1f..0x1f` - Return if call was successful.
/// > - `return` pops two top stack items: memory offset to read return data from and length of the return data.
/// > - This allows us to reuse the return data from the external call.
/// # Minimal Forwarder Init Code
/// Inspired by [Create3 Init Code](https://github.com/0xSequence/create3/blob/master/contracts/Create3.sol).
/// Following changes were made:
/// - Adjusted bytecode length to 32 bytes.
/// - Replaced second PUSH1 opcode with RETURNDATASIZE to push 0 onto the stack.
/// > `bytecode` refers to the bytecode specified in the above table.
/// ## Init Code Table
/// | Pos  | OP   | OP + Args | Description     | S1  | S0       |
/// | ---- | ---- | --------- | --------------- | --- | -------- |
/// | 0x00 | 0x7f | 0x7fXXXX  | push32 bytecode |     | bytecode |
/// | 0x1b | 0x3d | 0x3d      | returndatasize  | 0   | bytecode |
/// | 0x1c | 0x52 | 0x52      | mstore          |     |          |
/// | 0x1d | 0x60 | 0x6020    | push1 0x20      |     | 32       |
/// | 0x1f | 0x3d | 0x3d      | returndatasize  | 0   | 32       |
/// | 0x20 | 0xf3 | 0xf3      | return          |     |          |
/// > Init Code is executed when a contract is deployed. The returned value is saved as the contract code.
/// > Therefore, the init code is constructed in such a way that it returns the Minimal Forwarder bytecode.
/// ## Init Code Explanation
/// - `0x00..0x1a` - Push the Minimal Forwarder bytecode onto the stack.
/// > - `push32` pushes 32 bytes as a single stack item onto the stack.
/// - `0x1b..0x1b` - Push 0 onto the stack.
/// > No external calls were made, so the return data size is 0.
/// - `0x1c..0x1c` - Write the Minimal Forwarder bytecode to memory.
/// > - `mstore` pops two top stack items: memory offset to write to and value to write.
/// > - Minimal Forwarder bytecode is 32 bytes long, so we need a single `mstore` to write it to memory.
/// - `0x1d..0x1f` - Prepare stack for `return` opcode.
/// > - We need to put `0 32` on the stack in order to return first 32 bytes of memory.
/// - `0x20..0x20` - Return the Minimal Forwarder bytecode.
/// > - `return` pops two top stack items: memory offset to read return data from and length of the return data.
/// > - This allows us to return the Minimal Forwarder bytecode.
library MinimalForwarderLib {
    using Address for address;
    using TypeCasts for address;
    using TypeCasts for bytes32;

    /// @notice Minimal Forwarder deployed bytecode. See the above table for more details.
    bytes internal constant FORWARDER_BYTECODE =
        hex"60_20_36_03_80_60_20_3d_37_3d_3d_3d_92_3d_34_3d_35_5a_f1_3d_82_80_3e_90_3d_91_60_1e_57_fd_5b_f3";

    /// @notice Init code to deploy a minimal forwarder contract.
    bytes internal constant FORWARDER_INIT_CODE = abi.encodePacked(hex"7f", FORWARDER_BYTECODE, hex"3d_52_60_20_3d_f3");

    /// @notice Hash of the minimal forwarder init code. Used to predict the address of a deployed forwarder.
    bytes32 internal constant FORWARDER_INIT_CODE_HASH = keccak256(FORWARDER_INIT_CODE);

    /// @notice Deploys a minimal forwarder contract using `CREATE2` with a given salt.
    /// @dev Will revert if the salt is already used.
    /// @param salt         The salt to use for the deployment
    /// @return forwarder   The address of the deployed minimal forwarder
    function deploy(bytes32 salt) internal returns (address forwarder) {
        // `bytes arr` is stored in memory in the following way
        // 1. First, uint256 arr.length is stored. That requires 32 bytes (0x20).
        // 2. Then, the array data is stored.
        bytes memory initCode = FORWARDER_INIT_CODE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Deploy the minimal forwarder with our pre-made bytecode via CREATE2.
            // We add 0x20 to get the location where the init code starts.
            forwarder := create2(0, add(initCode, 0x20), mload(initCode), salt)
        }
        // Deploy fails if the given salt is already used.
        if (forwarder == address(0)) {
            revert ForwarderDeploymentFailed();
        }
    }

    /// @notice Forwards a call to a target address using a minimal forwarder.
    /// @dev Will bubble up any revert messages from the target.
    /// @param forwarder    The address of the minimal forwarder to use
    /// @param target       The address of the target contract to call
    /// @param payload      The payload to pass to the target contract
    /// @return returnData  The return data from the target contract
    function forwardCall(
        address forwarder,
        address target,
        bytes memory payload
    ) internal returns (bytes memory returnData) {
        // Forward a call without any ETH value
        returnData = forwardCallWithValue(forwarder, target, payload, 0);
    }

    /// @notice Forwards a call to a target address using a minimal forwarder with the given `msg.value`.
    /// @dev Will bubble up any revert messages from the target.
    /// @param forwarder    The address of the minimal forwarder to use
    /// @param target       The address of the target contract to call
    /// @param payload      The payload to pass to the target contract
    /// @param value        The amount of ETH to send with the call
    /// @return returnData  The return data from the target contract
    function forwardCallWithValue(
        address forwarder,
        address target,
        bytes memory payload,
        uint256 value
    ) internal returns (bytes memory returnData) {
        // The payload to pass to the forwarder:
        // 1. First 32 bytes is the encoded target address
        // 2. The rest is the encoded payload to pass to the target
        returnData = forwarder.functionCallWithValue(abi.encodePacked(target.addressToBytes32(), payload), value);
    }

    /// @notice Predicts the address of a minimal forwarder contract deployed using `deploy()`.
    /// @param deployer     The address of the deployer of the minimal forwarder
    /// @param salt         The salt to use for the deployment
    /// @return The predicted address of the minimal forwarder deployed with the given salt
    function predictAddress(address deployer, bytes32 salt) internal pure returns (address) {
        return keccak256(abi.encodePacked(hex"ff", deployer, salt, FORWARDER_INIT_CODE_HASH)).bytes32ToAddress();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {CastOverflow} from "./Errors.sol";

library TypeCasts {
    // alignment preserving cast
    function addressToBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    // alignment preserving cast
    function bytes32ToAddress(bytes32 buf) internal pure returns (address) {
        return address(uint160(uint256(buf)));
    }

    /// @dev Casts uint256 to uint40, reverts on overflow
    function safeCastToUint40(uint256 value) internal pure returns (uint40) {
        if (value > type(uint40).max) {
            revert CastOverflow();
        }
        return uint40(value);
    }

    /// @dev Casts uint256 to uint72, reverts on overflow
    function safeCastToUint72(uint256 value) internal pure returns (uint72) {
        if (value > type(uint72).max) {
            revert CastOverflow();
        }
        return uint72(value);
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
pragma solidity 0.8.17;

abstract contract SynapseCCTPFeesEvents {
    /// @notice Emitted when the fee collector is updated for a relayer
    /// @param relayer          The relayer address
    /// @param oldFeeCollector  The old fee collector address: will be able to withdraw prior fees
    /// @param newFeeCollector  The new fee collector address: will be able to withdraw future fees
    event FeeCollectorUpdated(address indexed relayer, address oldFeeCollector, address newFeeCollector);

    /// @notice Emitted when the fee for relaying a CCTP message is collected
    /// @dev If fee collector address is not set, the full fee is collected for the protocol
    /// @param feeCollector      The fee collector address
    /// @param relayerFeeAmount  The amount of fees collected for the relayer
    /// @param protocolFeeAmount The amount of fees collected for the protocol
    event FeeCollected(address feeCollector, uint256 relayerFeeAmount, uint256 protocolFeeAmount);

    /// @notice Emitted when the protocol fee is updated
    /// @param newProtocolFee  The new protocol fee
    event ProtocolFeeUpdated(uint256 newProtocolFee);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// TODO: merge with ROuterV2 structs
struct BridgeToken {
    string symbol;
    address token;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
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