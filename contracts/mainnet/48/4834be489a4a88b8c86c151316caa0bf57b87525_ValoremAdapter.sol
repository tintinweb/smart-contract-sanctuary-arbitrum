// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

// Abstract Classes
import {UpgradeableOperableKeepable} from "src/common/UpgradeableOperableKeepable.sol";

// Interfaces
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";
import {IOptionStrategy} from "src/interfaces/IOptionStrategy.sol";
import {IOption} from "src/interfaces/IOption.sol";
import {ICompoundStrategy} from "src/interfaces/ICompoundStrategy.sol";
import {IRouter} from "src/interfaces/IRouter.sol";
import {IUniswapV2Pair} from "src/interfaces/lp/IUniswapV2Pair.sol";
import {ISeaport} from "src/interfaces/option/valorem/ISeaport.sol";
import {IValorem} from "src/interfaces/option/valorem/IValorem.sol";
import {IUniswapV3Pool} from "src/interfaces/swap/uniswap/IUniswapV3Pool.sol";
//Libraries
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {AssetsPricing} from "src/libraries/AssetsPricing.sol";

contract ValoremAdapter is IOption, ERC1155TokenReceiver, UpgradeableOperableKeepable {
    using FixedPointMathLib for uint256;

    // Info needed execute options (stack too deep)
    struct ExecuteInfo {
        address thisAddress;
        uint256 wethAmount;
        uint256 totalCollateral;
        uint256 id;
        uint8 decimals;
        ISeaport.FullFillOrder seaportOrder;
    }

    struct FlashCallbackData {
        uint256 optionId;
        uint256 amount;
        uint256 cost;
        address caller;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  VARIABLES                                 */
    /* -------------------------------------------------------------------------- */
    /// @notice Internal representation of 100%
    uint256 private constant BASIS_POINTS = 1e12;

    // @notice Tokens used in the underlying logic
    IERC20 private constant WETH = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    IERC20 private constant USDC = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);

    /// @notice hash(epoch, type, strike) => id
    mapping(bytes32 => uint256) public optionId;

    /// @notice hash(epoch, type, strike) => decimals
    mapping(bytes32 => uint256) public optionDecimals;

    /// @notice Metavaults Factory
    address public factory;

    /// @notice Seaport 1.5
    ISeaport public seaport;

    /// @notice Valorem Clearing House 1.0.1 (on october 4th)
    IValorem public valorem;

    /// @notice ETH-USDC V3 Pool
    IUniswapV3Pool public WETH_USDC_V3;

    uint256 public constant VALOREM_BPS = 10_000;

    /// @notice Slippage to avoid reverts after simulations
    uint256 private slippage;

    /* -------------------------------------------------------------------------- */
    /*                                    INIT                                    */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Initializes the transparent proxy of the Valorem Adapter
     * @param _factory address of the factory
     * @param _seaport 1.5 seaport address
     */
    function initializeOptionAdapter(address _factory, address _seaport, address _valorem) external initializer {
        __Governable_init(msg.sender);

        if (_seaport == address(0) || _factory == address(0)) {
            revert ZeroAddress();
        }

        // Store factory in storage
        factory = _factory;

        // Store seaport in storage
        seaport = ISeaport(_seaport);

        // Store valorem in storage
        valorem = IValorem(_valorem);

        // Flash loan pool
        WETH_USDC_V3 = IUniswapV3Pool(0x17c14D2c404D167802b16C450d3c99F88F2c4F4d); // 3000 fee

        slippage = (99 * 1e12) / 100;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 ONLY OPERATOR                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Buy options.
     * @param params Parameter needed to buy options.
     */
    function purchase(OptionParams calldata params) public onlyOperator {
        ExecuteInfo memory info;

        info.thisAddress = address(this);

        info.wethAmount = WETH.balanceOf(info.thisAddress);

        WETH.approve(address(IOptionStrategy(msg.sender).swapper()), info.wethAmount);

        // Swaps received WETH to USDC
        IOptionStrategy(msg.sender).swapper().swapWethToUSDC(info.wethAmount);

        // Gets total collateral we have
        info.totalCollateral = USDC.balanceOf(info.thisAddress);

        (info.id, info.decimals, info.seaportOrder) =
            abi.decode(params._optionData, (uint256, uint8, ISeaport.FullFillOrder));

        if (info.totalCollateral < params._option.cost) {
            revert NotEnoughCollateral();
        }

        // Approve for spending on Seaport
        USDC.approve(address(seaport), params._option.cost);

        if (!seaport.fulfillOrder(info.seaportOrder.order, info.seaportOrder.fulfillerConduitKey)) {
            revert FulfillOrderFail();
        }

        // Add  the bought strike data to the storage of Option Strategy in order to handle mid epoch deposits
        IOptionStrategy(msg.sender).addBoughtStrikes(params._epoch, params._option.type_, params._option);

        bytes32 optionHash = keccak256(abi.encode(params._epoch, params._option.type_, params._option.strike));

        optionId[optionHash] = info.id;
        optionDecimals[optionHash] = info.decimals;

        // Emit event showing the prices of the strikes we bought and other relevant info
        emit ValoremPurchase(
            params._epoch, params._option.strike, params._option.cost, params._option.amount, params._option.type_
        );
    }

    /**
     * @notice Exercise ITM options.
     * @param params OptionParams struct containing the option data.
     */

    function settle(OptionParams calldata params) public onlyOperator returns (uint256) {
        uint256 _optionId = optionId[keccak256(abi.encode(params._epoch, params._option.type_, params._option.strike))];

        // Option Data
        IValorem.Option memory valoremOption = valorem.option(_optionId);

        uint256 _cost = _exerciseCost(valoremOption, params._option.amount);

        if (params._option.type_ == IRouter.OptionStrategy.BULL) {
            WETH_USDC_V3.flash(
                address(this),
                0,
                _cost,
                abi.encode(
                    FlashCallbackData({
                        optionId: _optionId,
                        amount: params._option.amount,
                        cost: _cost,
                        caller: msg.sender
                    })
                )
            );
        } else {
            WETH_USDC_V3.flash(
                address(this),
                _cost,
                0,
                abi.encode(
                    FlashCallbackData({
                        optionId: _optionId,
                        amount: params._option.amount,
                        cost: _cost,
                        caller: msg.sender
                    })
                )
            );
        }

        return 0;
    }

    /// @dev After we take the flash loan, Uniswap calls this fallback function
    /// Flash-loaning assets incur a 0.05% fee
    function uniswapV3FlashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external {
        if (msg.sender != address(WETH_USDC_V3)) {
            revert CallerIsNotAllowed();
        }

        (FlashCallbackData memory _data) = abi.decode(data, (FlashCallbackData));
        // Now we have the needed assets to settle, so we can exercise the options and using profits to pay back the flash loan + fees
        IRouter.OptionStrategy _type;

        // On puts we borrow WETH
        if (fee0 > 0) {
            WETH.approve(address(valorem), _data.cost);
            valorem.exercise(_data.optionId, uint112(_data.amount));

            uint256 toPayBack = fee0 + _data.cost;
            uint256 currentWETH = WETH.balanceOf(address(this));
            if (currentWETH < toPayBack) {
                // currentUSDC < toPayBack
                uint256 usdcNeeded = IOptionStrategy(_data.caller).swapper().wethFromUSDCIn(toPayBack - currentWETH); // toPayBack - currentWETH
                if (usdcNeeded > 0) {
                    USDC.approve(address(IOptionStrategy(_data.caller).swapper()), usdcNeeded);
                    IOptionStrategy(_data.caller).swapper().swapUSDCToWeth(usdcNeeded);
                }
            }

            WETH.transfer(msg.sender, fee0 + _data.cost);

            _type = IRouter.OptionStrategy.BEAR;
        }
        // On calls we borrow USDC
        else {
            USDC.approve(address(valorem), _data.cost);
            valorem.exercise(_data.optionId, uint112(_data.amount));

            // payback swap weth rewards to get fee1 + _data.cost USDC
            uint256 toPayBack = fee1 + _data.cost;
            uint256 currentUSDC = USDC.balanceOf(address(this));
            if (currentUSDC < toPayBack) {
                // currentUSDC < toPayBack
                uint256 wethNeeded = IOptionStrategy(_data.caller).swapper().USDCFromWethIn(toPayBack - currentUSDC); // toPayBack - currentUSDC
                if (wethNeeded > 0) {
                    WETH.approve(address(IOptionStrategy(_data.caller).swapper()), wethNeeded);
                    IOptionStrategy(_data.caller).swapper().swapWethToUSDC(wethNeeded);
                }
            }
            USDC.transfer(msg.sender, toPayBack);

            _type = IRouter.OptionStrategy.BULL;
        }

        uint256 usdcBalance = USDC.balanceOf(address(this));

        // If flow reached here, means that we have succesfully exercised the options profitably and paid back the flash loan
        if (usdcBalance > 0) {
            USDC.approve(address(IOptionStrategy(_data.caller).swapper()), usdcBalance);
            IOptionStrategy(_data.caller).swapper().swapUSDCToWeth(usdcBalance);
        }
        uint256 wethAmount = WETH.balanceOf(address(this));

        if (wethAmount > 0) {
            // Transfer to Option Strategy
            WETH.transfer(_data.caller, WETH.balanceOf(address(this)));
            IOptionStrategy(_data.caller).afterSettleOptions(_type, wethAmount);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                     VIEW                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Gets PNL and convert to WETH if > 0
     */
    function position(address _optionStrategy, address _compoundStrategy, IRouter.OptionStrategy _type)
        external
        view
        returns (uint256)
    {
        (uint256 pnl_, uint256 cost_) = _pnl(_optionStrategy, _compoundStrategy, _type);

        // Calculate min amoutn out of sushi trade. This takes in consideration fees
        cost_ = IOptionStrategy(_optionStrategy).swapper().RawUSDCToWETH(cost_);
        if (pnl_ > cost_) {
            return pnl_ - cost_;
        }
        return 0;
    }

    // Simulate outcome of the bought options if we were exercising now
    function pnl(address _optionStrategy, address _compoundStrategy, IRouter.OptionStrategy _type)
        external
        view
        returns (uint256)
    {
        (uint256 pnl_,) = _pnl(_optionStrategy, _compoundStrategy, _type);
        return pnl_;
    }

    function lpToCollateral(address _lp, uint256 _amount, address _optionStrategy) external view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(_lp);

        // Very precise but not 100%
        (uint256 token0Amount, uint256 token1Amount) = AssetsPricing.breakFromLiquidityAmount(_lp, _amount);

        uint256 wethAmount;

        // Convert received tokens from LP to WETH.
        // This function gets maxAmountOut and accounts for slippage + fees
        // We dont support LPs that doesnt have WETH in its composition (for now)
        if (pair.token0() == address(WETH)) {
            wethAmount =
                token0Amount + IOptionStrategy(_optionStrategy).swapper().wethFromToken(pair.token1(), token1Amount);
        } else if (pair.token1() == address(WETH)) {
            wethAmount =
                token1Amount + IOptionStrategy(_optionStrategy).swapper().wethFromToken(pair.token0(), token0Amount);
        } else {
            revert NoSupport();
        }

        return IOptionStrategy(_optionStrategy).swapper().USDCFromWeth(wethAmount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  ONLY FACTORY                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Add Operator role to _newOperator.
     */
    function addOperator(address _newOperator) public override {
        if (!(hasRole(OPERATOR, msg.sender) || (msg.sender == factory))) {
            revert CallerIsNotAllowed();
        }

        _grantRole(OPERATOR, _newOperator);

        emit OperatorAdded(_newOperator);
    }

    /* -------------------------------------------------------------------------- */
    /*                                 ONLY GOVERNOR                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Moves assets from the strategy to `_to`
     * @param _assets An array of IERC20 compatible tokens to move out from the strategy
     * @param _withdrawNative `true` if we want to move the native asset from the strategy
     */
    function emergencyWithdraw(address _to, address[] memory _assets, bool _withdrawNative) external onlyGovernor {
        uint256 assetsLength = _assets.length;
        for (uint256 i = 0; i < assetsLength; i++) {
            IERC20 asset = IERC20(_assets[i]);
            uint256 assetBalance = asset.balanceOf(address(this));

            if (assetBalance > 0) {
                // Transfer the ERC20 tokens
                asset.transfer(_to, assetBalance);
            }

            unchecked {
                ++i;
            }
        }

        uint256 nativeBalance = address(this).balance;

        // Nothing else to do
        if (_withdrawNative && nativeBalance > 0) {
            // Transfer the native currency
            (bool sent,) = payable(_to).call{value: nativeBalance}("");
            if (!sent) {
                revert FailSendETH();
            }
        }

        emit EmergencyWithdrawal(msg.sender, _to, _assets, _withdrawNative ? nativeBalance : 0);
    }

    /**
     * @notice Update Factory
     * @param _factory Fatory address
     */
    function updateFactory(address _factory) external onlyGovernor {
        factory = _factory;
    }

    /**
     * @notice Update Valorem
     * @param _valorem Valore address
     */
    function updateValorem(address _valorem) external onlyGovernor {
        valorem = IValorem(_valorem);
    }

    /**
     * @notice Update Seaport
     * @param _seaport Seaport address
     */
    function updateSeaport(address _seaport) external onlyGovernor {
        seaport = ISeaport(_seaport);
    }

    /**
     * @notice Update Flash loan pool
     * @param _pool flash loan pool address
     */
    function updateflashPool(address _pool) external onlyGovernor {
        WETH_USDC_V3 = IUniswapV3Pool(_pool);
    }

    /**
     * @notice Default slippage for safety measures
     * @param _slippage Default slippage
     */
    function setSlippage(uint256 _slippage) external onlyGovernor {
        if (_slippage == 0 || _slippage > BASIS_POINTS) revert InvalidSlippage();

        slippage = _slippage;
    }

    /* -------------------------------------------------------------------------- */
    /*                                     PRIVATE                                */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice return current option pnl and cost
     * @return pnl_ in usd in 6 decimals
     * @return totalCost_ total amount paid to purchased these options
     */
    function _pnl(address _optionStrategy, address _compoundStrategy, IRouter.OptionStrategy _type)
        private
        view
        returns (uint256 pnl_, uint256 totalCost_)
    {
        uint16 systemEpoch = ICompoundStrategy(_compoundStrategy).currentEpoch();

        IOptionStrategy.Option[] memory _options =
            IOptionStrategy(_optionStrategy).getOptions(systemEpoch, address(this), _type);

        uint256 length = _options.length;

        // Check PNL checking individually PNL on each strike we bought
        for (uint256 i; i < length;) {
            if (_options[i].amount > 0) {
                // Get Option ID
                uint256 _optionId = optionId[keccak256(abi.encode(systemEpoch, _options[i].type_, _options[i].strike))];
                // Option Data
                IValorem.Option memory valoremOption = valorem.option(_optionId);
                if (
                    block.timestamp >= valoremOption.exerciseTimestamp
                        && block.timestamp < valoremOption.expiryTimestamp
                ) {
                    uint256 expectedUnderlying = valoremOption.underlyingAmount * _options[i].amount;

                    if (_type == IRouter.OptionStrategy.BULL) {
                        // RETURN WETH REWARDS, ASK AND PAYBACK USDC TO SETTLE
                        // CALL
                        uint256 exerciseCost = _exerciseCost(valoremOption, _options[i].amount);

                        // add flash pool fee
                        exerciseCost = exerciseCost + exerciseCost.mulDivUp(WETH_USDC_V3.fee(), 1e6);
                        exerciseCost = IOptionStrategy(_optionStrategy).swapper().USDCFromWethIn(exerciseCost); // eth 18 decimals

                        if (expectedUnderlying > exerciseCost) {
                            pnl_ = pnl_ + (expectedUnderlying - exerciseCost); // eth 18 decimals
                        }
                    } else {
                        // PUT
                        // RETURN WETH REWARDS, ASK AND PAYBACK WETH TO SETTLE
                        uint256 exerciseCost = _exerciseCost(valoremOption, _options[i].amount);
                        exerciseCost = IOptionStrategy(_optionStrategy).swapper().wethFromUSDCIn(exerciseCost); // usdc 6 decimals

                        // add flash pool fee
                        exerciseCost = exerciseCost + exerciseCost.mulDivUp(WETH_USDC_V3.fee(), 1e6);

                        if (expectedUnderlying > exerciseCost) {
                            pnl_ = pnl_
                                + IOptionStrategy(_optionStrategy).swapper().wethFromUSDC(expectedUnderlying - exerciseCost); // eth in 18 decimals
                        }
                    }
                }
            }

            totalCost_ = totalCost_ + _options[i].cost; // usdc in 6 decimals

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice return exercise cost for an option
     * @return exercise cost if CALL, is in usdc if PUT is in weth
     */
    function _exerciseCost(IValorem.Option memory option, uint256 amount) private view returns (uint256) {
        // Exercise Amount
        uint256 rxAmount = option.exerciseAmount * amount;
        // Fee
        uint256 fee;
        if (valorem.feesEnabled()) {
            fee = (rxAmount * valorem.feeBps()) / VALOREM_BPS;
            if (fee == 0) {
                fee = 1;
            }
        }

        return rxAmount + fee;
    }

    function _applySlippage(uint256 _amountOut, uint256 _slippage) private pure returns (uint256) {
        return _amountOut.mulDivDown(_slippage, BASIS_POINTS);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event ValoremPurchase(
        uint16 indexed epoch, uint32 strike, uint256 cost, uint256 amount, IRouter.OptionStrategy type_
    );

    event ValoremSettle(
        uint16 indexed epoch,
        uint256 optionId,
        IRouter.OptionStrategy type_,
        uint32 strike,
        uint256 optionAmount,
        uint256 wethAmount
    );

    event EmergencyWithdrawal(address indexed caller, address indexed receiver, address[] tokens, uint256 nativeBalanc);

    /* -------------------------------------------------------------------------- */
    /*                                    ERRORS                                  */
    /* -------------------------------------------------------------------------- */

    error NotEnoughCollateral();
    error FulfillOrderFail();
    error FailSendETH();
    error ZeroAddress();
    error NoSupport();
    error InvalidSlippage();
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {UpgradeableGovernable} from "./UpgradeableGovernable.sol";

abstract contract UpgradeableOperableKeepable is UpgradeableGovernable {
    /**
     * @notice Operator role
     */
    bytes32 public constant OPERATOR = bytes32("OPERATOR");
    /**
     * @notice Keeper role
     */
    bytes32 public constant KEEPER = bytes32("KEEPER");

    /**
     * @notice Modifier if msg.sender has not Operator role revert.
     */
    modifier onlyOperator() {
        if (!hasRole(OPERATOR, msg.sender)) {
            revert CallerIsNotOperator();
        }

        _;
    }

    /**
     * @notice Modifier if msg.sender has not Keeper role revert.
     */
    modifier onlyKeeper() {
        if (!hasRole(KEEPER, msg.sender)) {
            revert CallerIsNotKeeper();
        }

        _;
    }

    /**
     * @notice Modifier if msg.sender has not Keeper or Operator role revert.
     */
    modifier onlyOperatorOrKeeper() {
        if (!(hasRole(OPERATOR, msg.sender) || hasRole(KEEPER, msg.sender))) {
            revert CallerIsNotAllowed();
        }

        _;
    }

    /**
     * @notice Modifier if msg.sender has not Keeper or Governor role revert.
     */
    modifier onlyGovernorOrKeeper() {
        if (!(hasRole(GOVERNOR, msg.sender) || hasRole(KEEPER, msg.sender))) {
            revert CallerIsNotAllowed();
        }

        _;
    }

    /**
     * @notice Add Operator role to _newOperator.
     */
    function addOperator(address _newOperator) public virtual onlyGovernor {
        _grantRole(OPERATOR, _newOperator);

        emit OperatorAdded(_newOperator);
    }

    /**
     * @notice Remove Operator role from _operator.
     */
    function removeOperator(address _operator) external onlyGovernor {
        _revokeRole(OPERATOR, _operator);

        emit OperatorRemoved(_operator);
    }

    /**
     * @notice Add Keeper role to _newKeeper.
     */
    function addKeeper(address _newKeeper) external onlyGovernor {
        _grantRole(KEEPER, _newKeeper);

        emit KeeperAdded(_newKeeper);
    }

    /**
     * @notice Remove Keeper role from _keeper.
     */
    function removeKeeper(address _keeper) external onlyGovernor {
        _revokeRole(KEEPER, _keeper);

        emit KeeperRemoved(_keeper);
    }

    event OperatorAdded(address _newOperator);
    event OperatorRemoved(address _operator);

    error CallerIsNotOperator();

    event KeeperAdded(address _newKeeper);
    event KeeperRemoved(address _keeper);

    error CallerIsNotKeeper();

    error CallerIsNotAllowed();
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

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import {IRouter} from "src/interfaces/IRouter.sol";
import {IOption} from "src/interfaces/IOption.sol";
import {ISwap} from "src/interfaces/ISwap.sol";

interface IOptionStrategy {
    struct Option {
        IRouter.OptionStrategy type_;
        uint32 strike; // ETH/USDC
        uint64 expiry;
        uint256 amount;
        uint256 cost;
    }

    // Index 0 is most profitable option
    struct ExecuteStrategy {
        uint16 epoch;
        IOption[] providers;
        // amount of the broken lp that will go to the provider to purchase options
        uint256[] providerPercentage;
        IOption.OptionParams[] params;
    }

    // Struct used to collect profits from options purchase
    struct CollectRewards {
        // System epoch
        uint16 epoch;
        // Strategy Type
        IRouter.OptionStrategy type_;
        // Array of providers
        address provider;
        // Extra data for options providers
        bytes[] optionData;
    }

    // Deposits into OptionStrategy to execute options logic
    struct Budget {
        // Deposits to buy options
        uint128 totalDeposits;
        uint128 bullDeposits;
        uint128 bearDeposits;
        // Profits from options
        uint128 bullEarned;
        uint128 bearEarned;
        uint128 totalEarned;
    }

    struct OptionOverpayAndData {
        // Option strike
        uint32 strike;
        // Amount of options
        uint256 amount;
        // Cost of option strike
        uint256 cost;
        // Option Data
        bytes optionData;
        // Percentaje of collateral used to buy options
        uint256 collateralPercentage;
        // Amount of collateral going to given strike
        uint256 toBuyOptions;
        // ToFarm -> only in case options prices are now cheaper
        uint256 toFarm;
        // true -> means options prices are now higher than when strategy was executed
        // If its false, we are purchasing same amount of options with less collateral and sending extra to farm
        bool isOverpaying;
    }

    function deposit(uint16 _epoch, uint256 _amount, uint256 _bullDeposits, uint256 _bearDeposits) external;
    function middleEpochOptionsBuy(IOption _provider, uint256 _lpAmount, IOption.OptionParams calldata _params)
        external;
    function executeBullStrategy(uint128 _toSpend, ExecuteStrategy calldata _execute, ISwap.SwapInfo calldata _swapInfo)
        external;
    function executeBearStrategy(uint128 _toSpend, ExecuteStrategy calldata _execute, ISwap.SwapInfo calldata _swapInfo)
        external;
    function startCrabStrategy(IRouter.OptionStrategy _strategyType, uint16 _epoch) external;
    function collectRewards(CollectRewards calldata _collect) external;
    function realizeRewards(uint16 _epoch, IRouter.OptionStrategy _type, ISwap.SwapInfo calldata _swapInfo)
        external
        returns (uint256);

    function afterSettleOptions(IRouter.OptionStrategy _type, uint256 _wethAmount) external;

    function afterMiddleEpochOptionsBuy(IRouter.OptionStrategy _type, uint256 _collateralAmount) external;
    function addBoughtStrikes(uint16 _epoch, IRouter.OptionStrategy _type, Option calldata _option) external;

    function getOptions(uint16 _epoch, address _provider, IRouter.OptionStrategy _type)
        external
        view
        returns (Option[] memory);
    function optionPosition(uint16 _epoch, IRouter.OptionStrategy _type) external view returns (uint256);
    function compareStrikes(uint256 _costPaid, uint256 _currentCost, uint256 _baseAmount)
        external
        view
        returns (uint256 toBuyOptions, uint256 toFarm, bool isOverpaying);
    function deltaPrice(
        uint16 _epoch,
        uint256 _userAmountOfLp,
        IRouter.OptionStrategy _strategy,
        bytes calldata _optionOrder,
        address _provider
    ) external view returns (OptionOverpayAndData memory);
    function getBullProviders(uint16 epoch) external view returns (IOption[] memory);
    function getBearProviders(uint16 epoch) external view returns (IOption[] memory);
    function getBudget(uint16 _epoch) external view returns (Budget memory);
    function defaultAdapter(IRouter.OptionStrategy) external view returns (IOption);

    function borrowedLP(IRouter.OptionStrategy _type) external view returns (uint256);
    function executedStrategy(uint16 _epoch, IRouter.OptionStrategy _type) external view returns (bool);

    function swapper() external view returns (ISwap);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IRouter} from "src/interfaces/IRouter.sol";
import {IOptionStrategy} from "src/interfaces/IOptionStrategy.sol";

interface IOption {
    // Data needed to purchase and settle options
    struct OptionParams {
        uint16 _epoch;
        IOptionStrategy.Option _option;
        bytes _optionData;
    }

    // Buys options.
    // Return avg option price in WETH
    function purchase(OptionParams calldata params) external;

    // Settle ITM options
    function settle(OptionParams calldata params) external returns (uint256);

    function position(address _optionStrategy, address _compoundStrategy, IRouter.OptionStrategy _type)
        external
        view
        returns (uint256);

    function pnl(address _optionStrategy, address _compoundStrategy, IRouter.OptionStrategy _type)
        external
        view
        returns (uint256);

    function lpToCollateral(address _lp, uint256 _amount, address _optionStrategy) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {IOption} from "src/interfaces/IOption.sol";
import {IRouter} from "src/interfaces/IRouter.sol";
import {IFarm} from "src/interfaces/IFarm.sol";
import {ISwap} from "src/interfaces/ISwap.sol";
import {ILPVault} from "src/interfaces/ILPVault.sol";
import {IOptionStrategy} from "src/interfaces/IOptionStrategy.sol";

interface ICompoundStrategy {
    /**
     * @notice Usefull Epoch Data
     */
    struct Epoch {
        // Start time of the epoch
        uint64 startTime;
        // When the Epoch expiries
        uint64 virtualEndTime;
        // When we finish the Epoch
        uint64 endTime;
        // % of Bull vault used to buy call options
        uint64 optionBullRisk;
        // % of Bear vault used to buy put options
        uint64 optionBearRisk;
        // Initial LP amount in the begin of the Epoch
        uint128 initialBullRatio;
        uint128 initialBearRatio;
        uint128 initialCrabRatio;
        // Withdraw Rates jLP -> LP
        uint128 withdrawBullExchangeRate;
        uint128 withdrawBearExchangeRate;
        // Flip Rates bullLP -> bearLP
        uint128 flipBullToBearExchangeRate;
        uint128 flipBullToCrabExchangeRate;
        uint128 flipBearToBullExchangeRate;
        uint128 flipBearToCrabExchangeRate;
        uint128 flipCrabToBullExchangeRate;
        uint128 flipCrabToBearExchangeRate;
        // Deposit Rates
        uint128 depositBullRatio;
        uint128 depositBearRatio;
        // Final amount of LP in the end of the Epoch
        uint128 finalBullRatio;
        uint128 finalBearRatio;
        uint128 finalCrabRatio;
    }

    /**
     * @notice Start epoch information, help on startEpoch (stack too deep)
     */
    struct StartEpochInfo {
        uint16 epoch;
        address thisAddress;
        uint256 currentLPBalance;
        uint256 farmBalance;
        uint256 initialBalanceSnapshot;
        uint256 bullAssets;
        uint256 bearAssets;
        uint256 crabAssets;
        uint256 totalBalance;
        uint256 bullAmount;
        uint256 bearAmount;
        uint256 toOptions;
        uint256 bullRatio;
        uint256 bearRatio;
        uint256 crabRatio;
    }

    /**
     * @notice General epoch information, help on endEpoch (stack too deep)
     */
    struct GeneralInfo {
        Epoch epochData;
        uint16 currentEpoch;
        uint256 endTime;
        address thisAddress;
        IRouter router;
        address routerAddress;
        ILPVault bullVault;
        ILPVault bearVault;
        ILPVault crabVault;
        IRouter.OptionStrategy bullStrat;
        IRouter.OptionStrategy bearStrat;
        IRouter.OptionStrategy crabStrat;
        IERC20 lpToken;
    }

    /**
     * @notice Flip signals information.
     */
    struct FlipInfo {
        uint256 bullToBear;
        uint256 bullToCrab;
        uint256 bearToBull;
        uint256 bearToCrab;
        uint256 crabToBull;
        uint256 crabToBear;
        uint256 redeemBullToBearAssets;
        uint256 redeemBullToCrabAssets;
        uint256 redeemBearToBullAssets;
        uint256 redeemBearToCrabAssets;
        uint256 redeemCrabToBullAssets;
        uint256 redeemCrabToBearAssets;
        uint256 bullToBearShares;
        uint256 bullToCrabShares;
        uint256 bearToBullShares;
        uint256 bearToCrabShares;
        uint256 crabToBearShares;
        uint256 crabToBullShares;
        uint256 bullToBearRate;
        uint256 bullToCrabRate;
        uint256 bearToBullRate;
        uint256 bearToCrabRate;
        uint256 crabToBullRate;
        uint256 crabToBearRate;
    }

    /**
     * @notice Withdraw signals information.
     */
    struct WithdrawInfo {
        uint256 bullShares;
        uint256 bearShares;
        uint256 bullAssets;
        uint256 bearAssets;
        uint256 totalSignals;
        uint256 bullRetention;
        uint256 bearRetention;
        uint256 retention;
        uint256 toTreasury;
        uint256 toPayBack;
        uint256 currentBalance;
        uint256 withdrawBullRate;
        uint256 withdrawBearRate;
    }

    /**
     * @notice Next epoch deposit information.
     */
    struct DepositInfo {
        uint256 depositBullAssets;
        uint256 depositBearAssets;
        uint256 depositBullShares;
        uint256 depositBearShares;
        uint256 depositBullRate;
        uint256 depositBearRate;
    }

    /**
     * @notice Auto compounds all the farming rewards.
     */
    function autoCompound() external;

    /**
     * @notice Handles LPs deposits accountability and staking
     * @param _amount Amount of LP tokens being deposited
     * @param _type Strategy which balance will be updated
     * @param _nextEpoch signal to not increase the balance of the vault immidiatly.
     */
    function deposit(uint256 _amount, IRouter.OptionStrategy _type, bool _nextEpoch) external;

    /**
     * @notice Withdraw LP assets.
     * @param _amountWithPenalty Amount to unstake
     * @param _receiver Who will receive the LP token
     */
    function instantWithdraw(uint256 _amountWithPenalty, IRouter.OptionStrategy _type, address _receiver) external;

    /**
     * @notice Get LP Vault Assets, overall LP for a Vault.
     */
    function vaultAssets(IRouter.OptionStrategy _type) external view returns (uint256);

    /**
     * @notice Get current LP Vault Balance, without pnl, borrowing LP and pending rewards.
     */
    function getVaultBalance(IRouter.OptionStrategy _type) external view returns (uint256);

    /**
     * @notice Get Current epoch.
     */
    function currentEpoch() external view returns (uint16);

    /**
     * @notice Get epoch Data.
     */
    function epochData(uint16 number) external view returns (Epoch memory);

    /**
     * @notice Get the LP Token.
     */
    function lpToken() external view returns (IERC20);

    /**
     * @notice Get the farm contract.
     */
    function farm() external view returns (IFarm);

    /**
     * @notice Get the three strategy Vaults; 0 => BULL, 1 => BEAR, 2 => CRAB
     */
    function getVaults() external view returns (ILPVault[] memory);

    /**
     * @notice Start new epoch.
     */
    function startEpoch(uint64 epochExpiry, uint64 optionBullRisk, uint64 optionBearRisk) external;

    /**
     * @notice Finish current epoch.
     */
    function endEpoch() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IOptionStrategy} from "src/interfaces/IOptionStrategy.sol";
import {ICompoundStrategy} from "src/interfaces/ICompoundStrategy.sol";
import {ILPVault} from "src/interfaces/ILPVault.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IRouter {
    /**
     * @notice Different types of vaults.
     */
    enum OptionStrategy {
        BULL,
        BEAR,
        CRAB
    }

    /**
     * @notice Deposit Inputs struct, inputs of deposit function.
     */
    struct DepositInputs {
        uint256 assets;
        OptionStrategy strategy;
        address receiver;
        bool instant;
        bytes[] optionOrders; // data neede to purchase the option
    }

    /**
     * @notice Deposit info struct, helps on deposit process (stack too deep).
     */
    struct DepositInfo {
        address receiver;
        OptionStrategy strategy;
        address thisAddress;
        uint16 epoch;
        uint64 endTime;
        uint256 optionBullRisk;
        uint256 optionBearRisk;
        address strategyAddress;
        address optionsAddress;
        ICompoundStrategy compoundStrategy;
        IOptionStrategy optionStrategy;
        IERC20 lpToken;
        ILPVault vault;
        uint256 assets;
        uint256 toFarm;
        uint256 toBuyOptions;
        uint256 shares;
    }

    /**
     * @notice Withdraw info struct, helps on withdraw process (stack too deep).
     */
    struct WithdrawInfo {
        uint16 currentEpoch;
        uint256 endTime;
        uint256 withdrawExchangeRate;
        uint256 currentBalance;
        uint256 sharesWithPenalty;
        uint256 lpAssets;
        uint256 retention;
        uint256 toTreasury;
        uint256 redemeed;
        address incentiveReceiver;
    }

    /**
     * @notice Cancel flip info struct, helps on cancelFlip (stack too deep).
     */
    struct CancelFlipInfo {
        uint16 commitEpoch;
        uint16 currentEpoch;
        uint256 endTime;
        uint256 finalShares;
        uint256 flipRate;
    }

    /**
     * @notice User withdraw signal struct.
     */
    struct WithdrawalSignal {
        uint16 targetEpoch;
        uint256 commitedShares;
        OptionStrategy strategy;
        uint256 redeemed;
    }

    /**
     * @notice User flip signal struct.
     */
    struct FlipSignal {
        uint16 targetEpoch;
        uint256 commitedShares;
        OptionStrategy oldStrategy;
        OptionStrategy newStrategy;
        uint256 redeemed;
    }

    /**
     * @notice Enable LP deposits to a Strategy Metavault.
     * @param _params Amount of assets to be deposit
     * @return Amount of shares minted.
     */
    function deposit(DepositInputs calldata _params, bytes calldata _signature) external returns (uint256);

    /**
     * @notice Get shares for previues epoch deposit.
     * @param _commitEpoch Amount of assets to be deposit
     * @param _strategy Type of Metavault, it can be BULL, BEAR or CRAB.
     * @param _receiver Who will receive the shares.
     * @return Amount of shares.
     */
    function claim(uint16 _commitEpoch, OptionStrategy _strategy, address _receiver) external returns (uint256);

    /**
     * @notice Signal withdraw to the next epoch.
     * @param _receiver Who will receive the assets redeemed.
     * @param _strategy Type of Metavault, it can be BULL, BEAR or CRAB.
     * @param _shares Amount of Metavault shares to redeem.
     * @return Target epoch.
     */
    function signalWithdraw(address _receiver, OptionStrategy _strategy, uint256 _shares) external returns (uint256);

    /**
     * @notice Cancel signal withdraw.
     * @param _targetEpoch Signal target epoch.
     * @param _strategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _receiver Who will receive the shares.
     * @return LP shares.
     */
    function cancelSignal(uint16 _targetEpoch, OptionStrategy _strategy, address _receiver)
        external
        returns (uint256);

    /**
     * @notice Withdraw.
     * @param _targetEpoch Signal target epoch.
     * @param _strategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _receiver Who will receive the assets.
     * @return LP assets.
     */
    function withdraw(uint16 _targetEpoch, OptionStrategy _strategy, address _receiver) external returns (uint256);

    /**
     * @notice Instant withdraw.
     * @param _shares Shares to redeem.
     * @param _strategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _receiver Who will receive the assets.
     * @return LP assets.
     */
    function instantWithdraw(uint256 _shares, OptionStrategy _strategy, address _receiver) external returns (uint256);

    /**
     * @notice Signal flip.
     * @param _shares Shares to flip.
     * @param _oldtrategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _newStrategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _receiver Who will receive the shares.
     */
    function signalFlip(uint256 _shares, OptionStrategy _oldtrategy, OptionStrategy _newStrategy, address _receiver)
        external
        returns (uint16);

    /**
     * @notice Cancel Flip Signal.
     * @param _targetEpoch Signal target epoch.
     * @param _oldStrategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _newStrategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _receiver Who will receive the shares.
     * @return LP shares.
     */
    function cancelFlip(
        uint16 _targetEpoch,
        OptionStrategy _oldStrategy,
        OptionStrategy _newStrategy,
        address _receiver
    ) external returns (uint256);

    /**
     * @notice Withdraw flipped shares.
     * @param _targetEpoch Shares to flip.
     * @param _oldStrategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _newStrategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _receiver Who will receive the shares.
     * @return LP shares.
     */
    function flipWithdraw(
        uint16 _targetEpoch,
        OptionStrategy _oldStrategy,
        OptionStrategy _newStrategy,
        address _receiver
    ) external returns (uint256);

    /**
     * @notice Update accounting when epoch finish.
     */
    function executeFinishEpoch() external;

    /**
     * @notice Total strategy next epoch deposit.
     */
    function nextEpochDeposits(OptionStrategy _strategy) external view returns (uint256);

    /**
     * @notice User next epoch deposit for a strategy.
     */
    function userNextEpochDeposits(address _user, uint16 _epoch, IRouter.OptionStrategy _strategy)
        external
        view
        returns (uint256);

    /**
     * @notice Get total withdraw signals.
     */
    function withdrawSignals(OptionStrategy _strategy) external view returns (uint256);

    /**
     * @notice Get user withdraw signals per epoch per strategy.
     */
    function getWithdrawSignal(address _user, uint16 _targetEpoch, OptionStrategy _strategy)
        external
        view
        returns (WithdrawalSignal memory);

    /**
     * @notice Total Flip Signals.
     */
    function flipSignals(OptionStrategy _oldStrategy, OptionStrategy _newStrategy) external view returns (uint256);

    /**
     * @notice Get user flip signals.
     */
    function getFlipSignal(address _user, uint16 _targetEpoch, OptionStrategy _oldStrategy, OptionStrategy _newStrategy)
        external
        view
        returns (FlipSignal memory);

    /**
     * @notice Get premium.
     */
    function premium() external view returns (uint256);

    /**
     * @notice Get slippage.
     */
    function slippage() external view returns (uint256);

    /**
     * @notice Get nonce.
     */
    function nonce() external view returns (uint256);

    /**
     * @notice Get domain separator.
     */
    function domainSeparator() external view returns (bytes32);

    /**
     * @notice Get domain separator.
     */
    function incentives() external view returns (address, uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ISeaport {
    enum ItemType
    // 0: ETH on mainnet, MATIC on polygon, etc.
    {
        NATIVE,
        // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
        ERC20,
        // 2: ERC721 items
        ERC721,
        // 3: ERC1155 items
        ERC1155,
        // 4: ERC721 items where a number of tokenIds are supported
        ERC721_WITH_CRITERIA,
        // 5: ERC1155 items where a number of ids are supported
        ERC1155_WITH_CRITERIA
    }

    enum OrderType
    // 0: no partial fills, anyone can execute
    {
        FULL_OPEN,
        // 1: partial fills supported, anyone can execute
        PARTIAL_OPEN,
        // 2: no partial fills, only offerer or zone can execute
        FULL_RESTRICTED,
        // 3: partial fills supported, only offerer or zone can execute
        PARTIAL_RESTRICTED,
        // 4: contract order type
        CONTRACT
    }

    struct ConsiderationItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
        address payable recipient;
    }

    struct OfferItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
    }

    struct OrderParameters {
        address offerer; // 0x00
        address zone; // 0x20
        OfferItem[] offer; // 0x40
        ConsiderationItem[] consideration; // 0x60
        OrderType orderType; // 0x80
        uint256 startTime; // 0xa0
        uint256 endTime; // 0xc0
        bytes32 zoneHash; // 0xe0
        uint256 salt; // 0x100
        bytes32 conduitKey; // 0x120
        uint256 totalOriginalConsiderationItems; // 0x140
            // offer.length                          // 0x160
    }

    struct OrderComponents {
        address offerer;
        address zone;
        OfferItem[] offer;
        ConsiderationItem[] consideration;
        OrderType orderType;
        uint256 startTime;
        uint256 endTime;
        bytes32 zoneHash;
        uint256 salt;
        bytes32 conduitKey;
        uint256 counter;
    }

    struct Order {
        OrderParameters parameters;
        bytes signature;
    }

    struct FullFillOrder {
        Order order;
        bytes32 fulfillerConduitKey;
    }

    function fulfillOrder(
        /**
         * @custom:name order
         */
        Order calldata,
        bytes32 fulfillerConduitKey
    ) external payable returns (bool fulfilled);

    /**
     * @notice Retrieve the current counter for a given offerer.
     *
     * @param offerer The offerer in question.
     *
     * @return counter The current counter.
     */
    function getCounter(address offerer) external view returns (uint256 counter);

    /**
     * @notice Retrieve the order hash for a given order.
     *
     * @custom:param order The components of the order.
     *
     * @return orderHash The order hash.
     */
    function getOrderHash(
        /**
         * @custom:name order
         */
        OrderComponents calldata
    ) external view returns (bytes32 orderHash);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/*//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                //
//   $$$$$$$$$$                                                                                   //
//    $$$$$$$$                                  _|                                                //
//     $$$$$$ $$$$$$$$$$   _|      _|   _|_|_|  _|    _|_|    _|  _|_|   _|_|    _|_|_|  _|_|     //
//       $$    $$$$$$$$    _|      _| _|    _|  _|  _|    _|  _|_|     _|_|_|_|  _|    _|    _|   //
//   $$$$$$$$$$ $$$$$$       _|  _|   _|    _|  _|  _|    _|  _|       _|        _|    _|    _|   //
//    $$$$$$$$    $$           _|       _|_|_|  _|    _|_|    _|         _|_|_|  _|    _|    _|   //
//     $$$$$$                                                                                     //
//       $$                                                                                       //
//                                                                                                //
//////////////////////////////////////////////////////////////////////////////////////////////////*/

/**
 * @title A clearing and settling engine for options on ERC20 tokens.
 * @author 0xAlcibiades
 * @author Flip-Liquid
 * @author neodaoist
 * @notice Valorem Options V1 is a DeFi money lego for writing physically
 * settled covered call and covered put options. All Valorem options are fully
 * collateralized with an ERC-20 underlying asset and exercised with an
 * ERC-20 exercise asset using a fair assignment process. Option contracts, or
 * long positions, are issued as fungible ERC-1155 tokens, with each token
 * representing a contract. Option writers are additionally issued an ERC-1155
 * NFT claim, or short position, which is used to claim collateral and for
 * option exercise assignment.
 */
interface IValorem {
    /*//////////////////////////////////////////////////////////////
    //  Events
    //////////////////////////////////////////////////////////////*/

    //
    // Write events
    //

    /**
     * @notice Emitted when a new option type is created.
     * @param optionId The token id of the new option type created.
     * @param exerciseAsset The ERC20 contract address of the exercise asset.
     * @param underlyingAsset The ERC20 contract address of the underlying asset.
     * @param exerciseAmount The amount, in wei, of the exercise asset required to exercise each contract.
     * @param underlyingAmount The amount, in wei of the underlying asset in each contract.
     * @param exerciseTimestamp The timestamp after which this option type can be exercised.
     * @param expiryTimestamp The timestamp before which this option type can be exercised.
     */
    event NewOptionType(
        uint256 optionId,
        address indexed exerciseAsset,
        address indexed underlyingAsset,
        uint96 exerciseAmount,
        uint96 underlyingAmount,
        uint40 exerciseTimestamp,
        uint40 indexed expiryTimestamp
    );

    /**
     * @notice Emitted when new options contracts are written.
     * @param optionId The token id of the option type written.
     * @param writer The address of the writer.
     * @param claimId The claim token id of the new or existing short position written against.
     * @param amount The amount of options contracts written.
     */
    event OptionsWritten(uint256 indexed optionId, address indexed writer, uint256 indexed claimId, uint112 amount);

    /**
     * @notice Emitted when options contracts are written into a bucket.
     * @param optionId The token id of the option type written.
     * @param claimId The claim token id of the new or existing short position written against.
     * @param bucketIndex The index of the bucket to which the options were written.
     * @param amount The amount of options contracts written.
     */
    event BucketWrittenInto(
        uint256 indexed optionId, uint256 indexed claimId, uint96 indexed bucketIndex, uint112 amount
    );

    //
    // Redeem events
    //

    /**
     * @notice Emitted when a claim is redeemed.
     * @param optionId The token id of the option type of the claim being redeemed.
     * @param claimId The token id of the claim being redeemed.
     * @param redeemer The address redeeming the claim.
     * @param exerciseAmountRedeemed The amount of the option.exerciseAsset redeemed.
     * @param underlyingAmountRedeemed The amount of option.underlyingAsset redeemed.
     */
    event ClaimRedeemed(
        uint256 indexed claimId,
        uint256 indexed optionId,
        address indexed redeemer,
        uint256 exerciseAmountRedeemed,
        uint256 underlyingAmountRedeemed
    );

    //
    // Exercise events
    //

    /**
     * @notice Emitted when option contract(s) is(are) exercised.
     * @param optionId The token id of the option type exercised.
     * @param exerciser The address that exercised the option contract(s).
     * @param amount The amount of option contracts exercised.
     */
    event OptionsExercised(uint256 indexed optionId, address indexed exerciser, uint112 amount);

    /**
     * @notice Emitted when a bucket is assigned exercise.
     * @param optionId The token id of the option type exercised.
     * @param bucketIndex The index of the bucket which is being assigned exercise.
     * @param amountAssigned The amount of options contracts assigned exercise in the given bucket.
     */
    event BucketAssignedExercise(uint256 indexed optionId, uint96 indexed bucketIndex, uint112 amountAssigned);

    //
    // Fee events
    //

    /**
     * @notice Emitted when protocol fees are accrued for a given asset.
     * @dev Emitted on write() when fees are accrued on the underlying asset,
     * or exercise() when fees are accrued on the exercise asset.
     * Will not be emitted when feesEnabled is false.
     * @param optionId The token id of the option type being written or exercised.
     * @param asset The ERC20 asset in which fees were accrued.
     * @param payer The address paying the fee.
     * @param amount The amount, in wei, of fees accrued.
     */
    event FeeAccrued(uint256 indexed optionId, address indexed asset, address indexed payer, uint256 amount);

    /**
     * @notice Emitted when accrued protocol fees for a given ERC20 asset are swept to the
     * feeTo address.
     * @param asset The ERC20 asset of the protocol fees swept.
     * @param feeTo The account to which fees were swept.
     * @param amount The total amount swept.
     */
    event FeeSwept(address indexed asset, address indexed feeTo, uint256 amount);

    /**
     * @notice Emitted when protocol fees are enabled or disabled.
     * @param feeTo The address which enabled or disabled fees.
     * @param enabled Whether fees are enabled or disabled.
     */
    event FeeSwitchUpdated(address feeTo, bool enabled);

    //
    // Access control events
    //

    /**
     * @notice Emitted when feeTo address is updated.
     * @param newFeeTo The new feeTo address.
     */
    event FeeToUpdated(address indexed newFeeTo);

    /**
     * @notice Emitted when TokenURIGenerator is updated.
     * @param newTokenURIGenerator The new TokenURIGenerator address.
     */
    event TokenURIGeneratorUpdated(address indexed newTokenURIGenerator);

    /*//////////////////////////////////////////////////////////////
    //  Errors
    //////////////////////////////////////////////////////////////*/

    //
    // Access control errors
    //

    /**
     * @notice The caller doesn't have permission to access that function.
     * @param accessor The requesting address.
     * @param permissioned The address which has the requisite permissions.
     */
    error AccessControlViolation(address accessor, address permissioned);

    //
    // Input errors
    //

    /// @notice The amount of option contracts written must be greater than zero.
    error AmountWrittenCannotBeZero();

    /**
     * @notice This claim is not owned by the caller.
     * @param claimId Supplied claim ID.
     */
    error CallerDoesNotOwnClaimId(uint256 claimId);

    /**
     * @notice The caller does not have enough option contracts to exercise the amount
     * specified.
     * @param optionId The supplied option id.
     * @param amount The amount of option contracts which the caller attempted to exercise.
     */
    error CallerHoldsInsufficientOptions(uint256 optionId, uint112 amount);

    /**
     * @notice Claims cannot be redeemed before expiry.
     * @param claimId Supplied claim ID.
     * @param expiry timestamp at which the option type expires.
     */
    error ClaimTooSoon(uint256 claimId, uint40 expiry);

    /**
     * @notice This option cannot yet be exercised.
     * @param optionId Supplied option ID.
     * @param exercise The time after which the option optionId be exercised.
     */
    error ExerciseTooEarly(uint256 optionId, uint40 exercise);

    /**
     * @notice The option exercise window is too short.
     * @param exercise The timestamp supplied for exercise.
     */
    error ExerciseWindowTooShort(uint40 exercise);

    /**
     * @notice The optionId specified expired has already expired.
     * @param optionId The id of the expired option.
     * @param expiry The expiry time for the supplied option Id.
     */
    error ExpiredOption(uint256 optionId, uint40 expiry);

    /**
     * @notice The expiry timestamp is too soon.
     * @param expiry Timestamp of expiry.
     */
    error ExpiryWindowTooShort(uint40 expiry);

    /**
     * @notice Invalid (zero) address.
     * @param input The address input.
     */
    error InvalidAddress(address input);

    /**
     * @notice The assets specified are invalid or duplicate.
     * @param asset1 Supplied ERC20 asset.
     * @param asset2 Supplied ERC20 asset.
     */
    error InvalidAssets(address asset1, address asset2);

    /**
     * @notice The token specified is not a claim token.
     * @param token The supplied token id.
     */
    error InvalidClaim(uint256 token);

    /**
     * @notice The token specified is not an option token.
     * @param token The supplied token id.
     */
    error InvalidOption(uint256 token);

    /**
     * @notice This option contract type already exists and thus cannot be created.
     * @param optionId The token id of the option type which already exists.
     */
    error OptionsTypeExists(uint256 optionId);

    /**
     * @notice The requested token is not found.
     * @param token The token requested.
     */
    error TokenNotFound(uint256 token);

    /*//////////////////////////////////////////////////////////////
    //  Data Structures
    //////////////////////////////////////////////////////////////*/

    /// @notice The type of an ERC1155 subtoken in the clearinghouse.
    enum TokenType {
        None,
        Option,
        Claim
    }

    /// @notice Data comprising the unique tuple of an option type associated with an ERC-1155 option token.
    struct Option {
        /// @custom:member underlyingAsset The underlying ERC20 asset which the option is collateralized with.
        address underlyingAsset;
        /// @custom:member underlyingAmount The amount of the underlying asset contained within an option contract of this type.
        uint96 underlyingAmount;
        /// @custom:member exerciseAsset The ERC20 asset which the option can be exercised using.
        address exerciseAsset;
        /// @custom:member exerciseAmount The amount of the exercise asset required to exercise each option contract of this type.
        uint96 exerciseAmount;
        /// @custom:member exerciseTimestamp The timestamp after which this option can be exercised.
        uint40 exerciseTimestamp;
        /// @custom:member expiryTimestamp The timestamp before which this option can be exercised.
        uint40 expiryTimestamp;
        /// @custom:member settlementSeed Deterministic seed used for option fair exercise assignment.
        uint160 settlementSeed;
        /// @custom:member nextClaimKey The next claim key available for this option type.
        uint96 nextClaimKey;
    }

    /**
     * @notice Data about a claim to a short position written on an option type.
     * When writing an amount of options of a particular type, the writer will be issued an ERC 1155 NFT
     * that represents a claim to the underlying and exercise assets, to be claimed after
     * expiry of the option. The amount of each (underlying asset and exercise asset) paid to the claimant upon
     * redeeming their claim NFT depends on the option type, the amount of options written, represented in this struct,
     * and what portion of this claim was assigned exercise, if any, before expiry.
     */
    struct Claim {
        /// @custom:member amountWritten The number of option contracts written against this claim expressed as a 1e18 scalar value.
        uint256 amountWritten;
        /// @custom:member amountExercised The amount of option contracts exercised against this claim expressed as a 1e18 scalar value.
        uint256 amountExercised;
        /// @custom:member optionId The option ID of the option type this claim is for.
        uint256 optionId;
    }

    /**
     * @notice Data about the ERC20 assets and liabilities for a given option (long) or claim (short) token,
     * in terms of the underlying and exercise ERC20 tokens.
     */
    struct Position {
        /// @custom:member underlyingAsset The address of the ERC20 underlying asset.
        address underlyingAsset;
        /// @custom:member underlyingAmount The amount, in wei, of the underlying asset represented by this position.
        int256 underlyingAmount;
        /// @custom:member exerciseAsset The address of the ERC20 exercise asset.
        address exerciseAsset;
        /// @custom:member exerciseAmount The amount, in wei, of the exercise asset represented by this position.
        int256 exerciseAmount;
    }

    /*//////////////////////////////////////////////////////////////
    //  Views
    //////////////////////////////////////////////////////////////*/

    //
    // Option information
    //

    /**
     * @notice Gets information about an option.
     * @param tokenId The tokenId of an option or claim.
     * @return optionInfo The Option for the given tokenId.
     */
    function option(uint256 tokenId) external view returns (Option memory optionInfo);

    /**
     * @notice Gets information about a claim.
     * @param claimId The tokenId of the claim.
     * @return claimInfo The Claim for the given claimId.
     */
    function claim(uint256 claimId) external view returns (Claim memory claimInfo);

    /**
     * @notice Gets information about the ERC20 token positions of an option or claim.
     * @param tokenId The tokenId of the option or claim.
     * @return positionInfo The underlying and exercise token positions for the given tokenId.
     */
    function position(uint256 tokenId) external view returns (Position memory positionInfo);

    //
    // Token information
    //

    /**
     * @notice Gets the TokenType for a given tokenId.
     * @dev Option and claim token ids are encoded as follows:
     *
     *   MSb
     *   0000 0000   0000 0000   0000 0000   0000 0000 ┐
     *   0000 0000   0000 0000   0000 0000   0000 0000 │
     *   0000 0000   0000 0000   0000 0000   0000 0000 │ 160b option key, created Option struct hash.
     *   0000 0000   0000 0000   0000 0000   0000 0000 │
     *   0000 0000   0000 0000   0000 0000   0000 0000 │
     *   0000 0000   0000 0000   0000 0000   0000 0000 ┘
     *   0000 0000   0000 0000   0000 0000   0000 0000 ┐
     *   0000 0000   0000 0000   0000 0000   0000 0000 │ 96b auto-incrementing claim key.
     *   0000 0000   0000 0000   0000 0000   0000 0000 ┘
     *                                             LSb
     * This function accounts for that, and whether or not tokenId has been initialized/decommissioned yet.
     * @param tokenId The token id to get the TokenType of.
     * @return typeOfToken The enum TokenType of the tokenId.
     */
    function tokenType(uint256 tokenId) external view returns (TokenType typeOfToken);

    //
    // Fee information
    //

    /**
     * @notice Gets the balance of protocol fees for a given token which have not been swept yet.
     * @param token The token for the un-swept fee balance.
     * @return The balance of un-swept fees.
     */
    function feeBalance(address token) external view returns (uint256);

    /**
     * @notice Gets the protocol fee, expressed in basis points.
     * @return fee The protocol fee.
     */
    function feeBps() external view returns (uint8 fee);

    /**
     * @notice Checks if protocol fees are enabled.
     * @return enabled Whether or not protocol fees are enabled.
     */
    function feesEnabled() external view returns (bool enabled);

    /**
     * @notice Returns the address to which protocol fees are swept.
     * @return The address to which fees are swept.
     */
    function feeTo() external view returns (address);

    /*//////////////////////////////////////////////////////////////
    //  Write Options
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Creates a new option contract type if it doesn't already exist.
     * @dev optionId can be precomputed using
     *  uint160 optionKey = uint160(
     *      bytes20(
     *          keccak256(
     *              abi.encode(
     *                  underlyingAsset,
     *                  underlyingAmount,
     *                  exerciseAsset,
     *                  exerciseAmount,
     *                  exerciseTimestamp,
     *                  expiryTimestamp,
     *                  uint160(0),
     *                  uint96(0)
     *              )
     *          )
     *      )
     *  );
     *  optionId = uint256(optionKey) << OPTION_ID_PADDING;
     * and then tokenType(optionId) == TokenType.Option if the option already exists.
     * @param underlyingAsset The contract address of the ERC20 underlying asset.
     * @param underlyingAmount The amount of underlyingAsset, in wei, collateralizing each option contract.
     * @param exerciseAsset The contract address of the ERC20 exercise asset.
     * @param exerciseAmount The amount of exerciseAsset, in wei, required to exercise each option contract.
     * @param exerciseTimestamp The timestamp after which this option can be exercised.
     * @param expiryTimestamp The timestamp before which this option can be exercised.
     * @return optionId The token id for the new option type created by this call.
     */
    function newOptionType(
        address underlyingAsset,
        uint96 underlyingAmount,
        address exerciseAsset,
        uint96 exerciseAmount,
        uint40 exerciseTimestamp,
        uint40 expiryTimestamp
    ) external returns (uint256 optionId);

    /**
     * @notice Writes a specified amount of the specified option, returning claim NFT id.
     * @param tokenId The desired token id to write against, input an optionId to get a new claim, or a claimId
     * to add to an existing claim.
     * @param amount The desired number of option contracts to write.
     * @return claimId The token id of the claim NFT which was input or created.
     */
    function write(uint256 tokenId, uint112 amount) external returns (uint256 claimId);

    /*//////////////////////////////////////////////////////////////
    //  Redeem Claims
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Redeems a claim NFT, transfers the underlying/exercise tokens to the caller.
     * Can be called after option expiry timestamp (inclusive).
     * @param claimId The ID of the claim to redeem.
     */
    function redeem(uint256 claimId) external;

    /*//////////////////////////////////////////////////////////////
    //  Exercise Options
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Exercises specified amount of optionId, transferring in the exercise asset,
     * and transferring out the underlying asset if requirements are met. Can be called
     * from exercise timestamp (inclusive), until option expiry timestamp (exclusive).
     * @param optionId The option token id of the option type to exercise.
     * @param amount The amount of option contracts to exercise.
     */
    function exercise(uint256 optionId, uint112 amount) external;

    /*//////////////////////////////////////////////////////////////
    //  Protocol Admin
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Enables or disables protocol fees.
     * @param enabled Whether or not protocol fees should be enabled.
     */
    function setFeesEnabled(bool enabled) external;

    /**
     * @notice Nominates a new address to which fees should be swept, requiring
     * the new feeTo address to accept before the update is complete. See also
     * acceptFeeTo().
     * @param newFeeTo The new address to which fees should be swept.
     */
    function setFeeTo(address newFeeTo) external;

    /**
     * @notice Accepts the new feeTo address and completes the update.
     * See also setFeeTo(address newFeeTo).
     */
    function acceptFeeTo() external;

    /**
     * @notice Sweeps fees to the feeTo address if there is more than 1 wei for
     * feeBalance for a given token.
     * @param tokens An array of tokens to sweep fees for.
     */
    function sweepFees(address[] memory tokens) external;

    function setApprovalForAll(address _operator, bool _approved) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.10;

interface IUniswapV3Pool {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
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
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: MIT

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {IAggregatorV3} from "src/interfaces/IAggregatorV3.sol";
import {IStableSwap} from "src/interfaces/swap/IStableSwap.sol";
import {UniswapV2Library} from "src/libraries/UniswapV2Library.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV2Pair} from "src/interfaces/lp/IUniswapV2Pair.sol";

/**
 * @title AssetsPricing
 * @author JonesDAO
 * @notice Helper contract to aggregate the process of fetching prices internally across Metavaults V2 product.
 */
library AssetsPricing {
    //////////////////////////////////////////////////////////
    //                  CONSTANTS
    //////////////////////////////////////////////////////////

    // @notice Chainlink ETH/USD oracle (8 decimals)
    IAggregatorV3 public constant ETH_ORACLE = IAggregatorV3(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);

    // @notice Chainlink USDC/USD oracle (8 decimals)
    IAggregatorV3 public constant USDC_ORACLE = IAggregatorV3(0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3);

    // @notice Chainlink stETH/ETH oracle (18 decimals)
    IAggregatorV3 public constant ST_ETH_ORACLE = IAggregatorV3(0x07C5b924399cc23c24a95c8743DE4006a32b7f2a);

    // @notice Chainlink wstETH/stETH ratio oracle (18 decimals)
    IAggregatorV3 public constant WST_ETH_ORACLE = IAggregatorV3(0xB1552C5e96B312d0Bf8b554186F846C40614a540);

    // @notice Chainlink wstETH/ETH ratio oracle (18 decimals)
    IAggregatorV3 public constant WST_ETH_RATIO_ORACLE = IAggregatorV3(0xb523AE262D20A936BC152e6023996e46FDC2A95D);

    // @notice Curve's 2CRV
    IStableSwap public constant CRV = IStableSwap(0x7f90122BF0700F9E7e1F688fe926940E8839F353);

    // @notice Used to normalize results to 18 decimals
    uint256 private constant STANDARD_DECIMALS = 1e18;

    // @notice Used to normalize USDC functions
    uint256 private constant USDC_DECIMALS = 1e6;

    //////////////////////////////////////////////////////////
    //                  UniV2 VIEW FUNCTIONS
    //////////////////////////////////////////////////////////

    /**
     * @param _lp Pool that will happen the token swap
     * @param _amountIn Amount of tokens that will be swapped
     * @param _tokenIn Received token
     * @param _tokenOut Wanted token
     * @return min amount of tokens with slippage applied
     */
    function getAmountOut(address _lp, uint256 _amountIn, address _tokenIn, address _tokenOut)
        external
        view
        returns (uint256)
    {
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(_lp, _tokenIn, _tokenOut);

        return UniswapV2Library.getAmountOut(_amountIn, reserveA, reserveB);
    }

    /**
     * @param _lp Pool that will happen the token swap
     * @param _amountOut Amount of tokens that we want as result of the swap
     * @param _tokenIn Received token
     * @param _tokenOut Wanted token
     * @return min amount of tokens with slippage applied
     */
    function getAmountIn(address _lp, uint256 _amountOut, address _tokenIn, address _tokenOut)
        external
        view
        returns (uint256)
    {
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(_lp, _tokenIn, _tokenOut);

        return UniswapV2Library.getAmountOut(_amountOut, reserveA, reserveB);
    }

    /**
     * @notice Get an estimation of token0 and token1 from breaking a given amount of LP
     * @param _lp LP token that will be used to simulate
     * @param _liquidityAmount Amount of LP tokens
     * @return Amount of token0
     * @return Amount of token1
     */
    function breakFromLiquidityAmount(address _lp, uint256 _liquidityAmount) public view returns (uint256, uint256) {
        uint256 totalLiquidity = IERC20(_lp).totalSupply();

        IERC20 _tokenA = IERC20(IUniswapV2Pair(_lp).token0());
        IERC20 _tokenB = IERC20(IUniswapV2Pair(_lp).token1());

        uint256 _amountA = (_tokenA.balanceOf(_lp) * _liquidityAmount) / totalLiquidity;
        uint256 _amountB = (_tokenB.balanceOf(_lp) * _liquidityAmount) / totalLiquidity;

        return (_amountA, _amountB);
    }

    /**
     * @notice Get estimation amount of LP tokens that will be received going from token0 or token1
     * @param _lp LP token that will be used to simulate
     * @param _tokenIn token0 or token1
     * @param _tokenAmount Amount of token0 or token1
     * @dev We dont verify it tokenIn is part of the LP because we do it in other parts of the code
     */
    function tokenToLiquidity(address _lp, address _tokenIn, uint256 _tokenAmount) public view returns (uint256) {
        (uint112 reserveA, uint112 reserveB,) = IUniswapV2Pair(_lp).getReserves();
        uint256 totalToken;

        if (_tokenIn == IUniswapV2Pair(_lp).token0()) {
            totalToken = reserveA;
        } else {
            totalToken = reserveB;
        }

        uint256 totalSupply = IERC20(_lp).totalSupply();

        return (totalSupply * _tokenAmount) / (totalToken * 2);
    }

    //////////////////////////////////////////////////////////
    //                  ASSETS PRICING
    //////////////////////////////////////////////////////////

    /**
     * @notice Returns wstETH price quoted in USD
     * @dev Returns value in 8 decimals
     */
    function wstEthPriceInUsd(uint256 amount) external view returns (uint256) {
        (, int256 stEthPrice,,,) = ST_ETH_ORACLE.latestRoundData();
        (, int256 wstEthRatio_,,,) = WST_ETH_ORACLE.latestRoundData();

        uint256 priceInEth = (uint256(stEthPrice) * uint256(wstEthRatio_)) / STANDARD_DECIMALS;

        return (amount * priceInEth) / STANDARD_DECIMALS;
    }

    /**
     * @notice Returns an arbitrary amount of wETH quoted in USD
     * @dev Returns value in 8 decimals
     */
    function ethPriceInUsd(uint256 amount) public view returns (uint256) {
        (, int256 ethPrice,,,) = ETH_ORACLE.latestRoundData();

        return (uint256(ethPrice) * amount) / STANDARD_DECIMALS;
    }

    /**
     * @notice Returns ETH price in USDC
     * @dev Returns value with 6 decimals
     */
    function ethPriceInUsdc(uint256 amount) external view returns (uint256) {
        uint256 ethPriceInUsd_ = ethPriceInUsd(amount * USDC_DECIMALS); // 8 + 6 decimals
        uint256 usdcPriceInUsd_ = usdcPriceInUsd(USDC_DECIMALS); // 8 decimals

        return ethPriceInUsd_ / usdcPriceInUsd_;
    }

    /**
     * @notice Returns wstETH quoted in ETH
     * @dev Returns value with 18 decimals
     */
    function wstEthRatio() external view returns (uint256) {
        (, int256 wstEthRatio_,,,) = WST_ETH_RATIO_ORACLE.latestRoundData();

        return uint256(wstEthRatio_);
    }

    /**
     * @notice Returns USD price of USDC
     * @dev Returns value with 8 decimals
     */
    function usdcPriceInUsd(uint256 amount) public view returns (uint256) {
        (, int256 usdcPrice,,,) = USDC_ORACLE.latestRoundData(); // 8 decimals

        return (uint256(usdcPrice) * amount) / USDC_DECIMALS;
    }

    /**
     * @notice Returns USDC price in ETH
     * @dev Returns value with 18 decimals
     */
    function usdcPriceInEth(uint256 amount) public view returns (uint256) {
        uint256 ethPriceInUsd_ = ethPriceInUsd(STANDARD_DECIMALS); // 8 decimals
        uint256 usdcPriceInUsd_ = usdcPriceInUsd(amount * STANDARD_DECIMALS); // 8 + 18 decimals

        return usdcPriceInUsd_ / ethPriceInUsd_; // 18 decimals
    }

    /**
     * @notice Returns the amount of 2crv that will be received from depositing given amount of USDC
     * @notice Since this is an unbalanced deposit, we may incur some positive or negative slippage
     * @dev 2crv = 18 decimals
     * @return 2crv amount that will be received
     */
    function get2CrvAmountFromDeposit(uint256 _usdcAmount) external view returns (uint256) {
        // First array element is USDC and second USDT, we pass it == true since its a deposit
        // Receive 2crv amount accounting for slippage but not fees
        return CRV.calc_token_amount([_usdcAmount, 0], true);
    }

    /**
     * @notice Returns amount of USDC that will be received by redeeming an amount of 2crv
     * @dev 6 decimals return
     * @return USDC amount
     */
    function getUsdcAmountFromWithdraw(uint256 _2crvAmount) public view returns (uint256) {
        return CRV.calc_withdraw_one_coin(_2crvAmount, 0);
    }

    function getUsdValueFromWithdraw(uint256 _2crvAmount) external view returns (uint256) {
        uint256 usdcAmount = getUsdcAmountFromWithdraw(_2crvAmount);

        return usdcPriceInUsd(usdcAmount);
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {AccessControlUpgradeable} from "openzeppelin-upgradeable-contracts/access/AccessControlUpgradeable.sol";

abstract contract UpgradeableGovernable is AccessControlUpgradeable {
    /**
     * @notice Governor role
     */
    bytes32 public constant GOVERNOR = bytes32("GOVERNOR");

    /**
     * @notice Initialize Governable contract.
     */
    function __Governable_init(address _governor) internal onlyInitializing {
        __AccessControl_init();
        _grantRole(GOVERNOR, _governor);
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
        _revokeRole(GOVERNOR, msg.sender);
        _grantRole(GOVERNOR, _newGovernor);

        emit GovernorUpdated(msg.sender, _newGovernor);
    }

    /**
     * @notice If msg.sender has not Governor role revert.
     */
    function _onlyGovernor() private view {
        if (!hasRole(GOVERNOR, msg.sender)) {
            revert CallerIsNotGovernor();
        }
    }

    event GovernorUpdated(address _oldGovernor, address _newGovernor);

    error CallerIsNotGovernor();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ILpsRegistry} from "src/common/LpsRegistry.sol";

interface ISwap {
    struct SwapInfo {
        ISwap swapper;
        SwapData data;
    }

    struct SwapData {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 slippage;
        bytes externalData;
    }

    function swap(SwapData memory) external returns (uint256);
    function batchSwap(SwapData[] memory) external returns (uint256[] memory);
    function swapTokensToEth(address _token, uint256 _amount) external;
    function swapWethToUSDC(uint256 _amount) external;
    function swapUSDCToWeth(uint256 _amount) external;
    function USDCFromWeth(uint256 _amount) external view returns (uint256);
    function wethFromUSDC(uint256 _amount) external view returns (uint256);
    function USDCFromWethIn(uint256 _amount) external view returns (uint256);
    function wethFromUSDCIn(uint256 _amount) external view returns (uint256);
    function wethFromToken(address _token, uint256 _amount) external view returns (uint256);
    function RawUSDCToWETH(uint256 _amount) external view returns (uint256);
    function lpsRegistry() external view returns (ILpsRegistry);

    event AdapterSwap(
        address indexed swapper,
        address tokenIn,
        address tokenOut,
        address receiver,
        uint256 amountIn,
        uint256 amountOut
    );

    error NotImplemented();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

import {IRouter} from "src/interfaces/IRouter.sol";

interface IFarm {
    function rewardToken() external view returns (IERC20);

    function balance() external view returns (uint256);

    function stake(uint256 _amount) external;

    function unstake(uint256 _amount, address _receiver) external;

    function earned() external view returns (uint256);

    function pendingRewards() external view returns (address[] memory, uint256[] memory);

    function pendingRewardsToLP() external view returns (uint256);

    function claim(address _receiver) external;

    function claimAndStake(IRouter router) external returns (uint256);

    function exit() external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

// Interfaces
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface ILPVault is IERC20 {
    /**
     * @notice get underlying token
     */
    function underlying() external returns (IERC20);
    /**
     * @notice See {IERC4626-deposit}.
     */
    function mint(uint256 _shares, address _receiver) external returns (uint256);
    /**
     * @notice See {IERC4626-deposit}.
     */
    function burn(address _account, uint256 _shares) external;
    /**
     * @notice See {IERC4626-deposit}.
     */
    function previewDeposit(uint256 _assets) external view returns (uint256);
    /**
     * @notice See {IERC4626-deposit}.
     */
    function previewRedeem(uint256 _shares) external view returns (uint256);
    /**
     * @notice get Vault total assets
     */
    function totalAssets() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IStableSwap is IERC20 {
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external returns (uint256);
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount, address receiver)
        external
        returns (uint256);

    function remove_liquidity(uint256 burn_amount, uint256[2] calldata min_amounts)
        external
        returns (uint256[2] memory);
    function remove_liquidity(uint256 burn_amount, uint256[2] calldata min_amounts, address receiver)
        external
        returns (uint256[2] memory);
    function remove_liquidity_one_coin(uint256 burn_amount, int128 i, uint256 min_amount) external returns (uint256);
    function remove_liquidity_one_coin(uint256 burn_amount, int128 i, uint256 min_amount, address receiver)
        external
        returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts, bool is_deposit) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 burn_amount, int128 i) external view returns (uint256);

    function coins(uint256 i) external view returns (address);

    function get_virtual_price() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {IUniswapV2Pair} from "src/interfaces/lp/IUniswapV2Pair.sol";

library SafeMathUniswap {
    /**
     * @notice Safe sum of uint256.
     */
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    /**
     * @notice Safe subtraction of uint256.
     */
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    /**
     * @notice Safe multiplication of uint256.
     */
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

library UniswapV2Library {
    using SafeMathUniswap for uint256;

    /**
     * @notice Returns sorted token addresses, used to handle return values from pairs sorted in this order.
     */
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    /**
     * @notice Fetches and sorts the reserves for a pair.
     */
    function getReserves(address pair, address tokenA, address tokenB)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /**
     * @notice Given some amount of an asset and pair reserves, returns an equivalent amount of the other asset.
     */
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    /**
     * @notice Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
     */
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    /**
     * @notice Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
     */
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountIn)
    {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
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
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Indetifier: MIT
pragma solidity ^0.8.10;

import {UpgradeableGovernable} from "src/common/UpgradeableGovernable.sol";
import {ILpsRegistry} from "src/interfaces/common/ILpsRegistry.sol";

/**
 * @title LpsRegistry
 * @author JonesDAO
 * @notice Contract to store information about tokens and its liquidity pools pairs
 */
contract LpsRegistry is ILpsRegistry, UpgradeableGovernable {
    // underlyingToken -> lpToken
    mapping(address => address) public lpToken;

    // underlyingToken -> poolId
    mapping(address => uint256) public poolID;

    // underlyingToken -> rewardToken
    mapping(address => address) public rewardToken;

    // underlyingToken -> rewardToken
    mapping(address => uint24) public poolFee;

    address private constant SUSHI = 0xd4d42F0b6DEF4CE0383636770eF773390d85c61A;
    address private constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address private constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address private constant SUSHI_LP = 0x3221022e37029923aCe4235D812273C5A42C322d;
    address private constant WETH_USDC_LP = 0x905dfCD5649217c42684f23958568e533C711Aa3;

    function initialize() public initializer {
        __Governable_init(msg.sender);

        lpAddress[SUSHI][WETH] = SUSHI_LP;
        lpAddress[WETH][SUSHI] = SUSHI_LP;
        lpToken[SUSHI] = SUSHI_LP;
        poolID[SUSHI] = 2;
        rewardToken[SUSHI] = address(0);

        poolFee[SUSHI] = 3000;

        lpAddress[WETH][USDC] = WETH_USDC_LP;
        lpAddress[USDC][WETH] = WETH_USDC_LP;
        lpToken[USDC] = WETH_USDC_LP;
        poolID[USDC] = 0;
        rewardToken[USDC] = address(0);

        poolFee[USDC] = 500;
    }

    //////////////////////////////////////////////////////////
    //                  STORAGE
    //////////////////////////////////////////////////////////

    /**
     * @notice Store the LP pair address for a given token0. Use public function to get the LP address for the given route.
     * @dev tokenIn => tokenOut => LP
     */
    mapping(address => mapping(address => address)) private lpAddress;

    //////////////////////////////////////////////////////////
    //                  GOVERNOR FUNCTIONS
    //////////////////////////////////////////////////////////

    /**
     * @notice Populates `lpAddress` for both ways swaps
     * @param _tokenIn Received token
     * @param _tokenOut Wanted token
     * @param _liquidityPool Address of the sushi pool that contains both tokens
     */
    function addWhitelistedLp(
        address _tokenIn,
        address _tokenOut,
        address _liquidityPool,
        address _rewardToken,
        uint256 _poolID,
        uint24 _fee
    ) external onlyGovernor {
        if (_tokenIn == address(0) || _tokenOut == address(0) || _liquidityPool == address(0)) {
            revert ZeroAddress();
        }

        // Add support to both ways swaps since it occurs using same LP
        lpAddress[_tokenIn][_tokenOut] = _liquidityPool;
        lpAddress[_tokenOut][_tokenIn] = _liquidityPool;
        lpToken[_tokenIn] = _liquidityPool;
        poolID[_tokenIn] = _poolID;
        rewardToken[_tokenIn] = _rewardToken;
        poolFee[_tokenIn] = _fee;
    }

    /**
     * @notice Sets 0 values for given LP and path
     * @param _tokenIn token0
     * @param _tokenOut token1
     */
    function removeWhitelistedLp(address _tokenIn, address _tokenOut) external onlyGovernor {
        if (_tokenIn == address(0) || _tokenOut == address(0)) {
            revert ZeroAddress();
        }

        lpAddress[_tokenIn][_tokenOut] = address(0);
        lpAddress[_tokenOut][_tokenIn] = address(0);
        lpToken[_tokenIn] = address(0);
        poolID[_tokenIn] = 0;
        rewardToken[_tokenIn] = address(0);
        poolFee[_tokenIn] = 0;
    }

    function updateGovernor(address _newGovernor) external override(ILpsRegistry, UpgradeableGovernable) onlyGovernor {
        _revokeRole(GOVERNOR, msg.sender);
        _grantRole(GOVERNOR, _newGovernor);

        emit GovernorUpdated(msg.sender, _newGovernor);
    }

    //////////////////////////////////////////////////////////
    //                  VIEW FUNCTIONS
    //////////////////////////////////////////////////////////

    /**
     * @notice Gets the address of the pool that contains the desired tokens
     * @param _tokenIn Received token
     * @param _tokenOut wanted token
     * @return Returns univ2 pool address for the given tokens
     * @dev will revert if there's no pool set for the given tokens
     */
    function getLpAddress(address _tokenIn, address _tokenOut) public view returns (address) {
        address pair = lpAddress[_tokenIn][_tokenOut];

        if (pair == address(0)) {
            revert ZeroAddress();
        }

        return pair;
    }

    error ZeroAddress();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
     * bearer except when using {AccessControl-_setupRole}.
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
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
        if (_initialized < type(uint8).max) {
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

// SPDX-License-Indetifier: MIT
pragma solidity ^0.8.10;

/**
 * @title LpsRegistry
 * @author JonesDAO
 * @notice Contract to store information about tokens and its liquidity pools pairs
 */
interface ILpsRegistry {
    function addWhitelistedLp(
        address _tokenIn,
        address _tokenOut,
        address _liquidityPool,
        address _rewardToken,
        uint256 _poolID,
        uint24 _fee
    ) external;

    function removeWhitelistedLp(address _tokenIn, address _tokenOut) external;

    function getLpAddress(address _tokenIn, address _tokenOut) external view returns (address);

    function lpToken(address _underlyingToken) external view returns (address);

    function poolID(address _underlyingToken) external view returns (uint256);

    function poolFee(address _underlyingToken) external view returns (uint24);

    function rewardToken(address _underlyingToken) external view returns (address);

    function updateGovernor(address _newGovernor) external;

    function initialize() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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