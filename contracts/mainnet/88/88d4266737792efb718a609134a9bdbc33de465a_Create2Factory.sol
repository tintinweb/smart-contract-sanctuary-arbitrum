// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title Modified Create2 factory contract
 * @author 0age
 * @notice This contract provides a callCreate2 function that takes a salt value
 * and a block of initialization code as arguments and passes them into inline
 * assembly. There is also a view function that computes the address of the
 * contract that will be created when submitting a given salt or nonce along
 * with a given block of initialization code.
 */
contract Create2Factory {
    address public immutable owner;
    DeployedContract[] public deployedContracts;

    struct DeployedContract {
        bytes32 salt;
        address deployer;
        address contractAddress;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev if a deployed contract supports the function signature `kill` then
     * we will invoke the function so long as msg.sender is the deployer of this contract
     */
    function killContract(address deployedContract) public payable {
        require(msg.sender == owner, "not owner");
        bytes memory input = abi.encodeWithSelector(bytes4(keccak256(bytes("kill(address)"))), payable(msg.sender));
        (bool ok,) = deployedContract.call(input);
        require(ok, "failed to call contract");
    }

    /**
     * @dev used to transfer ownership of a deployed program
     */
    function transferOwnership(address _contract, address _owner) public payable {
        require(msg.sender == owner, "not owner");
        bytes memory input = abi.encodeWithSelector(bytes4(keccak256(bytes("transferOwnership(address)"))), _owner);
        (bool ok,) = _contract.call(input);
        require(ok, "failed to transfer ownership");
    }

    /**
     * @dev Create a contract using CREATE2 by submitting a given salt or nonce
     * along with the initialization code for the contract. Note that the first 20
     * bytes of the salt must match those of the calling address, which prevents
     * contract creation events from being submitted by unintended parties.
     * @param salt bytes32 The nonce that will be passed into the CREATE2 call.
     * @param initializationCode bytes The initialization code that will be passed
     * into the CREATE2 call.
     * @return deploymentAddress of the contract that will be created, or the null address
     * if a contract already exists at that address.
     */

    function callCreate2(bytes32 salt, bytes calldata initializationCode)
        external
        payable
        returns (address deploymentAddress)
    {
        // prevent contract submissions from being stolen from tx.pool by requiring
        // that the first 20 bytes of the submitted salt match msg.sender.
        require(
            address(bytes20(salt)) == msg.sender,
            "Invalid salt - first 20 bytes of the salt must match calling address."
        );
        // move the initialization code from calldata to memory. (use calldataload?)
        bytes memory initCode = initializationCode;

        // using inline assembly: load data and length of data, then call CREATE2.
        assembly {
            // solhint-disable-line
            let encoded_data := add(0x20, initCode) // load initialization code.
            let encoded_size := mload(initCode) // load the init code's length.
            deploymentAddress :=
                create2( // call CREATE2 with 4 arguments.
                    callvalue(), // forward any attached value.
                    encoded_data, // pass in initialization code.
                    encoded_size, // pass in init code's length.
                    salt // pass in the salt value.
                )
        }

        // ensure that the contract address is not equal to the null address.
        require(
            deploymentAddress != address(0), "Failed to deploy contract using provided salt and initialization code."
        );
        deployedContracts.push(DeployedContract({salt: salt, deployer: msg.sender, contractAddress: deploymentAddress}));

        (bool ok,) = deploymentAddress.call(abi.encodeWithSelector(bytes4(keccak256(bytes("initialize()")))));
        require(ok);
    }

    /**
     * @dev Compute the address of the contract that will be created when
     * submitting a given salt or nonce to the contract. The CREATE2 address is
     * computed in accordance with EIP-1014, and adheres to the formula therein of
     * `keccak256( 0xff ++ address ++ salt ++ keccak256(init_code)))[12:]` when
     * performing the computation. The computed address is then checked for any
     * existing contract code - if so, the null address will be returned instead.
     * @param salt bytes32 The nonce passed into the CREATE2 address calculation.
     * @param initCodeHash bytes32 The keccak256 hash of the initialization code
     * that will be passed into the CREATE2 address calculation.
     * @return deploymentAddress of the contract that will be created, or the null address
     * if a contract already exists at that address.
     */
    function findCreate2Address(bytes32 salt, bytes32 initCodeHash) external view returns (address deploymentAddress) {
        // variable for checking code size of any pre-existing contract at address.
        uint256 existingContractSize;

        // determine the address where the contract will be deployed.
        deploymentAddress = address(
            uint160( // downcast to match the address type.
                uint256( // convert to uint to truncate upper digits.
                    keccak256( // compute the CREATE2 hash using 4 inputs.
                        abi.encodePacked( // pack all inputs to the hash together.
                            hex"ff", // start with 0xff to distinguish from RLP.
                            address(this), // this contract will be the caller.
                            salt, // pass in the supplied salt value.
                            initCodeHash // pass in the hash of initialization code.
                        )
                    )
                )
            )
        );

        // determine if any contract code already exists at the computed address.
        assembly {
            // solhint-disable-line
            existingContractSize := extcodesize(deploymentAddress)
        }

        // if so, return null address to signify failure. (detect selfdestructed?)
        if (existingContractSize > 0) {
            return address(0);
        }
    }
    /**
     * @dev helper function to return a front-run proof salt
     */

    function sprinkle(address caller, bytes12 salt) public pure returns (bytes32) {
        return bytes32(bytes.concat(bytes20(caller), salt));
    }
}