// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/// @author devfolio

import "solmate/src/tokens/ERC721.sol";

/// @title The OnChainCredential NFT Contract
/// @author devfolio
/// @notice The ERC721 contract for the OnChainCredential NFT Contract
contract OnChainCredential is ERC721 {
    /// @dev The Error thrown when the mint authority is not the caller
    error InvalidMintAuthority();
    /// @dev The Error thrown when the caller is not allowed to transfer the token
    error TransferNotAllowed();
    /// @dev The Error thrown when the caller is not the owner
    error InvalidCaller();

    /// @dev mapping of the tokenId to the metadata
    mapping(uint256 => string) private metadata;
    /// @dev The addrerss of the mint authority that is allowed to mint the NFT
    address internal mint_authority;
    /// @notice The owner of the contract
    address public owner;
    /// @dev The current token ID index
    uint256 tokenIDs = 0;

    constructor(
        string memory name,
        string memory symbol,
        address _mint_authority,
        address _owner
    ) ERC721(name, symbol) {
        mint_authority = _mint_authority;
        owner = _owner;
    }

    /// @notice Mints the OnChainCredential NFT
    /// @dev Only the mint authority can mint the NFT
    /// @param token_metadata Metadata of the token
    /// @param to Address of the receiver of the NFT
    function mint(string calldata token_metadata, address to) external {
        if (msg.sender != mint_authority) revert InvalidMintAuthority();

        uint256 current_token_index = tokenIDs;
        metadata[current_token_index] = token_metadata;

        _mint(to, current_token_index);

        unchecked {
            tokenIDs++;
        }
    }

    /// @notice Returns the metadata of the token
    /// @param id ID of the token
    /// @return Documents the return variables of a contract’s function state variable
    function tokenURI(
        uint256 id
    ) public view virtual override returns (string memory) {
        return metadata[id];
    }

    /// @notice Internal Transfer Function
    /// @param from address of current owner
    /// @param to address of new owner
    /// @param id ID of the token
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        if (msg.sender != owner) revert TransferNotAllowed();

        /// @dev Reference:
        /// https://github.com/transmissions11/solmate/blob/bfc9c25865a274a7827fea5abf6e4fb64fc64e6c/src/tokens/ERC721.sol#L82
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(from, to, id);
    }

    /// @notice Updates the mint authority of the OnChainCredential Contract
    /// @param newAuthority Address of the new mint authority
    function updateMintAuthority(address newAuthority) external {
        if (msg.sender != owner) revert InvalidCaller();
        mint_authority = newAuthority;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {OnChainCredential} from "./OnChainCredential.sol";

contract OnChainCredentialFactory {
    /// @dev mapping of the hackathon uuid to the credential contract address
    mapping(string => address) internal hackathonCredentialMapping;
    /// @dev The address of the mint authority allowed to create the credential contract
    address private _mintAuthority;
    /// @dev The owner of the contract
    address private owner;

    /// @dev The Error thrown when the caller is not the owner
    error InvalidCaller();

    /// @notice The event emitted when a new credential contract is deployed
    /// @param credential The contract address of the credential contract
    /// @param hackathon_uuid The uuid of the hackathon
    event OnChainCredentialCreated(
        address indexed credential,
        string hackathon_uuid
    );

    constructor(address _mintAuth) {
        owner = msg.sender;
        _mintAuthority = _mintAuth;
    }

    /// @notice Deploys a new Credential NFT Contract
    /// @param name The name of the collection
    /// @param symbol The symbol of the collection
    /// @param hackathon_uuid The uuid of the hackathon for which NFT contract is being deployed
    /// @param hackathon_owner The owner name of the collection
    /// @dev data is ABI encoded as (string, string, string, address) only the owner can call this function
    function deployCredential(
        string calldata name,
        string calldata symbol,
        string calldata hackathon_uuid,
        address hackathon_owner
    ) external {
        if (msg.sender != owner) revert InvalidCaller();
        OnChainCredential credential = new OnChainCredential(
            name,
            symbol,
            _mintAuthority,
            hackathon_owner
        );
        hackathonCredentialMapping[hackathon_uuid] = address(credential);

        emit OnChainCredentialCreated(address(credential), hackathon_uuid);
    }

    /// @notice Returns the address of the credential contract for a given hackathon UUID
    /// @param hackathon_uuid The UUID of the hackathon for which the credential contract address is to be returned
    /// @return hackathon_uuid The UUID of the hackathon
    function hackathonCredential(
        string memory hackathon_uuid
    ) external view returns (address) {
        return hackathonCredentialMapping[hackathon_uuid];
    }

    /// @notice Returns the address of the mint authority
    function mintAuthority() external view returns (address) {
        return _mintAuthority;
    }

    /// @notice Updates the mint authority
    /// @dev Only the owner can call this function
    function updateAuthority(address newAuthority) external {
        if (msg.sender != owner) revert InvalidCaller();
        _mintAuthority = newAuthority;
    }

    /// @notice Updates the owner Factory
    /// @dev Only the owner can call this function
    function updateOwner(address newOwner) external {
        if (msg.sender != owner) revert InvalidCaller();
        owner = newOwner;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

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
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

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
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
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
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}