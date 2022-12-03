//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import './interfaces/InterfaceArbiDogsNft.sol';
import './interfaces/InterfaceArbiDogsMinter.sol';

contract ArbiDogsMinter is InterfaceArbiDogsMinter, Ownable, ReentrancyGuard {
    uint256 public maxMintableTokens;

    InterfaceArbiDogsNft public arbiDogsNft;
    address public treasuryAddress;
    uint256 public fee;
    uint256 public tokenClaimed = 0;
    bool public isInitialized = false;
    bool public isWhitelistEnabled = true;
    mapping(address => bool) private whitelist;

    /**
     * @dev Allows only if NOT initialized
     */
    modifier onlyNotInitialized() {
        require(isInitialized == false, 'ArbiDogsMinter: contract already initialized');
        _;
    }

    /**
     * @dev Allows only if initialized
     */
    modifier onlyInitialized() {
        require(isInitialized, 'ArbiDogsMinter: contract not initialized');
        _;
    }

    /**
     * @dev initialize minter
     * @param _arbiDogsNft The address of ArbiDogsNft
     * @param _maxMintableTokens Max tokens to mint
     * @param _treasuryAddress Address where to transfer collected fees
     * @param _fee Fee for minting nft
     */
    function initialize(
        address _arbiDogsNft,
        uint256 _maxMintableTokens,
        address _treasuryAddress,
        uint256 _fee
    ) external onlyOwner onlyNotInitialized {
        require(_arbiDogsNft != address(0), 'ArbiDogsMinter: invalid ArbiDogsNft address');
        require(_maxMintableTokens > 0, 'ArbiDogsMinter: invalid _maxMintableTokens');

        arbiDogsNft = InterfaceArbiDogsNft(_arbiDogsNft);
        maxMintableTokens = _maxMintableTokens;
        _setTreasuryAddress(_treasuryAddress);
        _setFee(_fee);
        isInitialized = true;
        emit Initialize(_arbiDogsNft, _maxMintableTokens, _treasuryAddress, _fee);
    }

    /**
     * @dev Receive funds and call internal claim method
     */
    receive() external payable {
        _claim();
    }

    /**
     * @dev Claim tokenIds
     */
    function _claim() public payable onlyInitialized nonReentrant {
        if (isWhitelistEnabled) {
            require(whitelist[msg.sender], 'ArbiDogsMinter: User not on whitelist');
        }
        require(tokenClaimed < maxMintableTokens, 'ArbiDogsMinter: All tokens are sold');
        uint256 numberOfTokens = msg.value / fee;
        numberOfTokens = _Min(numberOfTokens, maxMintableTokens - tokenClaimed);
        require(numberOfTokens > 0, 'ArbiDogsMinter: Invalid number of tokens');

        uint256 totalPayValue = numberOfTokens * fee;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mintToken(msg.sender);
        }

        (bool treasurySuccess, ) = treasuryAddress.call{value: totalPayValue}('');
        require(treasurySuccess, 'ArbiDogsMinter: Transfer to treasuryAddress failed');

        tokenClaimed = tokenClaimed + numberOfTokens;

        emit Claim(msg.sender, numberOfTokens);

        if (totalPayValue < msg.value) {
            (bool success, ) = msg.sender.call{value: msg.value - totalPayValue}('');
            require(success, 'ArbiDogsMinter: Transfer user surplus failed');
        }
    }

    /**
     * @dev _Min internal method to get min between two uint256
     * @param a who to compare
     * @param b compare with
     */
    function _Min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    /**
     * @dev _mintToken internal method to mint a token
     * @param user Receiver address of the minted token
     */
    function _mintToken(address user) internal {
        maxMintableTokens--;

        arbiDogsNft.mint(user);
    }

    /**
     * @dev Setter for fee
     */
    function setFee(uint256 _fee) external onlyOwner {
        _setFee(_fee);
        emit SetFee(_fee);
    }

    /**
     * @dev Add to whitelist
     */
    function addToWhitelist(address[] calldata toAddAddresses) external onlyOwner {
        for (uint256 i = 0; i < toAddAddresses.length; i++) {
            whitelist[toAddAddresses[i]] = true;
        }
        emit WhitelistUpdateAdd(toAddAddresses.length);
    }

    /**
     * @dev Remove from whitelist
     */
    function removeFromWhitelist(address[] calldata toRemoveAddresses) external onlyOwner {
        for (uint256 i = 0; i < toRemoveAddresses.length; i++) {
            delete whitelist[toRemoveAddresses[i]];
        }
        emit WhitelistUpdateRemove(toRemoveAddresses.length);
    }

    /**
     * @dev Enable whitelist
     */
    function enableWhitelist() external onlyOwner {
        isWhitelistEnabled = true;
        emit WhitelistEnabled();
    }

    /**
     * @dev Disable whitelist
     */
    function disableWhitelist() external onlyOwner {
        isWhitelistEnabled = false;
        emit WhitelistDisabled();
    }

    /**
     * @dev Increase max mintable tokens
     */
    function increaseMaxMintableTokens(uint256 amount) external onlyOwner {
        require(amount > 0, 'ArbiDogsMinter: invalid _maxMintableTokens');

        maxMintableTokens = maxMintableTokens + amount;

        emit MaxMintableTokensChanged(maxMintableTokens);
    }

    /**
     * @dev Increase max mintable tokens
     */
    function decreaseMaxMintableTokens(uint256 amount) external onlyOwner {
        require(amount > 0, 'ArbiDogsMinter: invalid _maxMintableTokens');
        require(
            amount <= maxMintableTokens,
            'ArbiDogsMinter: amount should not be greater than current maxMintableTokens'
        );

        maxMintableTokens = maxMintableTokens - amount;

        emit MaxMintableTokensChanged(maxMintableTokens);
    }

    /**
     * @dev Setter for treasury address
     */
    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        _setTreasuryAddress(_treasuryAddress);
        emit SetTreasuryAddress(_treasuryAddress);
    }

    function _setFee(uint256 _fee) internal {
        require(_fee > 0, 'ArbiDogsMinter: invalid fee');
        fee = _fee;
    }

    function _setTreasuryAddress(address _treasuryAddress) internal {
        require(_treasuryAddress != address(0), 'ArbiDogsMinter: invalid treasury address');
        treasuryAddress = _treasuryAddress;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

interface InterfaceArbiDogsNft {
    event Mint(address indexed user, uint256 tokenId);
    event Reveal(uint256[] _tokenIds, string[] _hashes);
    event SetBaseURI(string _uri);
    event SetDefaultIpfsFile(string _file);

    function setBaseURI(string memory _uri) external;

    function mint(address user) external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

interface InterfaceArbiDogsMinter {
    event Claim(address indexed requester, uint256 numberOfTokens);
    event SetFee(uint256 fee);
    event SetTreasuryAddress(address treasuryAddress);
    event Initialize(
        address arbiDogsNft,
        uint256 maxMintableTokens,
        address treasuryAddress,
        uint256 fee
    );
    event WhitelistUpdateAdd(uint256 numberOfTokens);
    event WhitelistUpdateRemove(uint256 numberOfTokens);
    event WhitelistEnabled();
    event WhitelistDisabled();
    event MaxMintableTokensChanged(uint256 maxMintableTokens);

    function initialize(
        address _arbiDogsNft,
        uint256 _maxMintableTokens,
        address _treasuryAddress,
        uint256 _fee
    ) external;

    receive() external payable;

    function setFee(uint256 _fee) external;

    function setTreasuryAddress(address _treasuryAddress) external;
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