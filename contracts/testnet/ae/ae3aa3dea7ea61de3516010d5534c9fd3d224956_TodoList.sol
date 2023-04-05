/**
 *Submitted for verification at Arbiscan on 2023-04-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {
    string[] private todoItems;

    function addTodoItem(string memory newItem) public {
        todoItems.push(newItem);
    }

    function deleteTodoItem(uint256 indexToDelete) public {
        require(indexToDelete < todoItems.length, "Invalid index to delete.");
        todoItems[indexToDelete] = todoItems[todoItems.length - 1];
        todoItems.pop();
    }

    function getAllTodoItems() public view returns (string[] memory) {
        return todoItems;
    }
}