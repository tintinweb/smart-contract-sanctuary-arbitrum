/**
 *Submitted for verification at Arbiscan on 2023-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error NotReceiver();
error NotOwner();
error NotActive();

/**
 * @title ERC20
 * @dev Interface for ERC20 tokens
 */
interface ERC20 {
    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

/**
 * @title CrowdfundingFactory
 * @dev Deployer for Crowdfunding contract
 */
contract CrowdfundingFactory {
    address public receiver;
    address public owner;
    address public payment;
    address[] public deployedContracts;

    constructor(address _payment) {
        owner = msg.sender;
        payment = _payment;
    }

    event Campaign(
        address indexed contractAddress,
        address indexed payment,
        address indexed owner,
        uint256 sale,
        uint256 created
    );

    function createContract(uint256 _sale) public onlyOwner {
        address newContract = address(new Crowdfunding(payment, owner, _sale));
        deployedContracts.push(newContract);

        // emit event
        emit Campaign(newContract, payment, owner, _sale, block.timestamp);
    }

    function transferOwnership(address _receiver) public onlyOwner {
        receiver = _receiver;
    }

    function updateOwner() public onlyReceiver {
        owner = receiver;
        receiver = address(0);
    }

    function updatePayment(address _payment) public onlyOwner {
        payment = _payment;
    }

    function getDeployedContractsLength() public view returns (uint256) {
        return deployedContracts.length;
    }

    modifier onlyReceiver() {
        if (msg.sender != receiver) {
            revert NotReceiver();
        }
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }
}

/**
 * @title Crowdfunding
 * @dev Fundraising contract for crypto projects, payment token will be specified by owner on constructor
 */
contract Crowdfunding {
    ERC20 public payment;
    bool public isActive = true;
    address public immutable factory;
    address public immutable owner;
    uint256 public sale;
    uint256 public sold;
    address[] public participants;
    mapping(address => uint256) public allocations;

    constructor(address _payment, address _owner, uint256 _sale) {
        payment = ERC20(_payment);
        owner = _owner;
        sale = _sale;
        factory = msg.sender;
    }

    event Deposit(
        address indexed user,
        address indexed payment,
        uint256 amount,
        uint256 timestamp
    );

    event Withdraw(
        address indexed user,
        address indexed payment,
        uint256 amount,
        uint256 timestamp
    );

    function deposit(uint256 _amount) public onlyActive {
        payment.transferFrom(msg.sender, address(this), _amount);
        if (allocations[msg.sender] == 0) participants.push(msg.sender);
        allocations[msg.sender] += _amount;
        sold += _amount;

        // emit event
        emit Deposit(msg.sender, address(payment), _amount, block.timestamp);
    }

    function withdraw() public onlyOwner {
        uint256 balance = payment.balanceOf(address(this));
        payment.transfer(owner, balance);

        // emit event
        emit Withdraw(msg.sender, address(payment), balance, block.timestamp);
    }

    function togglePause() public onlyOwner {
        isActive = !isActive;
    }

    function getParticipantsLength() public view returns (uint256) {
        return participants.length;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    modifier onlyActive() {
        if (!isActive) {
            revert NotActive();
        }
        _;
    }
}