// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { OwnableUpgradeableSafe } from "./OwnableUpgradeableSafe.sol";
import { IInsuranceFund } from "./interfaces/IInsuranceFund.sol";
import { BlockContext } from "./utils/BlockContext.sol";
import { IAmm } from "./interfaces/IAmm.sol";
import { UIntMath } from "./utils/UIntMath.sol";
import { IntMath } from "./utils/IntMath.sol";
import { TransferHelper } from "./utils/TransferHelper.sol";
import { IInsuranceFundCallee } from "./interfaces/IInsuranceFundCallee.sol";
import { IETHStakingPool } from "./interfaces/IETHStakingPool.sol";
import { IClearingHouse } from "./interfaces/IClearingHouse.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

contract InsuranceFund is IInsuranceFund, OwnableUpgradeableSafe, BlockContext {
    using UIntMath for uint256;
    using IntMath for int256;
    using TransferHelper for IERC20;

    //**********************************************************//
    //    The below state variables can not change the order    //
    //**********************************************************//

    mapping(address => bool) private ammMap;
    mapping(address => bool) private quoteTokenMap;
    IAmm[] private amms;
    IERC20[] public quoteTokens;

    // contract dependencies;
    address private beneficiary;

    // amm => budget of the insurance fund, allocated to each market
    mapping(IAmm => uint256) public budgetsAllocated;

    address public ethStakingPool;

    address public tttStakingPool;

    // used to calculate the minimum insurance fund reserve amount for each collection
    uint8 public reserveCoeff;

    uint256[50] private __gap;

    //**********************************************************//
    //    The above state variables can not change the order    //
    //**********************************************************//

    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//

    //
    // EVENTS
    //

    event Withdrawn(address withdrawer, uint256 amount);
    event TokenAdded(address tokenAddress);
    event TokenRemoved(address tokenAddress);
    event ShutdownAllAmms(uint256 blockNumber);
    event AmmAdded(address amm);
    event AmmRemoved(address amm);

    //
    // FUNCTIONS
    //

    function initialize() public initializer {
        __Ownable_init();
        reserveCoeff = 1;
    }

    /**
     * @dev only owner can call
     * @param _amm IAmm address
     */
    function addAmm(IAmm _amm) public onlyOwner {
        require(!isExistedAmm(_amm), "IF_AAA"); //amm already added
        ammMap[address(_amm)] = true;
        amms.push(_amm);
        emit AmmAdded(address(_amm));

        // add token if it's new one
        IERC20 token = _amm.quoteAsset();
        if (!_isQuoteTokenExisted(token)) {
            quoteTokens.push(token);
            quoteTokenMap[address(token)] = true;
            emit TokenAdded(address(token));
        }
    }

    /**
     * @dev only owner can call. no need to call
     * @param _amm IAmm address
     */
    function removeAmm(IAmm _amm) external onlyOwner {
        require(isExistedAmm(_amm), "IF_ANE"); //amm not existed
        ammMap[address(_amm)] = false;
        uint256 ammLength = amms.length;
        for (uint256 i = 0; i < ammLength; i++) {
            if (amms[i] == _amm) {
                amms[i] = amms[ammLength - 1];
                amms.pop();
                emit AmmRemoved(address(_amm));
                break;
            }
        }
    }

    /**
     * @notice shutdown all Amms when fatal error happens
     * @dev only owner can call. Emit `ShutdownAllAmms` event
     */
    function shutdownAllAmm() external onlyOwner {
        for (uint256 i; i < amms.length; i++) {
            amms[i].shutdown();
        }
        emit ShutdownAllAmms(block.number);
    }

    function removeToken(IERC20 _token) external onlyOwner {
        require(_isQuoteTokenExisted(_token), "IF_TNE"); //token not existed

        quoteTokenMap[address(_token)] = false;
        uint256 quoteTokensLength = getQuoteTokenLength();
        for (uint256 i = 0; i < quoteTokensLength; i++) {
            if (quoteTokens[i] == _token) {
                if (i < quoteTokensLength - 1) {
                    quoteTokens[i] = quoteTokens[quoteTokensLength - 1];
                }
                quoteTokens.pop();
                break;
            }
        }

        // transfer the quoteToken to owner.
        if (_balanceOf(_token) > 0) {
            _token.safeTransfer(owner(), _balanceOf(_token));
        }

        emit TokenRemoved(address(_token));
    }

    function setBeneficiary(address _beneficiary) external onlyOwner {
        require(_beneficiary != address(0), "IF_ZA");
        beneficiary = _beneficiary;
    }

    /**
     * @notice activate the usage of ETH staking pool, can be called only by owner
     * @param _pool the address of the staking pool
     */
    function activateETHStakingPool(address _pool) external onlyOwner {
        require(_pool != address(0), "IF_ZA");
        ethStakingPool = _pool;
    }

    /**
     * @notice deactivate the usage of the ETH staking pool, can be called only by owner
     */
    function deactivateETHStakingPool() external onlyOwner {
        ethStakingPool = address(0);
    }

    /**
     * @notice decide how much insurance fund should be bigger, at least 1 times than vault
     */
    function setReserveCoeff(uint8 _coeff) external onlyOwner {
        require(_coeff >= 1, "IF_IC"); //invalid coefficient
        reserveCoeff = _coeff;
    }

    /**
     * @notice withdraw token to vault to cover cost, can be called only by the clearing house
     * cost is covered as follows if the staking pool has been activated
     * 1. if there is reward, it is used first
     * 2. if it is still not enough, this insurance fund is used
     * 3. if it is also still not enough, the staking principal is used
     * if the staking pool has not been activated
     * all is covered by this insurance fund
     */
    function withdraw(IAmm _amm, uint256 _amount) external override {
        uint256 budget = budgetsAllocated[_amm];
        IERC20 quoteToken = _amm.quoteAsset();
        require(beneficiary == _msgSender(), "IF_NB"); //not beneficiary
        require(_isQuoteTokenExisted(quoteToken), "IF_ANS"); //asset not supported
        address _ethStakingPool = ethStakingPool;
        if (_ethStakingPool != address(0) && quoteToken == IETHStakingPool(_ethStakingPool).quoteToken()) {
            // check reward
            uint256 amountCoveredByReward;
            int256 reward = IETHStakingPool(_ethStakingPool).calculateTotalReward();
            if (reward > 0) {
                amountCoveredByReward = Math.min(_amount, reward.abs());
            }
            // check this insurance fund
            uint256 amountCoveredByIF;
            if (_amount > amountCoveredByReward && budget > 0) {
                amountCoveredByIF = Math.min(_amount - amountCoveredByReward, budget);
                budgetsAllocated[_amm] -= amountCoveredByIF;
            }
            // check the eth staking pool
            uint256 amountCoveredByStakingPrincipal;
            if (_amount > amountCoveredByReward + amountCoveredByIF) {
                amountCoveredByStakingPrincipal = _amount - amountCoveredByReward - amountCoveredByIF;
            }

            if (amountCoveredByReward + amountCoveredByStakingPrincipal > 0) {
                IETHStakingPool(_ethStakingPool).withdraw(_amm, amountCoveredByReward + amountCoveredByStakingPrincipal);
            }
        } else {
            require(budget >= _amount, "IF_FNE"); //fund not enough
            budgetsAllocated[_amm] -= _amount;
        }
        quoteToken.safeTransfer(_msgSender(), _amount);
        emit Withdrawn(_msgSender(), _amount);
    }

    /**
     * @notice deposited token is distributed to this insurance fund and the staking pool as follows
     * if the staking pool has been activated
     * 1. staking principal is replenished first
     * 2. tribe3 reserve (insurance fund) is replenished up to vault * K
     * 3. the remain amount is distributed as reward
     * if the staking pool has not been activated
     * all fund is deposited to this insurance fund
     */
    function deposit(IAmm _amm, uint256 _amount) external override {
        IERC20 quoteToken = _amm.quoteAsset();
        require(_isQuoteTokenExisted(quoteToken), "IF_ANS"); //asset not supported
        uint256 balanceBefore = quoteToken.balanceOf(address(this));
        IInsuranceFundCallee(_msgSender()).depositCallback(quoteToken, _amount);
        _amount = quoteToken.balanceOf(address(this)) - balanceBefore;
        address _ethStakingPool = ethStakingPool;
        if (_ethStakingPool != address(0) && quoteToken == IETHStakingPool(_ethStakingPool).quoteToken()) {
            // replenish the staking principal if it has been activated
            uint256 amountToStakingPool;
            int256 reward = IETHStakingPool(_ethStakingPool).calculateTotalReward();
            if (reward < 0) {
                amountToStakingPool = Math.min(_amount, reward.abs());
            }
            // replenish this insurance fund
            uint256 amountToInsuranceFund;
            if (_amount > amountToStakingPool) {
                uint256 budget = budgetsAllocated[_amm];
                uint256 reserveAmount = IClearingHouse(beneficiary).getVaultFor(_amm) * reserveCoeff;
                if (reserveAmount > budget) {
                    amountToInsuranceFund = Math.min(_amount - amountToStakingPool, reserveAmount - budget);
                    budgetsAllocated[_amm] += amountToInsuranceFund;
                }
            }
            // distribute the remain amount as reward to the eth staking pool if it has been activated
            uint256 amountToReward;
            if (_amount > amountToStakingPool + amountToInsuranceFund) {
                amountToReward = _amount - amountToStakingPool - amountToInsuranceFund;
            }
            // transfer reward and principal replenishment to the eth staking pool
            if (amountToStakingPool + amountToReward > 0) {
                quoteToken.safeTransfer(_ethStakingPool, amountToStakingPool + amountToReward);
            }
        } else {
            budgetsAllocated[_amm] += _amount;
        }
    }

    //
    // VIEW
    //

    function getQuoteTokenLength() public view returns (uint256) {
        return quoteTokens.length;
    }

    function isExistedAmm(IAmm _amm) public view override returns (bool) {
        return ammMap[address(_amm)];
    }

    function getAllAmms() external view override returns (IAmm[] memory) {
        return amms;
    }

    function getAvailableBudgetFor(IAmm _amm) external view override returns (uint256 budget) {
        budget = budgetsAllocated[_amm];
        address _ethStakingPool = ethStakingPool;
        if (_ethStakingPool != address(0)) {
            IClearingHouse clearingHouse = IClearingHouse(beneficiary);
            uint256 currentVault = clearingHouse.getVaultFor(_amm);
            IERC20 quoteToken = _amm.quoteAsset();
            uint256 totalVault = quoteToken.balanceOf(address(clearingHouse));
            uint256 balanceOfStakingPool = quoteToken.balanceOf(_ethStakingPool);
            if (totalVault != 0) {
                budget += Math.mulDiv(balanceOfStakingPool, currentVault, totalVault);
            }
        }
    }

    //
    // private
    //

    function _isQuoteTokenExisted(IERC20 _token) internal view returns (bool) {
        return quoteTokenMap[address(_token)];
    }

    function _balanceOf(IERC20 _quoteToken) internal view returns (uint256) {
        return _quoteToken.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract OwnableUpgradeableSafe is OwnableUpgradeable {
    function renounceOwnership() public view override onlyOwner {
        revert("OS_NR"); // not able to renounce
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

// wrap block.xxx functions for testing
// only support timestamp and number so far
abstract contract BlockContext {
    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    uint256[50] private __gap;

    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function _blockNumber() internal view virtual returns (uint256) {
        return block.number;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IAmm } from "./IAmm.sol";

interface IInsuranceFund {
    function withdraw(IAmm _amm, uint256 _amount) external;

    function deposit(IAmm _amm, uint256 _amount) external;

    function isExistedAmm(IAmm _amm) external view returns (bool);

    function getAllAmms() external view returns (IAmm[] memory);

    function getAvailableBudgetFor(IAmm _amm) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/// @dev Implements simple fixed point math add, sub, mul and div operations.
library UIntMath {
    string private constant ERROR_NON_CONVERTIBLE = "Math: uint value is bigger than _INT256_MAX";

    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (uint256) {
        return 10**uint256(decimals);
    }

    function toInt(uint256 x) internal pure returns (int256) {
        require(uint256(type(int256).max) >= x, ERROR_NON_CONVERTIBLE);
        return int256(x);
    }

    // function modD(uint256 x, uint256 y) internal pure returns (uint256) {
    //     return (x * unit(18)) % y;
    // }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function mulD(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulD(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function mulD(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return Math.mulDiv(x, y, unit(decimals));
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divD(uint256 x, uint256 y) internal pure returns (uint256) {
        return divD(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divD(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return Math.mulDiv(x, unit(decimals), y);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/// @dev Implements simple signed fixed point math add, sub, mul and div operations.
library IntMath {
    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (int256) {
        return int256(10**uint256(decimals));
    }

    function toUint(int256 x) internal pure returns (uint256) {
        return uint256(abs(x));
    }

    function abs(int256 x) internal pure returns (uint256) {
        uint256 t = 0;
        if (x < 0) {
            t = uint256(0 - x);
        } else {
            t = uint256(x);
        }
        return t;
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function mulD(int256 x, int256 y) internal pure returns (int256) {
        return mulD(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function mulD(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        if (x == 0 || y == 0) {
            return 0;
        }
        if (x * y < 0) {
            return int256(Math.mulDiv(abs(x), abs(y), 10**uint256(decimals))) * (-1);
        } else {
            return int256(Math.mulDiv(abs(x), abs(y), 10**uint256(decimals)));
        }
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divD(int256 x, int256 y) internal pure returns (int256) {
        return divD(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divD(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        if (x == 0 || y == 0) {
            return 0;
        }
        if (x * y < 0) {
            return int256(Math.mulDiv(abs(x), 10**uint256(decimals), abs(y))) * (-1);
        } else {
            return int256(Math.mulDiv(abs(x), 10**uint256(decimals), abs(y)));
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IPriceFeed } from "./IPriceFeed.sol";

interface IAmm {
    /**
     * @notice asset direction, used in getQuotePrice, getBasePrice, swapInput and swapOutput
     * @param ADD_TO_AMM add asset to Amm
     * @param REMOVE_FROM_AMM remove asset from Amm
     */
    enum Dir {
        ADD_TO_AMM,
        REMOVE_FROM_AMM
    }

    function swapInput(
        Dir _dir,
        uint256 _amount,
        bool _isQuote,
        bool _canOverFluctuationLimit
    )
        external
        returns (
            uint256 quoteAssetAmount,
            int256 baseAssetAmount,
            uint256 spreadFee,
            uint256 tollFee
        );

    function swapOutput(
        Dir _dir,
        uint256 _amount,
        bool _isQuote,
        bool _canOverFluctuationLimit
    )
        external
        returns (
            uint256 quoteAssetAmount,
            int256 baseAssetAmount,
            uint256 spreadFee,
            uint256 tollFee
        );

    function repegCheck(uint256 budget)
        external
        returns (
            bool,
            int256,
            uint256,
            uint256
        );

    function adjust(uint256 _quoteAssetReserve, uint256 _baseAssetReserve) external;

    function shutdown() external;

    function settleFunding(uint256 _cap)
        external
        returns (
            int256 premiumFractionLong,
            int256 premiumFractionShort,
            int256 fundingPayment
        );

    function calcFee(uint256 _quoteAssetAmount) external view returns (uint256, uint256);

    //
    // VIEW
    //

    function getFormulaicUpdateKResult(int256 budget)
        external
        view
        returns (
            bool isAdjustable,
            int256 cost,
            uint256 newQuoteAssetReserve,
            uint256 newBaseAssetReserve
        );

    function getMaxKDecreaseRevenue(uint256 _quoteAssetReserve, uint256 _baseAssetReserve) external view returns (int256 revenue);

    function isOverFluctuationLimit(Dir _dirOfBase, uint256 _baseAssetAmount) external view returns (bool);

    function getQuoteTwap(Dir _dir, uint256 _quoteAssetAmount) external view returns (uint256);

    function getBaseTwap(Dir _dir, uint256 _baseAssetAmount) external view returns (uint256);

    function getQuotePrice(Dir _dir, uint256 _quoteAssetAmount) external view returns (uint256);

    function getBasePrice(Dir _dir, uint256 _baseAssetAmount) external view returns (uint256);

    function getQuotePriceWithReserves(
        Dir _dir,
        uint256 _quoteAssetAmount,
        uint256 _quoteAssetPoolAmount,
        uint256 _baseAssetPoolAmount
    ) external pure returns (uint256);

    function getBasePriceWithReserves(
        Dir _dir,
        uint256 _baseAssetAmount,
        uint256 _quoteAssetPoolAmount,
        uint256 _baseAssetPoolAmount
    ) external pure returns (uint256);

    function getSpotPrice() external view returns (uint256);

    // overridden by state variable

    function initMarginRatio() external view returns (uint256);

    function maintenanceMarginRatio() external view returns (uint256);

    function liquidationFeeRatio() external view returns (uint256);

    function partialLiquidationRatio() external view returns (uint256);

    function quoteAsset() external view returns (IERC20);

    function priceFeedKey() external view returns (bytes32);

    function tradeLimitRatio() external view returns (uint256);

    function fundingPeriod() external view returns (uint256);

    function priceFeed() external view returns (IPriceFeed);

    function getReserve() external view returns (uint256, uint256);

    function open() external view returns (bool);

    function adjustable() external view returns (bool);

    function canLowerK() external view returns (bool);

    function ptcKIncreaseMax() external view returns (uint256);

    function ptcKDecreaseMax() external view returns (uint256);

    function getSettlementPrice() external view returns (uint256);

    function getCumulativeNotional() external view returns (int256);

    function getBaseAssetDelta() external view returns (int256);

    function getUnderlyingPrice() external view returns (uint256);

    function isOverSpreadLimit()
        external
        view
        returns (
            bool result,
            uint256 marketPrice,
            uint256 oraclePrice
        );

    function isOverSpread(uint256 _limit)
        external
        view
        returns (
            bool result,
            uint256 marketPrice,
            uint256 oraclePrice
        );

    function getFundingPaymentEstimation(uint256 _cap)
        external
        view
        returns (
            bool notPayable,
            int256 premiumFractionLong,
            int256 premiumFractionShort,
            int256 fundingPayment,
            uint256 underlyingPrice
        );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IInsuranceFundCallee {
    function depositCallback(IERC20 _token, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IAmm } from "./IAmm.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IETHStakingPool {
    // overriden by storage var
    function totalSupply() external view returns (uint256);

    // overriden by storage var
    function quoteToken() external view returns (IERC20);

    function calculateTotalReward() external view returns (int256);

    function withdraw(IAmm _amm, uint256 _amount) external;
}

// SPDX-License-Identifier: BSD-3-CLAUSE
pragma solidity 0.8.9;

import { IAmm } from "./IAmm.sol";

interface IClearingHouse {
    enum Side {
        BUY,
        SELL
    }

    /// @notice This struct records personal position information
    /// @param size denominated in amm.baseAsset
    /// @param margin isolated margin
    /// @param openNotional the quoteAsset value of position when opening position. the cost of the position
    /// @param lastUpdatedCumulativePremiumFraction for calculating funding payment, record at the moment every time when trader open/reduce/close position
    /// @param blockNumber the block number of the last position
    struct Position {
        int256 size;
        int256 margin;
        uint256 openNotional;
        int256 lastUpdatedCumulativePremiumFraction;
        uint256 blockNumber;
    }

    function addMargin(IAmm _amm, uint256 _addedMargin) external;

    function removeMargin(IAmm _amm, uint256 _removedMargin) external;

    function settlePosition(IAmm _amm) external;

    function openPosition(
        IAmm _amm,
        Side _side,
        uint256 _amount,
        uint256 _leverage,
        uint256 _oppositeAmountLimit,
        bool _isQuote
    ) external;

    function closePosition(IAmm _amm, uint256 _quoteAssetAmountLimit) external;

    function liquidate(IAmm _amm, address _trader) external;

    function payFunding(IAmm _amm) external;

    // VIEW FUNCTIONS
    function getMarginRatio(IAmm _amm, address _trader) external view returns (int256);

    function getPosition(IAmm _amm, address _trader) external view returns (Position memory);

    function getVaultFor(IAmm _amm) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TH_STF"); // failed Safe Transfer From
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TH_ST"); // failed Safe Transfer
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TH_SA"); // failed Safe Approve
    }

    // /// @notice Transfers ETH to the recipient address
    // /// @dev Fails with `STE`
    // /// @param to The destination of the transfer
    // /// @param value The value to be transferred
    // function safeTransferETH(address to, uint256 value) internal {
    //     (bool success, ) = to.call{value: value}(new bytes(0));
    //     require(success, 'STE');
    // }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
        return a >= b ? a : b;
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

interface IPriceFeed {
    // get latest price
    function getPrice(bytes32 _priceFeedKey) external view returns (uint256);

    // get latest timestamp
    function getLatestTimestamp(bytes32 _priceFeedKey) external view returns (uint256);

    // get previous price with _back rounds
    function getPreviousPrice(bytes32 _priceFeedKey, uint256 _numOfRoundBack) external view returns (uint256);

    // get previous timestamp with _back rounds
    function getPreviousTimestamp(bytes32 _priceFeedKey, uint256 _numOfRoundBack) external view returns (uint256);

    // get twap price depending on _period
    function getTwapPrice(bytes32 _priceFeedKey, uint256 _interval) external view returns (uint256);

    function setLatestData(
        bytes32 _priceFeedKey,
        uint256 _price,
        uint256 _timestamp,
        uint256 _roundId
    ) external;

    function decimals(bytes32 _priceFeedKey) external view returns (uint8);
}