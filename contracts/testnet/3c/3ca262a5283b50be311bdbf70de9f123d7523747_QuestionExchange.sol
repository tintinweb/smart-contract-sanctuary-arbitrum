// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { Owned } from "solmate/auth/Owned.sol";
import { ReentrancyGuard } from "solmate/utils/ReentrancyGuard.sol";

/// @title QuestionExchange
/// @notice A contract allowing users to pay to have questions answered by other users
contract QuestionExchange is Owned, ReentrancyGuard {
    /// fee percentage up to 2 decimal places (1% = 100, 0.1% = 10, 0.01% = 1)
    uint8 public askFeePercentage;
    uint8 public answerFeePercentage;
    address public feeReceiver;

    enum QuestionStatus{ NONE, ASKED, ANSWERED, EXPIRED }

    struct Question {
        QuestionStatus status;
        string questionUrl;
        string answerUrl;
        address bidToken;
        uint256 bidAmount;
        uint256 expiresAt;
        address asker;
    }

    mapping(address => mapping(uint256 => Question)) public questions;
    mapping(address => uint256) public questionCounts;
    mapping(address => string) public profileUrls;

    mapping(address => uint256) public lockedAmounts;
    /// @notice emitted when a question is asked
    event Asked(
        address indexed answerer,
        address indexed asker,
        uint256 indexed questionId
    );

    /// @notice emitted when a question is answered
    event Answered(
        address indexed answerer,
        address indexed asker,
        uint256 indexed questionId
    );

    /// @notice emitted when a question is expired
    event Expired(
        address indexed answerer,
        address indexed asker,
        uint256 indexed questionId
    );

    /// @notice emitted when the fee receiver is set
    event FeeReceiverSet(
        address indexed feeReceiver
    );

    /// @notice emitted when the fee receiver is set
    event AskFeePercentageSet(
        uint8 indexed askFeePercentage
    );

    /// @notice emitted when the fee receiver is set
    event AnswerFeePercentageSet(
        uint8 indexed answerFeePercentage
    );

    /// @notice emitted when the fee receiver is set
    event ProfileUrlSet(
        address indexed profileAddress,
        string indexed profileUrl
    );

    /// @notice thrown when providing an empty question
    error EmptyQuestion();

    /// @notice thrown when attempting to action a question with the wrong status
    error InvalidStatus();

    /// @notice thrown when attempting to expire a question is answered or not yet expired
    error NotExpired();

    /// @notice thrown when attempting to claim an expired question that is already claimed
    error ExpiryClaimed();

    /// @notice thrown when answering a question that is expired
    error QuestionExpired();

    /// @notice thrown when providing an empty answer
    error EmptyAnswer();

    /// @notice thrown when attempting to expire a question that sender did not ask
    error NotAsker();

    /// @notice thrown when attempting to send ETH to this contract via fallback method
    error FallbackNotPayable();
    
    /// @notice thrown when attempting to send ETH to this contract via receive method
    error ReceiveNotPayable();

    constructor(uint8 _askFeePercentage, uint8 _answerFeePercentage) Owned(msg.sender) {
        askFeePercentage = _askFeePercentage;
        answerFeePercentage = _answerFeePercentage;
        feeReceiver = owner;
    }

    function ask(
        address answerer,
        address asker,
        string memory questionUrl,
        address bidToken,
        uint256 bidAmount,
        uint256 expiresAt
    ) public nonReentrant {
        uint256 nextQuestionId = questionCounts[answerer];
        questionCounts[answerer] = nextQuestionId + 1;

        questions[answerer][nextQuestionId] = Question({
            status: QuestionStatus.ASKED,
            questionUrl: questionUrl,
            bidToken: bidToken,
            bidAmount: bidAmount,
            expiresAt: expiresAt,
            asker: asker,
            answerUrl: ''
        });

        if(bidAmount != 0) {
            lockedAmounts[bidToken] += bidAmount;

            ERC20(bidToken).transferFrom(msg.sender, address(this), bidAmount);
        }

        emit Asked(answerer, asker, nextQuestionId);
    }

    function answer(
        uint256 questionId,
        string memory answerUrl
    ) public nonReentrant {
        Question storage question = questions[msg.sender][questionId];
        if(question.status != QuestionStatus.ASKED) revert InvalidStatus();
        if(question.expiresAt <= block.timestamp) revert QuestionExpired();

        question.answerUrl = answerUrl;
        question.status = QuestionStatus.ANSWERED;

        if(question.bidAmount != 0) {
            lockedAmounts[question.bidToken] -= question.bidAmount;
            uint256 feeAmount = answerFeePercentage == 0 
                ? 0
                : question.bidAmount * answerFeePercentage / 10000; // answerFeePercentage is normalised to 2 decimals

            ERC20(question.bidToken).transfer(msg.sender, question.bidAmount - feeAmount);
            ERC20(question.bidToken).transfer(feeReceiver, feeAmount);
        }

        emit Answered(msg.sender, question.asker, questionId);
    }

    function expire(
        address answerer,
        uint256 questionId
    ) public nonReentrant {
        Question storage question = questions[answerer][questionId];
        if(question.status != QuestionStatus.ASKED) revert InvalidStatus();
        if(question.expiresAt > block.timestamp) revert NotExpired();
        if(question.asker != msg.sender) revert NotAsker();

        question.status = QuestionStatus.EXPIRED;
        
        if(question.bidAmount != 0) {
            lockedAmounts[question.bidToken] -= question.bidAmount;

            uint256 feeAmount = question.bidAmount * askFeePercentage / 10000; // feePercentage is normalised to 2 decimals
            ERC20(question.bidToken).transfer(question.asker, question.bidAmount - feeAmount);
            ERC20(question.bidToken).transfer(feeReceiver, feeAmount);
        }

        emit Expired(answerer, msg.sender, questionId);
    }

    function setAskFeePercentage(uint8 newAskFeePercentage) public onlyOwner {
        askFeePercentage = newAskFeePercentage;
        emit AskFeePercentageSet(newAskFeePercentage);
    }

    function setAnswerFeePercentage(uint8 newAnswerFeePercentage) public onlyOwner {
        answerFeePercentage = newAnswerFeePercentage;
        emit AnswerFeePercentageSet(newAnswerFeePercentage);
    }

    function setFeeReceiver(address newFeeReceiver) public onlyOwner {
        feeReceiver = newFeeReceiver;
        emit FeeReceiverSet(newFeeReceiver);
    }

    function setProfileUrl(string memory newProfileUrl) public {
        profileUrls[msg.sender] = newProfileUrl;
        emit ProfileUrlSet(msg.sender, newProfileUrl);
    }

    function rescueTokens(address tokenAddress) public {
        uint256 totalBalance = ERC20(tokenAddress).balanceOf(address(this));

        ERC20(tokenAddress).transfer(owner, totalBalance - lockedAmounts[tokenAddress]);
    }

    /// @notice prevents ETH being sent directly to this contract
    fallback() external {
        // ETH received with no msg.data
        revert FallbackNotPayable();
    }

    /// @notice prevents ETH being sent directly to this contract
    receive() external payable {
        // ETH received with msg.data that does not match any contract function
        revert ReceiveNotPayable();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}