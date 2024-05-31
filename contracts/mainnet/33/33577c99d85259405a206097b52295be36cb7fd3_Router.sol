// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2024 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.7.6;
pragma abicoder v2;

import {MulDivMathLib} from "src/libraries/MulDivMathLib.sol";
import {SafeERC20} from "@openzeppelin/token/ERC20/SafeERC20.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

import {SafeMath} from "@openzeppelin/math/SafeMath.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgrades/utils/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin-upgrades/utils/PausableUpgradeable.sol";
import {UpgradeableOperableKeepable} from "src/governance/UpgradeableOperableKeepable.sol";
import {IRouter} from "src/interfaces/IRouter.sol";
import {ICompounder} from "src/interfaces/rewards/ICompounder.sol";
import {IRewardTracker} from "src/interfaces/rewards/IRewardTracker.sol";
import {ISingleRewardTracker} from "src/interfaces/rewards/ISingleRewardTracker.sol";
import {IPriceHelper} from "src/interfaces/swap/IPriceHelper.sol";

import {IManager} from "src/interfaces/manager/IManager.sol";

import {IBlast} from "src/interfaces/IBlast.sol";

// UniV3 LP Router Manager
contract Router is IRouter, UpgradeableOperableKeepable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeMath for uint256;
    using MulDivMathLib for uint256;
    using SafeERC20 for IERC20;

    // Deposit Stack too deep
    struct Variables {
        IERC20 managerToken;
        IManager manager;
        uint256 price0;
        uint256 price1;
        uint256 position0;
        uint256 position1;
    }

    // LP Manager Contract
    IManager private manager;
    // Compounder
    ICompounder private compounder;
    // Double Tracker
    IRewardTracker private tracker;
    // Single Zero Tracker
    ISingleRewardTracker private trackerZero;
    // Single One Tracker
    ISingleRewardTracker private trackerOne;
    // Price Helper Contract
    IPriceHelper public override price;

    // user => block number => exit orders
    mapping(address => mapping(uint256 => ExitOrder)) public exitOrder;

    uint256 private deviation;

    uint256 private constant PRECISION = 1e30;

    IBlast public constant BLAST_YIELD_CONTRACT = IBlast(0x4300000000000000000000000000000000000002);

    uint256 public constant blastID = 81457;

    function initializeRouter(
        address _manager,
        address _price,
        address _compounder,
        address _tracker,
        address _trackerZero,
        address _trackerOne
    ) external initializer {
        __Governable_init(msg.sender);
        __ReentrancyGuard_init();

        manager = IManager(_manager);
        price = IPriceHelper(_price);
        compounder = ICompounder(_compounder);
        tracker = IRewardTracker(_tracker);
        trackerZero = ISingleRewardTracker(_trackerZero);
        trackerOne = ISingleRewardTracker(_trackerOne);

        deviation = PRECISION.mulDivDown(5, 1000); // 0.5%

        IERC20(address(manager)).safeApprove(_compounder, type(uint256).max);

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        if (chainId == blastID) {
            BLAST_YIELD_CONTRACT.configureClaimableGas();
        }
    }

    /**
     * @notice Adds liquidity to the primary range
     * @param _deposit Deposit Input parameters
     * @return amount0 Amount of token0 deployed
     * @return amount1 Amount of token1 deployed
     * @return position Nimber of position token minted
     * @return shares Number of shares minted
     */
    function deposit(DepositInput calldata _deposit)
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256 amount0, uint256 amount1, uint256 position, uint256 shares)
    {
        require(_deposit.receiver != address(0), "Zero Address");
        require(_deposit.amount0 != 0 || _deposit.amount1 != 0, "Not Enough Amount");

        // Stack too deep
        Variables memory vars;

        // to save gas
        vars.manager = manager;
        vars.managerToken = IERC20(address(manager));

        // Check flash loan protection and get token prices in USD; 18 decimals
        (vars.price0, vars.price1) = price.getPrices(vars.manager.getPool());

        // Get Current Assets Under Management
        (vars.position0, vars.position1) = vars.manager.aum();

        if (_deposit.amount0 > 0 && _deposit.amount1 > 0) {
            // mint liquidty in default range
            (amount0, amount1) = vars.manager.mintLiquidity(msg.sender, 0, _deposit.amount0, _deposit.amount1);
        } else {
            amount0 = _deposit.amount0;
            amount1 = _deposit.amount1;

            // Transfer assets to manager
            vars.manager.transferAssets(msg.sender, _deposit.amount0, _deposit.amount1);
        }

        // Calculate position
        position = previewPosition(vars.price0, vars.price1, amount0, amount1, vars.position0, vars.position1);

        // Check Minimun
        require(
            amount0 >= _deposit.amount0Min && amount1 >= _deposit.amount1Min && position >= _deposit.minPosition,
            "Not Enough Amount"
        );

        vars.manager.mint(address(this), position);

        if (_deposit.compound) {
            // compound
            // Deposit position in compounder
            shares = compounder.deposit(position, _deposit.receiver);
            require(shares >= _deposit.minShares, "Not Enough Shares");
        } else {
            // Stake position in Tracker
            if (_deposit.rewardOption == 0) {
                vars.managerToken.safeTransfer(address(tracker), position);
                tracker.stake(_deposit.receiver, position);
            } else if (_deposit.rewardOption == 1) {
                vars.managerToken.safeTransfer(address(trackerZero), position);
                trackerZero.stake(_deposit.receiver, position);
            } else {
                vars.managerToken.safeTransfer(address(trackerOne), position);
                trackerOne.stake(_deposit.receiver, position);
            }
        }

        emit Deposit(msg.sender, _deposit.receiver, amount0, amount1, position, shares, _deposit.rewardOption);
    }

    /**
     * @notice Remove liquidty from primary range; shares are burnt.
     * @param _position Amount to shares to burn.
     * @param _receiver Who will receive the assets.
     * @param _amount0Min Minimum amount of token0 to be redeemed.
     * @param _amount1Min Minimum amount of token1 to be redeemed.
     * @param _compound True if user choose autocompounding shares.
     * @param _rewardOption Type of reward.
     * @return amount0 Amount of token0 redeemed.
     * @return amount1 Amount of token1 redeemed.
     */
    function withdraw(
        uint256 _position,
        address _receiver,
        uint256 _amount0Min,
        uint256 _amount1Min,
        bool _compound,
        uint8 _rewardOption
    ) external override nonReentrant whenNotPaused returns (uint256 amount0, uint256 amount1) {
        require(_receiver != address(0), "Zero Address");

        // to save gas
        IManager _manager = manager;

        // Check flash loan protection and get token prices in USD; 18 decimals
        price.getPrices(_manager.getPool());

        // Update rewards
        _manager.aum();

        uint256 _shares;

        require(_position >= 0, "Not Enough Amount");

        if (_compound) {
            require(compounder.balanceOf(msg.sender) >= _position, "Not Enough Amount");
            _shares = _position;
            _position = compounder.redeem(_shares, msg.sender);
        } else {
            if (_rewardOption == 0) {
                require(tracker.stakedAmount(msg.sender) >= _position, "Not Enough Amount");
                tracker.withdraw(msg.sender, _position);
            } else if (_rewardOption == 1) {
                require(trackerZero.stakedAmount(msg.sender) >= _position, "Not Enough Amount");
                trackerZero.withdraw(msg.sender, _position);
            } else {
                require(trackerOne.stakedAmount(msg.sender) >= _position, "Not Enough Amount");
                trackerOne.withdraw(msg.sender, _position);
            }
        }

        uint256 amount0AfterRetention;
        uint256 amount1AfterRetention;

        // Burn liquidity; amounts will send to receiver
        (amount0, amount1, amount0AfterRetention, amount1AfterRetention) =
            _manager.redeemLiquidity(_position, _receiver);

        // Check min Amount
        require(amount0 >= _amount0Min && amount1 >= _amount1Min, "Not Enough Amount");

        // Burn Position
        _manager.burn(address(this), _position);

        emit Withdraw(
            msg.sender,
            _receiver,
            _shares,
            _position,
            amount0,
            amount1,
            amount0AfterRetention,
            amount1AfterRetention,
            _rewardOption
        );

        amount0 = amount0AfterRetention;
        amount1 = amount1AfterRetention;
    }

    /**
     * @notice Adds liquidity to the primary range
     * @param _amount0 Amount of token0
     * @param _amount1 Amount of token1
     */
    function compoundDeposit(uint256 _amount0, uint256 _amount1) external override onlyOperator whenNotPaused {
        // to save gas
        IManager _manager = manager;

        // Check flash loan protection and get token prices in USD; 18 decimals
        (uint256 price0, uint256 price1) = price.getPrices(_manager.getPool());

        // Get Current Assets Under Management
        (uint256 position0, uint256 position1) = _manager.aumWithoutCollect();

        // Transfer assets to manager
        _manager.transferAssets(msg.sender, _amount0, _amount1);

        // Calculate position
        uint256 _position = previewPosition(price0, price1, _amount0, _amount1, position0, position1);

        // Stake position in Reward
        _manager.mint(address(tracker), _position);
        tracker.stake(address(compounder), _position);

        emit CompoundDeposit(msg.sender, _amount0, _amount1, _position);
    }

    /**
     * @notice Claim Rewards.
     * @param _receiver Who will receive the rewards.
     * @param _rewardOption Type of reward.
     * @return The amount of rewards in token0
     * @return The amount of rewards in token1
     */
    function claim(address _receiver, uint8 _rewardOption)
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256, uint256)
    {
        // to save gas
        IManager _manager = manager;

        // Update rewards
        _manager.aum();

        uint256 rewards0;
        uint256 rewards1;

        if (_rewardOption == 0) {
            (rewards0, rewards1) = tracker.claim(msg.sender);
        } else if (_rewardOption == 1) {
            rewards0 = trackerZero.claim(msg.sender);
        } else {
            rewards1 = trackerOne.claim(msg.sender);
        }

        if (rewards0 > 0) {
            _manager.token0().safeTransfer(_receiver, rewards0);
        }

        if (rewards1 > 0) {
            _manager.token1().safeTransfer(_receiver, rewards1);
        }

        emit Claim(msg.sender, rewards0, rewards1, _receiver, _rewardOption);

        return (rewards0, rewards1);
    }

    /**
     * @notice Compound position.
     * @param _amount Amount willing to be compounded.
     * @param _rewardOption Type of reward.
     * @return LP shares minted to user.
     */
    function compound(uint256 _amount, uint8 _rewardOption) external nonReentrant whenNotPaused returns (uint256) {
        // to save gas
        IManager _manager = manager;

        // Update rewards
        _manager.aum();

        uint256 rewards0;
        uint256 rewards1;

        if (_rewardOption == 0) {
            require(_amount <= tracker.stakedAmount(msg.sender), "Not Enough Amount");
            (rewards0, rewards1) = tracker.claim(msg.sender);
            // withdraw user staked UVRT
            tracker.withdraw(msg.sender, _amount);
        } else if (_rewardOption == 1) {
            require(_amount <= trackerZero.stakedAmount(msg.sender), "Not Enough Amount");
            rewards0 = trackerZero.claim(msg.sender);
            // withdraw user staked UVRT
            trackerZero.withdraw(msg.sender, _amount);
        } else {
            require(_amount <= trackerOne.stakedAmount(msg.sender), "Not Enough Amount");
            rewards1 = trackerOne.claim(msg.sender);
            // withdraw user staked UVRT
            trackerOne.withdraw(msg.sender, _amount);
        }

        if (rewards0 > 0) {
            _manager.token0().safeTransfer(msg.sender, rewards0);
        }

        if (rewards1 > 0) {
            _manager.token1().safeTransfer(msg.sender, rewards1);
        }

        // deposit in compounder
        uint256 shares = compounder.deposit(_amount, msg.sender);

        emit Compound(msg.sender, _amount, shares, _rewardOption);

        return shares;
    }

    /**
     * @notice Un Compound position.
     * @param _shares Shares willing to be un compounded.
     * @param _rewardOption Type of reward.
     * @return Amount position staked.
     */
    function unCompound(uint256 _shares, uint8 _rewardOption) external nonReentrant whenNotPaused returns (uint256) {
        // redeem jLP
        uint256 position = compounder.redeem(_shares, msg.sender);
        IERC20 managerToken = IERC20(address(manager));

        if (_rewardOption == 0) {
            // Stake position in Reward
            managerToken.safeTransfer(address(tracker), position);
            tracker.stake(msg.sender, position);
        } else if (_rewardOption == 1) {
            // Stake position in Reward
            managerToken.safeTransfer(address(trackerZero), position);
            trackerZero.stake(msg.sender, position);
        } else {
            // Stake position in Reward
            managerToken.safeTransfer(address(trackerOne), position);
            trackerOne.stake(msg.sender, position);
        }

        emit UnCompound(msg.sender, _shares, position, _rewardOption);

        return position;
    }

    /**
     * @notice Create exit order at specific price0.
     * @param _receiver Who will receive the withdraw amounts.
     * @param _amount Amount to withdraw.
     * @param _price price0 Will trigger the withdraw.
     * @param _compound True if user choose autocompounding shares.
     * @param _rewardOption Type of reward.
     * @return blockNumber
     */
    function createExitOrder(address _receiver, uint256 _amount, uint256 _price, bool _compound, uint8 _rewardOption)
        external
        nonReentrant
        whenNotPaused
        returns (uint256)
    {
        require(_amount > 0, "Amount Zero");

        if (_compound) {
            require(compounder.balanceOf(msg.sender) >= _amount, "Insufficient Shares");
        } else {
            if (_rewardOption == 0) {
                require(tracker.stakedAmount(msg.sender) >= _amount, "Insufficient Position");
            } else if (_rewardOption == 1) {
                require(trackerZero.stakedAmount(msg.sender) >= _amount, "Insufficient Position");
            } else {
                require(trackerOne.stakedAmount(msg.sender) >= _amount, "Insufficient Position");
            }
        }

        uint256 blockNumber = block.number;

        ExitOrder memory order = ExitOrder({
            receiver: _receiver,
            blockNumber: blockNumber,
            amount: _amount,
            price: _price,
            compound: _compound,
            rewardOption: _rewardOption,
            stage: 1
        });

        exitOrder[msg.sender][blockNumber] = order;

        emit NewExitOrder(msg.sender, order);

        return blockNumber;
    }

    /**
     * @notice Remove exit order.
     * @param _blockNumber Block number when the order was created
     */
    function removeOrder(uint256 _blockNumber) external nonReentrant whenNotPaused {
        ExitOrder storage order = exitOrder[msg.sender][_blockNumber];
        order.stage = 3;
        emit UpdateOrder(msg.sender, _blockNumber, order);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   KEEPER                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Claims gas spent and sends to treasury address
     */
    function claimGas() external onlyKeeper {
        BLAST_YIELD_CONTRACT.claimMaxGas(address(this), msg.sender);
    }

    /**
     * @notice Execute Orders in Batch. Only one order
     * @notice To remove delegator just set it to address(0)
     */
    function executeOrders(ExecuteOrder[] calldata _orders) external onlyKeeper {
        uint256 length = _orders.length;

        // to save gas
        IManager _manager = manager;

        // Check flash loan protection and get token prices in USD; 18 decimals
        (uint256 price0,) = price.getPrices(_manager.getPool());

        // Update rewards
        _manager.aum();

        for (uint256 i; i < length;) {
            uint256 executeLength = _orders[i].blockNumbers.length;
            for (uint256 j; j < executeLength;) {
                ExitOrder storage userOrder = exitOrder[_orders[i].user][_orders[i].blockNumbers[j]];
                uint256 newStage = _executeOrder(_manager, price0, _orders[i], userOrder, j);
                userOrder.stage = newStage;
                emit UpdateOrder(_orders[i].user, _orders[i].blockNumbers[j], userOrder);

                ++j;
            }
            ++i;
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                    VIEW                                    */
    /* -------------------------------------------------------------------------- */
    function previewPosition(
        uint256 price0,
        uint256 price1,
        uint256 amountIn0,
        uint256 amountIn1,
        uint256 position0,
        uint256 position1
    ) public view override returns (uint256) {
        // 18 decimals
        uint256 supply = manager.totalSupply();
        // normalize decimals; 18
        amountIn0 = price.normalise(address(manager.token0()), amountIn0);
        amountIn1 = price.normalise(address(manager.token1()), amountIn1);
        // 36 decimals
        uint256 usdIn = (price0 * amountIn0).add(price1 * amountIn1);

        if (supply != 0) {
            return usdIn.mulDivDown(supply, (price0 * position0).add(price1 * position1)); // 18 decimals
        } else {
            return usdIn.div(1e18); // 18 decimals
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                   GOVERNOR                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Pause Deposits.
     */
    function pause() external onlyGovernor {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    /**
     * @notice Update Internal Contracts.
     */
    function updateInternalContracts(
        address _manager,
        address _price,
        address _compounder,
        address _tracker,
        address _trackerZero,
        address _trackerOne
    ) external onlyGovernor {
        IERC20(address(manager)).safeApprove(address(compounder), 0);

        manager = IManager(_manager);
        price = IPriceHelper(_price);
        compounder = ICompounder(_compounder);
        tracker = IRewardTracker(_tracker);
        trackerZero = ISingleRewardTracker(_trackerZero);
        trackerOne = ISingleRewardTracker(_trackerOne);

        IERC20(address(manager)).safeApprove(_compounder, type(uint256).max);
    }

    /**
     * @notice Set arbitrary approval
     * @param _token token address
     * @param _spender spender address
     * @param _amount token amount
     */
    function govApproval(address _token, address _spender, uint256 _amount) external onlyGovernor {
        IERC20(_token).safeApprove(_spender, _amount);
    }

    /**
     * @notice Emergency Transfer Asset
     * @param _to Who will receive the asset.
     * @param _asset token address.
     */
    function emergencyTransfer(address _to, address _asset) external onlyGovernor {
        uint256 assetBalance = IERC20(_asset).balanceOf(address(this));

        if (assetBalance > 0) {
            // Transfer the ERC20 tokens
            IERC20(_asset).safeTransfer(_to, assetBalance);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                   PRIVATE                                  */
    /* -------------------------------------------------------------------------- */

    function _executeOrder(
        IManager _manager,
        uint256 _price0,
        ExecuteOrder memory _execOrder,
        ExitOrder memory _order,
        uint256 index
    ) private returns (uint256) {
        uint256 diff;

        if (_price0 > _order.price) {
            diff = _price0.sub(_order.price).mulDivDown(PRECISION, _price0.add(_order.price).div(2));
        } else {
            diff = _order.price.sub(_price0).mulDivDown(PRECISION, _price0.add(_order.price).div(2));
        }

        if (diff > deviation || _order.stage != 1) {
            return _order.stage; // Do nothing stage created
        }

        uint256 _shares;
        uint256 _position;

        if (_order.compound) {
            if (compounder.balanceOf(_execOrder.user) < _order.amount) {
                return 3; // Remove stage (User spend his amount)
            }
            _shares = _order.amount;
            _position = compounder.redeem(_shares, _execOrder.user);
        } else {
            if (_order.rewardOption == 0) {
                if (tracker.stakedAmount(_execOrder.user) < _order.amount) {
                    return 3; // Remove stage (User spend his amount)
                }
                _position = _order.amount;
                tracker.withdraw(_execOrder.user, _position);
            } else if (_order.rewardOption == 1) {
                if (trackerZero.stakedAmount(_execOrder.user) < _order.amount) {
                    return 3; // Remove stage (User spend his amount)
                }
                _position = _order.amount;
                trackerZero.withdraw(_execOrder.user, _position);
            } else {
                if (trackerOne.stakedAmount(_execOrder.user) < _order.amount) {
                    return 3; // Remove stage (User spend his amount)
                }
                _position = _order.amount;
                trackerOne.withdraw(_execOrder.user, _position);
            }
        }

        // Burn liquidity; amounts will send to receiver
        (uint256 amount0, uint256 amount1, uint256 amount0AfterRetention, uint256 amount1AfterRetention) =
            _manager.redeemLiquidity(_position, _order.receiver);

        // Check min Amount
        require(amount0 >= _execOrder.minAmount0[index] && amount1 >= _execOrder.minAmount1[index], "Not Enough Amount");

        // Burn Position
        _manager.burn(address(this), _position);

        emit OrderExecuted(
            _execOrder.user,
            _order.blockNumber,
            _price0,
            _position,
            _shares,
            amount0AfterRetention,
            amount1AfterRetention
        );
        return 2; // Executed stage
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library MulDivMathLib {
    uint256 internal constant MAX_UINT256 = 2 ** 256 - 1;

    function mulDivDown(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) { revert(0, 0) }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) { revert(0, 0) }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

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
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2024 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.7.6;
pragma abicoder v2;

import {UpgradeableGovernable} from "src/governance/UpgradeableGovernable.sol";

abstract contract UpgradeableOperableKeepable is UpgradeableGovernable {
    bytes32 public constant OPERATOR = bytes32("OPERATOR");
    bytes32 public constant KEEPER = bytes32("KEEPER");

    modifier onlyOperator() {
        require(hasRole(OPERATOR, msg.sender), "Caller Not Operator");

        _;
    }

    modifier onlyKeeper() {
        require(hasRole(KEEPER, msg.sender), "Caller Not keeper");

        _;
    }

    modifier onlyOperatorOrKeeper() {
        require(hasRole(OPERATOR, msg.sender) || hasRole(KEEPER, msg.sender), "Ivalid Caller");

        _;
    }

    modifier onlyGovernorOrKeeper() {
        require(hasRole(GOVERNOR, msg.sender) || hasRole(KEEPER, msg.sender), "Ivalid Caller");

        _;
    }

    /**
     * @notice Only msg.sender with OPERATOR or GOVERNOR role can call the function.
     */
    modifier onlyGovernorOrOperator() {
        require(hasRole(GOVERNOR, msg.sender) || hasRole(OPERATOR, msg.sender), "Ivalid Caller");
        _;
    }

    modifier onlyOperatorOrKeeperOrThis() {
        require(
            hasRole(KEEPER, msg.sender) || hasRole(OPERATOR, msg.sender) || msg.sender == address(this), "Ivalid Caller"
        );

        _;
    }

    function addOperator(address _newOperator) external onlyGovernor {
        _setupRole(OPERATOR, _newOperator);

        emit OperatorAdded(_newOperator);
    }

    function removeOperator(address _operator) external onlyGovernor {
        revokeRole(OPERATOR, _operator);

        emit OperatorRemoved(_operator);
    }

    function addKeeper(address _newKeeper) external onlyGovernor {
        _setupRole(KEEPER, _newKeeper);

        emit KeeperAdded(_newKeeper);
    }

    function removeKeeper(address _operator) external onlyGovernor {
        revokeRole(KEEPER, _operator);

        emit KeeperRemoved(_operator);
    }

    event OperatorAdded(address _newOperator);
    event OperatorRemoved(address _operator);
    event KeeperAdded(address _newKeeper);
    event KeeperRemoved(address _operator);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import {IPriceHelper} from "src/interfaces/swap/IPriceHelper.sol";

interface IRouter {
    /**
     * @notice Deposit Input Params
     * @param _amount0 Amount of token0
     * @param _amount1 Amount of token1
     * @param _amount0Min Minimum amount of token0 to be minted
     * @param _amount1Min Minimum amount of token1 to be minted
     * @param _minPosition Minimum amount of position to be received to the user
     * @param _minShares Minimum amount of shares to be received to the user
     * @param _receiver Who will receive the shares
     * @param _compound True if user choose autocompounding shares.
     * @param _rewardOption Type of reward.
     *
     */
    struct DepositInput {
        uint256 amount0;
        uint256 amount1;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 minPosition;
        uint256 minShares;
        address receiver;
        bool compound;
        uint8 rewardOption;
    }

    // stage:
    // 1 -> creted;
    // 2 -> executed;
    // 3 -> removed
    struct ExitOrder {
        address receiver;
        uint256 blockNumber;
        uint256 amount;
        uint256 price;
        bool compound;
        uint8 rewardOption;
        uint256 stage;
    }

    struct ExecuteOrder {
        address user;
        uint256[] blockNumbers;
        uint256[] minAmount0;
        uint256[] minAmount1;
    }

    function price() external returns (IPriceHelper);

    function deposit(DepositInput calldata _deposit)
        external
        returns (uint256, /*amount0*/ uint256, /*amount1*/ uint256, /*position*/ uint256); /*shares*/

    function withdraw(
        uint256 _position,
        address _receiver,
        uint256 _amount0Min,
        uint256 _amount1Min,
        bool _compound,
        uint8 _rewardOption
    ) external returns (uint256 amount0, uint256 amount1);

    function compoundDeposit(uint256 _amount0, uint256 _amount1) external;

    function claim(address _receiver, uint8 _rewardOption) external returns (uint256, uint256);

    function previewPosition(
        uint256 price0,
        uint256 price1,
        uint256 amountIn0,
        uint256 amountIn1,
        uint256 position0,
        uint256 position1
    ) external view returns (uint256);

    event Deposit(
        address indexed caller,
        address indexed receiver,
        uint256 amount0,
        uint256 amount1,
        uint256 position,
        uint256 shares,
        uint8 rewardOption
    );
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        uint256 shares,
        uint256 position,
        uint256 amount0,
        uint256 amount1,
        uint256 amount0AfterRetention,
        uint256 amount1AfterRetention,
        uint8 rewardOption
    );
    event CompoundDeposit(address indexed caller, uint256 amount0, uint256 amount1, uint256 position);
    event Claim(address indexed caller, uint256 rewards0, uint256 rewards1, address indexed target, uint8 rewardOption);
    event Compound(address indexed caller, uint256 amount, uint256 shares, uint8 _rewardOption);
    event UnCompound(address indexed caller, uint256 shares, uint256 position, uint8 _rewardOption);
    event NewExitOrder(address indexed user, ExitOrder order);
    event OrderExecuted(
        address indexed user,
        uint256 blockNumber,
        uint256 price0,
        uint256 position,
        uint256 shares,
        uint256 amount0,
        uint256 amount1
    );

    event UpdateOrder(address indexed user, uint256 blockNumber, ExitOrder order);

    event OrderRemoved(address indexed user, ExitOrder order);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

interface ICompounder {
    // Swap Input
    struct Swap {
        address tokenIn;
        uint256 amountIn;
        address tokenOut;
        uint256 minAmountOut;
        bytes externalData;
    }

    function keeperSwap(Swap calldata _swap) external;
    function keeperCompound(uint256 amount0, uint256 amount1) external;

    function compound() external;
    function deposit(uint256 _assets, address _receiver) external returns (uint256);
    function redeem(uint256 _shares, address _receiver) external returns (uint256);

    function previewDeposit(uint256 assets) external view returns (uint256);
    function previewRedeem(uint256 shares) external view returns (uint256);
    function totalAssetsToDeposits(address recipient, uint256 assets) external view returns (uint256);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Compound(uint256 amount0, uint256 amount1, uint256 totalAssets);
    event Deposit(address caller, address receiver, uint256 assets, uint256 shares);
    event Withdraw(address caller, address receiver, uint256, uint256 shares);
    event Retention(
        address indexed receiver,
        uint256 amount0,
        uint256 amount1,
        uint256 amount0AfterRetention,
        uint256 amount1AfterRetention,
        string typeOf
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IRewardTracker {
    // Swap Input
    struct Swap {
        address tokenIn;
        uint256 amountIn;
        address tokenOut;
        uint256 minAmountOut;
        bytes externalData;
    }

    /**
     * @notice Stake into this contract assets to start earning rewards
     * @param _account Owner of the stake and future rewards
     * @param _amount Assets to be staked
     * @return Amount of assets staked
     */
    function stake(address _account, uint256 _amount) external returns (uint256);

    /**
     * @notice Withdraw the staked assets
     * @param _account Owner of the assets to be withdrawn
     * @param _amount Assets to be withdrawn
     * @return Amount of assets witdrawed
     */
    function withdraw(address _account, uint256 _amount) external returns (uint256);

    /**
     * @notice Claim _account cumulative rewards
     * @dev Reward token will be transfer to the _account
     * @param _account Owner of the rewards
     * @return Amount of reward tokens0 transferred
     * @return Amount of reward tokens1 transferred
     */
    function claim(address _account) external returns (uint256, uint256);

    /**
     * @notice Return _account claimable rewards
     * @dev No reward token are transferred
     * @param _account Owner of the rewards
     * @return Amount of reward tokens that can be claim
     */
    function claimable(address _account) external view returns (uint256, uint256);

    /**
     * @notice Return _account staked amount
     * @param _account Owner of the staking
     * @return Staked amount
     */
    function stakedAmount(address _account) external view returns (uint256);

    /**
     * @notice Update global cumulative reward
     * @dev No reward token are transferred
     */
    function updateRewards() external;

    /**
     * @notice Deposit rewards
     * @dev Transfer from called here
     * @param _rewards0 Amount of reward asset0 transferer
     * @param _rewards1 Amount of reward asset1 transferer
     */
    function depositRewards(uint256 _rewards0, uint256 _rewards1) external;

    /**
     * @notice Swap and Process rewards
     * @param _swap Swap data array.
     */
    function swapAndProcess(Swap[] calldata _swap) external;

    event Stake(address indexed depositor, uint256 amount);
    event Withdraw(address indexed _account, uint256 _amount);
    event Claim0(address indexed receiver, uint256 amount);
    event Claim1(address indexed receiver, uint256 amount);
    event MerkleClaim(address[] users, address[] tokens, uint256[] amounts);
    event UpdateRewards0(address indexed _account, uint256 _rewards, uint256 _totalShares, uint256 _rewardPerShare);
    event UpdateRewards1(address indexed _account, uint256 _rewards, uint256 _totalShares, uint256 _rewardPerShare);
    event EmergencyWithdrawal(address indexed caller, address indexed receiver, address[] tokens, uint256 nativeBalanc);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

interface ISingleRewardTracker {
    // Swap Input
    struct Swap {
        address tokenIn;
        uint256 amountIn;
        address tokenOut;
        uint256 minAmountOut;
        bytes externalData;
    }

    /**
     * @notice Stake into this contract assets to start earning rewards
     * @param _account Owner of the stake and future rewards
     * @param _amount Assets to be staked
     * @return Amount of assets staked
     */
    function stake(address _account, uint256 _amount) external returns (uint256);

    /**
     * @notice Withdraw the staked assets
     * @param _account Owner of the assets to be withdrawn
     * @param _amount Assets to be withdrawn
     * @return Amount of assets witdrawed
     */
    function withdraw(address _account, uint256 _amount) external returns (uint256);

    /**
     * @notice Claim _account cumulative rewards
     * @dev Reward token will be transfer to the _account
     * @param _account Owner of the rewards
     * @return Amount of reward transferred
     */
    function claim(address _account) external returns (uint256);

    /**
     * @notice Return _account claimable rewards
     * @dev No reward token are transferred
     * @param _account Owner of the rewards
     * @return Amount of reward tokens that can be claim
     */
    function claimable(address _account) external view returns (uint256);

    /**
     * @notice Return _account staked amount
     * @param _account Owner of the staking
     * @return Staked amount
     */
    function stakedAmount(address _account) external view returns (uint256);

    /**
     * @notice Update global cumulative reward
     * @dev No reward token are transferred
     */
    function updateRewards() external;

    /**
     * @notice Deposit rewards
     * @dev Transfer from called here
     * @param _rewards Amount of reward asset transfered
     */
    function depositRewards(uint256 _rewards) external;

    /**
     * @notice Swap and Process rewards
     * @param _swap Swap data array.
     */
    function swapAndProcess(Swap[] calldata _swap) external;

    event Stake(address indexed depositor, uint256 amount);
    event Withdraw(address indexed _account, uint256 _amount);
    event Claim(address indexed receiver, uint256 amount);
    event MerkleClaim(address[] users, address[] tokens, uint256[] amounts);
    event UpdateRewards(address indexed _account, uint256 _rewards, uint256 _totalShares, uint256 _rewardPerShare);
    event EmergencyWithdrawal(address indexed caller, address indexed receiver, address[] tokens, uint256 nativeBalanc);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.7.6;
pragma abicoder v2;

import {IAggregatorV3} from "src/interfaces/swap/IAggregatorV3.sol";

interface IPriceHelper {
    // Pool Data needed for get safe price
    struct PoolData {
        IAggregatorV3 feed;
        address referenceToken;
        int24 secondsAgo;
        uint256 threshold;
        uint256 stalePeriod;
    }
    // 1e30 100%

    struct PoolInput {
        address referenceToken;
        int24 secondsAgo;
        uint256 threshold;
        uint256 stalePeriod;
    }

    function normalise(address _token, uint256 _amount) external view returns (uint256 normalised);
    function getPrices(address pool) external view returns (uint256 price0, uint256 price1);
    function checkManipulation(address pool) external view returns (uint256 spot);
    function updatePoolData(address pool, PoolInput calldata _input) external;

    function amountsForLiquidity(address pool, int24 tickLower, int24 tickUpper, uint128 liquidity)
        external
        view
        returns (uint256, uint256);
    function liquidityForAmounts(address pool, int24 tickLower, int24 tickUpper, uint256 amount0, uint256 amount1)
        external
        view
        returns (uint128);
    function amountsForAmount0(address pool, int24 tickLower, int24 tickUpper, uint256 amount0)
        external
        view
        returns (uint256, uint256);
    function amountsForAmount1(address pool, int24 tickLower, int24 tickUpper, uint256 amount1)
        external
        view
        returns (uint256, uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

import {IERC20Upgradeable} from "@openzeppelin-upgrades/token/ERC20/IERC20Upgradeable.sol";

interface IManager is IERC20Upgradeable {
    //Concentarte liquidity range
    struct Range {
        int24 tickLower;
        int24 tickUpper;
    }

    // Swap Input
    struct Swap {
        address tokenIn;
        uint256 amountIn;
        address tokenOut;
        uint256 minAmountOut;
        bytes externalData;
    }

    struct NewRange {
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0;
        uint256 amount1;
    }

    struct ExistingRange {
        uint256 index;
        bool burn;
        bool remove;
        uint256 amount0;
        uint256 amount1;
    }

    function aumWithoutCollect() external view returns (uint256 amount0, uint256 amount1);

    function aum() external returns (uint256 amount0, uint256 amount1);

    function getRanges() external returns (Range[] memory);

    function mintLiquidity(address _user, uint256 _index, uint256 _amount0, uint256 _amount1)
        external
        returns (uint256 amount0, uint256 amount1);

    function redeemLiquidity(uint256 _position, address _receiver)
        external
        returns (uint256 amount0, uint256 amount1, uint256 amount0AfterRetention, uint256 amount1AfterRetention);

    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;

    function transferAssets(address from, uint256 amount0, uint256 amount1) external;

    function previewRedeemLiquidity(uint256 _position)
        external
        view
        returns (uint256 amount0, uint256 amount1, uint256 amount0AfterRetention, uint256 amount1AfterRetention);

    function defaultRange() external view returns (int24, int24);

    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function getPool() external view returns (address);

    function burnLiquidity(uint128 _liquidity, uint256 _index, bool _notional)
        external
        returns (uint256 amount0, uint256 amount1);

    function rebalance(Swap memory _swap, ExistingRange[] calldata _existingRanges, NewRange[] calldata _newRange)
        external;

    function lpPosition(int24 tickLower, int24 tickUpper)
        external
        view
        returns (uint128 liquidity, uint128 rewards0, uint128 rewards1);

    function swapDefaultRange(uint256 _index) external;

    function toggleWithdrawalRate() external;

    function emergencyTransfer(address _to, address _asset) external;

    function setIncentives(address _incentiveReceiver, uint256 _yieldRate, uint256 _withdrawalRate) external;

    event Rewards(uint256 rewards0, uint256 rewards1);
    event RewardsPerRange(Range indexed, uint256 rewards0, uint256 rewards1);
    event Position(uint256 amount0, uint256 amount1);
    event Retention(
        address indexed receiver,
        uint256 amount0,
        uint256 amount1,
        uint256 amount0AfterRetention,
        uint256 amount1AfterRetention,
        string typeOf
    );
    event ExistingRangesRebalance(ExistingRange[]);
    event NewRangesRebalance(NewRange[]);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

enum YieldMode {
    AUTOMATIC,
    VOID,
    CLAIMABLE
}

enum GasMode {
    VOID,
    CLAIMABLE
}

interface IBlast {
    // configure
    function configureContract(address contractAddress, YieldMode _yield, GasMode gasMode, address governor) external;
    function configure(YieldMode _yield, GasMode gasMode, address governor) external;

    // base configuration options
    function configureClaimableYield() external;
    function configureClaimableYieldOnBehalf(address contractAddress) external;
    function configureAutomaticYield() external;
    function configureAutomaticYieldOnBehalf(address contractAddress) external;
    function configureVoidYield() external;
    function configureVoidYieldOnBehalf(address contractAddress) external;
    function configureClaimableGas() external;
    function configureClaimableGasOnBehalf(address contractAddress) external;
    function configureVoidGas() external;
    function configureVoidGasOnBehalf(address contractAddress) external;
    function configureGovernor(address _governor) external;
    function configureGovernorOnBehalf(address _newGovernor, address contractAddress) external;

    // claim yield
    function claimYield(address contractAddress, address recipientOfYield, uint256 amount) external returns (uint256);
    function claimAllYield(address contractAddress, address recipientOfYield) external returns (uint256);

    // claim gas
    function claimAllGas(address contractAddress, address recipientOfGas) external returns (uint256);
    function claimGasAtMinClaimRate(address contractAddress, address recipientOfGas, uint256 minClaimRateBips)
        external
        returns (uint256);
    function claimMaxGas(address contractAddress, address recipientOfGas) external returns (uint256);
    function claimGas(address contractAddress, address recipientOfGas, uint256 gasToClaim, uint256 gasSecondsToConsume)
        external
        returns (uint256);

    // read functions
    function readClaimableYield(address contractAddress) external view returns (uint256);
    function readYieldConfiguration(address contractAddress) external view returns (uint8);
    function readGasParams(address contractAddress)
        external
        view
        returns (uint256 etherSeconds, uint256 etherBalance, uint256 lastUpdated, GasMode);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2024 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.7.6;
pragma abicoder v2;

import {AccessControlUpgradeable} from "@openzeppelin-upgrades/access/AccessControlUpgradeable.sol";

abstract contract UpgradeableGovernable is AccessControlUpgradeable {
    /**
     * @notice Governor role
     */
    bytes32 public constant GOVERNOR = bytes32("GOVERNOR");

    /**
     * @notice Initialize Governable contract.
     */
    function __Governable_init(address _governor) internal initializer {
        __AccessControl_init();
        _setupRole(GOVERNOR, _governor);
    }

    /**
     * @notice Modifier if msg.sender has not Governor role revert.
     */
    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    /**
     * @notice Update Governor Role
     */
    function updateGovernor(address _newGovernor) external virtual onlyGovernor {
        renounceRole(GOVERNOR, msg.sender);
        _setupRole(GOVERNOR, _newGovernor);

        emit GovernorUpdated(msg.sender, _newGovernor);
    }

    /**
     * @notice If msg.sender has not Governor role revert.
     */
    function _onlyGovernor() private view {
        require(hasRole(GOVERNOR, msg.sender), "Caller Not Gov");
    }

    event GovernorUpdated(address _oldGovernor, address _newGovernor);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.2 <0.8.0;

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
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library EnumerableSetUpgradeable {
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}