// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/** Imports **/

import "openzeppelin/token/ERC20/IERC20.sol";
import "./interfaces/IVeJoeStaking.sol";
import "./interfaces/IStableJoeStaking.sol";
import "./Errors.sol";

/// @title Governance Joe Token
/// @author Trader Joe
/// @notice Token that sums user's JOE token owned and locked in sJOE and veJOE contracts for governance purposes
contract GovernanceJoe {
    /** Public variables **/

    IERC20 public immutable joeTokenAddress;
    IVeJoeStaking public immutable veJoeAddress;
    IStableJoeStaking public immutable sJoeAddress;

    /** Private variables **/

    string private constant _name = "GovernanceJoe";
    string private constant _symbol = "gJOE";

    /** Constructor **/

    /// @notice Set token and contract addresses
    /// @param _joeTokenAddress The address of JOE token
    /// @param _veJoeAddress The address of veJOE staking contract. Can be set to zero if veJOE is not deployed on the chain
    /// @param _sJoeAddress The address of sJOE staking contract
    constructor(address _joeTokenAddress, address _veJoeAddress, address _sJoeAddress) {
        if (_joeTokenAddress == address(0) || _sJoeAddress == address(0)) {
            revert GovernanceJoe__ZeroAddress();
        }

        joeTokenAddress = IERC20(_joeTokenAddress);
        veJoeAddress = IVeJoeStaking(_veJoeAddress);
        sJoeAddress = IStableJoeStaking(_sJoeAddress);
    }

    /** External View Functions **/

    /// @notice View function to retrieve sum of user's balances
    /// @param account User's address
    /// @return joeTotalBalance Sum of balances for JOE token and JOE staked in veJOE + sJOE contracts of the user
    function balanceOf(address account) public view returns (uint256 joeTotalBalance) {
        joeTotalBalance += _joeBalance(account);
        joeTotalBalance += _veJoeUnderlying(account);
        joeTotalBalance += _sJoeUnderlying(account);

        return joeTotalBalance;
    }

    /// @notice Returns the name of the token.
    function name() public pure returns (string memory) {
        return _name;
    }

    /// @notice Returns the symbol of the token, usually a shorter version of the name
    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    /** Internal Functions **/

    /// @notice View function to retrieve the JOE token balance of an account
    /// @param account User's address
    /// @return JOE token balance of the user
    function _joeBalance(address account) internal view returns (uint256) {
        return joeTokenAddress.balanceOf(account);
    }

    /// @notice View function to retrieve amount of JOE token staked in veJOE contract by an account
    /// @param account User's address
    /// @return JOE locked in veJOE contract by the user
    function _veJoeUnderlying(address account) internal view returns (uint256) {
        if (address(veJoeAddress) == address(0)) {
            return 0;
        }

        IVeJoeStaking.UserInfo memory userInfo = veJoeAddress.userInfos(account);
        return userInfo.balance;
    }

    /// @notice View function to retrieve amount of JOE token staked in sJOE contract by an account
    /// @param account User's address
    /// @return JOE locked in sJOE contract by the user
    function _sJoeUnderlying(address account) internal view returns (uint256) {
        (uint256 amount, ) = sJoeAddress.getUserInfo(account, IERC20(address(0)));
        return amount;
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

pragma solidity 0.8.10;

interface IVeJoeStaking {
    struct UserInfo {
        uint256 balance;
        uint256 rewardDebt;
        uint256 lastClaimTimestamp;
        uint256 speedUpEndTimestamp;
    }

    function userInfos(address account) external view returns (UserInfo memory);

    function deposit(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "openzeppelin/token/ERC20/IERC20.sol";

interface IStableJoeStaking {
    struct UserInfo {
        uint256 amount;
        mapping(IERC20 => uint256) rewardDebt;
    }

    function getUserInfo(address user, IERC20 rewardToken) external view returns (uint256, uint256);

    function deposit(uint256 amount) external;

    function depositFeePercent() external returns (uint256);

    function DEPOSIT_FEE_PERCENT_PRECISION() external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/** GovernanceJoe errors */

error GovernanceJoe__ZeroAddress();