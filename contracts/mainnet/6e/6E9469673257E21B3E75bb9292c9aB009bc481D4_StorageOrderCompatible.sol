/**
 *Submitted for verification at Arbiscan on 2023-02-10
*/

//SPDX-License-Identifier: UnLicensed
pragma solidity 0.8.4;

interface IERC20 {
    function transfer(address _to, uint _value) external;
}

contract StorageOrderCompatible {

    address payable public owner;
    uint public basePrice;
    uint public bytePrice;
    uint public sizeLimit;
    uint public servicePriceRate;
    mapping(address => bool) public nodes;
    address[] public nodeArray;

    event Order(address customer, address merchant, string cid, uint size, uint price);

    constructor(uint basePrice_, uint bytePrice_, uint servicePriceRate_, uint sizeLimit_) {
        owner = payable(msg.sender);
        basePrice = basePrice_;
        bytePrice = bytePrice_;
        servicePriceRate = servicePriceRate_;
        sizeLimit = sizeLimit_;
    }

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function"
        );
        _;
    }

    function addOrderNode(address nodeAddress) public onlyOwner {
        require(nodes[nodeAddress] == false, "Node already added");
        nodes[nodeAddress] = true;
        nodeArray.push(nodeAddress);
    }

    function removeOrderNode(address nodeAddress) public onlyOwner {
        require(nodes[nodeAddress], "Node not exist");
        delete nodes[nodeAddress];
        uint len = nodeArray.length;
        for (uint i = 0; i < len; i++) {
            if (nodeArray[i] == nodeAddress) {
                nodeArray[i] = nodeArray[len-1];
                nodeArray.pop();
                break;
            }
        }
    }

    function setOrderPrice(uint basePrice_, uint bytePrice_) public onlyOwner {
        basePrice = basePrice_;
        bytePrice = bytePrice_;
    }

    function setServicePriceRate(uint servicePriceRate_) public onlyOwner {
        servicePriceRate = servicePriceRate_;
    }

    function setSizeLimit(uint sizeLimit_) public onlyOwner {
        sizeLimit = sizeLimit_;
    }

    function getPrice(uint size) public view returns (uint price) {
        require(sizeLimit >= size, "Size exceeds the limit");
        return (basePrice + size * bytePrice / (1024**2)) * (servicePriceRate + 100) / 100;
    }

    function placeOrder(string memory cid, uint size) public payable {
        placeOrderWithNode(cid, size, getRandomNode(cid));
    }

    function placeOrderWithNode(string memory cid, uint size, address nodeAddress) public payable {
        require(sizeLimit >= size, "Size exceeds the limit");
        require(nodes[nodeAddress], "Unsupported node");

        uint price = getPrice(size);
        require(msg.value >= price, "No enough MATIC to place order");
        payable(nodeAddress).transfer(price);
        // Refund left MATIC
        if (msg.value > price)
            payable(msg.sender).transfer(msg.value - price);
        emit Order(msg.sender, nodeAddress, cid, size, price);
    }

    function getRandomNode(string memory cid) internal view returns (address) {
        require(nodeArray.length > 0, "No node to choose");
        uint nodeID = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, cid))) % nodeArray.length;
        return nodeArray[nodeID];
    }
}