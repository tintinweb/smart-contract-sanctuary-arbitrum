// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IInvestor {
  function file(bytes32, uint256) external;
}

contract InvestorEmergencyPauser {
    IInvestor public investor;
    mapping(address => bool) public exec;

    event File(bytes32 indexed what, address data);

    error Unauthorized();

    constructor(address _investor) {
        investor = IInvestor(_investor);
        exec[msg.sender] = true;
    }

    modifier auth() {
        if (!exec[msg.sender]) revert Unauthorized();
        _;
    }

    function file(bytes32 what, address data) external auth {
        if (what == "exec") exec[data] = !exec[data];
        emit File(what, data);
    }

    function pause() external auth {
        // Status 2 is liquidations only, commonly what's
        // needed to avoid bad debt but stop most attacks
        investor.file("status", 2);
    }
}