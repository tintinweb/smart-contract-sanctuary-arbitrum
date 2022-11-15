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

/**
 * @title Skills
 * @dev The contract for creating orders and getting rewards for the Expopulus DAPP
 */
contract Skills {

    // used to assign an index to the Orders
    using Counters for Counters.Counter;
    Counters.Counter private _orderCounter;

    struct Order {
        uint256 totalReturn;
        uint256 originalStake;
        uint256 stakeMultiple;
        uint endDate;
    }

    mapping(uint256 => Order) _orders;
    address payable private _wxpAddress;
    uint256 private _maximumStake;
    uint256 private _stakeMultiple;
    uint private _eventHorizon;
    uint private _minimumOrderDuration;
    uint private _maximumOrderDuration;

    constructor(
        address payable wxpAddress,
        uint256 maximumStake,
        uint256 stakeMultiple,
        uint eventHorizon,
        uint minimumOrderDuration,
        uint maximumOrderDuration
    ) {
        _wxpAddress = wxpAddress;
        _maximumStake = maximumStake;
        _stakeMultiple = stakeMultiple;
        _eventHorizon = eventHorizon;
        _minimumOrderDuration = minimumOrderDuration;
        _maximumOrderDuration = maximumOrderDuration;
    }

    /**
     * @dev Set the registry address, this is intended to be used by an owner or access control role in order to control
     * who can change this on the smart contract if it ever needs to change. The function will return the Id of the order.
     */
    function stake(uint endDate) payable external returns(uint256) {
        require(msg.value <= _maximumStake, "This amount is beyond the maximum stake.");
        require(msg.value > 0, "You must specify an amount > 0.");

        //check the end date is valid
        require(endDate > block.timestamp, "The end date is in the past.");
        require(endDate < _eventHorizon, "The order must end before the event horizon.");
        uint duration = endDate - block.timestamp;
        require(duration >= _minimumOrderDuration, "The order duration is too short.");
        require(duration <= _maximumOrderDuration, "The order duration is too long.");

        // convert the value into the WETH equivalent and deposit to this contract
        IWETH9Ext(_wxpAddress).depositTo{value: msg.value}(address(this));

        // add the order to the map
        uint256 currentIndex = _orderCounter.current();
        _orders[currentIndex] = Order(
            msg.value * _stakeMultiple / 100,
            msg.value,
            _stakeMultiple,
            endDate
        );
        _orderCounter.increment();

        return currentIndex;
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
     * @dev Returns the current stake multiple for calculating the return on a stake.
     */
    function getStakeMultiple() external view virtual returns(uint256) {
        return _stakeMultiple;
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