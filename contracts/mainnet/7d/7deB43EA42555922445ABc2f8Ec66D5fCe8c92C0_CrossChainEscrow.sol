// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract EIP712 {
    // --- Public fields ---

    bytes32 public immutable DOMAIN_SEPARATOR;

    // --- Constructor ---

    constructor(bytes memory name, bytes memory version) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain("
                    "string name,"
                    "string version,"
                    "uint256 chainId,"
                    "address verifyingContract"
                    ")"
                ),
                keccak256(name),
                keccak256(version),
                chainId,
                address(this)
            )
        );
    }

    // --- Internal methods ---

    function getEIP712Hash(
        bytes32 structHash
    ) internal view returns (bytes32 eip712Hash) {
        eip712Hash = keccak256(
            abi.encodePacked(hex"1901", DOMAIN_SEPARATOR, structHash)
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IEIP1271} from "../interfaces/IEIP1271.sol";

contract SignatureVerifier {
    // --- Errors ---

    error InvalidSignature();

    // --- Internal methods ---

    function verifySignature(
        address signer,
        bytes32 eip712Hash,
        bytes calldata signature
    ) internal view {
        if (signer.code.length == 0) {
            (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

            address actualSigner = ecrecover(eip712Hash, v, r, s);
            if (actualSigner == address(0) || actualSigner != signer) {
                revert InvalidSignature();
            }
        } else {
            if (
                IEIP1271(signer).isValidSignature(eip712Hash, signature) !=
                IEIP1271.isValidSignature.selector
            ) {
                revert InvalidSignature();
            }
        }
    }

    function splitSignature(
        bytes calldata signature
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        uint256 length = signature.length;
        if (length == 65) {
            assembly {
                r := calldataload(signature.offset)
                s := calldataload(add(signature.offset, 0x20))
                v := byte(0, calldataload(add(signature.offset, 0x40)))
            }
        } else if (length == 64) {
            assembly {
                r := calldataload(signature.offset)
                let vs := calldataload(add(signature.offset, 0x20))
                s := and(
                    vs,
                    0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                )
                v := add(shr(255, vs), 27)
            }
        } else {
            revert InvalidSignature();
        }

        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert InvalidSignature();
        }

        if (v != 27 && v != 28) {
            revert InvalidSignature();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EIP712} from "./common/EIP712.sol";
import {SignatureVerifier} from "./common/SignatureVerifier.sol";

contract CrossChainEscrow is EIP712, SignatureVerifier {
    // --- Structs ---

    struct Request {
        bool isCollectionRequest;
        address maker;
        address solver;
        address token;
        uint256 tokenId;
        uint256 amount;
        uint256 price;
        address recipient;
        uint256 chainId;
        uint256 deadline;
        uint256 salt;
    }

    struct RequestStatus {
        bool isExecuted;
        bool isPrevalidated;
    }

    struct Withdraw {
        address solver;
        address user;
        uint256 amount;
        uint256 deadline;
        uint256 salt;
    }

    struct WithdrawStatus {
        bool isExecuted;
    }

    // --- Events ---

    event Deposited(address user, address solver, uint256 amount);

    event RequestExecuted(bytes32 requestHash);
    event RequestPrevalidated(bytes32 requestHash, Request request);

    event WithdrawExecuted(
        bytes32 withdrawHash,
        address user,
        address solver,
        uint256 amount
    );

    // --- Errors ---

    error RequestIsExecuted();
    error RequestIsExpired();
    error RequestIsPrevalidated();

    error WithdrawIsExecuted();
    error WithdrawIsExpired();

    error Unauthorized();
    error UnsuccessfulCall();

    // --- Fields ---

    bytes32 public immutable REQUEST_TYPEHASH;
    bytes32 public immutable WITHDRAW_TYPEHASH;

    // Keep track of the user's deposited balance per solver
    mapping(address => mapping(address => uint256)) public perSolverBalance;

    // Keep track of request and withdraw statuses
    mapping(bytes32 => RequestStatus) public requestStatus;
    mapping(bytes32 => WithdrawStatus) public withdrawStatus;

    // --- Constructor ---

    constructor() EIP712("CrossChainEscrow", "1") {
        REQUEST_TYPEHASH = keccak256(
            abi.encodePacked(
                "Request(",
                "bool isCollectionRequest,",
                "address maker,",
                "address solver,",
                "address token,",
                "uint256 tokenId,",
                "uint256 amount,",
                "uint256 price,",
                "address recipient,",
                "uint256 chainId,",
                "uint256 deadline,",
                "uint256 salt"
                ")"
            )
        );

        WITHDRAW_TYPEHASH = keccak256(
            abi.encodePacked(
                "Withdraw(",
                "address solver,",
                "address user,",
                "uint256 amount,",
                "uint256 deadline,",
                "uint256 salt",
                ")"
            )
        );
    }

    // --- Public methods ---

    function deposit(address solver) public payable {
        perSolverBalance[msg.sender][solver] += msg.value;

        emit Deposited(msg.sender, solver, msg.value);
    }

    function prevalidate(Request memory request) public {
        address maker = request.maker;

        if (msg.sender != maker) {
            revert Unauthorized();
        }

        bytes32 requestHash = getRequestHash(request);
        RequestStatus memory status = requestStatus[requestHash];
        if (status.isExecuted) {
            revert RequestIsExecuted();
        }
        if (status.isPrevalidated) {
            revert RequestIsPrevalidated();
        }

        requestStatus[requestHash].isPrevalidated = true;

        emit RequestPrevalidated(requestHash, request);
    }

    function depositAndPrevalidate(
        address solver,
        Request calldata request
    ) external payable {
        deposit(solver);
        prevalidate(request);
    }

    function executeWithdraw(
        Withdraw calldata withdraw,
        bytes calldata signature
    ) external {
        address solver = withdraw.solver;
        address user = withdraw.user;
        uint256 amount = withdraw.amount;

        if (msg.sender != user) {
            revert Unauthorized();
        }

        if (withdraw.deadline < block.timestamp) {
            revert WithdrawIsExpired();
        }

        bytes32 withdrawHash = getWithdrawHash(withdraw);
        WithdrawStatus memory status = withdrawStatus[withdrawHash];
        if (status.isExecuted) {
            revert WithdrawIsExecuted();
        }

        bytes32 eip712Hash = getEIP712Hash(withdrawHash);
        verifySignature(solver, eip712Hash, signature);

        withdrawStatus[withdrawHash].isExecuted = true;

        perSolverBalance[user][solver] -= amount;
        send(user, amount);

        emit WithdrawExecuted(withdrawHash, user, solver, amount);
    }

    // --- Solver methods ---

    function executeRequest(
        Request calldata request,
        bytes calldata signature
    ) external {
        address solver = request.solver;
        address maker = request.maker;
        uint256 price = request.price;

        if (msg.sender != solver) {
            revert Unauthorized();
        }

        if (request.deadline < block.timestamp) {
            revert RequestIsExpired();
        }

        bytes32 requestHash = getRequestHash(request);
        RequestStatus memory status = requestStatus[requestHash];
        if (status.isExecuted) {
            revert RequestIsExecuted();
        }

        bytes32 eip712Hash = getEIP712Hash(requestHash);
        if (!status.isPrevalidated) {
            verifySignature(maker, eip712Hash, signature);
        }

        requestStatus[requestHash].isExecuted = true;

        perSolverBalance[maker][solver] -= price;
        send(solver, price);

        emit RequestExecuted(requestHash);
    }

    // --- View methods ---

    function getRequestHash(
        Request memory request
    ) public view returns (bytes32 requestHash) {
        requestHash = keccak256(
            abi.encode(
                REQUEST_TYPEHASH,
                request.isCollectionRequest,
                request.maker,
                request.solver,
                request.token,
                request.tokenId,
                request.amount,
                request.price,
                request.recipient,
                request.chainId,
                request.deadline,
                request.salt
            )
        );
    }

    function getWithdrawHash(
        Withdraw calldata withdraw
    ) public view returns (bytes32 withdrawHash) {
        withdrawHash = keccak256(
            abi.encode(
                WITHDRAW_TYPEHASH,
                withdraw.solver,
                withdraw.user,
                withdraw.amount,
                withdraw.deadline,
                withdraw.salt
            )
        );
    }

    // --- Internal methods ---

    function send(address to, uint256 amount) internal {
        (bool result, ) = to.call{value: amount}("");
        if (!result) {
            revert UnsuccessfulCall();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IEIP1271 {
    function isValidSignature(
        bytes32 eip712Hash,
        bytes calldata signature
    ) external view returns (bytes4 magicValue);
}