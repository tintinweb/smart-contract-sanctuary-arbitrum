// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

import {IPositionRouterCallbackReceiver} from "./interfaces/IPositionRouterCallbackReceiver.sol";

import {GmxFacet} from "./GmxFacet.sol";

contract GmxCallbackReceiver is IPositionRouterCallbackReceiver, Owned {
    /// @notice The USDC address.
    address public immutable USDC;

    /// @notice The kibo address.
    address public kibo;

    /// @notice The GMX position router address.
    address public gmxPositionRouter;

    /// @notice The collections of GMX pending request to the associated token.
    mapping(bytes32 pendingRequestKey => address token)
        public tokenPerPendingRequestKey;

    /// @notice The collections of GMX pending request per token.
    mapping(address token => bytes32 pendingRequestKey)
        public pendingRequestKeyPerToken;

    constructor(
        address _USDC,
        address _kibo,
        address _gmxPositionRouter
    ) Owned(msg.sender) {
        USDC = _USDC;
        kibo = _kibo;
        gmxPositionRouter = _gmxPositionRouter;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                              ERRORS                                            //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Reverted when requesting a position update while a request is already pending.
    ///
    /// @param token The token address.
    /// @param pendingRequestKey The pending request key.
    error RequestAlreadyPending(address token, bytes32 pendingRequestKey);

    /// @notice Reverted when the caller of the "gmxPositionCallback" method is not the GMX position
    ///         router.
    /// @param sender The sender address.
    error SenderIsNotGmx(address sender);

    /// @notice Reverted when the caller of the "registerPendingRequest" method is not Kibo.
    ///
    /// @param sender The sender address.
    error SenderIsNotKibo(address sender);

    /// @notice Reverted when calling the "gmxPositionCallback" method with an invalid requet key.
    ///
    /// @param requestKey The request key.
    error InvalidRequestKey(bytes32 requestKey);

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                         ADMIN FUNCTIONS                                        //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Set the Kibo address.
    ///
    /// @dev Can only be called by the owner.
    ///
    /// @param _kibo The Kibo address.
    function setKibo(address _kibo) external onlyOwner {
        kibo = _kibo;
    }

    /// @notice Set the GMX position router.
    ///
    /// @dev Can only be called by the owner.
    ///
    /// @param _gmxPositionRouter The GMX position router.
    function setGmxPositionRouter(
        address _gmxPositionRouter
    ) external onlyOwner {
        gmxPositionRouter = _gmxPositionRouter;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                          KIBO FUNCTIONS                                        //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Register a pending request key.
    ///
    /// @dev Can only be called by Kibo.
    ///
    /// @param pendingRequestKey The pending request key to register.
    /// @param token The associated token traded.
    function registerPendingRequest(
        bytes32 pendingRequestKey,
        address token
    ) external {
        // Ensure sender is Kibo.
        if (msg.sender != kibo) {
            revert SenderIsNotKibo({sender: msg.sender});
        }

        // Ensure no request is already pending for this token.
        bytes32 _pendingRequestKey = pendingRequestKeyPerToken[token];
        if (uint256(_pendingRequestKey) != 0) {
            revert RequestAlreadyPending({
                token: token,
                pendingRequestKey: _pendingRequestKey
            });
        }

        // Register the pending request.
        tokenPerPendingRequestKey[pendingRequestKey] = token;
        pendingRequestKeyPerToken[token] = pendingRequestKey;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                     GMX CALLBACK FUNCTION                                      //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice GMX position callback.
    ///
    /// @dev Can only be called by the GMX position router.
    ///
    /// @param requestKey The request key.
    /// @param isExecuted Whether the position updated has been executed.
    /// @param isIncrease Wheter the position update was an increase or a decrease.
    function gmxPositionCallback(
        bytes32 requestKey,
        bool isExecuted,
        bool isIncrease
    ) external {
        // Ensure the sender is the GMX position router.
        if (msg.sender != gmxPositionRouter) {
            revert SenderIsNotGmx({sender: msg.sender});
        }

        // Ensure the request pending key is valid.
        address token = tokenPerPendingRequestKey[requestKey];
        if (token == address(0)) {
            revert InvalidRequestKey({requestKey: requestKey});
        }

        // Delete this pending request from storage.
        delete pendingRequestKeyPerToken[token];
        delete tokenPerPendingRequestKey[requestKey];

        // Avoid multiple SLOADs.
        address _kibo = kibo;

        // Send all funds back to Kibo.
        uint256 tokenBalance = ERC20(token).balanceOf(address(this));
        uint256 usdcBalance = ERC20(USDC).balanceOf(address(this));

        if (tokenBalance != 0) {
            ERC20(token).transfer({to: _kibo, amount: tokenBalance});
        }

        if (usdcBalance != 0) {
            ERC20(USDC).transfer({to: _kibo, amount: usdcBalance});
        }

        // Notify kibo.
        GmxFacet(_kibo).notifyProcessedRequest({
            requestKey: requestKey,
            isExecuted: isExecuted,
            isIncrease: isIncrease,
            token: token,
            tokenAmount: tokenBalance,
            usdcAmount: usdcBalance
        });
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

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IPositionRouterCallbackReceiver {
    function gmxPositionCallback(
        bytes32 positionKey,
        bool isExecuted,
        bool isIncrease
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Position} from "./interfaces/IVault.sol";

import {ERC173} from "../../diamond/impl/ERC173/ERC173.sol";

import {GmxLib} from "./GmxLib.sol";
import {GmxSwapLib} from "./GmxSwapLib.sol";
import {GmxPositionLib, CurrentPositionRes} from "./GmxPositionLib.sol";

contract GmxFacet is ERC173 {
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                          VIEW FUNCTIONS                                        //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Return the GMX vault address used for swaps.
    ///
    /// @return _vault The GMX vault address.
    function gmxVault() external view returns (address _vault) {
        _vault = GmxLib.s().vault;
    }

    /// @notice Return the max chainlink slippage accepted for swaps.
    ///
    /// @return _maxChainlinkDivergence The max slippage accepted.
    function maxChainlinkDivergence()
        external
        view
        returns (uint256 _maxChainlinkDivergence)
    {
        _maxChainlinkDivergence = GmxLib.s().maxChainlinkDivergence;
    }

    /// @notice Return the GMX reader address used for swaps.
    ///
    /// @return _reader The GMX reader address.
    function gmxReader() external view returns (address _reader) {
        _reader = GmxSwapLib.s().reader;
    }

    /// @notice Return the max loop number used to compute GMX swaps.
    ///
    /// @return _maxLoopGetAmountIn The max loop number used to compute GMX swaps.
    function maxLoopGetAmountIn()
        external
        view
        returns (uint256 _maxLoopGetAmountIn)
    {
        _maxLoopGetAmountIn = GmxSwapLib.s().maxLoopGetAmountIn;
    }

    /// @notice Return the GMX router address used for position updates.
    ///
    /// @return _router The GMX router address.
    function gmxRouter() external view returns (address _router) {
        _router = GmxPositionLib.s().router;
    }

    /// @notice Return the GMX position router address used for position updates.
    ///
    /// @return _positionRouter The GMX position router address.
    function gmxPositionRouter()
        external
        view
        returns (address _positionRouter)
    {
        _positionRouter = GmxPositionLib.s().positionRouter;
    }

    /// @notice Fetch the protocol current position (if any) on GMX.
    ///
    /// @param token The token address.
    ///
    /// @return currPosRes The CurrentPositionRes struct.
    function currentPosition(
        address token
    ) external view returns (CurrentPositionRes memory currPosRes) {
        currPosRes = GmxPositionLib.currentPosition(token);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                         ADMIN FUNCTIONS                                        //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Set the GMX vault.
    ///
    /// @dev Can only be called by the owner.
    ///
    /// @param _vault The GMX vault address.
    function setGmxVault(address _vault) external onlyOwner {
        GmxLib.setGmxVault(_vault);
    }

    /// @notice Set the max chainlink slippage.
    ///
    /// @dev Can only be called by the owner.
    ///
    /// @param _maxChainlinkDivergence The max accepted divergence compared to chainlink price.
    function setMaxChainlinkDivergence(
        uint256 _maxChainlinkDivergence
    ) external onlyOwner {
        GmxLib.setMaxChainlinkDivergence(_maxChainlinkDivergence);
    }

    /// @notice Set the GMX reader.
    ///
    /// @dev Can only be called by the owner.
    ///
    /// @param _reader The GMX reader address.
    function setGmxReader(address _reader) external onlyOwner {
        GmxSwapLib.setGmxReader(_reader);
    }

    /// @notice Set the max loop number used to compute GMX swaps.
    ///
    /// @dev Can only be called by the owner.
    ///
    /// @param _maxLoopGetAmountIn The max loop to use.
    function setMaxLoopGetAmountIn(
        uint256 _maxLoopGetAmountIn
    ) external onlyOwner {
        GmxSwapLib.setMaxLoopGetAmountIn(_maxLoopGetAmountIn);
    }

    /// @notice Set the GMX router.
    ///
    /// @dev Can only be called by the owner.
    ///
    /// @param _router The GMX router address.
    function setGmxRouter(address _router) external onlyOwner {
        GmxPositionLib.setGmxRouter(_router);
    }

    /// @notice Set the GMX position router.
    ///
    /// @dev Can only be called by the owner.
    ///
    /// @param _positionRouter The GMX position router address.
    function setGmxPositionRouter(address _positionRouter) external onlyOwner {
        GmxPositionLib.setGmxPositionRouter(_positionRouter);
    }

    /// @notice Set the GMX callback receiver.
    ///
    /// @dev Can only be called by the owner.
    ///
    /// @param _callbackReceiver The GMX callback receiver address.
    function setGmxCallbackReceiver(
        address _callbackReceiver
    ) external onlyOwner {
        GmxPositionLib.setGmxCallbackReceiver(_callbackReceiver);
    }

    /// @notice Approve the GMX PositionRouter as on plugin on the GMX Router.
    ///
    /// @dev Can only be called by the owner.
    function approvePositionRouter() external onlyOwner {
        GmxPositionLib.approvePositionRouter();
    }

    /// @notice Deny the GMX PositionRouter as on plugin on the GMX Router.
    ///
    /// @dev Can only be called by the owner.
    function denyPositionRouter() external onlyOwner {
        GmxPositionLib.denyPositionRouter();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                GMX CALLBACK RECEIVER FUNCTION                                  //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Notify Kibo about a pending request that has been processed by GMX.
    ///
    /// @dev Can only be called by the GMX callback receiver.
    ///
    /// @param requestKey The request key processed.
    /// @param isExecuted Wheter the request as been executed.
    /// @param isIncrease Whether the request was for a position increase.
    /// @param token The token address.
    /// @param tokenAmount The token amount received if any.
    /// @param usdcAmount The USDC amount received if any.
    function notifyProcessedRequest(
        bytes32 requestKey,
        bool isExecuted,
        bool isIncrease,
        address token,
        uint256 tokenAmount,
        uint256 usdcAmount
    ) external {
        GmxPositionLib.notifyProcessedRequest({
            requestKey: requestKey,
            isExecuted: isExecuted,
            isIncrease: isIncrease,
            token: token,
            tokenAmount: tokenAmount,
            usdcAmount: usdcAmount
        });
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

struct Position {
    uint256 size;
    uint256 collateral;
    uint256 averagePrice;
    uint256 entryFundingRate;
    uint256 reserveAmount;
    int256 realisedPnl;
    uint256 lastIncreasedTime;
}

interface IVault {
    function gov() external view returns (address);

    function tokenBalances(address token) external view returns (uint256);

    function tokenWeights(address token) external view returns (uint256);

    function usdgAmounts(address token) external view returns (uint256);

    function maxUsdgAmounts(address token) external view returns (uint256);

    function poolAmounts(address token) external view returns (uint256);

    function reservedAmounts(address token) external view returns (uint256);

    function bufferAmounts(address token) external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function swapFeeBasisPoints() external view returns (uint256);

    function getFeeBasisPoints(
        address token,
        uint256 usdgDelta,
        uint256 feeBasisPoints,
        uint256 taxBasisPoints,
        bool increment
    ) external view returns (uint256);

    function cumulativeFundingRates(
        address collateralToken
    ) external view returns (uint256);

    function getMaxPrice(address token) external view returns (uint256);

    function getMinPrice(address token) external view returns (uint256);

    function swap(
        address tokenIn,
        address tokenOut,
        address receiver
    ) external returns (uint256);

    function getPositionKey(
        address account,
        address collateralToken,
        address indexToken,
        bool isLong
    ) external pure returns (bytes32);

    function positions(bytes32 key) external view returns (Position memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC173Lib} from "./ERC173Lib.sol";

abstract contract ERC173 {
    modifier onlyOwner() {
        require(msg.sender == ERC173Lib.s().owner, "UNAUTHORIZED");

        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

struct GmxLibStorage {
    address vault;
    uint256 maxChainlinkDivergence;
}

library GmxLib {
    bytes32 constant GMX_LIB_STORAGE_POSITION = keccak256("gmx-lib.storage");

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                              EVENTS                                            //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Emitted when the GMX vault is updated.
    ///
    /// @param gmxVault The GMX vault address.
    event GmxVaultUpdated(address gmxVault);

    /// @notice Emitted when the chainlink divergence is updated.
    ///
    /// @param maxChainlinkDivergence The max chainlink divergence percent accepted.
    event MaxChainlinkDivergenceUpdated(uint256 maxChainlinkDivergence);

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                        INTERNAL FUNCTIONS                                      //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Return the storage struct for reading and writing.
    ///
    /// @return storageStruct The GmxLibStorage struct.
    function s() internal pure returns (GmxLibStorage storage storageStruct) {
        bytes32 position = GMX_LIB_STORAGE_POSITION;
        assembly {
            storageStruct.slot := position
        }
    }

    /// @notice Set the GMX vault.
    ///
    /// @param vault The GMX vault address.
    function setGmxVault(address vault) internal {
        s().vault = vault;
        emit GmxVaultUpdated(vault);
    }

    /// @notice Set the max chainlink price divergence tolerated to perfrom actions on GMX.
    ///
    /// @param maxChainlinkDivergence The max accepted divergence compared to chainlink price.
    function setMaxChainlinkDivergence(
        uint256 maxChainlinkDivergence
    ) internal {
        s().maxChainlinkDivergence = maxChainlinkDivergence;
        emit MaxChainlinkDivergenceUpdated(maxChainlinkDivergence);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IVault} from "./interfaces/IVault.sol";
import {IReader} from "./interfaces/IReader.sol";

import {TokenLib} from "../Token/TokenLib.sol";
import {GmxLib} from "../Gmx/GmxLib.sol";

struct GmxSwapLibStorage {
    address reader;
    uint256 maxLoopGetAmountIn;
}

library GmxSwapLib {
    bytes32 constant GMX_SWAP_LIB_STORAGE_POSITION =
        keccak256("gmx-swap-lib.storage");

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                              EVENTS                                            //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Emitted when the GMX reader is updated.
    ///
    /// @param gmxReader The GMX reader address.
    event GmxReaderUpdated(address gmxReader);

    /// @notice Emitted when the max iteration to compute getAmountIn is updated.
    ///
    /// @param maxLoopGetAmountIn Themax iteration to compute getAmountIn.
    event MaxLoopGetAmountInUpdated(uint256 maxLoopGetAmountIn);

    /// @notice Emitted when a swap is performed on GMX.
    /// @param tokenIn The token in.
    /// @param amountIn The amount.
    /// @param tokenOut The token out.
    /// @param amountOut The amount out.
    event Swapped(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut
    );

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                              ERRORS                                            //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Reverted when the max loop has been reached when trying to compute the GMX amountIn.
    error GetAmountInMaxLoopReached();

    /// @notice Reverted when the swap price is not accepted.
    ///
    /// @param swapPrice The swap price.
    /// @param isLong Whether it was for longing or shorting.
    error SwapPriceNotAccepted(uint256 swapPrice, bool isLong);

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                       INTERNAL STRUCTURES                                      //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Avoid "Stack too deep" error in the "getAmountIn" method.
    struct GetAmountInStack {
        uint256 maxAmountIn;
        uint256 priceIn;
        uint256 priceOut;
        uint256 baseBps;
        uint256 taxBps;
        uint256 feeBasisPoint;
        uint256 smallestPrecision;
        uint256 maxLoopGetAmountIn;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                        INTERNAL FUNCTIONS                                      //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Return the storage struct for reading and writing.
    ///
    /// @return storageStruct The GmxSwapLibStorage struct.
    function s()
        internal
        pure
        returns (GmxSwapLibStorage storage storageStruct)
    {
        bytes32 position = GMX_SWAP_LIB_STORAGE_POSITION;
        assembly {
            storageStruct.slot := position
        }
    }

    /// @notice Set the GMX reader.
    ///
    /// @param reader The GMX reader address.
    function setGmxReader(address reader) internal {
        s().reader = reader;
        emit GmxReaderUpdated(reader);
    }

    /// @notice Set the max loop number used to cocmpute GMX swaps.
    ///
    /// @param maxLoopGetAmountIn The max loop to use.
    function setMaxLoopGetAmountIn(uint256 maxLoopGetAmountIn) internal {
        s().maxLoopGetAmountIn = maxLoopGetAmountIn;
        emit MaxLoopGetAmountInUpdated(maxLoopGetAmountIn);
    }

    /// @notice Return the swap amount out for a given amount in.
    ///
    /// @dev Simple wrapper around GMXReader method.
    ///
    /// @param tokenIn The token in.
    /// @param tokenOut The token out.
    ///
    /// @return maxAmountIn The maximum amount in.
    function getMaxAmountIn(
        address tokenIn,
        address tokenOut
    ) internal view returns (uint256 maxAmountIn) {
        // Get the maximum amount of tokenIn that can be swapped.
        maxAmountIn = IReader(s().reader).getMaxAmountIn({
            vault: GmxLib.s().vault,
            tokenIn: tokenIn,
            tokenOut: tokenOut
        });
    }

    /// @notice Return the swap amount out for a given amount in.
    ///
    /// @dev Simple wrapper around GMXReader method.
    ///
    /// @param tokenIn The token in.
    /// @param tokenOut The token out.
    /// @param amountIn The amount of token in to swap.
    ///
    /// @return amountOutAfterFees The amount of token out.
    /// @return feeAmount The fee amount in token out.
    function getAmountOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal view returns (uint256 amountOutAfterFees, uint256 feeAmount) {
        IReader reader = IReader(s().reader);
        (amountOutAfterFees, feeAmount) = reader.getAmountOut(
            GmxLib.s().vault,
            tokenIn,
            tokenOut,
            amountIn
        );
    }

    /// @notice Return the necessary amount of "tokenIn" needed to receive the specified
    ///         amount of "tokenOut".
    ///
    /// @param tokenIn The token in.
    /// @param tokenOut The token out.
    /// @param amountOut The requested amount out.
    /// @param tokenInPrecision The token in precision.
    /// @param tokenOutPrecision The token out precision.
    ///
    /// @return amountInAfterFees The amount of token in after fees.
    /// @return correctedAmountOutAfterFees The real amout ouf after fees corresponding to the returned amount in after fees value.
    function getAmountIn(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 tokenInPrecision,
        uint256 tokenOutPrecision
    )
        internal
        view
        returns (uint256 amountInAfterFees, uint256 correctedAmountOutAfterFees)
    {
        // Move stack var to memory to avoid "Stack too deep" issues.
        GetAmountInStack memory stack;
        {
            IVault vault = IVault(GmxLib.s().vault);

            // Fetch the prices from GMX price feed.
            stack.priceIn = (vault.getMinPrice(tokenIn) * 1e6) / 1e30;
            stack.priceOut = (vault.getMaxPrice(tokenOut) * 1e6) / 1e30;

            // Fetch the swap fees from the GMX vault.
            stack.baseBps = vault.swapFeeBasisPoints();
            stack.taxBps = vault.taxBasisPoints();

            // Start the algorithm with the default fee basis points of 30.
            stack.feeBasisPoint = 80;

            // Get the smallest token precision.
            stack.smallestPrecision = tokenInPrecision < tokenOutPrecision
                ? tokenInPrecision
                : tokenOutPrecision;
        }

        // Loop a finite amount of times (10 should be more than enough, in average 2-3 is sufficient)
        // to find the exact "feeBasisPoint" used.
        // Once the feeBasisPoint is found, it can be used then to compute the amount out
        // before the fees and then deduce the resulting amountIn.
        stack.maxLoopGetAmountIn = s().maxLoopGetAmountIn;
        for (
            stack.maxLoopGetAmountIn;
            stack.maxLoopGetAmountIn > 0;
            stack.maxLoopGetAmountIn -= 1
        ) {
            // Compute the amount out before the fees.
            // NOTE: Round up the division to not endup with less than necessary
            // if case of precision issues.
            uint256 amountOutBeforeFees = ((amountOut * 10_000) +
                (10_000 - stack.feeBasisPoint - 1)) /
                (10_000 - stack.feeBasisPoint);

            // Round up the amout out before the fees using the smallest precision.
            amountOutBeforeFees =
                (amountOutBeforeFees *
                    stack.smallestPrecision +
                    (tokenOutPrecision - 1)) /
                tokenOutPrecision;

            amountOutBeforeFees =
                (amountOutBeforeFees * tokenOutPrecision) /
                stack.smallestPrecision;

            // Compute the associated amount in with fees.
            // NOTE: Round up the division to not endup with less than necessary
            // if case of precision issues.
            amountInAfterFees =
                (amountOutBeforeFees * stack.priceOut + stack.priceIn - 1) /
                stack.priceIn;

            amountInAfterFees =
                (amountInAfterFees * tokenInPrecision + tokenOutPrecision - 1) /
                tokenOutPrecision;

            // Compute the USDG amount.
            // NOTE: USDC is 1e18 precision so mutliply the amount by 1e12.
            uint256 usdgAmount = (amountInAfterFees * stack.priceIn * 1e12) /
                tokenInPrecision;

            // Derive the real fee basis points from the USDG amount.
            uint256 newFeeBasisPoints = _getSwapFeesBasisPoint(
                tokenIn,
                tokenOut,
                usdgAmount,
                stack.baseBps,
                stack.taxBps
            );

            // If the new fees basis point matches with the one used to do all the computation above
            // we're good and we can exit the loo
            if (stack.feeBasisPoint == newFeeBasisPoints) {
                break;
            }

            // Else, the previous fees basis points was not correct and we must recompute all the variables.
            stack.feeBasisPoint = newFeeBasisPoints;
        }

        // If we did not manage to find the correct fee basis points within "maxLoopGetAmountIn" loops,
        // revert with an error.
        if (stack.maxLoopGetAmountIn == 0) {
            revert GetAmountInMaxLoopReached();
        }

        // Compute the correctedAmountOutBeforeFees given the amountInAfterFees that has been computed
        // in the bruteforce loop.
        // NOTE: We intentionnaly do the precision conversion after (resulting in a worst precision..) to match
        // what GMX is doing: https://github.com/gmx-io/gmx-contracts/blob/master/contracts/peripherals/Reader.sol#L92
        uint256 correctedAmountOutBeforeFees = (amountInAfterFees *
            stack.priceIn) / stack.priceOut;

        correctedAmountOutBeforeFees =
            (correctedAmountOutBeforeFees * tokenOutPrecision) /
            tokenInPrecision;

        // Apply fees on the correctedAmountOutBeforeFees.
        correctedAmountOutAfterFees =
            (correctedAmountOutBeforeFees * (10_000 - stack.feeBasisPoint)) /
            10_000;
    }

    /// @notice Swap exact token in for token out.
    ///
    /// @param tokenIn The token in.
    /// @param tokenOut The token out.
    /// @param amountIn The exact amount of token out in to swap.
    ///
    /// @return amountOutAfterFees The amount of token out received.
    function swapExactAmountIn(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal returns (uint256 amountOutAfterFees) {
        IVault vault = IVault(GmxLib.s().vault);
        TokenLib.transfer(tokenIn, address(vault), amountIn);
        amountOutAfterFees = vault.swap(tokenIn, tokenOut, address(this));
        emit Swapped(tokenIn, amountIn, tokenOut, amountOutAfterFees);
    }

    /// @notice Compute the buy price for a given swap and check if the price is acceptable.
    ///
    /// @param usdcAmountIn The USDC amount in used to buy.
    /// @param tokenAmountOut The token amount bought.
    /// @param precision The token precision.
    /// @param spot The spot price.
    ///
    /// @return _buyPrice The computed buy price.
    /// @return isAcceptable Whether or not the buy price is acceptable compared to chainlink.
    function buyPrice(
        uint256 usdcAmountIn,
        uint256 tokenAmountOut,
        uint256 precision,
        uint256 spot
    ) internal view returns (uint256 _buyPrice, bool isAcceptable) {
        uint256 maxChainlinkDivergence = GmxLib.s().maxChainlinkDivergence;
        uint256 maxBuyPrice = ((1e18 + maxChainlinkDivergence) * spot) / 1e18;
        _buyPrice = (tokenAmountOut * precision) / usdcAmountIn;
        isAcceptable = _buyPrice <= maxBuyPrice;
    }

    /// @notice Compute the sell price for a given swap and check if the price is acceptable.
    ///
    /// @param tokenAmountIn The token amount to sell.
    /// @param usdcAmountOut The USDC amount out.
    /// @param precision The token precision.
    /// @param spot The spot price.
    ///
    /// @return _sellPrice The computed sell price.
    /// @return isAcceptable Whether or not the sell price is acceptable compared to chainlink.
    function sellPrice(
        uint256 tokenAmountIn,
        uint256 usdcAmountOut,
        uint256 precision,
        uint256 spot
    ) internal view returns (uint256 _sellPrice, bool isAcceptable) {
        uint256 maxChainlinkDivergence = GmxLib.s().maxChainlinkDivergence;
        uint256 minSellPrice = ((1e18 - maxChainlinkDivergence) * spot) / 1e18;
        _sellPrice = (usdcAmountOut * precision) / tokenAmountIn;
        isAcceptable = _sellPrice >= minSellPrice;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                        PRIVATE FUNCTIONS                                       //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Compute the swap fees
    ///
    /// @param tokenIn The token in.
    /// @param tokenOut The token out.
    /// @param usdgAmount The USDG amount.
    ///
    /// @return feeBasisPoints The swap fees.
    function _getSwapFeesBasisPoint(
        address tokenIn,
        address tokenOut,
        uint256 usdgAmount,
        uint256 baseBps,
        uint256 taxBps
    ) private view returns (uint256 feeBasisPoints) {
        // NOTE: The feeBasisPoints computation is taken from the GMX Reader "getAmountOut" method:
        // https://github.com/gmx-io/gmx-contracts/blob/master/contracts/peripherals/Reader.sol#L71

        IVault vault = IVault(GmxLib.s().vault);

        uint256 feesBasisPoints0 = vault.getFeeBasisPoints(
            tokenIn,
            usdgAmount,
            baseBps,
            taxBps,
            true
        );

        uint256 feesBasisPoints1 = vault.getFeeBasisPoints(
            tokenOut,
            usdgAmount,
            baseBps,
            taxBps,
            false
        );

        // use the higher of the two fee basis points
        feeBasisPoints = feesBasisPoints0 > feesBasisPoints1
            ? feesBasisPoints0
            : feesBasisPoints1;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "solmate/tokens/ERC20.sol";

import {IVault, Position} from "./interfaces/IVault.sol";
import {IRouter} from "./interfaces/IRouter.sol";
import {ITimeLock} from "./interfaces/ITimeLock.sol";
import {IPositionRouter} from "./interfaces/IPositionRouter.sol";

import {GmxCallbackReceiver} from "../Gmx/GmxCallbackReceiver.sol";

import {TokenLib} from "../Token/TokenLib.sol";
import {LiquidityLib} from "../Liquidity/LiquidityLib.sol";
import {ChainlinkLib} from "../Chainlink/ChainlinkLib.sol";
import {GmxLib} from "../Gmx/GmxLib.sol";

import {USDC} from "../Constants.sol";

/// @notice Returned value of the "currentPosition" method.
/// 	- hasPosition: Whether the protocol has a position on GMX or not.
/// 	- isLong: Wheter the position is long or short.
/// 	- gmxPos: The current GMX position.
struct CurrentPositionRes {
    bool hasPosition;
    bool isLong;
    Position gmxPos;
}

/// @notice Parameters for the "crequestPositionIncrease" method.
/// 	- token: the index token.
/// 	-  tradeSizeIncreaseInUsd: the trade size increase in USD (1e30 precision).
/// 	- collateralToLockInUsdc: the collateral to lock in USDC.
/// 	- isLong Whether to increase our long our short position.
struct RequestPositionIncreaseParams {
    address token;
    uint256 tradeSizeIncreaseInUsd;
    uint256 collateralToLockInUsdc;
    bool isLong;
}

/// @notice Parameters for the "requestPositionDecrease" method.
/// 	- token: the index token.
/// 	- tradeSizeDecreaseInUsd: the trade size decrease in USD (1e30 precision).
/// 	- collateralToUnlockInUsd: the collateral to unlock in USD (1e30 precision).
/// 	- isLong: Whether to decrease our long our short position.
struct RequestPositionDecreaseParams {
    address token;
    uint256 tradeSizeDecreaseInUsd;
    uint256 collateralToUnlockInUsd;
    bool isLong;
}

struct GmxPositionLibStorage {
    address router;
    address positionRouter;
    address callbackReceiver;
}

library GmxPositionLib {
    bytes32 constant GMX_POSITION_LIB_STORAGE_POSITION =
        keccak256("gmx-position-lib.storage");

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                              EVENTS                                            //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Emitted when the GMX router is updated.
    ///
    /// @param gmxRouter The GMX router address.
    event GmxRouterUpdated(address gmxRouter);

    /// @notice Emitted when the GMX position router is updated.
    ///
    /// @param gmxPositionRouter The GMX position router address.
    event GmxPositionRouterUpdated(address gmxPositionRouter);

    /// @notice Emitted when the GMX callback receiver is updated.
    ///
    /// @param gmxCallbackReceiver The GMX position router address.
    event GmxCallbackReceiverUpdated(address gmxCallbackReceiver);

    /// @notice Emitted when a position request is sent to the GMX PositionRouter.
    ///
    /// @param requestKey The request key.
    /// @param token The token address.
    event PositionRequestSent(bytes32 requestKey, address token);

    /// @notice Emitted when a position request has been processed by the GMX PositionRouter.
    ///
    /// @param requestKey The request key.
    /// @param isExecuted Whether the request has been executed.
    /// @param isIncrease Wheter the request was a position increase or a decrease.
    /// @param token The token address.
    /// @param tokenAmount The token amount received if any.
    /// @param usdcAmount The USDC amount receibed if any.
    event PositionRequestProcessed(
        bytes32 requestKey,
        bool isExecuted,
        bool isIncrease,
        address token,
        uint256 tokenAmount,
        uint256 usdcAmount
    );

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                              ERRORS                                            //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Reverted when the caller of the "gmxPositionCallback" method is not the GMX position
    ///         router.
    ///
    /// @param sender The sender address.
    error SenderIsNotGmxCallbackReceiver(address sender);

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                        INTERNAL FUNCTIONS                                      //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Return the storage struct for reading and writing.
    ///
    /// @return storageStruct The GmxPositionLibStorage struct.
    function s()
        internal
        pure
        returns (GmxPositionLibStorage storage storageStruct)
    {
        bytes32 position = GMX_POSITION_LIB_STORAGE_POSITION;
        assembly {
            storageStruct.slot := position
        }
    }

    /// @notice Get the GMX short and long prices.
    ///
    /// @dev Simple wrapper around GMX Vault method.
    ///
    /// @param token The index token.
    ///
    /// @return shortPrice The GMX short price.
    /// @return longPrice The GMX long price.
    function shortLongPrices(
        address token
    ) internal view returns (uint256 shortPrice, uint256 longPrice) {
        IVault vault = IVault(GmxLib.s().vault);
        shortPrice = vault.getMinPrice(token);
        longPrice = vault.getMaxPrice(token);
    }

    /// @notice Fetch the protocol current position (if any) on GMX.
    ///
    /// @param token The token address.
    ///
    /// @return res The CurrentPositionRes struct.
    function currentPosition(
        address token
    ) internal view returns (CurrentPositionRes memory res) {
        res.gmxPos = _positions({
            token: token,
            // NOTE: We will most likely be short most of the time.
            isLong: false
        });

        if (res.gmxPos.size == 0) {
            res.gmxPos = _positions({token: token, isLong: true});
            res.isLong = true;
        }

        res.hasPosition = res.gmxPos.size != 0;
    }

    /// @notice Compute the GMX margin fee.
    ///
    /// @param collateralToken The collateral token used.
    /// @param usdTradeSize The trade size in USD (1e30 unit).
    /// @param usdPositionSize The position size in USD (1e30 unit).
    /// @param entryFundingRate The position entry funding rate.
    ///
    /// @return _marginFee The margin fee in USD (1e30 unit).
    function marginFeeInUsd(
        address collateralToken,
        uint256 usdTradeSize,
        uint256 usdPositionSize,
        uint256 entryFundingRate
    ) internal view returns (uint256 _marginFee) {
        uint256 posFee = _tradeFeeInUsd(usdTradeSize);
        uint256 fundingFee = _fundingFeeInUsd({
            collateralToken: collateralToken,
            usdPositionSize: usdPositionSize,
            entryFundingRate: entryFundingRate
        });

        _marginFee = posFee + fundingFee;
    }

    /// @notice Set the GMX router.
    ///
    /// @param router The GMX router address.
    function setGmxRouter(address router) internal {
        s().router = router;
        emit GmxRouterUpdated(router);
    }

    /// @notice Set the GMX position router.
    ///
    /// @param positionRouter The GMX position router address.
    function setGmxPositionRouter(address positionRouter) internal {
        s().positionRouter = positionRouter;
        emit GmxPositionRouterUpdated(positionRouter);
    }

    /// @notice Set the GMX callback receiver.
    ///
    /// @param callbackReceiver The GMX callback receiver address.
    function setGmxCallbackReceiver(address callbackReceiver) internal {
        s().callbackReceiver = callbackReceiver;
        emit GmxCallbackReceiverUpdated(callbackReceiver);
    }

    /// @notice Approve the GMX PositionRouter as on plugin on the GMX Router.
    ///
    /// @dev Necessary step in order to open positions on GMX.
    function approvePositionRouter() internal {
        IRouter router = IRouter(s().router);
        router.approvePlugin(s().positionRouter);
    }

    /// @notice Deny the GMX PositionRouter as on plugin on the GMX Router.
    ///
    function denyPositionRouter() internal {
        IRouter router = IRouter(s().router);
        router.denyPlugin(s().positionRouter);
    }

    /// @notice Send a request to GMX PositionRouter to increase our position.
    ///
    /// @param p The RequestPositionIncreaseParams struct.
    function requestPositionIncrease(
        RequestPositionIncreaseParams memory p
    ) internal {
        // Approve the GMX Router to take our collateral.
        ERC20(USDC).approve(s().router, p.collateralToLockInUsdc);

        address[] memory path;
        uint256 acceptablePrice;

        // Avoid "Stack too deep" error.
        // Set "path" and compute the "acceptablePrice"
        {
            // Get the Chainlink spot price used to compute an acceptable price.
            uint256 spot = ChainlinkLib.spot(p.token, false);

            // Get the max Chainlink divergence to compute an acceptable price.
            uint256 maxChainlinkDivergence = GmxLib.s().maxChainlinkDivergence;

            // For long:
            // 		1. Collateral must be in index token, so we must swap from USDC to the index token
            //		2. The acceptable price must be a max price.
            if (p.isLong) {
                path = new address[](2);
                path[0] = USDC;
                path[1] = p.token;

                // NOTE: The price must be in 1e30 precision.
                acceptablePrice =
                    (spot * (1e18 + maxChainlinkDivergence)) *
                    1e6;
            }
            // For short:
            // 		1. Collateral must a stable token so there is no need to swap.
            //		2. The acceptable price must be a min price.
            else {
                path = new address[](1);
                path[0] = USDC;

                // NOTE: The price must be in 1e30 precision.
                acceptablePrice = spot * (1e18 - maxChainlinkDivergence) * 1e6;
            }
        }

        // Send a request to GMX PositionRouter to increase our position.
        IPositionRouter positionRouter = IPositionRouter(s().positionRouter);
        uint256 executionFee = positionRouter.minExecutionFee();
        address callbackReceiver = s().callbackReceiver;
        bytes32 requestKey = positionRouter.createIncreasePosition{
            value: executionFee
        }({
            path: path,
            indexToken: p.token,
            amountIn: p.collateralToLockInUsdc,
            // NOTE: Can be 0 since we already specify "acceptablePrice".
            minOut: 0,
            sizeDelta: p.tradeSizeIncreaseInUsd,
            isLong: p.isLong,
            acceptablePrice: acceptablePrice,
            executionFee: executionFee,
            referralCode: bytes32("KIBO"),
            callbackTarget: callbackReceiver
        });

        GmxCallbackReceiver(callbackReceiver).registerPendingRequest({
            pendingRequestKey: requestKey,
            token: p.token
        });

        emit PositionRequestSent({token: p.token, requestKey: requestKey});
    }

    /// @notice Send a request to GMX PositionRouter to decrease our position.
    ///
    /// @param p The RequestPositionDecreaseParams struct.
    function requestPositionDecrease(
        RequestPositionDecreaseParams memory p
    ) internal {
        address[] memory path;
        uint256 acceptablePrice;

        // Avoid "Stack too deep" error.
        // Set "path" and compute the "acceptablePrice"
        {
            // Get the Chainlink spot price used to compute an acceptable price.
            uint256 spot = ChainlinkLib.spot(p.token, false);

            // Get the max Chainlink divergence to compute an acceptable price.
            uint256 maxChainlinkDivergence = GmxLib.s().maxChainlinkDivergence;

            // For long:
            // 		1. Collateral was in index token, so we must swap back from index token to USDC.
            //		2. The acceptable price must be a min price.
            if (p.isLong) {
                path = new address[](2);
                path[0] = p.token;
                path[1] = USDC;

                // NOTE: The price must be in 1e30 precision.
                acceptablePrice =
                    (spot * (1e18 - maxChainlinkDivergence)) *
                    1e6;
            }
            // For short:
            // 		1. Collateral was in USDC so there is no need to swap.
            //		2. The acceptable price must be a max price.
            else {
                path = new address[](1);
                path[0] = USDC;

                // NOTE: The price must be in 1e30 precision.
                acceptablePrice = spot * (1e18 + maxChainlinkDivergence) * 1e6;
            }
        }

        // Send a request to GMX PositionRouter to decrease our position.
        IPositionRouter positionRouter = IPositionRouter(s().positionRouter);
        uint256 executionFee = positionRouter.minExecutionFee();
        address callbackReceiver = s().callbackReceiver;
        bytes32 requestKey = positionRouter.createDecreasePosition{
            value: executionFee
        }({
            path: path,
            indexToken: p.token,
            collateralDelta: p.collateralToUnlockInUsd,
            sizeDelta: p.tradeSizeDecreaseInUsd,
            isLong: p.isLong,
            receiver: callbackReceiver,
            acceptablePrice: acceptablePrice,
            minOut: 0,
            executionFee: executionFee,
            withdrawETH: false,
            callbackTarget: callbackReceiver
        });

        GmxCallbackReceiver(callbackReceiver).registerPendingRequest({
            pendingRequestKey: requestKey,
            token: p.token
        });

        emit PositionRequestSent({token: p.token, requestKey: requestKey});
    }

    /// @notice Notify Kibo about a pending request that has been processed by GMX.
    ///
    /// @param requestKey The request key processed.
    /// @param isExecuted Wheter the request as been executed.
    /// @param isIncrease Whether the request was for a position increase.
    /// @param token The token address.
    /// @param tokenAmount The token amount received if any.
    /// @param usdcAmount The USDC amount received if any.
    function notifyProcessedRequest(
        bytes32 requestKey,
        bool isExecuted,
        bool isIncrease,
        address token,
        uint256 tokenAmount,
        uint256 usdcAmount
    ) internal {
        // Ensure the sender is our GMX callback receiver.
        if (msg.sender != s().callbackReceiver) {
            revert SenderIsNotGmxCallbackReceiver({sender: msg.sender});
        }

        // Increase the liquidity if we received some tokens back.
        if (tokenAmount != 0) {
            LiquidityLib.increaseLiquidity({token: token, amount: tokenAmount});
        }

        if (usdcAmount != 0) {
            LiquidityLib.increaseLiquidity({token: USDC, amount: usdcAmount});
        }

        emit PositionRequestProcessed({
            token: token,
            requestKey: requestKey,
            isExecuted: isExecuted,
            isIncrease: isIncrease,
            tokenAmount: tokenAmount,
            usdcAmount: usdcAmount
        });
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                        PRIVATE FUNCTIONS                                       //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Compute the GMX position key.
    ///
    /// @dev Copy of GMX Vault implementation to decrease gas waste.
    ///
    /// @param indexToken The index token.
    /// @param isLong Whether the position is long or short.
    /// @return posKey The GMX position key.
    function _positionKey(
        address indexToken,
        bool isLong
    ) private view returns (bytes32 posKey) {
        posKey = keccak256(
            abi.encodePacked(
                address(this),
                // NOTE:
                //  - for longs: collateral is the index token
                //  - for shorts: collateral is USDC.
                isLong ? indexToken : USDC,
                indexToken,
                isLong
            )
        );
    }

    /// @notice Return the associated GMX position.
    ///
    /// @dev Simple wrapper around GMX Vault method.
    ///
    /// @param token The index token.
    /// @param isLong Whether the position is long or short.
    ///
    /// @return pos The GMX position.
    function _positions(
        address token,
        bool isLong
    ) private view returns (Position memory pos) {
        IVault vault = IVault(GmxLib.s().vault);
        pos = vault.positions(
            _positionKey({indexToken: token, isLong: isLong})
        );
    }

    /// @notice Compute the GMX trade fee.
    ///
    /// @dev Copy of GMX VaultUtils implementation to decrease gas waste.
    ///
    /// @param usdTradeSize The USD trade size (1e30 unit).
    ///
    /// @return posFeeInUsd The USD position fee (1e30 unit).
    function _tradeFeeInUsd(
        uint256 usdTradeSize
    ) private view returns (uint256 posFeeInUsd) {
        IVault vault = IVault(GmxLib.s().vault);
        // NOTE: The marginFeeBasisPoints on the Vault is not used for trading and is replaced
        // by the marginFeeBasisPoints set in the goverance (TimeLock) contract.
        // See: https://github.com/gmx-io/gmx-contracts/blob/master/contracts/peripherals/Timelock.sol#L243
        uint256 afterFeeUsdTradeSize = (usdTradeSize *
            (10_000 - ITimeLock(vault.gov()).marginFeeBasisPoints())) / 10_000;
        posFeeInUsd = usdTradeSize - afterFeeUsdTradeSize;
    }

    /// @notice Compute the GMX funding fee.
    ///
    /// @dev Copy of GMX VaultUtils implementation to decrease gas waste.
    ///
    /// @param collateralToken The collateral token used.
    /// @param usdPositionSize The position size in USD (1e30 unit).
    /// @param entryFundingRate The position entry funding rate.
    ///
    /// @return fundingFeeInUsd The funding fee in USD (1e30 unit).
    function _fundingFeeInUsd(
        address collateralToken,
        uint256 usdPositionSize,
        uint256 entryFundingRate
    ) private view returns (uint256 fundingFeeInUsd) {
        IVault vault = IVault(GmxLib.s().vault);
        uint256 fundingRate = vault.cumulativeFundingRates(collateralToken) -
            entryFundingRate;
        fundingFeeInUsd = (usdPositionSize * fundingRate) / 1_000_000;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

struct ERC173Storage {
    address owner;
}

library ERC173Lib {
    bytes32 constant ERC173_STORAGE_POSITION = keccak256("erc173.storage");

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                        INTERNAL FUNCTIONS                                      //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Return the storage struct for reading and writing.
    /// @return storageStruct The ERC173 storage struct.
    function s() internal pure returns (ERC173Storage storage storageStruct) {
        bytes32 position = ERC173_STORAGE_POSITION;
        assembly {
            storageStruct.slot := position
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IReader {
    function getMaxAmountIn(
        address vault,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256);

    function getAmountOut(
        address vault,
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "solmate/tokens/ERC20.sol";

struct TokenLibStorage {
    mapping(address token => uint256 precision) precisions;
}

library TokenLib {
    bytes32 constant TOKEN_LIB_STORAGE_POSITION =
        keccak256("token-lib.storage");

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                              EVENTS                                            //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Emitted when an ERC20 token is registered.
    ///
    /// @param token The token address.
    /// @param name The token name.
    /// @param symbol The token symbol.
    /// @param decimals The token decimals.
    /// @param precision The token precision.
    event TokenRegistered(
        address token,
        string name,
        string symbol,
        uint256 decimals,
        uint256 precision
    );

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                        INTERNAL FUNCTIONS                                      //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Return the storage struct for reading and writing.
    ///
    /// @return storageStruct The TokenLibStorage struct.
    function s() internal pure returns (TokenLibStorage storage storageStruct) {
        bytes32 position = TOKEN_LIB_STORAGE_POSITION;
        assembly {
            storageStruct.slot := position
        }
    }

    /// @notice Wrapper arround ERC20 tokens transfer.
    function transfer(address token, address to, uint256 amount) internal {
        ERC20(token).transfer(to, amount);
    }

    /// @notice Wrapper arround ERC20 tokens transferFrom.
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        ERC20(token).transferFrom(from, to, amount);
    }

    /// @notice Register the given token in the protocol.
    ///
    /// @dev The token must support ERC20Metadata.
    ///
    /// @param token The token to register.
    function registerToken(address token) internal {
        uint256 decimals = ERC20(token).decimals();
        string memory name = ERC20(token).name();
        string memory symbol = ERC20(token).symbol();
        uint256 precision = 10 ** decimals;
        s().precisions[token] = precision;

        emit TokenRegistered({
            token: token,
            name: name,
            symbol: symbol,
            decimals: decimals,
            precision: precision
        });
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IRouter {
    function approvePlugin(address plugin) external;

    function denyPlugin(address plugin) external;

    function approvedPlugins(
        address user,
        address plugin
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface ITimeLock {
    function marginFeeBasisPoints() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IPositionRouter {
    function createIncreasePosition(
        address[] memory path,
        address indexToken,
        uint256 amountIn,
        uint256 minOut,
        uint256 sizeDelta,
        bool isLong,
        uint256 acceptablePrice,
        uint256 executionFee,
        bytes32 referralCode,
        address callbackTarget
    ) external payable returns (bytes32);

    function createDecreasePosition(
        address[] memory path,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        address receiver,
        uint256 acceptablePrice,
        uint256 minOut,
        uint256 executionFee,
        bool withdrawETH,
        address callbackTarget
    ) external payable returns (bytes32);

    function minExecutionFee() external returns (uint256);

    function minTimeDelayPublic() external returns (uint256);

    function executeIncreasePosition(
        bytes32 key,
        address payable executionFeeReceiver
    ) external returns (bool);

    function executeDecreasePosition(
        bytes32 key,
        address payable executionFeeReceiver
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {TokenLib} from "../Token/TokenLib.sol";
import {USDC} from "../Constants.sol";

struct LiquidityLibStorage {
    mapping(address asset => uint256 liquidity) liquidities;
    uint256 safeUsdc;
}

library LiquidityLib {
    bytes32 constant LIQUIDITY_LIB_STORAGE_POSITION =
        keccak256("liquidity-lib.storage");

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                              EVENTS                                            //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Emitted when liquidity is deposited into the protocol.
    ///
    /// @param asset The asset address.
    /// @param sender The sender address.
    /// @param amount The deposited amount.
    event LiquidityDeposited(address asset, address sender, uint256 amount);

    /// @notice Emitted when the liquidity is updated.
    ///
    /// @param token The token address.
    /// @param change The liquidity change.
    event LiquidityUpdated(address token, int256 change);

    /// @notice Emitted when the safe USDC is updated.
    ///
    /// @param change The safe USDC change.
    event SafeUsdcUpdated(int256 change);

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                              ERRORS                                            //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Reverted when trying to decrease the liquidity more than what's available.
    ///
    /// @param token The token address.
    /// @param availableLiquidity The liquidity available.
    /// @param amount The amount to decrease that triggered the error.
    error InsufficientLiquidity(
        address token,
        uint256 availableLiquidity,
        uint256 amount
    );

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                        INTERNAL FUNCTIONS                                      //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Return the storage struct for reading and writing.
    ///
    /// @return storageStruct The LiquidityLibStorage struct.
    function s()
        internal
        pure
        returns (LiquidityLibStorage storage storageStruct)
    {
        bytes32 position = LIQUIDITY_LIB_STORAGE_POSITION;
        assembly {
            storageStruct.slot := position
        }
    }

    /// @notice Deposit liquidity into the protocol.
    ///
    /// @param asset The asset address to deposit.
    /// @param amount The amount to deposit.
    function depositLiquidity(address asset, uint256 amount) internal {
        increaseLiquidity(asset, amount);

        TokenLib.transferFrom({
            token: asset,
            from: msg.sender,
            to: address(this),
            amount: amount
        });

        emit LiquidityDeposited(asset, msg.sender, amount);
    }

    /// @notice Increase the token liquidity.
    ///
    /// @param token The token address whose liquidity is increased.
    /// @param amount The amount to add.
    function increaseLiquidity(address token, uint256 amount) internal {
        s().liquidities[token] += amount;
        emit LiquidityUpdated({token: token, change: int256(amount)});
    }

    /// @notice Decrease the token liquidity.
    ///
    /// @param token The token address whose liquidity is decreased.
    /// @param amount The amount to remove.
    function decreaseLiquidity(address token, uint256 amount) internal {
        uint256 available = s().liquidities[token];
        if (available < amount) {
            revert InsufficientLiquidity({
                token: token,
                availableLiquidity: available,
                amount: amount
            });
        }

        unchecked {
            s().liquidities[token] -= amount;
        }
        emit LiquidityUpdated({token: token, change: -int256(amount)});
    }

    /// @notice Set the safe USDC for emergencies.
    ///
    /// @param amount The amount of USDC to lock for emergencies.
    function setSafeUsdc(uint256 amount) internal {
        uint256 safeUsdc = s().safeUsdc;

        int256 change = int256(amount) - int256(safeUsdc);
        // If we are locking more USDC than previously, decrease the available USDC liquidity.
        if (change > 0) {
            decreaseLiquidity(USDC, uint256(change));
        }
        // Else we are locking less USDC than previously, increase the available USDC liquidity.
        else {
            increaseLiquidity(USDC, uint256(-change));
        }

        s().safeUsdc = amount;
        emit SafeUsdcUpdated(change);
    }

    /// @notice Increase the safe USDC reserve.
    ///
    /// @param amount The amount of USDC to add to the safe reserve.
    function increaseSafeUsdc(uint256 amount) internal {
        s().safeUsdc += amount;
        emit SafeUsdcUpdated(int256(amount));
    }

    /// @notice Increase the safe USDC reserve.
    ///
    /// @param amount The amount of USDC to add to the safe reserve.
    function decreaseSafeUsdc(uint256 amount) internal {
        s().safeUsdc -= amount;
        emit SafeUsdcUpdated(-int256(amount));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "chainlink/v0.8/interfaces/AggregatorV3Interface.sol";

struct ChainlinkLibStorage {
    mapping(address asset => address priceFeed) priceFeeds;
}

library ChainlinkLib {
    bytes32 constant CHAINLINK_LIB_STORAGE_POSITION =
        keccak256("chainlink-lib.storage");

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                              EVENTS                                            //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Emitted when an token price feed is set.
    ///
    /// @param token The token address.
    ///
    /// @param priceFeed The associated chainlink price feed address.
    event PriceFeedSet(address token, address priceFeed);

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                              ERRORS                                            //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Reverted when a price feed is not configured for a given token.
    ///
    /// @param token The token address.
    error PriceFeedNotSet(address token);

    /// @notice Reverted when a price feed is returning a price less or equal than 0.
    ///
    /// @param token The token address.
    /// @param priceFeed The associated chainlink price feed address.
    /// @param price The returned price.
    error PriceFeedInvalidPrice(address token, address priceFeed, int256 price);

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                        INTERNAL FUNCTIONS                                      //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Return the storage struct for reading and writing.
    ///
    /// @return storageStruct The ChainlinkLibStorage struct.
    function s()
        internal
        pure
        returns (ChainlinkLibStorage storage storageStruct)
    {
        bytes32 position = CHAINLINK_LIB_STORAGE_POSITION;
        assembly {
            storageStruct.slot := position
        }
    }

    /// @notice Register the chainlink price feed for the given token.
    ///
    /// @param token The token address.
    ///
    /// @param priceFeed The chainlink price feed.
    function setPriceFeed(address token, address priceFeed) internal {
        s().priceFeeds[token] = priceFeed;
        emit PriceFeedSet(token, priceFeed);
    }

    /// @notice Fetch the spot from the chainlink price feed.
    ///
    /// @param token The token address.
    ///
    /// @return _spot The spot price in USDC (1e6) or precise unit (1e18).
    function spot(
        address token,
        bool precise
    ) internal view returns (uint256 _spot) {
        // Get the associated price feed address.
        address priceFeed = s().priceFeeds[token];

        // Make sure the price feed as been set.
        if (priceFeed == address(0)) {
            revert PriceFeedNotSet(token);
        }

        (
            ,
            /*uint80 roundID*/
            int256 price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = AggregatorV3Interface(priceFeed).latestRoundData();

        if (price <= 0) {
            revert PriceFeedInvalidPrice(token, priceFeed, price);
        }

        if (precise) {
            // Convert the chainlink price from 1e8 to 1e18.
            _spot = uint256(price * 1e10);
        } else {
            // Convert the chainlink price from 1e8 to 1e6.
            _spot = uint256(price / 1e2);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// TODO: Change me when deploying to GOERLI.
/// @dev USDC address.
address constant USDC = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);

/// @dev The square root of 2 PI in precise unit (1e18).
uint256 constant SQRT_TWO_PI = 2506628274631000502;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}