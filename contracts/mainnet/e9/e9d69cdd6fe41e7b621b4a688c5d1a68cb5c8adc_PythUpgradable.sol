/**
 *Submitted for verification at Arbiscan on 2023-08-03
*/

pragma solidity ^0.8.0;


library UnsafeBytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    ) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            
            
            tempBytes := mload(0x40)

            
            
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            
            
            
            let mc := add(tempBytes, 0x20)
            
            
            let end := add(mc, length)

            for {
                
                
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                
                
                mstore(mc, mload(cc))
            }

            
            
            
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            
            
            mc := end
            
            
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            
            
            
            
            
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) 
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    ) internal {
        assembly {
            
            
            
            let fslot := sload(_preBytes.slot)
            
            
            
            
            
            
            
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            
            
            
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                
                
                
                sstore(
                    _preBytes.slot,
                    
                    
                    add(
                        
                        
                        fslot,
                        add(
                            mul(
                                div(
                                    
                                    mload(add(_postBytes, 0x20)),
                                    
                                    exp(0x100, sub(32, mlength))
                                ),
                                
                                
                                exp(0x100, sub(32, newlength))
                            ),
                            
                            
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                
                
                
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                
                
                
                
                
                
                
                

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                
                mstore(0x0, _preBytes.slot)
                
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                
                
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                
                
                tempBytes := mload(0x40)

                
                
                
                
                
                
                
                
                let lengthmod := and(_length, 31)

                
                
                
                
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    
                    
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                
                
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            
            default {
                tempBytes := mload(0x40)
                
                
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (address) {
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    function toUint8(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (uint8) {
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (uint16) {
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (uint32) {
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (uint64) {
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (uint96) {
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (uint128) {
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (uint256) {
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (bytes32) {
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(
        bytes memory _preBytes,
        bytes memory _postBytes
    ) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            
            switch eq(length, mload(_postBytes))
            case 1 {
                
                
                
                
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                    
                    
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    
                    if iszero(eq(mload(mc), mload(cc))) {
                        
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    ) internal view returns (bool) {
        bool success = true;

        assembly {
            
            let fslot := sload(_preBytes.slot)
            
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)

            
            switch eq(slength, mlength)
            case 1 {
                
                
                
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            
                            success := 0
                        }
                    }
                    default {
                        
                        
                        
                        
                        let cb := 1

                        
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        
                        
                        for {

                        } eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                
                success := 0
            }
        }

        return success;
    }
}

contract PythStructs {
    
    
    
    
    
    
    
    
    struct Price {
        
        int64 price;
        
        uint64 conf;
        
        int32 expo;
        
        uint publishTime;
    }

    
    struct PriceFeed {
        
        bytes32 id;
        
        Price price;
        
        Price emaPrice;
    }
}

interface IPythEvents {
    
    
    
    
    
    event PriceFeedUpdate(
        bytes32 indexed id,
        uint64 publishTime,
        int64 price,
        uint64 conf
    );

    
    
    
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);
}

interface IPyth is IPythEvents {
    
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    
    
    
    
    function getPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    
    
    
    
    function getEmaPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    
    
    
    
    
    
    
    
    function getPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    
    
    
    
    
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    
    
    
    
    
    
    
    
    
    
    
    function getEmaPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    
    
    
    
    
    
    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    
    
    
    
    
    
    
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    
    
    
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}

library PythErrors {
    
    
    error InvalidArgument();
    
    
    error InvalidUpdateDataSource();
    
    
    error InvalidUpdateData();
    
    
    error InsufficientFee();
    
    
    error NoFreshUpdate();
    
    
    error PriceFeedNotFoundWithinRange();
    
    
    error PriceFeedNotFound();
    
    
    error StalePrice();
    
    
    error InvalidWormholeVaa();
    
    
    error InvalidGovernanceMessage();
    
    
    error InvalidGovernanceTarget();
    
    
    error InvalidGovernanceDataSource();
    
    
    error OldGovernanceMessage();
    
    
    error InvalidWormholeAddressToSet();
}

abstract contract AbstractPyth is IPyth {
    
    
    
    function queryPriceFeed(
        bytes32 id
    ) public view virtual returns (PythStructs.PriceFeed memory priceFeed);

    
    
    function priceFeedExists(
        bytes32 id
    ) public view virtual returns (bool exists);

    function getValidTimePeriod()
        public
        view
        virtual
        override
        returns (uint validTimePeriod);

    function getPrice(
        bytes32 id
    ) external view virtual override returns (PythStructs.Price memory price) {
        return getPriceNoOlderThan(id, getValidTimePeriod());
    }

    function getEmaPrice(
        bytes32 id
    ) external view virtual override returns (PythStructs.Price memory price) {
        return getEmaPriceNoOlderThan(id, getValidTimePeriod());
    }

    function getPriceUnsafe(
        bytes32 id
    ) public view virtual override returns (PythStructs.Price memory price) {
        PythStructs.PriceFeed memory priceFeed = queryPriceFeed(id);
        return priceFeed.price;
    }

    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) public view virtual override returns (PythStructs.Price memory price) {
        price = getPriceUnsafe(id);

        if (diff(block.timestamp, price.publishTime) > age)
            revert PythErrors.StalePrice();

        return price;
    }

    function getEmaPriceUnsafe(
        bytes32 id
    ) public view virtual override returns (PythStructs.Price memory price) {
        PythStructs.PriceFeed memory priceFeed = queryPriceFeed(id);
        return priceFeed.emaPrice;
    }

    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) public view virtual override returns (PythStructs.Price memory price) {
        price = getEmaPriceUnsafe(id);

        if (diff(block.timestamp, price.publishTime) > age)
            revert PythErrors.StalePrice();

        return price;
    }

    function diff(uint x, uint y) internal pure returns (uint) {
        if (x > y) {
            return x - y;
        } else {
            return y - x;
        }
    }

    
    function updatePriceFeeds(
        bytes[] calldata updateData
    ) public payable virtual override;

    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable virtual override {
        if (priceIds.length != publishTimes.length)
            revert PythErrors.InvalidArgument();

        for (uint i = 0; i < priceIds.length; i++) {
            if (
                !priceFeedExists(priceIds[i]) ||
                queryPriceFeed(priceIds[i]).price.publishTime < publishTimes[i]
            ) {
                updatePriceFeeds(updateData);
                return;
            }
        }

        revert PythErrors.NoFreshUpdate();
    }

    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    )
        external
        payable
        virtual
        override
        returns (PythStructs.PriceFeed[] memory priceFeeds);
}

library UnsafeCalldataBytesLib {
    function slice(
        bytes calldata _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes calldata) {
        return _bytes[_start:_start + _length];
    }

    function sliceFrom(
        bytes calldata _bytes,
        uint256 _start
    ) internal pure returns (bytes calldata) {
        return _bytes[_start:_bytes.length];
    }

    function toAddress(
        bytes calldata _bytes,
        uint256 _start
    ) internal pure returns (address) {
        address tempAddress;

        assembly {
            tempAddress := shr(96, calldataload(add(_bytes.offset, _start)))
        }

        return tempAddress;
    }

    function toUint8(
        bytes calldata _bytes,
        uint256 _start
    ) internal pure returns (uint8) {
        uint8 tempUint;

        assembly {
            tempUint := shr(248, calldataload(add(_bytes.offset, _start)))
        }

        return tempUint;
    }

    function toUint16(
        bytes calldata _bytes,
        uint256 _start
    ) internal pure returns (uint16) {
        uint16 tempUint;

        assembly {
            tempUint := shr(240, calldataload(add(_bytes.offset, _start)))
        }

        return tempUint;
    }

    function toUint32(
        bytes calldata _bytes,
        uint256 _start
    ) internal pure returns (uint32) {
        uint32 tempUint;

        assembly {
            tempUint := shr(224, calldataload(add(_bytes.offset, _start)))
        }

        return tempUint;
    }

    function toUint64(
        bytes calldata _bytes,
        uint256 _start
    ) internal pure returns (uint64) {
        uint64 tempUint;

        assembly {
            tempUint := shr(192, calldataload(add(_bytes.offset, _start)))
        }

        return tempUint;
    }

    function toUint96(
        bytes calldata _bytes,
        uint256 _start
    ) internal pure returns (uint96) {
        uint96 tempUint;

        assembly {
            tempUint := shr(160, calldataload(add(_bytes.offset, _start)))
        }

        return tempUint;
    }

    function toUint128(
        bytes calldata _bytes,
        uint256 _start
    ) internal pure returns (uint128) {
        uint128 tempUint;

        assembly {
            tempUint := shr(128, calldataload(add(_bytes.offset, _start)))
        }

        return tempUint;
    }

    function toUint256(
        bytes calldata _bytes,
        uint256 _start
    ) internal pure returns (uint256) {
        uint256 tempUint;

        assembly {
            tempUint := calldataload(add(_bytes.offset, _start))
        }

        return tempUint;
    }

    function toBytes32(
        bytes calldata _bytes,
        uint256 _start
    ) internal pure returns (bytes32) {
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := calldataload(add(_bytes.offset, _start))
        }

        return tempBytes32;
    }
}

interface Structs {
    struct Provider {
        uint16 chainId;
        uint16 governanceChainId;
        bytes32 governanceContract;
    }

    struct GuardianSet {
        address[] keys;
        uint32 expirationTime;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 guardianIndex;
    }

    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;
        uint32 guardianSetIndex;
        Signature[] signatures;
        bytes32 hash;
    }
}

interface IWormhole is Structs {
    event LogMessagePublished(
        address indexed sender,
        uint64 sequence,
        uint32 nonce,
        bytes payload,
        uint8 consistencyLevel
    );

    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function parseAndVerifyVM(
        bytes calldata encodedVM
    )
        external
        view
        returns (Structs.VM memory vm, bool valid, string memory reason);

    function verifyVM(
        Structs.VM memory vm
    ) external view returns (bool valid, string memory reason);

    function verifySignatures(
        bytes32 hash,
        Structs.Signature[] memory signatures,
        Structs.GuardianSet memory guardianSet
    ) external pure returns (bool valid, string memory reason);

    function parseVM(
        bytes memory encodedVM
    ) external pure returns (Structs.VM memory vm);

    function getGuardianSet(
        uint32 index
    ) external view returns (Structs.GuardianSet memory);

    function getCurrentGuardianSetIndex() external view returns (uint32);

    function getGuardianSetExpiry() external view returns (uint32);

    function governanceActionIsConsumed(
        bytes32 hash
    ) external view returns (bool);

    function isInitialized(address impl) external view returns (bool);

    function chainId() external view returns (uint16);

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function messageFee() external view returns (uint256);
}

library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    ) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            
            
            tempBytes := mload(0x40)

            
            
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            
            
            
            let mc := add(tempBytes, 0x20)
            
            
            let end := add(mc, length)

            for {
                
                
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                
                
                mstore(mc, mload(cc))
            }

            
            
            
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            
            
            mc := end
            
            
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            
            
            
            
            
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) 
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    ) internal {
        assembly {
            
            
            
            let fslot := sload(_preBytes.slot)
            
            
            
            
            
            
            
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            
            
            
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                
                
                
                sstore(
                    _preBytes.slot,
                    
                    
                    add(
                        
                        
                        fslot,
                        add(
                            mul(
                                div(
                                    
                                    mload(add(_postBytes, 0x20)),
                                    
                                    exp(0x100, sub(32, mlength))
                                ),
                                
                                
                                exp(0x100, sub(32, newlength))
                            ),
                            
                            
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                
                
                
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                
                
                
                
                
                
                
                

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                
                mstore(0x0, _preBytes.slot)
                
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                
                
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                
                
                tempBytes := mload(0x40)

                
                
                
                
                
                
                
                
                let lengthmod := and(_length, 31)

                
                
                
                
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    
                    
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                
                
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            
            default {
                tempBytes := mload(0x40)
                
                
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    function toUint8(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(
        bytes memory _preBytes,
        bytes memory _postBytes
    ) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            
            switch eq(length, mload(_postBytes))
            case 1 {
                
                
                
                
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                    
                    
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    
                    if iszero(eq(mload(mc), mload(cc))) {
                        
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    ) internal view returns (bool) {
        bool success = true;

        assembly {
            
            let fslot := sload(_preBytes.slot)
            
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)

            
            switch eq(slength, mlength)
            case 1 {
                
                
                
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            
                            success := 0
                        }
                    }
                    default {
                        
                        
                        
                        
                        let cb := 1

                        
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        
                        
                        for {

                        } eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                
                success := 0
            }
        }

        return success;
    }
}

contract PythInternalStructs {
    using BytesLib for bytes;

    struct PriceInfo {
        
        uint64 publishTime;
        int32 expo;
        int64 price;
        uint64 conf;
        
        int64 emaPrice;
        uint64 emaConf;
    }

    struct DataSource {
        uint16 chainId;
        bytes32 emitterAddress;
    }
}

contract PythDeprecatedStructs {
    
    enum DeprecatedPriceStatusV1 {
        UNKNOWN,
        TRADING,
        HALTED,
        AUCTION
    }

    struct DeprecatedPriceFeedV1 {
        
        bytes32 id;
        
        bytes32 productId;
        
        int64 price;
        
        uint64 conf;
        
        int32 expo;
        
        DeprecatedPriceStatusV1 status;
        
        uint32 maxNumPublishers;
        
        uint32 numPublishers;
        
        int64 emaPrice;
        
        uint64 emaConf;
        
        uint64 publishTime;
        
        int64 prevPrice;
        
        uint64 prevConf;
        
        uint64 prevPublishTime;
    }

    struct DeprecatedPriceInfoV1 {
        uint256 attestationTime;
        uint256 arrivalTime;
        uint256 arrivalBlock;
        DeprecatedPriceFeedV1 priceFeed;
    }

    
    struct DeprecatedPriceV2 {
        
        int64 price;
        
        uint64 conf;
        
        int32 expo;
        
        uint publishTime;
    }

    
    struct DeprecatedPriceFeedV2 {
        
        bytes32 id;
        
        DeprecatedPriceV2 price;
        
        DeprecatedPriceV2 emaPrice;
    }

    struct DeprecatedPriceInfoV2 {
        uint256 attestationTime;
        uint256 arrivalTime;
        uint256 arrivalBlock;
        DeprecatedPriceFeedV2 priceFeed;
    }
}

contract PythStorage {
    struct State {
        address wormhole;
        uint16 _deprecatedPyth2WormholeChainId; 
        bytes32 _deprecatedPyth2WormholeEmitter; 
        
        mapping(bytes32 => PythDeprecatedStructs.DeprecatedPriceInfoV1) _deprecatedLatestPriceInfoV1;
        
        PythInternalStructs.DataSource[] validDataSources;
        
        
        mapping(bytes32 => bool) isValidDataSource;
        uint singleUpdateFeeInWei;
        
        
        
        uint validTimePeriodSeconds;
        
        
        PythInternalStructs.DataSource governanceDataSource;
        
        
        
        uint64 lastExecutedGovernanceSequence;
        
        mapping(bytes32 => PythDeprecatedStructs.DeprecatedPriceInfoV2) _deprecatedLatestPriceInfoV2;
        
        
        uint32 governanceDataSourceIndex;
        
        
        mapping(bytes32 => PythInternalStructs.PriceInfo) latestPriceInfo;
    }
}

contract PythState {
    PythStorage.State _state;
}

contract PythGetters is PythState {
    function wormhole() public view returns (IWormhole) {
        return IWormhole(_state.wormhole);
    }

    function latestPriceInfo(
        bytes32 priceId
    ) internal view returns (PythInternalStructs.PriceInfo memory info) {
        return _state.latestPriceInfo[priceId];
    }

    function latestPriceInfoPublishTime(
        bytes32 priceId
    ) public view returns (uint64) {
        return _state.latestPriceInfo[priceId].publishTime;
    }

    function hashDataSource(
        PythInternalStructs.DataSource memory ds
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(ds.chainId, ds.emitterAddress));
    }

    function isValidDataSource(
        uint16 dataSourceChainId,
        bytes32 dataSourceEmitterAddress
    ) public view returns (bool) {
        return
            _state.isValidDataSource[
                keccak256(
                    abi.encodePacked(
                        dataSourceChainId,
                        dataSourceEmitterAddress
                    )
                )
            ];
    }

    function isValidGovernanceDataSource(
        uint16 governanceChainId,
        bytes32 governanceEmitterAddress
    ) public view returns (bool) {
        return
            _state.governanceDataSource.chainId == governanceChainId &&
            _state.governanceDataSource.emitterAddress ==
            governanceEmitterAddress;
    }

    function chainId() public view returns (uint16) {
        return wormhole().chainId();
    }

    function lastExecutedGovernanceSequence() public view returns (uint64) {
        return _state.lastExecutedGovernanceSequence;
    }

    function validDataSources()
        public
        view
        returns (PythInternalStructs.DataSource[] memory)
    {
        return _state.validDataSources;
    }

    function governanceDataSource()
        public
        view
        returns (PythInternalStructs.DataSource memory)
    {
        return _state.governanceDataSource;
    }

    function singleUpdateFeeInWei() public view returns (uint) {
        return _state.singleUpdateFeeInWei;
    }

    function validTimePeriodSeconds() public view returns (uint) {
        return _state.validTimePeriodSeconds;
    }

    function governanceDataSourceIndex() public view returns (uint32) {
        return _state.governanceDataSourceIndex;
    }
}

contract PythSetters is PythState {
    function setWormhole(address wh) internal {
        _state.wormhole = payable(wh);
    }

    function setLatestPriceInfo(
        bytes32 priceId,
        PythInternalStructs.PriceInfo memory info
    ) internal {
        _state.latestPriceInfo[priceId] = info;
    }

    function setSingleUpdateFeeInWei(uint fee) internal {
        _state.singleUpdateFeeInWei = fee;
    }

    function setValidTimePeriodSeconds(uint validTimePeriodSeconds) internal {
        _state.validTimePeriodSeconds = validTimePeriodSeconds;
    }

    function setGovernanceDataSource(
        PythInternalStructs.DataSource memory newDataSource
    ) internal {
        _state.governanceDataSource = newDataSource;
    }

    function setLastExecutedGovernanceSequence(uint64 sequence) internal {
        _state.lastExecutedGovernanceSequence = sequence;
    }

    function setGovernanceDataSourceIndex(uint32 newIndex) internal {
        _state.governanceDataSourceIndex = newIndex;
    }
}

library MerkleTree {
    uint8 constant MERKLE_LEAF_PREFIX = 0;
    uint8 constant MERKLE_NODE_PREFIX = 1;
    uint8 constant MERKLE_EMPTY_LEAF_PREFIX = 2;

    function hash(bytes memory input) internal pure returns (bytes20) {
        return bytes20(keccak256(input));
    }

    function emptyLeafHash() internal pure returns (bytes20) {
        return hash(abi.encodePacked(MERKLE_EMPTY_LEAF_PREFIX));
    }

    function leafHash(bytes memory data) internal pure returns (bytes20) {
        return hash(abi.encodePacked(MERKLE_LEAF_PREFIX, data));
    }

    function nodeHash(
        bytes20 childA,
        bytes20 childB
    ) internal pure returns (bytes20) {
        if (childA > childB) {
            (childA, childB) = (childB, childA);
        }
        return hash(abi.encodePacked(MERKLE_NODE_PREFIX, childA, childB));
    }

    
    
    
    
    
    
    
    
    function isProofValid(
        bytes calldata encodedProof,
        uint proofOffset,
        bytes20 root,
        bytes calldata leafData
    ) internal pure returns (bool valid, uint endOffset) {
        unchecked {
            bytes20 currentDigest = MerkleTree.leafHash(leafData);

            uint8 proofSize = UnsafeCalldataBytesLib.toUint8(
                encodedProof,
                proofOffset
            );
            proofOffset += 1;

            for (uint i = 0; i < proofSize; i++) {
                bytes20 siblingDigest = bytes20(
                    UnsafeCalldataBytesLib.toAddress(encodedProof, proofOffset)
                );
                proofOffset += 20;

                currentDigest = MerkleTree.nodeHash(
                    currentDigest,
                    siblingDigest
                );
            }

            valid = currentDigest == root;
            endOffset = proofOffset;
        }
    }

    
    
    
    
    
    
    
    
    function constructProofs(
        bytes[] memory messages,
        uint8 depth
    ) internal pure returns (bytes20 root, bytes[] memory proofs) {
        require((1 << depth) >= messages.length, "depth too small");

        bytes20[] memory tree = new bytes20[]((1 << (depth + 1)));

        
        
        
        
        
        
        
        

        
        bytes20 cachedEmptyLeafHash = emptyLeafHash();

        for (uint i = 0; i < (1 << depth); i++) {
            if (i < messages.length) {
                tree[(1 << depth) + i] = leafHash(messages[i]);
            } else {
                tree[(1 << depth) + i] = cachedEmptyLeafHash;
            }
        }

        
        for (uint k = depth; k > 0; k--) {
            uint level = k - 1;
            uint levelNumNodes = (1 << level);
            for (uint i = 0; i < levelNumNodes; i++) {
                uint id = (1 << level) + i;
                tree[id] = nodeHash(tree[id * 2], tree[id * 2 + 1]);
            }
        }

        root = tree[1];

        proofs = new bytes[](messages.length);

        for (uint i = 0; i < messages.length; i++) {
            
            proofs[i] = abi.encodePacked(depth);

            uint idx = (1 << depth) + i;

            
            
            while (idx > 1) {
                proofs[i] = abi.encodePacked(
                    proofs[i],
                    tree[idx ^ 1] 
                );

                
                idx /= 2;
            }
        }
    }
}

abstract contract PythAccumulator is PythGetters, PythSetters, AbstractPyth {
    uint32 constant ACCUMULATOR_MAGIC = 0x504e4155; 
    uint32 constant ACCUMULATOR_WORMHOLE_MAGIC = 0x41555756; 
    uint8 constant MINIMUM_ALLOWED_MINOR_VERSION = 0;
    uint8 constant MAJOR_VERSION = 1;

    enum UpdateType {
        WormholeMerkle
    }

    enum MessageType {
        PriceFeed
    }

    
    
    function parseAndVerifyPythVM(
        bytes calldata encodedVm
    ) internal view returns (IWormhole.VM memory vm) {
        {
            bool valid;
            (vm, valid, ) = wormhole().parseAndVerifyVM(encodedVm);
            if (!valid) revert PythErrors.InvalidWormholeVaa();
        }

        if (!isValidDataSource(vm.emitterChainId, vm.emitterAddress))
            revert PythErrors.InvalidUpdateDataSource();
    }

    function extractUpdateTypeFromAccumulatorHeader(
        bytes calldata accumulatorUpdate
    ) internal pure returns (uint offset, UpdateType updateType) {
        unchecked {
            offset = 0;

            {
                uint32 magic = UnsafeCalldataBytesLib.toUint32(
                    accumulatorUpdate,
                    offset
                );
                offset += 4;

                if (magic != ACCUMULATOR_MAGIC)
                    revert PythErrors.InvalidUpdateData();

                uint8 majorVersion = UnsafeCalldataBytesLib.toUint8(
                    accumulatorUpdate,
                    offset
                );

                offset += 1;

                if (majorVersion != MAJOR_VERSION)
                    revert PythErrors.InvalidUpdateData();

                uint8 minorVersion = UnsafeCalldataBytesLib.toUint8(
                    accumulatorUpdate,
                    offset
                );

                offset += 1;

                
                
                if (minorVersion < MINIMUM_ALLOWED_MINOR_VERSION)
                    revert PythErrors.InvalidUpdateData();

                
                
                uint8 trailingHeaderSize = UnsafeCalldataBytesLib.toUint8(
                    accumulatorUpdate,
                    offset
                );
                offset += 1;

                
                
                
                
                
                
                

                offset += trailingHeaderSize;
            }

            updateType = UpdateType(
                UnsafeCalldataBytesLib.toUint8(accumulatorUpdate, offset)
            );

            offset += 1;

            if (accumulatorUpdate.length < offset)
                revert PythErrors.InvalidUpdateData();
        }
    }

    function extractWormholeMerkleHeaderDigestAndNumUpdatesAndEncodedFromAccumulatorUpdate(
        bytes calldata accumulatorUpdate,
        uint encodedOffset
    )
        internal
        view
        returns (
            uint offset,
            bytes20 digest,
            uint8 numUpdates,
            bytes calldata encoded
        )
    {
        unchecked {
            encoded = UnsafeCalldataBytesLib.slice(
                accumulatorUpdate,
                encodedOffset,
                accumulatorUpdate.length - encodedOffset
            );
            offset = 0;

            uint16 whProofSize = UnsafeCalldataBytesLib.toUint16(
                encoded,
                offset
            );
            offset += 2;

            {
                bytes memory encodedPayload;
                {
                    IWormhole.VM memory vm = parseAndVerifyPythVM(
                        UnsafeCalldataBytesLib.slice(
                            encoded,
                            offset,
                            whProofSize
                        )
                    );
                    offset += whProofSize;

                    
                    
                    encodedPayload = vm.payload;
                }

                uint payloadOffset = 0;
                {
                    uint32 magic = UnsafeBytesLib.toUint32(
                        encodedPayload,
                        payloadOffset
                    );
                    payloadOffset += 4;

                    if (magic != ACCUMULATOR_WORMHOLE_MAGIC)
                        revert PythErrors.InvalidUpdateData();

                    UpdateType updateType = UpdateType(
                        UnsafeBytesLib.toUint8(encodedPayload, payloadOffset)
                    );
                    ++payloadOffset;

                    if (updateType != UpdateType.WormholeMerkle)
                        revert PythErrors.InvalidUpdateData();

                    
                    
                    payloadOffset += 8;

                    
                    
                    payloadOffset += 4;

                    digest = bytes20(
                        UnsafeBytesLib.toAddress(encodedPayload, payloadOffset)
                    );
                    payloadOffset += 20;

                    
                    if (payloadOffset > encodedPayload.length)
                        revert PythErrors.InvalidUpdateData();
                }
            }

            numUpdates = UnsafeCalldataBytesLib.toUint8(encoded, offset);
            offset += 1;
        }
    }

    function parseWormholeMerkleHeaderNumUpdates(
        bytes calldata wormholeMerkleUpdate,
        uint offset
    ) internal pure returns (uint8 numUpdates) {
        uint16 whProofSize = UnsafeCalldataBytesLib.toUint16(
            wormholeMerkleUpdate,
            offset
        );
        offset += 2;
        offset += whProofSize;
        numUpdates = UnsafeCalldataBytesLib.toUint8(
            wormholeMerkleUpdate,
            offset
        );
    }

    function extractPriceInfoFromMerkleProof(
        bytes20 digest,
        bytes calldata encoded,
        uint offset
    )
        internal
        pure
        returns (
            uint endOffset,
            PythInternalStructs.PriceInfo memory priceInfo,
            bytes32 priceId
        )
    {
        unchecked {
            bytes calldata encodedMessage;
            uint16 messageSize = UnsafeCalldataBytesLib.toUint16(
                encoded,
                offset
            );
            offset += 2;

            encodedMessage = UnsafeCalldataBytesLib.slice(
                encoded,
                offset,
                messageSize
            );
            offset += messageSize;

            bool valid;
            (valid, endOffset) = MerkleTree.isProofValid(
                encoded,
                offset,
                digest,
                encodedMessage
            );
            if (!valid) {
                revert PythErrors.InvalidUpdateData();
            }

            MessageType messageType = MessageType(
                UnsafeCalldataBytesLib.toUint8(encodedMessage, 0)
            );
            if (messageType == MessageType.PriceFeed) {
                (priceInfo, priceId) = parsePriceFeedMessage(encodedMessage, 1);
            } else {
                revert PythErrors.InvalidUpdateData();
            }

            return (endOffset, priceInfo, priceId);
        }
    }

    function parsePriceFeedMessage(
        bytes calldata encodedPriceFeed,
        uint offset
    )
        private
        pure
        returns (
            PythInternalStructs.PriceInfo memory priceInfo,
            bytes32 priceId
        )
    {
        unchecked {
            priceId = UnsafeCalldataBytesLib.toBytes32(
                encodedPriceFeed,
                offset
            );
            offset += 32;

            priceInfo.price = int64(
                UnsafeCalldataBytesLib.toUint64(encodedPriceFeed, offset)
            );
            offset += 8;

            priceInfo.conf = UnsafeCalldataBytesLib.toUint64(
                encodedPriceFeed,
                offset
            );
            offset += 8;

            priceInfo.expo = int32(
                UnsafeCalldataBytesLib.toUint32(encodedPriceFeed, offset)
            );
            offset += 4;

            
            
            
            
            priceInfo.publishTime = UnsafeCalldataBytesLib.toUint64(
                encodedPriceFeed,
                offset
            );
            offset += 8;

            
            
            offset += 8;

            priceInfo.emaPrice = int64(
                UnsafeCalldataBytesLib.toUint64(encodedPriceFeed, offset)
            );
            offset += 8;

            priceInfo.emaConf = UnsafeCalldataBytesLib.toUint64(
                encodedPriceFeed,
                offset
            );
            offset += 8;

            if (offset > encodedPriceFeed.length)
                revert PythErrors.InvalidUpdateData();
        }
    }

    function updatePriceInfosFromAccumulatorUpdate(
        bytes calldata accumulatorUpdate
    ) internal returns (uint8 numUpdates) {
        (
            uint encodedOffset,
            UpdateType updateType
        ) = extractUpdateTypeFromAccumulatorHeader(accumulatorUpdate);

        if (updateType != UpdateType.WormholeMerkle) {
            revert PythErrors.InvalidUpdateData();
        }

        uint offset;
        bytes20 digest;
        bytes calldata encoded;
        (
            offset,
            digest,
            numUpdates,
            encoded
        ) = extractWormholeMerkleHeaderDigestAndNumUpdatesAndEncodedFromAccumulatorUpdate(
            accumulatorUpdate,
            encodedOffset
        );

        unchecked {
            for (uint i = 0; i < numUpdates; i++) {
                PythInternalStructs.PriceInfo memory priceInfo;
                bytes32 priceId;
                (offset, priceInfo, priceId) = extractPriceInfoFromMerkleProof(
                    digest,
                    encoded,
                    offset
                );
                uint64 latestPublishTime = latestPriceInfoPublishTime(priceId);
                if (priceInfo.publishTime > latestPublishTime) {
                    setLatestPriceInfo(priceId, priceInfo);
                    emit PriceFeedUpdate(
                        priceId,
                        priceInfo.publishTime,
                        priceInfo.price,
                        priceInfo.conf
                    );
                }
            }
        }
        if (offset != encoded.length) revert PythErrors.InvalidUpdateData();
    }
}

abstract contract Pyth is
    PythGetters,
    PythSetters,
    AbstractPyth,
    PythAccumulator
{
    function _initialize(
        address wormhole,
        uint16[] calldata dataSourceEmitterChainIds,
        bytes32[] calldata dataSourceEmitterAddresses,
        uint16 governanceEmitterChainId,
        bytes32 governanceEmitterAddress,
        uint64 governanceInitialSequence,
        uint validTimePeriodSeconds,
        uint singleUpdateFeeInWei
    ) internal {
        setWormhole(wormhole);

        if (
            dataSourceEmitterChainIds.length !=
            dataSourceEmitterAddresses.length
        ) revert PythErrors.InvalidArgument();

        for (uint i = 0; i < dataSourceEmitterChainIds.length; i++) {
            PythInternalStructs.DataSource memory ds = PythInternalStructs
                .DataSource(
                    dataSourceEmitterChainIds[i],
                    dataSourceEmitterAddresses[i]
                );

            if (PythGetters.isValidDataSource(ds.chainId, ds.emitterAddress))
                revert PythErrors.InvalidArgument();

            _state.isValidDataSource[hashDataSource(ds)] = true;
            _state.validDataSources.push(ds);
        }

        {
            PythInternalStructs.DataSource memory ds = PythInternalStructs
                .DataSource(governanceEmitterChainId, governanceEmitterAddress);
            PythSetters.setGovernanceDataSource(ds);
            PythSetters.setLastExecutedGovernanceSequence(
                governanceInitialSequence
            );
        }

        PythSetters.setValidTimePeriodSeconds(validTimePeriodSeconds);
        PythSetters.setSingleUpdateFeeInWei(singleUpdateFeeInWei);
    }

    function updatePriceBatchFromVm(bytes calldata encodedVm) private {
        parseAndProcessBatchPriceAttestation(
            parseAndVerifyBatchAttestationVM(encodedVm)
        );
    }

    function updatePriceFeeds(
        bytes[] calldata updateData
    ) public payable override {
        uint totalNumUpdates = 0;
        for (uint i = 0; i < updateData.length; ) {
            if (
                updateData[i].length > 4 &&
                UnsafeCalldataBytesLib.toUint32(updateData[i], 0) ==
                ACCUMULATOR_MAGIC
            ) {
                totalNumUpdates += updatePriceInfosFromAccumulatorUpdate(
                    updateData[i]
                );
            } else {
                updatePriceBatchFromVm(updateData[i]);
                totalNumUpdates += 1;
            }

            unchecked {
                i++;
            }
        }
        uint requiredFee = getTotalFee(totalNumUpdates);
        if (msg.value < requiredFee) revert PythErrors.InsufficientFee();
    }

    
    function getUpdateFee(
        uint updateDataSize
    ) public view returns (uint feeAmount) {
        return singleUpdateFeeInWei() * updateDataSize;
    }

    function getUpdateFee(
        bytes[] calldata updateData
    ) public view override returns (uint feeAmount) {
        uint totalNumUpdates = 0;
        for (uint i = 0; i < updateData.length; i++) {
            if (
                updateData[i].length > 4 &&
                UnsafeCalldataBytesLib.toUint32(updateData[i], 0) ==
                ACCUMULATOR_MAGIC
            ) {
                (
                    uint offset,
                    UpdateType updateType
                ) = extractUpdateTypeFromAccumulatorHeader(updateData[i]);
                if (updateType != UpdateType.WormholeMerkle) {
                    revert PythErrors.InvalidUpdateData();
                }
                totalNumUpdates += parseWormholeMerkleHeaderNumUpdates(
                    updateData[i],
                    offset
                );
            } else {
                totalNumUpdates += 1;
            }
        }
        return getTotalFee(totalNumUpdates);
    }

    function verifyPythVM(
        IWormhole.VM memory vm
    ) private view returns (bool valid) {
        return isValidDataSource(vm.emitterChainId, vm.emitterAddress);
    }

    function parseAndProcessBatchPriceAttestation(
        IWormhole.VM memory vm
    ) internal {
        
        
        
        
        unchecked {
            bytes memory encoded = vm.payload;
            (
                uint index,
                uint nAttestations,
                uint attestationSize
            ) = parseBatchAttestationHeader(encoded);

            
            for (uint j = 0; j < nAttestations; j++) {
                (
                    PythInternalStructs.PriceInfo memory info,
                    bytes32 priceId
                ) = parseSingleAttestationFromBatch(
                        encoded,
                        index,
                        attestationSize
                    );

                
                index += attestationSize;

                
                uint64 latestPublishTime = latestPriceInfoPublishTime(priceId);

                if (info.publishTime > latestPublishTime) {
                    setLatestPriceInfo(priceId, info);
                    emit PriceFeedUpdate(
                        priceId,
                        info.publishTime,
                        info.price,
                        info.conf
                    );
                }
            }

            emit BatchPriceFeedUpdate(vm.emitterChainId, vm.sequence);
        }
    }

    function parseSingleAttestationFromBatch(
        bytes memory encoded,
        uint index,
        uint attestationSize
    )
        internal
        pure
        returns (PythInternalStructs.PriceInfo memory info, bytes32 priceId)
    {
        unchecked {
            
            
            
            uint attestationIndex = 0;

            
            attestationIndex += 32;

            priceId = UnsafeBytesLib.toBytes32(
                encoded,
                index + attestationIndex
            );
            attestationIndex += 32;

            info.price = int64(
                UnsafeBytesLib.toUint64(encoded, index + attestationIndex)
            );
            attestationIndex += 8;

            info.conf = UnsafeBytesLib.toUint64(
                encoded,
                index + attestationIndex
            );
            attestationIndex += 8;

            info.expo = int32(
                UnsafeBytesLib.toUint32(encoded, index + attestationIndex)
            );
            attestationIndex += 4;

            info.emaPrice = int64(
                UnsafeBytesLib.toUint64(encoded, index + attestationIndex)
            );
            attestationIndex += 8;

            info.emaConf = UnsafeBytesLib.toUint64(
                encoded,
                index + attestationIndex
            );
            attestationIndex += 8;

            {
                
                
                
                
                
                uint8 status = UnsafeBytesLib.toUint8(
                    encoded,
                    index + attestationIndex
                );
                attestationIndex += 1;

                
                attestationIndex += 4;

                
                attestationIndex += 4;

                
                attestationIndex += 8;

                info.publishTime = UnsafeBytesLib.toUint64(
                    encoded,
                    index + attestationIndex
                );
                attestationIndex += 8;

                if (status == 1) {
                    
                    attestationIndex += 24;
                } else {
                    
                    

                    
                    info.publishTime = UnsafeBytesLib.toUint64(
                        encoded,
                        index + attestationIndex
                    );
                    attestationIndex += 8;

                    
                    info.price = int64(
                        UnsafeBytesLib.toUint64(
                            encoded,
                            index + attestationIndex
                        )
                    );
                    attestationIndex += 8;

                    
                    info.conf = UnsafeBytesLib.toUint64(
                        encoded,
                        index + attestationIndex
                    );
                    attestationIndex += 8;
                }
            }

            if (attestationIndex > attestationSize)
                revert PythErrors.InvalidUpdateData();
        }
    }

    
    
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable override {
        if (priceIds.length != publishTimes.length)
            revert PythErrors.InvalidArgument();

        for (uint i = 0; i < priceIds.length; ) {
            
            
            if (latestPriceInfoPublishTime(priceIds[i]) < publishTimes[i]) {
                updatePriceFeeds(updateData);
                return;
            }

            unchecked {
                i++;
            }
        }

        revert PythErrors.NoFreshUpdate();
    }

    
    
    
    
    function getPriceUnsafe(
        bytes32 id
    ) public view override returns (PythStructs.Price memory price) {
        PythInternalStructs.PriceInfo storage info = _state.latestPriceInfo[id];
        price.publishTime = info.publishTime;
        price.expo = info.expo;
        price.price = info.price;
        price.conf = info.conf;

        if (price.publishTime == 0) revert PythErrors.PriceFeedNotFound();
    }

    
    
    
    
    function getEmaPriceUnsafe(
        bytes32 id
    ) public view override returns (PythStructs.Price memory price) {
        PythInternalStructs.PriceInfo storage info = _state.latestPriceInfo[id];
        price.publishTime = info.publishTime;
        price.expo = info.expo;
        price.price = info.emaPrice;
        price.conf = info.emaConf;

        if (price.publishTime == 0) revert PythErrors.PriceFeedNotFound();
    }

    function parseBatchAttestationHeader(
        bytes memory encoded
    )
        internal
        pure
        returns (uint index, uint nAttestations, uint attestationSize)
    {
        unchecked {
            index = 0;

            
            {
                uint32 magic = UnsafeBytesLib.toUint32(encoded, index);
                index += 4;
                if (magic != 0x50325748) revert PythErrors.InvalidUpdateData();

                uint16 versionMajor = UnsafeBytesLib.toUint16(encoded, index);
                index += 2;
                if (versionMajor != 3) revert PythErrors.InvalidUpdateData();

                
                
                
                index += 2;

                
                
                

                uint16 hdrSize = UnsafeBytesLib.toUint16(encoded, index);
                index += 2;

                
                
                
                
                
                
                
                
                
                
                
                
                

                uint8 payloadId = UnsafeBytesLib.toUint8(encoded, index);

                
                index += hdrSize;

                
                if (payloadId != 2) revert PythErrors.InvalidUpdateData();
            }

            
            nAttestations = UnsafeBytesLib.toUint16(encoded, index);
            index += 2;

            
            attestationSize = UnsafeBytesLib.toUint16(encoded, index);
            index += 2;

            
            
            if (encoded.length != (index + (attestationSize * nAttestations)))
                revert PythErrors.InvalidUpdateData();
        }
    }

    function parseAndVerifyBatchAttestationVM(
        bytes calldata encodedVm
    ) internal view returns (IWormhole.VM memory vm) {
        {
            bool valid;
            (vm, valid, ) = wormhole().parseAndVerifyVM(encodedVm);
            if (!valid) revert PythErrors.InvalidWormholeVaa();
        }

        if (!verifyPythVM(vm)) revert PythErrors.InvalidUpdateDataSource();
    }

    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    )
        external
        payable
        override
        returns (PythStructs.PriceFeed[] memory priceFeeds)
    {
        {
            uint requiredFee = getUpdateFee(updateData);
            if (msg.value < requiredFee) revert PythErrors.InsufficientFee();
        }
        unchecked {
            priceFeeds = new PythStructs.PriceFeed[](priceIds.length);
            for (uint i = 0; i < updateData.length; i++) {
                if (
                    updateData[i].length > 4 &&
                    UnsafeCalldataBytesLib.toUint32(updateData[i], 0) ==
                    ACCUMULATOR_MAGIC
                ) {
                    uint offset;
                    {
                        UpdateType updateType;
                        (
                            offset,
                            updateType
                        ) = extractUpdateTypeFromAccumulatorHeader(
                            updateData[i]
                        );

                        if (updateType != UpdateType.WormholeMerkle) {
                            revert PythErrors.InvalidUpdateData();
                        }
                    }

                    bytes20 digest;
                    uint8 numUpdates;
                    bytes calldata encoded;
                    (
                        offset,
                        digest,
                        numUpdates,
                        encoded
                    ) = extractWormholeMerkleHeaderDigestAndNumUpdatesAndEncodedFromAccumulatorUpdate(
                        updateData[i],
                        offset
                    );

                    for (uint j = 0; j < numUpdates; j++) {
                        PythInternalStructs.PriceInfo memory info;
                        bytes32 priceId;
                        (
                            offset,
                            info,
                            priceId
                        ) = extractPriceInfoFromMerkleProof(
                            digest,
                            encoded,
                            offset
                        );
                        {
                            
                            uint k = findIndexOfPriceId(priceIds, priceId);

                            
                            
                            if (k == priceIds.length || priceFeeds[k].id != 0) {
                                continue;
                            }

                            uint publishTime = uint(info.publishTime);
                            
                            
                            
                            
                            if (
                                publishTime >= minPublishTime &&
                                publishTime <= maxPublishTime
                            ) {
                                fillPriceFeedFromPriceInfo(
                                    priceFeeds,
                                    k,
                                    priceId,
                                    info,
                                    publishTime
                                );
                            }
                        }
                    }
                    if (offset != encoded.length)
                        revert PythErrors.InvalidUpdateData();
                } else {
                    bytes memory encoded;
                    {
                        IWormhole.VM
                            memory vm = parseAndVerifyBatchAttestationVM(
                                updateData[i]
                            );
                        encoded = vm.payload;
                    }

                    
                    
                    (
                        uint index,
                        uint nAttestations,
                        uint attestationSize
                    ) = parseBatchAttestationHeader(encoded);

                    
                    for (uint j = 0; j < nAttestations; j++) {
                        
                        
                        
                        uint attestationIndex = 0;

                        
                        attestationIndex += 32;

                        bytes32 priceId = UnsafeBytesLib.toBytes32(
                            encoded,
                            index + attestationIndex
                        );

                        
                        uint k = findIndexOfPriceId(priceIds, priceId);

                        
                        
                        if (k == priceIds.length || priceFeeds[k].id != 0) {
                            index += attestationSize;
                            continue;
                        }

                        (
                            PythInternalStructs.PriceInfo memory info,

                        ) = parseSingleAttestationFromBatch(
                                encoded,
                                index,
                                attestationSize
                            );

                        uint publishTime = uint(info.publishTime);
                        
                        
                        
                        
                        if (
                            publishTime >= minPublishTime &&
                            publishTime <= maxPublishTime
                        ) {
                            fillPriceFeedFromPriceInfo(
                                priceFeeds,
                                k,
                                priceId,
                                info,
                                publishTime
                            );
                        }

                        index += attestationSize;
                    }
                }
            }

            for (uint k = 0; k < priceIds.length; k++) {
                if (priceFeeds[k].id == 0) {
                    revert PythErrors.PriceFeedNotFoundWithinRange();
                }
            }
        }
    }

    function getTotalFee(
        uint totalNumUpdates
    ) private view returns (uint requiredFee) {
        return totalNumUpdates * singleUpdateFeeInWei();
    }

    function findIndexOfPriceId(
        bytes32[] calldata priceIds,
        bytes32 targetPriceId
    ) private pure returns (uint index) {
        uint k = 0;
        for (; k < priceIds.length; k++) {
            if (priceIds[k] == targetPriceId) {
                break;
            }
        }
        return k;
    }

    function fillPriceFeedFromPriceInfo(
        PythStructs.PriceFeed[] memory priceFeeds,
        uint k,
        bytes32 priceId,
        PythInternalStructs.PriceInfo memory info,
        uint publishTime
    ) private pure {
        priceFeeds[k].id = priceId;
        priceFeeds[k].price.price = info.price;
        priceFeeds[k].price.conf = info.conf;
        priceFeeds[k].price.expo = info.expo;
        priceFeeds[k].price.publishTime = publishTime;
        priceFeeds[k].emaPrice.price = info.emaPrice;
        priceFeeds[k].emaPrice.conf = info.emaConf;
        priceFeeds[k].emaPrice.expo = info.expo;
        priceFeeds[k].emaPrice.publishTime = publishTime;
    }

    function queryPriceFeed(
        bytes32 id
    ) public view override returns (PythStructs.PriceFeed memory priceFeed) {
        
        PythInternalStructs.PriceInfo memory info = latestPriceInfo(id);
        if (info.publishTime == 0) revert PythErrors.PriceFeedNotFound();

        priceFeed.id = id;
        priceFeed.price.price = info.price;
        priceFeed.price.conf = info.conf;
        priceFeed.price.expo = info.expo;
        priceFeed.price.publishTime = uint(info.publishTime);

        priceFeed.emaPrice.price = info.emaPrice;
        priceFeed.emaPrice.conf = info.emaConf;
        priceFeed.emaPrice.expo = info.expo;
        priceFeed.emaPrice.publishTime = uint(info.publishTime);
    }

    function priceFeedExists(bytes32 id) public view override returns (bool) {
        return (latestPriceInfoPublishTime(id) != 0);
    }

    function getValidTimePeriod() public view override returns (uint) {
        return validTimePeriodSeconds();
    }

    function version() public pure returns (string memory) {
        return "1.3.0";
    }
}

library AddressUpgradeable {
    
    function isContract(address account) internal view returns (bool) {
        
        
        

        return account.code.length > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                
                
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        
        if (returndata.length > 0) {
            
            
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

abstract contract Initializable {
    
    uint8 private _initialized;

    
    bool private _initializing;

    
    event Initialized(uint8 version);

    
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

interface IERC1822ProxiableUpgradeable {
    
    function proxiableUUID() external view returns (bytes32);
}

interface IBeaconUpgradeable {
    
    function implementation() external view returns (address);
}

library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        
        assembly {
            r.slot := slot
        }
    }

    
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        
        assembly {
            r.slot := slot
        }
    }

    
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        
        assembly {
            r.slot := slot
        }
    }

    
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        
        assembly {
            r.slot := slot
        }
    }
}

abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    
    event Upgraded(address indexed implementation);

    
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        
        
        
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    
    event AdminChanged(address previousAdmin, address newAdmin);

    
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    
    event BeaconUpgraded(address indexed beacon);

    
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    
    uint256[50] private __gap;
}

abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    
    address private immutable __self = address(this);

    
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    
    function _authorizeUpgrade(address newImplementation) internal virtual;

    
    uint256[50] private __gap;
}

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    
    uint256[50] private __gap;
}

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    
    uint256[49] private __gap;
}

contract PythGovernanceInstructions {
    using BytesLib for bytes;

    
    uint32 constant MAGIC = 0x5054474d;

    enum GovernanceModule {
        Executor, 
        Target 
    }

    GovernanceModule constant MODULE = GovernanceModule.Target;

    enum GovernanceAction {
        UpgradeContract, 
        AuthorizeGovernanceDataSourceTransfer, 
        SetDataSources, 
        SetFee, 
        SetValidPeriod, 
        RequestGovernanceDataSourceTransfer, 
        SetWormholeAddress 
    }

    struct GovernanceInstruction {
        GovernanceModule module;
        GovernanceAction action;
        uint16 targetChainId;
        bytes payload;
    }

    struct UpgradeContractPayload {
        address newImplementation;
    }

    struct AuthorizeGovernanceDataSourceTransferPayload {
        
        
        
        bytes claimVaa;
    }

    struct RequestGovernanceDataSourceTransferPayload {
        
        
        uint32 governanceDataSourceIndex;
    }

    struct SetDataSourcesPayload {
        PythInternalStructs.DataSource[] dataSources;
    }

    struct SetFeePayload {
        uint newFee;
    }

    struct SetValidPeriodPayload {
        uint newValidPeriod;
    }

    struct SetWormholeAddressPayload {
        address newWormholeAddress;
    }

    
    function parseGovernanceInstruction(
        bytes memory encodedInstruction
    ) public pure returns (GovernanceInstruction memory gi) {
        uint index = 0;

        uint32 magic = encodedInstruction.toUint32(index);

        if (magic != MAGIC) revert PythErrors.InvalidGovernanceMessage();

        index += 4;

        uint8 modNumber = encodedInstruction.toUint8(index);
        gi.module = GovernanceModule(modNumber);
        index += 1;

        if (gi.module != MODULE) revert PythErrors.InvalidGovernanceTarget();

        uint8 actionNumber = encodedInstruction.toUint8(index);
        gi.action = GovernanceAction(actionNumber);
        index += 1;

        gi.targetChainId = encodedInstruction.toUint16(index);
        index += 2;

        
        
        
        gi.payload = encodedInstruction.slice(
            index,
            encodedInstruction.length - index
        );
    }

    
    function parseUpgradeContractPayload(
        bytes memory encodedPayload
    ) public pure returns (UpgradeContractPayload memory uc) {
        uint index = 0;

        uc.newImplementation = address(encodedPayload.toAddress(index));
        index += 20;

        if (encodedPayload.length != index)
            revert PythErrors.InvalidGovernanceMessage();
    }

    
    function parseAuthorizeGovernanceDataSourceTransferPayload(
        bytes memory encodedPayload
    )
        public
        pure
        returns (AuthorizeGovernanceDataSourceTransferPayload memory sgds)
    {
        sgds.claimVaa = encodedPayload;
    }

    
    function parseRequestGovernanceDataSourceTransferPayload(
        bytes memory encodedPayload
    )
        public
        pure
        returns (RequestGovernanceDataSourceTransferPayload memory sgdsClaim)
    {
        uint index = 0;

        sgdsClaim.governanceDataSourceIndex = encodedPayload.toUint32(index);
        index += 4;

        if (encodedPayload.length != index)
            revert PythErrors.InvalidGovernanceMessage();
    }

    
    function parseSetDataSourcesPayload(
        bytes memory encodedPayload
    ) public pure returns (SetDataSourcesPayload memory sds) {
        uint index = 0;

        uint8 dataSourcesLength = encodedPayload.toUint8(index);
        index += 1;

        sds.dataSources = new PythInternalStructs.DataSource[](
            dataSourcesLength
        );

        for (uint i = 0; i < dataSourcesLength; i++) {
            sds.dataSources[i].chainId = encodedPayload.toUint16(index);
            index += 2;

            sds.dataSources[i].emitterAddress = encodedPayload.toBytes32(index);
            index += 32;
        }

        if (encodedPayload.length != index)
            revert PythErrors.InvalidGovernanceMessage();
    }

    
    function parseSetFeePayload(
        bytes memory encodedPayload
    ) public pure returns (SetFeePayload memory sf) {
        uint index = 0;

        uint64 val = encodedPayload.toUint64(index);
        index += 8;

        uint64 expo = encodedPayload.toUint64(index);
        index += 8;

        sf.newFee = uint256(val) * uint256(10) ** uint256(expo);

        if (encodedPayload.length != index)
            revert PythErrors.InvalidGovernanceMessage();
    }

    
    function parseSetValidPeriodPayload(
        bytes memory encodedPayload
    ) public pure returns (SetValidPeriodPayload memory svp) {
        uint index = 0;

        svp.newValidPeriod = uint256(encodedPayload.toUint64(index));
        index += 8;

        if (encodedPayload.length != index)
            revert PythErrors.InvalidGovernanceMessage();
    }

    
    function parseSetWormholeAddressPayload(
        bytes memory encodedPayload
    ) public pure returns (SetWormholeAddressPayload memory sw) {
        uint index = 0;

        sw.newWormholeAddress = address(encodedPayload.toAddress(index));
        index += 20;

        if (encodedPayload.length != index)
            revert PythErrors.InvalidGovernanceMessage();
    }
}

interface IBeacon {
    
    function implementation() external view returns (address);
}

interface IERC1822Proxiable {
    
    function proxiableUUID() external view returns (bytes32);
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        

        return account.code.length > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                
                
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        
        if (returndata.length > 0) {
            
            
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        
        assembly {
            r.slot := slot
        }
    }

    
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        
        assembly {
            r.slot := slot
        }
    }

    
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        
        assembly {
            r.slot := slot
        }
    }

    
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        
        assembly {
            r.slot := slot
        }
    }
}

abstract contract ERC1967Upgrade {
    
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    
    event Upgraded(address indexed implementation);

    
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        
        
        
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    
    event AdminChanged(address previousAdmin, address newAdmin);

    
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    
    event BeaconUpgraded(address indexed beacon);

    
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

abstract contract PythGovernance is
    PythGetters,
    PythSetters,
    PythGovernanceInstructions
{
    event ContractUpgraded(
        address oldImplementation,
        address newImplementation
    );
    event GovernanceDataSourceSet(
        PythInternalStructs.DataSource oldDataSource,
        PythInternalStructs.DataSource newDataSource,
        uint64 initialSequence
    );
    event DataSourcesSet(
        PythInternalStructs.DataSource[] oldDataSources,
        PythInternalStructs.DataSource[] newDataSources
    );
    event FeeSet(uint oldFee, uint newFee);
    event ValidPeriodSet(uint oldValidPeriod, uint newValidPeriod);
    event WormholeAddressSet(
        address oldWormholeAddress,
        address newWormholeAddress
    );

    function verifyGovernanceVM(
        bytes memory encodedVM
    ) internal returns (IWormhole.VM memory parsedVM) {
        (IWormhole.VM memory vm, bool valid, ) = wormhole().parseAndVerifyVM(
            encodedVM
        );

        if (!valid) revert PythErrors.InvalidWormholeVaa();

        if (!isValidGovernanceDataSource(vm.emitterChainId, vm.emitterAddress))
            revert PythErrors.InvalidGovernanceDataSource();

        if (vm.sequence <= lastExecutedGovernanceSequence())
            revert PythErrors.OldGovernanceMessage();

        setLastExecutedGovernanceSequence(vm.sequence);

        return vm;
    }

    function executeGovernanceInstruction(bytes calldata encodedVM) public {
        IWormhole.VM memory vm = verifyGovernanceVM(encodedVM);

        GovernanceInstruction memory gi = parseGovernanceInstruction(
            vm.payload
        );

        if (gi.targetChainId != chainId() && gi.targetChainId != 0)
            revert PythErrors.InvalidGovernanceTarget();

        if (gi.action == GovernanceAction.UpgradeContract) {
            if (gi.targetChainId == 0)
                revert PythErrors.InvalidGovernanceTarget();
            upgradeContract(parseUpgradeContractPayload(gi.payload));
        } else if (
            gi.action == GovernanceAction.AuthorizeGovernanceDataSourceTransfer
        ) {
            AuthorizeGovernanceDataSourceTransfer(
                parseAuthorizeGovernanceDataSourceTransferPayload(gi.payload)
            );
        } else if (gi.action == GovernanceAction.SetDataSources) {
            setDataSources(parseSetDataSourcesPayload(gi.payload));
        } else if (gi.action == GovernanceAction.SetFee) {
            setFee(parseSetFeePayload(gi.payload));
        } else if (gi.action == GovernanceAction.SetValidPeriod) {
            setValidPeriod(parseSetValidPeriodPayload(gi.payload));
        } else if (
            gi.action == GovernanceAction.RequestGovernanceDataSourceTransfer
        ) {
            
            revert PythErrors.InvalidGovernanceMessage();
        } else if (gi.action == GovernanceAction.SetWormholeAddress) {
            if (gi.targetChainId == 0)
                revert PythErrors.InvalidGovernanceTarget();
            setWormholeAddress(
                parseSetWormholeAddressPayload(gi.payload),
                encodedVM
            );
        } else {
            revert PythErrors.InvalidGovernanceMessage();
        }
    }

    function upgradeContract(UpgradeContractPayload memory payload) internal {
        
        
        upgradeUpgradableContract(payload);
    }

    function upgradeUpgradableContract(
        UpgradeContractPayload memory payload
    ) internal virtual;

    
    
    function AuthorizeGovernanceDataSourceTransfer(
        AuthorizeGovernanceDataSourceTransferPayload memory payload
    ) internal {
        PythInternalStructs.DataSource
            memory oldGovernanceDatSource = governanceDataSource();

        
        
        
        
        (IWormhole.VM memory vm, bool valid, ) = wormhole().parseAndVerifyVM(
            payload.claimVaa
        );
        if (!valid) revert PythErrors.InvalidWormholeVaa();

        GovernanceInstruction memory gi = parseGovernanceInstruction(
            vm.payload
        );
        if (gi.targetChainId != chainId() && gi.targetChainId != 0)
            revert PythErrors.InvalidGovernanceTarget();

        if (gi.action != GovernanceAction.RequestGovernanceDataSourceTransfer)
            revert PythErrors.InvalidGovernanceMessage();

        RequestGovernanceDataSourceTransferPayload
            memory claimPayload = parseRequestGovernanceDataSourceTransferPayload(
                gi.payload
            );

        
        if (
            governanceDataSourceIndex() >=
            claimPayload.governanceDataSourceIndex
        ) revert PythErrors.OldGovernanceMessage();

        setGovernanceDataSourceIndex(claimPayload.governanceDataSourceIndex);

        PythInternalStructs.DataSource
            memory newGovernanceDS = PythInternalStructs.DataSource(
                vm.emitterChainId,
                vm.emitterAddress
            );

        setGovernanceDataSource(newGovernanceDS);

        
        setLastExecutedGovernanceSequence(vm.sequence);

        emit GovernanceDataSourceSet(
            oldGovernanceDatSource,
            governanceDataSource(),
            lastExecutedGovernanceSequence()
        );
    }

    function setDataSources(SetDataSourcesPayload memory payload) internal {
        PythInternalStructs.DataSource[]
            memory oldDataSources = validDataSources();

        for (uint i = 0; i < oldDataSources.length; i += 1) {
            _state.isValidDataSource[hashDataSource(oldDataSources[i])] = false;
        }

        delete _state.validDataSources;
        for (uint i = 0; i < payload.dataSources.length; i++) {
            _state.validDataSources.push(payload.dataSources[i]);
            _state.isValidDataSource[
                hashDataSource(payload.dataSources[i])
            ] = true;
        }

        emit DataSourcesSet(oldDataSources, validDataSources());
    }

    function setFee(SetFeePayload memory payload) internal {
        uint oldFee = singleUpdateFeeInWei();
        setSingleUpdateFeeInWei(payload.newFee);

        emit FeeSet(oldFee, singleUpdateFeeInWei());
    }

    function setValidPeriod(SetValidPeriodPayload memory payload) internal {
        uint oldValidPeriod = validTimePeriodSeconds();
        setValidTimePeriodSeconds(payload.newValidPeriod);

        emit ValidPeriodSet(oldValidPeriod, validTimePeriodSeconds());
    }

    function setWormholeAddress(
        SetWormholeAddressPayload memory payload,
        bytes memory encodedVM
    ) internal {
        address oldWormholeAddress = address(wormhole());
        setWormhole(payload.newWormholeAddress);

        
        
        (IWormhole.VM memory vm, bool valid, ) = wormhole().parseAndVerifyVM(
            encodedVM
        );

        if (!valid) revert PythErrors.InvalidGovernanceMessage();

        if (!isValidGovernanceDataSource(vm.emitterChainId, vm.emitterAddress))
            revert PythErrors.InvalidGovernanceMessage();

        if (vm.sequence != lastExecutedGovernanceSequence())
            revert PythErrors.InvalidWormholeAddressToSet();

        GovernanceInstruction memory gi = parseGovernanceInstruction(
            vm.payload
        );

        if (gi.action != GovernanceAction.SetWormholeAddress)
            revert PythErrors.InvalidWormholeAddressToSet();

        
        

        
        
        SetWormholeAddressPayload
            memory newPayload = parseSetWormholeAddressPayload(gi.payload);

        if (newPayload.newWormholeAddress != payload.newWormholeAddress)
            revert PythErrors.InvalidWormholeAddressToSet();

        emit WormholeAddressSet(oldWormholeAddress, address(wormhole()));
    }
}

contract PythUpgradable is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    Pyth,
    PythGovernance
{
    function initialize(
        address wormhole,
        uint16[] calldata dataSourceEmitterChainIds,
        bytes32[] calldata dataSourceEmitterAddresses,
        uint16 governanceEmitterChainId,
        bytes32 governanceEmitterAddress,
        uint64 governanceInitialSequence,
        uint validTimePeriodSeconds,
        uint singleUpdateFeeInWei
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        Pyth._initialize(
            wormhole,
            dataSourceEmitterChainIds,
            dataSourceEmitterAddresses,
            governanceEmitterChainId,
            governanceEmitterAddress,
            governanceInitialSequence,
            validTimePeriodSeconds,
            singleUpdateFeeInWei
        );

        renounceOwnership();
    }

    
    
    constructor() initializer {}

    
    
    
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function pythUpgradableMagic() public pure returns (uint32) {
        return 0x97a6f304;
    }

    
    function upgradeUpgradableContract(
        UpgradeContractPayload memory payload
    ) internal override {
        address oldImplementation = _getImplementation();
        _upgradeToAndCallUUPS(payload.newImplementation, new bytes(0), false);

        
        
        
        if (this.pythUpgradableMagic() != 0x97a6f304)
            revert PythErrors.InvalidGovernanceMessage();

        emit ContractUpgraded(oldImplementation, _getImplementation());
    }
}