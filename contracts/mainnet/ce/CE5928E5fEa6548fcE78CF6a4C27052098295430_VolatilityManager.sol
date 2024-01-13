// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISettingsManager {
    function setVolatilityFactor(uint256 _tokenId, uint256 _volatilityFactor) external;

    function lastFundingTimes(uint256 _tokenId) external view returns (uint256);

    function updateFunding(uint256 _tokenId) external;
}

contract VolatilityManager {
    ISettingsManager public immutable settingsManager;

    mapping(address => bool) public isAdmin;

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "!admin");
        _;
    }

    constructor(address _settingsManager) {
        settingsManager = ISettingsManager(_settingsManager);

        isAdmin[msg.sender] = true;
    }

    function setAdmin(address _account, bool _isAdmin) external onlyAdmin {
        isAdmin[_account] = _isAdmin;
    }

    function setVolatilityFactors(
        uint256[] calldata assetIds,
        uint256[] calldata volatilityFactors
    ) external onlyAdmin {
        uint256 length = assetIds.length;
        require(length == volatilityFactors.length, "!length");

        for (uint256 i; i < length; ++i) {
            settingsManager.setVolatilityFactor(assetIds[i], volatilityFactors[i]);
        }
    }

    function getLastFundingTimes(
        uint256[] calldata assetIds
    ) external view returns (uint256[] memory lastFundingTimes) {
        uint256 length = assetIds.length;
        lastFundingTimes = new uint256[](length);

        for (uint256 i; i < length; ++i) {
            lastFundingTimes[i] = settingsManager.lastFundingTimes(assetIds[i]);
        }
    }

    function updateFundings(uint256[] calldata assetIds) external {
        uint256 length = assetIds.length;

        for (uint256 i; i < length; ++i) {
            settingsManager.updateFunding(assetIds[i]);
        }
    }
}