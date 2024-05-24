// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title TimeOracle
/// @author Civilization
/// @notice This contract is used to track periods of time based on a given epoch duration
/// @dev The owner of the contract can change the epoch duration
contract TimeOracle {
    address public owner; // Owner of the contract
    uint public startTime; // Start time of the tracking
    uint public epochDuration; // Duration of each period in seconds
    uint public currentPeriod; // Current periods elapsed from the start

    /// @notice Initializes the contract with a given epoch duration
    /// @param _epochDuration Duration of each period in seconds
    constructor(uint _epochDuration) {
        owner = msg.sender; // Set the deployer as the owner
        startTime = block.timestamp; // Initialization at deployment time
        epochDuration = _epochDuration;
    }

    /// @notice Calculates the start time for current period
    /// @return currentPeriodStartTime The start time for the current period
    function getCurrentPeriod()
        external
        view
        returns (uint currentPeriodStartTime)
    {
        require(
            block.timestamp >= startTime,
            "TimeOracle: Query before start time"
        );

        // Calculate how many periods have passed since the start
        uint period = (block.timestamp - startTime) /
            epochDuration;

        // Calculate the start time for the current period
        currentPeriodStartTime = startTime + period * epochDuration;

        return currentPeriodStartTime;
    }

    /// @notice Allows the owner to set a new epoch duration
    /// @param _newEpochDuration The new epoch duration in seconds
    function setEpochDuration(uint _newEpochDuration) external {
        require(
            msg.sender == owner,
            "TimeOracle: Only owner can change epochDuration"
        );

        // Calculate the current period before changing epochDuration
        currentPeriod += (block.timestamp - startTime) / epochDuration;

        // Update startTime to now
        startTime = block.timestamp;

        // Update epochDuration
        epochDuration = _newEpochDuration;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./interfaces/ICivFund.sol";
import "./CIV-TimeOracle.sol";

////////////////// ERROR CODES //////////////////
/*
    ERR_VG.1 = "Msg.sender is not the Vault";
    ERR_VG.2 = "Nothing to withdraw";
    ERR_VG.3 = "Wait for the previos epoch to settle before requesting withdraw";
*/

contract CivVaultGetter {
    ICivVault public civVault;

    /// @notice Each Strategy time Oracle
    mapping(uint => TimeOracle) public timeOracle;

    modifier onlyVault() {
        require(msg.sender == address(civVault), "ERR_VG.1");
        _;
    }

    constructor(address _civVaultAddress) {
        civVault = ICivVault(_civVaultAddress);
    }

    /// @notice Deploy new Time Oracle for the strategy
    /// @param _id Strategy Id
    /// @param _epochDuration Epoch Duration
    function addTimeOracle(uint _id, uint _epochDuration) external onlyVault {
        timeOracle[_id] = new TimeOracle(_epochDuration);
    }

    /// @notice Set new epochDuration for Strategy
    /// @dev Only the Getter can call this function from timeOracle
    /// @param _id Strategy Id
    /// @param _newEpochDuration new epochDuration
    function setEpochDuration(uint _id, uint _newEpochDuration) public {
        timeOracle[_id].setEpochDuration(_newEpochDuration);
    }

    /**
     * @dev Get the current period for a Strategy
     * @param _id The ID of the Strategy
     * @return currentPeriodStartTime The end time for the current period
     */
    function getCurrentPeriod(
        uint _id
    ) external view returns (uint currentPeriodStartTime) {
        return timeOracle[_id].getCurrentPeriod();
    }

    /**
     * @dev Retrieves the current balance of the user's fund representative token, and liquidity strategy token in a specific strategy.
     * @param _id The ID of the strategy from which to retrieve user balance information.
     * @param _user The user EOA
     * @return representTokenBalance The balance of the user's fund representative token in the given strategy.
     * @return assetTokenBalance The balance of the user's liquidity strategy token in the given strategy.
     * @return representTokenAddress The contract address of the fund representative token in the given strategy.
     * @return assetTokenAddress The contract address of the liquidity strategy token in the given strategy.
     */
    function getUserBalances(
        uint _id,
        address _user
    )
        external
        view
        returns (
            uint representTokenBalance,
            uint assetTokenBalance,
            address representTokenAddress,
            address assetTokenAddress
        )
    {
        representTokenAddress = address(
            civVault.getStrategyInfo(_id).fundRepresentToken
        );
        IERC20 representToken = IERC20(representTokenAddress);
        representTokenBalance = representToken.balanceOf(_user);

        assetTokenAddress = address(civVault.getStrategyInfo(_id).assetToken);
        IERC20 assetToken = IERC20(assetTokenAddress);
        assetTokenBalance = assetToken.balanceOf(_user);

        return (
            representTokenBalance,
            assetTokenBalance,
            representTokenAddress,
            assetTokenAddress
        );
    }

    /// @notice get unclaimed withdrawed token epochs
    /// @param _id Strategy Id
    /// @return _epochs array of unclaimed epochs
    function getUnclaimedTokens(
        uint _id,
        address _user
    ) public view returns (uint) {
        uint lastEpoch = civVault.getUserInfo(_id, _user).lastEpoch;
        require(lastEpoch > 0, "ERR_VG.2");
        EpochInfo memory epoch = civVault.getEpochInfo(_id, lastEpoch);
        require(epoch.VPS > 0, "ERR_VG.3");
        uint withdrawInfo = civVault
            .getUserInfoEpoch(_id, _user, lastEpoch)
            .withdrawInfo;

        return
            (withdrawInfo * epoch.currentWithdrawAssets) /
            epoch.totWithdrawnShares;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct StrategyInfo {
    // Info on each strategy
    IERC20 assetToken; // Address of asset token e.g. USDT
    ICivFundRT fundRepresentToken; // Fund Represent tokens for deposit in the strategy XCIV
    uint fee; // Strategy Fee Amount
    uint entryFee; // Strategy Entry Fee Amount
    uint maxDeposit; // Strategy Max Deposit Amount per Epoch
    uint maxUsers; // Strategy Max User per Epoch
    uint minDeposit; // Strategy Min Deposit Amount
    uint epochDuration; // Duration of an Epoch
    uint feeDuration; // Fee withdraw period
    uint lastFeeDistribution; // Last timestamp of distribution
    uint lastProcessedEpoch; // Last Epoch Processed
    uint watermark; // Fee watermark
    uint pendingFees; // Pending fees that owner can withdraw
    address[] withdrawAddress; // Strategy Withdraw Address
    address investAddress; // Strategy Invest Address
    bool initialized; // Is strategy initialized?
    bool paused; // Flag that deposit is paused or not
}

struct EpochInfo {
    uint totDepositors; // Current depositors of the epoch
    uint totDepositedAssets; // Tot deposited asset in current epoch
    uint totWithdrawnShares; // Tot withdrawn asset in current epoch
    uint VPS; // VPS after rebalancing
    uint netVPS; // Net VPS after rebalancing
    uint newShares; // New shares after rebalancing
    uint currentWithdrawAssets; // Withdrawn asset after rebalancing
    uint epochStartTime; // Epoch start time from time oracle
    uint entryFee; // Entry fee of the epoch
    uint totalFee; // Total fee of the epoch
    uint lastDepositorProcessed; // Last depositor that has recived shares
    uint duration;
}

struct UserInfo {
    uint lastEpoch; // Last withdraw epoch
}

struct UserInfoEpoch {
    uint depositInfo;
    uint feePaid;
    uint withdrawInfo;
    uint depositIndex;
    bool hasDeposited;
}

struct AddStrategyParam {
    IERC20 _assetToken;
    uint _maxDeposit;
    uint _maxUsers;
    uint _minAmount;
    uint _fee;
    uint _entryFee;
    uint _epochDuration;
    uint _feeDuration;
    address _investAddress;
    address[] _withdrawAddresses;
    bool _paused;
}

interface ICivVault {
    function feeBase() external view returns (uint);

    function getStrategyInfo(
        uint _id
    ) external view returns (StrategyInfo memory);

    function getEpochInfo(
        uint _id,
        uint _index
    ) external view returns (EpochInfo memory);

    function getCurrentEpoch(uint _id) external view returns (uint);

    function getUserInfo(
        uint _id,
        address _user
    ) external view returns (UserInfo memory);

    function getUserInfoEpoch(
        uint _id,
        address _user,
        uint _index
    ) external view returns (UserInfoEpoch memory);
}

interface ICivFundRT is IERC20 {
    function decimals() external view returns (uint8);
    function mint(uint _amount) external returns (bool);
    function burn(uint _amount) external returns (bool);
}

interface ICivVaultGetter {
    function getBalanceOfUser(uint, address) external view returns (uint);
    function addTimeOracle(uint, uint) external;
    function setEpochDuration(uint, uint) external;
    function getCurrentPeriod(uint) external view returns (uint);
}

interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint);
    function symbol() external view returns (string memory);
}