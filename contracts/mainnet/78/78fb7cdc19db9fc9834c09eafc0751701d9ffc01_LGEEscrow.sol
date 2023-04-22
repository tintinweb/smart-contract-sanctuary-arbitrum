/**
 *Submitted for verification at Arbiscan on 2023-04-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC20 {
    function transfer(address _to, uint _amount) external;

    function balanceOf(address _wallet) external view returns (uint);
}

contract LGEEscrow {
    address public lge_Counterparty;
    address[] public escrowedTokens;
    mapping(address => bool) authorizedOperator;
    bool ramsesSignature = false;
    bool counterpartySignature = false;

    modifier onlyRamsesOperator() {
        require(
            authorizedOperator[msg.sender] == true,
            "Ramses_Error: You are not authorized to perform this task"
        );
        _;
    }

    modifier onlyCounterparty() {
        require(
            msg.sender == lge_Counterparty,
            "Ramses_Error: You are not authorized to perform this task"
        );
        _;
    }

    constructor(address _ramsesOperator) {
        authorizedOperator[_ramsesOperator] = true;
        authorizedOperator[msg.sender] = true;
    }

    ///@dev set the counterParty address, for this case-- CRUIZE team
    function setCounterparty(
        address _counterParty
    ) external onlyRamsesOperator {
        lge_Counterparty = _counterParty;
    }

    ///@dev sets an array of the tokens to be escrowed
    function setTokensInEscrow(
        address[] calldata _tokens
    ) external onlyRamsesOperator {
        escrowedTokens = _tokens;
    }

    ///@dev adds a new operator for Ramses
    function addNewOperator(address _operator) external onlyRamsesOperator {
        authorizedOperator[_operator] = true;
    }

    ///@dev removes a Ramses Operator
    function removeOperator(
        address _removedOperator
    ) external onlyRamsesOperator {
        authorizedOperator[_removedOperator] = false;
    }

    //@signature commands
    function sign() external onlyCounterparty {
        counterpartySignature = true;
    }

    ///@dev RAMSES countersign
    function ramsesSign() external onlyRamsesOperator {
        ramsesSignature = true;
    }

    ///@dev only callable by lge_counterparty or Ramses operators after both sides have signed and confirmed
    function releaseRaisedAmount() external returns (bool) {
        require(
            msg.sender == lge_Counterparty ||
                authorizedOperator[msg.sender] == true
        );
        for (uint i = 0; i < escrowedTokens.length; ++i) {
            IERC20(escrowedTokens[i]).transfer(
                lge_Counterparty,
                IERC20(escrowedTokens[i]).balanceOf(address(this))
            );
        }

        return true;
    }

    function getBalanceOfEscrowedTokenAtIndex(
        uint _index
    ) external view returns (uint) {
        return IERC20(escrowedTokens[_index]).balanceOf(address(this));
    }
}