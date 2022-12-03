// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
pragma solidity 0.8.17;

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "O: caller must be the owner");
        _;
    }

    constructor() {
        _setOwner(msg.sender);
    }

    function renounceOwnership() external onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(
            newOwner != address(0),
            "O: new owner must not be the zero address"
        );

        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
pragma solidity 0.8.17;

import "./base/Ownable.sol";
import "../Proxy.sol";

contract IdentityProxyFactory is Ownable {
    event ProxyCreated(address indexed proxy);

    function getProxyAddress(address identityImpl, bytes32 salt)
        external
        view
        returns (address)
    {
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                address(this),
                                salt,
                                keccak256(
                                    abi.encodePacked(
                                        type(Proxy).creationCode,
                                        uint256(uint160(identityImpl))
                                    )
                                )
                            )
                        )
                    )
                )
            );
    }

    function createProxy(
        address identityImpl,
        bytes32 salt,
        bytes calldata initData
    ) external onlyOwner returns (address) {
        address proxy = address(new Proxy{salt: salt}(identityImpl));

        if (initData.length > 0) {
            (bool success, ) = proxy.call(initData);
            if (!success) {
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }

        emit ProxyCreated(proxy);

        return proxy;
    }
}

// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
pragma solidity 0.8.17;

import "./utils/Address.sol";

contract Proxy {
    using Address for address;

    address public immutable implementation;

    constructor(address impl) {
        require(
            impl.isContract(),
            "P: implementation must be an existing contract address"
        );

        implementation = impl;
    }

    fallback() external payable {
        _delegateCall(implementation);
    }

    receive() external payable {
        _delegateCall(implementation);
    }

    function _delegateCall(address impl) internal {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

library Address {
    function isContract(address addr) internal view returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(addr)
        }

        return size > 0;
    }
}