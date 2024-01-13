/**
 *Submitted for verification at Arbiscan.io on 2024-01-11
*/

// SPDX-License-Identifier: 0BSD
pragma solidity 0.8.23;

struct Config {
    address server;
    uint32[] selectors;
}

contract SetServers {
    function setServers(Config[] calldata configs) external {
        require(msg.sender == 0xfbA2A57A48Dd647511D1dAe8FbC4572560359088);
        for (uint i = 0; i < configs.length; i++) {
            Config calldata config = configs[i];
            address server = config.server;
            uint32[] calldata selectors = config.selectors;
            for (uint j = 0; j < selectors.length; j++) {
                uint32 selector = selectors[j]; // selector is equal to slot
                assembly { sstore(selector, server) } 
            }
        }
    }
}