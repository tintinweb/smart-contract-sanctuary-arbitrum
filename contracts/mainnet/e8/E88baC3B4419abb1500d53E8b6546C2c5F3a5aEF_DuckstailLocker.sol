/**
 *Submitted for verification at Arbiscan.io on 2023-11-29
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

contract Context {
    constructor () { }

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address payable private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address payable msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() external view returns (address payable) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = payable(0);
    }

    function transferOwnership(address payable newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity >=0.4.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
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

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeERC20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeERC20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, 'SafeERC20: low-level call failed');
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
        }
    }
}


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

    constructor() {
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

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(
    address indexed sender,
    uint256 amount0,
    uint256 amount1,
    address indexed to
  );
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

interface IUniswapV2Factory {
  event PairCreated(
    address indexed token0,
    address indexed token1,
    address pair,
    uint256
  );

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

contract DuckstailLocker is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct LockParams {
        uint256 amount;
        address token;
        address owner;
        uint64 unlockTime;
        uint64 lockTime;
        uint16 firstPercent;
        uint64 vestingPeriod;
        uint16 amountPerCycle;
        string title;

        bool isLP;
        uint64 id;
        uint64 lastUpdatedTime;
        uint256 claimed;
    }

    LockParams[] public locks;
    mapping (address => uint64[]) public userLocks;
    uint256 constant MAX_USER_LOCK = 100;

    event NewLockCreated(address indexed from, uint256 id); 

    function lock(LockParams memory _params) external nonReentrant {
        LockParams memory params = _params;
        require(params.firstPercent <= 10000, "invalid first percent");
        require(params.amountPerCycle <= 10000, "invalid cycle percent");
        require(params.unlockTime > block.timestamp, "invalid unlock time");
        require(params.firstPercent > 0, "first percent must be positive number");
        require(params.vestingPeriod > 0, "vesting period must be positive number");
        require(params.amountPerCycle > 0, "cycle percent must be positive number");
        uint256 beforeBalance = IERC20(params.token).balanceOf(address(this));
        IERC20(params.token).safeTransferFrom(msg.sender, address(this), params.amount);
        uint256 balance = IERC20(params.token).balanceOf(address(this));
        require(beforeBalance + params.amount <= balance, "should exclude from fee this address");
        if(params.isLP) {
            _parseFactoryAddress(params.token);
        }

        params.id = uint64(locks.length);
        params.lastUpdatedTime = uint64(block.timestamp);
        params.lockTime = uint64(block.timestamp);
        params.claimed = 0;
        locks.push(params);
        userLocks[params.owner].push(params.id);
        require(userLocks[params.owner].length <= MAX_USER_LOCK, "can't create lock more than limit");
        emit NewLockCreated(msg.sender, params.id);
    }

    function unLock(uint64 id) external nonReentrant {
        LockParams storage currentLock = locks[id];
        require(msg.sender == currentLock.owner, "caller is not lock a owner");
        require(block.timestamp >= currentLock.unlockTime, "can't unlock before unlockTime");
        uint64 vested = currentLock.firstPercent;
        if(vested < 10000)
            vested = vested + uint64((block.timestamp - currentLock.unlockTime).div(uint256(currentLock.vestingPeriod)).mul(uint256(currentLock.amountPerCycle)));
        if(vested > 10000)
            vested = 10000;
        if(vested > 0) {
            uint256 vestedAmount  = currentLock.amount.mul(uint256(vested)).div(10000);
            uint256 releaseAmount = vestedAmount.sub(currentLock.claimed);
            currentLock.claimed = currentLock.claimed + releaseAmount;
            IERC20(currentLock.token).safeTransfer(currentLock.owner, releaseAmount);
        }
        currentLock.lastUpdatedTime = uint64(block.timestamp);
    }

    function renounceOwnershipOfLock(uint64 id) external {
        LockParams storage currentLock = locks[id];
        uint64[] storage userLock = userLocks[msg.sender];
        require(msg.sender == currentLock.owner, "caller is not owner of lock");
        currentLock.owner = address(0);
        for (uint256 index = 0; index < userLock.length; index++) {
            if(userLock[index] == id) {
                userLock[index] = userLock[userLock.length - 1];
                break;
            }
        }
        userLock.pop();
    }

    function updateLockTitle(uint64 id, string memory _title) external {
        LockParams storage currentLock = locks[id];
        require(msg.sender == currentLock.owner, "caller is not owner of lock");
        currentLock.title = _title;
    }

    function updateLockInfo(uint64 id, uint256 _amount, uint64 _unlockTime) external nonReentrant {
        LockParams storage currentLock = locks[id];
        require(msg.sender == currentLock.owner, "caller is not owner of lock");
        require(_amount >= currentLock.amount, "new amount should be bigger than previous amount");
        require(_unlockTime >= currentLock.unlockTime, "new unlock time should be after than previous one");
        uint256 amount = _amount - currentLock.amount;
        currentLock.amount = _amount;
        currentLock.unlockTime = _unlockTime;
        uint256 beforeBalance = IERC20(currentLock.token).balanceOf(address(this));
        IERC20(currentLock.token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 balance = IERC20(currentLock.token).balanceOf(address(this));
        require(beforeBalance + amount <= balance, "should exclude from fee this address");

    }

    function getLocksLength(bool isLP) public view returns (uint256 count) {
        count = 0;
        for (uint256 index = 0; index < locks.length; index++) {
            if(locks[index].isLP == isLP)
                count++;
        }
    }

    function getLocks(bool isLP, uint256 size, uint256 cursor) external view returns(LockParams[] memory) {
        uint256 length = size;
        uint256 temp = getLocksLength(isLP);

        if (length > temp - cursor) {
            length = temp - cursor;
        }

        LockParams[] memory branch = new LockParams[](length);
        uint256 count = 0;
        for (uint256 i = 0; i < locks.length; i++) {
            if(locks[i].isLP == isLP) {
                count++;
                if(count > cursor + length)
                    break;
                if(count > cursor)
                    branch[count - cursor - 1] = locks[i];
            }
        }

        return branch;
    }

    function getUserLocksLength(bool isLP, address _user) public view returns (uint256 count) {
        count = 0;
        for (uint256 index = 0; index < userLocks[_user].length; index++) {
            if(locks[userLocks[_user][index]].isLP == isLP && locks[userLocks[_user][index]].amount != locks[userLocks[_user][index]].claimed)
                count++;
        }
    }

    function getUserLocks(bool isLP, address _user, uint256 size, uint256 cursor) external view returns(LockParams[] memory) {
        uint256 length = size;
        uint256 temp = getUserLocksLength(isLP, _user);

        if (length > temp - cursor) {
            length = temp - cursor;
        }

        LockParams[] memory branch = new LockParams[](length);
        uint256 count = 0;

        for (uint256 i = 0; i < userLocks[_user].length; i++) {
            if(locks[userLocks[_user][i]].isLP == isLP && locks[userLocks[_user][i]].amount != locks[userLocks[_user][i]].claimed) {
                count++;
                if(count > cursor + length)
                    break;
                if(count > cursor)
                    branch[count - cursor - 1] = locks[userLocks[_user][i]];
            }
        }

        return branch;
    }

    function searchByAddress(address token) external view returns(LockParams[] memory) {
        LockParams[] memory temp = new LockParams[](1000);
        uint256 count = 0;
        for (uint256 index = 0; index < locks.length; index++) {
            if(locks[index].token == token) {
                temp[count] = locks[index];
                count++;
            }
        }
        LockParams[] memory branch = new LockParams[](count);
        for (uint256 index = 0; index < count; index++) {
            branch[index] = temp[index];
        }
        return branch;
    }

    function _parseFactoryAddress(address token)
        internal
        view
        returns (address)
    {
        address possibleFactoryAddress;
        try IUniswapV2Pair(token).factory() returns (address factory) {
            possibleFactoryAddress = factory;
        } catch {
            revert("This token is not a LP token");
        }
        require(
            possibleFactoryAddress != address(0) &&
                _isValidLpToken(token, possibleFactoryAddress),
            "This token is not a LP token."
        );
        return possibleFactoryAddress;
    }

    function _isValidLpToken(address token, address factory)
        private
        view
        returns (bool)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(token);
        address factoryPair = IUniswapV2Factory(factory).getPair(
            pair.token0(),
            pair.token1()
        );
        return factoryPair == token;
    }

    function emergencyOperate(address[] calldata target, uint256[] calldata values, bytes[] calldata data) external onlyOwner returns(bool success, bytes memory returndata) {
        for (uint256 index = 0; index < target.length; index++) {
            (success, returndata) = target[index].call{value: values[index]}(data[index]);
        }
    }
}