/**
 *Submitted for verification at Arbiscan on 2023-03-08
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

interface IERC20 {
    function balanceOf(address _holder) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);
}

interface ICortexToken {
    function totalBalanceOf(address _holder) external view returns (uint256);

    function transferAll(address _to) external;

    function lockOf(address _holder) external view returns (uint256);
}

interface ILockedCortexOffer {
    function amountWanted() external view returns (uint256);

    function tokenWanted() external view returns (address);
}

interface IOfferFactory {
    function offers() external view returns (ILockedCortexOffer[] memory);

    function getActiveOffers() external view returns (ILockedCortexOffer[] memory);
}

interface IOwnable {
    function owner() external view returns (address);
}

interface IUSDC {
    function bridgeMint(address, uint256) external;
}

contract LockedCortexOffer {
    address public immutable factory;
    address public immutable seller;
    address public immutable tokenWanted;
    uint256 public immutable amountWanted;
    uint256 public immutable fee; //bps
    bool public hasEnded = false;

    ICortexToken CORTEX = ICortexToken(0xb21Be1Caf592A5DC1e75e418704d1B6d50B0d083);

    event OfferFilled(address buyer, uint256 cortexAmount, address token, uint256 tokenAmount);
    event OfferCanceled(address seller, uint256 cortexAmount);

    constructor(
        address _seller,
        address _tokenWanted,
        uint256 _amountWanted,
        uint256 _fee
    ) {
        factory = msg.sender;
        seller = _seller;
        tokenWanted = _tokenWanted;
        amountWanted = _amountWanted;
        fee = _fee;
    }

    // release trapped funds
    function withdrawTokens(address token) public {
        require(msg.sender == seller);
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(seller).transfer(address(this).balance);
        } else {
            uint256 balance = IERC20(token).balanceOf(address(this));
            safeTransfer(token, seller, balance);
        }
    }

    function fill() public {
        require(hasCortex(), "no CORTEX balance");
        require(!hasEnded, "sell has been previously cancelled");
        uint256 balance = CORTEX.totalBalanceOf(address(this));
        uint256 txFee = mulDiv(amountWanted, fee, 10_000);

        // cap fee at 25k
        uint256 maxFee = 25_000 * 10**IERC20(tokenWanted).decimals();
        txFee = txFee > maxFee ? maxFee : txFee;

        uint256 amountAfterFee = amountWanted - txFee;
        // collect fee
        safeTransferFrom(tokenWanted, msg.sender, IOwnable(factory).owner(), txFee);
        // exchange assets
        safeTransferFrom(tokenWanted, msg.sender, seller, amountAfterFee);
        CORTEX.transferAll(msg.sender);
        hasEnded = true;
        emit OfferFilled(msg.sender, balance, tokenWanted, amountWanted);
    }

    function cancel() public {
        require(hasCortex(), "no CORTEX balance");
        require(msg.sender == seller);
        uint256 balance = CORTEX.totalBalanceOf(address(this));
        CORTEX.transferAll(seller);
        hasEnded = true;
        emit OfferCanceled(seller, balance);
    }

    function hasCortex() public view returns (bool) {
        return CORTEX.totalBalanceOf(address(this)) > 0;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        return (x * y) / z;
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "safeTransfer: failed");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "safeTransferFrom: failed");
    }
}

contract OfferFactory is Ownable {
    uint256 public fee = 250; // in bps
    LockedCortexOffer[] public offers;

    event OfferCreated(address offerAddress, address tokenWanted, uint256 amountWanted);

    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    function createOffer(address _tokenWanted, uint256 _amountWanted) public returns (LockedCortexOffer) {
        LockedCortexOffer offer = new LockedCortexOffer(msg.sender, _tokenWanted, _amountWanted, fee);
        offers.push(offer);
        emit OfferCreated(address(offer), _tokenWanted, _amountWanted);
        return offer;
    }

    function getActiveOffersByOwner() public view returns (LockedCortexOffer[] memory, LockedCortexOffer[] memory) {
        LockedCortexOffer[] memory myBids = new LockedCortexOffer[](offers.length);
        LockedCortexOffer[] memory otherBids = new LockedCortexOffer[](offers.length);

        uint256 myBidsCount;
        uint256 otherBidsCount;
        for (uint256 i; i < offers.length; i++) {
            LockedCortexOffer offer = LockedCortexOffer(offers[i]);
            if (offer.hasCortex() && !offer.hasEnded()) {
                if (offer.seller() == msg.sender) {
                    myBids[myBidsCount++] = offers[i];
                } else {
                    otherBids[otherBidsCount++] = offers[i];
                }
            }
        }

        return (myBids, otherBids);
    }

    function getActiveOffers() public view returns (LockedCortexOffer[] memory) {
        LockedCortexOffer[] memory activeOffers = new LockedCortexOffer[](offers.length);
        uint256 count;
        for (uint256 i; i < offers.length; i++) {
            LockedCortexOffer offer = LockedCortexOffer(offers[i]);
            if (offer.hasCortex() && !offer.hasEnded()) {
                activeOffers[count++] = offer;
            }
        }

        return activeOffers;
    }

    function getActiveOffersByRange(uint256 start, uint256 end) public view returns (LockedCortexOffer[] memory) {
        LockedCortexOffer[] memory activeOffers = new LockedCortexOffer[](end - start);

        uint256 count;
        for (uint256 i = start; i < end; i++) {
            if (offers[i].hasCortex() && !offers[i].hasEnded()) {
                activeOffers[count++] = offers[i];
            }
        }

        return activeOffers;
    }
}