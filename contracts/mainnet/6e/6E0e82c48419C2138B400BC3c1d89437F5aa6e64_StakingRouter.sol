// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Library used to perform common ERC20 transactions
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Library performs approvals, transfers and views ERC20 state fields
library GammaSwapLibrary {

    error ST_Fail();
    error STF_Fail();
    error SA_Fail();
    error STE_Fail();

    /// @dev Check the ERC20 balance of an address
    /// @param _token - address of ERC20 token we're checking the balance of
    /// @param _address - Ethereum address we're checking for balance of ERC20 token
    /// @return balanceOf - amount of _token held in _address
    function balanceOf(address _token, address _address) internal view returns (uint256) {
        (bool success, bytes memory data) = _token.staticcall(abi.encodeCall(IERC20.balanceOf, _address));

        require(success && data.length >= 32);

        return abi.decode(data, (uint256));
    }

    /// @dev Get how much of an ERC20 token is in existence (minted)
    /// @param _token - address of ERC20 token we're checking the total minted amount of
    /// @return totalSupply - total amount of _token that is in existence (minted and not burned)
    function totalSupply(address _token) internal view returns (uint256) {
        (bool success, bytes memory data) = _token.staticcall(abi.encodeCall(IERC20.totalSupply,()));

        require(success && data.length >= 32);

        return abi.decode(data, (uint256));
    }

    /// @dev Get decimals of ERC20 token
    /// @param _token - address of ERC20 token we are getting the decimal information from
    /// @return decimals - decimals of ERC20 token
    function decimals(address _token) internal view returns (uint8) {
        (bool success, bytes memory data) = _token.staticcall(abi.encodeWithSignature("decimals()")); // requesting via ERC20 decimals implementation

        require(success && data.length >= 1);

        return abi.decode(data, (uint8));
    }

    /// @dev Get symbol of ERC20 token
    /// @param _token - address of ERC20 token we are getting the symbol information from
    /// @return symbol - symbol of ERC20 token
    function symbol(address _token) internal view returns (string memory) {
        (bool success, bytes memory data) = _token.staticcall(abi.encodeWithSignature("symbol()")); // requesting via ERC20 symbol implementation

        require(success && data.length >= 1);

        return abi.decode(data, (string));
    }

    /// @dev Get name of ERC20 token
    /// @param _token - address of ERC20 token we are getting the name information from
    /// @return name - name of ERC20 token
    function name(address _token) internal view returns (string memory) {
        (bool success, bytes memory data) = _token.staticcall(abi.encodeWithSignature("name()")); // requesting via ERC20 name implementation

        require(success && data.length >= 1);

        return abi.decode(data, (string));
    }

    /// @dev Safe transfer any ERC20 token, only used internally
    /// @param _token - address of ERC20 token that will be transferred
    /// @param _to - destination address where ERC20 token will be sent to
    /// @param _amount - quantity of ERC20 token to be transferred
    function safeTransfer(address _token, address _to, uint256 _amount) internal {
        (bool success, bytes memory data) = _token.call(abi.encodeCall(IERC20.transfer, (_to, _amount)));

        if(!(success && (data.length == 0 || abi.decode(data, (bool))))) revert ST_Fail();
    }

    /// @dev Moves `amount` of ERC20 token `_token` from `_from` to `_to` using the allowance mechanism. `_amount` is then deducted from the caller's allowance.
    /// @param _token - address of ERC20 token that will be transferred
    /// @param _from - address sending _token (not necessarily caller's address)
    /// @param _to - address receiving _token
    /// @param _amount - amount of _token being sent
    function safeTransferFrom(address _token, address _from, address _to, uint256 _amount) internal {
        (bool success, bytes memory data) = _token.call(abi.encodeCall(IERC20.transferFrom, (_from, _to, _amount)));

        if(!(success && (data.length == 0 || abi.decode(data, (bool))))) revert STF_Fail();
    }

    /// @dev Safe approve any ERC20 token to be spent by another address (`_spender`), only used internally
    /// @param _token - address of ERC20 token that will be approved
    /// @param _spender - address that will be granted approval to spend msg.sender tokens
    /// @param _amount - quantity of ERC20 token that `_spender` will be approved to spend
    function safeApprove(address _token, address _spender, uint256 _amount) internal {
        (bool success, bytes memory data) = _token.call(abi.encodeCall(IERC20.approve, (_spender, _amount)));

        if(!(success && (data.length == 0 || abi.decode(data, (bool))))) revert SA_Fail();
    }

    /// @dev Safe transfer any ERC20 token, only used internally
    /// @param _to - destination address where ETH will be sent to
    /// @param _amount - quantity of ERC20 token to be transferred
    function safeTransferETH(address _to, uint256 _amount) internal {
        (bool success, ) = _to.call{value: _amount}("");

        if(!success) revert STE_Fail();
    }

    /// @dev Check if `account` is a smart contract's address and it has been instantiated (has code)
    /// @param account - Ethereum address to check if it's a smart contract address
    /// @return bool - true if it is a smart contract address
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function convertUint128ToUint256Array(uint128[] memory arr) internal pure returns(uint256[] memory res) {
        res = new uint256[](arr.length);
        for(uint256 i = 0; i < arr.length;) {
            res[i] = uint256(arr[i]);
            unchecked {
                ++i;
            }
        }
    }

    function convertUint128ToRatio(uint128[] memory arr) internal pure returns(uint256[] memory res) {
        res = new uint256[](arr.length);
        for(uint256 i = 0; i < arr.length;) {
            res[i] = uint256(arr[i]) * 1000;
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Interface for Beacon Proxy Factory contract
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Beacon Proxy Factory creates Beacon Proxies that hold hold the state of the staking contracts
/// @dev There has to be a BeaconProxyFactory for each staking contract implementation
interface IBeaconProxyFactory {
    /// @dev Deploy beacon proxy Contract
    /// @return _beaconProxy address of beacon proxy contract
    function deploy() external returns (address _beaconProxy);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title Interface for Loan Tracker
/// @author Simon Mall
/// @notice Reward tracker specifically for staking loans
/// @dev Need to implement `supportsInterface` function
interface ILoanTracker is IERC20, IERC165 {
    /// @dev Initializes loan tracker
    /// @param _factory address of GammaPool factory contract
    /// @param _refId reference Id for loans that can be staked
    /// @param _manager address that has admin privileges in LoanTracker
    /// @param _name ERC20 name implementation
    /// @param _symbol ERC20 symbol implementation
    /// @param _gsPool GammaPool address
    /// @param _distributor Reward distributor
    function initialize(address _factory, uint16 _refId, address _manager, string memory _name, string memory _symbol, address _gsPool, address _distributor) external;

    /// @dev Set action handlers for this contract
    /// @param _handler Address to grant handler permissions to
    /// @param _isActive Allow or disallow handler permissions to `_handler`
    function setHandler(address _handler, bool _isActive) external;

    /// @dev Update reward params for contract
    function updateRewards() external;

    /// @dev Map staked Loan Id to staker address
    /// @param _loanId Staked loan id
    /// @return Address staked this loan
    function stakedLoans(uint256 _loanId) external view returns (address);

    /// @dev Stake loan
    /// @param _loanId Loan NFT identifier
    function stake(uint256 _loanId) external;

    /// @dev Stake loan on behalf of user
    /// @param _account Owner of loan
    /// @param _loanId Loan NFT identifier
    function stakeForAccount(address _account, uint256 _loanId) external;

    /// @dev Unstake loan
    /// @param _loanId Loan NFT identifier
    function unstake(uint256 _loanId) external;

    /// @dev Unstake loan on behalf of user
    /// @param _account Owner of loan
    /// @param _loanId Loan NFT identifier
    function unstakeForAccount(address _account, uint256 _loanId) external;

    /// @return Reward tokens emission per second
    function tokensPerInterval() external view returns (uint256);

    /// @dev Claim rewards for user
    /// @param _receiver Receiver of the rewards
    function claim(address _receiver) external returns (uint256);

    /// @dev Claim rewards on behalf of user
    /// @param _account User address eligible for rewards
    /// @param _receiver Receiver of the rewards
    function claimForAccount(address _account, address _receiver) external returns (uint256);

    /// @dev Returns claimable rewards amount for the user
    /// @param _account User address for this query
    function claimable(address _account) external view returns (uint256);

    /// @param _account User account in query
    /// @return Accrued rewards for user
    function cumulativeRewards(address _account) external view returns (uint256);

    /// @dev Set through initialize function
    /// @return GS Pool this LoanTracker is for
    function gsPool() external view returns (address);

    /// @dev Set in constructor
    /// @return Address of admin contract for this LoanTracker
    function manager() external view returns (address);

    /// @dev Set through initialize function
    /// @return Address of distributor contract for this LoanTracker
    function distributor() external view returns (address);

    /// @dev Given by distributor
    /// @return Address of reward token earned from staking
    function rewardToken() external view returns (address);

    /// @dev Emitted when rewards are claimed
    /// @param _account Beneficiary user
    /// @param _amount Rewards amount claimed
    event Claim(address _account, uint256 _amount);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for RestrictedToken contract
/// @author Simon Mall
/// @notice Used for esGS, esGSb and bnGS
interface IRestrictedToken is IERC20 {
  enum TokenType { ESCROW, BONUS }

  function tokenType() external view returns (TokenType);

  /// @param _user Address for query
  /// @return Check if an address is manager
  function isManager(address _user) external returns (bool);

  /// @notice Only admin is allowed to do this
  /// @dev Set manager permission
  /// @param _user Address to set permission to
  /// @param _isActive True - enable, False - disable
  function setManager(address _user, bool _isActive) external;

  /// @param _user Address for query
  /// @return Check if an address is handler
  function isHandler(address _user) external returns (bool);

  /// @notice Only admin or managers are allowed to do this
  /// @dev Set handler permission
  /// @param _user Address to set permission to
  /// @param _isActive True - enable, False - disable
  function setHandler(address _user, bool _isActive) external;

  /// @notice Only admin or managers or handlers are allowed to do this
  /// @dev Mint tokens
  /// @param _account Address to mint to
  /// @param _amount Amount of tokens to mint
  function mint(address _account, uint256 _amount) external;

  /// @notice Only admin or managers or handlers are allowed to do this
  /// @dev Burn tokens
  /// @param _account Address to burn from
  /// @param _amount Amount of tokens to burn
  function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title RewardDistributor contract
/// @author Simon Mall
/// @notice Distribute reward tokens to reward trackers
/// @dev Need to implement `supportsInterface` function
interface IRewardDistributor is IERC165 {
    /// @dev Configure contract after deployment
    /// @param _rewardToken Reward token this distributor distributes
    /// @param _rewardTracker Reward tracker associated with this distributor
    function initialize(address _rewardToken, address _rewardTracker) external;

    /// @dev used to pause distributions. Must be turned on to start rewarding stakers
    /// @return True when distributor is paused
    function paused() external view returns(bool);

    /// @dev Updated with every distribution or pause
    /// @return Last distribution time
    function lastDistributionTime() external view returns (uint256);

    /// @dev Given in the constructor
    /// @return RewardTracker contract associated with this RewardDistributor
    function rewardTracker() external view returns (address);

    /// @dev Given in the constructor
    /// @return Reward token contract
    function rewardToken() external view returns (address);

    /// @dev Amount of tokens to be distributed every second
    /// @return The tokens per interval based on duration
    function tokensPerInterval() external view returns (uint256);

    /// @dev Calculates the pending rewards based on the time since the last distribution
    /// @return The pending rewards amount
    function pendingRewards() external view returns (uint256);

    /// @dev Distributes pending rewards to the reward tracker
    /// @return The amount of rewards distributed
    function distribute() external returns (uint256);

    /// @dev Updates the last distribution time to the current block timestamp
    /// @dev Can only be called by the contract owner.
    function updateLastDistributionTime() external;

    /// @dev Pause or resume reward emission
    /// @param _paused Indicates if the reward emission is paused
    function setPaused(bool _paused) external;

    /// @dev Withdraw tokens from this contract
    /// @param _token ERC20 token address, address(0) refers to native token(i.e. ETH)
    /// @param _recipient Recipient for the withdrawal
    /// @param _amount Amount of tokens to withdraw
    function withdrawToken(address _token, address _recipient, uint256 _amount) external;

    /// @dev Returns max withdrawable amount of reward tokens in this contract
    function maxWithdrawableAmount() external returns (uint256);

    /// @dev Emitted when rewards are distributed to reward tracker
    /// @param amount Amount of reward tokens distributed
    event Distribute(uint256 amount);

    /// @dev Emitted when `tokensPerInterval` is updated
    /// @param amount Amount of reward tokens for every second
    event TokensPerIntervalChange(uint256 amount);

    /// @dev Emitted when bonus multipler basispoint is updated
    /// @param basisPoints New basispoints for bonus multiplier
    event BonusMultiplierChange(uint256 basisPoints);

    /// @dev Emitted when reward emission is paused or resumed
    /// @param rewardTracker Reward tracker contract mapped to this distributor
    /// @param timestamp Timestamp of this event
    /// @param paused If distributor is paused or not
    event StatusChange(address indexed rewardTracker, uint256 timestamp, bool paused);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title Interface for RewardTracker contract
/// @author Simon Mall
/// @notice Track staked/unstaked tokens along with their rewards
/// @notice RewardTrackers are ERC20
/// @dev Need to implement `supportsInterface` function
interface IRewardTracker is IERC20, IERC165 {
    /// @dev Set through initialize function
    /// @return RewardDistributor contract associated with this RewardTracker
    function distributor() external view returns(address);

    /// @dev Given by distributor
    /// @return Reward token contract
    function rewardToken() external view returns (address);

    /// @dev Set to true by default
    /// @return if true only handlers can transfer
    function inPrivateTransferMode() external view returns (bool);

    /// @dev Set to true by default
    /// @return if true only handlers can stake/unstake
    function inPrivateStakingMode() external view returns (bool);

    /// @dev Set to false by default
    /// @return if true only handlers can claim for an account
    function inPrivateClaimingMode() external view returns (bool);

    /// @dev Configure contract after deployment
    /// @param _name ERC20 name of reward tracker token
    /// @param _symbol ERC20 symbol of reward tracker token
    /// @param _depositTokens Eligible tokens for stake
    /// @param _distributor Reward distributor
    function initialize(string memory _name, string memory _symbol, address[] memory _depositTokens, address _distributor) external;

    /// @dev Set/Unset staking for token
    /// @param _depositToken Token address for query
    /// @param _isDepositToken True - Set, False - Unset
    function setDepositToken(address _depositToken, bool _isDepositToken) external;

    /// @dev Enable/Disable token transfers between accounts
    /// @param _inPrivateTransferMode Whether or not to enable token transfers
    function setInPrivateTransferMode(bool _inPrivateTransferMode) external;

    /// @dev Enable/Disable token staking from individual users
    /// @param _inPrivateStakingMode Whether or not to enable token staking
    function setInPrivateStakingMode(bool _inPrivateStakingMode) external;

    /// @dev Enable/Disable rewards claiming from individual users
    /// @param _inPrivateClaimingMode Whether or not to enable rewards claiming
    function setInPrivateClaimingMode(bool _inPrivateClaimingMode) external;

    /// @dev Set handler for this contract
    /// @param _handler Address for query
    /// @param _isActive True - Enable, False - Disable
    function setHandler(address _handler, bool _isActive) external;

    /// @dev Withdraw tokens from this contract
    /// @param _token ERC20 token address, address(0) refers to native token(i.e. ETH)
    /// @param _recipient Recipient for the withdrawal
    /// @param _amount Amount of tokens to withdraw
    function withdrawToken(address _token, address _recipient, uint256 _amount) external;

    /// @param _account Address for query
    /// @param _depositToken Token address for query
    /// @return Amount of staked tokens for user
    function depositBalances(address _account, address _depositToken) external view returns (uint256);

    /// @param _depositToken Token address of total deposit tokens to check
    /// @return Amount of all deposit tokens staked
    function totalDepositSupply(address _depositToken) external view returns (uint256);

    /// @param _account Address for query
    /// @return Total staked amounts for all deposit tokens
    function stakedAmounts(address _account) external view returns (uint256);

    /// @dev Update reward params for contract
    function updateRewards() external;

    /// @dev Stake deposit token to this contract
    /// @param _depositToken Deposit token to stake
    /// @param _amount Amount of deposit tokens
    function stake(address _depositToken, uint256 _amount) external;

    /// @dev Stake tokens on behalf of user
    /// @param _fundingAccount Address to stake tokens from
    /// @param _account Address to stake tokens for
    /// @param _depositToken Deposit token to stake
    /// @param _amount Amount of deposit tokens
    function stakeForAccount(address _fundingAccount, address _account, address _depositToken, uint256 _amount) external;

    /// @dev Unstake tokens from this contract
    /// @param _depositToken Deposited token
    /// @param _amount Amount to unstake
    function unstake(address _depositToken, uint256 _amount) external;

    /// @dev Unstake tokens on behalf of user
    /// @param _account Address to unstake tokens from
    /// @param _depositToken Deposited token
    /// @param _amount Amount to unstake
    /// @param _receiver Receiver of unstaked tokens
    function unstakeForAccount(address _account, address _depositToken, uint256 _amount, address _receiver) external;

    /// @return Reward tokens emission per second
    function tokensPerInterval() external view returns (uint256);

    /// @dev Claim rewards for user
    /// @param _receiver Receiver of the rewards
    function claim(address _receiver) external returns (uint256);

    /// @dev Claim rewards on behalf of user
    /// @param _account User address eligible for rewards
    /// @param _receiver Receiver of the rewards
    function claimForAccount(address _account, address _receiver) external returns (uint256);

    /// @dev Returns claimable rewards amount for the user
    /// @param _account User address for this query
    function claimable(address _account) external view returns (uint256);

    /// @param _account Address for query
    /// @return Average staked amounts of pair tokens required (used for vesting)
    function averageStakedAmounts(address _account) external view returns (uint256);

    /// @param _account User account in query
    /// @return Accrued rewards for user
    function cumulativeRewards(address _account) external view returns (uint256);

    /// @dev Emitted when deposit tokens are set
    /// @param _depositToken Deposit token address
    /// @param _isDepositToken If the token deposit is allowed
    event DepositTokenSet(address indexed _depositToken, bool _isDepositToken);

    /// @dev Emitted when tokens are staked
    /// @param _fundingAccount User address to account from
    /// @param _account User address to account to
    /// @param _depositToken Deposit token address
    /// @param _amount Amount of staked tokens
    event Stake(address indexed _fundingAccount, address indexed _account, address indexed _depositToken, uint256 _amount);

    /// @dev Emitted when tokens are unstaked
    /// @param _account User address
    /// @param _depositToken Deposit token address
    /// @param _amount Amount of unstaked tokens
    /// @param _receiver Receiver address
    event Unstake(address indexed _account, address indexed _depositToken, uint256 _amount, address indexed _receiver);

    /// Emitted whenever reward metric is updated
    /// @param _cumulativeRewardPerToken Up to date value for reward per staked token
    event RewardsUpdate(uint256 indexed _cumulativeRewardPerToken);

    /// @dev Emitted whenever user reward metrics are updated
    /// @param _account User address
    /// @param _claimableReward Claimable reward for `_account`
    /// @param _previousCumulatedRewardPerToken Reward per staked token for `_account` before update
    /// @param _averageStakedAmount Reserve token amounts required for vesting for `_account`
    /// @param _cumulativeReward Total claimed and claimable rewards for `_account`
    event UserRewardsUpdate(
        address indexed _account,
        uint256 _claimableReward,
        uint256 _previousCumulatedRewardPerToken,
        uint256 _averageStakedAmount,
        uint256 _cumulativeReward
    );

    /// @dev Emitted when rewards are claimed
    /// @param _account User address claiming
    /// @param _amount Rewards amount claimed
    /// @param _receiver Receiver of the rewards
    event Claim(address indexed _account, uint256 _amount, address _receiver);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Interface for StakingAdmin contract
/// @author Simon Mall
/// @notice StakingAdmin is an abstract base contract for StakingRouter
/// @notice StakingAdmin is meant to have admin only functions
interface IStakingAdmin {
  /// @dev Thrown in constructor for invalid params
  error InvalidConstructor();

  /// @dev Thrown in constructor for invalid restricted tokens
  error InvalidRestrictedToken();

  /// @dev Thrown in `execute` when calling untrusted contracts
  error InvalidExecute();

  /// @dev Thrown in `execute` for executing arbitrary calls for staking contracts
  error ExecuteFailed();

  /// @dev Thrown when creating staking contracts that have already been created for that deposit token
  error StakingContractsAlreadySet();

  /// @dev Thrown when a initializing the StakingAdmin with a zero address
  error MissingBeaconProxyFactory();

  /// @dev Thrown when a zero address is passed as one of the GS token parameters
  error MissingGSTokenParameter();

  /// @dev Thrown when setting GS token parameters when they have already been set
  error GSTokensAlreadySet();

  /// @dev Contracts for global staking
  struct AssetCoreTracker {
    address rewardTracker;  // Track GS + esGS
    address rewardDistributor;  // Reward esGS
    address loanRewardTracker;  // Track esGSb
    address loanRewardDistributor;  // Reward esGSb
    address bonusTracker; // Track GS + esGS + esGSb
    address bonusDistributor; // Reward bnGS
    address feeTracker; // Track GS + esGS + esGSb + bnGS(aka MP)
    address feeDistributor; // Reward WETH
    address vester; // Vest esGS -> GS (reserve GS or esGS or bnGS)
    address loanVester; // Vest esGSb -> GS (without reserved tokens)
  }

  /// @dev Contracts for pool-level staking
  struct AssetPoolTracker {
    address rewardTracker;  // Track GS_LP
    address rewardDistributor;  // Reward esGS
    address loanRewardTracker;  // Track tokenId(loan)
    address loanRewardDistributor;  // Reward esGSb
    address vester; // Vest esGS -> GS (reserve GS_LP)
  }

  /// @dev Setting up GS token parameters so that we can initialize the GS staking contracts (coreTrackers)
  /// @notice This can only be set once
  /// @param _gs - address of GS token
  /// @param _esGs - address of escrow GS token
  /// @param _esGsb - address of escrow GS token for loans
  /// @param _bnGs - address of bonus GS token
  /// @param _feeRewardToken - address of fee reward token
  function initializeGSTokens(address _gs, address _esGs, address _esGsb, address _bnGs, address _feeRewardToken) external;

  /// @dev GS token entitles stakers to a share of protocol revenue
  /// @return address of GS token
  function gs() external view returns(address);

  /// @dev Escrow GS tokens convert to GS token when vested
  /// @return address of escrow GS token
  function esGs() external view returns(address);

  /// @dev Escrow GS token for loans convert to GS token when vested
  /// @return address of escrow GS token for loans
  function esGsb() external view returns(address);

  /// @dev Bonus GS tokens increases share of protocol fees when staking GS tokens
  /// @return address of Bonus GS token
  function bnGs() external view returns(address);

  /// @dev Fee reward token is given as protocol revenue to stakers of GS token
  /// @return address of fee reward token
  function feeRewardToken() external view returns(address);

  /// @dev Get contracts for global staking
  /// @return rewardTracker Track GS + esGS
  /// @return rewardDistributor Reward esGS
  /// @return loanRewardTracker Track esGSb
  /// @return loanRewardDistributor Reward esGSb
  /// @return bonusTracker Track GS + esGS + esGSb
  /// @return bonusDistributor Reward bnGS
  /// @return feeTracker Track GS + esGS + esGSb + bnGS(aka MP)
  /// @return feeDistributor Reward WETH
  /// @return vester Vest esGS -> GS (reserve GS or esGS or bnGS)
  /// @return loanVester Vest esGSb -> GS (without reserved tokens)
  function coreTracker() external view returns(address rewardTracker, address rewardDistributor, address loanRewardTracker,
    address loanRewardDistributor, address bonusTracker, address bonusDistributor, address feeTracker, address feeDistributor,
    address vester, address loanVester);

  /// @dev Get contracts for pool staking
  /// @param pool address of GS pool that staking contract is for
  /// @param esToken address of escrow token staking contract rewards
  /// @return rewardTracker Track GS_LP
  /// @return rewardDistributor Reward esGS
  /// @return loanRewardTracker Track tokenId(loan)
  /// @return loanRewardDistributor Reward esGSb
  /// @return vester Vest esGS -> GS (reserve GS_LP)
  function poolTrackers(address pool, address esToken) external view returns(address rewardTracker,
    address rewardDistributor, address loanRewardTracker, address loanRewardDistributor, address vester);

  /// @dev Initialize StakingAdmin contract
  /// @param _loanTrackerFactory address of BeaconProxyFactory with LoanTracker implementation
  /// @param _rewardTrackerFactory address of BeaconProxyFactory with RewardTracker implementation
  /// @param _feeTrackerFactory address of BeaconProxyFactory with FeeTracker implementation
  /// @param _rewardDistributorFactory address of BeaconProxyFactory with RewardDistributor implementation
  /// @param _bonusDistributorFactory address of BeaconProxyFactory with BonusDistributor implementation
  /// @param _vesterFactory address of BeaconProxyFactory with Vester implementation
  /// @param _vesterNoReserveFactory address of BeaconProxyFactory with VesterNoReserve implementation
  function initialize(address _loanTrackerFactory, address _rewardTrackerFactory, address _feeTrackerFactory,
    address _rewardDistributorFactory, address _bonusDistributorFactory, address _vesterFactory,
    address _vesterNoReserveFactory) external;

  /// @dev Set vesting period for staking contract reward token
  function setPoolVestingPeriod(uint256 _poolVestingPeriod) external;

  /// @dev Setup global staking for GS/esGS/bnGS
  function setupGsStaking() external;

  /// @dev Setup global staking for esGSb
  function setupGsStakingForLoan() external;

  /// @dev Setup pool-level staking for GS_LP
  /// @param _gsPool GammaPool address
  /// @param _esToken Escrow reward token
  /// @param _claimableToken Claimable token from vesting
  function setupPoolStaking(address _gsPool, address _esToken, address _claimableToken) external;

  /// @dev Setup pool-level staking for loans
  /// @param _gsPool GammaPool address
  /// @param _refId Reference id for loan observer
  function setupPoolStakingForLoan(address _gsPool, uint16 _refId) external;

  /// @dev Execute arbitrary calls for staking contracts
  /// @param _stakingContract Contract to execute on
  /// @param _data Bytes data to pass as param
  function execute(address _stakingContract, bytes memory _data) external;

  /// @dev Emitted in `setupGsStaking`
  event CoreTrackerCreated(address rewardTracker, address rewardDistributor, address bonusTracker, address bonusDistributor, address feeTracker, address feeDistributor, address vester);

  /// @dev Emitted in `setupGsStakingForLoan`
  event CoreTrackerUpdated(address loanRewardTracker, address loanRewardDistributor, address loanVester);

  /// @dev Emitted in `setupPoolStaking`
  event PoolTrackerCreated(address indexed gsPool, address rewardTracker, address rewardDistributor, address vester);

  /// @dev Emitted in `setupPoolStakingForLoan`
  event PoolTrackerUpdated(address indexed gsPool, address loanRewardtracker, address loanRewardDistributor);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IStakingAdmin.sol";

/// @title Interface for StakingRouter contract
/// @author Simon Mall
/// @notice Contains user facing functions
interface IStakingRouter is IStakingAdmin {
    /* Stake */
    /// @dev Stake GS tokens on behalf of user
    /// @param _account User address for query
    /// @param _amount Amount of GS tokens to stake
    function stakeGsForAccount(address _account, uint256 _amount) external;

    /// @dev Stake GS tokens
    /// @param _amount Amount of GS tokens to stake
    function stakeGs(uint256 _amount) external;

    /// @dev Stake esGS tokens
    /// @param _amount AMount of esGS tokens to stake
    function stakeEsGs(uint256 _amount) external;

    /// @dev Stake esGSb tokens
    /// @param _amount Amount of esGSb tokens to stake
    function stakeEsGsb(uint256 _amount) external;

    /// @dev Stake GS_LP tokens on behalf of user
    /// @param _account User address for query
    /// @param _gsPool GammaPool address
    /// @param _esToken Escrow token address
    /// @param _amount Amount of GS_LP tokens to stake
    function stakeLpForAccount(address _account, address _gsPool, address _esToken, uint256 _amount) external;

    /// @dev Stake GS_LP tokens
    /// @param _gsPool GammaPool address
    /// @param _esToken Escrow token address
    /// @param _amount Amount of GS_LP tokens to stake
    function stakeLp(address _gsPool, address _esToken, uint256 _amount) external;

    /// @dev Stake loan on behalf of user
    /// @param _account User address for query
    /// @param _gsPool GammaPool address
    /// @param _loanId NFT loan id
    function stakeLoanForAccount(address _account, address _gsPool, uint256 _loanId) external;

    /// @dev Stake loan
    /// @param _gsPool GammaPool address
    /// @param _loanId NFT loan id
    function stakeLoan(address _gsPool, uint256 _loanId) external;

    /// @dev Unstake GS tokens
    /// @param _amount Amount of GS tokens to unstake
    function unstakeGs(uint256 _amount) external;

    /// @dev Unstake esGS tokens
    /// @param _amount Amount of esGS tokens to unstake
    function unstakeEsGs(uint256 _amount) external;

    /// @dev Unstake esGSb tokens
    /// @param _amount Amount of esGSb tokens to unstake
    function unstakeEsGsb(uint256 _amount) external;

    /// @dev Unstake GS_LP tokens on behalf of user
    /// @param _account User address for query
    /// @param _gsPool GammaPool address
    /// @param _esToken Escrow token address
    /// @param _amount Amount of GS_LP tokens to unstake
    function unstakeLpForAccount(address _account, address _gsPool, address _esToken, uint256 _amount) external;

    /// @dev Unstake GS_LP tokens
    /// @param _gsPool GammaPool address
    /// @param _esToken Escrow token address
    /// @param _amount Amount of GS_LP tokens to unstake
    function unstakeLp(address _gsPool, address _esToken, uint256 _amount) external;

    /// @dev Unstake loan on behalf of user
    /// @param _account User address for query
    /// @param _gsPool GammaPool address
    /// @param _loanId NFT loan id
    function unstakeLoanForAccount(address _account, address _gsPool, uint256 _loanId) external;

    /// @dev Unstake loan
    /// @param _gsPool GammaPool address
    /// @param _loanId NFT loan id
    function unstakeLoan(address _gsPool, uint256 _loanId) external;

    /* Vest */
    /// @dev Vest esGS tokens
    /// @param _amount Amount of esGS tokens to vest
    function vestEsGs(uint256 _amount) external;

    /// @dev Vest escrow tokens for pool
    /// @param _gsPool GammaPool address
    /// @param _esToken Escrow token address
    /// @param _amount Amount of escrow tokens to vest
    function vestEsTokenForPool(address _gsPool, address _esToken, uint256 _amount) external;

    /// @dev Vest esGSb tokens
    /// @param _amount Amount of esGSb tokens to vest
    function vestEsGsb(uint256 _amount) external;

    /// @dev Withdraw esGS tokens in vesting
    function withdrawEsGs() external;

    /// @dev Withdraw escrow tokens in vesting for pool
    /// @param _gsPool GammaPool address
    /// @param _esToken Escrow token address
    function withdrawEsTokenForPool(address _gsPool, address _esToken) external;

    /// @dev Withdraw esGSb tokens in vesting
    function withdrawEsGsb() external;

    /* Claim */
    /// @dev Claim rewards
    /// @param _shouldClaimRewards Should claim esGS rewards?
    /// @param _shouldClaimFee Should claim protocol revenue fees?
    /// @param _shouldClaimVesting Should claim vested GS?
    function claim(bool _shouldClaimRewards, bool _shouldClaimFee, bool _shouldClaimVesting) external;

    /// @dev Claim rewards for pool
    /// @param _gsPool GammaPool address
    /// @param _esToken Escrow token address
    /// @param _shouldClaimRewards Should claim esToken rewards?
    /// @param _shouldClaimVesting Should claim vested Token?
    function claimPool(address _gsPool, address _esToken, bool _shouldClaimRewards, bool _shouldClaimVesting) external;

    /* Compound */
    /// @dev Compound staking
    function compound() external;

    /// @dev Compound staking on behalf of user
    /// @param _account User address for query
    function compoundForAccount(address _account) external;

    /// @dev Get average staked amount for user
    /// @param _gsPool GammaPool address, address(0) refers to coreTracker
    /// @param _esToken Escrow token address, optional when referring to coreTracker
    /// @param _account User address for query
    function getAverageStakedAmount(address _gsPool, address _esToken, address _account) external view returns (uint256);

    /// @dev Emitted in `_stakeGs` function
    event StakedGs(address, address, uint256);

    /// @dev Emitted in `_stakeLp` function
    event StakedLp(address, address, uint256);

    /// @dev Emitted in `_stakeLoan` function
    event StakedLoan(address, address, uint256);

    /// @dev Emitted in `_unstakeGs` function
    event UnstakedGs(address, address, uint256);

    /// @dev Emitted in `_unstakeLp` function
    event UnstakedLp(address, address, uint256);

    /// @dev Emitted in `_unstakeLoan` function
    event UnstakedLoan(address, address, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title Interface for Vester contract
/// @author Simon Mall
/// @notice Normal ERC20 token operations are not allowed
/// @dev Need to implement `supportsInterface` function
interface IVester is IERC20, IERC165 {
    /// @dev Initialize Vester contract
    /// @param _name ERC20 name implementation
    /// @param _symbol ERC20 symbol implementation
    /// @param _vestingDuration how many seconds to vest the escrow token
    /// @param _esToken address of escrow token to vest
    /// @param _pairToken address of token that must be staked to determine how many tokens can be vested (optional)
    /// @param _claimableToken address of token that is given as reward for vesting escrow token
    /// @param _rewardTracker address of contract to track staked pairTokens to determine max vesting amount
    function initialize(string memory _name, string memory _symbol, uint256 _vestingDuration, address _esToken,
        address _pairToken, address _claimableToken, address _rewardTracker) external;

    /// @dev Get last vesting time of user
    /// @param _account User address for query
    function lastVestingTimes(address _account) external view returns(uint256);

    /// @dev Only used in Vester for rewards from staked LP tokens
    /// @return Address of LP token accepted as staked to be allowed to vest
    function pairToken() external view returns (address);

    /// @dev Only used in Vester for rewards from staked LP tokens
    /// @return Total GS LP tokens staked in RewardTracker
    function pairSupply() external view returns (uint256);

    /// @dev Returns total vested esGS amounts
    /// @param _account Vesting account
    function getTotalVested(address _account) external view returns (uint256);

    /// @dev Returns required pair token amount for vesting
    /// @param _account Vesting account
    /// @param _esAmount Vesting amount
    function getPairAmount(address _account, uint256 _esAmount) external view returns (uint256);

    /// @dev Updated with every vesting update
    /// @return Total amounts of claimableToken that has already vested
    function totalClaimable() external view returns(uint256);

    /// @dev Used to require user to commit a staked amount to be able to vest an escrow token
    /// @return True if there's a limit to how many esTokens a user can vest
    function hasMaxVestableAmount() external view returns(bool);

    /// @dev Set in constructor
    /// @return Time in seconds it will take to vest  the esToken into the claimableToken
    function vestingDuration() external view returns(uint256);

    /// @dev Set in constructor
    /// @return Address of token that will be claimed when esToken is vested.
    function claimableToken() external view returns(address);

    /// @dev Set in constructor
    /// @return Address of escrow token to vest in this Vester contract
    function esToken() external view returns(address);

    /// @dev Set handler for this contract
    /// @param _handler Address for query
    /// @param _isActive True - Enable, False - Disable
    function setHandler(address _handler, bool _isActive) external;

    /// @dev Withdraw tokens from this contract
    /// @param _token ERC20 token address, address(0) refers to native token(i.e. ETH)
    /// @param _recipient Recipient for the withdrawal
    /// @param _amount Amount of tokens to withdraw
    function withdrawToken(address _token, address _recipient, uint256 _amount) external;

    /// @dev Returns max withdrawable amount of reward tokens in this contract
    function maxWithdrawableAmount() external returns (uint256);

    /// @dev Returns reward tracker contract address
    function rewardTracker() external view returns (address);

    /// @dev Vest escrow tokens into GS
    /// @param _amount Amount of escrow tokens to vest
    function deposit(uint256 _amount) external;

    /// @dev Vest escrow tokens into GS on behalf of user
    /// @param _account User address for query
    /// @param _amount Amount of escrow tokens to vest
    function depositForAccount(address _account, uint256 _amount) external;

    /// @dev Claim GS rewards
    /// @return Amount of GS rewards
    function claim() external returns(uint256);

    /// @dev Claim GS rewards on behalf of user
    /// @param _account User address for query
    /// @param _receiver Receiver of rewards
    /// @return Amount of GS rewards
    function claimForAccount(address _account, address _receiver) external returns (uint256);

    /// @dev Withdraw escrow tokens and cancel vesting
    /// @dev Refund pair tokens to user
    function withdraw() external;

    /// @dev Withdraw escrow tokens and cancel vesting on behalf of user
    /// @dev Refund pair tokens to user
    /// @param _account User address for query
    function withdrawForAccount(address _account) external;

    /// @param _account User address for query
    /// @return Claimable GS amounts
    function claimable(address _account) external view returns (uint256);

    /// @param _account User address for query
    /// @return Cumulative amounts of GS rewards
    function cumulativeClaimAmounts(address _account) external view returns (uint256);

    /// @param _account User address for query
    /// @return Total claimed GS amounts
    function claimedAmounts(address _account) external view returns (uint256);

    /// @param _account User address for query
    /// @return Pair token amounts for account
    function pairAmounts(address _account) external view returns (uint256);

    /// @param _account User address for query
    /// @return Total vested escrow token amounts
    function getVestedAmount(address _account) external view returns (uint256);

    /// @param _account User address for query
    /// @return Cumulative reward deduction amounts
    function cumulativeRewardDeductions(address _account) external view returns (uint256);

    /// @param _account User address for query
    /// @return Bonus reward amounts
    function bonusRewards(address _account) external view returns (uint256);

    /// @dev Penalty user GS rewards
    /// @param _account User address for query
    /// @param _amount Deduction GS amounts to apply
    function setCumulativeRewardDeductions(address _account, uint256 _amount) external;

    /// @dev Add bonus GS rewards
    /// @param _account User address for query
    /// @param _amount Bonus GS amounts to apply
    function setBonusRewards(address _account, uint256 _amount) external;

    /// @param _account User address for query
    /// @return Max vestable escrow token amounts based on reward tracker, bonus and deductions
    function getMaxVestableAmount(address _account) external view returns (uint256);

    /// @param _account User address for query
    /// @return Average staked amount of pair tokens required for vesting
    function getAverageStakedAmount(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "@gammaswap/v1-core/contracts/libraries/GammaSwapLibrary.sol";

import "./interfaces/IRewardTracker.sol";
import "./interfaces/ILoanTracker.sol";
import "./interfaces/IRewardDistributor.sol";
import "./interfaces/IVester.sol";
import "./interfaces/IStakingAdmin.sol";
import "./interfaces/IRestrictedToken.sol";
import "./interfaces/IBeaconProxyFactory.sol";

/// @title StakingAdmin abstract contract
/// @author Simon Mall
/// @notice Admin functions for StakingRouter contract
abstract contract StakingAdmin is IStakingAdmin, Ownable2Step, Initializable, UUPSUpgradeable {
    using GammaSwapLibrary for address;
    using ERC165Checker for address;

    address public immutable factory;
    address public immutable manager;

    address public override gs;
    address public override esGs;
    address public override esGsb;
    address public override bnGs;
    address public override feeRewardToken;

    bool public gsTokensInitialized;

    // Factories
    address private loanTrackerFactory;
    address private rewardTrackerFactory;
    address private feeTrackerFactory;
    address private rewardDistributorFactory;
    address private bonusDistributorFactory;
    address private vesterFactory;
    address private vesterNoReserveFactory;

    uint256 public constant VESTING_DURATION = 365 * 24 * 60 * 60;
    uint256 public POOL_VESTING_DURATION = 365 * 24 * 60 * 60;

    AssetCoreTracker internal _coreTracker;
    mapping(address => mapping(address => AssetPoolTracker)) internal _poolTrackers;

    constructor(address _factory, address _manager) {
        if (_factory == address(0) || _manager == address(0)) revert InvalidConstructor();

        factory = _factory;
        manager = _manager;
    }

    /// @inheritdoc IStakingAdmin
    function initialize(
        address _loanTrackerFactory,
        address _rewardTrackerFactory,
        address _feeTrackerFactory,
        address _rewardDistributorFactory,
        address _bonusDistributorFactory,
        address _vesterFactory,
        address _vesterNoReserveFactory) external override virtual initializer {
        if (_loanTrackerFactory == address(0) || _rewardTrackerFactory == address(0) || _feeTrackerFactory == address(0) ||
            _rewardDistributorFactory == address(0) || _bonusDistributorFactory == address(0) || _vesterFactory == address(0) ||
            _vesterNoReserveFactory == address(0)) {
            revert MissingBeaconProxyFactory();
        }

        _transferOwnership(msg.sender);
        POOL_VESTING_DURATION = 365 * 24 * 60 * 60;

        loanTrackerFactory = _loanTrackerFactory;
        rewardTrackerFactory = _rewardTrackerFactory;
        feeTrackerFactory = _feeTrackerFactory;
        rewardDistributorFactory = _rewardDistributorFactory;
        bonusDistributorFactory = _bonusDistributorFactory;
        vesterFactory = _vesterFactory;
        vesterNoReserveFactory = _vesterNoReserveFactory;
    }

    /// @inheritdoc IStakingAdmin
    function initializeGSTokens(address _gs, address _esGs, address _esGsb, address _bnGs, address _feeRewardToken) external override virtual onlyOwner {
        if(gsTokensInitialized) revert GSTokensAlreadySet();

        if (_gs == address(0) || _esGs == address(0) || _esGsb == address(0) || _bnGs == address(0) || _feeRewardToken == address(0)) {
            revert MissingGSTokenParameter();
        }

        if (IRestrictedToken(_esGs).tokenType() != IRestrictedToken.TokenType.ESCROW ||
            IRestrictedToken(_esGsb).tokenType() != IRestrictedToken.TokenType.ESCROW ||
            IRestrictedToken(_bnGs).tokenType() != IRestrictedToken.TokenType.BONUS) {
            revert InvalidRestrictedToken();
        }

        gsTokensInitialized = true;

        gs = _gs;
        esGsb = _esGsb;
        esGs = _esGs;
        bnGs = _bnGs;
        feeRewardToken = _feeRewardToken;

        _coreTracker.rewardTracker = address(0);
        _coreTracker.rewardDistributor = address(0);
        _coreTracker.loanRewardTracker = address(0);
        _coreTracker.loanRewardDistributor = address(0);
        _coreTracker.bonusTracker = address(0);
        _coreTracker.bonusDistributor = address(0);
        _coreTracker.feeTracker = address(0);
        _coreTracker.feeDistributor = address(0);
        _coreTracker.vester = address(0);
        _coreTracker.loanVester = address(0);
    }


    /// @inheritdoc IStakingAdmin
    function coreTracker() external override virtual view returns(address rewardTracker, address rewardDistributor,
        address loanRewardTracker, address loanRewardDistributor, address bonusTracker, address bonusDistributor,
        address feeTracker, address feeDistributor, address vester, address loanVester) {
        rewardTracker = _coreTracker.rewardTracker;  // Track GS + esGS
        rewardDistributor = _coreTracker.rewardDistributor;  // Reward esGS
        loanRewardTracker = _coreTracker.loanRewardTracker;  // Track esGSb
        loanRewardDistributor = _coreTracker.loanRewardDistributor;  // Reward esGSb
        bonusTracker = _coreTracker.bonusTracker; // Track GS + esGS + esGSb
        bonusDistributor = _coreTracker.bonusDistributor; // Reward bnGS
        feeTracker = _coreTracker.feeTracker; // Track GS + esGS + esGSb + bnGS(aka MP)
        feeDistributor = _coreTracker.feeDistributor; // Reward WETH
        vester = _coreTracker.vester; // Vest esGS -> GS (reserve GS or esGS or bnGS)
        loanVester = _coreTracker.loanVester; // Vest esGSb -> GS (without reserved tokens)
    }

    /// @inheritdoc IStakingAdmin
    function poolTrackers(address pool, address esToken) external override virtual view returns(address rewardTracker,
        address rewardDistributor, address loanRewardTracker, address loanRewardDistributor, address vester) {
        rewardTracker = _poolTrackers[pool][esToken].rewardTracker;
        rewardDistributor = _poolTrackers[pool][esToken].rewardDistributor;
        loanRewardTracker = _poolTrackers[pool][esToken].loanRewardTracker;
        loanRewardDistributor = _poolTrackers[pool][esToken].loanRewardDistributor;
        vester = _poolTrackers[pool][esToken].vester;
    }

    /// @inheritdoc IStakingAdmin
    function setPoolVestingPeriod(uint256 _poolVestingPeriod) external override virtual onlyOwner {
        POOL_VESTING_DURATION = _poolVestingPeriod;
    }

    /// @inheritdoc IStakingAdmin
    function setupGsStaking() external override virtual onlyOwner {
        if (_coreTracker.rewardTracker != address(0)) revert StakingContractsAlreadySet();

        address[] memory _depositTokens = new address[](2);
        _depositTokens[0] = gs;
        _depositTokens[1] = esGs;
        (address _rewardTracker, address _rewardDistributor) = _combineTrackerDistributor("Staked GS", "sGS", esGs, _depositTokens, 0, false, false);

        delete _depositTokens;
        _depositTokens = new address[](1);
        _depositTokens[0] = _rewardTracker;
        (address _bonusTracker, address _bonusDistributor) = _combineTrackerDistributor("Staked + Bonus GS", "sbGS", bnGs, _depositTokens, 0, false, true);

        delete _depositTokens;
        _depositTokens = new address[](2);
        _depositTokens[0] = _bonusTracker;
        _depositTokens[1] = bnGs;
        (address _feeTracker, address _feeDistributor) = _combineTrackerDistributor("Staked + Bonus + Fee GS", "sbfGS", feeRewardToken, _depositTokens, 0, true, false);

        address _vester = IBeaconProxyFactory(vesterFactory).deploy();
        IVester(_vester).initialize("Vested GS", "vGS", VESTING_DURATION, esGs, _feeTracker, gs, _rewardTracker);

        IRewardTracker(_rewardTracker).setHandler(_bonusTracker, true);
        IRewardTracker(_bonusTracker).setHandler(_feeTracker, true);
        IRewardTracker(_bonusTracker).setInPrivateClaimingMode(true);
        IRewardTracker(_feeTracker).setHandler(_vester, true);
        IVester(_vester).setHandler(address(this), true);
        IRestrictedToken(esGs).setHandler(_rewardTracker, true);
        IRestrictedToken(esGs).setHandler(_rewardDistributor, true);
        IRestrictedToken(esGs).setHandler(_vester, true);
        IRestrictedToken(bnGs).setHandler(_feeTracker, true);
        IRestrictedToken(bnGs).setHandler(_bonusTracker, true);
        IRestrictedToken(bnGs).setHandler(_bonusDistributor, true);

        _coreTracker.rewardTracker = _rewardTracker;
        _coreTracker.rewardDistributor = _rewardDistributor;
        _coreTracker.bonusTracker = _bonusTracker;
        _coreTracker.bonusDistributor = _bonusDistributor;
        _coreTracker.feeTracker = _feeTracker;
        _coreTracker.feeDistributor = _feeDistributor;
        _coreTracker.vester = _vester;

        emit CoreTrackerCreated(_rewardTracker, _rewardDistributor, _bonusTracker, _bonusDistributor, _feeTracker, _feeDistributor, _vester);
    }

    /// @inheritdoc IStakingAdmin
    function setupGsStakingForLoan() external override virtual onlyOwner {
        if (_coreTracker.loanRewardTracker != address(0)) revert StakingContractsAlreadySet();

        address[] memory _depositTokens = new address[](1);
        _depositTokens[0] = esGsb;
        (address _loanRewardTracker, address _loanRewardDistributor) = _combineTrackerDistributor("Staked GS Loan", "sGSb", esGsb, _depositTokens, 0, false, false);

        IRewardTracker(_coreTracker.bonusTracker).setDepositToken(_loanRewardTracker, true);
        IRewardTracker(_loanRewardTracker).setHandler(_coreTracker.bonusTracker, true);

        address _loanVester = IBeaconProxyFactory(vesterNoReserveFactory).deploy();
        IVester(_loanVester).initialize("Vested GS Borrowed", "vGSB", VESTING_DURATION, esGsb, address(0), gs, _loanRewardTracker);

        IVester(_loanVester).setHandler(address(this), true);
        IRestrictedToken(esGsb).setHandler(_loanRewardTracker, true);
        IRestrictedToken(esGsb).setHandler(_loanRewardDistributor, true);
        IRestrictedToken(esGsb).setHandler(_loanVester, true);

        _coreTracker.loanRewardTracker = _loanRewardTracker;
        _coreTracker.loanRewardDistributor = _loanRewardDistributor;
        _coreTracker.loanVester = _loanVester;

        emit CoreTrackerUpdated(_loanRewardTracker, _loanRewardDistributor, _loanVester);
    }

    /// @inheritdoc IStakingAdmin
    function setupPoolStaking(address _gsPool, address _esToken, address _claimableToken) external override virtual onlyOwner {
        if (IRestrictedToken(_esToken).tokenType() != IRestrictedToken.TokenType.ESCROW) revert InvalidRestrictedToken();

        if (_poolTrackers[_gsPool][_esToken].rewardTracker != address(0)) revert StakingContractsAlreadySet();

        address[] memory _depositTokens = new address[](1);
        _depositTokens[0] = _gsPool;
        (address _rewardTracker, address _rewardDistributor) = _combineTrackerDistributor("Staked GS LP", "sGSlp", _esToken, _depositTokens, 0, false, false);

        address _vester = IBeaconProxyFactory(vesterFactory).deploy();
        IVester(_vester).initialize("Vested Pool GS", "vpGS", POOL_VESTING_DURATION, _esToken, _rewardTracker, _claimableToken, _rewardTracker);

        IRewardTracker(_rewardTracker).setHandler(_vester, true);
        IVester(_vester).setHandler(address(this), true);
        IRestrictedToken(_esToken).setHandler(_rewardTracker, true);
        IRestrictedToken(_esToken).setHandler(_rewardDistributor, true);
        IRestrictedToken(_esToken).setHandler(_vester, true);

        _poolTrackers[_gsPool][_esToken].rewardTracker = _rewardTracker;
        _poolTrackers[_gsPool][_esToken].rewardDistributor = _rewardDistributor;
        _poolTrackers[_gsPool][_esToken].vester = _vester;

        _gsPool.safeApprove(_rewardTracker, type(uint256).max);

        emit PoolTrackerCreated(_gsPool, _rewardTracker, _rewardDistributor, _vester);
    }

    /// @inheritdoc IStakingAdmin
    function setupPoolStakingForLoan(address _gsPool, uint16 _refId) external override virtual onlyOwner {
        if(_poolTrackers[_gsPool][esGsb].loanRewardTracker != address(0)) revert StakingContractsAlreadySet();

        address[] memory _depositTokens = new address[](1);
        _depositTokens[0] = _gsPool;
        (address _loanRewardTracker, address _loanRewardDistributor) = _combineTrackerDistributor("Staked GS Loan", "sGSb", esGsb, _depositTokens, _refId, false, false);

        IRestrictedToken(esGsb).setHandler(_loanRewardTracker, true);
        IRestrictedToken(esGsb).setHandler(_loanRewardDistributor, true);

        _poolTrackers[_gsPool][esGsb].loanRewardTracker = _loanRewardTracker;
        _poolTrackers[_gsPool][esGsb].loanRewardDistributor = _loanRewardDistributor;

        emit PoolTrackerUpdated(_gsPool, _loanRewardTracker, _loanRewardDistributor);
    }

    /// @inheritdoc IStakingAdmin
    function execute(address _stakingContract, bytes calldata _data) external override virtual onlyOwner {
        if(
            !_stakingContract.supportsInterface(type(IRewardTracker).interfaceId) &&
            !_stakingContract.supportsInterface(type(ILoanTracker).interfaceId) &&
            !_stakingContract.supportsInterface(type(IRewardDistributor).interfaceId) &&
            !_stakingContract.supportsInterface(type(IVester).interfaceId)
        ) {
            revert InvalidExecute();
        }

        (bool success, bytes memory result) = _stakingContract.call(_data);
        if (!success) {
            if (result.length == 0) revert ExecuteFailed();
            assembly {
                revert(add(32, result), mload(result))
            }
        }
    }

    /// @dev Deploy reward tracker and distributor as a pair and bind them
    /// @param _name RewardTracker name as ERC20 token
    /// @param _symbol RewardTracker symbol as ERC20 token
    /// @param _rewardToken Reward token address
    /// @param _depositTokens Array of deposit tokens in RewardTracker
    /// @param _refId LoanObserver Id
    /// @param _isFeeTracker True if reward tracker should be FeeTracker
    /// @param _isBonusDistributor True if reward distributor should be BonusDistributor
    /// @return Reward tracker address
    /// @return Reward distributor address
    function _combineTrackerDistributor(
        string memory _name,
        string memory _symbol,
        address _rewardToken,
        address[] memory _depositTokens,
        uint16 _refId,
        bool _isFeeTracker,
        bool _isBonusDistributor
    ) private returns (address, address) {
        address tracker;
        if (_refId > 0) {
            tracker = IBeaconProxyFactory(loanTrackerFactory).deploy();
        } else if (_isFeeTracker) {
            tracker = IBeaconProxyFactory(feeTrackerFactory).deploy();
        } else {
            tracker = IBeaconProxyFactory(rewardTrackerFactory).deploy();
        }

        address distributor;
        if (_isBonusDistributor) {
            distributor = IBeaconProxyFactory(bonusDistributorFactory).deploy();
            IRewardDistributor(distributor).initialize(_rewardToken, tracker);
        } else {
            distributor = IBeaconProxyFactory(rewardDistributorFactory).deploy();
            IRewardDistributor(distributor).initialize(_rewardToken, tracker);
        }

        if (_refId > 0) {
            ILoanTracker(tracker).initialize(factory, _refId, manager, _name, _symbol,_depositTokens[0], distributor);
            ILoanTracker(tracker).setHandler(address(this), true);
        } else {
            IRewardTracker(tracker).initialize(_name, _symbol, _depositTokens, distributor);
            IRewardTracker(tracker).setHandler(address(this), true);
        }
        IRewardDistributor(distributor).updateLastDistributionTime();

        return (tracker, distributor);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IRestrictedToken.sol";
import "./interfaces/IStakingRouter.sol";
import "./StakingAdmin.sol";

/// @title StakingRouter contract
/// @author Simon Mall
/// @notice Single entry for all staking related functions
contract StakingRouter is ReentrancyGuard, StakingAdmin, IStakingRouter {
    constructor(address _factory, address _manager) StakingAdmin(_factory, _manager) {
    }

    /// @inheritdoc IStakingRouter
    function stakeGsForAccount(address _account, uint256 _amount) external override virtual nonReentrant {
        _validateHandler();
        _stakeGs(msg.sender, _account, gs, _amount);
    }

    /// @inheritdoc IStakingRouter
    function stakeGs(uint256 _amount) external override virtual nonReentrant {
        _stakeGs(msg.sender, msg.sender, gs, _amount);
    }

    /// @inheritdoc IStakingRouter
    function stakeEsGs(uint256 _amount) external override virtual nonReentrant {
        _stakeGs(msg.sender, msg.sender, esGs, _amount);
    }

    /// @inheritdoc IStakingRouter
    function stakeEsGsb(uint256 _amount) external override virtual nonReentrant {
        _stakeGs(msg.sender, msg.sender, esGsb, _amount);
    }

    /// @inheritdoc IStakingRouter
    function stakeLpForAccount(address _account, address _gsPool, address _esToken, uint256 _amount) external override virtual nonReentrant {
        _validateHandler();
        _stakeLp(address(this), _account, _gsPool, _esToken, _amount);
    }

    /// @inheritdoc IStakingRouter
    function stakeLp(address _gsPool, address _esToken, uint256 _amount) external override virtual nonReentrant {
        _stakeLp(msg.sender, msg.sender, _gsPool, _esToken, _amount);
    }

    /// @inheritdoc IStakingRouter
    function stakeLoanForAccount(address _account, address _gsPool, uint256 _loanId) external override virtual nonReentrant {
        _validateHandler();
        _stakeLoan(_account, _gsPool, _loanId);
    }

    /// @inheritdoc IStakingRouter
    function stakeLoan(address _gsPool, uint256 _loanId) external override virtual nonReentrant {
        _stakeLoan(msg.sender, _gsPool, _loanId);
    }

    /// @inheritdoc IStakingRouter
    function unstakeGs(uint256 _amount) external override virtual nonReentrant {
        _unstakeGs(msg.sender, gs, _amount, true);
    }

    /// @inheritdoc IStakingRouter
    function unstakeEsGs(uint256 _amount) external override virtual nonReentrant {
        _unstakeGs(msg.sender, esGs, _amount, true);
    }

    /// @inheritdoc IStakingRouter
    function unstakeEsGsb(uint256 _amount) external override virtual nonReentrant {
        _unstakeGs(msg.sender, esGsb, _amount, true);
    }

    /// @inheritdoc IStakingRouter
    function unstakeLpForAccount(address _account, address _gsPool, address _esToken, uint256 _amount) external override virtual nonReentrant {
        _validateHandler();
        _unstakeLp(_account, _gsPool, _esToken, _amount);
    }

    /// @inheritdoc IStakingRouter
    function unstakeLp(address _gsPool, address _esToken, uint256 _amount) external override virtual nonReentrant {
        _unstakeLp(msg.sender, _gsPool, _esToken, _amount);
    }

    /// @inheritdoc IStakingRouter
    function unstakeLoanForAccount(address _account, address _gsPool, uint256 _loanId) external override virtual nonReentrant {
        _validateHandler();
        _unstakeLoan(_account, _gsPool, _loanId);
    }

    /// @inheritdoc IStakingRouter
    function unstakeLoan(address _gsPool, uint256 _loanId) external override virtual nonReentrant {
        _unstakeLoan(msg.sender, _gsPool, _loanId);
    }

    /// @inheritdoc IStakingRouter
    function vestEsGs(uint256 _amount) external override virtual nonReentrant {
        IVester(_coreTracker.vester).depositForAccount(msg.sender, _amount);
    }

    /// @inheritdoc IStakingRouter
    function vestEsTokenForPool(address _gsPool, address _esToken, uint256 _amount) external override virtual nonReentrant {
        address _vester = _poolTrackers[_gsPool][_esToken].vester;
        require(_vester != address(0), "StakingRouter: pool vester not found");

        IVester(_vester).depositForAccount(msg.sender, _amount);
    }

    /// @inheritdoc IStakingRouter
    function vestEsGsb(uint256 _amount) external override virtual nonReentrant {
        IVester(_coreTracker.loanVester).depositForAccount(msg.sender, _amount);
    }

    /// @inheritdoc IStakingRouter
    function withdrawEsGs() external override virtual nonReentrant {
        IVester(_coreTracker.vester).withdrawForAccount(msg.sender);
    }

    /// @inheritdoc IStakingRouter
    function withdrawEsTokenForPool(address _gsPool, address _esToken) external override virtual nonReentrant {
        address _vester = _poolTrackers[_gsPool][_esToken].vester;
        require(_vester != address(0), "StakingRouter: pool vester not found");

        IVester(_vester).withdrawForAccount(msg.sender);
    }

    /// @inheritdoc IStakingRouter
    function withdrawEsGsb() external override virtual nonReentrant {
        IVester(_coreTracker.loanVester).withdrawForAccount(msg.sender);
    }

    /// @inheritdoc IStakingRouter
    function claim(bool _shouldClaimRewards, bool _shouldClaimFee, bool _shouldClaimVesting) external override virtual nonReentrant {
        address account = msg.sender;

        if (_shouldClaimRewards) {
            IRewardTracker(_coreTracker.rewardTracker).claimForAccount(account, account);
        }
        if (_shouldClaimFee) {
            IRewardTracker(_coreTracker.feeTracker).claimForAccount(account, account);
        }
        if (_shouldClaimVesting) {
            IVester(_coreTracker.vester).claimForAccount(account, account);
        }

        // Loan Staking rewards
        if (_coreTracker.loanRewardTracker != address(0)) {
            IRewardTracker(_coreTracker.loanRewardTracker).claimForAccount(account, account);
        }
        if (_coreTracker.loanVester != address(0)) {
            IVester(_coreTracker.loanVester).claimForAccount(account, account);
        }
    }

    /// @inheritdoc IStakingRouter
    function claimPool(address _gsPool, address _esToken, bool _shouldClaimRewards, bool _shouldClaimVesting) external override virtual nonReentrant {
        address account = msg.sender;

        if (_shouldClaimRewards) {
            address _rewardTracker = _poolTrackers[_gsPool][_esToken].rewardTracker;
            require(_rewardTracker != address(0), "StakingRouter: pool tracker not found");
            IRewardTracker(_rewardTracker).claimForAccount(account, account);
        }
        if (_shouldClaimVesting) {
            address _vester = _poolTrackers[_gsPool][_esToken].vester;
            require(_vester != address(0), "StakingRouter: pool vester not found");
            IVester(_vester).claimForAccount(account, account);
        }

        // Loan Staking rewards
        if (_poolTrackers[_gsPool][esGsb].loanRewardTracker != address(0)) {
            ILoanTracker(_poolTrackers[_gsPool][esGsb].loanRewardTracker).claimForAccount(account, account);
        }
    }

    /// @inheritdoc IStakingRouter
    function compound() external override virtual nonReentrant {
        _compound(msg.sender);
    }

    /// @inheritdoc IStakingRouter
    function compoundForAccount(address _account) external override virtual nonReentrant {
        _validateHandler();
        _compound(_account);
    }

    /// @inheritdoc IStakingRouter
    function getAverageStakedAmount(address _gsPool, address _esToken, address _account) public override virtual view returns (uint256) {
        address vester = _gsPool == address(0) ? _coreTracker.vester : _poolTrackers[_gsPool][_esToken].vester;
        require(vester != address(0), "Vester contract not found");

        return IVester(vester).getAverageStakedAmount(_account);
    }

    function _validateHandler() private view {
        address user = msg.sender;
        require(owner() == user || manager == user, "StakingRouter: forbidden");
    }

    /// @dev Stake GS/esGS/esGSb
    /// @param _fundingAccount Funding account to move tokens from
    /// @param _account Account to stake tokens for
    /// @param _token Staking token address
    /// @param _amount Staking amount
    function _stakeGs(address _fundingAccount, address _account, address _token, uint256 _amount) private {
        require(_amount > 0, "StakingRouter: invalid amount");

        address rewardTracker = _coreTracker.rewardTracker;
        address bonusTracker = _coreTracker.bonusTracker;
        address feeTracker = _coreTracker.feeTracker;

        IRewardTracker(rewardTracker).stakeForAccount(_fundingAccount, _account, _token, _amount);
        IRewardTracker(bonusTracker).stakeForAccount(_account, _account, rewardTracker, _amount);
        IRewardTracker(feeTracker).stakeForAccount(_account, _account, bonusTracker, _amount);

        emit StakedGs(_account, _token, _amount);
    }

    /// @dev Deposit GS_LP tokens
    /// @param _fundingAccount Funding account to move tokens from
    /// @param _account Account to stake tokens for
    /// @param _gsPool GammaPool address
    /// @param _esToken Escrow token address
    /// @param _amount Staking amount
    function _stakeLp(address _fundingAccount, address _account, address _gsPool, address _esToken, uint256 _amount) private {
        require(_amount > 0, "StakingRouter: invalid amount");

        address _rewardTracker = _poolTrackers[_gsPool][_esToken].rewardTracker;
        require(_rewardTracker != address(0), "StakingRouter: pool tracker not found");

        IRewardTracker(_rewardTracker).stakeForAccount(_fundingAccount, _account, _gsPool, _amount);

        emit StakedLp(_account, _gsPool, _amount);
    }

    /// @dev Stake loan
    /// @param _account Owner of the loan
    /// @param _gsPool GammaPool address
    /// @param _loanId Loan Id
    function _stakeLoan(address _account, address _gsPool, uint256 _loanId) private {
        address _loanRewardTracker = _poolTrackers[_gsPool][esGsb].loanRewardTracker;
        require(_loanRewardTracker != address(0), "StakingRouter: pool loan tracker not found");

        ILoanTracker(_loanRewardTracker).stakeForAccount(_account, _loanId);

        emit StakedLoan(_account, _gsPool, _loanId);
    }

    /// @dev Unstake GS/esGS/esGSb
    /// @param _account Account to unstake from
    /// @param _token Staking token address
    /// @param _amount Amount to unstake
    /// @param _shouldReduceBnGs True if MP tokens should be burned (default true)
    function _unstakeGs(address _account, address _token, uint256 _amount, bool _shouldReduceBnGs) private {
        require(_amount > 0, "StakingRouter: invalid amount");

        address rewardTracker = _coreTracker.rewardTracker;
        address bonusTracker = _coreTracker.bonusTracker;
        address feeTracker = _coreTracker.feeTracker;

        uint256 balance = IRewardTracker(rewardTracker).stakedAmounts(_account);

        IRewardTracker(feeTracker).unstakeForAccount(_account, bonusTracker, _amount, _account);
        IRewardTracker(bonusTracker).unstakeForAccount(_account, rewardTracker, _amount, _account);
        IRewardTracker(rewardTracker).unstakeForAccount(_account, _token, _amount, _account);

        if (_shouldReduceBnGs) {
            uint256 bnGsAmount = IRewardTracker(bonusTracker).claimForAccount(_account, _account);
            if (bnGsAmount > 0) {
                IRewardTracker(feeTracker).stakeForAccount(_account, _account, bnGs, bnGsAmount);
            }

            uint256 stakedBnGs = IRewardTracker(feeTracker).depositBalances(_account, bnGs);
            if (stakedBnGs > 0) {
                uint256 reductionAmount = stakedBnGs * _amount / balance;
                IRewardTracker(feeTracker).unstakeForAccount(_account, bnGs, reductionAmount, _account);
                IRestrictedToken(bnGs).burn(_account, reductionAmount);
            }
        }

        emit UnstakedGs(_account, _token, _amount);
    }

    /// @dev Unstake GS_LP tokens
    /// @param _account Account to unstake from
    /// @param _gsPool GammaPool address
    /// @param _esToken Escrow token address
    /// @param _amount Amount to unstake
    function _unstakeLp(address _account, address _gsPool, address _esToken, uint256 _amount) private {
        require(_amount > 0, "StakingRouter: invalid amount");

        address _rewardTracker = _poolTrackers[_gsPool][_esToken].rewardTracker;
        require(_rewardTracker != address(0), "StakingRouter: pool tracker not found");

        IRewardTracker(_rewardTracker).unstakeForAccount(_account, _gsPool, _amount, _account);

        emit UnstakedLp(_account, _gsPool, _amount);
    }

    /// @dev Unstake loan
    /// @param _account Owner of the loan
    /// @param _gsPool GammaPool
    /// @param _loanId Loan Id
    function _unstakeLoan(address _account, address _gsPool, uint256 _loanId) private {
        address _loanRewardTracker = _poolTrackers[_gsPool][esGsb].loanRewardTracker;
        require(_loanRewardTracker != address(0), "StakingRouter: pool loan tracker not found");

        ILoanTracker(_loanRewardTracker).unstakeForAccount(_account, _loanId);

        emit UnstakedLoan(_account, _gsPool, _loanId);
    }

    /// @dev Compound and restake tokens
    /// @param _account User account to compound for
    function _compound(address _account) private {
        uint256 esGsAmount = IRewardTracker(_coreTracker.rewardTracker).claimForAccount(_account, _account);
        if (esGsAmount > 0) {
            _stakeGs(_account, _account, esGs, esGsAmount);
        }

        if (_coreTracker.loanRewardTracker != address(0)) {
            uint256 esGsbAmount = IRewardTracker(_coreTracker.loanRewardTracker).claimForAccount(_account, _account);
            if (esGsbAmount > 0) {
                _stakeGs(_account, _account, esGsb, esGsbAmount);
            }
        }

        uint256 bnGsAmount = IRewardTracker(_coreTracker.bonusTracker).claimForAccount(_account, _account);
        if (bnGsAmount > 0) {
            IRewardTracker(_coreTracker.feeTracker).stakeForAccount(_account, _account, bnGs, bnGsAmount);
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.3) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.9._
 */
interface IERC1967 {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.3) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/IERC1967.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade is IERC1967 {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts (last updated v4.8.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}