/**
 *Submitted for verification at Arbiscan on 2023-05-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract ApiShowARB {
    function applyFor(address to_, uint256 amount_, bytes memory reason_) external {}
    function bridgeToETH(uint256 amount) external {}
    function applyMBOX(uint256 amount_) external {}
    function applyToken(address token_, uint256 amount_) external {}
    function applyVerseMining(uint256 amount_, bytes memory reason_) external {}
    function claim(uint256 systx, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {}
    function claim(uint256 version, uint256[] calldata elements, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {}
    function claim(uint256 systx, uint256 version, uint256[] calldata elements, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {}
    function cancelAuction(uint256 index_) external {}
    function buy(address auctor_, uint256 index_, uint256 startTime_, uint256 price_, uint256 tradeType_) external {}
    function buy(address[] memory auctors_, uint256[] memory indexs_, uint256[] memory startTimes_, uint256[] memory prices_, uint256 tradeType_, bool ignoreSold) external {}
    function changePrice(uint256 index_, uint256 price_) external {}
    function beginBreed(uint256 tokenId0, uint256 tokenId1, uint256 suggestIndex, address feeToken, uint256 fee) external {}
    function endBreed() external {}
    function setBreedBlockhash(address addr, bytes32 hashCode) external {}
    function levelUp(uint256 dstId, uint256[] calldata srcIds) external {}
    function starUp(uint256 dstId, uint256 srcId) external {}
    function starUp(uint256 dstId, uint256 srcId1, uint256 srcId2) external {} 
}