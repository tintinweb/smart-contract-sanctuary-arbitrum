/**
 *Submitted for verification at Arbiscan on 2023-06-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

    struct NetWork {
        uint256 id;
        uint level;
        uint time;
        address sender_;
        address super_;
    }

contract Invitation {

    uint256 _autoIds;

    mapping(uint256 => NetWork) _netWorks;
    mapping(address => uint256) _userIds;

    address private _gate;
    address private _admin;
    address private _owner;

    event Post(uint256 indexed id, address indexed sender, uint256 level, address super_);

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyGate() {
        require(_gate == msg.sender || _admin == msg.sender, "Ownable: caller is not the gate");
        _;
    }

    function setGate(address __gate) external onlyAdmin
    {
        _gate = __gate;
    }

    modifier onlyAdmin() {
        require(_admin == msg.sender || _owner == msg.sender, "Ownable: caller is not the admin");
        _;
    }

    function setAdmin(address __admin) external onlyOwner
    {
        _admin = __admin;
    }

    constructor () {
        _owner = msg.sender;
        _autoIds = 1;
        _netWorks[_autoIds] = NetWork({
            id:_autoIds,
            level:0,
            time:block.timestamp,
            sender_:_owner,
            super_:address(0)
        });
        _userIds[_owner] = _autoIds;
    }

    function getAutoIds() external view returns (uint256)
    {
        return _autoIds;
    }

    function getInfoForId(uint256 _id) external view returns (NetWork memory)
    {
        return _netWorks[_id];
    }

    function getInfo(address _sender) external onlyGate view returns (NetWork memory)
    {
        return _netWorks[_userIds[_sender]];
    }

    function getSuper(address _sender) external onlyGate view returns (address)
    {
        uint256 id = _userIds[_sender];
        if (id == 0) return address(0);
        return _netWorks[id].super_;
    }

    function post(address _sender, address _super) external onlyGate
    {
        require(_userIds[_super] > 0, "Super invalid!");

        NetWork memory _superNetWork = _netWorks[_userIds[_super]];

        _autoIds++;
        NetWork memory netWork = NetWork({
            id:_autoIds,
            level:_superNetWork.level+1,
            time:block.timestamp,
            sender_:_sender,
            super_:_super
        });
        _netWorks[_autoIds] = netWork;
        _userIds[_sender] = _autoIds;

        emit Post(netWork.id, netWork.sender_, netWork.level, netWork.super_);
    }
}