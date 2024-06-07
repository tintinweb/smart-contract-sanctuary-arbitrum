// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./SignerRole.sol";
import "./IERC20.sol";
import "./TransferHelper.sol";

// multi chain version of vault
contract VaultV2 is Context, SignerRole, Ownable, Pausable {
    using SafeMath for uint256;

    uint256 private _expiredTime;
    mapping(uint256 => bool) private _signatureId;    
    mapping(address => uint256) private _depositedAmounts;
    mapping(address => bool) private _tokenEnable;

    /// @notice A list of all tokenAddresses
    address[] public allTokens;

    //prevent reentrancy attack
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    event Claim(uint256 id, address tokenAddress, address to, uint256 amount, uint256 timestamp);
    event UserDeposit(address from, address tokenAddress, uint256 amount);
    event SetToken(address tokenAddr, bool isEnabled);

    event PaymentReceived(address from, uint256 amount);

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    // verified
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "rc");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    modifier tokenEnabled(address tokenAddress) {
        require(_tokenEnable[tokenAddress], "mdnd");
        _;
    }

    constructor(address signer) {
        _addSigner(signer);
        _expiredTime = 60;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function deposit(uint256 amount, address tokenAddr) external tokenEnabled(tokenAddr) nonReentrant whenNotPaused {
        TransferHelper.safeTransferFrom(address(tokenAddr), _msgSender(), address(this), amount);
        _depositedAmounts[_msgSender()] = _depositedAmounts[_msgSender()].add(amount);
        emit UserDeposit(_msgSender(), address(tokenAddr), amount);
    }

    function claim(
        uint256 id,
        address token,
        uint256 amount,
        uint256 timestamp,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant whenNotPaused {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        require(
            isSigner(
                ecrecover(
                    toEthSignedMessageHash(
                        keccak256(abi.encodePacked(this, id, _msgSender(), token, chainId, amount, timestamp))
                    ),
                    v,
                    r,
                    s
                )
            ),
            "owner should sign token amount"
        );
        require(_signatureId[id] == false, "cse");
        _signatureId[id] = true;
        require(timestamp > block.timestamp.sub(_expiredTime), "the claim was expired");

        TransferHelper.safeTransfer(token, _msgSender(), amount);
        emit Claim(id, token, _msgSender(), amount, timestamp);
    }

    function enableToken(address newTokenAddr) external onlyOwner {        
        require(!_tokenEnable[newTokenAddr], "ete");
        allTokens.push(newTokenAddr);
        _tokenEnable[newTokenAddr] = true;
        emit SetToken(newTokenAddr, true);
    }

    function disableToken(address tokenAddr) external onlyOwner {
        _tokenEnable[tokenAddr] = false;
        emit SetToken(tokenAddr, false);
    }

    function getAllTokens() public view returns (address[] memory) {
        return allTokens;
    }

    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}