/**
 *Submitted for verification at Arbiscan on 2023-07-05
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
    }
}

interface ISupraRouter {
  function generateRequest(string memory _functionSig , uint8 _rngCount, uint256 _numConfirmations,address _clientWalletAddress) external returns(uint256);
}

contract VRFRequest is Ownable {

  address supraRouter;
  constructor(address _supraRouter) {
      supraRouter = _supraRouter;
  }

  event SupraVRFResponse(uint256 _nonce, uint256 _randomNumber, uint256 _timestamp);

  uint256 public requestCount; 
  mapping (uint256 => uint256) mappingRequestNonce;

  function requestSupraRandomNumber() external onlyOwner {
    ISupraRouter(supraRouter).generateRequest("storeSupraVRFResponse(uint256,uint256[])", 1, 1, msg.sender);
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
    emit SupraVRFResponse(_supraVRFRequestNonce, _supraGeneratedRandomNumber[0], block.timestamp);
  }

   
}