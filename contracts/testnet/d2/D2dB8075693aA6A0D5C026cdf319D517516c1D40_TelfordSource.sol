//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TelfordSource {
    // this contract will be deployed to Arbitrum
    address payable private bonderAddress;
    address private l1Relayer;
    uint256 private bonderPayment;
    uint256 private bridgeAmount;

    uint256 constant BONDER_FEE = 0.2 ether;

    event BridgeRequested(address indexed userAddress, uint256 indexed amount);
    event BonderReimbursed(uint256 indexed bonderPayment);

    modifier onlyL1Relayer() {
        require(
            msg.sender == l1Relayer,
            "Sorry pal, I can only be called by the L1Relayer!"
        );
        _;
    }

    constructor(address _bonderAddress, address _l1RelayerAddress) {
        bonderAddress = payable(_bonderAddress);
        l1Relayer = _l1RelayerAddress;
    }

    function bridge() external payable {
        require(
            msg.value > BONDER_FEE,
            "Ether sent must be greater than the bonder fee!"
        );

        bonderPayment = msg.value;
        bridgeAmount = bonderPayment - BONDER_FEE;

        emit BridgeRequested(msg.sender, bridgeAmount);
    }

    function fundsReceivedOnDestination() external onlyL1Relayer {
        (bool sent, ) = bonderAddress.call{value: bonderPayment}("");
        require(sent, "Failed to send Ether to bonder");

        emit BonderReimbursed(bonderPayment);
    }
}