// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./libraries/math/SafeMath.sol";
import "./libraries/token/IERC20Metadata.sol";
import "./libraries/token/IERC20.sol";
import "./tokens/interfaces/IMintable.sol";
import "./libraries/token/SafeERC20.sol";
import "./libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IRewardDistributor.sol";
import "./interfaces/IUtpRewardTracker.sol";
import "./interfaces/IDeflationManager.sol";
import "./libraries/access/Governable.sol";
import "./libraries/FullMath.sol";


contract UtpRewardTracker is IERC20, ReentrancyGuard, IUtpRewardTracker, Governable {
    using SafeMath for uint256;
    using FullMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant DUST = 100; 
    uint256 public constant PRECISION = 1e10;       // precision of deflation ratio
    uint256 public constant RP_PRECISION = 1e46;    // precision of perToken rewards

    uint256 public constant MAX_CDR = 1e46;         // max cumulative deflationary ratio

    string public name;
    string public symbol;
    uint8 public decimals = 6;
    
    address public deflationManager;                // deflation manager address
    bool public isInitialized;
    address public stakeToken;                      // deposit token address
    address[] public distributors;                  // reward distributors

    uint256 public override totalSupply;            // total proof token amount
    uint256 private _totalStaked;                   // total available staked amount after deflation
    mapping (address => uint256) public balances;   // stake proof of account
    mapping (address => mapping (address => uint256)) public allowances;

    uint256 public deflationRatioPerSecond;                  // deflation Ratio Per Second;
    uint256 public cumulativeDeflationaryRatio = PRECISION;  // initial deflation ratio
    mapping (address => uint256) public previousCumulatedDeflationRatio;    // user => last recorded cumulated deflation ratio
    mapping (address => uint256) private stakedAmounts;      // user => available amount after deflation
    mapping(address => mapping(address => uint256)) public claimableReward; // user => reward token => claimable rewards

    mapping(address => uint256) cumulativeRewardPerToken;    // reward token => available rewards base per staked
    mapping(address => mapping(address => uint256)) public previousCumulatedRewardPerToken; // user => reward token => available rewards base per staked

    mapping (address => mapping(address => uint256)) public override cumulativeRewards;     // user => reward token => cumulative gained rewards, used for vest
    mapping (address => mapping(address => uint256)) public override averageStakedAmounts;  // user => reward token => average Staked Amounts, used for vest

    bool public inPrivateTransferMode;
    bool public inPrivateStakingMode;
    bool public inPrivateClaimingMode;
    mapping (address => bool) public isHandler; 

    uint256 public lastUpdateTime;

    event Claimed(address rewardToken, address receiver, uint256 amount);
    event AddDistributor(address distributor);
    event SetDeflationRatioPerSecond(uint256 deflationRatioPerSecond);
    event SetInPrivateTransferMode(bool inPrivateTransferMode);
    event SetInPrivateStakingMode(bool inPrivateStakingMode);
    event SetInPrivateClaimingMode(bool inPrivateClaimingMode);
    event SetPriceFeed(address priceFeed);
    event SetHandler(address handler, bool isActive);

    constructor(string memory _name, string memory _symbol) public {
        name = _name;
        symbol = _symbol;
    }

    function initialize(
        address _stakeToken,
        address _deflationManager,
        address[] memory _distributors,
        uint256 _deflationRatioPerSecond
    ) external onlyGov {
        require(!isInitialized, "UTPRewardTracker: already initialized");
        require(
            _deflationRatioPerSecond < PRECISION
            && _deflationRatioPerSecond > 1,
            "UTPRewardTracker: invalid deflationRatioPerSecond"
        );
        isInitialized = true;

        stakeToken = _stakeToken;
        if (_stakeToken != address(0))
            decimals = IERC20Metadata(_stakeToken).decimals();
        deflationManager = _deflationManager;
        deflationRatioPerSecond = _deflationRatioPerSecond;
        lastUpdateTime = block.timestamp;
        uint256 len = _distributors.length;
        for (uint256 i=0; i<len; i++) {
            distributors.push(_distributors[i]);
        }
    }

    function addDistributor(address _distributor) external onlyGov {
        _updateRewards(address(0));
        distributors.push(_distributor);
        emit AddDistributor(_distributor);
    }

    function getDistributor() external view returns(address[] memory) {
        uint256 len = distributors.length;
        address[] memory _distributors = new address[](len);
        for(uint256 i=0; i<len; i++) {
            _distributors[i] = distributors[i];
        }
        return _distributors;
    }

    function totalStaked() public view returns(uint256) {
        uint256 cDfRt = cumulativeDeflationaryRatio;
        uint256 deflationaryRatio = _calculateDeflationRatio();
        return _totalStaked.mulDivRoundingUp(cDfRt, deflationaryRatio);
    }

    function setDeflationRatioPerSecond(uint256 _deflationRatioPerSecond) external onlyGov {
        require(
            _deflationRatioPerSecond < PRECISION &&
            _deflationRatioPerSecond > 1,
            "UTPRewardTracker: invalid deflationRatioPerSecond"
        );
        _updateRewards(address(0));
        deflationRatioPerSecond = _deflationRatioPerSecond;
        emit SetDeflationRatioPerSecond(_deflationRatioPerSecond);
    }

    function setInPrivateTransferMode(bool _inPrivateTransferMode) external onlyGov {
        inPrivateTransferMode = _inPrivateTransferMode;
        emit SetInPrivateTransferMode(_inPrivateTransferMode);
    }

    function setInPrivateStakingMode(bool _inPrivateStakingMode) external onlyGov {
        inPrivateStakingMode = _inPrivateStakingMode;
        emit SetInPrivateStakingMode(_inPrivateStakingMode);
    }

    function setInPrivateClaimingMode(bool _inPrivateClaimingMode) external onlyGov {
        inPrivateClaimingMode = _inPrivateClaimingMode;
        emit SetInPrivateClaimingMode(_inPrivateClaimingMode);
    }

    function setHandler(address _handler, bool _isActive) external onlyGov {
        isHandler[_handler] = _isActive;
        emit SetHandler(_handler, _isActive);
    }

    function withdrawToken(address _token, address _account, uint256 _amount) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function balanceOf(address _account) public view override returns (uint256) {
        return balances[_account];
    }

    /// @notice get available staked amount by deflation impact
    /// @param _account, account address
    function getStakedAmounts(address _account) public view override returns (uint256) {
        uint256 pdr = previousCumulatedDeflationRatio[_account];
        if (pdr == 0) pdr = PRECISION;
        return stakedAmounts[_account].mulDiv(pdr, _calculateDeflationRatio());
    }

    /// @notice stake for reward
    function stake(address /** _depositToken */, uint256 _amount) external override nonReentrant {
        if (inPrivateStakingMode) { revert("UTPRewardTracker: action not enabled"); }
        _stake(msg.sender, msg.sender, _amount);
    }

    /// @notice stake for reward for other account
    function stakeForAccount(address _fundingAccount, address _account, address /** _depositToken */, uint256 _amount) external override nonReentrant {
        _validateHandler();
        _stake(_fundingAccount, _account, _amount);
    }

    /// @notice withdraw staked token
    function unstake(address /** _depositToken */, uint256 _amount) external override nonReentrant returns(uint256){
        if (inPrivateStakingMode) { revert("UTPRewardTracker: action not enabled"); }
        return _unstake(msg.sender, _amount, msg.sender);
    }

    function unstakeForAccount(address _account, address /** _depositToken */, uint256 _amount, address _receiver) external override nonReentrant returns(uint256){
        _validateHandler();
        return _unstake(_account, _amount, _receiver);
    }

    function transfer(address _recipient, uint256 _amount) external override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) external view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) external override returns (bool) {
        if (isHandler[msg.sender]) {
            _transfer(_sender, _recipient, _amount);
            return true;
        }

        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "UTPRewardTracker: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    /// @notice get reward speed from the distributor
    function tokensPerInterval(address distributor) external override view returns (uint256) {
        return IRewardDistributor(distributor).tokensPerInterval();
    }

    /// @notice update reward global information
    function updateRewards() external override nonReentrant {
        _updateRewards(address(0));
    }

    /// @notice claim all rewards
    /// @notice _receiver, receive address
    function claim(address _receiver) external override nonReentrant returns (uint256[] memory) {
        if (inPrivateClaimingMode) { revert("UTPRewardTracker: action not enabled"); }
        _updateRewards(msg.sender);
        uint256 len = distributors.length;
        uint256[] memory amounts = new uint256[](len);
        for (uint256 i=0; i<len; i++) {
            amounts[i] = _claim(getRewardToken(distributors[i]), msg.sender, _receiver);
        }
        return amounts;
    }

    function claimForAccount(address _account, address _receiver) external override nonReentrant returns (address[] memory rewards, uint256[] memory amounts) {
        _validateHandler();
        _updateRewards(_account);
        uint256 len = distributors.length;
        rewards = new address[](len);
        amounts = new uint256[](len);
        
        for (uint256 i=0; i<len; i++) {
            rewards[i] = getRewardToken(distributors[i]);
            amounts[i] = _claim(rewards[i], _account, _receiver);
        }
    }

    function claimReward(address _rewardToken, address _receiver) external override nonReentrant returns (uint256) {
        if (inPrivateClaimingMode) { revert("UTPRewardTracker: action not enabled"); }
        _updateRewards(msg.sender);
        return _claim(_rewardToken, msg.sender, _receiver);
    }

    function claimRewardForAccount(address _rewardToken, address _account, address _receiver) external override nonReentrant returns (uint256) {
        _validateHandler();
        _updateRewards(_account);
        return _claim(_rewardToken, _account, _receiver);
    }

    struct ClaimTmp {
        uint256 stakedAmount;
        uint256 len;
        uint256 deflationaryRatio;
        uint256 supply;
        address rewardToken;
        uint256 blockReward;
        uint256 nextCumulativeRewardPerToken;
        uint256 cumulativeRewards;
        uint256 nextCumulativeReward;
        uint256 averageStakedAmounts;
    }

    /// @notice calculate all claimable reward by reward tokens
    /// @param _account, account address
    function claimable(address _account) public override view returns (address[] memory, uint256[] memory) {
        ClaimTmp memory tmp;
        tmp.stakedAmount = stakedAmounts[_account];
        tmp.len = distributors.length;
        uint256[] memory amounts = new uint256[](tmp.len);
        address[] memory rewards = new address[](tmp.len);
        for(uint256 i=0; i<tmp.len; i++) {
            rewards[i] = getRewardToken(distributors[i]);  
            amounts[i] = claimableReward[_account][rewards[i]]; 
        }
        if (tmp.stakedAmount < DUST) {
            return (rewards, amounts);
        }
        tmp.supply = _totalStaked;
        if (tmp.supply > DUST) {
            tmp.deflationaryRatio = _calculateDeflationRatio();
            if (tmp.deflationaryRatio > MAX_CDR) {
                tmp.deflationaryRatio = MAX_CDR;
            }

            tmp.supply = tmp.supply.mulDivRoundingUp(cumulativeDeflationaryRatio, tmp.deflationaryRatio);
        }else {
            tmp.supply = 0;
        }
        
        for(uint256 i=0; i<tmp.len; i++) {
            tmp.rewardToken = rewards[i];
            tmp.blockReward = IRewardDistributor(distributors[i]).pendingRewards(tmp.supply);
            tmp.nextCumulativeRewardPerToken = cumulativeRewardPerToken[tmp.rewardToken];
            if (tmp.supply > DUST) {
                tmp.nextCumulativeRewardPerToken = tmp.nextCumulativeRewardPerToken.add(
                    tmp.blockReward.mul(RP_PRECISION).div(tmp.supply).div(tmp.deflationaryRatio)
                );
            }

            amounts[i] = amounts[i].add(
                tmp.stakedAmount.mul(previousCumulatedDeflationRatio[_account]).mulDiv(
                    tmp.nextCumulativeRewardPerToken.sub(previousCumulatedRewardPerToken[_account][tmp.rewardToken]),
                    RP_PRECISION
                )
            );
        }
        return (rewards, amounts);
    }

    /// @notice get reward token address from distributor
    function getRewardToken(address _distributor) public view returns (address) {
        return IRewardDistributor(_distributor).rewardToken();
    }

    function _claim(address _rewardToken, address _account, address _receiver) private returns (uint256) {
        uint256 tokenAmount = claimableReward[_account][_rewardToken];
        claimableReward[_account][_rewardToken] = 0;

        if (tokenAmount > 0) {
            IERC20(_rewardToken).safeTransfer(_receiver, tokenAmount);
            emit Claimed(_rewardToken, _account, tokenAmount);
        }

        return tokenAmount;
    }

    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0), "UTPRewardTracker: mint to the zero address");

        totalSupply = totalSupply.add(_amount);
        balances[_account] = balances[_account].add(_amount);

        emit Transfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _amount) internal {
        require(_account != address(0), "UTPRewardTracker: burn from the zero address");

        balances[_account] = balances[_account].sub(_amount, "UTPRewardTracker: burn amount exceeds balance");
        totalSupply = totalSupply.sub(_amount);

        emit Transfer(_account, address(0), _amount);
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "UTPRewardTracker: transfer from the zero address");
        require(_recipient != address(0), "UTPRewardTracker: transfer to the zero address");

        if (inPrivateTransferMode) { _validateHandler(); }

        balances[_sender] = balances[_sender].sub(_amount, "UTPRewardTracker: transfer amount exceeds balance");
        balances[_recipient] = balances[_recipient].add(_amount);

        emit Transfer(_sender, _recipient,_amount);
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "UTPRewardTracker: approve from the zero address");
        require(_spender != address(0), "UTPRewardTracker: approve to the zero address");

        allowances[_owner][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);
    }

    function _validateHandler() private view {
        require(isHandler[msg.sender], "UTPRewardTracker: forbidden");
    }

    /// @notice stake token for reward
    function _stake(address _fundingAccount, address _account, uint256 _amount) private {
        require(_amount > 0, "UTPRewardTracker: invalid amount");
        require(MAX_CDR > cumulativeDeflationaryRatio, "UTPRewardTracker: stop stake");
        if (stakeToken != address(0))
            IERC20(stakeToken).safeTransferFrom(_fundingAccount, address(this), _amount);
        _updateRewards(_account);
        stakedAmounts[_account] = stakedAmounts[_account].add(_amount);
        _totalStaked = _totalStaked.add(_amount);
        _mint(_account, _amount);
    }

    /// @notice unstake token
    function _unstake(address _account, uint256 _amount, address _receiver) private returns(uint256 amount) {
        _updateRewards(_account);
        uint256 stakedAmount = stakedAmounts[_account];

        if (_amount > stakedAmount) {
            _amount = stakedAmount;
        }        

        uint256 burnAmount = balances[_account].sub(stakedAmounts[_account]);
        stakedAmounts[_account] = stakedAmount.sub(_amount);
        _burn(_account, balances[_account].sub(stakedAmounts[_account]));
        

        if (stakeToken != address(0)) {
            IMintable(stakeToken).burn(address(this), burnAmount);
            IERC20(stakeToken).safeTransfer(_receiver, _amount);
        }
        _totalStaked = _totalStaked.sub(_amount);
        return _amount;
    }

    /// @notice update reward global and account information
    function _updateRewards(address _account) private {
        uint256 cDfRt = cumulativeDeflationaryRatio;
        
        uint256 deflationaryRatio = _calculateDeflationRatio();
        deflationaryRatio = deflationaryRatio > MAX_CDR ? MAX_CDR : deflationaryRatio;
        uint256 len = distributors.length;
        
        _totalStaked = _totalStaked.mulDivRoundingUp(cDfRt, deflationaryRatio);
        for (uint256 i=0; i<len; i++) {
            _updateRewardsForDistributor(_account, distributors[i], deflationaryRatio);
        }

        cumulativeDeflationaryRatio = deflationaryRatio;

        if (_account != address(0)) {
            uint256 pdr = previousCumulatedDeflationRatio[_account];
            if (pdr == 0) pdr = PRECISION;
            stakedAmounts[_account] = stakedAmounts[_account].mulDiv(pdr, deflationaryRatio);
            previousCumulatedDeflationRatio[_account] = deflationaryRatio;
        }

        lastUpdateTime = block.timestamp;
    }

    /// @notice update reward token according to the distributor
    function _updateRewardsForDistributor(
        address _account, 
        address _distributor,
        uint256 deflationaryRatio
    ) private {
        ClaimTmp memory tmp;
        tmp.supply = _totalStaked > DUST ? _totalStaked : 0;
        if (deflationaryRatio < MAX_CDR)
            tmp.blockReward = IRewardDistributor(_distributor).distribute(tmp.supply);
        else 
            tmp.blockReward = 0;
        tmp.rewardToken = getRewardToken(_distributor);

        uint256 _cumulativeRewardPerToken = cumulativeRewardPerToken[tmp.rewardToken];
        if (tmp.supply > 0 && tmp.blockReward > 0) {
            _cumulativeRewardPerToken = _cumulativeRewardPerToken.add(
                tmp.blockReward.mul(RP_PRECISION).div(tmp.supply).div(deflationaryRatio)
            );

            cumulativeRewardPerToken[tmp.rewardToken] = _cumulativeRewardPerToken;
        }

        if (_cumulativeRewardPerToken == 0) {
            return;
        }

        if (_account != address(0)) {
            tmp.stakedAmount = stakedAmounts[_account];
            if (tmp.stakedAmount < DUST) tmp.stakedAmount = 0;
            uint256 pdr = previousCumulatedDeflationRatio[_account];
            if (pdr == 0) pdr = PRECISION;

            uint256 accountReward = tmp.stakedAmount.mul(pdr).mulDiv(
                _cumulativeRewardPerToken.sub(previousCumulatedRewardPerToken[_account][tmp.rewardToken]),
                RP_PRECISION
            );

            uint256 _claimableReward = claimableReward[_account][tmp.rewardToken].add(accountReward);
            claimableReward[_account][tmp.rewardToken] = _claimableReward;

            previousCumulatedRewardPerToken[_account][tmp.rewardToken] = _cumulativeRewardPerToken;
            
            if (accountReward > 0 && tmp.stakedAmount > 0) {
                tmp.cumulativeRewards = IDeflationManager(deflationManager).cumulativeRewards(_account, tmp.rewardToken);
                tmp.nextCumulativeReward = tmp.cumulativeRewards.add(accountReward);
                tmp.averageStakedAmounts = IDeflationManager(deflationManager).averageStakedAmounts(_account, tmp.rewardToken);
                tmp.averageStakedAmounts = tmp.averageStakedAmounts.mul(
                    tmp.cumulativeRewards).div(tmp.nextCumulativeReward
                ).add(balances[_account].mul(accountReward).div(tmp.nextCumulativeReward));

                IDeflationManager(deflationManager).updateStatus(_account, tmp.rewardToken, tmp.nextCumulativeReward, tmp.averageStakedAmounts);
            }
        }
    }

    /// @notice calculate the deflation ratio from last update timestamp to now
    function _calculateDeflationRatio() private view returns(uint256) {
        if (block.timestamp == lastUpdateTime) return cumulativeDeflationaryRatio;
        
        return cumulativeDeflationaryRatio.mulDiv(
            PRECISION.add(deflationRatioPerSecond.mul( block.timestamp.sub(lastUpdateTime) )),
            PRECISION
        );
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

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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

interface IMintable {
    function isMinter(address _account) external returns (bool);
    function setMinter(address _minter, bool _isActive) external;
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
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

pragma solidity 0.6.12;

interface IRewardDistributor {
    function rewardToken() external view returns (address);
    function tokensPerInterval() external view returns (uint256);
    function pendingRewards(uint256 supply) external view returns (uint256);
    function distribute(uint256 supply) external returns (uint256);
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

interface IDeflationManager {

    function cumulativeRewards(address _account, address _depositToken) external returns(uint256);
    function averageStakedAmounts(address _account, address _depositToken) external returns(uint256);

    function updateStatus(
        address _account, 
        address _rewardToken,
        uint256 _cumulativeReward,
        uint256 _averageStakedAmount
    ) external;
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
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