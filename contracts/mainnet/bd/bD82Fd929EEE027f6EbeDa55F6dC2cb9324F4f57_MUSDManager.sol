// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import {IERC20} from "./IERC20.sol";

import {IRates} from "./IRates.sol";
import {IMetaManager} from "./IMetaManager.sol";

import {Allowed} from "./Allowed.sol";
import {Constants} from "./Constants.sol";
import {IHelper} from "./IHelper.sol";
import {IMUSD} from "./IMUSD.sol";
import {IMUSDManager} from "./IMUSDManager.sol";
import {IRole} from "./IRole.sol";

import {IRewards} from "./IRewards.sol";

interface IGLPRewardsRouter {
    function claimFees() external;
}

contract MUSDManager is IMUSDManager, Allowed {
    // Global variables
    uint256 public totalDeposited;
    uint256 public totalBadDebt;

    // Token variables
    IERC20 public glp;
    IMUSD public mUSD;
    IRates public rates;
    IMetaManager public metaMgr;

    // fund level
    IHelper public helper;
    IRewards public mintingRewards;

    // provider level
    IRole public role;

    // GLP Rewards Router
    IGLPRewardsRouter public router; 

    // Min GLP
    uint256 public minGLP = Constants.PINT * 1000;

    // User level balances
    mapping(address => uint256) public deposited;
    mapping(address => uint256) public borrowed;
    mapping(address => bool) public redemptionProvider;

    event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    event Withdraw(address indexed user, uint256 amount, uint256 timestamp);
    event Mint(
        address indexed sponsor,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 timestamp
    );
    event Burn(
        address indexed provider,
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );
    event RedemptionProvider(address indexed user, bool status);
    event FeeDistributed(
        address indexed feeAddress,
        uint256 fee,
        uint256 timestamp
    );
    event InterestDistributed(
        uint256 glpAdded,
        uint256 payoutMUSD,
        uint256 timestamp
    );
    event RigidRedemption(
        address indexed caller,
        address indexed provider,
        uint256 musdAmount,
        uint256 glpAmount,
        uint256 timestamp
    );
    event LiquidationRecord(
        address indexed provider,
        address indexed keeper,
        address indexed onBehalfOf,
        uint256 musdamount,
        uint256 LiquidateglpAmount,
        uint256 keeperReward,
        bool superLiquidation,
        uint256 timestamp
    );

    constructor(address _glp, address _mUSD) Allowed(msg.sender) {
        glp = IERC20(_glp);
        mUSD = IMUSD(_mUSD);
    }

    function setHelpers(address _helper, address _rates, address _metaMgr,
     address _mintingRewards, address _role) external onlyOwner {
        helper = IHelper(_helper);
        rates = IRates(_rates);
        metaMgr = IMetaManager(_metaMgr);
        mintingRewards = IRewards(_mintingRewards);
        role = IRole(_role);
    }

    function setRewardsRouter(address _router) public onlyOwner {
        require(_router != address(0), "!addr");
        router = IGLPRewardsRouter(_router);
    }

    function becomeRedemptionProvider(bool _bool) external {
        mintingRewards.refreshReward(msg.sender);
        redemptionProvider[msg.sender] = _bool;
        emit RedemptionProvider(msg.sender, _bool);
    }
    
    // Contract panic functions
    function pause(bool _toPause) external onlyOwner {
        if (_toPause) _pause();
        else _unpause();

    }

    // View functions
    function getBorrowedOf(address _user) external view returns (uint256) {
        return borrowed[_user];
    }

    function getDepositOf(address _user) external view returns (uint256) {
        return deposited[_user];
    }

    function isRedemptionProvider(address user) external override view returns (bool) {
        return redemptionProvider[user];
    }

    function cr(address _user) public view returns (uint256) {
        if (borrowed[_user] > 0) {
            return
                (deposited[_user] * helper.getPriceOfGLP() * 100) /
                borrowed[_user];
        }
        return type(uint256).max;
    }

    function totalSupply() external view returns (uint256) {
        return mUSD.totalSupply();
    }

    function _checkHealth(address _user) internal view {
        bool isUnder = cr(_user) < rates.getSafeCR();
        if (borrowed[_user] > 0 && isUnder) revert("Undercollateral");
    }

    // Setter functions
    function setMinGLP(uint256 _amount) external onlyOwner {
        require(_amount >= Constants.PINT, "Should be more GLP");
        minGLP = _amount;
    }

    function depositToMint(
        uint256 _amount,
        uint256 _mUSDAmount
    ) external whenNotPaused nonReentrant {
        address caller = msg.sender;
        require(
            _amount + deposited[caller] >= minGLP,
            "less than minGLP"
        );

        glp.transferFrom(caller, address(this), _amount);

        totalDeposited += _amount;
        deposited[caller] += _amount;

        if (_mUSDAmount > 0) {
            _mint(caller, _mUSDAmount);
        }
        emit Deposit(caller, _amount, block.timestamp);
    }

    function withdraw(uint256 _amount) external whenNotPaused nonReentrant {
        address caller = msg.sender;
        require(_amount > 0, "Invalid");
        require(deposited[caller] >= _amount, "NoBalance");

        totalDeposited -= _amount;
        deposited[caller] -= _amount;

        if (borrowed[caller] > 0) {
            _checkHealth(caller);
        }

        glp.transfer(caller, _amount);
        emit Withdraw(caller, _amount, block.timestamp);
    }

    function mint(uint256 _mUSDAmount) external whenNotPaused nonReentrant {
        address caller = msg.sender;
        require(_mUSDAmount > 0, "Zero value");
        require(
            deposited[caller] >= minGLP,
            "less than minGLP"
        );
        _mint(caller, _mUSDAmount);

        uint256 mUSDSupply = mUSD.totalSupply();
        if (
            (borrowed[caller] * 100) / mUSDSupply > 10 &&
            mUSDSupply > 10_000_000 * 1e18
        ) revert("Invalid mint");
    }

    function burn(uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount > 0, "Zero amount");
        _repay( msg.sender,  msg.sender, _amount);
    }

    function _mint(address _caller, uint256 _amount) internal {
        uint256 sharesAmount = mUSD.getSharesByMintedMUSD(_amount);
        mintingRewards.refreshReward(_caller);
        borrowed[_caller] += _amount;
        rates.saveFees();
        mUSD.mintShares(_caller, sharesAmount, _amount);
        _checkHealth(_caller);
        emit Mint(msg.sender, _caller, _amount, block.timestamp);
    }

    function _repay(
        address _provider,
        address _onBehalfOf,
        uint256 _mUSDamount
    ) internal {
        require(
            borrowed[_onBehalfOf] >= _mUSDamount,
            "!amount"
        );
        uint256 sharesAmt = mUSD.getSharesByMintedMUSD(_mUSDamount);
        mintingRewards.refreshReward(_onBehalfOf);
        borrowed[_onBehalfOf] -= _mUSDamount;
        rates.saveFees();
        mUSD.burnShares(_provider, sharesAmt, _mUSDamount);

        emit Burn(_provider, _onBehalfOf, _mUSDamount, block.timestamp);
    }

    function liquidation(
        address provider,
        address onBehalfOf,
        uint256 glpAmount
    ) external whenNotPaused nonReentrant {
        require(role.isLiquidationProvider(provider), "Not a liquidation provider");
        uint256 glpPrice = helper.getPriceOfGLP();
        uint256 onBehalfOfCR = cr(onBehalfOf);
        require(onBehalfOfCR < rates.getBadCR(), "Healthy");
        require(
            glpAmount * 2 <= deposited[onBehalfOf],
            "max 50%"
        );

        uint256 musdAmount = (glpAmount * glpPrice) / Constants.PINT;

        _repay(provider, onBehalfOf, musdAmount);
        uint256 reducedGLP = (glpAmount * 11) / 10;
        totalDeposited -= reducedGLP;
        deposited[onBehalfOf] -= reducedGLP;
        uint256 reward2keeper;
        if (provider == msg.sender) {
            glp.transfer(msg.sender, reducedGLP);
        } else {
            reward2keeper = (glpAmount * rates.getKR()) / Constants.HUNDRED_PERCENT;
            glp.transfer(provider, reducedGLP - reward2keeper);
            glp.transfer(msg.sender, reward2keeper);
        }
        emit LiquidationRecord(
            provider,
            msg.sender,
            onBehalfOf,
            musdAmount,
            reducedGLP,
            reward2keeper,
            false,
            block.timestamp
        );
    }

    function harvest() public {
        router.claimFees();
    }

    function superLiquidation(
        address provider,
        address onBehalfOf,
        uint256 glpAmount
    ) external whenNotPaused nonReentrant {
        require(role.isLiquidationProvider(provider), "Not a liquidation provider");
        uint256 glpPrice = helper.getPriceOfGLP();
        uint256 onBehalfOfCR = cr(onBehalfOf);
        uint256 globalCR = (totalDeposited * glpPrice * 100) /
            mUSD.totalSupply();
        require(globalCR < rates.getBadCR(), "gcr_healthy");
        require(
            onBehalfOfCR < Constants.SUPER_BAD_COLLATERAL_LIMIT,
            "CR>125%"
        );
        require(glpAmount <= deposited[onBehalfOf], "Invalid Amount");

        uint256 musdAmount = (glpAmount * glpPrice) / Constants.PINT;
        if (onBehalfOfCR >= 1e20) { 
            musdAmount = (musdAmount * 1e20) / onBehalfOfCR;
        }

        _repay(provider, onBehalfOf, musdAmount);

        totalDeposited -= glpAmount;
        deposited[onBehalfOf] -= glpAmount;

        if(deposited[onBehalfOf] == 0 && borrowed[onBehalfOf] > 0) { // Accounting bad debt
            totalBadDebt += borrowed[onBehalfOf]; 
            borrowed[onBehalfOf] = 0;
        }

        uint256 reward2keeper;
        if (msg.sender != provider && onBehalfOfCR >= (Constants.HUNDRED_PERCENT + rates.getKR())) {
            reward2keeper = (glpAmount * rates.getKR()) / Constants.HUNDRED_PERCENT; 
            glp.transfer(msg.sender, reward2keeper);
        }
        glp.transfer(provider, glpAmount - reward2keeper);

        emit LiquidationRecord(
            provider,
            msg.sender,
            onBehalfOf,
            musdAmount,
            glpAmount,
            reward2keeper,
            true,
            block.timestamp
        );
    }

    function rigidRedemption(
        address _provider,
        uint256 _mUSDAmount
    ) external whenNotPaused nonReentrant {
        address caller = msg.sender;
        require(
            redemptionProvider[_provider], 
            "Only provider"
        );
        require(
            borrowed[_provider] >= _mUSDAmount,
            "Invalid"
        );
        require(
            cr(_provider) >= Constants.REDEMPTION_PROVIDER_CR, 
            "No_collateral"
        );

        _repay(caller, _provider, _mUSDAmount);

        uint256 glpAmount = _mUSDAmount * (Constants.HUNDRED_PERCENT - rates.getRFee());
        glpAmount /= (helper.getPriceOfGLP() * Constants.HUNDERED);
        deposited[_provider] -= glpAmount;
        totalDeposited -= glpAmount;
        glp.transfer(caller, glpAmount);
        emit RigidRedemption(
            caller,
            _provider,
            _mUSDAmount,
            glpAmount,
            block.timestamp
        );
    }

    function excessIncomeDistribution(
        uint256 payAmount
    ) external whenNotPaused {
        address provider = msg.sender;
        require(role.isDistributionProvider(provider), "no provider");
        // Harvest the fees generated by GLP
        harvest(); 
        
        IERC20 rt = IERC20(helper.getRewardToken());
        uint256 priceOfRT = helper.getPriceOfRewardToken();
        uint256 payoutEther = (payAmount * Constants.PINT) / priceOfRT;

        require(
            payoutEther <= rt.balanceOf(address(this)),
            "No_income"
        );

        payAmount = (payAmount * (Constants.HUNDRED_PERCENT - rates.getEDR())) / Constants.HUNDRED_PERCENT; //Rewards to caller
        uint256 fees = rates.getHoldingFee() + rates.newHoldingFee();

        if (payAmount > fees) {
            _settleFees(provider, fees);
            uint256 sharesAmount = mUSD.getSharesByMintedMUSD(payAmount - fees);
            mUSD.burnShares(provider, sharesAmount, 0);
            rates.setAccumulatedFee(0);
        } else {
            _settleFees(provider, payAmount);
            rates.setAccumulatedFee(fees - payAmount);
        }
        emit FeeDistributed(address(metaMgr), fees, block.timestamp);
        rt.transfer(provider, payoutEther);
        emit InterestDistributed(payAmount, payAmount, block.timestamp);
    }

    function _settleFees(address _provider, uint256 _fee) private {
        uint256 treasuryFee = (_fee * rates.getTFee()) / Constants.HUNDRED_PERCENT;
        mUSD.transferFrom(_provider, rates.getTreasury(), treasuryFee);
        mUSD.transferFrom(_provider, address(metaMgr), _fee - treasuryFee);
        metaMgr.notifyRewardAmount(_fee - treasuryFee);
    }

    function repayBadDebt(uint256 _amount) public {
        require(totalBadDebt >= _amount, "Low debt");
        mUSD.burnShares(msg.sender, mUSD.getSharesByMintedMUSD(_amount), _amount);
        totalBadDebt -= _amount;
    }
}