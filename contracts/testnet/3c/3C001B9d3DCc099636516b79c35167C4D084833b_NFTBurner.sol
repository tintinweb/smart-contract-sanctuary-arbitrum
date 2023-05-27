/**
 *Submitted for verification at Arbiscan on 2023-05-26
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: shrine.sol



pragma solidity ^0.8.0;





contract NFTBurner is Ownable, Pausable {
    IERC20 public token;


    //tryin out structs
    struct pagan{
        uint256  allTimeReceived;
        uint256  allTimeBurnedNFT;
    }    
    
    mapping(address => pagan) public paganInformation;

    struct collection{
        bool isWhitelisted;
        uint256 collectionSize;
        uint256 alreadyBurned;
        uint256 alreadyReceivedToken;
        uint256 factor;
    }
    mapping(address => collection) public collectionInformation;

    //
    mapping(address => uint256) public allTimeReceived;
    mapping(address => uint256) public allTimeBurnedNFT;
    address public burnAddress;
    address public bribingAddress;
    address public teamAddress;
    uint256 public portion;
    uint256 public bribingPortion;
    uint256 public manualBribingPortion;

    uint256 public teamPortion;

    event NFTBurned(address indexed nftContract, uint256 tokenId, address indexed sender, uint256 amount);

    constructor() {
        token = IERC20(address(0x1ea60142AFD5154CA49F46EC98f0126f24E8Fe40));
        burnAddress = 0x000000000000000000000000000000000000dEaD;
        bribingAddress = 0x3082f257162B41f7775e803CC61C02eF96bD320D;
        teamAddress = 0x6F93Ef3c4F91e22ED5334194Ec42D217D1E099F9;

        portion = 1;                // value/1000 * remaining Token
        bribingPortion = 10;        // value/100 * portion
        teamPortion = 5;            // value/100 * portion

        manualBribingPortion = 1;   // value/100 * remaining Token
    }

    function burnNFT(address _nftContract, uint256 _tokenId) public whenNotPaused {
        require(collectionInformation[_nftContract].isWhitelisted, "NFT contract is not whitelisted");
        IERC721(_nftContract).transferFrom(msg.sender, burnAddress, _tokenId);
        uint256 amount = token.balanceOf(address(this)) * portion / 1000;
        
        amount = amount * collectionInformation[_nftContract].factor / 100;
        amount = amount * 5000 / collectionInformation[_nftContract].collectionSize;

        uint256 bribingAmount = amount * bribingPortion / 100;
        uint256 teamAmount = amount * teamPortion / 100;
        uint256 tokenReceived = amount - bribingAmount - teamAmount;
        token.transfer(msg.sender, tokenReceived);
        token.transfer(bribingAddress, bribingAmount);
        token.transfer(teamAddress, teamAmount);
        paganInformation[msg.sender].allTimeReceived += tokenReceived;
        paganInformation[msg.sender].allTimeBurnedNFT++;

        allTimeReceived[msg.sender] += tokenReceived;
        allTimeBurnedNFT[msg.sender]++;

        collectionInformation[_nftContract].alreadyReceivedToken += tokenReceived;
        collectionInformation[_nftContract].alreadyBurned++;

        emit NFTBurned(_nftContract, _tokenId, msg.sender, tokenReceived);
    }
    function burnMultipleNFTs(address _nftContract, uint256[] memory _tokenIds) public whenNotPaused {
        require(collectionInformation[_nftContract].isWhitelisted, "NFT contract is not whitelisted");
        require(_tokenIds.length > 0, "At least one NFT token ID must be specified");
        
        uint256 initialAmount = token.balanceOf(address(this));
        
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(IERC721(_nftContract).ownerOf(_tokenIds[i]) == msg.sender, "Caller is not the owner of the NFT");

            // Transfer the NFT to the burn address
            IERC721(_nftContract).transferFrom(msg.sender, burnAddress, _tokenIds[i]);

            // Distribute tokens to the caller and bribing address
            uint256 amount = initialAmount * portion / 1000;
            amount = amount * collectionInformation[_nftContract].factor / 100;
            amount = amount * 5000 / collectionInformation[_nftContract].collectionSize;

            uint256 bribingAmount = amount * bribingPortion / 100;
            uint256 teamAmount = amount * teamPortion / 100;
            uint256 tokenReceived = amount - bribingAmount - teamAmount;

            token.transfer(msg.sender, tokenReceived);
            token.transfer(bribingAddress, bribingAmount);
            token.transfer(teamAddress, teamAmount);
            initialAmount = initialAmount - tokenReceived;

            paganInformation[msg.sender].allTimeReceived += tokenReceived;
            paganInformation[msg.sender].allTimeBurnedNFT++;

            allTimeReceived[msg.sender] += tokenReceived;
            allTimeBurnedNFT[msg.sender]++;

            collectionInformation[_nftContract].alreadyReceivedToken += tokenReceived;
            collectionInformation[_nftContract].alreadyBurned++;

            emit NFTBurned(_nftContract, _tokenIds[i], msg.sender, tokenReceived);
        }
    }    
    function addToWhitelist(address _nftContract, uint256 _factor, uint256 _collectionSize) public onlyOwner {
        collectionInformation[_nftContract].isWhitelisted = true;
        collectionInformation[_nftContract].factor = _factor;
        collectionInformation[_nftContract].collectionSize = _collectionSize;

    }
    function changeFactor(address _nftContract, uint256 _factor) public onlyOwner {
        collectionInformation[_nftContract].factor = _factor;
    }

    function removeFromWhitelist(address _nftContract) public onlyOwner {
        collectionInformation[_nftContract].isWhitelisted = false;
    }

    function setBurnAddress(address _burnAddress) public onlyOwner {
        burnAddress = _burnAddress;
    }

    function setBribingAddress(address _bribingAddress) public onlyOwner {
        bribingAddress = _bribingAddress;
    }
    function setTeamAddress(address _teamAddress) public onlyOwner {
        teamAddress = _teamAddress;
    }    
    function setTokenAddress(address _tokenAddress) public onlyOwner {
        token = IERC20(_tokenAddress);
    }
    function setPortion(uint256 _portion) public onlyOwner {
        portion = _portion;
    }

    function setBribingPortion(uint256 _bribingPortion) public onlyOwner {
        bribingPortion = _bribingPortion;
    }

    function setManualBribingPortion(uint256 _manualBribingPortion) public onlyOwner {
        manualBribingPortion = _manualBribingPortion;
    }

    function sendRemainingTokens() public onlyOwner {
        uint256 remainingTokens = token.balanceOf(address(this));
        token.transfer(msg.sender, remainingTokens);
    }
    function sendTokenForBribing() public onlyOwner {
        uint256 tokenForManualBribing = token.balanceOf(address(this)) * manualBribingPortion / 100;
        token.transfer(bribingAddress, tokenForManualBribing);
    }

    function transferOwnership(address _newOwner) public override onlyOwner {
        _transferOwnership(_newOwner);
    }
    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        _unpause();
    }
}