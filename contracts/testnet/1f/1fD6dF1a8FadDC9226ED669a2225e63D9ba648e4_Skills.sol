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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's Red-Black Tree Library v1.0-pre-release-a
//
// A Solidity Red-Black Tree binary search library to store and access a sorted
// list of unsigned integer data. The Red-Black algorithm rebalances the binary
// search tree, resulting in O(log n) insert, remove and search time (and ~gas)
//
// https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2020. The MIT Licence.
// ----------------------------------------------------------------------------
library BokkyPooBahsRedBlackTreeLibrary {

    struct Node {
        uint parent;
        uint left;
        uint right;
        bool red;
    }

    struct Tree {
        uint root;
        mapping(uint => Node) nodes;
    }

    uint private constant EMPTY = 0;

    function first(Tree storage self) internal view returns (uint _key) {
        _key = self.root;
        if (_key != EMPTY) {
            while (self.nodes[_key].left != EMPTY) {
                _key = self.nodes[_key].left;
            }
        }
    }
    function last(Tree storage self) internal view returns (uint _key) {
        _key = self.root;
        if (_key != EMPTY) {
            while (self.nodes[_key].right != EMPTY) {
                _key = self.nodes[_key].right;
            }
        }
    }
    function next(Tree storage self, uint target) internal view returns (uint cursor) {
        require(target != EMPTY);
        if (self.nodes[target].right != EMPTY) {
            cursor = treeMinimum(self, self.nodes[target].right);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].right) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }
    function prev(Tree storage self, uint target) internal view returns (uint cursor) {
        require(target != EMPTY);
        if (self.nodes[target].left != EMPTY) {
            cursor = treeMaximum(self, self.nodes[target].left);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].left) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }
    function exists(Tree storage self, uint key) internal view returns (bool) {
        return (key != EMPTY) && ((key == self.root) || (self.nodes[key].parent != EMPTY));
    }
    function isEmpty(uint key) internal pure returns (bool) {
        return key == EMPTY;
    }
    function getEmpty() internal pure returns (uint) {
        return EMPTY;
    }
    function getNode(Tree storage self, uint key) internal view returns (uint _returnKey, uint _parent, uint _left, uint _right, bool _red) {
        require(exists(self, key));
        return(key, self.nodes[key].parent, self.nodes[key].left, self.nodes[key].right, self.nodes[key].red);
    }

    function insert(Tree storage self, uint key) internal {
        require(key != EMPTY);
        require(!exists(self, key));
        uint cursor = EMPTY;
        uint probe = self.root;
        while (probe != EMPTY) {
            cursor = probe;
            if (key < probe) {
                probe = self.nodes[probe].left;
            } else {
                probe = self.nodes[probe].right;
            }
        }
        self.nodes[key] = Node({parent: cursor, left: EMPTY, right: EMPTY, red: true});
        if (cursor == EMPTY) {
            self.root = key;
        } else if (key < cursor) {
            self.nodes[cursor].left = key;
        } else {
            self.nodes[cursor].right = key;
        }
        insertFixup(self, key);
    }
    function remove(Tree storage self, uint key) internal {
        require(key != EMPTY);
        require(exists(self, key));
        uint probe;
        uint cursor;
        if (self.nodes[key].left == EMPTY || self.nodes[key].right == EMPTY) {
            cursor = key;
        } else {
            cursor = self.nodes[key].right;
            while (self.nodes[cursor].left != EMPTY) {
                cursor = self.nodes[cursor].left;
            }
        }
        if (self.nodes[cursor].left != EMPTY) {
            probe = self.nodes[cursor].left;
        } else {
            probe = self.nodes[cursor].right;
        }
        uint yParent = self.nodes[cursor].parent;
        self.nodes[probe].parent = yParent;
        if (yParent != EMPTY) {
            if (cursor == self.nodes[yParent].left) {
                self.nodes[yParent].left = probe;
            } else {
                self.nodes[yParent].right = probe;
            }
        } else {
            self.root = probe;
        }
        bool doFixup = !self.nodes[cursor].red;
        if (cursor != key) {
            replaceParent(self, cursor, key);
            self.nodes[cursor].left = self.nodes[key].left;
            self.nodes[self.nodes[cursor].left].parent = cursor;
            self.nodes[cursor].right = self.nodes[key].right;
            self.nodes[self.nodes[cursor].right].parent = cursor;
            self.nodes[cursor].red = self.nodes[key].red;
            (cursor, key) = (key, cursor);
        }
        if (doFixup) {
            removeFixup(self, probe);
        }
        delete self.nodes[cursor];
    }

    function treeMinimum(Tree storage self, uint key) private view returns (uint) {
        while (self.nodes[key].left != EMPTY) {
            key = self.nodes[key].left;
        }
        return key;
    }
    function treeMaximum(Tree storage self, uint key) private view returns (uint) {
        while (self.nodes[key].right != EMPTY) {
            key = self.nodes[key].right;
        }
        return key;
    }

    function rotateLeft(Tree storage self, uint key) private {
        uint cursor = self.nodes[key].right;
        uint keyParent = self.nodes[key].parent;
        uint cursorLeft = self.nodes[cursor].left;
        self.nodes[key].right = cursorLeft;
        if (cursorLeft != EMPTY) {
            self.nodes[cursorLeft].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].left) {
            self.nodes[keyParent].left = cursor;
        } else {
            self.nodes[keyParent].right = cursor;
        }
        self.nodes[cursor].left = key;
        self.nodes[key].parent = cursor;
    }
    function rotateRight(Tree storage self, uint key) private {
        uint cursor = self.nodes[key].left;
        uint keyParent = self.nodes[key].parent;
        uint cursorRight = self.nodes[cursor].right;
        self.nodes[key].left = cursorRight;
        if (cursorRight != EMPTY) {
            self.nodes[cursorRight].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].right) {
            self.nodes[keyParent].right = cursor;
        } else {
            self.nodes[keyParent].left = cursor;
        }
        self.nodes[cursor].right = key;
        self.nodes[key].parent = cursor;
    }

    function insertFixup(Tree storage self, uint key) private {
        uint cursor;
        while (key != self.root && self.nodes[self.nodes[key].parent].red) {
            uint keyParent = self.nodes[key].parent;
            if (keyParent == self.nodes[self.nodes[keyParent].parent].left) {
                cursor = self.nodes[self.nodes[keyParent].parent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].right) {
                        key = keyParent;
                        rotateLeft(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateRight(self, self.nodes[keyParent].parent);
                }
            } else {
                cursor = self.nodes[self.nodes[keyParent].parent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].left) {
                        key = keyParent;
                        rotateRight(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateLeft(self, self.nodes[keyParent].parent);
                }
            }
        }
        self.nodes[self.root].red = false;
    }

    function replaceParent(Tree storage self, uint a, uint b) private {
        uint bParent = self.nodes[b].parent;
        self.nodes[a].parent = bParent;
        if (bParent == EMPTY) {
            self.root = a;
        } else {
            if (b == self.nodes[bParent].left) {
                self.nodes[bParent].left = a;
            } else {
                self.nodes[bParent].right = a;
            }
        }
    }
    function removeFixup(Tree storage self, uint key) private {
        uint cursor;
        while (key != self.root && !self.nodes[key].red) {
            uint keyParent = self.nodes[key].parent;
            if (key == self.nodes[keyParent].left) {
                cursor = self.nodes[keyParent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateLeft(self, keyParent);
                    cursor = self.nodes[keyParent].right;
                }
                if (!self.nodes[self.nodes[cursor].left].red && !self.nodes[self.nodes[cursor].right].red) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].right].red) {
                        self.nodes[self.nodes[cursor].left].red = false;
                        self.nodes[cursor].red = true;
                        rotateRight(self, cursor);
                        cursor = self.nodes[keyParent].right;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].right].red = false;
                    rotateLeft(self, keyParent);
                    key = self.root;
                }
            } else {
                cursor = self.nodes[keyParent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateRight(self, keyParent);
                    cursor = self.nodes[keyParent].left;
                }
                if (!self.nodes[self.nodes[cursor].right].red && !self.nodes[self.nodes[cursor].left].red) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].left].red) {
                        self.nodes[self.nodes[cursor].right].red = false;
                        self.nodes[cursor].red = true;
                        rotateLeft(self, cursor);
                        cursor = self.nodes[keyParent].left;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].left].red = false;
                    rotateRight(self, keyParent);
                    key = self.root;
                }
            }
        }
        self.nodes[key].red = false;
    }
}
// ----------------------------------------------------------------------------
// End - BokkyPooBah's Red-Black Tree Library
// ----------------------------------------------------------------------------

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.11 <=0.9.0;

/**
 * @title Burner
 * @dev This contract is meant to receive funds and then self destruct removing the funds from circulation.
 */
contract Burner {

    receive() external payable {}

    function burn() external {
        // Selfdestruct and send eth to self,
        selfdestruct(payable(this));
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <=0.9.0;

import "token-bridge-contracts/contracts/tokenbridge/libraries/IWETH9.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IWETH9Ext is IWETH9, IERC20 {
    function depositTo(address account) external payable;
    function withdrawTo(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.11 <=0.9.0;

import "./IWETH9Ext.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./BokkyPooBahsRedBlackTreeLibrary.sol";
import "./Burner.sol";

/**
 * @title Skills
 * @dev The contract for creating orders and getting rewards for the Expopulus DAPP
 */
contract Skills {

    // for keeping the scores we use the BokkyPooBahs Black Tree Library
    using BokkyPooBahsRedBlackTreeLibrary for BokkyPooBahsRedBlackTreeLibrary.Tree;
    mapping(uint => uint) private _scoreValues;

    // used to assign an index to the Orders
    using Counters for Counters.Counter;
    Counters.Counter private _orderCounter;

    enum OrderStatus{
        OPEN,
        COMPLETED,
        EXPIRED
    }

    struct Order {
        address creator;
        uint256 totalReturn;
        uint256 originalStake;
        uint256 stakeMultiple;
        uint startDate;
        uint endDate;
        uint256 submissionsAllotted;
        uint256 submissionsSubmitted;
        uint256 numberOfWinners;
        OrderStatus status;
    }

    mapping(uint256 => Order) _orders;
    mapping(uint256 => BokkyPooBahsRedBlackTreeLibrary.Tree) _scoreTrees;
    mapping(uint256 => mapping(uint => address[])) _addressLookup; // orderId -> score -> address[]
    uint256 private _allocatedFunds = 0;
    address payable private _wxpAddress;
    uint256 private _minimumStake;
    uint256 private _maximumStake;
    uint256 private _stakeMultiple;
    uint256 private _minimumNumberOfSubmissionsPerOrder;
    uint256 private _maximumNumberOfSubmissionsPerOrder;
    uint256 private _maximumNumberOfWinnersPerOrder;
    uint256 private _winnerRewardAmount;
    uint private _eventHorizon;
    uint private _minimumOrderDuration;
    uint private _maximumOrderDuration;

    event OrderCreated(uint256 indexed id);

    constructor(
        address payable wxpAddress,
        uint256 minimumStake,
        uint256 maximumStake,
        uint256 stakeMultiple,
        uint256 minimumNumberOfSubmissionsPerOrder,
        uint256 maximumNumberOfSubmissionsPerOrder,
        uint256 maximumNumberOfWinnersPerOrder,
        uint256 winnerRewardAmount,
        uint eventHorizon,
        uint minimumOrderDuration,
        uint maximumOrderDuration
    ) {
        _wxpAddress = wxpAddress;
        _minimumStake = minimumStake;
        _maximumStake = maximumStake;
        _minimumNumberOfSubmissionsPerOrder = minimumNumberOfSubmissionsPerOrder;
        _maximumNumberOfSubmissionsPerOrder = maximumNumberOfSubmissionsPerOrder;
        _maximumNumberOfWinnersPerOrder = maximumNumberOfWinnersPerOrder;
        _stakeMultiple = stakeMultiple;
        _winnerRewardAmount = winnerRewardAmount;
        _eventHorizon = eventHorizon;
        _minimumOrderDuration = minimumOrderDuration;
        _maximumOrderDuration = maximumOrderDuration;
    }

    /**
     * @dev Create a new order in the system. The function will return the Id of the order.
     */
    function stake(uint endDate, uint256 submissionsAllotted, uint256 numberOfWinners) payable virtual external returns(uint256) {
        require(msg.value >= _minimumStake, "This amount is below the minimum stake.");
        require(msg.value <= _maximumStake, "This amount is beyond the maximum stake.");
        require(msg.value > 0, "You must specify an amount > 0.");

        //check the end date is valid
        require(endDate > block.timestamp, "The end date is in the past.");
        require(endDate < _eventHorizon, "The order must end before the event horizon.");
        uint duration = endDate - block.timestamp;
        require(duration >= _minimumOrderDuration, "The order duration is too short.");
        require(duration <= _maximumOrderDuration, "The order duration is too long.");

        // check the submissionsAllotted
        require(submissionsAllotted >= _minimumNumberOfSubmissionsPerOrder, "The submissions allotted is below the minimum.");
        require(submissionsAllotted <= _maximumNumberOfSubmissionsPerOrder, "The submissions allotted is above the maximum.");
        require(numberOfWinners > 0, "The number of winners must be greater than 0.");
        require(numberOfWinners <= submissionsAllotted, "The number of winners must be less than or equal to the submissions allotted.");
        require(numberOfWinners <= _maximumNumberOfWinnersPerOrder, "The number of winners must be less than the maximum number of winners per order.");

        // get the balance of this contract so we are able to check the amount of unallocatedFunds
        IWETH9Ext weth = IWETH9Ext(_wxpAddress);
        uint256 currentBalance = weth.balanceOf(address(this));
        uint256 unallocatedFunds = currentBalance - _allocatedFunds;

        // check to see if there is enough rewards available in the contract to distribute afterwards.
        uint256 totalReturn = msg.value * _stakeMultiple / 100;
        uint256 winnerPayoutAmount = _winnerRewardAmount * numberOfWinners;
        uint256 fundsNeeded = totalReturn - msg.value + winnerPayoutAmount;
        require(unallocatedFunds > fundsNeeded, "There is not enough reward to fulfill this order.");

        // convert the value into the WETH equivalent and deposit to this contract
        _allocatedFunds += (winnerPayoutAmount + totalReturn);
        weth.depositTo{value: msg.value}(address(this));

        // add the order to the map
        uint256 currentIndex = _orderCounter.current();
        _orders[currentIndex] = Order(
            msg.sender,
            totalReturn,
            msg.value,
            _stakeMultiple,
            block.timestamp,
            endDate,
            submissionsAllotted,
            0,
            numberOfWinners,
            OrderStatus.OPEN
        );
        _orderCounter.increment();

        // submit an event
        emit OrderCreated(currentIndex);

        // return the current index so the user can look up their order
        return currentIndex;
    }

    /**
     * @dev used to submit a score to be entered for an order
     */
    function submit(uint256 orderId, uint score) external virtual {
        // check the order is valid and active
        require(orderId < _orderCounter.current(), "The order submitted for has not been created yet.");

        // check the status is currently open
        require(_orders[orderId].status == OrderStatus.OPEN, "The order is no longer open, you cannot submit a score.");

        // check if the order is expired, if so go and expire the order
        if (block.timestamp >= _orders[orderId].endDate) {
            expireOrder(orderId);
            return;
        }

        require(_orders[orderId].submissionsSubmitted < _orders[orderId].submissionsAllotted, "The order has already been completed.");

        // due to a limitation of the binary search tree library, we cannot have a score of 0.
        require(score > 0, "A score of 0 is not allowed.");

        // increment the submissions
        _orders[orderId].submissionsSubmitted++;

        // check to see if a score of the same value has already been added. If it has not, then insert the score.
        // We don't want to accidentally add a score more than once, instead we keep an array of the address that
        // have submitted the same score.
        if (!_scoreTrees[orderId].exists(score)) {
            _scoreTrees[orderId].insert(score);
        }

        // add the sender to the array of addresses that have submitted the score
        _addressLookup[orderId][score].push(msg.sender);

        // finalize the order if the order is now complete
        if (_orders[orderId].submissionsSubmitted >= _orders[orderId].submissionsAllotted) {
            finalizeOrder(orderId);
        }
    }

    /**
     * @dev Used to end an order and distribute funds to the winners.
     */
    function finalizeOrder(uint256 orderId) internal virtual {

        // set the status to closed
        _orders[orderId].status = OrderStatus.COMPLETED;

        // send the reward to the order creator
        IWETH9Ext weth = IWETH9Ext(_wxpAddress);
        weth.withdrawTo(_orders[orderId].creator, _orders[orderId].totalReturn);

        // get the highest score and the first index of the addresses submitted for that score
        uint currentScore = _scoreTrees[orderId].last();
        uint256 currentAddressIndex = 0;

        // keep track of how many winners we have found so we know when to stop the loop.
        uint256 numberOfWinnersFound = 0;
        uint256 numberOfWinners = _orders[orderId].numberOfWinners;

        // find all the remaining winners
        while(numberOfWinnersFound < numberOfWinners) {

            // check to see if we are at the end of the submitters for the currentScore
            if ((_addressLookup[orderId][currentScore].length - 1) < currentAddressIndex) {
                currentAddressIndex = 0;
                currentScore = _scoreTrees[orderId].prev(currentScore);
                continue;
            }

            // send the winner their reward
            weth.withdrawTo(_addressLookup[orderId][currentScore][currentAddressIndex], _winnerRewardAmount);

            // increment the current index and winners found for the next iteration
            numberOfWinnersFound++;
            currentAddressIndex++;
        }

        // remove the allocated funds
        _allocatedFunds -= (numberOfWinners * _winnerRewardAmount + _orders[orderId].totalReturn);
    }

    /**
     * @dev Expires an order by burning any funds that were allocated to the order and not allowing submissions anymore
     */
    function expireOrder(uint256 orderId) internal virtual {
        // set the status to expired.
        _orders[orderId].status = OrderStatus.EXPIRED;

        // create a burner contract and transfer the allocated funds to it.
        uint256 allocatedFundsToBurn = _orders[orderId].totalReturn + (_orders[orderId].numberOfWinners * _winnerRewardAmount);
        Burner burner = new Burner();
        IWETH9Ext weth = IWETH9Ext(_wxpAddress);
        weth.withdrawTo(address(burner), allocatedFundsToBurn);

        // burn the funds that were sent to the burner.
        burner.burn();

        // remove the allocated funds to burn
        _allocatedFunds -= allocatedFundsToBurn;
    }

    /**
     * @dev Finds an order given the id.
     */
    function lookupOrder(uint256 id) external view virtual returns(Order memory) {
        return _orders[id];
    }

    /**
     * @dev Finds an order given the id.
     */
    function nextOrderId() external view virtual returns(uint256 id) {
        return _orderCounter.current();
    }

    /**
     * @dev Returns the current stake multiple for calculating the return on a stake.
     */
    function getStakeMultiple() external view virtual returns(uint256) {
        return _stakeMultiple;
    }

    /**
     * @dev Returns the minimum amount of submissions that allowed for an order
     */
    function getMinimumAndMaximumNumberOfSubmissionsPerOrder() external view virtual returns(uint256, uint256) {
        return (_minimumNumberOfSubmissionsPerOrder, _maximumNumberOfSubmissionsPerOrder);
    }

    /**
     * @dev Returns the current minimum stake.
     */
    function getMinimumAndMaximumStake() external view virtual returns(uint256, uint256) {
        return (_minimumStake, _maximumStake);
    }

    /**
     * @dev Returns the maximum number of winners allowed in a single order
     */
    function getMaximumNumberOfWinnersPerOrder() external view virtual returns(uint256) {
        return _maximumNumberOfWinnersPerOrder;
    }

    /**
     * @dev Returns the event horizon for when all of the tokens will be given out.
     */
    function getEventHorizon() external view virtual returns(uint) {
        return _eventHorizon;
    }

    /**
     * @dev Returns the minimum and maximum order durations in that order
     */
    function getMinimumAndMaximumDurations() external view virtual returns(uint, uint) {
        return (_minimumOrderDuration, _maximumOrderDuration);
    }

    /**
     * @dev Returns the minimum and maximum order durations in that order
     */
    function getAllocatedFunds() external view virtual returns(uint256) {
        return _allocatedFunds;
    }

    /**
     * @dev Used to get the funds currently not allocated out of the contract.
     */
    function withdrawUnallocatedFunds() external {
        // TODO Permissions or remove this function
        IWETH9Ext weth = IWETH9Ext(_wxpAddress);
        uint256 currentBalance = weth.balanceOf(address(this));
        uint256 unallocatedFunds = currentBalance - _allocatedFunds;
        weth.withdrawTo(msg.sender, unallocatedFunds);
    }

    /**
     * @dev Returns the highest score for a given order Id.
     */
    function getHighestScoreForOrder(uint256 orderId) external view virtual returns(uint) {
        return _scoreTrees[orderId].last();
    }

    /**
     * @dev Returns the next highest score after the score passed in for the order specified.
     */
    function getPreviousScoreForOrder(uint256 orderId, uint256 score) external view virtual returns(uint) {
        return _scoreTrees[orderId].prev(score);
    }

    /**
     * @dev Returns the submitter's address for the given score in the specified order. This is used to iterate over
     * everyone who has submitted the same score.
     */
    function getAddressForScore(uint256 orderId, uint256 score, uint256 index) external view virtual returns(address) {
        return _addressLookup[orderId][score][index];
    }
}

// SPDX-License-Identifier: Apache-2.0

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface IWETH9 {
    function deposit() external payable;

    function withdraw(uint256 _amount) external;
}