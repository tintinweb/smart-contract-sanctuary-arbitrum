// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {TokenAuthorizer} from "@src/TokenAuthorizer.sol";

import {Enum} from "@safe-contracts/common/Enum.sol";
import {ISafe} from "@src/interfaces/ISafe.sol";
import {ISwapRouter} from "@src/interfaces/ISwapRouter.sol";
import {INonfungiblePositionManager} from "@src/interfaces/INonfungiblePositionManager.sol";
import {IVaultFactory} from "@src/interfaces/IVaultFactory.sol";
import {IERC20} from "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin-contracts/token/ERC721/IERC721.sol";
import {IMultiSend} from "@src/interfaces/IMultiSend.sol";
import {ITradingModule} from "@src/interfaces/ITradingModule.sol";
import {IPool} from "@src/interfaces/IPool.sol";

contract TradingModule is ITradingModule, TokenAuthorizer {
    enum Caller {
        NONE,
        VAULT,
        OPERATOR
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyOperator() {
        if (!isOperator(msg.sender)) revert NotOperator();
        _;
    }

    modifier notPaused() {
        if (paused) revert ModulePaused();
        _;
    }

    ISwapRouter public immutable uniswapV3Router;
    INonfungiblePositionManager public immutable uniswapV3PositionManager;
    IPool public immutable aavePool;
    IVaultFactory public immutable vaultFactory;
    IMultiSend public immutable multiSend;

    mapping(address caller => bool authorized) private operators;
    address public immutable owner;
    bool public paused;

    constructor(
        address _owner,
        address _vaultFactory,
        address _multiSend,
        address _uniswapV3Router,
        address _uniswapV3PositionManager,
        address _aavePool,
        address[] memory _authorizedTokens
    ) TokenAuthorizer(_authorizedTokens) {
        vaultFactory = IVaultFactory(_vaultFactory);
        uniswapV3Router = ISwapRouter(_uniswapV3Router);
        uniswapV3PositionManager = INonfungiblePositionManager(_uniswapV3PositionManager);
        aavePool = IPool(_aavePool);
        multiSend = IMultiSend(_multiSend);
        owner = _owner;
    }

    function multicall(address vault, bytes memory transactions) public notPaused onlyOperator {
        // make sure we are calling DAMM vault
        _checkIsDAMMVault(vault);

        // the parsing code is taken from MultiSend.sol
        // the reverts are DAMM specific
        assembly {
            let length := mload(transactions)
            let i := 0x20
            for {
                // Pre block is not used in "while mode"
            } lt(i, length) {
                // Post block is not used in "while mode"
            } {
                // First byte of the data is the operation.
                // We shift by 248 bits (256 - 8 [operation byte]) it right since mload will always load 32 bytes (a word).
                // This will also zero out unused data.
                let operation := shr(0xf8, mload(add(transactions, i)))

                // we do not allow delegate calls
                if eq(operation, 1) { revert(0, 0) }

                // We offset the load address by 1 byte (operation byte)
                // We shift it right by 96 bits (256 - 160 [20 address bytes]) to right-align the data and zero out unused data.
                let to := shr(0x60, mload(add(transactions, add(i, 0x01))))

                // only allow calls from vault to this module
                if iszero(eq(to, address())) { revert(0, 0) }

                // We offset the load address by 21 byte (operation byte + 20 address bytes)
                let value := mload(add(transactions, add(i, 0x15)))
                // We offset the load address by 53 byte (operation byte + 20 address bytes + 32 value bytes)
                let dataLength := mload(add(transactions, add(i, 0x35)))

                // data length must be greater than 0
                if iszero(dataLength) { revert(0, 0) }

                // We offset the load address by 85 byte (operation byte + 20 address bytes + 32 value bytes + 32 data length bytes)
                let data := add(transactions, add(i, 0x55))

                // Directly load the first 4 bytes of data (the function selector)
                let selector := shr(224, mload(data))

                switch selector
                case 0x847a2675 {
                    // mintv3Position
                }
                case 0x6d79ecd8 {
                    // swapTokenWithV3
                }
                case 0x857449b8 { // increaseV3PositionLiquidity
                        // do nothing
                }
                case 0xfc91a99e { // decreaseV3PositionLiquidity
                        // do nothing
                }
                case 0x051d4102 { // burnV3Position
                        // do nothing
                }
                case 0xfbfd7958 {
                    // collectV3TokensOwed
                }
                case 0x71245ac0 {
                    // approveRouterAllowance
                }
                case 0xc62c6348 {
                    // approvePositionManagerAllowance
                }
                case 0x7800a52b {
                    // supplyAAVE
                }
                case 0x0712a079 {
                    // withdrawAAVE
                }
                case 0x497cc305 {
                    // approveAAVEPoolAllowance
                }
                default { revert(0, 0) } // selector must match one of the functions above, otherwise revert

                // Next entry starts at 85 byte + data length
                i := add(i, add(0x55, dataLength))
            }
        }

        bytes memory payload = abi.encodeWithSelector(IMultiSend.multiSend.selector, transactions);

        // @dev msg.sender will be the vault for multisend calls
        bool success =
            ISafe(vault).execTransactionFromModule(address(multiSend), 0, payload, Enum.Operation.DelegateCall);

        // check if safe transaction was successful
        if (!success) revert MulticallFailed();
    }

    // @dev caller should be operator for single calls and vault for multicalls.
    function _caller() internal view returns (Caller) {
        if (isOperator(msg.sender)) return Caller.OPERATOR;
        if (_isDAMMVault(msg.sender)) return Caller.VAULT;

        revert InvalidCaller();
    }

    function mintV3Position(INonfungiblePositionManager.MintParams calldata params) public notPaused {
        Caller caller = _caller();

        // recipient must always be the vault
        _checkIsDAMMVault(params.recipient);

        // vaults can only mint for themselves
        if (caller == Caller.VAULT && params.recipient != msg.sender) revert InvalidCaller();

        // token0 and token1 must be different
        if (params.token0 == params.token1) revert SameToken();

        // Only authorized tokens can be swapped by operators
        checkIsAuthorizedToken(params.token0);
        checkIsAuthorizedToken(params.token1);

        bytes memory mintCall = abi.encodeWithSelector(INonfungiblePositionManager.mint.selector, params);

        // call on behalf of vault
        bool success = ISafe(params.recipient).execTransactionFromModule(
            address(uniswapV3PositionManager), 0, mintCall, Enum.Operation.Call
        );

        // check if safe transaction was successful
        if (!success) revert MintFailed();
    }

    function burnV3Position(uint256 tokenId) public notPaused {
        Caller caller = _caller();

        // fetch position owner
        address tokenOwner = IERC721(address(uniswapV3PositionManager)).ownerOf(tokenId);

        // holder must be DAMM vault
        _checkIsDAMMVault(tokenOwner);

        // vaults can only burn for themselves
        if (caller == Caller.VAULT && tokenOwner != msg.sender) revert InvalidCaller();

        // get the position information
        (,, address token0, address token1,,,,,,,,) = uniswapV3PositionManager.positions(tokenId);

        // Only positions composed of authorized tokens can be increased by operators
        checkIsAuthorizedToken(token0);
        checkIsAuthorizedToken(token1);

        bytes memory burnCall = abi.encodeWithSelector(INonfungiblePositionManager.burn.selector, tokenId);

        // call on behalf of vault
        bool success = ISafe(tokenOwner).execTransactionFromModule(
            address(uniswapV3PositionManager), 0, burnCall, Enum.Operation.Call
        );

        // check if safe transaction was successful
        if (!success) revert BurnFailed();
    }

    function swapTokenWithV3(ISwapRouter.ExactInputSingleParams calldata params) public notPaused {
        Caller caller = _caller();

        // recipient must always be the vault
        _checkIsDAMMVault(params.recipient);

        // vaults can only swap for themselves
        if (caller == Caller.VAULT && params.recipient != msg.sender) revert InvalidCaller();

        // tokenIn and tokenOut must be different
        if (params.tokenIn == params.tokenOut) revert SameToken();

        // Only authorized tokens can be swapped by operators
        checkIsAuthorizedToken(params.tokenIn);
        checkIsAuthorizedToken(params.tokenOut);

        bytes memory swapCall = abi.encodeWithSelector(ISwapRouter.exactInputSingle.selector, params);

        // call on behalf of vault
        bool success = ISafe(params.recipient).execTransactionFromModule(
            address(uniswapV3Router), 0, swapCall, Enum.Operation.Call
        );

        // check if safe transaction was successful
        if (!success) revert SwapFailed();
    }

    function collectV3TokensOwed(INonfungiblePositionManager.CollectParams calldata params) public notPaused {
        Caller caller = _caller();

        // fetch position owner
        address tokenOwner = IERC721(address(uniswapV3PositionManager)).ownerOf(params.tokenId);

        // holder must be DAMM vault
        _checkIsDAMMVault(tokenOwner);

        // vaults can only collect for themselves
        if (caller == Caller.VAULT && tokenOwner != msg.sender) revert InvalidCaller();

        // get the position information
        (,, address token0, address token1,,,,,,,,) = uniswapV3PositionManager.positions(params.tokenId);

        // Only positions composed of authorized tokens can be increased by operators
        checkIsAuthorizedToken(token0);
        checkIsAuthorizedToken(token1);

        bytes memory collectFeesCall = abi.encodeWithSelector(INonfungiblePositionManager.collect.selector, params);

        // call on behalf of vault
        bool success = ISafe(tokenOwner).execTransactionFromModule(
            address(uniswapV3PositionManager), 0, collectFeesCall, Enum.Operation.Call
        );

        // check if safe transaction was successful
        if (!success) revert CollectFeesFailed();
    }

    function increaseV3PositionLiquidity(INonfungiblePositionManager.IncreaseLiquidityParams calldata params)
        public
        notPaused
    {
        Caller caller = _caller();

        // fetch position owner
        address tokenOwner = IERC721(address(uniswapV3PositionManager)).ownerOf(params.tokenId);

        // holder must be DAMM vault
        _checkIsDAMMVault(tokenOwner);

        // vaults can only increase liquidity for themselves
        if (caller == Caller.VAULT && tokenOwner != msg.sender) revert InvalidCaller();

        // get the position information
        (,, address token0, address token1,,,,,,,,) = uniswapV3PositionManager.positions(params.tokenId);

        // Only positions composed of authorized tokens can be increased by operators
        checkIsAuthorizedToken(token0);
        checkIsAuthorizedToken(token1);

        bytes memory increaseLiquidityCall =
            abi.encodeWithSelector(INonfungiblePositionManager.increaseLiquidity.selector, params);

        // call on behalf of vault
        bool success = ISafe(tokenOwner).execTransactionFromModule(
            address(uniswapV3PositionManager), 0, increaseLiquidityCall, Enum.Operation.Call
        );

        // check if safe transaction was successful
        if (!success) revert IncreaseLiquidityFailed();
    }

    function decreaseV3PositionLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams calldata params)
        public
        notPaused
    {
        Caller caller = _caller();

        // fetch position owner
        address tokenOwner = IERC721(address(uniswapV3PositionManager)).ownerOf(params.tokenId);

        // holder must be DAMM vault
        _checkIsDAMMVault(tokenOwner);

        // vaults can only decrease liquidity for themselves
        if (caller == Caller.VAULT && tokenOwner != msg.sender) revert InvalidCaller();

        // get the position information
        (,, address token0, address token1,,,,,,,,) = uniswapV3PositionManager.positions(params.tokenId);

        // Only positions composed of authorized tokens can be increased by operators
        checkIsAuthorizedToken(token0);
        checkIsAuthorizedToken(token1);

        bytes memory decreaseLiquidityCall =
            abi.encodeWithSelector(INonfungiblePositionManager.decreaseLiquidity.selector, params);

        // call on behalf of vault
        bool success = ISafe(tokenOwner).execTransactionFromModule(
            address(uniswapV3PositionManager), 0, decreaseLiquidityCall, Enum.Operation.Call
        );

        // check if safe transaction was successful
        if (!success) revert DecreaseLiquidityFailed();
    }

    function _approveERC20Allowance(address vault, address operator, address token, uint256 amount) internal {
        Caller caller = _caller();

        // Only authorized tokens can be approved by operators
        checkIsAuthorizedToken(token);

        _checkIsDAMMVault(vault);

        // vaults can only approve for themselves
        if (caller == Caller.VAULT && vault != msg.sender) revert InvalidCaller();

        bytes memory approveCall = abi.encodeWithSelector(IERC20.approve.selector, operator, amount);

        // call on behalf of vault
        bool success = ISafe(vault).execTransactionFromModule(address(token), 0, approveCall, Enum.Operation.Call);

        // check if approve was successful
        if (!success) revert ApproveFailed();
    }

    function approveRouterAllowance(address vault, address token, uint256 amount) public notPaused {
        _approveERC20Allowance(vault, address(uniswapV3Router), token, amount);
    }

    function approvePositionManagerAllowance(address vault, address token, uint256 amount) public notPaused {
        _approveERC20Allowance(vault, address(uniswapV3PositionManager), token, amount);
    }

    function approveAAVEPoolAllowance(address vault, address token, uint256 amount) public notPaused {
        _approveERC20Allowance(vault, address(aavePool), token, amount);
    }

    function supplyAAVE(address asset, uint256 amount, address onBehalfOf) public notPaused {
        Caller caller = _caller();

        // Only authorized tokens can be supplied by operators
        checkIsAuthorizedToken(asset);

        _checkIsDAMMVault(onBehalfOf);

        // vaults can only supply for themselves
        if (caller == Caller.VAULT && onBehalfOf != msg.sender) revert InvalidCaller();

        bytes memory supplyCall = abi.encodeWithSelector(IPool.supply.selector, asset, amount, onBehalfOf, 0);

        // call on behalf of vault
        bool success =
            ISafe(onBehalfOf).execTransactionFromModule(address(aavePool), 0, supplyCall, Enum.Operation.Call);

        // check if safe transaction was successful
        if (!success) revert SupplyAAVEFailed();
    }

    function withdrawAAVE(address asset, uint256 amount, address to) public notPaused {
        Caller caller = _caller();

        // Only authorized tokens can be withdrawn by operators
        checkIsAuthorizedToken(asset);

        _checkIsDAMMVault(to);

        // vaults can only withdraw for themselves
        if (caller == Caller.VAULT && to != msg.sender) revert InvalidCaller();

        bytes memory withdrawCall = abi.encodeWithSelector(IPool.withdraw.selector, asset, amount, to);

        // call on behalf of vault
        bool success = ISafe(to).execTransactionFromModule(address(aavePool), 0, withdrawCall, Enum.Operation.Call);

        // check if safe transaction was successful
        if (!success) revert WithdrawAAVEFailed();
    }

    function enableOperator(address _operator) public onlyOwner {
        operators[_operator] = true;

        emit EnableOperator(_operator);
    }

    function disableOperator(address _operator) public onlyOwner {
        operators[_operator] = false;

        emit DisableOperator(_operator);
    }

    function togglePause() public onlyOwner {
        paused = !paused;

        emit TogglePause(paused);
    }

    function isOperator(address _operator) public view returns (bool) {
        return operators[_operator];
    }

    function _isDAMMVault(address _vault) private view returns (bool) {
        return vaultFactory.getDeployedVaultNonce(_vault) > 0;
    }

    function _checkIsDAMMVault(address _vault) private view {
        if (!_isDAMMVault(_vault)) revert NotDAMMVault();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

abstract contract TokenAuthorizer {
    event TokensAuthorized(address[] tokens);

    error TokenNotAuthorized(address token);

    mapping(address token => bool authorized) public authorizedTokens;

    constructor(address[] memory _authorizedTokens) {
        // Register authorized tokens
        uint256 length = _authorizedTokens.length;
        for (uint256 i = 0; i < length;) {
            authorizedTokens[_authorizedTokens[i]] = true;

            // will never overflow due to size of _authorizedTokens
            unchecked {
                ++i;
            }
        }

        emit TokensAuthorized(_authorizedTokens);
    }

    function isAuthorizedToken(address token) public view returns (bool) {
        return authorizedTokens[token];
    }

    function checkIsAuthorizedToken(address token) internal view {
        if (!isAuthorizedToken(token)) revert TokenNotAuthorized(token);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Enum - Collection of enums used in Safe contracts.
 * @author Richard Meissner - @rmeissner
 */
abstract contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Enum} from "@safe-contracts/common/Enum.sol";

interface ISafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(address to, uint256 value, bytes calldata data, Enum.Operation operation)
        external
        returns (bool success);

    /**
     * @notice Execute `operation` (0: Call, 1: DelegateCall) to `to` with `value` (Native Token) and return data
     * @param to Destination address of module transaction.
     * @param value Ether value of module transaction.
     * @param data Data payload of module transaction.
     * @param operation Operation type of module transaction.
     * @return success Boolean flag indicating if the call succeeded.
     * @return returnData Data returned by the call.
     */
    function execTransactionFromModuleReturnData(address to, uint256 value, bytes memory data, Enum.Operation operation)
        external
        returns (bool success, bytes memory returnData);

    // @dev Allows to swap/replace an owner from the Safe with another address.
    ///      This can only be done via a Safe transaction.
    /// @notice Replaces the owner `oldOwner` in the Safe with `newOwner`.
    /// @param prevOwner Owner that pointed to the owner to be replaced in the linked list
    /// @param oldOwner Owner address to be replaced.
    /// @param newOwner New owner address.
    function swapOwner(address prevOwner, address oldOwner, address newOwner) external;

    // @dev Returns array of owners.
    /// @return Array of Safe owners.
    function getOwners() external view returns (address[] memory);

    /// @dev Allows to add a module to the whitelist.
    ///      This can only be done via a Safe transaction.
    /// @notice Enables the module `module` for the Safe.
    /// @param module Module to be whitelisted.
    function enableModule(address module) external;

    /// @dev Set a guard that checks transactions before execution
    /// @param guard The address of the guard to be used or the 0 address to disable the guard
    function setGuard(address guard) external;

    /// @dev Setup function sets initial storage of contract.
    /// @param _owners List of Safe owners.
    /// @param _threshold Number of required confirmations for a Safe transaction.
    /// @param to Contract address for optional delegate call.
    /// @param data Data payload for optional delegate call.
    /// @param fallbackHandler Handler for fallback calls to this contract
    /// @param paymentToken Token that should be used for the payment (0 is ETH)
    /// @param payment Value that should be paid
    /// @param paymentReceiver Address that should receive the payment (or 0 if tx.origin)
    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external;

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(address module) external view returns (bool);

    /// @return True if address is owner of the Safe
    function isOwner(address owner) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

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
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

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
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

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
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager {
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVaultFactory {
    event VaultDeployed(
        address indexed vault, address[] owners, address vaultGuard, address tradingModule, uint256 nonce
    );

    struct StorageSlot {
        address safeFactory; // Gnosis Safe Factory address
        address fallbackHandler; // Handler for fallback calls to this contract
        address singleton; // Address of the Gnosis Safe singleton contract
        address owner; // Vault Factory owner
        uint256 nonce; // Vault Factory nonce
    }

    function vaultDeploymentCallback(address _tradingModule, address _vaultGuard) external;

    function deployVault(address[] memory _owners, uint256 _threshold, address _tradingModule, address _vaultGuard)
        external
        returns (address);

    function getDeployedVaultNonce(address _vault) external view returns (uint256);

    function getOwner() external view returns (address);
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMultiSend {
    /**
     * @dev Sends multiple transactions and reverts all if one fails.
     * @param transactions Encoded transactions. Each transaction is encoded as a packed bytes of
     *                     operation as a uint8 with 0 for a call or 1 for a delegatecall (=> 1 byte),
     *                     to as a address (=> 20 bytes),
     *                     value as a uint256 (=> 32 bytes),
     *                     data length as a uint256 (=> 32 bytes),
     *                     data as bytes.
     *                     see abi.encodePacked for more information on packed encoding
     * @notice This method is payable as delegatecalls keep the msg.value from the previous call
     *         If the calling method (e.g. execTransaction) received ETH this would revert otherwise
     */
    function multiSend(bytes memory transactions) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ISwapRouter} from "@src/interfaces/ISwapRouter.sol";
import {INonfungiblePositionManager} from "@src/interfaces/INonfungiblePositionManager.sol";
import {IVaultFactory} from "@src/interfaces/IVaultFactory.sol";
import {IMultiSend} from "@src/interfaces/IMultiSend.sol";
import {IPool} from "@src/interfaces/IPool.sol";

interface ITradingModule {
    error ApproveFailed();
    error InvalidCaller();
    error MulticallFailed();
    error NotDAMMVault();
    error SameToken();
    error BurnFailed();
    error MintFailed();
    error CollectFeesFailed();
    error IncreaseLiquidityFailed();
    error DecreaseLiquidityFailed();
    error SwapFailed();
    error NotOwner();
    error NotOperator();
    error ModulePaused();
    error SupplyAAVEFailed();
    error WithdrawAAVEFailed();

    event EnableOperator(address indexed operator);
    event DisableOperator(address indexed operator);
    event TogglePause(bool paused);

    function vaultFactory() external view returns (IVaultFactory);

    function multiSend() external view returns (IMultiSend);

    function uniswapV3Router() external view returns (ISwapRouter);

    function uniswapV3PositionManager() external view returns (INonfungiblePositionManager);

    function aavePool() external view returns (IPool);

    function paused() external view returns (bool);

    function owner() external view returns (address);

    function multicall(address vault, bytes calldata transactions) external;

    function swapTokenWithV3(ISwapRouter.ExactInputSingleParams memory params) external;

    function mintV3Position(INonfungiblePositionManager.MintParams calldata params) external;

    function burnV3Position(uint256 tokenId) external;

    function collectV3TokensOwed(INonfungiblePositionManager.CollectParams calldata params) external;

    function increaseV3PositionLiquidity(INonfungiblePositionManager.IncreaseLiquidityParams calldata params)
        external;

    function decreaseV3PositionLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams calldata params)
        external;

    function approveRouterAllowance(address vault, address token, uint256 amount) external;

    function approvePositionManagerAllowance(address vault, address token, uint256 amount) external;

    function approveAAVEPoolAllowance(address vault, address token, uint256 amount) external;

    function supplyAAVE(address token, uint256 amount, address onBehalfOf) external;

    function withdrawAAVE(address asset, uint256 amount, address to) external;

    function enableOperator(address _operator) external;

    function disableOperator(address _operator) external;

    function isOperator(address _operator) external view returns (bool);

    function togglePause() external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 */
interface IPool {
    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     */
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);

    /**
     * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     */
    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf)
        external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     */
    function repay(address asset, uint256 amount, uint256 interestRateMode, address onBehalfOf)
        external
        returns (uint256);
}

// SPDX-License-Identifier: MIT
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