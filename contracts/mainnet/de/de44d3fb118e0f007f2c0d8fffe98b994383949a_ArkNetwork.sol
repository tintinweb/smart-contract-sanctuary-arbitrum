/**
 *Submitted for verification at Arbiscan on 2022-07-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Ark Network
/// @author charmful0x
/// @notice this contract is only for testing purpose
/// @dev link an EVM address to an Arweave address. The
///      contract is deterministic, but as part of Ark Network,
///      it becomes non-deterministic where the result
///      depends on the other SmartWeave contracts states.

contract ArkNetwork {
    uint256 constant ARWEAVE_ADDRESS_STRING_LENGTH = 43;
    address public owner;
    string public network;
    bool public pausedContract;

    modifier checkArAddrLen(string calldata _arweave_address) {
        require(bytes(_arweave_address).length == ARWEAVE_ADDRESS_STRING_LENGTH, "invalid Arweave address");
        _;
    }

    modifier isOwner() {
        require(msg.sender == owner, "invalid caller");
        _;
    }

    modifier contractNotPaused() {
        require(pausedContract == false, "contract paused");
        _;
    }

    event LinkIdentity(
        address indexed evmAddress,
        string indexed arweaveAddress,
        string arAddress
    );

    event PauseState(
    bool isPaused
    );

    event LaunchContract(
    string network
    );

    constructor(string memory _network, bool _pausedContract) {
        /**
         * @dev contract's initialization
         * @param _network network's name. This contract is EVMs compatible
         * @param _pausedContract initial contract's pause state. Assigned to False
        **/
        require(bytes(_network).length > 0, "network name too short");
        owner = msg.sender;
        network = _network;
        pausedContract = _pausedContract;

        emit LaunchContract(_network);
    }

    function linkIdentity(string calldata _arweave_address) checkArAddrLen(_arweave_address) contractNotPaused external {
        /**
         * @dev link an Arweave address to the caller's address (msg.sender)
         * @param _arweave_address base64url 43 char string
        **/
        emit LinkIdentity(msg.sender, _arweave_address, _arweave_address);
    }

    function reversePauseState(bool _pause) isOwner public {
        /**
         * @dev admin function to pause/unpause the contract
         * @param _pause True to pause the contract & vice-versa
        **/
        pausedContract = _pause;
        emit PauseState(_pause);
    }
}