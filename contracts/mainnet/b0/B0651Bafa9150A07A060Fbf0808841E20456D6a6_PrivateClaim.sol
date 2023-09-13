// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PrivateClaim {
  address public owner;
  uint256 public totalContributed;
  mapping(address => uint256) public coneAmount;
  mapping(address => uint256) public xConeAmount;

  address public coneAddress;
  address public xConeAddress;

  modifier onlyOwner() {
    require(msg.sender == owner, "Not the contract owner");
    _;
  }

  constructor(address _cone, address _xCone) {
    owner = msg.sender;
    coneAddress = _cone;
    xConeAddress = _xCone;
  }

  function contribute(
    address[] memory _contributor,
    uint256[] memory _coneAmount,
    uint256[] memory _xConeAmount
  ) public payable onlyOwner {
    require(_contributor.length == _coneAmount.length, "Array length mismatch");
    require(
      _contributor.length == _xConeAmount.length,
      "Array length mismatch"
    );
    for (uint256 i = 0; i < _contributor.length; i++) {
      require(_contributor[i] != address(0), "Invalid address");
      require(_coneAmount[i] > 0, "Invalid amount");
      require(_xConeAmount[i] > 0, "Invalid amount");
      coneAmount[_contributor[i]] = _coneAmount[i];
      xConeAmount[_contributor[i]] = _xConeAmount[i];
    }
  }

  function claim() external {
    require(coneAmount[msg.sender] > 0, "Nothing to claim");
    require(xConeAmount[msg.sender] > 0, "Nothing to claim");
    uint256 _coneAmount = coneAmount[msg.sender];
    uint256 _xConeAmount = xConeAmount[msg.sender];
    coneAmount[msg.sender] = 0;
    xConeAmount[msg.sender] = 0;
    IERC20(coneAddress).transfer(msg.sender, _coneAmount);
    IERC20(xConeAddress).transfer(msg.sender, _xConeAmount);
  }
}