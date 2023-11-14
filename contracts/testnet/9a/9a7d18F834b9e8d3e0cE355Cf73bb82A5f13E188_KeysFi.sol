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
import "./Data.sol";

interface IFriendforKeysFi {
    function getUserFrom(address from) external view returns (User memory);

    function getUserByCode(uint id) external view returns (User memory);

    function getInivteData(uint id) external view returns (address, uint, uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "./Data.sol";

interface IKeysFiforFriend {
    function setInitKey(address who) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "./Data.sol";
import "./IFriendforKeysFi.sol";
import "./IKeysFiforFriend.sol";

contract KeysFi is IKeysFiforFriend {
    address public protocolFeeDestination;
    uint256 public protocolFeePercent = 50;
    uint256 public subjectFeePercent = 50;
    // keysSubject => (Holder => Balance)
    mapping(address => mapping(address => uint256)) public keysBalance;

    // keysSubject => Supply
    mapping(address => uint256) public keysSupply;
    // subject=>sender[]
    mapping(address => mapping(uint => address)) holders;

    mapping(address => uint) holders_length;

    mapping(address => mapping(address => uint)) holders_index;
    //subject=>fans=>key amount

    // sender=>subject[]
    mapping(address => mapping(uint => address)) holding;
    mapping(address => uint) holding_length;
    mapping(address => mapping(address => uint)) holding_index;
    mapping(address => mapping(address => uint)) user_amount;

    IFriendforKeysFi frindeContract;
    address friend_address;

    constructor() {
        owner = msg.sender;
    }

    function setFriendAddress(address _address) external onlyOwner {
        require(isContract(_address), "address invaild");
        friend_address = _address;
        frindeContract = IFriendforKeysFi(_address);
    }

    function getPrice(
        uint256 supply,
        uint256 amount
    ) public pure returns (uint256) {
        uint256 sum1 = supply == 0
            ? 0
            : ((supply - 1) * (supply) * (2 * (supply - 1) + 1)) / 6;
        uint256 sum2 = supply == 0 && amount == 1
            ? 0
            : ((supply - 1 + amount) *
                (supply + amount) *
                (2 * (supply - 1 + amount) + 1)) / 6;
        uint256 summation = sum2 - sum1;
        return (summation * 1 ether) / 1600000;
    }

    function getBuyPrice(
        address keysSubject,
        uint256 amount
    ) public view returns (uint256) {
        return getPrice(keysSupply[keysSubject], amount);
    }

    function getSellPrice(
        address keysSubject,
        uint256 amount
    ) public view returns (uint256) {
        return getPrice(keysSupply[keysSubject] - amount, amount);
    }

    function getBuyPriceAfterFee(
        address keysSubject,
        uint256 amount
    ) public view returns (uint256) {
        uint256 price = getBuyPrice(keysSubject, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1000;
        uint256 subjectFee = (price * subjectFeePercent) / 1000;
        return price + protocolFee + subjectFee;
    }

    function getSellPriceAfterFee(
        address keysSubject,
        uint256 amount
    ) public view returns (uint256) {
        uint256 price = getSellPrice(keysSubject, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1000;
        uint256 subjectFee = (price * subjectFeePercent) / 1000;
        return price - protocolFee - subjectFee;
    }

    function buykeys(uint id, uint256 amount, uint inviteCode) public payable {
        (address keysSubject, uint _inviteCode, uint time) = frindeContract
            .getInivteData(id);
        require(
            block.timestamp - time > 60 * 60 * 12 ||
                _inviteCode == inviteCode ||
                msg.sender == keysSubject,
            "key101:The key not open"
        );

        uint256 supply = keysSupply[keysSubject];
        require(
            supply > 0 || keysSubject == msg.sender,
            "Only the keys' subject can buy the first share"
        );
        uint256 price = getPrice(supply, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1000;
        uint256 subjectFee = (price * subjectFeePercent) / 1000;
        require(
            msg.value >= price + protocolFee + subjectFee,
            "Insufficient payment"
        );
        keysBalance[keysSubject][msg.sender] =
            keysBalance[keysSubject][msg.sender] +
            amount;
        keysSupply[keysSubject] = supply + amount;

        (bool success1, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success2, ) = keysSubject.call{value: subjectFee}("");
        require(success1 && success2, "Unable to send funds");
        addKeys(keysSubject, msg.sender, amount);
    }

    function sellkeys(address keysSubject, uint256 amount) public payable {
        uint256 supply = keysSupply[keysSubject];
        require(supply > amount, "Cannot sell the last share");
        uint256 price = getPrice(supply - amount, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1000;
        uint256 subjectFee = (price * subjectFeePercent) / 1000;
        require(
            keysBalance[keysSubject][msg.sender] >= amount,
            "Insufficient keys"
        );
        keysBalance[keysSubject][msg.sender] =
            keysBalance[keysSubject][msg.sender] -
            amount;
        keysSupply[keysSubject] = supply - amount;

        (bool success1, ) = msg.sender.call{
            value: price - protocolFee - subjectFee
        }("");
        (bool success2, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success3, ) = keysSubject.call{value: subjectFee}("");
        require(success1 && success2 && success3, "Unable to send funds");
        removeKeys(keysSubject, amount);
    }

    function addKeys(address subject, address from, uint256 amount) private {
        if (user_amount[subject][from] == 0) {
            //holders
            holders[subject][holders_length[subject]] = from;
            holders_index[subject][from] = holders_length[subject];
            holders_length[subject] += 1;

            //holding
            holding[from][holding_length[from]] = subject;
            holding_index[from][subject] = holding_length[from];
            holding_length[from] += 1;
        }
        user_amount[subject][from] += amount;
    }

    function removeKeys(address subject, uint256 amount) private {
        uint ownAmout = user_amount[subject][msg.sender];
        require(
            keysSupply[subject] > amount && ownAmout >= amount,
            "the amount is wrong"
        );
        if (ownAmout - amount == 0) {
            //holder
            address holders_last = holders[subject][
                holders_length[subject] - 1
            ];
            holders[subject][holders_index[subject][msg.sender]] = holders_last;
            holders_index[subject][holders_last] = holders_index[subject][
                msg.sender
            ];
            holders_length[subject] -= 1;

            //holding
            address holding_last = holding[subject][
                holders_length[subject] - 1
            ];
            holding[msg.sender][
                holding_index[msg.sender][subject]
            ] = holding_last;
            holding_index[msg.sender][holding_last] = holding_index[msg.sender][
                subject
            ];

            holding_length[msg.sender] -= 1;
        }
        user_amount[subject][msg.sender] -= amount;
    }

    function setInitKey(address who) external returns (bool) {
        require(msg.sender == friend_address, "address invild");
        addKeys(who, who, 1);
        return true;
    }

    //get userinfo

    function getSubject(
        uint id,
        address subject
    ) external view returns (User[] memory, uint, uint, uint, uint) {}

    //tools
    function isContract(address a) private view returns (bool) {
        return a.code.length > 0;
    }

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