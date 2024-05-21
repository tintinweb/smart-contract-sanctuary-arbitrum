// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.23;

import {VRFConsumerBaseV2Plus} from "chainlink/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "chainlink/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import "chainlink/src/v0.8/automation/AutomationCompatible.sol";

/**
 * @title Random.win Main Smart Contract
 * @author Borr Technologies SAS, a registered French company
 *
 * @notice This contract is the main contract for Random.win RNG ( https://www.random.win )
 * 
 */
contract Main is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {

    /*** Errors ***/

    error TooManyWinners(uint32 nbWinners);
    error UnknownAlgorithm(uint8 algorithm);
    error DrawAlreadyExists(string cid);
    error DrawDoesNotExist(string cid);
    error DrawTooEarly(string cid);
    error RequestAlreadyPending(string cid);
    error DrawAlreadyCompleted(string cid);
    error RequestDoesNotExist(uint256 id);
    error RequestAlreadyFulfilled(uint256 id);
    error RandomnessFulfilledButEmpty(uint256 id);


    /*** Events ***/

    event DrawDeployed(string cid);
    event DrawDeployedBatch(string[] cids);
    event RandomnessRequested(
        uint256 requestId,
        string cid,
        uint32 numWords,
        bytes32 keyHash,
        uint256 s_subscriptionId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit
    );
    event RandomnessFulfilled(uint256 requestId, uint256[] randomWords);
    event DrawCompleted(string indexed cid);


    /*** Draws ***/

    struct Draw {
        address owner; // account who deployed the draw, i.e. the draw organizer
        uint64 publishedAt; // timestamp at which the draw was published on the contract
        uint64 scheduledAt; // timestamp at which the draw should be triggered
        uint64 occuredAt; // timestamp at which the draw has occurred
        uint32 nbParticipants; // number of participants
        uint32 nbWinners; // number of winners to select for this draw
        uint32 entropyNeeded; // number of bytes of information needed to compute winners
        bytes entropy; // entropy used to pick winners
        bool entropyPending; // when the random numbers are being generated
        bool completed; // when the draw is done and entropy as been filled
        uint8 algorithm; // algorithm to use to compute the winners from the entropy
        address callbackAddress; // contract implementing the CallbackContract interface (use "0x0" if none)
    }   
   
    uint32 public drawCount = 0;
    mapping(uint32 => string) public cids; // Draw index => Draw CID
    mapping(string => Draw) public draws; // Draw CID => Draw object
    string[] public queue; // Draws scheduled for later
    uint32 public maxWinners;
    
    uint32 private entropyNeededPerWinner = 8; // Retrieving 8 bytes (64 bits) of entropy for each winner is enough to have an infinitely small scaling bias


    /*** Requests ***/

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256 createdAt; // block timestamp
        uint256[] randomWords;
        string cid;
    }

    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */


    /*** VRF ***/
    uint256 private s_subscriptionId;
    address private link_token_contract;
    bytes32 private keyHash;
    uint32 private callbackGasLimit;
    uint16 private requestConfirmations;

    // Maximum number of words that can be received with fulfillRandomWords before reaching the gas limit
    uint32 private MAX_NUM_WORDS;

    AccountsContract private accounts;


    constructor (
        address accountsContractAddress,
        uint256 subscriptionId,
        uint32 _maxWinners,
        address _link_token_contract,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _maxNumWords
    )
        VRFConsumerBaseV2Plus(_link_token_contract)
    {
        accounts = AccountsContract(accountsContractAddress);
        s_subscriptionId = subscriptionId;
        maxWinners = _maxWinners;
        link_token_contract = _link_token_contract;
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        MAX_NUM_WORDS = _maxNumWords;
    }


    function deployDraw(
        address owner,
        string memory cid,
        uint64 scheduledAt,
        uint32 nbParticipants,
        uint32 nbWinners,
        uint8 algorithm,
        address callbackAddress
    )
        external
        onlyOwner
        returns (string memory)
    {
        createDraw(owner, cid, scheduledAt, nbParticipants, nbWinners, algorithm, callbackAddress);
        return cid;       
    }


    function deployDraw(
        uint32 numbers,
        uint32 range,
        uint8 algorithm,
        uint64 scheduledAt
    )
        external
        returns (string memory)
    {
        string memory cid = bytesToHex(abi.encodePacked(keccak256(abi.encodePacked(numbers, range, algorithm, scheduledAt, drawCount, block.number))));
        createDraw(msg.sender, cid, scheduledAt, range, numbers, algorithm, address(0));
        return cid;      
    }

    function deployDraw(
        uint64 scheduledAt,
        uint32 nbParticipants,
        uint32 nbWinners,
        uint8 algorithm,
        address callbackAddress
    )
        external
        returns (string memory)
    {
        string memory cid = bytesToHex(abi.encodePacked(keccak256(abi.encodePacked(scheduledAt, nbParticipants, nbWinners, algorithm, callbackAddress, drawCount, block.number))));
        createDraw(msg.sender, cid, scheduledAt, nbParticipants, nbWinners, algorithm, callbackAddress);
        return cid;      
    }


    function createDraw(
        address _owner,
        string memory cid,
        uint64 scheduledAt,
        uint32 nbParticipants,
        uint32 nbWinners,
        uint8 algorithm,
        address callbackAddress
    )
        private
    {

        if (draws[cid].publishedAt != 0) {
            revert DrawAlreadyExists(cid);
        }

        if (nbWinners > maxWinners || (algorithm == 2 && nbWinners > 100)) {
            revert TooManyWinners(nbWinners);
        }

        if (algorithm > 2) {
            revert UnknownAlgorithm(algorithm);
        }

        accounts.pay(_owner);

        uint64 publishedAt = uint64(block.timestamp);
        uint64 occuredAt = 0;
        bytes memory entropy = "";
        uint32 entropyNeeded = nbWinners * entropyNeededPerWinner;
        draws[cid] = Draw(_owner, publishedAt, scheduledAt, occuredAt, nbParticipants, nbWinners, entropyNeeded, entropy, false, false, algorithm, callbackAddress);
        drawCount++;
        cids[drawCount] = cid;

        emit DrawDeployed(cid);

        if (block.timestamp >= scheduledAt) {
            string[] memory _cids = new string[](1);
            _cids[0] = cid;
            generateEntropyFor(_cids);
        } else {
            queue.push(cid);
        }
    }


    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = false;
        bool[] memory isReady = new bool[](queue.length);
        uint32 count = 0;

        for (uint64 i = 0; i < queue.length; i++) {

            string memory cid = queue[i];

            // Conditions needed in order to trigger a draw
            if (draws[cid].publishedAt > 0 && block.timestamp >= draws[cid].scheduledAt && !draws[cid].entropyPending && !draws[cid].completed) {
                upkeepNeeded = true;
                isReady[i] = true;
                count++;
            }
        }

        if (upkeepNeeded) {
            uint32 j = 0;
            uint32[] memory queueIdx = new uint32[](count);
            for (uint32 i = 0; i < isReady.length; i++) {
                if (isReady[i]) {
                    queueIdx[j] = i;
                    j++;
                }
            }
            performData = abi.encode(queueIdx);
        }

        return (upkeepNeeded, performData);
    }


    function performUpkeep(
        bytes calldata performData
    )
        external
        override
    {
        uint32[] memory queueIdx = abi.decode(performData, (uint32[]));
        string[] memory _cids = new string[](queueIdx.length);

        // We revalidate the draws in the performUpkeep to prevent malicious actors
        // from calling performUpkeep with wrong parameters 
        for (uint64 i = 0; i < queueIdx.length; i++) {

            string memory cid = queue[queueIdx[i]];
            _cids[i] = cid;
            
            if (draws[cid].publishedAt == 0) {
                revert DrawDoesNotExist(cid);
            }

            if (block.timestamp < draws[cid].scheduledAt) {
                revert DrawTooEarly(cid);
            }

            if (draws[cid].entropyPending) {
                revert RequestAlreadyPending(cid);
            }

            if (draws[cid].completed) {
                revert DrawAlreadyCompleted(cid);
            }

            draws[cid].entropyPending = true;
        }

        removeIndexesFromArray(queue, queueIdx);
        generateEntropyFor(_cids);
    }

    function generateEntropyFor(string[] memory _cids)
        private
    {

        for (uint32 i = 0; i < _cids.length; i++) {

            string memory cid = _cids[i];
            uint32 entropyNeeded = draws[cid].entropyNeeded - uint32(draws[cid].entropy.length);

            // Each word gives an entropy of 32 bytes
            uint32 numWordsNeeded = divisionRoundUp(entropyNeeded, 32);
            
            while (numWordsNeeded > 0) {

                uint32 numWords = numWordsNeeded;

                if (numWords > MAX_NUM_WORDS) {
                    numWords = MAX_NUM_WORDS;
                }

                uint256 requestId = s_vrfCoordinator.requestRandomWords(
                    VRFV2PlusClient.RandomWordsRequest({
                        keyHash: keyHash,
                        subId: s_subscriptionId,
                        requestConfirmations: requestConfirmations,
                        callbackGasLimit: callbackGasLimit,
                        numWords: numWords,
                        extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
                    })
                );


                s_requests[requestId] = RequestStatus({
                    randomWords: new uint256[](0),
                    cid: cid,
                    fulfilled: false,
                    createdAt: block.timestamp
                });

                emit RandomnessRequested(
                    requestId,
                    cid,
                    numWords,
                    keyHash,
                    s_subscriptionId,
                    requestConfirmations,
                    callbackGasLimit
                );

                numWordsNeeded -= numWords;
            }

        }
 
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        RequestStatus memory request = s_requests[_requestId];
        string memory cid = request.cid;

        if (request.createdAt == 0) {
            revert RequestDoesNotExist(_requestId);
        }

        if (request.fulfilled) {
            revert RequestAlreadyFulfilled(_requestId);
        }

        if (_randomWords.length == 0) {
            revert RandomnessFulfilledButEmpty(_requestId);
        }

        if (draws[cid].completed) {
            revert DrawAlreadyCompleted(cid);
        }

        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RandomnessFulfilled(_requestId, _randomWords);

        bytes memory totalEntropy = abi.encodePacked(_randomWords);
        uint32 entropyNeeded = draws[cid].entropyNeeded - uint32(draws[cid].entropy.length);

        if (entropyNeeded > totalEntropy.length) {
            entropyNeeded = uint32(totalEntropy.length);
        }

        bytes memory newEntropy = extractBytes(totalEntropy, entropyNeeded);

        draws[cid].entropy = bytes.concat(draws[cid].entropy, newEntropy);

        if (draws[cid].entropy.length == draws[cid].entropyNeeded) {
            draws[cid].occuredAt = uint64(block.timestamp);
            draws[cid].entropyPending = false;
            draws[cid].completed = true;
            emit DrawCompleted(cid);

            if (draws[cid].callbackAddress != address(0)) {
                CallbackContract(draws[cid].callbackAddress).fulfillDrawWinners(cid);
            }
        }
    }


    /*** Getters ***/

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {

        RequestStatus memory request = s_requests[_requestId];

        if (request.createdAt == 0) {
            revert RequestDoesNotExist(_requestId);
        }

        return (request.fulfilled, request.randomWords);
    }

    function checkDrawWinners(string memory draw_identifier) external view returns (uint32[] memory) {

        require(draws[draw_identifier].completed, "This random draw has not occured yet. Come back later.");

        bytes memory totalEntropy = draws[draw_identifier].entropy;
        uint32 nbParticipants = draws[draw_identifier].nbParticipants;
        uint32 nbWinners = draws[draw_identifier].nbWinners;
        uint8 algorithm = draws[draw_identifier].algorithm;

        if (algorithm == 0) {
            return algorithmOrderedOutcomes(totalEntropy, nbParticipants, nbWinners);
        } else if (algorithm == 1) {
            return algorithmFisherYatesOptimized(totalEntropy, nbParticipants, nbWinners);
        } else if (algorithm == 2) {
            return algorithmFisherYatesOriginal(totalEntropy, nbParticipants, nbWinners);
        } else {
            revert UnknownAlgorithm(algorithm);
        }

    }

    function algorithmOrderedOutcomes(bytes memory totalEntropy, uint32 nbParticipants, uint32 nbWinners) private view returns (uint32[] memory) {
        uint32[] memory winnerIndexes = new uint32[](nbWinners); // Fixed sized array, all elements initialize to 0
        uint32 from = 0;

        for (uint32 i = 0; i < nbWinners; i++) {

            bytes8 extractedEntropy = extractBytes8(totalEntropy, from);
            from += entropyNeededPerWinner;

            // When i winners are already selected, we only need a random number between 0 and nbParticipants - i - 1 to select the next winner.
            // ⚠️ Using 64-bit integers for the modulo operation is extremely important to prevent scaling bias ⚠️
            // Then it is fine to convert the result to a 32-bit integer because we know that the output of the modulo will always be stricly less than nbParticipants which is a 32-bit integer
            uint32 randomNumber = uint32(uint64(extractedEntropy) % uint64(nbParticipants - i));
            uint32 nextWinner = randomNumber + 1; // We increment to convert the index to a line number
            uint32 j = 0;
            
            for (j = 0; j < i; j++) {
                if (winnerIndexes[j] <= nextWinner) {
                    nextWinner++;
                } else {
                    break;
                }
            }
            
            for (uint32 k = i; k > j; k--) {
                winnerIndexes[k] = winnerIndexes[k-1];
            }

            winnerIndexes[j] = nextWinner;
        }

        return winnerIndexes;
    }

    function algorithmFisherYatesOptimized(bytes memory totalEntropy, uint32 nbParticipants, uint32 nbWinners) private view returns (uint32[] memory) {
        uint32[] memory winnerIndexes = new uint32[](nbWinners); // Fixed sized array, all elements initialize to 0
        uint32 from = 0;
        uint32[] memory swapMap = new uint32[](nbParticipants);

        for (uint32 i = 0; i < nbWinners; i++) {
            bytes8 extractedEntropy = extractBytes8(totalEntropy, from);
            from += entropyNeededPerWinner;

            // When i winners are already selected, we only need a random number between 0 and nbParticipants - i - 1 to select the next winner.
            // ⚠️ Using 64-bit integers for the modulo operation is extremely important to prevent scaling bias ⚠️
            // Then it is fine to convert the result to a 32-bit integer because we know that the output of the modulo will always be stricly less than nbParticipants which is a 32-bit integer
            uint32 randomNumber = uint32(uint64(extractedEntropy) % uint64(nbParticipants - i));

            winnerIndexes[i] = (swapMap[randomNumber] != 0) ? swapMap[randomNumber] : randomNumber;
            swapMap[randomNumber] = nbParticipants - i - 1;
        }

        // We want to display line numbers, not indexes, so all indexes need to be +1
        for (uint32 i = 0; i < nbWinners; i++) {
            winnerIndexes[i] += 1;
        }

        return winnerIndexes;
    }

    function algorithmFisherYatesOriginal(bytes memory totalEntropy, uint32 nbParticipants, uint32 nbWinners) private view returns (uint32[] memory) {
        uint32[] memory winnerIndexes = new uint32[](nbWinners); // Fixed sized array, all elements initialize to 0
        uint32 from = 0;

        for (uint32 i = 0; i < nbWinners; i++) {
            bytes8 extractedEntropy = extractBytes8(totalEntropy, from);
            from += entropyNeededPerWinner;

            // When i winners are already selected, we only need a random number between 0 and nbParticipants - i - 1 to select the next winner.
            // ⚠️ Using 64-bit integers for the modulo operation is extremely important to prevent scaling bias ⚠️
            // Then it is fine to convert the result to a 32-bit integer because we know that the output of the modulo will always be stricly less than nbParticipants which is a 32-bit integer
            uint32 randomNumber = uint32(uint64(extractedEntropy) % uint64(nbParticipants - i));
            uint32 nextWinningIndex = randomNumber;
            uint32 min = 0;

            // Once a participant has been selected as a winner, it can never be selected again for that draw.
            // We enforce that by looping over all participants and ignoring those who are already known winners.
            // The offset variable keeps track of how many participants are ignored as we loop through the list and increments the next winning index accordingly.
            // When there is no more participants to ignore (offset == 0), it means we have reached the proper winning index so we break the loop and save this index.
            while (true) {
                uint32 offset = nbValuesBetween(winnerIndexes, min, nextWinningIndex, i);
                if (offset == 0) {
                    break;
                }
                min = nextWinningIndex + 1;
                nextWinningIndex += offset;
            }

            winnerIndexes[i] = nextWinningIndex;
        }

        // We want to display line numbers, not indexes, so all indexes need to be +1
        for (uint32 i = 0; i < nbWinners; i++) {
            winnerIndexes[i] += 1;
        }

        return winnerIndexes;
    }


    /*** Setters ***/

    function setSubscription(uint256 subscriptionId) external onlyOwner {
        s_subscriptionId = subscriptionId;
    }

    function setAccountsContract(address accountsContractAddress) external onlyOwner {
        accounts = AccountsContract(accountsContractAddress);
    }


    /*** Payment ***/

    function withdraw(uint256 amount, address _recipient) external onlyOwner {
        uint256 ethBalance = address(this).balance;
        require(ethBalance > 0, "Nothing to withdraw");
        require(ethBalance >= amount, "Amount too high");
        payable(_recipient).transfer(amount);
    }

    receive() external payable { }

    fallback() external payable { }



    /*** Utils ***/

    // Division rounds down by default in Solidity, this function rounds up
    function divisionRoundUp(uint32 a, uint32 m) private pure returns (uint32) {
        return (a + m - 1) / m;
    }


    function extractBytes(bytes memory data, uint32 n) private pure returns (bytes memory) {
        
        require(data.length >= n, "Slice out of bounds");
        
        bytes memory returnValue = new bytes(n);
        for (uint32 i = 0; i < n; i++) {
            returnValue[i] = data[i]; 
        }
        return returnValue;
    }

    function extractBytes8(bytes memory data, uint32 from) private pure returns (bytes8) {
        
        require(data.length >= from + 8, "Slice out of bounds");

        return bytes8(bytes.concat(data[from + 0], data[from + 1], data[from + 2], data[from + 3], data[from + 4], data[from + 5], data[from + 6], data[from + 7]));
    }

    function nbValuesBetween(uint32[] memory arr, uint32 min, uint32 max, uint32 imax) internal pure returns (uint32) {
        uint32 count = 0;

        for (uint32 i = 0; i < imax; i++) {
            if (arr[i] >= min && arr[i] <= max) {
                count++;
            }
        }

        return count;
    }

    // idx must be sorted in ascending order
    function removeIndexesFromArray(string[] storage arr, uint32[] memory idx) internal {

        uint32 previous = idx[0];
        for (uint32 i = 1; i < idx.length; i++) {
            if (previous < idx[i]) {
                previous = idx[i];
            } else {
                revert("Indexes must be sorted");
            }
        }
        require(idx[idx.length - 1] < arr.length, "Index to remove out of bound");

        uint32 stopAtIndex = uint32(arr.length - idx.length);
        uint32 indexToMove = uint32(arr.length);
        uint32 j = 0;

        for (uint32 i = 0; i < idx.length; i++) {

            if (idx[i] >= stopAtIndex) {
                break;
            }

            indexToMove--;

            while (j < idx.length) {
                uint32 indexToRemove = idx[idx.length-j-1];

                if (indexToRemove == indexToMove) {
                    indexToMove--;
                } else {
                    break;
                }

                j++;
            }

            arr[idx[i]] = arr[indexToMove];
        }

        for (uint32 i = 0; i < idx.length; i++) {
            arr.pop();
        }
    }

    function bytesToHex(bytes memory buffer) public pure returns (string memory) {

        // Fixed buffer size for hexadecimal convertion
        bytes memory converted = new bytes(buffer.length * 2);

        bytes memory _base = "0123456789abcdef";

        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return string(abi.encodePacked("0x", converted));
    }

}

interface CallbackContract {
    function fulfillDrawWinners(string memory cid) external;
}

interface AccountsContract {
    function pay(address user) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IVRFCoordinatorV2Plus} from "./interfaces/IVRFCoordinatorV2Plus.sol";
import {IVRFMigratableConsumerV2Plus} from "./interfaces/IVRFMigratableConsumerV2Plus.sol";
import {ConfirmedOwner} from "../../shared/access/ConfirmedOwner.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinatorV2Plus.
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBaseV2Plus, and can
 * @dev initialize VRFConsumerBaseV2Plus's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumerV2Plus is VRFConsumerBaseV2Plus {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _subOwner)
 * @dev       VRFConsumerBaseV2Plus(_vrfCoordinator, _subOwner) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create a subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords, extraArgs),
 * @dev see (IVRFCoordinatorV2Plus for a description of the arguments).
 *
 * @dev Once the VRFCoordinatorV2Plus has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBaseV2Plus.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2Plus is IVRFMigratableConsumerV2Plus, ConfirmedOwner {
  error OnlyCoordinatorCanFulfill(address have, address want);
  error OnlyOwnerOrCoordinator(address have, address owner, address coordinator);
  error ZeroAddress();

  // s_vrfCoordinator should be used by consumers to make requests to vrfCoordinator
  // so that coordinator reference is updated after migration
  IVRFCoordinatorV2Plus public s_vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) ConfirmedOwner(msg.sender) {
    s_vrfCoordinator = IVRFCoordinatorV2Plus(_vrfCoordinator);
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2Plus expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != address(s_vrfCoordinator)) {
      revert OnlyCoordinatorCanFulfill(msg.sender, address(s_vrfCoordinator));
    }
    fulfillRandomWords(requestId, randomWords);
  }

  /**
   * @inheritdoc IVRFMigratableConsumerV2Plus
   */
  function setCoordinator(address _vrfCoordinator) public override onlyOwnerOrCoordinator {
    s_vrfCoordinator = IVRFCoordinatorV2Plus(_vrfCoordinator);
  }

  modifier onlyOwnerOrCoordinator() {
    if (msg.sender != owner() && msg.sender != address(s_vrfCoordinator)) {
      revert OnlyOwnerOrCoordinator(msg.sender, owner(), address(s_vrfCoordinator));
    }
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// End consumer library.
library VRFV2PlusClient {
  // extraArgs will evolve to support new features
  bytes4 public constant EXTRA_ARGS_V1_TAG = bytes4(keccak256("VRF ExtraArgsV1"));
  struct ExtraArgsV1 {
    bool nativePayment;
  }

  struct RandomWordsRequest {
    bytes32 keyHash;
    uint256 subId;
    uint16 requestConfirmations;
    uint32 callbackGasLimit;
    uint32 numWords;
    bytes extraArgs;
  }

  function _argsToBytes(ExtraArgsV1 memory extraArgs) internal pure returns (bytes memory bts) {
    return abi.encodeWithSelector(EXTRA_ARGS_V1_TAG, extraArgs);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AutomationBase} from "./AutomationBase.sol";
import {AutomationCompatibleInterface} from "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {VRFV2PlusClient} from "../libraries/VRFV2PlusClient.sol";
import {IVRFSubscriptionV2Plus} from "./IVRFSubscriptionV2Plus.sol";

// Interface that enables consumers of VRFCoordinatorV2Plus to be future-proof for upgrades
// This interface is supported by subsequent versions of VRFCoordinatorV2Plus
interface IVRFCoordinatorV2Plus is IVRFSubscriptionV2Plus {
  /**
   * @notice Request a set of random words.
   * @param req - a struct containing following fiels for randomness request:
   * keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * requestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * extraArgs - abi-encoded extra args
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(VRFV2PlusClient.RandomWordsRequest calldata req) external returns (uint256 requestId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice The IVRFMigratableConsumerV2Plus interface defines the
/// @notice method required to be implemented by all V2Plus consumers.
/// @dev This interface is designed to be used in VRFConsumerBaseV2Plus.
interface IVRFMigratableConsumerV2Plus {
  /// @notice Sets the VRF Coordinator address
  /// @notice This method is should only be callable by the coordinator or contract owner
  function setCoordinator(address vrfCoordinator) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ConfirmedOwnerWithProposal} from "./ConfirmedOwnerWithProposal.sol";

/// @title The ConfirmedOwner contract
/// @notice A contract with helpers for basic contract ownership.
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function _preventExecution() internal view {
    // solhint-disable-next-line avoid-tx-origin
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    _preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice The IVRFSubscriptionV2Plus interface defines the subscription
/// @notice related methods implemented by the V2Plus coordinator.
interface IVRFSubscriptionV2Plus {
  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint256 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint256 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint256 subId, address to) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint256 subId) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint256 subId, address newOwner) external;

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription with LINK, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   * @dev Note to fund the subscription with Native, use fundSubscriptionWithNative. Be sure
   * @dev  to send Native with the call, for example:
   * @dev COORDINATOR.fundSubscriptionWithNative{value: amount}(subId);
   */
  function createSubscription() external returns (uint256 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return nativeBalance - native balance of the subscription in wei.
   * @return reqCount - Requests count of subscription.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(
    uint256 subId
  )
    external
    view
    returns (uint96 balance, uint96 nativeBalance, uint64 reqCount, address owner, address[] memory consumers);

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint256 subId) external view returns (bool);

  /**
   * @notice Paginate through all active VRF subscriptions.
   * @param startIndex index of the subscription to start from
   * @param maxCount maximum number of subscriptions to return, 0 to return all
   * @dev the order of IDs in the list is **not guaranteed**, therefore, if making successive calls, one
   * @dev should consider keeping the blockheight constant to ensure a holistic picture of the contract state
   */
  function getActiveSubscriptionIds(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  /**
   * @notice Fund a subscription with native.
   * @param subId - ID of the subscription
   * @notice This method expects msg.value to be greater than 0.
   */
  function fundSubscriptionWithNative(uint256 subId) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnable} from "../interfaces/IOwnable.sol";

/// @title The ConfirmedOwner contract
/// @notice A contract with helpers for basic contract ownership.
contract ConfirmedOwnerWithProposal is IOwnable {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    // solhint-disable-next-line custom-errors
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /// @notice Allows an owner to begin transferring ownership to a new address.
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /// @notice Allows an ownership transfer to be completed by the recipient.
  function acceptOwnership() external override {
    // solhint-disable-next-line custom-errors
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /// @notice Get the current owner
  function owner() public view override returns (address) {
    return s_owner;
  }

  /// @notice validate, transfer ownership, and emit relevant events
  function _transferOwnership(address to) private {
    // solhint-disable-next-line custom-errors
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /// @notice validate access
  function _validateOwnership() internal view {
    // solhint-disable-next-line custom-errors
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /// @notice Reverts if called by anyone other than the contract owner.
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOwnable {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}