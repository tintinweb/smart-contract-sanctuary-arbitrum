/**
 *Submitted for verification at Arbiscan on 2023-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


/**
 * @title UxuyGas 
 * https://uxuy.io
 */
contract UxuyGas {

    /// @notice Addresses of super operators
    mapping(address => bool) public superOperators;

    /// @notice Addresses of claimed
    mapping(address => bool) public claimed;

    /// @notice gas amount 
    uint256 public gasAmount = 0.0001 ether;

    /// @notice Requires sender to be contract super operator
    modifier onlyAdmin() {
        // Ensure sender is super operator
        require(superOperators[msg.sender], "Not super operator");
        _;
    }

    /// Events
    /// @notice Emitted after claim gas to a recipient
    event ClaimGas(address indexed recipient, uint256 indexed amount);   

    /// @notice Emitted after super operator is updated
    event AuthorizedOperator(address indexed operator, address indexed holder);

    /// @notice Emitted after super operator is updated
    event RevokedOperator(address indexed operator, address indexed holder);

    /// 
    constructor() {
        superOperators[msg.sender] = true;
    }

    /// multi-claim
    function batchClaimGas(address[] memory recipient) public onlyAdmin {
        for (uint256 i = 0; i < recipient.length; i++) {
            claimGas(recipient[i],gasAmount);
        }
    }

    /// Allow withdraw of ETH tokens from the contract
    function claimGas(address recipient) public onlyAdmin {
        claimGas(recipient,gasAmount);
    }

    /// Allow withdraw of ETH tokens from the contract
    function claimGas(address recipient, uint256 amount) public onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance >= amount, "UXUY gas balance is not enough! ");
        require(claimed[recipient] != true, "Recipient have claimed! ");

        payable(recipient).transfer(amount);
        claimed[recipient] = true;
        emit ClaimGas(recipient, amount);
    }

    /// @dev return balance
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Allows receiving ETH
    receive() external payable {}

    /// @notice set gas amount
    function setGasAmount(uint256 _val) public onlyAdmin {
        gasAmount = _val;
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

}