// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVotingEscrow} from "../interfaces/IVotingEscrow.sol";
import {IUnshethFarm} from "../interfaces/IUnshethFarm.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BoostStrapArbitrum is ReentrancyGuard {
    // solhint-disable var-name-mixedcase
    IERC20 public immutable USH;

    // USH-ETH Camelot LP Token
    IERC20 public immutable CAMELOT_LP;

    IERC20 public immutable UNSHETH;
    IERC20 public immutable WETH;

    address public constant VD_USH = address(0x69E3877a2A81345BAFD730e3E3dbEF74359988cA);

    address public constant UNSHETH_FARM = address(0x9eFB28060e0c4Ea2538a2B5Ede883E86219182B2);

    // SafeVault
    address public safeVault;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public lockTime;
    uint256 public unshethFarmLockTime;

    uint256 public recoverUserAssetsTime;

    bool public successfulGusherLaunch;

    mapping(address token => uint256 amount) public tokenContributions;

    mapping(address user => mapping(address token => uint256 amount)) public userContributions;

    event AssetsWithdrawnFromVotingEscrowToSafeVault();
    event LockTimeChanged(uint256 newLockTime);
    event SuccessfulGusherLaunchSet();
    event TokenDeposited(address indexed user, address token, uint256 amount);
    event TokenRecovered(address indexed user, address token, uint256 amount);
    event UnshethFarmLockTimeChanged(uint256 newUnshethFarmLockTime);
    event UnshethWithdrawnFromUnshethFarmToSafeVault();

    error AssetStillLockedInVotingEscrow();
    error DepositedUnpermittedToken();
    error EndTimeTooEarly();
    error FarmLockTimeTooHigh();
    error FarmLockTimeTooLow();
    error GusherHasNotLaunchedYet();
    error GusherSuccessfullyLaunchedAssetsAreInProtocol();
    error InsufficientContribution();
    error LockTimeTooLow();
    error NoAssetsToRecover();
    error OnlySafeVault();
    error RecoverTimeHasNotStarted();
    error RecoverTimeTooEarly();
    error SafeVaultAddressZero();
    error SaleHasEnded();
    error SaleHasNotEnded();
    error SaleHasNotStarted();
    error StartTimeOver();

    constructor(
        address _safeVault,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _recoverUserAssetsTime,
        uint256 _lockTime,
        uint256 _unshethFarmLockTime
    ) {
        if (_safeVault == address(0)) revert SafeVaultAddressZero();
        if (_startTime < block.timestamp) revert StartTimeOver();
        if (_endTime <= _startTime) revert EndTimeTooEarly();
        if (_recoverUserAssetsTime <= _endTime) revert RecoverTimeTooEarly();
        if (_lockTime < IVotingEscrow(VD_USH).MINTIME()) revert LockTimeTooLow();
        if (_unshethFarmLockTime < IUnshethFarm(UNSHETH_FARM).lock_time_min()) {
            revert FarmLockTimeTooLow();
        }
        if (_unshethFarmLockTime > IUnshethFarm(UNSHETH_FARM).lock_time_for_max_multiplier()) {
            revert FarmLockTimeTooHigh();
        }
        USH = IERC20(0x51A80238B5738725128d3a3e06Ab41c1d4C05C74);
        WETH = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
        UNSHETH = IERC20(0x0Ae38f7E10A43B5b2fB064B42a2f4514cbA909ef);
        CAMELOT_LP = IERC20(0x855F1b323FdD73AF1e2C075C1F422593624eD0DD);

        safeVault = _safeVault;

        startTime = _startTime;
        endTime = _endTime;
        recoverUserAssetsTime = _recoverUserAssetsTime;

        lockTime = _lockTime;
        unshethFarmLockTime = _unshethFarmLockTime;
    }

    modifier onlySafeVault() {
        if (msg.sender != safeVault) revert OnlySafeVault();
        _;
    }

    modifier withinSaleTime() {
        if (block.timestamp < startTime) revert SaleHasNotStarted();

        if (block.timestamp > endTime) revert SaleHasEnded();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    receive() external payable withinSaleTime nonReentrant {
        uint256 _amount = msg.value;

        tokenContributions[address(WETH)] += _amount;
        userContributions[msg.sender][address(WETH)] += _amount;

        IWETH(address(WETH)).deposit{value: _amount}();

        emit TokenDeposited(msg.sender, address(WETH), _amount);
    }

    /// @dev allows users to deposit whitelisted tokens into the contract. It issues a receipt token
    /// for the user
    /// @param token the token to deposit
    /// @param _amount the amount to deposit
    function depositIntoBooststrap(IERC20 token, uint256 _amount)
        public
        withinSaleTime
        nonReentrant
    {
        // allow only permitted tokens to be deposited
        if (
            address(token) != address(USH) && address(token) != address(WETH)
                && address(token) != address(UNSHETH) && address(token) != address(CAMELOT_LP)
        ) revert DepositedUnpermittedToken();

        if (address(token) == address(UNSHETH)) {
            uint256 minContribUnshETH = 1e16; // 0.01 ETH in wei
            if (_amount < minContribUnshETH) revert InsufficientContribution();
        }

        tokenContributions[address(token)] += _amount;
        userContributions[msg.sender][address(token)] += _amount;

        token.transferFrom(msg.sender, address(this), _amount);

        if (address(token) != address(UNSHETH) && address(token) != address(WETH)) {
            _depositInVD_USHContract(address(token), _amount);
        } else if (address(token) == address(UNSHETH)) {
            _stakeInUnshETHFarm(_amount);
        }

        emit TokenDeposited(msg.sender, address(token), _amount);
    }

    /// @dev find user contributions for all whitelisted tokens. Servers also as a pseudo user's
    /// receipt token balance
    function userTokenContributions(address contributor)
        external
        view
        returns (uint256, uint256, uint256, uint256)
    {
        uint256 ushContributions = userContributions[contributor][address(USH)];
        uint256 wethContributions = userContributions[contributor][address(WETH)];
        uint256 unshethContributions = userContributions[contributor][address(UNSHETH)];
        uint256 CAMELOT_LPContributions = userContributions[contributor][address(CAMELOT_LP)];

        return (ushContributions, wethContributions, unshethContributions, CAMELOT_LPContributions);
    }

    /// @dev allows users to recover their assets if Gusher doesn't launch on a timely manner
    /// @param token the token to recover
    function recoverFromBooststrap(IERC20 token) external nonReentrant {
        if (block.timestamp < recoverUserAssetsTime) revert RecoverTimeHasNotStarted();

        if (successfulGusherLaunch) revert GusherSuccessfullyLaunchedAssetsAreInProtocol();

        // withdraw from voting escrow if it is a token that was sent to it
        if (address(token) != address(UNSHETH) && address(token) != address(WETH)) {
            // if VD_USH global unlock or if token is still locked in voting escrow revert with
            // error
            if (
                IVotingEscrow(VD_USH).unlocked()
                    || block.timestamp <= IVotingEscrow(VD_USH).locked(address(this)).end
            ) revert AssetStillLockedInVotingEscrow();

            IVotingEscrow(VD_USH).withdraw();
        }

        // add check that user has assets in contract or that there are assets to recover in
        // contract
        if (
            userContributions[msg.sender][address(token)] == 0
                || token.balanceOf(address(this)) == 0
        ) revert NoAssetsToRecover();

        uint256 amountToRecover = userContributions[msg.sender][address(token)];

        // update state
        userContributions[msg.sender][address(token)] = 0;
        tokenContributions[address(token)] -= amountToRecover;

        // transfer assets to user
        token.transfer(msg.sender, amountToRecover);

        emit TokenRecovered(msg.sender, address(token), amountToRecover);
    }

    /// @dev allows the safeVault to withdraw all assets from unsheth VotingEscrow contract. Only
    /// SafeVault is allowed
    function withdrawAssetFromUnshethVotingEscrowAndIntoVault() external onlySafeVault {
        uint256 timeStampAllowedToWithdraw = IVotingEscrow(VD_USH).locked(address(this)).end;
        if (block.timestamp < timeStampAllowedToWithdraw) revert AssetStillLockedInVotingEscrow();
        IVotingEscrow(VD_USH).withdraw();

        // transfer assets to safeVault
        USH.transfer(safeVault, USH.balanceOf(address(this)));
        WETH.transfer(safeVault, WETH.balanceOf(address(this)));
        CAMELOT_LP.transfer(safeVault, CAMELOT_LP.balanceOf(address(this)));

        emit AssetsWithdrawnFromVotingEscrowToSafeVault();
    }

    /// @dev allows the safeVault to withdraw all unsheth from unsheth farm contract
    function unstakeUnshethFromFarm() external onlySafeVault {
        if (!successfulGusherLaunch) revert GusherHasNotLaunchedYet();
        if (block.timestamp < endTime) revert SaleHasNotEnded();
        IUnshethFarm.LockedStake[] memory lockedStakes =
            IUnshethFarm(UNSHETH_FARM).lockedStakesOf(address(this));

        uint256 length = lockedStakes.length;

        for (uint256 i; i < length;) {
            IUnshethFarm(UNSHETH_FARM).withdrawLocked(lockedStakes[i].kek_id);

            unchecked {
                ++i;
            }
        }

        // transfer assets to safeVault
        UNSHETH.transfer(safeVault, UNSHETH.balanceOf(address(this)));

        getUnshethFarmReward();

        emit UnshethWithdrawnFromUnshethFarmToSafeVault();
    }

    /// @dev allows the safeVault to withdraw specific unsheth from unsheth farm contract
    /// @param kekId the kekId of the locked stake to withdraw
    function unstakeUnshethFromFarm(bytes32 kekId) external onlySafeVault {
        if (!successfulGusherLaunch) revert GusherHasNotLaunchedYet();
        if (block.timestamp < endTime) revert SaleHasNotEnded();
        IUnshethFarm(UNSHETH_FARM).withdrawLocked(kekId);

        // transfer assets to safeVault
        UNSHETH.transfer(safeVault, UNSHETH.balanceOf(address(this)));

        getUnshethFarmReward();

        emit UnshethWithdrawnFromUnshethFarmToSafeVault();
    }

    /// @dev allows the safeVault to get rewards from unsheth farm contract
    function getUnshethFarmReward() public onlySafeVault {
        IUnshethFarm(UNSHETH_FARM).getReward();

        // rewards in unsheth farm are in USH
        USH.transfer(safeVault, USH.balanceOf(address(this)));
    }

    /// @dev set successfulGusherLaunch to true. Only SafeVault is allowed
    function setSuccessfulGusherLaunch() external onlySafeVault {
        successfulGusherLaunch = true;

        emit SuccessfulGusherLaunchSet();
    }

    /// @dev change lock time for unsheth voting escrow. Only allowed by safeVault
    /// @param _lockTime the new lock time
    function changeLockTime(uint256 _lockTime) external onlySafeVault {
        if (_lockTime < IVotingEscrow(VD_USH).MINTIME()) revert LockTimeTooLow();

        lockTime = _lockTime;

        emit LockTimeChanged(_lockTime);
    }

    /// @dev change lock time for unsheth farm contract
    /// @param _unshethFarmLockTime the new lock time
    function changeUnshethFarmLockTime(uint256 _unshethFarmLockTime) external onlySafeVault {
        if (_unshethFarmLockTime < IUnshethFarm(UNSHETH_FARM).lock_time_min()) {
            revert FarmLockTimeTooLow();
        }

        if (_unshethFarmLockTime > IUnshethFarm(UNSHETH_FARM).lock_time_for_max_multiplier()) {
            revert FarmLockTimeTooHigh();
        }

        unshethFarmLockTime = _unshethFarmLockTime;

        emit UnshethFarmLockTimeChanged(_unshethFarmLockTime);
    }

    /// @dev withdraw stuck assets in the contract. This may be stuck by accident
    /// @param token the token to withdraw
    function withdrawStuckAsset(IERC20 token) external onlySafeVault {
        token.transfer(safeVault, token.balanceOf(address(this)));
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _depositInVD_USHContract(address token, uint256 amount) private {
        if (IVotingEscrow(VD_USH).locked(address(this)).amount == 0) {
            _depositInUnshethVotingEscrow(address(token), amount);
        } else {
            _incrementAmountInUnshethVotingEscrow(address(token), amount);
        }
    }

    function _depositInUnshethVotingEscrow(address token, uint256 amount) private {
        IERC20(token).approve(VD_USH, amount);

        // there is no tokenA in unsheth voting escrow for Arbitrum.
        if (address(token) == address(CAMELOT_LP)) {
            IVotingEscrow(VD_USH).create_lock(0, amount, 0, block.timestamp + lockTime);
        } else if (address(token) == address(USH)) {
            IVotingEscrow(VD_USH).create_lock(0, 0, amount, block.timestamp + lockTime);
        }
    }

    function _incrementAmountInUnshethVotingEscrow(address token, uint256 amount) private {
        IERC20(token).approve(VD_USH, amount);

        if (address(token) == address(CAMELOT_LP)) {
            IVotingEscrow(VD_USH).increase_amount(0, amount, 0);
        } else if (address(token) == address(USH)) {
            IVotingEscrow(VD_USH).increase_amount(0, 0, amount);
        }
    }

    function _stakeInUnshETHFarm(uint256 amount) private {
        IERC20(UNSHETH).approve(address(UNSHETH_FARM), amount);

        IUnshethFarm(UNSHETH_FARM).stakeLocked(amount, unshethFarmLockTime);
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IVotingEscrow {
    struct LockedBalance {
        int128 amount; //weightedAmount
        uint256 amountA;
        uint256 amountB;
        uint256 amountC;
        uint256 end;
    }

    function create_lock(uint256, uint256, uint256, uint256) external;

    function increase_amount(uint256, uint256, uint256) external;

    function add_to_whitelist(address) external;

    function withdraw() external;

    function MINTIME() external view returns (uint256);

    function locked(address) external view returns (LockedBalance memory);

    function unlocked() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IUnshethFarm {
    struct LockedStake {
        bytes32 kek_id;
        uint256 start_timestamp;
        uint256 liquidity;
        uint256 ending_timestamp;
        uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
    }

    function stakeLocked(uint256, uint256) external;

    function getReward() external returns (uint256[] memory);

    function withdrawLocked(bytes32 kek_id) external;

    function lock_time_for_max_multiplier() external view returns (uint256);
    function lock_time_min() external view returns (uint256);

    function lockedStakesOf(address) external view returns (LockedStake[] memory);

    function sync() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}