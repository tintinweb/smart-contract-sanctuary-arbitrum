/**
 *Submitted for verification at Arbiscan on 2023-04-07
*/

// Sources flattened with hardhat v2.8.4 https://hardhat.org

// File contracts/commons/interfaces/IOSWAP_PairCreator.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.6.11;

interface IOSWAP_PairCreator {
    function createPair(bytes32 salt) external returns (address);
}


// File contracts/interfaces/IERC20.sol


pragma solidity =0.6.11;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


// File contracts/commons/interfaces/IOSWAP_PausablePair.sol


pragma solidity =0.6.11;

interface IOSWAP_PausablePair {
    function isLive() external view returns (bool);
    function factory() external view returns (address);

    function setLive(bool _isLive) external;
}


// File contracts/oracle/interfaces/IOSWAP_OraclePair.sol


pragma solidity =0.6.11;

interface IOSWAP_OraclePair is IOSWAP_PausablePair {
    struct Offer {
        address provider;
        uint256 staked;
        uint256 amount;
        uint256 reserve;
        uint256 expire;
        bool privateReplenish;
        bool isActive;
        bool enabled;
        uint256 prev;
        uint256 next;
    }

    event NewProvider(address indexed provider, uint256 index);
    event AddLiquidity(address indexed provider, bool indexed direction, uint256 staked, uint256 amount, uint256 newStakeBalance, uint256 newAmountBalance, uint256 expire, bool enable);
    event Replenish(address indexed provider, bool indexed direction, uint256 amountIn, uint256 newAmountBalance, uint256 newReserveBalance, uint256 expire);
    event RemoveLiquidity(address indexed provider, bool indexed direction, uint256 unstake, uint256 amountOut, uint256 reserveOut, uint256 newStakeBalance, uint256 newAmountBalance, uint256 newReserveBalance, uint256 expire, bool enable);
    event Swap(address indexed to, bool indexed direction, uint256 price, uint256 amountIn, uint256 amountOut, uint256 tradeFee, uint256 protocolFee);
    event SwappedOneProvider(address indexed provider, bool indexed direction, uint256 amountOut, uint256 amountIn, uint256 newAmountBalance, uint256 newCounterReserveBalance);
    event SetDelegator(address indexed provider, address delegator);
    event DelegatorPauseOffer(address indexed delegator, address indexed provider, bool indexed direction);
    event DelegatorResumeOffer(address indexed delegator, address indexed provider, bool indexed direction);

    function counter() external view returns (uint256);
    function first(bool direction) external view returns (uint256);
    function queueSize(bool direction) external view returns (uint256);
    function offers(bool direction, uint256 index) external view returns (
        address provider,
        uint256 staked,
        uint256 amount,
        uint256 reserve,
        uint256 expire,
        bool privateReplenish,
        bool isActive,
        bool enabled,
        uint256 prev,
        uint256 next
    );
    function providerOfferIndex(address provider) external view returns (uint256 index);
    function delegator(address provider) external view returns (address);

    function governance() external view returns (address);
    function oracleLiquidityProvider() external view returns (address);
    function govToken() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function scaleDirection() external view returns (bool);
    function scaler() external view returns (uint256);

    function lastGovBalance() external view returns (uint256);
    function lastToken0Balance() external view returns (uint256);
    function lastToken1Balance() external view returns (uint256);
    function protocolFeeBalance0() external view returns (uint256);
    function protocolFeeBalance1() external view returns (uint256);
    function stakeBalance() external view returns (uint256);
    function feeBalance() external view returns (uint256);

    function getLastBalances() external view returns (uint256, uint256);
    function getBalances() external view returns (uint256, uint256, uint256);

    function getLatestPrice(bool direction, bytes calldata payload) external view returns (uint256);
    function getAmountOut(address tokenIn, uint256 amountIn, bytes calldata data) external view returns (uint256 amountOut);
    function getAmountIn(address tokenOut, uint256 amountOut, bytes calldata data) external view returns (uint256 amountIn);

    function setDelegator(address _delegator, uint256 fee) external;

    function getQueue(bool direction, uint256 start, uint256 end) external view returns (uint256[] memory index, address[] memory provider, uint256[] memory amount, uint256[] memory staked, uint256[] memory expire);
    function getQueueFromIndex(bool direction, uint256 from, uint256 count) external view returns (uint256[] memory index, address[] memory provider, uint256[] memory amount, uint256[] memory staked, uint256[] memory expire);
    function getProviderOffer(address _provider, bool direction) external view returns (uint256 index, uint256 staked, uint256 amount, uint256 reserve, uint256 expire, bool privateReplenish);
    function findPosition(bool direction, uint256 staked, uint256 _afterIndex) external view returns (uint256 afterIndex, uint256 nextIndex);
    function addLiquidity(address provider, bool direction, uint256 staked, uint256 afterIndex, uint256 expire, bool enable) external returns (uint256 index);
    function setPrivateReplenish(bool _replenish) external;
    function replenish(address provider, bool direction, uint256 afterIndex, uint amountIn, uint256 expire) external;
    function pauseOffer(address provider, bool direction) external;
    function resumeOffer(address provider, bool direction, uint256 afterIndex) external;
    function removeLiquidity(address provider, bool direction, uint256 unstake, uint256 afterIndex, uint256 amountOut, uint256 reserveOut, uint256 expire, bool enable) external;
    function removeAllLiquidity(address provider) external returns (uint256 amount0, uint256 amount1, uint256 staked);
    function purgeExpire(bool direction, uint256 startingIndex, uint256 limit) external returns (uint256 purge);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function sync() external;

    function initialize(address _token0, address _token1) external;
    function redeemProtocolFee() external;
}


// File contracts/commons/interfaces/IOSWAP_PausableFactory.sol


pragma solidity =0.6.11;

interface IOSWAP_PausableFactory {
    event Shutdowned();
    event Restarted();
    event PairShutdowned(address indexed pair);
    event PairRestarted(address indexed pair);

    function governance() external view returns (address);

    function isLive() external returns (bool);
    function setLive(bool _isLive) external;
    function setLiveForPair(address pair, bool live) external;
}


// File contracts/commons/interfaces/IOSWAP_FactoryBase.sol


pragma solidity =0.6.11;

interface IOSWAP_FactoryBase is IOSWAP_PausableFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint newSize);

    function pairCreator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}


// File contracts/oracle/interfaces/IOSWAP_OracleFactory.sol


pragma solidity =0.6.11;

interface IOSWAP_OracleFactory is IOSWAP_FactoryBase {
    event ParamSet(bytes32 name, bytes32 value);
    event ParamSet2(bytes32 name, bytes32 value1, bytes32 value2);
    event OracleAdded(address indexed token0, address indexed token1, address oracle);
    event OracleScores(address indexed oracle, uint256 score);
    event Whitelisted(address indexed who, bool allow);

    function oracleLiquidityProvider() external view returns (address);

    function tradeFee() external view returns (uint256);
    function protocolFee() external view returns (uint256);
    function feePerDelegator() external view returns (uint256);
    function protocolFeeTo() external view returns (address);

    function securityScoreOracle() external view returns (address);
    function minOracleScore() external view returns (uint256);

    function oracles(address token0, address token1) external view returns (address oracle);
    function minLotSize(address token) external view returns (uint256);
    function isOracle(address) external view returns (bool);
    function oracleScores(address oracle) external view returns (uint256);

    function whitelisted(uint256) external view returns (address);
    function whitelistedInv(address) external view returns (uint256);
    function isWhitelisted(address) external returns (bool);

    function setOracleLiquidityProvider(address _oracleRouter, address _oracleLiquidityProvider) external;

    function setOracle(address from, address to, address oracle) external;
    function addOldOracleToNewPair(address from, address to, address oracle) external;
    function setTradeFee(uint256) external;
    function setProtocolFee(uint256) external;
    function setFeePerDelegator(uint256 _feePerDelegator) external;
    function setProtocolFeeTo(address) external;
    function setSecurityScoreOracle(address, uint256) external;
    function setMinLotSize(address token, uint256 _minLotSize) external;

    function updateOracleScore(address oracle) external;

    function whitelistedLength() external view returns (uint256);
    function allWhiteListed() external view returns(address[] memory list, bool[] memory allowed);
    function setWhiteList(address _who, bool _allow) external;

    function checkAndGetOracleSwapParams(address tokenA, address tokenB) external view returns (address oracle, uint256 _tradeFee, uint256 _protocolFee);
    function checkAndGetOracle(address tokenA, address tokenB) external view returns (address oracle);
}


// File contracts/gov/interfaces/IOAXDEX_Governance.sol


pragma solidity =0.6.11;

interface IOAXDEX_Governance {

    struct NewStake {
        uint256 amount;
        uint256 timestamp;
    }
    struct VotingConfig {
        uint256 minExeDelay;
        uint256 minVoteDuration;
        uint256 maxVoteDuration;
        uint256 minOaxTokenToCreateVote;
        uint256 minQuorum;
    }

    event ParamSet(bytes32 indexed name, bytes32 value);
    event ParamSet2(bytes32 name, bytes32 value1, bytes32 value2);
    event AddVotingConfig(bytes32 name, 
        uint256 minExeDelay,
        uint256 minVoteDuration,
        uint256 maxVoteDuration,
        uint256 minOaxTokenToCreateVote,
        uint256 minQuorum);
    event SetVotingConfig(bytes32 indexed configName, bytes32 indexed paramName, uint256 minExeDelay);

    event Stake(address indexed who, uint256 value);
    event Unstake(address indexed who, uint256 value);

    event NewVote(address indexed vote);
    event NewPoll(address indexed poll);
    event Vote(address indexed account, address indexed vote, uint256 option);
    event Poll(address indexed account, address indexed poll, uint256 option);
    event Executed(address indexed vote);
    event Veto(address indexed vote);

    function votingConfigs(bytes32) external view returns (uint256 minExeDelay,
        uint256 minVoteDuration,
        uint256 maxVoteDuration,
        uint256 minOaxTokenToCreateVote,
        uint256 minQuorum);
    function votingConfigProfiles(uint256) external view returns (bytes32);

    function oaxToken() external view returns (address);
    function votingToken() external view returns (address);
    function freezedStake(address) external view returns (uint256 amount, uint256 timestamp);
    function stakeOf(address) external view returns (uint256);
    function totalStake() external view returns (uint256);

    function votingRegister() external view returns (address);
    function votingExecutor(uint256) external view returns (address);
    function votingExecutorInv(address) external view returns (uint256);
    function isVotingExecutor(address) external view returns (bool);
    function admin() external view returns (address);
    function minStakePeriod() external view returns (uint256);

    function voteCount() external view returns (uint256);
    function votingIdx(address) external view returns (uint256);
    function votings(uint256) external view returns (address);


	function votingConfigProfilesLength() external view returns(uint256);
	function getVotingConfigProfiles(uint256 start, uint256 length) external view returns(bytes32[] memory profiles);
    function getVotingParams(bytes32) external view returns (uint256 _minExeDelay, uint256 _minVoteDuration, uint256 _maxVoteDuration, uint256 _minOaxTokenToCreateVote, uint256 _minQuorum);

    function setVotingRegister(address _votingRegister) external;
    function votingExecutorLength() external view returns (uint256);
    function initVotingExecutor(address[] calldata _setVotingExecutor) external;
    function setVotingExecutor(address _setVotingExecutor, bool _bool) external;
    function initAdmin(address _admin) external;
    function setAdmin(address _admin) external;
    function addVotingConfig(bytes32 name, uint256 minExeDelay, uint256 minVoteDuration, uint256 maxVoteDuration, uint256 minOaxTokenToCreateVote, uint256 minQuorum) external;
    function setVotingConfig(bytes32 configName, bytes32 paramName, uint256 paramValue) external;
    function setMinStakePeriod(uint _minStakePeriod) external;

    function stake(uint256 value) external;
    function unlockStake() external;
    function unstake(uint256 value) external;
    function allVotings() external view returns (address[] memory);
    function getVotingCount() external view returns (uint256);
    function getVotings(uint256 start, uint256 count) external view returns (address[] memory _votings);

    function isVotingContract(address votingContract) external view returns (bool);

    function getNewVoteId() external returns (uint256);
    function newVote(address vote, bool isExecutiveVote) external;
    function voted(bool poll, address account, uint256 option) external;
    function executed() external;
    function veto(address voting) external;
    function closeVote(address vote) external;
}


// File contracts/oracle/interfaces/IOSWAP_OracleAdaptor.sol


pragma solidity =0.6.11;

interface IOSWAP_OracleAdaptor {
    function isSupported(address from, address to) external view returns (bool supported);
    function getRatio(address from, address to, uint256 fromAmount, uint256 toAmount, bytes calldata payload) external view returns (uint256 numerator, uint256 denominator);
    function getLatestPrice(address from, address to, bytes calldata payload) external view returns (uint256 price);
    function decimals() external view returns (uint8);
}


// File contracts/libraries/SafeMath.sol



pragma solidity >=0.6.0 <0.8.0;

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


// File contracts/libraries/Address.sol



pragma solidity =0.6.11;

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
        assembly {
            size := extcodesize(account)
        }
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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


// File contracts/commons/OSWAP_PausablePair.sol


pragma solidity =0.6.11;

contract OSWAP_PausablePair is IOSWAP_PausablePair {
    bool public override isLive;
    address public override immutable factory;

    constructor() public {
        factory = msg.sender;
        isLive = true;
    }
    function setLive(bool _isLive) external override {
        require(msg.sender == factory, 'FORBIDDEN');
        isLive = _isLive;
    }
}


// File contracts/oracle/OSWAP_OraclePair.sol


pragma solidity =0.6.11;








contract OSWAP_OraclePair is IOSWAP_OraclePair, OSWAP_PausablePair {
    using SafeMath for uint256;

    uint256 constant FEE_BASE = 10 ** 5;
    uint256 constant FEE_BASE_SQ = (10 ** 5) ** 2;
    uint256 constant WEI = 10**18;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier onlyEndUser() {
        require((tx.origin == msg.sender && !Address.isContract(msg.sender)) || IOSWAP_OracleFactory(factory).isWhitelisted(msg.sender), "Not from user or whitelisted");
        _;
    }
    modifier onlyDelegator(address provider) {
        require(provider == msg.sender || delegator[provider] == msg.sender, "Not a delegator");
        _;
    }

    uint256 public override counter;
    mapping (bool => uint256) public override first;
    mapping (bool => uint256) public override queueSize;
    mapping (bool => mapping (uint256 => Offer)) public override offers;
    mapping (address => uint256) public override providerOfferIndex;
    mapping (address => address) public override delegator;

    address public override immutable governance;
    address public override immutable oracleLiquidityProvider;
    address public override immutable govToken;
    address public override token0;
    address public override token1;
    bool public override scaleDirection;
    uint256 public override scaler;

    uint256 public override lastGovBalance;
    uint256 public override lastToken0Balance;
    uint256 public override lastToken1Balance;
    uint256 public override protocolFeeBalance0;
    uint256 public override protocolFeeBalance1;
    uint256 public override stakeBalance;
    uint256 public override feeBalance;

    constructor() public {
        address _governance = IOSWAP_OracleFactory(msg.sender).governance();
        governance = _governance;
        govToken = IOAXDEX_Governance(_governance).oaxToken();
        oracleLiquidityProvider = IOSWAP_OracleFactory(msg.sender).oracleLiquidityProvider();
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external override {
        require(msg.sender == factory, 'FORBIDDEN'); // sufficient check

        token0 = _token0;
        token1 = _token1;

        offers[true][0].provider = address(this);
        offers[false][0].provider = address(this);
        require(token0 < token1, "Invalid token pair order");
        address oracle = IOSWAP_OracleFactory(factory).oracles(token0, token1);
        require(oracle != address(0), "No oracle found");

        uint8 token0Decimals = IERC20(token0).decimals();
        uint8 token1Decimals = IERC20(token1).decimals();
        scaleDirection = token1Decimals > token0Decimals;
        scaler = 10 ** uint256(scaleDirection ? (token1Decimals - token0Decimals) : (token0Decimals - token1Decimals));
    }

    function getLastBalances() external override view returns (uint256, uint256) {
        return (
            lastToken0Balance,
            lastToken1Balance
        );
    }
    function getBalances() public override view returns (uint256, uint256, uint256) {
        return (
            IERC20(govToken).balanceOf(address(this)),
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this))
        );
    }

    function getLatestPrice(bool direction, bytes calldata payload) public override view returns (uint256) {
        (address oracle,,) = IOSWAP_OracleFactory(factory).checkAndGetOracleSwapParams(token0, token1);
        (address tokenA, address tokenB) = direction ? (token0, token1) : (token1, token0);
        return IOSWAP_OracleAdaptor(oracle).getLatestPrice(tokenA, tokenB, payload);
    }

    function _safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }
    function _safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FROM_FAILED');
    }
    function minLotSize(bool direction) internal view returns (uint256) {
        return IOSWAP_OracleFactory(factory).minLotSize(direction ? token1 : token0);
    }

    function _getSwappedAmount(bool direction, uint256 amountIn, bytes calldata data) internal view returns (uint256 amountOut, uint256 price, uint256 tradeFeeCollected, uint256 tradeFee, uint256 protocolFee) {
        address oracle;
        (oracle, tradeFee, protocolFee)  = IOSWAP_OracleFactory(factory).checkAndGetOracleSwapParams(token0, token1);
        tradeFeeCollected = amountIn.mul(tradeFee).div(FEE_BASE);
        amountIn = amountIn.sub(tradeFeeCollected);
        (uint256 numerator, uint256 denominator) = IOSWAP_OracleAdaptor(oracle).getRatio(direction ? token0 : token1, direction ? token1 : token0, amountIn, 0, data);
        amountOut = amountIn.mul(numerator);
        if (scaler > 1)
            amountOut = (direction == scaleDirection) ? amountOut.mul(scaler) : amountOut.div(scaler);
        amountOut = amountOut.div(denominator);
        price = numerator.mul(WEI).div(denominator);
    }
    function getAmountOut(address tokenIn, uint256 amountIn, bytes calldata data) public override view returns (uint256 amountOut) {
        require(amountIn > 0, 'INSUFFICIENT_INPUT_AMOUNT');
        (amountOut,,,,) = _getSwappedAmount(tokenIn == token0, amountIn, data);
    }
    function getAmountIn(address tokenOut, uint256 amountOut, bytes calldata data) public override view returns (uint256 amountIn) {
        require(amountOut > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
        (address oracle, uint256 tradeFee,)  = IOSWAP_OracleFactory(factory).checkAndGetOracleSwapParams(token0, token1);
        bool direction = tokenOut == token1;
        address tokenIn = direction ? token0 : token1;
        (uint256 numerator, uint256 denominator) = IOSWAP_OracleAdaptor(oracle).getRatio(tokenIn, tokenOut, 0, amountOut, data);
        amountIn = amountOut.mul(denominator);
        if (scaler > 1)
            amountIn = (direction != scaleDirection) ? amountIn.mul(scaler) : amountIn.div(scaler);
        amountIn = amountIn.div(numerator).add(1);
        amountIn = amountIn.mul(FEE_BASE).div(FEE_BASE.sub(tradeFee)).add(1);
    }

    function setDelegator(address _delegator, uint256 fee) external override {
        address provider = msg.sender;
        delegator[provider] = _delegator;
        if (_delegator != address(0)) {
            uint256 feePerDelegator = IOSWAP_OracleFactory(factory).feePerDelegator();
            if (feePerDelegator > 0) {
                require(fee == feePerDelegator, "Fee Mismatch");
                feeBalance = feeBalance.add(feePerDelegator);
                _safeTransferFrom(govToken, provider, address(this), feePerDelegator);
            }
        }
        emit SetDelegator(provider, _delegator);
    }

    function getQueue(bool direction, uint256 start, uint256 end) external view override returns (uint256[] memory index, address[] memory provider, uint256[] memory amount, uint256[] memory staked, uint256[] memory expire) {
        uint256 _queueSize = queueSize[direction];
        if (start < _queueSize) {
            if (end >= _queueSize)
                end = _queueSize == 0 ? 0 : _queueSize.sub(1);
            uint256 count = end.add(1).sub(start);
            uint256 i = 0;
            Offer storage offer;
            uint256 currIndex = first[direction];
            for (offer = offers[direction][currIndex] ; i < start ; offer = offers[direction][currIndex = offer.next]) {
                i++;
            }
            return getQueueFromIndex(direction, currIndex, count);
        } else {
            index = amount = staked = expire = new uint256[](0);
            provider = new address[](0);
        }
    }
    function getQueueFromIndex(bool direction, uint256 from, uint256 count) public view override returns (uint256[] memory index, address[] memory provider, uint256[] memory amount, uint256[] memory staked, uint256[] memory expire) {
        index = new uint256[](count);
        provider = new address[](count);
        amount = new uint256[](count);
        staked = new uint256[](count);
        expire = new uint256[](count);

        uint256 i = 0;
        Offer storage offer = offers[direction][from];
        uint256 currIndex = from;
        for (i = 0; i < count && currIndex != 0; i++) {
            index[i] = currIndex;
            provider[i] = offer.provider;
            amount[i] = offer.amount;
            staked[i] = offer.staked;
            expire[i] = offer.expire;
            offer = offers[direction][currIndex = offer.next];
        }
    }
    function getProviderOffer(address provider, bool direction) external view override returns (uint256 index, uint256 staked, uint256 amount, uint256 reserve, uint256 expire, bool privateReplenish) {
        index = providerOfferIndex[provider];
        Offer storage offer = offers[direction][index];
        return (index, offer.staked, offer.amount, offer.reserve, offer.expire, offer.privateReplenish);
    }
    function findPosition(bool direction, uint256 staked, uint256 _afterIndex) public view override returns (uint256 afterIndex, uint256 nextIndex) {
        afterIndex = _afterIndex;
        if (afterIndex == 0){
            nextIndex = first[direction];
        } else {
            Offer storage prev = offers[direction][afterIndex];
            require(prev.provider != address(0), "Invalid index");

            while (prev.staked < staked) {
                afterIndex = prev.prev;
                if (afterIndex == 0){
                    break;
                } 
                prev = offers[direction][afterIndex];
            }
            nextIndex = afterIndex == 0 ? first[direction] : prev.next;
        }

        if (nextIndex > 0) {
            Offer storage next = offers[direction][nextIndex];
            while (staked <= next.staked) {
                afterIndex = nextIndex;
                nextIndex = next.next;
                if (nextIndex == 0) {
                    break;
                }
                next = offers[direction][nextIndex];
            }
        }
    }
    function _enqueue(bool direction, uint256 index, uint256 staked, uint256 afterIndex, uint256 amount, uint256 expire) internal {
        if (amount > 0 && expire > block.timestamp) {
            uint256 nextIndex;
            (afterIndex, nextIndex) = findPosition(direction, staked, afterIndex);

            if (afterIndex != 0)
                offers[direction][afterIndex].next = index;
            if (nextIndex != 0)
                offers[direction][nextIndex].prev = index;

            Offer storage offer = offers[direction][index];
            offer.prev = afterIndex;
            offer.next = nextIndex;

            if (afterIndex == 0){
                first[direction] = index;
            }

            if (!offer.isActive) {
                offer.isActive = true;
                queueSize[direction]++;
            }
        }
    }
    function _halfDequeue(bool direction, uint index) internal returns (uint256 prevIndex, uint256 nextIndex) {
        Offer storage offer = offers[direction][index];
        nextIndex = offer.next;
        prevIndex = offer.prev;

        if (prevIndex != 0) {
            offers[direction][prevIndex].next = nextIndex;
        }

        if (nextIndex != 0) {
            offers[direction][nextIndex].prev = prevIndex;
        }

        if (first[direction] == index){
            first[direction] = nextIndex;
        }
    }

    function _dequeue(bool direction, uint index) internal returns (uint256 nextIndex) {
        (,nextIndex) = _halfDequeue(direction, index);

        Offer storage offer = offers[direction][index];
        offer.prev = 0;
        offer.next = 0;
        offer.isActive = false;
        queueSize[direction] = queueSize[direction].sub(1);
    }

    function _newOffer(address provider, bool direction, uint256 index, uint256 staked, uint256 afterIndex, uint256 amount, uint256 expire, bool enable) internal {
        require(amount >= minLotSize(direction), "Minium lot size not met");

        if (enable)
            _enqueue(direction, index, staked, afterIndex, amount, expire);

        Offer storage offer = offers[direction][index];
        offer.provider = provider;
        offer.staked = staked;
        offer.amount = amount;
        offer.expire = expire;
        offer.privateReplenish = true;
        offer.enabled = enable;

        Offer storage counteroffer = offers[!direction][index];
        counteroffer.provider = provider;
        counteroffer.privateReplenish = true;
        counteroffer.enabled = enable;
    }
    function _renewOffer(bool direction, uint256 index, uint256 stakeAdded, uint256 afterIndex, uint256 amountAdded, uint256 expire, bool enable) internal {
        Offer storage offer = offers[direction][index];
        uint256 newAmount = offer.amount.add(amountAdded);
        require(newAmount >= minLotSize(direction), "Minium lot size not met");
        uint256 staked = offer.staked.add(stakeAdded);
        offer.enabled = enable;
        if (amountAdded > 0)
            offer.amount = newAmount;
        if (stakeAdded > 0)
            offer.staked = staked;
        offer.expire = expire;

        if (enable) {
            if (offer.isActive) {
                if (stakeAdded > 0 && (index != afterIndex || staked > offers[direction][offer.prev].staked)) {
                    _halfDequeue(direction, index);
                    _enqueue(direction, index, staked, afterIndex, newAmount, expire);
                }
            } else {
                _enqueue(direction, index, staked, afterIndex, newAmount, expire);
            }
        } else {
            if (offer.isActive)
                _dequeue(direction, index);
        }
    }
    function addLiquidity(address provider, bool direction, uint256 staked, uint256 afterIndex, uint256 expire, bool enable) external override lock returns (uint256 index) {
        require(IOSWAP_OracleFactory(factory).isLive(), 'GLOBALLY PAUSED');
        require(msg.sender == oracleLiquidityProvider || msg.sender == provider, "Not from router or owner");
        require(isLive, "PAUSED");
        require(provider != address(0), "Null address");
        require(expire > block.timestamp, "Already expired");

        (uint256 newGovBalance, uint256 newToken0Balance, uint256 newToken1Balance) = getBalances();
        require(newGovBalance.sub(lastGovBalance) >= staked, "Invalid feeIn");
        stakeBalance = stakeBalance.add(staked);
        uint256 amountIn;
        if (direction) {
            amountIn = newToken1Balance.sub(lastToken1Balance);
            if (govToken == token1)
                amountIn = amountIn.sub(staked);
        } else {
            amountIn = newToken0Balance.sub(lastToken0Balance);
            if (govToken == token0)
                amountIn = amountIn.sub(staked);
        }

        index = providerOfferIndex[provider];
        if (index > 0) {
            _renewOffer(direction, index, staked, afterIndex, amountIn, expire, enable);
        } else {
            index = (++counter);
            providerOfferIndex[provider] = index;
            require(amountIn > 0, "No amount in");
            _newOffer(provider, direction, index, staked, afterIndex, amountIn, expire, enable);

            emit NewProvider(provider, index);
        }

        lastGovBalance = newGovBalance;
        lastToken0Balance = newToken0Balance;
        lastToken1Balance = newToken1Balance;

        Offer storage offer = offers[direction][index];
        emit AddLiquidity(provider, direction, staked, amountIn, offer.staked, offer.amount, expire, enable);
    }
    function setPrivateReplenish(bool _replenish) external override lock {
        address provider = msg.sender;
        uint256 index = providerOfferIndex[provider];
        require(index > 0, "Provider not found");
        offers[false][index].privateReplenish = _replenish;
        offers[true][index].privateReplenish = _replenish;
    }
    function replenish(address provider, bool direction, uint256 afterIndex, uint amountIn, uint256 expire) external override lock {
        uint256 index = providerOfferIndex[provider];
        require(index > 0, "Provider not found");

        // move funds from internal wallet
        Offer storage offer = offers[direction][index];
        require(!offer.privateReplenish || provider == msg.sender, "Not from provider");

        if (provider != msg.sender) {
            if (offer.expire == 0) {
                // if expire is not set, set it the same as the counter offer
                expire = offers[!direction][index].expire;
            } else {
                // don't allow others to modify the expire
                expire = offer.expire;
            }
        }
        require(expire > block.timestamp, "Already expired");

        offer.reserve = offer.reserve.sub(amountIn);
        _renewOffer(direction, index, 0, afterIndex, amountIn, expire, offer.enabled);

        emit Replenish(provider, direction, amountIn, offer.amount, offer.reserve, expire);
    }
    function pauseOffer(address provider, bool direction) external override onlyDelegator(provider) {
        uint256 index = providerOfferIndex[provider];
        Offer storage offer = offers[direction][index];
        if (offer.isActive) {
            _dequeue(direction, index);
        }
        offer.enabled = false;
        emit DelegatorPauseOffer(msg.sender, provider, direction);
    }
    function resumeOffer(address provider, bool direction, uint256 afterIndex) external override onlyDelegator(provider) {
        uint256 index = providerOfferIndex[provider];
        Offer storage offer = offers[direction][index];
        
        if (!offer.isActive && offer.expire > block.timestamp && offer.amount >= minLotSize(direction)) {
            _enqueue(direction, index, offer.staked, afterIndex, offer.amount, offer.expire);
        }
        offer.enabled = true;
        emit DelegatorResumeOffer(msg.sender, provider, direction);
    }
    function removeLiquidity(address provider, bool direction, uint256 unstake, uint256 afterIndex, uint256 amountOut, uint256 reserveOut, uint256 expire, bool enable) external override lock {
        require(msg.sender == oracleLiquidityProvider || msg.sender == provider, "Not from router or owner");
        require(expire > block.timestamp, "Already expired");

        uint256 index = providerOfferIndex[provider];
        require(index > 0, "Provider liquidity not found");

        Offer storage offer = offers[direction][index];
        uint256 newAmount = offer.amount.sub(amountOut);
        require(newAmount == 0 || newAmount >= minLotSize(direction), "Minium lot size not met");

        uint256 staked = offer.staked.sub(unstake);
        offer.enabled = enable;
        if (amountOut > 0)
            offer.amount = newAmount;
        if (unstake > 0)
            offer.staked = staked;
        offer.reserve = offer.reserve.sub(reserveOut);
        offer.expire = expire;

        if (enable) {
            if (offer.isActive) {
                if (unstake > 0 && (index != afterIndex || offers[direction][offer.next].staked >= staked)) {
                    _halfDequeue(direction, index);
                    _enqueue(direction, index, staked, afterIndex, newAmount, expire);
                }
            } else {
                _enqueue(direction, index, staked, afterIndex, newAmount, expire);
            }
        } else {
            if (offer.isActive)
                _dequeue(direction, index);
        }

        if (unstake > 0) {
            stakeBalance = stakeBalance.sub(unstake);
            _safeTransfer(govToken, msg.sender, unstake); // optimistically transfer tokens
        }

        if (amountOut > 0 || reserveOut > 0)
            _safeTransfer(direction ? token1 : token0, msg.sender, amountOut.add(reserveOut)); // optimistically transfer tokens
        emit RemoveLiquidity(provider, direction, unstake, amountOut, reserveOut, offer.staked, offer.amount, offer.reserve, expire, enable);

        _sync();
    }
    function removeAllLiquidity(address provider) external override lock returns (uint256 amount0, uint256 amount1, uint256 staked) {
        require(msg.sender == oracleLiquidityProvider || msg.sender == provider, "Not from router or owner");
        uint256 staked0;
        uint256 staked1;
        uint256 reserve0;
        uint256 reserve1;
        (staked1, amount1, reserve1) = _removeAllLiquidityOneSide(provider, true);
        (staked0, amount0, reserve0) = _removeAllLiquidityOneSide(provider, false);
        staked = staked0.add(staked1);
        amount0 = amount0.add(reserve0);
        amount1 = amount1.add(reserve1);
        stakeBalance = stakeBalance.sub(staked);
        _safeTransfer(govToken, msg.sender, staked); // optimistically transfer tokens

        _sync();
    }
    function _removeAllLiquidityOneSide(address provider, bool direction) internal returns (uint256 staked, uint256 amount, uint256 reserve) {
        uint256 index = providerOfferIndex[provider];
        require(index > 0, "Provider liquidity not found");

        Offer storage offer = offers[direction][index];
        require(provider == offer.provider, "Forbidden");
        staked = offer.staked;
        amount = offer.amount;
        reserve = offer.reserve;

        offer.staked = 0;
        offer.amount = 0;
        offer.reserve = 0;

        if (offer.isActive)
            _dequeue(direction, index);
        _safeTransfer(direction ? token1 : token0, msg.sender, amount.add(reserve)); // optimistically transfer tokens
        emit RemoveLiquidity(provider, direction, staked, amount, reserve, 0, 0, 0, 0, offer.enabled);
    }
    function purgeExpire(bool direction, uint256 startingIndex, uint256 limit) external override lock returns (uint256 purge) {
        uint256 index = startingIndex;
        while (index != 0 && limit > 0) {
            Offer storage offer = offers[direction][index];
            if (offer.expire < block.timestamp) {
                index = _dequeue(direction, index);
                purge++;
            } else {
                index = offer.next;
            }
            limit--;
        }
    }

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external override lock onlyEndUser {
        require(isLive, "PAUSED");
        uint256 amount0In;
        uint256 amount1In;
        amount0In = IERC20(token0).balanceOf(address(this)).sub(lastToken0Balance);
        amount1In = IERC20(token1).balanceOf(address(this)).sub(lastToken1Balance);
        uint256 protocolFeeCollected;

        if (amount0Out == 0 && amount1Out != 0){
            (amount1Out, protocolFeeCollected) = _swap(to, true, amount0In, amount1Out, data);
            _safeTransfer(token1, to, amount1Out); // optimistically transfer tokens
            protocolFeeBalance0 = protocolFeeBalance0.add(protocolFeeCollected);
        } else if (amount0Out != 0 && amount1Out == 0){
            (amount0Out, protocolFeeCollected) = _swap(to, false, amount1In, amount0Out, data);
            _safeTransfer(token0, to, amount0Out); // optimistically transfer tokens
            protocolFeeBalance1 = protocolFeeBalance1.add(protocolFeeCollected);
        } else {
            revert("Not supported");
        }

        _sync();
    }
    function _swap(address to, bool direction, uint256 amountIn, uint256 _amountOut, bytes calldata data) internal returns (uint256 amountOut, uint256 protocolFeeCollected) {
        uint256 amountInMinusProtocolFee;
        {
            uint256 price;
            uint256 tradeFeeCollected;
            uint256 tradeFee;
            uint256 protocolFee;
            (amountOut, price, tradeFeeCollected, tradeFee, protocolFee) = _getSwappedAmount(direction, amountIn, data);
            require(amountOut >= _amountOut, "INSUFFICIENT_AMOUNT");
            if (protocolFee == 0) {
                amountInMinusProtocolFee = amountIn;
            } else {
                protocolFeeCollected = amountIn.mul(tradeFee.mul(protocolFee)).div(FEE_BASE_SQ);
                amountInMinusProtocolFee = amountIn.sub(protocolFeeCollected);
            }
            emit Swap(to, direction, price, amountIn, amountOut, tradeFeeCollected, protocolFeeCollected);
        }

        uint256 remainOut = amountOut;

        uint256 index = first[direction];
        Offer storage offer;
        Offer storage counteroffer;
        while (remainOut > 0 && index != 0) {
            offer = offers[direction][index];
            if (offer.expire < block.timestamp) {
                index = _dequeue(direction, index);
            } else {
                counteroffer = offers[!direction][index];
                uint256 amount = offer.amount;
                if (remainOut >= amount) {
                    // amount requested cover whole entry, clear entry
                    remainOut = remainOut.sub(amount);

                    uint256 providerShare = amountInMinusProtocolFee.mul(amount).div(amountOut);
                    counteroffer.reserve = counteroffer.reserve.add(providerShare);

                    offer.amount = 0;
                    emit SwappedOneProvider(offer.provider, direction, amount, providerShare, 0, counteroffer.reserve);

                    // remove from provider queue
                    index = _dequeue(direction, index);
                } else {
                    // remaining request amount
                    uint256 providerShare = amountInMinusProtocolFee.mul(remainOut).div(amountOut);
                    counteroffer.reserve = counteroffer.reserve.add(providerShare);

                    offer.amount = offer.amount.sub(remainOut);
                    emit SwappedOneProvider(offer.provider, direction, remainOut, providerShare, offer.amount, counteroffer.reserve);

                    remainOut = 0;
                }
            }
        }

        require(remainOut == 0, "Amount exceeds available fund");
    }

    function sync() external override lock {
        _sync();
    }
    function _sync() internal {
        (lastGovBalance, lastToken0Balance, lastToken1Balance) = getBalances();
    }

    function redeemProtocolFee() external override lock {
        address protocolFeeTo = IOSWAP_OracleFactory(factory).protocolFeeTo();
        uint256 _protocolFeeBalance0 = protocolFeeBalance0;
        uint256 _protocolFeeBalance1 = protocolFeeBalance1;
        uint256 _feeBalance = feeBalance;
        _safeTransfer(token0, protocolFeeTo, _protocolFeeBalance0); // optimistically transfer tokens
        _safeTransfer(token1, protocolFeeTo, _protocolFeeBalance1); // optimistically transfer tokens
        _safeTransfer(govToken, protocolFeeTo, _feeBalance); // optimistically transfer tokens
        protocolFeeBalance0 = 0;
        protocolFeeBalance1 = 0;
        feeBalance = 0;
        _sync();
    }
}


// File contracts/oracle/OSWAP_OraclePairCreator.sol


pragma solidity =0.6.11;


contract OSWAP_OraclePairCreator is IOSWAP_PairCreator {
    function createPair(bytes32 salt) external override returns (address pair) {
        bytes memory bytecode = type(OSWAP_OraclePair).creationCode;
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        return pair;
    }
}