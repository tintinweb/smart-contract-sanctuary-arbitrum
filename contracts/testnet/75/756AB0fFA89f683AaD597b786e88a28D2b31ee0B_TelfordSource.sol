//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TelfordSource {
    // this contract will be deployed to Arbitrum
    address payable private bonderAddress;
    address private l1Relayer;

    address private owner;

    uint256 constant BONDER_FEE = 0.2 ether;

    struct BridgeInfo {
        address userAddress;
        address bonderAddress;
        uint256 bridgeAmount;
        uint256 bonderPayment;
    }

    mapping(uint => BridgeInfo) private bridgeRequests;

    event BridgeRequested(
        address userAddress,
        uint256 amount,
        uint256 transferId
    );
    event BonderReimbursed(uint256 bonderPayment);

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Sorry pal, I can only be called by the contract owner!"
        );
        _;
    }

    modifier onlyL1Relayer() {
        require(
            msg.sender == l1Relayer,
            "Sorry pal, I can only be called by the L1Relayer!"
        );
        _;
    }

    constructor(address _bonderAddress, address _l1RelayerAddress) {
        owner = msg.sender;
        bonderAddress = payable(_bonderAddress);
        l1Relayer = _l1RelayerAddress;
    }

    function bridge(uint256 _transferId) external payable {
        require(
            msg.value > BONDER_FEE,
            "Ether sent must be greater than the bonder fee!"
        );

        uint256 bonderPayment = msg.value;
        uint256 bridgeAmount = bonderPayment - BONDER_FEE;

        bridgeRequests[_transferId] = BridgeInfo({
            userAddress: msg.sender,
            bonderAddress: bonderAddress,
            bridgeAmount: bridgeAmount,
            bonderPayment: bonderPayment
        });

        emit BridgeRequested(msg.sender, bridgeAmount, _transferId);
    }

    function fundsReceivedOnDestination(
        uint256 _transferId,
        uint256 _bridgeAmount
    ) external onlyL1Relayer {
        require(
            bridgeRequests[_transferId].bridgeAmount == _bridgeAmount,
            "UH OH! The transferId and bridgeAmount dont match!"
        );

        uint256 bonderPayment = bridgeRequests[_transferId].bonderPayment;

        (bool sent, ) = bridgeRequests[_transferId].bonderAddress.call{
            value: bonderPayment
        }("");
        require(sent, "Failed to send Ether to bonder");

        emit BonderReimbursed(bonderPayment);
    }

    function setBonder(address _bonder) external onlyOwner {
        bonderAddress = payable(_bonder);
    }

    function setL1Relayer(address _l1Relayer) external onlyOwner {
        l1Relayer = _l1Relayer;
    }
}