/**
 *Submitted for verification at Arbiscan on 2022-03-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma abicoder v2;

library BytesUtil {
    function memcpy(
        uint256 dest,
        uint256 src,
        uint256 len
    ) internal pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint256 mask = 256**(32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    function pointerToBytes(uint256 src, uint256 len)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory ret = new bytes(len);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }

        memcpy(retptr, src, len);
        return ret;
    }

    function addressToBytes(address a) internal pure returns (bytes memory b) {
        assembly {
            let m := mload(0x40)
            mstore(
                add(m, 20),
                xor(0x140000000000000000000000000000000000000000, a)
            )
            mstore(0x40, add(m, 52))
            b := m
        }
    }

    function uint256ToBytes(uint256 a) internal pure returns (bytes memory b) {
        assembly {
            let m := mload(0x40)
            mstore(add(m, 32), a)
            mstore(0x40, add(m, 64))
            b := m
        }
    }

    function doFirstParamEqualsAddress(bytes memory data, address _address)
        internal
        pure
        returns (bool)
    {
        if (data.length < (36 + 32)) {
            return false;
        }
        uint256 value;
        assembly {
            value := mload(add(data, 36))
        }
        return value == uint256(_address);
    }

    function doParamEqualsUInt256(
        bytes memory data,
        uint256 i,
        uint256 value
    ) internal pure returns (bool) {
        if (data.length < (36 + (i + 1) * 32)) {
            return false;
        }
        uint256 offset = 36 + i * 32;
        uint256 valuePresent;
        assembly {
            valuePresent := mload(add(data, offset))
        }
        return valuePresent == value;
    }

    function overrideFirst32BytesWithAddress(
        bytes memory data,
        address _address
    ) internal pure returns (bytes memory) {
        uint256 dest;
        assembly {
            dest := add(data, 48)
        } // 48 = 32 (offset) + 4 (func sig) + 12 (address is only 20 bytes)

        bytes memory addressBytes = addressToBytes(_address);
        uint256 src;
        assembly {
            src := add(addressBytes, 32)
        }

        memcpy(dest, src, 20);
        return data;
    }

    function overrideFirstTwo32BytesWithAddressAndInt(
        bytes memory data,
        address _address,
        uint256 _value
    ) internal pure returns (bytes memory) {
        uint256 dest;
        uint256 src;

        assembly {
            dest := add(data, 48)
        } // 48 = 32 (offset) + 4 (func sig) + 12 (address is only 20 bytes)
        bytes memory bbytes = addressToBytes(_address);
        assembly {
            src := add(bbytes, 32)
        }
        memcpy(dest, src, 20);

        assembly {
            dest := add(data, 68)
        } // 48 = 32 (offset) + 4 (func sig) + 32 (next slot)
        bbytes = uint256ToBytes(_value);
        assembly {
            src := add(bbytes, 32)
        }
        memcpy(dest, src, 32);

        return data;
    }
}


library SigUtil {
    function recover(bytes32 hash, bytes memory sig)
        internal
        pure
        returns (address recovered)
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28);

        recovered = ecrecover(hash, v, r, s);
        require(recovered != address(0));
    }

    function recoverWithZeroOnFailure(bytes32 hash, bytes memory sig)
        internal
        pure
        returns (address)
    {
        if (sig.length != 65) {
            return (address(0));
        }

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes memory) {
        return abi.encodePacked("\x19Ethereum Signed Message:\n32", hash);
    }
}


/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}


contract MetaTxRelay {
    struct Call {
        address from;
        address to;
        bytes signature;
    }

    struct CallParams {
        address tokenContract;
        uint256 amount;
        uint256 nonce;
        uint256 expiry;
    }

    mapping(address => bool) public tokenAccepted;
    mapping(address => uint256) public nonce;

    address public relayer;
    address public governor;
    address public wallet;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            )
        );
    bytes32 public constant ERC20METATRANSACTION_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "ERC20MetaTransaction(address from,address to,address tokenContract,uint256 amount,uint256 nonce,uint256 expiry)"
            )
        );

    event MetaTx(address indexed _from, uint256 indexed _nonce);

    constructor(uint256 _chainId) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256("MetaTxRelay"),
                keccak256("1.0.0"),
                _chainId,
                address(this)
            )
        );
        relayer = msg.sender;
        governor = msg.sender;
        wallet = msg.sender;
    }

    function executeMetaTransaction(
        Call memory _callData,
        CallParams memory _callParams
    ) public {
        require(tokenAccepted[_callParams.tokenContract], "Token not accepted");
        require(msg.sender == relayer, "Only relayer.");
        require(block.timestamp < _callParams.expiry, "Sig expired");
        require(
            nonce[_callData.from] + 1 == _callParams.nonce,
            "Bad signature nonce"
        );
        require(_callData.to == wallet, "Can only send to cipay");

        bytes memory dataToHash = abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(
                abi.encode(
                    ERC20METATRANSACTION_TYPEHASH,
                    _callData.from,
                    _callData.to,
                    _callParams.tokenContract,
                    _callParams.amount,
                    _callParams.nonce,
                    _callParams.expiry
                )
            )
        );
        require(
            SigUtil.recover(keccak256(dataToHash), _callData.signature) ==
                _callData.from,
            "signer != from"
        );
        nonce[_callData.from] = _callParams.nonce;
        ERC20 tokenContract = ERC20(_callParams.tokenContract);
        require(
            tokenContract.transferFrom(
                _callData.from,
                _callData.to,
                _callParams.amount
            ),
            "ERC20_TRANSFER_FAILED"
        );

        emit MetaTx(_callData.from, _callParams.nonce);
    }

    function setGovernor(address _governor) external {
        require(msg.sender == governor, "Only governor");
        governor = _governor;
    }

    function setTokenAccepted(address _tokenAddr, bool _accepted) external {
        require(msg.sender == governor, "Only governor");
        tokenAccepted[_tokenAddr] = _accepted;
    }

    function setWallet(address _wallet) external {
        require(msg.sender == governor, "Only governor");
        wallet = _wallet;
    }

    function recover(Call memory _callData, CallParams memory _callParams)
        external
        view
        returns (address)
    {
        bytes memory dataToHash = abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(
                abi.encode(
                    ERC20METATRANSACTION_TYPEHASH,
                    _callData.from,
                    _callData.to,
                    _callParams.tokenContract,
                    _callParams.amount,
                    _callParams.nonce,
                    _callParams.expiry
                )
            )
        );
        return SigUtil.recover(keccak256(dataToHash), _callData.signature);
    }
}