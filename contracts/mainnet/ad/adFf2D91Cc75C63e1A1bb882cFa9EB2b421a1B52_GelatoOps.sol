// SPDX-License-Identifier: UNLICENSED
//forked and minimize from https://github.com/gelatodigital/ops/blob/f6c45c81971c36e414afc31276481c47e202bdbf/contracts/integrations/OpsReady.sol
pragma solidity ^0.8.16;

interface IOpsProxyFactory {
    function getProxyOf(address account) external view returns (address, bool);
}

/**
 * @dev Inherit this contract to allow your smart contract to
 * - Make synchronous fee payments.
 * - Have call restrictions for functions to be automated.
 */
library GelatoOps {
    address private constant OPS_PROXY_FACTORY = 0xC815dB16D4be6ddf2685C201937905aBf338F5D7;

    function getDedicatedMsgSender(address msgSender) external view returns (address dedicatedMsgSender) {
        (dedicatedMsgSender, ) = IOpsProxyFactory(OPS_PROXY_FACTORY).getProxyOf(msgSender);
    }
}