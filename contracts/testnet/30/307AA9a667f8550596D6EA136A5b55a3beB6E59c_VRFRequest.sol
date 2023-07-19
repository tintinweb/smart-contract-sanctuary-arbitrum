/**
 *Submitted for verification at Arbiscan on 2023-07-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Modifier that checks if the caller is the owner of the contract.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        owner = newOwner;
    }
}

/**
 * @title ISupraRouter
 * @dev Interface for the SupraRouter contract that generates random numbers.
 */
interface ISupraRouter {
    function generateRequest(
        string memory _functionSig,
        uint8 _rngCount,
        uint256 _numConfirmations,
        address _clientWalletAddress
    ) external returns (uint256);
}

/**
 * @title VRFRequest
 * @dev The VRFRequest contract extends Ownable and allows the owner to request random numbers from a SupraRouter contract.
 */
contract VRFRequest is Ownable {
    address supraRouter;
    uint256 public supraRouterNonce;
    mapping(uint256 => uint256) public randomNumberBySupraRouterNonce;

    constructor(address _supraRouter) {
        supraRouter = _supraRouter;
    }

    event SupraVRFResponse(
        uint256 _nonce,
        uint256 _randomNumber,
        uint256 _timestamp
    );

    mapping(uint256 => uint256) mappingRequestNonce;

    /**
     * @dev Requests a random number from the SupraRouter contract.
     * Only the owner of the contract can call this function.
     */
    function requestSupraRandomNumber() external onlyOwner {
        ISupraRouter(supraRouter).generateRequest(
            "storeSupraVRFResponse(uint256,uint256[])",
            1,
            1,
            msg.sender
        );
    }

    /**
     * @dev Stores the random number received from the SupraRouter contract.
     * This function can only be called by the SupraRouter contract.
     * @param _supraVRFRequestNonce The nonce associated with the request.
     * @param _supraGeneratedRandomNumber The array containing the generated random number.
     */
    function storeSupraVRFResponse(
        uint256 _supraVRFRequestNonce,
        uint256[] calldata _supraGeneratedRandomNumber
    ) external {
        require(
            msg.sender == supraRouter,
            "only supra router can call this function"
        );
        supraRouterNonce = _supraVRFRequestNonce;
        randomNumberBySupraRouterNonce[
            _supraVRFRequestNonce
        ] = _supraGeneratedRandomNumber[0];
        emit SupraVRFResponse(
            _supraVRFRequestNonce,
            _supraGeneratedRandomNumber[0],
            block.timestamp
        );
    }
}