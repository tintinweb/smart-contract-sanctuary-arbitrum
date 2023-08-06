// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MintParams} from "../structs/erc721/ERC721Structs.sol";
import "../interfaces/IOmniseaERC721Psi.sol";
import "../interfaces/IOmniseaDropsFactory.sol";

contract OmniseaDropsManager is ReentrancyGuard {
    event Minted(address collection, address minter, uint256 quantity, uint256 value);

    uint256 public fixedFee;
    uint256 private _fee;
    address private _revenueManager;
    address private _owner;
    bool private _isPaused;
    IOmniseaDropsFactory private _factory;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor(address factory_) {
        _owner = msg.sender;
        _revenueManager = address(0x61104fBe07ecc735D8d84422c7f045f8d29DBf15);
        _factory = IOmniseaDropsFactory(factory_);
        _fee = 4;
        fixedFee = 250000000000000;
    }

    function setFee(uint256 fee) external onlyOwner {
        require(fee <= 20);
        _fee = fee;
    }

    function setFixedFee(uint256 fee) external onlyOwner {
        fixedFee = fee;
    }

    function setRevenueManager(address _manager) external onlyOwner {
        _revenueManager = _manager;
    }

    function mint(MintParams calldata _params) external payable nonReentrant {
        require(!_isPaused);
        require(_factory.drops(_params.collection));
        IOmniseaERC721Psi collection = IOmniseaERC721Psi(_params.collection);

        uint256 price = collection.mintPrice(_params.phaseId);
        uint256 quantityPrice = price * _params.quantity;
        require(msg.value == quantityPrice + fixedFee, "!=price");
        if (quantityPrice > 0) {
            uint256 paidToOwner = quantityPrice * (100 - _fee) / 100;
            (bool p1,) = payable(collection.owner()).call{value: paidToOwner}("");
            require(p1, "!p1");

            (bool p2,) = payable(_revenueManager).call{value: msg.value - paidToOwner}("");
            require(p2, "!p2");
        } else {
            (bool p3,) = payable(_revenueManager).call{value: msg.value}("");
            require(p3, "!p3");
        }
        collection.mint(msg.sender, _params.quantity, _params.merkleProof, _params.phaseId);

        emit Minted(_params.collection, msg.sender, _params.quantity, msg.value);
    }

    function setPause(bool isPaused_) external onlyOwner {
        _isPaused = isPaused_;
    }

    function withdraw() external onlyOwner {
        (bool p,) = payable(_owner).call{value: address(this).balance}("");
        require(p, "!p");
    }

    receive() external payable {}
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
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct CreateParams {
    string name;
    string symbol;
    string uri;
    string tokensURI;
    uint24 maxSupply;
    bool isZeroIndexed;
    uint24 royaltyAmount;
    uint256 endTime;
}

struct MintParams {
    address collection;
    uint24 quantity;
    bytes32[] merkleProof;
    uint8 phaseId;
}

struct OmnichainMintParams {
    address collection;
    uint24 quantity;
    uint256 paid;
    uint8 phaseId;
    address minter;
}

struct Phase {
    uint256 from;
    uint256 to;
    uint24 maxPerAddress;
    uint256 price;
    bytes32 merkleRoot;
}

struct BasicCollectionParams {
    string name;
    string symbol;
    string uri;
    string tokensURI;
    uint24 maxSupply;
    address owner;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { CreateParams } from "../structs/erc721/ERC721Structs.sol";

/**
 * @dev Interface of the IOmniseaUniversalONFT: Universal ONFT Core through delegation
 */
interface IOmniseaERC721Psi is IERC165 {
    function initialize(CreateParams memory params, address _owner, address _dropsManagerAddress, address _scheduler, address _universalONFT) external;
    function mint(address _minter, uint24 _quantity, bytes32[] memory _merkleProof, uint8 _phaseId) external;
    function mintPrice(uint8 _phaseId) external view returns (uint256);
    function exists(uint256 tokenId) external view returns (bool);
    function owner() external view returns (address);
    function dropsManager() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {CreateParams} from "../structs/erc721/ERC721Structs.sol";

interface IOmniseaDropsFactory {
    function create(CreateParams calldata params) external;
    function drops(address) external returns (bool);
}

// SPDX-License-Identifier: MIT
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