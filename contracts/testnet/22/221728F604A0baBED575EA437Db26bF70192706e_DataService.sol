// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./interfaces/IApp.sol";

/**
 * A service contract provide oracle data
 */
contract DataService is AutomationCompatibleInterface {
    using ERC165Checker for address;

    struct Register {
        uint256 waitIndex; //the index in tasklist (waiting array)
        bool executed;
    }

    address[] waiting; //array of hash(Register object)
    mapping(address => Register) registers; //hash -> Register object

    address public appAddress;

    modifier _onlyApp() {
        require(appAddress == msg.sender, "Only app address is allowed");
        _;
    }

    constructor(address appAddress_) {
        appAddress = appAddress_;
    }

    /**
     * Register for a result specify by resultAddr at resultAt timestamp,
     * when the block.timestamp > resultAt, this contract will get the result from oracle
     * then call proxy.setResult(uint256 resultAt, bytes32 resultAddr, uint256 result)
     * this just do one, no repeat
     */
    function register(address payable proxy) public _onlyApp {
        require(
            address(proxy).supportsInterface(type(IApp).interfaceId),
            "Contract not support IApp interface"
        );
        require(
            registers[proxy].waitIndex == 0,
            "Only allow unregistered contract"
        );

        Register memory r;
        r.waitIndex = waiting.length;
        r.executed = false;

        registers[proxy] = r;
        waiting.push(proxy);

        require(waiting[registers[proxy].waitIndex] == proxy, "Data not in sync"); //make sure the data is in sync
    }

    function _isValidPeriod(address payable proxy) private view returns (bool) {
        AppLib.Subscribe memory subscribe = IApp(proxy).getSubscribe();
        return
            (subscribe.resultAt + 30 minutes) > block.timestamp &&
            block.timestamp > subscribe.resultAt;
    }

    /**
     * The checkData is defined when the Upkeep was registered.
     */
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        uint256 _length = waiting.length;
        address[] memory addrs = new address[](_length);
        uint256 n = 0;
        for (uint256 i = 0; i < _length; i++) {
            if (_isValidPeriod(payable(waiting[i]))) {
                addrs[n] = waiting[i];
                n++;
            }
        }
        address[] memory rAddrs = new address[](n);
        for (uint256 i = 0; i < n; i++) {
            rAddrs[i] = addrs[i];
        }
        upkeepNeeded = n > 0;
        performData = abi.encode(rAddrs);
    }

    function _checkPerformUpkeep(address payable proxy) private {
        Register memory r = registers[proxy];
        AppLib.Subscribe memory subscribe = IApp(proxy).getSubscribe();

        if (!r.executed && _isValidPeriod(proxy)) {
            (bool success, bytes memory result) = subscribe.resultAddr.call{
                value: 0
            }(subscribe.resultCalldata);
            require(success);

            IApp(proxy).setResult(result);

            address lastAddr = waiting[waiting.length - 1];
            registers[lastAddr].waitIndex = r.waitIndex;
            waiting[r.waitIndex] = lastAddr;
            waiting.pop();

            registers[proxy].executed = true;
        }
    }

    /**
     * The performData is generated by the Automation Node's call to checkUpkeep function
     */
    function performUpkeep(bytes calldata performData) external override {
        address[] memory addrs = abi.decode(performData, (address[]));
        for (uint256 i = 0; i < addrs.length; i++) {
            _checkPerformUpkeep(payable(addrs[i]));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Library of function use in solidity source code
 */
library AppLib {
  /**
   * @dev Structure that describes the subscriber object to get results from oracle
   */
  struct Subscribe {
    uint256 resultAt; //schedule timestamp when results will be received
    address resultAddr; //address of contract provide result
    bytes resultCalldata; //abi.encodeWithSelector(bytes4(keccak256("someFunc(address,uint256)"), arg1, arg2);
  }

  /**
   * @dev Get a uint256 from bytes data start at offset
   * @param data bytes of data
   * @param offset start position to get from data, the length is 32 bytes
   */
  function sliceUint256(bytes memory data, uint256 offset) private pure returns (uint256) {
    require(data.length >= offset + 32, "Out of range");
    uint256 result;
    assembly {
      result := mload(add(data, add(0x20, offset)))
    }
    return result;
  }

}

/**
 * @dev Application contract interface of WaveBreak platform
 */
interface IApp is IERC165 {
    /**
     * @dev Initialize the IApp proxy contract 
     * @param initializeData = abi.encode(arg1, arg2, ...);
     */
    function initialize(address dataService, bytes memory initializeData) external;

    /**
     * @dev Get the AppLib.Subscribe of the IApp to known what kind of result it's subscribe for
     */
    function getSubscribe() external view returns (AppLib.Subscribe memory);

    /**
     * @dev This function will be called automatically to set the result for IApp contract
     * please implement its functionality for the purpose of IApp
     * @param result the results to be solved
     */
    function setResult(bytes memory result) external;
}