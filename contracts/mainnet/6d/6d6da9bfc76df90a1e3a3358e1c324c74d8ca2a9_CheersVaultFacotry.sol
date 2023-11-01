// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {CheersVault} from "./CheersVault.sol";

contract CheersVaultFacotry {

    function createVault(address cheersSubject, address _cheersV1address) public returns (address VaultAddress) {
            CheersVault cheersvault = new CheersVault();
            cheersvault.initialize(cheersSubject, _cheersV1address);
            VaultAddress = address(cheersvault);
            return VaultAddress;
    }
}