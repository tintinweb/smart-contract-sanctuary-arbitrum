/**
 *Submitted for verification at Arbiscan.io on 2024-05-03
*/

// SPDX-License-Identifier: Apache 2.0

/*

 Copyright 2022-2023 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity 0.8.19;

interface IToken {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);

    function balanceOf(address _who) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
}

/// @title Airdrop Helper - Facilitates sending ERC20 tokens to multiple users.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
contract HSendBatchTokens {
    
    /*
     * CORE FUNCTIONS
     */
    /// @dev Allows transferring an ERC20 standard token with 18 decimals to a batch of accounts.
    /// @param token Instance of address of the target token.
    /// @param targets Array of target addresses.
    function sendBatchTokens(
        IToken token,
        uint256 tokenAmount,
        address[] calldata targets
    )
        external
    {
        uint256 length = targets.length;
        assert(
            token.transferFrom(
                msg.sender,
                address(this),
                (tokenAmount * length)
            )
        );
        for (uint256 i = 0; i < length; i++) {
            token.transfer(
                targets[i],
                tokenAmount
            );
        }
    }
}