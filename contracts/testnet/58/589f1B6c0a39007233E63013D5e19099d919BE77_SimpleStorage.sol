// SimpleStorage.sol
// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.8.19;

contract SimpleStorage {

    enum taskStatus { Doing, Done }

    struct Task {
        string task;
        taskStatus status;
        address creator;
    }

    Task[] private tasks;
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    // Modifier to check if the sender is the creator of the task
    modifier onlyTaskCreator(uint256 index) {
        require(index < tasks.length, "Index out of bounds");
        require(tasks[index].creator == msg.sender, "Only the task creator can perform this operation");
        _;
    }

    function addTask(string memory _task) public {
        Task memory newTask = Task({
            task: _task,
            status: taskStatus.Doing,
            creator: msg.sender
        });
        tasks.push(newTask);
    }

    function getTask(uint256 index) public view onlyTaskCreator(index) returns (Task memory) {
        return tasks[index];
    }

    function getTaskCount() public view returns (uint256) {
        uint256 count=0;
        for(uint256 i=0;i<=tasks.length;i++){
            if(tasks[i].creator == msg.sender){
                count++;
            }
        }
        return count;
    }

    function removeIndex(uint256 index) public onlyTaskCreator(index) {
        require(index < tasks.length, "Index out of bounds");
        tasks[index] = tasks[tasks.length - 1];
        tasks.pop();
    }

    function updateIndex(uint256 index, string memory _task, taskStatus _status) public onlyTaskCreator(index) {
        require(index < tasks.length, "Index out of bounds");
        Task memory newTask = Task({
            task: _task,
            status: _status,
            creator: msg.sender
        });
        tasks[index] = newTask;
    }

      function removeAll() public {
        uint256 i = 0;
        while (i < tasks.length) {
            if (tasks[i].creator == msg.sender) {
                tasks[i] = tasks[tasks.length - 1];
                tasks.pop();
            } else {
                i++;
            }
        }
    }
}