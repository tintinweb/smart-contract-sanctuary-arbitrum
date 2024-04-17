// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Exchange.sol";

contract RedPacketFactory is Ownable,Pausable,ReentrancyGuard{

    event RedPacketDeployed(RedPacket createRedPacket);

    mapping (string => RedPacket) private uuid_redpacket;

    address private boom_address;

    address private to_address;

    address private exchange_address;

    Exchange private exchange_interface;

    ERC20 private boom_interface;

    struct RedPacket{
        string uuid; //red_packet_uuid
        uint create_time; //red_packet_create_time
        uint256 red_pakcet_amount;
        uint256 gas_amount;
        uint red_packet_count;
        address to_address;
        bool is_used;
    }

    function setExchangeAddress(address _exchnage_address) public onlyOwner {
        exchange_address = _exchnage_address;
        exchange_interface = Exchange(exchange_address);
    }

    function getExchangeAddress() public view returns (address) {
        return exchange_address;
    }

    function setBoomAddress(address _boom_address) public onlyOwner {
        boom_address = _boom_address;
        boom_interface = ERC20(_boom_address);
    }

    function getBoomAddress() public view returns (address) {
        return boom_address;
    }

    function setToAddress(address _to_address) public onlyOwner {
        to_address = _to_address;
    }

    function getToAddress() public view returns (address) {
        return to_address;
    }

    function getRedPacketInfo(string memory _uuid) public view returns (RedPacket memory){
        return uuid_redpacket[_uuid];
    }

    function createRedPacket(string memory _uuid,uint256 _amount, uint _count) public payable{
        uint eth_amount = msg.value;
        require(!uuid_redpacket[_uuid].is_used,"The red packet is existed");
        exchange_interface.subBoomBalance(msg.sender,_amount);
        payable(address(to_address)).transfer(eth_amount);
        boom_interface.mint(to_address,_amount);
        RedPacket memory newRedPacket;
        newRedPacket.uuid = _uuid;
        newRedPacket.create_time = block.timestamp;
        newRedPacket.red_pakcet_amount = _amount;
        newRedPacket.gas_amount = eth_amount;
        newRedPacket.red_packet_count = _count;
        newRedPacket.to_address = to_address;
        newRedPacket.is_used = true;
        uuid_redpacket[_uuid] = newRedPacket;
        emit RedPacketDeployed(newRedPacket);
    }

    constructor(address _exchnage_address,address _boom_address,address _to_address){
        boom_address = _boom_address;
        boom_interface = ERC20(_boom_address);
        exchange_address = _exchnage_address;
        exchange_interface = Exchange(_exchnage_address);
        to_address = _to_address;
    }
}