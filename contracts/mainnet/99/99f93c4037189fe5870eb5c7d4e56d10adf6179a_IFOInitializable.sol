/**
 *Submitted for verification at Arbiscan on 2023-04-22
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

interface IIFOV2 {
    function depositPool(uint256 _amount, uint8 _pid) external;

    function harvestPool(uint8 _pid) external;

    function finalWithdraw(uint256 _lpAmount, uint256 _offerAmount) external;

    function setPool(
        uint256 _offeringAmountPool,
        uint256 _raisingAmountPool,
        uint256 _limitPerUserInLP,
        bool _hasTax,
        uint8 _pid
    ) external;

    function updatePointParameters(
        uint256 _campaignId,
        uint256 _numberPoints,
        uint256 _thresholdPoints
    ) external;

    function viewPoolInformation(uint256 _pid)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool,
            uint256,
            uint256
        );

    function viewPoolTaxRateOverflow(uint256 _pid) external view returns (uint256);

    function viewUserInfo(address _user, uint8[] calldata _pids)
        external
        view
        returns (uint256[] memory, bool[] memory);

    function viewUserAllocationPools(address _user, uint8[] calldata _pids) external view returns (uint256[] memory);

    function viewUserOfferingAndRefundingAmountsForPools(address _user, uint8[] calldata _pids)
        external
        view
        returns (uint256[3][] memory);
}

/**
 * @title IFOInitializable
 */
contract IFOInitializable is IIFOV2, ReentrancyGuard, Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // Number of pools
  uint8 public constant NUMBER_POOLS = 2;

  // The address of the smart chef factory
  address public immutable IFO_FACTORY;

  // Max blocks (for sanity checks)
  uint256 public MAX_BUFFER_BLOCKS;

  // The LP token used
  IERC20 public lpToken;

  // The offering token
  IERC20 public offeringToken;

  // Whether it is initialized
  bool public isInitialized;

  // The block number when IFO starts
  uint256 public startBlock;

  // The block number when IFO ends
  uint256 public endBlock;

  // The campaignId for the IFO
  uint256 public campaignId;

  // The number of points distributed to each person who harvest
  uint256 public numberPoints;

  // The threshold for points (in LP tokens)
  uint256 public thresholdPoints;

  // Total tokens distributed across the pools
  uint256 public totalTokensOffered;

  // Array of PoolCharacteristics of size NUMBER_POOLS
  PoolCharacteristics[NUMBER_POOLS] private _poolInformation;

  // Checks if user has claimed points
  mapping(address => bool) private _hasClaimedPoints;

  // It maps the address to pool id to UserInfo
  mapping(address => mapping(uint8 => UserInfo)) private _userInfo;

  // Struct that contains each pool characteristics
  struct PoolCharacteristics {
    uint256 raisingAmountPool; // amount of tokens raised for the pool (in LP tokens)
    uint256 offeringAmountPool; // amount of tokens offered for the pool (in offeringTokens)
    uint256 limitPerUserInLP; // limit of tokens per user (if 0, it is ignored)
    bool hasTax; // tax on the overflow (if any, it works with _calculateTaxOverflow)
    uint256 totalAmountPool; // total amount pool deposited (in LP tokens)
    uint256 sumTaxesOverflow; // total taxes collected (starts at 0, increases with each harvest if overflow)
  }

  // Struct that contains each user information for both pools
  struct UserInfo {
    uint256 amountPool; // How many tokens the user has provided for pool
    bool claimedPool; // Whether the user has claimed (default: false) for pool
  }

  // Admin withdraw events
  event AdminWithdraw(uint256 amountLP, uint256 amountOfferingToken);

  // Admin recovers token
  event AdminTokenRecovery(address tokenAddress, uint256 amountTokens);

  // Deposit event
  event Deposit(address indexed user, uint256 amount, uint8 indexed pid);

  // Harvest event
  event Harvest(address indexed user, uint256 offeringAmount, uint256 excessAmount, uint8 indexed pid);

  // Event for new start & end blocks
  event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);

  // Event with point parameters for IFO
  event PointParametersSet(uint256 campaignId, uint256 numberPoints, uint256 thresholdPoints);

  // Event when parameters are set for one of the pools
  event PoolParametersSet(uint256 offeringAmountPool, uint256 raisingAmountPool, uint8 pid);

  // Modifier to prevent contracts to participate
  modifier notContract() {
    require(!_isContract(msg.sender), "contract not allowed");
    require(msg.sender == tx.origin, "proxy contract not allowed");
    _;
  }

  /**
   * @notice Constructor
   */
  constructor() public {
    IFO_FACTORY = msg.sender;
  }

  /**
   * @notice It initializes the contract
   * @dev It can only be called once.
   * @param _lpToken: the LP token used
   * @param _offeringToken: the token that is offered for the IFO
   * @param _startBlock: the start block for the IFO
   * @param _endBlock: the end block for the IFO
   * @param _maxBufferBlocks: maximum buffer of blocks from the current block number
   * @param _adminAddress: the admin address for handling tokens
   */
  function initialize(
    address _lpToken,
    address _offeringToken,
    uint256 _startBlock,
    uint256 _endBlock,
    uint256 _maxBufferBlocks,
    address _adminAddress
  ) public {
    require(!isInitialized, "Operations: Already initialized");
    require(msg.sender == IFO_FACTORY, "Operations: Not factory");

    // Make this contract initialized
    isInitialized = true;

    lpToken = IERC20(_lpToken);
    offeringToken = IERC20(_offeringToken);
    startBlock = _startBlock;
    endBlock = _endBlock;
    MAX_BUFFER_BLOCKS = _maxBufferBlocks;

    // Transfer ownership to admin
    transferOwnership(_adminAddress);
  }

  /**
   * @notice It allows users to deposit LP tokens to pool
   * @param _amount: the number of LP token used (18 decimals)
   * @param _pid: pool id
   */
  function depositPool(uint256 _amount, uint8 _pid) external override nonReentrant notContract {
    // Checks whether the pool id is valid
    require(_pid < NUMBER_POOLS, "Deposit: Non valid pool id");

    // Checks that pool was set
    require(
      _poolInformation[_pid].offeringAmountPool > 0 && _poolInformation[_pid].raisingAmountPool > 0,
      "Deposit: Pool not set"
    );

    // Checks whether the block number is not too early
    require(block.number > startBlock, "Deposit: Too early");

    // Checks whether the block number is not too late
    require(block.number < endBlock, "Deposit: Too late");

    // Checks that the amount deposited is not inferior to 0
    require(_amount > 0, "Deposit: Amount must be > 0");

    // Verify tokens were deposited properly
    require(offeringToken.balanceOf(address(this)) >= totalTokensOffered, "Deposit: Tokens not deposited properly");

    // Transfers funds to this contract
    lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);

    // Update the user status
    _userInfo[msg.sender][_pid].amountPool = _userInfo[msg.sender][_pid].amountPool.add(_amount);

    // Check if the pool has a limit per user
    if (_poolInformation[_pid].limitPerUserInLP > 0) {
      // Checks whether the limit has been reached
      require(
        _userInfo[msg.sender][_pid].amountPool <= _poolInformation[_pid].limitPerUserInLP,
        "Deposit: New amount above user limit"
      );
    }

    // Updates the totalAmount for pool
    _poolInformation[_pid].totalAmountPool = _poolInformation[_pid].totalAmountPool.add(_amount);

    emit Deposit(msg.sender, _amount, _pid);
  }

  /**
   * @notice It allows users to harvest from pool
   * @param _pid: pool id
   */
  function harvestPool(uint8 _pid) external override nonReentrant notContract {
    // Checks whether it is too early to harvest
    require(block.number > endBlock, "Harvest: Too early");

    // Checks whether pool id is valid
    require(_pid < NUMBER_POOLS, "Harvest: Non valid pool id");

    // Checks whether the user has participated
    require(_userInfo[msg.sender][_pid].amountPool > 0, "Harvest: Did not participate");

    // Checks whether the user has already harvested
    require(!_userInfo[msg.sender][_pid].claimedPool, "Harvest: Already done");

    // Claim points if possible
    _claimPoints(msg.sender);

    // Updates the harvest status
    _userInfo[msg.sender][_pid].claimedPool = true;

    // Initialize the variables for offering, refunding user amounts, and tax amount
    (
      uint256 offeringTokenAmount,
      uint256 refundingTokenAmount,
      uint256 userTaxOverflow
    ) = _calculateOfferingAndRefundingAmountsPool(msg.sender, _pid);

    // Increment the sumTaxesOverflow
    if (userTaxOverflow > 0) {
      _poolInformation[_pid].sumTaxesOverflow = _poolInformation[_pid].sumTaxesOverflow.add(userTaxOverflow);
    }

    // Transfer these tokens back to the user if quantity > 0
    if (offeringTokenAmount > 0) {
      offeringToken.safeTransfer(address(msg.sender), offeringTokenAmount);
    }

    if (refundingTokenAmount > 0) {
      lpToken.safeTransfer(address(msg.sender), refundingTokenAmount);
    }

    emit Harvest(msg.sender, offeringTokenAmount, refundingTokenAmount, _pid);
  }

  /**
   * @notice It allows the admin to withdraw funds
   * @param _lpAmount: the number of LP token to withdraw (18 decimals)
   * @param _offerAmount: the number of offering amount to withdraw
   * @dev This function is only callable by admin.
   */
  function finalWithdraw(uint256 _lpAmount, uint256 _offerAmount) external override onlyOwner {
    require(_lpAmount <= lpToken.balanceOf(address(this)), "Operations: Not enough LP tokens");
    require(_offerAmount <= offeringToken.balanceOf(address(this)), "Operations: Not enough offering tokens");

    if (_lpAmount > 0) {
      lpToken.safeTransfer(address(msg.sender), _lpAmount);
    }

    if (_offerAmount > 0) {
      offeringToken.safeTransfer(address(msg.sender), _offerAmount);
    }

    emit AdminWithdraw(_lpAmount, _offerAmount);
  }

  /**
   * @notice It allows the admin to recover wrong tokens sent to the contract
   * @param _tokenAddress: the address of the token to withdraw (18 decimals)
   * @param _tokenAmount: the number of token amount to withdraw
   * @dev This function is only callable by admin.
   */
  function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
    require(_tokenAddress != address(lpToken), "Recover: Cannot be LP token");
    require(_tokenAddress != address(offeringToken), "Recover: Cannot be offering token");

    IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

    emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
  }

  /**
   * @notice It sets parameters for pool
   * @param _offeringAmountPool: offering amount (in tokens)
   * @param _raisingAmountPool: raising amount (in LP tokens)
   * @param _limitPerUserInLP: limit per user (in LP tokens)
   * @param _hasTax: if the pool has a tax
   * @param _pid: pool id
   * @dev This function is only callable by admin.
   */
  function setPool(
    uint256 _offeringAmountPool,
    uint256 _raisingAmountPool,
    uint256 _limitPerUserInLP,
    bool _hasTax,
    uint8 _pid
  ) external override onlyOwner {
    require(block.number < startBlock, "Operations: IFO has started");
    require(_pid < NUMBER_POOLS, "Operations: Pool does not exist");

    _poolInformation[_pid].offeringAmountPool = _offeringAmountPool;
    _poolInformation[_pid].raisingAmountPool = _raisingAmountPool;
    _poolInformation[_pid].limitPerUserInLP = _limitPerUserInLP;
    _poolInformation[_pid].hasTax = _hasTax;

    uint256 tokensDistributedAcrossPools;

    for (uint8 i = 0; i < NUMBER_POOLS; i++) {
      tokensDistributedAcrossPools = tokensDistributedAcrossPools.add(_poolInformation[i].offeringAmountPool);
    }

    // Update totalTokensOffered
    totalTokensOffered = tokensDistributedAcrossPools;

    emit PoolParametersSet(_offeringAmountPool, _raisingAmountPool, _pid);
  }

  /**
   * @notice It updates point parameters for the IFO.
   * @param _numberPoints: the number of points for the IFO
   * @param _campaignId: the campaignId for the IFO
   * @param _thresholdPoints: the amount of LP required to receive points
   * @dev This function is only callable by admin.
   */
  function updatePointParameters(
    uint256 _campaignId,
    uint256 _numberPoints,
    uint256 _thresholdPoints
  ) external override onlyOwner {
    require(block.number < endBlock, "Operations: IFO has ended");

    numberPoints = _numberPoints;
    campaignId = _campaignId;
    thresholdPoints = _thresholdPoints;

    emit PointParametersSet(campaignId, numberPoints, thresholdPoints);
  }

  /**
   * @notice It allows the admin to update start and end blocks
   * @param _startBlock: the new start block
   * @param _endBlock: the new end block
   * @dev This function is only callable by admin.
   */
  function updateStartAndEndBlocks(uint256 _startBlock, uint256 _endBlock) external onlyOwner {
    require(_endBlock < (block.number + MAX_BUFFER_BLOCKS), "Operations: EndBlock too far");
    require(block.number < startBlock, "Operations: IFO has started");
    require(_startBlock < _endBlock, "Operations: New startBlock must be lower than new endBlock");
    require(block.number < _startBlock, "Operations: New startBlock must be higher than current block");

    startBlock = _startBlock;
    endBlock = _endBlock;

    emit NewStartAndEndBlocks(_startBlock, _endBlock);
  }

  /**
   * @notice It returns the pool information
   * @param _pid: poolId
   * @return raisingAmountPool: amount of LP tokens raised (in LP tokens)
   * @return offeringAmountPool: amount of tokens offered for the pool (in offeringTokens)
   * @return limitPerUserInLP; // limit of tokens per user (if 0, it is ignored)
   * @return hasTax: tax on the overflow (if any, it works with _calculateTaxOverflow)
   * @return totalAmountPool: total amount pool deposited (in LP tokens)
   * @return sumTaxesOverflow: total taxes collected (starts at 0, increases with each harvest if overflow)
   */
  function viewPoolInformation(uint256 _pid)
    external
    view
    override
    returns (
      uint256,
      uint256,
      uint256,
      bool,
      uint256,
      uint256
    )
  {
    return (
      _poolInformation[_pid].raisingAmountPool,
      _poolInformation[_pid].offeringAmountPool,
      _poolInformation[_pid].limitPerUserInLP,
      _poolInformation[_pid].hasTax,
      _poolInformation[_pid].totalAmountPool,
      _poolInformation[_pid].sumTaxesOverflow
    );
  }

  /**
   * @notice It returns the tax overflow rate calculated for a pool
   * @dev 100,000,000,000 means 0.1 (10%) / 1 means 0.0000000000001 (0.0000001%) / 1,000,000,000,000 means 1 (100%)
   * @param _pid: poolId
   * @return It returns the tax percentage
   */
  function viewPoolTaxRateOverflow(uint256 _pid) external view override returns (uint256) {
    if (!_poolInformation[_pid].hasTax) {
      return 0;
    } else {
      return _calculateTaxOverflow(_poolInformation[_pid].totalAmountPool, _poolInformation[_pid].raisingAmountPool);
    }
  }

  /**
   * @notice External view function to see user allocations for both pools
   * @param _user: user address
   * @param _pids[]: array of pids
   * @return
   */
  function viewUserAllocationPools(address _user, uint8[] calldata _pids)
    external
    view
    override
    returns (uint256[] memory)
  {
    uint256[] memory allocationPools = new uint256[](_pids.length);
    for (uint8 i = 0; i < _pids.length; i++) {
      allocationPools[i] = _getUserAllocationPool(_user, _pids[i]);
    }
    return allocationPools;
  }

  /**
   * @notice External view function to see user information
   * @param _user: user address
   * @param _pids[]: array of pids
   */
  function viewUserInfo(address _user, uint8[] calldata _pids)
    external
    view
    override
    returns (uint256[] memory, bool[] memory)
  {
    uint256[] memory amountPools = new uint256[](_pids.length);
    bool[] memory statusPools = new bool[](_pids.length);

    for (uint8 i = 0; i < NUMBER_POOLS; i++) {
      amountPools[i] = _userInfo[_user][i].amountPool;
      statusPools[i] = _userInfo[_user][i].claimedPool;
    }
    return (amountPools, statusPools);
  }

  /**
   * @notice External view function to see user offering and refunding amounts for both pools
   * @param _user: user address
   * @param _pids: array of pids
   */
  function viewUserOfferingAndRefundingAmountsForPools(address _user, uint8[] calldata _pids)
    external
    view
    override
    returns (uint256[3][] memory)
  {
    uint256[3][] memory amountPools = new uint256[3][](_pids.length);

    for (uint8 i = 0; i < _pids.length; i++) {
      uint256 userOfferingAmountPool;
      uint256 userRefundingAmountPool;
      uint256 userTaxAmountPool;

      if (_poolInformation[_pids[i]].raisingAmountPool > 0) {
        (
          userOfferingAmountPool,
          userRefundingAmountPool,
          userTaxAmountPool
        ) = _calculateOfferingAndRefundingAmountsPool(_user, _pids[i]);
      }

      amountPools[i] = [userOfferingAmountPool, userRefundingAmountPool, userTaxAmountPool];
    }
    return amountPools;
  }

  /**
   * @notice It allows users to claim points
   * @param _user: user address
   */
  function _claimPoints(address _user) internal {
    if (!_hasClaimedPoints[_user]) {
      uint256 sumPools;
      for (uint8 i = 0; i < NUMBER_POOLS; i++) {
        sumPools = sumPools.add(_userInfo[msg.sender][i].amountPool);
      }
      if (sumPools > thresholdPoints) {
        _hasClaimedPoints[_user] = true;
        // Increase user points
      }
    }
  }

  /**
   * @notice It calculates the tax overflow given the raisingAmountPool and the totalAmountPool.
   * @dev 100,000,000,000 means 0.1 (10%) / 1 means 0.0000000000001 (0.0000001%) / 1,000,000,000,000 means 1 (100%)
   * @return It returns the tax percentage
   */
  function _calculateTaxOverflow(uint256 _totalAmountPool, uint256 _raisingAmountPool) internal pure returns (uint256) {
    uint256 ratioOverflow = _totalAmountPool.div(_raisingAmountPool);

    if (ratioOverflow >= 500) {
      return 2000000000; // 0.2%
    } else if (ratioOverflow >= 250) {
      return 2500000000; // 0.25%
    } else if (ratioOverflow >= 100) {
      return 3000000000; // 0.3%
    } else if (ratioOverflow >= 50) {
      return 5000000000; // 0.5%
    } else {
      return 10000000000; // 1%
    }
  }

  /**
   * @notice It calculates the offering amount for a user and the number of LP tokens to transfer back.
   * @param _user: user address
   * @param _pid: pool id
   * @return {uint256, uint256, uint256} It returns the offering amount, the refunding amount (in LP tokens),
   * and the tax (if any, else 0)
   */
  function _calculateOfferingAndRefundingAmountsPool(address _user, uint8 _pid)
    internal
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 userOfferingAmount;
    uint256 userRefundingAmount;
    uint256 taxAmount;

    if (_poolInformation[_pid].totalAmountPool > _poolInformation[_pid].raisingAmountPool) {
      // Calculate allocation for the user
      uint256 allocation = _getUserAllocationPool(_user, _pid);

      // Calculate the offering amount for the user based on the offeringAmount for the pool
      userOfferingAmount = _poolInformation[_pid].offeringAmountPool.mul(allocation).div(1e12);

      // Calculate the payAmount
      uint256 payAmount = _poolInformation[_pid].raisingAmountPool.mul(allocation).div(1e12);

      // Calculate the pre-tax refunding amount
      userRefundingAmount = _userInfo[_user][_pid].amountPool.sub(payAmount);

      // Retrieve the tax rate
      if (_poolInformation[_pid].hasTax) {
        uint256 taxOverflow = _calculateTaxOverflow(
          _poolInformation[_pid].totalAmountPool,
          _poolInformation[_pid].raisingAmountPool
        );

        // Calculate the final taxAmount
        taxAmount = userRefundingAmount.mul(taxOverflow).div(1e12);

        // Adjust the refunding amount
        userRefundingAmount = userRefundingAmount.sub(taxAmount);
      }
    } else {
      userRefundingAmount = 0;
      taxAmount = 0;
      // _userInfo[_user] / (raisingAmount / offeringAmount)
      userOfferingAmount = _userInfo[_user][_pid].amountPool.mul(_poolInformation[_pid].offeringAmountPool).div(
        _poolInformation[_pid].raisingAmountPool
      );
    }
    return (userOfferingAmount, userRefundingAmount, taxAmount);
  }

  /**
   * @notice It returns the user allocation for pool
   * @dev 100,000,000,000 means 0.1 (10%) / 1 means 0.0000000000001 (0.0000001%) / 1,000,000,000,000 means 1 (100%)
   * @param _user: user address
   * @param _pid: pool id
   * @return it returns the user's share of pool
   */
  function _getUserAllocationPool(address _user, uint8 _pid) internal view returns (uint256) {
    if (_poolInformation[_pid].totalAmountPool > 0) {
      return _userInfo[_user][_pid].amountPool.mul(1e18).div(_poolInformation[_pid].totalAmountPool.mul(1e6));
    } else {
      return 0;
    }
  }

  /**
   * @notice Check if an address is a contract
   */
  function _isContract(address _addr) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(_addr)
    }
    return size > 0;
  }
}


contract IFODeployer is Ownable {
  using SafeERC20 for IERC20;

  uint256 public constant MAX_BUFFER_BLOCKS = 200000; // 200,000 blocks (6-7 days on BSC)

  event AdminTokenRecovery(address indexed tokenRecovered, uint256 amount);
  event NewIFOContract(address indexed ifoAddress);

  /**
   * @notice It creates the IFO contract and initializes the contract.
   * @param _lpToken: the LP token used
   * @param _offeringToken: the token that is offered for the IFO
   * @param _startBlock: the start block for the IFO
   * @param _endBlock: the end block for the IFO
   * @param _adminAddress: the admin address for handling tokens
   */
  function createIFO(
    address _lpToken,
    address _offeringToken,
    uint256 _startBlock,
    uint256 _endBlock,
    address _adminAddress
  ) external onlyOwner {
    require(IERC20(_lpToken).totalSupply() >= 0);
    require(IERC20(_offeringToken).totalSupply() >= 0);
    require(_lpToken != _offeringToken, "Operations: Tokens must be be different");
    require(_endBlock < (block.number + MAX_BUFFER_BLOCKS), "Operations: EndBlock too far");
    require(_startBlock < _endBlock, "Operations: StartBlock must be inferior to endBlock");
    require(_startBlock > block.number, "Operations: StartBlock must be greater than current block");

    bytes memory bytecode = type(IFOInitializable).creationCode;
    bytes32 salt = keccak256(abi.encodePacked(_lpToken, _offeringToken, _startBlock));
    address ifoAddress;

    assembly {
      ifoAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }

    IFOInitializable(ifoAddress).initialize(
      _lpToken,
      _offeringToken,
      _startBlock,
      _endBlock,
      MAX_BUFFER_BLOCKS,
      _adminAddress
    );

    emit NewIFOContract(ifoAddress);
  }

  /**
   * @notice It allows the admin to recover wrong tokens sent to the contract
   * @param _tokenAddress: the address of the token to withdraw
   * @dev This function is only callable by admin.
   */
  function recoverWrongTokens(address _tokenAddress) external onlyOwner {
    uint256 balanceToRecover = IERC20(_tokenAddress).balanceOf(address(this));
    require(balanceToRecover > 0, "Operations: Balance must be > 0");
    IERC20(_tokenAddress).safeTransfer(address(msg.sender), balanceToRecover);

    emit AdminTokenRecovery(_tokenAddress, balanceToRecover);
  }
}