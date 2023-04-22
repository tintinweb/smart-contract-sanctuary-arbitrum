/**
 *Submitted for verification at Arbiscan on 2023-04-22
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
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

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

interface IReferral {
  function setMasterChef(address _masterChef) external;

  function activate(address referrer) external;

  function activateBySign(
    address referee,
    address referrer,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function isActivated(address _address) external view returns (bool);

  function updateReferralReward(address accountAddress, uint256 reward) external;

  function claimReward() external;
}

contract Referral is IReferral, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct Account {
    address referrer;
    uint256 reward;
    uint256 accumReward;
    uint256 referredCount;
    uint256 activeTime;
  }

  event Activate(address referee, address referrer);
  event ClaimReward(address accountAddress, uint256 reward);
  event UpdateReferralReward(address referee, address referrer, uint256 reward);
  event UpdateMasterChef(address masterChef);

  // MasterChef address.
  address public masterChef;
  // DOGSHIT token.
  IERC20 public token;
  // Info of each account
  mapping(address => Account) public accounts;
  // Total rewards distributed
  uint256 public totalReward;
  // Total rewards transferred to this contract
  uint256 public totalRewardTransferred;

  bytes32 public DOMAIN_SEPARATOR;
  // keccak256("Activate(address referee,address referrer)")
  bytes32 public constant ACTIVATE_TYPEHASH = 0x4b1fc20d2fd2102f86b90df2c22a6641f5ef4f7fd96d33e36ab9bd6fbad1cf30;

  constructor(address _tokenAddress) public {
    require(
      _tokenAddress != address(0) && _tokenAddress != address(1),
      "Referral::constructor::_tokenAddress must not be address(0) or address(1)"
    );

    token = IERC20(_tokenAddress);

    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("Referral"),
        keccak256("1"),
        chainId,
        address(this)
      )
    );
  }

  // Only MasterChef can continue the execution
  modifier onlyMasterChef() {
    require(msg.sender == masterChef, "only masterChef");
    _;
  }

  // Update MasterChef address
  function setMasterChef(address _masterChef) public override onlyOwner {
    require(_masterChef != address(0), "invalid _masterChef");

    masterChef = _masterChef;
    emit UpdateMasterChef(_masterChef);
  }

  // Activates sender
  function activate(address referrer) external override {
    _activate(msg.sender, referrer);
  }

  // Delegates activates from signatory to `referee`
  function activateBySign(
    address referee,
    address referrer,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override {
    bytes32 digest = keccak256(
      abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(ACTIVATE_TYPEHASH, referee, referrer)))
    );
    address signer = ecrecover(digest, v, r, s);
    require(signer == referee, "invalid signature");

    _activate(referee, referrer);
  }

  // Internal function to activate `referee`
  function _activate(address referee, address referrer) internal {
    require(referee != address(0), "invalid referee");
    require(referee != referrer, "referee = referrer");
    require(accounts[referee].activeTime == 0, "referee account have been activated");
    if (referrer != address(0)) {
      require(accounts[referrer].activeTime > 0, "referrer account is not activated");
    }

    accounts[referee].referrer = referrer;
    accounts[referee].activeTime = block.timestamp;
    if (referrer != address(0)) {
      accounts[referrer].referredCount = accounts[referrer].referredCount.add(1);
    }

    emit Activate(referee, referrer);
  }

  // Function for check whether an address has activated
  function isActivated(address _address) public view override returns (bool) {
    return accounts[_address].activeTime > 0;
  }

  // Function for letting some observer call when some conditions met
  // Currently, the caller will MasterChef after transferring the DOGSHIT reward
  function updateReferralReward(address accountAddress, uint256 reward) external override onlyMasterChef {
    totalRewardTransferred = totalRewardTransferred.add(reward);
    if (accounts[accountAddress].referrer != address(0)) {
      Account storage referrerAccount = accounts[accounts[accountAddress].referrer];
      referrerAccount.reward = referrerAccount.reward.add(reward);
      totalReward = totalReward.add(reward);

      emit UpdateReferralReward(accountAddress, accounts[accountAddress].referrer, reward);
    }
  }

  // Claim DOGSHIT earned
  function claimReward() external override nonReentrant {
    require(accounts[msg.sender].activeTime > 0, "account is not activated");
    require(accounts[msg.sender].reward > 0, "reward amount = 0");

    Account storage account = accounts[msg.sender];
    uint256 pendingReward = account.reward;
    account.reward = account.reward.sub(pendingReward);
    account.accumReward = account.accumReward.add(pendingReward);
    token.safeTransfer(address(msg.sender), pendingReward);

    emit ClaimReward(msg.sender, pendingReward);
  }
}