// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./libraries/math/SafeMath.sol";
import "./libraries/token/IERC20.sol";
import "./libraries/token/SafeERC20.sol";
import "./libraries/utils/ReentrancyGuard.sol";
import "./libraries/utils/Address.sol";

import "./tokens/interfaces/IWETH.sol";
import "./interfaces/IRewardTracker.sol";
import "./interfaces/ILockTracker.sol";
import "./interfaces/ILpRewardTracker.sol";
import "./interfaces/IUtpRewardTracker.sol";
import "./interfaces/IPositionTracker.sol";
import "./interfaces/IVester.sol";
import "./interfaces/ILpVester.sol";
import "./interfaces/IPeriphery.sol";
import "./tokens/interfaces/IMintable.sol";
import "./libraries/access/Governable.sol";


contract RewardRouter is ReentrancyGuard, Governable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    struct ConfigParamInternal {
        address weth;
        address yfx;
        address iYfx;
        address mpYfx;
        address utp;
        address urp;
        address stakedYfxTracker;
        address bonusYfxTracker;
        address feeYfxTracker;
        address yfxLpTracker;
        address feeLpTracker;
        address stakedLpTracker;
        address stakedUtpTracker;
        address yfxVester;
        address lpVester;
        address utpVester;
        address router;
        address periphery;
    }


    bool public available;

    address public weth;                // WETH address
    address public yfx;                 // yfx token address
    address public iYfx;                // immature yfx token address
    address public mpYfx;               // multiplier point yfx token address
    address public utp;                 // Unified Trading value Proof
    address public urp;                 // Unified Referral value Proof

    // trackers are stake-reward basic contracts, users deposit stake tokens, get a proof token and earn possible reward tokens
    // we donate trackers as (deposit tokens, proof token, possible reward tokens)
    address public stakedYfxTracker;    // yfx stake tracker, ([YFX, iYFX], sYFX, iYFX)
    address public bonusYfxTracker;     // sYFX stake tracker, (sYFX, sbYFX, mpYFX)
    address public feeYfxTracker;       // sbYFX stake tracker, ([sbYFX, mpYFX], sbfYFX, fee)

    
    address public feeLpTracker;        // yfx lp token stake tracker for fee, (lp token, Flp, fee)
    address public yfxLpTracker;        // yfx lp token stake tracker for yfx, (flp, yfxLp, yfx)
    address public stakedLpTracker;     // flp token stake tracker, (yfxLp, stakedFlp, iYFX)

    address public stakedUtpTracker;    // utp token stake tracker, (utp, sUtp, [YFX, iYFX, fee])

    address public yfxVester;           // yfx vester, convert iYFX to YFX by reserving sbfYFX (yfx + iyfx + mpyfx)
    address public lpVester;            // yfx vester, convert iFYX to YFX by reserving stakedFlp
    address public utpVester;           // yfx vester, convert iFYX to YFX by reserving urp

    address public locker;              // lock yfx tracker
    address public lpLocker;            // lock yfx for UniSwap Lp tracker

    address public exRouter;
    address public periphery;

    address[] public positionMarkets;
    // market => tracker
    mapping(address => address) public positionTrackerList; 

    event StakeYfx(address account, address token, uint256 amount);
    event UnstakeYfx(address account, address token, uint256 amount);

    event ClaimedYFX(address account, uint32 period, uint256 claimedAmount, uint256 burnedAmount, uint256 lockedAmount);

    event StakeLp(address lp, address account, uint256 amount);
    event UnstakeLp(address lp, address account, uint256 amount);

    event StakeUtp(address account, uint256 amount);
    event UnstakeUtp(address account, uint256 amount);

    event AddMarket(address market, address tracker);
    event RemoveMarket(address market);

    event StakedPosition(address account, address market, uint256 amount);
    event UnstakedPosition(address account, address market, uint256 amount);

    receive() external payable {                                                                               
        require(msg.sender == weth, "RewardRouter: invalid sender");
    }

    modifier onlyExRouter() {
        require(msg.sender == exRouter, "RewardTracker: only onlyExRouter");
        _;
    }
    
    function initialize(
        ConfigParamInternal memory config
    ) external onlyGov {
        available = true;
        
        weth = config.weth;

        yfx = config.yfx;
        iYfx = config.iYfx;
        mpYfx = config.mpYfx;

        utp = config.utp;
        urp = config.urp;

        stakedYfxTracker = config.stakedYfxTracker;
        bonusYfxTracker = config.bonusYfxTracker;
        feeYfxTracker = config.feeYfxTracker;

        yfxLpTracker = config.yfxLpTracker;
        feeLpTracker = config.feeLpTracker;
        stakedLpTracker = config.stakedLpTracker;

        stakedUtpTracker = config.stakedUtpTracker;

        yfxVester = config.yfxVester;
        lpVester = config.lpVester;
        utpVester = config.utpVester;

        exRouter = config.router;
        periphery = config.periphery;
    }

    function setLockers(address _locker, address _lpLocker) external onlyGov {
        locker = _locker;
        lpLocker = _lpLocker;
    }

    function abandon() external onlyGov {
        available = false;
    }

    function checkStatus() public view {
        require(available, "RewardRouter: abandoned");
    }

    function setExRouter(address _exRouter) external onlyGov {
        exRouter = _exRouter;
    }

    function withdrawToken(address _token, address _account, uint256 _amount) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function modifierUtpTracker(address _utpTracker) external onlyGov {
        stakedUtpTracker = _utpTracker;
    }

    function addPositionTrackerList(address _market, address _tracker) external onlyGov {
        require(_market != address(0) && _tracker != address(0), "RewardRouter: params error");
        if (positionTrackerList[_market] != address(0)) return; 
        positionTrackerList[_market] = _tracker;
        positionMarkets.push(_market);
        emit AddMarket(_market, _tracker);
    }

    function removePositionTrackerList(address _market) external onlyGov {
        require(_market != address(0), "RewardRouter: params error");
        if (positionTrackerList[_market] != address(0)) {
            delete positionTrackerList[_market];
            uint256 len = positionMarkets.length;
            for (uint256 i=0; i < len; i++) {
                if (positionMarkets[i] == _market) {
                    positionMarkets[i] = positionMarkets[len-1];
                    positionMarkets.pop();
                }
            }
            emit RemoveMarket(_market);
        }
    }

    function getPositionMarkets() public view returns(address[] memory) {
        return positionMarkets;
    }

    function modifyStakedPosition(address _market, address _account, bool _isClearAll) public onlyExRouter nonReentrant {
        checkStatus();
        address tracker = positionTrackerList[_market];
        if (tracker == address(0)) return;

        IPeriphery.Position[] memory positions = IPeriphery(periphery).getAllPosition(_market, _account);
        uint256 size = positions[0].amount;
        if (positions[1].amount != 0)
            size = size.add(positions[1].amount);
        
        if (size > 0) size = size.div(1e14);
        uint256 depositAmount = IPositionTracker(tracker).depositAmount(_account);

        if (_isClearAll && IPeriphery(periphery).getPositionMode(_market, _account) == IPeriphery.PositionMode.OneWay) { 
            uint256 amount = IPositionTracker(tracker).unstakeForAccount(_account, _account, type(uint256).max, _account);
            emit UnstakedPosition(_account, _market, amount);
            depositAmount = 0;
        }

        
        if (depositAmount == size) return;
        if (depositAmount > size) {
            uint256 amount = IPositionTracker(tracker).unstakeForAccount(_account, _account, depositAmount.sub(size), _account);
            emit UnstakedPosition(_account, _market, amount);
        }
        else {
            size = size.sub(depositAmount);
            IPositionTracker(tracker).stakeForAccount(_account, _account, _account, size);
            emit StakedPosition(_account, _market, size);
        }
    }

    function claimPositionRewards(address _market, uint32 _period) public nonReentrant {
        checkStatus();
        address tracker = positionTrackerList[_market];
        if (tracker == address(0)) return;
        (address[] memory rewards, uint256[] memory amounts) = IPositionTracker(tracker).claimForAccount(msg.sender, address(this));
        uint256 len = rewards.length;
        uint256 yfxReward = 0;
        for (uint256 i=0; i<len; i++) {
            if (amounts[i] == 0) continue;
            if (rewards[i] == yfx && locker != address(0)) {
                yfxReward = yfxReward.add(amounts[i]);
            }
            else {
                IERC20(rewards[i]).safeTransfer(msg.sender, amounts[i]);
            }
        }
        if (yfxReward > 0) _claimAndLockYfx(msg.sender, _period, yfxReward);
    }

    function batchStakeYfxForAccount(address[] memory _accounts, uint256[] memory _amounts) external nonReentrant onlyGov {
        checkStatus();
        for (uint256 i = 0; i < _accounts.length; i++) {
            _stakeYfx(msg.sender, _accounts[i], yfx, _amounts[i]);
        }
    }

    function stakeYfxForAccount(address _account, uint256 _amount) external nonReentrant onlyGov {
        checkStatus();
        _stakeYfx(msg.sender, _account, yfx, _amount);
    }

    function stakeYfx(uint256 _amount) external nonReentrant {
        checkStatus();
        _stakeYfx(msg.sender, msg.sender, yfx, _amount);
    }

    function stakeIYfx(uint256 _amount) external nonReentrant {
        checkStatus();
        _stakeYfx(msg.sender, msg.sender, iYfx, _amount);
    }

    function unstakeYfx(uint256 _amount) external nonReentrant {
        checkStatus();
        _unstakeYfx(msg.sender, yfx, _amount, true);
    }

    function unstakeIYfx(uint256 _amount) external nonReentrant {
        checkStatus();
        _unstakeYfx(msg.sender, iYfx, _amount, true);
    }

    function lockYfx(uint256 _amount, uint32 _period) external nonReentrant {
        checkStatus();
        ILockTracker(locker).lockForAccount(msg.sender, msg.sender, _period, _amount);
    }

    function unlockYfx(uint256 _id) public nonReentrant returns(uint256 amount) {
        checkStatus();
        amount = ILockTracker(locker).unlockForAccount(msg.sender, _id, msg.sender);
    }

    function lockLp(uint256 _lpId, uint32 _period) external nonReentrant {
        checkStatus();
        ILockTracker(lpLocker).lockUniLpForAccount(msg.sender, msg.sender, _lpId, _period);
    }

    function unlockLp(uint256 _id) external nonReentrant {
        checkStatus();
        ILockTracker(lpLocker).unlockUniLpForAccount(msg.sender, _id, msg.sender);
    }

    function claimLockReward() public nonReentrant returns(uint256 amount) {
        checkStatus();
        return ILockTracker(locker).claimForAccount(msg.sender, msg.sender);
    }

    function claimLpLockReward(uint32 _period) public nonReentrant returns(uint256 amount) {
        checkStatus();
        amount = ILockTracker(lpLocker).claimForAccount(msg.sender, msg.sender);
        if (locker != address(0)) {
            _claimAndLockYfx(msg.sender, _period, amount);
        }
        else {
            IERC20(yfx).safeTransfer(msg.sender, amount);
        }
    }

    function stakeLp(address _lp, uint256 _amount) external nonReentrant returns (uint256) {
        checkStatus();
        require(_amount > 0, "RewardRouter: invalid amount");
        
        address account = msg.sender;
        ILpRewardTracker(feeLpTracker).stakeForAccount(_lp, account, account, _amount);
        address proof = ILpRewardTracker(feeLpTracker).proofToken(_lp);
        ILpRewardTracker(yfxLpTracker).stakeForAccount(
            proof, account, account, _amount
        );
        ILpRewardTracker(stakedLpTracker).stakeForAccount(
            ILpRewardTracker(yfxLpTracker).proofToken(proof), account, account, _amount
        );

        emit StakeLp(_lp, account, _amount);

        return _amount;
    }

    function unstakeLp(address _lp, uint256 _amount) external nonReentrant returns (uint256) {
        checkStatus();
        require(_amount > 0, "RewardRouter: invalid lpAmount");

        address account = msg.sender;
        address proof = ILpRewardTracker(feeLpTracker).proofToken(_lp);
        ILpRewardTracker(stakedLpTracker).unstakeForAccount(
            ILpRewardTracker(yfxLpTracker).proofToken(proof), account, account, _amount
        );
        ILpRewardTracker(yfxLpTracker).unstakeForAccount(proof, account, account, _amount);
        ILpRewardTracker(feeLpTracker).unstakeForAccount(_lp, account, account, _amount);

        emit UnstakeLp(_lp, account, _amount);

        return _amount;
    }

    function stakeLpForAccount(
        address _account, address _lp, uint256 _amount
    ) external nonReentrant onlyExRouter returns (uint256) {
        checkStatus();
        require(_amount > 0, "RewardRouter: invalid amount");
        
        ILpRewardTracker(feeLpTracker).stakeForAccount(_lp, _account, _account, _amount);
        address proof = ILpRewardTracker(feeLpTracker).proofToken(_lp);
        ILpRewardTracker(yfxLpTracker).stakeForAccount(
            proof, _account, _account, _amount
        );
        ILpRewardTracker(stakedLpTracker).stakeForAccount(
            ILpRewardTracker(yfxLpTracker).proofToken(proof), _account, _account, _amount
        );
        emit StakeLp(_lp, _account, _amount);

        return _amount;
    }

    function unstakeLpForAccount(
        address _account, address _lp, uint256 _amount, bool isLiquidate
    ) public nonReentrant onlyExRouter returns (uint256) {
        checkStatus();
        if (_amount == 0) return 0;
        address fProof = ILpRewardTracker(feeLpTracker).proofToken(_lp);
        address yfxProof = ILpRewardTracker(yfxLpTracker).proofToken(fProof);
        address sfProof = ILpRewardTracker(stakedLpTracker).proofToken(yfxProof);
        if (isLiquidate) 
            ILpVester(lpVester).liquidateLp(_account, sfProof);
        uint256 stakedAmount = ILpRewardTracker(feeLpTracker).depositBalances(_account, _lp);
        _amount = stakedAmount < _amount ? stakedAmount : _amount;
        ILpRewardTracker(stakedLpTracker).unstakeForAccount(yfxProof, _account, _account, _amount);
        ILpRewardTracker(yfxLpTracker).unstakeForAccount(fProof, _account, _account, _amount);
        ILpRewardTracker(feeLpTracker).unstakeForAccount(_lp, _account, _account, _amount);

        emit UnstakeLp(_lp, _account, _amount);

        return _amount;
    }

    function stakeUtp(uint256 _amount) external nonReentrant {
        checkStatus();
        require(_amount > 0, "RewardRouter: invalid amount");
        address account = msg.sender;
        IUtpRewardTracker(stakedUtpTracker).stakeForAccount(account, account, utp, _amount);

        emit StakeUtp(account, _amount);
    }

    function unstakeUtp(uint256 _amount) external nonReentrant returns(uint256 amount) {
        checkStatus();
        require(_amount > 0, "RewardRouter: invalid amount");
        address account = msg.sender;
        amount = IUtpRewardTracker(stakedUtpTracker).unstakeForAccount(account, utp, _amount, account);
        
        emit UnstakeUtp(account, _amount);
    }

    function _claimAndLockYfx(address _account, uint32 _period, uint256 _amount) private returns(uint256 lockedAmount, uint256 burnAmount) {
        if (_amount > 0) {
            uint256 burnRatio = ILockTracker(locker).getBurnRatio(_period);
            
            if (burnRatio == 0) {
                lockedAmount = _amount;
            }
            else {
                lockedAmount = _amount.mul(1e6-burnRatio).div(1e6);
                burnAmount = _amount.sub(lockedAmount);
                IERC20(yfx).safeTransfer(address(1), burnAmount);
            }
            
            if (_period == 0) {
                IERC20(yfx).safeTransfer(_account, lockedAmount);
            }
            else {
                IERC20(yfx).safeApprove(locker, lockedAmount);
                ILockTracker(locker).lockForAccount(address(this), _account, _period, lockedAmount);    
            }
            
            emit ClaimedYFX(_account, _period, _amount, burnAmount, lockedAmount);
        }
    }

    struct HandleParams {
        uint32 _lockYfxPeriod;
        bool _shouldClaimRewardYfx;
        bool _shouldClaimVestYfx;
        bool _shouldStakeYfx;
        bool _shouldClaimIYfx;
        bool _shouldStakeIYfx;
        bool _shouldStakeMultiplierPoints;
        bool _shouldClaimWeth;
        bool _shouldConvertWethToEth;
        address[] _markets;
    }
    function handleRewards(
        HandleParams calldata param
    ) external nonReentrant {
        checkStatus();
        address account = msg.sender;

        uint256 vestAmount = 0;
        uint256 rewardAmount = 0;
        uint256 iYfxAmount = 0;

        /** handle yfx */
        if (param._shouldClaimRewardYfx) {
            rewardAmount = rewardAmount.add(IUtpRewardTracker(stakedUtpTracker).claimRewardForAccount(yfx, account, address(this)));
            rewardAmount = rewardAmount.add(ILpRewardTracker(yfxLpTracker).claimForAccount(account, address(this)));
            rewardAmount = rewardAmount.add(ILockTracker(lpLocker).claimForAccount(account, address(this)));

            uint256 len = param._markets.length;
            if (len > 0) {
                for (uint256 i=0; i<len; i++) {
                    address tracker = positionTrackerList[param._markets[i]];
                    if (tracker == address(0)) continue;
                    rewardAmount = rewardAmount.add(IPositionTracker(tracker).claimRewardForAccount(yfx, account, address(this)));
                }
            }
            
            if (locker != address(0)) {
                if (rewardAmount > 0) {
                    _claimAndLockYfx(account, param._lockYfxPeriod, rewardAmount);
                    rewardAmount = 0;
                }
            }
        }
        if (param._shouldClaimVestYfx) {
            if (yfxVester != address(0)) 
                vestAmount = vestAmount.add(IVester(yfxVester).claimForAccount(account, address(this)));
            if (lpVester != address(0)) 
                vestAmount = vestAmount.add(ILpVester(lpVester).claimAllForAccount(account, address(this)));
            if (utpVester != address(0)) 
                vestAmount = vestAmount.add(IVester(utpVester).claimForAccount(account, address(this)));

            if (param._shouldStakeYfx) {
                if (vestAmount > 0) {
                    IERC20(yfx).safeApprove(stakedYfxTracker, vestAmount);
                    _stakeYfx(address(this), account, yfx, vestAmount);
                    vestAmount = 0;
                }
            } 
        }

        if (rewardAmount.add(vestAmount) > 0) {
            IERC20(yfx).safeTransfer(account, rewardAmount.add(vestAmount));
        }

        /** handle iYfx */
        if (param._shouldClaimIYfx) {
            iYfxAmount = iYfxAmount.add(IRewardTracker(stakedYfxTracker).claimForAccount(account, account));
            iYfxAmount = iYfxAmount.add(IRewardTracker(stakedLpTracker).claimForAccount(account, account));
            iYfxAmount = iYfxAmount.add(IUtpRewardTracker(stakedUtpTracker).claimRewardForAccount(iYfx, account, account));
        }

        if (param._shouldStakeIYfx && iYfxAmount > 0) {
            _stakeYfx(account, account, iYfx, iYfxAmount);
        }
        
        /** handle mpYfx */
        if (param._shouldStakeMultiplierPoints) {
            uint256 mpYfxAmount = IRewardTracker(bonusYfxTracker).claimForAccount(account, account);
            mpYfxAmount = mpYfxAmount.add(IUtpRewardTracker(stakedUtpTracker).claimRewardForAccount(mpYfx, account, account));
            if (mpYfxAmount > 0) {
                IRewardTracker(feeYfxTracker).stakeForAccount(account, account, mpYfx, mpYfxAmount);
            }
        }
        
        /** handle eth */
        if (param._shouldClaimWeth) {
            if (param._shouldConvertWethToEth) {
                uint256 wethAmount = IRewardTracker(feeYfxTracker).claimForAccount(account, address(this));
                wethAmount = wethAmount.add(IRewardTracker(feeLpTracker).claimForAccount(account, address(this)));
                if(locker != address(0)) wethAmount = wethAmount.add(ILockTracker(locker).claimForAccount(account, address(this)));
                
                if (wethAmount > 0) {
                    IWETH(weth).withdraw(wethAmount);
                    payable(account).sendValue(wethAmount);
                }
            } else {
                IRewardTracker(feeYfxTracker).claimForAccount(account, account);
                IRewardTracker(feeLpTracker).claimForAccount(account, account);
                if(locker != address(0)) ILockTracker(locker).claimForAccount(account, account);
            }
        }
    }

    function _stakeYfx(address _fundingAccount, address _account, address _token, uint256 _amount) private {
        require(_amount > 0, "RewardRouter: invalid amount");

        IRewardTracker(stakedYfxTracker).stakeForAccount(_fundingAccount, _account, _token, _amount);
        IRewardTracker(bonusYfxTracker).stakeForAccount(_account, _account, stakedYfxTracker, _amount);
        IRewardTracker(feeYfxTracker).stakeForAccount(_account, _account, bonusYfxTracker, _amount);

        emit StakeYfx(_account, _token, _amount);
    }

    function _unstakeYfx(address _account, address _token, uint256 _amount, bool _shouldReduceMpYfx) private {
        require(_amount > 0, "RewardRouter: invalid amount");

        uint256 balance = IRewardTracker(stakedYfxTracker).stakedAmounts(_account);

        IRewardTracker(feeYfxTracker).unstakeForAccount(_account, bonusYfxTracker, _amount, _account);
        IRewardTracker(bonusYfxTracker).unstakeForAccount(_account, stakedYfxTracker, _amount, _account);
        IRewardTracker(stakedYfxTracker).unstakeForAccount(_account, _token, _amount, _account);

        if (_shouldReduceMpYfx) {
            uint256 mpYfxAmount = IRewardTracker(bonusYfxTracker).claimForAccount(_account, _account);
            mpYfxAmount = mpYfxAmount.add(
                IUtpRewardTracker(stakedUtpTracker).claimRewardForAccount(mpYfx, _account, _account)
            );
            if (mpYfxAmount > 0) {
                IRewardTracker(feeYfxTracker).stakeForAccount(_account, _account, mpYfx, mpYfxAmount);
            }

            uint256 stakedMpYfx = IRewardTracker(feeYfxTracker).depositBalances(_account, mpYfx);
            if (stakedMpYfx > 0) {
                uint256 reductionAmount = stakedMpYfx.mul(_amount).div(balance);
                IRewardTracker(feeYfxTracker).unstakeForAccount(_account, mpYfx, reductionAmount, _account);
                IMintable(mpYfx).burn(_account, reductionAmount);
            }
        }

        emit UnstakeYfx(_account, _token, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "../math/SafeMath.sol";
import "../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
contract ReentrancyGuard {
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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IRewardTracker {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);
    function stakedAmounts(address _account) external view returns (uint256);
    function updateRewards() external;
    function stake(address _depositToken, uint256 _amount) external;
    function stakeForAccount(address _fundingAccount, address _account, address _depositToken, uint256 _amount) external;
    function unstake(address _depositToken, uint256 _amount) external returns(uint256);
    function unstakeForAccount(address _account, address _depositToken, uint256 _amount, address _receiver) external returns(uint256);
    function tokensPerInterval() external view returns (uint256);
    function claim(address _receiver) external returns (uint256);
    function claimForAccount(address _account, address _receiver) external returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function averageStakedAmounts(address _account) external view returns (uint256);
    function cumulativeRewards(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface ILockTracker {
    struct LockConfig {
        uint32 multiplier;
        uint32 burnRatio;
    }

    struct LockInfo {
        uint256 amount;
        address account;
        uint32 multiplier;
        uint32 period;
        uint32 lockTime;
    }

    event Locked(address indexed account, uint32 indexed period, uint32 multiplier, address token, uint256 amount, uint256 id, address from);
    event LockedLp(address indexed account, uint32 indexed period, uint32 multiplier, address token, uint256 amount, uint256 id, address from, uint256 nftId);
    event Unlocked(address indexed account, uint32 indexed period, uint32 multiplier, address token, uint256 amount, uint256 id, address from);
    event UnlockedLp(address indexed account, uint32 indexed period, uint32 multiplier, address token, uint256 amount, uint256 id, address from, uint256 nftId);

    function getBurnRatio(uint32 _period) external view returns(uint256 burnRatio);
    function depositBalances(address _account) external view returns (uint256);
    function lockedAmounts(address _account) external view returns (uint256);
    function updateRewards() external;

    function lock(uint32 _period, uint256 _amount) external;
    function lockForAccount(address _fundingAccount, address _account, uint32 _period, uint256 _amount) external;
    function unlock(uint256 _id) external returns(uint256);
    function unlockForAccount(address _account, uint256 _id, address _receiver) external returns(uint256);

    function lockUniLpForAccount(address _fundingAccount, address _account, uint256 _id, uint32 _period) external;
    function unlockUniLpForAccount(address _account, uint256 _id, address _receiver) external;

    function tokensPerInterval() external view returns (uint256);
    function claim(address _receiver) external returns (uint256);
    function claimForAccount(address _account, address _receiver) external returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function cumulativeRewards(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ILpRewardTracker {
    function getDepositTokens() external view returns(address[] memory);
    function proofToken(address _depositToken) external view returns(address);
    function proofForStakeToken(address _proofToken) external view returns(address);
    function depositBalances(address _account, address _depositToken) external view returns (uint256);
    function updateRewards() external;
    function stake(address _depositToken, uint256 _amount) external;
    function stakeForAccount(address _depositToken, address _fundingAccount, address _account, uint256 _amount) external;
    function unstake(address _depositToken, uint256 _amount) external;
    function unstakeForAccount(address _depositToken, address _account, address _receiver, uint256 _amount) external;
    function claim(address _receiver) external returns (uint256);
    function claimForAccount(address _account, address _receiver) external returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function averageStakedAmounts(address _account, address _depositToken) external view returns (uint256);
    function cumulativeRewards(address _account, address _depositToken) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


interface IUtpRewardTracker {
    function getStakedAmounts(address _account) external view returns(uint256);
    function cumulativeRewards(address _account, address _depositToken) external view returns(uint256);
    function averageStakedAmounts(address _account, address _depositToken) external view returns(uint256);

    function stake(address /** _depositToken */, uint256 _amount) external;

    function stakeForAccount(address _fundingAccount, address _account, address /** _depositToken */, uint256 _amount) external;

    function unstake(address /** _depositToken */, uint256 _amount) external returns(uint256);

    function unstakeForAccount(address _account, address /** _depositToken */, uint256 _amount, address _receiver) external returns(uint256);
    
    function tokensPerInterval(address distributor) external view returns (uint256);

    function updateRewards() external;

    function claim(address _receiver) external returns (uint256[] memory);
    function claimForAccount(address _account, address _receiver) external returns (address[] memory, uint256[] memory);
    function claimable(address _account) external view returns (address[] memory, uint256[] memory);
    function claimReward(address _rewardToken, address _receiver) external returns (uint256);
    function claimRewardForAccount(address _rewardToken, address _account, address _receiver) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


interface IPositionTracker {
    function getStakedAmounts(address _account) external view returns(uint256);
    function cumulativeRewards(address _account, address _depositToken) external view returns(uint256);
    function averageStakedAmounts(address _account, address _depositToken) external view returns(uint256);
    function depositAmount(address _account) external view returns(uint256);

    function stake(address /** _depositToken */, uint256 _amount) external;

    function stakeForAccount(address _fundingAccount, address _account, address /** _depositToken */, uint256 _amount) external;

    function unstake(address /** _depositToken */, uint256 _amount) external returns(uint256);

    function unstakeForAccount(address _account, address /** _depositToken */, uint256 _amount, address _receiver) external returns(uint256);
    
    function tokensPerInterval(address distributor) external view returns (uint256);

    function updateRewards() external;

    function claim(address _receiver) external returns (uint256[] memory);
    function claimForAccount(address _account, address _receiver) external returns (address[] memory, uint256[] memory);
    function claimable(address _account) external view returns (address[] memory, uint256[] memory);
    function claimReward(address _rewardToken, address _receiver) external returns (uint256);
    function claimRewardForAccount(address _rewardToken, address _account, address _receiver) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IVester {
    function rewardTracker() external view returns (address);
    function claimForAccount(address _account, address _receiver) external returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function cumulativeClaimAmounts(address _account) external view returns (uint256);
    function claimedAmounts(address _account) external view returns (uint256);
    function pairAmounts(address _account) external view returns (uint256);
    function getVestedAmount(address _account) external view returns (uint256);
    function getVestAmount(address _account, uint256 _pairAmount) external view returns (uint256);
    function getMaxVestableAmount(address _account) external view returns (uint256);
    function getCombinedAverageStakedAmount(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ILpVester {
    function getPairTokens() external view returns(address[] memory);

    function rewardTracker() external view returns (address);

    function claimAllForAccount(address _account, address _receiver) external returns (uint256 amount);
    function claimForAccount(address _pariToken, address _account, address _receiver) external returns (uint256);

    function liquidateLp(address _account, address _pairToken) external;

    function totalClaimable(address _account) external view returns(uint256);
    function claimable(address _pariToken, address _account) external view returns (uint256);
    function cumulativeClaimAmounts(address _pariToken, address _account) external view returns (uint256);
    function claimedAmounts(address _pariToken, address _account) external view returns (uint256);
    function pairAmounts(address _pariToken, address _account) external view returns (uint256);
    function getTotalVestedAmount(address _account) external view returns(uint256);
    function getVestedAmount(address _pariToken, address _account) external view returns (uint256);
    function getVestAmount(address _pairToken, address _account, uint256 _pairAmount) external view returns (uint256);
    function getMaxVestableAmount(address _pariToken, address _account) external view returns (uint256);
    function getCombinedAverageStakedAmount(address _pariToken, address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IPeriphery {
    struct Position {
        uint256 id;                 // position id, generated by counter
        address taker;              // taker address
        address market;             // market address
        int8 direction;             // position direction
        uint16 takerLeverage;       // leverage used by trader
        uint256 amount;             // position amount
        uint256 value;              // position value
        uint256 takerMargin;        // margin of trader
        uint256 makerMargin;        // margin of maker(pool)
        uint256 multiplier;         // multiplier of quanto perpetual contracts
        int256 frLastX96;           // last settled funding global cumulative value
        uint256 stopLossPrice;      // stop loss price of this position set by trader
        uint256 takeProfitPrice;    // take profit price of this position set by trader
        bool useIP;                 // true if the tp/sl is executed by index price
        uint256 lastTPSLTs;         // last timestamp of trading setting the stop loss price or take profit price
        int256 fundingPayment;      // cumulative funding need to pay of this position
        uint256 debtShare;          // borrowed share of interest module
        int256 pnl;                 // cumulative realized pnl of this position
        bool isETH;                 // true if the margin is payed by ETH
        uint256 lastUpdateTs;       // last updated timestamp of this position
    }

    struct PoolInfo {
        uint256 minAddLiquidityAmount;
        uint256 minRemoveLiquidityAmount;
        uint256 reserveRate;
        uint256 removeLiquidityFeeRate;
        int256 balance;
        uint256 sharePrice;
        uint256 assetAmount;
        bool addPaused;
        bool removePaused;
        uint256 totalSupply;
        address baseAsset;
    }

    enum PositionMode{
        Hedge,
        OneWay
    }

    function getSharePrice(address _pool) external view returns (uint256 price);
    function getAllPosition(address _market, address _taker) external view returns (Position[] memory);
    function getPoolInfo(address _pool) external view returns (PoolInfo memory info);
    function getPositionMode(address _market, address _taker) external view returns (PositionMode _mode);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IMintable {
    function isMinter(address _account) external returns (bool);
    function setMinter(address _minter, bool _isActive) external;
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract Governable {
    address public gov;

    constructor() public {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}