// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./AuctionV2.sol";
import "./SaleV2.sol";

contract AuctionFactory is Ownable {
    address[] public auctions;
    mapping(address => address[]) private userAuctions;
    address[] public sales;
    mapping(address => address[]) private userSales;

    address public treasury;

    uint256 public auctionSellerTax = 5;

    uint256 public saleSellerTax = 5;

    uint256 public auctionDeadlineDelay = 7 days;
    uint256 public saleDeadlineDelay = 7 days;

    event AuctionCreated(address auction, address seller);
    event SaleCreated(address sale, address seller);

    constructor(address admin, address _treasury) Ownable(admin) {
        treasury = _treasury;
    }

    function createAuction(uint256 _duration, uint256 _startingPrice)
        public
        returns (address)
    {
        Auction newAuction = new Auction(_duration, _startingPrice, msg.sender, owner());
        auctions.push(address(newAuction));
        userAuctions[msg.sender].push(address(newAuction));

        emit AuctionCreated(address(newAuction), msg.sender);

        return address(newAuction);
    }

    function createSale(uint256 _price) public returns (address) {
        Sale newSale = new Sale(_price, msg.sender, owner());
        sales.push(address(newSale));
        userSales[msg.sender].push(address(newSale));

        emit SaleCreated(address(newSale), msg.sender);

        return address(newSale);
    }
    

    function getAuctions() public view returns (address[] memory) {
        return auctions;
    }

    function getUserAuctions(address user) public view returns (address[] memory) {
        return userAuctions[user];
    }

    function getSales() public view returns (address[] memory) {
        return sales;
    }

    function getUserSales(address user) public view returns (address[] memory) {
        return userSales[user];
    }

    function setAuctionTaxes(uint256 _sellerTax) public onlyOwner {
        auctionSellerTax = _sellerTax;
    }

    function setSaleTaxes(uint256 _sellerTax) public onlyOwner {
        saleSellerTax = _sellerTax;
    }

    function setTreasury(address _treasury) public onlyOwner {
        treasury = _treasury;
    }

    function setAuctionDeadlineDelay(uint256 _delay) public onlyOwner {
        auctionDeadlineDelay = _delay;
    }

    function setSaleDeadlineDelay(uint256 _delay) public onlyOwner {
        saleDeadlineDelay = _delay;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAuctionFactory.sol";

contract Auction is Ownable {
    address payable public seller;
    uint256 public auctionEndTime;
    uint256 public startingPrice;
    uint256 public deadline;

    address public highestBidder;
    uint256 public highestBid;
    uint256 public bidCount;

    bool public confirmed = false;
    bool public ended = false;
    bool public frozen = false;

    IAuctionFactory public auctionFactory;

    uint256 public sellerTax;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor(
        uint256 _duration,
        uint256 _startingPrice,
        address _seller,
        address admin
    ) Ownable(admin) {
        auctionFactory = IAuctionFactory(msg.sender);

        auctionEndTime = block.timestamp + _duration;
        startingPrice = _startingPrice;
        deadline = auctionEndTime + auctionFactory.auctionDeadlineDelay();
        seller = payable(_seller);
    }

    /**
     * @dev Allows users to bid on the auction.
     */
    function bid() public payable {
        require(block.timestamp <= auctionEndTime, "Auction already ended.");
        require(!ended, "Auction has already ended.");
        require(
            msg.sender != seller,
            "Seller cannot bid on their own auction."
        );

        if (msg.sender == highestBidder) {
            highestBid += msg.value;
        } else {
            require(
                msg.value >= startingPrice,
                "Bid must be greater or equal than starting price."
            );
            require(msg.value > highestBid, "There already is a higher bid.");

            bool tmpSuccess;
            (tmpSuccess, ) = highestBidder.call{value: highestBid, gas: 30000}(
                ""
            );
            require(tmpSuccess, "Transfer failed.");
            highestBidder = msg.sender;
            highestBid = msg.value;
            bidCount++;
        }

        emit HighestBidIncreased(msg.sender, msg.value);
    }

    /**
     * @dev Allows auction's winner to confirm the transaction.
     */
    function bidderConfirms() public {
        require(
            block.timestamp >= auctionEndTime,
            "Auction has not ended yet."
        );
        require(
            msg.sender == highestBidder || msg.sender == owner(),
            "Only the highest bidder can call this function."
        );
        require(!confirmed, "Highest bidder has already confirmed.");

        confirmed = true;

        _auctionEnd(seller);
    }

    /**
     * @dev Allows either the seller or the highest bidder to end the auction, depending on the situation.
     */
    function auctionEnd() public {
        _auctionEnd(msg.sender);
    }

    function _auctionEnd(address sender) internal {
        require(block.timestamp >= auctionEndTime, "Auction not yet ended.");
        require(!frozen, "Auction is frozen.");
        require(!ended, "Auction has already ended.");

        // If the auction has ended, highest bidder has not confirmed
        if (!confirmed) {
            require(
                block.timestamp > block.timestamp + deadline,
                "Deadline not yet reached."
            );
            require(
                sender == highestBidder,
                "Only the highest bidder can end the auction."
            );

            bool tmpSuccess;
            (tmpSuccess, ) = highestBidder.call{
                value: highestBid,
                gas: 30000
            }("");
            require(tmpSuccess, "Transfer failed.");
        }
        // If the auction has ended, the highest bidder has paid and confirmed
        else if (confirmed) {
            require(sender == seller, "Only the seller can end the auction.");

            sellerTax = auctionFactory.auctionSellerTax();
            uint256 sellerPayment = highestBid -
                ((highestBid * sellerTax) / 100);
            uint256 toTreasury = address(this).balance - sellerPayment;

            bool tmpSuccess;
            (tmpSuccess, ) = seller.call{value: sellerPayment, gas: 30000}("");
            require(tmpSuccess, "Transfer failed.");

            _toTreasury(toTreasury);
        }

        ended = true;

        emit AuctionEnded(highestBidder, highestBid);
    }

    function cancelAuction() public {
        require(
            msg.sender == seller || msg.sender == owner(),
            "Only the seller can cancel the auction."
        );
        require(!ended, "Auction has already ended.");

        ended = true;

        if (highestBid != 0) {
            bool tmpSuccess;
            (tmpSuccess, ) = highestBidder.call{
                value: highestBid,
                gas: 30000
            }("");
            require(tmpSuccess, "Transfer failed.");
        }
    }

    /**
     * @dev Allows the owner to freeze the auction.
     */
    function freeze(bool a) public onlyOwner {
        frozen = a;
    }

    /**
     * @dev Allows the owner to withdraw the funds from the contract.
     * @param recipient The address to send the funds to.
     * @notice This function is only callable by the owner, IT SHOULD NOT BE USED OTHERWISE.
     */
    function emergencyWithdraw(address recipient) public onlyOwner {
        _emergencyWithdraw(recipient);
    }

    function _emergencyWithdraw(address recipient) internal {
        bool tmpSuccess;
        (tmpSuccess, ) = recipient.call{
            value: address(this).balance,
            gas: 30000
        }("");
        require(tmpSuccess, "Transfer failed.");
    }

    function _toTreasury(uint256 amount) internal {
        bool tmpSuccess;
        (tmpSuccess, ) = auctionFactory.treasury().call{
            value: amount,
            gas: 30000
        }("");
        require(tmpSuccess, "Transfer failed.");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAuctionFactory {
    function auctionSellerTax() external view returns (uint256);
    function saleSellerTax() external view returns (uint256);
    function treasury() external view returns (address);
    function auctionDeadlineDelay() external view returns (uint256);
    function saleDeadlineDelay() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAuctionFactory.sol";

contract Sale is Ownable {
    address payable public seller;
    uint256 public price;
    uint256 public saleTime;
    uint256 public deadline;

    address public buyer;

    bool public hasPaid = false;
    bool public confirmed = false;
    bool public ended = false;
    bool public frozen = false;

    IAuctionFactory public auctionFactory;

    uint256 public sellerTax;

    event Buy(address buyer, uint256 price);
    event SaleSuccess(address buyer, address seller, uint256 price);
    event SaleReverted(address buyer, address seller, uint256 price);

    constructor(
        uint256 _price,
        address _seller,
        address admin
    ) Ownable(admin) {
        auctionFactory = IAuctionFactory(msg.sender);

        price = _price;
        seller = payable(_seller);
    }

    modifier onlySeller() {
        require(
            msg.sender == seller || msg.sender == owner(),
            "Only the seller can call this function."
        );
        _;
    }

    /**
     * @dev Allows any user to buy the item.
     * @notice Funds are stored in the contract until irl transaction is complete.
     */
    function buy() public payable {
        require(
            msg.value == price,
            "You must pay the price."
        );
        require(!hasPaid, "You have already paid.");
        require(!ended, "Sale has already ended.");

        deadline = block.timestamp + auctionFactory.saleDeadlineDelay();

        hasPaid = true;

        buyer = msg.sender;

        emit Buy(msg.sender, price);
    }

    /**
     * @dev Allows buyer to confirm the transaction.
     */
    function buyerConfirms() public {
        require(
            msg.sender == buyer || msg.sender == owner(),
            "Only the buyer can call this function."
        );
        require(hasPaid, "Buyer has not paid yet.");
        require(!confirmed, "Buyer has already confirmed.");

        confirmed = true;

        _saleEnd(seller);
    }

    /**
     * @dev Allows either the seller or the buyer to end the sale, depending on the situation.
     */
    function saleEnd() public {
        _saleEnd(msg.sender);
    }

    function _saleEnd(address sender) internal {
        require(!frozen, "Sale is frozen.");
        require(!ended, "Sale has already ended.");

        // If buyer has not confirmed
        if (!confirmed) {
            require(
                block.timestamp > block.timestamp + deadline,
                "Deadline not yet reached."
            );
            require(
                sender == buyer,
                "Only the buyer can end the sale."
            );

            bool tmpSuccess;
            (tmpSuccess, ) = buyer.call{
                value: price,
                gas: 30000
            }("");
            require(tmpSuccess, "Transfer failed.");

            emit SaleReverted(buyer, seller, price);
        }
        // If buyer has confirmed
        else if (confirmed) {
            require(sender == seller, "Only the seller can end the sale.");

            sellerTax = auctionFactory.saleSellerTax();
            uint256 sellerPayment = price -
                ((price * sellerTax) / 100);
            uint256 toTreasury = address(this).balance - sellerPayment;

            bool tmpSuccess;
            (tmpSuccess, ) = seller.call{value: sellerPayment, gas: 30000}("");
            require(tmpSuccess, "Transfer failed.");

            _toTreasury(toTreasury);

            emit SaleSuccess(buyer, seller, price);
        }

        ended = true;
    }

    /**
     * @dev Allows the seller to modify the price of the item.
     * @param _newPrice The new price of the item.
     */
    function modifyPrice(uint256 _newPrice) public onlySeller {
        require(!hasPaid, "Item already bought.");

        price = _newPrice;
    }

    /**
     * @dev Allows the seller to cancel the sale.
     */
    function cancelSale() public onlySeller {
        require(!ended, "Sale has already ended.");

        ended = true;

        if (hasPaid) {
            bool tmpSuccess;
            (tmpSuccess, ) = buyer.call{
                value: price,
                gas: 30000
            }("");
            require(tmpSuccess, "Transfer failed.");
        }
    }

    /**
     * @dev Allows the owner to freeze the auction.
     */
    function freeze(bool a) public onlyOwner {
        frozen = a;
    }

    /**
     * @dev Allows the owner to withdraw the funds from the contract.
     * @param recipient The address to send the funds to.
     * @notice This function is only callable by the owner, IT SHOULD NOT BE USED OTHERWISE.
     */
    function emergencyWithdraw(address recipient) public onlyOwner {
        _emergencyWithdraw(recipient);
    }

    function _emergencyWithdraw(address recipient) internal {
        bool tmpSuccess;
        (tmpSuccess, ) = recipient.call{
            value: address(this).balance,
            gas: 30000
        }("");
        require(tmpSuccess, "Transfer failed.");
    }

    function _toTreasury(uint256 amount) internal {
        bool tmpSuccess;
        (tmpSuccess, ) = auctionFactory.treasury().call{
            value: amount,
            gas: 30000
        }("");
        require(tmpSuccess, "Transfer failed.");
    }
}