// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

contract OptionStorage {

    event Save(
        uint256 optionId,
        address optionsContract,
        address user
    );

    function save(
        uint256 optionId,
        address optionsContractAddress,
        address user
    ) external {
        emit Save(optionId, optionsContractAddress, user);
    }
}