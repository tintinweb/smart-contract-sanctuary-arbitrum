// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../ConnectorRegistry.sol";
import "./RamsesV3Connector.sol";

import "../interfaces/external/ramses/IRamsesV2Pool.sol";
import "../interfaces/external/uniswap/IUniswapV3Factory.sol";

contract RamsesV3PoolRegistry is ICustomConnectorRegistry {
    IUniswapV3Factory public immutable factory;
    RamsesV3Connector public immutable connector;

    constructor(IUniswapV3Factory factory_, RamsesV3Connector connector_) {
        factory = factory_;
        connector = connector_;
    }

    function connectorOf(address target)
        external
        view
        override
        returns (address)
    {
        IRamsesV2Pool pool = IRamsesV2Pool(target);

        (bool success0, bytes memory returnData0) =
            address(pool).staticcall(abi.encodeWithSignature("token0()"));

        if (success0) {
            address token0 = abi.decode(returnData0, (address));

            (bool success1, bytes memory returnData1) =
                address(pool).staticcall(abi.encodeWithSignature("token1()"));

            if (success1) {
                address token1 = abi.decode(returnData1, (address));

                (bool successFee, bytes memory returnDataFee) =
                    address(pool).staticcall(abi.encodeWithSignature("fee()"));

                if (successFee) {
                    uint24 fee = abi.decode(returnDataFee, (uint24));

                    if (factory.getPool(token0, token1, fee) == target) {
                        return address(connector);
                    }
                }
            }
        }

        return address(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./base/Admin.sol";
import "./base/TimelockAdmin.sol";

error ConnectorNotRegistered(address target);

interface ICustomConnectorRegistry {
    function connectorOf(address target) external view returns (address);
}

contract ConnectorRegistry is Admin, TimelockAdmin {
    event ConnectorChanged(address target, address connector);
    event CustomRegistryAdded(address registry);
    event CustomRegistryRemoved(address registry);

    error ConnectorAlreadySet(address target);
    error ConnectorNotSet(address target);

    ICustomConnectorRegistry[] public customRegistries;
    mapping(ICustomConnectorRegistry => bool) public isCustomRegistry;

    mapping(address target => address connector) private connectors_;

    constructor(
        address admin_,
        address timelockAdmin_
    ) Admin(admin_) TimelockAdmin(timelockAdmin_) { }

    /// @notice Update connector addresses for a batch of targets.
    /// @dev Controls which connector contracts are used for the specified
    /// targets.
    /// @custom:access Restricted to protocol admin.
    function setConnectors(
        address[] calldata targets,
        address[] calldata connectors
    ) external onlyAdmin {
        for (uint256 i; i != targets.length;) {
            if (connectors_[targets[i]] != address(0)) {
                revert ConnectorAlreadySet(targets[i]);
            }
            connectors_[targets[i]] = connectors[i];
            emit ConnectorChanged(targets[i], connectors[i]);

            unchecked {
                ++i;
            }
        }
    }

    function updateConnectors(
        address[] calldata targets,
        address[] calldata connectors
    ) external onlyTimelockAdmin {
        for (uint256 i; i != targets.length;) {
            if (connectors_[targets[i]] == address(0)) {
                revert ConnectorNotSet(targets[i]);
            }
            connectors_[targets[i]] = connectors[i];
            emit ConnectorChanged(targets[i], connectors[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Append an address to the custom registries list.
    /// @custom:access Restricted to protocol admin.
    function addCustomRegistry(ICustomConnectorRegistry registry)
        external
        onlyAdmin
    {
        customRegistries.push(registry);
        isCustomRegistry[registry] = true;
        emit CustomRegistryAdded(address(registry));
    }

    /// @notice Replace an address in the custom registries list.
    /// @custom:access Restricted to protocol admin.
    function updateCustomRegistry(
        uint256 index,
        ICustomConnectorRegistry newRegistry
    ) external onlyTimelockAdmin {
        address oldRegistry = address(customRegistries[index]);
        isCustomRegistry[customRegistries[index]] = false;
        emit CustomRegistryRemoved(oldRegistry);
        customRegistries[index] = newRegistry;
        isCustomRegistry[newRegistry] = true;
        if (address(newRegistry) != address(0)) {
            emit CustomRegistryAdded(address(newRegistry));
        }
    }

    function connectorOf(address target) external view returns (address) {
        address connector = connectors_[target];
        if (connector != address(0)) {
            return connector;
        }

        uint256 length = customRegistries.length;
        for (uint256 i; i != length;) {
            if (address(customRegistries[i]) != address(0)) {
                try customRegistries[i].connectorOf(target) returns (
                    address _connector
                ) {
                    if (_connector != address(0)) {
                        return _connector;
                    }
                } catch {
                    // Ignore
                }
            }

            unchecked {
                ++i;
            }
        }

        revert ConnectorNotRegistered(target);
    }

    function hasConnector(address target) external view returns (bool) {
        if (connectors_[target] != address(0)) {
            return true;
        }

        uint256 length = customRegistries.length;
        for (uint256 i; i != length;) {
            if (address(customRegistries[i]) != address(0)) {
                try customRegistries[i].connectorOf(target) returns (
                    address _connector
                ) {
                    if (_connector != address(0)) {
                        return true;
                    }
                } catch {
                    // Ignore
                }

                unchecked {
                    ++i;
                }
            }
        }

        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ILiquidityConnector.sol";
import "../interfaces/IFarmConnector.sol";
import "../interfaces/external/ramses/IRamsesNonfungiblePositionManager.sol";
import "../interfaces/external/uniswap/ISwapRouter.sol";

struct NewPositionParams {
    int24 tickLower;
    int24 tickUpper;
    uint24 fee;
}

struct RamsesV3AddLiquidityExtraData {
    uint256 tokenId;
    bool isIncrease;
    NewPositionParams newPositionParams;
}

struct RamsesV3RemoveLiquidityExtraData {
    uint256 tokenId;
    uint128 liquidity;
    uint128 amount0Max;
    uint128 amount1Max;
}

struct RamsesV3SwapExtraData {
    address pool;
    bytes path;
}

struct RamsesV3ClaimExtraData {
    uint256 tokenId;
    address[] tokens;
    uint128 maxAmount0;
    uint128 maxAmount1;
}

contract RamsesV3Connector is ILiquidityConnector, IFarmConnector {
    constructor() { }

    function addLiquidity(AddLiquidityData memory addLiquidityData)
        external
        payable
        override
    {
        RamsesV3AddLiquidityExtraData memory extra = abi.decode(
            addLiquidityData.extraData, (RamsesV3AddLiquidityExtraData)
        );

        if (extra.isIncrease) {
            IRamsesNonfungiblePositionManager.IncreaseLiquidityParams memory
                params = IRamsesNonfungiblePositionManager
                    .IncreaseLiquidityParams({
                    tokenId: extra.tokenId,
                    amount0Desired: addLiquidityData.desiredAmounts[0],
                    amount1Desired: addLiquidityData.desiredAmounts[1],
                    amount0Min: addLiquidityData.minAmounts[0],
                    amount1Min: addLiquidityData.minAmounts[1],
                    deadline: block.timestamp + 1
                });

            IRamsesNonfungiblePositionManager(addLiquidityData.router)
                .increaseLiquidity(params);
        } else {
            IRamsesNonfungiblePositionManager.MintParams memory params =
            IRamsesNonfungiblePositionManager.MintParams({
                token0: addLiquidityData.tokens[0],
                token1: addLiquidityData.tokens[1],
                fee: extra.newPositionParams.fee,
                tickLower: extra.newPositionParams.tickLower,
                tickUpper: extra.newPositionParams.tickUpper,
                amount0Desired: addLiquidityData.desiredAmounts[0],
                amount1Desired: addLiquidityData.desiredAmounts[1],
                amount0Min: addLiquidityData.minAmounts[0],
                amount1Min: addLiquidityData.minAmounts[1],
                recipient: address(this),
                deadline: block.timestamp + 1,
                veRamTokenId: 0
            });

            IRamsesNonfungiblePositionManager(addLiquidityData.router).mint(
                params
            );
        }
    }

    function removeLiquidity(RemoveLiquidityData memory removeLiquidityData)
        external
        override
    {
        RamsesV3RemoveLiquidityExtraData memory extra = abi.decode(
            removeLiquidityData.extraData, (RamsesV3RemoveLiquidityExtraData)
        );

        if (extra.liquidity == type(uint128).max) {
            (,,,,,,, uint128 liquidity,,,,) = IRamsesNonfungiblePositionManager(
                removeLiquidityData.router
            ).positions(extra.tokenId);
            extra.liquidity = liquidity;
        }

        IRamsesNonfungiblePositionManager.DecreaseLiquidityParams memory params =
        IRamsesNonfungiblePositionManager.DecreaseLiquidityParams({
            tokenId: extra.tokenId,
            liquidity: extra.liquidity,
            amount0Min: removeLiquidityData.minAmountsOut[0],
            amount1Min: removeLiquidityData.minAmountsOut[1],
            deadline: block.timestamp + 1
        });

        IRamsesNonfungiblePositionManager(removeLiquidityData.router)
            .decreaseLiquidity(params);

        IRamsesNonfungiblePositionManager(removeLiquidityData.router).collect(
            IRamsesNonfungiblePositionManager.CollectParams({
                tokenId: extra.tokenId,
                recipient: address(this),
                amount0Max: extra.amount0Max,
                amount1Max: extra.amount1Max
            })
        );

        (,,,,,,, uint128 liquidityAfter,,,,) = IRamsesNonfungiblePositionManager(
            removeLiquidityData.router
        ).positions(extra.tokenId);

        if (liquidityAfter == 0) {
            IRamsesNonfungiblePositionManager(removeLiquidityData.router).burn(
                extra.tokenId
            );
        }
    }

    function swapExactTokensForTokens(SwapData memory swapData)
        external
        payable
        override
    {
        RamsesV3SwapExtraData memory extraData =
            abi.decode(swapData.extraData, (RamsesV3SwapExtraData));

        IERC20(swapData.tokenIn).approve(extraData.pool, swapData.amountIn);

        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
            path: extraData.path,
            recipient: address(this),
            deadline: block.timestamp + 1,
            amountIn: swapData.amountIn,
            amountOutMinimum: swapData.minAmountOut
        });

        ISwapRouter(swapData.router).exactInput(params);
    }

    function deposit(
        address target,
        address token,
        bytes memory extraData
    ) external payable override { }

    function withdraw(
        address target,
        uint256 amount,
        bytes memory extraData
    ) external override { }

    function claim(address target, bytes memory extraData) external override {
        RamsesV3ClaimExtraData memory data =
            abi.decode(extraData, (RamsesV3ClaimExtraData));
        IRamsesNonfungiblePositionManager(target).getReward(
            data.tokenId, data.tokens
        );
        if (data.maxAmount0 > 0 || data.maxAmount1 > 0) {
            IRamsesNonfungiblePositionManager.CollectParams memory params =
            IRamsesNonfungiblePositionManager.CollectParams({
                tokenId: data.tokenId,
                recipient: address(this),
                amount0Max: data.maxAmount0,
                amount1Max: data.maxAmount1
            });
            IRamsesNonfungiblePositionManager(target).collect(params);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "./IRamsesV2PoolImmutables.sol";
import "./IRamsesV2PoolState.sol";

/// @title The interface for a Ramses V2 Pool
/// @notice A Ramses pool facilitates swapping and automated market making
/// between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IRamsesV2Pool is IRamsesV2PoolImmutables, IRamsesV2PoolState {
    /// @notice Initializes a pool with parameters provided
    function initialize(
        address _factory,
        address _nfpManager,
        address _veRam,
        address _voter,
        address _token0,
        address _token1,
        uint24 _fee,
        int24 _tickSpacing
    ) external;

    function _advancePeriod() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and
/// control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in
    /// hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via
    /// the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or
    /// 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard
    /// coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns
    /// 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee,
    /// or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or
    /// token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in
    /// hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or
    /// token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee
    /// is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip
    /// (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all
    /// pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Admin contract
/// @author vfat.tools
/// @notice Provides an administration mechanism allowing restricted functions
abstract contract Admin {
    /// ERRORS ///

    /// @notice Thrown when the caller is not the admin
    error NotAdminError(); //0xb5c42b3b

    /// EVENTS ///

    /// @notice Emitted when a new admin is set
    /// @param oldAdmin Address of the old admin
    /// @param newAdmin Address of the new admin
    event AdminSet(address oldAdmin, address newAdmin);

    /// STORAGE ///

    /// @notice Address of the current admin
    address public admin;

    /// MODIFIERS ///

    /// @dev Restricts a function to the admin
    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdminError();
        _;
    }

    /// WRITE FUNCTIONS ///

    /// @param admin_ Address of the admin
    constructor(address admin_) {
        emit AdminSet(admin, admin_);
        admin = admin_;
    }

    /// @notice Sets a new admin
    /// @param newAdmin Address of the new admin
    /// @custom:access Restricted to protocol admin.
    function setAdmin(address newAdmin) external onlyAdmin {
        emit AdminSet(admin, newAdmin);
        admin = newAdmin;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title TimelockAdmin contract
/// @author vfat.tools
/// @notice Provides an timelockAdministration mechanism allowing restricted
/// functions
abstract contract TimelockAdmin {
    /// ERRORS ///

    /// @notice Thrown when the caller is not the timelockAdmin
    error NotTimelockAdminError();

    /// EVENTS ///

    /// @notice Emitted when a new timelockAdmin is set
    /// @param oldTimelockAdmin Address of the old timelockAdmin
    /// @param newTimelockAdmin Address of the new timelockAdmin
    event TimelockAdminSet(address oldTimelockAdmin, address newTimelockAdmin);

    /// STORAGE ///

    /// @notice Address of the current timelockAdmin
    address public timelockAdmin;

    /// MODIFIERS ///

    /// @dev Restricts a function to the timelockAdmin
    modifier onlyTimelockAdmin() {
        if (msg.sender != timelockAdmin) revert NotTimelockAdminError();
        _;
    }

    /// WRITE FUNCTIONS ///

    /// @param timelockAdmin_ Address of the timelockAdmin
    constructor(address timelockAdmin_) {
        emit TimelockAdminSet(timelockAdmin, timelockAdmin_);
        timelockAdmin = timelockAdmin_;
    }

    /// @notice Sets a new timelockAdmin
    /// @dev Can only be called by the current timelockAdmin
    /// @param newTimelockAdmin Address of the new timelockAdmin
    function setTimelockAdmin(address newTimelockAdmin)
        external
        onlyTimelockAdmin
    {
        emit TimelockAdminSet(timelockAdmin, newTimelockAdmin);
        timelockAdmin = newTimelockAdmin;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct AddLiquidityData {
    address router;
    address lpToken;
    address[] tokens;
    uint256[] desiredAmounts;
    uint256[] minAmounts;
    bytes extraData;
}

struct RemoveLiquidityData {
    address router;
    address lpToken;
    address[] tokens;
    uint256 lpAmountIn;
    uint256[] minAmountsOut;
    bytes extraData;
}

struct SwapData {
    address router;
    uint256 amountIn;
    uint256 minAmountOut;
    address tokenIn;
    bytes extraData;
}

interface ILiquidityConnector {
    function addLiquidity(AddLiquidityData memory addLiquidityData)
        external
        payable;

    function removeLiquidity(RemoveLiquidityData memory removeLiquidityData)
        external;

    function swapExactTokensForTokens(SwapData memory swapData)
        external
        payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFarmConnector {
    function deposit(
        address target,
        address token,
        bytes memory extraData
    ) external payable;

    function withdraw(
        address target,
        uint256 amount,
        bytes memory extraData
    ) external;

    function claim(address target, bytes memory extraData) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Non-fungible token for positions
/// @notice Wraps Ramses V2 positions in a non-fungible token interface which
/// allows for them to be transferred
/// and authorized.
interface IRamsesNonfungiblePositionManager {
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was
    /// increased
    /// @param amount0 The amount of token0 that was paid for the increase in
    /// liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in
    /// liquidity
    event IncreaseLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was
    /// decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease
    /// in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease
    /// in liquidity
    event DecreaseLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts
    /// transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were
    /// collected
    /// @param recipient The address of the account that received the collected
    /// tokens
    /// @param amount0 The amount of token0 owed to the position that was
    /// collected
    /// @param amount1 The amount of token1 owed to the position that was
    /// collected
    event Collect(
        uint256 indexed tokenId,
        address recipient,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when the attachment of an NFP is switched to a different
    /// veRam NFT.
    /// @param tokenId The identifier of the NFP for which the attachment is
    /// switched.
    /// @param oldVeRamTokenId The identifier of the previous veRam NFT to which
    /// the NFP was attached.
    /// @param newVeRamTokenId The identifier of the new veRam NFT to which the
    /// NFP was attached.
    event SwitchAttachment(
        uint256 indexed tokenId,
        uint256 oldVeRamTokenId,
        uint256 newVeRamTokenId
    );

    /// @notice The address of the veRam NFTs
    function veRam() external view returns (address);

    /// @notice Returns the position information associated with a given token
    /// ID.
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
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last
    /// action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last
    /// action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the
    /// position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the
    /// position as of the last computation
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
        uint256 veRamTokenId;
    }

    // details about the Ramses position
    struct Position {
        // the nonce for permits
        uint96 nonce;
        // the address that is approved for spending this token
        address operator;
        // the ID of the pool with which this token is connected
        uint80 poolId;
        // the tick range of the position
        int24 tickLower;
        int24 tickUpper;
        // the liquidity of the position
        uint128 liquidity;
        // the fee growth of the aggregate position as of the last action on the
        // individual position
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        // how many uncollected tokens are owed to the position, as of the last
        // computation
        uint128 tokensOwed0;
        uint128 tokensOwed1;
        // the veRam tokenId attached
        uint256 veRamTokenId;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if
    /// the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as
    /// `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens
    /// paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being
    /// increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a
    /// slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a
    /// slippage check,
    /// deadline The time by which the transaction must be included to effect
    /// the change
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

    /// @notice Decreases the amount of liquidity in a position and accounts it
    /// to the position
    /// @param params tokenId The ID of the token for which liquidity is being
    /// decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the
    /// burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the
    /// burned liquidity,
    /// deadline The time by which the transaction must be included to effect
    /// the change
    /// @return amount0 The amount of token0 accounted to the position's tokens
    /// owed
    /// @return amount1 The amount of token1 accounted to the position's tokens
    /// owed
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

    /// @notice Switches the attachment of a token to a different veRam NFT.
    /// @param tokenId The identifier of the NFP to switch attachment.
    /// @param veRamTokenId The identifier of the veRam NFT to attach.
    function switchAttachment(uint256 tokenId, uint256 veRamTokenId) external;

    /// @notice Collects up to a maximum amount of fees owed to a specific
    /// position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being
    /// collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The
    /// token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;

    function getReward(uint256 tokenId, address[] memory tokens) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter {
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

    /// @notice Swaps `amountIn` of one token for as much as possible of another
    /// token
    /// @param params The parameters necessary for the swap, encoded as
    /// `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another
    /// along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded
    /// as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

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

    /// @notice Swaps as little as possible of one token for `amountOut` of
    /// another token
    /// @param params The parameters necessary for the swap, encoded as
    /// `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of
    /// another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded
    /// as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods
/// will always return the same values
interface IRamsesV2PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the
    /// IRamsesV2Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The contract that manages RamsesV2 NFPs, which must adhere to
    /// the INonfungiblePositionManager interface
    /// @return The contract address
    function nfpManager() external view returns (address);

    /// @notice The contract that manages veRamses NFTs, which must adhere to
    /// the IVotinEscrow interface
    /// @return The contract address
    function veRam() external view returns (address);

    /// @notice The contract that manages Ramses votes, which must adhere to the
    /// IVoter interface
    /// @return The contract address
    function voter() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee the pool was initialized with
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and
    /// always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick,
    /// i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always
    /// positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick
    /// in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from
    /// overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding
    /// in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);

    /// @notice returns the current fee set for the pool
    function currentFee() external view returns (uint24);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any
/// frequency including multiple times
/// per transaction
interface IRamsesV2PoolState {
    /// @notice reads arbitrary storage slots and returns the bytes
    /// @param slots The slots to read from
    /// @return returnData The data read from the slots
    function readStorage(bytes32[] calldata slots)
        external
        view
        returns (bytes32[] memory returnData);

    /// @notice The 0th storage slot in the pool stores many values, and is
    /// exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a
    /// sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick
    /// transition that was run.
    /// This value may not always be equal to
    /// SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was
    /// written,
    /// observationCardinality The current maximum number of observations stored
    /// in the pool,
    /// observationCardinalityNext The next maximum number of observations, to
    /// be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted
    /// 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap
    /// fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice Returns the last tick of a given period
    /// @param period The period in question
    /// @return previousPeriod The period before current period
    /// @dev this is because there might be periods without trades
    ///  startTick The start tick of the period
    ///  lastTick The last tick of the period, if the period is finished
    ///  endSecondsPerLiquidityPeriodX128 Seconds per liquidity at period's end
    ///  endSecondsPerBoostedLiquidityPeriodX128 Seconds per boosted liquidity
    /// at period's end
    function periods(uint256 period)
        external
        view
        returns (
            uint32 previousPeriod,
            int24 startTick,
            int24 lastTick,
            uint160 endSecondsPerLiquidityCumulativeX128,
            uint160 endSecondsPerBoostedLiquidityCumulativeX128,
            uint32 boostedInRange
        );

    /// @notice The last period where a trade or liquidity change happened
    function lastPeriod() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit
    /// of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit
    /// of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees()
        external
        view
        returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all
    /// ticks
    function liquidity() external view returns (uint128);

    /// @notice The currently in range derived liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all
    /// ticks
    function boostedLiquidity() external view returns (uint128);

    /// @notice Get the boost information for a specific position at a period
    /// @return boostAmount the amount of boost this position has for this
    /// period,
    /// veRamAmount the amount of veRam attached to this position for this
    /// period,
    /// secondsDebtX96 used to account for changes in the deposit amount during
    /// the period
    /// boostedSecondsDebtX96 used to account for changes in the boostAmount and
    /// veRam locked during the period,
    function boostInfos(
        uint256 period,
        bytes32 key
    )
        external
        view
        returns (
            uint128 boostAmount,
            int128 veRamAmount,
            int256 secondsDebtX96,
            int256 boostedSecondsDebtX96
        );

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses
    /// the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the
    /// tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from
    /// the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from
    /// the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the
    /// tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the
    /// other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the
    /// current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross
    /// is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if
    /// liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in
    /// comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint128 boostedLiquidityGross,
            int128 boostedLiquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See
    /// TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the
    /// owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick
    /// range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick
    /// range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position
    /// as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position
    /// as of the last mint/burn/poke
    /// Returns attachedVeRamId the veRam tokenId attached to the position
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1,
            uint256 attachedVeRamId
        );

    /// @notice Returns a period's total boost amount and total veRam attached
    /// @param period Period timestamp
    /// @return totalBoostAmount The total amount of boost this period has,
    /// Returns totalVeRamAmount The total amount of veRam attached to this
    /// period
    function boostInfos(uint256 period)
        external
        view
        returns (uint128 totalBoostAmount, int128 totalVeRamAmount);

    /// @notice Get the period seconds debt of a specific position
    /// @param period the period number
    /// @param recipient recipient address
    /// @param index position index
    /// @param tickLower lower bound of range
    /// @param tickUpper upper bound of range
    /// @return secondsDebtX96 seconds the position was not in range for the
    /// period
    /// @return boostedSecondsDebtX96 boosted seconds the period
    function positionPeriodDebt(
        uint256 period,
        address recipient,
        uint256 index,
        int24 tickLower,
        int24 tickUpper
    )
        external
        view
        returns (int256 secondsDebtX96, int256 boostedSecondsDebtX96);

    /// @notice get the period seconds in range of a specific position
    /// @param period the period number
    /// @param owner owner address
    /// @param index position index
    /// @param tickLower lower bound of range
    /// @param tickUpper upper bound of range
    /// @return periodSecondsInsideX96 seconds the position was not in range for
    /// the period
    /// @return periodBoostedSecondsInsideX96 boosted seconds the period
    function positionPeriodSecondsInRange(
        uint256 period,
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper
    )
        external
        view
        returns (
            uint256 periodSecondsInsideX96,
            uint256 periodBoostedSecondsInsideX96
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to
    /// get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the
    /// life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range
    /// liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the
    /// values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized,
            uint160 secondsPerBoostedLiquidityPeriodX128
        );
}