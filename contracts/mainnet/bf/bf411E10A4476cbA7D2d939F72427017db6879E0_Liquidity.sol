// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Liquidity {

    address public admin;
    mapping(address => LiquidityInfo[]) public liquidities;
    uint256 public liquidityID;

    struct LiquidityInfo {
        uint256 id;
        address owner;
        string tokenA;
        string tokenB;
        string tokenA_Address;
        string tokenB_Address;
        string poolAddress;
        string network;
        string transactionHash;
        uint256 timeCreated;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function addLiquity(
        string memory _tokenA,
        string memory _tokenB,
        string memory _tokenA_Address,
        string memory _tokenB_Address,
        string memory _poolAddress,
        string memory _network,
        string memory _transactionHash

    ) external {
        liquidityID++;
        uint256 currentLiquidityID = liquidityID;

        liquidities[msg.sender].push (LiquidityInfo ({
            id: currentLiquidityID,
            owner: msg.sender,
            tokenA: _tokenA,
            tokenB: _tokenB,
            tokenA_Address: _tokenA_Address,
            tokenB_Address: _tokenB_Address,
            poolAddress: _poolAddress,
            network: _network,
            transactionHash: _transactionHash,
            timeCreated: block.timestamp
        }));
    }

    function getAllLiquidity(address _address) public view returns (LiquidityInfo[] memory) {
        return liquidities[_address];
    }

    function transferEther() external payable {
        require(msg.value > 0, "Amount should be greater than 0");

        //TRANSFER ETHER TO ADDRESS
        (bool success, ) = admin.call{value: msg.value} ("");
        require(success, "Transfer failed");
    }
}