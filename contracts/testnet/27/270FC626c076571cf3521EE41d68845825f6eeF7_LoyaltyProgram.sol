// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

contract LoyaltyProgram {
    event Save(uint256 optionId, string assetPair, address options_contract);

    function save(
        uint256 optionId,
        string memory assetPair,
        address options_contract
    ) external {
        // do nothing
        emit Save(optionId, assetPair, options_contract);
    }
}