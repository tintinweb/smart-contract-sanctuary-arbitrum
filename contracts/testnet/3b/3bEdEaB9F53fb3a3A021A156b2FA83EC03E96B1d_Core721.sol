/**
 *Submitted for verification at Arbiscan on 2022-06-28
*/

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
  /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

  event Transfer(address indexed from, address indexed to, uint256 indexed id);

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 indexed id
  );

  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

  string public name;

  string public symbol;

  function tokenURI(uint256 id) public view virtual returns (string memory);

  /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

  mapping(address => uint256) public balanceOf;

  mapping(uint256 => address) public ownerOf;

  mapping(uint256 => address) public getApproved;

  mapping(address => mapping(address => bool)) public isApprovedForAll;

  /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor(string memory _name, string memory _symbol) {
    name = _name;
    symbol = _symbol;
  }

  /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

  function approve(address spender, uint256 id) public virtual {
    address owner = ownerOf[id];

    require(
      msg.sender == owner || isApprovedForAll[owner][msg.sender],
      "NOT_AUTHORIZED"
    );

    getApproved[id] = spender;

    emit Approval(owner, spender, id);
  }

  function setApprovalForAll(address operator, bool approved) public virtual {
    isApprovedForAll[msg.sender][operator] = approved;

    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function transferFrom(
    address from,
    address to,
    uint256 id
  ) public virtual {
    require(from == ownerOf[id], "WRONG_FROM");

    require(to != address(0), "INVALID_RECIPIENT");

    require(
      msg.sender == from ||
        msg.sender == getApproved[id] ||
        isApprovedForAll[from][msg.sender],
      "NOT_AUTHORIZED"
    );
    _beforeTokenTransfer(from, to, id);

    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    unchecked {
      balanceOf[from]--;

      balanceOf[to]++;
    }

    ownerOf[id] = to;

    delete getApproved[id];

    emit Transfer(from, to, id);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id
  ) public virtual {
    transferFrom(from, to, id);

    require(
      to.code.length == 0 ||
        ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
        ERC721TokenReceiver.onERC721Received.selector,
      "UNSAFE_RECIPIENT"
    );
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    bytes memory data
  ) public virtual {
    transferFrom(from, to, id);

    require(
      to.code.length == 0 ||
        ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
        ERC721TokenReceiver.onERC721Received.selector,
      "UNSAFE_RECIPIENT"
    );
  }

  /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

  function supportsInterface(bytes4 interfaceId)
    public
    pure
    virtual
    returns (bool)
  {
    return
      interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
      interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
      interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
  }

  /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

  function _mint(address to, uint256 id) internal virtual {
    require(to != address(0), "INVALID_RECIPIENT");

    require(ownerOf[id] == address(0), "ALREADY_MINTED");
    _beforeTokenTransfer(address(0), to, id);

    // Counter overflow is incredibly unrealistic.
    unchecked {
      balanceOf[to]++;
    }

    ownerOf[id] = to;

    emit Transfer(address(0), to, id);
  }

  function _burn(uint256 id) internal virtual {
    address owner = ownerOf[id];

    require(ownerOf[id] != address(0), "NOT_MINTED");
    _beforeTokenTransfer(owner, address(0), id);

    // Ownership check above ensures no underflow.
    unchecked {
      balanceOf[owner]--;
    }

    delete ownerOf[id];

    delete getApproved[id];

    emit Transfer(owner, address(0), id);
  }

  /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

  function _safeMint(address to, uint256 id) internal virtual {
    _mint(to, id);

    require(
      to.code.length == 0 ||
        ERC721TokenReceiver(to).onERC721Received(
          msg.sender,
          address(0),
          id,
          ""
        ) ==
        ERC721TokenReceiver.onERC721Received.selector,
      "UNSAFE_RECIPIENT"
    );
  }

  function _safeMint(
    address to,
    uint256 id,
    bytes memory data
  ) internal virtual {
    _mint(to, id);

    require(
      to.code.length == 0 ||
        ERC721TokenReceiver(to).onERC721Received(
          msg.sender,
          address(0),
          id,
          data
        ) ==
        ERC721TokenReceiver.onERC721Received.selector,
      "UNSAFE_RECIPIENT"
    );
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, ``from``'s `tokenId` will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
  function onERC721Received(
    address operator,
    address from,
    uint256 id,
    bytes calldata data
  ) external returns (bytes4);
}

pragma solidity ^0.8.0;
interface IMintValidator721 {
  function validate(
    address _recipient,
    uint256 _dropId,
    string calldata _metadata,
    bytes memory _data
  ) external;
}

pragma solidity ^0.8.0;



interface IFabricator721 {
  function modularMintInit(
    uint256 _dropId,
    address _to,
    bytes memory _data,
    address _validator,
    string calldata _metadata
  ) external;

  function modularMintCallback(
    address recipient,
    uint256 _id,
    bytes memory _data
  ) external;

  function quantityMinted(uint256 collectibleId) external returns (uint256);

  function idToValidator(uint256 collectibleId) external returns (address);
}

pragma solidity ^0.8.0;

interface IXferHook {
  function xferHook(
    address from,
    address to,
    uint256 id
  ) external;
}



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

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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


// Experiment with solmate 721?



/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

pragma solidity ^0.8.0;
//pragma abicoder v2;


interface IReadMetadata {
  function get(uint256 _id) external view returns (string memory metadata);
}

contract MetadataRegistry is IReadMetadata, Auth {
  event Register(uint256 id, string metadata);
  event UnRegister(uint256 id);

  mapping(uint256 => string) public idToMetadata;

  constructor(Authority auth) Auth(msg.sender, auth) {}

  function set(uint256 _id, string calldata _metadata) public requiresAuth {
    idToMetadata[_id] = _metadata;
    emit Register(_id, _metadata);
  }

  function get(uint256 _id)
    public
    view
    override
    returns (string memory metadata)
  {
    metadata = idToMetadata[_id];
    require(bytes(metadata).length > 0, "MISSING_URI");
  }

  function setMultiple(uint256[] calldata _ids, string[] calldata _metadatas)
    external
    requiresAuth
  {
    require(_ids.length == _metadatas.length, "SET_MULTIPLE_LENGTH_MISMATCH");
    for (uint256 i = 0; i < _ids.length; i++) {
      set(_ids[i], _metadatas[i]);
    }
  }
}

/// @title Core721
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details//Interface
contract Core721 is Context, ERC721, IFabricator721, Auth {
  using Strings for uint256;
  event Validator(IMintValidator721 indexed validator, bool indexed active);

  mapping(IMintValidator721 => bool) public isValidator;
  mapping(IMintValidator721 => uint256[]) public validatorToIds;
  mapping(uint256 => address) public override idToValidator;
  mapping(uint256 => uint256) public override quantityMinted;
  mapping(uint256 => address) public idToTransferHook;
  // URI base; NOT the whole uri.
  string private _baseURI;
  IReadMetadata private _registry;

  /**
   * @dev intializes the core ERC1155 logic, and sets the original URI base
   */
  constructor(
    string memory baseUri_,
    IReadMetadata registry_,
    Authority authority
  ) ERC721("PILLS AVATARS", "AVAPILL") Auth(msg.sender, authority) {
    _registry = registry_;
    _baseURI = baseUri_;
  }

  modifier onlyValidator() {
    bool isActive = isValidator[IMintValidator721(msg.sender)];
    require(isActive, "VALIDATOR_INACTIVE");
    _;
  }

  /**
   * @dev query URI for a token Id. Queries the Metadata registry on the backend
   */
  function uri(uint256 _id) public view returns (string memory) {
    // Use the underlying metadata contract?
    return string(abi.encodePacked(_baseURI, _id.toString()));
  }

  /**
   * @dev change the URI base address after construction.
   */
  function setBaseURI(string calldata _newBaseUri) external requiresAuth {
    _baseURI = _newBaseUri;
  }

  /**
   * @dev change the URI base address after construction.
   */
  function setNewRegistry(IReadMetadata registry_) external requiresAuth {
    _registry = registry_;
  }

  /**
   * @dev An active Validator is necessary to enable `modularMint`
   */
  function addValidator(IMintValidator721 _validator, uint256[] memory ids)
    external
    virtual
    requiresAuth
  {
    bool isActive = isValidator[_validator];
    require(!isActive, "VALIDATOR_ACTIVE");
    for (uint256 i; i < ids.length; i++) {
      require(idToValidator[ids[i]] == address(0x0), "INVALID_VALIDATOR_IDS");
      idToValidator[ids[i]] = address(_validator);
    }
    isValidator[_validator] = true;
    emit Validator(_validator, !isActive);
  }

  /**
   * @dev An active Validator is necessary to enable `modularMint`
   */
  function addTransferHook(IXferHook hooker, uint256[] memory ids)
    external
    virtual
    requiresAuth
  {
    for (uint256 i; i < ids.length; i++) {
      require(idToTransferHook[ids[i]] == address(0x0), "INVALID_HOOK_IDS");
      idToTransferHook[ids[i]] = address(hooker);
    }
  }

  /**
   * @dev Remove Validators that are no longer needed to remove attack surfaces
   */
  function removeValidator(IMintValidator721 _validator)
    external
    virtual
    requiresAuth
  {
    bool isActive = isValidator[_validator];
    require(isActive, "VALIDATOR_INACTIVE");
    uint256[] memory ids = validatorToIds[_validator];
    for (uint256 i; i < ids.length; i++) {
      idToValidator[ids[i]] = address(0x0);
    }
    isValidator[_validator] = false;
    emit Validator(_validator, !isActive);
  }

  /**
   * @dev Upgrade the validator responsible for a certain
   */
  function upgradeValidator(
    IMintValidator721 _oldValidator,
    IMintValidator721 _newValidator
  ) external virtual requiresAuth {
    bool isActive = isValidator[_oldValidator];
    require(isActive, "VALIDATOR_INACTIVE");
    uint256[] memory ids = validatorToIds[_oldValidator];
    for (uint256 i; i < ids.length; i++) {
      idToValidator[ids[i]] = address(_newValidator);
    }
    isValidator[_oldValidator] = false;
    emit Validator(_oldValidator, !isActive);
    isValidator[_newValidator] = true;
    emit Validator(_newValidator, !isActive);
  }

  /**
   * @dev Mint mulitiple tokens at different quantities. This is an requiresAuth
          function and is meant basically as a sudo-command. Auth should be 
   */
  function mint(
    address _to,
    uint256 _id,
    bytes memory _data
  ) external virtual requiresAuth {
    _safeMint(_to, _id, _data);
  }

  /**
   * @dev Creates `amount` new tokens for `to`, of token type `id`.
   *      At least one Validator must be active in order to utilized this interface.
   */
  function modularMintInit(
    uint256 _dropId,
    address _to,
    bytes memory _data,
    address _validator,
    string calldata _metadata
  ) public virtual override {
    IMintValidator721 validator = IMintValidator721(_validator);
    require(isValidator[validator], "BAD_VALIDATOR");
    validator.validate(_to, _dropId, _metadata, _data);
  }

  /**
   * @dev Creates `amount` new tokens for `to`, of token type `id`.
   *      At least one Validator must be active in order to utilized this interface.
   */
  function modularMintCallback(
    address recipient,
    uint256 _id,
    bytes calldata _data
  ) public virtual override onlyValidator {
    require(idToValidator[_id] == address(msg.sender), "INVALID_MINT");
    _safeMint(recipient, _id, _data);
  }

  // OPTIMIZATION: No need for numbers to be readable, so this could be optimized
  // but gas cost here doesn't matter so we go for the standard approach
  function tokenURI(uint256 _id) public view override returns (string memory) {
    return string(abi.encodePacked(_baseURI, _id.toString()));
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 id
  ) internal override {
    if (idToTransferHook[id] != address(0x0)) {
      IXferHook(idToTransferHook[id]).xferHook(from, to, id);
    }
  }
}