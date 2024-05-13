// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
pragma solidity =0.8.8;
pragma abicoder v2;

import "./lib/LPercentage.sol";
import "./lib/LLocker.sol";
import "./lib/LProfile.sol";
import "./lib/LHelper.sol";

import "./modules/UseAccessControl.sol";
import "./modules/interfaces/IDToken.sol";
import "./modules/interfaces/IDistributor.sol";
import "./modules/interfaces/IPCLocker.sol";
import "./modules/interfaces/IEarning.sol";

import "./interfaces/IPoolFactory.sol";
import "./interfaces/IProfile.sol";
import "./interfaces/IDCT.sol";
import "./interfaces/IVoting.sol";
import "./interfaces/IEthSharing.sol";
import "./interfaces/IExchanger.sol";
import "./interfaces/ILotteryRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Helper {
    function _thisTokenBalance(
        address token_
    )
        internal
        view
        returns(uint)
    {
        return IERC20(token_).balanceOf(address(this));
    }

    function _transferAllToken(
        address token_,
        address to_
    )
        internal
    {
        IERC20(token_).transfer(to_, _thisTokenBalance(token_));
    }
}

contract StakingTokens is Helper {
    event AddLocker(
        address indexed token,
        address indexed locker
    );

    event SetMinLockA(
        address token,
        uint minLockA
    );

    mapping(address => IPCLocker) internal _lockers;
    mapping(address => uint) internal _minLockAs;

    function _initStakingTokens(
        address[] memory tokens_,
        address[] memory lockers_
    )
        internal
    {
        uint n = tokens_.length;
        require(n > 2 && n == lockers_.length, "length invalid");
        for(uint i = 0; i < n; i++) {
            _addLocker(tokens_[i], lockers_[i]);
        }
    }

    function _setMinLockA(
        address token_,
        uint minLockA_
    )
        internal
    {
        _minLockAs[token_] = minLockA_;
        emit SetMinLockA(token_, minLockA_);
    }

    function _addLocker(
        address token_,
        address locker_
    )
        internal
    {
        require(token_ != address(0x0) && locker_ != address(0x0), "invalid address");
        require(address(_lockers[token_]) == address(0x0), "locker already exist");
        _lockers[token_] = IPCLocker(locker_);
        emit AddLocker(token_, locker_);
    }

    function _lock(
        address token_,
        address payable poolOwner_,
        uint duration_
    )
        internal
        returns (uint)
    {
        uint value = _thisTokenBalance(token_);
        require(value >= _minLockAs[token_], "lockA too low");
        IPCLocker locker = _lockers[token_];
        locker.clean();
        IERC20(token_).transfer(address(locker), value);
        locker.lock(msg.sender, poolOwner_, duration_);
        return value;
    }

    function getStakingTokenConfig(
        address token_
    )
        external
        view
        returns(address, uint)
    {
        return (address(_lockers[token_]), _minLockAs[token_]);
    }
}

contract Controller is UseAccessControl, StakingTokens {
    using LPercentage for *;
    using LProfile for *;

    modifier tryPublicMint() {
        if (block.timestamp - _lastMintAt > _mintingInt) {
            _lastMintAt = block.timestamp;
            _dct.publicMint();
        }
        _;
    }

    event Stake(
        address indexed token,
        address indexed poolOwner,
        address indexed staker,
        uint amount,
        uint duration,
        uint powerMinted
    );

    event AdminUpdateConfig(
        uint[] values
    );

    string constant public VERSION = "DEV";

    IERC20 private _weth;
    IDCT private _dct;

    IDistributor private _devTeam;
    IPoolFactory private _poolFactory;
    IProfile private _profileC;

    // IPCLocker private _eLocker;
    IDToken private _eP2PDToken;
    // IDistributor private _eP2PDistributor;
    IEarning private _eEarning;

    // IPCLocker private _dLocker;
    IDToken private _dP2PDToken;
    IDistributor private _dP2PDistributor;
    IEarning private _dEarning;

    IVoting private _voting;

    IDistributor private _eDP2PDistributor;
    IDistributor private _dDP2PDistributor;

    IEthSharing private _ethSharing;
    IExchanger private _exchanger;
    ILotteryRouter private _lotteryRouter;

    uint public _maxBooster = 2;

    uint public _minDuration = 30 days;
    uint public _maxDuration = 720 days;
    // uint public _minStakeETHAmount = 0.001e18;
    // uint public _minStakeDCTAmount = 7 ether;

    uint public _maxSponsorAdv = 10;
    uint public _maxSponsorAfter = 1 days;

    uint public _lastMintAt;
    uint public _mintingInt = 7;

    uint public _attackFee = 1 ether;
    uint public _minFreezeDuration = 7 days;
    uint public _maxFreezeDuration = 100 days;
    uint public _freezeDurationUnit = 100 days;
    uint public _minDefenderFund = 0.1e18;

    uint public _maxVoterPercent = 5000; //50%
    uint public _minVoterPercent = 1000; //10%
    uint public _minAttackerFundRate = 2500; //25%

    uint public _bountyPullEarningPercent = 100; //1%

    uint public _selfStakeAdvantage = 15000; // 150%

    uint public _isPausedAttack = 1;

    uint public _dctTaxPercent = 100;

    uint public _lotteryPercent = 20;

    uint constant public MAX_LOTTERY_PERCENT = 500;

    receive() external payable {}

    function initController(
        address[] memory tokens_,
        address[] memory lockers_,
        address[] memory contracts_
    )
        external
        initializer
    {
        _initStakingTokens(tokens_, lockers_);
        _weth = IERC20(contracts_[0]);
        _dct = IDCT(contracts_[1]);

        initUseAccessControl(contracts_[2]);
        _devTeam = IDistributor(contracts_[3]);
        _poolFactory = IPoolFactory(contracts_[4]);
        _profileC = IProfile(contracts_[5]);

        // _eLocker = IPCLocker(contracts_[6]);
        _eP2PDToken = IDToken(contracts_[7]);
        _eEarning = IEarning(contracts_[8]);

        // _dLocker = IPCLocker(contracts_[9]);
        _dP2PDToken = IDToken(contracts_[10]);
        _dP2PDistributor = IDistributor(contracts_[11]);
        _dEarning = IEarning(contracts_[12]);

        _voting = IVoting(contracts_[13]);

        //airdrop ETH by dP2PDToken
        _eDP2PDistributor = IDistributor(contracts_[14]);
        //airdrop DCT by dP2PDToken
        _dDP2PDistributor = IDistributor(contracts_[15]);

        // note
        // add ethSharing in initController
        _ethSharing = IEthSharing(contracts_[16]);
        _exchanger = IExchanger(contracts_[17]);
        _lotteryRouter = ILotteryRouter(contracts_[18]);

        _dP2PDToken.activeAthRecord();
    }

    function _thisWethBalance()
        internal
        view
        returns(uint)
    {
        return _thisTokenBalance(address(_weth));
    }

    function _thisDctBalance()
        internal
        view
        returns(uint)
    {
        return _thisTokenBalance(address(_dct));
    }

    //call after update Fs, booster, or P2uDToken Balance
    function _reCalEP2PDBalance(
        address poolOwner_
    )
        internal
    {
        if (_poolFactory.isCreated(poolOwner_)) {
            IPoolFactory.SPool memory pool = _poolFactory.getPool(poolOwner_);
            IDToken p2UDtoken = IDToken(pool.dToken);

            uint oldEP2PBalance = _eP2PDToken.balanceOf(pool.dctDistributor);

            uint newEP2PBalance = LHelper.calEP2PDBalance(
                _profileC.fsOf(poolOwner_),
                _profileC.boosterOf(poolOwner_),
                p2UDtoken.totalSupply()
            );
            if (newEP2PBalance > oldEP2PBalance) {
                _eP2PDToken.mint(pool.dctDistributor, newEP2PBalance - oldEP2PBalance);
            } else if (newEP2PBalance < oldEP2PBalance) {
                _eP2PDToken.burn(pool.dctDistributor, oldEP2PBalance - newEP2PBalance);
            }
        }
    }

    function reCalFs(
        address poolOwner_
    )
        external
    {
        _reCalFs(poolOwner_);
    }

    // call after update ETH earning balance
    function _reCalFs(
        address account_
    )
        internal
        tryPublicMint
    {
        _eEarning.shareCommission(account_);
        uint maxEarning = _eEarning.maxEarningOf(account_);
        _profileC.updateFsOf(account_, LHelper.calFs(
            _eEarning.earningOf(account_) + _voting.defenderEarningFreezedOf(account_),
            maxEarning
        ));
        _reCalEP2PDBalance(account_);
    }

    function reCalBooster(
        address account_
    )
        external
    {
        _reCalBooster(account_);
    }

    //call after update dP2pDtoken balance
    function _reCalBooster(
        address account_
    )
        internal
    {
        uint maxBoostVotePower = _dP2PDToken.athBalance();
        uint boostVotePower = _dP2PDToken.balanceOf(account_);
        uint newBooster = LProfile.calBooster(boostVotePower, maxBoostVotePower, _maxBooster);
        _profileC.updateBoosterOf(account_, newBooster);
    }

    // eth only
    function _updateSponsor(
        address payable poolOwner_,
        address staker_,
        uint minSPercent_
    )
        internal
    {
        if (poolOwner_ == staker_) {
            return;
        }
        IProfile.SProfile memory profile = _profileC.profileOf(poolOwner_);
        if (profile.sponsor == staker_) {
            return;
        }
        require(profile.nextSPercent >= minSPercent_, "profile rate changed");
        IPoolFactory.SPool memory pool = _poolFactory.getPool(poolOwner_);
        IDToken p2UDtoken = IDToken(pool.dToken);
        uint timeDiff = block.timestamp - profile.updatedAt;
        if (timeDiff > _maxSponsorAfter) {
            timeDiff = _maxSponsorAfter;
        }

        uint sponsorDTokenBalance = p2UDtoken.balanceOf(profile.sponsor);
        uint stakerDTokenBalance = p2UDtoken.balanceOf(staker_);
        uint sponsorBonus = sponsorDTokenBalance * (_maxSponsorAdv - 1)
            * timeDiff / _maxSponsorAfter;
        uint sponsorPower = sponsorDTokenBalance + sponsorBonus;
        if (stakerDTokenBalance > sponsorPower || poolOwner_ == profile.sponsor) {
            address[] memory pools = new address[](1);
            pools[0] = poolOwner_;
            earningPulls(poolOwner_, pools, poolOwner_);
            _profileC.updateSponsor(poolOwner_, staker_);
        }
    }

    // eth only
    function _shareDevTeam(
        address token_,
        uint amount_
    )
        internal
    {
        IERC20(token_).transfer(address(_devTeam), amount_);
    }

    // eth only
    function _sharePoolOwner(
        uint amount_,
        address payable poolOwner_
    )
        internal
    {
        _eEarning.clean();

        _weth.transfer(address(_eEarning), amount_);

        _eEarning.update(poolOwner_, true);
    }

    // eth only
    function _sharePoolUser(
        uint amount_,
        address payable poolOwner_
    )
        internal
    {
        IPoolFactory.SPool memory pool = _poolFactory.getPool(poolOwner_);
        _weth.transfer(pool.ethDistributor, amount_);
    }

    function _joinLottery(
        address account_
    )
        internal
    {
        uint value = LPercentage.getPercentA(_thisTokenBalance(address(_weth)), _lotteryPercent);
        _weth.transfer(address(_lotteryRouter), value);
        _lotteryRouter.join(account_);
    }

    function _stake(
        address token_,
        address account_,
        address payable poolOwner_,
        uint duration_,
        uint minSPercent_,
        uint poolConfigCode_
    )
        internal
    {
        require(tx.origin == account_, "onlyHuman");
        bool isEth_ = token_ != address(_dct);
        if (isEth_) {
            if (!_poolFactory.isCreated(account_)) {
                _poolFactory.createPool(account_);
                _ethSharing.initPoolConfig(account_);

                if (account_ == poolOwner_) {
                    // first stake self
                    _profileC.updateSponsor(account_, account_);
                } else {
                    // first stake other
                    _profileC.updateSponsor(account_, address(_devTeam));
                }
            }
            require(_poolFactory.isCreated(poolOwner_), "not activated");
        }

        uint value = _thisTokenBalance(token_);
        IPCLocker locker = _lockers[token_];
        // todo
        // uint minStakeAmount = isEth_ ? _minStakeETHAmount : _minStakeDCTAmount;

        LLocker.SLock memory oldLockData = locker.getLockData(account_, poolOwner_);

        {
        // require(value >= minStakeAmount, "amount too small");

        uint rd = LLocker.restDuration(oldLockData);
        require(rd + duration_ <= _maxDuration, "total lock duration too high.");
        }
        require(duration_ == 0 || duration_ >= _minDuration, "duration too small");

        uint powerMinted;
        if (isEth_) {
            {
            _ethSharing.tryResetPool(poolOwner_);
            (uint devTeamA, uint poolOwnerA, uint poolUserA, ) =
                _ethSharing.getSharingParts(poolOwner_, value, poolConfigCode_);
            _shareDevTeam(token_, devTeamA);
            if (account_ != poolOwner_) {
                if (token_ == address(_weth)){
                    _sharePoolOwner(poolOwnerA, poolOwner_);
                    _sharePoolUser(poolUserA, poolOwner_);
                    _joinLottery(account_);
                }
            }
            }
            {
            uint aLock = _lock(token_, poolOwner_, duration_);

            powerMinted = LHelper.calMintStakingPower(
                oldLockData,
                aLock,
                duration_,
                account_ == poolOwner_,
                _selfStakeAdvantage
            );
            }
            IPoolFactory.SPool memory pool = _poolFactory.getPool(poolOwner_);
            IDToken p2UDtoken = IDToken(pool.dToken);
            bool isFirstStake = p2UDtoken.totalSupply() == 0;
            _dP2PDistributor.distribute();
            _dP2PDistributor.claimFor(pool.dctDistributor, pool.dctDistributor);

            p2UDtoken.mint(account_, powerMinted);
            locker.incMintedPower(account_, poolOwner_, powerMinted);

            if (isFirstStake) {
                IDistributor(pool.ethDistributor).distribute();
            }

            _updateSponsor(poolOwner_, account_, minSPercent_);
            emit Stake(token_, poolOwner_, account_, value, duration_, powerMinted);
        } else {
            uint taxA = LPercentage.getPercentA(_thisDctBalance(), _dctTaxPercent);
            _dct.transfer(address(0xdead), taxA);

            {
            require(account_ == poolOwner_, "can only stake DCT for yourself");
            uint aLock = _lock(token_, poolOwner_, duration_);

            powerMinted = LHelper.calMintStakingPower(
                oldLockData,
                aLock,
                duration_,
                false,
                _selfStakeAdvantage
            );
            }
            _dP2PDToken.mint(poolOwner_, powerMinted);
            emit Stake(token_, poolOwner_, account_, value, duration_, powerMinted);
        }

        _reCalBooster(poolOwner_);
        _reCalFs(poolOwner_);
    }

    function _prepareToken(
        address token_,
        uint tokenA_
    )
        internal
    {
        if (address(this).balance > 0) {
            payable(address(_exchanger)).transfer(address(this).balance);
            _exchanger.ethToWeth(address(this));
        }
        if (tokenA_ > 0) {
            IERC20(token_).transferFrom(msg.sender, address(this), tokenA_);
        }
    }

    function stake(
        address token_,
        address payable poolOwner_,
        uint duration_,
        uint minSPercent_,
        uint poolConfigCode_,
        uint tokenA_,
        bool mustBeSponsor_
    )
        public
        payable
    {
        // bool isEth = true;
        _prepareToken(token_, tokenA_);
        // uint gethBal = _thisWethBalance();
        // if (gethBal < _minStakeETHAmount && gethBal > 0) {
        //     _weth.transfer(msg.sender, _thisWethBalance());
        // }
        if (msg.sender != poolOwner_) {
            require(token_ == address(_weth) || token_ == address(_dct), "invalid token");
        }

        _stake(token_, msg.sender, poolOwner_, duration_, minSPercent_, poolConfigCode_);
        if (mustBeSponsor_) {
            IProfile.SProfile memory profile = _profileC.profileOf(poolOwner_);
            require(profile.sponsor == msg.sender, "frontrun");
        }
    }

    // function dctStake(
    //     uint amount_,
    //     address payable poolOwner_,
    //     uint duration_
    // )
    //     public
    // {
    //     _dct.transferFrom(msg.sender, address(this), amount_);
    //     uint dctBal = _thisDctBalance();
    //     if (dctBal < _minStakeDCTAmount && dctBal > 0) {
    //         _dct.transfer(msg.sender, dctBal);
    //     }
    //     bool isEth = false;
    //     // any
    //     uint poolConfigCode = 0;
    //     _stake(isEth, msg.sender, poolOwner_, duration_, 0, poolConfigCode);
    // }

    function _distributorClaimFor(
        address distributor_,
        address account_,
        address dest_
    )
        internal
    {
        IDistributor(distributor_).distribute();
        IDistributor(distributor_).claimFor(account_, dest_);
    }

    function _earningPull(
        address account_,
        address poolOwner_
    )
        internal
    {
        IPoolFactory.SPool memory pool = _poolFactory.getPool(poolOwner_);
        _dP2PDistributor.claimFor(pool.dctDistributor, pool.dctDistributor);

        _distributorClaimFor(pool.dctDistributor, account_, address(_dEarning));
        _distributorClaimFor(pool.ethDistributor, account_, address(this));
    }

    function earningPulls(
        address account_,
        address[] memory poolOwners_,
        address bountyPullerTo_
    )
        public
    {
        _dEarning.clean();
        _eEarning.clean();

        _dP2PDistributor.distribute();

        _distributorClaimFor(address(_eDP2PDistributor), account_, address(this));
        _distributorClaimFor(address(_dDP2PDistributor), account_, address(_dEarning));

        for(uint i = 0; i < poolOwners_.length; i++) {
            _earningPull(account_, poolOwners_[i]);
        }

        if (bountyPullerTo_ == account_) {
            _weth.transfer(address(_eEarning), _thisWethBalance());
        } else {
            uint256 amountForPuller = _thisWethBalance() * _bountyPullEarningPercent / LPercentage.DEMI;

            _weth.transfer(bountyPullerTo_, amountForPuller);
            _weth.transfer(address(_eEarning), _thisWethBalance());
        }

        _dEarning.update(account_, true);
        _eEarning.update(account_, true);

        _reCalFs(account_);
    }

    /*
        UNLOCK: REINVEST/WITHDRAW
    */

    function lockWithdraw(
        address token_,
        address payable poolOwner_,
        uint amount_,
        address payable dest_,
        bool isForced_
    )
        public
        tryPublicMint
    {
        bool isEth_ = token_ != address(_dct);
        address account = msg.sender;
        IPCLocker locker = _lockers[token_];

        LLocker.SLock memory oldLockData = locker.getLockData(account, poolOwner_);
        locker.withdraw(account, poolOwner_, address(this), amount_, isForced_);
        uint restAmount = oldLockData.amount - amount_;

        require(restAmount == 0 || restAmount >= _minLockAs[token_], "rest amount too small");
        // burn
        if (isEth_) {
            IPoolFactory.SPool memory pool = _poolFactory.getPool(poolOwner_);
            IDToken p2UDtoken = IDToken(pool.dToken);
            uint burnedPower = LHelper.calBurnStakingPower(locker.getMintedPower(account, poolOwner_), amount_, oldLockData.amount);
            _dP2PDistributor.distribute();
            _dP2PDistributor.claimFor(pool.dctDistributor, pool.dctDistributor);

            p2UDtoken.burn(account, burnedPower);
            locker.decMintedPower(account, poolOwner_, burnedPower);

            _reCalEP2PDBalance(poolOwner_);
        } else {
            uint burnedPower = LHelper.calBurnStakingPower(_dP2PDToken.balanceOf(poolOwner_), amount_, oldLockData.amount);
            _dP2PDToken.burn(poolOwner_, burnedPower);

            _reCalBooster(poolOwner_);
            _reCalEP2PDBalance(poolOwner_);
        }

        if (token_ == address(_weth)) {
            _weth.transfer(address(_exchanger), _thisWethBalance());
            _exchanger.wethToEth(dest_);
        } else {
            _transferAllToken(token_, dest_);
        }
    }

    // EARNING: REINVEST/WITHDRAW

    function earningReinvest(
        address token_,
        address payable poolOwner_,
        uint duration_,
        uint amount_,
        // address[] memory pulledPoolOwners_,
        uint minSPercent_,
        uint poolConfigCode_
    )
        external
    {
        require(token_ == address(_weth) || token_ == address(_dct), "invalid token");
        bool isEth_ = token_ != address(_dct);
        address account = msg.sender;
        earningWithdraw(token_, amount_, payable(address(this)));
        if (isEth_) {
            LLocker.SLock memory oldLockData = _lockers[token_].getLockData(account, poolOwner_);
            uint realDuration = duration_ + LLocker.restDuration(oldLockData);
            if (realDuration > _maxDuration) {
                realDuration = _maxDuration;
            }
            uint maxEarning = _eEarning.maxEarningOf(account);
            maxEarning -= amount_ * realDuration / _maxDuration;
            _eEarning.updateMaxEarning(account, maxEarning);
        }
        _stake(token_, account, poolOwner_, duration_, minSPercent_, poolConfigCode_);
    }

    function earningWithdraw(
        address token_,
        uint amount_,
        address payable dest_
    )
        public
    {
        require(token_ == address(_weth) || token_ == address(_dct), "invalid token");
        bool isEth_ = token_ != address(_dct);
        address account = msg.sender;
        // earningPulls(account, pulledPoolOwners_, account);
        IEarning earning = isEth_ ? _eEarning : _dEarning;

        earning.withdraw(account, amount_, address(this));
        //burn
        if (isEth_) {
            _reCalFs(account);
        }

        if (dest_ != address(this) && isEth_) {
            _weth.transfer(address(_exchanger), _thisWethBalance());
            _exchanger.wethToEth(dest_);
        } else {
            _transferAllToken(token_, dest_);
        }
    }

    function createVote(
        address defender_,
        uint dEthValue_,
        uint voterPercent_,
        uint freezeDuration_,
        uint wethA_,
        string memory aInfoUrl_
    )
        external
        payable
    {
        require(_isPausedAttack == 0, "paused");

        address attacker = msg.sender;
        address token_ = address(_weth);
        _prepareToken(token_, wethA_);
        uint aEthValue = _thisWethBalance();

        require(defender_ != address(_devTeam));
        require(dEthValue_ >= _minDefenderFund, "dEthValue_ too small");
        require(voterPercent_ <= _maxVoterPercent && voterPercent_ >= _minVoterPercent, "voterPercent_ invalid");
        require(freezeDuration_ >= _minFreezeDuration && freezeDuration_ <= _maxFreezeDuration, "freezeDuration_ invalid");
        require(aEthValue * LPercentage.DEMI / dEthValue_ >= _minAttackerFundRate, "aEthValue invalid");

        uint aQuorum = LHelper.calAQuorum(
            aEthValue,
            dEthValue_,
            voterPercent_,
            freezeDuration_,
            _freezeDurationUnit
        );

        _voting.clean();
        _eEarning.withdraw(defender_, dEthValue_, address(_voting));
        _weth.transfer(address(_voting), aEthValue);

        _dct.transferFrom(attacker, address(0xdead), _attackFee);

        _voting.createVote(
            attacker,
            defender_,
            aEthValue,
            dEthValue_,
            voterPercent_,
            aQuorum,
            block.timestamp,
            block.timestamp + freezeDuration_,
            aInfoUrl_
        );

        _reCalFs(defender_);
    }

    function votingClaimFor(
        uint voteId_,
        address voter_
    )
        external
    {
        IVoting.SVoteBasicInfo memory vote = _voting.getVote(voteId_);
        bool isFinalizedBefore = vote.isFinalized;

        _voting.claimFor(voteId_, voter_);

        if (!isFinalizedBefore) {
            _reCalFs(vote.defender);
        }

        _reCalFs(voter_);
    }

    // ADMIN: CONFIGS
    function updateConfigs(
        uint[] memory values_
    )
        external
        onlyAdmin
    {

        require(values_[0] <= 300, "max 3%");
        _bountyPullEarningPercent = values_[0];

        _maxBooster = values_[1];

        _maxSponsorAdv = values_[2];
        _maxSponsorAfter = values_[3];

        _attackFee = values_[4];
        _maxVoterPercent = values_[5];
        _minAttackerFundRate = values_[6];
        _freezeDurationUnit = values_[7];
        _selfStakeAdvantage = values_[8];

        _profileC.setDefaultSPercentConfig(values_[9]);
        _isPausedAttack = values_[10];

        _profileC.setMinSPercentConfig(values_[11]);

        _dctTaxPercent = values_[12];

        _minFreezeDuration = values_[13];
        _maxFreezeDuration = values_[14];

        // _minStakeETHAmount = values_[15];
        // _minStakeDCTAmount = values_[16];

        _minDefenderFund = values_[17];

        require(values_[18] >= 100, '_minVoterPercent must >= 1%');
        _minVoterPercent = values_[18];

        _lotteryPercent = values_[19];
        require(_lotteryPercent <= MAX_LOTTERY_PERCENT, "lottery percent too high");

        emit AdminUpdateConfig(values_);
    }

    function setMinLockA(
        address token_,
        uint minLockA_
    )
        external
        onlyAdmin
    {
        _setMinLockA(token_, minLockA_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDCT is IERC20 {
    function HALVING_INTERVAL()
        external
        view
        returns(uint);

    function initDCT(
        address accessControl_,
        address rewardPool_,
        address premineAddress_,
        uint256 premineAmount_,
        address cleanTo_
    )
        external;

    function tps()
        external
        view
        returns(uint);

    function pendingA()
        external
        view
        returns(uint);

    function publicMint()
        external;

    function lastMintAt()
        external
        view
        returns(uint);

    function lastHalved()
        external
        view
        returns(uint);

    function rewardPool()
        external
        view
        returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

interface IEthSharing {
    function initEthSharing(
        address accessControl_,
        uint devTeamPercent_,
        uint defaultOwnerPercent_,
        uint defaultUserPercent_,
        bool inDefaultOnlyMode_

    )
        external;

    function configSystem(
        uint devTeamPercent_,
        uint defaultOwnerPercent_,
        uint defaultUserPercent_,
        bool inDefaultOnlyMode_
    )
        external;

    function initPoolConfig(
        address poolOwner_
    )
        external
        returns(bool);

    function tryResetPool(
        address poolOwner_
    )
        external;

    function configPool(
        uint ownerPercent_,
        uint userPercent_ 
    )
        external;

    function getPoolLockPercent(
        address poolOwner_
    )
        external
        view
        returns(uint);

    function getDevTeamPart(
        uint value_
    )
        external
        view
        returns(uint);

    function getSysExcPart(
        uint value_
    )
        external
        view
        returns(uint);

    function getPoolOwnerPart(
        address poolOwner_,
        uint value_
    )
        external
        view
        returns(uint);

    function getPoolUserPart(
        address poolOwner_,
        uint value_
    )
        external
        view
        returns(uint);

    function getLockedPart(
        address poolOwner_,
        uint value_
    )
        external
        view
        returns(uint);

    function getSharingParts(
        address poolOwner_,
        uint value_,
        uint code_
    )
        external
        view
        returns(uint devTeamA, uint poolOwnerA, uint poolUserA, uint lockedA);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

interface IExchanger {
    function ethToWeth(
        address dest_
    )
        external;

    function wethToEth(
        address dest_
    )
        external;

    function fromEthSwap(
        address account_,
        uint minWstethA_,
        address dest_
    )
        external;

    function toEthSwap(
        address account_,
        uint minEthA_,
        address payable dest_
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

interface ILotteryRouter {
    function join(
        address account_
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

interface IPoolFactory {
    struct SPool{
        address dToken;
        address ethDistributor;
        address dctDistributor;
    }

    function initPoolFactory(
        address accessControl_,
        address geth_,
        address dct_
    )
        external;

    function createPool(
        address owner_
    )
        external;

    function isCreated(
        address owner_
    )
        external
        view
        returns(bool);

    function getPool(
        address owner_
    )
        external
        view
        returns(SPool memory);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

interface IProfile {
    struct SProfile{
        address sponsor;
        uint sPercent;
        uint nextSPercent;
        uint updatedAt;
        uint ifs;
        uint bonusBooster;
    }

    function updateSponsor(
        address account_,
        address sponsor_
    )
        external;

    function profileOf(
        address account_
    )
        external
        view
        returns(SProfile memory);

    function getSponsorPart(
        address account_,
        uint amount_
    )
        external
        view
        returns(address sponsor, uint sAmount);

    function setSPercent(
        uint sPercent_
    )
        external;

    function setDefaultSPercentConfig(
        uint sPercent_
    )
        external;

    function setMinSPercentConfig(
        uint sPercent_
    )
        external;

    function updateFsOf(
        address account_,
        uint fs_
    )
        external;

    function updateBoosterOf(
        address account_,
        uint booster_
    )
        external;

    function fsOf(
        address account_
    )
        external
        view
        returns(uint);

    function boosterOf(
        address account_
    )
        external
        view
        returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import "../modules/interfaces/ICashier.sol";

interface IVoting is ICashier {
    struct SVoteBasicInfo{
        address attacker;
        address defender;

        uint aEthValue;
        uint dEthValue;

        uint voterPercent;
        uint aQuorum;

        uint startedAt;
        uint endAt;

        uint attackerPower;
        uint defenderPower;

        uint totalClaimed;

        bool isFinalized;
        bool isAttackerWon;
        uint winVal;
        uint winnerPower;
        bool isClosed;
    }

    function createVote(
        address attacker_,
        address defender_,

        uint aEthValue_,
        uint dEthValue_,

        uint voterPercent_,
        uint aQuorum_,

        uint startedAt_,
        uint endAt_,

        string memory aInfoUrl_
    )
        external;

    function getVote(
        uint voteId_
    )
        external
        view
        returns(SVoteBasicInfo memory);

    function claimFor(
        uint voteId_,
        address voter_
    )
        external;


    function defenderEarningFreezedOf(
        address account_
    )
        external
        view
        returns(uint);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;

import "./LPercentage.sol";
import "./LProfile.sol";
import "../lib/LLocker.sol";

library LHelper {
    using LLocker for *;
    function calEP2PDBalance(
        uint fs_,
        uint booster_,
        uint totalP2UBalance_
    )
        internal
        pure
        returns(uint)
    {
       return fs_ * booster_ * totalP2UBalance_ / LPercentage.DEMIE2;
    }

    function calMintStakingPower(
        LLocker.SLock memory oldLockData,
        uint lockAmount_,
        uint lockTime_,
        bool isSelfStake_,
        uint selfStakeAdvantage_
    )
        internal
        view
        returns(uint)
    {
        uint rd = LLocker.restDuration(oldLockData);
        uint oldALock = oldLockData.amount;
        uint dLockForOldA = lockTime_;
        uint dLockForStakeA = lockTime_ + rd;
        if (lockTime_ == 0) {
            require(rd > 0, "already unlocked");
        }
        uint rs = (oldALock * calMultiplierForOldAmount(dLockForOldA) + lockAmount_ * calMultiplier(dLockForStakeA)) / LPercentage.DEMI;
        if (isSelfStake_) {
            rs = rs * selfStakeAdvantage_ / LPercentage.DEMI;
        }
        return rs;
    }


    function calBurnStakingPower(
        uint powerBalance_,
        uint unlockedA_,
        uint totalLockedA_
    )
        internal
        pure
        returns(uint)
    {
        return powerBalance_ * unlockedA_ / totalLockedA_;
    }

    function calFs(
        uint earningBalance_,
        uint maxEarning_
    )
        internal
        pure
        returns(uint)
    {
        uint max = maxEarning_;
        if (max < earningBalance_) {
            max = earningBalance_;
        }
        if (max == 0) {
            return LPercentage.DEMI;
        }
        return earningBalance_ * LPercentage.DEMI / max;
    }
    // with DEMI multiplied
    function calMultiplierForOldAmount(
        uint lockTime_
    )
        internal
        pure
        returns(uint)
    {
        uint x = lockTime_ * LPercentage.DEMI / 30 days;
        uint rs = (1300 * x / LPercentage.DEMI);
        return rs;
    }

    function calMultiplier(
        uint lockTime_
    )
        internal
        pure
        returns(uint)
    {
        uint x = lockTime_ * LPercentage.DEMI / 30 days;
        require(x >= LPercentage.DEMI, 'lockTime_ too small');
        uint rs = (1300 * x / LPercentage.DEMI) + 8800;
        return rs;
    }

    function calAQuorum(
        uint aEthValue_,
        uint dEthValue_,
        uint voterPercent_,
        uint freezeDuration_,
        uint freezeDurationUnit_
    )
        internal
        pure
        returns(uint)
    {
        uint tmp = LPercentage.DEMI - voterPercent_;
        uint leverage = LPercentage.DEMIE2 *
            dEthValue_ * freezeDuration_ / aEthValue_ / freezeDurationUnit_ / tmp;
        if (leverage < LPercentage.DEMI) {
            leverage = LPercentage.DEMI;
        }
        return LPercentage.DEMI * leverage / (leverage + LPercentage.DEMI);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;

import "./LPercentage.sol";

library LLocker {
    struct SLock {
        uint startedAt;
        uint amount;
        uint duration;
    }

    function getLockId(
        address account_,
        address poolOwner_
    )
        internal
        pure
        returns(bytes32)
    {
        return keccak256(abi.encode(account_, poolOwner_));
    }

    function restDuration(
        SLock memory lockData_
    )
        internal
        view
        returns(uint)
    {
        if (lockData_.startedAt > block.timestamp) {
            return lockData_.duration + lockData_.startedAt - block.timestamp;
        }
        uint pastTime = block.timestamp - lockData_.startedAt;
        if (pastTime < lockData_.duration) {
            return lockData_.duration - pastTime;
        } else {
            return 0;
        }
    }

    function prolong(
        SLock storage lockData_,
        uint amount_,
        uint duration_
    )
        internal
    {
        if (lockData_.amount == 0) {
            require(amount_ > 0 && duration_ > 0, "amount_ = 0 or duration_ = 0");
        } else {
            require(amount_ > 0 || duration_ > 0, "amount_ = 0 and duration_ = 0");
        }

        lockData_.amount += amount_;

        uint rd = restDuration(lockData_);
        if (rd == 0) {
            lockData_.duration = duration_;
            lockData_.startedAt = block.timestamp;
            return;
        }

        lockData_.duration += duration_;
    }

    function isUnlocked(
        SLock memory lockData_,
        uint fs_,
        bool isPoolOwner_
    )
        internal
        view
        returns(bool)
    {
        uint mFactor = isPoolOwner_ ? 2 * LPercentage.DEMI - fs_ : fs_;
        uint duration = lockData_.duration * mFactor / LPercentage.DEMI;
        uint elapsedTime = block.timestamp - lockData_.startedAt;
        return elapsedTime >= duration;
    }

    function calDuration(
        SLock memory lockData_,
        uint fs_,
        bool isPoolOwner_
    )
        internal
        pure
        returns(uint)
    {
        uint mFactor = isPoolOwner_ ? 2 * LPercentage.DEMI - fs_ : fs_;
        uint duration = lockData_.duration * mFactor / LPercentage.DEMI;
        return duration;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;

library LPercentage {
    uint constant public DEMI = 10000;
    uint constant public DEMIE2 = DEMI * DEMI;
    uint constant public DEMIE3 = DEMIE2 * DEMI;

    function validatePercent(
        uint percent_
    )
        internal
        pure
    {
        // 100% == DEMI == 10000
        require(percent_ <= DEMI, "invalid percent");
    }

    function getPercentA(
        uint value,
        uint percent
    )
        internal
        pure
        returns(uint)
    {
        return value * percent / DEMI;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;

import "./LPercentage.sol";

library LProfile {
    // fs: Financial_stability
    // invert fs: ifs = 1 - fs
    // multiplied DEMI = 10000

    function invertOf(
        uint value_
    )
        internal
        pure
        returns(uint)
    {
        return LPercentage.DEMI - value_;
    }

    function calBooster(
        uint boostVotePower_,
        uint maxBoostVotePower_,
        uint maxBooster_
    )
        pure
        internal
        returns(uint)
    {
        uint max = boostVotePower_ > maxBoostVotePower_ ? boostVotePower_ : maxBoostVotePower_;
        if (max == 0) {
            return LPercentage.DEMI;
        }
        return LPercentage.DEMI + LPercentage.DEMI * (maxBooster_ - 1) * boostVotePower_ / max;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;
pragma abicoder v2;

contract Initializable {
  bool private _isNotInitializable;
  address private _deployerOrigin;

  constructor()
  {
    _deployerOrigin = tx.origin;
  }

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(!_isNotInitializable, "isNotInitializable");
    require(tx.origin == _deployerOrigin || _deployerOrigin == address(0x0), "initializer access denied");
    _;
    _isNotInitializable = true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

interface IAccessControl {
    function addAdmins(
        address[] memory accounts_
    )
        external;

    function removeAdmins(
        address[] memory accounts_
    )
        external;

    /*
        view
    */

    function isOwner(
        address account_
    )
        external
        returns(bool);

    function isAdmin(
        address account_
    )
        external
        view
        returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

interface ICashier {
    function clean()
        external;

    function cleanTo()
        external
        view
        returns(address);

    function currentBalance()
        external
        view
        returns(uint);

    function lastestBalance()
        external
        view
        returns(uint); 
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import "./ICashier.sol";

interface IDistributor is ICashier {
    function initDistributor(
        address accessControl_,
        address dToken_,
        address rewardToken_
    )
        external;

    function beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    )
        external;

    function distribute()
        external;

    function rewardOf(
        address account_
    )
        external
        view
        returns(uint);

    function claimFor(
        address account_,
        address dest_
    )
        external;        
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import "./IPERC20.sol";

interface IDToken is IPERC20 {
    function initDToken(
        address accessControl_,
        string memory name_,
        string memory symbol_,
        address[] memory distributorAddrs_
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import "./IPERC20.sol";
import "./ICashier.sol";

interface IEarning is IPERC20, ICashier {
    function initEarning(
        address token_,
        address profileCAddr_,
        address accessControl_,
        string memory name_,
        string memory symbol_
    )
        external;

    function updateMaxEarning(
        address account_,
        uint maxEarning_
    )
        external;

    function shareCommission(
        address account_
    )
        external;

    function update(
        address account_,
        bool needShareComm_
    )
        external;

    function withdraw(
        address account_,
        uint amount_,
        address dest_
    )
        external;

    function earningOf(
        address account_
    )
        external
        view
        returns(uint);

    function maxEarningOf(
        address account_
    )
        external
        view
        returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import "../../lib/LLocker.sol";

import "./ICashier.sol";

interface ILocker is ICashier {
    function initLocker(
        address accessControl_,
        address token_,
        address profileCAddr_,
        address penaltyAddress_
    )
        external;

    function lock(
        address account_,
        address poolOwner_,
        uint duration_
    )
        external;

    function withdraw(
        address account_,
        address poolOwner_,
        address dest_,
        uint amount_,
        bool isForced_
    )
        external;

    function penaltyAddress()
        external
        view
        returns(address);

    function getLockId(
        address account_,
        address poolOwner_
    )
        external
        pure
        returns(bytes32);

    function getLockDataById(
        bytes32 lockId_
    )
        external
        view
        returns(LLocker.SLock memory);

    function getLockData(
        address account_,
        address poolOwner_
    )
        external
        view
        returns(LLocker.SLock memory);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import "../../lib/LLocker.sol";

import "./ILocker.sol";

interface IPCLocker is ILocker {
    function getMintedPower(
        address account_,
        address poolOwner_
    )
        external
        view
        returns(uint);

    function incMintedPower(
        address account_,
        address poolOwner_,
        uint amount_
    )
        external;

    function decMintedPower(
        address account_,
        address poolOwner_,
        uint amount_
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IATHBalance {
    function athBalance()
    external
    view
    returns(uint);
}

interface IPERC20 is IERC20, IATHBalance {
    function initPERC20(
        address owner_,
        string memory name_,
        string memory symbol_
    )
        external;

    function mint(
        address account_,
        uint amount_
    )
        external;

    function burn(
        address account_,
        uint amount_
    )
        external;

    function needAthRecord()
        external
        view
        returns(bool);

    function activeAthRecord()
        external;

    function deactiveAthRecord()
        external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;
pragma abicoder v2;

import "./Initializable.sol";

import "./interfaces/IAccessControl.sol";


// interface IBlast {
//   // Note: the full interface for IBlast can be found below
//   function configureClaimableGas() external;
//   function configureGovernor(address governor) external;
// }
// interface IBlastPoints {
//   function configurePointsOperator(address operator) external;
// }

// // https://docs.blast.io/building/guides/gas-fees
// // added constant: BLAST_GOV
// contract BlastClaimableGas {
//   IBlast public constant BLAST = IBlast(0x4300000000000000000000000000000000000002);
//   // todo
//   // replace gov address
//   address constant private BLAST_GOV = address(0x6d9cD20Ba0Dc1CCE0C645a6b5759f5ad1bD2704F);

//   function initClaimableGas() internal {
//     BLAST.configureClaimableGas();
//     // This sets the contract's governor. This call must come last because after
//     // the governor is set, this contract will lose the ability to configure itself.
//     BLAST.configureGovernor(BLAST_GOV);
//     IBlastPoints(0x2536FE9ab3F511540F2f9e2eC2A805005C3Dd800).configurePointsOperator(0x6d9cD20Ba0Dc1CCE0C645a6b5759f5ad1bD2704F);
//   }
// }

// contract UseAccessControl is Initializable, BlastClaimableGas {
contract UseAccessControl is Initializable {
    event ApproveAdmin(
        address indexed account,
        address indexed admin
    );

    event RevokeAdmin(
        address indexed account,
        address indexed admin
    );

    modifier onlyOwner() {
        require(_accessControl.isOwner(msg.sender), "onlyOwner");
        _;
    }

    modifier onlyAdmin() {
        require(_accessControl.isAdmin(msg.sender), "onlyAdmin");
        _;
    }

    modifier onlyApprovedAdmin(
        address account_
    )
    {
        address admin = msg.sender;
        require(_accessControl.isAdmin(admin), "onlyAdmin");
        require(_isApprovedAdmin[account_][admin], "onlyApprovedAdmin");
        _;
    }

    IAccessControl internal _accessControl;

    mapping(address => mapping(address => bool)) private _isApprovedAdmin;

    function initUseAccessControl(
        address accessControl_
    )
        public
        initializer
    {
        _accessControl = IAccessControl(accessControl_);
        // initClaimableGas();
    }

    function approveAdmin(
        address admin_
    )
        external
    {
        address account = msg.sender;
        require(_accessControl.isAdmin(admin_), "onlyAdmin");
        require(!_isApprovedAdmin[account][admin_], "onlyNotApprovedAdmin");
        _isApprovedAdmin[account][admin_] = true;
        emit ApproveAdmin(account, admin_);
    }

    function revokeAdmin(
        address admin_
    )
        external
    {
        address account = msg.sender;
        // require(_accessControl.isAdmin(admin_), "onlyAdmin");
        require(_isApprovedAdmin[account][admin_], "onlyApprovedAdmin");
        _isApprovedAdmin[account][admin_] = false;
        emit RevokeAdmin(account, admin_);
    }

    function isApprovedAdmin(
        address account_,
        address admin_
    )
        external
        view
        returns(bool)
    {
        return _isApprovedAdmin[account_][admin_];
    }
}