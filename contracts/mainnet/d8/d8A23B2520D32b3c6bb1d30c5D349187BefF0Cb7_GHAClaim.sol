/**
 *Submitted for verification at Arbiscan on 2023-05-17
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: GHAClaim.sol


pragma solidity ^0.8.19;

contract GHAClaim {

  uint256 public releaseTime;
  bool public released = false;

  mapping (address => uint256) public amount;
  mapping (address => uint256) public claimed;

  IERC20 public GHA = IERC20(0xeCA66820ed807c096e1Bd7a1A091cD3D3152cC79);

    // assign mappings
    constructor() {
        amount[0xd2B954a0635096DdAadD7FF1D5A182198f02fcaE] = 1905 * 1e18;
        amount[0x08582F71815194ED765e9B1a0b0d84b3ceF057c6] = 2380 * 1e18;
        amount[0x6ED88188Da646B6fE64022895dE4045C35EbA48e] = 2865 * 1e18;
    }

    modifier onlyOwner() {
        require(msg.sender == 0xe7c48B9DD485Efa6bEf7831B562DDd6C10aEef95);
        _;
    }

  // release to be claimable
  function release() external onlyOwner {
    released = true;
    releaseTime = block.timestamp;
  }

  function claim() external {
    require(released);
    require(amount[msg.sender] != 0);
    uint256 unlocked = _unlocked(msg.sender);

    uint256 claiming = unlocked - claimed[msg.sender];
    require(claiming != 0);

    // update user claimed, transfer the tokens and emit event
    claimed[msg.sender] += claiming;
    GHA.transfer(msg.sender, claiming);
  }

  function _unlocked(address _beneficiary) public view returns (uint256) {
    uint256 claimable = amount[_beneficiary];
    // calculate time passed since last claimed and set the new time
    uint256 timePass = block.timestamp - releaseTime;
    if (timePass >= 7 days) {
      // fully unlocked
      return claimable;
    } else {
      return claimable * timePass / (7 days);
    }
  }

  // recover unsupported tokens accidentally sent to the contract itself
  function governanceRecoverUnsupported(IERC20 _token, address _to, uint256 _amount) external onlyOwner {
      _token.transfer(_to, _amount);
  }
}