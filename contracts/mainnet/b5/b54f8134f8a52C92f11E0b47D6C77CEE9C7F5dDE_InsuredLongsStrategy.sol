//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import {IAtlanticPutsPool} from "../../atlantic-pools/interfaces/IAtlanticPutsPool.sol";
import {IRouter} from "../../external/gmx/interfaces-modified/IRouter.sol";
import {IVault} from "../../external/gmx/interfaces-modified/IVault.sol";
import {IERC20} from "../../interfaces/IERC20.sol";
import {IDopexPositionManager, IncreaseOrderParams, DecreaseOrderParams} from "./interfaces/IDopexPositionManager.sol";
import {IInsuredLongsUtils} from "./interfaces/IInsuredLongsUtils.sol";
import {IInsuredLongsStrategy} from "./interfaces/IInsuredLongsStrategy.sol";
import {IDopexPositionManagerFactory} from "./interfaces/IDopexPositionManagerFactory.sol";
import {ICallbackForwarder} from "./interfaces/ICallbackForwarder.sol";
import {IDopexFeeStrategy} from "../../fees/interfaces/IDopexFeeStrategy.sol";

import {SafeERC20} from "../../libraries/SafeERC20.sol";
import {Pausable} from "../../helpers/Pausable.sol";
import {ContractWhitelist} from "../../helpers/ContractWhitelist.sol";
import {ReentrancyGuard} from "../../helpers/ReentrancyGuard.sol";

contract InsuredLongsStrategy is
    ContractWhitelist,
    Pausable,
    ReentrancyGuard,
    IInsuredLongsStrategy
{
    using SafeERC20 for IERC20;

    uint256 private constant BPS_PRECISION = 100000;
    uint256 private constant STRATEGY_FEE_KEY = 3;
    uint256 public positionsCount = 1;

    /**
     * @notice Time window in which whitelisted keeper can settle positions.
     */
    uint256 public keeperHandleWindow;

    uint256 public maxLeverage;

    /**
     * @notice Multiplier Bps used to calculate extra amount of
     *         collateral required to exist in a long position such
     *         that it has enough to be unwinded back to its
     *         respective atlantic pool if the position has borrowed
     *         collateral and mark price has decreased way below
     *         liquidation price.
     */
    uint256 public liquidationCollateralMultiplierBps;

    mapping(uint256 => StrategyPosition) public strategyPositions;

    /**
     * @notice Orders after created are saved here and used in
     *         gmxPositionCallback() for reference when a order
     *         is executed.
     */
    mapping(bytes32 => uint256) public pendingOrders;

    /**
     * @notice ID of the strategy position belonging to a user.
     */
    mapping(address => uint256) public userPositionIds;

    /**
     * @notice A multiplier applied to an atlantic pool's ticksize
     *         when calculating liquidation price. This multiplier
     *         summed up with liquidation price gives a price suitable
     *         for insuring the long position.
     *
     *         same Offset bps will be applied to strike price which acts
     *         as threshold to persist unlocked collateral in the
     *         long position. If mark price of the index token
     *         crosses this trigger price (strike + offsetBps)
     *         collateral will be removed from the long position
     *         and relocked back into the atlantic pool that it
     *         was borrowed from.
     */
    mapping(address => uint256) public tickSizeMultiplierBps;

    /**
     * @notice Keepers are EOA or contracts that will have special
     *         permissions required to carry out insurance related
     *         functions available in this contract.
     *         1. Create a order to add collateral to a position.
     *         2. Create a order to remove collateral from a position.
     *         3. Create a order to exit a position.
     */
    mapping(address => bool) public whitelistedKeepers;

    /**
     * @notice Number of positions active (not settled.)
     *         if it is equal to zero then contract is allowed
     *         to withdraw fee tokens.
     */
    uint256 public activePositions;

    /**
     * @notice Atlantic Put pools that can be used by this strategy contract
     *         for purchasing put options, unlocking, relocking and unwinding of
     *         collateral.
     */
    mapping(bytes32 => address) public whitelistedAtlanticPools;

    mapping(address => bool) public whitelistedUsers;

    mapping(uint256 => address) public pendingStrategyPositionToken;

    address public positionRouter;
    address public router;
    address public vault;
    address public feeDistributor;
    address public gov;
    IDopexFeeStrategy public feeStrategy;

    bool public whitelistMode = true;
    bool public useDiscountForFees = true;

    /**
     *  @notice Index token supported by this strategy contract.
     */
    address public strategyIndexToken;

    IInsuredLongsUtils public utils;
    IDopexPositionManagerFactory public positionManagerFactory;

    constructor(
        address _vault,
        address _positionRouter,
        address _router,
        address _positionManagerFactory,
        address _feeDistributor,
        address _utils,
        address _gov,
        address _indexToken,
        address _feeStrategy
    ) {
        utils = IInsuredLongsUtils(_utils);
        positionManagerFactory = IDopexPositionManagerFactory(
            _positionManagerFactory
        );
        positionRouter = _positionRouter;
        router = _router;
        vault = _vault;
        feeDistributor = _feeDistributor;
        gov = _gov;
        strategyIndexToken = _indexToken;
        liquidationCollateralMultiplierBps = 300;
        feeStrategy = IDopexFeeStrategy(_feeStrategy);
    }

    /**
     * @notice Reuse strategy for a position manager that has an active
     *         gmx position.
     *
     * @param _positionId     ID of the position in strategyPositions mapping
     * @param _expiry         Expiry of the insurance
     * @param _keepCollateral Whether to deposit underlying to allow unwinding
     *                        of options
     */
    function reuseStrategy(
        uint256 _positionId,
        uint256 _expiry,
        bool _keepCollateral
    ) external onlyWhitelistedUser {
        _isEligibleSender();
        _whenNotPaused();

        StrategyPosition memory position = strategyPositions[_positionId];

        address userPositionManager = userPositionManagers(msg.sender);

        _validate(position.atlanticsPurchaseId == 0, 28);
        _validate(msg.sender == position.user, 27);
        _validate(
            utils.getPositionLeverage(
                userPositionManager,
                position.indexToken
            ) <= maxLeverage,
            30
        );

        uint256 positionSize = utils.getPositionSize(
            userPositionManager,
            position.indexToken
        );

        _validate(positionSize > 0, 5);

        IDopexPositionManager(userPositionManager).lock();

        position.expiry = _expiry;
        position.keepCollateral = _keepCollateral;

        strategyPositions[_positionId] = position;

        // Collect strategy position fee
        _collectPositionFee(
            positionSize,
            position.collateralToken,
            position.indexToken
        );

        unchecked {
            ++activePositions;
        }

        _enableStrategy(_positionId);

        emit ReuseStrategy(_positionId);
    }

    /**
     * @notice                 Create strategy postiion and create long position order
     * @param _increaseOrder   Parameters related to the long position to open
     * @param _collateralToken Address of the collateral token. Also to refer to
     *                         atlantic pool to buy puts from
     * @param _expiry          Timestamp of expiry for selecting a atlantic pool
     * @param _keepCollateral  Deposit underlying to keep collateral if position
     *                         is left increased before expiry
     */
    function useStrategyAndOpenLongPosition(
        IncreaseOrderParams calldata _increaseOrder,
        address _collateralToken,
        uint256 _expiry,
        bool _keepCollateral
    ) external payable onlyWhitelistedUser nonReentrant {
        _whenNotPaused();
        _isEligibleSender();

        // Only longs are accepted
        _validate(_increaseOrder.isLong, 0);
        _validate(_increaseOrder.indexToken == strategyIndexToken, 1);
        _validate(
            _increaseOrder.path[_increaseOrder.path.length - 1] ==
                strategyIndexToken,
            1
        );

        // Collateral token and path[0] must be the same
        if (_increaseOrder.path.length > 1) {
            _validate(_collateralToken == _increaseOrder.path[0], 16);
        }

        // Must have enough collateral for fees
        _validate(
            !utils.validateIncreaseExecution(
                _increaseOrder.collateralDelta,
                _increaseOrder.positionSizeDelta,
                _increaseOrder.path[0],
                _increaseOrder.indexToken
            ),
            17
        );

        // Must to exceed max leverage
        _validate(
            utils.calculateLeverage(
                _increaseOrder.positionSizeDelta,
                _increaseOrder.collateralDelta,
                _increaseOrder.path[0]
            ) <= maxLeverage,
            30
        );

        address userPositionManager = userPositionManagers(msg.sender);
        uint256 userPositionId = userPositionIds[msg.sender];

        // Should not have open positions
        _validate(
            utils.getPositionSize(
                userPositionManager,
                _increaseOrder.indexToken
            ) == 0,
            29
        );

        // If position ID and manager is already created for the user, ensure it's a settled one
        _validate(
            strategyPositions[userPositionId].atlanticsPurchaseId == 0,
            9
        );

        _validate(
            _getAtlanticPoolAddress(
                _increaseOrder.indexToken,
                _collateralToken,
                _expiry
            ) != address(0),
            8
        );

        unchecked {
            ++activePositions;
        }

        // If position "state" is already created, use existing one or create new
        if (userPositionId == 0) {
            userPositionId = positionsCount;
            unchecked {
                ++positionsCount;
            }

            _newStrategyPosition(
                userPositionId,
                _expiry,
                _increaseOrder.indexToken,
                _collateralToken,
                _keepCollateral
            );
            userPositionIds[msg.sender] = userPositionId;
        } else {
            _newStrategyPosition(
                userPositionId,
                _expiry,
                _increaseOrder.indexToken,
                _collateralToken,
                _keepCollateral
            );
        }

        // if a position manager is not created for the user, create one or use existing one
        if (userPositionManager == address(0)) {
            userPositionManager = positionManagerFactory.createPositionmanager(
                msg.sender
            );
        }

        _safeTransferFrom(
            _increaseOrder.path[0],
            msg.sender,
            userPositionManager,
            _increaseOrder.collateralDelta
        );

        // Create increase order for long position
        IDopexPositionManager(userPositionManager).enableAndCreateIncreaseOrder{
            value: msg.value
        }(_increaseOrder, vault, router, positionRouter, msg.sender);

        pendingOrders[
            utils.getPositionKey(userPositionManager, true)
        ] = userPositionId;

        // Collect strategy position fee
        if (_increaseOrder.path.length > 1) {
            _collectPositionFee(
                _increaseOrder.positionSizeDelta,
                _increaseOrder.path[0],
                _increaseOrder.path[_increaseOrder.path.length - 1]
            );
        } else {
            _collectPositionFee(
                _increaseOrder.positionSizeDelta,
                _increaseOrder.path[0],
                _collateralToken
            );
        }

        emit UseStrategy(userPositionId);
    }

    /**
     * @notice Enable keepCollateral state of the strategy position
     *         such allowing users to keep their long positions post
     *         expiry of the atlantic put from which options were purch-
     *         -ased from.
     */
    function enableKeepCollateral(uint256 _positionId) external {
        _isEligibleSender();
        StrategyPosition memory position = strategyPositions[_positionId];

        _validate(position.user == msg.sender, 27);
        _validate(position.state != ActionState.Settled, 3);
        // Must be an active position with insurance
        _validate(position.atlanticsPurchaseId != 0, 19);
        _validate(!position.keepCollateral, 18);

        uint256 unwindCost = utils.getAtlanticUnwindCosts(
            _getAtlanticPoolAddress(
                position.indexToken,
                position.collateralToken,
                position.expiry
            ),
            position.atlanticsPurchaseId,
            false
        );

        _safeTransferFrom(
            position.indexToken,
            msg.sender,
            address(this),
            unwindCost
        );

        strategyPositions[_positionId].keepCollateral = true;
        emit KeepCollateralEnabled(_positionId);
    }

    /**
     * @notice            Create a order to add collateral to managed long gmx position
     * @param _positionId ID of the strategy position in strategyPositions Mapping
     */
    function createIncreaseManagedPositionOrder(
        uint256 _positionId
    ) external payable {
        // Only whitelisted keepers are allowed to execute
        _validate(whitelistedKeepers[msg.sender], 2);

        StrategyPosition memory position = strategyPositions[_positionId];

        _validate(position.atlanticsPurchaseId != 0, 19);
        _validate(position.state != ActionState.Increased, 4);

        address positionManager = userPositionManagers(position.user);
        IAtlanticPutsPool pool = IAtlanticPutsPool(
            _getAtlanticPoolAddress(
                position.indexToken,
                position.collateralToken,
                position.expiry
            )
        );

        uint256 collateralUnlocked = utils.getCollateralAccess(
            address(pool),
            position.atlanticsPurchaseId
        );

        uint256 fundingFees = pool.calculateFundingFees(
            position.user,
            collateralUnlocked
        );

        // Skip unlocking if collateral already unlocked
        if (ActionState.IncreasePending != position.state) {
            _safeTransferFrom(
                position.collateralToken,
                position.user,
                address(this),
                fundingFees
            );

            // Unlock collateral from atlantic pool
            pool.unlockCollateral(
                position.atlanticsPurchaseId,
                positionManager,
                position.user
            );
        }

        // Create order to add unlocked collateral
        IDopexPositionManager(positionManager).increaseOrder{value: msg.value}(
            IncreaseOrderParams(
                utils.get2TokenSwapPath(
                    position.collateralToken,
                    position.indexToken
                ),
                position.indexToken,
                collateralUnlocked,
                0,
                0,
                true
            )
        );

        strategyPositions[_positionId].state = ActionState.IncreasePending;
        pendingOrders[
            utils.getPositionKey(positionManager, true)
        ] = _positionId;

        emit ManagedPositionIncreaseOrderSuccess(_positionId);
    }

    /**
     * @notice            Create a order to exit from strategy and long gmx position
     * @param _positionId ID of the strategy position in strategyPositions Mapping
     */
    function createExitStrategyOrder(
        uint256 _positionId,
        bool exitLongPosition
    ) external payable nonReentrant {
        StrategyPosition memory position = strategyPositions[_positionId];

        _updateGmxVaultCummulativeFundingRate(position.indexToken);

        _validate(position.atlanticsPurchaseId != 0, 19);

        // Keeper can only call during keeperHandleWindow before expiry
        if (msg.sender != position.user) {
            _validate(whitelistedKeepers[msg.sender], 2);
            if (!_isKeeperHandleWindow(position.expiry)) {
                _validate(isManagedPositionLiquidatable(_positionId), 21);
            }
        }
        _validate(position.state != ActionState.Settled, 3);

        address positionManager = userPositionManagers(position.user);

        address[] memory swapPath = isManagedPositionDecreasable(_positionId)
            ? utils.get2TokenSwapPath(
                position.indexToken,
                position.collateralToken
            )
            : utils.get1TokenSwapPath(position.indexToken);

        uint256 sizeDelta = exitLongPosition
            ? utils.getPositionSize(positionManager, position.indexToken)
            : 0;

        uint256 collateralDelta;
        // if position has borrowed collateral and user wishes to exit
        if (position.state == ActionState.Increased && !exitLongPosition) {
            collateralDelta = IVault(vault).tokenToUsdMin(
                swapPath[0],
                utils.getAmountIn(
                    utils.getCollateralAccess(
                        _getAtlanticPoolAddress(
                            position.indexToken,
                            position.collateralToken,
                            position.expiry
                        ),
                        position.atlanticsPurchaseId
                    ) +
                        utils.getMarginFees(
                            positionManager,
                            position.indexToken,
                            position.collateralToken
                        ),
                    IDopexPositionManager(positionManager).minSlippageBps(),
                    position.collateralToken,
                    position.indexToken
                )
            );
        }

        if (collateralDelta > 0) {
            _validate(
                utils.validateDecreaseCollateralDelta(
                    positionManager,
                    position.indexToken,
                    collateralDelta
                ),
                31
            );
        }

        if (collateralDelta > 0 || sizeDelta > 0) {
            // Create order to exit position
            IDopexPositionManager(positionManager).decreaseOrder{
                value: msg.value
            }(
                DecreaseOrderParams(
                    IncreaseOrderParams(
                        swapPath,
                        position.indexToken,
                        collateralDelta,
                        sizeDelta,
                        0,
                        true
                    ),
                    positionManager,
                    false
                )
            );

            pendingStrategyPositionToken[_positionId] = swapPath[
                swapPath.length - 1
            ];

            strategyPositions[_positionId].state = ActionState.ExitPending;

            pendingOrders[
                utils.getPositionKey(positionManager, false)
            ] = _positionId;
        } else {
            _exitStrategy(_positionId, position.user);
        }
        emit CreateExitStrategyOrder(_positionId);
    }

    function gmxPositionCallback(
        bytes32 positionKey,
        bool isExecuted,
        bool
    ) external payable nonReentrant {
        _validate(whitelistedKeepers[msg.sender], 2);
        uint256 positionId = pendingOrders[positionKey];
        ActionState currentState = strategyPositions[positionId].state;

        if (currentState == ActionState.EnablePending) {
            if (isExecuted) {
                _enableStrategy(positionId);
                return;
            } else {
                emergencyStrategyExit(positionId);
                return;
            }
        }
        if (currentState == ActionState.IncreasePending) {
            if (isExecuted) {
                strategyPositions[positionId].state = ActionState.Increased;
                return;
            }
            return;
        }

        if (currentState == ActionState.ExitPending) {
            _exitStrategy(positionId);
            return;
        }
    }

    /**
     * @notice            Exit strategy by abandoning the options position.
     *                    Can only be called if gmx position has no borrowed
     *                    collateral.
     * @param _positionId Id of the position in strategyPositions mapping .
     *
     */
    function emergencyStrategyExit(uint256 _positionId) public nonReentrant {
        (
            uint256 expiry,
            uint256 purchaseId,
            address indexToken,
            address collateralToken,
            address user,
            bool keepCollateral,
            ActionState state
        ) = getStrategyPosition(_positionId);

        if (msg.sender != user) {
            _validate(whitelistedKeepers[msg.sender], 2);
        }

        address atlanticPool = _getAtlanticPoolAddress(
            indexToken,
            collateralToken,
            expiry
        );

        _validate(state != ActionState.Increased, 26);

        if (keepCollateral) {
            (, uint256 amount) = _getOptionsPurchase(atlanticPool, purchaseId);

            _safeTransfer(indexToken, user, amount);
        }

        _exitStrategy(_positionId, user);

        emit EmergencyStrategyExit(_positionId);
    }

    /**
     * @notice              Check if a managed position can have added collateral
     *                      removed and relocked into atlantics pool
     * @param  _positionId  ID of the position in strategyPositions mapping
     * @return isDecreasable
     */
    function isManagedPositionDecreasable(
        uint256 _positionId
    ) public view returns (bool isDecreasable) {
        StrategyPosition memory position = strategyPositions[_positionId];

        address pool = _getAtlanticPoolAddress(
            position.indexToken,
            position.collateralToken,
            position.expiry
        );

        (uint256 strike, ) = _getOptionsPurchase(
            pool,
            position.atlanticsPurchaseId
        );

        isDecreasable =
            utils.getPrice(position.indexToken) >=
            getStrikeWithOffsetBps(strike, pool);
    }

    /**
     * @notice Check if a long position has enough collateral + offset
     *         to unwind. After which the position must be strictly closed.
     *         positions of users who have deposited collateral will be ignored.
     * @param  _positionId  ID of the position in strategyPositions mapping
     * @return isLiquidatable
     */
    function isManagedPositionLiquidatable(
        uint256 _positionId
    ) public view returns (bool isLiquidatable) {
        StrategyPosition memory position = strategyPositions[_positionId];

        if (position.atlanticsPurchaseId == 0) return false;

        uint256 unwindCosts = (utils.getAtlanticUnwindCosts(
            _getAtlanticPoolAddress(
                position.indexToken,
                position.collateralToken,
                position.expiry
            ),
            position.atlanticsPurchaseId,
            false
        ) * (BPS_PRECISION + liquidationCollateralMultiplierBps)) /
            BPS_PRECISION;

        uint256 amountOut = utils.getAmountReceivedOnExitPosition(
            userPositionManagers(position.user),
            position.indexToken,
            address(0)
        );

        if (!position.keepCollateral) {
            if (position.state == ActionState.Increased) {
                isLiquidatable = unwindCosts > amountOut;
            }
        }
    }

    /**
     * @notice                 Get strategy position details
     * @param _positionId      Id of the position in strategy positions
     *                         mapping
     * @return expiry
     * @return purchaseId      Options purchase id
     * @return indexToken      Address of the index token
     * @return collateralToken Address of the collateral token
     * @return user            Address of the strategy position owner
     * @return keepCollateral  Has deposited underlying to persist
     *                         borrowed collateral
     * @return state           State of the position from ActionState enum
     */
    function getStrategyPosition(
        uint256 _positionId
    )
        public
        view
        returns (uint256, uint256, address, address, address, bool, ActionState)
    {
        StrategyPosition memory position = strategyPositions[_positionId];
        return (
            position.expiry,
            position.atlanticsPurchaseId,
            position.indexToken,
            position.collateralToken,
            position.user,
            position.keepCollateral,
            position.state
        );
    }

    /**
     * @notice         Get fee charged on creating a strategy postion
     * @param _size    Size of the gmx position in 1e30 decimals
     * @param _toToken Address of the index token of the gmx position
     * @return fees    Fee amount in index token / _toToken decimals
     */
    function getPositionfee(
        uint256 _size,
        address _toToken,
        address _account
    ) public view returns (uint256 fees) {
        // Unchecked meant first usdWithFee calculation
        // Overflow/underflow is checked within IVault().usdToTokenMin()
        unchecked {
            uint256 feeBps = feeStrategy.getFeeBps(
                STRATEGY_FEE_KEY,
                _account,
                useDiscountForFees
            );
            uint256 usdWithFee = (_size * (10000000 + feeBps)) / 10000000;
            fees = IVault(vault).usdToTokenMin(_toToken, (usdWithFee - _size));
        }
    }

    /**
     * @notice            Get strike amount added with offset bps of
     *                    the index token
     * @param _strike     Strike of the option
     * @param _pool Address of the index token / underlying
     *                     of the option
     */
    function getStrikeWithOffsetBps(
        uint256 _strike,
        address _pool
    ) public view returns (uint256 strikeWithOffset) {
        unchecked {
            uint256 offset = (IAtlanticPutsPool(_pool)
                .getCurrentEpochTickSize() *
                (BPS_PRECISION + tickSizeMultiplierBps[_pool])) / BPS_PRECISION;
            strikeWithOffset = _strike + offset;
        }
    }

    function userPositionManagers(
        address _user
    ) public view returns (address _positionManager) {
        return
            IDopexPositionManagerFactory(positionManagerFactory)
                .userPositionManagers(_user);
    }

    function _exitStrategy(uint256 _positionId) private {
        StrategyPosition memory position = strategyPositions[_positionId];

        address pendingToken = pendingStrategyPositionToken[_positionId];
        uint256 receivedTokens = IDopexPositionManager(
            userPositionManagers(position.user)
        ).withdrawTokens(utils.get1TokenSwapPath(pendingToken), address(this))[
                0
            ];

        IAtlanticPutsPool pool = IAtlanticPutsPool(
            _getAtlanticPoolAddress(
                position.indexToken,
                position.collateralToken,
                position.expiry
            )
        );

        uint256 unwindAmount = utils.getAtlanticUnwindCosts(
            address(pool),
            position.atlanticsPurchaseId,
            true
        );

        uint256 deductable;
        if (pendingToken == position.indexToken) {
            pool.unwind(position.atlanticsPurchaseId);
            if (!position.keepCollateral) {
                deductable = unwindAmount;
            }
        } else {
            if (pool.getOptionsPurchase(position.atlanticsPurchaseId).unlock) {
                deductable = utils.getCollateralAccess(
                    address(pool),
                    position.atlanticsPurchaseId
                );
                // Relock collateral
                pool.relockCollateral(position.atlanticsPurchaseId);
            }

            if (position.keepCollateral) {
                _safeTransfer(position.indexToken, position.user, unwindAmount);
            }
        }

        delete pendingStrategyPositionToken[_positionId];

        _exitStrategy(_positionId, position.user);

        _safeTransfer(pendingToken, position.user, receivedTokens - deductable);

        emit ManagedPositionExitStrategy(_positionId);
    }

    function _exitStrategy(uint256 _positionId, address _user) private {
        delete strategyPositions[_positionId].atlanticsPurchaseId;
        delete strategyPositions[_positionId].expiry;
        delete strategyPositions[_positionId].keepCollateral;
        strategyPositions[_positionId].state = ActionState.Settled;
        strategyPositions[_positionId].user = _user;
        unchecked {
            --activePositions;
        }
        IDopexPositionManager(userPositionManagers(_user)).release();
    }

    function _newStrategyPosition(
        uint256 _positionId,
        uint256 _expiry,
        address _indexToken,
        address _collateralToken,
        bool _keepCollateral
    ) private {
        strategyPositions[_positionId].expiry = _expiry;
        strategyPositions[_positionId].indexToken = _indexToken;
        strategyPositions[_positionId].collateralToken = _collateralToken;
        strategyPositions[_positionId].user = msg.sender;
        strategyPositions[_positionId].keepCollateral = _keepCollateral;
        strategyPositions[_positionId].state = ActionState.EnablePending;
    }

    function _enableStrategy(uint256 _positionId) private {
        StrategyPosition memory position = strategyPositions[_positionId];

        address positionManager = userPositionManagers(position.user);

        address atlanticPool = _getAtlanticPoolAddress(
            position.indexToken,
            position.collateralToken,
            position.expiry
        );

        uint256 putStrike = utils.getEligiblePutStrike(
            atlanticPool,
            tickSizeMultiplierBps[atlanticPool],
            utils.getLiquidationPrice(positionManager, position.indexToken) /
                1e22
        );

        uint256 optionsAmount = utils.getRequiredAmountOfOptionsForInsurance(
            putStrike,
            positionManager,
            position.indexToken,
            position.collateralToken
        );

        IAtlanticPutsPool pool = IAtlanticPutsPool(atlanticPool);

        uint256 optionsCosts = pool.calculatePremium(putStrike, optionsAmount) +
            pool.calculatePurchaseFees(position.user, putStrike, optionsAmount);

        _safeTransferFrom(
            position.collateralToken,
            position.user,
            address(this),
            optionsCosts
        );

        uint256 purchaseId = pool.purchase(
            putStrike,
            optionsAmount,
            address(this),
            position.user
        );

        strategyPositions[_positionId].atlanticsPurchaseId = purchaseId;
        strategyPositions[_positionId].state = ActionState.Active;

        if (position.keepCollateral) {
            _safeTransferFrom(
                position.indexToken,
                position.user,
                address(this),
                utils.getAtlanticUnwindCosts(atlanticPool, purchaseId, false)
            );
        }

        ICallbackForwarder(positionManagerFactory.callback())
            .createIncreaseOrder(_positionId);

        emit StrategyPositionEnabled(_positionId);
    }

    function _collectPositionFee(
        uint256 _positionSize,
        address _tokenIn,
        address _tokenOut
    ) private {
        uint256 fee = getPositionfee(_positionSize, _tokenIn, msg.sender);
        _safeTransferFrom(_tokenIn, msg.sender, address(this), fee);
        _balanceFeeReserves(fee, _tokenIn, _tokenOut);
    }

    function _isKeeperHandleWindow(
        uint256 _expiry
    ) private view returns (bool isInWindow) {
        // Unchecked because keeperHandleWindow is hours/minutes unix timestamp format
        unchecked {
            return block.timestamp > _expiry - keeperHandleWindow;
        }
    }

    function _getAtlanticPoolAddress(
        address _indexToken,
        address _quoteToken,
        uint256 _expiry
    ) private view returns (address poolAddress) {
        return
            whitelistedAtlanticPools[
                _getPoolKey(_indexToken, _quoteToken, _expiry)
            ];
    }

    function _getPoolKey(
        address _indexToken,
        address _quoteToken,
        uint256 _expiry
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_indexToken, _quoteToken, _expiry));
    }

    function setAtlanticPool(
        address _poolAddress,
        address _indexToken,
        address _quoteToken,
        uint256 _expiry,
        uint256 _tickSizeMultiplierBps
    ) external onlyGov {
        whitelistedAtlanticPools[
            _getPoolKey(_indexToken, _quoteToken, _expiry)
        ] = _poolAddress;
        tickSizeMultiplierBps[_poolAddress] = _tickSizeMultiplierBps;

        _safeApprove(_indexToken, _poolAddress, type(uint256).max);
        _safeApprove(_quoteToken, _poolAddress, type(uint256).max);

        emit AtlanticPoolWhitelisted(
            _poolAddress,
            _quoteToken,
            _indexToken,
            _expiry,
            _tickSizeMultiplierBps
        );
    }

    function setMaxLeverage(uint256 _maxLeverage) external onlyGov {
        maxLeverage = _maxLeverage;
    }

    function setLiquidationCollateralMultiplierBps(
        uint256 _multiplier
    ) external onlyGov {
        liquidationCollateralMultiplierBps = _multiplier;
        emit LiquidationCollateralMultiplierBpsSet(_multiplier);
    }

    function setKeeperhandleWindow(uint256 _window) external onlyGov {
        keeperHandleWindow = _window;
    }

    function setKeeper(address _keeper, bool setAs) external onlyGov {
        whitelistedKeepers[_keeper] = setAs;
    }

    function whitelistUsers(
        address[] calldata _users,
        bool[] calldata _whitelist
    ) external onlyGov {
        for (uint256 i; i < _users.length; ) {
            whitelistedUsers[_users[i]] = _whitelist[i];
            unchecked {
                ++i;
            }
        }
    }

    function setWhitelistMode(bool _mode) external onlyGov {
        whitelistMode = _mode;
    }

    function setAddresses(
        address _positionRouter,
        address _router,
        address _vault,
        address _feeDistributor,
        address _utils,
        address _positionManagerFactory
    ) external onlyGov {
        positionRouter = _positionRouter;
        router = _router;
        vault = _vault;
        feeDistributor = _feeDistributor;
        utils = IInsuredLongsUtils(_utils);
        positionManagerFactory = IDopexPositionManagerFactory(
            _positionManagerFactory
        );
    }

    /**
     * @notice Add a contract to the whitelist
     * @dev    Can only be called by the owner
     * @param _contract Address of the contract that needs to be added to the whitelist
     */
    function addToContractWhitelist(address _contract) external onlyGov {
        _addToContractWhitelist(_contract);
    }

    /**
     * @notice Add a contract to the whitelist
     * @dev    Can only be called by the owner
     * @param _contract Address of the contract that needs to be added to the whitelist
     */
    function removeFromContractWhitelist(address _contract) external onlyGov {
        _removeFromContractWhitelist(_contract);
    }

    function setUseDiscountForFees(
        bool _setAs
    ) external onlyGov returns (bool) {
        useDiscountForFees = _setAs;
        emit UseDiscountForFeesSet(_setAs);
        return true;
    }

    /**
     * @notice Pauses the vault for emergency cases
     * @dev     Can only be called by DEFAULT_ADMIN_ROLE
     * @return  Whether it was successfully paused
     */
    function pause() external onlyGov returns (bool) {
        _pause();
        return true;
    }

    /**
     *  @notice Unpauses the vault
     *  @dev    Can only be called by DEFAULT_ADMIN_ROLE
     *  @return success it was successfully unpaused
     */
    function unpause() external onlyGov returns (bool) {
        _unpause();
        return true;
    }

    function _updateGmxVaultCummulativeFundingRate(address _token) private {
        IVault(vault).updateCumulativeFundingRate(_token);
    }

    /**
     * @notice               Transfers all funds to msg.sender
     * @dev                  Can only be called by DEFAULT_ADMIN_ROLE
     * @param tokens         The list of erc20 tokens to withdraw
     * @param transferNative Whether should transfer the native currency
     */
    function emergencyWithdraw(
        address[] calldata tokens,
        bool transferNative
    ) external onlyGov returns (bool) {
        _whenPaused();
        if (transferNative) payable(msg.sender).transfer(address(this).balance);

        for (uint256 i; i < tokens.length; ) {
            IERC20 token = IERC20(tokens[i]);
            token.safeTransfer(msg.sender, token.balanceOf(address(this)));
            unchecked {
                ++i;
            }
        }

        return true;
    }

    /**
     * @notice Withdraw fees in tokens.
     * @param _tokens   Addresses of tokens to withdraw fees for.
     * @return _amounts Amounts of tokens withdrawn.
     */
    function withdrawFees(
        address[] calldata _tokens
    ) external onlyGov returns (uint256[] memory _amounts) {
        _validate(activePositions == 0, 123);

        if (_tokens.length > 0) {
            _amounts = new uint256[](_tokens.length);

            for (uint256 i; i < _tokens.length; ) {
                _amounts[i] = IERC20(_tokens[i]).balanceOf(address(this));

                _safeTransfer(_tokens[i], feeDistributor, _amounts[i]);

                unchecked {
                    ++i;
                }
            }
        }
    }

    function _safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) private {
        IERC20(_token).safeTransferFrom(_from, _to, _amount);
    }

    function _safeApprove(
        address _token,
        address _spender,
        uint256 _amount
    ) private {
        IERC20(_token).safeApprove(_spender, _amount);
    }

    function _safeTransfer(
        address _token,
        address _to,
        uint256 _amount
    ) private {
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function _validate(bool trueCondition, uint256 errorCode) private pure {
        if (!trueCondition) {
            revert InsuredLongsStrategyError(errorCode);
        }
    }

    /**
     * @notice Swap fee tokens to ensure 50-50 ratio.
     * @param _amountIn Amount of tokens.
     * @param _tokenIn  Address of the token received.
     * @param _tokenOut Address of the token to swap to.
     */
    function _balanceFeeReserves(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) private {
        _amountIn = (_amountIn / 2);
        uint256 received = IERC20(_tokenOut).balanceOf(address(this));
        _safeApprove(_tokenIn, router, _amountIn);
        IRouter(router).swap(
            utils.get2TokenSwapPath(_tokenIn, _tokenOut),
            _amountIn,
            0,
            address(this)
        );
        received = IERC20(_tokenOut).balanceOf(address(this)) - received;
    }

    function _getOptionsPurchase(
        address _atlanticPool,
        uint256 _purchaseId
    ) private view returns (uint256 strike, uint256 amount) {
        (strike, amount) = utils.getOptionsPurchase(_atlanticPool, _purchaseId);
    }

    modifier onlyWhitelistedUser() {
        if (whitelistMode) {
            _validate(whitelistedUsers[msg.sender], 10);
        }
        _;
    }

    modifier onlyGov() {
        _validate(msg.sender == gov, 32);
        _;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Structs
import {DepositPosition, Addresses, OptionsPurchase, Checkpoint, VaultState} from "../AtlanticsStructs.sol";

/**                                                                                                 
          █████╗ ████████╗██╗      █████╗ ███╗   ██╗████████╗██╗ ██████╗
          ██╔══██╗╚══██╔══╝██║     ██╔══██╗████╗  ██║╚══██╔══╝██║██╔════╝
          ███████║   ██║   ██║     ███████║██╔██╗ ██║   ██║   ██║██║     
          ██╔══██║   ██║   ██║     ██╔══██║██║╚██╗██║   ██║   ██║██║     
          ██║  ██║   ██║   ███████╗██║  ██║██║ ╚████║   ██║   ██║╚██████╗
          ╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝ ╚═════╝
                                                                        
          ██████╗ ██████╗ ████████╗██╗ ██████╗ ███╗   ██╗███████╗       
          ██╔═══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝       
          ██║   ██║██████╔╝   ██║   ██║██║   ██║██╔██╗ ██║███████╗       
          ██║   ██║██╔═══╝    ██║   ██║██║   ██║██║╚██╗██║╚════██║       
          ╚██████╔╝██║        ██║   ██║╚██████╔╝██║ ╚████║███████║       
          ╚═════╝ ╚═╝        ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝       
                                                               
                            Atlantic Options
              Yield bearing put options with mobile collateral                                                           
*/

interface IAtlanticPutsPool {
    function addresses() external view returns (Addresses memory);

    // Deposits collateral as a writer with a specified max strike for the next epoch
    function deposit(
        uint256 maxStrike,
        address user
    ) external payable returns (bool);

    // Purchases an atlantic for a specified strike
    function purchase(
        uint256 strike,
        uint256 amount,
        address receiver,
        address account
    ) external returns (uint256);

    // Unlocks collateral from an atlantic by depositing underlying. Callable by dopex managed contract integrations.
    function unlockCollateral(uint256 amount, address to, address account) external returns (uint256);

    // Gracefully exercises an atlantic, sends collateral to integrated protocol,
    // underlying to writer and charges an unwind fee
    // to the option holder/protocol
    function unwind(uint256) external returns (uint256);

    // Re-locks collateral into an atlatic option. Withdraws underlying back to user, sends collateral back
    // from dopex managed contract to option
    // Handles exceptions where collateral may get stuck due to failures in other protocols.
    function relockCollateral(
        uint256
    ) external returns (uint256 collateralCollected);

    function calculatePnl(
        uint256 price,
        uint256 strike,
        uint256 amount
    ) external returns (uint256);

    function calculatePremium(uint256, uint256) external view returns (uint256);

    function calculatePurchaseFees(
        address,
        uint256,
        uint256
    ) external view returns (uint256);

    function settle(
        uint256 purchaseId,
        address receiver
    ) external returns (uint256 pnl);

    function epochTickSize(uint256 epoch) external view returns (uint256);

    function checkpointIntervalTime() external view returns (uint256);

    function getEpochHighestMaxStrike(
        uint256 _epoch
    ) external view returns (uint256 _highestMaxStrike);

    function calculateSettlementFees(
        uint256 settlementPrice,
        uint256 pnl,
        uint256 amount
    ) external view returns (uint256);

    function getUsdPrice() external view returns (uint256);

    function getEpochSettlementPrice(
        uint256 _epoch
    ) external view returns (uint256 _settlementPrice);

    function currentEpoch() external view returns (uint256);

    function getOptionsPurchase(
        uint256 _tokenId
    ) external view returns (OptionsPurchase memory);

    function getDepositPosition(
        uint256 _tokenId
    ) external view returns (DepositPosition memory);

    function depositIdCount() external view returns (uint256);

    function purchaseIdCount() external view returns (uint256);

    function getEpochCheckpoints(
        uint256,
        uint256
    ) external view returns (Checkpoint[] memory);

    function epochVaultStates(
        uint256 _epoch
    ) external view returns (VaultState memory);

    function getEpochStrikes(
        uint256 _epoch
    ) external view returns (uint256[] memory _strike_s);

    function getUnwindAmount(
        uint256 _optionsAmount,
        uint256 _optionStrike
    ) external view returns (uint256 unwindAmount);

    function strikeMulAmount(
        uint256 _strike,
        uint256 _amount
    ) external view returns (uint256);

    function isWithinExerciseWindow() external view returns (bool);

    function setPrivateMode(bool _mode) external;

    function getCurrentEpochTickSize() external view returns (uint256);

    function calculateFundingFees(
        address _account,
        uint256 _collateralAccess
    ) external view returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRouter {
  function addPlugin(address _plugin) external;

  function approvePlugin(address _plugin) external;

  function pluginTransfer(
    address _token,
    address _account,
    address _receiver,
    uint256 _amount
  ) external;

  function pluginIncreasePosition(
    address _account,
    address _collateralToken,
    address _indexToken,
    uint256 _sizeDelta,
    bool _isLong
  ) external;

  function pluginDecreasePosition(
    address _account,
    address _collateralToken,
    address _indexToken,
    uint256 _collateralDelta,
    uint256 _sizeDelta,
    bool _isLong,
    address _receiver
  ) external returns (uint256);

  function swap(
    address[] memory _path,
    uint256 _amountIn,
    uint256 _minOut,
    address _receiver
  ) external;

  function swapTokensToETH(
    address[] memory _path,
    uint256 _amountIn,
    uint256 _minOut,
    address payable _receiver
  ) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVault {
    struct Position {
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        uint256 entryFundingRate;
        uint256 reserveAmount;
        int256 realisedPnl;
        uint256 lastIncreasedTime;
    }

    function updateCumulativeFundingRate(address _indexToken) external;

    function adjustForDecimals(
        uint256 _amount,
        address _tokenDiv,
        address _tokenMul
    ) external view returns (uint256);

    function positions(bytes32) external view returns (Position memory);

    function isInitialized() external view returns (bool);

    function isSwapEnabled() external view returns (bool);

    function isLeverageEnabled() external view returns (bool);

    function setError(uint256 _errorCode, string calldata _error) external;

    function router() external view returns (address);

    function usdg() external view returns (address);

    function gov() external view returns (address);

    function whitelistedTokenCount() external view returns (uint256);

    function maxLeverage() external view returns (uint256);

    function minProfitTime() external view returns (uint256);

    function hasDynamicFees() external view returns (bool);

    function fundingInterval() external view returns (uint256);

    function totalTokenWeights() external view returns (uint256);

    function getTargetUsdgAmount(
        address _token
    ) external view returns (uint256);

    function inManagerMode() external view returns (bool);

    function inPrivateLiquidationMode() external view returns (bool);

    function maxGasPrice() external view returns (uint256);

    function approvedRouters(
        address _account,
        address _router
    ) external view returns (bool);

    function isLiquidator(address _account) external view returns (bool);

    function isManager(address _account) external view returns (bool);

    function minProfitBasisPoints(
        address _token
    ) external view returns (uint256);

    function tokenBalances(address _token) external view returns (uint256);

    function lastFundingTimes(address _token) external view returns (uint256);

    function setMaxLeverage(uint256 _maxLeverage) external;

    function setInManagerMode(bool _inManagerMode) external;

    function setManager(address _manager, bool _isManager) external;

    function setIsSwapEnabled(bool _isSwapEnabled) external;

    function setIsLeverageEnabled(bool _isLeverageEnabled) external;

    function setMaxGasPrice(uint256 _maxGasPrice) external;

    function setUsdgAmount(address _token, uint256 _amount) external;

    function setBufferAmount(address _token, uint256 _amount) external;

    function setMaxGlobalShortSize(address _token, uint256 _amount) external;

    function setInPrivateLiquidationMode(
        bool _inPrivateLiquidationMode
    ) external;

    function setLiquidator(address _liquidator, bool _isActive) external;

    function setFundingRate(
        uint256 _fundingInterval,
        uint256 _fundingRateFactor,
        uint256 _stableFundingRateFactor
    ) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _minProfitBps,
        uint256 _maxUsdgAmount,
        bool _isStable,
        bool _isShortable
    ) external;

    function setPriceFeed(address _priceFeed) external;

    function withdrawFees(
        address _token,
        address _receiver
    ) external returns (uint256);

    function directPoolDeposit(address _token) external;

    function buyUSDG(
        address _token,
        address _receiver
    ) external returns (uint256);

    function sellUSDG(
        address _token,
        address _receiver
    ) external returns (uint256);

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function increasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function decreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint256);

    function liquidatePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        address _feeReceiver
    ) external;

    function tokenToUsdMin(
        address _token,
        uint256 _tokenAmount
    ) external view returns (uint256);

    function priceFeed() external view returns (address);

    function fundingRateFactor() external view returns (uint256);

    function stableFundingRateFactor() external view returns (uint256);

    function cumulativeFundingRates(
        address _token
    ) external view returns (uint256);

    function getNextFundingRate(address _token) external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function stableTaxBasisPoints() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function swapFeeBasisPoints() external view returns (uint256);

    function stableSwapFeeBasisPoints() external view returns (uint256);

    function marginFeeBasisPoints() external view returns (uint256);

    function allWhitelistedTokensLength() external view returns (uint256);

    function allWhitelistedTokens(uint256) external view returns (address);

    function whitelistedTokens(address _token) external view returns (bool);

    function stableTokens(address _token) external view returns (bool);

    function shortableTokens(address _token) external view returns (bool);

    function feeReserves(address _token) external view returns (uint256);

    function globalShortSizes(address _token) external view returns (uint256);

    function globalShortAveragePrices(
        address _token
    ) external view returns (uint256);

    function maxGlobalShortSizes(
        address _token
    ) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function tokenWeights(address _token) external view returns (uint256);

    function guaranteedUsd(address _token) external view returns (uint256);

    function poolAmounts(address _token) external view returns (uint256);

    function bufferAmounts(address _token) external view returns (uint256);

    function reservedAmounts(address _token) external view returns (uint256);

    function usdgAmounts(address _token) external view returns (uint256);

    function maxUsdgAmounts(address _token) external view returns (uint256);

    function getRedemptionAmount(
        address _token,
        uint256 _usdgAmount
    ) external view returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        );

    function getPositionFee(
        address /* _account */,
        address /* _collateralToken */,
        address /* _indexToken */,
        bool /* _isLong */,
        uint256 _sizeDelta
    ) external view returns (uint256);

    function getFundingFee(
        address /* _account */,
        address _collateralToken,
        address /* _indexToken */,
        bool /* _isLong */,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function usdToTokenMin(
        address _token,
        uint256 _usdAmount
    ) external view returns (uint256);

    function getPositionLeverage(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (uint256);

    function getFundingFee(
        address _token,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function getPositionFee(uint256 _sizeDelta) external view returns (uint256);

    function getPositionDelta(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (bool, uint256);

    function validateLiquidation(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        bool _raise
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * NOTE: Modified to include symbols and decimals.
 */
interface IERC20 {

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Structs
struct IncreaseOrderParams {
    address[] path;
    address indexToken;
    uint256 collateralDelta;
    uint256 positionSizeDelta;
    uint256 acceptablePrice;
    bool isLong;
}

struct DecreaseOrderParams {
    IncreaseOrderParams orderParams;
    address receiver;
    bool withdrawETH;
}

interface IDopexPositionManager {
    function enableAndCreateIncreaseOrder(
        IncreaseOrderParams calldata params,
        address _gmxVault,
        address _gmxRouter,
        address _gmxPositionRouter,
        address _user
    ) external payable;

    function increaseOrder(IncreaseOrderParams memory) external payable;

    function decreaseOrder(DecreaseOrderParams calldata) external payable;

    function release() external;

    function minSlippageBps() external view returns (uint256);

    function withdrawTokens(
        address[] calldata _tokens,
        address _receiver
    ) external returns (uint256[] memory _amounts);

    function strategyControllerTransfer(
        address _token,
        address _to,
        uint256 amount
    ) external;

    function lock() external;

    function slippage() external view returns (uint256);

    event IncreaseOrderCreated(
        address[] _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _acceptablePrice
    );
    event DecreaseOrderCreated(
        address[] _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _acceptablePrice
    );
    event ReferralCodeSet(bytes32 _newReferralCode);
    event Released();
    event Locked();
    event TokensWithdrawn(address[] tokens, uint256[] amounts);
    event SlippageSet(uint256 _slippage);
    event CallbackSet(address _callback);
    event FactorySet(address _factory);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IInsuredLongsUtils {
    function getLiquidationPrice(
        address _positionManager,
        address _indexToken
    ) external view returns (uint256 liquidationPrice);

    function getLiquidationPrice(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta
    ) external view returns (uint256);

    function getRequiredAmountOfOptionsForInsurance(
        address _atlanticPool,
        address _collateralToken,
        address _indexToken,
        uint256 _size,
        uint256 _collateral,
        uint256 _putStrike
    ) external view returns (uint256 optionsAmount);

    function getRequiredAmountOfOptionsForInsurance(
        uint256 _putStrike,
        address _positionManager,
        address _indexToken,
        address _quoteToken
    ) external view returns (uint256 optionsAmount);

    function getEligiblePutStrike(
        address _atlanticPool,
        uint256 _offset,
        uint256 _liquidationPrice
    ) external view returns (uint256 eligiblePutStrike);

    function getPositionKey(
        address _positionManager,
        bool isIncrease
    ) external view returns (bytes32 key);

    function getPositionLeverage(
        address _positionManager,
        address _indexToken
    ) external view returns (uint256);

    function getLiquidatablestate(
        address _positionManager,
        address _indexToken,
        address _collateralToken,
        address _atlanticPool,
        uint256 _purchaseId,
        bool _isIncreased
    ) external view returns (uint256 _usdOut, address _outToken);

    function getAtlanticUnwindCosts(
        address _atlanticPool,
        uint256 _purchaseId,
        bool
    ) external view returns (uint256);

    function get1TokenSwapPath(
        address _token
    ) external pure returns (address[] memory path);

    function get2TokenSwapPath(
        address _token1,
        address _token2
    ) external pure returns (address[] memory path);

    function getOptionsPurchase(
        address _atlanticPool,
        uint256 purchaseId
    ) external view returns (uint256, uint256);

    function getPrice(address _token) external view returns (uint256 _price);

    function getCollateralAccess(
        address atlanticPool,
        uint256 _purchaseId
    ) external view returns (uint256 _collateralAccess);

    function getFundingFee(
        address _indexToken,
        address _positionManager,
        address _convertTo
    ) external view returns (uint256 fundingFee);

    function getAmountIn(
        uint256 _amountOut,
        uint256 _slippage,
        address _tokenOut,
        address _tokenIn
    ) external view returns (uint256 _amountIn);

    function getPositionSize(
        address _positionManager,
        address _indexToken
    ) external view returns (uint256 size);

    function getPositionFee(
        uint256 _size
    ) external view returns (uint256 feeUsd);

    function getAmountReceivedOnExitPosition(
        address _positionManager,
        address _indexToken,
        address _outToken
    ) external view returns (uint256 amountOut);

    function getStrategyExitSwapPath(
        address _atlanticPool,
        uint256 _purchaseId
    ) external view returns (address[] memory path);

    function validateIncreaseExecution(
        uint256 _collateralSize,
        uint256 _size,
        address _collateralToken,
        address _indexToken
    ) external view returns (bool);

    function validateUnwind(
        address _positionManager,
        address _indexToken,
        address _atlanticPool,
        uint256 _purchaseId
    ) external view returns (bool);

    function getUsdOutForUnwindWithFee(
        address _positionManager,
        address _indexToken,
        address _atlanticPool,
        uint256 _purchaseId
    ) external view returns (uint256 _usdOut);

    function calculateCollateral(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralAmount,
        uint256 _size
    ) external view returns (uint256 collateral);

    function calculateLeverage(
        uint256 _size,
        uint256 _collateral,
        address _collateralToken
    ) external view returns (uint256 _leverage);

    function getMinUnwindablePrice(
        address _positionManager,
        address _atlanticPool,
        address _indexToken,
        uint256 _purchaseId,
        uint256 _offset
    ) external view returns (bool isLiquidatable);


   function validateDecreaseCollateralDelta(
        address _positionManager,
        address _indexToken,
        uint256 _collateralDelta
    ) external view returns (bool valid);

       function getMarginFees(
        address _positionManager,
        address _indexToken,
        address _convertTo
    ) external view returns (uint256 fees);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface IInsuredLongsStrategy {
    function gmxPositionCallback(
        bytes32 positionKey,
        bool isExecuted,
        bool
    ) external payable;

    function positionsCount() external view returns (uint256);

    function getStrategyPosition(
        uint256 _positionId
    )
        external
        view
        returns (
            uint256,
            uint256,
            address,
            address,
            address,
            bool,
            ActionState
        );

    function isManagedPositionDecreasable(
        uint256 _positionId
    ) external view returns (bool isDecreasable);

    function isManagedPositionLiquidatable(
        uint256 _positionId
    ) external view returns (bool isLiquidatable);

    function createExitStrategyOrder(
        uint256 _positionId,
        bool exitLongPosition
    ) external payable;

    function createIncreaseManagedPositionOrder(
        uint256 _positionId
    ) external payable;

    function emergencyStrategyExit(uint256 _positionId) external;

    event AtlanticPoolWhitelisted(
        address _poolAddress,
        address _quoteToken,
        address _indexToken,
        uint256 _expiry,
        uint256 _tickSizeMultiplier
    );
    event UseStrategy(uint256 _positionId);
    event StrategyPositionEnabled(uint256 _positionId);
    event ManagedPositionIncreaseOrderSuccess(uint256 _positionId);
    event ManagedPositionExitStrategy(uint256 _positionId);
    event CreateExitStrategyOrder(uint256 _positionId);
    event ReuseStrategy(uint256 _positionId);
    event EmergencyStrategyExit(uint256 _positionId);
    event LiquidationCollateralMultiplierBpsSet(uint256 _multiplierBps);
    event KeepCollateralEnabled(uint256 _positionId);
    event FeeWithdrawn(address _token, uint256 _amount);
    event UseDiscountForFeesSet(bool _setAs);

    error InsuredLongsStrategyError(uint256 _errorCode);

    enum ActionState {
        None, // 0
        Settled, // 1
        Active, // 2
        IncreasePending, // 3
        Increased, // 4
        EnablePending, // 5
        ExitPending // 6
    }

    struct StrategyPosition {
        uint256 expiry;
        uint256 atlanticsPurchaseId;
        address indexToken;
        address collateralToken;
        address user;
        bool keepCollateral;
        ActionState state;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IDopexPositionManagerFactory {
    function createPositionmanager(address _user) external returns (address positionManager);
    function callback() external view returns (address);
    function minSlipageBps() external view returns (uint256);
    function userPositionManagers(address _user) external view returns (address);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface ICallbackForwarder {
    function gmxPositionCallback(
        bytes32 positionKey,
        bool isExecuted,
        bool
    ) external;

    function createIncreaseOrder(uint256 _positionId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IDopexFeeStrategy {
 function getFeeBps(
        uint256 _feeType,
        address _user,
        bool _useDiscount
    ) external view returns (uint256 _feeBps);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "../interfaces/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

/// @title Lighter version of the Openzeppelin Pausable contract
/// @author witherblock
/// @notice Helps pause a contract to block the execution of selected functions
/// @dev Difference from the Openzeppelin version is changing the modifiers to internal fns and requires to reverts
abstract contract Pausable {
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
     * @dev Internal function to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _whenNotPaused() internal view {
        if (paused()) revert ContractPaused();
    }

    /**
     * @dev Internal function to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _whenPaused() internal view {
        if (!paused()) revert ContractNotPaused();
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual {
        _whenNotPaused();
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual {
        _whenPaused();
        _paused = false;
        emit Unpaused(msg.sender);
    }

    error ContractPaused();
    error ContractNotPaused();
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

/// @title ContractWhitelist
/// @author witherblock
/// @notice A helper contract that lets you add a list of whitelisted contracts that should be able to interact with restricited functions
abstract contract ContractWhitelist {
    /// @dev contract => whitelisted or not
    mapping(address => bool) public whitelistedContracts;

    error AddressNotContract();
    error ContractNotWhitelisted();
    error ContractAlreadyWhitelisted();

    /*==== SETTERS ====*/

    /// @dev add to the contract whitelist
    /// @param _contract the address of the contract to add to the contract whitelist
    function _addToContractWhitelist(address _contract) internal {
        if (!isContract(_contract)) revert AddressNotContract();

        whitelistedContracts[_contract] = true;

        emit AddToContractWhitelist(_contract);
    }

    /// @dev remove from  the contract whitelist
    /// @param _contract the address of the contract to remove from the contract whitelist
    function _removeFromContractWhitelist(address _contract) internal {

        whitelistedContracts[_contract] = false;

        emit RemoveFromContractWhitelist(_contract);
    }

    // modifier is eligible sender modifier
    function _isEligibleSender() internal view {
        // the below condition checks whether the caller is a contract or not
        if (msg.sender != tx.origin) {
            if (!whitelistedContracts[msg.sender]) {
                revert ContractNotWhitelisted();
            }
        }
    }

    /*==== VIEWS ====*/

    /// @dev checks for contract or eoa addresses
    /// @param addr the address to check
    /// @return bool whether the passed address is a contract address
    function isContract(address addr) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /*==== EVENTS ====*/

    event AddToContractWhitelist(address indexed _contract);
    event RemoveFromContractWhitelist(address indexed _contract);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.7;

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

    error ReentrancyCall();

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
        // On the first call to nonReentrant, _notEntered will be true
        if (_status == _ENTERED) revert ReentrancyCall();

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

struct Addresses {
  address quoteToken;
  address baseToken;
  address feeDistributor;
  address feeStrategy;
  address optionPricing;
  address priceOracle;
  address volatilityOracle;
}

struct VaultState {
  // Settlement price set on expiry
  uint256 settlementPrice;
  // Timestamp at which the epoch expires
  uint256 expiryTime;
  // Start timestamp of the epoch
  uint256 startTime;
  // Whether vault has been bootstrapped
  bool isVaultReady;
  // Whether vault is expired
  bool isVaultExpired;
}


struct Checkpoint {
  uint256 startTime;
  uint256 totalLiquidity;
  uint256 totalLiquidityBalance;
  uint256 activeCollateral;
  uint256 unlockedCollateral;
  uint256 premiumAccrued;
  uint256 fundingFeesAccrued;
  uint256 underlyingAccrued;
}

struct OptionsPurchase {
  uint256 epoch;
  uint256 optionStrike;
  uint256 optionsAmount;
  uint256[] strikes;
  uint256[] checkpoints;
  uint256[] weights;
  address user;
  bool unlock;
}

struct DepositPosition {
  uint256 epoch;
  uint256 strike;
  uint256 timestamp;
  uint256 liquidity;
  uint256 checkpoint;
  address depositor;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}