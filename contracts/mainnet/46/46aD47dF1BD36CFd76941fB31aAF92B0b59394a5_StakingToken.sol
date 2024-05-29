// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface ICommission {
    function getConditionTotalCommission(uint8 _level) external returns (uint256);

    function getConditionClaimCommission(uint8 _level) external returns (uint256);

    function setConditionTotalCommission(uint8 _level, uint256 _value) external;

    function setConditionDirectStakeTokenCommission(uint8 _level, uint256 _value) external;

    function setConditionClaimCommission(uint8 _level, uint256 _value) external;

    function setMaxNumberStakeValue(uint8 _percent) external;

    function setDefaultMaxCommission(uint256 _value) external;

    function getTotalCommission(address _wallet) external view returns (uint256);

    function calculateEarnedUsd(address _address, uint256 _claimUsd) external view returns (uint256);

    function getDirectCommissionUsd(address _wallet) external view returns (uint256);

    function getInterestCommissionUsd(address _wallet) external view returns (uint256);

    function getRankingCommissionUsd(address _wallet) external view returns (uint256);

    function getReStakeValueUsd(address _wallet) external view returns (uint256);

    function getTeamStakeValue(address _wallet) external view returns (uint256);

    function updateWalletCommission(address _wallet,
        uint256 _directCommission,
        uint256 _interestCommission,
        uint256 _reStakeValueUsd,
        uint256 _reStakeClaimUsd,
        uint256 _stakeTokenClaimUsd,
        uint256 _stakeNativeTokenClaimUsd,
        uint256 _rankingCommission,
        uint256 _teamStakeValue) external;

    function setSystemWallet(address _newSystemWallet) external;

    function setOracleAddress(address _oracleAddress) external;

    function setRankingContractAddress(address _stakingAddress) external;

    function getCommissionRef(
        address _refWallet,
        uint256 _totalValueUsdWithDecimal,
        uint256 _totalCommission,
        uint16 _commissionBuy
    )  external returns (uint256);

    function updateDataRestake(
        address _receiver,
        uint256 totalValueUsdWithDecimal,
        bool _payRef,
        bool _updateRanking,
        bool _isStakeToken
    ) external;

    function updateDataClaim(
        address _receiver,
        uint256 totalValueUsdWithDecimal,
        bool _isPayRanking
    ) external;

    function updateRankingNetworkData(address _refWallet, uint256 _totalValueUsdWithDecimal, uint16 _commissionRanking, uint256 _totalCommission) external;

    function getMaxCommissionByAddressInUsd(address _wallet) external view returns (uint256);

    function updateClaimReStakeUsd(address _address, uint256 _claimUsd) external;

    function updateReStakeValueUsd(address _address, uint256 _value) external;

    function updateClaimStakeTokenUsd(address _address, uint256 _claimUsd) external;

    function updateClaimStakeNativeUsd(address _address, uint256 _claimUsd) external;

    function setAddressCanUpdateCommission(address _address, bool _value) external;

    function getCommissionPercent(uint8 _level) external returns (uint16);

    function getDirectCommissionPercent(uint8 _level) external returns (uint16);

    function setCommissionPercent(uint8 _level, uint16 _percent) external;

    function setDirectCommissionPercent(uint8 _level, uint16 _percent) external;

    function setDirectCommissionStakeTokenPercent(uint8 _level, uint16 _percent) external;

    function setToken(address _address) external;

    function setNetworkAddress(address _address) external;

    function setMaxLevel(uint8 _maxLevel) external;

    function withdrawTokenEmergency(address _token, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPancakePair {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}

contract Oracle is Ownable {
    uint256 public constant PRECISION = 1000000;

    mapping(address => uint256) private addressUsdtAmount;
    mapping(address => uint256) private addressTokenAmount;

    mapping(address => uint256) private addressMinTokenAmount;
    mapping(address => uint256) private addressMaxTokenAmount;

    mapping(address => address) private tokenPairAddress;
    address public stableToken;

    constructor(address _stableToken) {
        stableToken = _stableToken;
    }

    function convertUsdBalanceDecimalToTokenDecimal(address _token, uint256 _balanceUsdDecimal) external view returns (uint256) {
        uint256 tokenAmount = addressTokenAmount[_token];
        uint256 usdtAmount = addressUsdtAmount[_token];
        if (tokenAmount > 0 && usdtAmount > 0) {
            uint256 amountTokenDecimal = (_balanceUsdDecimal * tokenAmount) / usdtAmount;
            return amountTokenDecimal;
        }

        address pairAddress = tokenPairAddress[_token];
        require(pairAddress != address(0), "Invalid pair address");
        (uint256 _reserve0, uint256 _reserve1, ) = IPancakePair(pairAddress).getReserves();
        (uint256 _tokenBalance, uint256 _stableBalance) = address(_token) < address(stableToken)
            ? (_reserve0, _reserve1)
            : (_reserve1, _reserve0);
        _stableBalance = _stableBalance * 1000000000000;
        uint256 minTokenAmount = addressMinTokenAmount[_token];
        uint256 maxTokenAmount = addressMaxTokenAmount[_token];
        uint256 _minTokenAmount = (_balanceUsdDecimal * minTokenAmount) / PRECISION;
        uint256 _maxTokenAmount = (_balanceUsdDecimal * maxTokenAmount) / PRECISION;
        uint256 _tokenAmount = (_balanceUsdDecimal * _tokenBalance) / _stableBalance;

        require(_tokenAmount >= _minTokenAmount, "Price is too low");
        require(_tokenAmount <= _maxTokenAmount, "Price is too hight");

        return _tokenAmount;
    }

    function setTokenPrice(address _token, address _pairAddress, uint256 _tokenAmount, uint256 _usdtAmount, uint256 _minTokenAmount, uint256 _maxTokenAmount) external onlyOwner {
        addressUsdtAmount[_token] = _usdtAmount;
        addressTokenAmount[_token] = _tokenAmount;
        addressMinTokenAmount[_token] = _minTokenAmount;
        addressMaxTokenAmount[_token] = _maxTokenAmount;
        tokenPairAddress[_token] = _pairAddress;
    }

    function setTokenInfo(address _token, address _pairAddress, uint256 _tokenAmount, uint256 _usdtAmount, uint256 _minTokenAmount, uint256 _maxTokenAmount) external onlyOwner {
        addressUsdtAmount[_token] = _usdtAmount;
        addressTokenAmount[_token] = _tokenAmount;
        addressMinTokenAmount[_token] = _minTokenAmount;
        addressMaxTokenAmount[_token] = _maxTokenAmount;
        tokenPairAddress[_token] = _pairAddress;
    }

    function setStableToken(address _stableToken) external onlyOwner {
        stableToken = _stableToken;
    }

    function withdrawTokenEmergency(address _token, uint256 _amount) external onlyOwner {
        require(_amount > 0, "INVALID AMOUNT");
        require(IERC20(_token).transfer(msg.sender, _amount), "CANNOT WITHDRAW TOKEN");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IStakeApy {
    function setApy(uint256 _poolId, uint256 _poolIdEarnPerDay) external;

    function setApyExactly(uint256 _poolId, uint256[] calldata _startTime, uint256[] calldata _endTime, uint256[] calldata _tokenEarn) external;

    function getStartTime(uint256 _poolId) external view returns (uint256[] memory);

    function getEndTime(uint256 _poolId) external view returns (uint256[] memory);

    function getPoolApy(uint256 _poolId) external view returns (uint256[] memory);

    function getMaxIndex(uint256 _poolId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IStakingToken {
    struct StakePools {
        uint256 poolId;
        uint256 maxStakePerWallet;
        uint256 duration;
        uint256 totalStake;
        uint256 totalStakeUsd;
        uint256 totalEarn;
        uint256 totalEarnUsd;
        address subToken;
        uint256 rate;
        bool needPending;
        bool canStakeUsd;
        bool canStakeToken;
        bool isMaxEarn;
    }
    struct DetailStake {
        uint256 stakeId;
        address userAddress;
        uint256 poolId;
        uint256 unlockTime;
        uint256 startTime;
        uint256 totalValueStake;
        uint256 totalValueStakeUsd;
        uint256 totalValueClaimed;
        uint256 totalValueClaimedUsd;
        uint256 totalSubToken;
        uint256 rate;
        address subTokenAddress;
        bool isWithdraw;
        bool isPending;
        uint8 canWithdrawPending;
        bool stakeByUsd;
        bool stakeByToken;
    }

    event Staked(uint256 indexed id, uint256 poolId, address indexed staker, uint256 stakeValue, uint256 startTime, uint256 unlockTime);

    event Claimed(uint256 indexed id, address indexed staker, uint256 claimAmount);

    event Harvested(uint256 indexed id);

    function setOracleAddress(address _oracleAddress) external;

    function setCommissionAddress(address _commissionContract) external;

    function setApyContract(address _stakeApy) external;

    function setUsdContract(address _usdAddress) external;

    function setTokenContract(address _token) external;

    function getTotalUserWithdrawToken(address _userId) external returns (uint256);

    function getTotalUserWithdrawUsd(address _userId) external returns (uint256);

    function withdraw(uint256 _stakeId, bool _quickWithdraw) external;

    function claimPending(uint256 _stakeId) external;

    function executePendingAdmin(uint256 _stakeId) external;

    function withdrawPool(uint256[] memory _stakeIds, bool _quickWithdraw) external;

    function getStakePool(uint256 _poolId) external view returns (StakePools memory);

    function setStakePool(uint256 _poolId, uint256 _maxStakePerWallet, uint256 _duration, address _subToken, uint256 _rate, bool needPending, bool _canStakeToken, bool _canStakeUsd, bool _isMaxEarn) external;

    function addStakeAdmin(uint256 _poolId, address _userAddress, uint256 _totalValueStake, bool _stakeByUsd) external;

    function getDetailStake(uint256 _stakeId) external view returns (DetailStake memory);

    function setRewardFee(uint256 _rewardFee) external;

    function setWithdrawFee(uint256 _rewardFee) external;

    function setUsdStakeFee(uint256 _rewardFee) external;

    function setTotalStaked(uint256 _totalStakedToken, uint256 _totalStakedUsd) external;

    function setUsePrice(uint8 _usePrice) external;

    function setTotalUserStaked(uint256 _totalStakedUsd, uint256 _totalStakedToken, address _userId) external;

    function getTotalUserStakedToken(address _userId) external returns (uint256);

    function getTotalUserStakedUsd(address _userId) external returns (uint256);

    function setSaleWalletAddress(address _saleAddress) external;

    function stake(uint256 _poolId, uint256 _stakeValue) external;

    function stakeByUsd(uint256 _poolId, uint256 _valueStakeUsd) external;

    function calculateTokenEarnedStake(uint256 _stakeId) external view returns (uint256);

    function checkCanClaim(uint256 _stakeId) external view returns (bool);

    function checkCanClaimUsd(uint256 _stakeId) external view returns (bool);

    function checkCanClaimMulti(uint256[] memory _stakeIds, address _userAddress) external view  returns (bool);

    function calculateTokenEarnedStakeByUsd(uint256 _stakeId) external view returns (uint256);

    function calculateTokenEarnedMulti(uint256[] memory _stakeIds) external view returns (uint256);

    function claim(uint256 _poolId) external;

    function claimAll(uint256[] memory _poolIds) external;

    function recoverLostBNB() external;

    function withdrawTokenEmergency(address _token, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IStakingToken.sol";
import "../stake_apy/IStakeApy.sol";
import "../token/SUBERC20.sol";
import "../token/TETHToken.sol";
import "../oracle/Oracle.sol";
import "../commission/ICommission.sol";

contract StakingToken is IStakingToken, Ownable {
    uint256 public timeOpenStaking = 1689786000;
    uint private unlocked = 1;
    uint8 private usePrice = 1; //1: chainlink 2: pancake
    uint256 public tokenDecimal = 1000000000000000000;
    uint256 public usdtDecimal = 1000000;
    uint256 public priceFeedDecimal = 100000000;
    uint256 public rewardFee = 0;
    uint256 public withdrawFee = 0;
    uint256 public usdStakeFee = 0;
    address private saleWallet = 0xdc7a6dBac6E02d6AA264053E2f7E9F39F6Bda15E;
    address private eToken;
    address private tToken;
    address private oracleContract;
    address public stakeApy;
    address public usdToken;
    address public token;
    address public commissionContract;
    uint256 public totalStakedToken;
    uint256 public totalFeeClaimToken;
    uint256 public totalFeeWithdrawToken;
    uint256 public totalClaimedToken;
    uint256 public totalClaimedUsd;
    uint256 public totalStakedUsd;
    uint256 public totalWithdrawToken;
    uint256 public totalWithdrawUsd;
    uint256 public stakeTokenPoolLength = 4;
    uint256 private stakeIndex = 0;
    mapping(uint256 => StakePools) private stakePools;
    mapping(uint256 => DetailStake) private stakedToken;
    mapping(address => uint256) private totalUserStakedToken;
    mapping(address => uint256) public totalUserClaimedToken;
    mapping(address => uint256) public totalUserClaimedUsd;
    mapping(address => uint256) private totalUserStakedUsd;
    mapping(address => uint256) private totalUserWithdrawToken;
    mapping(address => uint256) private totalUserWithdrawUsd;
    mapping(address => mapping (uint256 => uint256)) private totalUserStakedPoolToken;
    AggregatorV3Interface internal immutable priceFeed;

    constructor(address _token, address _stakeApy, address _eToken, address _tToken, address _priceFeed, address _usdToken, address _commissionContract) {
        token = _token;
        eToken = _eToken;
        tToken = _tToken;
        stakeApy = _stakeApy;
        usdToken = _usdToken;
        commissionContract = _commissionContract;
        priceFeed = AggregatorV3Interface(_priceFeed);
        initStakePool();
    }

    modifier isTimeForStaking() {
        require(block.timestamp >= timeOpenStaking, "TOKEN STAKING: THE STAKING PROGRAM HAS NOT YET STARTED.");
        _;
    }

    modifier lock() {
        require(unlocked == 1, "TOKEN STAKING: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }    /**
     * @dev init stake pool default
     */
    function initStakePool() internal {
        stakePools[0].poolId = 0;
        stakePools[0].maxStakePerWallet = 0;
        stakePools[0].duration = 0;
        stakePools[0].subToken = eToken;
        stakePools[0].rate = 1000;
        stakePools[0].needPending = true;
        stakePools[0].canStakeUsd = false;
        stakePools[0].canStakeToken = false;
        stakePools[0].isMaxEarn = true;

        stakePools[1].poolId = 1;
        stakePools[1].maxStakePerWallet = 0;
        stakePools[1].duration = 12;
        stakePools[1].subToken = tToken;
        stakePools[1].rate = 1000;
        stakePools[1].needPending = true;
        stakePools[1].canStakeUsd = true;
        stakePools[1].canStakeToken = true;
        stakePools[1].isMaxEarn = true;

        stakePools[2].poolId = 2;
        stakePools[2].maxStakePerWallet = 0;
        stakePools[2].duration = 18;
        stakePools[2].subToken = tToken;
        stakePools[2].rate = 1000;
        stakePools[2].needPending = true;
        stakePools[2].canStakeUsd = true;
        stakePools[2].canStakeToken = true;
        stakePools[2].isMaxEarn = true;

        stakePools[3].poolId = 3;
        stakePools[3].maxStakePerWallet = 0;
        stakePools[3].duration = 24;
        stakePools[3].subToken = tToken;
        stakePools[3].rate = 1000;
        stakePools[3].needPending = true;
        stakePools[3].canStakeUsd = true;
        stakePools[3].canStakeToken = true;
        stakePools[3].isMaxEarn = true;
    }

    function setCommissionAddress(address _commissionContract) external override onlyOwner {
        require(_commissionContract != address(0), "MARKETPLACE: INVALID COMMISSION ADDRESS");
        commissionContract = _commissionContract;
    }

    /**
        * @dev set oracle address
     */
    function setOracleAddress(address _oracleAddress) external override onlyOwner {
        require(_oracleAddress != address(0), "MARKETPLACE: INVALID ORACLE ADDRESS");
        oracleContract = _oracleAddress;
    }

    /**
 * @dev get stake token pool
     */
    function getStakePool(uint256 _poolId) public view override returns (StakePools memory) {
        StakePools memory _stakePool = stakePools[_poolId];

        return _stakePool;
    }

    function setStakePool(uint256 _poolId, uint256 _maxStakePerWallet, uint256 _duration, address _subToken, uint256 _rate, bool needPending, bool _canStakeToken, bool _canStakeUsd, bool _isMaxEarn) external override onlyOwner {
        stakePools[_poolId].poolId = _poolId;
        stakePools[_poolId].maxStakePerWallet = _maxStakePerWallet;
        stakePools[_poolId].duration = _duration;
        stakePools[_poolId].subToken = _subToken;
        stakePools[_poolId].rate = _rate;
        stakePools[_poolId].needPending = needPending;
        stakePools[_poolId].canStakeToken = _canStakeToken;
        stakePools[_poolId].canStakeUsd = _canStakeUsd;
        stakePools[_poolId].isMaxEarn = _isMaxEarn;
        uint256 _index = _poolId + 1;
        if (_index > stakeTokenPoolLength) {
            stakeTokenPoolLength = _index;
        }
    }

    function setRewardFee(uint256 _rewardFee) external override onlyOwner {
        rewardFee = _rewardFee;
    }

    function setWithdrawFee(uint256 _withdrawFee) external override onlyOwner {
        withdrawFee = _withdrawFee;
    }

    function setUsdStakeFee(uint256 _fee) external override onlyOwner {
        usdStakeFee = _fee;
    }

    function getDetailStake(uint256 _stakeId) public view override returns (DetailStake memory) {
        return stakedToken[_stakeId];
    }

    function setTotalStaked(uint256 _totalStakedToken, uint256 _totalStakedUsd) external override onlyOwner {
        totalStakedUsd = _totalStakedUsd;
        totalStakedToken = _totalStakedToken;
    }

    function setUsePrice(uint8 _usePrice) external override onlyOwner {
        require(_usePrice == 1 || _usePrice == 2, 'Invalid param');
        usePrice = _usePrice;
    }

    function setTotalUserStaked(uint256 _totalStakedUsd, uint256 _totalStakedToken, address _userId) external override onlyOwner {
        totalUserStakedToken[_userId] = _totalStakedToken;
        totalUserStakedUsd[_userId] = _totalStakedUsd;
    }

    function getTotalUserStakedToken(address _userId) public view override returns (uint256) {
        return totalUserStakedToken[_userId];
    }

    function getTotalUserStakedUsd(address _userId) public view override returns (uint256) {
        return totalUserStakedUsd[_userId];
    }

    function setSaleWalletAddress(address _saleAddress) external override onlyOwner {
        require(_saleAddress != address(0), "MARKETPLACE: INVALID SALE ADDRESS");
        saleWallet = _saleAddress;
    }

    function stake(uint256 _poolId, uint256 _stakeValue) external override lock() {
        require(_stakeValue > 0, "Amount must be greater than 0");
        StakePools memory pool = stakePools[_poolId];
        bool canStakeToken = pool.canStakeToken;
        require(canStakeToken, "CNS");
        require(
            SUBERC20(token).balanceOf(msg.sender) >= _stakeValue,
            "TOKEN STAKE: Not enough balance to stake"
        );
        require(
            SUBERC20(token).allowance(msg.sender, address(this)) >= _stakeValue,
            "TOKEN STAKE: Must approve first"
        );
        require(
            SUBERC20(token).transferFrom(msg.sender, saleWallet, _stakeValue),
            "TOKEN STAKE: Transfer token to TOKEN STAKE failed"
        );
        uint256 totalUserStakePool = totalUserStakedPoolToken[msg.sender][_poolId] + _stakeValue;
        require(
            stakePools[_poolId].maxStakePerWallet == 0 || stakePools[_poolId].maxStakePerWallet >= totalUserStakePool,
            "TOKEN STAKE: User stake max value of token"
        );
        stakeExecute(_poolId, msg.sender, _stakeValue, totalUserStakePool, false);
    }

    function stakeByUsd(uint256 _poolId, uint256 _valueStakeUsd) external override lock() {
        require(_valueStakeUsd > 0, "Amount must be greater than 0");
        StakePools memory pool = stakePools[_poolId];
        bool canStakeUsd = pool.canStakeUsd;
        require(canStakeUsd, "CNS");
        require(
            SUBERC20(usdToken).balanceOf(msg.sender) >= _valueStakeUsd,
            "TOKEN STAKE: Not enough balance to stake"
        );
        require(
            SUBERC20(usdToken).allowance(msg.sender, address(this)) >= _valueStakeUsd,
            "TOKEN STAKE: Must approve first"
        );
        require(
            SUBERC20(usdToken).transferFrom(msg.sender, saleWallet, _valueStakeUsd),
            "TOKEN STAKE: Transfer token to TOKEN STAKE failed"
        );
        if (usdStakeFee > 0) {
            _valueStakeUsd = _valueStakeUsd - _valueStakeUsd * usdStakeFee / 10000;
        }
        _valueStakeUsd = _valueStakeUsd * tokenDecimal / usdtDecimal;
        uint256 _stakeValue = _valueStakeUsd * priceFeedDecimal / uint256(getLatestPrice());

        uint256 totalUserStakePool = totalUserStakedPoolToken[msg.sender][_poolId] + _stakeValue;
        require(
            stakePools[_poolId].maxStakePerWallet == 0 || stakePools[_poolId].maxStakePerWallet >= totalUserStakePool,
            "TOKEN STAKE: User stake max value of token"
        );
        stakeExecute(_poolId, msg.sender, _stakeValue, totalUserStakePool, true);
    }

    function stakeExecute(uint256 _poolId, address _userAddress, uint256 _stakeValue, uint256 totalUserStakePool, bool _stakeByUsd) internal {
        // insert data staking
        stakeIndex = stakeIndex + 1;
        uint256 subTokenMint = _stakeValue * stakePools[_poolId].rate / 1000;
        SUBERC20(stakePools[_poolId].subToken).mintToken(_userAddress, subTokenMint);
        uint256 _valueUsd = _stakeValue * getTokenUsdPrice() / priceFeedDecimal;
        // if pool duration = 0 => no limit for stake time, can claim every time
        uint256 unlockTimeEstimate = stakePools[_poolId].duration == 0 ? 0 : (block.timestamp + (2592000 * stakePools[_poolId].duration));
        stakedToken[stakeIndex].stakeId = stakeIndex;
        stakedToken[stakeIndex].userAddress = _userAddress;
        stakedToken[stakeIndex].poolId = _poolId;
        stakedToken[stakeIndex].unlockTime = unlockTimeEstimate;
        stakedToken[stakeIndex].startTime = block.timestamp;
        stakedToken[stakeIndex].totalValueStake = _stakeValue;
        stakedToken[stakeIndex].totalValueStakeUsd = _valueUsd;
        stakedToken[stakeIndex].totalValueClaimed = 0;
        stakedToken[stakeIndex].totalValueClaimedUsd = 0;
        stakedToken[stakeIndex].subTokenAddress = stakePools[_poolId].subToken;
        stakedToken[stakeIndex].totalSubToken = subTokenMint;
        stakedToken[stakeIndex].rate = stakePools[_poolId].rate;
        stakedToken[stakeIndex].isWithdraw = false;
        stakedToken[stakeIndex].isPending = false;
        stakedToken[stakeIndex].stakeByUsd = _stakeByUsd;
        stakedToken[stakeIndex].stakeByToken = _stakeByUsd == false ? true : false;
        stakedToken[stakeIndex].canWithdrawPending = 0;

        // update fixed data
        totalUserStakedPoolToken[_userAddress][_poolId] = totalUserStakePool;
        stakePools[_poolId].totalStake += _stakeValue;
        stakePools[_poolId].totalStakeUsd += _valueUsd;
        totalStakedToken += _stakeValue;
        totalStakedUsd += _valueUsd;
        totalUserStakedToken[_userAddress] += _stakeValue;
        totalUserStakedUsd[_userAddress] += _valueUsd;
        emit Staked(stakeIndex, _poolId, _userAddress, _stakeValue, block.timestamp, unlockTimeEstimate);
    }

    function stakeExecuteAdmin(uint256 _poolId, address _userAddress, uint256 _stakeValue, uint256 _valueUsd, uint256 _startTime, uint256 _totalValueClaimed, uint256 _totalValueClaimedUsd, bool _isWithdraw,  bool _stakeByUsd) external onlyOwner {
        uint256 totalUserStakePool = totalUserStakedPoolToken[_userAddress][_poolId] + _stakeValue;
        // insert data staking
        stakeIndex = stakeIndex + 1;
        uint256 subTokenMint = _stakeValue * stakePools[_poolId].rate / 1000;
        uint256 unlockTimeEstimate = stakePools[_poolId].duration == 0 ? 0 : (_startTime + (2592000 * stakePools[_poolId].duration));
        stakedToken[stakeIndex].stakeId = stakeIndex;
        stakedToken[stakeIndex].userAddress = _userAddress;
        stakedToken[stakeIndex].poolId = _poolId;
        stakedToken[stakeIndex].unlockTime = unlockTimeEstimate;
        stakedToken[stakeIndex].startTime = _startTime;
        stakedToken[stakeIndex].totalValueStake = _stakeValue;
        stakedToken[stakeIndex].totalValueStakeUsd = _valueUsd;
        stakedToken[stakeIndex].totalValueClaimed = _totalValueClaimed;
        stakedToken[stakeIndex].totalValueClaimedUsd = _totalValueClaimedUsd;
        stakedToken[stakeIndex].subTokenAddress = stakePools[_poolId].subToken;
        stakedToken[stakeIndex].totalSubToken = subTokenMint;
        stakedToken[stakeIndex].rate = stakePools[_poolId].rate;
        stakedToken[stakeIndex].isWithdraw = _isWithdraw;
        stakedToken[stakeIndex].isPending = false;
        stakedToken[stakeIndex].stakeByUsd = _stakeByUsd;
        stakedToken[stakeIndex].stakeByToken = _stakeByUsd == false ? true : false;
        stakedToken[stakeIndex].canWithdrawPending = 0;

        // update fixed data
        totalUserStakedPoolToken[_userAddress][_poolId] = totalUserStakePool;
        stakePools[_poolId].totalStake += _stakeValue;
        stakePools[_poolId].totalStakeUsd += _valueUsd;
        totalStakedToken += _stakeValue;
        totalStakedUsd += _valueUsd;
        totalUserStakedToken[_userAddress] += _stakeValue;
        totalUserStakedUsd[_userAddress] += _valueUsd;
    }

    function calculateTokenEarnedStake(uint256 _stakeId) public view override returns (uint256) {
       DetailStake memory _stakedUserToken = stakedToken[_stakeId];
        if (_stakedUserToken.isWithdraw) {
            return 0;
        }
        uint256 totalTokenClaimDecimal = 0;
        uint256 index = IStakeApy(stakeApy).getMaxIndex(_stakedUserToken.poolId);
        uint256 apy = 0;
        for (uint i = 0; i < index; i++) {
            uint256 startTime = IStakeApy(stakeApy).getStartTime(_stakedUserToken.poolId)[i];
            uint256 endTime = IStakeApy(stakeApy).getEndTime(_stakedUserToken.poolId)[i];
            apy = IStakeApy(stakeApy).getPoolApy(_stakedUserToken.poolId)[i];
            // calculate token claim for each stake pool
            startTime = startTime >= _stakedUserToken.startTime ? startTime : _stakedUserToken.startTime;
            // _stakedUserToken.unlockTime == 0 mean no limit for this pool
            uint256 timeDuration = _stakedUserToken.unlockTime == 0 ? block.timestamp :  (_stakedUserToken.unlockTime < block.timestamp ? _stakedUserToken.unlockTime : block.timestamp);
            endTime = endTime == 0 ? timeDuration : (endTime <= timeDuration ? endTime : timeDuration);

            if (startTime <= endTime) {
                totalTokenClaimDecimal += ((endTime - startTime) * apy * _stakedUserToken.totalValueStake) / 31104000 / 100000;
            }
        }

        totalTokenClaimDecimal = totalTokenClaimDecimal - _stakedUserToken.totalValueClaimed;

        return totalTokenClaimDecimal;
    }

    function checkCanClaim(uint256 _stakeId) public view override returns (bool) {
        DetailStake memory _stakedUserToken = stakedToken[_stakeId];
        uint256 _poolId = _stakedUserToken.poolId;
        address _userAddress = _stakedUserToken.userAddress;
        StakePools memory _stakePool = stakePools[_poolId];
        uint256 _totalTokenClaimDecimal = calculateTokenEarnedStake(_stakeId);
        uint256 _totalUsdClaimDecimal = _totalTokenClaimDecimal * getTokenUsdPrice() / priceFeedDecimal;
        uint256 totalCanClaim = _totalUsdClaimDecimal;
        if (_stakePool.isMaxEarn) {
            totalCanClaim = ICommission(commissionContract).calculateEarnedUsd(_userAddress, _totalUsdClaimDecimal);
        }
        return totalCanClaim == _totalUsdClaimDecimal;
    }

    function checkCanClaimUsd(uint256 _stakeId) public view override returns (bool) {
        DetailStake memory _stakedUserToken = stakedToken[_stakeId];
        uint256 _poolId = _stakedUserToken.poolId;
        address _userAddress = _stakedUserToken.userAddress;
        StakePools memory _stakePool = stakePools[_poolId];
        uint256 _totalUsdClaimDecimal = calculateTokenEarnedStakeByUsd(_stakeId);
        uint256 totalCanClaim = _totalUsdClaimDecimal;
        if (_stakePool.isMaxEarn) {
            totalCanClaim = ICommission(commissionContract).calculateEarnedUsd(_userAddress, _totalUsdClaimDecimal);
        }
        return totalCanClaim == _totalUsdClaimDecimal;
    }

    function checkCanClaimMulti(uint256[] memory _stakeIds, address _userAddress) public view override returns (bool) {
        uint256 _totalTokenClaimDecimal = calculateTokenEarnedMulti(_stakeIds);
        uint256 _totalUsdClaimDecimal = _totalTokenClaimDecimal * getTokenUsdPrice() / priceFeedDecimal;
        uint256 totalCanClaim = ICommission(commissionContract).calculateEarnedUsd(_userAddress, _totalUsdClaimDecimal);
        return totalCanClaim == _totalUsdClaimDecimal;
    }

    function calculateTokenEarnedStakeByUsd(uint256 _stakeId) public view override returns (uint256) {
       DetailStake memory _stakedUserToken = stakedToken[_stakeId];
        if (_stakedUserToken.isWithdraw) {
            return 0;
        }
        uint256 totalTokenClaimDecimal = 0;
        uint256 index = IStakeApy(stakeApy).getMaxIndex(_stakedUserToken.poolId);
        uint256 apy = 0;
        for (uint i = 0; i < index; i++) {
            uint256 startTime = IStakeApy(stakeApy).getStartTime(_stakedUserToken.poolId)[i];
            uint256 endTime = IStakeApy(stakeApy).getEndTime(_stakedUserToken.poolId)[i];
            apy = IStakeApy(stakeApy).getPoolApy(_stakedUserToken.poolId)[i];
            // calculate token claim for each stake pool
            startTime = startTime >= _stakedUserToken.startTime ? startTime : _stakedUserToken.startTime;
            // _stakedUserToken.unlockTime == 0 mean no limit for this pool
            uint256 timeDuration = _stakedUserToken.unlockTime == 0 ? block.timestamp :  (_stakedUserToken.unlockTime < block.timestamp ? _stakedUserToken.unlockTime : block.timestamp);
            endTime = endTime == 0 ? timeDuration : (endTime <= timeDuration ? endTime : timeDuration);

            if (startTime <= endTime) {
                totalTokenClaimDecimal += ((endTime - startTime) * apy * _stakedUserToken.totalValueStakeUsd) / 31104000 / 100000;
            }
        }

        totalTokenClaimDecimal = totalTokenClaimDecimal - _stakedUserToken.totalValueClaimedUsd;

        return totalTokenClaimDecimal;
    }

    function calculateTokenEarnedMulti(uint256[] memory _stakeIds) public view override returns (uint256) {
        uint256 _totalTokenClaimDecimal = 0;
        for (uint i = 0; i < _stakeIds.length; i++) {
            _totalTokenClaimDecimal += calculateTokenEarnedStake(_stakeIds[i]);
        }

        return _totalTokenClaimDecimal;
    }

    function addStakeAdmin(uint256 _poolId, address _userAddress, uint256 _totalValueStake, bool _stakeByUsd) external override onlyOwner {
        uint256 totalUserStakePool = totalUserStakedPoolToken[msg.sender][_poolId] + _totalValueStake;
        require(
            stakePools[_poolId].maxStakePerWallet == 0 || stakePools[_poolId].maxStakePerWallet >= totalUserStakePool,
            "TOKEN STAKE: User stake max value of token"
        );
        // insert data staking
        stakeExecute(_poolId, _userAddress, _totalValueStake, totalUserStakePool, _stakeByUsd);
    }

    function claim(uint256 _stakeId) public override {
        DetailStake memory _stakedUserToken = stakedToken[_stakeId];
        require(
            _stakedUserToken.userAddress == msg.sender, "STAKING: ONLY OWNER OF STAKE CAN CLAIM"
        );
        if (_stakedUserToken.stakeByUsd) {
            claimByUsd(_stakeId);
        }
        if (_stakedUserToken.stakeByToken) {
            claimByToken(_stakeId);
        }
    }

    function claimByToken(uint256 _stakeId) internal {
        bool _checkCanClaim = checkCanClaim(_stakeId);
        require(_checkCanClaim == true, "STAKING: CANNOT CLAIM");
        uint256 _totalTokenClaimDecimal = calculateTokenEarnedStake(_stakeId);
        DetailStake memory _stakedUserToken = stakedToken[_stakeId];
        require(
            _stakedUserToken.userAddress == msg.sender, "STAKING: ONLY OWNER OF STAKE CAN CLAIM"
        );
        if (_totalTokenClaimDecimal > 0) {
            if (rewardFee != 0) {
                uint256 _fee = _totalTokenClaimDecimal * rewardFee / 10000;
                _totalTokenClaimDecimal = _totalTokenClaimDecimal - _fee;
                totalFeeClaimToken += _fee;
            }
            require(
                SUBERC20(token).balanceOf(address(this)) >= _totalTokenClaimDecimal,
                "TOKEN STAKE: NOT ENOUGH TOKEN BALANCE TO PAY UNSTAKE REWARD"
            );
            require(
                SUBERC20(token).transfer(msg.sender, _totalTokenClaimDecimal),
                "TOKEN STAKE: UNABLE TO TRANSFER COMMISSION PAYMENT TO RECIPIENT"
            );
            // transfer token to user and close stake pool
            uint256 _earnUsd = _totalTokenClaimDecimal * getTokenUsdPrice() / priceFeedDecimal;
            stakePools[stakedToken[_stakeId].poolId].totalEarn += _totalTokenClaimDecimal;
            stakePools[stakedToken[_stakeId].poolId].totalEarnUsd += _earnUsd;
            totalClaimedToken += _totalTokenClaimDecimal;
            totalClaimedUsd += _earnUsd;
            stakedToken[_stakeId].totalValueClaimed += _totalTokenClaimDecimal;
            stakedToken[_stakeId].totalValueClaimedUsd += _earnUsd;
            totalUserClaimedToken[msg.sender] += _totalTokenClaimDecimal;
            totalUserClaimedUsd[msg.sender] += _earnUsd;
            uint256 _poolId = _stakedUserToken.poolId;
            StakePools memory _stakePool = stakePools[_poolId];
            if (_stakePool.isMaxEarn) {
                ICommission(commissionContract).updateClaimStakeNativeUsd(msg.sender, _earnUsd);
            }
            emit Claimed(_stakeId, msg.sender, _totalTokenClaimDecimal);
        }
    }

    function claimByUsd(uint256 _stakeId) internal {
        bool _checkCanClaim = checkCanClaimUsd(_stakeId);
        require(_checkCanClaim == true, "STAKING: CANNOT CLAIM");
        uint256 _totalUsdClaimDecimal = calculateTokenEarnedStakeByUsd(_stakeId);
        DetailStake memory _stakedUserToken = stakedToken[_stakeId];
        require(
            _stakedUserToken.userAddress == msg.sender, "STAKING: ONLY OWNER OF STAKE CAN CLAIM"
        );
        if (_totalUsdClaimDecimal > 0) {
            if (rewardFee != 0) {
                uint256 _fee = _totalUsdClaimDecimal * rewardFee / 10000;
                _totalUsdClaimDecimal = _totalUsdClaimDecimal - _fee;
            }
            uint256 _totalTokenClaimDecimal = _totalUsdClaimDecimal * priceFeedDecimal / uint256(getLatestPrice());
            uint256 _totalUsdClaimDecimalTransfer = _totalUsdClaimDecimal * usdtDecimal / tokenDecimal;
            require(
                SUBERC20(usdToken).balanceOf(address(this)) >= _totalUsdClaimDecimalTransfer,
                "TOKEN STAKE: NOT ENOUGH TOKEN BALANCE TO PAY UNSTAKE REWARD"
            );
            require(
                SUBERC20(usdToken).transfer(msg.sender, _totalUsdClaimDecimalTransfer),
                "TOKEN STAKE: UNABLE TO TRANSFER COMMISSION PAYMENT TO RECIPIENT"
            );
            // transfer token to user and close stake pool
            stakePools[stakedToken[_stakeId].poolId].totalEarn += _totalTokenClaimDecimal;
            stakePools[stakedToken[_stakeId].poolId].totalEarnUsd += _totalUsdClaimDecimal;
            totalClaimedToken += _totalTokenClaimDecimal;
            totalClaimedUsd += _totalUsdClaimDecimal;
            stakedToken[_stakeId].totalValueClaimed += _totalTokenClaimDecimal;
            stakedToken[_stakeId].totalValueClaimedUsd += _totalUsdClaimDecimal;
            totalUserClaimedToken[msg.sender] += _totalTokenClaimDecimal;
            totalUserClaimedUsd[msg.sender] += _totalUsdClaimDecimal;
            uint256 _poolId = _stakedUserToken.poolId;
            StakePools memory _stakePool = stakePools[_poolId];
            if (_stakePool.isMaxEarn) {
                ICommission(commissionContract).updateClaimStakeNativeUsd(msg.sender, _totalUsdClaimDecimal);
            }
            emit Claimed(_stakeId, msg.sender, _totalTokenClaimDecimal);
        }
    }

    function claimAll(uint256[] memory _stakeIds) external override  {
        require(_stakeIds.length > 0, "TOKEN STAKE: INVALID STAKE LIST");
        for (uint i = 0; i < _stakeIds.length; i++) {
            claim(_stakeIds[i]);
        }
    }

    function withdraw(uint256 _stakeId, bool _quickWithdraw) public override lock() {
        DetailStake memory _stakedUserToken = stakedToken[_stakeId];
        require(
            _stakedUserToken.userAddress == msg.sender, "STAKE: ONLY OWNER OF STAKE CAN WITHDRAW"
        );
        require(
            !_stakedUserToken.isWithdraw, "STAKE: WITHDRAW FALSE"
        );
        // check stake can be harvested now
        if (_stakedUserToken.unlockTime <= block.timestamp) {
            claim(_stakeId);
            uint256 _poolId = _stakedUserToken.poolId;
            uint256 _value = _stakedUserToken.totalValueStake;
            StakePools memory pool = stakePools[_poolId];
            bool needPending = pool.needPending;
            address _subTokenAddress = _stakedUserToken.subTokenAddress;
            uint256 _subTokenValue = _stakedUserToken.totalSubToken;
            require(SUBERC20(_subTokenAddress).balanceOf(msg.sender) >= _subTokenValue, "STAKING:  NOT ENOUGH SUB TOKEN BALANCE");
            require(
                SUBERC20(_subTokenAddress).allowance(msg.sender, address(this)) >= _subTokenValue,
                "STAKING: Must approve first"
            );
            require(
                SUBERC20(_subTokenAddress).transferFrom(msg.sender, address(this), _subTokenValue),
                "TOKEN STAKE: Transfer token to TOKEN STAKE failed"
            );
            TETHToken(_subTokenAddress).burn(_subTokenValue);
            if (needPending) {
                if (_quickWithdraw) {
                    if (withdrawFee != 0) {
                        uint256 _fee = _value * withdrawFee / 10000;
                        _value = _value - _fee;
                        totalFeeWithdrawToken += _fee;
                    }
                } else {
                    _value = 0;
                    stakedToken[_stakeId].isPending = true;
                }
            }
            stakedToken[_stakeId].isWithdraw = true;
            emit Harvested(_stakeId);
            if (_value > 0) {
                require(
                    SUBERC20(token).balanceOf(address(this)) >= _value,
                    "TOKEN STAKING: NOT ENOUGH TOKEN BALANCE TO PAY USER STAKE VALUE"
                );
                require(
                    SUBERC20(token).transfer(_stakedUserToken.userAddress, _value),
                    "STAKING: UNABLE TO TRANSFER COMMISSION PAYMENT TO STAKE USER"
                );
                //update withdraw

                uint256 totalUserStakePool = totalUserStakedPoolToken[msg.sender][_poolId] - _value;
                uint256 poolStakeValue = stakePools[_poolId].totalStake - _value;
                totalUserStakedPoolToken[msg.sender][_poolId] = totalUserStakePool;
                stakePools[_poolId].totalStake = poolStakeValue;
                totalWithdrawToken += _value;
                totalWithdrawUsd += _value * getTokenUsdPrice() / priceFeedDecimal;
                totalUserWithdrawToken[msg.sender] += _value;
                totalUserWithdrawUsd[msg.sender] += _value * getTokenUsdPrice() / priceFeedDecimal;
            }
        }
    }

    function executePendingAdmin(uint256 _stakeId) public override onlyOwner {
        DetailStake memory _stakedUserToken = stakedToken[_stakeId];
        require(_stakedUserToken.isPending, 'STAKING: Can not update not pending');
        require(_stakedUserToken.canWithdrawPending == 0, 'STAKING: This stake was updated');
        stakedToken[_stakeId].canWithdrawPending = 1;
    }

    function claimPending(uint256 _stakeId) public override lock() {
        DetailStake memory _stakedUserToken = stakedToken[_stakeId];
        require(
            _stakedUserToken.userAddress == msg.sender, "STAKE: ONLY OWNER OF STAKE CAN WITHDRAW"
        );
        require(
            _stakedUserToken.isWithdraw, "STAKE: WITHDRAW FALSE"
        );
        require(_stakedUserToken.isPending, 'STAKING: Can not update');
        require(_stakedUserToken.canWithdrawPending == 1, 'STAKING: This stake can not claim');
        stakedToken[_stakeId].canWithdrawPending = 2;
        uint256 _poolId = _stakedUserToken.poolId;
        uint256 _value = _stakedUserToken.totalValueStake;
        require(
            SUBERC20(token).balanceOf(address(this)) >= _value,
            "TOKEN STAKING: NOT ENOUGH TOKEN BALANCE TO PAY USER STAKE VALUE"
        );
        require(
            SUBERC20(token).transfer(_stakedUserToken.userAddress, _value),
            "STAKING: UNABLE TO TRANSFER COMMISSION PAYMENT TO STAKE USER"
        );
        //update withdraw
        uint256 totalUserStakePool = totalUserStakedPoolToken[msg.sender][_poolId] - _value;
        uint256 poolStakeValue = stakePools[_poolId].totalStake - _value;
        totalUserStakedPoolToken[msg.sender][_poolId] = totalUserStakePool;
        stakePools[_poolId].totalStake = poolStakeValue;
        totalWithdrawToken += _value;
        totalWithdrawUsd += _value * getTokenUsdPrice() / priceFeedDecimal;
        totalUserWithdrawToken[msg.sender] += _value;
        totalUserWithdrawUsd[msg.sender] += _value * getTokenUsdPrice() / priceFeedDecimal;
    }

    function withdrawPool(uint256[] memory _stakeIds, bool _quickWithdraw) external override {
        require(_stakeIds.length > 0, "TOKEN STAKE: INVALID STAKE LIST");
        for (uint i = 0; i < _stakeIds.length; i++) {
            withdraw(_stakeIds[i], _quickWithdraw);
        }
    }

    function getTotalUserWithdrawToken(address _userId) public view override returns (uint256) {
        return totalUserWithdrawToken[_userId];
    }

    function getTotalUserWithdrawUsd(address _userId) public view override returns (uint256) {
        return totalUserWithdrawUsd[_userId];
    }

    function setApyContract(address _stakeApy) external override onlyOwner {
        stakeApy = _stakeApy;
    }

    function setUsdtDecimal(uint256 _decimal) external onlyOwner {
        usdtDecimal = _decimal;
    }

    function setUsdContract(address _usdAddress) external override onlyOwner {
        usdToken = _usdAddress;
    }

    function setTokenContract(address _token) external override onlyOwner {
        token = _token;
    }

    function getTokenUsdPrice() public view returns (uint256) {
        if (usePrice == 1) {
            return uint256(getLatestPrice());
        }
        return getPriceOracle();
    }

    function getPriceOracle() internal view returns (uint256) {
        uint256 tokenPrice = Oracle(oracleContract).convertUsdBalanceDecimalToTokenDecimal(token, tokenDecimal);
        return tokenDecimal * priceFeedDecimal / tokenPrice;
    }

    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return priceFeed;
    }

    /**
 *   @dev Recover lost bnb and send it to the contract owner
     */
    function recoverLostBNB() public override onlyOwner {
        address payable recipient = payable(msg.sender);
        recipient.transfer(address(this).balance);
    }

    /**
 * @dev withdraw some token balance from contract to owner account
     */
    function withdrawTokenEmergency(address _token, uint256 _amount) public override onlyOwner {
        require(_amount > 0, "INVALID AMOUNT");
        require(SUBERC20(_token).transfer(msg.sender, _amount), "CANNOT WITHDRAW TOKEN");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract SUBERC20 is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private addressCanMint;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function setAddressCanMint(address account, bool hasUpdate) public onlyOwner {
        addressCanMint[account] = hasUpdate;
    }

    function isAddressCanMint(address account) public view returns (bool) {
        return addressCanMint[account];
    }

    function mintToken(address account, uint256 amount) external {
        require(
            isAddressCanMint(msg.sender) || owner() == msg.sender,
            "fBNB: CANNOT MINT"
        );
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
        // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
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

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
        // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
        // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "./SUBERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract SUBERC20Burnable is Context, SUBERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./SUBERC20.sol";
import "./SUBERC20Burnable.sol";

contract TETHToken is SUBERC20, SUBERC20Burnable {
    address private contractOwner;

    constructor() SUBERC20("tETH", "tETH") {
        contractOwner = _msgSender();
    }

    modifier checkOwner() {
        require(owner() == _msgSender() || contractOwner == _msgSender(), "tETH: CALLER IS NOT THE OWNER");
        _;
    }

    function recoverLostBNB() public checkOwner {
        address payable recipient = payable(msg.sender);
        recipient.transfer(address(this).balance);
    }

    function withdrawTokenEmergency(address _token, uint256 _amount) public checkOwner {
        require(_amount > 0, "tETH: INVALID AMOUNT");
        require(SUBERC20(_token).transfer(msg.sender, _amount), "tETH: CANNOT WITHDRAW TOKEN");
    }
}