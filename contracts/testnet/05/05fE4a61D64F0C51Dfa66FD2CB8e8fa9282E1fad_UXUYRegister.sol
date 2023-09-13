/**
 *Submitted for verification at Arbiscan.io on 2023-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IUXUYSBT {
    /**
     * To register a name
     * @param owner : The owner of a name
     * @param name : The name to be registered.
     * @param reverseRecord : Whether to set a record for resolving the name.
     * @return tokenId : The tokenId.
     */
    function register(address owner, string calldata name, bool reverseRecord) external returns (uint tokenId);
}

contract UXUYRegister {

    IUXUYSBT private SBTHandle;

    /// @notice Addresses of super operators
    mapping(address => bool) public superOperators;

    /// Events
    /// @notice Emitted after super operator is updated
    event AuthorizedOperator(address indexed operator, address indexed holder);

    /// @notice Emitted after super operator is updated
    event RevokedOperator(address indexed operator, address indexed holder);

    /// @notice Requires sender to be contract super operator
    modifier onlyAdmin() {
        // Ensure sender is super operator
        require(superOperators[msg.sender], "Not super operator");
        _;
    }
    
    /// @notice set 
    constructor(address _UXSBTToken) {
        superOperators[msg.sender] = true;
        SBTHandle = IUXUYSBT(_UXSBTToken);
    }
   
    function multiRegister(address[] memory to, string[] calldata name) public onlyAdmin {
        require(to.length == name.length, "address.len must equal name.len ");
        for (uint256 i = 0; i < to.length; i++) {
            SBTHandle.register(to[i], name[i],false);
        }
    }

    /// @notice Allows super operator to update super operator
    function authorizeOperator(address _operator) external onlyAdmin {
        superOperators[_operator] = true;
        emit AuthorizedOperator(_operator, msg.sender);
    }

    /// @notice Allows super operator to update super operator
    function revokeOperator(address _operator) external onlyAdmin {
        superOperators[_operator] = false;
        emit RevokedOperator(_operator, msg.sender);
    }

    /**
     * Allow withdraw of ETH tokens from the contract
     */
    function withdrawETH(address recipient) public onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "balance is zero");
        payable(recipient).transfer(balance);
    }

    /// @notice Allows receiving ETH
    receive() external payable {}
}