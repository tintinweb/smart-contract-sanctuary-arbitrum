/**
 *Submitted for verification at Arbiscan on 2023-04-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract SmolPool {

    address private poolController;


    uint256 private constant internalDecimals = 10**24;
    uint256 private constant BASE = 10**18;
    uint256 private _smolScalingFactor = BASE;
    uint256 private _underlyingSupply;
    uint256 private _totalSupply;

    mapping(address => uint256) private _smolBalances;

    modifier onlyPoolController() {
        require(msg.sender == poolController, "Must be called by the pool controller");
        _;
    }

    constructor(address _poolController) {
        poolController = _poolController;

    }

    function maxScalingFactor() external view returns (uint256) {
        return _maxScalingFactor();
    }

    function _maxScalingFactor() internal view returns (uint256) {
        return uint256(int256(-1)) / _underlyingSupply;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _smolToFragment(_smolBalances[account]);
    }

    function mint(address to, uint256 amount) public onlyPoolController {
        _totalSupply += amount;

        uint256 smolValue = _fragmentToSmol(amount);

        _underlyingSupply += smolValue;

        _smolBalances[to] += smolValue;
    }

    function burn(address from, uint256 amount) public onlyPoolController {
        _totalSupply -= amount;

        uint256 smolValue = _fragmentToSmol(amount);

        _underlyingSupply -= smolValue;

        _smolBalances[from] -= smolValue;
    }

      function divRound(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a + b / 2) / b;
    }

    function _smolToFragment(uint256 smol) internal view returns (uint256) {
        return divRound(smol * _smolScalingFactor, internalDecimals);
    }

    function _fragmentToSmol(uint256 fragment) internal view returns (uint256) {
        return divRound(fragment * internalDecimals, _smolScalingFactor);
    }

    function getScalingFactor() public view returns (uint256) {
        return _smolScalingFactor;
    }


    function rebase(uint256 indexDelta, bool positive) public onlyPoolController {

        uint256 oldSmolScalingFactor = _smolScalingFactor;

        if (!positive) {
            _smolScalingFactor = (_smolScalingFactor * (BASE - indexDelta)) / BASE;
        } else {
            uint256 newScalingFactor = (_smolScalingFactor * (BASE + indexDelta)) / BASE;

            if (newScalingFactor < _maxScalingFactor()) {
                _smolScalingFactor = newScalingFactor;
            } else {
                _smolScalingFactor = _maxScalingFactor();
            }
        }

        _totalSupply = _totalSupply * _smolScalingFactor / oldSmolScalingFactor;
    }

}