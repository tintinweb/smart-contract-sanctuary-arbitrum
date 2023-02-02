/**
 *Submitted for verification at Arbiscan on 2023-01-31
*/

// File: contracts/interfaces/IERC20TransferGateway.sol


pragma solidity ^0.8.9;

/**
 * @dev Interface of the ERC20 cross-chain transfer vea gateway
 */
interface IERC20TransferGateway {

    function rewardLP(address receiverGateway, bytes32 transferDataHash, address claimer, uint256 fee) external;

}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


// File: @kleros/vea-contracts/interfaces/IFastBridgeSender.sol



/**
 *  @authors: [@jaybuidl, @shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

interface IFastBridgeSender {
    // ************************************* //
    // *              Events               * //
    // ************************************* //

    /**
     * @dev The Fast Bridge participants need to watch for these events and relay the messageHash on the FastBridgeReceiverOnEthereum.
     * @param fastMessage The fast message data.
     * @param fastMessage The hash of the fast message data encoded with the nonce.
     */
    event MessageReceived(bytes fastMessage, bytes32 fastMessageHash);

    /**
     * @dev The event is emitted when messages are sent through the canonical bridge.
     * @param epoch The epoch of the batch requested to send.
     * @param canonicalBridgeMessageID The unique identifier of the safe message returned by the canonical bridge.
     */
    event SentSafe(uint256 indexed epoch, bytes32 canonicalBridgeMessageID);

    /**
     * The bridgers need to watch for these events and relay the
     * batchMerkleRoot on the FastBridgeReceiver.
     */
    event BatchOutgoing(uint256 indexed batchID, uint256 batchSize, uint256 epoch, bytes32 batchMerkleRoot);

    // ************************************* //
    // *        Function Modifiers         * //
    // ************************************* //

    /**
     * Note: Access must be restricted by the receiving gateway by checking the sender argument.
     * @dev Sends an arbitrary message across domain using the Fast Bridge.
     * @param _receiver The cross-domain contract address which receives the calldata.
     * @param _calldata The receiving domain encoded message data.
     */
    function sendFast(address _receiver, bytes memory _calldata) external;

    /**
     * Sends a batch of arbitrary message from one domain to another
     * via the fast bridge mechanism.
     */
    function sendBatch() external;

    /**
     * @dev Sends a markle root representing an arbitrary batch of messages across domain using the Safe Bridge, which relies on the chain's canonical bridge. It is unnecessary during normal operations but essential only in case of challenge.
     * @param _epoch block number of batch
     */
    function sendSafeFallback(uint256 _epoch) external payable;
}

// File: contracts/transfer/ERC20LPGateway.sol


pragma solidity ^0.8.9;




contract ERC20LPGateway {

    struct TransferData{
        uint256 amount;
        uint256 maxFee;
        address destination;
        uint32 startTime;
        uint32 feeRampup;
        uint32 nonce;
    }

    uint256 public constant CONTRACT_FEE_BASIS_POINTS = 5;
    uint256 public constant BASIS_POINTS = 10000;

    IERC20 public immutable token;
    IFastBridgeSender public immutable bridge;
    IERC20TransferGateway public immutable gateway;

    mapping(bytes32 => bool) public claimedTransferHashes;

    constructor(IFastBridgeSender _bridge, IERC20 _token, IERC20TransferGateway _gateway) {
        bridge = _bridge;
        token = _token;
        gateway = _gateway;
    }

    function claim(TransferData calldata _transferData) public{
        bytes32 transferDataHash = keccak256(abi.encodePacked(
            _transferData.amount,
            _transferData.maxFee,
            _transferData.destination,
            _transferData.startTime,
            _transferData.feeRampup,
            _transferData.nonce
        ));
        require(!claimedTransferHashes[transferDataHash], "Already claimed.");
        claimedTransferHashes[transferDataHash] = true;

        uint256 fee = getLPFee(_transferData, block.timestamp);
        uint256 total = _transferData.amount + _transferData.maxFee;
        uint256 amountPaid = total - fee;
        bool success = token.transferFrom(msg.sender, _transferData.destination, amountPaid);
        require(success, "Transfer Failed");

        bytes memory _calldata = abi.encodeWithSelector(IERC20TransferGateway.rewardLP.selector, transferDataHash, msg.sender, total);
        bridge.sendFast(address(gateway), _calldata);
    }

    function getLPFee(TransferData calldata _transferData, uint256 _currentTime) public pure returns (uint256 fee){
        if (_currentTime < _transferData.startTime)
            return 0;
        else if (_currentTime >= _transferData.startTime + _transferData.feeRampup)
            return _transferData.maxFee;
        else
            return _transferData.maxFee * (_currentTime - _transferData.startTime) / _transferData.feeRampup;
    }
}