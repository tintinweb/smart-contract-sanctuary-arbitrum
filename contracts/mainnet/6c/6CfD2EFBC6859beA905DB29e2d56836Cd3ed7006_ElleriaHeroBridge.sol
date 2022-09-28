pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IEllerianHero.sol";
import "./interfaces/IEllerianHeroUpgradeable.sol";
import "./interfaces/ISignature.sol";

/** 
 * Tales of Elleria
*/
contract ElleriaHeroBridge is Ownable {

  //IEllerianHero private ellerianHeroAbi;
  address private heroAddress;
  IEllerianHeroUpgradeable private upgradeableAbi;
  ISignature private signatureAbi;
  address private signerAddr;

  /**
  * Gets the original owner of a specific hero.
  */
  function GetOwnerOfTokenId(uint256 _tokenId) external view returns (address) {
      return IERC721(heroAddress).ownerOf(_tokenId);
  }

  /**
   * Links to our other contracts to get things working.
   */
  function SetAddresses(address _ellerianHeroAddr, address _upgradeableAddr, address _signatureAddr, address _signerAddr) external onlyOwner {
      //ellerianHeroAbi = IEllerianHero(_ellerianHeroAddr);
      heroAddress = _ellerianHeroAddr;
      upgradeableAbi = IEllerianHeroUpgradeable(_upgradeableAddr);
      signatureAbi = ISignature(_signatureAddr);
      signerAddr = _signerAddr;
      
  }

  /**
  * Sends a hero into Elleria (Metamask > Elleria)
  * Changed from transfer to https://www.erc721nes.org/.
  */
  function BridgeIntoGame(uint256[] memory _tokenIds) external {
    for (uint i = 0; i < _tokenIds.length; i++) {
        require(IERC721(heroAddress).ownerOf(_tokenIds[i]) == msg.sender, "SFF");
        upgradeableAbi.Stake(_tokenIds[i]);
    }
  }

  /**
  * Retrieves your hero out of Elleria (Elleria > Metamask)
  */
  function RetrieveFromGame(bytes memory _signature, uint256[] memory _tokenIds) external {
    uint256 tokenSum;
    for (uint i = 0; i < _tokenIds.length; i++) {
      require(IERC721(heroAddress).ownerOf(_tokenIds[i]) == msg.sender, "SFF");
      upgradeableAbi.Unstake(_tokenIds[i]);
      tokenSum = _tokenIds[i] + tokenSum;
    }

    require(signatureAbi.verify(signerAddr, msg.sender, _tokenIds.length, "withdrawal", tokenSum, _signature), "Invalid withdraw");
  }


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

// Interface for upgradeable logic.
contract IEllerianHeroUpgradeable {

    function GetHeroDetails(uint256 _tokenId) external view returns (uint256[9] memory) {}
    function GetHeroClass(uint256 _tokenId) external view returns (uint256) {}
    function GetHeroLevel(uint256 _tokenId) external view returns (uint256) {}
    function GetHeroName(uint256 _tokenId) external view returns (string memory) {}
    function GetHeroExperience(uint256 _tokenId) external view returns (uint256[2] memory) {}
    function GetAttributeRarity(uint256 _tokenId) external view returns (uint256) {}

    function GetUpgradeCost(uint256 _level) external view returns (uint256[2] memory) {}
    function GetUpgradeCostFromTokenId(uint256 _tokenId) public view returns (uint256[2] memory) {}

    function ResetHeroExperience(uint256 _tokenId, uint256 _exp) external {}
    function UpdateHeroExperience(uint256 _tokenId, uint256 _exp) external {}

    function SetHeroLevel (uint256 _tokenId, uint256 _level) external {}
    function SetNameChangeFee(uint256 _feeInWEI) external {}
    function SetHeroName(uint256 _tokenId, string memory _name) public {}

    function SynchronizeHero (bytes memory _signature, uint256[] memory _data) external {}
    function IsStaked(uint256 _tokenId) external view returns (bool) {}
    function Stake(uint256 _tokenId) external {}
    function Unstake(uint256 _tokenId) external {}

    function initHero(uint256 _tokenId, uint256 _str, uint256 _agi, uint256 _vit, uint256 _end, uint256 _intel, uint256 _will, uint256 _total, uint256 _class) external {}

    function AttemptHeroUpgrade(address sender, uint256 tokenId, uint256 goldAmountInEther, uint256 tokenAmountInEther) public {}
}

pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED

// Interface for Elleria's Heroes.
contract IEllerianHero {

  function safeTransferFrom (address _from, address _to, uint256 _tokenId) public {}
  function safeTransferFrom (address _from, address _to, uint256 _tokenId, bytes memory _data) public {}

  function mintUsingToken(address _recipient, uint256 _amount, uint256 _variant) public {}

  function burn (uint256 _tokenId, bool _isBurnt) public {}

  function ownerOf(uint256 tokenId) external view returns (address owner) {}
  function isApprovedForAll(address owner, address operator) external view returns (bool) {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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