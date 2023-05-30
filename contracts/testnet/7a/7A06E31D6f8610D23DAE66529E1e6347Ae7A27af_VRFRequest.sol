// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Ownable.sol";

interface ISupraRouter {
  /**
    @dev Generates a request for a random number from the SupraRouter.
    @param _functionSig The signature of the function to be called in the SupraRouter.
    @param _rngCount The number of random numbers to generate.
    @param _numConfirmations The number of confirmations required for the request.
    @param _clientWalletAddress The address of the client's wallet.
    @return The nonce of the generated request.
  */
  function generateRequest(string memory _functionSig , uint8 _rngCount, uint256 _numConfirmations,address _clientWalletAddress) external returns(uint256);
}

contract VRFRequest is Ownable {

  address supraRouter;
  constructor(address _supraRouter) {
      supraRouter = _supraRouter;
  }

  event SupraVRFResponse(uint256 _nonce, uint256 _randomNumber);

  uint256 public requestCount; 
  mapping (uint256 => uint256) mappingRequestNonce;
  mapping (uint256 => uint256) mappingRandomNumber;

  /**
    @dev Requests a supra random number from the SupraRouter.
    Only the owner of the contract can call this function.
  */
  function requestSupraRandomNumber() external onlyOwner {
    uint256 supraVRFRequestNonce =  ISupraRouter(supraRouter).generateRequest("storeSupraVRFResponse(uint256,uint256[])", 1, 1, msg.sender);
    mappingRequestNonce[requestCount] = supraVRFRequestNonce;
    requestCount++;
  }

  /**
    @dev Stores the Supra VRF response in the contract.
    Only the SupraRouter can call this function.
    @param _supraVRFRequestNonce The nonce of the Supra VRF request.
    @param _supraGeneratedRandomNumber The array of generated random numbers.
  */
  function storeSupraVRFResponse(uint256 _supraVRFRequestNonce, uint256[] calldata _supraGeneratedRandomNumber) external {
    require(msg.sender == supraRouter, "only supra router can call this function");
    mappingRandomNumber[_supraVRFRequestNonce] = _supraGeneratedRandomNumber[0];

    emit SupraVRFResponse(_supraVRFRequestNonce, _supraGeneratedRandomNumber[0]);
  }

  /**
    @dev Gets the VRF request nonce for a given request count.
    @param _requestCount The request count.
    @return The VRF request nonce.
  */
  function getVRFRequestNonce(uint256 _requestCount) external view returns (uint256) {
    return mappingRequestNonce[_requestCount];
  }

  /**
    @dev Gets the Supra random number for a given request nonce.
    @param _requestNonce The request nonce.
    @return The Supra random number.
  */
  function getSupraRandomNumber(uint256 _requestNonce) external view returns (uint256) {
    return mappingRandomNumber[_requestNonce];
  }
   
}