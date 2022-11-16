// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IFREN {
    function balanceOf(address) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address);
}

contract FrenHat is Ownable, ReentrancyGuard {
    address public Phat_NFT = 0xb75DB4EF3615E954b29c690B76Af994Ad41d04D5;
    address public Phat1_NFT = 0xAf4a2633621B9B0bc49B2D29A0CeAc2Ca680D352;
    address public Fren_NFT = 0x249bB0B4024221f09d70622444e67114259Eb7e8;
    address public Phat_Token = 0x69b2cd28B205B47C8ba427e111dD486f9C461B57;
    address public Fren_Token = 0x54cfe852BEc4FA9E431Ec4aE762C33a6dCfcd179;
    address public Trimmed_Phat_Token = 0x35d1d6f8EBC86B8DF9266f3Bb574F666A9543473;
    address public constant fren_grave = 0x000000000000000000000000000000000000dEaD;
    uint256 public HatPrice = 42069 * 1e18;
    mapping(uint256 => bool) public _hasHat;
    mapping(address => bool) private _isNonFren;

    constructor() {}

    function setAddress(
        address _Phat_NFT,
        address _Phat1_NFT,
        address _Fren_NFT,
        address _Phat_Token,
        address _Fren_Token
    ) public onlyOwner {
        Phat_NFT = _Phat_NFT;
        Phat1_NFT = _Phat1_NFT;
        Fren_NFT = _Fren_NFT;
        Phat_Token = _Phat_Token;
        Fren_Token = _Fren_Token;
    }

    function setHatPrice(uint256 _HatPrice) public onlyOwner {
        HatPrice = _HatPrice;
    }

    function getHat(uint256 _tokenID) public {
        require(!_isNonFren[msg.sender], "No Non Frens Allowed");
        require(msg.sender == IFREN(Fren_NFT).ownerOf(_tokenID), "You must own this Fren to put an Hat on");
        require(IFREN(Fren_Token).balanceOf(tx.origin) > HatPrice, "You must have $NFA to burn for Hat");
        require(
            IFREN(Phat_Token).balanceOf(tx.origin) > 0 ||
                IFREN(Phat_NFT).balanceOf(tx.origin) > 0 ||
                IFREN(Phat1_NFT).balanceOf(tx.origin) > 0 ||
                IFREN(Trimmed_Phat_Token).balanceOf(tx.origin) > 0,
            "You must have an Hat to put on your Fren"
        );
        IFREN(Fren_Token).transferFrom(msg.sender, fren_grave, HatPrice);
        _hasHat[_tokenID] = true;
    }

    function hasHat(uint256 _tokenID) public returns (bool) {
        return _hasHat[_tokenID];
    }

    function setNonFrens(address[] calldata _addresses, bool bot) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _isNonFren[_addresses[i]] = bot;
        }
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