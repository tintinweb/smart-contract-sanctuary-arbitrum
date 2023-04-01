// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Context.sol";
import "./IForwardRequest.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract EssentialERC2771Context is Context {
    address private _trustedForwarder;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "403");
        _;
    }

    modifier onlyForwarder() {
        require(isTrustedForwarder(msg.sender), "Counter:429");
        _;
    }

    constructor(address trustedForwarder) {
        owner = msg.sender;
        _trustedForwarder = trustedForwarder;
    }

    function setTrustedForwarder(address trustedForwarder) external onlyOwner {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(0x60, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 72];
        } else {
            return super._msgData();
        }
    }

    function _msgNFT() internal view returns (IForwardRequest.NFT memory) {
        uint256 chainId;
        uint256 tokenId;
        address contractAddress;
        if (isTrustedForwarder(msg.sender)) {
            assembly {
                chainId := calldataload(sub(calldatasize(), 104))
                contractAddress := shr(0x60, calldataload(sub(calldatasize(), 40)))
                tokenId := calldataload(sub(calldatasize(), 72))
            }
        }

        return IForwardRequest.NFT({contractAddress: contractAddress, tokenId: tokenId, chainId: chainId});
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IForwardRequest {
    struct ERC721ForwardRequest {
        address from; // Externally-owned account (EOA) signing the request.
        address authorizer; // Externally-owned account (EOA) that authorized from account in PlaySession.
        address to; // Destination address, normally a smart contract for an nFight game.
        address nftContract; // The address of the NFT contract for the token being used.
        uint256 nftTokenId; // The tokenId of the NFT being used
        uint256 nftChainId; // The chainId of the NFT neing used
        uint256 targetChainId; // The chainId where the Forwarder and implementation contract are deployed.
        uint256 value; // Amount of ether to transfer to the destination.
        uint256 gas; // Amount of gas limit to set for the execution.
        uint256 nonce; // On-chain tracked nonce of a transaction.
        bytes data; // (Call)data to be sent to the destination.
    }

    struct ForwardRequest {
        address from; // Externally-owned account (EOA) signing the request.
        address authorizer; // Externally-owned account (EOA) that authorized from account in PlaySession.
        address to; // Destination address, normally a smart contract for an nFight game.
        uint256 targetChainId; // The chainId where the Forwarder and implementation contract are deployed.
        uint256 value; // Amount of ether to transfer to the destination.
        uint256 gas; // Amount of gas limit to set for the execution.
        uint256 nonce; // On-chain tracked nonce of a transaction.
        bytes data; // (Call)data to be sent to the destination.
    }

    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    struct PlaySession {
        address authorized; // Burner EOA that is authorized to play with NFTs by owner EOA.
        uint256 expiresAt; // block timestamp when the session is invalidated.
    }

    struct NFT {
        address contractAddress;
        uint256 tokenId;
        uint256 chainId;
    }
}

interface IRandomizer {
		function request(uint256 callbackGasLimit) external returns (uint256);
		function request(uint256 callbackGasLimit, uint256 confirmations) external returns (uint256);
		function clientWithdrawTo(address _to, uint256 _amount) external;
	}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@xessential/contracts/fwd/EssentialERC2771Context.sol";
import "./IRandomizer.sol";

contract NFTGiveaway is EssentialERC2771Context {
    address public nftContract;
    uint256 public nftChainId;
    uint256 public endsAt;

    mapping(uint256 => address) public tokenEntries;
    mapping(address => uint16) public userEntries;
    address[] public entrants;
    address public winner;

    // VRF
    uint256 public randomId;
    IRandomizer public randomizer;

    constructor(address trustedForwarder, address _nftContract, uint256 _nftChainId, address _randomizer)
        EssentialERC2771Context(trustedForwarder)
    {
        nftContract = _nftContract;
        nftChainId = _nftChainId;
        endsAt = block.timestamp + 7 days;
        randomizer = IRandomizer(_randomizer);
    }

    // Convenience getter for frontend
    function giveawayInfo(address user) external view returns (uint256, uint16) {
        return (entrants.length, userEntries[user]);
    }

    function enterGiveaway() external onlyForwarder {
        require(block.timestamp < endsAt, "Giveaway has ended");

        IForwardRequest.NFT memory nft = _msgNFT();

        require(nft.chainId == nftChainId, "Invalid NFT chain ID");
        require(nft.contractAddress == nftContract, "Invalid NFT contract");
        require(tokenEntries[nft.tokenId] == address(0), "NFT already entered");

        tokenEntries[nft.tokenId] = _msgSender();
        entrants.push(_msgSender());
        unchecked {
            ++userEntries[_msgSender()];
        }
    }

    function clearRaffle() external {
        require(randomId == 0, "Already cleared");
        require(block.timestamp > endsAt, "Giveaway has not ended");

        uint256 requestId = randomizer.request(50000);

        randomId = requestId;
    }

    function randomizerCallback(uint256 _id, bytes32 _value) external {
        require(_id == randomId, "Wrong requestId");
        require(msg.sender == address(randomizer), "Caller not Randomizer");
        require(winner == address(0), "Already drawn");

        uint256 winnerIndex = uint256(_value) % entrants.length;
        winner = entrants[winnerIndex];
    }

    function randomizerWithdraw(uint256 amount) external onlyOwner {
        randomizer.clientWithdrawTo(msg.sender, amount);
    }
}