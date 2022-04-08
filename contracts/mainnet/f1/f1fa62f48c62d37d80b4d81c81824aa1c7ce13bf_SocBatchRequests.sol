//  ___  _____  ___    ___    __    ___  _   _
// / __)(  _  )/ __)  / __)  /__\  / __)( )_( )
// \__ \ )(_)(( (__  ( (__  /(__)\ \__ \ ) _ (
// (___/(_____)\___)()\___)(__)(__)(___/(_) (_)
//   ___  _____  _  _  ____  ____    __    ___  ____
//  / __)(  _  )( \( )(_  _)(  _ \  /__\  / __)(_  _)
// ( (__  )(_)(  )  (   )(   )   / /(__)\( (__   )(
//  \___)(_____)(_)\_) (__) (_)\_)(__)(__)\___) (__)


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ChainlinkClient.sol";
import "./ConfirmedOwner.sol";

contract SocBatchRequests is ChainlinkClient, ConfirmedOwner {
  using Chainlink for Chainlink.Request;

  uint256 constant private ORACLE_PAYMENT = 3;
  uint256 public lastBatchResponse;

  event RequestFulfilled(
    bytes32 indexed requestId,
    uint256 indexed batchResponse
  );

  constructor() ConfirmedOwner(msg.sender){
    setChainlinkToken(0xf97f4df75117a78c1A5a0DBb814Af92458539FB4);
  }

  function request(address _oracle, string memory _jobId, string memory _batchRequest)
    public
    onlyOwner
  {
    Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(_jobId), address(this), this.fulfill.selector);
    req.add("get", _batchRequest);
    sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
  }

  function fulfill(bytes32 _requestId, uint256 _batchResponse)
    public
    recordChainlinkFulfillment(_requestId)
  {
    emit RequestFulfilled(_requestId, _batchResponse);
    lastBatchResponse = _batchResponse;
  }

  function getChainlinkToken() public view returns (address) {
    return chainlinkTokenAddress();
  }

  function withdrawLink() public onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
    require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
  }

  function cancelRequest(
    bytes32 _requestId,
    uint256 _payment,
    bytes4 _callbackFunctionId,
    uint256 _expiration
  )
    public
    onlyOwner
  {
    cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
  }

  function stringToBytes32(string memory source) private pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }

    assembly { // solhint-disable-line no-inline-assembly
      result := mload(add(source, 32))
    }
  }
}