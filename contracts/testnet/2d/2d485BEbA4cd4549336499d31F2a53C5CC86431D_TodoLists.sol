pragma solidity 0.8.4;

// SPDX-License-Identifier: BUSL-1.1

contract TodoLists {
    mapping(address => string[]) public address2ListIds;
    mapping(string => bool) public listIds2exists;
    mapping(address => bool) public user2used;
    uint256 public todoCnt = 0;
    string[] public listIds;

    address[] public users;

    function uint2str(
        uint256 _i
    ) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    struct TodoItem {
        string id;
        string title;
        string description;
        bool isDone;
    }
    struct TodoList {
        string id;
        TodoItem[] todos;
    }
    mapping(string => TodoItem[]) public id2TodoItems;

    function addList(string memory _id) public {
        if (listIds2exists[_id] == true) {
            revert("listid already exists");
        }
        address2ListIds[msg.sender].push(_id);
        if (user2used[msg.sender] == false) {
            user2used[msg.sender] = true;
            users.push(msg.sender);
        }
        if (listIds2exists[_id] == false) {
            listIds2exists[_id] = true;
            listIds.push(_id);
        }
    }

    function removeList(string memory _id) public {
        if (!user2used[msg.sender]) {
            revert("User never uses this app");
        }
        string[] storage userLists = address2ListIds[msg.sender];
        for (uint i = 0; i < userLists.length; i++) {
            // keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
            if (
                keccak256(abi.encodePacked(userLists[i])) ==
                keccak256(abi.encodePacked(_id))
            ) {
                userLists[i] = userLists[userLists.length - 1];
                TodoItem[] storage todos = id2TodoItems[_id];
                while (todos.length > 0) {
                    todos.pop();
                }
                userLists.pop();
                if (userLists.length == 0) {
                    // turn off the user
                    user2used[msg.sender] = false;
                    // delete user from users
                    for (uint j = 0; j < users.length; j++) {
                        if (users[j] == msg.sender) {
                            users[j] = users[users.length - 1];
                            users.pop();
                        }
                    }
                }
                listIds2exists[_id] = false;
            }
        }
    }

    function getUserIds() public view returns (string[] memory) {
        return address2ListIds[msg.sender];
    }

    function addTodo(
        string memory listid,
        string memory title,
        string memory description
    ) public {
        if (listIds2exists[listid] == false) {
            revert("listid not exists");
        }
        TodoItem memory todoItem = TodoItem(
            uint2str(todoCnt),
            title,
            description,
            false
        );
        todoCnt++;
        id2TodoItems[listid].push(todoItem);
    }

    function updateTodo(
        string memory todoId,
        string memory listid,
        string memory title,
        string memory description
    ) public {
        if (listIds2exists[listid] == false) {
            revert("listid not exists");
        }
        TodoItem[] storage todos = id2TodoItems[listid];
        for (uint i = 0; i < todos.length; i++) {
            if (
                keccak256(abi.encodePacked(todos[i].id)) ==
                keccak256(abi.encodePacked(todoId))
            ) {
                todos[i].title = title;
                todos[i].description = description;
            }
        }
    }

    function deleteTodo(string memory todoId, string memory listid) public {
        if (listIds2exists[listid] == false) {
            revert("listid not exists");
        }
        TodoItem[] storage todos = id2TodoItems[listid];
        if (todos.length == 0) {
            revert("todos is empty");
        }
        for (uint i = 0; i < todos.length; i++) {
            if (
                keccak256(abi.encodePacked(todos[i].id)) ==
                keccak256(abi.encodePacked(todoId))
            ) {
                todos[i] = todos[todos.length - 1];
                todos.pop();
            }
        }
    }

    function getTodos(address user) public view returns (TodoList[] memory) {
        string[] storage userLists = address2ListIds[user];
        TodoList[] memory todoLists = new TodoList[](userLists.length);
        for (uint i = 0; i < userLists.length; i++) {
            TodoItem[] storage todos = id2TodoItems[userLists[i]];
            todoLists[i] = TodoList(userLists[i], todos);
        }
        return todoLists;
    }

    receive() external payable {}

    fallback() external payable {}
}