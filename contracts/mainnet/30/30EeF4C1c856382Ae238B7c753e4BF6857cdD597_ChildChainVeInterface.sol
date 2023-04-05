// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;
contract ChildChainVeInterface {
    address public callproxy; // The Anycall contract we send cross chain messages too
    address public executor; // Anycall Executor Address for receiving calls from Mainnet
    address public base; // Child Chain Solid
    address public voter; // Child Chain Voter contract 
    address public nftBridge; // Parent chain NFT Bridge contract
    uint256 public chainId; // What chain are we on? 
    uint256 public epoch; // Current epoch on mainnet will be same on child chain
    uint256 public totalSupply; // Total supply on mainnet will be same on child chain

    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    struct UserInfo { 
        address ownerOf;
        uint256 firstEpoch;
        uint256 amount;
    }

    mapping(uint => uint) public attachments; // Is the nft attached to any gauges? 
    mapping (uint256 => UserInfo) public userInfo; // Mapping user tokenId to their ChildChain UserInfo

    event Attach(address indexed owner, address indexed gauge, uint256 tokenId);
    event Detach(address indexed owner, address indexed gauge, uint256 tokenId);
    event SetAnycall(address oldProxy, address newProxy, address oldExec, address newExec);
    event Error();

    function initialize (
        address _callproxy,
        address _executor,
        address _voter,
        address _nftBridge,
        address _base,
        uint256 _chainId
    ) external {}

    function voted(uint256 _tokenId) public view returns (bool isVoted) {}

    function balanceOfNFT(uint256 _tokenId) public view returns (uint256) {}

    function isApprovedOrOwner(address _user, uint256 _tokenId) external view returns (bool) {}

    function attachTokenToGauge(uint256 _tokenId, address _account) external {}

    function detachTokenFromGauge(uint256 _tokenId, address _account) external {}

    /// Bridged nft execution from mainnet and NFT Burn. anyExecute Callable only by anycall executor ///
    function anyExecute(bytes calldata data) external returns (bool success, bytes memory result) {}   

    function _exec(bytes memory _data) public returns (bool success, bytes memory result) {}

    function burn(uint256 _tokenId) external payable {}

    /// Setters /// 
    function setAnycallAddresses(address _proxy, address _executor) external {}

     function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256
    ) internal pure {}
}