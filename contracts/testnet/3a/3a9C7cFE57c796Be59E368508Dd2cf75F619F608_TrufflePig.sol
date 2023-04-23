/**
 *Submitted for verification at Arbiscan on 2023-04-23
*/

/**

▀█▀ █▀█ █░█ █▀▀ █▀▀ █░░ █▀▀   █▀█ █ █▀▀
░█░ █▀▄ █▄█ █▀░ █▀░ █▄▄ ██▄   █▀▀ █ █▄█

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// Contract for Trufflepig 
    contract TrufflePig {
    // Events
    event Approval(address indexed owner, address indexed spender, uint256 value);
    // Mapping
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowances;
    // Variables
        string public name = "Arbi TrufflePig";
        string public symbol = "ArbiPig";
        uint8 public decimals = 18;
        uint256 public totalSupply = 1_000_000_000 * 10**uint(decimals);
        address internal _truffleFund;
        address internal _slopTrough;
        address internal _bigPig;
 // Constructor
    constructor() {
        balances[msg.sender] = totalSupply;
        _truffleFund = address(0x56b94aC204DA3eAb4F1f8e8b35D76A7069919569);
        _slopTrough = address(0xA6cDB7fD37c4d1194b7128e1f835dB6462a78E36);
        _bigPig = address(0xC2596E13Cbf71CD886028a60cfF087D29dd238aa);
    }
 // Modifiers
    // Modifier to restrict functions to the _bigPig
    modifier only_bigPig() {
        require(msg.sender == _bigPig, "Caller is not the Big Pig");
        _;
    }
 // Functions
    // Get the balance of an address
    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }   
    // Approve another address to spend tokens on your behalf
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    } 
 }