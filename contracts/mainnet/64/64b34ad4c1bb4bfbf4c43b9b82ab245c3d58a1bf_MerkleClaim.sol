/**
 *Submitted for verification at Arbiscan on 2022-08-25
*/

// File: lib/MerkleProof.sol


pragma solidity >=0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// File: lib/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: ERC721.sol


pragma solidity >=0.8.0;

/*//////////////////////////////////////////////////////////////
                             IMPORTS
//////////////////////////////////////////////////////////////*/


contract ERC721 {
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
    string public baseURI;
    // keep track of the last minted ID depending on the tier
    mapping (uint => uint) public lastId;


    function baseTokenURI() public view returns (string memory) {return baseURI;}

    function tokenURI(uint256 _id) public view returns (string memory) {
        require(_id != 0, "NFT ID starts at 1");
        require(_id <= 369, "ID out of bounds");

        uint id;
        if (_id==1) {id=1;} else if (_id < 11) {id=2;} else {id=3;}

        return string(abi.encodePacked(baseTokenURI(), Strings.toString(id)));
    
    }


    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;


    function ownerOf(uint256 id) public view returns (address owner) {

        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");

    }

    function balanceOf(address owner) public view returns (uint256) {

        require(owner != address(0), "ZERO_ADDRESS");
        return _balanceOf[owner];

    }

    function totalSupply() public view returns (uint256) {

        return lastId[1] + (lastId[2]-1) + (lastId[3]-10);

    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) {
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
        lastId[1] = 0;
        lastId[2] = 1;
        lastId[3] = 10;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public {

        address owner = _ownerOf[id];
        require(
            msg.sender == owner || 
            isApprovedForAll[owner][msg.sender],
            "NOT_AUTHORIZED"
        );
        
        getApproved[id] = spender;
        emit Approval(owner, spender, id);

    }

    function setApprovalForAll(address operator, bool approved) public {

        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);

    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public {

        require(from == _ownerOf[id], "WRONG_FROM");
        require(to != address(0), "INVALID_RECIPIENT");
        require(
            msg.sender == from ||
            isApprovedForAll[from][msg.sender] ||
            msg.sender == getApproved[id],
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
    ) public {

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
    ) public {

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

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {

        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f;   // ERC165 Interface ID for ERC721Metadata

    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint tier) internal returns (bool) {

        uint id;
        id = lastId[tier] + 1;
        require(to != address(0), "INVALID_RECIPIENT");
        require(_ownerOf[id] == address(0), "ALREADY_MINTED");
        require(id < 370, "MAX TOKENS ALREADY MINTED");

        lastId[tier]++;
        // Counter overflow is impossible as they are only 369 winners.
        unchecked {
            _balanceOf[to]++;
        }
        _ownerOf[id] = to;
        emit Transfer(address(0), to, id);
        return true;

    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal returns (bool) {

        (bool success) = _mint(to, id);
        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
        return success;

    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal {

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
contract ERC721TokenReceiver {

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {

        return ERC721TokenReceiver.onERC721Received.selector;
    
    }
}

// File: lib/IERC20.sol


pragma solidity >=0.8.0;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function decimals() external view returns (uint8);
}

// File: merkle.sol


pragma solidity >=0.8.0;

/*//////////////////////////////////////////////////////////////
                            Imports
//////////////////////////////////////////////////////////////*/





/*//////////////////////////////////////////////////////////////
                            Contract
//////////////////////////////////////////////////////////////*/

/// @title MerkleClaimERC20
/// @notice tokens claimable by members of a merkle tree
contract MerkleClaim is ERC721 {

    /*//////////////////////////////////////////////////////////////
                            Immutable storage
    //////////////////////////////////////////////////////////////*/

    /// @dev input struct for the constructor to avoid stack too deep
    struct MerkleData {
        address _admin;
        address _token;
        uint256 _startClaim;
        string _name;
        string _symbol;
        string _baseURI;
        bytes32 _merkleRoot;
    }

    address public admin = 0x5f49174FdEb42959f3234053b18F5c4ad497CC55;
    address public token = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    uint256 public startClaim = block.timestamp;
    uint256 public endClaim;
    uint256 public tier1amount;
    uint256 public tier2amount;
    uint256 public tier3amount;
    /// @notice ERC20-claimee inclusion root
    bytes32 public merkleRoot=0xfd3d146001235eb7f1360b6a7e73b21ede3db4e45e6d008df917819a3b0389c8;

    /*//////////////////////////////////////////////////////////////
                            Mutable storage
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping of addresses who have claimed tokens
    mapping(address => bool) public hasClaimed;

    /*//////////////////////////////////////////////////////////////
                               Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }
    
    /*//////////////////////////////////////////////////////////////
                                 Errors
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown if address has already claimed
    error AlreadyClaimed();
    /// @notice Thrown if address/amount are not part of Merkle tree
    error NotInMerkle();

    /*//////////////////////////////////////////////////////////////
                              Constructor
    //////////////////////////////////////////////////////////////*/

    constructor() ERC721(
        "3xcalibur Holy Grail",
        "XCAL-HG",
        "ipfs://QmNWy6kcdZwGGZJyB3mamZDAeJapqbicot97QgBrm2fvyy/"
    ) {

        endClaim = startClaim + 24 weeks;
        tier1amount = 3690 * (10 ** 6);
        tier2amount = 369 * (10 ** 6);
        tier3amount = 1 * (10 ** 6);
    
    }

    /*//////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted after a successful token claim
    /// @param to recipient of claim
    /// @param amount of tokens claimed
    event Claim(address indexed to, uint256 amount);

    /// @notice Emitted after admin withdraws remaining funds
    /// @param amount of tokens withdrawn
    event Withdraw(uint256 amount);
    
    /*//////////////////////////////////////////////////////////////
                             View Functions
    //////////////////////////////////////////////////////////////*/

    function claimPeriod() public view returns (bool) {
        return block.timestamp > startClaim && block.timestamp < endClaim;
    }

    function claimPeriod(uint time) public view returns (bool) {
        return time > startClaim && time < endClaim;
    }

    /*//////////////////////////////////////////////////////////////
                            Update Functions
    //////////////////////////////////////////////////////////////*/

    function setBaseURI(string memory _baseURI) public onlyAdmin {
        baseURI = _baseURI;
    }

    /*//////////////////////////////////////////////////////////////
                            Claim Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows claiming tokens if address is part of merkle tree
    /// @param to address of claimee
    /// @param amount of tokens owed to claimee
    /// @param proof merkle proof to prove address and amount are in tree
    function claim(address to, uint256 amount, bytes32[] calldata proof) external {
        
        // Throw if address has already claimed tokens
        if (hasClaimed[to]) revert AlreadyClaimed();
        // Throw if timestamp not in the claim window
        require(block.timestamp > startClaim, "Claim not yet available");
        require(block.timestamp < endClaim, "Claim has expired");
        // check amount validity
        require(
            amount == tier1amount ||
            amount == tier2amount ||
            amount == tier3amount, "Amount not valid"
        );

        // Verify merkle proof, or revert if not in tree
        bytes32 leaf = keccak256(abi.encodePacked(to, amount));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
        if (!isValidLeaf) revert NotInMerkle();

        // Set address to claimed
        hasClaimed[to] = true;

        // mint NFT to claimee, send usdc if required
        if (amount == tier1amount) {
            // mint tier 1
            (bool success) = _mint(to, 1);
            require(success, "Could not mint token");

            // transfer from contract to claimee
            (success) = IERC20(token).transfer(
                to,
                amount
            );
            require(success, "Failed to transfer tokens");

        } else if (amount == tier2amount) {
            // mint tier 2
            (bool success) = _mint(to, 2);
            require(success, "Could not mint token");

            // transfer from contract to claimee
            (success) = IERC20(token).transfer(
                to,
                amount
            );
            require(success, "Failed to transfer tokens");
            
        } else if (amount == tier3amount) {
            // mint tier 3
            (bool success) = _mint(to, 3);
            require(success, "Could not mint token");
        }

        // Emit claim event
        emit Claim(to, amount);
    }

    /// @notice 85 tier 3 have not been rewarded to participants before the end of the HG
    /// @notice This function mints these NFTs to admin for future distribution
    function claimRemaining() external {
        uint i;
        while (i < 85) {_mint(admin, 3); unchecked{i++;}}
    }

    /// @notice allow to withdraw remaining funds after the claim period
    function withdraw() public onlyAdmin {
        // throw if the claim window has not yet ended
        require(block.timestamp > endClaim, "Claim has not expired");
        // transfer all remaining funds from contract to admin
        (bool success) = IERC20(token).transfer(
            admin,
            IERC20(token).balanceOf(address(this))
        );
        require(success, "Failed to transfer tokens");
    }

}