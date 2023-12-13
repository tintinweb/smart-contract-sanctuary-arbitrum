/**
 *Submitted for verification at Arbiscan.io on 2023-12-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract RewardManager {
    error NotEnoughFunds();

    address public immutable REWARD_TREASURY_ADDRESS;
    uint256 public immutable BASE_FEE;
    uint256 public immutable FEE_PER_EPOCH;
    uint256 public immutable PROTOCOL_FEE_PERCENTAGE; // scaled by 8

    mapping(uint256 => UserInstance) public idToUserInstance;
    mapping(address => bool) public baseFeePaid;
    uint256 public nonce;

    event NewUserInstance(uint256 indexed instanceId, uint256 numberOfEpochs);
    event CollectTrainingFees(
        uint256 indexed instanceId,
        uint256 numberOfEpochs
    );

    struct UserInstance {
        address[] clientAddress;
        uint256 numberOfEpochs;
    }

    /// @notice Constructor for RewardManager
    /// @param _rewardTreasuryAddress Address of reward treasury
    /// @param _baseFee Base fee
    /// @param _feePerEpoch Fee per epoch
    /// @param _protocolFeePercentage Percentage of fee to be sent to protocol
    constructor(
        address _rewardTreasuryAddress,
        uint256 _baseFee,
        uint256 _feePerEpoch,
        uint256 _protocolFeePercentage
    ) {
        REWARD_TREASURY_ADDRESS = _rewardTreasuryAddress;
        BASE_FEE = _baseFee;
        FEE_PER_EPOCH = _feePerEpoch;
        PROTOCOL_FEE_PERCENTAGE = _protocolFeePercentage;
    }

    /// @notice Function to pay base fee
    /// @dev This function is used to pay base fee
    function payBaseFee() external payable {
        if (msg.value < BASE_FEE) {
            revert NotEnoughFunds();
        }
        baseFeePaid[msg.sender] = true;
    }

    /// @notice Function to create new user instance
    /// @dev This function is used to create new user instance
    /// @param _clientAddress Address of client
    /// @param _numberOfEpochs Number of epochs for which client wants to train
    /// @return Instance id of user
    function newUserInstance(
        address[] calldata _clientAddress,
        uint256 _numberOfEpochs
    ) external returns (uint256) {
        uint256 _instanceId = uint256(
            keccak256(
                abi.encodePacked(
                    nonce,
                    _clientAddress,
                    _numberOfEpochs,
                    block.timestamp
                )
            )
        );
        idToUserInstance[_instanceId] = UserInstance(
            _clientAddress,
            _numberOfEpochs
        );
        nonce++;
        emit NewUserInstance(_instanceId, _numberOfEpochs);
        return _instanceId;
    }

    /// @notice Function to collect training fees
    /// @dev This function is used to collect training fees
    /// @param _instanceId Instance id of user
    function collectTrainingFees(uint256 _instanceId) external payable {
        uint256 _numberOfEpochs = idToUserInstance[_instanceId].numberOfEpochs;
        address[] memory _clientAddress = idToUserInstance[_instanceId]
            .clientAddress;
        uint256 trainingFee = _numberOfEpochs * FEE_PER_EPOCH;

        if (msg.value < trainingFee) {
            revert NotEnoughFunds();
        }

        uint256 protocolFee = (trainingFee * PROTOCOL_FEE_PERCENTAGE) / 1e8;

        uint256 balanceBeforeFeeDistribution = address(this).balance;
        uint256 clientFee = (trainingFee - protocolFee) / _clientAddress.length;
        for (uint256 i = 0; i < _clientAddress.length; i++) {
            (bool _success, ) = _clientAddress[i].call{value: clientFee}("");
            require(_success, "Transfer failed.");
        }
        uint256 balanceAfterFeeDistribution = address(this).balance;

        uint256 protocolFeeToTransfer = trainingFee -
            (balanceBeforeFeeDistribution - balanceAfterFeeDistribution);

        (bool success, ) = REWARD_TREASURY_ADDRESS.call{
            value: protocolFeeToTransfer
        }("");
        require(success, "Transfer failed.");
        emit CollectTrainingFees(_instanceId, _numberOfEpochs);
    }

    /// @notice Function to get reward treasury address
    /// @dev This function is used to get reward treasury address
    /// @return Address of reward treasury
    function getRewardTreasuryAddress() external view returns (address) {
        return REWARD_TREASURY_ADDRESS;
    }

    /// @notice Function to get fee per epoch
    /// @dev This function is used to get fee per epoch
    /// @return Fee per epoch
    function getFeePerEpoch() external view returns (uint256) {
        return FEE_PER_EPOCH;
    }

    /// @notice Function to get protocol fee percentage
    /// @dev This function is used to get protocol fee percentage
    /// @return Protocol fee percentage
    function getProtocolFeePercentage() external view returns (uint256) {
        return PROTOCOL_FEE_PERCENTAGE;
    }

    /// @notice Function to get user instance
    /// @dev This function is used to get user instance
    /// @param _instanceId Instance id of user
    /// @return clientAddress Address of client
    function getUserInstance(
        uint256 _instanceId
    ) external view returns (address[] memory, uint256) {
        return (
            idToUserInstance[_instanceId].clientAddress,
            idToUserInstance[_instanceId].numberOfEpochs
        );
    }
}