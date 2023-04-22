// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Basic {
    address public owner;
    mapping(address => bool) isMod;
    bool public isPause = false;
    modifier onlyOwner() {
        require(msg.sender == owner, "Must be owner");
        _;
    }
    modifier onlyMod() {
        require(isMod[msg.sender] || msg.sender == owner, "Must be mod");
        _;
    }

    modifier notPause() {
        require(!isPause, "Must be not pause");
        _;
    }

    function addMod(address _mod) public onlyOwner {
        if (_mod != address(0x0)) {
            isMod[_mod] = true;
        }
    }

    function removeMod(address _mod) public onlyOwner {
        isMod[_mod] = false;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        if (_newOwner != address(0x0)) {
            owner = _newOwner;
        }
    }

    function changePause(uint256 _change) public onlyOwner {
        isPause = _change == 1;
    }

    constructor() {
        owner = msg.sender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./BasicAuth.sol";

contract MemberManager is Basic {
    address[] public addressBook;
    mapping(address => address) public sponsor;

    event NewMember(address member, address sponsor);

    constructor() {
        addressBook.push(msg.sender);
    }

    function getTotalMember() public view returns (uint256) {
        return addressBook.length;
    }

    function addMember(
        address _member,
        address _sponsor
    ) public onlyMod notPause {
        require(
            sponsor[_sponsor] != address(0x0) || _sponsor == owner,
            "Sponsor must be user"
        );
        sponsor[_member] = _sponsor;
        addressBook.push(_member);
        emit NewMember(_member, _sponsor);
    }

    function getParentTree(
        address _child
    ) public view returns (address[8] memory) {
        address nextParent = _child;
        address[8] memory addressList;
        for (uint256 i = 0; i < 8; i++) {
            if (sponsor[nextParent] != address(0x0)) {
                addressList[i] = sponsor[nextParent];
                nextParent = sponsor[nextParent];
            } else {
                break;
            }
        }
        return addressList;
    }

    function isParent(
        address _parent,
        address _child
    ) public view returns (bool) {
        if (_parent == _child) return true;
        address nextParent = sponsor[_child];
        while (nextParent != address(0x0)) {
            if (nextParent == _parent) return true;
            nextParent = sponsor[_child];
        }
        return false;
    }
}