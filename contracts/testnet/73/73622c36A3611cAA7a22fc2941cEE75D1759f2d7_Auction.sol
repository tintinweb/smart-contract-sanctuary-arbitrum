// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {IPriceOracle} from "../arbregistrar/IARBRegistrarController.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {StringUtils} from "../common/StringUtils.sol";

error InvalidLabel(string label);
error NotEnoughQuota();
error BidAmountTooLow(uint minBidAmount);
error AuctionHardDeadlinePassed();
error AuctionNotEnded();
error AuctionEnded();
error AuctionNotStarted();
error AuctionStarted();
error AuctionWinnerCannotWithdraw();
error CannotWithdrawZeroAmount();

contract Auction is Ownable {
    using StringUtils for *;

    uint256 public constant MIN_REGISTRATION_DURATION = 365 days;

    // TokenAuctionStatus stores the state of an auction.
    struct TokenAuctionStatus {
        // the label string.
        string label;
        // the current highest bidder.
        address winner;
        // current endTime.
        uint endTime;
        // the number of amount bidded by users, when withdraw
        // the value will be reset to 0.
        mapping(address => uint) userFunds;
    }

    // UserStatus stores user's available quota and enumerable bids.
    struct UserStatus {
        // user address to the available quota the user has for bidding on new domains.
        uint8 quota;
        // list tokenIDs that he has bidded.
        uint256[] bids;
        // map user to the tokenIDs that he has bidded.
        mapping(uint256 => bool) bided;
    }

    // pair of amount and tokenID.
    struct TopBid {
        uint256 tokenID;
        uint256 bid;
    }

    // pair of amount and label.
    struct TopBidView {
        string label;
        uint256 bid;
    }

    // deps
    IPriceOracle public immutable prices;

    // static
    // TBD: arbitrum time
    // https://github.com/OffchainLabs/arbitrum/blob/master/docs/Time_in_Arbitrum.md
    uint public immutable startTime;
    uint public immutable initialEndTime;
    uint public immutable hardEndTime;
    uint public immutable extendDuration; //in second

    ////// state
    // map user address to his auction status.
    mapping(address => UserStatus) public userStatus;
    //// map token ID to its auction status
    mapping(uint256 => TokenAuctionStatus) public auctionStatus;
    // Top ten bidded domains.
    TopBid[10] public topBids;
    // The total amount that the auction contract owner can withdraw.
    // Withdraw can only happen after hardEndTime and the value will be reset to 0, after withdraw.
    uint256 public ownerCanWithdraw;

    // TODO: add events.
    // event LogBid(
    //     address bidder,
    //     uint bid,
    //     address highestBidder,
    //     uint highestBid
    // );
    // event LogWithdrawal(
    //     address withdrawer,
    //     address withdrawalAccount,
    //     uint amount
    // );

    constructor(
        IPriceOracle _prices,
        uint _startTime,
        uint _initialEndTime,
        uint _hardEndTime,
        uint _extendDuration
    ) {
        require(_startTime < _initialEndTime);
        require(_initialEndTime < _hardEndTime);
        require(_startTime > block.timestamp);
        require(_extendDuration > 0);

        prices = _prices;
        startTime = _startTime;
        initialEndTime = _initialEndTime;
        hardEndTime = _hardEndTime;
        extendDuration = _extendDuration;
    }

    // place a bid on @p label, total bid amount will be aggregated, returns the new bid value.
    function placeBid(
        string calldata label
    ) public payable onlyAfterStart onlyBeforeHardEnd returns (uint) {
        // reject payments of 0 ETH
        if (msg.value <= 0) {
            revert BidAmountTooLow(1);
        }

        uint256 tokenID = uint256(keccak256(bytes(label)));

        // consume quota
        _consumeQuota(msg.sender, tokenID);

        // verify label and initialize auction status if this is the first bid.
        _initAuctionStatus(tokenID, label);
        TokenAuctionStatus storage status = auctionStatus[tokenID];

        // per-label endtime check
        if (block.timestamp > status.endTime) {
            revert AuctionEnded();
        }

        // verify amount and update auction status
        uint newBid = status.userFunds[msg.sender] + msg.value;
        uint minBid = nextBidFloorPrice(tokenID, label);
        if (newBid < minBid) {
            revert BidAmountTooLow(minBid);
        }
        address prevWinner = status.winner;
        uint prevHighestBid = status.userFunds[prevWinner];
        // does not matter if new winner is the same or not.
        status.winner = msg.sender;
        status.userFunds[msg.sender] = newBid;
        ownerCanWithdraw += (newBid - prevHighestBid);

        // extend end time if necessary, but do not exceed hardEndTime.
        if (status.endTime - block.timestamp <= extendDuration) {
            status.endTime = block.timestamp + extendDuration;
            if (status.endTime > hardEndTime) {
                status.endTime = hardEndTime; // probably not necessary but not bad to keep.
            }
        }
        
        // update top ten bid
        _updateTopBids(tokenID, newBid);

        return newBid;
    }

    function _updateTopBids(uint256 tokenID, uint256 newBid) private {
        // rank0 to rank9 will be used.
        uint8 rank = 10;
        for (; rank > 0; rank--) {
            // optimization: most bids won't make it to top 10.
            if (newBid < topBids[rank - 1].bid) {
                break;
            }
        }
        //deduplication check
        bool exist = false;
        uint8 dupIndex = 0;
        for (uint8 i = rank + 1; i < 10; i++) {
            if (topBids[i].tokenID == tokenID) {      
                exist = true;
                dupIndex = i;
                break;
            }
        }
        if(exist) {
            for (uint8 j = dupIndex; j < 10; j++) {
                topBids[j] = topBids[j + 1];
            }
        }
        if (rank < 10) {
            for (uint8 j = 9; j > rank; j--) {
                topBids[j] = topBids[j - 1];
            }
            topBids[rank].tokenID = tokenID;
            topBids[rank].bid = newBid;
        }
    }

    // withdraw fund bidded on @p label, if not the winner.
    function withdraw(string calldata label) public returns (uint) {
        uint256 tokenID = uint256(keccak256(bytes(label)));
        TokenAuctionStatus storage status = auctionStatus[tokenID];
        if (status.winner == msg.sender) {
            revert AuctionWinnerCannotWithdraw();
        }
        uint amount = status.userFunds[msg.sender];
        status.userFunds[msg.sender] = 0;
        if (amount == 0) {
            revert CannotWithdrawZeroAmount();
        }

        // send the funds
        payable(msg.sender).transfer(amount);
        return amount;
    }

    // contract owner withdraw all winner amount.
    function ownerWithdraw() public onlyOwner onlyAfterHardEnd {
        uint amount = ownerCanWithdraw;
        ownerCanWithdraw = 0;
        if (amount == 0) {
            revert CannotWithdrawZeroAmount();
        }
        payable(msg.sender).transfer(amount);
    }

    // set user quota, only possible before auction starts.
    function setUserQuota(
        address user,
        uint8 quota
    ) public onlyOwner onlyBeforeStart {
        UserStatus storage us = userStatus[user];
        us.quota = quota;
    }

    // Each bid to a new tokenID will consume a quota.
    // When the quota drops to 0, users can’t bid for a new domain.
    function _consumeQuota(address user, uint256 tokenID) private {
        // user has bidded on this tokenID before, no more quota required.
        if (userStatus[user].bided[tokenID]) {
            return;
        }
        UserStatus storage us = userStatus[user];
        if (userStatus[user].quota < 1) {
            revert NotEnoughQuota();
        }
        us.quota -= 1;
        us.bided[tokenID] = true;
        us.bids.push(tokenID);
    }

    // initialize auction status label and endtime, if not initialized yet.
    // It will also check @p lable validity, revert if invalid.
    function _initAuctionStatus(
        uint256 tokenID,
        string calldata label
    ) private {
        if (!valid(label)) {
            revert InvalidLabel(label);
        }
        TokenAuctionStatus storage status = auctionStatus[tokenID];
        // auction of @p label is already initialialzed, just return.
        if (status.endTime != 0) {
            return;
        }
        status.label = label;
        status.endTime = initialEndTime;
    }

    // returns the min bid price for @p tokenID.
    // If there's already a bid on @p TokenID, price = (lastBid * 105%).
    // otherwise, the min bid price will be the 1-year registration fee.
    function nextBidFloorPrice(
        uint256 tokenID,
        string calldata name
    ) public view returns (uint) {
        TokenAuctionStatus storage status = auctionStatus[tokenID];
        if (status.winner != address(0)) {
            // If any user bids, min bid is set at 105% of the top bid.
            uint currentHighest = status.userFunds[status.winner];
            return (currentHighest / 100) * 105;
        } else {
            IPriceOracle.Price memory price = prices.price(
                name,
                0,
                MIN_REGISTRATION_DURATION
            );
            return price.base;
        }
    }

    function topBidsView() public view returns (TopBidView[10] memory rv) {
        for (uint i = 0; i < topBids.length; i++) {
            rv[i] = (
                TopBidView(
                    auctionStatus[topBids[i].tokenID].label,
                    topBids[i].bid
                )
            );
        }
    }

    // returns true if the name is valid.
    function valid(string calldata name) public pure returns (bool) {
        // check unicode rune count, if rune count is >=3, byte length must be >=3.
        if (name.strlen() < 3) {
            return false;
        }
        bytes memory nb = bytes(name);
        // zero width for /u200b /u200c /u200d and U+FEFF
        for (uint256 i; i < nb.length - 2; i++) {
            if (bytes1(nb[i]) == 0xe2 && bytes1(nb[i + 1]) == 0x80) {
                if (
                    bytes1(nb[i + 2]) == 0x8b ||
                    bytes1(nb[i + 2]) == 0x8c ||
                    bytes1(nb[i + 2]) == 0x8d
                ) {
                    return false;
                }
            } else if (bytes1(nb[i]) == 0xef) {
                if (bytes1(nb[i + 1]) == 0xbb && bytes1(nb[i + 2]) == 0xbf)
                    return false;
            }
        }
        return true;
    }

    // returns true if @p user is the winner of auction on @p tokenID.
    function isWinner(
        address user,
        uint256 tokenID
    ) public view returns (bool) {
        return auctionStatus[tokenID].winner == user;
    }

    // returns the number of quota that the @p user can use in phase 2.
    function phase2Quota(address user) public view returns (uint8) {
        UserStatus storage us = userStatus[user];
        uint8 quota = us.quota;
        for (uint8 i = 0; i < us.bids.length; i++) {
            if (!isWinner(user, us.bids[i])) {
                quota++;
            }
        }
        return quota;
    }

    function min(uint a, uint b) private pure returns (uint) {
        if (a < b) return a;
        return b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    modifier onlyBeforeStart() {
        if (block.timestamp >= startTime) {
            revert AuctionStarted();
        }
        _;
    }

    modifier onlyAfterStart() {
        if (block.timestamp < startTime) {
            revert AuctionNotStarted();
        }
        _;
    }

    modifier onlyBeforeHardEnd() {
        if (block.timestamp > hardEndTime) {
            revert AuctionHardDeadlinePassed();
        }
        _;
    }

    modifier onlyAfterHardEnd() {
        if (block.timestamp <= hardEndTime) {
            revert AuctionNotEnded();
        }
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../price-oracle/IPriceOracle.sol";

interface IARBRegistrarController {
    function rentPrice(string memory, uint256)
        external
        view
        returns (IPriceOracle.Price memory);

    function available(string memory) external returns (bool);

    function makeCommitment(
        string memory,
        address,
        bytes32
    ) external pure returns (bytes32);

    function commit(bytes32) external;

    function registerWithConfig(
        string calldata,
        address,
        uint256,
        bytes32,
        address,
        bool
    ) external payable;

    function renew(string calldata, uint256) external payable;
}

pragma solidity >=0.8.4;

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint) {
        uint len;
        uint i = 0;
        uint bytelength = bytes(s).length;
        for(len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if(b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
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
pragma solidity >=0.8.4;

interface IPriceOracle {
    struct Price {
        uint256 base;
        uint256 premium;
    }
    
    function price(
        string calldata name,
        uint256 expires,
        uint256 duration
    ) external view returns (Price calldata);

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