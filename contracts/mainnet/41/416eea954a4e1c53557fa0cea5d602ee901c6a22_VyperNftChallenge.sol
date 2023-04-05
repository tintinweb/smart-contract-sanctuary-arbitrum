// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ICyfrinSecurityChallengeContract} from "../interfaces/ICyfrinSecurityChallengeContract.sol";
import {ICyfrinSecurityChallenges} from "../interfaces/ICyfrinSecurityChallenges.sol";

error ACyfrinSecurityChallengeContract__AlreadySolved();
error ACyfrinSecurityChallengeContract__TransferFailed();

abstract contract ACyfrinSecurityChallengeContract is
    ICyfrinSecurityChallengeContract
{
    string private constant BLANK_TWITTER_HANLE = "";
    string private constant BLANK_SPECIAL_DESCRIPTION = "";
    ICyfrinSecurityChallenges internal immutable i_cyfrinSecurityChallenges;
    bool internal s_solved;
    string private s_twitterHandleOfSolver;

    modifier requireIsNotSolved() {
        if (s_solved) {
            revert ACyfrinSecurityChallengeContract__AlreadySolved();
        }
        _;
    }

    constructor(address cyfrinSecurityChallengesNft) {
        i_cyfrinSecurityChallenges = ICyfrinSecurityChallenges(
            cyfrinSecurityChallengesNft
        );
        s_solved = false;
    }

    /*
     * @param twitterHandleOfSolver - The twitter handle of the solver.
     * It can be left blank.
     */
    function _updateAndRewardSolver(
        string memory twitterHandleOfSolver
    ) internal requireIsNotSolved {
        s_solved = true;
        s_twitterHandleOfSolver = twitterHandleOfSolver;
        ICyfrinSecurityChallenges(i_cyfrinSecurityChallenges).mintNft(
            msg.sender
        );
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) {
            revert ACyfrinSecurityChallengeContract__TransferFailed();
        }
    }

    function _updateAndRewardSolver() internal {
        _updateAndRewardSolver(BLANK_TWITTER_HANLE);
    }

    function description() external view virtual returns (string memory);

    function specialImage() external view virtual returns (string memory) {
        return BLANK_SPECIAL_DESCRIPTION;
    }

    function isSolved() external view returns (bool) {
        return s_solved;
    }

    function getTwitterHandleOfSolver() external view returns (string memory) {
        return s_twitterHandleOfSolver;
    }

    // Gonna see if people MEV this shit...
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../abstractContracts/ACyfrinSecurityChallengeContract.sol";

error VyperNftChallenge__CallFailed();
error VyperNftChallenge__UserDoesntHaveNft();

interface IVyperNft {
    function hasNft(address) external view returns (bool);
}

contract VyperNftChallenge is ACyfrinSecurityChallengeContract {
    address public s_helper;

    constructor(
        address vyperHelper,
        address cscNft
    ) ACyfrinSecurityChallengeContract(cscNft) {
        s_helper = vyperHelper;
    }

    /*
     * @param selector - Hehe.
     * @param twitterHandle - Your twitter handle. Can be a blank string.
     */
    function solveChallenge(
        address yourContractAddress,
        bytes4 selector,
        string memory yourTwitterHandle
    ) public requireIsNotSolved {
        (bool success, ) = s_helper.call(
            abi.encodeWithSelector(selector, yourContractAddress, msg.sender)
        );
        if (!success) {
            revert VyperNftChallenge__CallFailed();
        }
        if (!IVyperNft(s_helper).hasNft(msg.sender)) {
            revert VyperNftChallenge__UserDoesntHaveNft();
        }
        _updateAndRewardSolver(yourTwitterHandle);
    }

    function description() external pure override returns (string memory) {
        return unicode"🐍🐍🐍🐍🐍🐍🐍🐍🐍🐍🐍🐍🐍";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ICyfrinSecurityChallengeContract {
    function description() external view returns (string memory);

    function specialImage() external view returns (string memory);

    /* Each contract must have a "solveChallenge" function, however, the signature
     * maybe be different in all cases because of different input parameters.
     * Because of this, we are not going to define the function here.
     *
     * This function should call back to the CyfrinSecurityChallenges contract
     * to mint the NFT.
     */
    // function solveChallenge() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ICyfrinSecurityChallenges {
    function mintNft(address receiver) external returns (uint256);

    function addChallenge(address challengeContract) external returns (uint256);
}