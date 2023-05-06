/**
 *Submitted for verification at Arbiscan on 2023-05-06
*/

// SPDX-License-Identifier: MIT
 /* Synthetix (SNX) is a 100% AI-created token deployed on the Arbitrum blockchain. 
 * The maximum supply of the token is 100 billion, and the commission for buying is 0%, 
 * the commission for selling is 0.5%, and the wallet address for the commission is 0x5e9E8658D74CBA825BD18BF483dCeE96C0FE1aBC 
 * (this commission will be used for advertising expenses). Token transfer is prohibited for 10 minutes after receiving 
 * (to prevent sandwich attacks from bot traders).
 * 
 * The name Synthetix was suggested and the code was written by ChatGPT. 
 * 
 * For more information about Synthetix, please visit our website at www.synthetixarb.com.
 * You can also follow us on Twitter at @Synthetix_arb for the latest updates and announcements.
 */
pragma solidity ^0.8.0;

contract Synthetix {
    string public constant name = "Synthetix";
    string public constant symbol = "SNX";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 100000000000 * 10 ** decimals;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public constant commissionWallet = 0x5e9E8658D74CBA825BD18BF483dCeE96C0FE1aBC;
    uint256 public constant commissionRateForSell = 5; // 0.5%

    mapping(address => uint256) public lastTransferTime;
    uint256 public constant transferLockDuration = 10 minutes;

    bool public ownershipRenounced;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);

    modifier onlyBeforeOwnershipRenounced() {
        require(!ownershipRenounced, "Ownership has already been renounced.");
        _;
    }

    constructor() {
        balanceOf[msg.sender] = totalSupply;

        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(lastTransferTime[msg.sender] + transferLockDuration <= block.timestamp, "Transfer is locked for a short period of time after receiving.");
        require(_value <= balanceOf[msg.sender], "Insufficient balance.");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        lastTransferTime[_to] = block.timestamp;

        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(lastTransferTime[_from] + transferLockDuration <= block.timestamp, "Transfer is locked for a short period of time after receiving.");
        require(_value <= balanceOf[_from], "Insufficient balance.");
        require(_value <= allowance[_from][msg.sender], "Insufficient allowance.");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        lastTransferTime[_to] = block.timestamp;

        return true;
    }

    function sell(uint256 _value) external returns (bool success) {
        require(_value <= balanceOf[msg.sender], "Insufficient balance.");

        uint256 commission = _value * commissionRateForSell / 100;
        balanceOf[commissionWallet] += commission;

        balanceOf[msg.sender] -= _value;
        balanceOf[commissionWallet] -= commission;

        emit Transfer(msg.sender, address(0), _value);

        return true;
    }

    function renounceOwnership() external onlyBeforeOwnershipRenounced() {
        ownershipRenounced = true;

        emit OwnershipRenounced(msg.sender);
    }
}