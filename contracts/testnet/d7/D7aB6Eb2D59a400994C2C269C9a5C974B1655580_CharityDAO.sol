// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./ERC20.sol";

contract CharityDAO is ERC20 {
                    
    address zeroAddr = 0x0000000000000000000000000000000000000000;
    uint public required;
    struct Proposal {
        address from;
        address to;
        uint value;
        bytes data;
        bool executed;
        uint timelimit;
        string reason;
    }

    Proposal[] public proposals;
    address[] public members;
    event DepositFunds(address from, uint amount);
    event SubmitProposal(uint transactionId);
    event ApproveProposal(address owner, uint transactionId);
    event ExecuteProposal(uint transactionId);

    //       ["0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"]
    //       0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB

    struct StackHolder {
        address stackHolder;
        uint weight; 
        address delegate;
        uint token; 
    }
    mapping(address => StackHolder) public stackHolders;
    mapping(address => bool) public isOwners;
    mapping(uint => mapping(address => bool)) public approved;



    modifier onlyOwner(){
        require(isOwners[msg.sender],"caller is not owner");
        _;
    }
    modifier transactionExist(uint _transactionId){
        require(_transactionId < proposals.length,"Transaction is not exist");
        _;
    }
    modifier notApproved(uint _transactionId){
        require(!approved[_transactionId][msg.sender], "Transaction is already approved");
        _;
    }
   modifier notExecuted(uint _transactionId){
        require(!proposals[_transactionId].executed, "Transaction is already executed");
        _;
    }
    constructor(address[] memory _owners,uint _required) payable {
        require(_owners.length > 0 , "Minimum One Owners required");
        require(_required <= _owners.length && _required > 0,"Invalid required numbers of owners");
        for(uint i; i<_owners.length; i++){
            address owner = _owners[i];
            require(owner != address(0),"invaild owner");
            require(!isOwners[owner],"owner is not unique");
            stackHolders[owner] = StackHolder({
            stackHolder:owner,
            weight: 0,
            delegate:zeroAddr,
            token: 0  
        });
        members.push(owner);
        isOwners[owner] = true;
    }
       _transfeTokenShare();
       required = _required; 
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }
     receive() external payable{
        emit DepositFunds(msg.sender, msg.value);
    }


    function _transfeTokenShare() private {
        for(uint i=0; i < members.length; i++){
            address membersAddr = members[i];
            address toAccount = stackHolders[membersAddr].stackHolder;
            uint tokenAmt = 1500;
            transfer(toAccount, tokenAmt);
            stackHolders[membersAddr].token = tokenAmt;
            _tokenWeight(toAccount);
        }
    }


    function _tokenWeight(address addressIs) private {
        uint tokenAmount = stackHolders[addressIs].token;
        if(tokenAmount == 0){
            stackHolders[addressIs].weight = 0;
        }else if(tokenAmount <= 500){
            stackHolders[addressIs].weight = 1;
        }else if(tokenAmount <= 1000){
            stackHolders[addressIs].weight = 2;
        }else if(tokenAmount <= 1500){
            stackHolders[addressIs].weight = 3;
        }else if(tokenAmount <= 2000){
            stackHolders[addressIs].weight = 4;
        }else if(tokenAmount <= 2500){
            stackHolders[addressIs].weight = 5;
        }
    } 

    function transferTokenToStackHolders(address toAccount,uint amount)  public onlyOwner{
        require(isOwners[toAccount], "Given address is not stack holder of the contract");
        transfer(toAccount,amount);
        stackHolders[msg.sender].token = stackHolders[msg.sender].token - amount;
        _tokenWeight(msg.sender);
        stackHolders[toAccount].token = stackHolders[toAccount].token + amount;
        _tokenWeight(toAccount);
    }


    function submitProposal(address _to, uint _value,string memory _reason,uint _timelimit, bytes calldata _data)
        public {
            proposals.push(Proposal({
                from: msg.sender,
                to:_to,
                value:_value,
                data:_data,
                executed:false,
                timelimit:block.timestamp + _timelimit,
                reason:_reason
            }));
            emit SubmitProposal(proposals.length -1);
    }  

    function approveProposal(uint _transactionId) public onlyOwner transactionExist(_transactionId) notExecuted(_transactionId) notApproved(_transactionId) {
        Proposal storage proposalIs = proposals[_transactionId];
        require(block.timestamp < proposalIs.timelimit,"Voting time limit is exceed");
        require(stackHolders[msg.sender].weight >= 3, "Share holder dosen't have efficient share amount to do vote");
        approved[_transactionId][msg.sender] =true;
        emit ApproveProposal(msg.sender, _transactionId);
    } 


    function _getApprovalCount(uint _transactionId) private view returns(uint count) {
        for(uint i; i < members.length; i++){
            if(approved[_transactionId][members[i]]){
                count += 1;
            }
        }
        return count;
    }


    function executeProposal(uint _transactionId) public transactionExist(_transactionId) notExecuted(_transactionId){
        require(_getApprovalCount(_transactionId) >= required,"Approvals are less then the required");
        Proposal storage proposalIs = proposals[_transactionId];
        proposalIs.executed = true;
        (bool success,) = proposalIs.to.call{value: proposalIs.value}(proposalIs.data);
        require(success, "transaction failled"); 
        emit ExecuteProposal(_transactionId);
    }

}