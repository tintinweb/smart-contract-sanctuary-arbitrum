// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../ConnectorRegistry.sol";
import "./RamsesGaugeConnector.sol";
import "./RamsesV3Connector.sol";
import { IGaugeRegistryVoter } from "./GaugeRegistry.sol";
import { IGaugeV2 } from "../interfaces/external/ramses/IGaugeV2.sol";

interface IRamsesPairFactory {
    function isPair(address pair) external view returns (bool);
}

contract RamsesGaugeRegistry is ICustomConnectorRegistry {
    IGaugeRegistryVoter public immutable voter;
    RamsesGaugeConnector public immutable ramsesGaugeConnector;
    IRamsesPairFactory public immutable ramsesPairFactory;
    RamsesV3Connector public immutable ramsesV3Connector;
    address public immutable ramsesCLGaugeFactory;

    constructor(
        IGaugeRegistryVoter voter_,
        RamsesGaugeConnector ramsesGaugeConnector_,
        IRamsesPairFactory ramsesPairFactory_,
        RamsesV3Connector ramsesV3Connector_,
        address ramsesCLGaugeFactory_
    ) {
        voter = voter_;
        ramsesGaugeConnector = ramsesGaugeConnector_;
        ramsesPairFactory = ramsesPairFactory_;
        ramsesV3Connector = ramsesV3Connector_;
        ramsesCLGaugeFactory = ramsesCLGaugeFactory_;
    }

    function connectorOf(address target)
        external
        view
        override
        returns (address)
    {
        if (voter.isGauge(target)) {
            if (ramsesPairFactory.isPair(voter.poolForGauge(target))) {
                return address(ramsesGaugeConnector);
            }
            address gaugeFactory = IGaugeV2(target).gaugeFactory();
            if (gaugeFactory == ramsesCLGaugeFactory) {
                return address(ramsesV3Connector);
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

import "../interfaces/IFarmConnector.sol";
import "../interfaces/external/ramses/IRamsesGauge.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";

struct RamsesClaimExtraData {
    address[] rewardTokens;
}

contract RamsesGaugeConnector is IFarmConnector {
    function deposit(
        address target,
        address token,
        bytes memory // _extraData
    ) external payable override {
        uint256 amount = IERC20(token).balanceOf(address(this));
        SafeTransferLib.safeApprove(token, target, amount);
        IRamsesGauge(target).deposit(amount, 0);
    }

    function withdraw(
        address target,
        uint256 amount,
        bytes memory // _extraData
    ) external override {
        IRamsesGauge(target).withdraw(amount);
    }

    function claim(address target, bytes memory _extraData) external override {
        RamsesClaimExtraData memory extraData =
            abi.decode(_extraData, (RamsesClaimExtraData));
        IRamsesGauge(target).claimFees();
        IRamsesGauge(target).getReward(address(this), extraData.rewardTokens);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../ConnectorRegistry.sol";

interface IGaugeRegistryVoter {
    function isGauge(address target) external view returns (bool);

    function poolForGauge(address gauge) external view returns (address);
}

contract GaugeRegistry is ICustomConnectorRegistry {
    IGaugeRegistryVoter public immutable voter;
    address public immutable connector;

    constructor(IGaugeRegistryVoter voter_, address connector_) {
        voter = voter_;
        connector = connector_;
    }

    function connectorOf(address target)
        external
        view
        override
        returns (address)
    {
        if (voter.isGauge(target)) {
            return connector;
        }

        return address(0);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0 <0.9.0;

interface IGaugeV2 {
    /// @notice Emitted when a reward notification is made.
    /// @param from The address from which the reward is notified.
    /// @param reward The address of the reward token.
    /// @param amount The amount of rewards notified.
    /// @param period The period for which the rewards are notified.
    event NotifyReward(
        address indexed from,
        address indexed reward,
        uint256 amount,
        uint256 period
    );

    /// @notice Emitted when a bribe is made.
    /// @param from The address from which the bribe is made.
    /// @param reward The address of the reward token.
    /// @param amount The amount of tokens bribed.
    /// @param period The period for which the bribe is made.
    event Bribe(
        address indexed from,
        address indexed reward,
        uint256 amount,
        uint256 period
    );

    /// @notice Emitted when rewards are claimed.
    /// @param period The period for which the rewards are claimed.
    /// @param _positionHash The identifier of the NFP for which rewards are
    /// claimed.
    /// @param receiver The address of the receiver of the claimed rewards.
    /// @param reward The address of the reward token.
    /// @param amount The amount of rewards claimed.
    event ClaimRewards(
        uint256 period,
        bytes32 _positionHash,
        address receiver,
        address reward,
        uint256 amount
    );

    /// @notice Emitted when a new reward token was pushed to the rewards array
    event RewardAdded(address reward);

    /// @notice Emitted when a reward token was removed from the rewards array
    event RewardRemoved(address reward);

    /// @notice Initializes the contract with the provided gaugeFactory, voter,
    /// and pool addresses.
    /// @param _gaugeFactory The address of the gaugeFactory to set.
    /// @param _voter The address of the voter to set.
    /// @param _nfpManager The address of the NFP manager to set.
    /// @param _feeCollector The address of the fee collector to set.
    /// @param _pool The address of the pool to set.
    function initialize(
        address _gaugeFactory,
        address _voter,
        address _nfpManager,
        address _feeCollector,
        address _pool
    ) external;

    /// @notice Retrieves the value of the firstPeriod variable.
    /// @return The value of the firstPeriod variable.
    function firstPeriod() external returns (uint256);

    /// @notice Retrieves the total supply of a specific token for a given
    /// period.
    /// @param period The period for which to retrieve the total supply.
    /// @param token The address of the token for which to retrieve the total
    /// supply.
    /// @return The total supply of the specified token for the given period.
    function tokenTotalSupplyByPeriod(
        uint256 period,
        address token
    ) external view returns (uint256);

    /// @notice Retrieves the total boosted seconds for a specific period.
    /// @param period The period for which to retrieve the total boosted
    /// seconds.
    /// @return The total boosted seconds for the specified period.
    function periodTotalBoostedSeconds(uint256 period)
        external
        view
        returns (uint256);

    /// @notice Retrieves the getTokenTotalSupplyByPeriod of the current period.
    /// @dev included to support voter's left() check during distribute().
    /// @param token The address of the token for which to retrieve the
    /// remaining amount.
    /// @return The amount of tokens left to distribute in this period.
    function left(address token) external view returns (uint256);

    /// @notice Retrieves the reward rate for a specific reward address.
    /// @dev this method returns the base rate without boost
    /// @param token The address of the reward for which to retrieve the reward
    /// rate.
    /// @return The reward rate for the specified reward address.
    function rewardRate(address token) external view returns (uint256);

    /// @notice Retrieves the claimed amount for a specific period, position
    /// hash, and user address.
    /// @param period The period for which to retrieve the claimed amount.
    /// @param _positionHash The identifier of the NFP for which to retrieve the
    /// claimed amount.
    /// @param reward The address of the token for the claimed amount.
    /// @return The claimed amount for the specified period, token ID, and user
    /// address.
    function periodClaimedAmount(
        uint256 period,
        bytes32 _positionHash,
        address reward
    ) external view returns (uint256);

    /// @notice Retrieves the last claimed period for a specific token, token ID
    /// combination.
    /// @param token The address of the reward token for which to retrieve the
    /// last claimed period.
    /// @param _positionHash The identifier of the NFP for which to retrieve the
    /// last claimed period.
    /// @return The last claimed period for the specified token and token ID.
    function lastClaimByToken(
        address token,
        bytes32 _positionHash
    ) external view returns (uint256);

    /// @notice Retrieves the reward address at the specified index in the
    /// rewards array.
    /// @param index The index of the reward address to retrieve.
    /// @return The reward address at the specified index.
    function rewards(uint256 index) external view returns (address);

    /// @notice Checks if a given address is a valid reward.
    /// @param reward The address to check.
    /// @return A boolean indicating whether the address is a valid reward.
    function isReward(address reward) external view returns (bool);

    /// @notice Returns an array of reward token addresses.
    /// @return An array of reward token addresses.
    function getRewardTokens() external view returns (address[] memory);

    /// @notice Returns the hash used to store positions in a mapping
    /// @param owner The address of the position owner
    /// @param index The index of the position
    /// @param tickLower The lower tick boundary of the position
    /// @param tickUpper The upper tick boundary of the position
    /// @return _hash The hash used to store positions in a mapping
    function positionHash(
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper
    ) external pure returns (bytes32);

    /// @notice Retrieves the liquidity and boosted liquidity for a specific
    /// NFP.
    /// @param tokenId The identifier of the NFP.
    /// @return liquidity The liquidity of the position token.
    /// @return boostedLiquidity The boosted liquidity of the position token.
    /// @return veRamTokenId The attached veRam token
    function positionInfo(uint256 tokenId)
        external
        view
        returns (
            uint128 liquidity,
            uint128 boostedLiquidity,
            uint256 veRamTokenId
        );

    /// @notice Returns the amount of rewards earned for an NFP.
    /// @param token The address of the token for which to retrieve the earned
    /// rewards.
    /// @param tokenId The identifier of the specific NFP for which to retrieve
    /// the earned rewards.
    /// @return reward The amount of rewards earned for the specified NFP and
    /// tokens.
    function earned(
        address token,
        uint256 tokenId
    ) external view returns (uint256 reward);

    /// @notice Returns the amount of rewards earned during a period for an NFP.
    /// @param period The period for which to retrieve the earned rewards.
    /// @param token The address of the token for which to retrieve the earned
    /// rewards.
    /// @param tokenId The identifier of the specific NFP for which to retrieve
    /// the earned rewards.
    /// @return reward The amount of rewards earned for the specified NFP and
    /// tokens.
    function periodEarned(
        uint256 period,
        address token,
        uint256 tokenId
    ) external view returns (uint256);

    /// @notice Retrieves the earned rewards for a specific period, token,
    /// owner, index, tickLower, and tickUpper.
    /// @param period The period for which to retrieve the earned rewards.
    /// @param token The address of the token for which to retrieve the earned
    /// rewards.
    /// @param owner The address of the owner for which to retrieve the earned
    /// rewards.
    /// @param index The index for which to retrieve the earned rewards.
    /// @param tickLower The tick lower bound for which to retrieve the earned
    /// rewards.
    /// @param tickUpper The tick upper bound for which to retrieve the earned
    /// rewards.
    /// @return The earned rewards for the specified period, token, owner,
    /// index, tickLower, and tickUpper.
    function periodEarned(
        uint256 period,
        address token,
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper
    ) external view returns (uint256);

    /// @notice Retrieves the earned rewards for a specific period, token,
    /// owner, index, tickLower, and tickUpper.
    /// @dev used by getReward() and saves gas by saving states
    /// @param period The period for which to retrieve the earned rewards.
    /// @param token The address of the token for which to retrieve the earned
    /// rewards.
    /// @param owner The address of the owner for which to retrieve the earned
    /// rewards.
    /// @param index The index for which to retrieve the earned rewards.
    /// @param tickLower The tick lower bound for which to retrieve the earned
    /// rewards.
    /// @param tickUpper The tick upper bound for which to retrieve the earned
    /// rewards.
    /// @param caching Whether to cache the results or not.
    /// @return The earned rewards for the specified period, token, owner,
    /// index, tickLower, and tickUpper.
    function cachePeriodEarned(
        uint256 period,
        address token,
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        bool caching
    ) external returns (uint256);

    /// @notice Notifies the contract about the amount of rewards to be
    /// distributed for a specific token.
    /// @param token The address of the token for which to notify the reward
    /// amount.
    /// @param amount The amount of rewards to be distributed.
    function notifyRewardAmount(address token, uint256 amount) external;

    /// @notice Retrieves the reward amount for a specific period, NFP, and
    /// token addresses.
    /// @param period The period for which to retrieve the reward amount.
    /// @param tokens The addresses of the tokens for which to retrieve the
    /// reward amount.
    /// @param tokenId The identifier of the specific NFP for which to retrieve
    /// the reward amount.
    /// @param receiver The address of the receiver of the reward amount.
    function getPeriodReward(
        uint256 period,
        address[] calldata tokens,
        uint256 tokenId,
        address receiver
    ) external;

    /// @notice Retrieves the rewards for a specific period, set of tokens,
    /// owner, index, tickLower, tickUpper, and receiver.
    /// @param period The period for which to retrieve the rewards.
    /// @param tokens An array of token addresses for which to retrieve the
    /// rewards.
    /// @param owner The address of the owner for which to retrieve the rewards.
    /// @param index The index for which to retrieve the rewards.
    /// @param tickLower The tick lower bound for which to retrieve the rewards.
    /// @param tickUpper The tick upper bound for which to retrieve the rewards.
    /// @param receiver The address of the receiver of the rewards.
    function getPeriodReward(
        uint256 period,
        address[] calldata tokens,
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        address receiver
    ) external;

    function addRewards(address reward) external;

    function removeRewards(address reward) external;

    function getRewardForOwner(
        uint256 tokenId,
        address[] memory tokens
    ) external;

    function getReward(uint256 tokenId, address[] memory tokens) external;

    /// @notice Notifies rewards for periods greater than current period
    /// @dev does not push fees
    /// @dev requires reward token to be whitelisted
    function notifyRewardAmountForPeriod(
        address token,
        uint256 amount,
        uint256 period
    ) external;

    /// @notice Notifies rewards for the next period
    /// @dev does not push fees
    /// @dev requires reward token to be whitelisted
    function notifyRewardAmountNextPeriod(
        address token,
        uint256 amount
    ) external;

    function gaugeFactory() external view returns (address);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IRamsesGauge {
    function notifyRewardAmount(address token, uint256 amount) external;

    function getReward(address account, address[] memory tokens) external;

    function claimFees()
        external
        returns (uint256 claimed0, uint256 claimed1);

    function left(address token) external view returns (uint256);

    function isForPair() external view returns (bool);

    function whitelistNotifiedRewards(address token) external;

    function removeRewardWhitelist(address token) external;

    function rewardsListLength() external view returns (uint256);

    function rewards(uint256 index) external view returns (address);

    function earned(
        address token,
        address account
    ) external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function derivedBalances(address) external view returns (uint256);

    function rewardRate(address) external view returns (uint256);

    function deposit(uint256 amount, uint256 tokenId) external;

    function withdraw(uint256 amount) external;
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error ETHTransferFailed();
    error TransferFromFailed();
    error TransferFailed();
    error ApproveFailed();

    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        if (!success) revert ETHTransferFailed();
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        if (!success) revert TransferFromFailed();
    }

    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        if (!success) revert TransferFailed();
    }

    function safeApprove(
        address token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        if (!success) revert ApproveFailed();
    }
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