/**
 *Submitted for verification at Arbiscan on 2023-07-31
*/

// SPDX-License-Identifier: MIT                                                                               
                                                    
pragma solidity 0.8.9;
interface IVRFProvider {
    function getPrice() external view returns(uint256);
    function getOperatorWallet() external view returns(address);
    function requestUint() external payable returns(uint256);
}

contract DiceRoll {

    IVRFProvider public provider; // VRF provider
    mapping(uint256 => uint256) public result;
    mapping(uint256 => bool) public pending;
    uint256 public lastID;

    constructor(address _provider) {
        provider = IVRFProvider(_provider);
    }

    modifier onlyProvider {
        require(msg.sender == address(provider), "Only the provider can call this.");
        _;
    }

    function roll() public payable returns(uint256){
        lastID = provider.requestUint();

        pending[lastID] = true;

        return lastID;
    }

    function callback(uint256 id, uint256 randNum) external onlyProvider returns(uint256) {
        result[id] = randNum % 6 + 1;
        return result[id];
    }
}