// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "../BaseVerification.sol";

contract AnyswapV4Verification is BaseVerifier {
    function bridgeERC20To(
        uint256 amount,
        uint256 toChainId,
        bytes32 metadata,
        address receiverAddress,
        address token,
        address wrapperTokenAddress
    ) external returns (SocketRequest memory) {
         return SocketRequest(amount, receiverAddress, toChainId, token, msg.sig);
    }

    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

abstract contract BaseVerifier {
    struct SocketRequest {
        uint256 amount;
        address recipient;
        uint256 toChainId;
        address token;
        bytes4 signature;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "../BaseVerification.sol";

contract HopL2Verifier is BaseVerifier{
    struct HopBridgeRequestData {
        // fees passed to relayer
        uint256 bonderFee;
        // The minimum amount received after attempting to swap in the destination AMM market. 0 if no swap is intended.
        uint256 amountOutMin;
        // The deadline for swapping in the destination AMM market. 0 if no swap is intended.
        uint256 deadline;
        // Minimum amount expected to be received or bridged to destination
        uint256 amountOutMinDestination;
        // deadline for bridging to destination
        uint256 deadlineDestination;
        // socket offchain created hash
        bytes32 metadata;
    }

    function bridgeERC20To(
        address receiverAddress,
        address token,
        address hopAMM,
        uint256 amount,
        uint256 toChainId,
        HopBridgeRequestData calldata hopBridgeRequestData
    ) external returns (SocketRequest memory) {
        return SocketRequest(amount, receiverAddress, toChainId, token, msg.sig);
    }

    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./utils/Ownable.sol";

error RouteIdNotFound();
error FailedToVerify();
error RouteIdNotMatched();
error AmountNotMatched();
error RecipientNotMatched();
error ToChainIdNotMatched();
error TokenNotMatched();
error SignatureNotMatched();

contract SocketVerifier is Ownable {
    address public socketGateway;

    mapping(uint32 => address) public routeIdsToVerifiers;

    struct SocketRequest {
        uint256 amount;
        address recipient;
        uint256 toChainId;
        address token;
        bytes4 signature;
    }

    struct UserRequest {
        uint32 routeId;
        bytes socketRequest;
    }

    struct UserRequestValidation {
        uint32 routeId;
        SocketRequest socketRequest;
    }

    constructor(address _owner, address _socketGateway) Ownable(_owner) {
        socketGateway = _socketGateway;
    }

    function parseCallData(
        bytes calldata callData
    ) public returns (UserRequest memory) {
        // get calldata signature from first 4 bytes
        uint32 routeId = uint32(bytes4(callData[0:4]));
        if (routeIdsToVerifiers[routeId] != address(0)) {
            (bool success, bytes memory socketRequest) = routeIdsToVerifiers[
                routeId
            ].call(callData[4:]);
            if (!success) {
                revert FailedToVerify();
            }
            return UserRequest(routeId, socketRequest);
        } else {
            revert RouteIdNotFound();
        }
    }

    function validateRotueId(
        bytes calldata callData,
        uint32 expectedRouteId
    ) external {
        uint32 routeId = uint32(bytes4(callData[0:4]));
        if (routeIdsToVerifiers[routeId] != address(0)) {
            if (routeId != expectedRouteId) {
                revert RouteIdNotMatched();
            }
        } else {
            revert RouteIdNotFound();
        }
    }

    function validateSocketRequest(
        bytes calldata callData,
        UserRequestValidation calldata expectedRequest
    ) external {
        UserRequest memory userRequest = parseCallData(callData);
        if (userRequest.routeId != expectedRequest.routeId) {
            revert RouteIdNotMatched();
        }

        SocketRequest memory socketRequest = abi.decode(
            userRequest.socketRequest,
            (SocketRequest)
        );

        if (socketRequest.amount != expectedRequest.socketRequest.amount) {
            revert AmountNotMatched();
        }
        if (
            socketRequest.recipient != expectedRequest.socketRequest.recipient
        ) {
            revert RecipientNotMatched();
        }
        if (
            socketRequest.toChainId != expectedRequest.socketRequest.toChainId
        ) {
            revert ToChainIdNotMatched();
        }
        if (socketRequest.token != expectedRequest.socketRequest.token) {
            revert TokenNotMatched();
        }
        if (
            socketRequest.signature != expectedRequest.socketRequest.signature
        ) {
            revert SignatureNotMatched();
        }
    }

    function addVerifier(uint32 routeId, address verifier) external onlyOwner {
        routeIdsToVerifiers[routeId] = verifier;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

error OnlyOwner();
error OnlyNominee();

abstract contract Ownable {
    address private _owner;
    address private _nominee;

    event OwnerNominated(address indexed nominee);
    event OwnerClaimed(address indexed claimer);

    constructor(address owner_) {
        _claimOwner(owner_);
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert OnlyOwner();
        }
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function nominee() public view returns (address) {
        return _nominee;
    }

    function nominateOwner(address nominee_) external {
        if (msg.sender != _owner) {
            revert OnlyOwner();
        }
        _nominee = nominee_;
        emit OwnerNominated(_nominee);
    }

    function claimOwner() external {
        if (msg.sender != _nominee) {
            revert OnlyNominee();
        }
        _claimOwner(msg.sender);
    }

    function _claimOwner(address claimer_) internal {
        _owner = claimer_;
        _nominee = address(0);
        emit OwnerClaimed(claimer_);
    }
}