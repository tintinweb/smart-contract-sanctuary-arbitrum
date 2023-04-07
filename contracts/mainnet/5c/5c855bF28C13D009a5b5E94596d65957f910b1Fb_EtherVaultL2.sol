pragma solidity ^0.8.16;
// SPDX-License-Identifier:MIT
/*

 888~~    d8   888                       Y88b      /                    888   d8
 888___ _d88__ 888-~88e  e88~~8e  888-~\  Y88b    /    /~~~8e  888  888 888 _d88__
 888     888   888  888 d888  88b 888      Y88b  /         88b 888  888 888  888
 888     888   888  888 8888__888 888       Y888/     e88~-888 888  888 888  888
 888     888   888  888 Y888    , 888        Y8/     C888  888 888  888 888  888
 888___  "88_/ 888  888  "88___/  888         Y       "88_-888 "88_-888 888  "88_/

Ethervault Multi-signature Wallet - Layer-2 Version: Written without constraints of
reducing deploy costs, unlike version 1 which strives to limit deployment and gas
costs above all else. Supports price feeds, daily withdrawal limit is a dollar
value.  ~ Darkerego, Copyright 2023
*/




import "IERC20.sol";
import "IAggregatorV3.sol";

contract EtherVaultL2 {

    /*
      @dev: gas optimized variable packing
    */
    uint8 public version = 2;
    bool public paused;
    uint8 private mutex;
    uint8 public signerCount;
    uint8 public threshold;
    uint16 public proposalId;
    uint32 public execNonce;
    uint32 public txCount;
    uint32 private lastDay;
    uint128 public dailyLimit;
    uint128 public spentToday;
    // address public immutable consumerAddress;


    struct Proposal{
        address proposer;
        address modifiedSigner;
        bool paused;
        uint8 newThreshold;
        uint8 numSigners;
        uint32 initiated;
        uint128 newLimit;
        mapping (address => uint8) approvals;
    }

    struct Transaction{
        address proposer;
        address dest;
        uint128 value;
        bytes data;
        uint8 numSigners;
        mapping (address => uint8) approvals;
    }

    /*
      @dev: Error Messages
    */
    string constant DUP_SIG_ERR = "Already signed.";
    string constant TX_FAIL_ERR = "Call failed";
    string constant TX_NOT_FOUND_ERR = "Transaction not found";
    string constant INS_FUNDS_ERR = "Insufficient funds";
    string constant AUTH_ERR = "!Auth/Nonce/Mutex";

    /*
      @dev: Mapping Indexes
       Signer address => 1 (substituted for bool to save gas)
       TXID > Transaction
       ProposalID => Proposal
    */
    mapping (address => uint8) isSigner;
    mapping (uint32 => Transaction) public pendingTxs;
    mapping (uint16 => Proposal) public pendingProposals;
    /*
      @dev: Tracked token mapping (1 == enabled):
      tokenAddress => 1
    */
    mapping (address => address) public trackedTokens;

    function auth(
        address s,
        uint32 _nonce
        ) private {
        /*
          @dev: Checks if sender is a signer, checks nonce,
          and ensures system state is not locked.
        */

        require(isSigner[s] == 1 && _nonce == execNonce +1 && mutex == 0, AUTH_ERR);
        execNonce += 1;
    }

    function isPaused() private view {
        /*
          Called by modifier checkPaused
        */
        require(! paused, "System paused");
    }

    modifier checkPaused {
        /*
          Revert if the contract is paused.
        */
        isPaused();
        _;
    }


    modifier protected(
        uint32 _nonce
        ) {
        /*
          @dev: Restricted function access protection and reentrancy guards.
          Saves some gas by combining these checks and using an int instead of
          bool.
        */
       auth(msg.sender, _nonce);
       mutex = 1;
       _;
       mutex = 0;

    }

    constructor(
        /*
          Ethervault Layer 2 Version Constructor Parameters:

          @param _signers: list of addresses
          @param _threshold: required number of signers to process a transaction that is over limit or a raw transaction
          @param _dailyDollarLimit: integer value of the daily withdrawal limit in dollars. Example $50 == 50
          @param _consumerAddress: Address of PriceFeeder contract.
        */
        address[] memory _signers,
        uint8 _threshold,
        uint128 _dailyDollarLimit,
        address ethPriceAggregator
        ){
        /*
            @dev: Since we're not constrained by deployment size in this layer 2 version,
            we can afford to validate the constructor arguments.
        */
        require(ethPriceAggregator != address(0), "EthFeed is zero address");
        require(_signers.length >= 3, "Need at least 3 signers");
        require(_threshold < _signers.length && _threshold >= 2, "Threshold >= 2 < len(signers)");

        /*
              @dev: When I wrote this, I never imagined having more than 128
              signers. If for some reason you do, you may want to modify this code.
        */
        unchecked{ // save some gas
        uint8 slen = uint8(_signers.length);
        signerCount = slen;
        for (uint8 i = 0; i < slen; i++) {
            isSigner[_signers[i]] = 1;
        }
      }
        (threshold, dailyLimit, spentToday, mutex) = (_threshold, _dailyDollarLimit, 0, 0);
        trackedTokens[address(0)] = ethPriceAggregator;
    }
    /*
       @dev: Allow arbitrary deposits to contract.
    */
    receive() external payable {}



    function trackToken(
        /*
          @dev: Make the contract aware of a token's price so that withdrawals can be
          limited to the dailyLimit (which in this version of Ethervault is a DOLLAR value).
          Requires the consumer contract actually supports this token.
        */
        address tokenAddress,
        address feedAddress,
        uint32 _nonce
        ) external protected(_nonce) {
            require(trackedTokens[tokenAddress] == address(0), "Already tracking.");
            require(AggregatorV3Interface(feedAddress).decimals() == 8, "Decimals!=8");
            trackedTokens[tokenAddress] = feedAddress;
    }


    function execute(
        /*
            @dev: Function to execute a transaction with arbitrary parameters. Handles
            all withdrawals, etc. Can be used for token transfers, eth transfers,
            or anything else.
        */
        address recipient,
        uint256 _value,
        bytes memory data
        ) private {
       assembly {
            let success_ := call(gas(), recipient, _value, add(data, 0x20), mload(data), 0x0, 0x0)
            let success := eq(success_, 0x1)
            let retSz := returndatasize()

            if iszero(success) {
                revert(data, retSz)}
            }


        }

    function newProposal(
        /*
          @dev: Create a new proposal to change the daily limits, the signer threshold, or to
          add or revoke a signer. If the specified address is already a signer, then this is a
          revokation change. If not, it is a granting change.
        */
        address _signer,
        uint128 _limit,
        uint8 _threshold,
        bool _paused,
        uint32 _nonce
    ) external protected(_nonce) returns(uint16){
        proposalId += 1;
        Proposal storage prop = pendingProposals[proposalId];
        (prop.modifiedSigner, prop.newLimit, prop.initiated,
        prop.newThreshold, prop.proposer) = (_signer, _limit,
        uint32(block.timestamp),  _threshold, msg.sender);
        // stack too deep
        prop.paused = _paused;
        sign(0, proposalId, msg.sender);
        return proposalId;
    }

    function deleteProposal(
        /*
          @dev: Allow only the proposer to delete a pending proposal they created.
        */
        uint16 _proposalId,
        uint32 _nonce
        ) external protected(_nonce) {
        Proposal storage proposalObj = pendingProposals[_proposalId];
        if (proposalObj.proposer == msg.sender){
            delete pendingProposals[_proposalId];
        }
    }

    function approveProposal(
        uint16 _proposalId,
        uint32 _nonce
        ) external protected(_nonce) {
        /*
          @dev: Approve a pending proposal and execute it if all required
           signers are accounted for.
        */
        require(pendingProposals[_proposalId].approvals[msg.sender] == 0, DUP_SIG_ERR);
        Proposal storage proposalObj = pendingProposals[_proposalId];
        // if all signers have signed
        if(proposalObj.numSigners +1 == signerCount)  {
             // if limit/threshold are being updated
            if (proposalObj.newLimit > 0||proposalObj.newThreshold >0){
                dailyLimit = proposalObj.newLimit;
                threshold = proposalObj.newThreshold;
            } // set paused
            paused = proposalObj.paused;
            if (proposalObj.modifiedSigner != address(0)) {
                if (isSigner[proposalObj.modifiedSigner] == 1) {
                    /*
                    @dev: Signer exists, so this must be a revokation proposal.
                    revoke this signer and reset the approval count.
                    Admin cannot be revoked.
                    */
                    isSigner[proposalObj.modifiedSigner] = 0;
                    signerCount-=1;
                } else {
                    /*
                    @dev: Signer does not exist yet, so this must be signer addition.
                    Grant signer role, reset pending signer count.
                    */
                    isSigner[proposalObj.modifiedSigner] = 1;
                    signerCount+=1;
            }
            }
            delete pendingProposals[_proposalId];
        } else {
            // More signatures needed, so just sign.
            //signProposal(msg.sender, _proposalId);
            sign(0, _proposalId, msg.sender);
        }
    }


    function deleteTx(
        /*
          @dev: Remove pending transaction from storage and cancel it.
          Only the propoper of the transaction can delete.
        */
        uint32 txid,
        uint32 _nonce
        ) external protected(_nonce) {
        require(pendingTxs[txid].proposer == msg.sender, "!proposer");
        require(pendingTxs[txid].dest != address(0), TX_NOT_FOUND_ERR);
        delete pendingTxs[txid];
    }


    function approveTx(
        /*
          @dev: Function to approve a pending tx. If the signature threshold
          is met, the transaction will be executed in this same call. Reverts
          if the caller is the same signer that initialized or already approved
          the transaction.
        */
        uint32 txid,
        uint32 _nonce
        ) external protected(_nonce) checkPaused {
        Transaction storage _tx = pendingTxs[txid];
        require(pendingTxs[txid].approvals[msg.sender] == 0, DUP_SIG_ERR);
        require(_tx.dest != address(0), TX_NOT_FOUND_ERR);
        if(_tx.numSigners + 1 >= threshold){
            execute(_tx.dest, _tx.value, _tx.data);
            // should not have any re-entrency vulnerability because of mutex checks
            delete pendingTxs[txid];
        } else {
            sign(txid, 0, msg.sender);
        }
    }

    function sign(uint32 txid, uint16 _proposalId, address signer) private {
        /*
          @dev: Sign a pending proposal or transaction.
        */
        if (txid > 0) {
            pendingTxs[txid].approvals[signer] = 1;
            pendingTxs[txid].numSigners += 1;
        } else {
            pendingProposals[_proposalId].approvals[signer] = 1;
            pendingProposals[_proposalId].numSigners += 1;
        }
    }

    function checkBalance(
        /*
          @dev: Function that checks if the balance of a token or native Eth is sufficient
          to process a withdrawal request. If it is not, the transaction will revert.
        */
        address tokenAddress,
        uint amount
        ) private view {
        if (tokenAddress == address(0)) {
            uint128 self;
            assembly {
                self :=selfbalance()
            }
            // make sure we have equity for this request
            require(self >= amount, INS_FUNDS_ERR);
        } else {
            require(IERC20(tokenAddress).balanceOf(address(this)) >= amount, INS_FUNDS_ERR);
        }
    }

    function encodeTransfer(
        /*
          @dev: View function that encodes calldata for an ERC20 token transfer.
        */
        address dest,
        uint256 amount
        ) public pure returns(bytes memory){
        return abi.encodeWithSignature(
                "transfer(address,uint256)",
                dest,
                amount
            );
    }

    function withdraw(
        /*
          @dev: The layer-2 friendly Ethervault version
          contains functionality to get price data from
          chainlink oracle and also has this seperate
          withdraw function for Ethereum and erc20 tokens.

          @dev: Initiate a new withdrawal. Logic flow:
          (Note: to save gas, the nonce also doubles as the TXID.)
           1) Check that we have balance to cover this transaction.
           2) Check if the dollar value requested amount of
           token/ether is below daily dollar allowance.
             yes) The transaction will be executed here and value added to `spentToday`.
             no)  The transaction requires the approval of `threshold` signatories,
                  so it will be queued pending approval.
        */

        address tokenAddress, // address(0) to specify Ethereum
        address destination,
        uint128 amount,
        uint32 _nonce
        /*
          @dev: encode transaction to transfer erc20 token
        */
    ) external protected(_nonce) checkPaused returns (uint32){
        checkBalance(tokenAddress, amount);
        if (underLimit(tokenAddress, amount)) {
            spentToday += uint128(getDollarValue(tokenAddress, amount));
            if (tokenAddress == address(0)) {
                execute(destination, amount, "");
            } else {
                execute(tokenAddress, 0, encodeTransfer(destination, amount));
            }
            return 0;
        } else {
            if (tokenAddress == address(0)) {
                return submitTx(msg.sender, destination, amount, "");
            } else {
                return submitTx(msg.sender, tokenAddress, 0, encodeTransfer(destination, amount));
            }
        }
    }

    function submitTx(
        /*
          Private function to add a transaction to the pending queue.
        */
        address proposer,
        address recipient,
        uint128 value,
        bytes memory data
        ) private returns(uint32) {
        txCount += 1;
        // requires approval from signatories -- not factored into daily allowance
        Transaction storage txObject = pendingTxs[txCount];
        (txObject.proposer, txObject.dest, txObject.value, txObject.data) = (proposer, recipient, value, data);
        sign(txCount, 0, proposer);
        return txCount;
    }

    function submitRawTx(
        /*
          @dev: Function that allows authorized signers to propose a new transaction
          with arbitrary parameters including custom data. Essentially this is an interface
          for `recipient.call{value: value}(data)`. Because it is possible to bypass withdrawal
          limits, any raw transaction requires authorization of additional signers.
        */
        address recipient,
        uint128 value,
        bytes memory data,
        uint32 _nonce

        ) external protected(_nonce) returns(uint32) {
        // gas efficient balance call
        checkBalance(address(0), value);
        return submitTx(msg.sender, recipient, value, data);

    }

    function getTokenDecimals(address tokenAddress) private view returns(uint8) {
        //uint decimals;
        if (tokenAddress == address(0)) {
            return 18;
        } else {
            return IERC20(tokenAddress).decimals();
        }
    }

    function getDollarValue(address tokenAddress, uint256 amount)
      /*
        @dev Convert arbitrary amount of token into a dollar amount.
      */
        public
        view
        returns (uint256)
    {
        uint decimals = getTokenDecimals(tokenAddress);
        (, int256 answer, , , ) = AggregatorV3Interface(trackedTokens[tokenAddress]).latestRoundData();
        uint price;
        if (decimals == 8) {
            price = uint(answer);
        }
        else if (decimals > 8) {
            price = (uint(answer) * (decimals - 8)**10);
        }
        else {
            price = uint(answer) / 10**(8 - decimals);
        }
        return (price * amount) / (10** decimals);
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
    }

    function underLimit(
        address tokenAddress,
        uint128 _value
        ) private returns (bool) {
        /*
          @dev: Function to determine whether or not a requested
          transaction's value is over the daily allowance and
          shall require additional confirmation or not. If it is
          a different day from the last time this ran, reset the
          allowance.
        */
        uint32 t = uint32(block.timestamp / 1 days);
        if (t > lastDay) {
            (spentToday, lastDay) = (0,t);
        }
        if (trackedTokens[tokenAddress] == address(0)) {
            // not tracking limits on this token, no limit
            return true;
        }
        uint dollarValue = getDollarValue(tokenAddress, _value) / (10**getTokenDecimals(tokenAddress));
        if (spentToday + dollarValue <= dailyLimit) {
            return true;
        } else {
            return false;}
    }



}

// SPDX-License-Identifier:MIT

pragma solidity ^0.8.16;

interface IERC20 {
	function totalSupply() external view returns (uint);
    function decimals() external view returns (uint8);
	function balanceOf(address account) external view returns (uint);
	function transfer(address recipient, uint amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint);
	function approve(address spender, uint amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier:MIT

pragma solidity ^0.8.16;


interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}