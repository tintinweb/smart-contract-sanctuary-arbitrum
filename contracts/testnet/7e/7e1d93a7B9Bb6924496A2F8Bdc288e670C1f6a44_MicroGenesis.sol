// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface InitializableInterface {
    /**
     * @notice Used internally to initialize the contract instead of through a constructor
     * @dev This function is called by the deployer/factory when creating a contract
     * @param initPayload abi encoded payload to use for contract initilaization
     */
    function init(bytes memory initPayload) external returns (bool);
}

/**
 * @dev In the beginning there was a smart contract...
 */
contract MicroGenesis {
    event Deployed(address indexed contractAddress);

    constructor() {}

    function deploy(bytes12 saltHash, bytes memory sourceCode)
        external
        payable
    {
        bytes32 salt = bytes32(
            keccak256(abi.encodePacked(msg.sender, saltHash))
        );

        address contractAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            salt,
                            keccak256(sourceCode)
                        )
                    )
                )
            )
        );

        require(!_isContract(contractAddress), "Micro: already deployed");

        assembly {
            contractAddress := create2(
                0,
                add(sourceCode, 0x20),
                mload(sourceCode),
                salt
            )
        }
        require(_isContract(contractAddress), "Micro: deployment failed");

        emit Deployed(contractAddress);
    }

    function deployWithPayload(
        bytes12 saltHash,
        bytes memory sourceCode,
        bytes memory initCode
    ) external payable {
        bytes32 salt = bytes32(
            keccak256(abi.encodePacked(msg.sender, saltHash))
        );

        address contractAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            salt,
                            keccak256(sourceCode)
                        )
                    )
                )
            )
        );

        require(!_isContract(contractAddress), "Micro: already deployed");

        assembly {
            contractAddress := create2(
                0,
                add(sourceCode, 0x20),
                mload(sourceCode),
                salt
            )
        }

        require(_isContract(contractAddress), "Micro: deployment failed");
        require(
            InitializableInterface(contractAddress).init(initCode),
            "Micro: initialization failed"
        );
        emit Deployed(contractAddress);
    }

    function getBytecodeNFT(
        bytes memory sourceCode,
        string memory _name,
        string memory _symbol
    ) public pure returns (bytes memory) {
        return abi.encodePacked(sourceCode, abi.encode(_name, _symbol));
    }

    function getBytecodeBridge(
        bytes memory sourceCode,
        address _lzEndpoint
    ) public pure returns (bytes memory) {
        return
            abi.encodePacked(
                sourceCode,
                abi.encode(_lzEndpoint)
            );
    }

    function _isContract(address contractAddress) internal view returns (bool) {
        bytes32 codehash;
        assembly {
            codehash := extcodehash(contractAddress)
        }
        return (codehash != 0x0 &&
            codehash !=
            0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
    }
}