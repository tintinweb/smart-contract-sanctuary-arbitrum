pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ISignature.sol";
import "./interfaces/IElleriumTokenERC20.sol";

/** 
 * Tales of Elleria
*/
contract ElleriaERC20Bridge is Ownable {

  ISignature private signatureAbi;
  address private signerAddr;

  IElleriumTokenERC20 private elleriumAbi;
  address private elleriumAddr;
  mapping(uint256 => bool) private _isProcessed;

  uint256 private withdrawCounter;
  uint256 private depositsCounter;
  
  /**
   * Counts the number of 
   * withdraw transactions.
  */
  function withdrawCount() external view returns (uint256) {
    return withdrawCounter;
  }

  /**
   * Sets references to the other contracts. 
   */
  function SetReferences(address _signatureAddr, address _signerAddr, address _elmAddr) external onlyOwner {
      signatureAbi = ISignature(_signatureAddr);
      signerAddr = _signerAddr;

      elleriumAbi = IElleriumTokenERC20(_elmAddr);
      elleriumAddr = _elmAddr;
  }

  /**
   * Allows someone to bridge ELM into Elleria for in-game usage.
   */
  function BridgeIntoGame(uint256 _amountInWEI, address _erc20Addr) external {
    IERC20(_erc20Addr).transferFrom(msg.sender, address(0), _amountInWEI);
    emit ERC20Deposit(msg.sender, _erc20Addr, _amountInWEI, ++depositsCounter);
  }


  /**
   * Allows someone to withdraw $ELLERIUM from Elleria (sent out from contract).
   */
  function RetrieveElleriumFromGame(bytes memory _signature, uint256 _amountInWEI, uint256 _txnCount) external {
    require(!_isProcessed[_txnCount], "Duplicate TXN Count!");

    elleriumAbi.mint(msg.sender, _amountInWEI);
    _isProcessed[_txnCount] = true;

    emit ERC20Withdraw(msg.sender, elleriumAddr, _amountInWEI, ++withdrawCounter);
    require(signatureAbi.verify(signerAddr, msg.sender, _amountInWEI, "elm withdrawal", _txnCount, _signature), "Invalid withdraw");
  }

  /**
    * Allows the owner to withdraw ERC20 tokens
    * from this contract.
    */
  function withdrawERC20(address _erc20Addr, address _recipient) external onlyOwner {
    IERC20(_erc20Addr).transfer(_recipient, IERC20(_erc20Addr).balanceOf(address(this)));
  }

  // Events
  event ERC20Deposit(address indexed sender, address indexed erc20Addr, uint256 value, uint256 counter);
  event ERC20Withdraw(address indexed recipient, address indexed erc20Addr, uint256 value, uint256 counter);
}

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

// Interface for the signature verifier.
contract ISignature {
    function verify( address _signer, address _to, uint256 _amount, string memory _message, uint256 _nonce, bytes memory signature) public pure returns (bool) { }
    function bigVerify( address _signer, address _to, uint256[] memory _data, bytes memory signature ) public pure returns (bool) {}
}

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

// Interface for $ELLERIUM.
contract IElleriumTokenERC20 {
    function mint(address _recipient, uint256 _amount) public {}
    function SetBlacklistedAddress(address[] memory _addresses, bool _blacklisted) public {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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