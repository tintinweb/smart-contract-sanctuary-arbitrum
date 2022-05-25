/**
 *Submitted for verification at Arbiscan on 2022-05-25
*/

pragma solidity >=0.4.21 <0.9.0;

contract ArbRetryableTxDummy {
    function createRetryableTicket(
        address destAddr,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external {}

    function redeem(bytes32 userTxHash) external {}

    function keepalive(bytes32 userTxHash) external {}

    function cancel(bytes32 userTxHash) external {}

    event TicketCreated(bytes32 indexed userTxHash);
    event LifetimeExtended(bytes32 indexed userTxHash, uint256 newTimeout);
    event Redeemed(bytes32 indexed userTxHash);
    event Canceled(bytes32 indexed userTxHash);
}