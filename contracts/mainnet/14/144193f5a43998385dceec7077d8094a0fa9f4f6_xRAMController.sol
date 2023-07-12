/**
 *Submitted for verification at Arbiscan on 2023-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface XWhitelist {
    function multisig() external view returns (address);

    function isOperator(address _user) external view returns (bool);

    function addWhitelist(address _user) external;

    function removeWhitelist(address _user) external;
}

interface IBaseVoter {
    function setXRamRatio(uint256 _xRamRatio) external;

    function setGaugeXRamRatio(
        address[] calldata _gauges,
        uint256[] calldata _xRamRatios
    ) external;

    function resetGaugeXRamRatio(address[] calldata _gauges) external;

    function whitelist(address _token) external;

    function forbid(address _token, bool _status) external;

    function gauges(address _pair) external view returns (address);

    function gaugeXRamRatio(address _gauge) external view returns (uint256);

    function xWhitelistOperator() external view returns (address);
}

contract xRAMController {
    mapping(address => bool) controllers;
    XWhitelist xWL = XWhitelist(0xe101e843a69fbE91717Ee169F187Fa89D1037Ae6);
    address public multisig = xWL.multisig();
    address public voter = 0xAAA2564DEb34763E3d05162ed3f5C2658691f499;
    IBaseVoter base = IBaseVoter(voter);

    modifier onlyMultisig() {
        require(
            msg.sender == multisig,
            "xRAMController: Only the multisig can call this function"
        );
        _;
    }

    modifier onlyController() {
        require(
            controllers[msg.sender],
            "xRAMController: Only a controller can call this function"
        );
        _;
    }

    constructor() {
        (controllers[multisig], controllers[msg.sender]) = (true, true);
    }

    //*********************************************************************** */

    /// @notice add a controller of this address
    function addController(address _newController) external onlyMultisig {
        controllers[_newController] = true;
    }

    /// @notice remove a controller of this address
    function removeController(address _oldController) external onlyMultisig {
        controllers[_oldController] = false;
    }

    /// @notice add an xRAM whitelist
    function whitelistAddress(address _whitelistee) external onlyController {
        xWL.addWhitelist(_whitelistee);
    }

    /// @notice remove an xRAM whitelist
    function removeWhitelistedAddress(
        address _whitelistee
    ) external onlyController {
        xWL.removeWhitelist(_whitelistee);
    }

    /// @notice whitelist xRAM addresses in batches
    function batchAddWhitelist(
        address[] calldata _whitelistees
    ) external onlyController {
        for (uint i = 0; i < _whitelistees.length; ++i) {
            xWL.addWhitelist(_whitelistees[i]);
        }
    }

    /// @notice remove xRAM whitelists in batches
    function batchRemoveWhitelist(
        address[] calldata _whitelistees
    ) external onlyController {
        for (uint i = 0; i < _whitelistees.length; ++i) {
            xWL.removeWhitelist(_whitelistees[i]);
        }
    }

    //*********************************************************************** */

    /// @notice sets the default xRamRatio
    function setDefaultRatio(uint256 _xRamRatio) external onlyController {
        base.setXRamRatio(_xRamRatio);
    }

    /// @notice sets the xRamRatio of specifics gauges
    function setGaugeRatios(
        address[] calldata _gauges,
        uint256[] calldata _xRamRatios
    ) external onlyController {
        base.setGaugeXRamRatio(_gauges, _xRamRatios);
    }

    /// @notice set gauge ratios using the pair address
    function setGaugeRatiosByPair(
        address[] memory _pairs,
        uint256[] calldata _xRamRatios
    ) external onlyController {
        for (uint256 i = 0; i < _pairs.length; ++i) {
            _pairs[i] = base.gauges(_pairs[i]);
        }
        base.setGaugeXRamRatio(_pairs, _xRamRatios);
    }

    /// @notice resets the xRamRatio of specifics gauges back to default
    function resetGaugeRatios(
        address[] calldata _gauges
    ) external onlyController {
        base.resetGaugeXRamRatio(_gauges);
    }

    /// @notice reset xRAM ratios back to default by pairs
    function resetRatiosByPair(
        address[] memory _pairs
    ) external onlyController {
        for (uint256 i = 0; i < _pairs.length; ++i) {
            _pairs[i] = base.gauges(_pairs[i]);
        }

        base.resetGaugeXRamRatio(_pairs);
    }

    /// @notice whitelists a token to be used in gauge creation
    function whitelistToken(address _token) external onlyController {
        base.whitelist(_token);
    }

    /// @notice forbids a non-supported token from creating a new gauge
    function forbidToken(address _token, bool _status) external onlyController {
        base.forbid(_token, _status);
    }

    //*********************************************************************** */

    /// @notice checks whether the address is a controller or not
    function isController(address _controller) external view returns (bool) {
        return controllers[_controller];
    }

    /// @notice checks to ensure this contract has the proper permissions to perform its tasks
    function isActive() public view returns (bool) {
        if (
            xWL.isOperator(address(this)) &&
            msg.sender == base.xWhitelistOperator()
        ) return true;
        return false;
    }

    /// @notice get the xRAM ratio for the gauge through the pair
    function getXRamRatioByPair(address _pair) external view returns (uint256) {
        return base.gaugeXRamRatio(base.gauges(_pair));
    }

    /// @notice get the xRAM ratio for the gauge
    function getXRamRatioByGauge(
        address _gauge
    ) external view returns (uint256) {
        return base.gaugeXRamRatio(_gauge);
    }
}