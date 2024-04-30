// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import {IBusinessFacet} from "../interfaces/internal/IBusinessFacet.sol";

contract BusinessFacet is IBusinessFacet {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.BusinessFacet.diamond.storage");
    struct Business {
        mapping(address => uint) GasTag;
        mapping(bytes32 => address) serviceAddress;
    }

    function diamondStorage() internal pure returns (Business storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function getServiceAddress(
        string memory serviceName
    ) external view returns (address) {
        Business storage ds = diamondStorage();
        return ds.serviceAddress[keccak256(abi.encode(serviceName))];
    }

    function setServiceAddress(
        string memory _serviceName,
        address _addr
    ) external {
        Business storage ds = diamondStorage();
        ds.serviceAddress[keccak256(abi.encode(_serviceName))] = _addr;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IBusinessFacet {
    function getServiceAddress(
        string memory serviceName
    ) external view returns (address);

    function setServiceAddress(
        string memory _serviceName,
        address _addr
    ) external;
}