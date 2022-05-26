// contracts/GameRelics.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IEllerianRelics.sol";
import "./interfaces/ISignature.sol";

/** 
 * Tales of Elleria
*/
contract EllerianRelicBridge is Ownable {

  IEllerianRelics private relicsAbi;
  ISignature private signatureAbi;
  address private signerAddr;

  mapping(uint256 => bool) private _isProcessed;

  uint256 private withdrawCounter;
  uint256 private depositsCounter;


  /**
   * Links to our other contracts to get things working.
   */
  function SetAddresses(address _relicsAddr, address _signatureAddr, address _signerAddr) external onlyOwner {
    relicsAbi = IEllerianRelics(_relicsAddr);
    signatureAbi = ISignature(_signatureAddr);
    signerAddr = _signerAddr;
      
  }

  /**
  * Burns relic so they appear in your Elleria inventory.
  */
  function BridgeIntoGame(uint256[] memory _ids, uint256[] memory _amounts) external {
    relicsAbi.burnBatch(msg.sender, _ids, _amounts);
    emit RelicBridged(msg.sender, _ids, _amounts, ++depositsCounter);
  }
  
  /**
   * Counts the number of 
   * withdraw transactions.
  */
  function withdrawCount() external view returns (uint256) {
    return withdrawCounter;
  }

  /**
  * Mints relics from Elleria into your Metamask wallet.
  */
  function RetrieveFromGame(bytes[] memory _signatures, uint256[] memory _ids, uint256[] memory _amounts, uint256 _txnCount) external {
    require(!_isProcessed[_txnCount], "Duplicate TXN Count!");
    _isProcessed[_txnCount] = true;

    for (uint i = 0; i < _ids.length; i++) {
      require(signatureAbi.verify(signerAddr, msg.sender, _ids[i] * _amounts[i], "relicwithdrawal", _txnCount, _signatures[i]), "Invalid relic withdraw");
    }

    relicsAbi.mintBatch(msg.sender, _ids, _amounts);
    emit RelicRetrieved(msg.sender, _ids, _amounts, ++withdrawCounter);
  }

    event RelicBridged(address _from, uint256[] ids, uint256[] amounts, uint256 counter);
    event RelicRetrieved(address _from, uint256[] ids, uint256[] amounts, uint256 counter);
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

// Interface for Ellerian Relics.
contract IEllerianRelics {
    function mint(address to, uint256 id, uint256 amount) external { }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external {}

    function burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) external {}

    function externalMint(address to, uint256 id, uint256 amount) external {}
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