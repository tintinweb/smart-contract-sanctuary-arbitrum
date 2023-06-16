// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Structs.sol";
import {SignatureBuilder} from "./SignatureBuilder.sol";

contract RequestBuilder {
  // default value for namespace
  bytes16 public constant DEFAULT_NAMESPACE = bytes16(keccak256("main"));
  // default value for a signature request
  SignatureRequest DEFAULT_SIGNATURE_REQUEST =
    SignatureRequest({
      message: "MESSAGE_SELECTED_BY_USER",
      isSelectableByUser: false,
      extraData: ""
    });

  function build(
    AuthRequest memory auth,
    ClaimRequest memory claim,
    SignatureRequest memory signature,
    bytes16 namespace
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    AuthRequest memory auth,
    ClaimRequest memory claim,
    bytes16 namespace
  ) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    ClaimRequest memory claim,
    SignatureRequest memory signature,
    bytes16 namespace
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    ClaimRequest memory claim,
    bytes16 namespace
  ) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    AuthRequest memory auth,
    SignatureRequest memory signature,
    bytes16 namespace
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    AuthRequest memory auth,
    bytes16 namespace
  ) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    AuthRequest memory auth,
    ClaimRequest memory claim,
    SignatureRequest memory signature
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    AuthRequest memory auth,
    ClaimRequest memory claim
  ) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    AuthRequest memory auth,
    SignatureRequest memory signature
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(AuthRequest memory auth) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    ClaimRequest memory claim,
    SignatureRequest memory signature
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(ClaimRequest memory claim) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  // build with arrays for auths and claims
  function build(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature,
    bytes16 namespace
  ) external pure returns (SismoConnectRequest memory) {
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    bytes16 namespace
  ) external view returns (SismoConnectRequest memory) {
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    ClaimRequest[] memory claims,
    SignatureRequest memory signature,
    bytes16 namespace
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    ClaimRequest[] memory claims,
    bytes16 namespace
  ) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    AuthRequest[] memory auths,
    SignatureRequest memory signature,
    bytes16 namespace
  ) external pure returns (SismoConnectRequest memory) {
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    AuthRequest[] memory auths,
    bytes16 namespace
  ) external view returns (SismoConnectRequest memory) {
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature
  ) external pure returns (SismoConnectRequest memory) {
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims
  ) external view returns (SismoConnectRequest memory) {
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    AuthRequest[] memory auths,
    SignatureRequest memory signature
  ) external pure returns (SismoConnectRequest memory) {
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(AuthRequest[] memory auths) external view returns (SismoConnectRequest memory) {
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    ClaimRequest[] memory claims,
    SignatureRequest memory signature
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(ClaimRequest[] memory claims) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct SismoConnectRequest {
  bytes16 namespace;
  AuthRequest[] auths;
  ClaimRequest[] claims;
  SignatureRequest signature;
}

struct SismoConnectConfig {
  bytes16 appId;
  VaultConfig vault;
}

struct VaultConfig {
  bool isImpersonationMode;
}

struct AuthRequest {
  AuthType authType;
  uint256 userId; // default: 0
  // flags
  bool isAnon; // default: false -> true not supported yet, need to throw if true
  bool isOptional; // default: false
  bool isSelectableByUser; // default: true
  //
  bytes extraData; // default: ""
}

struct ClaimRequest {
  ClaimType claimType; // default: GTE
  bytes16 groupId;
  bytes16 groupTimestamp; // default: bytes16("latest")
  uint256 value; // default: 1
  // flags
  bool isOptional; // default: false
  bool isSelectableByUser; // default: true
  //
  bytes extraData; // default: ""
}

struct SignatureRequest {
  bytes message; // default: "MESSAGE_SELECTED_BY_USER"
  bool isSelectableByUser; // default: false
  bytes extraData; // default: ""
}

enum AuthType {
  VAULT,
  GITHUB,
  TWITTER,
  EVM_ACCOUNT,
  TELEGRAM,
  DISCORD
}

enum ClaimType {
  GTE,
  GT,
  EQ,
  LT,
  LTE
}

struct Auth {
  AuthType authType;
  bool isAnon;
  bool isSelectableByUser;
  uint256 userId;
  bytes extraData;
}

struct Claim {
  ClaimType claimType;
  bytes16 groupId;
  bytes16 groupTimestamp;
  bool isSelectableByUser;
  uint256 value;
  bytes extraData;
}

struct Signature {
  bytes message;
  bytes extraData;
}

struct SismoConnectResponse {
  bytes16 appId;
  bytes16 namespace;
  bytes32 version;
  bytes signedMessage;
  SismoConnectProof[] proofs;
}

struct SismoConnectProof {
  Auth[] auths;
  Claim[] claims;
  bytes32 provingScheme;
  bytes proofData;
  bytes extraData;
}

struct SismoConnectVerifiedResult {
  bytes16 appId;
  bytes16 namespace;
  bytes32 version;
  VerifiedAuth[] auths;
  VerifiedClaim[] claims;
  bytes signedMessage;
}

struct VerifiedAuth {
  AuthType authType;
  bool isAnon;
  uint256 userId;
  bytes extraData;
  bytes proofData;
}

struct VerifiedClaim {
  ClaimType claimType;
  bytes16 groupId;
  bytes16 groupTimestamp;
  uint256 value;
  bytes extraData;
  uint256 proofId;
  bytes proofData;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Structs.sol";

contract SignatureBuilder {
  // default values for Signature Request
  bytes public constant DEFAULT_SIGNATURE_REQUEST_MESSAGE = "MESSAGE_SELECTED_BY_USER";
  bool public constant DEFAULT_SIGNATURE_REQUEST_IS_SELECTABLE_BY_USER = false;
  bytes public constant DEFAULT_SIGNATURE_REQUEST_EXTRA_DATA = "";

  function build(bytes memory message) external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: message,
        isSelectableByUser: DEFAULT_SIGNATURE_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_SIGNATURE_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes memory message,
    bool isSelectableByUser
  ) external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: message,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_SIGNATURE_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes memory message,
    bytes memory extraData
  ) external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: message,
        isSelectableByUser: DEFAULT_SIGNATURE_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  function build(
    bytes memory message,
    bool isSelectableByUser,
    bytes memory extraData
  ) external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: message,
        isSelectableByUser: isSelectableByUser,
        extraData: extraData
      });
  }

  function build(bool isSelectableByUser) external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: DEFAULT_SIGNATURE_REQUEST_MESSAGE,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_SIGNATURE_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bool isSelectableByUser,
    bytes memory extraData
  ) external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: DEFAULT_SIGNATURE_REQUEST_MESSAGE,
        isSelectableByUser: isSelectableByUser,
        extraData: extraData
      });
  }

  function buildEmpty() external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: DEFAULT_SIGNATURE_REQUEST_MESSAGE,
        isSelectableByUser: DEFAULT_SIGNATURE_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_SIGNATURE_REQUEST_EXTRA_DATA
      });
  }
}