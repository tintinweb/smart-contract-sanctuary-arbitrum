/**
 *Submitted for verification at Arbiscan on 2023-05-29
*/

/* Tribeone: ProxyPerpsV2.sol
* Latest source (may be newer): https://github.com/TribeOneDefi/tribeone-v3-contracts/blob/master/contracts/ProxyPerpsV2.sol
* Docs: https://docs.tribeone.io/contracts/ProxyPerpsV2
*
* Contract Dependencies: 
*	- Owned
* Libraries: (none)
*
* MIT License
* ===========
*
* Copyright (c) 2023 Tribeone
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/



pragma solidity ^0.5.16;

// https://docs.tribeone.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}


// Inheritance


// Internal references


// https://docs.tribeone.io/contracts/source/contracts/proxy
contract Proxy is Owned {
    Proxyable public target;

    constructor(address _owner) public Owned(_owner) {}

    function setTarget(Proxyable _target) external onlyOwner {
        target = _target;
        emit TargetUpdated(_target);
    }

    function _emit(
        bytes calldata callData,
        uint numTopics,
        bytes32 topic1,
        bytes32 topic2,
        bytes32 topic3,
        bytes32 topic4
    ) external onlyTarget {
        uint size = callData.length;
        bytes memory _callData = callData;

        assembly {
            /* The first 32 bytes of callData contain its length (as specified by the abi).
             * Length is assumed to be a uint256 and therefore maximum of 32 bytes
             * in length. It is also leftpadded to be a multiple of 32 bytes.
             * This means moving call_data across 32 bytes guarantees we correctly access
             * the data itself. */
            switch numTopics
                case 0 {
                    log0(add(_callData, 32), size)
                }
                case 1 {
                    log1(add(_callData, 32), size, topic1)
                }
                case 2 {
                    log2(add(_callData, 32), size, topic1, topic2)
                }
                case 3 {
                    log3(add(_callData, 32), size, topic1, topic2, topic3)
                }
                case 4 {
                    log4(add(_callData, 32), size, topic1, topic2, topic3, topic4)
                }
        }
    }

    // solhint-disable no-complex-fallback
    function() external payable {
        // Mutable call setting Proxyable.messageSender as this is using call not delegatecall
        target.setMessageSender(msg.sender);

        assembly {
            let free_ptr := mload(0x40)
            calldatacopy(free_ptr, 0, calldatasize)

            /* We must explicitly forward ether to the underlying contract as well. */
            let result := call(gas, sload(target_slot), callvalue, free_ptr, calldatasize, 0, 0)
            returndatacopy(free_ptr, 0, returndatasize)

            if iszero(result) {
                revert(free_ptr, returndatasize)
            }
            return(free_ptr, returndatasize)
        }
    }

    modifier onlyTarget {
        require(Proxyable(msg.sender) == target, "Must be proxy target");
        _;
    }

    event TargetUpdated(Proxyable newTarget);
}


// Inheritance


// Internal references


// https://docs.tribeone.io/contracts/source/contracts/proxyable
contract Proxyable is Owned {
    // This contract should be treated like an abstract contract

    /* The proxy this contract exists behind. */
    Proxy public proxy;

    /* The caller of the proxy, passed through to this contract.
     * Note that every function using this member must apply the onlyProxy or
     * optionalProxy modifiers, otherwise their invocations can use stale values. */
    address public messageSender;

    constructor(address payable _proxy) internal {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");

        proxy = Proxy(_proxy);
        emit ProxyUpdated(_proxy);
    }

    function setProxy(address payable _proxy) external onlyOwner {
        proxy = Proxy(_proxy);
        emit ProxyUpdated(_proxy);
    }

    function setMessageSender(address sender) external onlyProxy {
        messageSender = sender;
    }

    modifier onlyProxy {
        _onlyProxy();
        _;
    }

    function _onlyProxy() private view {
        require(Proxy(msg.sender) == proxy, "Only the proxy can call");
    }

    modifier optionalProxy {
        _optionalProxy();
        _;
    }

    function _optionalProxy() private {
        if (Proxy(msg.sender) != proxy && messageSender != msg.sender) {
            messageSender = msg.sender;
        }
    }

    modifier optionalProxy_onlyOwner {
        _optionalProxy_onlyOwner();
        _;
    }

    // solhint-disable-next-line func-name-mixedcase
    function _optionalProxy_onlyOwner() private {
        if (Proxy(msg.sender) != proxy && messageSender != msg.sender) {
            messageSender = msg.sender;
        }
        require(messageSender == owner, "Owner only function");
    }

    event ProxyUpdated(address proxyAddress);
}


pragma experimental ABIEncoderV2;

// Inheritance


// Internal references


/**
 * Based on Proxy.sol that adds routing capabilities to route specific function calls (selectors) to
 * specific implementations and flagging the routes if are views in order to not call
 * proxyable.setMessageSender() that is mutative (resulting in a revert).
 *
 * In order to manage the routes it provides two onlyOwner functions (`addRoute` and `removeRoute`), and
 * some helper views to get the size of the route list (`getRoutesLength`), the list of routes (`getRoutesPage`),
 * and a list of all the targeted contracts.
 */
// https://docs.tribeone.io/contracts/source/contracts/ProxyPerpsV2
contract ProxyPerpsV2 is Owned {
    /* ----- Dynamic router storage ----- */
    struct Route {
        bytes4 selector;
        address implementation;
        bool isView;
    }

    // Route definition and index to quickly access it
    Route[] internal _routes;
    mapping(bytes4 => uint) internal _routeIndexes;
    // number of routes referencing a target, if number is greater than zero, it means the address is a valid target
    mapping(address => uint) internal _targetReferences;
    // list of valid target addresses (more than zero references in the routes)
    address[] internal _routedTargets;

    constructor(address _owner) public Owned(_owner) {}

    /* ----- Dynamic router administration ----- */
    function _contains(bytes4 selector) internal view returns (bool) {
        if (_routes.length == 0) {
            return false;
        }
        uint index = _routeIndexes[selector];
        return index != 0 || _routes[0].selector == selector;
    }

    function _removeTargetReference(address implementation) internal {
        require(_targetReferences[implementation] > 0, "Target not referenced.");

        // Decrement the references
        _targetReferences[implementation] -= 1;

        // if was the latest reference, remove it from the _routedTargets and emit an event
        if (_targetReferences[implementation] == 0) {
            // Accepting a for loop since implementations for a market is going to be a very limited number (initially only 2)
            for (uint idx = 0; idx < _routedTargets.length; idx++) {
                if (_routedTargets[idx] == implementation) {
                    // remove it by bringing the last one to that position and poping the latest item (if it's the latest one will do an unecessary write)
                    _routedTargets[idx] = _routedTargets[_routedTargets.length - 1];
                    _routedTargets.pop();
                    break;
                }
            }

            emit TargetedRouteRemoved(implementation);
        }
    }

    function addRoute(
        bytes4 selector,
        address implementation,
        bool isView
    ) external onlyOwner {
        require(selector != bytes4(0), "Invalid nil selector");

        if (_contains(selector)) {
            // Update data
            Route storage route = _routes[_routeIndexes[selector]];

            // Remove old implementation reference
            _removeTargetReference(route.implementation);

            route.selector = selector;
            route.implementation = implementation;
            route.isView = isView;
        } else {
            // Add data
            _routeIndexes[selector] = _routes.length;
            Route memory newRoute;
            newRoute.selector = selector;
            newRoute.implementation = implementation;
            newRoute.isView = isView;

            _routes.push(newRoute);
        }

        // Add to targeted references
        _targetReferences[implementation] += 1;
        if (_targetReferences[implementation] == 1) {
            // First reference, add to routed targets and emit the event
            _routedTargets.push(implementation);
            emit TargetedRouteAdded(implementation);
        }

        emit RouteUpdated(selector, implementation, isView);
    }

    function removeRoute(bytes4 selector) external onlyOwner {
        require(_contains(selector), "Selector not in set.");

        // Replace the removed selector with the last selector of the list.
        uint index = _routeIndexes[selector];
        uint lastIndex = _routes.length - 1; // We required that selector is in the list, so it is not empty.

        // Remove target reference
        _removeTargetReference(_routes[index].implementation);

        // Ensure target is in latest index
        if (index != lastIndex) {
            // No need to shift the last selector if it is the one we want to delete.
            Route storage shiftedElement = _routes[lastIndex];
            _routes[index] = shiftedElement;
            _routeIndexes[shiftedElement.selector] = index;
        }

        // Remove target
        _routes.pop();
        delete _routeIndexes[selector];
        emit RouteRemoved(selector);
    }

    function getRoute(bytes4 selector) external view returns (Route memory) {
        if (!_contains(selector)) {
            return Route(0, address(0), false);
        }
        return _routes[_routeIndexes[selector]];
    }

    function getRoutesLength() external view returns (uint) {
        return _routes.length;
    }

    function getRoutesPage(uint index, uint pageSize) external view returns (Route[] memory) {
        // NOTE: This implementation should be converted to slice operators if the compiler is updated to v0.6.0+
        uint endIndex = index + pageSize; // The check below that endIndex <= index handles overflow.

        // If the page extends past the end of the list, truncate it.
        if (endIndex > _routes.length) {
            endIndex = _routes.length;
        }
        if (endIndex <= index) {
            return new Route[](0);
        }

        uint n = endIndex - index; // We already checked for negative overflow.
        Route[] memory page = new Route[](n);
        for (uint i; i < n; i++) {
            page[i] = _routes[i + index];
        }
        return page;
    }

    function getAllTargets() external view returns (address[] memory) {
        return _routedTargets;
    }

    ///// BASED ON PROXY.SOL /////
    /* ----- Proxy based on Proxy.sol ----- */

    function _emit(
        bytes calldata callData,
        uint numTopics,
        bytes32 topic1,
        bytes32 topic2,
        bytes32 topic3,
        bytes32 topic4
    ) external onlyTargets {
        uint size = callData.length;
        bytes memory _callData = callData;

        assembly {
            /* The first 32 bytes of callData contain its length (as specified by the abi).
             * Length is assumed to be a uint256 and therefore maximum of 32 bytes
             * in length. It is also leftpadded to be a multiple of 32 bytes.
             * This means moving call_data across 32 bytes guarantees we correctly access
             * the data itself. */
            switch numTopics
                case 0 {
                    log0(add(_callData, 32), size)
                }
                case 1 {
                    log1(add(_callData, 32), size, topic1)
                }
                case 2 {
                    log2(add(_callData, 32), size, topic1, topic2)
                }
                case 3 {
                    log3(add(_callData, 32), size, topic1, topic2, topic3)
                }
                case 4 {
                    log4(add(_callData, 32), size, topic1, topic2, topic3, topic4)
                }
        }
    }

    // solhint-disable no-complex-fallback
    function() external payable {
        bytes4 sig4 = msg.sig;

        require(_contains(sig4), "Invalid selector");

        // Identify target
        address implementation = _routes[_routeIndexes[sig4]].implementation;
        bool isView = _routes[_routeIndexes[sig4]].isView;

        if (isView) {
            assembly {
                let free_ptr := mload(0x40)
                calldatacopy(free_ptr, 0, calldatasize)

                /* We must explicitly forward ether to the underlying contract as well. */
                let result := staticcall(gas, implementation, free_ptr, calldatasize, 0, 0)
                returndatacopy(free_ptr, 0, returndatasize)

                if iszero(result) {
                    revert(free_ptr, returndatasize)
                }
                return(free_ptr, returndatasize)
            }
        } else {
            // Mutable call setting Proxyable.messageSender as this is using call not delegatecall
            Proxyable(implementation).setMessageSender(msg.sender);
            assembly {
                let free_ptr := mload(0x40)
                calldatacopy(free_ptr, 0, calldatasize)

                /* We must explicitly forward ether to the underlying contract as well. */
                let result := call(gas, implementation, callvalue, free_ptr, calldatasize, 0, 0)
                returndatacopy(free_ptr, 0, returndatasize)

                if iszero(result) {
                    revert(free_ptr, returndatasize)
                }
                return(free_ptr, returndatasize)
            }
        }
    }

    modifier onlyTargets {
        require(_targetReferences[msg.sender] > 0, "Must be a proxy target");
        _;
    }

    event RouteUpdated(bytes4 route, address implementation, bool isView);

    event RouteRemoved(bytes4 route);

    event TargetedRouteAdded(address targetedRoute);

    event TargetedRouteRemoved(address targetedRoute);
}