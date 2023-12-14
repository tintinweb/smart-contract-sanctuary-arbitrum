/**
 *Submitted for verification at Arbiscan.io on 2023-12-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DEFI_DIVIDE {
    struct groupStructureArray {
        string name;
        uint UID;
        address[] members;
    }

    struct ExpenseStructureArray {
        string context;
        uint256 amount;
        address paidby;
        address[] involvedAddresses;
        uint[] splitamount;
        bool[] settlementTracking;
        string json_deatils;
    }
    //

    ExpenseStructureArray[] private expenses;
    groupStructureArray[] private groups;

    // Mapping from group UID to an array of expense indices
    mapping(uint => uint256[]) private  groupExpenses;

    // Mapping for  receving address preferences
    mapping (address => bool) private isUPI;

    // Mapping for receving address prefered crypto 
    mapping (address => address) private cyrptopreference;

    // Mapping from user address to an array of group UIDs
    mapping(address => uint[]) private userGroups;

    // Mapping from expense index to a mapping of member addresses to their settlement status
    mapping(uint256 => mapping(address => bool)) public expenseSettlementStatus;


    // mapping(uint => uint256[]) public groupExpenses;
    function getGroupExpenses(uint uid) public view returns (uint[] memory){
        return groupExpenses[uid];
    }




    // Mapping to track how much each address owes in each group
    // The key is a combination of group UID and member address
    mapping(uint => mapping(address => uint256)) public amountOwed;
    mapping (uint => mapping(address => uint256)) public amountToBeGiven;

    address adminWallet =  0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    function changeCyrptoPreference(address preferedCrypto) public {
        cyrptopreference[msg.sender] = preferedCrypto;
    }

    function setReceiverPreference(bool _isUPI) public {
        isUPI[msg.sender] = _isUPI ;
    }

    function checkReceiverType(address receiver) public   view returns(string memory val){
        if ( isUPI[receiver] ){
            return "UPI";
        }
        else {
            return "CRYPTO";
        }
    }


    // Event declaration
    event GroupCreated(string name, uint UID, address[] members);

    // Event for split expense
    event ExpenseSplit(string context, uint256 amount, address involvedAddress);

    function createGroup(string memory name,uint _UID, address[] memory _members) public {
        groupStructureArray memory newGroup = groupStructureArray({
            name:name,
            UID: _UID,
            members: _members
        });

        groups.push(newGroup);
        // Add each member to the userGroups mapping
        for (uint i = 0; i < _members.length; i++) {
            userGroups[_members[i]].push(_UID);
        }
        
        // Emit the event after creating the group
        emit GroupCreated(name, _UID, _members);

    }
    // Function to check if an address is a member of a group
    function isGroupMember(uint _groupUID, address _member) public view returns (bool) {
        
        uint[] memory usergroups = userGroups[_member];

        for (uint i = 0; i < usergroups.length; i++) {
                if (usergroups[i] ==_groupUID) {
                    return true;
                }
            }
        return false;
        }
    

    function findGroupIndex(uint _UID) private view returns (uint256) {
        for(uint i = 0; i < groups.length; i++) {
            if(groups[i].UID == _UID) {
                return i;
            }
        }
        return groups.length; // Returns an out-of-range index if not found
    }
    function addExpenseToGroup(uint _groupUID, ExpenseStructureArray memory _expense) public {
        // Ensure the group exists and get its index
        uint256 groupIndex = findGroupIndex(_groupUID);
        require(groupIndex < groups.length, "Group does not exist.");
        amountToBeGiven[_groupUID][_expense.paidby] = _expense.amount; 
        // Check if msg.sender is a member of the group
        bool isMember = false;
        for (uint i = 0; i < groups[groupIndex].members.length; i++) {
            if (groups[groupIndex].members[i] == msg.sender) {
                isMember = true;
                break;
            }
        }
        require(isMember, "Sender is not a member of the group.");

        // Add the expense to the expenses array and get its index
        for (uint i = 0; i < _expense.involvedAddresses.length; i++) {
            _expense.settlementTracking[i] = false;
        }
        expenses.push(_expense);
        uint256 expenseIndex = expenses.length - 1;

        // Link the expense index to the group
        groupExpenses[_groupUID].push(expenseIndex);
        
        for (uint i = 0; i < _expense.involvedAddresses.length; i++) {
            expenseSettlementStatus[expenseIndex][_expense.involvedAddresses[i]] = false;
        }

        // If default split is true, split the expense equally and emit events
        
        require(_expense.splitamount.length == _expense.involvedAddresses.length, "Split amounts do not match involved addresses.");
        for (uint i = 0; i < _expense.involvedAddresses.length; i++) {
            if (_expense.involvedAddresses[i] != _expense.paidby) {
                amountOwed[_groupUID][_expense.involvedAddresses[i]] += _expense.splitamount[i];

            }
            emit ExpenseSplit(_expense.context, _expense.splitamount[i], _expense.involvedAddresses[i]);
            
        }
    }

    // Function to retrieve group details, accessible only to its members
    function getGroupDetails(uint _groupUID) public view returns (groupStructureArray memory) {
        uint256 groupIndex = findGroupIndex(_groupUID);
        require(groupIndex < groups.length, "Group does not exist.");
        return groups[groupIndex];
    }

    // Function to retrieve expense details, accessible only to members of the group associated with the expense
    function getExpenseDetails(uint256 _expenseIndex) public view returns (ExpenseStructureArray memory) {
        require(_expenseIndex < expenses.length, "Expense does not exist.");
        return expenses[_expenseIndex];
    }
    // Function to retrieve the list of groups a user is a member of
    function getUserGroups(address user) public view returns (uint[] memory) {
        return userGroups[user];
    }

    function settleUp(uint _groupUID, uint256[] memory expenseIndices) public returns (uint256) {
        require(isGroupMember(_groupUID, msg.sender), "Caller is not a member of the group.");

        uint256 amountpaid = 0;
        for (uint i = 0; i < expenseIndices.length; i++) {
            require(expenseIndices[i] < expenses.length, "Invalid expense index.");
            ExpenseStructureArray storage expense = expenses[expenseIndices[i]];

            // Find the caller's index in involvedAddresses
            int256 callerIndex = -1;
            for (uint j = 0; j < expense.involvedAddresses.length; j++) {
                if (expense.involvedAddresses[j] == msg.sender) {
                    callerIndex = int256(j);
                    break;
                }
            }
            require(callerIndex >= 0, "Caller not involved in the expense.");

            // Update settlement tracking for the caller
            expense.settlementTracking[uint256(callerIndex)] = true;  
            amountpaid += expense.splitamount[uint256(callerIndex)];
            amountOwed[_groupUID][msg.sender] = amountOwed[_groupUID][msg.sender] -amountpaid ;
            
        }
        return amountpaid;
    }
}