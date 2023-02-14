// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

// ====================================================================
// ====================== OffChainAsset.sol ========================
// ====================================================================

/**
 * @title Off Chain Asset
 * @author MAXOS Team - https://maxos.finance/
 * @dev Representation of an off-chain investment
 */
import "../Stabilizer/IStabilizer.sol";
import "../Common/Owned.sol";
import "../Common/ERC20/IERC20Metadata.sol";
import "../Utils/Uniswap/V3/libraries/TransferHelper.sol";

contract OffChainAsset is Owned {
    IERC20Metadata public usdx;

    // Variables
    bool public redeem_mode;
    uint256 public redeem_amount;
    uint256 public redeem_time;
    uint256 public current_value;
    uint256 public valuation_time;
    address public stabilizer;
    address public wallet;

    // Constants
    uint256 private constant DAY_TIMESTAMP = 24 * 60 * 60;

    // Events
    event Deposit(uint256 usdx_amount, uint256 sweep_amount);
    event Withdraw(uint256 amount);
    event Payback(address token, uint256 amount);

    // Errors
    error OnlyStabilizer();
    error OnlyBorrower();
    error SettingDisabled();
    error InvalidToken();
    error NotEnoughAmount();

    constructor(
        address _wallet,
        address _stabilizer,
        address _sweep_address,
        address _usdx_address
    ) Owned(_sweep_address) {
        wallet = _wallet;
        stabilizer = _stabilizer;
        usdx = IERC20Metadata(_usdx_address);
        redeem_mode = false;
    }

    modifier onlyStabilizer() {
        if (msg.sender != stabilizer) revert OnlyStabilizer();
        _;
    }

    modifier onlyBorrower() {
        if (msg.sender != IStabilizer(stabilizer).borrower())
            revert OnlyBorrower();
        _;
    }

    modifier onlySettingEnabled() {
        if (!IStabilizer(stabilizer).settings_enabled())
            revert SettingDisabled();
        _;
    }

    /**
     * @notice Current Value of investment.
     */
    function currentValue() external view returns (uint256) {
        return current_value;
    }

    /**
     * @notice Update wallet to send the investment to.
     * @param _wallet New wallet address.
     */
    function setWallet(address _wallet)
        external
        onlyBorrower
        onlySettingEnabled
    {
        wallet = _wallet;
    }

    /**
     * @notice Deposit stable coins into Off Chain asset.
     * @param usdx_amount USDX Amount of asset to be deposited.
     * @param sweep_amount Sweep Amount of asset to be deposited.
     * @dev tracks the time when current_value was updated.
     */
    function deposit(uint256 usdx_amount, uint256 sweep_amount)
        external
        onlyStabilizer
    {
        TransferHelper.safeTransferFrom(
            address(usdx),
            stabilizer,
            wallet,
            usdx_amount
        );
        TransferHelper.safeTransferFrom(
            address(SWEEP),
            stabilizer,
            wallet,
            sweep_amount
        );

        uint256 sweep_in_usdx = SWEEP.convertToUSDX(sweep_amount);
        current_value += usdx_amount;
        current_value += sweep_in_usdx;
        valuation_time = block.timestamp;

        emit Deposit(usdx_amount, sweep_amount);
    }

    /**
     * @notice Payback stable coins to Stabilizer
     * @param token token address to payback. USDX, SWEEP ...
     * @param amount The amount of usdx to payback.
     */
    function payback(address token, uint256 amount) external {
        if (token != address(SWEEP) && token != address(usdx))
            revert InvalidToken();
        if (token == address(SWEEP)) {
            amount = SWEEP.convertToUSDX(amount);
        }
        if (redeem_amount > amount) revert NotEnoughAmount();

        TransferHelper.safeTransferFrom(
            address(token),
            msg.sender,
            stabilizer,
            amount
        );

        current_value -= amount;
        redeem_mode = false;
        redeem_amount = 0;

        emit Payback(token, amount);
    }

    /**
     * @notice Withdraw usdx tokens from the asset.
     * @param amount The amount to withdraw.
     * @dev tracks the time when current_value was updated.
     */
    function withdraw(uint256 amount) external onlyStabilizer {
        redeem_amount = amount;
        redeem_mode = true;
        redeem_time = block.timestamp;

        emit Withdraw(amount);
    }

    /**
     * @notice Update Value of investment.
     * @param _value New value of investment.
     * @dev tracks the time when current_value was updated.
     */
    function updateValue(uint256 _value) external onlyCollateralAgent {
        current_value = _value;
        valuation_time = block.timestamp;
    }

    /**
     * @notice Withdraw Rewards.
     * @dev this function was added to generate compatibility with On Chain investment.
     */
    function withdrawRewards(address _owner) external {}
    
    function liquidate(address, uint256) external {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
pragma solidity 0.8.16;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)
pragma solidity 0.8.16;

import "./IERC20.sol";

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

// ==========================================================
// ====================== Owned ========================
// ==========================================================

// Primary Author(s)
// MAXOS Team: https://maxos.finance/

import "../Sweep/ISweep.sol";

contract Owned {
    address public sweep_address;
    ISweep public SWEEP;

    // Events
    event SetSweep(address indexed sweep_address);

    // Errors
    error OnlyAdmin();
    error OnlyCollateralAgent();
    error ZeroAddressDetected();

    constructor(address _sweep_address) {
        sweep_address = _sweep_address;
        SWEEP = ISweep(_sweep_address);
    }

    modifier onlyAdmin() {
        if (msg.sender != SWEEP.owner()) revert OnlyAdmin();
        _;
    }

    modifier onlyCollateralAgent() {
        if (msg.sender != SWEEP.collateral_agency())
            revert OnlyCollateralAgent();
        _;
    }

    /**
     * @notice setSweep
     * @param _sweep_address.
     */
    function setSweep(address _sweep_address) external onlyAdmin {
        if (_sweep_address == address(0)) revert ZeroAddressDetected();
        sweep_address = _sweep_address;
        SWEEP = ISweep(_sweep_address);

        emit SetSweep(_sweep_address);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.16;

interface IStabilizer {
    // Getters
    function sweep_borrowed() external view returns (uint256);

    function min_equity_ratio() external view returns (int256);

    function loan_limit() external view returns (uint256);

    function call_time() external view returns (uint256);

    function call_delay() external view returns (uint256);

    function call_amount() external view returns (uint256);

    function borrower() external view returns (address);

    function settings_enabled() external view returns (bool);

    function spread_fee() external view returns (uint256);

    function spread_date() external view returns (uint256);

    function liquidator_discount() external view returns (uint256);

    function liquidatable() external view returns (bool);

    function frozen() external view returns (bool);

    function isDefaulted() external view returns (bool);

    function getCurrentValue() external view returns (uint256);
    
    function getDebt() external view returns (uint256);

    function accruedFee() external view returns (uint256);

    function getJuniorTrancheValue() external view returns (int256);

    function getEquityRatio() external view returns (int256);

    // Setters
    function configure(
        address asset,
        int256 min_equity_ratio,
        uint256 spread_fee,
        uint256 loan_limit,
        uint256 liquidator_discount,
        uint256 call_delay,
        bool liquidatable,
        string calldata link
    ) external;

    function propose() external;

    function reject() external;

    function setFrozen(bool frozen) external;

    function setBorrower(address borrower) external;

    // Actions
    function invest(uint256 amount0, uint256 amount1) external;

    function divest(uint256 usdx_amount) external;

    function buySWEEP(uint256 usdx_amount) external;

    function sellSWEEP(uint256 sweep_amount) external;

    function buy(uint256 usdx_amount, uint256 amount_out_min)
        external
        returns (uint256);

    function sell(uint256 sweep_amount, uint256 amount_out_min)
        external
        returns (uint256);

    function borrow(uint256 sweep_amount) external;

    function repay(uint256 sweep_amount) external;

    function withdraw(address token, uint256 amount) external;

    function collect() external;

    function payFee() external;

    function liquidate() external;

    function marginCall(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

interface ISweep {
    struct Minter {
        uint256 max_amount;
        uint256 minted_amount;
        bool is_listed;
        bool is_enabled;
    }

    function DEFAULT_ADMIN_ADDRESS() external view returns (address);

    function balancer() external view returns (address);

    function treasury() external view returns (address);

    function collateral_agency() external view returns (address);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function isValidMinter(address) external view returns (bool);

    function amm_price() external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function minter_burn_from(uint256 amount) external;

    function minter_mint(address m_address, uint256 m_amount) external;

    function minters(address m_address) external returns (Minter memory);

    function target_price() external view returns (uint256);

    function interest_rate() external view returns (int256);

    function period_time() external view returns (uint256);

    function step_value() external view returns (int256);

    function setInterestRate(int256 interest_rate) external;

    function setTargetPrice(uint256 current_target_price, uint256 next_target_price) external;    

    function startNewPeriod() external;

    function setUniswapOracle(address uniswap_oracle_address) external;

    function setTimelock(address new_timelock) external;

    function symbol() external view returns (string memory);

    function timelock_address() external view returns (address);

    function totalSupply() external view returns (uint256);

    function convertToUSDX(uint256 amount) external view returns (uint256);

    function convertToSWEEP(uint256 amount) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

import "../../../../Common/ERC20/IERC20.sol";

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "STF"
        );
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ST"
        );
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SA"
        );
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "STE");
    }
}