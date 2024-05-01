// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Lib } from "./libraries/Lib.sol";
import {IGenerator} from "./interfaces/IGenerator.sol";
import {IStake} from "./interfaces/IStake.sol";

interface ITemplate {
    function initialize(bytes calldata data) external ;
    function initializePayable(bytes calldata data) external payable;
}

contract StakingPoolFactory {
    address public generator;
    constructor(address _generator) {
        generator = _generator;
    }

    address[] public pools;
    mapping(address => bool) public isPool;
    event PoolCreated(address indexed factory, address pool, address indexed stake, address indexed reward, bool mintsRewards);

    function owner() public view returns (address) {
        return IGenerator(generator).factoryInfo(generator).owner;
    }
    modifier onlyOwner() {
        require(msg.sender == owner(), "F:NA");
        _;
    }

    struct Template {
        address template;
        uint fee;
        bool shouldPay;
    }
    bytes4 constant templateSelector = bytes4(keccak256("initialize(bytes)"));
    bytes4 constant payableTemplateSelector = bytes4(keccak256("initializePayable(bytes)"));
    mapping(uint => Template) public templates;
    uint public totalTemplates;
    event TemplateAdded(uint i, address template, uint fee);
    event FeeUpdated(address indexed template, uint fee);
    function addTemplate(address _templateAddress, uint _fee, bool shouldPay) external onlyOwner {
        templates[totalTemplates] = Template(_templateAddress, _fee, shouldPay);
        emit TemplateAdded(totalTemplates, _templateAddress, _fee);
        totalTemplates++;
    }
    function setFee(uint _template, uint _fee) external onlyOwner {
        templates[_template].fee = _fee;
        emit FeeUpdated(templates[_template].template, _fee);
    }

    function createPool(uint _template, bytes calldata _data) external payable returns (address created) {
        address template = templates[_template].template;
        require(template != address(0));
        uint fee = templates[_template].fee;
        uint v = msg.value;
        if (v > fee) {
            uint a = v - fee;
            payable(msg.sender).transfer(a);
            v -= a;
        }
        require(v >= fee, "F:IF");
        if (v > 0) {
            payable(owner()).transfer(fee);
            v -= fee;
        }
        bytes32 salt = keccak256(abi.encodePacked(pools.length));
        created = Lib.cloneDeterministic(template, salt);
        if (!templates[_template].shouldPay) {
             (bool success,) = address(created).call(abi.encodeWithSelector(templateSelector, _data));
             require(success, "Failed to initialize");
        } else{
             (bool success,) = address(created).call{value: v}(abi.encodeWithSelector(payableTemplateSelector, _data));
             require(success, "Failed to initialize");
        }
        pools.push(created);
        isPool[created] = true;
        IStake s = IStake(created);
        address f = s.factory();
        address stake = s.stakingToken();
        address reward = s.rewardToken();
        bool rewardBased = s.rewardBased();
        emit PoolCreated(f, created, stake, reward, rewardBased);
    }

    function totalPools() external view returns (uint256) {
        return pools.length;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IStake {
    function stakingToken() external view returns (address);
    function rewardToken() external view returns (address);
    function factory() external view returns (address);
    function rewardBased() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


interface IGenerator {
    struct Info {
        address owner;
        uint16 burnFee;
        address burnToken;
        uint16 teamFee;
        address teamAddress;
        uint16 lpFee;
        address referrer;
        uint16 referFee;
        uint16 labFee;
    }
    function allowLoans() external view returns (bool);
    function isPair(address) external view returns (bool);
    function borrowFee() external view returns (uint16);
    function factoryInfo(address) external view returns (Info memory);
    function pairFees(address pair) external view returns (Info memory);
    function LAB_FEE() external view returns (uint16);
    function FEE_DENOMINATOR() external view returns (uint16);
    function stables(address) external view returns (bool);
    function pairs(address factory, address token0, address token1) external view returns (address);
    function getPairs(address[] calldata path) external  view returns (address[] memory _pairs);
    function maxSwap2Fee(uint16 f) external view returns (uint16);
    function swapInternal(
        address[] calldata _pairs,
        address caller,
        address to
    ) external returns (uint256 amountOut);
    function WRAPPED_ETH() external view returns (address);
    function createPair(
        address tokenA, 
        address tokenB
    ) external returns (address pair);
     function createSwap2Pair(
        address tokenA, 
        address tokenB,
        address feeTaker,
        address takeFeeIn
    ) external returns (address pair);
    function createPairWithLiquidity(
        address tokenA, 
        address tokenB,
        uint amountA,
        uint amountB,
        address to,
        address feeTaker,
        address takeFeeIn
    ) external returns (address pair);
    function isFactory(address) external returns (bool);
    function tokens(address) external returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// a library for performing various math operations

library Lib {
    function sortsBefore(address tokenA, address tokenB) internal pure returns (address, address) {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }
}