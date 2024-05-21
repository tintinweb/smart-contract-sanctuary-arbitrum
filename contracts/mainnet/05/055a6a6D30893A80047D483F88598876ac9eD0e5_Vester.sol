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
pragma solidity 0.8.21;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./interfaces/IRestrictedToken.sol";
import "./interfaces/IRewardTracker.sol";
import "./interfaces/IVester.sol";

/// @title Vester contract
/// @author Simon Mall
/// @notice Vest esGS tokens to claim GS tokens
/// @notice Vesting is done linearly over an year
/// @dev Requires averaged amount of pair tokens to be reserved
contract Vester is ReentrancyGuard, Ownable2Step, Initializable, IVester {
    using SafeERC20 for IERC20;

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    uint256 public override vestingDuration;

    address public override pairToken;
    address public override esToken;
    address public override claimableToken;

    address public override rewardTracker;

    uint256 public override totalSupply;
    uint256 public override pairSupply;
    uint256 public override totalClaimable;

    bool public override hasMaxVestableAmount;

    mapping (address => uint256) public balances;
    mapping (address => uint256) public override pairAmounts;
    mapping (address => uint256) public override cumulativeClaimAmounts;
    mapping (address => uint256) public override claimedAmounts;
    mapping (address => uint256) public override lastVestingTimes;

    mapping (address => uint256) public override cumulativeRewardDeductions;
    mapping (address => uint256) public override bonusRewards;

    mapping (address => bool) public isHandler;

    event Claim(address receiver, uint256 amount);
    event Deposit(address account, uint256 amount);
    event Withdraw(address account, uint256 claimedAmount, uint256 balance);
    event PairTransfer(address indexed from, address indexed to, uint256 value);

    constructor (){
    }

    /// @inheritdoc IVester
    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _vestingDuration,
        address _esToken,
        address _pairToken,
        address _claimableToken,
        address _rewardTracker) external override virtual initializer {
        _transferOwnership(msg.sender);
        name = _name;
        symbol = _symbol;

        vestingDuration = _vestingDuration;

        esToken = _esToken;
        pairToken = _pairToken;
        claimableToken = _claimableToken;

        rewardTracker = _rewardTracker;

        if (rewardTracker != address(0)) {
            hasMaxVestableAmount = true;
        }
    }

    /// @inheritdoc IVester
    function setHandler(address _handler, bool _isActive) external override virtual onlyOwner {
        isHandler[_handler] = _isActive;
    }

    /// @inheritdoc IVester
    function withdrawToken(address _token, address _recipient, uint256 _amount) external override virtual onlyOwner {
        if (_token == address(0)) {
            payable(_recipient).transfer(_amount);
        } else {
            uint256 maxAmount = maxWithdrawableAmount();
            _amount = _amount == 0 || _amount > maxAmount ? maxAmount : _amount;
            if (_amount > 0) {
                IERC20(_token).safeTransfer(_recipient, _amount);
            }
        }
    }

    /// @inheritdoc IVester
    function maxWithdrawableAmount() public override virtual view returns (uint256) {
        uint256 rewardsSupply = IERC20(claimableToken).balanceOf(address(this));
        uint256 rewardsRequired = totalSupply + totalClaimable;

        require(rewardsSupply >= rewardsRequired, "Vester: Insufficient funds");

        return rewardsSupply - rewardsRequired;
    }

    /// @dev Restrict max cap of vestable token amounts
    /// @param _hasMaxVestableAmount True if applied
    function setHasMaxVestableAmount(bool _hasMaxVestableAmount) external onlyOwner {
        hasMaxVestableAmount = _hasMaxVestableAmount;
    }

    /// @inheritdoc IVester
    function deposit(uint256 _amount) external override virtual nonReentrant {
        _deposit(msg.sender, _amount);
    }

    /// @inheritdoc IVester
    function depositForAccount(address _account, uint256 _amount) external override virtual nonReentrant {
        _validateHandler();
        _deposit(_account, _amount);
    }

    /// @inheritdoc IVester
    function claim() external override virtual nonReentrant returns (uint256) {
        return _claim(msg.sender, msg.sender);
    }

    /// @inheritdoc IVester
    function claimForAccount(address _account, address _receiver) external override virtual nonReentrant returns (uint256) {
        _validateHandler();
        return _claim(_account, _receiver);
    }

    /// @inheritdoc IVester
    function withdraw() external override virtual nonReentrant {
        _withdraw(msg.sender);
    }

    /// @inheritdoc IVester
    function withdrawForAccount(address _account) external override virtual nonReentrant {
        _validateHandler();
        _withdraw(_account);
    }

    /// @inheritdoc IVester
    function setCumulativeRewardDeductions(address _account, uint256 _amount) external override virtual nonReentrant {
        _validateHandler();
        cumulativeRewardDeductions[_account] = _amount;
    }

    /// @inheritdoc IVester
    function setBonusRewards(address _account, uint256 _amount) external override virtual nonReentrant {
        _validateHandler();
        bonusRewards[_account] = _amount;
    }

    /// @inheritdoc IVester
    function claimable(address _account) public override virtual view returns (uint256) {
        uint256 amount = cumulativeClaimAmounts[_account] - claimedAmounts[_account];
        uint256 nextClaimable = _getNextClaimableAmount(_account);

        return amount + nextClaimable;
    }

    /// @inheritdoc IVester
    function getMaxVestableAmount(address _account) public override virtual view returns (uint256) {
        if (!hasRewardTracker()) { return 0; }

        uint256 bonusReward = bonusRewards[_account];
        uint256 cumulativeReward = IRewardTracker(rewardTracker).cumulativeRewards(_account);
        uint256 maxVestableAmount = cumulativeReward + bonusReward;

        uint256 cumulativeRewardDeduction = cumulativeRewardDeductions[_account];

        if (maxVestableAmount < cumulativeRewardDeduction) {
            return 0;
        }

        return maxVestableAmount - cumulativeRewardDeduction;
    }

    /// @inheritdoc IVester
    function getAverageStakedAmount(address _account) public override virtual view returns (uint256) {
        uint256 cumulativeReward = IRewardTracker(rewardTracker).cumulativeRewards(_account);
        if (cumulativeReward == 0) { return 0; }

        return IRewardTracker(rewardTracker).averageStakedAmounts(_account);
    }

    /// @inheritdoc IVester
    function getPairAmount(address _account, uint256 _esAmount) public override virtual view returns (uint256) {
        if (!hasRewardTracker()) { return 0; }

        uint256 averageStakedAmount = getAverageStakedAmount(_account);
        if (averageStakedAmount == 0) {
            return 0;
        }

        uint256 maxVestableAmount = getMaxVestableAmount(_account);
        if (maxVestableAmount == 0) {
            return 0;
        }

        return _esAmount * averageStakedAmount / maxVestableAmount;
    }

    /// @dev Returns if reward tracker is set
    function hasRewardTracker() public view returns (bool) {
        return rewardTracker != address(0);
    }

    /// @dev Returns if pair token is set
    function hasPairToken() public view returns (bool) {
        return pairToken != address(0);
    }

    /// @inheritdoc IVester
    function getTotalVested(address _account) public override virtual view returns (uint256) {
        return balances[_account] + cumulativeClaimAmounts[_account];
    }

    /// @inheritdoc IERC20
    function balanceOf(address _account) public override virtual view returns (uint256) {
        return balances[_account];
    }

    /// @inheritdoc IERC20
    // empty implementation, tokens are non-transferrable
    function transfer(address /* recipient */, uint256 /* amount */) public override virtual returns (bool) {
        revert("Vester: non-transferrable");
    }

    /// @inheritdoc IERC20
    // empty implementation, tokens are non-transferrable
    function allowance(address /* owner */, address /* spender */) public override virtual view returns (uint256) {
        return 0;
    }

    /// @inheritdoc IERC20
    // empty implementation, tokens are non-transferrable
    function approve(address /* spender */, uint256 /* amount */) public override virtual returns (bool) {
        revert("Vester: non-transferrable");
    }

    /// @inheritdoc IERC20
    // empty implementation, tokens are non-transferrable
    function transferFrom(address /* sender */, address /* recipient */, uint256 /* amount */) public override virtual returns (bool) {
        revert("Vester: non-transferrable");
    }

    /// @inheritdoc IVester
    function getVestedAmount(address _account) public override virtual view returns (uint256) {
        uint256 balance = balances[_account];
        uint256 cumulativeClaimAmount = cumulativeClaimAmounts[_account];

        return balance + cumulativeClaimAmount;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public override virtual pure returns (bool) {
        return interfaceId == type(IVester).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    function _validateHandler() private view {
        require(isHandler[msg.sender], "Vester: forbidden");
    }

    function _mint(address _account, uint256 _amount) private {
        require(_account != address(0), "Vester: mint to the zero address");

        totalSupply = totalSupply + _amount;
        balances[_account] = balances[_account] + _amount;

        emit Transfer(address(0), _account, _amount);
    }

    function _mintPair(address _account, uint256 _amount) private {
        require(_account != address(0), "Vester: mint to the zero address");

        pairSupply = pairSupply + _amount;
        pairAmounts[_account] = pairAmounts[_account] + _amount;

        emit PairTransfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _amount) private {
        require(_account != address(0), "Vester: burn from the zero address");

        balances[_account] = balances[_account] - _amount;
        totalSupply = totalSupply - _amount;

        emit Transfer(_account, address(0), _amount);
    }

    function _burnPair(address _account, uint256 _amount) private {
        require(_account != address(0), "Vester: burn from the zero address");

        pairAmounts[_account] = pairAmounts[_account] - _amount;
        pairSupply = pairSupply - _amount;

        emit PairTransfer(_account, address(0), _amount);
    }

    function _deposit(address _account, uint256 _amount) private {
        require(_amount > 0, "Vester: invalid _amount");

        _updateVesting(_account);

        IERC20(esToken).safeTransferFrom(_account, address(this), _amount);

        _mint(_account, _amount);

        if (hasPairToken()) {
            uint256 pairAmount = pairAmounts[_account];
            uint256 nextPairAmount = getPairAmount(_account, balances[_account]);
            if (nextPairAmount > pairAmount) {
                uint256 pairAmountDiff = nextPairAmount - pairAmount;
                IERC20(pairToken).safeTransferFrom(_account, address(this), pairAmountDiff);
                _mintPair(_account, pairAmountDiff);
            }
        }

        if (hasMaxVestableAmount) {
            uint256 maxAmount = getMaxVestableAmount(_account);
            require(getTotalVested(_account) <= maxAmount, "Vester: max vestable amount exceeded");
        }

        emit Deposit(_account, _amount);
    }

    /// @dev Returns claimable GS amount
    /// @param _account Vesting account
    function _getNextClaimableAmount(address _account) private view returns (uint256) {
        uint256 timeDiff = block.timestamp - lastVestingTimes[_account];

        uint256 balance = balances[_account];
        if (balance == 0) { return 0; }

        uint256 vestedAmount = getVestedAmount(_account);
        uint256 claimableAmount = vestedAmount * timeDiff / vestingDuration;

        if (claimableAmount < balance) {
            return claimableAmount;
        }

        return balance;
    }

    /// @dev Claim pending GS tokens
    /// @param _account Vesting account
    /// @param _receiver Receiver of rewards
    function _claim(address _account, address _receiver) private returns (uint256) {
        _updateVesting(_account);

        uint256 amount = claimable(_account);
        unchecked {
            claimedAmounts[_account] = claimedAmounts[_account] + amount;
            totalClaimable -= amount;
        }
        IERC20(claimableToken).safeTransfer(_receiver, amount);

        emit Claim(_account, amount);

        return amount;
    }

    /// @dev Withdraw esGS tokens and cancel vesting
    /// @param _account Vesting account
    function _withdraw(address _account) private {
        _claim(_account, _account);

        uint256 claimedAmount = cumulativeClaimAmounts[_account];
        uint256 balance = balances[_account];
        uint256 totalVested = balance + claimedAmount;
        require(totalVested > 0, "Vester: vested amount is zero");

        if (hasPairToken()) {
            uint256 pairAmount = pairAmounts[_account];
            _burnPair(_account, pairAmount);
            IERC20(pairToken).safeTransfer(_account, pairAmount);
        }

        IERC20(esToken).safeTransfer(_account, balance);
        _burn(_account, balance);

        delete cumulativeClaimAmounts[_account];
        delete claimedAmounts[_account];
        delete lastVestingTimes[_account];

        emit Withdraw(_account, claimedAmount, balance);
    }

    /// @dev Update vesting params for user
    /// @param _account Vesting account
    function _updateVesting(address _account) private {
        uint256 amount = _getNextClaimableAmount(_account);
        lastVestingTimes[_account] = block.timestamp;

        if (amount == 0) {
            return;
        }

        // transfer claimableAmount from balances to cumulativeClaimAmounts
        _burn(_account, amount);
        unchecked {
            cumulativeClaimAmounts[_account] = cumulativeClaimAmounts[_account] + amount;
            totalClaimable += amount;
        }

        IRestrictedToken(esToken).burn(address(this), amount);
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
interface IERC20Permit {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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