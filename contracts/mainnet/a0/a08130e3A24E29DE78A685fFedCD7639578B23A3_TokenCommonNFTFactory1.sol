// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./common_1.sol";

library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address addr) {
        require(
            address(this).balance >= amount,
            "Create2: insufficient balance"
        );
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash
    ) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
}

interface deployAddressOwnershipTransfer {
    function transferOwnership(address newOwner) external;
}

contract TokenCommonNFTFactory1 {
    bytes public creationCode;

    constructor() {
        creationCode = type(FatSaleNFT).creationCode;
    }

    event Deployed(address addr);
    mapping(address => uint256) public userMap; 

    function deploy(
        string[] memory stringParams,
        address[] memory addressParams,
        uint256[] memory numberParams,
        bool[] memory boolParams,
        uint256[] memory factoryFeeList,
        address[] memory factoryAddrList,
        uint256 _seed 
    ) external returns (address) {

        address addr = Create2.deploy(
            0,
            keccak256(
                abi.encodePacked(
                    userMap[tx.origin],
                    _seed,
                    "FatNFT",
                    address(tx.origin)
                )
            ),
            abi.encodePacked(
                creationCode,
                abi.encode(
                    stringParams,
                    addressParams,
                    numberParams,
                    boolParams,
                    factoryFeeList,
                    factoryAddrList
                )
            )
        );

        userMap[tx.origin] += 1;
        emit Deployed(addr);
        deployAddressOwnershipTransfer(addr).transferOwnership(tx.origin);
        return addr;
    }

    function getDeployAddress(
        string[] memory stringParams,
        address[] memory addressParams,
        uint256[] memory numberParams,
        bool[] memory boolParams,
        uint256[] memory factoryFeeList,
        address[] memory factoryAddrList,
        uint256 _seed, 
        address _owner
    ) external view returns (address) {
        bytes32 salt = keccak256(
            abi.encodePacked(userMap[_owner], _seed, "FatNFT", address(_owner))
        );
        return
            Create2.computeAddress(
                salt,
                keccak256(
                    abi.encodePacked(
                        creationCode,
                        abi.encode(
                            stringParams,
                            addressParams,
                            numberParams,
                            boolParams,
                            factoryFeeList,
                            factoryAddrList
                        )
                    )
                )
            );
    }
}