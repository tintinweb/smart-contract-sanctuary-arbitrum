// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

//Code by 9571  2024-06-16

contract LogLib {

    event debugstr(
        address addr1,
        address addr2,
        uint256 time,
        string  msg1,
        string  msg2,
        uint256 num
    );
    event debugnum(
        address addr1,
        address addr2,
        uint256 time,
        string  msg1,
        uint256 num1,
        uint256 num2
    );
    event debugaddr(
        address addr1,
        address addr2,
        uint256 time,
        address addr3,
        string  msg1,
        uint256 num1,
        uint256 num2
    );

    event debuggroup(
        address addr1,
        address addr2,
        uint256 time,
        address addr3,
        string  msg1,
        string  msg2,
        string  msg3,
        string  msg4,
        string  msg5,
        uint256 num1,
        uint256 num2,
        uint256 num3
    );

    event debuglist(
        address addr1,
        address addr2,
        uint256 time,
        string[]   msg1,
        address[]  msg2,
        uint256[]  num
    );

    function LogStr(
        string memory msg1,
        string memory msg2,
        uint256 num
    ) public {
        emit debugstr(
            address(msg.sender),
            tx.origin,
            block.timestamp,
            msg1,
            msg2,
            num
        );
    }

    function LogNum(
        string memory msg1,
        uint256 num1,
        uint256 num2
    ) public {
        emit debugnum(
            address(msg.sender),
            tx.origin,
            block.timestamp,
            msg1,
            num1,
            num2
        );
    }

    function LogAddr(
        address target_addr,
        string memory msg1,
        uint256 num1,
        uint256 num2
    ) public {
        emit debugaddr(
            address(msg.sender),
            tx.origin,
            block.timestamp,
            target_addr,
            msg1,
            num1,
            num2
        );
    }

    function logGroup(
        address target_addr,
        string memory msg1,
        string memory msg2,
        string memory msg3,
        string memory msg4,
        string memory msg5,
        uint256 num1,
        uint256 num2,
        uint256 num3
    ) public {
        emit debuggroup(
            address(msg.sender),
            tx.origin,
            block.timestamp,
            target_addr,
            msg1,
            msg2,
            msg3,
            msg4,
            msg5,
            num1,
            num2,
            num3
        );
    }

      function LogList(
        string[] memory msg1,
        address[] memory msg2,
        uint256[] memory num
    ) public {
        emit debuglist(
            address(msg.sender),
            tx.origin,
            block.timestamp,
            msg1,
            msg2,
            num
        );
    }

}

/*
interface LogLib {
    function LogStr(
        string memory msg1,
        string memory msg2,
        uint256 num
    ) external;

    function LogNum(
        string memory msg1,
        uint256 num1,
        uint256 num2
    ) external;

    function LogAddr(
        address target_addr,
        string memory msg1,
        uint256 num1,
        uint256 num2
    ) external;

    function logGroup(
        address target_addr,
        string memory msg1,
        string memory msg2,
        string memory msg3,
        string memory msg4,
        string memory msg5,
        uint256 num1,
        uint256 num2,
        uint256 num3
    ) external;

    function LogList(
        string[] memory msg1,
        address[] memory msg2,
        uint256[] memory num
    ) external;

}
*/