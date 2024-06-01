// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/security/Pausable.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "./SafeMath.sol";
import "./IERC1155WithCreators.sol";
import "./SignerRole.sol";
import "./Roles.sol";
import "./IERC20.sol";
import "./TransferHelper.sol";
import "./Initializable.sol";

// multi chain version of vault
contract StreamController is Initializable {
    using SafeMath for uint256;
    using Roles for Roles.Role;

    enum FundType {
        TIP,
        PPV,
        BOUNTY
    }
    enum BountyType {
        VIEWER,
        COMMENTOR
    }

    struct Bounty {
        uint256 totalAmount;
        uint256 reserveAmount;
        uint256 bountyAmount;
        uint32 countOfViewers; // decreased when claim
        uint32 countOfCommentors; // decreased when claim
        address tokenAddress;
    }

    // General state
    address public owner;
    bool public paused;
    Roles.Role private _signers;

    /// @notice bounty list for each stream nft
    mapping(uint256 => Bounty) public bounties;
    /// @notice ppvInfo for each stream nft
    // mapping(uint256 => PPVInfo) public ppvStreamInfo;
    /// @notice user can claim bounty one time only
    mapping(uint256 => mapping(address => bool)) public isClaimedBounty;
    /// @notice timestamp that user paid last for ppv
    mapping(uint256 => mapping(address => uint256)) public lastTimePaidPPV;
    mapping(uint256 => mapping(address => uint256)) public totalTips;

    mapping(address => bool) private _tokenEnable;
    /// @notice A list of all tokenAddresses
    address[] public allTokens;

    /// @notice prevent reentrancy attack
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    /// @notice global variables
    address public streamCollection;
    address public devWallet;

    uint256 private constant FEE_DENOMINATOR = 1000;
    uint256 private feeNumerator;

    /// @notice user can claim bounty one time only
    mapping(uint256 => mapping(address => bool)) public
        isClaimedBountyForViewers;
    /// @notice user can claim bounty one time only
    mapping(uint256 => mapping(address => bool)) public
        isClaimedBountyForCommentors;

    /// @notice events
    event SendFunds(
        uint256 tokenId,
        uint256 amount,
        uint256 timestamp,
        address from,
        address to,
        address tokenAddress,
        FundType fundType
    );
    event CreateBounty(
        uint256 tokenId,
        uint256 totalAmount,
        uint256 bountyAmount,
        uint256 timestamp,
        uint32 countOfViewers,
        uint32 countOfCommentors,
        address creator,
        address tokenAddress
    );
    event CreatePPVStream(
        uint256 tokenId,
        uint256 totalAmount,
        address creator,
        address tokenAddress
    );
    event ClaimBounty(
        uint256 tokenId,
        uint256 amount,
        uint256 timestamp,
        address tokenAddress,
        address to,
        BountyType bountyType
    );
    event SetToken(address tokenAddress, bool isEnabled);
    event PaymentReceived(address from, uint256 amount);

    /// @notice errors
    error NotStreamCreator();
    error InvalidBountyAmount();
    error InvalidPPVAmount();
    error InvalidStream();
    error InvalidPPVStream();
    error NotFunds();
    error NotSign();
    error Paused();
    error NotOwner();

    /// @notice user funds functions
    function sendFundsForPPV(
        uint256 tokenId,
        uint256 amount,
        address to,
        address tokenAddress
    ) external whitelisted(tokenAddress) whenNotPaused {
        if (msg.sender == to) revert NotFunds();
        uint256 feeAmount = (amount * feeNumerator) / FEE_DENOMINATOR;
        uint256 realAmount = amount - feeAmount;
        TransferHelper.safeTransferFrom(
            tokenAddress, msg.sender, to, realAmount
        );
        TransferHelper.safeTransferFrom(
            tokenAddress, msg.sender, devWallet, feeAmount
        );
        emit SendFunds(
            tokenId,
            amount,
            block.timestamp,
            msg.sender,
            to,
            tokenAddress,
            FundType.PPV
        );
    }

    function sendTip(
        uint256 tokenId,
        uint256 amount,
        address to,
        address tokenAddress
    ) external whitelisted(tokenAddress) whenNotPaused {
        if (msg.sender == to) revert NotFunds();
        TransferHelper.safeTransferFrom(tokenAddress, msg.sender, to, amount);
        emit SendFunds(
            tokenId,
            amount,
            block.timestamp,
            msg.sender,
            to,
            tokenAddress,
            FundType.TIP
        );
    }

    function mintWithBounty(
        uint256 id,
        uint256 timestamp,
        uint8 v,
        bytes32 r,
        bytes32 s,
        // uint256 supply,
        string memory uri,
        uint256 bountyAmount,
        uint32 countOfViewers, // decreased when claim
        uint32 countOfCommentors,
        address tokenAddress
    ) external {
        IERC1155WithCreators(streamCollection).mintFromController(
            id, timestamp, v, r, s, 1000, uri, msg.sender
        );
        createBounty(
            id, bountyAmount, countOfViewers, countOfCommentors, tokenAddress
        );
    }

    function createBounty(
        uint256 tokenId,
        uint256 bountyAmount,
        uint32 countOfViewers, // decreased when claim
        uint32 countOfCommentors,
        address tokenAddress
    ) public whitelisted(tokenAddress) whenNotPaused {
        uint256 _tokenId = tokenId;
        uint256 _bountyAmount = bountyAmount;
        uint32 _countOfViewers = countOfViewers;
        uint32 _countOfCommentors = countOfCommentors;
        address _tokenAddress = tokenAddress;
        if (
            IERC1155WithCreators(streamCollection).creators(_tokenId)
                != msg.sender
        ) revert NotStreamCreator();
        if (
            _bountyAmount == 0
                || (_countOfViewers == 0 && _countOfCommentors == 0)
        ) revert InvalidBountyAmount();
        uint256 totalAmount =
            _bountyAmount * (_countOfViewers + _countOfCommentors);
        Bounty memory bounty = Bounty({
            totalAmount: totalAmount,
            reserveAmount: totalAmount,
            bountyAmount: _bountyAmount,
            tokenAddress: _tokenAddress,
            countOfViewers: _countOfViewers,
            countOfCommentors: _countOfCommentors
        });
        bounties[_tokenId] = bounty;
        uint256 fee = (totalAmount * feeNumerator) / FEE_DENOMINATOR;
        TransferHelper.safeTransferFrom(
            _tokenAddress, msg.sender, address(this), totalAmount + fee
        );
        emit CreateBounty(
            _tokenId,
            totalAmount,
            _bountyAmount,
            block.timestamp,
            _countOfViewers,
            _countOfCommentors,
            msg.sender,
            _tokenAddress
        );
    }

    function claimBounty(
        uint256 tokenId,
        bytes32 r,
        bytes32 s,
        uint8 v,
        BountyType bountyType
    ) external nonReentrant whenNotPaused {
        uint256 chainId;
        uint256 _tokenId = tokenId;
        Bounty memory bounty = bounties[_tokenId];
        if (bounty.bountyAmount == 0) revert NotFunds();
        assembly {
            chainId := chainid()
        }
        if (
            !isSigner(
                ecrecover(
                    toEthSignedMessageHash(
                        keccak256(
                            abi.encodePacked(
                                this, msg.sender, chainId, _tokenId, bountyType
                            )
                        )
                    ),
                    v,
                    r,
                    s
                )
            )
        ) revert NotSign();

        if (bountyType == BountyType.VIEWER) {
            if (
                bounty.countOfViewers < 1
                    || isClaimedBountyForViewers[_tokenId][msg.sender]
            ) revert NotFunds();
            --bounties[_tokenId].countOfViewers;
            isClaimedBountyForViewers[_tokenId][msg.sender] = true;
        } else if (bountyType == BountyType.COMMENTOR) {
            if (
                bounty.countOfCommentors < 1
                    || isClaimedBountyForCommentors[_tokenId][msg.sender]
            ) revert NotFunds();
            --bounties[_tokenId].countOfCommentors;
            isClaimedBountyForCommentors[_tokenId][msg.sender] = true;
        }
        // isClaimedBounty[_tokenId][msg.sender] = true;
        TransferHelper.safeTransfer(
            bounty.tokenAddress, msg.sender, bounty.bountyAmount
        );
        emit ClaimBounty(
            tokenId,
            bounty.bountyAmount,
            block.timestamp,
            bounty.tokenAddress,
            msg.sender,
            bountyType
        );
    }

    /// @notice owner set functions
    function setPaused(bool pause) public onlyOwner {
        paused = pause;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function addSigner(address account) public onlySigner {
        _signers.add(account);
    }

    function renounceSigner() public {
        _signers.remove(msg.sender);
    }

    function isSigner(address account) public view returns (bool) {
        return _signers.has(account);
    }

    function init(
        address _owner,
        address _signer,
        address _streamCollectionAddress,
        address _devWallet,
        address[] calldata enabledTokens
    ) external initializer {
        feeNumerator = 100;
        owner = _owner;
        _signers.add(_signer);
        streamCollection = _streamCollectionAddress;
        devWallet = _devWallet;
        unchecked {
            for (uint256 i; i < enabledTokens.length;) {
                allTokens.push(enabledTokens[i]);
                _tokenEnable[enabledTokens[i]] = true;
                emit SetToken(enabledTokens[i], true);
                ++i;
            }
        }
    }

    function setStreamCollection(address _streamCollectionAddress)
        external
        onlyOwner
    {
        streamCollection = _streamCollectionAddress;
    }

    function setDevWallet(address _devWallet) external onlyOwner {
        devWallet = _devWallet;
    }

    function setFee(uint256 _feeNumerator) external onlyOwner {
        feeNumerator = _feeNumerator;
    }

    function enableToken(address newTokenAddr) external onlyOwner {
        require(!_tokenEnable[newTokenAddr], "ete");
        allTokens.push(newTokenAddr);
        _tokenEnable[newTokenAddr] = true;
        emit SetToken(newTokenAddr, true);
    }

    function disableToken(address tokenAddress) external onlyOwner {
        _tokenEnable[tokenAddress] = false;
        emit SetToken(tokenAddress, false);
    }

    function getAllTokens() public view returns (address[] memory) {
        return allTokens;
    }

    receive() external payable virtual {
        emit PaymentReceived(msg.sender, msg.value);
    }

    /// @notice modifiers
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "rc");
        _status = _ENTERED;

        _;
        _status = _NOT_ENTERED;
    }

    modifier whitelisted(address tokenAddress) {
        require(_tokenEnable[tokenAddress], "mdnd");
        _;
    }

    // Modifiers
    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }
    // Admin functions

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlySigner() {
        require(
            _signers.has(msg.sender),
            "SignerRole: caller does not have the Signer role"
        );
        _;
    }

    /// utility functions
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
    }
}