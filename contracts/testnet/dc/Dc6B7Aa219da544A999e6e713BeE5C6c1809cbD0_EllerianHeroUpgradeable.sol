pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IVRFHelper.sol";
import "./IEllerianHero.sol";
import "./ISignature.sol";

contract IHeroBridge {
 function GetOwnerOfTokenId(uint256 _tokenId) external view returns (address) {}
}

/** 
 * Tales of Elleria
*/
contract EllerianHeroUpgradeable is Ownable {
  uint256[] private fail_probability = [0, 0, 0, 0, 10, 20, 25, 30, 35, 40, 50, 60, 60, 60, 60];
  uint256[] private upgrade_gold_cost = [0, 20000, 50000, 150000, 450000, 1000000, 2000000, 5000000, 10000000, 20000000, 50000000, 100000000, 100000000, 100000000, 100000000];
  uint256[] private upgrade_token_cost = [0, 0, 0, 0, 5, 50, 100, 500, 1000, 1000, 2000, 5000, 5000, 5000, 10000];
  uint256[] private experience_needed = [0, 0, 50, 150, 450, 1000, 2000, 3000, 4000, 8000, 10000, 12000, 14000, 16000, 50000];

  uint256[] private attributesRarity = [0, 300, 400];

  mapping(uint256 => uint256) private heroExperience;
  mapping(uint256 => uint256) private heroLevel;
  mapping(uint256 => string) private heroName;


  uint256 private nameChangeFee = (100000 * 10 ** 18);

  mapping (address => bool) private _approvedAddresses;
  
  // The hero's attributes.
  struct heroAttributes {
    uint256 str;          // Strength =     PHYSICAL ATK
    uint256 agi;          // Agility =      HIT RATE
    uint256 vit;          // Vitality =     HEALTH
    uint256 end;          // Endurance =    PHYSICAL DEFENSE
    uint256 intel;        // Intelligence = MAGIC ATK
    uint256 will;         // Will =         MAGIC DEFENSE
    uint256 total;        // Total Attributes 
    uint256 class;        // Class
    uint256 tokenid;      // Token ID
    uint256 summonedTime; // Time of Mint
  }

  mapping(uint256 => heroAttributes) private heroDetails;  // Keeps track of each hero's attributes.

  address private minterAddress;
  address private tokenAddress;
  address private goldAddress;
  address private feesAddress;
  address private signerAddr;
  IHeroBridge private heroBridgeAbi;
  ISignature private signatureAbi;
  IVRFHelper vrfAbi;
  
  /**
   * Adjust the attribute rarity threshold if required .
   */
  function SetAttributeRarity(uint256[] memory _attributes) external {
    require(_approvedAddresses[msg.sender], "17");

    attributesRarity = _attributes;

    emit AttributeRarityChange(msg.sender, _attributes);
  }

    
  /**
   * Allows the name change fee to be changed.
   */
  function SetNameChangeFee(uint256 _feeInWEI) external {
    require(_approvedAddresses[msg.sender], "17");
    nameChangeFee = _feeInWEI;

    emit RenamingFeeChange(msg.sender, _feeInWEI);
  }

  /**
   * Allows the different contracts to be linked.
   */
  function SetAddresses(address _minterAddress, address _goldAddress,  address _tokenAddress, 
  address _signatureAddr, address _feesAddress, address _vrfAddress, address _signerAddr,
  address _heroBridgeAddr) external onlyOwner {
      minterAddress = _minterAddress;
      goldAddress = _goldAddress;
      tokenAddress = _tokenAddress;
      feesAddress = _feesAddress;
      signerAddr = _signerAddr;

      heroBridgeAbi = IHeroBridge(_heroBridgeAddr);
      signatureAbi = ISignature(_signatureAddr);
      vrfAbi = IVRFHelper(_vrfAddress);
  }

  /**
    * Approves the specified addresses
    * for administrative functions.
    */
  function SetApprovedAddress(address _address, bool _allowed) public onlyOwner {
      _approvedAddresses[_address] = _allowed;
  }

  /**
    * Sets the upgrade costs and requirements.
    */
  function SetUpgradeRequirements(uint256[] memory _new_gold_costs_in_ether, uint256[] memory _new_token_costs_in_ether, uint256[] memory _new_chances) external onlyOwner {
    upgrade_gold_cost = _new_gold_costs_in_ether;
    upgrade_token_cost = _new_token_costs_in_ether;
    fail_probability = _new_chances;

    emit UpgradeRequirementsChanged(msg.sender, _new_gold_costs_in_ether, _new_token_costs_in_ether, _new_chances);
  }

  /**
    * Sets the requirements needed to level up.
    */
  function SetEXPRequiredForLevelUp(uint256[] memory _new_exp) external onlyOwner {
    experience_needed = _new_exp;
    emit ExpRequirementsChanged(msg.sender, _new_exp);
  }

  /**
    * Allows the hero's name to be changed.
    * Must be called directly from a wallet.
    */
  function SetHeroName(uint256 _tokenId, string memory _name) public {
    require(IERC721(minterAddress).ownerOf(_tokenId) == tx.origin, "22");
    heroName[_tokenId] = _name;

    IERC20(goldAddress).transferFrom(tx.origin, feesAddress, nameChangeFee);
    emit NameChange(msg.sender, _tokenId, _name);
  }

  /**
   * Changes the attributes and emits an event to
   * make transparent all attribute updates.
   */
  function UpdateAttributes(uint256 _tokenId, uint256 _str, uint256 _agi, uint256 _vit, uint256 _end, uint256 _intel, uint256 _will) external {
    require(_approvedAddresses[msg.sender], "21");

    heroDetails[_tokenId].str = _str;
    heroDetails[_tokenId].agi = _agi;
    heroDetails[_tokenId].vit = _vit;
    heroDetails[_tokenId].end = _end;
    heroDetails[_tokenId].intel = _intel;
    heroDetails[_tokenId].will = _will;
    heroDetails[_tokenId].total = _str + _agi + _vit + _end + _intel + _will;

    emit AttributeChange(msg.sender, _tokenId, _str, _agi, _vit, _end, _intel, _will);
  }

  /**
   * Gets the attributes for a specific hero.
   */
  function GetHeroDetails(uint256 _tokenId) external view returns (uint256[9] memory) {
    return [heroDetails[_tokenId].str, heroDetails[_tokenId].agi, heroDetails[_tokenId].vit, 
    heroDetails[_tokenId].end, heroDetails[_tokenId].intel, heroDetails[_tokenId].will, 
    heroDetails[_tokenId].total, heroDetails[_tokenId].class, heroDetails[_tokenId].summonedTime];
  }

  /**
   * Gets only the class for a specific hero.
   */
  function GetHeroClass(uint256 _tokenId) external view returns (uint256) {
    return heroDetails[_tokenId].class;
  }

  /**
   * Gets only the level for a specific hero.
   */
  function GetHeroLevel(uint256 _tokenId) external view returns (uint256) {
    return heroLevel[_tokenId];
  }
  
  /**
   * Gets the upgrade cost for a specific level.
   */
  function GetUpgradeCost(uint256 _level) external view returns (uint256[2] memory) {
    return [upgrade_gold_cost[_level], upgrade_token_cost[_level]];
  }

  /**
   * Gets the upgrade cost for a specific hero.
   */
  function GetUpgradeCostFromTokenId(uint256 _tokenId) public view returns (uint256[2] memory) {
    return [upgrade_gold_cost[heroLevel[_tokenId]], upgrade_token_cost[heroLevel[_tokenId]]];
  }

  /**
   * Gets the experience a certain hero has.
   */
  function GetHeroExperience(uint256 _tokenId) external view returns (uint256[2] memory) {
    return [heroExperience[_tokenId], experience_needed[heroLevel[_tokenId]]];
  }
  
  /**
   * Resets a hero's experience to its starting point.
   */
  function ResetHeroExperience(uint256 _tokenId, uint256 _exp) external {
      require(_approvedAddresses[msg.sender], "18");
      heroExperience[_tokenId] = _exp;

      emit ExpChange(msg.sender, _tokenId, _exp);
  }

  /**
   * Gets the name for a specific hero.
   */
  function GetHeroName(uint256 _tokenId) external view returns (string memory) {
    return heroName[_tokenId];
  }

  /**
  * Gets the exp required to upgrade for a certain level.
  */
  function GetEXPRequiredForLevelUp(uint256 _level) external view returns (uint256) {
    return experience_needed[_level];
  }

  /**
    * Gets the probability to fail an upgrade for a certain level.
    */
  function GetFailProbability(uint256 _level) external view returns (uint256) {
    return fail_probability[_level];
  }

  /**
   * Adjust the attribute rarity threshold if required .
   */
  function GetAttributeRarity(uint256 _tokenId) external view returns (uint256) {
    uint256 _totalAttributes = heroDetails[_tokenId].total;

    if (_totalAttributes < attributesRarity[1])
      return 0;
    else if (_totalAttributes < attributesRarity[2])
      return 1;

    return 2;
  }

  /**
   * Rewards a certain hero with experience.
   */
  function UpdateHeroExperience(uint256 _tokenId, uint256 _exp) external {
    require(_approvedAddresses[msg.sender], "7");
    heroExperience[_tokenId] = heroExperience[_tokenId] + _exp;

    emit ExpChange(msg.sender, _tokenId, heroExperience[_tokenId]);
  }

  /**
   * Sets the level for a specific hero.
   * Emits an event so abuse can be tracked.
   */
  function SetHeroLevel (uint256 _tokenId, uint256 _level) external {
    require(_approvedAddresses[msg.sender], "17");
    heroLevel[_tokenId] = _level;

    emit LevelChange(msg.sender, _tokenId, _level, 0, 0);
  }

  /**
   * Synchronizes a hero's stats from Elleria
   * onto the blockchain.
   */
  function SynchronizeHero (bytes memory _signature, uint256 _tokenId, uint256 _level, uint256 _exp) external {
    require (heroBridgeAbi.GetOwnerOfTokenId(_tokenId) == msg.sender, "22");

    if (heroLevel[_tokenId] != _level) {
      emit LevelChange(signerAddr, _tokenId, _level, 0, 0);
      heroLevel[_tokenId] = _level;
    }

    if (heroExperience[_tokenId] != _exp) {
      emit ExpChange(signerAddr, _tokenId, _exp);
      heroExperience[_tokenId] = _exp;
    }

    require(signatureAbi.verify(signerAddr, msg.sender, _tokenId, Strings.toString(_level), _exp, _signature), "Invalid Sync");
  }

  /**
    * Allows someone to attempt an upgrade on his hero.
    * Must be called directly from a wallet.
    */  
  function AttemptHeroUpgrade(uint256 _tokenId, uint256 _goldAmountInEther, uint256 _tokenAmountInEther) public {
      require (IERC721(minterAddress).ownerOf(_tokenId) == tx.origin, "22");
      require(msg.sender == tx.origin, "9");

      // Transfer $MEDALS
      uint256 correctAmount = _goldAmountInEther * 1e18;
      IERC20(goldAddress).transferFrom(tx.origin, feesAddress, correctAmount);

      // Transfer $ELLERIUM
      correctAmount = _tokenAmountInEther * 1e18;
      if (correctAmount > 0) {
      IERC20(tokenAddress).transferFrom(tx.origin, feesAddress, correctAmount);
      }

      // Attempts the upgrade.
      uint256 level = updateLevel(_tokenId, _goldAmountInEther, _tokenAmountInEther);

      emit Upgrade(msg.sender, _tokenId, level);
  }

  /**
    * Rolls a number to check if the upgrade succeeds.
    */
  function updateLevel(uint256 _tokenId, uint256 _goldAmountInEther, uint256 _tokenAmountInEther) internal returns (uint256) {
      uint256[2] memory UpgradeCosts = GetUpgradeCostFromTokenId(_tokenId);
      require(_goldAmountInEther == UpgradeCosts[0], "ERR4");
      require(_tokenAmountInEther == UpgradeCosts[1], "ERR5");
      require(heroExperience[_tokenId] >= experience_needed[heroLevel[_tokenId]], "ERR6");

      uint256 randomNumber = vrfAbi.GetVRF(_tokenId) % 100;
      if (randomNumber >= fail_probability[heroLevel[_tokenId]]) {
        heroLevel[_tokenId] = heroLevel[_tokenId] + 1;
        emit LevelChange(msg.sender, _tokenId, heroLevel[_tokenId], _goldAmountInEther, _tokenAmountInEther);
      }

      return heroLevel[_tokenId];
  }

  /**
    * Initializes the hero upon minting.
    */
  function initHero(uint256 _tokenId, uint256 _str, uint256 _agi, uint256 _vit, uint256 _end,
  uint256 _intel, uint256 _will, uint256 _total, uint256 _class) external {
    require(_approvedAddresses[msg.sender], "36");
    heroName[_tokenId] = "Hero";
    heroLevel[_tokenId] = 1;

    heroDetails[_tokenId] = heroAttributes({
      str: _str,
      agi: _agi, 
      vit: _vit,
      end: _end,
      intel: _intel,
      will: _will,
      total: _total,
      class: _class,
      tokenid: _tokenId,
      summonedTime: block.timestamp
      });

    emit AttributeChange(msg.sender, _tokenId, _str, _agi, _vit, _end, _intel, _will);
  }

  event AttributeRarityChange(address _from, uint256[] _newRarity);
  event RenamingFeeChange(address _from, uint256 _newFee);
  event UpgradeRequirementsChanged(address _from, uint256[] _new_gold_costs_in_ether, uint256[] _new_token_costs_in_ether, uint256[] _new_chances);
  event ExpRequirementsChanged(address _from, uint256[] _expRequirements);
  event NameChange(address _from, uint256 _tokenId, string _newName);
  event Upgrade(address _from, uint256 _tokenId, uint256 _level);
  event ExpChange(address _from, uint256 _tokenId, uint256 _exp);
  event LevelChange(address _from, uint256 _tokenId, uint256 _level, uint256 _gold, uint256 _token);
  event AttributeChange(address _from, uint256 _tokenId, uint256 _str, uint256 _agi, uint256 _vit, uint256 _end, uint256 _intel, uint256 _will);
}

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

// Interface for the randomizer.
contract IVRFHelper {
    function GetVRF(uint256) external view returns (uint256) {}
}

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

// Interface for the signature verifier.
contract ISignature {
    function verify( address _signer, address _to, uint256 _amount, string memory _message, uint256 _nonce, bytes memory signature) public pure returns (bool) { }
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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
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