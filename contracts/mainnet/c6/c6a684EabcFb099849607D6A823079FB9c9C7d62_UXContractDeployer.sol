// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/Context.sol";


abstract contract Manager is Context {

    mapping(address => bool) private _accounts;

    modifier onlyManager {
        require(isManager(), "only manager");
        _;
    }

    constructor() {
        _accounts[_msgSender()] = true;
    }

    function isManager(address one) public view returns (bool) {
        return _accounts[one];
    }

    function isManager() public view returns (bool) {
        return isManager(_msgSender());
    }

    function setManager(address one, bool val) public onlyManager {
        require(one != address(0), "address is zero");
        _accounts[one] = val;
    }

    function setManagerBatch(address[] calldata list, bool val) public onlyManager {
        for (uint256 i = 0; i < list.length; i++) {
            setManager(list[i], val);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.19;

/**
 * A contract-deploy factory which deploys contract as same address on different ETH-compatible chains (e.g. ETH, BSC, Polygon, etc.)
 * 
 * How to generate a specific prefix for contract address (replace bytecode and constructorArgs to yours):
 * 
 * <code>
 * const ethUtil = require('ethereumjs-util');
 * const prefix = "Fe666";
 * 
 * // ContractFactory address:
 * const deployContract = 'ea5837e1f89e3cf23027da7866e6492458383b59';
 * // contract bytecode:
 * const bytecode = '6080604052348015...';
 * // constructor args:
 * const constructorArgs = '0000000000000000...';
 * 
 * // bytecode hash:
 * let bytecodeHash = ethUtil.keccak256(new Buffer(bytecode + constructorArgs, 'hex')).toString('hex');
 * 
 * // find salt:
 * for (let i = 0; i< 0xfffffff; i++) {
 *     let salt = i.toString(16).padStart(64, '0');
 *     // payload data:
 *     let payload = 'ff' + deployContract + salt + bytecodeHash;
 *     // contract address:
 *     let addr = ethUtil.bufferToHex(ethUtil.keccak256(new Buffer(payload, 'hex'))).substr(26);
 *     // test prefix:
 *     if (addr.startsWith(prefix)) {
 *         console.log(salt);
 *         console.log(addr);
 *         break;
 *     }
 * }
 * console.log('END');
 * </code>
 */
import {Manager} from "./libs/Manager.sol";

interface IUXMANAGER {
    function authorizeOperator(address _operator) external;
    function setManager(address one, bool val) external;
}

contract UXContractDeployer is Manager{

    event ContractDeployed(address creatorAddress, address contractAddress);
    uint256 public fee;

    constructor() {
        setManager(msg.sender,true);
        fee = 0.00 ether;
    }

    /**
     * setManager for contract
     */
    function setContractManager(address _contractAddress, address _managerAddress) public onlyManager {
        require(_contractAddress != address(0), "Zero address");
        require(_managerAddress != address(0), "Zero address");
        IUXMANAGER(_contractAddress).setManager(_managerAddress, true);
    }

    /**
     * authorizeOperator for contract
     */
    function setContractOperator(address _contractAddress, address _managerAddress) public onlyManager {
        require(_contractAddress != address(0), "Zero address");
        require(_managerAddress != address(0), "Zero address");
        IUXMANAGER(_contractAddress).authorizeOperator(_managerAddress);
    }

    function setFee(uint256 _fee) public onlyManager {
        fee = _fee;
    }

    function withdrawFee(address payable _to) public onlyManager{
        require(_to != address(0), "Zero address");
        _to.transfer(address(this).balance);
    }
 
    /**
     * deploy contract by salt, contract bytecode.
     */
    function deployContract(bytes32 salt, bytes memory contractBytecode) public payable {
        require(msg.value == fee, "Invalid fee");
        address addr;
        assembly {
            addr := create2(0, add(contractBytecode, 0x20), mload(contractBytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        emit ContractDeployed(msg.sender, addr);
    }

    /**
     * deploy contract by salt, contract bytecode and constructor args.
     */
    function deployContractWithConstructor(bytes32 salt, bytes memory contractBytecode, bytes memory constructorArgsEncoded) public payable {
        require(msg.value == fee, "Invalid fee");
        // deploy contracts with constructor (address):
        bytes memory payload = abi.encodePacked(contractBytecode, constructorArgsEncoded);
        address addr;
        assembly {
            addr := create2(0, add(payload, 0x20), mload(payload), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        emit ContractDeployed(msg.sender, addr);
    }
}