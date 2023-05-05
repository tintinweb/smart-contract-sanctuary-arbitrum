// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./ERC20Capped.sol";

contract Headlines is ERC20Capped, Ownable {
    uint256 public constant maxSupply = 220000000000 * 10 ** 18; // 220b
    uint256 public prizePool = 50000000000 * 10 ** 18; // 50b
    uint256 public teamSupply = 20000000000 * 10 ** 18; // 20b
    uint256 public initialMintAmount = 5000000 * 10 ** 18; // 5m
    uint256 public hlsCost = 250000 * 10 ** 18; // 250k
    uint256 public mintCost = 5 * 10 ** 14; // 0.0005, 1u
    uint256 public lastClipUpdate;
    address public hlsOwner;
    string public hls = "FUCK XIRTAM";
    mapping(address => uint256) public lastMintValue;
    mapping(address => uint256) public lastMintTime;

    event ClipUpdated(
        address indexed user,
        string message,
        uint256 newClipCost
    );
    event PrizePoolClaimed(address indexed hlsOwner, uint256 amount);
    event Log(string func, uint gas);

    modifier maxLength(string memory message) {
        require(
            bytes(message).length <= 26,
            "Message must be 26 characters or less"
        );
        _;
    }

    constructor() ERC20("Headlines", "HLS") ERC20Capped(maxSupply) {
        _mint(address(this), maxSupply);
        _transfer(address(this), msg.sender, teamSupply);
        hlsOwner = msg.sender;
    }

    function mintHls() external payable {
        require(
            block.timestamp >= lastMintTime[msg.sender] + 1 days,
            "You can only mint once every 24 hours"
        );
        require(msg.value == mintCost, "Need little fee");
        uint256 mintAmount;
        if (lastMintValue[msg.sender] == 0) {
            mintAmount = initialMintAmount;
        } else {
            mintAmount = lastMintValue[msg.sender] / 2;
        }
        require(mintAmount > 0, "Mint amount is too small");
        require(
            balanceOf(address(this)) - prizePool >= mintAmount,
            "Not enough HLS left to mint"
        );
        lastMintValue[msg.sender] = mintAmount;
        lastMintTime[msg.sender] = block.timestamp;
        _transfer(address(this), msg.sender, mintAmount);
    }

    function setHls(string memory message) external maxLength(message) {
        require(bytes(message).length > 0, "Message cannot be empty");
        if (msg.sender != hlsOwner) {
            require(
                balanceOf(msg.sender) >= hlsCost,
                "Insufficient HLS"
            );
            IERC20(address(this)).transferFrom(
                msg.sender,
                address(this),
                hlsCost
            );
            _burn(address(this), hlsCost);
            hlsCost = hlsCost + (hlsCost * 5000) / 10000;
        }
        hls = message;
        hlsOwner = msg.sender;
        lastClipUpdate = block.timestamp;
        emit ClipUpdated(msg.sender, message, hlsCost);
    }

    function claimPrizePool() external {
        require(
            block.timestamp >= lastClipUpdate + 7 days,
            "Prizepool can be claimed if 7 days have passed without a HLS update"
        );
        require(
            msg.sender == hlsOwner,
            "Only the current hlsOwner can claim the prizepool"
        );
        uint256 claimAmount = prizePool;
        prizePool = 0;
        _transfer(address(this), msg.sender, claimAmount);
        emit PrizePoolClaimed(msg.sender, prizePool);
    }

    fallback() external payable {
        emit Log("fallback", gasleft());
    }

    receive() external payable {
        emit Log("receive", gasleft());
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(getBalance());
    }
}