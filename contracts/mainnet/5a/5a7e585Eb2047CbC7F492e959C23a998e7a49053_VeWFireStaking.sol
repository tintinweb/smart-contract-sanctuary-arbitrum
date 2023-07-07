// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./VeWFireToken.sol";
import "./interfaces/IWFIRE.sol";

/// @title Vote Escrow WFire Staking
/// @author Promethios
/// @notice Stake FIRE to earn veWFIRE, which you can use to earn higher farm yields and gain
/// voting power. Note that unstaking any amount of FIRE will burn all of your existing veWFIRE.
contract VeWFireStaking is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Info for each user
    /// `balance`: Amount of FIRE currently staked by user
    /// `rewardDebt`: The reward debt of the user
    /// `lastClaimTimestamp`: The timestamp of user's last claim or withdraw
    /// `speedUpEndTimestamp`: The timestamp when user stops receiving speed up benefits, or
    /// zero if user is not currently receiving speed up benefits
    struct UserInfo {
        uint256 balance;
        uint256 rewardDebt;
        uint256 lastClaimTimestamp;
        uint256 speedUpEndTimestamp;
        /**
         * @notice We do some fancy math here. Basically, any point in time, the amount of veWFIRE
         * entitled to a user but is pending to be distributed is:
         *
         *   pendingReward = pendingBaseReward + pendingSpeedUpReward
         *
         *   pendingBaseReward = (user.balance * accVeWFirePerShare) - user.rewardDebt
         *
         *   if user.speedUpEndTimestamp != 0:
         *     speedUpCeilingTimestamp = min(block.timestamp, user.speedUpEndTimestamp)
         *     speedUpSecondsElapsed = speedUpCeilingTimestamp - user.lastClaimTimestamp
         *     pendingSpeedUpReward = speedUpSecondsElapsed * user.balance * speedUpVeWFirePerSharePerSec
         *   else:
         *     pendingSpeedUpReward = 0
         */
    }

    IERC20Upgradeable public fire;
    IWFIRE public wfire;
    VeWFireToken public veWFire;

    /// @notice The maximum limit of veWFIRE user can have as percentage points of staked FIRE
    /// For example, if user has `n` FIRE staked, they can own a maximum of `n * maxCapPct / 100` veWFIRE.
    uint256 public maxCapPct;

    /// @notice The upper limit of `maxCapPct`
    uint256 public upperLimitMaxCapPct;

    /// @notice The accrued veWFire per share, scaled to `ACC_VEWFIRE_PER_SHARE_PRECISION`
    uint256 public accVeWFirePerShare;

    /// @notice Precision of `accVeWFirePerShare`
    uint256 public ACC_VEWFIRE_PER_SHARE_PRECISION;

    /// @notice The last time that the reward variables were updated
    uint256 public lastRewardTimestamp;

    /// @notice veWFIRE per sec per FIRE staked, scaled to `VEWFIRE_PER_SHARE_PER_SEC_PRECISION`
    uint256 public veWFirePerSharePerSec;

    /// @notice Speed up veWFIRE per sec per FIRE staked, scaled to `VEWFIRE_PER_SHARE_PER_SEC_PRECISION`
    uint256 public speedUpVeWFirePerSharePerSec;

    /// @notice The upper limit of `veWFirePerSharePerSec` and `speedUpVeWFirePerSharePerSec`
    uint256 public upperLimitVeWFirePerSharePerSec;

    /// @notice Precision of `veWFirePerSharePerSec`
    uint256 public VEWFIRE_PER_SHARE_PER_SEC_PRECISION;

    /// @notice Percentage of user's current staked FIRE user has to deposit in order to start
    /// receiving speed up benefits, in parts per 100.
    /// @dev Specifically, user has to deposit at least `speedUpThreshold/100 * userStakedWFire` FIRE.
    /// The only exception is the user will also receive speed up benefits if they are depositing
    /// with zero balance
    uint256 public speedUpThreshold;

    /// @notice The length of time a user receives speed up benefits
    uint256 public speedUpDuration;

    mapping(address => UserInfo) public userInfos;

    uint256 constant MAX_INT =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    event Claim(address indexed user, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event UpdateMaxCapPct(address indexed user, uint256 maxCapPct);
    event UpdateRewardVars(uint256 lastRewardTimestamp, uint256 accVeWFirePerShare);
    event UpdateSpeedUpThreshold(address indexed user, uint256 speedUpThreshold);
    event UpdateVeWFirePerSharePerSec(address indexed user, uint256 veWFirePerSharePerSec);
    event Withdraw(address indexed user, uint256 withdrawAmount, uint256 burnAmount);

    /// @notice Initialize with needed parameters
    /// @param _fire Address of the FIRE token contract
    /// @param _wfire Address of the WFIRE token contract
    /// @param _veWFire Address of the veWFIRE token contract
    /// @param _veWFirePerSharePerSec veWFIRE per sec per FIRE staked, scaled to `VEWFIRE_PER_SHARE_PER_SEC_PRECISION`
    /// @param _speedUpVeWFirePerSharePerSec Similar to `_veWFirePerSharePerSec` but for speed up
    /// @param _speedUpThreshold Percentage of total staked FIRE user has to deposit receive speed up
    /// @param _speedUpDuration Length of time a user receives speed up benefits
    /// @param _maxCapPct Maximum limit of veWFIRE user can have as percentage points of staked FIRE
    function initialize(
        IERC20Upgradeable _fire,
        IWFIRE _wfire,
        VeWFireToken _veWFire,
        uint256 _veWFirePerSharePerSec,
        uint256 _speedUpVeWFirePerSharePerSec,
        uint256 _speedUpThreshold,
        uint256 _speedUpDuration,
        uint256 _maxCapPct
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        require(address(_fire) != address(0), "VeWFireStaking: unexpected zero address for _fire");
        require(
            address(_wfire) != address(0),
            "VeWFireStaking: unexpected zero address for _wfire"
        );
        require(
            address(_veWFire) != address(0),
            "VeWFireStaking: unexpected zero address for _veWFire"
        );

        upperLimitVeWFirePerSharePerSec = 1e36;
        require(
            _veWFirePerSharePerSec <= upperLimitVeWFirePerSharePerSec,
            "VeWFireStaking: expected _veWFirePerSharePerSec to be <= 1e36"
        );
        require(
            _speedUpVeWFirePerSharePerSec <= upperLimitVeWFirePerSharePerSec,
            "VeWFireStaking: expected _speedUpVeWFirePerSharePerSec to be <= 1e36"
        );

        require(
            _speedUpThreshold != 0 && _speedUpThreshold <= 100,
            "VeWFireStaking: expected _speedUpThreshold to be > 0 and <= 100"
        );

        require(
            _speedUpDuration <= 365 days,
            "VeWFireStaking: expected _speedUpDuration to be <= 365 days"
        );

        upperLimitMaxCapPct = 10000000;
        require(
            _maxCapPct != 0 && _maxCapPct <= upperLimitMaxCapPct,
            "VeWFireStaking: expected _maxCapPct to be non-zero and <= 10000000"
        );

        maxCapPct = _maxCapPct;
        speedUpThreshold = _speedUpThreshold;
        speedUpDuration = _speedUpDuration;
        fire = _fire;
        wfire = _wfire;
        veWFire = _veWFire;
        veWFirePerSharePerSec = _veWFirePerSharePerSec;
        speedUpVeWFirePerSharePerSec = _speedUpVeWFirePerSharePerSec;
        lastRewardTimestamp = block.timestamp;
        ACC_VEWFIRE_PER_SHARE_PRECISION = 1e18;
        VEWFIRE_PER_SHARE_PER_SEC_PRECISION = 1e18;
    }

    /// @notice Set maxCapPct
    /// @param _maxCapPct The new maxCapPct
    function setMaxCapPct(uint256 _maxCapPct) external onlyOwner {
        require(
            _maxCapPct > maxCapPct,
            "VeWFireStaking: expected new _maxCapPct to be greater than existing maxCapPct"
        );
        require(
            _maxCapPct != 0 && _maxCapPct <= upperLimitMaxCapPct,
            "VeWFireStaking: expected new _maxCapPct to be non-zero and <= 10000000"
        );
        maxCapPct = _maxCapPct;
        emit UpdateMaxCapPct(_msgSender(), _maxCapPct);
    }

    /// @notice Set veWFirePerSharePerSec
    /// @param _veWFirePerSharePerSec The new veWFirePerSharePerSec
    function setVeWFirePerSharePerSec(uint256 _veWFirePerSharePerSec) external onlyOwner {
        require(
            _veWFirePerSharePerSec <= upperLimitVeWFirePerSharePerSec,
            "VeWFireStaking: expected _veWFirePerSharePerSec to be <= 1e36"
        );
        updateRewardVars();
        veWFirePerSharePerSec = _veWFirePerSharePerSec;
        emit UpdateVeWFirePerSharePerSec(_msgSender(), _veWFirePerSharePerSec);
    }

    /// @notice Set speedUpThreshold
    /// @param _speedUpThreshold The new speedUpThreshold
    function setSpeedUpThreshold(uint256 _speedUpThreshold) external onlyOwner {
        require(
            _speedUpThreshold != 0 && _speedUpThreshold <= 100,
            "VeWFireStaking: expected _speedUpThreshold to be > 0 and <= 100"
        );
        speedUpThreshold = _speedUpThreshold;
        emit UpdateSpeedUpThreshold(_msgSender(), _speedUpThreshold);
    }

    /// @notice Deposits WFIRE to start staking for veWFIRE. Note that any pending veWFIRE
    /// will also be claimed in the process.
    /// @param _amount The amount of WFIRE to deposit
    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, "VeWFireStaking: expected deposit amount to be greater than zero");

        _deposit(_amount);

        IERC20Upgradeable(address(wfire)).safeTransferFrom(_msgSender(), address(this), _amount);
    }

    /// @notice Deposits FIRE to start staking for veWFIRE. Note that any pending veWFIRE
    /// will also be claimed in the process.
    /// @param _fireAmount The amount of FIRE to deposit
    function depositFire(uint256 _fireAmount) external nonReentrant {
        require(_fireAmount > 0, "VeWFireStaking: expected deposit amount to be greater than zero");

        uint256 _amount = (_fireAmount * wfire.MAX_WFIRE_SUPPLY()) / fire.totalSupply();

        _deposit(_amount);

        fire.safeTransferFrom(_msgSender(), address(this), _fireAmount);
        if (fire.allowance(address(this), address(wfire)) < _fireAmount) {
            fire.approve(address(wfire), MAX_INT);
        }
        _amount = wfire.deposit(_fireAmount);
    }

    function getTotalFireStaked() external view returns (uint256 fireAmount, uint256 percent) {
        fireAmount =
            (IERC20Upgradeable(address(wfire)).balanceOf(address(this)) * fire.totalSupply()) /
            wfire.MAX_WFIRE_SUPPLY();
        percent = (fireAmount * 10000) / fire.totalSupply();
    }

    function getUserStakedFire(address user) external view returns (uint256 fireAmount) {
        fireAmount = (userInfos[user].balance * fire.totalSupply()) / wfire.MAX_WFIRE_SUPPLY();
    }

    function _deposit(uint256 _amount) internal {
        updateRewardVars();

        UserInfo storage userInfo = userInfos[_msgSender()];

        if (_getUserHasNonZeroBalance(_msgSender())) {
            // Transfer to the user their pending veWFIRE before updating their UserInfo
            _claim();

            // We need to update user's `lastClaimTimestamp` to now to prevent
            // passive veWFIRE accrual if user hit their max cap.
            userInfo.lastClaimTimestamp = block.timestamp;

            uint256 userStakedWFire = userInfo.balance;

            // User is eligible for speed up benefits if `_amount` is at least
            // `speedUpThreshold / 100 * userStakedWFire`
            if (_amount * 100 >= speedUpThreshold * userStakedWFire) {
                userInfo.speedUpEndTimestamp = block.timestamp + speedUpDuration;
            }
        } else {
            // If user is depositing with zero balance, they will automatically
            // receive speed up benefits
            userInfo.speedUpEndTimestamp = block.timestamp + speedUpDuration;
            userInfo.lastClaimTimestamp = block.timestamp;
        }

        userInfo.balance = userInfo.balance + _amount;
        userInfo.rewardDebt =
            (accVeWFirePerShare * userInfo.balance) /
            ACC_VEWFIRE_PER_SHARE_PRECISION;

        emit Deposit(_msgSender(), _amount);
    }

    /// @notice Withdraw staked FIRE. Note that unstaking any amount of FIRE means you will
    /// lose all of your current veWFIRE.
    /// @param _amount The amount of WFIRE to unstake
    /// @param _unwrap unwrap wfire or not
    function withdraw(uint256 _amount, bool _unwrap) external {
        require(_amount > 0, "VeWFireStaking: expected withdraw amount to be greater than zero");

        UserInfo storage userInfo = userInfos[_msgSender()];

        require(
            userInfo.balance >= _amount,
            "VeWFireStaking: cannot withdraw greater amount of WFIRE than currently staked"
        );
        updateRewardVars();

        // Note that we don't need to claim as the user's veWFIRE balance will be reset to 0
        userInfo.balance = userInfo.balance - _amount;
        userInfo.rewardDebt =
            (accVeWFirePerShare * userInfo.balance) /
            ACC_VEWFIRE_PER_SHARE_PRECISION;
        userInfo.lastClaimTimestamp = block.timestamp;
        userInfo.speedUpEndTimestamp = 0;

        // Burn the user's current veWFIRE balance
        uint256 userVeWFireBalance = veWFire.balanceOf(_msgSender());
        veWFire.burnFrom(_msgSender(), userVeWFireBalance);

        // Send user their requested amount of staked FIRE
        if (_unwrap) {
            uint256 fireAmount = wfire.burn(_amount);
            fire.safeTransfer(_msgSender(), fireAmount);
        } else {
            IERC20Upgradeable(address(wfire)).safeTransfer(_msgSender(), _amount);
        }

        emit Withdraw(_msgSender(), _amount, userVeWFireBalance);
    }

    /// @notice Claim any pending veWFIRE
    function claim() external {
        require(
            _getUserHasNonZeroBalance(_msgSender()),
            "VeWFireStaking: cannot claim veWFIRE when no WFIRE is staked"
        );
        updateRewardVars();
        _claim();
    }

    /// @notice Get the pending amount of veWFIRE for a given user
    /// @param _user The user to lookup
    /// @return The number of pending veWFIRE tokens for `_user`
    function getPendingVeWFire(address _user) public view returns (uint256) {
        if (!_getUserHasNonZeroBalance(_user)) {
            return 0;
        }

        UserInfo memory user = userInfos[_user];

        // Calculate amount of pending base veWFIRE
        uint256 _accVeWFirePerShare = accVeWFirePerShare;
        uint256 secondsElapsed = block.timestamp - lastRewardTimestamp;
        if (secondsElapsed > 0) {
            _accVeWFirePerShare =
                _accVeWFirePerShare +
                (secondsElapsed * veWFirePerSharePerSec * ACC_VEWFIRE_PER_SHARE_PRECISION) /
                VEWFIRE_PER_SHARE_PER_SEC_PRECISION;
        }
        uint256 pendingBaseVeWFire = (_accVeWFirePerShare * user.balance) /
            ACC_VEWFIRE_PER_SHARE_PRECISION -
            user.rewardDebt;

        // Calculate amount of pending speed up veWFIRE
        uint256 pendingSpeedUpVeWFire;
        if (user.speedUpEndTimestamp != 0) {
            uint256 speedUpCeilingTimestamp = block.timestamp > user.speedUpEndTimestamp
                ? user.speedUpEndTimestamp
                : block.timestamp;
            uint256 speedUpSecondsElapsed = speedUpCeilingTimestamp - user.lastClaimTimestamp;
            uint256 speedUpAccVeWFirePerShare = speedUpSecondsElapsed *
                speedUpVeWFirePerSharePerSec;
            pendingSpeedUpVeWFire =
                (speedUpAccVeWFirePerShare * user.balance) /
                VEWFIRE_PER_SHARE_PER_SEC_PRECISION;
        }

        uint256 pendingVeWFire = pendingBaseVeWFire + pendingSpeedUpVeWFire;

        // Get the user's current veWFIRE balance
        uint256 userVeWFireBalance = veWFire.balanceOf(_user);

        // This is the user's max veWFIRE cap multiplied by 100
        uint256 scaledUserMaxVeWFireCap = user.balance * maxCapPct;

        if (userVeWFireBalance * 100 >= scaledUserMaxVeWFireCap) {
            // User already holds maximum amount of veWFIRE so there is no pending veWFIRE
            return 0;
        } else if ((userVeWFireBalance + pendingVeWFire) * 100 > scaledUserMaxVeWFireCap) {
            return (scaledUserMaxVeWFireCap - userVeWFireBalance * 100) / 100;
        } else {
            return pendingVeWFire;
        }
    }

    /// @notice Update reward variables
    function updateRewardVars() public {
        if (block.timestamp <= lastRewardTimestamp) {
            return;
        }

        if (IERC20Upgradeable(address(wfire)).balanceOf(address(this)) == 0) {
            lastRewardTimestamp = block.timestamp;
            return;
        }

        uint256 secondsElapsed = block.timestamp - lastRewardTimestamp;
        accVeWFirePerShare =
            accVeWFirePerShare +
            (secondsElapsed * veWFirePerSharePerSec * ACC_VEWFIRE_PER_SHARE_PRECISION) /
            VEWFIRE_PER_SHARE_PER_SEC_PRECISION;
        lastRewardTimestamp = block.timestamp;

        emit UpdateRewardVars(lastRewardTimestamp, accVeWFirePerShare);
    }

    /// @notice Checks to see if a given user currently has staked FIRE
    /// @param _user The user address to check
    /// @return Whether `_user` currently has staked FIRE
    function _getUserHasNonZeroBalance(address _user) private view returns (bool) {
        return userInfos[_user].balance > 0;
    }

    /// @dev Helper to claim any pending veWFIRE
    function _claim() private {
        uint256 veWFireToClaim = getPendingVeWFire(_msgSender());

        UserInfo storage userInfo = userInfos[_msgSender()];

        userInfo.rewardDebt =
            (accVeWFirePerShare * userInfo.balance) /
            ACC_VEWFIRE_PER_SHARE_PRECISION;

        // If user's speed up period has ended, reset `speedUpEndTimestamp` to 0
        if (userInfo.speedUpEndTimestamp != 0 && block.timestamp >= userInfo.speedUpEndTimestamp) {
            userInfo.speedUpEndTimestamp = 0;
        }

        if (veWFireToClaim > 0) {
            userInfo.lastClaimTimestamp = block.timestamp;

            veWFire.mint(_msgSender(), veWFireToClaim);
            emit Claim(_msgSender(), veWFireToClaim);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./VeERC20.sol";

interface IRewarder {
    function updateFactor(address, uint256) external;
}

/// @title Vote Escrow WFIRE Token - veWFIRE
/// @author Promethios
/// @notice Infinite supply, used to receive extra farming yields and voting power
contract VeWFireToken is VeERC20("VeWFireToken", "veWFIRE"), Ownable {
    /// @notice rewarders contracts including the BoostedMasterChef contract
    IRewarder[] public rewarders;

    mapping(address => bool) public isOperator;

    event UpdateRewarders(address indexed user, IRewarder[] rewarders);

    /// @dev Creates `_amount` token to `_to`. Must only be called by the owner (VeWFireStaking)
    /// @param _to The address that will receive the mint
    /// @param _amount The amount to be minted
    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    /// @dev Destroys `_amount` tokens from `_from`. Callable only by the owner (VeWFireStaking)
    /// @param _from The address that will burn tokens
    /// @param _amount The amount to be burned
    function burnFrom(address _from, uint256 _amount) external onlyOwner {
        _burn(_from, _amount);
    }

    function setOperator(address operator, bool _is) external onlyOwner {
        isOperator[operator] = _is;
    }

    /// @dev Sets the address of the master chef contract this updates
    /// @param _rewarders the addresses of Rewarder contracts
    function setRewarders(IRewarder[] calldata _rewarders) external {
        require(isOperator[msg.sender], "Not operator");

        delete rewarders;
        // We allow 0 address here if we want to disable the callback operations
        for (uint256 index = 0; index < _rewarders.length; index++) {
            rewarders.push(_rewarders[index]);
        }

        emit UpdateRewarders(_msgSender(), rewarders);
    }

    function _afterTokenOperation(address _account, uint256 _newBalance) internal override {
        for (uint256 index = 0; index < rewarders.length; index++) {
            IRewarder rewarder = rewarders[index];
            if (address(rewarder) != address(0)) {
                rewarder.updateFactor(_account, _newBalance);
            }
        }
    }

    function renounceOwnership() public override onlyOwner {
        revert("VeWFireToken: Cannot renounce, can only transfer ownership");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

interface IWFIRE {
    function deposit(uint256 fires) external returns (uint256);

    function burn(uint256 wfires) external returns (uint256);

    function MAX_WFIRE_SUPPLY() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";

import "./interfaces/IVeERC20.sol";

/// @title VeERC20
/// @notice Modified version of ERC20 where transfers and allowances are disabled.
/// @dev Only minting and burning are allowed. The hook `_beforeTokenOperation` and
/// `_afterTokenOperation` methods are called before and after minting/burning respectively.
contract VeERC20 is Context, IVeERC20 {
    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /// @dev Emitted when `value` tokens are burned and minted
    event Burn(address indexed account, uint256 value);
    event Mint(address indexed beneficiary, uint256 value);

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenOperation(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Mint(account, amount);

        _afterTokenOperation(account, _balances[account]);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenOperation(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Burn(account, amount);

        _afterTokenOperation(account, _balances[account]);
    }

    /**
     * @dev Hook that is called before any minting and burning.
     * @param from the account transferring tokens
     * @param to the account receiving tokens
     * @param amount the amount being minted or burned
     */
    function _beforeTokenOperation(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any minting and burning.
     * @param account the account being affected
     * @param newBalance the new balance of `account` after minting/burning
     */
    function _afterTokenOperation(address account, uint256 newBalance) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/// @title Vote Escrow ERC20 Token Interface
/// @author Promethios
/// @notice Interface of a ERC20 token used for vote escrow. Notice that transfers and
/// allowances are disabled
interface IVeERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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
interface IERC20PermitUpgradeable {
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