/**
 *Submitted for verification at Arbiscan.io on 2024-06-15
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC20.sol)

pragma solidity ^0.8.20;


// File: contracts/STIPBIncentivizer.sol


pragma solidity ^0.8.20;


interface IGauge {
    function notifyRewardAmount(address token, uint256 amount) external;

    function notifyRewardAmountNextPeriod(address token, uint256 amount)
        external;
}

interface IVoter {
    function gauges(address pool) external view returns (address gauge);
}

error NotAuthorized();
error Failure();

contract STIPBIncentivizer {
    address public multisig;
    uint256 public weekly;
    mapping(address => bool) authorized;

    IVoter public voter;

    IERC20 public constant ARB =
        IERC20(0x912CE59144191C1204E64559FE8253a0e49E6548);

    modifier onlyAuthorized() {
        if (!authorized[msg.sender]) revert NotAuthorized();
        _;
    }

    event NewWeeklyArbAmount(uint256 _old, uint256 _new);
    event SubmittedIncentives(
        address[] indexed _pools,
        uint256[] indexed _amounts
    );

    constructor(address _multisig, address _voter) {
        multisig = _multisig;
        authorized[msg.sender] = true;
        authorized[_multisig] = true;
        voter = IVoter(_voter);
    }

    ///@notice modifies the weekly variable (amount of ARB to distro) if it is to change
    function setWeekly(uint256 _newWeekly) external onlyAuthorized {
        emit NewWeeklyArbAmount(weekly, _newWeekly);
        weekly = _newWeekly;
    }

    ///@notice submits the ARB incentives to all pools for the upcoming period if they are all concentrated liq
    function sendUpcomingInAdvanceIfAllCl(
        address[] calldata _pools,
        uint256[] calldata _amounts
    ) external onlyAuthorized {
        for (uint256 i = 0; i < _pools.length; ++i) {
            IGauge gauge = IGauge(voter.gauges(_pools[i]));
            ARB.approve(address(gauge), weekly);
            gauge.notifyRewardAmountNextPeriod(address(ARB), _amounts[i]);
        }
        if (ARB.balanceOf(address(this)) > 0)
            ARB.transfer(multisig, ARB.balanceOf(address(this)));

        emit SubmittedIncentives(_pools, _amounts);
    }

    ///@notice submits the ARB incentives to all pools current period
    function submitIncentivesCurrent(
        address[] calldata _pools,
        uint256[] calldata _amounts
    ) external onlyAuthorized {
        for (uint256 i = 0; i < _pools.length; ++i) {
            IGauge gauge = IGauge(voter.gauges(_pools[i]));
            ARB.approve(address(gauge), weekly);
            gauge.notifyRewardAmount(address(ARB), _amounts[i]);
        }
        if (ARB.balanceOf(address(this)) > 0)
            ARB.transfer(multisig, ARB.balanceOf(address(this)));

        emit SubmittedIncentives(_pools, _amounts);
    }

    // backstop
    function execute(address _x, bytes calldata _data) external {
        if (msg.sender != multisig) revert NotAuthorized();
        (bool success, ) = _x.call(_data);
        if (!success) revert Failure();
    }
}