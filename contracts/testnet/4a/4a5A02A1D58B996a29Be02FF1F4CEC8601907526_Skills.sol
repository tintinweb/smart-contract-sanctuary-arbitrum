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

pragma solidity >=0.8.0 <=0.9.0;

import "token-bridge-contracts/contracts/tokenbridge/libraries/IWETH9.sol";


interface IWETH9Ext is IWETH9 {
    function depositTo(address account) external payable;
    function withdrawTo(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.11 <=0.9.0;

import "./IWETH9Ext.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./BokkyPooBahsRedBlackTreeLibrary.sol";

/**
 * @title Skills
 * @dev The contract for creating orders and getting rewards for the Expopulus DAPP
 */
contract Skills {

    // for keeping the scores we use the BokkyPooBahs Black Tree Library
    using BokkyPooBahsRedBlackTreeLibrary for BokkyPooBahsRedBlackTreeLibrary.Tree;
    BokkyPooBahsRedBlackTreeLibrary.Tree private _scoreTree;
    mapping(uint => uint) private _scoreValues;

    // used to assign an index to the Orders
    using Counters for Counters.Counter;
    Counters.Counter private _orderCounter;

    struct Order {
        address creator;
        uint256 totalReturn;
        uint256 originalStake;
        uint256 stakeMultiple;
        uint startDate;
        uint endDate;
        uint256 submissionsAllotted;
        uint256 submissionsSubmitted;
    }

    mapping(uint256 => Order) _orders;
    mapping(uint256 => BokkyPooBahsRedBlackTreeLibrary.Tree) _scoreTrees;
    mapping(uint256 => mapping(uint =>BokkyPooBahsRedBlackTreeLibrary.Tree)) _timestampTrees;
    mapping(uint256 => mapping(uint => mapping(uint => address))) _addressLookup; // orderId -> score -> timestamp -> address
    address payable private _wxpAddress;
    uint256 private _minimumStake;
    uint256 private _maximumStake;
    uint256 private _stakeMultiple;
    uint256 private _minimumNumberOfSubmissionsPerOrder;
    uint256 private _maximumNumberOfSubmissionsPerOrder;
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
        uint eventHorizon,
        uint minimumOrderDuration,
        uint maximumOrderDuration
    ) {
        _wxpAddress = wxpAddress;
        _minimumStake = minimumStake;
        _maximumStake = maximumStake;
        _minimumNumberOfSubmissionsPerOrder = minimumNumberOfSubmissionsPerOrder;
        _maximumNumberOfSubmissionsPerOrder = maximumNumberOfSubmissionsPerOrder;
        _stakeMultiple = stakeMultiple;
        _eventHorizon = eventHorizon;
        _minimumOrderDuration = minimumOrderDuration;
        _maximumOrderDuration = maximumOrderDuration;
    }

    /**
     * @dev Create a new order in the system. The function will return the Id of the order.
     */
    function stake(uint endDate, uint256 submissionsAllotted) payable external returns(uint256) {
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

        // convert the value into the WETH equivalent and deposit to this contract
        IWETH9Ext(_wxpAddress).depositTo{value: msg.value}(address(this));

        // add the order to the map
        uint256 currentIndex = _orderCounter.current();
        _orders[currentIndex] = Order(
            msg.sender,
            msg.value * _stakeMultiple / 100,
            msg.value,
            _stakeMultiple,
            block.timestamp,
            endDate,
            submissionsAllotted,
            0
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
    function submit(uint256 orderId, uint score) external {
        // check the order is valid and active
        require(orderId < _orderCounter.current(), "The order submitted for has not been created yet.");
        require(_orders[orderId].submissionsSubmitted == _orders[orderId].submissionsAllotted, "The order has already been completed.");

        // due to a limitation of the binary search tree library, we cannot have a score of 0.
        require(score > 0, "A score of 0 is not allowed.");

        // increment the submissions
        _orders[orderId].submissionsSubmitted++;

        // check to see if a score of the same value has already been added. If it has, then add just the timestamp
        // to the timestamp tree
        if (_scoreTrees[orderId].exists(score)) {

            // check to see if someone has already submitted this block timestamp. If so, keep adding 1 to the timestamp
            // until it finds the next highest timestamp.
            uint temporaryTimestamp = block.timestamp;
            while(_timestampTrees[orderId][score].exists(block.timestamp)) {
                temporaryTimestamp++;
            }

            // add the lowest possible timestamp for the score
            _timestampTrees[orderId][score].insert(temporaryTimestamp);

            // add an entry to the address lookup
            _addressLookup[orderId][score][temporaryTimestamp] = msg.sender;
        }

        // if this score has not yet been submitted add a score with corresponding timestamp and address
        else {
            _scoreTrees[orderId].insert(score);
            _timestampTrees[orderId][score].insert(block.timestamp);
            _addressLookup[orderId][score][block.timestamp] = msg.sender;
        }
    }

    // just a helper function for now to get the currency back while testing.
    function testWithdraw(uint256 amount) external {
        IWETH9Ext(_wxpAddress).withdrawTo(msg.sender, amount);
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
    function getMinimumNumberOfSubmissionsPerOrder() external view virtual returns(uint256) {
        return _minimumNumberOfSubmissionsPerOrder;
    }

    /**
     * @dev Returns the maximum amount of submissions that allowed for an order
     */
    function getMaximumNumberOfSubmissionsPerOrder() external view virtual returns(uint256) {
        return _maximumNumberOfSubmissionsPerOrder;
    }

    /**
     * @dev Returns the current minimum stake.
     */
    function getMinimumStake() external view virtual returns(uint256) {
        return _minimumStake;
    }

    /**
     * @dev Returns the current maximum stake.
     */
    function getMaximumStake() external view virtual returns(uint256) {
        return _maximumStake;
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
}

// SPDX-License-Identifier: Apache-2.0

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface IWETH9 {
    function deposit() external payable;

    function withdraw(uint256 _amount) external;
}