// SimpleStorage.sol
// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.8.19;

contract SimpleStorage {

    enum taskStatus{Doing,Done}

    struct Task{     //struct means interface
     string task;
     taskStatus status;
    }

    Task[] public tasks;
    address private owner;

constructor(){
    owner = msg.sender;
    }

    function getOwner() public view returns (address) {    
        return owner;
    }

    function addTask(string memory _task, taskStatus _status) public {
        require(owner==tx.origin,"Only the original sender can update status");
       Task memory newTask = Task ({
        task:_task,
        status:_status
       });
       tasks.push(newTask);
    }

    function getAll() public view returns (Task[] memory){
        require(owner==tx.origin,"Only the original sender can read status");
         return tasks;
    }
    
    function removeIndex(uint256 Index) public {
        require(owner==tx.origin,"Only the original sender can update status");
        require(Index < tasks.length, "Index out of bounds");
        tasks[Index] = tasks[tasks.length-1];
          tasks.pop();
    }

    function updateIndex(uint256 Index, string memory _task, taskStatus _status) public {
        require(owner==tx.origin,"Only the original sender can update status");
            require(Index < tasks.length, "Index out of bounds");
             Task memory newTask = Task ({
              task:_task,
              status:_status
            });
            tasks[Index]=newTask;
    }

     function removeAll() public {
        require(owner==tx.origin,"Only the original sender can update status");
        delete tasks ;
    }
}