// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ImmutableProfile is Ownable {
    // User struct to store username and NFT address
    struct User {
        string username;
        address nftAddress;
        uint256 tokenID;
        bool blocked;
    }

    // Mapping to store user data, using their Ethereum address as a key
    mapping(address => User) private users;

    // Array to store the Ethereum addresses of registered users
    address[] private userAddresses;

    // Event that is fired when user data is updated
    event UserDataUpdated(
        address indexed userAddress,
        string username,
        address indexed nftAddress,
        uint256 indexed tokenID
    );

    // Function to set or update username
    function setUsername(string memory _username) public {
        require(!users[msg.sender].blocked, "User is blocked");

        _setUsername(msg.sender, _username);
    }

    // Function to set or update user NFT
    function setUserNFT(address _nftAddress, uint256 _tokenId) public {
        require(!users[msg.sender].blocked, "User is blocked");

        _setUserNFT(msg.sender, _nftAddress, _tokenId);
    }

    // Function for the owner to set or update user data
    function setUserDataByOwner(
        address _userAddress,
        string memory _username,
        address _nftAddress,
        uint256 _tokenId
    ) public onlyOwner {
        _setUsername(_userAddress, _username);
        _setUserNFT(_userAddress, _nftAddress, _tokenId);
    }

    // Internal function to set or update username
    function _setUsername(
        address _userAddress,
        string memory _username
    ) internal {
        if (bytes(users[_userAddress].username).length == 0) {
            userAddresses.push(_userAddress);
        }

        users[_userAddress].username = _username;

        emit UserDataUpdated(
            _userAddress,
            _username,
            users[_userAddress].nftAddress,
            users[_userAddress].tokenID
        );
    }

    // Internal function to set or update user NFT
    function _setUserNFT(
        address _userAddress,
        address _nftAddress,
        uint256 _tokenId
    ) internal {
        if (!(_nftAddress == address(0))) {
            require(
                IERC721(_nftAddress).supportsInterface(
                    type(IERC721).interfaceId
                ),
                "Invalid ERC721 contract address"
            );
        }

        if (msg.sender != owner()) {
            require(
                msg.sender == _userAddress,
                "Only owner can update data for other users"
            );
        }

        if (msg.sender != owner()) {
            require(
                IERC721(_nftAddress).ownerOf(_tokenId) == msg.sender,
                "Caller must be the NFT owner"
            );
        }

        users[_userAddress].nftAddress = _nftAddress;
        users[_userAddress].tokenID = _tokenId;

        emit UserDataUpdated(
            _userAddress,
            users[_userAddress].username,
            _nftAddress,
            _tokenId
        );
    }

    // Function to get user data
    function getUserData(
        address _userAddress
    ) public view returns (string memory, address, bool, uint256) {
        User storage user = users[_userAddress];
        return (user.username, user.nftAddress, user.blocked, user.tokenID);
    }

    // Function for the owner to block a user and reset their profile
    function blockAndResetUserProfile(address _userAddress) public onlyOwner {
        users[_userAddress] = User("", address(0), 0, true);
    }

    // Function to get all user profiles with pagination (100 profiles per page)
    function getUserProfiles(
        uint256 _page
    ) public view returns (User[] memory) {
        uint256 startIndex = _page * 100;
        uint256 endIndex = startIndex + 100;

        // If the startIndex is greater than or equal to the userAddresses length, return an empty array
        if (startIndex >= userAddresses.length) {
            return new User[](0);
        }

        // If endIndex is greater than the userAddresses length, set endIndex to the length
        if (endIndex > userAddresses.length) {
            endIndex = userAddresses.length;
        }

        // Calculate the size of the result array and create a new array of User structs
        uint256 resultSize = endIndex - startIndex;
        User[] memory result = new User[](resultSize);

        // Iterate through the userAddresses array from startIndex to endIndex and populate the result array
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = users[userAddresses[i]];
        }

        return result;
    }
}