// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./CreditRequest.sol";
import "./ICreditRequest.sol";

contract CreditFactory {
    mapping(bytes32 => ICreditRequest) creditRequests;

    function create(bytes32 hash, uint8 status) external {
        ICreditRequest cr = new CreditRequest(hash, ICreditRequest.Status(status));
        creditRequests[hash] = cr;
    }

    function viewData(bytes32 hash) external view  returns(ICreditRequest.CreditData memory) {
        ICreditRequest cr = creditRequests[hash];
        return cr.viewData();
    }

    function changeStatus(bytes32 hash, uint8 newStatus) external returns(ICreditRequest.CreditData memory) {
        ICreditRequest cr = creditRequests[hash];
        cr.changeStatus(ICreditRequest.Status(newStatus));
        return cr.viewData();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ICreditRequest.sol";

contract CreditRequest is ICreditRequest {
    CreditData cd;
    constructor(bytes32 _hash, Status _status) {
        cd = CreditData(_hash, _status);
    }

    function viewData() external view returns(CreditData memory) {
        return cd;
    }

    function changeStatus(Status newStatus) external returns(CreditData memory) {
        cd.status = newStatus;
        return cd;
    }
}

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