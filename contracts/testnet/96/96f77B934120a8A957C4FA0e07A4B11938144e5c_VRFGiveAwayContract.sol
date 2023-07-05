/**
 *Submitted for verification at Arbiscan on 2023-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        owner = newOwner;
    }
}

interface ISupraRouter {
    /**
    @dev Generates a request for a random number from the SupraRouter.
    @param _functionSig The signature of the function to be called in the SupraRouter.
    @param _rngCount The number of random numbers to generate.
    @param _numConfirmations The number of confirmations required for the request.
    @param _clientWalletAddress The address of the client's wallet.
    @return The nonce of the generated request.
  */
    function generateRequest(
        string memory _functionSig,
        uint8 _rngCount,
        uint256 _numConfirmations,
        address _clientWalletAddress
    ) external returns (uint256);
}

contract VRFGiveAwayContract is Ownable {
    address supraRouter;

    constructor(address _supraRouter) {
        supraRouter = _supraRouter;
    }

    event SupraVRFResponse(uint256 _nonce, uint256 _randomNumber);

    bool public isRequestFulfilled;
    uint256 public nextRequestCount = 1;

    mapping(uint256 => uint256) mappingRequestNonce;
    mapping(uint256 => uint256) mappingRandomNumber;

    /**
     * @dev Requests a supra random number.
     *
     * This function generates a supra random number request by interacting with the Supra Router contract.
     * It stores the supra VRF request nonce and increments the next request count.
     * Note: Only the contract owner can call this function.
     */
    function requestSupraRandomNumber() external onlyOwner {
        uint256 supraVRFRequestNonce = ISupraRouter(supraRouter)
            .generateRequest(
                "storeSupraVRFResponse(uint256,uint256[])",
                1,
                1,
                msg.sender
            );
        mappingRequestNonce[nextRequestCount] = supraVRFRequestNonce;
        nextRequestCount++;
        isRequestFulfilled = false;
    }

    /**
     * @dev Chooses the winners from an array of participants.
     * @param _participants The array of participant names.
     * @param _winnerCount The number of winners to choose.
     * @return An array of winner names.
     */
    function chooseWinner(string[] memory _participants, uint256 _winnerCount, uint256 _supraGeneratedRandomNumber)
        public
        pure
        returns (string[] memory)
    {
        require(
            _winnerCount <= countUniqueParticipants(_participants),
            "Supra: Cannot request more than total unique participants"
        );

        string[] memory winnerNames = new string[](_winnerCount);
        uint256 randomNumber = _supraGeneratedRandomNumber;

        for (uint256 winnerLoop = 0; winnerLoop < _winnerCount; winnerLoop++) {
            uint256 index = randomNumber % _participants.length;
            while (isWinner(winnerNames, _participants[index])) {

                // remove participant if already a winner
                _participants[index] = _participants[_participants.length-1];

                // reducing size of dynamic array by 1 
                assembly { mstore(_participants, sub(mload(_participants), 1)) }
                
                index = randomNumber % _participants.length;
            }
            winnerNames[winnerLoop] = _participants[index];
        }

        return winnerNames;
    }

    /**
     * @dev Check if a name exists in the list of winners.
     * @param winners The array of winner names.
     * @param name The name to check.
     * @return A boolean indicating whether the name is a winner.
     */
    function isWinner(string[] memory winners, string memory name)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < winners.length; i++) {
            if (
                keccak256(abi.encodePacked(winners[i])) ==
                keccak256(abi.encodePacked(name))
            ) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Counts the total number of unique strings in a dynamic string array.
     * @param supraEntries The array of strings to count unique entries from.
     * @return The total number of unique strings.
     */
    function countUniqueParticipants(string[] memory supraEntries)
        internal
        pure
        returns (uint256)
    {
        uint256 count = 0;
        uint256 arrayLength = supraEntries.length;
        bool[] memory uniqueFlags = new bool[](arrayLength);

        for (uint256 i = 0; i < arrayLength; i++) {
            if (!uniqueFlags[i]) {
                count++;
                for (uint256 j = i + 1; j < arrayLength; j++) {
                    if (
                        keccak256(abi.encodePacked(supraEntries[i])) ==
                        keccak256(abi.encodePacked(supraEntries[j]))
                    ) {
                        uniqueFlags[j] = true;
                    }
                }
            }
        }

        return count;
    }

    /**
    @dev Stores the Supra VRF response in the contract.
    Only the SupraRouter can call this function.
    @param _supraVRFRequestNonce The nonce of the Supra VRF request.
    @param _supraGeneratedRandomNumber The array of generated random numbers.
  */
    function storeSupraVRFResponse(
        uint256 _supraVRFRequestNonce,
        uint256[] calldata _supraGeneratedRandomNumber
    ) external {
        require(
            msg.sender == supraRouter,
            "only supra router can call this function"
        );
        mappingRandomNumber[
            _supraVRFRequestNonce
        ] = _supraGeneratedRandomNumber[0];
        isRequestFulfilled = true;

        emit SupraVRFResponse(
            _supraVRFRequestNonce,
            _supraGeneratedRandomNumber[0]
        );
    }

    function getLatestSupraRandomNumber() external view returns (uint256) {
        return mappingRandomNumber[mappingRequestNonce[nextRequestCount - 1]];
    }

    /**
    @dev Gets the VRF request nonce for a given request count.
    @param _requestCount The request count.
    @return The VRF request nonce.
  */
    function getVRFRequestNonce(uint256 _requestCount)
        external
        view
        returns (uint256)
    {
        return mappingRequestNonce[_requestCount];
    }

    /**
    @dev Gets the Supra random number for a given request nonce.
    @param _requestNonce The request nonce.
    @return The Supra random number.
  */
    function getSupraRandomNumber(uint256 _requestNonce)
        external
        view
        returns (uint256)
    {
        return mappingRandomNumber[_requestNonce];
    }
}