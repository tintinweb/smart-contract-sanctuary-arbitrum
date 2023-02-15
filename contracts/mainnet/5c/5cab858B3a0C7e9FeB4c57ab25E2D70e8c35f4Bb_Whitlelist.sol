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

pragma solidity 0.8.11;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function decimals() external view returns (uint8);

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

pragma solidity 0.8.11;

contract Governable {
    address public gov;

    constructor() {
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
pragma solidity 0.8.11;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Governable } from "./libraries/Governable.sol";
import { IERC20 } from "./interfaces/IERC20.sol";

contract Whitlelist is ReentrancyGuard, Governable {
    bool public isDeposit;
    bool public isClaimWhitelist;
    bool public isClaimAirdropToken;

    uint256 public amountDeposit = 5 * 10 ** 18;
    uint256 public totalDeposit;
    uint256 public totalClaim;
    uint256 public totalAirdrop;
    uint256 public amountAirdrop = 5 * 10 ** 18;
    address public tokenDeposit;
    address public tokenGov;

    mapping (address => uint256) public depositUsers;
    mapping (address => bool) public isClaimTokenDeposit;
    mapping (address => bool) public isClaimTokenGov;

    event Deposit(address indexed account, uint256 amount);
    event ClaimWhitlelist(address indexed account, uint256 amount);
    event ClaimAirdropToken(address indexed account, uint256 amount);

    constructor(address _tokenDeposit, address _tokenGov) {
      tokenDeposit = _tokenDeposit;
      tokenGov = _tokenGov;
    }

    function setWhitlelistStatus(bool _isDeposit, bool _isClaimWhitelist, bool _isClaimAirdropToken) external onlyGov {
      isDeposit = _isDeposit;
      isClaimWhitelist = _isClaimWhitelist;
      isClaimAirdropToken = _isClaimAirdropToken;
    }
    
    function setTokens(address _tokenDeposit, address _tokenGov) external onlyGov {
      tokenDeposit = _tokenDeposit;
      tokenGov = _tokenGov;
    }

    function setTokensAmount(uint256 _amountDeposit, uint256 _amountAirdrop) external onlyGov {
      amountDeposit = _amountDeposit;
      amountAirdrop = _amountAirdrop;
    }

    function deposit(uint256 _amount) external {
      require(isDeposit, "Whitlelist: deposit not active");
      require(_amount == amountDeposit, "Whitlelist: amount equal amountDeposit");
      require(depositUsers[msg.sender] == 0, "Whitlelist: user already in whitlelist");

      IERC20(tokenDeposit).transferFrom(msg.sender, address(this), amountDeposit);
      depositUsers[msg.sender] = amountDeposit;
      totalDeposit += amountDeposit;

      emit Deposit(msg.sender, amountDeposit);
    }

    function withDrawnFund(uint256 _amount) external onlyGov {
      IERC20(tokenDeposit).transfer(msg.sender, _amount);
    }

    function claimWhitlelist() external {
      require(isClaimWhitelist, "Whitlelist: claim token not active");
      require(depositUsers[msg.sender] > 0, "Whitlelist: user don't have balance");
      require(!isClaimTokenDeposit[msg.sender], "Whitlelist: user already claim token");
      require(IERC20(tokenDeposit).balanceOf(address(this)) >= amountDeposit, "Whitlelist: not enough balance");
      
      IERC20(tokenDeposit).transfer(msg.sender, amountDeposit);
      isClaimTokenDeposit[msg.sender] = true;
      totalClaim += amountDeposit;
      emit ClaimWhitlelist(msg.sender, amountDeposit);
    }

    function claimAirdropToken() external {
      require(isClaimAirdropToken, "Whitlelist: claim token not active");
      require(depositUsers[msg.sender] > 0, "Whitlelist: user don't have balance");
      require(!isClaimTokenGov[msg.sender], "Whitlelist: user already claim token");
      require(IERC20(tokenGov).balanceOf(address(this)) >= amountAirdrop, "Whitlelist: not enough balance");

      IERC20(tokenGov).transfer(msg.sender, amountAirdrop);
      isClaimTokenGov[msg.sender] = true;
      totalAirdrop += amountAirdrop;

      emit ClaimAirdropToken(msg.sender, amountAirdrop);
    }

    /**
     * @notice Allows the owner to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @dev Callable by owner
     */
    function recoverFungibleTokens(address _token) external onlyGov {
        uint256 amountToRecover = IERC20(_token).balanceOf(address(this));
        require(amountToRecover != 0, "Operations: No token to recover");

        IERC20(_token).transfer(address(msg.sender), amountToRecover);
    }
}