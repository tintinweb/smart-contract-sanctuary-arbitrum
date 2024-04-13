/**
 *Submitted for verification at Arbiscan.io on 2024-04-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract RwasTeam is Ownable {

    address public manager;
    modifier onlyManager() {
        require(owner() == msg.sender || manager == msg.sender, "For Manager Use Only");
        _;
    }
    function setManager(address _manager) public onlyManager {
        manager = _manager;
    }

    mapping(address => bool) public addressControllerMap;//address => Controller
    function setController(address _controller,bool _flag) public onlyManager {
        addressControllerMap[_controller] = _flag;
    }

    modifier onlyController() {
        require(addressControllerMap[msg.sender] == true, "For Controller Use Only");
        _;
    }
    
    mapping(uint256 => address) public teamNumberLeaderMap;//team number => leader address
    mapping(address => uint256) public addressTeamNumberMap;//address => team number
    event Event_Register(address _address,uint256 _teamNumber);

    constructor () {
        manager = msg.sender;
    }

    function register(address _address) public onlyManager {
        require(addressTeamNumberMap[_address] == 0, "This address has already been registered");
        addressTeamNumberMap[_address] = block.number;
        teamNumberLeaderMap[block.number] = _address;
        emit Event_Register(_address,block.number);
    }

    function getTeamNumber(address _address) public view returns(uint256){
        return addressTeamNumberMap[_address];
    }

    function getLeader(uint256 _teamNumber) public view returns(address){
        return teamNumberLeaderMap[_teamNumber];
    }

    function validTeamNumber(uint256 _teamNumber) public view returns(bool){
        if(teamNumberLeaderMap[_teamNumber] == address(0)){
            return false;
        }
        return true;
    }
    
    function setTeamNumber(address _address,uint256 _teamNumber) external onlyController {
        require(teamNumberLeaderMap[_teamNumber] != address(0), "Team Number is invalid");
        require(addressTeamNumberMap[_address] == 0, "This address has already been registered");
        addressTeamNumberMap[_address] = _teamNumber;
    }
}