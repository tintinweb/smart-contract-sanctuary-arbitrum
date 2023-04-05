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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {BinHelper} from "./libraries/BinHelper.sol";
import {Clone} from "./libraries/Clone.sol";
import {Constants} from "./libraries/Constants.sol";
import {FeeHelper} from "./libraries/FeeHelper.sol";
import {LiquidityConfigurations} from "./libraries/math/LiquidityConfigurations.sol";
import {ILBFactory} from "./interfaces/ILBFactory.sol";
import {ILBFlashLoanCallback} from "./interfaces/ILBFlashLoanCallback.sol";
import {ILBPair} from "./interfaces/ILBPair.sol";
import {LBToken} from "./LBToken.sol";
import {OracleHelper} from "./libraries/OracleHelper.sol";
import {PackedUint128Math} from "./libraries/math/PackedUint128Math.sol";
import {PairParameterHelper} from "./libraries/PairParameterHelper.sol";
import {PriceHelper} from "./libraries/PriceHelper.sol";
import {ReentrancyGuard} from "./libraries/ReentrancyGuard.sol";
import {SafeCast} from "./libraries/math/SafeCast.sol";
import {SampleMath} from "./libraries/math/SampleMath.sol";
import {TreeMath} from "./libraries/math/TreeMath.sol";
import {Uint256x256Math} from "./libraries/math/Uint256x256Math.sol";

/**
 * @title Liquidity Book Pair
 * @author Trader Joe
 * @notice The Liquidity Book Pair contract is the core contract of the Liquidity Book protocol
 */
contract LBPair is LBToken, ReentrancyGuard, Clone, ILBPair {
    using BinHelper for bytes32;
    using FeeHelper for uint128;
    using LiquidityConfigurations for bytes32;
    using OracleHelper for OracleHelper.Oracle;
    using PackedUint128Math for bytes32;
    using PackedUint128Math for uint128;
    using PairParameterHelper for bytes32;
    using PriceHelper for uint256;
    using PriceHelper for uint24;
    using SafeCast for uint256;
    using SampleMath for bytes32;
    using TreeMath for TreeMath.TreeUint24;
    using Uint256x256Math for uint256;

    modifier onlyFactory() {
        if (msg.sender != address(_factory)) revert LBPair__OnlyFactory();
        _;
    }

    modifier onlyProtocolFeeRecipient() {
        if (msg.sender != _factory.getFeeRecipient()) revert LBPair__OnlyProtocolFeeRecipient();
        _;
    }

    uint256 private constant _MAX_TOTAL_FEE = 0.1e18; // 10%

    ILBFactory private immutable _factory;

    bytes32 private _parameters;

    bytes32 private _reserves;
    bytes32 private _protocolFees;

    mapping(uint256 => bytes32) private _bins;

    TreeMath.TreeUint24 private _tree;
    OracleHelper.Oracle private _oracle;

    /**
     * @dev Constructor for the Liquidity Book Pair contract that sets the Liquidity Book Factory
     * @param factory_ The Liquidity Book Factory
     */
    constructor(ILBFactory factory_) {
        _factory = factory_;

        // Disable the initialize function
        _parameters = bytes32(uint256(1));
    }

    /**
     * @notice Initialize the Liquidity Book Pair fee parameters and active id
     * @dev Can only be called by the Liquidity Book Factory
     * @param baseFactor The base factor for the static fee
     * @param filterPeriod The filter period for the static fee
     * @param decayPeriod The decay period for the static fee
     * @param reductionFactor The reduction factor for the static fee
     * @param variableFeeControl The variable fee control for the static fee
     * @param protocolShare The protocol share for the static fee
     * @param maxVolatilityAccumulator The max volatility accumulator for the static fee
     * @param activeId The active id of the Liquidity Book Pair
     */
    function initialize(
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        uint24 activeId
    ) external override onlyFactory {
        bytes32 parameters = _parameters;
        if (parameters != 0) revert LBPair__AlreadyInitialized();

        __ReentrancyGuard_init();

        _setStaticFeeParameters(
            parameters.setActiveId(activeId).updateIdReference(),
            baseFactor,
            filterPeriod,
            decayPeriod,
            reductionFactor,
            variableFeeControl,
            protocolShare,
            maxVolatilityAccumulator
        );
    }

    /**
     * @notice Returns the Liquidity Book Factory
     * @return factory The Liquidity Book Factory
     */
    function getFactory() external view override returns (ILBFactory factory) {
        return _factory;
    }

    /**
     * @notice Returns the token X of the Liquidity Book Pair
     * @return tokenX The address of the token X
     */
    function getTokenX() external pure override returns (IERC20 tokenX) {
        return _tokenX();
    }

    /**
     * @notice Returns the token Y of the Liquidity Book Pair
     * @return tokenY The address of the token Y
     */
    function getTokenY() external pure override returns (IERC20 tokenY) {
        return _tokenY();
    }

    /**
     * @notice Returns the bin step of the Liquidity Book Pair
     * @dev The bin step is the increase in price between two consecutive bins, in basis points.
     * For example, a bin step of 1 means that the price of the next bin is 0.01% higher than the price of the previous bin.
     * @return binStep The bin step of the Liquidity Book Pair, in 10_000th
     */
    function getBinStep() external pure override returns (uint16) {
        return _binStep();
    }

    /**
     * @notice Returns the reserves of the Liquidity Book Pair
     * This is the sum of the reserves of all bins, minus the protocol fees.
     * @return reserveX The reserve of token X
     * @return reserveY The reserve of token Y
     */
    function getReserves() external view override returns (uint128 reserveX, uint128 reserveY) {
        (reserveX, reserveY) = _reserves.sub(_protocolFees).decode();
    }

    /**
     * @notice Returns the active id of the Liquidity Book Pair
     * @dev The active id is the id of the bin that is currently being used for swaps.
     * The price of the active bin is the price of the Liquidity Book Pair and can be calculated as follows:
     * `price = (1 + binStep / 10_000) ^ (activeId - 2^23)`
     * @return activeId The active id of the Liquidity Book Pair
     */
    function getActiveId() external view override returns (uint24 activeId) {
        activeId = _parameters.getActiveId();
    }

    /**
     * @notice Returns the reserves of a bin
     * @param id The id of the bin
     * @return binReserveX The reserve of token X in the bin
     * @return binReserveY The reserve of token Y in the bin
     */
    function getBin(uint24 id) external view override returns (uint128 binReserveX, uint128 binReserveY) {
        (binReserveX, binReserveY) = _bins[id].decode();
    }

    /**
     * @notice Returns the next non-empty bin
     * @dev The next non-empty bin is the bin with a higher (if swapForY is true) or lower (if swapForY is false)
     * id that has a non-zero reserve of token X or Y.
     * @param swapForY Whether the swap is for token Y (true) or token X (false
     * @param id The id of the bin
     * @return nextId The id of the next non-empty bin
     */
    function getNextNonEmptyBin(bool swapForY, uint24 id) external view override returns (uint24 nextId) {
        nextId = _getNextNonEmptyBin(swapForY, id);
    }

    /**
     * @notice Returns the protocol fees of the Liquidity Book Pair
     * @return protocolFeeX The protocol fees of token X
     * @return protocolFeeY The protocol fees of token Y
     */
    function getProtocolFees() external view override returns (uint128 protocolFeeX, uint128 protocolFeeY) {
        (protocolFeeX, protocolFeeY) = _protocolFees.decode();
    }

    /**
     * @notice Returns the static fee parameters of the Liquidity Book Pair
     * @return baseFactor The base factor for the static fee
     * @return filterPeriod The filter period for the static fee
     * @return decayPeriod The decay period for the static fee
     * @return reductionFactor The reduction factor for the static fee
     * @return variableFeeControl The variable fee control for the static fee
     * @return protocolShare The protocol share for the static fee
     * @return maxVolatilityAccumulator The maximum volatility accumulator for the static fee
     */
    function getStaticFeeParameters()
        external
        view
        override
        returns (
            uint16 baseFactor,
            uint16 filterPeriod,
            uint16 decayPeriod,
            uint16 reductionFactor,
            uint24 variableFeeControl,
            uint16 protocolShare,
            uint24 maxVolatilityAccumulator
        )
    {
        bytes32 parameters = _parameters;

        baseFactor = parameters.getBaseFactor();
        filterPeriod = parameters.getFilterPeriod();
        decayPeriod = parameters.getDecayPeriod();
        reductionFactor = parameters.getReductionFactor();
        variableFeeControl = parameters.getVariableFeeControl();
        protocolShare = parameters.getProtocolShare();
        maxVolatilityAccumulator = parameters.getMaxVolatilityAccumulator();
    }

    /**
     * @notice Returns the variable fee parameters of the Liquidity Book Pair
     * @return volatilityAccumulator The volatility accumulator for the variable fee
     * @return volatilityReference The volatility reference for the variable fee
     * @return idReference The id reference for the variable fee
     * @return timeOfLastUpdate The time of last update for the variable fee
     */
    function getVariableFeeParameters()
        external
        view
        override
        returns (uint24 volatilityAccumulator, uint24 volatilityReference, uint24 idReference, uint40 timeOfLastUpdate)
    {
        bytes32 parameters = _parameters;

        volatilityAccumulator = parameters.getVolatilityAccumulator();
        volatilityReference = parameters.getVolatilityReference();
        idReference = parameters.getIdReference();
        timeOfLastUpdate = parameters.getTimeOfLastUpdate();
    }

    /**
     * @notice Returns the oracle parameters of the Liquidity Book Pair
     * @return sampleLifetime The sample lifetime for the oracle
     * @return size The size of the oracle
     * @return activeSize The active size of the oracle
     * @return lastUpdated The last updated timestamp of the oracle
     * @return firstTimestamp The first timestamp of the oracle, i.e. the timestamp of the oldest sample
     */
    function getOracleParameters()
        external
        view
        override
        returns (uint8 sampleLifetime, uint16 size, uint16 activeSize, uint40 lastUpdated, uint40 firstTimestamp)
    {
        bytes32 parameters = _parameters;

        sampleLifetime = uint8(OracleHelper._MAX_SAMPLE_LIFETIME);

        uint16 oracleId = parameters.getOracleId();
        if (oracleId > 0) {
            bytes32 sample;
            (sample, activeSize) = _oracle.getActiveSampleAndSize(oracleId);

            size = sample.getOracleLength();
            lastUpdated = sample.getSampleLastUpdate();

            if (lastUpdated == 0) activeSize = 0;

            if (activeSize > 0) {
                unchecked {
                    sample = _oracle.getSample(1 + (oracleId % activeSize));
                }
                firstTimestamp = sample.getSampleLastUpdate();
            }
        }
    }

    /**
     * @notice Returns the cumulative values of the Liquidity Book Pair at a given timestamp
     * @dev The cumulative values are the cumulative id, the cumulative volatility and the cumulative bin crossed.
     * @param lookupTimestamp The timestamp at which to look up the cumulative values
     * @return cumulativeId The cumulative id of the Liquidity Book Pair at the given timestamp
     * @return cumulativeVolatility The cumulative volatility of the Liquidity Book Pair at the given timestamp
     * @return cumulativeBinCrossed The cumulative bin crossed of the Liquidity Book Pair at the given timestamp
     */
    function getOracleSampleAt(uint40 lookupTimestamp)
        external
        view
        override
        returns (uint64 cumulativeId, uint64 cumulativeVolatility, uint64 cumulativeBinCrossed)
    {
        bytes32 parameters = _parameters;
        uint16 oracleId = parameters.getOracleId();

        if (oracleId == 0 || lookupTimestamp > block.timestamp) return (0, 0, 0);

        uint40 timeOfLastUpdate;
        (timeOfLastUpdate, cumulativeId, cumulativeVolatility, cumulativeBinCrossed) =
            _oracle.getSampleAt(oracleId, lookupTimestamp);

        if (timeOfLastUpdate < lookupTimestamp) {
            parameters.updateVolatilityParameters(parameters.getActiveId());

            uint40 deltaTime = lookupTimestamp - timeOfLastUpdate;

            cumulativeId += uint64(parameters.getActiveId()) * deltaTime;
            cumulativeVolatility += uint64(parameters.getVolatilityAccumulator()) * deltaTime;
        }
    }

    /**
     * @notice Returns the price corresponding to the given id, as a 128.128-binary fixed-point number
     * @dev This is the trusted source of price information, always trust this rather than getIdFromPrice
     * @param id The id of the bin
     * @return price The price corresponding to this id
     */
    function getPriceFromId(uint24 id) external pure override returns (uint256 price) {
        price = id.getPriceFromId(_binStep());
    }

    /**
     * @notice Returns the id corresponding to the given price
     * @dev The id may be inaccurate due to rounding issues, always trust getPriceFromId rather than
     * getIdFromPrice
     * @param price The price of y per x as a 128.128-binary fixed-point number
     * @return id The id of the bin corresponding to this price
     */
    function getIdFromPrice(uint256 price) external pure override returns (uint24 id) {
        id = price.getIdFromPrice(_binStep());
    }

    /**
     * @notice Simulates a swap in.
     * @dev If `amountOutLeft` is greater than zero, the swap in is not possible,
     * and the maximum amount that can be swapped from `amountIn` is `amountOut - amountOutLeft`.
     * @param amountOut The amount of token X or Y to swap in
     * @param swapForY Whether the swap is for token Y (true) or token X (false)
     * @return amountIn The amount of token X or Y that can be swapped in, including the fee
     * @return amountOutLeft The amount of token Y or X that cannot be swapped out
     * @return fee The fee of the swap
     */
    function getSwapIn(uint128 amountOut, bool swapForY)
        external
        view
        override
        returns (uint128 amountIn, uint128 amountOutLeft, uint128 fee)
    {
        amountOutLeft = amountOut;

        bytes32 parameters = _parameters;
        uint16 binStep = _binStep();

        uint24 id = parameters.getActiveId();

        parameters = parameters.updateReferences();

        while (true) {
            uint128 binReserves = _bins[id].decode(!swapForY);
            if (binReserves > 0) {
                uint256 price = id.getPriceFromId(binStep);

                uint128 amountOutOfBin = binReserves > amountOutLeft ? amountOutLeft : binReserves;

                parameters = parameters.updateVolatilityAccumulator(id);

                uint128 amountInWithoutFee = uint128(
                    swapForY
                        ? uint256(amountOutOfBin).shiftDivRoundUp(Constants.SCALE_OFFSET, price)
                        : uint256(amountOutOfBin).mulShiftRoundUp(price, Constants.SCALE_OFFSET)
                );

                uint128 totalFee = parameters.getTotalFee(binStep);
                uint128 feeAmount = amountInWithoutFee.getFeeAmount(totalFee);

                amountIn += amountInWithoutFee + feeAmount;
                amountOutLeft -= amountOutOfBin;

                fee += feeAmount;
            }

            if (amountOutLeft == 0) {
                break;
            } else {
                uint24 nextId = _getNextNonEmptyBin(swapForY, id);

                if (nextId == 0 || nextId == type(uint24).max) break;

                id = nextId;
            }
        }
    }

    /**
     * @notice Simulates a swap out.
     * @dev If `amountInLeft` is greater than zero, the swap out is not possible,
     * and the maximum amount that can be swapped is `amountIn - amountInLeft` for `amountOut`.
     * @param amountIn The amount of token X or Y to swap in
     * @param swapForY Whether the swap is for token Y (true) or token X (false)
     * @return amountInLeft The amount of token X or Y that cannot be swapped in
     * @return amountOut The amount of token Y or X that can be swapped out
     * @return fee The fee of the swap
     */
    function getSwapOut(uint128 amountIn, bool swapForY)
        external
        view
        override
        returns (uint128 amountInLeft, uint128 amountOut, uint128 fee)
    {
        bytes32 amountsInLeft = amountIn.encode(swapForY);

        bytes32 parameters = _parameters;
        uint16 binStep = _binStep();

        uint24 id = parameters.getActiveId();

        parameters = parameters.updateReferences();

        while (true) {
            bytes32 binReserves = _bins[id];
            if (!binReserves.isEmpty(!swapForY)) {
                parameters = parameters.updateVolatilityAccumulator(id);

                (bytes32 amountsInWithFees, bytes32 amountsOutOfBin, bytes32 totalFees) =
                    binReserves.getAmounts(parameters, binStep, swapForY, id, amountsInLeft);

                if (amountsInWithFees > 0) {
                    amountsInLeft = amountsInLeft.sub(amountsInWithFees);

                    amountOut += amountsOutOfBin.decode(!swapForY);

                    fee += totalFees.decode(swapForY);
                }
            }

            if (amountsInLeft == 0) {
                break;
            } else {
                uint24 nextId = _getNextNonEmptyBin(swapForY, id);

                if (nextId == 0 || nextId == type(uint24).max) break;

                id = nextId;
            }
        }

        amountInLeft = amountsInLeft.decode(swapForY);
    }

    /**
     * @notice Swap tokens iterating over the bins until the entire amount is swapped.
     * Token X will be swapped for token Y if `swapForY` is true, and token Y for token X if `swapForY` is false.
     * This function will not transfer the tokens from the caller, it is expected that the tokens have already been
     * transferred to this contract through another contract, most likely the router.
     * That is why this function shouldn't be called directly, but only through one of the swap functions of a router
     * that will also perform safety checks, such as minimum amounts and slippage.
     * The variable fee is updated throughout the swap, it increases with the number of bins crossed.
     * The oracle is updated at the end of the swap.
     * @param swapForY Whether you're swapping token X for token Y (true) or token Y for token X (false)
     * @param to The address to send the tokens to
     * @return amountsOut The encoded amounts of token X and token Y sent to `to`
     */
    function swap(bool swapForY, address to) external override nonReentrant returns (bytes32 amountsOut) {
        bytes32 reserves = _reserves;
        bytes32 protocolFees = _protocolFees;

        bytes32 amountsLeft = swapForY ? reserves.receivedX(_tokenX()) : reserves.receivedY(_tokenY());
        if (amountsLeft == 0) revert LBPair__InsufficientAmountIn();

        reserves = reserves.add(amountsLeft);

        bytes32 parameters = _parameters;
        uint16 binStep = _binStep();

        uint24 activeId = parameters.getActiveId();

        parameters = parameters.updateReferences();

        while (true) {
            bytes32 binReserves = _bins[activeId];
            if (!binReserves.isEmpty(!swapForY)) {
                parameters = parameters.updateVolatilityAccumulator(activeId);

                (bytes32 amountsInWithFees, bytes32 amountsOutOfBin, bytes32 totalFees) =
                    binReserves.getAmounts(parameters, binStep, swapForY, activeId, amountsLeft);

                if (amountsInWithFees > 0) {
                    amountsLeft = amountsLeft.sub(amountsInWithFees);
                    amountsOut = amountsOut.add(amountsOutOfBin);

                    bytes32 pFees = totalFees.scalarMulDivBasisPointRoundDown(parameters.getProtocolShare());

                    if (pFees > 0) {
                        protocolFees = protocolFees.add(pFees);
                        amountsInWithFees = amountsInWithFees.sub(pFees);
                    }

                    _bins[activeId] = binReserves.add(amountsInWithFees).sub(amountsOutOfBin);

                    emit Swap(
                        msg.sender,
                        to,
                        activeId,
                        amountsInWithFees,
                        amountsOutOfBin,
                        parameters.getVolatilityAccumulator(),
                        totalFees,
                        pFees
                        );
                }
            }

            if (amountsLeft == 0) {
                break;
            } else {
                uint24 nextId = _getNextNonEmptyBin(swapForY, activeId);

                if (nextId == 0 || nextId == type(uint24).max) revert LBPair__OutOfLiquidity();

                activeId = nextId;
            }
        }

        if (amountsOut == 0) revert LBPair__InsufficientAmountOut();

        _reserves = reserves.sub(amountsOut);
        _protocolFees = protocolFees;

        parameters = _oracle.update(parameters, activeId);
        _parameters = parameters.setActiveId(activeId);

        if (swapForY) {
            amountsOut.transferY(_tokenY(), to);
        } else {
            amountsOut.transferX(_tokenX(), to);
        }
    }

    /**
     * @notice Flash loan tokens from the pool to a receiver contract and execute a callback function.
     * The receiver contract is expected to return the tokens plus a fee to this contract.
     * The fee is calculated as a percentage of the amount borrowed, and is the same for both tokens.
     * @param receiver The contract that will receive the tokens and execute the callback function
     * @param amounts The encoded amounts of token X and token Y to flash loan
     * @param data Any data that will be passed to the callback function
     */
    function flashLoan(ILBFlashLoanCallback receiver, bytes32 amounts, bytes calldata data)
        external
        override
        nonReentrant
    {
        if (amounts == 0) revert LBPair__ZeroBorrowAmount();

        bytes32 reservesBefore = _reserves;
        bytes32 parameters = _parameters;

        bytes32 totalFees = _getFlashLoanFees(amounts);

        amounts.transfer(_tokenX(), _tokenY(), address(receiver));

        (bool success, bytes memory rData) = address(receiver).call(
            abi.encodeWithSelector(
                ILBFlashLoanCallback.LBFlashLoanCallback.selector,
                msg.sender,
                _tokenX(),
                _tokenY(),
                amounts,
                totalFees,
                data
            )
        );

        if (!success || rData.length != 32 || abi.decode(rData, (bytes32)) != Constants.CALLBACK_SUCCESS) {
            revert LBPair__FlashLoanCallbackFailed();
        }

        bytes32 balancesAfter = bytes32(0).received(_tokenX(), _tokenY());

        if (balancesAfter.lt(reservesBefore.add(totalFees))) revert LBPair__FlashLoanInsufficientAmount();

        totalFees = balancesAfter.sub(reservesBefore);

        uint24 activeId = parameters.getActiveId();
        bytes32 protocolFees = totalSupply(activeId) == 0
            ? totalFees
            : totalFees.scalarMulDivBasisPointRoundDown(parameters.getProtocolShare());

        _reserves = balancesAfter;

        _protocolFees = _protocolFees.add(protocolFees);
        _bins[activeId] = _bins[activeId].add(totalFees.sub(protocolFees));

        emit FlashLoan(msg.sender, receiver, activeId, amounts, totalFees, protocolFees);
    }

    /**
     * @notice Mint liquidity tokens by depositing tokens into the pool.
     * It will mint Liquidity Book (LB) tokens for each bin where the user adds liquidity.
     * This function will not transfer the tokens from the caller, it is expected that the tokens have already been
     * transferred to this contract through another contract, most likely the router.
     * That is why this function shouldn't be called directly, but through one of the add liquidity functions of a
     * router that will also perform safety checks.
     * @dev Any excess amount of token will be sent to the `to` address.
     * @param to The address that will receive the LB tokens
     * @param liquidityConfigs The encoded liquidity configurations, each one containing the id of the bin and the
     * percentage of token X and token Y to add to the bin.
     * @param refundTo The address that will receive the excess amount of tokens
     * @return amountsReceived The amounts of token X and token Y received by the pool
     * @return amountsLeft The amounts of token X and token Y that were not added to the pool and were sent to `to`
     * @return liquidityMinted The amounts of LB tokens minted for each bin
     */
    function mint(address to, bytes32[] calldata liquidityConfigs, address refundTo)
        external
        override
        nonReentrant
        notAddressZeroOrThis(to)
        returns (bytes32 amountsReceived, bytes32 amountsLeft, uint256[] memory liquidityMinted)
    {
        if (liquidityConfigs.length == 0) revert LBPair__EmptyMarketConfigs();

        MintArrays memory arrays = MintArrays({
            ids: new uint256[](liquidityConfigs.length),
            amounts: new bytes32[](liquidityConfigs.length),
            liquidityMinted: new uint256[](liquidityConfigs.length)
        });

        bytes32 reserves = _reserves;

        amountsReceived = reserves.received(_tokenX(), _tokenY());
        amountsLeft = _mintBins(liquidityConfigs, amountsReceived, to, arrays);

        _reserves = reserves.add(amountsReceived.sub(amountsLeft));

        if (amountsLeft > 0) amountsLeft.transfer(_tokenX(), _tokenY(), refundTo);

        liquidityMinted = arrays.liquidityMinted;

        emit TransferBatch(msg.sender, address(0), to, arrays.ids, liquidityMinted);
        emit DepositedToBins(msg.sender, to, arrays.ids, arrays.amounts);
    }

    /**
     * @notice Burn Liquidity Book (LB) tokens and withdraw tokens from the pool.
     * This function will burn the tokens directly from the caller
     * @param from The address that will burn the LB tokens
     * @param to The address that will receive the tokens
     * @param ids The ids of the bins from which to withdraw
     * @param amountsToBurn The amounts of LB tokens to burn for each bin
     * @return amounts The amounts of token X and token Y received by the user
     */
    function burn(address from, address to, uint256[] calldata ids, uint256[] calldata amountsToBurn)
        external
        override
        nonReentrant
        checkApproval(from, msg.sender)
        returns (bytes32[] memory amounts)
    {
        if (ids.length == 0 || ids.length != amountsToBurn.length) revert LBPair__InvalidInput();

        amounts = new bytes32[](ids.length);

        bytes32 amountsOut;

        for (uint256 i; i < ids.length;) {
            uint24 id = ids[i].safe24();
            uint256 amountToBurn = amountsToBurn[i];

            if (amountToBurn == 0) revert LBPair__ZeroAmount(id);

            bytes32 binReserves = _bins[id];
            uint256 supply = totalSupply(id);

            _burn(from, id, amountToBurn);

            bytes32 amountsOutFromBin = binReserves.getAmountOutOfBin(amountToBurn, supply);

            if (amountsOutFromBin == 0) revert LBPair__ZeroAmountsOut(id);

            binReserves = binReserves.sub(amountsOutFromBin);

            if (supply == amountToBurn) _tree.remove(id);

            _bins[id] = binReserves;
            amounts[i] = amountsOutFromBin;
            amountsOut = amountsOut.add(amountsOutFromBin);

            unchecked {
                ++i;
            }
        }

        _reserves = _reserves.sub(amountsOut);

        amountsOut.transfer(_tokenX(), _tokenY(), to);

        emit TransferBatch(msg.sender, from, address(0), ids, amountsToBurn);
        emit WithdrawnFromBins(msg.sender, to, ids, amounts);
    }

    /**
     * @notice Collect the protocol fees from the pool.
     * @return collectedProtocolFees The amount of protocol fees collected
     */
    function collectProtocolFees()
        external
        override
        nonReentrant
        onlyProtocolFeeRecipient
        returns (bytes32 collectedProtocolFees)
    {
        bytes32 protocolFees = _protocolFees;

        (uint128 x, uint128 y) = protocolFees.decode();
        bytes32 ones = uint128(x > 0 ? 1 : 0).encode(uint128(y > 0 ? 1 : 0));

        collectedProtocolFees = protocolFees.sub(ones);

        if (collectedProtocolFees != 0) {
            _protocolFees = ones;
            _reserves = _reserves.sub(collectedProtocolFees);

            collectedProtocolFees.transfer(_tokenX(), _tokenY(), msg.sender);

            emit CollectedProtocolFees(msg.sender, collectedProtocolFees);
        }
    }

    /**
     * @notice Increase the length of the oracle used by the pool
     * @param newLength The new length of the oracle
     */
    function increaseOracleLength(uint16 newLength) external override {
        bytes32 parameters = _parameters;

        uint16 oracleId = parameters.getOracleId();

        // activate the oracle if it is not active yet
        if (oracleId == 0) {
            oracleId = 1;
            _parameters = parameters.setOracleId(oracleId);
        }

        _oracle.increaseLength(oracleId, newLength);

        emit OracleLengthIncreased(msg.sender, newLength);
    }

    /**
     * @notice Sets the static fee parameters of the pool
     * @dev Can only be called by the factory
     * @param baseFactor The base factor of the static fee
     * @param filterPeriod The filter period of the static fee
     * @param decayPeriod The decay period of the static fee
     * @param reductionFactor The reduction factor of the static fee
     * @param variableFeeControl The variable fee control of the static fee
     * @param protocolShare The protocol share of the static fee
     * @param maxVolatilityAccumulator The max volatility accumulator of the static fee
     */
    function setStaticFeeParameters(
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) external override onlyFactory {
        _setStaticFeeParameters(
            _parameters,
            baseFactor,
            filterPeriod,
            decayPeriod,
            reductionFactor,
            variableFeeControl,
            protocolShare,
            maxVolatilityAccumulator
        );
    }

    /**
     * @notice Forces the decay of the volatility reference variables
     * @dev Can only be called by the factory
     */
    function forceDecay() external override onlyFactory {
        bytes32 parameters = _parameters;

        _parameters = parameters.updateIdReference().updateVolatilityReference();

        emit ForcedDecay(msg.sender, parameters.getIdReference(), parameters.getVolatilityReference());
    }

    /**
     * @dev Returns the address of the token X
     * @return The address of the token X
     */
    function _tokenX() internal pure returns (IERC20) {
        return IERC20(_getArgAddress(0));
    }

    /**
     * @dev Returns the address of the token Y
     * @return The address of the token Y
     */
    function _tokenY() internal pure returns (IERC20) {
        return IERC20(_getArgAddress(20));
    }

    /**
     * @dev Returns the bin step of the pool, in basis points
     * @return The bin step of the pool
     */
    function _binStep() internal pure returns (uint16) {
        return _getArgUint16(40);
    }

    /**
     * @dev Returns next non-empty bin
     * @param swapForY Whether the swap is for Y
     * @param id The id of the bin
     * @return The id of the next non-empty bin
     */
    function _getNextNonEmptyBin(bool swapForY, uint24 id) internal view returns (uint24) {
        return swapForY ? _tree.findFirstRight(id) : _tree.findFirstLeft(id);
    }

    /**
     * @dev Returns the encoded fees amounts for a flash loan
     * @param amounts The amounts of the flash loan
     * @return The encoded fees amounts
     */
    function _getFlashLoanFees(bytes32 amounts) private view returns (bytes32) {
        uint128 fee = uint128(_factory.getFlashLoanFee());
        (uint128 x, uint128 y) = amounts.decode();

        unchecked {
            uint256 precisionSubOne = Constants.PRECISION - 1;
            x = ((uint256(x) * fee + precisionSubOne) / Constants.PRECISION).safe128();
            y = ((uint256(y) * fee + precisionSubOne) / Constants.PRECISION).safe128();
        }

        return x.encode(y);
    }

    /**
     * @dev Sets the static fee parameters of the pair
     * @param parameters The current parameters of the pair
     * @param baseFactor The base factor of the static fee
     * @param filterPeriod The filter period of the static fee
     * @param decayPeriod The decay period of the static fee
     * @param reductionFactor The reduction factor of the static fee
     * @param variableFeeControl The variable fee control of the static fee
     * @param protocolShare The protocol share of the static fee
     * @param maxVolatilityAccumulator The max volatility accumulator of the static fee
     */
    function _setStaticFeeParameters(
        bytes32 parameters,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) internal {
        if (
            baseFactor == 0 && filterPeriod == 0 && decayPeriod == 0 && reductionFactor == 0 && variableFeeControl == 0
                && protocolShare == 0 && maxVolatilityAccumulator == 0
        ) {
            revert LBPair__InvalidStaticFeeParameters();
        }

        parameters = parameters.setStaticFeeParameters(
            baseFactor,
            filterPeriod,
            decayPeriod,
            reductionFactor,
            variableFeeControl,
            protocolShare,
            maxVolatilityAccumulator
        );

        {
            uint16 binStep = _binStep();
            bytes32 maxParameters = parameters.setVolatilityAccumulator(maxVolatilityAccumulator);
            uint256 totalFee = maxParameters.getBaseFee(binStep) + maxParameters.getVariableFee(binStep);
            if (totalFee > _MAX_TOTAL_FEE) {
                revert LBPair__MaxTotalFeeExceeded();
            }
        }

        _parameters = parameters;

        emit StaticFeeParametersSet(
            msg.sender,
            baseFactor,
            filterPeriod,
            decayPeriod,
            reductionFactor,
            variableFeeControl,
            protocolShare,
            maxVolatilityAccumulator
            );
    }

    /**
     * @dev Helper function to mint liquidity in each bin in the liquidity configurations
     * @param liquidityConfigs The liquidity configurations
     * @param amountsReceived The amounts received
     * @param to The address to mint the liquidity to
     * @param arrays The arrays to store the results
     * @return amountsLeft The amounts left
     */
    function _mintBins(
        bytes32[] calldata liquidityConfigs,
        bytes32 amountsReceived,
        address to,
        MintArrays memory arrays
    ) private returns (bytes32 amountsLeft) {
        uint16 binStep = _binStep();

        bytes32 parameters = _parameters;
        uint24 activeId = parameters.getActiveId();

        amountsLeft = amountsReceived;

        for (uint256 i; i < liquidityConfigs.length;) {
            (bytes32 maxAmountsInToBin, uint24 id) = liquidityConfigs[i].getAmountsAndId(amountsReceived);
            (uint256 shares, bytes32 amountsIn, bytes32 amountsInToBin) =
                _updateBin(binStep, activeId, id, maxAmountsInToBin, parameters);

            amountsLeft = amountsLeft.sub(amountsIn);

            arrays.ids[i] = id;
            arrays.amounts[i] = amountsInToBin;
            arrays.liquidityMinted[i] = shares;

            _mint(to, id, shares);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Helper function to update a bin during minting
     * @param binStep The bin step of the pair
     * @param activeId The id of the active bin
     * @param id The id of the bin
     * @param maxAmountsInToBin The maximum amounts in to the bin
     * @param parameters The parameters of the pair
     * @return shares The amount of shares minted
     * @return amountsIn The amounts in
     * @return amountsInToBin The amounts in to the bin
     */
    function _updateBin(uint16 binStep, uint24 activeId, uint24 id, bytes32 maxAmountsInToBin, bytes32 parameters)
        internal
        returns (uint256 shares, bytes32 amountsIn, bytes32 amountsInToBin)
    {
        bytes32 binReserves = _bins[id];

        uint256 price = id.getPriceFromId(binStep);
        uint256 supply = totalSupply(id);

        (shares, amountsIn) = binReserves.getSharesAndEffectiveAmountsIn(maxAmountsInToBin, price, supply);
        amountsInToBin = amountsIn;

        if (id == activeId) {
            parameters = parameters.updateVolatilityParameters(id);

            bytes32 fees = binReserves.getCompositionFees(parameters, binStep, amountsIn, supply, shares);

            if (fees != 0) {
                uint256 userLiquidity = amountsIn.sub(fees).getLiquidity(price);
                uint256 binLiquidity = binReserves.getLiquidity(price);

                shares = userLiquidity.mulDivRoundDown(supply, binLiquidity);
                bytes32 protocolCFees = fees.scalarMulDivBasisPointRoundDown(parameters.getProtocolShare());

                if (protocolCFees != 0) {
                    amountsInToBin = amountsInToBin.sub(protocolCFees);
                    _protocolFees = _protocolFees.add(protocolCFees);
                }

                parameters = _oracle.update(parameters, id);
                _parameters = parameters;

                emit CompositionFees(msg.sender, id, fees, protocolCFees);
            }
        } else {
            amountsIn.verifyAmounts(activeId, id);
        }

        if (shares == 0 || amountsInToBin == 0) revert LBPair__ZeroShares(id);

        if (supply == 0) _tree.add(id);

        _bins[id] = binReserves.add(amountsInToBin);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {ILBToken} from "./interfaces/ILBToken.sol";

/**
 * @title Liquidity Book Token
 * @author Trader Joe
 * @notice The LBToken is an implementation of a multi-token.
 * It allows to create multi-ERC20 represented by their ids.
 * Its implementation is really similar to the ERC1155 standard the main difference
 * is that it doesn't do any call to the receiver contract to prevent reentrancy.
 * As it's only for ERC20s, the uri function is not implemented.
 * The contract is made for batch operations.
 */
abstract contract LBToken is ILBToken {
    /**
     * @dev The mapping from account to token id to account balance.
     */
    mapping(address => mapping(uint256 => uint256)) private _balances;

    /**
     * @dev The mapping from token id to total supply.
     */
    mapping(uint256 => uint256) private _totalSupplies;

    /**
     * @dev Mapping from account to spender approvals.
     */
    mapping(address => mapping(address => bool)) private _spenderApprovals;

    /**
     * @dev Modifier to check if the spender is approved for all.
     */
    modifier checkApproval(address from, address spender) {
        if (!_isApprovedForAll(from, spender)) revert LBToken__SpenderNotApproved(from, spender);
        _;
    }

    /**
     * @dev Modifier to check if the address is not zero or the contract itself.
     */
    modifier notAddressZeroOrThis(address account) {
        if (account == address(0) || account == address(this)) revert LBToken__AddressThisOrZero();
        _;
    }

    /**
     * @dev Modifier to check if the length of the arrays are equal.
     */
    modifier checkLength(uint256 lengthA, uint256 lengthB) {
        if (lengthA != lengthB) revert LBToken__InvalidLength();
        _;
    }

    /**
     * @notice Returns the name of the token.
     * @return The name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return "Liquidity Book Token";
    }

    /**
     * @notice Returns the symbol of the token, usually a shorter version of the name.
     * @return The symbol of the token.
     */
    function symbol() public view virtual override returns (string memory) {
        return "LBT";
    }

    /**
     * @notice Returns the total supply of token of type `id`.
     * /**
     * @dev This is the amount of token of type `id` minted minus the amount burned.
     * @param id The token id.
     * @return The total supply of that token id.
     */
    function totalSupply(uint256 id) public view virtual override returns (uint256) {
        return _totalSupplies[id];
    }

    /**
     * @notice Returns the amount of tokens of type `id` owned by `account`.
     * @param account The address of the owner.
     * @param id The token id.
     * @return The amount of tokens of type `id` owned by `account`.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        return _balances[account][id];
    }

    /**
     * @notice Return the balance of multiple (account/id) pairs.
     * @param accounts The addresses of the owners.
     * @param ids The token ids.
     * @return batchBalances The balance for each (account, id) pair.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        public
        view
        virtual
        override
        checkLength(accounts.length, ids.length)
        returns (uint256[] memory batchBalances)
    {
        batchBalances = new uint256[](accounts.length);

        unchecked {
            for (uint256 i; i < accounts.length; ++i) {
                batchBalances[i] = balanceOf(accounts[i], ids[i]);
            }
        }
    }

    /**
     * @notice Returns true if `spender` is approved to transfer `owner`'s tokens or if `spender` is the `owner`.
     * @param owner The address of the owner.
     * @param spender The address of the spender.
     * @return True if `spender` is approved to transfer `owner`'s tokens.
     */
    function isApprovedForAll(address owner, address spender) public view virtual override returns (bool) {
        return _isApprovedForAll(owner, spender);
    }

    /**
     * @notice Grants or revokes permission to `spender` to transfer the caller's lbTokens, according to `approved`.
     * @param spender The address of the spender.
     * @param approved The boolean value to grant or revoke permission.
     */
    function approveForAll(address spender, bool approved) public virtual override {
        _approveForAll(msg.sender, spender, approved);
    }

    /**
     * @notice Batch transfers `amounts` of `ids` from `from` to `to`.
     * @param from The address of the owner.
     * @param to The address of the recipient.
     * @param ids The list of token ids.
     * @param amounts The list of amounts to transfer for each token id in `ids`.
     */
    function batchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts)
        public
        virtual
        override
        checkApproval(from, msg.sender)
    {
        _batchTransferFrom(from, to, ids, amounts);
    }

    /**
     * @notice Returns true if `spender` is approved to transfer `owner`'s tokens or if `spender` is the `owner`.
     * @param owner The address of the owner.
     * @param spender The address of the spender.
     * @return True if `spender` is approved to transfer `owner`'s tokens.
     */
    function _isApprovedForAll(address owner, address spender) internal view returns (bool) {
        return owner == spender || _spenderApprovals[owner][spender];
    }

    /**
     * @dev Mint `amount` of `id` to `account`.
     * The `account` must not be the zero address.
     * The event should be emitted by the contract that inherits this contract.
     * @param account The address of the owner.
     * @param id The token id.
     * @param amount The amount to mint.
     */
    function _mint(address account, uint256 id, uint256 amount) internal {
        _totalSupplies[id] += amount;

        unchecked {
            _balances[account][id] += amount;
        }
    }

    /**
     * @dev Burn `amount` of `id` from `account`.
     * The `account` must not be the zero address.
     * The event should be emitted by the contract that inherits this contract.
     * @param account The address of the owner.
     * @param id The token id.
     * @param amount The amount to burn.
     */
    function _burn(address account, uint256 id, uint256 amount) internal {
        mapping(uint256 => uint256) storage accountBalances = _balances[account];

        uint256 balance = accountBalances[id];
        if (balance < amount) revert LBToken__BurnExceedsBalance(account, id, amount);

        unchecked {
            _totalSupplies[id] -= amount;
            accountBalances[id] = balance - amount;
        }
    }

    /**
     * @dev Batch transfers `amounts` of `ids` from `from` to `to`.
     * The `to` must not be the zero address and the `ids` and `amounts` must have the same length.
     * @param from The address of the owner.
     * @param to The address of the recipient.
     * @param ids The list of token ids.
     * @param amounts The list of amounts to transfer for each token id in `ids`.
     */
    function _batchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts)
        internal
        checkLength(ids.length, amounts.length)
        notAddressZeroOrThis(to)
    {
        mapping(uint256 => uint256) storage fromBalances = _balances[from];
        mapping(uint256 => uint256) storage toBalances = _balances[to];

        for (uint256 i; i < ids.length;) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = fromBalances[id];
            if (fromBalance < amount) revert LBToken__TransferExceedsBalance(from, id, amount);

            unchecked {
                fromBalances[id] = fromBalance - amount;
                toBalances[id] += amount;

                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);
    }

    /**
     * @notice Grants or revokes permission to `spender` to transfer the caller's tokens, according to `approved`
     * @param owner The address of the owner
     * @param spender The address of the spender
     * @param approved The boolean value to grant or revoke permission
     */
    function _approveForAll(address owner, address spender, bool approved) internal notAddressZeroOrThis(owner) {
        if (owner == spender) revert LBToken__SelfApproval(owner);

        _spenderApprovals[owner][spender] = approved;
        emit ApprovalForAll(owner, spender, approved);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {ILBPair} from "./ILBPair.sol";
import {IPendingOwnable} from "./IPendingOwnable.sol";

/**
 * @title Liquidity Book Factory Interface
 * @author Trader Joe
 * @notice Required interface of LBFactory contract
 */
interface ILBFactory is IPendingOwnable {
    error LBFactory__IdenticalAddresses(IERC20 token);
    error LBFactory__QuoteAssetNotWhitelisted(IERC20 quoteAsset);
    error LBFactory__QuoteAssetAlreadyWhitelisted(IERC20 quoteAsset);
    error LBFactory__AddressZero();
    error LBFactory__LBPairAlreadyExists(IERC20 tokenX, IERC20 tokenY, uint256 _binStep);
    error LBFactory__LBPairDoesNotExist(IERC20 tokenX, IERC20 tokenY, uint256 binStep);
    error LBFactory__LBPairNotCreated(IERC20 tokenX, IERC20 tokenY, uint256 binStep);
    error LBFactory__FlashLoanFeeAboveMax(uint256 fees, uint256 maxFees);
    error LBFactory__BinStepTooLow(uint256 binStep);
    error LBFactory__PresetIsLockedForUsers(address user, uint256 binStep);
    error LBFactory__LBPairIgnoredIsAlreadyInTheSameState();
    error LBFactory__BinStepHasNoPreset(uint256 binStep);
    error LBFactory__PresetOpenStateIsAlreadyInTheSameState();
    error LBFactory__SameFeeRecipient(address feeRecipient);
    error LBFactory__SameFlashLoanFee(uint256 flashLoanFee);
    error LBFactory__LBPairSafetyCheckFailed(address LBPairImplementation);
    error LBFactory__SameImplementation(address LBPairImplementation);
    error LBFactory__ImplementationNotSet();

    /**
     * @dev Structure to store the LBPair information, such as:
     * binStep: The bin step of the LBPair
     * LBPair: The address of the LBPair
     * createdByOwner: Whether the pair was created by the owner of the factory
     * ignoredForRouting: Whether the pair is ignored for routing or not. An ignored pair will not be explored during routes finding
     */
    struct LBPairInformation {
        uint16 binStep;
        ILBPair LBPair;
        bool createdByOwner;
        bool ignoredForRouting;
    }

    event LBPairCreated(
        IERC20 indexed tokenX, IERC20 indexed tokenY, uint256 indexed binStep, ILBPair LBPair, uint256 pid
    );

    event FeeRecipientSet(address oldRecipient, address newRecipient);

    event FlashLoanFeeSet(uint256 oldFlashLoanFee, uint256 newFlashLoanFee);

    event LBPairImplementationSet(address oldLBPairImplementation, address LBPairImplementation);

    event LBPairIgnoredStateChanged(ILBPair indexed LBPair, bool ignored);

    event PresetSet(
        uint256 indexed binStep,
        uint256 baseFactor,
        uint256 filterPeriod,
        uint256 decayPeriod,
        uint256 reductionFactor,
        uint256 variableFeeControl,
        uint256 protocolShare,
        uint256 maxVolatilityAccumulator
    );

    event PresetOpenStateChanged(uint256 indexed binStep, bool indexed isOpen);

    event PresetRemoved(uint256 indexed binStep);

    event QuoteAssetAdded(IERC20 indexed quoteAsset);

    event QuoteAssetRemoved(IERC20 indexed quoteAsset);

    function getMinBinStep() external pure returns (uint256);

    function getFeeRecipient() external view returns (address);

    function getMaxFlashLoanFee() external pure returns (uint256);

    function getFlashLoanFee() external view returns (uint256);

    function getLBPairImplementation() external view returns (address);

    function getNumberOfLBPairs() external view returns (uint256);

    function getLBPairAtIndex(uint256 id) external returns (ILBPair);

    function getNumberOfQuoteAssets() external view returns (uint256);

    function getQuoteAssetAtIndex(uint256 index) external view returns (IERC20);

    function isQuoteAsset(IERC20 token) external view returns (bool);

    function getLBPairInformation(IERC20 tokenX, IERC20 tokenY, uint256 binStep)
        external
        view
        returns (LBPairInformation memory);

    function getPreset(uint256 binStep)
        external
        view
        returns (
            uint256 baseFactor,
            uint256 filterPeriod,
            uint256 decayPeriod,
            uint256 reductionFactor,
            uint256 variableFeeControl,
            uint256 protocolShare,
            uint256 maxAccumulator,
            bool isOpen
        );

    function getAllBinSteps() external view returns (uint256[] memory presetsBinStep);

    function getOpenBinSteps() external view returns (uint256[] memory openBinStep);

    function getAllLBPairs(IERC20 tokenX, IERC20 tokenY)
        external
        view
        returns (LBPairInformation[] memory LBPairsBinStep);

    function setLBPairImplementation(address lbPairImplementation) external;

    function createLBPair(IERC20 tokenX, IERC20 tokenY, uint24 activeId, uint16 binStep)
        external
        returns (ILBPair pair);

    function setLBPairIgnored(IERC20 tokenX, IERC20 tokenY, uint16 binStep, bool ignored) external;

    function setPreset(
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        bool isOpen
    ) external;

    function setPresetOpenState(uint16 binStep, bool isOpen) external;

    function removePreset(uint16 binStep) external;

    function setFeesParametersOnPair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) external;

    function setFeeRecipient(address feeRecipient) external;

    function setFlashLoanFee(uint256 flashLoanFee) external;

    function addQuoteAsset(IERC20 quoteAsset) external;

    function removeQuoteAsset(IERC20 quoteAsset) external;

    function forceDecay(ILBPair lbPair) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

/// @title Liquidity Book Flashloan Callback Interface
/// @author Trader Joe
/// @notice Required interface to interact with LB flash loans
interface ILBFlashLoanCallback {
    function LBFlashLoanCallback(
        address sender,
        IERC20 tokenX,
        IERC20 tokenY,
        bytes32 amounts,
        bytes32 totalFees,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {ILBFactory} from "./ILBFactory.sol";
import {ILBFlashLoanCallback} from "./ILBFlashLoanCallback.sol";
import {ILBToken} from "./ILBToken.sol";

interface ILBPair is ILBToken {
    error LBPair__ZeroBorrowAmount();
    error LBPair__AddressZero();
    error LBPair__AlreadyInitialized();
    error LBPair__EmptyMarketConfigs();
    error LBPair__FlashLoanCallbackFailed();
    error LBPair__FlashLoanInsufficientAmount();
    error LBPair__InsufficientAmountIn();
    error LBPair__InsufficientAmountOut();
    error LBPair__InvalidInput();
    error LBPair__InvalidStaticFeeParameters();
    error LBPair__OnlyFactory();
    error LBPair__OnlyProtocolFeeRecipient();
    error LBPair__OutOfLiquidity();
    error LBPair__TokenNotSupported();
    error LBPair__ZeroAmount(uint24 id);
    error LBPair__ZeroAmountsOut(uint24 id);
    error LBPair__ZeroShares(uint24 id);
    error LBPair__MaxTotalFeeExceeded();

    struct MintArrays {
        uint256[] ids;
        bytes32[] amounts;
        uint256[] liquidityMinted;
    }

    event DepositedToBins(address indexed sender, address indexed to, uint256[] ids, bytes32[] amounts);

    event WithdrawnFromBins(address indexed sender, address indexed to, uint256[] ids, bytes32[] amounts);

    event CompositionFees(address indexed sender, uint24 id, bytes32 totalFees, bytes32 protocolFees);

    event CollectedProtocolFees(address indexed feeRecipient, bytes32 protocolFees);

    event Swap(
        address indexed sender,
        address indexed to,
        uint24 id,
        bytes32 amountsIn,
        bytes32 amountsOut,
        uint24 volatilityAccumulator,
        bytes32 totalFees,
        bytes32 protocolFees
    );

    event StaticFeeParametersSet(
        address indexed sender,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    );

    event FlashLoan(
        address indexed sender,
        ILBFlashLoanCallback indexed receiver,
        uint24 activeId,
        bytes32 amounts,
        bytes32 totalFees,
        bytes32 protocolFees
    );

    event OracleLengthIncreased(address indexed sender, uint16 oracleLength);

    event ForcedDecay(address indexed sender, uint24 idReference, uint24 volatilityReference);

    function initialize(
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        uint24 activeId
    ) external;

    function getFactory() external view returns (ILBFactory factory);

    function getTokenX() external view returns (IERC20 tokenX);

    function getTokenY() external view returns (IERC20 tokenY);

    function getBinStep() external view returns (uint16 binStep);

    function getReserves() external view returns (uint128 reserveX, uint128 reserveY);

    function getActiveId() external view returns (uint24 activeId);

    function getBin(uint24 id) external view returns (uint128 binReserveX, uint128 binReserveY);

    function getNextNonEmptyBin(bool swapForY, uint24 id) external view returns (uint24 nextId);

    function getProtocolFees() external view returns (uint128 protocolFeeX, uint128 protocolFeeY);

    function getStaticFeeParameters()
        external
        view
        returns (
            uint16 baseFactor,
            uint16 filterPeriod,
            uint16 decayPeriod,
            uint16 reductionFactor,
            uint24 variableFeeControl,
            uint16 protocolShare,
            uint24 maxVolatilityAccumulator
        );

    function getVariableFeeParameters()
        external
        view
        returns (uint24 volatilityAccumulator, uint24 volatilityReference, uint24 idReference, uint40 timeOfLastUpdate);

    function getOracleParameters()
        external
        view
        returns (uint8 sampleLifetime, uint16 size, uint16 activeSize, uint40 lastUpdated, uint40 firstTimestamp);

    function getOracleSampleAt(uint40 lookupTimestamp)
        external
        view
        returns (uint64 cumulativeId, uint64 cumulativeVolatility, uint64 cumulativeBinCrossed);

    function getPriceFromId(uint24 id) external view returns (uint256 price);

    function getIdFromPrice(uint256 price) external view returns (uint24 id);

    function getSwapIn(uint128 amountOut, bool swapForY)
        external
        view
        returns (uint128 amountIn, uint128 amountOutLeft, uint128 fee);

    function getSwapOut(uint128 amountIn, bool swapForY)
        external
        view
        returns (uint128 amountInLeft, uint128 amountOut, uint128 fee);

    function swap(bool swapForY, address to) external returns (bytes32 amountsOut);

    function flashLoan(ILBFlashLoanCallback receiver, bytes32 amounts, bytes calldata data) external;

    function mint(address to, bytes32[] calldata liquidityConfigs, address refundTo)
        external
        returns (bytes32 amountsReceived, bytes32 amountsLeft, uint256[] memory liquidityMinted);

    function burn(address from, address to, uint256[] calldata ids, uint256[] calldata amountsToBurn)
        external
        returns (bytes32[] memory amounts);

    function collectProtocolFees() external returns (bytes32 collectedProtocolFees);

    function increaseOracleLength(uint16 newLength) external;

    function setStaticFeeParameters(
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) external;

    function forceDecay() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Liquidity Book Token Interface
 * @author Trader Joe
 * @notice Interface to interact with the LBToken.
 */
interface ILBToken {
    error LBToken__AddressThisOrZero();
    error LBToken__InvalidLength();
    error LBToken__SelfApproval(address owner);
    error LBToken__SpenderNotApproved(address from, address spender);
    error LBToken__TransferExceedsBalance(address from, uint256 id, uint256 amount);
    error LBToken__BurnExceedsBalance(address from, uint256 id, uint256 amount);

    event TransferBatch(
        address indexed sender, address indexed from, address indexed to, uint256[] ids, uint256[] amounts
    );

    event ApprovalForAll(address indexed account, address indexed sender, bool approved);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply(uint256 id) external view returns (uint256);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function isApprovedForAll(address owner, address spender) external view returns (bool);

    function approveForAll(address spender, bool approved) external;

    function batchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Liquidity Book Pending Ownable Interface
 * @author Trader Joe
 * @notice Required interface of Pending Ownable contract used for LBFactory
 */
interface IPendingOwnable {
    error PendingOwnable__AddressZero();
    error PendingOwnable__NoPendingOwner();
    error PendingOwnable__NotOwner();
    error PendingOwnable__NotPendingOwner();
    error PendingOwnable__PendingOwnerAlreadySet();

    event PendingOwnerSet(address indexed pendingOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function setPendingOwner(address pendingOwner) external;

    function revokePendingOwner() external;

    function becomeOwner() external;

    function renounceOwnership() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Liquidity Book Address Helper Library
 * @author Trader Joe
 * @notice This library contains functions to check if an address is a contract and
 * catch low level calls errors
 */
library AddressHelper {
    error AddressHelper__NonContract();
    error AddressHelper__CallFailed();

    /**
     * @notice Private view function to perform a low level call on `target`
     * @dev Revert if the call doesn't succeed
     * @param target The address of the account
     * @param data The data to execute on `target`
     * @return returnData The data returned by the call
     */
    function callAndCatch(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = target.call(data);

        if (success) {
            if (returnData.length == 0 && !isContract(target)) revert AddressHelper__NonContract();
        } else {
            if (returnData.length == 0) {
                revert AddressHelper__CallFailed();
            } else {
                // Look for revert reason and bubble it up if present
                assembly {
                    revert(add(32, returnData), mload(returnData))
                }
            }
        }

        return returnData;
    }

    /**
     * @notice Private view function to return if an address is a contract
     * @dev It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * @param account The address of the account
     * @return Whether the account is a contract (true) or not (false)
     */
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {PackedUint128Math} from "./math/PackedUint128Math.sol";
import {Uint256x256Math} from "./math/Uint256x256Math.sol";
import {SafeCast} from "./math/SafeCast.sol";
import {Constants} from "./Constants.sol";
import {PairParameterHelper} from "./PairParameterHelper.sol";
import {FeeHelper} from "./FeeHelper.sol";
import {PriceHelper} from "./PriceHelper.sol";
import {TokenHelper} from "./TokenHelper.sol";

/**
 * @title Liquidity Book Bin Helper Library
 * @author Trader Joe
 * @notice This library contains functions to help interaction with bins.
 */
library BinHelper {
    using PackedUint128Math for bytes32;
    using PackedUint128Math for uint128;
    using Uint256x256Math for uint256;
    using PriceHelper for uint24;
    using SafeCast for uint256;
    using PairParameterHelper for bytes32;
    using FeeHelper for uint128;
    using TokenHelper for IERC20;

    error BinHelper__CompositionFactorFlawed(uint24 id);
    error BinHelper__LiquidityOverflow();

    /**
     * @dev Returns the amount of tokens that will be received when burning the given amount of liquidity
     * @param binReserves The reserves of the bin
     * @param amountToBurn The amount of liquidity to burn
     * @param totalSupply The total supply of the liquidity book
     * @return amountsOut The encoded amount of tokens that will be received
     */
    function getAmountOutOfBin(bytes32 binReserves, uint256 amountToBurn, uint256 totalSupply)
        internal
        pure
        returns (bytes32 amountsOut)
    {
        (uint128 binReserveX, uint128 binReserveY) = binReserves.decode();

        uint128 amountXOutFromBin;
        uint128 amountYOutFromBin;

        if (binReserveX > 0) {
            amountXOutFromBin = (amountToBurn.mulDivRoundDown(binReserveX, totalSupply)).safe128();
        }

        if (binReserveY > 0) {
            amountYOutFromBin = (amountToBurn.mulDivRoundDown(binReserveY, totalSupply)).safe128();
        }

        amountsOut = amountXOutFromBin.encode(amountYOutFromBin);
    }

    /**
     * @dev Returns the share and the effective amounts in when adding liquidity
     * @param binReserves The reserves of the bin
     * @param amountsIn The amounts of tokens to add
     * @param price The price of the bin
     * @param totalSupply The total supply of the liquidity book
     * @return shares The share of the liquidity book that the user will receive
     * @return effectiveAmountsIn The encoded effective amounts of tokens that the user will add.
     * This is the amount of tokens that the user will actually add to the liquidity book,
     * and will always be less than or equal to the amountsIn.
     */
    function getSharesAndEffectiveAmountsIn(bytes32 binReserves, bytes32 amountsIn, uint256 price, uint256 totalSupply)
        internal
        pure
        returns (uint256 shares, bytes32 effectiveAmountsIn)
    {
        (uint256 x, uint256 y) = amountsIn.decode();

        uint256 userLiquidity = getLiquidity(x, y, price);
        if (totalSupply == 0 || userLiquidity == 0) return (userLiquidity, amountsIn);

        uint256 binLiquidity = getLiquidity(binReserves, price);
        if (binLiquidity == 0) return (userLiquidity, amountsIn);

        shares = userLiquidity.mulDivRoundDown(totalSupply, binLiquidity);
        uint256 effectiveLiquidity = shares.mulDivRoundUp(binLiquidity, totalSupply);

        if (userLiquidity > effectiveLiquidity) {
            uint256 deltaLiquidity = userLiquidity - effectiveLiquidity;

            // The other way might be more efficient, but as y is the quote asset, it is more valuable
            if (deltaLiquidity >= Constants.SCALE) {
                uint256 deltaY = deltaLiquidity >> Constants.SCALE_OFFSET;
                deltaY = deltaY > y ? y : deltaY;

                y -= deltaY;
                deltaLiquidity -= deltaY << Constants.SCALE_OFFSET;
            }

            if (deltaLiquidity >= price) {
                uint256 deltaX = deltaLiquidity / price;
                deltaX = deltaX > x ? x : deltaX;

                x -= deltaX;
            }

            amountsIn = uint128(x).encode(uint128(y));
        }

        return (shares, amountsIn);
    }

    /**
     * @dev Returns the amount of liquidity following the constant sum formula `L = price * x + y`
     * @param amounts The amounts of tokens
     * @param price The price of the bin
     * @return liquidity The amount of liquidity
     */
    function getLiquidity(bytes32 amounts, uint256 price) internal pure returns (uint256 liquidity) {
        (uint256 x, uint256 y) = amounts.decode();
        return getLiquidity(x, y, price);
    }

    /**
     * @dev Returns the amount of liquidity following the constant sum formula `L = price * x + y`
     * @param x The amount of the token X
     * @param y The amount of the token Y
     * @param price The price of the bin
     * @return liquidity The amount of liquidity
     */
    function getLiquidity(uint256 x, uint256 y, uint256 price) internal pure returns (uint256 liquidity) {
        if (x > 0) {
            unchecked {
                liquidity = price * x;
                if (liquidity / x != price) revert BinHelper__LiquidityOverflow();
            }
        }
        if (y > 0) {
            unchecked {
                y <<= Constants.SCALE_OFFSET;
                liquidity += y;

                if (liquidity < y) revert BinHelper__LiquidityOverflow();
            }
        }

        return liquidity;
    }

    /**
     * @dev Verify that the amounts are correct and that the composition factor is not flawed
     * @param amounts The amounts of tokens
     * @param activeId The id of the active bin
     * @param id The id of the bin
     */
    function verifyAmounts(bytes32 amounts, uint24 activeId, uint24 id) internal pure {
        if (id < activeId && (amounts << 128) > 0 || id > activeId && uint256(amounts) > type(uint128).max) {
            revert BinHelper__CompositionFactorFlawed(id);
        }
    }

    /**
     * @dev Returns the composition fees when adding liquidity to the active bin with a different
     * composition factor than the bin's one, as it does an implicit swap
     * @param binReserves The reserves of the bin
     * @param parameters The parameters of the liquidity book
     * @param binStep The step of the bin
     * @param amountsIn The amounts of tokens to add
     * @param totalSupply The total supply of the liquidity book
     * @param shares The share of the liquidity book that the user will receive
     * @return fees The encoded fees that will be charged
     */
    function getCompositionFees(
        bytes32 binReserves,
        bytes32 parameters,
        uint16 binStep,
        bytes32 amountsIn,
        uint256 totalSupply,
        uint256 shares
    ) internal pure returns (bytes32 fees) {
        if (shares == 0) return 0;

        (uint128 amountX, uint128 amountY) = amountsIn.decode();
        (uint128 receivedAmountX, uint128 receivedAmountY) =
            getAmountOutOfBin(binReserves.add(amountsIn), shares, totalSupply + shares).decode();

        if (receivedAmountX > amountX) {
            uint128 feeY = (amountY - receivedAmountY).getCompositionFee(parameters.getTotalFee(binStep));

            fees = feeY.encodeSecond();
        } else if (receivedAmountY > amountY) {
            uint128 feeX = (amountX - receivedAmountX).getCompositionFee(parameters.getTotalFee(binStep));

            fees = feeX.encodeFirst();
        }
    }

    /**
     * @dev Returns whether the bin is empty (true) or not (false)
     * @param binReserves The reserves of the bin
     * @param isX Whether the reserve to check is the X reserve (true) or the Y reserve (false)
     * @return Whether the bin is empty (true) or not (false)
     */
    function isEmpty(bytes32 binReserves, bool isX) internal pure returns (bool) {
        return isX ? binReserves.decodeX() == 0 : binReserves.decodeY() == 0;
    }

    /**
     * @dev Returns the amounts of tokens that will be added and removed from the bin during a swap
     * along with the fees that will be charged
     * @param binReserves The reserves of the bin
     * @param parameters The parameters of the liquidity book
     * @param binStep The step of the bin
     * @param swapForY Whether the swap is for Y (true) or for X (false)
     * @param activeId The id of the active bin
     * @param amountsInLeft The amounts of tokens left to swap
     * @return amountsInWithFees The encoded amounts of tokens that will be added to the bin, including fees
     * @return amountsOutOfBin The encoded amounts of tokens that will be removed from the bin
     * @return totalFees The encoded fees that will be charged
     */
    function getAmounts(
        bytes32 binReserves,
        bytes32 parameters,
        uint16 binStep,
        bool swapForY, // swap `swapForY` and `activeId` to avoid stack too deep
        uint24 activeId,
        bytes32 amountsInLeft
    ) internal pure returns (bytes32 amountsInWithFees, bytes32 amountsOutOfBin, bytes32 totalFees) {
        uint256 price = activeId.getPriceFromId(binStep);

        uint128 binReserveOut = binReserves.decode(!swapForY);

        uint128 maxAmountIn = swapForY
            ? uint256(binReserveOut).shiftDivRoundUp(Constants.SCALE_OFFSET, price).safe128()
            : uint256(binReserveOut).mulShiftRoundUp(price, Constants.SCALE_OFFSET).safe128();

        uint128 totalFee = parameters.getTotalFee(binStep);
        uint128 maxFee = maxAmountIn.getFeeAmount(totalFee);

        maxAmountIn += maxFee;

        uint128 amountIn128 = amountsInLeft.decode(swapForY);
        uint128 fee128;
        uint128 amountOut128;

        if (amountIn128 >= maxAmountIn) {
            fee128 = maxFee;

            amountIn128 = maxAmountIn;
            amountOut128 = binReserveOut;
        } else {
            fee128 = amountIn128.getFeeAmountFrom(totalFee);

            uint256 amountIn = amountIn128 - fee128;

            amountOut128 = swapForY
                ? uint256(amountIn).mulShiftRoundDown(price, Constants.SCALE_OFFSET).safe128()
                : uint256(amountIn).shiftDivRoundDown(Constants.SCALE_OFFSET, price).safe128();

            if (amountOut128 > binReserveOut) amountOut128 = binReserveOut;
        }

        (amountsInWithFees, amountsOutOfBin, totalFees) = swapForY
            ? (amountIn128.encodeFirst(), amountOut128.encodeSecond(), fee128.encodeFirst())
            : (amountIn128.encodeSecond(), amountOut128.encodeFirst(), fee128.encodeSecond());
    }

    /**
     * @dev Returns the encoded amounts that were transferred to the contract
     * @param reserves The reserves
     * @param tokenX The token X
     * @param tokenY The token Y
     * @return amounts The amounts, encoded as follows:
     * [0 - 128[: amountX
     * [128 - 256[: amountY
     */
    function received(bytes32 reserves, IERC20 tokenX, IERC20 tokenY) internal view returns (bytes32 amounts) {
        amounts = _balanceOf(tokenX).encode(_balanceOf(tokenY)).sub(reserves);
    }

    /**
     * @dev Returns the encoded amounts that were transferred to the contract, only for token X
     * @param reserves The reserves
     * @param tokenX The token X
     * @return amounts The amounts, encoded as follows:
     * [0 - 128[: amountX
     * [128 - 256[: empty
     */
    function receivedX(bytes32 reserves, IERC20 tokenX) internal view returns (bytes32) {
        uint128 reserveX = reserves.decodeX();
        return (_balanceOf(tokenX) - reserveX).encodeFirst();
    }

    /**
     * @dev Returns the encoded amounts that were transferred to the contract, only for token Y
     * @param reserves The reserves
     * @param tokenY The token Y
     * @return amounts The amounts, encoded as follows:
     * [0 - 128[: empty
     * [128 - 256[: amountY
     */
    function receivedY(bytes32 reserves, IERC20 tokenY) internal view returns (bytes32) {
        uint128 reserveY = reserves.decodeY();
        return (_balanceOf(tokenY) - reserveY).encodeSecond();
    }

    /**
     * @dev Transfers the encoded amounts to the recipient
     * @param amounts The amounts, encoded as follows:
     * [0 - 128[: amountX
     * [128 - 256[: amountY
     * @param tokenX The token X
     * @param tokenY The token Y
     * @param recipient The recipient
     */
    function transfer(bytes32 amounts, IERC20 tokenX, IERC20 tokenY, address recipient) internal {
        (uint128 amountX, uint128 amountY) = amounts.decode();

        if (amountX > 0) tokenX.safeTransfer(recipient, amountX);
        if (amountY > 0) tokenY.safeTransfer(recipient, amountY);
    }

    /**
     * @dev Transfers the encoded amounts to the recipient, only for token X
     * @param amounts The amounts, encoded as follows:
     * [0 - 128[: amountX
     * [128 - 256[: empty
     * @param tokenX The token X
     * @param recipient The recipient
     */
    function transferX(bytes32 amounts, IERC20 tokenX, address recipient) internal {
        uint128 amountX = amounts.decodeX();

        if (amountX > 0) tokenX.safeTransfer(recipient, amountX);
    }

    /**
     * @dev Transfers the encoded amounts to the recipient, only for token Y
     * @param amounts The amounts, encoded as follows:
     * [0 - 128[: empty
     * [128 - 256[: amountY
     * @param tokenY The token Y
     * @param recipient The recipient
     */
    function transferY(bytes32 amounts, IERC20 tokenY, address recipient) internal {
        uint128 amountY = amounts.decodeY();

        if (amountY > 0) tokenY.safeTransfer(recipient, amountY);
    }

    function _balanceOf(IERC20 token) private view returns (uint128) {
        return token.balanceOf(address(this)).safe128();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Clone
 * @notice Class with helper read functions for clone with immutable args.
 * @author Trader Joe
 * @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Clone.sol)
 * @author Adapted from clones with immutable args by zefram.eth, Saw-mon & Natalie
 * (https://github.com/Saw-mon-and-Natalie/clones-with-immutable-args)
 */
abstract contract Clone {
    /**
     * @dev Reads an immutable arg with type bytes
     * @param argOffset The offset of the arg in the immutable args
     * @param length The length of the arg
     * @return arg The immutable bytes arg
     */
    function _getArgBytes(uint256 argOffset, uint256 length) internal pure returns (bytes memory arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            // Grab the free memory pointer.
            arg := mload(0x40)
            // Store the array length.
            mstore(arg, length)
            // Copy the array.
            calldatacopy(add(arg, 0x20), add(offset, argOffset), length)
            // Allocate the memory, rounded up to the next 32 byte boundary.
            mstore(0x40, and(add(add(arg, 0x3f), length), not(0x1f)))
        }
    }

    /**
     * @dev Reads an immutable arg with type address
     * @param argOffset The offset of the arg in the immutable args
     * @return arg The immutable address arg
     */
    function _getArgAddress(uint256 argOffset) internal pure returns (address arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(0x60, calldataload(add(offset, argOffset)))
        }
    }

    /**
     * @dev Reads an immutable arg with type uint256
     * @param argOffset The offset of the arg in the immutable args
     * @return arg The immutable uint256 arg
     */
    function _getArgUint256(uint256 argOffset) internal pure returns (uint256 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /**
     * @dev Reads a uint256 array stored in the immutable args.
     * @param argOffset The offset of the arg in the immutable args
     * @param length The length of the arg
     * @return arg The immutable uint256 array arg
     */
    function _getArgUint256Array(uint256 argOffset, uint256 length) internal pure returns (uint256[] memory arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            // Grab the free memory pointer.
            arg := mload(0x40)
            // Store the array length.
            mstore(arg, length)
            // Copy the array.
            calldatacopy(add(arg, 0x20), add(offset, argOffset), shl(5, length))
            // Allocate the memory.
            mstore(0x40, add(add(arg, 0x20), shl(5, length)))
        }
    }

    /**
     * @dev Reads an immutable arg with type uint64
     * @param argOffset The offset of the arg in the immutable args
     * @return arg The immutable uint64 arg
     */
    function _getArgUint64(uint256 argOffset) internal pure returns (uint64 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(0xc0, calldataload(add(offset, argOffset)))
        }
    }

    /**
     * @dev Reads an immutable arg with type uint16
     * @param argOffset The offset of the arg in the immutable args
     * @return arg The immutable uint16 arg
     */
    function _getArgUint16(uint256 argOffset) internal pure returns (uint16 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(0xf0, calldataload(add(offset, argOffset)))
        }
    }

    /**
     * @dev Reads an immutable arg with type uint8
     * @param argOffset The offset of the arg in the immutable args
     * @return arg The immutable uint8 arg
     */
    function _getArgUint8(uint256 argOffset) internal pure returns (uint8 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(0xf8, calldataload(add(offset, argOffset)))
        }
    }

    /**
     * @dev Reads the offset of the packed immutable args in calldata.
     * @return offset The offset of the packed immutable args in calldata.
     */
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        /// @solidity memory-safe-assembly
        assembly {
            offset := sub(calldatasize(), shr(0xf0, calldataload(sub(calldatasize(), 2))))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Liquidity Book Constants Library
 * @author Trader Joe
 * @notice Set of constants for Liquidity Book contracts
 */
library Constants {
    uint8 internal constant SCALE_OFFSET = 128;
    uint256 internal constant SCALE = 1 << SCALE_OFFSET;

    uint256 internal constant PRECISION = 1e18;
    uint256 internal constant SQUARED_PRECISION = PRECISION * PRECISION;

    uint256 internal constant MAX_FEE = 0.1e18; // 10%
    uint256 internal constant MAX_PROTOCOL_SHARE = 2_500; // 25% of the fee

    uint256 internal constant BASIS_POINT_MAX = 10_000;

    /// @dev The expected return after a successful flash loan
    bytes32 internal constant CALLBACK_SUCCESS = keccak256("LBPair.onFlashLoan");
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {Constants} from "./Constants.sol";

/**
 * @title Liquidity Book Fee Helper Library
 * @author Trader Joe
 * @notice This library contains functions to calculate fees
 */
library FeeHelper {
    error FeeHelper__FeeTooLarge();
    error FeeHelper__ProtocolShareTooLarge();

    /**
     * @dev Modifier to check that the fee is not too large
     * @param fee The fee
     */
    modifier verifyFee(uint128 fee) {
        if (fee > Constants.MAX_FEE) revert FeeHelper__FeeTooLarge();
        _;
    }

    /**
     * @dev Modifier to check that the protocol share is not too large
     * @param protocolShare The protocol share
     */
    modifier verifyProtocolShare(uint128 protocolShare) {
        if (protocolShare > Constants.MAX_PROTOCOL_SHARE) revert FeeHelper__ProtocolShareTooLarge();
        _;
    }

    /**
     * @dev Calculates the fee amount from the amount with fees, rounding up
     * @param amountWithFees The amount with fees
     * @param totalFee The total fee
     * @return feeAmount The fee amount
     */
    function getFeeAmountFrom(uint128 amountWithFees, uint128 totalFee)
        internal
        pure
        verifyFee(totalFee)
        returns (uint128)
    {
        unchecked {
            // Can't overflow, max(result) = (type(uint128).max * 0.1e18 + 1e18 - 1) / 1e18 < 2^128
            return uint128((uint256(amountWithFees) * totalFee + Constants.PRECISION - 1) / Constants.PRECISION);
        }
    }

    /**
     * @dev Calculates the fee amount that will be charged, rounding up
     * @param amount The amount
     * @param totalFee The total fee
     * @return feeAmount The fee amount
     */
    function getFeeAmount(uint128 amount, uint128 totalFee) internal pure verifyFee(totalFee) returns (uint128) {
        unchecked {
            uint256 denominator = Constants.PRECISION - totalFee;
            // Can't overflow, max(result) = (type(uint128).max * 0.1e18 + (1e18 - 1)) / 0.9e18 < 2^128
            return uint128((uint256(amount) * totalFee + denominator - 1) / denominator);
        }
    }

    /**
     * @dev Calculates the composition fee amount from the amount with fees, rounding down
     * @param amountWithFees The amount with fees
     * @param totalFee The total fee
     * @return The amount with fees
     */
    function getCompositionFee(uint128 amountWithFees, uint128 totalFee)
        internal
        pure
        verifyFee(totalFee)
        returns (uint128)
    {
        unchecked {
            uint256 denominator = Constants.SQUARED_PRECISION;
            // Can't overflow, max(result) = type(uint128).max * 0.1e18 * 1.1e18 / 1e36 <= 2^128 * 0.11e36 / 1e36 < 2^128
            return uint128(uint256(amountWithFees) * totalFee * (uint256(totalFee) + Constants.PRECISION) / denominator);
        }
    }

    /**
     * @dev Calculates the protocol fee amount from the fee amount and the protocol share, rounding down
     * @param feeAmount The fee amount
     * @param protocolShare The protocol share
     * @return protocolFeeAmount The protocol fee amount
     */
    function getProtocolFeeAmount(uint128 feeAmount, uint128 protocolShare)
        internal
        pure
        verifyProtocolShare(protocolShare)
        returns (uint128)
    {
        unchecked {
            return uint128(uint256(feeAmount) * protocolShare / Constants.BASIS_POINT_MAX);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {SampleMath} from "./math/SampleMath.sol";
import {SafeCast} from "./math/SafeCast.sol";
import {PairParameterHelper} from "./PairParameterHelper.sol";

/**
 * @title Liquidity Book Oracle Helper Library
 * @author Trader Joe
 * @notice This library contains functions to manage the oracle
 * The oracle samples are stored in a single bytes32 array.
 * Each sample is encoded as follows:
 * 0 - 16: oracle length (16 bits)
 * 16 - 80: cumulative id (64 bits)
 * 80 - 144: cumulative volatility accumulator (64 bits)
 * 144 - 208: cumulative bin crossed (64 bits)
 * 208 - 216: sample lifetime (8 bits)
 * 216 - 256: sample creation timestamp (40 bits)
 */
library OracleHelper {
    using SampleMath for bytes32;
    using SafeCast for uint256;
    using PairParameterHelper for bytes32;

    error OracleHelper__InvalidOracleId();
    error OracleHelper__NewLengthTooSmall();
    error OracleHelper__LookUpTimestampTooOld();

    struct Oracle {
        bytes32[65535] samples;
    }

    uint256 internal constant _MAX_SAMPLE_LIFETIME = 120 seconds;

    /**
     * @dev Modifier to check that the oracle id is valid
     * @param oracleId The oracle id
     */
    modifier checkOracleId(uint16 oracleId) {
        if (oracleId == 0) revert OracleHelper__InvalidOracleId();
        _;
    }

    /**
     * @dev Returns the sample at the given oracleId
     * @param oracle The oracle
     * @param oracleId The oracle id
     * @return sample The sample
     */
    function getSample(Oracle storage oracle, uint16 oracleId)
        internal
        view
        checkOracleId(oracleId)
        returns (bytes32 sample)
    {
        unchecked {
            sample = oracle.samples[oracleId - 1];
        }
    }

    /**
     * @dev Returns the active sample and the active size of the oracle
     * @param oracle The oracle
     * @param oracleId The oracle id
     * @return activeSample The active sample
     * @return activeSize The active size of the oracle
     */
    function getActiveSampleAndSize(Oracle storage oracle, uint16 oracleId)
        internal
        view
        returns (bytes32 activeSample, uint16 activeSize)
    {
        activeSample = getSample(oracle, oracleId);
        activeSize = activeSample.getOracleLength();

        if (oracleId != activeSize) {
            activeSize = getSample(oracle, activeSize).getOracleLength();
            activeSize = oracleId > activeSize ? oracleId : activeSize;
        }
    }

    /**
     * @dev Returns the sample at the given timestamp. If the timestamp is not in the oracle, it returns the closest sample
     * @param oracle The oracle
     * @param oracleId The oracle id
     * @param lookUpTimestamp The timestamp to look up
     * @return lastUpdate The last update timestamp
     * @return cumulativeId The cumulative id
     * @return cumulativeVolatility The cumulative volatility
     * @return cumulativeBinCrossed The cumulative bin crossed
     */
    function getSampleAt(Oracle storage oracle, uint16 oracleId, uint40 lookUpTimestamp)
        internal
        view
        returns (uint40 lastUpdate, uint64 cumulativeId, uint64 cumulativeVolatility, uint64 cumulativeBinCrossed)
    {
        (bytes32 activeSample, uint16 activeSize) = getActiveSampleAndSize(oracle, oracleId);

        if (oracle.samples[oracleId % activeSize].getSampleLastUpdate() > lookUpTimestamp) {
            revert OracleHelper__LookUpTimestampTooOld();
        }

        lastUpdate = activeSample.getSampleLastUpdate();
        if (lastUpdate <= lookUpTimestamp) {
            return (
                lastUpdate,
                activeSample.getCumulativeId(),
                activeSample.getCumulativeVolatility(),
                activeSample.getCumulativeBinCrossed()
            );
        } else {
            lastUpdate = lookUpTimestamp;
        }
        (bytes32 prevSample, bytes32 nextSample) = binarySearch(oracle, oracleId, lookUpTimestamp, activeSize);
        uint40 weightPrev = nextSample.getSampleLastUpdate() - lookUpTimestamp;
        uint40 weightNext = lookUpTimestamp - prevSample.getSampleLastUpdate();

        (cumulativeId, cumulativeVolatility, cumulativeBinCrossed) =
            prevSample.getWeightedAverage(nextSample, weightPrev, weightNext);
    }

    /**
     * @dev Binary search to find the 2 samples surrounding the given timestamp
     * @param oracle The oracle
     * @param oracleId The oracle id
     * @param lookUpTimestamp The timestamp to look up
     * @param length The oracle length
     * @return prevSample The previous sample
     * @return nextSample The next sample
     */
    function binarySearch(Oracle storage oracle, uint16 oracleId, uint40 lookUpTimestamp, uint16 length)
        internal
        view
        returns (bytes32, bytes32)
    {
        uint256 low = 0;
        uint256 high = length - 1;

        bytes32 sample;
        uint40 sampleLastUpdate;

        uint256 startId = oracleId; // oracleId is 1-based
        while (low <= high) {
            uint256 mid = (low + high) >> 1;

            assembly {
                oracleId := addmod(startId, mid, length)
            }

            sample = oracle.samples[oracleId];
            sampleLastUpdate = sample.getSampleLastUpdate();

            if (sampleLastUpdate > lookUpTimestamp) {
                high = mid - 1;
            } else if (sampleLastUpdate < lookUpTimestamp) {
                low = mid + 1;
            } else {
                return (sample, sample);
            }
        }

        if (lookUpTimestamp < sampleLastUpdate) {
            unchecked {
                if (oracleId == 0) {
                    oracleId = length;
                }

                return (oracle.samples[oracleId - 1], sample);
            }
        } else {
            assembly {
                oracleId := addmod(oracleId, 1, length)
            }

            return (sample, oracle.samples[oracleId]);
        }
    }

    /**
     * @dev Sets the sample at the given oracleId
     * @param oracle The oracle
     * @param oracleId The oracle id
     * @param sample The sample
     */
    function setSample(Oracle storage oracle, uint16 oracleId, bytes32 sample) internal checkOracleId(oracleId) {
        unchecked {
            oracle.samples[oracleId - 1] = sample;
        }
    }

    /**
     * @dev Updates the oracle
     * @param oracle The oracle
     * @param parameters The parameters
     * @param activeId The active id
     * @return The updated parameters
     */
    function update(Oracle storage oracle, bytes32 parameters, uint24 activeId) internal returns (bytes32) {
        uint16 oracleId = parameters.getOracleId();
        if (oracleId == 0) return parameters;

        bytes32 sample = getSample(oracle, oracleId);

        uint40 createdAt = sample.getSampleCreation();
        uint40 lastUpdatedAt = createdAt + sample.getSampleLifetime();

        if (block.timestamp.safe40() > lastUpdatedAt) {
            unchecked {
                (uint64 cumulativeId, uint64 cumulativeVolatility, uint64 cumulativeBinCrossed) = sample.update(
                    uint40(block.timestamp - lastUpdatedAt),
                    activeId,
                    parameters.getVolatilityAccumulator(),
                    parameters.getDeltaId(activeId)
                );

                uint16 length = sample.getOracleLength();
                uint256 lifetime = block.timestamp - createdAt;

                if (lifetime > _MAX_SAMPLE_LIFETIME) {
                    assembly {
                        oracleId := add(mod(oracleId, length), 1)
                    }

                    lifetime = 0;
                    createdAt = uint40(block.timestamp);

                    parameters = parameters.setOracleId(oracleId);
                }

                sample = SampleMath.encode(
                    length, cumulativeId, cumulativeVolatility, cumulativeBinCrossed, uint8(lifetime), createdAt
                );
            }

            setSample(oracle, oracleId, sample);
        }

        return parameters;
    }

    /**
     * @dev Increases the oracle length
     * @param oracle The oracle
     * @param oracleId The oracle id
     * @param newLength The new length
     */
    function increaseLength(Oracle storage oracle, uint16 oracleId, uint16 newLength) internal {
        bytes32 sample = getSample(oracle, oracleId);
        uint16 length = sample.getOracleLength();

        if (length >= newLength) revert OracleHelper__NewLengthTooSmall();

        bytes32 lastSample = length == oracleId ? sample : length == 0 ? bytes32(0) : getSample(oracle, length);

        uint256 activeSize = lastSample.getOracleLength();
        activeSize = oracleId > activeSize ? oracleId : activeSize;

        for (uint256 i = length; i < newLength;) {
            oracle.samples[i] = bytes32(uint256(activeSize));

            unchecked {
                ++i;
            }
        }

        setSample(oracle, oracleId, (sample ^ bytes32(uint256(length))) | bytes32(uint256(newLength)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {Constants} from "./Constants.sol";
import {SafeCast} from "./math/SafeCast.sol";
import {Encoded} from "./math/Encoded.sol";

/**
 * @title Liquidity Book Pair Parameter Helper Library
 * @author Trader Joe
 * @dev This library contains functions to get and set parameters of a pair
 * The parameters are stored in a single bytes32 variable in the following format:
 * [0 - 16[: base factor (16 bits)
 * [16 - 28[: filter period (12 bits)
 * [28 - 40[: decay period (12 bits)
 * [40 - 54[: reduction factor (14 bits)
 * [54 - 78[: variable fee control (24 bits)
 * [78 - 92[: protocol share (14 bits)
 * [92 - 112[: max volatility accumulator (20 bits)
 * [112 - 132[: volatility accumulator (20 bits)
 * [132 - 152[: volatility reference (20 bits)
 * [152 - 176[: index reference (24 bits)
 * [176 - 216[: time of last update (40 bits)
 * [216 - 232[: oracle index (16 bits)
 * [232 - 256[: active index (24 bits)
 */
library PairParameterHelper {
    using SafeCast for uint256;
    using Encoded for bytes32;

    error PairParametersHelper__InvalidParameter();

    uint256 internal constant OFFSET_BASE_FACTOR = 0;
    uint256 internal constant OFFSET_FILTER_PERIOD = 16;
    uint256 internal constant OFFSET_DECAY_PERIOD = 28;
    uint256 internal constant OFFSET_REDUCTION_FACTOR = 40;
    uint256 internal constant OFFSET_VAR_FEE_CONTROL = 54;
    uint256 internal constant OFFSET_PROTOCOL_SHARE = 78;
    uint256 internal constant OFFSET_MAX_VOL_ACC = 92;
    uint256 internal constant OFFSET_VOL_ACC = 112;
    uint256 internal constant OFFSET_VOL_REF = 132;
    uint256 internal constant OFFSET_ID_REF = 152;
    uint256 internal constant OFFSET_TIME_LAST_UPDATE = 176;
    uint256 internal constant OFFSET_ORACLE_ID = 216;
    uint256 internal constant OFFSET_ACTIVE_ID = 232;

    uint256 internal constant MASK_STATIC_PARAMETER = 0xffffffffffffffffffffffffffff;

    /**
     * @dev Get the base factor from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 16[: base factor (16 bits)
     * [16 - 256[: other parameters
     * @return baseFactor The base factor
     */
    function getBaseFactor(bytes32 params) internal pure returns (uint16 baseFactor) {
        baseFactor = params.decodeUint16(OFFSET_BASE_FACTOR);
    }

    /**
     * @dev Get the filter period from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 16[: other parameters
     * [16 - 28[: filter period (12 bits)
     * [28 - 256[: other parameters
     * @return filterPeriod The filter period
     */
    function getFilterPeriod(bytes32 params) internal pure returns (uint16 filterPeriod) {
        filterPeriod = params.decodeUint12(OFFSET_FILTER_PERIOD);
    }

    /**
     * @dev Get the decay period from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 28[: other parameters
     * [28 - 40[: decay period (12 bits)
     * [40 - 256[: other parameters
     * @return decayPeriod The decay period
     */
    function getDecayPeriod(bytes32 params) internal pure returns (uint16 decayPeriod) {
        decayPeriod = params.decodeUint12(OFFSET_DECAY_PERIOD);
    }

    /**
     * @dev Get the reduction factor from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 40[: other parameters
     * [40 - 54[: reduction factor (14 bits)
     * [54 - 256[: other parameters
     * @return reductionFactor The reduction factor
     */
    function getReductionFactor(bytes32 params) internal pure returns (uint16 reductionFactor) {
        reductionFactor = params.decodeUint14(OFFSET_REDUCTION_FACTOR);
    }

    /**
     * @dev Get the variable fee control from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 54[: other parameters
     * [54 - 78[: variable fee control (24 bits)
     * [78 - 256[: other parameters
     * @return variableFeeControl The variable fee control
     */
    function getVariableFeeControl(bytes32 params) internal pure returns (uint24 variableFeeControl) {
        variableFeeControl = params.decodeUint24(OFFSET_VAR_FEE_CONTROL);
    }

    /**
     * @dev Get the protocol share from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 78[: other parameters
     * [78 - 92[: protocol share (14 bits)
     * [92 - 256[: other parameters
     * @return protocolShare The protocol share
     */
    function getProtocolShare(bytes32 params) internal pure returns (uint16 protocolShare) {
        protocolShare = params.decodeUint14(OFFSET_PROTOCOL_SHARE);
    }

    /**
     * @dev Get the max volatility accumulator from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 92[: other parameters
     * [92 - 112[: max volatility accumulator (20 bits)
     * [112 - 256[: other parameters
     * @return maxVolatilityAccumulator The max volatility accumulator
     */
    function getMaxVolatilityAccumulator(bytes32 params) internal pure returns (uint24 maxVolatilityAccumulator) {
        maxVolatilityAccumulator = params.decodeUint20(OFFSET_MAX_VOL_ACC);
    }

    /**
     * @dev Get the volatility accumulator from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 112[: other parameters
     * [112 - 132[: volatility accumulator (20 bits)
     * [132 - 256[: other parameters
     * @return volatilityAccumulator The volatility accumulator
     */
    function getVolatilityAccumulator(bytes32 params) internal pure returns (uint24 volatilityAccumulator) {
        volatilityAccumulator = params.decodeUint20(OFFSET_VOL_ACC);
    }

    /**
     * @dev Get the volatility reference from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 132[: other parameters
     * [132 - 152[: volatility reference (20 bits)
     * [152 - 256[: other parameters
     * @return volatilityReference The volatility reference
     */
    function getVolatilityReference(bytes32 params) internal pure returns (uint24 volatilityReference) {
        volatilityReference = params.decodeUint20(OFFSET_VOL_REF);
    }

    /**
     * @dev Get the index reference from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 152[: other parameters
     * [152 - 176[: index reference (24 bits)
     * [176 - 256[: other parameters
     * @return idReference The index reference
     */
    function getIdReference(bytes32 params) internal pure returns (uint24 idReference) {
        idReference = params.decodeUint24(OFFSET_ID_REF);
    }

    /**
     * @dev Get the time of last update from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 176[: other parameters
     * [176 - 216[: time of last update (40 bits)
     * [216 - 256[: other parameters
     * @return timeOflastUpdate The time of last update
     */
    function getTimeOfLastUpdate(bytes32 params) internal pure returns (uint40 timeOflastUpdate) {
        timeOflastUpdate = params.decodeUint40(OFFSET_TIME_LAST_UPDATE);
    }

    /**
     * @dev Get the oracle id from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 216[: other parameters
     * [216 - 232[: oracle id (16 bits)
     * [232 - 256[: other parameters
     * @return oracleId The oracle id
     */
    function getOracleId(bytes32 params) internal pure returns (uint16 oracleId) {
        oracleId = params.decodeUint16(OFFSET_ORACLE_ID);
    }

    /**
     * @dev Get the active index from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 232[: other parameters
     * [232 - 256[: active index (24 bits)
     * @return activeId The active index
     */
    function getActiveId(bytes32 params) internal pure returns (uint24 activeId) {
        activeId = params.decodeUint24(OFFSET_ACTIVE_ID);
    }

    /**
     * @dev Get the delta between the current active index and the cached active index
     * @param params The encoded pair parameters, as follows:
     * [0 - 232[: other parameters
     * [232 - 256[: active index (24 bits)
     * @param activeId The current active index
     * @return The delta
     */
    function getDeltaId(bytes32 params, uint24 activeId) internal pure returns (uint24) {
        uint24 id = getActiveId(params);
        unchecked {
            return activeId > id ? activeId - id : id - activeId;
        }
    }

    /**
     * @dev Calculates the base fee, with 18 decimals
     * @param params The encoded pair parameters
     * @param binStep The bin step (in basis points)
     * @return baseFee The base fee
     */
    function getBaseFee(bytes32 params, uint16 binStep) internal pure returns (uint256) {
        unchecked {
            // Base factor is in basis points, binStep is in basis points, so we multiply by 1e10
            return uint256(getBaseFactor(params)) * binStep * 1e10;
        }
    }

    /**
     * @dev Calculates the variable fee
     * @param params The encoded pair parameters
     * @param binStep The bin step (in basis points)
     * @return variableFee The variable fee
     */
    function getVariableFee(bytes32 params, uint16 binStep) internal pure returns (uint256 variableFee) {
        uint256 variableFeeControl = getVariableFeeControl(params);

        if (variableFeeControl != 0) {
            unchecked {
                // The volatility accumulator is in basis points, binStep is in basis points,
                // and the variable fee control is in basis points, so the result is in 100e18th
                uint256 prod = uint256(getVolatilityAccumulator(params)) * binStep;
                variableFee = (prod * prod * variableFeeControl + 99) / 100;
            }
        }
    }

    /**
     * @dev Calculates the total fee, which is the sum of the base fee and the variable fee
     * @param params The encoded pair parameters
     * @param binStep The bin step (in basis points)
     * @return totalFee The total fee
     */
    function getTotalFee(bytes32 params, uint16 binStep) internal pure returns (uint128) {
        unchecked {
            return (getBaseFee(params, binStep) + getVariableFee(params, binStep)).safe128();
        }
    }

    /**
     * @dev Set the oracle id in the encoded pair parameters
     * @param params The encoded pair parameters
     * @param oracleId The oracle id
     * @return The updated encoded pair parameters
     */
    function setOracleId(bytes32 params, uint16 oracleId) internal pure returns (bytes32) {
        return params.set(oracleId, Encoded.MASK_UINT16, OFFSET_ORACLE_ID);
    }

    /**
     * @dev Set the volatility reference in the encoded pair parameters
     * @param params The encoded pair parameters
     * @param volRef The volatility reference
     * @return The updated encoded pair parameters
     */
    function setVolatilityReference(bytes32 params, uint24 volRef) internal pure returns (bytes32) {
        if (volRef > Encoded.MASK_UINT20) revert PairParametersHelper__InvalidParameter();

        return params.set(volRef, Encoded.MASK_UINT20, OFFSET_VOL_REF);
    }

    /**
     * @dev Set the volatility accumulator in the encoded pair parameters
     * @param params The encoded pair parameters
     * @param volAcc The volatility accumulator
     * @return The updated encoded pair parameters
     */
    function setVolatilityAccumulator(bytes32 params, uint24 volAcc) internal pure returns (bytes32) {
        if (volAcc > Encoded.MASK_UINT20) revert PairParametersHelper__InvalidParameter();

        return params.set(volAcc, Encoded.MASK_UINT20, OFFSET_VOL_ACC);
    }

    /**
     * @dev Set the active id in the encoded pair parameters
     * @param params The encoded pair parameters
     * @param activeId The active id
     * @return newParams The updated encoded pair parameters
     */
    function setActiveId(bytes32 params, uint24 activeId) internal pure returns (bytes32 newParams) {
        return params.set(activeId, Encoded.MASK_UINT24, OFFSET_ACTIVE_ID);
    }

    /**
     * @dev Sets the static fee parameters in the encoded pair parameters
     * @param params The encoded pair parameters
     * @param baseFactor The base factor
     * @param filterPeriod The filter period
     * @param decayPeriod The decay period
     * @param reductionFactor The reduction factor
     * @param variableFeeControl The variable fee control
     * @param protocolShare The protocol share
     * @param maxVolatilityAccumulator The max volatility accumulator
     * @return newParams The updated encoded pair parameters
     */
    function setStaticFeeParameters(
        bytes32 params,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) internal pure returns (bytes32 newParams) {
        if (
            filterPeriod > decayPeriod || decayPeriod > Encoded.MASK_UINT12
                || reductionFactor > Constants.BASIS_POINT_MAX || protocolShare > Constants.MAX_PROTOCOL_SHARE
                || maxVolatilityAccumulator > Encoded.MASK_UINT20
        ) revert PairParametersHelper__InvalidParameter();

        newParams = newParams.set(baseFactor, Encoded.MASK_UINT16, OFFSET_BASE_FACTOR);
        newParams = newParams.set(filterPeriod, Encoded.MASK_UINT12, OFFSET_FILTER_PERIOD);
        newParams = newParams.set(decayPeriod, Encoded.MASK_UINT12, OFFSET_DECAY_PERIOD);
        newParams = newParams.set(reductionFactor, Encoded.MASK_UINT14, OFFSET_REDUCTION_FACTOR);
        newParams = newParams.set(variableFeeControl, Encoded.MASK_UINT24, OFFSET_VAR_FEE_CONTROL);
        newParams = newParams.set(protocolShare, Encoded.MASK_UINT14, OFFSET_PROTOCOL_SHARE);
        newParams = newParams.set(maxVolatilityAccumulator, Encoded.MASK_UINT20, OFFSET_MAX_VOL_ACC);

        return params.set(uint256(newParams), MASK_STATIC_PARAMETER, 0);
    }

    /**
     * @dev Updates the index reference in the encoded pair parameters
     * @param params The encoded pair parameters
     * @return newParams The updated encoded pair parameters
     */
    function updateIdReference(bytes32 params) internal pure returns (bytes32 newParams) {
        uint24 activeId = getActiveId(params);
        return params.set(activeId, Encoded.MASK_UINT24, OFFSET_ID_REF);
    }

    /**
     * @dev Updates the time of last update in the encoded pair parameters
     * @param params The encoded pair parameters
     * @return newParams The updated encoded pair parameters
     */
    function updateTimeOfLastUpdate(bytes32 params) internal view returns (bytes32 newParams) {
        uint40 currentTime = block.timestamp.safe40();
        return params.set(currentTime, Encoded.MASK_UINT40, OFFSET_TIME_LAST_UPDATE);
    }

    /**
     * @dev Updates the volatility reference in the encoded pair parameters
     * @param params The encoded pair parameters
     * @return The updated encoded pair parameters
     */
    function updateVolatilityReference(bytes32 params) internal pure returns (bytes32) {
        uint256 volAcc = getVolatilityAccumulator(params);
        uint256 reductionFactor = getReductionFactor(params);

        uint24 volRef;
        unchecked {
            volRef = uint24(volAcc * reductionFactor / Constants.BASIS_POINT_MAX);
        }

        return setVolatilityReference(params, volRef);
    }

    /**
     * @dev Updates the volatility accumulator in the encoded pair parameters
     * @param params The encoded pair parameters
     * @param activeId The active id
     * @return The updated encoded pair parameters
     */
    function updateVolatilityAccumulator(bytes32 params, uint24 activeId) internal pure returns (bytes32) {
        uint256 idReference = getIdReference(params);

        uint256 deltaId;
        uint256 volAcc;

        unchecked {
            deltaId = activeId > idReference ? activeId - idReference : idReference - activeId;
            volAcc = (uint256(getVolatilityReference(params)) + deltaId * Constants.BASIS_POINT_MAX);
        }

        uint256 maxVolAcc = getMaxVolatilityAccumulator(params);

        volAcc = volAcc > maxVolAcc ? maxVolAcc : volAcc;

        return setVolatilityAccumulator(params, uint24(volAcc));
    }

    /**
     * @dev Updates the volatility reference and the volatility accumulator in the encoded pair parameters
     * @param params The encoded pair parameters
     * @return The updated encoded pair parameters
     */
    function updateReferences(bytes32 params) internal view returns (bytes32) {
        uint256 dt = block.timestamp - getTimeOfLastUpdate(params);

        if (dt >= getFilterPeriod(params)) {
            params = updateIdReference(params);
            params = dt < getDecayPeriod(params) ? updateVolatilityReference(params) : setVolatilityReference(params, 0);
        }

        return updateTimeOfLastUpdate(params);
    }

    /**
     * @dev Updates the volatility reference and the volatility accumulator in the encoded pair parameters
     * @param params The encoded pair parameters
     * @param activeId The active id
     * @return The updated encoded pair parameters
     */
    function updateVolatilityParameters(bytes32 params, uint24 activeId) internal view returns (bytes32) {
        params = updateReferences(params);
        return updateVolatilityAccumulator(params, activeId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {Uint128x128Math} from "./math/Uint128x128Math.sol";
import {Uint256x256Math} from "./math/Uint256x256Math.sol";
import {SafeCast} from "./math/SafeCast.sol";
import {Constants} from "./Constants.sol";

/**
 * @title Liquidity Book Price Helper Library
 * @author Trader Joe
 * @notice This library contains functions to calculate prices
 */
library PriceHelper {
    using Uint128x128Math for uint256;
    using Uint256x256Math for uint256;
    using SafeCast for uint256;

    int256 private constant REAL_ID_SHIFT = 1 << 23;

    /**
     * @dev Calculates the price from the id and the bin step
     * @param id The id
     * @param binStep The bin step
     * @return price The price as a 128.128-binary fixed-point number
     */
    function getPriceFromId(uint24 id, uint16 binStep) internal pure returns (uint256 price) {
        uint256 base = getBase(binStep);
        int256 exponent = getExponent(id);

        price = base.pow(exponent);
    }

    /**
     * @dev Calculates the id from the price and the bin step
     * @param price The price as a 128.128-binary fixed-point number
     * @param binStep The bin step
     * @return id The id
     */
    function getIdFromPrice(uint256 price, uint16 binStep) internal pure returns (uint24 id) {
        uint256 base = getBase(binStep);
        int256 realId = price.log2() / base.log2();

        unchecked {
            id = uint256(REAL_ID_SHIFT + realId).safe24();
        }
    }

    /**
     * @dev Calculates the base from the bin step, which is `1 + binStep / BASIS_POINT_MAX`
     * @param binStep The bin step
     * @return base The base
     */
    function getBase(uint16 binStep) internal pure returns (uint256) {
        unchecked {
            return Constants.SCALE + (uint256(binStep) << Constants.SCALE_OFFSET) / Constants.BASIS_POINT_MAX;
        }
    }

    /**
     * @dev Calculates the exponent from the id, which is `id - REAL_ID_SHIFT`
     * @param id The id
     * @return exponent The exponent
     */
    function getExponent(uint24 id) internal pure returns (int256) {
        unchecked {
            return int256(uint256(id)) - REAL_ID_SHIFT;
        }
    }

    /**
     * @dev Converts a price with 18 decimals to a 128.128-binary fixed-point number
     * @param price The price with 18 decimals
     * @return price128x128 The 128.128-binary fixed-point number
     */
    function convertDecimalPriceTo128x128(uint256 price) internal pure returns (uint256) {
        return price.shiftDivRoundDown(Constants.SCALE_OFFSET, Constants.PRECISION);
    }

    /**
     * @dev Converts a 128.128-binary fixed-point number to a price with 18 decimals
     * @param price128x128 The 128.128-binary fixed-point number
     * @return price The price with 18 decimals
     */
    function convert128x128PriceToDecimal(uint256 price128x128) internal pure returns (uint256) {
        return price128x128.mulShiftRoundDown(Constants.PRECISION, Constants.SCALE_OFFSET);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Liquidity Book Reentrancy Guard Library
 * @author Trader Joe
 * @notice This library contains functions to prevent reentrant calls to a function
 */
abstract contract ReentrancyGuard {
    error ReentrancyGuard__ReentrantCall();

    /**
     * Booleans are more expensive than uint256 or any type that takes up a full
     * word because each write operation emits an extra SLOAD to first read the
     * slot's contents, replace the bits taken up by the boolean, and then write
     * back. This is the compiler's defense against contract upgrades and
     * pointer aliasing, and it cannot be disabled.
     *
     * The values being non-zero value makes deployment a bit more expensive,
     * but in exchange the refund on every call to nonReentrant will be lower in
     * amount. Since refunds are capped to a percentage of the total
     * transaction's gas, it is best to keep them low in cases like this one, to
     * increase the likelihood of the full refund coming into effect.
     */

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        if (_status != _NOT_ENTERED) revert ReentrancyGuard__ReentrantCall();

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {AddressHelper} from "./AddressHelper.sol";

/**
 * @title Liquidity Book Token Helper Library
 * @author Trader Joe
 * @notice Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using TokenHelper for IERC20;` statement to your contract,
 * which allows you to call the safe operation as `token.safeTransfer(...)`
 */
library TokenHelper {
    using AddressHelper for address;

    error TokenHelper__TransferFailed();

    /**
     * @notice Transfers token and reverts if the transfer fails
     * @param token The address of the token
     * @param owner The owner of the tokens
     * @param recipient The address of the recipient
     * @param amount The amount to send
     */
    function safeTransferFrom(IERC20 token, address owner, address recipient, uint256 amount) internal {
        bytes memory data = abi.encodeWithSelector(token.transferFrom.selector, owner, recipient, amount);

        bytes memory returnData = address(token).callAndCatch(data);

        if (returnData.length > 0 && !abi.decode(returnData, (bool))) revert TokenHelper__TransferFailed();
    }

    /**
     * @notice Transfers token and reverts if the transfer fails
     * @param token The address of the token
     * @param recipient The address of the recipient
     * @param amount The amount to send
     */
    function safeTransfer(IERC20 token, address recipient, uint256 amount) internal {
        bytes memory data = abi.encodeWithSelector(token.transfer.selector, recipient, amount);

        bytes memory returnData = address(token).callAndCatch(data);

        if (returnData.length > 0 && !abi.decode(returnData, (bool))) revert TokenHelper__TransferFailed();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Liquidity Book Bit Math Library
 * @author Trader Joe
 * @notice Helper contract used for bit calculations
 */
library BitMath {
    /**
     * @dev Returns the index of the closest bit on the right of x that is non null
     * @param x The value as a uint256
     * @param bit The index of the bit to start searching at
     * @return id The index of the closest non null bit on the right of x.
     * If there is no closest bit, it returns max(uint256)
     */
    function closestBitRight(uint256 x, uint8 bit) internal pure returns (uint256 id) {
        unchecked {
            uint256 shift = 255 - bit;
            x <<= shift;

            // can't overflow as it's non-zero and we shifted it by `_shift`
            return (x == 0) ? type(uint256).max : mostSignificantBit(x) - shift;
        }
    }

    /**
     * @dev Returns the index of the closest bit on the left of x that is non null
     * @param x The value as a uint256
     * @param bit The index of the bit to start searching at
     * @return id The index of the closest non null bit on the left of x.
     * If there is no closest bit, it returns max(uint256)
     */
    function closestBitLeft(uint256 x, uint8 bit) internal pure returns (uint256 id) {
        unchecked {
            x >>= bit;

            return (x == 0) ? type(uint256).max : leastSignificantBit(x) + bit;
        }
    }

    /**
     * @dev Returns the index of the most significant bit of x
     * This function returns 0 if x is 0
     * @param x The value as a uint256
     * @return msb The index of the most significant bit of x
     */
    function mostSignificantBit(uint256 x) internal pure returns (uint8 msb) {
        assembly {
            if gt(x, 0xffffffffffffffffffffffffffffffff) {
                x := shr(128, x)
                msb := 128
            }
            if gt(x, 0xffffffffffffffff) {
                x := shr(64, x)
                msb := add(msb, 64)
            }
            if gt(x, 0xffffffff) {
                x := shr(32, x)
                msb := add(msb, 32)
            }
            if gt(x, 0xffff) {
                x := shr(16, x)
                msb := add(msb, 16)
            }
            if gt(x, 0xff) {
                x := shr(8, x)
                msb := add(msb, 8)
            }
            if gt(x, 0xf) {
                x := shr(4, x)
                msb := add(msb, 4)
            }
            if gt(x, 0x3) {
                x := shr(2, x)
                msb := add(msb, 2)
            }
            if gt(x, 0x1) { msb := add(msb, 1) }
        }
    }

    /**
     * @dev Returns the index of the least significant bit of x
     * This function returns 255 if x is 0
     * @param x The value as a uint256
     * @return lsb The index of the least significant bit of x
     */
    function leastSignificantBit(uint256 x) internal pure returns (uint8 lsb) {
        assembly {
            let sx := shl(128, x)
            if iszero(iszero(sx)) {
                lsb := 128
                x := sx
            }
            sx := shl(64, x)
            if iszero(iszero(sx)) {
                x := sx
                lsb := add(lsb, 64)
            }
            sx := shl(32, x)
            if iszero(iszero(sx)) {
                x := sx
                lsb := add(lsb, 32)
            }
            sx := shl(16, x)
            if iszero(iszero(sx)) {
                x := sx
                lsb := add(lsb, 16)
            }
            sx := shl(8, x)
            if iszero(iszero(sx)) {
                x := sx
                lsb := add(lsb, 8)
            }
            sx := shl(4, x)
            if iszero(iszero(sx)) {
                x := sx
                lsb := add(lsb, 4)
            }
            sx := shl(2, x)
            if iszero(iszero(sx)) {
                x := sx
                lsb := add(lsb, 2)
            }
            if iszero(iszero(shl(1, x))) { lsb := add(lsb, 1) }

            lsb := sub(255, lsb)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Liquidity Book Encoded Library
 * @author Trader Joe
 * @notice Helper contract used for decoding bytes32 sample
 */
library Encoded {
    uint256 internal constant MASK_UINT1 = 0x1;
    uint256 internal constant MASK_UINT8 = 0xff;
    uint256 internal constant MASK_UINT12 = 0xfff;
    uint256 internal constant MASK_UINT14 = 0x3fff;
    uint256 internal constant MASK_UINT16 = 0xffff;
    uint256 internal constant MASK_UINT20 = 0xfffff;
    uint256 internal constant MASK_UINT24 = 0xffffff;
    uint256 internal constant MASK_UINT40 = 0xffffffffff;
    uint256 internal constant MASK_UINT64 = 0xffffffffffffffff;
    uint256 internal constant MASK_UINT128 = 0xffffffffffffffffffffffffffffffff;

    /**
     * @notice Internal function to set a value in an encoded bytes32 using a mask and offset
     * @dev This function can overflow
     * @param encoded The previous encoded value
     * @param value The value to encode
     * @param mask The mask
     * @param offset The offset
     * @return newEncoded The new encoded value
     */
    function set(bytes32 encoded, uint256 value, uint256 mask, uint256 offset)
        internal
        pure
        returns (bytes32 newEncoded)
    {
        assembly {
            newEncoded := and(encoded, not(shl(offset, mask)))
            newEncoded := or(newEncoded, shl(offset, and(value, mask)))
        }
    }

    /**
     * @notice Internal function to set a bool in an encoded bytes32 using an offset
     * @dev This function can overflow
     * @param encoded The previous encoded value
     * @param boolean The bool to encode
     * @param offset The offset
     * @return newEncoded The new encoded value
     */
    function setBool(bytes32 encoded, bool boolean, uint256 offset) internal pure returns (bytes32 newEncoded) {
        return set(encoded, boolean ? 1 : 0, MASK_UINT1, offset);
    }

    /**
     * @notice Internal function to decode a bytes32 sample using a mask and offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param mask The mask
     * @param offset The offset
     * @return value The decoded value
     */
    function decode(bytes32 encoded, uint256 mask, uint256 offset) internal pure returns (uint256 value) {
        assembly {
            value := and(shr(offset, encoded), mask)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a bool using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return boolean The decoded value as a bool
     */
    function decodeBool(bytes32 encoded, uint256 offset) internal pure returns (bool boolean) {
        assembly {
            boolean := and(shr(offset, encoded), MASK_UINT1)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint8 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value
     */
    function decodeUint8(bytes32 encoded, uint256 offset) internal pure returns (uint8 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT8)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint12 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value as a uint16, since uint12 is not supported
     */
    function decodeUint12(bytes32 encoded, uint256 offset) internal pure returns (uint16 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT12)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint14 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value as a uint16, since uint14 is not supported
     */
    function decodeUint14(bytes32 encoded, uint256 offset) internal pure returns (uint16 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT14)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint16 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value
     */
    function decodeUint16(bytes32 encoded, uint256 offset) internal pure returns (uint16 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT16)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint20 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value as a uint24, since uint20 is not supported
     */
    function decodeUint20(bytes32 encoded, uint256 offset) internal pure returns (uint24 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT20)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint24 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value
     */
    function decodeUint24(bytes32 encoded, uint256 offset) internal pure returns (uint24 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT24)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint40 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value
     */
    function decodeUint40(bytes32 encoded, uint256 offset) internal pure returns (uint40 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT40)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint64 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value
     */
    function decodeUint64(bytes32 encoded, uint256 offset) internal pure returns (uint64 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT64)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint128 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value
     */
    function decodeUint128(bytes32 encoded, uint256 offset) internal pure returns (uint128 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT128)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {PackedUint128Math} from "./PackedUint128Math.sol";
import {Encoded} from "./Encoded.sol";

/**
 * @title Liquidity Book Liquidity Configurations Library
 * @author Trader Joe
 * @notice This library contains functions to encode and decode the config of a pool and interact with the encoded bytes32.
 */
library LiquidityConfigurations {
    using PackedUint128Math for bytes32;
    using PackedUint128Math for uint128;
    using Encoded for bytes32;

    error LiquidityConfigurations__InvalidConfig();

    uint256 private constant OFFSET_ID = 0;
    uint256 private constant OFFSET_DISTRIBUTION_Y = 24;
    uint256 private constant OFFSET_DISTRIBUTION_X = 88;

    uint256 private constant PRECISION = 1e18;

    /**
     * @dev Encode the distributionX, distributionY and id into a single bytes32
     * @param distributionX The distribution of the first token
     * @param distributionY The distribution of the second token
     * @param id The id of the pool
     * @return config The encoded config as follows:
     * [0 - 24[: id
     * [24 - 88[: distributionY
     * [88 - 152[: distributionX
     * [152 - 256[: empty
     */
    function encodeParams(uint64 distributionX, uint64 distributionY, uint24 id)
        internal
        pure
        returns (bytes32 config)
    {
        config = config.set(distributionX, Encoded.MASK_UINT64, OFFSET_DISTRIBUTION_X);
        config = config.set(distributionY, Encoded.MASK_UINT64, OFFSET_DISTRIBUTION_Y);
        config = config.set(id, Encoded.MASK_UINT24, OFFSET_ID);
    }

    /**
     * @dev Decode the distributionX, distributionY and id from a single bytes32
     * @param config The encoded config as follows:
     * [0 - 24[: id
     * [24 - 88[: distributionY
     * [88 - 152[: distributionX
     * [152 - 256[: empty
     * @return distributionX The distribution of the first token
     * @return distributionY The distribution of the second token
     * @return id The id of the bin to add the liquidity to
     */
    function decodeParams(bytes32 config)
        internal
        pure
        returns (uint64 distributionX, uint64 distributionY, uint24 id)
    {
        distributionX = config.decodeUint64(OFFSET_DISTRIBUTION_X);
        distributionY = config.decodeUint64(OFFSET_DISTRIBUTION_Y);
        id = config.decodeUint24(OFFSET_ID);

        if (uint256(config) > type(uint152).max || distributionX > PRECISION || distributionY > PRECISION) {
            revert LiquidityConfigurations__InvalidConfig();
        }
    }

    /**
     * @dev Get the amounts and id from a config and amountsIn
     * @param config The encoded config as follows:
     * [0 - 24[: id
     * [24 - 88[: distributionY
     * [88 - 152[: distributionX
     * [152 - 256[: empty
     * @param amountsIn The amounts to distribute as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @return amounts The distributed amounts as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @return id The id of the bin to add the liquidity to
     */
    function getAmountsAndId(bytes32 config, bytes32 amountsIn) internal pure returns (bytes32, uint24) {
        (uint64 distributionX, uint64 distributionY, uint24 id) = decodeParams(config);

        (uint128 x1, uint128 x2) = amountsIn.decode();

        assembly {
            x1 := div(mul(x1, distributionX), PRECISION)
            x2 := div(mul(x2, distributionY), PRECISION)
        }

        return (x1.encode(x2), id);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {Constants} from "../Constants.sol";

/**
 * @title Liquidity Book Packed Uint128 Math Library
 * @author Trader Joe
 * @notice This library contains functions to encode and decode two uint128 into a single bytes32
 * and interact with the encoded bytes32.
 */
library PackedUint128Math {
    error PackedUint128Math__AddOverflow();
    error PackedUint128Math__SubUnderflow();
    error PackedUint128Math__MultiplierTooLarge();

    uint256 private constant OFFSET = 128;
    uint256 private constant MASK_128 = 0xffffffffffffffffffffffffffffffff;
    uint256 private constant MASK_128_PLUS_ONE = MASK_128 + 1;

    /**
     * @dev Encodes two uint128 into a single bytes32
     * @param x1 The first uint128
     * @param x2 The second uint128
     * @return z The encoded bytes32 as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     */
    function encode(uint128 x1, uint128 x2) internal pure returns (bytes32 z) {
        assembly {
            z := or(and(x1, MASK_128), shl(OFFSET, x2))
        }
    }

    /**
     * @dev Encodes a uint128 into a single bytes32 as the first uint128
     * @param x1 The uint128
     * @return z The encoded bytes32 as follows:
     * [0 - 128[: x1
     * [128 - 256[: empty
     */
    function encodeFirst(uint128 x1) internal pure returns (bytes32 z) {
        assembly {
            z := and(x1, MASK_128)
        }
    }

    /**
     * @dev Encodes a uint128 into a single bytes32 as the second uint128
     * @param x2 The uint128
     * @return z The encoded bytes32 as follows:
     * [0 - 128[: empty
     * [128 - 256[: x2
     */
    function encodeSecond(uint128 x2) internal pure returns (bytes32 z) {
        assembly {
            z := shl(OFFSET, x2)
        }
    }

    /**
     * @dev Encodes a uint128 into a single bytes32 as the first or second uint128
     * @param x The uint128
     * @param first Whether to encode as the first or second uint128
     * @return z The encoded bytes32 as follows:
     * if first:
     * [0 - 128[: x
     * [128 - 256[: empty
     * else:
     * [0 - 128[: empty
     * [128 - 256[: x
     */
    function encode(uint128 x, bool first) internal pure returns (bytes32 z) {
        return first ? encodeFirst(x) : encodeSecond(x);
    }

    /**
     * @dev Decodes a bytes32 into two uint128
     * @param z The encoded bytes32 as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @return x1 The first uint128
     * @return x2 The second uint128
     */
    function decode(bytes32 z) internal pure returns (uint128 x1, uint128 x2) {
        assembly {
            x1 := and(z, MASK_128)
            x2 := shr(OFFSET, z)
        }
    }

    /**
     * @dev Decodes a bytes32 into a uint128 as the first uint128
     * @param z The encoded bytes32 as follows:
     * [0 - 128[: x
     * [128 - 256[: any
     * @return x The first uint128
     */
    function decodeX(bytes32 z) internal pure returns (uint128 x) {
        assembly {
            x := and(z, MASK_128)
        }
    }

    /**
     * @dev Decodes a bytes32 into a uint128 as the second uint128
     * @param z The encoded bytes32 as follows:
     * [0 - 128[: any
     * [128 - 256[: y
     * @return y The second uint128
     */
    function decodeY(bytes32 z) internal pure returns (uint128 y) {
        assembly {
            y := shr(OFFSET, z)
        }
    }

    /**
     * @dev Decodes a bytes32 into a uint128 as the first or second uint128
     * @param z The encoded bytes32 as follows:
     * if first:
     * [0 - 128[: x1
     * [128 - 256[: empty
     * else:
     * [0 - 128[: empty
     * [128 - 256[: x2
     * @param first Whether to decode as the first or second uint128
     * @return x The decoded uint128
     */
    function decode(bytes32 z, bool first) internal pure returns (uint128 x) {
        return first ? decodeX(z) : decodeY(z);
    }

    /**
     * @dev Adds two encoded bytes32, reverting on overflow on any of the uint128
     * @param x The first bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y The second bytes32 encoded as follows:
     * [0 - 128[: y1
     * [128 - 256[: y2
     * @return z The sum of x and y encoded as follows:
     * [0 - 128[: x1 + y1
     * [128 - 256[: x2 + y2
     */
    function add(bytes32 x, bytes32 y) internal pure returns (bytes32 z) {
        assembly {
            z := add(x, y)
        }

        if (z < x || uint128(uint256(z)) < uint128(uint256(x))) {
            revert PackedUint128Math__AddOverflow();
        }
    }

    /**
     * @dev Adds an encoded bytes32 and two uint128, reverting on overflow on any of the uint128
     * @param x The bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y1 The first uint128
     * @param y2 The second uint128
     * @return z The sum of x and y encoded as follows:
     * [0 - 128[: x1 + y1
     * [128 - 256[: x2 + y2
     */
    function add(bytes32 x, uint128 y1, uint128 y2) internal pure returns (bytes32) {
        return add(x, encode(y1, y2));
    }

    /**
     * @dev Subtracts two encoded bytes32, reverting on underflow on any of the uint128
     * @param x The first bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y The second bytes32 encoded as follows:
     * [0 - 128[: y1
     * [128 - 256[: y2
     * @return z The difference of x and y encoded as follows:
     * [0 - 128[: x1 - y1
     * [128 - 256[: x2 - y2
     */
    function sub(bytes32 x, bytes32 y) internal pure returns (bytes32 z) {
        assembly {
            z := sub(x, y)
        }

        if (z > x || uint128(uint256(z)) > uint128(uint256(x))) {
            revert PackedUint128Math__SubUnderflow();
        }
    }

    /**
     * @dev Subtracts an encoded bytes32 and two uint128, reverting on underflow on any of the uint128
     * @param x The bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y1 The first uint128
     * @param y2 The second uint128
     * @return z The difference of x and y encoded as follows:
     * [0 - 128[: x1 - y1
     * [128 - 256[: x2 - y2
     */
    function sub(bytes32 x, uint128 y1, uint128 y2) internal pure returns (bytes32) {
        return sub(x, encode(y1, y2));
    }

    /**
     * @dev Returns whether any of the uint128 of x is strictly greater than the corresponding uint128 of y
     * @param x The first bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y The second bytes32 encoded as follows:
     * [0 - 128[: y1
     * [128 - 256[: y2
     * @return x1 < y1 || x2 < y2
     */
    function lt(bytes32 x, bytes32 y) internal pure returns (bool) {
        (uint128 x1, uint128 x2) = decode(x);
        (uint128 y1, uint128 y2) = decode(y);

        return x1 < y1 || x2 < y2;
    }

    /**
     * @dev Returns whether any of the uint128 of x is strictly greater than the corresponding uint128 of y
     * @param x The first bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y The second bytes32 encoded as follows:
     * [0 - 128[: y1
     * [128 - 256[: y2
     * @return x1 < y1 || x2 < y2
     */
    function gt(bytes32 x, bytes32 y) internal pure returns (bool) {
        (uint128 x1, uint128 x2) = decode(x);
        (uint128 y1, uint128 y2) = decode(y);

        return x1 > y1 || x2 > y2;
    }

    /**
     * @dev Multiplies an encoded bytes32 by a uint128 then divides the result by 10_000, rounding down
     * The result can't overflow as the multiplier needs to be smaller or equal to 10_000
     * @param x The bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param multiplier The uint128 to multiply by (must be smaller or equal to 10_000)
     * @return z The product of x and multiplier encoded as follows:
     * [0 - 128[: floor((x1 * multiplier) / 10_000)
     * [128 - 256[: floor((x2 * multiplier) / 10_000)
     */
    function scalarMulDivBasisPointRoundDown(bytes32 x, uint128 multiplier) internal pure returns (bytes32 z) {
        if (multiplier == 0) return 0;

        uint256 BASIS_POINT_MAX = Constants.BASIS_POINT_MAX;
        if (multiplier > BASIS_POINT_MAX) revert PackedUint128Math__MultiplierTooLarge();

        (uint128 x1, uint128 x2) = decode(x);

        assembly {
            x1 := div(mul(x1, multiplier), BASIS_POINT_MAX)
            x2 := div(mul(x2, multiplier), BASIS_POINT_MAX)
        }

        return encode(x1, x2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Liquidity Book Safe Cast Library
 * @author Trader Joe
 * @notice This library contains functions to safely cast uint256 to different uint types.
 */
library SafeCast {
    error SafeCast__Exceeds248Bits();
    error SafeCast__Exceeds240Bits();
    error SafeCast__Exceeds232Bits();
    error SafeCast__Exceeds224Bits();
    error SafeCast__Exceeds216Bits();
    error SafeCast__Exceeds208Bits();
    error SafeCast__Exceeds200Bits();
    error SafeCast__Exceeds192Bits();
    error SafeCast__Exceeds184Bits();
    error SafeCast__Exceeds176Bits();
    error SafeCast__Exceeds168Bits();
    error SafeCast__Exceeds160Bits();
    error SafeCast__Exceeds152Bits();
    error SafeCast__Exceeds144Bits();
    error SafeCast__Exceeds136Bits();
    error SafeCast__Exceeds128Bits();
    error SafeCast__Exceeds120Bits();
    error SafeCast__Exceeds112Bits();
    error SafeCast__Exceeds104Bits();
    error SafeCast__Exceeds96Bits();
    error SafeCast__Exceeds88Bits();
    error SafeCast__Exceeds80Bits();
    error SafeCast__Exceeds72Bits();
    error SafeCast__Exceeds64Bits();
    error SafeCast__Exceeds56Bits();
    error SafeCast__Exceeds48Bits();
    error SafeCast__Exceeds40Bits();
    error SafeCast__Exceeds32Bits();
    error SafeCast__Exceeds24Bits();
    error SafeCast__Exceeds16Bits();
    error SafeCast__Exceeds8Bits();

    /**
     * @dev Returns x on uint248 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint248
     */
    function safe248(uint256 x) internal pure returns (uint248 y) {
        if ((y = uint248(x)) != x) revert SafeCast__Exceeds248Bits();
    }

    /**
     * @dev Returns x on uint240 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint240
     */
    function safe240(uint256 x) internal pure returns (uint240 y) {
        if ((y = uint240(x)) != x) revert SafeCast__Exceeds240Bits();
    }

    /**
     * @dev Returns x on uint232 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint232
     */
    function safe232(uint256 x) internal pure returns (uint232 y) {
        if ((y = uint232(x)) != x) revert SafeCast__Exceeds232Bits();
    }

    /**
     * @dev Returns x on uint224 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint224
     */
    function safe224(uint256 x) internal pure returns (uint224 y) {
        if ((y = uint224(x)) != x) revert SafeCast__Exceeds224Bits();
    }

    /**
     * @dev Returns x on uint216 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint216
     */
    function safe216(uint256 x) internal pure returns (uint216 y) {
        if ((y = uint216(x)) != x) revert SafeCast__Exceeds216Bits();
    }

    /**
     * @dev Returns x on uint208 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint208
     */
    function safe208(uint256 x) internal pure returns (uint208 y) {
        if ((y = uint208(x)) != x) revert SafeCast__Exceeds208Bits();
    }

    /**
     * @dev Returns x on uint200 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint200
     */
    function safe200(uint256 x) internal pure returns (uint200 y) {
        if ((y = uint200(x)) != x) revert SafeCast__Exceeds200Bits();
    }

    /**
     * @dev Returns x on uint192 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint192
     */
    function safe192(uint256 x) internal pure returns (uint192 y) {
        if ((y = uint192(x)) != x) revert SafeCast__Exceeds192Bits();
    }

    /**
     * @dev Returns x on uint184 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint184
     */
    function safe184(uint256 x) internal pure returns (uint184 y) {
        if ((y = uint184(x)) != x) revert SafeCast__Exceeds184Bits();
    }

    /**
     * @dev Returns x on uint176 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint176
     */
    function safe176(uint256 x) internal pure returns (uint176 y) {
        if ((y = uint176(x)) != x) revert SafeCast__Exceeds176Bits();
    }

    /**
     * @dev Returns x on uint168 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint168
     */
    function safe168(uint256 x) internal pure returns (uint168 y) {
        if ((y = uint168(x)) != x) revert SafeCast__Exceeds168Bits();
    }

    /**
     * @dev Returns x on uint160 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint160
     */
    function safe160(uint256 x) internal pure returns (uint160 y) {
        if ((y = uint160(x)) != x) revert SafeCast__Exceeds160Bits();
    }

    /**
     * @dev Returns x on uint152 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint152
     */
    function safe152(uint256 x) internal pure returns (uint152 y) {
        if ((y = uint152(x)) != x) revert SafeCast__Exceeds152Bits();
    }

    /**
     * @dev Returns x on uint144 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint144
     */
    function safe144(uint256 x) internal pure returns (uint144 y) {
        if ((y = uint144(x)) != x) revert SafeCast__Exceeds144Bits();
    }

    /**
     * @dev Returns x on uint136 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint136
     */
    function safe136(uint256 x) internal pure returns (uint136 y) {
        if ((y = uint136(x)) != x) revert SafeCast__Exceeds136Bits();
    }

    /**
     * @dev Returns x on uint128 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint128
     */
    function safe128(uint256 x) internal pure returns (uint128 y) {
        if ((y = uint128(x)) != x) revert SafeCast__Exceeds128Bits();
    }

    /**
     * @dev Returns x on uint120 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint120
     */
    function safe120(uint256 x) internal pure returns (uint120 y) {
        if ((y = uint120(x)) != x) revert SafeCast__Exceeds120Bits();
    }

    /**
     * @dev Returns x on uint112 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint112
     */
    function safe112(uint256 x) internal pure returns (uint112 y) {
        if ((y = uint112(x)) != x) revert SafeCast__Exceeds112Bits();
    }

    /**
     * @dev Returns x on uint104 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint104
     */
    function safe104(uint256 x) internal pure returns (uint104 y) {
        if ((y = uint104(x)) != x) revert SafeCast__Exceeds104Bits();
    }

    /**
     * @dev Returns x on uint96 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint96
     */
    function safe96(uint256 x) internal pure returns (uint96 y) {
        if ((y = uint96(x)) != x) revert SafeCast__Exceeds96Bits();
    }

    /**
     * @dev Returns x on uint88 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint88
     */
    function safe88(uint256 x) internal pure returns (uint88 y) {
        if ((y = uint88(x)) != x) revert SafeCast__Exceeds88Bits();
    }

    /**
     * @dev Returns x on uint80 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint80
     */
    function safe80(uint256 x) internal pure returns (uint80 y) {
        if ((y = uint80(x)) != x) revert SafeCast__Exceeds80Bits();
    }

    /**
     * @dev Returns x on uint72 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint72
     */
    function safe72(uint256 x) internal pure returns (uint72 y) {
        if ((y = uint72(x)) != x) revert SafeCast__Exceeds72Bits();
    }

    /**
     * @dev Returns x on uint64 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint64
     */
    function safe64(uint256 x) internal pure returns (uint64 y) {
        if ((y = uint64(x)) != x) revert SafeCast__Exceeds64Bits();
    }

    /**
     * @dev Returns x on uint56 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint56
     */
    function safe56(uint256 x) internal pure returns (uint56 y) {
        if ((y = uint56(x)) != x) revert SafeCast__Exceeds56Bits();
    }

    /**
     * @dev Returns x on uint48 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint48
     */
    function safe48(uint256 x) internal pure returns (uint48 y) {
        if ((y = uint48(x)) != x) revert SafeCast__Exceeds48Bits();
    }

    /**
     * @dev Returns x on uint40 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint40
     */
    function safe40(uint256 x) internal pure returns (uint40 y) {
        if ((y = uint40(x)) != x) revert SafeCast__Exceeds40Bits();
    }

    /**
     * @dev Returns x on uint32 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint32
     */
    function safe32(uint256 x) internal pure returns (uint32 y) {
        if ((y = uint32(x)) != x) revert SafeCast__Exceeds32Bits();
    }

    /**
     * @dev Returns x on uint24 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint24
     */
    function safe24(uint256 x) internal pure returns (uint24 y) {
        if ((y = uint24(x)) != x) revert SafeCast__Exceeds24Bits();
    }

    /**
     * @dev Returns x on uint16 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint16
     */
    function safe16(uint256 x) internal pure returns (uint16 y) {
        if ((y = uint16(x)) != x) revert SafeCast__Exceeds16Bits();
    }

    /**
     * @dev Returns x on uint8 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint8
     */
    function safe8(uint256 x) internal pure returns (uint8 y) {
        if ((y = uint8(x)) != x) revert SafeCast__Exceeds8Bits();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {Encoded} from "./Encoded.sol";

/**
 * @title Liquidity Book Sample Math Library
 * @author Trader Joe
 * @notice This library contains functions to encode and decode a sample into a single bytes32
 * and interact with the encoded bytes32
 * The sample is encoded as follows:
 * 0 - 16: oracle length (16 bits)
 * 16 - 80: cumulative id (64 bits)
 * 80 - 144: cumulative volatility accumulator (64 bits)
 * 144 - 208: cumulative bin crossed (64 bits)
 * 208 - 216: sample lifetime (8 bits)
 * 216 - 256: sample creation timestamp (40 bits)
 */
library SampleMath {
    using Encoded for bytes32;

    uint256 internal constant OFFSET_ORACLE_LENGTH = 0;
    uint256 internal constant OFFSET_CUMULATIVE_ID = 16;
    uint256 internal constant OFFSET_CUMULATIVE_VOLATILITY = 80;
    uint256 internal constant OFFSET_CUMULATIVE_BIN_CROSSED = 144;
    uint256 internal constant OFFSET_SAMPLE_LIFETIME = 208;
    uint256 internal constant OFFSET_SAMPLE_CREATION = 216;

    /**
     * @dev Encodes a sample
     * @param oracleLength The oracle length
     * @param cumulativeId The cumulative id
     * @param cumulativeVolatility The cumulative volatility
     * @param cumulativeBinCrossed The cumulative bin crossed
     * @param sampleLifetime The sample lifetime
     * @param createdAt The sample creation timestamp
     * @return sample The encoded sample
     */
    function encode(
        uint16 oracleLength,
        uint64 cumulativeId,
        uint64 cumulativeVolatility,
        uint64 cumulativeBinCrossed,
        uint8 sampleLifetime,
        uint40 createdAt
    ) internal pure returns (bytes32 sample) {
        sample = sample.set(oracleLength, Encoded.MASK_UINT16, OFFSET_ORACLE_LENGTH);
        sample = sample.set(cumulativeId, Encoded.MASK_UINT64, OFFSET_CUMULATIVE_ID);
        sample = sample.set(cumulativeVolatility, Encoded.MASK_UINT64, OFFSET_CUMULATIVE_VOLATILITY);
        sample = sample.set(cumulativeBinCrossed, Encoded.MASK_UINT64, OFFSET_CUMULATIVE_BIN_CROSSED);
        sample = sample.set(sampleLifetime, Encoded.MASK_UINT8, OFFSET_SAMPLE_LIFETIME);
        sample = sample.set(createdAt, Encoded.MASK_UINT40, OFFSET_SAMPLE_CREATION);
    }

    /**
     * @dev Gets the oracle length from an encoded sample
     * @param sample The encoded sample as follows:
     * [0 - 16[: oracle length (16 bits)
     * [16 - 256[: any (240 bits)
     * @return length The oracle length
     */
    function getOracleLength(bytes32 sample) internal pure returns (uint16 length) {
        return sample.decodeUint16(0);
    }

    /**
     * @dev Gets the cumulative id from an encoded sample
     * @param sample The encoded sample as follows:
     * [0 - 16[: any (16 bits)
     * [16 - 80[: cumulative id (64 bits)
     * [80 - 256[: any (176 bits)
     * @return id The cumulative id
     */
    function getCumulativeId(bytes32 sample) internal pure returns (uint64 id) {
        return sample.decodeUint64(OFFSET_CUMULATIVE_ID);
    }

    /**
     * @dev Gets the cumulative volatility accumulator from an encoded sample
     * @param sample The encoded sample as follows:
     * [0 - 80[: any (80 bits)
     * [80 - 144[: cumulative volatility accumulator (64 bits)
     * [144 - 256[: any (112 bits)
     * @return volatilityAccumulator The cumulative volatility
     */
    function getCumulativeVolatility(bytes32 sample) internal pure returns (uint64 volatilityAccumulator) {
        return sample.decodeUint64(OFFSET_CUMULATIVE_VOLATILITY);
    }

    /**
     * @dev Gets the cumulative bin crossed from an encoded sample
     * @param sample The encoded sample as follows:
     * [0 - 144[: any (144 bits)
     * [144 - 208[: cumulative bin crossed (64 bits)
     * [208 - 256[: any (48 bits)
     * @return binCrossed The cumulative bin crossed
     */
    function getCumulativeBinCrossed(bytes32 sample) internal pure returns (uint64 binCrossed) {
        return sample.decodeUint64(OFFSET_CUMULATIVE_BIN_CROSSED);
    }

    /**
     * @dev Gets the sample lifetime from an encoded sample
     * @param sample The encoded sample as follows:
     * [0 - 208[: any (208 bits)
     * [208 - 216[: sample lifetime (8 bits)
     * [216 - 256[: any (40 bits)
     * @return lifetime The sample lifetime
     */
    function getSampleLifetime(bytes32 sample) internal pure returns (uint8 lifetime) {
        return sample.decodeUint8(OFFSET_SAMPLE_LIFETIME);
    }

    /**
     * @dev Gets the sample creation timestamp from an encoded sample
     * @param sample The encoded sample as follows:
     * [0 - 216[: any (216 bits)
     * [216 - 256[: sample creation timestamp (40 bits)
     * @return creation The sample creation timestamp
     */
    function getSampleCreation(bytes32 sample) internal pure returns (uint40 creation) {
        return sample.decodeUint40(OFFSET_SAMPLE_CREATION);
    }

    /**
     * @dev Gets the sample last update timestamp from an encoded sample
     * @param sample The encoded sample as follows:
     * [0 - 216[: any (216 bits)
     * [216 - 256[: sample creation timestamp (40 bits)
     * @return lastUpdate The sample last update timestamp
     */
    function getSampleLastUpdate(bytes32 sample) internal pure returns (uint40 lastUpdate) {
        lastUpdate = getSampleCreation(sample) + getSampleLifetime(sample);
    }

    /**
     * @dev Gets the weighted average of two samples and their respective weights
     * @param sample1 The first encoded sample
     * @param sample2 The second encoded sample
     * @param weight1 The weight of the first sample
     * @param weight2 The weight of the second sample
     * @return weightedAverageId The weighted average id
     * @return weightedAverageVolatility The weighted average volatility
     * @return weightedAverageBinCrossed The weighted average bin crossed
     */
    function getWeightedAverage(bytes32 sample1, bytes32 sample2, uint40 weight1, uint40 weight2)
        internal
        pure
        returns (uint64 weightedAverageId, uint64 weightedAverageVolatility, uint64 weightedAverageBinCrossed)
    {
        uint256 cId1 = getCumulativeId(sample1);
        uint256 cVolatility1 = getCumulativeVolatility(sample1);
        uint256 cBinCrossed1 = getCumulativeBinCrossed(sample1);

        if (weight2 == 0) return (uint64(cId1), uint64(cVolatility1), uint64(cBinCrossed1));

        uint256 cId2 = getCumulativeId(sample2);
        uint256 cVolatility2 = getCumulativeVolatility(sample2);
        uint256 cBinCrossed2 = getCumulativeBinCrossed(sample2);

        if (weight1 == 0) return (uint64(cId2), uint64(cVolatility2), uint64(cBinCrossed2));

        uint256 totalWeight = uint256(weight1) + weight2;

        unchecked {
            weightedAverageId = uint64((cId1 * weight1 + cId2 * weight2) / totalWeight);
            weightedAverageVolatility = uint64((cVolatility1 * weight1 + cVolatility2 * weight2) / totalWeight);
            weightedAverageBinCrossed = uint64((cBinCrossed1 * weight1 + cBinCrossed2 * weight2) / totalWeight);
        }
    }

    /**
     * @dev Updates a sample with the given values
     * @param sample The encoded sample
     * @param deltaTime The time elapsed since the last update
     * @param activeId The active id
     * @param volatilityAccumulator The volatility accumulator
     * @param binCrossed The bin crossed
     * @return cumulativeId The cumulative id
     * @return cumulativeVolatility The cumulative volatility
     * @return cumulativeBinCrossed The cumulative bin crossed
     */
    function update(bytes32 sample, uint40 deltaTime, uint24 activeId, uint24 volatilityAccumulator, uint24 binCrossed)
        internal
        pure
        returns (uint64 cumulativeId, uint64 cumulativeVolatility, uint64 cumulativeBinCrossed)
    {
        unchecked {
            cumulativeId = uint64(activeId) * deltaTime;
            cumulativeVolatility = uint64(volatilityAccumulator) * deltaTime;
            cumulativeBinCrossed = uint64(binCrossed) * deltaTime;
        }

        cumulativeId += getCumulativeId(sample);
        cumulativeVolatility += getCumulativeVolatility(sample);
        cumulativeBinCrossed += getCumulativeBinCrossed(sample);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {BitMath} from "./BitMath.sol";

/**
 * @title Liquidity Book Tree Math Library
 * @author Trader Joe
 * @notice This library contains functions to interact with a tree of TreeUint24.
 */
library TreeMath {
    using BitMath for uint256;

    struct TreeUint24 {
        bytes32 level0;
        mapping(bytes32 => bytes32) level1;
        mapping(bytes32 => bytes32) level2;
    }

    /**
     * @dev Returns true if the tree contains the id
     * @param tree The tree
     * @param id The id
     * @return True if the tree contains the id
     */
    function contains(TreeUint24 storage tree, uint24 id) internal view returns (bool) {
        bytes32 leaf2 = bytes32(uint256(id) >> 8);

        return tree.level2[leaf2] & bytes32(1 << (id & type(uint8).max)) != 0;
    }

    /**
     * @dev Adds the id to the tree and returns true if the id was not already in the tree
     * It will also propagate the change to the parent levels.
     * @param tree The tree
     * @param id The id
     * @return True if the id was not already in the tree
     */
    function add(TreeUint24 storage tree, uint24 id) internal returns (bool) {
        bytes32 key2 = bytes32(uint256(id) >> 8);

        bytes32 leaves = tree.level2[key2];
        bytes32 newLeaves = leaves | bytes32(1 << (id & type(uint8).max));

        if (leaves != newLeaves) {
            tree.level2[key2] = newLeaves;

            if (leaves == 0) {
                bytes32 key1 = key2 >> 8;
                leaves = tree.level1[key1];

                tree.level1[key1] = leaves | bytes32(1 << (uint256(key2) & type(uint8).max));

                if (leaves == 0) tree.level0 |= bytes32(1 << (uint256(key1) & type(uint8).max));
            }

            return true;
        }

        return false;
    }

    /**
     * @dev Removes the id from the tree and returns true if the id was in the tree.
     * It will also propagate the change to the parent levels.
     * @param tree The tree
     * @param id The id
     * @return True if the id was in the tree
     */
    function remove(TreeUint24 storage tree, uint24 id) internal returns (bool) {
        bytes32 key2 = bytes32(uint256(id) >> 8);

        bytes32 leaves = tree.level2[key2];
        bytes32 newLeaves = leaves & ~bytes32(1 << (id & type(uint8).max));

        if (leaves != newLeaves) {
            tree.level2[key2] = newLeaves;

            if (newLeaves == 0) {
                bytes32 key1 = key2 >> 8;
                leaves = tree.level1[key1];

                tree.level1[key1] = leaves & ~bytes32(1 << (uint256(key2) & type(uint8).max));

                if (leaves == 0) tree.level0 &= ~bytes32(1 << (uint256(key1) & type(uint8).max));
            }

            return true;
        }

        return false;
    }

    /**
     * @dev Returns the first id in the tree that is lower than or equal to the given id.
     * It will return type(uint24).max if there is no such id.
     * @param tree The tree
     * @param id The id
     * @return The first id in the tree that is lower than or equal to the given id
     */
    function findFirstRight(TreeUint24 storage tree, uint24 id) internal view returns (uint24) {
        bytes32 leaves;

        bytes32 key2 = bytes32(uint256(id) >> 8);
        uint8 bit = uint8(id & type(uint8).max);

        if (bit != 0) {
            leaves = tree.level2[key2];
            uint256 closestBit = _closestBitRight(leaves, bit);

            if (closestBit != type(uint256).max) return uint24(uint256(key2) << 8 | closestBit);
        }

        bytes32 key1 = key2 >> 8;
        bit = uint8(uint256(key2) & type(uint8).max);

        if (bit != 0) {
            leaves = tree.level1[key1];
            uint256 closestBit = _closestBitRight(leaves, bit);

            if (closestBit != type(uint256).max) {
                key2 = bytes32(uint256(key1) << 8 | closestBit);
                leaves = tree.level2[key2];

                return uint24(uint256(key2) << 8 | uint256(leaves).mostSignificantBit());
            }
        }

        bit = uint8(uint256(key1) & type(uint8).max);

        if (bit != 0) {
            leaves = tree.level0;
            uint256 closestBit = _closestBitRight(leaves, bit);

            if (closestBit != type(uint256).max) {
                key1 = bytes32(closestBit);
                leaves = tree.level1[key1];

                key2 = bytes32(uint256(key1) << 8 | uint256(leaves).mostSignificantBit());
                leaves = tree.level2[key2];

                return uint24(uint256(key2) << 8 | uint256(leaves).mostSignificantBit());
            }
        }

        return type(uint24).max;
    }

    /**
     * @dev Returns the first id in the tree that is higher than or equal to the given id.
     * It will return 0 if there is no such id.
     * @param tree The tree
     * @param id The id
     * @return The first id in the tree that is higher than or equal to the given id
     */
    function findFirstLeft(TreeUint24 storage tree, uint24 id) internal view returns (uint24) {
        bytes32 leaves;

        bytes32 key2 = bytes32(uint256(id) >> 8);
        uint8 bit = uint8(id & type(uint8).max);

        if (bit != type(uint8).max) {
            leaves = tree.level2[key2];
            uint256 closestBit = _closestBitLeft(leaves, bit);

            if (closestBit != type(uint256).max) return uint24(uint256(key2) << 8 | closestBit);
        }

        bytes32 key1 = key2 >> 8;
        bit = uint8(uint256(key2) & type(uint8).max);

        if (bit != type(uint8).max) {
            leaves = tree.level1[key1];
            uint256 closestBit = _closestBitLeft(leaves, bit);

            if (closestBit != type(uint256).max) {
                key2 = bytes32(uint256(key1) << 8 | closestBit);
                leaves = tree.level2[key2];

                return uint24(uint256(key2) << 8 | uint256(leaves).leastSignificantBit());
            }
        }

        bit = uint8(uint256(key1) & type(uint8).max);

        if (bit != type(uint8).max) {
            leaves = tree.level0;
            uint256 closestBit = _closestBitLeft(leaves, bit);

            if (closestBit != type(uint256).max) {
                key1 = bytes32(closestBit);
                leaves = tree.level1[key1];

                key2 = bytes32(uint256(key1) << 8 | uint256(leaves).leastSignificantBit());
                leaves = tree.level2[key2];

                return uint24(uint256(key2) << 8 | uint256(leaves).leastSignificantBit());
            }
        }

        return 0;
    }

    /**
     * @dev Returns the first bit in the given leaves that is strictly lower than the given bit.
     * It will return type(uint256).max if there is no such bit.
     * @param leaves The leaves
     * @param bit The bit
     * @return The first bit in the given leaves that is strictly lower than the given bit
     */
    function _closestBitRight(bytes32 leaves, uint8 bit) private pure returns (uint256) {
        unchecked {
            return uint256(leaves).closestBitRight(bit - 1);
        }
    }

    /**
     * @dev Returns the first bit in the given leaves that is strictly higher than the given bit.
     * It will return type(uint256).max if there is no such bit.
     * @param leaves The leaves
     * @param bit The bit
     * @return The first bit in the given leaves that is strictly higher than the given bit
     */
    function _closestBitLeft(bytes32 leaves, uint8 bit) private pure returns (uint256) {
        unchecked {
            return uint256(leaves).closestBitLeft(bit + 1);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {Constants} from "../Constants.sol";
import {BitMath} from "./BitMath.sol";

/**
 * @title Liquidity Book Uint128x128 Math Library
 * @author Trader Joe
 * @notice Helper contract used for power and log calculations
 */
library Uint128x128Math {
    using BitMath for uint256;

    error Uint128x128Math__LogUnderflow();
    error Uint128x128Math__PowUnderflow(uint256 x, int256 y);

    uint256 constant LOG_SCALE_OFFSET = 127;
    uint256 constant LOG_SCALE = 1 << LOG_SCALE_OFFSET;
    uint256 constant LOG_SCALE_SQUARED = LOG_SCALE * LOG_SCALE;

    /**
     * @notice Calculates the binary logarithm of x.
     * @dev Based on the iterative approximation algorithm.
     * https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
     * Requirements:
     * - x must be greater than zero.
     * Caveats:
     * - The results are not perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation
     * Also because x is converted to an unsigned 129.127-binary fixed-point number during the operation to optimize the multiplication
     * @param x The unsigned 128.128-binary fixed-point number for which to calculate the binary logarithm.
     * @return result The binary logarithm as a signed 128.128-binary fixed-point number.
     */
    function log2(uint256 x) internal pure returns (int256 result) {
        // Convert x to a unsigned 129.127-binary fixed-point number to optimize the multiplication.
        // If we use an offset of 128 bits, y would need 129 bits and y**2 would would overflow and we would have to
        // use mulDiv, by reducing x to 129.127-binary fixed-point number we assert that y will use 128 bits, and we
        // can use the regular multiplication

        if (x == 1) return -128;
        if (x == 0) revert Uint128x128Math__LogUnderflow();

        x >>= 1;

        unchecked {
            // This works because log2(x) = -log2(1/x).
            int256 sign;
            if (x >= LOG_SCALE) {
                sign = 1;
            } else {
                sign = -1;
                // Do the fixed-point inversion inline to save gas
                x = LOG_SCALE_SQUARED / x;
            }

            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = (x >> LOG_SCALE_OFFSET).mostSignificantBit();

            // The integer part of the logarithm as a signed 129.127-binary fixed-point number. The operation can't overflow
            // because n is maximum 255, LOG_SCALE_OFFSET is 127 bits and sign is either 1 or -1.
            result = int256(n) << LOG_SCALE_OFFSET;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y != LOG_SCALE) {
                // Calculate the fractional part via the iterative approximation.
                // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
                for (int256 delta = int256(1 << (LOG_SCALE_OFFSET - 1)); delta > 0; delta >>= 1) {
                    y = (y * y) >> LOG_SCALE_OFFSET;

                    // Is y^2 > 2 and so in the range [2,4)?
                    if (y >= 1 << (LOG_SCALE_OFFSET + 1)) {
                        // Add the 2^(-m) factor to the logarithm.
                        result += delta;

                        // Corresponds to z/2 on Wikipedia.
                        y >>= 1;
                    }
                }
            }
            // Convert x back to unsigned 128.128-binary fixed-point number
            result = (result * sign) << 1;
        }
    }

    /**
     * @notice Returns the value of x^y. It calculates `1 / x^abs(y)` if x is bigger than 2^128.
     * At the end of the operations, we invert the result if needed.
     * @param x The unsigned 128.128-binary fixed-point number for which to calculate the power
     * @param y A relative number without any decimals, needs to be between ]2^21; 2^21[
     */
    function pow(uint256 x, int256 y) internal pure returns (uint256 result) {
        bool invert;
        uint256 absY;

        if (y == 0) return Constants.SCALE;

        assembly {
            absY := y
            if slt(absY, 0) {
                absY := sub(0, absY)
                invert := iszero(invert)
            }
        }

        if (absY < 0x100000) {
            result = Constants.SCALE;
            assembly {
                let squared := x
                if gt(x, 0xffffffffffffffffffffffffffffffff) {
                    squared := div(not(0), squared)
                    invert := iszero(invert)
                }

                if and(absY, 0x1) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x2) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x4) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x8) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x10) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x20) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x40) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x80) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x100) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x200) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x400) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x800) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x1000) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x2000) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x4000) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x8000) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x10000) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x20000) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x40000) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x80000) { result := shr(128, mul(result, squared)) }
            }
        }

        // revert if y is too big or if x^y underflowed
        if (result == 0) revert Uint128x128Math__PowUnderflow(x, y);

        return invert ? type(uint256).max / result : result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Liquidity Book Uint256x256 Math Library
 * @author Trader Joe
 * @notice Helper contract used for full precision calculations
 */
library Uint256x256Math {
    error Uint256x256Math__MulShiftOverflow();
    error Uint256x256Math__MulDivOverflow();

    /**
     * @notice Calculates floor(x*y/denominator) with full precision
     * The result will be rounded down
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
     * Requirements:
     * - The denominator cannot be zero
     * - The result must fit within uint256
     * Caveats:
     * - This function does not work with fixed-point numbers
     * @param x The multiplicand as an uint256
     * @param y The multiplier as an uint256
     * @param denominator The divisor as an uint256
     * @return result The result as an uint256
     */
    function mulDivRoundDown(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        (uint256 prod0, uint256 prod1) = _getMulProds(x, y);

        return _getEndOfDivRoundDown(x, y, denominator, prod0, prod1);
    }

    /**
     * @notice Calculates ceil(x*y/denominator) with full precision
     * The result will be rounded up
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
     * Requirements:
     * - The denominator cannot be zero
     * - The result must fit within uint256
     * Caveats:
     * - This function does not work with fixed-point numbers
     * @param x The multiplicand as an uint256
     * @param y The multiplier as an uint256
     * @param denominator The divisor as an uint256
     * @return result The result as an uint256
     */
    function mulDivRoundUp(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        result = mulDivRoundDown(x, y, denominator);
        if (mulmod(x, y, denominator) != 0) result += 1;
    }

    /**
     * @notice Calculates floor(x * y / 2**offset) with full precision
     * The result will be rounded down
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
     * Requirements:
     * - The offset needs to be strictly lower than 256
     * - The result must fit within uint256
     * Caveats:
     * - This function does not work with fixed-point numbers
     * @param x The multiplicand as an uint256
     * @param y The multiplier as an uint256
     * @param offset The offset as an uint256, can't be greater than 256
     * @return result The result as an uint256
     */
    function mulShiftRoundDown(uint256 x, uint256 y, uint8 offset) internal pure returns (uint256 result) {
        (uint256 prod0, uint256 prod1) = _getMulProds(x, y);

        if (prod0 != 0) result = prod0 >> offset;
        if (prod1 != 0) {
            // Make sure the result is less than 2^256.
            if (prod1 >= 1 << offset) revert Uint256x256Math__MulShiftOverflow();

            unchecked {
                result += prod1 << (256 - offset);
            }
        }
    }

    /**
     * @notice Calculates floor(x * y / 2**offset) with full precision
     * The result will be rounded down
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
     * Requirements:
     * - The offset needs to be strictly lower than 256
     * - The result must fit within uint256
     * Caveats:
     * - This function does not work with fixed-point numbers
     * @param x The multiplicand as an uint256
     * @param y The multiplier as an uint256
     * @param offset The offset as an uint256, can't be greater than 256
     * @return result The result as an uint256
     */
    function mulShiftRoundUp(uint256 x, uint256 y, uint8 offset) internal pure returns (uint256 result) {
        result = mulShiftRoundDown(x, y, offset);
        if (mulmod(x, y, 1 << offset) != 0) result += 1;
    }

    /**
     * @notice Calculates floor(x << offset / y) with full precision
     * The result will be rounded down
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
     * Requirements:
     * - The offset needs to be strictly lower than 256
     * - The result must fit within uint256
     * Caveats:
     * - This function does not work with fixed-point numbers
     * @param x The multiplicand as an uint256
     * @param offset The number of bit to shift x as an uint256
     * @param denominator The divisor as an uint256
     * @return result The result as an uint256
     */
    function shiftDivRoundDown(uint256 x, uint8 offset, uint256 denominator) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;

        prod0 = x << offset; // Least significant 256 bits of the product
        unchecked {
            prod1 = x >> (256 - offset); // Most significant 256 bits of the product
        }

        return _getEndOfDivRoundDown(x, 1 << offset, denominator, prod0, prod1);
    }

    /**
     * @notice Calculates ceil(x << offset / y) with full precision
     * The result will be rounded up
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
     * Requirements:
     * - The offset needs to be strictly lower than 256
     * - The result must fit within uint256
     * Caveats:
     * - This function does not work with fixed-point numbers
     * @param x The multiplicand as an uint256
     * @param offset The number of bit to shift x as an uint256
     * @param denominator The divisor as an uint256
     * @return result The result as an uint256
     */
    function shiftDivRoundUp(uint256 x, uint8 offset, uint256 denominator) internal pure returns (uint256 result) {
        result = shiftDivRoundDown(x, offset, denominator);
        if (mulmod(x, 1 << offset, denominator) != 0) result += 1;
    }

    /**
     * @notice Helper function to return the result of `x * y` as 2 uint256
     * @param x The multiplicand as an uint256
     * @param y The multiplier as an uint256
     * @return prod0 The least significant 256 bits of the product
     * @return prod1 The most significant 256 bits of the product
     */
    function _getMulProds(uint256 x, uint256 y) private pure returns (uint256 prod0, uint256 prod1) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }
    }

    /**
     * @notice Helper function to return the result of `x * y / denominator` with full precision
     * @param x The multiplicand as an uint256
     * @param y The multiplier as an uint256
     * @param denominator The divisor as an uint256
     * @param prod0 The least significant 256 bits of the product
     * @param prod1 The most significant 256 bits of the product
     * @return result The result as an uint256
     */
    function _getEndOfDivRoundDown(uint256 x, uint256 y, uint256 denominator, uint256 prod0, uint256 prod1)
        private
        pure
        returns (uint256 result)
    {
        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
        } else {
            // Make sure the result is less than 2^256. Also prevents denominator == 0
            if (prod1 >= denominator) revert Uint256x256Math__MulDivOverflow();

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1
            // See https://cs.stackexchange.com/q/138556/92363
            unchecked {
                // Does not overflow because the denominator cannot be zero at this stage in the function
                uint256 lpotdod = denominator & (~denominator + 1);
                assembly {
                    // Divide denominator by lpotdod.
                    denominator := div(denominator, lpotdod)

                    // Divide [prod1 prod0] by lpotdod.
                    prod0 := div(prod0, lpotdod)

                    // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one
                    lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
                }

                // Shift in bits from prod1 into prod0
                prod0 |= prod1 * lpotdod;

                // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
                // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
                // four bits. That is, denominator * inv = 1 mod 2^4
                uint256 inverse = (3 * denominator) ^ 2;

                // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
                // in modular arithmetic, doubling the correct bits in each step
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
            }
        }
    }
}