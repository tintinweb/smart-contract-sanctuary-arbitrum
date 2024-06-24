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
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Vester - Vesting Contract
 * @dev A contract for distributing vested tokens over a period of time.
 */
contract Vester {
    string public name; // Name of the vesting contract
    uint256 public constant vestingInterval = 30 days; // 30 days per interval
    uint256 public immutable totalLocked; // Total amount of tokens to be vested
    uint256 public immutable vestingPeriod; // Vesting period in months
    uint256 public vestingsClaimed = 0; // Number of vestings claimed so far
    address public immutable owner; // Address with permissions to claim the token vesting
    uint256[] public vestingSchedule; // Timestamps representing the vesting schedule

    event Withdrawn(address indexed beneficiary, uint256 amount);
    event EmergencyWithdrawn(address indexed beneficiary, uint256 amount);

    /**
     * @dev Contract constructor
     * @param _name The name of the vesting contract
     * @param _totalLocked The total amount of tokens to be vested
     * @param _vestingPeriod The vesting period in months
     * @param _vestingClaimer Address with permissions to claim the token vesting
     * @param _vestingStartMonth The number of months from deployment until vesting starts
     */
    constructor(
        string memory _name,
        uint256 _totalLocked,
        uint256 _vestingPeriod,
        address _vestingClaimer,
        uint8 _vestingStartMonth
    ) {
        // First vesting
        vestingSchedule.push(
            block.timestamp + (vestingInterval * _vestingStartMonth)
        );

        name = _name;
        owner = _vestingClaimer;
        totalLocked = _totalLocked;
        vestingPeriod = _vestingPeriod;

        // Generate vesting schedule for the remaining periods
        for (uint256 i = 1; i < _vestingPeriod; i++) {
            vestingSchedule.push(vestingSchedule[i - 1] + vestingInterval);
        }
    }

    /**
     * @dev Withdraw vested tokens
     * @param _token The address of the ERC-20 token to be withdrawn
     */
    function withdraw(address _token) external {
        require(_token != address(0), "Vester: not valid address");
        require(msg.sender == owner, "Vester: not owner");
        uint256 withdrawableAmount = totalLocked / vestingPeriod;
        IERC20 token = IERC20(_token);

        require(
            block.timestamp >= vestingSchedule[vestingsClaimed],
            "Vester: vesting period has not started"
        );
        require(
            vestingsClaimed < vestingPeriod,
            "Vester: all tokens already withdrawn"
        );

        uint256 currentInterval = vestingSchedule[vestingsClaimed];
        require(
            currentInterval <= block.timestamp,
            "Vester: not enough time has passed"
        );

        require(
            token.balanceOf(address(this)) >= withdrawableAmount,
            "Vester: insufficient balance in the contract"
        );

        vestingsClaimed++;
        token.transfer(owner, withdrawableAmount);
        emit Withdrawn(owner, withdrawableAmount);
    }

    /**
     * @dev Get the remaining locked tokens in the contract
     * @param _token The address of the ERC-20 token
     * @return uint256 The remaining locked tokens
     */
    function remainingLockedTokens(
        address _token
    ) external view returns (uint256) {
        require(_token != address(0), "Vester: not valid address");
        IERC20 token = IERC20(_token);
        return token.balanceOf(address(this));
    }

    /**
     * @dev Get the timestamp of the next vesting schedule
     * @return uint256 The timestamp of the next vesting schedule
     */
    function nextVesting() external view returns (uint256) {
        return vestingSchedule[vestingsClaimed];
    }

    /**
     * @dev Emergency withdraw function to claim any remaining tokens after all vestings are claimed
     * @param _token The address of the ERC-20 token
     */
    function extraWithdraw(address _token) external {
        require(msg.sender == owner, "Vester: not owner");
        require(_token != address(0), "Vester: not valid address");
        require(
            vestingsClaimed == vestingPeriod,
            "Vester: not all vestings are claimed"
        );
        IERC20 token = IERC20(_token);
        uint256 remainingBalance = token.balanceOf(address(this));
        require(remainingBalance > 0, "Vester: no remaining balance");

        token.transfer(owner, remainingBalance);
        emit EmergencyWithdrawn(owner, remainingBalance);
    }
}