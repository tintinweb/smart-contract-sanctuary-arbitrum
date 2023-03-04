// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICreditRequest {
    enum Status {OPENED, CLOSED, CANCELED}
    struct CreditData {
        bytes32 hash;
        Status status;
    }

    function viewData() external view returns(CreditData memory);

    function changeStatus(Status newStatus) external returns(CreditData memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ICreditRequest.sol";

contract Storage {
    ICreditRequest.CreditData[] cd;
    mapping (bytes32=>uint256) hashToIndexCreditData;

    function create(bytes32 hash, uint8 status) external returns(ICreditRequest.CreditData memory) {
        cd.push(ICreditRequest.CreditData(hash, ICreditRequest.Status(status)));
        hashToIndexCreditData[hash] = cd.length - 1;
        return cd[hashToIndexCreditData[hash]];
    } 

    function getCreditData(bytes32 hash) external view returns(ICreditRequest.CreditData memory) {
        return cd[hashToIndexCreditData[hash]];
    }

    function changeStatus(bytes32 hash, uint8 newStatus) external returns(ICreditRequest.CreditData memory) {
        uint256 cdIndex = hashToIndexCreditData[hash];
        cd[cdIndex].status = ICreditRequest.Status(newStatus);
        return cd[cdIndex];
    }
}