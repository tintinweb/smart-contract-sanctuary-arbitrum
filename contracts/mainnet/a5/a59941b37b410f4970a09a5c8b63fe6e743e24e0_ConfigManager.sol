//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./KarrotInterfaces.sol";

/**
Manager for config variables

Notes:
- once operation is stable, timelock will be set as owner
- openKarrotChefDeposits: first stolen pool epoch (epoch 0) starts at the same time as the karrot chef deposits open
 */


contract ConfigManager is Ownable {
    //======================================================================================
    // setup
    //======================================================================================

    IRabbit public rabbit;
    IKarrotsToken public karrots;
    IStolenPool public stolenPool;
    IAttackRewardCalculator public rewardCalculator;
    IDexInterfacer public dexInterfacer;
    IKarrotChef public karrotChef;
    IFullProtec public karrotFullProtec;

    address public treasuryAddress; //(TESTING)main treasury
    address public treasuryBAddress; //(TESTING)funds from stolen funds pool
    address public sushiswapFactoryAddress; //arb one mainnet + eth goerli + fuji
    address public sushiswapRouterAddress; //arb one mainnet + eth goerli + fuji
    address public karrotsPoolAddress;
    address public timelockControllerAddress;
    address public karrotsAddress;
    address public karrotChefAddress;
    address public karrotFullProtecAddress;
    address public karrotStolenPoolAddress;
    address public rabbitAddress;
    address public randomizerAddress; //mainnet (arb one) 0x5b8bB80f2d72D0C85caB8fB169e8170A05C94bAF
    address public attackRewardCalculatorAddress;
    address public dexInterfacerAddress;
    address public presaleDistributorAddress; //testing is 0xFB1423Bf6b2CB13b4c86AA19AE4Bf266C9B36460
    address public teamSplitterAddress; //testing is 0x7639c5Fba3878f9717c90037bF0F355E40B49a6E

    constructor(
        address _treasuryAddress,
        address _treasuryBAddress,
        address _sushiswapFactoryAddress,
        address _sushiswapRouterAddress,
        address _randomizerAddress,
        address _presaleDistributorAddress,
        address _teamSplitterAddress
    ) {
        treasuryAddress = _treasuryAddress;
        treasuryBAddress = _treasuryBAddress;
        sushiswapFactoryAddress = _sushiswapFactoryAddress;
        sushiswapRouterAddress = _sushiswapRouterAddress;
        randomizerAddress = _randomizerAddress;
        presaleDistributorAddress = _presaleDistributorAddress;
        teamSplitterAddress = _teamSplitterAddress;
    }

    function transferOwnershipToTimelock() external onlyOwner {
        transferOwnership(timelockControllerAddress);
    }

    //======================================================================================
    // include setters for each "global" parameter --> gated by onlyOwner
    //======================================================================================

    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        treasuryAddress = _treasuryAddress;
    }

    function setTreasuryBAddress(address _treasuryBAddress) external onlyOwner {
        treasuryBAddress = _treasuryBAddress;      
    }

    function setSushiFactoryAddress(address _sushiswapFactoryAddress) external onlyOwner {
        sushiswapFactoryAddress = _sushiswapFactoryAddress;        
    }

    function setSushiRouterAddress(address _sushiswapRouterAddress) external onlyOwner {
        sushiswapRouterAddress = _sushiswapRouterAddress;        
    }

    function setKarrotsPoolAddress(address _karrotsPoolAddress) external onlyOwner {
        karrotsPoolAddress = _karrotsPoolAddress;        
    }

    function setTimelockControllerAddress(address _timelockControllerAddress) external onlyOwner {
        timelockControllerAddress = _timelockControllerAddress;       
    }

    function setKarrotTokenAddress(address _karrotTokenAddress) external onlyOwner {
        karrotsAddress = _karrotTokenAddress;
        karrots = IKarrotsToken(_karrotTokenAddress);    
    }

    function setKarrotChefAddress(address _karrotChefAddress) external onlyOwner {
        karrotChefAddress = _karrotChefAddress;
        karrotChef = IKarrotChef(_karrotChefAddress);       
    }

    function setKarrotFullProtecAddress(address _fullProtecAddress) external onlyOwner {
        karrotFullProtecAddress = _fullProtecAddress;
        karrotFullProtec = IFullProtec(_fullProtecAddress);      
    }

    function setKarrotStolenPoolAddress(address _stolenPoolAddress) external onlyOwner {
        karrotStolenPoolAddress = _stolenPoolAddress;
        stolenPool = IStolenPool(_stolenPoolAddress);   
    }

    function setRabbitAddress(address _rabbitAddress) external onlyOwner {
        rabbitAddress = _rabbitAddress;
        rabbit = IRabbit(_rabbitAddress);       
    }

    function setRandomizerAddress(address _randomizerRequesterAddress) external onlyOwner {
        randomizerAddress = _randomizerRequesterAddress;        
    }

    function setRewardCalculatorAddress(address _rewardCalculatorAddress) external onlyOwner {
        attackRewardCalculatorAddress = _rewardCalculatorAddress;
        rewardCalculator = IAttackRewardCalculator(_rewardCalculatorAddress);       
    }

    function setDexInterfacerAddress(address _dexInterfacerAddress) external onlyOwner {
        dexInterfacerAddress = _dexInterfacerAddress;
        dexInterfacer = IDexInterfacer(_dexInterfacerAddress);      
    }

    function setPresaleDistributorAddress(address _presaleClaimContractAddress) external onlyOwner {
        presaleDistributorAddress = _presaleClaimContractAddress;      
    }

    function setTeamSplitterAddress(address _teamSplitterAddress) external onlyOwner {
        teamSplitterAddress = _teamSplitterAddress;     
    }

    //======================================================================================
    // NEW SETTERS FOR KARROTS CONFIG (CALLS FUNCTIONS ON KARROTS)
    //======================================================================================

    function setSellTaxIsActive(bool _sellTaxIsActive) external onlyOwner {
        karrots.setSellTaxIsActive(_sellTaxIsActive);
    }

    function setBuyTaxIsActive(bool _buyTaxIsActive) external onlyOwner {
        karrots.setBuyTaxIsActive(_buyTaxIsActive);
    }

    function setBuyTaxRate(uint16 _buyTaxRate) external onlyOwner {
        karrots.setBuyTaxRate(_buyTaxRate);
    }

    function setSellTaxRate(uint16 _sellTaxRate) external onlyOwner {
        karrots.setSellTaxRate(_sellTaxRate);
    }

    function setTradingIsOpen(bool _tradingIsOpen) external onlyOwner {
        karrots.setTradingIsOpen(_tradingIsOpen);
    }

    function addDexAddress(address _dexAddress) external onlyOwner {
        karrots.addDexAddress(_dexAddress);
    }

    function setMaxIndexDelta(uint256 _maxIndexDelta) external onlyOwner {
        karrots.setMaxIndexDelta(_maxIndexDelta);
    }

    //======================================================================================
    // NEW SETTERS FOR RABBIT (CALLS FUNCTIONS ON RABBIT)
    //======================================================================================

    function setRabbitMintIsOpen(bool _rabbitMintIsOpen) external onlyOwner {
        rabbit.setRabbitMintIsOpen(_rabbitMintIsOpen);
    }

    function setRabbitBatchSize(uint16 _rabbitBatchSize) external onlyOwner {
        rabbit.setRabbitBatchSize(_rabbitBatchSize);
    }

    function setRabbitMintSecondsBetweenBatches(uint32 _rabbitMintSecondsBetweenBatches) external onlyOwner {
        rabbit.setRabbitMintSecondsBetweenBatches(_rabbitMintSecondsBetweenBatches);
    }

    function setRabbitMaxPerWallet(uint8 _rabbitMaxPerWallet) external onlyOwner {
        rabbit.setRabbitMaxPerWallet(_rabbitMaxPerWallet);
    }

    function setRabbitMintPriceInKarrots(uint72 _rabbitMintPriceInKarrots) external onlyOwner {
        rabbit.setRabbitMintPriceInKarrots(_rabbitMintPriceInKarrots);
    }

    function setRabbitRerollPriceInKarrots(uint72 _rabbitRerollPriceInKarrots) external onlyOwner {
        rabbit.setRabbitRerollPriceInKarrots(_rabbitRerollPriceInKarrots);
    }

    function setRabbitMintKarrotFeePercentageToBurn(uint16 _rabbitMintKarrotFeePercentageToBurn) external onlyOwner {
        rabbit.setRabbitMintKarrotFeePercentageToBurn(_rabbitMintKarrotFeePercentageToBurn);
    }

    function setRabbitMintKarrotFeePercentageToTreasury(
        uint16 _rabbitMintKarrotFeePercentageToTreasury
    ) external onlyOwner {
        rabbit.setRabbitMintKarrotFeePercentageToTreasury(_rabbitMintKarrotFeePercentageToTreasury);
    }

    function setRabbitMintTier1Threshold(uint16 _rabbitMintTier1Threshold) external onlyOwner {
        rabbit.setRabbitMintTier1Threshold(_rabbitMintTier1Threshold);
    }

    function setRabbitMintTier2Threshold(uint16 _rabbitMintTier2Threshold) external onlyOwner {
        rabbit.setRabbitMintTier2Threshold(_rabbitMintTier2Threshold);
    }

    function setRabbitTier1HP(uint8 _rabbitTier1HP) external onlyOwner {
        rabbit.setRabbitTier1HP(_rabbitTier1HP);
    }

    function setRabbitTier2HP(uint8 _rabbitTier2HP) external onlyOwner {
        rabbit.setRabbitTier2HP(_rabbitTier2HP);
    }

    function setRabbitTier3HP(uint8 _rabbitTier3HP) external onlyOwner {
        rabbit.setRabbitTier3HP(_rabbitTier3HP);
    }

    function setRabbitTier1HitRate(uint16 _rabbitTier1HitRate) external onlyOwner {
        rabbit.setRabbitTier1HitRate(_rabbitTier1HitRate);
    }

    function setRabbitTier2HitRate(uint16 _rabbitTier2HitRate) external onlyOwner {
        rabbit.setRabbitTier2HitRate(_rabbitTier2HitRate);
    }

    function setRabbitTier3HitRate(uint16 _rabbitTier3HitRate) external onlyOwner {
        rabbit.setRabbitTier3HitRate(_rabbitTier3HitRate);
    }

    //call this EPOCH_LENGTH after opening deposits for KarrotChef! will revert otherwise...
    function setRabbitAttackIsOpen(bool _isOpen) external onlyOwner {
        stolenPool.setStolenPoolAttackIsOpen(_isOpen);
        rabbit.setRabbitAttackIsOpen(_isOpen);
    }

    function setAttackCooldownSeconds(uint32 _attackCooldownSeconds) external onlyOwner {
        rabbit.setAttackCooldownSeconds(_attackCooldownSeconds);
    }

    function setAttackHPDeductionAmount(uint8 _attackHPDeductionAmount) external onlyOwner {
        rabbit.setAttackHPDeductionAmount(_attackHPDeductionAmount);
    }

    function setAttackHPDeductionThreshold(uint16 _attackHPDeductionThreshold) external onlyOwner {
        rabbit.setAttackHPDeductionThreshold(_attackHPDeductionThreshold);
    }

    function setRandomizerMintCallbackGasLimit(uint24 _randomizerMintCallbackGasLimit) external onlyOwner {
        rabbit.setRandomizerMintCallbackGasLimit(_randomizerMintCallbackGasLimit);
    }

    function setRandomizerAttackCallbackGasLimit(uint24 _randomizerAttackCallbackGasLimit) external onlyOwner {
        rabbit.setRandomizerAttackCallbackGasLimit(_randomizerAttackCallbackGasLimit);
    }

    //======================================================================================
    // NEW SETTERS FOR KARROT CHEF (CALLS FUNCTIONS ON KARROT CHEF)
    //======================================================================================

    function setKarrotChefPoolAllocPoints(uint256 _pid, uint128 _allocPoints, bool _withUpdate) external onlyOwner {
        karrotChef.setAllocationPoint(_pid, _allocPoints, _withUpdate);
    }

    function setKarrotChefLockDuration(uint256 _pid, uint256 _lockDuration) external onlyOwner {
        karrotChef.setLockDuration(_pid, _lockDuration);
    }

    function updateKarrotChefRewardPerBlock(uint88 _karrotChefRewardPerBlock) external onlyOwner {
        karrotChef.updateRewardPerBlock(_karrotChefRewardPerBlock);
    }

    function setKarrotChefCompoundRatio(uint48 _compoundRatio) external onlyOwner {
        karrotChef.setCompoundRatio(_compoundRatio);
    }

    function openKarrotChefDeposits() external onlyOwner {
        karrotChef.openKarrotChefDeposits();
        stolenPool.setStolenPoolOpenTimestamp();
    }

    function setDepositIsPaused(bool _depositIsPaused) external onlyOwner {
        karrotChef.setDepositIsPaused(_depositIsPaused);
    }

    function setClaimTaxRate(uint16 _maxClaimTaxRate) external onlyOwner {
        karrotChef.setClaimTaxRate(_maxClaimTaxRate);
    }

    function setRandomizerClaimCallbackGasLimit(uint24 _randomizerCallbackGasLimit) external onlyOwner {
        karrotChef.setRandomizerClaimCallbackGasLimit(_randomizerCallbackGasLimit);
    }

    function setFullProtecLiquidityProportion(uint16 _fullProtecLiquidityProportion) external onlyOwner {
        karrotChef.setFullProtecLiquidityProportion(_fullProtecLiquidityProportion);
    }

    function setClaimTaxChance(uint16 _claimTaxChance) external onlyOwner {
        karrotChef.setClaimTaxChance(_claimTaxChance);
    }

    function withdrawRequestFeeFunds(address _to, uint256 _amount) external onlyOwner {
        karrotChef.randomizerWithdrawKarrotChef(_to, _amount);
        rabbit.randomizerWithdrawRabbit(_to, _amount);
    }

    function setRefundsAreOn(bool _refundsAreOn) external onlyOwner {
        karrotChef.setRefundsAreOn(_refundsAreOn);
        rabbit.setRefundsAreOn(_refundsAreOn);
    }

    //======================================================================================
    // NEW SETTERS FOR FULL PROTEC
    //======================================================================================

    function openFullProtecDeposits() external onlyOwner {
        karrotFullProtec.openFullProtecDeposits();
    }

    function setFullProtecLockDuration(uint32 _lockDuration) external onlyOwner {
        karrotFullProtec.setFullProtecLockDuration(_lockDuration);
    }

    function setThresholdFullProtecKarrotBalance(uint224 _thresholdFullProtecKarrotBalance) external onlyOwner {
        karrotFullProtec.setThresholdFullProtecKarrotBalance(_thresholdFullProtecKarrotBalance);
    }

    //======================================================================================
    // NEW SETTERS FOR STOLEN POOL 
    //======================================================================================

    function setAttackBurnPercentage(uint16 _attackBurnPercentage) external onlyOwner {
        stolenPool.setAttackBurnPercentage(_attackBurnPercentage);
    }

    function setStolenPoolEpochLength(uint32 _stolenPoolEpochLength) external onlyOwner {
        stolenPool.setStolenPoolEpochLength(_stolenPoolEpochLength);
    }

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
pragma solidity ^0.8.19;

//================================================================================
// COMPLETE (interfaces with all functions used across contracts)
//================================================================================

interface IConfig {
    function dexInterfacerAddress() external view returns (address);
    function karrotsAddress() external view returns (address);
    function karrotChefAddress() external view returns (address);
    function karrotStolenPoolAddress() external view returns (address);
    function karrotFullProtecAddress() external view returns (address);
    function karrotsPoolAddress() external view returns (address);
    function rabbitAddress() external view returns (address);
    function randomizerAddress() external view returns (address);
    function sushiswapRouterAddress() external view returns (address);
    function sushiswapFactoryAddress() external view returns (address);
    function treasuryAddress() external view returns (address);
    function treasuryBAddress() external view returns (address);
    function teamSplitterAddress() external view returns (address);
    function presaleDistributorAddress() external view returns (address);
    function attackRewardCalculatorAddress() external view returns (address);
}

interface IKarrotChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function claim(uint256 _pid) external;
    function attack() external;
    function randomizerWithdrawKarrotChef(address _to, uint256 _amount) external;
    function getUserStakedAmount(address _user) external view returns (uint256);
    function getTotalStakedAmount() external view returns (uint256);
    function updateConfig() external;
    function setAllocationPoint(uint256 _pid, uint128 _allocPoint, bool _withUpdatePools) external;
    function setLockDuration(uint256 _pid, uint256 _lockDuration) external;
    function updateRewardPerBlock(uint88 _rewardPerBlock) external;
    function setCompoundRatio(uint48 _compoundRatio) external;
    function openKarrotChefDeposits() external;
    function setDepositIsPaused(bool _isPaused) external;
    function setThresholdFullProtecKarrotBalance(uint256 _thresholdFullProtecKarrotBalance) external;
    function setClaimTaxRate(uint16 _maxTaxRate) external;
    function randomzierWithdraw(address _to, uint256 _amount) external;
    function setRandomizerClaimCallbackGasLimit(uint24 _randomizerClaimCallbackGasLimit) external;
    function setFullProtecLiquidityProportion(uint16 _fullProtecLiquidityProportion) external;
    function setClaimTaxChance(uint16 _claimTaxChance) external;
    function setRefundsAreOn(bool _refundsAreOn) external;
}

interface IKarrotsToken {
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function updateConfig() external;
    function addDexAddress(address _dexAddress) external;
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function rebase(uint256 epoch, uint256 indexDelta, bool positive) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transferUnderlying(address to, uint256 value) external returns (bool);
    function fragmentToKarrots(uint256 value) external view returns (uint256);
    function karrotsToFragment(uint256 karrots) external view returns (uint256);
    function balanceOfUnderlying(address who) external view returns (uint256);
    function setSellTaxRate(uint16 _sellTaxRate) external;
    function setBuyTaxRate(uint16 _buyTaxRate) external;
    function setSellTaxIsActive(bool _sellTaxIsActive) external;
    function setBuyTaxIsActive(bool _buyTaxIsActive) external;
    function setTradingIsOpen(bool _tradingIsOpen) external;
    function setMaxIndexDelta(uint256 _maxIndexDelta) external;
}

interface IRabbit {
    function getRabbitSupply() external view returns (uint256);
    function getRabbitIdsByOwner(address _owner) external view returns (uint256[] memory);
    function updateConfig() external;
    function randomizerWithdrawRabbit(address _to, uint256 _amount) external;
    function setRabbitMintIsOpen(bool _isOpen) external;
    function setRabbitBatchSize(uint16 _batchSize) external;
    function setRabbitMintSecondsBetweenBatches(uint32 _secondsBetweenBatches) external;
    function setRabbitMaxPerWallet(uint8 _maxPerWallet) external;
    function setRabbitMintPriceInKarrots(uint72 _priceInKarrots) external;
    function setRabbitRerollPriceInKarrots(uint72 _priceInKarrots) external;
    function setRabbitMintKarrotFeePercentageToBurn(uint16 _karrotFeePercentageToBurn) external;
    function setRabbitMintKarrotFeePercentageToTreasury(uint16 _karrotFeePercentageToTreasury) external;
    function setRabbitMintTier1Threshold(uint16 _tier1Threshold) external;
    function setRabbitMintTier2Threshold(uint16 _tier2Threshold) external;
    function setRabbitTier1HP(uint8 _tier1HP) external;
    function setRabbitTier2HP(uint8 _tier2HP) external;
    function setRabbitTier3HP(uint8 _tier3HP) external;
    function setRabbitTier1HitRate(uint16 _tier1HitRate) external;
    function setRabbitTier2HitRate(uint16 _tier2HitRate) external;
    function setRabbitTier3HitRate(uint16 _tier3HitRate) external;
    function setRabbitAttackIsOpen(bool _isOpen) external;
    function setAttackCooldownSeconds(uint32 _attackCooldownSeconds) external;
    function setAttackHPDeductionAmount(uint8 _attackHPDeductionAmount) external;
    function setAttackHPDeductionThreshold(uint16 _attackHPDeductionThreshold) external;
    function setRandomizerMintCallbackGasLimit(uint24 _randomizerMintCallbackGasLimit) external;
    function setRandomizerAttackCallbackGasLimit(uint24 _randomizerAttackCallbackGasLimit) external;
    function setRefundsAreOn(bool _refundsAreOn) external;
}

interface IFullProtec {
    function getUserStakedAmount(address _user) external view returns (uint256);
    function getTotalStakedAmount() external view returns (uint256);
    function getIsUserAboveThresholdToAvoidClaimTax(address _user) external view returns (bool);
    function updateConfig() external;
    function openFullProtecDeposits() external;
    function setFullProtecLockDuration(uint32 _lockDuration) external;
    function setThresholdFullProtecKarrotBalance(uint224 _thresholdFullProtecKarrotBalance) external;
}

interface IStolenPool {
    function deposit(uint256 _amount) external;
    function attack(address _sender, uint256 _rabbitTier, uint256 _rabbitId) external;
    function updateConfig() external;
    function setStolenPoolOpenTimestamp() external;
    function setStolenPoolAttackIsOpen(bool _isOpen) external;
    function setAttackBurnPercentage(uint16 _attackBurnPercentage) external;
    function setStolenPoolEpochLength(uint32 _epochLength) external;
}

interface IAttackRewardCalculator {
    function calculateRewardPerAttackByTier(
        uint256 tier1Attacks,
        uint256 tier2Attacks,
        uint256 tier3Attacks,
        uint256 tier1Weight,
        uint256 tier2Weight,
        uint256 tier3Weight,
        uint256 totalKarrotsDepositedThisEpoch
    ) external view returns (uint256[] memory);
}

interface IDexInterfacer {
    function updateConfig() external;
    function depositEth() external payable;
    function depositErc20(uint256 _amount) external;
    function getPoolIsCreated() external view returns (bool);
    function getPoolIsFunded() external view returns (bool);
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