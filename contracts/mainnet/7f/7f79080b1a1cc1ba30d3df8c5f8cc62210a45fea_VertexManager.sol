// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {IERC20Metadata} from "openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {Math} from "openzeppelin/utils/math/Math.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";

import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";

import {IVertexManager} from "src/interfaces/IVertexManager.sol";
import {IEndpoint} from "src/interfaces/IEndpoint.sol";
import {IClearinghouse} from "src/interfaces/IClearinghouse.sol";

import {VertexProcessor} from "src/VertexProcessor.sol";
import {VertexStorage} from "src/VertexStorage.sol";
import {VertexRouter} from "src/VertexRouter.sol";

/// @title Elixir pool manager for Vertex
/// @author The Elixir Team
/// @custom:security-contact [email protected]
/// @notice Pool manager contract to provide liquidity for spot and perp market making on Vertex Protocol.
contract VertexManager is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuard, VertexStorage {
    using Math for uint256;
    using SafeERC20 for IERC20Metadata;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a perp withdrawal is queued.
    /// @param spot The spot added to the queue.
    /// @param queueCount The queue count.
    /// @param queueUpTo The queue up to.
    event Queued(Spot spot, uint128 queueCount, uint128 queueUpTo);

    /// @notice Emitted when a claim is made.
    /// @param user The user for which the tokens were claimed.
    /// @param token The token claimed.
    /// @param amount The token amount claimed.
    event Claim(address indexed user, address indexed token, uint256 indexed amount);

    /// @notice Emitted when the pause statuses are updated.
    /// @param depositPaused True if deposits are paused, false otherwise.
    /// @param withdrawPaused True if withdrawals are paused, false otherwise.
    /// @param claimPaused True if claims are paused, false otherwise.
    event PauseUpdated(bool indexed depositPaused, bool indexed withdrawPaused, bool indexed claimPaused);

    /// @notice Emitted when a pool is added.
    /// @param id The ID of the pool.
    /// @param poolType The type of the pool.
    /// @param router The router address of the pool.
    /// @param tokens The tokens of the pool.
    /// @param hardcaps The hardcaps of the pool.
    event PoolAdded(
        uint256 indexed id, PoolType poolType, address indexed router, address[] tokens, uint256[] hardcaps
    );

    /// @notice Emitted when tokens are added to a pool.
    /// @param id The ID of the pool.
    /// @param tokens The new tokens of the pool.
    /// @param hardcaps The hardcaps of the added tokens.
    event PoolTokensAdded(uint256 indexed id, address[] tokens, uint256[] hardcaps);

    /// @notice Emitted when a pool's hardcaps are updated.
    /// @param id The ID of the pool.
    /// @param hardcaps The new hardcaps of the pool.
    event PoolHardcapsUpdated(uint256 indexed id, uint256[] hardcaps);

    /// @notice Emitted when the Vertex product ID of a token is updated.
    /// @param token The token address.
    /// @param productId The new Vertex product ID of the token.
    event TokenUpdated(address indexed token, uint256 indexed productId);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the receiver is the zero address.
    error ZeroAddress();

    /// @notice Emitted when a token is duplicated.
    /// @param token The duplicated token.
    error DuplicatedToken(address token);

    /// @notice Emitted when a token is already supported.
    /// @param token The token address.
    /// @param id The ID of the pool.
    error AlreadySupported(address token, uint256 id);

    /// @notice Emitted when deposits are paused.
    error DepositsPaused();

    /// @notice Emitted when withdrawals are paused.
    error WithdrawalsPaused();

    /// @notice Emitted when claims are paused.
    error ClaimsPaused();

    /// @notice Emitted when the length of two arrays don't match.
    /// @param array1 The uint256 array input.
    /// @param array2 The address array input.
    error MismatchInputs(uint256[] array1, address[] array2);

    /// @notice Emitted when the pool is not valid or used in the incorrect function.
    /// @param id The ID of the pool.
    error InvalidPool(uint256 id);

    /// @notice Emitted when the token is not valid because it has more than 18 decimals.
    /// @param token The address of the token.
    error InvalidToken(address token);

    /// @notice Emitted when the amount given to withdraw is less than the fee to pay.
    /// @param amount The amount given to withdraw.
    /// @param fee The fee to pay.
    error AmountTooLow(uint256 amount, uint256 fee);

    /// @notice Emitted when the given spot ID to unqueue is not valid.
    error InvalidSpot(uint128 spotId, uint128 queueUpTo);

    /// @notice Emitted when the caller is not the external account of the pool's router.
    error NotExternalAccount(address router, address externalAccount, address caller);

    /// @notice Emitted when the msg.value of the call is too low for the fee.
    /// @param value The msg.value.
    /// @param fee The fee to pay.
    error FeeTooLow(uint256 value, uint256 fee);

    /// @notice Emitted when the fee transfer fails.
    error FeeTransferFailed();

    /// @notice Emitted when the price returned is zero.
    error ZeroPrice();

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Reverts when deposits are paused.
    modifier whenDepositNotPaused() {
        if (depositPaused) revert DepositsPaused();
        _;
    }

    /// @notice Reverts when withdrawals are paused.
    modifier whenWithdrawNotPaused() {
        if (withdrawPaused) revert WithdrawalsPaused();
        _;
    }

    /// @notice Reverts when claims are paused.
    modifier whenClaimNotPaused() {
        if (claimPaused) revert ClaimsPaused();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Prevent the implementation contract from being initialized.
    /// @dev The proxy contract state will still be able to call this function because the constructor does not affect the proxy state.
    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                               INITIALIZER
    //////////////////////////////////////////////////////////////*/

    /// @notice No constructor in upgradable contracts, so initialized with this function.
    /// @param _endpoint The address of the Vertex Endpoint contract.
    /// @param _processor The address of the VertexProcessor contract.
    /// @param _slowModeFee The fee to pay Vertex for slow mode transactions.
    function initialize(address _endpoint, address _processor, uint256 _slowModeFee) public initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();

        // Set Vertex's endpoint address.
        endpoint = IEndpoint(_endpoint);

        // Set the processor address.
        processor = _processor;

        // Set the slow mode fee.
        slowModeFee = _slowModeFee;

        // Set the quote token for slow-mode transactions through Vertex.
        quoteToken = IERC20Metadata(IClearinghouse(endpoint.clearinghouse()).getQuote());
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL ENTRY
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit a token into a perp pool.
    /// @param id The pool ID.
    /// @param token The token to deposit.
    /// @param amount The token amount to deposit.
    /// @param receiver The receiver of the virtual LP balance.
    function depositPerp(uint256 id, address token, uint256 amount, address receiver)
        external
        payable
        whenDepositNotPaused
        nonReentrant
    {
        // Fetch the pool storage.
        Pool storage pool = pools[id];

        // Check that the pool is perp.
        if (pool.poolType != PoolType.Perp) revert InvalidPool(id);

        // Check that the receiver is not the zero address.
        if (receiver == address(0)) revert ZeroAddress();

        // Take fee for unqueue transaction.
        takeElixirFee(pool.router);

        // Add to queue.
        queue[queueCount++] = Spot(
            msg.sender,
            pool.router,
            SpotType.DepositPerp,
            abi.encode(DepositPerp({id: id, token: token, amount: amount, receiver: receiver}))
        );

        emit Queued(queue[queueCount - 1], queueCount, queueUpTo);
    }

    /// @notice Deposits tokens into a spot pool.
    /// @dev Requests are placed into a FIFO queue, which is processed by the Elixir market-making network and passed on to Vertex via the `unqueue` function.
    /// @param id The ID of the pool to deposit.
    /// @param token0 The base token.
    /// @param token1 The quote token.
    /// @param amount0 The amount of base tokens.
    /// @param amount1Low The low limit of the quote token amount.
    /// @param amount1High The high limit of the quote token amount.
    /// @param receiver The receiver of the virtual LP balance.
    function depositSpot(
        uint256 id,
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1Low,
        uint256 amount1High,
        address receiver
    ) external payable whenDepositNotPaused nonReentrant {
        // Fetch the pool storage.
        Pool storage pool = pools[id];

        // Check that the pool is spot.
        if (pool.poolType != PoolType.Spot) revert InvalidPool(id);

        // Check that the tokens are not duplicated.
        if (token0 == token1) revert DuplicatedToken(token0);

        // Check that the receiver is not the zero address.
        if (receiver == address(0)) revert ZeroAddress();

        // Take fee for unqueue transaction.
        takeElixirFee(pool.router);

        // Add to queue.
        queue[queueCount++] = Spot(
            msg.sender,
            pool.router,
            SpotType.DepositSpot,
            abi.encode(
                DepositSpot({
                    id: id,
                    token0: token0,
                    token1: token1,
                    amount0: amount0,
                    amount1Low: amount1Low,
                    amount1High: amount1High,
                    receiver: receiver
                })
            )
        );

        emit Queued(queue[queueCount - 1], queueCount, queueUpTo);
    }

    /// @notice Requests to withdraw a token from a perp pool.
    /// @dev Requests are placed into a FIFO queue, which is processed by the Elixir market-making network and passed on to Vertex via the `unqueue` function.
    /// @dev After processed by Vertex, the user (or anyone on behalf of it) can call the `claim` function.
    /// @param id The ID of the pool to withdraw from.
    /// @param token The token to withdraw.
    /// @param amount The amount of token shares to withdraw.
    function withdrawPerp(uint256 id, address token, uint256 amount)
        external
        payable
        whenWithdrawNotPaused
        nonReentrant
    {
        // Fetch the pool storage.
        Pool storage pool = pools[id];

        // Check that the pool is perp.
        if (pool.poolType != PoolType.Perp) revert InvalidPool(id);

        // Check that the amount is at least the Vertex fee to pay.
        uint256 fee = getTransactionFee(token);

        if (amount < fee) revert AmountTooLow(amount, fee);

        // Take fee for unqueue transaction.
        takeElixirFee(pool.router);

        // Add to queue.
        queue[queueCount++] = Spot(
            msg.sender,
            pool.router,
            SpotType.WithdrawPerp,
            abi.encode(WithdrawPerp({id: id, token: token, amount: amount}))
        );

        emit Queued(queue[queueCount - 1], queueCount, queueUpTo);
    }

    /// @notice Withdraws tokens from a spot pool.
    /// @dev Requests are placed into a FIFO queue, which is processed by the Elixir market-making network and passed on to Vertex via the `unqueue` function.
    /// @param id The ID of the pool to withdraw from.
    /// @param token0 The base token.
    /// @param token1 The quote token.
    /// @param amount0 The amount of base tokens.
    function withdrawSpot(uint256 id, address token0, address token1, uint256 amount0)
        external
        payable
        whenWithdrawNotPaused
        nonReentrant
    {
        // Fetch the pool data.
        Pool storage pool = pools[id];

        // Check that the pool is spot.
        if (pool.poolType != PoolType.Spot) revert InvalidPool(id);

        // Check that the tokens are not duplicated.
        if (token0 == token1) revert DuplicatedToken(token0);

        // Take fee for unqueue transaction.
        takeElixirFee(pool.router);

        // Add to queue.
        queue[queueCount++] = Spot(
            msg.sender,
            pool.router,
            SpotType.WithdrawSpot,
            abi.encode(WithdrawSpot({id: id, token0: token0, token1: token1, amount0: amount0}))
        );

        emit Queued(queue[queueCount - 1], queueCount, queueUpTo);
    }

    /// @notice Claim received tokens from the pending balance and fees.
    /// @param user The address to claim for.
    /// @param token The token to claim.
    /// @param id The ID of the pool to claim from.
    function claim(address user, address token, uint256 id) external whenClaimNotPaused nonReentrant {
        // Fetch the pool data.
        Pool storage pool = pools[id];

        // Check that the pool exists.
        if (pool.router == address(0)) revert InvalidPool(id);

        // Check that the user is not the zero address.
        if (user == address(0)) revert ZeroAddress();

        // Fetch the pool router.
        VertexRouter router = VertexRouter(pool.router);

        // Establish empty token data.
        Token storage tokenData;

        // If token is the Clearinghouse quote token, point to the old quote token data.
        if (oldQuoteToken != address(0) && token == address(quoteToken)) {
            tokenData = pool.tokens[oldQuoteToken];
        } else {
            tokenData = pool.tokens[token];
        }

        // Get Elixir's pending fee balance.
        uint256 fee = tokenData.fees[user];

        // Calculate the user's claim amount.
        uint256 claim =
            Math.min(tokenData.userPendingAmount[user] + fee, IERC20Metadata(token).balanceOf(address(router)));

        // Resets the pending balance of the user.
        tokenData.userPendingAmount[user] -= claim - fee;

        // Resets the Elixir pending fee balance.
        tokenData.fees[user] -= fee;

        // Fetch the tokens from the router.
        router.claimToken(token, claim);

        // Transfers the tokens after to prevent reentrancy.
        IERC20Metadata(token).safeTransfer(owner(), fee);
        IERC20Metadata(token).safeTransfer(user, claim - fee);

        emit Claim(user, token, claim - fee);
    }

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the price on Vertex of a given by product.
    /// @param id The ID of the product to get the price of.
    function getPrice(uint32 id) public view returns (uint256 price) {
        // If id is 0 (quote), return default price.
        price = (id == 0) ? 1e18 : endpoint.getPriceX18(id);

        if (price == 0) revert ZeroPrice();
    }

    /// @notice Returns the data a pool and a token within it.
    /// @param id The ID of the pool supporting the token.
    /// @param token The token to fetch the data of.
    function getPoolToken(uint256 id, address token) external view returns (address, uint256, uint256, bool) {
        // Get the pool data.
        Pool storage pool = pools[id];

        // Establish empty token data.
        Token storage tokenData;

        // If token is the Clearinghouse quote token, point to the old quote token data.
        if (oldQuoteToken != address(0) && token == address(quoteToken)) {
            tokenData = pool.tokens[oldQuoteToken];
        } else {
            tokenData = pool.tokens[token];
        }

        return (pool.router, tokenData.activeAmount, tokenData.hardcap, tokenData.isActive);
    }

    /// @notice Returns the slow-mode fee for a given pool and token.
    /// @param token The token to fetch the fee from.
    function getTransactionFee(address token) public view returns (uint256) {
        return slowModeFee.mulDiv(
            10 ** (18 + IERC20Metadata(token).decimals() - quoteToken.decimals()),
            getPrice(tokenToProduct[token]),
            Math.Rounding.Up
        );
    }

    /// @notice Returns a user's active amount for a token within a pool.
    /// @param id The ID of the pool to fetch the active amounts of.
    /// @param token The token to fetch the active amounts of.
    /// @param user The user to fetch the active amounts of.
    function getUserActiveAmount(uint256 id, address token, address user) external view returns (uint256) {
        // If token is the Clearinghouse quote token, point to the old quote token.
        if (oldQuoteToken != address(0) && token == address(quoteToken)) {
            token = oldQuoteToken;
        }

        return pools[id].tokens[token].userActiveAmount[user];
    }

    /// @notice Returns a user's pending amount for a token within a pool.
    /// @param id The ID of the pool to fetch the pending amount of.
    /// @param token The token to fetch the pending amount of.
    /// @param user The user to fetch the pending amount of.
    function getUserPendingAmount(uint256 id, address token, address user) external view returns (uint256) {
        // If token is the Clearinghouse quote token, point to the old quote token.
        if (oldQuoteToken != address(0) && token == address(quoteToken)) {
            token = oldQuoteToken;
        }

        return pools[id].tokens[token].userPendingAmount[user];
    }

    /// @notice Returns a user's reimbursement fee for a token within a pool.
    /// @param id The ID of the pool to fetch the fee for.
    /// @param token The token to fetch the fee for.
    /// @param user The user to fetch the fee for.
    function getUserFee(uint256 id, address token, address user) external view returns (uint256) {
        // If token is the Clearinghouse quote token, point to the old quote token.
        if (oldQuoteToken != address(0) && token == address(quoteToken)) {
            token = oldQuoteToken;
        }

        return pools[id].tokens[token].fees[user];
    }

    /// @notice Returns the balanced amount of quote tokens given an amount of base tokens.
    /// @param token0 The base token.
    /// @param token1 The quote token.
    /// @param amount0 The amount of base tokens.
    function getBalancedAmount(address token0, address token1, uint256 amount0) external view returns (uint256) {
        return amount0.mulDiv(
            (getPrice(tokenToProduct[token0]) * (10 ** 18)) / getPrice(tokenToProduct[token1]),
            10 ** (18 + IERC20Metadata(token0).decimals() - IERC20Metadata(token1).decimals()),
            Math.Rounding.Down
        );
    }

    /// @notice Returns the calculated amount of tokens to receive when withdrawing, given an amount of tokens and the pool balance on Vertex.
    /// @param balance The Vertex balance of the pool.
    /// @param amount The amount of tokens withdrawing.
    /// @param activeAmount The active amount of tokens in the pool.
    function getWithdrawAmount(uint256 balance, uint256 amount, uint256 activeAmount) public pure returns (uint256) {
        // Calculate the amount to receive via percentage of ownership, accounting for any trading losses.
        return amount.mulDiv(balance, activeAmount, Math.Rounding.Down);
    }

    /// @notice Returns the external account of a pool router.
    function getExternalAccount(address router) private view returns (address) {
        return address(uint160(bytes20(VertexRouter(router).externalSubaccount())));
    }

    /// @notice Enforce the Elixir fee in native ETH.
    /// @param router The pool router.
    function takeElixirFee(address router) private {
        // Get the Elixir processing fee for unqueue transaction using WETH as token.
        // Safely assumes that WETH ID on Vertex is 3.
        uint256 fee = getTransactionFee(productToToken[3]);

        // Check that the msg.value is equal or more than the fee.
        if (msg.value < fee) revert FeeTooLow(msg.value, fee);

        // Transfer fee to the external account EOA.
        (bool sent,) = payable(getExternalAccount(router)).call{value: msg.value}("");
        if (!sent) revert FeeTransferFailed();
    }

    /// @notice Returns the next spot in the queue to process.
    function nextSpot() external view returns (Spot memory) {
        return queue[queueUpTo];
    }

    /*//////////////////////////////////////////////////////////////
                          PERMISSIONED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Processes the next spot in the withdraw perp queue.
    /// @param spotId The ID of the spot queue to process.
    /// @param response The response to the spot transaction.
    function unqueue(uint128 spotId, bytes memory response) external {
        // Get the spot data from the queue.
        Spot memory spot = queue[queueUpTo];

        // Get the external account of the router.
        address externalAccount = getExternalAccount(spot.router);

        // Check that the sender is the external account of the router.
        if (msg.sender != externalAccount) revert NotExternalAccount(spot.router, externalAccount, msg.sender);

        if (response.length != 0) {
            // Check that next spot in queue matches the given spot ID.
            if (spotId != queueUpTo + 1) revert InvalidSpot(spotId, queueUpTo);

            // Process spot. Skips if fail or revert.
            bytes memory processorCall =
                abi.encodeWithSelector(VertexProcessor.processSpot.selector, spot, response, address(this));
            processor.delegatecall(processorCall);
        } else {
            // Intetionally skip.
        }

        // Increase the queue up to.
        queueUpTo++;
    }

    /// @notice Manages the paused status of deposits, withdrawals, and claims
    /// @param _depositPaused True to pause deposits, false otherwise.
    /// @param _withdrawPaused True to pause withdrawals, false otherwise.
    /// @param _claimPaused True to pause claims, false otherwise.
    function pause(bool _depositPaused, bool _withdrawPaused, bool _claimPaused) external onlyOwner {
        depositPaused = _depositPaused;
        withdrawPaused = _withdrawPaused;
        claimPaused = _claimPaused;

        emit PauseUpdated(depositPaused, withdrawPaused, claimPaused);
    }

    /// @notice Adds a new pool.
    /// @param id The ID of the new pool.
    /// @param tokens The tokens to add.
    /// @param hardcaps The hardcaps for the tokens.
    /// @param poolType The type of the pool.
    /// @param externalAccount The external account to link to the Vertex Endpoint.
    function addPool(
        uint256 id,
        address[] calldata tokens,
        uint256[] calldata hardcaps,
        PoolType poolType,
        address externalAccount
    ) external onlyOwner {
        // Check that the pool doesn't exist.
        if (pools[id].router != address(0)) revert InvalidPool(id);

        // Deploy a new router contract.
        VertexRouter router = new VertexRouter(address(endpoint), externalAccount);

        // Approve the fee token to the router.
        router.makeApproval(address(quoteToken));

        // Create LinkSigner request for Vertex.
        IEndpoint.LinkSigner memory linkSigner =
            IEndpoint.LinkSigner(router.contractSubaccount(), router.externalSubaccount(), 0);

        // Fetch payment fee from owner. This can be reimbursed on withdrawals after tokens are received.
        quoteToken.safeTransferFrom(owner(), address(router), slowModeFee);

        // Submit slow-mode tx to Vertex.
        router.submitSlowModeTransaction(
            abi.encodePacked(uint8(IEndpoint.TransactionType.LinkSigner), abi.encode(linkSigner))
        );

        // Set the router address of the pool.
        pools[id].router = address(router);

        // Set the pool type.
        pools[id].poolType = poolType;

        // Add tokens to pool.
        addPoolTokens(id, tokens, hardcaps);

        emit PoolAdded(id, poolType, address(router), tokens, hardcaps);
    }

    /// @notice Adds new tokens to a pool.
    /// @param id The ID of the pool.
    /// @param tokens The tokens to add.
    /// @param hardcaps The hardcaps for the tokens.
    function addPoolTokens(uint256 id, address[] calldata tokens, uint256[] calldata hardcaps) public onlyOwner {
        // Fetch the pool router.
        VertexRouter router = VertexRouter(pools[id].router);

        // Loop over tokens to add.
        for (uint256 i = 0; i < tokens.length; i++) {
            // Get the token address.
            address token = tokens[i];

            // Check that the token decimals are below or equal to 18 decimals (Vertex maximum).
            if (IERC20Metadata(token).decimals() > 18) revert InvalidToken(token);

            // Fetch the token data storage within the pool.
            Token storage tokenData;

            // If token is the Clearinghouse quote token, point to the old quote token data.
            if (oldQuoteToken != address(0) && token == address(quoteToken)) {
                tokenData = pools[id].tokens[oldQuoteToken];
            } else {
                tokenData = pools[id].tokens[token];
            }

            // Check if the token is already supported, and enable if not.
            if (!tokenData.isActive) {
                tokenData.isActive = true;
            } else {
                revert AlreadySupported(token, id);
            }

            // Add the hardcap to the token data.
            tokenData.hardcap = hardcaps[i];

            // Make router approve tokens to Vertex endpoint.
            router.makeApproval(token);
        }

        emit PoolTokensAdded(id, tokens, hardcaps);
    }

    /// @notice Updates the hardcaps of a pool.
    /// @param id The ID of the pool.
    /// @param tokens The list of tokens to update the hardcaps of.
    /// @param hardcaps The hardcaps for the tokens.
    function updatePoolHardcaps(uint256 id, address[] calldata tokens, uint256[] calldata hardcaps)
        external
        onlyOwner
    {
        // Check that the length of the hardcaps array matches the pool tokens length.
        if (hardcaps.length != tokens.length) revert MismatchInputs(hardcaps, tokens);

        // Loop over hardcaps to update.
        for (uint256 i = 0; i < hardcaps.length; i++) {
            // Get the token.
            address token = tokens[i];

            // If token is the Clearinghouse quote token, point to the old quote token.
            if (oldQuoteToken != address(0) && token == address(quoteToken)) {
                token = oldQuoteToken;
            }

            pools[id].tokens[token].hardcap = hardcaps[i];
        }

        emit PoolHardcapsUpdated(id, hardcaps);
    }

    /// @notice Updates the Vertex product ID of a token address.
    /// @param token The token to update.
    /// @param productId The new Vertex product ID to represent this token.
    function updateToken(address token, uint32 productId) external onlyOwner {
        // Update the token to product ID and opposite direction mapping.
        tokenToProduct[token] = productId;
        productToToken[productId] = token;

        emit TokenUpdated(token, productId);
    }

    /// @notice Rescues any stuck tokens in the contract.
    /// @param token The token to rescue.
    /// @param amount The amount of token to rescue.
    function rescue(address token, uint256 amount) external onlyOwner {
        IERC20Metadata(token).safeTransfer(owner(), amount);
    }

    /// @notice Updates the Processor implementation address.
    /// @param _processor The new Processor implementation address.
    function updateProcessor(address _processor) external onlyOwner {
        processor = _processor;
    }

    /// @notice Update the quote token.
    /// @param _quoteToken The new quote token.
    function updateQuoteToken(address _quoteToken) external onlyOwner {
        oldQuoteToken = address(quoteToken);
        quoteToken = IERC20Metadata(_quoteToken);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Upgrades the implementation of the proxy to new address.
    function _authorizeUpgrade(address) internal override onlyOwner {}
}

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
        if (_initialized != type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface IVertexManager {
    /// @notice The types of spots supported by this contract.
    enum SpotType {
        Empty,
        DepositSpot,
        WithdrawPerp,
        WithdrawSpot,
        DepositPerp
    }

    /// @notice The structure for perp deposits to be processed by Elixir.
    struct DepositPerp {
        // The ID of the pool.
        uint256 id;
        // The token address.
        address token;
        // The amount of token to deposit.
        uint256 amount;
        // The receiver address.
        address receiver;
    }

    /// @notice The structure for spot deposits to be processed by Elixir.
    struct DepositSpot {
        // The ID of the pool.
        uint256 id;
        // The token0 address.
        address token0;
        // The token1 address.
        address token1;
        // The amount of token0 to deposit.
        uint256 amount0;
        // The low limit of token1 to deposit.
        uint256 amount1Low;
        // The high limit of token1 to deposit.
        uint256 amount1High;
        // The receiver of the virtual LP balance.
        address receiver;
    }

    /// @notice The structure of perp withdrawals to be processed by Elixir.
    struct WithdrawPerp {
        // The ID of the pool.
        uint256 id;
        // The token address.
        address token;
        // The amount of token shares to withdraw.
        uint256 amount;
    }

    /// @notice The structure of spot withdrawals to be processed by Elixir.
    struct WithdrawSpot {
        // The ID of the pool.
        uint256 id;
        // The token0 address.
        address token0;
        // The token1 address.
        address token1;
        // The amount of token0 shares to withdraw.
        uint256 amount0;
    }

    /// @notice The response structure for DepositSpot.
    struct DepositSpotResponse {
        // The amount of token1 to take from user.
        uint256 amount1;
        // The amount of token0 shares to add.
        uint256 token0Shares;
        // The amount of token1 shares to add.
        uint256 token1Shares;
    }

    /// @notice The response structure for DepositPerp.
    struct DepositPerpResponse {
        // The amount of shares to receive.
        uint256 shares;
    }

    /// @notice The response structure for WithdrawPerp.
    struct WithdrawPerpResponse {
        // The amount of of tokens the user should receive.
        uint256 amountToReceive;
    }

    /// @notice The response structure for WithdrawSpot.
    struct WithdrawSpotResponse {
        // The amount of token1 to use.
        uint256 amount1;
        // The amount of token0 the user should receive.
        uint256 amount0ToReceive;
        // The amount of token1 the user should receive.
        uint256 amount1ToReceive;
    }

    /// @notice The types of pools supported by this contract.
    enum PoolType {
        Inactive,
        Spot,
        Perp
    }

    /// @notice The data structure of pools.
    struct Pool {
        // The router address of the pool.
        address router;
        // The pool type. True for spot, false for perp.
        PoolType poolType;
        // The data of the supported tokens in the pool.
        mapping(address token => Token data) tokens;
    }

    /// @notice The data structure of tokens.
    struct Token {
        // The active market making balance of users for a token within a pool.
        mapping(address user => uint256 balance) userActiveAmount;
        // The pending amounts of users for a token within a pool.
        mapping(address user => uint256 amount) userPendingAmount;
        // The pending fees of a token within a pool.
        mapping(address user => uint256 amount) fees;
        // The total active amounts of a token within a pool.
        uint256 activeAmount;
        // The hardcap of the token within a pool.
        uint256 hardcap;
        // The status of the token within a pool. True if token is supported.
        bool isActive;
    }

    /// @notice The data structure of queue spots.
    struct Spot {
        // The sender of the request.
        address sender;
        // The router address of the pool.
        address router;
        // The type of request.
        SpotType spotType;
        // The transaction to process.
        bytes transaction;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {IClearinghouse} from "src/interfaces/IClearinghouse.sol";

interface IEndpoint {
    enum TransactionType {
        LiquidateSubaccount,
        DepositCollateral,
        WithdrawCollateral,
        SpotTick,
        UpdatePrice,
        SettlePnl,
        MatchOrders,
        DepositInsurance,
        ExecuteSlowMode,
        MintLp,
        BurnLp,
        SwapAMM,
        MatchOrderAMM,
        DumpFees,
        ClaimSequencerFees,
        PerpTick,
        ManualAssert,
        Rebate,
        UpdateProduct,
        LinkSigner,
        UpdateFeeRates
    }

    struct DepositCollateral {
        bytes32 sender;
        uint32 productId;
        uint128 amount;
    }

    struct WithdrawCollateral {
        bytes32 sender;
        uint32 productId;
        uint128 amount;
        uint64 nonce;
    }

    struct LinkSigner {
        bytes32 sender;
        bytes32 signer;
        uint64 nonce;
    }

    struct SlowModeTx {
        uint64 executableAt;
        address sender;
        bytes tx;
    }

    /// @notice Returns the Clearinghouse contract.
    function clearinghouse() external view returns (IClearinghouse);

    /// @notice Returns the slow-mode queue state.
    function getSlowModeTx(uint64 idx) external view returns (SlowModeTx memory, uint64, uint64);

    /// @notice Executes a submitted slow-mode transaction.
    function executeSlowModeTransaction() external;

    /// @notice Submits a slow-mode transaction to Vertex.
    function submitSlowModeTransaction(bytes calldata transaction) external;

    /// @notice Submits a deposit transaction to Vertex.
    function depositCollateralWithReferral(
        bytes12 subaccountName,
        uint32 productId,
        uint128 amount,
        string calldata referralCode
    ) external;

    /// @notice Returns a slow-mode transaction.
    function slowModeTxs(uint64 txId) external view returns (uint64 executableAt, address sender, bytes calldata tx);

    /// @notice Gets the price of a product.
    function getPriceX18(uint32 productId) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface IClearinghouse {
    /// @notice Retrieve quote ERC20 address.
    function getQuote() external view returns (address);

    /// @notice Retrieve the engine of a product.
    function getEngineByProduct(uint32 productId) external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {IERC20Metadata} from "openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {Math} from "openzeppelin/utils/math/Math.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";

import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";

import {IEndpoint} from "src/interfaces/IEndpoint.sol";
import {IClearinghouse} from "src/interfaces/IClearinghouse.sol";

import {VertexStorage} from "src/VertexStorage.sol";
import {VertexManager} from "src/VertexManager.sol";
import {VertexRouter} from "src/VertexRouter.sol";

/// @title Elixir pool processor for Vertex
/// @author The Elixir Team
/// @custom:security-contact [email protected]
/// @notice Back-end contract to process queue deposits and withdrawals. This contract is delegatecalled from VertexManager.
contract VertexProcessor is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuard, VertexStorage {
    using SafeERC20 for IERC20Metadata;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a deposit is made.
    /// @param router The router of the pool deposited to.
    /// @param caller The caller of the deposit function, for which tokens are taken from.
    /// @param receiver The receiver of the LP balance.
    /// @param id The ID of the pool deposting to.
    /// @param token The token deposited.
    /// @param amount The token amount deposited.
    /// @param shares The amount of shares received.
    event Deposit(
        address indexed router,
        address caller,
        address indexed receiver,
        uint256 indexed id,
        address token,
        uint256 amount,
        uint256 shares
    );

    /// @notice Emitted when a withdraw is made.
    /// @param router The router of the pool withdrawn from.
    /// @param user The user who withdrew.
    /// @param tokenId The Vertex product ID of the token withdrawn.
    /// @param amount The token amount the user receives.
    event Withdraw(address indexed router, address indexed user, uint32 tokenId, uint256 indexed amount);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a token is not supported for a pool.
    /// @param token The address of the unsupported token.
    /// @param id The ID of the pool.
    error UnsupportedToken(address token, uint256 id);

    /// @notice Emitted when the queue spot type is invalid.
    error InvalidSpotType(Spot spot);

    /// @notice Emitted when the slippage is too high.
    /// @param amount The amount of tokens given.
    /// @param amountLow The low limit of token amounts.
    /// @param amountHigh The high limit of token amounts.
    error SlippageTooHigh(uint256 amount, uint256 amountLow, uint256 amountHigh);

    /// @notice Emitted when the hardcap of a pool would be exceeded.
    /// @param token The token address being deposited.
    /// @param hardcap The hardcap of the pool given the token.
    /// @param activeAmount The active amount of tokens in the pool.
    /// @param amount The amount of tokens being deposited.
    error HardcapReached(address token, uint256 hardcap, uint256 activeAmount, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                    INTERNAL DEPOSIT/WITHDRAW LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Internal deposit logic for both spot and perp pools.
    /// @param caller The user who is depositing.
    /// @param id The id of the pool.
    /// @param pool The data of the pool to deposit.
    /// @param token The tokens to deposit.
    /// @param amount The amounts of token to deposit.
    /// @param receiver The receiver of the virtual LP balance.
    function _deposit(
        address caller,
        uint256 id,
        Pool storage pool,
        address token,
        uint256 amount,
        uint256 shares,
        address receiver
    ) private {
        // Establish empty token data.
        Token storage tokenData;

        // If token is the Clearinghouse quote token, point to the old quote token data.
        if (oldQuoteToken != address(0) && token == address(quoteToken)) {
            tokenData = pool.tokens[oldQuoteToken];
        } else {
            tokenData = pool.tokens[token];
        }

        // Check that the token is supported by the pool.
        if (!tokenData.isActive || token == oldQuoteToken) revert UnsupportedToken(token, id);

        // Check if the amount exceeds the token's pool hardcap.
        if (tokenData.activeAmount + shares > tokenData.hardcap) {
            revert HardcapReached(token, tokenData.hardcap, tokenData.activeAmount, shares);
        }

        // Fetch the router of the pool.
        VertexRouter router = VertexRouter(pool.router);

        // Transfer tokens from the caller to this contract.
        IERC20Metadata(token).safeTransferFrom(caller, address(router), amount);

        // Deposit funds to Vertex through router.
        router.submitSlowModeDeposit(tokenToProduct[token], uint128(amount), "9O7rUEUljP");

        // Add amount to the active market making balance of the user.
        tokenData.userActiveAmount[receiver] += shares;

        // Add amount to the active pool market making balance.
        tokenData.activeAmount += shares;

        emit Deposit(address(router), caller, receiver, id, token, amount, shares);
    }

    /// @notice Internal withdraw logic for both spot and perp pools.
    /// @param caller The user who is withdrawing.
    /// @param pool The data of the pool to withdraw from.
    /// @param token The token to withdraw.
    /// @param amount The amount of token to substract from active balances.
    /// @param fee The fee to pay.
    /// @param amountToReceive The amount of tokens the user receives.
    function _withdraw(
        address caller,
        Pool storage pool,
        address token,
        uint256 amount,
        uint256 fee,
        uint256 amountToReceive
    ) private {
        // Establish empty token data.
        Token storage tokenData;

        // If token is the Clearinghouse quote token, point to the old quote token data.
        if (oldQuoteToken != address(0) && token == address(quoteToken)) {
            tokenData = pool.tokens[oldQuoteToken];
        } else {
            tokenData = pool.tokens[token];
        }

        // Substract amount from the active market making balance of the caller.
        tokenData.userActiveAmount[caller] -= amount;

        // Substract amount from the active pool market making balance.
        tokenData.activeAmount -= amount;

        // Add fee to the Elixir balance.
        tokenData.fees[caller] += fee;

        // Update the user pending balance.
        tokenData.userPendingAmount[caller] += (amountToReceive - fee);

        // Create Vertex withdraw payload request.
        IEndpoint.WithdrawCollateral memory withdrawPayload = IEndpoint.WithdrawCollateral(
            VertexRouter(pool.router).contractSubaccount(), tokenToProduct[token], uint128(amountToReceive), 0
        );

        // Fetch payment fee from owner. This can be reimbursed on withdrawals after tokens are received.
        quoteToken.safeTransferFrom(owner(), pool.router, slowModeFee);

        // Submit Withdraw slow-mode tx to Vertex.
        VertexRouter(pool.router).submitSlowModeTransaction(
            abi.encodePacked(uint8(IEndpoint.TransactionType.WithdrawCollateral), abi.encode(withdrawPayload))
        );

        emit Withdraw(pool.router, caller, tokenToProduct[token], amountToReceive);
    }

    /// @notice Processes a spot transaction given a response.
    /// @param spot The spot to process.
    /// @param response The response for the spot in queue.
    /// @param manager The VertexManager contract calling this function.
    function processSpot(Spot calldata spot, bytes memory response, VertexManager manager) public {
        if (spot.spotType == SpotType.DepositSpot) {
            DepositSpot memory spotTxn = abi.decode(spot.transaction, (DepositSpot));

            DepositSpotResponse memory responseTxn = abi.decode(response, (DepositSpotResponse));

            // Check for slippage based on the needed amount1.
            if (responseTxn.amount1 < spotTxn.amount1Low || responseTxn.amount1 > spotTxn.amount1High) {
                revert SlippageTooHigh(responseTxn.amount1, spotTxn.amount1Low, spotTxn.amount1High);
            }

            // Execute deposit logic for token0.
            _deposit(
                spot.sender,
                spotTxn.id,
                pools[spotTxn.id],
                spotTxn.token0,
                spotTxn.amount0,
                responseTxn.token0Shares,
                spotTxn.receiver
            );

            // Execute deposit logic for token1.
            _deposit(
                spot.sender,
                spotTxn.id,
                pools[spotTxn.id],
                spotTxn.token1,
                responseTxn.amount1,
                responseTxn.token1Shares,
                spotTxn.receiver
            );
        } else if (spot.spotType == SpotType.DepositPerp) {
            DepositPerp memory spotTxn = abi.decode(spot.transaction, (DepositPerp));

            DepositPerpResponse memory responseTxn = abi.decode(response, (DepositPerpResponse));

            // Execute the deposit logic.
            _deposit(
                spot.sender,
                spotTxn.id,
                pools[spotTxn.id],
                spotTxn.token,
                spotTxn.amount,
                responseTxn.shares,
                spotTxn.receiver
            );
        } else if (spot.spotType == SpotType.WithdrawPerp) {
            WithdrawPerp memory spotTxn = abi.decode(spot.transaction, (WithdrawPerp));

            WithdrawPerpResponse memory responseTxn = abi.decode(response, (WithdrawPerpResponse));

            // Execute the withdraw logic.
            _withdraw(
                spot.sender,
                pools[spotTxn.id],
                spotTxn.token,
                spotTxn.amount,
                manager.getTransactionFee(spotTxn.token),
                responseTxn.amountToReceive
            );
        } else if (spot.spotType == SpotType.WithdrawSpot) {
            WithdrawSpot memory spotTxn = abi.decode(spot.transaction, (WithdrawSpot));

            WithdrawSpotResponse memory responseTxn = abi.decode(response, (WithdrawSpotResponse));

            // Execute the withdraw logic for token0.
            _withdraw(
                spot.sender,
                pools[spotTxn.id],
                spotTxn.token0,
                spotTxn.amount0,
                manager.getTransactionFee(spotTxn.token0),
                responseTxn.amount0ToReceive
            );
            // Execute the withdraw logic for token1.
            _withdraw(
                spot.sender,
                pools[spotTxn.id],
                spotTxn.token1,
                responseTxn.amount1,
                manager.getTransactionFee(spotTxn.token1),
                responseTxn.amount1ToReceive
            );
        } else {
            revert InvalidSpotType(spot);
        }
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Upgrades the implementation of the proxy to new address.
    function _authorizeUpgrade(address) internal override onlyOwner {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {IERC20Metadata} from "openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";

import {IEndpoint} from "src/interfaces/IEndpoint.sol";
import {IVertexManager} from "src/interfaces/IVertexManager.sol";

/// @title Elixir storage for Vertex
/// @author The Elixir Team
/// @custom:security-contact [email protected]
/// @notice Back-end contract with storage variables.
abstract contract VertexStorage is IVertexManager {
    /// @notice The pools managed given an ID.
    mapping(uint256 id => Pool pool) public pools;

    /// @notice The Vertex product IDs of token addresses.
    mapping(address token => uint32 id) public tokenToProduct;

    /// @notice The token addresses of Vertex product IDs.
    mapping(uint32 id => address token) public productToToken;

    /// @notice The queue for Elixir to process.
    mapping(uint128 => Spot) public queue;

    /// @notice The queue count.
    uint128 public queueCount;

    /// @notice The queue up to.
    uint128 public queueUpTo;

    /// @notice The Vertex slow mode fee.
    uint256 public slowModeFee = 1000000;

    /// @notice Vertex's Endpoint contract.
    IEndpoint public endpoint;

    /// @notice Fee payment token for slow mode transactions through Vertex.
    IERC20Metadata public quoteToken;

    /// @notice The pause status of deposits. True if deposits are paused.
    bool public depositPaused;

    /// @notice The pause status of withdrawals. True if withdrawals are paused.
    bool public withdrawPaused;

    /// @notice The pause status of claims. True if claims are paused.
    bool public claimPaused;

    /// @notice Old quote token of Vertex.
    address internal oldQuoteToken;

    /// @notice The smart contract to off-load processing logic.
    address internal processor;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {IERC20Metadata} from "openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import {IEndpoint} from "src/interfaces/IEndpoint.sol";

/// @title Elixir pool router for Vertex
/// @author The Elixir Team
/// @custom:security-contact [email protected]
/// @dev This contract is needed because an address can only have one Vertex linked signer at a time,
/// which is incompatible with the VertexManager singleton approach.
/// @notice Pool router contract to send slow-mode transactions to Vertex.
contract VertexRouter {
    using SafeERC20 for IERC20Metadata;

    /*//////////////////////////////////////////////////////////////
                                VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Vertex's Endpoint contract.
    IEndpoint public immutable endpoint;

    /// @notice Bytes of this contract's subaccount.
    bytes32 public immutable contractSubaccount;

    /// @notice Bytes of the external account's subaccount.
    bytes32 public immutable externalSubaccount;

    /// @notice The Manager contract associated with this Router.
    address public immutable manager;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Reverts when the sender is not the manager.
    error NotManager();

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Reverts when the sender is not the manager.
    modifier onlyManager() {
        if (msg.sender != manager) revert NotManager();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Set the manager, Vertex Endpoint, and subaccounts.
    /// @param _endpoint The address of the Vertex Endpoint contract.
    /// @param _externalAccount The address of the external account to link to the Vertex Endpoint.
    constructor(address _endpoint, address _externalAccount) {
        // Set the Manager as the owner.
        manager = msg.sender;

        // Set Vertex's endpoint address.
        endpoint = IEndpoint(_endpoint);

        // Store this contract's internal and external subaccount.
        contractSubaccount = bytes32(uint256(uint160(address(this))) << 96);
        externalSubaccount = bytes32(uint256(uint160(_externalAccount)) << 96);
    }

    /*//////////////////////////////////////////////////////////////
                        VERTEX SLOW TRANSACTION
    //////////////////////////////////////////////////////////////*/

    /// @notice Submits a slow mode transaction to Vertex.
    /// @dev More information about slow mode transactions:
    /// https://vertex-protocol.gitbook.io/docs/developer-resources/api/withdrawing-on-chain
    /// @param transaction The transaction to submit.
    function submitSlowModeTransaction(bytes memory transaction) external onlyManager {
        endpoint.submitSlowModeTransaction(transaction);
    }

    /// @notice Sends a deposit to Vertex.
    /// @dev By calling this function, the sender and msg.sender are the same.
    /// @param productId The Vertex product ID.
    /// @param amount The amount to deposit.
    /// @param referral The Vertex referral code to use for this deposit.
    function submitSlowModeDeposit(uint32 productId, uint128 amount, string calldata referral) external onlyManager {
        // Send deposit with the last 12 bytes of this router subaccount. Shift left 160 bits, leaving 96 bits i.e. 12 bytes.
        endpoint.depositCollateralWithReferral(bytes12(contractSubaccount << 160), productId, amount, referral);
    }

    /*//////////////////////////////////////////////////////////////
                             TOKEN TRANSFER
    //////////////////////////////////////////////////////////////*/

    /// @notice Approves Vertex to transfer a token.
    /// @param token The token to approve.
    function makeApproval(address token) external onlyManager {
        // Approve the token transfer.
        IERC20Metadata(token).approve(address(endpoint), type(uint256).max);
    }

    /// @notice Allow claims from VertexManager contract.
    /// @param token The token to transfer.
    /// @param amount The amount to transfer.
    function claimToken(address token, uint256 amount) external onlyManager {
        // Transfer the token to the manager.
        IERC20Metadata(token).safeTransfer(manager, amount);
    }
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/IERC1967Upgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}