/**
 *Submitted for verification at Arbiscan on 2023-05-17
*/

// SPDX-License-Identifier: MIT
/****************************************************************************************
 Ramses LGEEscrow contract
 Author(s): @RAMSES Exchange on Arbitrum One
 Description: LGE Escrow to ensure mutual agreement before distribution of raised capital
*****************************************************************************************/

pragma solidity ^0.8.16;

interface IERC20 {
    function transfer(address _to, uint _amount) external;

    function balanceOf(address _wallet) external view returns (uint);
}

contract LGEEscrow {
    address public lge_Counterparty;
    string public constant LGE_PARTNER = "Unlimited Network";
    address[] public escrowedTokens;
    mapping(address => bool) authorizedOperator;
    bool emergency = false;
    bool ramsesSignature = false;
    bool counterpartySignature = false;

    event counterPartyDeclared(address _counterparty);
    event TokensEscrowedChanged(address[] _tokens);
    event CounterSigned(bool _signed);
    event OperatorRemoved(address _removed);
    event OperatorAdded(address _added);
    event TokensReleasedFromEscrow(bool _status);
    event RamsesSignOff(bool _signed);
    event Emergency(bool _state);

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

    ///@dev set the counterParty address, for this case-- The Unlimited team
    function setCounterparty(
        address _counterParty
    ) external onlyRamsesOperator {
        require(
            lge_Counterparty != msg.sender,
            "Ramses_Error: You cannot be the counterparty"
        );
        lge_Counterparty = _counterParty;
        emit counterPartyDeclared(lge_Counterparty);
    }

    ///@dev sets an array of the tokens to be escrowed
    function setTokensInEscrow(
        address[] memory _tokens
    ) external onlyRamsesOperator {
        escrowedTokens = _tokens;
        emit TokensEscrowedChanged(escrowedTokens);
    }

    ///@dev adds a new operator for Ramses
    function addNewOperator(address _operator) external onlyRamsesOperator {
        authorizedOperator[_operator] = true;
        emit OperatorAdded(_operator);
    }

    ///@dev removes a Ramses Operator
    function removeOperator(
        address _removedOperator
    ) external onlyRamsesOperator {
        authorizedOperator[_removedOperator] = false;
        emit OperatorRemoved(_removedOperator);
    }

    //@counterparty signature command
    function sign() external onlyCounterparty {
        counterpartySignature = true;
        emit CounterSigned(true);
    }

    ///@dev RAMSES countersign
    function ramsesSign() external onlyRamsesOperator {
        ramsesSignature = true;
        emit RamsesSignOff(true);
    }

    ///@dev only callable by lge_counterparty or Ramses operators after both sides have signed and confirmed
    function releaseRaisedAmount() external returns (bool) {
        require(
            msg.sender == lge_Counterparty ||
                authorizedOperator[msg.sender] == true
        );
        require(
            ramsesSignature == true && counterpartySignature == true,
            "Signature Error: Both sides have not signed yet!"
        );
        for (uint i = 0; i < escrowedTokens.length; ++i) {
            IERC20(escrowedTokens[i]).transfer(
                lge_Counterparty,
                IERC20(escrowedTokens[i]).balanceOf(address(this))
            );
        }

        emit TokensReleasedFromEscrow(true);

        return true;
    }

    function emergencyModeActivate() external onlyRamsesOperator {
        require(
            emergency == false,
            "Emergency!: There is currently an emergency."
        );
        emergency = true;
        emit Emergency(true);
    }

    function emergencyModeDisable() external onlyRamsesOperator {
        require(
            emergency == true,
            "Emergency_Error: There is no current emergency."
        );
        emergency = false;
        emit Emergency(false);
    }

    function forceWithdrawTokens(
        address[] calldata _tokens,
        uint[] calldata _amounts,
        address _receiver
    ) external onlyRamsesOperator {
        require(
            emergency == true,
            "Emergency_Error: There is no current emergency."
        );

        for (uint i = 0; i < _tokens.length; ++i) {
            IERC20(_tokens[i]).transfer(_receiver, _amounts[i]);
        }
    }

    function getBalanceOfEscrowedTokenAtIndex(
        uint _index
    ) external view returns (uint) {
        return IERC20(escrowedTokens[_index]).balanceOf(address(this));
    }
}