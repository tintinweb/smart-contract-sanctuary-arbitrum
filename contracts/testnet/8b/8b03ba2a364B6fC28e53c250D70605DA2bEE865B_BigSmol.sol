// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";

interface ISmolPool {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function rebase(uint256 indexDelta, bool positive) external;
    function getScalingFactor() external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface ISmols {
    function walletOfOwner(address _address) external view returns (uint256[] memory);
}

interface IRandomizer {
    function requestRandomNumber() external returns(uint256);
    function revealRandomNumber(uint256 _requestId) external view returns(uint256);
    function isRandomReady(uint256 _requestId) external view returns(bool);
}

contract BigSmol is Ownable, ReentrancyGuard {

    event Rebased(address winner, address loser, uint256 poolOneSupplyBefore, uint256 poolOneSupplyAfter, uint256 poolTwoSupplyBefore, uint256 poolTwoSupplyAfter);

    enum Results { NONE, POOL_ONE, POOL_TWO }

    address public smolToken;

    address public poolOne;
    address public poolTwo;

    bool public lockSetters = false;

    address public randomizerContract = 0x9b58fc8c7B224Ae8479DA7E6eD37CA4Ac58099a9;
    address public smolContract = 0x2A7eff2E0Bf139Ad640320BCa7Dd0C7ee95FADC1;

    uint256 public uncleDanasTokens;
    uint256 public smolTokensToClaim;

    uint256 public epochNumber;
    uint256 public lockPoolsAt;
    uint256 private randomRequestId;

    uint256 private poolCycle = 3 minutes;

    uint256 claimPerSmol = 10000 ether;

    uint256 private constant BASE = 10**18;

    Results[] lastFiveResults = [Results.NONE, Results.NONE, Results.NONE, Results.NONE, Results.NONE];

    mapping(uint256 => bool) public smolClaimed;

    constructor(address _smolToken) {
        smolToken = _smolToken;

        lockPoolsAt = block.timestamp + poolCycle;
    }

    modifier onlyOrigin() {
        require(msg.sender == tx.origin, "EOAs only");
        _;
    }

    function poolsOpen() public view returns (bool) {
        return block.timestamp <= lockPoolsAt;
    }

    function stakeToPool(uint256 amount, address pool) external nonReentrant onlyOrigin {
        require(pool == poolOne || pool == poolTwo, "Invalid pool address");
        require(poolsOpen(), "Pools are locked");

        IERC20(smolToken).transferFrom(msg.sender, address(this), amount);

        ISmolPool(pool).mint(msg.sender, amount);
    }

    function unstakeFromPool(address pool, uint256 amount) external nonReentrant onlyOrigin {
        require(pool == poolOne || pool == poolTwo, "Invalid pool address");
        require(poolsOpen(), "Pools are locked");

        ISmolPool(pool).burn(msg.sender, amount);

        IERC20(smolToken).transfer(msg.sender, amount);
    }


    function _handleRebase(address _poolOne, address _poolTwo) internal {
        ISmolPool smolPoolOne = ISmolPool(_poolOne);
        ISmolPool smolPoolTwo = ISmolPool(_poolTwo);

        if(smolPoolOne.totalSupply() == 0 || smolPoolTwo.totalSupply() == 0) return;

        uint256 indexDeltaWinner = BASE / 10;

        uint256 poolTwoTotalSupply = IERC20(_poolTwo).totalSupply();
        uint256 tokensLostInLoserPool = (poolTwoTotalSupply * indexDeltaWinner) / BASE;
        uint256 halfTokensLostInLoserPool = tokensLostInLoserPool / 2;

        uint256 indexDeltaLoser = BASE / 10;

        if (uncleDanasTokens >= halfTokensLostInLoserPool) {
            uncleDanasTokens -= halfTokensLostInLoserPool;
            indexDeltaLoser = BASE / 20;
        }

        smolPoolOne.rebase(indexDeltaWinner, true);
        smolPoolTwo.rebase(indexDeltaLoser, false);
    }

    function calculateWinChances() internal view returns (uint256 poolOneWinChance, uint256 poolTwoWinChance) {
        uint256 poolOneTotalSupply = ISmolPool(poolOne).totalSupply();
        uint256 poolTwoTotalSupply = ISmolPool(poolTwo).totalSupply();

        uint256 totalSupply = poolOneTotalSupply + poolTwoTotalSupply;

        uint256 inversePoolOneTotalSupply = totalSupply - poolOneTotalSupply;
        uint256 inversePoolTwoTotalSupply = totalSupply - poolTwoTotalSupply;

        uint256 totalInverseSupply = inversePoolOneTotalSupply + inversePoolTwoTotalSupply;

        poolOneWinChance = (inversePoolOneTotalSupply * 100) / totalInverseSupply;
        poolTwoWinChance = 100 - poolOneWinChance;
    }

    function _chooseRandomPoolWinner(uint256 rng) internal view returns (address) {
        (uint256 poolOneWinChance, uint256 poolTwoWinChance) = calculateWinChances();

        uint256 randomNumber = uint256(keccak256(abi.encodePacked(rng))) % (poolOneWinChance + poolTwoWinChance);

        if (randomNumber < poolOneWinChance) {
            return poolOne;
        } else {
            return poolTwo;
        }
    }

    function requestRebase() public nonReentrant onlyOrigin {
        require(!poolsOpen(), "Pools are open");
        require(randomRequestId == 0, "Random already requested");
        
        randomRequestId = IRandomizer(randomizerContract).requestRandomNumber();
    }

    function isRebaseReady() public view returns (bool) {
        if(randomRequestId == 0) return false;
        if(poolsOpen()) return false;

        return IRandomizer(randomizerContract).isRandomReady(randomRequestId);
    }

    function handleRandomRebase() public nonReentrant onlyOrigin {
        require(isRebaseReady(), "Random not ready");

        uint256 supplyBeforePoolOne = ISmolPool(poolOne).totalSupply();
        uint256 supplyBeforePoolTwo = ISmolPool(poolTwo).totalSupply();

        if(supplyBeforePoolOne == 0 || supplyBeforePoolTwo == 0) {
            lockPoolsAt = block.timestamp + poolCycle;
            randomRequestId = 0;

            return;
        }

        uint256 rng = IRandomizer(randomizerContract).revealRandomNumber(randomRequestId);

        address winnerPool = _chooseRandomPoolWinner(rng);
        address loserPool = winnerPool == poolOne ? poolTwo : poolOne;

        _handleRebase(winnerPool, loserPool);

        uint256 supplyAfterPoolOne = ISmolPool(poolOne).totalSupply();
        uint256 supplyAfterPoolTwo = ISmolPool(poolTwo).totalSupply();

        lockPoolsAt = block.timestamp + poolCycle;
        randomRequestId = 0;

        lastFiveResults[4] = lastFiveResults[3];
        lastFiveResults[3] = lastFiveResults[2];
        lastFiveResults[2] = lastFiveResults[1];
        lastFiveResults[1] = lastFiveResults[0];

        if (winnerPool == poolOne) {
            lastFiveResults[0] = Results.POOL_ONE;
        } else {
            lastFiveResults[0] = Results.POOL_TWO;
        }

        epochNumber++;

        emit Rebased(winnerPool, loserPool, supplyBeforePoolOne, supplyBeforePoolTwo, supplyAfterPoolOne, supplyAfterPoolTwo);
    }

    function getPoolData() external view returns (
        uint256 poolOneTotalSupply, 
        uint256 poolTwoTotalSupply, 
        uint256 poolOneWinChance, 
        uint256 poolTwoWinChance, 
        Results[] memory recentResults,
        bool poolOpen,
        bool rebaseReady,
        bool rebaseRequested,
        uint256 _epochNumber,
        uint256 _lockPoolsAt
    ) {
        poolOneTotalSupply = ISmolPool(poolOne).totalSupply();
        poolTwoTotalSupply = ISmolPool(poolTwo).totalSupply();

        poolOpen = poolsOpen();
        rebaseReady = isRebaseReady();
        rebaseRequested = randomRequestId != 0;

        _epochNumber = epochNumber;
        _lockPoolsAt = lockPoolsAt;

        recentResults = lastFiveResults;

        if(poolOneTotalSupply == 0 && poolTwoTotalSupply == 0)
            return (0, 0, 0, 0, recentResults, poolOpen, rebaseReady, rebaseRequested, _epochNumber, _lockPoolsAt);

        if(poolOneTotalSupply == 0)
            return (0, 0, 100, 0, recentResults, poolOpen, rebaseReady, rebaseRequested, _epochNumber, _lockPoolsAt);

        if(poolTwoTotalSupply == 0)
            return (0, 0, 0, 100, recentResults, poolOpen, rebaseReady, rebaseRequested, _epochNumber, _lockPoolsAt);
        
        (poolOneWinChance, poolTwoWinChance) = calculateWinChances();

    }

    //Don't call this on-chain unless you love paying gas.
    function getEligibleSmolTokensFor(address wallet) public view returns (uint256[] memory) {
        uint256[] memory tokensOwned = ISmols(smolContract).walletOfOwner(wallet);

        uint256 eligibleCount = 0;

        for(uint i = 0; i < tokensOwned.length; i++) {
            if(!smolClaimed[tokensOwned[i]])
                eligibleCount++;
        }

        uint256[] memory eligibleToClaim = new uint256[](eligibleCount);

        uint256 index = 0;

        for(uint i = 0; i < tokensOwned.length; i++) {
            if(!smolClaimed[tokensOwned[i]])
                eligibleToClaim[index++] = tokensOwned[i];
        }

        return eligibleToClaim;
    }

    function claimSmolTokens(uint256[] calldata tokenIds) public nonReentrant {
        uint256 reward = 0;

        for(uint i = 0; i < tokenIds.length; i++) {
            require(IERC721(smolContract).ownerOf(tokenIds[i]) == msg.sender, "Not owner of token");
            require(!smolClaimed[tokenIds[i]], "Token already claimed");

            smolClaimed[tokenIds[i]] = true;

            reward += claimPerSmol;
        }

        if(reward > smolTokensToClaim) {
            reward = smolTokensToClaim;
            smolTokensToClaim = 0;
        }

        if(reward <= smolTokensToClaim)
            smolTokensToClaim -= reward;

        IERC20(smolToken).transfer(msg.sender, reward);
    }

    function depositUncleDanaTokens(uint256 amount) external onlyOwner {
        IERC20(smolToken).transferFrom(msg.sender, address(this), amount);
        uncleDanasTokens += amount;
    }

    function depositSmolTokensToClaim(uint256 amount) external onlyOwner {
        IERC20(smolToken).transferFrom(msg.sender, address(this), amount);
        smolTokensToClaim += amount;
    }

    function depositOverflow(uint256 amount) external onlyOwner {
        IERC20(smolToken).transferFrom(msg.sender, address(this), amount);
    }

    function lockContractSetters() external onlyOwner {
        lockSetters = true;
    }

    function emergencyFix() external onlyOwner {
        lockPoolsAt = block.timestamp + poolCycle;
        randomRequestId = 0;
    }

    function setRandomizer(address _randomizer) external onlyOwner {
        require(_randomizer != address(0), "Invalid randomizer address");
        require(!lockSetters, "Setters locked");
        randomizerContract = _randomizer;
    }

    function setSmolContract(address _smolContract) external onlyOwner {
        require(_smolContract != address(0), "Invalid smol contract address");
        require(!lockSetters, "Setters locked");
        smolContract = _smolContract;
    }

    function setPoolCycle(uint256 time) external onlyOwner {
        require(!lockSetters, "Setters locked");
        poolCycle = time;
    }

    function setPools(address _poolOne, address _poolTwo) external onlyOwner {
        require(_poolOne != address(0) && _poolTwo != address(0), "Invalid pool address");
        require(poolOne == address(0) && poolTwo == address(0), "Pools already set");

        poolOne = _poolOne;
        poolTwo = _poolTwo;
    }


}