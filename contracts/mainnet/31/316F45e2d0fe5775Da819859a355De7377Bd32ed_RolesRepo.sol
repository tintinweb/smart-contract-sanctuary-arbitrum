// SPDX-License-Identifier: UNLICENSED

/* *
 * v0.2.4
 * Copyright (c) 2021-2024 LI LI @ JINGTIAN & GONGCHENG.
 * 
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.8;

library RolesRepo {

    struct Role {
        address admin;
        mapping(address => bool) isMember;
    }

    struct Repo {
        mapping(bytes32 => Role) roles;
    }

    // ##################
    // ##    Modifier  ##
    // ##################

    modifier onlyAdmin(
        Repo storage repo, 
        bytes32 role, 
        address caller
    ) {
        require(repo.roles[role].admin == caller, 
            "RR.onlyAdmin: not admin");
        _;
    }

    // #################
    // ##    Write    ##
    // #################

    function setRoleAdmin(
        Repo storage repo,
        bytes32 role,
        address acct
    ) public {
        repo.roles[role].admin = acct;
        repo.roles[role].isMember[acct] = true;
    }

    function quitRoleAdmin(
        Repo storage repo,
        bytes32 role,
        address caller
    ) public onlyAdmin(repo, role, caller) {
        delete repo.roles[role].admin;
        delete repo.roles[role].isMember[caller];
    }
    
    function grantRole(
        Repo storage repo,
        bytes32 role,
        address acct,
        address caller
    ) public onlyAdmin(repo, role, caller) {
        repo.roles[role].isMember[acct] = true;
    }

    function revokeRole(
        Repo storage repo,
        bytes32 role,
        address acct,
        address caller
    ) public onlyAdmin(repo, role, caller) {
        delete repo.roles[role].isMember[acct];
    }

    function renounceRole(
        Repo storage repo,
        bytes32 role,
        address caller
    ) public {
        delete repo.roles[role].isMember[caller];
    }

    function abandonRole(
        Repo storage repo,
        bytes32 role
    ) public {
        delete repo.roles[role];
    }

    // ###############
    // ##   Read    ##
    // ###############

    function getRoleAdmin(Repo storage repo, bytes32 role)
        public view returns (address)
    {
        return repo.roles[role].admin;
    }

    function hasRole(
        Repo storage repo,
        bytes32 role,
        address acct
    ) public view returns (bool) {
        return repo.roles[role].isMember[acct];
    }
}