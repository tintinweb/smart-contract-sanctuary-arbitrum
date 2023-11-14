// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
struct User {
    string name; //elon musk
    uint sign_time;
    string username; //sender username @elonmusk
    string profile_image_url;
    string bio;
    uint whoid; // dapp user id
    uint invite_from; //invite id
    string location;
    bool verified;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "./InviteCode.sol";
import "./Data.sol";
import "./IFriendforKeysFi.sol";
import "./IKeysFiforFriend.sol";

contract Friend is IFriendforKeysFi {
    InviteCode inviteCode_Script = new InviteCode();

    mapping(address => User) users;
    mapping(address => bool) isSign_address;
    mapping(string => bool) isSign_xid;
    mapping(uint => address) id_address;
    mapping(uint => address) userCount_address;
    mapping(uint => uint) id_inviteCode;
    uint public usersCount;
    uint code = 100000;

    bool stopSign = false;

    address public keysFi_address;
    IKeysFiforFriend keysFiContract;

    constructor() {
        owner = msg.sender;
    }

    function setkeysFiAddress(address _address) external onlyOwner {
        require(isContract(_address), "address invaild");
        keysFi_address = _address;
        keysFiContract = IKeysFiforFriend(_address);
    }

    function signUp(User memory _user, string memory xxx) external {
        require(!stopSign, "fr500");
        require(!isContract(msg.sender), "fr501");
        require(!isSign_address[msg.sender], "fr502");
        require(!isSign_xid[xxx], "fr503");
        require(getLen(_user.name) < 257, "fr101:");
        require(getLen(_user.username) < 257, "fr102");
        require(getLen(_user.profile_image_url) < 257, "fr103");
        require(getLen(_user.bio) < 1025, "fr104");
        code += usersCount + (block.timestamp % 8);
        _user.whoid = code;

        _user.sign_time = block.timestamp;
        users[msg.sender] = _user;
        id_address[code] = msg.sender;
        userCount_address[usersCount] = msg.sender;
        isSign_address[msg.sender] = true;
        isSign_xid[xxx] = true;
        usersCount++;
        id_inviteCode[code] = inviteCode_Script.setInviteCode(code);
        bool isok = keysFiContract.setInitKey(msg.sender);
        require(isok, "fr404");
    }

    // event InviteCodeeEvent(uint);

    function setStopSign(bool v) external onlyOwner {
        stopSign = v;
    }

    function getUserByIndex(
        uint i
    ) external view onlyOwner returns (User memory) {
        return users[userCount_address[i]];
    }

    function getInviteCode() external view returns (uint) {
        return id_inviteCode[users[msg.sender].whoid];
    }

    function getAddressByCode(uint id) external view returns (address) {
        return id_address[id];
    }

    function getUserByCode(
        uint id
    ) external view returns (User memory, address) {
        return (users[id_address[id]], id_address[id]);
    }

    function getUser() external view returns (User memory) {
        return users[msg.sender];
    }

    function getUserFrom(address from) external view returns (User memory) {
        require(msg.sender == keysFi_address, "address invaild");
        return users[from];
    }

    function getInivteData(
        uint id
    ) external view returns (address, uint, uint) {
        User memory _user = users[id_address[id]];
        return (id_address[id], id_inviteCode[_user.whoid], _user.sign_time);
    }

    ///////////////---------tools
    function getLen(string memory s) public pure returns (uint) {
        return bytes(s).length;
    }

    function isContract(address a) private view returns (bool) {
        return a.code.length > 0;
    }

    ////-----------------------keys--------------------------------------

    ///------------------------keys end----------------------------------
    //-admin
    address private owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "not Owner");
        _;
    }

    function changeOwner(address a) external onlyOwner {
        require(a != address(0), "a err");
        owner = a;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "./Data.sol";

interface IFriendforKeysFi {
    function getUserFrom(address from) external view returns (User memory);

    function getUserByCode(
        uint id
    ) external view returns (User memory, address);

    ///subject ,invite code , sign time
    function getInivteData(uint id) external view returns (address, uint, uint);

    function getAddressByCode(uint id) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "./Data.sol";

interface IKeysFiforFriend {
    function setInitKey(address who) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract InviteCode {
    function setInviteCode(uint length) external view returns (uint) {
        return block.timestamp * (length % 100) * 17 + block.number * 13 + 22;
    }
}